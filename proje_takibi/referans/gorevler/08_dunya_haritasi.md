# §8. Dünya haritası

> Bu dosya `../YAPILACAKLAR.md` dizininin bir bölümü. Görev kimlikleri (ör. **8.2**, **12.2c**, **R0**) ve § başvuruları dizindekiyle aynı. Kurallar: `00_kurallar.md`. Başlamadan önce: `../00_BASLA_BURADAN.md`.

Ayrıntılı geçmiş: `../belgeler/HARITA_GECMISI.md`.

### Durum (2026-10-17): v3 kullanıcı onaylı son hâl

Sürümler:
1. **v1:** Bulut oturumunda yarım kalan render yerelde baştan kuruldu ve çizildi.
2. **v2:** Kullanıcının `d.docx` talepleri uygulandı.
3. **v3:** İkinci tur düzeltmeler işlendi ve kullanıcı onayladı. **Son hâl bu.**

**Son harita: `../harita_final/`.** Ayrıntılar `../harita_final/BENIOKU.md` içinde.
- `goruntuleyici/index.html`: tam kalite, yakınlaştırılabilir görüntüleyici. Ada göre arama, kervan işareti, konum gösterimi var.
- `wayborne_harita.geojson`: haritadaki tüm varlıklar.
  - Toplam 1224 özellik.
  - 123 yerleşim, 3 kervansaray, 177 yol parçası, 330 yol düğümü.
  - Su, kara, orman, dağ ve kültür bölgesi çokgenleri; etiketler.
- `isaret_atli/`: oyuncu işareti; at ve binici, 8 yön.

**Tam çözünürlüklü görüntü:** `xx/Harita_Calismasi/cikti/v3_final/map_16384.png` (16012×16013 px, 181 MB) ve `.jpg`.

**Ara sürümler:** `cikti/v1_ilk_render/`, `cikti/v2_duzenlemeler/`.

**Diğer dosyalar** (`xx/Harita_Calismasi/` altında):
- `kod/`: kod kopyası (`cm/`, `kcd/`, `atlas/`, `mapview/`). Yeni betikler `cm/` içinde: `edit_fields.py`, `geo_export.py`, `marker.py`, `make_viewer.py`.
- `_replay/scratchpad/`: çalışan ortam ve ara veriler.
  - Düzenlemeden önceki kod: `cm/code_v1_yedek/`.
  - Düzenlemeden önceki sahne: `cm/full_v1/`.

**v1'de uygulananlar (önceki oturumun son istekleri):**
- yollar tek çizgi,
- parşömen kenarı yok,
- alttaki "Wayborne" yazısı ve kartuşu yok,
- su koyu kurşuni tonda,
- kar yalnız kuzeybatıda ve mürekkep tarzında.

**v2'de uygulananlar (`d.docx`; görseller `../referanslar/harita_duzenleme_d_docx/gorseller/image1–11.png`):**

| # | Talep | Yapılan | Kod |
|---|---|---|---|
| image1–4 | Çift, bozuk, bağlanmamış yollar | Yollar artık piksel taramasından değil, vektör kaynaktan (`world_kcd.json`) kuruluyor. Su üstündeki parçalar kesiliyor, 13 px'ten yakın paralel izler tek orta çizgiye iniyor, yerleşime varmayan çıkmaz uçlar budanıyor. | `cm_full.py` `vector_roads()`, komut `vroads` |
| — | Ana yollar biraz kalın, patikalar aynı | Ana yol (`c == "road"`) ve kervan yolu 1 px kalınlaştırıldı. Yeni dosya: `roads_main.npy`. | `_road_raster()` |
| image5 | Reskel suya taşmış | Suya taşan 11 kıyı yerleşimi kıyıdan 22–30 px içeri alındı. Kentler kapsam dışı; şekillerini zaten araziden alıyorlar. | `edit_fields.py` → `atlas/places_v3.json` |
| image6 | Pusula ve deniz yolu | Pusula çizilmiyor. Denizden geçen yollar vektör kesimiyle kalktı. | `render()` içinde `_furniture` kaldırıldı |
| image7 | İnce şerit adalar | Vorgat doğusundaki 3 ada kaldırıldı (kutu x 3960–4096, y 1880–2360; 4096 ızgarası). | `edit_fields.py` |
| image8 | Denizde yol | Kalktı (image6 ile aynı çözüm). | `vector_roads()` |
| image9 | Göçebe bölgesinde kervansaray | Tarvessa ve Ombrakal kaldırıldı. Kalanlar: Orbeyan, Duvenmor, Seyvan. Kural: en yakın yerleşimin kültürü `gocebe` ise kervansaray konmuyor. | `prep()` |
| image10 | Kırmızı çerçevenin dışı kalksın | Birleştirmede kenar bandı kırpılıyor: sol %1,14, üst %1,01, sağ %1,14, alt %1,26. | `stitch()` |
| image11 | Göl denize açılan boğaz olsun | Kesgrav doğusundaki koy, en dar yerinden doğu denizine açıldı (kara şeridi 160 px, boğaz yaklaşık 64 px). | `edit_fields.py` → `fields_v2.npz` |

