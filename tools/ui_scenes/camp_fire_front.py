"""Menü kampının ateşini (odunlar ve alev) arka plandan keser: ateşin ardında oturan
yolcunun bacakları ateşin arkasında kalsın diye, o yolcunun üstüne yeniden çizilir
(GrimDrafts.FIRE_FRONT_RECT). Çokgen arka planın 1920x1080 piksellerinde elle izlendi.

    python3 -I tools/ui_scenes/camp_fire_front.py

Render'ın alevi köşeli tek renk konilerdi (kullanıcı, 2026-11-02, T16-04): koniler
render'dan silinir (OpenCV inpaint, yalnız alev bölgesi, odunlar kalır) ve
background.jpg buradan yazılır; alev oyunda `CampFlame` ile dalgalanan dillerle
çizilir. Kaynak render art_source/ui_scenes/camp_background_render.jpg.
"""
import os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
CAMP = os.path.join(ROOT, "data", "assets", "ui", "towns", "camp")
BOX = (460, 665, 660, 860)
OUTLINE = [(472, 847), (470, 807), (500, 800), (508, 793), (513, 745), (530, 770), (550, 723), (563, 688),
           (577, 710), (587, 710), (607, 767), (608, 793), (647, 792), (654, 820), (627, 832), (620, 848)]

import cv2
import numpy as np

SOURCE = os.path.join(ROOT, "art_source", "ui_scenes", "camp_background_render.jpg")
# Alev konilerinin bölgesi (odunların üstü), 1920x1080 pikselinde elle izlendi.
FLAME = [(503, 796), (507, 742), (528, 700), (556, 660), (582, 658), (598, 700), (614, 758), (614, 796)]
raw = cv2.imread(SOURCE)
flame_mask = np.zeros(raw.shape[:2], np.uint8)
cv2.fillPoly(flame_mask, [np.array(FLAME, np.int32)], 255)
flame_mask = cv2.dilate(flame_mask, np.ones((5, 5), np.uint8))
clean = cv2.inpaint(raw, flame_mask, 9, cv2.INPAINT_TELEA)
cv2.imwrite(os.path.join(CAMP, "background.jpg"), clean, [cv2.IMWRITE_JPEG_QUALITY, 94])

bg = Image.open(os.path.join(CAMP, "background.jpg")).convert("RGBA")
mask = Image.new("L", bg.size, 0)
ImageDraw.Draw(mask).polygon(OUTLINE, fill=255)
bg.putalpha(mask.filter(ImageFilter.GaussianBlur(1.2)))
bg.crop(BOX).save(os.path.join(CAMP, "fire_front.png"))
print("fire_front.png", BOX)
