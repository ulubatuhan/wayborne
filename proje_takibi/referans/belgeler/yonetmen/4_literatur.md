# Wayborne — Literatür ve Pazar Taraması

> **Belge:** Yönetmen paketi, bölüm 4. Oyun tasarımı ve pazarlama planına kaynak olacak masa başı araştırma.
> **Kapsam:** Oyuncu motivasyonu literatürü, karşılaştırmalı oyun analizi, 2024–2026 indie PC/Steam pazarlaması, sentez önerileri.
> **Platform notu:** Wayborne yalnızca PC/Steam için geliştiriliyor. Web derlemesi sadece iç test amaçlıdır, pazarlama veya dağıtım kanalı olarak düşünülmemiştir.
> **Tarih:** Ekim 2026. Kaynaklar 1979–2026 arasını kapsıyor. Köşeli parantezdeki `[R#]` numaraları sondaki kaynakçaya karşılık gelir.

---

## 0. Yönetici Özeti

1. Wayborne'un önerdiği bileşim (kervan yolculuğu, stres ve moral yönetimi, referans oyun tarzı sıra tabanlı savaş, soy ve halef sistemi, ticaret ve borç) birçok kanıtlanmış "çekirdek kancayı" bir araya getiriyor. Bu kancaları taşıyan oyunlar ticari olarak doğrulanmış durumda. referans oyun 6 milyon kopya [R32], Frostpunk 5 milyon [R45], Kenshi 3 milyon [R44], Against the Storm 2 milyon [R41], Wartales Steam'de 1 milyon [R43], Dredge 1 milyon [R37] sattı.
2. Bu bileşimin en büyük riski **yolculuğun kendisinin sıkıcı hale gelmesi**. referans oyun II'nin "sıkıcı posta arabası yolculuğu" şikâyetleri [R35] ve The Banner Saga'da kaynak dengesine dair eleştiriler [R30] bunu açıkça gösteriyor. Yol, bekleme süresi gibi değil, karar yoğun bir sahne gibi tasarlanmalı.
3. Literatür, kaybın anlamlı olması için oyuncunun **bağlanma (relatedness)** ve **ustalık (competence)** ihtiyaçlarının beslenmesi gerektiğini söylüyor [R1][R2]. Kayıptan kaçınma (loss aversion) [R17] kalıcı ölümü güçlü kılar. Ancak telafi edici bir miras sistemi yoksa oyuncu oyunu bırakır. Soy ve halef mekaniği Wayborne'un en ayırt edici kancası olabilir.
4. Pazarlamada belirleyici olan şey **istek listesi (wishlist)**. Zukowski'nin eski "en az ~7.000 istek listesi" eşiği [R56] ve GameDiscoverCo'nun 10 doların üzerindeki oyunlar için ilk hafta medyan dönüşüm oranı **0,10×** [R57] planlamanın temel taşları. Zukowski Haziran 2026'daki Steam değişikliği nedeniyle eşik yazısını "arşiv" olarak işaretledi [R56]. Bu yüzden eşik, kesin bir hedef değil, yönlendirici bir değer olarak kullanılmalı.
5. Projede yapay zekâ destekli sanat ve kod kullanılıyor. Valve, Ocak 2026'da yalnızca geliştirme aşamasında kullanılan araçları (ör. kod asistanları) bildirim zorunluluğundan çıkardı. Oyuncunun gördüğü yapay zekâ içeriği ise hâlâ bildirilmek zorunda [R68]. Game Oracle'ın 2025 analizi, yapay zekâ bildiren oyunların benzerlerine göre ~%52,6 daha az inceleme aldığını buldu [R70]. Bu, pazarlama açısından ciddi bir risk ve sanat stratejisinin yeniden gözden geçirilmesini gerektiriyor.

---

## 1. Yöntem ve Güvenilirlik Notu

- **Yöntem:** Web araması ve birincil/ikincil kaynak okuması yapıldı. Akademik çalışmalar için orijinal yayın künyesi (DOI veya yayınevi) verildi. Satış rakamları için önceliği **geliştirici ve yayıncı açıklamalarına** verdim. Üçüncü taraf tahminleri (Gamalytic, VG Insights, Raijin, Vaporlens, SteamPulse gibi) açıkça "tahmin" olarak işaretlendi.
- **Tahmin araçlarının sınırları:** Üçüncü taraf tahminleri aynı oyun için 3 kata varan farklılık gösterebiliyor. Örneğin Battle Brothers için Raijin ~634 bin, Vaporlens ~1,96 milyon kopya tahmini veriyor [R53]. Bu tahminler aralık olarak okunmalı.
- **Doğrulanamayan veriler:** Pentiment, Heaven's Vault, Mount & Blade, Expeditions serisi, Banner of the Maid ve Crusader Kings için güvenilir ve güncel satış verisi bulamadım. Bu oyunlar yalnızca tasarım açısından ele alındı, satış rakamı verilmedi.
- **İkincil aktarım:** GDC konuşmalarının bir kısmının (Sigman 2016, Booth 2009) içeriği basın haberleri üzerinden aktarıldı. Bu durum metinde belirtildi.

---

## 2. Oyuncu Motivasyonu ve Bağlılık Literatürü

### 2.1 Öz Belirleme Kuramı (Self-Determination Theory, SDT)

- **Kaynak:** Ryan, Rigby ve Przybylski (2006), oyun motivasyonunu üç temel psikolojik ihtiyaçla açıklıyor: **özerklik** (autonomy), **yeterlik/ustalık** (competence) ve **ilişkili olma** (relatedness). Dört çalışmada bu ihtiyaçların tatmini oyundan alınan keyfi ve oynamaya devam etme niyetini öngördü [R1]. Przybylski, Rigby ve Ryan (2010) modeli genişletti. İhtiyaç tatmini sağlayan oyunların daha sağlıklı bir bağlılık ürettiğini öne sürdüler [R2].
- **Wayborne için çıkarım:**
  - *Özerklik:* Rota seçimi, hangi şehre gidileceği, hangi yükün taşınacağı ve borç alıp almama kararları özerklik hissini taşır. Harita "tek doğru rota" sunmamalı.
  - *Ustalık:* Savaşta ve ekonomide oyuncu sonuçların nedenini anlayabilmeli. Muhasebe defteri (ledger) / "waybook" arayüzü, yeterlik geri bildirimini veren araç olabilir.
  - *İlişkili olma:* Tek oyunculu bir oyunda ilişkili olma ihtiyacı yapay karakterlere bağlanmayla karşılanır. Kervan üyelerinin adları, geçmişleri ve tuhaflıkları bu ihtiyacı besler. referans oyun'ın kahraman kişilikleri bunun bir örneği [R22].

### 2.2 Akış (Flow)

- **Kaynak:** Csikszentmihalyi (1990), akış durumunu beceri ile meydan okuma arasındaki denge olarak tanımlıyor. Bu durumda net hedefler ve anında geri bildirim bulunur [R3]. Chen (2007), oyunlarda akışı oyuncuya göre ayarlamanın gerektiğini savundu. Farklı oyuncuların "akış bölgeleri" farklıdır ve oyun, oyuncuya seçimler aracılığıyla kendi zorluğunu seçme imkânı vermelidir [R4].
- **Wayborne için çıkarım:** Zorluğu yalnızca bir menü ayarıyla değil, oyun içindeki seçimlerle ayarlamak (riskli/güvenli rota, kısa/uzun yol) Chen'in önerisine uyar. Oyuncu risk seçerek kendi akış bölgesini bulur.

### 2.3 Lazzaro'nun 4 Eğlence Anahtarı

- **Kaynak:** Lazzaro (2004), oyuncu gözlemine dayalı olarak dört eğlence türü tanımladı. **Zor eğlence** (hard fun: zorluk, ustalık, *fiero* zafer hissi), **kolay eğlence** (easy fun: merak, keşif), **ciddi eğlence** (serious fun: oyunun gerçek hayattaki durumu değiştirmesi, rahatlama) ve **insanlar faktörü** (people fun) [R5].
- **Wayborne için çıkarım:** Savaş ve hayatta kalma *zor eğlence*, harita ve olay keşfi *kolay eğlence* sağlar. Tek oyunculu bir oyunda "insanlar faktörü" Twitch/YouTube izleyiciliği ve topluluk paylaşımıyla dolaylı olarak karşılanabilir (bkz. §4.6).

### 2.4 MDA Çerçevesi

- **Kaynak:** Hunicke, LeBlanc ve Zubek (2004), oyunu **Mekanik → Dinamik → Estetik** zinciriyle analiz ediyor. Tasarımcı mekaniklerden başlar, oyuncu ise estetikten (yani hissedilen duygudan) başlar. Makale sekiz estetik türü sayar: duyu, fantezi, anlatı, meydan okuma, dostluk, keşif, ifade ve teslimiyet [R6].
- **Wayborne için çıkarım:** Hedef estetikler açıkça yazılmalı. Önerim şu: *fantezi* (kervan başı olmak), *meydan okuma*, *anlatı* ve *keşif*. Her mekanik bu estetiklerden birine hizmet etmeli. Örnek: açlık mekaniği → kaynak gerilimi dinamiği → meydan okuma ve anlatı estetiği.

### 2.5 Yee ve Quantic Foundry Motivasyon Modeli

- **Kaynak:** Yee (2006), çevrimiçi oyunlarda faktör analizi yaparak motivasyonları üç üst bileşen altında topladı: **başarı**, **sosyal** ve **sürükleyicilik (immersion)** [R7]. Quantic Foundry'nin daha sonraki Gamer Motivation Model'i 6 ana motivasyon kümesi ve 12 alt boyut tanımlıyor. Bunlar arasında *Strateji* (planlama, karar), *Keşif*, *Hikâye* ve *Tamamlama* var [R8].
- **Wayborne için çıkarım:** Hedef oyuncu profili büyük olasılıkla "Strateji + Sürükleyicilik (Hikâye/Fantezi)" kümesidir. Bu profil referans oyun, Battle Brothers ve Wartales oyuncularıyla örtüşür. Pazarlama dili de bu iki motivasyona hitap etmeli ("her karar bir bedel", "her yolculuk bir hikâye").

