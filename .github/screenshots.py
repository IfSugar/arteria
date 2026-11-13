#!/usr/bin/env python3
"""Takes the README's screenshots (docs/*.webp) from the page served by preview.py with made-up data.
Re-run it when the page changes; the animations come from demo-gif.py.

  map.webp       the map ("home" scenario)
  flow.webp      Flow
  map-sel.webp   a TV behind the node traced
  details.webp   the +N more list open and a phone's Details ("bulbs": 33 devices, private addresses)
  rename.webp    renaming a device: the field, and what the new name will make it
  zoom.webp      the expanded map zoomed in on the node, a device traced
  expanded.webp  the expanded view at 1600 x 900 ("bulbs")

Needs: Python 3 with Playwright (pip install playwright), Chrome or Chromium, and Pillow.
Usage: python3 .github/screenshots.py [path to chrome [shot ...]]   (about 5 minutes: each page samples for a while first,
Flow for two minutes so its internet chart is full; name shots, e.g. flow zoom, to take only those)
"""
import asyncio, os, shutil, subprocess, sys, time
from playwright.async_api import async_playwright
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
DOCS = os.path.join(REPO, 'docs')
CHROME = sys.argv[1] if len(sys.argv) > 1 else (shutil.which('google-chrome') or shutil.which('chromium') or None)
ONLY = set(sys.argv[2:])
want = lambda name: not ONLY or name in ONLY
WARM = 18000   # ms of sampling first: rates, smoothing, the busiest list and the stand slots settle
TV, LAPTOP, PHONE, DESKTOP = '00:00:5E:00:53:11', '00:00:5E:00:53:05', '06:CC:00:00:02:04', '00:00:5E:00:53:81'


def webp(png, name):
    out = os.path.join(DOCS, name)
    Image.open(png).convert('RGB').save(out, 'WEBP', quality=88, method=6)
    os.remove(png)
    print('docs/%s: %dx%d, %d KB' % (name, *Image.open(out).size, os.path.getsize(out) // 1024))


async def page(b, port, w=900, h=1000, scale=2, warm=WARM):
    pg = await b.new_page(viewport={'width': w, 'height': h}, device_scale_factor=scale)
    await pg.goto('http://127.0.0.1:%d/user1.asp' % port)
    await pg.evaluate('localStorage.clear()')
    await pg.wait_for_timeout(warm)
    await pg.mouse.move(2, 2)
    return pg


async def shot(pg, name, full=False):
    png = os.path.join(DOCS, name + '.png')
    await pg.mouse.move(2, 2); await pg.wait_for_timeout(400)
    if full: await pg.screenshot(path=png)
    else: await (await pg.query_selector('#ar')).screenshot(path=png)
    webp(png, name + '.webp')
    await pg.close()


async def label(pg, mac):
    await pg.dispatch_event('#arMapLabels .ar-lb[data-id="%s"]' % mac, 'click'); await pg.wait_for_timeout(900)


async def main():
    home = subprocess.Popen([sys.executable, os.path.join(HERE, 'tests', 'preview.py'), 'home', '8881'], stdout=subprocess.DEVNULL)
    bulbs = subprocess.Popen([sys.executable, os.path.join(HERE, 'tests', 'preview.py'), 'bulbs', '8882'], stdout=subprocess.DEVNULL)
    time.sleep(1)
    try:
        async with async_playwright() as p:
            b = await p.chromium.launch(executable_path=CHROME, args=['--no-sandbox'])
            if want('map'):
                pg = await page(b, 8881); await shot(pg, 'map')
            if want('flow'):
                pg = await page(b, 8881, warm=125000); await pg.click('#arTabFlow'); await pg.wait_for_timeout(2500); await shot(pg, 'flow')
            if want('map-sel'):
                pg = await page(b, 8881); await label(pg, TV); await pg.wait_for_timeout(1500); await shot(pg, 'map-sel')
            if want('details'):
                pg = await page(b, 8882); await label(pg, 'more')
                await pg.click('#arMoreList button:has-text("Annas-iPhone")'); await pg.wait_for_timeout(800)
                await pg.click('#arRoDet'); await pg.wait_for_timeout(1200); await shot(pg, 'details')
            if want('rename'):
                pg = await page(b, 8881); await label(pg, LAPTOP)
                await pg.click('#arRoEdit'); await pg.keyboard.type('Study iMac', delay=40); await pg.wait_for_timeout(800)
                await shot(pg, 'rename')
            if want('zoom'):   # the expanded view in a window the shape of the page's own view, zoomed in on the node with a TV traced
                pg = await page(b, 8881, 1000, 1100)
                await pg.click('#arBig'); await pg.wait_for_timeout(1500); await label(pg, TV)
                bb = await (await pg.query_selector('#arMapLabels .ar-lb[data-id="%s"]' % TV)).bounding_box()
                x, y = bb['x'] + bb['width'] / 2 - 60, bb['y'] - 40
                for _ in range(14):   # a pinch to about 2x
                    await pg.evaluate("([x, y]) => document.getElementById('arMap').dispatchEvent(new WheelEvent('wheel', { deltaY: -5, ctrlKey: true, clientX: x, clientY: y, bubbles: true, cancelable: true }))", [x, y])
                await pg.wait_for_timeout(2500); await shot(pg, 'zoom', full=True)
            if want('expanded'):
                pg = await page(b, 8882, 1600, 900, 1.25)
                await pg.click('#arBig'); await pg.wait_for_timeout(1500); await label(pg, DESKTOP); await pg.wait_for_timeout(1500)
                await shot(pg, 'expanded', full=True)
            await b.close()
    finally:
        home.terminate(); bulbs.terminate()


asyncio.run(main())
