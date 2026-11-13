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
	wans_dualwan) cat "$t/dualwan" 2>/dev/null || echo "wan none" ;; wan1_ifname) echo usb0 ;; wan1_proto) echo dhcp ;; wans_mode) echo lb ;;   # a test turns dual WAN on
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
# br0, and a Guest Network Pro bridge (br52) that reaches LAN port eth3 through its VLAN interface eth3.52
cat > "$B/brctl" <<EOF
#!$bb sh
case "\$1 \$2" in
	'showstp br0') printf 'br0\n bridge id\neth1 (4)\n port id\neth5 (5)\neth6 (6)\neth7 (7)\nwds1.0.1 (9)\n' ;;
	'showmacs br0') printf 'port no\tmac addr\t\tis local?\tageing timer\n  5\t02:cc:00:00:00:09\tno\t\t   0.11\n  9\t02:cc:00:00:00:11\tno\t\t   0.20\n  6\t00:00:5e:00:53:fc\tyes\t\t   0.00\n' ;;
	'showstp br52') printf 'br52\n bridge id\neth3.52 (1)\n port id\nwl0.2 (2)\n' ;;
	'showmacs br52') printf 'port no\tmac addr\t\tis local?\tageing timer\n  1\t02:cc:00:00:00:52\tno\t\t   1.10\n  1\t02:cc:00:00:00:09\tno\t\t   1.10\n' ;;
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
  usb0: 1234567890 900000 0 0 0 0 0 0 98765432 400000 0 0 0 0 0 0
