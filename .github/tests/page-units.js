// Runs parts of the page's script in Node, with a stand-in document, through window.Arteria._t:
// how devices are classified, that every kind has a drawing, an icon and a label, which shape a router
// or node model gets, how a private address that changed finds its old nickname, that the device
// report carries no names, MACs or IPs, and the two geometries (the page's view and the expanded one). Usage: node page-units.js page.js   (prints ok/FAIL lines)
'use strict';
const fs = require('fs'), vm = require('vm');
const el = () => new Proxy(function () {}, { get: (o, k) => k === Symbol.toPrimitive ? () => '' : el(), apply: () => el(), set: () => true });
const sb = { document: el(), navigator: { userAgent: 'node' }, location: { pathname: '/user1.asp' }, setTimeout() {}, clearTimeout() {}, setInterval() {}, clearInterval() {}, console };
sb.window = sb;
vm.runInNewContext(fs.readFileSync(process.argv[2], 'utf8'), sb);
const AR = sb.Arteria, T = AR._t, A = AR.state;
let fails = 0;
const ok = (cond, what, detail) => { console.log((cond ? 'ok    ' : 'FAIL  ') + what + (cond || detail === undefined ? '' : ': ' + detail)); if (!cond) fails++; };

// ---- 1. classification: name, saved icon, detected icon, os, link, maker, DHCP vendor class -> kind
const CASES = [
	['DESKTOP-AB12CD3', 0, 34, 2, 'wifi', '', 'MSFT 5.0', 'desktop'],     // Windows' default host name, which the router calls "Desktop" (34)
	['DESKTOP-AB12CD3', 34, 34, 2, 'wifi', '', 'MSFT 5.0', 'desktop'],
	['Mac Studio', 6, 6, 5, 'wired', 'Apple', '', 'mac'],                  // renamed: the router saved its loose "Macbook" guess
	['Mac Studio', 6, 0, 5, 'wired', 'Apple', '', 'mac'],
	['Mac Book Work', 6, 6, 5, 'wifi', 'Apple', '', 'laptop'],
	['MacBook-Pro', 0, 6, 5, 'wifi', '', '', 'laptop'],
	['Study', 14, 6, 5, 'wifi', '', '', 'mac'],                            // the user picked the iMac icon
	['Study', 6, 6, 5, 'wifi', '', '', 'laptop'],                          // a saved loose icon, no hint in the name
	['Office box', 0, 30, 2, 'wired', '', 'MSFT 5.0', 'desktop'],          // Windows: wired is a desktop...
	['Office box', 0, 30, 2, 'wifi', '', 'MSFT 5.0', 'laptop'],            // ...on Wi-Fi a laptop
	['ExampleNasDXP4800', 0, 4, 0, 'wired', '', '', 'nas'],
	['LGwebOSTV', 0, 0, 0, 'wifi', '', '', 'tv'],
	['Bedroom Daikin AC', 0, 0, 0, 'wifi', '', '', 'air'],
	['wiz_a1b2c3', 0, 0, 0, 'wifi', 'WiZ Connected', 'udhcp 1.24', 'light'],
	['Device …F5:86', 0, 0, 0, 'wifi', 'Signify B.V.', '', 'light'],
	['Device …F5:86', 0, 60, 0, 'wifi', '', '', 'light'],
	['Philips Hue', 0, 60, 0, 'wired', '', '', 'hub'],                     // a bare "Hue" is the bridge: the bulbs are Zigbee behind it
	['Hall lamp', 70, 0, 0, 'wifi', '', '', 'plug'],                       // the user's icon beats the name
	['Johns-iPhone', 0, 0, 5, 'wifi', '', '', 'phone'],
	['Galaxy-S24', 0, 9, 1, 'wifi', '', 'android-dhcp-14', 'phone'],
	['Device …00:11', 0, 0, 1, 'wifi', '', 'android-dhcp-14', 'phone'],
	['Kitchen Echo', 0, 0, 0, 'wifi', '', '', 'smartspeaker'],
	['Sonos Arc', 0, 81, 0, 'wifi', '', '', 'soundbar'],
	['Apple-TV', 0, 11, 5, 'wifi', '', '', 'streamer'],
	['EPSON123456', 0, 18, 0, 'wifi', '', '', 'printer'],
	['Front doorbell', 0, 0, 0, 'wifi', '', '', 'doorbell'],
	['Garden camera', 0, 0, 0, 'wifi', '', '', 'camera'],
	['Roborock-S8', 0, 0, 0, 'wifi', '', '', 'vacuum'],
	['Washing machine', 0, 0, 0, 'wifi', '', '', 'appliance'],
	['Hall thermostat', 0, 0, 0, 'wifi', '', '', 'thermostat'],
	['Smart plug', 0, 0, 0, 'wifi', '', '', 'plug'],
	['Door sensor', 0, 0, 0, 'wifi', '', '', 'sensor'],
	['Front door lock', 0, 0, 0, 'wifi', '', '', 'lock'],
	['Apple Watch', 0, 0, 5, 'wifi', '', '', 'watch'],
	['Kindle', 0, 25, 0, 'wifi', '', '', 'tablet'],
	['PS5', 0, 7, 0, 'wired', '', '', 'console'],
	['RT-AC68U', 0, 2, 0, 'wired', '', '', 'switch'],
	['Device …AA:BB', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'iot'],
	['Device …AA:BB', 0, 0, 0, 'wifi', '', '', 'generic'],
	['Home Assistant', 0, 22, 3, 'wired', '', '', 'hub'],
	['raspberrypi', 0, 22, 3, 'wired', '', '', 'pi'],
	// the devices in the forum's screenshots, and the Raspberry Pi, Echo Studio and Fire TV Stick
	['raspberry02', 0, 34, 3, 'wifi', '', '', 'pi'],
	['rp5-util02', 0, 0, 3, 'wifi', '', '', 'pi'],
	['Device', 0, 0, 0, 'wired', 'Raspberry Pi Trading Ltd', '', 'pi'],
	['RP-AX56', 0, 0, 4, 'wifi', 'ASUSTek COMPUTER INC.', '', 'generic'],      // an ASUS repeater, not a Pi
	['Echo Studio', 0, 45, 0, 'wifi', 'Amazon Technologies Inc.', '', 'smartspeaker'],
	['Alexa Kitchen', 0, 0, 0, 'wifi', '', '', 'smartspeaker'],
	["Alexa's iPhone", 0, 0, 5, 'wifi', 'Apple', '', 'phone'],
	['Fire TV Bedroom', 0, 0, 0, 'wifi', 'Amazon Technologies Inc.', '', 'stick'],
	['Fire TV Cube', 0, 0, 0, 'wifi', '', '', 'streamer'],
	['ring-minicam', 0, 0, 0, 'wifi', '', '', 'camera'],
	['ring-floodlightcam', 0, 0, 0, 'wifi', '', '', 'camera'],
	['ring-chime', 0, 0, 0, 'wifi', '', '', 'plug'],
	['ring-bridge', 0, 0, 0, 'wifi', '', '', 'hub'],
	['myqdoor-left', 0, 0, 0, 'wifi', '', '', 'hub'],
	['tstat-up', 0, 0, 0, 'wifi', '', '', 'thermostat'],
	['kd-43x85j', 0, 0, 0, 'wifi', '', '', 'tv'],
	['hpenvy-7640', 0, 0, 0, 'wifi', '', '', 'printer'],
	['office-subw', 0, 0, 0, 'wifi', '', '', 'speaker'],
	['Xiaomi-Pad-7', 0, 0, 1, 'wifi', '', 'android-dhcp-14', 'tablet'],
	['Redmi-Pad-SE', 0, 0, 1, 'wifi', '', '', 'tablet'],
	['Redmi Note 13', 0, 0, 1, 'wifi', '', '', 'phone'],
	['Kamera Warsztat', 0, 0, 0, 'wifi', '', '', 'camera'],
	['Lennox iComfort S40', 0, 0, 0, 'wifi', '', '', 'thermostat'],
	['Rav4 ChargePoint', 0, 0, 0, 'wifi', '', '', 'plug'],
	['SP111 nr4', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'plug'],
	['wled-WLED', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'light'],
	['Lampa Salon', 0, 0, 0, 'wifi', '', '', 'light'],
	['Firestick', 0, 0, 0, 'wifi', '', '', 'stick'],
];
A.names = AR.parseNames({});
const bad = [];
CASES.forEach((c, i) => {
	const mac = '00:00:5E:00:53:' + (16 + i).toString(16).toUpperCase(), N = A.names, unnamed = /^Device/.test(c[0]);
	if (c[1] || !unnamed) N.custom[mac] = { name: unnamed ? '' : c[0], type: c[1] };
	N.nmp[mac] = { name: '', vendor: c[5], vendorclass: c[6], type: c[2], os_type: c[3] };
	const r = T.classify(mac, c[0], c[4]);
	if (r.kind !== c[7]) bad.push(c[0] + ' (' + c[1] + '/' + c[2] + ') -> ' + r.kind + ' by ' + r.rule + ', expected ' + c[7]);
});
ok(!bad.length, 'classification: ' + CASES.length + ' cases', bad.join('; '));

