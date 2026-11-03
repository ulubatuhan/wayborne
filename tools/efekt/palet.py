"""Efektlerin renkleri. `ArtPalette`'in kuralı burada da geçerli:

**Tek sıcak kaynak.** Dünyada sıcak renk yalnızca bir ışık kaynağından
gelir. Bu dosyada sıcak olan yalnızca `KOR` ve `KOR_AK` - ateşin kendisi.
Yağmur, kar, sis, su, çamur, toz, duman ve nefes soğuk ve soluk; biri
ısıtılırsa ateşin anlamı kalmaz (bkz. kurallar-sanat, Art Rules).

Değerler `scripts/ui/art_palette.gd` ile elle eşleşiyor: `KOR` oradaki
`TORCH`, `MARSH_MIST` `TravelBand`'in bataklık sisiyle aynı. İkisi
ayrılırsa ateş iki ekranda iki renk olur.
"""

# Gökten düşen
YAGMUR = (0.72, 0.79, 0.88)
YAGMUR_SOLUK = (0.58, 0.65, 0.74)
KAR = (0.93, 0.95, 0.98)
KAR_SOLUK = (0.80, 0.85, 0.92)
DOLU = (0.86, 0.90, 0.95)

# Hava
SIS = (0.70, 0.73, 0.76)
BATAKLIK_SISI = (0.50, 0.56, 0.49)  # TravelBand.MARSH_MIST
BUHAR = (0.86, 0.89, 0.92)
KIRAGI = (0.84, 0.92, 0.98)

# Yer. Çamur **önlükten açık**: yolun altındaki en yakın şerit neredeyse
# siyah bir toprak bandı (bkz. kurallar-sanat, "önlüğe göre açık"), ve ilk
# ölçüde gerçek çamur rengi (0.26, 0.21, 0.16) oraya basıldığında koyunun
# üstünde koyu kalıp hiç görünmüyordu. Havaya savrulan çamur ışık da alır;
# yerdeki iz bu yüzden kendi rengiyle değil, içinde biriken suyun
# parıltısıyla okunuyor (`parlak`).
SU = (0.60, 0.70, 0.78)
SU_PARLAK = (0.78, 0.86, 0.92)
CAMUR = (0.42, 0.34, 0.26)
CAMUR_ACIK = (0.56, 0.47, 0.36)
TOZ = (0.72, 0.66, 0.55)
TOZ_SOLUK = (0.58, 0.53, 0.45)
YAPRAK = (0.52, 0.46, 0.28)

# Duman
DUMAN = (0.46, 0.45, 0.46)
DUMAN_KOYU = (0.28, 0.27, 0.28)

# Tek sıcak kaynak: ateş.
KOR = (0.96, 0.68, 0.34)  # ArtPalette.TORCH
KOR_AK = (1.00, 0.85, 0.55)