### 2.6 Merak ve Bilgi Boşluğu Kuramı

- **Kaynak:** Loewenstein (1994), merakı **bilgi boşluğu** algısından doğan bir dürtü olarak tanımlıyor. Kişi biraz bilgi sahibi olduğunda ve eksik parçayı fark ettiğinde merak en yüksek seviyeye çıkar. Hiç bilgi yoksa ya da bilgi tamamsa merak düşüktür [R9].
- **Wayborne için çıkarım:** Mürekkep ve parşömen haritasında "yarı bilinen" bölgeler en güçlü merak tetikleyicisidir. Örnek: bir söylenti, haritanın kenarına karalanmış bir not ya da "burada canavarlar olabilir" gibi bir ibare. Sunless Sea'nin sis altındaki haritası ve 80 Days'in şehir söylentileri bu ilkeyi uygular [R26][R24].

### 2.7 Ortaya Çıkan Anlatı ve Hikâye Üreticileri

- **Kaynak:** Sylvester (2013), *Designing Games* kitabında oyunun bir "deneyim motoru" olduğunu ve anlatının mekanik etkileşimlerden ortaya çıkabileceğini savunuyor [R10]. Sylvester'in 2017 GDC konuşmasında RimWorld'ü "oyun" değil, "hikâye üreteci" olarak tanımladığı aktarılıyor. Konuşmada bazı özelliklerin bilinçli olarak dışarıda bırakılması da anlatılıyor. Böylece oyuncu, aslında orada olmayan hikâye öğelerini kendi zihninde tamamlıyor (apofeni) [R11]. RimWorld'ün "AI Storyteller" sistemi (Cassandra, Phoebe, Randy) olayların temposunu ve şiddetini düzenleyen bir anlatı yöneticisi olarak çalışıyor [R77].
- **Kaynak:** James Ryan (2018), doktora tezinde simülasyonların ürettiği olaylardan anlatıyı "küratörlük" yoluyla çıkarmayı inceledi. Ryan'a göre simülasyon bir dünya üretir, ama o dünyadan hikâye çıkarmak ayrı bir tasarım sorunudur [R12]. Mateas ve Stern'in Façade çalışması, drama yöneticisi (drama manager) kavramının erken bir örneğidir [R13].
- **Kaynak:** Short ve Adams (ed., 2019), *Procedural Storytelling in Game Design* derlemesinde prosedürel anlatı tekniklerini topluyor [R14]. Kate Compton'ın (2016) üreteç tasarımı yazısı ise "10.000 kâse yulaf ezmesi" sorununu tanımlıyor: Teknik olarak birbirinden farklı ama algısal olarak aynı içerik oyuncu için anlamsızdır [R15].
- **Wayborne için çıkarım:**
  1. Yol olayları, yalnızca rastgele bir tablodan çekilmemeli. Bir "yol yönetmeni" (storyteller), kervanın durumuna (stres, açlık, borç) göre olay seçmeli.
  2. Waybook/defter, **küratörlük aracı** olarak kullanılabilir. Oyun, simülasyonda olan biteni anlatı cümlelerine dönüştürüp kaydeder. Örnek: "Çorak Geçit'te üçüncü gün: Aldric açlıktan isyan etti." Bu, Ryan'ın küratörlük önerisinin doğrudan bir uygulamasıdır.
  3. Compton'ın uyarısı gereği, olayların varyasyon sayısından çok **algısal farklılık** önemlidir. Her olay oyuncunun kararını değiştirecek kadar farklı olmalı.

### 2.8 Anlamlı Seçim ("İlginç Kararlar")

- **Kaynak:** Sid Meier, GDC 2012'de oyunun "bir dizi ilginç karar" olduğu görüşünü işledi. İlginç bir kararın net bir doğru cevabı yoktur, takas (trade-off) içerir ve sonuçları oyuncuya görünür [R16].
- **Kaynak:** 80 Days'te Jon Ingold, seçimlerin çekiciliğini blackjack'e benzetiyor: Her yeni kart aynı kararı daha riskli hale getirir [R24]. Meg Jayanth'ın GDC konuşması, oyunun stratejik açıdan kötü ama anlatı açısından cazip seçimlerle oyuncuyu "yoldan çıkardığını" anlatıyor [R25].
- **Wayborne için çıkarım:** Her yol olayında en az bir **anlatısal açıdan cazip ama mekanik açıdan riskli** seçenek bulunmalı. "Yabancıyı kervana al" seçeneği bunun bir örneği: Yeni bir karakter gelir, ama açlık artar. Jayanth'ın ilkesi bu.

### 2.9 Kayıptan Kaçınma ve Kalıcı Ölüm

- **Kaynak:** Kahneman ve Tversky'nin (1979) Beklenti Kuramı'na göre kayıplar, eşit büyüklükteki kazançlardan psikolojik olarak daha ağır hissedilir [R17].
- **Tasarım sonucu:** Kalıcı ölüm (permadeath), kayıptan kaçınma eğilimini kullanarak her kararın ağırlığını artırır. Ancak aynı mekanizma, oyuncunun "her şeyi kaybettim" hissiyle oyunu bırakmasına da yol açabilir. referans oyun'da kahramanlar ölür, ama mezra (mezra) ve servet kalıcıdır. Bu tampon, kaybı sindirilebilir kılar [R75]. referans oyun II mezrayı kaldırdı. Oyuncu tartışmalarında birinci oyunda kaybın "yeni kahramanla devam" anlamına geldiği, ikinci oyunda ise "başa dön" hissi yarattığı dile getiriliyor [R35].
- **Wayborne için çıkarım:** Soy ve halef sistemi tam olarak bu tampon işlevini görür. Kervan başı öldüğünde varis devralır. Kaybın acısı korunur, ama ilerleme sıfırlanmaz. Bkz. §3.4.

### 2.10 Roguelite Koşu Yapısı ve Kalıcı İlerleme (Meta-Progression)

- **Kaynak (Slay the Spire):** Oyun tek oturumda bitirilebilen koşulara dayanır. Koşu içi kararlar (kart ekleme ve çıkarma) ile koşular arası açılımlar ayrıdır. Slay the Spire 2, ilk haftasında 3 milyondan fazla kopya sattı ve 25 milyondan fazla koşu kaydedildi [R40]. Bu, "bir koşu daha" döngüsünün gücünü gösteriyor.
- **Kaynak (Against the Storm):** Eremite, kalıcı ilerlemeyi "Citadel" (Smoldering City) aracılığıyla, koşular arasında geliştirilen bir "ilerleme avatarı" olarak kurguladı. Fırtına döngüsü (Blightstorm) her birkaç yerleşimde bir haritayı sıfırlıyor. Geliştiriciler bunu şehir kurmanın "yeniden inşa" hissi ile roguelite ihtiyaçları arasında bir uzlaşma olarak tanımlıyor [R42]. Bir dış eleştiri ise bu üst katmanın çekirdek oyundan kopuk kaldığını savunuyor [R42].
- **Wayborne için çıkarım:** Kalıcı ilerleme, **dünyanın kendisinde** görünür olmalı. Örnekler: hanedan defteri, lonca kredisi, açılan ticaret yolları. Bunlar soyut menü puanları olarak kalmamalı. Against the Storm eleştirisi, üst katmanın çekirdek döngüyle bağlantılı olması gerektiğini gösteriyor.

### 2.11 Tempo ve Gerilim Eğrileri (Yapay Zekâ Yönetmeni)

- **Kaynak:** Michael Booth'un (Valve) 2009 AIIDE sunumunda Left 4 Dead'in "AI Director" sistemi anlatılıyor. Sistem, oyuncuların algılanan stresini izler ve **gerilim artışı → zirve → rahatlama** (build-up → sustain peak → relax) evreleri arasında geçiş yapar [R18]. Valve'in L4D2 betik belgeleri bu durum adlarını doğruluyor (BUILD_UP, SUSTAIN_PEAK, RELAX) [R19].
- **Wayborne için çıkarım:** Yol, sabit olay sıklığıyla değil, bir gerilim eğrisiyle yönetilmeli. Zorlu bir savaştan sonra güvenli bir kamp veya bir tüccar olayı gelmeli. Uzun süre sakin geçen bir yolculuğun ardından ise bir pusu gelmeli. Kervanın stres/moral değerleri yönetmen için girdi olarak kullanılabilir.

### 2.12 "Juice" ve Geri Bildirim

- **Kaynak:** Jonasson ve Purho (2012), "Juice it or lose it" konuşmasında aynı oyunun ses, ekran sarsıntısı, parçacık efekti ve tween animasyonlarıyla nasıl dönüştüğünü gösterdi [R20]. Swink (2008), *Game Feel* kitabında gerçek zamanlı kontrol, simüle edilmiş uzay ve "cilalama" (polish) katmanlarını tanımlıyor [R21].
- **Wayborne için çıkarım:** Sıra tabanlı bir oyunda bile "juice" önemlidir. referans oyun'ın kritik vuruş anındaki yakınlaştırması ve anlatıcı sesi buna örnektir [R22]. Defter arayüzünde mürekkep lekesinin yayılması, para sayma sesi ve borç damgası gibi mikro geri bildirimler, düşük bütçeyle yüksek etki sağlar.

### 2.13 İlk Kullanıcı Deneyimi (FTUE) ve İlk 10 Dakika