**v3'te uygulananlar (sohbette verilen ikinci tur):**

| Talep | Yapılan | Kod |
|---|---|---|
| Göz ya da halka biçimli kavşaklar istenmiyor (Ontinara Tower, Brazdun çevresi) | Birleşen iki iz arasında kalan küçük kapalı boşluklar (30.000 px²'ye kadar), iskelet çıkarılmadan önce dolduruluyor. Kavşaklar tek çizgi. | `vector_roads()` içinde `remove_small_holes` |
| Kuzeybatı ormanı (Dornak–Zurek–Taragun) doğal değil | Kaynakta kusursuz bir elips ve düz bir blok vardı. Alan bükülüp çok ölçekli gürültüyle eşiklendi: düzensiz kenar, iç açıklıklar, dağınık kümeler. Yalnız bu bölge (4096 ızgarasında x, y < 1050) değişti; 1350'ye kadar yumuşak geçiş var. | `edit_fields.py` adım 4 |
| Doğal köprü kalksın, yalnız boğaz kalsın | Köprü çizilmiyor ve su tonundan muafiyeti de kalktı. Boğaz açık. | Render'da `CM_ARCH=` boş verilir. `_arch()` kodu duruyor ama veri verilmezse hiçbir şey çizmiyor. |

**Komut sırası** (`_replay/scratchpad/cm` içinden):
- Ortam değişkenleri: `CM_FIELDS=../kcd/out/vgf/fields_v2.npz`, `CM_ARCH=` (boş), `REPLAY_ALLOW_HEAVY=1`.
- Ön adım (yalnız arazi ve yer düzenlenince): `python3 -I code/edit_fields.py ../kcd/out/vgf/fields.npz ../atlas/places.json ../kcd/out/vgf/fields_v2.npz ../atlas/places_v3.json full`

1. `prep $CM_FIELDS ../atlas/places_v3.json ../kcd/out/layout_v3.json full`
2. `finalize full`
3. `vroads full ../kcd/out/world_kcd.json`
4. 16 karo: `tile full <x> <y>`, ortam değişkenleri `CM_OUT=2 CM_PEAKS=1 CM_RELIEF=0`
5. `stitch full`
6. `python code/geo_export.py full $CM_FIELDS ../atlas/places_v3.json ../atlas/names full/wayborne_harita.geojson`
7. `python code/marker.py full/isaret` (pycairo kullanıcı paketinde olduğu için `-I` olmadan)
8. `python code/make_viewer.py full/map_16384.png full/wayborne_harita.geojson full/isaret <çıktı klasörü>`

Toplam süre bu makinede yaklaşık 12 dakika.

### Açık işler

**Haritayı oyuna aktarma (ana iş, kullanıcı isteği):**
- [x] **8.1 Harita ekranını yeni haritayla değiştir.**
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `b4a41c2`): Harita ekranı yeni haritada (WorldMapView, MapTileView); N7 ile kapandı.
  - **Bugünkü durum:** Oyundaki dünya haritası (`scenes/game/world_map.tscn`, `scripts/ui/world_map.gd`, `scripts/travel/world_map_data.gd`) yer tutucu `b6_map` parşömenini kullanıyor.
  - **Yeni harita:** Tek parça 16k bir doku GPU doku sınırını (çoğu kartta 16384) zorlar ve gereksiz VRAM tutar. Kullanılacak olan `../harita_final/goruntuleyici/t/<seviye>/<x>_<y>.jpg` karo piramidi: 1024 px karolar, 5 seviye (seviye 4 tam çözünürlük).
  - **Uygulama:** Godot'ta yakınlığa göre seviye seçen ve yalnızca görünen karoları yükleyen bir karo katmanı.
  - **Yer:** Karoları `data/assets/map/tiles/` altına koy; LFS'e alınması önerilir (§6.1).
  - **Kabul kriteri:** Sürükleme ve kaydırmayla yakınlaşma çalışıyor; tam yakınlıkta yazılar okunur; mobilde bellek sınırı içinde kalıyor.
