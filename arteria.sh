#!/bin/sh
###############################################################################
#  Arteria for Asuswrt-Merlin
#  A live, animated map of how traffic flows between the internet, the router,
#  its AiMesh nodes and every client. It only samples while its page is open.
#
#  Page: Traffic Analyzer -> Arteria (two views: Map and Flow)
#
#  Usage: arteria.sh                    (a menu, when run in a terminal: amtm opens this)
#         arteria.sh install | update [force | dev [branch]] | uninstall | status | check |
#                    nodes [test] | nodekey [node-ip] | debug | sample | amtmupdate [check] |
#                    startup | version
#
#  Install:  curl -fsL --retry 3 https://github.com/IfSugar/arteria/releases/latest/download/arteria.sh \
#              -o /tmp/arteria.sh && sh /tmp/arteria.sh install
###############################################################################

VERSION="1.0.0"
NAME="arteria"
TITLE="Arteria"

# AR_ROOT, AR_PROC and AR_SYS let the script be tested off-router; they are empty on the router.
ROOT="${AR_ROOT:-}"
PROC="${AR_PROC:-/proc}"
SYSNET="${AR_SYS:-/sys}/class/net"
ADDON_DIR="$ROOT/jffs/addons/$NAME"
SCRIPT="$ADDON_DIR/$NAME.sh"
PAGE_SRC="$ADDON_DIR/$NAME.asp"
CONF="$ADDON_DIR/config"
BUILD_FILE="$ADDON_DIR/build"   # "dev <branch> <commit> <installed>" for a development version; none for a release
KEY="$ADDON_DIR/node_key"       # the SSH key the router uses to read AiMesh nodes (never leaves the router)
SSH_HOME="$ADDON_DIR"           # dbclient keeps known_hosts in $HOME/.ssh: each node's host key is pinned here
SCRIPTS_DIR="$ROOT/jffs/scripts"
HELPER="$ROOT/usr/sbin/helper.sh"
WWW_USER="$ROOT/www/user"
MENUTREE="$ROOT/www/require/modules/menuTree.js"
TMP_MENUTREE="$ROOT/tmp/menuTree.js"
WEBUI_LOCK="$ROOT/tmp/addonwebui.lock"
TMPD="$ROOT/tmp/$NAME"
REPO="IfSugar/arteria"
RAW_BASE="https://raw.githubusercontent.com/$REPO"
RAW_URL="${AR_RAW_URL:-$RAW_BASE/main}"   # AR_RAW_URL: test hook only

[ -z "$ROOT" ] && PATH="/sbin:/bin:/usr/sbin:/usr/bin:$PATH:/opt/bin:/opt/sbin"
export PATH

# ---- defaults (overridden by $CONF) ----------------------------------------
INTERVAL=2              # seconds between samples while the page is open (1-10)
IDLE_STOP=20            # stop sampling this many seconds after the last page closed (10-300)
NODES=on                # on: read each AiMesh node's per-device counters over SSH; off: backhaul totals only
NODE_USER=""            # SSH user on the nodes; empty = the router's admin name
AMTM_UPDATE=on          # on: amtm may update Arteria (amtmupdate); off: only 'update' does
[ -f "$CONF" ] && . "$CONF"
case "$INTERVAL" in [1-9]|10) ;; *) INTERVAL=2 ;; esac
case "$IDLE_STOP" in ''|*[!0-9]*) IDLE_STOP=20 ;; esac
[ "$IDLE_STOP" -lt 10 ] && IDLE_STOP=10
[ "$IDLE_STOP" -gt 300 ] && IDLE_STOP=300
case "$NODES" in on|off) ;; *) NODES=on ;; esac
case "$AMTM_UPDATE" in on|off) ;; *) AMTM_UPDATE=on ;; esac
case "$NODE_USER" in *[!A-Za-z0-9._-]*) NODE_USER="" ;; esac

# ---- helpers ---------------------------------------------------------------
log() { logger -t "$NAME" "$*" 2>/dev/null; }
say() { printf '%s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
now() { date +%s; }
js() { printf '%s' "$1" | tr -d '\000-\037' | sed 's/\\/\\\\/g; s/"/\\"/g'; }      # JSON string body
jnum() { case "$1" in ''|-|?*-*|*[!0-9-]*) echo null ;; *) echo "$1" ;; esac; }    # JSON number

# Is a program on PATH? (Router BusyBox builds can lack the `command` builtin, so walk PATH.)
have() {
	case "$1" in */*) [ -f "$1" ] && [ -x "$1" ]; return ;; esac
	_ifs=$IFS; IFS=:
	for _d in $PATH; do
		if [ -f "${_d:-.}/$1" ] && [ -x "${_d:-.}/$1" ]; then IFS=$_ifs; return 0; fi
	done
	IFS=$_ifs; return 1
}

# Background work runs at the lowest CPU priority, so routing, Wi-Fi and the web UI always come first.
lowprio() { renice -n 19 -p $$ >/dev/null 2>&1 || true; }

# A pid read from one of our files is only ours while that process still runs our command. A router
# reuses pids quickly (every sample starts dozens of short programs), and a stale file must never
# make Arteria signal someone else's process.
pid_ours() {   # pid pattern
	case "$1" in ''|*[!0-9]*) return 1 ;; esac
	tr '\000' ' ' < "/proc/$1/cmdline" 2>/dev/null | grep -q -- "$2"
}

web_dir() {
	d="$(readlink -f "$WWW_USER" 2>/dev/null)"
	[ -n "$d" ] || d="$WWW_USER"
	echo "$d/$NAME"
}

# httpd runs .htm/.js files through its <% %> template engine, so no '<' may reach the page raw.
# In this JSON '<' can only occur inside strings (device names), where < is identical.
write_atomic() {   # file content-from-stdin
	tmp="$1.$$.tmp"
	if sed 's/</\\u003c/g' > "$tmp"; then mv -f "$tmp" "$1"; else rm -f "$tmp"; return 1; fi
}

fw_version() {   # e.g. 3004.388.13_0
	fw=$(nvram get buildno); ext=$(nvram get extendno); fv=$(nvram get firmver | tr -d .)
	[ -n "$ext" ] && fw="${fw}_$ext"; [ -n "$fv" ] && fw="$fv.$fw"
	echo "$fw"
}

# ---- what the router has ---------------------------------------------------------
# Every Wi-Fi interface the router serves clients on (radios and guest networks), as "ifname:band".
radio_list() {
	for u in 0 1 2 3; do
		f=$(nvram get wl${u}_ifname); [ -n "$f" ] || continue
		case "$(nvram get wl${u}_nband)" in 2) b=2.4 ;; 1) b=5 ;; 4) b=6 ;; *) b=0 ;; esac
		printf '%s:%s\n' "$f" "$b"
		for v in $(nvram get wl${u}_vifs); do printf '%s:%s\n' "$v" "$b"; done
	done
}

# Wired LAN ports: lan_ifnames without the Wi-Fi interfaces, in the router's order (LAN 1 first).
lan_ports() {
	wifi=" $(radio_list | cut -d: -f1 | tr '\n' ' ') "
	for p in $(nvram get lan_ifnames); do
		case "$wifi" in *" $p "*) continue ;; esac
		printf '%s\n' "$p"
	done
}

wan_if() { w=$(nvram get wan0_gw_ifname); [ -n "$w" ] || w=$(nvram get wan0_ifname); printf '%s' "$w"; }

# The router's own interface addresses. A node lists the router as a "station" on its backhaul
# radio; the page drops these so the router never shows up as one of its own clients.
own_macs() {
	cat "$SYSNET"/*/address 2>/dev/null | tr a-f A-F | grep -v '^00:00:00:00:00:00$' | sort -u
}

# AiMesh nodes, one per line: "MAC IP MODEL". From the router's own AiMesh list; never the router itself.
node_list() {
	me=$(nvram get lan_ipaddr)
	nvram get cfg_device_list | tr '<' '\n' | awk -F'>' -v me="$me" '
		NF >= 3 && $2 != me && $2 ~ /^[0-9.]+$/ && $3 ~ /^[0-9A-Fa-f:]+$/ { print toupper($3), $2, $1 }'
}
node_alias() { sed -n 's/.*"cfg_alias":"\([^"]*\)".*/\1/p' "$ROOT/tmp/$1.json" 2>/dev/null | head -1; }
# A node's backhaul stations: the addresses it uses to connect to the router over Wi-Fi.
node_stas() {
	sed -n "s/.*\"$1\":{\([^}]*\)}.*/\1/p" "$ROOT/tmp/relist.json" 2>/dev/null | grep -o '[0-9A-Fa-f:]\{17\}' | tr a-f A-F | tr '\n' ' '
}
# Only when missing: on JFFS even a chmod that changes nothing is a write to flash, and the sampler calls this.
ssh_home() { [ -d "$SSH_HOME/.ssh" ] || { mkdir -p "$SSH_HOME/.ssh" && chmod 700 "$SSH_HOME/.ssh"; } 2>/dev/null; }
node_file() { printf '%s/node.%s' "$TMPD" "$(printf '%s' "$1" | tr -d :)"; }

