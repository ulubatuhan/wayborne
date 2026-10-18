"""Kullanım: python render_overlays.py <harita.html> [boyut=4096]
Şeffaf PNG katmanları üretir: overlay_roads.png, overlay_icons.png (playwright gerekir)."""
import sys,base64
from playwright.sync_api import sync_playwright
html=sys.argv[1];size=int(sys.argv[2]) if len(sys.argv)>2 else 4096
import os
with sync_playwright() as p:
    b=p.chromium.launch();pg=b.new_page(viewport={'width':1200,'height':900})
    pg.goto('file://'+os.path.abspath(html));pg.wait_for_timeout(800)
    for name,o in(('overlay_roads',{'roads':True}),('overlay_icons',{'icons':True,'mul':1.4})):
        u=pg.evaluate('([s,o])=>window.exportOverlay(s,o)',[size,o])
        open(name+'.png','wb').write(base64.b64decode(u.split(',')[1]));print(name)
    b.close()
