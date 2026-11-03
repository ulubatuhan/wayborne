"""Efekt kataloğu: yolda hissedilen her ıslaklık, kuruluk ve soğukluk.

Her kalem bir çekirdek (`cekirdekler.py`) ve bir parametre takımı. Alanlar:

- `id`      : oyunun kullandığı ad (`FxCatalog`), dosya adı da bu
- `cekirdek`: hangi çekirdek basacak
- `en/boy`  : tek karenin pikseli
- `kare`    : kaç kare
- `fps`     : oynatma hızı
- `dongu`   : perde ve bekleyen efektler döner; sıçrama bir kez oynar
- `m`       : karenin **dünyadaki eni** (metre). Oyun figür boyundan
              piksel/metre çıkarıp ölçekliyor (bkz. Prop Rules "ölçek
              gerçek boy"), yani efekt ekran çözünürlüğüne göre büyüyor.
- `mil`     : sprite'ın hangi noktasının verilen konuma oturacağı (0..1).
              Yerden fışkıran her şeyin mili alt-orta: temas noktası orası.
- `oklama`  : "yok" | "x" - oyunda yöne göre aynalanabilir mi
"""

from palet import (
    BATAKLIK_SISI, BUHAR, CAMUR, CAMUR_ACIK, DOLU, DUMAN, DUMAN_KOYU, KAR,
    KAR_SOLUK, KIRAGI, KOR, KOR_AK, SIS, SU, SU_PARLAK, TOZ, TOZ_SOLUK,
    YAGMUR, YAGMUR_SOLUK, YAPRAK,
)

PERDE_EN = 160
PERDE_KARE = 16

# Yerden fışkıranların ortak kutusu: geniş ve alçak, çünkü sıçrama yukarı
# değil *yanlara* gider - dar kutuda damlalar kenarda kesiliyordu.
PATLAMA = {"en": 120, "boy": 84, "kare": 12, "fps": 26, "dongu": False,
           "mil": [0.5, 1.0], "oklama": "x"}

KATALOG: list[dict] = []


def _ekle(**kw) -> None:
    KATALOG.append(kw)


def _patlama(**kw) -> None:
    taban = dict(PATLAMA)
    taban.update(kw)
    taban["cekirdek"] = "patlama"
    _ekle(**taban)


# ---------------------------------------------------------------------------
# 1. Gökten düşen: perdeler. Ekranı döşüyorlar, zamanda döngülüler.
# ---------------------------------------------------------------------------

_ekle(id="rain_light", cekirdek="perde", en=PERDE_EN, boy=PERDE_EN,
      kare=PERDE_KARE, fps=24, dongu=True, m=5.5, mil=[0.5, 0.5], oklama="yok",
      adet=70, cx=1, cy=3, renk=YAGMUR, renk2=YAGMUR_SOLUK,
      uzunluk=(7.0, 15.0), kalinlik=(0.45, 0.85), alfa=(0.16, 0.38))

_ekle(id="rain_medium", cekirdek="perde", en=PERDE_EN, boy=PERDE_EN,
      kare=PERDE_KARE, fps=24, dongu=True, m=5.5, mil=[0.5, 0.5], oklama="yok",
      adet=150, cx=1, cy=3, renk=YAGMUR, renk2=YAGMUR_SOLUK,
      uzunluk=(10.0, 22.0), kalinlik=(0.5, 1.0), alfa=(0.20, 0.52))

_ekle(id="rain_heavy", cekirdek="perde", en=PERDE_EN, boy=PERDE_EN,
      kare=PERDE_KARE, fps=28, dongu=True, m=5.0, mil=[0.5, 0.5], oklama="yok",
      adet=260, cx=1, cy=4, renk=YAGMUR, renk2=YAGMUR_SOLUK,
      uzunluk=(16.0, 34.0), kalinlik=(0.6, 1.3), alfa=(0.24, 0.62))

_ekle(id="sleet", cekirdek="perde", en=PERDE_EN, boy=PERDE_EN,
      kare=PERDE_KARE, fps=24, dongu=True, m=5.5, mil=[0.5, 0.5], oklama="yok",
      adet=150, cx=1, cy=3, renk=YAGMUR, renk2=KAR_SOLUK,
      uzunluk=(4.0, 16.0), kalinlik=(0.7, 1.5), alfa=(0.22, 0.55),
      kanat=(0.0, 3.0))