# Key logins must never fall back to a password: when a node refuses the key, dbclient asks for one on
# the terminal, and a password typed there would make a refused key look like it works. Dropbear 2024.84
# and later (Merlin 3004.388.13 has 2026.94) have -o BatchMode=yes, which turns password and
# keyboard-interactive logins off. Prints that option, or nothing on an older dbclient.
ssh_batch() { dbclient -o help 2>&1 | grep -q BatchMode && printf '%s' '-o BatchMode=yes'; }
# True if this process can reach a terminal (dbclient opens /dev/tty itself to ask for a password,
# whatever stdin is). The sampler, started by the router's service events, has none.
has_tty() { ( exec < /dev/tty ) 2> /dev/null; }

ssh_port() { p=$(nvram get sshd_port); case "$p" in ''|*[!0-9]*) p=22 ;; esac; printf '%s' "$p"; }
ssh_user() { if [ -n "$NODE_USER" ]; then printf '%s' "$NODE_USER"; else u=$(nvram get http_username); printf '%s' "${u:-admin}"; fi; }

# One line per Wi-Fi client: "S ifname band MAC tx-bytes rx-bytes rssi tx-kbps rx-kbps connected-s idle-s".
# The input is "@ ifname band MAC" followed by that client's `wl sta_info`. tx is what the access point
# sent to the client (its download), rx what it received (its upload). The same program runs on the nodes,
# so it must not contain single quotes.
STA_AWK='function out() { if (m != "") print "S", x, b, m, tx, rx, r, tr, rr, cn, id }
$1 == "@" { out(); x = $2; b = $3; m = $4; tx = "-"; rx = "-"; r = "-"; tr = "-"; rr = "-"; cn = "-"; id = "-"; next }
/tx total bytes:/ { tx = $NF; next }
/rx data bytes:/ { rx = $NF; next }
/^smoothed rssi:/ { r = $NF; next }
/rate of last tx pkt:/ { tr = $6; next }
/rate of last rx pkt:/ { rr = $6; next }
/^[ \t]*in network / { cn = $3; next }
/^[ \t]*idle / { id = $2; next }
END { out() }'

# "S ..." lines -> JSON rows: ["ifname","band","MAC","tx","rx",rssi,txMbps,rxMbps,connected,idle].
# Byte counters stay strings: shell arithmetic is 32-bit, and awk would print big numbers as 9.5e+09.
ROWS_AWK='function q(s) { return (s ~ /^[0-9]+$/) ? "\"" s "\"" : "null" }
function n(s) { return (s ~ /^-?[0-9]+$/) ? s : "null" }
function k(s) { return (s ~ /^[0-9]+$/) ? int(s / 1000) : "null" }
function row(s) { return "[\"" $2 "\",\"" $3 "\",\"" toupper($4) "\"," q($5) "," q($6) "," n($7) "," k($8) "," k($9) "," n($10) "," n($11) "]" }'

sta_lines() {   # the router's own Wi-Fi clients (incl. the nodes' backhaul stations)
	for p in $RADIOS; do
		x=${p%%:*}; b=${p#*:}
		for m in $(wl -i "$x" assoclist 2>/dev/null | cut -d' ' -f2); do
			echo "@ $x $b $m"; wl -i "$x" sta_info "$m" 2>/dev/null
		done
	done | awk "$STA_AWK"
}
sta_json() {
	sta_lines | awk "$ROWS_AWK"'
		$1 == "S" && $2 ~ /^[A-Za-z0-9.]+$/ && $3 ~ /^[0-9.]+$/ && $4 ~ /^[0-9A-Fa-f:]+$/ { printf "%s%s", (c++ ? "," : ""), row() }'
}

# The script each node runs while the page is open: every INTERVAL seconds it prints a block of its
# clients' counters ("#B uptime", "S ..." lines, "#E"). It stops by itself after 30 minutes, or as soon
# as the router hangs up. It reads counters only; nothing on the node is changed.
write_node_script() {
	printf 'I=%s\n' "$INTERVAL"
	cat <<'EOF'
L=""
for u in 0 1 2 3; do
	f=$(nvram get wl${u}_ifname); [ -n "$f" ] || continue
	b=$(nvram get wl${u}_nband)
	case "$b" in 2) b=2.4 ;; 1) b=5 ;; 4) b=6 ;; *) b=0 ;; esac
	for x in $f $(nvram get wl${u}_vifs); do L="$L $x:$b"; done
done
n=0
while [ $n -lt $((1800 / I)) ]; do
	echo "#B $(cut -d' ' -f1 /proc/uptime)"
	for p in $L; do
		x=${p%%:*}; b=${p#*:}
		for m in $(wl -i "$x" assoclist 2>/dev/null | cut -d' ' -f2); do
			echo "@ $x $b $m"; wl -i "$x" sta_info "$m" 2>/dev/null
		done
EOF
	printf "\tdone | awk '%s'\n" "$STA_AWK"
	cat <<'EOF'
	echo "#E"
	n=$((n + 1)); sleep $I
done
EOF
}

# ---- AiMesh node sessions ----------------------------------------------------------
# While the page is open the router keeps one SSH session to each node. Key login only: the sampler
# has no terminal, so dbclient can never ask for (or send) a password. Host keys are pinned in $SSH_HOME.
node_start() {   # mac ip
	f=$(node_file "$1")
	: > "$f.out"; : > "$f.err"; now > "$f.start"; rm -f "$f.fail" "$f.last"
	(HOME="$SSH_HOME" exec dbclient $BATCH -y -K 10 -I 30 -p "$PORT" -i "$KEY" "$SSHUSER@$2" 'sh -s') \
		< "$TMPD/node.sh" >> "$f.out" 2>> "$f.err" 8>&- &
	echo $! > "$f.pid"
}
node_stop_all() {
	for p in "$TMPD"/node.*.pid; do
		[ -f "$p" ] || continue
		q=$(cat "$p" 2>/dev/null); pid_ours "$q" dbclient && kill "$q" 2>/dev/null; rm -f "$p"
	done
}
node_running() { pid_ours "$(cat "$1.pid" 2>/dev/null)" dbclient; }

# ok: fresh counters; wait: connecting; nokey: the node refused the key ('nodekey' fixes it);
# hostkey: the node's identity changed ('nodekey' re-pins it); down: unreachable; off: node access is off.
node_state() {   # file-base -> state
	if [ "$NODES" != on ]; then echo off; return; fi
	if [ ! -s "$KEY" ] || ! have dbclient; then echo nokey; return; fi
	f=$1
	if grep -q '^#E' "$f.out" 2>/dev/null || grep -q '^#E' "$f.last" 2>/dev/null; then
		age=$(( $(now) - $(date -r "$f.out" +%s 2>/dev/null || echo 0) ))
		[ "$age" -le $((INTERVAL * 3 + 4)) ] && { echo ok; return; }
	fi
	if node_running "$f"; then
		st=$(cat "$f.start" 2>/dev/null || echo 0)
		[ $(( $(now) - st )) -lt 15 ] && { echo wait; return; }
		echo down; return
	fi
	e=$(cat "$f.err" 2>/dev/null)
	case "$e" in
		*[Hh]ost\ key*|*[Mm]ismatch*|*[Ii]dentification*) echo hostkey ;;
		*[Pp]ermission\ denied*|*[Aa]uth*|*[Pp]assword*|*publickey*) echo nokey ;;
		*) echo down ;;
	esac
}

