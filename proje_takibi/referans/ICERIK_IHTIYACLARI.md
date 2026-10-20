# Senden gereken içerik ve bulunan kaynaklar

**Tarih:** 2026-10-17 · **Bağlı:** `YAPILACAKLAR.md` (Kim sütunu `CI` ve `S` olan görevler), `IS_DAGILIMI.md`.

Bu dosya iki şey söylüyor:
1. Oyun için **senden** gelmesi gereken içerik ne, hangi görevi bekletiyor.
2. Her içerik için **önce benim aradığım** CC0 ya da serbest kaynaklar ve onları hangi teknikle kullanacağımız. Kaynak bulamadığım yerler “Sana kalan” diye işaretli.

**Lisans kuralı:** Öncelik CC0 (kamu malı). CC-BY ya da OFL kullanılabilir ama künye ister; künye `CREDITS.md`'ye yazılır. NC (ticari olmayan) ya da ND (değiştirilemez) lisanslı hiçbir şey kullanılmaz. Senin isteğinle CC0 üreticileri de gönüllü olarak `CREDITS.md`'ye eklenir (Y-J05). Ticari oyun referans görsellerinin pikselleri depoya girmez (`gorevler/00_kurallar.md`).

**İndirme kuralı:** Bu raporda hiçbir dosya indirilmedi. Bir kaynak kullanılacağı zaman: lisans sayfasının o günkü kopyası (ekran görüntüsü ya da PDF) `art_source/licenses/` altına konur, dosya adı ve kaynak bağlantısı `LICENSES.md`'ye işlenir.

---

## A. Yalnızca senden gelebilecek içerik