- [x] **8.2 Oyuncunun konumunu haritada göster ve takip et.**
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `b4a41c2`): Atlı kervan 8 yönlü, yolda yolun üstünde; Kervana git düğmesi ve açılır harita onu ortalar (N7, N24). Gölgesi 19555b5.
  - **İşaret:** At ve binici, `../harita_final/isaret_atli/atli_<yön>_<px>.png`.
    - 8 yön: `K`, `KD`, `D`, `GD`, `G`, `GB`, `B`, `KB`. Gidiş yönüne göre seçilir; formül `../harita_final/BENIOKU.md` içinde.
    - Bağlama noktası `atli_yonler.json` dosyasındaki `anchor`.
    - Kullanıcı onaylı tasarım ve kararlar: `../belgeler/ATLI_ISARET.md`.
    - Sürüm 1 sabit karelerden oluşuyor. İleride yürüme animasyonu istenirse `rider_marker.py`, at modelinin animasyon karelerinden aynı yöntemle render edebilir.
  - **Konum kaynağı:** Kervanın dünya konumu. Seyahatte iki yerleşim arasındaki yol parçası boyunca, ilerleme oranıyla enterpolasyon yapılır (8.3'teki yol grafiği).
  - **Arayüz:** "Kervana git" düğmesi. Harita açılınca kervan ortalanır.
  - **Referans:** Görüntüleyicideki davranış (`goruntuleyici/index.html`) bunun basit bir örneği.
- [x] **8.3 Oyun dünyasını `wayborne_harita.geojson` üzerine oturt.**
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `887fa0c`): Oyun dünyası wayborne_harita.geojson'dan (N1-N6): 27 yerleşim, 41 yol, süreler; arazi de haritadan (N28, 2c8be40).
  - **Yerleşimler:** Oyundaki şehir ve yer kimliklerini (`test_loc_a…e`, `world_places.json`) GeoJSON `place_<n>` kimlikleriyle eşle.
  - **Seyahat:** Seyahat ve rota sistemi `yol` kenarları ile `yol_düğümü` düğümlerinden kurulan grafikte çalışsın.
    - Kenar ağırlığı: `length_px`.
    - Yol sınıfı (ana yol/patika) hız ve tehlikeyi etkileyebilir.
  - **Bölge kuralları:** Kültür bölgesi, orman, dağ ve su gibi kurallar ilgili çokgenlerden sorgulansın: nokta-çokgen testi.
  - **Ölçek:** Koordinatlar görüntü pikseli; dünya ızgarasına dönüşüm `BENIOKU.md` içinde. Oyun içi mesafe ölçeği (piksel başına gün ya da km) tasarım kararı, kullanıcıya sor.
  - **Testler:** Her yerleşimin yol ağına bağlı olduğu (izole yer yok); kaldırılan kervansarayların ve deniz yollarının oyunda da olmadığı.
- [x] **8.4 `world_places.json`'ı GeoJSON ile eşitle.**
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `dc516c6`): Kullanılmayan eski yer listesi kaldırıldı; tek kaynak GeoJSON -> settlements.json.
  - Bugün `data/config/world_places.json` hiçbir kod tarafından okunmuyor ve içinde 12 adet `ih_mezra` var (§1.1, isim kuralı).
  - Harita v3'teki yer listesi (`atlas/places_v3.json`, GeoJSON `yerleşim`) tek doğruluk kaynağı olsun.
  - Kaldırılan kervansaraylar (Tarvessa, Ombrakal) ve taşınan yerleşimler oyunda da güncellenmeli.

- [ ] **8.10 Harita saate göre kararıp aydınlansın (gündüz, akşam, gece).** Kullanıcı isteği, 2026-10-17.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `4eca777`): Çarpan ton katmanı, kararma eğrisi yolun gökyüzüyle aynı; test TEST_PLANI.md'de.
  - **Kaynak:** Oyun saati `JourneyClock`'tan; şehirde de günün saati.
  - **Tonlar:** Harita dokusunun üstüne tek bir renk ve parlaklık katmanı:
    - Gündüz: doğal.
    - Akşam: sıcak, hafif koyu (≈ %85 parlaklık).
    - Gece: soğuk mavi-gri, koyu (≈ %60 parlaklık).
  - Geçişler yumuşak olacak, dakikalar içinde lerp.
  - **Kural: harita hiçbir zaman okunamayacak kadar kararmamalı.**
    - Gecede bile yazılar, yollar ve kıyılar okunur kalacak.
    - Kabul kriteri: en karanlık tonda mürekkep ile kâğıt arasındaki kontrast oranı ≥ 4.5:1. Yazılar için gerekirse ayrı ve daha az kararan bir katman.
  - **Görüntüleyici:** `../harita_final/goruntuleyici` aynı kuralı bir CSS ya da canvas katmanıyla deneyebilir.