nodes_tick() {   # keep a session to every node; restart dead ones, but never retry a refused key
	[ -n "$NODE_LIST" ] || return 0
	printf '%s\n' "$NODE_LIST" | while read -r mac ip model; do
		[ -n "$ip" ] || continue
		f=$(node_file "$mac")
		node_running "$f" && continue
		[ -f "$f.fail" ] && continue
		st=$(cat "$f.start" 2>/dev/null || echo 0)
		if [ -f "$f.start" ]; then
			case "$(node_state "$f")" in nokey|hostkey) touch "$f.fail"; continue ;; esac
			[ $(( $(now) - st )) -lt 30 ] && continue
		fi
		node_start "$mac" "$ip"
	done
	# keep the output files small (dbclient appends, so emptying them is safe), keeping the last
	# complete block aside so the page doesn't lose the node's devices for a sample
	for o in "$TMPD"/node.*.out; do
		[ -f "$o" ] || continue
		if [ "$(wc -c < "$o")" -gt 131072 ]; then
			awk '/^#B / { b = "" } { b = b $0 "\n" } /^#E/ { last = b } END { printf "%s", last }' "$o" > "${o%.out}.last"
			: > "$o"
		fi
	done
	return 0
}

# The last complete block a node sent, as JSON: "up":"<node uptime>","c":[rows].
# Only rows between a "#B" and its "#E" count: the file can be emptied in the middle of a block.
NODE_AWK="$ROWS_AWK"'
/^#B / { cur = ""; cc = 0; cup = ($2 ~ /^[0-9.]+$/) ? $2 : ""; open = 1; next }
open && /^S / && $2 ~ /^[A-Za-z0-9.]+$/ && $3 ~ /^[0-9.]+$/ && $4 ~ /^[0-9A-Fa-f:]+$/ { cur = cur (cc++ ? "," : "") row(); next }
/^#E/ { if (open) { last = cur; lup = cup; done = 1 } open = 0; next }
END { if (done) printf "\"up\":\"%s\",\"c\":[%s]", lup, last; else printf "\"up\":null,\"c\":[]" }'

nodes_json() {
	c=0
	printf '%s\n' "$NODE_LIST" | while read -r mac ip model; do
		[ -n "$mac" ] || continue
		f=$(node_file "$mac")
		[ $c -gt 0 ] && printf ','; c=1
		printf '{"mac":"%s","ip":"%s","model":"%s","alias":"%s","sta":"%s","state":"%s",' \
			"$mac" "$ip" "$(js "$model")" "$(js "$(node_alias "$mac")")" "$(node_stas "$mac")" "$(node_state "$f")"
		if [ -s "$f.out" ] || [ -s "$f.last" ]; then cat "$f.last" "$f.out" 2>/dev/null | awk "$NODE_AWK"; else printf '"up":null,"c":[]'; fi
		printf '}'
	done
}

# ---- one sample ---------------------------------------------------------------------
links_json() {   # [port, carrier, Mb/s] for the WAN and every wired port
	c=0; printf '['
	for p in $WAN_IF $PORTS; do
		[ $c -gt 0 ] && printf ','; c=1
		printf '["%s",%s,%s]' "$p" "$(jnum "$(cat "$SYSNET/$p/carrier" 2>/dev/null)")" "$(jnum "$(cat "$SYSNET/$p/speed" 2>/dev/null)")"
	done
	printf ']'
}
macs_json() {    # [port, MAC] for every address the bridge has learned on a wired port
	map=$(brctl showstp br0 2>/dev/null | sed -n 's/^\([A-Za-z0-9.]*\) (\([0-9]*\))$/\2 \1/p' | tr '\n' ';')
	printf '['
	brctl showmacs br0 2>/dev/null | awk -v map="$map" -v want=" $PORTS " '
		BEGIN { n = split(map, a, ";"); for (i = 1; i <= n; i++) { split(a[i], b, " "); P[b[1]] = b[2] } }
		NR > 1 && $3 == "no" && $2 ~ /^[0-9A-Fa-f:]+$/ { p = P[$1]; if (p != "" && index(want, " " p " ")) printf "%s[\"%s\",\"%s\"]", (c++ ? "," : ""), p, toupper($2) }'
	printf ']'
}
ifs_json() {     # [ifname, rx bytes, tx bytes] for the WAN, the wired ports and the AiMesh WDS links
	awk -v want=" $WAN_IF $PORTS " 'NR > 2 {
		sub(/^[ \t]+/, ""); i = index($0, ":"); if (!i) next
		n = substr($0, 1, i - 1); split(substr($0, i + 1), f, " ")
		if (index(want, " " n " ") || n ~ /^wds/) printf "%s[\"%s\",\"%s\",\"%s\"]", (c++ ? "," : ""), n, f[1], f[9] }' "$PROC/net/dev"
}

sample_init() {
	RADIOS=$(radio_list | tr '\n' ' ')
	PORTS=$(lan_ports | tr '\n' ' ')
	WAN_IF=$(wan_if)
	MODEL=$(nvram get productid)
	FW=$(fw_version)
	OWN=$(own_macs | awk '{ printf "%s\"%s\"", (c++ ? "," : ""), $1 }')
	PORT=$(ssh_port); SSHUSER=$(ssh_user); BATCH=$(ssh_batch)
	ssh_home
	NODE_LIST=""
	[ "$NODES" = on ] && NODE_LIST=$(node_list)
	PORTS_JSON=$(printf '%s' "$PORTS" | awk '{ for (i = 1; i <= NF; i++) printf "%s\"%s\"", (i > 1 ? "," : ""), $i }')
}

sample_json() {   # seq ms -> one sample as JSON on stdout
	printf '{"v":1,"seq":%s,"up":"%s","epoch":%s,"ms":%s,' "$1" "$(cut -d' ' -f1 "$PROC/uptime")" "$(now)" "$2"
	printf '"router":{"model":"%s","fw":"%s","load":"%s"},' "$(js "$MODEL")" "$(js "$FW")" "$(cut -d' ' -f1 "$PROC/loadavg")"
	printf '"interval":%s,"nodes_mode":"%s","wan":"%s","ports":[%s],"own":[%s],' "$INTERVAL" "$NODES" "$WAN_IF" "$PORTS_JSON" "$OWN"
	printf '"links":'; cat "$TMPD/links.json" 2>/dev/null || printf '[]'
	printf ',"macs":'; cat "$TMPD/macs.json" 2>/dev/null || printf '[]'
	printf ',"ifs":['; ifs_json; printf ']'
	printf ',"sta":['; sta_json; printf ']'
	printf ',"nodes":['; nodes_json; printf ']}'
}

# Names come from the router's own client list: the nicknames you set (custom_clientlist), the names
# the router detected (nmp_cl_json.js), DHCP host names and the AiMesh client list. The page combines them.
export_names() {
	{
		printf '{"custom":"%s","leases":"' "$(js "$(nvram get custom_clientlist)")"
		tr '\n' '|' < "$ROOT/var/lib/misc/dnsmasq.leases" 2>/dev/null | tr -d '\000-\037' | sed 's/\\/\\\\/g; s/"/\\"/g'
		printf '","nmp":'
		if head -c 1 "$ROOT/jffs/nmp_cl_json.js" 2>/dev/null | grep -q '{'; then tr -d '\000-\037' < "$ROOT/jffs/nmp_cl_json.js"; else printf '{}'; fi
		printf ',"cl":'
		if head -c 1 "$ROOT/tmp/clientlist.json" 2>/dev/null | grep -q '{'; then tr -d '\000-\037' < "$ROOT/tmp/clientlist.json"; else printf '{}'; fi
		printf '}'
	} | write_atomic "$(web_dir)/names.htm"
}

uptime_cs() { awk '{ printf "%d", $1 * 100 }' "$PROC/uptime"; }   # centiseconds, for timing a sample

# ---- the sampler: runs only while the page is open ----------------------------------------
# The page asks for "start_arteria" every few seconds (service-event). Each request refreshes a
# heartbeat file; the sampler stops IDLE_STOP seconds after the last one, and at once if the page
# says it closed (start_arteriastop). Nothing runs on a schedule.
hb_fresh() {
	hb=$(date -r "$TMPD/heartbeat" +%s 2>/dev/null) || return 1
	[ $(( $(now) - hb )) -le "$IDLE_STOP" ]
}
sampler_running() { pid_ours "$(cat "$TMPD/sampler.pid" 2>/dev/null)" "$NAME.sh sampler"; }