- **Kaynak:** Andersen ve ark. (2012), 45.000'den fazla oyuncuyla yaptıkları deneylerde öğreticilerin yalnızca karmaşık oyunlarda belirgin fark yarattığını buldu. Bağlama duyarlı (just-in-time) yardımın, öne yüklenmiş öğreticilerden daha etkili olduğunu gösterdiler [R78].
- **Kaynak:** Steamworks'ün Next Fest belgesi, demo ana menüsüne bir geri bildirim bağlantısı eklemeyi öneriyor [R61]. Zukowski, Next Fest öncesinde demonun yayıncılarca test edilmesini öneriyor, çünkü ilk günkü bir hata demoyu "bitirebilir" [R59].
- **Wayborne için çıkarım:** Wayborne karmaşık bir oyun. Andersen'in bulgusuna göre öğretim gerekli. Ancak öğretim, ilk yolculuğun içine yayılmalı. Önerilen akış: ilk 3 dakikada ilk karar, ilk 10 dakikada ilk savaş ve ilk kayıp tehdidi.

### 2.14 Elde Tutma: Oturum, "Bir Koşu Daha" ve Ödül Takvimleri

- **Kaynak:** Hopson (2001), davranışçı psikolojiden ödül takvimlerini oyun tasarımına uyguladı. Değişken oranlı ödüllerin süreklilik ve tekrar oynamayı artırdığını, ancak etik sınırlar gözetilmesi gerektiğini anlattı [R79].
- **Wayborne için çıkarım:** Doğal bir oturum birimi tanımlanmalı. Önerim "bir şehirden diğerine bir sefer" (20–40 dakika). Her sefer bir kapanış anı (şehre varış, hesap kapama) ve bir açık uç (yeni söylenti, ödenmemiş borç) ile bitmeli. Böylece oyuncu "bir sefer daha" diye devam eder. Günlük seri (streak) gibi mobil mekanikler PC'de tek oyunculu bir oyun için uygun değil. Bu yöntem önerilmez.

### 2.15 Zorluk Ayarı

- **Kaynak:** Hunicke (2005), dinamik zorluk ayarlamasının (DDA) oyuncuya hissettirilmeden yapılabileceğini, ancak saydamlığın etik ve algısal açıdan önemli olduğunu tartıştı [R80].
- **Kaynak:** referans oyun'ın Erken Erişim döneminde ceset ve kalp krizi mekanikleri tepki aldı. Geliştiriciler bu mekanikleri kapatma seçenekleri ekledi [R36].
- **Wayborne için çıkarım:** Zorluk ayarları **mekanik bazında** sunulmalı. Örnekler: kalıcı ölüm kapalı, açlık yumuşatılmış. Gizli DDA yerine şeffaf seçenekler tercih edilmeli. referans oyun'ın deneyimi, "zalim" tasarımın bile bir kapatma seçeneğine ihtiyaç duyabileceğini gösteriyor.

---

## 3. Karşılaştırmalı Oyun Analizi

### 3.1 Özet Tablo

| Oyun | Çekirdek kanca | Oturum yapısı | Satış (doğrulama düzeyi) | Kaynak |
|---|---|---|---|---|
| referans oyun (2016) | Stres/ilinti (affliction), çaresizlik estetiği, anlatıcı | Zindan seferi + mezra yönetimi | 1M (Kas. 2016), 6M (Ara. 2022) — **resmî** | [R33][R32] |
| referans oyun II (2023) | Posta arabasıyla "roguelite yolculuk", ilişki sistemi | Tek koşulu yolculuk | Steam çıkışıyla 600k+ — **resmî** | [R34] |
| The Banner Saga (2014) | Kervan yolculuğu + taktik savaş + seçim sonuçları | Bölüm/yolculuk | ~1M (SteamPulse/VGI) — **tahmin** | [R30][R31] |
| FTL (2012) | Gemi kaptanlığı fantezisi, sektör haritası | 1–2 saatlik koşu | Satış verisi doğrulanamadı | [R23] |
| 80 Days (2014) | Dünya etrafında yarış, metin tabanlı seçimler | Tek koşu, ~1–2 saat | Satış verisi doğrulanamadı. TIME 2014 Yılın Oyunu | [R24][R55] |
| Sunless Sea (2015) | Karanlık okyanus, yakıt/yiyecek/korku, edebî yazım | Uzun keşif seferleri | 100k (Şub. 2015), 350k (Haz. 2018) — **resmî/ikincil** | [R29] |
| Sunless Skies (2019) | Aynı formül, gökyüzünde | — | Sunless Sea'nin aynı dönemdeki satışının ~%15'i — **resmî** | [R28] |
| Dredge (2023) | Rahat balıkçılık + Lovecraft korkusu | Gün/gece döngüsü | 1M+ (Eki. 2023) — **resmî** | [R37] |
| Inscryption (2021) | Deste kurma + meta-anlatı sürprizi | Koşu + perde yapısı | 3 ayda 1M — **resmî** | [R38] |
| Slay the Spire (2019) / 2 (2026) | Rogue-like deste kurma | 30–60 dk koşu | StS: 1,5M (2019); StS2: ilk hafta 3M+ — **resmî** | [R39][R40] |
| Against the Storm (2023) | Roguelite şehir kurma | 1–2 saatlik yerleşim | 2M (Ağu. 2026, tüm platformlar) — **resmî** | [R41] |
| Wartales (2023) | Paralı asker grubu, açık dünya, ücret/yiyecek | Serbest | Steam'de 1M+ (Kas. 2024) — **resmî** | [R43] |
| Kenshi (2018) | Sınırsız sandbox, zalim dünya | Serbest | 3M (May. 2026) — **resmî** | [R44] |
| Frostpunk (2018) | Ahlaki ikilemler, toplum gerilimi | Senaryo | 5M+ (Nis. 2024) — **resmî** | [R45] |
| Cultist Simulator (2018) | Kart tabanlı Lovecraft anlatısı | Oturumlar/koşular | ~105k ilk yıl, 1,76M $ brüt — **resmî** | [R46] |
| Battle Brothers (2017) | Paralı asker şirketi, kalıcı ölüm | Kampanya | 634k (Raijin) ile 1,96M (Vaporlens) arası — **tahmin, çelişkili** | [R53] |
| Pacific Drive (2024) | Yolculuk-hayatta kalma, araba bakımı | Sefer | 600k (Tem. 2024), 1M (Şub. 2025) — **resmî** | [R47] |
| Keep Driving (2025) | Yol gezisi RPG'si, FTL/Oregon Trail II etkisi | Yolculuk | ~440k (Vaporlens) — **tahmin**. Çıkış öncesi 170k+ istek listesi | [R48] |
| Caravan SandWitch (2024) | Rahat kervan keşfi | Açık dünya | 54k–244k (kaynaklar çelişiyor) — **tahmin** | [R49] |
| Caravan (2016) | Kervan ticaret + roguelike öğeleri | Sefer | Doğrulanamadı | [R52] |
| The Oregon Trail (2021/22) | Klasik yolculuk, temsiliyet güncellemesi | Yolculuk | Steam: "Çoğunlukla Olumlu", son dönem "Karışık" (anlık görüntü) | [R51] |
| Book of Travels (2021) | "Minik MMO" yolculuk RPG'si | Çevrimiçi | Başarısız. Ekip 35'ten ~10'a indi, sunucular 2026'da kapandı | [R50] |

### 3.2 Yolculuğu İlginç Kılmak: Beş Model

1. **The Banner Saga — Hız ile bakım arasındaki gerilim.** Stoic, açık dünya keşfi için kaynakları olmadığını, bunun yerine kervan yolculuğunu kullandığını söylüyor. Tasarımı "King of Dragon Pass ile Oregon Trail karışımı" olarak tanımlıyor. Yönetilen üç değer var: dayanıklılık, moral ve erzak. Olaylar bu değerlere göre tetikleniyor [R30]. Erzak bittiğinde kervan üyeleri ölmeye başlıyor. Düşük moral ise savaşta irade (willpower) cezası veriyor [R30]. **Eleştiri:** Tek para birimi olan "renown" hem erzak hem karakter gelişimi için harcanıyor. İncelemeler bu dengenin çok zorlayıcı olduğunu belirtiyor [R30]. **Ders:** Ortak para birimi gerilim yaratır, ama oyuncu "hiçbir şey yapamıyorum" hissine düşmemeli.
2. **FTL — Tek bir duygu, esnek mekanik.** Subset Games, tasarımı tek bir hisse kilitledi: yıldız gemisi kaptanı olmak. Bunun dışındaki tür ve mekanik kararları esnek tuttu [R23]. Sektör haritası, her adımda "risk mi, ödül mü" seçimi sunuyor. **Ders:** Wayborne'un tek cümlelik deneyim hedefi "karanlık bir dünyada kervan başı olmak" olmalı. Her özellik bu hisse göre değerlendirilmeli.
3. **80 Days — Rota kararı = anlatı kararı.** Inkle'ın tasarım sabiti "istediğin rotadan dünya turu" idi. Bu sabit, tasarım kararlarını test etmek için bir ölçüt oldu [R24]. Para, zaman ve eşya, anlatı seçimleriyle iç içe geçiyor. **Ders:** Haritadaki her şehir seçimi, mekanik bir karar olduğu kadar hikâye vaadi de taşımalı.
4. **Sunless Sea — Kaynak + korku + edebî yazım.** Yakıt, yiyecek ve "terör" değerleri yolculuğu sürekli bir gerilime dönüştürüyor. Oyun, 3 kişilik çekirdek ekiple yaklaşık 15 ayda yapıldı [R26]. **Uyarı:** Sunless Skies, Sunless Sea'nin aynı dönemdeki satışının sadece ~%15'ine ulaştı. Failbetter bunu kısmen erken bir Erken Erişim kararına ve değişen pazara bağladı [R27][R28].
5. **Oregon Trail ve modern yorumları.** The Oregon Trail (2021), Yerli Amerikan karakterleri ve akademik danışmanlarla temsiliyeti güncellediğini belirtiyor [R51]. Keep Driving ise FTL ve Oregon Trail II'den açıkça ilham alan, araç-içi bir yol gezisi RPG'si olarak sunuldu. "Çok Olumlu" incelemeler aldı [R48]. Oyunculardan gelen eleştiriler tekrar eden mekanikler ve sınırlı içerik üzerine yoğunlaştı [R48]. **Ders:** Yolculuk türünün en sık şikâyeti **tekrardır**. Olay havuzunun derinliği ve olay zincirleri, içerik planının merkezinde olmalı.

