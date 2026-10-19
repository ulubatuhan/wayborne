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

**Bilinen eksik:** hattın baştan sona yeniden koşturulması denenmedi; yalnızca derleme (`py_compile`) ve yol taraması yapıldı. Çıktı
`xx/TODO/harita_final/` ve `Harita_Calismasi/cikti/v3_final/` altında.
