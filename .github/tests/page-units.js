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
	['Washing machine', 0, 0, 0, 'wifi', '', '', 'washer'],
	['BOSCH-WAX32EH0EU-00005E0053A1', 0, 0, 0, 'wifi', 'BSH Hausgeraete GmbH', '', 'washer'],
	['BOSCH-WTX87EH0EU-00005E0053A2', 0, 0, 0, 'wifi', 'BSH Hausgeraete GmbH', '', 'dryer'],
	['SIEMENS-SN85TX00CE-00005E0053A3', 0, 0, 0, 'wifi', 'BSH Hausgeraete GmbH', '', 'dishwasher'],
	['BOSCH-SMV4HVX31E-00005E0053A4', 0, 0, 0, 'wifi', '', '', 'dishwasher'],
	['BOSCH-KGN39AIAT-00005E0053A5', 0, 0, 0, 'wifi', '', '', 'appliance'],
	['Kitchen dishwasher', 0, 0, 0, 'wifi', '', '', 'dishwasher'],
	['Tumble dryer', 0, 0, 0, 'wifi', '', '', 'dryer'],
	['Electrolux_Appliance', 0, 0, 0, 'wifi', 'Electrolux Appliances AB', '', 'appliance'],
	['Device …00:A6', 0, 0, 0, 'wifi', 'Electrolux Appliances AB', '', 'appliance'],
	['ems-esp', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'boiler'],
	['Hall thermostat', 0, 0, 0, 'wifi', '', '', 'thermostat'],
	['Smart plug', 0, 0, 0, 'wifi', '', '', 'plug'],
	['Door sensor', 0, 0, 0, 'wifi', '', '', 'contact'],
	['Philips Air', 0, 0, 0, 'wifi', 'Shanghai MXCHIP Information Technology Co., Ltd.', '', 'purifier'],
	['mxchip', 0, 0, 0, 'wifi', 'Shanghai MXCHIP Information Technology Co., Ltd.', '', 'iot'],
	['Bedroom humidifier', 0, 0, 0, 'wifi', '', '', 'purifier'],
	['L630', 0, 0, 0, 'wifi', '', '', 'light'],
	['L530E', 0, 0, 0, 'wifi', '', '', 'light'],
	['KL130(EU)', 0, 0, 0, 'wifi', '', '', 'light'],
	['P110', 0, 0, 0, 'wifi', '', '', 'plug'],
	['C200', 0, 0, 0, 'wifi', '', '', 'camera'],
	['S505', 0, 0, 0, 'wifi', '', '', 'wallswitch'],
	['HS220(US)', 0, 0, 0, 'wifi', '', '', 'wallswitch'],
	['H200', 0, 0, 0, 'wired', '', '', 'hub'],
	['RV30_Max_Plus', 0, 0, 0, 'wifi', '', '', 'vacuum'],
	['ihoment_H6159_1A2B', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'strip'],      // Govee's H61… are LED strips
	['ihoment_H6008_1A2B', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'light'],      // ...its H600… bulbs
	['ihoment_H7070_1A2B', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'light'],
	['ihoment_H7121_1A2B', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'purifier'],
	['ihoment_H5075_1A2B', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'sensor'],
	['shelly1-A1B2C3', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'wallswitch'],
	['Hall light switch', 0, 0, 0, 'wifi', '', '', 'wallswitch'],
	['Patio window sensor', 0, 0, 0, 'wifi', '', '', 'contact'],
	['shellydw2-A1B2C3', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'contact'],
	['Nintendo Switch', 0, 0, 0, 'wifi', '', '', 'console'],
	['Office switch', 0, 2, 0, 'wired', '', '', 'switch'],
	// words run together: a name rule finds "nas" in JohnsNas, nas01, johns_nas and ExampleDSPNAS; a first name that ends in it isn't one
	['JohnsNas', 0, 0, 0, 'wired', '', '', 'nas'],
	['nas01', 0, 0, 0, 'wired', '', '', 'nas'],
	['johns_nas', 0, 0, 0, 'wired', '', '', 'nas'],
	['ExampleDSPNAS', 0, 0, 0, 'wired', '', '', 'nas'],
	['KidsTV', 0, 0, 0, 'wifi', '', '', 'tv'],
	['LivingRoomLamp', 0, 0, 0, 'wifi', '', '', 'light'],
	['office_printer', 0, 0, 0, 'wifi', '', '', 'printer'],
	['OfficePC', 0, 0, 0, 'wired', '', '', 'desktop'],
	['BedroomAC', 0, 0, 0, 'wifi', '', '', 'air'],
	['JONAS-iPhone', 0, 0, 0, 'wifi', '', '', 'phone'],
	['Jonas', 0, 0, 0, 'wifi', '', '', 'generic'],
	['RT-AC1200', 0, 0, 0, 'wifi', '', '', 'generic'],
	// a saved icon that is just the router's own guess (the client editor saves it with a nickname): the name comes first
	['Lounge Daikin AC', 7, 7, 0, 'wifi', 'Murata Manufacturing Co., Ltd.', '', 'air'],
	// ... or a computer, phone, tablet, watch or console icon on a device named after a home device: nobody picks a console
	// for an air conditioner. Other icons still win over the name: a plug named for its lamp stays a plug (Hall lamp, above).
	['Lounge Daikin AC', 7, 0, 0, 'wifi', 'Murata Manufacturing Co., Ltd.', '', 'air'],
	['Kitchen fridge', 25, 0, 0, 'wifi', '', '', 'appliance'],
	['Kids PS5', 7, 0, 0, 'wifi', '', '', 'console'],
	['Living room', 7, 0, 0, 'wifi', '', '', 'console'],
	['TV speaker', 47, 0, 0, 'wifi', '', '', 'soundbar'],
	['Living room', 7, 7, 0, 'wifi', '', '', 'console'],
	['Kids room', 23, 7, 0, 'wifi', '', '', 'tv'],
	// the newer kinds
	['Wallbox Pulsar', 0, 0, 0, 'wifi', '', '', 'charger'],
	['Tesla Wall Connector', 0, 0, 0, 'wifi', '', '', 'charger'],
	['easee-home', 0, 0, 0, 'wifi', '', '', 'charger'],
	['Tesla Model Y', 0, 0, 0, 'wifi', '', '', 'car'],
	['Polestar 2', 0, 0, 0, 'wifi', '', '', 'car'],
	['Tesla Powerwall', 0, 0, 0, 'wifi', '', '', 'solar'],
	['Fronius Symo', 0, 0, 0, 'wifi', '', '', 'solar'],
	['OpenDTU-1A2B3C', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'solar'],
	['Device …01:F2', 0, 0, 0, 'wifi', 'SolarEdge Technologies', '', 'solar'],
	['Automower 430X', 0, 0, 0, 'wifi', '', '', 'mower'],
	['Ecovacs GOAT G1', 0, 0, 0, 'wifi', '', '', 'mower'],
	['Landroid', 0, 0, 0, 'wifi', '', '', 'mower'],
	['Quest-3', 0, 0, 0, 'wifi', '', '', 'vr'],
	['Oculus Quest 2', 0, 0, 0, 'wifi', '', '', 'vr'],
	['XGIMI Horizon', 0, 0, 0, 'wifi', '', '', 'projector'],
	['Epson EH-LS800', 0, 0, 0, 'wifi', '', '', 'projector'],
	['Garage', 0, 0, 0, 'wifi', '', '', 'garage'],
	['Garage light', 0, 0, 0, 'wifi', '', '', 'light'],
	['ratgdo-1a2b3c', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'garage'],
	['Bambu Lab P1S', 0, 0, 0, 'wifi', '', '', 'printer3d'],
	['octopi', 0, 0, 0, 'wifi', '', '', 'printer3d'],
	['Kitchen Echo Show', 0, 0, 0, 'wifi', '', '', 'display'],
	['Nest Hub', 0, 0, 0, 'wifi', '', '', 'display'],
	['Echo Dot', 0, 0, 0, 'wifi', '', '', 'smartspeaker'],
	['Bedroom blinds', 0, 0, 0, 'wifi', '', '', 'blinds'],
	['Somfy TaHoma', 0, 0, 0, 'wired', '', '', 'hub'],
	['Rachio-3', 0, 0, 0, 'wifi', '', '', 'sprinkler'],
	['Gardena smart gateway', 0, 0, 0, 'wifi', '', '', 'sprinkler'],
	['Cat feeder', 0, 0, 0, 'wifi', '', '', 'pet'],
	['Furbo', 0, 0, 0, 'wifi', '', '', 'pet'],
	['Peloton', 0, 0, 0, 'wifi', '', '', 'fitness'],
	// LED strips
	['Desk LED strip', 0, 0, 0, 'wifi', '', '', 'strip'],
	['TV backlight', 0, 0, 0, 'wifi', '', '', 'strip'],
	['Kitchen strip', 0, 0, 0, 'wifi', '', '', 'strip'],
	['Bed LEDs', 0, 0, 0, 'wifi', '', '', 'strip'],
	['GoveeStrip', 0, 0, 0, 'wifi', '', '', 'strip'],
	['Govee', 0, 0, 0, 'wifi', '', '', 'strip'],
	['Govee floor lamp', 0, 0, 0, 'wifi', '', '', 'light'],
	['Govee light bar', 0, 0, 0, 'wifi', '', '', 'light'],
	['Govee purifier', 0, 0, 0, 'wifi', '', '', 'purifier'],
	['Govee thermometer', 0, 0, 0, 'wifi', '', '', 'sensor'],
	['Nanoleaf Lightstrip', 0, 0, 0, 'wifi', '', '', 'strip'],
	['yeelink-light-strip2_miio123', 0, 0, 0, 'wifi', '', '', 'strip'],
	['L930', 0, 0, 0, 'wifi', '', '', 'strip'],
	['KL430(US)', 0, 0, 0, 'wifi', '', '', 'strip'],
	['LED-Streifen Flur', 0, 0, 0, 'wifi', '', '', 'strip'],
	['LED лента', 0, 0, 0, 'wifi', '', '', 'strip'],
	['Power strip', 0, 0, 0, 'wifi', '', '', 'plug'],
	['Smart strip', 0, 0, 0, 'wifi', '', '', 'generic'],
	['Desk LED strip', 60, 0, 0, 'wifi', '', '', 'strip'],                 // renamed here: the router's light icon was saved with it
	['Desk lamp', 60, 0, 0, 'wifi', '', '', 'light'],
	['Hall lamp', 70, 0, 0, 'wifi', '', '', 'plug'],
	// boilers
	['ems-esp-boiler', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'boiler'],
	['Gas boiler', 0, 0, 0, 'wifi', '', '', 'boiler'],
	['Vitoconnect', 0, 0, 0, 'wifi', '', '', 'boiler'],
	['otgw-1A2B3C', 0, 0, 0, 'wifi', '', '', 'boiler'],
	['Water heater', 0, 0, 0, 'wifi', '', '', 'boiler'],
	['Газов котел', 0, 0, 0, 'wifi', '', '', 'boiler'],
	['Boiler thermostat', 0, 0, 0, 'wifi', '', '', 'thermostat'],
	['Bathroom heater', 0, 0, 0, 'wifi', '', '', 'appliance'],
	['Device …01:F5', 0, 0, 0, 'wifi', 'Viessmann Climate Solutions SE', '', 'boiler'],
	['Gas boiler', 50, 0, 0, 'wifi', '', '', 'boiler'],                    // the router's appliance icon, saved with the name
	['Washing machine', 50, 0, 0, 'wifi', '', '', 'washer'],
	// more names for the older kinds
	['NPI3C2AF4', 0, 0, 0, 'wifi', '', '', 'printer'],
	['BRW0123456789AB', 0, 0, 0, 'wifi', '', '', 'printer'],
	['Fire TV Omni', 0, 0, 0, 'wifi', '', '', 'tv'],
	['Fire TV Stick 4K', 0, 0, 0, 'wifi', '', '', 'stick'],
	['Vizio Soundbar', 0, 0, 0, 'wifi', '', '', 'soundbar'],
	['Hisense AC', 0, 0, 0, 'wifi', '', '', 'air'],
	['Eufy RoboVac', 0, 0, 0, 'wifi', '', '', 'vacuum'],
	['Wyze Bulb', 0, 0, 0, 'wifi', '', '', 'light'],
	['Baby monitor', 0, 0, 0, 'wifi', '', '', 'camera'],
	['SM-S918B', 0, 0, 0, 'wifi', '', '', 'phone'],
	['SM-X710', 0, 0, 0, 'wifi', '', '', 'tablet'],
	['LibreELEC', 0, 0, 0, 'wired', '', '', 'streamer'],
	['WiiM Pro', 0, 0, 0, 'wifi', '', '', 'speaker'],
	['Hive Hub', 0, 0, 0, 'wifi', '', '', 'thermostat'],
	['Device …01:F3', 0, 0, 0, 'wifi', 'Amazon Technologies Inc.', '', 'smartspeaker'],
	['Device …01:F4', 0, 0, 0, 'wifi', 'Shenzhen Intellirocks Tech. Co., Ltd.', '', 'strip'],
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
	['myqdoor-left', 0, 0, 0, 'wifi', '', '', 'garage'],
	['tstat-up', 0, 0, 0, 'wifi', '', '', 'thermostat'],
	['kd-43x85j', 0, 0, 0, 'wifi', '', '', 'tv'],
	['hpenvy-7640', 0, 0, 0, 'wifi', '', '', 'printer'],
	['office-subw', 0, 0, 0, 'wifi', '', '', 'speaker'],
	['Xiaomi-Pad-7', 0, 0, 1, 'wifi', '', 'android-dhcp-14', 'tablet'],
	['Redmi-Pad-SE', 0, 0, 1, 'wifi', '', '', 'tablet'],
	['Redmi Note 13', 0, 0, 1, 'wifi', '', '', 'phone'],
	['Kamera Warsztat', 0, 0, 0, 'wifi', '', '', 'camera'],
	['Lennox iComfort S40', 0, 0, 0, 'wifi', '', '', 'thermostat'],
	['Rav4 ChargePoint', 0, 0, 0, 'wifi', '', '', 'charger'],
	['SP111 nr4', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'plug'],
	['wled-WLED', 0, 0, 0, 'wifi', 'Espressif Inc.', '', 'strip'],
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
			A.flowPick = null; A.flowMem = {}; A.flowK = {};
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

