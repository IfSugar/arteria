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
#                    nodes [test] | nodekey [node-ip | print] | debug | sample | amtmupdate [check] |
#                    startup | version
#
#  Install:  d=/tmp/arteria-install; rm -rf "$d" && mkdir -m 700 "$d" && curl -fsL --retry 3 \
#              https://github.com/IfSugar/arteria/releases/latest/download/arteria.sh -o "$d/arteria.sh" && sh "$d/arteria.sh" install
###############################################################################

VERSION="2.2.0"
NAME="arteria"
# Files and folders only root can change. Scripts the router starts from service-event run with no umask, which made
# the page's data files and their folder writable by any program on the router.
umask 022
TITLE="Arteria"

# AR_ROOT, AR_PROC and AR_SYS let the script be tested off-router; they are empty on the router. AR_SSHD_WAIT (seconds)
# too: how long nodekey gives a node's SSH server to restart after adding the key (a stand-in node doesn't restart).
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
IDLE_STOP=120           # stop sampling this many seconds after the last heartbeat of an open page (120-300)
NODES=on                # on: read each AiMesh node's per-device counters over SSH; off: backhaul totals only
NODE_USER=""            # SSH user on the nodes; empty = the router's admin name
AMTM_UPDATE=on          # on: amtm may update Arteria (amtmupdate); off: only 'update' does
[ -f "$CONF" ] && . "$CONF"
case "$INTERVAL" in [1-9]|10) ;; *) INTERVAL=2 ;; esac
case "$IDLE_STOP" in ''|*[!0-9]*) IDLE_STOP=120 ;; esac
[ "$IDLE_STOP" -lt 120 ] && IDLE_STOP=120   # the page's heartbeat comes every 45 s: room for a late or lost one
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
# link, that belongs to root, and has one name only (a hard link to a root-only file elsewhere in /tmp, such as /tmp/etc's,
# would pass the other tests). Anyone on the router can create /tmp/arteria.asp or /tmp/menuTree.js first.
ours_file() { [ -f "$1" ] && [ ! -L "$1" ] && [ -O "$1" ] && [ "$(ls -ln "$1" 2>/dev/null | awk '{ print $2 }')" = 1 ]; }
# The menu copy addons share: root's own file, and a menu (it defines menuTree), before Arteria edits or mounts it.
ours_menu() { ours_file "$TMP_MENUTREE" && grep -q menuTree "$TMP_MENUTREE" 2>/dev/null; }

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
	tr '\000' ' ' 2>/dev/null < "/proc/$1/cmdline" | grep -q -- "$2"
}

web_dir() {
	d="$(readlink -f "$WWW_USER" 2>/dev/null)"
	[ -n "$d" ] || d="$WWW_USER"
	echo "$d/$NAME"
}
web_init() { mkdir -p "$(web_dir)" && chmod 755 "$(web_dir)"; }   # also tightens a folder an older version left open (in RAM: no flash write)

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

# Link aggregation (a NAS on LAN 1 and LAN 2): the bridge has the bond, while lan_ifnames and the port map name its members.
bonds() {   # lines "bond member member...", for each bond in a bridge
	for s in "$SYSNET"/*/bonding/slaves; do
		[ -r "$s" ] || continue
		b=${s%/bonding/slaves}; b=${b##*/}
		[ -d "$SYSNET/$b/brport" ] && printf '%s %s\n' "$b" "$(cat "$s" 2>/dev/null)"
	done
}
# Wired LAN ports: lan_ifnames without the Wi-Fi interfaces, in the router's order (LAN 1 first). A bond's members are one
# port, the bond, where its first member is: the bridge learns its devices' addresses on the bond, and counts them there.
lan_ports() {
	wifi=" $(radio_list | cut -d: -f1 | tr '\n' ' ') "; bm=$(bonds); out=" "
	for p in $(nvram get lan_ifnames); do
		case "$wifi" in *" $p "*) continue ;; esac
		b=$(printf '%s\n' "$bm" | awk -v p="$p" '{ for (i = 2; i <= NF; i++) if ($i == p) { print $1; exit } }')
		[ -n "$b" ] && p=$b
		case "$out" in *" $p "*) continue ;; esac
		out="$out$p "; printf '%s\n' "$p"
	done
}

# The Wi-Fi network each interface serves, by name, and whether it is a radio's own interface (its main network): the page
# names a device's network only when it isn't a main one (a guest network, or one of Guest Network Pro's on 3006). A network
# reached through wl0.1 and the like isn't necessarily a guest one: some setups put a main network there.
nets_json() {   # ["ifname","network name",1 for a radio's own interface] for every Wi-Fi interface the router serves
	c=0
	for u in 0 1 2 3; do
		f=$(nvram get wl${u}_ifname); [ -n "$f" ] || continue
		for x in $f $(nvram get wl${u}_vifs); do
			if [ "$x" = "$f" ]; then n=$(nvram get wl${u}_ssid); o=1; else n=$(nvram get "${x}_ssid"); o=0; fi
			[ $c -gt 0 ] && printf ','; c=1
			printf '["%s","%s",%s]' "$(js "$x")" "$(js "$n")" "$o"
		done
	done
}

# The firmware's own map of its ports ('rc port_status', on firmware that has it): each LAN port's number as printed on the
# router, its interface and its link. lan_ifnames lists the ports in the router's order on most models, but not on all:
# the RT-AX88U's LAN 1-4 are eth4-eth1, and its LAN 5-8 all sit behind eth5, a link to a second switch chip that is always up.
port_table() {   # lines "ifname number up Mb/s" for the LAN ports; nothing on firmware without the map
	have rc || return 0
	# the router's own ports come first (a USB port's devices on lines of their own, usb_path=, after it); what follows, its
	# AiMesh nodes' ports from a closed library, is left out: the parse stops at the end of the router's block, or at a port
	# label it has already seen. A bond's members are named as the bond (lan_ports).
	rc port_status 2>&1 | awk -v bm="$(bonds | awk '{ for (i = 2; i <= NF; i++) printf "%s=%s ", $i, $1 }')" '
		BEGIN { n = split(bm, a, " "); for (k = 1; k <= n; k++) { split(a[k], b, "="); B[b[1]] = b[2] } }
		go && !/phy_port_id=/ && !/^[ \t]*usb_path=/ { exit } /phy_port_id=/ { go = 1; l = ""; i = ""; s = ""; r = ""
		n = split($0, f, ","); for (k = 1; k <= n; k++) { e = f[k]; gsub(/^ +| +$/, "", e); p = index(e, "="); if (!p) continue
			key = substr(e, 1, p - 1); v = substr(e, p + 1)
			if (key == "label_name") l = v; else if (key == "ifname") i = v; else if (key == "state") s = v; else if (key == "link_rate") r = v }
		if (l ~ /^[A-Z][0-9]+$/) { if (l in seen) exit; seen[l] = 1 }
		if (l ~ /^L[0-9]+$/ && i ~ /^[A-Za-z0-9._-]+$/) print ((i in B) ? B[i] : i), substr(l, 2), (s == "up" ? 1 : 0), (r ~ /^[0-9]+$/ ? r : 0) }'
}
# {"ifname":"numbers"}: "1" for one port, "5-8" for an interface several ports share, "1+2" for a bond
port_labels_json() {
	printf '%s\n' "$PTAB" | awk -v want=" $PORTS " -v bonds=" $BONDS " 'NF == 4 && index(want, " " $1 " ") {
		if (!($1 in lo) || $2 + 0 < lo[$1]) lo[$1] = $2 + 0; if (!($1 in hi) || $2 + 0 > hi[$1]) hi[$1] = $2 + 0; all[$1] = all[$1] (all[$1] == "" ? "" : "+") $2 }
		END { for (i in lo) printf "%s\"%s\":\"%s\"", (c++ ? "," : ""), i, (index(bonds, " " i " ") ? all[i] : (lo[i] == hi[i] ? lo[i] : lo[i] "-" hi[i])) }'
}

wan_if() { w=$(nvram get wan0_gw_ifname); [ -n "$w" ] || w=$(nvram get wan0_ifname); printf '%s' "$w"; }
# Dual WAN (Load Balance or Failover): the second WAN's interface, when one is set up (wans_dualwan "wan usb", "wan lan"...).
wan2_if() {
	set -- $(nvram get wans_dualwan)
	[ -n "$2" ] && [ "$2" != none ] || return 0
	w=$(nvram get wan1_gw_ifname); [ -n "$w" ] || w=$(nvram get wan1_ifname)
	[ -n "$w" ] && [ "$w" != "$(wan_if)" ] && printf '%s' "$w"
}

