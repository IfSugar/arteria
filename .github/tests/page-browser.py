#!/usr/bin/env python3
"""Drives the page in a real browser (headless Chrome), against preview.py's made-up data, in every scenario:

  1. no page or console errors, in the page's view and the expanded view, on Map and Flow, with the
     "+N more" list, Details and the device report open;
  2. the expanded view: Escape closes the report, then the list, then the view; Tab never leaves it;
     closing puts the stage back where it was, 728 x 518, inside the router's page;
  3. the "hostile" scenario: names and AiMesh client-list keys that look like HTML stay text and run nothing;
  4. two Arteria tabs: closing one doesn't tell the router to stop sampling while the other is open;
  5. in every scenario, labels keep off other devices' drawings, what is cut short shows in full on hover, and the
     totals in the tab bar don't move as their numbers change;
  6. in every scenario and both views, no device's drawing overlaps another's, every label's line is short, and no two
     lines cross.

Needs Python 3 with Playwright (pip install playwright; the browser is the system's Chrome or Chromium).
Usage: python3 .github/tests/page-browser.py [path to chrome]
"""
import asyncio, os, shutil, subprocess, sys, time
from playwright.async_api import async_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
CHROME = sys.argv[1] if len(sys.argv) > 1 else (shutil.which('google-chrome') or shutil.which('chromium') or shutil.which('chromium-browser'))
SCENARIOS = ['home', 'bulbs', 'crowd', 'house', 'kinds1', 'kinds2', 'kinds3', 'kinds4', 'kinds5', 'kinds6', 'newer', 'nokey', 'offline', 'weak', 'busy', 'quiet', 'nonode', 'hostile', 'mesh4', 'nodecrowd', 'wired',
             'meshswitch', 'meshswitch1', 'meshswitch2', 'meshchain', 'meshnokey']
fails = []


def check(cond, what):
    print(('ok    ' if cond else 'FAIL  ') + what)
    if not cond:
        fails.append(what)


INJECTED = """() => ({ els: document.querySelectorAll('#ar img, #ar script, #ar iframe, #ar a[href^="javascript"], #ar [onload], #ar [onerror]').length,
    xss: window.__xss || 0 })"""
STAGE = """() => { const s = document.querySelector('#ar .ar-stage').getBoundingClientRect(), ar = document.getElementById('ar');
    return { w: Math.round(s.width), h: Math.round(s.height), x: Math.round(s.left), td: ar.parentNode.tagName, big: Arteria.state.big }; }"""


