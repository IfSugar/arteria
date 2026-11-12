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
#  3. Without the node key, the node is reported as "nokey" and never retried in a loop. At a terminal,
#     nodekey keeps a node's pinned identity unless you say to trust a new one, and logs in once.
#  4. A stale pid file never makes Arteria signal another process, or keeps the sampler from starting.
#  5. install hooks itself in and adds its menu line right after Statistic in Traffic Analyzer (last in
#     Network Tools on routers without it); update and update dev install only a whole download of the
#     right version, from this repository's branches; uninstall removes everything it added and nothing else.
#
# Usage: .github/tests/router.sh [path/to/arteria.sh]   (needs busybox, python3; about 20 s)
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
# the router's own authorized SSH keys are kept in a file, so a test can see what Arteria adds and removes
[ "\$1" = set ] && case "\$2" in sshd_authkeys=*) printf '%s' "\${2#sshd_authkeys=}" > "$t/router-authkeys" ;; esac
[ "\$1" = get ] || exit 0
case "\$2" in
	sshd_authkeys) cat "$t/router-authkeys" 2>/dev/null ;;
	sshd_pass) cat "$t/sshd-pass" 2>/dev/null || echo 1 ;;   # Allow Password Login (a test turns it off)
	productid) echo RT-AX86U ;; buildno) echo 388.13 ;; extendno) echo 0 ;; firmver) echo 3.0.0.4 ;;
	wl0_ifname) echo eth6 ;; wl1_ifname) echo eth7 ;; wl0_nband) echo 2 ;; wl1_nband) echo 1 ;;
	lan_ifnames) echo "eth4 eth3 eth2 eth1 eth5 eth6 eth7" ;; wan0_gw_ifname|wan0_ifname) echo eth0 ;; wan0_proto) echo dhcp ;;
	lan_ipaddr) echo 192.168.50.1 ;; http_username) echo admin ;; sshd_port) echo 2222 ;; sshd_enable) echo 1 ;;
	jffs2_scripts) echo 1 ;; rc_support) echo "mssid 2.4G 5G usbX1 bwdpi wl6 amas" ;;
	# AiMesh's list of the nodes it's in touch with: saving a setting empties it for minutes (a test sets no-device-list)
	cfg_device_list) [ -f "$t/no-device-list" ] || echo "<RP-AX56>192.168.50.10>$NODE>0" ;;
	# every node that has joined (node, its 2.4 and 5 GHz backhaul addresses, when): kept across saves
	cfg_relist) echo "<$NODE>$S2>$S5>1761147712" ;;
	dhcp_staticlist) echo "<02:CC:00:00:00:04>192.168.50.20>>" ;;
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
			printf "\t rate of last tx pkt: 864000 kbps - 1000 kbps\n\t rate of last rx pkt: 650000 kbps\nsmoothed rssi: -58\n"
			if (m !~ /:13\$/) printf "\t flags 0x1e13b: WME N_CAP VHT_CAP HE_CAP AMPDU AMSDU\n\t OMI 0x0000: 20Mhz rx=1ss tx=1ss\n\t tx nrate\n\t he mcs 11 Nss 2 Tx Exp 0 bw80 ldpc 2xLTF GI 0.8us auto\n\t rx nrate\n\t he mcs 9 Nss 1 Tx Exp 0 bw80 ldpc\n\t link bandwidth = 80 MHZ\n" }' "$F/assoc" ;;
	*) exit 1 ;;
esac
EOF
cat > "$B/brctl" <<EOF
#!$bb sh
case "\$1" in
	showstp) printf 'br0\n bridge id\neth1 (4)\n port id\neth5 (5)\neth6 (6)\neth7 (7)\nwds1.0.1 (9)\n' ;;
	showmacs) printf 'port no\tmac addr\t\tis local?\tageing timer\n  5\t02:cc:00:00:00:09\tno\t\t   0.11\n  9\t02:cc:00:00:00:11\tno\t\t   0.20\n  6\t00:00:5e:00:53:fc\tyes\t\t   0.00\n' ;;
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
printf 'IP address       HW type     Flags       HW address            Mask     Device\n192.168.50.30    0x1         0x2         02:cc:00:00:00:01     *        br0\n192.168.50.31    0x1         0x0         00:00:00:00:00:00     *        br0\n' > "$t/proc/net/arp"
printf '#!%s sh\n[ "$1 $2 $3" = "-6 neigh show" ] && printf "2001:db8::12 lladdr 02:cc:00:00:00:12 REACHABLE\\nfe80::12 lladdr 02:cc:00:00:00:12 STALE\\n2001:db8::99 FAILED\\n"\n' "$bb" > "$B/ip"
echo "25588.76 90000.00" > "$t/proc/uptime"; echo "1.39 1.28 1.27 3/216 4894" > "$t/proc/loadavg"
for i in eth0 eth1 eth2 eth3 eth4 eth5 eth6 eth7 br0; do mkdir -p "$t/sys/class/net/$i"; done
echo 00:00:5e:00:53:fc > "$t/sys/class/net/br0/address"; echo 00:00:5e:00:53:fd > "$t/sys/class/net/eth7/address"
echo 00:00:5e:00:53:fc > "$t/sys/class/net/eth6/address"
for i in eth0 eth5; do echo 1 > "$t/sys/class/net/$i/carrier"; done
for i in eth1 eth2 eth3 eth4; do echo 0 > "$t/sys/class/net/$i/carrier"; echo -1 > "$t/sys/class/net/$i/speed"; done
echo 1000 > "$t/sys/class/net/eth0/speed"; echo 2500 > "$t/sys/class/net/eth5/speed"
printf '{"%s":{"sta2g":"%s","sta5g":"%s","sta6g":""}}' "$NODE" "$S2" "$S5" > "$R/tmp/relist.json"
printf '{"misc":{"cfg_alias":"Hall"}}' > "$R/tmp/$NODE.json"
printf '{"%s":{"2G":{"02:CC:00:00:00:11":{"ip":"192.168.50.4","rssi":"-49"}}}}' "$NODE" > "$R/tmp/clientlist.json"
printf '{"02:CC:00:00:00:03":{"mac":"02:CC:00:00:00:03","name":"Client","vendor":"Apple","type":0}}' > "$R/jffs/nmp_cl_json.js"
printf '1794400000 02:cc:00:00:00:04 192.168.50.20 Pixel-8 *\n' > "$R/var/lib/misc/dnsmasq.leases"
printf 'am_settings_get() { :; }\n' > "$R/usr/sbin/helper.sh"
# Laid out like the RT-AX86U's menuTree.js in Merlin 3004.388.13 (menuTree_bwdpi_traffic_analyzer.js):
# Traffic Monitor is a tab in two menus (Traffic Manager, hidden on this model, and Traffic Analyzer,
# where Statistic follows Traffic Monitor's hidden sub-pages), code elsewhere also builds Traffic
# Monitor tabs (never to be touched), and Network Tools ends with its "NULL" entry.
cat > "$R/www/require/modules/menuTree.js" <<'EOF'
define(function(){
	var menuTree = {
		list: [
			{
				menuName: "<#Menu_TrafficManager#>",
				index: "menu_QoS",
				tab: [
					{url: "QoS_EZQoS.asp", tabName: "<#menu5_3_2#>"},
					{url: "Main_TrafficMonitor_realtime.asp", tabName: "<#traffic_monitor#>"},
					{url: "Main_TrafficMonitor_last24.asp", tabName: "__INHERIT__"},
					{url: "Main_TrafficMonitor_daily.asp", tabName: "__INHERIT__"},
					{url: "AdaptiveQoS_InternetSpeed.asp", tabName: "<#InternetSpeed#>"},
				]
			},
			{
				menuName: "<#Traffic_Analyzer#>",
				index: "menu_TrafficAnalyzer",
				tab: [
					{url: "Main_TrafficMonitor_realtime.asp", tabName: "<#traffic_monitor#>"},
					{url: "Main_TrafficMonitor_last24.asp", tabName: "__INHERIT__"},
					{url: "Main_TrafficMonitor_daily.asp", tabName: "__INHERIT__"},
					{url: "Main_TrafficMonitor_monthly.asp", tabName: "__INHERIT__"},
					{url: "Main_TrafficMonitor_settings.asp", tabName: "__INHERIT__"},
					{url: "TrafficAnalyzer_Statistic.asp", tabName: "<#Statistic#>"},
					{url: "AdaptiveQoS_TrafficLimiter.asp", tabName: "Traffic Limiter"},
                                        {url: "NULL", tabName: "__INHERIT__"}
				]
			},
			{
				menuName: "<#menu5#>",
				index: "menu_Setting",
				tab: [
					{url: "Advanced_Privacy.asp", tabName: "<#menu_privacy#>"},
					{url: "Tools_OtherSettings.asp", tabName: "Tweaks"},
					{url: "NULL", tabName: "__INHERIT__"}
				]
			},
			{
				menuName: "<#Network_Tools#>",
				index: "menu_NekworkTool",
				tab: [
					{url: "Main_Analysis_Content.asp", tabName: "<#Network_Analysis#>"},
					{url: "Main_Netstat_Content.asp", tabName: "Netstat"},
					{url: "Advanced_Wireless_Survey.asp", tabName: "Site Survey"},
					{url: "NULL", tabName: "__INHERIT__"}
				]
			}
		],
		exclude: {
			menus: function(){ var retArray = []; return retArray; },
			tabs: function(){ var retArray = []; return retArray; }
		}
	};
	var fix = function(i, index){
		if(i == 2) menuTree.list[i].tab[index] = {url: "Main_TrafficMonitor_realtime.asp", tabName: "<#traffic_monitor#>"};
		else menuTree.list[i].tab[index] = {url: "Main_TrafficMonitor_realtime.asp", tabName: "<#traffic_monitor#>"};
	};
	return menuTree;
});
EOF

