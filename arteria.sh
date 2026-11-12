#!/bin/sh
###############################################################################
#  Arteria for Asuswrt-Merlin
#  A live, animated map of how traffic flows between the internet, the router,
#  its AiMesh nodes and every client. It only samples while its page is open.
#
#  Page: Traffic Analyzer -> Arteria, or Network Tools -> Arteria without Traffic Analyzer (two views: Map and Flow)
#
#  Usage: arteria.sh                    (a menu, when run in a terminal: amtm opens this)
#         arteria.sh install | update [force | dev [branch]] | uninstall | status | check |
#                    nodes [test] | nodekey [node-ip | print] | fingerbank [off | now | compare] | debug | sample |
#                    amtmupdate [check] | startup | version
#
#  Install:  d=/tmp/arteria-install; rm -rf "$d" && mkdir -m 700 "$d" && curl -fsL --retry 3 \
#              https://github.com/IfSugar/arteria/releases/latest/download/arteria.sh -o "$d/arteria.sh" && sh "$d/arteria.sh" install
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
FB_KEY="$ADDON_DIR/fingerbank_key"   # your own Fingerbank API key, when you turned device recognition on
FB_CACHE="$ADDON_DIR/fingerbank"     # Fingerbank's answers, one line per question (see fb_keys)
DISC="$ADDON_DIR/discovered"         # what devices said about themselves when asked (Recognise now), by MAC
FB_URL="https://api.fingerbank.org/api/v2/combinations/interrogate"
DHCP_FP="$TMPD/dhcp_fp"              # each device's DHCP fingerprint, in RAM: "MAC options vendor-class"
DNSMASQ_CONF="$ROOT/etc/dnsmasq.conf"
REPO="IfSugar/arteria"
RAW_BASE="https://raw.githubusercontent.com/$REPO"
RAW_URL="${AR_RAW_URL:-$RAW_BASE/main}"   # AR_RAW_URL: test hook only

[ -z "$ROOT" ] && PATH="/sbin:/bin:/usr/sbin:/usr/bin:$PATH:/opt/bin:/opt/sbin"
export PATH

# ---- defaults (overridden by $CONF) ----------------------------------------
INTERVAL=2              # seconds between samples while the page is open (1-10)
IDLE_STOP=20            # stop sampling this many seconds after the last page closed (20-300)
NODES=on                # on: read each AiMesh node's per-device counters over SSH; off: backhaul totals only
NODE_USER=""            # SSH user on the nodes; empty = the router's admin name
AMTM_UPDATE=on          # on: amtm may update Arteria (amtmupdate); off: only 'update' does
[ -f "$CONF" ] && . "$CONF"
case "$INTERVAL" in [1-9]|10) ;; *) INTERVAL=2 ;; esac
case "$IDLE_STOP" in ''|*[!0-9]*) IDLE_STOP=20 ;; esac
[ "$IDLE_STOP" -lt 20 ] && IDLE_STOP=20    # the page's heartbeat comes every 8 s: leave room for a late one
[ "$IDLE_STOP" -gt 300 ] && IDLE_STOP=300
case "$NODES" in on|off) ;; *) NODES=on ;; esac
case "$AMTM_UPDATE" in on|off) ;; *) AMTM_UPDATE=on ;; esac
case "$NODE_USER" in -*|*[!A-Za-z0-9._-]*) NODE_USER="" ;; esac

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

# /tmp is writable by every process on the router, root or not (some services run as "nobody"). Arteria
# keeps the script it sends to the nodes and the updates it downloads in $TMPD, so it only ever uses that
# folder if it is a real directory (not a link someone planted) that belongs to root and nobody else can write.
tmpd() {
	[ -d "$TMPD" ] || mkdir -m 700 "$TMPD" 2>/dev/null
	[ -d "$TMPD" ] && [ ! -L "$TMPD" ] && [ -O "$TMPD" ] && return 0
	log "$TMPD isn't a folder of ours: not using it"
	die "$TMPD exists and isn't Arteria's own folder. Remove it and try again."
}

# A file in a folder others can write (/tmp) that Arteria may read or install from: a regular file, not a
# link, that belongs to root. Anyone on the router can create /tmp/arteria.asp or /tmp/menuTree.js first.
ours_file() { [ -f "$1" ] && [ ! -L "$1" ] && [ -O "$1" ]; }

# The Addons API's lock file, shared with other addons. Opened for appending (never truncated) and never
# through a link or someone else's file: a name in /tmp could be a link planted by anyone.
webui_lock() {
	if [ -L "$WEBUI_LOCK" ] || { [ -e "$WEBUI_LOCK" ] && ! ours_file "$WEBUI_LOCK"; }; then
		log "$WEBUI_LOCK isn't root's own file: not using it"; say "$WEBUI_LOCK isn't root's own file. Remove it and try again."; return 1
	fi
	exec 9>>"$WEBUI_LOCK" && flock -x 9 2>/dev/null
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
		NF >= 3 && $2 != me && $2 ~ /^[0-9.]+$/ && $3 ~ /^[0-9A-Fa-f:]+$/ { m = $1; gsub(/[^ -~]/, "", m); print toupper($3), $2, m }'   # the model as printable text only: it reaches the terminal
}
# How many nodes have joined AiMesh (cfg_relist), whether or not they're in the list above right now: saving
# almost any setting empties that list for several minutes while the nodes stay online. Only for messages.
nodes_joined() { nvram get cfg_relist | tr '<' '\n' | grep -c '^[0-9A-Fa-f:]\{17\}>'; }
nodes_none_why() {   # why node_list is empty, for the terminal
	k=$(nodes_joined)
	if [ "${k:-0}" -gt 0 ]; then
		say "AiMesh lists $k node(s), but none is in the router's current AiMesh list. That list stays empty for several"
		say "minutes after you save a setting, then the nodes come back by themselves: if a node is on, try again shortly."
	else
		say "No AiMesh nodes found."
	fi
}
node_alias() { ours_file "$ROOT/tmp/$1.json" && sed -n 's/.*"cfg_alias":"\([^"]*\)".*/\1/p' "$ROOT/tmp/$1.json" 2>/dev/null | head -1 | tr -cd '\040-\176'; }
# A node's backhaul stations: the addresses it uses to connect to the router over Wi-Fi.
node_stas() {
	ours_file "$ROOT/tmp/relist.json" || return 0
	sed -n "s/.*\"$1\":{\([^}]*\)}.*/\1/p" "$ROOT/tmp/relist.json" 2>/dev/null | grep -o '[0-9A-Fa-f:]\{17\}' | tr a-f A-F | tr '\n' ' '
}
node_models() { printf '%s\n' "$1" | awk '{ $1 = ""; $2 = ""; sub(/^ +/, ""); printf "%s%s", (c++ ? ", " : ""), $0 }'; }   # node list -> "RP-AX56, ..."
# Only when missing: on JFFS even a chmod that changes nothing is a write to flash, and the sampler calls this.
ssh_home_init() { [ -d "$SSH_HOME/.ssh" ] || { mkdir -p "$SSH_HOME/.ssh" && chmod 700 "$SSH_HOME/.ssh"; } 2>/dev/null; }
node_file() { printf '%s/node.%s' "$TMPD" "$(printf '%s' "$1" | tr -d :)"; }

# Key logins must never fall back to a password: when a node refuses the key, dbclient asks for one on
# the terminal, and a password typed there would make a refused key look like it works. Dropbear 2024.84
# and later (Merlin 3004.388.13 has it) have -o BatchMode=yes, which turns password and
# keyboard-interactive logins off. Prints that option, or nothing on an older dbclient.
ssh_batch() { dbclient -o help 2>&1 | grep -q BatchMode && printf '%s' '-o BatchMode=yes'; }
# True if this process can reach a terminal (dbclient opens /dev/tty itself to ask for a password,
# whatever stdin is). The sampler, started by the router's service events, has none.
has_tty() { ( exec < /dev/tty ) 2> /dev/null; }

ssh_port() { p=$(nvram get sshd_port); case "$p" in ''|*[!0-9]*) p=22 ;; esac; printf '%s' "$p"; }
ssh_user() { if [ -n "$NODE_USER" ]; then printf '%s' "$NODE_USER"; else u=$(nvram get http_username); printf '%s' "${u:-admin}"; fi; }

# One line per Wi-Fi client: "S ifname band MAC tx-bytes rx-bytes rssi tx-kbps rx-kbps connected-s idle-s
# standard streams width". The input is "@ ifname band MAC" followed by that client's `wl sta_info`. tx is
# what the access point sent to the client (its download), rx what it received (its upload). The standard
# comes from the client's capability flags (EHT_CAP = Wi-Fi 7, HE_CAP = 6, VHT_CAP = 5, N_CAP = 4), streams
# and width from its last data rates ("he mcs 11 Nss 2 ... bw80") or "link bandwidth = 80 MHZ"; drivers
# that print none of these leave "-". The same program runs on the nodes, so it must not contain single quotes.
STA_AWK='function out() { if (m != "") print "S", x, b, m, tx, rx, r, tr, rr, cn, id, cap, ss, bw }
$1 == "@" { out(); x = $2; b = $3; m = $4; tx = "-"; rx = "-"; r = "-"; tr = "-"; rr = "-"; cn = "-"; id = "-"; cap = "-"; ss = "-"; bw = "-"; next }
/^[ \t]*flags 0x/ { if ($0 ~ /EHT_CAP/) cap = "be"; else if ($0 ~ /HE_CAP/) cap = "ax"; else if ($0 ~ /VHT_CAP/) cap = "ac"; else if ($0 ~ /N_CAP/) cap = "n"; next }
/Nss [0-9]/ { for (i = 1; i < NF; i++) if ($i == "Nss" && $(i + 1) + 0 > ss + 0) ss = $(i + 1) + 0 }
/ bw[0-9]+/ { if (match($0, / bw[0-9]+/)) bw = substr($0, RSTART + 3, RLENGTH - 3) }
/link bandwidth = [0-9]/ { bw = $4; next }
/tx total bytes:/ { tx = $NF; next }
/rx data bytes:/ { rx = $NF; next }
/^smoothed rssi:/ { r = $NF; next }
/rate of last tx pkt:/ { tr = $6; next }
/rate of last rx pkt:/ { rr = $6; next }
/^[ \t]*in network / { cn = $3; next }
/^[ \t]*idle / { id = $2; next }
END { out() }'

# "S ..." lines -> JSON rows: ["ifname","band","MAC","tx","rx",rssi,txMbps,rxMbps,connected,idle,standard,streams,width].
# Byte counters stay strings: shell arithmetic is 32-bit, and awk would print big numbers as 9.5e+09.
ROWS_AWK='function q(s) { return (s ~ /^[0-9]+$/) ? "\"" s "\"" : "null" }
function n(s) { return (s ~ /^-?[0-9]+$/) ? s : "null" }
function k(s) { return (s ~ /^[0-9]+$/) ? int(s / 1000) : "null" }
function cp(v) { return (v ~ /^(n|ac|ax|be)$/) ? "\"" v "\"" : "null" }
function row() { return "[\"" $2 "\",\"" $3 "\",\"" toupper($4) "\"," q($5) "," q($6) "," n($7) "," k($8) "," k($9) "," n($10) "," n($11) "," cp($12) "," n($13) "," n($14) "]" }'

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
write_node_script() {   # [rounds]   default: 30 minutes' worth (the page's session); 'nodes test' runs one
	printf 'I=%s\nN=%s\n' "$INTERVAL" "${1:-$((1800 / INTERVAL))}"
	cat <<'EOF'
L=""
for u in 0 1 2 3; do
	f=$(nvram get wl${u}_ifname); [ -n "$f" ] || continue
	b=$(nvram get wl${u}_nband)
	case "$b" in 2) b=2.4 ;; 1) b=5 ;; 4) b=6 ;; *) b=0 ;; esac
	for x in $f $(nvram get wl${u}_vifs); do L="$L $x:$b"; done
done
n=0
while [ $n -lt $N ]; do
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
	n=$((n + 1)); [ $n -lt $N ] && sleep $I
done
EOF
}

# ---- AiMesh node sessions ----------------------------------------------------------
# While the page is open the router keeps one SSH session to each node. Key login only: the sampler
# has no terminal, so dbclient can never ask for (or send) a password. Host keys are pinned in $SSH_HOME,
# only by nodekey (no -y here): a node seen for the first time isn't trusted until you say so there.
node_start() {   # mac ip
	f=$(node_file "$1")
	: > "$f.out"; : > "$f.err"; now > "$f.start"; rm -f "$f.fail" "$f.last"
	# ulimit -f: a session that writes more than about 1 MB between two trims is ended (nodes_tick trims at 128 KB),
	# so a node that floods its output can't fill the router's RAM; it is reconnected like any dropped session.
	(ulimit -f 2048 2>/dev/null; HOME="$SSH_HOME" exec dbclient $BATCH -K 10 -I 30 -p "$PORT" -i "$KEY" "$SSHUSER@$2" 'sh -s') \
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
	e=$(tail -c 2048 "$f.err" 2>/dev/null | tr -d '\000')
	case "$e" in
		*trusted\ hosts*) echo nokey ;;   # never trusted yet: nodekey asks
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
			# the last complete block, found by its line numbers: building it up as an awk string costs the square of its size
			blk=$(awk '/^#B / { s = NR } /^#E/ && s { a = s; z = NR } END { if (z) print a "," z }' "$o")
			if [ -n "$blk" ]; then sed -n "${blk}p" "$o" > "${o%.out}.last"; else : > "${o%.out}.last"; fi
			: > "$o"
		fi
		[ "$(wc -c < "${o%.out}.err" 2>/dev/null || echo 0)" -gt 65536 ] && : > "${o%.out}.err"
	done
	return 0
}

