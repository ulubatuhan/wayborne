# Aşama 2-3 — Render Pipeline + Siluetten 2B Mesh (tek katman kanıtı)

**Sonuç:** `male_medium` varyantının `forearm_front` katmanı için uçtan uca
hat çalışıyor - gerçek MPFB2 verisinden ağırlık haritası render'ı, siluetten
üçgenleme, BeastSkin export, ve **gerçek yürüyüş fazlarında** (motion=1.0,
tek bir pozda değil) Godot'ta doğrulandı. Tek açık madde: kapsama IoU 0,983,
hedef 0,99'un biraz altında - kök neden anlaşıldı, kullanıcı kararı bekliyor.

## Aşama 2: render pipeline

- **Motor uyarlaması (kılavuzla çelişen, belgelenen nokta):** kılavuz
  Workbench/FLAT/AA-kapalı istiyor; bu `bpy` 5.0.1 paketinde yalnızca CYCLES
  kayıtlı - Workbench/EEVEE gerçek bir GL bağlamı (`libEGL.so.1`) arıyor ve
  bu kum havuzunda yok (denendi, SIGABRT ile çöktü). Çözüm: CYCLES + bir
  Emission shader (vertex rengini **doğrudan**, hiçbir ışık/gölge katkısı
  olmadan yayan) + minimal piksel filtre genişliği (`filter_width=0.01`) -
  veri anlamı aynı (renk = öznitelik değeri, gölgelendirme yok), yalnızca bu
  ortamda çalışan motora uyarlandı.
- **Doğrulama (kılavuz 9.4'ün kendi testi, gerçekten koşturuldu):** `weights.exr`'nin
  3 kanalının toplamı, kapsanan **10.376 pikselin tamamında** 0,999999-1,000000
  aralığında (0,99-1,01 dışı: **0 piksel**). Triangle rasterleyicinin
  doğrusal enterpolasyonu gerçekten skinning'in kendi enterpolasyonuyla
  aynı - kılavuzun kendi iddiası, gerçek sayıyla doğrulandı.
- Kök maskesi (smoothstep) render'ı da aynı mekanizmayla üretildi.

## Aşama 3: siluetten mesh

- OpenCV kontur (`RETR_CCOMP`) + 2px dilate + Douglas-Peucker (1px tolerans,
  dışarı-taşma 0px) + eklem çevresi yoğunlaştırma + `triangle` kısıtlı
  Delaunay (`pq30a`).
- **368 vertex, 596 üçgen** (hedef aralık: katman başına 150-600 - üst
  sınırda ama içinde).
- **Ters dönmüş/dejenere üçgen: 0.**
- **Kapsama IoU: 0,983** (hedef ≥0,99 - **geçmiyor**).

### Bulunan ve düzeltilen gerçek bir hata (Aşama 3)

İlk gait render'ı mesh'i iğne gibi gerip dağıtıyordu (ekran görüntüsü arşivde).
Neden: `skin.json`'un `joint_names`'i yalnızca katmanın kendi iki ucunu
(`elbow_front`, `hand_front`) taşıyordu, ama `bone_names` 3 kemik içeriyordu
(`forearm_front`, `upper_arm_front`, `hand_front`) - `upper_arm_front`'un
`shoulder` ucu ve `hand_front`'un `fingers_front` ucu **hiç kaydedilmemişti**.
`BeastSkin.joint()` tanımsız bir isimde sessizce `(0,0)` döndürüyor - bu da o
kemiğe az da olsa ağırlıklı her vertex'i köke doğru geren yanlış bir dönüşüm
üretiyordu. Düzeltme: katmanın **kendi iki ucu değil**, `bones3`'ün
`FigureRig.BONES`'a göre ihtiyaç duyduğu **tüm** eklemler kaydediliyor artık.
Düzeltildikten sonra gait render'ı temiz çıktı (ekli görsel).

### Açık madde: kapsama IoU 0,983 vs 0,99 hedefi

Kök neden: `ROOT_THRESHOLD` (0,02) sınırı, orijinal 3B mesh'in üçgen
düzeyinde pürüzlü (zikzak) bir sınır üretiyor (`texture.png`'de görülebilir).
Bu sınırı 1px toleransla takip etmek ~1000 vertex gerektiriyor (denendi,
IoU 0,999'a çıktı ama 150-600 bütçesini ~2 kat aştı). `vertex_group_smooth`
(mesh kenar komşuluğuna göre ağırlık yumuşatma) denendi, IoU'yu iyileştirdi
(0,977→0,985 civarı) ama hedefi tam tutturmadı - raporlanan 0,983 bu
yapılandırmayla (smooth factor=0,5, repeat=4).

Kılavuzun kendi kuralı: **"Bir eşiği tutturamıyorsan eşiği gevşetme; sorunu
ve ölçülen değeri raporla."** Bu yüzden eşik değiştirilmedi - iki seçenek
kullanıcıya sunuluyor:
1. Eşiği (0,99→~0,98) bu **kök-genişletme sınırları** için gevşet - gerçek
   silüet kenarında (giysinin/derinin dış hattı) hâlâ 0,99+ bekleniyor,
   yalnızca komşu katmanla zaten örtüşen (kılavuz 9.2 - "kasıtlı, boşluk
   oluşmasını engelleyen mekanizma") iç sınırda gevşet.
2. Kök sınırını Blender'da daha agresif yumuşat (ör. `repeat=10+`) ve
   vertex bütçesini biraz aşmayı kabul et.

## Görsel kanıt

`build/figures/variants/male_medium/layers/forearm_front/`:
`texture.png` (doku), `weights.exr`/`root_mask.exr` (veri), `skin.json`/`.tres`
(mesh), `mesh_test_report.json`. Gait kanıtı: gönderilen `slice_gait.png` -
**gerçek yürüyüş fazlarında** (FigureRig.pose, motion=1.0 - paint pozunun
kendisi değil), 4 fazda, kopukluk/boşluk/ters dönme yok.