// ---- 12b. Flow rows stay put while traffic wobbles: once the first few samples have sized the rows, sample after sample
// (each device +-40%, the total too) rows hardly move (only when a row reaches a new high step) and devices don't swap in
// or out of "+N more"; a device whose traffic jumps
// fivefold moves the rows below it a few times while its new level shows, then they settle again
const fstill = [];
[T.geomSmall(), T.geomBig(1184, 790, 0)].forEach(g => {
	const keepG = T.G(); T.useGeom(g);
	try {
		A.flowPick = null; A.flowMem = {}; A.flowK = {};
		let rnd = 7; const r = () => (rnd = (rnd * 16807) % 2147483647) / 2147483647;
		const base = fdevs.map(d => d.dn), tops = [], moves = [];
		for (let sIdx = 0; sIdx < 40; sIdx++) {
			fdevs.forEach((d, i) => { const surge = sIdx >= 20 && i === 4 ? 5 : 1; d.dn = d.sdn = base[i] * surge * (0.6 + 0.8 * r()); });
			fnet.wan.dn = fnet.wan.sdn = 30 * (0.6 + 0.8 * r());
			const gs = T.flowGroups(fnet), L = T.flowLayout(gs, fnet, 'dn'), at = {};
			gs.forEach(gr => gr.rows.forEach(rw => { at[rw.id] = Math.round(L.slot[rw.id].top * 10) / 10; }));
			tops.push(at);
			if (sIdx) moves.push(Object.keys(at).some(id => at[id] !== tops[sIdx - 1][id]) || Object.keys(tops[sIdx - 1]).length !== Object.keys(at).length);
		}
		// moves[i] compares sample i+1 with sample i: 0-2 size the rows, 3-18 wobble, 19 is the jump, 19-28 its new level shows, 29-38 settled
		const quiet = moves.slice(3, 19).filter(Boolean).length, after = moves.slice(19, 29).filter(Boolean).length, settled = moves.slice(29).filter(Boolean).length;
		if (quiet > 2) fstill.push((g.big ? 'big' : 'small') + ': rows moved ' + quiet + ' times in 16 samples while traffic only wobbled');   /* the old layout: 15 */
		if (after > 4 || settled) fstill.push((g.big ? 'big' : 'small') + ': after one device\'s traffic jumped, rows moved ' + after + ' times, then ' + settled + ' more');
	} catch (e) { fstill.push('ERROR ' + e.message); }
	fdevs.forEach((d, i) => { d.dn = d.sdn = (i % 5) * 3.1; });
	T.useGeom(keepG);
});
ok(!fstill.length, 'Flow rows stay put while traffic wobbles, and settle again when a device gets much busier', fstill.join('; '));