EOF
printf 'IP address       HW type     Flags       HW address            Mask     Device\n192.168.50.30    0x1         0x2         02:cc:00:00:00:01     *        br0\n192.168.50.31    0x1         0x0         00:00:00:00:00:00     *        br0\n' > "$t/proc/net/arp"
printf '#!%s sh\n[ "$1 $2 $3" = "-6 neigh show" ] && printf "2001:db8::12 lladdr 02:cc:00:00:00:12 REACHABLE\\nfe80::12 lladdr 02:cc:00:00:00:12 STALE\\n2001:db8::99 FAILED\\n"\n' "$bb" > "$B/ip"
echo "25588.76 90000.00" > "$t/proc/uptime"; echo "1.39 1.28 1.27 3/216 4894" > "$t/proc/loadavg"
for i in eth0 eth1 eth2 eth3 eth4 eth5 eth6 eth7 br0; do mkdir -p "$t/sys/class/net/$i"; done
mkdir -p "$t/sys/class/net/br0/bridge" "$t/sys/class/net/br52/bridge"   # the LAN bridges
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
printf '#!%s sh\n[ -f "%s/node-cut-crash" ] && kill -SEGV $$\nexec "%s" cut "$@"\n' "$bb" "$t" "$bb" > "$N/cut"   # a node whose cut can crash
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
keys=""; while [ \$# -gt 1 ]; do [ "\$1" = -i ] && keys="\$keys \$2"; shift; done
# root's own key (it says "userkey") opens the node only when a test says so; Arteria's key ("key") as below
own=0; user=0; for k in \$keys; do [ -s "\$k" ] || continue; if [ "\$(cat "\$k")" = userkey ]; then [ -f "$t/node-accepts-user" ] && user=1; else own=1; fi; done
# the node's identity (host key), only when a test sets one. Like Dropbear's dbclient: a host seen for the first
# time is pinned only with -y; without it, it prints the fingerprint and refuses (no terminal, or BatchMode).
if [ -f "$t/node-identity" ]; then
	kh="\$HOME/.ssh/known_hosts"; id=\$(cat "$t/node-identity")
	if grep -q "^192.168.50.10 " "\$kh" 2>/dev/null; then
		grep -qx "192.168.50.10 ssh-ed25519 \$id" "\$kh" || { printf 'dbclient: Connection to admin@192.168.50.10:2222 exited:\\n\\nHost key mismatch for 192.168.50.10 !\\nIf you know that the host key is correct you can\\nremove the bad entry from ~/.ssh/known_hosts\\n' >&2; exit 1; }
	elif [ \$y = 1 ]; then mkdir -p "\$HOME/.ssh"; echo "192.168.50.10 ssh-ed25519 \$id" >> "\$kh"
	else printf "\\nHost '192.168.50.10' is not in the trusted hosts file.\\n(ssh-ed25519 fingerprint SHA256:%s)\\n\\ndbclient: Connection to admin@192.168.50.10:2222 exited: Didn't validate host key\\n" "\$id" >&2; exit 1; fi
	# a password typed at a terminal (nodekey): the right one, always
	if [ -z "\$keys" ] && [ -t 0 ]; then echo "password login to \$id" >> "$t/dbclient.pw"; exec env PATH="$N:$B" "$bb" sh -c "\$1"; fi
	# Arteria's key works only once the node lists it
	grep -q AAAAC3NzaC1lZDI1NTE5AAAAITEST "$t/node-authkeys" 2>/dev/null || own=0
fi
[ \$own = 1 ] || [ \$user = 1 ] || { echo "dbclient: Connection to admin@192.168.50.10:2222 exited: No auth methods could be used." >&2; exit 1; }
echo "\$1" >> "$t/dbclient.cmds"
[ "\$1" = 'sh -s' ] || exec env PATH="$N:$B" "$bb" sh -c "\$1"
# The page's session: like the real dbclient it stays this process (Arteria stops it by its pid, and checks that the pid is a
# dbclient), and stopping it ends the node's side. AR_NODE_SESSION marks the node's side, so a test can see that it's gone.
exec 3<&0
if [ -f "$t/node-hostile" ]; then env AR_NODE_SESSION="$t" "$bb" sh "$t/node-hostile" <&3 3<&- &   # a node that sends anything but counters
else env AR_NODE_SESSION="$t" PATH="$N:$B" "$bb" sh -s <&3 3<&- &
fi
c=\$!; exec 3<&-
trap 'kill \$c 2>/dev/null; exit 0' TERM INT HUP
wait \$c
EOF
printf '#!%s sh\nf=""; while [ $# -gt 0 ]; do [ "$1" = -f ] && f=$2; shift; done\n[ -n "$f" ] && printf "key\\n" > "$f" && echo pub > "$f.pub"\necho "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITEST admin@router"\n' "$bb" > "$B/dropbearkey"
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
assert s['macs'] == [['eth5', '02:CC:00:00:00:09'], ['eth3', '02:CC:00:00:00:52']], s['macs']   # Guest Network Pro's br52 too, each address once
n = s['nodes'][0]
assert n['mac'] == '02:10:00:00:00:80' and n['ip'] == '192.168.50.10' and n['model'] == 'RP-AX56' and n['alias'] == 'Hall', n
assert n['sta'].split() == ['02:10:00:00:00:81', '02:10:00:00:00:84'], n['sta']
assert n['state'] == 'nokey' and n['c'] == [], n
assert '00:00:5E:00:53:FC' in s['own']
assert s['router']['model'] == 'RT-AX86U' and s['router']['fw'] == '3004.388.13_0', s['router']
EOF
# dual WAN: the second WAN (a USB modem here) is sampled too, and named in the sample
echo "wan usb" > "$t/dualwan"; runa sample > "$t/sample-dw.json" 2>/dev/null || true; rm -f "$t/dualwan"
python3 - "$t/sample-dw.json" "$t/sample.json" <<'EOF' && ok "dual WAN: the second WAN's interface is sampled and named; without it, nothing changes" || fail=1
import json, sys
s, one = json.load(open(sys.argv[1])), json.load(open(sys.argv[2]))
ifs = {r[0]: r for r in s['ifs']}
assert s['wan'] == 'eth0' and s['wan2'] == 'usb0' and ifs['usb0'][1:] == ['1234567890', '98765432'], (s['wan2'], s['ifs'])
assert one['wan2'] == '' and 'usb0' not in [r[0] for r in one['ifs']], one['wan2']
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
# a rename on the page: it saves the router's client list, then asks for the names at once, not in 30 s
rm -f "$W/names.htm"; runi service_event start arterianames
grep -q 'Living room TV' "$W/names.htm" 2>/dev/null && [ ! -f "$R/tmp/arteria/sampler.pid" ] \
	&& ok "service event arterianames: names exported at once, the sampler not started" || { bad "arterianames:"; ls "$W"; fail=1; }
# before a rename, the page asks for the router's client list as it is now, with a token: only digits are taken
chmod 777 "$W"; : > "$t/syslog"
(umask 0; runi service_event start arteriacl12345678)
[ "$(stat -c %a "$W")" = 755 ] && [ "$(stat -c %a "$W/clist.htm")" = 644 ] \
	&& ok "the page's files and their folder: only root can change them, whatever umask the router starts it with" || { bad "permissions:"; ls -la "$W"; }
(umask 0; runi service_event start arterianames)
grep -q "renaming a device on the page: read the router's client list ([0-9]* name(s))" "$t/syslog" \
	&& grep -q "renamed a device on the page: the router's client list has [0-9]* name(s) (before: [0-9]*)" "$t/syslog" \
	&& ! grep -q 'Living room\|02:CC' "$t/syslog" && ok "renames are logged: how many names the router's list has before and after, no names or addresses" \
	|| { bad "rename log:"; cat "$t/syslog"; }
for bad in 'arteriacl' 'arteriacl12x' 'arteriacl1234567890123' 'arteriacl1;reboot'; do runi service_event start "$bad"; done
python3 - "$W/clist.htm" <<'EOF' && ! grep -q '<' "$W/clist.htm" && ok "service event arteriacl<token>: the router's client list now, with the page's token" || { bad "arteriacl:"; cat "$W/clist.htm"; fail=1; }
import json, sys
c = json.load(open(sys.argv[1]))
assert c['tok'] == '12345678' and 'Living room TV>02:CC:00:00:00:05' in c['custom'] and 'Kids "tablet"\\' in c['custom'], c
EOF
runi service_event start arteria
waitfor 10 seq_at_least 2
python3 - "$W/live.htm" <<'EOF' && ok "without the key: node is 'nokey', its clients aren't read" || fail=1
import json, sys
s = json.load(open(sys.argv[1]))
n = s['nodes'][0]
assert n['state'] == 'nokey' and n['c'] == [], n
assert s['seq'] >= 2, s['seq']
EOF
tries=$(cat "$R/tmp/arteria/"node.*.err 2>/dev/null | grep -c 'No auth')   # with no key at all, none is tried
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
# no session left: neither the stand-in dbclient nor the node side it runs
no_session() { ! pgrep -f "$B/dbclient" > /dev/null 2>&1 && ! grep -qsa "AR_NODE_SESSION=$t" /proc/[0-9]*/environ; }
waitfor 6 no_session
no_session && ok "node session ends with the sampler" || { bad "the node session outlived the page:"; pgrep -af "$B/dbclient"; }
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
printf 'printf "#B 1\\n#E\\n#B 99999999999999999999\\n#E\\n"\nexec sleep 30\n' > "$t/node-hostile"
rm -rf "$R/tmp/arteria" "$W"; runi service_event start arteria
node_ok() { grep -q '"state":"ok"' "$W/live.htm" 2>/dev/null; }
waitfor 10 node_ok
node_ok && ok "a node whose uptimes make no sense still counts as answering (its pace is capped)" || { bad "a node with absurd uptimes:"; grep -o '"nodes":.*' "$W/live.htm" | head -c 300; echo; }
runi service_event start arteriastop
waitfor 6 sampler_gone; waitfor 6 no_session
rm -f "$t/node-hostile"; rm -rf "$R/tmp/arteria" "$W"

# nodes test: key login, then one round of the page's own node script: how many devices, how long. A node where that
# round fails (the session drops) says so, with addresses and user names taken out of the message.
run nodes test > "$t/nt.out" 2>&1 || true
grep -q "key login OK (Arteria's key), reads [0-9][0-9]* device(s), one round takes about [0-9][0-9]* s$" "$t/nt.out" \
	&& ok "nodes test: key login, then the node's devices read by the page's own script, with the time it takes" \
	|| { bad "nodes test:"; cat "$t/nt.out"; }
printf 'echo "dbclient: Connection to admin@192.168.50.10:2222 exited: Remote closed the connection" >&2\nexit 1\n' > "$t/node-hostile"
run nodes test > "$t/nt.out" 2>&1 || true; rm -f "$t/node-hostile"
grep -q "key login OK (Arteria's key), reading its devices failed: dbclient: Connection to user@IP:2222 exited: Remote closed the connection" "$t/nt.out" \
	&& ok "nodes test: a node whose session breaks says why, without its address or user name" \
	|| { bad "nodes test, broken session:"; cat "$t/nt.out"; }
touch "$t/node-cut-crash"; rm -f "$R/tmp/arteria/node-trace.txt"; run nodes test > "$t/nt.out" 2>&1 || true; rm -f "$t/node-cut-crash"
tr="$R/tmp/arteria/node-trace.txt"
grep -q "something on the node crashed running: cut .* (what it ran is in .*/node-trace.txt, without addresses)$" "$t/nt.out" \
	&& grep -q '^+ cut ' "$tr" && grep -q 'Segmentation fault' "$tr" && ! grep -qi '02:CC\|192\.168' "$tr" \
	&& ok "nodes test: when something crashes on the node, what it ran is saved, without addresses" || { bad "nodes test, a crash on the node:"; cat "$t/nt.out"; head -n 20 "$tr" 2>/dev/null; }
printf 'echo "#B 1"\necho "Segmentation fault" >&2\nexit 139\n' > "$t/node-hostile"
rm -rf "$R/tmp/arteria" "$W"; runi service_event start arteria
node_crash() { grep -q '"state":"crash"' "$W/live.htm" 2>/dev/null; }
waitfor 10 node_crash
node_crash && ok "a node where something crashes shows as 'crash', not 'not answering'" || { bad "node crash state:"; grep -o '"nodes":.*' "$W/live.htm" | head -c 300; echo; }
runi service_event start arteriastop; waitfor 6 sampler_gone; waitfor 6 no_session; rm -f "$t/node-hostile"; rm -rf "$R/tmp/arteria" "$W"
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
nk() { AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" AR_SSHD_WAIT=0 PATH="$B" "$py" "$t/term.py" "$bb" "$inst" "$1" 2>&1 || true; }   # answer
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
	[ -s "$R/jffs/addons/arteria/node_key" ] && ! ls "$R/jffs/addons/arteria/" | grep -q '\.new' \
		&& ok "nodekey: a new key leaves no temporary files behind (newer dropbearkey writes a .pub next to it)" || { bad "files left by a new key:"; ls "$R/jffs/addons/arteria/"; }
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
	if grep -q "Password login over SSH is off on the router" "$t/nk-nopass.out" && grep -q "reboot it" "$t/nk-nopass.out" && grep -q "nodes test" "$t/nk-nopass.out" \
		&& [ ! -f "$t/dbclient.pw" ] && grep -q 'AAAAC3NzaC1lZDI1NTE5AAAAITEST arteria' "$t/router-authkeys"; then
		ok "nodekey with password login off: no password asked, the key waits in the router's list, and it says to reboot the node"
	else bad "nodekey with password login off:"; cat "$t/nk-nopass.out"; fi
	# A router already set up for passwordless logins to its nodes (the forum's guide, the Wireless Report addon): root's
	# own key (~/.ssh/id_dropbear) opens the node, and root's known_hosts pins it. nodekey finds that, adds nothing, asks nothing.
	rm -rf "$R/jffs/addons/arteria/.ssh" "$t/dbclient.pw"; : > "$t/node-authkeys"; cp "$t/router-authkeys" "$t/rk.before"
	mkdir -p "$R/tmp/home/root/.ssh"; echo userkey > "$R/tmp/home/root/.ssh/id_dropbear"; echo USERPIN > "$t/node-identity"; touch "$t/node-accepts-user"
	echo "192.168.50.10 ssh-ed25519 USERPIN" > "$R/tmp/home/root/.ssh/known_hosts"
	nk y > "$t/nk-user.out"
	if grep -q "Key login works with /tmp/home/root/.ssh/id_dropbear, the key root on this router already uses for the nodes: nothing to add" "$t/nk-user.out" \
		&& grep -q "Trusted its SSH identity as root on this router already does" "$t/nk-user.out" && ! grep -q "(y/n)" "$t/nk-user.out" \
		&& [ ! -f "$t/dbclient.pw" ] && cmp -s "$t/router-authkeys" "$t/rk.before" && [ ! -s "$t/node-authkeys" ]; then
		ok "nodekey on a router with passwordless logins to its nodes: uses root's key and pin, adds and asks nothing"
	else bad "nodekey with root's own key:"; cat "$t/nk-user.out"; fi
	# root's known_hosts pins the node, but no key opens it: a password would follow, so nodekey forgets the copied pin and
	# asks first, with the fingerprint, as for a node it has never seen. No: no password, nothing pinned.
	rm -rf "$R/jffs/addons/arteria/.ssh" "$t/dbclient.pw" "$t/node-accepts-user"; : > "$t/node-authkeys"
	nk n > "$t/nk-rootpin.out"; touch "$t/node-accepts-user"
	if grep -q "hasn't connected to 192.168.50.10 before" "$t/nk-rootpin.out" && grep -q "SHA256:USERPIN" "$t/nk-rootpin.out" \
		&& [ ! -f "$t/dbclient.pw" ] && ! grep -q USERPIN "$R/jffs/addons/arteria/.ssh/known_hosts" 2>/dev/null; then
		ok "nodekey: a node pinned only in root's known_hosts gets no password until its fingerprint is confirmed"
	else bad "nodekey, root's pin and no working key:"; cat "$t/nk-rootpin.out"; fi
else echo "skip  nodekey at a terminal (python3 has no pty module here)"; fi
# The page's sessions with root's own key: no Arteria key at all, the node pinned only in root's known_hosts
if [ -f "$t/node-accepts-user" ]; then
	rm -rf "$R/jffs/addons/arteria/.ssh" "$R/tmp/arteria"; rm -f "$R/jffs/addons/arteria/node_key"; : > "$t/syslog"
	runi service_event start arteria
	waitfor 12 node_read
	if grep -q '"state":"ok"' "$W/live.htm" && grep -q USERPIN "$R/jffs/addons/arteria/.ssh/known_hosts" && grep -q "trusted node 192.168.50.10's SSH identity as root's own known_hosts does" "$t/syslog"; then
		ok "a router with passwordless logins to its nodes: the page reads them with root's key, nothing to set up"
	else bad "sampler with root's own key:"; head -c 400 "$W/live.htm"; cat "$R"/tmp/arteria/node.*.err; fi
	run status > "$t/st-user.out" 2>&1 || true
	grep -q '^Node access: on, key present' "$t/st-user.out" && ok "status: root's own key counts as the key" || { bad "status with root's key:"; grep '^Node access' "$t/st-user.out"; }
	run nodes test > "$t/nt-user.out" 2>&1 || true
	grep -q 'key login OK (/tmp/home/root/.ssh/id_dropbear), reads' "$t/nt-user.out" && ok "nodes test names the key that works" || { bad "nodes test with root's key:"; cat "$t/nt-user.out"; }
	run debug > "$t/debug-user.out" 2>&1 || true
	grep -q '^Node keys:   /tmp/home/root/.ssh/id_dropbear$' "$t/debug-user.out" && grep -q 'state=ok, a round every [0-9]* s, last output [0-9]* s ago, 5 station(s)' "$t/debug-user.out" \
		&& ok "debug: the node keys, and each node's pace, freshness and devices while the page is open" || { bad "debug, nodes:"; grep -A3 '^Node' "$t/debug-user.out"; }
	runi service_event start arteriastop; waitfor 6 sampler_gone; waitfor 6 no_session
	no_sampler() { ! pgrep -f "$inst sampler" > /dev/null 2>&1; }; waitfor 10 no_sampler   # gone, not only its pid file
	rm -rf "$R/tmp/home" "$t/node-accepts-user" "$R/tmp/arteria" "$W"
fi
# The sampler pins no node by itself (only one root's known_hosts already pins): one seen for the first time is "nokey"
# (run nodekey) and stays unpinned
rm -rf "$R/jffs/addons/arteria/.ssh" "$R/tmp/arteria"; echo FIRSTKEY > "$t/node-identity"; printf 'key\n' > "$R/jffs/addons/arteria/node_key"
runi service_event start arteria
node_tried() { grep -q "trusted hosts" "$R"/tmp/arteria/node.*.err 2>/dev/null && seq_at_least 2; }
waitfor 10 node_tried
if grep -q '"state":"nokey"' "$W/live.htm" 2>/dev/null && ! grep -q FIRSTKEY "$R/jffs/addons/arteria/.ssh/known_hosts" 2>/dev/null; then
	ok "the sampler doesn't pin a node it has never seen: it says to run nodekey"
else bad "sampler and an unknown node:"; grep -o '"nodes":.*' "$W/live.htm" | head -c 300; echo; cat "$R"/tmp/arteria/node.*.err; cat "$R/jffs/addons/arteria/.ssh/known_hosts" 2>/dev/null; ls -la "$R/tmp/home/root/.ssh" 2>&1; fi
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

# ---- 3b: the guard: Arteria leaves a busy or overloaded router alone -------------------------------
# Busy (load at least 2 per core, or under 48 MB available): it samples a third as often and starts no node sessions.
# Overloaded (4 per core, or under 24 MB) when the page opens, or three rounds in a row: it pauses for 2 minutes,
# says why on the page and in the system log, and the page's requests don't start it again meanwhile.
lav() { echo "$1 1.00 1.00 3/216 4894" > "$t/proc/loadavg"; }
printf 'processor\t: 0\nprocessor\t: 1\n' > "$t/proc/cpuinfo"
paused_by() { grep -q "\"paused\":\"$1\"" "$W/live.htm" 2>/dev/null; }
paused_load() { paused_by load; }; paused_mem() { paused_by memory; }
lav 9.50; : > "$t/syslog"
runi service_event start arteria
waitfor 8 paused_load
if paused_load && [ -f "$R/tmp/arteria/paused" ] && grep -q 'paused for 2 minutes: the router is busy (load 9.50 on 2 cores)' "$t/syslog"; then
	ok "guard: an overloaded router (load 4 per core) isn't sampled: the page and the log say why"
else bad "guard, overloaded at the start:"; head -c 300 "$W/live.htm"; cat "$t/syslog"; fi
waitfor 4 sampler_gone; runi service_event start arteria; sleep 1
sampler_gone && ok "guard: for 2 minutes after a pause the page's requests don't start it again" || bad "guard: the sampler started again during the pause"
lav 0.50; run status > "$t/status.out" 2>&1 || true
grep -q '^Last pause: .*the router is busy (load 9.50 on 2 cores) (resumes within 2 minutes)' "$t/status.out" && grep -q '^Router:  *load 0.50 on 2 cores' "$t/status.out" \
	&& ok "status: the router's load now, its memory, and the last pause with the load it saw then" || { bad "status, after a pause:"; cat "$t/status.out"; }
lav 0.50; printf 'MemTotal: 500000 kB\nMemFree: 9000 kB\nMemAvailable: 20000 kB\n' > "$t/proc/meminfo"; rm -f "$R/tmp/arteria/paused"
runi service_event start arteria
waitfor 8 paused_mem
paused_mem && grep -q 'low on memory (19 MB available)' "$t/syslog" && ok "guard: a router low on memory (under 24 MB available) isn't sampled" || { bad "guard, memory:"; head -c 300 "$W/live.htm"; cat "$t/syslog"; }
waitfor 4 sampler_gone
# busy: sampled a third as often, never paused; then overloaded for three rounds while sampling: it pauses.
# The page was open before with the node read: while busy, the node isn't shown from that old output, and gets no session.
printf 'MemTotal: 500000 kB\nMemAvailable: 300000 kB\n' > "$t/proc/meminfo"; lav 0.50; rm -f "$R/tmp/arteria/paused"
runi service_event start arteria; waitfor 12 node_read
runi service_event start arteriastop; waitfor 6 sampler_gone; waitfor 6 no_session
s0=$(grep -c "sh -s" "$t/dbclient.cmds"); rm -f "$W/live.htm"; lav 4.50; : > "$t/syslog"
runi service_event start arteria
waitfor 10 seq_at_least 1
python3 - "$W/live.htm" <<'EOF' && [ "$(grep -c "sh -s" "$t/dbclient.cmds")" = "$s0" ] && ok "guard: a busy router (load 2 per core) is sampled a third as often, opens no node session, and the sample says so" || { bad "guard, busy: $(grep -c "sh -s" "$t/dbclient.cmds") sessions, $s0 before"; fail=1; }
import json, sys
s = json.load(open(sys.argv[1]))
assert s['interval'] == 3 and s['router']['busy'] == 1 and s['router']['cpus'] == 2 and s['router']['mem'] == 292, (s['interval'], s['router'])
n = s['nodes'][0]
assert n['state'] == 'busy' and n['c'] == [], n   # not 'down' with the clients of the last time
EOF
lav 9.50
waitfor 20 paused_load
paused_load && ! grep -q '"seq"' "$W/live.htm" && ok "guard: overloaded three rounds in a row while sampling, it pauses" || { bad "guard, overloaded while sampling:"; head -c 300 "$W/live.htm"; }
waitfor 4 sampler_gone
grep -q 'paused for 2 minutes' "$t/syslog" && ! grep -q 'sampling stopped (page closed)' "$t/syslog" && ok "a pause isn't logged as the page closing" || { bad "log after a pause:"; cat "$t/syslog"; }
runi service_event start arteriastop
lav 1.39; rm -f "$t/proc/cpuinfo" "$t/proc/meminfo"; rm -rf "$R/tmp/arteria" "$W"

# ---- 4: install and uninstall ----------------------------------------------------------------
printf '#!/bin/sh\n/some/other/script startup &\n' > "$R/jffs/scripts/services-start"
cp "$R/jffs/scripts/services-start" "$t/ss.before"
# 1.0.0's hook line, which started the script for every service event on the router: install replaces it
printf '#!/bin/sh\n/some/other/script event "$@" &\n%s/jffs/addons/arteria/arteria.sh service_event "$@" & # arteria\n' "$R" > "$R/jffs/scripts/service-event"
cp "$R/www/require/modules/menuTree.js" "$t/menu.before"
# what an older version's key setup, or a development version's device recognition, may have left
d="$R/jffs/addons/arteria"; mkdir -p "$d"; echo key > "$d/node_key"
for f in node_key.new.pub discovered fingerbank fingerbank_key; do echo x > "$d/$f"; done
AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$bb" ash "$script" install < /dev/null > "$t/install.out" 2>&1 || { bad "install failed:"; cat "$t/install.out"; }
[ -s "$d/node_key" ] && ! ls "$d" | grep -q '\.new\|discovered\|fingerbank' \
	&& ok "install tidies files older or development versions left, and keeps the node key" || { bad "after install:"; ls "$d"; }
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
grep -q "arteria.sh startup & # arteria" "$R/jffs/scripts/services-start" && grep -q 'service_event "$@" & ;; esac # arteria' "$R/jffs/scripts/service-event" && ok "hooks added" || bad "hooks missing"
se="$R/jffs/scripts/service-event"
if [ "$(grep -c '# arteria$' "$se")" = 1 ] && grep -q '^case "\$2" in arteria\*) .*arteria\.sh service_event "\$@" & ;; esac # arteria$' "$se" && grep -q '^/some/other/script event' "$se"; then
	ok "the service-event hook replaces 1.0.0's line, and other scripts' lines stay"
else bad "service-event hook:"; cat "$se"; fi
hook() { AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$bb" sh "$se" "$@" 2>/dev/null; }   # the other script's line isn't there to run
rm -f "$R/tmp/arteria/heartbeat"; hook restart wan; sleep 1
[ ! -f "$R/tmp/arteria/heartbeat" ] && ok "the hook starts Arteria for its own events only, not for the router's others" || bad "the hook ran Arteria for 'restart wan'"
hook start arteria; hb_made() { [ -f "$R/tmp/arteria/heartbeat" ]; }; waitfor 5 hb_made
hb_made && ok "the hook passes the page's request on" || bad "the hook didn't pass 'start arteria' on"
hook start arteriastop; waitfor 6 sampler_gone; waitfor 6 no_session
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
# doctor: the known problems, found, then fixed. What going back to 1.0.0 leaves (its own hook line next to today's), a
# file an old version left, page files anyone could change, a client list copy left after the page closed, a node
# session left running; then a command that crashes on the node. Never a name, MAC or IP in what it says.
doc() { AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$bb" ash "$R/jffs/addons/arteria/arteria.sh" doctor "$@" > "$t/doc.out" 2>&1; }
printf '%s/jffs/addons/arteria/arteria.sh service_event "$@" & # arteria\n' "$R" >> "$R/jffs/scripts/service-event"
echo pub > "$R/jffs/addons/arteria/node_key.new.pub"
mkdir -p "$W"; echo '{}' > "$W/clist.htm"; chmod 777 "$W"; chmod 666 "$W/clist.htm"
printf 'while :; do sleep 1; done\n' > "$t/loop.sh"
(env PATH="$B" HOME="$R/jffs/addons/arteria" "$B/dbclient" -o BatchMode=yes -K 10 -I 30 -p 2222 -i "$R/jffs/addons/arteria/node_key" admin@192.168.50.10 'sh -s' < "$t/loop.sh" > /dev/null 2>&1 &)
left_session() { pgrep -f "$B/dbclient .* -K 10 -I 30 .*sh -s" > /dev/null 2>&1; }
waitfor 3 left_session
doc && rc=0 || rc=1
if [ $rc = 1 ] && grep -q '^  \[FIX \] service-event has 2 lines of Arteria' "$t/doc.out" && grep -q '^  \[ OK \] services-start: ' "$t/doc.out" \
	&& grep -q '^  \[FIX \] 1 file(s) an older' "$t/doc.out" && grep -q '^  \[FIX \] .* can be changed by any program' "$t/doc.out" \
	&& grep -q '^  \[FIX \] a copy of the router' "$t/doc.out" && grep -q '^  \[FIX \] 1 node session(s) still running' "$t/doc.out" \
	&& grep -q '^  \[ OK \] node 1 (RP-AX56): key login works' "$t/doc.out" && ! grep -q '192\.168\|02:CC\|Hall' "$t/doc.out"; then
	ok "doctor: finds what going back to 1.0.0 leaves, old files, open permissions, a leftover client list and node session"
else bad "doctor:"; cat "$t/doc.out"; fi
doc fix || true; grep -q '^Fixed 5 problem(s)\.$' "$t/doc.out" && fixed=1 || { fixed=0; cat "$t/doc.out"; }
doc && rc=0 || rc=1
if [ $rc = 0 ] && [ $fixed = 1 ] && grep -q 'Nothing wrong found' "$t/doc.out" && [ "$(grep -c '# arteria$' "$R/jffs/scripts/service-event")" = 1 ] \
	&& grep -qxF "case \"\$2\" in arteria*) $R/jffs/addons/arteria/arteria.sh service_event \"\$@\" & ;; esac # arteria" "$R/jffs/scripts/service-event" \
	&& grep -q '/some/other/script event' "$R/jffs/scripts/service-event" && [ "$(stat -c %a "$W")" = 755 ] && [ ! -e "$W/clist.htm" ] \
	&& [ ! -e "$R/jffs/addons/arteria/node_key.new.pub" ] && ! left_session; then
	ok "doctor fix: one hook line, today's (others' lines kept), files tidied, permissions tightened, the session stopped"
else bad "doctor fix:"; cat "$t/doc.out"; grep -n . "$R/jffs/scripts/service-event"; ls -la "$W"; fi
touch "$t/node-cut-crash"; doc || true; rm -f "$t/node-cut-crash"
if grep -q "^  \[WARN\] node 1 (RP-AX56): something crashed on the node running Arteria's script, at: cut " "$t/doc.out" \
	&& grep -q '^== node 1 (RP-AX56)' "$R/tmp/arteria/node-trace.txt" && ! grep -qi '192\.168\|02:CC' "$t/doc.out" "$R/tmp/arteria/node-trace.txt"; then
	ok "doctor: a command that crashes on a node is named, its trace saved without addresses"
else bad "doctor, a crash on the node:"; cat "$t/doc.out"; fi
AR_ROOT="$R" AR_PROC="$t/proc" AR_SYS="$t/sys" PATH="$B" "$bb" ash "$R/jffs/addons/arteria/arteria.sh" uninstall > "$t/uninstall.out" 2>&1 || bad "uninstall failed"
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