### 3.3 referans oyun: Bağlanma ve Stres Draması

- Tyler Sigman'ın GDC 2016 konuşmasının önemli bir kısmı ilinti (affliction) ve stres sistemlerine ayrılmıştı. Bu sistemler Erken Erişim boyunca fazla değişmedi [R22].
- Sigman, ilhamın oyunlardan değil insan deneyiminden geldiğini söylüyor. Band of Brothers'ta bir karakterin bombardıman altında çözülmesini örnek veriyor. Oyunun "ruh sağlığı" hakkında değil, "strese verilen insani tepki" hakkında olduğunu vurguluyor [R22].
- Mekanik: 100 stres puanında bir irade sınavı yapılır. Çoğunlukla olumsuz bir ilinti (ör. paranoya), nadiren olumlu bir erdem (virtue) ortaya çıkar [R22].
- **Bağlanma kaynakları:** Kahramana ad verilmesi, kalıcı huylar (quirk), anlatıcının dramatik yorumları ve ölümün kalıcılığı. Bu öğeler SDT'nin "ilişkili olma" ihtiyacını karşılar [R1].
- **Ticari kanıt:** İlk 12 ayda 650k+ kopya, Kasım 2016'da 1M (satışların %94'ü Steam'den), Aralık 2022'de 6M [R33][R32].
- **Eleştiriler:** Oyuncular RNG'nin "adaletsiz" hissettirdiği anları ve geç oyundaki tekrarı eleştirdi. Ceset mekaniği de tartışma yarattı. Bu tepkiler sonrasında kapatma seçenekleri eklendi [R36].

### 3.4 Soy ve Halef Sistemleri

- **Rogue Legacy:** Her varis rastgele huylarla gelir (renk körlüğü, devlik vb.). Bu sistem "genetik olarak farklı bir çocuk" hissi verir. Oyuncu ölümden sonra üç varis arasından seçim yapar [R54]. Rogue Legacy 2'de varis seçiminin ve ölümün etkisi artırıldı [R54].
- **Crusader Kings serisi:** Oyuncu bir kişiyi değil, bir **hanedanı** oynar. Karakter öldüğünde oyun varisle devam eder. Veraset yasaları (ör. kısmi miras ile primogeniture) mirasın bölünmesini belirler. Bu bölünme, ölümü stratejik bir krize dönüştürür [R76].
- **Wayborne için sentez:**
  - Varis, öncekinden somut özellikler devralmalı. Örnekler: borç, itibar, bir düşman, bir lonca ilişkisi. Rogue Legacy tarzında bir yeni huy da gelmeli.
  - CK tarzı bir "miras krizi" de eklenebilir. Örnek: Varis küçük yaşta olabilir, ya da kervan içinde bir hak iddiacısı ortaya çıkabilir.
  - Waybook, hanedanın kronikleri gibi işleyebilir. Önceki kervan başlarının sayfaları defterde kalır. Bu, ölümü bir "bölüm sonu" anına dönüştürür.

### 3.5 Ton + Sürpriz: Dredge ve Inscryption

- **Dredge:** Rahat balıkçılık oyunu görünümü, Lovecraftvari korkuyla birleşiyor. Black Salt Games ilk yıl için ~100 bin satış hedeflemişti. Bu hedefe ilk 24 saatte ulaştılar ve Ekim 2023'te 1 milyonu geçtiler [R37]. **Ders:** Tanıdık bir döngünün içine yerleştirilen tonal kontrast, güçlü bir pazarlama kancası oluşturuyor.
- **Inscryption:** Deste kurma oyununu bir meta-anlatı sürpriziyle birleştirdi. Üç aydan kısa sürede 1 milyon sattı [R38]. **Ders:** Bir sürpriz ya da "gizli katman", kulaktan kulağa yayılmayı (word of mouth) ve yayıncı içeriğini besler. Ancak Wayborne için büyük bir sürpriz bir zorunluluk değil, bir seçenektir. Daha düşük riskli bir alternatif, haritada ilerledikçe dünyanın "gerçek" doğasının ortaya çıkmasıdır (Loewenstein [R9]).

### 3.6 Başarısızlıklardan ve Düşük Performanstan Dersler

| Vaka | Ne oldu | Wayborne için ders |
|---|---|---|
| Sunless Skies | Satışlar, Sunless Sea'nin ~%15'inde kaldı. Erken Erişime çok erken girildi, basın penceresi kaçırıldı [R27][R28] | Hazır olmadan Erken Erişime girme. Steam'in "Popular Upcoming" görünürlüğünü bir kez kullanabilirsin [R56] |
| The Banner Saga 2 | Gelir, ilk oyunun yaklaşık üçte biri civarında kaldı. Stoic, rekabetin 70 oyundan 400 oyuna çıktığını belirtti [R31] | Çıkış tarihini rekabeti göz önüne alarak seç |
| referans oyun II | Mezranın kaldırılması ve "sıkıcı posta arabası yolculuğu" şikâyetleri. Red Hook araba dayanıklılığı gibi yamalarla yanıt verdi [R35] | Yolculuk sahnesi pasif kalmamalı. Kalıcı ilerleme kaybı tamponlanmalı |
| Book of Travels | Çıkış beklentinin altında kaldı. Ekip 35'ten ~10'a indi, 2026'da sunucular kapandı [R50] | Kapsam büyüklüğü küçük ekip için ölümcül olabilir. Wayborne'un tek oyunculu olması bu açıdan doğru bir karar |
| Slay the Spire (erken dönem) | İlk günlerde ~800 kopya sattı. Çinli yayıncıların ilgisiyle satışlar yükseldi [R39][R72] | Yavaş bir çıkış ölüm fermanı değil. Yayıncı/streamer ilgisi oyunu kurtarabilir. Yerelleştirme (özellikle Basitleştirilmiş Çince) önemli |

### 3.7 Steam İnceleme Temaları (Sentez)

**Sık övgüler (türün tamamında):**
- Atmosfer ve tutarlı sanat yönetimi (referans oyun, Sunless Sea, Dredge, Keep Driving) [R22][R26][R37][R48]
- Kararların ağırlığı ve "hikâyemin bana ait olması" (RimWorld, Wartales, Kenshi) [R11][R43][R44]
- Müzik ve anlatıcı sesi (referans oyun, Keep Driving) [R22][R48]

**Sık şikâyetler:**
- Tekrar ve geç oyunda angarya (grind) (referans oyun, referans oyun II, Keep Driving) [R36][R35][R48]
- "Adaletsiz" hissettiren rastgelelik (referans oyun) [R36]
- Kaynak dengesinin oyuncuyu çaresiz bırakması (The Banner Saga) [R30]
- Kalıcı ilerlemenin çekirdekten kopukluğu (Against the Storm eleştirisi, referans oyun II) [R42][R35]
- Hatalar ve yerelleştirme kalitesi (Keep Driving) [R48]

---

## 4. Indie PC/Steam Pazarlaması (2024–2026)

### 4.1 İstek Listeleri (Wishlist) ve Dönüşüm

- **Eşik:** Zukowski'nin 2022 tarihli yazısı "en az ~7.000 istek listesi" önerir. Yazıya göre bazı oyunlar, rekabetin zayıf olduğu haftalarda ~5.500 ile Popular Upcoming listesine girmiş [R56].
- **Popular Upcoming:** Önümüzdeki 7 günde çıkacak en çok istek listesine eklenen 10 oyunu gösterir. Listede yer almak günde ~1.000 istek listesi getirir. Bir oyun bu listeye **yalnızca bir kez** girebilir. Yetersiz istek listesiyle Erken Erişime girmek bu hakkı harcar [R56].
- **Önemli güncelleme:** Zukowski, bu yazıyı Haziran 2026'da Valve'in "Personalized Calendar" özelliğini başlatması nedeniyle "arşiv/güncel değil" olarak işaretledi [R56]. Yeni sistemin etkisine dair doğrulanmış bir veri bulamadım. **7.000 eşiği bir taban olarak kullanılmalı, garanti olarak değil.**
- **Dönüşüm oranları:** GameDiscoverCo'nun 2024 anketine göre 10 binden fazla istek listesiyle çıkan oyunlarda ilk hafta medyan dönüşüm **0,17×**. 25 binden fazlası için **0,15×**. **10 doların üzerindeki oyunlar için 0,10×** [R57]. Dağılım çok geniş: medyanın %10'u ile 10 katı arasında değişiyor [R57].
- **Wayborne hesabı (açıklayıcı):** 15–20 dolarlık bir fiyatla 20.000 istek listesiyle çıkış yapılırsa, 0,10× oranıyla ilk hafta yaklaşık **2.000 satış** beklenebilir. Bu, medyan bir senaryodur, tahmin değildir.
- **Diğer kanallar:** Zukowski, her festivalin ~1.000–3.000 istek listesi getirebileceğini ve Facebook/Reddit/TikTok reklamlarında 1 istek listesinin ~1 dolara mal olduğunu aktarıyor [R56].

### 4.2 Steam Next Fest ve Demo Stratejisi