// ---- 13. a nickname the router's client editor saved by itself (its DHCP software, the maker) isn't a name
const NM = '00:00:5E:00:53:F2', nk = (nick, host, vendor) => { A.names = AR.parseNames({ custom: '<' + nick + '>' + NM + '>0>0>>', leases: '1999999999 ' + NM.toLowerCase() + ' 192.168.50.88 ' + host + ' *',
	nmp: { [NM]: { name: '', vendor: vendor, vendorclass: '', type: 0, os_type: 0 } } }); return T.nameInfo(NM); };
let ni = nk('dhcpcd-6 8 2 Linux-5 4 1', 'roborock-vacuum-s5e', 'Beijing Xiaomi Mobile Software Co.,Ltd');
ok(ni.name === 'roborock-vacuum-s5e' && ni.src === 'device', 'a nickname that is only DHCP software gives way to the device\'s own name', JSON.stringify(ni));
ni = nk('Beijing Xiaomi Mobile Software C', 'roborock-vacuum-s5e', 'Beijing Xiaomi Mobile Software Co.,Ltd');
ok(ni.name === 'roborock-vacuum-s5e', 'so does a nickname that is only the maker (cut short or not)', JSON.stringify(ni));
ni = nk('Vacuum', 'roborock-vacuum-s5e', 'Beijing Xiaomi Mobile Software Co.,Ltd');
ok(ni.name === 'Vacuum' && ni.src === 'nick', 'a nickname you gave still wins', JSON.stringify(ni));
A.names = AR.parseNames({ custom: '<dhcpcd-6 8 2 Linux-5 4 1>' + NM + '>0>61>>', nmp: { [NM]: { name: '', vendor: '', vendorclass: '', type: 0, os_type: 0 } } });
ok(T.classify(NM, '', 'wifi').kind === 'vacuum', '... and the icon saved with it still counts');

// ---- 14. renaming a device rewrites only its entry in the router's client list, the way the router's own editor writes it
const RL = T.renameList, M1 = '02:CC:00:00:00:05', M2 = '02:CC:00:00:00:13', M3 = '02:CC:00:00:00:21';
const rlbad = [];
const eq = (got, want, what) => { if (got !== want) rlbad.push(what + ': ' + JSON.stringify(got)); };
eq(RL('<Living room TV>' + M1 + '>0>23>><Kids>' + M2 + '>0>21>>', M1, 'Lounge TV', 23), '<Lounge TV>' + M1 + '>0>23>><Kids>' + M2 + '>0>21>>', 'rename, other entry untouched');
eq(RL('<Kids>' + M2 + '>0>21>>', M1, 'Hall lamp', 60), '<Kids>' + M2 + '>0>21>><Hall lamp>' + M1 + '>0>60>>', 'a new entry, as the editor writes it');
eq(RL('Kids>' + M2 + '>0>0>>>><Den>' + M3 + '>0>2>>>>', M1, 'Den plug', 70), '<Kids>' + M2 + '>0>0>>>><Den>' + M3 + '>0>2>>>><Den plug>' + M1 + '>0>70>>>>', 'newer firmware: the first entry\'s lost "<" back, the new one shaped like the others');
eq(RL('<Old>' + M1.toLowerCase() + '>0>7>>x>y<Kids>' + M2 + '>0>21>>', M1, 'Bedroom AC', 49), '<Bedroom AC>' + M1 + '>0>49>>x>y<Kids>' + M2 + '>0>21>>', 'a lower-case MAC found; its other fields kept');
eq(RL('<A>' + M1 + '>0>7>><B>' + M1 + '>0>9>>', M1, 'Only one', 0), '<Only one>' + M1 + '>0>0>>', 'a duplicate goes');
eq(RL('<A>' + M1 + '>0>7>><Kids>' + M2 + '>0>21>>', M1, '', 0), '<Kids>' + M2 + '>0>21>>', 'no name: the entry goes');
eq(RL('<A>' + M1 + '>0>7>>', M1, '', 0), '', 'the last entry removed: an empty list');
eq(RL('', M1, 'Ünïcode lamp ✓', 60), '<Ünïcode lamp ✓>' + M1 + '>0>60>>', 'an empty list, any letters');
/* each kind's saved icon reads back as that kind: the same icon, or a broader one its name narrows (LED strip -> light) */
Object.keys(T.ASUS_TYPE).forEach(k => { const b = T.TYPE_KIND[T.ASUS_TYPE[k]]; if (b !== k && T.SUB[k] !== b) rlbad.push('icon ' + T.ASUS_TYPE[k] + ' for ' + k + ' reads back as ' + b); });
ok(!rlbad.length, 'Renaming rewrites only that device\'s entry in the router\'s client list, as the router writes it', rlbad.join('; '));

// ---- 15. the short rates on labels and lists carry their unit's letter: small for bits (k, m, g), capital for bytes (K, M, G)
{
	const u0 = A.unit, got = [];
	A.unit = 'Mb'; [[0, '0'], [0.047, '47k'], [2.1, '2.1m'], [131, '131m'], [1250, '1.25g']].forEach(([x, e]) => got.push([x, T.short(x), e]));
	A.unit = 'MB'; [[0.376, '47K'], [16.8, '2.1M'], [10000, '1.25G']].forEach(([x, e]) => got.push([x + ' (MB)', T.short(x), e]));
	A.unit = u0;
	const bad = got.filter(g => g[1] !== g[2]);
	ok(!bad.length, 'Short rates: k m g for bits, K M G for bytes: ' + got.map(g => g[1]).join(' '), bad.map(g => g[0] + ' -> ' + g[1] + ', expected ' + g[2]).join('; '));
}