// ---- 2. every kind the rules can produce has a drawing of its own, an icon and a label
const kinds = new Set(['generic', 'switch', 'iot']);
Object.values(T.TYPE_KIND).forEach(k => kinds.add(k));
T.KIND_STRONG.forEach(r => kinds.add(r[0])); T.KIND_WEAK.forEach(r => kinds.add(r[0]));
const generic = T.objDevice('t', 'generic', 8, 8, 'L').svg.join('');
const missing = [];
kinds.forEach(k => {
	if (!T.ICON[k]) missing.push(k + ': no icon');
	if (!T.KIND_LABEL[k]) missing.push(k + ': no label');
	const svg = T.objDevice('t', k, 8, 8, 'L').svg.join('');
	if (!/<(path|polygon|circle|ellipse)/.test(svg)) missing.push(k + ': draws nothing');
	else if (k !== 'generic' && svg === generic) missing.push(k + ': falls back to the generic box');
});
ok(!missing.length, 'every kind (' + kinds.size + ') has a drawing, an icon and a label', missing.join('; '));

// ---- 3. what a router or AiMesh node looks like, from its model name
const FORMS = [['RP-AX56', 'plug'], ['RP-AX58', 'plug'], ['RP-BE58', 'plug'], ['RP-AC55', 'plug'], ['RP-AC1900', 'plug'], ['ZenWiFi_XP4', 'plug'],
	['ZenWiFi_XT8', 'tower'], ['XT9', 'tower'], ['ZenWiFi_Pro_XT12', 'tower'], ['ZenWiFi_BQ16', 'tower'], ['ET8', 'tower'], ['CT8', 'tower'], ['RT-AX95Q', 'tower'], ['GT6', 'tower'],
	['ZenWiFi_XD4', 'cube'], ['XD5', 'cube'], ['XD6S', 'cube'], ['ZenWiFi_BD4', 'cube'], ['CD6', 'cube'],
	['Lyra', 'puck'], ['MAP-AC2200', 'puck'], ['Lyra_Mini', 'puck'],
	['GT-AX11000', 'gaming'], ['GT-BE98_PRO', 'gaming'], ['RT-AX89X', 'gaming'], ['RT-AC5300', 'gaming'],
	['RT-AX86U', 'router'], ['RT-AX88U_PRO', 'router'], ['RT-BE88U', 'router'], ['TUF-AX3000', 'router'], ['DSL-AX82U', 'router']];