# ---- the node: its own nvram and wl, reached through a stand-in dbclient ----------------------------
cat > "$F/node-assoc" <<'EOF'
eth1 00:00:5E:00:53:FC 1000 2000
eth2 00:00:5E:00:53:FD 3000 4000
wl0.1 02:CC:00:00:00:11 4000 1000
wl1.1 02:CC:00:00:00:12 5000000 60000
wl1.1 02:CC:00:00:00:13 800000 90000
EOF
sed "s#$F/assoc#$F/node-assoc#" "$B/wl" > "$N/wl"
cat > "$N/nvram" <<EOF
#!$bb sh
# the node's own authorized SSH keys, in a file: nodekey adds the router's key here
case "\$1 \$2" in
	'get sshd_authkeys') cat "$t/node-authkeys" 2>/dev/null ;;
	'set sshd_authkeys='*) printf '%s' "\${2#sshd_authkeys=}" > "$t/node-authkeys" ;;
	'commit '*) ;;
	*) case "\$2" in wl0_ifname) echo eth1 ;; wl1_ifname) echo eth2 ;; wl0_vifs) echo wl0.1 ;; wl1_vifs) echo wl1.1 ;; wl0_nband) echo 2 ;; wl1_nband) echo 1 ;; esac ;;
esac
EOF
cat > "$B/dbclient" <<EOF
#!$bb sh
# a node that accepts only the router's Arteria key
[ "\$1 \$2" = "-o help" ] && { printf 'Available options:\\n\\tBatchMode\\n\\tPort\\n' >&2; exit 0; }
echo "\$*" >> "$t/dbclient.args"
y=0; for a in "\$@"; do [ "\$a" = -y ] && y=1; done
key=""; while [ \$# -gt 1 ]; do [ "\$1" = -i ] && key=\$2; shift; done
# the node's identity (host key), only when a test sets one. Like Dropbear's dbclient: a host seen for the first
# time is pinned only with -y; without it, it prints the fingerprint and refuses (no terminal, or BatchMode).
if [ -f "$t/node-identity" ]; then
	kh="\$HOME/.ssh/known_hosts"; id=\$(cat "$t/node-identity")
	if grep -q "^192.168.50.10 " "\$kh" 2>/dev/null; then
		grep -qx "192.168.50.10 ssh-ed25519 \$id" "\$kh" || { printf 'dbclient: Connection to admin@192.168.50.10:2222 exited:\\n\\nHost key mismatch for 192.168.50.10 !\\nIf you know that the host key is correct you can\\nremove the bad entry from ~/.ssh/known_hosts\\n' >&2; exit 1; }
	elif [ \$y = 1 ]; then mkdir -p "\$HOME/.ssh"; echo "192.168.50.10 ssh-ed25519 \$id" >> "\$kh"
	else printf "\\nHost '192.168.50.10' is not in the trusted hosts file.\\n(ssh-ed25519 fingerprint SHA256:%s)\\n\\ndbclient: Connection to admin@192.168.50.10:2222 exited: Didn't validate host key\\n" "\$id" >&2; exit 1; fi
	# a password typed at a terminal (nodekey): the right one, always
	if [ -z "\$key" ] && [ -t 0 ]; then echo "password login to \$id" >> "$t/dbclient.pw"; exec env PATH="$N:$B" "$bb" sh -c "\$1"; fi
	# the key works only once the node lists it
	grep -q AAAAC3NzaC1lZDI1NTE5AAAAITEST "$t/node-authkeys" 2>/dev/null || { echo "dbclient: Connection to admin@192.168.50.10:2222 exited: No auth methods could be used." >&2; exit 1; }
fi
[ -n "\$key" ] && [ -s "\$key" ] || { echo "dbclient: Connection to admin@192.168.50.10:2222 exited: No auth methods could be used." >&2; exit 1; }
echo "\$1" >> "$t/dbclient.cmds"
[ "\$1" = 'sh -s' ] && [ -f "$t/node-hostile" ] && exec "$bb" sh "$t/node-hostile"   # a node that sends anything but counters
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
# debug: router facts and classification counts for an issue, never a name, host name, MAC or IP
run debug > "$t/debug.out" 2>&1 || true
if grep -q '^Saved icons: ' "$t/debug.out" && grep -q '^Detected types: ' "$t/debug.out" && grep -q '^Private MACs: ' "$t/debug.out" \
	&& ! grep -qE 'Living room|tablet|Pixel-8|Hall|192\.168\.|02:[Cc][Cc]|02:10:00' "$t/debug.out"; then ok "debug: counts only, no names, MACs or IPs"
else bad "debug output:"; cat "$t/debug.out"; fi
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
assert '00:00:5E:00:53:FC' in s['own']
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
# waitfor SECONDS COMMAND...: retry COMMAND every 0.1 s until it succeeds, for at most SECONDS, instead of a fixed
# sleep. It only waits: the checks after it decide (and say) whether what it waited for happened.
waitfor() { local end=$(( $(date +%s%N) / 1000000 + $1 * 1000 )); shift; until "$@"; do [ $(( $(date +%s%N) / 1000000 )) -ge $end ] && return 0; sleep 0.1; done; }
seq_at_least() { [ "$(grep -o '"seq":[0-9]*' "$W/live.htm" 2>/dev/null | cut -d: -f2)" -ge "$1" ] 2>/dev/null; }
sampler_gone() { [ ! -f "$R/tmp/arteria/sampler.pid" ]; }
runi service_event start arteria
waitfor 10 seq_at_least 2
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
waitfor 6 sampler_gone
[ -f "$R/tmp/arteria/sampler.pid" ] && bad "sampler still running after the page closed" || ok "sampler stops when the page closes"

# ---- 2: with the key: the node's clients over the session ------------------------------------------
printf 'key\n' > "$R/jffs/addons/arteria/node_key"
runi service_event start arteria
node_read() { grep -q '"state":"ok"' "$W/live.htm" 2>/dev/null && grep -q '02:CC:00:00:00:13' "$W/live.htm" && [ -s "$W/names.htm" ]; }
waitfor 12 node_read
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
# Details: the Wi-Fi standard, streams and width per client, on the router and the node; null where the driver says nothing
r = {x[2]: x for x in s['sta']}
assert r['02:CC:00:00:00:03'][10:13] == ['ax', 2, 80], r['02:CC:00:00:00:03']
assert c['02:CC:00:00:00:12'][10:13] == ['ax', 2, 80], c['02:CC:00:00:00:12']
assert c['02:CC:00:00:00:13'][10:13] == [None, None, None], c['02:CC:00:00:00:13']
assert names['fixed'] == '<02:CC:00:00:00:04>192.168.50.20>>', names['fixed']
assert names['arp'] == '02:cc:00:00:00:01 192.168.50.30|', names['arp']
assert names['n6'] == '02:cc:00:00:00:12 2001:db8::12|02:cc:00:00:00:12 fe80::12|', names['n6']
EOF
grep -q '<' "$W/live.htm" "$W/names.htm" && bad "a raw '<' reached the page's data (httpd would run it as a template)" || ok "no raw '<' in the data files"
[ "$(grep -c "sh -s" "$t/dbclient.cmds" 2>/dev/null || echo 0)" = 1 ] && ok "one SSH session per node" || bad "SSH sessions: $(grep -c 'sh -s' "$t/dbclient.cmds" 2>/dev/null)"
grep -q -- "-p 2222 .*admin@192.168.50.10 sh -s" "$t/dbclient.args" && ok "the session uses the router's SSH port and admin name" || { bad "SSH arguments:"; cat "$t/dbclient.args"; }
grep -- " -i " "$t/dbclient.args" | grep -qv -- "-o BatchMode=yes" && { bad "a key login without BatchMode (dbclient could ask for a password):"; cat "$t/dbclient.args"; } || ok "key logins never offer a password (BatchMode)"
runi service_event start arteriastop
no_session() { ! pgrep -f "$N" > /dev/null 2>&1; }
waitfor 6 no_session
pgrep -f "$N" > /dev/null 2>&1 && bad "the node session outlived the page" || ok "node session ends with the sampler"
rm -rf "$R/tmp/arteria" "$W"

# A hostile node: rows with bad fields, markup, junk on stderr, and a flood. Only valid rows reach the page,
# the files stay small (the session is cut at about 1 MB, then trimmed), and the sample is still valid JSON.
cat > "$t/node-hostile" <<'EOF'
i=0
while [ $i -lt 40 ]; do
	printf '#B 1234.5\n'
	printf 'S eth1;reboot 5 02:CC:00:00:00:41 1 2 -50 100 100 10 0 ax 2 80\n'
	printf 'S wl1.1 5 "><img/src=x> 1 2 -50 100 100 10 0 ax 2 80\n'
	printf 'S wl1.1 5 02:CC:00:00:00:42 1e999 "x" -50<b> 100 100 10 0 ax 2 80\n'
	printf 'S wl1.1 5 02:CC:00:00:00:43 1000 2000 -50 100 100 10 0 ax 2 80\n'
	printf '#E\n'
	echo 'junk on stderr <script>' >&2
	[ $i -eq 1 ] && head -c 3000000 /dev/zero | tr '\0' 'x'
	i=$((i + 1)); sleep 1
done
EOF
runi service_event start arteria
big=0; for i in $(seq 45); do   # the largest the node's files get while it floods
	n=$(ls -l "$R"/tmp/arteria/node.* 2>/dev/null | awk '$5 > 1100000 { n++ } END { print n + 0 }'); [ "$n" -gt "$big" ] && big=$n; sleep 0.1
done
if python3 - "$W/live.htm" <<'EOF' && [ "$big" = 0 ] && ! grep -q '<' "$W/live.htm"; then ok "a hostile node: only valid rows and fields reach the page, its output stays bounded"
import json, sys
s = json.load(open(sys.argv[1]))
c = s['nodes'][0]['c']
assert [r[2] for r in c] == ['02:CC:00:00:00:42', '02:CC:00:00:00:43'], c   # a bad interface or MAC: the row is dropped
assert c[0][3:6] == [None, None, None] and c[1][3:6] == ['1000', '2000', -50], c   # a bad number: that field is null
EOF
else bad "hostile node ($big big files):"; ls -l "$R"/tmp/arteria/; python3 -c "import json,sys; print(json.load(open(sys.argv[1]))[\"nodes\"])" "$W/live.htm"; cat "$R"/tmp/arteria/node.*.last; fi
runi service_event start arteriastop
waitfor 6 sampler_gone; waitfor 6 no_session
rm -f "$t/node-hostile"; rm -rf "$R/tmp/arteria" "$W"

# nodes test: key login, then one round of the page's own node script: how many devices, how long. A node where that
# round fails (the session drops) says so, with addresses and user names taken out of the message.
run nodes test > "$t/nt.out" 2>&1 || true
grep -q 'key login OK, reads [0-9][0-9]* device(s), one round takes about [0-9][0-9]* s$' "$t/nt.out" \
	&& ok "nodes test: key login, then the node's devices read by the page's own script, with the time it takes" \
	|| { bad "nodes test:"; cat "$t/nt.out"; }
printf 'echo "dbclient: Connection to admin@192.168.50.10:2222 exited: Remote closed the connection" >&2\nexit 1\n' > "$t/node-hostile"
run nodes test > "$t/nt.out" 2>&1 || true; rm -f "$t/node-hostile"
grep -q 'key login OK, reading its devices failed: dbclient: Connection to user@IP:2222 exited: Remote closed the connection' "$t/nt.out" \
	&& ok "nodes test: a node whose session breaks says why, without its address or user name" \
	|| { bad "nodes test, broken session:"; cat "$t/nt.out"; }
run debug > "$t/debug2.out" 2>&1 || true
grep -q 'state=(page closed)' "$t/debug2.out" && ! grep -q '192\.168\.' "$t/debug2.out" \
	&& ok "debug: no node state while the page is closed (it would read 'down')" || { bad "debug, nodes:"; grep -A2 '^Nodes' "$t/debug2.out"; }

# Which nodes: the router's AiMesh list, never the router itself. Saving a setting empties that list for minutes while
# the nodes stay online: nodes then says so, rather than "no nodes".
run nodes > "$t/nodes.out" 2>&1
[ "$(grep -c 'Hall (RP-AX56, 192.168.50.10)' "$t/nodes.out")" = 1 ] && ! grep -q '192.168.50.1)' "$t/nodes.out" \
	&& ok "nodes: the AiMesh node once, with its name, model and address; not the router" || { bad "nodes:"; cat "$t/nodes.out"; }
touch "$t/no-device-list"; run nodes > "$t/nodes.out" 2>&1
grep -q "AiMesh lists 1 node(s), but none is in the router's current AiMesh list" "$t/nodes.out" \
	&& ok "nodes: while a settings save has emptied the AiMesh list, says the node will come back, not 'no nodes'" \
	|| { bad "nodes with the AiMesh list emptied:"; cat "$t/nodes.out"; }
rm -f "$t/no-device-list"

# nodekey print: one line to paste on a node, which adds the key once and keeps the keys already there
line=$(run nodekey print 2>&1 | grep "^k='ssh-")
mkdir -p "$t/nk"; printf 'ssh-ed25519 AAAAown me@laptop' > "$t/nk/store"
printf '#!%s sh\ncase "$1" in get) cat "%s/nk/store" ;; set) printf "%%s" "${2#sshd_authkeys=}" > "%s/nk/store" ;; esac\n' "$bb" "$t" "$t" > "$t/nk/nvram"
printf '#!%s sh\nexit 0\n' "$bb" > "$t/nk/service"; chmod +x "$t/nk/nvram" "$t/nk/service"
if [ -n "$line" ] && PATH="$t/nk:$B" "$bb" sh -c "$line" > /dev/null && PATH="$t/nk:$B" "$bb" sh -c "$line" | grep -q 'already has' \
	&& [ "$(grep -c '' "$t/nk/store")" = 2 ] && grep -q '^ssh-ed25519 AAAAown me@laptop$' "$t/nk/store" && grep -q 'AAAAC3NzaC1lZDI1NTE5AAAAITEST arteria$' "$t/nk/store"; then
	ok "nodekey print: a one-line command that adds the key once and keeps the node's own keys"
else bad "nodekey print:"; printf '%s\n' "$line"; cat "$t/nk/store"; fi

# nodekey, at a terminal (a pty): the node's pinned identity is only replaced when the person says so, and
# no password goes to a node whose identity changed until then
mkdir -p "$R/jffs/addons/arteria/.ssh"; echo "192.168.50.10 ssh-ed25519 OLDKEY" > "$R/jffs/addons/arteria/.ssh/known_hosts"
echo NEWKEY > "$t/node-identity"; rm -f "$R/jffs/addons/arteria/node_key" "$t/dbclient.pw"
cat > "$t/term.py" <<'EOF'
import os, pty, sys, select, time
pid, fd = pty.fork()
if pid == 0:
    os.execv(sys.argv[1], [sys.argv[1], 'ash', sys.argv[2], 'nodekey'])
out = b''; sent = False; end = time.time() + 40
while time.time() < end:
    r, _, _ = select.select([fd], [], [], 0.5)
    if not r: continue
    try: d = os.read(fd, 4096)
    except OSError: break
    if not d: break
    out += d
    if not sent and b'(y/n)' in out: os.write(fd, sys.argv[3].encode() + b'\n'); sent = True
sys.stdout.write(out.decode('utf-8', 'replace'))
EOF
py=$(command -v python3)
nk() { AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$py" "$t/term.py" "$bb" "$inst" "$1" 2>&1 || true; }   # answer
if "$py" -c 'import pty' 2>/dev/null; then
	nk n > "$t/nk-n.out"
	if grep -q "Trust the new identity" "$t/nk-n.out" && grep -q "OLDKEY" "$R/jffs/addons/arteria/.ssh/known_hosts" && [ ! -f "$t/dbclient.pw" ]; then
		ok "nodekey: a changed node identity is kept, and no password is sent, when the answer is no"
	else bad "nodekey with a changed identity, answer n:"; cat "$t/nk-n.out"; fi
	nk y > "$t/nk-y.out"
	if grep -q "Key added" "$t/nk-y.out" && grep -q "Key login works" "$t/nk-y.out" && grep -q "NEWKEY" "$R/jffs/addons/arteria/.ssh/known_hosts" \
		&& ! grep -q "OLDKEY" "$R/jffs/addons/arteria/.ssh/known_hosts" && [ "$(grep -c . "$t/dbclient.pw")" = 1 ]; then
		ok "nodekey: after a yes the new identity is pinned and the key is added with one password login"
	else bad "nodekey with a changed identity, answer y:"; cat "$t/nk-y.out"; fi
	# first contact: nothing pinned yet, so nodekey shows what answered and asks before any password is sent
	rm -rf "$R/jffs/addons/arteria/.ssh" "$t/dbclient.pw" "$t/node-authkeys"; echo FIRSTKEY > "$t/node-identity"
	nk n > "$t/nk-first-n.out"
	if grep -q "hasn't connected to 192.168.50.10 before" "$t/nk-first-n.out" && grep -q "SHA256:FIRSTKEY" "$t/nk-first-n.out" \
		&& [ ! -f "$t/dbclient.pw" ] && ! grep -q FIRSTKEY "$R/jffs/addons/arteria/.ssh/known_hosts" 2>/dev/null; then
		ok "nodekey: a node seen for the first time shows its fingerprint, and no password is sent when the answer is no"
	else bad "nodekey, first contact, answer n:"; cat "$t/nk-first-n.out"; fi
	nk y > "$t/nk-first-y.out"
	if grep -q "Key login works" "$t/nk-first-y.out" && grep -q "FIRSTKEY" "$R/jffs/addons/arteria/.ssh/known_hosts" && [ "$(grep -c . "$t/dbclient.pw")" = 1 ]; then
		ok "nodekey: after a yes the first identity is pinned and the key is added with one password login"
	else bad "nodekey, first contact, answer y:"; cat "$t/nk-first-y.out"; fi
	# a node that already got the key from an AiMesh sync: trusted, then the key works, no password at all
	rm -rf "$R/jffs/addons/arteria/.ssh" "$t/dbclient.pw"; echo SYNCEDKEY > "$t/node-identity"
	nk y > "$t/nk-synced.out"
	if grep -q "Key login works" "$t/nk-synced.out" && grep -q SYNCEDKEY "$R/jffs/addons/arteria/.ssh/known_hosts" && [ ! -f "$t/dbclient.pw" ]; then
		ok "nodekey: a node that already has the key (an AiMesh sync) is trusted with no password at all"
	else bad "nodekey, node already has the key:"; cat "$t/nk-synced.out"; fi
	[ "$(grep -c 'AAAAC3NzaC1lZDI1NTE5AAAAITEST arteria' "$t/router-authkeys" 2>/dev/null)" = 1 ] \
		&& ok "nodekey keeps the key in the router's own list too, once (AiMesh copies that list to the nodes)" || { bad "router's key list:"; cat "$t/router-authkeys"; }
	# the key works, but the node's own list (nvram) doesn't have it: nodekey adds it there with the key, no password
	rm -f "$t/node-identity" "$t/dbclient.pw"; : > "$t/node-authkeys"
	nk y > "$t/nk-keep.out"; nk y > "$t/nk-keep2.out"
	if grep -q "Already has the key" "$t/nk-keep.out" && grep -q "node's own key list too" "$t/nk-keep.out" && ! grep -q "own key list" "$t/nk-keep2.out" \
		&& [ "$(grep -c 'AAAAC3NzaC1lZDI1NTE5AAAAITEST arteria' "$t/node-authkeys")" = 1 ] && [ ! -f "$t/dbclient.pw" ]; then
		ok "nodekey: a node that takes the key but doesn't list it gets it in its own list, once, with no password"
	else bad "nodekey, key works but the node doesn't list it:"; cat "$t/nk-keep.out" "$t/nk-keep2.out"; cat "$t/node-authkeys"; fi
	# password login off on the router (and so on the nodes): no password is asked for; the key waits in the router's
	# list for the next AiMesh sync, and nodekey says how to start one
	rm -rf "$R/jffs/addons/arteria/.ssh" "$t/dbclient.pw"; echo PASSKEY > "$t/node-identity"; : > "$t/node-authkeys"; echo 0 > "$t/sshd-pass"
	nk y > "$t/nk-nopass.out"; rm -f "$t/sshd-pass"
	if grep -q "Password login over SSH is off on the router" "$t/nk-nopass.out" && grep -q "saving a setting" "$t/nk-nopass.out" && grep -q "nodes test" "$t/nk-nopass.out" \
		&& [ ! -f "$t/dbclient.pw" ] && grep -q 'AAAAC3NzaC1lZDI1NTE5AAAAITEST arteria' "$t/router-authkeys"; then
		ok "nodekey with password login off: no password asked, the key waits in the router's list for the AiMesh sync"
	else bad "nodekey with password login off:"; cat "$t/nk-nopass.out"; fi
else echo "skip  nodekey at a terminal (python3 has no pty module here)"; fi
# The sampler never pins a node itself: one seen for the first time is "nokey" (run nodekey) and stays unpinned
rm -rf "$R/jffs/addons/arteria/.ssh" "$R/tmp/arteria"; echo FIRSTKEY > "$t/node-identity"; printf 'key\n' > "$R/jffs/addons/arteria/node_key"
runi service_event start arteria
node_tried() { grep -q "trusted hosts" "$R"/tmp/arteria/node.*.err 2>/dev/null && seq_at_least 2; }
waitfor 10 node_tried
if grep -q '"state":"nokey"' "$W/live.htm" 2>/dev/null && ! grep -q FIRSTKEY "$R/jffs/addons/arteria/.ssh/known_hosts" 2>/dev/null; then
	ok "the sampler doesn't pin a node it has never seen: it says to run nodekey"
else bad "sampler and an unknown node:"; head -c 400 "$W/live.htm"; cat "$R"/tmp/arteria/node.*.err; fi
runi service_event start arteriastop; waitfor 6 sampler_gone; waitfor 6 no_session
rm -f "$t/node-identity" "$t/dbclient.pw" "$t/node-authkeys"; rm -rf "$R/jffs/addons/arteria/.ssh"; printf 'key\n' > "$R/jffs/addons/arteria/node_key"
rm -rf "$R/tmp/arteria"

# ---- 3: stale pid files never touch someone else's process ----------------------------------------
# The router reuses pids within minutes. A pid file left behind (a sampler or node session that was
# killed) may by then name an unrelated process: it must neither be signalled nor block the sampler.
sleep 300 & other=$!
mkdir -p "$R/tmp/arteria"; echo "$other" > "$R/tmp/arteria/sampler.pid"
runi service_event start arteria
new_sampler() { [ -f "$R/tmp/arteria/sampler.pid" ] && [ "$(cat "$R/tmp/arteria/sampler.pid" 2>/dev/null)" != "$other" ]; }
waitfor 8 new_sampler
[ "$(cat "$R/tmp/arteria/sampler.pid" 2>/dev/null)" != "$other" ] && [ -f "$R/tmp/arteria/sampler.pid" ] \
	&& ok "a stale sampler pid file doesn't keep the sampler from starting" || bad "the sampler didn't start over a stale pid file"
runi service_event start arteriastop
waitfor 6 sampler_gone; waitfor 6 no_session
echo "$other" > "$R/tmp/arteria/sampler.pid"; echo "$other" > "$R/tmp/arteria/node.021000000080.pid"
runi startup > /dev/null 2>&1   # stops the sampler and node sessions, as an update or uninstall does
kill -0 "$other" 2>/dev/null && ok "stale pid files never signal another process" || bad "Arteria killed a process that wasn't its own"
kill "$other" 2>/dev/null; wait "$other" 2>/dev/null || true
rm -rf "$R/tmp/arteria" "$W" "$R/tmp/menuTree.js" "$R/jffs/addons/arteria/webui_page" "$R"/www/user/user*

# /tmp/arteria planted as a link by someone else: Arteria won't use it, so nothing runs or is written through it
mkdir -p "$t/planted"; ln -s "$t/planted" "$R/tmp/arteria"
runi service_event start arteria > "$t/planted.out" 2>&1 || true
sleep 1   # nothing should happen: give a sampler the time it would need to start
if [ -z "$(ls -A "$t/planted")" ] && ! pgrep -f "$script sampler" > /dev/null; then ok "a planted /tmp/arteria link is refused: no sampler, nothing written through it"
else bad "planted /tmp/arteria:"; ls -la "$t/planted"; cat "$t/planted.out"; fi
rm -f "$R/tmp/arteria"

# ---- 3b: Fingerbank (off unless you give your own key) --------------------------------------------
# dnsmasq's config as the router writes it, then its postconf scripts, at every dnsmasq restart (a stand-in service);
# a stand-in dnsmasq that knows script-on-renewal; ASUS's lease script, which records how it was called;
# a stand-in curl for api.fingerbank.org, which reads its config (the key) from stdin and logs its arguments.
mkdir -p "$R/etc"
printf 'domain-needed\ndhcp-script=%s/dhcpc_lease\n' "$t" > "$t/dnsmasq.base"; cp "$t/dnsmasq.base" "$R/etc/dnsmasq.conf"
printf '#!%s sh\necho "$* opts=$DNSMASQ_REQUESTED_OPTIONS" >> "%s/lease.log"\n' "$bb" "$t" > "$t/dhcpc_lease"
printf '#!/bin/sh\n# another addon\nCONFIG=$1\n' > "$R/jffs/scripts/dnsmasq.postconf"; chmod 755 "$R/jffs/scripts/dnsmasq.postconf"
cp "$R/jffs/scripts/dnsmasq.postconf" "$t/postconf.before"
cat > "$B/service" <<EOF
#!$bb sh
echo "\$*" >> "$t/service.log"
[ "\$1" = restart_dnsmasq ] || exit 0
cp "$t/dnsmasq.base" "$R/etc/dnsmasq.conf"
[ -f "$R/jffs/scripts/dnsmasq.postconf" ] && AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$bb" sh "$R/jffs/scripts/dnsmasq.postconf" "$R/etc/dnsmasq.conf"
exit 0
EOF
printf '#!%s sh\n[ "$1" = --help ] && echo "    --script-on-renewal        Call DHCP script on lease renewal."\nexit 0\n' "$bb" > "$B/dnsmasq"
cat > "$B/curl" <<EOF
#!$bb sh
echo "\$*" >> "$t/fbcurl.args"
cfg=\$(cat); printf '%s\n' "\$cfg" >> "$t/fbcurl.cfg"
d=""; while [ \$# -gt 0 ]; do [ "\$1" = -d ] && d=\$2; shift; done
case "\$cfg" in *BADKEY*) printf '{"errors":"Unauthorized"}\n401'; exit 0 ;; esac
case "\$d" in
	*'"dhcp_fingerprint":"1,3,6,15,31,33,43,44,46,47,119,121,249,252","dhcp_vendor":"dhcpcd-9.4.1:Linux:armv7l x"'*)
		printf '{"device":{"id":15666,"name":"Amazon Echo","parents":[]},"device_name":"Internet of Things (IoT)/Home Assistant/Amazon Alexa/Amazon Echo","score":87,"version":"","request_id":"x"}\n200' ;;
	*) printf '{"errors":{"details":"No profiling result"}}\n404' ;;