// ---- 16. dual WAN: the internet is both WANs together, each kept for the readout; with one WAN, nothing changes
{
	const d1 = { ok: false }, keep = Object.assign({}, A.prev || {}), keepSm = Object.assign({}, A.sm || {});
	['wan', 'wan2'].forEach(k => { if (A.prev) delete A.prev[k]; if (A.sm) delete A.sm[k]; });
	AR.buildNet(smp({ up: '5000.0', wan2: 'usb0', ifs: [['eth0', '0', '0'], ['usb0', '0', '0']], links: [['eth0', 1, 1000], ['usb0', 1, 0]] }));
	const dw = AR.buildNet(smp({ up: '5002.0', wan2: 'usb0', ifs: [['eth0', '2500000', '250000'], ['usb0', '1250000', '125000']], links: [['eth0', 1, 1000], ['usb0', 1, 0]] }));
	const sum = dw.wans ? dw.wans[0].r.dn + dw.wans[1].r.dn : -1;
	d1.ok = !!dw.wans && dw.wans.map(w => w.ifn).join(' ') === 'eth0 usb0' && Math.abs(dw.wan.dn - sum) < 1e-9 && dw.wans[1].r.dn > 0 && dw.wans[0].r.dn > dw.wans[1].r.dn;
	['wan', 'wan2'].forEach(k => { if (A.prev) delete A.prev[k]; if (A.sm) delete A.sm[k]; });
	const one = AR.buildNet(smp({ up: '6000.0' }));
	ok(d1.ok && !one.wans, 'dual WAN: the internet is both WANs together (' + (dw.wans ? dw.wans.map(w => w.ifn + ' ' + w.r.dn.toFixed(1)).join(' + ') + ' = ' + dw.wan.dn.toFixed(1) : 'none') + ' Mb/s); one WAN as before');
	if (A.prev) Object.assign(A.prev, keep); if (A.sm) Object.assign(A.sm, keepSm);
}

// ---- 17. a device's network: named only when it isn't a main one (a guest network, or one of Guest Network Pro's); a main
// network's name served on a wl0.x interface is still a main network
{
	const nn = AR.buildNet(smp({ up: '7100.0', nets: [['eth6', 'Home', 1], ['wl0.1', 'Guest <x>', 0], ['wl0.2', 'Home', 0], ['eth7', 'Home', 1]],
		sta: [['eth6', '2.4', '00:00:5E:00:53:71', '1', '1', -50, 100, 100, 10, 1, null, null, null], ['wl0.1', '2.4', '00:00:5E:00:53:72', '1', '1', -50, 100, 100, 10, 1, null, null, null],
			['wl0.2', '2.4', '00:00:5E:00:53:73', '1', '1', -50, 100, 100, 10, 1, null, null, null]] }));
	const by = m => (nn.devs.filter(d => d.mac === m)[0] || {}).net;
	ok(by('00:00:5E:00:53:71') === '' && by('00:00:5E:00:53:72') === 'Guest <x>' && by('00:00:5E:00:53:73') === '',
		'network names: a guest network is named, a main one (even on wl0.2) isn\'t', [by('00:00:5E:00:53:71'), by('00:00:5E:00:53:72'), by('00:00:5E:00:53:73')].join(' | '));
}

// ---- 18. ports named as printed on the router: the firmware's own numbers when it has them (the RT-AX88U's LAN 1-4 run
// eth4-eth1), a port shared by several (its LAN 5-8 behind eth5) by the one that is up; else by the router's order
{
	const pm = (o) => AR.buildNet(smp(Object.assign({ up: '7200.0', ports: ['eth1', 'eth2', 'eth3', 'eth4', 'eth5'], macs: [['eth4', '00:00:5E:00:53:81'], ['eth5', '00:00:5E:00:53:82']] }, o)));
	const lab = (n, m) => (n.devs.filter(d => d.mac === m)[0] || {}).portLabel;
	const a1 = pm({ plab: { eth4: '1', eth3: '2', eth2: '3', eth1: '4', eth5: '5-8' }, links: [['eth0', 1, 1000], ['eth4', 1, 1000], ['eth5', 1, 100, '7']] });
	const a2 = pm({ plab: { eth4: '1', eth5: '5-8' }, links: [['eth0', 1, 1000], ['eth4', 1, 1000], ['eth5', 1, 1000, '6,7']] });
	const a3 = pm({ links: [['eth0', 1, 1000], ['eth4', 1, 1000], ['eth5', 1, 1000]] });
	const got = [lab(a1, '00:00:5E:00:53:81'), lab(a1, '00:00:5E:00:53:82'), lab(a2, '00:00:5E:00:53:82'), lab(a3, '00:00:5E:00:53:81'), lab(a3, '00:00:5E:00:53:82')];
	ok(got.join(' | ') === 'LAN 1 | LAN 7 | LAN 5–8 | LAN 4 | LAN 5', 'ports: the firmware\'s own numbers, a shared port by the one that is up, else the router\'s order', got.join(' | '));
}

