# Kuşam promptları — bütün figür yolu (B kategorisi)

**Bu dosya `docs/gemini-prompts.md`'nin B bölümünün yerine geçiyor.** Format
değişti: artık 3×3'lük bir parça sayfası değil, **tek bir bütün figür**
isteniyor.

Neden: dokuz ayrı hücreyi eklem işaretlerine hizalı istemek yedi tur üst üste
başarısız oldu (saç/ten rengi/silah hücresi sızmaları, hücre sınırlarının
karışması, üslup kayması). Hayvanlar aynı duvara çarpmıştı ve çözüm oradan
geliyor — CLAUDE.md'nin kendi cümlesi: *"Nine disjoint parts aligned to joint
markers is not something an image model does reliably; one side view is."*
Tek, tutarlı bir yandan görünüş bir görüntü modelinin de, bir ressamın da,
bir 3B render'ın da güvenilir biçimde verebildiği şey.

Kesme işini artık `tools/wardrobe_cut.py` yapıyor: her boyalı pikseli
altındaki kemiğe verip dokuz parça tuvaline döndürüyor. Mankenin kendisiyle
ölçüldü — kesilip yeniden kurulan figür, boyandığı pozda orijinalinden
**%0.04**, en uzak pozda **%4.2** farklı çıkıyor.

---

## Her prompt'un başına eklenen ortak blok

Aşağıdaki her kalem için **`docs/wardrobe/paint_pose_reference.png` dosyasını
referans görsel olarak ekle** ve şu bloğu kalemin kendi tarifinin başına
yapıştır:

```
Use the attached image as an exact underlay. It is a 768x1152 reference of a
wooden artist's mannequin, side view, facing right, mid-stride.

Paint ONLY the garment described below, worn on that body, at exactly the
scale, position and pose of the underlay. Output 768x1152, the same framing.

Hard rules:
- Do NOT draw the body, head, face, hair, hands or feet. Only the garment.
  Everywhere the garment does not cover must be empty background.
- Do NOT move, rotate, rescale or re-pose the figure. The garment must sit on
  the underlay's own limbs, pixel for pixel.
- Side view, facing right. Light from the upper left. Flat, matte, hand-inked
  look with a dark contour line - no gloss, no glow, no rim light, no gradient
  background, no shadow cast on the ground.
- Both the near and the far limb get their garment: the far sleeve and far
  trouser leg are visible beside the body and must be painted too, slightly
  darker.
- No text, no letters, no logo, no watermark anywhere in the image.
- Flat single-colour background (plain mid-grey), nothing else in the frame.
```

Teslimat JPG ise arka planı araç kaldırıyor (`--key`).

---

## Kalemler

Her başlığın altındaki metni ortak bloğun **arkasına** ekle.

### B-01 · hat_felt — Fötr Şapka
`python3 tools/wardrobe_cut.py <dosya> hat_felt`
Kapsadığı yerler: baş.