# The last complete block a node sent, as JSON: "up":"<node uptime>","c":[rows].
# Only rows between a "#B" and its "#E" count: the file can be emptied in the middle of a block. At most 512 rows a
# block (a node serves far fewer clients): a hostile node can't make every sample cost seconds of CPU.
NODE_AWK="$ROWS_AWK"'
/^#B / { cur = ""; cc = 0; cup = ($2 ~ /^[0-9.]+$/) ? $2 : ""; open = 1; next }
open && cc < 512 && /^S / && $2 ~ /^[A-Za-z0-9.]+$/ && $3 ~ /^[0-9.]+$/ && $4 ~ /^[0-9A-Fa-f:]+$/ { cur = cur (cc++ ? "," : "") row(); next }
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
		NR > 1 && $3 == "no" && $2 ~ /^[0-9A-Fa-f:]+$/ { p = P[$1]; if (p != "" && index(want, " " p " ") && N[p]++ < 64) printf "%s[\"%s\",\"%s\"]", (c++ ? "," : ""), p, toupper($2) }'
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
	ssh_home_init
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
		# The firmware's own JSON files go in as they are, first: a duplicate key later in the object wins, so
		# nothing in them can replace the keys Arteria writes after them. The AiMesh list in /tmp only if it's root's own.
		printf '{"nmp":'
		if head -c 1 "$ROOT/jffs/nmp_cl_json.js" 2>/dev/null | grep -q '{'; then tr -d '\000-\037' < "$ROOT/jffs/nmp_cl_json.js"; else printf '{}'; fi
		printf ',"cl":'
		if ours_file "$ROOT/tmp/clientlist.json" && head -c 1 "$ROOT/tmp/clientlist.json" 2>/dev/null | grep -q '{'; then tr -d '\000-\037' < "$ROOT/tmp/clientlist.json"; else printf '{}'; fi
		printf ',"custom":"%s","leases":"' "$(js "$(nvram get custom_clientlist)")"
		tr '\n' '|' < "$ROOT/var/lib/misc/dnsmasq.leases" 2>/dev/null | tr -d '\000-\037' | sed 's/\\/\\\\/g; s/"/\\"/g'
		printf '"'
		# For the page's Details: DHCP reservations, addresses seen without a lease (static ones), and IPv6
		# neighbours on the LAN bridge. Only hex, dots and colons get through the two awks, so nothing can
		# break out of the JSON strings.
		printf ',"fixed":"%s","arp":"' "$(js "$(nvram get dhcp_staticlist)")"
		awk 'NR > 1 && $3 != "0x0" && $4 ~ /^[0-9A-Fa-f:]+$/ && $1 ~ /^[0-9.]+$/ { printf "%s %s|", $4, $1 }' "$PROC/net/arp" 2>/dev/null
		printf '","n6":"'
		if have ip; then
			ip -6 neigh show dev br0 2>/dev/null | awk '$1 ~ /^[0-9A-Fa-f:]+$/ && $NF != "FAILED" && $NF != "INCOMPLETE" { for (i = 2; i < NF; i++) if ($i == "lladdr" && $(i + 1) ~ /^[0-9A-Fa-f:]+$/) printf "%s %s|", $(i + 1), $1 }'
		fi
		printf '","fb":"'
		fb_on && fb_export
		printf '","dc":"'
		fb_on && disc_export
		printf '"}'
	} | write_atomic "$(web_dir)/names.htm"
	fb_status
}

uptime_cs() { awk '{ printf "%d", ($1 % 1000000) * 100 }' "$PROC/uptime"; }   # centiseconds (mod 11.5 days: 32-bit safe), for timing a sample

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
	tmpd; mkdir -p "$(web_dir)"
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
		if [ $((seq % 15)) -eq 14 ] || [ -f "$TMPD/fb_new" ]; then rm -f "$TMPD/fb_new"; export_names; fi   # a new answer from Fingerbank: at once
		{ [ $seq -eq 1 ] || [ $((seq % 15)) -eq 7 ]; } && fb_tick
		[ $((seq % 30)) -eq 29 ] && sample_init      # nodes and radios can change while the page is open
		[ "$NODES" = on ] && nodes_tick
		sample_json "$seq" "$ms" | write_atomic "$WD/live.htm"
		ms=$(( ($(uptime_cs) - t0) * 10 )); [ "$ms" -lt 0 ] && ms=0   # the counter wrapped during this sample
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
			tmpd; touch "$TMPD/heartbeat"
			sampler_running || (sh "$SCRIPT" sampler < /dev/null > /dev/null 2>&1 &) ;;
		"${NAME}stop")
			rm -f "$TMPD/heartbeat" ;;
		"${NAME}fbprep") tmpd; fb_ui_prep ;;    # the page's Settings (Fingerbank), see fb_ui_save
		"${NAME}fb") tmpd; fb_ui_save ;;
		"${NAME}fboff") tmpd; fb_ui_off ;;
		"${NAME}fbnow") tmpd; fb_ui_now ;;
	esac
}

stop_all() {   # sampler and node sessions, e.g. before an update or uninstall
	p=$(cat "$TMPD/sampler.pid" 2>/dev/null)
	pid_ours "$p" "$NAME.sh sampler" && kill "$p" 2>/dev/null
	node_stop_all
	rm -f "$TMPD/sampler.pid" "$TMPD/heartbeat"
}

# ---- device recognition with Fingerbank (your own free API key) -------------------------------------
# Off until you run "fingerbank" with your own key. Then dnsmasq hands each DHCP request to a small script
# of Arteria's first (dnsmasq.postconf points dhcp-script at it): it notes which options the device asked
# for, in order (its DHCP fingerprint), and its vendor class, in RAM, then runs the lease script dnsmasq
# had before (ASUS's /sbin/dhcpc_lease) with the same arguments. While the page is open, the sampler asks
# Fingerbank about each fingerprint it hasn't seen yet, one at a time. Only the option list and the vendor
# class go to Fingerbank: no MAC, name or address. The answers stay on JFFS, one short line each.
fb_on() { [ -s "$FB_KEY" ]; }
fb_devices() { if [ -f "$DHCP_FP" ]; then wc -l < "$DHCP_FP" | tr -d ' '; else echo 0; fi; }   # devices with a fingerprint
fw_major() { v=$(fw_version); v=${v%%.*}; case "$v" in ''|*[!0-9]*) echo 0 ;; *) echo "$v" ;; esac; }

# dnsmasq.postconf (and dnsmasq-sdn.postconf on 3006, one per network) runs this with dnsmasq's config file as it starts.
dnsmasq_conf() {   # config-file
	fb_on || return 0
	cf=$1; [ -f "$cf" ] || return 0
	[ -d "$TMPD" ] || mkdir -m 700 "$TMPD" 2>/dev/null
	{ [ -d "$TMPD" ] && [ ! -L "$TMPD" ] && [ -O "$TMPD" ]; } || return 0
	# a lease script that runs as another user couldn't open our folder: leave dnsmasq alone
	u=$(sed -n 's/^dhcp-scriptuser=//p' "$cf" | tail -n 1); [ -z "$u" ] || [ "$u" = root ] || return 0
	cur=$(sed -n 's/^dhcp-script=//p' "$cf" | tail -n 1)
	case "$cur" in
		"$TMPD"/dhcp_hook.*) return 0 ;;   # ours already
		*[!A-Za-z0-9/._-]*) log "dnsmasq's lease script has an unusual name: leaving it alone"; return 0 ;;
	esac
	h="$TMPD/dhcp_hook.$(printf '%s' "$cur" | md5sum | cut -c1-8).sh"
	write_dhcp_hook "$h" "$cur" || return 0
	if [ -n "$cur" ]; then sed -i "s|^dhcp-script=.*|dhcp-script=$h|" "$cf"; else echo "dhcp-script=$h" >> "$cf"; fi
	# By default dnsmasq runs the script for new leases only: a device that stays connected and renews would never be seen.
	grep -q '^script-on-renewal' "$cf" || { dnsmasq --help 2>/dev/null | grep -q 'script-on-renewal' && echo 'script-on-renewal' >> "$cf"; }
	return 0
}

write_dhcp_hook() {   # file next-script (empty: none)
	nx="exit 0"; [ -n "$2" ] && nx="exec $2 \"\$@\""
	cat > "$1.new" <<EOF || return 1
#!/bin/sh
# Arteria (Fingerbank device recognition): note which DHCP options a device asked for, in order (its fingerprint),
# and its vendor class, have a new device recognised, then run the lease script dnsmasq had before, with the same
# arguments and environment.
PATH="\${PATH:-/sbin:/bin:/usr/sbin:/usr/bin}"
case "\$1" in add|old)
	m=\$(printf '%s' "\$2" | tr 'a-f' 'A-F')
	o=\$(printf '%s' "\$DNSMASQ_REQUESTED_OPTIONS" | tr -cd '0-9,' | cut -c1-160)
	case "\$m" in ??:??:??:??:??:??) ;; *) o="" ;; esac
	case "\$m" in *[!0-9A-F:]*) o="" ;; esac
	if [ -n "\$o" ] && [ -z "\$DNSMASQ_IAID" ]; then
		v=\$(printf '%s' "\$DNSMASQ_VENDOR_CLASS" | tr -cd 'A-Za-z0-9 ._:/+-' | tr -s ' ' | sed 's/^ //; s/ \$//' | cut -c1-80)
		{ grep -v "^\$m " "$DHCP_FP" 2>/dev/null | tail -n 299; printf '%s %s %s\n' "\$m" "\$o" "\$v"; } > "$DHCP_FP.new" && mv -f "$DHCP_FP.new" "$DHCP_FP"
		# a fingerprint Fingerbank hasn't answered yet: ask now, in the background, page open or not
		t=\$(printf '\t')
		grep -qF "\$o;\$v\$t" "$FB_CACHE" 2>/dev/null || ( ${ROOT:+AR_ROOT=$ROOT }"$SCRIPT" fblookup < /dev/null > /dev/null 2>&1 & )
		# a device that just joined and hasn't said what it is yet: ask the network about it in a minute (once until a reboot)
		if [ "\$1" = add ] && ! grep -q "^\$m|" "$DISC" 2>/dev/null && ! grep -qx "\$m" "$TMPD/disc_tried" 2>/dev/null; then
			echo "\$m" >> "$TMPD/disc_tried"; ( ${ROOT:+AR_ROOT=$ROOT }${AR_PROC:+AR_PROC=$PROC }${AR_DISC_DELAY:+AR_DISC_DELAY=$DISC_DELAY }"$SCRIPT" discnew < /dev/null > /dev/null 2>&1 & )
		fi
	fi ;;
esac
$nx
EOF
	chmod 700 "$1.new" && mv -f "$1.new" "$1"
}

fb_hooks() {   # add | del
	if [ "$1" = add ]; then
		hook_add dnsmasq.postconf "$SCRIPT dnsmasq_conf \"\$1\""
		[ "$(fw_major)" -ge 3006 ] && hook_add dnsmasq-sdn.postconf "$SCRIPT dnsmasq_conf \"\$1\""
		return 0
	fi
	for p in dnsmasq.postconf dnsmasq-sdn.postconf; do
		hook_del "$p"; f="$SCRIPTS_DIR/$p"
		# a file that was only there for Arteria's line goes with it
		[ -f "$f" ] && [ -z "$(grep -v '^#!' "$f" | grep -v '^[[:space:]]*$')" ] && rm -f "$f"
	done
	return 0
}
fb_hooked() { grep -q "^dhcp-script=$TMPD/dhcp_hook\." "$DNSMASQ_CONF" 2>/dev/null; }
fb_rehook() {   # the lease script dnsmasq runs, rewritten by this version (dnsmasq keeps calling it by its name)
	f=$(sed -n 's/^dhcp-script=//p' "$DNSMASQ_CONF" 2>/dev/null | head -n 1)
	case "$f" in "$TMPD"/dhcp_hook.*.sh) ours_file "$f" || return 0 ;; *) return 0 ;; esac
	write_dhcp_hook "$f" "$(sed -n 's/^exec \(.*\) "\$@"$/\1/p' "$f" | head -n 1)"
}