const fbad = FORMS.filter(f => T.formOf(f[0], 'x').form !== f[1]).map(f => f[0] + ' -> ' + T.formOf(f[0], 'x').form);
ok(!fbad.length, 'model shapes: ' + FORMS.length + ' models', fbad.join('; '));
ok(T.formOf('Mystery-1', 'tower').form === 'tower' && T.formOf('Mystery-1', 'router').form === 'router', 'an unknown model keeps today\'s look');
ok(T.formOf('RP-AC1900', 'x').ant && !T.formOf('RP-AX56', 'x').ant, 'plug-in repeaters with antennas get them');
// every shape draws, as a node and as the main router, and says where its Wi-Fi arcs meet
const sbad = [];
['RP-AX56', 'RP-AC1900', 'ZenWiFi_XT8', 'ZenWiFi_XD4', 'Lyra', 'GT-AX11000', 'RT-AX58U', 'Mystery-1'].forEach(m => {
	try {
		const n = T.objNode('node:x', 12, 2, m), r = T.objRouter(m);
		[n, r].forEach((o, i) => { if (!/<polygon|<path/.test(o.svg.join('')) || !(o.bbox()[2] > o.bbox()[0]) || (i === 0 && !o.hub)) sbad.push(m + (i ? ' as router' : ' as node')); });
	} catch (e) { sbad.push(m + ': ' + e.message); }
});
ok(!sbad.length, 'every shape draws as a node and as the main router', sbad.join('; '));

// ---- 4. a private address that changed takes over its old nickname only when it is unambiguous
const NEW = '0A:00:00:00:00:01', OLD = '06:00:00:00:00:09', NEW2 = '0E:00:00:00:00:02';
const lease = (mac, host) => Math.floor(Date.now() / 1000 + 3600) + ' ' + mac.toLowerCase() + ' 192.168.50.9 ' + host + ' *';
const al = (custom, leases, online) => T.buildAliases(AR.parseNames({ custom: custom, leases: leases.join('|') }), online);
let r = al('<Tom\'s tablet>' + OLD + '>0>21>>', [lease(OLD, 'Toms-iPad'), lease(NEW, 'Toms-iPad')], { [NEW]: 1 });
ok(r[NEW] && r[NEW].name === 'Tom\'s tablet' && r[NEW].type === 21, 'a rotated address finds its nickname by host name');
r = al('<Phone>' + OLD + '>0>10>>', [lease(OLD, 'iPhone'), lease(NEW, 'iPhone')], { [NEW]: 1 });
ok(!r[NEW], 'a factory host name ("iPhone") never matches');
r = al('<Tom\'s tablet>' + OLD + '>0>21>>', [lease(OLD, 'Toms-iPad'), lease(NEW, 'Toms-iPad'), lease(NEW2, 'Toms-iPad')], { [NEW]: 1, [NEW2]: 1 });
ok(!r[NEW] && !r[NEW2], 'two unnamed addresses with that host name: no match');
r = al('<Tom\'s tablet>' + OLD + '>0>21>>', [lease(OLD, 'Toms-iPad'), lease(NEW, 'Toms-iPad')], { [NEW]: 1, [OLD]: 1 });
ok(!r[NEW], 'the named address is still connected: no match');
let thrown = '';
try { al('<Phone>' + OLD + '>0>10>>', [lease(OLD, 'constructor'), lease(NEW, 'constructor'), lease(NEW2, '__proto__')], { [NEW]: 1, [NEW2]: 1 }); } catch (e) { thrown = e.message; }
ok(!thrown, 'host names like "constructor" or "__proto__" are just names', thrown);
ok(T.isPrivate('0A:00:00:00:00:01') && T.isPrivate('f6:00:00:00:00:01') && !T.isPrivate('00:00:5E:00:53:01'), 'private (locally administered) addresses are recognised');

// ---- 5. the device report: numbers and rule names only
const MAC = '00:00:5E:00:53:01', secrets = ['Secret Name', 'secret-host', 'Secret Vendor', '00:00:5E', '00:00:5e', '192.168.50.77', 'MSFT', '2001:db8'];
A.names = AR.parseNames({ custom: '<Secret Name>' + MAC + '>0>0>>', leases: '1999999999 ' + MAC.toLowerCase() + ' 192.168.50.77 secret-host *',
	nmp: { [MAC]: { name: 'secret-host', vendor: 'Secret Vendor Inc', vendorclass: 'MSFT 5.0', type: 34, os_type: 2 } }, n6: MAC + ' 2001:db8::1|' });
const dv = { id: MAC, mac: MAC, name: 'Secret Name', link: 'wifi', band: '5' };
dv.why = T.classify(MAC, dv.name, 'wifi'); dv.kind = dv.why.kind;
const rep = T.buildReport({ router: { model: 'RT-AX86U' }, devs: [dv] });
const leak = secrets.filter(x => rep.indexOf(x) >= 0);
ok(!leak.length && /desktop/.test(rep), 'the device report has no names, MACs or IPs', 'leaks ' + leak.join(', '));

// ---- 6. geometry: the page's own view never moves; the expanded view's stands are where they can be
const gs = T.geomSmall(), g0 = T.G();
ok(JSON.stringify([gs.U, gs.OX, gs.OY, gs.x0, gs.y0, gs.x1, gs.y1, gs.SW, gs.SH, gs.hit, gs.wifiSlots.length, gs.nodeSlots.length, gs.wiredSlots.length, gs.flow.x, gs.flow.rows, gs.flow.rowMin, gs.flow.limit])
	=== JSON.stringify([24, 322, 96, 0, 0, 18, 14, 728, 518, 44, 4, 2, 2, { src: 80, rt: 190, link: 298, mesh: 434, dev: 516 }, 8, 44, 508]) && g0.key === 's',
	'the page\'s view keeps its 728 × 518 geometry');
