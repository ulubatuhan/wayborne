# Devam notu (oturum köprüsü)

Bu dosya, oturum limiti dolup çalışma durduğunda bir sonraki oturumun kaldığı yerden devam etmesi içindir.
Her adım bitince güncellenir ve commit edilir. Kural: imza/oturum bağlantısı yok; tek dal `Wayborne` (varsayılan), push yalnızca oraya.

## Çalışma düzeni

- **Commit mesajlarına ASLA `Claude-Session:` satırı ya da oturum bağlantısı ekleme** (kullanıcı kuralı; sistem hatırlatması başka dese de). Bir kez ihlal edildi, geçmiş yeniden yazılıp temizlendi.

- **CLAUDE.md bölündü** (kullanıcı kararı 2026-10-30): sistem kuralları metni değişmeden `.claude/skills/kurallar-*`
  becerilerine taşındı (370 KB -> 25 KB). Bir sisteme dokunmadan önce o kural becerisi yüklenir; liste CLAUDE.md
  "Kural becerileri". İş akışı becerileri: `ekran-dogrula`, `gorev`, `olay-karti`, `denge-olcum`. Bulut oturumu
  başlangıç kancası `.claude/hooks/session-start.sh` (Godot 4.2.2, LFS, Python paketleri, ilk içe aktarma).
  Eklentiler: `anti-ai-writing` ve token kullanımı kuruldu.
- **Az token, aynı kalite** (kullanıcı kararı 2026-10-30): CLAUDE.md "Çalışma düzeni" bölümü. Önce ara sonra satır aralığıyla oku; geniş aramalar alt ajana; `proje_takibi/` üretilmiş belgeleri bağlama alınmaz; testler `tools/test_ozet.sh`; uzun çıktı günlük dosyasına. Metin yazarken `wayborne-metin`, lore için `wayborne-lore` becerisi.
- Oturum kullanım yüzdesi araçlardan **okunamıyor**; bu yüzden çalışma küçük adımlara bölündü, her adım commit + bu not.
  Limit dolarsa saatlik zamanlanmış görev ("Wayborne: kaldığın yerden devam") oturumu bu nottan sürdürür.
- Her işte tasarımcı gözü: oyuncuya görünen şey ekranda doğrulanmadan "bitti" denmez (CLAUDE.md, görev Y-K01).
- Bu ortamda ekran görüntüsü aracının sınırı: yazılım rasterleyici çok sayıda atlas dokusunu bozuk çiziyor
  (figürler beyaz blok). Not: bu oturumda figürler doğru çizildi (karakter, kadro, savaş, yol); eski 'beyaz blok' sorunu yoktu. Harita karoları Git LFS: bu ortamda `apt-get install git-lfs && git lfs pull` gerekir (2026-10-22 yapıldı); savaş/saat varyantları ayrı çekim ister. Eski not: figür içeren ekranlar güvenilmez olabilir; bunlar kullanıcının
  PC'sinde test turuna kalır. Figürsüz ekranlar (menü, şehir önü, defter, harita) ekran görüntüsüyle doğrulanabilir.

## Adımlar