# One question to Fingerbank. The key goes in a header read from a here-document, so it never shows in a command line.
fb_query() {   # api-key question ("options;vendor class[;services;SERVER strings[;MAC]]", see fb_keys) -> "HTTP-code body"
	b=$(printf '%s\n' "$2" | awk -F';' 'function list(name, v, sep,   a, n, i, t) { n = split(v, a, sep); t = ""
			for (i = 1; i <= n; i++) if (a[i] != "") t = t (t == "" ? "" : ",") "\"" a[i] "\""
			if (t != "") s = s (s == "" ? "" : ",") "\"" name "\":[" t "]" }
		{ s = ""; if ($1 != "") s = "\"dhcp_fingerprint\":\"" $1 "\""; if ($2 != "") s = s (s == "" ? "" : ",") "\"dhcp_vendor\":\"" $2 "\""
		  list("mdns_services", $3, ","); list("upnp_server_strings", $4, "~")
		  if ($5 ~ /^[0-9A-F:]+$/) s = s (s == "" ? "" : ",") "\"mac\":\"" $5 "\""; print "{" s "}" }' | tr -d '\\')
	out=$(curl -s --proto =https --connect-timeout 10 --max-time 20 -K - -X POST -H 'Content-Type: application/json' -d "$b" -w '\n%{http_code}' "$FB_URL" 2>/dev/null <<EOF
header = "Authorization: Bearer $1"
EOF
)
	printf '%s %s' "$(printf '%s\n' "$out" | tail -n 1)" "$(printf '%s\n' "$out" | sed '$d' | tr -d '\r\n')"
}

fb_cache_add() {   # fingerprint-key code score name
	n=$(printf '%s' "$4" | tr -d '"\\|<>\t' | tr -cd '\040-\176' | cut -c1-150)
	{ [ -f "$FB_CACHE" ] && awk -F'\t' -v k="$1" '$1 != k' "$FB_CACHE" | tail -n 199; printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "${3:-0}" "$n" "$(now)"; } > "$FB_CACHE.new" \
		&& mv -f "$FB_CACHE.new" "$FB_CACHE"
}

# What Arteria asks Fingerbank about each device, one line each: "MAC<tab>question". The question is the key of
# Fingerbank's answer in the cache too: "options;vendor class" from its DHCP request (the vendor class with single
# spaces), then, once it has answered Recognise now, ";services;SERVER strings": up to 5 of the mDNS services it offers
# (the telling ones first, comma-separated) and up to 3 UPnP SERVER strings ("~"-separated). Identical devices
# ask the same question, so they share one answer.
fb_keys() {
	cat "$DISC" 2>/dev/null | awk -F'|' -v fp="$DHCP_FP" 'BEGIN { while ((getline l < fp) > 0) { n = split(l, f, " "); if (f[1] !~ /^[0-9A-F:]+$/ || f[2] !~ /^[0-9,]+$/) continue
			v = ""; for (i = 3; i <= n; i++) v = v (i > 3 ? " " : "") f[i]; if (!(f[1] in d)) o[++c] = f[1]; d[f[1]] = f[2] ";" v } }
		$1 ~ /^[0-9A-F:]+$/ && length($1) == 17 {
			n = split($2, a, " "); t = ""; k = 0
			for (p = 0; p < 2; p++) for (i = 1; i <= n && k < 5; i++) if (a[i] ~ /\.local$/ && (a[i] ~ /^_(http|https|ssh|sftp-ssh)\._tcp\./) == p) { t = t (k++ ? "," : "") a[i] }
			n = split($5, a, "~"); u = ""; for (i = 1; i <= n && i <= 3; i++) u = u (i > 1 ? "~" : "") a[i]
			if (t u != "") { x[$1] = t ";" u; if (!($1 in d)) o[++c] = $1 } }
		END { for (i = 1; i <= c; i++) { m = o[i]; if (!(m in d) && !(m in x)) continue; q = (m in d) ? d[m] : ";"; if (m in x) q = q ";" x[m]; print m "\t" q } }'
}
# The first question Fingerbank hasn't answered: never asked, or not known to it more than 30 days ago; with FB_SINCE
# (Recognise now), also any answered before that moment, so every device is asked again (its old answer stays until then).
FB_SINCE=0
fb_next() {
	fb_keys | awk -F'\t' -v c="$FB_CACHE" -v now="$(now)" -v since="$FB_SINCE" 'BEGIN { while ((getline l < c) > 0) { split(l, f, "\t"); if ((f[2] == 200 || now - f[5] < 2592000) && f[5] >= since) done[f[1]] = 1 } }
		!($2 in done) { print $2; exit }'
}

fb_lookup() {   # up to 10 lookups, while there's anything to ask and Fingerbank answers
	k=$(head -n 1 "$FB_KEY" 2>/dev/null | tr -cd 'A-Za-z0-9'); case $k in "") return 0 ;; esac   # never [ "$k" ]: [ is a program there
	i=0
	while [ $i -lt 10 ]; do
		pick=$(fb_next); [ -n "$pick" ] || return 0
		# at most 100 an hour, a third of Fingerbank's free limit (a home network needs a few dozen, once)
		t=$(now); set -- $(cat "$TMPD/fb_hour" 2>/dev/null); h=${1:-0}; c=${2:-0}
		[ $((t - h)) -ge 3600 ] 2>/dev/null || [ "$h" = 0 ] && { h=$t; c=0; }
		[ "$c" -lt 100 ] || { echo "wait $((h + 3600))" > "$TMPD/fb_state"; return 0; }
		echo "$h $((c + 1))" > "$TMPD/fb_hour"
		r=$(fb_query "$k" "$pick"); code=${r%% *}; body=${r#* }
		echo "${code:-000} $t" > "$TMPD/fb_last"
		case "$code" in
			200) fb_cache_add "$pick" 200 "$(printf '%s' "$body" | sed -n 's/.*"score":\([0-9][0-9]*\).*/\1/p' | head -n 1)" \
					"$(printf '%s' "$body" | sed -n 's/.*"device_name":"\([^"]*\)".*/\1/p' | head -n 1)" ;;
			404) fb_cache_add "$pick" 404 0 "" ;;
			401|403) echo badkey > "$TMPD/fb_state"; log "Fingerbank turned the API key down (HTTP $code): run '$SCRIPT fingerbank' to enter it again"; return 0 ;;
			429) echo "wait $((t + 3600))" > "$TMPD/fb_state"; return 0 ;;    # over the free hourly limit: an hour's pause
			*) echo "wait $((t + 300))" > "$TMPD/fb_state"; return 0 ;;       # no answer: try again in five minutes
		esac
		rm -f "$TMPD/fb_state"; touch "$TMPD/fb_new"
		i=$((i + 1))
	done
}

# From dnsmasq's lease script (a new fingerprint) and the sampler: one round of lookups at a time, in the background.
fb_tick() {   # [wait]: wait for a round that's running (dnsmasq's script: its new fingerprint mustn't be missed)
	fb_on && { [ -s "$DHCP_FP" ] || [ -s "$DISC" ]; } && have curl || return 0
	lk="-n"; [ "$1" = wait ] && lk="-w 120"
	st=$(cat "$TMPD/fb_state" 2>/dev/null)
	case "$st" in badkey) return 0 ;; "wait "*) [ "$(now)" -ge "${st#wait }" ] 2>/dev/null || return 0 ;; esac
	( exec 8>&- 7>"$TMPD/fb.lock"; flock $lk 7 || exit 0; fb_lookup ) < /dev/null > /dev/null 2>&1 &
}

# For the page: "MAC>score>Fingerbank's device path>options|" for each device Arteria asks about (score and path
# empty until Fingerbank has answered). Until the question with a device's services has an answer, the answer to its
# DHCP fingerprint alone stands in.
fb_export() {
	fb_keys | awk -F'\t' -v c="$FB_CACHE" 'BEGIN { while ((getline l < c) > 0) { split(l, f, "\t"); if (f[2] == 200) { s[f[1]] = f[3]; n[f[1]] = f[4] } } }
		{ split($2, q, ";"); k = $2; if (!(k in s)) k = q[1] ";" q[2]
		  printf "%s>%s>%s>%s|", $1, (k in s ? s[k] : ""), (k in n ? n[k] : ""), q[1] }' | tr -d '"\\'
}

fb_restart_dnsmasq() {   # want: on | off -> 0 once dnsmasq runs with (or without) our lease script
	service restart_dnsmasq > /dev/null 2>&1
	i=0; while [ $i -lt 15 ]; do
		if [ "$1" = on ]; then fb_hooked && return 0; else fb_hooked || return 0; fi
		sleep 1; i=$((i + 1))
	done
	return 1
}

fb_off() {   # [quiet]
	was=0; fb_hooked && was=1
	rm -f "$FB_KEY" "$FB_CACHE" "$DISC" "$TMPD/fb_state" "$TMPD/fb_last"
	fb_hooks del
	if [ $was = 1 ]; then
		[ "$1" = quiet ] || say "Restarting dnsmasq (DNS and DHCP pause for a second)..."
		fb_restart_dnsmasq off || [ "$1" = quiet ] || say "dnsmasq hasn't restarted yet; it drops Arteria's script at its next restart."
	fi
	fb_hooked || rm -f "$TMPD"/dhcp_hook.*.sh "$DHCP_FP"
	return 0
}

# Turn Fingerbank on with this key: check it with Fingerbank, keep it for root only, hook dnsmasq in.
# The key is only ever passed to commands through here-documents, never as an argument (ps would show it).
fb_enable() {   # key -> 0 when Fingerbank is on; FB_MSG says what happened
	k=$(tr -d ' \r\n\t' <<EOF
$1
EOF
)
	case "$k" in '') FB_MSG="No key given. Nothing changed."; return 1 ;; esac   # case, not [: on the router [ is a program
	case "$k" in *[!A-Za-z0-9]*) FB_MSG="That doesn't look like a Fingerbank API key (letters and digits only). Nothing changed."; return 1 ;; esac
	[ ${#k} -ge 20 ] && [ ${#k} -le 128 ] || { FB_MSG="That doesn't look like a Fingerbank API key (it's ${#k} characters long). Nothing changed."; return 1; }
	have curl || { FB_MSG="This router has no curl, which Fingerbank lookups need. Nothing changed."; return 1; }
	tmpd
	r=$(fb_query "$k" "1,3,6,15,119,252;"); code=${r%% *}; note=""
	case "$code" in
		200|404) ;;
		401|403) FB_MSG="Fingerbank turned this key down (HTTP $code). Check it on your account page at api.fingerbank.org. Nothing changed."; return 1 ;;
		429) note=" Fingerbank says the key is over its hourly limit right now: Arteria waits an hour before its first lookups." ;;
		000|'') FB_MSG="Couldn't reach api.fingerbank.org. Check the router's internet connection, then try again. Nothing changed."; return 1 ;;
		*) FB_MSG="Fingerbank answered HTTP $code. Try again later. Nothing changed."; return 1 ;;
	esac
	( umask 077; cat > "$FB_KEY.new" <<EOF
$k
EOF
	) && chmod 600 "$FB_KEY.new" && mv -f "$FB_KEY.new" "$FB_KEY" || { FB_MSG="Couldn't save the key. Nothing changed."; return 1; }
	rm -f "$TMPD/fb_state"; [ "$code" = 429 ] && echo "wait $(( $(now) + 3600 ))" > "$TMPD/fb_state"
	fb_hooks add
	log "Fingerbank turned on"
	if fb_restart_dnsmasq on; then
		FB_MSG="Saved. Each device is recognised when it connects or renews its address. Recognise now asks the devices on the network what they are right away.$note"
	else
		FB_MSG="Saved, but dnsmasq hasn't picked up the change yet. It will at its next restart (a reboot, or saving a LAN setting).$note"
	fi
	return 0
}