- **Valve'in kuralları:** Next Fest'e yalnızca demosu olan oyunlar katılabilir. Valve, katılımcı listesini etkinlikten 10 gün önce basına iletir. Kategori seçilmezse oyun festivalde görünmez. Demo menüsünde bir geri bildirim bağlantısı bulunmalı [R61].
- **Ölçek:** Haziran 2025 Next Fest'inde 2.600'den fazla demo vardı [R63]. Ekim 2025'te Valve'in ilk 10 listesinde yalnızca bir oyunun var olan bir fikrî mülke (IP) dayandığı görüldü [R63]. Bu, yeni IP'lerin de öne çıkabildiğini gösteriyor.
- **Demo-dönüşüm ilişkisi:** Alinea Analytics'in Ekim 2025 analizinde demo oynama oranları oyuna göre %16,7 ile %29,5 arasında değişti [R64].
- **Demo uzunluğu:** Üçüncü taraf rehberler, kendi içinde tamamlanmış, 15–40 dakikalık ve bilinçli bir kancayla biten demolar öneriyor [R61][R62]. Bu bir Valve kuralı değil, bir uygulama tavsiyesi.
- **Zamanlama:** Next Fest'e sadece bir kez katılınabildiği bildiriliyor [R61]. Demonun festivalden birkaç hafta önce yayınlanması yaygın bir tavsiye [R62].
- **Wayborne için:** Demonun kapsamı "ilk sefer + ilk ölüm/varis anı" olmalı. Soy sisteminin demoda görülmesi en güçlü kanca olur.

### 4.3 Kapsül Görseli

- Zukowski'ye göre kapsül sanatı, bütçe kısıtlıysa para harcanması gereken **ilk** kalemdir. Fragman, reklam veya fuardan önce gelir [R59]. Kapsülün görevi, oyunun ne olduğunu bir bakışta göstermektir. Önerilen yöntem, sanatçıya türün en başarılı oyunlarından örnekler gösterip ortak özellikleri aktarmaktır [R58].
- **Clanfolk vakası:** Daha renkli ve dikkat çekici bir kapsüle geçildikten sonra aynı yayıncının ikinci videosu ~%230 daha fazla izlenme aldı [R59]. Zukowski, yayıncıların bir oyunu seçip seçmemesinde kapsülün etkili olduğunu söylüyor.
- **Wayborne için:** Kapsülde kervan silueti, karanlık bir yol ve parşömen haritasının bir kenarı birlikte görünmeli. "Mürekkep-parşömen" estetiği, karanlık fantezi türünü bir bakışta okutabilmeli. Kapsül sanatı yapay zekâ ile üretilmemeli (bkz. §4.10).

### 4.4 Fragman: İlk Saniyeler

- Derek Lieu'nün tavsiyeleri kaynaklar arasında tutarlı: Fragman **oynanışla açılmalı**. Kancaya ilk 10–15 saniyede, en geç fragmanın ilk yarısında ulaşılmalı. Logolar, siyah ekranlar ve yavaş geçişler başta kullanılmamalı. Sıra şöyle olmalı: tür → kanca → içerik [R60].
- Zukowski'nin aktarıldığı kaynaklara göre oynanış gösterdiği sürece ~30 saniyelik bir fragman yeterli [R59].
- **Wayborne için önerilen ilk 5 saniye:** Harita üzerinde kervanın ilerlediği bir mürekkep çizgisi, ardından bir pusu ve savaşa geçiş. 10. saniyede bir kervan başının ölümü, 15. saniyede "Varisin devraldı" anı.

### 4.5 Etiketler ve Tür Konumlandırması

- Zukowski'nin 2019–2022 analizine göre roguelike deste kurma oyunları medyan satışta tüm indie türlerin önündeydi. Platform oyunları, FPS ve kule savunması gibi türlerin ise "fazla arz" sorunu vardı [R65]. 2024'ün ilk yarısında 1.000'den fazla inceleme alan oyunlar arasında korku ve co-op öne çıktı. YouTube izlenmelerinde RPG ilk sırada, strateji ikinci sıradaydı [R65].
- Zukowski'nin "hit" eşiği ~1.000 inceleme, bu da kabaca 300 bin dolar brüt gelire karşılık geliyor [R65].
- **Wayborne için önerilen etiket önceliği:** *RPG*, *Turn-Based Combat*, *Roguelite*, *Dark Fantasy*, *Management*, *Trading*, *Permadeath*, *Medieval*, *Choices Matter*, *Story Rich*. Steam etiketlerinde ilk sıradaki etiketler en görünür olanlar. "referans oyun benzeri" algısı ilk etiketlerde kurulmalı.

### 4.6 Yayıncı/YouTube Çekiciliği ve "Kliplenebilir Anlar"

- Zukowski, yayıncıların bir oyunu seçmesinde kapsülün rolünü vurguluyor. Ayrıca bir Next Fest demosunun ilk gün çıkacak bir hatayla "bitebileceği" uyarısında bulunuyor [R59].
- Slay the Spire'ın erken dönemde Çinli yayıncılar sayesinde yükselmesi, yayıncı ilgisinin satışlara etkisini gösteriyor [R39][R72].
- **Kliplenebilir an tasarımı (çıkarım):** referans oyun'ın ilinti (affliction) anı ("Paranoyak!"), kendi kendine ortaya çıkan, kısa ve dramatik bir klip yaratır [R22]. Wayborne'da da aynı işlevi görecek anlar tasarlanmalı: bir kervan başının ölümü, bir varisin tahta çıkışı, bir borç tahsildarının gelişi. Bu anlar 10–20 saniyelik, sesli ve görsel olarak "patlayan" anlar olmalı.

### 4.7 Discord, Topluluk ve Devloglar

- Steamworks, demoda bir Discord veya forum bağlantısı önerir [R61].
- Zukowski'nin aktardığı bir vakada iyi hazırlanmış tek bir Reddit gönderisi (30 saniyelik bir fragman) ~11.000 istek listesi getirdi [R56].
- **Wayborne için:** Devloglar, oyunun "nasıl yapıldığı" yerine ortaya çıkan hikâyeleri anlatmalı. Örnek: "Bu hafta oyun testinde bir varis, babasının borcunu ödemek için kervanı sattı." Bu tür içerik Sylvester'in hikâye üreteci fikrini pazarlamaya taşır [R11].

### 4.8 Fiyatlandırma

- GameDiscoverCo verilerinde 10 doların üzerindeki oyunların ilk hafta dönüşümü daha düşük (0,10×) [R57]. Ancak bu, toplam gelirin düşük olduğu anlamına gelmiyor.
- Jake Birkett, kart oyunu nişinde 9,99–14,99 dolar fiyat aralığını "makul sanat bütçesi ve oyun süresiyle" tercih ettiğini söylüyor [R66]. Birkett'in GDC 2016 konuşması, uzun kuyruk satışlarının ve oyun kataloğunun önemine odaklanıyor [R66].
- **Wayborne için:** Karşılaştırmalı oyunlar 15–25 dolar aralığında. Önerim 14,99–19,99 dolar. Çıkış indirimi %10–15 civarında tutulmalı. Kesin bir fiyat tavsiyesi için içerik saati ve rakip fiyatlarıyla güncel bir analiz gerekli.

### 4.9 Çıkış Zamanlaması

- Banner Saga 2 vakası, rekabetin önemini gösteriyor. Stoic, çıkış penceresindeki oyun sayısının 70'ten 400'e çıktığını belirtiyor [R31].
- Popular Upcoming, haftalık rekabete göre çalışır. Aynı hafta çıkan büyük bir oyun, küçük oyunu listeden itebilir [R56].
- Ekim 2026 Next Fest'i 19–26 Ekim olarak bildiriliyor (üçüncü taraf kaynak, Steamworks üzerinden doğrulanmalı) [R61 bağlamında aktarılan rehber].
- **Wayborne için:** Next Fest'ten 4–10 hafta sonra, büyük indirim dönemleri ve AAA çıkışlarıyla çakışmayan bir hafta seçilmeli. GameDiscoverCo verilerinde Şubat ve Ağustos'ta dönüşüm sıçramaları görülüyor [R57]. Bu bilgi bir ipucu olarak değerlendirilmeli.

### 4.10 Steam'de Yapay Zekâ Bildirimi ve Algısı

- **Kural (2024):** Valve, yapay zekâ kullanımını içerik anketinde ikiye ayırdı: **önceden üretilmiş** (geliştirme sırasında) ve **canlı üretilen** (oyun çalışırken). Bildirimler mağaza sayfasında gösteriliyor [R67].
- **Kural (Ocak 2026):** Kod asistanları ve hata ayıklama araçları gibi yalnızca geliştirme sürecinde kullanılan araçlar bildirim zorunluluğundan çıkarıldı. **Oyunda, mağaza sayfasında veya pazarlama materyallerinde** oyuncunun gördüğü yapay zekâ içeriği ise hâlâ bildirilmek zorunda [R68].
- **Ölçek:** Totally Human'ın Temmuz 2025 analizine göre Steam kataloğunun ~%7'si (7.818 oyun) ve 2025'te çıkan oyunların ~%20'si yapay zekâ kullanımını bildirmiş. Bu, 2024'ün aynı dönemine göre ~%800'lük bir artış [R69].
- **Algı ve ticari etki:** Game Oracle'ın 9.879 oyunluk analizi, yayıncı, geliştirici deneyimi ve tür kontrol edildiğinde yapay zekâ bildiren oyunların **~%52,6 daha az inceleme** aldığını buldu [R70]. İnceleme sayısı satışlar için yalnızca bir göstergedir ve nedensellik kanıtlanmamıştır [R70].
- **Sert bir örnek:** Indie Game Awards, Aralık 2025'te Clair Obscur: Expedition 33'ün Yılın Oyunu ödülünü geri aldı. Gerekçe, oyunda kısa süre bulunan ve yamayla kaldırılan yapay zekâ ile üretilmiş doku görselleriydi [R71].
- **Wayborne için çıkarım:**
  1. Yapay zekâ destekli **kod** artık bildirim kapsamında değil [R68].
  2. Yapay zekâ destekli **sanat** oyuncunun gördüğü içerikte yer alıyorsa bildirilmeli [R68]. Bu ciddi bir ticari risk taşıyor [R70].
  3. Önerilen strateji: Kapsül, fragman, mağaza ekran görüntüleri ve kahraman portreleri gibi en görünür varlıklar **insan eliyle** yapılmalı veya elden geçirilmeli. Yapay zekâ kullanılan alanlar bildirimde dürüst ve özel bir dille anlatılmalı. Örnek: "Arka plan dokularının ilk taslakları yapay zekâ ile üretildi ve el ile yeniden boyandı." Bildirimin gizlenmesi ya da eksik yapılması, Clair Obscur örneğindeki gibi çok daha büyük bir tepki riski yaratır [R71].

