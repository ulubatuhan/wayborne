# 3 — Yaratıcının Vizyonu: Wayborne (Temmuz – 16 Ekim 2026)

> Kaynaklar: ana geliştirme oturumunun ~590 anlamlı kullanıcı mesajı (28.08–16.10.2026),
> claude.ai sohbetleri (`game_design` 17.07–12.09, `Marketing`, `Websayfa`, `Wayborne_Legal`,
> `Makaleler`, `Texture İyileştirmeleri`, `Wayborne Harita Üretimi`), proje belgeleri
> (`game_pitch.md`, `game_design.md`, `wayborne_marketing_context.md`, `sanatci_rehberi.md`),
> depodaki `docs/lore/*`, `GELISIM_GECMISI.md`, `AI_DISCLOSURE.md`, `CLAUDE.md › Ana Hedefler`.
> Alıntılar kullanıcının yazdığı haliyle (yazım hataları korunarak), kısaltılarak verildi.
> Tarih biçimi: GG.AA (yıl 2026).

---

## 0. Tek paragrafta vizyon

Wayborne, Sideria adlı tek bir kıtada geçen, yandan görünümlü, 2D, karanlık ("grim")
bir **kervan yönetimi / ticaret / hayatta kalma RPG'si**. Oyuncu şehirden şehre mal ve
yolcu taşır, deadline'a yetişmeye çalışır, borca batar, pazarlık eder, yolda EU4 tarzı
olay kartlarıyla ve referans oyun tarzı savaşla karşılaşır. Asıl konu kervan değil,
**kervanı çeken insanlar ve onların aşınması**; kervan "yıkılabilir ama yok olmaz",
lider ölünce ad bir sonrakine geçer. Yaratıcının hedefi bir demo değil, "mükemmel"
bir oyun: "yarısı büyüklüğünde bir baldurs gate" kapsamında, sistemleri en zengin yanı
olan, referans oyun / Frostpunk / This War of Mine gibi "oyuncunun içinde yer eden"
bir deneyim. Dünya Ortaçağ Avrupa'sı, Türk göçebe bozkırı ve Venedik-vari ticaret
kentlerinden esinlenir ama hiçbir gerçek adı/imgeyi taklit etmez.

---

## 1. Çekirdek vizyon, fantezi, ton ve ilham kaynakları

### 1.1 Fantezi ve çekirdek döngü
- 17.07 (game_design): "bir kervanımız var ve bu kervanı yöneten kişi biziz, fantastik bir dünyada harita üzerinde ilerliyor ve şehirden şehire mal ve yolcu taşıyoruz."
- 17.07: "Oyundaki temel akış bir şehirden diğerine sağ salim deadline'dan önce kervanı götürebilmek ... kar ve reputasyon elde etmek, bu süreçte de sanity gibi metrikleri korumak."
- 17.07: "detaylı fakat oynanışı kolay bir oyun hayal ediyorum."
- 17.07: Zincirleme rota: "euro truck simulator gibi ... a şehrinden mal alıp bunu önce b'ye bırakıp sonra c'ye gider ... Death stranding gibi de düşünebilirsin."
- 23.07: "sonuç olarak bir kervan olmalıyız, ordu değil."
- 11.09: "Oyunda sonu olan bir hikaye olacak fakat sonsuza kadar (eğer başarılabilirse) ticarete devam edilebilir de olacak."
- 11.09: Kapsam: "Bu oyun yarısı büyüklüğünde bir baldurs gate gibi olacak o yüzden çok iyi dizayn etmeli kod tabanı."
- 22.09 (Makaleler): hikâye "uzun metinler veya diyaloglar yerine ... sistem mekanikleri, çevre tasarımı ve oynanış üzerinden (systemic storytelling)" anlatılacak.
- 17.09 (eski notlar): "Oyundaki kararlarımız bir kelebek etkisi yaratmalı." / "Oyunda gelişme başarma hissi olmalı."

