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
#ar .ar-bar { display: flex; align-items: center; gap: 10px; height: 46px; border-bottom: 1px solid #7d8c90; margin: 4px 0 12px; }
#ar .ar-tabs { display: flex; gap: 10px; align-self: stretch; }
#ar .ar-tabs button { background: none; border: 0; border-bottom: 2px solid transparent; color: #e3eaec; font-size: 13px; padding: 0 6px; min-width: 44px; margin-bottom: -1px; }
#ar .ar-tabs button:hover { color: #fff; }
#ar .ar-tabs button.on { color: #fff; border-bottom-color: var(--accent); font-weight: 600; cursor: default; }
#ar .ar-sum { flex: 1; display: flex; align-items: baseline; justify-content: flex-end; gap: 12px; white-space: nowrap; font-variant-numeric: tabular-nums; color: var(--ink); }
#ar .ar-sum .k { color: #e3eaec; }
#ar .ar-sum b { font-weight: 600; }
#ar .ar-sum .v { display: inline-block; min-width: 10.6ch; }   /* room for the widest number ("↓ 99.9 MB/s"), so nothing moves as numbers change */
#ar .ar-sum .n { display: inline-block; min-width: 9.6ch; text-align: right; }
#ar .ar-sum .dn { color: var(--dnt); font-weight: 700; }
#ar .ar-sum .up { color: var(--upt); font-weight: 700; }
/* Every pill-shaped control is the same: 44px tall overall, a dark fill, the same border, 12px text, 14px sides */
#ar .ar-unit { display: flex; flex: none; height: 44px; border: 1px solid #6b7b80; border-radius: 22px; overflow: hidden; background: var(--surface); }
#ar .ar-unit button { background: none; border: 0; margin: 0; padding: 0 14px; min-width: 44px; color: #c3c2b7; font-size: 12px; font-weight: 600; font-variant-numeric: tabular-nums; }
#ar .ar-unit button:hover { color: #fff; }
#ar .ar-unit button.on { background: #3a4549; color: #fff; cursor: default; }
#ar .ar-live { min-height: 44px; padding: 0 14px; display: flex; align-items: center; gap: 8px; border-radius: 22px; border: 1px solid #6b7b80; background: var(--surface); color: var(--ink); font-size: 12px; font-weight: 600; white-space: nowrap; flex: none; }
#ar .ar-live .dot { width: 8px; height: 8px; border-radius: 4px; background: var(--muted); flex: none; }
#ar .ar-live.live .dot { background: #3ddc97; animation: arblink 1.6s ease-in-out infinite; }
#ar .ar-live.warn .dot { background: var(--accent); }
#ar .ar-ibtn { width: 44px; height: 44px; flex: none; margin: 0; padding: 0; display: flex; align-items: center; justify-content: center; border-radius: 22px; border: 1px solid #6b7b80; background: var(--surface); color: var(--ink); }
#ar .ar-ibtn:hover { background: #3a4549; }
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
#ar .ar-lb .x { font-size: 10px; line-height: 12px; color: var(--muted); overflow: hidden; text-overflow: ellipsis; font-variant-numeric: tabular-nums; }
#ar .ar-lb.x3 > span { height: 46px; }
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
#ar #arRoTraffic { display: flex; flex-direction: column; gap: 10px; }
#ar .ar-ro-tools { display: flex; align-items: center; gap: 6px; }
#ar .ar-det { position: relative; height: 20px; margin: -2px 0; padding: 0 8px; border-radius: 10px; border: 1px solid var(--axis); background: transparent; color: var(--ink-2); font-size: 10.5px; }
#ar .ar-det::before { content: ""; position: absolute; inset: -12px -6px; }
#ar .ar-det:hover { color: #fff; }
#ar .ar-det.on { border-color: var(--accent); color: #fff; }
#ar .ar-details { display: grid; grid-template-columns: minmax(0, .9fr) minmax(0, 1.35fr) minmax(0, 1fr) minmax(0, .95fr); gap: 8px 12px; align-content: start; flex: 1 1 0; min-height: 0; }
#ar .ar-details .ar-stat .v { font-size: 11.5px; -webkit-user-select: text; user-select: text; }
#ar .ar-note { font-size: 11px; line-height: 15px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; color: var(--ink-2); }
#ar .ar-side { flex: 1 1 0; padding: 12px 8px 6px; display: flex; flex-direction: column; gap: 6px; }
#ar .ar-top button { height: 44px; width: 100%; margin: 0; padding: 0 8px; display: flex; align-items: center; gap: 9px; border-radius: 8px; border: 1px solid transparent; background: transparent; color: var(--ink); text-align: left; min-width: 0; }
#ar .ar-top button:hover { background: rgba(255,255,255,.04); }
#ar .ar-top button.on { border-color: var(--accent); background: #3a4549; }
#ar .ar-top .nm { font-size: 12px; line-height: 14px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: block; }
#ar .ar-top .bar { display: block; height: 3px; border-radius: 2px; background: #1a2225; margin-top: 5px; }
#ar .ar-top .bar > span { display: block; height: 3px; border-radius: 2px; background: var(--dn); width: 0; transition: width .4s ease; }
#ar .ar-top .rt { display: flex; flex-direction: column; align-items: flex-end; gap: 1px; font-size: 11px; line-height: 14px; font-variant-numeric: tabular-nums; white-space: nowrap; flex: none; }
#ar .ar-more-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; height: 16px; padding: 0 0 0 8px; }
#ar .ar-x { width: 44px; height: 44px; margin: -14px -8px -14px 0; border: 0; background: transparent; color: var(--ink-2); font-size: 18px; line-height: 1; border-radius: 8px; }
#ar .ar-x:hover { color: #fff; }
#ar .ar-more-list button { height: 40px; }
#ar .ar-more-list { flex: 1 1 0; min-height: 0; overflow-y: auto; overscroll-behavior: contain; scrollbar-width: thin; scrollbar-color: #4a585d transparent; }
#ar .ar-more-list::-webkit-scrollbar { width: 6px; } #ar .ar-more-list::-webkit-scrollbar-thumb { background: #4a585d; border-radius: 3px; }
#ar .ar-empty { padding: 8px; color: var(--muted); font-size: 11.5px; }
#ar .ar-hist { flex: 1 1 0; padding: 14px 16px; display: flex; flex-direction: column; gap: 10px; }
#ar .ar-hist .vals { display: flex; gap: 16px; height: 22px; }
#ar .ar-hist .vals span.n { font-size: 18px; line-height: 22px; font-weight: 700; font-variant-numeric: tabular-nums; }
#ar .ar-hist .vals span.u, #ar .ar-hist .vals span.l { font-size: 11px; color: var(--muted); }
#ar .ar-flowbar { position: absolute; left: 12px; top: 10px; right: 16px; height: 44px; display: flex; align-items: center; gap: 14px; }
#ar .ar-seg { display: flex; height: 44px; border-radius: 22px; border: 1px solid #6b7b80; overflow: hidden; flex: none; background: var(--surface); }
#ar .ar-seg button { height: 42px; margin: 0; padding: 0 14px; border: 0; background: transparent; color: var(--ink-2); font-size: 12px; font-weight: 600; white-space: nowrap; }
#ar .ar-seg button.on-dn { background: #1f4a63; color: var(--dnt); }
#ar .ar-seg button.on-up { background: #5a3520; color: var(--upt); }
#ar .ar-scale { display: flex; align-items: center; gap: 7px; flex: none; font-size: 11px; color: var(--ink-2); font-variant-numeric: tabular-nums; white-space: nowrap; }
#ar .ar-scale .sw { width: 4px; height: 24px; border-radius: 2px; background: var(--dn); }
#ar .ar-row { position: absolute; margin: 0; padding: 0 6px; display: flex; align-items: center; gap: 6px; border-radius: 8px; border: 1px solid transparent; background: rgba(255,255,255,.035); color: var(--ink); text-align: left; overflow: hidden; }
#ar .ar-row.on { border-color: var(--accent); background: #3a4549; }
#ar .ar-row.off { opacity: .6; }
#ar .ar-row .tx { flex: 1 1 0; min-width: 0; display: flex; flex-direction: column; gap: 1px; }
#ar .ar-row .nm { font-size: 12px; line-height: 15px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
#ar .ar-row .sb { font-size: 10.5px; line-height: 13px; color: var(--muted); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
#ar .ar-row .vl { display: flex; flex-direction: column; align-items: flex-end; gap: 1px; flex: none; }
#ar .ar-row .vl .n { font-size: 13px; line-height: 15px; font-weight: 700; font-variant-numeric: tabular-nums; }
#ar .ar-row .vl .u { font-size: 10px; line-height: 13px; color: var(--muted); }
#ar .ar-row .cx { flex: none; font-size: 11px; color: var(--ink-2); text-align: right; white-space: nowrap; font-variant-numeric: tabular-nums; }
#ar .ar-row .c1 { width: 56px; } #ar .ar-row .c2 { width: 70px; }
#ar .ar-fscroll { position: absolute; left: 0; top: 0; right: 0; bottom: 0; }
#ar .ar-foot { margin-top: 8px; color: var(--muted); font-size: 11px; display: flex; justify-content: space-between; gap: 10px; }
#ar .ar-foot a { color: var(--muted); }
#ar .ar-foot-r { display: flex; gap: 14px; }
#ar .ar-link { border: 0; background: none; padding: 0; color: var(--muted); font: inherit; text-decoration: underline; cursor: pointer; }
#ar .ar-link:hover, #ar .ar-foot a:hover { color: var(--ink-2); }
#ar .ar-side.ar-report { flex: 1 1 0; width: auto; }
#ar .ar-report textarea { flex: 1 1 0; min-height: 0; margin: 0 4px; resize: none; border: 1px solid var(--line); border-radius: 8px; background: #1f272a; color: var(--ink-2);
	font: 10px/14px ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; padding: 6px 8px; white-space: pre; overflow: auto; }
#ar .hide { display: none !important; }
/* The expanded view: the same page, over the router's own, filling the window. Cards move to a column on
   the right (below the stage under 1180 px). */
#ar.big { position: fixed; left: 0; top: 0; right: 0; bottom: 0; z-index: 9000; width: auto; margin: 0; padding: 8px 16px 10px; background: #4d595d; overflow: auto;
	display: grid; grid-template-areas: "bar bar" "stage cards" "foot foot"; grid-template-rows: auto 1fr auto; grid-template-columns: minmax(0, 1fr) 372px; column-gap: 12px; }
#ar.big .ar-bar { grid-area: bar; } #ar.big .ar-stage { grid-area: stage; align-self: start; } #ar.big .ar-foot { grid-area: foot; }
#ar.big .ar-cards { grid-area: cards; flex-direction: column; height: auto; margin-top: 0; min-height: 0; overflow: hidden; }
#ar.big .ar-readout { width: auto; flex: none; }
#ar.big .ar-details { grid-template-columns: minmax(0, 1fr) minmax(0, 1.3fr); flex: none; }
#ar.big .ar-side, #ar.big .ar-hist { flex: 1 1 0; min-height: 0; }
#ar.big #arTop .ar-top { flex: 1 1 0; min-height: 0; overflow-y: auto; scrollbar-width: thin; scrollbar-color: #4a585d transparent; }
#ar.big:not(.narrow) #arHist svg { width: 100%; height: auto; }
#ar.big .ar-fscroll { overflow-y: auto; overscroll-behavior: contain; scrollbar-width: thin; scrollbar-color: #4a585d transparent; }
#ar.big .ar-scale { margin-left: auto; }
#ar.big .ar-flowbar { left: 0; right: 10px; top: 0; height: 54px; padding: 10px 6px 0 12px; background: var(--surface); z-index: 1; }
#ar.big.narrow { grid-template-areas: "bar" "stage" "cards" "foot"; grid-template-rows: auto auto auto auto; grid-template-columns: minmax(0, 1fr); }
#ar.big.narrow .ar-cards { flex-direction: row; height: 224px; margin-top: 12px; }
#ar.big.narrow .ar-readout { width: 440px; }
#ar.big.narrow .ar-details { grid-template-columns: minmax(0, .9fr) minmax(0, 1.35fr) minmax(0, 1fr) minmax(0, .95fr); }
/* Animation: CSS only, so the browser does the work and the router just answers a poll every 2 s. */
#ar .df-a { animation-timing-function: linear; animation-iteration-count: infinite; }
#ar .df-led { animation-name: arled; }
#ar .df-ripple { transform-box: fill-box; transform-origin: center; animation-name: arripple; animation-duration: 2.6s; animation-timing-function: ease-out; }
#ar.paused .df-a, #ar.paused .ar-live .dot { animation-play-state: paused !important; }
#ar .lk, #ar .ob, #ar .rb { transition: opacity .3s ease; }
#ar .ob { cursor: pointer; }
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
	net: null, mapSig: '', flowSig: '', slot: {}, slotAt: 0, flowPick: null, flowMem: {}, flowK: {},
	hist: [], timers: {}, mapRefs: null, flowRefs: null, big: false, narrow: false, slotBy: {}
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
	console: rr(3, 8, 18, 9, 4.5) + 'M8 11v3M6.5 12.5h3M15.5 12h.01M17.5 13.5h.01',
	generic: rr(4, 7, 16, 10, 2) + 'M8 12h.01M12 12h4',
	switch: rr(2.5, 8, 19, 8, 1.5) + 'M6 12h.01M9 12h.01M12 12h.01M15 12h.01M18 12h.01',
	desktop: rr(2.5, 6, 12, 9, 1.5) + 'M6 19h5M8.5 15v4' + rr(17, 4, 4.5, 16, 1.2) + 'M19.25 7.5h.01',
	mac: rr(3, 3, 18, 11, 1.5) + rr(7, 17, 10, 4, 1.5) + 'M9.5 19h.01',
	light: 'M9.5 18h5M10.5 21h3M12 3a6 6 0 0 0-3.7 10.7c.7.6 1.2 1.3 1.2 2.3h5c0-1 .5-1.7 1.2-2.3A6 6 0 0 0 12 3z',
	air: rr(3, 5, 18, 8, 2) + 'M6.5 10h11M8 16v2M12 16v3.5M16 16v2',
	speaker: rr(6.5, 3, 11, 18, 2.5) + ci(12, 14, 3) + 'M12 7.5h.01',
	printer: 'M7 8V4h10v4' + rr(3.5, 8, 17, 8, 2) + 'M7 13.5h10V20H7z',
	watch: rr(7, 7, 10, 10, 2.5) + 'M9.2 7l.6-3.5h4.4l.6 3.5M9.2 17l.6 3.5h4.4l.6-3.5M12 10v2.2l1.4.9',
	camera: rr(3, 7, 12.5, 10, 2) + 'M15.5 10.5l5.5-2.5v8l-5.5-2.5',
	repeater: rr(7, 3, 10, 13, 2.5) + 'M10 16v4.5M14 16v4.5M10 7.5a3 3 0 0 1 4 0M12 11h.01',
	cube: rr(5, 8, 14, 11, 2.5) + 'M9.5 12.5a3.5 3.5 0 0 1 5 0M12 15.5h.01',
	puck: 'M3 13c0-2.2 4-4 9-4s9 1.8 9 4-4 4-9 4-9-1.8-9-4zM3 13v2.5c0 2.2 4 4 9 4s9-1.8 9-4V13M10 5.5a3 3 0 0 1 4 0',
	streamer: rr(4, 9, 16, 7, 2) + 'M7.5 12.5h.01M4 20h16',
	soundbar: rr(2.5, 9, 19, 6, 2) + 'M6 12h.01M9.5 12h8',
	doorbell: rr(8, 3, 8, 18, 2.5) + ci(12, 8, 1.6) + ci(12, 15.5, 1.2),
	lock: rr(5, 10.5, 14, 10, 2) + 'M8.5 10.5V7.5a3.5 3.5 0 0 1 7 0v3M12 14.5v2',
	sensor: ci(12, 12, 3) + 'M5.6 7.5a8 8 0 0 0 0 9M18.4 7.5a8 8 0 0 1 0 9',
	thermostat: ci(12, 12, 8.5) + 'M12 12l3-3.5M8 16.5h8',
	plug: 'M9 3v5M15 3v5' + rr(6, 8, 12, 7, 2) + 'M12 15v6',
	hub: rr(4, 13, 16, 6, 2) + 'M8 16h.01M12 16h.01M16 16h.01M8.5 9.5a5 5 0 0 1 7 0M10.6 11.4a2 2 0 0 1 2.8 0',
	vacuum: ci(12, 12, 8.5) + ci(12, 9, 2) + 'M9.5 16.5h5',
	appliance: rr(5, 3, 14, 18, 2) + ci(12, 13.5, 3.5) + 'M8 6.5h.01M11 6.5h5',
	washer: rr(5, 3, 14, 18, 2) + ci(12, 13.5, 3.5) + 'M8 6.5h.01M11 6.5h5M10 14.5c.7-.6 1.3-.6 2 0s1.3.6 2 0',
	dryer: rr(5, 3, 14, 18, 2) + ci(12, 13.5, 3.5) + 'M8 6.5h.01M11 6.5h5M10.5 12.5h3M10.5 14.5h3',
	dishwasher: rr(5, 3, 14, 18, 2) + 'M5 8.5h14M8 6h.01M11 6h5M9 11.5h6',
	iot: rr(5, 5, 14, 14, 3) + 'M12 9.5v2.5M12 14.5h.01',
	pi: rr(2.5, 6, 19, 12, 2) + rr(8.5, 10, 5, 5, 1) + 'M5.5 8.5h7' + rr(16, 9.5, 3.5, 6, .8),
	stick: rr(2.5, 9, 13.5, 6, 2) + 'M16 10.5h3.5v3H16M6 12h.01',
	smartspeaker: 'M6 5.5c0-1.4 2.7-2.5 6-2.5s6 1.1 6 2.5v13c0 1.4-2.7 2.5-6 2.5s-6-1.1-6-2.5zM6 5.5c0 1.4 2.7 2.5 6 2.5s6-1.1 6-2.5',
	purifier: rr(6.5, 3, 11, 18, 3.5) + 'M9.5 6.5h5M9.5 10v5M12 10v5M14.5 10v5' + rr(8.5, 16.5, 7, 2.5, .8),
	wallswitch: rr(4, 4, 16, 16, 2.5) + rr(9, 7, 6, 10, 1.5) + 'M12 9v2',
	contact: rr(3.5, 5, 6, 14, 1.5) + rr(12, 8, 3.5, 8, 1) + 'M6.5 8.5h.01M19.5 3v18',
	charger: rr(4, 3, 10, 13, 2) + 'M9.6 6l-2 3.5h3l-2 3.5M9 16v2a3 3 0 0 0 3 3h4a3 3 0 0 0 3-3v-6' + rr(17.2, 8, 3.6, 4, .8),
	car: 'M5 17H3.5v-4l2.2-4.5a1.5 1.5 0 0 1 1.3-.8h10a1.5 1.5 0 0 1 1.3.8l2.2 4.5v4H19M3.5 13h17M9.5 17h5' + ci(7.5, 17, 2) + ci(16.5, 17, 2),
	solar: 'M3 15l2.5-9h13l2.5 9zM4.3 10.5h15.4M9.5 6l-1.3 9M14.5 6l1.3 9M12 15v5M8.5 20h7',
	mower: 'M3.5 16c0-4.1 3.8-7.5 8.5-7.5s8.5 3.4 8.5 7.5zM12 8.5V6.5M10.5 5.2h3' + ci(7, 18, 2) + ci(17, 18, 2),
	vr: 'M3 10.5A2.5 2.5 0 0 1 5.5 8h13a2.5 2.5 0 0 1 2.5 2.5v4a2.5 2.5 0 0 1-2.5 2.5h-3.6l-1.4-2.2h-3l-1.4 2.2H5.5A2.5 2.5 0 0 1 3 14.5zM1.5 12H3M21 12h1.5',
	projector: rr(2.5, 8.5, 19, 8.5, 2) + ci(15.5, 12.75, 2.5) + 'M6 11.5h4M6 14h2.5M5 17v2M19 17v2M15.5 6V4M19 6.5l1.4-1.4M12 6.5l-1.4-1.4',
	garage: 'M3 21V9.5l9-5.5 9 5.5V21M7 21v-8.5h10V21M7 15.3h10M7 18.1h10',
	printer3d: 'M3 21h18M5 21V3.5h14V21M5 8.5h14' + rr(10, 8.5, 4, 3.2, .6) + 'M12 11.7v1.3' + rr(9.5, 15, 5, 6, 1),
	display: rr(3, 3.5, 18, 11.5, 2) + 'M5.5 15l-1.5 5.5h16L18.5 15M7 7.5h5M7 10.5h3',
	blinds: 'M3 4h18M5 4v10.5h14V4M5 7.5h14M5 11h14M16 14.5V18' + ci(16, 19.4, 1.4),
	sprinkler: 'M9.5 21h5M11 21v-5h2v5M12 16c-1.2-3.8-4.3-6.6-8-7M12 16c1.2-3.8 4.3-6.6 8-7M12 16V7.5M5 13.5h.01M19 13.5h.01M8.5 6.5h.01M15.5 6.5h.01',
	pet: 'M4 16h16l-1.4 3.8a2 2 0 0 1-1.9 1.2H7.3a2 2 0 0 1-1.9-1.2z' + ci(12, 10.2, 2.2) + ci(7.2, 7.6, 1.3) + ci(10.1, 4.2, 1.3) + ci(13.9, 4.2, 1.3) + ci(16.8, 7.6, 1.3),
	fitness: rr(4.5, 6.5, 3.2, 11, 1) + rr(16.3, 6.5, 3.2, 11, 1) + 'M2.5 9.5v5M21.5 9.5v5M7.7 12h8.6',
	more: ci(6, 12, 1.6) + ci(12, 12, 1.6) + ci(18, 12, 1.6),
	expand: 'M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5',
	collapse: 'M9 4v5H4M15 4v5h5M9 20v-5H4M15 20v-5h5',
	full: rr(3, 5, 18, 14, 2) + 'M7 10V8.5h2M17 10V8.5h-2M7 14v1.5h2M17 14v1.5h-2'
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
	try { localStorage.removeItem('arteria.open.' + TAB_ID); } catch (e) { /* no storage: nothing to clean up */ }
	if (otherTabLive()) return;   /* another Arteria tab is still watching: let it keep the router sampling */
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
	store('open.' + TAB_ID, String(Date.now()));   /* "this tab is sampling", for the other Arteria tabs of this browser */
	A.timers.hb = setTimeout(heartbeat, 8000);
}
/* Two Arteria tabs open: when one closes, it mustn't stop the sampling the other one is watching. Each tab notes
   its last heartbeat in this browser's storage; a tab that goes away only says "stop" if no other one is live. */
