# Gösterge ikonları: Gemini promptları (moral, stres, takat, tehlike)

Referans görsel: `proje_takibi/referans/taslaklar/y_gosterge_stil_referansi.png`. Oyunun mevcut ikonları (stat, görev,
durum ikonları, mühür, kâse), gösterge plakası ve palet. İlk istemde bu resmi ekle: "Match the drawing style of the
attached reference sheet."

## Nasıl kullanılır

1. Her gösterge için önce **Yüksek** hücresini üret.
2. Orta ve Düşük için o ilk çıktıyı ekle ve başına şunu yaz: *"Same icon as the attached image: same object, same camera
   angle, same scale and framing, same line style. Change only this:"* ve ardından hücrenin konu satırını. Üç hâl ancak
   böyle aynı nesne gibi okunur.
3. Her istemin sonuna **ORTAK STİL** bloğunu ekle.

## ORTAK STİL (her istemin sonuna)

```
Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine
cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet.
Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917,
parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers.
No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge.
One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown
64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else
in the background.
```

## Konu satırları

| | Yüksek | Orta | Düşük |
|---|---|---|---|
| **Moral (meşale)** | An iron wall-bracket torch with a tall, full flame, wrapped pitch-soaked cloth head, sparks rising. | The same torch, flame half as tall, leaning and ragged, fewer sparks. | The same torch burnt out: charred black cloth head, one small red ember, a thin wisp of grey smoke. |
| **Moral (sancak, öneri)** | A caravan's swallow-tailed cloth banner on a wooden pole, raised to the top and flying full in the wind. | The same banner halfway down the pole, hanging slack, edges frayed. | The same banner at the foot of the pole, torn, limp and muddy. |
| **Stres (dikenli sarmaşık)** | A thorny bramble vine crushed into a dense, knotted ball, thorns everywhere, a few dark red drops on the thorns. | The same bramble drawn into a tighter ring, coiling over itself, more thorns pointing inward. | The same bramble as a loose, open ring, few thorns, calm and even. |
| **Takat (at)** | A draught horse in side profile, trotting strongly, head up, mane and tail lifted by the motion. | The same horse standing still, head lowered, flanks heaving, breath vapour from the nostrils. | The same horse collapsed on its side, legs folded, head on the ground, eyes half closed, exhausted but alive. |
| **Tehlike (kuzgunlar)** | A gnarled, leafless dark branch crowded with three black ravens, feathers ruffled, beaks open, dark-red eye glints. | The same branch with one black raven perched, looking forward, a small dark-red glint in its eye. | The same branch, empty. |

Not: sütunlar değerin kendisi. Yüksek stres en yoğun düğüm, yüksek tehlike üç kuzgun. Tutarlılık için her
göstergede önce en dolu hâli (Yüksek) üret, öbür ikisini ondan türet: dalı ve sarmaşığı boşaltmak, eklemekten daha
kolay tutarlı kalıyor.

## Kopyalanmaya hazır istemler
Her blok tek başına bir istem: olduğu gibi yapıştır. Ek olarak ne iliştireceğin başlıkta yazıyor.

### Moral (meşale)

**Yüksek** (ek: stil referansı panosu)

```
Match the drawing style of the attached reference sheet. An iron wall-bracket torch with a tall, full flame, wrapped pitch-soaked cloth head, sparks rising.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers. No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge. One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown 64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

**Orta** (ek: bu göstergenin Yüksek çıktısı)

```
Same icon as the attached image: same object, same camera angle, same scale and framing, same line style. Change only this: The same torch, flame half as tall, leaning and ragged, fewer sparks.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers. No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge. One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown 64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

**Düşük** (ek: bu göstergenin Yüksek çıktısı)

```
Same icon as the attached image: same object, same camera angle, same scale and framing, same line style. Change only this: The same torch burnt out: charred black cloth head, one small red ember, a thin wisp of grey smoke.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers. No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge. One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown 64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

### Moral (sancak, öneri)

**Yüksek** (ek: stil referansı panosu)

```
Match the drawing style of the attached reference sheet. A caravan's swallow-tailed cloth banner on a wooden pole, raised to the top and flying full in the wind.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers. No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge. One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown 64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

**Orta** (ek: bu göstergenin Yüksek çıktısı)

```
Same icon as the attached image: same object, same camera angle, same scale and framing, same line style. Change only this: The same banner halfway down the pole, hanging slack, edges frayed.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers. No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge. One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown 64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

**Düşük** (ek: bu göstergenin Yüksek çıktısı)

```
Same icon as the attached image: same object, same camera angle, same scale and framing, same line style. Change only this: The same banner at the foot of the pole, torn, limp and muddy.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers. No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge. One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown 64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