# For deciding what's worth sending: each device that answered Recognise now, looked up four ways. Nothing is kept.
fb_compare_one() {   # api-key question -> "device path (score)", or why not
	r=$(fb_query "$1" "$2"); c=${r%% *}; b=${r#* }
	case "$c" in
		200) printf '%s (%s)' "$(printf '%s' "$b" | sed -n 's/.*"device_name": *"\([^"]*\)".*/\1/p' | head -n 1)" "$(printf '%s' "$b" | sed -n 's/.*"score": *\([0-9][0-9]*\).*/\1/p' | head -n 1)" ;;
		404) printf 'not known' ;;
		*) printf 'no answer (HTTP %s)' "${c:-000}" ;;
	esac
}
fb_compare() {
	fb_on || die "Fingerbank is off: run '$SCRIPT fingerbank' first."
	have curl || die "This router has no curl."
	[ -s "$DISC" ] || die "No device has said what it is yet: press Recognise now in Settings (or run '$SCRIPT fingerbank now') first."
	tmpd; k=$(head -n 1 "$FB_KEY" 2>/dev/null | tr -cd 'A-Za-z0-9'); case $k in "") die "No key." ;; esac
	say "Fingerbank's answer for each device that said what it is, four ways: its DHCP fingerprint alone (if it has one),"
	say "+ the services it announced, + its maker (the first half of its MAC), + its whole MAC. Up to 4 lookups a device,"
	say "100 at most. Nothing is saved. No names or IP addresses are shown or sent."
	fb_keys > "$TMPD/cmp.keys"; n=0
	while IFS="$(printf '\t')" read -r m q; do
		grep -q "^$m|" "$DISC" || continue
		[ $n -lt 97 ] || { say ""; say "(stopped at 100 lookups)"; break; }
		case "$q" in *";"*";"*";"*) ;; *) q="$q;;" ;; esac
		o=${q%%;*}; r=${q#*;}; v=${r%%;*}
		say ""
		say "...${m#????????????}  $(awk -F'|' -v m="$m" '$1 == m { gsub(/~/, " / ", $5); print ($2 != "" ? $2 : "-") ($3 != "" ? "  [" $3 "]" : "") ($4 != "" ? "  [" $4 "]" : "") ($5 != "" ? "  [" $5 "]" : "") }' "$DISC" | head -n 1)"
		[ -n "$o" ] && say "  DHCP only:   $(fb_compare_one "$k" "$o;$v")" && n=$((n + 1))
		say "  + services:  $(fb_compare_one "$k" "$q")"
		say "  + maker:     $(fb_compare_one "$k" "$q;${m%?????????}:00:00:00")"
		say "  + whole MAC: $(fb_compare_one "$k" "$q;$m")"
		n=$((n + 3))
	done < "$TMPD/cmp.keys"
	rm -f "$TMPD/cmp.keys"
}

fingerbank_cmd() {   # [off | now | compare]
	[ "$1" = compare ] && { fb_compare; return 0; }
	if [ "$1" = now ]; then
		tmpd
		if [ -n "$(socat_bin)" ]; then say "Asking the devices on the network what they are (15 to 20 seconds), then Fingerbank..."
		else say "Looking up every device with Fingerbank..."; fi
		fb_recognise || die "$FB_MSG"; say "$FB_MSG"; return 0
	fi
	if [ "$1" = off ]; then
		fb_off
		say "Fingerbank is off: the key, Fingerbank's answers and what devices said are deleted, and dnsmasq runs the router's own lease script directly again."
		log "Fingerbank turned off"
		return 0
	fi
	say "Device recognition with Fingerbank is optional: Arteria works fully without it."
	say "Turned on, Arteria asks Fingerbank (fingerbank.org) what each device is from the DHCP options it asks for,"
	say "and after Recognise now also from the services it announces on the network."
	say "What is shared with Fingerbank: for each kind of device, that option list, its DHCP vendor class and the names of"
	say "the services it announces (e.g. _googlecast._tcp) and its UPnP server string. Never a MAC address, device name or"
	say "IP address on your network. Fingerbank sees your public IP address, as any website does, and adds combinations"
	say "it doesn't know yet to its database. Its terms: https://www.fingerbank.org/"
	say ""
	say "Get a free key: open https://api.fingerbank.org , choose Login or Signup, then copy the API key from your account."
	say "Keep the key to yourself: the free key allows 300 lookups an hour, and anyone using it uses up yours."
	say "Saving restarts dnsmasq (DNS and DHCP pause for about a second)."
	say ""
	if [ -t 0 ]; then
		printf 'Paste your Fingerbank API key (it is not shown; Enter alone cancels): '
		trap 'stty echo 2>/dev/null; echo; exit 1' INT TERM
		stty -echo 2>/dev/null; read -r k || k=""; stty echo 2>/dev/null; echo
		trap - INT TERM
	else
		read -r k || k=""
	fi
	k2=$(tr -d ' \t\r' <<EOF
$k
EOF
)
	case "$k2" in '') say "Nothing changed."; return 1 ;; esac
	say "Checking the key with Fingerbank..."
	fb_enable "$k" || die "$FB_MSG"
	say "$FB_MSG"
	say "To ask the devices on the network what they are right away: $SCRIPT fingerbank now"
	say "To stop and delete the key and the answers: $SCRIPT fingerbank off (or the page's Settings)."
}

# ---- Fingerbank from the page's Settings ---------------------------------------------------------------
# The page can only hand the router a value through the Addons API's shared settings file
# (/jffs/addons/custom_settings.txt), and the router's web server rewrites that whole file with what the page
# sends: the page has to send every addon's settings back, as each addon page does, and the firmware cuts
# values at their first space on the way to the page. So, just before saving, the page asks for an exact
# copy of the file (fbprep); the save (fb) takes the key out and puts that copy back, so no other addon's
# setting changes, then turns Fingerbank on. The page follows it all in fb.htm.
CUSTOM_SETTINGS="$ROOT/jffs/addons/custom_settings.txt"

