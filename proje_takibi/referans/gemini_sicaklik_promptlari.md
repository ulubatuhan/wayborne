# Sıcaklık göstergesi: Gemini promptları (hava ikonları ve rakamlar)
Sonuç: sıcaklık göstergesi de öbür dördü gibi bronz bir madalyon olacak. İçinde o anın havası, havanın üstünde derece
("5", "−12°" gibi). Rakamların etrafındaki hafif ışık halesini **ben ekliyorum** (işleme hattında, oyunda 2-3 px). Resme
gömülürse gücü sonradan ayarlanamaz, o yüzden istemde hale yok.

Referans görseller:
- `proje_takibi/referans/taslaklar/y_gosterge_stil_referansi.png` (oyunun ikon dili ve paleti)
- `proje_takibi/referans/taslaklar/y_gosterge_madalyon_referansi.png` (onaylanan dört madalyon; hava ikonları bunlarla
  yan yana duracak)

## Hangi resim ne zaman

| Resim | Ne zaman |
|---|---|
| Açık (gündüz) | açık hava, gündüz |
| Açık (gece) | açık hava, akşam ve gece |
| Bulutlu | kapalı hava |
| Yağmur | yağmur, 0 °C ve üstü |
| Sis | sis |
| Fırtına | fırtına, 0 °C ve üstü |
| Kar | yağmur, 0 °C'nin altında |
| Tipi | fırtına, 0 °C'nin altında |

Oyunun beş havası var (açık, kapalı, yağmur, sis, fırtına); gece ve kar/tipi yalnızca görünüş, yeni bir hava değil.

## Nasıl kullanılır

1. **Hava ikonları:** ilk istem (Açık gündüz) için iki referans görseli de ekle. Sonraki her ikon için ilk çıktıyı ekle
   ve "Same style..." ile başlayan istemi kullan; sekizi ancak böyle aynı elden çıkmış gibi durur.
2. **Rakamlar:** tek istem, tek sayfa. Ek olarak stil referansını ekle. Bir rakam bozuk çıkarsa (yapay zekâ rakamlarda
   sık şaşırır: ters 4, kuyruklu 7) sayfayı yeniden ürettir; tek tek düzeltmeye çalışma, aynı sayfadan gelmeleri gerek.
3. Dosya adları: hava ikonları `sicaklik_<ad>.png` (`sicaklik_acik_gunduz.png` gibi, aşağıdaki başlıklarda yazıyor),
   rakam sayfası `sicaklik_rakamlar.png`. PNG ver; JPG gelirse ben çeviririm.

## Kopyalanmaya hazır istemler: hava ikonları

### Açık (gündüz) → `sicaklik_acik_gunduz.png` (ek: iki referans görseli)

```
Match the drawing style of the attached reference sheet. A low pale sun with short straight engraved rays, a few thin wisps of cloud along the bottom edge.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, slate blue-grey #788A94, frost white-blue #CCE0ED, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for sunlight. No neon, no glow aura, no purple, no saturated cyan, no smooth vector gradients, no text, no numbers, no frame, no border, no circle badge. The motif is composed to sit inside a circle with a generous margin all round. Keep the centre of the picture calm and fairly pale, because a number will be laid over it later; put the heaviest detail and darkest ink toward the edges. Bold, simple shapes that still read when shown 64 pixels wide; avoid tiny repeated detail. Square 1:1 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

### Açık (gece) → `sicaklik_acik_gece.png` (ek: Açık (gündüz) çıktısı)

```
Same style, same line weight and the same framing as the attached image, a different weather: A thin crescent moon high on one side and three small stars, faint night-sky hatching only near the edges.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, slate blue-grey #788A94, frost white-blue #CCE0ED, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for sunlight. No neon, no glow aura, no purple, no saturated cyan, no smooth vector gradients, no text, no numbers, no frame, no border, no circle badge. The motif is composed to sit inside a circle with a generous margin all round. Keep the centre of the picture calm and fairly pale, because a number will be laid over it later; put the heaviest detail and darkest ink toward the edges. Bold, simple shapes that still read when shown 64 pixels wide; avoid tiny repeated detail. Square 1:1 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

### Bulutlu → `sicaklik_bulutlu.png` (ek: Açık (gündüz) çıktısı)

```
Same style, same line weight and the same framing as the attached image, a different weather: Two heavy layered clouds drifting across, dense cross-hatching on their lower edges, their upper middle left pale.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, slate blue-grey #788A94, frost white-blue #CCE0ED, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for sunlight. No neon, no glow aura, no purple, no saturated cyan, no smooth vector gradients, no text, no numbers, no frame, no border, no circle badge. The motif is composed to sit inside a circle with a generous margin all round. Keep the centre of the picture calm and fairly pale, because a number will be laid over it later; put the heaviest detail and darkest ink toward the edges. Bold, simple shapes that still read when shown 64 pixels wide; avoid tiny repeated detail. Square 1:1 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

### Yağmur → `sicaklik_yagmur.png` (ek: Açık (gündüz) çıktısı)

```
Same style, same line weight and the same framing as the attached image, a different weather: A dark rain cloud along the top and slanted lines of rain falling across the lower half, the rain sparse in the middle.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, slate blue-grey #788A94, frost white-blue #CCE0ED, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for sunlight. No neon, no glow aura, no purple, no saturated cyan, no smooth vector gradients, no text, no numbers, no frame, no border, no circle badge. The motif is composed to sit inside a circle with a generous margin all round. Keep the centre of the picture calm and fairly pale, because a number will be laid over it later; put the heaviest detail and darkest ink toward the edges. Bold, simple shapes that still read when shown 64 pixels wide; avoid tiny repeated detail. Square 1:1 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