// ---- 19. a weak backhaul: judged by the link carrying the node's traffic, or while the node is quiet by its fastest link that
// isn't 2.4 GHz; an idle link's last packets (control frames, sent slowly) say nothing, and 6 GHz reads lower for the same link
{
	const bhNet = (up, rows) => AR.buildNet(smp({ up: up, sta: rows, nodes: [{ mac: '02:10:00:00:00:A0', ip: '192.168.50.11', model: 'BQ16', alias: 'Den',
		sta: '02:10:00:00:00:A1 02:10:00:00:00:A2', state: 'ok', up: up, c: [] }] }));
	const row = (mac, band, rx, tx, rssi, ptx, prx) => ['eth7', band, mac, String(tx), String(rx), rssi, ptx, prx, 100, 0, 'be', 2, 160];
	const fresh = () => { A.weakHold = {}; [A.sm, A.prev].forEach(o => Object.keys(o).forEach(k => { if (k.indexOf('02:10:00:00:00:A') >= 0) delete o[k]; })); };
	const weak = (rows1, rows2, t) => { fresh(); bhNet(t[0], rows1); const n = bhNet(t[1], rows2); return n.nodes[0].weak; };
	// a 6 GHz backhaul at -75 dBm, idle, its last packets at 24/54 Mb/s; the 2.4 GHz link as strong as ever: not weak
	const quiet6 = weak([row('02:10:00:00:00:A1', '6', 1000, 1000, -75, 24, 54), row('02:10:00:00:00:A2', '2.4', 1000, 1000, -44, 229, 195)],
		[row('02:10:00:00:00:A1', '6', 1000, 1000, -75, 24, 54), row('02:10:00:00:00:A2', '2.4', 1000, 1000, -44, 229, 195)], ['7300.0', '7302.0']);
	// the same link busy (20 Mb/s) at 2882 Mb/s: not weak; busy at 144 Mb/s: weak
	const busyFast = weak([row('02:10:00:00:00:A1', '6', 1e6, 1e6, -75, 2882, 2401)], [row('02:10:00:00:00:A1', '6', 1e6 + 5e6, 1e6, -75, 2882, 2401)], ['7400.0', '7402.0']);
	const busySlow = weak([row('02:10:00:00:00:A1', '6', 1e6, 1e6, -60, 144, 120)], [row('02:10:00:00:00:A1', '6', 1e6 + 5e6, 1e6, -60, 144, 120)], ['7500.0', '7502.0']);
	// a 5 GHz backhaul carrying the traffic at -78 dBm, a strong idle 2.4 GHz one beside it: weak (the 5 GHz link is the one in use)
	const weak5 = weak([row('02:10:00:00:00:A1', '5', 1e6, 1e6, -78, 144, 459), row('02:10:00:00:00:A2', '2.4', 1000, 1000, -44, 229, 195)],
		[row('02:10:00:00:00:A1', '5', 1e6 + 5e6, 1e6, -78, 144, 459), row('02:10:00:00:00:A2', '2.4', 1000, 1000, -44, 229, 195)], ['7600.0', '7602.0']);
	ok(!quiet6 && !busyFast && busySlow && weak5, 'weak backhaul: by the link in use, not an idle link\'s last packets; 6 GHz at -75 dBm is fine',
		JSON.stringify({ quiet6, busyFast, busySlow, weak5 }));
	// a 5 GHz link at -73 dBm running at 864 Mb/s, busy or idle: a good link (AiMesh's "Great"); at -78 dBm and busy at 864: still fast
	const good73 = weak([row('02:10:00:00:00:A1', '5', 1e6, 1e6, -73, 864, 864)], [row('02:10:00:00:00:A1', '5', 1e6 + 5e6, 1e6, -73, 864, 864)], ['7700.0', '7702.0']);
	const idle73 = weak([row('02:10:00:00:00:A1', '5', 1e6, 1e6, -73, 6, 24)], [row('02:10:00:00:00:A1', '5', 1e6, 1e6, -73, 6, 24)], ['7710.0', '7712.0']);
	const fast78 = weak([row('02:10:00:00:00:A1', '5', 1e6, 1e6, -78, 864, 720)], [row('02:10:00:00:00:A1', '5', 1e6 + 5e6, 1e6, -78, 864, 720)], ['7720.0', '7722.0']);
	ok(!good73 && !idle73 && !fast78, 'weak backhaul: -73 dBm isn\'t weak; a low signal on a link that runs fast under traffic isn\'t either', JSON.stringify({ good73, idle73, fast78 }));
	// near the line, from one sample to the next: the warning changes only once the new reading has held for 10 s
	fresh();
	const at = (up, rssi) => bhNet(up, [row('02:10:00:00:00:A1', '5', 1000, 1000, rssi, 6, 24)]).nodes[0].weak;
	const seq = [at('7800.0', -77), at('7802.0', -77), at('7804.0', -70), at('7810.0', -70), at('7814.0', -70), at('7816.0', -77), at('7818.0', -70), at('7820.0', -77), at('7830.0', -77)];
	ok(seq.join() === 'true,true,true,true,false,false,false,false,true', 'weak backhaul: shown at once once measured, then changed only after 10 s of the other reading', seq.join());
	A.weakHold = {};
}

// ---- 20. a node on a Wi-Fi backhaul that counts its own uplink: its backhaul is its own count, made in the same round as its
// devices' (the router's count of the same link runs a round ahead of the node's); one on a wired backhaul keeps the router's
{
	const nd = (up, nup, bhTx, uRx, devRx) => AR.buildNet(smp({ up: up, sta: [['eth7', '5', '02:10:00:00:00:B1', String(bhTx), '1000', -55, 864, 864, 100, 0, 'ax', 2, 80]],
		nodes: [{ mac: '02:10:00:00:00:B0', ip: '192.168.50.12', model: 'RP-AX56', alias: 'Loft', sta: '02:10:00:00:00:B1', state: 'ok', up: nup,
			c: [['wl1.1', '5', '00:00:5E:00:53:B2', String(devRx), '1000', -50, 600, 600, 100, 0, 'ax', 2, 80]], u: [['eth6', String(uRx), '2000']] }] }));
	nd('7700.0', '500.0', 1e6, 1e6, 1e6);
	// the router's count says 8 MB/s already; the node's round, 2 s on its clock, says 2 MB/s through the uplink and to the device
	const n = nd('7702.0', '502.0', 1e6 + 16e6, 1e6 + 4e6, 1e6 + 4e6).nodes[0], dv = n.devs[0];
	ok(n.bhOwn && Math.abs(n.bh.dn - 16) < 0.01 && Math.abs(dv.dn - 16) < 0.01, 'a node\'s backhaul from its own uplink count, in step with its devices (backhaul ' + n.bh.dn.toFixed(1) + ', device ' + (dv ? dv.dn.toFixed(1) : '-') + ' Mb/s)');
	// a node whose own count stays at nothing (it isn't counting its real uplink) while the router counts 16 Mb/s on its
	// backhaul: the node's count for two samples, then, from the third in a row, the router's
	const nz = (k) => AR.buildNet(smp({ up: (7800 + 2 * k).toFixed(1), sta: [['eth7', '5', '02:10:00:00:00:C1', String(1e6 + k * 4e6), '1000', -55, 864, 864, 100, 0, 'ax', 2, 80]],
		nodes: [{ mac: '02:10:00:00:00:C0', ip: '192.168.50.13', model: 'RP-AX56', alias: 'Attic', sta: '02:10:00:00:00:C1', state: 'ok', up: (600 + 2 * k).toFixed(1),
			c: [['wl1.1', '5', '00:00:5E:00:53:C2', '1000', '1000', -50, 600, 600, 100, 0, 'ax', 2, 80]], u: [['eth6', '5000', '2000']] }] })).nodes[0];
	let m = null, own = [];
	for (let k = 0; k <= 5; k++) { m = nz(k); if (k) own.push(m.bhOwn ? 1 : 0); }
	// the same while the node's round is slower than the page: samples without a new round don't count towards the three
	const nz2 = (k, r) => AR.buildNet(smp({ up: (7900 + 2 * k).toFixed(1), sta: [['eth7', '5', '02:10:00:00:00:D1', String(1e6 + k * 4e6), '1000', -55, 864, 864, 100, 0, 'ax', 2, 80]],
		nodes: [{ mac: '02:10:00:00:00:D0', ip: '192.168.50.14', model: 'RP-AX56', alias: 'Den', sta: '02:10:00:00:00:D1', state: 'ok', up: (700 + 3 * r).toFixed(1),
			c: [['wl1.1', '5', '00:00:5E:00:53:D2', '1000', '1000', -50, 600, 600, 100, 0, 'ax', 2, 80]], u: [['eth6', '5000', '2000']] }] })).nodes[0];
	const slow = [];
	[0, 1, 1, 1, 2, 2].forEach((r, k) => { const q = nz2(k, r); if (k) slow.push(q.bhOwn ? 1 : 0); });
	ok(slow.join('') === '11111', 'a node slower than the page keeps its own count until three of its rounds say otherwise (' + slow.join('') + ')');
	ok(own.join('') === '11000' && m.bh.dn > 10, 'a node whose own uplink count stays at nothing while the router counts its backhaul falls back to the router\'s (' + own.join('') + ', ' + m.bh.dn.toFixed(1) + ' Mb/s)');
}