var TAB_ID = Math.random().toString(36).slice(2, 10);
function otherTabLive() {
	var live = false;
	try {
		for (var i = localStorage.length - 1; i >= 0; i--) {
			var k = localStorage.key(i);
			if (!k || k.indexOf('arteria.open.') !== 0 || k === 'arteria.open.' + TAB_ID) continue;
			var age = Date.now() - (+localStorage.getItem(k) || 0);
			if (age < 12000) live = true;
			else if (age > 120000) localStorage.removeItem(k);   /* a tab that closed without saying so */
		}
	} catch (e) { return false; }
	return live;
}
function poll() {
	clearTimeout(A.timers.poll);
	if (!running()) return;
	getJSON('live.htm').then(onSample, function () { onSample(null); }).then(null, logErr).then(function () {
		A.timers.poll = setTimeout(poll, Math.max(1, A.interval) * 1000);
	});
	if (Date.now() - A.namesAt > 30000) loadNames();
}
function loadNames() {
	A.namesAt = Date.now();
	getJSON('names.htm').then(function (n) { A.names = parseNames(n); A.namesAt = Date.now(); }, function () {});
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
var JUNK_NAME = /^(dhcpcd|android-dhcp|udhcp|unknown|client|localhost|espressif|esp[_-]|wlan|\*|-)|:|^[0-9a-f]{10,}$/i;
function parseNames(n) {
	var out = { custom: {}, nmp: {}, lease: {}, cl: n && n.cl || {}, arp: {}, n6: {}, fixed: {} };
	String(n && n.custom || '').split('<').forEach(function (e) {
		var f = e.split('>');
		if (f.length >= 2 && /^[0-9A-Fa-f:]{17}$/.test(f[1])) out.custom[f[1].toUpperCase()] = { name: f[0], type: +f[3] || 0 };
	});
	var nmp = n && n.nmp || {};
	Object.keys(nmp).forEach(function (k) { if (nmp[k]) out.nmp[k.toUpperCase()] = nmp[k]; });
	String(n && n.leases || '').split('|').forEach(function (l) {
		var f = l.split(' ');
		if (f.length >= 4 && /^[0-9A-Fa-f:]{17}$/.test(f[1])) out.lease[f[1].toUpperCase()] = { exp: f[0], ip: f[2], host: f[3] === '*' ? '' : f[3], cid: f[4] || '' };   /* "*": no host name */
	});
	/* addresses the router has seen without a lease (static ones), IPv6 neighbours (globals first), reservations */
	String(n && n.arp || '').split('|').forEach(function (e) { var f = e.split(' '); if (f.length === 2 && /^[0-9A-Fa-f:]{17}$/.test(f[0])) out.arp[f[0].toUpperCase()] = f[1]; });
	String(n && n.n6 || '').split('|').forEach(function (e) {
		var f = e.split(' '), m = (f[0] || '').toUpperCase();
		if (f.length === 2 && /^[0-9A-F:]{17}$/.test(m) && (out.n6[m] = out.n6[m] || []).length < 4) out.n6[m].push(f[1]);
	});
	Object.keys(out.n6).forEach(function (m) { out.n6[m].sort(function (a, b) { return (/^fe80:/i.test(a) ? 1 : 0) - (/^fe80:/i.test(b) ? 1 : 0); }); });
	String(n && n.fixed || '').split('<').forEach(function (e) { var f = e.split('>'); if (/^[0-9A-Fa-f:]{17}$/.test(f[0])) out.fixed[f[0].toUpperCase()] = f[1] || ''; });
	return out;
}
/* A device's label, and where it came from: your nickname, a nickname matched by host name (al, see
   buildAliases), the name the device gave, its maker, or nothing ('tail': buildNet then uses the kind,
   "Light …F5:86", once the device is classified). */
/* The router's client editor fills its name box with what it shows, so saving just an icon can store "dhcpcd-6 8 2 …"
   or the maker's name as a nickname: those aren't yours, and the device's own name is better. */
var JUNK_NICK = /^(dhcpcd|android-dhcp|udhcp|espressif|esp[_-]|unknown|localhost|wlan\d*$)/i;
function nickOf(c, m) {
	var n = String(c && c.name || '').trim(), k = function (s) { return String(s || '').toLowerCase().replace(/[^a-z0-9]/g, ''); }, kn = k(n);
	if (!n || JUNK_NICK.test(n)) return '';
	if (m && kn.length >= 6 && [m.vendor, m.vendorclass].some(function (v) { return v && k(v).indexOf(kn) === 0; })) return '';
	return n;
}
function nameInfo(mac, al) {
	var N = A.names, c = N && N.custom[mac], m = N && N.nmp[mac], l = N && N.lease[mac];
	if (nickOf(c, m)) return { name: nickOf(c, m), src: 'nick' };
	if (al && al.name) return { name: al.name, src: 'alias' };
	if (m && m.name && !JUNK_NAME.test(m.name) && m.name !== m.vendor) return { name: String(m.name).trim(), src: 'device' };
	if (l && l.host && !JUNK_NAME.test(l.host)) return { name: l.host, src: 'device' };
	var v = String(m && (m.vendor || m.vendorclass) || '');
	if (v && !JUNK_NAME.test(v)) return { name: v.replace(/,? (Co\.|Inc\.|Ltd\.|Corp\.|Corporation|Limited|Technology|Technologies|Electronics|Manufacturing|Communication).*$/i, '').trim(), src: 'maker' };
	return { name: 'Device …' + mac.slice(-5), src: 'tail' };
}
/* ---- device kinds ----------------------------------------------------------------------------
   ASUS icon numbers (the "type" in custom_clientlist and in nmp_cl_json.js) -> Arteria kind.
   Source: client_function.js custom_icon_list_api.db and networkmap/db/nmp_*_type.js (3004.388.13). */
var TYPE_KIND = {
	1: 'desktop', 34: 'desktop', 72: 'desktop', 14: 'mac',
	6: 'laptop', 35: 'laptop', 37: 'laptop', 38: 'laptop',
	9: 'phone', 10: 'phone', 19: 'phone', 28: 'phone', 33: 'phone',
	20: 'tablet', 21: 'tablet', 25: 'tablet', 29: 'tablet', 73: 'tablet',
	23: 'tv', 11: 'streamer', 12: 'streamer', 27: 'streamer', 46: 'streamer', 47: 'soundbar',
	43: 'speaker', 44: 'speaker', 45: 'speaker', 48: 'speaker', 81: 'speaker',
	7: 'console', 74: 'console', 75: 'console', 76: 'console', 77: 'console',
	4: 'nas', 2: 'switch', 24: 'switch', 78: 'switch',
	18: 'printer', 26: 'printer',
	5: 'camera', 41: 'camera', 85: 'doorbell', 63: 'lock', 67: 'lock',
	49: 'air', 60: 'light', 61: 'vacuum', 66: 'plug', 70: 'plug',
	62: 'sensor', 68: 'sensor', 69: 'sensor', 64: 'watch', 65: 'watch',
	50: 'appliance', 52: 'appliance', 53: 'appliance', 54: 'appliance', 55: 'appliance', 56: 'appliance', 57: 'appliance', 58: 'appliance', 59: 'appliance',
	51: 'iot', 71: 'iot'
};
/* Icon numbers networkmap hands out from one loose keyword ("mac" -> 6, "win"/"pc"/"nb" -> 1, "desktop" -> 34,
   a DHCP vendor class -> 9/22/30/31): a clear name beats these, even when they were saved with a nickname. */
var TYPE_LOOSE = { 1: 1, 6: 1, 9: 1, 22: 1, 30: 1, 31: 1, 32: 1, 34: 1 };
/* Names that say what a device is. First match wins, so the specific ones come first. */
var KIND_STRONG = [
	['mac', /\bmac[ _-]?(studio|mini|pro)\b|\bimac/i],
	['laptop', /mac[ _-]?book|\bmbp\b|\bmba\b|laptop|notebook|thinkpad|latitude|zenbook|vivobook|ideapad|chromebook|surface|elitebook|probook|\bxps\b|\byoga\b|magicbook|matebook|galaxy[ _-]?book|zephyrus|\bspectre\b/i],
	['pi', /raspberry|\brpi\d*\b|^rpi?\d([-_.]|$)|\bpi[ _-]?[345]\b|pi[ _-]?hole/i],   /* before desktop and nas: a Pi often runs a server */
	['desktop', /^desktop-[a-z0-9]{4,}|^win-[a-z0-9]{6,}|desktop|workstation|\btower\b|\bpc\b|optiplex|\bnuc\b|thinkcentre|prodesk|\bhtpc\b/i],
	['nas', /\bnas\b|synology|diskstation|qnap|dxp\d|truenas|freenas|unraid|terramaster|asustor|ugreen|proxmox|\bserver\b|openmediavault|\bomv\b|xpenology|my[ _-]?cloud|readynas|\bdrobo\b|zimacube|jellyfin|\bplex\b|nextcloud/i],
	['vr', /\bquest[ _-]?\d?\b|oculus|\bvr\b|vision[ _-]?pro|\bpico[ _-]?(neo|[34])\b|\bvive\b|valve[ _-]?index|\bpsvr/i],
	['stick', /fire[ _-]?tv(?![ _-]?(cube|edition|omni))|fire[ _-]?stick|chromecast|roku[ _-]?(stick|express)|streaming[ _-]?stick|\bmi[ _-]?stick/i],
	['streamer', /apple[ _-]?tv|fire[ _-]?tv[ _-]?cube|\bshield\b|\broku\b|set[ -]?top|\bstb\b|\bmi ?box|tv[ _-]?(box|streamer)|android[ _-]?box|\bmag\d{3}\b|formuler|ugoos|homatics|dune[ _-]?hd|zappiti|\bmecool|\bzidoo|\bosmc\b|libreelec|coreelec|\bkodi\b|\btivo|\bsky[ _-]?(q|stream)\b|\bhumax|dreambox|enigma2|\bvu[ _-]?(\+|plus|uno|duo|zero|solo)/i],
	['projector', /projector|beamer|xgimi|\boptoma\b|\bbenq\b|nebula[ _-]?(capsule|mars|cosmos)|dangbei|formovie|\bepson[ _-]?(eh|ef|co|tw)[ _-]?\w|\bvava\b|\bwemax\b|\bvidda\b|hisense[ _-]?(c[12]|pl[12])\b|freestyle|cinebeam|\bjmgo\b/i],
	['soundbar', /sound ?bar|sonos[ _-]?(arc|beam|ray)|playbar|playbase|av[ -]?receiver|\bavr\b|denon(?![ _-]?home)|marantz|yamaha|onkyo|home[ -]?(cinema|theat)|\bhw-[a-z]{1,2}\d{2,3}|\bpolk\b|\barcam\b/i],   /* before TV: "Vizio soundbar" */
	['tv', /\btv\b|tv$|television|bravia|webos|tizen|\b[oq]led|hisense(?![ _-]?(ac|a\/c|air|fridge))|vizio|^(kd|xr|xbr|kdl)[-_]?\d{2}[a-z]|^(qn|un|qe|ue|gq)\d{2}[a-z]|\btcl\b(?![ _-]?(ac|a\/c|air|phone|tab))|viera|aquos|ambilight|vidaa|the[ _-]?frame|grundig|\bmetz\b|loewe/i],   /* with Sony and Samsung model numbers */
	['display', /echo[ _-]?(show|spot|hub)|nest[ _-]?hub|google[ _-]?home[ _-]?hub|smart[ _-]?(display|clock)|\bportal\b|lenovo[ _-]?smart|(photo|picture|digital)[ _-]?frame|nixplay|aura[ _-]?frame|meural|frameo|pix-?star/i],   /* before smart speaker: an Echo Show */
	['smartspeaker', /homepod|\becho\b|echo[ _-]?(dot|pop|studio)|alexa(?!['’]s)|google[ _-]?home|nest[ _-]?(mini|audio)|^amazon-[0-9a-f]{6,}$/i],   /* Amazon's own devices call themselves amazon-<hex>: Echos, most often */
	['speaker', /speaker|sonos|subwoofer|\bsubw\b|\bbose\b|\bheos\b|\bjbl\b|bluesound|\bwiim\b|libratone|bang[ _-]?(&|and)?[ _-]?olufsen|\bbeo(play|sound|lab)|harman|marshall|ultimate[ _-]?ears|\bnaim\b|devialet|\bkef\b|audio[ _-]?pro|volumio|moode|squeezebox|picoreplayer|denon[ _-]?home/i],
	['console', /playstation|\bps[345]\b|xbox|nintendo|steam ?deck|\bswitch[ _-]?(oled|lite)\b|rog[ _-]?ally|legion[ _-]?go|ayaneo|retroid|anbernic|\bwii\b|msi[ _-]?claw/i],
	['fitness', /peloton|\btonal\b|treadmill|exercise|fitness|\browing|\brower\b|concept[ _-]?2|ergometer|hydrow|wahoo|\bkickr|\btacx|\bzwift|elliptical|spin[ _-]?bike|indoor[ _-]?(bike|cycle)|\bechelon|nordictrack|\bifit\b|technogym|bowflex|speediance/i],
	['tablet', /ipad|tablet|[ _-]pad([ _-]|\d|$)|matepad|lenovo[ _-]?tab|kindle|\bkobo\b|e-?reader|paperwhite|galaxy[ _-]?tab|\btab\b|\bsm-[tpx]\d{3}|\bmi[ _-]?pad|\bboox\b|remarkable|supernote|pocketbook|\btolino|\bnook\b|fire[ _-]?(hd|max)/i],
	['watch', /watch\b|fitbit|garmin|\bmi ?band\b|bracelet|\bsm-r\d{3}/i],
	['phone', /iphone|\bpixel[ _-]?\d|galaxy[ _-]?[asz]\d|phone\b|redmi|oneplus|\bpoco\b|galaxy[ _-]?(note|fold|flip|xcover)|\bsm-[asgfmnze]\d{3}|\bmoto[ _-]?(g|e|x|edge|razr|one)\b|motorola[ _-]?(edge|razr|one|moto)|\boppo\b|\bvivo\b|realme|xperia|\bhonor[ _-]?(\d|magic|x\d)|zenfone|fairphone|\bxiaomi[ _-]?\d|\bmi[ _-]?\d{1,2}\b|huawei[ _-]?(p\d|mate|nova|y\d)|\bnokia[ _-]?(\d|[cgx]\d|xr)|\bnubia|\balcatel|\btecno|\binfinix/i],
	['printer3d', /3d[ _-]?print|\bbambu|\bprusa|creality|octoprint|\boctopi\b|\bvoron|klipper|mainsail|fluidd|moonraker|\belegoo|anycubic|flashforge|snapmaker|\bqidi\b|\bender[ _-]?\d|\bsovol/i],   /* before printer */
	['printer', /printer|laserjet|officejet|deskjet|envy[ _-]?\d|\bepson|\bbrother\b|\bcanon\b|\bet-\d|\bmfc-|\bhl-l|scanner|^npi[0-9a-f]{6}\b|^hp[0-9a-f]{6}$|^br[nw][0-9a-f]{12}$|^epson[0-9a-f]{6}$|xerox|kyocera|ricoh|lexmark|pantum|\bmfp\b|\bdymo\b|\bzebra\b|konica|bizhub|\boki\b/i],   /* with HP's, Brother's and Epson's own host names: NPI3C2AF4, BRW…, EPSON3C2AF4 */
	['contact', /(door|window)[ _-]?(\/ ?window[ _-]?)?(sensor|contact)|contact[ _-]?sensor|shelly[ _-]?(door|dw)/i],
	['doorbell', /doorbell|ring[ _-]?pro|\bring[ _-]?(door|video)|nest[ _-]?hello|doorbird|intercom|door[ _-]?station|akuvox|video[ _-]?door/i],
	['pet', /pet[ _-]?(feeder|fountain|cam|door|camera)|feeder|litter|petlibro|petkit|whisker|sure[ _-]?(petcare|feed|flap)|cat[ _-]?flap|furbo|petcube|petsafe|\bdog[ _-]?cam|\bcat[ _-]?(cam|fountain)|tractive|bird[ _-]?buddy/i],   /* before camera: a pet camera */
	['camera', /\bcam\b|[a-z]cam(\b|\d)|camera|kamera|ipcam|reolink|\barlo\b|\bblink|\bwyze(?![ _-]?(bulb|plug|lock|vac|robot|scale|watch|band|switch|light))|\beufy(?![ _-]?(robo|clean|vac|bulb|lock|smart ?lock|scale|plug))|hikvision|dahua|\bnvr\b|nest[ _-]?cam|^(tapo[ _-]?)?c[1-5]\d\d(ws?)?$|\bimou\b|ezviz|annke|amcrest|foscam|\blorex|\bswann\b|\buvc[ _-]|baby[ _-]?(monitor|cam)|nanit|\bowlet|\bmiku\b|webcam|imilab|\bkc\d{3}\b|wansview|\bzosi\b|heimvision|simplisafe|\bcanary\b/i],   /* Tapo cameras name themselves by model: C200 */
	['lock', /\block\b|smart ?lock|\bnuki\b|\byale\b|schlage|tedee|ultraloq|lockly|danalock|igloohome|\blevel[ _-]?(lock|bolt|touch)|\bwelock|kwikset|\bloqed|deadbolt/i],
	['thermostat', /thermostat|\btstat|lennox|icomfort|honeywell|resideo|\bsensi\b|\bmysa\b|\btado\b|ecobee|\btrv\b|netatmo|nest[ _-]?(learning|thermostat)|ems[-_]?esp|viessmann|vaillant|vitoconnect|\bhive\b|\bwiser\b|evohome|plugwise|buderus|remeha|intergas|\bnefit\b|bosch[ _-]?(easy[ _-]?control|ct\d{3})/i],   /* EMS-ESP: a boiler's gateway */
	['blinds', /blind|curtain|\bshades?\b|shutter|rollo|rolladen|jalousie|\bsomfy(?![ _-]?(garage|gate|alarm|cam|tahoma|box|connexoon))|smartwings|motion[ _-]?blinds|powerview|\bbrel\b|\btuiss|awning/i],   /* before switch and light: "blind switch" */
	['wallswitch', /wall ?switch|light ?switch|smart ?switch|switch ?module|\bdimmer\b|shelly[ _-]?(1|2|plus ?[12]|pro ?[12]|i4|dimmer)\b|sonoff[ _-]?(t[0-4]|tx|mini)\b|^(tapo[ _-]?)?s5\d\d[a-z]?$|^(hs2[0-2]0|ks2\d\d|es20m)\b/i],
	/* Tapo and Kasa devices name themselves by model (L630, KL130), Govee's by its maker and model (ihoment_H6159_…) */
	['light', /bulb|\blamp|\bwled\b|light\b|light ?strip|led ?strip|\bwiz\b|wiz[_-]|lifx|yeelight|yeelink|signify|nanoleaf|govee|^(tapo[ _-]?)?l[5-9]\d\d[a-z]?$|^(kl|lb)\d{3}\b|ihoment[_-]?h(6|70)|twinkly|sengled|\bcync\b|lumary|gledopto|magic[ _-]?home|flux[ _-]?led|\bhue[ _-]?(lamp|bulb|play|go|lightstrip|iris|bloom|gradient|signe)\b|led[ _-]?controller/i],
	['garage', /garage[ _-]?(door|opener|gate)|^garage$|\bmyq|liftmaster|chamberlain|tailwind|ratgdo|ismartgate|gogogate|aladdin[ _-]?connect|gate[ _-]?opener|meross[ _-]?msg/i],   /* before hub */
	['hub', /\bbridge\b|\bhub\b|home[ _-]?assistant|\bhass|smartthings|zigbee|\bthread\b|hubitat|\bhomey\b|\bhue\b|conbee|^(tapo[ _-]?)?h[12]00$|dirigera|tradfri|fibaro|\bezlo\b|\bvera(plus|edge|secure)?\b|homebridge|deconz|phoscon|zigbee2mqtt|\bz2m\b|z-?wave|\bmatter\b|openhab|node-?red|domoticz|iobroker|jeedom|homematic|\bccu3\b|raspberrymatic|\bslzb|smlight|tubeszb|\bajax\b|tahoma|connexoon|lutron|caseta|broadlink|harmony|\bihost\b|\bhoobs\b/i],
	['purifier', /purifier|humidifier|air[ _-]?(cleaner|performer|treatment)|philips[ _-]?air\b|\bblueair|levoit|\bcoway|\bwinix|airmega|ihoment[_-]?h71[24]|dyson[ _-]?(pure|hot|cool|purifier|humidify)|\bzhimi|\bmi[ _-]?air\b|smartmi|rabbit[ _-]?air|molekule/i],
	['air', /\bac\b|a\/c|air ?con|daikin|heat ?pump|climate|mitsubishi|sensibo|midea|\bgree\b|fujitsu|haier[ _-]?(ac|air)|tosot|cooper[ _-]?hunter|\bhvac\b|split[ _-]?(ac|unit)|airzone|intesis|\bdkn\b|onecta|melcloud|comfort[ _-]?cloud|windfree|\bcarrier\b|\btrane\b/i],
	['charger', /ev[ _-]?(charger|box|station)|car[ _-]?charger|charge ?point|wallbox|juicebox|\beasee\b|\bzappi\b|myenergi|wall[ _-]?connector|\bohme\b|pod[ _-]?point|\bgo-?e(charger)?\b|openevse|\bkeba\b|\balfen\b|zaptec|\bevse\b|emporia[ _-]?(ev|charger)|grizzl-?e|hypervolt|nrgkick|\bcharger\b/i],   /* before solar and car: a Tesla Wall Connector */
	['solar', /solar|(pv|hybrid|string)[ _-]?inverter|^inverter\b|\bpv\b|fronius|solaredge|enphase|\benvoy\b|sunny[ _-]?(boy|tripower|island)|sun2000|growatt|goodwe|\bsofar|solax|victron|\bcerbo|sungrow|powerwall|\bdeye\b|hoymiles|apsystems|\bsolix\b|ecoflow|zendure|bluetti|jackery|home[ _-]?battery|power[ _-]?station|kostal|\bsolis\b|sigenergy|\bsenec\b|sonnen|shine[ _-]?(wifi|lan|x)|opendtu|ahoy[ _-]?dtu|\bdtu\b|marstek|sunsynk/i],   /* before car: a Tesla Powerwall */
	['car', /\btesla\b|model[ _-]?[3sxy]\b|cybertruck|polestar|rivian|\blucid\b|\bvolvo\b|\bbmw\b|ioniq|mach[ _-]?e\b|\bcar\b|\bvw[ _-]?id|\bid\.?[3457]\b|e-?tron|enyaq|nissan[ _-]?leaf/i],
	['mower', /mower|landroid|\bworx\b|navimow|sileno|\bluba\b|mammotion|\byuka\b|ecovacs[ _-]?goat|\bgoat[ _-]?[goa]\d|husqvarna|\bstiga\b|robomow|\bindego\b|ambrogio|yarbo|\bkress\b|\blawn|dreame[ _-]?a\d|sunseeker|terramow/i],   /* before vacuum: Ecovacs and Dreame make both */
	['sprinkler', /sprinkler|irrigation|\brachio|rain[ _-]?bird|b-?hyve|hydrawise|gardena|opensprinkler|\bnetro\b|watering|eve[ _-]?aqua|linktap|hoselink|water[ _-]?timer/i],
	['vacuum', /vacuum|roborock|rockrobo|roomba|irobot|deebot|ecovacs|dreame|\bmop\b|^(tapo[ _-]?)?rv\d\d|robovac|\bneato|shark[ _-]?(iq|robot|ai|vac)|narwal|\bviomi|roidmi|proscenic|\blefant|\bmova\b|braava|kobold|\bconga|jet[ _-]?bot|robot[ _-]?(vacuum|cleaner|mop)|dyson[ _-]?360/i],
	/* Bosch, Siemens and Neff machines name themselves "BOSCH-WAX32EH0EU-…": the model number says what each is
	   (WA, WG, WM, WU washers; WT, WQ dryers; WN, WD, WV washer-dryers; SM, SN, SB, SP, SX dishwashers) */
	['dishwasher', /dish ?washer|geschirr|^(bosch|siemens|neff|gaggenau|bsh|constructa|balay|pitsos|profilo)[-_ ]s[mnbpgrx][a-z]{0,2}\d/i],
	['dryer', /tumble|dryer|trockner|^(bosch|siemens|neff|bsh|constructa|balay|pitsos|profilo)[-_ ]w[tq][a-z]{0,2}\d/i],
	['washer', /washer|washing|waschmaschine|^(bosch|siemens|neff|bsh|constructa|balay|pitsos|profilo)[-_ ]w[agmnuvdx][a-z]{0,2}\d/i],
	['appliance', /appliance|fridge|refrigerator|freezer|\boven\b|microwave|kettle|coffee|\bfan\b|heater|boiler|cooker|air ?fryer|ihoment[_-]?h7|^(bosch|siemens|neff|gaggenau|bsh)[-_ ][a-z]{2}|thermomix|nespresso|de'?[ _-]?longhi|\bjura\b|\bsmeg\b|\banova|\bmeater|instant[ _-]?pot|breville|cosori|\bthinq\b|espresso/i],
	['plug', /\bplug|\bchime|\bsp1\d\d\b|smart ?plug|\boutlet\b|socket|power ?strip|\bhs1\d\d\b|\bkp\d{3}\b|^(tapo[ _-]?)?p[13]\d\d[a-z]?$|^ep\d\d\b|meross[ _-]?mss|gosund|teckin|blitzwolf/i],
	['sensor', /sensor|\bmotion\b|\bleak\b|smoke|detector|alarm|weather ?station|aqara|ihoment[_-]?h5|thermometer|hygrometer|air[ _-]?(quality|monitor)|\bawair|airthings|\bco2\b|\bradon|purpleair|qingping|\bflood|(energy|power)[ _-]?meter|shelly[ _-]?(ht|h&t|flood|smoke|3?em)|emporia[ _-]?vue|iotawatt|\bsiren\b/i],
	['iot', /espressif|\besp[-_]?(32|8266|home)|tuya|shelly|sonoff|meross|\btapo\b|\bkasa\b|tasmota|\bwled\b|dyson|smart ?life|ihoment/i]
];
/* Words as people run them together, split apart so the rules above find them: JohnsNas, KidsTV, LivingRoomLamp (camelCase),
   nas01, Camera2 (a number after a word), office_printer, ExampleDSPNAS (an acronym stuck to another, after a lower-case letter).
   Both the name as it is and this one are tried, so model numbers (DXP2800, L630) still match as written. */
function nameWords(s) {
	return String(s).replace(/([a-z])([A-Z]*?)(NAS|NVR|PC)(?![a-z])/g, '$1$2 $3').replace(/([a-z])([A-Z])/g, '$1 $2').replace(/([A-Z]+)([A-Z][a-z])/g, '$1 $2')
		.replace(/([a-z]{3,})(\d+)\b/gi, '$1 $2').replace(/[_.]+/g, ' ');
}
/* A Wi-Fi module's maker and the host name its firmware sends, when the two together say what the device is:
   Daikin's Wi-Fi adapters (BRP069…) carry a Murata module and call themselves "Client". */
var MODULE_KIND = [
	['air', /murata/i, /^client$/i]
];
/* Weaker hints: the maker (from the MAC address) and the DHCP vendor class. Used only when nothing above matched. */
var KIND_WEAK = [
	['light', /signify|wiz connected|lifx|yeelight|nanoleaf|intellirocks|twinkly|ledworks/i],   /* Shenzhen Intellirocks: Govee */
	['air', /daikin|sensibo|gree electric|midea/i],
	['smartspeaker', /amazon technologies/i],   /* Amazon's own Wi-Fi: Echo speakers, most often */
	['speaker', /sonos|bose corp|bluesound|lenbrook|harman|bang & olufsen|devialet|linkplay/i],
	['printer3d', /bambu|creality|prusa|elegoo|anycubic|flashforge|snapmaker|qidi/i],
	['printer', /seiko epson|brother industries|canon|hewlett.*print|xerox|kyocera|ricoh|lexmark|pantum|zebra tech|konica/i],
	['vr', /oculus|meta platforms tech/i],
	['charger', /wallbox|easee|myenergi|chargepoint|zaptec|alfen|keba|ohme|pod point|go-e|juicebox|hypervolt/i],
	['solar', /fronius|solaredge|enphase|sma solar|growatt|goodwe|victron|sungrow|hoymiles|kostal|solax|sofar|sigenergy|sonnen|apsystems|ecoflow|zendure|bluetti|jackery/i],
	['car', /tesla/i],
	['mower', /husqvarna|positec|mammotion|stiga|robomow|segway|kress/i],
	['sprinkler', /rachio|rain bird|orbit irrigation|hunter industries|gardena/i],
	['garage', /chamberlain|tailwind|nexx|genie company/i],
	['blinds', /somfy|hunter douglas|smartwings|dooya/i],
	['pet', /petlibro|petkit|automated pet care|sure petcare|tomofun|petcube|whisker/i],
	['fitness', /peloton|tonal|ifit|echelon|technogym|hydrow|wahoo/i],
	['thermostat', /tado|ecobee|netatmo|resideo|viessmann|vaillant/i],
	['tv', /lg innotek|hisense|vizio|tcl king/i],
	['streamer', /\broku\b/i],
	['nas', /synology|qnap|ugreen/i],
	['pi', /raspberry/i],
	['console', /nintendo|sony interactive/i],
	['camera', /hikvision|dahua|reolink|arlo|ezviz|amcrest|foscam|wyze/i],
	['vacuum', /roborock|irobot|ecovacs|dreame|narwal|neato|sharkninja/i],
	['appliance', /electrolux|\baeg\b|bsh hausger|miele|whirlpool|bauknecht|haier|candy|beko|arcelik|liebherr|vorwerk/i],
	['iot', /espressif|tuya|shelly|itead|texas instruments|murata|azurewave|mxchip|\budhcp/i]
];
/* The kinds people carry or sit at: an icon of these saved on a home device is the router's guess (see classify) */
var PERSONAL = { desktop: 1, mac: 1, laptop: 1, phone: 1, tablet: 1, watch: 1, console: 1 };
/* Why a device got its kind: kept for the readout's Details and the classification report. */
function classify(mac, name, link, al) {
	var N = A.names, c = al ? { name: al.name, type: al.type || 0 } : N && N.custom[mac], m = N && N.nmp[mac], l = N && N.lease[mac];
	var ct = (c && c.type) || 0, nt = (m && +m.type) || 0, os = (m && +m.os_type) || 0;
	var res = function (kind, rule, tok) { return { kind: kind, rule: rule, tok: tok || '', ct: ct, nt: nt, os: os }; };
	var KEYS = ['nickname', 'label', 'hostname', 'router name'], names = [al ? c.name : nickOf(c, m), name, l && l.host, m && m.name], i, j, r;
	/* What a name says: as written first, then with words run together split apart (only when nothing matched as written,
	   so "Somfy TaHoma" stays a hub) */
	var byName = function (s, j) {
		var w, i;
		if (!s) return null;
		for (i = 0; i < KIND_STRONG.length; i++) if (KIND_STRONG[i][1].test(s)) return res(KIND_STRONG[i][0], 'name', KEYS[j] + ' #' + i);
		if ((w = nameWords(s)) !== s) for (i = 0; i < KIND_STRONG.length; i++) if (KIND_STRONG[i][1].test(w)) return res(KIND_STRONG[i][0], 'name', KEYS[j] + ' #' + i + ' split');
		return null;
	};
	/* 1. the icon you picked in the router's client list. Saving a nickname there also saves whatever icon the editor showed,
	   often only the router's guess at the time, so the name comes first when the saved icon is:
	   - the router's own guess (the same icon it detects), or a loose one (any computer, any phone);
	   - a computer, phone, tablet, watch or console icon on a device you named after a home device ("Daikin AC"): nobody
	     picks a game console for their air conditioner. A nickname the editor filled in with the device's own name
	     (DESKTOP-…) isn't one you typed. Other icons you picked win over the name: a plug named for its lamp stays a plug. */
	var key = function (s) { return String(s || '').toLowerCase().replace(/[^a-z0-9]/g, ''); };
	var typed = names[0] && [l && l.host, m && m.name].every(function (h) { return !h || key(h) !== key(names[0]); }), mine = typed ? byName(names[0], 0) : null;
	if (ct && TYPE_KIND[ct] && ct !== nt && (!TYPE_LOOSE[ct] || nt) && !(mine && PERSONAL[TYPE_KIND[ct]] && !PERSONAL[mine.kind])) return res(TYPE_KIND[ct], 'your icon');
	/* 2. a name that says what it is: your nickname, then the names the device gave */
	for (j = 0; j < names.length; j++) if ((r = byName(names[j], j))) return r;
	/* a Wi-Fi module's maker with the name its firmware gives, when the pair says what the device is */
	var mk = [m && m.vendor, m && m.vendorclass].join(' ');
	for (i = 0; i < MODULE_KIND.length; i++) if (MODULE_KIND[i][1].test(mk) && [l && l.host, m && m.name].some(function (h) { return h && MODULE_KIND[i][2].test(h); })) return res(MODULE_KIND[i][0], 'module', '#' + i);
	/* 3. the router's own icon number */
	var t = ct || nt;
	if (t === 30 || (!TYPE_KIND[t] && os === 2)) return res(link === 'wired' ? 'desktop' : 'laptop', 'windows + link');
	if (TYPE_KIND[t]) return res(TYPE_KIND[t], ct ? 'saved icon' : 'router icon');
	/* 4. Android says so itself (before the maker: phones carry Wi-Fi chips from module makers), then maker and DHCP vendor class */
	if (/^android-dhcp/i.test(m && m.vendorclass || '') || os === 1) return res('phone', 'android');
	var txt = [m && m.vendor, m && m.vendorclass].join(' ');
	for (i = 0; i < KIND_WEAK.length; i++) if (KIND_WEAK[i][1].test(txt)) return res(KIND_WEAK[i][0], 'maker', '#' + i);
	return res('generic', 'none');
}

/* ---- names: private addresses and re-identifying a device whose address changed (section 7) ---- */
function isPrivate(mac) { return /^.[26AEae]/.test(mac); }   /* locally administered: a randomised "private" Wi-Fi address */
/* Host names many devices share out of the box: never enough to say two addresses are one device. */
var GENERIC_HOST = /^(iphone|ipad|ipod|mac|imac|macbook(-?(air|pro))?|mac-?(mini|studio|pro)|apple-?watch|watch|android(-[0-9a-f]+)?|galaxy[-a-z0-9]*|pixel[-a-z0-9]*|localhost|espressif|esp[-_][0-9a-f]+|wlan\d*|unknown)$/i;
function hostKey(h) { h = String(h || '').trim().toLowerCase().replace(/\.(local|lan|home)$/, ''); return h.length >= 4 && !JUNK_NAME.test(h) && !GENERIC_HOST.test(h) ? h : ''; }
function hostMemo(set) {   /* per-browser memory of "this named address used this host name"; the router stores nothing */
	var m = {};
	try { m = JSON.parse(store('hosts') || '{}'); } catch (e) { m = null; }
	if (!m || typeof m !== 'object' || Array.isArray(m)) m = {};
	if (set) {
		Object.keys(set).forEach(function (k) { m[k] = set[k]; });
		var ks = Object.keys(m);
		if (ks.length > 300) ks.slice(0, ks.length - 300).forEach(function (k) { delete m[k]; });
		store('hosts', JSON.stringify(m));
	}
	return m;
}
/* online: { MAC: 1 } for every address in this sample. Returns { newMac: { mac: oldMac, name, type, host } }. */
function buildAliases(N, online) {
	var memo = hostMemo(), learn = {}, named = Object.create(null), fresh = Object.create(null), out = {};   /* keyed by host names: "constructor" is one */
	var hostOf = function (mac) { var l = N.lease[mac], m = N.nmp[mac]; return hostKey(l && l.host) || hostKey(m && m.name) || hostKey(memo[mac]); };
	Object.keys(N.custom).forEach(function (mac) {
		var h = hostOf(mac);
		if (!h || !N.custom[mac].name) return;
		if (memo[mac] !== h) learn[mac] = h;
		(named[h] = named[h] || []).push(mac);
	});
	if (Object.keys(learn).length) hostMemo(learn);
	Object.keys(online).forEach(function (mac) {
		var h = !N.custom[mac] && isPrivate(mac) ? hostOf(mac) : '';
		if (h) (fresh[h] = fresh[h] || []).push(mac);
	});
	Object.keys(fresh).forEach(function (h) {
		var olds = (named[h] || []).filter(function (m) { return !online[m]; });
		/* exactly one unnamed private address and exactly one named, absent address share this host name */
		if (fresh[h].length === 1 && olds.length === 1 && (named[h] || []).length === 1)
			out[fresh[h][0]] = { mac: olds[0], name: N.custom[olds[0]].name, type: N.custom[olds[0]].type, host: h };
	});
	return out;
}

/* ---- the Details view of the readout (section 6): up to 12 cells of [label, value, title] ---- */
var OS_NAME = { 1: 'Android', 2: 'Windows', 3: 'Linux', 4: 'ASUS', 5: 'Apple' };   /* networkmap.h BASE_TYPE_* */
var WIFI_STD = { n: 'Wi-Fi 4 (802.11n)', ac: 'Wi-Fi 5 (802.11ac)', ax: 'Wi-Fi 6 (802.11ax)', be: 'Wi-Fi 7 (802.11be)' };
var KIND_LABEL = { desktop: 'Desktop PC', mac: 'Mac desktop', laptop: 'Laptop', phone: 'Phone', tablet: 'Tablet', watch: 'Watch', printer: 'Printer', tv: 'TV', streamer: 'Streaming box',
	speaker: 'Speaker', soundbar: 'Home cinema', console: 'Game console', nas: 'NAS', camera: 'Camera', doorbell: 'Doorbell', lock: 'Smart lock', thermostat: 'Thermostat', light: 'Light',
	hub: 'Smart-home hub', air: 'Air conditioner', vacuum: 'Robot vacuum', appliance: 'Appliance', washer: 'Washing machine', dryer: 'Dryer', dishwasher: 'Dishwasher', plug: 'Smart plug', sensor: 'Sensor', iot: 'Smart device', switch: 'Network device', generic: 'Device',
	pi: 'Single-board computer', stick: 'Streaming stick', smartspeaker: 'Smart speaker', purifier: 'Air purifier', wallswitch: 'Smart switch', contact: 'Door sensor',
	charger: 'EV charger', car: 'Car', solar: 'Solar or battery', mower: 'Robot mower', vr: 'VR headset', projector: 'Projector', garage: 'Garage door', printer3d: '3D printer',
	display: 'Smart display', blinds: 'Smart blinds', sprinkler: 'Sprinkler', pet: 'Pet device', fitness: 'Fitness equipment' };
function ago(s) {
	if (s === null || s === undefined || isNaN(s)) return '—';
	s = Math.max(0, Math.round(s));
	if (s < 90) return s + ' s';
	if (s < 5400) return Math.round(s / 60) + ' min';
	if (s < 172800) return Math.floor(s / 3600) + ' h ' + Math.round(s % 3600 / 60) + ' min';
	return Math.round(s / 86400) + ' days';
}
function osOf(m) {
	var vc = String(m && m.vendorclass || ''), a = /^android-dhcp-(\d+)/i.exec(vc);
	if (a) return 'Android ' + a[1];
	if (/^MSFT/i.test(vc)) return 'Windows';
	if (/^dhcpcd|^udhcp|linux/i.test(vc)) return 'Linux' + (/^udhcp/i.test(vc) ? ' (embedded)' : '');
	return OS_NAME[m && +m.os_type] || '—';
}
/* A device's IPv4 address: its DHCP lease, the router's ARP table, or the node's own client list. */
function ipOf(dv) {
	var N = A.names, mac = dv && dv.mac;
	if (!N || !mac) return '';
	var l = N.lease && N.lease[mac], cl = dv.node && N.cl && N.cl[dv.node.mac], ip = (l && l.ip) || (N.arp && N.arp[mac]) || '';
	if (!ip && cl) ['2G', '5G', '5G1', '6G'].forEach(function (b) { var e = cl[b] && (cl[b][mac] || cl[b][mac.toLowerCase()]); if (e && e.ip) ip = e.ip; });
	return ip;
}
function detailsFor(net, dv) {
	var N = A.names || { custom: {}, nmp: {}, lease: {}, arp: {}, n6: {}, fixed: {} }, mac = dv.mac, m = N.nmp[mac], l = N.lease[mac], al = dv.alias, w = dv.why || {};
	var ip = ipOf(dv);
	var v6 = (N.n6 && N.n6[mac]) || [], now = (net && net.epoch) || Date.now() / 1000;   /* the router's clock: the browser's can differ */
	var left = l && +l.exp ? +l.exp - now : 0;
	var lease = N.fixed && N.fixed[mac] ? 'Reserved' : (l ? (left > 0 ? 'DHCP · ' + (left >= 5400 ? Math.round(left / 3600) + ' h' : ago(left)) + ' left' : 'DHCP') : (ip ? 'Static' : '—'));
	var priv = mac && isPrivate(mac), wifi = dv.link === 'wifi';
	var std = WIFI_STD[dv.std] ? WIFI_STD[dv.std].split(' (')[0].slice(6) + (dv.band === '6' && dv.std === 'ax' ? 'E' : '') : '';   /* "6", "6E": the label says Wi-Fi */
	var kl = KIND_LABEL[dv.kind] || 'Device', why = { 'your icon': 'the icon you chose in the router\'s client list', name: 'its name', 'windows + link': 'Windows, and how it is connected',
		'saved icon': 'the icon saved in the router\'s client list', 'router icon': 'the type the router detected', maker: 'its maker', module: 'its Wi-Fi module\'s maker and the name it gives', android: 'Android' }[w.rule];
	var wifiTxt = (std || '—') + (dv.nss ? ' · ' + dv.nss + '×' + dv.nss : '') + (dv.bw ? ' · ' + dv.bw + ' MHz' : '');
	/* four columns; the second is the widest, for the MAC, the Wi-Fi details and IPv6 */
	var cells = [
		['IP address', ip || '—'],
		[priv ? 'MAC · private' : 'MAC address', mac || '—', priv ? mac + ': a private (randomised) Wi-Fi address. It can change, and it says nothing about the maker.' : ''],
		['Host name', (l && l.host && l.host !== '*' ? l.host : '') || (m && m.name) || '—'],
		['Maker', (m && m.vendor) || (priv ? 'Hidden' : '—'), priv && !(m && m.vendor) ? 'A private address hides the maker.' : ''],
		['System', osOf(m)],
		wifi ? ['Wi-Fi', wifiTxt, (WIFI_STD[dv.std] || 'Wi-Fi') + (dv.nss ? ', ' + dv.nss + ' spatial streams' : '') + (dv.bw ? ', ' + dv.bw + ' MHz channel' : '')] : ['Port', (dv.portLabel || '—') + (dv.speed ? ' · ' + speedTxt(dv.speed) : '')],
		['Shown as', kl, kl + (why ? ': recognised by ' + why : '')],
		wifi ? ['Link ↓ / ↑ Mb/s', (dv.phy || '—') + ' / ' + (dv.phyUp || '—'), 'Link rate: ' + (dv.phy || '—') + ' Mb/s down, ' + (dv.phyUp || '—') + ' Mb/s up'] : ['Devices on it', String(dv.count || 1)],
		wifi ? ['Connected', ago(dv.conn), 'Connected for ' + ago(dv.conn) + (dv.idle > 0 ? ', idle for ' + ago(dv.idle) : '') + (dv.node ? ' (restarts when it roams between the router and a node)' : '')] : ['Connected', '—'],
		['IPv6', v6.length ? v6[0] + (v6.length > 1 ? ' +' + (v6.length - 1) : '') : '—', v6.join('\n')],
		['Address', lease, l && left > 0 ? 'DHCP lease, ' + ago(left) + ' left' : ''],
		al ? ['Matched', 'by host name', 'This private address has no name of its own. It uses the host name of the device you named "' + al.name + '", which is not connected now, so it is shown under that name.']
			: ['Name from', nickOf(N.custom[mac], m) ? 'your client list' : ((l && l.host) || (m && m.name) ? 'the device' : 'its maker or kind')]
	];
	return cells;
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
	if (!r) { if (s) s.age++; if (s) return s; s = zeroRate(); s.age = 0; return s; }
	if (!s) s = A.sm[key] = { dn: r.dn, up: r.up, sdn: r.dn, sup: r.up };
	else { s.dn += 0.6 * (r.dn - s.dn); s.up += 0.6 * (r.up - s.up); s.sdn += 0.2 * (r.dn - s.sdn); s.sup += 0.2 * (r.up - s.sup); }
	s.ok = true; s.age = 0;
	return s;
}
function measure(key, t, d, u) { return smooth(key, rate(key, t, d, u)); }

/* ---------------------------------------------------------------- the network, from one sample */
function zeroRate() { return { dn: 0, up: 0, sdn: 0, sup: 0, ok: false }; }   /* a rate that hasn't been measured yet */
function speedTxt(mbps) { return mbps >= 1000 ? mbps / 1000 + ' GbE' : mbps + ' Mb/s'; }   /* a port's link speed */
function dbm(v, none) { return v !== null && v !== undefined && v !== '' ? v + ' dBm' : (none === undefined ? '—' : none); }
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
/* Addresses and interface names become ids, and ids go into the scene's markup as attributes: anything
   that is not exactly a MAC address or an interface name is dropped here, wherever it came from. */
var MAC_RE = /^[0-9A-F]{2}(:[0-9A-F]{2}){5}$/, IF_RE = /^[A-Za-z0-9_.-]{1,16}$/;
function isMac(m) { return typeof m === 'string' && MAC_RE.test(m); }
function isIf(i) { return typeof i === 'string' && IF_RE.test(i); }
function cleanSample(d) {
	var rows = function (a) { return (Array.isArray(a) ? a : []).filter(function (r) { return Array.isArray(r) && isMac(r[2]) && isIf(r[0]); }); };
	return { router: d.router || {}, ms: d.ms, interval: d.interval, epoch: +d.epoch || 0, up: d.up, wan: isIf(d.wan) ? d.wan : '',
		own: (Array.isArray(d.own) ? d.own : []).filter(isMac), ports: (Array.isArray(d.ports) ? d.ports : []).filter(isIf),
		links: (Array.isArray(d.links) ? d.links : []).filter(function (l) { return Array.isArray(l) && isIf(l[0]); }),
		ifs: (Array.isArray(d.ifs) ? d.ifs : []).filter(function (r) { return Array.isArray(r) && isIf(r[0]); }),
		macs: (Array.isArray(d.macs) ? d.macs : []).filter(function (pm) { return Array.isArray(pm) && isIf(pm[0]) && isMac(pm[1]); }),
		sta: rows(d.sta),
		nodes: (Array.isArray(d.nodes) ? d.nodes : []).filter(function (n) { return n && isMac(n.mac); }).map(function (n) {
			return { mac: n.mac, ip: n.ip, model: String(n.model || ''), alias: String(n.alias || ''), state: n.state, up: n.up, c: rows(n.c), sta: String(n.sta || '').split(/\s+/).filter(isMac).join(' ') };
		}) };
}
function buildNet(d) {
	d = cleanSample(d);
	var t = parseFloat(d.up), own = {}, bh = {}, net = { router: d.router, nodes: [], devs: [], byId: {}, ms: d.ms, interval: d.interval, epoch: d.epoch };
	(d.own || []).forEach(function (m) { own[m] = 1; });
	var ifs = {};
	(d.ifs || []).forEach(function (r) { ifs[r[0]] = r; });
	/* internet */
	var w = ifs[d.wan];
	net.wan = w ? measure('wan', t, w[1], w[2]) : zeroRate();
	net.wanIf = d.wan; net.wanSpeed = linkOf(d, d.wan).speed;
	/* AiMesh nodes and the addresses they use to reach the router */
	(d.nodes || []).forEach(function (n, i) {
		var node = { id: 'node:' + n.mac, mac: n.mac, ip: n.ip, model: n.model || 'AiMesh node', alias: n.alias || '', state: n.state, nup: n.up,
			rows: n.c || [], sta: String(n.sta || '').split(/\s+/).filter(Boolean), bh: zeroRate(), bhRows: [], devs: [], idx: i };
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
		seen[mac] = { ap: 'router', ifn: r[0], band: r[1], mac: mac, rssi: r[5], phy: r[6], phyUp: r[7], conn: r[8], idle: r[9], std: r[10], nss: r[11], bw: r[12], s: s, st: 'ok' };
	});
	net.nodes.forEach(function (node) {
		var b = zeroRate(), best = null;
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
				var cand = { ap: node.mac, node: node, ifn: r[0], band: r[1], mac: mac, rssi: r[5], phy: r[6], phyUp: r[7], conn: r[8], idle: r[9], std: r[10], nss: r[11], bw: r[12], s: s, st: 'ok' };
				var o = seen[mac];   /* roaming: the newer association wins */
				if (!o || (+cand.conn < +o.conn)) seen[mac] = cand;
			});
		} else if (A.names && A.names.cl[node.mac]) {   /* not readable: list its clients without numbers */
			var cl = A.names.cl[node.mac];
			[['2G', '2.4'], ['5G', '5'], ['5G1', '5'], ['6G', '6']].forEach(function (bk) {
				Object.keys(cl[bk[0]] || {}).forEach(function (k) {
					var m = k.toUpperCase();
					if (!isMac(m) || seen[m] || own[m] || bh[m]) return;
					seen[m] = { ap: node.mac, node: node, band: bk[1], mac: m, rssi: +((cl[bk[0]][k] || {}).rssi) || null, phy: null, s: zeroRate(), st: node.online ? 'nodata' : 'off' };
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
			rssi: x.rssi, phy: x.phy, phyUp: x.phyUp, conn: x.conn, idle: x.idle, std: x.std, nss: x.nss, bw: x.bw, s: x.s, st: x.st });
	});
	/* private addresses that took over a named device's host name (section 7): worked out again only when
	   the names or the set of connected addresses change */
	var online = {};
	net.devs.forEach(function (dv) { if (dv.mac) online[dv.mac] = 1; });
	var akey = (A.namesAt || 0) + ':' + Object.keys(online).sort().join(',');
	if (akey !== A.aliasKey) { A.aliasKey = akey; A.aliases = A.names ? buildAliases(A.names, online) : {}; }
	net.devs.forEach(function (dv) {
		var al = dv.mac && A.aliases && A.aliases[dv.mac];
		if (al) dv.alias = al;
		if (!dv.name) { var ni = nameInfo(dv.mac, al); dv.name = ni.name; dv.nameSrc = ni.src; }
		if (!dv.kind) { dv.why = classify(dv.mac, dv.nameSrc === 'tail' ? '' : dv.name, dv.link, al); dv.kind = dv.why.kind; }
		if (dv.nameSrc === 'tail' && dv.kind !== 'generic') dv.name = KIND_LABEL[dv.kind] + ' …' + dv.mac.slice(-5);
		dv.dn = dv.s.dn; dv.up = dv.s.up; dv.sdn = dv.s.sdn; dv.sup = dv.s.sup;
		net.byId[dv.id] = dv;
		if (dv.node) dv.node.devs.push(dv);
	});
	/* totals: everything the router delivered = its own clients + the nodes' backhaul */
	var tot = zeroRate();
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
/* G: everything the map and the flow need to know about size (section "geometry" below). The page's own
   view is geomSmall(), 728 × 518, and never moves; the expanded view swaps in geomBig() for the window. */
var CC = Math.cos(Math.PI / 6), G = null;
function P(X, Y, Z) { return [G.OX + (X - Y) * CC * G.U, G.OY + (X + Y) * 0.5 * G.U - (Z || 0) * G.U]; }
function px(v) { return n1(v * G.U / 24); }   /* a size in pixels that grows with the drawing */
function ptsS(ps) { return ps.map(function (p) { return n1(p[0]) + ',' + n1(p[1]); }).join(' '); }
function poly(ps, st) { return '<polygon points="' + ptsS(ps) + '" style="' + st + '"/>'; }
function pline(ps, st, dy) { return '<path d="M' + ps.map(function (p) { return n1(p[0]) + ' ' + n1(p[1] + (dy || 0)); }).join(' L') + '" style="' + st + '"/>'; }
function ell(c, r, st, cls) { return '<ellipse cx="' + n1(c[0]) + '" cy="' + n1(c[1]) + '" rx="' + n1(1.2247 * r * G.U) + '" ry="' + n1(0.7071 * r * G.U) + '"' + (cls ? ' class="' + cls + '"' : '') + ' style="' + st + '"/>'; }
/* Four tones from one base colour: top, left (lit), right (shade), deep; plus edge and rim. Light comes from the upper left. */
function MAT(base, light) {
	var dark = '#0b1012';
	return { t: mix(base, light ? 0.34 : 0.2), l: base, r: mix(base, light ? 0.26 : 0.32, dark), d: mix(base, 0.6, dark), e: mix(base, light ? 0.5 : 0.74, dark),
		hi: 'rgba(255,255,255,' + (light ? '.85' : '.3') + ')', hi2: 'rgba(255,255,255,' + (light ? '.4' : '.12') + ')' };
}
var M_BODY = MAT('#48555b'), M_DARK = MAT('#2c363a'), M_BLACK = MAT('#1d2427'), M_WHITE = MAT('#d3dadc', true), M_ALU = MAT('#b4bdc1', true),
	M_METAL = MAT('#7d8b91'), M_WALL = MAT('#3b484e'), M_TABLE = MAT('#66757c'), M_PCB = MAT('#2f7a4c');

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
		if (dz * G.U > 9) this.svg.push(pline([P(X + dx, Y + dy, Z + dz), P(X + dx, Y + dy, Z)], 'fill:none;stroke:' + m.hi2 + ';stroke-width:.8;stroke-linecap:round'));
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
function objRouter(model) {
	var f = formOf(model, 'router'), o;
	if (f.form !== 'router' && f.form !== 'gaming') {   /* a mesh unit as the main router: on the same base plate, so the cables still meet it */
		o = new Obj('router', 7.1, 7.1, HUB_TOP[f.form] + 0.1);
		o.box(5.42, 5.82, 0, 3.36, 2.56, 0.07, M_BLACK, { rim: false, shadow: true });
		hubBody(o, 'router', 7.1, f.form === 'plug' ? 6.6 : 7.1, f, ACC);
		routerCollars(o);
		return o;
	}
	o = new Obj('router', 7.1, 7.1, 2.0);
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
	if (f.form === 'gaming') [[5.56, 7.9], [8.5, 7.9], [8.5, 6.9]].forEach(function (a) {   /* a gaming router: three more antennas, front and side */
		o.box(a[0], a[1], 0.64, 0.15, 0.15, 1.22, M_DARK);
		o.face('L', 0, 0.9, 1, 1, 'fill:' + ACC + ';opacity:.8');
	});
	routerCollars(o);
	return o;
}
function routerCollars(o) {
	if (!G.big) { o.collar(6.12, 8.3, 0.36, 0.2); o.collar(7.82, 8.3, 0.36, 0.2); return; }
	o.collar(5.67, 8.3, 0.81, 0.2); o.collar(7.82, 8.3, 0.81, 0.2); o.collar(8.7, 7.07, 0.2, 0.36);
}
/* A cylinder: two ellipses and the band between them, lit from the left like the boxes. side = the id of its two-tone gradient. */
Obj.prototype.disc = function (cx, cy, z, r, h, m, side, o) {
	o = o || {};
	var c0 = P(cx, cy, z), c1 = P(cx, cy, z + h), rx = 1.2247 * r * G.U, ry = 0.7071 * r * G.U;
	this.svg.push('<path d="M' + n1(c1[0] - rx) + ' ' + n1(c1[1]) + ' L' + n1(c0[0] - rx) + ' ' + n1(c0[1]) + ' A' + n1(rx) + ' ' + n1(ry) + ' 0 0 0 ' + n1(c0[0] + rx) + ' ' + n1(c0[1]) + ' L' + n1(c1[0] + rx) + ' ' + n1(c1[1]) + ' Z" style="fill:url(#' + side + ');stroke:' + m.e + ';stroke-width:.7;stroke-linejoin:round"/>');
	this.svg.push(ell(c1, r, 'fill:' + m.t + ';stroke:' + m.e + ';stroke-width:.7'));
	if (o.track !== false) this.pts.push([c1[0] - rx, c1[1] - ry], [c0[0] + rx, c0[1] + ry]);
	if (o.shadow) this.shadow.push([cx - r * 0.75, cy - r * 0.75, r * 1.5, r * 1.5, 0.45 * (z + h) + 0.1, -0.2 * (z + h) - 0.04]);
	return this;
};
/* What an ASUS router or AiMesh node looks like, from its model name: first match wins. */
var FORMS = [
	['plug', /^(RP-|XP4|PL-)/, /^RP-AC(1900|87|66|53)/],          /* plug-in repeaters and powerline units (2nd: with antennas) */
	['tower', /^(XT\d|ET\d|CT\d|BT\d|BQ\d|GT6|RT-AXE?95Q|BLUECAVE|EBM)/],   /* ZenWiFi towers, ROG Rapture GT6 */
	['cube', /^(XD\d|XC\d|CD\d|BD\d|EBA|RT-AX57[ _-]?GO)/],        /* ZenWiFi compact units */
	['puck', /^(LYRA|MAP-AC)/],
	['gaming', /^(GT-|RT-AX89|RT-AC5300|RT-BE9[68])/],            /* ROG Rapture and the eight-antenna flagships */
	['router', /^(RT-?|TUF|DSL-|GS-|TX-|BRT-|4G-|RM-|EBR|EBG|ROG)/]
];
function formOf(model, fallback) {
	var m = String(model || '').toUpperCase().replace(/^(ASUS|ROG RAPTURE|TUF GAMING)[ _-]+/, '').replace(/^ZENWIFI[ _-]*(PRO[ _-]*)?(AX[ _-]|BE[ _-]|AC[ _-])?/, '');
	for (var i = 0; i < FORMS.length; i++) if (FORMS[i][1].test(m)) return { form: FORMS[i][0], ant: !!(FORMS[i][2] && FORMS[i][2].test(m)) };
	return { form: fallback, ant: false };
}
var FORM_ICON = { plug: 'repeater', tower: 'mesh', cube: 'cube', puck: 'puck', gaming: 'router', router: 'router' };
function ringSvg(id, c, r) {
	if (id === 'router') return ell(c, r, 'fill:' + ACC + ';stroke:#ffe9a3;stroke-width:.9');
	return '<g data-ring="' + id + ':lit">' + ell(c, r, 'fill:' + MESH + ';stroke:#d6cffc;stroke-width:.9') + '</g>' +
		'<g data-ring="' + id + ':dead" class="hide">' + ell(c, r, 'fill:#5a6569;stroke:' + BAD + ';stroke-width:1.2') + '</g>';
}
/* One body per form, built around (cx, cy). The accent is violet on a node and yellow on the main router.
   Each sets o.hub, where the Wi-Fi arcs meet above it. */
function hubBody(o, id, cx, cy, f, acc) {
	var b, c;
	if (f.form === 'plug') {
		o.box(cx - 0.9, cy - 0.46, 0, 1.8, 0.14, 1.72, M_WALL, { shadow: true });   /* a piece of wall */
		b = o.last;
		o.line('L', 0, 0.07, 1, 0.07, 'rgba(0,0,0,.3)', 1, b);
		o.face('L', 0.2, 0.2, 0.8, 0.9, 'fill:#c9d1d4;stroke:#6b777c;stroke-width:.7', b);   /* the socket plate */
		if (f.ant) [cx - 0.4, cx + 0.3].forEach(function (ax) { o.box(ax, cy - 0.3, 1.3, 0.1, 0.1, 0.75, M_WHITE); });
		o.box(cx - 0.42, cy - 0.32, 0.5, 0.84, 0.3, 0.92, M_WHITE, { ao: true, shadow: true });   /* the extender */
		[0.14, 0.21, 0.28, 0.35].forEach(function (v) { o.line('L', 0.2, v, 0.8, v, '#8f9a9e', 1.2); });
		[0.3, 0.45, 0.6].forEach(function (v) { o.line('R', 0.25, v, 0.75, v, '#7f8a8e', 1.1); });
		o.svg.push(ringSvg(id, o.fp('L', 0.5, 0.7), 0.14));
		o.hub = P(cx, cy - 0.17, f.ant ? 2.3 : 1.95);
	} else if (f.form === 'router' || f.form === 'gaming') {
		var g = f.form === 'gaming', m = g ? M_BLACK : M_BODY, base = g ? '#1d2427' : '#48555b';
		if (g) [cx - 0.78, cx - 0.2, cx + 0.38].forEach(function (ax) { o.box(ax, cy - 0.66, 0.2, 0.12, 0.12, 1.2, M_DARK); o.face('L', 0, 0.9, 1, 1, 'fill:' + acc + ';opacity:.85'); });
		o.box(cx - 0.82, cy - 0.62, 0, 1.64, 1.24, 0.06, M_BLACK, { rim: false, shadow: true });
		o.box(cx - 0.75, cy - 0.55, 0.06, 1.5, 1.1, 0.34, m, { ao: true, shadow: true });
		b = o.last;
		o.face('T', 0.04, 0.06, 0.96, 0.94, 'fill:' + mix(base, 0.27) + ';stroke:' + mix(base, 0.05) + ';stroke-width:.7', b);
		[0.24, 0.4, 0.56].forEach(function (v) { o.line('T', 0.1, v, 0.5, v, '#2b3438', 1.5, b); });
		o.line('T', 0.6, 0.88, 0.92, 0.88, acc, 1.8, b);
		o.face('L', 0.5, 0.26, 0.94, 0.72, 'fill:#141b1e;stroke:#0d1214;stroke-width:.6', b);
		[['#3ddc97', 1.7], [acc, 0], [acc, 2.3]].forEach(function (c2, i) { o.led('L', 0.6 + i * 0.12, 0.5, c2[0], c2[1], -0.3 * i, 1.2, b); });
		if (!g) [cx - 0.66, cx + 0.5].forEach(function (ax) { o.box(ax, cy - 0.53, 0.4, 0.13, 0.13, 0.95, M_DARK); o.face('L', 0, 0.9, 1, 1, 'fill:' + acc + ';opacity:.85'); });
		if (g) {
			o.face('T', 0.56, 0.2, 0.9, 0.62, 'fill:#141b1e;stroke:' + acc + ';stroke-width:.8', b);
			[[cx - 0.86, cy + 0.3], [cx + 0.7, cy + 0.3], [cx + 0.7, cy - 0.3]].forEach(function (a2) { o.box(a2[0], a2[1], 0.2, 0.12, 0.12, 1.2, M_DARK); o.face('L', 0, 0.9, 1, 1, 'fill:' + acc + ';opacity:.85'); });
		} else o.svg.push(ringSvg(id, P(cx + 0.3, cy + 0.02, 0.4), 0.18));
		o.hub = P(cx, cy, g ? 1.9 : 1.75);
	} else if (f.form === 'cube') {
		o.box(cx - 0.52, cy - 0.52, 0, 1.04, 1.04, 0.06, M_METAL, { rim: false, shadow: true });
		o.box(cx - 0.45, cy - 0.45, 0.06, 0.9, 0.9, 0.62, M_WHITE, { ao: true, shadow: true });
		[0.3, 0.42, 0.54].forEach(function (v) { o.line('L', 0.24, v, 0.76, v, '#8f9a9e', 1.2); o.line('R', 0.24, v, 0.76, v, '#7f8a8e', 1.1); });
		c = P(cx, cy, 0.68);
		o.svg.push(ell(c, 0.27, 'fill:#bcc5c8;stroke:#8f9a9e;stroke-width:.7'), ringSvg(id, c, 0.18));
		o.hub = P(cx, cy, 1.1);
	} else if (f.form === 'puck') {
		o.disc(cx, cy, 0.04, 0.62, 0.26, M_WHITE, 'ar-cw', { shadow: true });
		var c1 = P(cx, cy, 0.3);
		o.svg.push(ell(c1, 0.36, 'fill:#bcc5c8;stroke:#8f9a9e;stroke-width:.7'), ringSvg(id, c1, 0.25));
		o.hub = P(cx, cy, 0.8);
	} else {   /* tower */
		o.box(cx - 0.7, cy - 0.7, 0, 1.4, 1.4, 0.07, M_METAL, { rim: false, shadow: true });
		o.box(cx - 0.6, cy - 0.6, 0.07, 1.2, 1.2, 1.72, M_WHITE, { ao: true, shadow: true });
		[0.5, 0.57, 0.64, 0.71].forEach(function (v) { o.line('L', 0.24, v, 0.76, v, '#8f9a9e', 1.2); });
		o.face('L', 0.3, 0.16, 0.7, 0.3, 'fill:#aab4b8;stroke:#8f9a9e;stroke-width:.6');
		[0.5, 0.57, 0.64, 0.71].forEach(function (v) { o.line('R', 0.24, v, 0.76, v, '#7f8a8e', 1.1); });
		c = P(cx, cy, 1.79);
		o.svg.push(ell(c, 0.36, 'fill:#bcc5c8;stroke:#8f9a9e;stroke-width:.7'), ringSvg(id, c, 0.25));
		o.hub = P(cx, cy, 2.12);
	}
}
var HUB_TOP = { plug: 1.75, router: 1.4, gaming: 1.45, cube: 0.7, puck: 0.34, tower: 1.86 };
function objNode(id, cx, cy, model) {
	var f = formOf(model, 'tower'), o = new Obj(id, cx, cy, HUB_TOP[f.form] + (f.ant ? 0.35 : 0));
	hubBody(o, id, cx, cy, f, MESH);
	o.form = f.form;
	return o;
}
/* Clients: one drawing per kind, built around the stand's centre (cx, cy); objDevice below picks it. */
function drawTvSide(id, kind, cx, cy, face) {
	var o;
	o = new Obj(id, cx, cy, 1.92);
	o.box(cx - 0.4, cy - 0.5, 0, 0.5, 1.0, 0.08, M_DARK, { shadow: true });
	o.box(cx - 0.18, cy - 0.08, 0.08, 0.12, 0.16, 0.36, M_BLACK, { rim: false });
	o.box(cx - 0.06, cy - 1.35, 0.42, 0.12, 2.7, 1.5, M_BLACK, { shadow: true });
	o.screen('R', 'ar-scr2', true);
	o.target = P(cx, cy, 1.96);
	return o;
}
function drawTv(id, kind, cx, cy, face) {
	var o;
	o = new Obj(id, cx, cy, 1.97);
	o.box(cx - 0.5, cy - 0.25, 0, 1.0, 0.5, 0.08, M_DARK, { shadow: true });
	o.box(cx - 0.08, cy - 0.16, 0.08, 0.16, 0.12, 0.36, M_BLACK, { rim: false });
	o.box(cx - 1.4, cy - 0.06, 0.42, 2.8, 0.12, 1.55, M_BLACK, { shadow: true });
	o.screen('L', 'ar-scr1', true);
	o.led('L', 0.5, 0.035, BAD, 0, 0, 0.9);
	o.target = P(cx, cy, 1.99);
	return o;
}
function drawLaptop(id, kind, cx, cy, face) {
	var o;
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
	return o;
}
function drawPhone(id, kind, cx, cy, face) {
	var o;
	o = new Obj(id, cx, cy, 1.0);
	o.box(cx - 0.35, cy - 0.18, 0, 0.7, 0.42, 0.07, M_DARK, { shadow: true });
	o.box(cx - 0.25, cy - 0.05, 0.07, 0.5, 0.1, 0.95, M_BLACK);
	o.face('L', 0.09, 0.04, 0.91, 0.96, 'fill:url(#ar-scr4)');
	o.face('L', 0.36, 0.9, 0.64, 0.93, 'fill:#0d1214');
	o.face('L', 0.18, 0.5, 0.82, 0.62, 'fill:#ffffff;opacity:.2');
	o.target = P(cx, cy, 1.07);
	return o;
}
function drawTablet(id, kind, cx, cy, face) {
	var o;
	o = new Obj(id, cx, cy, 0.6);
	[[cx - 0.6, cy + 0.45], [cx + 0.48, cy + 0.45], [cx + 0.48, cy - 0.55]].forEach(function (l) { o.box(l[0], l[1], 0, 0.12, 0.12, 0.45, M_DARK, { rim: false }); });
	o.box(cx - 0.65, cy - 0.6, 0.45, 1.3, 1.2, 0.09, M_TABLE, { shadow: true });
	o.box(cx - 0.45, cy - 0.4, 0.54, 0.9, 0.75, 0.05, M_BLACK);
	o.face('T', 0.06, 0.07, 0.94, 0.93, 'fill:url(#ar-scr5)');
	o.face('T', 0.14, 0.18, 0.5, 0.5, 'fill:#ffffff;opacity:.16');
	o.target = P(cx, cy, 0.64);
	return o;
}
function drawNas(id, kind, cx, cy, face) {
	var o;
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
	return o;
}
function drawDesktop(id, kind, cx, cy, face) {   /* a tower PC with its monitor and keyboard */
	var o, b;
	o = new Obj(id, cx, cy, 1.22);
	o.box(cx - 0.95, cy - 0.5, 0, 0.5, 1.0, 1.15, M_DARK, { ao: true, shadow: true });
	b = o.last;
	o.face('L', 0.16, 0.72, 0.84, 0.9, 'fill:#141b1e;stroke:#0d1214;stroke-width:.6', b);
	o.line('L', 0.16, 0.62, 0.84, 0.62, 'rgba(255,255,255,.14)', 0.8, b);
	o.led('L', 0.28, 0.5, '#3ddc97', 0, 0, 1.1, b);
	o.line('L', 0.46, 0.5, 0.84, 0.5, DN, 1.2, b);
	[0.3, 0.38, 0.46, 0.54, 0.62].forEach(function (v) { o.line('R', 0.2, v, 0.8, v, '#1f2629', 1.3, b); });
	o.box(cx + 0.1, cy - 0.5, 0, 0.5, 0.3, 0.05, M_DARK, { shadow: true });
	o.box(cx + 0.3, cy - 0.38, 0.05, 0.1, 0.07, 0.3, M_BLACK, { rim: false });
	o.box(cx - 0.25, cy - 0.34, 0.3, 1.2, 0.07, 0.8, M_BLACK, { shadow: true });
	o.screen('L', 'ar-scr3', false);
	o.face('L', 0.1, 0.5, 0.6, 0.84, 'fill:#ffffff;opacity:.16');
	o.face('L', 0.66, 0.3, 0.9, 0.84, 'fill:#ffffff;opacity:.1');
	o.box(cx - 0.1, cy + 0.2, 0, 0.9, 0.3, 0.04, M_ALU);
	o.face('T', 0.05, 0.14, 0.95, 0.86, 'fill:#59646a');
	o.target = P(cx + 0.35, cy - 0.3, 1.12);
	return o;
}
function drawMac(id, kind, cx, cy, face) {   /* a compact aluminium desktop (Mac Studio, Mac mini) with its display */
	var o;
	o = new Obj(id, cx, cy, 1.24);
	o.box(cx - 0.55, cy - 0.52, 0, 0.6, 0.34, 0.04, M_ALU, { shadow: true });
	o.box(cx - 0.31, cy - 0.4, 0.04, 0.12, 0.06, 0.3, M_ALU, { rim: false });
	o.box(cx - 0.95, cy - 0.36, 0.3, 1.4, 0.06, 0.92, M_ALU, { shadow: true });
	o.face('L', 0, 0, 1, 1, 'fill:#11181b');
	o.screen('L', 'ar-scr2', false);
	o.face('L', 0.1, 0.5, 0.6, 0.84, 'fill:#ffffff;opacity:.16');
	o.box(cx + 0.02, cy + 0.02, 0, 0.74, 0.74, 0.36, M_ALU, { ao: true, shadow: true });
	o.face('L', 0.12, 0.34, 0.2, 0.54, 'fill:#59646a');
	o.face('L', 0.26, 0.34, 0.34, 0.54, 'fill:#59646a');
	o.face('L', 0.46, 0.38, 0.74, 0.5, 'fill:#59646a');
	o.led('L', 0.88, 0.44, '#f0efec', 0, 0, 0.8);
	o.face('T', 0.3, 0.3, 0.7, 0.7, 'fill:#c9d0d3;stroke:#8f999e;stroke-width:.5');
	o.target = P(cx - 0.25, cy - 0.33, 1.24);
	return o;
}
function drawLight(id, kind, cx, cy, face) {   /* a lit bulb on a small lamp foot */
	var o, g;
	o = new Obj(id, cx, cy, 0.95);
	o.box(cx - 0.2, cy - 0.2, 0, 0.4, 0.4, 0.08, M_DARK, { shadow: true });
	o.box(cx - 0.09, cy - 0.09, 0.08, 0.18, 0.18, 0.28, M_METAL, { rim: false });
	o.line('L', 0.05, 0.4, 0.95, 0.4, '#48555b', 0.9);
	o.line('L', 0.05, 0.72, 0.95, 0.72, '#48555b', 0.9);
	g = P(cx, cy, 0.62);
	o.svg.push('<circle cx="' + n1(g[0]) + '" cy="' + n1(g[1]) + '" r="15" style="fill:url(#ar-glow)"/>');
	o.svg.push('<circle cx="' + n1(g[0]) + '" cy="' + n1(g[1]) + '" r="7.5" style="fill:url(#ar-bulb);stroke:#ffe9a3;stroke-width:.9"/>');
	o.pts.push([g[0] - 9, g[1] - 9], [g[0] + 9, g[1] + 9]);
	o.target = P(cx, cy, 1.0);
	return o;
}
function drawAir(id, kind, cx, cy, face) {   /* a split air conditioner on a piece of wall */
	var o, g;
	o = new Obj(id, cx, cy, 1.6);
	o.box(cx - 0.9, cy - 0.3, 0, 1.8, 0.14, 1.55, M_WALL, { shadow: true });
	o.line('L', 0, 0.08, 1, 0.08, 'rgba(0,0,0,.3)', 1);
	o.box(cx - 0.75, cy - 0.16, 0.92, 1.5, 0.32, 0.44, M_WHITE, { shadow: true });
	o.face('L', 0.04, 0.08, 0.96, 0.32, 'fill:#aab4b8;stroke:#8f9a9e;stroke-width:.6');
	o.line('L', 0.07, 0.2, 0.93, 0.2, '#7f8a8e', 1);
	o.led('L', 0.9, 0.66, '#3ddc97', 0, 0, 1);
	[0.24, 0.5, 0.76].forEach(function (u) { g = o.fp('L', u, 0); o.svg.push(pline([[g[0], g[1] + 4], [g[0], g[1] + 11]], 'fill:none;stroke:' + DN + ';stroke-opacity:.7;stroke-width:1.4;stroke-linecap:round')); });
	o.target = P(cx, cy, 1.62);
	return o;
}
function drawPi(id, kind, cx, cy, face) {   /* a single-board computer (Raspberry Pi): a green board, its chip, pins and ports */
	var o, b, g;
	o = new Obj(id, cx, cy, 0.42);
	[[cx - 0.6, cy - 0.4], [cx + 0.48, cy - 0.4], [cx - 0.6, cy + 0.3], [cx + 0.48, cy + 0.3]].forEach(function (f) { o.box(f[0], f[1], 0, 0.1, 0.1, 0.08, M_METAL, { rim: false }); });
	o.box(cx - 0.68, cy - 0.46, 0.08, 1.36, 0.92, 0.05, M_PCB, { shadow: true });
	b = o.last;
	for (var i = 0; i < 10; i++) { g = o.fp('T', 0.1 + i * 0.062, 0.1, b); o.svg.push('<circle cx="' + n1(g[0]) + '" cy="' + n1(g[1]) + '" r="' + px(0.9) + '" style="fill:#d9b23a"/>'); }
	o.box(cx - 0.62, cy - 0.42, 0.13, 0.66, 0.1, 0.1, M_BLACK, { rim: false });   /* the pin header */
	o.box(cx - 0.3, cy - 0.12, 0.13, 0.34, 0.34, 0.05, M_METAL);                   /* the processor */
	o.face('T', 0.15, 0.15, 0.85, 0.85, 'fill:#a9b4b8');
	o.box(cx + 0.12, cy - 0.06, 0.13, 0.16, 0.24, 0.04, M_BLACK, { rim: false });   /* memory */
	o.box(cx + 0.34, cy - 0.42, 0.13, 0.34, 0.26, 0.24, M_ALU);                    /* two USB ports and the network port */
	o.box(cx + 0.34, cy - 0.12, 0.13, 0.34, 0.26, 0.24, M_ALU);
	o.box(cx + 0.34, cy + 0.18, 0.13, 0.34, 0.26, 0.26, M_ALU);
	o.face('R', 0.2, 0.25, 0.8, 0.75, 'fill:#141b1e');
	o.led('L', 0.08, 0.5, '#ff5c5c', 0, 0, 0.8, b);
	o.led('L', 0.14, 0.5, '#3ddc97', 1.3, 0, 0.8, b);
	o.target = P(cx, cy, 0.46);
	return o;
}
function drawStick(id, kind, cx, cy, face) {   /* a streaming stick (Fire TV Stick, Chromecast, Roku Stick) and its remote */
	var o;
	o = new Obj(id, cx, cy, 0.24);
	o.box(cx - 0.08, cy + 0.12, 0, 0.2, 0.78, 0.06, M_DARK, { shadow: true });   /* the remote */
	o.svg.push(ell(o.fp('T', 0.5, 0.25), 0.07, 'fill:#141b1e;stroke:#56646a;stroke-width:.8'));
	[0.45, 0.6, 0.75].forEach(function (v) { var g = o.fp('T', 0.5, v); o.svg.push('<circle cx="' + n1(g[0]) + '" cy="' + n1(g[1]) + '" r="' + px(0.9) + '" style="fill:#56646a"/>'); });
	o.box(cx - 0.58, cy - 0.5, 0, 0.92, 0.3, 0.14, M_BLACK, { shadow: true });   /* the stick */
	o.face('T', 0.08, 0.2, 0.55, 0.8, 'fill:none;stroke:rgba(255,255,255,.12);stroke-width:.8');
	o.led('L', 0.12, 0.5, DN, 2.4, 0, 0.9);
	o.box(cx + 0.34, cy - 0.44, 0.02, 0.2, 0.18, 0.1, M_METAL);                   /* its HDMI plug */
	o.target = P(cx, cy - 0.2, 0.26);
	return o;
}
function drawSmartSpeaker(id, kind, cx, cy, face) {   /* a cylinder smart speaker (Echo Studio, HomePod, Nest Audio): fabric, a light ring on top */
	var o, c;
	o = new Obj(id, cx, cy, 1.0);
	o.disc(cx, cy, 0, 0.42, 0.92, M_DARK, 'ar-cd', { shadow: true });
	[0.25, 0.45, 0.65].forEach(function (z) { var a = P(cx, cy, z), rx = 1.2247 * 0.42 * G.U, ry = 0.7071 * 0.42 * G.U;
		o.svg.push('<path d="M' + n1(a[0] - rx) + ' ' + n1(a[1]) + ' A' + n1(rx) + ' ' + n1(ry) + ' 0 0 0 ' + n1(a[0] + rx) + ' ' + n1(a[1]) + '" style="fill:none;stroke:#1f2629;stroke-width:1.1"/>'); });
	c = P(cx, cy, 0.92);
	o.svg.push(ell(c, 0.36, 'fill:none;stroke:' + DN + ';stroke-width:1.6'), ell(c, 0.2, 'fill:#141b1e'));
	[-0.11, 0.11].forEach(function (d) { var g = P(cx + d, cy - d, 0.92); o.svg.push('<circle cx="' + n1(g[0]) + '" cy="' + n1(g[1]) + '" r="' + px(1) + '" style="fill:#56646a"/>'); });
	o.target = P(cx, cy, 1.0);
	return o;
}
function drawSpeaker(id, kind, cx, cy, face) {   /* a smart speaker: fabric sides, a light ring on top */
	var o;
	o = new Obj(id, cx, cy, 0.9);
	o.box(cx - 0.3, cy - 0.3, 0, 0.6, 0.6, 0.85, M_DARK, { ao: true, shadow: true });
	[0.2, 0.32, 0.44, 0.56, 0.68, 0.8].forEach(function (v) { o.line('L', 0.14, v, 0.86, v, '#1f2629', 1.3); o.line('R', 0.14, v, 0.86, v, '#1a2023', 1.2); });
	o.svg.push(ell(P(cx, cy, 0.85), 0.17, 'fill:#141b1e;stroke:' + DN + ';stroke-width:1.2'));
	o.target = P(cx, cy, 0.92);
	return o;
}
function drawPrinter(id, kind, cx, cy, face) {
	var o, b;
	o = new Obj(id, cx, cy, 0.85);
	o.box(cx - 0.6, cy - 0.4, 0, 1.2, 0.8, 0.45, M_BODY, { ao: true, shadow: true });
	b = o.last;
	o.face('T', 0.07, 0.3, 0.93, 0.9, 'fill:none;stroke:rgba(255,255,255,.14);stroke-width:.8');
	o.face('L', 0.12, 0.22, 0.88, 0.46, 'fill:#141b1e;stroke:#0d1214;stroke-width:.6');
	o.led('L', 0.86, 0.74, '#3ddc97', 0, 0, 1);
	o.line('L', 0.12, 0.74, 0.5, 0.74, 'rgba(255,255,255,.18)', 1.2);
	o.box(cx - 0.4, cy - 0.36, 0.45, 0.8, 0.04, 0.4, M_WHITE, { rim: false });
	o.box(cx - 0.42, cy + 0.4, 0.1, 0.84, 0.3, 0.03, M_WHITE, { rim: false });
	o.target = P(cx, cy - 0.3, 0.88);
	return o;
}
function drawWatch(id, kind, cx, cy, face) {   /* a watch on its charging puck */
	var o;
	o = new Obj(id, cx, cy, 0.72);
	o.box(cx - 0.26, cy - 0.26, 0, 0.52, 0.52, 0.08, M_WHITE, { shadow: true });
	o.box(cx - 0.12, cy - 0.03, 0.08, 0.24, 0.08, 0.12, M_DARK, { rim: false });
	o.box(cx - 0.2, cy - 0.05, 0.2, 0.4, 0.12, 0.4, M_BLACK);
	o.face('L', 0.1, 0.08, 0.9, 0.92, 'fill:url(#ar-scr4)');
	o.face('L', 0.24, 0.46, 0.76, 0.6, 'fill:#ffffff;opacity:.2');
	o.box(cx - 0.12, cy - 0.03, 0.6, 0.24, 0.08, 0.1, M_DARK, { rim: false });
	o.target = P(cx, cy, 0.74);
	return o;
}
function drawCamera(id, kind, cx, cy, face) {   /* a camera head on a short post */
	var o;
	o = new Obj(id, cx, cy, 0.92);
	o.box(cx - 0.2, cy - 0.2, 0, 0.4, 0.4, 0.06, M_DARK, { shadow: true });
	o.box(cx - 0.05, cy - 0.05, 0.06, 0.1, 0.1, 0.48, M_DARK, { rim: false });
	o.box(cx - 0.2, cy - 0.3, 0.54, 0.4, 0.6, 0.34, M_WHITE, { shadow: true });
	o.face('L', 0.12, 0.12, 0.88, 0.88, 'fill:#141b1e');
	o.led('L', 0.5, 0.5, DN, 0, 0, 1.7);
	o.target = P(cx, cy, 0.94);
	return o;
}
function drawStreamer(id, kind, cx, cy, face) {   /* a streaming box or stick: Apple TV, Chromecast, Fire TV, Shield, Roku */
	var o;
	o = new Obj(id, cx, cy, 0.24);
	o.box(cx - 0.36, cy - 0.36, 0, 0.72, 0.72, 0.2, M_BLACK, { shadow: true });
	o.line('L', 0.1, 0.5, 0.7, 0.5, 'rgba(255,255,255,.14)', 0.8);
	o.led('L', 0.86, 0.5, DN, 0, 0, 1);
	o.face('T', 0.14, 0.14, 0.86, 0.86, 'fill:none;stroke:rgba(255,255,255,.14);stroke-width:.8');
	o.box(cx - 0.62, cy + 0.42, 0, 0.18, 0.5, 0.05, M_ALU, { rim: false });
	o.target = P(cx, cy, 0.26);
	return o;
}
function drawSoundbar(id, kind, cx, cy, face) {   /* a soundbar or AV receiver */
	var o;
	o = new Obj(id, cx, cy, 0.32);
	o.box(cx - 1.1, cy - 0.17, 0, 2.2, 0.34, 0.26, M_BLACK, { shadow: true });
	[0.3, 0.5, 0.7].forEach(function (v) { o.line('L', 0.04, v, 0.8, v, '#2c363a', 1.2); });
	o.led('L', 0.9, 0.5, DN, 0, 0, 1);
	o.target = P(cx, cy, 0.3);
	return o;
}
function drawDoorbellLock(id, kind, cx, cy, face) {   /* on a piece of door frame: a video doorbell, or a keypad lock */
	var o, g;
	o = new Obj(id, cx, cy, 1.3);
	o.box(cx - 0.4, cy - 0.2, 0, 0.8, 0.14, 1.25, M_WALL, { shadow: true });
	o.line('L', 0, 0.08, 1, 0.08, 'rgba(0,0,0,.3)', 1);
	o.box(cx - 0.15, cy - 0.06, 0.4, 0.3, 0.08, 0.7, kind === 'lock' ? M_METAL : M_BLACK);
	if (kind === 'lock') {
		[0.78, 0.62, 0.46].forEach(function (v) { [0.28, 0.5, 0.72].forEach(function (u) { g = o.fp('L', u, v); o.svg.push('<circle cx="' + n1(g[0]) + '" cy="' + n1(g[1]) + '" r=".9" style="fill:#20282b"/>'); }); });
		o.face('L', 0.4, 0.1, 0.6, 0.3, 'fill:#20282b');
	} else {
		o.led('L', 0.5, 0.76, DN, 0, 0, 1.5);
		g = o.fp('L', 0.5, 0.26);
		o.svg.push('<circle cx="' + n1(g[0]) + '" cy="' + n1(g[1]) + '" r="2.6" style="fill:#11181b;stroke:' + ACC + ';stroke-width:1"/>');
	}
	o.target = P(cx, cy, 1.3);
	return o;
}
function drawSensorThermostat(id, kind, cx, cy, face) {   /* a small puck: motion, door, temperature, leak, smoke; with a dial, a thermostat */
	var o, g;
	o = new Obj(id, cx, cy, 0.24);
	o.disc(cx, cy, 0, 0.3, 0.16, M_WHITE, 'ar-cw', { shadow: true });
	if (kind === 'thermostat') { o.svg.push(ell(P(cx, cy, 0.16), 0.2, 'fill:#141b1e;stroke:' + ACC + ';stroke-width:1.3')); o.svg.push(ell(P(cx, cy, 0.16), 0.07, 'fill:' + UPT)); }
	else { o.svg.push(ell(P(cx, cy, 0.16), 0.12, 'fill:#aeb8bb')); g = P(cx, cy, 0.16); o.svg.push('<circle cx="' + n1(g[0]) + '" cy="' + n1(g[1]) + '" r="1.2" class="df-a df-led" style="fill:#3ddc97;animation-duration:' + (3 + (hash(id) % 10) / 4) + 's"/>'); }
	o.target = P(cx, cy, 0.3);
	return o;
}
function drawPlug(id, kind, cx, cy, face) {   /* a smart plug: a white block with a socket on top */
	var o;
	o = new Obj(id, cx, cy, 0.42);
	o.box(cx - 0.21, cy - 0.21, 0, 0.42, 0.42, 0.38, M_WHITE, { shadow: true });
	o.face('T', 0.2, 0.2, 0.8, 0.8, 'fill:#aeb8bb');
	o.face('T', 0.34, 0.3, 0.42, 0.7, 'fill:#20282b'); o.face('T', 0.58, 0.3, 0.66, 0.7, 'fill:#20282b');
	o.led('L', 0.5, 0.5, '#3ddc97', 0, 0, 1.1);
	o.target = P(cx, cy, 0.46);
	return o;
}
function drawHub(id, kind, cx, cy, face) {   /* a smart-home hub or bridge */
	var o, g;
	o = new Obj(id, cx, cy, 0.22);
	o.box(cx - 0.36, cy - 0.36, 0, 0.72, 0.72, 0.16, M_WHITE, { shadow: true });
	[0.3, 0.5, 0.7].forEach(function (u, i) { g = o.fp('T', u, 0.72); o.svg.push('<circle cx="' + n1(g[0]) + '" cy="' + n1(g[1]) + '" r="1.3"' + (i === 1 ? ' class="df-a df-led"' : '') + ' style="fill:' + DN + (i === 1 ? ';animation-duration:' + (2.6 + (hash(id) % 10) / 4) + 's' : '') + '"/>'); });
	o.svg.push(ell(P(cx, cy - 0.06, 0.16), 0.13, 'fill:none;stroke:#8f9a9e;stroke-width:.8'));
	o.target = P(cx, cy, 0.24);
	return o;
}
function drawVacuum(id, kind, cx, cy, face) {   /* a robot vacuum */
	var o, g;
	o = new Obj(id, cx, cy, 0.3);
	o.disc(cx, cy, 0.03, 0.5, 0.15, M_DARK, 'ar-cd', { shadow: true });
	o.disc(cx - 0.1, cy - 0.1, 0.18, 0.15, 0.06, M_BLACK, 'ar-cd', { track: false });
	g = P(cx + 0.2, cy + 0.2, 0.18);
	o.svg.push('<circle cx="' + n1(g[0]) + '" cy="' + n1(g[1]) + '" r="1.3" style="fill:#3ddc97"/>');
	o.target = P(cx, cy, 0.3);
	return o;
}
function drawAppliance(id, kind, cx, cy, face) {   /* white goods: a washing machine, a dryer, a dishwasher, or another appliance */
	var o;
	o = new Obj(id, cx, cy, 1.2);
	o.box(cx - 0.5, cy - 0.5, 0, 1.0, 1.0, 1.15, M_WHITE, { ao: true, shadow: true });
	[0.3, 0.45, 0.6].forEach(function (v) { o.line('R', 0.2, v, 0.8, v, '#7f8a8e', 1.1); });
	if (kind === 'dishwasher') {   /* a plain door: the control strip along its top, a handle under it */
		o.face('L', 0.04, 0.84, 0.96, 0.96, 'fill:#20282b;stroke:#8f9a9e;stroke-width:.6');
		o.led('L', 0.84, 0.9, '#3ddc97', 0, 0, 0.9);
		o.face('L', 0.14, 0.88, 0.5, 0.92, 'fill:url(#ar-scr4);opacity:.7');
		o.face('L', 0.3, 0.7, 0.7, 0.75, 'fill:#8f9a9e');
		o.line('L', 0.04, 0.06, 0.96, 0.06, '#aab4b8', 1);
	} else {
		o.face('L', 0.08, 0.82, 0.92, 0.94, 'fill:#aab4b8;stroke:#8f9a9e;stroke-width:.6');
		o.led('L', 0.82, 0.88, '#3ddc97', 0, 0, 0.9);
		o.face('L', 0.22, 0.14, 0.78, 0.7, 'fill:#20282b;stroke:#8f9a9e;stroke-width:1');
		if (kind === 'dryer') {   /* an empty drum: no water, a lint filter under the door */
			o.face('L', 0.3, 0.2, 0.7, 0.64, 'fill:#3a4448');
			[0.36, 0.48].forEach(function (v) { o.line('L', 0.38, v, 0.62, v, '#56646a', 1); });
			o.face('L', 0.36, 0.04, 0.64, 0.09, 'fill:#8f9a9e');
		} else o.face('L', 0.3, 0.2, 0.7, 0.64, 'fill:url(#ar-scr4);opacity:.55');   /* water behind the glass */
	}
	o.target = P(cx, cy, 1.2);
	return o;
}
function drawPurifier(id, kind, cx, cy, face) {   /* an air purifier or humidifier: a white tower, its water tank, side grilles, an air ring on top */
	var o, c;
	o = new Obj(id, cx, cy, 1.25);
	o.box(cx - 0.32, cy - 0.32, 0, 0.64, 0.64, 1.2, M_WHITE, { ao: true, shadow: true });
	o.face('L', 0.1, 0.06, 0.9, 0.34, 'fill:#8fc3e3;fill-opacity:.55;stroke:#8f9a9e;stroke-width:.6');   /* the water tank */
	o.line('L', 0.1, 0.12, 0.9, 0.12, 'rgba(255,255,255,.5)', 0.8);
	[0.22, 0.36, 0.5, 0.64, 0.78].forEach(function (u) { o.line('L', u, 0.44, u, 0.9, '#9aa5a9', 1.1); o.line('R', u, 0.44, u, 0.9, '#8a9599', 1); });
	c = P(cx, cy, 1.2);
	o.svg.push(ell(c, 0.24, 'fill:#20282b;stroke:#8f9a9e;stroke-width:.8'), ell(c, 0.15, 'fill:none;stroke:' + DN + ';stroke-width:1.3'));
	o.led('L', 0.5, 0.96, '#3ddc97', 0, 0, 0.9);
	o.target = P(cx, cy, 1.26);
	return o;
}
function drawWallSwitch(id, kind, cx, cy, face) {   /* a smart light switch on a piece of wall */
	var o;
	o = new Obj(id, cx, cy, 1.3);
	o.box(cx - 0.4, cy - 0.2, 0, 0.8, 0.14, 1.25, M_WALL, { shadow: true });
	o.line('L', 0, 0.08, 1, 0.08, 'rgba(0,0,0,.3)', 1);
	o.box(cx - 0.21, cy - 0.06, 0.52, 0.42, 0.05, 0.42, M_WHITE);
	o.face('L', 0.26, 0.16, 0.74, 0.84, 'fill:#dfe4e6;stroke:#8f9a9e;stroke-width:.7');   /* the rocker */
	o.line('L', 0.3, 0.5, 0.7, 0.5, '#aab4b8', 0.8);
	o.led('L', 0.5, 0.72, '#3ddc97', 0, 0, 0.8);
	o.target = P(cx, cy, 1.3);
	return o;
}
function drawContact(id, kind, cx, cy, face) {   /* a door or window sensor: the sensor and its magnet, either side of a door's edge */
	var o;
	o = new Obj(id, cx, cy, 1.3);
	o.box(cx - 0.4, cy - 0.2, 0, 0.8, 0.14, 1.25, M_WALL, { shadow: true });
	o.line('L', 0, 0.08, 1, 0.08, 'rgba(0,0,0,.3)', 1);
	o.line('L', 0.56, 0.0, 0.56, 1, 'rgba(0,0,0,.45)', 1.4);                     /* the door's edge */
	o.box(cx - 0.3, cy - 0.06, 0.6, 0.16, 0.06, 0.42, M_WHITE);                 /* the sensor */
	o.led('L', 0.5, 0.82, DN, 2.8 + (hash(id) % 10) / 4, 0, 0.8);
	o.box(cx + 0.02, cy - 0.06, 0.66, 0.12, 0.06, 0.3, M_WHITE);                /* its magnet */
	o.target = P(cx, cy, 1.3);
	return o;
}
/* ---- the newer kinds: an EV charger, a car, solar, a robot mower, a VR headset, a projector, a garage door, a 3D printer,
   a smart display, smart blinds, a sprinkler, a pet feeder, a treadmill ---- */
var M_CAR = MAT('#b5473f'), M_GRASS = MAT('#4f8a3c'), M_PRINT = MAT('#e0a33a'), M_RED = MAT('#c0392b');
function curve(a, c1, c2, b, st) { return '<path d="M' + n1(a[0]) + ' ' + n1(a[1]) + ' C' + [c1, c2, b].map(function (p) { return n1(p[0]) + ' ' + n1(p[1]); }).join(' ') + '" style="' + st + '"/>'; }
function drawCharger(id, kind, cx, cy, face) {   /* an EV charger: a wallbox with its light strip, its cable looped down to the holster */
	var o;
	o = new Obj(id, cx, cy, 1.35);
	o.box(cx - 0.45, cy - 0.2, 0, 0.9, 0.14, 1.3, M_WALL, { shadow: true });
	o.line('L', 0, 0.08, 1, 0.08, 'rgba(0,0,0,.3)', 1);
	o.box(cx - 0.32, cy - 0.06, 0.55, 0.5, 0.12, 0.62, M_DARK, { shadow: true });
	o.face('L', 0.14, 0.64, 0.86, 0.86, 'fill:#141b1e;stroke:#56646a;stroke-width:.6');
	o.line('L', 0.24, 0.36, 0.76, 0.36, '#3ddc97', 1.8);
	o.led('L', 0.5, 0.75, DN, 2.2 + (hash(id) % 10) / 4, 0, 0.9);
	o.box(cx + 0.24, cy - 0.06, 0.62, 0.12, 0.1, 0.2, M_DARK);                     /* the holster */
	o.svg.push(curve(P(cx - 0.12, cy + 0.06, 0.55), P(cx - 0.14, cy + 0.12, -0.05), P(cx + 0.32, cy + 0.12, -0.05), P(cx + 0.3, cy + 0.04, 0.62),
		'fill:none;stroke:#1d2427;stroke-width:2.4;stroke-linecap:round'));
	o.target = P(cx, cy, 1.35);
	return o;
}
function drawCar(id, kind, cx, cy, face) {   /* an electric car: a red body, its cabin and windows, headlights, the charge light */
	var o;
	o = new Obj(id, cx, cy, 0.72);
	[cx - 0.55, cx + 0.3].forEach(function (x) { o.box(x, cy - 0.4, 0, 0.26, 0.08, 0.26, M_BLACK, { rim: false }); });   /* the far wheels, mostly hidden */
	o.box(cx - 0.75, cy - 0.36, 0.1, 1.5, 0.72, 0.3, M_CAR, { ao: true, shadow: true });
	o.face('R', 0.1, 0.5, 0.3, 0.75, 'fill:#ffe9a8'); o.face('R', 0.7, 0.5, 0.9, 0.75, 'fill:#ffe9a8');
	o.led('L', 0.08, 0.72, '#3ddc97', 1.6, 0, 0.9);
	o.box(cx - 0.45, cy - 0.3, 0.4, 0.82, 0.6, 0.26, M_CAR);
	o.face('L', 0.06, 0.14, 0.47, 0.86, 'fill:#1b2a33;stroke:#0d1214;stroke-width:.5'); o.face('L', 0.53, 0.14, 0.94, 0.86, 'fill:#1b2a33;stroke:#0d1214;stroke-width:.5');
	o.face('R', 0.08, 0.14, 0.92, 0.86, 'fill:#22343f;stroke:#0d1214;stroke-width:.5');
	o.face('T', 0.06, 0.08, 0.94, 0.92, 'fill:#2a3d48;opacity:.85');   /* a glass roof */
	[cx - 0.42, cx + 0.43].forEach(function (x) {   /* the near wheels: round, in the car's side */
		var ring = function (r) { var ps = []; for (var t = 0; t < 16; t++) ps.push(P(x + r * Math.cos(t * Math.PI / 8), cy + 0.37, 0.14 + r * Math.sin(t * Math.PI / 8))); return ps; };
		o.svg.push(poly(ring(0.14), 'fill:#1d2427;stroke:#0b1012;stroke-width:.7'), poly(ring(0.065), 'fill:#8f9a9e'));
	});
	o.target = P(cx, cy, 0.72);
	return o;
}
function drawSolar(id, kind, cx, cy, face) {   /* solar and a home battery: a battery tower with its charge level, a panel tilted to the sun */
	var o, a, b, c, d, i, f;
	o = new Obj(id, cx, cy, 1.2);
	o.box(cx + 0.05, cy - 0.32, 0, 0.6, 0.42, 1.15, M_WHITE, { ao: true, shadow: true });
	for (i = 0; i < 4; i++) o.face('L', 0.32, 0.34 + i * 0.12, 0.68, 0.42 + i * 0.12, 'fill:' + (i < 3 ? '#3ddc97' : '#56646a'));
	o.led('L', 0.5, 0.9, DN, 0, 0, 0.8);
	o.svg.push(pline([P(cx - 0.45, cy + 0.05, 0), P(cx - 0.45, cy + 0.05, 0.42)], 'fill:none;stroke:#56646a;stroke-width:1.6'));   /* its leg */
	a = P(cx - 0.85, cy + 0.42, 0.1); b = P(cx - 0.05, cy + 0.42, 0.1); c = P(cx - 0.05, cy - 0.16, 0.66); d = P(cx - 0.85, cy - 0.16, 0.66);
	o.svg.push(poly([a, b, c, d], 'fill:#1d3a5c;stroke:#8f9a9e;stroke-width:.8'));
	f = function (p, q, t) { return [p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t]; };
	[0.25, 0.5, 0.75].forEach(function (t) { o.svg.push(pline([f(a, b, t), f(d, c, t)], 'fill:none;stroke:rgba(159,214,255,.45);stroke-width:.7')); });
	[0.5].forEach(function (t) { o.svg.push(pline([f(a, d, t), f(b, c, t)], 'fill:none;stroke:rgba(159,214,255,.45);stroke-width:.7')); });
	o.svg.push(poly([f(d, c, 0.08), f(d, c, 0.4), f(f(a, d, 0.62), f(b, c, 0.62), 0.3)], 'fill:#ffffff;opacity:.1'));
	o.pts.push(a, b, c, d);
	o.target = P(cx + 0.2, cy, 1.2);
	return o;
}
function drawMower(id, kind, cx, cy, face) {   /* a robot lawn mower: a low body, its green shell and red stop button, a few blades of grass */
	var o;
	o = new Obj(id, cx, cy, 0.45);
	[[cx - 0.62, cy + 0.42], [cx + 0.66, cy - 0.1], [cx + 0.1, cy + 0.5], [cx - 0.2, cy + 0.55]].forEach(function (g) {
		o.svg.push(pline([P(g[0], g[1], 0), P(g[0] - 0.03, g[1], 0.13)], 'fill:none;stroke:#5fa04a;stroke-width:1.3;stroke-linecap:round'), pline([P(g[0] + 0.05, g[1], 0), P(g[0] + 0.09, g[1], 0.1)], 'fill:none;stroke:#5fa04a;stroke-width:1.3;stroke-linecap:round')); });
	[cx - 0.48, cx + 0.22].forEach(function (x) { o.box(x, cy - 0.44, 0, 0.26, 0.08, 0.24, M_BLACK, { rim: false }); });
	o.box(cx - 0.6, cy - 0.38, 0.06, 1.2, 0.76, 0.18, M_BODY, { ao: true, shadow: true });
	o.face('R', 0.1, 0.3, 0.9, 0.6, 'fill:#20282b');                              /* its bumper */
	o.box(cx - 0.46, cy - 0.3, 0.24, 0.86, 0.6, 0.1, M_GRASS);
	o.disc(cx + 0.06, cy - 0.02, 0.34, 0.1, 0.05, M_RED, 'ar-cd', { track: false });
	[cx - 0.48, cx + 0.22].forEach(function (x) { o.box(x, cy + 0.36, 0, 0.26, 0.08, 0.24, M_BLACK, { rim: false }); o.face('L', 0.3, 0.3, 0.7, 0.7, 'fill:#56646a'); });
	o.led('L', 0.88, 0.5, '#3ddc97', 2.4, 0, 0.8, [cx - 0.6, cy - 0.38, 0.06, 1.2, 0.76, 0.18]);
	o.target = P(cx, cy, 0.45);
	return o;
}
function drawVr(id, kind, cx, cy, face) {   /* a VR headset: a white visor, its dark front with two cameras, the strap behind; two controllers */
	var o;
	o = new Obj(id, cx, cy, 0.5);
	o.svg.push(ell(P(cx, cy - 0.42, 0.24), 0.4, 'fill:none;stroke:#1d2427;stroke-width:' + px(2.6)), ell(P(cx, cy - 0.42, 0.24), 0.4, 'fill:none;stroke:#3b484e;stroke-width:' + px(1.2)));   /* the head strap */
	o.box(cx - 0.42, cy - 0.16, 0.08, 0.84, 0.34, 0.32, M_WHITE, { ao: true, shadow: true });
	o.face('L', 0.03, 0.08, 0.97, 0.92, 'fill:#20282b;stroke:#8f9a9e;stroke-width:.7');   /* the visor */
	[0.27, 0.73].forEach(function (u) { var g = o.fp('L', u, 0.5); o.svg.push('<circle cx="' + n1(g[0]) + '" cy="' + n1(g[1]) + '" r="' + px(3.2) + '" style="fill:#2c363a;stroke:#56646a;stroke-width:.8"/>'); });
	o.led('L', 0.5, 0.78, DN, 2.6, 0, 0.7);
	[[cx + 0.52, cy + 0.02], [cx + 0.56, cy + 0.38]].forEach(function (g) {   /* two controllers, each with its tracking ring */
		o.box(g[0], g[1], 0, 0.12, 0.12, 0.26, M_WHITE, { shadow: true });
		o.svg.push(ell(P(g[0] + 0.06, g[1] + 0.06, 0.32), 0.14, 'fill:none;stroke:#d3dadc;stroke-width:' + px(1.6)));
	});
	o.target = P(cx, cy, 0.5);
	return o;
}
function drawProjector(id, kind, cx, cy, face) {   /* a projector: a white box, its lens and a soft beam forward */
	var o, l, r;
	o = new Obj(id, cx, cy, 0.42);
	o.box(cx - 0.42, cy - 0.32, 0, 0.84, 0.64, 0.32, M_WHITE, { ao: true, shadow: true });
	[0.25, 0.4, 0.55, 0.7].forEach(function (u) { o.line('R', u, 0.3, u, 0.75, '#9aa5a9', 1); });
	o.face('L', 0.08, 0.35, 0.4, 0.65, 'fill:#aab4b8');
	l = o.fp('L', 0.7, 0.5); r = px(5.5);
	o.svg.push(poly([l, P(cx - 0.12, cy + 1.05, 0.5), P(cx + 0.46, cy + 1.05, -0.02)], 'fill:' + DNT + ';opacity:.13'));
	o.svg.push('<circle cx="' + n1(l[0]) + '" cy="' + n1(l[1]) + '" r="' + r + '" style="fill:#141b1e;stroke:#56646a;stroke-width:1.2"/>',
		'<circle cx="' + n1(l[0]) + '" cy="' + n1(l[1]) + '" r="' + px(2.6) + '" style="fill:' + DN + ';opacity:.85"/>');
	o.led('T', 0.85, 0.2, '#3ddc97', 0, 0, 0.8);
	o.target = P(cx, cy, 0.42);
	return o;
}
function drawGarage(id, kind, cx, cy, face) {   /* a garage door: a sectional door in a piece of wall, the opener's box above it */
	var o;
	o = new Obj(id, cx, cy, 1.3);
	o.box(cx - 0.6, cy - 0.2, 0, 1.2, 0.14, 1.25, M_WALL, { shadow: true });
	o.face('L', 0.1, 0, 0.9, 0.76, 'fill:#aab4b8;stroke:#7f8a8e;stroke-width:.8');
	[0.19, 0.38, 0.57].forEach(function (v) { o.line('L', 0.1, v, 0.9, v, '#7f8a8e', 1); });
	o.line('L', 0.44, 0.1, 0.56, 0.1, '#56646a', 1.4);
	o.box(cx - 0.12, cy - 0.06, 1.0, 0.24, 0.08, 0.14, M_DARK);
	o.led('L', 0.5, 0.5, '#3ddc97', 2.8, 0, 0.8);
	o.target = P(cx, cy, 1.3);
	return o;
}
function drawPrinter3d(id, kind, cx, cy, face) {   /* a 3D printer: an open frame, the bed with a print on it, the head on its gantry */
	var o;
	o = new Obj(id, cx, cy, 1.15);
	o.box(cx - 0.45, cy - 0.45, 0, 0.9, 0.9, 0.14, M_DARK, { ao: true, shadow: true });
	o.box(cx - 0.36, cy - 0.36, 0.14, 0.72, 0.72, 0.03, M_METAL, { rim: false });
	[cx - 0.45, cx + 0.39].forEach(function (x) { o.box(x, cy - 0.36, 0.14, 0.06, 0.06, 0.96, M_BODY, { rim: false }); });
	o.box(cx - 0.45, cy - 0.36, 1.06, 0.9, 0.06, 0.06, M_BODY);
	o.box(cx - 0.45, cy - 0.33, 0.62, 0.9, 0.04, 0.04, M_METAL, { rim: false });
	o.box(cx - 0.11, cy - 0.06, 0.17, 0.22, 0.22, 0.22, M_PRINT);
	o.box(cx - 0.08, cy - 0.29, 0.5, 0.16, 0.18, 0.2, M_BLACK);
	o.led('L', 0.5, 0.7, ACC, 1.4, 0, 0.8);
	o.svg.push(pline([P(cx, cy - 0.2, 0.5), P(cx, cy - 0.2, 0.42)], 'fill:none;stroke:#c9a400;stroke-width:1.4'));
	o.target = P(cx, cy, 1.15);
	return o;
}
function drawDisplay(id, kind, cx, cy, face) {   /* a smart display (Echo Show, Nest Hub): a screen on a fabric speaker base */
	var o;
	o = new Obj(id, cx, cy, 0.8);
	o.box(cx - 0.42, cy - 0.2, 0, 0.84, 0.38, 0.22, M_DARK, { shadow: true });
	[0.3, 0.6].forEach(function (v) { o.line('L', 0.05, v, 0.95, v, '#1f2629', 1.1); });
	o.box(cx - 0.42, cy - 0.16, 0.22, 0.84, 0.07, 0.54, M_BLACK, { shadow: true });
	o.screen('L', 'ar-scr3', true);
	o.target = P(cx, cy, 0.8);
	return o;
}
function drawBlinds(id, kind, cx, cy, face) {   /* smart blinds: a window in a piece of wall, the blind half down, its motor rail on top */
	var o;
	o = new Obj(id, cx, cy, 1.45);
	o.box(cx - 0.5, cy - 0.2, 0, 1.0, 0.14, 1.4, M_WALL, { shadow: true });
	o.face('L', 0.15, 0.2, 0.85, 0.86, 'fill:#355a70;stroke:#8f9a9e;stroke-width:.8');
	o.line('L', 0.5, 0.2, 0.5, 0.48, '#8f9a9e', 0.8);
	o.face('L', 0.15, 0.48, 0.85, 0.86, 'fill:#d3dadc');
	[0.56, 0.64, 0.72, 0.8].forEach(function (v) { o.line('L', 0.15, v, 0.85, v, '#9aa5a9', 0.9); });
	o.line('L', 0.15, 0.48, 0.85, 0.48, '#7f8a8e', 1.5);
	o.box(cx - 0.38, cy - 0.06, 1.22, 0.76, 0.07, 0.08, M_WHITE);
	o.led('L', 0.92, 0.5, '#3ddc97', 0, 0, 0.7);
	o.target = P(cx, cy, 1.45);
	return o;
}
function drawSprinkler(id, kind, cx, cy, face) {   /* a sprinkler: a patch of lawn, the pop-up head spraying both ways, its controller */
	var o, t, w = 'fill:none;stroke:' + DN + ';stroke-opacity:.8;stroke-width:1.5;stroke-dasharray:2 3;stroke-linecap:round';
	o = new Obj(id, cx, cy, 0.62);
	o.disc(cx, cy, 0, 0.58, 0.03, M_GRASS, 'ar-cd', { shadow: true });
	o.box(cx - 0.44, cy - 0.44, 0.03, 0.22, 0.12, 0.38, M_WHITE, { shadow: true });   /* its controller */
	o.led('L', 0.5, 0.75, '#3ddc97', 2.4, 0, 0.8);
	o.disc(cx, cy, 0.03, 0.09, 0.05, M_DARK, 'ar-cd', { track: false });
	o.box(cx - 0.03, cy - 0.03, 0.08, 0.06, 0.06, 0.22, M_METAL, { rim: false });
	t = P(cx, cy, 0.32);
	o.svg.push(curve(t, P(cx - 0.05, cy + 0.15, 0.85), P(cx - 0.1, cy + 0.42, 0.5), P(cx - 0.1, cy + 0.55, 0.06), w),
		curve(t, P(cx + 0.15, cy - 0.05, 0.85), P(cx + 0.42, cy - 0.1, 0.5), P(cx + 0.55, cy - 0.1, 0.06), w));
	o.pts.push(P(cx, cy, 0.62));
	o.target = P(cx, cy, 0.62);
	return o;
}
function drawPet(id, kind, cx, cy, face) {   /* a pet feeder: a white hopper with food behind its window, a bowl in front */
	var o;
	o = new Obj(id, cx, cy, 0.85);
	o.box(cx - 0.3, cy - 0.42, 0, 0.6, 0.45, 0.8, M_WHITE, { ao: true, shadow: true });
	o.face('L', 0.2, 0.46, 0.8, 0.86, 'fill:#b5793d;fill-opacity:.75;stroke:#8f9a9e;stroke-width:.6');
	o.led('L', 0.5, 0.3, '#3ddc97', 0, 0, 0.8);
	o.disc(cx, cy + 0.32, 0, 0.22, 0.09, M_WHITE, 'ar-cw', { shadow: true });
	o.svg.push(ell(P(cx, cy + 0.32, 0.09), 0.15, 'fill:#8a5a2b'));
	o.target = P(cx, cy - 0.1, 0.85);
	return o;
}
function drawFitness(id, kind, cx, cy, face) {   /* fitness equipment: a treadmill, its belt, two uprights and the console with a screen */
	var o;
	o = new Obj(id, cx, cy, 1.05);
	o.box(cx - 0.75, cy - 0.3, 0.02, 1.3, 0.6, 0.14, M_DARK, { ao: true, shadow: true });
	o.face('T', 0.03, 0.14, 0.97, 0.86, 'fill:#141b1e');
	[cx + 0.42].forEach(function (x) { o.box(x, cy - 0.3, 0.16, 0.06, 0.06, 0.78, M_METAL, { rim: false }); o.box(x, cy + 0.24, 0.16, 0.06, 0.06, 0.78, M_METAL, { rim: false }); });
	o.box(cx + 0.38, cy - 0.32, 0.94, 0.16, 0.64, 0.1, M_BLACK, { shadow: true });
	o.face('T', 0.15, 0.2, 0.85, 0.8, 'fill:url(#ar-scr2)');
	o.led('L', 0.5, 0.5, '#3ddc97', 0, 0, 0.7, [cx - 0.75, cy - 0.3, 0.02, 1.3, 0.6, 0.14]);
	o.target = P(cx, cy, 1.05);
	return o;
}
function drawIot(id, kind, cx, cy, face) {
	var o;
	o = new Obj(id, cx, cy, 0.42);
	o.box(cx - 0.21, cy - 0.21, 0, 0.42, 0.42, 0.42, M_WHITE, { shadow: true });
	o.face('T', 0.3, 0.3, 0.7, 0.7, 'fill:#aeb8bb');
	o.led('L', 0.5, 0.55, ACC, 2.6 + (hash(id) % 10) / 4, -(hash(id) % 7) / 3, 1.2);
	o.target = P(cx, cy, 0.5);
	return o;
}
function drawSwitch(id, kind, cx, cy, face) {
	var o, b;
	o = new Obj(id, cx, cy, 0.3);
	o.box(cx - 0.8, cy - 0.4, 0, 1.6, 0.8, 0.24, M_BODY, { shadow: true });
	b = o.last;
	for (var i = 0; i < 5; i++) { var u = 0.1 + i * 0.165; o.face('L', u, 0.22, u + 0.11, 0.7, 'fill:#11181b;stroke:#c9a400;stroke-width:.7', b); o.led('L', u + 0.055, 0.86, '#3ddc97', i % 2 ? 0.8 : 0, -i * 0.2, 0.8, b); }
	o.target = P(cx, cy, 0.3);
	return o;
}
function drawConsole(id, kind, cx, cy, face) {
	var o;
	o = new Obj(id, cx, cy, 0.3);
	o.box(cx - 0.6, cy - 0.42, 0, 1.2, 0.84, 0.24, M_BLACK, { shadow: true });
	o.line('L', 0.08, 0.5, 0.92, 0.5, DN, 1.2);
	o.face('T', 0.1, 0.12, 0.9, 0.88, 'fill:none;stroke:rgba(255,255,255,.14);stroke-width:.8');
	o.target = P(cx, cy, 0.32);
	return o;
}
function drawGeneric(id, kind, cx, cy, face) {
	var o;
	o = new Obj(id, cx, cy, 0.45);
	o.box(cx - 0.45, cy - 0.35, 0, 0.9, 0.7, 0.4, M_DARK, { ao: true, shadow: true });
	o.face('T', 0.15, 0.18, 0.85, 0.82, 'fill:none;stroke:rgba(255,255,255,.14);stroke-width:.8');
	o.led('L', 0.24, 0.6, '#3ddc97', 1.9 + (hash(id) % 10) / 5, 0, 1.1);
	o.line('L', 0.4, 0.6, 0.85, 0.6, 'rgba(255,255,255,.18)', 1.2);
	o.target = P(cx, cy, 0.46);
	return o;
}
var DRAW = {
	tv: drawTv, laptop: drawLaptop, phone: drawPhone, tablet: drawTablet, nas: drawNas, desktop: drawDesktop, mac: drawMac, light: drawLight,
	air: drawAir, speaker: drawSpeaker, printer: drawPrinter, watch: drawWatch, camera: drawCamera, streamer: drawStreamer, soundbar: drawSoundbar,
	doorbell: drawDoorbellLock, lock: drawDoorbellLock, sensor: drawSensorThermostat, thermostat: drawSensorThermostat, plug: drawPlug, hub: drawHub,
	vacuum: drawVacuum, appliance: drawAppliance, washer: drawAppliance, dryer: drawAppliance, dishwasher: drawAppliance, iot: drawIot, switch: drawSwitch, console: drawConsole, generic: drawGeneric,
	pi: drawPi, stick: drawStick, smartspeaker: drawSmartSpeaker, purifier: drawPurifier, wallswitch: drawWallSwitch, contact: drawContact,
	charger: drawCharger, car: drawCar, solar: drawSolar, mower: drawMower, vr: drawVr, projector: drawProjector, garage: drawGarage, printer3d: drawPrinter3d,
	display: drawDisplay, blinds: drawBlinds, sprinkler: drawSprinkler, pet: drawPet, fitness: drawFitness
};
/* Devices on the map: one drawing per kind, at (cx, cy) on the floor, facing left (the default) or right.
   Kinds without a drawing of their own get the generic box. */
function objDevice(id, kind, cx, cy, face) {
	var draw = kind === 'tv' && face === 'R' ? drawTvSide : (DRAW[kind] || drawGeneric);
	return draw(id, kind, cx, cy, face);
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
	{ cx: 11.55, cy: 0.95, zone: [10.4, 0, 18, 6.4], text: [10.7, 6.05], dev: [{ cx: 16.98, cy: 1.9, face: 'R' }, { cx: 16.4, cy: 4.45 }, { cx: 13.9, cy: 4.75 }] },
	{ cx: 1.3, cy: 9.6, zone: [0, 8.3, 5.3, 14], text: [0.35, 13.6], dev: [{ cx: 3.55, cy: 12.55 }, { cx: 1.35, cy: 12.55 }, { cx: 3.9, cy: 9.8 }] }
];
var WIFI_SLOTS = [{ cx: 14.4, cy: 10.6 }, { cx: 16.6, cy: 7.4 }, { cx: 12.4, cy: 12.75 }, { cx: 10.9, cy: 9.9 }];
var WIRED_SLOTS = [
	{ cx: 8.25, cy: 13.18, route: [[8.0, 8.35], [8.0, 13.1]] },
	{ cx: 3.17, cy: 11.83, route: [[6.3, 8.35], [6.3, 11.83], [4.1, 11.83]], needsNoNodeB: true }
];
var TRAY = { cx: 1.7, cy: 5.3 };

/* ---------------------------------------------------------------- geometry
   The small view's numbers are the hand-placed ones above, so it does not move by a pixel. The expanded
   view grows the floor around the same core (internet terminal, router, WAN pipe keep their world
   coordinates; only the origin moves) and generates its stands from the floor size, nearest first. */
function geomSmall() {
	return { key: 's', big: false, U: 24, OX: 322, OY: 96, x0: 0, y0: 0, x1: 18, y1: 14, SW: 728, SH: 518, hit: 44,
		nodeSlots: NODE_SLOTS, wifiSlots: WIFI_SLOTS, wiredSlots: WIRED_SLOTS, tray: TRAY,
		flow: { x: { src: 80, rt: 190, link: 298, mesh: 434, dev: 516 }, rowLeft: 530, rowW: 190, rows: 8, rowMin: 44, target: 230, top: 88, limit: 508 } };
}
/* Five pipes, one per LAN port, so wired devices never land on the tray in the big view. Two lanes leave
   each collar on the router's front (the collars are wider there), one leaves its side. */
var BIG_WIRED = [
	{ cx: 8.25, cy: 13.18, route: [[8.0, 8.35], [8.0, 13.1]] },
	{ cx: 3.17, cy: 11.83, route: [[5.85, 8.35], [5.85, 11.83], [4.1, 11.83]] },
	{ cx: 12.4, cy: 10.6, route: [[8.45, 8.35], [8.45, 10.6], [11.4, 10.6]] },
	{ cx: 6.55, cy: 15.75, route: [[6.3, 8.35], [6.3, 15.65]] },
	{ cx: 12.6, cy: 7.25, route: [[8.75, 7.25], [11.6, 7.25]] }
];
/* w, h: the stage's size in pixels; nodes: how many AiMesh nodes get a zone (up to three) */
function geomBig(w, h, nodes) {
	var U = Math.max(24, Math.min(30, Math.round(h / 28))), cu = CC * U;
	var n = Math.min(Math.floor((w - 64) / cu), Math.floor((h - 134) * 2 / U));   /* floor cells across both axes that fit */
	n = Math.max(32, Math.min(n, 52));
	var fx = Math.round(n * 9 / 16), fy = n - fx;                                     /* the small floor is 18 × 14 */
	var x0 = -Math.round((fx - 18) * 0.4) || 0, y0 = -Math.round((fy - 14) * 0.4) || 0;
	var g = { big: true, U: U, x0: x0, y0: y0, x1: x0 + fx, y1: y0 + fy, SW: w, SH: h, hit: 56, nodes: Math.min(nodes || 0, 3), tray: TRAY };
	g.OX = Math.round((w - n * cu) / 2 + (g.y1 - x0) * cu);   /* the floor centred across the stage */
	g.OY = 96 - Math.round((x0 + y0) * U / 2);
	g.key = 'b' + U + 'x' + fx + 'x' + fy + 'n' + g.nodes + 'w' + w + 'h' + h;
	var keep = G;
	G = g;   /* genSlots projects points to test them against the overlays */
	try { genSlots(g); } finally { G = keep; }
	g.flow = flowGeom(w, h);
	return g;
}
function box2(a, b, pad) { return [Math.min(a[0], b[0]) - pad, Math.min(a[1], b[1]) - pad, Math.max(a[0], b[0]) + pad, Math.max(a[1], b[1]) + pad]; }
function genSlots(g) {
	var cells = [], pitchX = 3.0, pitchY = 2.6;
	var inR = function (x, y, r) { return x > r[0] && x < r[2] && y > r[1] && y < r[3]; };
	/* node zones: back right and front left as in the small view, a third front right. On a small floor (a
	   short or narrow window) they shrink, so none reaches under the router or into another zone. */
	var RT = [3.9, 4.3, 10.3, 9.9];   /* the router and its base plate, with half a cell of room */
	var z0 = [Math.max(g.x1 - 10.5, RT[2] + 0.4), g.y0, g.x1, g.y0 + 9];
	var z1 = [g.x0, Math.max(g.y1 - 8.4, RT[3] + 0.3), g.x0 + 9, g.y1];
	var z2 = [Math.max(g.x1 - 9.5, z1[2] + 0.3), Math.max(g.y1 - 8, z0[3] + 0.3), g.x1, g.y1];
	if (z2[0] < RT[2] + 0.4) z2[1] = Math.max(z2[1], RT[3] + 0.3);
	g.nodeSlots = [
		{ zone: z0, cx: z0[0] + 1.15, cy: g.y0 + 0.95 },
		{ zone: z1, cx: g.x0 + 1.3, cy: z1[1] + 1.3 },
		{ zone: z2, cx: z2[0] + 1.2, cy: z2[1] + 1.2 }
	].slice(0, g.nodes);
	var keep = [RT, [0.4, 0.6, 3.2, 2.9], [3.2, 0.9, 7.9, 2.5], [6.3, 2.5, 7.9, 4.8],   /* router, internet terminal, WAN pipe */
		[1.0, g.y0, 2.4, 1.2], [g.x0, 3.9, 3.2, 6.9]];                                                   /* the fibre from the wall, the tray */
	var inFloor = function (s) { return s.cx - 1.4 > g.x0 && s.cx + 1.4 < g.x1 && s.cy - 1.3 > g.y0 && s.cy + 1.3 < g.y1; };
	var inZone = function (s) { return g.nodeSlots.some(function (ns) { return inR(s.cx, s.cy, ns.zone) || s.route.some(function (p) { return inR(p[0], p[1], ns.zone); }); }); };
	g.wiredSlots = BIG_WIRED.filter(function (s) { return inFloor(s) && !inZone(s); });
	g.wiredSlots.forEach(function (s) {
		keep.push([s.cx - 1.6, s.cy - 1.4, s.cx + 1.6, s.cy + 1.4]);
		s.route.forEach(function (p, i) { if (i) keep.push(box2(s.route[i - 1], p, 0.6)); });
	});
	var overlay = function (x, y) {   /* the map's text, legend and notice */
		var p = P(x, y, 0.8);
		return (p[0] < 250 && p[1] < 84) || (p[0] > g.SW - 270 && p[1] < 70) || (p[0] < 450 && p[1] > g.SH - 46);
	};
	for (var i = 0, x = g.x0 + 1.6; x <= g.x1 - 1.4; i++, x += pitchX) for (var j = 0, y = g.y0 + 1.5; y <= g.y1 - 1.3; j++, y += pitchY) {
		if (keep.some(function (r) { return inR(x, y, r); }) || overlay(x, y)) continue;
		cells.push({ cx: +x.toFixed(2), cy: +y.toFixed(2), odd: (i + j) % 2 });
	}
	g.nodeSlots.forEach(function (ns) {
		ns.text = [ns.zone[0] + 0.3, ns.zone[3] - 0.35];
		ns.dev = [];
		cells.forEach(function (c) {
			if (c.taken || !inR(c.cx, c.cy, ns.zone)) return;
			c.taken = 1;   /* a zone's cells are its node's, even the ones too close to the node to use */
			if (Math.abs(c.cx - ns.cx) + Math.abs(c.cy - ns.cy) <= 1.8 || c.cy > ns.zone[3] - 1.2) return;
			ns.dev.push({ cx: c.cx, cy: c.cy, face: c.cx > ns.zone[2] - 1.7 ? 'R' : undefined });
		});
		ns.dev.sort(function (a, b) { return Math.abs(a.cx - ns.cx) + Math.abs(a.cy - ns.cy) - Math.abs(b.cx - ns.cx) - Math.abs(b.cy - ns.cy); });
	});
	/* as many stands as the stage has room for labels: about one per 24,000 px², the node and wired ones included */
	var d = function (c) { return Math.abs(c.cx - 7.1) + Math.abs(c.cy - 7.1); };
	var cap = Math.round(g.SW * g.SH / 24000) - g.wiredSlots.length - g.nodeSlots.reduce(function (a, ns) { return a + ns.dev.length; }, 0);
	g.wifiSlots = cells.filter(function (c) { return !c.taken; }).sort(function (a, b) { return a.odd - b.odd || d(a) - d(b); }).slice(0, Math.max(8, Math.min(40, cap)))
		.map(function (c) { return { cx: c.cx, cy: c.cy }; });
}
G = geomSmall();

function pickStands(list, n, prevKey) {   /* the n busiest, keeping devices that already have a stand unless something is 3x busier */
	var cur = list.filter(function (dv) { return A.slot[dv.id] && A.slot[dv.id].g === prevKey; });
	var score = function (dv) { return busy(dv) * (A.slot[dv.id] && A.slot[dv.id].g === prevKey ? 3 : 1) + (dv.st === 'ok' ? 1e-6 : 0); };
	var ranked = list.slice().sort(function (a, b) { return score(b) - score(a) || byName(a, b); });
	var keep = ranked.slice(0, n);
	if (cur.length && Date.now() - A.slotAt < 20000) {   /* hold the stands for 20 s unless devices joined or left */
		if (cur.length >= Math.min(n, list.length)) keep = cur.slice(0, n);
	}
	return keep;
}
function mapLayout(net) {
	var L = { nodes: [], devs: [], tray: [], wired: [] };
	var shownNodes = net.nodes.slice(0, G.nodeSlots.length);
	shownNodes.forEach(function (n, i) { L.nodes.push({ node: n, slot: G.nodeSlots[i] }); });
	var visible = net.devs.filter(function (dv) { return dv.st !== 'off'; });
	var nodeB = shownNodes.length > 1;
	/* wired */
	var wslots = G.wiredSlots.filter(function (s) { return !(s.needsNoNodeB && nodeB); });
	var wired = visible.filter(function (dv) { return dv.link === 'wired'; });
	var wk = pickStands(wired, wslots.length, 'w');
	/* the router's Wi-Fi clients */
	var direct = visible.filter(function (dv) { return dv.link === 'wifi' && !dv.node; });
	var dk = pickStands(direct, G.wifiSlots.length, 'r');
	/* each node's clients */
	var nk = {};
	shownNodes.forEach(function (n, i) { nk[n.mac] = pickStands(visible.filter(function (dv) { return dv.node === n; }), G.nodeSlots[i].dev.length, 'n' + i); });
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
	put(dk, 'r', G.wifiSlots, L.devs);
	shownNodes.forEach(function (n, i) { put(nk[n.mac], 'n' + i, G.nodeSlots[i].dev, L.devs); });
	var stood = {};
	L.wired.concat(L.devs).forEach(function (x) { stood[x.dev.id] = 1; });
	L.tray = visible.filter(function (dv) { return !stood[dv.id]; });
	A.slot = A.gotAny ? next : {};   /* before the first rates every device looks idle: pick again once they're known */
	return L;
}
function mapSignature(L) {
	return JSON.stringify([G.key, L.nodes.map(function (x) { return [x.node.mac, formOf(x.node.model, 'tower').form]; }), L.wired.concat(L.devs).map(function (x) { return [x.dev.id, x.group, x.slot.cx, x.dev.kind]; }), L.tray.length > 0]);
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
		'<path d="' + dl(sp, 2.5, 3.5) + '" style="fill:none;stroke:#000000;stroke-opacity:.22;stroke-width:' + px(13) + j + '"/>' +
		'<path d="' + dl(sp) + '" style="fill:none;stroke:#0e1417;stroke-width:' + px(14) + j + '"/>' +
		'<path d="' + dl(sp) + '" style="fill:none;stroke:#33424a;stroke-width:' + px(11.5) + j + '"/>' +
		'<path d="' + dl(sp) + '" style="fill:none;stroke:#141c20;stroke-width:' + px(8) + j + '"/>' +
		'<path d="' + dl(sp, 0, -4.4 * G.U / 24) + '" style="fill:none;stroke:rgba(255,255,255,.3);stroke-width:1' + j + '"/>' +
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
		'<ellipse cx="' + n1(p1[0]) + '" cy="' + n1(p1[1]) + '" rx="' + px(6.5) + '" ry="' + px(3.7) + '" style="fill:rgba(16,22,25,.55);stroke:rgba(255,255,255,.55);stroke-width:1"/>' +
		lane(qd(a[0], a[1], a[2]), DNT, DN, id + '|dn') + lane(qd(b[0], b[1], b[2]), UPT, UP, id + '|up') + '</g>' };
}

/* Build the whole map for one layout (only when devices get or lose a stand). */
function buildMap(net, L) {
	var objs = [objWan(), objRouter(net.router.model)], links = [], arcs = [], hubs = [], zones = [], marks = [];
	var HR = objs[1].hub || P(7.1, 7.1, 2.2);
	L.nodes.forEach(function (x, i) {
		var s = x.slot, o = objNode(x.node.id, s.cx, s.cy, x.node.model);
		objs.push(o);
		var z = s.zone, t = P(s.text[0], s.text[1]);
		zones.push('<g data-zone="' + x.node.id + '" class="ob">' + poly([P(z[0], z[1]), P(z[2], z[1]), P(z[2], z[3]), P(z[0], z[3])], 'fill:rgba(169,156,245,.09);stroke:rgba(169,156,245,.55);stroke-width:1;stroke-dasharray:5 5') +
			'<text transform="matrix(' + CC.toFixed(4) + ' 0.5 ' + (-CC).toFixed(4) + ' 0.5 ' + n1(t[0]) + ' ' + n1(t[1]) + ')" style="font-size:11px;font-weight:700;letter-spacing:.12em;fill:rgba(205,197,252,.9)">' + esc(('via ' + x.node.name).toUpperCase().slice(0, 22)) + '</text></g>');
		var a = arc(x.node.id, HR, o.hub, 0.2, true);
		arcs.push(a);
		hubs.push('<ellipse cx="' + n1(o.hub[0]) + '" cy="' + n1(o.hub[1]) + '" rx="' + px(8) + '" ry="' + px(4.6) + '" style="fill:rgba(16,22,25,.6);stroke:' + MESH + ';stroke-width:1.2"/>');
		hubs.push('<ellipse cx="' + n1(o.hub[0]) + '" cy="' + n1(o.hub[1]) + '" rx="' + px(8) + '" ry="' + px(4.6) + '" class="df-a df-ripple" style="fill:none;stroke:' + MESH + ';stroke-width:1.2;animation-delay:-1.3s"/>');
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
		var tr = objTray(G.tray.cx, G.tray.cy);
		objs.push(tr);
		arcs.push(arc('more', HR, tr.target, 0.2, false));
		var tc = P(G.tray.cx, G.tray.cy, 0.02);
		marks.push('<g data-mk="more:on" class="hide">' + ell(tc, 1.42, 'fill:none;stroke:' + ACC + ';stroke-width:1.4') + ell(tc, 1.42, 'fill:none;stroke:' + ACC + ';stroke-width:1.2', 'df-a df-ripple') + '</g>');
	}
	objs.sort(function (a, b) { return a.depth - b.depth; });
	hubs.push('<ellipse cx="' + n1(HR[0]) + '" cy="' + n1(HR[1]) + '" rx="' + px(9) + '" ry="' + px(5.2) + '" style="fill:rgba(16,22,25,.6);stroke:' + ACC + ';stroke-width:1.2"/>');
	hubs.push('<ellipse cx="' + n1(HR[0]) + '" cy="' + n1(HR[1]) + '" rx="' + px(9) + '" ry="' + px(5.2) + '" class="df-a df-ripple" style="fill:none;stroke:' + ACC + ';stroke-width:1.2"/>');

	/* the room: slab, two low walls, a grid and the fibre wall plate */
	var WT = 0.35, WH = 1.1, floor = [], x0 = G.x0, y0 = G.y0, X1 = G.x1, Y1 = G.y1, FW = X1 - x0;
	floor.push(poly([P(x0 - WT, Y1, 0), P(X1, Y1, 0), P(X1, Y1, -0.45), P(x0 - WT, Y1, -0.45)], 'fill:#28343a'));
	floor.push(poly([P(X1, y0 - WT, 0), P(X1, Y1, 0), P(X1, Y1, -0.45), P(X1, y0 - WT, -0.45)], 'fill:#1b2428'));
	floor.push(poly([P(x0 - WT, y0 - WT), P(X1, y0 - WT), P(X1, Y1), P(x0 - WT, Y1)], 'fill:url(#ar-floor)'));
	var g = [];
	for (var i = x0 + 1; i < X1; i++) { var a0 = P(i, y0), a1 = P(i, Y1); g.push('M' + n1(a0[0]) + ' ' + n1(a0[1]) + ' L' + n1(a1[0]) + ' ' + n1(a1[1])); }
	for (var k = y0 + 1; k < Y1; k++) { var b0 = P(x0, k), b1 = P(X1, k); g.push('M' + n1(b0[0]) + ' ' + n1(b0[1]) + ' L' + n1(b1[0]) + ' ' + n1(b1[1])); }
	floor.push('<path d="' + g.join(' ') + '" style="fill:none;stroke:rgba(255,255,255,.045);stroke-width:1"/>');
	floor.push(pline([P(x0 - WT, Y1), P(X1, Y1), P(X1, y0 - WT)], 'fill:none;stroke:rgba(255,255,255,.22);stroke-width:1'));
	var w = new Obj('wall', 0, 0, 0);
	w.box(x0 - WT, y0 - WT, 0, WT, Y1 - y0 + WT, WH, M_WALL);
	w.line('R', 0.03, 0.12, 1, 0.12, 'rgba(0,0,0,.35)', 1);
	w.box(x0, y0 - WT, 0, FW, WT, WH, M_WALL);
	w.line('L', 0, 0.12, 1, 0.12, 'rgba(0,0,0,.3)', 1);
	var bw = w.last;
	w.face('L', (1.42 - x0) / FW, 0.3, (1.93 - x0) / FW, 0.72, 'fill:#c9d1d4;stroke:#6b777c;stroke-width:.7', bw);
	var pp = w.fp('L', (1.675 - x0) / FW, 0.5, bw);
	w.svg.push('<circle cx="' + n1(pp[0]) + '" cy="' + n1(pp[1]) + '" r="' + px(1.7) + '" style="fill:' + DN + '"/>');
	floor = floor.concat(w.svg);
	floor.push(pline([P(1.675, y0, 0.42), P(1.675, y0, 0.06), P(1.675, 1.15, 0.06)], 'fill:none;stroke:#11181b;stroke-width:' + px(4.5) + ';stroke-linecap:round;stroke-linejoin:round'));
	floor.push(pline([P(1.675, y0, 0.42), P(1.675, y0, 0.06), P(1.675, 1.15, 0.06)], 'fill:none;stroke:#3f7fa6;stroke-width:' + px(1.8) + ';stroke-linecap:round;stroke-linejoin:round'));

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
		'<radialGradient id="ar-glow"><stop offset=".3" style="stop-color:#ffcc00;stop-opacity:.36"/><stop offset="1" style="stop-color:#ffcc00;stop-opacity:0"/></radialGradient>' +
		'<radialGradient id="ar-bulb" cx=".36" cy=".32" r=".8"><stop offset="0" style="stop-color:#fff6d0"/><stop offset=".5" style="stop-color:#ffcc00"/><stop offset="1" style="stop-color:#b38f00"/></radialGradient>' +
		'<linearGradient id="ar-cw" x1="0" y1="0" x2="1" y2="0"><stop offset=".5" style="stop-color:' + M_WHITE.l + '"/><stop offset=".5" style="stop-color:' + M_WHITE.r + '"/></linearGradient>' +
		'<linearGradient id="ar-cd" x1="0" y1="0" x2="1" y2="0"><stop offset=".5" style="stop-color:' + M_DARK.l + '"/><stop offset=".5" style="stop-color:' + M_DARK.r + '"/></linearGradient>' +
		'<filter id="ar-blur" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="2.4"/></filter></defs>';
	var svg = '<svg width="' + G.SW + '" height="' + G.SH + '" viewBox="0 0 ' + G.SW + ' ' + G.SH + '" role="img" aria-label="Isometric map of your network: traffic moving between the internet, the router, its AiMesh nodes and each device">' +
		defs + floor.join('') + zones.join('') + links.join('') + '<g style="opacity:.3" filter="url(#ar-blur)">' + sh.join('') + '</g>' +
		objs.map(function (o) { return '<g data-obj="' + o.id + '" class="ob">' + o.svg.join('') + '</g>'; }).join('') +
		arcs.map(function (a) { return a.svg; }).join('') + hubs.join('') + marks.join('') + leaders.join('') + '</svg>';
	var html = labels.map(function (lb) {
		return '<button type="button" class="ar-lb' + (lb.x3 ? ' x3' : '') + '" data-id="' + esc(lb.id) + '" style="left:' + lb.x + 'px;top:' + lb.y + 'px;width:' + lb.w + 'px;height:' + G.hit + 'px;justify-content:' + lb.just + '" aria-pressed="false">' +
			'<span><span class="n">' + esc(lb.name) + '</span><span class="v"></span>' + (lb.x3 ? '<span class="x">' + esc(lb.x3) + '</span>' : '') + '</span></button>';
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
	var HIT = G.hit, SW = G.SW, SH = G.SH, LBL = 1000, rects = [], out = [];   /* a label on another label: only when there is nowhere else at all */
	var zones = [[0, 0, 244, 78], [SW - 266, 0, SW, 62], [0, SH - 40, 440, SH]];
	var byId = {};
	objs.forEach(function (o) { byId[o.id] = o; });
	var items = [{ id: 'router', name: net.router.model || 'Router', o: byId.router }, { id: 'wan', name: 'Internet', o: byId.wan }];
	L.nodes.forEach(function (x) { items.push({ id: x.node.id, name: x.node.name, o: byId[x.node.id], x3: G.big ? thirdLine(x.node) : '' }); });
	L.wired.concat(L.devs).sort(function (a, b) { return busy(b.dev) - busy(a.dev); }).forEach(function (x) { items.push({ id: x.dev.id, name: x.dev.name, o: byId[x.dev.id], x3: G.big ? thirdLine(x.dev) : '' }); });
	if (L.tray.length) items.push({ id: 'more', name: '+' + L.tray.length + ' more', o: byId.more });
	var ov = function (a, b) { return !(a[2] <= b[0] || b[2] <= a[0] || a[3] <= b[1] || b[3] <= a[1]); };
	var arcPts = [];
	arcs.forEach(function (a) { arcPts = arcPts.concat(a.pts.slice(3, -3)); });
	items.forEach(function (it) {
		if (!it.o) return;
		var name = it.name.length > 24 ? it.name.slice(0, 23) + '…' : it.name;
		/* A node's second line can grow a " · weak" tag, so it gets room for that up front. */
		var w = Math.round(Math.max(textW(name, true), it.x3 ? textW(it.x3) * 0.96 + 8 : 0, it.id.indexOf('node:') === 0 ? 112 : 76) + 22), bb = it.o.bbox(), ax = it.o.anchor[0];
		var cands = [];
		(G.big ? [0, -34, 34, -68, 68, -102, 102, -136, 136] : [0, -34, 34, -68, 68]).forEach(function (dx) {
			cands.push({ x: ax - w / 2 + dx, y: bb[1] - 7 - HIT, px: ax + dx, py: bb[1] - 12, ay: bb[1] - 2, just: 'center' });
			cands.push({ x: ax - w / 2 + dx, y: bb[3] + 7, px: ax + dx, py: bb[3] + 12, ay: bb[3] + 2, just: 'center' });
		});
		cands.push({ x: bb[2] + 11, y: (bb[1] + bb[3]) / 2 - HIT / 2, px: bb[2] + 15, py: (bb[1] + bb[3]) / 2, ay: (bb[1] + bb[3]) / 2, axr: bb[2] + 1, just: 'flex-start' });
		cands.push({ x: bb[0] - 11 - w, y: (bb[1] + bb[3]) / 2 - HIT / 2, px: bb[0] - 15, py: (bb[1] + bb[3]) / 2, ay: (bb[1] + bb[3]) / 2, axr: bb[0] - 1, just: 'flex-end' });
		/* When all of those cover something, further out to either side, a little higher or lower: a longer line costs a
		   little for every pixel, covering another device's drawing a lot more. */
		var mid = (bb[1] + bb[3]) / 2, near = cands.length;
		[0, 40, 80, 130, 190, 260, 340, 440].forEach(function (sx) {   /* as far as the free space beside the floor */
			[0, -26, 26, -52, 52, -78, 78].forEach(function (dy) {
				if (!sx && !dy) return;
				var d = 20 + sx + Math.abs(dy);
				cands.push({ x: bb[2] + 11 + sx, y: mid - HIT / 2 + dy, px: bb[2] + 15 + sx, py: mid + dy, ay: mid, axr: bb[2] + 1, just: 'flex-start', d: d });
				cands.push({ x: bb[0] - 11 - w - sx, y: mid - HIT / 2 + dy, px: bb[0] - 15 - sx, py: mid + dy, ay: mid, axr: bb[0] - 1, just: 'flex-end', d: d });
			});
		});
		(G.big ? [0, -34, 34, -68, 68, -102, 102, -170, 170] : [0, -34, 34, -68, 68, -102, 102]).forEach(function (dx) {
			[24, 48, 80, 120, 170].forEach(function (dy) {
				var d = 20 + Math.abs(dx) + dy;
				cands.push({ x: ax - w / 2 + dx, y: bb[3] + 7 + dy, px: ax + dx, py: bb[3] + 12 + dy, ay: bb[3] + 2, just: 'center', d: d });
				cands.push({ x: ax - w / 2 + dx, y: bb[1] - 7 - HIT - dy, px: ax + dx, py: bb[1] - 12 - dy, ay: bb[1] - 2, just: 'center', d: d });
			});
		});
		var best = null, bestCost = 1e9, OBJ = G.big ? 150 : 90;   /* covering another device: worse than a long line, still better than hiding a label */
		cands.forEach(function (c, ci) {
			if (ci >= near && bestCost < 30) return;   /* a near spot that covers nothing much: no need to look further */
			var r = [c.x, c.y + 5, c.x + w, c.y + HIT - 5], cost = ci * 0.01 + (c.d || 0) * 0.12;
			if (r[0] < 4 || r[1] < 4 || r[2] > SW - 4 || r[3] > SH - 4) cost += 1000;
			rects.forEach(function (o) { if (ov(r, o)) cost += LBL; });
			objs.forEach(function (o) { if (o !== it.o && ov(r, o.bbox())) cost += OBJ; });
			zones.forEach(function (z) { if (ov(r, z)) cost += 60; });
			if (cost < bestCost) arcPts.forEach(function (p) { if (p[0] > r[0] - 2 && p[0] < r[2] + 2 && p[1] > r[1] && p[1] < r[3]) cost += 0.6; });
			if (cost < bestCost) { bestCost = cost; best = c; }
		});
		var x = Math.round(best.x), y = Math.round(best.y);
		rects.push([x, y + 5, x + w, y + HIT - 5]);
		out.push({ id: it.id, name: name, x3: it.x3 || '', x: x, y: y, w: w, just: best.just, px: best.px, py: best.py, ax: best.axr !== undefined ? best.axr : ax, ay: best.ay });
	});
	return out;
}

/* ---------------------------------------------------------------- selection: what lights up */
function chainOf(net, id) {
	if (!id || id === 'router') return null;
	if (id === 'wan') return ['wan'];
	if (id.indexOf('more') === 0) return ['more'];
	var n = net.byId[id];
	if (!n) return null;
	if (n.mac && id.indexOf('node:') === 0) return [id].concat(n.devs.map(function (dv) { return dv.id; }), n.devs.some(function (dv) { return inTray(dv.id); }) ? ['more'] : []);   /* its clients on the tray light the tray */
	var end = inTray(id) ? 'more' : id;   /* a device on the tray is traced to the tray */
	return n.node ? [n.node.id, end] : [end];
}
function isMore(id) { return !!id && id.indexOf('more') === 0; }
function inTray(id) { return !!(A.layout && A.layout.tray.some(function (dv) { return dv.id === id; })); }
/* The devices behind the "+N more" that is open: the map's tray, or one Flow group's "+N more" row.
   open: the list shows (the group itself or one of its devices is selected). */
function hiddenSet(net) {
	var sel = A.sel, devs = null, key = 'more', title = '';
	if (A.tab === 'map') {
		if (!A.layout || !A.layout.tray.length) return null;
		devs = A.layout.tray; title = 'On the tray';
	} else {
		var rows = [];
		(A.flowGs || []).forEach(function (g) { g.rows.forEach(function (r) { if (r.more) rows.push({ g: g, r: r }); }); });
		if (!rows.length) return null;
		var hit = rows.filter(function (x) { return x.r.id === sel || x.r.more.some(function (dv) { return dv.id === sel; }); })[0];
		if (hit) { devs = hit.r.more; key = hit.r.id; title = hit.g.label; }
		else { devs = []; rows.forEach(function (x) { devs = devs.concat(x.r.more); }); title = 'Grouped'; }
	}
	var has = devs.some(function (dv) { return dv.id === sel; });
	return { key: key, title: title, devs: devs, open: isMore(sel) || has, dev: has ? net.byId[sel] : null };
}
function selValid(net) {
	if (A.sel && !net.byId[A.sel] && !isMore(A.sel)) A.sel = null;
	if (isMore(A.sel) && !hiddenSet(net)) A.sel = null;
	return A.sel;
}
function pick(id) { A.sel = A.sel === id || id === 'router' ? null : id; render(); }
/* In the list: tapping the selected device again goes back to its group, so the list stays open. */
function pickHidden(id) { A.sel = A.sel === id ? (A.moreKey || 'more') : id; render(); }
function closeMore() {
	var back = A.tab === 'map' ? (A.mapRefs && A.mapRefs.labels.more) : (A.flowRefs && A.flowRefs.rows[A.moreKey]);
	A.sel = null; render();
	if (back && $('arMore').contains(document.activeElement)) back.focus();
}

/* ---------------------------------------------------------------- rendering */
function render() {
	var net = A.net;
	var root = $('ar');
	if (!root) return;
	root.className = [A.paused ? 'paused' : '', A.big ? 'big' : '', A.big && A.narrow ? 'narrow' : ''].join(' ').replace(/^ +| +$/g, '').replace(/ +/g, ' ');
	if (!net) { setNotice('Starting the sampler on the router…', MUTED); return; }
	try { renderSummary(net); } catch (e) { logErr(e); }
	if (A.tab === 'map') { try { renderMap(net); } catch (e) { logErr(e); } }
	else { try { renderFlow(net); } catch (e) { logErr(e); } }
	try { renderReadout(net); renderSide(net); renderFoot(net); } catch (e) { logErr(e); }
}
function logErr(e) { if (window.console) console.error('Arteria:', e); }
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
	s.innerHTML = '<span class="v" aria-label="Internet download ' + esc(full(net.wan.dn)) + '"><span class="dn" aria-hidden="true">↓</span> <b>' + esc(full(net.wan.dn)) + '</b></span>' +
		'<span class="v" aria-label="Internet upload ' + esc(full(net.wan.up)) + '"><span class="up" aria-hidden="true">↑</span> <b>' + esc(full(net.wan.up)) + '</b></span><span class="k n">' + net.clients + ' clients</span>';
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
	if (G.big && Math.min(net.nodes.length, 3) !== G.nodes) fit();   /* a node joined or left: its zone */
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
		Object.keys(refs.objs).forEach(function (id) { refs.objs[id].addEventListener('click', function () { pick(id); focusMore(); }); });   /* a drawing does what its label does */
		Array.prototype.forEach.call(root.querySelectorAll('.ar-lb'), function (el) {
			refs.labels[el.getAttribute('data-id')] = el;
			el.addEventListener('click', function () { pick(el.getAttribute('data-id')); focusMore(); });
			if (el.getAttribute('data-id') === 'more') el.setAttribute('aria-controls', 'arMore');
		});
		A.mapRefs = refs;
	}
	var R = A.mapRefs, sel = selValid(net), on = chainOf(net, sel);
	var lit = function (id) { return !on || on.indexOf(id) >= 0; };
	var trayDev = inTray(sel) ? net.byId[sel] : null, trayOn = isMore(sel) || !!trayDev;   /* a tray device is selected: the tray's arc carries its packets */
	var trayDn = 0, trayUp = 0, traySdn = 0, traySup = 0;
	L.tray.forEach(function (dv) { trayDn += dv.dn; trayUp += dv.up; traySdn += dv.sdn; traySup += dv.sup; });
	var rateOf = function (id) {
		if (id === 'wan') return net.wan;
		if (id === 'more') return { dn: trayDn, up: trayUp, sdn: traySdn, sup: traySup };
		var x = net.byId[id];
		if (!x) return zeroRate();
		return x.bh ? x.bh : x;
	};
	R.lanes.forEach(function (el) {
		var k = el.getAttribute('data-lane').split('|'), r = k[0] === 'more' && trayDev ? trayDev : rateOf(k[0]), x = net.byId[k[0]];
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
		var x3 = G.big && x && el.querySelector('.x');
		if (x3) { var t3 = thirdLine(x); if (x3.textContent !== t3) x3.textContent = t3; }
		var isOn = sel === id || (id === 'more' && trayOn);
		if (id === 'more') el.setAttribute('aria-expanded', trayOn ? 'true' : 'false');
		el.className = 'ar-lb' + (x3 ? ' x3' : '') + (isOn ? ' on' : '') + (id === 'router' || lit(id) ? '' : ' dim');
		el.setAttribute('aria-pressed', isOn ? 'true' : 'false');
	});
	if (R.marks['more:on']) R.marks['more:on'].setAttribute('class', trayOn ? '' : 'hide');
	var nt = noticeFor(net) || (trayOn ? ['The tray\'s devices are listed ' + (G.big && !A.narrow ? 'on the right' : 'below the map') + '. Pick one to trace it.', MUTED] : ['Tap a device or its label to trace its path. Tap it again to show everything.', MUTED]);
	setNotice(nt[0], nt[1]);
}

/* ---------------------------------------------------------------- the flow (Sankey) */
var FBW = { src: 10, rt: 12, link: 10, mesh: 10, dev: 8 }, FGAP = 3, FGGAP = 11, FSGAP = 34, FKCAP = 11.5;
/* The big view's flow: columns spread across the stage, a row for every device (up to 60), wider rows
   with more columns, and no height limit: the stage scrolls instead of the ribbons shrinking. */
function flowGeom(w, h) {
	var rowW = Math.min(420, Math.round(w * 0.34)), dev = w - rowW - 22, k = (dev - 16) / 500;
	return { x: { src: 96, rt: Math.round(96 + 110 * k), link: Math.round(96 + 218 * k), mesh: Math.round(96 + 354 * k), dev: dev }, rowLeft: dev + 14, rowW: rowW,
		rows: 60, rowMin: 34, target: Math.round(h * 0.45), top: 88, limit: null };
}
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
	if (!gs.length) gs.push({ id: 'r5', label: '5 GHz', kind: 'wifi', devs: [], node: null });   /* nothing connected: an empty band, so the frame still draws */
	/* row budget: every group gets one row; then the busiest devices overall, each costing a row
	   (and its group a "+N more" row while some of it is still hidden) */
	var shown = {}, budget = G.flow.rows;
	gs.forEach(function (g) { g.devs.sort(function (a, b) { return busy(b) - busy(a) || byName(a, b); }); shown[g.id] = []; });
	var rows = function () { return gs.reduce(function (a, g) { var n = shown[g.id].length; return a + Math.max(1, n + (n < g.devs.length ? 1 : 0)); }, 0); };
	/* a device with a row keeps it unless a hidden one is three times busier, so rows don't come and go with every sample */
	var prev = A.flowPick || {}, cands = [], pull = function (c) { return flowHeld('pick|' + c.dv.id, busy(c.dv)) * (prev[c.dv.id] ? 3 : 1); };   /* by recent peaks: a moment's dip doesn't cost a row */
	gs.forEach(function (g) { g.devs.forEach(function (dv) { cands.push({ g: g, dv: dv }); }); });
	cands.sort(function (a, b) { return pull(b) - pull(a) || byName(a.dv, b.dv); });
	cands.forEach(function (c) {
		shown[c.g.id].push(c.dv);
		if (rows() > budget) shown[c.g.id].pop();
	});
	A.flowPick = {}; gs.forEach(function (g) { shown[g.id].forEach(function (dv) { A.flowPick[dv.id] = 1; }); });
	gs.forEach(function (g) {
		var sh = shown[g.id].slice().sort(byName), hidden = g.devs.filter(function (dv) { return sh.indexOf(dv) < 0; });
		g.rows = sh.map(function (dv) { return { id: dv.id, dev: dv }; });
		if (hidden.length) g.rows.push({ id: 'more:' + g.id, more: hidden });
		if (!g.rows.length && g.node) g.rows.push({ id: g.node.id, nodeOnly: g.node });
	});
	return gs;
}
function flowSignature(gs) { return G.key + JSON.stringify(gs.map(function (g) { return [g.id, g.rows.map(function (r) { return r.id; })]; })); }
function buildFlow(gs) {
	var o = [], keys = [], FX0 = G.flow.x;
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
	o.push(lbl('rtb', '<text data-t="agg:rt" x="' + (FX0.rt + 6) + '" y="0" style="font-size:10.5px;fill:#c3c2b7;text-anchor:middle;font-variant-numeric:tabular-nums;paint-order:stroke;stroke:#2b3539;stroke-width:4px;stroke-linejoin:round"></text>'));
	gs.forEach(function (g) {
		var nm = g.node ? 'Backhaul' : g.label, pw = Math.round(textW(nm, true) + 70);
		o.push(lbl('g:' + g.id, '<rect x="' + (FX0.link - 4) + '" y="-12.5" width="' + pw + '" height="17" rx="4" style="fill:#2b3539;fill-opacity:.92"/>' +
			'<text x="' + (FX0.link + 2) + '" y="0" style="font-size:11px;font-weight:700;fill:' + (g.node ? '#cdc5fc' : '#f0efec') + '">' + esc(nm) + '<tspan data-t="gv:' + g.id + '" dx="6" style="font-weight:400;fill:#c3c2b7;font-variant-numeric:tabular-nums"></tspan></text>'));
		if (g.node) {
			var nn = g.label.length > 12 ? g.label.slice(0, 11) + '…' : g.label, tip = nn !== g.label ? '<title>' + esc(g.label) + '</title>' : '';
			o.push(lbl('n:' + g.id, '<rect x="' + (FX0.mesh - 4) + '" y="-12.5" width="' + Math.round(textW(nn, true) + 12) + '" height="17" rx="4" style="fill:#2b3539;fill-opacity:.92"/><text x="' + (FX0.mesh + 2) + '" y="0" style="font-size:11px;font-weight:700;fill:#cdc5fc">' + tip + esc(nn) + '</text>'));
		}
	});
	var hs = 'font-size:10px;font-weight:700;letter-spacing:.12em;fill:#93a9b1';
	var heads = '<text data-t="srchead" x="' + (FX0.src - 22) + '" y="68" style="' + hs + ';text-anchor:middle">SOURCE</text>' +
		[[FX0.rt + 6, 'ROUTER'], [FX0.link + 5, 'LINK']].map(function (h) { return '<text x="' + h[0] + '" y="68" style="' + hs + ';text-anchor:middle">' + h[1] + '</text>'; }).join('') +
		(gs.some(function (g) { return g.node; }) ? '<text x="' + (FX0.mesh + 5) + '" y="68" style="' + hs + ';text-anchor:middle">NODE</text>' : '') +
		'<text x="' + (G.flow.rowLeft + 8) + '" y="68" style="' + hs + '">DEVICE</text>';
	var svg = '<svg width="' + G.SW + '" height="' + G.SH + '" viewBox="0 0 ' + G.SW + ' ' + G.SH + '" role="img" aria-label="Flow diagram: traffic between the internet or the local network and each device, through the router and each link; ribbon width follows throughput">' +
		heads + '<g data-mode="1" class="m-dn">' + o.join('') + '</g></svg>';
	var rows = [];
	gs.forEach(function (g) { g.rows.forEach(function (r) {
		rows.push('<button type="button" class="ar-row" data-row="' + esc(r.id) + '" aria-pressed="false" style="top:0;height:' + G.flow.rowMin + 'px;left:' + G.flow.rowLeft + 'px;width:' + G.flow.rowW + 'px">' +
			'<span class="ic"></span><span class="tx"><span class="nm"></span><span class="sb"></span></span>' + (G.big ? '<span class="cx c1"></span><span class="cx c2"></span>' : '') +
			'<span class="vl"><span class="n"></span><span class="u"></span></span></button>');
	}); });
	return { svg: svg, rows: rows.join('') };
}
/* What a Flow row carries (key: 'sdn'/'sup' smoothed, 'dn'/'up' shown), what a group carries, and whether a
   group is a node that can't report per device (then its rows share one ribbon). */
function flowRowVal(r, key) {
	if (r.dev) return r.dev.st === 'ok' ? Math.max(r.dev[key], 0) : 0;
	if (r.more) return r.more.reduce(function (a, dv) { return a + (dv.st === 'ok' ? Math.max(dv[key], 0) : 0); }, 0);
	if (r.nodeOnly) return Math.max(r.nodeOnly.bh[key], 0);
	return 0;
}
function flowGroupVal(g, key) { return g.node ? Math.max(g.node.bh[key], 0) : g.rows.reduce(function (a, r) { return a + flowRowVal(r, key); }, 0); }
function flowAgg(g) { return !!(g.node && g.node.state !== 'ok'); }
/* Where everything goes in the Flow view, from the numbers alone (no DOM): the scale k (px per Mb/s),
   each row's slot, each group's band, the router block and the two sources. The scale is chosen on the
   smoothed rates so it doesn't jump; the ribbons use the shown ones. */
/* The most a row (or a group) needed lately, in steps that double (1, 2, 4…), so rows don't move with every sample:
   reaching a higher step counts at once; a row only shrinks back after half a minute of using well under its step. */
function flowHeld(id, v) {
	var M = A.flowMem || (A.flowMem = {}), m = M[id], now = Date.now(), q = v > 0 ? Math.pow(2, Math.ceil(Math.log(v) / Math.LN2 - 1e-9)) : 0;
	if (!m || q > m.v) M[id] = m = { v: q, t: now };
	else if (v >= m.v * 0.4) m.t = now;
	else if (now - m.t > 30000) M[id] = m = { v: q, t: now };
	return m.v;
}
function flowLayout(gs, net, mode) {
	var f = mode === 'up' ? 'up' : 'dn', bf = mode === 'up' ? 'sup' : 'sdn';
	var lay = function (k, key) {
		var y = G.flow.top, slot = {}, grp = {};
		gs.forEach(function (g, gi) {
			if (gi) y += FGGAP;
			var y0 = y, Hh = 0, n = g.rows.length, gv = flowGroupVal(g, key), gm = flowHeld(key + '|g:' + g.id, gv);
			var aggH = flowAgg(g) && gv > 0 ? Math.max(gv * k, 1.5) : 0, aggM = flowAgg(g) && gm > 0 ? Math.max(gm * k, 1.5) : 0;
			g.rows.forEach(function (r, ri) {
				if (ri) y += FGAP;
				var v = flowAgg(g) ? 0 : flowRowVal(r, key), h = v > 0 ? Math.max(v * k, 1.5) : 0;
				var vm = flowAgg(g) ? 0 : flowHeld(key + '|' + r.id, v), hm = vm > 0 ? Math.max(vm * k, 1.5) : 0;   /* room for its recent peak */
				var sl = Math.max(hm, G.flow.rowMin, aggM ? (aggM - FGAP * (n - 1)) / n : 0);
				slot[r.id] = { top: y, s: sl, h: h, bar: y + (sl - h) / 2 };
				y += sl; Hh += h;
			});
			if (aggH) Hh = aggH;
			/* a node's backhaul can carry more than its listed clients (the node itself, rounding) */
			if (g.node && !flowAgg(g) && gv * k > Hh) Hh = Math.min(gv * k, y - y0);
			grp[g.id] = { y0: y0, y1: y, H: Hh, top: (y0 + y) / 2 - Hh / 2 };
		});
		return { slot: slot, grp: grp, bottom: y };
	};
	var total = gs.reduce(function (a, g) { return a + flowGroupVal(g, bf); }, 0), LIM = G.flow.limit, KK = G.key + f;
	/* the scale the traffic asks for, made smaller as far as needed to fit; the last scale is kept while it still fits and
	   isn't far below that, so ribbons don't all resize at every sample */
	var k = Math.min(FKCAP, G.flow.target / Math.max(total, 1e-6)), k0 = A.flowK && A.flowK[KK], kT = k;
	for (var i = 0; LIM && i < 120 && lay(k, bf).bottom > LIM - 6; i++) k *= 0.97;
	if (k0 && k0 <= kT * 1.6 && k0 >= k * 0.6 && (!LIM || lay(k0, bf).bottom <= LIM - 6)) k = k0;
	var Lf = lay(k, f);
	for (var j = 0; LIM && j < 80 && Lf.bottom > LIM; j++) { k *= 0.97; Lf = lay(k, f); }
	(A.flowK || (A.flowK = {}))[KK] = k;
	var grp = Lf.grp, first = grp[gs[0].id], last = grp[gs[gs.length - 1].id];
	var Hr = gs.reduce(function (a, g) { return a + grp[g.id].H; }, 0);
	var rc = (first.top + last.top + last.H) / 2;
	if (!LIM) rc = Math.min(rc, Math.max(G.flow.top + Hr / 2 + FSGAP, G.SH / 2));   /* scrolling: the router stays on the first screen */
	var wv = Math.max(net.wan[f], 0), lv = Math.max(net.local[f], 0);
	var hi = wv + lv > 0 ? Hr * Math.min(wv / (wv + lv), 1) : Hr;
	var stop = rc - (Hr + FSGAP) / 2;
	return { k: k, slot: Lf.slot, grp: grp, bottom: Lf.bottom, Hr: Hr, rtop: rc - Hr / 2,
		src: { wan: { top: stop, h: hi }, loc: { top: stop + hi + FSGAP, h: Hr - hi } },
		height: LIM ? G.SH : Math.max(G.SH, Math.ceil(Lf.bottom + 12)) };   /* the big view: the stage grows and scrolls */
}
/* What a Flow row says: name, second line, icon, state, the big view's two columns. */
function flowRowInfo(g, r) {
	var x = { name: '', sub: '', icon: 'generic', st: 'ok', c1: '', c2: '' };
	if (r.dev) {
		var dv = r.dev; x.name = dv.name; x.icon = dv.kind; x.st = dv.st;
		x.sub = dv.st === 'off' ? 'Offline' : (dv.st === 'nodata' ? 'Not reported' : linkShort(dv));
		if (G.big) {   /* wider rows: where it's connected and its address, then signal and link rate in columns */
			var ip = ipOf(dv), wired = dv.link === 'wired';
			x.sub = (wired ? dv.portLabel : (dv.node ? dv.node.name : bandName(dv.band))) + (ip ? ' · ' + ip : '') + (dv.guest ? ' · guest' : '') + (dv.st === 'off' ? ' · offline' : '');
			x.c1 = wired ? (dv.speed ? speedTxt(dv.speed) : '') : dbm(dv.rssi, '');
			x.c2 = wired ? (dv.count > 1 ? dv.count + ' devices' : '') : (dv.phy ? dv.phy + ' Mb/s' : '');
		}
	} else if (r.more) { x.name = '+' + r.more.length + ' more'; x.icon = 'more'; x.sub = r.more.slice(0, 3).map(function (dv) { return dv.name; }).join(', '); }
	else { x.name = r.nodeOnly.name; x.icon = FORM_ICON[formOf(r.nodeOnly.model, 'tower').form] || 'mesh'; x.sub = 'No clients right now'; }
	if (g.node && flowAgg(g)) { x.st = g.node.online ? 'nodata' : 'off'; if (r.dev) x.sub = g.node.online ? 'Not reported' : 'Offline'; }
	return x;
}
/* The Flow view, every poll: the layout above, painted onto the scene (rebuilt only when the rows change). */
function renderFlow(net) {
	var gs = flowGroups(net), sig = flowSignature(gs);
	A.flowGs = gs;
	if (sig !== A.flowSig) {
		var b = buildFlow(gs);
		$('arFlowScene').innerHTML = b.svg;
		$('arFlowRows').innerHTML = b.rows;
		A.flowSig = sig;
		var root = $('arFlow'), refs = { f: {}, s: {}, br: {}, tx: {}, t: {}, hl: {}, rb: {}, rows: {} };
		[['data-f', 'f'], ['data-s', 's'], ['data-br', 'br'], ['data-tx', 'tx'], ['data-t', 't'], ['data-hl', 'hl'], ['data-rb', 'rb'], ['data-row', 'rows']].forEach(function (p) {
			Array.prototype.forEach.call(root.querySelectorAll('[' + p[0] + ']'), function (el) { refs[p[1]][el.getAttribute(p[0])] = el; });
		});
		Object.keys(refs.rows).forEach(function (id) { refs.rows[id].addEventListener('click', function () { pick(id); focusMore(); });
			if (id.indexOf('more:') === 0) refs.rows[id].setAttribute('aria-controls', 'arMore'); });
		refs.mode = root.querySelector('[data-mode]');
		refs.svg = $('arFlowScene').firstChild;
		A.flowRefs = refs;
	}
	var R = A.flowRefs, upm = A.mode === 'up', f = upm ? 'up' : 'dn', bf = upm ? 'sup' : 'sdn';
	R.mode.setAttribute('class', upm ? 'm-up' : 'm-dn');
	R.t.srchead.textContent = upm ? 'DESTINATION' : 'SOURCE';
	var sel = selValid(net), rowVal = flowRowVal, gVal = flowGroupVal, agg = flowAgg;
	var Lay = flowLayout(gs, net, A.mode), k = Lay.k, slot = Lay.slot, grp = Lay.grp, Hr = Lay.Hr, rtop = Lay.rtop, src = Lay.src;
	var Hs = String(Lay.height);
	if (R.svg.getAttribute('height') !== Hs) { R.svg.setAttribute('height', Hs); R.svg.setAttribute('viewBox', '0 0 ' + G.SW + ' ' + Hs); }
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
	var hs = hiddenSet(net), hdev = hs && hs.dev;
	var focus = !!selG, whole = focus && (selNode || agg(selG));
	var rowSel = function (r) { return sel && (r.id === sel || (r.more && r.more.some(function (dv) { return dv.id === sel; })) || (sel === 'more' && r.more)); };
	var X = G.flow.x, BW = FBW, ry = rtop;
	mk('src:wan', X.src + BW.src, src.wan.top, X.rt, ry, src.wan.h, net.wan[bf], focus ? 'rb mid' : 'rb');
	mk('src:loc', X.src + BW.src, src.loc.top, X.rt, ry + src.wan.h, src.loc.h, net.local[bf], focus ? 'rb mid' : 'rb');
	var hl = { a: 'M0 0', b: 'M0 0', on: false };
	gs.forEach(function (g) {
		var Gr = grp[g.id], litG = !focus || (whole && g === selG);
		mk('g:' + g.id, X.rt + BW.rt, ry, X.link, Gr.top, Gr.H, gVal(g, bf), litG ? 'rb' : 'rb dim');
		B('g:' + g.id, Gr.top, Gr.H);
		var x0 = X.link + BW.link;
		if (g.node) {
			mk('m:' + g.id, x0, Gr.top, X.mesh, Gr.top, Gr.H, gVal(g, bf), litG ? 'rb' : 'rb dim');
			B('n:' + g.id, Gr.top, Gr.H);
			x0 = X.mesh + BW.mesh;
			var brk = R.br['brk:' + g.id];
			if (brk) { if (agg(g)) { brk.setAttribute('y', n1(Gr.y0 + 5)); brk.setAttribute('height', n1(Math.max(Gr.y1 - Gr.y0 - 10, 1))); setC(brk, ''); } else setC(brk, 'hide'); }
		}
		var cy = Gr.top, off = 0;
		g.rows.forEach(function (r, ri) {
			var sl = slot[r.id], onR = !focus || rowSel(r) || (whole && g === selG);
			if (agg(g)) {
				if (ri === 0) { mk('d:' + r.id, x0, Gr.top, X.dev, Gr.top, Gr.H, gVal(g, bf), onR ? 'rb' : 'rb dim'); B('d:' + r.id, Gr.top, Gr.H); }
				else { mk('d:' + r.id, 0, 0, 0, 0, 0, 0, 'rb hide'); B('d:' + r.id, 0, 0); }
			} else {
				mk('d:' + r.id, x0, cy, X.dev, sl.bar, sl.h, rowVal(r, bf), onR ? 'rb' : 'rb dim');
				B('d:' + r.id, sl.bar, sl.h);
				if (focus && !whole && rowSel(r) && sl.h > 0) {
					/* one hidden device: highlight its share of the "+N more" ribbon, at the top of it */
					var hh = r.more && hdev ? Math.max(sl.h * Math.max(hdev[f], 0) / Math.max(rowVal(r, f), 1e-9), 1) : sl.h;
					hl.a = rib(X.rt + BW.rt, ry + off, ry + off + hh, X.link, cy, cy + hh);
					if (g.node) hl.b = rib(X.link + BW.link, cy, cy + hh, X.mesh, cy, cy + hh);
					hl.on = true;
				}
			}
			cy += sl.h; off += sl.h;
		});
		ry += Gr.H;
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
		var Gr = grp[g.id];
		T('g:' + g.id, Gr.H > 0 ? Gr.top - 7 : (Gr.y0 + Gr.y1) / 2 + 4);
		if (g.node) T('n:' + g.id, Gr.H > 0 ? Gr.top - 7 : (Gr.y0 + Gr.y1) / 2 + 4);
		if (R.t['gv:' + g.id]) R.t['gv:' + g.id].textContent = g.node && !g.node.online ? 'offline' : full(gVal(g, f));
	});
	/* the device rows */
	gs.forEach(function (g) { g.rows.forEach(function (r) {
		var el = R.rows[r.id], sl = slot[r.id];
		if (!el) return;
		el.style.top = n1(sl.top) + 'px'; el.style.height = n1(sl.s) + 'px';
		var x = flowRowInfo(g, r), name = x.name, sub = x.sub, icon = x.icon, st = x.st, c1 = x.c1, c2 = x.c2;
		var v = st === 'ok' ? rowVal(r, f) : null, fm = fmt(v);
		var isOn = rowSel(r);
		var key = [name, sub, icon, fm.n, fm.u, st, upm, c1, c2].join('|');
		if (r.more) el.setAttribute('aria-expanded', isOn ? 'true' : 'false');
		if (el._k !== key) {
			el._k = key;
			el.querySelector('.ic').innerHTML = iconSvg(icon, 16, INK2);
			el.querySelector('.nm').textContent = name;
			el.querySelector('.sb').textContent = sub;
			var nEl = el.querySelector('.vl .n');
			nEl.textContent = st === 'off' ? '—' : fm.n; nEl.style.color = st !== 'ok' ? INK2 : (upm ? UPT : DNT);
			el.querySelector('.vl .u').textContent = st === 'off' ? '' : fm.u;
			if (G.big) { el.querySelector('.c1').textContent = c1; el.querySelector('.c2').textContent = c2; }
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
/* The big view's third label line: how it's connected (band and signal, or port and speed). Link rates
   and addresses are in the readout and on Flow's rows; on the map they would make the labels too wide. */
function thirdLine(x) {
	if (!x.link) return !x.online ? 'Offline' : (x.wiredPort ? 'Wired backhaul' : bandName(x.bhBand) + ' backhaul') + (dbm(x.bhRssi, '') ? ' · ' + dbm(x.bhRssi) : '');
	return x.st === 'off' ? 'Offline' : linkShort(x);
}
function linkShort(dv) {
	if (dv.link === 'wired') return dv.portLabel + (dv.speed ? ' · ' + speedTxt(dv.speed) : '') + (dv.count > 1 ? ' · ' + dv.count + ' devices' : '');
	return (dv.node ? dv.node.name : bandName(dv.band)) + (dbm(dv.rssi, '') ? ' · ' + dbm(dv.rssi) : '') + (dv.guest ? ' · guest' : '');
}

/* ---------------------------------------------------------------- the readout card (both views) */
function readoutFor(net) {
	/* Whole network: everything your devices received and sent. That's the internet plus local traffic:
	   between your own devices, and to or from the router itself (its pages, DNS, a USB share). The bar
	   shows the internet part solid and the local part lighter. */
	var id = A.sel, d = { icon: FORM_ICON[formOf(net.router.model, 'router').form] || 'router', badge: 'Router', name: 'Whole network', link: (net.router.model || 'Router') + ' · all your devices, internet and local' };
	var dn = net.total.dn, up = net.total.up;
	var sdn = full(net.wan.dn) + ' internet + ' + full(net.local.dn) + ' local', sup = full(net.wan.up) + ' internet + ' + full(net.local.up) + ' local';
	var k1 = 'Clients', v1 = net.clients + ' online', k2 = 'Local traffic', v2 = full(net.local.dn), path = 'Through the router';
	var note = A.tab === 'map' ? 'Tap a device or its label on the map to trace its path.' : 'Tap a device row to trace it through the ribbons.', tone = INK2;
	var pct = function (a, b) { return a === null || !(b > 0) ? 0 : Math.max(0, Math.min(100, Math.round(100 * a / b))); };
	var rname = net.router.model || 'Router';
	if (id === 'wan') {
		d = { icon: 'globe', badge: 'WAN', name: 'Internet', link: 'WAN port · ' + (net.wanIf || '?') };
		dn = net.wan.dn; up = net.wan.up;
		sdn = pct(dn, net.total.dn) + '% of all download comes from the internet'; sup = pct(up, net.total.up) + '% of all upload goes to the internet';
		k1 = 'Interface'; v1 = net.wanIf || '—'; k2 = 'Link rate'; v2 = net.wanSpeed ? net.wanSpeed + ' Mb/s' : '—';
		path = 'Internet → ' + rname; note = 'Measured on the WAN interface counters.';
	} else if (isMore(id) && hiddenSet(net)) {
		var t = hiddenSet(net).devs, sd = 0, su = 0;
		t.forEach(function (dv) { sd += dv.dn; su += dv.up; });
		d = { icon: 'more', badge: 'Grouped', name: '+' + t.length + ' more', link: t.length + ' quieter devices, grouped' };
		dn = sd; up = su; sdn = pct(dn, net.total.dn) + '% of all download'; sup = pct(up, net.total.up) + '% of all upload';
		k1 = 'Busiest'; v1 = t.length ? t.slice().sort(function (a, b) { return busy(b) - busy(a); })[0].name : '—'; k2 = 'Devices'; v2 = String(t.length);
		path = rname + ' → ' + t.length + ' devices'; note = 'Listed on the right, busiest first. Pick one to trace it.';
	} else if (id && id.indexOf('node:') === 0 && net.byId[id]) {
		var n = net.byId[id];
		d = { icon: FORM_ICON[formOf(n.model, 'tower').form] || 'mesh', badge: 'AiMesh node', name: n.name, link: n.online ? (n.wiredPort ? 'Wired backhaul' : bandName(n.bhBand) + ' wireless backhaul') : 'Offline' };
		dn = n.online ? n.bh.dn : null; up = n.online ? n.bh.up : null;
		sdn = pct(dn, net.total.dn) + '% goes through the node'; sup = pct(up, net.total.up) + '% comes through the node';
		k1 = 'Backhaul signal'; v1 = dbm(n.bhRssi); k2 = 'Link rate'; v2 = n.bhPhy ? n.bhPhy + ' Mb/s' : '—';
		path = rname + ' → ' + n.name;
		note = { ok: 'Its devices are counted on the node and read over SSH.', nokey: 'Per-device data needs node access: run arteria.sh nodekey.', hostkey: 'Its SSH identity changed: run arteria.sh nodekey.',
			down: 'Not answering over SSH: showing its backhaul total.', wait: 'Connecting to the node…', off: 'Node access is off: backhaul total only.' }[n.state] || '';
		if (n.weak) { note = 'A weak backhaul caps everything behind the node.'; tone = ACC; }
		if (!n.online) { note = 'The node isn\'t connected to the router.'; tone = BAD; sdn = sup = 'offline'; }
	} else if (id && net.byId[id] && net.byId[id].link) {
		var dv = net.byId[id];
		d = { icon: dv.kind, badge: dv.link === 'wired' ? 'Wired' : 'Wi-Fi', name: dv.name,
			link: dv.link === 'wired' ? 'Wired · ' + dv.portLabel : bandName(dv.band) + ' · on ' + (dv.node ? dv.node.name : rname) + (dv.guest ? ' · guest network' : '') + (dv.alias ? ' · matched by host name' : '') };
		dn = dv.st === 'ok' ? dv.dn : null; up = dv.st === 'ok' ? dv.up : null;
		sdn = pct(dn, net.total.dn) + '% of all download'; sup = pct(up, net.total.up) + '% of all upload';
		if (dv.link === 'wired') { k1 = 'Port'; v1 = dv.portLabel; k2 = 'Link rate'; v2 = dv.speed ? dv.speed + ' Mb/s' : '—'; }
		else { k1 = 'Signal'; v1 = dbm(dv.rssi); k2 = 'Link rate'; v2 = dv.phy ? dv.phy + ' Mb/s' : '—'; }
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
	renderDetails(net, r);
}
/* The readout's Details face (section 6): who the selected device is and how it's connected. Every value is
   set as text, never parsed as HTML: names and host names come from the network. */
function renderDetails(net, r) {
	var dv = A.sel && net.byId[A.sel] && net.byId[A.sel].link && net.byId[A.sel].mac ? net.byId[A.sel] : null, box = $('arRoDetails');
	var both = G.big && !A.narrow, show = !!((A.det || both) && dv), btn = $('arRoDet');   /* the big view's tall readout shows both faces */
	$('arRoTraffic').className = show && !both ? 'hide' : ''; box.className = show ? 'ar-details' : 'ar-details hide';
	btn.className = dv && !both ? 'ar-det' + (A.det ? ' on' : '') : 'ar-det hide';
	btn.setAttribute('aria-pressed', A.det ? 'true' : 'false');
	if (!show) return;
	if (!both) $('arRoLink').textContent = r.d.link + ' · ↓ ' + short(dv.st === 'ok' ? dv.dn : null) + ' ↑ ' + short(dv.st === 'ok' ? dv.up : null);
	var cells = detailsFor(net, dv);
	while (box.children.length < cells.length) { var c = document.createElement('div'); c.className = 'ar-stat'; c.innerHTML = '<span class="k"></span><span class="v"></span>'; box.appendChild(c); }
	cells.forEach(function (x, i) { var c = box.children[i]; c.firstChild.textContent = x[0]; c.lastChild.textContent = x[1]; c.title = x[2] || (x[0] + ': ' + x[1]); });
}
/* The device report: how each device was recognised, for an issue about a device drawn as the wrong thing.
   It carries numbers and rule names only, never a name, host name, MAC or IP (the rule's "tok" names the
   source and the rule's position, not the text it matched). */
function buildReport(net) {
	var pad = function (v, n) { v = String(v); return v.length >= n ? v + ' ' : v + new Array(n - v.length + 1).join(' '); };
	var N = A.names || {}, rows = [];
	(net ? net.devs : []).forEach(function (dv) {
		if (!dv.mac) return;   /* a port with several devices behind it */
		var w = dv.why || {}, mac = dv.mac, c = N.custom && N.custom[mac], m = N.nmp && N.nmp[mac], l = N.lease && N.lease[mac];
		var has = [c && c.name ? 'nick' : '', dv.alias ? 'matched' : '', l && l.host ? 'host' : '', m && m.vendor ? 'maker' : '', m && m.vendorclass ? 'vc' : ''].filter(Boolean).join(',') || '-';
		rows.push(pad(dv.kind, 11) + pad((w.rule || '?') + (w.tok ? ': ' + w.tok : ''), 24) + pad((w.ct || 0) + '/' + (w.nt || 0), 8) + pad(w.os || 0, 4)
			+ pad(dv.link === 'wired' ? 'wired' : (dv.band || '?') + ' GHz', 9) + pad(isPrivate(mac) ? 'yes' : 'no', 8) + has);
	});
	rows.sort();
	return ['Arteria ' + VERSION + ' · ' + ((net && net.router.model) || 'router') + ' · ' + rows.length + ' devices',
		pad('kind', 11) + pad('rule', 24) + pad('icon', 8) + pad('os', 4) + pad('link', 9) + pad('private', 8) + 'has'].concat(rows,
		['', 'icon: the ASUS icon number saved in the client list / found by the router.', 'os: 1 Android, 2 Windows, 3 Linux, 4 ASUS, 5 Apple.',
		'has: which name sources exist (nickname, host name, maker, DHCP vendor class), never their text.']).join('\n');
}
/* Map: the busiest devices right now. Flow: the internet over the last two minutes. */
var TOP_BIG = 12;
function renderSide(net) {
	var rep = !!A.report, mapOn = A.tab === 'map', hs = hiddenSet(net), open = !rep && !!(hs && hs.open);
	$('arReport').className = rep ? 'ar-card ar-side ar-report' : 'ar-card ar-side ar-report hide';
	$('arReadout').className = rep ? 'ar-card ar-readout hide' : 'ar-card ar-readout';
	$('arTop').className = mapOn && !open && !rep ? 'ar-card ar-side' : 'ar-card ar-side hide';
	$('arHist').className = mapOn || open || rep ? 'ar-card ar-hist hide' : 'ar-card ar-hist';
	$('arMore').className = open ? 'ar-card ar-side' : 'ar-card ar-side hide';
	$('arRepBtn').setAttribute('aria-expanded', rep ? 'true' : 'false');
	if (rep) { var tx = $('arRepTx'), t = buildReport(net); if (tx.value !== t && document.activeElement !== tx) { tx.value = t; tx.setSelectionRange(0, 0); tx.scrollTop = tx.scrollLeft = 0; } }
	else if (open) renderMore(hs);
	else if (mapOn) {
		var nTop = G.big ? TOP_BIG : 4;
		var top = net.devs.filter(function (dv) { return dv.st === 'ok'; }).sort(function (a, b) { return busy(b) - busy(a); }).slice(0, nTop);
		var mx = top.length ? Math.max(busy(top[0]), 1e-6) : 1;
		for (var i = 0; i < TOP_BIG; i++) {
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
/* The list behind a "+N more": the same rows as "Busiest right now", busiest first. The order is held
   for 10 s so rows don't move under a finger; rows are reused, so the scroll position and focus stay. */
function renderMore(hs) {
	var box = $('arMoreList'), ord = A.moreOrd;
	A.moreKey = hs.key;
	$('arMoreTitle').textContent = hs.title + ' · ' + hs.devs.length + ' devices';
	var byId = {};
	hs.devs.forEach(function (dv) { byId[dv.id] = dv; });
	if (!ord || ord.key !== hs.key || Date.now() - ord.at > 10000) {
		ord = A.moreOrd = { key: hs.key, at: Date.now(), ids: hs.devs.slice().sort(function (a, b) { return busy(b) - busy(a) || byName(a, b); }).map(function (dv) { return dv.id; }) };
	} else {
		ord.ids = ord.ids.filter(function (id) { return byId[id]; });
		hs.devs.forEach(function (dv) { if (ord.ids.indexOf(dv.id) < 0) ord.ids.push(dv.id); });
	}
	var have = {};
	Array.prototype.forEach.call(box.children, function (el) { have[el.getAttribute('data-id')] = el; });
	var mx = Math.max.apply(null, hs.devs.map(busy).concat([1e-6]));
	ord.ids.forEach(function (id, i) {
		var dv = byId[id], el = have[id];
		if (!el) {
			el = document.createElement('button');
			el.type = 'button'; el.setAttribute('data-id', id);
			el.innerHTML = A.rowHtml;
		}
		delete have[id];
		if (box.children[i] !== el) box.insertBefore(el, box.children[i] || null);
		if (el._icon !== dv.kind) { el.querySelector('.ic').innerHTML = iconSvg(dv.kind, 18, INK2); el._icon = dv.kind; }
		el.querySelector('.nm').textContent = dv.name;
		el.querySelector('.bar > span').style.width = Math.max(3, Math.round(100 * busy(dv) / mx)) + '%';
		el.querySelector('.rd').textContent = dv.st === 'ok' ? '↓ ' + short(dv.dn) : '—';
		el.querySelector('.ru').textContent = dv.st === 'ok' ? '↑ ' + short(dv.up) : '';
		el.className = A.sel === id ? 'on' : '';
		el.setAttribute('aria-pressed', A.sel === id ? 'true' : 'false');
	});
	Object.keys(have).forEach(function (id) { box.removeChild(have[id]); });
}
/* After opening a "+N more" from the keyboard, move to its list. */
function focusMore() {
	var b = $('arMoreList').firstChild;
	if (isMore(A.sel) && b && A.kbd) b.focus();
}
function renderSpark() {
	var Wd = 244, H = 116, base = H - 20, h = A.hist;
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
	if (isMore(A.sel)) A.sel = null;   /* the two views group differently */
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
/* ---------------------------------------------------------------- the expanded view
   Same DOM, same state, same render(): only the geometry changes. #ar moves to <body> while expanded so
   no ancestor of the router's page can clip it; a comment marks its place to go back to. */
function fsEl() { return document.fullscreenElement || document.webkitFullscreenElement || null; }
function fsCan() { var r = $('ar'); return !!(r && (r.requestFullscreen || r.webkitRequestFullscreen)); }
function toggleFull() {
	var r = $('ar');
	try {
		if (fsEl()) { var x = document.exitFullscreen || document.webkitExitFullscreen; if (x) x.call(document); }
		else { var q = r.requestFullscreen || r.webkitRequestFullscreen; var p = q && q.call(r); if (p && p.catch) p.catch(function () {}); }
	} catch (e) { logErr(e); }
}
/* Size the stage: the page's 728 × 518, or what the window leaves when expanded. */
function fit() {
	var root = $('ar'), g;
	if (A.big) {
		A.narrow = window.innerWidth < 1180;
		var w = Math.max(728, Math.floor(window.innerWidth - 32 - (A.narrow ? 0 : 384)));
		var h = Math.max(518, Math.floor(window.innerHeight - 110 - (A.narrow ? 236 : 0)));
		g = geomBig(w, h, A.net ? A.net.nodes.length : 0);
	} else { A.narrow = false; g = geomSmall(); }
	if (G.key !== g.key) {   /* stands are remembered per view, so closing puts every device back where it was */
		A.slotBy[G.big ? 'b' : 's'] = { slot: A.slot, at: A.slotAt };
		var m = A.slotBy[g.big ? 'b' : 's'];
		A.slot = m ? m.slot : {}; A.slotAt = m ? m.at : 0;
		G = g;
	}
	var st = root.querySelector('.ar-stage');
	st.style.width = g.big ? g.SW + 'px' : ''; st.style.height = g.big ? g.SH + 'px' : '';
	['arMap', 'arFlow'].forEach(function (id) { $(id).style.width = g.big ? g.SW - 2 + 'px' : ''; $(id).style.height = g.big ? g.SH - 2 + 'px' : ''; });
}
function setBig(on) {
	var root = $('ar'), b = $('arBig');
	on = !!on;
	if (on === A.big) return;
	A.big = on;
	if (on) {
		A.holder = A.holder || document.createComment('arteria');
		root.parentNode.insertBefore(A.holder, root);
		document.body.appendChild(root);
		root.setAttribute('role', 'dialog'); root.setAttribute('aria-modal', 'true'); root.setAttribute('aria-label', 'Arteria, expanded view');
		A.docOverflow = document.documentElement.style.overflow;
		document.documentElement.style.overflow = 'hidden';
	} else {
		if (fsEl()) toggleFull();
		if (A.holder && A.holder.parentNode) A.holder.parentNode.insertBefore(root, A.holder);
		['role', 'aria-modal', 'aria-label'].forEach(function (k) { root.removeAttribute(k); });
		document.documentElement.style.overflow = A.docOverflow || '';
	}
	b.innerHTML = iconSvg(on ? 'collapse' : 'expand', 20, '#f0efec');
	b.setAttribute('aria-pressed', on ? 'true' : 'false');
	b.setAttribute('aria-label', on ? 'Close the expanded view' : 'Expand');
	b.title = on ? 'Back to the page (Esc)' : 'Expand: a bigger view with more detail';
	$('arFull').className = on && fsCan() ? 'ar-ibtn' : 'ar-ibtn hide';
	fit(); render();
	b.focus();
}
/* While expanded, Tab stays inside and Escape closes it (the "+N more" list and the report close first). */
function bigKeys(e) {
	if (!A.big) return;
	if (e.key === 'Escape' || e.key === 'Esc') {
		if (fsEl()) return;   /* the browser leaves full screen itself */
		e.preventDefault();
		if (A.report) { A.report = false; render(); $('arRepBtn').focus(); }
		else if (A.net && hiddenSet(A.net) && hiddenSet(A.net).open) closeMore();
		else setBig(false);
		return;
	}
	if (e.key !== 'Tab') return;
	var f = Array.prototype.filter.call($('ar').querySelectorAll('button, a[href], textarea'), function (el) { return el.offsetParent !== null && !el.disabled; });
	if (!f.length) return;
	var i = f.indexOf(document.activeElement);
	if (e.shiftKey ? i <= 0 : (i < 0 || i === f.length - 1)) { e.preventDefault(); f[e.shiftKey ? f.length - 1 : 0].focus(); }
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
	A.det = store('det') === '1';
	$('arRoDet').addEventListener('click', function () { A.det = !A.det; store('det', A.det ? '1' : '0'); render(); });
	$('arUnitMb').addEventListener('click', function () { setUnit('Mb'); });
	$('arUnitMB').addEventListener('click', function () { setUnit('MB'); });
	setUnit(store('unit'));
	$('arTabMap').addEventListener('click', function () { setTab('map'); });
	$('arTabFlow').addEventListener('click', function () { setTab('flow'); });
	$('arLive').addEventListener('click', togglePause);
	/* a name, a maker or a path cut short with "…" shows in full on hover: only the text itself (a few inline parts at most),
	   never a container, and never the map's labels (tap one for its details) */
	$('ar').addEventListener('mouseover', function (e) {
		if (!e.target.closest || e.target.closest('#arMapLabels, svg')) return;
		for (var el = e.target, i = 0; el && el.nodeType === 1 && el.id !== 'ar' && i < 2 && el.querySelectorAll('*').length <= 3; el = el.parentNode, i++) {
			if (el.clientWidth && el.scrollWidth > el.clientWidth + 1) { if (!el.title || el._tip) { el.title = el.textContent.trim(); el._tip = true; } return; }
			if (el._tip) { el.removeAttribute('title'); el._tip = false; }
		}
	});
	$('arDn').addEventListener('click', function () { setMode('dn'); });
	$('arUp').addEventListener('click', function () { setMode('up'); });
	A.rowHtml = $('arTop0').innerHTML;   /* the one row markup, for the busiest list and the "+N more" list */
	for (var t = 1; t < TOP_BIG; t++) { var c = $('arTop0').cloneNode(true); c.id = 'arTop' + t; c.className = 'hide'; $('arTopEmpty').parentNode.insertBefore(c, $('arTopEmpty')); }
	for (var i = 0; i < TOP_BIG; i++) (function (btn) { btn.addEventListener('click', function () { if (btn._id) pick(btn._id); }); })($('arTop' + i));
	$('arBig').innerHTML = iconSvg('expand', 20, '#f0efec');
	$('arFull').innerHTML = iconSvg('full', 20, '#f0efec');
	$('arBig').addEventListener('click', function () { setBig(!A.big); });
	$('arFull').addEventListener('click', toggleFull);
	document.addEventListener('keydown', bigKeys);
	var refit = function () { if (!A.big) return; clearTimeout(A.timers.fit); A.timers.fit = setTimeout(function () { fit(); render(); }, 200); };
	window.addEventListener('resize', refit);
	document.addEventListener('fullscreenchange', refit);
	document.addEventListener('webkitfullscreenchange', refit);
	$('arMoreList').addEventListener('click', function (e) {
		var b = e.target.closest ? e.target.closest('button[data-id]') : null;
		if (b) pickHidden(b.getAttribute('data-id'));
	});
	$('arMoreClose').addEventListener('click', closeMore);
	$('arMore').addEventListener('keydown', function (e) { if (e.key === 'Escape') { e.stopPropagation(); closeMore(); } });
	var closeReport = function () { A.report = false; render(); $('arRepBtn').focus(); };
	$('arRepBtn').addEventListener('click', function () { A.report = !A.report; render(); if (A.report) $('arRepTx').focus(); });
	$('arRepClose').addEventListener('click', closeReport);
	$('arReport').addEventListener('keydown', function (e) { if (e.key === 'Escape') { e.stopPropagation(); closeReport(); } });
	document.addEventListener('keydown', function () { A.kbd = true; }, true);
	document.addEventListener('pointerdown', function () { A.kbd = false; }, true);
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
window.Arteria = { _t: { objDevice: objDevice, objNode: objNode, objRouter: objRouter, iconSvg: iconSvg, ICON: ICON, classify: classify, P: P, poly: poly, formOf: formOf, hubBody: hubBody, Obj: Obj, buildAliases: buildAliases, isPrivate: isPrivate, detailsFor: detailsFor, nameInfo: nameInfo, KIND_LABEL: KIND_LABEL, TYPE_KIND: TYPE_KIND, KIND_STRONG: KIND_STRONG, KIND_WEAK: KIND_WEAK, buildReport: buildReport, geomSmall: geomSmall, geomBig: geomBig, G: function () { return G; }, useGeom: function (g) { G = g; }, mapLayout: mapLayout, buildMap: buildMap, flowGroups: flowGroups, buildFlow: buildFlow, flowLayout: flowLayout }, state: A, setBig: setBig, render: render, onSample: onSample, report: function () { return buildReport(A.net); }, buildNet: buildNet, parseNames: parseNames, pick: pick, setTab: setTab, setMode: setMode };
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

<div id="ar">
	<div class="ar-bar">
		<nav class="ar-tabs" aria-label="Arteria views">
			<button type="button" id="arTabMap" class="on" aria-selected="true">Map</button>
			<button type="button" id="arTabFlow" aria-selected="false">Flow</button>
		</nav>
		<div class="ar-sum" id="arSum"></div>
		<div class="ar-unit" role="group" aria-label="Show rates in"><button type="button" id="arUnitMb" class="on" aria-pressed="true" title="Megabits per second, the unit internet plans and speed tests use">Mb/s</button><button type="button" id="arUnitMB" aria-pressed="false" title="Megabytes per second, the unit file downloads show (8 times smaller)">MB/s</button></div>
		<button type="button" class="ar-live warn" id="arLive" aria-pressed="false" title="Pause or resume. While paused, the router stops sampling."><span class="dot"></span><span id="arLiveTxt">Connecting…</span></button>
		<button type="button" class="ar-ibtn hide" id="arFull" aria-label="Full screen" title="Full screen"></button>
		<button type="button" class="ar-ibtn" id="arBig" aria-pressed="false" aria-label="Expand" title="Expand: a bigger view with more detail"></button>
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
			<div class="ar-fscroll" id="arFlowScroll"><div id="arFlowScene"></div><div id="arFlowRows"></div></div>
			<div class="ar-flowbar">
				<div class="ar-seg" role="group" aria-label="Direction">
					<button type="button" id="arDn" class="on-dn" aria-pressed="true">↓ Download</button>
					<button type="button" id="arUp" aria-pressed="false">↑ Upload</button>
				</div>
				<div class="ar-notice" id="arNoticeFlow" style="flex:1 1 0;min-width:0"><span class="sw"></span><span class="tx"></span></div>
				<div class="ar-scale"><span class="sw" id="arScaleSw"></span><span id="arScaleTx"></span></div>
			</div>
		</div>
	</div>

	<div class="ar-cards">
		<div class="ar-card ar-readout" id="arReadout">
			<div class="ar-ro-head"><div class="eyebrow">Live readout</div><div class="ar-ro-tools"><button type="button" class="ar-det hide" id="arRoDet" aria-pressed="false" aria-controls="arRoDetails" title="Show the device's address, maker, system and connection">Details</button><div class="ar-badge" id="arRoBadge"></div></div></div>
			<div class="ar-ro-id"><div class="ar-ico" id="arRoIcon"></div><div style="min-width:0"><div class="ar-ro-name" id="arRoName">Whole network</div><div class="ar-ro-link" id="arRoLink"></div></div></div>
			<div id="arRoTraffic">
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
			<div class="ar-details hide" id="arRoDetails" role="group" aria-label="Device details"></div>
		</div>
		<div class="ar-card ar-side" id="arTop">
			<div class="eyebrow" style="padding:0 8px">Busiest right now</div>
			<div class="ar-top">
				<button type="button" id="arTop0" class="hide" aria-pressed="false"><span class="ic"></span><span style="flex:1 1 0;min-width:0"><span class="nm"></span><span class="bar"><span></span></span></span><span class="rt"><span class="rd c-dn"></span><span class="ru c-up"></span></span></button>
				<div id="arTopEmpty" class="ar-empty">Nothing is moving yet.</div>
			</div>
		</div>
		<div class="ar-card ar-side hide" id="arMore" role="region" aria-labelledby="arMoreTitle">
			<div class="ar-more-head"><div class="eyebrow" id="arMoreTitle"></div><button type="button" class="ar-x" id="arMoreClose" aria-label="Close this list" title="Close (Esc)">×</button></div>
			<div class="ar-top ar-more-list" id="arMoreList"></div>
		</div>
		<div class="ar-card ar-side ar-report hide" id="arReport" role="region" aria-labelledby="arRepTitle">
			<div class="ar-more-head"><div class="eyebrow" id="arRepTitle">Device report · how each device was recognised · no names, MACs or IPs</div><button type="button" class="ar-x" id="arRepClose" aria-label="Close the report" title="Close (Esc)">×</button></div>
			<textarea id="arRepTx" readonly spellcheck="false" aria-label="How each device was recognised, for an issue report" title="Paste it into a GitHub issue if a device is drawn as the wrong thing."></textarea>
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
	<div class="ar-foot"><span id="arFootTx">Arteria</span><span class="ar-foot-r"><button type="button" class="ar-link" id="arRepBtn" aria-controls="arReport" aria-expanded="false">Device report</button><a href="https://github.com/IfSugar/arteria" target="_blank" rel="noopener noreferrer">GitHub</a></span></div>
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