| # | İçerik | Bekleyen görevler | Ne lazım | Ben ne yapabilirim |
|---|---|---|---|---|
| A1 | **Lore ve tarihçe** | Y-E06 → Y-C01, Y-C09, Y-C12, Y-E01, Y-E02, Y-E04, Y-E08, Y-C18, Y-A07, Y-I02 | `SORULAR.md` coğrafya soruları, “Yolda doğan kim?” çelişkisinin çözümü, bölgeler arası siyasi ilişkiler (dostluk, düşmanlık, ticaret), inançlar ve dünya sırrı, büyünün dünyadaki yeri | Soruları tek tek önüne koyarım, cevaplarını lore belgesine işlerim, çelişkileri gösteririm. Karar senin. |
| A2 | **Adlar** | 1.1 (mezra yerine), 8.7 (boğaz), Y-C13 (şehir kişileri), Y-C09 (bölgesel düşman adları), yeni eşyalar (Y-C06) | Onay | Kurala uygun ad listeleri öneririm (başka eserlerden ve gerçek tarihten değil, birbirine benzemeyen). |
| A3 | **Kampanya bölümleri** | Y-C18 | Bölümlerin hikâyesi | Taslak yazabilirim; ama senin notun gereği bölümleri sen yazıyor ya da onaylıyorsun. |
| A4 | **Babadan devir açılışı** | Y-C14, Y-D04, Y-H01 | Babanın adı, hastalığı, borcun kime olduğu, açılış sahnesinin tonu | Sahne metni ve sahne tahtası taslağı. |
| A5 | **Dünya sırrı** | Y-E04 | Sırrın kendisi (yalnızca geliştirici bilir) | İpuçlarını oyuna dağıtırım. |
| A6 | **Playtest** | Y-A06, Y-H02 | Haftalık bir saatlik oyun, video kaydı, beş dış oyuncu | Her döngü için kontrol listesi ve ölçüm raporu hazırlarım. |
| A7 | **Steam hesabı ve sayfası** | Y-J01T, Y-J04 | Steamworks hesabı (uygulama başına 100 $ ücret; kesin tutarı Steamworks'te kontrol et), vergi ve banka bilgileri, sayfa yayını | Sayfa metni, etiket önerisi, görsel listesi, demo derlemesi. Ödeme ve kimlik bilgilerine dokunamam. |
| A8 | **Kapsül sanatı** | Y-J02 | İnsan eliyle yapılmış kapsül (sen, eşin ya da ücretli sanatçı) | Brief, ölçüler (Steam'in bütün kapsül boyutları), referans tahtası. Ücretli iş için maliyet tahmini. |
| A9 | **El çizimi** | Y-J06 | AI görsellerinin elle yeniden çizimi (Kasım sonu) | AI ile üretilmiş görsellerin listesi ve öncelik sırası. |
| A10 | **Fragman kurgusu ve yayın** | Y-J03, Y-J08 | Kurgu, müzik seçimi, devlog paylaşımı | Godot'nun film kaydı kipiyle (`--write-movie`) ham görüntüleri ben çekerim; sahne tahtasını ben yazarım. |
| A11 | **Fiyat kararı** | Y-J10 | Karar | Seçenekler ve gerekçe `gorevler/13_yonetmen_onerileri.md` Y-J10'da. |
| A12 | **Varis sahnesi videosu** | Y-D04 | Ücretli üretim olacaksa onay | Sahne tahtası; oyun içi gerçek zamanlı sahne olarak da kurulabilir (ücretsiz). |

---
## S. Ses ve müzik: bulunan kaynaklar

Tam rapor, lisans sayfalarının bağlantılarıyla: `belgeler/kaynak_arastirmasi/CC0_SES.md`. Senin notuna göre sesleri Gemini ile de üretiyorsun. Sıra: önce CC0, eksik kalanı Gemini; Gemini'den gelenler Steam beyanına yazılır (Y-J05).

| # | İhtiyaç | Görev | Kaynak (lisans) | Teknik |
|---|---|---|---|---|
| S-1 | Yol ambiyansı: biyom × gün saati (orman, bozkır, dağ, bataklık, nehir, gece böcekleri, şafak kuşları, rüzgâr, yağmur, fırtına) | Y-I01, Y-G07, Y-G16 | **Freesound CC0** (`forest ambience night` 130 sonuç, `thunder` 2.783, `rain on canvas`, `crickets night`), **BigSoundBank** (CC0) | 30–90 sn döngüler, −20…−18 LUFS, döngü noktasında 1–2 sn eşit güç geçiş. Bus: `Master > Ambience > {Bed, Weather, Spot}`. Gün saati değişince iki oynatıcı arasında 4–8 sn geçiş. Spot sesleri `AudioStreamRandomizer` ile 8–25 sn arayla. Olay kartı açılınca Ambience −6 dB. Sis sessizliği ayrı bir ses değil: düşük rüzgâr ve alçak geçiren filtre. Ana menü: müzik yok, gece ormanı ve ateş, yaklaşık −22 LUFS. |
| S-2 | Kervan: tekerlek gıcırtısı, toynak, horlama, koşum şıngırtısı, köpek, grup ayak sesi, sandık ve çuval | Y-I01, 10.4 | **Freesound CC0** (craigsmith `Buckboard Creaking`, `Horse Muffled Hooves on Dirt`; inek sesleri öküz yerine), **OpenGameArt CC0** (RPG Sound Pack zincirleri, TinyWorlds ayak sesleri), **Kenney RPG Audio** | Tekerlek tek döngü, perdesi hıza bağlı (`0.9 + hız × 0.2`). Toynak adım başına randomizer (en az 6 varyasyon), zemine göre değişir. Grup ayak sesi 3–4 kaydın zaman kaydırmalı katmanı. |
| S-3 | Kamp: ateş çıtırtısı, ateşin tutuşması, tencere, anlaşılmaz konuşma uğultusu, fener gıcırtısı | 12.2c, Y-B12, Y-C20 | **Freesound CC0** (`campfire` 114 sonuç, `torch ignite`, `match strike`, `lantern creak`, `stew boiling`) | Ateşte taban döngü ve ayrı çıtırtılar. Uğultu: İngilizce mırıltı kaydı alçak geçiren filtre (~1,2 kHz), ters çevirme ve perde kaydırmayla anlaşılmaz yapılır. |
| S-4 | Şehir: pazar kalabalığı, uzak demirci, büyük kapı, taverna | 12.2a, Y-G10T, Y-I01 | **Freesound CC0** (bolkmar “Crowded street at medieval market”, ldezem demirci kaydı, `tavern` 94 sonuç) | Uzaklık için alçak geçiren filtre ve yankı. Kapı için hazır kayıt yok: `large wooden door` + `chain rattle` + `winch` katmanı. |
| S-5 | Savaş: kılıç, balta, künt vuruş, ok, kalkan, inilti, kurt, geyik, panik | 9.8, Y-G05, Y-H05 | **Freesound CC0** (`sword clash` 132, `arrow impact` 49, `wolf howl` 72, IENBA “Crowd in panic”), **OpenGameArt** RPG Sound Pack ve Battle Sound Effects, **Kenney Impact Sounds** | Vuruş başına üç katman: metal çınlama + künt gövde + zırh ya da kumaş kuyruğu. Her katmanda randomizer, perde ±%5–8, tekrarsız. |
| S-6 | Arayüz ve defter: kâğıt, sayfa, tüy kalem, mühür, para, kitap kapanması | 9.11, Y-B08, Y-D04 | **OpenGameArt** 80 CC0 RPG SFX (4 kitap sesi), **Kenney** 50 RPG SFX, **Freesound CC0** (brktkrgll “Ink Quill Writing on Parchment”, Cerise_Virtuelle “Wax seal”) | Ayrı `UI` bus'ı. Sayfa çevirmede en az 5 varyasyon, perde ±%4. |
| S-7 | Müzik: gerilim katmanları, yas teması | Y-I02 | **OpenGameArt RandomMind** (CC0; “Lament for a Warrior's Soul” yas teması adayı), OpenGameArt CC0 dark ambient drone'lar. **FreePD kapandı, kullanılmaz.** | Hazır stem yok: CC0 drone + Freesound CC0 tek vuruşlardan (frame drum, taiko, bodhran) 90 BPM döngüler + CC0 cello drone ve bowed metal gerilim katmanı, hepsi aynı tonalitede. Godot 4.2'de `AudioStreamSynchronized` yok (4.3+); karar P00'da. |
| S-8 | Anlatıcı sesi | Y-I03 | **CC0 yok.** Kokoro-82M (Apache-2.0) yalnızca İngilizce; Piper `lessac` ticari kullanıma kapalı | Senin kararın: Gemini ile; Steam beyanına girer. |

**Kullanılabilir ama CC0 olmayanlar:** Sonniss GDC paketi (atıf gerekmez; sesleri ayrıca dağıtmak ve **YZ'ye örnek olarak vermek yasak**, yani Gemini'ye beslenmez), Pixabay (atıf gerekmez; hak talebi gelirse kullanımı hemen durdurma maddesi var). **Künye zorunlu:** Freesound CC-BY sesleri, Kevin MacLeod. **Kullanılmaz:** Freesound NC ve Sampling+, BBC ses arşivi.

## G. Görsel: bulunan kaynaklar

Tam rapor: `belgeler/kaynak_arastirmasi/CC0_GORSEL.md`.

**Önemli:** Quaternius'un lisansı 28 Ağustos 2026'da değişmiş. Paket sayfaları hâlâ “CC0” yazıyor, lisans sayfası “Quaternius Asset License v1.0” diyor. Elindeki eski indirmeler CC0 kalır; **yeni indirmeler QAL** (ticari ve atıfsız kullanım serbest, modelleri ayrıca dağıtmak yasak). Her yeni indirmede tarih ve lisans sayfasının ekran görüntüsü saklanır.

| # | İhtiyaç | Görev | Kaynak (lisans) | Teknik |
|---|---|---|---|---|
| G-1 | Saç, sakal ve başlık | Y-G03 | MakeHuman topluluk paketleri: **hair01, bodyparts05, hats01, hats02, suits02** (CC0); hats03, hats04, hair02/03, bodyparts06 (CC-BY, künye zorunlu). MPFB çıktısının kapalı kaynak oyunda kullanımı serbest. | `monk_robe_hood` sadeleştirilip kervan kukuletası olur; miğferlerdeki dinî semboller kaldırılır. Türban, sarık ve kalpak Blender'da modellenir (kumaş simülasyonu, kürk parçacığı). |
| G-2 | 3B nesne ve yapı: sur, kule, kapı, çadır, kamp ateşi, fıçı, tezgâh, mezar, harabe | 12.2a, 9.10, 9.12, Y-G07, Y-B11, Y-A07 | **Kenney** Castle Kit, Survival Kit, Fantasy Town Kit, Graveyard Kit (CC0); **Quaternius** Medieval Village MegaKit, Fantasy Props MegaKit, Ultimate Modular Ruins (yeni indirme QAL); **Poly Haven** `Lantern_01` ve diğerleri (CC0). Poly Pizza ve OpenGameArt'ta yalnızca CC0 filtresiyle. | Ortak şablon `.blend`: tek renk gri malzeme, Depth, Normal ve ışık geçişleri, mürekkep konturu, 3 eşikli tarama, kâğıt Multiply. Yapılarda yandan ve 3/4 iki render. |
| G-3 | Hayvanlar: at, öküz, eşek, köpek, kurt, ayı, yaban domuzu, geyik | Y-G05, Y-C09 | Quaternius Ultimate Animated Animal Pack (elde), OpenGameArt **yaban domuzu** (Teh_Bucket), **kurt** (NewDLC), **geyik** (crownjoshua), hepsi CC0; OpenGameArt “CC0 3D Animals/Creatures” koleksiyonu (her öğe ayrıca kontrol edilir) | Yan profilden 8–12 karelik yürüme ve koşu döngüsü. Animasyonu olmayana Rigify ile basit yürüyüş. Siluette 2 px kontur. |
| G-4 | Dokular: toprak yol, çimen, kaya, çamur, kar, ahşap, kumaş, deri, kâğıt | Y-G02, Y-G07 | **Poly Haven**, **ambientCG** (CC0); kâğıt için **TextureCan** Paper 0027, 0006, 0024 (CC0) | Kâğıt dokusu her katmana Multiply. Tarama dokuları hazır yok, kendimiz üretiriz (3 ton, 512² döşenebilir). En özgün kâğıt: kendi kâğıdının 600 dpi taraması. |
| G-5 | Gravür ve harita referansları | Y-G04, Y-G09, 8.8 | **Carta Marina** (Wikimedia, PD Mark), **Rijksmuseum** ve **Met** CC0 işaretli görseller, **Biodiversity Heritage Library** kamu malı eserleri, **Old Book Illustrations** görselleri (açıklama metinleri NC, kopyalanmaz), Public Domain Review'da yalnızca “No Additional Rights” olanlar | Doğrudan: yalnızca PD ve CC0. Harita süsleri ve dalga taraması gibi teknikler izlenir; gerçek adlar ve kıyılar alınmaz, dinî figürler çıkarılır. Hayvan gravürleri yalnızca duruş ve tarama yönü referansı, elle yeniden çizilir. **David Rumsey haritaları kullanılmaz (NC).** |
| G-6 | Mürekkep ve tarama shader'ları, efekt dokuları | Y-G02, Y-G06 | godotshaders “Post-Process Outline (Depth/Normal)” ve “Advanced Hatching” (CC0), “Hatching shader” (MIT); Blender Line Art ve Freestyle (çıktı serbest); David Revoy 2023 Krita fırça kiti (CC0) | Sprite'lar Blender'da çevrimdışı pişirilir; Godot'ta yalnızca kâğıt overlay, fener ışık maskesi ve kırmızı dışı desatürasyon. GPLv3 shader yok. |
| G-7 | Arayüz: çerçeve, düğme, ikon, süs | 9.1, Y-C06 | **Kenney** UI Pack RPG Expansion ve Fantasy UI Borders (CC0); **game-icons.net** (CC BY 3.0, künye zorunlu); Old Book Illustrations süsleri | Çerçeveler kâğıt ve mürekkep diline yeniden boyanır. İkonlara hafif “mürekkep taşması” filtresi. |
| G-8 | Yazı yüzleri | Y-G14, Y-J13 | SIL OFL 1.1: IM Fell English (yalnızca temel Latin; Türkçe ğ, ş, İ, ı eksik olabilir), **EB Garamond** (Türkçe ve Kiril), Cormorant Garamond, Old Standard TT, **Noto Serif SC** (Çince) | OFL metni dağıtıma, Credits'te liste. Çince için EB Garamond'un arkasına fallback. |
| G-9 | Steam kapsülü | Y-J02 | Kaynak değil, kural: yalnızca sanat ve logo; Header 920×430, Small 462×174, Main 1232×706, Vertical 748×896 | İnsan eliyle (sen, eşin ya da sanatçı). |
| G-10 | Kısa video ve fragman araçları | Y-D04, Y-J03 | Blender (Grease Pencil, VSE), Krita, OpenToonz (çıktılar senin); Godot `--write-movie` | Kâğıt kesik tekniği: sprite parçaları düzlemlere, 12 fps. Haritada mürekkep çizgisinin akarak ilerlemesi (Grease Pencil Build modifier). |

## L. Künye düzeni (CC0 dahil)

Senin isteğin: CC0 üreticileri de anılsın (Y-J05).
1. Tek künye kaydı: `dosya | kaynak | yazar | URL | lisans | lisans sayfası | indirme tarihi | değişiklik`. Ses için ayrıca `audio/CREDITS.csv`.
2. Derleme kontrolü: varlık klasöründe künyesi olmayan dosya ya da lisansında NC, ND ya da Sampling+ geçen satır varsa derleme durur.
3. CC-BY varlıklar oyun içi Credits ekranında zorunlu (yazar, eser, lisans ve bağlantısı, “değiştirildi” notu). CC0 üreticileri gönüllü teşekkür bölümünde.
4. OFL ve MIT lisans metinleri dağıtım klasörüne.
5. Quaternius, Sonniss ve Pixabay indirmelerinde lisans sayfasının o günkü kopyası saklanır.
6. YZ ile üretilen her dosya künyede `kaynak: YZ (Gemini)`; Steam beyanı buradan doldurulur.

## Sana kalanlar: kaynak bulamadıklarım

| # | İhtiyaç | Görev | Neden bulunamadı | Öneri |
|---|---|---|---|---|
| K-1 | Türban, sarık, kalpak, ayrı kukuleta (CC0) | Y-G03 | MPFB için CC0 yok; yalnızca CC-BY başörtüsü ve sherpa şapkası | Blender'da modellenir (yapabilirim) ya da CC-BY olanlar künyeyle kullanılır. Karar senin. |
| K-2 | Rig'li ve animasyonlu kaliteli ayı | Y-C09, Y-G05 | Yalnızca “White Bear (Low poly)”, rig durumu belirsiz; gerçek ayı sesi de zayıf | Gemini ya da kendi render'ımız; ses için Sonniss ya da Pixabay'e bakılabilir. |
| K-3 | Öküz ve eşek modeli | 10.4 | Elindeki Quaternius paketinde boğa ve eşek olabilir; doğrulanmadı | Paketi açıp bakarım. |
| K-4 | Kaliteli kapalı kervan vagonu (CC0) | — | Yalnızca Quaternius `Cart` ve CC-BY modeller | Mevcut vagon render'ın sürer. |
| K-5 | Doğu ve bozkır tarzı çadır ve tezgâhlar | Y-G10T, 9.4 | Kenney ve Quaternius Batı ortaçağı tarzı | Kendi modelimiz ya da Gemini. |
| K-6 | Balmumu mühür, defter cetveli ve tablosu | Y-D04, 9.11 | Kaliteli CC0 kaynak yok | Özgün tasarım (yapabilirim); el çizimi istersen senden. |
| K-7 | Uyarlanabilir müzik stem'leri ve oyuna özgü yas teması | Y-I02 | Hazır CC0 stem yok | Gemini, arkadaşın ya da bestekâr. |
| K-8 | Türkçe anlatıcı sesi | Y-I03 | CC0 ya da uygun açık TTS yok | Gemini (beyanlı) ya da insan seslendirme. |
| K-9 | Zincirli büyük ahşap kapı, kurgusal dilde uğultu, mürekkep sıçrama vuruşu, çeşitli yaban domuzu sesleri | 12.2a, Y-I01 | Hazır CC0 kayıt yok | CC0 parçalardan katmanlayarak tasarlarım ya da Gemini. |
| K-10 | Kapsül ve ana tanıtım görseli | Y-J02 | Steam ve inceleme riski yüzünden insan eliyle olmalı | Sen, eşin ya da ücretli sanatçı. |

**Doğrulanamayan kaynaklar** (sayfalar erişim hatası verdi; indirmeden önce elle bakılmalı): Rawpixel, NGA, Library of Congress, British Library Flickr, Met politika sayfası, Sketchfab lisans filtresi, Musopen.