---

## 5. Sentez: Kanıta Dayalı 34 Öneri

### A. Çekirdek Tasarım

1. **Tek cümlelik deneyim hedefi belirle ve her özelliği bu cümleye göre değerlendir.** Önerilen cümle: "Karanlık bir dünyada, borç ve ölüm gölgesinde bir kervanı ve hanedanı ayakta tutmak." — [R23][R24][R6]
2. **Hedef estetikleri MDA çerçevesiyle yazılı hale getir.** Önerilen estetikler fantezi, meydan okuma, anlatı ve keşif. Her mekanik bunlardan birine bağlanmalı. — [R6]
3. **Yolculuğu bir karar sahnesine dönüştür.** Her yol bölümünde en az bir anlamlı takas olmalı (hız-güvenlik, erzak-moral). Pasif "yürüme" süresi bırakma. — [R16][R30][R35]
4. **Hız ile bakım arasındaki gerilimi çekirdeğe koy.** Hızlı gitmek açlık ve stresi artırmalı. Kamp yapmak zaman ve erzak tüketmeli. — [R30]
5. **Tek bir ortak para birimi kullanma ya da dikkatli kullan.** Banner Saga'daki "renown" ikilemi gerilim yaratır, ama "çaresizlik" şikâyetine yol açar. Erzak ve gelişimi ayrı ekonomilere böl, ya da en azından oyuncuya bir kurtuluş yolu (ör. borç alma) bırak. — [R30]
6. **Lonca kredisi ve borç sistemini bir "kurtuluş vanası" olarak tasarla.** Oyuncu çıkmaza girdiğinde borç alabilmeli. Borcun bedeli ileride, örneğin varise miras olarak ortaya çıkmalı. Bu, kayıptan kaçınmayı dramatik bir gerilime dönüştürür. — [R17][R76]
7. **Stres ve moral eşiklerinde dramatik "kırılma anları" tasarla.** referans oyun'daki gibi 100 puanda bir sınav olmalı. Sonuç çoğunlukla olumsuz, nadiren kahramanca olmalı. Bu sistem insani tepkilerden ilham almalı. — [R22]
8. **Kervan üyelerine kişilik ver.** Ad, geçmiş, huylar ve en az bir ilişki bağı olmalı. Bağlanma, kaybın anlamlı olmasının ön koşuludur. — [R1][R22]
9. **Soy ve halef sistemini oyunun imzası yap.** Varis; borç, itibar, düşman ve lonca ilişkisini devralmalı. Ayrıca rastgele bir huy da gelmeli. Ölüm bir "bölüm sonu" anı olarak sahnelenmeli. — [R54][R76][R17]
10. **Kalıcı ilerlemeyi dünyanın içine yerleştir.** Açılan ticaret yolları, hanedan defteri ve lonca kredisi gibi. Soyut bir puan menüsü kullanma. — [R42][R35]
11. **Kalıcı ölüm için bir "tampon" bulundur.** Oyuncu varisle devam edebilmeli. Asla tamamen sıfırdan başlamamalı. Bu tampon olmazsa referans oyun II'deki "başa dönüş" şikâyetleri tekrarlanır. — [R35][R75]

### B. İçerik ve Anlatı

12. **Olay seçimini bir "yol yönetmeni" (storyteller) ile yönet.** Yönetmen, kervanın stres, açlık ve borç durumuna göre olay seçmeli. Gerilim artışı → zirve → rahatlama döngüsü uygulamalı. — [R18][R19][R77]
13. **Olay havuzunun büyüklüğünden çok, olaylar arasındaki algısal farklılığa yatırım yap.** Her olay, oyuncunun kararını değiştirecek kadar farklı olmalı. Aksi halde "yulaf ezmesi" sorunu yaşanır. — [R15]
14. **Olay zincirleri kur.** Bir olaydaki seçim, sonraki bir şehirde ya da sonraki bir varisin döneminde karşılık bulmalı. Bu, yolculuk türünün en büyük şikâyeti olan tekrarı azaltır. — [R48][R36][R24]
15. **Her olayda anlatısal açıdan cazip ama mekanik açıdan riskli bir seçenek sun.** — [R25][R16]
16. **Waybook'u bir küratörlük aracı olarak kullan.** Simülasyonda yaşananları otomatik olarak anlatı cümlelerine dönüştür. Oyuncunun "kendi hikâyesi" böylece görünür olur ve paylaşılabilir hale gelir. — [R12][R11]
17. **Haritada "yarı bilinen" bölgeler bırak.** Söylentiler, eksik çizimler ve kenar notları bilgi boşluğu yaratır. Keşif bu boşlukları doldurmalı. — [R9][R26]
18. **Tonal kontrast ve aşamalı bir "dünya sırrı" kullan.** Büyük bir sürpriz zorunlu değil, ama dünyanın gerçek doğasının yavaş yavaş açığa çıkması kulaktan kulağa yayılmayı besler. — [R37][R38][R9]

### C. Kullanıcı Deneyimi ve İlk Saatler

19. **Öğretimi ilk yolculuğun içine yay.** Bağlama duyarlı ipuçları kullan. Önde bir öğretici duvarı oluşturma. — [R78]
20. **İlk 10 dakikalık bir hedef zaman çizelgesi belirle.** İlk 3 dakikada ilk anlamlı karar. İlk 10 dakikada ilk savaş ve ilk kayıp tehdidi. — [R78][R59]
21. **Defter arayüzünü geri bildirim kanalı olarak tasarla.** Oyuncu her sonucun nedenini görebilmeli (ör. "moral -10: açlık, 2 gün"). Bu, ustalık ihtiyacını karşılar. — [R1][R4]
22. **Sıra tabanlı savaşta "juice"a yatırım yap.** Kritik vuruşta yakınlaştırma, anlatıcı sesi, mürekkep efektleri ve ses kullan. — [R20][R21][R22]
23. **Zorluğu mekanik bazında ve şeffaf biçimde ayarlanabilir yap.** Kalıcı ölüm ve açlık şiddeti gibi ayarlar sun. Gizli DDA yerine açık seçenekler tercih et. — [R80][R36][R4]

### D. Elde Tutma

24. **Doğal oturum birimini "bir sefer" olarak tanımla.** Hedef süre 20–40 dakika olmalı. Her sefer bir kapanış ve bir açık uçla bitmeli. — [R79][R40]
25. **"Bir koşu daha" hissi için her ölümde yeni bir merak kancası aç.** Varisin farklı bir huyu veya yeni bir söylenti olabilir. — [R9][R54]
26. **Yerelleştirmeyi baştan planla.** Basitleştirilmiş Çince öncelikli olmalı. Metin tabanlı olaylar için yerelleştirme dostu bir veri yapısı kur. — [R39][R72][R48]

### E. Pazarlama

27. **Steam sayfasını mümkün olduğunca erken aç.** Hedef: çıkışta en az ~7.000, ideal olarak 15–20 binin üzerinde istek listesi. Haziran 2026 sonrası Steam değişikliğini izlemeye devam et. — [R56][R57]
28. **Bütçenin ilk kalemini insan eliyle yapılmış kapsül sanatına ayır.** Türün başarılı kapsüllerinden referans toplayıp sanatçıya ver. — [R58][R59][R70]
29. **Fragmana oynanışla başla.** Kanca ilk 10–15 saniyede gösterilmeli. Önerilen kanca "kervan başı ölür, varis devralır" anı. — [R60]
30. **Demoyu "ilk sefer + ilk varis anı" olarak kurgula.** Demoyu Next Fest'ten birkaç hafta önce yayınla. Menüde bir geri bildirim bağlantısı olsun. Demoyu yayıncılarla önceden test et. — [R61][R62][R59][R64]
31. **Erken Erişime ancak oyunun içeriği hazır olduğunda gir.** Popular Upcoming listesine girme hakkı tek seferlik. — [R27][R28][R56]
32. **Kliplenebilir anları bilinçli olarak tasarla ve pazarlamada kullan.** Kırılma anları, ölüm/tahta çıkış sahneleri ve borç tahsildarı gibi. Devloglarda ortaya çıkan oyuncu hikâyelerini paylaş. — [R22][R11][R56]
33. **Çıkış haftasını rekabete göre seç.** Next Fest'ten 4–10 hafta sonrası hedeflenmeli. Büyük AAA çıkışlarıyla çakışmaktan kaçın. — [R31][R56][R57]
34. **Yapay zekâ bildirimini dürüst ve ayrıntılı yap. Görünür varlıklarda yapay zekâ kullanımını en aza indir.** Kod asistanı kullanımı bildirim gerektirmiyor. Oyuncunun gördüğü sanatta yapay zekâ kullanımı ise inceleme sayısını ve itibarı ciddi şekilde etkileyebilir. — [R67][R68][R69][R70][R71]

---

## 6. Riskler ve Açık Sorular