_ekle(id="hail", cekirdek="perde", en=PERDE_EN, boy=PERDE_EN,
      kare=PERDE_KARE, fps=30, dongu=True, m=5.0, mil=[0.5, 0.5], oklama="yok",
      adet=85, cx=1, cy=4, renk=DOLU, renk2=KAR, tanecik=True,
      kalinlik=(0.9, 1.9), alfa=(0.45, 0.85))

_ekle(id="snow_light", cekirdek="perde", en=PERDE_EN, boy=PERDE_EN,
      kare=PERDE_KARE, fps=18, dongu=True, m=6.0, mil=[0.5, 0.5], oklama="yok",
      adet=90, cx=1, cy=1, renk=KAR, renk2=KAR_SOLUK, tanecik=True,
      kalinlik=(0.5, 1.2), alfa=(0.30, 0.70), kanat=(3.0, 11.0))

_ekle(id="snow_heavy", cekirdek="perde", en=PERDE_EN, boy=PERDE_EN,
      kare=PERDE_KARE, fps=18, dongu=True, m=5.5, mil=[0.5, 0.5], oklama="yok",
      adet=200, cx=1, cy=1, renk=KAR, renk2=KAR_SOLUK, tanecik=True,
      kalinlik=(0.7, 1.8), alfa=(0.35, 0.85), kanat=(4.0, 14.0))

# Tipide kar neredeyse yatay: döngü oranı cx=3/cy=1, yani eğim 3.
_ekle(id="blizzard", cekirdek="perde", en=PERDE_EN, boy=PERDE_EN,
      kare=PERDE_KARE, fps=30, dongu=True, m=5.0, mil=[0.5, 0.5], oklama="yok",
      adet=200, cx=3, cy=1, renk=KAR, renk2=KAR_SOLUK,
      uzunluk=(8.0, 20.0), kalinlik=(0.6, 1.5), alfa=(0.20, 0.58),
      kanat=(2.0, 7.0))

_ekle(id="fog_drift", cekirdek="sis", en=PERDE_EN * 2, boy=PERDE_EN,
      kare=PERDE_KARE, fps=12, dongu=True, m=11.0, mil=[0.5, 0.5], oklama="yok",
      adet=26, cx=1, renk=SIS, yaricap=(22.0, 58.0), alfa=(0.05, 0.13),
      en_oran=2.6)

_ekle(id="ground_mist", cekirdek="sis", en=PERDE_EN * 2, boy=PERDE_EN // 2,
      kare=PERDE_KARE, fps=10, dongu=True, m=11.0, mil=[0.5, 1.0], oklama="yok",
      adet=22, cx=1, renk=BATAKLIK_SISI, yaricap=(16.0, 40.0),
      alfa=(0.06, 0.16), en_oran=3.4)


# ---------------------------------------------------------------------------
# 2. Yere düşüş: damlanın kuru toprağa, birikintiye ve kara çarpması.
# ---------------------------------------------------------------------------

_patlama(id="rain_impact_dry", en=28, boy=20, kare=10, fps=30, m=0.44,
         adet=13, aci=(55, 125), hiz=(26.0, 52.0), yercekimi=70.0,
         omur=(0.35, 0.6), yaricap=(0.9, 1.8), alfa=(0.50, 0.85),
         renk=TOZ, renk2=TOZ_SOLUK, oklama="yok",
         leke={"r": 6.0, "alfa": 0.16, "renk": TOZ_SOLUK, "en_oran": 2.4})

_ekle(id="rain_ripple", cekirdek="halka", en=56, boy=30, kare=12, fps=24,
      dongu=False, m=0.62, mil=[0.5, 0.5], oklama="yok",
      renk=SU_PARLAK, halka=2, r_son=22.0, kalinlik=1.2, alfa=0.78,
      araluk=0.26, en_oran=2.6, damla=True)

_patlama(id="rain_crown", en=34, boy=26, kare=10, fps=30, m=0.5,
         adet=11, aci=(62, 118), hiz=(30.0, 64.0), yercekimi=55.0,
         omur=(0.4, 0.7), yaricap=(0.9, 1.8), alfa=(0.68, 1.0),
         renk=SU_PARLAK, renk2=SU, uzar=3.0, oklama="yok",
         leke={"r": 6.0, "alfa": 0.13, "renk": SU, "en_oran": 2.8})

