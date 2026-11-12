#!/usr/bin/env python3
"""Serve arteria.asp with made-up data, the way the router would, to look at the page without a router.

    python3 .github/tests/preview.py [scenario] [port]      then open http://localhost:8000/user1.asp

Scenarios: home (default), nokey, offline, weak, busy, quiet, nonode, bulbs, kinds1..kinds4, hostile.
Counters grow with the clock at each device's rate, so the page computes live rates exactly as it
does on a router. All names and addresses are made up.
"""
import json, math, os, random, sys, time, re
from urllib.parse import parse_qs
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
ASP = os.path.join(HERE, '..', '..', 'arteria.asp')
SCN = sys.argv[1] if len(sys.argv) > 1 else 'home'
PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 8000
T0 = time.time()
NODE = '02:10:00:00:00:80'
OWN = ['00:00:5E:00:53:FC', '00:00:5E:00:53:FD', '02:00:5E:00:53:FC', '02:00:5E:00:53:FD']

# (mac, name, where, band/port, down Mb/s, up Mb/s, rssi)  where: router | node | wired
DEVICES = [
    ('02:CC:00:00:00:01', 'MacBook Pro', 'router', '5', 96.0, 5.8, -51),
    ('02:CC:00:00:00:02', 'Pixel 8', 'router', '5', 12.4, 1.1, -60),
    ('02:CC:00:00:00:03', 'Kitchen speaker', 'router', '2.4', 0.32, 0.05, -61),
    ('02:CC:00:00:00:04', 'Smart plug', 'router', '2.4', 0.002, 0.003, -63),
    ('02:CC:00:00:00:05', 'Work laptop', 'router', '5', 3.2, 0.9, -48),
    ('02:CC:00:00:00:06', 'Doorbell camera', 'router', '2.4', 0.05, 1.8, -66),
    ('02:CC:00:00:00:09', 'Ugreen NAS', 'wired', 'eth5', 1.9, 41.2, None),
    ('02:CC:00:00:00:11', 'LG TV', 'node', '5', 40.6, 0.7, -57),
    ('02:CC:00:00:00:12', 'iPad', 'node', '5', 11.0, 2.1, -62),
    ('02:CC:00:00:00:13', 'Samsung TV', 'node', '5', 6.4, 0.3, -66),
    ('02:CC:00:00:00:14', 'Thermostat', 'node', '2.4', 0.004, 0.006, -55),
    ('02:CC:00:00:00:15', 'Robot vacuum', 'node', '2.4', 0.02, 0.04, -53),
    ('02:CC:00:00:00:16', 'Galaxy S24', 'node', '5', 2.3, 0.4, -61),
]
# Extra facts about a device, by MAC: the icon number saved in the router's client list ("ctype"), what the
# router detected ("ntype", "os", "vendor", "vc" = DHCP vendor class), its DHCP host name ("host"), and
# "nick": False for a device the user never named (so the page has to work its name out).
X = {}
def dev(mac, name, where, band, d, u, rssi, **x):
    DEVICES.append((mac, name, where, band, d, u, rssi)); X[mac] = x