### Sis → `sicaklik_sis.png` (ek: Açık (gündüz) çıktısı)

```
Same style, same line weight and the same framing as the attached image, a different weather: Three long horizontal bands of mist drifting across, soft broken engraved lines, a faint bare tree silhouette behind them at one side.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, slate blue-grey #788A94, frost white-blue #CCE0ED, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for sunlight. No neon, no glow aura, no purple, no saturated cyan, no smooth vector gradients, no text, no numbers, no frame, no border, no circle badge. The motif is composed to sit inside a circle with a generous margin all round. Keep the centre of the picture calm and fairly pale, because a number will be laid over it later; put the heaviest detail and darkest ink toward the edges. Bold, simple shapes that still read when shown 64 pixels wide; avoid tiny repeated detail. Square 1:1 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

### Fırtına → `sicaklik_firtina.png` (ek: Açık (gündüz) çıktısı)

```
Same style, same line weight and the same framing as the attached image, a different weather: A black storm cloud along the top, a jagged lightning bolt striking down at one side, wind-driven rain slanting hard.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, slate blue-grey #788A94, frost white-blue #CCE0ED, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for sunlight. No neon, no glow aura, no purple, no saturated cyan, no smooth vector gradients, no text, no numbers, no frame, no border, no circle badge. The motif is composed to sit inside a circle with a generous margin all round. Keep the centre of the picture calm and fairly pale, because a number will be laid over it later; put the heaviest detail and darkest ink toward the edges. Bold, simple shapes that still read when shown 64 pixels wide; avoid tiny repeated detail. Square 1:1 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

### Kar → `sicaklik_kar.png` (ek: Açık (gündüz) çıktısı)

```
Same style, same line weight and the same framing as the attached image, a different weather: A low grey cloud along the top and snow falling from it: scattered six-pointed snowflakes, a few large ones near the edges, small ones in the middle.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, slate blue-grey #788A94, frost white-blue #CCE0ED, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for sunlight. No neon, no glow aura, no purple, no saturated cyan, no smooth vector gradients, no text, no numbers, no frame, no border, no circle badge. The motif is composed to sit inside a circle with a generous margin all round. Keep the centre of the picture calm and fairly pale, because a number will be laid over it later; put the heaviest detail and darkest ink toward the edges. Bold, simple shapes that still read when shown 64 pixels wide; avoid tiny repeated detail. Square 1:1 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

### Tipi → `sicaklik_tipi.png` (ek: Açık (gündüz) çıktısı)

```
Same style, same line weight and the same framing as the attached image, a different weather: A blizzard: snow driven sideways by a strong wind, curling wind lines sweeping across the top and bottom, snowflakes streaking.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, slate blue-grey #788A94, frost white-blue #CCE0ED, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for sunlight. No neon, no glow aura, no purple, no saturated cyan, no smooth vector gradients, no text, no numbers, no frame, no border, no circle badge. The motif is composed to sit inside a circle with a generous margin all round. Keep the centre of the picture calm and fairly pale, because a number will be laid over it later; put the heaviest detail and darkest ink toward the edges. Bold, simple shapes that still read when shown 64 pixels wide; avoid tiny repeated detail. Square 1:1 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

## Kopyalanmaya hazır istem: rakamlar → `sicaklik_rakamlar.png` (ek: stil referansı)

```
A single type specimen sheet on a plain flat mid-grey background (#808080). Twelve characters in two rows of six, each centred in its own equal invisible square cell with generous empty space around it:
Row 1: 0 1 2 3 4 5
Row 2: 6 7 8 9 − °
(the eleventh character is a minus sign, a short horizontal bar; the twelfth is a degree sign, a small raised ring).
Style: hand-engraved serif numerals like the figures printed in a 17th-century merchant's ledger. Lining figures: every digit the same height, all sitting on the same baseline, the same stroke weight throughout. Solid ink black #0E0D0F, slightly rough inked edges, no hatching inside the strokes, no outline, no glow, no shadow, no texture on the background.
Exactly these twelve characters and nothing else: no letters, no words, no grid lines, no borders, no frames, no decoration. Landscape 3:2 canvas.
```

## Neden böyle

- **Ortası sakin:** derece resmin ortasına binecek. Ağır mürekkep ortada olursa rakam okunmaz, hale de onu kurtaramaz;
  istem ayrıntıyı kenara itiyor.
- **Kare tuval:** madalyon yuvarlak. Önceki dört ikon 2:3 geldi, daireye sığdırırken boşluk kaldı; kare daha verimli.
- **Rakamlar düz mürekkep, taramasız:** 64 px'lik madalyonda bir rakam ~20 px boyunda. İç tarama o boyda kirli gri bir
  lekeye döner.
- **Eşit boy, aynı taban çizgisi:** "−12" gibi sayılar tek tek harflerden dizilecek. Eski üslup rakamlar (inişli
  çıkışlı) dizilince dans eder.
- **Hale yok, çerçeve yok:** ikisini de işleme hattı ekliyor, böylece oyunda ayarlanabiliyor.
- **Neon ve canlı camgöbeği yok:** soğuk tonlar için paletten arduvaz mavisi ve buz beyazı var; parlak mavi efektler
  oyunun dilinde değil.