esac
EOF
chmod +x "$t/dhcpc_lease" "$B/service" "$B/dnsmasq" "$B/curl"
FBK=abcdef0123456789abcdef0123456789abcdef01
fbst() { python3 -c "import json,sys; v=json.load(open(sys.argv[1]))[sys.argv[2]]; print(json.dumps(v) if not isinstance(v, str) else v)" "$W/fb.htm" "$1"; }
fbk="$R/jffs/addons/arteria/fingerbank_key"

# A key Fingerbank turns down changes nothing
printf 'BADKEY0123456789BADKEY01\n' | runi fingerbank > "$t/fb.out" 2>&1 && bad "fingerbank accepted a refused key" || true
if grep -q 'turned this key down' "$t/fb.out" && [ ! -f "$fbk" ] && cmp -s "$R/jffs/scripts/dnsmasq.postconf" "$t/postconf.before"; then
	ok "fingerbank: a key Fingerbank turns down changes nothing"
else bad "fingerbank, refused key:"; cat "$t/fb.out"; fi

# A good key: saved for root only, one line in dnsmasq.postconf after the other addon's, dnsmasq restarted with our
# lease script (which hands on to ASUS's) and with script-on-renewal; the key never in a command line
: > "$t/fbcurl.args"; : > "$t/fbcurl.cfg"
printf '%s\n' "$FBK" | runi fingerbank > "$t/fb.out" 2>&1 || { bad "fingerbank failed:"; cat "$t/fb.out"; }
hook=$(sed -n 's/^dhcp-script=//p' "$R/etc/dnsmasq.conf")
if [ "$(cat "$fbk" 2>/dev/null)" = "$FBK" ] && [ "$(stat -c %a "$fbk")" = 600 ] \
	&& [ "$(grep -c '# arteria$' "$R/jffs/scripts/dnsmasq.postconf")" = 1 ] && head -n 3 "$R/jffs/scripts/dnsmasq.postconf" | cmp -s - "$t/postconf.before" \
	&& case "$hook" in "$R/tmp/arteria/dhcp_hook."*.sh) true ;; *) false ;; esac && grep -q "^exec $t/dhcpc_lease \"\$@\"$" "$hook" \
	&& grep -q '^script-on-renewal$' "$R/etc/dnsmasq.conf" && grep -q restart_dnsmasq "$t/service.log"; then
	ok "fingerbank: key saved for root only, dnsmasq runs Arteria's lease script first (then ASUS's), and on renewals"
