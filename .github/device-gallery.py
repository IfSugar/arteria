#!/usr/bin/env python3
"""Draws docs/devices.webp: every kind of device Arteria knows, with the page's own drawings and icons, and
example names that make a device that kind. Each example is checked against the page's name rules first,
so the picture never promises a name that doesn't work. Re-run it when kinds or name rules change.

Needs: Python 3 with Playwright (pip install playwright), Chrome or Chromium, and Pillow.
Usage: python3 .github/device-gallery.py [path to chrome]
"""
import asyncio, json, os, shutil, subprocess, sys, time
from playwright.async_api import async_playwright
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
OUT = os.path.join(REPO, 'docs', 'devices.webp')
CHROME = sys.argv[1] if len(sys.argv) > 1 else (shutil.which('google-chrome') or shutil.which('chromium') or None)
port = 8883

# kind -> example names (any one word or name in the list works; case doesn't matter). An empty list: no name
# makes it that kind (the router's icon does).
GROUPS = [
    ('Computers and phones', [
        ('desktop', ['Office PC', 'Gaming PC', 'DESKTOP-K3M9QZ1']), ('mac', ['Study iMac', 'Mac mini', 'Mac Studio']),
        ('laptop', ['Work laptop', 'MacBook Air', 'ThinkPad']), ('pi', ['Raspberry Pi', 'raspberrypi']),
        ('phone', ["Anna's iPhone", 'Pixel 8', 'Galaxy S24']), ('tablet', ['iPad', 'Galaxy Tab', 'Kindle']),
        ('watch', ['Apple Watch', 'Galaxy Watch'])]),
    ('TV, music and games', [
        ('tv', ['Living room TV', 'Bravia', 'LGwebOSTV']), ('streamer', ['Apple TV', 'Shield', 'Fire TV Cube']),
        ('stick', ['Fire TV Stick', 'Chromecast']), ('speaker', ['Kitchen speaker', 'Sonos Five', 'Bose']),
        ('smartspeaker', ['Echo Dot', 'HomePod', 'Nest Audio']), ('display', ['Echo Show', 'Nest Hub']),
        ('soundbar', ['Soundbar', 'Home cinema', 'Sonos Arc']), ('projector', ['Projector', 'Epson projector']),
        ('console', ['PS5', 'Xbox', 'Nintendo Switch']), ('vr', ['Quest 3', 'VR headset'])]),
    ('Home and office', [
        ('printer', ['Office printer', 'LaserJet', 'Brother printer']), ('printer3d', ['3D printer', 'Bambu', 'Prusa']),
        ('nas', ['Synology NAS', 'Ugreen NAS', 'JohnsNas']), ('switch', []),
        ('fitness', ['Peloton', 'Treadmill'])]),
    ('Smart home', [
        ('camera', ['Garage camera', 'Reolink', 'Baby monitor']), ('doorbell', ['Doorbell', 'Ring doorbell']),
        ('lock', ['Front door lock', 'Nuki']), ('garage', ['Garage door', 'MyQ']),
        ('thermostat', ['Thermostat', 'Nest thermostat', 'Ecobee']), ('boiler', ['Gas boiler', 'EMS-ESP', 'Water heater']),
        ('air', ['Bedroom AC', 'Daikin', 'Air conditioner']), ('purifier', ['Air purifier', 'Humidifier', 'Philips Air']),
        ('light', ['Hall lamp', 'Hue bulb', 'Ceiling light']), ('strip', ['LED strip', 'Govee strip', 'TV backlight']),
        ('wallswitch', ['Light switch', 'Dimmer', 'Shelly 1']), ('blinds', ['Smart blinds', 'Somfy']),
        ('plug', ['Smart plug', 'Tapo P110']), ('hub', ['Hue Bridge', 'Home Assistant', 'Zigbee hub']),
        ('contact', ['Door sensor', 'Window sensor']), ('sensor', ['Leak sensor', 'Motion sensor', 'Smoke detector']),
        ('vacuum', ['Robot vacuum', 'Roomba', 'Roborock']), ('washer', ['Washing machine', 'Washer']),
        ('dryer', ['Dryer', 'Tumble dryer']), ('dishwasher', ['Dishwasher']),
        ('appliance', ['Kitchen fridge', 'Oven', 'Coffee machine']), ('pet', ['Pet feeder', 'Cat feeder', 'Litter box']),
        ('iot', ['ESP32', 'Tuya', 'Sonoff'])]),
    ('Outdoors and energy', [
        ('car', ['Tesla', 'Car']), ('charger', ['EV charger', 'Wallbox', 'Easee']),
        ('solar', ['Solar inverter', 'Powerwall', 'Home battery']), ('mower', ['Robot mower', 'Automower']),
        ('sprinkler', ['Sprinkler', 'Rachio']), ('generic', [])]),
]
NOTE = {'switch': "the router's Router or Access point icon", 'generic': 'anything Arteria can’t tell'}

