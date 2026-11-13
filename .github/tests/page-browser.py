#!/usr/bin/env python3
"""Drives the page in a real browser (headless Chrome), against preview.py's made-up data, in every scenario:

  1. no page or console errors, in the page's view and the expanded view, on Map and Flow, with the
     "+N more" list, Details and the device report open;
  2. the expanded view: Escape closes the report, then the list, then the view; Tab never leaves it;
     closing puts the stage back where it was, 728 x 518, inside the router's page;
  3. the "hostile" scenario: names and AiMesh client-list keys that look like HTML stay text and run nothing;
  4. two Arteria tabs: closing one doesn't tell the router to stop sampling while the other is open;
  5. in every scenario, labels keep off other devices' drawings, and what is cut short shows in full on hover.

Needs Python 3 with Playwright (pip install playwright; the browser is the system's Chrome or Chromium).
Usage: python3 .github/tests/page-browser.py [path to chrome]
"""
import asyncio, os, shutil, subprocess, sys, time
from playwright.async_api import async_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
CHROME = sys.argv[1] if len(sys.argv) > 1 else (shutil.which('google-chrome') or shutil.which('chromium') or shutil.which('chromium-browser'))
SCENARIOS = ['home', 'bulbs', 'kinds1', 'kinds2', 'kinds3', 'kinds4', 'nokey', 'offline', 'weak', 'busy', 'quiet', 'nonode', 'hostile']
fails = []


def check(cond, what):
    print(('ok    ' if cond else 'FAIL  ') + what)
    if not cond:
        fails.append(what)


INJECTED = """() => ({ els: document.querySelectorAll('#ar img, #ar script, #ar iframe, #ar a[href^="javascript"], #ar [onload], #ar [onerror]').length,
    xss: window.__xss || 0 })"""
STAGE = """() => { const s = document.querySelector('#ar .ar-stage').getBoundingClientRect(), ar = document.getElementById('ar');
    return { w: Math.round(s.width), h: Math.round(s.height), x: Math.round(s.left), td: ar.parentNode.tagName, big: Arteria.state.big }; }"""