else bad "fingerbank, good key:"; cat "$t/fb.out"; ls -l "$fbk"; cat "$R/jffs/scripts/dnsmasq.postconf" "$R/etc/dnsmasq.conf"; fi
grep -q "$FBK" "$t/fbcurl.args" && bad "the key was in curl's command line" || ok "the key never appears in a command line"
grep -q "^header = \"Authorization: Bearer $FBK\"$" "$t/fbcurl.cfg" && ok "the key goes to Fingerbank as a Bearer header" || { bad "curl config:"; cat "$t/fbcurl.cfg"; }
# restarting again: still one line, still ours (the postconf runs at every dnsmasq start)
PATH="$B" service restart_dnsmasq
[ "$(grep -c '^dhcp-script=' "$R/etc/dnsmasq.conf")" = 1 ] && [ "$(sed -n 's/^dhcp-script=//p' "$R/etc/dnsmasq.conf")" = "$hook" ] \
	&& [ "$(grep -c '^script-on-renewal' "$R/etc/dnsmasq.conf")" = 1 ] && ok "a dnsmasq restart keeps one lease script line, ours" || { bad "after a restart:"; cat "$R/etc/dnsmasq.conf"; }

# The lease script, called as dnsmasq calls it: it notes the fingerprint (and the vendor class, cleaned), always hands
# on to ASUS's script with the same arguments and environment, and ignores a MAC or option list that isn't one
: > "$t/lease.log"; : > "$t/fbcurl.args"
lease() { env -i PATH="$B" DNSMASQ_REQUESTED_OPTIONS="$1" DNSMASQ_VENDOR_CLASS="$2" "$hook" "$3" "$4" 192.168.50.99 host; }
lease '1,3,6,15,31,33,43,44,46,47,119,121,249,252' 'dhcpcd-9.4.1:Linux:armv7l "x"<>' add 02:cc:00:00:00:05
lease '1,3,6,15,119,252' '  MSFT   5.0 ' old 02:cc:00:00:00:12
lease '1,3,6;reboot' '' add '02:cc:00:00:00:0Z'
lease '1,3,6' '' del 02:cc:00:00:00:07
lease '1,3,6,15,119,252,95' '' add 02:cc:00:00:00:12    # the same device again: one line, the latest
fp="$R/tmp/arteria/dhcp_fp"
if [ "$(cat "$fp")" = "$(printf '02:CC:00:00:00:05 1,3,6,15,31,33,43,44,46,47,119,121,249,252 dhcpcd-9.4.1:Linux:armv7l x\n02:CC:00:00:00:12 1,3,6,15,119,252,95 ')" ] \
	&& [ "$(grep -c '' "$t/lease.log")" = 5 ] && grep -q '^add 02:cc:00:00:00:05 192.168.50.99 host opts=1,3,6,15,31' "$t/lease.log" && grep -q '^del 02:cc:00:00:00:07 ' "$t/lease.log"; then
	ok "lease script: notes each device's fingerprint once, cleaned; ASUS's script still gets every call, unchanged"