if SCN == 'bulbs':   # the real-world mix: a desktop PC, a Mac desktop, an AC unit, and 18 quiet bulbs on the tray
    DEVICES = [d for d in DEVICES if d[1] not in ('Smart plug', 'Thermostat', 'Robot vacuum')]
    dev('02:CC:00:00:02:01', 'DESKTOP-K3M9QZ1', 'router', '5', 22.0, 3.1, -55, nick=False, host='DESKTOP-K3M9QZ1', ntype=34, os=2, vc='MSFT 5.0')
    dev('02:CC:00:00:02:02', 'Studio Mac', 'wired', 'eth4', 30.0, 9.0, None, ctype=6, ntype=6, os=5, host='Mac-Studio', vendor='Apple, Inc.')
    dev('02:CC:00:00:02:03', 'Bedroom AC', 'router', '2.4', 0.01, 0.01, -64, host='DaikinAP12345')
    dev('06:CC:00:00:02:04', '', 'router', '5', 0.8, 0.2, -58, nick=False, host='Annas-iPhone')            # a private address, named by its host name
    dev('0A:CC:00:00:02:05', '', 'node', '5', 0.6, 0.1, -60, nick=False, host='Toms-iPad')                  # rotated: "Tom's tablet" was named under 02:CC:00:00:0F:05
    X['02:CC:00:00:0F:05'] = dict(nickonly="Tom's tablet", host='Toms-iPad', ctype=21)
    for i in range(18):
        dev('02:CC:00:00:03:%02X' % i, '', 'router' if i % 3 else 'node', '2.4', 0.002 + (i % 6) * 0.004, 0.001 + (i % 4) * 0.002, -52 - i,
            nick=False, host='wiz_%06x' % (0xa1b2c3 + i * 7919), vendor='WiZ Connected Lighting Company Limited' if i % 2 else '', ntype=60 if i % 5 == 0 else 0, vc='udhcp 1.24.2')
if SCN == 'hostile':   # names that look like HTML (host names, makers): the page must show them as text and never run them
    dev('02:CC:00:00:05:01', 'Tom\'s "test" & co', 'router', '5', 9.0, 1.0, -55, host='<b>bold</b>', vendor='<img src=x onerror="window.__xss=1">', vc='<i>vc</i>')
    dev('02:CC:00:00:05:02', '', 'node', '2.4', 0.01, 0.01, -60, nick=False, host='<svg/onload=window.__xss=2>', vendor='"><script>window.__xss=3</script>')
    for i in range(10):
        dev('02:CC:00:00:05:%02X' % (i + 3), '', 'router', '2.4', 0.001, 0.001, -70 - i, nick=False, host='<u>q%d</u>' % i, vendor='<a href=javascript:window.__xss=4>x</a>')
ZOO = [('Garage desktop', 'desktop'), ('Mac mini', 'mac'), ('Work laptop', 'laptop'), ('Pixel 9', 'phone'), ('Kindle', 'tablet'), ('Sport watch', 'watch'), ('Office printer', 'printer'), ('Lounge TV', 'tv'),
       ('Apple TV', 'streamer'), ('Kitchen speaker', 'speaker'), ('Lounge soundbar', 'soundbar'), ('PlayStation 5', 'console'), ('Attic NAS', 'nas'), ('Garden camera', 'camera'), ('Front doorbell', 'doorbell'), ('Porch lock', 'lock'),
       ('Hall thermostat', 'thermostat'), ('Desk lamp', 'light'), ('Zigbee hub', 'hub'), ('Bedroom AC', 'air'), ('Robot vacuum', 'vacuum'), ('Washing machine', 'washer'), ('Heater plug', 'plug'), ('Leak sensor', 'sensor'),
       ('Tasmota relay', 'iot'), ('Mystery box', 'generic'), ('Fire TV Stick', 'stick'), ('Echo Studio', 'smartspeaker'), ('Raspberry Pi', 'pi'),
       ('Air purifier', 'purifier'), ('Hall light switch', 'wallswitch'), ('Front door sensor', 'contact'),
       ('Tumble dryer', 'dryer'), ('Kitchen dishwasher', 'dishwasher'), ('Kitchen fridge', 'appliance')]
if SCN.startswith('kinds'):   # kinds1..kinds4: every kind of device on a stand, nine at a time
    n = int(SCN[5:] or 1) - 1
    DEVICES = []
    for i, (nm, kind) in enumerate(ZOO[n * 9:n * 9 + 9]):
        where, band = [('router', '5'), ('router', '5'), ('router', '2.4'), ('router', '5'), ('wired', 'eth5'), ('wired', 'eth4'), ('node', '5'), ('node', '5'), ('node', '2.4')][i]
        dev('02:CC:00:00:04:%02X' % (n * 9 + i), nm, where, band, 8.0 + i, 1.0 + i / 4, None if where == 'wired' else -50 - i)