fb_msg() {   # ok(1|0|"") message: the result the page shows, numbered so it can tell a new one from the last
	n=$(cat "$TMPD/fb_seq" 2>/dev/null); n=$(( ${n:-0} + 1 )); echo "$n" > "$TMPD/fb_seq"
	printf '%s\n%s\n' "$1" "$2" > "$TMPD/fb_msg"
}
fb_status() {   # -> fb.htm, for the page's Settings: never the key, only its last 4 characters
	d=$(web_dir); mkdir -p "$d" 2>/dev/null || return 0
	on=false; tl=""; fb_on && { on=true; tl=$(head -n 1 "$FB_KEY" | tr -cd 'A-Za-z0-9' | tail -c 4); }
	hk=false; fb_hooked && hk=true
	bz=false; [ -f "$TMPD/fb_busy" ] && bz=true
	dv=$(fb_devices); kn=$(awk -F'\t' '$2 == 200 { n++ } END { print n + 0 }' "$FB_CACHE" 2>/dev/null)
	wt=0; fb_on && [ -d "$TMPD" ] && wt=$(fb_waiting | grep -c .)
	ok=$(sed -n 1p "$TMPD/fb_msg" 2>/dev/null); case "$ok" in 1) ok=true ;; 0) ok=false ;; *) ok=null ;; esac
	sc=false; [ -n "$(socat_bin)" ] && sc=true; as=$(grep -c . "$DISC" 2>/dev/null)
	printf '{"on":%s,"tail":"%s","hooked":%s,"busy":%s,"devices":%s,"known":%s,"waiting":%s,"asked":%s,"socat":%s,"last":"%s","state":"%s","seq":%s,"ok":%s,"msg":"%s","prep":"%s"}' \
		"$on" "$tl" "$hk" "$bz" "${dv:-0}" "${kn:-0}" "${wt:-0}" "${as:-0}" "$sc" "$(cut -d' ' -f1 "$TMPD/fb_last" 2>/dev/null | tr -cd '0-9')" \
		"$(cut -d' ' -f1 "$TMPD/fb_state" 2>/dev/null | tr -cd 'a-z')" "$(cat "$TMPD/fb_seq" 2>/dev/null || echo 0)" "$ok" \
		"$(js "$(sed -n '2,$p' "$TMPD/fb_msg" 2>/dev/null)")" "$(cat "$TMPD/fb_prep" 2>/dev/null)" | write_atomic "$d/fb.htm"
}
fb_ui_prep() {
	if [ -f "$CUSTOM_SETTINGS" ]; then cp -f "$CUSTOM_SETTINGS" "$TMPD/cs.saved"; else rm -f "$TMPD/cs.saved"; fi
	echo "$(now).$$" > "$TMPD/fb_prep"
	fb_status
}
fb_ui_save() {
	k=$(sed -n 's/^arteria_fbkey //p' "$CUSTOM_SETTINGS" 2>/dev/null | head -n 1 | tr -cd 'A-Za-z0-9')
	# put the shared file back as it was a moment ago (a copy older than a minute could undo another addon's save)
	if [ -f "$TMPD/cs.saved" ] && [ $(( $(now) - $(date -r "$TMPD/cs.saved" +%s) )) -le 60 ]; then
		grep -v '^arteria_fbkey ' "$TMPD/cs.saved" > "$TMPD/cs.new"; cat "$TMPD/cs.new" > "$CUSTOM_SETTINGS"
	else
		sed -i '/^arteria_fbkey /d' "$CUSTOM_SETTINGS" 2>/dev/null
	fi
	rm -f "$TMPD/cs.saved" "$TMPD/cs.new"
	touch "$TMPD/fb_busy"; fb_msg "" "Checking the key with Fingerbank..."; fb_status
	if fb_enable "$k"; then fb_msg 1 "$FB_MSG"; else fb_msg 0 "$FB_MSG"; fi
	rm -f "$TMPD/fb_busy"; fb_status
}
# ---- Recognise now: asking the devices what they are ----------------------------------------------------
# A device's DHCP fingerprint often only tells Fingerbank its system ("Android", "Linux"). Most devices also say
# what they are when asked, the way phones find printers and speakers: over mDNS (Bonjour) they list the services
# they offer (_googlecast, _airplay, _spotify-connect, _matter...) and often their model, and over UPnP they send
# a SERVER string and a description. Recognise now asks, with Entware's socat (opkg install socat), keeps the
# answers by MAC in DISC (never names or addresses), and looks each device up again with them.
# DISC: "MAC|services|model fields|UPnP description|UPnP SERVER strings|epoch", one line per device, newest last.
socat_bin() { if have socat; then echo socat; elif [ -x /opt/bin/socat ]; then echo /opt/bin/socat; fi; }
# Names travel as hex labels joined by dots ("5f736d62.5f746370.6c6f63616c" is _smb._tcp.local), so any byte in a name is safe.
# hex names on stdin, one per line -> mDNS questions of type $1, as printf formats (octal escapes), several per packet
disc_packets() {
	awk -v qt="$1" 'function oc(n) { return sprintf("\\%03o", n) }
	function hx(s, i) { return index("0123456789abcdef", substr(s, i, 1)) - 1 }
	function flush() { if (nq) print oc(0) oc(0) oc(0) oc(0) oc(int(nq / 256)) oc(nq % 256) oc(0) oc(0) oc(0) oc(0) oc(0) oc(0) body; nq = 0; body = ""; len = 12 }
	BEGIN { len = 12 }
	/^[0-9a-f.]+$/ {
		q = ""; n = split($0, lab, "."); ql = 0
		for (i = 1; i <= n; i++) { l = length(lab[i]) / 2; q = q oc(l); for (j = 1; j < 2 * l; j += 2) q = q oc(hx(lab[i], j) * 16 + hx(lab[i], j + 1)); ql += l + 1 }
		q = q oc(0) oc(int(qt / 256)) oc(qt % 256) oc(0) oc(1); ql += 5
		if (len + ql > 1200) flush()
		body = body q; len += ql; nq++
	}
	END { flush() }'
}
# Ask from an ordinary port ("legacy unicast"): devices answer straight back to it, and socat -x dumps each answer apart.
# -t: how long socat listens once the question is sent (its default, half a second, misses devices that answer late)
disc_ask() {   # qtype < hex names
	disc_packets "$1" | while read -r f; do
		printf "$f" | "$DS" -x -t2 -T2 - "UDP4-DATAGRAM:224.0.0.251:5353,bind=$DLAN:0" 2>> "$DT/x" > /dev/null
	done
}
# The answers so far, decoded: "PTR owner target", "SRV owner host", "TXT owner k=v;k=v" (model fields only), "A host ip"
disc_records() {
	awk 'function hb(s) { return index("0123456789abcdef", substr(s, 1, 1)) * 16 + index("0123456789abcdef", substr(s, 2, 1)) - 17 }
	function name(p,   out, l, c, jumped, g, lab) {
		out = ""; jumped = 0
		for (g = 0; g < 64; g++) {
			l = B[p]
			if (l == "") { NEXT = p + 1; return out }
			if (l == 0) { if (!jumped) NEXT = p + 1; return out }
			if (l >= 192) { if (!jumped) NEXT = p + 2; p = (l - 192) * 256 + B[p + 1]; jumped = 1; continue }
			lab = ""; for (c = 1; c <= l; c++) lab = lab sprintf("%02x", B[p + c])
			out = out (out == "" ? "" : ".") lab; p += l + 1
		}
		return out
	}
	function txt(p, end,   out, l, s, c, ch) {
		out = ""
		while (p < end) {
			l = B[p]; s = ""
			for (c = 1; c <= l; c++) { ch = B[p + c]; s = s ((ch >= 32 && ch < 127 && index(";|~<>\"\\", A[ch]) == 0) ? A[ch] : "?") }
			if (s ~ /^(model|rpMd|md|mn|vn|ty|product|usb_MFG|usb_MDL|DT|modelid|am|mf|manufacturer)=./) out = out (out == "" ? "" : ";") substr(s, 1, 60)
			p += l + 1
		}
		return out
	}
	function msg(   p, qd, nr, i, own, ty, rl, rp) {
		if (N < 12) return
		qd = B[4] * 256 + B[5]; nr = B[6] * 256 + B[7] + B[8] * 256 + B[9] + B[10] * 256 + B[11]
		p = 12
		for (i = 0; i < qd; i++) { name(p); p = NEXT + 4 }
		for (i = 0; i < nr && p < N; i++) {
			own = name(p); p = NEXT
			ty = B[p] * 256 + B[p + 1]; rl = B[p + 8] * 256 + B[p + 9]; rp = p + 10
			if (ty == 12) print "PTR\t" own "\t" name(rp)
			else if (ty == 33) print "SRV\t" own "\t" name(rp + 6)
			else if (ty == 16) print "TXT\t" own "\t" txt(rp, rp + rl)
			else if (ty == 1 && rl == 4) print "A\t" own "\t" B[rp] "." B[rp + 1] "." B[rp + 2] "." B[rp + 3]
			p = rp + rl
		}
	}
	BEGIN { for (i = 32; i < 127; i++) A[i] = sprintf("%c", i) }
	/^[<>] / { if (dir == "<") msg(); dir = substr($0, 1, 1); N = 0; split("", B); next }
	/^ [0-9a-f][0-9a-f]( |$)/ { if (dir == "<") for (i = 1; i <= NF; i++) B[N++] = hb($i) }
	END { if (dir == "<") msg() }' "$DT/x" 2>/dev/null | sort -u
}
disc_run() {   # socat -> DISC updated; DISC_N: how many devices answered
	DS=$1; DLAN=$(nvram get lan_ipaddr); DT="$TMPD/disc.d"; DISC_N=0
	rm -rf "$DT"; mkdir -m 700 "$DT" || return 1
	case "$DLAN" in *[!0-9.]*|'') return 1 ;; esac
	# mDNS: 1. which kinds of service are offered, 2. who offers each, 3. the details of each offer, 4. their hosts' addresses
	st=5f7365727669636573.5f646e732d7364.5f756470.6c6f63616c   # _services._dns-sd._udp.local
	echo "$st" | disc_ask 12
	disc_records | awk -F'\t' '$1 == "PTR" { print $3 }' | sort -u | disc_ask 12
	disc_records > "$DT/r"
	awk -F'\t' -v st="$st" '$1 == "PTR" && $2 != st { inst[$3] = 1 } $1 == "SRV" { srv[$2] = 1 } $1 == "TXT" { txt[$2] = 1 }
		END { for (i in inst) if (!(i in srv) || !(i in txt)) print i }' "$DT/r" | disc_ask 255
	disc_records > "$DT/r"
	awk -F'\t' '$1 == "SRV" { t[$3] = 1 } $1 == "A" { a[$2] = 1 } END { for (h in t) if (!(h in a)) print h }' "$DT/r" | disc_ask 1
	disc_records > "$DT/r"
	# UPnP: who's there (each reply's SERVER string), then each device's description (LOCATION holds its address).
	# Devices wait up to MX (2) seconds before they answer, so socat listens for 3.
	printf 'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: "ssdp:discover"\r\nMX: 2\r\nST: ssdp:all\r\n\r\n' \
		| "$DS" -t3 -T3 - "UDP4-DATAGRAM:239.255.255.250:1900,bind=$DLAN:0" 2>/dev/null | tr -d '\r' > "$DT/ssdp"
	awk 'function out() { if (ip != "" && sv != "") print "USRV\t" ip "\t" sv; ip = sv = "" }
		/^HTTP\// { out() } { l = tolower($0) }
		l ~ /^location:/ && match($0, /:\/\/[0-9.]+[:\/]/) { ip = substr($0, RSTART + 3, RLENGTH - 4) }
		l ~ /^server:/ { sv = $0; sub(/^[^:]*: */, "", sv); gsub(/[^ -~]|["\\|~;<>]/, "", sv); sv = substr(sv, 1, 120) }
		END { out() }' "$DT/ssdp" | sort -u >> "$DT/r"
	sed -n 's/^[Ll][Oo][Cc][Aa][Tt][Ii][Oo][Nn]: *//p' "$DT/ssdp" | sort -u | head -n 40 | while read -r u; do
		case "$u" in http://[0-9]*) ;; *) continue ;; esac
		ip=$(printf '%s\n' "$u" | sed -n 's|^http://\([0-9.]*\)[:/].*|\1|p'); [ -n "$ip" ] || continue
		# only from a device on the LAN (one in the ARP table): never the router itself, or anything a reply points elsewhere
		awk -v ip="$ip" '$1 == ip && $3 != "0x0" { f = 1 } END { exit !f }' "$PROC/net/arp" 2>/dev/null || continue
		curl -s --proto =http --max-redirs 0 -m 3 --max-filesize 65536 "$u" < /dev/null 2>/dev/null | tr -d '\r\n\t' > "$DT/desc"
		f=""; for k in manufacturer modelName modelNumber; do
			v=$(sed -n "s:.*<$k>\([^<]*\)</$k>.*:\1:p" "$DT/desc" | head -n 1 | tr -cd ' -~' | tr -d '|~;<>"\\' | cut -c1-60); [ -n "$v" ] && f="$f${f:+; }$k=$v"
		done
		[ -n "$f" ] && printf 'UPNP\t%s\t%s\n' "$ip" "$f"
	done | sort -u >> "$DT/r"
	# by address, then by MAC (the ARP table); merged into DISC: this round's answers replace a device's older ones
	awk -F'\t' -v arp="$PROC/net/arp" -v now="$(now)" 'function txt(h,   n, i, l, s, j, x) {   # hex name -> text
			n = split(h, l, "."); s = ""
			for (i = 1; i <= n; i++) { x = ""; for (j = 1; j < length(l[i]); j += 2) x = x sprintf("%c", (index("0123456789abcdef", substr(l[i], j, 1)) - 1) * 16 + index("0123456789abcdef", substr(l[i], j + 1, 1)) - 1); s = s (s == "" ? "" : ".") x }
			return s
		}
		function srt(str, sep,   a, n, i, j, x, o) {   # the parts in order, so a device always asks the same question
			n = split(str, a, sep)
			for (i = 2; i <= n; i++) { x = a[i]; for (j = i - 1; j >= 1 && a[j] > x; j--) a[j + 1] = a[j]; a[j + 1] = x }
			o = ""; for (i = 1; i <= n; i++) if (a[i] != "" && a[i] != a[i - 1]) o = o (o == "" ? "" : sep) a[i]
			return o
		}
		BEGIN { while ((getline line < arp) > 0) { split(line, f, " "); m = toupper(f[4]); if (f[3] != "0x0" && m ~ /^[0-9A-F:]+$/ && length(m) == 17 && m != "00:00:00:00:00:00") mac[f[1]] = m } }
		$1 == "PTR" { svc[$3] = txt($2) } $1 == "SRV" { host[$2] = $3 } $1 == "A" { ip[$2] = $3 } $1 == "TXT" { tx[$2] = $3 }
		$1 == "UPNP" { up[$2] = up[$2] (up[$2] == "" ? "" : "; ") $3; seen[$2] = 1 }
		$1 == "USRV" { us[$2] = us[$2] (us[$2] == "" ? "" : "~") $3; seen[$2] = 1 }
		END {
			for (i in host) if ((host[i] in ip) && (i in svc)) {
				d = ip[host[i]]; t = svc[i]
				if (t !~ /^_[A-Za-z0-9-]+\._(tcp|udp)\.local$/) continue
				seen[d] = 1; if (index(" " S[d] " ", " " t " ") == 0) S[d] = S[d] (S[d] == "" ? "" : " ") t
				if (tx[i] != "") M[d] = M[d] (M[d] == "" ? "" : ";") tx[i]
			}
			for (d in seen) if (d in mac) print mac[d] "|" srt(S[d], " ") "|" substr(srt(M[d], ";"), 1, 200) "|" up[d] "|" us[d] "|" now
		}' "$DT/r" | sort > "$DT/new"
	DISC_N=$(grep -c . "$DT/new")
	if [ "$DISC_N" -gt 0 ]; then
		{ cat "$DISC" 2>/dev/null | awk -F'|' 'NR == FNR { n[$1] = 1; next } !($1 in n)' "$DT/new" - | tail -n 299; cat "$DT/new"; } > "$DT/all" \
			&& mv -f "$DT/all" "$DISC"
	fi
	rm -rf "$DT"
	return 0
}
# A device just joined (from dnsmasq's lease script): wait a minute, so it has settled and announced itself, then ask the
# network once, for it and every device that joined meanwhile, and look up what they said.
DISC_DELAY="${AR_DISC_DELAY:-60}"   # AR_DISC_DELAY: test hook only
case "$DISC_DELAY" in ''|*[!0-9]*) DISC_DELAY=60 ;; esac
disc_new() {
	fb_on && tmpd && [ -n "$(socat_bin)" ] || return 0
	( exec 8>&- 6>"$TMPD/disc.wait"; flock -n 6 || exit 0     # one wait at a time: devices joining meanwhile go along
	  sleep "$DISC_DELAY"; flock -u 6
	  exec 7>"$TMPD/disc.lock"; flock -w 120 7 || exit 0
	  disc_run "$(socat_bin)" || exit 0
	  [ "$DISC_N" -gt 0 ] && touch "$TMPD/fb_new"
	  log "A device joined: $DISC_N device(s) answered over mDNS or UPnP"
	  fb_tick wait ) < /dev/null > /dev/null 2>&1 &
}
# For the page: "MAC>services>model fields>UPnP description|" for each device that said what it is
disc_export() {
	cat "$DISC" 2>/dev/null | awk -F'|' '$1 ~ /^[0-9A-F:]+$/ && length($1) == 17 { printf "%s>%s>%s>%s|", $1, $2, $3, $4 }' | tr -d '\000-\037"\\<'
}
fb_waiting() {   # MACs with a lease from the router and no fingerprint yet (they're looked up when they next renew it)
	{
		own_macs
		node_list | while read -r m ip model; do echo "$m"; node_stas "$m" | tr ' ' '\n'; done
		cut -d' ' -f1 "$DHCP_FP" 2>/dev/null
	} | tr 'a-f' 'A-F' | grep . > "$TMPD/wait.skip"
	awk 'NR == FNR { skip[$1] = 1; next } { m = toupper($2) } length(m) == 17 && m ~ /^[0-9A-F:]+$/ && !(m in skip) && !seen[m]++ { print m }' \
		"$TMPD/wait.skip" "$ROOT/var/lib/misc/dnsmasq.leases" 2>/dev/null
	rm -f "$TMPD/wait.skip"
}
fb_recognised() {   # -> "recognised total": devices Fingerbank has an answer for, out of those Arteria asks about
	fb_export | tr '|' '\n' | awk -F'>' 'NF >= 3 { t++; if ($3 != "") r++ } END { print r + 0, t + 0 }'
}
fb_recognise() {   # -> FB_MSG; progress goes to fb.htm
	fb_on || { FB_MSG="Fingerbank is off: add a key first."; return 1; }
	have curl || { FB_MSG="This router has no curl, which Fingerbank lookups need."; return 1; }
	S=$(socat_bin); a=""
	if [ -n "$S" ]; then
		fb_msg "" "Asking the devices on the network what they are..."; fb_status
		( exec 8>&- 7>"$TMPD/disc.lock"; flock -w 120 7; disc_run "$S"; echo "$DISC_N" > "$TMPD/disc_n" ) < /dev/null > /dev/null 2>&1
		DISC_N=$(cat "$TMPD/disc_n" 2>/dev/null); rm -f "$TMPD/disc_n"
		case "$DISC_N" in ''|*[!0-9]*) FB_MSG="Couldn't ask the network: the router's LAN address is missing."; return 1 ;; esac
		a="$DISC_N device(s) answered. "
		log "Recognise now: $DISC_N device(s) answered over mDNS or UPnP"
	fi
	fb_msg "" "${a}Looking them up with Fingerbank..."; fb_status
	# every device's question again, as far as the hourly limit allows (one round at a time, as in the background)
	FB_SINCE=$(now)
	( exec 8>&- 7>"$TMPD/fb.lock"; flock -w 120 7 || exit 0
	  i=0; while [ $i -lt 10 ] && [ -n "$(fb_next)" ]; do
		fb_lookup; i=$((i + 1))
		case "$(cat "$TMPD/fb_state" 2>/dev/null)" in badkey|"wait "*) break ;; esac
	  done ) < /dev/null > /dev/null 2>&1
	set -- $(fb_recognised)
	FB_MSG="${a}Fingerbank has an answer for $1 of $2 device(s)."
	case "$(cat "$TMPD/fb_state" 2>/dev/null)" in
		badkey) FB_MSG="$FB_MSG Fingerbank turned the key down: save a new one." ;;
		"wait "*) FB_MSG="$FB_MSG The rest are looked up when Fingerbank answers again (at most 100 lookups an hour)." ;;
	esac
	[ -n "$S" ] || FB_MSG="$FB_MSG To recognise more, let Arteria ask devices what they are: install Entware's socat (opkg install socat), then Recognise now again."
	return 0
}
fb_ui_now() {
	touch "$TMPD/fb_busy"; fb_msg "" "Recognising devices..."; fb_status
	if fb_recognise; then fb_msg 1 "$FB_MSG"; else fb_msg 0 "$FB_MSG"; fi
	log "Fingerbank: $FB_MSG"
	rm -f "$TMPD/fb_busy"; fb_status
}
fb_ui_off() {
	touch "$TMPD/fb_busy"; fb_msg "" "Turning Fingerbank off..."; fb_status
	fb_off quiet; log "Fingerbank turned off"
	fb_msg 1 "Fingerbank is off. The key, its answers and what devices said are deleted, and dnsmasq runs the router's own lease script directly again."
	rm -f "$TMPD/fb_busy"; fb_status
}