else bad "lease script:"; cat "$fp" "$t/lease.log"; fi

# Fingerbank is asked about each new fingerprint at once, in the background, page open or not (the option list and
# vendor class only), the answers stay on JFFS, and the page gets them when it opens.
fb_answered() { grep -q '^1,3,6,15,119,252,95;' "$R/jffs/addons/arteria/fingerbank" 2>/dev/null && grep -q 'Amazon Echo' "$R/jffs/addons/arteria/fingerbank"; }
waitfor 15 fb_answered
python3 - "$R/jffs/addons/arteria/fingerbank" "$t/fbcurl.args" <<'EOF' && ok "lookups: each new fingerprint asked at once, page closed, without MAC or name" || fail=1
import sys
cache = [l.split('\t') for l in open(sys.argv[1]).read().splitlines()]
got = set((c[0], c[1], c[2]) for c in cache)
need = {('1,3,6,15,119,252,95;', '404', '0'), ('1,3,6,15,31,33,43,44,46,47,119,121,249,252;dhcpcd-9.4.1:Linux:armv7l x', '200', '87')}
# :12's first fingerprint (its vendor class "  MSFT   5.0 " with single spaces) may or may not be asked about before :12 sent its next one
assert need <= got <= need | {('1,3,6,15,119,252;MSFT 5.0', '404', '0')}, cache
args = open(sys.argv[2]).read()
assert args.count('interrogate') == len(cache), args
assert '02:cc:00' not in args.lower() and 'host' not in args and '192.168' not in args, args
EOF
: > "$t/fbcurl.args"; rm -f "$W/names.htm"
runi service_event start arteria
fb_shown() { grep -q 'Amazon Echo' "$W/names.htm" 2>/dev/null; }
waitfor 10 fb_shown
python3 - "$W/names.htm" "$t/fbcurl.args" <<'EOF' && ok "the page gets the answers when it opens, without asking Fingerbank again" || fail=1
import json, sys
fb = json.load(open(sys.argv[1]))['fb']
assert fb == '02:CC:00:00:00:05>87>Internet of Things (IoT)/Home Assistant/Amazon Alexa/Amazon Echo>1,3,6,15,31,33,43,44,46,47,119,121,249,252|02:CC:00:00:00:12>>>1,3,6,15,119,252,95|', fb
assert open(sys.argv[2]).read().count('interrogate') == 0
EOF
runi service_event start arteriastop; waitfor 6 sampler_gone

# status and debug: counts, never the key or a MAC; a key Fingerbank later turns down stops the lookups and says so
runi status > "$t/st.out" 2>&1; runi debug > "$t/dbg.out" 2>&1 || true
if grep -q '^Fingerbank:  on, 2 devices fingerprinted, 1 kinds of device known to Fingerbank, last reply 404' "$t/st.out" \
	&& grep -q "^Fingerbank:     on; lease script: Arteria's, then $t/dhcpc_lease; renewals: yes; 2 devices" "$t/dbg.out" \
	&& ! grep -qi "$FBK\|02:cc:00" "$t/st.out" "$t/dbg.out"; then ok "status and debug: Fingerbank's state in counts, no key or MAC"
else bad "status/debug:"; grep -i fingerbank "$t/st.out" "$t/dbg.out"; fi
# Recognise now: asks the devices on the network what they are (mDNS and UPnP, through socat), keeps what they said by
# MAC (never names or addresses), and asks Fingerbank again with it. Nothing is disconnected. A stand-in socat answers
# as a small network would: a speaker that needs every round of questions, a laptop (a name with an apostrophe, its
# answers compressed) with a UPnP description, a printer that isn't in the ARP table (so it can't be told apart),
# and UPnP replies pointing at the router itself and at 127.0.0.1, which are never fetched.
cp "$R/var/lib/misc/dnsmasq.leases" "$t/leases.before"; cp "$t/proc/net/arp" "$t/arp.before"
for m in 01 03 05 12 13 99; do echo "1794400000 02:cc:00:00:00:$m 192.168.50.1$m h$m *"; done > "$R/var/lib/misc/dnsmasq.leases"
printf '1794400000 02:10:00:00:00:80 192.168.50.10 node *\n1794400000 02:10:00:00:00:81 192.168.50.11 bh *\n' >> "$R/var/lib/misc/dnsmasq.leases"
printf '192.168.50.130   0x1         0x2         02:cc:00:00:00:01     *        br0\n192.168.50.131   0x1         0x2         02:CC:00:00:00:05     *        br0\n' >> "$t/proc/net/arp"
for d in "$B" "$N"; do mv "$d/wl" "$d/wl.real"; printf '#!%s sh\n[ "$3" = deauthenticate ] && echo "$*" >> "%s/deauth.log"\nexec "%s/wl.real" "$@"\n' "$bb" "$t" "$d" > "$d/wl"; chmod +x "$d/wl"; done
: > "$t/deauth.log"; : > "$t/socat.log"
cat > "$B/socat" <<EOF
#!$py
import sys, struct
open("$t/socat.log", "a").write(" ".join(sys.argv[1:]) + "\n")
DEV = [  # address, host, [(service type, instance, TXT, extras with the PTR answer)]
    ("192.168.50.130", "Kitchen-Speaker.local", [("_spotify-connect._tcp.local", "Kitchen Speaker._spotify-connect._tcp.local", ["VERSION=1.0"], False),
                                                ("_meshcop._udp.local", "Speaker #1A2B._meshcop._udp.local", ["vn=Amazon", "mn=Echo 4th Gen", "nn=Home"], False)]),
    ("192.168.50.131", "Jos-Laptop.local", [("_companion-link._tcp.local", "Jo’s Laptop._companion-link._tcp.local", ["rpMd=MacBookPro18,1", "rpHN=ab12"], True),
                                           ("_http._tcp.local", "Jo’s Laptop._http._tcp.local", ["path=/"], True)]),
    ("192.168.50.140", "Printer.local", [("_printer._tcp.local", "Printer._printer._tcp.local", ["ty=Made Up LaserJet 1000"], True)]),
]
class Pk:   # a DNS answer, its names compressed
    def __init__(s): s.b = bytearray(12); s.off = {}; s.n = 0
    def name(s, n):
        labs = n.split(".")
        for i in range(len(labs)):
            suf = ".".join(labs[i:]).lower()
            if suf in s.off: s.b += struct.pack(">H", 0xC000 | s.off[suf]); return
            s.off[suf] = len(s.b); e = labs[i].encode(); s.b += bytes([len(e)]) + e
        s.b += b"\0"
    def rr(s, owner, typ, rdata):
        s.name(owner); s.b += struct.pack(">HHI", typ, 0x8001, 120); lp = len(s.b); s.b += b"\0\0"; rdata(); struct.pack_into(">H", s.b, lp, len(s.b) - lp - 2); s.n += 1
    def ptr(s, o, t): s.rr(o, 12, lambda: s.name(t))
    def srv(s, o, h): s.rr(o, 33, lambda: (s.b.extend(struct.pack(">HHH", 0, 0, 80)), s.name(h)))
    def txt(s, o, t): s.rr(o, 16, lambda: [s.b.extend(bytes([len(x.encode())]) + x.encode()) for x in t])
    def a(s, o, ip): s.rr(o, 1, lambda: s.b.extend(bytes(int(x) for x in ip.split("."))))
def dump(d, way):
    sys.stderr.write("%s 2026/11/12 23:00:00.000000  length=%d from=0 to=%d\n" % (way, len(d), len(d) - 1))
    for i in range(0, len(d), 16): sys.stderr.write(" " + " ".join("%02x" % x for x in d[i:i + 16]) + "\n")
    sys.stderr.write("--\n")
if "5353" in " ".join(sys.argv):
    q = sys.stdin.buffer.read(); dump(q, ">")
    qs = []; p = 12
    for _ in range(struct.unpack(">H", q[4:6])[0]):
        labs = []
        while q[p]: labs.append(q[p + 1:p + 1 + q[p]].decode()); p += 1 + q[p]
        qs.append((".".join(labs).lower(), struct.unpack(">H", q[p + 1:p + 3])[0])); p += 5
    for ip, host, svcs in DEV:
        r = Pk()
        for n, t in qs:
            for typ, inst, tx, extra in svcs:
                if n == "_services._dns-sd._udp.local" and t == 12: r.ptr(n, typ)
                elif n == typ.lower() and t == 12:
                    r.ptr(typ, inst)
                    if extra: r.srv(inst, host); r.txt(inst, tx); r.a(host, ip)
                elif n == inst.lower() and t == 255: r.srv(inst, host); r.txt(inst, tx)
            if n == host.lower() and t == 1: r.a(host, ip)
        if r.n:
            struct.pack_into(">HHHHHH", r.b, 0, 0, 0x8400, 0, r.n, 0, 0); dump(bytes(r.b), "<")
else:
    sys.stdin.read()
    for loc, srv in (("http://192.168.50.131:8099/desc.xml", "Linux/5.10 UPnP/1.0 MadeUp/1.0"), ("http://192.168.50.1:80/rootDesc.xml", "AsusWRT/3004 UPnP/1.1 MiniUPnPd/2.3"), ("http://127.0.0.1:80/x", "Evil/1.0")):
        sys.stdout.write("HTTP/1.1 200 OK\r\nCACHE-CONTROL: max-age=1800\r\nLOCATION: %s\r\nSERVER: %s\r\nST: upnp:rootdevice\r\n\r\n" % (loc, srv))
