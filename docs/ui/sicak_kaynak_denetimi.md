# Tek sıcak kaynak denetimi (görev Y-G17)

Kural (`kurallar-sanat`, Art Rules): dünyada sıcak renk yalnızca bir ışık kaynağından gelir (ateş, fener, meşale,
pencere ışığı, defter sayfası). Gök, zemin, bina, giysi ve sahne dokusu soğuk ve soluk kalır. Arayüzün okunaklılığı
kuralın dışında.

## Ölçüm (2026-10-31)

Ölçü: bir resimde doygun sıcak piksellerin payı (ton kırmızıdan sarıya, doygunluk > 0,35, parlaklık > 0,45).
Şehir önü resimleri, 27 yerleşim:

| resim | ortanca | en yüksek |
|---|---|---|
| sabah | %0,1 | %5,2 |
| gündüz | %0,3 | %0,4 |
| akşam | %10,2 | %25,3 (Orbeyan) |
| gece (`background`) | %0,1 | %13,8 |

Gündüz ve sabah resimleri kurala uyuyor. **Akşam resimleri uymuyor:** akşam ışığı bütün sahneyi turuncuya
boyuyor; sıcaklık ışık kaynağından değil gökyüzünden geliyor. Yolun render edilmiş katmanları nötr gün ışığında,
kurala uyuyor (ışık oyunda çarpılıyor).

Koddaki doygun sıcak renklerin çoğu ışık kaynağı: kamp ateşi (`RoadCaravan`), fener ve meşale
(`road_journey.gd`), taverna ateşi (`TavernRoom`), kervansarayın kapı feneri (`TravelBand._draw_serai`). Bunlar
kurala uygun.

## Aykırılar ve düzeltme sırası

1. **Akşam şehir resimleri** (`town_post.py` akşam derecelendirmesi). Akşam ışığı sahneyi turuncuya boyamasın;
   sıcaklık pencerelere, meşalelere ve fenerlere çekilsin. En ağır olanlar: Orbeyan, Caramine, Mirsana, Auderin,
   Akavan, Selvicar. Render yeniden gerekir.
2. **Yolun gökyüzü şafak ve alacakaranlıkta** (`ArtPalette` evreleri, `TravelBand.sky_for_hour`). Ufuk bandı ve
   güneşin halesi sıcak; güneş bir ışık kaynağı olduğu için halesi kalabilir, ama gökyüzünün bütünü soğuk kalmalı.
   Karar gerekiyor: güneşi ışık kaynağı sayıyor muyuz?
3. **Gece resimleri**: bazılarında (%13,8'e kadar) sıcaklık bir pencereden değil göğün alt bandından geliyor;
   tek tek bakılacak.
4. **Giysi renkleri** (`OutfitCatalog`): deri ve yün tonları sıcak ama soluk; doygunluğu düşük olanlar kurala uyuyor.
   Kırmızı şalvar gibi doygun parçalar (`harem_pants`) soluklaştırılabilir.
5. **Arayüz altın ve kan rengi** (`ArtPalette.GOLD`, `BLOOD`, uyarı rengi): kuralın dışında, dokunulmaz.

Her düzeltme ekran görüntüsüyle önce ve sonra gösterilir (`ekran-dogrula`).