_patlama(id="snow_settle", en=34, boy=22, kare=10, fps=18, m=0.5,
         adet=13, aci=(50, 130), hiz=(18.0, 40.0), yercekimi=18.0,
         surtunme=2.2, omur=(0.7, 1.0), yaricap=(1.4, 3.0),
         alfa=(0.42, 0.78), renk=KAR, renk2=KAR_SOLUK, oklama="yok",
         leke={"r": 6.0, "alfa": 0.12, "renk": KAR_SOLUK, "en_oran": 2.6})

_patlama(id="canopy_drip", en=20, boy=48, kare=12, fps=26, m=0.3,
         kaynak_y=0.0, adet=5, aci=(76, 104), hiz=(6.0, 14.0),
         yercekimi=460.0, surtunme=0.2, omur=(0.6, 1.0),
         yaricap=(1.0, 1.9), alfa=(0.5, 0.8), uzar=4.0,
         renk=SU_PARLAK, renk2=SU, oklama="yok")


# ---------------------------------------------------------------------------
# 3. Ayak, toynak, pençe: geçen yayanın ve hayvanın zemine tepkisi.
#    Dört zemin: kuru toprak, çamur, su, kar.
# ---------------------------------------------------------------------------

_patlama(id="step_dust", m=0.95, adet=16, aci=(8, 62), hiz=(28.0, 72.0),
         yercekimi=14.0, surtunme=1.6, omur=(0.55, 1.0),
         yaricap=(2.2, 5.0), alfa=(0.40, 0.76), yumusak=0.95,
         renk=TOZ, renk2=TOZ_SOLUK)

_patlama(id="step_mud", m=0.88, adet=16, aci=(18, 78), hiz=(45.0, 108.0),
         yercekimi=85.0, omur=(0.4, 0.75), yaricap=(1.0, 2.3),
         alfa=(0.66, 1.0), renk=CAMUR, renk2=CAMUR_ACIK,
         yere_yapisir=True, uzar=2.0,
         leke={"r": 9.0, "alfa": 0.18, "renk": CAMUR, "en_oran": 2.8})

_patlama(id="step_splash", m=0.95, adet=18, aci=(22, 82), hiz=(55.0, 126.0),
         yercekimi=60.0, omur=(0.45, 0.85), yaricap=(0.9, 2.2),
         alfa=(0.62, 1.0), renk=SU_PARLAK, renk2=SU, uzar=3.5,
         leke={"r": 12.0, "alfa": 0.20, "renk": SU_PARLAK, "en_oran": 3.0})

_patlama(id="step_snow", m=0.9, adet=15, aci=(14, 72), hiz=(26.0, 62.0),
         yercekimi=30.0, surtunme=1.8, omur=(0.5, 0.9),
         yaricap=(1.5, 3.2), alfa=(0.48, 0.88), yumusak=0.9,
         renk=KAR, renk2=KAR_SOLUK,
         leke={"r": 8.0, "alfa": 0.13, "renk": KAR_SOLUK, "en_oran": 2.6})

# Toynak daha ağır: aynı zemine daha çok ve daha hızlı parça savuruyor.
_patlama(id="hoof_dust", m=1.15, adet=20, aci=(6, 56), hiz=(36.0, 90.0),
         yercekimi=16.0, surtunme=1.5, omur=(0.6, 1.1),
         yaricap=(2.6, 6.0), alfa=(0.42, 0.80), yumusak=0.95,
         renk=TOZ, renk2=TOZ_SOLUK)

_patlama(id="hoof_mud", m=1.08, adet=20, aci=(16, 80), hiz=(55.0, 128.0),
         yercekimi=95.0, omur=(0.4, 0.8), yaricap=(1.1, 2.8),
         alfa=(0.70, 1.0), renk=CAMUR, renk2=CAMUR_ACIK,
         yere_yapisir=True, uzar=2.6,
         leke={"r": 11.0, "alfa": 0.20, "renk": CAMUR, "en_oran": 2.8})

_patlama(id="hoof_splash", m=1.18, adet=22, aci=(20, 84), hiz=(66.0, 150.0),
         yercekimi=66.0, omur=(0.45, 0.9), yaricap=(1.0, 2.5),
         alfa=(0.64, 1.0), renk=SU_PARLAK, renk2=SU, uzar=4.5,
         leke={"r": 14.0, "alfa": 0.23, "renk": SU_PARLAK, "en_oran": 3.0})