# The router's own interface addresses. A node lists the router as a "station" on its backhaul
# radio; the page drops these so the router never shows up as one of its own clients.
own_macs() {
	cat "$SYSNET"/*/address 2>/dev/null | tr a-f A-F | grep -v '^00:00:00:00:00:00$' | sort -u
}

# AiMesh nodes, one per line: "MAC IP MODEL". From the router's own AiMesh list; never the router itself, and never an address
# outside the router's LAN (an old entry, such as a node's address from before it joined, 192.168.50.x by default: nothing
# answers there, so it only showed as a node that's down).
node_list() {
	me=$(nvram get lan_ipaddr); nm=$(nvram get lan_netmask)
	nvram get cfg_device_list | tr '<' '\n' | awk -F'>' -v me="$me" -v nm="${nm:-255.255.255.0}" '
		function net(a,   x, y, i, b, s) { split(a, x, "."); split(nm, y, "."); s = ""; for (i = 1; i <= 4; i++) { b = 256 - y[i]; s = s "." (x[i] - x[i] % b) } return s }
		NF >= 3 && $2 != me && $2 ~ /^[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+$/ && (me == "" || net($2) == net(me)) && $3 ~ /^[0-9A-Fa-f:]+$/ {
			m = $1; gsub(/[^ -~]/, "", m); print toupper($3), $2, m }'   # the model as printable text only: it reaches the terminal
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

# The keys Arteria offers a node, in order: its own, then the one root on this router already logs in to nodes with,
# Dropbear's default ~/.ssh/id_dropbear (the forum's passwordless guide and the Wireless Report addon keep it in
# /jffs/.ssh and copy it there at boot). dbclient tries each in turn, so a router set up for passwordless logins to its
# nodes needs nothing more for Arteria. Only regular, non-empty files that belong to root; each file once.
node_keys() {
	{ [ -s "$KEY" ] && printf '%s\n' "$KEY"
	  for k in "$ROOT/tmp/home/root/.ssh/id_dropbear" "$ROOT/jffs/.ssh/id_dropbear" "$ROOT/jffs/.ssh/id_dropbear_rsa"; do
		ours_file "$k" && [ -s "$k" ] && printf '%s\n' "$k"
	  done; } | awk '!seen[$0]++'
}
key_args() { for k in ${TRY_KEYS:-$(node_keys)}; do printf '%s %s ' -i "$k"; done; }   # -> "-i key -i key ..."
key_name() { case "$1" in "$KEY") printf "Arteria's key" ;; *) printf '%s' "${1#$ROOT}" ;; esac; }
# Root's own logins to the nodes pin each node's SSH identity in root's known_hosts. A node pinned there but not yet
# here is pinned here the same way: root on this router already trusted it. Nothing is ever pinned that root hadn't.
import_pin() {   # ip -> 0 if a pin was copied   (its own variable names: callers' f, h and l are theirs)
	pin_kh="$SSH_HOME/.ssh/known_hosts"; pin_h=$(printf '%s' "$1" | sed 's/\./\\./g')
	grep -Eq "^(\[$pin_h\]:[0-9]+|$pin_h)[ ,]" "$pin_kh" 2>/dev/null && return 1
	for pin_f in "$ROOT/tmp/home/root/.ssh/known_hosts" "$ROOT/jffs/.ssh/known_hosts"; do
		ours_file "$pin_f" || continue
		pin_l=$(grep -E "^(\[$pin_h\]:[0-9]+|$pin_h)[ ,]" "$pin_f" 2>/dev/null | head -4)
		[ -n "$pin_l" ] || continue
		ssh_home_init; printf '%s\n' "$pin_l" >> "$pin_kh"
		log "trusted node $1's SSH identity as root's own known_hosts does"
		return 0
	done
	return 1
}
unpin() {   # ip: forget the identity pinned for it   (its own variable name, like import_pin's)
	pin_u=$(printf '%s' "$1" | sed 's/\./\\./g')
	[ -f "$SSH_HOME/.ssh/known_hosts" ] && sed -i "/^$pin_u /d; /^\[$pin_u\]:/d" "$SSH_HOME/.ssh/known_hosts"
}

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
# The script the page runs on each node, sent as the SSH command itself: the node's login shell runs it, as it would run it
# typed in a terminal there. (Sent to "sh -s" instead, it crashed on some stock-firmware nodes, whose sh also refuses -x.)
# It reads the node's own Wi-Fi interfaces, never its uplink: on a node with a Wi-Fi backhaul, the radio's own interface is a
# client of the router (a client mode, or named in sta_phy_ifnames/sta_ifnames), and the node's devices are on wl0.1-style
# interfaces. A node on an Ethernet backhaul still names its radios in those lists, but they are access points with the node's
# devices on them (an RT-AC86U, a ZenWiFi XD6): so a named interface counts as the uplink only while it isn't an access point.
# A node that joins its radios' uplinks into one interface, dpsta (sta_phy_ifnames=dpsta, sta_ifnames=its radios: an RP-AX56),
# counts each packet on dpsta and on the radio it came in on: its uplink is dpsta alone, or the backhaul reads double.
# Each round also reports the uplink's own byte counters ("U ifname rx tx"), read in the same round as its devices': the page
# shows the node's part of Flow from those, so the node's backhaul and its devices always add up, even while a download that
# just started is reaching the router's figures a round before the node's. A wired uplink is found among its wired ports
# (below), and named with "X ifname": its counters are the node's own count of its backhaul, which matters when several nodes
# are behind one of the router's ports (a switch, or a node wired behind another), as that port counts them all together.
# With "trace" it runs one round and says on stderr what it runs before each command ("+ wl -i ... assoclist"), so a command
# that crashes on the node is named (nodes test, doctor), without needing the node's sh to support -x.
# Each round also names the network on each interface it reads ("N wl0.1 0 name": 1 for a radio's own interface), so the page
# can name a guest network on the node as it does on the router, and reads the node's wired ports as the router reads its own:
# each LAN port's link and counters ("L eth3 1 1000", "C eth3 rx tx") and the addresses its bridges learned on it
# ("M eth3 MAC"). The port its bridge learned one of the router's own addresses on (R) leads to the router (a wired backhaul):
# that one is left out, with everything else on the network behind it.
# With "why" it reads no counters: it prints each interface it reads and each one it skips as the uplink (and why), with how
# many devices each has ("W read wl0.1 - 3", "W skip eth6 psr 1"), for a node that reads 0 devices (node_why).
NODE_MARK="# arteria node script"
NODE_PROC="${AR_NODE_PROC:-/proc}"   # AR_NODE_PROC: test hook only (a stand-in node's /proc)
NODE_SYS="${AR_NODE_SYS:-/sys}"      # AR_NODE_SYS: test hook only (a stand-in node's /sys)
write_node_script() {   # [rounds] [trace|why]   rounds default: 30 minutes' worth (the page's session); 'nodes test' runs one
	printf '%s\nI=%s\nN=%s\nT=%s\nW=%s\nP=%s\n' "$NODE_MARK" "$INTERVAL" "${1:-$((1800 / INTERVAL))}" "$( [ "$2" = trace ] && echo 1)" "$( [ "$2" = why ] && echo 1)" "$NODE_PROC"
	printf 'Q=%s\nR=" %s"\n' "$NODE_SYS" "$(own_macs | tr '\n' ' ')"   # R: the router's own addresses, MACs only
	printf "A='%s'\n" "$STA_AWK"
	cat <<'EOF'
if [ -n "$T" ]; then t() { echo "+ $*" >&2; }; else t() { :; }; fi   # decided once: no "[" run for each command
[ -z "$T" ] || { t busybox; v=$(busybox 2>&1 | head -n 1); t "shell: $0, /bin/sh is $(readlink /bin/sh 2>/dev/null), ${v%% multi-call*}"; }
t nvram get sta_phy_ifnames sta_ifnames
S=" $(nvram get sta_phy_ifnames) $(nvram get sta_ifnames) "
L=""
K=""
Z=" "
Y=" "
G=""
for u in 0 1 2 3; do
	t nvram get wl${u}_ifname
	f=$(nvram get wl${u}_ifname); [ -n "$f" ] || continue
	t nvram get wl${u}_nband wl${u}_mode wl${u}_vifs
	b=$(nvram get wl${u}_nband)
	case "$b" in 2) b=2.4 ;; 1) b=5 ;; 4) b=6 ;; *) b=0 ;; esac
	m=$(nvram get wl${u}_mode)
	v=$(nvram get wl${u}_vifs)
	Y="$Y$f $v "
	case "$m" in sta|wet|psta|psr) Z="$Z$f "; K="$K $f:$m"; f="" ;; esac
	for x in $f $v; do
		case "$S" in *" $x "*)
			t wl -i $x ap
			case "$(wl -i "$x" ap 2>/dev/null)" in *1*) ;; *) K="$K $x:listed"; continue ;; esac ;;
		esac
		L="$L $x:$b"
		if [ "$x" = "$f" ]; then c=1; k=wl${u}_ssid; else c=0; k=${x}_ssid; fi
		t nvram get $k
		G="$G
N $x $c $(nvram get "$k")"
	done
done
# the uplink: the named interfaces that aren't read (access points), and the radios in a client mode
U=" "
for x in $S; do case " $L " in *" $x:"*) ;; *) U="$U$x " ;; esac; done
U="$U${Z# }"
case "$U" in *" dpsta "*)
	t nvram get dpsta_ifnames
	M=" $(nvram get dpsta_ifnames) "
	[ "$M" != "  " ] || M="$U"   # its members not named: dpsta stands for every uplink
	V=" dpsta "
	for x in $U; do case "$M" in *" $x "*) ;; *) [ "$x" = dpsta ] || V="$V$x " ;; esac; done
	U="$V" ;;
esac
t "reads:$L, uplink:$U"
# its wired ports: the ports in its bridges (its LAN ports, and its WAN port, which a node bridges too) that aren't a Wi-Fi
# interface or its Wi-Fi uplink, when it has brctl to say who is on each. A port can be in a bridge as itself or by a VLAN on it.
E=" "
t nvram get lan_ifnames wan_ifnames
for p in $(nvram get lan_ifnames) $(nvram get wan_ifnames); do
	case "$Y$U$E" in *" $p "*) continue ;; esac
	[ -d "$Q/class/net/$p/bonding_slave" ] && continue   # a bond's port: the bond is read (below)
	for d in "$Q/class/net/$p/brport" "$Q/class/net/$p".*/brport; do [ -d "$d" ] && { E="$E$p "; break; }; done
done
# and an Ethernet port that is only in another bridge: a LAN port given to a VLAN (Guest Network Pro's LAN: VLAN) leaves
# lan_ifnames and is in that VLAN's bridge alone (br53), untagged. A bridge port's name, less a VLAN on it, is the port.
# A bond (a NAS on two of the node's ports) is in the bridge in its ports' place: it is one port, as on the router.
for d in "$Q"/class/net/*/brport; do
	p=${d%/brport}; p=${p##*/}; p=${p%.[0-9]*}
	case "$p" in eth[0-9]*|vlan[0-9]*|bond[0-9]*) ;; *) continue ;; esac
	case "$Y$U$E" in *" $p "*) continue ;; esac
	[ -d "$Q/class/net/$p/bonding_slave" ] && continue
	[ -d "$Q/class/net/$p" ] && E="$E$p "
done
if [ "$E" != " " ]; then t brctl show; brctl show > /dev/null 2>&1 || E=" "; fi
if [ -n "$W" ]; then
	for p in $L; do echo "W read ${p%%:*} - $(wl -i "${p%%:*}" assoclist 2>/dev/null | wc -l)"; done
	for p in $K; do echo "W skip ${p%%:*} ${p#*:} $(wl -i "${p%%:*}" assoclist 2>/dev/null | wc -l)"; done
	exit 0
fi
r() {
	for p in $L; do
		x=${p%%:*}; b=${p#*:}
		t wl -i $x assoclist
		a=$(wl -i "$x" assoclist 2>/dev/null)
		t cut -d' ' -f2
		for m in $(echo "$a" | cut -d' ' -f2); do
			echo "@ $x $b $m"
			t wl -i $x sta_info
			wl -i "$x" sta_info "$m" 2>/dev/null
		done
	done
}
q() {   # each wired port's link ("L port carrier Mb/s"), then each address a bridge learned on one ("port MAC")
	for p in $E; do echo "L $p $(cat "$Q/class/net/$p/carrier" 2>/dev/null || echo 0) $(cat "$Q/class/net/$p/speed" 2>/dev/null || echo 0)"; done
	for d in "$Q"/class/net/*/bridge; do
		[ -d "$d" ] || continue
		d=${d%/bridge}; d=${d##*/}
		t brctl showstp $d
		k=$(brctl showstp "$d" 2>/dev/null | sed -n 's/^\([A-Za-z0-9.]*\) (\([0-9]*\))$/\2 \1/p' | tr '\n' ';')
		t brctl showmacs $d
		brctl showmacs "$d" 2>/dev/null | awk -v k="$k" 'BEGIN { n = split(k, a, ";"); for (i = 1; i <= n; i++) { split(a[i], b, " "); P[b[1]] = b[2] } }
			NR > 1 && $3 == "no" && $2 ~ /^[0-9A-Fa-f:]+$/ { p = P[$1]; sub(/\.[0-9]+$/, "", p); if (p != "") print p, toupper($2) }'
	done
}
n=0
while [ $n -lt $N ]; do
	t cut -d' ' -f1 /proc/uptime
	echo "#B $(cut -d' ' -f1 /proc/uptime)"
	t awk $P/net/dev
	awk -v w="$U" -v e="$E" 'NR > 2 { sub(/^[ \t]+/, ""); i = index($0, ":"); if (!i) next; n = substr($0, 1, i - 1); split(substr($0, i + 1), f, " ")
		if (index(w, " " n " ")) print "U", n, f[1], f[9]; else if (index(e, " " n " ")) print "C", n, f[1], f[9] }' $P/net/dev
	[ -z "$G" ] || printf '%s\n' "${G#?}"
	# the wired ports, each address once and at most 64 a port; none for a port with one of the router's addresses on it, which
	# is named instead ("X port"): it is the node's wired uplink, and its counters (C) are the node's own count of its backhaul
	[ "$E" = " " ] || q | awk -v e="$E" -v r="$R" '$1 == "L" { if (index(e, " " $2 " ")) { l[++nl] = $2 " " ($3 == 1 ? 1 : 0) " " ($4 ~ /^[0-9]+$/ ? $4 : 0) } next }
		index(e, " " $1 " ") { if (index(r, " " $2 " ")) x[$1] = 1; else if (!($2 in s) && c[$1] < 64) { s[$2] = 1; c[$1]++; m[++nm] = $1 " " $2 } }
		END { for (i = 1; i <= nl; i++) { split(l[i], a, " "); if (!(a[1] in x)) print "L", l[i] }
			for (i = 1; i <= nm; i++) { split(m[i], a, " "); if (!(a[1] in x)) print "M", m[i] }
			for (p in x) print "X", p }'
	if [ -n "$T" ]; then o=$(r); t awk; printf '%s\n' "$o" | awk "$A"; else r | awk "$A"; fi   # traced: the reading, then the awk
	echo "#E"
	n=$((n + 1)); [ $n -lt $N ] && sleep $I
done
EOF
}

# ---- AiMesh node sessions ----------------------------------------------------------
# While the page is open the router keeps one SSH session to each node. Key login only: the sampler
# has no terminal, so dbclient can never ask for (or send) a password. Host keys are pinned in $SSH_HOME
# by nodekey, or copied from root's own known_hosts (import_pin), never with -y here: a node neither has
# pinned isn't trusted until you say so in nodekey.
node_start() {   # mac ip
	f=$(node_file "$1")
	: > "$f.out"; : > "$f.err"; now > "$f.start"; rm -f "$f.fail" "$f.last"
	# ulimit -f: a session that writes more than about 1 MB between two trims is ended (nodes_tick trims at 128 KB),
	# so a node that floods its output can't fill the router's RAM; it is reconnected like any dropped session.
	import_pin "$2"
	(ulimit -f 2048 2>/dev/null; HOME="$SSH_HOME" exec dbclient $BATCH -K 10 -I 30 -p "$PORT" $KEYARGS "$SSHUSER@$2" "$(cat "$TMPD/node.sh")") \
		< /dev/null >> "$f.out" 2>> "$f.err" 8>&- &
	echo $! > "$f.pid"
}
node_stop_all() {
	for p in "$TMPD"/node.*.pid; do
		[ -f "$p" ] || continue
		q=$(cat "$p" 2>/dev/null); pid_ours "$q" dbclient && kill "$q" 2>/dev/null; rm -f "$p"
	done
}
node_running() { pid_ours "$(cat "$1.pid" 2>/dev/null)" dbclient; }

