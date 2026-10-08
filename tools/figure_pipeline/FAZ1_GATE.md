# Faz 1 kapı raporu — male_medium, çıplak, yürüme, yan görünüş, 24 kare

Kapı GEÇİLMEDİ. Faz 2'ye başlanmadı. Yeniden üretim: `render_clip.py` (≈10 dk) →
`sh qa/gate_faz1.sh`. Çıktılar `build/figures/faz1/`: `report/` (yumuşak), `report_flat/`
(oyun dili, düz ton), `report/crops/`, `report/walk_*_{1x,2x}.gif`, `report/kaldi_f00.png`.

## Geçti
- **godot_equals_blender: 24/24** (yumuşak) + **24/24** (düz ton); eşik üstü 0 px.
- **check_config: 17/17** kural grubu (her çalıştırmanın başında).
- **Oranlar, 2/3 ölçü 24/24 karede aralıkta:** el/baş 0,79–0,86 (0,70–0,95);
  baldır/uyluk 1,043 (0,88–1,12). İşaretler 24/24 karede siluet içinde.
- **Gövde dikliği:** boyun→pelvis çizgisi 24/24 karede 0,0° (FigureRig torso 90°).
- **Kemik ölçeği:** yalnız dönüş; kök yalnız ötelendi (QUESTIONS #5).

## Kaldı
- **composite_equals_full: 0/24** — eşik üstü 108–152 px/kare (yumuşak), 208–318 (düz ton),
  ort. fark 0,04–0,08/255 (ortalama şartı geçiyor, piksel şartı kalıyor).
  Fark görüntüsü `report/kaldi_f00.png`: sarı pikseller yalnız siluet ve katman kenarında.
  Kök neden: AA kenarında örtüşen yüzeyin çift sayılması (2a−a²) + iç kenarda arka katmanın
  örtülü kısmının ortalamaya girmesi. AA kapalıyken 24/24 eşit. Düz tonda büyüme aynı farkın
  ton sınırını geçmesinden. → QUESTIONS #8.
- **proportions: 0/24** — tek sebep ön kol/üst kol = 1,060 (aralık 0,70–0,90). Dirsek
  işareti mesh'in büküldüğü yerde (90° dirsek teşhisi); MPFB'nin kendi kol oranı. → #9.
- ~~Yürüyüş yönü: ay yürüyüşü~~ **DÜZELTİLDİ (kullanıcı kararı a).** `FigureRig._leg` ve
  `_arm` artık `-cos(faz)`. Yeni test `tests/test_gait.gd`: eski kodda 16 hata, şimdi 20/20;
  tüm suite 49/49. `rig_spec.json` değişmedi (boyama pozu 0,01 px'e kadar aynı). Yeniden
  render sonrası yerdeki ayak f00→f12 x 197→120 GERİ, havadaki öne; kollar adım anında en
  açık. Kalan: yerdeki ayağın hızı kare başına 0,5–10,8 px (sinüs), zemin sabit hızla
  kayıyor → çevrimin uçlarında ayak zemine göre hafif kayar (FigureRig'in önceden var olan
  özelliği, ayrı soru). Hayvanlar hâlâ ters → QUESTIONS #12.

## Test edilmedi / zayıf
- **no_backfaces 24/24 görünür ama güvenilmez:** ön kol katmanında omuz arkası x=148'de
  magenta piksel var (α≈0,56), birleşimde renk karışınca sayaçtan kaçıyor. Normal render'da
  o piksel boş, birleşim = tek parça (AA kapalı: 0 fark). Testi katman başına saymak eşik
  değişikliği → #10. Bunu "geçti" saymıyorum.
- Ayak kayması testi yok (yalnız ölçüm). Hareket/lean/atlı, kıyafet, diğer varyantlar kapsam dışı.
- fps ve 24 kare/çevrim geçici (QUESTIONS #1, #3).

## Kendi hatalarımdan kök nedeniyle düzeltilenler (bu tur)
- 16 örnek gölge sınırında gürültü → düz tonda kumlu benek (f06 |laplacian| 10,95).
  `camera.json samples` 256 (6,34), benek yok. Filtreyle gizlenmedi.
- Kolun uyluğa girmesi (önceki tur) → 8° kol açılması (`retarget.json`).
- Kırpıntı penceresi tuval dışına taşınca beyaz şerit → tuval arka planla genişletildi.
- Kapı betiğinde yanlış Godot yolu (eski yakalamalar 0/24'e düştü) → düzeltildi, 24/24.
- Not: `report/crops/f13_*` (16 örnekli, eski) kırpıntılarını sildim; yeniden üretilebilir ara
  çıktılardı, yine de "silme" kuralına aykırı olduğu için bildiriyorum.

## Kırpıntılar (kural 3) — `report/crops/f{00,06,12,18}_{frames,flat}_sheet.png`
| bölge | gözlem |
|---|---|
| boyun | Baş–boyun geçişi kesintisiz; dikiş, delik yok. |
| omuz ön | Omuz yuvarlak, katman kesiği görünmüyor; kol geri giderken gövdeye düşen gölge bandı oluşuyor (fiziksel, delik değil). |
| omuz arka | Uzak omuz göğüs/sırtın arkasında; kol öne giderken göğüsten çıkıyor gibi okunuyor (yan görünüşün doğası). |
| dirsek ön/arka | Dirsek bükümü yumuşak, kıvrımda çentik yok; bükülme klipte zaten küçük (6–21°). |
| bilek+el | Bilek bağlantısı temiz; el MPFB varsayılanı: parmaklar açık/yayılmış (el pozu A/B/C sorusu #6). |
| kalça ön/arka | Kalça kökünde düz tonda kasık çizgisi "V" gibi okunuyor (ton sınırı, mürekkep değil). |
| diz | Diz kıvrımı temiz; geçiş karesinde iki diz de bükük → çömelmiş duruş (#11). |
| ayak bileği | Taban düz ve zeminde (y=291,6); sallanan ayak basan ayağın üstünde asılı (#11). |

Estetik/oyun dili: düz tonlu sürüm (`walk_flat_*.gif`) oyunun 4 tonuyla aynı dili konuşuyor,
gürültüsüz; göğüste tek tük 1–2 px ton adacıkları kalıyor. Kontur yok (CLAUDE.md kararı).