async def serve(scn, port):
    srv = subprocess.Popen([sys.executable, os.path.join(HERE, 'preview.py'), scn, str(port)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(50):   # until it answers
        try:
            r, w = await asyncio.open_connection('127.0.0.1', port); w.close(); break
        except OSError:
            await asyncio.sleep(0.1)
    return srv


async def ready(pg):   # two samples in: rates, stands and the tray are known
    await pg.wait_for_function("window.Arteria && Arteria.state.gotAny && Arteria.state.net", timeout=20000)
    await pg.wait_for_timeout(300)


async def scenario(b, scn, port):
    srv = await serve(scn, port)
    try:
        ctx = await b.new_context(viewport={'width': 1600, 'height': 900})
        pg = await ctx.new_page()
        errs = []
        pg.on('pageerror', lambda e: errs.append(str(e)))
        pg.on('console', lambda m: errs.append(m.text) if m.type == 'error' and 'Failed to load resource' not in m.text else None)
        await pg.goto('http://127.0.0.1:%d/user1.asp' % port)
        await ready(pg)
        small = await pg.evaluate(STAGE)
        tag = scn.ljust(8)
        # the page's view: Flow, the list, Details, the report
        await pg.click('#arTabFlow'); await pg.wait_for_timeout(250)
        await pg.click('#arTabMap'); await pg.wait_for_timeout(250)
        more = await pg.query_selector('#arMapLabels .ar-lb[data-id="more"]')
        if more:
            await more.click(); await pg.wait_for_timeout(250)
            first = await pg.query_selector('#arMoreList button')
            if first:
                await first.click(); await pg.wait_for_timeout(250)
        dev = await pg.evaluate("(Arteria.state.net.devs.find(d => d.mac && d.st === 'ok') || {}).id || ''")
        if dev:
            await pg.evaluate("(id) => { Arteria.state.sel = null; Arteria.pick(id); }", dev); await pg.wait_for_timeout(250)
            if await pg.is_visible('#arRoDet'):
                await pg.click('#arRoDet'); await pg.wait_for_timeout(250); await pg.click('#arRoDet')
        await pg.click('#arRepBtn'); await pg.wait_for_timeout(250)
        await pg.keyboard.press('Escape'); await pg.wait_for_timeout(300)
        # the expanded view
        await pg.evaluate("Arteria.pick(null)")
        await pg.click('#arBig'); await pg.wait_for_timeout(400)
        await pg.click('#arTabFlow'); await pg.wait_for_timeout(250)
        await pg.click('#arTabMap'); await pg.wait_for_timeout(250)
        order = []
        await pg.click('#arRepBtn'); await pg.wait_for_timeout(200)
        more = await pg.query_selector('#arMapLabels .ar-lb[data-id="more"]')
        if more:   # the report and the list can't both be open: the list is opened after the report is closed
            await pg.keyboard.press('Escape'); await pg.wait_for_timeout(200)
            order.append(await pg.evaluate("({ big: Arteria.state.big, rep: !!Arteria.state.report })"))
            await more.click(); await pg.wait_for_timeout(250)
            await pg.mouse.click(5, 5); await pg.wait_for_timeout(200)   # focus outside the list
            await pg.keyboard.press('Escape'); await pg.wait_for_timeout(200)
            order.append(await pg.evaluate("({ big: Arteria.state.big, list: !document.getElementById('arMore').classList.contains('hide') })"))
            ok_order = order[0] == {'big': True, 'rep': False} and order[1] == {'big': True, 'list': False}
        else:
            await pg.keyboard.press('Escape'); await pg.wait_for_timeout(200)
            st = await pg.evaluate("({ big: Arteria.state.big, rep: !!Arteria.state.report })")
            ok_order = st == {'big': True, 'rep': False}
        await pg.focus('#arBig')
        out = 0
        for _ in range(40):
            await pg.keyboard.press('Tab')
            if not await pg.evaluate("document.getElementById('ar').contains(document.activeElement)"):
                out += 1
        await pg.keyboard.press('Escape'); await pg.wait_for_timeout(250)
        after = await pg.evaluate(STAGE)
        await pg.wait_for_timeout(2200)   # one more sample after all of it: errors in the next render show up too
        inj = await pg.evaluate(INJECTED)
        # a device's label doesn't cover another device's drawing (on a crowded floor, one may have to)
        cover = await pg.evaluate('''() => {
            const objs = [...document.querySelectorAll('#ar g[data-obj]')].map(g => [g.getAttribute('data-obj'), g.getBoundingClientRect()]);
            let n = 0;
            document.querySelectorAll('#ar .ar-lb').forEach(b => {
                const r = b.firstElementChild.getBoundingClientRect(), id = b.getAttribute('data-id');
                objs.forEach(([oid, o]) => { if (oid !== id && o.width && r.left < o.right - 2 && o.left + 2 < r.right && r.top < o.bottom - 2 && o.top + 2 < r.bottom) n++; });
            });
            return n;
        }''')
        # anything cut short with "…" (a name, a maker, a path) shows in full on hover
        tip = await pg.evaluate('''() => {
            const cut = [...document.querySelectorAll('#ar *')].filter(e => e.clientWidth && e.scrollWidth > e.clientWidth + 1 && e.offsetParent && !e.children.length);
            const btn = [...document.querySelectorAll('#ar .ar-lb[title]')];
            if (!cut.length && !btn.length) return null;
            const bad = cut.filter(e => { e.dispatchEvent(new MouseEvent('mouseover', { bubbles: true })); return e.title !== e.textContent.trim(); });
            return { n: cut.length + btn.length, bad: bad.length, btn: btn.every(b => b.title.length > b.querySelector('.n').textContent.length - 1) };
        }''')
        await ctx.close()
        check(not errs, tag + 'no page errors' + ('' if not errs else ': ' + ' / '.join(errs[:3])))
        check(small['w'] == 728 and small['h'] == 518 and small['td'] == 'TD', tag + 'the page\'s view is 728 x 518 inside the router\'s page')
        check(ok_order, tag + 'Escape closes the report, then the list, and keeps the expanded view open')
        check(out == 0, tag + 'Tab stays inside the expanded view')
        check(after == small, tag + 'closing the expanded view puts the stage back as it was')
        check(inj['els'] == 0 and not inj['xss'], tag + 'nothing that looks like HTML became markup or ran')
        check(cover <= (1 if scn in ('bulbs', 'busy', 'hostile') else 0), tag + 'labels don\'t cover other devices (%d)' % cover)
        if tip is not None:
            check(tip['bad'] == 0 and tip['btn'], tag + 'what is cut short shows in full on hover (%d)' % tip['n'])
    finally:
        srv.terminate()


async def two_tabs(b, port):
    """Two Arteria tabs: when one stops (paused, or closed), it doesn't tell the router to stop sampling while the
    other one is still showing it; the last one does. (Pausing sends the same request as closing a tab.)"""
    srv = await serve('home', port)
    try:
        ctx = await b.new_context()
        stops = []
        # the stop request is the page's only beacon (a "ping"; its body isn't visible here)
        ctx.on('request', lambda r: stops.append(1) if r.resource_type == 'ping' and 'start_apply' in r.url else None)
        a = await ctx.new_page(); await a.goto('http://127.0.0.1:%d/user1.asp' % port)
        c = await ctx.new_page(); await c.goto('http://127.0.0.1:%d/user1.asp' % port)
        await ready(a); await ready(c)   # both have sent a heartbeat
        await a.click('#arLive'); await a.wait_for_timeout(800)
        first = len(stops)
        await c.click('#arLive'); await c.wait_for_timeout(800)
        check(first == 0, 'two tabs: pausing or closing one doesn\'t stop the sampling the other one is showing')
        check(len(stops) == 1, 'two tabs: the last one to stop tells the router to stop')
        await ctx.close()
    finally:
        srv.terminate()


async def main():
    if not CHROME:
        sys.exit('page-browser.py needs Chrome or Chromium (or its path as the argument)')
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path=CHROME, args=['--no-sandbox'])
        # every scenario at once, each in its own browser context against its own preview server
        await asyncio.gather(*[scenario(b, s, 8700 + i) for i, s in enumerate(SCENARIOS)], two_tabs(b, 8790))
        await b.close()


t0 = time.time()
asyncio.run(main())
print('Browser: %s (%d s)' % ('all checks passed.' if not fails else '%d failed.' % len(fails), time.time() - t0))
sys.exit(1 if fails else 0)