if SCN == 'busy':
    for i in range(14):
        DEVICES.append(('02:CC:00:00:01:%02X' % i, ['Phone', 'Bulb', 'Plug', 'Tablet', 'Laptop', 'Speaker', 'Camera'][i % 7] + ' %d' % (i + 1),
                        'router' if i % 3 else 'node', '2.4' if i % 2 else '5', 0.5 + (i % 5) * 1.7, 0.1 + (i % 3) * 0.4, -50 - i))
if SCN == 'quiet':
    DEVICES = [(m, n, w, b, d * 0.003, u * 0.003, r) for (m, n, w, b, d, u, r) in DEVICES]
if SCN == 'nonode':
    DEVICES = [d for d in DEVICES if d[2] != 'node']
# Ordinary made-up devices get addresses from the IEEE documentation range 00:00:5E:00:53:xx (RFC 7042). A
# 02:... address is locally administered, which the page reads as a private (randomised) Wi-Fi address; the
# fixtures' private ones start 06:, 0A: or 0E: and are kept as they are.
def _doc(mac):
    if not mac.startswith('02:CC:'):
        return mac
    hi, lo = int(mac[12:14], 16), int(mac[15:17], 16)
    return '00:00:5E:00:53:%02X' % ({0: 0x00, 1: 0x60, 2: 0x80, 3: 0xA0, 4: 0xC0, 5: 0xE0, 15: 0xF0}[hi] + lo)
DEVICES = [(_doc(d[0]),) + tuple(d[1:]) for d in DEVICES]
X = {_doc(m): x for m, x in X.items()}
assert len(set(d[0] for d in DEVICES)) == len(DEVICES)
NODE_ON = SCN not in ('nonode',)
NODE_STATE = {'nokey': 'nokey', 'offline': 'down', 'hostile': 'nokey'}.get(SCN, 'ok')   # hostile: the page lists the node's clients from the AiMesh client list
NODE_ONLINE = SCN != 'offline'
WEAK = SCN == 'weak'


def wobble(k, t):
    return 1 + 0.12 * math.sin(1.3 * t / 2 + k * 1.7) + 0.05 * math.sin(0.41 * t / 2 + k * 0.9)


def counter(rate_mbps, t, k, base):
    # integral of the wobbling rate, so consecutive samples give realistic varying rates
    steps = int(t * 2)
    total = sum(rate_mbps * wobble(k, s / 2.0) for s in range(steps)) * 0.5
    return str(int(base + total * 1e6 / 8))