# ---- web UI (Merlin Addons API) ------------------------------------------------
# Insert line $2 into the menu copy $1, in a tab list right after the tab for url $3 and the hidden
# sub-pages that follow it (its "__INHERIT__" tabs). Only tab-list lines count: some models'
# menuTree.js also builds tabs in code ("menuTree.list[i].tab[index] = {url: ...}"), never touched.
after_tab() {   # file line url
	awk -v e="$2" -v u="$3" '
		ins { if ($0 ~ /tabName: "__INHERIT__"/ && $0 !~ /url: "NULL"/) { print; next } print e; ins = 0 }
		index($0, "{url: \"" u "\", tabName:") && $0 ~ /^[ \t]*[{]url: / { ins = 1 }
		{ print }' "$1" > "$1.2" && mv -f "$1.2" "$1"
}
tab_count() { grep -c "^[[:space:]]*{url: \"$2\", tabName:" "$1"; }   # file url

# Where the menu entry goes: Traffic Analyzer, right after Statistic. Merlin shows that menu on models
# with Trend Micro's engine (bwdpi, like the RT-AX86U) in router mode. Routers without it: Network
# Tools, after all its other tabs (just before the list's closing "NULL" entry). Sets where (the menu's
# name) and added (lines added); if neither fits, where stays empty and the menu is left alone.
menu_insert() {   # file line
	where=""; added=0; ta=0
	case ",$(nvram get rc_support | tr ' ' ',')," in *,bwdpi,*) ta=1 ;; esac
	case "$(nvram get sw_mode)" in ''|1) ;; *) ta=0 ;; esac   # hidden in access point, repeater and bridge modes
	if [ $ta = 1 ] && [ "$(tab_count "$1" TrafficAnalyzer_Statistic.asp)" = 1 ]; then
		after_tab "$1" "$2" TrafficAnalyzer_Statistic.asp && added=1 && where="Traffic Analyzer"
	elif [ "$(grep -c 'index: "menu_NekworkTool"' "$1")" = 1 ]; then
		awk -v e="$2" '
			/index: "menu_/ { nt = ($0 ~ /index: "menu_NekworkTool"/) }
			nt && /^[ \t]*[{]url: "NULL"/ { print e; nt = 0 }
			{ print }' "$1" > "$1.2" && mv -f "$1.2" "$1" && added=1 && where="Network Tools"
	fi
}

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
	tmpd
	webui_lock || return 1
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
	# The copy other addons share. Only root's own file is trusted (anyone can create /tmp/menuTree.js first, and
	# its content becomes the menu every router page runs); otherwise start from the firmware's, renamed into place
	# so a planted link is replaced, never written through.
	if ! ours_file "$TMP_MENUTREE"; then
		cp -f "$MENUTREE" "$TMPD/menuTree.base" && mv -f "$TMPD/menuTree.base" "$TMP_MENUTREE" || { flock -u 9; return 1; }
	fi
	new="$TMPD/menuTree.$$"   # in our own folder: a name in /tmp could be a link someone planted
	sed "/tabName: \"$TITLE\"/d" "$TMP_MENUTREE" > "$new"
	before=$(wc -l < "$new")
	entry="{url: \"$am_webui_page\", tabName: \"$TITLE\"},"
	menu_insert "$new" "$entry"
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
	webui_lock || return 1
	if ours_file "$TMP_MENUTREE"; then
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
	tmpd
	stop_all          # a sampler can't survive a reboot, but an update replaces it
	mount_webui
	return 0
}

write_conf() {
	cat > "$CONF" <<EOF
# Arteria settings - run "$SCRIPT startup" after editing
INTERVAL=$INTERVAL               # seconds between samples while the page is open (1-10)
IDLE_STOP=$IDLE_STOP             # stop sampling this many seconds after the last page closed (20-300)
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

# AiMesh copies the router's own list of authorized SSH keys to every node whenever it syncs settings (saving
# a Wi-Fi or system page does), replacing the node's list: a key added only on a node is gone after the next
# sync. So the key is kept in the router's list too, and every sync carries it to the nodes. On the router
# itself it only lets in whoever holds node_key, which only root on this router can read.
router_key_add() {   # public-key-line base64 -> 0 if it was added now
	c=$(nvram get sshd_authkeys)
	case "$c" in *"$2"*) return 1 ;; esac
	nvram set sshd_authkeys="$(printf '%s\n%s\n' "$c" "$1" | sed '/^$/d')" && nvram commit
}
router_key_del() {   # base64: take Arteria's line out of the router's list (uninstall)
	c=$(nvram get sshd_authkeys)
	case "$c" in *"$1"*) ;; *) return 0 ;; esac
	nvram set sshd_authkeys="$(printf '%s\n' "$c" | grep -vF "$1")" && nvram commit
}
# The key works, but perhaps only from the node SSH server's current list: AiMesh writes the node's own list (in
# its nvram) from the router's at the next sync, and a node that restarts before then rebuilds its list from its own.
# So the key goes into the node's own list now too, logging in with the key: no password, nothing restarted.
node_keep_key() {   # ip   (uses $pub and $b64 from nodekey)
	node_try "$1" "" "k='$pub'; c=\$(nvram get sshd_authkeys); case \"\$c\" in *'$b64'*) ;; *) nvram set sshd_authkeys=\"\${c:+\$c
}\$k\" && nvram commit && echo arteria-added-key ;; esac; echo arteria-ok" || return 0
	case "$TRY_OUT" in *arteria-added-key*) say "  Added it to the node's own key list too, so it stays if the node restarts before the next sync." ;; esac
}

# Try the key on a node: key only, never a password (see ssh_batch). Gives up after 8 s.
# Returns 0 if the key works, 1 if not, 2 if it can't be tried without risking a password prompt
# (an older dbclient, run from a terminal).
node_try() {   # ip [pin] [command]   pin: also trust and pin the identity that answers (only after the person said yes)
	# command: run on the node, ending with "echo arteria-ok"; its output is left in TRY_OUT
	tmpd; ssh_home_init; o="$TMPD/try.$$"; TRY_ERR=""; TRY_HOSTKEY=0; TRY_NEW=0; TRY_FP=""; TRY_OUT=""; y=""; [ "$2" = pin ] && y=-y
	b=$(ssh_batch)
	if [ -z "$b" ] && has_tty; then TRY_ERR="this firmware's SSH client can't try a key without offering a password"; return 2; fi
	(HOME="$SSH_HOME" exec dbclient $b $y -p "$(ssh_port)" -i "$KEY" "$(ssh_user)@$1" "${3:-echo arteria-ok}") \
		< /dev/null > "$o" 2>&1 &
	p=$!; i=0
	while kill -0 "$p" 2>/dev/null; do
		[ $i -ge 8 ] && { kill "$p" 2>/dev/null; break; }
		sleep 1; i=$((i + 1))
	done
	grep -q '^arteria-ok' "$o" 2>/dev/null; rc=$?
	grep -qi 'host key mismatch' "$o" 2>/dev/null && TRY_HOSTKEY=1
	grep -qi 'not in the trusted hosts' "$o" 2>/dev/null && TRY_NEW=1   # first contact: nothing pinned for this address yet
	TRY_FP=$(grep -o '[A-Za-z0-9-]* fingerprint [A-Za-z0-9:+/=]*' "$o" 2>/dev/null | head -1)
	TRY_ERR=$(grep -v '^arteria-ok' "$o" 2>/dev/null | tail -1 | tr -cd '\040-\176' | cut -c1-120)
	TRY_OUT=$(head -c 512 "$o" 2>/dev/null | tr -cd '\012\040-\176')
	rm -f "$o"
	return $rc
}

# For text that may be posted in a bug report: addresses and user names out.
scrub() { sed 's/[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}/IP/g; s/[0-9A-Fa-f]\{2\}\(:[0-9A-Fa-f]\{2\}\)\{5\}/MAC/g; s/[A-Za-z0-9._-]*@/user@/g'; }

# One round of the script the page runs on a node: whether it works there, how many devices it reads and how
# long that takes. The page counts a node as answering while its output is at most 3 rounds + 4 s old, so a round
# much slower than that shows as "not answering" even though key login works.
node_probe() {   # ip -> PROBE_MSG; 0 if a round came back
	tmpd; ssh_home_init; s="$TMPD/probe.$$.sh"; o="$TMPD/probe.$$"; PROBE_MSG=""
	write_node_script 1 > "$s"
	t0=$(now)
	(HOME="$SSH_HOME" exec dbclient $(ssh_batch) -p "$(ssh_port)" -i "$KEY" "$(ssh_user)@$1" 'sh -s') < "$s" > "$o" 2>&1 &
	p=$!; i=0
	while kill -0 "$p" 2>/dev/null; do
		[ $i -ge 30 ] && { kill "$p" 2>/dev/null; break; }
		sleep 1; i=$((i + 1))
	done
	t=$(( $(now) - t0 )); [ $t -ge 1 ] || t=1
	if grep -q '^#E' "$o" 2>/dev/null; then
		PROBE_MSG="reads $(grep -c '^S ' "$o") device(s), one round takes about $t s"
		[ $t -gt $((INTERVAL * 2 + 4)) ] && PROBE_MSG="$PROBE_MSG: too slow, the page shows it as not answering"
		rc=0
	elif [ $i -ge 30 ]; then PROBE_MSG="reading its devices took over 30 s"; rc=1
	else
		e=$(grep -v '^#B\|^S \|^#E' "$o" 2>/dev/null | tr -cd '\012\040-\176' | grep . | tail -1 | scrub | cut -c1-120)
		PROBE_MSG="reading its devices failed${e:+: $e}"; rc=1
	fi
	rm -f "$s" "$o"
	return $rc
}

nodes_cmd() {   # [test]
	if [ "$NODES" != on ]; then say "Reading AiMesh nodes is off (NODES=off in $CONF): the page shows backhaul totals only."; fi
	list=$(node_list)
	if [ -z "$list" ]; then nodes_none_why; return 0; fi
	say "AiMesh nodes (SSH port $(ssh_port), user $(ssh_user)):"
	printf '%s\n' "$list" | while read -r mac ip model; do
		al=$(node_alias "$mac")
		line="  ${al:-$model} ($model, $ip)"
		if [ "$1" = test ]; then
			if [ ! -s "$KEY" ]; then line="$line: no key yet, run '$SCRIPT nodekey'"
			else
				node_try "$ip"; rc=$?
				if [ $rc -eq 0 ]; then node_probe "$ip"; line="$line: key login OK, $PROBE_MSG"
				elif [ $rc -eq 2 ]; then line="$line: can't test here ($TRY_ERR); open the page, it shows whether the node answers"
				elif [ "$TRY_NEW" = 1 ]; then line="$line: not trusted yet (Arteria hasn't connected to it before); run '$SCRIPT nodekey', which shows its fingerprint first"
				else line="$line: key login failed${TRY_ERR:+ ($TRY_ERR)}; run '$SCRIPT nodekey'"
				fi
			fi
		else
			line="$line: $(node_state "$(node_file "$mac")")"
		fi
		say "$line"
	done
}

# The same change nodekey makes, as one line to paste in a shell on the node: add the router's key to
# the node's authorized keys (keeping any already there), unless it's listed, then restart its SSH server.
nodekey_line() {   # public-key-line
	b=$(printf '%s' "$1" | cut -d' ' -f2)
	printf "k='%s'; c=\$(nvram get sshd_authkeys); case \"\$c\" in *'%s'*) echo 'The node already has the key.' ;; *) nvram set sshd_authkeys=\"\$(printf '%%s\\\\n%%s\\\\n' \"\$c\" \"\$k\" | sed '/^\$/d')\" && nvram commit && echo 'Key added. Restarting SSH: this session may close.' && service restart_sshd ;; esac\n" "$1" "$b"
}
nodekey_print() {
	[ -s "$KEY" ] || make_key || die "Couldn't create the key in $KEY"
	pub=$(pub_key); [ -n "$pub" ] || die "Couldn't read the public key from $KEY"
	say "To give a node the router's key yourself: log in to the node over SSH (from any computer,"
	say "with your router admin name and password), then paste this line and press Enter:"
	say ""
	nodekey_line "$pub"
	say ""
	say "It adds the key to the node's authorized keys (Administration > System > Authorized Keys on the"
	say "router lists only the router's own). Then run '$SCRIPT nodes test' here."
}

