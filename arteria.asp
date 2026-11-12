<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<meta http-equiv="Pragma" content="no-cache"/>
<meta http-equiv="Expires" content="-1"/>
<link rel="shortcut icon" href="images/favicon.png"/>
<link rel="icon" href="images/favicon.png"/>
<title>Arteria</title>
<!-- arteria-version: 1.0.0 (must match VERSION in arteria.sh) -->
<link rel="stylesheet" type="text/css" href="index_style.css"/>
<link rel="stylesheet" type="text/css" href="form_style.css"/>
<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script type="text/javascript" src="/validator.js"></script>
<style>
#ar {
	--surface: #2b3539;
	--line: #3d4a4f;
	--axis: #4a585d;
	--ink: #f0efec;
	--ink-2: #c3c2b7;
	--muted: #93a9b1;
	--accent: #ffcc00;
	--dn: #59c3ff;
	--up: #ff8a3d;
	--dnt: #9bdcff;
	--upt: #ffb27a;
	--mesh: #a99cf5;
	--bad: #ff9c8a;
	width: 728px;
	margin: 0 auto;
	font-family: system-ui, -apple-system, "Segoe UI", Arial, sans-serif;
	color: var(--ink);
	font-size: 12px;
}
#ar * { box-sizing: border-box; }
#ar button { font-family: inherit; cursor: pointer; }
#ar button:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
#ar .ar-bar { display: flex; align-items: center; gap: 14px; height: 46px; border-bottom: 1px solid #7d8c90; margin: 4px 0 12px; }
#ar .ar-tabs { display: flex; gap: 14px; align-self: stretch; }
#ar .ar-tabs button { background: none; border: 0; border-bottom: 2px solid transparent; color: #e3eaec; font-size: 13px; padding: 0 6px; min-width: 44px; margin-bottom: -1px; }
#ar .ar-tabs button:hover { color: #fff; }
#ar .ar-tabs button.on { color: #fff; border-bottom-color: var(--accent); font-weight: 600; cursor: default; }
#ar .ar-sum { flex: 1; display: flex; align-items: baseline; justify-content: flex-end; gap: 12px; white-space: nowrap; font-variant-numeric: tabular-nums; color: var(--ink); }
#ar .ar-sum .k { color: #e3eaec; }
#ar .ar-sum b { font-weight: 600; }
#ar .ar-sum .dn { color: var(--dnt); font-weight: 700; }
#ar .ar-sum .up { color: var(--upt); font-weight: 700; }
#ar .ar-unit { display: flex; flex: none; height: 32px; border: 1px solid #6b7b80; border-radius: 16px; overflow: hidden; }
#ar .ar-unit button { background: none; border: 0; margin: 0; padding: 0 9px; min-width: 44px; color: #c3c2b7; font-size: 11.5px; font-weight: 600; font-variant-numeric: tabular-nums; }
#ar .ar-unit button:hover { color: #fff; }
#ar .ar-unit button.on { background: #3a4549; color: #fff; cursor: default; }
#ar .ar-live { min-height: 44px; padding: 0 16px; display: flex; align-items: center; gap: 8px; border-radius: 22px; border: 1px solid #6b7b80; background: var(--surface); color: var(--ink); font-size: 12px; font-weight: 600; white-space: nowrap; flex: none; }
#ar .ar-live .dot { width: 8px; height: 8px; border-radius: 4px; background: var(--muted); flex: none; }
#ar .ar-live.live .dot { background: #3ddc97; animation: arblink 1.6s ease-in-out infinite; }
#ar .ar-live.warn .dot { background: var(--accent); }
#ar .ar-stage { position: relative; width: 728px; height: 518px; border-radius: 12px; background: var(--surface); border: 1px solid var(--line); overflow: hidden; }
#ar .ar-view { display: none; position: absolute; left: 0; top: 0; width: 726px; height: 516px; }
#ar .ar-view.on { display: block; }
#ar .ar-view > svg { position: absolute; left: -1px; top: -1px; display: block; }
#ar .eyebrow { font-size: 10.5px; line-height: 13px; font-weight: 600; letter-spacing: .08em; text-transform: uppercase; color: var(--muted); }
#ar .ar-over { position: absolute; font-size: 11px; line-height: 15px; color: var(--ink-2); pointer-events: none; }
#ar .ar-legend { display: flex; flex-direction: column; gap: 5px; }
#ar .ar-legend span.sw { display: inline-block; width: 8px; height: 8px; border-radius: 4px; margin-right: 6px; vertical-align: 0; }
#ar .ar-notice { display: flex; align-items: center; gap: 7px; max-width: 420px; font-size: 11.5px; color: var(--ink); }
#ar .ar-notice .sw { width: 8px; height: 8px; border-radius: 4px; flex: none; background: var(--muted); }
#ar .ar-lb { position: absolute; height: 44px; margin: 0; padding: 0; border: 0; background: transparent; color: var(--ink); display: flex; align-items: center; transition: opacity .3s ease; }
#ar .ar-lb > span { display: flex; flex-direction: column; justify-content: center; gap: 1px; height: 34px; padding: 0 9px; border-radius: 8px; background: rgba(14,20,23,.93); border: 1px solid rgba(255,255,255,.2); text-align: left; white-space: nowrap; box-shadow: 0 2px 6px rgba(0,0,0,.28); max-width: 100%; overflow: hidden; }
#ar .ar-lb:hover > span { background: #101619; }
#ar .ar-lb.on > span { border-color: var(--accent); }
#ar .ar-lb.dim { opacity: .5; }
#ar .ar-lb .n { font-size: 11px; line-height: 14px; font-weight: 700; overflow: hidden; text-overflow: ellipsis; }
#ar .ar-lb .v { font-size: 10.5px; line-height: 13px; font-variant-numeric: tabular-nums; }
#ar .c-dn { color: var(--dnt); } #ar .c-up { color: var(--upt); } #ar .c-mut { color: var(--ink-2); } #ar .c-bad { color: var(--bad); } #ar .c-warn { color: var(--accent); }
#ar .ar-cards { display: flex; gap: 12px; margin-top: 12px; height: 224px; }
#ar .ar-card { background: var(--surface); border: 1px solid var(--line); border-radius: 12px; min-width: 0; }
#ar .ar-readout { width: 440px; flex: none; padding: 14px 16px; display: flex; flex-direction: column; gap: 10px; }
#ar .ar-ro-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; height: 16px; }
#ar .ar-badge { font-size: 10.5px; line-height: 14px; padding: 0 7px; border-radius: 8px; border: 1px solid var(--axis); color: var(--ink-2); white-space: nowrap; }
#ar .ar-ro-id { display: flex; align-items: center; gap: 10px; height: 36px; }
#ar .ar-ico { width: 36px; height: 36px; border-radius: 9px; background: #1c2427; border: 1px solid var(--line); display: flex; align-items: center; justify-content: center; flex: none; }
#ar .ar-ro-name { font-size: 16px; line-height: 19px; font-weight: 700; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
#ar .ar-ro-link { font-size: 12px; line-height: 15px; color: var(--ink-2); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
#ar .ar-metrics { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 20px; }
#ar .ar-metric { display: flex; flex-direction: column; gap: 4px; min-width: 0; }
#ar .ar-metric .top { display: flex; align-items: baseline; gap: 5px; height: 28px; }
#ar .ar-metric .lbl { font-size: 11px; color: var(--muted); width: 68px; flex: none; }
#ar .ar-metric .num { font-size: 24px; line-height: 28px; font-weight: 700; font-variant-numeric: tabular-nums; }
#ar .ar-metric .unit { font-size: 12px; color: var(--muted); }
#ar .ar-track { height: 4px; border-radius: 2px; background: #1a2225; overflow: hidden; }
#ar .ar-track > div { height: 4px; border-radius: 2px; width: 0; transition: width .4s ease; }
#ar .ar-metric .share { font-size: 10.5px; line-height: 13px; color: var(--muted); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
#ar .ar-stats { display: flex; gap: 16px; height: 29px; }
#ar .ar-stat { display: flex; flex-direction: column; gap: 1px; min-width: 0; }
#ar .ar-stat .k { font-size: 10.5px; line-height: 13px; color: var(--muted); white-space: nowrap; }
#ar .ar-stat .v { font-size: 12px; line-height: 15px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
#ar .ar-note { font-size: 11px; line-height: 15px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; color: var(--ink-2); }
#ar .ar-side { flex: 1 1 0; padding: 12px 8px 6px; display: flex; flex-direction: column; gap: 6px; }
#ar .ar-top button { height: 44px; width: 100%; margin: 0; padding: 0 8px; display: flex; align-items: center; gap: 9px; border-radius: 8px; border: 1px solid transparent; background: transparent; color: var(--ink); text-align: left; min-width: 0; }
#ar .ar-top button:hover { background: rgba(255,255,255,.04); }
#ar .ar-top button.on { border-color: var(--accent); background: #3a4549; }
#ar .ar-top .nm { font-size: 12px; line-height: 14px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: block; }
#ar .ar-top .bar { display: block; height: 3px; border-radius: 2px; background: #1a2225; margin-top: 5px; }
#ar .ar-top .bar > span { display: block; height: 3px; border-radius: 2px; background: var(--dn); width: 0; transition: width .4s ease; }
#ar .ar-top .rt { display: flex; flex-direction: column; align-items: flex-end; gap: 1px; font-size: 11px; line-height: 14px; font-variant-numeric: tabular-nums; white-space: nowrap; flex: none; }
#ar .ar-empty { padding: 8px; color: var(--muted); font-size: 11.5px; }
#ar .ar-hist { flex: 1 1 0; padding: 14px 16px; display: flex; flex-direction: column; gap: 10px; }
#ar .ar-hist .vals { display: flex; gap: 16px; height: 22px; }
#ar .ar-hist .vals span.n { font-size: 18px; line-height: 22px; font-weight: 700; font-variant-numeric: tabular-nums; }
#ar .ar-hist .vals span.u, #ar .ar-hist .vals span.l { font-size: 11px; color: var(--muted); }
#ar .ar-flowbar { position: absolute; left: 12px; top: 10px; right: 16px; height: 44px; display: flex; align-items: center; gap: 14px; }
#ar .ar-seg { display: flex; border-radius: 22px; border: 1px solid #6b7b80; overflow: hidden; flex: none; }
#ar .ar-seg button { height: 44px; margin: 0; padding: 0 16px; border: 0; background: transparent; color: var(--ink-2); font-size: 12px; font-weight: 600; white-space: nowrap; }
#ar .ar-seg button.on-dn { background: #1f4a63; color: var(--dnt); }
#ar .ar-seg button.on-up { background: #5a3520; color: var(--upt); }
#ar .ar-scale { display: flex; align-items: center; gap: 7px; flex: none; font-size: 11px; color: var(--ink-2); font-variant-numeric: tabular-nums; white-space: nowrap; }
#ar .ar-scale .sw { width: 4px; height: 24px; border-radius: 2px; background: var(--dn); }
#ar .ar-row { position: absolute; left: 530px; width: 190px; margin: 0; padding: 0 6px; display: flex; align-items: center; gap: 6px; border-radius: 8px; border: 1px solid transparent; background: rgba(255,255,255,.035); color: var(--ink); text-align: left; overflow: hidden; }
#ar .ar-row.on { border-color: var(--accent); background: #3a4549; }
#ar .ar-row.off { opacity: .6; }
#ar .ar-row .tx { flex: 1 1 0; min-width: 0; display: flex; flex-direction: column; gap: 1px; }
#ar .ar-row .nm { font-size: 12px; line-height: 15px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
#ar .ar-row .sb { font-size: 10.5px; line-height: 13px; color: var(--muted); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
#ar .ar-row .vl { display: flex; flex-direction: column; align-items: flex-end; gap: 1px; flex: none; }
#ar .ar-row .vl .n { font-size: 13px; line-height: 15px; font-weight: 700; font-variant-numeric: tabular-nums; }
#ar .ar-row .vl .u { font-size: 10px; line-height: 13px; color: var(--muted); }
#ar .ar-foot { margin-top: 8px; color: var(--muted); font-size: 11px; display: flex; justify-content: space-between; gap: 10px; }
#ar .ar-foot a { color: var(--muted); }
#ar .hide { display: none !important; }
/* Animation: CSS only, so the browser does the work and the router just answers a poll every 2 s. */
#ar .df-a { animation-timing-function: linear; animation-iteration-count: infinite; }
#ar .df-led { animation-name: arled; }
#ar .df-ripple { transform-box: fill-box; transform-origin: center; animation-name: arripple; animation-duration: 2.6s; animation-timing-function: ease-out; }
#ar.paused .df-a, #ar.paused .ar-live .dot { animation-play-state: paused !important; }
#ar .lk, #ar .ob, #ar .rb { transition: opacity .3s ease; }
#ar .lk.dim { opacity: .14; } #ar .ob.dim { opacity: .38; } #ar .ob.off { opacity: .3; }
#ar .rb.dim { opacity: .2; } #ar .rb.mid { opacity: .55; }
#ar .alt-off { stroke: #ff9c8a; } #ar .alt-nd { stroke: #c3c2b7; } #ar .alt-warn { stroke: #ffcc00; }
#ar .rf { fill-opacity: .34; stroke-opacity: .55; stroke-width: 1px; }
#ar .m-dn .rf, #ar .m-dn .bf { fill: #59c3ff; stroke: #59c3ff; }
#ar .m-up .rf, #ar .m-up .bf { fill: #ff8a3d; stroke: #ff8a3d; }
#ar .bf, #ar .bm { stroke: none !important; }
#ar .bm { fill: #a99cf5; }
#ar .m-dn .rf.bhc, #ar .m-up .rf.bhc { fill: #a99cf5; stroke: #a99cf5; }
#ar .rf.loc { fill-opacity: .2; }
#ar .rf.nd { fill-opacity: .16; stroke-dasharray: 3 4; }
#ar .rf.hl { fill-opacity: .8; stroke-opacity: 1; }
#ar .m-dn .sk { stroke: #d5f0ff; } #ar .m-up .sk { stroke: #ffdcc2; }
#ar .sk { stroke-opacity: .9; fill: none; stroke-width: 2.2px; stroke-linecap: round; }
@keyframes arblink { 0%, 100% { opacity: 1; } 50% { opacity: .25; } }
@keyframes arled { 0%, 40%, 60%, 100% { opacity: 1; } 50% { opacity: .15; } }
@keyframes arripple { from { transform: scale(1); opacity: .75; } to { transform: scale(2.3); opacity: 0; } }
@media (prefers-reduced-motion: reduce) { #ar .df-a, #ar .ar-live .dot { animation: none !important; } #ar .lk, #ar .ob, #ar .rb, #ar .ar-lb { transition: none; } }
</style>
<style id="arPackets"></style>
<script type="text/javascript">
/* Everything below is private, so nothing clashes with the firmware's globals (jQuery's $, store, ...).
   Only initial() (called by <body onload>) and the Arteria object (used by the page's buttons) are global. */
(function () {
'use strict';
var VERSION = '1.0.0';
var BASE = '/ext/arteria/';
var DN = '#59c3ff', UP = '#ff8a3d', DNT = '#9bdcff', UPT = '#ffb27a', MESH = '#a99cf5', ACC = '#ffcc00', BAD = '#ff9c8a', MUTED = '#93a9b1', INK2 = '#c3c2b7';
/* Packets: one CSS class per bucket (b0 = busiest). As throughput rises on a log scale, packets grow
   (wider and longer) and sit closer together. They all move at the same slow, steady speed, so nothing
   speeds up or flickers when traffic changes: watching the map for minutes should be calm. */
var PERIODS = [28, 32, 36, 41, 47, 54, 62, 71, 80];   /* spacing, px */
var PK_W = [8.0, 7.2, 6.4, 5.6, 4.9, 4.2, 3.6, 3.0, 2.6];   /* width, px */
var PK_D = [5.0, 4.5, 4.0, 3.5, 3.0, 2.5, 2.0, 1.5, 1.0];   /* length beyond the round caps, px */
var SPEED = 40, SK_SPEED = 42;   /* px per second: map packets, flow streaks */

var A = {
	tab: 'map', mode: 'dn', unit: 'Mb', sel: null, paused: false,
	interval: 2, seq: null, up: null, fresh: 0, started: Date.now(), useForm: false, gotAny: false,
	prev: {}, sm: {}, bk: {}, names: null, namesAt: 0,
	net: null, mapSig: '', flowSig: '', slot: {}, slotAt: 0, flowPick: null, flowAt: 0,
	hist: [], timers: {}, mapRefs: null, flowRefs: null, labels: {}
};

/* ---------------------------------------------------------------- small helpers */
function $(id) { return document.getElementById(id); }
function esc(s) {
	return String(s === null || s === undefined ? '' : s).replace(/[&<>"']/g, function (c) {
		return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
	});
}
function n1(v) { return (Math.round(v * 10) / 10).toString(); }
function hash(s) { var h = 7; for (var i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) % 100003; return h; }
/* Rates are kept in Mb/s (megabits); A.unit 'MB' shows them in megabytes (÷ 8): kB/s, MB/s, GB/s.
   Link rates (Wi-Fi and Ethernet) stay in Mb/s, as the hardware states them. */
function fmt(x) {
	if (x === null || x === undefined || isNaN(x)) return { n: '—', u: '' };
	var B = A.unit === 'MB', v = B ? x / 8 : x, k = B ? 'kB/s' : 'kb/s', m = B ? 'MB/s' : 'Mb/s';
	if (v < 0.0005) return { n: '0', u: k };
	if (v < 0.9995) return { n: String(Math.round(v * 1000)), u: k };
	if (v < 99.95) return { n: v.toFixed(1), u: m };
	if (v < 999.5) return { n: v.toFixed(0), u: m };
	return { n: (v / 1000).toFixed(2), u: B ? 'GB/s' : 'Gb/s' };
}
function full(x) { var f = fmt(x); return f.u ? f.n + ' ' + f.u : f.n; }
function short(x) { var f = fmt(x), u = f.u.charAt(0); return f.n === '0' ? '0' : (u === 'k' ? f.n + 'k' : (u === 'G' ? f.n + 'G' : f.n)); }
function store(k, v) {
	try { if (v === undefined) return localStorage.getItem('arteria.' + k); localStorage.setItem('arteria.' + k, v); }
	catch (e) { return null; }
}
function mix(hex, t, to) {
	to = to || '#ffffff';
	var a = [1, 3, 5].map(function (i) { return parseInt(hex.substr(i, 2), 16); });
	var b = [1, 3, 5].map(function (i) { return parseInt(to.substr(i, 2), 16); });
	return '#' + a.map(function (v, i) { var c = Math.round(v + (b[i] - v) * t); return (c < 16 ? '0' : '') + c.toString(16); }).join('');
}
/* Density bucket for a smoothed rate, with hysteresis so a rate sitting on a boundary doesn't
   re-start the packets every poll. */
function bucketOf(key, x) {
	if (!(x > 0.0005)) { A.bk[key] = 'bx'; return 'bx'; }
	var p = 80 - 17 * Math.log10(10 * x + 1), want = PERIODS.length - 1;
	for (var i = 0; i < PERIODS.length; i++) if (p <= PERIODS[i]) { want = i; break; }
	var cur = A.bk[key];
	if (cur && cur !== 'bx') {
		var c = +cur.substr(1), lo = c > 0 ? PERIODS[c - 1] - 1.5 : -1e9, hi = PERIODS[c] + 1.5;
		if (p > lo && p <= hi) return cur;
	}
	A.bk[key] = 'b' + want;
	return A.bk[key];
}
function packetCss() {
	var out = [], keys = {};
	PERIODS.forEach(function (P, i) {
		keys[P] = 1; keys[2 * P] = 1;
		out.push('#ar .pk.b' + i + '{stroke-dasharray:' + PK_D[i] + ' ' + (P - PK_D[i]) + ';animation-name:arp' + P + ';animation-duration:' + (P / SPEED).toFixed(3) + 's;stroke-width:' + PK_W[i] + 'px}');
		out.push('#ar .pk.h.b' + i + '{stroke-width:' + (PK_W[i] * 1.9).toFixed(1) + 'px}');
		out.push('#ar .pk.t.b' + i + '{stroke-width:' + (PK_W[i] * 0.8).toFixed(1) + 'px}#ar .pk.t.h.b' + i + '{stroke-width:' + (PK_W[i] * 1.5).toFixed(1) + 'px}');
		out.push('#ar .sk.b' + i + '{stroke-dasharray:11 ' + (2 * P - 11) + ';animation-name:arp' + (2 * P) + ';animation-duration:' + (2 * P / SK_SPEED).toFixed(3) + 's}');
	});
	out.push('#ar .pk.bx,#ar .sk.bx{display:none}');
	Object.keys(keys).forEach(function (k) { out.push('@keyframes arp' + k + '{from{stroke-dashoffset:0}to{stroke-dashoffset:-' + k + '}}'); });
	return out.join('\n');
}

/* ---------------------------------------------------------------- icons (24x24 strokes) */
function rr(x, y, w, h, r) {
	return 'M' + (x + r) + ' ' + y + 'h' + (w - 2 * r) + 'a' + r + ' ' + r + ' 0 0 1 ' + r + ' ' + r + 'v' + (h - 2 * r) + 'a' + r + ' ' + r + ' 0 0 1 ' + (-r) + ' ' + r +
		'h' + (-(w - 2 * r)) + 'a' + r + ' ' + r + ' 0 0 1 ' + (-r) + ' ' + (-r) + 'v' + (-(h - 2 * r)) + 'a' + r + ' ' + r + ' 0 0 1 ' + r + ' ' + (-r) + 'z';
}
function ci(cx, cy, r) { return 'M' + (cx - r) + ' ' + cy + 'a' + r + ' ' + r + ' 0 1 0 ' + (2 * r) + ' 0a' + r + ' ' + r + ' 0 1 0 ' + (-2 * r) + ' 0z'; }
var ICON = {
	globe: ci(12, 12, 9) + 'M3 12h18M12 3c3.2 3.4 3.2 14.6 0 18M12 3c-3.2 3.4-3.2 14.6 0 18',
	router: rr(3, 13, 18, 6, 2) + 'M7 13V7M12 13V5M17 13V7M7 16h.01M10 16h.01',
	mesh: rr(7, 3, 10, 18, 3) + 'M10 8a3 3 0 0 1 4 0M12 15h.01',
	nas: rr(5, 3, 14, 18, 2) + 'M9.5 7v9M14.5 7v9M9.5 18.5h.01M14.5 18.5h.01',
	laptop: rr(5, 5, 14, 10, 1) + 'M2.5 19h19',
	phone: rr(7.5, 3, 9, 18, 2) + 'M11 18h2',
	tv: rr(3, 5, 18, 12, 1.5) + 'M9 21h6M12 17v4',
	tablet: rr(5, 3, 14, 18, 2) + 'M11 18h2',
	iot: 'M9 3v5M15 3v5' + rr(6, 8, 12, 7, 2) + 'M12 15v6',
	console: rr(3, 8, 18, 9, 4.5) + 'M8 11v3M6.5 12.5h3M15.5 12h.01M17.5 13.5h.01',
	generic: rr(4, 7, 16, 10, 2) + 'M8 12h.01M12 12h4',
	switch: rr(2.5, 8, 19, 8, 1.5) + 'M6 12h.01M9 12h.01M12 12h.01M15 12h.01M18 12h.01',
	more: ci(6, 12, 1.6) + ci(12, 12, 1.6) + ci(18, 12, 1.6),
	home: 'M4 11l8-7 8 7M6 9.5V20h12V9.5'
};
function iconSvg(name, size, color) {
	return '<svg width="' + size + '" height="' + size + '" viewBox="0 0 24 24" aria-hidden="true" style="display:block;flex:none">' +
		'<path d="' + (ICON[name] || ICON.generic) + '" style="fill:none;stroke:' + color + ';stroke-width:1.7;stroke-linecap:round;stroke-linejoin:round"/></svg>';
}

/* ---------------------------------------------------------------- talking to the router
   The page asks the router to sample by "starting" a service named arteria every few seconds
   (Merlin passes it to the addon's service-event hook). The router stops sampling about 20 s
   after the last request, so a closed or hidden page costs the router nothing. */
function page() { return window.location.pathname.substring(1) || 'index.asp'; }
/* The same fields, with the same values, as the standard addon form below (formScriptActions):
   start_apply.htm is the router's settings handler, so it gets nothing else, and never an empty
   productid (the form's value is the router's own, filled in by the router). */
function pokeBody(action) {
	var f = document.formScriptActions, pid = f && f.productid ? f.productid.value : '';
	return (pid ? 'productid=' + encodeURIComponent(pid) + '&' : '') + 'current_page=' + encodeURIComponent(page()) +
		'&next_page=' + encodeURIComponent(page()) + '&action_mode=apply&action_script=' + action + '&action_wait=';
}
function poke(action) {
	if (A.useForm && action === 'start_arteria') {   // fallback: the same form other addon pages submit
		var f = document.formScriptActions;
		if (f) { f.current_page.value = page(); f.next_page.value = page(); f.action_script.value = action; f.submit(); }
		return;
	}
	try {
		fetch('/start_apply.htm', { method: 'POST', credentials: 'same-origin', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: pokeBody(action) })
			.catch(function () {});
	} catch (e) { /* old browser: the poll will notice */ }
}
function stopBeacon() {
	try { if (navigator.sendBeacon) navigator.sendBeacon('/start_apply.htm', new Blob([pokeBody('start_arteriastop')], { type: 'application/x-www-form-urlencoded' })); }
	catch (e) { /* the router stops by itself */ }
}
function getJSON(name) {
	return fetch(BASE + name + '?_=' + Date.now(), { cache: 'no-store', credentials: 'same-origin' })
		.then(function (r) { if (!r.ok) throw new Error(r.status); return r.text(); })
		.then(function (t) { return JSON.parse(t); });
}
function running() { return !A.paused && !document.hidden; }
function heartbeat() {
	clearTimeout(A.timers.hb);
	if (!running()) return;
	poke('start_arteria');
	A.timers.hb = setTimeout(heartbeat, 8000);
}
function poll() {
	clearTimeout(A.timers.poll);
	if (!running()) return;
	getJSON('live.htm').then(onSample, function () { onSample(null); }).then(function () {
		A.timers.poll = setTimeout(poll, Math.max(1, A.interval) * 1000);
	});
	if (Date.now() - A.namesAt > 30000) loadNames();
}
function loadNames() {
	A.namesAt = Date.now();
	getJSON('names.htm').then(function (n) { A.names = parseNames(n); }, function () {});
}
function resume() {
	A.fresh = 0; A.started = Date.now();
	heartbeat(); poll();
	setLive();
}
function suspend() {
	clearTimeout(A.timers.hb); clearTimeout(A.timers.poll);
	setLive();
}

/* ---------------------------------------------------------------- names and device kinds */
var WEAK = /^(dhcpcd|android-dhcp|udhcp|unknown|client|localhost|espressif|esp[_-]|wlan|\*|-)|:|^[0-9a-f]{10,}$/i;
function parseNames(n) {
	var out = { custom: {}, nmp: {}, lease: {}, cl: n && n.cl || {} };
	String(n && n.custom || '').split('<').forEach(function (e) {
		var f = e.split('>');
		if (f.length >= 2 && /^[0-9A-Fa-f:]{17}$/.test(f[1])) out.custom[f[1].toUpperCase()] = { name: f[0], type: +f[3] || 0 };
	});
	var nmp = n && n.nmp || {};
	Object.keys(nmp).forEach(function (k) { if (nmp[k]) out.nmp[k.toUpperCase()] = nmp[k]; });
	String(n && n.leases || '').split('|').forEach(function (l) {
		var f = l.split(' ');
		if (f.length >= 4 && /^[0-9A-Fa-f:]{17}$/.test(f[1])) out.lease[f[1].toUpperCase()] = { ip: f[2], host: f[3] };
	});
	return out;
}
function nameOf(mac) {
	var N = A.names, c = N && N.custom[mac], m = N && N.nmp[mac], l = N && N.lease[mac];
	if (c && c.name) return c.name;
	if (m && m.name && !WEAK.test(m.name) && m.name !== m.vendor) return m.name.trim();
	if (l && l.host && !WEAK.test(l.host)) return l.host;
	var v = m && (m.vendor || m.vendorclass);
	if (v && !WEAK.test(v)) return v.replace(/,? (Co\.|Inc\.|Ltd\.|Corp\.|Corporation|Limited|Technology|Technologies|Electronics|Manufacturing|Communication).*$/i, '').trim();
	return 'Device …' + mac.slice(-5);
}
var TYPE_KIND = { 1: 'laptop', 4: 'nas', 6: 'laptop', 7: 'console', 9: 'phone', 10: 'phone', 11: 'tv', 12: 'tv', 14: 'laptop', 19: 'phone', 20: 'tablet', 21: 'tablet', 23: 'tv', 25: 'tablet', 27: 'tv', 28: 'phone', 29: 'tablet', 30: 'laptop', 34: 'phone', 35: 'laptop' };
var KIND_RE = [
	['nas', /\bnas\b|synology|ugreen|qnap|dxp\d|truenas|unraid|diskstation|terramaster|asustor/i],
	['tv', /\btv\b|television|bravia|webos|tizen|roku|chromecast|fire ?tv|shield|apple ?tv|lg innotek|hisense|vizio|google tv|android ?tv/i],
	['tablet', /ipad|tablet|kindle|galaxy tab|\btab\b/i],
	['console', /playstation|\bps[45]\b|xbox|nintendo|steam ?deck/i],
	['laptop', /macbook|laptop|notebook|thinkpad|desktop|\bpc\b|imac|mac ?mini|windows|latitude|zenbook|vivobook|ideapad|chromebook|surface/i],
	['phone', /iphone|pixel|galaxy|android|xiaomi|redmi|oneplus|oppo|vivo|huawei|honor|motorola|realme|phone|poco/i],
	['iot', /espressif|esp32|esp8266|tuya|shelly|sonoff|tado|plug|bulb|\bhue\b|nest|ring\b|meross|tapo|wiz|yeelight|sensor|thermostat|doorbell|echo|alexa|amazon|sonos|speaker|vacuum|roborock|dyson|bridge|camera/i]
];
function kindOf(mac, name) {
	var N = A.names, c = N && N.custom[mac], m = N && N.nmp[mac], l = N && N.lease[mac];
	var txt = [name, m && m.name, m && m.vendor, m && m.vendorclass, l && l.host].join(' ');
	for (var i = 0; i < KIND_RE.length; i++) if (KIND_RE[i][1].test(txt)) return KIND_RE[i][0];
	return TYPE_KIND[(c && c.type) || (m && +m.type) || 0] || 'generic';
}

/* ---------------------------------------------------------------- rates
   Counters arrive as running byte totals; a rate is the difference between two samples. A counter
   that went down means the client reconnected or roamed: that sample is skipped, never negative. */
function rate(key, t, dnBytes, upBytes) {
	var cur = { t: t, d: +dnBytes, u: +upBytes }, p = A.prev[key];
	A.prev[key] = cur;
	if (!p || !(t > p.t) || isNaN(cur.d) || isNaN(cur.u)) return null;
	var dt = t - p.t;
	if (dt > 30 || cur.d < p.d || cur.u < p.u) return null;
	return { dn: (cur.d - p.d) * 8 / dt / 1e6, up: (cur.u - p.u) * 8 / dt / 1e6 };
}
function smooth(key, r) {
	var s = A.sm[key];
	if (!r) { if (s) s.age++; return s || { dn: 0, up: 0, sdn: 0, sup: 0, ok: false, age: 0 }; }
	if (!s) s = A.sm[key] = { dn: r.dn, up: r.up, sdn: r.dn, sup: r.up };
	else { s.dn += 0.6 * (r.dn - s.dn); s.up += 0.6 * (r.up - s.up); s.sdn += 0.2 * (r.dn - s.sdn); s.sup += 0.2 * (r.up - s.sup); }
	s.ok = true; s.age = 0;
	return s;
}
function measure(key, t, d, u) { return smooth(key, rate(key, t, d, u)); }

/* ---------------------------------------------------------------- the network, from one sample */
function bandName(b) { return b === '2.4' ? '2.4 GHz' : (b === '6' ? '6 GHz' : (b === '5' ? '5 GHz' : 'Wi-Fi')); }
function portLabel(d, ifn) {
	var i = (d.ports || []).indexOf(ifn), sp = linkOf(d, ifn).speed;
	if (sp >= 2500) return (sp >= 10000 ? '10G' : (sp / 1000) + 'G') + ' port';
	return 'LAN ' + (i + 1);
}
function linkOf(d, ifn) {
	var l = (d.links || []).filter(function (x) { return x[0] === ifn; })[0];
	return { up: l ? l[1] === 1 : false, speed: l && l[2] > 0 ? l[2] : 0 };
}
function buildNet(d) {
	var t = parseFloat(d.up), own = {}, bh = {}, net = { router: d.router || {}, nodes: [], devs: [], byId: {}, ms: d.ms, interval: d.interval };
	(d.own || []).forEach(function (m) { own[m] = 1; });
	var ifs = {};
	(d.ifs || []).forEach(function (r) { ifs[r[0]] = r; });
	/* internet */
	var w = ifs[d.wan];
	net.wan = w ? measure('wan', t, w[1], w[2]) : { dn: 0, up: 0, sdn: 0, sup: 0, ok: false };
	net.wanIf = d.wan; net.wanSpeed = linkOf(d, d.wan).speed;
	/* AiMesh nodes and the addresses they use to reach the router */
	(d.nodes || []).forEach(function (n, i) {
		var node = { id: 'node:' + n.mac, mac: n.mac, ip: n.ip, model: n.model || 'AiMesh node', alias: n.alias || '', state: n.state, nup: n.up,
			rows: n.c || [], sta: String(n.sta || '').split(/\s+/).filter(Boolean), bh: { dn: 0, up: 0, sdn: 0, sup: 0, ok: false }, bhRows: [], devs: [], idx: i };
		node.name = node.alias || node.model;
		node.sta.forEach(function (m) { bh[m] = node; });
		net.nodes.push(node);
	});
	/* the router's own Wi-Fi clients, and the nodes' backhaul stations */
	var seen = {};
	(d.sta || []).forEach(function (r) {
		var mac = r[2];
		if (bh[mac]) { bh[mac].bhRows.push({ r: r, s: measure('b:' + mac, t, r[3], r[4]) }); return; }
		if (own[mac]) return;
		var s = measure('r:' + mac, t, r[3], r[4]);
		seen[mac] = { ap: 'router', ifn: r[0], band: r[1], mac: mac, rssi: r[5], phy: r[6], conn: r[8], s: s, st: 'ok' };
	});
	net.nodes.forEach(function (node) {
		var b = { dn: 0, up: 0, sdn: 0, sup: 0, ok: false }, best = null;
		node.bhRows.forEach(function (x) {
			b.dn += x.s.dn; b.up += x.s.up; b.sdn += x.s.sdn; b.sup += x.s.sup; b.ok = b.ok || x.s.ok;
			if (!best || x.s.sdn + x.s.sup > best.s.sdn + best.s.sup || (x.r[1] !== '2.4' && best.r[1] === '2.4' && x.s.sdn + x.s.sup >= best.s.sdn + best.s.sup)) best = x;
		});
		node.bh = b; node.online = node.bhRows.length > 0;
		if (best) { node.bhBand = best.r[1]; node.bhRssi = best.r[5]; node.bhPhy = best.r[6]; }
		/* a node on a wired backhaul: its address on a LAN port */
		(d.macs || []).forEach(function (pm) {
			if (pm[1] === node.mac || node.sta.indexOf(pm[1]) >= 0) {
				var pr = ifs[pm[0]];
				if (pr) { node.bh = measure('pb:' + pm[0], t, pr[2], pr[1]); node.online = true; node.wiredPort = pm[0]; }
			}
		});
		if (!node.online && node.state === 'ok') node.online = true;
		/* its clients, counted on the node itself */
		var nt = parseFloat(node.nup);
		if (node.state === 'ok') {
			node.rows.forEach(function (r) {
				var mac = r[2];
				if (own[mac] || bh[mac] || mac === node.mac) return;
				var s = measure('n:' + node.mac + ':' + mac, nt, r[3], r[4]);
				var cand = { ap: node.mac, node: node, ifn: r[0], band: r[1], mac: mac, rssi: r[5], phy: r[6], conn: r[8], s: s, st: 'ok' };
				var o = seen[mac];   /* roaming: the newer association wins */
				if (!o || (+cand.conn < +o.conn)) seen[mac] = cand;
			});
		} else if (A.names && A.names.cl[node.mac]) {   /* not readable: list its clients without numbers */
			var cl = A.names.cl[node.mac];
			[['2G', '2.4'], ['5G', '5'], ['5G1', '5'], ['6G', '6']].forEach(function (bk) {
				Object.keys(cl[bk[0]] || {}).forEach(function (m) {
					m = m.toUpperCase();
					if (seen[m] || own[m] || bh[m]) return;
					seen[m] = { ap: node.mac, node: node, band: bk[1], mac: m, rssi: +((cl[bk[0]][m] || {}).rssi) || null, phy: null, s: { dn: 0, up: 0, sdn: 0, sup: 0, ok: false }, st: node.online ? 'nodata' : 'off' };
				});
			});
		}
	});
	/* wired: what the bridge has learned on each port */
	var onPort = {};
	(d.macs || []).forEach(function (pm) {
		if (seen[pm[1]] || own[pm[1]] || bh[pm[1]]) return;
		if (net.nodes.some(function (n) { return n.mac === pm[1] || n.wiredPort === pm[0]; })) return;
		(onPort[pm[0]] = onPort[pm[0]] || []).push(pm[1]);
	});
	(d.ports || []).forEach(function (p) {
		var lk = linkOf(d, p), list = onPort[p] || [], pr = ifs[p];
		if (!lk.up || net.nodes.some(function (n) { return n.wiredPort === p; })) return;
		var s = pr ? measure('p:' + p, t, pr[2], pr[1]) : smooth('p:' + p, null);
		var dev = { link: 'wired', port: p, portLabel: portLabel(d, p), speed: lk.speed, s: s, st: 'ok', ap: 'router' };
		if (list.length === 1) { dev.id = list[0]; dev.mac = list[0]; }
		else { dev.id = 'port:' + p; dev.count = list.length; dev.kind = list.length > 1 ? 'switch' : 'generic'; dev.name = list.length > 1 ? 'Switch on ' + dev.portLabel : 'Device on ' + dev.portLabel; }
		net.devs.push(dev);
	});
	Object.keys(seen).forEach(function (mac) {
		var x = seen[mac];
		net.devs.push({ id: mac, mac: mac, link: 'wifi', ap: x.ap, node: x.node || null, ifn: x.ifn, band: x.band, guest: !!(x.ifn && x.ifn.indexOf('.') > 0 && x.ap === 'router'),
			rssi: x.rssi, phy: x.phy, s: x.s, st: x.st });
	});
	net.devs.forEach(function (dv) {
		if (!dv.name) dv.name = nameOf(dv.mac);
		if (!dv.kind) dv.kind = kindOf(dv.mac, dv.name);
		dv.dn = dv.s.dn; dv.up = dv.s.up; dv.sdn = dv.s.sdn; dv.sup = dv.s.sup;
		net.byId[dv.id] = dv;
		if (dv.node) dv.node.devs.push(dv);
	});
	/* totals: everything the router delivered = its own clients + the nodes' backhaul */
	var tot = { dn: 0, up: 0, sdn: 0, sup: 0 };
	net.devs.forEach(function (dv) { if (!dv.node && dv.st === 'ok') { tot.dn += dv.dn; tot.up += dv.up; tot.sdn += dv.sdn; tot.sup += dv.sup; } });
	net.nodes.forEach(function (n) {
		tot.dn += n.bh.dn; tot.up += n.bh.up; tot.sdn += n.bh.sdn; tot.sup += n.bh.sup;
		var r = n.bhRssi, p = n.bhPhy;
		n.weak = n.online && !n.wiredPort && ((r !== null && r !== undefined && r < -72) || (p > 0 && p < 200));
		n.devs.sort(byName);
		if (n.state === 'ok') {   /* what the node's clients add up to, vs the backhaul */
			n.sum = n.devs.reduce(function (a, dv) { return a + dv.dn + dv.up; }, 0);
		}
	});
	net.total = tot;
	net.local = { dn: Math.max(0, Math.min(tot.dn - net.wan.dn, tot.dn)), up: Math.max(0, Math.min(tot.up - net.wan.up, tot.up)),
		sdn: Math.max(0, tot.sdn - net.wan.sdn), sup: Math.max(0, tot.sup - net.wan.sup) };
	net.clients = net.devs.filter(function (dv) { return dv.st !== 'off'; }).reduce(function (a, dv) { return a + (dv.count > 1 ? dv.count : 1); }, 0);
	net.byId.wan = { id: 'wan' }; net.byId.router = { id: 'router' };
	net.nodes.forEach(function (n) { net.byId[n.id] = n; });
	return net;
}
function byName(a, b) { return a.name.toLowerCase() < b.name.toLowerCase() ? -1 : (a.name.toLowerCase() > b.name.toLowerCase() ? 1 : 0); }
function busy(x) { return (x.sdn || 0) + (x.sup || 0); }

/* ---------------------------------------------------------------- one sample arrived */
function onSample(d) {
	var nowMs = Date.now();
	if (d && d.v === 1 && (d.seq !== A.seq || d.up !== A.up)) {
		var first = A.seq === null;
		A.seq = d.seq; A.up = d.up;
		if (d.interval > 0) A.interval = d.interval;
		A.net = buildNet(d);
		if (!first) { A.fresh = nowMs; A.gotAny = true; }
		var w = A.net.wan;
		A.hist.push({ dn: w.dn, up: w.up });
		if (A.hist.length > Math.round(120 / A.interval)) A.hist.shift();
	}
	/* the router hasn't answered the first requests: try the classic form once */
	if (!A.fresh && !A.useForm && nowMs - A.started > 12000) { A.useForm = true; poke('start_arteria'); }
	setLive();
	render();
}
function stale() { return !A.fresh || Date.now() - A.fresh > (A.interval * 3 + 4) * 1000; }

/* ---------------------------------------------------------------- the isometric map */
var U = 24, OX = 322, OY = 96, CC = Math.cos(Math.PI / 6), FX = 18, FY = 14, SW = 728, SH = 518;
function P(X, Y, Z) { return [OX + (X - Y) * CC * U, OY + (X + Y) * 0.5 * U - (Z || 0) * U]; }
function ptsS(ps) { return ps.map(function (p) { return n1(p[0]) + ',' + n1(p[1]); }).join(' '); }
function poly(ps, st) { return '<polygon points="' + ptsS(ps) + '" style="' + st + '"/>'; }
function pline(ps, st, dy) { return '<path d="M' + ps.map(function (p) { return n1(p[0]) + ' ' + n1(p[1] + (dy || 0)); }).join(' L') + '" style="' + st + '"/>'; }
function ell(c, r, st, cls) { return '<ellipse cx="' + n1(c[0]) + '" cy="' + n1(c[1]) + '" rx="' + n1(1.2247 * r * U) + '" ry="' + n1(0.7071 * r * U) + '"' + (cls ? ' class="' + cls + '"' : '') + ' style="' + st + '"/>'; }
/* Four tones from one base colour: top, left (lit), right (shade), deep; plus edge and rim. Light comes from the upper left. */
function MAT(base, light) {
	var dark = '#0b1012';
	return { t: mix(base, light ? 0.34 : 0.2), l: base, r: mix(base, light ? 0.26 : 0.32, dark), d: mix(base, 0.6, dark), e: mix(base, light ? 0.5 : 0.74, dark),
		hi: 'rgba(255,255,255,' + (light ? '.85' : '.3') + ')', hi2: 'rgba(255,255,255,' + (light ? '.4' : '.12') + ')' };
}
var M_BODY = MAT('#48555b'), M_DARK = MAT('#2c363a'), M_BLACK = MAT('#1d2427'), M_WHITE = MAT('#d3dadc', true), M_ALU = MAT('#b4bdc1', true),
	M_METAL = MAT('#7d8b91'), M_WALL = MAT('#3b484e'), M_TABLE = MAT('#66757c');

function Obj(id, cx, cy, top) { this.id = id; this.cx = cx; this.cy = cy; this.depth = cx + cy; this.svg = []; this.pts = []; this.anchor = P(cx, cy, top); this.shadow = []; this.target = P(cx, cy, top); }
Obj.prototype.box = function (X, Y, Z, dx, dy, dz, m, o) {
	o = o || {};
	var T = [P(X, Y, Z + dz), P(X + dx, Y, Z + dz), P(X + dx, Y + dy, Z + dz), P(X, Y + dy, Z + dz)];
	var L = [P(X, Y + dy, Z), P(X + dx, Y + dy, Z), P(X + dx, Y + dy, Z + dz), P(X, Y + dy, Z + dz)];
	var R = [P(X + dx, Y, Z), P(X + dx, Y + dy, Z), P(X + dx, Y + dy, Z + dz), P(X + dx, Y, Z + dz)];
	var st = ';stroke:' + m.e + ';stroke-width:.7;stroke-linejoin:round';
	this.svg.push(poly(L, 'fill:' + m.l + st), poly(R, 'fill:' + m.r + st), poly(T, 'fill:' + m.t + st));
	this.last = [X, Y, Z, dx, dy, dz];
	if (o.ao) { var a = Math.min(0.09, dz * 0.3) / dz; this.face('L', 0, 0, 1, a, 'fill:' + m.d + ';opacity:.55'); this.face('R', 0, 0, 1, a, 'fill:' + m.d + ';opacity:.55'); }
	if (o.rim !== false) {
		this.svg.push(pline([P(X, Y + dy, Z + dz), P(X + dx, Y + dy, Z + dz)], 'fill:none;stroke:' + m.hi + ';stroke-width:1;stroke-linecap:round'));
		this.svg.push(pline([P(X + dx, Y + dy, Z + dz), P(X + dx, Y, Z + dz)], 'fill:none;stroke:' + m.hi2 + ';stroke-width:1;stroke-linecap:round'));
		if (dz * U > 9) this.svg.push(pline([P(X + dx, Y + dy, Z + dz), P(X + dx, Y + dy, Z)], 'fill:none;stroke:' + m.hi2 + ';stroke-width:.8;stroke-linecap:round'));
	}
	if (o.track !== false) this.pts = this.pts.concat(T, L, R);
	if (o.shadow) { var h = Math.min(Z + dz, 1.7); this.shadow.push([X, Y, dx, dy, 0.45 * h + 0.1, -0.2 * h - 0.04]); }
	return this;
};
Obj.prototype.fp = function (w, u, v, b) {
	b = b || this.last;
	var X = b[0], Y = b[1], Z = b[2], dx = b[3], dy = b[4], dz = b[5];
	if (w === 'L') return P(X + u * dx, Y + dy, Z + v * dz);
	if (w === 'R') return P(X + dx, Y + u * dy, Z + v * dz);
	return P(X + u * dx, Y + v * dy, Z + dz);
};
Obj.prototype.face = function (w, u0, v0, u1, v1, st, b) { this.svg.push(poly([this.fp(w, u0, v0, b), this.fp(w, u1, v0, b), this.fp(w, u1, v1, b), this.fp(w, u0, v1, b)], st)); return this; };
Obj.prototype.line = function (w, u0, v0, u1, v1, c, sw, b) { this.svg.push(pline([this.fp(w, u0, v0, b), this.fp(w, u1, v1, b)], 'fill:none;stroke:' + c + ';stroke-width:' + (sw || 1.2) + ';stroke-linecap:round')); return this; };
Obj.prototype.led = function (w, u, v, c, dur, delay, r, b) {
	var p = this.fp(w, u, v, b); r = r || 1.5;
	this.svg.push('<circle cx="' + n1(p[0]) + '" cy="' + n1(p[1]) + '" r="' + n1(r * 2.1) + '" style="fill:' + c + ';opacity:.28"/>');
	this.svg.push('<circle cx="' + n1(p[0]) + '" cy="' + n1(p[1]) + '" r="' + n1(r) + '"' + (dur ? ' class="df-a df-led"' : '') + ' style="fill:' + c + (dur ? ';animation-duration:' + dur + 's;animation-delay:' + (delay || 0) + 's' : '') + '"/>');
	return this;
};
Obj.prototype.collar = function (X, Y, dx, dy) { this.box(X, Y, 0, dx, dy, 0.3, M_METAL, { track: false }); this.face('T', 0.2, 0.2, 0.8, 0.8, 'fill:#11181b'); return this; };
Obj.prototype.screen = function (w, grad, tiles) {
	this.face(w, 0.035, 0.07, 0.965, 0.93, 'fill:url(#' + grad + ')');
	if (tiles) {
		for (var i = 0; i < 4; i++) { var u = 0.09 + i * 0.21; this.face(w, u, 0.14, u + 0.17, 0.36, 'fill:#ffffff;opacity:.2'); }
		this.face(w, 0.09, 0.48, 0.52, 0.82, 'fill:#ffffff;opacity:.13');
	}
	var a = w === 'L' ? 0.035 : 0.4, b = w === 'L' ? 0.6 : 0.965;
	this.svg.push(poly([this.fp(w, a, 0.93), this.fp(w, b, 0.93), this.fp(w, w === 'L' ? a : b, 0.5)], 'fill:#ffffff;opacity:.09'));
	return this;
};
Obj.prototype.bbox = function () {
	var xs = this.pts.map(function (p) { return p[0]; }), ys = this.pts.map(function (p) { return p[1]; });
	return [Math.min.apply(null, xs), Math.min.apply(null, ys), Math.max.apply(null, xs), Math.max.apply(null, ys)];
};

/* The fixed parts: the internet terminal and the router. */
function objWan() {
	var o = new Obj('wan', 1.675, 1.675, 2.45);
	o.box(1.15, 1.15, 0, 1.05, 1.05, 0.5, M_BODY, { ao: true, shadow: true });
	o.line('L', 0.15, 0.5, 0.85, 0.5, DN, 1.4);
	o.led('L', 0.5, 0.22, '#3ddc97', 1.9, 0, 1.3);
	o.box(1.33, 1.33, 0.5, 0.69, 0.69, 0.16, M_DARK);
	var c0 = P(1.675, 1.675, 0.66), g = P(1.675, 1.675, 1.72);
	o.svg.push(ell(c0, 0.24, 'fill:' + DN), ell(c0, 0.24, 'fill:none;stroke:' + DN + ';stroke-width:1.4', 'df-a df-ripple'));
	o.svg.push(poly([[c0[0] - 6.5, c0[1]], [c0[0] + 6.5, c0[1]], [g[0] + 15, g[1] + 4], [g[0] - 15, g[1] + 4]], 'fill:url(#ar-beam)'));
	o.svg.push('<circle cx="' + n1(g[0]) + '" cy="' + n1(g[1]) + '" r="25" style="fill:url(#ar-halo)"/>');
	o.svg.push('<circle cx="' + n1(g[0]) + '" cy="' + n1(g[1]) + '" r="15" style="fill:url(#ar-globe);stroke:#bfe8ff;stroke-width:1.1"/>');
	o.svg.push('<path d="M' + n1(g[0] - 15) + ' ' + n1(g[1]) + ' h30 M' + n1(g[0] - 13) + ' ' + n1(g[1] - 7.5) + ' a15 6.5 0 0 0 26 0 M' + n1(g[0] - 13) + ' ' + n1(g[1] + 7.5) + ' a15 6.5 0 0 1 26 0" style="fill:none;stroke:rgba(225,245,255,.6);stroke-width:.9"/>');
	o.svg.push('<ellipse cx="' + n1(g[0]) + '" cy="' + n1(g[1]) + '" rx="6.5" ry="15" style="fill:none;stroke:rgba(225,245,255,.6);stroke-width:.9"/>');
	o.pts.push([g[0] - 16, g[1] - 16], [g[0] + 16, g[1] + 16]);
	o.collar(2.2, 1.5, 0.2, 0.35);
	return o;
}
function objRouter() {
	var o = new Obj('router', 7.1, 7.1, 2.0);
	o.box(5.42, 5.82, 0, 3.36, 2.56, 0.07, M_BLACK, { rim: false, shadow: true });
	o.box(5.5, 5.9, 0.07, 3.2, 2.4, 0.57, M_BODY, { ao: true, shadow: true });
	var body = o.last;
	o.face('T', 0.035, 0.05, 0.965, 0.95, 'fill:' + mix('#48555b', 0.27) + ';stroke:' + mix('#48555b', 0.05) + ';stroke-width:.7');
	[0.2, 0.31, 0.42, 0.53, 0.64].forEach(function (v) { o.line('T', 0.09, v, 0.5, v, '#2b3438', 1.5); o.line('T', 0.09, v + 0.035, 0.5, v + 0.035, 'rgba(255,255,255,.16)', 0.7); });
	o.face('T', 0.6, 0.22, 0.9, 0.62, 'fill:' + mix('#48555b', 0.12) + ';stroke:#2b3438;stroke-width:.6');
	o.line('T', 0.62, 0.9, 0.93, 0.9, ACC, 1.8);
	o.face('L', 0.5, 0.3, 0.95, 0.7, 'fill:#141b1e;stroke:#0d1214;stroke-width:.6');
	[['#3ddc97', 1.7], ['#3ddc97', 1.1], [DN, 0.7], [DN, 0.9], [ACC, 2.3]].forEach(function (c, i) { o.led('L', 0.56 + i * 0.082, 0.5, c[0], c[1], -0.3 * i, 1.3, body); });
	o.line('L', 0.06, 0.5, 0.4, 0.5, 'rgba(255,255,255,.14)', 0.8);
	for (var i = 0; i < 5; i++) { var u = 0.1 + i * 0.165; o.face('R', u, 0.26, u + 0.11, 0.68, 'fill:#11181b;stroke:' + (i === 0 ? DN : '#c9a400') + ';stroke-width:.9', body); }
	[5.62, 6.52, 7.42, 8.32].forEach(function (ax) {
		o.box(ax - 0.04, 5.92, 0.64, 0.24, 0.24, 0.14, M_BLACK, { rim: false, track: false });
		o.box(ax, 5.96, 0.78, 0.15, 0.15, 1.22, M_DARK);
		o.face('L', 0, 0.9, 1, 1, 'fill:' + ACC + ';opacity:.8');
	});
	o.collar(6.12, 8.3, 0.36, 0.2);
	o.collar(7.82, 8.3, 0.36, 0.2);
	return o;
}
function objNode(id, cx, cy) {
	var o = new Obj(id, cx, cy, 1.86);
	o.box(cx - 0.7, cy - 0.7, 0, 1.4, 1.4, 0.07, M_METAL, { rim: false, shadow: true });
	o.box(cx - 0.6, cy - 0.6, 0.07, 1.2, 1.2, 1.72, M_WHITE, { ao: true, shadow: true });
	[0.5, 0.57, 0.64, 0.71].forEach(function (v) { o.line('L', 0.24, v, 0.76, v, '#8f9a9e', 1.2); });
	o.face('L', 0.3, 0.16, 0.7, 0.3, 'fill:#aab4b8;stroke:#8f9a9e;stroke-width:.6');
	[0.5, 0.57, 0.64, 0.71].forEach(function (v) { o.line('R', 0.24, v, 0.76, v, '#7f8a8e', 1.1); });
	var c = P(cx, cy, 1.79);
	o.svg.push(ell(c, 0.36, 'fill:#bcc5c8;stroke:#8f9a9e;stroke-width:.7'));
	o.svg.push('<g data-ring="' + id + ':lit">' + ell(c, 0.25, 'fill:' + MESH + ';stroke:#d6cffc;stroke-width:.9') + '</g>');
	o.svg.push('<g data-ring="' + id + ':dead" class="hide">' + ell(c, 0.25, 'fill:#5a6569;stroke:' + BAD + ';stroke-width:1.2') + '</g>');
	o.hub = P(cx, cy, 2.12);
	return o;
}
/* Clients: one generic form per kind, built around the slot's centre. */
function objDevice(id, kind, cx, cy, face) {
	var o, b;
	if (kind === 'tv' && face === 'R') {
		o = new Obj(id, cx, cy, 1.92);
		o.box(cx - 0.4, cy - 0.5, 0, 0.5, 1.0, 0.08, M_DARK, { shadow: true });
		o.box(cx - 0.18, cy - 0.08, 0.08, 0.12, 0.16, 0.36, M_BLACK, { rim: false });
		o.box(cx - 0.06, cy - 1.35, 0.42, 0.12, 2.7, 1.5, M_BLACK, { shadow: true });
		o.screen('R', 'ar-scr2', true);
		o.target = P(cx, cy, 1.96);
	} else if (kind === 'tv') {
		o = new Obj(id, cx, cy, 1.97);
		o.box(cx - 0.5, cy - 0.25, 0, 1.0, 0.5, 0.08, M_DARK, { shadow: true });
		o.box(cx - 0.08, cy - 0.16, 0.08, 0.16, 0.12, 0.36, M_BLACK, { rim: false });
		o.box(cx - 1.4, cy - 0.06, 0.42, 2.8, 0.12, 1.55, M_BLACK, { shadow: true });
		o.screen('L', 'ar-scr1', true);
		o.led('L', 0.5, 0.035, BAD, 0, 0, 0.9);
		o.target = P(cx, cy, 1.99);
	} else if (kind === 'laptop') {
		o = new Obj(id, cx, cy, 1.07);
		o.box(cx - 0.8, cy - 0.52, 0.07, 1.6, 0.07, 1.0, M_BLACK, { shadow: true });
		o.screen('L', 'ar-scr3', false);
		o.face('L', 0.1, 0.5, 0.6, 0.84, 'fill:#ffffff;opacity:.16');
		o.face('L', 0.66, 0.3, 0.9, 0.84, 'fill:#ffffff;opacity:.1');
		o.box(cx - 0.8, cy - 0.45, 0, 1.6, 1.05, 0.07, M_ALU, { shadow: true });
		o.face('T', 0.07, 0.1, 0.93, 0.58, 'fill:#59646a');
		[0.22, 0.34, 0.46].forEach(function (v) { o.line('T', 0.09, v, 0.91, v, '#8b969b', 0.7); });
		o.face('T', 0.36, 0.66, 0.64, 0.93, 'fill:#c9d0d3;stroke:#8f999e;stroke-width:.5');
		o.target = P(cx, cy - 0.49, 1.14);
	} else if (kind === 'phone') {
		o = new Obj(id, cx, cy, 1.0);
		o.box(cx - 0.35, cy - 0.18, 0, 0.7, 0.42, 0.07, M_DARK, { shadow: true });
		o.box(cx - 0.25, cy - 0.05, 0.07, 0.5, 0.1, 0.95, M_BLACK);
		o.face('L', 0.09, 0.04, 0.91, 0.96, 'fill:url(#ar-scr4)');
		o.face('L', 0.36, 0.9, 0.64, 0.93, 'fill:#0d1214');
		o.face('L', 0.18, 0.5, 0.82, 0.62, 'fill:#ffffff;opacity:.2');
		o.target = P(cx, cy, 1.07);
	} else if (kind === 'tablet') {
		o = new Obj(id, cx, cy, 0.6);
		[[cx - 0.6, cy + 0.45], [cx + 0.48, cy + 0.45], [cx + 0.48, cy - 0.55]].forEach(function (l) { o.box(l[0], l[1], 0, 0.12, 0.12, 0.45, M_DARK, { rim: false }); });
		o.box(cx - 0.65, cy - 0.6, 0.45, 1.3, 1.2, 0.09, M_TABLE, { shadow: true });
		o.box(cx - 0.45, cy - 0.4, 0.54, 0.9, 0.75, 0.05, M_BLACK);
		o.face('T', 0.06, 0.07, 0.94, 0.93, 'fill:url(#ar-scr5)');
		o.face('T', 0.14, 0.18, 0.5, 0.5, 'fill:#ffffff;opacity:.16');
		o.target = P(cx, cy, 0.64);
	} else if (kind === 'nas') {
		o = new Obj(id, cx, cy, 2.0);
		o.box(cx - 0.9, cy - 0.8, 0, 1.8, 1.6, 0.07, M_BLACK, { rim: false, shadow: true });
		o.box(cx - 0.85, cy - 0.75, 0.07, 1.7, 1.5, 1.93, M_BODY, { ao: true, shadow: true });
		[[0.08, 0.47], [0.53, 0.92]].forEach(function (u) {
			o.face('L', u[0], 0.1, u[1], 0.76, 'fill:#20282b;stroke:#141a1d;stroke-width:.8');
			o.line('L', u[0] + 0.06, 0.68, u[1] - 0.06, 0.68, '#5f6d73', 1.6);
			o.line('L', u[0] + 0.06, 0.2, u[1] - 0.06, 0.2, 'rgba(255,255,255,.1)', 0.8);
		});
		o.led('L', 0.16, 0.87, '#3ddc97', 0.42, 0);
		o.led('L', 0.28, 0.87, '#3ddc97', 0.31, -0.1);
		o.led('L', 0.88, 0.87, DN, 0, 0, 1.3);
		[0.3, 0.38, 0.46, 0.54, 0.62].forEach(function (v) { o.line('R', 0.2, v, 0.8, v, '#1f2629', 1.3); });
		o.target = P(cx, cy, 2.05);
	} else if (kind === 'iot') {
		o = new Obj(id, cx, cy, 0.42);
		o.box(cx - 0.21, cy - 0.21, 0, 0.42, 0.42, 0.42, M_WHITE, { shadow: true });
		o.face('T', 0.3, 0.3, 0.7, 0.7, 'fill:#aeb8bb');
		o.led('L', 0.5, 0.55, ACC, 2.6 + (hash(id) % 10) / 4, -(hash(id) % 7) / 3, 1.2);
		o.target = P(cx, cy, 0.5);
	} else if (kind === 'switch') {
		o = new Obj(id, cx, cy, 0.3);
		o.box(cx - 0.8, cy - 0.4, 0, 1.6, 0.8, 0.24, M_BODY, { shadow: true });
		b = o.last;
		for (var i = 0; i < 5; i++) { var u = 0.1 + i * 0.165; o.face('L', u, 0.22, u + 0.11, 0.7, 'fill:#11181b;stroke:#c9a400;stroke-width:.7', b); o.led('L', u + 0.055, 0.86, '#3ddc97', i % 2 ? 0.8 : 0, -i * 0.2, 0.8, b); }
		o.target = P(cx, cy, 0.3);
	} else if (kind === 'console') {
		o = new Obj(id, cx, cy, 0.3);
		o.box(cx - 0.6, cy - 0.42, 0, 1.2, 0.84, 0.24, M_BLACK, { shadow: true });
		o.line('L', 0.08, 0.5, 0.92, 0.5, DN, 1.2);
		o.face('T', 0.1, 0.12, 0.9, 0.88, 'fill:none;stroke:rgba(255,255,255,.14);stroke-width:.8');
		o.target = P(cx, cy, 0.32);
	} else {
		o = new Obj(id, cx, cy, 0.45);
		o.box(cx - 0.45, cy - 0.35, 0, 0.9, 0.7, 0.4, M_DARK, { ao: true, shadow: true });
		o.face('T', 0.15, 0.18, 0.85, 0.82, 'fill:none;stroke:rgba(255,255,255,.14);stroke-width:.8');
		o.led('L', 0.24, 0.6, '#3ddc97', 1.9 + (hash(id) % 10) / 5, 0, 1.1);
		o.line('L', 0.4, 0.6, 0.85, 0.6, 'rgba(255,255,255,.18)', 1.2);
		o.target = P(cx, cy, 0.46);
	}
	return o;
}
function objTray(cx, cy) {
	var o = new Obj('more', cx, cy, 0.36);
	o.box(cx - 0.9, cy - 0.7, 0, 1.8, 1.4, 0.1, M_DARK, { shadow: true });
	var toks = [];
	for (var i = 0; i < 3; i++) for (var j = 0; j < 2; j++) toks.push([cx - 0.72 + i * 0.5, cy - 0.52 + j * 0.56, (i + j) % 2]);
	toks.sort(function (a, b) { return a[0] + a[1] - b[0] - b[1]; });
	toks.forEach(function (t) { o.box(t[0], t[1], 0.1, 0.34, 0.34, 0.2, t[2] ? M_WHITE : M_METAL); });
	o.target = P(cx, cy, 0.38);
	return o;
}

/* Where things go. The router sits in the middle; up to two AiMesh nodes get a zone of their own,
   each with stands for its busiest clients; the router's busiest Wi-Fi and wired clients get stands
   around it; everything else goes on the "+N more" tray. Stands are sticky, so devices don't jump. */
var NODE_SLOTS = [
	{ cx: 11.55, cy: 0.95, zone: [10.4, 0, FX, 6.4], text: [10.7, 6.05], dev: [{ cx: 16.98, cy: 1.9, face: 'R' }, { cx: 16.4, cy: 4.45 }, { cx: 13.9, cy: 4.75 }] },
	{ cx: 1.3, cy: 9.6, zone: [0, 8.3, 5.3, FY], text: [0.35, 13.6], dev: [{ cx: 3.55, cy: 12.55 }, { cx: 1.35, cy: 12.55 }, { cx: 3.9, cy: 9.8 }] }
];
var WIFI_SLOTS = [{ cx: 14.4, cy: 10.6 }, { cx: 16.6, cy: 7.4 }, { cx: 12.4, cy: 12.75 }, { cx: 10.9, cy: 9.9 }];
var WIRED_SLOTS = [
	{ cx: 8.25, cy: 13.18, route: [[8.0, 8.35], [8.0, 13.1]] },
	{ cx: 3.17, cy: 11.83, route: [[6.3, 8.35], [6.3, 11.83], [4.1, 11.83]], needsNoNodeB: true }
];
var TRAY = { cx: 1.7, cy: 5.3 };

function pickStands(list, n, prevKey) {   /* the n busiest, keeping devices that already have a stand unless something is 3x busier */
	var cur = list.filter(function (dv) { return A.slot[dv.id] && A.slot[dv.id].g === prevKey; });
	var score = function (dv) { return busy(dv) * (A.slot[dv.id] && A.slot[dv.id].g === prevKey ? 3 : 1) + (dv.st === 'ok' ? 1e-6 : 0); };
	var ranked = list.slice().sort(function (a, b) { return score(b) - score(a) || byName(a, b); });
	var keep = ranked.slice(0, n);
	if (cur.length && Date.now() - A.slotAt < 20000) {   /* hold the stands for 20 s unless devices joined or left */
		var same = cur.every(function (dv) { return list.indexOf(dv) >= 0; });
		if (same && cur.length >= Math.min(n, list.length)) keep = cur.slice(0, n);
	}
	return keep;
}
function mapLayout(net) {
	var L = { nodes: [], devs: [], tray: [], wired: [] };
	var shownNodes = net.nodes.slice(0, NODE_SLOTS.length);
	shownNodes.forEach(function (n, i) { L.nodes.push({ node: n, slot: NODE_SLOTS[i] }); });
	var visible = net.devs.filter(function (dv) { return dv.st !== 'off'; });
	var nodeB = shownNodes.length > 1;
	/* wired */
	var wslots = WIRED_SLOTS.filter(function (s) { return !(s.needsNoNodeB && nodeB); });
	var wired = visible.filter(function (dv) { return dv.link === 'wired'; });
	var wk = pickStands(wired, wslots.length, 'w');
	/* the router's Wi-Fi clients */
	var direct = visible.filter(function (dv) { return dv.link === 'wifi' && !dv.node; });
	var dk = pickStands(direct, WIFI_SLOTS.length, 'r');
	/* each node's clients */
	var nk = {};
	shownNodes.forEach(function (n, i) { nk[n.mac] = pickStands(visible.filter(function (dv) { return dv.node === n; }), NODE_SLOTS[i].dev.length, 'n' + i); });
	var used = {}, next = {};
	var place = function (dv, g, slots) {
		var prev = A.slot[dv.id], idx = prev && prev.g === g && !used[g + prev.i] && prev.i < slots.length ? prev.i : -1;
		if (idx < 0) for (var i = 0; i < slots.length; i++) if (!used[g + i]) { idx = i; break; }
		used[g + idx] = 1;
		next[dv.id] = { g: g, i: idx };
		return slots[idx];
	};
	/* devices that keep their stand first, then the newcomers */
	var put = function (list, g, slots, into) {
		list.slice().sort(function (a, b) { return (A.slot[b.id] && A.slot[b.id].g === g ? 1 : 0) - (A.slot[a.id] && A.slot[a.id].g === g ? 1 : 0); })
			.forEach(function (dv) { into.push({ dev: dv, slot: place(dv, g, slots), group: g }); });
	};
	put(wk, 'w', wslots, L.wired);
	put(dk, 'r', WIFI_SLOTS, L.devs);
	shownNodes.forEach(function (n, i) { put(nk[n.mac], 'n' + i, NODE_SLOTS[i].dev, L.devs); });
	var stood = {};
	L.wired.concat(L.devs).forEach(function (x) { stood[x.dev.id] = 1; });
	L.tray = visible.filter(function (dv) { return !stood[dv.id]; });
	A.slot = A.gotAny ? next : {};   /* before the first rates every device looks idle: pick again once they're known */
	return L;
}
function mapSignature(L) {
	return JSON.stringify([L.nodes.map(function (x) { return x.node.mac; }), L.wired.concat(L.devs).map(function (x) { return [x.dev.id, x.group, x.slot.cx, x.dev.kind]; }), L.tray.length > 0]);
}

/* lanes: one direction of one link, a soft halo plus a bright capsule riding the same dash pattern */
function lane(d, color, glow, key, tube) {
	var dl = -(hash(key) % 100) / 100 * 2, t = tube ? ' t' : '';
	return '<path d="' + d + '" data-lane="' + key + '" data-cls="df-a pk h' + t + '" class="df-a pk h' + t + ' bx" style="fill:none;stroke:' + glow + ';stroke-opacity:.3;stroke-linecap:round;animation-delay:' + dl.toFixed(2) + 's"/>' +
		'<path d="' + d + '" data-lane="' + key + '" data-cls="df-a pk' + t + '" class="df-a pk' + t + ' bx" style="fill:none;stroke:' + color + ';stroke-linecap:round;animation-delay:' + dl.toFixed(2) + 's"/>';
}
function qd(p0, c, p1) { return 'M' + n1(p0[0]) + ' ' + n1(p0[1]) + ' Q' + n1(c[0]) + ' ' + n1(c[1]) + ' ' + n1(p1[0]) + ' ' + n1(p1[1]); }
function offQ(p0, c, p1, o) {
	var dx = p1[0] - p0[0], dy = p1[1] - p0[1], L = Math.sqrt(dx * dx + dy * dy) || 1, rx = -dy / L * o, ry = dx / L * o;
	return [[p0[0] + rx, p0[1] + ry], [c[0] + rx, c[1] + ry], [p1[0] + rx, p1[1] + ry]];
}
function offPoly(pts, o) {
	var nrm = function (a, b) { var dx = b[0] - a[0], dy = b[1] - a[1], L = Math.sqrt(dx * dx + dy * dy) || 1; return [-dy / L, dx / L]; };
	return pts.map(function (p, i) {
		var v;
		if (i === 0) v = nrm(pts[0], pts[1]);
		else if (i === pts.length - 1) v = nrm(pts[i - 1], pts[i]);
		else { var a = nrm(pts[i - 1], p), b = nrm(p, pts[i + 1]), k = 1 + a[0] * b[0] + a[1] * b[1]; v = [(a[0] + b[0]) / k, (a[1] + b[1]) / k]; }
		return [p[0] + v[0] * o, p[1] + v[1] * o];
	});
}
function arcCtrl(p0, p1, bulge) {
	var mx = (p0[0] + p1[0]) / 2, my = (p0[1] + p1[1]) / 2, dx = p1[0] - p0[0], dy = p1[1] - p0[1], L = Math.sqrt(dx * dx + dy * dy) || 1;
	var nx = -dy / L, ny = dx / L;
	if (ny > 0) { nx = -nx; ny = -ny; }
	var h = bulge * L + 16;
	return [mx + nx * h, my + ny * h];
}
function tube(id, world) {
	var sp = world.map(function (w) { return P(w[0], w[1], 0.1); });
	var j = ';stroke-linecap:round;stroke-linejoin:round';
	var dl = function (ps, dx, dy) { return 'M' + ps.map(function (p) { return n1(p[0] + (dx || 0)) + ' ' + n1(p[1] + (dy || 0)); }).join(' L'); };
	var dn = offPoly(world, 0.085).map(function (w) { return P(w[0], w[1], 0.1); });
	var up = offPoly(world.slice().reverse(), 0.085).map(function (w) { return P(w[0], w[1], 0.1); });
	return '<g data-link="' + id + '" class="lk">' +
		'<path d="' + dl(sp, 2.5, 3.5) + '" style="fill:none;stroke:#000000;stroke-opacity:.22;stroke-width:13' + j + '"/>' +
		'<path d="' + dl(sp) + '" style="fill:none;stroke:#0e1417;stroke-width:14' + j + '"/>' +
		'<path d="' + dl(sp) + '" style="fill:none;stroke:#33424a;stroke-width:11.5' + j + '"/>' +
		'<path d="' + dl(sp) + '" style="fill:none;stroke:#141c20;stroke-width:8' + j + '"/>' +
		'<path d="' + dl(sp, 0, -4.4) + '" style="fill:none;stroke:rgba(255,255,255,.3);stroke-width:1' + j + '"/>' +
		lane(dl(dn), DNT, DN, id + '|dn', true) + lane(dl(up), UPT, UP, id + '|up', true) + '</g>';
}
function arc(id, p0, p1, bulge, mesh) {
	var c = arcCtrl(p0, p1, bulge), d = qd(p0, c, p1);
	var track = mesh ? 'stroke:' + MESH + ';stroke-opacity:.3;stroke-width:11' : 'stroke:#ffffff;stroke-opacity:.07;stroke-width:9';
	var a = offQ(p0, c, p1, 3.0), b = offQ(p1, c, p0, 3.0);
	var pts = [];
	for (var i = 0; i <= 40; i++) { var t = i / 40; pts.push([(1 - t) * (1 - t) * p0[0] + 2 * t * (1 - t) * c[0] + t * t * p1[0], (1 - t) * (1 - t) * p0[1] + 2 * t * (1 - t) * c[1] + t * t * p1[1]]); }
	return { pts: pts, mid: pts[20], svg: '<g data-link="' + id + '" class="lk">' +
		'<path d="' + d + '" style="fill:none;' + track + ';stroke-linecap:round"/>' +
		'<path d="' + d + '" style="fill:none;stroke:rgba(255,255,255,.16);stroke-width:1;stroke-linecap:round"/>' +
		'<path d="' + d + '" data-alt="' + id + '" class="hide" style="fill:none;stroke-width:2;stroke-linecap:round;stroke-dasharray:1 7"/>' +
		'<ellipse cx="' + n1(p1[0]) + '" cy="' + n1(p1[1]) + '" rx="6.5" ry="3.7" style="fill:rgba(16,22,25,.55);stroke:rgba(255,255,255,.55);stroke-width:1"/>' +
		lane(qd(a[0], a[1], a[2]), DNT, DN, id + '|dn') + lane(qd(b[0], b[1], b[2]), UPT, UP, id + '|up') + '</g>' };
}

/* Build the whole map for one layout (only when devices get or lose a stand). */
function buildMap(net, L) {
	var objs = [objWan(), objRouter()], links = [], arcs = [], hubs = [], zones = [], marks = [];
	var HR = P(7.1, 7.1, 2.2);
	L.nodes.forEach(function (x, i) {
		var s = x.slot, o = objNode(x.node.id, s.cx, s.cy);
		objs.push(o);
		var z = s.zone, t = P(s.text[0], s.text[1]);
		zones.push('<g data-zone="' + x.node.id + '" class="ob">' + poly([P(z[0], z[1]), P(z[2], z[1]), P(z[2], z[3]), P(z[0], z[3])], 'fill:rgba(169,156,245,.09);stroke:rgba(169,156,245,.55);stroke-width:1;stroke-dasharray:5 5') +
			'<text transform="matrix(' + CC.toFixed(4) + ' 0.5 ' + (-CC).toFixed(4) + ' 0.5 ' + n1(t[0]) + ' ' + n1(t[1]) + ')" style="font-size:11px;font-weight:700;letter-spacing:.12em;fill:rgba(205,197,252,.9)">' + esc(('via ' + x.node.name).toUpperCase().slice(0, 22)) + '</text></g>');
		var a = arc(x.node.id, HR, o.hub, 0.2, true);
		arcs.push(a);
		hubs.push('<ellipse cx="' + n1(o.hub[0]) + '" cy="' + n1(o.hub[1]) + '" rx="8" ry="4.6" style="fill:rgba(16,22,25,.6);stroke:' + MESH + ';stroke-width:1.2"/>');
		hubs.push('<ellipse cx="' + n1(o.hub[0]) + '" cy="' + n1(o.hub[1]) + '" rx="8" ry="4.6" class="df-a df-ripple" style="fill:none;stroke:' + MESH + ';stroke-width:1.2;animation-delay:-1.3s"/>');
		var m = a.mid;
		marks.push('<g data-mk="' + x.node.id + ':off" class="hide"><circle cx="' + n1(m[0]) + '" cy="' + n1(m[1]) + '" r="9" style="fill:#2b3539;stroke:' + BAD + ';stroke-width:1.4"/>' +
			'<path d="M' + n1(m[0] - 3.5) + ' ' + n1(m[1] - 3.5) + ' l7 7 M' + n1(m[0] + 3.5) + ' ' + n1(m[1] - 3.5) + ' l-7 7" style="fill:none;stroke:' + BAD + ';stroke-width:1.8;stroke-linecap:round"/></g>');
		marks.push('<g data-mk="' + x.node.id + ':warn" class="hide"><circle cx="' + n1(m[0]) + '" cy="' + n1(m[1]) + '" r="9" style="fill:#2b3539;stroke:' + ACC + ';stroke-width:1.4"/>' +
			'<path d="M' + n1(m[0]) + ' ' + n1(m[1] - 4.5) + ' v6 M' + n1(m[0]) + ' ' + n1(m[1] + 4.5) + ' v.01" style="fill:none;stroke:' + ACC + ';stroke-width:2;stroke-linecap:round"/></g>');
		x.obj = o;
	});
	var hubOf = function (dv) { for (var i = 0; i < L.nodes.length; i++) if (L.nodes[i].node === dv.node) return L.nodes[i].obj.hub; return HR; };
	L.devs.forEach(function (x) {
		var o = objDevice(x.dev.id, x.dev.kind, x.slot.cx, x.slot.cy, x.slot.face);
		objs.push(o);
		arcs.push(arc(x.dev.id, hubOf(x.dev), o.target, x.dev.node ? 0.3 : 0.22, false));
	});
	links.push(tube('wan', [[2.3, 1.675], [7.1, 1.675], [7.1, 6.0]]));
	L.wired.forEach(function (x) {
		objs.push(objDevice(x.dev.id, x.dev.kind, x.slot.cx, x.slot.cy, 'L'));
		links.push(tube(x.dev.id, x.slot.route));
	});
	if (L.tray.length) {
		var tr = objTray(TRAY.cx, TRAY.cy);
		objs.push(tr);
		arcs.push(arc('more', HR, tr.target, 0.2, false));
	}
	objs.sort(function (a, b) { return a.depth - b.depth; });
	hubs.push('<ellipse cx="' + n1(HR[0]) + '" cy="' + n1(HR[1]) + '" rx="9" ry="5.2" style="fill:rgba(16,22,25,.6);stroke:' + ACC + ';stroke-width:1.2"/>');
	hubs.push('<ellipse cx="' + n1(HR[0]) + '" cy="' + n1(HR[1]) + '" rx="9" ry="5.2" class="df-a df-ripple" style="fill:none;stroke:' + ACC + ';stroke-width:1.2"/>');

	/* the room: slab, two low walls, a grid and the fibre wall plate */
	var WT = 0.35, WH = 1.1, floor = [];
	floor.push(poly([P(-WT, FY, 0), P(FX, FY, 0), P(FX, FY, -0.45), P(-WT, FY, -0.45)], 'fill:#28343a'));
	floor.push(poly([P(FX, -WT, 0), P(FX, FY, 0), P(FX, FY, -0.45), P(FX, -WT, -0.45)], 'fill:#1b2428'));
	floor.push(poly([P(-WT, -WT), P(FX, -WT), P(FX, FY), P(-WT, FY)], 'fill:url(#ar-floor)'));
	var g = [];
	for (var i = 1; i < FX; i++) { var a0 = P(i, 0), a1 = P(i, FY); g.push('M' + n1(a0[0]) + ' ' + n1(a0[1]) + ' L' + n1(a1[0]) + ' ' + n1(a1[1])); }
	for (var k = 1; k < FY; k++) { var b0 = P(0, k), b1 = P(FX, k); g.push('M' + n1(b0[0]) + ' ' + n1(b0[1]) + ' L' + n1(b1[0]) + ' ' + n1(b1[1])); }
	floor.push('<path d="' + g.join(' ') + '" style="fill:none;stroke:rgba(255,255,255,.045);stroke-width:1"/>');
	floor.push(pline([P(-WT, FY), P(FX, FY), P(FX, -WT)], 'fill:none;stroke:rgba(255,255,255,.22);stroke-width:1'));
	var w = new Obj('wall', 0, 0, 0);
	w.box(-WT, -WT, 0, WT, FY + WT, WH, M_WALL);
	w.line('R', 0.03, 0.12, 1, 0.12, 'rgba(0,0,0,.35)', 1);
	w.box(0, -WT, 0, FX, WT, WH, M_WALL);
	w.line('L', 0, 0.12, 1, 0.12, 'rgba(0,0,0,.3)', 1);
	var bw = w.last;
	w.face('L', 1.42 / FX, 0.3, 1.93 / FX, 0.72, 'fill:#c9d1d4;stroke:#6b777c;stroke-width:.7', bw);
	var pp = w.fp('L', 1.675 / FX, 0.5, bw);
	w.svg.push('<circle cx="' + n1(pp[0]) + '" cy="' + n1(pp[1]) + '" r="1.7" style="fill:' + DN + '"/>');
	floor = floor.concat(w.svg);
	floor.push(pline([P(1.675, 0, 0.42), P(1.675, 0, 0.06), P(1.675, 1.15, 0.06)], 'fill:none;stroke:#11181b;stroke-width:4.5;stroke-linecap:round;stroke-linejoin:round'));
	floor.push(pline([P(1.675, 0, 0.42), P(1.675, 0, 0.06), P(1.675, 1.15, 0.06)], 'fill:none;stroke:#3f7fa6;stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round'));

	var sh = [];
	objs.forEach(function (o) {
		var parts = o.shadow.map(function (s) {
			var X = s[0], Y = s[1], dx = s[2], dy = s[3], sx = s[4], sy = s[5];
			return poly([P(X, Y + dy), P(X + dx, Y + dy), P(X + dx + sx, Y + dy + sy), P(X + dx + sx, Y + sy), P(X + sx, Y + sy), P(X, Y)], 'fill:#000000');
		}).join('');
		if (parts) sh.push('<g data-sh="' + o.id + '">' + parts + '</g>');
	});

	/* labels: real buttons over the scene, placed where they hit nothing */
	var labels = placeLabels(net, L, objs, arcs);
	var leaders = labels.map(function (lb) {
		return '<g data-lead="' + lb.id + '" class="ob"><path d="M' + n1(lb.px) + ' ' + n1(lb.py) + ' L' + n1(lb.ax) + ' ' + n1(lb.ay) + '" style="fill:none;stroke:rgba(255,255,255,.4);stroke-width:1"/>' +
			'<circle cx="' + n1(lb.ax) + '" cy="' + n1(lb.ay) + '" r="2" style="fill:#f0efec"/></g>';
	});
	var grad = function (id, a, b, c) {
		return '<linearGradient id="' + id + '" x1="0" y1="0" x2="1" y2="1"><stop offset="0" style="stop-color:' + a + '"/>' + (c ? '<stop offset=".55" style="stop-color:' + b + '"/>' : '') + '<stop offset="1" style="stop-color:' + (c || b) + '"/></linearGradient>';
	};
	var defs = '<defs><linearGradient id="ar-floor" x1="0" y1="0" x2="1" y2="1"><stop offset="0" style="stop-color:#43535b"/><stop offset="1" style="stop-color:#2e3b41"/></linearGradient>' +
		grad('ar-scr1', '#123049', '#2c76a6', '#6cc6ea') + grad('ar-scr2', '#22265a', '#4f57bd', '#a3acf5') + grad('ar-scr3', '#0f2a40', '#2f78a6') + grad('ar-scr4', '#1b3346', '#4a96c0') + grad('ar-scr5', '#1a3a52', '#5aa9d6') +
		'<linearGradient id="ar-beam" x1="0" y1="1" x2="0" y2="0"><stop offset="0" style="stop-color:#59c3ff;stop-opacity:.5"/><stop offset="1" style="stop-color:#59c3ff;stop-opacity:0"/></linearGradient>' +
		'<radialGradient id="ar-halo"><stop offset=".45" style="stop-color:#59c3ff;stop-opacity:.34"/><stop offset="1" style="stop-color:#59c3ff;stop-opacity:0"/></radialGradient>' +
		'<radialGradient id="ar-globe" cx=".36" cy=".32" r=".8"><stop offset="0" style="stop-color:#bfe8ff"/><stop offset=".5" style="stop-color:#59c3ff"/><stop offset="1" style="stop-color:#1e6fa3"/></radialGradient>' +
		'<filter id="ar-blur" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="2.4"/></filter></defs>';
	var svg = '<svg width="' + SW + '" height="' + SH + '" viewBox="0 0 ' + SW + ' ' + SH + '" role="img" aria-label="Isometric map of your network: traffic moving between the internet, the router, its AiMesh nodes and each device">' +
		defs + floor.join('') + zones.join('') + links.join('') + '<g style="opacity:.3" filter="url(#ar-blur)">' + sh.join('') + '</g>' +
		objs.map(function (o) { return '<g data-obj="' + o.id + '" class="ob">' + o.svg.join('') + '</g>'; }).join('') +
		arcs.map(function (a) { return a.svg; }).join('') + hubs.join('') + marks.join('') + leaders.join('') + '</svg>';
	var html = labels.map(function (lb) {
		return '<button type="button" class="ar-lb" data-id="' + esc(lb.id) + '" style="left:' + lb.x + 'px;top:' + lb.y + 'px;width:' + lb.w + 'px;justify-content:' + lb.just + '" aria-pressed="false">' +
			'<span><span class="n">' + esc(lb.name) + '</span><span class="v"></span></span></button>';
	}).join('');
	return { svg: svg, labels: html };
}

/* Label placement: try spots around each object, keep the first that hits no other label, object,
   Wi-Fi arc or overlay. Widths come from the real text, measured once. */
var ctx2d = null;
function textW(s, bold) {
	try {
		ctx2d = ctx2d || document.createElement('canvas').getContext('2d');
		ctx2d.font = (bold ? '700 ' : '') + '11px system-ui, -apple-system, "Segoe UI", Arial, sans-serif';
		return ctx2d.measureText(s).width;
	} catch (e) { return s.length * 6.6; }
}
function placeLabels(net, L, objs, arcs) {
	var HIT = 44, rects = [], out = [];
	var zones = [[0, 0, 244, 78], [462, 0, SW, 62], [0, SH - 40, 440, SH]];
	var byId = {};
	objs.forEach(function (o) { byId[o.id] = o; });
	var items = [{ id: 'router', name: net.router.model || 'Router', o: byId.router }, { id: 'wan', name: 'Internet', o: byId.wan }];
	L.nodes.forEach(function (x) { items.push({ id: x.node.id, name: x.node.name, o: byId[x.node.id] }); });
	L.wired.concat(L.devs).sort(function (a, b) { return busy(b.dev) - busy(a.dev); }).forEach(function (x) { items.push({ id: x.dev.id, name: x.dev.name, o: byId[x.dev.id] }); });
	if (L.tray.length) items.push({ id: 'more', name: '+' + L.tray.length + ' more', o: byId.more });
	var ov = function (a, b) { return !(a[2] <= b[0] || b[2] <= a[0] || a[3] <= b[1] || b[3] <= a[1]); };
	var arcPts = [];
	arcs.forEach(function (a) { arcPts = arcPts.concat(a.pts.slice(3, -3)); });
	items.forEach(function (it) {
		if (!it.o) return;
		var name = it.name.length > 24 ? it.name.slice(0, 23) + '…' : it.name;
		/* A node's second line can grow a " · weak" tag, so it gets room for that up front. */
		var w = Math.round(Math.max(textW(name, true), it.id.indexOf('node:') === 0 ? 112 : 76) + 22), bb = it.o.bbox(), ax = it.o.anchor[0];
		var cands = [];
		[0, -34, 34, -68, 68].forEach(function (dx) {
			cands.push({ x: ax - w / 2 + dx, y: bb[1] - 7 - HIT, px: ax + dx, py: bb[1] - 12, ay: bb[1] - 2, just: 'center' });
			cands.push({ x: ax - w / 2 + dx, y: bb[3] + 7, px: ax + dx, py: bb[3] + 12, ay: bb[3] + 2, just: 'center' });
		});
		cands.push({ x: bb[2] + 11, y: (bb[1] + bb[3]) / 2 - HIT / 2, px: bb[2] + 15, py: (bb[1] + bb[3]) / 2, ay: (bb[1] + bb[3]) / 2, axr: bb[2] + 1, just: 'flex-start' });
		cands.push({ x: bb[0] - 11 - w, y: (bb[1] + bb[3]) / 2 - HIT / 2, px: bb[0] - 15, py: (bb[1] + bb[3]) / 2, ay: (bb[1] + bb[3]) / 2, axr: bb[0] - 1, just: 'flex-end' });
		var best = null, bestCost = 1e9;
		cands.forEach(function (c, ci) {
			var r = [c.x, c.y + 5, c.x + w, c.y + HIT - 5], cost = ci * 0.01;
			if (r[0] < 4 || r[1] < 4 || r[2] > SW - 4 || r[3] > SH - 4) cost += 1000;
			rects.forEach(function (o) { if (ov(r, o)) cost += 100; });
			objs.forEach(function (o) { if (o !== it.o && ov(r, o.bbox())) cost += 40; });
			zones.forEach(function (z) { if (ov(r, z)) cost += 60; });
			arcPts.forEach(function (p) { if (p[0] > r[0] - 2 && p[0] < r[2] + 2 && p[1] > r[1] && p[1] < r[3]) cost += 0.6; });
			if (cost < bestCost) { bestCost = cost; best = c; }
		});
		var x = Math.round(best.x), y = Math.round(best.y);
		rects.push([x, y + 5, x + w, y + HIT - 5]);
		out.push({ id: it.id, name: name, x: x, y: y, w: w, just: best.just, px: best.px, py: best.py, ax: best.axr !== undefined ? best.axr : ax, ay: best.ay });
	});
	return out;
}

/* ---------------------------------------------------------------- selection: what lights up */
function chainOf(net, id) {
	if (!id || id === 'router') return null;
	if (id === 'wan') return ['wan'];
	if (id === 'more') return ['more'];
	var n = net.byId[id];
	if (!n) return null;
	if (n.mac && id.indexOf('node:') === 0) return [id].concat(n.devs.map(function (dv) { return dv.id; }));
	if (n.node) return [n.node.id, id];
	return [id];
}
function selValid(net) {
	if (A.sel && !net.byId[A.sel] && A.sel !== 'more') A.sel = null;
	if (A.sel === 'more' && !(A.layout && A.layout.tray.length)) A.sel = null;
	return A.sel;
}
function pick(id) { A.sel = A.sel === id || id === 'router' ? null : id; render(); }

/* ---------------------------------------------------------------- rendering */
function render() {
	var net = A.net;
	var root = $('ar');
	if (!root) return;
	root.className = A.paused ? 'paused' : '';
	if (!net) { setNotice('Starting the sampler on the router…', MUTED); return; }
	try { renderSummary(net); } catch (e) { report(e); }
	if (A.tab === 'map') { try { renderMap(net); } catch (e) { report(e); } }
	else { try { renderFlow(net); } catch (e) { report(e); } }
	try { renderReadout(net); renderSide(net); renderFoot(net); } catch (e) { report(e); }
}
function report(e) { if (window.console) console.error('Arteria:', e); }
function setLive() {
	var b = $('arLive'), t = $('arLiveTxt');
	if (!b) return;
	var cls = 'ar-live', txt;
	if (A.paused) txt = 'Paused';
	else if (document.hidden) txt = 'Hidden';
	else if (!A.fresh) { txt = 'Connecting…'; cls += ' warn'; }
	else if (stale()) { txt = 'Waiting for the router'; cls += ' warn'; }
	else { txt = 'Live · every ' + A.interval + ' s'; cls += ' live'; }
	b.className = cls; t.textContent = txt;
	b.setAttribute('aria-pressed', A.paused ? 'true' : 'false');
}
function renderSummary(net) {
	var s = $('arSum');
	s.innerHTML = '<span class="k">Internet</span><span><span class="dn">↓</span> <b>' + esc(full(net.wan.dn)) + '</b></span><span><span class="up">↑</span> <b>' + esc(full(net.wan.up)) + '</b></span><span class="k">' + net.clients + ' clients</span>';
}
function noticeFor(net) {
	if (A.paused) return ['Paused. The router stops sampling about 20 s after you pause.', MUTED];
	if (!A.fresh) return [Date.now() - A.started > 20000 ? 'No samples from the router. Is Arteria installed? Run arteria.sh status on the router.' : 'Starting the sampler on the router…', Date.now() - A.started > 20000 ? ACC : MUTED];
	if (stale()) return ['The router stopped sending samples. Retrying…', ACC];
	for (var i = 0; i < net.nodes.length; i++) {
		var n = net.nodes[i];
		if (!n.online) return [n.name + ' is offline. Its devices may rejoin through the router.', BAD];
		if (n.weak) return ['Weak backhaul: ' + n.name + ' links at ' + (n.bhRssi || '?') + ' dBm, ' + (n.bhPhy || '?') + ' Mb/s.', ACC];
		if (n.state === 'nokey') return [n.name + ': per-device traffic needs node access. Run arteria.sh nodekey on the router.', ACC];
		if (n.state === 'hostkey') return [n.name + ' has a new SSH identity (reset?). Run arteria.sh nodekey to trust it again.', ACC];
		if (n.state === 'down') return [n.name + ' isn\'t answering over SSH, so its devices show without numbers.', ACC];
		if (n.state === 'off') return ['Node access is off (NODES=off): ' + n.name + ' shows its backhaul total only.', MUTED];
	}
	if (net.total.sdn + net.total.sup < 0.05) return ['The network is idle. Packets thin out as throughput falls.', INK2];
	return null;
}
function setNotice(text, color) {
	['arNoticeMap', 'arNoticeFlow'].forEach(function (id) {
		var el = $(id);
		if (!el) return;
		el.querySelector('.tx').textContent = text;
		el.querySelector('.sw').style.background = color;
	});
}

/* the map, every poll: classes and numbers only (the scene is rebuilt only when stands change) */
function renderMap(net) {
	var L = mapLayout(net), sig = mapSignature(L);
	A.layout = L;
	if (sig !== A.mapSig) {
		var b = buildMap(net, L);
		$('arMapScene').innerHTML = b.svg;
		$('arMapLabels').innerHTML = b.labels;
		A.mapSig = sig; A.slotAt = A.gotAny ? Date.now() : 0;
		var refs = { lanes: [], links: {}, alts: {}, objs: {}, leads: {}, rings: {}, zones: {}, marks: {}, labels: {} };
		var root = $('arMap');
		Array.prototype.forEach.call(root.querySelectorAll('[data-lane]'), function (el) { refs.lanes.push(el); });
		[['data-link', 'links'], ['data-alt', 'alts'], ['data-obj', 'objs'], ['data-lead', 'leads'], ['data-ring', 'rings'], ['data-zone', 'zones'], ['data-mk', 'marks']].forEach(function (p) {
			Array.prototype.forEach.call(root.querySelectorAll('[' + p[0] + ']'), function (el) { refs[p[1]][el.getAttribute(p[0])] = el; });
		});
		Array.prototype.forEach.call(root.querySelectorAll('.ar-lb'), function (el) {
			refs.labels[el.getAttribute('data-id')] = el;
			el.addEventListener('click', function () { pick(el.getAttribute('data-id')); });
		});
		A.mapRefs = refs;
	}
	var R = A.mapRefs, sel = selValid(net), on = chainOf(net, sel);
	var lit = function (id) { return !on || on.indexOf(id) >= 0; };
	var trayDn = 0, trayUp = 0, traySdn = 0, traySup = 0;
	L.tray.forEach(function (dv) { trayDn += dv.dn; trayUp += dv.up; traySdn += dv.sdn; traySup += dv.sup; });
	var rateOf = function (id) {
		if (id === 'wan') return net.wan;
		if (id === 'more') return { dn: trayDn, up: trayUp, sdn: traySdn, sup: traySup };
		var x = net.byId[id];
		if (!x) return { dn: 0, up: 0, sdn: 0, sup: 0 };
		return x.bh ? x.bh : x;
	};
	R.lanes.forEach(function (el) {
		var k = el.getAttribute('data-lane').split('|'), r = rateOf(k[0]), x = net.byId[k[0]];
		var bk = x && x.st && x.st !== 'ok' ? 'bx' : bucketOf(k[0] + '|' + k[1], k[1] === 'dn' ? r.sdn : r.sup);
		if (x && x.mac && k[0].indexOf('node:') === 0 && !x.online) bk = 'bx';
		var cls = el.getAttribute('data-cls') + ' ' + bk;
		if (el.getAttribute('class') !== cls) el.setAttribute('class', cls);
	});
	Object.keys(R.links).forEach(function (id) { R.links[id].setAttribute('class', lit(id) ? 'lk' : 'lk dim'); });
	Object.keys(R.objs).forEach(function (id) {
		if (id === 'wall') return;
		var x = net.byId[id], off = x && ((x.st && x.st === 'off') || (id.indexOf('node:') === 0 && !x.online));
		R.objs[id].setAttribute('class', off ? 'ob off' : (id === 'router' || lit(id) ? 'ob' : 'ob dim'));
		if (R.leads[id]) R.leads[id].setAttribute('class', id === 'router' || lit(id) ? 'ob' : 'ob dim');
	});
	Object.keys(R.alts).forEach(function (id) {
		var x = net.byId[id], c = 'hide';
		if (x && id.indexOf('node:') === 0) c = !x.online ? 'alt-off' : (x.weak ? 'alt-warn' : 'hide');
		else if (x && x.st === 'nodata') c = 'alt-nd';
		R.alts[id].setAttribute('class', c);
	});
	net.nodes.forEach(function (n) {
		var off = !n.online;
		if (R.rings[n.id + ':lit']) { R.rings[n.id + ':lit'].setAttribute('class', off ? 'hide' : ''); R.rings[n.id + ':dead'].setAttribute('class', off ? '' : 'hide'); }
		if (R.zones[n.id]) R.zones[n.id].setAttribute('class', off ? 'ob off' : 'ob');
		if (R.marks[n.id + ':off']) { R.marks[n.id + ':off'].setAttribute('class', off ? '' : 'hide'); R.marks[n.id + ':warn'].setAttribute('class', !off && n.weak ? '' : 'hide'); }
	});
	Object.keys(R.labels).forEach(function (id) {
		var el = R.labels[id], v = el.querySelector('.v'), x = net.byId[id], r = rateOf(id), html;
		if (id === 'router') html = '<span class="c-mut">' + net.clients + ' clients</span>';
		else if (id.indexOf('node:') === 0 && x && !x.online) html = '<span class="c-bad">Offline</span>';
		else if (x && x.st === 'off') html = '<span class="c-bad">Offline</span>';
		else if (x && x.st === 'nodata') html = '<span class="c-mut">Not reported</span>';
		else html = '<span class="c-dn">↓ ' + esc(short(r.dn)) + '</span><span class="c-up" style="margin-left:6px">↑ ' + esc(short(r.up)) + '</span>' +
			(x && x.weak ? '<span class="c-warn"> · weak</span>' : '');
		if (v.innerHTML !== html) v.innerHTML = html;
		var isOn = sel === id;
		el.className = 'ar-lb' + (isOn ? ' on' : '') + (id === 'router' || lit(id) ? '' : ' dim');
		el.setAttribute('aria-pressed', isOn ? 'true' : 'false');
	});
	var nt = noticeFor(net) || ['Tap a device label to trace its path. Tap it again to show everything.', MUTED];
	setNotice(nt[0], nt[1]);
}

/* ---------------------------------------------------------------- the flow (Sankey) */
var FX0 = { src: 80, rt: 190, link: 298, mesh: 434, dev: 516 }, FBW = { src: 10, rt: 12, link: 10, mesh: 10, dev: 8 };
var FTOP = 88, FLIMIT = SH - 10, FGAP = 3, FGGAP = 11, FMIN = 44, FSGAP = 34, FTARGET = 230, FKCAP = 11.5, FROWS = 8;
/* Which rows the Flow view shows: groups in a fixed order (the router's 5 GHz clients, each node,
   wired, then 2.4 and 6 GHz), names in alphabetical order. A group that can't fit all its devices
   shows its busiest and a "+N more" row; membership is re-checked every 10 s, not every poll. */
function flowGroups(net) {
	var gs = [], visible = net.devs.filter(function (dv) { return dv.st !== 'off' || dv.node; });
	var add = function (id, label, kind, devs, node) { if (devs.length || node) gs.push({ id: id, label: label, kind: kind, devs: devs, node: node || null }); };
	add('r5', '5 GHz', 'wifi', visible.filter(function (dv) { return dv.link === 'wifi' && !dv.node && dv.band === '5'; }));
	net.nodes.forEach(function (n) { add(n.id, n.name, 'node', n.devs.slice(), n); });
	add('lan', 'LAN', 'wired', visible.filter(function (dv) { return dv.link === 'wired'; }));
	add('r24', '2.4 GHz', 'wifi', visible.filter(function (dv) { return dv.link === 'wifi' && !dv.node && dv.band === '2.4'; }));
	add('r6', '6 GHz', 'wifi', visible.filter(function (dv) { return dv.link === 'wifi' && !dv.node && dv.band !== '5' && dv.band !== '2.4'; }));
	/* row budget: every group gets one row; then the busiest devices overall, each costing a row
	   (and its group a "+N more" row while some of it is still hidden) */
	var shown = {}, budget = FROWS;
	gs.forEach(function (g) { g.devs.sort(function (a, b) { return busy(b) - busy(a) || byName(a, b); }); shown[g.id] = []; });
	var rows = function () { return gs.reduce(function (a, g) { var n = shown[g.id].length; return a + Math.max(1, n + (n < g.devs.length ? 1 : 0)); }, 0); };
	var prev = A.flowPick || {};
	var hold = Date.now() - A.flowAt < 10000;
	var cands = [];
	gs.forEach(function (g) { g.devs.forEach(function (dv) { cands.push({ g: g, dv: dv, keep: hold && prev[dv.id] }); }); });
	cands.sort(function (a, b) { return (b.keep ? 1 : 0) - (a.keep ? 1 : 0) || busy(b.dv) - busy(a.dv); });
	cands.forEach(function (c) {
		shown[c.g.id].push(c.dv);
		if (rows() > budget) shown[c.g.id].pop();
	});
	if (!hold) { A.flowAt = Date.now(); A.flowPick = {}; gs.forEach(function (g) { shown[g.id].forEach(function (dv) { A.flowPick[dv.id] = 1; }); }); }
	gs.forEach(function (g) {
		var sh = shown[g.id].slice().sort(byName), hidden = g.devs.filter(function (dv) { return sh.indexOf(dv) < 0; });
		g.rows = sh.map(function (dv) { return { id: dv.id, dev: dv }; });
		if (hidden.length) g.rows.push({ id: 'more:' + g.id, more: hidden });
		if (!g.rows.length && g.node) g.rows.push({ id: g.node.id, nodeOnly: g.node });
	});
	return gs;
}
function flowSignature(gs) { return JSON.stringify(gs.map(function (g) { return [g.id, g.rows.map(function (r) { return r.id; })]; })); }
function buildFlow(gs) {
	var o = [], keys = [];
	var rb = function (key, cls) {
		keys.push(key);
		var dl = function (i) { return (-((hash(key) * 17 + i * 29) % 100) / 100 * 1.4).toFixed(2); };
		return '<g data-rb="' + key + '" class="rb"><path data-f="' + key + '" class="rf' + (cls || '') + '" d="M0 0"/>' +
			[0, 1, 2].map(function (i) { return '<path data-s="' + key + '|' + i + '" class="df-a sk bx" d="M0 0" style="animation-delay:' + dl(i) + 's"/>'; }).join('') + '</g>';
	};
	o.push(rb('src:wan'), rb('src:loc', ' loc'));
	gs.forEach(function (g) {
		o.push(rb('g:' + g.id, g.node ? ' bhc' : ''));
		if (g.node) o.push(rb('m:' + g.id, ' bhc'));
		g.rows.forEach(function (r) { o.push(rb('d:' + r.id, g.node && g.node.state !== 'ok' ? ' nd' : (g.node ? ' bhc' : ''))); });
	});
	o.push('<path data-hl="a" class="rf hl hide" d="M0 0"/><path data-hl="b" class="rf hl hide" d="M0 0"/>');
	var bar = function (key, x, w, cls) { return '<rect data-br="' + key + '" x="' + x + '" y="0" width="' + w + '" height="0" rx="2" class="' + cls + '"/>'; };
	o.push(bar('src:wan', FX0.src, FBW.src, 'bf'), bar('src:loc', FX0.src, FBW.src, 'bf'));
	o.push('<rect data-br="rt" x="' + FX0.rt + '" y="0" width="' + FBW.rt + '" height="0" rx="2" style="fill:' + ACC + '"/>');
	gs.forEach(function (g) {
		o.push(bar('g:' + g.id, FX0.link, FBW.link, g.node ? 'bm' : 'bf'));
		if (g.node) o.push(bar('n:' + g.id, FX0.mesh, FBW.mesh, 'bm'), '<rect data-br="brk:' + g.id + '" x="' + (FX0.dev + FBW.dev + 2) + '" y="0" width="2" height="0" rx="1" class="hide" style="fill:#c3c2b7"/>');
		g.rows.forEach(function (r) { o.push(bar('d:' + r.id, FX0.dev, FBW.dev, g.node ? 'bm' : 'bf')); });
	});
	var lbl = function (key, inner) { return '<g data-tx="' + key + '" transform="translate(0 0)">' + inner + '</g>'; };
	o.push(lbl('src:wan', '<text x="' + (FX0.src - 8) + '" y="-2" style="font-size:12px;font-weight:700;fill:#f0efec;text-anchor:end">Internet</text><text data-t="agg:wan" x="' + (FX0.src - 8) + '" y="12" style="font-size:10.5px;fill:#c3c2b7;text-anchor:end;font-variant-numeric:tabular-nums"></text>'));
	o.push(lbl('src:loc', '<text x="' + (FX0.src - 8) + '" y="-2" style="font-size:12px;font-weight:700;fill:#f0efec;text-anchor:end">Local</text><text data-t="agg:loc" x="' + (FX0.src - 8) + '" y="12" style="font-size:10.5px;fill:#c3c2b7;text-anchor:end;font-variant-numeric:tabular-nums"></text><text x="' + (FX0.src - 8) + '" y="25" style="font-size:10px;fill:#93a9b1;text-anchor:end">LAN ↔ LAN</text>'));
	o.push(lbl('rt', '<text data-t="rtname" x="' + (FX0.rt + 6) + '" y="0" style="font-size:12px;font-weight:700;fill:#ffcc00;text-anchor:middle"></text>'));
	o.push(lbl('rtb', '<text data-t="agg:rt" x="' + (FX0.rt + 6) + '" y="0" style="font-size:10.5px;fill:#c3c2b7;text-anchor:middle;font-variant-numeric:tabular-nums"></text>'));
	gs.forEach(function (g) {
		var nm = g.node ? 'Backhaul' : g.label, pw = Math.round(textW(nm, true) + 70);
		o.push(lbl('g:' + g.id, '<rect x="' + (FX0.link - 4) + '" y="-12.5" width="' + pw + '" height="17" rx="4" style="fill:#2b3539;fill-opacity:.92"/>' +
			'<text x="' + (FX0.link + 2) + '" y="0" style="font-size:11px;font-weight:700;fill:' + (g.node ? '#cdc5fc' : '#f0efec') + '">' + esc(nm) + '<tspan data-t="gv:' + g.id + '" dx="6" style="font-weight:400;fill:#c3c2b7;font-variant-numeric:tabular-nums"></tspan></text>'));
		if (g.node) {
			var nn = g.label.length > 12 ? g.label.slice(0, 11) + '…' : g.label;
			o.push(lbl('n:' + g.id, '<rect x="' + (FX0.mesh - 4) + '" y="-12.5" width="' + Math.round(textW(nn, true) + 12) + '" height="17" rx="4" style="fill:#2b3539;fill-opacity:.92"/><text x="' + (FX0.mesh + 2) + '" y="0" style="font-size:11px;font-weight:700;fill:#cdc5fc">' + esc(nn) + '</text>'));
		}
	});
	var hs = 'font-size:10px;font-weight:700;letter-spacing:.12em;fill:#93a9b1';
	var heads = '<text data-t="srchead" x="58" y="68" style="' + hs + ';text-anchor:middle">SOURCE</text>' +
		[[FX0.rt + 6, 'ROUTER'], [FX0.link + 5, 'LINK']].map(function (h) { return '<text x="' + h[0] + '" y="68" style="' + hs + ';text-anchor:middle">' + h[1] + '</text>'; }).join('') +
		(gs.some(function (g) { return g.node; }) ? '<text x="' + (FX0.mesh + 5) + '" y="68" style="' + hs + ';text-anchor:middle">NODE</text>' : '') +
		'<text x="538" y="68" style="' + hs + '">DEVICE</text>';
	var svg = '<svg width="' + SW + '" height="' + SH + '" viewBox="0 0 ' + SW + ' ' + SH + '" role="img" aria-label="Flow diagram: traffic between the internet or the local network and each device, through the router and each link; ribbon width follows throughput">' +
		heads + '<g data-mode="1" class="m-dn">' + o.join('') + '</g></svg>';
	var rows = [];
	gs.forEach(function (g) { g.rows.forEach(function (r) {
		rows.push('<button type="button" class="ar-row" data-row="' + esc(r.id) + '" aria-pressed="false" style="top:0;height:44px">' +
			'<span class="ic"></span><span class="tx"><span class="nm"></span><span class="sb"></span></span><span class="vl"><span class="n"></span><span class="u"></span></span></button>');
	}); });
	return { svg: svg, rows: rows.join('') };
}
function renderFlow(net) {
	var gs = flowGroups(net), sig = flowSignature(gs);
	if (sig !== A.flowSig) {
		var b = buildFlow(gs);
		$('arFlowScene').innerHTML = b.svg;
		$('arFlowRows').innerHTML = b.rows;
		A.flowSig = sig;
		var root = $('arFlow'), refs = { f: {}, s: {}, br: {}, tx: {}, t: {}, hl: {}, rb: {}, rows: {} };
		[['data-f', 'f'], ['data-s', 's'], ['data-br', 'br'], ['data-tx', 'tx'], ['data-t', 't'], ['data-hl', 'hl'], ['data-rb', 'rb'], ['data-row', 'rows']].forEach(function (p) {
			Array.prototype.forEach.call(root.querySelectorAll('[' + p[0] + ']'), function (el) { refs[p[1]][el.getAttribute(p[0])] = el; });
		});
		Object.keys(refs.rows).forEach(function (id) { refs.rows[id].addEventListener('click', function () { pick(id.indexOf('more:') === 0 ? 'more' : id); }); });
		refs.mode = root.querySelector('[data-mode]');
		A.flowRefs = refs;
	}
	var R = A.flowRefs, upm = A.mode === 'up', f = upm ? 'up' : 'dn', bf = upm ? 'sup' : 'sdn';
	R.mode.setAttribute('class', upm ? 'm-up' : 'm-dn');
	R.t.srchead.textContent = upm ? 'DESTINATION' : 'SOURCE';
	var sel = selValid(net);
	var rowVal = function (r, key) {
		if (r.dev) return r.dev.st === 'ok' ? Math.max(r.dev[key], 0) : 0;
		if (r.more) return r.more.reduce(function (a, dv) { return a + (dv.st === 'ok' ? Math.max(dv[key], 0) : 0); }, 0);
		if (r.nodeOnly) return Math.max(r.nodeOnly.bh[key], 0);
		return 0;
	};
	var gVal = function (g, key) { return g.node ? Math.max(g.node.bh[key], 0) : g.rows.reduce(function (a, r) { return a + rowVal(r, key); }, 0); };
	var agg = function (g) { return g.node && g.node.state !== 'ok'; };
	var lay = function (k, key) {
		var y = FTOP, slot = {}, grp = {};
		gs.forEach(function (g, gi) {
			if (gi) y += FGGAP;
			var y0 = y, Hh = 0, n = g.rows.length, gv = gVal(g, key);
			var aggH = agg(g) && gv > 0 ? Math.max(gv * k, 1.5) : 0;
			g.rows.forEach(function (r, ri) {
				if (ri) y += FGAP;
				var v = agg(g) ? 0 : rowVal(r, key), h = v > 0 ? Math.max(v * k, 1.5) : 0;
				var sl = Math.max(h, FMIN, aggH ? (aggH - FGAP * (n - 1)) / n : 0);
				slot[r.id] = { top: y, s: sl, h: h, bar: y + (sl - h) / 2 };
				y += sl; Hh += h;
			});
			if (aggH) Hh = aggH;
			/* a node's backhaul can carry more than its listed clients (the node itself, rounding) */
			if (g.node && !agg(g) && gv * k > Hh) Hh = Math.min(gv * k, y - y0);
			grp[g.id] = { y0: y0, y1: y, H: Hh, top: (y0 + y) / 2 - Hh / 2 };
		});
		return { slot: slot, grp: grp, bottom: y };
	};
	var total = gs.reduce(function (a, g) { return a + gVal(g, bf); }, 0);
	var k = Math.min(FKCAP, FTARGET / Math.max(total, 1e-6));
	for (var i = 0; i < 120 && lay(k, bf).bottom > FLIMIT - 6; i++) k *= 0.97;
	var Lf = lay(k, f);
	for (var j = 0; j < 80 && Lf.bottom > FLIMIT; j++) { k *= 0.97; Lf = lay(k, f); }
	var slot = Lf.slot, grp = Lf.grp;
	var first = grp[gs[0].id], last = grp[gs[gs.length - 1].id];
	var Hr = gs.reduce(function (a, g) { return a + grp[g.id].H; }, 0);
	var rc = (first.top + last.top + last.H) / 2, rtop = rc - Hr / 2;
	var wv = Math.max(net.wan[f], 0), lv = Math.max(net.local[f], 0);
	var hi = wv + lv > 0 ? Hr * Math.min(wv / (wv + lv), 1) : Hr;
	var stop = rc - (Hr + FSGAP) / 2;
	var src = { wan: { top: stop, h: hi }, loc: { top: stop + hi + FSGAP, h: Hr - hi } };
	var rib = function (x0, a0, b0, x1, a1, b1) {
		var xm = n1((x0 + x1) / 2);
		return 'M' + n1(x0) + ' ' + n1(a0) + ' C' + xm + ' ' + n1(a0) + ' ' + xm + ' ' + n1(a1) + ' ' + n1(x1) + ' ' + n1(a1) + ' L' + n1(x1) + ' ' + n1(b1) +
			' C' + xm + ' ' + n1(b1) + ' ' + xm + ' ' + n1(b0) + ' ' + n1(x0) + ' ' + n1(b0) + ' Z';
	};
	var mid = function (x0, y0, x1, y1) {
		var xm = n1((x0 + x1) / 2);
		return upm ? 'M' + n1(x1) + ' ' + n1(y1) + ' C' + xm + ' ' + n1(y1) + ' ' + xm + ' ' + n1(y0) + ' ' + n1(x0) + ' ' + n1(y0)
			: 'M' + n1(x0) + ' ' + n1(y0) + ' C' + xm + ' ' + n1(y0) + ' ' + xm + ' ' + n1(y1) + ' ' + n1(x1) + ' ' + n1(y1);
	};
	var setD = function (el, d) { if (el && el.getAttribute('d') !== d) el.setAttribute('d', d); };
	var setC = function (el, c) { if (el && el.getAttribute('class') !== c) el.setAttribute('class', c); };
	var mk = function (key, x0, a0, x1, a1, w, base, cls) {
		var n = w <= 0 ? 0 : (w < 10 ? 1 : (w < 36 ? 2 : 3));
		setD(R.f[key], w > 0 ? rib(x0, a0, a0 + w, x1, a1, a1 + w) : 'M0 0');
		setC(R.rb[key], w > 0 ? cls : 'rb hide');
		var bk = bucketOf('f|' + key + '|' + f, base);
		for (var i = 0; i < 3; i++) {
			var fr = (i + 0.5) / Math.max(n, 1);
			setD(R.s[key + '|' + i], i < n ? mid(x0, a0 + fr * w, x1, a1 + fr * w) : 'M0 0');
			setC(R.s[key + '|' + i], 'df-a sk ' + (i < n ? bk : 'bx'));
		}
	};
	var B = function (key, y, h) { var el = R.br[key]; if (!el) return; el.setAttribute('y', n1(y)); el.setAttribute('height', n1(Math.max(h, 0.01))); if (h <= 0) setC(el, (el.getAttribute('class') || '').replace(/ ?hide/, '') + ' hide'); else setC(el, (el.getAttribute('class') || '').replace(/ ?hide/, '')); };
	var T = function (key, y) { if (R.tx[key]) R.tx[key].setAttribute('transform', 'translate(0 ' + n1(y) + ')'); };
	/* which ribbons stay bright */
	var gOf = {};
	gs.forEach(function (g) { g.rows.forEach(function (r) { gOf[r.id] = g; if (r.dev) gOf[r.dev.id] = g; if (r.more) r.more.forEach(function (dv) { gOf[dv.id] = g; }); }); });
	var selNode = sel && sel.indexOf('node:') === 0 ? sel : null;
	var selG = selNode ? gs.filter(function (g) { return g.id === selNode; })[0] : (sel && sel !== 'wan' && sel !== 'more' ? gOf[sel] : null);
	var focus = !!selG, whole = focus && (selNode || agg(selG));
	var rowSel = function (r) { return sel && (r.id === sel || (r.more && r.more.some(function (dv) { return dv.id === sel; })) || (sel === 'more' && r.more)); };
	var X = FX0, BW = FBW, ry = rtop;
	mk('src:wan', X.src + BW.src, src.wan.top, X.rt, ry, src.wan.h, net.wan[bf], focus ? 'rb mid' : 'rb');
	mk('src:loc', X.src + BW.src, src.loc.top, X.rt, ry + src.wan.h, src.loc.h, net.local[bf], focus ? 'rb mid' : 'rb');
	var hl = { a: 'M0 0', b: 'M0 0', on: false };
	gs.forEach(function (g) {
		var G = grp[g.id], litG = !focus || (whole && g === selG);
		mk('g:' + g.id, X.rt + BW.rt, ry, X.link, G.top, G.H, gVal(g, bf), litG ? 'rb' : 'rb dim');
		B('g:' + g.id, G.top, G.H);
		var x0 = X.link + BW.link;
		if (g.node) {
			mk('m:' + g.id, x0, G.top, X.mesh, G.top, G.H, gVal(g, bf), litG ? 'rb' : 'rb dim');
			B('n:' + g.id, G.top, G.H);
			x0 = X.mesh + BW.mesh;
			var brk = R.br['brk:' + g.id];
			if (brk) { if (agg(g)) { brk.setAttribute('y', n1(G.y0 + 5)); brk.setAttribute('height', n1(Math.max(G.y1 - G.y0 - 10, 1))); setC(brk, ''); } else setC(brk, 'hide'); }
		}
		var cy = G.top, off = 0;
		g.rows.forEach(function (r, ri) {
			var sl = slot[r.id], onR = !focus || rowSel(r) || (whole && g === selG);
			if (agg(g)) {
				if (ri === 0) { mk('d:' + r.id, x0, G.top, X.dev, G.top, G.H, gVal(g, bf), onR ? 'rb' : 'rb dim'); B('d:' + r.id, G.top, G.H); }
				else { mk('d:' + r.id, 0, 0, 0, 0, 0, 0, 'rb hide'); B('d:' + r.id, 0, 0); }
			} else {
				mk('d:' + r.id, x0, cy, X.dev, sl.bar, sl.h, rowVal(r, bf), onR ? 'rb' : 'rb dim');
				B('d:' + r.id, sl.bar, sl.h);
				if (focus && !whole && rowSel(r) && sl.h > 0) {
					hl.a = rib(X.rt + BW.rt, ry + off, ry + off + sl.h, X.link, cy, cy + sl.h);
					if (g.node) hl.b = rib(X.link + BW.link, cy, cy + sl.h, X.mesh, cy, cy + sl.h);
					hl.on = true;
				}
			}
			cy += sl.h; off += sl.h;
		});
		ry += G.H;
	});
	setD(R.hl.a, hl.a); setD(R.hl.b, hl.b);
	setC(R.hl.a, 'rf hl' + (hl.on ? '' : ' hide')); setC(R.hl.b, 'rf hl' + (hl.on && hl.b !== 'M0 0' ? '' : ' hide'));
	B('src:wan', src.wan.top, src.wan.h); B('src:loc', src.loc.top, src.loc.h);
	R.br.rt.setAttribute('y', n1(rtop)); R.br.rt.setAttribute('height', n1(Math.max(Hr, 0.01)));
	T('src:wan', src.wan.top + src.wan.h / 2); T('src:loc', src.loc.top + src.loc.h / 2); T('rt', rtop - 10); T('rtb', rtop + Hr + 17);
	R.t['agg:wan'].textContent = full(net.wan[f]); R.t['agg:loc'].textContent = full(net.local[f]);
	R.t.rtname.textContent = net.router.model || 'Router';
	R.t['agg:rt'].textContent = full(gs.reduce(function (a, g) { return a + gVal(g, f); }, 0));
	gs.forEach(function (g) {
		var G = grp[g.id];
		T('g:' + g.id, G.H > 0 ? G.top - 7 : (G.y0 + G.y1) / 2 + 4);
		if (g.node) T('n:' + g.id, G.H > 0 ? G.top - 7 : (G.y0 + G.y1) / 2 + 4);
		if (R.t['gv:' + g.id]) R.t['gv:' + g.id].textContent = g.node && !g.node.online ? 'offline' : full(gVal(g, f));
	});
	/* the device rows */
	gs.forEach(function (g) { g.rows.forEach(function (r) {
		var el = R.rows[r.id], sl = slot[r.id];
		if (!el) return;
		el.style.top = n1(sl.top) + 'px'; el.style.height = n1(sl.s) + 'px';
		var name, sub, icon, st = 'ok';
		if (r.dev) {
			var dv = r.dev; name = dv.name; icon = dv.kind; st = dv.st;
			sub = dv.st === 'off' ? 'Offline' : (dv.st === 'nodata' ? 'Not reported' : linkShort(dv));
		} else if (r.more) { name = '+' + r.more.length + ' more'; icon = 'more'; sub = r.more.slice(0, 3).map(function (dv) { return dv.name; }).join(', '); }
		else { name = r.nodeOnly.name; icon = 'mesh'; sub = 'No clients right now'; }
		if (g.node && agg(g)) { st = g.node.online ? 'nodata' : 'off'; if (r.dev) sub = g.node.online ? 'Not reported' : 'Offline'; }
		var v = st === 'ok' ? rowVal(r, f) : null, fm = fmt(v);
		var isOn = rowSel(r);
		var key = [name, sub, icon, fm.n, fm.u, st, upm].join('|');
		if (el._k !== key) {
			el._k = key;
			el.querySelector('.ic').innerHTML = iconSvg(icon, 16, INK2);
			el.querySelector('.nm').textContent = name;
			el.querySelector('.sb').textContent = sub;
			var nEl = el.querySelector('.vl .n');
			nEl.textContent = st === 'off' ? '—' : fm.n; nEl.style.color = st !== 'ok' ? INK2 : (upm ? UPT : DNT);
			el.querySelector('.vl .u').textContent = st === 'off' ? '' : fm.u;
		}
		el.className = 'ar-row' + (isOn ? ' on' : '') + (st === 'off' ? ' off' : '');
		el.setAttribute('aria-pressed', isOn ? 'true' : 'false');
	}); });
	$('arScaleTx').textContent = '= ' + full(24 / k);
	$('arScaleSw').style.background = upm ? UP : DN;
	$('arDn').className = upm ? '' : 'on-dn'; $('arUp').className = upm ? 'on-up' : '';
	$('arDn').setAttribute('aria-pressed', upm ? 'false' : 'true'); $('arUp').setAttribute('aria-pressed', upm ? 'true' : 'false');
	var nt = noticeFor(net) || ['Ribbon width follows throughput. Tap a device to trace it.', MUTED];
	setNotice(nt[0], nt[1]);
}
function linkShort(dv) {
	if (dv.link === 'wired') return dv.portLabel + (dv.speed ? ' · ' + (dv.speed >= 1000 ? dv.speed / 1000 + ' GbE' : dv.speed + ' Mb/s') : '') + (dv.count > 1 ? ' · ' + dv.count + ' devices' : '');
	return (dv.node ? dv.node.name : bandName(dv.band)) + (dv.rssi !== null && dv.rssi !== undefined ? ' · ' + dv.rssi + ' dBm' : '') + (dv.guest ? ' · guest' : '');
}

/* ---------------------------------------------------------------- the readout card (both views) */
function readoutFor(net) {
	/* Whole network: everything your devices received and sent. That's the internet plus local traffic:
	   between your own devices, and to or from the router itself (its pages, DNS, a USB share). The bar
	   shows the internet part solid and the local part lighter. */
	var id = A.sel, d = { icon: 'router', badge: 'Router', name: 'Whole network', link: (net.router.model || 'Router') + ' · all your devices, internet and local' };
	var dn = net.total.dn, up = net.total.up;
	var sdn = full(net.wan.dn) + ' internet + ' + full(net.local.dn) + ' local', sup = full(net.wan.up) + ' internet + ' + full(net.local.up) + ' local';
	var k1 = 'Clients', v1 = net.clients + ' online', k2 = 'Local traffic', v2 = full(net.local.dn), path = 'Through the router';
	var note = A.tab === 'map' ? 'Tap a device label on the map to trace its path.' : 'Tap a device row to trace it through the ribbons.', tone = INK2;
	var pct = function (a, b) { return a === null || !(b > 0) ? 0 : Math.max(0, Math.min(100, Math.round(100 * a / b))); };
	var rname = net.router.model || 'Router';
	if (id === 'wan') {
		d = { icon: 'globe', badge: 'WAN', name: 'Internet', link: 'WAN port · ' + (net.wanIf || '?') };
		dn = net.wan.dn; up = net.wan.up;
		sdn = pct(dn, net.total.dn) + '% of all download comes from the internet'; sup = pct(up, net.total.up) + '% of all upload goes to the internet';
		k1 = 'Interface'; v1 = net.wanIf || '—'; k2 = 'Link rate'; v2 = net.wanSpeed ? net.wanSpeed + ' Mb/s' : '—';
		path = 'Internet → ' + rname; note = 'Measured on the WAN interface counters.';
	} else if (id === 'more' && A.layout) {
		var t = A.layout.tray, sd = 0, su = 0;
		t.forEach(function (dv) { sd += dv.dn; su += dv.up; });
		d = { icon: 'more', badge: 'Grouped', name: '+' + t.length + ' more', link: t.length + ' quieter devices, grouped' };
		dn = sd; up = su; sdn = pct(dn, net.total.dn) + '% of all download'; sup = pct(up, net.total.up) + '% of all upload';
		k1 = 'Busiest'; v1 = t.length ? t.slice().sort(function (a, b) { return busy(b) - busy(a); })[0].name : '—'; k2 = 'Devices'; v2 = String(t.length);
		path = rname + ' → ' + t.length + ' devices'; note = t.map(function (dv) { return dv.name; }).join(', ');
	} else if (id && id.indexOf('node:') === 0 && net.byId[id]) {
		var n = net.byId[id];
		d = { icon: 'mesh', badge: 'AiMesh node', name: n.name, link: n.online ? (n.wiredPort ? 'Wired backhaul' : bandName(n.bhBand) + ' wireless backhaul') : 'Offline' };
		dn = n.online ? n.bh.dn : null; up = n.online ? n.bh.up : null;
		sdn = pct(dn, net.total.dn) + '% goes through the node'; sup = pct(up, net.total.up) + '% comes through the node';
		k1 = 'Backhaul signal'; v1 = n.bhRssi !== undefined && n.bhRssi !== null ? n.bhRssi + ' dBm' : '—'; k2 = 'Link rate'; v2 = n.bhPhy ? n.bhPhy + ' Mb/s' : '—';
		path = rname + ' → ' + n.name;
		note = { ok: 'Its devices are counted on the node and read over SSH.', nokey: 'Per-device data needs node access: run arteria.sh nodekey.', hostkey: 'Its SSH identity changed: run arteria.sh nodekey.',
			down: 'Not answering over SSH: showing its backhaul total.', wait: 'Connecting to the node…', off: 'Node access is off: backhaul total only.' }[n.state] || '';
		if (n.weak) { note = 'A weak backhaul caps everything behind the node.'; tone = ACC; }
		if (!n.online) { note = 'The node isn\'t connected to the router.'; tone = BAD; sdn = sup = 'offline'; }
	} else if (id && net.byId[id] && net.byId[id].link) {
		var dv = net.byId[id];
		d = { icon: dv.kind, badge: dv.link === 'wired' ? 'Wired' : 'Wi-Fi', name: dv.name,
			link: dv.link === 'wired' ? 'Wired · ' + dv.portLabel : bandName(dv.band) + ' · on ' + (dv.node ? dv.node.name : rname) + (dv.guest ? ' · guest network' : '') };
		dn = dv.st === 'ok' ? dv.dn : null; up = dv.st === 'ok' ? dv.up : null;
		sdn = pct(dn, net.total.dn) + '% of all download'; sup = pct(up, net.total.up) + '% of all upload';
		if (dv.link === 'wired') { k1 = 'Port'; v1 = dv.portLabel; k2 = 'Link rate'; v2 = dv.speed ? dv.speed + ' Mb/s' : '—'; }
		else { k1 = 'Signal'; v1 = dv.rssi !== null && dv.rssi !== undefined ? dv.rssi + ' dBm' : '—'; k2 = 'Link rate'; v2 = dv.phy ? dv.phy + ' Mb/s' : '—'; }
		path = rname + (dv.node ? ' → ' + dv.node.name : '') + ' → ' + dv.name;
		note = dv.link === 'wired' ? (dv.count > 1 ? dv.count + ' devices share this port: their traffic is added up.' : 'Measured on the port counters.')
			: (dv.node ? 'Counted on ' + dv.node.name + ' and read over SSH.' : 'Measured from Wi-Fi client counters on the router.');
		if (dv.st === 'nodata') { sdn = sup = 'not reported by the node'; note = dv.node ? dv.node.name + ' isn\'t reporting per-device traffic: see its backhaul total.' : ''; }
		if (dv.st === 'off') { sdn = sup = 'offline'; note = 'Offline.'; tone = BAD; }
	}
	var a = fmt(dn), b = fmt(up);
	return { d: d, dnN: a.n, dnU: a.u, upN: b.n, upU: b.u, dnW: pct(dn, net.total.dn) + '%', upW: pct(up, net.total.up) + '%', dnS: sdn, upS: sup, k1: k1, v1: v1, k2: k2, v2: v2, path: path, note: note, tone: tone, all: !id,
		dnNet: pct(net.wan.dn, net.total.dn), upNet: pct(net.wan.up, net.total.up) };
}
function renderReadout(net) {
	var r = readoutFor(net), el = $('arReadout');
	var key = r.d.icon + r.d.name;
	if (el._icon !== key) { $('arRoIcon').innerHTML = iconSvg(r.d.icon, 20, '#f0efec'); el._icon = key; }
	$('arRoBadge').textContent = r.d.badge; $('arRoName').textContent = r.d.name; $('arRoLink').textContent = r.d.link;
	$('arRoDnN').textContent = r.dnN; $('arRoDnU').textContent = r.dnU; $('arRoUpN').textContent = r.upN; $('arRoUpU').textContent = r.upU;
	$('arRoDnW').style.width = r.all ? '100%' : r.dnW; $('arRoUpW').style.width = r.all ? '100%' : r.upW;
	var split = function (c, p) { return r.all ? 'linear-gradient(90deg,' + c + ' ' + p + '%,' + c + '59 ' + p + '%)' : c; };
	$('arRoDnW').style.background = split('#59c3ff', r.dnNet); $('arRoUpW').style.background = split('#ff8a3d', r.upNet);
	$('arRoDnS').textContent = r.dnS; $('arRoUpS').textContent = r.upS;
	$('arRoK1').textContent = r.k1; $('arRoV1').textContent = r.v1; $('arRoK2').textContent = r.k2; $('arRoV2').textContent = r.v2; $('arRoPath').textContent = r.path;
	var nt = $('arRoNote'); nt.textContent = r.note; nt.title = r.note; nt.style.color = r.tone;
}
/* Map: the busiest devices right now. Flow: the internet over the last two minutes. */
function renderSide(net) {
	var mapOn = A.tab === 'map';
	$('arTop').className = mapOn ? 'ar-card ar-side' : 'ar-card ar-side hide';
	$('arHist').className = mapOn ? 'ar-card ar-hist hide' : 'ar-card ar-hist';
	if (mapOn) {
		var top = net.devs.filter(function (dv) { return dv.st === 'ok'; }).sort(function (a, b) { return busy(b) - busy(a); }).slice(0, 4);
		var mx = top.length ? Math.max(busy(top[0]), 1e-6) : 1;
		for (var i = 0; i < 4; i++) {
			var btn = $('arTop' + i), dv = top[i];
			if (!dv) { btn.className = 'hide'; continue; }
			btn.className = A.sel === dv.id ? 'on' : '';
			btn.setAttribute('aria-pressed', A.sel === dv.id ? 'true' : 'false');
			btn._id = dv.id;
			if (btn._icon !== dv.kind) { btn.querySelector('.ic').innerHTML = iconSvg(dv.kind, 18, INK2); btn._icon = dv.kind; }
			btn.querySelector('.nm').textContent = dv.name;
			btn.querySelector('.bar > span').style.width = Math.max(3, Math.round(100 * busy(dv) / mx)) + '%';
			btn.querySelector('.rd').textContent = '↓ ' + short(dv.dn); btn.querySelector('.ru').textContent = '↑ ' + short(dv.up);
		}
		$('arTopEmpty').className = top.length ? 'hide' : 'ar-empty';
	} else {
		var w = net.wan, a = fmt(w.dn), b = fmt(w.up);
		$('arHDnN').textContent = a.n; $('arHDnU').textContent = a.u; $('arHUpN').textContent = b.n; $('arHUpU').textContent = b.u;
		renderSpark();
	}
}
function renderSpark() {
	var Wd = 244, H = 116, base = H - 20, h = A.hist, n = Math.max(h.length, 2);
	var per = A.unit === 'MB' ? 8 : 1;   /* the axis steps are round numbers in the unit shown */
	var mxv = Math.max.apply(null, h.map(function (x) { return Math.max(x.dn, x.up); }).concat([0.001])) / per;
	var steps = [0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000], top = steps[steps.length - 1];
	for (var i = 0; i < steps.length; i++) if (steps[i] >= mxv * 1.12) { top = steps[i]; break; }
	top *= per;
	var cap = Math.round(120 / A.interval);
	var px = function (i) { return (2 + (cap - h.length + i) * (Wd - 6) / Math.max(cap - 1, 1)).toFixed(1); };
	var py = function (v) { return (14 + (1 - Math.min(v / top, 1)) * (base - 14)).toFixed(1); };
	var line = function (k) { return h.length ? 'M' + h.map(function (x, i) { return px(i) + ' ' + py(x[k]); }).join(' L') : 'M0 0'; };
	var lab = function (v) { var u = A.unit === 'MB' ? ['kB/s', 'MB/s'] : ['kb/s', 'Mb/s']; v = v / per; return v < 1 ? Math.round(v * 1000) + ' ' + u[0] : v + ' ' + u[1]; };
	$('arSpDn').setAttribute('d', line('dn')); $('arSpUp').setAttribute('d', line('up'));
	$('arSpArea').setAttribute('d', h.length ? line('dn') + ' L' + px(h.length - 1) + ' ' + base + ' L' + px(0) + ' ' + base + ' Z' : 'M0 0');
	if (h.length) { var ex = px(h.length - 1), ey = py(h[h.length - 1].dn); ['arSpDot', 'arSpRip'].forEach(function (id) { $(id).setAttribute('cx', ex); $(id).setAttribute('cy', ey); }); }
	$('arSpTop').textContent = lab(top); $('arSpMid').textContent = lab(top / 2);
	void n;
}
function renderFoot(net) {
	var t = 'Arteria ' + VERSION + ' · samples every ' + A.interval + ' s only while this page is open';
	if (net.ms !== undefined && net.ms > 0) t += ' · last sample ' + net.ms + ' ms';
	if (net.router.load) t += ' · router load ' + net.router.load;
	$('arFootTx').textContent = t;
}

/* ---------------------------------------------------------------- page controls */
function setTab(t) {
	A.tab = t; store('tab', t);
	$('arTabMap').className = t === 'map' ? 'on' : ''; $('arTabFlow').className = t === 'flow' ? 'on' : '';
	$('arTabMap').setAttribute('aria-selected', t === 'map' ? 'true' : 'false'); $('arTabFlow').setAttribute('aria-selected', t === 'flow' ? 'true' : 'false');
	$('arMap').className = 'ar-view' + (t === 'map' ? ' on' : ''); $('arFlow').className = 'ar-view' + (t === 'flow' ? ' on' : '');
	render();
}
function setMode(m) { A.mode = m; store('mode', m); render(); }
function setUnit(u) {
	A.unit = u === 'MB' ? 'MB' : 'Mb'; store('unit', A.unit);
	$('arUnitMb').className = A.unit === 'Mb' ? 'on' : ''; $('arUnitMB').className = A.unit === 'MB' ? 'on' : '';
	$('arUnitMb').setAttribute('aria-pressed', A.unit === 'Mb' ? 'true' : 'false'); $('arUnitMB').setAttribute('aria-pressed', A.unit === 'MB' ? 'true' : 'false');
	render();
}
function togglePause() {
	A.paused = !A.paused;
	if (A.paused) { suspend(); stopBeacon(); } else resume();
	render();
}
function boot() {
	$('arPackets').textContent = packetCss();
	A.tab = store('tab') === 'flow' ? 'flow' : 'map';
	A.mode = store('mode') === 'up' ? 'up' : 'dn';
	$('arUnitMb').addEventListener('click', function () { setUnit('Mb'); });
	$('arUnitMB').addEventListener('click', function () { setUnit('MB'); });
	setUnit(store('unit'));
	$('arTabMap').addEventListener('click', function () { setTab('map'); });
	$('arTabFlow').addEventListener('click', function () { setTab('flow'); });
	$('arLive').addEventListener('click', togglePause);
	$('arDn').addEventListener('click', function () { setMode('dn'); });
	$('arUp').addEventListener('click', function () { setMode('up'); });
	for (var i = 0; i < 4; i++) (function (btn) { btn.addEventListener('click', function () { if (btn._id) pick(btn._id); }); })($('arTop' + i));
	document.addEventListener('visibilitychange', function () { if (document.hidden) { suspend(); } else if (!A.paused) resume(); });
	window.addEventListener('pagehide', stopBeacon);
	setTab(A.tab);
	loadNames();
	resume();
}
function initial() {
	/* The firmware draws its menu here. If that ever fails, still show our page. */
	try { if (typeof show_menu === 'function') show_menu(); }
	catch (e) { if (window.console) console.error('Arteria: show_menu() failed', e); }
	boot();
}
window.initial = initial;
window.Arteria = { state: A, render: render, onSample: onSample, buildNet: buildNet, parseNames: parseNames, pick: pick, setTab: setTab, setMode: setMode };
})();
</script>
</head>
<body onload="initial();" class="bg">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="current_page" value=""/>
<input type="hidden" name="next_page" value=""/>
<input type="hidden" name="group_id" value=""/>
<input type="hidden" name="modified" value="0"/>
<input type="hidden" name="action_mode" value="apply"/>
<input type="hidden" name="action_wait" value="3"/>
<input type="hidden" name="first_time" value=""/>
<input type="hidden" name="action_script" value=""/>
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>"/>
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>"/>
<table class="content" align="center" cellpadding="0" cellspacing="0">
<tr>
<td width="17">&nbsp;</td>
<td valign="top" width="202">
<div id="mainMenu"></div>
<div id="subMenu"></div>
</td>
<td valign="top">
<div id="tabMenu" class="submenuBlock"></div>
<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
<tr>
<td align="left" valign="top">
<table width="760px" border="0" cellpadding="5" cellspacing="0" class="FormTitle" id="FormTitle">
<tr>
<td bgcolor="#4D595D" colspan="3" valign="top">
<div>&nbsp;</div>
<div class="formfonttitle">Arteria</div>
<div style="margin:10px 0 10px 5px;" class="splitLine"></div>
<div class="formfontdesc">Live traffic between the internet, your router, its AiMesh nodes and every client. The router samples only while this page is open.</div>

<div id="ar">
	<div class="ar-bar">
		<nav class="ar-tabs" aria-label="Arteria views">
			<button type="button" id="arTabMap" class="on" aria-selected="true">Map</button>
			<button type="button" id="arTabFlow" aria-selected="false">Flow</button>
		</nav>
		<div class="ar-sum" id="arSum"></div>
		<div class="ar-unit" role="group" aria-label="Show rates in"><button type="button" id="arUnitMb" class="on" aria-pressed="true" title="Megabits per second, the unit internet plans and speed tests use">Mb/s</button><button type="button" id="arUnitMB" aria-pressed="false" title="Megabytes per second, the unit file downloads show (8 times smaller)">MB/s</button></div>
		<button type="button" class="ar-live warn" id="arLive" aria-pressed="false" title="Pause or resume. While paused, the router stops sampling."><span class="dot"></span><span id="arLiveTxt">Connecting…</span></button>
	</div>

	<div class="ar-stage">
		<!-- ============ MAP ============ -->
		<div class="ar-view on" id="arMap">
			<div id="arMapScene"></div>
			<div class="ar-over" style="left:16px;top:14px;width:224px">
				<div class="eyebrow">Live map</div>
				<div style="margin-top:4px">Pipes are cables, arcs are Wi-Fi. Each packet is traffic in motion; they grow and bunch up as throughput rises.</div>
			</div>
			<div class="ar-over ar-legend" style="right:16px;top:14px">
				<div><span class="sw" style="background:#59c3ff"></span>Download, toward the device</div>
				<div><span class="sw" style="background:#ff8a3d"></span>Upload, toward the internet</div>
				<div><span class="sw" style="background:#a99cf5"></span>AiMesh backhaul</div>
			</div>
			<div id="arMapLabels"></div>
			<div class="ar-over ar-notice" id="arNoticeMap" style="left:16px;bottom:12px"><span class="sw"></span><span class="tx">Starting the sampler on the router…</span></div>
		</div>
		<!-- ============ FLOW ============ -->
		<div class="ar-view" id="arFlow">
			<div id="arFlowScene"></div>
			<div class="ar-flowbar">
				<div class="ar-seg" role="group" aria-label="Direction">
					<button type="button" id="arDn" class="on-dn" aria-pressed="true">↓ Download</button>
					<button type="button" id="arUp" aria-pressed="false">↑ Upload</button>
				</div>
				<div class="ar-notice" id="arNoticeFlow" style="flex:1 1 0;min-width:0"><span class="sw"></span><span class="tx"></span></div>
				<div class="ar-scale"><span class="sw" id="arScaleSw"></span><span id="arScaleTx"></span></div>
			</div>
			<div id="arFlowRows"></div>
		</div>
	</div>

	<div class="ar-cards">
		<div class="ar-card ar-readout" id="arReadout">
			<div class="ar-ro-head"><div class="eyebrow">Live readout</div><div class="ar-badge" id="arRoBadge"></div></div>
			<div class="ar-ro-id"><div class="ar-ico" id="arRoIcon"></div><div style="min-width:0"><div class="ar-ro-name" id="arRoName">Whole network</div><div class="ar-ro-link" id="arRoLink"></div></div></div>
			<div class="ar-metrics">
				<div class="ar-metric"><div class="top"><span class="lbl">↓ Download</span><span class="num c-dn" id="arRoDnN">—</span><span class="unit" id="arRoDnU"></span></div>
					<div class="ar-track"><div id="arRoDnW" style="background:#59c3ff"></div></div><div class="share" id="arRoDnS"></div></div>
				<div class="ar-metric"><div class="top"><span class="lbl">↑ Upload</span><span class="num c-up" id="arRoUpN">—</span><span class="unit" id="arRoUpU"></span></div>
					<div class="ar-track"><div id="arRoUpW" style="background:#ff8a3d"></div></div><div class="share" id="arRoUpS"></div></div>
			</div>
			<div class="ar-stats">
				<div class="ar-stat" style="width:92px;flex:none"><span class="k" id="arRoK1"></span><span class="v" id="arRoV1"></span></div>
				<div class="ar-stat" style="width:84px;flex:none"><span class="k" id="arRoK2"></span><span class="v" id="arRoV2"></span></div>
				<div class="ar-stat" style="flex:1 1 0"><span class="k">Path</span><span class="v" id="arRoPath"></span></div>
			</div>
			<div class="ar-note" id="arRoNote"></div>
		</div>
		<div class="ar-card ar-side" id="arTop">
			<div class="eyebrow" style="padding:0 8px">Busiest right now</div>
			<div class="ar-top">
				<button type="button" id="arTop0" class="hide" aria-pressed="false"><span class="ic"></span><span style="flex:1 1 0;min-width:0"><span class="nm"></span><span class="bar"><span></span></span></span><span class="rt"><span class="rd c-dn"></span><span class="ru c-up"></span></span></button>
				<button type="button" id="arTop1" class="hide" aria-pressed="false"><span class="ic"></span><span style="flex:1 1 0;min-width:0"><span class="nm"></span><span class="bar"><span></span></span></span><span class="rt"><span class="rd c-dn"></span><span class="ru c-up"></span></span></button>
				<button type="button" id="arTop2" class="hide" aria-pressed="false"><span class="ic"></span><span style="flex:1 1 0;min-width:0"><span class="nm"></span><span class="bar"><span></span></span></span><span class="rt"><span class="rd c-dn"></span><span class="ru c-up"></span></span></button>
				<button type="button" id="arTop3" class="hide" aria-pressed="false"><span class="ic"></span><span style="flex:1 1 0;min-width:0"><span class="nm"></span><span class="bar"><span></span></span></span><span class="rt"><span class="rd c-dn"></span><span class="ru c-up"></span></span></button>
				<div id="arTopEmpty" class="ar-empty">Nothing is moving yet.</div>
			</div>
		</div>
		<div class="ar-card ar-hist hide" id="arHist">
			<div class="eyebrow">Internet · last 2 min</div>
			<div class="vals"><span><span class="l">↓ </span><span class="n c-dn" id="arHDnN">—</span> <span class="u" id="arHDnU"></span></span><span><span class="l">↑ </span><span class="n c-up" id="arHUpN">—</span> <span class="u" id="arHUpU"></span></span></div>
			<svg width="244" height="116" viewBox="0 0 244 116" role="img" aria-label="Internet throughput over the last two minutes" style="display:block">
				<path d="M0 14 H244 M0 55 H244" style="fill:none;stroke:rgba(255,255,255,.1);stroke-width:1;stroke-dasharray:3 4"/>
				<path d="M0 96 H244" style="fill:none;stroke:rgba(255,255,255,.2);stroke-width:1"/>
				<text id="arSpTop" x="0" y="11" style="font-size:9.5px;fill:#93a9b1"></text>
				<text id="arSpMid" x="0" y="52" style="font-size:9.5px;fill:#93a9b1"></text>
				<path id="arSpArea" d="M0 0" style="fill:#59c3ff;fill-opacity:.16"/>
				<path id="arSpDn" d="M0 0" style="fill:none;stroke:#59c3ff;stroke-width:1.6;stroke-linejoin:round"/>
				<path id="arSpUp" d="M0 0" style="fill:none;stroke:#ff8a3d;stroke-width:1.5;stroke-linejoin:round"/>
				<circle id="arSpDot" cx="-10" cy="-10" r="3" style="fill:#59c3ff"/>
				<circle id="arSpRip" cx="-10" cy="-10" r="3" class="df-a df-ripple" style="fill:none;stroke:#59c3ff;stroke-width:1.2"/>
				<text x="0" y="112" style="font-size:9.5px;fill:#93a9b1">2 min ago</text>
				<text x="244" y="112" style="font-size:9.5px;fill:#93a9b1;text-anchor:end">now</text>
			</svg>
		</div>
	</div>
	<div class="ar-foot"><span id="arFootTx">Arteria</span><a href="https://github.com/IfSugar/arteria" target="_blank" rel="noopener">GitHub</a></div>
</div>
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
<td width="10" align="center" valign="top">&nbsp;</td>
</tr>
</table>
</form>
<form method="post" name="formScriptActions" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="productid" value="<% nvram_get("productid"); %>"/>
<input type="hidden" name="current_page" value=""/>
<input type="hidden" name="next_page" value=""/>
<input type="hidden" name="action_mode" value="apply"/>
<input type="hidden" name="action_script" value=""/>
<input type="hidden" name="action_wait" value=""/>
</form>
<div id="footer"></div>
</body>
</html>
