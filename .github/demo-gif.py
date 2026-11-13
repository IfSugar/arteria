#!/usr/bin/env python3
"""Records docs/demo.webp, the README's demo (an animated WebP): the page served by preview.py with
made-up data ("home" scenario), driven by a drawn cursor. It traces a device, opens its details,
renames another one (its drawing changes), switches to Flow and the units, then opens the expanded
view and zooms and pans its map. Re-run it when the page changes.

With --forum it records docs/forum.gif instead, for forum posts (forums show GIFs, not animated WebP;
posts link to it on main): a quicker tour of the same page, the Map with a device traced, then Flow,
about 15 seconds at 560 px wide and small enough to embed (about 1.2 MB).

Needs: Python 3 with Playwright (pip install playwright), Chrome or Chromium, Pillow and ffmpeg
(with libwebp). Usage: python3 .github/demo-gif.py [--forum] [path to chrome]   (about 4 minutes:
the page runs for two minutes first, so the 2-minute internet chart is full)
"""
import asyncio, base64, io, os, shutil, subprocess, sys, tempfile, time
from playwright.async_api import async_playwright
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
FORUM = '--forum' in sys.argv
ARGS = [a for a in sys.argv[1:] if a != '--forum']
OUT = os.path.join(REPO, 'docs', 'forum.gif' if FORUM else 'demo.webp')
CHROME = ARGS[0] if ARGS else (shutil.which('google-chrome') or shutil.which('chromium') or None)
FPS = 10 if FORUM else 15
COLORS = 96 if FORUM else 192
WIDTH = 560 if FORUM else None   # the forum GIF is scaled down: every moving packet costs bytes in every frame
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
  window.demoGlide = (on) => { c.style.transition = on ? '' : 'none'; };   // off while it follows a drag step by step
  window.demoRipple = (x, y) => { const r = document.createElement('div'); Object.assign(r.style, { position: 'fixed', left: x + 'px', top: y + 'px', width: '44px', height: '44px', borderRadius: '50%', border: '2px solid #fff', zIndex: 99998, pointerEvents: 'none', animation: 'demoRip .6s ease-out forwards' }); document.body.appendChild(r); setTimeout(() => r.remove(), 700); };
})();
"""
frames = []
box = None
full = []   # (from, to) screencast times when the expanded view fills the window: those frames show the whole window

async def record():
    global box
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path=CHROME, args=['--no-sandbox'])
        pg = await b.new_page(viewport={'width': 900, 'height': 1000}, device_scale_factor=1)
        await pg.goto('http://127.0.0.1:%d/user1.asp' % port)
        await pg.evaluate("localStorage.clear()")
        await pg.wait_for_timeout(125000)   # warm up: rates, stand slots and a full 2-minute internet chart
        await pg.evaluate(CURSOR)
        if FORUM:   # a quicker cursor
            await pg.evaluate("document.getElementById('demoCursor').style.transition = 'transform .45s cubic-bezier(.45,.05,.25,1)'")
        box = await pg.evaluate("() => { const r = document.getElementById('ar').getBoundingClientRect(); const c = document.getElementById('arHist').closest('.ar-cards') || document.getElementById('arHist').parentElement; const cb = c.getBoundingClientRect(); return [r.left, r.top, r.width, cb.bottom - r.top]; }")
        cdp = await pg.context.new_cdp_session(pg)
        def on_frame(ev):
            frames.append((ev['metadata']['timestamp'], ev['data']))
            asyncio.ensure_future(cdp.send('Page.screencastFrameAck', {'sessionId': ev['sessionId']}))
        cdp.on('Page.screencastFrame', on_frame)
        await cdp.send('Page.startScreencast', {'format': 'png', 'everyNthFrame': 1})

        async def click(sel, before=550 if FORUM else 900, after=0):
            bb = await (await pg.query_selector(sel)).bounding_box()
            x, y = bb['x'] + bb['width'] / 2, bb['y'] + bb['height'] / 2
            await pg.evaluate('([x, y]) => demoMove(x, y)', [x, y]); await pg.wait_for_timeout(before)
            await pg.evaluate('([x, y]) => demoRipple(x, y)', [x, y]); await pg.click(sel, force=True)
            await pg.wait_for_timeout(after)

        if FORUM:
            await pg.wait_for_timeout(1600)                                   # the map, flowing
            await click('.ar-lb[data-id="00:00:5E:00:53:11"]', after=2400)     # trace a TV behind the node
            await click('.ar-lb[data-id="00:00:5E:00:53:11"]', before=400, after=500)   # let go
            await click('#arTabFlow', after=2400)                              # Flow: download
            await click('#arUp', after=1800)                                   # Flow: upload
            await click('#arDn', before=400, after=300)
            await click('#arTabMap', after=600)                                # back to the map
            await pg.evaluate('demoMove(820, 560)'); await pg.wait_for_timeout(900)   # rest where it started, for a clean loop
            await cdp.send('Page.stopScreencast')
            await pg.wait_for_timeout(300)
            await b.close()
            return
        await pg.wait_for_timeout(3000)                                   # the map, flowing
        await click('.ar-lb[data-id="00:00:5E:00:53:11"]', after=3000)     # trace a TV behind the node
        await click('#arRoDet', after=2800)                                # its details
        await click('#arRoDet', before=600, after=500)
        # rename the work laptop: the icon shows what it will be while typing, and once saved the map draws an iMac
        await click('.ar-lb[data-id="00:00:5E:00:53:05"]', before=700, after=1400)
        await click('#arRoEdit', before=600, after=500)
        await pg.keyboard.type('Study iMac', delay=120); await pg.wait_for_timeout(1300)
        await click('#arRoOk', before=500, after=3200)
        await click('.ar-lb[data-id="00:00:5E:00:53:05"]', before=700, after=900)   # let go
        await click('#arTabFlow', after=3200)                              # Flow: download
        await click('#arUp', after=2800)                                   # Flow: upload
        await click('#arUnitMB', after=2400)                               # MB/s
        await click('#arUnitMb', before=700, after=500)                    # back to Mb/s
        await click('#arDn', before=700, after=400)
        await click('#arTabMap', after=1200)                               # back to the map
        # the expanded view fills the window: zoom in around the node with a trackpad pinch, drag the map, back to 100%
        t0 = time.time(); await click('#arBig', after=2200)
        full.append([t0 + 0.05, None])
        lb = await (await pg.query_selector('.ar-lb[data-id="00:00:5E:00:53:11"]')).bounding_box()
        zx, zy = lb['x'] + lb['width'] / 2, lb['y'] + lb['height'] + 30
        await pg.evaluate('([x, y]) => demoMove(x, y)', [zx, zy]); await pg.wait_for_timeout(900); await pg.mouse.move(zx, zy)
        for _ in range(16):   # about 2.2x
            await pg.evaluate("([x, y]) => document.getElementById('arMap').dispatchEvent(new WheelEvent('wheel', { deltaY: -5, ctrlKey: true, clientX: x, clientY: y, bubbles: true, cancelable: true }))", [zx, zy])
            await pg.wait_for_timeout(35)
        await pg.wait_for_timeout(1600)
        await pg.evaluate('demoGlide(false)'); await pg.mouse.down()
        for k in range(1, 31):   # drag the map to the right and down a little
            x, y = zx + 150 * k / 30, zy + 60 * k / 30
            await pg.mouse.move(x, y); await pg.evaluate('([x, y]) => demoMove(x, y)', [x, y]); await pg.wait_for_timeout(30)
        await pg.mouse.up(); await pg.evaluate('demoGlide(true)'); await pg.wait_for_timeout(1500)
        await click('#arZoomFit', after=1600)                              # the whole map again
        await click('#arBig', before=700, after=0)                         # back to the page
        full[-1][1] = time.time() + 0.05; await pg.wait_for_timeout(1300)
        await pg.evaluate('demoMove(820, 560)'); await pg.wait_for_timeout(1700)   # rest where it started, for a clean loop
        await cdp.send('Page.stopScreencast')
        await pg.wait_for_timeout(300)
        await b.close()

def frame(ts, data):
    """One screencast frame, cropped to the addon; while the expanded view fills the window, the whole window
    scaled to the same size (the window and the addon have nearly the same shape), on the page's background."""
    im = Image.open(io.BytesIO(base64.b64decode(data))).convert('RGB')
    w, h = int(box[2]), int(box[3])
    if any(a <= ts and (b is None or ts < b) for a, b in full):
        sc = min(w / im.width, h / im.height)
        im = im.resize((round(im.width * sc), round(im.height * sc)), Image.LANCZOS)
        out = Image.new('RGB', (w, h), im.getpixel((2, im.height - 2)))
        out.paste(im, ((w - im.width) // 2, (h - im.height) // 2))
        return out
    return im.crop((int(box[0]), int(box[1]), int(box[0]) + w, int(box[1]) + h))

def build(tmp):
    """Resample to FPS, then encode a looping GIF with one shared palette (--forum), or an animated WebP."""
    t0 = frames[0][0]
    seq = [(ts - t0, ts, data) for ts, data in frames]
    n, j, shown, img = int(seq[-1][0] * FPS), 0, -1, None
    for i in range(n):   # each output frame shows the newest screencast frame at its time
        while j + 1 < len(seq) and seq[j + 1][0] <= i / FPS: j += 1
        if j != shown:
            shown, img = j, frame(seq[j][1], seq[j][2])
        img.save(os.path.join(tmp, 's%05d.png' % i))
    src = ['-framerate', str(FPS), '-i', os.path.join(tmp, 's%05d.png')]
    if FORUM:
        pal = os.path.join(tmp, 'palette.png')
        sc = 'scale=%d:-1:flags=lanczos,' % WIDTH if WIDTH else ''
        subprocess.run(['ffmpeg', '-v', 'error', '-y'] + src + ['-vf', sc + 'palettegen=max_colors=%d:stats_mode=diff' % COLORS, pal], check=True)
        subprocess.run(['ffmpeg', '-v', 'error', '-y'] + src + ['-i', pal, '-lavfi', ('[0:v]' + sc.rstrip(',') + '[x];[x][1:v]' if sc else '') + 'paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle', '-loop', '0', OUT], check=True)
    else:
        subprocess.run(['ffmpeg', '-v', 'error', '-y'] + src + ['-c:v', 'libwebp_anim', '-lossless', '0', '-quality', '65',
                        '-compression_level', '6', '-loop', '0', '-an', OUT], check=True)
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