_patlama(id="hoof_snow", m=1.12, adet=18, aci=(12, 74), hiz=(32.0, 76.0),
         yercekimi=34.0, surtunme=1.7, omur=(0.55, 1.0),
         yaricap=(1.7, 3.8), alfa=(0.50, 0.92), yumusak=0.9,
         renk=KAR, renk2=KAR_SOLUK,
         leke={"r": 10.0, "alfa": 0.16, "renk": KAR_SOLUK, "en_oran": 2.6})

_patlama(id="paw_snow", en=56, boy=40, m=0.55, adet=12, aci=(14, 76),
         hiz=(20.0, 46.0), yercekimi=26.0, surtunme=1.9, omur=(0.45, 0.85),
         yaricap=(1.1, 2.4), alfa=(0.38, 0.72), yumusak=0.9,
         renk=KAR, renk2=KAR_SOLUK)


# ---------------------------------------------------------------------------
# 4. Tekerlek: temas çizgisi boyunca yelpaze. Geniş kutu, çünkü savrulan
#    şey tekerleğin arkasına doğru uzuyor.
# ---------------------------------------------------------------------------

_patlama(id="wheel_dust", en=180, boy=112, kare=14, fps=24, m=1.6,
         adet=24, aci=(4, 48), hiz=(34.0, 94.0), yercekimi=12.0,
         surtunme=1.4, omur=(0.7, 1.2), yaricap=(3.4, 8.0),
         alfa=(0.34, 0.66), yumusak=0.98, renk=TOZ, renk2=TOZ_SOLUK,
         gecikme=(0.0, 0.25))

_patlama(id="wheel_mud", en=180, boy=112, kare=14, fps=26, m=1.6,
         adet=26, aci=(12, 76), hiz=(62.0, 146.0), yercekimi=98.0,
         omur=(0.45, 0.9), yaricap=(1.2, 3.0), alfa=(0.66, 1.0),
         renk=CAMUR, renk2=CAMUR_ACIK, yere_yapisir=True, uzar=3.0,
         leke={"r": 16.0, "alfa": 0.18, "renk": CAMUR, "en_oran": 3.2})

_patlama(id="wheel_splash", en=180, boy=112, kare=14, fps=28, m=1.7,
         adet=30, aci=(14, 80), hiz=(72.0, 172.0), yercekimi=72.0,
         omur=(0.45, 0.95), yaricap=(1.0, 2.6), alfa=(0.58, 1.0),
         renk=SU_PARLAK, renk2=SU, uzar=5.5,
         leke={"r": 19.0, "alfa": 0.20, "renk": SU_PARLAK, "en_oran": 3.4})

_patlama(id="wheel_snow", en=180, boy=112, kare=14, fps=22, m=1.6,
         adet=24, aci=(10, 70), hiz=(40.0, 98.0), yercekimi=36.0,
         surtunme=1.7, omur=(0.6, 1.1), yaricap=(2.0, 4.8),
         alfa=(0.44, 0.84), yumusak=0.92, renk=KAR, renk2=KAR_SOLUK,
         leke={"r": 15.0, "alfa": 0.14, "renk": KAR_SOLUK, "en_oran": 3.0})


# ---------------------------------------------------------------------------
# 5. Yerde kalan izler. Yassı lekeler zemindir (bkz. TravelForeground'un
#    "yassı lekeler zemindir" kuralı): üst üste binmeleri doğal.
# ---------------------------------------------------------------------------

_ekle(id="track_foot_mud", cekirdek="iz", en=40, boy=20, kare=5, fps=1,
      dongu=False, m=0.42, mil=[0.5, 0.5], oklama="x", renk=CAMUR_ACIK,
      parlak=SU_PARLAK, sonum=0.82, yumusak=0.42,
      sekiller=[["elips", 0.43, 0.54, 4.6, 1.75, 0.90],
                ["elips", 0.60, 0.52, 3.4, 1.30, 0.76],
                ["elips", 0.72, 0.47, 1.8, 1.25, 0.58]])