sampler() {
	mkdir -p "$TMPD" "$(web_dir)"
	exec 8>"$TMPD/sampler.lock"
	flock -n 8 || exit 0                 # another sampler is already running
	lowprio
	echo $$ > "$TMPD/sampler.pid"
	trap 'node_stop_all; rm -f "$TMPD/sampler.pid"; exit 0' INT TERM
	sample_init
	write_node_script > "$TMPD/node.sh"
	rm -f "$TMPD"/node.*.fail "$TMPD"/node.*.start "$TMPD"/node.*.last
	WD=$(web_dir); seq=0; ms=0
	log "sampling started (page open)"
	export_names
	while hb_fresh; do
		t0=$(uptime_cs)
		if [ $((seq % 5)) -eq 0 ]; then
			links_json > "$TMPD/links.json"; macs_json > "$TMPD/macs.json"
		fi
		[ $((seq % 15)) -eq 14 ] && export_names
		[ $((seq % 30)) -eq 29 ] && sample_init      # nodes and radios can change while the page is open
		[ "$NODES" = on ] && nodes_tick
		sample_json "$seq" "$ms" | write_atomic "$WD/live.htm"
		ms=$(( ($(uptime_cs) - t0) * 10 ))
		seq=$((seq + 1))
		sleep "$INTERVAL"
	done
	node_stop_all
	rm -f "$TMPD/sampler.pid"
	log "sampling stopped (page closed)"
}

service_event() {   # action service
	[ "$1" = "start" ] || return 0
	case "$2" in
		"$NAME")
			mkdir -p "$TMPD"; touch "$TMPD/heartbeat"
			sampler_running || (sh "$SCRIPT" sampler < /dev/null > /dev/null 2>&1 &) ;;
		"${NAME}stop")
			rm -f "$TMPD/heartbeat" ;;
	esac
}

stop_all() {   # sampler and node sessions, e.g. before an update or uninstall
	p=$(cat "$TMPD/sampler.pid" 2>/dev/null)
	pid_ours "$p" "$NAME.sh sampler" && kill "$p" 2>/dev/null
	node_stop_all
	rm -f "$TMPD/sampler.pid" "$TMPD/heartbeat"
}

# ---- web UI (Merlin Addons API) ------------------------------------------------
menu_remount() {
	umount "$MENUTREE" 2>/dev/null
	mount -o bind "$TMP_MENUTREE" "$MENUTREE"
}

is_ours() { [ "$(cat "$WWW_USER/${1%.asp}.title" 2>/dev/null)" = "$TITLE" ]; }

# Pick a page slot: keep our previous slot if it's still free (stable URL), otherwise the
# first free userN.asp. Slots are identified as ours by their .title file; taken slots are skipped.
find_webui_page() {
	am_webui_page=none
	prev=$(cat "$ADDON_DIR/webui_page" 2>/dev/null)
	if [ -n "$prev" ] && { [ ! -f "$WWW_USER/$prev" ] || is_ours "$prev"; }; then
		am_webui_page=$prev; return
	fi
	i=1
	while [ $i -le 20 ]; do
		p="user$i.asp"
		if [ -f "$WWW_USER/$p" ]; then
			is_ours "$p" && { am_webui_page=$p; return; }
		elif [ "$am_webui_page" = none ]; then
			am_webui_page=$p
		fi
		i=$((i + 1))
	done
}

mount_webui() {
	[ -d "$WWW_USER" ] || { say "$WWW_USER not found - is this Asuswrt-Merlin with JFFS scripts enabled?"; return 1; }
	mkdir -p "$TMPD"
	exec 9>"$WEBUI_LOCK"; flock -x 9 2>/dev/null
	find_webui_page
	if [ "$am_webui_page" = "none" ]; then
		flock -u 9; say "No free web UI slot (Merlin allows 20 addon pages)."; log "no free webui page"; return 1
	fi
	# drop any other slot we held before (only if it is still ours)
	for f in "$WWW_USER"/user*.title; do
		[ -f "$f" ] || continue
		p="$(basename "$f" .title).asp"
		[ "$p" != "$am_webui_page" ] && is_ours "$p" && rm -f "$WWW_USER/$p" "$f"
	done
	cp -f "$PAGE_SRC" "$WWW_USER/$am_webui_page"
	echo "$TITLE" > "$WWW_USER/${am_webui_page%.asp}.title"
	[ "$(cat "$ADDON_DIR/webui_page" 2>/dev/null)" = "$am_webui_page" ] || echo "$am_webui_page" > "$ADDON_DIR/webui_page"
	# Menu: edit a copy, and only swap it in if the result is exactly our new lines at known anchors.
	# A broken menuTree.js would break the router's whole menu, so never risk it.
	[ -f "$TMP_MENUTREE" ] || cp -f "$MENUTREE" "$TMP_MENUTREE"
	new="$TMP_MENUTREE.$NAME.$$"
	sed "/tabName: \"$TITLE\"/d" "$TMP_MENUTREE" > "$new"
	before=$(wc -l < "$new")
	entry="{url: \"$am_webui_page\", tabName: \"$TITLE\"},"
	# Just before Traffic Monitor (the tabs after it inherit its name, so never after it). Merlin's
	# menu lists Traffic Monitor in two menus, Traffic Analyzer (models with Trend Micro's engine, like
	# the RT-AX86U) and Traffic Manager (the others), and shows one of them: Arteria goes in both.
	# Merlin's Tools menu is the fallback.
	where=""; added=0
	n=$(grep -c 'url: "Main_TrafficMonitor_realtime.asp"' "$new")
	if [ "$n" -ge 1 ] && [ "$n" -le 2 ]; then
		sed -i "/url: \"Main_TrafficMonitor_realtime.asp\"/i $entry" "$new"; added=$n
		case ",$(nvram get rc_support | tr ' ' ',')," in *,bwdpi,*) where="Traffic Analyzer" ;; *) where="Traffic Manager" ;; esac
	elif [ "$(grep -c 'url: "Tools_OtherSettings.asp"' "$new")" = 1 ]; then
		sed -i "/url: \"Tools_OtherSettings.asp\"/a $entry" "$new"; added=1; where="Tools"
	fi
	if [ -n "$where" ] && [ "$(grep -c "tabName: \"$TITLE\"" "$new")" = "$added" ] && [ "$(wc -l < "$new")" -eq $((before + added)) ]; then
		mv -f "$new" "$TMP_MENUTREE"
		menu_remount
		echo "$where" > "$TMPD/menu_where"
	else
		rm -f "$new" "$TMPD/menu_where"
		say "Couldn't add the menu entry safely, so the menu was left alone. Open http://$(nvram get lan_ipaddr)/$am_webui_page instead."
		log "menu entry not added (unexpected menuTree.js); page at $am_webui_page"
	fi
	flock -u 9
	mkdir -p "$(web_dir)"
	log "web UI mounted as $am_webui_page"
}

unmount_webui() {
	page=$(cat "$ADDON_DIR/webui_page" 2>/dev/null)
	exec 9>"$WEBUI_LOCK"; flock -x 9 2>/dev/null
	if [ -f "$TMP_MENUTREE" ]; then
		sed -i "/tabName: \"$TITLE\"/d" "$TMP_MENUTREE"
		menu_remount
	fi
	[ -n "$page" ] && is_ours "$page" && rm -f "$WWW_USER/$page" "$WWW_USER/${page%.asp}.title"
	flock -u 9
}

hook_add() {   # file line
	f="$SCRIPTS_DIR/$1"
	[ -s "$f" ] || printf '#!/bin/sh\n' > "$f"   # missing or empty
	head -1 "$f" | grep -q '^#!' || sed -i '1i #!/bin/sh' "$f"
	hook_del "$1"
	[ -n "$(tail -c 1 "$f")" ] && echo >> "$f"   # never glue onto a last line with no newline
	printf '%s # %s\n' "$2" "$NAME" >> "$f"
	chmod 755 "$f"
}

hook_del() {   # only lines this addon wrote: start with our script path, end with our tag
	f="$SCRIPTS_DIR/$1"
	[ -f "$f" ] && sed -i "\\|^$SCRIPT .*# $NAME\$|d" "$f"
	return 0
}

startup() {
	mkdir -p "$TMPD"
	stop_all          # a sampler can't survive a reboot, but an update replaces it
	mount_webui
	return 0
}

write_conf() {
	cat > "$CONF" <<EOF
# Arteria settings - run "$SCRIPT startup" after editing
INTERVAL=$INTERVAL               # seconds between samples while the page is open (1-10)
IDLE_STOP=$IDLE_STOP             # stop sampling this many seconds after the last page closed (10-300)
NODES=$NODES               # on: read each AiMesh node's per-device counters over SSH; off: backhaul totals only
NODE_USER="$NODE_USER"            # SSH user on the nodes; empty = the router's admin name
AMTM_UPDATE=$AMTM_UPDATE         # on: amtm may update Arteria (amtmupdate); off: only 'update' does
EOF
}