- [ ] **8.11 Şehirlerde ve yerleşimlerde küçük ışıklar; akşam ve gece hafifçe parıldasın.** Kullanıcı isteği, 2026-10-17.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `4eca777`): 250 ışık, türe göre (şehir 6-12, kasaba 3-5, köy 1-2, harabe yok); test TEST_PLANI.md'de.
  - **Görünüm:** İşaretteki fenerin ışıltısıyla aynı dil (`../belgeler/ATLI_ISARET.md`): küçük sıcak sarı noktalar ve saydam hale.
  - **Konumlar:** `wayborne_harita.geojson` içindeki `yerleşim` noktaları. Işık sayısı ve dağılımı sınıfa göre:
    - kent: 6–12 ışık, kentin şekli içinde dağınık,
    - kasaba: 3–5,
    - köy ve kamp: 1–2,
    - harabe ve işaret: yok.
  - **Zamanlama:**
    - Gündüz görünmez.
    - Akşam yavaşça yanar.
    - Gece en parlak hâlinde; her ışık farklı fazda, düşük genlikli ve yavaş titreşir (mum gibi; hızlı yanıp sönme değil).
  - **Teknik:** Harita karolarına yakılmaz, ayrı bir katman olarak çizilir; zoom'da boyutları sabit ekran pikselinde kalır. Tek bir shader ya da çok noktalı bir `MultiMeshInstance2D` yeterli.
  - **Not:** Kervanın fener ışıltısı ile şehir ışıkları gece aynı ışık dilini paylaşmalı.

**Haritanın kendisi (küçük):**
- [ ] **8.5 Yazı ile yolun çakışmasını gider.** Bazı kent adlarının altından yol geçiyor (örnek: Vastrevar). Yazının arkasına kâğıt renginde bir halo ya da maske ekle; `_text()` ve `_road_raster()` sırası.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `c59fb3a`): 126 etikete opak kâğıt halesi, yazı IM FELL; 161+85 karo yeniden yazıldı.
- [x] **8.6 Sahne nesne sayısını kontrol et.** Yeniden kurulan sahnede yaklaşık 118.500 nesne var, orijinalde 201.956 vardı. Fark, orijinal sahnenin kodun eski bir sürümüyle üretilmesinden geliyor. Kullanıcı v3'ü onayladı, yalnız bilgi olarak duruyor.
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Bilgi maddesi: kullanıcı v3'ü onayladı; eylem gerekmiyor.
- [ ] **8.7 Boğaza ad ver.** GeoJSON'da geçici olarak "Kesgrav Boğazı" yazıyor. İsim kuralına uygun bir ad kullanıcıya sorulsun.
- [x] **8.8 Atlas sayfasını güncelle.** Yeni harita ve kültüre göre adlar oraya hiç işlenmedi.
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Eski claude.ai atlas sayfası okunamadı; yeni harita, 27 yerleşim (tr/en/zh, tür, kültür, mallar, komşular) ve 41 yol (gün, tehlike, arazi) TODO/belgeler/atlas/ATLAS.md'de. Kervansarayların zh adı veride eksik.
- [ ] **8.9 Harita kodunu depoya ekle.**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `04f0db7`): Harita hattı tools/worldmap altında (atlas, cm, zemin, mapview). Üç mutlak yol göreli; referans oyun adları, ih_mezra (ih_mezra) ve referans oyun değişkenleri temizlendi (kcd klasörü zemin oldu). Büyük ara veriler depo dışında. YAPILMADI: hattın baştan sona yeniden koşturulması (yalnızca py_compile). fields.npz LFS kararı 6.1'e bağlı.
  - Kod ve veri hattı (`kcd/`, `atlas/`, `cm/`) şu an yalnızca `Harita_Calismasi/` altında; depoda `tools/worldmap/` gibi bir yere alınmalı.
  - Büyük ara veriler (`fields.npz` vb.) LFS'e ya da depo dışına.
  - Betiklerdeki `D:/…` yolları göreli yapılmalı.