// ---- 21. more AiMesh nodes than the map has zones (two, three in the expanded view): the busiest get them, a node keeps its
// zone and its place unless one without is 3x busier (and over 1 Mb/s), at most one swap every 20 s, and the tray names the rest
{
	const mk = (k, sdn) => ({ mac: '02:10:00:00:00:C' + k, id: 'node:02:10:00:00:00:C' + k, name: 'Node ' + k, online: sdn >= 0, bh: { dn: sdn, up: 0, sdn: Math.max(sdn, 0), sup: 0 } });
	const ns = [mk(1, 2), mk(2, 40), mk(3, 0.5), mk(4, 80)], names = z => z.map(n => n.name).join(',');
	A.gotAny = true; A.nodeZones = null; A.nodeSwapAt = 0;
	let z = T.pickNodes(ns, 3);
	ok(names(z) === 'Node 4,Node 2,Node 1', 'with four nodes and three zones, the three busiest get them', names(z));
	ns[2].bh.sdn = 5; z = T.pickNodes(ns, 3);   /* 2.5x the quietest shown: not enough */
	const kept = names(z) === 'Node 4,Node 2,Node 1';
	ns[2].bh.sdn = 30; z = T.pickNodes(ns, 3);  /* 15x: it takes the quietest one's zone, in its place; the others stay put */
	const swapped = names(z) === 'Node 4,Node 2,Node 3';
	ns[0].bh.sdn = 200; z = T.pickNodes(ns, 3);  /* another swap right away (over 3x the quietest shown): held for 20 s */
	const held = names(z) === 'Node 4,Node 2,Node 3';
	A.nodeSwapAt = Date.now() - 21000; z = T.pickNodes(ns, 3);
	ok(kept && swapped && held && names(z) === 'Node 4,Node 2,Node 1', 'a node keeps its zone unless one without is 3x busier, takes its place, and swaps wait 20 s', names(z));
	A.nodeZones = null; ok(names(T.pickNodes(ns.slice(0, 2), 3)) === 'Node 1,Node 2' && A.nodeZones === null, 'with no more nodes than zones, they keep their order');
	{   /* an offline node with a zone gives way to an idle node that's online */
		const o = [mk(5, 9), mk(6, 8), mk(7, 0)]; A.nodeZones = null; A.nodeSwapAt = 0;
		T.pickNodes(o, 2); o[0].online = false; o[0].bh.sdn = 0; A.nodeSwapAt = 0;
		ok(names(T.pickNodes(o, 2)) === 'Node 7,Node 6', 'an offline node gives its zone to an idle node that is online', names(T.pickNodes(o, 2)));
	}
	const dv = { id: 'D1', node: ns[1], name: 'TV' };
	const hs = { nodes: [ns[1]], devs: [dv, { id: 'D2', node: null, name: 'Phone' }] };
	ok(T.trayName(hs.devs, hs.nodes) === '+2 more · +1 node' && T.trayName([], [ns[1], ns[2]]) === '+2 nodes', 'the tray counts the nodes without a zone', T.trayName(hs.devs, hs.nodes));
	ok(T.noZoneText(hs) === 'No room on the map for Node 2 (1 device). Its devices are in this list, and Flow shows every node.'
		&& T.noZoneText({ nodes: [ns[1], ns[2]], devs: [] }) === 'No room on the map for Node 2 (0 devices) and Node 3 (0 devices). Flow shows every node.',
		'the tray\'s list names the nodes without a zone', T.noZoneText(hs));
	// on the map itself: four nodes from a sample, in the expanded view (three zones) and the page's (two)
	const s4 = (up, m) => smp({ up: up, sta: [1, 2, 3, 4].map(k => ['eth7', '5', '02:10:00:00:00:D' + k, String(1e6 + m * k * 1e6), '1000', -55, 864, 864, 100, 0, 'ax', 2, 80]),
		nodes: [1, 2, 3, 4].map(k => ({ mac: '02:10:00:00:00:E' + k, ip: '192.168.50.1' + k, model: 'RP-AX56', alias: 'Node ' + k, sta: '02:10:00:00:00:D' + k, state: 'ok', up: up,
			c: [['wl1.1', '5', '00:00:5E:00:53:E' + k, '1000', '1000', -50, 600, 600, 100, 0, 'ax', 2, 80]] })) });
	AR.buildNet(s4('8000.0', 0)); const n4 = AR.buildNet(s4('8002.0', 2));
	const out = [];
	[[T.geomBig(1184, 790, 4), 1], [T.geomSmall(), 2]].forEach(([g, hidden]) => {
		const keepG = T.G(); T.useGeom(g); A.nodeZones = null; A.nodeSwapAt = 0;
		try {
			const L = T.mapLayout(n4), m = T.buildMap(n4, L);
			const onTray = L.tray.filter(d => L.hidden.indexOf(d.node) >= 0).length;
			out.push(L.nodes.length + '+' + L.hidden.length + (L.hidden.length === hidden && onTray === hidden && L.hidden.every(n => n.name === 'Node 1' || n.name === 'Node 2') && m.labels.indexOf('+' + hidden + ' node') >= 0 ? '' : ' bad'));
		} catch (e) { out.push('ERROR ' + e.message); }
		T.useGeom(keepG);
	});
	ok(out.join(' ') === '3+1 2+2', 'on the map: the quietest nodes without a zone, their devices on the tray, and the tray says how many nodes', out.join(' '));
	A.nodeZones = null; A.nodeSwapAt = 0;
	// a node with one busy-ish camera (1.5 Mb/s) has the zone; one with 18 quiet devices (0.3 Mb/s) takes it: traffic doesn't
	// decide between them, devices do. A download (3x and over 1 Mb/s) still beats any number of devices.
	{
		const dz = (k, sdn, n) => Object.assign(mk(k, sdn), { devs: Array.from({ length: n }, (_, i) => ({ id: 'X' + k + i, st: 'ok' })) });
		const cam = dz(1, 1.5, 1), lounge = dz(2, 0.3, 18), dl = dz(3, 40, 1);
		A.nodeZones = ['02:10:00:00:00:C1']; A.nodeSwapAt = 0;
		const a = names(T.pickNodes([cam, lounge], 1));
		A.nodeZones = ['02:10:00:00:00:C2']; A.nodeSwapAt = 0;
		const b = names(T.pickNodes([lounge, dl], 1));
		A.nodeZones = ['02:10:00:00:00:C2']; A.nodeSwapAt = 0;
		const c = names(T.pickNodes([lounge, dz(4, 0.1, 12)], 1));   /* 12 devices aren't over twice 18: it keeps its zone */
		A.nodeZones = null; A.nodeSwapAt = 0;
		const d = names(T.pickNodes([dz(5, 0, 2), dz(6, 0, 9), dz(7, 0, 4)], 2));   /* nothing measured yet (the page just opened): most devices first */
		ok(a === 'Node 2' && b === 'Node 3' && c === 'Node 2' && d === 'Node 6,Node 7', 'zones: when traffic doesn\'t decide, the node with many more devices gets one; a download still wins', [a, b, c, d].join(' | '));
		A.nodeZones = null; A.nodeSwapAt = 0;
	}
}