def sample(seq):
    t = time.time() - T0
    up = 25588.76 + t
    sta, node_c = [], []
    nd = nu = 0.0
    for k, (mac, name, where, band, d, u, rssi) in enumerate(DEVICES):
        if where == 'wired':
            continue
        if where == 'node' and SCN == 'offline':
            continue
        # ... connected s, idle s, then what wl sta_info says about the client: Wi-Fi standard, streams, channel width
        row = ['eth7' if band == '5' else 'eth6', band, mac, counter(d, t, k, 9e9), counter(u, t, k + 50, 1e9), rssi, 864 if band == '5' else 144, 650 if band == '5' else 72,
               4000 + k * 1700, k % 5 * 40, ['ax', 'ac', 'ax', 'n'][k % 4] if band == '5' else ['n', 'ax'][k % 2], 2 if band == '5' else 1, 80 if band == '5' else 20]
        if where == 'node':
            row[0] = 'wl1.1' if band == '5' else 'wl0.1'
            node_c.append(row)
            nd += d; nu += u
        else:
            sta.append(row)
    if NODE_ON and NODE_ONLINE:
        sta.append(['eth7', '5', '02:10:00:00:00:84', counter(nd * 1.02 + 0.05, t, 90, 9e9), counter(nu * 1.02 + 0.03, t, 91, 1e9),
                    -78 if WEAK else -52, 144 if WEAK else 516, 459, 25793, 0])
        sta.append(['eth6', '2.4', '02:10:00:00:00:81', counter(0.02, t, 92, 3e7), counter(0.004, t, 93, 9e5), -44, 229, 195, 25763, 0])
    wired = [d for d in DEVICES if d[2] == 'wired']
    tot_d = sum(d[4] for d in DEVICES if d[2] != 'node' or (NODE_ONLINE and NODE_ON)) + 0.05
    tot_u = sum(d[5] for d in DEVICES if d[2] != 'node' or (NODE_ON and NODE_ONLINE))
    local = 38.0 if SCN not in ('quiet',) else 0.1
    ifs = [['eth0', counter(max(tot_d - local, 0.01), t, 200, 2.9e10), counter(max(tot_u - local, 0.01), t, 201, 7.8e9)]]
    for (mac, name, where, port, d, u, rssi) in wired:
        ifs.append([port, counter(u, t, 210 + hash(port) % 7, 7.8e7), counter(d, t, 211 + hash(port) % 7, 4.6e8)])
    for p in ('eth1', 'eth2', 'eth3') + (() if any(d[3] == 'eth4' for d in DEVICES) else ('eth4',)):
        ifs.append([p, '0', '0'])
    ifs.append(['wds0.0.1', '670308', '19215137'])
    ifs.append(['wds1.0.1', counter(nu, t, 220, 9.6e8), counter(nd, t, 221, 9.7e9)])
    nodes = []
    if NODE_ON:
        nodes.append({'mac': NODE, 'ip': '192.168.50.10', 'model': 'RP-AX56', 'alias': 'Hall', 'sta': '02:10:00:00:00:81 02:10:00:00:00:84',
                      'state': NODE_STATE if NODE_ONLINE else 'down', 'up': ('%.2f' % (35054.41 + t)) if NODE_STATE == 'ok' and NODE_ONLINE else None,
                      'c': node_c if NODE_STATE == 'ok' and NODE_ONLINE else []})
    return {'v': 1, 'seq': seq, 'up': '%.2f' % up, 'epoch': int(time.time()), 'ms': 41, 'router': {'model': 'RT-AX86U', 'fw': '3004.388.13_0', 'load': '1.39'},
            'interval': 2, 'nodes_mode': 'on', 'wan': 'eth0', 'ports': ['eth4', 'eth3', 'eth2', 'eth1', 'eth5'], 'own': OWN,
            'links': [['eth0', 1, 1000], ['eth4', 1 if any(d[3] == 'eth4' for d in DEVICES) else 0, 1000 if any(d[3] == 'eth4' for d in DEVICES) else -1], ['eth3', 0, -1], ['eth2', 0, -1], ['eth1', 0, -1], ['eth5', 1, 2500]],
            'macs': [[d[3], d[0]] for d in wired], 'ifs': ifs, 'sta': sta, 'nodes': nodes}