### Stres (dikenli sarmaşık)

**Yüksek** (ek: stil referansı panosu)

```
Match the drawing style of the attached reference sheet. A thorny bramble vine crushed into a dense, knotted ball, thorns everywhere, a few dark red drops on the thorns.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers. No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge. One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown 64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

**Orta** (ek: bu göstergenin Yüksek çıktısı)

```
Same icon as the attached image: same object, same camera angle, same scale and framing, same line style. Change only this: The same bramble drawn into a tighter ring, coiling over itself, more thorns pointing inward.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers. No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge. One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown 64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

**Düşük** (ek: bu göstergenin Yüksek çıktısı)

```
Same icon as the attached image: same object, same camera angle, same scale and framing, same line style. Change only this: The same bramble as a loose, open ring, few thorns, calm and even.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers. No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge. One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown 64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

### Takat (at)

**Yüksek** (ek: stil referansı panosu)

```
Match the drawing style of the attached reference sheet. A draught horse in side profile, trotting strongly, head up, mane and tail lifted by the motion.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers. No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge. One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown 64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

**Orta** (ek: bu göstergenin Yüksek çıktısı)

```
Same icon as the attached image: same object, same camera angle, same scale and framing, same line style. Change only this: The same horse standing still, head lowered, flanks heaving, breath vapour from the nostrils.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers. No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge. One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown 64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

**Düşük** (ek: bu göstergenin Yüksek çıktısı)

```
Same icon as the attached image: same object, same camera angle, same scale and framing, same line style. Change only this: The same horse collapsed on its side, legs folded, head on the ground, eyes half closed, exhausted but alive.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers. No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge. One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown 64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

### Tehlike (kuzgunlar)

**Yüksek** (ek: stil referansı panosu)

```
Match the drawing style of the attached reference sheet. A gnarled, leafless dark branch crowded with three black ravens, feathers ruffled, beaks open, dark-red eye glints.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers. No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge. One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown 64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

**Orta** (ek: bu göstergenin Yüksek çıktısı)

```
Same icon as the attached image: same object, same camera angle, same scale and framing, same line style. Change only this: The same branch with one black raven perched, looking forward, a small dark-red glint in its eye.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers. No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge. One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown 64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

**Düşük** (ek: bu göstergenin Yüksek çıktısı)

```
Same icon as the attached image: same object, same camera angle, same scale and framing, same line style. Change only this: The same branch, empty.

Hand-engraved etching in the style of a 17th-century woodcut book illustration: dark ink linework with fine cross-hatching for shading, muted and desaturated, grim and weathered, like the attached reference sheet. Limited palette: ink black #0E0D0F, iron grey #454242, rust brown #734024, dried-blood crimson #992917, parchment #C4B08F, ash grey #ABA69E; dull amber #EDA852 only for fire or embers. No neon, no glow aura, no purple, no cyan, no smooth vector gradients, no text, no frame, no border, no circle badge. One object centred with generous empty margin around it. Bold, simple silhouette that still reads when shown 64 pixels tall; avoid tiny repeated detail. Portrait 2:3 canvas. Plain flat mid-grey background (#808080), nothing else in the background.
```

## Neden bu değişiklikler

- **Vektör ve neon değil, gravür:** oyunun bütün ikonları mürekkep, tarama ve soluk renk. Parlak mor ve mavi efektler
  kullanıcı kararıyla daha önce kaldırıldı (Y-G06).
- **Siyah değil, düz gri zemin:** ikonları oyuna alan hat (`tools/waybook_assets.py`) düz gri zemini saydam yapıyor.
  Siyah zemin, ikonun kendi siyah mürekkep konturuyla birlikte silinir.
- **Dikenli tel yerine dikenli sarmaşık:** dikenli tel 1870'lerin icadı; ortaçağ kervan dünyasında yabancı durur.
  Aynı imge dikenli sarmaşıkla korunuyor.
- **Atın son hâli ölü değil, bitkin:** takat sıfır ölüm demek değil. Ölü at ölüm göstergesi gibi okunur.
- **Küçük boy:** göstergeler oyunda ~64×92 px. "Yüzlerce diken" o boyda gri bir lekeye dönüşür, sade siluet şart.
- **Meşale uyarısı:** sıcaklık göstergesi de bir alev (mum). Yan yana iki alev aynı şeyi gösteriyor gibi okunabilir.
  Bu yüzden sancak satırı alternatif olarak eklendi; ikisini de üretip yan yana denemek mümkün.