EOF
chmod +x "$B/socat"
# Fingerbank, asked with what the devices said, knows them better (the stand-in curl answers these questions)
mv "$B/curl" "$t/curl.fb"
cat > "$B/curl" <<EOF
#!$bb sh
case "\$*" in *desc.xml*) echo "\$*" >> "$t/upnp.args"; printf '<?xml version="1.0"?><root><device><friendlyName>Jo</friendlyName><manufacturer>Made Up Inc</manufacturer><modelName>Laptop</modelName></device></root>'; exit 0 ;;
	*http://*) echo "\$*" >> "$t/upnp.args"; exit 0 ;; esac
for a in "\$@"; do case "\$a" in
	*'"mdns_services":["_meshcop._udp.local","_spotify-connect._tcp.local"]'*) cat > /dev/null; echo "\$*" >> "$t/fbcurl.args"
		printf '{"device_name":"Internet of Things (IoT)/Home Assistant/Amazon Alexa/Amazon Echo","score":73}\n200'; exit 0 ;;
	*'"mdns_services":["_companion-link._tcp.local","_http._tcp.local"],"upnp_server_strings":["Linux/5.10 UPnP/1.0 MadeUp/1.0"]'*) cat > /dev/null; echo "\$*" >> "$t/fbcurl.args"
		printf '{"device_name":"Computer/Apple Mac/MacBook Pro","score":80}\n200'; exit 0 ;;
esac; done
exec "$t/curl.fb" "\$@"
EOF
chmod +x "$B/curl"; : > "$t/fbcurl.args"; : > "$t/upnp.args"
runi service_event start arteriafbnow
disc="$R/jffs/addons/arteria/discovered"
if [ "$(cut -d'|' -f1-5 "$disc")" = "$(printf '%s\n' '02:CC:00:00:00:01|_meshcop._udp.local _spotify-connect._tcp.local|mn=Echo 4th Gen;vn=Amazon||' \
	'02:CC:00:00:00:05|_companion-link._tcp.local _http._tcp.local|rpMd=MacBookPro18,1|manufacturer=Made Up Inc; modelName=Laptop|Linux/5.10 UPnP/1.0 MadeUp/1.0')" ] \
	&& [ "$(cut -d'|' -f6 "$disc" | grep -c '^1[0-9]\{9\}$')" = 2 ]; then
	ok "recognise now: each device's services, model and UPnP details kept by MAC (none without one), with no name or address"
else bad "recognise now, what devices said:"; cat "$disc" "$t/socat.log"; fi
grep -qi "Jo\|Kitchen\|Speaker\|192\.168\|ab12\|friendly" "$disc" && bad "a name or address was kept: $(cat "$disc")" || ok "recognise now keeps no names, host names or addresses"
[ "$(cat "$t/upnp.args")" = "-s --proto =http --max-redirs 0 -m 3 --max-filesize 65536 http://192.168.50.131:8099/desc.xml" ] \
	&& ok "recognise now: UPnP descriptions only from devices on the LAN, never the router itself or 127.0.0.1" || { bad "UPnP fetches:"; cat "$t/upnp.args"; }
[ ! -s "$t/deauth.log" ] && ok "recognise now disconnects nothing" || { bad "something was disconnected:"; cat "$t/deauth.log"; }
if grep -q '^1,3,6,15,31,33,43,44,46,47,119,121,249,252;dhcpcd-9.4.1:Linux:armv7l x;_companion-link._tcp.local,_http._tcp.local;Linux/5.10 UPnP/1.0 MadeUp/1.0	200	80	Computer/Apple Mac/MacBook Pro	' "$R/jffs/addons/arteria/fingerbank" \
	&& grep -q '^;;_meshcop._udp.local,_spotify-connect._tcp.local;	200	73	' "$R/jffs/addons/arteria/fingerbank" \
	&& [ "$(fbst ok)" = true ] && fbst msg | grep -q '^2 device(s) answered\. Fingerbank has an answer for 2 of 3 device(s)\.$' && [ "$(fbst asked)" = 2 ] && [ "$(fbst socat)" = true ]; then
	ok "recognise now: Fingerbank asked again with each device's services and UPnP SERVER string, and the page told"
else bad "recognise now, Fingerbank:"; cat "$R/jffs/addons/arteria/fingerbank" "$W/fb.htm"; fi
grep -qi '02:cc\|"mac"\|Jo\|Kitchen\|rpMd\|192\.168' "$t/fbcurl.args" && bad "Fingerbank got more than it should: $(cat "$t/fbcurl.args")" || ok "Fingerbank gets services and SERVER strings only: no MAC, name, model field or address"
# the page gets the better answers (the one from the DHCP fingerprint alone stands in until there is one)
rm -f "$W/names.htm"; runi service_event start arteria
fb_better() { grep -q 'MacBook Pro' "$W/names.htm" 2>/dev/null; }; waitfor 15 fb_better
python3 - "$W/names.htm" <<'EOF' && ok "the page gets each device's answer to its fullest question, and what each device announced" || fail=1
import json, sys
n = json.load(open(sys.argv[1])); fb = n['fb']; dc = n['dc']
assert fb == '02:CC:00:00:00:05>80>Computer/Apple Mac/MacBook Pro>1,3,6,15,31,33,43,44,46,47,119,121,249,252|02:CC:00:00:00:12>>>1,3,6,15,119,252,95|02:CC:00:00:00:01>73>Internet of Things (IoT)/Home Assistant/Amazon Alexa/Amazon Echo>|', fb
assert dc == '02:CC:00:00:00:01>_meshcop._udp.local _spotify-connect._tcp.local>mn=Echo 4th Gen;vn=Amazon>|02:CC:00:00:00:05>_companion-link._tcp.local _http._tcp.local>rpMd=MacBookPro18,1>manufacturer=Made Up Inc; modelName=Laptop|', dc
EOF
runi service_event start arteriastop; waitfor 6 sampler_gone
[ "$(fbst waiting)" = 4 ] && ok "fb.htm counts the devices not seen yet" || { bad "waiting count:"; cat "$W/fb.htm"; }
# compare: each device that answered, looked up four ways (with its maker, then its whole MAC); nothing is kept
cp "$R/jffs/addons/arteria/fingerbank" "$t/fbcache.before"; : > "$t/fbcurl.args"
runi fingerbank compare > "$t/cmp.out" 2>&1 || { bad "fingerbank compare failed:"; cat "$t/cmp.out"; }
if grep -q '^\.\.\.00:05  _companion-link._tcp.local _http._tcp.local  \[rpMd=MacBookPro18,1\]' "$t/cmp.out" \
	&& grep -q '^  DHCP only:   Internet of Things (IoT)/Home Assistant/Amazon Alexa/Amazon Echo (87)$' "$t/cmp.out" \
	&& [ "$(grep -c '^  + whole MAC: ' "$t/cmp.out")" = 2 ] && [ "$(grep -c '^  DHCP only: ' "$t/cmp.out")" = 1 ] \
	&& grep -q '"mac":"02:CC:00:00:00:05"' "$t/fbcurl.args" && grep -q '"mac":"02:CC:00:00:00:00"' "$t/fbcurl.args" \
	&& ! grep -qi 'Jo\|Kitchen\|192\.168\|friendly' "$t/cmp.out" && cmp -s "$R/jffs/addons/arteria/fingerbank" "$t/fbcache.before"; then
	ok "fingerbank compare: each device four ways (DHCP, + services, + maker, + whole MAC), nothing kept, no names or addresses"
else bad "fingerbank compare:"; cat "$t/cmp.out"; fi
grep -q "$FBK" "$t/fbcurl.args" && bad "the key was in curl's command line (compare)" || true
# a device that joins is asked about after a minute (here at once): it and any that joined meanwhile, once until a reboot
printf '192.168.50.140   0x1         0x2         02:cc:00:00:00:14     *        br0\n' >> "$t/proc/net/arp"
export AR_DISC_DELAY=0; PATH="$B" service restart_dnsmasq; hook=$(sed -n 's/^dhcp-script=//p' "$R/etc/dnsmasq.conf")
n0=$(grep -c 5353 "$t/socat.log")
lease '1,3,6,15,44,47' '' add 02:cc:00:00:00:14
joined() { grep -q '^02:CC:00:00:00:14|_printer._tcp.local|ty=Made Up LaserJet 1000|' "$disc" 2>/dev/null; }; waitfor 15 joined
sleep 1; n1=$(grep -c 5353 "$t/socat.log")
lease '1,3,6,15,44,47' '' add 02:cc:00:00:00:14; lease '1,3,6,15,119,252' '' add 02:cc:00:00:00:05; lease '1,3,6,15' '' old 02:cc:00:00:00:77
sleep 2; n2=$(grep -c 5353 "$t/socat.log")
if joined && [ "$n1" -gt "$n0" ] && [ "$n2" = "$n1" ]; then ok "a device that joins is asked what it is, once; not one that said already, nor a renewal"
else bad "a device joining: $n0 $n1 $n2"; cat "$disc"; fi
unset AR_DISC_DELAY; PATH="$B" service restart_dnsmasq; hook=$(sed -n 's/^dhcp-script=//p' "$R/etc/dnsmasq.conf")
# without socat: Fingerbank still looks every device up, and the page says how to recognise more
: > "$t/fbcurl.args"; mv "$B/socat" "$t/socat.off"; runi service_event start arteriafbnow
[ "$(grep -c interrogate "$t/fbcurl.args")" -ge 3 ] && ok "recognise now asks Fingerbank again about every device, also those it answered before" || { bad "recognise now didn't ask again:"; cat "$t/fbcurl.args"; }
[ "$(fbst ok)" = true ] && [ "$(fbst socat)" = false ] && fbst msg | grep -q "Fingerbank has an answer for [0-9]* of [0-9]* device(s)\. To recognise more.*opkg install socat" \
	&& ok "recognise now without socat: lookups only, and says how to recognise more" || { bad "recognise now, no socat:"; cat "$W/fb.htm"; }