def names():
    cl = {NODE: {'2G': {}, '5G': {}}}
    for (mac, name, where, band, d, u, rssi) in DEVICES:
        if where == 'node':
            cl[NODE]['2G' if band == '2.4' else '5G'][mac] = {'ip': '192.168.50.%d' % (int(mac[-2:], 16) + 100), 'rssi': str(rssi)}
    if SCN == 'hostile':   # a client-list key that isn't a MAC address, as a hostile or imitated node could report
        cl[NODE]['2G']['"><img src=x onerror="window.__xss=5">'] = {'ip': '192.168.50.250', 'rssi': '-40'}
    custom = ''.join('<%s>%s>0>%d>>' % (n, m, X.get(m, {}).get('ctype', 0)) for (m, n, w, b, d, u, r) in DEVICES if X.get(m, {}).get('nick', True))
    custom += ''.join('<%s>%s>0>%d>>' % (x['nickonly'], m, x.get('ctype', 0)) for m, x in X.items() if 'nickonly' in x)
    leases = '|'.join('%d %s 192.168.50.%d %s 01:%s' % (int(time.time()) + 79000 - i * 3000, m.lower(), 20 + i, x['host'], m.lower()) for i, (m, x) in enumerate(X.items()) if x.get('host'))
    nmp = {m: {'mac': m, 'name': x.get('host', ''), 'vendor': x.get('vendor', ''), 'vendorclass': x.get('vc', ''), 'type': x.get('ntype', 0), 'os_type': x.get('os', 0)}
           for m, x in X.items() if any(k in x for k in ('ntype', 'vendor', 'vc', 'os', 'nickonly'))}
    # Details: a reservation for the first device, ARP entries for the rest without a lease, and IPv6 neighbours
    # (documentation prefix 2001:db8::/32, RFC 3849)
    macs = [d[0] for d in DEVICES]
    fixed = '<%s>192.168.50.2>>' % macs[0] if macs else ''
    arp = ''.join('%s 192.168.50.%d|' % (m.lower(), 100 + i) for i, m in enumerate(macs) if not X.get(m, {}).get('host'))
    n6 = ''.join('%s 2001:db8::%x|%s fe80::%x|' % (m.lower(), 0x100 + i, m.lower(), 0x200 + i) for i, m in enumerate(macs[:6]))
    return {'custom': custom, 'leases': leases, 'nmp': nmp, 'cl': cl, 'fixed': fixed, 'arp': arp, 'n6': n6}


# Settings: what the router does when the page asks it to Recognise now (arteria.sh recognise_ui), and rec.htm.
REC = {'busy': False, 'asked': 0, 'socat': True, 'seq': 0, 'ok': None, 'msg': ''}


def router_action(f):
    act = (f.get('action_script') or [''])[0]
    if act == 'start_arteriarec':
        REC.update(asked=9, seq=REC['seq'] + 2, ok=True, msg='9 device(s) said what they are.')


class H(BaseHTTPRequestHandler):
    seq = 0

    def log_message(self, *a):
        pass

    def send(self, body, ctype='text/html; charset=utf-8', code=200):
        b = body.encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', ctype)
        self.send_header('Content-Length', str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def do_GET(self):
        path = self.path.split('?')[0]
        if path in ('/', '/user1.asp'):
            page = open(ASP, encoding='utf-8').read()
            page = page.replace('<% nvram_get("productid"); %>', 'RT-AX86U')   # what the router fills in
            page = re.sub(r'<%.*?%>', '', page)
            return self.send(page)
        if path == '/ext/arteria/live.htm':
            H.seq += 1
            return self.send(json.dumps(sample(H.seq)), 'text/html')
        if path == '/ext/arteria/names.htm':
            return self.send(json.dumps(names()), 'text/html')
        if path == '/ext/arteria/rec.htm':
            return self.send(json.dumps(REC), 'text/html')
        if path.endswith('.js'):
            return self.send('', 'application/javascript')
        if path.endswith('.css'):
            return self.send('body.bg{background:#21333e;color:#fff;font-family:Arial} .formfonttitle{font-size:16px;font-weight:bold;color:#fff} .formfontdesc{color:#fff;font-size:12px}', 'text/css')
        return self.send('not found', code=404)

    def do_POST(self):
        n = int(self.headers.get('Content-Length') or 0)
        router_action(parse_qs(self.rfile.read(n).decode('utf-8', 'replace')))
        return self.send('<html></html>')


if __name__ == '__main__':
    print('Arteria preview (%s) on http://localhost:%d/user1.asp' % (SCN, PORT))
    ThreadingHTTPServer(('127.0.0.1', PORT), H).serve_forever()