# How long a node takes for one round (its clients' counters, then the pause), from the uptimes its last two blocks
# start with: a slow node (many clients, a slow driver) still counts as answering while it keeps that pace.
node_period() {   # file-base -> seconds (at least INTERVAL)
	cat "$1.last" "$1.out" 2>/dev/null | awk -v i="$INTERVAL" '/^#B [0-9.]+$/ { a = b; b = $2 + 0 } END { p = (a != "" && b > a) ? int(b - a + 0.999) : i; if (p > 64) p = 64; print (p > i ? p : i) }'
}
# ok: fresh counters; wait: connecting; nokey: the node refused the key ('nodekey' fixes it);
# hostkey: the node's identity changed ('nodekey' re-pins it); down: unreachable; off: node access is off;
# busy: no session yet because the router is busy (see the guard); crash: a command on the node crashed.
node_state() {   # file-base -> state
	if [ "$NODES" != on ]; then echo off; return; fi
	if [ -z "${KEYARGS-$(key_args)}" ] || ! have dbclient; then echo nokey; return; fi
	f=$1
	if grep -q '^#E' "$f.out" 2>/dev/null || grep -q '^#E' "$f.last" 2>/dev/null; then
		age=$(( $(now) - $(date -r "$f.out" +%s 2>/dev/null || echo 0) ))
		win=$(( $(node_period "$f") * 2 + 4 )); [ $win -lt $((INTERVAL * 3 + 4)) ] && win=$((INTERVAL * 3 + 4)); [ $win -gt 64 ] && win=64
		[ "$age" -le "$win" ] && { echo ok; return; }
	fi
	if node_running "$f"; then
		st=$(cat "$f.start" 2>/dev/null || echo 0)
		[ $(( $(now) - st )) -lt 15 ] && { echo wait; return; }
		echo down; return
	fi
	[ -n "$NODE_NOSTART" ] && [ ! -f "$f.start" ] && { echo busy; return; }   # not tried yet: the router is busy
	e=$(tail -c 2048 "$f.err" 2>/dev/null | tr -d '\000')
	case "$e" in
		*trusted\ hosts*) echo nokey ;;   # never trusted yet: nodekey asks
		*[Hh]ost\ key*|*[Mm]ismatch*|*[Ii]dentification*) echo hostkey ;;
		*[Pp]ermission\ denied*|*[Aa]uth*|*[Pp]assword*|*publickey*) echo nokey ;;
		*Segmentation\ fault*) echo crash ;;   # a command on the node crashed running Arteria's script ('nodes test' saves what it ran)
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
		[ -n "$NODE_NOSTART" ] && continue   # the router is busy: no new sessions (the running ones carry on)
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
		[ "$(wc -c 2>/dev/null < "${o%.out}.err" || echo 0)" -gt 65536 ] && : > "${o%.out}.err"
	done
	return 0
}

# The last complete block a node sent, as JSON: "up":"<node uptime>","c":[rows],"u":[its uplink's counters],
# "w":[its wired ports: ifname, carrier, Mb/s, rx, tx],"m":[[port, MAC] learned on them],"n":[[ifname, network name, main]].
# Only rows between a "#B" and its "#E" count: the file can be emptied in the middle of a block. At most 512 rows a
# block (a node serves far fewer clients), 8 ports, 128 addresses and 16 networks: a hostile node can't make every sample
# cost seconds of CPU. A network name is any text up to 64 bytes, escaped for JSON (and a "<" later, by write_atomic).
# je escapes it one character at a time: what a backslash means in gsub's replacement differs between awks (BusyBox 1.38
# drops the one in "\\\"", so a network name with a quote broke the JSON).
NODE_AWK="$ROWS_AWK"'
function je(s,   o, c, i, len) { gsub(/[[:cntrl:]]/, "", s); len = length(s); for (i = 1; i <= len; i++) { c = substr(s, i, 1); if (c == "\\" || c == "\"") o = o "\\"; o = o c } return o }
function nm(s) { return s ~ /^[A-Za-z0-9._-]+$/ && length(s) <= 16 }
/^#B / { cur = ""; cc = 0; cu = ""; uc = 0; cw = ""; wc = 0; cl = ""; lc = 0; cm = ""; mc = 0; cn = ""; nc = 0; cx = ""; xc = 0; cup = ($2 ~ /^[0-9.]+$/) ? $2 : ""; open = 1; next }
open && xc < 4 && /^X / && NF == 2 && nm($2) { cx = cx $2 ";"; xc++; next }
open && cc < 512 && /^S / && $2 ~ /^[A-Za-z0-9.]+$/ && $3 ~ /^[0-9.]+$/ && $4 ~ /^[0-9A-Fa-f:]+$/ { cur = cur (cc++ ? "," : "") row(); next }
open && uc < 8 && /^U / && NF == 4 && nm($2) && $3 ~ /^[0-9]+$/ && $4 ~ /^[0-9]+$/ && length($3) <= 20 && length($4) <= 20 { cu = cu (uc++ ? "," : "") "[\"" $2 "\",\"" $3 "\",\"" $4 "\"]"; next }
open && wc < 8 && /^C / && NF == 4 && nm($2) && $3 ~ /^[0-9]+$/ && $4 ~ /^[0-9]+$/ && length($3) <= 20 && length($4) <= 20 { cw = cw $2 " " $3 " " $4 ";"; wc++; next }
open && lc < 8 && /^L / && NF == 4 && nm($2) && $3 ~ /^[01]$/ && $4 ~ /^[0-9]+$/ && length($4) <= 6 { cl = cl $2 " " $3 " " ($4 + 0) ";"; lc++; next }
open && mc < 128 && /^M / && NF == 3 && nm($2) && $3 ~ /^[0-9A-F:]+$/ && length($3) == 17 { cm = cm (mc++ ? "," : "") "[\"" $2 "\",\"" $3 "\"]"; next }
open && nc < 16 && /^N / && nm($2) && $3 ~ /^[01]$/ { s = $0; sub(/^N [^ ]+ [01] ?/, "", s); if (length(s) <= 64) cn = cn (nc++ ? "," : "") "[\"" $2 "\",\"" je(s) "\"," $3 "]"; next }
/^#E/ { if (open) { last = cur; lu = cu; lw = cw; ll = cl; lm = cm; ln = cn; lx = cx; lup = cup; done = 1 } open = 0; next }
END {
	if (!done) { printf "\"up\":null,\"c\":[],\"u\":[],\"w\":[],\"m\":[],\"n\":[]"; exit }
	j = split(lw, a, ";"); for (i = 1; i <= j; i++) if (split(a[i], b, " ") == 3) K[b[1]] = b[2] "\",\"" b[3]   # (k is a function: ROWS_AWK)
	w = ""; j = split(ll, a, ";"); for (i = 1; i <= j; i++) if (split(a[i], b, " ") == 3 && (b[1] in K)) w = w (w == "" ? "" : ",") "[\"" b[1] "\"," b[2] "," b[3] ",\"" K[b[1]] "\"]"
	# a wired uplink (X): its counters join the uplink rows, like those of a Wi-Fi uplink
	j = split(lx, a, ";"); for (i = 1; i <= j; i++) if (a[i] in K) lu = lu (lu == "" ? "" : ",") "[\"" a[i] "\",\"" K[a[i]] "\"]"
	printf "\"up\":\"%s\",\"c\":[%s],\"u\":[%s],\"w\":[%s],\"m\":[%s],\"n\":[%s]", lup, last, lu, w, lm, ln }'

nodes_json() {
	c=0
	printf '%s\n' "$NODE_LIST" | while read -r mac ip model; do
		[ -n "$mac" ] || continue
		f=$(node_file "$mac")
		[ $c -gt 0 ] && printf ','; c=1
		printf '{"mac":"%s","ip":"%s","model":"%s","alias":"%s","sta":"%s","state":"%s",' \
			"$mac" "$ip" "$(js "$model")" "$(js "$(node_alias "$mac")")" "$(node_stas "$mac")" "$(node_state "$f")"
		if [ -s "$f.out" ] || [ -s "$f.last" ]; then cat "$f.last" "$f.out" 2>/dev/null | awk "$NODE_AWK"; else printf '"up":null,"c":[],"u":[],"w":[],"m":[],"n":[]'; fi
		printf '}'
	done
}

