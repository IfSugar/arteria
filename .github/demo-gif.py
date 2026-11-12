#!/usr/bin/env python3
"""Records docs/demo.gif, the README's demo: the page served by preview.py with made-up data
("home" scenario), driven by a drawn cursor. Re-run it when the page changes.

With --map it records docs/map.gif instead: the map alone, about 10 seconds at 600 px wide, small
enough (about 1 MB) to embed in a forum post.

Needs: Python 3 with Playwright (pip install playwright), Chrome or Chromium, Pillow and ffmpeg.
Usage: python3 .github/demo-gif.py [--map] [path to chrome]   (the full demo takes about 3 minutes:
the page runs for two minutes first, so the 2-minute internet chart is full)
"""
import asyncio, base64, io, os, shutil, subprocess, sys, tempfile, time
from playwright.async_api import async_playwright
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
MAP = '--map' in sys.argv
ARGS = [a for a in sys.argv[1:] if a != '--map']
OUT = os.path.join(REPO, 'docs', 'map.gif' if MAP else 'demo.gif')
CHROME = ARGS[0] if ARGS else (shutil.which('google-chrome') or shutil.which('chromium') or None)
FPS = 12 if MAP else 20
COLORS = 96 if MAP else 192
WIDTH = 600 if MAP else None   # the map GIF is scaled down: every moving packet costs bytes in every frame
port = 8871

CURSOR = """
(() => {
  const c = document.createElement('div'); c.id = 'demoCursor';
  c.innerHTML = '<svg width="22" height="26" viewBox="0 0 22 26"><path d="M2 2 L2 21 L7 16.5 L10.5 24 L14 22.5 L10.5 15 L17 15 Z" fill="#fff" stroke="#111" stroke-width="1.6" stroke-linejoin="round"/></svg>';
  Object.assign(c.style, { position: 'fixed', left: '0', top: '0', zIndex: 99999, pointerEvents: 'none', transition: 'transform .75s cubic-bezier(.45,.05,.25,1)', transform: 'translate(818px, 558px)', filter: 'drop-shadow(0 2px 3px rgba(0,0,0,.5))' });
  document.body.appendChild(c);
  const st = document.createElement('style');
  st.textContent = '@keyframes demoRip { from { transform: translate(-50%,-50%) scale(.2); opacity: .9 } to { transform: translate(-50%,-50%) scale(1); opacity: 0 } }';
  document.head.appendChild(st);
  window.demoMove = (x, y) => { c.style.transform = 'translate(' + (x - 2) + 'px,' + (y - 2) + 'px)'; };
  window.demoRipple = (x, y) => { const r = document.createElement('div'); Object.assign(r.style, { position: 'fixed', left: x + 'px', top: y + 'px', width: '44px', height: '44px', borderRadius: '50%', border: '2px solid #fff', zIndex: 99998, pointerEvents: 'none', animation: 'demoRip .6s ease-out forwards' }); document.body.appendChild(r); setTimeout(() => r.remove(), 700); };
})();
"""
frames = []
box = None