| Risk | Olasılık | Etki | Azaltma |
|---|---|---|---|
| Yolculuğun tekrara düşmesi | Yüksek | Yüksek | Öneri 3, 12–14 |
| Yapay zekâ bildirimi nedeniyle görünürlük ve itibar kaybı | Orta–Yüksek | Yüksek | Öneri 28, 34 |
| Kapsamın küçük ekibi aşması | Yüksek | Yüksek | Book of Travels dersi [R50]. Dikey dilim (vertical slice) öncelikli olmalı |
| Kalıcı ölüm nedeniyle oyuncunun oyunu bırakması | Orta | Orta | Öneri 9, 11, 23 |
| Haziran 2026 Steam değişikliği sonrası istek listesi eşiklerinin belirsizliği | Orta | Orta | GameDiscoverCo ve Zukowski'nin güncel verilerini izle [R56][R57] |

**Açık sorular:**
- Personalized Calendar'ın (Haziran 2026) küçük oyunların görünürlüğüne etkisi hakkında doğrulanmış veri bulamadım.
- FTL, 80 Days, Pentiment, Heaven's Vault, Mount & Blade, Expeditions ve Banner of the Maid için güvenilir satış rakamı bulamadım.
- Yapay zekâ bildiriminin etkisine dair Game Oracle verisi korelasyonsaldır. Kalite farkını kontrol etmediği eleştirisi var [R70].

---

## 7. Kaynakça

**Akademik ve tasarım kuramı**

- [R1] Ryan, R. M., Rigby, C. S., & Przybylski, A. (2006). The Motivational Pull of Video Games: A Self-Determination Theory Approach. *Motivation and Emotion*, 30(4), 347–363. https://doi.org/10.1007/s11031-006-9051-8
- [R2] Przybylski, A. K., Rigby, C. S., & Ryan, R. M. (2010). A Motivational Model of Video Game Engagement. *Review of General Psychology*, 14(2), 154–166. https://doi.org/10.1037/a0019440
- [R3] Csikszentmihalyi, M. (1990). *Flow: The Psychology of Optimal Experience*. Harper & Row.
- [R4] Chen, J. (2007). Flow in Games (and Everything Else). *Communications of the ACM*, 50(4), 31–34. https://doi.org/10.1145/1232743.1232769
- [R5] Lazzaro, N. (2004). *Why We Play Games: Four Keys to More Emotion Without Story*. XEODesign. http://www.xeodesign.com/xeodesign_whyweplaygames.pdf
- [R6] Hunicke, R., LeBlanc, M., & Zubek, R. (2004). MDA: A Formal Approach to Game Design and Game Research. AAAI Workshop on Challenges in Game AI. https://users.cs.northwestern.edu/~hunicke/MDA.pdf
- [R7] Yee, N. (2006). Motivations for Play in Online Games. *CyberPsychology & Behavior*, 9(6), 772–775. https://doi.org/10.1089/cpb.2006.9.772
- [R8] Quantic Foundry. Gamer Motivation Model. https://quanticfoundry.com/gamer-motivation-model/
- [R9] Loewenstein, G. (1994). The Psychology of Curiosity: A Review and Reinterpretation. *Psychological Bulletin*, 116(1), 75–98. https://doi.org/10.1037/0033-2909.116.1.75
- [R10] Sylvester, T. (2013). *Designing Games: A Guide to Engineering Experiences*. O'Reilly Media.
- [R11] Sylvester, T. (2017). RimWorld: Contrarian, Ridiculous, and Impossible Design Methods. GDC 2017. https://gdcvault.com/play/1024232/-RimWorld-Contrarian-Ridiculous-and
- [R12] Ryan, J. (2018). *Curating Simulated Storyworlds* (Doktora tezi). UC Santa Cruz. https://escholarship.org/uc/item/1340j5h2
- [R13] Mateas, M., & Stern, A. (2005). Structuring Content in the Façade Interactive Drama Architecture. *AIIDE 2005 Proceedings*, AAAI. https://ojs.aaai.org/index.php/AIIDE
- [R14] Short, T. X., & Adams, T. (Eds.) (2019). *Procedural Storytelling in Game Design*. CRC Press. (Yayınevi kataloğu; URL doğrulanmadı.)
- [R15] Compton, K. (2016). So you want to build a generator… http://galaxykate0.tumblr.com/post/139774965871/so-you-want-to-build-a-generator
- [R16] Meier, S. (2012). Interesting Decisions. GDC 2012. https://www.gdcvault.com/play/1015756/Interesting
- [R17] Kahneman, D., & Tversky, A. (1979). Prospect Theory: An Analysis of Decision under Risk. *Econometrica*, 47(2), 263–291. https://doi.org/10.2307/1914185
- [R18] Booth, M. (2009). The AI Systems of Left 4 Dead. AIIDE 2009 açılış konuşması, Valve. https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf
- [R19] Valve Developer Community. L4D2 Director Scripts. https://developer.valvesoftware.com/wiki/L4D2_Director_Scripts
- [R20] Jonasson, M., & Purho, P. (2012). Juice it or lose it. GDC Europe 2012. https://www.youtube.com/watch?v=Fy0aCDmgnxg
- [R21] Swink, S. (2008). *Game Feel: A Game Designer's Guide to Virtual Sensation*. Morgan Kaufmann.
- [R78] Andersen, E., O'Rourke, E., Liu, Y.-E., Snider, R., Lowdermilk, J., Truong, D., Cooper, S., & Popović, Z. (2012). The Impact of Tutorials on Games of Varying Complexity. *CHI 2012*. https://doi.org/10.1145/2207676.2207687
- [R79] Hopson, J. (2001). Behavioral Game Design. Gamasutra / Game Developer. https://www.gamedeveloper.com/design/behavioral-game-design
- [R80] Hunicke, R. (2005). The Case for Dynamic Difficulty Adjustment in Games. *ACE 2005*. https://doi.org/10.1145/1178477.1178573

**Oyun vakaları ve satış verileri**