# ---- AiMesh node access (an SSH key only the router holds) -------------------------
make_key() {
	mkdir -p "$ADDON_DIR"
	rm -f "$KEY.new"
	dropbearkey -t ed25519 -f "$KEY.new" > /dev/null 2>&1 || dropbearkey -t rsa -s 2048 -f "$KEY.new" > /dev/null 2>&1 || return 1
	chmod 600 "$KEY.new" && mv -f "$KEY.new" "$KEY"
}
pub_key() { dropbearkey -y -f "$KEY" 2>/dev/null | awk '/^ssh-/ { print $1, $2, "arteria"; exit }'; }

# Try the key on a node: key only, never a password (see ssh_batch). Gives up after 8 s.
# Returns 0 if the key works, 1 if not, 2 if it can't be tried without risking a password prompt
# (an older dbclient, run from a terminal).
node_try() {   # ip
	mkdir -p "$TMPD"; ssh_home; o="$TMPD/try.$$"; TRY_ERR=""
	b=$(ssh_batch)
	if [ -z "$b" ] && has_tty; then TRY_ERR="this firmware's SSH client can't try a key without offering a password"; return 2; fi
	(HOME="$SSH_HOME" exec dbclient $b -y -p "$(ssh_port)" -i "$KEY" "$(ssh_user)@$1" 'echo arteria-ok') \
		< /dev/null > "$o" 2>&1 &
	p=$!; i=0
	while kill -0 "$p" 2>/dev/null; do
		[ $i -ge 8 ] && { kill "$p" 2>/dev/null; break; }
		sleep 1; i=$((i + 1))
	done
	grep -q '^arteria-ok' "$o" 2>/dev/null; rc=$?
	TRY_ERR=$(grep -v '^arteria-ok' "$o" 2>/dev/null | tail -1 | cut -c1-120)
	rm -f "$o"
	return $rc
}

nodes_cmd() {   # [test]
	if [ "$NODES" != on ]; then say "Reading AiMesh nodes is off (NODES=off in $CONF): the page shows backhaul totals only."; fi
	list=$(node_list)
	if [ -z "$list" ]; then say "No AiMesh nodes found."; return 0; fi
	say "AiMesh nodes (SSH port $(ssh_port), user $(ssh_user)):"
	printf '%s\n' "$list" | while read -r mac ip model; do
		al=$(node_alias "$mac")
		line="  ${al:-$model} ($model, $ip)"
		if [ "$1" = test ]; then
			if [ ! -s "$KEY" ]; then line="$line: no key yet, run '$SCRIPT nodekey'"
			else
				node_try "$ip"; rc=$?
				if [ $rc -eq 0 ]; then line="$line: key login OK"
				elif [ $rc -eq 2 ]; then line="$line: can't test here ($TRY_ERR); open the page, it shows whether the node answers"
				else line="$line: key login failed${TRY_ERR:+ ($TRY_ERR)}; run '$SCRIPT nodekey'"
				fi
			fi
		else
			line="$line: $(node_state "$(node_file "$mac")")"
		fi
		say "$line"
	done
}

# Give each node the router's Arteria key. Asks for the node's password once (the router's admin
# password, which AiMesh nodes share); it goes to the node only and is never stored. The key is
# added to the node's authorized keys, keeping any that are already there.
nodekey() {   # [node-ip]
	have dbclient && have dropbearkey || die "This firmware has no SSH client (dbclient/dropbearkey)."
	[ "$(nvram get sshd_enable)" = "0" ] && die "SSH is off on the router (Administration > System > Enable SSH). AiMesh nodes follow that setting: turn it on (LAN only is enough) and try again."
	[ -t 0 ] || die "nodekey asks for each node's password, so run it in a terminal."
	[ -s "$KEY" ] || make_key || die "Couldn't create the key in $KEY"
	pub=$(pub_key); b64=$(printf '%s' "$pub" | cut -d' ' -f2)
	[ -n "$b64" ] || die "Couldn't read the public key from $KEY"
	ssh_home
	list=$(node_list)
	[ -n "$1" ] && list=$(printf '%s\n' "$list" | awk -v ip="$1" '$2 == ip')
	[ -n "$list" ] || die "No AiMesh node${1:+ at $1} found."
	fails=0
	# the remote side: add the key unless it's there, then restart its SSH server (after we've disconnected)
	cmd="k='$pub'; c=\$(nvram get sshd_authkeys); case \"\$c\" in *'$b64'*) echo arteria-had-key ;; *) nvram set sshd_authkeys=\"\${c:+\$c
}\$k\"; nvram commit; echo arteria-added-key; (sleep 2; service restart_sshd) > /dev/null 2>&1 & ;; esac"
	printf '%s\n' "$list" > "$TMPD/nodekey.list"
	while read -r mac ip model; do
		al=$(node_alias "$mac")
		say ""
		say "${al:-$model} ($model, $ip)"
		# a node that was reset has a new host key: forget the old one so it can be pinned again
		[ -f "$SSH_HOME/.ssh/known_hosts" ] && sed -i "/^$ip /d; /^\[$ip\]:/d" "$SSH_HOME/.ssh/known_hosts"
		node_try "$ip"; rc=$?
		if [ $rc -eq 0 ]; then say "  Already has the key."; continue; fi
		say "  Enter the node's password (your router's admin password). It goes to the node only and isn't stored."
		out=$(HOME="$SSH_HOME" dbclient -y -p "$(ssh_port)" "$(ssh_user)@$ip" "$cmd" < /dev/tty 2>&1)
		case "$out" in
			*arteria-had-key*)   say "  The node already listed the key." ;;
			*arteria-added-key*) say "  Key added."; sleep 4 ;;
			*) say "  Couldn't log in: $(printf '%s' "$out" | tail -1 | cut -c1-120)"; fails=$((fails + 1)); continue ;;
		esac
		node_try "$ip"; rc=$?
		if [ $rc -eq 0 ]; then say "  Key login works."
		elif [ $rc -eq 2 ]; then say "  Can't test the key from here; open the page: it shows whether the node answers."
		else say "  The key still doesn't work${TRY_ERR:+ ($TRY_ERR)}."; fails=$((fails + 1))
		fi
	done < "$TMPD/nodekey.list"
	rm -f "$TMPD/nodekey.list" "$TMPD"/node.*.fail
	say ""
	[ $fails -eq 0 ] && say "Done. Reopen the page to see each node's devices." && return 0
	say "$fails node(s) not set up. Check that SSH is on, the password is right, and run '$SCRIPT nodekey' again."
	return 1
}

# ---- support check (read-only: changes nothing on the router) ------------------
ck_ok()   { say "  [ OK ] $*"; }
ck_warn() { say "  [WARN] $*"; }
ck_fail() { say "  [FAIL] $*"; ck_fails=$((ck_fails + 1)); }

free_kb() { df -Pk "$1" 2>/dev/null | awk 'NR == 2 { print $4 }'; }