const gbad = [];
[[1568, 780, 1], [1184, 790, 3], [864, 610, 2], [992, 518, 0], [1504, 970, 2]].forEach(([w, h, n]) => {
	const g = T.geomBig(w, h, n), inR = (s, r) => s.cx > r[0] && s.cx < r[2] && s.cy > r[1] && s.cy < r[3];
	const keep = [[4.4, 4.8, 9.8, 9.4], [0.4, 0.6, 3.2, 2.9], [3.2, 0.9, 7.9, 2.5], [6.3, 2.5, 7.9, 4.8]];
	const all = g.wifiSlots.concat(...g.nodeSlots.map(ns => ns.dev), g.wiredSlots);
	const tag = w + 'x' + h + ': ';
	if (T.G() !== g0) gbad.push(tag + 'geomBig changed the current geometry');
	if (g.wifiSlots.length < 8) gbad.push(tag + g.wifiSlots.length + ' Wi-Fi stands');
	if (g.nodeSlots.length !== n) gbad.push(tag + g.nodeSlots.length + ' node zones for ' + n + ' nodes');
	all.forEach(s => {
		if (!(s.cx - 1.2 > g.x0 && s.cx + 1.2 < g.x1 && s.cy - 1.2 > g.y0 && s.cy + 1.2 < g.y1)) gbad.push(tag + 'stand off the floor ' + s.cx + ',' + s.cy);
		if (keep.some(r => inR(s, r))) gbad.push(tag + 'stand on the router or the WAN pipe ' + s.cx + ',' + s.cy);
	});
	const st = g.wifiSlots.concat(...g.nodeSlots.map(ns => ns.dev));
	st.forEach((a, i) => st.slice(i + 1).forEach(b => { if (Math.abs(a.cx - b.cx) < 2.9 && Math.abs(a.cy - b.cy) < 2.5) gbad.push(tag + 'stands too close ' + a.cx + ',' + a.cy); }));
	g.wifiSlots.forEach(s => { if (g.nodeSlots.some(ns => inR(s, ns.zone))) gbad.push(tag + 'a router stand in a node zone ' + s.cx + ',' + s.cy); });
	const p = (x, y) => [g.OX + (x - y) * Math.cos(Math.PI / 6) * g.U, g.OY + (x + y) * 0.5 * g.U];
	const corners = [p(g.x0, g.y0), p(g.x1, g.y0), p(g.x0, g.y1), p(g.x1, g.y1)];
	if (corners.some(c => c[0] < 0 || c[0] > w || c[1] < 0 || c[1] > h)) gbad.push(tag + 'the floor leaves the stage');
});
ok(!gbad.length, 'expanded view: stands on the floor, apart, off the router, and the floor fits (5 window sizes)', gbad.slice(0, 6).join('; '));
const gb = T.geomBig(1568, 780, 1);
ok(gb.wifiSlots.length + gb.nodeSlots[0].dev.length + gb.wiredSlots.length >= 30 && gb.wiredSlots.length === 5, 'a 1600 × 900 window has stands for 30 or more devices, five of them wired',
	gb.wifiSlots.length + '+' + gb.nodeSlots[0].dev.length + '+' + gb.wiredSlots.length);

// ---- 7. names are text: a host name or maker that looks like HTML never becomes markup on the map or the flow
const H = ['<img src=x onerror=alert(1)>', '"><svg onload=alert(2)>', "Tom's \"test\" & co"];
const hdevs = H.map((name, i) => ({ id: 'D' + i, mac: '00:00:5E:00:53:9' + i, name: name, link: i ? 'wifi' : 'wired', band: '5', portLabel: 'LAN 1', kind: 'generic', st: 'ok', dn: 1, up: 1, sdn: 1 + i, sup: 1, rssi: -50 }));
const hnet = { router: { model: 'RT-AX86U<b>' }, nodes: [], devs: hdevs, byId: {}, wan: { dn: 1, up: 1 } };
hdevs.forEach(d => { hnet.byId[d.id] = d; });
const html = [];
[T.geomSmall(), T.geomBig(1184, 790, 0)].forEach(g => {
	const keepG = T.G(); A.gotAny = true; T.useGeom(g);
	try {
		const L = T.mapLayout(hnet), m = T.buildMap(hnet, L), f = T.buildFlow(T.flowGroups(hnet));
		html.push(m.svg, m.labels, f.svg, f.rows);
	} catch (e) { html.push('ERROR ' + e.message); }
	T.useGeom(keepG);
});
const raw = html.join('').match(/<img|<svg onload|<b>|ERROR.*/g);
ok(!raw && html.join('').indexOf('Tom&#39;s &quot;test&quot; &amp; co') >= 0, 'names that look like HTML stay text on the map and the flow', raw && raw.slice(0, 3).join(', '));

// ---- 8. ids are checked where they enter: nothing that isn't a MAC address or an interface name becomes a device
const NODE = '02:10:00:00:00:80', EVIL = '"><img src=x onerror="&#97;lert(1)">';
const smp = o => Object.assign({ v: 1, seq: 1, up: '100.0', epoch: 1, ms: 5, router: { model: 'RT-AX86U' }, interval: 2, wan: 'eth0', ports: ['eth1'], own: [],
	links: [['eth0', 1, 1000], ['eth1', 0, -1]], macs: [], ifs: [['eth0', '1', '1']], sta: [], nodes: [] }, o || {});
