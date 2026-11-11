#!/usr/bin/env python3
"""Serve arteria.asp with made-up data, the way the router would, to look at the page without a router.

    python3 .github/tests/preview.py [scenario] [port]      then open http://localhost:8000/user1.asp

Scenarios: home (default), nokey, offline, weak, busy, quiet, nonode.
Counters grow with the clock at each device's rate, so the page computes live rates exactly as it
does on a router. All names and addresses are made up.
"""
import json, math, os, random, sys, time, re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
ASP = os.path.join(HERE, '..', '..', 'arteria.asp')
SCN = sys.argv[1] if len(sys.argv) > 1 else 'home'
PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 8000
T0 = time.time()
NODE = '02:10:00:00:00:80'
OWN = ['24:4B:FE:00:00:20', '24:4B:FE:00:00:24', '26:4B:FE:00:00:20', '26:4B:FE:00:00:24']

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
if SCN == 'busy':
    for i in range(14):
        DEVICES.append(('02:CC:00:00:01:%02X' % i, ['Phone', 'Bulb', 'Plug', 'Tablet', 'Laptop', 'Speaker', 'Camera'][i % 7] + ' %d' % (i + 1),
                        'router' if i % 3 else 'node', '2.4' if i % 2 else '5', 0.5 + (i % 5) * 1.7, 0.1 + (i % 3) * 0.4, -50 - i))
if SCN == 'quiet':
    DEVICES = [(m, n, w, b, d * 0.003, u * 0.003, r) for (m, n, w, b, d, u, r) in DEVICES]
if SCN == 'nonode':
    DEVICES = [d for d in DEVICES if d[2] != 'node']
NODE_ON = SCN not in ('nonode',)
NODE_STATE = {'nokey': 'nokey', 'offline': 'down'}.get(SCN, 'ok')
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
        row = ['eth7' if band == '5' else 'eth6', band, mac, counter(d, t, k, 9e9), counter(u, t, k + 50, 1e9), rssi, 864 if band == '5' else 144, 650, 4000 + k * 100, k % 5]
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
        ifs.append([port, counter(u, t, 210, 7.8e7), counter(d, t, 211, 4.6e8)])
    for p in ('eth1', 'eth2', 'eth3', 'eth4'):
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
            'links': [['eth0', 1, 1000], ['eth4', 0, -1], ['eth3', 0, -1], ['eth2', 0, -1], ['eth1', 0, -1], ['eth5', 1, 2500]],
            'macs': [[d[3], d[0]] for d in wired], 'ifs': ifs, 'sta': sta, 'nodes': nodes}


def names():
    cl = {NODE: {'2G': {}, '5G': {}}}
    for (mac, name, where, band, d, u, rssi) in DEVICES:
        if where == 'node':
            cl[NODE]['2G' if band == '2.4' else '5G'][mac] = {'ip': '192.168.50.%d' % (int(mac[-2:], 16) + 100), 'rssi': str(rssi)}
    custom = ''.join('<%s>%s>0>0>>' % (n, m) for (m, n, w, b, d, u, r) in DEVICES)
    return {'custom': custom, 'leases': '', 'nmp': {}, 'cl': cl}


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
            page = re.sub(r'<%.*?%>', '', page)
            return self.send(page)
        if path == '/ext/arteria/live.htm':
            H.seq += 1
            return self.send(json.dumps(sample(H.seq)), 'text/html')
        if path == '/ext/arteria/names.htm':
            return self.send(json.dumps(names()), 'text/html')
        if path.endswith('.js'):
            return self.send('', 'application/javascript')
        if path.endswith('.css'):
            return self.send('body.bg{background:#21333e;color:#fff;font-family:Arial} .formfonttitle{font-size:16px;font-weight:bold;color:#fff} .formfontdesc{color:#fff;font-size:12px}', 'text/css')
        return self.send('not found', code=404)

    def do_POST(self):
        n = int(self.headers.get('Content-Length') or 0)
        self.rfile.read(n)
        return self.send('<html></html>')


if __name__ == '__main__':
    print('Arteria preview (%s) on http://localhost:%d/user1.asp' % (SCN, PORT))
    ThreadingHTTPServer(('127.0.0.1', PORT), H).serve_forever()