check_support() {
	ck_fails=0
	say "Checking that this router can run $TITLE:"

	if [ "$(uname -o 2>/dev/null)" = "ASUSWRT-Merlin" ]; then
		ck_ok "Asuswrt-Merlin $(fw_version)"
	else
		ck_fail "Not Asuswrt-Merlin firmware. Stock ASUS firmware can't run addons."
	fi
	if [ -f "$HELPER" ] && grep -q 'am_settings_get' "$HELPER" 2>/dev/null && [ -e "$WWW_USER" ] && [ -f "$MENUTREE" ]; then
		ck_ok "Addons API (web pages)"
	else
		ck_fail "This firmware has no Addons API. Update to Asuswrt-Merlin 386 or newer."
	fi

	# Broadcom driver: per-client byte counters
	if ! have wl; then
		ck_fail "No Broadcom Wi-Fi driver ('wl' not found). Only Broadcom-based models are supported."
	else
		RADIOS=$(radio_list | tr '\n' ' ')
		[ -n "$RADIOS" ] || ck_fail "No Wi-Fi radios found."
		up=0; probe=""
		for p in $RADIOS; do
			x=${p%%:*}
			case "$x" in *.*) continue ;; esac
			[ "$(wl -i "$x" isup 2>/dev/null)" = "1" ] && up=$((up + 1))
			[ -n "$probe" ] || probe=$(wl -i "$x" assoclist 2>/dev/null | cut -d' ' -f2 | head -1 | sed "s/^/$x /")
		done
		[ $up -gt 0 ] || ck_warn "No Wi-Fi radio is switched on."
		if [ -n "$probe" ]; then
			set -- $probe
			row=$( { echo "@ $1 0 $2"; wl -i "$1" sta_info "$2" 2>/dev/null; } | awk "$STA_AWK")
			set -- $row
			case "$5:$6" in
				*-*|:) ck_warn "This driver's per-client counters look different. Please report it with the output of 'debug'." ;;
				*) ck_ok "Per-client Wi-Fi counters (wl sta_info)" ;;
			esac
		else
			ck_warn "No Wi-Fi clients right now, so the per-client counters couldn't be checked."
		fi
	fi
	w=$(wan_if)
	if [ -n "$w" ] && grep -q "^ *$w:" "$PROC/net/dev"; then ck_ok "WAN counters ($w)"
	else ck_warn "WAN interface '${w:-?}' not found in $PROC/net/dev: internet totals will be missing."
	fi

	# Shell tools the addon relies on (router BusyBox builds vary)
	t="$ROOT/tmp/$NAME.selftest.$$"; printf 'ab' > "$t" 2>/dev/null; lack=""
	[ "$(tail -c 1 "$t" 2>/dev/null)" = "b" ] || lack="$lack tail-c"
	date -r "$t" +%s >/dev/null 2>&1 || lack="$lack date-r"
	[ -n "$(readlink -f "$ROOT/tmp" 2>/dev/null)" ] || lack="$lack readlink-f"
	[ "$(printf 'x\n' | sed 's/x/y/')" = "y" ] && [ "$(echo 1 | awk '{ print toupper("a") $1 + 1 }')" = "A2" ] || lack="$lack sed/awk"
	[ "$(printf 'a\tb' | tr -d '\000-\037')" = "ab" ] || lack="$lack tr"
	for p in flock brctl; do have "$p" || lack="$lack $p"; done
	rm -f "$t"
	if [ -z "$lack" ]; then ck_ok "Shell tools (BusyBox)"
	else ck_fail "This firmware's BusyBox lacks:$lack"
	fi

	# AiMesh nodes (optional)
	nl=$(node_list)
	if [ -z "$nl" ]; then
		ck_ok "No AiMesh nodes (the map shows the router and its clients)"
	elif ! have dbclient || ! have dropbearkey; then
		ck_warn "AiMesh nodes found, but no SSH client: the map shows their backhaul totals only."
	else
		n=$(printf '%s\n' "$nl" | wc -l | tr -d ' ')
		ck_ok "$n AiMesh node(s): $(printf '%s\n' "$nl" | awk '{ $1 = ""; $2 = ""; sub(/^ +/, ""); printf "%s%s", (c++ ? ", " : ""), $0 }')"
		[ "$(nvram get sshd_enable)" = "0" ] && ck_warn "SSH is off on the router, so nodes can't be read per device (Administration > System > Enable SSH, LAN only is enough)."
	fi

	jkb=$(free_kb "$ROOT/jffs")
	if [ ! -d "$ROOT/jffs" ]; then ck_fail "The JFFS partition isn't available."
	elif [ "${jkb:-0}" -lt 512 ]; then ck_fail "Less than 512 KB free on JFFS."
	else ck_ok "JFFS space ($(awk -v k="$jkb" 'BEGIN { print int(k / 1024) }') MB free)"
	fi
	find_webui_page
	if [ "$am_webui_page" = none ]; then
		ck_fail "No free addon page slot (all 20 are used by other addons)."
	else
		ck_ok "Addon page slot: $am_webui_page"
	fi
	[ "$(nvram get jffs2_scripts)" = "1" ] || ck_warn "'JFFS custom scripts and configs' is off. Install will switch it on."

	say ""
	if [ $ck_fails -gt 0 ]; then say "This router can't run $TITLE ($ck_fails problem(s) above)."; return 1; fi
	say "This router can run $TITLE."
	return 0
}

# ---- install / update / uninstall ------------------------------------------------------
asp_matches() { [ -s "$1" ] && grep -q "arteria-version: $VERSION " "$1"; }

# Download $1 to $2 [quiet]. Up to 3 attempts; succeeds only if a non-empty file arrived.
fetch() {
	for attempt in 1 2 3; do
		rm -f "$2" 2>/dev/null; mkdir -p "$(dirname "$2")"
		code=$(curl -sL --retry 2 --connect-timeout 15 -w '%{http_code}' -o "$2" "$1" 2>/dev/null); rc=$?
		if [ $rc -eq 23 ]; then why="couldn't write $2"
		elif [ $rc -ne 0 ]; then why="curl error $rc"
		elif [ "$code" != "200" ]; then why="HTTP $code"
		elif [ ! -s "$2" ]; then why="empty response"
		else return 0
		fi
		[ "$code" = "404" ] && break
		[ $attempt -lt 3 ] && sleep 2
	done
	[ "$3" = quiet ] || say "  download failed ($why): $1"
	rm -f "$2" 2>/dev/null; return 1
}

latest_tag() {
	t=$(curl -fsL --retry 2 --connect-timeout 15 -H 'Accept: application/vnd.github+json' \
		"https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
		| sed -n 's/.*"tag_name": *"\([0-9][0-9.]*\)".*/\1/p' | head -1)
	[ -n "$t" ] || t=$(curl -fsI --retry 2 --connect-timeout 15 -o /dev/null -w '%{redirect_url}' \
		"https://github.com/$REPO/releases/latest" 2>/dev/null \
		| sed -n 's#.*/releases/tag/\([0-9][0-9.]*\)$#\1#p')
	echo "$t"
}
release_url() {
	[ -n "$AR_RAW_URL" ] && { echo "$RAW_URL"; return; }
	t=$(latest_tag); [ -n "$t" ] && echo "$RAW_BASE/$t"
}
ver_gt() {   # true if version $1 is newer than $2 (1.0.10 > 1.0.9)
	awk -v a="$1" -v b="$2" 'BEGIN { n = split(a, x, "."); m = split(b, y, "."); if (m > n) n = m
		for (i = 1; i <= n; i++) { if (x[i] + 0 > y[i] + 0) exit 0; if (x[i] + 0 < y[i] + 0) exit 1 }
		exit 1 }'
}

install() {
	src="$(cd "$(dirname "$0")" && pwd)"
	say "Installing $TITLE $VERSION"
	say ""
	check_support || die "Nothing was installed or changed."
	say ""
	if [ "$(nvram get jffs2_scripts)" != "1" ]; then
		nvram set jffs2_scripts=1; nvram commit
		say "Enabled 'JFFS custom scripts and configs' (needed so the addon survives reboots)."
	fi
	mkdir -p "$ADDON_DIR" "$SCRIPTS_DIR" "$TMPD"
	if [ "$src" != "$ADDON_DIR" ]; then
		asp="$src/$NAME.asp"
		if ! asp_matches "$asp"; then   # missing, or left over from another version
			say "Downloading the web page from GitHub..."
			asp="$TMPD/$NAME.asp.dl"; got=0
			if [ -n "$AR_RAW_URL" ]; then bases="$RAW_URL"; else bases="$RAW_BASE/$VERSION $RAW_URL"; fi
			for base in $bases release; do
				[ "$base" = release ] && { base=$(release_url); [ -n "$base" ] || continue; }
				if fetch "$base/$NAME.asp" "$asp" quiet; then
					asp_matches "$asp" && { got=1; break; }
				fi
			done
			[ $got -eq 1 ] || { rm -f "$asp"; die "Couldn't get $NAME.asp $VERSION. Put it in the same folder as $NAME.sh and run install again."; }
		fi
		stop_all
		# rename into place: a running copy of the old script (e.g. during update) keeps reading its own file
		cp -f "$src/$NAME.sh" "$SCRIPT.new" && mv -f "$SCRIPT.new" "$SCRIPT"
		cp -f "$asp" "$PAGE_SRC.new" && mv -f "$PAGE_SRC.new" "$PAGE_SRC"
		rm -f "$TMPD/$NAME.asp.dl"
	fi
	chmod 755 "$SCRIPT"
	if [ -n "$AR_BUILD" ]; then printf '%s\n' "$AR_BUILD" > "$BUILD_FILE"; else rm -f "$BUILD_FILE"; fi
	[ -f "$CONF" ] || write_conf
	hook_add services-start "$SCRIPT startup &"
	hook_add service-event "$SCRIPT service_event \"\$@\" &"
	startup

	# AiMesh nodes: per-device counters need the router's key on each node
	nl=""
	[ "$NODES" = on ] && have dbclient && have dropbearkey && nl=$(node_list)
	if [ -n "$nl" ]; then
		[ -s "$KEY" ] || make_key || say "Couldn't create the SSH key for the nodes."
		missing=""
		printf '%s\n' "$nl" > "$TMPD/install.nodes"
		while read -r mac ip model; do
			node_try "$ip" || missing="$missing $ip"
		done < "$TMPD/install.nodes"
		rm -f "$TMPD/install.nodes"
		say ""
		if [ -z "$missing" ]; then
			say "AiMesh nodes: key login works, so the map shows each node's devices."
		else
			say "Arteria reads each AiMesh node's devices over SSH, with a key only the router holds."
			say "Node(s) without the key yet:$missing"
			if [ -t 0 ] && [ -t 1 ]; then
				printf 'Give them the key now? You will be asked for the router admin password once per node. (y/n) '
				read -r a
				case "$a" in [yY]*) nodekey || true ;; *) say "Run '$SCRIPT nodekey' any time. Until then the map shows the nodes' totals." ;; esac
			else
				say "Run '$SCRIPT nodekey' in a terminal. Until then the map shows the nodes' totals."
			fi
		fi
	fi

	page=$(cat "$ADDON_DIR/webui_page" 2>/dev/null)
	where=$(cat "$TMPD/menu_where" 2>/dev/null)
	say ""
	if [ -n "$where" ]; then
		say "Done. Open the router UI -> $where -> $TITLE"
		say "(If the tab isn't there, reload the page with Ctrl+F5 / Cmd+Shift+R: browsers cache the menu.)"
	else
		say "Done."
	fi
	[ -n "$page" ] && say "Direct link: http://$(nvram get lan_ipaddr)/$page"
	say "Arteria samples only while that page is open, and stops about $IDLE_STOP seconds after you leave it."
}

