# Dünya haritası araçları

Wayborne dünya haritasının (v3, 16012×16013 px) üretim hattı. `xx/Harita_Calismasi/kod/`'dan alındı (görev 8.9); betiklerdeki mutlak yollar
göreli yapıldı, referans oyunun adı ve küçük köy türünün eski adı temizlendi (`kcd` klasörü `zemin` oldu, tür `ih_mezra`).

| Klasör | Ne |
|---|---|
| `atlas/` | Yer listeleri (`places_v3.json` güncel), adlar, bölge verisi |
| `cm/` | Harita çizimi: yerleşim, dağ, yol, işaret (`rider_marker.py`), GeoJSON dışa aktarımı (`geo_export.py`) |
| `zemin/` | Zemin, ağaç, su, bulut, yol ve yerleşim yerleşimi; `vg_*` parçalı tam boy render |
| `mapview/` | Karo piramidi (`make_tiles.py`) ve tarayıcı görüntüleyici |

Büyük ara veriler (`fields.npz` vb.) **depoda yok**: `xx/Harita_Calismasi/` altında. Betikler yolları argüman ya da ortam değişkeni
(`CM_FIELDS`, `CM_BASEMAP`, `CM_DEM`, `ZEMIN_LAYOUT`, `ZEMIN_WORLD`, `CM_DEBUG_DIR` ...) olarak alır. Bağımlılıklar: numpy, scipy, opencv,
pillow. Kâğıt dokusu `art_source/textures/ambientcg/Paper005` yolundan depo köküne göre okunur.

**Baştan sona koşturma (2026-10-20, görev 8.9):** `bash tools/worldmap/run_all.sh <girdi kökü> <çıktı klasörü>`. Girdi kökü
`Harita_Calismasi/_replay/scratchpad/kcd` (eski pakette yol dosyası `out/world_kcd.json`; betik `world_zemin.json` adını
bekliyor, kopyalayıp yeniden adlandırın). Süre bu makinede ~30 dk (alanlar 2,5 dk, sahne ve yollar ~3 dk, 16 karo ~20 dk).
Çıktı `Harita_Calismasi/rerun_1020/full/` ile `cikti/v3_final/` karşılaştırıldı (4096 px, ortalama piksel farkı 10,8):
kıyı, göl, dağ simgeleri, orman, kent ve adlar aynı yerde. Kalan iki fark: (1) son haritada alanların `roads` katmanı
elle, uzun su geçişleri kesilmiş bir sürümle değiştirilmişti; bu adım kodda yok, o yüzden kervan yolunun kalın çizgisi
ve birkaç yol parçası eksik çıkıyor; (2) birkaç kentin ayak izi (Rivecande, Dravoss) biraz farklı çiziliyor. İlk koşu
`CM_PEAKS=1 CM_RELIEF=0` olmadan yapıldı ve dağlar koyu kabartma lekesi olarak çıktı; betik bunları artık kendisi veriyor.
