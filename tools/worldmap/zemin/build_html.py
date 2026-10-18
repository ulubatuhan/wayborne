"""Kullanım: python build_html.py <zemin_gorseli.jpg|png> [cikti.html]
renderer_template.html + data/world.json + verilen zemin görselini tek dosyalık HTML haritaya çevirir.
Zemin görseli kare olmalı (dünya koordinatı 4096x4096; görsel kareye gerilir)."""
import base64,sys,io
from PIL import Image
src=sys.argv[1];out=sys.argv[2] if len(sys.argv)>2 else 'wayborne_new.html'
im=Image.open(src).convert('RGB')
if im.width!=im.height:im=im.resize((max(im.size),)*2,Image.LANCZOS)
im=im.resize((min(im.width,2560),)*2,Image.LANCZOS)
b=io.BytesIO();im.save(b,'JPEG',quality=85,optimize=True,progressive=True)
t=open('renderer_template.html',encoding='utf8').read()
t=t.replace('/*DATA*/',open('../data/world.json',encoding='utf8').read()).replace('/*IMG*/',base64.b64encode(b.getvalue()).decode())
open(out,'w',encoding='utf8').write(t);print(out,len(t)/1e6,'MB')