A.names = AR.parseNames({ cl: { [NODE]: { '2G': { [EVIL]: { ip: '192.168.50.9', rssi: '-50' }, '__proto__': {}, '00:00:5e:00:53:44': { rssi: '-61' } } } } });
let hn = AR.buildNet(smp({ ports: ['eth1', EVIL], links: [['eth0', 1, 1000], ['eth1', 1, 1000], [EVIL, 1, 1000]], macs: [['eth1', EVIL], [EVIL, '00:00:5E:00:53:45']],
	sta: [['eth6', '5', EVIL, '1', '1', -50, 100, 100, 10, 1, null, null, null], [EVIL, '5', '00:00:5E:00:53:46', '1', '1', -50, 100, 100, 10, 1, null, null, null], 'junk', null],
	nodes: [{ mac: NODE, ip: '192.168.50.10', model: 'RP-AX56', alias: 'Hall', sta: '02:10:00:00:00:81 ' + EVIL, state: 'nokey', up: null, c: [] }, { mac: EVIL, model: 'x', state: 'ok', c: [] }, null] }));
const ids = hn.devs.map(d => d.id).concat(hn.nodes.map(n => n.id)).sort().join(' ');
let hm = '';
try { A.gotAny = true; const L = T.mapLayout(hn), m = T.buildMap(hn, L), f = T.buildFlow(T.flowGroups(hn)); hm = m.svg + m.labels + f.svg + f.rows; } catch (e) { hm = 'ERROR ' + e.message; }
ok(ids === '00:00:5E:00:53:44 node:' + NODE + ' port:eth1' && !/<img|ERROR/i.test(hm) && (hn.byId['00:00:5E:00:53:44'] || {}).rssi === -61, 'addresses and ports that aren\'t one are dropped (sample, node list, AiMesh client list)', ids + ' ' + (hm.match(/<img|ERROR.*/i) || ''));

// ---- 9. one odd value never stops a sample: names of the wrong type, an empty network
A.names = AR.parseNames({ nmp: { '00:00:5E:00:53:02': { name: 12345, vendor: 67 } }, custom: 7, leases: null });
let threw = '';
try {
	AR.buildNet(smp({ sta: [['eth6', '5', '00:00:5E:00:53:02', '1', '1', -50, 100, 100, 10, 1, null, null, null]] }));
	AR.buildNet({ v: 1 }); AR.buildNet(smp({ nodes: 'x', sta: {}, macs: 5, ports: null }));
} catch (e) { threw = e.message; }
ok(!threw, 'a sample or a name of the wrong type doesn\'t throw', threw);
A.names = AR.parseNames({});
const eg = T.flowGroups(AR.buildNet(smp()));
ok(eg.length === 1 && eg[0].rows.length === 0, 'Flow with nothing connected still has a group to draw', eg.length);

// ---- 10. classification: Android before the Wi-Fi module's maker; words that only contain a keyword
const kindFor = (name, nmp) => { A.names = AR.parseNames({ nmp: { '00:00:5E:00:53:7E': nmp || {} } }); return T.classify('00:00:5E:00:53:7E', name, 'wifi').kind; };
const cb = [['', { vendor: 'Murata Manufacturing Co., Ltd.', vendorclass: 'android-dhcp-14', os_type: 1 }, 'phone'], ['', { vendor: 'Murata Manufacturing Co., Ltd.' }, 'iot'],
	['Watchtower', null, 'generic'], ['Apple Watch', null, 'watch'], ['Johns-AppleWatch', null, 'watch'], ['Cambridge Audio', null, 'generic'], ['Hue Bridge', null, 'hub'], ['Motion sensor', null, 'sensor']]
	.filter(c => kindFor(c[0], c[1]) !== c[2]).map(c => (c[0] || JSON.stringify(c[1])) + ' -> ' + kindFor(c[0], c[1]));
ok(!cb.length, 'classification: Android phones with a module maker, and near-miss names', cb.join('; '));

// ---- 11. expanded view: a node's zone never reaches under the router or into another zone, and holds its node
const ovl = (a, b) => !(a[2] <= b[0] || b[2] <= a[0] || a[3] <= b[1] || b[3] <= a[1]), zb = [];
[[728, 518, 3], [992, 518, 3], [1068, 518, 2], [864, 610, 3], [950, 658, 3], [1184, 790, 3], [1504, 970, 3]].forEach(([w, h, n]) => {
	const g = T.geomBig(w, h, n);
	g.nodeSlots.forEach((s, i) => {
		if (ovl(s.zone, [4.4, 4.8, 9.8, 9.4])) zb.push(w + 'x' + h + ': zone ' + i + ' under the router');
		if (!(s.cx > s.zone[0] && s.cx < s.zone[2] && s.cy > s.zone[1] && s.cy < s.zone[3])) zb.push(w + 'x' + h + ': node ' + i + ' outside its zone');
		g.nodeSlots.slice(i + 1).forEach((o, j) => { if (ovl(s.zone, o.zone)) zb.push(w + 'x' + h + ': zones ' + i + ' and ' + (i + 1 + j) + ' overlap'); });
	});
});
ok(!zb.length, 'expanded view: node zones clear of the router and of each other (7 window sizes, up to 3 nodes)', zb.slice(0, 5).join('; '));

// ---- 12. the Flow layout, from numbers alone: rows apart and tall enough, ribbons fit their groups, sources add up
const fdevs = [];
for (let i = 0; i < 40; i++) fdevs.push({ id: 'F' + i, mac: '00:00:5E:00:53:' + (0x40 + i).toString(16).toUpperCase(), name: 'Dev ' + i, link: i % 7 ? 'wifi' : 'wired', band: i % 3 ? '5' : '2.4',
	portLabel: 'LAN 1', kind: 'generic', st: 'ok', dn: (i % 5) * 3.1, up: i % 4, sdn: (i % 5) * 3.1, sup: i % 4 });