| # | İş | Durum |
|---|---|---|
| F1 | Test turu dokümanı: `proje_takibi/TEST_TURU.md` + `.html` (85 madde, 8 bölüm; üretici `referans/test_turu_uret.py`). Yayınlanan sayfa linki kullanıcıya verildi mi: aşağıya yaz | md/html bitti; sayfa https://claude.ai/artifact/JBLDXTSBvqL8V5gsm1j2ox (özel; kullanıcıya verildi) |
| A1 | 2.1 kapandı (web/export kaldırıldı) | bitti |
| A2 | Y-J05 kapandı (müzik silindi, künyede BEKLENİYOR yok) | bitti |
| A3 | N31d: `look_ahead` pozu çubuk figürde düzeltildi (arm_f 64/148, 27295 test yeşil). KALAN: Blender yok bu ortamda; `tools/figure_pipeline/mesh/append_clips.py --clips look_ahead` ile 6 beden x giysi render, `tests/screenshot_reactions.gd` ile bak, sonra `RoadCaravan.LOOK_ENABLED = true`. Kullanıcının PC'sinde (Blender) yapılacak | pozu bitti, render kullanıcıda |
| F2 | Test turuna 13 ekran görüntüsü + 'ben baktım' notları + hata listesi eklendi (`referans/test_turu_gorsel.py`, görüntüler `test_turu_gorseller/`). Kalan ~70 madde görüntülenemedi (saat/olay/durum gerekir): sonraki turda özel çekim betikleri yazılıp genişletilecek. Bulunan açık hatalar: hub kapı yazısı lider adına biniyor, savaş sahnesi sağ taşması (Y-G05), kıyafet dolabı boş yuva/giyinik figür uyumsuzluğu. | bitti (genişletilebilir) |
| A4 | Y-H07: istenen kapsam (metin boyutu, desenli şerit, otomatik duraklatma) zaten yapılmış; "test bekliyor"a alındı ve test turuna eklendi | bitti |
| B1 | 9.2 + Y-G16 ana menü: ateşin başına üç yolcu eklendi (`GrimDrafts.CAMP_TRAVELLERS`), test bekliyor; ince ayar: saçsız mankenler, yan yana diziliş (oturur/çömelmiş poz istenirse yeni klip gerekir) | bitti (test bekliyor) |
| B2 | 9.1 ortak UI kiti v2 | kullanıcı kararıyla (C1) eklendi, bkz. K8 |
| B3 | Y-G05 savaş ekranı | sırada |
| B4 | 12.2 yol görünümü büyük revizyon, 9.10 biyom arka planları | sırada |
| B5 | Y-G11T masa şablonu taslağı, Y-G13 beş ana görsel | sırada |
| L1 | Lore özeti `docs/lore/LORE_OZET.txt` + soru defteri (harita v3, 302 soru, özet ilk sekmede) https://claude.ai/artifact/GL3TcJUe1Agerti9VP6JbH ; üretici `tools/lore_soru_sayfasi.py`. Cevaplar sayfanın db'sinde `answers/<qid>`: okunup LORE.md/TARIHCE.md'ye işlenecek | bitti, cevap bekleniyor |
| L2 | Lore turu 2 (2026-10-29/30): soru defteri I'in 90 bölge cevabı ve 8 onay işlendi; `docs/lore/` LORE, TARIHCE, SORULAR, LORE_OZET yeniden yazıldı (34 öneri T1-T34, 12 çelişki Ç1-Ç12). Lore becerisi `.claude/skills/wayborne-lore/`. Soru defteri II https://claude.ai/artifact/MfVQJSzrrLb68TwZJSPQdh (262 soru; üretici `tools/lore_soru_sayfasi.py`, cevaplar db `answers/<qid>`). Kıtlık kararı görev Y-C21; üç tasarım dersi Y-C22-24 (`docs/design_notes/kitlik_tasarim_dersleri.md`); "haritada adı olan her yer oynanabilir" hedefi CLAUDE.md Ana Hedefler | bitti, cevap bekleniyor |
| L3 | Lore turu 3 (2026-10-30): defter II'nin 30 onay cevabı işlendi. Mezhepler düzeltildi (El; Septisizm kurulu, Yumruk/The Fist reformcu); haritadaki her parça kendi bölgesi (Taşkök kuzeybatı, Ayazkaya kuzeydoğu, Karaocak? doğu sıradağı, Tolvarin ve Kirsavel batı, Ezmerak Baronluğu doğu, Ors güneybatı, Gelgit Kıyısı? güneydoğu). 27 yerleşim taslağı ve kalan soruların önerili cevapları `tools/lore_defter3_banka.py`'de (tek kaynak), kopyası `docs/lore/ONERILER_III.md`. **Soru defteri III:** https://claude.ai/artifact/VyXLaSr6scKjA4236bfANg (db, `answers/<qid>`, 144 soru). Sonraki adım: defter III cevaplarını oku (ArtifactData list answers), onaylananları LORE.md/TARIHCE.md'ye [Yazar, onaylandı] olarak taşı. | açık |
| F1 | Film ve kervan fikirleri (2026-10-31): fikir listesi https://claude.ai/artifact/1y14iTWYKSVhrQfkh4Ud81 cevaplandı; 27 görev `gorevler/15_film_kervan_fikirleri.md`'de, tek sıcak kaynak kuralı `kurallar-sanat`'ta, Gokyurt misafirliği, veba ve kervansaray hâlleri LORE.md'de. İnanç mahkemesi kartının açıklaması yeniden yazılacak. | açık |
| F2 | Senaryo sistemi kaldırıldı (Y-A08 bitti, Y-C18 iptal). A listesi (tek başına yapılanlar) ve B listesi (yapıp onaya sunulanlar) 2026-10-31'de bitti ve push edildi; durumlar görev kaydında. B: portre yönergesi + `bust_ink` yorgunluk (Y-G19), bataklık sisi (Y-G22), kartın bölge görünüşü (Y-G20, `screenshot_card_regions`), soy sonu yürüyüşü (Y-G23, `screenshot_lineage_end`), küçük lütuf (Y-B16, `screenshot_mercy`), kart partisi 1 taslağı (`docs/design_notes/kart_partisi_01.md`). CI Screenshots düzeltmesi: `CardDrift` ağaca girince başlar. Bekleyen kullanıcı onayları: kart partisi 1, portre görünüşü, bölge kart dili, güneş ışık kaynağı mı, inanç mahkemesi, ant bağı kapsamı, kervanın inancı (Y-C34). Engelli: kamp ateşi oturma (Blender yok). **Onay sayfası:** https://claude.ai/artifact/QfLWy4uqjFG6XRDTsC8Ttd (db `answers/<id>`: a1-a9, b1-b5, k01-k10, q1-q4; `karar` onay/duzenle/red, `not`). Cevaplar okundu ve uygulandı (2026-10-31, kullanıcı: "düzeltmeleri direkt yap, onaya sunma"): soy sonu kaldırıldı, güneş ve şafak/akşam soğuk, 10 kart + ikinci halka + Avuçiçi kafilesi oyunda, İlan Panosu çivili pano (`NoticeBoard`), veba sistemi (`PlagueWorld` + `plague_news`), ant bağı ve kervanbaşı inancı. Çizim envanteri 691 satır; şablon zipleri yeniden üretilip kullanıcıya gönderildi. | bitti |
| F3 | Eksikler oyunda (2026-11-01): inanç karakter ekranında ve parti görünümünde, panoda kafile ve sürücü ilanları, veba yolda duyulur, ant kardeşleri, tek sıcak kaynak (şehir resimleri gölgelendiricide soğur), kıtlık ve şehir morali (`Scarcity`), kıtlık paleti, beş feda kartı, domino ve son çareler, üç büyüme krizi, inanç mahkemesi. Bekleyen: geçiş belgesi ve kıtlığın sebebi (defter III cevabı), el çizimleri, gerçek ses kayıtları. | bitti |
| C1 | İmleç: pirinç ok ucu (kullanıcı referansı "Shaped"), `tools/cursor_art.py`; sönük ok her yerde, parlak düğme üstünde; kumanda imleci aynı resim. 28779 test yeşil, `tests/screenshot_cursor.gd` | bitti |
| C2 | Sırada (kullanıcı, 2026-10-23): Y-G03 saç/başlık render, Y-C06 35+ ekipman, Y-G04 büst portreleri, Y-G13 vitrin görselleri | sürüyor (C3-C6) |
| C3 | Y-G03 saç: 7 MPFB saç giysi gibi render (`outfits.json` slot hair), renk tint (`hair_color`), yaratılışta seçim, işe alım/tayfa/düşman tohumdan. Kuyruk: `build/figures/outfits/run_hair.sh`, `run_hair_hd.sh`, `run_body_hd.sh` (log `build/figures/outfits/logs/queue.log`). Bitince: `pack_outfits.py --variants ... --items hair_*`, `pack_hd.py --items hair_* --outfits-only`, import (`--editor --quit-after 6000`), test_outfit, ekran görüntüleri. Sarık/sakal yok (CC0 kaynak yok) | bitti: 42 saç kümesi ve 42 HD küme (6 beden); sarık/sakal CC0 kaynak bulununca |
| C4 | Y-C06 36 ekipman (sinerji, bedelli, lanetli; kilise laneti kaldırır), ikonlar `tools/equipment_icons.py`, ölçüm simulate_journeys parça taraması | bitti (24527c4) |
| C5 | Y-G04 büst portresi (`BustPortrait`): karakter, kadro, aday, madalyon (devir, döküm), Düşenler (ölünün görünüşü defter satırında `look`) | bitti: madalyon oval maskeyle, Düşenler portreleri ekranda doğrulandı |
| C6 | Y-G13 vitrin: `tests/screenshot_showcase.gd` -> `docs/steam/vitrin/*.jpg`. Bulunan ve oyunda düzeltilen: kamp koltukları ateşin üstündeydi, harita atlısında fener yoktu | bitti: beş kare saçlı figürlerle, `docs/steam/vitrin/*.jpg`; kullanıcı onayı bekliyor |
| C7 | Kamp ateşi oturma (kullanıcı, 2026-10-23): bitti (2026-11-01). Ateşe varan figür kütüğe oturup ellerini ateşe uzatır (`sit_fire`, `RoadCaravan.CAMP_SEATED_CLIP`); 6 beden ve bütün giysiler render edilip paketlendi (`tools/figure_pipeline/add_clip.py`, ~15 dk), `screenshot_camp` ile görüldü. Düzeltme (kullanıcı): yalnızca iki kişi oturur, ayak uçları taş çemberin bittiği yerde; öbürleri oturanların hemen arkasında ayakta, el uzatmadan (`CAMP_SITTERS`, `_seat_reach`). | bitti |
| C8 | Windows kurulumu (kullanıcı, 2026-11-01): `kurulum/Wayborne.cmd` tek dosya (cmd + PowerShell). Git yoksa winget ile kurar, `Wayborne` dalını sığ klonlar (`Wayborne\oyun`), Godot 4.2.2'yi indirir (`Wayborne\godot`), güncelleme gelince iki kez içe aktarır, oyunu açar. Linux'ta pwsh 7.4 ile ayrıştırıldı, ilk indirme ve "güncel" yolu denendi; Windows'ta henüz koşmadı. | bitti |
| C9 | Oyun testi geri bildirimleri (kullanıcı, 2026-11-01): menüde fener kalktı, ateş arkadaki yolcunun önünde (`fire_front.png`); şehir vurgusu yalnızca dış hat (`outline.png`, `tools/ui_scenes/venue_outline.py`, scipy ister); şehir paneli +/- ile katlanır; taverna masa arkası kesimi, yavaş ışık, fiyat söyleyen konuk; tam ekran ve ayarı; kamp sandıkları, boyunduruk boyunda; harita ikonları uzaklaşınca küçülür; Yola Çık yön sorar (dış alan atlanır); şehir gözlemi defterin Günlük sayfasında (`GameSession.journal`); olay kartı opak ve büyük; savaşta düşman turları sırayla (`CombatEncounter.paced`), klipler yavaş, kartlarda Durur/Vurur alt alta; belde kılıç kınında. Açık: batıya giden yolda kervan sola yürümüyor (yol bandı hep sağa akıyor; aynalamak bant, işaretler ve yazılar için ayrı iş). TEST_BEKLEYEN doğrulaması alt ajanda. | kısmen |
| C10 | TEST_BEKLEYEN doğrulaması (2026-11-01, alt ajan, rapor scratch'te): 105 görevin kodu oyunda. Düzeltildi: onay kutusu simgeleri, karakter oluşturma stat satırı, baskın seçenek 9→0, harita kamp çadırı, yol hafızası boyu, İngilizce GP ve tekil-çoğul. Açık: Vastrevar gece resmi 960x540, defter lekelerinde ızgara, menüde öndeki iki yolcu bulanık ve menü ateşi köşeli, eksik biyom varyantları (meadow_cold, marsh_cold/warm, ufuk dağları), Drazvor adı haritada yok, yolda veba görseli, 25 kartta riskli seçenek yok. Kapandı: 12.2c kamp yürüyüşü (0,5 oyun saati) ve yoldaki kamp alevi; Y-K02 iptal; başka kervanların figürü kullanıcı kararıyla gerekmez. | kısmen |
| L4 | Lore defter III çelişkileri işlendi (2026-11-01): Ç2-Ç11, Ç13, Ç14, yolda doğan, işaret, nefes. Adlar: Raegmund, Daveric, Aldemar, Valdric, Lenart Bey, Septimar. Oyunda: kâğıt ve bozkır baharı malları, Orvahel/Orbeyan malları, göçebe Orbeyan+Kirsavel başlangıcı, Akavan/Samuran Vadi (`economy.json` region_override, `build_settlements.py` + `annotate_walls.py` ile yeniden üretildi), her bölgede başlangıç (Karaocak/Vorgat hariç, N8), mezarda "taş yığ", Yumruk şehrinde kilise notu, Avuçiçi kapısı (aracı %20, mekânlar kapalı), `evt_avucici_hand` ve kalıcı tek el (`missing_hand`, `stump.gdshader`, iki elli yetenekler kilitli). Açık: Ç12 balıkçıların yurdu; defter III'ün öbür 128 sorusu cevapsız; durur pozda yakın el bazı karelerde gövde katmanında kaldığı için tam silinmiyor. | kısmen |
| K10 | Kullanıcı onayı (2026-11-01): Y-A01, Y-A02 (vaat ve sütunlar; CLAUDE.md kutusu kalktı), Y-B08 (günün satırı olduğu gibi, serbest metin yok), Y-C02 (kontrat ekranı, lonca görevleri sabit), 12.2, 12.2e, Y-G05, N29, Y-F04T kapandı. | bitti |
| K11 | 12.2a kapandı (tam ekran kapı geçişi 2026-10-22'de silinmişti, kapılar yolun iki ucunda). Y-K02 iptal (kullanıcı): `tools/ci` silindi, `screenshots.yml` yalnızca çekim + betik hatası kapısı + fotoğraf çıktısı. | bitti |
| 4.5 | Kod denetimi (kullanıcı, 2026-11-02): ölü kod ve kopya mantık. Silindi: 21 çağrılmayan fonksiyon, 9 okunmayan sabit, `UiIcon`'un `PIPS` modu + `ArtDraw.pip`, `_route_meta`'nın üç okunmayan payı, `RoadSignals`'ın eski `KIND_RESOLVED/ESCALATED_KEYS` tabloları. Tek kaynağa indi: `CombatUnit.status_name_key` (iki ekranda birebir kopyaydı), `Wording.danger_band`, `InGameMenu.open_in`, `NodeUtil.modal_card` (dokuz panel), `NodeUtil.panel_header` (iki panel), `InkMenu._add_rows`. Net -412/+210 satır, 45 dosya. Doğrulama: 30602 test; on modal panel refactör öncesi/sonrası **piksel piksel aynı**. Dokunulmadı: koruma zincirleri, veri tablosu uzunluğundaki fonksiyonlar, `MarketScale`'in resimsiz yedek çizimi. | bitti |
| Y-G25 | Yağmur ve kar bedende (kullanıcı, 2026-11-05): `Soaking` kervanın **üstündeki** su ve karı `GroundCover` gibi hesaplıyor (saklanmıyor, iki gün hafıza, ateş günün sonunda kurutuyor, eriyen kar suya dönüyor). Çizim: `ArtDraw.snow_cap` düzensiz tek yığın, `wet_sheen`, `wet_tint`; `WalkFigure` baş/sırt/omuz, `ArtDraw.wagon` brandanın tepesi; pay `RoadCaravan`'dan yumuşak geçişle dağılıyor. Mekanik: ıslak giysi ısısının %55'ini kaybediyor (`Temperature.WET_WARMTH_LOSS`) - yağmurun bedeli gece ödeniyor, kuruma yolu ateş; erzak sözü etkilenmiyor. Yağmur dinince brandadan `canopy_drip`. Ekran görüntüsü dört hata yakaladı (kar önce kalas, sonra şekerleme sırası, sonra aşçı şapkası; ve render figürler `head` değil `head_top` verdiği için insanlarda hiç kar çizilmemişti). 30923 test geçti. | bitti |
| Y-G24 | Zemin ve hava efektleri (kullanıcı, 2026-11-03): 46 efekt, hepsi **kod**; `tools/efekt/` (tuval + beş çekirdek + palet + katalog) sprite sheet basıyor, `python3 tools/efekt/uret.py [<id>...] [--tabaka]`, çıktı `data/assets/fx/sheets/` + `fx.json`. Aileler: perde (yağmur x3, karla karışık, dolu, kar x2, tipi, sis, yer buğusu), yere düşüş (kuru toprağa damla, birikinti halkası, taç sıçrama, kar konması, branda damlası), ayak/toynak/pençe ve tekerlek dört zeminde (kuru, çamur, su, kar), yerde kalan iz (ayak/toynak/tekerlek; çamur ve kar), soğuk (nefes buharı, kırağı, birikinti kırışığı), ateş (kor, duman x2, buhar, fener halesi), rüzgâr (toz, yaprak, kar). Oyun tarafı: `FxCatalog`, `FxLayer` (havuzlu, efekt bırakıldığı **toprağa** çivili), `WeatherCurtain` (iki derinlik), `GroundCover` (hesaplanır, saklanmaz; üç gün hafıza). `RoadCaravan` her ayak/toynak/tekerlek temasında efekt ve iz bırakıyor (`WalkFigure.take_footfalls`). Perde varken şeridin kendi yağmuru susuyor, sanat eksikse geri geliyor. Doğrulama: `tests/test_road_fx.gd` 280 test (toplam 30891 geçti), `tests/screenshot_road_fx.gd` sekiz kare. | bitti |
| T16 | Oyun testi turu 2026-11-02 (bölüm 16, P19) bitti. T16-01 kamp: normal yürüyüş, yürüyüş+iniş ≤10 sn, öncü ateşi, saat 0.05x. T16-02 balıkçılar: tek yurt yok, `peoples`, işe alım yerleşimin halkından. T16-03 batıya yolda kervan sola (`lay_road`, `terrain_from`), geri dönüş tüm kervanı çevirir. T16-04 menü: oturuşun HD kümesi, ateş `CampFlame`. T16-05 kesik el duruşta da (`stump_layers`). T16-06 taverna: konaklama (`lodge_night`) ve oyun masası ekranı (`TavernGame`). T16-07 bölgesel itibar ve hizipler (`Standing`, standing.json). T16-08 bölgesel düşmanlar (12 yeni, `REGIONAL_BANDITS`, LORE T48). T16-09 hatırlayan kişiler ve yolun reisi (`People`, `evt_chief_returns`). T16-10 CI tek `ci.yml` (GitHub'da yeşil). T16-11 99 adlı yer yollarda (`road_places`, levha, ziyaret kartı). Onay bekleyen: T16-07, T16-08, T16-09 (kullanıcı oyunda deneyecek). | bitti |
| D1 | El çizimi programı (kullanıcı, 2026-10-27): envanter (676 görsel), şablon üretici ve 10 zip (scratchpad'de üretildi, kullanıcıya gönderildi; depoda yok, `python3 -I tools/el_cizimi/sablon_uret.py <klasör>` ile yeniden), Excel takip, süreç belgesi, alım aracı (sahte teslimlerle oyunda denendi, deneme sanatı geri alındı). Bu ortamda gerekenler: `pip install psd-tools opencv-python-headless`, Godot 4.2.2 indir (`/usr/local/bin/godot`) | bitti |
| D2 | Figür pilotu: tek rölanti çizimi 14 poza bükülüyor (`docs/el_cizimi/pilot/`); etek/cüppe tek parça `etek` katmanı. Klip açıları `godot --headless --path . --script res://tools/figure_pipeline/godot/export_clips.gd` -> `build/figures/clips` | bitti |
| D3 | Sıradaki: ilk gerçek çizim gelince `al.py`; ilk beden çizimiyle `HumanSkin` (GDScript) + ince/iri türetme denemesi | bekliyor (kullanıcının çizimi) |

## Kullanıcı kararları (2026-10-21, karar defteri) - İŞ SIRASI

"Taslaktakini al" = taslak görseli oyunda birebir kurulacak. Her madde bitince ekran görüntüsüyle taslakla karşılaştır.

| # | Madde | Karar | Durum |
|---|---|---|---|
| K1 | A1 ana menü (y_g16_menu_kamp.png) | şerit yok, sahne tam ekran, sağda altın WAYBORNE (IM Fell SC), EB Garamond menü, soy satırı altta | bitti: şerit, alt yazı ve fener kalktı; yolcular ateşten aydınlanıyor (firelit.gdshader); keçe başlık düzeldi (felt_cap) |
| K2 | A2 karakter ekranı (y_96_karakter.png) | taslaktakini al | bitti: IM Fell altın ad ve başlıklar, büyük satırlar, beceri çubuğunda sayı ipucuna taşındı, sınıf amblemi alt başlıktan kalktı; türetilmiş stat satırı bilgi kaybı olmasın diye kaldı |
| K3 | A3 defter Düşenler (y_911_dusenler.png) | taslaktakini al | bitti: IM Fell mürekkep başlıklar ve adlar, çizgi harflerin ortasında, 80 px mezar işaretleri, hikâye satırları aralıklı; screenshot_waybook.gd onarıldı (AudioManager ağaçtan) |
| K4 | A5 şehir kapıları | kulelerin altında kapıyla birleşen sur duvarı yok; düzelt | bitti: settlement_gates.py her gözetleme kulesinin arkasına TallWall koyuyor (WALL_BEHIND_DEPTH), 27 kapı gece ve gündüz yeniden render edildi; sur kulelerin altından kapıya kesintisiz geçiyor |
| K5 | A6 + C3 yol ışığı/biyom (y_122e_yol_isik.png) | taslaktakini al | bitti: Gauss haleli güneş/ay, bulutlar, ufuk bandı, sis şeridi, soğuk uzak/sıcak ön, koyu gece ve fenerin yol dairesi; screenshot_road_light.gd tabloyu basıyor. Haritadaki konuma göre biyom varyantı (Y-G07) Blender ister, bu ortamda yok |
| K6 | B1 şehir durum varyantları (y_93_sehir_varyant_vastrevar.png) | taslaktakini al | bitti: gri (kapalı hava, şehrin tohumlu havası) ve kriz (veba/savaş: kızıl ufuk, duman) gölgelendiricide; screenshot_city_moods.gd |
| K7 | B2 kadro kartı (y_97_kadro_karti.png) | taslaktakini al | bitti: 380x620 kart, 62 px rozet, 34 px IM Fell ad, kartlar arası 60 px, mevki yazısı ipucuna taşındı, başlık IM Fell altın |
| K8 | C1 UI kiti v2 (stash "B2 UI kiti denemesi", y_91_ui_kit*.png) | test ederek ekle | bitti: stash uygulandı; çerçeveli panel (pazar, olay kartı), kırmızı ana eylem (pazar Al, taverna Sohbete başla, kartın ilk seçeneği), parşömen ipucu plakası ve pazar fişi, başlık şeridi; test_waybook_theme yeni karara göre güncellendi, 27298 test yeşil |
| K9 | C2 savaş ekranı (y_98_savas.png) | taslaktakini al; kanama/kritik vb. efektler OLMASIN | bitti: tur madalyonu (Roma rakamı), tam ekran (yol HUD gizli), iki alt panel: yetenek kartları (isabet %/kilit sebebi) ve hedef (can, koruma, durum, davranış, kayıt); kritik mührü eklenmedi |
| K10 | D1 pazar | oyundaki kalsın; diğer vagonlar, vagon ve kullanıcı envanterleri açılır-kapanır sekme olarak eklensin | bitti: kervan sütunu bölüm bölüm (her vagon, her kişinin çantası), başlığa tıklayınca açılıp kapanıyor, kapalıyken yük özeti; açık/kapalı oturum boyunca hatırlanıyor |
| K11 | D2 yol HUD | oyundaki kalsın, taslak y_99_yol_hud.png silinsin | bitti: taslak ve karar görseli silindi, arayuz_taslaklari.py'den hud() çıktı |
| K12 | D3 şehirde insanlar (y_g10t_sehir_halk_vastrevar*.png) | taslaktakini al | bitti: TownsfolkLayer (gece 4 kişi, akşam/gündüz 9), yerin ışığı, fenerli bekçi, yürüyenler gidip geliyor; ayaklar alt şeridin üstünde |
| K13 | Kapı bayrakları + sur malzemesi (kullanıcı notu, 2026-10-21) | bayrak kumaş rengiyle; haritadaki kütük surlu yerleşimlerin kapısı, şehir önü ve hub kapısı gerçekten kütük | KOD BİTTİ: `FLAG_MATERIAL`, `palisade` (kütük sur), `Location.wall`, `palisade_gate` eşyası, test. RENDER SÜRÜYOR: 27 kapı (`gates_all.sh`) sonra 9 ahşap kasabanın şehir önü (`towns_wood.sh`); her kapı ayrı commit. Biten kasabalar `git log` 'Kapı:' / 'Kasaba:' satırlarında. |
| K16 | Yolun iki ucu yerleşimin kendi kapısı (kullanıcı, 2026-10-21/22) | GateArrival SİLİNDİ; başta çıkış (kuyrukta), sonda varış (liderin önünde) kapısı; arkada şehir pusta, geçitte parmaklık/kanat, gece meşale | BİTTİ, PUSHLANDI (22c5ad4): 27 kesit iki katman, geçit ölçülü (taş 3.9x4.4, kütük 3.6x3.3, oba 4.5 m), testler 28398 yeşil, CI yeşil. Görüntü: `tests/screenshot_arrival_gate.gd -- <çıkış> <varış>`. |
| K17 | Türe özel şehir ve giriş (kullanıcı, 2026-10-22) | oba, maden, liman, bataklık, nehir | BİTTİ (2026-10-22): kod, kesitler ve 27 yerleşimin hepsi dört vakitle yeniden render edildi (son: selvicar 1587651); test_settlements 986 geçti. |
| K18 | Vadi yapıları yıpranmış + her şey kasvetli (kullanıcı, 2026-10-22) | vadi: kir, akıntı, dipte toprak/yosun; bütün sahneler grim | BİTTİ: `weather_materials`, `GrimGrade` (yol/savaş/hub), `town_grade` (kesit), STIL_REHBERI 'Kasvet'. Vadi yerleşimleri render edildi (K17 ile birlikte bitti). Ölçüm: öğlen yol doygunluğu 0.17-0.20, şehir 0.15. |
| K19 | Bağlanmamış geliştirmeleri bağla (kullanıcı, 2026-10-22) | sıcaklık, GRANT_OUTFIT, tazelik, fener amblemi, look_ahead | BİTTİ (533bc38; look_ahead render edildi, LOOK_ENABLED açık): `Temperature` (°C; gece soğuğu giysiye göre stres/yorgunluk, ateş, ayazda humma, tayfa morali; dondurucu gün erzak payı + planlayıcı `cold_ration_shares`; Durum sekmesinde alev), balık tazeliği satışa (`freshness_multiplier`), `GRANT_OUTFIT` zula ve terk edilmiş kervanda, menüde fener amblemi. SÜRÜYOR: `look_ahead` pozu 70/197 (el alına), scratchpad `look_batch.sh` (log `build/figures/logs/look_batch.log`, sonunda `LOOK_TAMAM`): 6 beden + bütün giysiler render, `append_clips --clips look_ahead`. Bitince: `godot --headless --editor --quit-after 3000` (iki kez), `RoadCaravan.LOOK_ENABLED = true`, `tests/screenshot_reactions.gd` ile bak, testler, commit. Taslak bileşenler (GrimNotice/WornCell/MarketMeter/TradeScales) K10/K11 kararıyla bilerek bağlanmıyor. |
| K20 | Gösterge madalyonları (kullanıcı, 2026-10-22) | şişe yok; Gemini resimleri bronz sikkede; sayılar yalnızca fare üstünde | BİTTİ: moral meşale, stres sarmaşık, tehlike kuzgun, takat at (3 hâl, `Wording.band` eşiği), sıcaklık o anın havası (8 resim; gece ay, sıfır altı kar/tipi). Değer birimiyle levhada ("72/100", "%45", "−4 °C"). Hat: `tools/gauge_icons.py` (kaynak `art_source/gauges/`). Promptlar: `proje_takibi/referans/gemini_gosterge_promptlari.md`, `gemini_sicaklik_promptlari.md`. |
| K15 | Denetim: niyet edilip oyuna bağlanmamış maddeler (kullanıcı, 2026-10-21) | otomatik tarama: olaylarda kullanılmayan etki türleri, kimsenin vermediği eşya/ekipman, çağrılmayan fonksiyon/sabit/sinyal, ses dosyaları | BİTTİ. Düzeltilen: `ring_charmed` hiçbir yerden gelmiyordu, haydut ganimetine eklendi. Belgelenen açıklar (CLAUDE.md Ana Hedefler): `GRANT_OUTFIT` hiçbir olayda yok; yığın yaşı fiyata girmiyor; oyunda sıcaklık modeli yok (Celsius göstergesini yalnız taslak ekranlar besliyor); `lantern_emblem.png` hiçbir ekranda çizilmiyor (Y-G08 açık); `CHAIN_ADVANCE` kullanılmıyor (lore bekliyor, Y-E06). Kapanmış Ana Hedefler maddeleri (hastalık, zor işe alım) silindi. Ölü ama zararsız: ~70 çeviri anahtarı (eski pazar sepeti/durum paneli), `DutyCatalog.PRIMARY/SECONDARY_MATCH_MULTIPLIER`, `RoadSignals.get_*_key`, `EnemyCatalog.*_REGION_ID` sabitleri. |
| K14 | Yol: haritadaki konuma göre biyom varyantları (Y-G07/9.10, kullanıcı 2026-10-21 'şimdi bu işe başla') | kuzey soğuk, güney sıcak, dağa yakın parçada ufukta dağ | BİTTİ (2026-10-21). 24 görünüş render edildi (`data/assets/ui/road/<biyom>_<iklim>[_peaks]/`, peaks yalnız far); `settlements.json` `--annotate` ile climate/peaks aldı; `RouteTerrain.look_of`, `RoadStrips.fallback_chain`; testler 28166 geçti; tablo `tests/screenshot_road_looks.gd`. Haritanın kullandığı her görünüş var; meadow_cold ve marsh_cold/warm hiçbir yolda olmadığı için render edilmedi (düz biyoma düşer). |

KALSIN (dokunma): A4 kilise, A7 gün evreleri, A8 taverna, A9 sohbet, A10 terazi, A11, A12, A13, B3, C4 (oyundaki masa), C5.

Kullanıcı kararları (2026-10-21): 2.3 CityView silinmiş kalsın (bitti); 6.1 LFS taşınmayacak (bitti); Y-H01 şimdilik öğretici/yardım paneli yok, kaldırıldı (bitti); Y-G08 motif ateş ve fener birlikte (güncellenecek); N31f ortam kayıtlarını kullanıcı getirecek. Karar bekleyen madde kalmadı; lore'a bağlılar yazılmaz.
Lore'a bağlı olanlar (Y-E01/E02/E06, Y-A07) yazılmaz.

## Ticaretin odağı turu — 17 önerinin hepsi oyunda (2026-11-05)

Gerekçeler `docs/design_notes/ticaret_ve_kasvet.md`, maddeler
`docs/design_notes/ticaret_onerileri.md`, iş kaydı
`proje_takibi/referans/gorevler/17_ticaret_odak.md`. Kullanıcı on yedisini de
onayladı; hepsi uygulandı, her parça ayrı commit ve push edildi.

**Ne değişti, tek cümleyle:** pazarlık tek bir karara indi (%45 → %15), erzak
şehirde tükeniyor, altın kıtlıkta değersizleşiyor ve takas varsayılan hâle
geliyor, fiyatın nedeni üç kelime, ticaret deftere ahlaki bir iz bırakıyor,
açlık ve yorgunluk bedende görünüyor, yol üç gün üst üste susabiliyor ve borç
büyümeyi bırakıp bir ad ile bir yük taşıyor.

**Hiçbir sistem kesilmedi** (derinleşme, asla sadeleştirme): kese, lonca,
itibar, kontrat, borç, pazarlık hepsi duruyor - kipleri değişti. Tek gerçek
kaldırma nakit kredi (P13), yerine mal avansı geldi.

**Ölçüm (P8):** `simulate_career`'a kalıcı "kâr tavanı" satırı eklendi. Asıl
bulgu ölçüm aracının kendisiydi: satış şehir hazinesini ve geri satış tavanını
hiç uğramıyordu, rapor 6948 GG'lik bir tepe gösteriyordu. Araç ekranın
kapılarından geçirilince kese eğrisi düşüyor (oran 0.59-0.82), tepe 1617,
ölüm oranı değişmedi.

**Ekran görüntüsünün yakaladığı yedi kusur** (hiçbirini test göremezdi):
pazarlıkta kazancı görünmeyen risk düğmesi; her malın altında yazan "Kıtlık";
içe aktarılmamış çeviri anahtarı; aşınmanın dört hâlde de görünmemesi; borç
özetinde kese bakiyesinin "en yakın vade" diye basılması; "-12 gün"; ve
takasta kıtlığın neden iyi olduğunun söylenmemesi.

**Yapılmayan tek şey:** P15'in "haber satın alınabilsin" kısmı, kullanıcının
N34 kararıyla (*"tavernadan doğrudan dedikodu satın alınmasın"*) çeliştiği
için uygulanmadı; haber anlatılıyor, kervansaray da aynı kurala bağlandı.
Kullanıcı N34'ü geri alırsa satın alma tek düğmeyle açılır.

**Testler:** 31990 geçti. Yeni paket `tests/test_trade_focus.gd`; yeni araçlar
`screenshot_haggling`, `screenshot_price_marks`, `screenshot_barter`,
`screenshot_wear`, `screenshot_debt`, `screenshot_provisioning`.

## Oyuncu profilleri turu (2026-11-05)

Rapor `docs/design_notes/oyuncu_profilleri.md`, kayıt
`proje_takibi/referans/gorevler/18_oyuncu_profilleri.md`, araç
`tests/simulate_personas.gd` (`--iz <profil>`, `--ablasyon`).

**Tek cümlelik bulgu:** oyunu şu an yalnız **optimize eden** oyuncu
bitirebiliyor. Tüccar 24 seferin 24'ünü tamamlıyor; Hikâyeci ve Merhametli
üçüncü seferde ölüyor.

**Ablasyon:** tayfayı beslemek tek başına dayanıklılığı 3 → 11.2 sefer
değiştiriyor. Planlayıcıyı okumak ve pazarlık etmek hiçbir şey
değiştirmiyor.

**Ekran:** planlayıcı açıkça uyarıyor; eksik olan bedelin **ölçeği**
("moral düşer, stres birikir" ↔ kervan üç seferde biter).

**Karar bekleyen:** yedi öneri (Ö1-Ö7), hiçbiri sistem kesmiyor. En
yüksek öncelik Ö1 (uyarı ölümü adıyla ansın) ve Ö2 (sofra kipi
planlayıcıda görünsün).

### Öneriler uygulandı ve yeniden ölçüldü (2026-11-05)

Yedi önerinin hepsi oyunda (Ö6 hariç: Ö1'in güçlenen uyarısı aynı işi
yapıyor). Aynı simülatör, aynı tohumlar:

- **Hayatta Kalan artık oyunu bitiriyor:** 18.7 → 24.0 sefer, 3/3 ölümden
  0/3'e, keyif 0 → 29.9.
- **Merhametli üç kat yaşıyor:** 3.0 → 9.7 sefer.
- **Tamamlayıcı (gelişen) ikinci bitiren oldu:** 11.0 → 16.7, keyif
  38.8 → 53.7.
- **Tüccar neredeyse değişmedi** (53.3 → 55.3) ve gündelik işi koşu başına
  yalnız 1.3 gün kullandı - can simidi zordakine açık, güçlüye bedava
  kazanç değil.

**Açık kalan karar (PR07):** Hikâyeci profili hâlâ bitiremiyor (5.0 sefer)
ve keyfi düştü - daha uzun yaşayınca daha çok aç gün görüyor. Çözümü
kıtlık kipine dokunuyor (affedici rota seçimi ya da sınırlı ilk sefer),
o yüzden yapılmadı.

## Oyun günlükleri turu — altı profil (2026-11-05)

Rapor `docs/design_notes/oyuncu_gunlukleri.md`; altı günlüğün tamamı
`docs/design_notes/oyuncu_gunlukleri/*.md`; kayıt
`proje_takibi/referans/gorevler/18_oyuncu_profilleri.md` (PR08-PR12).
Araç `tests/simulate_player_diaries.gd` (6 profil × 2 koşu × 20 sefer),
ekran `tests/screenshot_diary_fixes.gd`, kilitler
`tests/test_persona_fixes.gd` (12 test; süit 32 055 geçti).

**Profiller:** Kâğıt Üstünde Tüccar · Defter Tutan · Ucunda Yürüyen ·
Listeyi Kapatan · Bedeli Soran · Vagonu Kuran (yeni). Her biri keyif
aldığı yerleri listeliyor ve şehrin bütün fiillerini deniyor; günlüğe
`istedim` / `keyif` / `anladım` satırları düşüyor (808 / 1022 / 103).

**Düzeltilen kusurlar (hepsi testli):**
- K1 `TRAVEL_DAYS` kat edilen yolu siliyordu - `journey_total_days`
  artmayınca `get_days_travelled()` sıfıra kırpılıyordu ve oyuncu
  gecikme kartından sonra başa dönmüş görünüyordu →
  `GameSession.extend_journey()`.
- K2 yolda arama yalnız en iyi sezgiye bakıyordu, el sayısına değil →
  `FORAGE_PER_EXTRA_HAND`.
- K3 konaklama, şölen ve kilise bağışı sebep söylemeden ölüyordu → üç
  yeni `*_block_reason` + ekranlar.
- K4 teslimat kaç tane eksik olduğunu söylemiyordu →
  `get_chain_missing_text`.
- K5 emirler paneli kadro listesinin üstüne biniyordu.
- K6 yolda "Yiyecek ara" emri · K7 soy bilgiyi taşıyor (fiyat defteri
  kulaktan dolma olarak devrediliyor).

**Ölçüm aracı üç kez yalan söyledi, üçü de yakalandı:** savaş
simülatörde hiç çözülmüyordu ("sıfır ölüm" sahteydi); "sebep yazmıyor"
sayısı benim uydurduğum cümleden geliyordu (gerçek bulgu: 102 kez
"Yeterli altının yok"); "sıfır aç gün" yalnız adı olan partiyi
sayıyordu (isimsiz ekip 60-98 gün aç).

**Açık kalan karar (PR11/PR12):** oyunun ortası yok. Dört profil 20/20
sefer sıfır ölümle, iki profil iki koşunun ikisinde de 5-6,5 seferde
bitiyor; arada bant yok ve ayıran şey beceri değil, sofranın herkese
açık olup olmaması. Sebebi aritmetik: **ticaret dışında günlük tüketimi
aşan tek bir gelir yok** (gündelik iş net +0,4 gün, arama ≈0, dövüş
küçük). Öneriler G1-G8 raporda; G1 (kervanı ücretle yük taşımaya vermek)
ve G2 (isimsiz ekibin açlığı deftere geçsin) kullanıcı kararı bekliyor.

## Önerilerin uygulanması (2026-11-06)

Rapor `docs/design_notes/oyuncu_gunlukleri.md` §9; kayıt
`18_oyuncu_profilleri.md` PR13-PR18. Süit 32 129 geçti; ekran
`tests/screenshot_g_fixes.gd` (5 kare).

**G1 reddedildi** (kullanıcı): kervanı ücretle yük taşımaya vermek ticaret
odağını artırıyor, tüccar konvoyundan farkı yok, hissi zayıflatıyor.

**G2 dağılma** - kullanıcı öneriyi bir defter satırından bir mekaniğe
çevirdi. `_sync_crew_names()` boşalan eli bedavaya dolduruyordu; artık
`crew_missing` var. Üçüncü aç geceden itibaren bir el ayrılır, yedinciden
itibaren ölür; tüketim ellerden, taşıma gücü `get_driveable_wagon_count()`
üzerinden hesaplanıyor. Boşta vagonun yükü taşınır, sığmayan yolda kalır.
Eksik el kervansarayda parayla kapanır (`hire_crew_hand`), fiyat
`crew_lost_to_hunger` ile yükselir.
**Ölçüm: Bedeli Soran 6,5 → 12,0 sefer, ölüm 3,5 → 1,0, biten koşu 2/2 →
1/2.** Dört ölümsüz profil hâlâ ölmüyor ama teslimatları yarıya iniyor:
aç bırakmak öldürmüyor, küçültüyor. Aradaki bant açıldı.

**G5** yere düşen mutlaka yaralanır + kaybedilen dövüşte yük yağmalanır
(erzak hariç). **G6** kolon uzadıkça yavaşlar ve göze batar; planlayıcı
payı adıyla yazar. **G3/G4/G7/G8** görünürlük: eksik malzeme sayıyla,
pazarda tarif ve bekleyen kişi notu, avans eşiği, pano ilanı tıklanınca
sebebini söylüyor.

**Açık kalan (PR18):** Defter Tutan profili hâlâ iki koşuda da bitiyor.
Sorunu açlık değil gelirsizlik; G1 tam onu çözecekti ve reddedildi.
Can simitleri işe yarıyor ama kullanılmaları gerekiyor (Bedeli Soran 29
gün çalıştı + 26 gün aradı; Defter Tutan 7 ve 8). Tempo kararı kullanıcıda.

## İkinci tur düzeltmeler (2026-11-06)

Rapor `docs/design_notes/oyuncu_gunlukleri.md` §10; kayıt PR19-PR22.
Süit 32 163 geçti; ekran `tests/screenshot_g_fixes.gd` (7 kare).

- **Dağılmada ölüm ve terk ediş birlikte** (kullanıcı): kademeli kural geç
  gecelerde yine yalnız ölüm bırakıyordu. `get_crew_death_share()` %15'ten
  %65'e, tavan %85 - 1,0'e varmıyor.
- **Tavernada dilencilik:** yalnız meyhaneciyle, aç karna, günde bir,
  kayıtta; itibar doğrudan düşer. İki düzeltme: "aç" ölçütü ambarın dibi
  (önceki okumayla hiç tetiklenmiyordu), getiri 2 GG'den 5-18 GG'ye.
- **Tavernada dolandırıcılık:** kargodaki en ucuz malı nadir diye satmak,
  Zeka+Karizma kontrolü (oran ekranda), karşıdakinin kesesi tohumlu ve
  bilinmiyor, yakalanınca itibar -3 ve o gün taverna kapalı.
- **Ölçüm beş koşuya çıkarıldı.** §9'un "ölüm 1,0" iddiası durmadı (2,4);
  "sefer 12,0" durdu (11,4). Defter Tutan 5,8 → 7,4 sefer, 5/5 → 4/5.
  Varsayılan liderin dolandırma oranı %12: profiller hiç denemedi, ki
  kullanıcının şartı buydu.

## Üç uzman profili (2026-11-06)

Rapor `docs/design_notes/uzman_degerlendirme.md`; kayıt PR23-PR24.
Araç `tests/simulate_expert_review.gd` (6 koşu × 40 sefer).

Tutundurma Analisti · Sistem Tasarımcısı · Zanaat Denetçisi. Araç baştan
söylüyor: gerçek D1/D7/iade/inceleme insan ister; buradakiler vekil
gösterge. Üç ölçüm kusuru koşu sırasında yakalandı (20 sefer sınırı beceri
farkını gizliyordu, negatif keseyle oran anlamsızdı, kişi işleri hiç
teklif edilmediği için "açıkta kalan iş" sahte sıfırdı).

**Baş bulgu:** içerik pisti 4,2 sefer, çekilişlerin %73'ü tekrar, ama 40
seferde katalogun yalnız %56'sı görülüyor. Oyun yeni görünmeyi içerik
bittiği için değil, aynı kartları yeniden çektiği için bırakıyor →
U1 (çekiliş görülmemiş kartı kayırsın) içerik üretmeden kapatır.

**İkinci:** 40 seferde 0/6 koşu bitiyor; soy/defter omurgası yetkin
oyuncuda hiç ateşlenmiyor. Ustalık kesede (554 GG) ve açlıkta (%26→%9)
görünüyor, hayatta kalmada görünmüyor.

**Zanaat denetimi:** %100 benzersiz metin, TTR 0,66, %3 tek seçenekli,
%4 sahte seçim, %64 beceri kontrolü, sıfır etkisiz sonuç, sıfır YZ yazım
izi - ölçülebilen her eksende el emeği. Tek büyük açık: 199 sonucun
sıfırı bir kişinin ya da yerin adını geçiriyor (U2).

Öneriler U1-U7 raporda; U3 (yetkin oyuncuya da bir son) kullanıcı kararı.

## U1 + U2 oyuna alındı (2026-11-07)

**U1 - çekiliş artık görülmemişi kayırıyor.** `GameSession` son 12 kartın
halkasını tutuyor (`recent_card_ids`, kayda yazılıyor), `build_event_context`
hem onu hem `seen_event_ids`'i yönetmene taşıyor,
`RoadDirector.novelty_multiplier` üç kademe uyguluyor: hiç görülmemiş ×2,4,
eskiden görülmüş ×0,8, yeni görülmüş ×0,35. Hiçbiri sıfır değil - kart
havuzdan çıkmıyor, sıraya giriyor; domino çarpanı (×2,5) üstte kalıyor, yani
bir zincirin ikinci halkası yeni görülmüş olsa bile geliyor.

**U2 - sonuçlar ad anıyor.** Tek kapı `EventText.fill()`: önce eski
`People.fill_names` işaretleri ({place}, {nemesis}...), sonra `{who}` (check'i
gerçekten atan kişi; check yoksa tohumdan sabit biri) ve `{town}` (seferde
gidilen, şehirdeyken bulunulan yerleşim), en sonda temizlik - çözülemeyen
işaret ekrana çıkmıyor (eski `fill_names` "{nemesis}"i olduğu gibi
geçiriyordu). Türkçe çekim tuzağı ad bir ortak ada yapıştırılarak aşıldı
("{town} yolunda"), yani kesme işareti/ünlü uyumu sorunu hiç doğmuyor.

193 sonuç metni yeniden yazıldı (tr + en): 191'i bir kişi ya da yer anıyor
(144 `{who}`, 47 `{town}`). İkisi bilerek adsız: `EVT_TROUBLED_NIGHT_SLEEP_GOOD`
(bütün kervanın gecesi) ve `EVT_PORT_GOSSIP_INTRIGUE` (zaten İpekevi'ni anıyor).

Bu arada kullanıcının "han deme, kervansaray de" kuralını çiğneyen dört metin
çıktı ve düzeldi: `EVT_SICK_OWN_CARE_BAD`, `EVT_SICK_OPT_LEAVE`,
`EVT_PORT_GOSSIP_TEXT`, `EVT_RIVAL_SLANDER_TEXT` (+ `STORY_WIDOW_2` ui.csv'de).

Test `tests/test_event_text.gd` (22 doğrulama): katalogdaki her sonuç boş bir
oturumla dolduruluyor, hiçbirinde küme parantezi kalmıyor, ad oranı ≥%95.
Ekran doğrulaması `tests/screenshot_named_cards.gd` - gerçek yol ekranında
gerçek kart: *"Fidyeyi kabul ettiler; kervan Vastrevar yoluna devam ediyor."*
ve *"Torgan yalnızca çürümüş erzak buldu; vakit boşa gitti."*

Sırada: U3-U7 ve her seferde en az bir dövüş + asker kaçakları.

## Yol kesenler ve dövüş garantisi (2026-11-07)

**Garanti.** `GameSession.journey_combat_count` sefer başına sıfırlanıyor ve
sefer kaydına yazılıyor (yükleyip garantiyi sıfırlamak yok). Borç iki kapıdan
kapanıyor: savaşın gerçekten açılması (`EventEffectApplier`, TRIGGER_COMBAT /
TRIGGER_AMBUSH) ya da dövüşe açılan bir kartla yüzleşilmesi
(`EventResolver.note_raid_faced`). İkincisi bilerek: "fidyeyi öde" bir karar,
kaçamak değil - yoksa garanti "oyuncu dövüşene kadar her gün haydut"a
dönüşürdü. **Sıkılaştırmak istenirse** `note_raid_faced` çağrısı kaldırılır,
garanti saf "her seferde bir dövüş" olur (karar senin).

Rampa + kapı: son üç günde dövüş kartları ×3,5, ötekiler ×0,2
(`RoadDirector.combat_debt_multiplier`); son günde `EventEngine` günü %100
kart yapıp havuzu dövüş kartlarına indiriyor. Ölçüm (`tests/measure_combat_
quota.gd`, 120 koşu/yol): 3 günlük yolda bile %100, ilk kesilme ortalama 2.
gün - yani "son gün mutlaka haydut" deseni oluşmuyor.

**Muafiyet.** Avuçiçi (`ahit`), Gokyurt (`gocebe`) ve Kuzey Krallığı'nın
*kendi şehirleri arası* yollar. Krallıktan sınıra çıkan yolda garanti işliyor
(ölçümde %100). Garantiyi kaldırmak yetmedi: ölçüm o yolların yine %77
oranında kesildiğini gösterdi, yani "aşırı korunan yer" ekranda
hissedilmiyordu - korunan yolda dövüş kartları ×0,3 (`GUARDED_ROAD_WEIGHT`),
şimdi %38-48.

**Üç yeni kart** (hepsinde aynı üç yol: ver · dövüş · blöf):
- `evt_deserter_levy` "Maaşsız Bölük" - asker kaçakları yükün **hepsini**
  ister. Gokyurt'ta ve krallığın şehirleri arasında çıkmaz
  (`deserters_on_this_road`); kıtlıkta ve tehlikede sıklaşır.
- `evt_cargo_toll` "Para Değil, Mal" - haydut yarısını ister (yolu yarın da
  kullanacak). Kıtlıkta ×2.
- `evt_road_ultimatum` "Ya Paran Ya Canın" - her şeyi bırakıp yaya devam.
  Düşük ağırlık, 6 gün bekleme: kıtlığın en sert yüzü her gün görünmemeli.

**Blöf (Zeka).** `CARGO_DECOY` yükün en ucuz kalemini "paha biçilmez" diye
verir; tutarsa gerisi ve can kurtulur. Tutmazsa `TRIGGER_AMBUSH`: savaş
pusuyla başlar, ilk round'da **düşman önce oynar**
(`CombatEncounter.ambushed`, ikinci round'dan sonra sıra normale döner).
Verecek yük yoksa seçenek sebebiyle kilitli.

Yeni etkiler: `CARGO_PLUNDER` (amount = yüzde, "all" = bırakılan tek mal da
yok; erzağa dokunmaz), `CARGO_DECOY`, `TRIGGER_AMBUSH`.

Test `tests/test_road_raiders.gd` (65 doğrulama). Ekran
`tests/screenshot_raiders.gd`: üç kart da üç yolu okunur gösteriyor, blöf
oranıyla ("Veysel · Zeka · %47"), yüksüz kervanda sebebiyle kilitli
("Verecek yükün yok"). İki ölçüm kusuru koşu sırasında yakalandı: yük
`start_journey`den önce konunca kervan yeniden kurulurken siliniyordu, ve
ekran aracı kendi kurduğu oturumu kullanıyordu (yol ekranı GameState'inkini
okur).

Sırada: U3-U7.

## U3-U7 oyuna alındı (2026-11-07)

Ölçüm karşılaştırması `docs/design_notes/uzman_degerlendirme.md` §7.

**U7 - metnin sözü tutuluyor.** `EventCatalog.PROMISED_EFFECTS`: 29 sonuç
cümlesi somut bir şey söylüyordu ama oyun uygulamıyordu (bulunan takı
gelmiyordu, kavgada kırılan vagon kırılmıyordu, "deftere yazılır" denen ad
yazılmıyordu). Tablo tek yerde duruyor, `_apply_career_threats` deseniyle
kataloğa işleniyor. Yalnız sayı oynatan sonuç %36 → %22.

**U6 - varışta ustalık.** `journey_hungry_days` sefer başına sayılıyor ve
kayda giriyor; varış özeti iki satır yazıyor: "3 gün aç kalkıldı (10 günlük
yolda)" ve "Kilerde 5 günlük erzak kaldı". Ekranda doğrulandı.

**U4 - boş tur.** `CityBriefModel` artık boş liste döndürmüyor: hiçbir
ihtiyaç yoksa bedelli bir öneri geliyor (birinin isteği → taverna, gündelik
iş → planlayıcı, yoksa taverna). Ekranda doğrulandı: "Bir gün çalışılabilir:
bir gün gider, 6 erzak gelir." İki eski test bu kuralla çelişiyordu
("hazır kervanda uyarı listesi boş"), kurala göre güncellendi: acil uyarı
yok, ama öneri var.

**U5 - ilk oturumun imzası.** Dövüş garantisi zaten 1/6'yı 4/6 yaptı. Üstüne
"üst üste ödeyenle pazarlık biter" eklendi (`raids_bought_off`,
`RAID_PATIENCE` 3): eşiğe gelen kervana fidye seçeneği sebebiyle kapanıyor,
gerçek bir dövüş sayacı sıfırlıyor. Eşiği 2'ye indirmek ölçümü
değiştirmedi - kalan iki koşu ödemiyor, **blöf yapıyor ve tutuyor**; yani
kullanıcının kendi mekaniği çalışıyor, eşik gevşekte bırakıldı.

**U3 - son.** Seçilen kol kıtlığın derinleşmesi: `Scarcity.DRIFT_PER_DAY`
0,0004 → 0,00055, `DRIFT_CAP` 0,2 → 0,45. Birinci yıl neredeyse aynı, geç
oyun ısırıyor. 90 sefer ölçümünde acemi 68,3'te, açgözlü 75,5'te bitiyor;
**plan okuyan hâlâ bitmiyor**. Raporun öbür iki kolu (yaşlanma/kuşak
baskısı, büyüyen kervanın krizleri - Y-C24) açık; bu senin kararın.

Test `tests/test_retention.gd` (48 doğrulama). Ekran
`tests/screenshot_retention.gd`.

## U3'ün kolu seçildi + yol keseni dengeleme (2026-11-07, kullanıcı kararı)

**U3: "büyüyen kervanın ekonomisi zorlaşmalı; açlık, moral."** Üç kol:
- **Bakım** (yeni): her vagon her yol günü para yer. İlk iki vagon bedava,
  sonrası gün başına 0,5 GG. Planlayıcıda ("Vagon bakımı (varışta): 15 GG")
  ve varış özetinde yazılı. Vagon almak artık tek seferlik masraf değil.
- **Kalabalık** (yeni): çıkış morali ağız sayısıyla düşer (8 ağızdan sonra
  her ağız -2, en çok -12). Moral dökümünde "Kalabalık kolon" satırı.
- **Açlık** (zaten vardı): büyüyen kervan daha çok el ister (eller yer) ve
  daha yavaş yürür (G6), yani aynı yol daha çok gün ve erzak demek.

İlk deneme çok sertti ve ölçüm yakaladı: 1 bedava vagon + 1,6 GG/gün +
kalabalık -18 ile plan okuyan oyuncunun kesesi +86'dan **-4770 GG**'ye,
aç sefer %6'dan %41'e, boş tur %28'den %81'e çıktı. Bu bir son değil
sefalettir - oyun bitmiyor, iflas etmiş hâlde sürüyordu. Baskı dörtte
bire indirildi. Şimdi (90 sefer): acemi 69,7'de, açgözlü 75,5'te bitiyor;
plan okuyan 90'ı tamamlıyor ama kesesi **-271 GG** (eskiden +86), aç
sefer %14 (eskiden %6). Yani yetkin oyuncu artık bıçak sırtında.

**Fidyenin tabanı.** "Fidyeler en az 5 kişilik bir ekibin bir haftalık
erzağı kadar olmalı" → `RANSOM_FLOOR_PROVISIONS` 35, `RANSOM_FLOOR_GOLD`
140. Haydut pususu 80/130/190 → **140/210/290**; haydut kervansarayı 50 →
240 (pazarlıkla 140'a iner); haraç 70 → 140, erzakla 8 → 35. Gümrük
rüşveti (80 GG) dokunulmadı - rüşvet fidye değil.

**Blöfün tavanı.** `SkillCheck`e `ceiling` alanı eklendi; blöfünki 70.
"Çok zeki bir kervanbaşı 10 haydut liderinden 7'sini dolandırabilsin
sadece" - zekâ ne kadar yükselirse yükselsin şans %70'i geçmiyor. Zorluğu
yükseltmek bunu çözmezdi: yeterince yüksek bir stat yine %95'e çıkıyordu.

**Lafa bakmayan çete.** `is_raid_deaf()` - kervanın adı ve günden tohumlu,
%20. O gün blöf seçeneği sebebiyle kapalı: "Reis lafı kesiyor: bu çete
konuşmaya gelmemiş." Ekranda doğrulandı.

**Erzak isteyen yağmacı** (`evt_provision_raid`, "Un İsteyenler"). Altın
da mal da istemiyorlar. Blöf yok ve olamaz - bir çuval unu paha biçilmez
diye yutturamazsın, karşındaki onu yiyecek. Yerine Karizma: tutarsa
yarısına (17 erzak) razı olurlar, tutmazsa 35'i alıp bir de kırılırsın.
Kıtlık derinleştikçe ağırlığı 2,4 kat artıyor. Ekranda doğrulandı:
"Daha azına ikna etmeye çalış — Veysel · Karizma · %50".

Dövüş garantisi ölçümü yeniden koşuldu: üç muaf olmayan yolda hâlâ %100.

## Soru defteri IV işlendi (2026-11-07)

Defterin kendisi: https://claude.ai/artifact/DsC1PMXP2y4WnwH9mXgFHR (24 cevap, veritabanından okundu).

**Kanona geçen (16 onay):** coğrafyanın adları (Ağıt Denizi, Gelgit Denizi, Kemersu, Karaocak Sırtı, Taşkök,
Kemersal Ormanı, Ayazkaya Çamlığı), kadim yurdun yeri, Sürü Yılı takvimi ve dört çağ, Mirsana'nın yedi tüccar
evi, Gelgit Kıyısı'nın deniz ağzı, Vadi savaşlarının tarafları, asker kaçaklarının kimden/nerede/nasılı,
haydutun mal istemesi, "ya paran ya canın"ın bir çizgi olması, kervanın muhafız tutmaması, dağılma,
dilencilik, dolandırıcılık, el tutma ve kervan adının töresi.

**Düzeltmeler (5) ve sildikleri:**
- **Kıtlığın sebebi İllet.** Büyü ya da mevsim değil: veba işgücünü yok etti, üretim düştü, ambarlar bir daha
  dolmadı. T31 (uzayan kış / solgunluk), T32 (kıtlık imparatorluğun son yıllarında başladı) ve T33 (deli kral
  kıtlığı büyücülere yükledi) **silindi**.
- **Altmış yılın çizgisi** (TARIHCE §VIa, yeni): çöküş 60 yıl önce → 35 yıl barış → İllet → Gokyurt sınırını
  kapatır → 5 yılda krallıklar yenilir → 40. yılın sonunda kıtlık → son 20 yıl hastalık ve savaş → bugün bazı
  devletler göçebe topraklarına göz dikiyor ama harekete geçmedi. Kıtlık yirmi yaşında, kırk değil.
- **Deli kral** imparatorluğun son yöneticisiydi, katliam kıtlıktan önce. Yeni açık soru: kıtlık yokken
  büyücüleri neden katletti?
- **Baikhan ve Gokana bir varlık değil:** Baikhan yer ve gök, Gokana su ve yağmur; birbirini tamamlarlar.
- **Kaçak ihbarının itibarla sonucu yok** (iyisi de var kötüsü de). `evt_deserter_search`in +1 itibarı
  kaldırıldı; kalan bedel yalnız stres.

**Oyuna dokunanlar:**
- Vebanın adı **İllet** oldu: ui/events/game CSV'lerinde 14 metin (İngilizcede "the Affliction").
- `EVT_LEVY_TEXT` yeniden yazıldı: kaçak para değil yiyecek istiyor, bölük dağıldı, dönecek yer yok.
- Yeni görev **Y-E13**: dağılan tayfanın yolda karşına çıkması kartı (kullanıcının kendi önerisi).

**Yeni açık sorular:** deli kralın gerekçesi; imparatorluğun Sürü Yılı'na verdiği ad ve hikâye.
**Onay bekleyen üç türetme:** T49 (göçebenin tapınağı yok), T50 (kıtlık eğrisi idarenin tükenmesini anlatır),
T51 (üç kuşak üç dünya).

## Dünya kitabı: tek belge (2026-11-07)

**Kullanıcının isteği:** "T49 ONAYLI, diğerleri için de sen kendi cevaplarını üret ve lore'a ekle... tüm lore
ve tarihçeyi tara, coğrafyayı, tarihi, lore'u, inanışları. Elimizdeki tüm bağlamı kategorize et ve birbirine
bağla, çelişkileri düzelt, boşlukları doldur benim yazdıklarımı çiğnemeden. Tek bir doküman oluştur ve ileride
bu dokümana bakarak oyun içi diyalogları ve metin kaynaklarını üretebileceğin bir yapıda olsun."

**Sonuç: `docs/lore/SIDERIA.md`** (1689 satır, 16 bölüm). Dört belge orada birleştirildi ve **silindi**:
`LORE.md`, `TARIHCE.md`, `SORULAR.md`, `ONERILER_III.md` (git geçmişinde dururlar). Bundan sonra lore, tarih,
coğrafya, inanç ve oyun içi metin yalnızca bu belgeden üretilir; yeni lore belgesi açılmaz.

**Bölümler:** 0 nasıl kullanılır (işaretler, iki değişmez kural, metin üretirken izlenecek yol) · 1 dünya bir
bakışta + **beş omurga** · 2 zaman (dört çağ, takvim, altmış yılın çizgisi, üç kuşak) · 3 görünmeyen dünya ve
derin geçmiş · 4 imparatorluk · 5 İllet ve kıtlık · 6 coğrafya · 7 halklar ve diller · 8 inançlar · 9 güçler
ve ilişkiler ağı · 10 **11 bölge ve 27 yerleşim** (her yerleşimde kalp / gelenek / kıtlık) · 11 adı konmuş
yerler · 12 yolun töresi, kaçaklar, kervanın adı, bölgesel düşmanlar · 13 gündelik hayat · 14 **söyleyiş**
(kim neye yemin eder, neye küfreder; aynı haberin altı okunuşu) · 15 **metin üretim kılavuzu** (14 kaynak türü
için uzunluk, ses, yasak) · 16 karar günlüğü, asla söylenmeyecekler, kullanıcıya ait kararlar.

**Yeni işaret:** **[Karar]** = kullanıcının 2026-11-07'de verdiği yetkiyle benim verdiğim karar; kanon gibi
kullanılır, bir [Yazar] satırıyla çakışırsa yanlıştır ve silinir. Sıra: [Yazar] > [Oyun] > [Harita] > [Karar].

**Karara bağlanan açık sorular (benim cevaplarım):**
- **Deli kral neden katletti:** hastalandı, Raviellon'da eğitilmiş büyücülerden **ömür** istedi; büyü kendi
  yaşam enerjisidir, kimse başkasının ömrünü uzatamaz. Reddi ihanet, denemeleri "yapabiliyorlar ama
  yapmıyorlar"ın kanıtı saydı ve hepsini yazlık sarayının avlusunda yaktırdı. Altı kaynak altı ayrı şey
  anlatıyor (§4.2), hiçbiri doğrulanmıyor.
- **Kullanıcının aynı gün verdiği iki düzeltme [Yazar] (işlendi):**
  - **Göçebe savaşının sebebi asimilasyon:** imparatorluk boyları **tek tek** asimile etmeye çalıştı, boylar
    direndi, sonunda **dokuz boy birleşip** savaştı. Benim "bozkır karakolları otlak bedeli koydu, kurak yıl
    taşınmaz hâle getirdi" gerekçem düştü. Yeni [Karar] dokusu: asimilasyon oba oba yürüdü (beye
    "imparatorluğun beyi" denmesi, obaya kâtip, Sogurtay suyundan okumanın "Kitap'ın bir satırı" ilan
    edilmesi, otlağın deftere yazılması); birlik Sogurtay konseyinde kuruldu; **Baikhan'ın hiç asimile
    edilememesinin sebebi bu savaştır**, inancın gücü değil.
  - **Deli imparatorun sonu:** savaşın sonlarında **kendini bir ayinle yakarak ölümsüz kılmaya çalıştı ve
    öldü** — büyücüleri yaktırdığı aynı avluda, çünkü ayinin işlemeyeceğini söyleyecek herkesi kendi eliyle
    yakmıştı. Benim "hastalığından bir yıl sonra öldü, göçebeler o boşluğa yürüdü" satırım düştü. Böylece
    üçüncü omurga (§1.2/3, kendine ait olmayan yaşamı almak) kadimlerden imparatora doğrudan bağlandı; oyun
    bu bağı hiçbir yerde kurmaz.
- **İmparatorluğun takvime verdiği ad:** aynı gün, üç ad — göçebe **İlk Ot**, imparatorluk/Vaelghard **Yol
  Günü** (Septimar'ın fermanı anlatıyı tersine çevirdi: ot yolu değil yol otu getirir; büro yine otlağa atlı
  yollar ve bunu herkes bilir), kilise **Sayfa Günü**. Üç yıl sayma biçimi: Ferman yılı / çöküşten beri /
  Sogurtay suyunun tadı.
- **T49 onaylandı** (göçebenin tapınağı yok), **T50** ve **T51** karara bağlandı; defter III'ün bütün
  önerileri (T4, T34-T48, 27 yerleşim taslağı, takip/yer/coğrafya/geçmiş soruları) [Karar] olarak işlendi.
- Ayrıca kararlaştı: imparatorluğun adı **Vael** ve dört yüz yılı; Merigard'ı kimin yaktığının bilinmemesi;
  kadim taşları batıya kimin taşıdığının bilinmemesi; Bekçi Kadın'ın iki adı (Yolcu Ana, Yolkiz); Büyük Han
  **Kaytaş**; Orbeyan'ı **Kutlay Ana** işletir; yasaklı iki inancın kendi adları (Saban Yolu, Sürü Sözü) ve
  kilisenin inançları yer adıyla anma yöntemi; GG'yi Orsolune basıyor, Orvahel kapıda yeniden damgalıyor.

**Çelişkiler:** Ç1-Ç14 kapandı. Kullanıcının geçersiz kıldığı ve bir daha kullanılmayacak satırların listesi
§16.1'de (uzayan kış/solgunluk, kıtlığın imparatorluk sonunda başlaması, deli kralın eski gerekçesi,
"Baikhan gök Gokana toprak", Gelgit Kıyısı'nın balıkçı yurdu olması, ihbarın itibar etkisi, Uzun/Sabah Denizi
adları, Vadi nehrinin "Vael Suyu" adı, sunakların dörde inmesi, senaryo sistemi).

**Hâlâ kullanıcıda:** (1) kadim uygarlığın sonu — oyunda hiç söylenmeyecek, benim duran önerim §16.3'te;
(2) oyunun hikâyesi, kampanyası ve ona ait diyaloglar (kullanıcı kendisi yazacak).

**Dokunulan dosyalar:** `docs/lore/SIDERIA.md` (yeni), `LORE_OZET.txt` (başlık ve karar bölümü yenilendi),
`CLAUDE.md` Ana Hedefler, `CLAUDE_BASLANGIC.md`, `docs/design/TASARIM.md`, `docs/history/FAZ_ANLATILARI.md`,
`.claude/skills/wayborne-lore` ([Karar] işareti ve tek belge kuralı), `wayborne-metin`, `kurallar-savas`,
`tools/lore_soru_sayfasi.py` ve `lore_defter3_banka.py` (defter III kapandı, çıktısı tarihsel kopya),
kod yorumlarındaki LORE.md başvuruları (`enemy_catalog`, `event_catalog`, `outfit_catalog`,
`test_combat_core`), görev Y-E06 (durum: "lore kapandı, hikâye kullanıcıda").

## El çizimi takip sayfası (2026-11-08)

Kullanıcı: "elde çizmem gereken tüm kaynakların yerini belirt, nasıl çizmem gerektiğini açıkla, GitHub'a nereye
yükleyeceğimi anlatan ve ne kadar kaldığını takip eden bir artifact hazırla (güncelle dediğimde GitHub'a bağlanıp
ölçüm yapsın)."

**Sayfa:** https://claude.ai/artifact/2n5snQZu3vRhhQSv6K2cPk (özel; `db` + `user` yetenekleri, ikon brush).
İçinde: 714 kalemin tamamı (süzgeç + arama), her kalemin kartı (ne çizilecek, tuval, katmanlar alttan üste,
teslim biçimi ve kopyalanabilir dosya adı, renklendirme kuralı, oyundaki hedef dosya, bugünkü kaynak, tahmin,
bağımlılık, tipine göre öğütler), altı başlıkta nasıl çizilir rehberi, yükleme adımları ve klasör haritası,
öncelik/kategori ilerleme çubukları, "sırada ne var" (öncelik 1'den en kısa altı iş).

**Ölçüm depodan:** `art_source/el_cizimi/islenmis/<KİMLİK>/` → oyunda, `gelen/<KİMLİK>.*` → yüklendi, yoksa
bekliyor. Araç: `tools/el_cizimi/ilerleme.py` (`--yaz` → `docs/el_cizimi/ilerleme.json`, `--sayfa <yol>` →
şablondan sayfayı üretir). Şablon: `docs/el_cizimi/takip_sayfasi_sablon.html` (`__VERI__` yer tutucusu).

**"Güncelle" iş akışı (kullanıcı bu sözü yazınca):**

    git pull && python3 -I tools/el_cizimi/ilerleme.py --yaz --sayfa <scratchpad>/el_cizimi_atolyesi.html
    Artifact publish → aynı file_path (URL korunur; açık sayfa kendi tazelenir)

Yayınlanmış sayfa özel depoya kendisi bağlanamaz (artifact CSP'si dış fetch'i kesiyor); ölçümü bu oturum yapar.
Sayfadaki "çiziyorum / bitti / takıldım" işaretleri `durum` koleksiyonunda; ArtifactData ile okunabilir
(deneme belgesi yazılıp silindi, yazma ve okuma çalışıyor).

**Bugünkü ölçüm:** 714 kalem, 2053 saat tahmin, 0 oyunda, 0 yüklendi; AI kaynaklı 183 (öncelik 1).
Excel 714 satıra yeniden üretildi (691'di). SUREC.md'ye sayfa ve güncelleme komutu yazıldı.