DRAW = r"""(groups) => {
  const T = Arteria._t, KL = T.KIND_LABEL, bad = [], seen = new Set();
  const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;');
  let h = '<div class="t">Arteria: ' + Object.keys(KL).length + ' kinds of device</div>' +
          '<div class="s">Put one of these words in a device’s name (in Arteria or the router’s client list), or pick the router’s icon for it.</div>';
  groups.forEach(([title, kinds]) => {
    h += '<div class="g">' + esc(title) + '</div><div class="row">';
    kinds.forEach(([k, names]) => {
      seen.add(k);
      names.forEach(n => { const r = T.nameKind(n); if (!r || r.kind !== k) bad.push(k + ': ' + n + ' -> ' + (r && r.kind)); });
      const o = T.objDevice('gal-' + k, k, 8, 8, 'L'), b = o.bbox(), p = 4;
      const vb = [b[0] - p, b[1] - p, b[2] - b[0] + 2 * p, b[3] - b[1] + 2 * p].map(v => v.toFixed(1)).join(' ');
      h += '<div class="c"><svg viewBox="' + vb + '" preserveAspectRatio="xMidYMax meet">' + o.svg.join('') + '</svg>' +
           '<div class="n">' + T.iconSvg(k, 15, '#d9e3e6') + '<span>' + esc(KL[k]) + '</span></div>' +
           '<div class="e">' + (names.length ? names.map(esc).join(' · ') : esc(NOTE[k] || '')) + '</div></div>';
    });
    h += '</div>';
  });
  Object.keys(KL).forEach(k => { if (!seen.has(k)) bad.push('not shown: ' + k); });
  const st = document.createElement('style');
  st.textContent = '#gal{position:absolute;left:0;top:0;width:1536px;padding:26px 32px 30px;background:#151b1d;z-index:99999;color:#e3eaec;font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}' +
    '#gal .t{font-size:24px;font-weight:700}#gal .s{font-size:14px;color:#a9b6ba;margin:4px 0 6px}' +
    '#gal .g{font-size:11.5px;letter-spacing:.09em;text-transform:uppercase;color:#8fa0a5;margin:16px 0 8px;font-weight:600}' +
    '#gal .row{display:grid;grid-template-columns:repeat(8,1fr);gap:10px}' +
    '#gal .c{background:#1c2427;border:1px solid #2a3438;border-radius:10px;padding:10px 10px 9px;height:170px;display:flex;flex-direction:column}' +
    '#gal svg{width:100%;height:108px;display:block}#gal .n{display:flex;align-items:center;gap:6px;margin-top:6px;font-size:13.5px;font-weight:650}' +
    '#gal .n svg{width:15px;height:15px;flex:none}#gal .e{font-size:11.5px;color:#9fb0b5;margin-top:3px;line-height:1.35}';
  document.head.appendChild(st);
  const g = document.createElement('div'); g.id = 'gal'; g.innerHTML = h;
  document.getElementById('ar').appendChild(g);
  return bad;
}"""


async def main():
    srv = subprocess.Popen([sys.executable, os.path.join(HERE, 'tests', 'preview.py'), 'home', str(port)], stdout=subprocess.DEVNULL)
    time.sleep(1)
    try:
        async with async_playwright() as p:
            b = await p.chromium.launch(executable_path=CHROME, args=['--no-sandbox'])
            pg = await b.new_page(viewport={'width': 1600, 'height': 1000}, device_scale_factor=1.25)
            await pg.goto('http://127.0.0.1:%d/user1.asp' % port)
            await pg.wait_for_function("document.querySelectorAll('#arMapLabels .ar-lb').length > 5", timeout=20000)
            await pg.evaluate("document.getElementById('ar').style.position = 'relative'")
            bad = await pg.evaluate(DRAW.replace('NOTE[k]', 'NOTE_[k]').replace('(groups) => {', '(groups) => { const NOTE_ = ' + json.dumps(NOTE) + ';'), GROUPS)
            if bad:
                sys.exit('examples that don\'t match the name rules, or kinds left out:\n  ' + '\n  '.join(bad))
            await pg.wait_for_timeout(600)
            png = OUT[:-5] + '.png'
            await (await pg.query_selector('#gal')).screenshot(path=png, animations='disabled')
            Image.open(png).convert('RGB').save(OUT, 'WEBP', quality=90, method=6)
            os.remove(png)
            print('docs/devices.webp: %dx%d, %d KB' % (*Image.open(OUT).size, os.path.getsize(OUT) // 1024))
            await b.close()
    finally:
        srv.terminate()


asyncio.run(main())