const fnet = { router: { model: 'RT-AX86U' }, nodes: [], devs: fdevs, byId: {}, wan: { dn: 30, up: 10, sdn: 30, sup: 10 }, local: { dn: 12, up: 3, sdn: 12, sup: 3 } };
fdevs.forEach(d => { fnet.byId[d.id] = d; });
const flbad = [];
[T.geomSmall(), T.geomBig(1184, 790, 0)].forEach(g => {
	const keepG = T.G(); T.useGeom(g);
	try {
		['dn', 'up'].forEach(mode => {
			A.flowAt = 0;
			const gs = T.flowGroups(fnet), L = T.flowLayout(gs, fnet, mode), tag = (g.big ? 'big ' : 'small ') + mode + ': ';
			let prev = -1, rows = 0;
			gs.forEach(gr => gr.rows.forEach(r => {
				const s = L.slot[r.id]; rows++;
				if (!s || s.top < prev - 0.01) flbad.push(tag + 'rows overlap at ' + r.id);
				if (s && s.s < g.flow.rowMin - 0.01) flbad.push(tag + 'row shorter than a tap target: ' + r.id);
				if (s && (s.h > s.s + 0.01 || s.bar < s.top - 0.01)) flbad.push(tag + 'ribbon outside its row: ' + r.id);
				prev = s ? s.top + s.s : prev;
			}));
			if (g.big && rows !== fdevs.length) flbad.push(tag + rows + ' rows for ' + fdevs.length + ' devices');
			if (!g.big && rows > g.flow.rows) flbad.push(tag + rows + ' rows, budget ' + g.flow.rows);
			if (g.flow.limit && L.bottom > g.flow.limit + 0.01) flbad.push(tag + 'runs past the stage: ' + L.bottom);
			if (!g.flow.limit && L.height < L.bottom) flbad.push(tag + 'the scrolling stage is shorter than its rows');
			if (Math.abs(L.src.wan.h + L.src.loc.h - L.Hr) > 0.01) flbad.push(tag + 'internet + local != router');
			if (!(L.k > 0 && L.k <= 11.5)) flbad.push(tag + 'scale ' + L.k);
		});
	} catch (e) { flbad.push('ERROR ' + e.message); }
	T.useGeom(keepG);
});
ok(!flbad.length, 'Flow layout: rows apart and tap-sized, ribbons in their rows, internet + local = router, fits or scrolls', flbad.slice(0, 5).join('; '));


// ---- 13. Fingerbank: its device paths (as its API returns them) -> kinds; an answer that names only a system or a
// maker, or one it isn't confident about, leaves the decision to the names; your icon still comes first
const FB = [
	['Audio, Imaging or Video Equipment/Video Player and Recorder/Digital Media Player/Amazon Fire TV/Amazon Fire TV Stick', 'stick'],
	['Audio, Imaging or Video Equipment/Video Player and Recorder/Digital Media Player/Amazon Fire TV', 'stick'],
	['Audio, Imaging or Video Equipment/Video Player and Recorder/Digital Media Player/Amazon Fire TV/Amazon Fire TV Cube', 'streamer'],
	['Audio, Imaging or Video Equipment/Video Player and Recorder/Digital Media Player/Google Chromecast', 'stick'],
	['Audio, Imaging or Video Equipment/Video Player and Recorder/Digital Media Player/Apple TV', 'streamer'],
	['Audio, Imaging or Video Equipment/Video Player and Recorder/Digital Media Player/Roku', 'streamer'],
	['Phone, Tablet or Wearable/Generic Android/Google Android/Google TV Streamer', 'streamer'],
	['Phone, Tablet or Wearable/Generic Android/NVidia Android/NVIDIA SHIELD', 'streamer'],
	['Internet of Things (IoT)/Home Assistant/Amazon Alexa/Amazon Echo', 'smartspeaker'],
	['Internet of Things (IoT)/Home Assistant/Amazon Alexa/Amazon Echo Show', 'smartspeaker'],
	['Internet of Things (IoT)/Home Assistant/Amazon Alexa', 'smartspeaker'],
	['Internet of Things (IoT)/Home Assistant/Google Home Device/Google Nest', 'smartspeaker'],
	['Audio, Imaging or Video Equipment/Speaker and Soundbar/Apple HomePod', 'smartspeaker'],
	['Audio, Imaging or Video Equipment/Audio Player/Sonos Player/Sonos One', 'speaker'],
	['Audio, Imaging or Video Equipment/Audio Player/Sonos Player/Sonos Beam', 'soundbar'],
	['Audio, Imaging or Video Equipment/Television/LG TV/LG TV - WebOS', 'tv'],
	['Audio, Imaging or Video Equipment/Television/Roku TV', 'tv'],
	['Audio, Imaging or Video Equipment/Television/LG TV/LG TV - Google TV OS/Android TV', 'tv'],
	['Audio, Imaging or Video Equipment/Camera/Surveillance Camera/Wyze Camera', 'camera'],
	['Audio, Imaging or Video Equipment/Camera/Surveillance Camera/Nest Camera', 'camera'],
	['Internet of Things (IoT)/Locks/Nest Lock/Nest Doorbell', 'doorbell'],
	['Internet of Things (IoT)/Locks/Ring', 'doorbell'],
	['Gaming Console/Sony Gaming Console/Playstation/PlayStation 5', 'console'],
	['Gaming Console/Nintendo Gaming Console/Nintendo Switch', 'console'],
	['Storage Device/Ugreen NAS', 'nas'],
	['Internet of Things (IoT)/Generic IoT/Raspberry Pi/Raspberry Pi 4', 'pi'],
	['Internet of Things (IoT)/Generic IoT/Raspberry Pi', 'pi'],
	['Internet of Things (IoT)/Lighting/Philips Lighting/Philips Hue Smart Lighting', 'light'],
	['Internet of Things (IoT)/Lighting/Philips Lighting/Philips Hue Bridge', 'hub'],
	['Internet of Things (IoT)/Plugs/TP-Link Smart Plugs/TP-Link Tapo Smart Plug', 'plug'],
	['Internet of Things (IoT)/Thermostat/Nest Thermostat', 'thermostat'],
	['Internet of Things (IoT)/Appliance/iRobot/iRobot Roomba', 'vacuum'],
	['Internet of Things (IoT)/Generic IoT/Espressif', 'iot'],
	['Phone, Tablet or Wearable/Generic Android/Google Android/Google Pixel', 'phone'],
	['Phone, Tablet or Wearable/Generic Android/Samsung Android/Galaxy S6', 'phone'],
	['Phone, Tablet or Wearable/Apple Mobile Device/Apple iPhone', 'phone'],
	['Phone, Tablet or Wearable/Apple Mobile Device/Apple iPad', 'tablet'],
	['Phone, Tablet or Wearable/Apple Mobile Device/Apple Watch', 'watch'],
	['Phone, Tablet or Wearable/Generic Android/Amazon Android/Amazon Kindle Fire', 'tablet'],
	['Phone, Tablet or Wearable/Amazon Kindle', 'tablet'],
	['Operating System/Apple OS/Mac OS X or macOS/Mac OS X/Apple MacBook Pro', 'laptop'],
	['Router, Access Point or Femtocell/Wi-Fi Repeater', 'switch'],
	// a system, a maker or a brand of Android: nothing
	['Operating System/Windows OS/Microsoft Windows Kernel 10.0/11', ''],
	['Operating System/Apple OS/iOS', ''],
	['Operating System/Apple OS/Mac OS X or macOS', ''],
	['Phone, Tablet or Wearable/Generic Android', ''],
	['Phone, Tablet or Wearable/Generic Android/Samsung Android', ''],
	['Phone, Tablet or Wearable/Generic Android/Amazon Android', ''],
	['Generic PC/Windows based PC', ''],
	['Hardware Manufacturer/Espressif', ''],
	['Phone, Tablet or Wearable', ''],
];
const fbBad = FB.filter(f => T.fbKind(f[0]) !== f[1]).map(f => f[0].split('/').pop() + ' -> ' + (T.fbKind(f[0]) || 'none') + ', expected ' + (f[1] || 'none'));
ok(!fbBad.length, 'Fingerbank paths -> kinds: ' + FB.length + ' paths', fbBad.join('; '));
FB.forEach(f => { if (f[1]) kinds.add(f[1]); });
ok([...kinds].every(k => T.ICON[k] && T.KIND_LABEL[k]), 'every kind Fingerbank can give has an icon and a label');

