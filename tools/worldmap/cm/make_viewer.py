"""Yerelde açılan yakınlaştırılabilir harita görüntüleyicisi (OpenSeadragon) üretir.

usage: python3 make_viewer.py <map.png> <harita.geojson> <isaret_dir> <out_dir>
out_dir/index.html dosyası tarayıcıda doğrudan açılır (file://). Karolar out_dir/t/<seviye>/<x>_<y>.jpg.
"""
import json
import math
import os
import shutil
import sys

from PIL import Image

Image.MAX_IMAGE_PIXELS = None
src, geo_p, mark_dir, out = sys.argv[1:5]
TILE = 1024
im = Image.open(src).convert("RGB")
W, H = im.size
MAXL = 4                                   # seviye 4 = tam çözünürlük, her alt seviye yarısı
os.makedirs(out, exist_ok=True)
cur = im
for L in range(MAXL, -1, -1):
    w, h = cur.size
    d = os.path.join(out, "t", str(L))
    os.makedirs(d, exist_ok=True)
    for ty in range(math.ceil(h / TILE)):
        for tx in range(math.ceil(w / TILE)):
            cur.crop((tx * TILE, ty * TILE, min(w, (tx + 1) * TILE), min(h, (ty + 1) * TILE))).save(
                os.path.join(d, "%d_%d.jpg" % (tx, ty)), quality=82, optimize=True, progressive=True)
    print("seviye", L, w, h, flush=True)
    if L:
        cur = cur.resize((math.ceil(w / 2), math.ceil(h / 2)), Image.LANCZOS)

geo = json.load(open(geo_p, encoding="utf-8"))
places = []
for f in geo["features"]:
    p = f["properties"]
    if p["layer"] in ("yerleşim", "kervansaray") and f["geometry"]["type"] == "Point":
        x, y = f["geometry"]["coordinates"]
        places.append({"id": p["id"], "tr": p.get("name_tr"), "en": p.get("name_en"), "c": p.get("class"), "x": x, "y": y})
with open(os.path.join(out, "places.js"), "w", encoding="utf-8") as fh:
    fh.write("window.MAP = " + json.dumps({"w": W, "h": H, "tile": TILE, "maxLevel": MAXL}) + ";\n")
    fh.write("window.PLACES = " + json.dumps(places, ensure_ascii=False) + ";\n")
for d_ in ("K", "KD", "D", "GD", "G", "GB", "B", "KB"):
    shutil.copy(os.path.join(mark_dir, "atli_%s_96.png" % d_), os.path.join(out, "atli_%s.png" % d_))