# A node that was reset or replaced has a new SSH identity (host key), and the one pinned for it no longer
# matches. Something else answering at the node's address looks exactly the same, and the next step sends
# it the admin password, so the old identity is only forgotten when the person at the terminal says so.
trust_new_identity() {   # ip -> 0 if the old identity was forgotten
	say "  This node's SSH identity isn't the one Arteria saw before. That's expected if the node was reset,"
	say "  updated or replaced. If it wasn't, something else may be answering at $1: answer n."
	printf '  Trust the new identity? (y/n) '
	read -r a < /dev/tty || a=n
	case "$a" in [yY]*) ;; *) say "  Left alone."; return 1 ;; esac
	h=$(printf '%s' "$1" | sed 's/\./\\./g')
	[ -f "$SSH_HOME/.ssh/known_hosts" ] && sed -i "/^$h /d; /^\[$h\]:/d" "$SSH_HOME/.ssh/known_hosts"
	return 0
}

# The first time Arteria reaches a node there is no pinned identity to check it against: whatever answers at the
# address would get the admin password. Say so, show what answered, and go on only if the person says yes.
trust_first_contact() {   # ip -> 0 to go ahead
	say "  Arteria hasn't connected to $1 before, so it can't tell the node from something else answering there."
	say "  It answered with ${TRY_FP:-an SSH identity}. Go on only if the node is up and nothing else is on the network"
	say "  that shouldn't be (or answer n and use '$SCRIPT nodekey print' from your own computer instead)."
	printf '  Trust it? (y/n) '
	read -r a < /dev/tty || a=n
	case "$a" in [yY]*) return 0 ;; *) say "  Left alone."; return 1 ;; esac
}

# Give each node the router's Arteria key. Asks for the node's password once (the router's admin
# password, which AiMesh nodes share); it goes to the node only and is never stored. The key is
# added to the node's authorized keys, keeping any that are already there.
nodekey() {   # [node-ip | print]
	[ "$1" = print ] && { nodekey_print; return; }
	have dbclient && have dropbearkey || die "This firmware has no SSH client (dbclient/dropbearkey)."
	[ "$(nvram get sshd_enable)" = "0" ] && die "SSH is off on the router (Administration > System > Enable SSH). AiMesh nodes follow that setting: turn it on (LAN only is enough) and try again."
	[ -t 0 ] || die "nodekey asks for each node's password, so run it in a terminal."
	tmpd
	[ -s "$KEY" ] || make_key || die "Couldn't create the key in $KEY"
	pub=$(pub_key); b64=$(printf '%s' "$pub" | cut -d' ' -f2)
	[ -n "$b64" ] || die "Couldn't read the public key from $KEY"
	ssh_home_init
	if router_key_add "$pub" "$b64"; then
		say "Added the key to the router's own SSH key list too (Administration > System > Authorized Keys): AiMesh"
		say "copies that list to the nodes whenever it syncs settings, so they keep the key."
	fi
	list=$(node_list)
	[ -n "$1" ] && list=$(printf '%s\n' "$list" | awk -v ip="$1" '$2 == ip')
	if [ -z "$list" ]; then [ -n "$1" ] && die "No AiMesh node at $1 found."; nodes_none_why; exit 1; fi
	fails=0; sync=0
	# With password login off (Administration > System > Allow Password Login), a node takes no password, but
	# AiMesh still copies the router's key list (which has the key now, see above) to it at its next settings sync.
	nopass=0; [ "$(nvram get sshd_pass)" = "0" ] && nopass=1
	# the remote side: add the key unless it's there, then restart its SSH server (after we've disconnected)
	cmd="k='$pub'; c=\$(nvram get sshd_authkeys); case \"\$c\" in *'$b64'*) echo arteria-had-key ;; *) nvram set sshd_authkeys=\"\${c:+\$c
}\$k\"; nvram commit; echo arteria-added-key; (sleep 2; service restart_sshd) > /dev/null 2>&1 & ;; esac"
	printf '%s\n' "$list" > "$TMPD/nodekey.list"
	while read -r mac ip model; do
		al=$(node_alias "$mac")
		say ""
		say "${al:-$model} ($model, $ip)"
		node_try "$ip"; rc=$?
		if [ $rc -eq 0 ]; then say "  Already has the key."; node_keep_key "$ip"; continue; fi
		if [ "$TRY_HOSTKEY" = 1 ] && ! trust_new_identity "$ip"; then fails=$((fails + 1)); continue; fi
		if [ "$TRY_NEW" = 1 ] && ! trust_first_contact "$ip"; then fails=$((fails + 1)); continue; fi
		if [ "$TRY_HOSTKEY" = 1 ] || [ "$TRY_NEW" = 1 ]; then   # trusted now: the key may already be there (an AiMesh sync)
			node_try "$ip" pin && { say "  Key login works."; node_keep_key "$ip"; continue; }
		fi
		if [ $nopass = 1 ]; then say "  Password login over SSH is off on the router, so the key reaches this node with the next AiMesh sync."; sync=$((sync + 1)); continue; fi
		say "  Enter the node's password (your router's admin password). It goes to the node only and isn't stored."
		out=$(HOME="$SSH_HOME" dbclient -y -p "$(ssh_port)" "$(ssh_user)@$ip" "$cmd" < /dev/tty 2>&1)
		case "$out" in *[Hh]ost\ key\ mismatch*)   # only seen here when the key couldn't be tried first (an older dbclient)
			if trust_new_identity "$ip"; then out=$(HOME="$SSH_HOME" dbclient -y -p "$(ssh_port)" "$(ssh_user)@$ip" "$cmd" < /dev/tty 2>&1); fi ;;
		esac
		case "$out" in
			*arteria-had-key*)   say "  The node already listed the key." ;;
			*arteria-added-key*) say "  Key added."; sleep 4 ;;
			*[Nn]o\ auth\ methods*) say "  The node doesn't take passwords over SSH, so the key reaches it with the next AiMesh sync."; sync=$((sync + 1)); continue ;;
			*) say "  Couldn't log in: $(printf '%s' "$out" | tail -1 | tr -cd '\040-\176' | cut -c1-120)"; fails=$((fails + 1)); continue ;;
		esac
		node_try "$ip"; rc=$?
		if [ $rc -eq 0 ]; then say "  Key login works."
		elif [ $rc -eq 2 ]; then say "  Can't test the key from here; open the page: it shows whether the node answers."
		else say "  The key still doesn't work${TRY_ERR:+ ($TRY_ERR)}."; fails=$((fails + 1))
		fi
	done < "$TMPD/nodekey.list"
	rm -f "$TMPD/nodekey.list" "$TMPD"/node.*.fail
	say ""
	if [ $sync -gt 0 ]; then
		say "$sync node(s) will get the key from the router: it is in the router's Authorized Keys (Administration >"
		say "System), and AiMesh copies that list to the nodes when it syncs settings. Start a sync by saving a setting"
		say "in the router's web page (saving Wireless > General works; Wi-Fi restarts briefly), wait a few minutes"
		say "until the node is back in the AiMesh list, then run '$SCRIPT nodes test'."
		[ $fails -eq 0 ] && return 0
		say ""
	fi
	[ $fails -eq 0 ] && say "Done. Reopen the page to see each node's devices." && return 0
	say "$fails node(s) not set up. Check that SSH is on and the password is right."
	say ""
	say "If the password is right and the node still refuses it: ASUS firmware locks out an address for a"
	say "while after several failed logins, and then refuses even the right password from it. The node's"
	say "/tmp/protect_srv.log shows it. Wait a while (or reboot the node) and run '$SCRIPT nodekey' again,"
	say "or add the key on the node yourself: '$SCRIPT nodekey print' shows the line to paste there."
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
	tmpd; t="$TMPD/selftest.$$"; printf 'ab' > "$t" 2>/dev/null; lack=""   # in our own folder: a name in /tmp could be a link
	[ "$(tail -c 1 "$t" 2>/dev/null)" = "b" ] || lack="$lack tail-c"
	date -r "$t" +%s >/dev/null 2>&1 || lack="$lack date-r"
	[ -O "$t" ] || lack="$lack test-O"
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
	if [ -z "$nl" ] && [ "$(nodes_joined)" -gt 0 ]; then
		ck_warn "AiMesh lists $(nodes_joined) node(s), but none is in the router's current AiMesh list (empty for a few minutes after a settings save). Run check again shortly."
	elif [ -z "$nl" ]; then
		ck_ok "No AiMesh nodes (the map shows the router and its clients)"
	elif ! have dbclient || ! have dropbearkey; then
		ck_warn "AiMesh nodes found, but no SSH client: the map shows their backhaul totals only."
	else
		n=$(printf '%s\n' "$nl" | wc -l | tr -d ' ')
		ck_ok "$n AiMesh node(s): $(node_models "$nl")"
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
# Whole files only: the page ends with </html> and the script with its dispatch (the "esac" on its last
# line), so a download that was cut short is never installed.
whole_page() { [ -s "$1" ] && tail -n 3 "$1" | grep -q '</html>'; }
whole_script() { [ "$(tail -n 1 "$1" 2>/dev/null)" = "esac" ] && sh -n "$1" 2>/dev/null; }
script_version() { sed -n 's/^VERSION="\([0-9][0-9.]*\)".*/\1/p' "$1" 2>/dev/null | head -1; }
asp_matches() { whole_page "$1" && grep -q "arteria-version: $VERSION " "$1"; }

# Download $1 to $2 [quiet]. Up to 3 attempts; succeeds only if a non-empty file arrived.
fetch() {
	for attempt in 1 2 3; do
		rm -f "$2" 2>/dev/null; mkdir -p "$(dirname "$2")"
		code=$(curl -sL --proto =https --proto-redir =https --retry 2 --connect-timeout 15 -w '%{http_code}' -o "$2" "$1" 2>/dev/null); rc=$?
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
	t=$(curl -fsL --proto =https --proto-redir =https --retry 2 --connect-timeout 15 -H 'Accept: application/vnd.github+json' \
		"https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
		| sed -n 's/.*"tag_name": *"\([0-9][0-9.]*\)".*/\1/p' | head -1)
	[ -n "$t" ] || t=$(curl -fsI --proto =https --retry 2 --connect-timeout 15 -o /dev/null -w '%{redirect_url}' \
		"https://github.com/$REPO/releases/latest" 2>/dev/null \
		| sed -n 's#.*/releases/tag/\([0-9][0-9.]*\)$#\1#p')
	echo "$t"
}
# Why there's no latest release to install: none has been published yet, or GitHub can't be reached.
no_release_why() {
	code=$(curl -s --proto =https --connect-timeout 15 -o /dev/null -w '%{http_code}' "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null)
	case "$code" in
		404) printf "No release of %s has been published yet, so there's nothing to update to. '%s update dev' installs the newest code on main (a development version)." "$TITLE" "$SCRIPT" ;;
		''|000) printf "Couldn't reach GitHub (no internet connection on the router, or DNS?); nothing was changed." ;;
		*) printf "GitHub didn't list the latest release (HTTP %s; it may be rate-limiting this address for a while); nothing was changed." "$code" ;;
	esac
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
	mkdir -p "$ADDON_DIR" "$SCRIPTS_DIR"; tmpd
	if [ "$src" != "$ADDON_DIR" ]; then
		# The script must be root's own (installing from /tmp, anyone could have created that file first). A page
		# next to it is used only if it is root's own too; otherwise it is downloaded.
		ours_file "$0" || die "$0 isn't a file only root can change. Download arteria.sh again into a folder only root can write (see the README) and run install from there."
		asp="$src/$NAME.asp"
		if ! ours_file "$asp" || ! asp_matches "$asp"; then   # missing, someone else's, or left over from another version
			say "Downloading the web page from GitHub..."
			asp="$TMPD/$NAME.asp.dl"; got=0
			if [ -n "$AR_RAW_URL" ]; then bases="$RAW_URL"; else bases="$RAW_BASE/$VERSION release"; fi   # releases only, never main
			for base in $bases; do
				[ "$base" = release ] && { base=$(release_url); [ -n "$base" ] || continue; }
				if fetch "$base/$NAME.asp" "$asp" quiet; then
					asp_matches "$asp" && { got=1; break; }
				fi
			done
			[ $got -eq 1 ] || { rm -f "$asp"; die "Couldn't get $NAME.asp $VERSION. Put it in the same folder as $NAME.sh and run install again."; }
		fi
		stop_all
		# rename into place: a running copy of the old script (e.g. during update) keeps reading its own file
		cp -f "$0" "$SCRIPT.new" && mv -f "$SCRIPT.new" "$SCRIPT"
		cp -f "$asp" "$PAGE_SRC.new" && mv -f "$PAGE_SRC.new" "$PAGE_SRC"
		rm -f "$TMPD/$NAME.asp.dl"
	fi
	chmod 755 "$SCRIPT"
	if [ -n "$AR_BUILD" ]; then printf '%s\n' "$AR_BUILD" > "$BUILD_FILE"; else rm -f "$BUILD_FILE"; fi
	[ -f "$CONF" ] || write_conf
	hook_add services-start "$SCRIPT startup &"
	hook_add service-event "$SCRIPT service_event \"\$@\" &"
	fb_on && fb_hooks add && fb_hooked && fb_rehook
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

