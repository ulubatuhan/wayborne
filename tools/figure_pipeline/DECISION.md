# DECISION — Faz 0 raporu ve yol karşılaştırması

**Geçti (sayıyla):** 5/5 Faz-0 maddesi toplandı (klip/FigureRig, ekran boyu, bellek, envanter, bu tablo). Ölçümler: 1 gerçek-sahne ölçümü (1920×1080, 8 `WalkFigure`), 1 katman-kutusu ölçümü (48 kare, 5 katman), 1 bellek tablosu (26 satır). Hiçbir içerik üretilmedi, hiçbir dosya silinmedi.
**Kaldı:** karar bekleyen 1 kapı (yol seçimi). Bellek tablosunun 4 girdisi varsayım (aşağıda "Varsayım" etiketli); 4 soru `QUESTIONS.md`'de.
**Test edilmedi:** gerçek GPU'da hiçbir şey (hedef makine/fps bilinmiyor); MPFB eli ve oranları Faz 1 `proportions` testine kadar render'dan ölçülmedi; giysili kırpıntı boyutları (Faz 3).
**Kullanıcıdan istenen tek karar:** yol A mı (katmanlı kare render) yoksa B mi (mesh-deform)? Öneri en altta.

---

## 1. FigureRig ve klipler (dosya:satır)

**Klip yok.** `AnimationPlayer`/`AnimatedSprite`/`SpriteFrames`/`.anim` için `scripts/`, `scenes/`, `tests/` tarandı: sıfır sonuç. Hiçbir klibin kare sayısı ya da fps'i yok; her şey tek bir saf fonksiyondan geliyor:

| Ne | Nerede | Gerçek |
|---|---|---|
| Poz = saf fonksiyon | `scripts/character/figure_rig.gd:112` `pose(ground, h, phase, motion, facing, lean, seated, bulk)` | 8 sürekli/ayrık girdi; tablo/klip yok |
| Tek çalışma-zamanı çağıran | `scripts/ui/walk_figure.gd:240` | başka çağıran yok (`rg "FigureRig.pose"`: yalnız testler/araçlar) |
| Yürüyüş = sinüs + 2 kemikli çözüm | `figure_rig.gd:118` kalça zıplaması `sin(2·phase)`; `:160-175` `_leg` (ayak hedefi `cos/sin`, diz `solve_joint`); `:178-191` `_arm` (`lerpf(0.35, sin(phase), motion)`) | **IK var** (yalnız bacak-ayak, `:199`); nişan alma yok; klip karışımı yok |
| Genlik karışımı (tek 1-B karışım) | `walk_figure.gd:172` `ease_motion`; `:42-43` `REST_EASE_SECONDS=0.25`, `START_EASE_SECONDS=0.12` | `motion` 0↔1, 0,12/0,25 sn'de sürekli |
| Faz sürücüsü | `walk_figure.gd:157-170` `advance()`: `phase += delta·|speed|·TAU` | **mesafeye bağlı, değişken hız**; yön yalnız `facing` (ayna) |
| Yol hızı | `road_caravan.gd:112` `STEP_RATE=0.43` çevrim/sn; lider tavanı `:289` ×2,4; saat çarpanı `journey_clock.gd:24` `SPEEDS=[0.5,1,1.5,3]` | ≈0,2–1,3 çevrim/sn |
| Hub hızı | `world_hub.gd:15` `WALK_SPEED=280`, `:61` `STEP_PER_UNIT=0.0178`, `:267` | 280·0,0178 ≈ **5 çevrim/sn** (60 fps'te çevrim başına ~12 kare) |
| Eğilme (rüzgâr) | `road_caravan.gd:182` `WIND_LEAN` 0,035/0,07 rad ×(1±0,35) dalga, `:529` | sürekli, ≤ ~0,095 rad (5,4°), figür başına faz kaymalı |
| Yön | `walk_figure.gd:189`; dönüş dalgası `world_hub.gd:119-142` | ±1 ayna + figür başına gecikmeli dönüş |
| Oturan biniciyi poz | `figure_rig.gd:121-126` `seated=true` | arka bacak yok; ayrı poz |
| Savaş | `combat_figure.gd:223-250`: `set_standing()` + `set_combat_stance(true)`; lunge/sarsıntı/düşüş `combat_fx.gd:41` (`FALL_ANGLE=1,25`) | **tek duran poz + tüm-figür dönüşümü**, klip değil |

Sonuç: tek yürüme çevrimi (faz 0..TAU), duran poz ve ayna yeterli olan şeyler: yol yürüyüşü, hub yürüyüşü, savaş duruşu. **Sabit kare listesinin karşılamadığı sürekli girdiler:** `motion` (başlama/durma geçişi), `lean` (rüzgâr), `seated` (atlı lider), `bulk` (baş hacmi), boy ölçeği 0,86–1,14 (`world_hub.gd:680`).

## 2. Ekranda figür boyu ve fps

**Ölçüm** (`qa/_measure_screen_figure.gd`, gerçek `road_journey.tscn`, 1920×1080, 2 vagonlu kervan, zoom 1,0; `qa/..` çıktısı `scratchpad/measure_screen.log`):
- yürüyen kişi kutusu **113–119 px** (boy ölçeği 0,94–1,06); çizilen insan kutunun ~%86'sı ≈ **~100 px**
- atlı lider kutusu **169 px**; öküz 139 px
- hub: `world_hub.gd:43-50` kişi 62–86 px, atlı lider 128 px, ekip 72 px
- yakınlaştırma 0,7–1,6 (CLAUDE.md, Road Movement Rules) → yol figürü ≈ 83–190 px kutu: **2× render'ın gerekçesi 1,6 yakınlaştırma**
- **Hedef fps: projede tanımlı değil** (`project.godot`: `max_fps`/vsync ayarı yok; viewport 1920×1080 `canvas_items/expand`). Varsayım 60 (PERF.md'deki varsayımla aynı) — soru olarak `QUESTIONS.md`'de.

## 3. Bellek tahmini (`qa/memory_estimate.py`, çıktı `qa/memory_estimate_output.txt`)

Formül: `piksel = varyant × parça × ort.katman × kare × ort.kırpılmış katman alanı`.
Ölçülen: 5 katmanın sabit en-büyük kutu alanı **0,844 h²** (48 kare, gerçek `FigureRig.pose`; kalınlık payı **varsayım**: uzuv 0,055h, gövde 0,11h → kırpıntı, giysisiz gövdeye oturan **alt sınır**). Varsayım: 40 parça/varyant, giysi başına 3 katman, 1 B/px = 8 bpp ETC2/BC3.

| Varyant | Kare | Render | Kütüphane px | RGBA8 sıkıştırmasız | GPU sıkıştırmalı (1 B/px) |
|---|---|---|---|---|---|
| 4 | 48 | 1× (h=119) | 56 M | 224 MB | 56 MB |
| 4 | 100 | 1× | 117 M | 467 MB | 117 MB |
| 4 | 100 | 2× (h=238) | 467 M | 1866 MB | 467 MB |
| 6 | 100 | 2× | 700 M | 2799 MB | 700 MB |
| 4 | 100 | 1×, **gevşek kutu** (pelerin/silah payı) | 191 M | 765 MB | 191 MB |
| 4 | 100 | 2×, gevşek kutu | 765 M | 3059 MB | 765 MB |

Çalışma kümesi (aynı anda bellekte; kişi başına gövde + 4 giysi, 48 kare): 1 varyant 1× **2 MB** GPU / 8 MB RGBA; 4 varyant 2× **31 MB** GPU / 125 MB RGBA. Mesh-deform karşılığı (kare yok, parça/katman başına tek doku): 4 varyant × 40 parça 1× **1,2 MB** GPU, 2× 4,7 MB.

**Düzeltme (postmortem'e):** "sıkıştırmasız ~350 MB" sayısı 345,6 Mpx × **1** B/px; RGBA8 (4 B/px) olsa 1382 MB, aynı senaryoda GPU sıkıştırmalı 346 MB (raporun "~90 MB"ı ~0,26 B/px varsayıyor; Godot 4.2'de ASTC doğrulanmadı, 8 bpp aldım). **Disk/Web:** CLAUDE.md "Web build her dokuyu indirir" — Web hedefi sürüyorsa kütüphane toplamı indirme boyutudur; 56–117 MB (1×) kabul edilebilir olabilir, 467–765 MB değil. Varyant başına ayrı paket gerekirse bu ayrı iş.

## 4. Envanter (hiçbir şey silinmedi)

**Yeniden kullanılacak:** `SETUP.md` + MPFB kurulum komutu; `blender/make_variant.py` (`build_human`, `validate_bone_map` — **dikkat:** `:35` `RIG_SPEC_CANON` ve `:171` notu: varyantın `rig_spec.json`'una oyunun KANONİK `paint_joints`'i kopyalanıyor, varyant iskeletinden ölçülmüyor = POSTMORTEM kök neden 1; Faz 1'de değişmeli); `config/bone_map.json` (53/53 eşleşti); `config/variants/male_medium.json`; `qa/perf_figure_crowd*.gd` (yalnız B yolu seçilirse); `tools/human_body_render.py` kamera/poz altyapısı.
**Terk edilen (diskte kalıyor):** `blender/render_passes.py` (14 kemik katmanı), `mesh/silhouette_mesh.py`, `mesh/json_to_tres.gd`, `qa/render_full_body_gait.gd`, `qa/render_slice_gait.gd`, `qa/_debug_*.gd`, `qa/_custom0_probe.gd`, `ASAMA*.md` (yanlış iddialar içeriyor: kayıt olarak durur), `tests/_proof_skin/`, `build/figures/` (394 MB, git dışı).
**Dokunulmayan, oyunda duran eski rijit sistem:** `data/assets/characters/wardrobe/*` (1,1 MB), `tools/wardrobe_*.py`, `tools/human_body_*.py`.
**Faz-0 ölçüm betikleri (yeni):** `qa/_measure_layer_bbox.gd`, `qa/_measure_screen_figure.gd`, `qa/memory_estimate.py`.

## 5. İki yolun karşılaştırması (bu gerçeklerle)

| Ölçüt | A: katmanlı kare render | B: mesh-deform |
|---|---|---|
| Sürekli girdiler (`motion`, `lean`, `seated`, `bulk`, boy ölçeği) | **Karşılamıyor:** kare listesi yalnız çevrim+duruş+ayna; geçiş/eğilme için ek set ya da yaklaşım gerekir (sorular `QUESTIONS.md`) | Hepsini doğrudan alır (aynı kemik açıları, `FigureRig` kodu çalışır) |
| IK / karışım | Sadece fazın fonksiyonu → pişirilebilir; `motion` 1-B karışım → ek genlik seti ya da çapraz geçiş | Çalışma anında |
| Kesik/delik/çıkık uzuv | Yapısı gereği yok (gerçek 3B kare) | Her eklemde mühendislik: önceki denemede ortaya çıkan 6 hata sınıfı (POSTMORTEM) |
| Performans (50 figür) | Figür başına 5 sprite; ihmal edilebilir | B yolu 14,1 ms ort./19,6 p99 (llvmpipe, **bütçe 16,7 ms'nin 0,84'ü**), C yolu **ölçülmedi**; kural: A<4 ms değil → C sığmalı → sığmıyorsa dur. B bu kuralda seçilebilir sonuç **değildi** (önceki oturum ihlal etti) |
| Bellek/disk | Büyük (56 MB–3 GB, varsayıma bağlı); Web'de indirme boyutu | Ihmal edilebilir (~1–5 MB) |
| Giysi oturması | 3B'de MPFB çözer, 2B'ye olduğu gibi gelir | 2B'de maske + ağırlık yeniden kurulur |
| Doğrulama | Ana test: katmanlar = tek parça render | 7 test türü + kâhin IoU (Ek) |
| Yeni sahibinin riski | Düşük-orta; bellek tavanı gerçek bir kısıt | Yüksek (önceki denemede başarısız) |
| Açık risk (iki yol da) | **Açı-yalnız aktarım:** `FigureRig` uyluk=kaval=120 birim; MPFB uyluk 109,9 / baldır 114,7 (REF px, önceki `rig_spec.json`, *yalnız karşılaştırma*) → aynı açılarla ayaklar yerden kopabilir/gömülebilir; kalça yüksekliği ayarı gerekir (sorusu `QUESTIONS.md`'de) | aynı |

## 6. Öneri

**A (katmanlı kare render), şu sınırlarla:** (1) önce 1×, 24–48 kare/çevrim, 2 varyant bütçesiyle başla; 2× ve 100 kare ancak gerçek giysi kutuları ölçülünce; (2) `motion`/`lean`/`seated` için politika kullanıcı kararı olarak (soruları QUESTIONS.md'de) — A'yı seçmek bu üçünü "yaklaşıkla" demek, "hiç oynatma" değil; (3) B'ye dönüş yolu açık kalsın: Faz 1 çıktısı (kare başına kemik açıları + eklem konumları JSON'u) iki yolun da ortak girdisi. Gerekçe sırası: kesik/delik sınıfı yapısal olarak ortadan kalkıyor; sürekli girdilerin hiçbiri çalışma anında IK/nişan/klip karışımı gerektirmiyor (Bölüm 1); B'nin bütçe kuralı kanıtsız. **Kullanıcı seçmeden Faz 1'e başlamıyorum.**