- [R22] PC Gamer — How referans oyun got inspiration from Band of Brothers and Aliens (Sigman, GDC 2016 haberi). https://www.pcgamer.com/uk/how-referans oyun-dungeon-got-inspiration-from-band-of-brothers-and-aliens
- [R23] Davis, M., & Ma, J. (2013). Designing Without a Pitch — FTL Postmortem. GDC 2013. https://gdcvault.com/play/1018034/Designing-Without-a-Pitch-FTL
- [R24] Ingold, J., & Humfrey, J. Postmortem: inkle's 80 Days. Game Developer. https://www.gamedeveloper.com/business/postmortem-inkle-s-i-80-days-i-
- [R25] Short, E. (2015). Interactive Narrative GDC Talks (Part 1) — Jayanth, "Leading Players Astray" özeti. https://emshort.blog/2015/04/02/interactive-narrative-gdc-talks-part-1/
- [R26] Kennedy, A. Postmortem: Failbetter Games' Sunless Sea. Game Developer. https://www.gamedeveloper.com/audio/postmortem-failbetter-games-i-sunless-sea-i-
- [R27] Failbetter Games. Sunless Sea sales and funding deep dive, Part III. https://www.failbettergames.com/sunless-sea-sales-and-funding-deep-dive-part-iii-early-access-and-final-release/
- [R28] Failbetter Games. Failbetter update: weathering a storm. https://www.failbettergames.com/news/failbetter-update-weathering-a-storm
- [R29] Wikipedia — Sunless Sea. https://en.wikipedia.org/wiki/Sunless_Sea ; Engadget (2017). https://www.engadget.com/2017/03/03/nautical-horror-game-sunless-sea-heads-to-ipad/
- [R30] GameBanshee — The Banner Saga Interview (Stoic). https://gamebanshee.com/3ay ; Banner Saga Wiki — Caravan. https://bannersaga.fandom.com/wiki/Caravan ; God is a Geek inceleme (2014). https://godisageek.com/2014/01/the-banner-saga-review/
- [R31] Engadget (2017). 'Banner Saga' back to Kickstarter to fund final chapter. https://www.engadget.com/2017-01-25-banner-saga-back-to-kickstarter-to-fund-final-chapter.html ; SteamPulse tahmini. https://steampulse.org/game/237990
- [R32] Game World Observer (2022). referans oyun sales 6 million copies. https://gameworldobserver.com/2022/12/26/referans oyun-dungeon-sales-6-million-copies-red-hook
- [R33] MCV/Develop (2016). referans oyun passes 1 million sales. https://mcvuk.com/articles/pc/referans oyun-dungeon-passes-1-million-sales
- [R34] Game World Observer (2023). referans oyun II sales 600k copies. https://gameworldobserver.com/2023/06/08/referans oyun-dungeon-ii-sales-600k-copies-steam-launch
- [R35] PC Gamer — referans oyun 2 review. https://pcgamer.com/referans oyun-dungeon-2-review ; Steam Topluluğu tartışması. https://steamcommunity.com/app/1940340/discussions/0/3830918083267104058 ; Vaporlens özeti. (referans oyun bağlantısı kaldırıldı)
- [R36] GamersDecide — referans oyun's 3,000+ Negative Reviews. https://gamersdecide.com/pc-game-news/referans oyun-dungeon-s-3000-negative-reviews-too-difficult-be-fun
- [R37] 80.lv (2023). An indie game Dredge has sold over 1 million copies. https://80.lv/articles/an-indie-game-dredge-has-sold-over-1-million-copies/
- [R38] Game Developer (2022). Demonic deck-builder Inscryption passes 1 million sales. https://gamedeveloper.com/business/demonic-deck-builder-inscryption-passes-1-million-sales
- [R39] GamesBeat (2019). Slay the Spire passes 1.5 million copies sold. https://gamesbeat.com/slay-the-spire-passes-1-5-million-copies-sold/ ; Gamasutra. https://gamasutra.com/business/after-a-worrisome-start-i-slay-the-spire-i-has-sold-more-than-1-5-million-copies
- [R40] KitGuru (2026). Slay the Spire II has already sold over 3 million copies. https://www.kitguru.net/desktop-pc/mustafa-mahmoud/slay-the-spire-ii-has-already-sold-over-3-million-copies/
- [R41] Game Developer (2026). Against the Storm hits 2 million copies sold. https://www.gamedeveloper.com/press-release/critically-acclaimed-city-builder-against-the-storm-hits-2-million-copies-sold
- [R42] Game Developer (2023). How Against the Storm managed to mix city-building and roguelite play. https://www.gamedeveloper.com/road-to-igf-2023/how-against-the-storm-managed-to-mix-city-building-and-roguelite-play ; Yang, R. (2023). Design review of Against the Storm. https://www.blog.radiator.debacle.us/2023/06/design-review-of-against-storm-by.html ; Eremite Games — Progression update. https://eremitegames.com/progression-update/
- [R43] Gamespress (2024). Wartales surpasses million units sold. https://gamespress.com/Wartales-Surpasses-Million-Units-Sold-Lays-Siege-in-The-Skelmar-Invasi ; GameDiscoverCo — Wartales: how did it sell 600k copies? https://newsletter.gamediscover.co/p/wartales-how-did-it-sell-600k-copies
- [R44] Game World Observer (2024). Kenshi sales 2.3 million. https://gameworldobserver.com/2024/04/10/kenshi-sales-2-3-million-copies-lo-fi-games ; WN Hub (2026). Kenshi 3 million. https://wnhub.io/news/finance/item-50939
- [R45] Game Developer (2024). Frostpunk has topped 5 million sales in six years. https://gamedeveloper.com/business/frostpunk-has-topped-5-million-sales-in-six-years ; GamesBeat (2019). https://gamesbeat.com/frostpunk-sells-over-1-4-million-copies-in-its-first-year/
- [R46] PC Gamer — Cultist Simulator has sold over 100,000 copies. https://pcgamer.com/cultist-simulator-has-sold-over-100000-copies ; Game Developer — After the Dawn. https://www.gamedeveloper.com/game-platforms/after-the-dawn-a-mini-retrospective-on-cultist-simulator
- [R47] Cosmocover (2025). Pacific Drive hits 1 million. https://www.cosmocover.com/newsroom/one-game-one-year-one-million-ironwood-studios-pacific-drive-hits-top-gear-with-huge-milestone ; Game Developer (2024). https://gamedeveloper.com/business/pacific-drive-sales-drive-past-600k-copies-sold
- [R48] Notebookcheck (2025). Keep Driving launches with Very Positive reviews. https://www.notebookcheck.net/Highly-rated-driving-adventure-RPG-launches-on-Steam-with-Very-Positive-reviews.958107.0.html ; 80.lv — FTL ve Oregon Trail II'den ilham alan sürüş oyunu. https://80.lv/articles/an-atmospheric-pixelated-driving-game-inspired-by-ftl-oregon-trail-ii ; Vaporlens tahmini. https://vaporlens.app/app/2756920/keep_driving/stats/details
- [R49] SteamPulse. https://steampulse.org/game/1582650 ; Raijin. https://raijin.gg/app/1582650/Caravan_SandWitch ; Tech-Gaming inceleme. https://www.tech-gaming.com/caravan-sandwitch/
- [R50] TechRaptor — Book of Travels dev lays off staff. https://techraptor.net/gaming/news/book-of-travels-dev-lays-off-staff-after-tough-launch ; Massively OP (2026). https://massivelyop.com/2026/08/04/this-patch-concludes-the-content-we-have-for-book-of-travels-might-delight-has-sunsetted-its-tiny-mmo/
- [R51] Steam — The Oregon Trail. https://store.steampowered.com/app/2013360/The_Oregon_Trail
- [R52] Steam — Caravan (2016). https://store.steampowered.com/app/352890
- [R53] Raijin — Battle Brothers. https://raijin.gg/app/365360/Battle_Brothers ; Vaporlens. https://vaporlens.app/app/365360/battle_brothers/stats/details
- [R54] Nintendo — Indie World interview: Rogue Legacy 2 (Teddy Lee). https://nintendo.com/whatsnew/indie-world-interview-rogue-legacy-2-game-designer-teddy-lee-talks-about-the-newly-available-heir ; StrategyWiki — Rogue Legacy. https://strategywiki.org/wiki/Rogue_Legacy
- [R55] IF50 — 2014: 80 Days. https://if50.substack.com/p/2014-80-days
- [R72] PCGamesN — Slay the Spire one million sales. https://www.pcgamesn.com/slay-the-spire/slay-the-spire-one-million-sales
- [R75] Wikipedia — referans oyun. (referans oyun bağlantısı kaldırıldı)
- [R76] Crusader Kings III Wiki — Succession. https://ck3.paradoxwikis.com/Succession
- [R77] RimWorld Wiki — AI Storytellers. https://rimworldwiki.com/wiki/AI_Storytellers

**Pazarlama ve platform**

- [R56] Zukowski, C. (2022; Haziran 2026'da arşive alındı). How many wishlists should I have when I launch my game? https://howtomarketagame.com/2022/09/25/archive-how-many-wishlists-should-i-have-when-i-launch-my-game/ ; https://howtomarketagame.com/2026/06/25/archive-how-many-wishlists-should-i-have-when-i-launch-my-game/
- [R57] Carless, S. (2025, 17 Ekim). The state of Steam wishlist conversions. GameDiscoverCo. https://newsletter.gamediscover.co/p/the-state-of-steam-wishlist-conversions
- [R58] Zukowski, C. (2020). Five trends in Steam capsule art. https://howtomarketagame.com/2020/07/27/five-trends-in-steam-capsule-art/
- [R59] Unity Blog — 5 tips & strategies for marketing indie games (Zukowski röportajı). https://unity.com/blog/tips-strategies-for-marketing-indie-games ; WN Hub — Zukowski Clanfolk kapsül vakası. https://wnhub.io/news/marketing/item-45016
- [R60] GameDiscoverCo — How to get to your game's hook quick. https://newsletter.gamediscover.co/p/how-to-get-to-your-games-hook-quick ; WN Hub — Derek Lieu, trailer mistakes. https://wnhub.io/news/analytics/item-237
- [R61] Valve. Steamworks Documentation — Steam Next Fest Tips. https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/tips ; Next Fest demo kontrol listesi (üçüncü taraf). https://ziva.sh/docs/steam-next-fest-demo-checklist
- [R62] Brown, M. (GMTK). How to make a great Steam Next Fest demo. https://gmtk.substack.com/p/how-to-make-a-great-steam-next-fest
- [R63] GameDiscoverCo (2025). Who 'won' October 2025's Steam Next Fest? https://newsletter.gamediscover.co/p/who-won-october-2025s-steam-next ; Game World Observer (2025). https://gameworldobserver.com/2025/06/19/gamediscoverco-named-the-games-with-the-most-wishlists-following-the-june-2025s-steam-next-fest
- [R64] Alinea Analytics. Wishlist-to-buyer conversions for games with Steam Next Fest demos. https://alineaanalytics.substack.com/p/wishlist-to-buyer-conversions-for
- [R65] Game World Observer (2022). Roguelike deckbuilders beat all indie genres on Steam. https://gameworldobserver.com/2022/04/22/roguelike-deckbuilders-beat-all-indie-genres-on-steam-in-terms-of-sales-but-only-99-such-titles-released-since-2019 ; Game World Observer (2024). Top game genres on Steam H1 2024. https://gameworldobserver.com/2024/07/18/top-game-genres-on-steam-first-half-2024-key-trends
- [R66] Birkett, J. (2016). The No Hit Wonder — 11 Years and Still Going. GDC 2016. https://gdcvault.com/play/1023086/The-No-Hit-Wonder-11 ; Game World Observer (2022). https://gameworldobserver.com/2022/04/12/diablo-creator-david-brevik-asks-whether-devs-can-find-success-making-small-cheap-games
- [R67] PC Games Insider — Valve has updated its Steam AI content policy. https://www.pcgamesinsider.biz/news/74232/valve-has-updated-its-steam-ai-content-policy ; GameFromScratch. https://gamefromscratch.com/steam-makes-massive-update-to-ai-generation-policy/
- [R68] Notebookcheck (2026). Steam updates AI disclosure form. https://www.notebookcheck.net/Steam-updates-AI-disclosure-form-requiring-developers-to-report-visible-and-in-game-AI-but-not-background-tools.1206103.0.html ; Automaton (2026). https://automaton-media.com/articles/newsjp/steam-ai-20260117-407801/
- [R69] Video Games Chronicle (2025). Steam games disclosing generative AI use 'are up 800%' this year. https://www.videogameschronicle.com/news/steam-games-disclosing-generative-ai-use-are-up-800-this-year/
- [R70] Notebookcheck — Study suggests AI is hurting video game sales (Game Oracle). https://www.notebookcheck.net/Study-suggests-AI-is-hurting-video-game-sales.1328725.0.html ; OpenCritic. https://opencritic.com/news/33528/ai-is-ruining-game-sales-numbers-show
- [R71] The A.V. Club (2025). Clair Obscur GenAI IGA awards rescinded. https://www.avclub.com/clair-obscur-genai-iga-awards-rescinded

> **Doğrulama notu:** R14'ün URL'si ve R13'ün tam makale bağlantısı doğrulanmadı; yalnızca yayın künyesi verildi. R5, R15, R18 ve R20 bağlantıları literatürde yaygın kullanılan adreslerdir, ancak bu çalışma sırasında açılarak kontrol edilmedi. "Tahmin" olarak işaretlenen tüm satış rakamları üçüncü taraf modellerine dayanır. Bu rakamlar resmî değildir ve kaynaklar arasında çelişki vardır.
