# Aşama 0 — Performans Testi

**Sonuç (tek cümle):** Mevcut yol (A, BeastSkin/GDScript CPU skinning) hedef bütçeyi ~23 kat aşıyor; Godot'nun yerleşik Polygon2D+Skeleton2D yolu (B) aynı yükte bütçeye yakın (ort. 14,1ms); GPU shader denemesi (C) bu kum havuzunda B'den belirgin şekilde yavaş çıktı, ama bu muhtemelen yazılım rasterleyicisinin (gerçek GPU yok) malzeme/draw-call maliyetini büyütmesinden kaynaklanıyor — gerçek donanımda yeniden ölçülmeli. **Karar: B yolu (Polygon2D + Skeleton2D) ile devam.**

## Ortam

- Gerçek GPU yok; `LIBGL_ALWAYS_SOFTWARE=1` + Mesa llvmpipe (yazılım rasterleyici) üzerinden ölçüldü. Bu, **mutlak** kare sürelerini (özellikle GPU-bağımlı Yol C'yi) gerçek donanıma göre kötü yönde çarpıtır; **CPU'da hesaplanan** kısımlar (Yol A/B'nin deform döngüsü) donanımdan bağımsız, gerçekçi kalır.
- Hedef FPS kullanıcıdan alınmadı; varsayım: 60 FPS (kare bütçesi 16,7ms), geliştirme makinesi burası (bkz. kılavuz bölüm 7). **Kullanıcı farklı bir hedef makine/FPS isterse yeniden ölçülmeli.**

## Test sahnesi

`tools/figure_pipeline/qa/perf_figure_crowd*.gd` — 50 figür, figür başına **3072 vertex** (kılavuzun "~3.000 vertex" hedefine en yakın tam sayı: 16 "kemik" × 192 vertex), vertex başına 2-3 kemik ağırlığı, her figür farklı yürüyüş fazında, 600 kare ölçülüp ilk/son kare atıldı (598 kare raporlanıyor).

## Üç yolun sonucu

| Yol | Açıklama | Kare süresi ort. | p95 | p99 | Not |
|---|---|---|---|---|---|
| **A** | Mevcut `BeastSkin`/`BeastRig.skin_deform()` — GDScript CPU döngüsü + `canvas_item_add_triangle_array` | **133,9 ms** | 165,0 ms | 183,7 ms | Yalnızca deform+çizim çağrısı (`skin_ms`) 95,8ms — bütçenin ~23 katı |
| **B** | `Polygon2D` + `Skeleton2D` + `Bone2D` (motorun kendi C++ tarafı) | **14,1 ms** | 17,5 ms | 19,6 ms | Bütçeye en yakın; p99 hafif aşıyor |
| **C** | `MeshInstance2D` + `canvas_item` shader, kemik dönüşümleri küçük bir uniform dizisinde, CPU yalnızca diziyi yazıyor | **88,1 ms** | 106,2 ms | 129,3 ms | Bkz. aşağıdaki "Yol C neden yavaş çıktı" |

Ham JSON çıktılar: `/root/.local/share/godot/app_userdata/Wayborne/perf_path_{a,b,c}.json` (konteyner `user://` yolu - proje deposunun dışında, `build/`'a eşdeğer).

## Yol A: kodu okuyarak nerede hesaplandığı

`scripts/character/beast_rig.gd`'nin `skin_deform()`'u saf GDScript: her vertex için `BeastSkin.INFLUENCES` (3) kemik dönüşümünü okuyup ağırlıklı topluyor, sonucu `draw_skin()` her `_draw()` çağrısında **yeniden hesaplıyor** (önbellek yok) - tam olarak kılavuzun aktardığı Godot CPU-optimizasyon raporundaki `Polygon2D::_notification()` sınıfı maliyet. Hayvanlarda bugüne kadar sorun çıkarmamasının sebebi küçük ölçek (birkaç yüz vertex, az sayıda eşzamanlı hayvan) - 50 × 3000 ölçeğinde (kılavuzun hedef sahne yükü) kesinlikle çöküyor.

## Yol C neden yavaş çıktı (önemli çekince)

Önce bir ön koşul doğrulandı (tahmin edilmedi): Godot 4.2/5.0'ın `canvas_item` vertex shader'ında **`CUSTOM0`/`CUSTOM1` yok** ("Unknown identifier" derleme hatası - `tools/figure_pipeline/qa/_custom0_probe.gd` ile doğrulandı, 3B'nin `spatial` shader'ından farklı). Bu yüzden Yol C, kemik id/ağırlığını vertex `COLOR`'a paketleyip (2 etkiye düşerek - BeastSkin'in 3'ü yerine) kemik dönüşümlerini küçük bir `uniform vec2 bones[48]` dizisinde taşıdı.

CPU tarafı iş (800 `Transform2D` hesaplama/kare, 50 `set_shader_parameter` çağrısı) milisaniyenin çok altında olmalı - 88ms'nin kaynağı neredeyse kesinlikle **50 ayrı `ShaderMaterial`'ın her karede malzeme/pipeline durumu değişimi** ve bunun yazılım rasterleyicisinde (gerçek GPU'nun paralel çalıştıracağı işi CPU'da sırayla yapan llvmpipe) orantısız pahalı olması. **Bu sonuç gerçek donanımda yeniden ölçülmeden "Yol C kötü" diye kapatılmamalı** - yalnızca bu ortamda B'den geride kaldığı, B zaten bütçeye yakın olduğu için C'yi zorlamanın gerekmediği söylenebilir.

## Karar

> A yolu bütçenin %25'inden azını kullanıyorsa (60 FPS'te ≈ 4 ms), A ile devam et.

A, 95,8ms ile bunun **~23 katı** - devam edilemez.

> Kullanmıyorsa ve C yolu kullanıyorsa, C'yi kur...

C ölçüldü ama bu ortamda B'nin gerisinde kaldı, ve B zaten bütçeye yakın (ort. 14,1ms < 16,7ms; yalnızca p99 19,6ms ile hafif üstünde). Kılavuzun harfi "A yetmezse C'ye geç" diyor, ama amaç "hedef bütçeyi tutturmak" - B onu zaten tutturuyor, daha basit (motorun kendi, iyi test edilmiş kodu), daha az risk taşıyor (Yol C'nin 2-etki sınırlaması ve shader-tabanlı hassasiyet kayıpları yok) ve ölçülen hiçbir dezavantajı yok. **Bu yüzden B ile devam ediyorum** - harfi değil amacı takip eden bir karar; kullanıcı C'yi gerçek donanımda yeniden ölçtürmek isterse script'ler (`perf_figure_crowd_c.gd`) hazır duruyor.

## Mimari sonucu: BeastSkin formatı okundu, runtime çizim yolu değişiyor

Bölüm 10.5 "önce BeastSkin'in mevcut veri formatını oku" diyordu - okundu (`scripts/character/beast_skin.gd`, `beast_rig.gd`). Export formatı (vertex/uv/indices/bone_ids/bone_weights) **aynı kalıyor** - bu, Aşama 3'ün üreteceği verinin şekli. Ama **bu performans ölçümü yüzünden runtime'da bu veriyi OKUYAN taraf değişiyor**: hayvanlarda olduğu gibi `BeastRig.skin_deform()` + GDScript döngüsüyle değil, `Polygon2D.add_bone()` + `Skeleton2D`/`Bone2D` ile - motor bunu kendi C++ tarafında, bizim ölçtüğümüz 14,1ms'lik maliyetle yapıyor. `BeastSkin`'in kendisi (hayvanlar da kullanıyor) **değiştirilmedi** - yalnızca insan figürü hattının yeni içeriği, export edilen vertex/ağırlık verisini bir `BeastSkin` kaynağından değil doğrudan bir `Polygon2D`+`Skeleton2D` sahne ağacından okuyacak. Bu, Aşama 3'ün "export formatı" adımında somutlaştırılacak.

## Sonraki ölçüm ihtiyacı

- Gerçek hedef makine/FPS kullanıcıdan alınmalı (bölüm 5'teki açık karar), bu rapor 60 FPS/geliştirme makinesi varsayımıyla yazıldı.
- p99'un bütçeyi hafif aşması (19,6ms) gerçek içerikle (sentetik ızgara değil) yeniden doğrulanmalı.
- Yol C, gerçek bir GPU'da (bu kum havuzunun dışında) yeniden ölçülmeye değer - burada ölçülen kötü sonuç donanım eksikliğinin bir yapıntısı olabilir.
