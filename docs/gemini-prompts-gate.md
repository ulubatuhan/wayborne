# Şehir kapısı promptları (K kategorisi)

Yürüyüş alanındaki (`scripts/world/world_hub.gd`) şehir kapısı hâlâ düz bir
`ColorRect`: `GATE_COLOR`, zemin çizgisinde duran 150x230'luk bir kutu.
Oyunun son yer tutucusu bu.

## Önce bir uyarı: bu resim prosedürel bir sahnenin içine giriyor

Hub'ın manzarası `_draw()` ile çiziliyor (`HubScenery`, `ArtDraw`), yani
kapı fotoğrafik ya da 3B render bir illüstrasyon olursa Art Rules'un
defalarca kaydettiği "iki ayrı prodüksiyon" tuzağına düşer - ekranın geri
kalanı düz mürekkep, ortasında bir tablo. O yüzden her prompt'un ortak
bloğu bunu **ilk kuralı** olarak söylüyor, ve teslimat geldiğinde ilk
bakılacak şey konu değil, dil olacak: aynı düz mürekkep, aynı sınırlı
palet, aynı kontur.

Resim gelmezse ya da sahneye oturmazsa ikinci yol duruyor: aynı kapıyı
`ArtDraw` ile (duvar + kemer + kanat silueti) çizmek. O da kabul edilebilir
bir sonuç, çünkü asıl kusur kapının çirkin olması değil, **bir dikdörtgen
olması**.

## Şablonlar

| Dosya | Ne işe yarar |
|---|---|
| `docs/gate/gate_template.png` | 900x700. Zemin çizgisi, kapı açıklığının gerçek kutusu (150x230), hub'ın gerçekten çizdiği boyda iki insan, ve insan boyu cinsinden yükseklik kılavuzları. **Üstüne boyanır, yeniden boyutlandırılmaz.** |
| `docs/gate/gate_palette.png` | `ArtPalette`in ilgili renkleri, altlarında hex değerleri. |

Üretmek/yenilemek: `python3 tools/gate_template.py`

---

## Her prompt'un başına eklenen ortak blok

`gate_template.png`'i referans görsel olarak ekle ve şunu kalemin kendi
tarifinin önüne yapıştır:

```
Use the attached image as an exact underlay. It is a 900x700 template with a
red GROUND line, a red rectangle marking the doorway opening, and two stick
figures drawn at the exact height a person is drawn in this game.

STYLE - this is the hard part, read it twice:
- Flat, hand-inked 2D artwork: solid shapes, a dark contour line, at most
  two or three flat tones per material. NOT photorealistic, NOT a 3D render,
  NOT painterly, no texture photography, no lens blur, no bloom.
- Think a printed woodcut or a flat vector side-elevation, lit evenly. The
  game tints the whole scene by the hour of day, so paint it in neutral
  daylight with no strong cast shadows and no baked sunset colour.
- Side-on elevation, flat to the camera. No perspective, no vanishing point,
  no three-quarter view - the whole game's walking area is a flat side view.
- Limited earthy palette: dark ink #0E0D0F for contours, muted stone greys
  and browns, pale gold #DBB357 only as a rare accent (a hinge, a banner
  ring). No saturated colours.

HARD RULES:
- The foot of the structure sits exactly on the red GROUND line.
- The opening sits exactly over the red rectangle and is empty (the player
  walks through it) - do not draw a closed door across it.
- Keep the template's scale: the two stick figures are real people. The gate
  must read as a city gate they could walk through.
- Transparent background. Nothing outside the structure itself - no sky, no
  ground, no landscape, no scenery, no people.
- No text, no letters, no numbers, no signage, no watermark anywhere.
- Output 900x700, same framing as the template.
```

Teslimat JPG ise arka planı `tools/waybook_ingest_v2.py`'nin keyleme yolu
kaldırıyor; şeffaf PNG tercih edilir.

---

## Kalemler

### K-01 · Şehir kapısı (ana)
Çıktı: `gate_main.png`

> SUBJECT: The gate of a walled trading city on a caravan road. A thick
> masonry wall of dressed stone blocks, running off both edges of the frame,
> with a tall arched opening in the middle. Over the arch a short projecting
> gallery with a plain timber hoarding and narrow slit windows. On each side
> of the opening a squat buttress tower, flat-topped, lower than the wall
> head. Heavy iron-banded timber gate leaves stand folded back flat against
> the wall on either side of the opening, so the way through is clear. The
> stone is weathered and uneven, patched in places with newer blocks; a
> little road dust stains the lowest courses.
>
> This city grew out of trade, not worship or war: wall, gate, warehouse.
> No dome, no minaret, no spire, no cathedral window, no heraldry, no
> statues, no banners with emblems.

### K-02 · Duvar parçası (yanlara uzar, tekrarlanabilir)
Çıktı: `gate_wall.png`
Aynı ortak blok, ama kapı açıklığı **yok** - bu parça kapının iki yanına
eklenip duvarı uzatmak için:

> SUBJECT: A plain section of the same city wall, no opening in it. Dressed
> stone blocks in the same courses and the same weathering as the gate, a
> simple flat coping along the top, one narrow slit window high up. It must
> tile seamlessly against itself on the left and right edges: the stone
> courses meet the frame edge at the same heights on both sides.
>
> Ignore the doorway rectangle in the template for this one - fill that part
> with wall like everywhere else. The ground line still applies.

### K-03 · Kapı kemerinin gece feneri (küçük ek)
Çıktı: `gate_lamp.png`
Opsiyonel, küçük bir parça - gece sahnesinde kemerin yanında yanan fener:

> SUBJECT: A single wrought-iron wall lantern on a short bracket, seen from
> the side, its horn panes glowing warm. Nothing else in the frame. Small -
> about one third of a person's height. Transparent background.
>
> Output a smaller canvas than the template (about 160x220); the template is
> only for reading the game's style and palette here, not for placement.

---

## Teslimattan sonra

Dosyalar `art_source/gate/` altına konur (`.gdignore` ile Godot'un
import'undan uzak), sonra işlenip `data/assets/world/gate/`'e yazılır ve
`world_hub.gd`'nin `_build_spots()`'u `ColorRect` yerine bir `TextureRect`
kurar - etkileşim dikdörtgeni (`_spots`) **aynı kalır**, yalnızca görünen
şey değişir. Oranın doğruluğu `tests/screenshot_hub_motion.gd`'nin
kılavuzlu karesiyle aynı şekilde ölçülür: kapının açıklığı gerçekten bir
insanın geçebileceği gibi mi duruyor.