> GARMENT: A soft felt cap in faded brown (#6B5238), the kind worn by nomads
> and drovers: rounded crown, a short upturned brim at the front, a stitched
> seam along the side. It sits on the top of the head down to the ears. The
> face and the rest of the body stay empty.

### B-02 · hat_hood — Yolcu Kukuletesi
`python3 tools/wardrobe_cut.py <dosya> hat_hood`
Kapsadığı yerler: baş, gövdenin üst kenarı (omuz pelerini).

> GARMENT: A grey-brown wool travelling hood (#4D4D57) pulled over the head,
> drawn slightly forward over the brow, falling to the neck and the top of the
> shoulders as a short shoulder cape. The face opening stays empty.

### B-03 · shirt_linen — Keten Gömlek
`python3 tools/wardrobe_cut.py <dosya> shirt_linen`
Kapsadığı yerler: gövde, üst kol, ön kol (iki kol da).

> GARMENT: A plain undyed linen shirt (#D1C7A8), loose and slightly creased,
> collarless with a short slit at the neck, long sleeves ending just above the
> wrist, hem tucked at the waist. Thin, soft fabric.

### B-04 · shirt_dyed — Boyalı Gömlek
`python3 tools/wardrobe_cut.py <dosya> shirt_dyed`
Kapsadığı yerler: gövde, üst kol, ön kol.

> GARMENT: A woad-dyed blue linen shirt (#5C7594), faded unevenly from sun and
> washing, a narrow woven band along the collar and cuffs in pale gold
> (#DCB357). Long sleeves to the wrist, belted at the waist with a thin cord.

### B-05 · jacket_wool — Yün Kaftan
`python3 tools/wardrobe_cut.py <dosya> jacket_wool`
Kapsadığı yerler: gövde, üst kol, ön kol, uyluğun üstü (etek).

> GARMENT: A heavy brown wool kaftan-style coat (#614733), wrapped across the
> chest and tied at the side, reaching mid-thigh so its skirt hangs over the
> upper thigh, long sleeves slightly wider at the cuff, a darker felt trim
> along the front edge and hem. Worn patches at the elbows.

### B-06 · jacket_leather — Deri Yelek
`python3 tools/wardrobe_cut.py <dosya> jacket_leather`
Kapsadığı yerler: gövde, üst kolun üst üçte biri.

> GARMENT: A dark oiled leather jerkin (#4D3324), sleeveless body with short
> cap sleeves over the shoulder only, laced up the front with leather thongs,
> scuffed and creased, a broad belt with a simple iron buckle.

### B-07 · gloves_leather — Deri Eldiven
`python3 tools/wardrobe_cut.py <dosya> gloves_leather`
Kapsadığı yerler: el, ön kolun bilek ucu.

> GARMENT: Brown work gloves of thick leather (#57402E) with a short flared
> cuff that covers the lower forearm, stitched seams on the back of the hand.
> Both hands are gloved.

### B-08 · pants_wool — Yün Şalvar
`python3 tools/wardrobe_cut.py <dosya> pants_wool`
Kapsadığı yerler: uyluk, baldır (iki bacak da).

> GARMENT: Dark grey-brown wool trousers (#47423D), loose at the thigh,
> wrapped tight below the knee with cloth puttee bands up the shin.

### B-09 · pants_canvas — Kanvas Şalvar
`python3 tools/wardrobe_cut.py <dosya> pants_canvas`
Kapsadığı yerler: uyluk, baldır.

> GARMENT: Light sand-coloured canvas trousers (#948A70), baggy in the
> Anatolian şalvar cut - full at the thigh, gathered at the ankle - dusty at
> the hem, a patched knee.

### B-10 · shoes_boots — Binici Çizmesi
`python3 tools/wardrobe_cut.py <dosya> shoes_boots`
Kapsadığı yerler: baldır (konç), ayak.

> GARMENT: Tall soft leather riding boots (#382920), reaching just below the
> knee, a slightly upturned toe, worn creases at the ankle, a thin sole. Both
> feet are booted; the sole wraps the underlay's own foot exactly.

### B-11 · shoes_sandals — Sandalet
`python3 tools/wardrobe_cut.py <dosya> shoes_sandals`
Kapsadığı yerler: ayak, bileğin alt ucu.

> GARMENT: Simple leather sandals (#80664D): a flat sole with straps across
> the foot and two thin straps wrapping the lower ankle. The foot itself is
> NOT painted - only the sole and the straps, with empty background in the
> gaps between them.

### B-12 · armor_tier_1 — Deri Zırh
`python3 tools/wardrobe_cut.py <dosya> armor_tier_1`
Kapsadığı yerler: gövde, omuz, uyluğun üstü.

> GARMENT: Hardened boiled-leather armour: a thick quilted-and-leather
> cuirass covering chest and back to the hip, overlapping leather strips
> hanging over the upper thigh, small leather shoulder guards. Brown and dark
> tan (#5A3F2A / #7A5A3C), stitched, scuffed, matte.

### B-13 · armor_tier_2 — Zincir Gömlek
`python3 tools/wardrobe_cut.py <dosya> armor_tier_2`
Kapsadığı yerler: gövde, üst kol, uyluğun üst yarısı.

> GARMENT: A riveted iron mail shirt (cold steel #6F7A82, darker in the
> folds) reaching mid-thigh, with elbow-length mail sleeves, worn over a
> quilted under-coat whose padded edge shows at the neck and hem. The mail is
> a fine ring texture, not individual shiny rings; dull, slightly rusty.

### B-14 · armor_tier_3 — Plaka Zırh
`python3 tools/wardrobe_cut.py <dosya> armor_tier_3`
Kapsadığı yerler: gövde, üst kol, ön kol, uyluk.

> GARMENT: Lamellar and plate armour of a veteran caravan guard: a chest of
> laced iron lamellae over mail, a rounded pauldron on the shoulder, a plate
> vambrace on the forearm, lamellar tassets over the thigh, a riveted iron
> gorget at the neck. Dull iron (#6F7A82) with dark leather lacing and a thin
> pale-gold (#DCB357) edge on the pauldron - worn, dented, never polished.

### B-15 · weapon_tier_1 — Kervan Kılıcı
`python3 tools/wardrobe_cut.py <dosya> weapon_tier_1 --only weapon`
Kapsadığı yerler: yalnız silah.

> GARMENT: A plain iron arming sword for caravan guards, held in the figure's
> forward hand and hanging straight DOWN from the grip: straight single-edged
> blade, simple cross guard, leather-wrapped grip, round iron pommel. Grey
> steel, a few nicks on the edge. Paint only the sword - not the hand.

### B-16 · weapon_tier_2 — Usta İşi Kılıç
`python3 tools/wardrobe_cut.py <dosya> weapon_tier_2 --only weapon`
Kapsadığı yerler: yalnız silah.

> GARMENT: A well-made curved sabre (kılıç), held in the figure's forward hand
> and hanging DOWN from the grip: a slightly curved single-edged blade
> widening a little toward the tip, a short straight guard with downturned
> ends, a grip wrapped in dark leather, a dulled brass (#DCB357) pommel cap.
> The curve bends toward the right. Paint only the sabre - not the hand.

### B-17 · weapon_tier_3 — Şahin Kılıcı
`python3 tools/wardrobe_cut.py <dosya> weapon_tier_3 --only weapon`
Kapsadığı yerler: yalnız silah.

> GARMENT: A fine old sabre of a master smith, held in the figure's forward
> hand and hanging DOWN from the grip: a deeply curved blade with a subtle
> wavy forging pattern in the steel, a pale-gold (#DCB357) guard whose two
> ends are shaped like folded falcon wings, a grip bound in dark red cord
> (#A83029), a falcon-head pommel. Still worn and matte, not glowing. The
> curve bends toward the right. Paint only the sabre - not the hand.

### B-18 · amulet_ward — Muska
`python3 tools/wardrobe_cut.py <dosya> amulet_ward --only torso`
Kapsadığı yerler: yalnız göğsün üstü.

> GARMENT: A small folded triangular cloth charm (muska) in faded red wool,
> stitched shut, hanging from a dark cord around the neck; the cord runs up
> toward the neck, the charm rests on the upper chest. Nothing else is
> painted.

### B-19 · amulet_wolf_fang — Kurt Dişi
`python3 tools/wardrobe_cut.py <dosya> amulet_wolf_fang --only torso`
Kapsadığı yerler: yalnız göğsün üstü.

> GARMENT: A single large yellowed wolf fang bound with a leather thong, hung
> on a braided cord around the neck, resting on the upper chest. Nothing else
> is painted.

### B-20 · amulet_courage — Cesaret Tılsımı
`python3 tools/wardrobe_cut.py <dosya> amulet_courage --only torso`
Kapsadığı yerler: yalnız göğsün üstü.

> GARMENT: A flat bronze disc pendant (dull #B08A4A), its face hammered with a
> simple radiating pattern (no letters, no religious sign), on a thin chain
> around the neck, resting on the upper chest. Nothing else is painted.

---

## B-00 (çıplak beden) burada yok — bilerek

Çıplak beden artık prompt'la istenmiyor; CC0 bir 3B insan modelinden
deterministik olarak render edilecek (bkz. CLAUDE.md'nin Ana Hedefler'indeki
"Çıplak beden (B-00) AI-prompt yerine 3D model render'ından üretilecek"
maddesi). Bu dosyadaki yirmi kalem ise 2B yolda kalıyor: `Wardrobe`'un
takılıp-çıkarılabilir katman mimarisi (`SLOT_LAYERS`) tek bir sürekli
render'dan kolay ayrışmıyor.

Beden gelene kadar her kalem bugünkü mankenin üstünde çiziliyor — manken
zaten oyunda, ve bu dosyanın referans görseli de o.

## Teslimattan sonra

```
python3 tools/wardrobe_cut.py <dosya> <kalem_id>
godot --headless --import
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" \
  godot --path . --rendering-driver opengl3 --script res://tests/screenshot_hub.gd
```

Son adım bir test değil, bir resim: parçanın gerçekten yürüyen figürün
üstünde durduğunu hiçbir assertion göremez (bkz. CLAUDE.md, Testing).