async def serve(scn, port, env=None):
    srv = subprocess.Popen([sys.executable, os.path.join(HERE, 'preview.py'), scn, str(port)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                           env=dict(os.environ, **(env or {})))
    for _ in range(50):   # until it answers
        try:
            r, w = await asyncio.open_connection('127.0.0.1', port); w.close(); break
        except OSError:
            await asyncio.sleep(0.1)
    return srv


LABEL_OVERLAPS = '''() => {
    const rs = [...document.querySelectorAll('#ar .ar-lb')].map(b => b.firstElementChild.getBoundingClientRect()).filter(r => r.width);
    let n = 0;
    rs.forEach((a, i) => rs.slice(i + 1).forEach(b => { if (a.left < b.right - 1 && b.left < a.right - 1 && a.top < b.bottom - 1 && b.top < a.bottom - 1) n++; }));
    return n;
}'''


# labels that cover another device's drawing
LABEL_COVERS = '''() => {
    const objs = [...document.querySelectorAll('#ar g[data-obj]')].map(g => [g.getAttribute('data-obj'), g.getBoundingClientRect()]);
    let n = 0;
    document.querySelectorAll('#ar .ar-lb').forEach(b => {
        const r = b.firstElementChild.getBoundingClientRect(), id = b.getAttribute('data-id');
        objs.forEach(([oid, o]) => { if (oid !== id && o.width && r.left < o.right - 2 && o.left + 2 < r.right && r.top < o.bottom - 2 && o.top + 2 < r.bottom) n++; });
    });
    return n;
}'''



# traffic lines that run under a label: a line may pass under its own device's label, and under the label of the hub it
# leaves (the router, a node, the internet's) for the first 30% of its length; under any other label, it is hidden. Only a
# map at its snuggest (a crowd that has room only so) may hide one, where a label had no other spot: those aren't counted
LINES_UNDER = r"""() => {
    const L = Arteria.state.layout, from = { wan: 'wan', more: 'router' }, end = { wan: 'router' }, out = [];
    if (L.snug > 1) return out;
    L.devs.concat(L.wired).forEach(x => { from[x.dev.id] = x.dev.node ? x.dev.node.id : 'router'; });
    L.nodes.forEach(x => { const v = x.node.viaWired && x.node.via; from[x.node.id] = v && /^node:/.test(v.id) ? v.id : (L.hubOf || {})[x.node.id] || 'router'; });
    const labs = [...document.querySelectorAll('#ar .ar-lb')].map(b => [b.getAttribute('data-id'), b.firstElementChild.getBoundingClientRect()]).filter(l => l[1].width);
    document.querySelectorAll('#arMapScene g.lk[data-link]').forEach(g => {
        const id = g.getAttribute('data-link'), p = g.querySelectorAll('path')[1], M = p && p.getScreenCTM(), len = p ? p.getTotalLength() : 0, n = 60;
        if (!M || !len) return;
        const pts = []; for (let i = 0; i <= n; i++) { const q = p.getPointAtLength(len * i / n); pts.push([M.a * q.x + M.c * q.y + M.e, M.b * q.x + M.d * q.y + M.f]); }
        labs.forEach(([lid, r]) => {
            if (lid === (end[id] || id)) return;
            for (let i = lid === from[id] ? Math.ceil(n * 0.3) : 0; i <= n; i++) { const q = pts[i];
                if (q[0] > r.left + 2 && q[0] < r.right - 2 && q[1] > r.top + 2 && q[1] < r.bottom - 2) { out.push(id.slice(-5) + ' under ' + lid.slice(-5)); break; } }
        });
    });
    return out;
}"""

# Room on the map: drawings that overlap (their outlines, worked out here from the shapes in each drawing: the router is left
# out, its plate is mostly floor and stands keep off it by where they are), the longest label line, and lines that cross.
ROOM = r'''() => {
    const hull = pts => { const p = pts.slice().sort((a, b) => a[0] - b[0] || a[1] - b[1]), h = [], t = (o, a, b) => (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0]);
        for (const q of p) { while (h.length >= 2 && t(h[h.length - 2], h[h.length - 1], q) <= 0) h.pop(); h.push(q); }
        const n = h.length + 1; for (let i = p.length - 2; i >= 0; i--) { while (h.length >= n && t(h[h.length - 2], h[h.length - 1], p[i]) <= 0) h.pop(); h.push(p[i]); }
        h.pop(); return h; };
    // apart: a straight line passes between the two outlines, a pixel or more from each
    const apart = (p, q) => p.some((u, i) => { const v = p[(i + 1) % p.length], nx = v[1] - u[1], ny = u[0] - v[0], n = Math.hypot(nx, ny); if (!n) return false;
        const pr = w => ((w[0] - u[0]) * nx + (w[1] - u[1]) * ny) / n; return Math.min(...q.map(pr)) - Math.max(...p.map(pr)) >= 1; });
    const shapes = [...document.querySelectorAll('#arMapScene g[data-obj]')].filter(g => !/^(wall|router)$/.test(g.getAttribute('data-obj'))).map(g => { const pts = [];
        g.querySelectorAll('polygon').forEach(e => { const n = e.getAttribute('points').trim().split(/[ ,]+/).map(Number); for (let i = 0; i < n.length; i += 2) pts.push([n[i], n[i + 1]]); });
        g.querySelectorAll('ellipse, circle').forEach(e => { if (e.classList.contains('df-ripple') || /url\(#ar-(halo|glow)/.test(e.getAttribute('style') || '')) return;   // light, not the thing itself
            const cx = +e.getAttribute('cx'), cy = +e.getAttribute('cy'), rx = +(e.getAttribute('rx') || e.getAttribute('r')), ry = +(e.getAttribute('ry') || e.getAttribute('r'));
            pts.push([cx - rx, cy], [cx + rx, cy], [cx, cy - ry], [cx, cy + ry]); });
        return [g.getAttribute('data-obj'), hull(pts)]; }).filter(s => s[1].length > 2);
    const on = [];
    shapes.forEach((a, i) => shapes.slice(i + 1).forEach(b => { if (!apart(a[1], b[1]) && !apart(b[1], a[1])) on.push(a[0] + ' / ' + b[0]); }));
    const segs = [...document.querySelectorAll('#arMapScene g[data-lead] path')].map(p => p.getAttribute('d').match(/-?[\d.]+/g).map(Number));
    const side = (a, b, c, d, x, y) => (c - a) * (y - b) - (d - b) * (x - a);
    const X = (a, b) => { const d1 = side(b[0], b[1], b[2], b[3], a[0], a[1]), d2 = side(b[0], b[1], b[2], b[3], a[2], a[3]), d3 = side(a[0], a[1], a[2], a[3], b[0], b[1]), d4 = side(a[0], a[1], a[2], a[3], b[2], b[3]);
        return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) && ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0)); };
    let cross = 0; segs.forEach((a, i) => segs.slice(i + 1).forEach(b => { if (X(a, b)) cross++; }));
    const L = Arteria.state.layout;
    return { on: on, cross: cross, line: Math.round(Math.max(0, ...segs.map(s => Math.hypot(s[0] - s[2], s[1] - s[3])))), stands: L.wired.length + L.devs.length, labels: segs.length };
}'''
LINE = 110   # the longest line from a label to its device, in pixels: labels stay next to their devices


def room_ok(r):
    return not r['on'] and r['cross'] == 0 and r['line'] <= LINE and r['labels'] >= r['stands'] + 2


def room_txt(rs):
    return '; '.join('%d stands, longest line %d px, %d crossings%s' % (r['stands'], r['line'], r['cross'], (', overlapping: ' + ', '.join(r['on'][:3])) if r['on'] else '') for r in rs)


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
        tag = scn.ljust(11)
        if scn == 'mesh4':   # four nodes and two zones: the busiest two get them, and the tray and its list name the other two
            await pg.wait_for_timeout(2200)   # a few samples in: the busiest nodes are known
            lb = await pg.evaluate("(document.querySelector('#arMapLabels .ar-lb[data-id=\"more\"]') || {}).innerText || ''")
            await pg.click('#arMapLabels .ar-lb[data-id="more"]'); await pg.wait_for_timeout(300)
            note = await pg.evaluate("document.getElementById('arMoreNote').classList.contains('hide') ? '' : document.getElementById('arMoreNote').textContent")
            zones = await pg.evaluate("Arteria.state.layout.nodes.map(x => x.node.name).join(',')")
            check('+2 nodes' in lb and note.startswith('No room on the map for Garage (1 device) and Loft (1 device).') and zones == 'Hall,Office',
               tag + ': four nodes: the busiest two get zones, the tray and its list name the other two (' + zones + ')')
            await pg.keyboard.press('Escape'); await pg.wait_for_timeout(200)
        if scn == 'wired':   # a switch lists its devices, one of them picked is traced to the switch; a node's wired device and guest network
            sw = await pg.evaluate("(Arteria.state.net.devs.find(d => d.behind) || {}).id || ''")
            await pg.click('#arMapLabels .ar-lb[data-id="%s"]' % sw); await pg.wait_for_timeout(300)
            lst = await pg.evaluate("[...document.querySelectorAll('#arMoreList button .nm')].map(e => e.textContent).join(',')")
            title = await pg.evaluate("document.getElementById('arMoreTitle').textContent")
            # below the map, the cards grow to show every row of the list: none scrolled out of sight
            fit = await pg.evaluate("""() => { const l = document.getElementById('arMoreList'), c = document.getElementById('arCards');
                return { rows: l.children.length, scroll: l.scrollHeight - l.clientHeight, h: Math.round(c.getBoundingClientRect().height) }; }""")
            await pg.click('#arMoreList button'); await pg.wait_for_timeout(300)
            picked = await pg.evaluate("""(sw) => ({ link: document.getElementById('arRoLink').textContent, name: document.getElementById('arRoName').textContent,
                on: document.querySelector('#arMapLabels .ar-lb[data-id="' + sw + '"]').classList.contains('on'), list: !document.getElementById('arMore').classList.contains('hide') })""", sw)
            pi = await pg.evaluate("""() => { const d = Arteria.state.net.devs.find(x => x.name === 'Pi-hole') || {}, g = Arteria._t.flowGroups(Arteria.state.net);
                return [d.node && d.node.name, d.link, d.portLabel, g.some(x => x.node && x.devs.indexOf(d) >= 0), g.some(x => x.id === 'lan' && x.devs.indexOf(d) >= 0)].join('|'); }""")
            guest = await pg.evaluate("(Arteria.state.net.devs.find(d => d.name === 'Visitor phone') || {}).net || ''")
            check(fit['rows'] == 4 and fit['scroll'] <= 1 and fit['h'] > 224,
                  tag + ': a switch\'s list below the map: the cards grow to show all its rows (%s)' % fit)
            check(sw == 'port:eth4' and lst == 'Backup NAS,Game PC,Media NAS,Streaming box' and title.startswith('Switch-01 · 4 devices')
                  and picked['name'] == 'Backup NAS' and 'through a switch' in picked['link'] and picked['on'] and picked['list'],
                  tag + ': a managed switch is named after itself and lists its four devices; one picked shows its details, the switch stays lit and the list open (%s; %s; %s)' % (title, lst, picked['link']))
            check(pi == 'Hall|wired|Hall LAN|true|false' and guest == 'Guests', tag + ': a device on the node\'s LAN port is the node\'s; a node\'s guest network is named (%s, %s)' % (pi, guest))
            # pipes are cables, arcs are Wi-Fi: the node (on an Ethernet backhaul) and its wired device by pipe, its Wi-Fi devices by arc
            kinds = await pg.evaluate("""() => { const L = Arteria.state.layout, node = L.nodes[0].node;
                const k = id => { const e = document.querySelector('#arMapScene [data-lane="' + id + '|dn"]'); return e ? (e.classList.contains('t') ? 'pipe' : 'arc') : 'none'; };
                const devs = L.devs.filter(x => x.dev.node === node);
                return { node: k(node.id), wired: devs.filter(x => x.dev.link === 'wired').map(x => k(x.dev.id)), wifi: devs.filter(x => x.dev.link === 'wifi').map(x => k(x.dev.id)) }; }""")
            check(kinds['node'] == 'pipe' and kinds['wired'] and all(k == 'pipe' for k in kinds['wired']) and kinds['wifi'] and all(k == 'arc' for k in kinds['wifi']),
                  tag + ': a node on an Ethernet backhaul and its wired device are drawn as pipes, its Wi-Fi devices as arcs (%s)' % kinds)
            await pg.keyboard.press('Escape'); await pg.wait_for_timeout(200)
            await pg.evaluate("Arteria.pick(null)"); await pg.wait_for_timeout(200)
            back = await pg.evaluate("Math.round(document.getElementById('arCards').getBoundingClientRect().height)")
            check(back == 224, tag + ': with the list closed, the cards are back to their height (%s px)' % back)
            # another computer's fonts: with every text 15% or 30% wider (fewer labels fit), the device on a cable still has its stand
            wides = []
            for scale in (1.15, 1.3):
                wctx = await b.new_context(viewport={'width': 1600, 'height': 900})
                wpg = await wctx.new_page()
                await wpg.add_init_script("(() => { const m = CanvasRenderingContext2D.prototype.measureText;"
                                          " CanvasRenderingContext2D.prototype.measureText = function (t) { return { width: m.call(this, t).width * %s }; }; })()" % scale)
                await wpg.goto('http://127.0.0.1:%d/user1.asp' % port); await ready(wpg); await wpg.wait_for_timeout(2500)   # the first rates are in: picked anew
                wides.append(await wpg.evaluate("""() => { const L = Arteria.state.layout, node = L.nodes[0].node;
                    return L.devs.filter(x => x.dev.node === node).map(x => x.dev.link + ':' + x.dev.name); }"""))
                await wctx.close()
            check(all('wired:Pi-hole' in w for w in wides), tag + ': with wider text, a device on a cable keeps its stand before Wi-Fi devices do (%s)' % ' | '.join(', '.join(w) for w in wides))
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
        lbov_big = await pg.evaluate(LABEL_OVERLAPS)
        cover_big = await pg.evaluate(LABEL_COVERS)
        under_big = await pg.evaluate(LINES_UNDER)
        room_big = [await pg.evaluate(ROOM)]
        if scn in ('nodecrowd', 'house'):   # a crowded floor in a smaller window, where labels have the least room; and in a large one
            await pg.set_viewport_size({'width': 1456, 'height': 832}); await pg.wait_for_timeout(900)
            lbov_big += await pg.evaluate(LABEL_OVERLAPS); cover_big += await pg.evaluate(LABEL_COVERS); under_big += await pg.evaluate(LINES_UNDER)
            room_big.append(await pg.evaluate(ROOM))
            await pg.set_viewport_size({'width': 2540, 'height': 1450}); await pg.wait_for_timeout(900)
            lbov_big += await pg.evaluate(LABEL_OVERLAPS); cover_big += await pg.evaluate(LABEL_COVERS); under_big += await pg.evaluate(LINES_UNDER)
            room_big.append(await pg.evaluate(ROOM))
            await pg.set_viewport_size({'width': 1600, 'height': 900}); await pg.wait_for_timeout(500)
        if scn.startswith('mesh') and scn != 'mesh4':   # nodes on a switch: drawn between the router and them only where it's sure, and costs no stand
            hub = await pg.evaluate(r"""() => { const A = Arteria.state, L = A.layout, net = A.net, sw = (L.hubs[0] || {}).dev;
                const lane = id => { const e = document.querySelector('#arMapScene [data-lane="' + id + '|dn"]'); return e ? (e.classList.contains('t') ? 'pipe' : 'arc') : 'none'; };
                const from = id => { const g = document.querySelector('#arMapScene g.lk[data-link="' + id + '"]'); return !!g; };
                const r = { hubs: L.hubs.length, nodes: Object.keys(L.hubOf).length, tray: L.tray.length, pipe: sw ? lane(sw.id) : '', label: '', third: '', note: '', chain: '' };
                if (sw) {
                    const lb = document.querySelector('#arMapLabels .ar-lb[data-id="' + sw.id + '"]'); r.label = lb ? lb.innerText.replace(/\s+/g, ' ') : '';
                    Arteria.pick(sw.id); r.note = Arteria._t.readoutFor(net).note; Arteria.pick(null);
                    const nd = L.nodes.find(x => L.hubOf[x.node.id]); r.chain = Arteria._t.chainOf(net, nd.node.id).slice(0, 2).join(',');
                    /* one figure for it: its label, its readout and the list of the busiest show the same (the cable carries the whole port) */
                    const lab = (document.querySelector('#arMapLabels .ar-lb[data-id="' + sw.id + '"] .v') || {}).textContent || '';
                    Arteria.pick(sw.id); const ro = Arteria._t.readoutFor(net); Arteria.pick(null);
                    const dv = net.byId[sw.id], sh = x => Arteria._t.short(x);
                    r.same = lab.indexOf(sh(dv.dn)) >= 0 && Math.abs(parseFloat(ro.dnN) - (dv.dn >= 1 ? dv.dn : dv.dn * 1000)) < 0.06 * Math.max(1, dv.dn >= 1 ? dv.dn : dv.dn * 1000);
                    /* the same devices laid out without the switch: no fewer on the tray */
                    const key = A.hubFit.key; A.hubFit = { key: key, spot: null }; A.stands = null; Arteria.render(); r.trayNo = A.layout.tray.length;
                    A.hubFit = null; A.stands = null; Arteria.render(); r.trayAgain = A.layout.tray.length;
                }
                return r; }""")
            if scn in ('meshswitch', 'meshswitch1', 'meshswitch2'):
                extra = {'meshswitch': '', 'meshswitch1': ' and Garage PC', 'meshswitch2': ' and 2 devices'}[scn]
                check(hub['hubs'] == 1 and hub['nodes'] == 3 and hub['pipe'] == 'pipe' and 'Switch on LAN 2' in hub['label'] and hub['chain'].startswith('port:eth3,node:')
                      and hub['note'].startswith('On it: Annex, Kitchen' + (', Master Bedroom' + extra if extra else ' and Master Bedroom')) and hub['tray'] <= hub['trayNo'] and hub['trayAgain'] == hub['tray']
                      and hub['same'], tag + ': nodes on a switch: the switch is drawn between the router and them, their cables leave from it, a node is traced through it, '
                      'one figure for it everywhere (%s)' % hub)
                # in smaller windows too: the switch never on a node's drawing or behind the router, and nothing under or over a label
                fit = []
                for w, h in ((1440, 900), (1180, 760)):
                    await pg.set_viewport_size({'width': w, 'height': h}); await pg.wait_for_timeout(700)
                    r = await pg.evaluate(ROOM); u = await pg.evaluate(LINES_UNDER); c = await pg.evaluate(LABEL_COVERS)
                    behind = await pg.evaluate("""() => { const L = Arteria.state.layout; return L.wired.filter(x => x.hub && x.slot.cx + x.slot.cy < 14.2).length; }""")
                    fit.append((w, [o for o in r['on'] if 'port:' in o], u, c, behind))
                await pg.set_viewport_size({'width': 1600, 'height': 900}); await pg.wait_for_timeout(500)
                check(all(not f[1] and not f[2] and f[3] == 0 and f[4] == 0 for f in fit), tag + ': in smaller windows, the switch is on no node\'s drawing, not behind the router, and lines and labels keep apart (%s)' % fit)
            else:
                check(hub['hubs'] == 0 and hub['nodes'] == 0, tag + ': a node wired behind another, or a node not read: no switch drawn in front of the nodes (%s)' % hub)
        check(cover_big == 0, tag + 'expanded view: labels don\'t cover other devices (%d)' % cover_big)
        check(not under_big, tag + 'expanded view: no traffic line runs under another device\'s label (%s)' % (', '.join(under_big[:4]) or 'none'))
        if scn == 'crowd':   # a smaller window, where a crowd of labels has the least room
            await pg.set_viewport_size({'width': 1280, 'height': 720}); await pg.wait_for_timeout(700)
            lbov_big += await pg.evaluate(LABEL_OVERLAPS)
            room_big.append(await pg.evaluate(ROOM))
            await pg.set_viewport_size({'width': 1600, 'height': 900}); await pg.wait_for_timeout(500)
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
        # the totals in the tab bar keep their place whatever the numbers: the narrowest and the widest leave them where they are
        still = await pg.evaluate('''() => {
            const s = document.getElementById('arSum'), k = s && s.querySelector('.v'), bs = s ? [...s.querySelectorAll('.v b')] : [];
            if (!k || bs.length !== 2) return null;
            const at = () => k.getBoundingClientRect().left, old = bs.map(b => b.textContent), x0 = at();
            bs.forEach(b => { b.textContent = '99.9 MB/s'; }); const x1 = at();
            bs.forEach(b => { b.textContent = '0 kb/s'; }); const x2 = at();
            bs.forEach((b, i) => { b.textContent = old[i]; });
            return Math.max(Math.abs(x1 - x0), Math.abs(x2 - x0));
        }''')
        # a device's label doesn't cover another device's drawing (on a crowded floor, one may have to)
        cover = await pg.evaluate(LABEL_COVERS)
        under = await pg.evaluate(LINES_UNDER)
        room = await pg.evaluate(ROOM)
        # labels never sit on one another
        lbov = await pg.evaluate(LABEL_OVERLAPS)
        # a label's rates (2.1M, 47k, 1.25G) fit inside it
        spill = await pg.evaluate('''() => [...document.querySelectorAll('#arMapLabels .ar-lb')].filter(b => { const s = b.firstElementChild, v = s.querySelector('.v');
            return v && v.getBoundingClientRect().right > s.getBoundingClientRect().right - 8; }).map(b => b.querySelector('.n').textContent)''')
        # anything cut short with "…" outside the map's labels (a name, a maker, a path) shows in full on hover; pointing at a
        # map label shows no tooltip at all, on it or on anything around it
        tip = await pg.evaluate('''() => {
            const cut = [...document.querySelectorAll('#ar *')].filter(e => e.clientWidth && e.scrollWidth > e.clientWidth + 1 && e.offsetParent && !e.children.length && !e.closest('#arMapLabels'));
            const bad = cut.filter(e => { e.dispatchEvent(new MouseEvent('mouseover', { bubbles: true })); return e.title !== e.textContent.trim(); });
            document.querySelectorAll('#arMapLabels .ar-lb .n, #arMapLabels .ar-lb .v').forEach(e => e.dispatchEvent(new MouseEvent('mouseover', { bubbles: true })));
            const lb = document.querySelector('#arMapLabels'), tipped = [...document.querySelectorAll('[title]')].filter(e => e.contains(lb) || e.closest('#arMapLabels'));
            return { n: cut.length, bad: bad.length, labels: tipped.length };
        }''')
        # a device's drawing does what its label does: tapping it traces the device, tapping again shows everything
        dev = await pg.evaluate('''() => { const g = [...document.querySelectorAll('#ar g[data-obj]')].find(g => /^[0-9A-F]{2}:/.test(g.getAttribute('data-obj')) && g.getBoundingClientRect().width); return g ? g.getAttribute('data-obj') : null; }''')
        tap = None
        if dev:
            await pg.dispatch_event('#ar g[data-obj="%s"]' % dev, 'click'); await pg.wait_for_timeout(150)
            a = await pg.evaluate('Arteria.state.sel')
            await pg.dispatch_event('#ar g[data-obj="%s"]' % dev, 'click'); await pg.wait_for_timeout(150)
            tap = (a == dev, await pg.evaluate('Arteria.state.sel') is None)
        await ctx.close()
        check(not errs, tag + 'no page errors' + ('' if not errs else ': ' + ' / '.join(errs[:3])))
        check(small['w'] == 728 and small['h'] == 518 and small['td'] == 'TD', tag + 'the page\'s view is 728 x 518 inside the router\'s page')
        check(ok_order, tag + 'Escape closes the report, then the list, and keeps the expanded view open')
        check(out == 0, tag + 'Tab stays inside the expanded view')
        check(after == small, tag + 'closing the expanded view puts the stage back as it was')
        check(inj['els'] == 0 and not inj['xss'], tag + 'nothing that looks like HTML became markup or ran')
        check(cover == 0, tag + 'labels don\'t cover other devices (%d)' % cover)
        check(not under, tag + 'no traffic line runs under another device\'s label (%s)' % (', '.join(under[:4]) or 'none'))
        check(room_ok(room), tag + 'no drawing overlaps another, every label is next to its device, no lines cross (%s)' % room_txt([room]))
        check(all(room_ok(r) for r in room_big), tag + 'expanded view: no drawing overlaps another, every label is next to its device, no lines cross (%s)' % room_txt(room_big))
        check(not spill, tag + 'every label\'s rates fit inside it' + ('' if not spill else ' (%s)' % ', '.join(spill[:4])))
        check(still is not None and still < 0.5, tag + 'the totals keep their place as the numbers change (%s px)' % still)
        check(lbov == 0 and lbov_big == 0, tag + 'labels don\'t sit on one another (%d in the page\'s view, %d expanded)' % (lbov, lbov_big))
        check(tip['bad'] == 0 and tip['labels'] == 0, tag + 'what is cut short shows in full on hover (%d), the map\'s labels show no tooltip' % tip['n'])
        if tap is not None:
            check(tap == (True, True), tag + 'tapping a device\'s drawing traces it, tapping again shows everything')
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


async def heartbeat_pace(b, port):
    """The router logs two lines for each request that keeps it sampling: while samples come, the page asks every 45 s, not
    every 8; when they stop coming (the router rebooted, say), it asks again within seconds."""
    srv = await serve('home', port)
    try:
        ctx = await b.new_context(viewport={'width': 1440, 'height': 900})
        pg = await ctx.new_page(); await pg.goto('http://127.0.0.1:%d/user1.asp' % port); await ready(pg)
        posts = lambda: pg.evaluate("fetch('/_posts').then(r => r.json())")
        await pg.wait_for_timeout(9000)   # past the 8 s heartbeat that samples were still on their way for
        n0 = await posts(); await pg.wait_for_timeout(12000); n1 = await posts()
        check(n1 == n0, 'heartbeat: while samples come, no request for 12 s (it asks every 45 s; %d requests)' % (n1 - n0))
        await pg.evaluate("fetch('/_set/live_off/1')")
        t0 = time.time(); n2 = n1
        while time.time() - t0 < 16 and n2 == n1:
            await pg.wait_for_timeout(500); n2 = await posts()
        check(n2 > n1, 'heartbeat: when samples stop, the page asks again within seconds (%.0f s)' % (time.time() - t0))
        await ctx.close()
    finally:
        srv.terminate()


async def stay_logged_in(b, port):
    """The router's Auto Logout, counted by its state.js from the page's load, doesn't log you out of the open page: the page
    sets the count to 0, as the router's own System Log does. The stand-in counts 3 ticks of 0.2 s, so without that the page
    would be at Logout.asp within a second."""
    srv = await serve('home', port, {'AR_LOGOUT': '3'})
    try:
        ctx = await b.new_context(viewport={'width': 1440, 'height': 900})
        pg = await ctx.new_page(); await pg.goto('http://127.0.0.1:%d/user1.asp' % port)
        await pg.wait_for_timeout(3000)   # 15 ticks
        st = await pg.evaluate("() => [location.pathname, window.AUTOLOGOUT_MAX_MINUTE, !!document.getElementById('ar')]")
        check(st == ['/user1.asp', 0, True], 'stays logged in: the router\'s Auto Logout is off while the page is open (%s)' % st)
        await ctx.close()
    finally:
        srv.terminate()


async def speed_test(b, port):
    """A speed test on one laptop: in the expanded Flow view the river fits the window, nothing scrolls."""
    srv = await serve('speedtest', port)
    try:
        ctx = await b.new_context(viewport={'width': 1440, 'height': 860})
        pg = await ctx.new_page(); await pg.goto('http://127.0.0.1:%d/user1.asp' % port); await ready(pg)
        await pg.click('#arBig'); await pg.click('#arTabFlow'); await pg.wait_for_timeout(2600)
        fs = await pg.evaluate("(() => { const s = document.getElementById('arFlowScroll'); return [s.scrollHeight, s.clientHeight]; })()")
        check(fs[0] <= fs[1] + 1, 'speed test: the expanded Flow view fits the window, no scrolling (%d of %d px)' % tuple(fs))
        await ctx.close()
    finally:
        srv.terminate()


async def zoom(b, port):
    """The expanded map zooms and pans like a whiteboard, never with scrollbars; the page's own view doesn't zoom."""
    srv = await serve('home', port)
    try:
        ctx = await b.new_context(viewport={'width': 1440, 'height': 900})
        pg = await ctx.new_page(); await pg.goto('http://127.0.0.1:%d/user1.asp' % port); await ready(pg)
        tf = "getComputedStyle(document.getElementById('arMapScene')).transform"
        z = lambda: pg.evaluate("Arteria.state.pz")
        box = await (await pg.query_selector('#arMap')).bounding_box()
        cx, cy = box['x'] + box['width'] / 2, box['y'] + box['height'] / 2
        await pg.mouse.move(cx, cy); await pg.mouse.wheel(0, -300); await pg.wait_for_timeout(100)
        check((await z())['s'] == 1 and await pg.evaluate(tf) == 'none', 'zoom: the page\'s own view doesn\'t zoom')
        await pg.click('#arBig'); await pg.wait_for_timeout(600)
        box = await (await pg.query_selector('#arMap')).bounding_box()
        px, py = box['x'] + box['width'] * 0.3, box['y'] + box['height'] * 0.4
        # a mouse wheel (whole notches): zooms in around the pointer, which stays over the same spot of the map
        before = await pg.evaluate("(([x, y]) => { const r = document.getElementById('arMap').getBoundingClientRect(), z = Arteria.state.pz; return [(x - r.left - z.x) / z.s, (y - r.top - z.y) / z.s]; })", [px, py])
        await pg.mouse.move(px, py)
        for _ in range(3): await pg.mouse.wheel(0, -120)
        await pg.wait_for_timeout(100)
        a = await z()
        after = await pg.evaluate("(([x, y]) => { const r = document.getElementById('arMap').getBoundingClientRect(), z = Arteria.state.pz; return [(x - r.left - z.x) / z.s, (y - r.top - z.y) / z.s]; })", [px, py])
        check(a['s'] > 1.5 and abs(after[0] - before[0]) < 1 and abs(after[1] - before[1]) < 1, 'zoom: the mouse wheel zooms in around the pointer (%.2fx)' % a['s'])
        # the scene zooms through its viewBox, never scaled as a picture (that asks the graphics card for a huge layer and
        # flickers); the labels' layer carries the matching transform
        vb = await pg.evaluate("(() => { const s = document.querySelector('#arMapScene svg'); return [getComputedStyle(document.getElementById('arMapScene')).transform, +s.getAttribute('viewBox').split(' ')[2], +s.getAttribute('width'), getComputedStyle(document.getElementById('arMapLabels')).transform]; })()")
        check(vb[0] == 'none' and abs(vb[1] - vb[2] / a['s']) < 0.5 and vb[3] != 'none', 'zoom: the map zooms its drawing, not a picture of it')
        # a trackpad's two-finger scroll (small, fractional steps) pans; a pinch (ctrl + wheel) zooms
        await pg.evaluate("(([x, y]) => { const el = document.getElementById('arMap'); for (let i = 0; i < 6; i++) el.dispatchEvent(new WheelEvent('wheel', { deltaX: 6.5, deltaY: 4.25, clientX: x, clientY: y, bubbles: true, cancelable: true })); })", [px, py])
        b2 = await z()
        check(abs(b2['s'] - a['s']) < 1e-6 and (b2['x'] != a['x'] or b2['y'] != a['y']), 'zoom: two fingers on a trackpad pan')
        await pg.evaluate("(([x, y]) => { const el = document.getElementById('arMap'); for (let i = 0; i < 4; i++) el.dispatchEvent(new WheelEvent('wheel', { deltaY: 8, ctrlKey: true, clientX: x, clientY: y, bubbles: true, cancelable: true })); })", [px, py])
        c = await z()
        check(c['s'] < b2['s'], 'zoom: a trackpad pinch zooms')
        # dragging pans; the click that ends the drag doesn't trace a device
        lb = await pg.evaluate("(() => { const l = [...document.querySelectorAll('#arMapLabels .ar-lb')].find(l => { const r = l.getBoundingClientRect(), m = document.getElementById('arMap').getBoundingClientRect(); return r.width && r.left > m.left + 40 && r.right < m.right - 40 && r.top > m.top + 40 && r.bottom < m.bottom - 40; }); if (!l) return null; const r = l.getBoundingClientRect(); return [r.left + r.width / 2, r.top + r.height / 2]; })()")
        if lb:
            d0 = await z()
            await pg.mouse.move(lb[0], lb[1]); await pg.mouse.down(); await pg.mouse.move(lb[0] + 60, lb[1] + 40, steps=6)
            # a sample landing mid-drag keeps the map moving and zoomed as it was: one more step of the drag, a render and the
            # reading, all in one go (the map stops "moving" 200 ms after the last step: a busy test browser can take longer)
            mid, rings = await pg.evaluate("(([x, y]) => { window.dispatchEvent(new PointerEvent('pointermove', { pointerId: 1, pointerType: 'mouse', isPrimary: true, buttons: 1, clientX: x, clientY: y, bubbles: true })); Arteria.render(); return [[document.getElementById('ar').classList.contains('moving'), getComputedStyle(document.querySelector('#arMapScene .pk')).animationPlayState], [...document.querySelectorAll('#arMapScene .df-ripple, #arMapScene .df-led')].map(e => getComputedStyle(e).animationName)]; })", [lb[0] + 64, lb[1] + 42])
            await pg.mouse.up()
            await pg.wait_for_timeout(100)
            d1 = await z()
            check((d1['x'], d1['y']) != (d0['x'], d0['y']) and await pg.evaluate('Arteria.state.sel') is None, 'zoom: dragging pans, and doesn\'t trace the device it started on')
            await pg.wait_for_timeout(300)
            aft = await pg.evaluate("[document.getElementById('ar').classList.contains('moving'), getComputedStyle(document.querySelector('#arMapScene .pk')).animationPlayState]")
            check(mid == [True, 'paused'] and aft == [False, 'running'], 'zoom: the animations wait while the map is dragged, even when a sample lands mid-drag, and go on when it stops (%s, %s)' % (mid, aft))
            check(rings and all(n == 'none' for n in rings), 'zoom: while it moves, the rings and LEDs don\'t animate at all, so the browser draws the map as one picture (%d)' % len(rings))
        check(await pg.evaluate("!document.querySelector('#arMapScene [filter], #arMapScene filter')"), 'zoom: the map has no blur filter, which would be redrawn for every frame it moves')
        fade = await pg.evaluate("[Arteria.state.pz.s > 1, getComputedStyle(document.querySelector('#arMapScene .ob')).transitionDuration, getComputedStyle(document.querySelector('#arMapLabels .ar-lb')).transitionDuration]")
        check(fade == [True, '0s', '0s'], 'zoom: zoomed in, tracing a device dims the rest at once, without a fade that would flicker (%s)' % fade)
        # no scrollbars, and nothing scrolls, not even when the keyboard reaches a label that is off screen
        for _ in range(12): await pg.keyboard.press('Tab')
        sc = await pg.evaluate("(() => { const s = document.querySelector('#ar .ar-stage'), m = document.getElementById('arMap'); return [s.scrollLeft, s.scrollTop, m.scrollLeft, m.scrollTop, s.offsetWidth - s.clientWidth - 2, m.offsetWidth - m.clientWidth]; })()")
        check(max(sc) <= 0 and min(sc) >= 0, 'zoom: zoomed and panned, no scrollbars, nothing scrolls (%s)' % sc)
        # never past the map's edges: the map always covers the stage
        await pg.mouse.move(cx, cy); await pg.mouse.down(); await pg.mouse.move(cx + 3000, cy + 3000, steps=4); await pg.mouse.up()
        e = await z()
        check(e['x'] <= 0.01 and e['y'] <= 0.01, 'zoom: panning stops at the map\'s edges')
        # the buttons: in, out, and back to the whole map; zooming out stops there
        s0 = (await z())['s']; await pg.click('#arZoomIn'); s1 = (await z())['s']   # straight after a drag: only the drag's own click is eaten
        await pg.click('#arZoomFit'); f = await z()
        await pg.mouse.move(px, py); await pg.mouse.wheel(0, 600); g = await z()
        check(s1 > s0 and f['s'] == 1 and f['x'] == 0 and g['s'] == 1 and await pg.evaluate(tf) == 'none', 'zoom: the buttons zoom in and back to the whole map; zooming out stops there')
        back = await pg.evaluate("getComputedStyle(document.querySelector('#arMapScene .ob')).transitionDuration")
        check(back == '0.3s', 'zoom: at 100%% the rest of the map fades as before (%s)' % back)
        # closing the expanded view and opening it again shows the whole map
        await pg.click('#arZoomIn'); await pg.keyboard.press('Escape'); await pg.wait_for_timeout(200)
        await pg.click('#arBig'); await pg.wait_for_timeout(300)
        check((await z())['s'] == 1, 'zoom: the expanded view opens on the whole map')
        await ctx.close()
    finally:
        srv.terminate()


async def rename(b, port):
    """Renaming a device from the readout: its name becomes a text field with a check and a cross; the icon beside it and the
    line under it say what the name will show as; saving writes the router's client list (so the router shows it too), and
    the page shows it once the router has it. The cross and Escape leave everything as it was."""
    srv = await serve('home', port)
    try:
        ctx = await b.new_context(viewport={'width': 1440, 'height': 900})
        pg = await ctx.new_page(); await pg.goto('http://127.0.0.1:%d/user1.asp' % port); await ready(pg)
        mac = await pg.evaluate("(() => [...document.querySelectorAll('#arMapLabels .ar-lb')].map(l => l.getAttribute('data-id')).find(i => /^[0-9A-F]{2}:/.test(i)))()")
        check(await pg.evaluate("document.getElementById('arRoEdit').classList.contains('hide') && !document.getElementById('arRoNrow').classList.contains('ed')"), 'rename: the whole network has no pencil, its name isn\'t a button')
        await pg.dispatch_event('#arMapLabels .ar-lb[data-id="%s"]' % mac, 'click'); await pg.wait_for_timeout(200)
        st = lambda: pg.evaluate("(() => ({ name: document.getElementById('arRoName').textContent, ed: document.getElementById('arRoNrow').classList.contains('ed'), editing: !document.getElementById('arRoEd').classList.contains('hide'), btns: !document.getElementById('arRoEd').classList.contains('hide'), line: document.getElementById('arRoLink').textContent, icon: document.getElementById('arRoIcon').innerHTML }))()")
        s0 = await st()
        check(s0['ed'] and not s0['editing'], 'rename: a device\'s name in the readout can be clicked to rename it')
        # an edit button after the name: just the pencil, no border or background; no outline on the name
        eb = await pg.evaluate("(() => { const e = document.getElementById('arRoEdit'), n = document.getElementById('arRoName'), b = e.getBoundingClientRect(), r = n.getBoundingClientRect(), rw = document.getElementById('arRoNrow').getBoundingClientRect(), cs = getComputedStyle(e); return { shown: !e.classList.contains('hide') && b.width > 0 && !!e.querySelector('svg'), size: [b.width, b.height], bare: cs.borderTopStyle === 'none' && cs.backgroundColor === 'rgba(0, 0, 0, 0)', after: b.left >= r.right, row: [rw.top, rw.height], mid: Math.abs((b.top + b.bottom) / 2 - (r.top + r.bottom) / 2), nb: getComputedStyle(n).borderTopStyle }; })()")
        check(eb['shown'] and eb['size'] == [26, 26] and eb['bare'] and eb['after'] and eb['mid'] < 1.5 and eb['nb'] == 'none',
              'rename: an edit button after the name, just the pencil (%s)' % eb)
        # the name and the pencil are one: hovering the name lights the pencil, the row ends at the pencil (nothing to click beyond it)
        await pg.evaluate("document.getElementById('arRoEdit').style.transition = 'none'")   # the fade's end, not its timing (a busy test browser may not step it)
        await pg.mouse.move(5, 5); await pg.wait_for_timeout(100); o0 = await pg.evaluate("getComputedStyle(document.getElementById('arRoEdit')).opacity")
        await pg.hover('#arRoName'); await pg.wait_for_timeout(100)
        hv = await pg.evaluate("(() => { const e = document.getElementById('arRoEdit'), rw = document.getElementById('arRoNrow').getBoundingClientRect(); return { o: getComputedStyle(e).opacity, cur: getComputedStyle(document.getElementById('arRoName')).cursor, end: rw.right - e.getBoundingClientRect().right }; })()")
        check(float(o0) < 0.7 and hv['o'] == '1' and hv['cur'] == 'pointer' and abs(hv['end']) < 0.5, 'rename: hovering the name lights the pencil, the two are one button (%s, %s)' % (o0, hv))
        await pg.evaluate("document.getElementById('arRoEdit').style.transition = ''")
        # the cross: nothing changes
        await pg.click('#arRoEdit'); s1 = await st()
        fld = await pg.evaluate("(() => { const b = document.getElementById('arRoEd').getBoundingClientRect(); return [b.top, b.height]; })()")
        check(abs(fld[0] - eb['row'][0]) < 0.5 and abs(fld[1] - eb['row'][1]) < 0.5, 'rename: the edit button opens the text field in the name\'s row, nothing moves (%s vs %s)' % (fld, eb['row']))
        check(s1['editing'] and s1['btns'] and await pg.evaluate("document.getElementById('arRoIn').value") == s0['name'], 'rename: the edit button turns the name into a text field with a check and a cross')
        row = await pg.evaluate("(() => ['arRoIn', 'arRoOk', 'arRoNo'].map(i => { const r = document.getElementById(i).getBoundingClientRect(); return [r.top, r.height, r.width]; }))()")
        check(all(abs(r[0] - row[0][0]) < 0.5 and abs(r[1] - row[0][1]) < 0.5 for r in row) and abs(row[1][2] - row[1][1]) < 0.5, 'rename: the check and the cross sit in the field\'s row, squares exactly as tall as it (%s)' % row)
        await pg.fill('#arRoIn', 'Lounge purifier'); s2 = await st()
        want = await pg.evaluate("(() => { const d = document.createElement('div'); d.innerHTML = Arteria._t.iconSvg('purifier', 20, '#f0efec'); return d.innerHTML; })()")
        check(s2['icon'] == want and 'Air purifier' in s2['line'], 'rename: while typing, the icon and the line under the name say what it will show as (%s)' % s2['line'])
        await pg.click('#arRoNo'); s3 = await st()
        check(not s3['editing'] and s3['name'] == s0['name'] and await pg.evaluate("document.activeElement.id") == 'arRoEdit', 'rename: the cross keeps the old name, and the edit button has the focus again')
        # a name with < or > isn't sent
        await pg.click('#arRoEdit'); await pg.fill('#arRoIn', 'Hall <lamp>'); await pg.click('#arRoOk'); await pg.wait_for_timeout(300)
        s4 = await st()
        saved = await pg.evaluate("fetch('/ext/arteria/names.htm').then(r => r.json()).then(n => n.custom)")
        check(s4['editing'] and '<' in s4['line'] and 'Hall <lamp>' not in saved, 'rename: a name with < or > is refused, nothing is sent')
        # saving: the router's client list gets it, the page shows it, the device is drawn as what the name says
        await pg.fill('#arRoIn', 'Lounge purifier'); await pg.keyboard.press('Enter')
        await pg.wait_for_function("document.getElementById('arRoName').textContent === 'Lounge purifier' && document.getElementById('arRoEd').classList.contains('hide')", timeout=15000)
        saved = await pg.evaluate("fetch('/ext/arteria/names.htm').then(r => r.json()).then(n => n.custom)")
        await pg.wait_for_timeout(2300)
        kind = await pg.evaluate("Arteria.state.net.byId['%s'].kind" % mac)
        check('<Lounge purifier>%s>0>0>>' % mac in saved and saved.count(mac) == 1 and kind == 'purifier', 'rename: Enter saves it in the router\'s client list, and the device is drawn as an air purifier (%s)' % kind)
        # Escape while renaming in the expanded view only leaves the name
        await pg.click('#arBig'); await pg.wait_for_timeout(300)
        await pg.click('#arRoName'); await pg.keyboard.press('Escape'); await pg.wait_for_timeout(150)
        s5 = await st()
        check(not s5['editing'] and await pg.evaluate('Arteria.state.big'), 'rename: Escape leaves the name, not the expanded view')
        # no name: the router's own name and icon come back
        await pg.click('#arRoName'); await pg.fill('#arRoIn', ''); await pg.click('#arRoOk')   # clicking the name works too
        await pg.wait_for_function("document.getElementById('arRoEd').classList.contains('hide')", timeout=15000)
        saved = await pg.evaluate("fetch('/ext/arteria/names.htm').then(r => r.json()).then(n => n.custom)")
        check(mac not in saved and 'removed' in (await st())['line'], 'rename: an empty name removes the nickname')
        await ctx.close()
    finally:
        srv.terminate()


async def until(pg, js, secs=10):   # poll a page expression until it's true, for at most secs
    end = time.time() + secs
    while time.time() < end:
        if await pg.evaluate(js): return True
        await pg.wait_for_timeout(200)
    return False


async def rename_safe(b, port):
    """Renaming rewrites one entry of the router's client list and posts the whole list back: it always starts from the
    router's list as it is at that moment, never from the page's copy (missing, or a minute old). Plus the small rules."""
    srv = await serve('home', port)
    try:
        ctx = await b.new_context(viewport={'width': 1440, 'height': 900})
        pg = await ctx.new_page(); await pg.goto('http://127.0.0.1:%d/user1.asp' % port); await ready(pg)
        cust = lambda: pg.evaluate("fetch('/_custom').then(r => r.json())")
        ents = lambda c: [e for e in c.split('<') if e]
        macs = await pg.evaluate("[...document.querySelectorAll('#arMapLabels .ar-lb')].map(l => l.dataset.id).filter(i => /^[0-9A-F]{2}:/.test(i))")
        closed = "document.getElementById('arRoEd').classList.contains('hide')"
        async def edit(m):   # select it (a click on the selected one would deselect it), then the pencil
            if await pg.evaluate('Arteria.state.sel') != m: await pg.dispatch_event('#arMapLabels .ar-lb[data-id="%s"]' % m, 'click'); await pg.wait_for_timeout(150)
            await pg.click('#arRoEdit')
        async def ren(m, name):
            await edit(m); await pg.fill('#arRoIn', name); await pg.keyboard.press('Enter')
        has = lambda *names: "fetch('/_custom').then(r => r.json()).then(c => %s)" % ' && '.join("c.includes(%r)" % n for n in names)
        c0 = await cust()
        # no copy of the list at all (names.htm missing): a rename keeps every other entry
        await pg.evaluate("fetch('/_set/names_off/1')"); await pg.evaluate("Arteria.state.names = null")
        await ren(macs[0], 'Garage light')
        got = await until(pg, has('Garage light'))
        c1 = await cust()
        kept = [e for e in ents(c0) if macs[0] not in e.upper()]
        check(got and all(e in ents(c1) for e in kept) and len(ents(c1)) >= len(kept) + 1,
              'rename: with no copy of the client list, a rename keeps every other entry (%d of %d)' % (sum(e in ents(c1) for e in kept), len(kept)))
        await pg.evaluate("fetch('/_set/names_off/0')"); await until(pg, closed, 20)
        # the list changed behind the page's back (the router's own client editor): that change stays
        await pg.evaluate("(c => fetch('/start_apply.htm', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: 'action_mode=apply&action_script=saveNvram&custom_clientlist=' + encodeURIComponent(c + '<Shed sensor>02:CC:00:00:00:99>0>0>>') }))", c1)
        await ren(macs[1], 'Hall lamp')
        check(await until(pg, has('Hall lamp', 'Shed sensor')), 'rename: a change made elsewhere since the page last read the list stays')
        await until(pg, closed, 20)
        # two renames in a row, the second picked while the first is saving: neither undoes the other; no cancelling a save
        await ren(macs[2], 'First one')
        locked = await pg.evaluate("document.getElementById('arRoNo').disabled && document.getElementById('arRoOk').disabled")
        await ren(macs[3], 'Second one')
        check(await until(pg, has('First one', 'Second one', 'Hall lamp', 'Shed sensor'), 15) and locked,
              'rename: two renames in a row both stay, and the cross is off while a name is saving (%s)' % locked)
        await until(pg, closed, 20)
        # a device without a nickname: the name shown, left as it is, saves nothing
        await ren(macs[5], ''); await until(pg, "fetch('/_custom').then(r => r.json()).then(c => !c.toUpperCase().includes(%r))" % macs[5]); await until(pg, closed, 20)
        c2 = await cust(); await edit(macs[5]); pre = await pg.evaluate("document.getElementById('arRoIn').value")
        await pg.keyboard.press('Enter'); await pg.wait_for_timeout(1500)
        check(macs[5] not in c2.upper() and await cust() == c2 and await pg.evaluate(closed), 'rename: the name shown, left as it is, saves nothing (%r)' % pre)
        # a name Arteria would ignore (one routers fill in themselves) is refused, not saved
        c3 = await cust(); await edit(macs[4]); await pg.fill('#arRoIn', 'ESP-Kitchen'); await pg.keyboard.press('Enter'); await pg.wait_for_timeout(800)
        hint = await pg.evaluate("document.getElementById('arRoLink').textContent")
        check('ignores' in hint and await cust() == c3 and not await pg.evaluate(closed), 'rename: a name Arteria ignores is refused (%r)' % hint)
        await pg.keyboard.press('Escape'); await pg.wait_for_timeout(150)
        # the expanded view: Tab goes from the field to the check and the cross; Escape there leaves the name, not the view
        await pg.click('#arBig'); await pg.wait_for_timeout(600)
        await edit(macs[4]); await pg.keyboard.press('Tab')
        f1 = await pg.evaluate("document.activeElement.id"); await pg.keyboard.press('Tab')
        f2 = await pg.evaluate("document.activeElement.id"); await pg.keyboard.press('Escape'); await pg.wait_for_timeout(150)
        check(f1 == 'arRoOk' and f2 == 'arRoNo' and await pg.evaluate(closed) and await pg.evaluate('Arteria.state.big'),
              'rename, expanded view: Tab reaches the check and the cross, Escape there leaves the name and keeps the view (%s, %s)' % (f1, f2))
        # zoomed in, a label tabbed to out of view brings itself into view
        for _ in range(4): await pg.click('#arZoomIn'); await pg.wait_for_timeout(80)
        await pg.wait_for_timeout(300)
        inview = "(l => { const r = l.getBoundingClientRect(), m = document.getElementById('arMap').getBoundingClientRect(); return r.left >= m.left && r.right <= m.right && r.top >= m.top && r.bottom <= m.bottom; })"
        out = await pg.evaluate("(f => [...document.querySelectorAll('#arMapLabels .ar-lb')].findIndex(l => !f(l)))(%s)" % inview)
        if out >= 0:
            await pg.keyboard.press('Shift')
            await pg.evaluate("document.querySelectorAll('#arMapLabels .ar-lb')[%d].focus()" % out); await pg.wait_for_timeout(200)
            check(await pg.evaluate("%s(document.querySelectorAll('#arMapLabels .ar-lb')[%d])" % (inview, out)), 'zoom: a label tabbed to out of view comes into view')
        else: check(False, 'zoom: no label out of view at 400%')
        await ctx.close()
    finally:
        srv.terminate()


async def guard(b, port_busy, port_dead):
    # the router paused sampling because it was overloaded: the page says why, and asks less often
    srv = await serve('overload', port_busy)
    try:
        ctx = await b.new_context(viewport={'width': 1600, 'height': 900})
        pg = await ctx.new_page(); await pg.goto('http://127.0.0.1:%d/user1.asp' % port_busy)
        await pg.wait_for_timeout(3500)
        live = await pg.evaluate("document.getElementById('arLiveTxt').textContent")
        note = await pg.evaluate("(document.querySelector('#ar .ar-notice .tx') || {}).textContent || ''")
        check(live == 'Router busy · paused' and 'busy (load 14.20 on 4 cores)' in note and 'about 2 minutes' in note,
              'guard: when the router pauses itself, the page says why (%r, %r)' % (live, note[:70]))
        # opened over a minute ago, the router samples again: the page goes live, without giving up first or switching
        # to the classic form for its requests
        await pg.evaluate("Arteria.state.started = Date.now() - 61000"); await pg.evaluate("fetch('/_set/resumed/1')")
        seen = []
        end = time.time() + 16
        while time.time() < end:
            t = await pg.evaluate("document.getElementById('arLiveTxt').textContent")
            if not seen or seen[-1] != t: seen.append(t)
            if t.startswith('Live'): break
            await pg.wait_for_timeout(200)
        form = await pg.evaluate('Arteria.state.useForm')
        check(seen[-1].startswith('Live') and 'Stopped · try again' not in seen and not form,
              'guard: after a pause the page goes live again, without giving up or changing how it asks (%s)' % ' → '.join(seen))
        await ctx.close()
    finally:
        srv.terminate()
    # nothing ever comes back: after a minute the page stops asking, says what to check, and the Live button tries again
    srv = await serve('dead', port_dead)
    try:
        ctx = await b.new_context(viewport={'width': 1600, 'height': 900})
        pg = await ctx.new_page(); await pg.goto('http://127.0.0.1:%d/user1.asp' % port_dead)
        await pg.wait_for_timeout(1500)
        await pg.evaluate("Arteria.state.started = Date.now() - 61000")
        await pg.wait_for_timeout(2600)
        live = await pg.evaluate("document.getElementById('arLiveTxt').textContent")
        note = await pg.evaluate("(document.querySelector('#ar .ar-notice .tx') || {}).textContent || ''")
        n0 = await pg.evaluate("fetch('/_posts').then(r => r.json())")
        await pg.wait_for_timeout(9000)
        n1 = await pg.evaluate("fetch('/_posts').then(r => r.json())")
        check(live == 'Stopped · try again' and 'No samples from the router for a minute' in note and n1 == n0,
              'guard: with no samples for a minute the page stops asking the router (%r, %d -> %d requests)' % (live, n0, n1))
        await pg.click('#arLive'); await pg.wait_for_timeout(600)
        n2 = await pg.evaluate("fetch('/_posts').then(r => r.json())")
        live2 = await pg.evaluate("document.getElementById('arLiveTxt').textContent")
        check(n2 > n1 and live2 == 'Connecting…', 'guard: the Live button asks again (%r, %d requests)' % (live2, n2 - n1))
        await ctx.close()
    finally:
        srv.terminate()


async def outlines(b, port):
    # labels are placed around each drawing's outline (its bbox): every drawing must stay inside it, glows and beams included
    srv = await serve('home', port)
    try:
        ctx = await b.new_context(viewport={'width': 1600, 'height': 900})
        pg = await ctx.new_page(); await pg.goto('http://127.0.0.1:%d/user1.asp' % port); await ready(pg)
        out = await pg.evaluate('''() => {
            const T = Arteria._t, out = [], svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
            svg.setAttribute('width', 2000); svg.setAttribute('height', 2000); document.body.appendChild(svg);
            Object.keys(T.KIND_LABEL).forEach(k => {
                const o = T.objDevice('t', k, 8, 8, 'L'), bb = o.bbox();
                svg.innerHTML = '<g>' + o.svg.join('') + '</g>'; const g = svg.firstElementChild.getBBox();
                const d = [bb[0] - g.x, bb[1] - g.y, g.x + g.width - bb[2], g.y + g.height - bb[3]].map(Math.round);
                if (Math.max(...d) > 3) out.push(k + ' ' + JSON.stringify(d));
            });
            svg.remove(); return out; }''')
        check(not out, 'every drawing stays inside the outline its label is placed around' + ('' if not out else ': ' + '; '.join(out)))
        await ctx.close()
    finally:
        srv.terminate()


async def start_theme_motion(b, port, port_rog):
    # 1. until the page is live it asks for samples every second (the router's second sample comes a second after its first:
    #    a router that hasn't answered yet, here), then at the interval the samples state (2 s); gaps include the server's answer
    dead = await serve('dead', port + 20)
    try:
        dc = await b.new_context(viewport={'width': 1300, 'height': 900})
        dp = await dc.new_page()
        await dp.goto('http://127.0.0.1:%d/user1.asp' % (port + 20))
        await dp.wait_for_timeout(4500)
        lv = await (await dp.request.get('http://127.0.0.1:%d/_lives' % (port + 20))).json()
        dg = [round(b2 - a2, 2) for a2, b2 in zip(lv, lv[1:])]
        await dc.close()
    finally:
        dead.terminate()
    srv = await serve('home', port)
    try:
        ctx = await b.new_context(viewport={'width': 1300, 'height': 900})
        pg = await ctx.new_page()
        await pg.goto('http://127.0.0.1:%d/user1.asp' % port)
        await ready(pg)
        await pg.wait_for_timeout(4500)
        lives = await (await pg.request.get('http://127.0.0.1:%d/_lives' % port)).json()
        gaps = [round(b2 - a2, 2) for a2, b2 in zip(lives, lives[1:])]
        # a second each until live: the gaps after the first under 1.5 s; the first includes the page's first full drawing, so it
        # only has to be well short of the 2 s pace's two gaps
        check(len(dg) >= 3 and max(dg[1:]) < 1.5 and dg[0] < 2.6 and len(gaps) >= 3 and min(gaps[-2:]) > 1.8,
              'start: until it is live the page asks for samples every second (%s), then every 2 s (%s)' % (dg[:4], gaps[-2:]))
        # 2. less motion asked for: the packets stand still, the legend says so; Animate starts them, and the browser remembers
        mc = await b.new_context(viewport={'width': 1300, 'height': 900}, reduced_motion='reduce')
        mp = await mc.new_page()
        await mp.goto('http://127.0.0.1:%d/user1.asp' % port)
        await ready(mp)
        anim = "() => getComputedStyle(document.querySelector('#arMapScene .df-a')).animationName"
        still = await mp.evaluate("() => !document.getElementById('arMotion').classList.contains('hide')"), await mp.evaluate(anim)
        await mp.click('#arMotionOn'); await mp.wait_for_timeout(200)
        moving = await mp.evaluate("() => document.getElementById('arMotion').classList.contains('hide')"), await mp.evaluate(anim)
        await mp.reload(); await ready(mp)
        kept = await mp.evaluate("() => document.getElementById('ar').classList.contains('anim') && document.getElementById('arMotion').classList.contains('hide')")
        check(still[0] and still[1] == 'none' and moving[0] and moving[1] != 'none' and kept,
              'less motion: the packets stand still and the legend says so; Animate starts them, and is remembered (%s %s %s)' % (still, moving, kept))
        await mc.close(); await ctx.close()
    finally:
        srv.terminate()
    # 3. a ROG router's page: black, with red highlights (the router's ring and light strip too); the traffic's colours stay
    srv = await serve('home', port_rog, {'AR_THEME': 'rog'})
    try:
        ctx = await b.new_context(viewport={'width': 1300, 'height': 900})
        pg = await ctx.new_page()
        await pg.goto('http://127.0.0.1:%d/user1.asp' % port_rog)
        await ready(pg)
        th = await pg.evaluate('''() => { const ar = document.getElementById('ar'), cs = getComputedStyle(ar);
            return { cls: ar.className, acc: cs.getPropertyValue('--accent').trim(), dn: cs.getPropertyValue('--dn').trim(),
                tab: getComputedStyle(document.querySelector('#ar .ar-tabs button.on')).borderBottomColor,
                stage: getComputedStyle(document.querySelector('#ar .ar-stage')).backgroundColor,
                ring: document.getElementById('arMapScene').innerHTML.indexOf('#ff3349') >= 0 }; }''')
        check('th-rog' in th['cls'] and th['acc'] == '#ff3349' and th['tab'] == 'rgb(255, 51, 73)' and th['stage'] == 'rgb(23, 24, 26)' and th['dn'] == '#59c3ff' and th['ring'],
              'theme: a ROG router\'s page is black with red highlights, the traffic\'s colours unchanged (%s)' % th)
        await ctx.close()
    finally:
        srv.terminate()


async def main():
    if not CHROME:
        sys.exit('page-browser.py needs Chrome or Chromium (or its path as the argument)')
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path=CHROME, args=['--no-sandbox'])
        # every scenario at once, each in its own browser context against its own preview server
        await asyncio.gather(*[scenario(b, s, 8700 + i) for i, s in enumerate(SCENARIOS)], two_tabs(b, 8790), speed_test(b, 8791), zoom(b, 8792), rename(b, 8793), outlines(b, 8794), guard(b, 8795, 8796), rename_safe(b, 8797), heartbeat_pace(b, 8798), stay_logged_in(b, 8799))
        await start_theme_motion(b, 8780, 8781)   # on its own: it times the page's first requests, which every other check would slow
        await b.close()


t0 = time.time()
asyncio.run(main())
print('Browser: %s (%d s)' % ('all checks passed.' if not fails else '%d failed.' % len(fails), time.time() - t0))
sys.exit(1 if fails else 0)