update() {   # [force]  fetch the latest release from GitHub and reinstall over this one
	dl="$TMPD/update.$$"; rm -rf "$dl"; mkdir -p "$dl" || die "Couldn't create $dl"
	say "Checking GitHub for updates..."
	rel=$(release_url)
	[ -n "$rel" ] || { rm -rf "$dl"; die "Couldn't find the latest release on GitHub (no connection to github.com?); nothing was changed."; }
	fetch "$rel/$NAME.sh" "$dl/$NAME.sh" || { rm -rf "$dl"; die "Couldn't download the update; nothing was changed."; }
	new=$(sed -n 's/^VERSION="\([0-9][0-9.]*\)".*/\1/p' "$dl/$NAME.sh" | head -1)
	if [ -z "$new" ] || ! sh -n "$dl/$NAME.sh" 2>/dev/null; then
		rm -rf "$dl"; die "The downloaded script looks incomplete; nothing was changed."
	fi
	if [ "$new" = "$VERSION" ] && [ "$1" != "force" ] && [ ! -f "$BUILD_FILE" ]; then
		rm -rf "$dl"; say "Already up to date ($VERSION)."; return 0
	fi
	if ver_gt "$VERSION" "$new" && [ "$1" != "force" ]; then
		rm -rf "$dl"
		say "This is $VERSION$( [ -f "$BUILD_FILE" ] && printf ' (a development version)'), newer than the latest release ($new). Nothing was changed; 'update force' installs $new."
		return 0
	fi
	if ! fetch "$rel/$NAME.asp" "$dl/$NAME.asp" || ! grep -q "arteria-version: $new " "$dl/$NAME.asp"; then
		rm -rf "$dl"; die "Couldn't download the matching web page; nothing was changed."
	fi
	say "Updating $VERSION -> $new (settings and node access are kept)"
	sh "$dl/$NAME.sh" install < /dev/null; rc=$?
	rm -rf "$dl"
	[ $rc -eq 0 ] && rm -f "$BUILD_FILE"
	return $rc
}

build_text() {   # "" for a release; "development version: main @ 1a2b3c4, installed 2026-11-11 23:30"
	[ -f "$BUILD_FILE" ] || return 0
	read -r kind br sha when < "$BUILD_FILE"
	[ "$kind" = dev ] && printf 'development version: %s @ %s, installed %s' "$br" "$sha" "$when"
}
update_dev() {   # [branch]
	br=${1:-main}
	case "$br" in ''|[-./]*|*..*|*//*|*/|*[!A-Za-z0-9._/-]*|refs/*|pull/*) die "'$br' isn't a branch name; nothing was changed." ;; esac
	dl="$TMPD/update.$$"; rm -rf "$dl"; mkdir -p "$dl" || die "Couldn't create $dl"
	say "Looking up the newest commit on $br..."
	# Only a branch of this repository, by its commit. GitHub also serves commits and pull requests
	# from other people's forks under this repository's addresses, and those aren't reviewed here.
	sha=$(curl -fsL --retry 2 --connect-timeout 15 -H 'Accept: application/vnd.github+json' \
		"https://api.github.com/repos/$REPO/branches/$br" 2>/dev/null \
		| grep -o '"sha": *"[0-9a-f]\{40\}"' | head -1 | grep -o '[0-9a-f]\{40\}')
	[ -n "$sha" ] || { rm -rf "$dl"; die "GitHub has no branch '$br' in $REPO, or couldn't be reached; nothing was changed."; }
	fetch "$RAW_BASE/$sha/$NAME.sh" "$dl/$NAME.sh" quiet || { rm -rf "$dl"; die "Couldn't download $NAME.sh from '$br'; nothing was changed."; }
	new=$(sed -n 's/^VERSION="\([0-9][0-9.]*\)".*/\1/p' "$dl/$NAME.sh" | head -1)
	if [ -z "$new" ] || ! sh -n "$dl/$NAME.sh" 2>/dev/null; then
		rm -rf "$dl"; die "The script on '$br' looks incomplete; nothing was changed."
	fi
	if ! fetch "$RAW_BASE/$sha/$NAME.asp" "$dl/$NAME.asp" quiet || ! grep -q "arteria-version: $new " "$dl/$NAME.asp"; then
		rm -rf "$dl"; die "Couldn't download the matching web page from '$br'; nothing was changed."
	fi
	short=$(printf '%s' "$sha" | cut -c1-7)
	say "Installing the development version of $br ($new, commit $short). Settings and node access are kept;"
	say "'$SCRIPT update' goes back to the latest release."
	b="dev $br $short $(date '+%Y-%m-%d %H:%M')"
	AR_BUILD="$b" sh "$dl/$NAME.sh" install < /dev/null; rc=$?
	rm -rf "$dl"
	if [ $rc -eq 0 ]; then
		printf '%s\n' "$b" > "$BUILD_FILE"
		log "development version installed: $br @ $short ($new)"
	fi
	return $rc
}

uninstall() {
	say "Removing $TITLE"
	stop_all
	unmount_webui
	hook_del services-start
	hook_del service-event
	rm -rf "$(web_dir)" "$TMPD" "$ADDON_DIR"
	say "Removed. The router's key for the nodes was deleted with it; the copy each node lists under"
	say "its authorized keys no longer opens anything and goes away if the node is reset."
}

status() {
	say "$TITLE $VERSION$(b=$(build_text); [ -n "$b" ] && printf ' (%s)' "$b")"
	say "Web page:    $(cat "$ADDON_DIR/webui_page" 2>/dev/null || echo 'not mounted')"
	if sampler_running; then
		live="$(web_dir)/live.htm"
		ms=$(sed -n 's/.*"ms":\([0-9]*\).*/\1/p' "$live" 2>/dev/null | head -1)
		say "Sampling:    yes, the page is open (every $INTERVAL s${ms:+, last sample took $ms ms})"
	else
		say "Sampling:    no (starts when the page opens, stops ${IDLE_STOP} s after it closes)"
	fi
	say "Node access: $NODES$( [ "$NODES" = on ] && { [ -s "$KEY" ] && printf ', key present' || printf ", no key yet ('nodekey' creates it)"; })"
	nl=$(node_list)
	[ -n "$nl" ] && say "Nodes:       $(printf '%s\n' "$nl" | awk '{ $1 = ""; $2 = ""; sub(/^ +/, ""); printf "%s%s", (c++ ? ", " : ""), $0 }') (details: '$SCRIPT nodes test')"
	say "amtm updates: $AMTM_UPDATE"
}

