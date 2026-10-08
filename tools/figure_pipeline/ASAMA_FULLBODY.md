# Tam vücut genişletme — bulgular ve düzeltmeler

Kullanıcının "tam bir vücut üret, tüm hareketlerini göster" isteği üzerine
`forearm_front` tek katmanından 14 kemiğin tamamına genişletildi
(torso, head, upper/forearm/hand × front/back, thigh/shin/foot × front/back).

## 1. Gerçek, zum'lanarak doğrulanan boşluk (kullanıcının sorusu) — düzeltildi

`slice_gait.png`'i 4× büyütünce dirsek/bilekte arka plan grisi mesh içinden
görünüyordu — ASAMA3.md'nin zaten kaydettiği 0,9845 IoU açığının görsel
karşılığı. `SIMPLIFY_EPS_PX` 1,0 → 0,5: forearm_front'ta IoU 0,9845 → 0,9911.
Tüm 14 katmana uygulandı, hepsi ≥0,99 IoU ile geçti (torso 0,998, el hariç
hepsi 0,99-0,998 arası).

## 2. Segfault: el katmanlarında `triangle.triangulate()` çöküyordu

Kök neden: Cycles'in 1-sample FLAT render'ı sınırda 1-2 piksellik
dithering/AA gürültüsü bırakıyor, bu da `cv2.findContours`'ta 2-4 pikselik
sahte "delik" olarak görünüyor (el başına 12 tane ölçüldü). Bu kadar küçük,
neredeyse çakışık noktalı bir delik `triangle` kütüphanesini segfault'a
düşürüyordu (faulthandler ile doğrulandı: çökme `tr.triangulate()` içinde).
Düzeltme: `MIN_HOLE_AREA_PX=12` altındaki delikler PSLG'ye hiç girmiyor.
Eller ayrıca ince parmaklar yüzünden eps=0,5'te IoU hedefini tutturamadı,
eps=0,35'e düşürüldü (hand_front IoU 0,995, hand_back 0,999).

## 3. Gerçek, ciddi bug: "şekerleme kağıdı" (candy-wrapper) gerilme — düzeltildi

Tam vücut ilk render'ında kollarda/bacaklarda uzun "fırça izi" gerilmeler
çıktı. Kök neden ölçülerek bulundu (`_debug_thigh2.gd`): bir katmanın kök-
genişleme bölgesindeki bazı vertex'ler, FARKLI açılarda dönen iki komşu
kemiğe (örn. thigh_back dönerken torso sabit, ya da shin_back çok farklı
açıda) gerçek, anlamlı ağırlık taşıyordu (ölçüldü: bir vertex %99,8 torso
ağırlıklıyken geometrik olarak uyluğun parçasıydı). Torso/shin_back
dönmezken/farklı dönerken, bu vertex komşularından kopup gerildi.

İlk deneme (MIN_CORE_SHARE=0,6 tavanı) yetmedi — en kötü vertex'te hâlâ
32px kayma vardı (REF_H=512'nin ~%6'sı). MIN_CORE_SHARE=1,0 (tam rijit,
komşu kemik ağırlığı sıfıra iniyor) ile thigh_back'te hata tamamen gitti,
tüm fazlarda doğrulandı. Bu, oyunun kendi FigureRig sisteminin zaten
kullandığı yöntemle aynı ("a part is painted once... pivot bone'un ilk
ekleminde" — rijit, karışımsız). BeastRig'in yumuşak karışımı tek sürekli
deri için güvenli; burada her katman ayrı mesh/doku olduğu için örtüşme
(seam gap'i önleyen) zaten geometrik, deformasyonun yumuşak olmasına
gerek yok.

Tüm 14 katman bu düzeltmeyle yeniden üretildi, tam vücut sweep'i temiz.

## 4. Kalan, anlaşılan ama henüz çözülmemiş

- **Omuzda koyu leke**: `head` katmanının kendi `texture.png`'sinde zaten
  var (boyun/omuz kökü sınırında bir yüzey, ışığa ters açıdan bakıyor).
  Piksel örneklemesiyle doğrulandı: arka plan rengiyle eşleşmiyor (gerçek
  delik değil), yalnızca gri yer tutucu malzemenin ışıklandırma hatası.
  Gerçek boyanmış dokularla değişecek ama ışık kurulumu (`human_body_
  render.py setup_scene`) iyileştirilebilir.
- Torso/kalça sınırında hâlâ hafif tırtıklı kenarlar (IoU %99,8, görünür
  kalan %0,2).
- Hand katmanları vertex bütçesini (150-600) aşıyor (1322/1143) - ince
  parmaklar için eps düşürmenin bedeli, ASAMA3.md'nin aynı tradeoff'u.
- Yalnızca `male_medium` varyantı işlendi; `female_medium` aynı pipeline'dan
  geçmedi.

## Dosyalar

`tools/figure_pipeline/mesh/silhouette_mesh.py` (MIN_HOLE_AREA_PX,
MIN_CORE_SHARE=1.0, eps=0.5 eklendi), `tools/figure_pipeline/blender/
render_passes.py` (LAYER_BONES 14 kemiğe genişletildi),
`tools/figure_pipeline/qa/render_full_body_gait.gd` (yeni - 14 katmanlı
kompozit renderer), `build/figures/variants/male_medium/full_body_gait.png`
(kanıt, kullanıcıya gönderildi).