: > "$t/socat.log"; lease '1,3,6,15,44,48' '' add 02:cc:00:00:00:15; sleep 2
[ ! -s "$t/socat.log" ] && ok "without socat, a device joining asks nothing" || bad "a join without socat ran socat" 
mv "$t/socat.off" "$B/socat"
for d in "$B" "$N"; do mv -f "$d/wl.real" "$d/wl"; done
mv -f "$t/curl.fb" "$B/curl"; rm -f "$B/socat"
cp "$t/leases.before" "$R/var/lib/misc/dnsmasq.leases"; cp "$t/arp.before" "$t/proc/net/arp"
printf 'BADKEY0123456789BADKEY01\n' > "$fbk"; lease '1,3,6,15,44' '' add 02:cc:00:00:00:01
runi service_event start arteria; fb_refused() { grep -q badkey "$R/tmp/arteria/fb_state" 2>/dev/null; }; waitfor 10 fb_refused
runi service_event start arteriastop; waitfor 6 sampler_gone
runi status > "$t/st.out" 2>&1
fb_refused && grep -q 'KEY TURNED DOWN' "$t/st.out" && ok "a key Fingerbank turns down later stops the lookups, and status says so" || { bad "refused later:"; cat "$t/st.out"; }

# The page's Settings: the key arrives through the Addons API's shared settings file, which the router's web server
# rewrites with what the page sent (values cut at their first space, plus the key). The router takes the key out and
# puts back the copy it made just before, so every other addon's setting is exactly as it was; fb.htm tells the page.
cs="$R/jffs/addons/custom_settings.txt"
printf 'otheraddon_title Cool Addon 1.0\notheraddon_mode on\n' > "$cs"; cp "$cs" "$t/cs.before"
# commands that get their arguments on a command line ([, test, printf, echo are programs on the router): they log them
mkdir -p "$t/argv"; for c in '[' test printf echo expr; do printf '#!%s sh\necho "$*" >> "%s/argv.log"\nexec "%s" "%s" "$@"\n' "$bb" "$t" "$bb" "$c" > "$t/argv/$c"; chmod +x "$t/argv/$c"; done
runw() { AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$t/argv:$B" BASH_ENV="$t/no-builtins.sh" "$bash_bin" "$script" "$@"; }
runi service_event start arteriafboff
[ "$(fbst on)" = false ] && [ "$(fbst ok)" = true ] && fbst msg | grep -q '^Fingerbank is off' && [ ! -e "$fbk" ] && cmp -s "$cs" "$t/cs.before" \
	&& ok "settings page: turning Fingerbank off" || { bad "settings page, off:"; cat "$W/fb.htm"; }
runi service_event start arteriafbprep
printf 'otheraddon_title Cool\notheraddon_mode on\narteria_fbkey %s\n' "$FBK" > "$cs"   # what httpd writes
: > "$t/argv.log"; : > "$t/fbcurl.args"
runw service_event start arteriafb
if cmp -s "$cs" "$t/cs.before" && [ "$(cat "$fbk" 2>/dev/null)" = "$FBK" ] && [ "$(fbst on)" = true ] && [ "$(fbst tail)" = ef01 ] && [ "$(fbst ok)" = true ] \
	&& fbst msg | grep -q '^Saved\.' && fb_hooked_t() { grep -q "^dhcp-script=$R/tmp/arteria/dhcp_hook" "$R/etc/dnsmasq.conf"; } && fb_hooked_t; then
	ok "settings page: the key saved, every other addon's setting exactly as before (spaces too), dnsmasq hooked"
else bad "settings page, save:"; cat "$cs" "$W/fb.htm"; fi
grep -q "$FBK" "$W/fb.htm" "$t/argv.log" "$t/fbcurl.args" "$R/tmp/arteria/"* 2>/dev/null && { bad "the key turned up where it mustn't:"; grep -l "$FBK" "$W/fb.htm" "$t/argv.log" "$t/fbcurl.args" "$R/tmp/arteria/"*; } \
	|| ok "the key never reaches fb.htm, a command line, curl's arguments or a file in RAM"
runi service_event start arteriafbprep
printf 'otheraddon_title Cool\narteria_fbkey BADKEY0123456789BADKEY01\n' > "$cs"
runi service_event start arteriafb
[ "$(fbst ok)" = false ] && fbst msg | grep -q 'turned this key down' && cmp -s "$cs" "$t/cs.before" && [ "$(cat "$fbk")" = "$FBK" ] \
	&& ok "settings page: a key Fingerbank turns down changes nothing, and says why" || { bad "settings page, refused key:"; cat "$cs" "$W/fb.htm"; }
# a copy older than a minute is never put back (it could undo another addon's save): only the key's line goes
runi service_event start arteriafbprep; touch -d "@$(( $(date +%s) - 120 ))" "$R/tmp/arteria/cs.saved"
printf 'otheraddon_mode off\narteria_fbkey %s\n' "$FBK" > "$cs"
runi service_event start arteriafb
[ "$(cat "$cs")" = "otheraddon_mode off" ] && ok "settings page: an old copy of the settings is never put back, only the key taken out" || { bad "old copy:"; cat "$cs"; }

# off: the key and the answers go, the postconf line goes (the other addon's stay), dnsmasq runs ASUS's script directly again
runi fingerbank off > "$t/fb.out" 2>&1 || bad "fingerbank off failed"
if [ ! -e "$fbk" ] && [ ! -e "$R/jffs/addons/arteria/fingerbank" ] && cmp -s "$R/jffs/scripts/dnsmasq.postconf" "$t/postconf.before" \
	&& cmp -s "$R/etc/dnsmasq.conf" "$t/dnsmasq.base" && ! ls "$R"/tmp/arteria/dhcp_hook.* "$fp" > /dev/null 2>&1; then
	ok "fingerbank off: key, answers, hook and fingerprints gone; dnsmasq as before; the other addon's lines untouched"
else bad "fingerbank off:"; cat "$t/fb.out" "$R/jffs/scripts/dnsmasq.postconf" "$R/etc/dnsmasq.conf"; ls "$R/tmp/arteria"; fi
rm -f "$R/jffs/scripts/dnsmasq.postconf" "$B/curl"

# ---- 4: install and uninstall ----------------------------------------------------------------
printf '#!/bin/sh\n/some/other/script startup &\n' > "$R/jffs/scripts/services-start"
cp "$R/jffs/scripts/services-start" "$t/ss.before"
cp "$R/www/require/modules/menuTree.js" "$t/menu.before"
AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$bb" ash "$script" install < /dev/null > "$t/install.out" 2>&1 || { bad "install failed:"; cat "$t/install.out"; }
page=$(cat "$R/jffs/addons/arteria/webui_page" 2>/dev/null || echo none)
[ "$page" = user1.asp ] && [ -f "$R/www/user/user1.asp" ] && ok "install mounts the page in the first free slot" || bad "page slot: $page"
grep -q 'arteria-version: ' "$R/www/user/user1.asp" && ok "mounted page is Arteria's" || bad "mounted page isn't arteria.asp"
m="$R/tmp/menuTree.js"
# exactly one new line, right after Statistic in Traffic Analyzer; the code lines untouched
if [ "$(grep -c 'tabName: "Arteria"' "$m")" = 1 ] && [ "$(wc -l < "$m")" -eq $(( $(wc -l < "$t/menu.before") + 1 )) ] \
	&& grep -A1 'url: "TrafficAnalyzer_Statistic.asp"' "$m" | tail -n 1 | grep -q 'tabName: "Arteria"' \
	&& [ "$(grep -c 'tab\[index\] = {url: "Main_TrafficMonitor_realtime.asp"' "$m")" = 2 ]; then
	ok "menu: Arteria right after Statistic in Traffic Analyzer, nothing else touched"
else bad "menu:"; cat "$m"; fi
grep -q 'Traffic Analyzer -> Arteria' "$t/install.out" && ok "install points to Traffic Analyzer" || { bad "install output:"; cat "$t/install.out"; }
# A router without Traffic Analyzer (no Trend Micro engine, or not in router mode): last in Network Tools
{ echo 'nvram() { case "$2" in rc_support) echo "mssid 2.4G 5G wl6 amas" ;; esac; }'; sed -n '/^after_tab() {/,/^}/p;/^tab_count() {/p;/^menu_insert() {/,/^}/p' "$script"; } > "$t/menu_fns.sh"
cp "$t/menu.before" "$t/nt.js"
r=$(PATH="$B" "$bb" sh -c ". '$t/menu_fns.sh'; menu_insert '$t/nt.js' '{url: \"user4.asp\", tabName: \"Arteria\"},'; echo \"\$where|\$added\"")
if [ "$r" = "Network Tools|1" ] && [ "$(wc -l < "$t/nt.js")" -eq $(( $(wc -l < "$t/menu.before") + 1 )) ] \
	&& grep -A1 'tabName: "Arteria"' "$t/nt.js" | tail -n 1 | grep -q 'url: "NULL"' \
	&& [ "$(grep -B1 'tabName: "Arteria"' "$t/nt.js" | head -n 1 | grep -c 'Advanced_Wireless_Survey.asp')" = 1 ]; then
	ok "menu without Traffic Analyzer: last in Network Tools"
else bad "Network Tools menu ($r):"; grep -n -B2 -A2 Arteria "$t/nt.js"; fi
grep -q "arteria.sh startup & # arteria" "$R/jffs/scripts/services-start" && grep -q 'service_event "$@" & # arteria' "$R/jffs/scripts/service-event" && ok "hooks added" || bad "hooks missing"
grep -qi "key login works\|Node(s) without the key" "$t/install.out" && ok "install checks node access" || { bad "install didn't check the nodes:"; cat "$t/install.out"; }

# ---- 5: update and update dev install only a whole download of the right version --------------
# A stand-in curl serves GitHub's addresses from $t/srv: the latest release's tag, branches, raw files.
srv=$t/srv; mkdir -p "$srv/api/branches" "$srv/raw"
cat > "$B/curl" <<EOF
#!$bb sh
o=""; w=""; url=""
while [ \$# -gt 0 ]; do
	case "\$1" in -o) o=\$2; shift ;; -w) w=\$2; shift ;; -H|--retry|--connect-timeout) shift ;; -*) ;; *) url=\$1 ;; esac
	shift
done
echo "\$url" >> "$t/curl.log"
[ -f "$t/offline" ] && { [ -n "\$w" ] && printf 000; exit 7; }   # no connection
case "\$url" in
	https://raw.githubusercontent.com/IfSugar/arteria/*) f="$srv/raw/\${url#https://raw.githubusercontent.com/IfSugar/arteria/}" ;;
	https://api.github.com/repos/IfSugar/arteria/releases/latest) f="$srv/api/latest" ;;
	https://api.github.com/repos/IfSugar/arteria/branches/*) f="$srv/api/branches/\${url#https://api.github.com/repos/IfSugar/arteria/branches/}" ;;
	*) f=/nonexistent ;;