_ekle(id="track_foot_snow", cekirdek="iz", en=40, boy=20, kare=5, fps=1,
      dongu=False, m=0.42, mil=[0.5, 0.5], oklama="x", renk=KAR_SOLUK,
      sonum=0.70, yumusak=0.62,
      sekiller=[["elips", 0.43, 0.54, 5.0, 1.75, 0.56],
                ["elips", 0.60, 0.52, 3.6, 1.30, 0.46],
                ["elips", 0.72, 0.47, 2.0, 1.25, 0.34]])

_ekle(id="track_hoof_mud", cekirdek="iz", en=36, boy=20, kare=5, fps=1,
      dongu=False, m=0.34, mil=[0.5, 0.5], oklama="x", renk=CAMUR_ACIK,
      parlak=SU_PARLAK, sonum=0.82, yumusak=0.42,
      sekiller=[["hilal", 0.5, 0.54, 5.4, 2.2, 200, 340, 0.78]])

_ekle(id="track_hoof_snow", cekirdek="iz", en=36, boy=20, kare=5, fps=1,
      dongu=False, m=0.34, mil=[0.5, 0.5], oklama="x", renk=KAR_SOLUK,
      sonum=0.70, yumusak=0.55,
      sekiller=[["hilal", 0.5, 0.54, 5.6, 2.4, 200, 340, 0.60]])

_ekle(id="track_wheel_mud", cekirdek="iz", en=96, boy=22, kare=5, fps=1,
      dongu=False, m=1.35, mil=[0.5, 0.5], oklama="yok", renk=CAMUR_ACIK,
      parlak=SU_PARLAK, sonum=0.80,
      sekiller=[["yiv", 0.04, 0.96, 0.38, 2.1, 0.82, 1.3],
                ["yiv", 0.04, 0.96, 0.64, 1.8, 0.68, 1.1],
                ["elips", 0.22, 0.40, 3.2, 2.2, 0.26],
                ["elips", 0.71, 0.64, 2.8, 2.2, 0.22]])

_ekle(id="track_wheel_snow", cekirdek="iz", en=96, boy=22, kare=5, fps=1,
      dongu=False, m=1.35, mil=[0.5, 0.5], oklama="yok", renk=KAR_SOLUK,
      sonum=0.68,
      sekiller=[["yiv", 0.04, 0.96, 0.38, 2.4, 0.52, 1.2],
                ["yiv", 0.04, 0.96, 0.64, 2.1, 0.42, 1.0]])


# ---------------------------------------------------------------------------
# 6. Soğuk ve nem: nefes, kırağı, birikintinin kırışığı.
# ---------------------------------------------------------------------------

_ekle(id="breath_vapor", cekirdek="bulut", en=56, boy=34, kare=14, fps=16,
      dongu=False, m=0.6, mil=[0.10, 0.62], oklama="x", renk=BUHAR,
      adet=9, kaynak_x=0.10, kaynak_y=0.62, hiz_x=(26.0, 48.0),
      hiz_y=(-10.0, -2.0), yaricap=(1.6, 3.4), buyume=(5.0, 10.0),
      omur=(0.55, 1.0), alfa=(0.26, 0.50), savrul=3.0)

_ekle(id="breath_vapor_beast", cekirdek="bulut", en=72, boy=44, kare=14,
      fps=14, dongu=False, m=0.85, mil=[0.10, 0.62], oklama="x", renk=BUHAR,
      adet=12, kaynak_x=0.10, kaynak_y=0.62, hiz_x=(34.0, 64.0),
      hiz_y=(-14.0, -4.0), yaricap=(2.2, 4.6), buyume=(7.0, 14.0),
      omur=(0.6, 1.0), alfa=(0.28, 0.54), savrul=4.0)

_patlama(id="frost_glint", en=44, boy=44, kare=14, fps=16, m=0.55,
         kaynak_y=0.5, adet=16, aci=(0, 360), hiz=(8.0, 22.0),
         yercekimi=6.0, surtunme=1.2, omur=(0.5, 1.0),
         yaricap=(0.7, 1.6), alfa=(0.55, 1.0), yumusak=0.3,
         renk=KIRAGI, renk2=KAR, oklama="yok")

_ekle(id="puddle_shiver", cekirdek="sis", en=80, boy=28, kare=16, fps=12,
      dongu=True, m=0.70, mil=[0.5, 0.5], oklama="yok", renk=SU_PARLAK,
      adet=7, cx=1, yaricap=(4.0, 9.0), alfa=(0.05, 0.12), en_oran=3.6)