# ---- one sample ---------------------------------------------------------------------
links_json() {   # [port, carrier, Mb/s] for the WAN and every wired port; [port, up, Mb/s, "numbers up"] for one ports share
	[ -n "$SHARED" ] && PTAB=$(port_table)
	c=0; printf '['
	for p in $WAN_IF $WAN2_IF $PORTS; do
		[ $c -gt 0 ] && printf ','; c=1
		case " $SHARED " in
			*" $p "*) printf '%s\n' "$PTAB" | awk -v p="$p" '$1 == p && $3 == 1 { u = u (u == "" ? "" : ",") $2; if ($4 + 0 > s) s = $4 + 0 }
				END { printf "[\"%s\",%d,%d,\"%s\"]", p, (u != ""), (u != "" ? s : -1), u }' ;;
			*) printf '["%s",%s,%s]' "$p" "$(jnum "$(cat "$SYSNET/$p/carrier" 2>/dev/null)")" "$(jnum "$(cat "$SYSNET/$p/speed" 2>/dev/null)")" ;;
		esac
	done
	printf ']'
}
# The LAN bridges: br0, and the ones Guest Network Pro adds (br52, br53...), which reach a wired port through a VLAN
# interface on it (eth3.52 is LAN port eth3).
bridges() {
	b=$(for d in "$SYSNET"/*/bridge; do [ -d "$d" ] && basename "$(dirname "$d")"; done)
	printf '%s\n' "${b:-br0}"
}
macs_json() {    # [port, MAC] for every address a LAN bridge has learned on a wired port
	printf '['
	for br in $(bridges); do
		map=$(brctl showstp "$br" 2>/dev/null | sed -n 's/^\([A-Za-z0-9.]*\) (\([0-9]*\))$/\2 \1/p' | tr '\n' ';')
		brctl showmacs "$br" 2>/dev/null | awk -v map="$map" '
			BEGIN { n = split(map, a, ";"); for (i = 1; i <= n; i++) { split(a[i], b, " "); P[b[1]] = b[2] } }
			NR > 1 && $3 == "no" && $2 ~ /^[0-9A-Fa-f:]+$/ { p = P[$1]; sub(/\.[0-9]+$/, "", p); if (p != "") print p, toupper($2) }'
	done | awk -v want=" $PORTS " 'index(want, " " $1 " ") && !seen[$2]++ && N[$1]++ < 64 { printf "%s[\"%s\",\"%s\"]", (c++ ? "," : ""), $1, $2 }'
	printf ']'
}
ifs_json() {     # [ifname, rx bytes, tx bytes] for the WAN, the wired ports and the AiMesh WDS links
	awk -v want=" $WAN_IF $WAN2_IF $PORTS " 'NR > 2 {
		sub(/^[ \t]+/, ""); i = index($0, ":"); if (!i) next
		n = substr($0, 1, i - 1); split(substr($0, i + 1), f, " ")
		if (index(want, " " n " ") || n ~ /^wds/) printf "%s[\"%s\",\"%s\",\"%s\"]", (c++ ? "," : ""), n, f[1], f[9] }' "$PROC/net/dev"
}

sample_init() {
	RADIOS=$(radio_list | tr '\n' ' ')
	PORTS=$(lan_ports | tr '\n' ' ')
	WAN_IF=$(wan_if); WAN2_IF=$(wan2_if)
	MODEL=$(nvram get productid)
	FW=$(fw_version)
	OWN=$(own_macs | awk '{ printf "%s\"%s\"", (c++ ? "," : ""), $1 }')
	PORT=$(ssh_port); SSHUSER=$(ssh_user); BATCH=$(ssh_batch); KEYARGS=$(key_args)
	ssh_home_init
	NODE_LIST=""
	[ "$NODES" = on ] && NODE_LIST=$(node_list)
	PORTS_JSON=$(printf '%s' "$PORTS" | awk '{ for (i = 1; i <= NF; i++) printf "%s\"%s\"", (i > 1 ? "," : ""), $i }')
	NETS_JSON=$(nets_json)
	BONDS=$(bonds | cut -d' ' -f1 | tr '\n' ' ')
	PTAB=$(port_table); PLAB_JSON=$(port_labels_json)
	# interfaces several ports share (the RT-AX88U's eth5): their own link says nothing about the ports, so those come from the
	# map. Not a bond: its own link is up while one of its members is, at their speeds together.
	# And an interface for one port whose own link disagrees with the map's: the GT-BE98 Pro's LAN 1 is vlan4094, a VLAN
	# interface whose own link is up at 10 Gb/s, like the internal link it is on, whatever is plugged into the port.
	SHARED=$(printf '%s\n' "$PTAB" | awk -v want=" $PORTS " -v bonds=" $BONDS " -v sys="$SYSNET" 'NF == 4 && index(want, " " $1 " ") && !index(bonds, " " $1 " ") { n[$1]++; u[$1] = $3; r[$1] = $4 }
		END { for (i in n) {
			if (n[i] > 1) { printf "%s ", i; continue }
			c = 0; s = 0; f = sys "/" i "/carrier"; if ((getline c < f) <= 0) c = 0; close(f); f = sys "/" i "/speed"; if ((getline s < f) <= 0) s = 0; close(f)
			if ((c + 0 == 1) != (u[i] + 0 == 1) || (u[i] + 0 == 1 && r[i] + 0 > 0 && s + 0 != r[i] + 0)) printf "%s ", i } }')
}

sample_json() {   # seq ms -> one sample as JSON on stdout
	printf '{"v":1,"seq":%s,"up":"%s","epoch":%s,"ms":%s,' "$1" "$(cut -d' ' -f1 "$PROC/uptime")" "$(now)" "$2"
	printf '"router":{"model":"%s","fw":"%s","load":"%s","cpus":%s,"mem":%s,"busy":%s},' "$(js "$MODEL")" "$(js "$FW")" "$(cut -d' ' -f1 "$PROC/loadavg")" "${CPUS:-2}" "$(jnum "${MEMMB:--}")" "${HEALTH:-0}"
	printf '"interval":%s,"nodes_mode":"%s","wan":"%s","wan2":"%s","ports":[%s],"plab":{%s},"nets":[%s],"own":[%s],' "${EFF:-$INTERVAL}" "$NODES" "$WAN_IF" "$WAN2_IF" "$PORTS_JSON" "$PLAB_JSON" "$NETS_JSON" "$OWN"
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
		tr '\n' '|' 2>/dev/null < "$ROOT/var/lib/misc/dnsmasq.leases" | tr -d '\000-\037' | sed 's/\\/\\\\/g; s/"/\\"/g'
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
		printf '"}'
	} | write_atomic "$(web_dir)/names.htm"
}

uptime_cs() { awk '{ printf "%d", ($1 % 1000000) * 100 }' "$PROC/uptime"; }   # centiseconds (mod 11.5 days: 32-bit safe), for timing a sample

# ---- keeping the router safe ------------------------------------------------------------
# Arteria must never be what makes a router struggle. Before and while it samples it looks at the load (the 1-minute
# average, per core) and the memory still available. When the router is busy it samples less often and starts no new
# node sessions; when it is overloaded three rounds in a row (or already is when the page opens) it stops, says why on
# the page and in the system log, and doesn't start again for 2 minutes.
PAUSED="$TMPD/paused"
cpu_count() { n=$(grep -c '^processor' "$PROC/cpuinfo" 2>/dev/null); case "$n" in ''|0|*[!0-9]*) n=2 ;; esac; echo "$n"; }
mem_avail_kb() {   # MemAvailable, or on old kernels free + buffers + cache; nothing if unknown
	awk '/^MemAvailable:/ { a = $2 } /^(MemFree|Buffers|Cached):/ { f += $2 } END { if (a != "") print a; else if (f) print f }' "$PROC/meminfo" 2>/dev/null
}
# HEALTH: 0 fine, 1 busy (load at least 2 per core, or under 48 MB free), 2 overloaded (4 per core, or under 24 MB);
# HWHY: load or memory; LOAD, MEMMB: the figures, for the page and the log.
health() {
	set -- $(awk -v c="${CPUS:-2}" -v m="$(mem_avail_kb)" 'NR == 1 { l = $1 + 0
		lv = (l >= 4 * c) ? 2 : (l >= 2 * c) ? 1 : 0
		mv = (m == "") ? 0 : (m < 24576) ? 2 : (m < 49152) ? 1 : 0
		printf "%d %s %s %s", (lv > mv ? lv : mv), $1, (m == "" ? "-" : int(m / 1024)), (mv > lv ? "memory" : "load") }' "$PROC/loadavg" 2>/dev/null)
	HEALTH=${1:-0}; LOAD=${2:-?}; MEMMB=${3:--}; HWHY=${4:-load}
}
health_text() {   # why -> a sentence for the log and the terminal
	case "$1" in
		memory) printf 'the router is low on memory (%s MB available)' "$MEMMB" ;;
		slow) printf 'each sample took over 15 s' ;;
		*) printf 'the router is busy (load %s on %s cores)' "$LOAD" "${CPUS:-2}" ;;
	esac
}
pause_sampling() {   # why: load | memory | slow
	printf '%s %s %s %s %s\n' "$(now)" "$1" "$LOAD" "${CPUS:-2}" "$MEMMB" > "$PAUSED"
	log "paused for 2 minutes: $(health_text "$1")"
	node_stop_all
	printf '{"v":1,"paused":"%s","epoch":%s,"load":"%s","cpus":%s,"mem":%s}' "$1" "$(now)" "$(js "$LOAD")" "${CPUS:-2}" "$(jnum "$MEMMB")" \
		| write_atomic "$(web_dir)/live.htm"
}
paused_recently() { p=$(date -r "$PAUSED" +%s 2>/dev/null) || return 1; [ $(( $(now) - p )) -lt 120 ]; }

# ---- the sampler: runs only while the page is open ----------------------------------------
# The page asks for "start_arteria" every 45 s (service-event; the router logs two lines for each, so not more
# often). Each request refreshes a heartbeat file; the sampler stops IDLE_STOP seconds after the last one, and
# at once if the page says it closed or paused (start_arteriastop). Nothing runs on a schedule.
hb_fresh() {
	hb=$(date -r "$TMPD/heartbeat" +%s 2>/dev/null) || return 1
	[ $(( $(now) - hb )) -le "$IDLE_STOP" ]
}
sampler_running() { pid_ours "$(cat "$TMPD/sampler.pid" 2>/dev/null)" "$NAME.sh sampler"; }

sampler() {
	tmpd; web_init
	exec 8>"$TMPD/sampler.lock"
	flock -n 8 || { echo "another sampler holds $TMPD/sampler.lock" >&2; exit 0; }
	lowprio
	trap 'node_stop_all; rm -f "$TMPD/sampler.pid"; exit 0' INT TERM
	# the page closed (start_arteriastop): its signal cuts the pause before the next sample short, which can be 10 s. Only the
	# heartbeat decides whether to go on: a page opened again at once (a reload) has put it back. The traps come before the pid.
	SAMPLER_STOP=""; trap 'SAMPLER_STOP=1' USR1
	echo $$ > "$TMPD/sampler.pid"
	sample_init
	CPUS=$(cpu_count); health
	if [ "$HEALTH" -ge 2 ]; then pause_sampling "$HWHY"; rm -f "$TMPD/sampler.pid"; exit 0; fi
	rm -f "$PAUSED"
	write_node_script > "$TMPD/node.sh"
	rm -f "$TMPD"/node.*.fail "$TMPD"/node.*.start "$TMPD"/node.*.last "$TMPD"/node.*.k "$TMPD"/node.*.out "$TMPD"/node.*.err
	WD=$(web_dir); seq=0; ms=0; over=0; slow=0; paused=0; EFF=$INTERVAL
	log "sampling started (page open)"
	while SAMPLER_STOP=""; hb_fresh; do
		t0=$(uptime_cs)
		health
		if [ "$HEALTH" -ge 2 ]; then over=$((over + 1)); else over=0; fi
		[ $over -ge 3 ] && { pause_sampling "$HWHY"; paused=1; break; }
		# Work done only every few rounds (the ports, the names, the lists of nodes and radios) and starting the node
		# sessions doesn't count toward the pace below: a round that does it would otherwise slow the next ones.
		if [ $((seq % 5)) -eq 0 ]; then
			links_json > "$TMPD/links.json"; macs_json > "$TMPD/macs.json"
		fi
		[ $((seq % 15)) -eq 14 ] && export_names
		[ $((seq % 30)) -eq 29 ] && { sample_init; [ "$(wc -c 2>/dev/null < "$TMPD/sampler.err" || echo 0)" -gt 32768 ] && : > "$TMPD/sampler.err"; }   # nodes and radios can change while the page is open
		NODE_NOSTART=""; [ "$HEALTH" -ge 1 ] && NODE_NOSTART=1
		[ "$NODES" = on ] && [ $seq -eq 0 ] && nodes_tick
		t1=$(uptime_cs)
		[ "$NODES" = on ] && [ $seq -gt 0 ] && nodes_tick
		sample_json "$seq" "$ms" | write_atomic "$WD/live.htm"
		t2=$(uptime_cs)
		ms=$(( (t2 - t0) * 10 )); [ "$ms" -lt 0 ] && ms=0   # the counter wrapped during this sample
		if [ "$ms" -gt 15000 ]; then slow=$((slow + 1)); else slow=0; fi
		[ $slow -ge 2 ] && { pause_sampling slow; paused=1; break; }
		# Sampling takes at most about a third of the time: a router that needs longer for a sample is sampled less
		# often (up to every 10 s), and a busy one at a third of the rate. The page polls at the interval each sample states.
		core=$(( (t2 - t1) * 10 )); [ "$core" -lt 0 ] && core=0
		EFF=$(( (core * 3 + 999) / 1000 )); [ "$EFF" -lt "$INTERVAL" ] && EFF=$INTERVAL
		[ "$HEALTH" -ge 1 ] && [ "$EFF" -lt $((INTERVAL * 3)) ] && EFF=$((INTERVAL * 3))
		[ "$EFF" -gt 10 ] && EFF=10
		seq=$((seq + 1))
		# The page shows rates from the second sample on: on a router that isn't busy that one comes after 1 s, so the page is
		# live about a second after the router started. The names are written alongside, so they don't hold it up.
		if [ $seq -eq 1 ]; then
			( export_names ) 8>&- &   # without the sampler's lock (a hung child must not keep it); ash keeps fd 8 for "f 8>&-"
			[ "$HEALTH" -eq 0 ] && { sampler_nap 1; continue; }
		fi
		sampler_nap "$EFF"
	done
	node_stop_all
	rm -f "$TMPD/sampler.pid" "$WD/clist.htm"   # the copy of the client list a rename read: needed only while the page is open
	[ $paused = 1 ] || log "sampling stopped: no page open (closed, paused or in a hidden tab)"
}

# The pause between samples, cut short by the page closing: the shell runs a trap (USR1, above) only once a command it waits
# for has ended, and 'wait' ends at once when a signal comes, where a 'sleep' in the foreground would run its course.
# The sleep doesn't get the sampler's lock (fd 8): one left running must not keep the next sampler from starting.
sampler_nap() { [ -n "$SAMPLER_STOP" ] && return 0; sleep "$1" 8>&- & sn=$!; wait $sn 2>/dev/null || kill $sn 2>/dev/null; }   # kill only a sleep the stop cut short: a finished one's number is free again
cl_count() { nvram get custom_clientlist | tr '<' '\n' | grep -c '>'; }   # names in the router's client list

service_event() {   # action service
	[ "$1" = "start" ] || return 0
	case "$2" in
		"$NAME")
			tmpd; touch "$TMPD/heartbeat"
			# the sampler's own errors are kept (doctor shows them): it is started with nowhere else to say anything
			sampler_running || paused_recently || { : > "$TMPD/sampler.err"; (sh "$SCRIPT" sampler < /dev/null > /dev/null 2>> "$TMPD/sampler.err" &); } ;;   # paused: the page says why
		"${NAME}stop")
			rm -f "$TMPD/heartbeat"
			p=$(cat "$TMPD/sampler.pid" 2>/dev/null)
			if pid_ours "$p" "$NAME.sh sampler"; then kill -USR1 "$p" 2>/dev/null || :; fi ;;   # only our own sampler
		"${NAME}names"*)   # a device was renamed on the page (it saved the router's client list first): show it now, not in 30 s
			tmpd; web_init && export_names
			b=$(cat "$TMPD/clist.n" 2>/dev/null); rm -f "$TMPD/clist.n"
			log "renamed a device on the page: the router's client list has $(cl_count) name(s)${b:+ (before: $b)}"
			# the copy of the list this rename read, by its token: gone now, paused page or not (another rename's stays)
			tok=${2#"${NAME}names"}
			case "$tok" in ''|*[!0-9]*) ;; *) [ ${#tok} -le 12 ] && grep -q "^{\"tok\":\"$tok\"," "$(web_dir)/clist.htm" 2>/dev/null && rm -f "$(web_dir)/clist.htm" ;; esac
			return 0 ;;
		"${NAME}cl"*)   # the page is about to rename a device: the router's client list as it is now, with the page's token
			tok=${2#"${NAME}cl"}
			case "$tok" in ''|*[!0-9]*) return 0 ;; esac
			[ ${#tok} -le 12 ] || return 0
			tmpd; web_init && printf '{"tok":"%s","custom":"%s"}' "$tok" "$(js "$(nvram get custom_clientlist)")" | write_atomic "$(web_dir)/clist.htm"
			n=$(cl_count); echo "$n" > "$TMPD/clist.n"
			log "renaming a device on the page: read the router's client list ($n name(s))" ;;
	esac
}

stop_all() {   # sampler and node sessions, e.g. before an update or uninstall
	p=$(cat "$TMPD/sampler.pid" 2>/dev/null)
	pid_ours "$p" "$NAME.sh sampler" && kill "$p" 2>/dev/null
	node_stop_all
	rm -f "$TMPD/sampler.pid" "$TMPD/heartbeat"
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

# Puts the edited menu ($1, in our folder) in place of /tmp/menuTree.js and removes $1, renamed into place (all at once:
# never a half-written menu). While the menu is mounted more than once, one mount over another (see menu_remount),
# /tmp/menuTree.js can't be renamed over ("Device or resource busy"): then the mounts come off first, and the caller
# mounts it again (menu_remount). Fails, the menu unchanged, when even that doesn't work.
menu_put() {
	mv -f "$1" "$TMP_MENUTREE" 2>/dev/null || { menu_unmount; mv -f "$1" "$TMP_MENUTREE" 2>/dev/null; }
	set -- $? "$1"; rm -f "$2"; return $1
}

# Every addon mounts the shared copy over the firmware's menu. One that mounts it without unmounting first (or two at
# once) leaves it mounted twice, one over the other: the page still shows the menu, but /tmp/menuTree.js can then no
# longer be renamed over, so no addon's menu change sticks. So every mount is removed (all of the same shared copy)
# and it's mounted once; only root's own menu file is mounted.
menu_unmount() { mr=0; while [ $mr -lt 8 ] && umount "$MENUTREE" 2>/dev/null; do mr=$((mr + 1)); done; }
menu_remount() {
	ours_menu || return 1
	menu_unmount
	mount -o bind "$TMP_MENUTREE" "$MENUTREE"
}
menu_mounts() { awk -v m="$MENUTREE" '$2 == m { n++ } END { print n + 0 }' "$PROC/mounts" 2>/dev/null || echo 0; }

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
	if ! ours_menu; then
		cp -f "$MENUTREE" "$TMPD/menuTree.base" && mv -f "$TMPD/menuTree.base" "$TMP_MENUTREE" || { flock -u 9; return 1; }
	fi
	rm -f "$TMPD"/menuTree.[0-9]*   # left by an older version when /tmp/menuTree.js couldn't be replaced (see below)
	new="$TMPD/menuTree.$$"   # in our own folder: a name in /tmp could be a link someone planted
	sed "/tabName: \"$TITLE\"/d" "$TMP_MENUTREE" > "$new"
	before=$(wc -l < "$new")
	entry="{url: \"$am_webui_page\", tabName: \"$TITLE\"},"
	menu_insert "$new" "$entry"
	if [ -n "$where" ] && [ "$(grep -c "tabName: \"$TITLE\"" "$new")" = "$added" ] && [ "$(wc -l < "$new")" -eq $((before + added)) ]; then
		if ! menu_put "$new"; then
			say "Couldn't update the menu ($TMP_MENUTREE can't be changed), so it was left as it was. Open http://$(nvram get lan_ipaddr)/$am_webui_page instead."
			log "menu not updated: $TMP_MENUTREE can't be replaced or written"
		fi
		menu_remount
		echo "$where" > "$TMPD/menu_where"
	else
		rm -f "$new" "$TMPD/menu_where"
		say "Couldn't add the menu entry safely, so the menu was left alone. Open http://$(nvram get lan_ipaddr)/$am_webui_page instead."
		log "menu entry not added (unexpected menuTree.js); page at $am_webui_page"
	fi
	flock -u 9
	web_init
	log "web UI mounted as $am_webui_page"
}

unmount_webui() {
	tmpd; page=$(cat "$ADDON_DIR/webui_page" 2>/dev/null)
	webui_lock || return 1
	if ours_menu; then   # the edited copy replaces the menu only if it came out whole: its lines, less ours, and its last line
		new="$TMPD/menuTree.$$"; n0=$(wc -l < "$TMP_MENUTREE"); k=$(grep -c "tabName: \"$TITLE\"" "$TMP_MENUTREE")
		if sed "/tabName: \"$TITLE\"/d" "$TMP_MENUTREE" > "$new" 2>/dev/null && [ "$(wc -l < "$new")" -eq $((n0 - k)) ] \
			&& [ "$(tail -n 1 "$new")" = "$(tail -n 1 "$TMP_MENUTREE")" ]; then menu_put "$new"
		else rm -f "$new"; log "menu entry not removed: the edited copy didn't come out whole (/tmp full?)"; fi
		menu_remount
	fi
	[ -n "$page" ] && is_ours "$page" && rm -f "$WWW_USER/$page" "$WWW_USER/${page%.asp}.title"
	flock -u 9
}

# Arteria's line goes first, right after #!/bin/sh: the router runs these scripts line by line, and a line before ours that
# ends the script (exit) or waits for something would keep the page's requests from ever reaching Arteria. Our line only
# starts Arteria in the background, for its own events: it never holds up the lines after it.
hook_add() {   # file line
	f="$SCRIPTS_DIR/$1"
	[ -s "$f" ] || printf '#!/bin/sh\n' > "$f"   # missing or empty
	hook_put "$f" "$2 # $NAME"
	chmod 755 "$f"
}
hook_del() {   # only lines this addon wrote: they run our script and end with our tag (older versions' lines start with it)
	f="$SCRIPTS_DIR/$1"
	[ -f "$f" ] && hook_put "$f"
	return 0
}
# A hook file without Arteria's lines, and with the line given (if any) right after #!/bin/sh (added if missing); Windows line
# endings dropped (the router can't run a file that has them). The new file is made in full and checked (its line count)
# before it's written over the old one in place (cat >, so it keeps its owner and mode); a copy of the old one is kept until
# the written file matches, and put back if it doesn't: a full JFFS never leaves it cut short, other addons' lines lost.
# ENVIRON, so awk reads the lines as they are.
HOOK_AWK='function ours(l) { t = "# " ENVIRON["N"]; return substr(l, length(l) - length(t) + 1) == t && (index(l, ENVIRON["S"] " ") == 1 || index(l, "case \"$2\" in " ENVIRON["N"] "*) " ENVIRON["S"] " ") == 1) }
	{ sub(/\r$/, "") }
	NR == 1 { if (ENVIRON["L"] != "") { if ($0 ~ /^#!/) { print; n++; $0 = "" } else { print "#!/bin/sh"; n++ } print ENVIRON["L"]; n++; if ($0 == "") next }
		else if ($0 !~ /^#!/) { print "#!/bin/sh"; n++ } }
	ours($0) { next }
	{ print; n++ }
	END { if (ENVIRON["C"] != "") { printf "%d\n", n > ENVIRON["C"] } }'
hook_put() {   # file [line]
	hp_n="$1.$$"; hp_o="$1.o$$"; hp_c="$1.c$$"
	S="$SCRIPT" N="$NAME" L="$2" C="$hp_c" awk "$HOOK_AWK" "$1" > "$hp_n" 2>/dev/null
	if [ -s "$hp_c" ] && [ "$(wc -l < "$hp_n")" -eq "$(cat "$hp_c")" ] && cp -p "$1" "$hp_o" 2>/dev/null && cmp -s "$1" "$hp_o"; then
		if ! { cat "$hp_n" > "$1" && cmp -s "$hp_n" "$1"; } 2>/dev/null; then
			cat "$hp_o" > "$1" 2>/dev/null; log "couldn't rewrite $1 (JFFS full?): left as it was"
		fi
	elif ! cmp -s "$1" "$hp_n" 2>/dev/null; then log "couldn't rewrite $1 (JFFS full?): left as it was"; fi
	rm -f "$hp_n" "$hp_o" "$hp_c"
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
IDLE_STOP=$IDLE_STOP            # stop sampling this many seconds after the last heartbeat of an open page (120-300)
NODES=$NODES               # on: read each AiMesh node's per-device counters over SSH; off: backhaul totals only
NODE_USER="$NODE_USER"            # SSH user on the nodes; empty = the router's admin name
AMTM_UPDATE=$AMTM_UPDATE         # on: amtm may update Arteria (amtmupdate); off: only 'update' does
EOF
}

# ---- AiMesh node access (an SSH key only the router holds) -------------------------
make_key() {   # newer dropbearkey also writes the public key next to the new one (.new.pub): not needed, pub_key reads it
	mkdir -p "$ADDON_DIR"
	rm -f "$KEY.new" "$KEY.new.pub"
	dropbearkey -t ed25519 -f "$KEY.new" > /dev/null 2>&1 || dropbearkey -t rsa -s 2048 -f "$KEY.new" > /dev/null 2>&1 || { rm -f "$KEY.new" "$KEY.new.pub"; return 1; }
	rm -f "$KEY.new.pub"
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

# Wait for a process, at most some seconds, looking every 0.2 s (usleep, which Merlin's BusyBox has; else every second):
# a login that takes half a second doesn't keep nodes test, nodekey or doctor waiting a whole one.
wait_pid() {   # pid seconds -> 1 if it had to be stopped
	if have usleep; then wp_n=$(( $2 * 5 )); wp_s="usleep 200000"; else wp_n=$2; wp_s="sleep 1"; fi
	wp_i=0
	while kill -0 "$1" 2>/dev/null; do
		[ $wp_i -ge $wp_n ] && { kill "$1" 2>/dev/null; return 1; }
		$wp_s; wp_i=$((wp_i + 1))
	done
	return 0
}

# Try the key on a node: key only, never a password (see ssh_batch). Gives up after 8 s.
# Returns 0 if the key works, 1 if not, 2 if it can't be tried without risking a password prompt
# (an older dbclient, run from a terminal).
node_try() {   # ip [pin] [command]   pin: also trust and pin the identity that answers (only after the person said yes)
	# command: run on the node, ending with "echo arteria-ok"; its output is left in TRY_OUT
	tmpd; ssh_home_init; o="$TMPD/try.$$"; TRY_ERR=""; TRY_HOSTKEY=0; TRY_NEW=0; TRY_FP=""; TRY_OUT=""; y=""; [ "$2" = pin ] && y=-y
	b=$(ssh_batch)
	if [ -z "$b" ] && has_tty; then TRY_ERR="this firmware's SSH client can't try a key without offering a password"; return 2; fi
	(ulimit -f 2048 2>/dev/null; HOME="$SSH_HOME" exec dbclient $b $y -p "$(ssh_port)" $(key_args) "$(ssh_user)@$1" "${3:-echo arteria-ok}") \
		< /dev/null > "$o" 2>&1 &
	wait_pid $! 8
	grep -q '^arteria-ok' "$o" 2>/dev/null; rc=$?
	grep -qi 'host key mismatch' "$o" 2>/dev/null && TRY_HOSTKEY=1
	grep -qi 'not in the trusted hosts' "$o" 2>/dev/null && TRY_NEW=1   # first contact: nothing pinned for this address yet
	TRY_FP=$(grep -o '[A-Za-z0-9-]* fingerprint [A-Za-z0-9:+/=]*' "$o" 2>/dev/null | head -1)
	TRY_ERR=$(grep -v '^arteria-ok' "$o" 2>/dev/null | tail -1 | tr -cd '\040-\176' | cut -c1-120)
	TRY_OUT=$(head -c 512 "$o" 2>/dev/null | tr -cd '\012\040-\176')
	rm -f "$o"
	return $rc
}

# Which of the keys a node takes, for the terminal: each tried on its own (key only, never a password).
key_used() {   # ip -> the key's name, or nothing
	for k in $(node_keys); do TRY_KEYS="$k" node_try "$1" > /dev/null 2>&1 && { key_name "$k"; return 0; }; done
	return 1
}
# For text that may be posted in a bug report: addresses and user names out.
scrub() { sed 's/[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}/IP/g; s/[0-9A-Fa-f]\{2\}\(:[0-9A-Fa-f]\{2\}\)\{5\}/MAC/g; s/[A-Za-z0-9._-]*@/user@/g'; }

# One round of the script the page runs on a node: whether it works there, how many devices it reads and how
# long that takes. The page counts a node as answering while its output keeps up with its own pace, up to a round every
# 30 s, so a node slower than that shows as "not answering" even though key login works.
node_probe() {   # ip [trace-file] -> PROBE_MSG, PROBE_CRASH (1: something crashed there); 0 if a round came back
	tmpd; ssh_home_init; o="$TMPD/probe.$$"; PROBE_MSG=""; PROBE_CRASH=0; TRACE_AT=""; WHY_BAD=0
	t0=$(now)
	# ulimit -f, as for the page's sessions: a node that floods its output can't fill the router's RAM (about 1 MB at most)
	(ulimit -f 2048 2>/dev/null; HOME="$SSH_HOME" exec dbclient $(ssh_batch) -p "$(ssh_port)" $(key_args) "$(ssh_user)@$1" "$(write_node_script 1)") < /dev/null > "$o" 2>&1 &
	wait_pid $! 30; late=$?
	t=$(( $(now) - t0 )); [ $t -ge 1 ] || t=1
	if grep -q '^#E' "$o" 2>/dev/null; then
		nd=$(grep -c '^S ' "$o"); nw=$(grep -c '^M ' "$o")
		PROBE_MSG="reads $nd device(s), one round takes about $t s"
		[ $t -gt 30 ] && PROBE_MSG="$PROBE_MSG: too slow, the page shows it as not answering"
		[ "$nd" = 0 ] && { node_why "$1"; PROBE_MSG="$PROBE_MSG ($WHY_MSG)"; }
		[ "$nw" = 0 ] || PROBE_MSG="$PROBE_MSG; $nw more on its wired ports"
		rc=0
	elif [ $late = 1 ]; then PROBE_MSG="reading its devices took over 30 s"; rc=1
	else
		# the last line that isn't the script's own output (a network's name, an address): what the session said when it broke
		e=$(grep -v -e '^#B' -e '^[SUCLMNX] ' -e '^#E' "$o" 2>/dev/null | tr -cd '\012\040-\176' | grep . | tail -1 | scrub | cut -c1-120)
		PROBE_MSG="reading its devices failed${e:+: $e}"; rc=1
	fi
	grep -Eq "$CRASH_RE" "$o" 2>/dev/null && PROBE_CRASH=1
	rm -f "$o"
	# Something on the node crashed (its firmware's awk or wl, say): the same round again, traced, says what
	if [ $PROBE_CRASH = 1 ]; then
		tf=${2:-$TMPD/node-trace.txt}
		node_trace "$1" "$tf"
		PROBE_MSG="$PROBE_MSG; something on the node crashed${TRACE_AT:+ running: $TRACE_AT} (what it ran is in $tf, without addresses)"
	fi
	return $rc
}
# A node that reads 0 devices: which of its interfaces the script reads and which it skips as the uplink, with each one's
# device count. Devices on a skipped interface mean the uplink was guessed wrong on that node. Interface names only.
node_why() {   # ip -> WHY_MSG
	wo="$TMPD/why.$$"
	(ulimit -f 2048 2>/dev/null; HOME="$SSH_HOME" exec dbclient $(ssh_batch) -p "$(ssh_port)" $(key_args) "$(ssh_user)@$1" "$(write_node_script 1 why)") < /dev/null > "$wo" 2>&1 &
	wait_pid $! 30
	WHY_MSG=$(awk 'n < 32 && $1 == "W" && $3 ~ /^[A-Za-z0-9._-]+$/ && length($3) <= 16 && $5 ~ /^[0-9]+$/ && length($5) <= 6 { n++
		if ($2 == "read") r = r (r ? ", " : "") $3 " " $5
		else if ($2 == "skip" && $4 == "listed") { s = s (s ? ", " : "") $3 " " $5; if ($5 > 0) bad = 1 }
		else if ($2 == "skip" && $4 ~ /^(sta|wet|psta|psr)$/) s = s (s ? ", " : "") $3 " (" $4 " mode, its uplink)" }
		END { printf "%sdevices on each interface it reads: %s; on each it skips as the uplink: %s", (bad ? "!" : ""), (r ? r : "none"), (s ? s : "none") }' "$wo" | cut -c1-600)
	WHY_BAD=0; case "$WHY_MSG" in !*) WHY_BAD=1; WHY_MSG=${WHY_MSG#!} ;; esac   # devices on an interface taken for the uplink
	grep -Eq "$CRASH_RE" "$wo" 2>/dev/null && WHY_MSG="$WHY_MSG; something crashed while counting them"
	rm -f "$wo"
}
# One round of the node's script, traced (each command named before it runs), with every command's errors shown (the page's
# own run hides wl's): a command that crashes on the node is named. The trace goes to a file for a bug report, without
# addresses or user names.
CRASH_RE='Segmentation fault|Illegal instruction|Bus error'
node_trace() {   # ip file -> 0 if something crashed on the node; TRACE_AT: the command it was running
	tmpd; o="$TMPD/trace.$$"; TRACE_AT=""
	(ulimit -f 2048 2>/dev/null; HOME="$SSH_HOME" exec dbclient $(ssh_batch) -p "$(ssh_port)" $(key_args) "$(ssh_user)@$1" "$(write_node_script 1 trace | sed 's| 2>/dev/null||g')") < /dev/null > "$o" 2>&1 &
	wait_pid $! 30
	grep -v '^N ' "$o" | tr -cd '\012\040-\176' | scrub | cut -c1-200 | head -n 400 > "$2"   # N: a network's name, never in a report
	rm -f "$o"
	grep -Eq "$CRASH_RE" "$2" || return 1
	TRACE_AT=$(awk -v re="$CRASH_RE" '$0 ~ re { print c; exit } /^\+ / { c = substr($0, 3, 80) }' "$2")
	return 0
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
			if [ -z "$(node_keys)" ]; then line="$line: no key yet, run '$SCRIPT nodekey'"
			else
				import_pin "$ip"; node_try "$ip"; rc=$?
				if [ $rc -eq 0 ]; then node_probe "$ip"; line="$line: key login OK ($(key_used "$ip")), $PROBE_MSG"
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
	unpin "$1"
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

# Arteria's key in the router's own list (once per nodekey run), so AiMesh keeps it on the nodes. On nodes with ASUS's
# own firmware only the first key of that list works once the router's web page has saved it (Merlin joins its keys with
# '>', which that firmware doesn't split), so when other keys are already listed it says so.
nodekey_router_list() {   # uses $pub and $b64; sets rk
	[ "$rk" = 1 ] && return 0; rk=1
	others=$(nvram get sshd_authkeys | tr '>' '\n' | grep -c '^ssh-')
	router_key_add "$pub" "$b64" || return 0
	say "  Added Arteria's key to the router's own SSH key list (Administration > System > Authorized Keys): AiMesh"
	say "  copies that list to the nodes, so they keep it."
	if [ "${others:-0}" -gt 0 ]; then
		say "  That list already had $others key(s). Nodes with ASUS's own firmware take only the first key in it once the"
		say "  router's web page has saved it, so Arteria's may not reach those nodes: a key of the router's own (see below) does."
	fi
}
# A node takes one of the keys: with Arteria's, keep it listed on the node and in the router's list; with the key root
# already logs in to the nodes with, there's nothing to add.
nodekey_works() {   # ip message
	w=$(key_used "$1")
	if [ -n "$w" ] && [ "$w" != "Arteria's key" ]; then say "  Key login works with $w, the key root on this router already uses for the nodes: nothing to add."; return 0; fi
	say "  $2"; nodekey_router_list; node_keep_key "$1"
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
	ssh_home_init; rk=0
	list=$(node_list)
	[ -n "$1" ] && list=$(printf '%s\n' "$list" | awk -v ip="$1" '$2 == ip')
	if [ -z "$list" ]; then [ -n "$1" ] && die "No AiMesh node at $1 found."; nodes_none_why; exit 1; fi
	fails=0; sync=0
	# With password login off (Administration > System > Allow Password Login), a node takes no password, but it
	# loads the router's key list (which gets Arteria's key, see nodekey_router_list) when it starts: reboot it.
	nopass=0; [ "$(nvram get sshd_pass)" = "0" ] && nopass=1
	# the remote side: add the key unless it's there, then restart its SSH server (after we've disconnected)
	cmd="k='$pub'; c=\$(nvram get sshd_authkeys); case \"\$c\" in *'$b64'*) echo arteria-had-key ;; *) nvram set sshd_authkeys=\"\${c:+\$c
}\$k\"; nvram commit; echo arteria-added-key; (sleep 2; service restart_sshd) > /dev/null 2>&1 & ;; esac"
	printf '%s\n' "$list" > "$TMPD/nodekey.list"
	while read -r mac ip model; do
		al=$(node_alias "$mac")
		say ""
		say "${al:-$model} ($model, $ip)"
		imp=0; import_pin "$ip" && imp=1
		node_try "$ip"; rc=$?
		if [ $rc -eq 0 ]; then [ $imp = 1 ] && say "  Trusted its SSH identity as root on this router already does."; nodekey_works "$ip" "Already has the key."; continue; fi
		# Root's known_hosts may have been filled without anyone checking. A key login that works risks nothing, but a
		# password goes only to an identity confirmed here: forget the copied one, so the question below shows its fingerprint.
		if [ $imp = 1 ] && [ $rc -ne 2 ]; then unpin "$ip"; node_try "$ip"; rc=$?; fi   # (2: no key try at all; keep root's pin then)
		if [ "$TRY_HOSTKEY" = 1 ] && ! trust_new_identity "$ip"; then fails=$((fails + 1)); continue; fi
		if [ "$TRY_NEW" = 1 ] && ! trust_first_contact "$ip"; then fails=$((fails + 1)); continue; fi
		if [ "$TRY_HOSTKEY" = 1 ] || [ "$TRY_NEW" = 1 ]; then   # trusted now: the key may already be there (an AiMesh sync)
			node_try "$ip" pin && { nodekey_works "$ip" "Key login works."; continue; }
		fi
		nodekey_router_list
		if [ $nopass = 1 ]; then say "  Password login over SSH is off on the router, so the key reaches this node from the router's list."; sync=$((sync + 1)); continue; fi
		say "  Enter the node's password (your router's admin password). It goes to the node only and isn't stored."
		out=$(HOME="$SSH_HOME" dbclient -y -p "$(ssh_port)" "$(ssh_user)@$ip" "$cmd" < /dev/tty 2>&1)
		case "$out" in *[Hh]ost\ key\ mismatch*)   # only seen here when the key couldn't be tried first (an older dbclient)
			if trust_new_identity "$ip"; then out=$(HOME="$SSH_HOME" dbclient -y -p "$(ssh_port)" "$(ssh_user)@$ip" "$cmd" < /dev/tty 2>&1); fi ;;
		esac
		case "$out" in
			*arteria-had-key*)   say "  The node already listed the key." ;;
			*arteria-added-key*) say "  Key added."; sleep "${AR_SSHD_WAIT:-4}" ;;
			*[Nn]o\ auth\ methods*) say "  The node doesn't take passwords over SSH, so the key reaches it from the router's list."; sync=$((sync + 1)); continue ;;
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
		say "$sync node(s) will get Arteria's key from the router's own list (Administration > System > Authorized Keys)."
		say "A node loads that list when it starts: reboot it (in the router's web page: AiMesh, pick the node, reboot),"
		say "wait until it's back in the AiMesh list, then run '$SCRIPT nodes test'."
		say "If this router already has a key it logs in to the nodes with, Arteria uses it too: keep it in"
		say "/jffs/.ssh/id_dropbear (or ~/.ssh/id_dropbear), and its nodes in root's known_hosts."
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
ck_info() { say "  [INFO] $*"; }
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
			ck_info "No Wi-Fi clients on the router itself right now (devices on AiMesh nodes don't count here), so the per-client counters will be checked once one connects: run check again then."
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
		# rename into place: a running copy of the old script (e.g. during update) keeps reading its own file. A development
		# version gets "# amtm NoMD5check" under its first line: amtm takes a script that differs from the release with the same
		# number for an MD5 update, and that update would put the release back over it. A release's own file has no such line.
		if [ -n "$AR_BUILD" ]; then
			{ head -n 1 "$0"; echo '# amtm NoMD5check (a development version: not the release with this number)'; tail -n +2 "$0" | grep -v '^# amtm NoMD5check'; } > "$SCRIPT.new"
		else
			grep -v '^# amtm NoMD5check' "$0" > "$SCRIPT.new"
		fi && mv -f "$SCRIPT.new" "$SCRIPT"
		cp -f "$asp" "$PAGE_SRC.new" && mv -f "$PAGE_SRC.new" "$PAGE_SRC"
		rm -f "$TMPD/$NAME.asp.dl"
	fi
	chmod 755 "$SCRIPT"
	if [ -n "$AR_BUILD" ]; then printf '%s\n' "$AR_BUILD" > "$BUILD_FILE"; else rm -f "$BUILD_FILE"; fi
	[ -f "$CONF" ] || write_conf
	hook_add services-start "$SCRIPT startup &"
	hook_add service-event "case \"\$2\" in $NAME*) $SCRIPT service_event \"\$@\" & ;; esac"
	# left by an older version's key setup, or by a development version's device recognition
	rm -f "$KEY.new.pub" "$ADDON_DIR/discovered" "$ADDON_DIR/fingerbank" "$ADDON_DIR/fingerbank_key"
	startup

	# AiMesh nodes: per-device counters need the router's key on each node
	nl=""
	[ "$NODES" = on ] && have dbclient && have dropbearkey && nl=$(node_list)
	if [ -n "$nl" ]; then
		[ -s "$KEY" ] || make_key || say "Couldn't create the SSH key for the nodes."
		missing=""
		printf '%s\n' "$nl" > "$TMPD/install.nodes"
		while read -r mac ip model; do
			import_pin "$ip"; node_try "$ip" || missing="$missing $ip"
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
	say "Arteria samples only while that page is open: it stops when you close it, or about $IDLE_STOP seconds after you switch away."
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
	# amtm asks for an update when the script differs from the release with the same number: a development version does.
	# Through amtm, a development version is replaced only by a newer release ('update' itself goes back to the release).
	# amtm runs amtmupdate only for a newer number, so a development version stays over the release with its own number
	# until the next one, or until 'update'.
	if [ -n "$AR_AMTM" ] && [ -f "$BUILD_FILE" ] && ! ver_gt "$new" "$VERSION"; then
		rm -rf "$dl"; say "Kept the $(build_text): the latest release, $new, isn't newer. '$SCRIPT update' goes back to it."; return 0
	fi
	if ver_gt "$VERSION" "$new" && [ "$1" != "force" ]; then
		rm -rf "$dl"
		say "This is $VERSION$( [ -f "$BUILD_FILE" ] && printf ' (a development version)'), newer than the latest release ($new). Nothing was changed; 'update force' installs $new."
		return 0
	fi
	get_page "$rel" "the latest release"
	# the same number again only replaces a development version (update dev): say so
	say "Updating $VERSION$( [ -f "$BUILD_FILE" ] && printf ' (%s)' "$(build_text)") -> $new$( [ -f "$BUILD_FILE" ] && printf ', the release') (settings and node access are kept)"
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
		say "Sampling:    no (starts when the page opens; stops when it closes, or ${IDLE_STOP} s after you switch away)"
	fi
	CPUS=$(cpu_count); health
	say "Router:      load $LOAD on $CPUS cores, $MEMMB MB memory available$( [ "$HEALTH" -ge 2 ] && printf ': overloaded, Arteria would pause' )$( [ "$HEALTH" = 1 ] && printf ': busy, Arteria samples less often' )"
	if [ -f "$PAUSED" ]; then
		read -r pt pw pl pc pm < "$PAUSED"
		LOAD=${pl:-$LOAD}; CPUS=${pc:-$CPUS}; MEMMB=${pm:-$MEMMB}   # what it saw then, not now
		say "Last pause:  $(date -d "@$pt" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "$pt"), $(health_text "$pw")$(paused_recently && printf ' (resumes within 2 minutes)')"
	fi
	say "Node access: $NODES$( [ "$NODES" = on ] && { [ -n "$(node_keys)" ] && printf ', key present' || printf ", no key yet ('nodekey' creates it)"; })"
	nl=$(node_list)
	[ -n "$nl" ] && say "Nodes:       $(node_models "$nl") (details: '$SCRIPT nodes test')"
	say "amtm updates: $AMTM_UPDATE"
}

# ---- doctor: Arteria's known problems on this router, and what fixes each -----------------------------------------
# It only looks, unless asked to fix: 'doctor fix' repairs what's safe to repair here (the hook lines, file permissions,
# files and node sessions left over) and leaves the rest to you or a bug report. No device names, MACs or IPs in it.
dr_ok()   { say "  [ OK ] $*"; }
dr_info() { say "  [INFO] $*"; }
dr_warn() { say "  [WARN] $*"; DR_W=$((DR_W + 1)); }
dr_fix()  { if [ "$DR_FX" = 1 ]; then say "  [DONE] $*: fixed"; DR_D=$((DR_D + 1)); else say "  [FIX ] $*"; DR_F=$((DR_F + 1)); fi; }
dr_hook() {   # file line what
	f="$SCRIPTS_DIR/$1"
	if grep -q "$(printf '\r')" "$f" 2>/dev/null; then   # saved by a Windows editor: "#!/bin/sh\r" isn't a shell, so the router can't run it
		[ "$DR_FX" = 1 ] && hook_add "$1" "$2"   # rewritten without them (and with Arteria's line first)
		dr_fix "$1 has Windows line endings, so the router can't run it (none of the lines in it run)"
	fi
	cf="$TMPD/hook.$$"; sed 's/\r$//' "$f" > "$cf" 2>/dev/null   # its lines, without Windows line endings (that's said above)
	cur=$(grep -cxF "$2 # $NAME" "$cf" 2>/dev/null); cur=${cur:-0}
	all=$(grep -c "# $NAME\$" "$cf" 2>/dev/null); all=${all:-0}
	if [ "$cur" = 1 ] && [ "$all" = 1 ] && [ -x "$f" ] && [ "$(sed -n 2p "$cf")" = "$2 # $NAME" ]; then dr_ok "$1: Arteria's line, once, first ($3)"
	else
		if [ "$all" = 0 ]; then w="$1 has no line of Arteria's, so $3 doesn't happen"
		elif [ "$cur" = 0 ]; then w="$1 has an older line of Arteria's (an older version's, or one left by going back to 1.0.0)"
		elif [ ! -x "$f" ]; then w="$1 isn't executable, so the router doesn't run it"
		elif [ "$all" != 1 ]; then w="$1 has $all lines of Arteria's: an older one too (going back to 1.0.0 leaves today's line next to its own)"
		else w="$1: Arteria's line isn't first, so a line before it can keep it from running (one that ends the script, or waits)"
		fi
		[ "$DR_FX" = 1 ] && hook_add "$1" "$2"
		dr_fix "$w"
	fi
	o=$(grep -v "# $NAME\$" "$cf" 2>/dev/null | grep -c "$NAME"); o=${o:-0}
	rm -f "$cf"
	[ "$o" -gt 0 ] && dr_info "$1: $o more line(s) mention $NAME but aren't Arteria's own (yours?), left alone"
	return 0
}
# The router's system log, oldest first: /tmp/syslog.log and the one before it, or scribe's (syslog-ng's) when it keeps its own.
log_files() {
	for f in "$ROOT/tmp/syslog.log-1" "$ROOT/tmp/syslog.log"; do [ -s "$f" ] && ours_file "$f" && printf '%s\n' "$f"; done   # /tmp: root's own only
	f="$ROOT/opt/var/log/messages"; [ -s "$f" ] && [ ! -L "$f" ] && printf '%s\n' "$f"
	return 0
}
# The log's lines about the page's requests: Arteria's own, the router running service-event for them, and the router's
# service handler waiting for, or dropping, a request because it was still busy with another. Addresses taken out.
log_requests() {   # [lines]
	for f in $(log_files); do cat "$f"; done 2>/dev/null | grep -E "$NAME|skip the event|waitting|waiting \"" | tail -n "${1:-12}" | scrub | tr -cd '\012\040-\176' | cut -c1-160
}
# Lines of service-event other than Arteria's that run a program and wait for it. The router runs service-event for every
# service request, one request at a time, and waits for it (up to 2 minutes): the page's requests wait behind these lines.
hook_waiters() {
	sed 's/\r$//' "$SCRIPTS_DIR/service-event" 2>/dev/null | awk -v me="# $NAME" 'NR == 1 && /^#!/ { next } /^[ \t]*(#|$)/ { next }
		substr($0, length($0) - length(me) + 1) == me { next }
		/\// && $0 !~ /&[ \t]*($|;|#|fi([ \t]|$)|esac)/ { for (i = 1; i < NF; i++) if ($i !~ /^[A-Za-z_][A-Za-z0-9_]*=/) break
			n = split($i, a, "/"); p = a[n]; gsub(/[^A-Za-z0-9._+-]/, "", p); print "line " NR ": " substr(p, 1, 40) }'   # its program's name only: the rest can hold passwords, tokens
}
# What the page does when it opens, end to end: a service request (start_arteria), the router's service-event hook, the
# sampler starting, and its first samples. Then it stops sampling again, as the page does when it closes.
dr_wait() {   # seconds test-command...  -> 0 once the test passes
	dw_n=$1; shift
	if have usleep; then dw_n=$((dw_n * 5)); dw_s="usleep 200000"; else dw_s="sleep 1"; fi
	while [ "$dw_n" -gt 0 ]; do "$@" && return 0; $dw_s; dw_n=$((dw_n - 1)); done
	"$@"
}
dr_hb_since() { h=$(date -r "$TMPD/heartbeat" +%s 2>/dev/null) && [ "$h" -ge "$DR_T0" ]; }
dr_sampled() { f="$(web_dir)/live.htm"; m=$(date -r "$f" +%s 2>/dev/null) && [ "$m" -ge "$DR_T0" ] && grep -q '"seq":[1-9]\|"paused":' "$f"; }
dr_stopped() { ! sampler_running; }
dr_request() {
	if sampler_running; then dr_ok "a page is open and sampling runs: its requests reach Arteria"; return 0; fi
	if paused_recently; then dr_info "Arteria paused itself in the last 2 minutes ('$SCRIPT status' says why): run doctor again after that to test the page's requests"; return 0; fi
	if ! have service; then dr_info "this firmware has no 'service' command, so the page's requests can't be tested from here"; return 0; fi
	dwq=${AR_DR_WAIT:-20}; dws=${AR_DR_WAIT:-15}   # AR_DR_WAIT: test hook only
	sleep 1; DR_T0=$(now)
	service start_arteria > /dev/null 2>&1
	if ! dr_wait "$dwq" dr_hb_since; then
		dr_warn "a request like the page's (start_arteria) didn't reach Arteria within $dwq s: the page would show 'Connecting…'"
		e=$(log_requests 40 | grep -E "skip the event|waitting|waiting \"" | tail -n 3)
		[ -n "$e" ] && { dr_info "the router's service handler was busy with another request:"; printf '%s\n' "$e" | sed 's/^/           /'; }
	else
		t1=$(( $(now) - DR_T0 ))
		if dr_wait "$dws" dr_sampled; then
			if grep -q '"paused":' "$(web_dir)/live.htm"; then dr_info "a request like the page's reached Arteria in $t1 s, and it paused itself: '$SCRIPT status' says why"
			else dr_ok "a request like the page's reached Arteria in $t1 s, and its first samples came $(( $(now) - DR_T0 - t1 )) s later"; fi
		else
			dr_warn "a request like the page's reached Arteria in $t1 s, but no samples came within $dws s"
			e=$(grep . "$TMPD/sampler.err" 2>/dev/null | tail -n 3 | scrub | tr -cd '\012\040-\176' | cut -c1-140)
			[ -n "$e" ] && { dr_info "the sampler's last errors:"; printf '%s\n' "$e" | sed 's/^/           /'; }
		fi
		[ "$t1" -gt 5 ] && dr_info "requests take $t1 s to reach Arteria: the router handles one at a time, so each waits for the one before it"
	fi
	service start_arteriastop > /dev/null 2>&1
	dr_wait 10 dr_stopped
	w=$(hook_waiters)
	if [ -n "$w" ]; then
		dr_info "service-event runs these line(s) for every service request, the page's too, and the router waits for them:"
		printf '%s\n' "$w" | head -n 5 | scrub | sed 's/^/           /'
	fi
	return 0
}
# A lock left held: something still has the sampler's lock open (a process left from a sampler that was killed), so every
# sampler the page starts gives up at once.
dr_lock() {
	l="$TMPD/sampler.lock"
	sampler_running && return 0
	[ -f "$l" ] || return 0
	( flock -n 9 ) 2>/dev/null 9< "$l" && return 0
	hp=""; hc=""
	for q in /proc/[0-9]*; do
		for d in "$q"/fd/*; do
			[ "$(readlink "$d" 2>/dev/null)" = "$l" ] || continue
			hp="$hp ${q#/proc/}"; hc="$hc; $(tr '\000' ' ' 2>/dev/null < "$q/cmdline" | awk 'NR == 1 { n = split($1, a, "/"); p = a[n]; if (p ~ /^(ba|a|)sh$/ && $2 != "") { n = split($2, a, "/"); p = p " " a[n] } print p }' | tr -cd '\040-\176' | cut -c1-40)"; break
		done
	done
	if [ "$DR_FX" = 1 ]; then   # only something Arteria started has its private lock (in its own folder) open: all of them go
		kill $hp 2>/dev/null
		if ! dr_wait 3 dr_lock_free; then
			dr_warn "something still holds the sampler's lock, so the page can't start sampling${hc:+ (${hc#; })}, and stopping it didn't free it: a reboot does"
			return 0
		fi
	fi
	dr_fix "something still holds the sampler's lock, so the page can't start sampling${hc:+ (${hc#; })}"
}
dr_lock_free() { ( flock -n 9 ) 2>/dev/null 9< "$TMPD/sampler.lock"; }

doctor() {   # [fix]
	tmpd; DR_FX=0; [ "$1" = fix ] && DR_FX=1; DR_F=0; DR_W=0; DR_D=0
	say "$TITLE $VERSION: looking for known problems$( [ "$DR_FX" = 1 ] && printf ', and fixing what can be fixed here')"
	say ""
	say "Installation"
	if [ -f "$SCRIPT" ]; then
		dr_hook service-event "case \"\$2\" in $NAME*) $SCRIPT service_event \"\$@\" & ;; esac" "the page can start sampling"
		dr_hook services-start "$SCRIPT startup &" "the page is mounted again after a reboot"
	else dr_warn "Arteria isn't installed in $ADDON_DIR: run the installer"; fi
	n=0; for f in "$KEY.new.pub" "$ADDON_DIR/discovered" "$ADDON_DIR/fingerbank" "$ADDON_DIR/fingerbank_key"; do [ -e "$f" ] && n=$((n + 1)); done
	if [ $n -gt 0 ]; then
		[ "$DR_FX" = 1 ] && rm -f "$KEY.new.pub" "$ADDON_DIR/discovered" "$ADDON_DIR/fingerbank" "$ADDON_DIR/fingerbank_key"
		dr_fix "$n file(s) an older or development version left in $ADDON_DIR"
	else dr_ok "no files left by older versions"; fi
	mm=$(menu_mounts)
	if [ "$mm" -gt 1 ] && ! ours_menu; then dr_warn "the router's menu is mounted $mm times, one over another, and $TMP_MENUTREE isn't root's own menu file: not touching it"
	elif [ "$mm" -gt 1 ] && [ "$DR_FX" = 1 ] && ! { webui_lock && { menu_remount; flock -u 9; [ "$(menu_mounts)" = 1 ]; }; }; then
		dr_warn "the router's menu is mounted $mm times, one over another, and it couldn't be mounted once now: a reboot fixes it"
	elif [ "$mm" -gt 1 ]; then
		dr_fix "the router's menu is mounted $mm times, one over another (an addon mounted it again without unmounting it first), so addons' menu changes can fail (\"Device or resource busy\")"
	fi
	say ""
	say "The page's files"
	d=$(web_dir)
	if [ -d "$d" ]; then
		ww=$( { ls -ld "$d"; ls -l "$d" | grep -v '^total'; } | cut -c9 | grep -c w)
		if [ "$ww" -gt 0 ]; then
			[ "$DR_FX" = 1 ] && { chmod 755 "$d"; chmod 644 "$d"/* 2>/dev/null; }
			dr_fix "$ww of them (or their folder) can be changed by any program on the router, not only root"
		else dr_ok "only root can change them"; fi
		if [ -f "$d/clist.htm" ] && ! sampler_running; then
			[ "$DR_FX" = 1 ] && rm -f "$d/clist.htm"
			dr_fix "a copy of the router's client list from a rename is still there (it's only needed while the page is open)"
		fi
	else dr_info "none yet: they appear when the page is opened"; fi
	say ""
	say "Sampling"
	if sampler_running; then dr_info "running (a page is open)"
	else
		n=0; ps=""
		for q in /proc/[0-9]*; do   # a page's node session (its own -K 10 -I 30 ... and the node script) with no page open
			c=$(tr '\000' ' ' 2>/dev/null < "$q/cmdline")
			case "$c" in *dbclient*" -K 10 -I 30 "*"$NODE_MARK"*|*dbclient*" -K 10 -I 30 "*" sh -s ") n=$((n + 1)); ps="$ps ${q#/proc/}" ;; esac
		done
		if [ $n -gt 0 ]; then [ "$DR_FX" = 1 ] && kill $ps 2>/dev/null; dr_fix "$n node session(s) still running with no page open"
		else dr_ok "not running, nothing left running (it runs only while the page is open)"; fi
	fi
	paused_recently && dr_info "paused in the last 2 minutes: the router was busy ('$SCRIPT status' says why)"
	dr_lock
	say ""
	say "The page's requests"
	if [ -f "$SCRIPT" ]; then dr_request; else dr_info "not tested: Arteria isn't installed"; fi
	say ""
	say "AiMesh nodes"
	list=$(node_list)
	if [ "$NODES" != on ]; then dr_info "reading nodes is off (NODES=off)"
	elif [ -z "$list" ]; then dr_info "none found"
	elif [ -z "$(node_keys)" ]; then dr_warn "no key to read them with: run '$SCRIPT nodekey'"
	else
		# the same check as 'nodes test': one round of the page's own node script; traced when something crashes there
		i=0; : > "$TMPD/node-trace.txt"
		printf '%s\n' "$list" > "$TMPD/doctor.nodes"
		while read -r mac ip model; do
			i=$((i + 1)); nm="node $i ($model)"
			import_pin "$ip"; node_try "$ip"; rc=$?
			if [ $rc -eq 2 ]; then dr_info "$nm: can't be tested from here ($TRY_ERR)"; continue; fi
			if [ $rc -ne 0 ]; then dr_warn "$nm: key login doesn't work${TRY_ERR:+ ($(printf '%s' "$TRY_ERR" | scrub))}: run '$SCRIPT nodes test'"; continue; fi
			rm -f "$TMPD/trace.n"
			node_probe "$ip" "$TMPD/trace.n"; rc=$?
			if [ "$PROBE_CRASH" = 1 ]; then
				dr_warn "$nm: something crashed on the node running Arteria's script${TRACE_AT:+, at: $TRACE_AT}"
			elif [ $rc -eq 0 ]; then
				case "$PROBE_MSG" in *too\ slow*) dr_warn "$nm: key login works, and Arteria's script $PROBE_MSG" ;;
					*) if [ "$WHY_BAD" = 1 ]; then dr_warn "$nm: key login works, but Arteria's script $PROBE_MSG: its devices are on an interface it took for the uplink. Please post this line"
					else dr_ok "$nm: key login works, and Arteria's script $PROBE_MSG"; fi ;; esac
			else dr_warn "$nm: key login works, but Arteria's script failed there: ${PROBE_MSG#reading its devices failed: }"; fi
			[ -s "$TMPD/trace.n" ] && { echo "== $nm"; cat "$TMPD/trace.n"; } >> "$TMPD/node-trace.txt"
			rm -f "$TMPD/trace.n"
		done < "$TMPD/doctor.nodes"
		rm -f "$TMPD/doctor.nodes"
		[ -s "$TMPD/node-trace.txt" ] && dr_info "what crashed and what ran before it: $TMPD/node-trace.txt (no addresses), for a bug report" || rm -f "$TMPD/node-trace.txt"
	fi
	say ""
	if [ $DR_D -gt 0 ]; then say "Fixed $DR_D problem(s)."; fi
	if [ $DR_F -gt 0 ]; then say "Run '$SCRIPT doctor fix' to fix the [FIX] lines."; fi
	if [ $DR_W -gt 0 ]; then say "The [WARN] lines need you, or a bug report: post them, with '$SCRIPT debug', in the forum thread."; fi
	[ $DR_F -eq 0 ] && [ $DR_W -eq 0 ] && [ $DR_D -eq 0 ] && say "Nothing wrong found."
	[ $DR_F -eq 0 ]   # 1: something 'doctor fix' would fix
}

# Everything a bug report needs, and nothing personal: no device names, no MAC or IP addresses.
debug() {
	say "$(ver_line)"
	say "Router:      $(nvram get productid) $(nvram get odmpid)  firmware $(fw_version)  $(uname -m)"
	say "BusyBox:     $(busybox 2>/dev/null | head -1 | cut -d' ' -f2)   dbclient: $(have dbclient && echo yes || echo no)   dropbearkey: $(have dropbearkey && echo yes || echo no)"
	say "Settings:    INTERVAL=$INTERVAL IDLE_STOP=$IDLE_STOP NODES=$NODES amtm=$AMTM_UPDATE"
	CPUS=$(cpu_count); health
	say "Health:      load $LOAD on $CPUS cores, $MEMMB MB available (level $HEALTH)$( [ -f "$PAUSED" ] && read -r pt pw pl < "$PAUSED" && printf ', last pause: %s, %s s ago' "$pw" "$(( $(now) - pt ))")"
	say "WAN:         $(wan_if) ($(nvram get wan0_proto))$(w2=$(wan2_if); [ -n "$w2" ] && printf ', second WAN: %s (%s, %s)' "$w2" "$(nvram get wan1_proto)" "$(nvram get wans_mode)")"
	# each Wi-Fi interface: its radio's band setting and the band of the channel it is on, its mode, its bridge, whether its
	# network is a main one (by name, never shown), its clients. A network name only as "main" or "other".
	mains=" "; for u in 0 1 2 3; do [ -n "$(nvram get wl${u}_ifname)" ] && mains="$mains$(nvram get wl${u}_ssid | tr -d ' ')|"; done
	for u in 0 1 2 3; do
		f=$(nvram get wl${u}_ifname); [ -n "$f" ] || continue
		case "$(nvram get wl${u}_nband)" in 2) b=2.4 ;; 1) b=5 ;; 4) b=6 ;; *) b=? ;; esac
		for x in $f $(nvram get wl${u}_vifs); do
			if [ "$x" = "$f" ]; then n="main"; md=$(nvram get wl${u}_mode); else n=$(nvram get "${x}_ssid" | tr -d ' '); case "$mains" in *"|$n|"*|*" $n|"*) n="main" ;; *) n="other" ;; esac; md=$(nvram get "${x}_mode"); fi
			cs=$(wl -i "$x" chanspec 2>/dev/null | cut -d' ' -f1)
			br=$(readlink "$SYSNET/$x/master" 2>/dev/null); br=${br##*/}
			say "Wi-Fi:       $x radio $u ($b GHz), channel ${cs:-?}, mode ${md:-ap}, bridge ${br:-none}, $n network, up=$(wl -i "$x" isup 2>/dev/null), clients=$(wl -i "$x" assoclist 2>/dev/null | wc -l | tr -d ' ')"
		done
	done
	for p in $(lan_ports); do
		say "Port:        $p carrier=$(cat "$SYSNET/$p/carrier" 2>/dev/null) speed=$(cat "$SYSNET/$p/speed" 2>/dev/null)"
	done
	pt=$(port_table | awk '{ printf "%sLAN %s %s %s %s", (c++ ? ", " : ""), $2, $1, ($3 ? "up" : "down"), $4 }')
	say "Port map:    ${pt:-none from the firmware}   (lan_ifnames: $(nvram get lan_ifnames))"
	say "WDS links:   $(grep -c '^ *wds' "$PROC/net/dev")"
	nl=$(node_list)
	say "Nodes:       $(printf '%s\n' "$nl" | grep -c .) $(printf '%s\n' "$nl" | awk '{ printf "%s%s", (c++ ? "," : ""), $3 }')   ssh port: $(ssh_port)   sshd_enable: $(nvram get sshd_enable)"
	[ -n "$nl" ] && say "Node keys:   $(for k in $(node_keys); do printf '%s; ' "$(key_name "$k")"; done | sed 's/; $//')"
	printf '%s\n' "$nl" | while read -r mac ip model; do
		[ -n "$mac" ] || continue
		f=$(node_file "$mac"); x=""
		if sampler_running; then
			st=$(node_state "$f")
			[ -f "$f.out" ] && x=", a round every $(node_period "$f") s, last output $(( $(now) - $(date -r "$f.out" +%s) )) s ago, $(cat "$f.last" "$f.out" 2>/dev/null | awk "$NODE_AWK" | grep -o '\["[A-Za-z0-9.]*","[0-9.]*","[0-9A-F:]\{17\}"' | wc -l | tr -d ' ') station(s)"
		else st="(page closed)"; fi
		say "  $model: backhaul stations=$(node_stas "$mac" | wc -w | tr -d ' ') state=$st$x"
		e=$(tail -c 2048 "$f.err" 2>/dev/null | tr -cd '\012\040-\176' | grep . | tail -1 | scrub | cut -c1-120)
		[ -n "$e" ] && say "    last SSH message: $e"
		# its Wi-Fi backhaul as the router sees it: band, signal, the rates of the last packets each way, idle time
		for m in $(node_stas "$mac"); do
			for p in $(radio_list); do
				x=${p%%:*}
				wl -i "$x" assoclist 2>/dev/null | grep -qi "$m" || continue
				{ echo "@ $x ${p#*:} $m"; wl -i "$x" sta_info "$m" 2>/dev/null; } | awk "$STA_AWK" | awk '{ printf "    backhaul: %s GHz on %s, %s dBm, last packets %d/%d Mb/s, idle %s s, %s %s streams %s MHz\n", $3, $2, $7, $8 / 1000, $9 / 1000, $11, $12, $13, $14 }'
			done
		done
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
	live="$(web_dir)/live.htm"
	[ -f "$live" ] && say "Last sample: $(sed -n 's/.*"ms":\([0-9]*\).*/\1/p' "$live" | head -1) ms, $(( $(now) - $(date -r "$live" +%s) )) s ago"
	# what the router's AiMesh client list has for each node (its sections' names only): a node's wired devices, if it lists them
	ours_file "$ROOT/tmp/clientlist.json" && say "Client list: $(tr -d '\n' < "$ROOT/tmp/clientlist.json" | grep -o '"[A-Za-z0-9_]\{1,16\}":{' | tr -d '":{' | grep -v '^[0-9A-Fa-f]*$' | sort | uniq -c | awk '{ printf "%s%sx%s", (c++ ? " " : ""), $2, $1 }')"
	# the page's requests: service-event lines that wait, the sampler's last errors, and the system log's lines about them
	say "Hook:        line $(grep -n "# $NAME\$" "$SCRIPTS_DIR/service-event" 2>/dev/null | cut -d: -f1 | tr '\n' ' ')of service-event, $(hook_waiters | grep -c .) other line(s) there wait for their program"
	e=$(grep . "$TMPD/sampler.err" 2>/dev/null | tail -n 3 | scrub | tr -cd '\012\040-\176' | cut -c1-140)
	[ -n "$e" ] && { say "Sampler errors:"; printf '%s\n' "$e" | sed 's/^/  /'; }
	l=$(log_requests 12)
	[ -n "$l" ] && { say "System log (the page's requests):"; printf '%s\n' "$l" | sed 's/^/  /'; }
	return 0
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
	( AR_AMTM=1 update ) > "$alog" 2>&1; rc=$?
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
	say "       nodes [test] | nodekey [node-ip | print] | doctor [fix] | debug | sample | amtmupdate [check] | startup | version"
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
		say "  d  Doctor: look for known problems, and fix them"
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
				before=$(md5sum 2>/dev/null < "$SCRIPT")
				if [ "$opt" = 8 ]; then
					say " Development versions are unreleased and can be broken. Option 4 goes back to the latest release."
					printf ' Branch (Enter for main, e to go back): '; read -r br || br=e
					case "$br" in e|E) continue ;; esac
					( update_dev "${br:-main}" )
				elif [ "$opt" = 5 ]; then ( update force ); else ( update ); fi
				menu_pause
				# the update replaced this script: carry on in the new one
				[ -f "$SCRIPT" ] && [ "$(md5sum 2>/dev/null < "$SCRIPT")" != "$before" ] && exec sh "$SCRIPT" menu ;;
			6) ( debug ); menu_pause ;;
			d|D)
				if ! ( doctor ); then
					printf '\n Fix the [FIX] lines now? (y/n) '; read -r a || a=n
					case "$a" in [yY]*) say ""; ( doctor fix ) ;; esac
				fi
				menu_pause ;;
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
	status)        status ;;
	debug)         debug ;;
	doctor)        doctor "$2"; exit $? ;;
	version)       say "$VERSION" ;;
	amtmupdate)    amtm_update "$2"; exit $? ;;
	*)             usage ;;
esac