async def record():
    global box
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path=CHROME, args=['--no-sandbox'])
        pg = await b.new_page(viewport={'width': 900, 'height': 1000}, device_scale_factor=1)
        await pg.goto('http://127.0.0.1:%d/user1.asp' % port)
        await pg.evaluate("localStorage.clear()")
        await pg.wait_for_timeout(25000 if MAP else 125000)   # warm up: rates, stand slots (and for the full demo, a full 2-minute chart)
        await pg.evaluate(CURSOR)
        box = await pg.evaluate("() => { const s = document.querySelector('#ar .ar-stage').getBoundingClientRect(); return [s.left, s.top, s.width, s.height]; }") if MAP else await pg.evaluate("() => { const r = document.getElementById('ar').getBoundingClientRect(); const c = document.getElementById('arHist').closest('.ar-cards') || document.getElementById('arHist').parentElement; const cb = c.getBoundingClientRect(); return [r.left, r.top, r.width, cb.bottom - r.top]; }")
        cdp = await pg.context.new_cdp_session(pg)
        def on_frame(ev):
            frames.append((ev['metadata']['timestamp'], ev['data']))
            asyncio.ensure_future(cdp.send('Page.screencastFrameAck', {'sessionId': ev['sessionId']}))
        cdp.on('Page.screencastFrame', on_frame)
        await cdp.send('Page.startScreencast', {'format': 'png', 'everyNthFrame': 1})

        async def click(sel, before=900, after=0):
            bb = await (await pg.query_selector(sel)).bounding_box()
            x, y = bb['x'] + bb['width'] / 2, bb['y'] + bb['height'] / 2
            await pg.evaluate('([x, y]) => demoMove(x, y)', [x, y]); await pg.wait_for_timeout(before)
            await pg.evaluate('([x, y]) => demoRipple(x, y)', [x, y]); await pg.click(sel, force=True)
            await pg.wait_for_timeout(after)

        if MAP:
            await pg.wait_for_timeout(3000)                                   # the map, flowing
            await click('.ar-lb[data-id="00:00:5E:00:53:11"]', after=3400)     # trace a TV behind the node
            await click('.ar-lb[data-id="00:00:5E:00:53:11"]', before=600, after=900)   # let go
            await pg.evaluate('demoMove(820, 560)'); await pg.wait_for_timeout(1500)   # rest where it started, for a clean loop
            await cdp.send('Page.stopScreencast')
            await pg.wait_for_timeout(300)
            await b.close()
            return
        await pg.wait_for_timeout(3500)                                   # the map, flowing
        await click('.ar-lb[data-id="00:00:5E:00:53:11"]', after=3400)     # trace a TV behind the node
        await click('#arRoDet', after=3200)                                # its details
        await click('#arRoDet', before=600, after=500)
        await click('.ar-lb[data-id="00:00:5E:00:53:11"]', before=700, after=1000)   # let go
        await click('.ar-lb[data-id="more"]', after=2200)                  # the "+N more" tray opens a list
        await click('#arMoreList button:nth-child(2)', after=3000)         # trace one of its devices
        await click('#arMoreClose', before=700, after=1000)
        await click('#arTabFlow', after=3600)                              # Flow: download
        await click('#arUp', after=3200)                                   # Flow: upload
        await click('#arUnitMB', after=2600)                               # MB/s
        await click('#arUnitMb', before=700, after=600)                    # back to Mb/s
        await click('#arDn', before=700, after=400)
        await click('#arTabMap', after=1500)                               # back to the map
        await pg.evaluate('demoMove(820, 560)'); await pg.wait_for_timeout(1700)   # rest where it started, for a clean loop
        await cdp.send('Page.stopScreencast')
        await pg.wait_for_timeout(300)
        await b.close()

def build(tmp):
    """Crop to the addon, resample to FPS, and encode a looping GIF with one shared palette."""
    t0 = frames[0][0]
    seq = [(ts - t0, data) for ts, data in frames]
    crop = (int(box[0]), int(box[1]), int(box[0] + box[2]), int(box[1] + box[3]))
    n, j, shown, img = int(seq[-1][0] * FPS), 0, -1, None
    for i in range(n):   # each output frame shows the newest screencast frame at its time
        while j + 1 < len(seq) and seq[j + 1][0] <= i / FPS: j += 1
        if j != shown:
            shown, img = j, Image.open(io.BytesIO(base64.b64decode(seq[j][1]))).convert('RGB').crop(crop)
        img.save(os.path.join(tmp, 's%05d.png' % i))
    pal = os.path.join(tmp, 'palette.png')
    src = ['-framerate', str(FPS), '-i', os.path.join(tmp, 's%05d.png')]
    sc = 'scale=%d:-1:flags=lanczos,' % WIDTH if WIDTH else ''
    subprocess.run(['ffmpeg', '-v', 'error', '-y'] + src + ['-vf', sc + 'palettegen=max_colors=%d:stats_mode=diff' % COLORS, pal], check=True)
    subprocess.run(['ffmpeg', '-v', 'error', '-y'] + src + ['-i', pal, '-lavfi', ('[0:v]' + sc.rstrip(',') + '[x];[x][1:v]' if sc else '') + 'paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle', '-loop', '0', OUT], check=True)
    print('%s: %d frames, %d KB' % (os.path.relpath(OUT, REPO), n, os.path.getsize(OUT) // 1024))

if __name__ == '__main__':
    srv = subprocess.Popen([sys.executable, os.path.join(HERE, 'tests', 'preview.py'), 'home', str(port)], stdout=subprocess.DEVNULL)
    try:
        time.sleep(1)
        asyncio.run(record())
    finally:
        srv.terminate()
    with tempfile.TemporaryDirectory() as tmp:
        build(tmp)