# ---------------------------------------------------------------------------
# 7. Ateş ve duman. Sıcak renk yalnızca burada: tek sıcak kaynak kuralı.
# ---------------------------------------------------------------------------

_ekle(id="ember_rise", cekirdek="bulut", en=56, boy=96, kare=16, fps=20,
      dongu=True, m=0.50, mil=[0.5, 1.0], oklama="yok", renk=KOR,
      adet=20, hiz_x=(-10.0, 10.0), hiz_y=(-80.0, -44.0),
      yaricap=(0.9, 1.9), buyume=(-0.3, 0.2), omur=(0.6, 1.0),
      alfa=(0.6, 1.0), gecikme=(0.0, 0.9), savrul=7.0)

_ekle(id="smoke_thin", cekirdek="bulut", en=72, boy=112, kare=16, fps=14,
      dongu=True, m=0.95, mil=[0.5, 1.0], oklama="yok", renk=DUMAN,
      adet=16, hiz_x=(-8.0, 14.0), hiz_y=(-62.0, -38.0),
      yaricap=(3.0, 6.0), buyume=(10.0, 20.0), omur=(0.7, 1.0),
      alfa=(0.16, 0.32), gecikme=(0.0, 0.9), savrul=9.0)

_ekle(id="smoke_thick", cekirdek="bulut", en=96, boy=128, kare=16, fps=12,
      dongu=True, m=1.40, mil=[0.5, 1.0], oklama="yok", renk=DUMAN_KOYU,
      adet=22, hiz_x=(-10.0, 16.0), hiz_y=(-54.0, -30.0),
      yaricap=(5.0, 10.0), buyume=(16.0, 30.0), omur=(0.7, 1.0),
      alfa=(0.20, 0.40), gecikme=(0.0, 0.9), savrul=11.0)

_ekle(id="fire_steam", cekirdek="bulut", en=72, boy=88, kare=14, fps=18,
      dongu=False, m=1.0, mil=[0.5, 1.0], oklama="yok", renk=BUHAR,
      adet=14, hiz_x=(-14.0, 14.0), hiz_y=(-78.0, -46.0),
      yaricap=(2.0, 5.0), buyume=(9.0, 18.0), omur=(0.5, 0.9),
      alfa=(0.16, 0.34), gecikme=(0.0, 0.3), savrul=8.0)

_ekle(id="lantern_halo", cekirdek="sis", en=72, boy=72, kare=16, fps=14,
      dongu=True, m=0.95, mil=[0.5, 0.5], oklama="yok", renk=KOR_AK,
      adet=5, cx=0, yaricap=(10.0, 26.0), alfa=(0.05, 0.11), en_oran=1.0)


# ---------------------------------------------------------------------------
# 8. Rüzgâr: yerden kalkan toz, savrulan yaprak ve kar.
# ---------------------------------------------------------------------------

_patlama(id="dust_gust", en=160, boy=72, kare=16, fps=18, m=2.4,
         adet=26, aci=(2, 34), hiz=(50.0, 130.0), yercekimi=-14.0,
         surtunme=1.1, omur=(0.7, 1.2), yaricap=(3.0, 8.0),
         alfa=(0.10, 0.26), yumusak=0.98, renk=TOZ, renk2=TOZ_SOLUK,
         gecikme=(0.0, 0.3))

_patlama(id="leaf_drift", en=160, boy=84, kare=16, fps=16, m=2.4,
         adet=15, aci=(6, 46), hiz=(44.0, 104.0), yercekimi=36.0,
         surtunme=0.9, omur=(0.8, 1.2), yaricap=(1.4, 2.8),
         alfa=(0.60, 0.95), yumusak=0.35, renk=YAPRAK, renk2=TOZ_SOLUK,
         gecikme=(0.0, 0.35), uzar=2.0)

_patlama(id="snow_gust", en=160, boy=72, kare=16, fps=20, m=2.3,
         adet=30, aci=(2, 30), hiz=(56.0, 148.0), yercekimi=-8.0,
         surtunme=1.0, omur=(0.7, 1.2), yaricap=(2.0, 6.0),
         alfa=(0.14, 0.34), yumusak=0.96, renk=KAR, renk2=KAR_SOLUK,
         gecikme=(0.0, 0.3))
