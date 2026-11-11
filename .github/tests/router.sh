#!/bin/bash
# Arteria on a stand-in router.
#
# Runs arteria.sh with only Merlin's BusyBox commands on PATH (merlin-applets.txt), with [, printf
# and echo as separate programs like on the router, and stand-ins for nvram, wl, brctl and dbclient.
# The router has two radios, a NAS on its 2.5G port and one AiMesh node; the node is emulated too:
# the stand-in dbclient runs the script Arteria sends to nodes, against the node's own stand-in wl.
#
#  1. "sample" prints one valid sample: internet, ports, Wi-Fi clients, the node and its backhaul.
#  2. The page's request (service-event "start arteria") starts the sampler; it reads the node's
#     clients over the session, writes live.htm and names.htm, and stops when the page says so.
#  3. Without the node key, the node is reported as "nokey" and never retried in a loop.
#  4. A stale pid file never makes Arteria signal another process, or keeps the sampler from starting.
#  5. install hooks itself in and adds its menu line before Traffic Monitor (Merlin has it in two menus); uninstall
#     removes everything it added and nothing else.
#
# Usage: .github/tests/router.sh [path/to/arteria.sh]   (needs busybox, python3)
set -eu
here=$(cd "$(dirname "$0")" && pwd)
script=${1:-$here/../../arteria.sh}
case "$script" in /*) ;; *) script=$PWD/$script ;; esac
asp=$(dirname "$script")/arteria.asp
bb=$(command -v busybox) || { echo "::error::router.sh needs busybox installed"; exit 1; }
bash_bin=$(command -v bash)
t=$(mktemp -d); trap 'pkill -f "$t/" 2>/dev/null || true; rm -rf "$t"' EXIT
R=$t/root; F=$t/fix; B=$t/bin; N=$t/node-bin
mkdir -p "$R/jffs/addons" "$R/jffs/scripts" "$R/www/user" "$R/www/require/modules" "$R/tmp" "$R/usr/sbin" "$R/var/lib/misc" "$F" "$B" "$N" "$t/proc/net"
fail=0
ok()  { echo "ok    $*"; }
bad() { echo "FAIL  $*"; fail=1; }

# ---- Merlin's BusyBox commands, and nothing else ---------------------------------------------
"$bb" --list > "$t/bb.list"
grep -v '^#' "$here/merlin-applets.txt" | while IFS= read -r a; do
	[ -n "$a" ] || continue
	if grep -qxF -- "$a" "$t/bb.list"; then ln -s "$bb" "$B/$a"
	elif p=$(command -v -- "$a"); then ln -s "$p" "$B/$a"   # e.g. flock: Merlin has it, Debian's BusyBox doesn't
	fi
done
for a in logger mount umount uname; do rm -f "$B/$a"; done
printf '#!%s sh\nshift 2; echo "$*" >> "%s/syslog"\n' "$bb" "$t" > "$B/logger"
printf '#!%s sh\nexit 0\n' "$bb" > "$B/mount"; cp "$B/mount" "$B/umount"
printf '#!%s sh\n[ "$1" = -o ] && echo ASUSWRT-Merlin || echo Linux\n' "$bb" > "$B/uname"

# ---- the router ------------------------------------------------------------------------------
NODE=02:10:00:00:00:80; S2=02:10:00:00:00:81; S5=02:10:00:00:00:84
cat > "$B/nvram" <<EOF
#!$bb sh
[ "\$1" = get ] || exit 0
case "\$2" in
	productid) echo RT-AX86U ;; buildno) echo 388.13 ;; extendno) echo 0 ;; firmver) echo 3.0.0.4 ;;
	wl0_ifname) echo eth6 ;; wl1_ifname) echo eth7 ;; wl0_nband) echo 2 ;; wl1_nband) echo 1 ;;
	lan_ifnames) echo "eth4 eth3 eth2 eth1 eth5 eth6 eth7" ;; wan0_gw_ifname|wan0_ifname) echo eth0 ;; wan0_proto) echo dhcp ;;
	lan_ipaddr) echo 192.168.50.1 ;; http_username) echo admin ;; sshd_port) echo 2222 ;; sshd_enable) echo 1 ;;
	jffs2_scripts) echo 1 ;; rc_support) echo "mssid 2.4G 5G usbX1 bwdpi wl6 amas" ;;
	cfg_device_list) echo "<RP-AX56>192.168.50.10>$NODE>0" ;;
	custom_clientlist) echo "<Living room TV>02:CC:00:00:00:05>0>23>><Kids \"tablet\"\\\\>02:CC:00:00:00:13>0>21>>" ;;
esac
EOF
# Wi-Fi clients: counters grow with the clock, so two samples differ
cat > "$F/assoc" <<EOF
eth6 02:CC:00:00:00:01 5000000 40000
eth6 02:CC:00:00:00:02 2000 3000
eth6 $S2 20000 1000
eth7 02:CC:00:00:00:03 12000000 700000
eth7 02:CC:00:00:00:04 1500000 120000
eth7 $S5 6000000 400000
EOF
cat > "$B/wl" <<EOF
#!$bb sh
[ "\$1" = -i ] && { ifc=\$2; shift 2; }
case "\$1" in
	isup) echo 1 ;;
	assoclist) awk -v i="\$ifc" '\$1 == i { print "assoclist", \$2 }' "$F/assoc" ;;
	sta_info)
		awk -v i="\$ifc" -v m="\$2" -v now="\$(date +%s)" '\$1 == i && \$2 == m {
			printf "[VER 8] STA %s:\n\t aid:3\n\t idle 2 seconds\n\t in network 4100 seconds\n", m
			printf "\t tx total pkts: 1\n\t tx total bytes: %.0f\n\t rx data pkts: 1\n\t rx data bytes: %.0f\n", 9000000000 + \$3 * (now % 100000), 1000000000 + \$4 * (now % 100000)
			printf "\t rate of last tx pkt: 864000 kbps - 1000 kbps\n\t rate of last rx pkt: 650000 kbps\nsmoothed rssi: -58\n" }' "$F/assoc" ;;
	*) exit 1 ;;
esac
EOF
cat > "$B/brctl" <<EOF
#!$bb sh
case "\$1" in
	showstp) printf 'br0\n bridge id\neth1 (4)\n port id\neth5 (5)\neth6 (6)\neth7 (7)\nwds1.0.1 (9)\n' ;;
	showmacs) printf 'port no\tmac addr\t\tis local?\tageing timer\n  5\t02:cc:00:00:00:09\tno\t\t   0.11\n  9\t02:cc:00:00:00:11\tno\t\t   0.20\n  6\t24:4b:fe:00:00:20\tyes\t\t   0.00\n' ;;
esac
EOF
cat > "$t/proc/net/dev" <<'EOF'
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
  eth0: 29125544074 24245912 0 994 0 0 0 816 7883399323 10409911 0 0 0 0 0 0
  eth1: 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
  eth5: 78941131 419678 0 0 0 0 0 2655 466104548 652685 0 0 0 0 0 0
  eth6: 36927904 221172 0 0 0 637609 0 0 63250738 306987 445 0 0 0 0 0
  eth7: 3774351766 4653250 0 21 0 0 0 27194 14871487368 12052532 0 3262 0 0 0 0
wds1.0.1: 962647865 2228803 0 5159 0 0 0 45379 9796037641 8283991 0 0 0 0 0 0
    br0: 4630432670 7044139 0 0 0 0 0 0 24640308964 20233741 0 0 0 0 0 0
EOF
echo "25588.76 90000.00" > "$t/proc/uptime"; echo "1.39 1.28 1.27 3/216 4894" > "$t/proc/loadavg"
for i in eth0 eth1 eth2 eth3 eth4 eth5 eth6 eth7 br0; do mkdir -p "$t/sys/class/net/$i"; done
echo 24:4b:fe:00:00:20 > "$t/sys/class/net/br0/address"; echo 24:4b:fe:00:00:24 > "$t/sys/class/net/eth7/address"
echo 24:4b:fe:00:00:20 > "$t/sys/class/net/eth6/address"
for i in eth0 eth5; do echo 1 > "$t/sys/class/net/$i/carrier"; done
for i in eth1 eth2 eth3 eth4; do echo 0 > "$t/sys/class/net/$i/carrier"; echo -1 > "$t/sys/class/net/$i/speed"; done
echo 1000 > "$t/sys/class/net/eth0/speed"; echo 2500 > "$t/sys/class/net/eth5/speed"
printf '{"%s":{"sta2g":"%s","sta5g":"%s","sta6g":""}}' "$NODE" "$S2" "$S5" > "$R/tmp/relist.json"
printf '{"misc":{"cfg_alias":"Hall"}}' > "$R/tmp/$NODE.json"
printf '{"%s":{"2G":{"02:CC:00:00:00:11":{"ip":"192.168.50.4","rssi":"-49"}}}}' "$NODE" > "$R/tmp/clientlist.json"
printf '{"02:CC:00:00:00:03":{"mac":"02:CC:00:00:00:03","name":"Client","vendor":"Apple","type":0}}' > "$R/jffs/nmp_cl_json.js"
printf '1794400000 02:cc:00:00:00:04 192.168.50.20 Pixel-8 *\n' > "$R/var/lib/misc/dnsmasq.leases"
printf 'am_settings_get() { :; }\n' > "$R/usr/sbin/helper.sh"
# Laid out like Merlin 3004.388's menuTree.js: Traffic Monitor is in two menus (Traffic Manager for
# models without Trend Micro's engine, Traffic Analyzer for those with it; only one is shown), plus Tools.
cat > "$R/www/require/modules/menuTree.js" <<'EOF'
var menuTree = { list: [
			{
				menuName: "<#Menu_TrafficManager#>",
				index: "menu_QoS",
				tab: [
					{url: "QoS_EZQoS.asp", tabName: "<#menu5_3_2#>"},
					{url: "Main_TrafficMonitor_realtime.asp", tabName: "<#traffic_monitor#>"},
					{url: "Main_TrafficMonitor_last24.asp", tabName: "__INHERIT__"},
				]
			},
			{
				menuName: "<#Traffic_Analyzer#>",
				index: "menu_TrafficAnalyzer",
				tab: [
					{url: "TrafficAnalyzer_Statistic.asp", tabName: "<#Statistic#>"},
					{url: "Main_TrafficMonitor_realtime.asp", tabName: "<#traffic_monitor#>"},
					{url: "Main_TrafficMonitor_last24.asp", tabName: "__INHERIT__"},
				]
			},
			{
				menuName: "<#Menu_usb_application#>",
				index: "menu_Tools",
				tab: [
					{url: "Tools_OtherSettings.asp", tabName: "Other Settings"},
				]
			}
		],
		exclude: { menus: function () { var retArray = []; retArray.push("Main_TrafficMonitor_realtime.asp"); return retArray; } }
};
EOF

# ---- the node: its own nvram and wl, reached through a stand-in dbclient ----------------------------
cat > "$N/nvram" <<EOF
#!$bb sh
case "\$2" in wl0_ifname) echo eth1 ;; wl1_ifname) echo eth2 ;; wl0_vifs) echo wl0.1 ;; wl1_vifs) echo wl1.1 ;; wl0_nband) echo 2 ;; wl1_nband) echo 1 ;; esac
EOF
cat > "$F/node-assoc" <<'EOF'
eth1 24:4B:FE:00:00:20 1000 2000
eth2 24:4B:FE:00:00:24 3000 4000
wl0.1 02:CC:00:00:00:11 4000 1000
wl1.1 02:CC:00:00:00:12 5000000 60000
wl1.1 02:CC:00:00:00:13 800000 90000
EOF
sed "s#$F/assoc#$F/node-assoc#" "$B/wl" > "$N/wl"
cat > "$B/dbclient" <<EOF
#!$bb sh
# a node that accepts only the router's Arteria key
[ "\$1 \$2" = "-o help" ] && { printf 'Available options:\\n\\tBatchMode\\n\\tPort\\n' >&2; exit 0; }
echo "\$*" >> "$t/dbclient.args"
key=""; while [ \$# -gt 1 ]; do [ "\$1" = -i ] && key=\$2; shift; done
[ -n "\$key" ] && [ -s "\$key" ] || { echo "dbclient: Connection to admin@192.168.50.10:2222 exited: No auth methods could be used." >&2; exit 1; }
echo "\$1" >> "$t/dbclient.cmds"
case "\$1" in 'sh -s') exec env PATH="$N:$B" "$bb" sh -s ;; *) exec env PATH="$N:$B" "$bb" sh -c "\$1" ;; esac
EOF
printf '#!%s sh\nf=""; while [ $# -gt 0 ]; do [ "$1" = -f ] && f=$2; shift; done\n[ -n "$f" ] && printf "key\\n" > "$f"\necho "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITEST admin@router"\n' "$bb" > "$B/dropbearkey"
for f in "$B"/* "$N"/*; do [ -L "$f" ] || chmod +x "$f"; done   # the stand-ins; never the symlinked system tools

echo 'enable -n test [ printf echo' > "$t/no-builtins.sh"
run()  { AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" BASH_ENV="$t/no-builtins.sh" "$bash_bin" "$script" "$@"; }
runa() { AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$bb" ash "$script" "$@"; }

# ---- 1: one sample --------------------------------------------------------------------------
mkdir -p "$R/jffs/addons/arteria"
runa sample > "$t/sample.json" 2> "$t/sample.err" || true
[ -s "$t/sample.err" ] && { bad "'sample' printed errors:"; cat "$t/sample.err"; }
run sample > "$t/sample2.json" 2> "$t/sample2.err" || true
[ -s "$t/sample2.err" ] && { bad "'sample' printed errors under bash without builtins:"; cat "$t/sample2.err"; }
python3 - "$t/sample.json" <<'EOF' && ok "sample: internet, ports, Wi-Fi clients, node and backhaul" || fail=1
import json, sys
s = json.load(open(sys.argv[1]))
assert s['wan'] == 'eth0', s['wan']
assert s['ports'] == ['eth4', 'eth3', 'eth2', 'eth1', 'eth5'], s['ports']
ifs = {r[0]: r for r in s['ifs']}
assert ifs['eth0'][1] == '29125544074' and ifs['eth0'][2] == '7883399323', ifs['eth0']
assert 'wds1.0.1' in ifs and 'eth5' in ifs and 'br0' not in ifs
sta = {r[2]: r for r in s['sta']}
assert len(sta) == 6, sta
r = sta['02:CC:00:00:00:03']
assert r[0] == 'eth7' and r[1] == '5' and r[5] == -58 and r[6] == 864 and r[7] == 650 and r[8] == 4100 and r[9] == 2, r
assert r[3].isdigit() and int(r[3]) > 9000000000, r   # big counters stay exact strings
links = {l[0]: l for l in s['links']}
assert links['eth5'] == ['eth5', 1, 2500] and links['eth1'] == ['eth1', 0, -1] and links['eth0'][2] == 1000, links
assert s['macs'] == [['eth5', '02:CC:00:00:00:09']], s['macs']
n = s['nodes'][0]
assert n['mac'] == '02:10:00:00:00:80' and n['ip'] == '192.168.50.10' and n['model'] == 'RP-AX56' and n['alias'] == 'Hall', n
assert n['sta'].split() == ['02:10:00:00:00:81', '02:10:00:00:00:84'], n['sta']
assert n['state'] == 'nokey' and n['c'] == [], n
assert '24:4B:FE:00:00:20' in s['own']
assert s['router']['model'] == 'RT-AX86U' and s['router']['fw'] == '3004.388.13_0', s['router']
EOF
cmp -s "$t/sample.json" "$t/sample2.json" || python3 -c "
import json,sys; a=json.load(open('$t/sample.json')); b=json.load(open('$t/sample2.json'))
for k in ('epoch','sta','up'): a.pop(k,None); b.pop(k,None)
sys.exit(0 if a==b else 1)" && ok "ash and bash-without-builtins agree" || bad "ash and bash give different samples"

# ---- 3 first: no key, no retry loop ---------------------------------------------------------------
W=$R/www/user/arteria
cp "$script" "$R/jffs/addons/arteria/arteria.sh"; cp "$asp" "$R/jffs/addons/arteria/arteria.asp"
printf 'INTERVAL=1\nIDLE_STOP=10\n' > "$R/jffs/addons/arteria/config"
inst="$R/jffs/addons/arteria/arteria.sh"
runi() { AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$bb" ash "$inst" "$@"; }
runi service_event start arteria
sleep 5
python3 - "$W/live.htm" <<'EOF' && ok "without the key: node is 'nokey', its clients aren't read" || fail=1
import json, sys
s = json.load(open(sys.argv[1]))
n = s['nodes'][0]
assert n['state'] == 'nokey' and n['c'] == [], n
assert s['seq'] >= 2, s['seq']
EOF
tries=$(grep -c 'No auth' "$R/tmp/arteria/"node.*.err 2>/dev/null || echo 0)
[ "$tries" -le 1 ] && ok "a refused key is tried once, not in a loop ($tries)" || bad "the node was asked $tries times"
runi service_event start arteriastop
sleep 3
[ -f "$R/tmp/arteria/sampler.pid" ] && bad "sampler still running after the page closed" || ok "sampler stops when the page closes"

# ---- 2: with the key: the node's clients over the session ------------------------------------------
printf 'key\n' > "$R/jffs/addons/arteria/node_key"
runi service_event start arteria
sleep 6
python3 - "$W/live.htm" "$W/names.htm" <<'EOF' && ok "sampler: node clients read over SSH, names exported" || fail=1
import json, sys
s = json.load(open(sys.argv[1]))
n = s['nodes'][0]
assert n['state'] == 'ok', n
c = {r[2]: r for r in n['c']}
assert set(c) >= {'02:CC:00:00:00:11', '02:CC:00:00:00:12', '02:CC:00:00:00:13'}, c
assert c['02:CC:00:00:00:12'][0] == 'wl1.1' and c['02:CC:00:00:00:12'][1] == '5', c
assert c['02:CC:00:00:00:11'][1] == '2.4', c
assert float(n['up']) > 0, n['up']
names = json.load(open(sys.argv[2]))
assert 'Living room TV>02:CC:00:00:00:05' in names['custom'], names['custom']
assert 'Kids "tablet"\\' in names['custom'], names['custom']
assert 'Pixel-8' in names['leases'], names['leases']
assert names['nmp']['02:CC:00:00:00:03']['vendor'] == 'Apple'
assert '02:10:00:00:00:80' in names['cl']
EOF
grep -q '<' "$W/live.htm" "$W/names.htm" && bad "a raw '<' reached the page's data (httpd would run it as a template)" || ok "no raw '<' in the data files"
[ "$(grep -c "sh -s" "$t/dbclient.cmds" 2>/dev/null || echo 0)" = 1 ] && ok "one SSH session per node" || bad "SSH sessions: $(grep -c 'sh -s' "$t/dbclient.cmds" 2>/dev/null)"
grep -q -- "-p 2222 .*admin@192.168.50.10 sh -s" "$t/dbclient.args" && ok "the session uses the router's SSH port and admin name" || { bad "SSH arguments:"; cat "$t/dbclient.args"; }
grep -- " -i " "$t/dbclient.args" | grep -qv -- "-o BatchMode=yes" && { bad "a key login without BatchMode (dbclient could ask for a password):"; cat "$t/dbclient.args"; } || ok "key logins never offer a password (BatchMode)"
runi service_event start arteriastop
sleep 3
pgrep -f "$N" > /dev/null 2>&1 && bad "the node session outlived the page" || ok "node session ends with the sampler"
rm -rf "$R/tmp/arteria" "$W"

# nodekey print: one line to paste on a node, which adds the key once and keeps the keys already there
line=$(run nodekey print 2>&1 | grep "^k='ssh-")
mkdir -p "$t/nk"; printf 'ssh-ed25519 AAAAown me@laptop' > "$t/nk/store"
printf '#!%s sh\ncase "$1" in get) cat "%s/nk/store" ;; set) printf "%%s" "${2#sshd_authkeys=}" > "%s/nk/store" ;; esac\n' "$bb" "$t" "$t" > "$t/nk/nvram"
printf '#!%s sh\nexit 0\n' "$bb" > "$t/nk/service"; chmod +x "$t/nk/nvram" "$t/nk/service"
if [ -n "$line" ] && PATH="$t/nk:$B" "$bb" sh -c "$line" > /dev/null && PATH="$t/nk:$B" "$bb" sh -c "$line" | grep -q 'already has' \
	&& [ "$(grep -c '' "$t/nk/store")" = 2 ] && grep -q '^ssh-ed25519 AAAAown me@laptop$' "$t/nk/store" && grep -q 'AAAAC3NzaC1lZDI1NTE5AAAAITEST arteria$' "$t/nk/store"; then
	ok "nodekey print: a one-line command that adds the key once and keeps the node's own keys"
else bad "nodekey print:"; printf '%s\n' "$line"; cat "$t/nk/store"; fi

# ---- 3: stale pid files never touch someone else's process ----------------------------------------
# The router reuses pids within minutes. A pid file left behind (a sampler or node session that was
# killed) may by then name an unrelated process: it must neither be signalled nor block the sampler.
sleep 300 & other=$!
mkdir -p "$R/tmp/arteria"; echo "$other" > "$R/tmp/arteria/sampler.pid"
runi service_event start arteria
sleep 4
[ "$(cat "$R/tmp/arteria/sampler.pid" 2>/dev/null)" != "$other" ] && [ -f "$R/tmp/arteria/sampler.pid" ] \
	&& ok "a stale sampler pid file doesn't keep the sampler from starting" || bad "the sampler didn't start over a stale pid file"
runi service_event start arteriastop
sleep 3
echo "$other" > "$R/tmp/arteria/sampler.pid"; echo "$other" > "$R/tmp/arteria/node.021000000080.pid"
runi startup > /dev/null 2>&1   # stops the sampler and node sessions, as an update or uninstall does
kill -0 "$other" 2>/dev/null && ok "stale pid files never signal another process" || bad "Arteria killed a process that wasn't its own"
kill "$other" 2>/dev/null; wait "$other" 2>/dev/null || true
rm -rf "$R/tmp/arteria" "$W" "$R/tmp/menuTree.js" "$R/jffs/addons/arteria/webui_page" "$R"/www/user/user*

# ---- 4: install and uninstall ----------------------------------------------------------------
printf '#!/bin/sh\n/some/other/script startup &\n' > "$R/jffs/scripts/services-start"
cp "$R/jffs/scripts/services-start" "$t/ss.before"
cp "$R/www/require/modules/menuTree.js" "$t/menu.before"
AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$bb" ash "$script" install < /dev/null > "$t/install.out" 2>&1 || { bad "install failed:"; cat "$t/install.out"; }
page=$(cat "$R/jffs/addons/arteria/webui_page" 2>/dev/null || echo none)
[ "$page" = user1.asp ] && [ -f "$R/www/user/user1.asp" ] && ok "install mounts the page in the first free slot" || bad "page slot: $page"
grep -q 'arteria-version: ' "$R/www/user/user1.asp" && ok "mounted page is Arteria's" || bad "mounted page isn't arteria.asp"
m="$R/tmp/menuTree.js"
# exactly two new lines, each right before a Traffic Monitor tab (in the menu that's shown, and the other)
if [ "$(grep -c 'tabName: "Arteria"' "$m")" = 2 ] && [ "$(wc -l < "$m")" -eq $(( $(wc -l < "$t/menu.before") + 2 )) ] \
	&& awk '/tabName: "Arteria"/ { a = 1; next } a { if ($0 !~ /url: "Main_TrafficMonitor_realtime.asp"/) bad = 1; a = 0 } END { exit bad }' "$m"; then
	ok "menu: Arteria right before Traffic Monitor, in both menus that have it"
else bad "menu:"; cat "$m"; fi
grep -q 'Traffic Analyzer -> Arteria' "$t/install.out" && ok "install points to Traffic Analyzer" || { bad "install output:"; cat "$t/install.out"; }
grep -q "arteria.sh startup & # arteria" "$R/jffs/scripts/services-start" && grep -q 'service_event "$@" & # arteria' "$R/jffs/scripts/service-event" && ok "hooks added" || bad "hooks missing"
grep -qi "key login works\|Node(s) without the key" "$t/install.out" && ok "install checks node access" || { bad "install didn't check the nodes:"; cat "$t/install.out"; }
AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$bb" ash "$R/jffs/addons/arteria/arteria.sh" uninstall > "$t/uninstall.out" 2>&1 || bad "uninstall failed"
[ ! -e "$R/jffs/addons/arteria" ] && [ ! -e "$R/www/user/user1.asp" ] && ok "uninstall removes the addon and its page" || bad "files left after uninstall"
cmp -s "$R/jffs/scripts/services-start" "$t/ss.before" && ok "other scripts' hook lines untouched" || { bad "services-start changed:"; cat "$R/jffs/scripts/services-start"; }
grep -q Arteria "$m" && bad "menu line left behind" || ok "menu line removed"

[ $fail -eq 0 ] && echo "Router: all checks passed." || { echo "::error::Router checks failed."; exit 1; }