### 1.2 Ton
- Pitch (Temmuz): temel duygular — "Bir sonraki şehre yetişme çabası, karar anındaki gerilim, yolun verdiği yalnızlık, ... pişmanlık." Slogan: "kervan durduğunda her şey durur."
- 15.09: amaç "referans oyun dungeon, frost punk ya da this war of mine gibi çok özel hissettiren mekanik ve art dokunuslarini bulmaliyim."
- 17.09: "Oyunumuz şu an için çok vanilla, dümdüz bir kervan oyunu gibi. Bu hissiyat yok" — art olmadan da "bu his dereceli olarak uyanabilmeli."
- 15.10: "Unutma, aynı kasvetli, grim tarz devam etmeli."
- 14.10 (aktarılan UI prompt'u): "A warm bowl of soup, a safe fire, and a trusted companion are luxury items" — kıtlık, paranoya, çöküş.
- Anlatıcı yok (13.10, C6): "oyunda hiçbir noktada yazarın ağzından bir metin yer almayacak, tüm metinler ... npclerin ağzından yazılmış gibi."
- Lore tezi (LORE.md, oyunda yazılı): "Konu kervan değil, kervanı çeken insanlar ve onların aşınması." Defter (Waybook) hiçbir satırı silmez, ölenin adının üstü çizilir.
- "Wayborne" adı (13.10, C12): "Ana karakterimizin hikayesinin temeli yolda doğmuş olması ve kendini ait hissedebildiği tek yerin yol olması."

### 1.3 Dünya (Sideria)
- 17.07: "M&B Warband gibi farklı kültürler içeren bir evren, orta dünya gibi özgün bir haritada"; "Dünyanın geri kalanı hakkında bilginin yavaş ve kısıtlı aktığı bir dönem."
- 17.07: "Orta çağın orta avrupası gibi birden fazla küçük krallığın, prensliğin bulunduğu kozmopolitik ve kaotik bir ortam."
- 17.07: savaşın kenarındayız — "savaşa dahil olmamalıyız ama savaşın etkilerini yaşayabiliriz ... kuşatmadaki bir şehre mal kaçırabiliriz ya da mültecilere yardım."
- 17.07: Mistik unsur çok nadir — "en küçük bir hatada oyunun bitmesine dahi sebep olan nadir bir lovecraftian unsur"; "su perileri 40 saatlik gameplay'de bir kere görülebilir"; ghoul/vampir/kurtadam "köydeki bir çocuğun kaybolmasında halkın ağzına hikaye olmuş" düzeyinde.
- 13.10 (C1): "Doğudaki göçebe türkler, orta avrupanın dini açıdan karmaşa ve kaos yaşadığı, binbir prenslik ... ve ticaret peşinde koşan venedik gibi ... hiçbir imgeyi, ismi olayı referans veyahut taklit edemeyiz."
- 13.10 (C2): "Tanrıların varlığı kanıtsız, inanç, insanların yorumu ve ihtiyacı eseridir."
- 13.10 (C6): "öbürkiler" (görünmeyen, yaşamı dönüştüren varlıklar), nadir büyücüler (uzak büyü kıtası Raviellon), deli kralın büyücü katliamı, kadim uygarlık "ac odyssey'de yer alan antik yunan öncesi ... teknlojik bir detay olmamalı."
- 13.10 (C10): "Yolda ölen bir kişi, yola aittir ... Sen dursan dahi yol durmaz, bir yol bitse dahi diğeri başlar." Yol kenarı ölülerini sayan bekçi kadın = "wayfarer".
- 17.09 (Google AI konsepti, yaratıcı "hangileri bize uygun" diye sordu): imparatorluk/tefecilik vs göçebe töre çatışması, takas ekonomisi (kımız, tuz, at, halı), yaralıların topallaması, ateş başı sohbetler.
- İki büyük inanç (14.10): "Bu evrende temel alınan iki güçlü inanış var. bunlar baikhan ve the hand inançları." (Önceki adlandırma: The Old Writ / Writbound & Renewed; Dağ kabilesinin nefes inancı "minor"a indirildi.)
- Baikhan yaratılış metnini yaratıcı kendisi yazdı (24–28.08): "Önce atlar vardı. İki attı..." — yas dokuz gün, deniz Gokana'nın gözyaşı. "Anlatıdaki belirsizlikler kasıtlı."
- 16.10 kültür paleti: dağ kabileleri, göçebe boyları (yurtlar), "nilfgard benzeri" kuzey askerî imparatorluk kalıntısı, ara bölge karışık kültürler, "Tyrell hanesi benzeri" vadi kültürü, eski ahit dini merkezi şehir, maden bölgesi, "ticaret odaklı ve hoşgörülü, yenilikçi" güney kentleri.

### 1.4 İlham kaynakları (yaratıcının ağzından)
| Kaynak | Ne için | Tarih / alıntı |
|---|---|---|
| **referans oyun** | Savaş, stres/huy, şehir menüsü, sanat tonu | 01.09 "kombat mekanigi ise tamamen referans oyun dungeon gibi olmalı"; 12.09 "Tamamen referans oyunda örnek al"; 05.10 "referans oyun dungeon gibi özel bir görünüm istiyorum" |
| **Kingdom Come: Deliverance** | Pazarlık; harita stili | 28.08 "kingdom come'da olduğu gibi bir pazarlık mantığı"; 15.10 KCD harita referansı |
| **Europa Universalis IV** | Olay kartları | 31.08 "eu4 gibi kartlarla ilerlemeli"; 14.09 "Ben event card istedim eu4'teki gibi" |
| **"Two Kingdoms"** (muhtemelen Kingdom Two Crowns) | Yol ekranı yerleşimi, yan bakış | 17.07; 14.09 "Two Kingdoms gibi olmalı, event sistemi ise eu4 gibi" |
| **Town of Salem** | Şehrin üstten izometrik görünümü (sonra terk edildi) | 12.09 |
| **Sword and Sandals** | Minimum karakter kalitesi çıtası | 03.10 "En basitinden sword and sandals kadar bir modele dahi ulaşamadık" |
| **Frostpunk, This War of Mine** | Duygusal ağırlık, ahlaki ikilem | 15.09, 17.09, 24.09 |
| **Mount & Blade Warband** | Kültürlü dünya; F tuşu komut menüsü | 17.07; 12.09 "mount and blade gibi komutlar" |
| **Euro Truck Sim, Death Stranding, FTL** | Döngü, ton | 17.07 ("FTL tonu") |
| **Don't Starve + referans oyun** | Sanity | 23.07 "bu mekanik beni her zaman çok büyülemiştir" |
| **Banner Saga, FAR: Lone Sails** | Atmosfer (pitch) | Temmuz pitch |
| **Patrician, Hanseatic League, Pillars of the Earth** | Ticaret/okuma | 23.07 |
| **Metin2** | Tek beceriyi geliştirme | 02.09 "metin 2'de olduğu gibi bir skilli geliştirebileceksin" |
| **Divinity 2** | Stat yapısı | 20.09 "divination 2'yi örnek alabilirsin" |
| **Project Zomboid** | Huy/perk | 20.09 |
| **Fallout New Vegas** | Wisdom/Int ile sonucu sezme | 17.09 |
| **Rust** | Basit crafting menüsü | 17.09 |
| **Oregon Trail** | Yol ekranı kompozisyonu | 15.10 "Oregon trsil'i baz alabilitiz" |
| **Vagrus, Carta Marina, Tolkien'in Orta Dünya haritası** | Harita çizim dili | 15–16.10 |
| **Westeros, Nilfgaard (Witcher), Tyrell (GoT), AC Odyssey, King Arthur** | Dünya/kültür benzetmeleri | 24.07, 16.10, 13.10, 17.07 |
| **Disco Elysium, Slay the Spire** | Pitch/hedef kitle belgeleri | Temmuz |

---

## 2. Israrla savunulan tasarım sütunları

1. **Derinleşme, asla sadeleştirme.** 17.09: "asla sadeleştirme istemiyorum, derinleşme, zenginleşme bizim yönümüz." 20.09: "Oyunun sistemi en zengin yanı olmalı." 20.09: "Sürekli daha minik olaylar öneriyorsun. Vizyonunu genişlet, maliyetten korkma." 20.09: "kestirme, kolay, ucuz yola kaçma. Zengin bir sistem ve oyun yaratıyoruz."
2. **referans oyun savaşı ve psikolojisi.** 4 kişilik saf, mevki, stres, huylar (02.09: "referans oyunda gibi"), Ölümün Kıyısı; 17.09: "herkes ölebilir artık. Evet ölmeden önce bir zar ile hayata tutunabilir herkes ama 1 hp kalacak."
3. **Kervan yok olmaz, sürünür.** 08.09: "kervan yok olmaz ama sürünür, dağılır, sadece kervan lideri, vagonu ve belki ona sadik olan ekibi kalıncaya kadar her şeyi kaybedebilir, altını eksiye düşebilir yani borca batabilir."
4. **Borç ve yaşayan ekonomi.** 08.09: kâr kaynağı yalnız fiyat farkı değil, "enflasyon, mevsimsel artış, arz talep dengesindeki değişim, ekonomik ve politik olaylar"; borçlar sekmesi; 16.09 Gemini'yle hazırlanmış "Sideria Tüccarlar Loncası Kredi Sistemi" (dosya masrafı, temerrüt, tahsilatçılar); 20.09 tüccarların kesesi sınırlı.
5. **Her karara stat check.** 20.09: "her kararın arkasında bir skill check mekanizmasi olmalı"; "3-4 event değil tüm eventlere, oyunun temeline işle."
6. **Olaylar oyuncunun karşısına çıkar; EU4 kartı.** 11.09: "olay oyuncu tarafından çekilmemeli, oyuncunun karşısına çıkmalı." 14.09: "evnetler popup message gibi gelmeli eu4te olduğu gibi." 14.09: "yolda kurt var gibi bir event varsa oraya gelirken yolda kurt görmeliyiz önümüzde."
7. **Karakter/mizaç duyarlı olaylar, kelebek etkisi.** 08.09: "yolcu hırsız ise partiye almak kötü sonuçlanabilir, kinci biri ise yemek vermemek daha sonra başımıza sorun açabilir"; "event tree ya da bir karar agaci mantiginda sematize edilmeli."
8. **Yolun hissi: ilerleme, değişen arazi, zaman, hava.** 12.09: "arkaplan ve akıcılığı çok önemli, ilerleme hissiyatı çok önemli ve çevre de gittikçe değişmeli"; 08.09 gündüz/ikindi/gece, hız 1x/1.5x/3x, kamp ateşi ambiyansı; 17.09 notu: "Göç esnasında arkaplan çok önemli ... oyuncuyu sıkmamalı."
9. **Kervanın fiziksel gerçekliği.** 12.09: lider "önden gidiyor atı ile"; 12.09 vagonlar arası mesafe, "yanyana iki kişiden fazla olmamali"; 09.10: "kervan koşmaz, en fazla hızlı yürür"; "moonwalk hissi olmasın asla"; 17.09 hız = bireylerin ve vagonun minimum hızı + tempo; 20.09 bozuk/çamurlu yolda hız zarar, 3-4 saatten sonra yorgunluk.
10. **Bireysel insanlar: açlık, kamp, sofra.** 17.09: "1.90 boyunda bir erkek ile 1.60 boyunda bir kadının açlığı aynı olmamalı"; her gece yemek dağıtım ekranı, "herkes tekli sıraya geçip yemek dagitilsin ... Kamp ateşi de olsun mutlaka."
11. **Kısıtlar görünür olsun / gerçekçi oran.** Hayvan boyları (02.10 eşek "kulakları ile beraber ... bir insanın omzuna kadar"; 02.10 öküz boynuzu omza), yaşayan dünya (17.09: "arkada yaşayan ve gelişen bir dünya olmalı" — NPC statları seferler arasında yükselir).
12. **Envanter = vagonların toplamı + crafting.** 17.09: "2-3 kere istedim bunu senden ama yapmadın ... her vagonun da bir envanteri olacak"; Rust gibi bandaj/vagon bezi craft; 17.09 kılıç/zırh "envanter değil".
13. **Lore'a sadakat, özgün adlandırma.** 15.09: "Ufukta camii gibi lore disi figurler olmamali"; 16.10: "Kilise, camii gibi gerçekte bulunan figürleri kullanma"; 16.10: "Grimmezra gibi referans oyunda özgü bir isim kullanma dosyalar içinde sakın."
14. **Sanat yönü en önemlisi; tutarlılık.** 03.10: "Sanat yönü en önemlisi ve bu en küçük detay"; 12.09: "Önemli olan her yerin birbiri ile uyumlu ve aynı tarzda olması"; 12.09: "Grafik tarzımız piksel olmayacak."
15. **Sağlam temel.** 08.09: "temelimiz çok sağlam olmalı"; 31.08: "mükemmel optimize olmasını istiyorum"; 15.09: "önce temelini iyi oturtmaliyim."
16. **Lokalizasyon ve pazar.** 31.08 dil seçimi; 08.09 "yaklaşık 10 farklı dile ... flex bir yapımız olmalı"; 16.10 "oyun çin pazarında da amerika ve avrupa pazarında da ilerleyecek."

### Özellikle sevdiği / övdüğü şeyler
- 28.08 ilk ekonomi testi: "Çok güzel, tamam."
- 24.09 Opus master prompt'unun sonucu için: "Önceki çalışmamız harika bir temel oluşturdu."
- 25.09: "low hud tasarımı genel olarak iyi."
- 28.09 hayvan rig'leri: "Çok güzel, tamamdır."
- 08.10 MPFB tabanlı insan hattı: "Çok güzel ilerliyorsun. Onaylıyorum bu çalışmayı." 08.10: "Tamamdır, güzel olmuş."
- 10.10 3B kıyafet paketi: "Diğer art içerikleri çok güzel." (yedek binici pantolonu "daha iyi")
- 14.10: "Efektler iyi"; UI çalışması için "ekran geliştirmelerini beğendim".
- 15.10 render edilmiş şehir: "Mükemmel böyle render et."
- 16.10 Carta Marina tarzı şehir çizimleri: "İşte şehirleri sevdim burada."
- 14.08 harita editörü fırça deseni: "buradaki random dağılım çok iyi, tebrik ederim."
- Masa/defter ("desk scene") arka plan promptları ile "istediğimiz tarzda çıktı alıyorduk" (27.09).

---

## 3. Tekrarlayan şikâyetler ve reddedilenler

### 3.1 Görsel kalite (en baskın tema)
- 12.09: "Bu görseller rezalet, sanki excel'de oyun yapıyoruz."
- 12.09: "bizim combat daha çok visualnovelrpg gibi ve hoş değil, sıkıcı."
- 13.09: "Ağaçlar havada gibi duruyor görselde, nasıl fark etmedin."
- 14.09: "Oyun hala text based rpg gibi."
- 24.09: "Çok kötü olmuş bu mesela, yaparken test etmedin mi? Güzel mi sence?"
- 25.09: "Sence şu an uygun mu AAA Indıe kalitemize?"
- 03.10 insan modeli: "Rezalet olmuş"; 05.10: "Bu boşlukları, bu sanatsal faciaları neden fark edemedin"; 07.10: "Bunu gören kişi kör olmalı. İnanılmaz kötü her şey."
- 02.10 Gemini parça üretimi: "hatlar çok çizgifilm gibi, bunu sevmedim"; "fiyasko".
- 15.10 harita: "Olmamış çok kötü"; 16.10: "Allah aşkına boş yere token harcıyorsun"; "nasıl onaylarsın bunu. ne çizim tarzı, ne de perspektifi doğru değil."
- Sanat stilinin "referans oyun tarzımızdan tamamen bağımsız" kayması (27.09), Gemini'nin "western" kıyafetler ve çerçeve eklemesi (27.09).

### 3.2 "Kendini kontrol etmiyorsun" / doğrulama eksikliği
- 18.09 gri şerit: "Son attığın görselde de kabak gibi duuryor o grilik. nasıl göremiyorsun"; "biraz güve nbana yani".
- 30.09: "All green ... demişsin ama görsellere baktığımda karakterler arası boşluğun ... ezildiğini görüyorum."
- 07.10: "Sana o parmak, el uzunluğunu söylediğim halde aynı şekilde yapmışsın."
- 30.09: "Bunları eklemiş ve sorunu düzeltmiş olman gerekirdi!"; 17.09: "2-3 kere istedim bunu senden ama yapmadın."
- 16.10: "Bir saniye, oyuna baglamadin mi hala ui çalışmalarını? Ana menu degismemis?"
- 05.10: "bir daha böyle bir hata yapmamak için kendine not düş." → 08.10 kendi "teftiş" kuralları: "Göz kararı onay yok", "Semptom gizleme yasak", "Sessiz sapma yok".

### 3.3 UI / navigasyon
- 10.09: "bazı sayfalardan geri çıkılmıyor. TÜM SAYFALARI KONTROL ET"; 11.09: "en çok karşılaştığım sorun menülere girip tekrar geri çıkamamak."
- 12.09: ekran boyutuna sığmayan metin, "okey diyemiyorum".
- 18.09: "şu gri arkaplandan çok sıkıldım."
- 25.09: "Butonların üstüne koyduğun scratch detayları olmuyor"; "Nine slice istemedim bunu"; 27.09 deri efektli butonları ve sayı giriş çerçevelerini kaldır, minimal butonlar.
- 25.09: farklı çözünürlükler "Yan yana koyduğunda görüntü aynı olmalı."
- 14.10: "hud butonları çok alakasız ... ana menüdeki fener ışığı çok parlak ve ana menü arkaplanı hoş değil."
- 14.10: envanterde "itemlerin resimleri de olmalı ... silahlar da burada yer almalı."

### 3.4 Mekanik / denge şikâyetleri
- 09.09 pazarlık: slider'ı hep sola zorlayarak sömürülebilir; "3 kere reddedildiğinde teklif ya satış fiyatımdan al ya da çık demeli tüccar."
- 09.09: moral simülasyonda 100'ün altına inmiyor → isyan olayı hiç ateşlenmiyor.
- 14.09: "Itibar çok hızlı kaybediliyor ve kazanılmıyor geri hemen."
- 14.09: "Yol bitiyor bir süre sonra ve sinirda (görünmez duvar) bekliyoruz."
- 14.09: olay, görevli öndeki objeye değil vagona denk gelince açıldı — "kervana ait en öndeki objeye denk geldiğinde event açılmalı."
- 15.09: dış değerlendirmede "sadece savaş seyrekligi konusunda katılıyorum."
- 26.09: "testte önüme bir hayvan sürüsü çıktı ... yaban domuzu ve kurt gibi mix bir seri cikmamasi gerektiğini ... söylemiştim."
- 14.10: atlı lider "ellerini sallıyor yürür gibi"; kampta vagondakiler "havadan iniyor"; kamp bitince oyun "bir anda hızlanıyor".

### 3.5 Açıkça reddedilenler (gerekçesiyle)
| Reddedilen | Tarih | Gerekçe / alıntı |
|---|---|---|
| "Olay çek" butonu | 11.09 | "çok yersiz ... oyuncunun karşısına çıkmalı" |
| Alttaki büyük metin/log alanı | 14.09 | "En altta bir satır ... log sekmesi olabilir" |
| Görsel stres efekti ve donma efekti | 26.09 | "kaldır komple" |
| Butonlarda çizik detayları, nine-slice, deri butonlar | 25–27.09 | "Güzel gözükmüyorlar" |
| Savaşta karakter çerçeveleri | 30.09 | "çerçeve olmasın ... hafif bir glow olsun" |
| Manken kontur çizgisi | 04.10 | "Mankenin konturu olmasın" |
| Saf mankende saç/kaş | 08.10 | karakter yaratımda modüler eklenecek |
| Radyal durum efektleri | 14.10 | yanma "gerçekçi bir şekilde yanan bir adam", donma bölgesel buzlanma, zehir yeşil sis |
| Keçe külah | 10.10 | "doneme uyhun değil" |
| Yandan görünüm şehir | 14.10 | "yandan görünüm istemiyorum, birebir referans oyun dungeon mantığında" |
| Haritada kabartma, renk, parşömen kenarı, bulut | 16.10 | "kabartma istemiyorum"; "Renklerden vazgeçelim"; "parşömen detayı ekleme kenarlara" |
| Üç seçenekli öneriler | 15.10 | "3 farklı seçenek sunma zira aralarında nitelikli bir fark yok" |
| Demo odaklı yeniden tasarım | 15.09 | "amacım demo çıkartmak değil sadece, oyunu mükemmel yapmak" |
| "Yolda küçük olumlu sinyal" türü | 23.09 | "sil, ihtiyacımız yok" |
| Dış AI'ların önerilerinin çoğu | 16.09 | "Pr a, b, c'yi devreye al ... geri kalan önerileri gormezden gel" |
| Kampanyanın sadeleştirilmesi, reddedilen görevler | 23.09 | silindi |
| Atölye'nin kervan avlusu paneli olması | 17.09 | "vagondaki basic repair mantığı içindi bu" |
| Commit'lerde Claude ibaresi / session linki | 04.09, 24.09 | "KESİNLİKLE VE ASLA ... SESSİON LİNKİ ASLA PAYLAŞILMAYACAK" |
| Fakir düşünme | 20.09 | "Şu fakir düşünme olayını bırak." |

---

## 4. Tersine dönen / terk edilen kararlar

| Konu | Önce | Sonra | Neden |
|---|---|---|---|
| Takvim | 17.07: "1-2 ay sonunda steam, xbox"; 2 ay | 14.08: Şubat 2027 Next Fest, demo 8 Şubat; 15.09: "amacım demo çıkartmak değil" | Kapsam büyüdü, kalite önceliği |
| Sanat üretimi | 17.07: eşiyle kâğıda çizim + AI (nano banana) | Prosedürel `_draw()` → Gemini görselleri (Eylül) → MakeHuman/MPFB 3B render + Quaternius/CC0 paketleri (Ekim) | Parça parça AI üretimi tutarsız; 27.09 "manken üretmek çok zormuş parça parça" |
| Giysi boyama (B-01..B-20) | 2D parça sayfaları | 3B render | Ana Hedefler'de "artık boyanmayacak" |
| Ölüm kuralı | 23.07: lider ölünce ikinci adam; Codex: "yalnızca lider ölür" | 17.09: "Unut bunu, herkes ölebilir artık" | "bu felsefeyi hep yanlış anladın" |
| Savaş | Basit/metin tabanlı | 12.09 tam referans oyun; 14.09 savaş yolda bir sahne | "sıkıcı" |
| Olay sunumu | Alt log/metin | EU4 kartı, yaklaşınca yolda görünür | "text based rpg gibi" |
| Yol kontrolü | Kervan kendi kendine varıyor | 11.09 A/D ile yürüme, geri giderken yavaş; 25.09 "a/d mi ... otomatik yürümeli ve komutlarla mı" yeniden tartışıldı, öneriye "hepsine katılıyorum" | Kontrol hissi |
| Şehir görünümü | 01.09 yer tutucu harita → 12.09 Town of Salem izometrik | 02.10 / 14.10 referans oyun tarzı arka plan + bina butonları; 15.10 render edilmiş kasaba önü | Atmosfer |
| Başlangıç partisi | 01.09 seçilebilir (4 kişi=2 vagon, maks 6) | 08.09: "iki kişi ve bir vagon ile başlasın. bunun seçeneği olmasın" | Playthrough akışı |
| Kervan büyüklüğü | 23.07: 2–12 vagon, 10–80 kişi | 20.09: 8 vagona kadar, ~18 kişi; 02.10: vagon sayısı seviye/itibarla artsın | Gerçekçilik/sistem |
| Vagon başına hayvan | İki öküz | 16.09: "bir vagonu iki öküz değil bir öküz çeksin" | Görsel/oran |
| Stres/moral | 02.09: stres parti başına | 17.09 (eski notlar): "Stres parti genelinde bir stat, moral ise bireysel" | Notlardan geri gelen fikir |
| Cinsiyet | 30.09: "cinsiyetlerin mekanik etkisi olmayacak" | 02.10: "Kadınlar esnek ve rogue benzeri ... erkekler ise daha dayanıklı" | Fikir değişti |
| Din adları | Temmuz: Baikhan + The Old Writ (Writbound/Renewed) | 14.10: "baikhan ve the hand"; dağ nefes inancı minor | Lore olgunlaştı |
| Lore parçası | "Mürekkep savaşları" | 28.08: "titiz bir şekilde kaldırıp" | — |
| Şehir adları | Karakonak/Kurtboğazı/İpekevi/Demirkapı/Yeşilova | 08.09 "birer placeholder"; 13.10 C14 "Değişecek"; 16.10 yeni adlandırma | Gerçek harita |
| Harita stili | KCD tarzı (15.10) → Vagrus → Carta Marina (16.10) | Orta Dünya gibi parşömen tonu, mürekkep, renksiz; dağlar için CC0 asset | Hiçbir dağ çizimi beğenilmedi |
| Harita bulutları | 15.10 bulut ekle (gidilmeyen yerler) | 15.10 "bulutları ekleme sakın" | — |
| Hedef altın (GOAL_GOLD) | Faz 8'de hedef ekranı | Sonra kaldırıldı ("days_as_leader" final kapısı) | "Zenginlik hiçbir şeyi bitirmez" |
| Pazarlık | KCD sabır/slider | 09.09 üç ret + ültimatom | Sömürü noktası |
| Stres/donma ekran efekti | Eklendi | 26.09 kaldırıldı | Beğenilmedi |
| Repo geçmişi | Normal commit geçmişi | 24.09 tek commit'e ezildi, GELISIM_GECMISI.md yazıldı | Session linki ifşası (KVKK şikâyeti) |
| Repo görünürlüğü | — | 24.09 "private yapmayacğaım çünkü o zaman senin repo erişimin kalkar" | Araç kısıtı kabullenildi |

---

## 5. Pazarlama, hedef kitle, platform, gelir, hukuk/AI beyanı, web sitesi

### 5.1 Platform ve gelir modeli
- 17.07: "Amacım hızlıca oyuu üretmek, üretim aşamasında pazarlama yapmak ve crowdfunding için kitle oluşturmak, sonunda da kickstarter ile süreci başlatıp ... steam, xbox üzerinden oyunu yayınlamak."
- 17.07: "Kısa vadede nakit önceliğim."
- game_design.md: "Steam (Early Access) + Xbox (ID@Xbox), itch.io ilk yayın noktası."
- Marketing: itch.io'da "Pay-what-you-want ile erken nakit akışı"; Kickstarter hedefi "$8K - $15K (wishlist 1000+ olursa)"; tier'lar $5–$250, map editor erişimi bir tier ("Inkarnate alternatifi").
- 30.07: harita editörü "önce gizli tutup sonra kickstarter'da seviyeye göre paylaşabilirim ... daha sonra free olarak da sunabilirim."
- 14.09: Xbox tarayıcısı + kumanda desteği — gerekçe "game test aşamalarını benim için daha sık ve konforlu hale getirecek."
- PC hedefi; 31.08: "bu bir bilgisayar oyunu olacak."

### 5.2 Takvim (hedef)
- 14.08: "şubat next fest'e yetişmek istiyorum"; "fest'e bir demo yetiştirmem yeterli değil mi?"
- Marketing belgesi: Ocak 2027 Steam sayfası + demo; **8 Şubat 2027 kesin son tarih**, 22 Şubat 2027 Next Fest. Kickstarter Next Fest sırasında/sonrasında.
- 15.09 ile tutarsız: "amacım demo çıkartmak değil sadece, oyunu mükemmel yapmak" (takvim baskısı vs kalite hedefi — çözülmedi).

### 5.3 Hedef kitle ve mesaj
- Marketing belgesi: FTL, referans oyun, Slay the Spire oyuncuları; Oregon Trail nesli; lore odaklılar; M&B hayranları; "25-40 yaş, PC oyuncusu"; "Kervan/ticaret nişi az dolu — bu avantaj."
- Mesaj: "Solo/aile projesi vurgusu güçlü"; "his sat, özellik değil".
- 16.10: Çin + Amerika + Avrupa pazarı; şehir adları "ingilizceye çevrilebilir ya da ingilizce de okunabilir olsun." 11 dil altyapısı var.
- Kanal: Reddit (önce karma, r/IndieDev, r/worldbuilding, r/fantasymap...), X, Discord ("Türkiye'de banlı — VPN ile"), 500 üye hedefi; 13.08 "reddit kullanmadım daha önce hiç".

### 5.4 Web sitesi
- 28.08 (Websayfa): domain `waybornegame.com` (Cloudflare, $10.46/yıl), GitHub private repo, Netlify, 2FA; "Toplam maliyet: $10.46/yıl".
- 28.08: e-posta abonelik sorusu — "en ucuz yol nedir 100 adet gibi küçük bir limit olmadan"; karar: "kod yazmana gerek yok şu an."
- Oyunun web build'i GitHub Pages'te (test için).

### 5.5 Hukuk, lisans, AI beyanı, gizlilik
- 04.09 (Legal): "Oyunumu steam'e eklemek, para kazanmak ve lisans haklarını korumak için ..."; 11.09: "Kickstarter'da Türkiye'den fon almanın yolları nelerdir? Yurtdışında şirket kurmak çok pahalı."
- 17.09: LICENSE — "tüm hakları benim ve satışa sunulmadıca kullanılmamalıdır."
- 17.09: Steam AI bildirisi — "kodlama, sanat vs ... destekleyici konumda yapay zeka kullanılmıştır." 24.09: "There's no problem with ai closure text, I wanted it to be there."
- **Dikkat:** `AI_DISCLOSURE.md` hâlâ "tüm görseller ... prosedürel çizim fonksiyonlarıyla (`_draw()`) üretilir" diyor; Eylül sonundan beri Gemini görselleri, 3B render'lar ve CC0 paketler oyunda → beyan güncel değil.
- 04.09 & 24.09: commit/PR'larda "claude ibaresi" ve session linki yasak; 24.09 session linki ifşası "bir gizlilik ihlali ... KVKK!" — şikâyet dilekçesi istendi, repo geçmişi tek commit'e ezildi.
- 27.07: harita editörü lisansı / korsan yazılım sorusu (lisans bilinci var, kararsız).
- CC0/"ücretsiz ticari kullanıma açık" asset tercihi (28.09, 09.10, 16.10); CREDITS.md mevcut.

---

## 6. Çözülmemiş sorular ve gerçekleşmeyen istekler

### 6.1 Ana Hedefler'de açık (CLAUDE.md)
- Gerçek seslendirme + savaş nidaları (eski not #7 "Sesli anlatımlı bir tutorial, yaşlı story teller sesi/genç indie dev sesi?", #11 karakterler "korkar ve ağlar").
- Karanlık arayüzün ekranlara bağlanması yarım (16.10: "Ana menu degismemis?").
- Kıyafetlerin ganimete/loot'a bağlanması (09.10 isteği).
- Lore ve tarihçenin tamamlanması — `SORULAR.md`'de coğrafya fazı soruları bekliyor; "Yolda doğan kim?" çelişkisi açık.
- Eşya bozulması; hastalık/doktor/şehrin ilaç stoğu (15.10); yoldaş bulmanın zorlaşması (15.10: "sadece buna mecbur olanlar katılmalı"); Celsius sıcaklık (14.10).
- Codex'in olay bölümü güncel değil (24.09: güncellenmesi istenmedi).
- Beş ikon ve görsel denetim tablosundaki küçük eksikler.

### 6.2 Konuşmalarda istenip izi kaybolan / kısmen yapılanlar
- **Harita** — 16.10 itibarıyla bitmedi: dağ çizimi, net zoom ("ekranda sadece şehri görebileceğim kadar"), "çift ve anlamsız yollar", 5 kervansaraylı ipek yolu, kültürel yapı farkları, gemiler/balıkçı tekneleri; yerleşim adları artifact'te onay bekliyor.
- **Dungeon'lar** (Temmuz pitch'in çekirdeği: rota dışı dungeon, hazine, mistik yaratık) — oturumda hiç ele alınmadı.
- **Lovecraftian nadir varlık**, su perisi gibi efsanevi karşılaşmalar, kurtadam/vampir — yalnızca lore'da.
- **Liman/gemi ticareti, senet** (V2), **din değiştirme süreci**, mezhep çatışması savaşları, dini bayramlar, üç katmanlı para birimi, mevsimlerin bölgesel etkisi, lüks/fakir semt fiyat farkı, toplu alım indirimi — tasarım belgelerinde var, oturumda durumları belirsiz.
- **Kampanya bölümleri**: 17.09 "Kampanya bölümlerini daha yazmadık bile."
- **İki dini yorum için iki ayrı trailer** (#12, "planda tut").
- **Av olayı**: geyik/erkek geyik avı ve mini savaş (28.09), köpekle iz sürme (maks 2), eşekli küçük tüccarlar ve "yarım vagon" (tek tekerli) — tasarlandı, oyundaki karşılığı doğrulanmadı.
- **Büyücü kostümü + basic DnD büyüleri**, isabet animasyonları, saplı kalan oklar (14.10) — kısmen.
- **Binme/inme ve vagondan inme spriteları**, kampta liderin attan inmesi (14.10).
- **Şehir kapısı/surlar** (02.10 "Hala bir şehre vardığımızda kapı karesinden başka bir şey görmüyoruz") — Faz 25'te kapandı denmiş.
- **Diğer kervanlarla karşılaşma** (askerî konvoy, mülteci, dini konvoy — 17.09 #24-25), hırsızlık/cinayet soruşturması (#23), manipülasyon huyu (#19-20), Wisdom/Int ile sonuç sezme (#21) — kısmen işlendi, derinliği belirsiz.
- **Boy/kilo/cinsiyetin statlara etkisi** (28.09 "Bu statlara etki konusunu bekleyen ana hedeflere ekler misin") — 02.10'da yapılması istendi.
- **Harita editörü** (Wayborne Map Editor) — ayrı proje, Kickstarter tier'ı olarak düşünülmüş; Ağustos'tan beri dokunulmamış.
- **Marketing görevleri** (Steam dev hesabı, Reddit karma, Discord, itch Coming Soon, press kit, trailer) — konuşmalarda tamamlandığına dair hiçbir iz yok; Ekim ortası itibarıyla tüm odak geliştirmede.
- `tone_guide.md`, `steam_page.md`, `kickstarter_copy.md`, `reward_tiers.md`, `devlog_template.md` — "henüz yazılmadı".
- Çözülmemiş stratejik gerilim: Şubat 2027 Next Fest takvimi ↔ "baldurs gate yarısı" kapsam + "mükemmel" kalite + hâlâ temel sanat hattı (insan figürü, harita) arayışı.

---

## 7. Yaratıcının kapasitesine dair sinyaller

### 7.1 Ekip
- Solo geliştirici + eşi: 17.07 "eşim ile kağıda çizim yapıp ... ai'a ... 2d modellemesini"; "İkimiz de eli kalem tutan, ortalama içerikler çizebilen insanlarız fakat ressam değiliz"; 14.08 "eşimin dijital bir geçmişi yok ... sadece resim çizmeyi biliyor karakalem."
- Ses: 17.07 "arkadaşımdan yardım alacağım" (şaka: "çamaşır makinesinin başlangıç sesini kaydedip"); 15.09 iki folk müzik dosyası yükledi (ana menü/yol, şehir).
- Marketing belgesi: "Geliştirici: Batuhan (kod, tasarım, yönetim)"; "Narrative/lore: Claude destekli".
- Kodlama: 17.07 "Kodlamayı tamamen ai destekli yapacağım"; 17.07 "Ben oyunun mekaniklerini, combat ve ticaret sistemi dahil 6 haftada bitiririm. İşin asıl zor tarafı narrative ve art." Yaratıcı kod yazmıyor; repo ile tamamen Claude Code çalışıyor, git/cmd konusunda deneyimsiz (02.10 zip yükleme, Temmuz PAT/credential sorunları).
- Rolü: 02.09 "sen kumandansın, sonnet 5 için ona tüm planı dök"; 28.09 "sen oyunumuzun srt direktörüsün"; 24.09 "You are the director of this AAA quality indie game!"

### 7.2 Araçlar
- **Claude**: Claude Code (Opus = vizyon/plan, Sonnet 5 = uygulama), claude.ai projeleri; diğer modellere çapraz değerlendirme (16.09 "Farklı modellerde bu promptu calistirdim").
- **Gemini / Google AI**: görsel üretimi (arka planlar, olay illüstrasyonları, ikonlar, kapı), teknik prompt yazımı (referans oyun savaş promptu 12.09, kredi sistemi 16.09, title ekranı 16.09, gri şerit teşhisi 18.09, mesh kesme önerisi 28.09). 25.09: "Gemini bana jpg olarak veriyor" — PNG gerekenlerin arka planını kendisi kaldırıyor (27.09).
- **Adobe Firefly (GPT image 2), OpenArt, nano banana**: harita denemeleri (Temmuz). Prompt'larda Midjourney/Stable Diffusion/FLUX hedefleniyor.
- **3B**: MakeHuman/MPFB (Blender, Claude ortamında), Quaternius paketleri, "Ultimate Animated Animal Pack", cartographyassets (CC0 dağ). İnkarnate/Wonderdraft düşünüldü, kendi editörünü yazdırdı.
- **Akademik okuma**: 22.09 makaleler (Bogost, Frostpunk biyopolitikası, environmental storytelling, renk ve duygu) — PDF olarak basılı okumak istiyor ("kağıt ziyan olmasın").

### 7.3 Bütçe ve zaman
- Düşük bütçe: site $10.46/yıl; ücretsiz/CC0 asset; "Yurtdışında şirket kurmak çok pahalı"; "Kısa vadede nakit önceliğim"; Kickstarter + itch PWYW ile erken nakit.
- AI kullanım maliyetine duyarlılık iki yönlü: 20.09 "maliyetten korkma"; 16.10 "boş yere token harcıyorsun"; 11.09 karbon ayak izi ve önbellek bağlamını küçültme sorusu.
- Zaman: Claude oturum limitlerine sık takılıyor (haftalık limit 15.09), "limit dolarsa ... o zaman devam et"; mesajlar sabah 05:00'ten gece yarısına; bazen telefondan çalışıyor (04.10 "Telefondayim").
- Aynı claude.ai hesabında başka bir kurumsal iş projesi de bulunuyor; oyun büyük olasılıkla tam zamanlı bir işin yanında yürütülüyor (çıkarım).
- Art bekliyor: 11.09 "Görsel varlıklar biraz daha bekleyecek maalesef"; 15.09 "şu an art ile ilgilenemiyorum".

### 7.4 Çalışma tarzı (yönetmen için çıkarımlar)
- Çok net, görsel geri bildirim veriyor; ekran görüntüsü üzerinden çalışıyor, piksel detayında hata yakalıyor.
- Uzun otonomi veriyor ("bana soru sorma, onay isteme") ama sonuçta sert denetliyor; "bitti" denip test edilmemiş işe tahammülü yok.
- Dış AI çıktılarını (Gemini, Google AI, Opus master prompt) sıkça "kılavuz" olarak getiriyor; her öneriyi değil, seçerek alıyor.
- Hedefleri tek listede istiyor: 17.09 "Ana hedefler dışında bir şey kalmasın, başka bir yerde not birikmesin bundan sonra." 03.10 "hedeflerimize sürekli önceki faz çalışma notlarını eklemeyelim."
- Gizlilik ve atıf konusunda hassas (Claude ibaresi yok, session linki yok, KVKK).