HTML = r"""<!doctype html>
<html lang="tr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Wayborne Haritası</title>
<style>
  :root { --ground:#1b1612; --chip:rgba(27,22,18,.86); --line:rgba(214,196,158,.35); --text:#eadfc6; --accent:#c9a96a; }
  html,body { height:100%; margin:0; background:var(--ground); color:var(--text); font:14px/1.4 Georgia,"Times New Roman",serif; overflow:hidden; }
  #map { position:fixed !important; left:0; top:0; width:100vw; height:100vh; height:100dvh; }
  .panel { position:fixed; z-index:5; left:12px; top:calc(12px + env(safe-area-inset-top,0px)); display:flex; flex-direction:column; gap:6px; max-width:min(320px, calc(100vw - 24px)); }
  .chip { background:var(--chip); border:1px solid var(--line); border-radius:14px; padding:6px 12px; }
  #q { width:100%; box-sizing:border-box; background:var(--chip); color:var(--text); border:1px solid var(--line); border-radius:14px; padding:8px 12px; font:inherit; }
  #hits { list-style:none; margin:0; padding:0; max-height:40vh; overflow:auto; }
  #hits li { padding:6px 12px; cursor:pointer; border-top:1px solid var(--line); background:var(--chip); }
  #hits li:hover, #hits li:focus { background:#3a2e22; outline:none; }
  .bar { position:fixed; z-index:5; display:flex; gap:8px; right:max(12px, env(safe-area-inset-right,0px)); bottom:calc(12px + env(safe-area-inset-bottom,0px)); }
  .bar button { min-width:46px; height:46px; border-radius:23px; border:1px solid var(--line); background:var(--chip); color:var(--text); font:18px/1 Georgia,serif; cursor:pointer; padding:0 14px; }
  .bar button[aria-pressed="true"] { border-color:var(--accent); color:var(--accent); }
  .bar button:focus-visible, #q:focus-visible { outline:2px solid var(--accent); outline-offset:2px; }
  #me { width:72px; height:72px; pointer-events:none; filter:drop-shadow(0 1px 2px rgba(0,0,0,.4)); }
  #err { position:fixed; inset:0; display:grid; place-items:center; padding:24px; text-align:center; }
</style></head><body>
<div id="map"></div>
<div class="panel">
  <input id="q" type="search" placeholder="Yer ara (ör. Vastrevar)" aria-label="Yer ara" autocomplete="off">
  <ul id="hits" role="listbox"></ul>
  <div class="chip" id="where" aria-live="polite">Kervan: —</div>
</div>
<div class="bar">
  <button id="move" aria-pressed="false" title="Haritaya dokunarak kervanı taşı">Taşı</button>
  <button id="follow" title="Kervana git">Kervan</button>
  <button id="zin" aria-label="Yaklaştır">+</button>
  <button id="zout" aria-label="Uzaklaştır">−</button>
  <button id="home" aria-label="Tüm harita">⌂</button>
</div>
<img id="me" src="atli_G.png" alt="Kervanın konumu">
<script src="places.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/openseadragon/4.1.0/openseadragon.min.js"></script>
<script>
// Kare döngüsü çalışmıyorsa (gömülü/arka plan görünüm) zamanlayıcıya geç, sonra görüntüleyiciyi kur.
(function () {
  var ok = false;
  try { requestAnimationFrame(function () { ok = true; }); } catch (e) {}
  setTimeout(function () {
    if (!ok) {
      window.requestAnimationFrame = function (cb) { return setTimeout(function () { cb(performance.now()); }, 16); };
      window.cancelAnimationFrame = function (id) { clearTimeout(id); };
      if (window.OpenSeadragon) { OpenSeadragon.requestAnimationFrame = window.requestAnimationFrame; OpenSeadragon.cancelAnimationFrame = window.cancelAnimationFrame; }
    }
    start();
  }, 250);
})();
function start() {
  var M = window.MAP, P = window.PLACES || [];
  if (!window.OpenSeadragon) { document.getElementById('map').innerHTML = '<div id="err">Görüntüleyici kütüphanesi yüklenemedi (internet bağlantısı gerekir).</div>'; return; }
  var viewer = OpenSeadragon({
    element: document.getElementById('map'), showNavigationControl: false,
    gestureSettingsTouch: { pinchRotate: false, flickEnabled: true }, gestureSettingsMouse: { clickToZoom: false },
    maxZoomPixelRatio: 3, visibilityRatio: 0.5, smoothTileEdgesMinZoom: Infinity,
    tileSources: { width: M.w, height: M.h, tileSize: M.tile, tileOverlap: 0, minLevel: 0, maxLevel: M.maxLevel,
      getLevelScale: function (l) { return Math.pow(2, l - M.maxLevel); },
      getNumTiles: function (l) { var s = Math.pow(2, l - M.maxLevel); return new OpenSeadragon.Point(Math.ceil(Math.ceil(M.w * s) / M.tile), Math.ceil(Math.ceil(M.h * s) / M.tile)); },
      getTileUrl: function (l, x, y) { return 't/' + l + '/' + x + '_' + y + '.jpg'; } }
  });
  window.viewer = viewer;
  // kervan konumu: ?x=..&y=.. (görüntü pikseli) > son kaydedilen > ilk kent
  var q = new URLSearchParams(location.search), pos = null;
  if (q.get('x') && q.get('y')) pos = { x: +q.get('x'), y: +q.get('y') };
  if (!pos) { try { pos = JSON.parse(localStorage.getItem('wayborne_kervan') || 'null'); } catch (e) {} }
  if (!pos) { var v = P.find(function (p) { return p.en === 'Vastrevar'; }) || P[0]; pos = { x: v.x, y: v.y }; }
  var me = document.getElementById('me');
  function nearest(x, y) { var b = null, bd = 1e18; P.forEach(function (p) { var d = (p.x - x) * (p.x - x) + (p.y - y) * (p.y - y); if (d < bd) { bd = d; b = p; } }); return { p: b, d: Math.sqrt(bd) }; }
  var DIRS = ['D', 'GD', 'G', 'GB', 'B', 'KB', 'K', 'KD'];   // 0° = sağa (doğu), saat yönünde
  function face(dx, dy) {
    if (Math.abs(dx) + Math.abs(dy) < 4) return;
    var a = Math.atan2(dy, dx) * 180 / Math.PI; if (a < 0) a += 360;
    me.src = 'atli_' + DIRS[Math.round(a / 45) % 8] + '.png';
  }
  function place(x, y) {
    if (pos) face(x - pos.x, y - pos.y);
    pos = { x: Math.round(x), y: Math.round(y) };
    try { localStorage.setItem('wayborne_kervan', JSON.stringify(pos)); } catch (e) {}
    var vp = viewer.viewport.imageToViewportCoordinates(pos.x, pos.y);
    viewer.updateOverlay(me, vp, OpenSeadragon.Placement.BOTTOM);
    var n = nearest(pos.x, pos.y);
    document.getElementById('where').textContent = 'Kervan: ' + (n.p ? (n.d < 250 ? n.p.tr : n.p.tr + ' yakınları') : '—') + '  ·  x ' + pos.x + ', y ' + pos.y;
  }
  viewer.addOnceHandler('open', function () {
    viewer.addOverlay({ element: me, location: viewer.viewport.imageToViewportCoordinates(pos.x, pos.y), placement: OpenSeadragon.Placement.BOTTOM, checkResize: false });
    place(pos.x, pos.y);
  });
  var moveBtn = document.getElementById('move');
  moveBtn.onclick = function () { moveBtn.setAttribute('aria-pressed', moveBtn.getAttribute('aria-pressed') === 'true' ? 'false' : 'true'); };
  viewer.addHandler('canvas-click', function (e) {
    if (!e.quick || moveBtn.getAttribute('aria-pressed') !== 'true') return;
    var ip = viewer.viewport.viewerElementToImageCoordinates(e.position); place(ip.x, ip.y);
  });
  function go(x, y, z) { viewer.viewport.panTo(viewer.viewport.imageToViewportCoordinates(x, y)); if (z) viewer.viewport.zoomTo(viewer.viewport.imageToViewportZoom(z)); }
  document.getElementById('follow').onclick = function () { go(pos.x, pos.y, 0.6); };
  document.getElementById('zin').onclick = function () { viewer.viewport.zoomBy(1.6); };
  document.getElementById('zout').onclick = function () { viewer.viewport.zoomBy(1 / 1.6); };
  document.getElementById('home').onclick = function () { viewer.viewport.goHome(); };
  var qi = document.getElementById('q'), hits = document.getElementById('hits');
  function norm(s) { return (s || '').toLocaleLowerCase('tr'); }
  qi.oninput = function () {
    var t = norm(qi.value).trim(); hits.innerHTML = '';
    if (t.length < 2) return;
    P.filter(function (p) { return norm(p.tr).indexOf(t) >= 0 || norm(p.en).indexOf(t) >= 0; }).slice(0, 12).forEach(function (p) {
      var li = document.createElement('li'); li.tabIndex = 0; li.setAttribute('role', 'option');
      li.textContent = p.tr + (p.en && p.en !== p.tr ? ' · ' + p.en : '');
      li.onclick = li.onkeydown = function (ev) { if (ev.type === 'keydown' && ev.key !== 'Enter') return; go(p.x, p.y, 0.8); hits.innerHTML = ''; qi.value = p.tr; };
      hits.appendChild(li);
    });
  };
}
</script></body></html>
"""
open(os.path.join(out, "index.html"), "w", encoding="utf-8").write(HTML)
print("görüntüleyici", out, W, H, len(places), "yer")