const FM = '00:00:5E:00:53:F1', fbNames = (fb, custom) => AR.parseNames({ custom: custom || '', fb: fb,
	nmp: { [FM]: { name: 'Kitchen Echo', vendor: '', vendorclass: '', type: 0, os_type: 0 } } });
const kOf = (fb, custom) => { A.names = fbNames(fb, custom); return T.classify(FM, 'Kitchen Echo', 'wifi'); };
let fr = kOf(FM + '>87>Audio, Imaging or Video Equipment/Video Player and Recorder/Digital Media Player/Amazon Fire TV/Amazon Fire TV Stick>1,3,6,15|');
ok(fr.kind === 'stick' && fr.rule === 'fingerbank' && fr.tok === 'Amazon Fire TV Stick, 87', 'Fingerbank comes before the name ("Kitchen Echo" that Fingerbank knows as a Fire TV Stick)', JSON.stringify(fr));
fr = kOf(FM + '>87>Audio, Imaging or Video Equipment/Video Player and Recorder/Digital Media Player/Amazon Fire TV/Amazon Fire TV Stick>1,3,6,15|', '<Kitchen>' + FM + '>0>23>>');
ok(fr.kind === 'tv' && fr.rule === 'your icon', 'your icon comes before Fingerbank', JSON.stringify(fr));
fr = kOf(FM + '>50>Audio, Imaging or Video Equipment/Video Player and Recorder/Digital Media Player/Amazon Fire TV/Amazon Fire TV Stick>1,3,6,15|');
ok(fr.kind === 'smartspeaker' && fr.rule === 'name', 'a score of 50 or less leaves it to the name', JSON.stringify(fr));
fr = kOf(FM + '>92>Phone, Tablet or Wearable/Generic Android/Amazon Android>1,3,6,15|');
ok(fr.kind === 'smartspeaker' && fr.rule === 'name', 'an answer that names only a system leaves it to the name', JSON.stringify(fr));
fr = kOf(FM + '>>>1,3,6,15|' + 'junk|02:XX>1>2>3|');
ok(fr.kind === 'smartspeaker' && A.names.fb[FM].o === '1,3,6,15' && Object.keys(A.names.fb).length === 1, 'no answer yet: the fingerprint is kept, the name decides; malformed entries are dropped', JSON.stringify(A.names.fb));
A.names = fbNames(FM + '>87>Internet of Things (IoT)/Home Assistant/Amazon Alexa/Amazon Echo>1,3,6,15|');
const fdv = { id: FM, mac: FM, name: 'Kitchen Echo', link: 'wifi', band: '5' }; fdv.why = T.classify(FM, fdv.name, 'wifi'); fdv.kind = fdv.why.kind;
const frep = T.buildReport({ router: { model: 'RT-AX86U' }, devs: [fdv] }), fcells = T.detailsFor({ epoch: 0 }, fdv);
ok(/smartspeaker +fingerbank .* Amazon Echo 87/.test(frep) && frep.indexOf('Kitchen') < 0 && frep.indexOf('00:00:5E') < 0, 'the device report shows what Fingerbank named and its score, still no names or MACs', frep);
ok(fcells.some(c => c[0] === 'Shown as' && /recognised by Fingerbank \(Amazon Echo, 87\)/.test(c[2])), 'Details say Fingerbank recognised it', JSON.stringify(fcells.filter(c => c[0] === 'Shown as')));