# update and update dev: download the script from base URL $1 into a fresh folder of ours ($dl) and check
# it is whole; $new is its version. $2 names the source in messages, $3 is fetch's "quiet".
get_script() {   # base source [quiet]
	tmpd; dl="$TMPD/update.$$"; rm -rf "$dl"; mkdir "$dl" || die "Couldn't create $dl"
	fetch "$1/$NAME.sh" "$dl/$NAME.sh" $3 || { rm -rf "$dl"; die "Couldn't download $NAME.sh from $2; nothing was changed."; }
	new=$(script_version "$dl/$NAME.sh")
	if [ -z "$new" ] || ! whole_script "$dl/$NAME.sh"; then
		rm -rf "$dl"; die "The script from $2 looks incomplete; nothing was changed."
	fi
}
# ...then its page, which must be whole and the same version.
get_page() {   # base source [quiet]
	if ! fetch "$1/$NAME.asp" "$dl/$NAME.asp" $3 || ! whole_page "$dl/$NAME.asp" || ! grep -q "arteria-version: $new " "$dl/$NAME.asp"; then
		rm -rf "$dl"; die "Couldn't download the matching web page from $2; nothing was changed."
	fi
}
# ...and install them over this one. Settings and node access are kept; install writes the development-
# version mark from AR_BUILD ($1), or removes it for a release.
install_dl() {   # [build]
	AR_BUILD="$1" sh "$dl/$NAME.sh" install < /dev/null; rc=$?
	rm -rf "$dl"
	return $rc
}

update() {   # [force]  fetch the latest release from GitHub and reinstall over this one
	say "Checking GitHub for updates..."
	rel=$(release_url)
	[ -n "$rel" ] || die "$(no_release_why)"
	get_script "$rel" "the latest release"
	if [ "$new" = "$VERSION" ] && [ "$1" != "force" ] && [ ! -f "$BUILD_FILE" ]; then
		rm -rf "$dl"; say "Already up to date ($VERSION)."; return 0
	fi
	if ver_gt "$VERSION" "$new" && [ "$1" != "force" ]; then
		rm -rf "$dl"
		say "This is $VERSION$( [ -f "$BUILD_FILE" ] && printf ' (a development version)'), newer than the latest release ($new). Nothing was changed; 'update force' installs $new."
		return 0
	fi
	get_page "$rel" "the latest release"
	say "Updating $VERSION -> $new (settings and node access are kept)"
	install_dl
}

build_text() {   # "" for a release; "development version: main @ 1a2b3c4, installed 2026-11-11 23:30"
	[ -f "$BUILD_FILE" ] || return 0
	read -r kind br sha when < "$BUILD_FILE"
	[ "$kind" = dev ] && printf 'development version: %s @ %s, installed %s' "$br" "$sha" "$when"
}
ver_line() { printf '%s %s' "$TITLE" "$VERSION"; b=$(build_text); [ -n "$b" ] && printf ' (%s)' "$b"; return 0; }   # "Arteria 1.0.0 (development version: ...)"
update_dev() {   # [branch]
	br=${1:-main}
	case "$br" in ''|[-./]*|*..*|*//*|*/|*[!A-Za-z0-9._/-]*|refs/*|pull/*) die "'$br' isn't a branch name; nothing was changed." ;; esac
	say "Looking up the newest commit on $br..."
	# Only a branch of this repository, by its commit. GitHub also serves commits and pull requests
	# from other people's forks under this repository's addresses, and those aren't reviewed here.
	sha=$(curl -fsL --proto =https --proto-redir =https --retry 2 --connect-timeout 15 -H 'Accept: application/vnd.github+json' \
		"https://api.github.com/repos/$REPO/branches/$br" 2>/dev/null \
		| grep -o '"sha": *"[0-9a-f]\{40\}"' | head -1 | grep -o '[0-9a-f]\{40\}')
	[ -n "$sha" ] || die "GitHub has no branch '$br' in $REPO, or couldn't be reached; nothing was changed."
	get_script "$RAW_BASE/$sha" "'$br'" quiet
	get_page "$RAW_BASE/$sha" "'$br'" quiet
	short=$(printf '%s' "$sha" | cut -c1-7)
	say "Installing the development version of $br ($new, commit $short). Settings and node access are kept;"
	say "'$SCRIPT update' goes back to the latest release."
	b="dev $br $short $(date '+%Y-%m-%d %H:%M')"
	install_dl "$b"; rc=$?
	[ $rc -eq 0 ] && log "development version installed: $br @ $short ($new)"
	return $rc
}

uninstall() {
	say "Removing $TITLE"
	stop_all
	unmount_webui
	hook_del services-start
	hook_del service-event
	fb_off quiet
	b64=$([ -s "$KEY" ] && pub_key | cut -d' ' -f2)
	[ -n "$b64" ] && router_key_del "$b64"
	rm -rf "$(web_dir)" "$TMPD" "$ADDON_DIR"
	say "Removed. The router's key for the nodes was deleted with it, and taken out of the router's own SSH key"
	say "list; the copy each node lists goes at the next AiMesh sync, and no longer opens anything anyway."
}

status() {
	say "$(ver_line)"
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
	[ -n "$nl" ] && say "Nodes:       $(node_models "$nl") (details: '$SCRIPT nodes test')"
	if fb_on; then
		say "Fingerbank:  on, $(fb_counts)$(fb_hooked || printf ' (dnsmasq not using it yet)')"
	else
		say "Fingerbank:  off ('$SCRIPT fingerbank' turns device recognition on, with your own free key)"
	fi
	say "amtm updates: $AMTM_UPDATE"
}
fb_counts() {   # "5 devices fingerprinted, 4 answered Recognise now, 3 kinds of device known to Fingerbank, last reply 200"
	d=$(fb_devices); a=$(awk -F'\t' '$2 == 200 { n++ } END { print n + 0 }' "$FB_CACHE" 2>/dev/null); q=$(grep -c . "$DISC" 2>/dev/null)
	printf '%s devices fingerprinted, ' "${d:-0}"; [ "${q:-0}" -gt 0 ] && printf '%s answered Recognise now, ' "$q"
	printf '%s kinds of device known to Fingerbank' "${a:-0}"
	l=$(cut -d' ' -f1 "$TMPD/fb_last" 2>/dev/null); [ -n "$l" ] && printf ', last reply %s' "$l"
	case "$(cat "$TMPD/fb_state" 2>/dev/null)" in badkey) printf ', KEY TURNED DOWN: run fingerbank again' ;; "wait "*) printf ', waiting before the next lookup' ;; esac
	return 0
}

# Everything a bug report needs, and nothing personal: no device names, no MAC or IP addresses.
debug() {
	say "$(ver_line)"
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
		f=$(node_file "$mac")
		if sampler_running; then st=$(node_state "$f"); else st="(page closed)"; fi
		say "  $model: backhaul stations=$(node_stas "$mac" | wc -w | tr -d ' ') state=$st"
		e=$(tail -c 2048 "$f.err" 2>/dev/null | tr -cd '\012\040-\176' | grep . | tail -1 | scrub | cut -c1-120)
		[ -n "$e" ] && say "    last SSH message: $e"
	done
	[ -n "$nl" ] && say "  (for each node's devices and round time, run: $SCRIPT nodes test)"
	# the first client's sta_info field names (the values are counters only)
	for p in $(radio_list); do
		x=${p%%:*}; m=$(wl -i "$x" assoclist 2>/dev/null | cut -d' ' -f2 | head -1)
		[ -n "$m" ] || continue
		say "sta_info fields ($x):"
		wl -i "$x" sta_info "$m" 2>/dev/null | sed 's/\([0-9A-Fa-f]\{2\}:\)\{2,\}[0-9A-Fa-f]\{2\}/xx:xx/g; s/^/  /' | head -80
		break
	done
	# How the router classifies devices, as numbers only (no names, addresses or MACs): the icon numbers
	# saved in the client list, the types and systems networkmap detected, the DHCP vendor classes cut to
	# their leading letters (the rest can name a phone model), and how many Wi-Fi clients use a private address.
	say "Saved icons:    $(nvram get custom_clientlist | tr '<' '\n' | awk -F'>' 'NF >= 4 && $4 ~ /^[0-9]+$/ { n[$4 + 0]++ } END { for (t in n) printf "%sx%d ", t, n[t] }')"
	f="$ROOT/jffs/nmp_cl_json.js"
	if [ -f "$f" ]; then
		say "Detected types: $(tr -d '\000-\037' < "$f" | tr '{' '\n' | sed -n 's/.*"type": *"\{0,1\}\([0-9][0-9]*\).*/\1/p' | sort -n | uniq -c | awk '{ printf "%sx%d ", $2, $1 }')"
		say "Detected OS:    $(tr -d '\000-\037' < "$f" | tr '{' '\n' | sed -n 's/.*"os_type": *"\{0,1\}\([0-9][0-9]*\).*/\1/p' | sort -n | uniq -c | awk '{ printf "%sx%d ", $2, $1 }')"
		say "Vendor classes: $(tr -d '\000-\037' < "$f" | tr '{' '\n' | sed -n 's/.*"vendorclass": *"\([A-Za-z]*\).*/\1/p' | cut -c1-12 | sort | uniq -c | awk '{ printf "%sx%d ", $2, $1 }')"
	fi
	say "Private MACs:   $(for p in $(radio_list); do wl -i "${p%%:*}" assoclist 2>/dev/null; done | awk '$2 ~ /^.[26AEae]/ { n++ } END { print n + 0, "of", NR }')"
	if fb_on; then
		cur=$(sed -n 's/^dhcp-script=//p' "$DNSMASQ_CONF" 2>/dev/null | tail -n 1)
		case "$cur" in
			"$TMPD"/dhcp_hook.*) ls="Arteria's, then $(sed -n 's/^exec \([^ ]*\).*/\1/p' "$cur" 2>/dev/null | grep . || echo none)" ;;
			'') ls="none" ;; *) ls="$cur, not Arteria's" ;;
		esac
		say "Fingerbank:     on; lease script: $ls; renewals: $(grep -q '^script-on-renewal' "$DNSMASQ_CONF" 2>/dev/null && echo yes || echo no); $(fb_counts); socat: $([ -n "$(socat_bin)" ] && echo yes || echo no)"
	else
		say "Fingerbank:     off"
	fi
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
	tmpd; alog="$TMPD/amtmupdate.log"
	( update ) > "$alog" 2>&1; rc=$?
	now_ver=$(script_version "$SCRIPT")
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
	say "       nodes [test] | nodekey [node-ip | print] | fingerbank [off | now | compare] | debug | sample | amtmupdate [check] | startup | version"
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
		say " Fingerbank:   $(fb_on && echo on || echo off)"
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
		say "  f  Device recognition with Fingerbank: turn $(fb_on && printf off || printf 'on (your own free key)')"
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
			f|F)
				if fb_on; then
					printf ' Turn Fingerbank off and delete its key and answers? (y/n) '; read -r a || a=n
					case "$a" in [yY]*) ( fingerbank_cmd off ) ;; *) say " Nothing changed." ;; esac
				else ( fingerbank_cmd ); fi
				menu_pause ;;
			e|E|q|Q) return 0 ;;
			'') ;;
			*) say " $opt isn't an option."; menu_pause ;;
		esac
	done
}

# Keep this dispatch last, ending in a bare "esac": update only installs a download that ends with it (whole_script).
case "$1" in
	'')            if [ -t 0 ] && [ -t 1 ]; then menu; else usage; fi ;;
	menu)          menu ;;
	install)       install ;;
	update)        if [ "$2" = dev ]; then update_dev "$3"; else update "$2"; fi; exit $? ;;
	check)         check_support; exit $? ;;
	uninstall)     uninstall ;;
	startup)       startup ;;
	sampler)       sampler ;;
	sample)        tmpd; sample_init; links_json > "$TMPD/links.json"; macs_json > "$TMPD/macs.json"; sample_json 0 0; echo ;;
	service_event) service_event "$2" "$3" ;;
	nodes)         nodes_cmd "$2" ;;
	nodekey)       nodekey "$2"; exit $? ;;
	fingerbank)    fingerbank_cmd "$2"; exit $? ;;
	dnsmasq_conf)  dnsmasq_conf "$2" ;;
	fblookup)      fb_on && tmpd && fb_tick wait ;;   # from dnsmasq's lease script, for a new fingerprint
	discnew)       disc_new ;;                        # from dnsmasq's lease script, for a device that just joined
	status)        status ;;
	debug)         debug ;;
	version)       say "$VERSION" ;;
	amtmupdate)    amtm_update "$2"; exit $? ;;
	*)             usage ;;
esac
