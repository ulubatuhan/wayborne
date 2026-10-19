# Ortak mürekkep geçişi (Y-G02): öneri ve deneme

Araç: `tools/npr/ink_pass.py`. Dört adım, sırasıyla:
1. Üç ton: gölge, orta ve ışık, yumuşak eşikle.
2. Tarama: gölgede 45°, en koyuda çapraz.
3. Kontur: siluet kalın, iç çizgi ince, `INK` rengi.
4. Kâğıt dokusu: Paper005.

Deterministik; oyun varlıklarına **onaydan sonra** uygulanır.

Karşılaştırma görüntüsü (solda bugün, sağda geçiş): `TODO/kontrol_goruntuleri/12_npr_onerisi.jpg`, ana dosya dizininde.
Görüntüde sırasıyla:
- erkek bedenin atlas sayfasından bir parça;
- kurdun atlas sayfasından bir parça;
- brandalı vagonun katmanları;
- orman yolunun orta katmanı.

## Bulgular

| Hat | Sonuç | Öneri |
|---|---|---|
| Sahne nesneleri (vagon, araba, bina) | Kontur net, tarama hafif, kâğıt dokusu ton birliği veriyor | Paketlemede uygula (`PropArt` paketleyicisi) |
| Yol, orta ve zemin katmanı | Ağaç ve otta kontur okunur, render'ın kendi mürekkebiyle uyumlu | `road_post.py`'de mevcut mürekkebin yerine bu modül |
| Yol, uzak katman | Kuralla çelişir: mürekkep yalnızca kervanın düzleminde (STIL_REHBERI, Rendered Road Rules) | Uygulama |
| Kasaba arka planları | `town_post.py` zaten eşdeğerini yapıyor (Sobel, kâğıt, kir) | Ortak modüle taşı, eşikleri birleştir; görünüş neredeyse aynı kalır |
| İnsan ve hayvan kareleri | Figür beş katmandan (uzak kol, uzak bacak, gövde, yakın bacak, yakın kol) birleşiyor. Katman başına kontur, katman sınırında iç çizgi üretir: omuzda ve kalçada dikiş | Katman başına kontur **yok**. Paketlemede kare başına birleşik siluetten dışa doğru tek bir **kontur katmanı** üret, en arkada çiz. Üç ton ve tarama katman başına uygulanabilir |

## Sonraki adım (onaydan sonra)

1. `tools/npr/ink_pass.py`'yi `PropArt`, `road_post.py`, `town_post.py` ve figür paketleyicilerine (`pack_frames.py`,
   `pack_outfits.py`, `pack_beasts.py`) bağla. Figürlerde yalnızca ton ve tarama katman başına; siluet konturu ayrı katman.
2. `BodyFrames`'e kontur katmanı (`KIND_OUTLINE`) ve `WalkFigure._draw_person_frames`'e onu ilk çizen satır.
3. Bütün varlıkları yeniden paketle (render gerekmez; paketleme görüntü üstünde çalışır), ekran görüntüsüyle karşılaştır.

Maliyet: paketleme birkaç saat (Blender gerekmez); ekran doğrulaması akşam testinde.
