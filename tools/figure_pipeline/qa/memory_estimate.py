"""Faz 0: katmanli kare render'in bellek/disk tahmini. Her girdi ya OLCULMUS (kaynak
yaninda) ya da ACIKCA varsayim. Formul:
  piksel = varyant x parca x ort.katman x kare x ort.kirpilmis-katman-alani
"""
# --- OLCULMUS (qa/_measure_layer_bbox.gd, gercek FigureRig yurume dongusu, 48 kare) ---
# 5 katmanin sabit max kutu alani toplami, h^2 biriminde (kalinlik payi VARSAYIM: uzuv 0.055h, govde 0.11h)
BODY_5LAYER_AREA_H2 = 0.8439          # govde: bir karedeki 5 katmanin toplami
AVG_LAYER_AREA_H2 = BODY_5LAYER_AREA_H2 / 5.0
# --- OLCULMUS (qa/_measure_screen_figure.gd, gercek yol sahnesi, 1920x1080, zoom 1.0) ---
BOX_H_1X = 119.0                       # yurume figurunun kutu boyu px (lider atli: 169)
# --- VARSAYIM (Faz 0 sorularinda, kullanici kararina bagli) ---
PARTS_PER_VARIANT = 40                 # postmortem ornegi: govde + 39 kiyafet parcasi
LAYERS_PER_GARMENT = 3                 # postmortem ornegi (gomlek: iki kol + govde)
BYTES = {"sikistirmasiz RGBA8 (4 B/px)": 4.0, "GPU sikistirmali 8bpp ETC2/BC3 (1 B/px)": 1.0}

def px_per_variant_frame(h, parts):
    body = BODY_5LAYER_AREA_H2 * h * h
    garments = (parts - 1) * LAYERS_PER_GARMENT * AVG_LAYER_AREA_H2 * h * h
    return body + garments

def mb(x):
    return x / 1e6

print("== KUTUPHANE TOPLAMI (disk/Web indirme/en kotu bellek) ==")
print("varyant parca kare  render |  px(M)  | " + " | ".join(BYTES))
for scale_name, h in (("1x", BOX_H_1X), ("2x", BOX_H_1X * 2)):
    for V in (2, 4, 6):
        for F in (24, 48, 100):
            px = V * F * px_per_variant_frame(h, PARTS_PER_VARIANT)
            cols = " | ".join("%8.0f MB" % mb(px * b) for b in BYTES.values())
            print(f"{V:^7}{PARTS_PER_VARIANT:^6}{F:^6}{scale_name:^8}| {mb(px):7.0f} | {cols}")

print()
print("== CALISMA KUMESI (ayni anda bellekte): V_yuklu varyant, kisi basina govde + 4 kiyafet ==")
print("V_yuklu kare render | " + " | ".join(BYTES))
for scale_name, h in (("1x", BOX_H_1X), ("2x", BOX_H_1X * 2)):
    for Vl in (1, 4):
        F = 48
        px = Vl * F * px_per_variant_frame(h, 5)
        cols = " | ".join("%8.0f MB" % mb(px * b) for b in BYTES.values())
        print(f"{Vl:^8}{F:^5}{scale_name:^7}| {cols}")

print()
print("== MESH-DEFORM karsilastirmasi: kare yok, parca/katman basina TEK doku (F=1) ==")
for scale_name, h in (("1x", BOX_H_1X), ("2x", BOX_H_1X * 2)):
    px = 4 * 1 * px_per_variant_frame(h, PARTS_PER_VARIANT)
    print(f"4 varyant x 40 parca, {scale_name}: " + " | ".join("%6.1f MB" % mb(px * b) for b in BYTES.values()))

print()
print("== GEVSEK SINIR (postmortem'in 60x120 px / 160 px figur varsayimi -> 0.281 h^2 katman basina) ==")
print("Neden: giysiler (pelerin, uzun palto, silah, sac) govdeye oturan kutudan buyuk; ustteki")
print("'olculmus' alan govde-oturan alt sinirdir. Gercek deger Faz 3'te giysiyle olculur.")
LOOSE = (60 * 120) / (160.0 * 160.0)
for scale_name, h in (("1x", BOX_H_1X), ("2x", BOX_H_1X * 2)):
    px = 4 * 100 * PARTS_PER_VARIANT * LAYERS_PER_GARMENT * LOOSE * h * h
    print(f"4 varyant x 40 parca x 100 kare, {scale_name}: {mb(px):6.0f} Mpx -> " +
          " | ".join("%7.0f MB" % mb(px * b) for b in BYTES.values()))
print("Not: postmortem'in 'siskistirmasiz ~350 MB' sayisi 345.6 Mpx x 1 B/px; RGBA8 icin 4 B/px =",
      "%.0f MB (1 B/px olsa %.0f MB)." % (mb(4.0 * 4 * 100 * 40 * 3 * 60 * 120), mb(4.0 * 100 * 40 * 3 * 60 * 120)))