// ---- 22. a switch on a LAN port: one device with the port's figures, and the devices behind it, each named and pickable, with no
// figures of their own; picking the switch or one of them opens the list of its devices, and one of them is traced to the switch
{
	A.names = AR.parseNames({ custom: '<Game PC>00:00:5E:00:53:A1>0>0>><Backup NAS>00:00:5E:00:53:A2>0>4>>' });
	['p:eth1', 'p:eth2'].forEach(k => { delete A.prev[k]; delete A.sm[k]; });
	const sw = (up, tx) => AR.buildNet(smp({ up: up, ports: ['eth1', 'eth2'], links: [['eth0', 1, 1000], ['eth1', 1, 1000], ['eth2', 1, 1000]],
		macs: [['eth1', '00:00:5E:00:53:A1'], ['eth1', '00:00:5E:00:53:A2'], ['eth1', '00:00:5E:00:53:A3'], ['eth2', '00:00:5E:00:53:A4']],
		ifs: [['eth0', '1', '1'], ['eth1', '1000', String(tx)], ['eth2', '0', '0']] }));
	sw('9000.0', 1000); const n = sw('9002.0', 1000 + 2.5e6);
	const s = n.byId['port:eth1'], b = s && s.behind || [], one = n.byId['00:00:5E:00:53:A4'];
	const names = b.map(d => d.name).join(','), inDevs = n.devs.filter(d => d.sw).length;
	const pickable = b.every(d => n.byId[d.id] === d && d.st === 'shared' && d.sw === s && d.link === 'wired' && d.portLabel === 'LAN 1');
	A.sel = 'port:eth1'; const hsS = T.hiddenSet(n);
	A.sel = '00:00:5E:00:53:A2'; const hsD = T.hiddenSet(n), ch = T.chainOf(n, A.sel), ro = T.readoutFor(n);
	const kinds = b.map(d => d.kind).join(',');
	A.sel = null;
	ok(s && s.kind === 'switch' && s.count === 3 && Math.abs(s.dn - 10) < 0.01 && names === 'Backup NAS,Device …53:A3,Game PC' && kinds.indexOf('nas') >= 0 && pickable && !inDevs && one && !one.behind
		&& n.clients === 4 && hsS && hsS.open && hsS.devs === b && hsS.key === 'port:eth1' && hsD && hsD.devs === b && ch.join() === 'port:eth1'
		&& ro.dnN === '—' && /through a switch/.test(ro.d.link) && /all 3 together/.test(ro.note) && ro.path === 'RT-AX86U → switch → Backup NAS',
		'a switch: the port\'s figures on one device, its devices named in its list (no figures of their own), each one traced to it',
		JSON.stringify({ names, kinds, dn: s && s.dn, inDevs, clients: n.clients, ch, link: ro.d.link, note: ro.note }));
	const cells = T.detailsFor(n, n.byId['00:00:5E:00:53:A1']), cell = cells.filter(c => c[0] === 'Behind')[0];
	const rep = T.buildReport(n).split('\n').filter(l => / wired /.test(l)).length;
	ok(cell && cell[1] === 'a switch · 3 devices' && rep === 4, 'a device behind a switch: its details say so, and the device report lists each one', (cell && cell[1]) + ', ' + rep + ' wired rows');
	A.names = AR.parseNames({});
}

// ---- 23. a node's wired ports, read on the node: a device on one is the node's (its zone, its Flow group, its backhaul), measured
// on the node's port counters; a port that is down, or that leads back into the network (an address of the router's, of a node's,
// or of a Wi-Fi device), shows nothing; and a device on the node's guest network is named with it
{
	const N = '02:10:00:00:00:F0', bh = '02:10:00:00:00:F1';
	const nn = (up, nup, tx) => AR.buildNet(smp({ up: up, own: ['00:00:5E:00:53:FC'], nets: [['eth6', 'Home', 1], ['eth7', 'Home', 1]],
		sta: [['eth7', '5', bh, String(1e6 + tx), '1000', -55, 864, 864, 100, 0, 'ax', 2, 80], ['eth7', '5', '00:00:5E:00:53:F9', '1', '1', -50, 600, 600, 100, 0, 'ax', 2, 80]],
		nodes: [{ mac: N, ip: '192.168.50.15', model: 'RT-AX86U', alias: 'Den', sta: bh, state: 'ok', up: nup,
			c: [['wl1.1', '5', '00:00:5E:00:53:F2', '1000', '1000', -50, 600, 600, 100, 0, 'ax', 2, 80], ['wl1.2', '5', '00:00:5E:00:53:F3', '1000', '1000', -50, 600, 600, 100, 0, 'ax', 2, 80]],
			w: [['eth3', 1, 1000, '500', String(1000 + tx)], ['eth4', 0, 0, '0', '0'], ['eth1', 1, 1000, '9', '9'], ['eth2', 1, 1000, '9', '9'], ['eth5', 1, 100, '9', '9']],
			m: [['eth3', '00:00:5E:00:53:F4'], ['eth1', '00:00:5E:00:53:FC'], ['eth2', '00:00:5E:00:53:F9'], ['eth5', bh]],
			n: [['eth1', 'Home', 1], ['wl1.1', 'Home', 0], ['wl1.2', 'Guests "x"', 0]] }] }));
	nn('9100.0', '600.0', 0); const n = nn('9102.0', '602.0', 4e6), node = n.nodes[0];
	const pi = n.byId['00:00:5E:00:53:F4'], ports = n.devs.filter(d => d.node === node && d.link === 'wired').map(d => d.port).join(',');
	const g = T.flowGroups(n), lan = g.filter(x => x.id === 'lan')[0], ng = g.filter(x => x.id === node.id)[0];
	const keepG = T.G(); T.useGeom(T.geomBig(1184, 790, 1)); A.nodeZones = null;
	let onMap = '';
	try { const L = T.mapLayout(n); onMap = L.wired.map(x => x.dev.id).join(',') + '|' + L.devs.filter(x => x.dev.node === node).map(x => x.dev.id).sort().join(','); } catch (e) { onMap = 'ERROR ' + e.message; }
	T.useGeom(keepG);
	const net = m => (n.byId[m] || {}).net;
	ok(pi && pi.node === node && pi.link === 'wired' && pi.portLabel === 'Den LAN' && Math.abs(pi.dn - 16) < 0.01 && ports === 'eth3' && node.devs.indexOf(pi) >= 0
		&& !lan && ng && ng.devs.indexOf(pi) >= 0 && onMap.split('|')[0] === '' && onMap.split('|')[1].indexOf(pi.id) >= 0,
		'a node\'s wired device: in its zone and its Flow group, on its port counters; ports that are down or lead back into the network show nothing',
		JSON.stringify({ ports, dn: pi && pi.dn, label: pi && pi.portLabel, lan: !!lan, onMap }));
	ok(net('00:00:5E:00:53:F3') === 'Guests "x"' && net('00:00:5E:00:53:F2') === '' && net('00:00:5E:00:53:F9') === '',
		'a node\'s guest network is named for its devices; a main network on the node (the router\'s name) isn\'t', [net('00:00:5E:00:53:F3'), net('00:00:5E:00:53:F2')].join(' | '));
}