esac
if [ -f "\$f" ]; then if [ -n "\$o" ]; then cat "\$f" > "\$o"; else cat "\$f"; fi; [ -n "\$w" ] && printf 200; exit 0; fi
[ -n "\$w" ] && printf 404
exit 22
EOF
chmod +x "$B/curl"
cur=$(sed -n 's/^VERSION="\([0-9.]*\)".*/\1/p' "$script")
release() {   # dir version: a whole release of this script and page, renumbered
	mkdir -p "$srv/raw/$1"
	sed "s/^VERSION=\"$cur\"/VERSION=\"$2\"/" "$script" > "$srv/raw/$1/arteria.sh"
	sed "s/arteria-version: $cur /arteria-version: $2 /" "$asp" > "$srv/raw/$1/arteria.asp"
}
upd() { AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$bb" ash "$R/jffs/addons/arteria/arteria.sh" "$@" < /dev/null > "$t/upd.out" 2>&1; }
inst_ver() { sed -n 's/^VERSION="\([0-9.]*\)".*/\1/p' "$R/jffs/addons/arteria/arteria.sh"; }
upd update || true   # nothing published yet: GitHub answers 404
grep -q 'No release of Arteria has been published yet' "$t/upd.out" && grep -q 'update dev' "$t/upd.out" && [ "$(inst_ver)" = "$cur" ] \
	&& ok "update: with no release yet, it says so and points to 'update dev'" || { bad "update, no release:"; cat "$t/upd.out"; }
touch "$t/offline"; upd update || true; rm -f "$t/offline"
grep -q "Couldn't reach GitHub" "$t/upd.out" && ok "update: without a connection, it says so" || { bad "update, offline:"; cat "$t/upd.out"; }
printf '{"tag_name": "%s"}' "$cur" > "$srv/api/latest"; release "$cur" "$cur"
upd update || true; grep -q 'Already up to date' "$t/upd.out" && [ "$(inst_ver)" = "$cur" ] && ok "update: the same version changes nothing" || { bad "update, same version:"; cat "$t/upd.out"; }
printf '{"tag_name": "9.9.9"}' > "$srv/api/latest"; release 9.9.9 9.9.9
sed -i '/^# Keep this dispatch last/,$d' "$srv/raw/9.9.9/arteria.sh"   # cut off before the dispatch: still passes sh -n
upd update || true
grep -q 'looks incomplete' "$t/upd.out" && [ "$(inst_ver)" = "$cur" ] && ok "update: a script cut short is refused" || { bad "update, cut script:"; cat "$t/upd.out"; }
release 9.9.9 9.9.9; head -n 40 "$asp" | sed "s/arteria-version: $cur /arteria-version: 9.9.9 /" > "$srv/raw/9.9.9/arteria.asp"
upd update || true
grep -q 'matching web page' "$t/upd.out" && [ "$(inst_ver)" = "$cur" ] && ok "update: a page cut short is refused" || { bad "update, cut page:"; cat "$t/upd.out"; }
release 9.9.9 9.9.9; sed -i 's/arteria-version: 9.9.9 /arteria-version: 9.9.8 /' "$srv/raw/9.9.9/arteria.asp"
upd update || true
grep -q 'matching web page' "$t/upd.out" && [ "$(inst_ver)" = "$cur" ] && ok "update: a page of another version is refused" || { bad "update, page version:"; cat "$t/upd.out"; }
release 9.9.9 9.9.9; sed -i 's/^INTERVAL=.*/INTERVAL=3/' "$R/jffs/addons/arteria/config"
upd update || true
if [ "$(inst_ver)" = 9.9.9 ] && grep -q 'arteria-version: 9.9.9 ' "$R/jffs/addons/arteria/arteria.asp" && grep -q '^INTERVAL=3' "$R/jffs/addons/arteria/config" \
	&& [ "$(grep -c '# arteria$' "$R/jffs/scripts/services-start")" = 1 ] && [ "$(grep -c '# arteria$' "$R/jffs/scripts/service-event")" = 1 ] && [ ! -f "$R/jffs/addons/arteria/build" ]; then
	ok "update: a newer release is installed, settings kept, one hook line each"
else bad "update to 9.9.9:"; cat "$t/upd.out"; fi
printf '{"tag_name": "%s"}' "$cur" > "$srv/api/latest"
upd update || true; grep -q 'newer than the latest release' "$t/upd.out" && [ "$(inst_ver)" = 9.9.9 ] && ok "update: never goes back to an older release unless forced" || { bad "update, older:"; cat "$t/upd.out"; }
: > "$t/curl.log"; badnames=""
for br in 'a..b' '-x' 'refs/heads/main' 'a b' 'pull/1/head' '/x' 'x/'; do
	upd update dev "$br" || true
	grep -q "isn't a branch name" "$t/upd.out" || badnames="$badnames [$br]"
done
[ -z "$badnames" ] && [ ! -s "$t/curl.log" ] && ok "update dev: refuses what isn't a branch name, before any download" || { bad "update dev names:$badnames"; cat "$t/curl.log"; }
sha=0123456789abcdef0123456789abcdef01234567
mkdir -p "$srv/api/branches/fix"; printf '{"name": "fix/menu", "commit": {"sha": "%s"}}' "$sha" > "$srv/api/branches/fix/menu"; release "$sha" 9.9.10
upd update dev fix/menu || true
if [ "$(inst_ver)" = 9.9.10 ] && grep -q "^dev fix/menu 0123456 " "$R/jffs/addons/arteria/build" 2>/dev/null \
	&& ! grep -v "/$sha/\|branches/fix/menu" "$t/curl.log" | grep -q .; then
	ok "update dev <branch>: that branch's newest commit, fetched by its commit id, marked as a development version"
else bad "update dev fix/menu:"; cat "$t/upd.out" "$t/curl.log"; fi
# back to a release from a development version: the same number is installed again, and install takes the mark away
printf '{"tag_name": "9.9.10"}' > "$srv/api/latest"; release 9.9.10 9.9.10
upd update || true
if grep -q "Updating" "$t/upd.out" && [ "$(inst_ver)" = 9.9.10 ] && [ ! -f "$R/jffs/addons/arteria/build" ]; then
	ok "update: from a development version back to the release, the mark is gone"
else bad "update after update dev:"; cat "$t/upd.out"; fi
# with Fingerbank on, uninstall also takes Arteria's line out of dnsmasq.postconf and gives dnsmasq back its own lease script
printf 'abcdef0123456789abcdef0123456789abcdef01\n' > "$R/jffs/addons/arteria/fingerbank_key"
printf '#!/bin/sh\n%s dnsmasq_conf "$1" # arteria\n' "$R/jffs/addons/arteria/arteria.sh" > "$R/jffs/scripts/dnsmasq.postconf"; chmod 755 "$R/jffs/scripts/dnsmasq.postconf"
PATH="$B" service restart_dnsmasq; grep -q "^dhcp-script=$R/tmp/arteria/dhcp_hook" "$R/etc/dnsmasq.conf" || bad "the Fingerbank hook didn't take before uninstall"
# an update (a reinstall) rewrites the lease script dnsmasq is running, still handing on to the router's own
h=$(sed -n 's/^dhcp-script=//p' "$R/etc/dnsmasq.conf"); grep -v discnew "$h" > "$t/oldhook"; cat "$t/oldhook" > "$h"
AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$bb" ash "$script" install < /dev/null > "$t/reinst.out" 2>&1 || { bad "reinstall failed:"; cat "$t/reinst.out"; }
grep -q ' discnew ' "$h" && grep -q "^exec $t/dhcpc_lease \"\$@\"$" "$h" && [ "$(sed -n 's/^dhcp-script=//p' "$R/etc/dnsmasq.conf")" = "$h" ] \
	&& ok "an update rewrites dnsmasq's running lease script in place, still handing on to the router's" || { bad "rewriting the lease script:"; cat "$h"; }
AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$bb" ash "$R/jffs/addons/arteria/arteria.sh" uninstall > "$t/uninstall.out" 2>&1 || bad "uninstall failed"
[ ! -e "$R/jffs/scripts/dnsmasq.postconf" ] && cmp -s "$R/etc/dnsmasq.conf" "$t/dnsmasq.base" && ok "uninstall with Fingerbank on: dnsmasq gets its own lease script back" || { bad "uninstall, Fingerbank:"; cat "$R/etc/dnsmasq.conf"; }
[ ! -e "$R/jffs/addons/arteria" ] && [ ! -e "$R/www/user/user1.asp" ] && ok "uninstall removes the addon and its page" || bad "files left after uninstall"
grep -q 'arteria' "$t/router-authkeys" 2>/dev/null && { bad "uninstall left the key in the router's list:"; cat "$t/router-authkeys"; } || ok "uninstall takes the key out of the router's own list"
cmp -s "$R/jffs/scripts/services-start" "$t/ss.before" && ok "other scripts' hook lines untouched" || { bad "services-start changed:"; cat "$R/jffs/scripts/services-start"; }
grep -q Arteria "$m" && bad "menu line left behind" || ok "menu line removed"

# A page someone planted next to the installer (a link, or a file that isn't root's own) is never installed:
# the real one is downloaded from the release instead.
mkdir -p "$t/inst"; cp "$script" "$t/inst/arteria.sh"
printf 'PLANTED <!-- arteria-version: %s -->\n</html>\n' "$cur" > "$t/planted.asp"; ln -s "$t/planted.asp" "$t/inst/arteria.asp"
printf '{"tag_name": "%s"}' "$cur" > "$srv/api/latest"; release "$cur" "$cur"; : > "$t/curl.log"
AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$bb" ash "$t/inst/arteria.sh" install < /dev/null > "$t/inst.out" 2>&1 || true
if ! grep -q PLANTED "$R/jffs/addons/arteria/arteria.asp" 2>/dev/null && grep -q "arteria-version: $cur " "$R/jffs/addons/arteria/arteria.asp" && grep -q "/$cur/arteria.asp" "$t/curl.log"; then
	ok "install: a page planted next to the installer is ignored, the release's is downloaded"
else bad "planted page:"; cat "$t/inst.out"; head -3 "$R/jffs/addons/arteria/arteria.asp"; fi
AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$bb" ash "$R/jffs/addons/arteria/arteria.sh" uninstall > /dev/null 2>&1 || true

[ $fail -eq 0 ] && echo "Router: all checks passed." || { echo "::error::Router checks failed."; exit 1; }
