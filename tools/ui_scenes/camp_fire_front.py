"""Menü kampının ateşini (odunlar ve alev) arka plandan keser: ateşin ardında oturan
yolcunun bacakları ateşin arkasında kalsın diye, o yolcunun üstüne yeniden çizilir
(GrimDrafts.FIRE_FRONT_RECT). Çokgen arka planın 1920x1080 piksellerinde elle izlendi.

    python3 -I tools/ui_scenes/camp_fire_front.py
"""
import os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
CAMP = os.path.join(ROOT, "data", "assets", "ui", "towns", "camp")
BOX = (460, 665, 660, 860)
OUTLINE = [(472, 847), (470, 807), (500, 800), (508, 793), (513, 745), (530, 770), (550, 723), (563, 688),
           (577, 710), (587, 710), (607, 767), (608, 793), (647, 792), (654, 820), (627, 832), (620, 848)]

bg = Image.open(os.path.join(CAMP, "background.jpg")).convert("RGBA")
mask = Image.new("L", bg.size, 0)
ImageDraw.Draw(mask).polygon(OUTLINE, fill=255)
bg.putalpha(mask.filter(ImageFilter.GaussianBlur(1.2)))
bg.crop(BOX).save(os.path.join(CAMP, "fire_front.png"))
print("fire_front.png", BOX)