# Everything a bug report needs, and nothing personal: no device names, no MAC or IP addresses.
debug() {
	say "$TITLE $VERSION$(b=$(build_text); [ -n "$b" ] && printf ' (%s)' "$b")"
	say "Router:      $(nvram get productid) $(nvram get odmpid)  firmware $(fw_version)  $(uname -m)"
	say "BusyBox:     $(busybox 2>/dev/null | head -1 | cut -d' ' -f2)   dbclient: $(have dbclient && echo yes || echo no)   dropbearkey: $(have dropbearkey && echo yes || echo no)"
	say "Settings:    INTERVAL=$INTERVAL IDLE_STOP=$IDLE_STOP NODES=$NODES amtm=$AMTM_UPDATE"
	say "WAN:         $(wan_if) ($(nvram get wan0_proto))"
	for p in $(radio_list); do
		x=${p%%:*}
		say "Wi-Fi:       $x band ${p#*:} GHz, up=$(wl -i "$x" isup 2>/dev/null), clients=$(wl -i "$x" assoclist 2>/dev/null | wc -l | tr -d ' ')"
	done
	for p in $(lan_ports); do
		say "Port:        $p carrier=$(cat "$SYSNET/$p/carrier" 2>/dev/null) speed=$(cat "$SYSNET/$p/speed" 2>/dev/null)"
	done
	say "WDS links:   $(grep -c '^ *wds' "$PROC/net/dev")"
	nl=$(node_list)
	say "Nodes:       $(printf '%s\n' "$nl" | grep -c .) $(printf '%s\n' "$nl" | awk '{ printf "%s%s", (c++ ? "," : ""), $3 }')   ssh port: $(ssh_port)   sshd_enable: $(nvram get sshd_enable)"
	printf '%s\n' "$nl" | while read -r mac ip model; do
		[ -n "$mac" ] || continue
		say "  $model: backhaul stations=$(node_stas "$mac" | wc -w | tr -d ' ') state=$(node_state "$(node_file "$mac")")"
	done
	# the first client's sta_info field names (the values are counters only)
	for p in $(radio_list); do
		x=${p%%:*}; m=$(wl -i "$x" assoclist 2>/dev/null | cut -d' ' -f2 | head -1)
		[ -n "$m" ] || continue
		say "sta_info fields ($x):"
		wl -i "$x" sta_info "$m" 2>/dev/null | sed 's/[0-9A-Fa-f][0-9A-Fa-f]:[0-9A-Fa-f:]*/xx:xx/g; s/^/  /' | head -40
		break
	done
	live="$(web_dir)/live.htm"
	[ -f "$live" ] && say "Last sample: $(sed -n 's/.*"ms":\([0-9]*\).*/\1/p' "$live" | head -1) ms, $(( $(now) - $(date -r "$live" +%s) )) s ago"
}

# ---- amtm and the menu ----------------------------------------------------------
# amtm (the Asuswrt-Merlin Terminal Menu) updates scripts that answer "amtmupdate". It runs
# "amtmupdate check" (exit 0: amtm may update it, 1: the user turned that off), and when a newer
# release is out, "amtmupdate", expecting a line or two and exit 0 on success, 1 on failure.
amtm_update() {   # [check]
	if [ "$1" = check ]; then [ "$AMTM_UPDATE" = on ]; return; fi
	if [ "$AMTM_UPDATE" != on ]; then
		say "  ✖  $TITLE: updates through amtm are turned off (AMTM_UPDATE=off). '$SCRIPT update' still works."
		return 1
	fi
	say "  i  Running function amtmupdate"
	mkdir -p "$TMPD"; alog="$TMPD/amtmupdate.log"
	( update ) > "$alog" 2>&1; rc=$?
	now_ver=$(sed -n 's/^VERSION="\([0-9][0-9.]*\)".*/\1/p' "$SCRIPT" 2>/dev/null | head -1)
	if [ $rc -eq 0 ]; then
		say "  ✔  $TITLE ${now_ver:-$VERSION} amtmupdate complete"
		log "amtmupdate: $VERSION -> ${now_ver:-$VERSION}"
	else
		why=$(grep -v '^[[:space:]]*$' "$alog" | tail -1 | sed 's/^ERROR: //' | cut -c1-100)
		say "  ✖  $TITLE amtmupdate failed: ${why:-no output} (details in $alog)"
		log "amtmupdate failed: $why"
	fi
	return $rc
}

usage() {
	say "Usage: $0 [menu] | install | check | update [force | dev [branch]] | uninstall | status |"
	say "       nodes [test] | nodekey [node-ip] | debug | sample | amtmupdate [check] | startup | version"
}
menu_pause() { printf '\n Press Enter to go back to the menu '; read -r dummy || exit 0; }
menu_uninstall() {   # true once removed
	printf ' Remove %s? Type yes to confirm: ' "$TITLE"; read -r a || return 1
	if [ "$a" != yes ]; then say " Nothing was removed."; menu_pause; return 1; fi
	uninstall
	return 0
}
# Run with no arguments in a terminal (which is how amtm opens it). Each action runs in a subshell,
# so one that stops with an error returns to the menu instead of closing it.
menu() {
	while :; do
		have clear && clear
		page=$(cat "$ADDON_DIR/webui_page" 2>/dev/null)
		where=$(cat "$TMPD/menu_where" 2>/dev/null)
		say ""
		say " $TITLE $VERSION${page:+   (${where:-Tools} > $TITLE, $page)}"
		b=$(build_text); [ -n "$b" ] && say " This is a $b"
		say " Sampling:     $(sampler_running && echo 'now (the page is open)' || echo 'only while the page is open')"
		say " Node access:  $NODES"
		say " amtm updates: $AMTM_UPDATE"
		say ""
		say "  1  Status"
		say "  2  AiMesh nodes: test key login"
		say "  3  AiMesh nodes: give them the key (asks each node's password once)"
		say "  4  Update to the latest release"
		say "  5  Reinstall the latest release"
		say "  6  Debug report, for bug reports (no names or addresses)"
		say "  7  Turn amtm updates $( [ "$AMTM_UPDATE" = on ] && printf off || printf on)"
		say "  8  Development version from GitHub, for testing unreleased changes"
		say "  9  Uninstall"
		say "  e  Exit"
		printf '\n Choose an option: '
		read -r opt || { say ""; return 0; }
		say ""
		case "$opt" in
			1) ( status ); menu_pause ;;
			2) ( nodes_cmd test ); menu_pause ;;
			3) ( nodekey ); menu_pause ;;
			4|5|8)
				before=$(md5sum < "$SCRIPT" 2>/dev/null)
				if [ "$opt" = 8 ]; then
					say " Development versions are unreleased and can be broken. Option 4 goes back to the latest release."
					printf ' Branch (Enter for main, e to go back): '; read -r br || br=e
					case "$br" in e|E) continue ;; esac
					( update_dev "${br:-main}" )
				elif [ "$opt" = 5 ]; then ( update force ); else ( update ); fi
				menu_pause
				# the update replaced this script: carry on in the new one
				[ -f "$SCRIPT" ] && [ "$(md5sum < "$SCRIPT" 2>/dev/null)" != "$before" ] && exec sh "$SCRIPT" menu ;;
			6) ( debug ); menu_pause ;;
			7)
				if [ "$AMTM_UPDATE" = on ]; then AMTM_UPDATE=off; else AMTM_UPDATE=on; fi
				write_conf; log "amtm updates turned $AMTM_UPDATE" ;;
			9) menu_uninstall && return 0 ;;
			e|E|q|Q) return 0 ;;
			'') ;;
			*) say " $opt isn't an option."; menu_pause ;;
		esac
	done
}

case "$1" in
	'')            if [ -t 0 ] && [ -t 1 ]; then menu; else usage; fi ;;
	menu)          menu ;;
	install)       install ;;
	update)        if [ "$2" = dev ]; then update_dev "$3"; else update "$2"; fi; exit $? ;;
	check)         check_support; exit $? ;;
	uninstall)     uninstall ;;
	startup)       startup ;;
	sampler)       sampler ;;
	sample)        mkdir -p "$TMPD"; sample_init; links_json > "$TMPD/links.json"; macs_json > "$TMPD/macs.json"; sample_json 0 0; echo ;;
	service_event) service_event "$2" "$3" ;;
	nodes)         nodes_cmd "$2" ;;
	nodekey)       nodekey "$2"; exit $? ;;
	status)        status ;;
	debug)         debug ;;
	version)       say "$VERSION" ;;
	amtmupdate)    amtm_update "$2"; exit $? ;;
	*)             usage ;;
esac