// ---- 14. What a device announced when asked (Recognise now): Apple model identifiers, models in mDNS records and UPnP
// descriptions (read with the name rules), telling services. It comes after your icon and before Fingerbank and names.
const AN = [   // [services, model fields, UPnP description, expected kind]
	['_companion-link._tcp.local', 'rpMd=MacBookPro18,1', '', 'laptop'],
	['_device-info._tcp.local', 'model=Mac14,2', '', 'laptop'],
	['_device-info._tcp.local', 'model=Mac14,12', '', 'mac'],
	['_device-info._tcp.local', 'model=iMac21,1', '', 'mac'],
	['_companion-link._tcp.local', 'rpMd=iPhone14,2', '', 'phone'],
	['_companion-link._tcp.local', 'rpMd=iPad13,4', '', 'tablet'],
	['_airplay._tcp.local _raop._tcp.local', 'model=AppleTV11,1', '', 'streamer'],
	['_airplay._tcp.local', 'model=AudioAccessory5,1', '', 'smartspeaker'],
	['_meshcop._udp.local _spotify-connect._tcp.local', 'mn=Echo 4th Gen;vn=Amazon', '', 'smartspeaker'],
	['_googlecast._tcp.local', 'md=Chromecast', '', 'stick'],
	['_googlecast._tcp.local', 'md=Google Nest Mini', '', 'smartspeaker'],
	['_googlecast._tcp.local', 'md=BRAVIA 4K VH2', '', 'tv'],
	['_ipp._tcp.local _printer._tcp.local', 'product=(HP LaserJet Pro M404dn);ty=HP LaserJet Pro M404dn', '', 'printer'],
	['_ipps._tcp.local', '', '', 'printer'],
	['_sonos._tcp.local', '', '', 'speaker'],
	['_hue._tcp.local', '', '', 'hub'],
	['', '', 'manufacturer=Ugreen Group Limited; modelName=UGREEN; modelNumber=DXP2800', 'nas'],
	['', '', 'manufacturer=Plex, Inc.; modelName=Plex Media Server', ''],
	['_smb._tcp.local _home-assistant._tcp.local', '', '', ''],
	['_spotify-connect._tcp.local', '', '', ''],
];
const anOf = r => AR.parseNames({ dc: FM + '>' + r[0] + '>' + r[1] + '>' + r[2] + '|' }).dc[FM];
const anBad = AN.filter(r => ((T.announcedKind(anOf(r)) || [''])[0]) !== r[3]).map(r => (r[1] || r[2] || r[0]) + ' -> ' + ((T.announcedKind(anOf(r)) || ['none'])[0]) + ', expected ' + (r[3] || 'none'));
ok(!anBad.length, 'what devices announce -> kinds: ' + AN.length + ' cases', anBad.join('; '));
const anNames = (dc, custom, fb) => AR.parseNames({ custom: custom || '', dc: dc, fb: fb || '', nmp: { [FM]: { name: 'Kitchen Echo', vendor: '', vendorclass: '', type: 0, os_type: 0 } } });
A.names = anNames(FM + '>_companion-link._tcp.local>rpMd=MacBookPro18,1>|', '', FM + '>87>Internet of Things (IoT)/Home Assistant/Amazon Alexa/Amazon Echo>1,3,6,15|');
fr = T.classify(FM, 'Kitchen Echo', 'wifi');
ok(fr.kind === 'laptop' && fr.rule === 'announced' && fr.tok === 'MacBookPro18,1', 'what a device announced comes before Fingerbank and its name', JSON.stringify(fr));
A.names = anNames(FM + '>_companion-link._tcp.local>rpMd=MacBookPro18,1>|', '<Kitchen>' + FM + '>0>23>>');
fr = T.classify(FM, 'Kitchen Echo', 'wifi');
ok(fr.kind === 'tv' && fr.rule === 'your icon', 'your icon comes before what a device announced', JSON.stringify(fr));
A.names = anNames(FM + '>_spotify-connect._tcp.local>>|' + 'junk|02:XX>a>b>c|' + FM.toLowerCase() + '>x>y>z|');
fr = T.classify(FM, 'Kitchen Echo', 'wifi');
ok(fr.kind === 'smartspeaker' && fr.rule === 'name' && Object.keys(A.names.dc).length === 1, 'nothing telling announced: the name decides; malformed entries are dropped', JSON.stringify(fr));
A.names = anNames(FM + '>_meshcop._udp.local>mn=Echo 4th Gen;vn=Amazon>|');
const adv = { id: FM, mac: FM, name: 'Kitchen Echo', link: 'wifi', band: '5' }; adv.why = T.classify(FM, adv.name, 'wifi'); adv.kind = adv.why.kind;
const arep = T.buildReport({ router: { model: 'RT-AX86U' }, devs: [adv] }), acells = T.detailsFor({ epoch: 0 }, adv);
ok(/smartspeaker +announced: Amazon Echo 4th Gen .*said/.test(arep) && arep.indexOf('Kitchen') < 0 && arep.indexOf('00:00:5E') < 0, 'the device report shows the announced model, still no names or MACs', arep);
ok(acells.some(c => c[0] === 'Shown as' && /recognised by what it announced \(Amazon Echo 4th Gen\)/.test(c[2])), 'Details say what the device announced', JSON.stringify(acells.filter(c => c[0] === 'Shown as')));

process.exit(fails ? 1 : 0);