// ---- 24. several nodes behind one router port (a switch; Living room wired behind Kitchen): the port counts them all together. Each
// node that is read shows its own count, Kitchen without what it passes on to Living room; one that isn't read gets the rest; the
// whole network counts the port once. A node wired behind a Wi-Fi node, not read, gets the port of the node in front as its backhaul.
{
	const K = '02:10:00:00:01:10', LR = '02:10:00:00:01:20', MB = '02:10:00:00:01:30', B = 250000;   /* bytes in 2 s for 1 Mb/s */
	const sh = (k, mbRead) => AR.buildNet(smp({ up: (9500 + 2 * k).toFixed(1), ports: ['eth1'], links: [['eth0', 1, 1000], ['eth1', 1, 1000]],
		ifs: [['eth0', '1', '1'], ['eth1', '1000', String(1000 + k * 60 * B)]], macs: [['eth1', K], ['eth1', LR], ['eth1', MB]],
		nodes: [
			{ mac: K, ip: '192.168.50.21', model: 'RT-AX86U', alias: 'Kitchen', sta: '', state: 'ok', up: (1000 + 2 * k).toFixed(1), c: [],
				u: [['eth0', String(1000 + k * 40 * B), '1000']], w: [['eth4', 1, 1000, '1000', String(1000 + k * 25 * B)]], m: [['eth4', LR]] },
			{ mac: LR, ip: '192.168.50.22', model: 'RT-AX86U', alias: 'Living room', sta: '', state: 'ok', up: (2000 + 2 * k).toFixed(1), c: [],
				u: [['eth0', String(1000 + k * 25 * B), '1000']] },
			mbRead ? { mac: MB, ip: '192.168.50.23', model: 'RT-AX86U', alias: 'Master', sta: '', state: 'ok', up: (3000 + 2 * k).toFixed(1), c: [], u: [['eth0', String(1000 + k * 20 * B), '1000']] }
				: { mac: MB, ip: '192.168.50.23', model: 'RT-AX86U', alias: 'Master', sta: '', state: 'nokey', up: null, c: [] }] }));
	sh(0, true); const n = sh(1, true), by = a => n.nodes.filter(x => x.name === a)[0];
	const f = x => x.bh.dn.toFixed(1);
	const got = [f(by('Kitchen')), f(by('Living room')), f(by('Master')), n.total.dn.toFixed(1)].join(' ');
	const lr = by('Living room');
	A.sel = lr.id; const ro = T.readoutFor(n); A.sel = null;
	ok(got === '15.0 25.0 20.0 60.0' && lr.via === by('Kitchen') && lr.viaWired && ro.path === 'RT-AX86U → Kitchen → Living room' && /Wired backhaul · through Kitchen/.test(ro.d.link),
		'nodes behind one port: each its own figure (Kitchen without Living room, wired behind it), the port counted once in the whole network', got + ' | ' + ro.path + ' | ' + ro.d.link);
	sh(2, false); const n2 = sh(3, false);
	ok(n2.nodes.filter(x => x.name === 'Master')[0].bh.dn.toFixed(1) === '20.0' && n2.total.dn.toFixed(1) === '60.0',
		'a node that isn\'t read, behind the same port: what the port carries beyond the others', n2.nodes.map(x => x.name + ' ' + x.bh.dn.toFixed(1)).join(', '));
	// behind a node on a Wi-Fi backhaul, and not read: online, with the port of the node in front as its backhaul
	const W = '02:10:00:00:01:40', WB = '02:10:00:00:01:41', D = '02:10:00:00:01:50';
	const wf = k => AR.buildNet(smp({ up: (9600 + 2 * k).toFixed(1), sta: [['eth7', '5', WB, String(1000 + k * 30 * B), '1000', -55, 864, 864, 100, 0, 'ax', 2, 80]],
		nodes: [{ mac: W, ip: '192.168.50.24', model: 'RT-AX86U', alias: 'Hall', sta: WB, state: 'ok', up: (4000 + 2 * k).toFixed(1), c: [],
			u: [['eth6', String(1000 + k * 30 * B), '1000']], w: [['eth3', 1, 1000, '1000', String(1000 + k * 12 * B)]], m: [['eth3', D]] },
			{ mac: D, ip: '192.168.50.25', model: 'RT-AX58U', alias: 'Den', sta: '', state: 'nokey', up: null, c: [] }] }));
	wf(0); const n3 = wf(1), den = n3.nodes[1], hall = n3.nodes[0];
	ok(den.online && den.via === hall && den.viaWired && den.bh.dn.toFixed(1) === '12.0' && hall.bh.dn.toFixed(1) === '18.0' && n3.total.dn.toFixed(1) === '30.0' && T.chainOf(n3, den.id)[0] === den.id,
		'a node wired behind a Wi-Fi node, not read: online, its backhaul the port in front of it; the node in front without it',
		[den.online, den.bh.dn.toFixed(1), hall.bh.dn.toFixed(1), n3.total.dn.toFixed(1)].join(' '));
}

// ---- 25. a router port a node is behind, on a switch with a PC and a NAS: they show on that port (a switch with its two
// devices), with what the port carries beyond the node when it counts its own; when it isn't read, their traffic is in its
// figure (not reported apart), and the whole network counts the port once either way
{
	const ND = '02:10:00:00:02:10', B = 250000;
	const bz = (k, read) => AR.buildNet(smp({ up: (9800 + 2 * k).toFixed(1), ports: ['eth1'], links: [['eth0', 1, 1000], ['eth1', 1, 1000]], plab: { eth1: '2' },
		ifs: [['eth0', '1', '1'], ['eth1', '1000', String(1000 + k * 80 * B)]], macs: [['eth1', ND], ['eth1', '00:00:5E:00:53:D1'], ['eth1', '00:00:5E:00:53:D2']],
		nodes: [read ? { mac: ND, ip: '192.168.50.31', model: 'GT-AXE16000', alias: 'Lounge', sta: '', state: 'ok', up: (5000 + 2 * k).toFixed(1), c: [], u: [['eth0', String(1000 + k * 30 * B), '1000']] }
			: { mac: ND, ip: '192.168.50.31', model: 'GT-AXE16000', alias: 'Lounge', sta: '', state: 'nokey', up: null, c: [] }] }));
	['p:eth1', 'pb:eth1'].forEach(k => { delete A.prev[k]; delete A.sm[k]; });
	bz(0, true); const n = bz(1, true), sw = n.byId['port:eth1'];
	A.sel = 'port:eth1'; const ro = T.readoutFor(n); A.sel = null;
	ok(sw && sw.count === 2 && sw.behind.length === 2 && sw.st === 'ok' && sw.dn.toFixed(1) === '50.0' && n.nodes[0].bh.dn.toFixed(1) === '30.0' && n.total.dn.toFixed(1) === '80.0'
		&& sw.portLabel === 'LAN 2' && /On a switch with Lounge/.test(ro.note),
		'a PC and a NAS on a switch with a node: on its router port, with the port\'s traffic beyond the node\'s', JSON.stringify({ dn: sw && sw.dn, node: n.nodes[0].bh.dn, total: n.total.dn, note: ro.note }));
	bz(2, false); const n2 = bz(3, false), sw2 = n2.byId['port:eth1'];
	ok(sw2 && sw2.count === 2 && sw2.st === 'nodata' && n2.nodes[0].bh.dn.toFixed(1) === '80.0' && n2.total.dn.toFixed(1) === '80.0',
		'the same with the node not read: the devices show, their traffic in the node\'s figure, the port counted once', JSON.stringify({ st: sw2 && sw2.st, node: n2.nodes[0].bh.dn, total: n2.total.dn }));
}

// ---- 26. a bond (LAN 3+4 for a NAS) is named by its ports, whatever their speed together; a port that the firmware maps (LAN 2
// through a VLAN interface) is named by its number
{
	const n = AR.buildNet(smp({ up: '9900.0', ports: ['eth3', 'bond0'], plab: { eth3: '2', bond0: '3+4' }, links: [['eth0', 1, 1000], ['eth3', 1, 1000, '2'], ['bond0', 1, 5000]],
		macs: [['eth3', '00:00:5E:00:53:E1'], ['bond0', '00:00:5E:00:53:E2']] }));
	const lab = m => (n.byId[m] || {}).portLabel;
	ok(lab('00:00:5E:00:53:E1') === 'LAN 2' && lab('00:00:5E:00:53:E2') === 'LAN 3+4' && n.byId['00:00:5E:00:53:E2'].speed === 5000,
		'a bond by its ports (LAN 3+4), a mapped port by its number', [lab('00:00:5E:00:53:E1'), lab('00:00:5E:00:53:E2')].join(' | '));
}

process.exit(fails ? 1 : 0);
