# SIDERIA — Wayborne'un dünya kitabı

**Bu, evrenin tek belgesidir.** Daha önce `LORE.md` (dünya ne), `TARIHCE.md` (ne zaman ne oldu),
`SORULAR.md` (açık sorular) ve `ONERILER_III.md` (önerilen cevaplar) diye dört parçaydı; 2026-11-07'de hepsi
burada birleştirildi, çelişkileri çözüldü, boşlukları dolduruldu. O dosyalar silindi; git geçmişinde dururlar.
Bundan sonra lore, tarih, coğrafya, inanç ve oyun içi metin bu belgeden üretilir.

**Son güncelleme:** 2026-11-07. Defter IV'ün 24 cevabı, T49'un onayı ve kullanıcının "kalanlar için sen kendi
cevaplarını üret" talimatı işlendi.

## 0. Bu belge nasıl okunur ve nasıl kullanılır

### 0.1 İşaretler

| işaret | anlamı | değiştirme yetkisi |
|---|---|---|
| **[Yazar]** | Kullanıcının kendi sözü. Kanon, tartışılmaz. | yalnızca kullanıcı |
| **[Oyun]** | Bugün oyunda yazılı (metin, kart, kural, veri). | kod ve çeviri işi |
| **[Harita]** | Onaylı harita v3 ve yer atlası (`places_v3.json`, `settlements.json`). | harita işi |
| **[Karar]** | Kullanıcının 2026-11-07'deki yetkisiyle benim verdiğim karar. Kanon gibi kullanılır; kullanıcı aksini söyleyene kadar geçerlidir. | kullanıcı bir satırı kaldırabilir |
| **[Boş]** | Kasıtlı boşluk: kullanıcının kendi cevabını beklediği ya da dünyanın hiç bilmemesi gereken şey. | §16.3'e bak |

Bir çelişki görürsen sıra şudur: **[Yazar] > [Oyun] > [Harita] > [Karar]**. [Karar] satırı bir [Yazar] satırıyla
çakışıyorsa [Karar] yanlıştır ve silinir.

### 0.2 İki değişmez kural

1. **Oyunda anlatıcı yok [Yazar].** Bu belge yazarın hakikatidir. Oyun içindeki hiçbir metin bu belgenin satırını
   olduğu gibi söylemez. Her cümle dünyanın içinden biri tarafından söylenir ya da yazılır: bir NPC, bir kitabın
   yazarı, bir yazıtı kazıyan el, bir lonca kâtibi. Dolayısıyla **oyun içi her kaynak bu belgenin eksik ya da yanlış
   bir yorumudur.**
2. **Hiçbir gerçek ad, figür, imge ya da olay alınmaz [Yazar, Harita].** Özel adlar uydurmadır, ASCII yazılır, her
   dilde aynı kalır, birbirine çok benzemez. Gerçek dinî imge (haç, hilal, kubbe, minare, gerçek kutsal kitap adı)
   kullanılmaz. Mimari ticaret kökenlidir: sur, kapı, ambar; kilise binası bir çan kulesidir.
   Bu kural depodaki her dosya için geçerlidir ve `tests/test_naming_rule.gd` onu bekçiler.

### 0.3 Metin üretirken izlenecek yol

Bir diyalog, kitap parçası, yazıt, haber ya da kart metni yazarken sırayla bak:

1. **Kim konuşuyor?** → §7 (halklar, diller), §13 (gündelik hayat, adlar) ve §10'daki o yerleşimin satırı.
2. **Nerede konuşuyor?** → §10'daki bölge ve yerleşim maddesi: kervan orada ne görür, ne duyar, neyden korkar.
3. **Neye inanıyor?** → §8. Aynı olay Septisist kâtibin, Yumruk Okuyan'ının, şamanın ve dinsiz bir arabacının
   ağzında dört ayrı şeydir.
4. **Ne kadar biliyor?** → §16.3 "asla söylenmeyecekler" ve §0.2/1. Kimse tarihin tamamını bilmez;
   herkes kendi bölgesinin anlatısını bilir.
5. **Hangi omurgaya dokunuyor?** → §1.2. Bir metin beş omurgadan birine değmiyorsa muhtemelen gereksizdir.
6. **Hangi kaynak türü?** → §15. Her türün uzunluğu, sesi ve yasakları orada.

Dil ve zanaat kuralları (yapay zekâ izleri, Türkçe ve İngilizce denetim listesi):
`.claude/skills/wayborne-metin/SKILL.md`. Lore yazım yöntemi: `.claude/skills/wayborne-lore/SKILL.md`.

---

## 1. Dünya bir bakışta

### 1.1 Tek paragraf

**Sideria** tek bir kıtadır. Dört yüz yıl onu bir imparatorluk tuttu; altmış yıl önce göçebe boyları onu dize
getirdi ve imparatorluk parçalandı. Otuz beş yıl, kimsenin sonradan ad koymaya değer bulmadığı bir barış oldu.
Sonra **İllet** çıktı: bir hastalık, kıtayı dolaştı ve çalışacak insanı aldı. Ambarlar bir daha dolmadı; kırkıncı
yılda **kıtlık** başladı ve yirmi yıldır sürüyor. Bugün krallıklar, prenslikler, konseyler ve kabileler birbirinin
toprağını değil **ambarını ve işgücünü** istiyor. Kimse kazanmıyor, kimse de bırakmıyor. Bu dünyada bir kervanın
işi artık ucuz alıp pahalı satmak değil: **yükü ve insanı bir yerden öbürüne sağ ulaştırmak.**

### 1.2 Beş omurga

Dünyanın bütün parçalarını birbirine bağlayan beş motif. Yeni bir yer, kişi, olay ya da metin yazarken en az
birine dokunmalı; hiçbirine dokunmuyorsa gerekçesi sorulur. (Kullanıcının dört sütunu — yol yaşar, insanlar
aşınır, defter unutmaz, ticaret bilgi oyunudur — oyunun sütunlarıdır; bunlar dünyanın.)

1. **Ambar.** [Karar] Sideria'da her savaş ambar savaşıdır. Göçebe birliği imparatorluğun şehirlerine değil
   ambarlarına yürüdü; bugün Vadi'nin paralı bölükleri aynı şeyi birbirine yapıyor. Kimse toprak istemiyor,
   çünkü toprağı ekecek adam yok. Bir yeri anlatacaksan ambarının nerede olduğunu ve kimin saydığını bil.
2. **Yazı ve kayıt.** [Karar] Bu dünyada seni ne öldürür ne yaşatır: adının nereye yazıldığı belirler. El'in
   Kitabı, loncanın defteri, Vastrevar'ın Kayıt Bürosu, baronun boynuz fişi, kervanın kendi defteri — hepsi aynı
   el. Karşısında tek bir şey var: **yol**, hiçbir ad yazmaz (yol kenarı mezarları işaretsizdir) ve Baikhan,
   hiç defter tutmaz. Oyunun defteri (Waybook) bu kavganın oyuncu tarafındaki yüzüdür.
3. **Kendinin olmayan yaşamı almak.** [Karar] Kadimler kendi yaşam enerjilerinden fazlasını kullanmayı denedi ve
   bittiler. Deli kral kendisine ait olmayan bir ömür istedi ve imparatorluk onunla bitti. Fazlasını zorlayan
   büyücü adayı ölür. İllet bir kıtanın işgücünü, yani yaşamını aldı. Bu, dünyanın tekrar eden tek günahıdır ve
   **oyun bunu asla açıkça söylemez**; yalnızca dört ayrı yerde aynı gölge düşer.
4. **Taşınmış taş.** [Yazar, defter IV] Kadim tapınaklar yalnız doğudadır; batıda bulunan her kadim taş oradan
   taşınmıştır. Yani dünyanın en eski şeyleri her yerde yersizdir: bir Vadi kilisesinin temelinde Karaocak'tan
   gelmiş bir blok olabilir ve kimse bilmez. [Karar] Kimin taşıdığı, nasıl taşıdığı hiçbir kaynakta yok.
5. **Aşınma.** [Oyun] Konu kervan değil, kervanı çeken insanlar ve onların aşınması. Dünya da aynı şekilde
   aşınıyor: yıkılmıyor, eskiyor. Kervansaraylar kapanmıyor, bakımsız kalıyor; devletler çökmüyor, idare ediyor;
   kimse kazanmıyor, herkes azalıyor.

### 1.3 Oyunun tezi [Oyun, Yazar]

- Oyuncu bir kervanın **adını** taşır; lider ölünce ad devredilir. Tek gerçek son, adı taşıyacak kimsenin
  kalmamasıdır.
- Kervanın defteri hiçbir satırı silmez; ölenin ya da gidenin adının üstü çizilir. İlk satır kurucudur.
- **"Wayborne" bir yer adı değil [Yazar]:** ana karakter yolda doğmuştur ve kendini ait hissedebildiği tek yer
  yoldur. Kuşak sisteminde o **ilk liderdir**: kervanı babasından devralan kişi.
- **Defter El inancını, yol Baikhan inancını temsil eder [Yazar].** Defter adları silmez, yol adları mühürlemez:
  biri yazarak hatırlar, öbürü bırakarak. **[Yazar, T25]** Bu bir bakış açısıdır, tek doğru okuma değil:
  kervanı iki inancın arasında yaşayan biri olarak gören de olur, yalnızca birinin gözünden bakan da, dini hiç
  işe katmadan yalnızca yolu ve yükü gören de. Oyun hiçbirini doğrulamaz.

---

## 2. Zaman

### 2.1 Ölçek [Yazar]

Dünya, en az on bin yıl görünür (binlerce yıllık ağaçlar, buzda donmuş eşi görülmemiş hayvanlar); hakikatte yüz
binlerce yıl ve sayısız nesil. Eski çağların süreleri kasıtlı olarak belirsizdir. Yakın geçmiş ise yaşayanların
hafızasındadır: **imparatorluğun çöküşünü görenler hâlâ hayatta.**

### 2.2 Dört çağ [Yazar, defter IV]

| çağ | ne | halk arasındaki adları |
|---|---|---|
| **Kadimler** | Derin zaman ve kadim uygarlık (§3.2). | [Karar] Vaelghard kâtibi "ad verilemeyen çağ" der; dağlı "taşın zamanı" der. |
| **Dağınık Beylikler** | Kadimlerin sonundan imparatorluğa kadar: kayıp çağ, eski inançların doğuşu, küçük beylikler (§3.3, §3.4). | [Karar] İlk kısmı **Sessiz Bin Yıl**; sonrası "beyliklerin zamanı". |
| **İmparatorluk** | Vael İmparatorluğu'nun dört yüz yılı (§4). | [Karar] Vaelghard ve Septisistler **Ferman Çağı** der (Septimar'ın fermanından). |
| **Kıtlık** | Bugün. Kırkıncı yılda başladı, yirmi yaşında. | [Yazar] "Kıtlık"; kimse ona daha iyi bir ad vermedi. [Karar] Halk ağzında **Açlık Çağı**, resmî yazışmada "kıt yıllar", Vadi'de yalnızca "bu yıllar". |

[Karar] **Çöküşten İllet'e kadarki otuz beş yılın adı yoktur** ve bu kendi başına bir bilgidir: kimse ad koymaya
değer bulmadı. Onu görenler "barış yılları" der, görmeyenler "eskiden" der. Vaelghard'ın kâtibi o yılları
belgelerinde yalnızca sayıyla anar.

[Karar] **Yangın Yılı** bir çağ değil bir yıldır: başkentin yandığı yıl, yani çöküş yılı. Vadi'de ve Avuçiçi'nde
takvim konuşmasında "Yangın'dan beri" denir.

### 2.3 Takvim: bir gün, üç ad

**[Yazar, defter IV]** Takvim **Sürü Yılı**'dır: yıl **ilk otun çıktığı gün** başlar. Göçebe takvimidir;
imparatorluğa da geçmiştir, çünkü ordu da otla yürür. Dört mevsim, oyunun kullandığı 360 gün.
İmparatorluk bu takvimi **orijinaliyle almadı**: adını ve hikâyesini kendine göre değiştirdi. Bugün kuzeyde ve
şehirlerde yılın başı aynı gündür ama ona başka bir ad verilir ve başka bir başlangıç anlatılır.

[Karar] Aynı günün üç adı, üç hikâyesi:

| kim | günün adı | anlattığı hikâye | günü nasıl belirler |
|---|---|---|---|
| Göçebe | **İlk Ot** | Yıl, sürünün yemeye başladığı gün başlar. Hikâye yok, bakılan şey var. | Obanın yaşlıları yere bakar. Boylar arasında bir iki gün oynar ve kimse buna aldırmaz. |
| İmparatorluk, bugün Vaelghard ve şehirler | **Yol Günü** | "Ot, yol açıldığı için biter kışı." Septimar'ın fermanı anlatıyı tersine çevirdi: ot yolu değil, yol otu getirir. | Vastrevar'da Kayıt Bürosu fermanı okuyarak ilan eder. [Karar] Ama büro her yıl otlağa atlı yollar ve bunu herkes bilir: kâtibin fermanı, çobanların haberinden bir gün sonra gelir. Bu, kuzeyde en sevilen şakadır ve yüksek sesle yapılmaz. |
| El kilisesi | **Sayfa Günü** | Yılın ilk satırı Kitap'a o gün yazılır. | Orvahel mühürler; şehir kiliseleri Orvahel'in gününü bekler. |

[Karar] **Yıl sayma biçimleri de ayrıdır** ve bu, bir belgenin nereden geldiğini söyler:
- **Vaelghard ve Septisist şehirler:** Septimar'ın fermanından sayar (*Ferman yılı*). Sayı büyüktür, dört
  haneli yazılır, bir kâtibin elinden çıkar.
- **Ors, seküler Vadi şehirleri, lonca defterleri:** çöküşten sayar ("çöküşten beri altmış yıl"). Ticaretin
  dili budur; oyunun bütün yakın tarihi bu sayıyla anlatılır.
- **Gokyurt:** yıl saymaz. Sogurtay suyunun tadını sayar: "üç acı sudan beri" (§8.3).
- **Ayazkaya:** hükümle sayar: "Demirbalta'nın üçüncü kışı".

### 2.4 Altmış yılın çizgisi [Yazar, defter IV]

Yıllar çöküşten sayılır; bugün 60. yıldır.

| yıl | olan |
|---|---|
| 0 | **İmparatorluk çöker.** Başkent Merigard yakılır, halkı sürülür. |
| 0–35 | **Otuz beş yıl barış.** Beylikler ve krallıklar kendi düzenlerini kurar; yollar işler, ticaret sürer. Vaelghard toplanır, Vadi'nin şehirleri bağımsızlığını ilan eder, Kanlı Baron hükmünü alır, lonca güneye taşınır, Orvahel kurulur, Yumruk doğar, Tolvarin ile Kirsavel ayrışır, Ayazkaya yol kavgasına girer. |
| 35 | **İllet çıkar.** Hiç kimse birlik hâlinde onunla mücadele etmeye çalışmaz. |
| 35 | **Gokyurt sınırını kapatır:** göçebe halkı sınırlarını daha iyi kontrol eder, kimseyi yanaştırmaz, izolasyonunu korur. Bugün kıtanın en sağlıklı yeri olmasının sebebi budur. |
| 35–40 | Öbür krallıklar **teker teker hastalığa yenilir.** İşgücü azalır; ticaret ve üretim çok düşer. |
| 40 | **Kıtlık başlar.** Sebebi büyü ya da mevsim değil, çalışacak insanın kalmamasıdır. |
| 40–60 | Krallıklar birbirinin **malına ve toprağına göz diker**; teker teker savaşlar başlar. Son yirmi yıl hastalık ve savaşla geçer. |
| 60 (bugün) | Halklar ve ordular perişan. **Bazı devletler gözlerini göçebe topraklarına çevirmeye cüret eder oldu, ama henüz harekete geçmediler.** Oyunun bugünü bu eşiğin üstünde durur. |

### 2.5 Üç kuşak, üç dünya [Karar, T51]

Çizgi oyunun soy sistemini de ölçeklendirir. Çöküşü çocukken gören bir adam bugün yetmişindedir: hatırlayan sağ.

- **Dede** barış yıllarında yürüdü. Yol açıktı, kervansaray bir gün bedava yatırırdı, bir yükü satmak bir seferi
  kurtarırdı. Onun hikâyeleri bugün yalan gibi gelir ve o yalan söylemiyor.
- **Baba** İlleti gördü. Kardeşini, çırağını, ortağını gömdü. Kıtlığın başlangıcını bilen son kuşak; "eskiden
  böyle değildi" diyen o.
- **Oğul** (oyuncunun kervanbaşısı) **kıtlıktan başkasını bilmiyor.** Ona göre dünya böyledir. Bir NPC ona barış
  yıllarını anlatırsa iki şeyden biri olur: ya inanmaz, ya da inanır ve bir daha eskisi gibi olmaz.

Bir NPC yazarken hangi kuşaktan olduğunu seç. Yetmişindeki bir arabacıyla otuzundaki bir arabacı aynı yolu aynı
sözcüklerle anlatamaz.

---

## 3. Görünmeyen dünya ve derin geçmiş

Bu bölüm yazarın hakikatidir; oyunda hiç kimse bunu bu açıklıkla bilmez.

### 3.1 Öbürküler [Yazar]

İnsanlarla aynı dünyada, başka bir "boyutta" yaşayan görünmeyen varlıklar; halk onlara peri, hayalet, ruh der.
Yaşamdan beslenir ama onu tüketmez, **dönüştürür**: kimi kötüye, kimi iyiye. Etkileri çok küçüktür ve birikerek
büyür (moral düşüşü, vesvese, sağduyu); kimi bir yere yerleşip nesneleri oynatır. Güçleri yaşla değişir, ömürleri
genelde kısadır. Kültürleri, anlayışları ve haklarında hiçbir kaynak yoktur. Çok dolaylı yoldan savaşa bile sebep
olabilirler; bu radikal bir istisnadır.

- [Karar] Oyunda bir "öbürkü" birimi yok ve olmayacak; **stres ve moral sistemi onların sahnesidir.** Kartlarda
  yalnızca insanların onlara verdiği adlar ve kişisel tanıklıklar olur.
- [Karar] **Yerel adları** bir metnin nereli olduğunu hemen söyler: Vaelghard'da **kayıtsızlar** (deftere
  yazılmayanlar), Vadi'de **komşu**, Gokyurt'ta **rüzgâr çocukları**, dağda **soğuk soluk**, güneyde
  **karşı taraf**. Hiçbiri "öbürkü" demez; "öbürküler" yazarın sözcüğüdür.
- [Karar] **Issız tepeler** (Gokyurt ile Vaelghard arasında, Kovrast ve Kemersal'in ötesi) "onların yeri" diye
  bilinir; obalar oradan geçmez.

### 3.2 Kadim uygarlık [Yazar]

Bugünkü insanlıktan önce bir uygarlık yaşadı. Gündelik hayatı basitti, teknolojisi yoktu; ama **yaşam enerjisini
bugünkü büyücülerden çok daha güçlü, serbest ve radikal kullanmayı** buldu. Bu güçle nesneleri tılsımladılar ve
hayvanları mutasyona uğrattılar (eski yaratıklar). Tapınaklarının duvarlarına gündelik hayatlarını resmettiler;
kalan bilginin neredeyse tamamı bu tasvirlerdir. Kontrol edemedikleri güç sonlarını getirdi; nasıl olduğu
bilinmiyor.

- **[Yazar, defter IV] Yurdu Karaocak Sırtı'nın doğu etekleri.** Madenciler bugün onların açtığı galerilerin
  içinde çalışıyor; **Vorgat ve Zurek'in zenginliği aslında kadim bir şehrin üstüne kurulmuş olmasından.**
- **[Yazar, defter IV] Tapınak yalnız doğuda.** Sunaklar yol boyunca her yerde, ama batıda bulunan her kadim taş
  doğudan taşınmıştır (§1.2/4).
- **[Yazar]** Kuzeybatı ve kuzeydoğu dağlarının buzullarında, maden derinliklerindeki "farklı dünyalarda" ve
  ışık görmeyen dağ arası vadilerde eski ve çok tehlikeli yaratıklar kalır.
- **Sonları:** §16.3. Oyunda hiç söylenmeyecek; cevabı kullanıcının.

### 3.3 Kayıp çağ [Yazar]

Hayatta kalanlar yaşam mücadelesini sürdürdü ama kültürlerini yitirdi. Zamanla yeni bir medeniyet kurdular:
bugünkü insanlık. [Karar] Uzunluğu bin yıl kadardır ve ondan yazılı tek satır kalmadı; halk ona **Sessiz Bin
Yıl** der. Bu çağdan kalan tek şey alışkanlıklardır: yol kenarına taş yığmak, ölüyü suya bırakmak, ilk ota
bakmak. Kimse bunları nereden öğrendiğini bilmez.

### 3.4 Eski inançlar çağı [Yazar]

İnsanlar anlamlandıramadıklarını tanrılara bağladı; pek çok pagan inanç doğdu (§8.4). Yol kenarı sunakları,
tapınaklar ve katakomblar bu inançlar için yapıldı. **Yol kutsallaştı:** yolda ölen yola ait sayıldı, mezarına ad
konmadı; Bekçi Kadın inancı doğdu (§8.5). [Karar] Bu çağ aynı zamanda **Dağınık Beylikler**in ikinci yarısıdır:
her vadi kendi beyini, her inanç kendi taşını kurdu, ve hiçbiri bir hafta ötesini yönetmedi.

### 3.5 Nadir yaratıklar [Yazar]

Kurtadamlar, vampirler, olağanüstü iri ve güçlü hayvanlar: çok nadir, genelde çok nadir hastalıkların sonucu.
Halkın bilgisi çocuk masallarıyla sınırlı. Görenler genelde zekâlarına yenilir. Kötü niyetli olmak zorunda
değiller; kimi çektiği acı yüzünden kötülüğe meyleder.

- **[Yazar, onaylandı]** Kurt sürüsü reisleri (Kırağı Kurdu, Zifir Kurdu [Oyun]) bu ailenin en hafif ucudur:
  halk masal yakıştırır, aslında iri ve yaşlı hayvanlardır.
- [Karar] **Masal hep komşu bölgenin yaratığını anlatır.** Kurtadam Gokyurt sınırında anlatılır (Selvicar),
  vampir Vadi'nin bataklıklarında, dev hayvanlar Ayazkaya'da ve buzulda. Kimse kendi kasabasının yaratığını
  anlatmaz; o yalnızca "geçen kış bir şey oldu" diye anılır.

### 3.6 Büyü ve büyücüler [Yazar]

- Büyü, **yaşam enerjisini** öbürkülerin ötesinde kullanmayı öğrenmektir: efsun, koruma, saldırı; sözlü ya da
  hareketli, malzemeleriyle yapılır.
- Büyücüler **Raviellon**'daki okulda yıllarca eğitim alıp döner. Eğitim o kadar ağırdır ki çoğu aday kendi yaşam
  enerjisini tüketerek ölür ya da öldürülür; bu yüzden çok nadirdirler.
- Kilise ve göçebe boyları onları hoş karşılamaz. Yalnızca güney kentlerinde ve sayılı krallıkların
  konseylerinde yer alırlar: büyülü eşya ve özel ihtiyaç karşılar, ya da kendi araştırmasını barış içinde
  sürdürmek için şehir konseyine sağladığı avantajlar karşılığında anlaşır.
- **[Yazar, onaylandı]** Büyücüler deli kralın katliamından önce de Sideria'daydı; Raviellon'la temas
  imparatorluktan eskidir. [Karar] Yazılı **ilk** temas çok daha yenidir: imparatorluğun ikinci yüzyılında
  Zelmarin'den bir kaptanın defteri. Kaydın eskiliği gerçeğin eskiliği değildir — bu dünyada sık rastlanan bir
  yanılgı.
- **[Yazar] Büyücü avcıları:** eski büyücülerin öğrettiği tılsımlı giysiler giyen özel savaşçılar.
  [Karar] Bugünkü hâlleri deli kralın katliamından kalan bir tarikattir: yakma işini yapan adamların torunları.
  İmparatorluk düşünce işsiz kaldılar; Vaelghard onları sessizce tuttu ve bunu hiçbir yerde yazmaz.
  Oyunda yalnızca olay kartı olarak görünürler.
- **[Oyun]** Yolda nadir ve bir kez görülen bir kaçak büyücü kervanı kesebilir. [Karar] Bir büyücü kervanın
  kadrosuna **katılamaz**: taşımak her şehrin kapısında sorun olur. İleride çok nadir bir olay kartıyla açılabilir.

### 3.7 Tılsımlı nesneler [Yazar, onaylandı]

Oyundaki yüzük ve kolyeler (satılmaz, bulunur) kadim tılsımlı nesnelerin ilk izidir. Bu nesneleri **bugünün
büyücüleri de yapabilir.** Her biri bir statı düşürmek zorunda değildir:

- çoğu bir statı artırıp birini düşürür (bugünkü kural),
- **nadir olanlar hiç düşürmeden birden çok statı artırır** ("kusursuz"),
- bazıları bir statı çok yükseltip birini çok düşürür ("aşırı").

Kadim olanların işlevleri: öldüren, geleceği gösteren, güç ya da zaaf veren, bela getiren, eski yaratıkları
uyandıran.

---

## 4. İmparatorluk

### 4.1 Vael İmparatorluğu [Karar, çerçeve [Yazar]]

- **Adı Vael İmparatorluğu**, hükümdarın unvanı İmparator. **Vaelghard** "Vael'in bekçisi" demek: krallık
  imparatorluğun mirasçısı olduğunu adıyla söyler ve bunu her fırsatta hatırlatır.
- **Süresi** dört yüz yıl kadar. En geniş hâliyle bugünkü Vaelghard, Büyük Vadi, Ezmerak, Avuçiçi ve batı
  sınırı. **Ors** bağlı bir ticaret ortağıydı: vergiyle ve askerle değil, sözleşmeyle bağlı. **Gokyurt,
  Ayazkaya ve Taşkök hiç tam bağlanmadı.**
- **Başkenti Merigard** [Yazar], bugünkü Orvahel'in yerinde. Vadi'deki **Merigaud** adını ondan alır
  ("Merigard"ın Vadi ağzıyla söylenişi); para birimi **GG (Gümüş Gard)** da başkentin adını taşır
  [Yazar, Ç3 çözüldü].
- **Ana yollar imparatorluk yollarıdır** [Yazar]. Üstlerindeki pagan sunakları onlardan eskidir (§8.6).
- **Vastrevar** imparatorluğun en büyük kentlerinden biriydi [Yazar].
- **[Yazar]** **İmparator Septimar** kural koyucudur: imparatorluk altındaki farklı dinî görüşleri ezer ve El
  inancına katar. Kilisenin bugünkü kurulu mezhebi **Septisizm** adını ondan alır (§8.1). Takvimin imparatorluk
  hikâyesi de onun fermanıdır (§2.3).
- **[Yazar]** İmparatorluğun baron ve düklerinden **Dük Valdric** bugünkü Ezmerak ve Golcavar topraklarını
  yönetir; piç oğlu **Aldemar** hanedanda yetişmeye uygun görülmez, orduya verilir (§10.3).

[Karar] **Asimilasyonun sırası:** önce Vadi'nin köy inançları, sonra kıyıların deniz inanışı, en son dağın
nefesi. Direnenler: Tolvarin, Kirsavel, Taşkök ve Gokyurt. Ayazkaya'nın inanışını kilise yuttu ama dağlı
bırakmadı — bugün Dağın Nefesi'nin en yüksek sesle yaşadığı yer orası (§8.4).

### 4.2 Deli kral [Yazar, defter IV + Karar]

**[Yazar, defter IV]** Deli kral **imparatorluğun son yöneticisiydi**. "Kral" denmesi bir hakarettir: halk ona
imparator demeyi bıraktı. **Katliam kıtlıktan öncedir** — kıtlık çöküşten kırk yıl sonra başlar, yani katliamın
sebebi açlık değildir.

**[Karar] Neden katletti.** Son imparator hastalandı. İllet değil (ondan yirmi beş yıl önce), adı konmamış bir
hastalık: eli tutmaz oldu, sonra ayağı. Raviellon'da eğitilmiş büyücüleri saraya çağırdı ve onlardan tek bir şey
istedi: **ömür.** Büyü yaşam enerjisidir; bir büyücü kendi enerjisini harcar, başkasının ömrünü uzatmaz —
kadimlerin bile yapamadığı şey budur. Büyücüler bunu söylediler. İmparator sözlerini ihanet, denemelerini ise
"yapabiliyorlar ama yapmıyorlar"ın kanıtı saydı. Hepsini yazlık sarayının avlusunda yaktırdı.

[Karar] Bir yıl kadar sonra yine öldü ve arkasında emir verecek kimse kalmadı; göçebe birliği tam o boşluğa
yürüdü. Dolayısıyla **imparatorluk onunla bitti** ve tarihe "deli" diye geçen adam dünyanın tek doğru sözünü
duyan adamdır. Hiçbir kaynak bunu böyle anlatmaz:

| kim | nasıl anlatır |
|---|---|
| Vaelghard kanun kitabı | Hastalık aklını aldı, taht sahipsiz kaldı, düzeni kuzey devraldı. (Krallığın mirasçılık iddiasının temeli bu paragraftır.) |
| Göçebe destanı | Kendisine ait olmayan bir ömür istedi; gök aklını aldı. Destan büyücüleri hiç anmaz. |
| Orsian muhasebe defteri | Büyücülerin malları saraya geçti ve hiçbir borç kapanmadı. Orsian'a sorarsan deliliğin bir satırı vardır ve o satır ödenmemiştir. |
| Avuçiçi | Söz konusu bile edilmez. Kâtip "o yıllar Kitap'a yazılmadı" der. |
| Raviellon | Hiçbir şey. Kimse cevap vermiyor; büyücülerin bugün bile Sideria'dan uzak durmasının sebebi budur. |
| Büyücü avcıları | Kendi aralarında: "görev tamamlandı" der, kimden emir aldıklarını söylemezler (§3.6). |

- **[Harita]** Sarayının yıkıntısı Vastrevar'ın doğusunda: **Deli Kral Sarayı Yıkıntısı** (§11).

### 4.3 Çöküş ve büyük savaş [Yazar]

- **Göçebe boyları tarihte bir kez birlikte davranır:** Han birliği toplar, ordular birleşir ve imparatorluğa
  karşı savaşır. İmparatorluk dize gelir ve parçalanır. Savaş bitince her boy obasına döner.
  [Karar] Sebebi: imparatorluğun bozkır karakolları (Sargalak) otlak geçişlerine bedel koymaya başladı ve kurak
  bir yıl bunu taşınmaz hâle getirdi. Birliği Sogurtay konseyinde bir han kurdu.
  [Karar] **Ordular şehirlere değil ambarlara saldırdı.** İmparatorluk ordusu yerinden kalkamadı, çünkü kendini
  besleyemiyordu. Bugünün Vadi savaşları aynı şeyi tekrar ediyor (§1.2/1).
- **Büyük savaşın sonunda** Merigard'ın halkı sürülür, şehir yakılır.
  [Karar] **Kim yaktı:** herkes başkasını suçlar ve oyun hiçbirini doğrulamaz. Vaelghard göçebeleri suçlar;
  göçebeler açlıktan ayaklanan kendi halkını; Vadi, Vaelghard'ın ordusunu (başkenti yakıp Orvahel'i kurmak
  için). Hakikat: göçebe birliği şehri kuşattı, açlık kapıyı içeriden açtı, yangını kimin başlattığı bilinmiyor.
- **[Yazar, T7]** Dört kuleli tapınak yangından kalan tek yapıdır: **şehir genç, tapınak eski.**
- **[Yazar, onaylandı T8]** Son meydan muharebesi **Mühür Savaşı Ovası**'nda olur; düşen imparatorluk mühürleri
  bugün nadir "eski mühür" olarak elden ele geçer.
- **[Yazar]** Baikhan yolu bu güç sayesinde hiçbir zaman asimile edilemedi.
- **[Yazar, defter IV]** Çöküş bugünden **altmış yıl** öncedir; bütün yakın tarih bu güne göre sayılır.

### 4.4 Parçalanmanın ilk yılları [Yazar]

Hepsi §2.4'ün "otuz beş yıl barış" aralığına düşer.

1. İmparatorluğun en güçlü kalıntısı kuzeyde **Vaelghard Krallığı** olarak toplanır: resmî devamı değil, aynı
   kültür. Başkenti Vastrevar.
2. **Büyük Vadi**'nin şehirleri bağımsızlık ilan eder; prensleri ve hanedanları yerlerini korur. Her şehir bir
   prenslik olur.
3. **Kanlı Baron.** Aldemar, Dük Valdric'in öldüğünü öğrenince döner, hanedanın geri kalanını bir yemekte basıp
   öldürür, toprakları alır. Bölgeyi hiç olmadığı kadar iyi yönetir, refah artar; ordu yıllarının
   hastalıklarından genç ölür. Oğlu **Daveric** bugün hüküm sürüyor **[Yazar, onaylandı T26]**.
4. **Tüccar Loncası**'nın merkezi Merigaud'dan **Orsolune**'ye taşınır; **[Yazar, onaylandı T24]** Orsian
   sözleşme ahlakı kıtanın ticaret kuralı olur.
5. **Orvahel kurulur.** Vaelghard, eski başkentin yanmış yerine kutsal kenti kurar, dinî geçmişi yüzünden
   fonlar ve garantörü olur. Birinci Okuyucu orada oturur.
6. **El inancı ikiye bölünür:** Septisizm ve Yumruk (§8.1). [Karar] Yumruk **Belvanor**'da doğar.
7. Batı sınırında **Tolvarin** ve **Kirsavel** iki ayrı şehir olur; sınır kavgaları başlar.
   **[Yazar, onaylandı T15]** Bölünmüş Sancak Ovası ayrılığın yeri.
8. Savaş mültecileri sınır topraklarına yığılır, ucuz işçi olur.
9. **Ayazkaya**'nın kabileleri imparatorluk düzeninden kurtulur ve Vaelghard'a karşı savaşa girer.
   [Karar] Savaş çöküşten hemen sonra başladı ve hiç bitmedi: Vaelghard imparatorluğun dağ yollarını kendi yolu
   saydı, dağlılar bedel istedi, kral bedeli ödemeyi kibrine yediremedi, dağlılar yolu kapattı.
   **Bu savaş bir yol kavgasıdır** ve iki taraf da bunu unutmuş gibi davranır.

---

## 5. İllet ve kıtlık

### 5.1 İllet (veba)

- **[Yazar, defter IV]** Hastalığın **genel adı İllet**; kıtada herkes bu adla anlar. Yerel adları da var; en
  yaygını **Kara Nefes** (dağlıların "Orman'ın Nefesi"yle kasıtlı olarak çakışır — dağlı onu ormanın öcü sayar,
  şehirli hastalık).
- **[Yazar, defter IV]** Halkın açıklaması bölgeye göre değişir: Avuçiçi **inançsızların cezası** der, Vadi
  **kirli su** der (ve haklıdır), göçebe **şehirlerin hastalığı** der ve şehre girmez. Kervan üçünü de duyar,
  hiçbirini doğrulayamaz — bilgi oyununun parçası.
- **[Yazar, 2026-10-31]** Veba genel bir durum; etkisi her yerde görülür, bölgeden bölgeye farklıdır. **Vebanın
  hiç bulaşmadığı köyler var; nedeni bilinmez.** [Karar] Bu köyler bunu bir erdem sanır ve komşuları onlara
  inanmaz: "Niye siz değil de biz?" kıtlığın en sık sorulan sorusudur ve cevabı yoktur.
- **[Oyun]** İllet bir **dünya hâli**dir: kart açılmadan önce görünür (görev Y-C25).

### 5.2 Kıtlığın sebebi [Yazar, defter IV]

**Kıtlığı başlatan şey büyülü bir olay ya da değişen mevsimler değil, işgücünün çökmesidir.** İllet kıtaya
yayıldı, çalışacak insan azaldı, üretim ve ticaret düştü; ambarlar bir daha dolmadı. *"En büyük kaynak
işgücüdür."* Kıtlık bu kaynağın kaybından doğdu.

Bu karar daha önce yazılmış "uzayan kış" ve "solgunluk" önerilerini ve "kıtlık imparatorluğun son yıllarında
başladı" türetmesini **geçersiz kılar**; o satırlar silindi ve bu belgede yoklar.

**Zaman:** kıtlık kırkıncı yılın sonunda başladı, bugün **yirmi yaşında** — bir kuşak, iki değil (§2.4).

### 5.3 Bugünün hâli

- **[Yazar, defter IV] Bugün kıtlık olabileceği en kötü hâlinde**, ama devletler ve şehirler bir şekilde ayakta
  kalıyor, idare ediyorlar. Kimse daha fazlasını yapamıyor. Durum haylice kötü: çocuklar açlıktan ölüyor, bazı
  yerlerde İlletli hastalar bile zorla çalıştırılıyor.
- **[Karar, T50]** "En kötü hâlinde" olan **acı**; kırılmamış olan **düzen**. Oyunun kıtlık eğrisinin yıllar
  içinde derinleşmesi (`Scarcity.DRIFT_PER_DAY` 0,00055, tavan 0,45) açlığın artmasını değil, **idare
  edebilmenin tükenmesini** anlatır. Metin yazarken fark budur: kimse "artık daha açız" demez; "artık eskisi
  gibi idare edemiyoruz" der.
- **[Yazar]** **Bütün savaşlar temelde bu kıtlıktan doğar.** Oyunda kıtlık ve yokluk her mekanikte ve ortamda
  hissedilir; ticaret kıttır, asıl iş kervanı bir yerden öbürüne ulaştırmaktır.
- **[Yazar]** **Vadi** kıtada en çok kıtlık ve mali zarar yaşayan bölge.
- **[Yazar]** **Gokyurt** kıtlıktan öbür yerlere göre daha az etkilendi; kıtanın hâlâ en sağlıklı yeri
  (sınırını kapattığı için).
- **[Yazar]** **Kervansaraylar:** çoğu eskimiş, ücra ama açık; çok azı kapanmış harabe; bazıları haydutların
  elinde. **Oyun metninde "han" denmez, kervansaray denir.**
- **[Yazar, 2026-10-31]** Gokyurt'un kervansaray ve konaklama yerlerinde **bir gün konaklama ve yeme içme
  ücretsizdir**; bedelini konsey öder. Öbür bölgelerde de eskiden böyleydi; kıtlıkta kaldırıldı.

### 5.4 Kıtlıkta kim ne ister [Karar, T34]

| kim | ister | verir | kıtlıktaki yüzü |
|---|---|---|---|
| Orvahel | gıda, kâğıt, tekstil, bal [Yazar] | iksir (manastır şifahaneleri) | Kıtlığı en az hisseden şehir; Vaelghard fonluyor. Komşuların öfkesi bu yüzden ona da yöneliyor. |
| Büyük Vadi | her şey | buğday, ipek, şarap | Buğday üretir ve aç kalır: savaş hasadı yakıyor (T23). |
| Vaelghard | buğday | demir, kumaş, kürk | Güneye borçlanarak besleniyor ve bundan hoşnut değil. |
| Ezmerak | lüks, ticaret hacmi | buğday (sulak tarım) | Kıtlık baronun kesesini büyütüyor; halk bunu biliyor. |
| Orsolune | borç senedi | altın, buğday (borçla) | Kıtlıkta büyüyor. Orsian ahlakı — "dolandırma, ama kitaptaki açığı kullan" — en çok burada sınanır. |
| Ayazkaya | tahıl, tuz karşılığı çelik | çelik, tuz | Bedel artık para değil un olarak isteniyor. |
| Gokyurt | un, kumaş | kürk, et, at | Demir değil **un** istiyor; un getiren kervanın tamgası bir yıl geçer. |
| Taşkök | tahıl | odun, kuyum, cevher | Mütevazı ve hoşgörülü; en az konuşan bölge. |

### 5.5 Kıtlığın üç tasarım dersi [Yazar, 2026-10-30]

Tasarım notu `docs/design_notes/kitlik_tasarim_dersleri.md`; metin yazarken üçü de geçerli.

1. **Ahlaki zorunluluk.** Kıtlık kartlarında doğru seçenek yoktur: her seçenek bir şeyi feda eder ve bedel adı
   olan birine düşer. Palet kıtlık derecesiyle solar ve kirlenir (dünyada; arayüz okunaklı kalır).
2. **Yenilmez çevre ve domino.** Soğuk ve kıtlık yenilmez, dayanılır. Var olan sistemlerin bedelleri birbirini
   tetikler; kervan son eşyalarını yakmaya, yemeye itilir.
3. **Çözülemeyen problem.** Büyüme ve servet kendiliğinden yeni kriz doğurur; bir krizi çözen hamle öbürünü
   besler.

**Sınır [Yazar]:** güç ve ödül sistemleri kesilmez, bedelli olur (derinleşme, asla sadeleştirme). *"Doğru
stoklayan aç kalmaz"* sözü korunur.

### 5.6 Kıtlığın adları [Karar]

Aynı şeyin adı her yerde ayrıdır; bir NPC'nin hangi sözcüğü kullandığı nereli olduğunu söyler.

| kim | der |
|---|---|
| Vaelghard (resmî) | **Kıt Yıllar** |
| El kilisesi | **Kapanan Sayfa** |
| Gokyurt | **Acı Su** (Sogurtay suyunun tadı, §8.3) |
| Ors | **Uzun Fiyat** |
| Ayazkaya | **Tutulan Nefes** |
| Büyük Vadi | yalnızca **"bu yıl"** |

---

## 6. Coğrafya

### 6.1 Çerçeve

- **[Harita]** Harita v3: mürekkep ve parşömen tonu. **27 oynanabilir yerleşim** (12 şehir, 12 kasaba,
  3 kervansaray), 41 yol; kuzey ucu Auderin'den güney ucu Orsolune'ye kervanla **61 gün**.
- **[Yazar]** Harita kıtayla biter. Kıta dışında: büyücülüğüyle ünlü küçük kıta **Raviellon**; güney
  tüccarlarının bildiği adalar; iki büyük kıta. Hepsi çok uzak, deniz koşulları yüzünden yolculuk çok zor.
- **[Yazar]** Raviellon'a ve uzak kıtalara gemiler **Orsolune** ve **Zelmarin**'den kalkar.
- **[Yazar]** Kıtanın en kuzeyinde **daima kar** vardır. **Kış, Sideria'ya kuzeydoğudan gelir.**

### 6.2 Sular

| su | nerede | işaret |
|---|---|---|
| **Ağıt Denizi** | Batı denizi; Ors ve Mirsana ona bakar. | [Yazar, defter IV] |
| **Gelgit Denizi** | Güneydoğu suyu; Zelmarin adını oradan alır. | [Yazar, defter IV] |
| **Ayaz Denizi** | Kuzey suyu. Kimse açılmaz; Grauth Feneri ona bakar. | [Karar] |
| **Donmuş Boğaz** | Ayaz Denizi'nin kuzeydoğu ağzı, Grauth'un kuzeyi. **Kış oradan gelir.** | [Karar] |
| **Kemersu** | Ana nehir: Taşkök dağlarından doğar, Vadi'yi besler, Ors kıyısında Ağıt Denizi'ne dökülür. **Vadi'nin bütün değirmenleri onun üstünde.** | [Yazar, defter IV] |
| **Ocak Suyu** | Vorgat'ın nehri: Karaocak'tan Gelgit Kıyısı'na iner, cevheri ve balığı taşır. | [Karar] |
| **Vael Gölleri** | Ortadaki büyük tatlı sular. En büyüğü Rivecande'nin önündeki **Ayna Göl**; kuzeyde dar bir boğazla Ayaz Denizi'ne bağlı, bu yüzden Rivecande liman sayılır. | [Karar] |
| **Sisli Saz** | Batı bataklığı (Samuran, Liraven). Masalı: suyun altında imparatorluk yolu devam eder; durgun gecelerde eski fenerleri yanar. | [Karar] |
| **Su Tarlaları** | Golcavar'ın kurutulup kanala çevrilmiş bataklığı. | [Karar] |

[Karar] **Ağıt Denizi'nin adı** sesindendir: Ors sıradağlarının kayalıkları arasından geçen rüzgâr ağıt gibi ses
çıkarır ve balıkçı bunu "deniz hâlâ ağlıyor" diye okur (§8.4, Denizin İlk Gözyaşı). Güneydoğuda ise inanışın
**yeri** var, sesi değil: Gelgit Taşları.

### 6.3 Yükseltiler ve ormanlar

| yer | ne | işaret |
|---|---|---|
| **Karaocak Sırtı** | Doğu sıradağı; bölgeyle aynı kök. Güney ucu Gelgit Kıyısı'na iner. Kadim uygarlığın yurdu doğu etekleridir. | [Yazar, defter IV] |
| **Taşkök Dağları** | Kuzeybatı dağları; ormanlı etekleri Taşkök'ün, karlı doruğu kimsenin. | [Yazar, defter IV] / [Karar] |
| **Ors sıradağları** | Güney kıyısında; Orsolune şehri de bölge de adını onlardan alır. | [Yazar] |
| **Kartalın Nefesi Zirvesi** | Ulmarec ile Droskal arasındaki en yüksek zirve (kuzeydoğu dağları); iki kabilenin yolunun kesiştiği doruk. Kutsal (§8.4). | [Yazar] / [Karar: tam yer] |
| **Kemersal Ormanı** | Büyük orman. Kemersu'yla aynı kökü taşır; Gokyurt ile Vaelghard arasındaki tepe halkı adını ormandan almıştır. Taşkök'ün ünlü odunu onun kuzey yakasından iner. | [Yazar, defter IV] / [Karar] |
| **Ayazkaya Çamlığı** | Kuzeydeki iğne ormanı. | [Yazar, defter IV] |
| **Pus Ormanı** | Avuçiçi'nin çam ormanı; binlerce yıllık ağaçlar orada. Havası basık ve puslu. | [Karar] |
| **Buzullar** | Kuzeybatı ve kuzeydoğu dağlarında: maden derinliklerinde, ışık görmeyen vadilerde, zirvelerde. Eski ve çok tehlikeli yaratıklar barındırır. | [Yazar] |
| **Issız tepeler** | Gokyurt ile Vaelghard arasında, Kovrast ve Kemersal'in ötesi: "onların yeri" (§3.1). | [Karar] |

**[Yazar]** Vaelghard çok dağlı ve göllüdür, manzarası güzeldir; güvenli zamanlarda başka krallıklardan gezginler
gelirdi. **Avuçiçi** dağlık ve çam ormanlıdır, havası basık. **Gokyurt'un güneybatısı** obaların kışlağıdır:
hava soğuyunca oraya göçülür, hayvancılık ve balıkçılık yapılır.

### 6.4 İklim ve yol mevsimi

- **[Yazar]** Kış kuzeydoğudan gelir; kuzey ucunda daima kar var.
- **[Yazar]** Vaelghard'da **şehirler arası yollar kışın da açık kalır** (trafik yoğun), ama **daha kuzeye çıkan
  kasaba yolları kardan kapanır**: yalnızca atla gidilir, ağır yük taşınmaz.
- **[Oyun]** Brazdun–Kesgrav kıtanın en tehlikeli yolu (iki gün ama dağ); Kesgrav–Rivecande de tehlikeli.
- **[Yazar, Ç10]** Ezmerak'tan geçmeden kuzeye gitmek kâğıt üstünde mümkündür: Orbeyan'dan Selvicar'a doğrudan
  yol yoktur (arada bir sürü yurt ve dolaşılması gereken bir göl var), üstelik herkes Gokyurt'a girmek istemez.
  Kuzeye en mantıklı yol yine Ezmerak'tır.

---

## 7. Halklar ve diller

### 7.1 Oynanabilir beş kültür [Oyun]

| kültür | kendi tanımı | ayrıcalık | kanondaki yurdu |
|---|---|---|---|
| **Göçebe Boyları** | "Bozkırda doğdun; yol senin evin, kervan senin obandır." | yolda az erzak | Gokyurt [Yazar] |
| **Vadi Loncaları** | "Taş köprüler ve lonca defterleri arasında büyüdün; rakam senin dilin." | pazarda indirim | Büyük Vadi [Yazar] |
| **Dağ Kabilesi** | "Geçitleri koruyan bir kabiledensin; kavga senin için pazarlıktan kolaydır." | savaşta fazla hasar | Ayazkaya [Yazar] |
| **Liman Şehri** | "Rıhtımda beş dil öğrendin…" | tavernada haber kolay | Ors / Orsolune [Karar] |
| **Balıkçı Kasabası** | "Ağ onarmayı yürümeden önce öğrendin…" | erzak ucuz | **Tek yurdu yok** [Yazar, Ç12] |

- **[Yazar, Ç12] Balıkçıların tek bir yurdu yoktur.** Balıkçı kültürü kıyıda ve göl kıyısında, balıkçılık
  yapılan her kasabada yaşar ve orada bölgenin kültürüyle karışır: Mirsana'nın balıkçısı limanlıyla,
  Samuran'ınki ve Rivecande'ninki vadiliyle, Brazdun'unki dağlıyla, Kirsavel'inki bozkırlıyla aynı sokakta
  oturur, aynı evde evlenir.
- **[Yazar, Ç8]** Göçebe kültürü **Orbeyan ve Kirsavel**'de başlar (Vaelghard şehirlerinde değil).
- **[Yazar, Ç13] Her bölge oynanabilir:** oyuncu her bölgenin bir yerleşiminden başlayabilir. Bu daha fazla
  kültür demek değildir; çoğu şehir zaten Vadi kültüründedir, başlangıçta kültür yere göre seçilir.
- **[Oyun]** İşe alınanların %75'i yerleşimin halklarındandır (`RecruitCatalog.LOCAL_SHARE`,
  `settlements.json` → `peoples`).

### 7.2 Tepe halkları: Kovrast ve Kemersal [Yazar, Ç2]

- Gokyurt ile Vaelghard arasındaki tepelerde yaşarlar; **dağlı kabilesi sayılmazlar**, kuzey dağlılarından ayrı
  tutulurlar.
- **Orman'ın Nefesi**'ne inanırlar; inanışları daha barışçıdır. Göçebelerle iyi anlaşmalarının sebebi budur.
- [Karar] Orman'ın Nefesi, Dağın Nefesi'yle aynı sözcüğü taşır ama **güce değil sabra** bakar: ağaç izinsiz
  kesilmez, avdan pay ormana bırakılır. Göçebenin "doğaya saygısızlık etme" töresiyle aynı dili konuşur;
  Vaelghard'ın kuzey sınırında iki halk arasında sessiz bir tampon olurlar. Septisist kâtip onları "henüz
  yazılmamış sayfa" diye anar.
- [Karar] Dağlıların "Kara Nefes" dediği İllet, bu tepelerde "Orman'ın Nefesi'nin tersi" diye anılır: ormanın
  verdiğini geri aldığı an. Kervan aynı iki sözcüğü iki ayrı anlamda duyar ve bu kasıtlıdır (§5.1).

### 7.3 Diller

- **[Yazar] İmparatorluk dili** ortak dildir: Vaelghard'ın resmî, gramerli dili; Orvahel'in ve kutsal metnin
  dili; Ezmerak'ta da konuşulur. Kuzey Krallığı'nda keskin, diksiyonlu, dolu dolu konuşulur.
- **[Yazar, T5] Vadi ağzı** ayrı bir dil değildir, aynı dilin daha günlük ve serbest kullanımıdır (şehir ağzı
  ile köy ağzı farkı gibi, ama köy kadar gündelik değil). Vadi, Tolvarin, Kirsavel ve Ezmerak'ta.
- **[Yazar] Göçebe dili:** Gokyurt; Kirsavel'de de konuşulur.
- **[Yazar, T5] Dağlıların dili** ayrı bir dildir; tadı sert ünsüzler, kısa heceler, eski bir kuzey dilinin
  tınısı.
- [Karar] **Taşkök ve Karaocak** dağlıların dilinin yumuşamış bir kolunu konuşur.
- [Karar] **Orsianlar** imparatorluk dilini konuşur ama **sözleşmenin ve hesabın sözcükleri deniz ötesinden**
  gelmiştir. Bir Orsian tüccar borç konuşurken yabancı bir sözcük kullanır ve kuzeyli bunu küstahlık sanır.
- [Karar] **Gelgit Kıyısı** imparatorluk dilini **deniz ağzıyla** konuşur [Yazar, defter IV].
- [Karar] Bir **liman insanının "beş dili"**: imparatorluk dilinin iki ağzı (ağzından nereli olduğu anlaşılır;
  ticarette bu bir dildir), göçebe dili, dağlıların dili ve deniz ötesinden bir dil.

**Metin notu [Karar].** Oyun tek dilde yazılır (tr/en); dil farkı **sözcük seçimiyle** gösterilir, aksan
taklidiyle değil. Kuzeyli tam cümle kurar ve unvan kullanır; Vadili kısa keser ve fiyat söyler; dağlı iki
sözcükle konuşur; göçebe benzetmeyle konuşur (hava, hayvan, otlak); limanlı sayı ve koşul söyler.

---

## 8. İnançlar

**[Yazar]** Sideria'nın iki büyük inancı: **El (The Hand)** ve **Baikhan**. Diğer bütün inançlar küçük, yerel,
yasaklı ya da bu ikisinin içinde erimiş. **Tanrıların varlığı kanıtsızdır**; inanç insanların yorumu ve
ihtiyacıdır. Gerçekten doğaüstü olaylar çok nadirdir ve onlar da insanın idrak edemediği şeylerdir.

### 8.1 El ve onun Kilisesi [Yazar]

- İnancın adı **The Hand**; Türkçe metinlerde **El**. "El'in yazdığı sayfa" inancın dilidir. Kutsal metin
  **El'in Kitabı**'dır; kutsal kentin askerleri onu göğüslerine bağlı taşır.
- [Karar] **El nedir:** adı söylenmeyen bir tanrının elidir. Tanrı yazmaz, **eli yazar**. Kitap bu yüzden "El'in
  yazdığı sayfa"dır. Tanrının kendisi hakkında konuşmak iki mezhepte de yasaktır; konuşulan yalnızca el. Bir
  metin asla tanrının adını aramaz — arayan kişi zaten sapkındır.
- Kilisenin başı **Birinci Okuyucu**'dur. Bugün: **V. Leon "Lekesiz"** (*The Pure*), makamı **Orvahel**.
- Kilise karşılaştığı pagan inançları **asimile ederek** büyüdü ve tarihlerini sildi: Denizin İlk Gözyaşı ve
  Dağın İlk Nefesi'ni adlarını değiştirerek benimsedi; bugün onlar "El'in yazdığı bir sayfa".
- [Karar] Kilisenin bir inancı yutma yöntemi hep aynıdır: **inancın kendi adını alır, yerine bir yer adı koyar.**
  Bu yüzden yasaklı inançlar bugün şehirlerinin adıyla anılır ("Tolvarin'in inancı", "Kirsavel'in inancı");
  kendi adları yalnızca kendi içlerinde yaşar (§8.4).

#### İki mezhep [Yazar, T1]

| | **Septisizm** | **Yumruk (The Fist)** |
|---|---|---|
| ne der | Kitap, zaman içinde eklenen satırlarıyla birlikte El'in sözüdür. Eklenenleri sorgulamak kesin olarak günahtır. | Kitabın yalnızca özü, ilk sayfası okunmalı ve uygulanmalı. Sonradan eklenen her satır yasaktır, bir iğrençliktir. Her şey okunabilir, sorgulanabilir, anlaşılabilir. |
| adı nereden | Farklı dinî görüşleri ezerek El inancına katan imparator **Septimar**'tan | reformcuların sembolünden |
| sembolü | **parmak uçları yukarı bakan, avuç içi görünen açık el** | **yatay, yumruk yapmış el** |
| nerede baskın | Vaelghard, Orvahel (yüzde yüz), kuzey Vadi (Ondrelle, Merigaud), Ezmerak, Zelmarin | güney Vadi (Belvanor, Ilsande, Caramine), Orsolune |
| karışık | Mirsana (ikisi ve eski inanç), Zelmarin (Septisizm ağır) | |

- **Septisizm kilisenin kurulu düzenidir; Yumruk reformdur.** Reformun özü bir geri dönüştür: Septimar'ın ve
  ondan sonrakilerin Kitap'a kattığı her şeyi silip ilk sayfaya inmek.
- [Karar, T35] **Septimar'ın "eklemeleri" asimile ettiği inançların kendisidir:** Dağın İlk Nefesi, Denizin İlk
  Gözyaşı ve adı silinmiş başkaları Kitap'a birer sayfa olarak girdi. Yumruk bu sayfaları söküp atmak ister. Bu
  yüzden **Yumruk'un yükseldiği yerde eski inanışlar daha da sıkışır, Septisizm'in yerleştiği yerde kılık
  değiştirmiş hâlleriyle yaşar.** Bir Yumruk vaizi kıyıdaki balıkçının deniz duasını "sonradan eklenmiş satır"
  diye yasaklar; bir Septisist kâtip aynı duayı Kitap'tan okutur.
- [Karar, T46] **Yumruk'un sembolü** ilk sayfayı sıkıca tutan eldir; açık el bütün sayfaları gösterir.
  Septisist yumruğu öfke diye okur, Yumruk'tan olan sadakat diye.
- [Karar, T47] **Yumruk nasıl doğdu:** çöküşten sonra Belvanor'da. İmparatorluğun dağılmasını Septimar'ın
  eklemelerine bağlayan bir kâtip, Kitap'ın yalnızca ilk sayfasını kilisenin kapısına çaktı ve altına bir soru
  yazdı. **Kâtibin adı bilinmiyor** ve Yumruk bunu bilerek saklar: kimse Okuyan'dan büyük değildir. Güney
  Vadi'nin seküler prensleri Yumruk'u Orvahel'in vergisinden kurtulmak için de sevdi.
- **[Yazar]** Vadi'de din bir inanç göstergesinden çok **topluluk, güç alanı ve politik araçtır**: kiliseler
  orta derecede doludur, iletişim ve ağ kurmak için kullanılır, entrikaya açıktır.
- **[Oyun]** Kilise ekranı Dağın İlk Nefesi ve Denizin İlk Gözyaşı'nı "İki İnanış" başlığıyla okutur.
  **[Yazar, onaylandı]** Septisist kilise ikisini Kitap'ın birer sayfası diye **eşit** okutur; yalnızca Yumruk
  şehirlerinde kilise bu iki sayfayı "sonradan eklenmiş" diye okutur.

#### Dereceler [Karar, T4]

- **Septisizm:** **Birinci Okuyucu** > **Okuyucular** (şehir kiliselerinin başları) > **Kâtipler** (rahipler;
  Kitap'ı kopyalar, eklenen satırları sayfaya işler, okutur, arınmayı yürütür) > **Çıraklar**. Kâtibin asıl
  görevi eklemeleri korumaktır: Kitap'ın her kopyası bütün satırlarıyla, **Orvahel'in mühürlediği sırayla**
  yazılır.
- **Yumruk'ta derece yoktur, Okuyan vardır:** Kitap'ın ilk sayfasını ezbere bilen ve onu herkese sorgulatabilen
  kişi. Cemaat bir Okuyan'ın çevresinde toplanır; Okuyanlar birbirine bağlı değildir.
- [Karar] **Yumruk'un ortak bir sözcüsü yok** ve olmaması bir ilkedir. En yakın şey Belvanor'daki **Soru
  Taşı**'dır: cemaatin sorduğu sorular oraya çakılır, taşın dolması iyi sayılır. Bir Okuyan "Yumruk adına"
  konuşursa Yumruk'tan olanlar ilk ona karşı çıkar.
- [Karar] **Birinci Okuyucu nasıl seçilir:** Okuyucular dört kuleli tapınakta toplanır ve her kulede bir kez oy
  verir; **dört kulede de aynı ad çıkarsa** seçilir, çıkmazsa gün yeniden başlar. Seçilen, eski Okuyucuların
  adlarından birini alır. **Leon** en çok alınan addır: Orvahel'in ilk Birinci Okuyucusu Leon'du. Önceki dört
  Leon'dan yalnızca birincisi hatırlanır; bugünkü beşincidir.

### 8.2 Arınma, şifa ve hastalık [Yazar, onaylandı]

Huy arındırma kültüre göre ya **kilisede ya da doğada ibadetle**, ya da **hastane gibi bir yerde tedaviyle**
olur. Aynı yerde kapılan hastalıklar da iyileştirilebilir. **Mistik bir mucize değil:** işe yarıyorsa insanın
kendisinde, bakımda ve toplulukta yarar.

[Karar] Kültüre göre arınma yolu:

| kim | nerede, nasıl |
|---|---|
| Septisist şehir | Kilise: kâtip Kitap'tan okutur, kişi günlerce dinlenir. |
| Yumruk şehri | İlk sayfa okunur ve **soru sorulur**; arınma bir sohbettir. |
| Gokyurt | Suyla ve yalnız kalmakla: bir gece bozkırda. |
| Ayazkaya, Taşkök | Doğada: dağlı yüksek bir yere çıkar, Taşkök'lü ormanda ağaç diker. |
| Balıkçı kasabası | Kıyıda: ağ onarılır ve bir dua bırakılır. |
| Her yer | **Şifahane** (§8.7): parayla, mezhebe bakmadan. |

### 8.3 Baikhan [Yazar]

- Göçebe boylarının inancı; kilisenin asimilasyonundan kaçabilen tek büyük inanç. Bir dinden çok **yaşam tarzı
  ve felsefe**: özgürlük ve bağımsızlık; doğaya, göğe ve toprağa saygı. Tek ibadeti **yaşama dokunulan her an
  saygı göstermek**. Ölü doğanın parçası olur.
- **[Yazar, defter IV] Baikhan ve Gokana bir varlık değil.** İkisi bir inanışın, göçebe felsefesinin
  unsurlarıdır: **Baikhan yeri ve göğü**, **Gokana suyu ve yağmuru** temsil eder. Birbirini tamamlar, birbirine
  ihtiyaç duyarlar. Bu yüzden göçebe "Baikhan'a" diye dua etmez, **"Baikhan'ın altında"** der; kuyuya inen suya
  **Gokana'nın payı** denir.
- [Karar, T49 — kullanıcı onayladı] Bir varlığa değil bir düzene inanıldığı için **göçebenin tapınağı yoktur**:
  tapınak kapalı bir yerdir, yer ve gök kapatılamaz. Şamanın işi aracılık değil **okumaktır**.
- **[Yazar] Gokyurt'ta Baikhan'dan başka inanç yoktur.**
- **[Yazar] Sogurtay Obası şamanlarındır.** Bütün boylar yılda bir ay oraya göçüp konaklar, suyun tadına varır
  ve doğaya şükreder. **[Yazar, onaylandı T22]** Şamanlar Baikhan'ın tek kurumsal yüzü: kitapları yok, sözle ve
  **sudan** okurlar. **Sogurtay suyu kutsaldır.**
- **[Yazar, T21] Sogurtay'ın takvimi:** dokuz boyun her biri yılda bir ay Sogurtay'a gelir (dokuz boy, dokuz
  ay). Kalan **üç ay** şamanlarındır: sessizce ibadet eder, doğayla bütünleşir, doğayı tımar eder, şükrederler.
  Bu şamanlara doğanın hiçbir unsuru zarar vermez; doğa onları tanır. Boyların beyleri Sogurtay'a yalnızca
  **konsey** toplanacağı zaman birlikte gelir; konsey her zaman orada toplanır.
- [Karar, T36] Bir boyun ayı ötekinin ayıyla **çakışmaz**; Sogurtay'da iki boy aynı anda bulunmaz. Kan davası
  olan iki boy bu yüzden Sogurtay'da hiç karşılaşmaz; barış ancak konsey toplanınca, beylerin ağzından
  konuşulur. Şamanların üç ayı **kışın en sert ayları**: oba kışlağa çekilmişken Sogurtay'da yalnızca şamanlar
  kalır.
- [Karar] Şamanlara **Su Okuyan** denir. Her boy kendi ayında Sogurtay suyunu tadar: **su tatlıysa yıl iyi,
  acıysa kötü geçer.** Bu yıllarda su acı — göçebenin kıtlığa verdiği ad da bu (§5.6). Şamanların kendi adları
  yoktur, yalnızca doğdukları boyun adıyla anılırlar.

### 8.4 Eski inançlar ve küçük inanışlar

- **Dağın Nefesi** [Oyun, Yazar]. Efsanesi: dünya ilk soluğunu dağların doruğunda aldı; ustaların güç sınavı o
  nefese yaklaşma çabasıdır. Sideria genelinde küçük bir inanış ama **en yüksek sesle Ayazkaya'da** yaşar;
  orada güçlü olmak her şeydir. Kutsal doruk **Kartalın Nefesi Zirvesi**.
  - **[Yazar, T20]** Ayazkaya'da yönetim "kim güçlü çıkarsa" el değiştirir. Bir kabile beyinin hükmü, Kartalın
    Nefesi'ne **tırmanıp dönmesiyle** tanınır. Hüküm sınanacaksa meydan okuyan önce dağa tırmanır, sonra mevcut
    beyin yerleşkesinde **düello** edilir; kazananın hükmü sürer ya da el değiştirir. Güç sınavı bir dua değil,
    bir taç giyme.
  - **[Yazar, onaylandı T18] İlk Nefes Taşları** (doğu kıyısı, Saldrek'in güneydoğusu): sınavın başladığı yer.
- **Denizin İlk Gözyaşı** [Oyun]: deniz ilk tanrının gözyaşından doğdu ve hâlâ ağlar; balıkçıların "deniz
  tanrıları".
  - [Karar] **Kimin gözyaşı söylenmez** — El'de olduğu gibi tanrının adı yoktur, yalnızca bıraktığı şey vardır.
    İnanış kıtanın bütün balıkçılarındadır; **en eski kıyısı Gelgit Taşları**'dır (gelgit taşları örtüp açtıkça
    denizin ağladığı söylenir), **sesi** ise batıda, Ağıt Denizi'nde duyulur (§6.2).
  - [Karar] Septisizm bu inanışı Kitap'a bir sayfa olarak kattı; Zelmarin'in "karışık" inancı budur: **kilisede
    El'e, kıyıda denize dua edilir, ikisi aynı kişinin ağzından.**
- **Orman'ın Nefesi** [Yazar]: Kovrast ve Kemersal'in inanışı (§7.2).
- **Yasaklı eski inançlar** [Yazar], Septisizm'in yasakladıkları:
  | kilisenin dediği | kendi adı [Karar] | ne der |
  |---|---|---|
  | "Kirsavel'in inancı" | **Sürü Sözü** | Hayvanlar kutsaldır: ölenlerin taşıyıcısıdır. Bir hayvanı incitmek bir ataya el kaldırmaktır. |
  | "Tolvarin'in inancı" | **Saban Yolu** | Toprak kutsaldır. Tanrısı yoktur; ölenler tarlaya gömülür ve hasatla geri döner. |
  | "Taşkök'ün inancı" | [Karar] **Ocak Duası** ve ağaç töresi | Madencilik ve odunculuk temelli; azınlıkta göçebe inançları. |
  | "Vadi'nin köy inançları" | adları silinmiş | Çok azınlıkta; Septisizm'in içine soğurulmuş hâlleriyle yaşanır ve tanınırlar. Yöneticiler onları pek medeni bulmaz. |

### 8.5 Yol, ölüm ve Bekçi Kadın [Yazar]

- **Yol kutsaldır**, hangi dinden olunursa olunsun: **sen dursan da yol durmaz.**
- **Yolda ölen yola aittir**; mezarı dünyada hitap edildiği adla mühürlenmez. Yol kenarı mezarları bu yüzden
  işaretsizdir. **[Yazar, onaylandı]** Taş yığmak saygıdır, ad yazmak ihlaldir.
- Ahiret: El'e göre cennet ya da cehennem; Baikhan'a göre doğaya karışmak.
- **Bekçi Kadın:** iki inançta da tanrının elçisi; yoldaki ölüleri karşılayan, darda kalan yolcuya farklı
  kılıklarda yardıma gelen. İki inançta da kendi dillerinde "yolcu" anlamına gelen adlarla anılır.
  [Karar] El inancında **Yolcu Ana**, Baikhan'da **Yolkiz** (göçebe dilinde yol ve kız sözcüklerinden). İkisi
  de "yolcu" demek.
- **[Yazar, onaylandı]** Oyundaki yaşlı bekçi kadını halk Bekçi Kadın'ın kılıklarından biri sayar; **oyun bunu
  asla doğrulamaz.**
- [Karar] **Yol dışında ölüler nasıl gömülür:** Septisistler kilise mezarlığına, adıyla. Yumruk mezara yalnızca
  ilk sayfadan bir satır yazar, ad yazmaz. Göçebeler ölüyü bozkıra bırakır. Dağlılar yakar. Bataklıkta suya
  bırakılır. Bir şehirde ölen ama şehre ait olmayan yabancı **Yabancılar Mezarlığı**'na gider (§11).

### 8.6 Yol kenarı sunakları [Yazar]

Çoğu eski pagan dinlerinden kalma: yıkık, başka amaçla kullanılan ya da terk edilmiş yapılar; sağlamlarının
altında o dine göre yerleştirilmiş mezarlar (katakomb), çok azında eski tılsımlı eşyalar.

- **[Yazar, onaylandı]** Ana yollar **imparatorluk yollarıdır**; sunaklar onlardan eskidir. **[Yazar, Ç9]**
  Oyundaki **on yol sunağı durağı kalır**: sunaklar eski yolların kenarında her bölgede bulunur.
- [Karar] Sağlam olanı, altında mezar ya da tılsım taşıyanı çok nadirdir; Vadi'nin dış kıyılarında ve iç köy
  yollarında en sık rastlanır. Taşlarının bir kısmı doğudan taşınmıştır ve bunu kimse bilmez (§1.2/4).

### 8.7 Kurumlar ve şifahaneler

- **Tüccar Loncası** [Oyun, Yazar]: kontrat, borç, haber; her şehirde **aynı defter**. Merkezi imparatorlukta
  Merigaud'ydu, bugün Orsolune.
  [Karar] **Kimseye bağlı değil** — Orsolune'de oturur ama Konsey'e de bağlı değildir. Kendi askeri yok, kiralık
  kılıç tutar. Kiliseyle ilişkisi mezhebe göre: Septisist şehirlerde vergi verir, Yumruk şehirlerinde vermez.
  Kralların hepsine borç verir. **Kuruluşu:** imparatorluk yollarının kervancıları Merigaud'da ilk ortak
  defteri açtı — kim kime borçlu; defter bir kurum oldu.
  [Karar] **Kara Defter:** borcunu ödemeyen kervanın adı her şehirde okunur, hiçbir lonca sözleşmesi alamaz.
  Oyundaki itibar ve borç sistemi bunun yüzüdür.
- **El kilisesi** [Yazar]: Septisizm (Orvahel, Birinci Okuyucu) ve Yumruk (güney, Okuyanlar).
- **Ordular** [Yazar]: Vaelghard'ın düzenli ordusu; Orvahel'in Kitap taşıyan muhafızları; Orsolune'nin küçük
  ordusu ve kiralık kılıçları; dağlıların akınları; göçebe atlıları. [Yazar, defter IV] Vadi'de devlet ve ordu
  yok: **paralı bölükler.**
- **Büyücüler** [Yazar]: Raviellon'da eğitimli; güneyde ve sayılı konseylerde (§3.6).
- [Karar] **Şifahaneler:** çoğu kilisenin manastırıdır (Açık Kapı gibi, §11); Ors'ta bağımsız hekimler vardır.
  Kıtlıkta ikisi de dolu ve ikisi de para istiyor; Açık Kapı istemiyor ve bu yüzden kapısında kuyruk var.

---

## 9. Güçler

### 9.1 Siyasi harita bugün

**[Yazar]** Siyasi birim her bölgede kendi sözcüğünü taşır; oyunun haber kartlarındaki "beylik" sözcüğü
sınırda, Taşkök'te ve bozkırda doğrudur. **[Yazar, 2026-10-30]** Haritadaki her bölge parçası kendi bölgesidir.

| harita parçası | bölge | yönetim | başta | merkez | baskın inanç | dil |
|---|---|---|---|---|---|---|
| kuzeybatı bozkırı | **Gokyurt** (dışarıdakiler: Çadıreli) | Obalar, her biri kendi beyiyle; ortak töre; Büyük Han | Han (Arsalkan Obası) | Arsalkan | Baikhan | göçebe dili |
| kuzeybatı dağları | **Taşkök** | Beylikler; her yerleşimin beyi, ortak konsey | konsey | **Harvek** | madenci ve oduncu eski inançları | dağ dilinin yumuşak kolu |
| kuzey | **Vaelghard Krallığı** (Kuzey Krallığı) | Krallık | Kral **Raegmund** | **Vastrevar** | Septisizm | imparatorluk dili, Kuzey ağzı (resmî) |
| kuzeydoğu dağları | **Ayazkaya** (halkı: dağlılar) | Kabileler; en güçlü kabile hükmeder | **Demirbalta** kabilesi | **Droskal** | Dağın Nefesi | dağlıların dili |
| batı sınırı | **Tolvarin ve Kirsavel** (kervancılar "Çitler" der) | İki bağımsız şehir, iki bey | **Lenart Bey**, **Vasko Bey** | kendileri | yasaklı eski inançlar | Vadi ağzı; Kirsavel göçebe dili de |
| doğu sınırı | **Ezmerak Baronluğu** | Bağımsız baronluk | Baron **Daveric** | **Ezmerak** | Septisizm | Vadi ağzı, Kuzey ağzı |
| orta | **Büyük Vadi** | Her şehir ayrı bir prenslik | prensler | yok | kuzeyde Septisizm, güneyde Yumruk | Vadi ağzı |
| doğu, çember | **Avuçiçi** | Teokrasi | Birinci Okuyucu **V. Leon** | **Orvahel** | yalnızca Septisizm | imparatorluk dili |
| doğu sıradağı | **Karaocak** | Beylik | Vorgat beyi | **Vorgat** | madenci eski inançları | dağ dilinin yumuşak kolu |
| güneybatı kıyısı | **Ors** (halkı: **Orsianlar**) | Orsolune Konseyi (ticaret oligarşisi) | konsey | **Orsolune** | Yumruk | imparatorluk dili + deniz ötesi hesap sözcükleri |
| (Ors içinde) | **Mirsana** | Bağımsız ticaret şehir devleti | **yedi tüccar evi, sırayla** [Yazar, defter IV] | Mirsana | Yumruk, Septisizm ve eski inanç karışık | imparatorluk dili |
| güneydoğu kıyısı | **Gelgit Kıyısı** | Zelmarin Konseyi | konsey | **Zelmarin** | Septisizm ağır, karışık | imparatorluk dili, deniz ağzı |

Haritanın dışında kalan yerleşimler en yakın parçaya düşer: Golcavar Ezmerak Baronluğu'na, Liraven Vadi'ye,
Zelmarin Gelgit Kıyısı'na. **[Yazar, Ç11]** Akavan ve Samuran kanona göre **Vadi**'dir (Ondrelle'e ve Liraven'e
bağlı), haritada batı sınırına yakın düşseler de.

**Adlar [Yazar, Ç4].** Kral **Raegmund**, Baron **Daveric**, Kanlı Baron **Aldemar**, Dük **Valdric**,
Tolvarin'in **Lenart Bey**'i, imparator **Septimar** (mezhebin adı Septisizm kalır). Birinci Okuyucu **V. Leon**
adını korur. Cevaplardaki yazım haritaya göre düzeltildi: Tolyarin → **Tolvarin**, Ezmarek → **Ezmerak**,
Akayan → **Akavan**, Lirayen → **Liraven**, Droskol → **Droskal**, Belvanır → **Belvanor**.

### 9.2 Konseyler nasıl çalışır [Karar]

- **Orsolune Konseyi:** dokuz sandalye, en büyük dokuz defter (ticaret evi). Sandalye tuttuğu borçla alınır;
  başkan yoktur, **Defter Başı** her yıl dönüşümlüdür. Kıtlıkta sandalye değişimi hızlandı.
- **Mirsana:** **yedi tüccar evi sırayla** yönetir [Yazar, defter IV]. Sıra bir yıldır ve kimse sırasını
  satamaz (satmayı denemiş iki ev bugün yok). Pazarın günlük işini, tezgâh sahiplerinin seçtiği **Terazi**
  yürütür: sıradaki eve bağlıdır ama onun adamı değildir — bu denge Mirsana'nın bütün siyasetidir.
- **Zelmarin Konseyi:** kaptanlar ve bağ sahipleri. Bugün ikiye bölünmüş: bağ sökülüp buğday ekilsin mi
  (§10.11).
- **Taşkök konseyi:** her yerleşimin beyi. Bir kuralla toplanır: **odun satılır, orman satılmaz.**
- **Gokyurt konseyi:** yalnızca iç sorunda toplanır, Sogurtay'da; Büyük Han yönetir, askerî müdahale etmez.
- **Avuçiçi:** konsey yok; Okuyucular yalnızca Birinci Okuyucu seçimi için toplanır (§8.1).

### 9.3 İlişkiler ağı

| kim | kime | ne |
|---|---|---|
| Gokyurt | Vaelghard | düşman; yağma ve pusu, karşılıksız [Yazar] |
| Ayazkaya | Vaelghard | düşman; savaş (bir yol kavgası) [Yazar] |
| Gokyurt | Taşkök | dost, ticaret anlaşması [Yazar] |
| Ayazkaya | Ezmerak | ticaret anlaşması (tuz ve çeliğin kapısı) [Yazar] |
| Vaelghard | Orvahel | müttefik ve garantör [Yazar] |
| Vaelghard | Orsolune | borçlu, hoşnutsuz [Yazar] |
| bazı Vadi şehirleri | Ezmerak | borçlu [Yazar] |
| Orsolune | kıtanın çoğu | borç verir, ticaret anlaşmaları [Yazar] |
| Orsolune | Zelmarin | ticaret anlaşması [Yazar] |
| Tolvarin | Kirsavel | husumet, küçük savaşlar [Yazar] |
| Caramine | Belvanor | barış ve ticaret [Yazar] |
| Ilsande | Caramine | savaş [Yazar] |
| Merigaud, Ondrelle, Belvanor | birbirleri | savaş [Yazar] |
| Orvahel | bütün kâfir şehirler | düşman ama yalnızca kendini korur [Yazar] |
| Vaelghard | Büyük Vadi | "düzen için" iniyor; asıl derdi Kemersu'nun değirmenleri [Yazar, defter IV] |
| Karaocak | Avuçiçi | cevher satar, kapıdan içeri alınmaz [Karar] |
| Zelmarin | Karaocak | komşu; Vorgat'ın cevheri gemiye Zelmarin'den biner [Karar] |

**[Yazar, onaylandı T28] Vaelghard çember içinde:** batıda göçebeler, kuzeyde ve doğuda dağlılar, güneyde
borçlu olduğu güney. Kibri yüzünden birden fazla düşmanla birden savaşıyor ve bu yüzden şu an hiçbir cephede
kazanamıyor. Ama her şey birkaç diplomatik ya da yeterince zekice stratejik hamleyle her an değişebilir. Herkes
ondan korkuyor, o herkese karşı bekliyor.

**[Yazar, defter IV] Bugünün eşiği:** perişan ordular arasında bazı devletler **göçebe topraklarına göz
dikmeye cüret eder oldu** — Gokyurt kıtanın hâlâ beslenen tek yeri. Henüz kimse harekete geçmedi. Oyunun bugünü
bu eşiğin üstünde durur ve haber kartları bu gerilimi taşır.

---

## 10. Bölgeler ve yerleşimler

Her bölgede: ne olduğu, kervanın ne yaşadığı, neyi asla affetmediği, sonra yerleşimleri. Yerleşim satırlarının
üçlüsü **kalp** (şehrin merkezinde ne var), **gelenek** (kervanın uymak zorunda olduğu şey) ve **kıtlık** (orada
yokluk nasıl görünüyor) — oyun içi metin üretmek için en çok kullanılacak yer burası.
Yerleşim maddeleri [Karar]; bölge maddeleri belirtilmedikçe [Yazar].

### 10.1 Gokyurt

İçeriden **Gokyurt**, dışarıdan biraz küçümseyerek **Çadıreli** denir. **[Yazar, onaylandı T29]** "Çadıreli"
Vaelghard'ın ağzıdır: bir kayıt bürosunda adı olmayan, vergi vermeyen halka verilmiş ad.

- **Yönetim:** her obayı kendi beyi yönetir; obalar kendi törelerine sadıktır ve birbirinin işine karışmaz.
  Bütün boyların ortak, kültürel bir töresi vardır. Çok nadir bir iç savaş çıkarsa diğer beyler arayı bulmak
  için **konsey** kurar; barışı sağlarlar ama askerî müdahale etmezler. Konseyi en kuvvetli boyun beyi, **Büyük
  Han** yönetir.
- **Han:** hanın obası bugün de **Arsalkan**. Han gücüne göre belirlenir; hanlığın değişmesi için bir obanın
  hanın obasıyla savaşıp kazanması gerekir. Han yalnızca dış ilişkileri yönetir ve bir iç sorunda konseyi
  toplar; obaların iç işine karışmaz.
  [Karar] Bugünkü Büyük Han **Kaytaş Han**: yaşlı, büyük savaşı çocukken gördü. Arsalkan'da oturur, Vaelghard'la
  açık savaştan kaçınır ama genç beylerin akınlarını durdurmaz: *"Otlak kurursa ok kendi yolunu bulur."*
- **Dokuz boy** vardır, her birinin bir yurdu var; **Sogurtay** bunlardan sayılmaz, şamanlarındır. Haritadaki
  dokuz oba: Kaynurak, Ebrusun, Sadirim, Ilkatay, Burkasan, Otekur, Taragun, Yelbarik, Arsalkan.
- **Göçebe birliği** dağılmış bir şey değil; boyların kendisidir. Tarihte bütün boyların birlikte davrandığı tek
  olay imparatorluğa karşı savaştır.
- **Göç:** hava soğudukça obalar Gokyurt içinde güneybatıya göçer; orada hayvancılık ve balıkçılık yaparlar.
- **Yabancı kervan:** bozkıra girmeye cesaret eden kervan **doğaya saygısızlık etmemesi** gerektiğini bilir;
  geçtiği yerlerin **beylerinden izin almış ve hediye getirmiş** olmalıdır. Misafirlik ve hoşgörü esastır ama
  hediye yine de beklenir. Göçebeler yoldaki kervanlara saygı duyar.
- **Asla affetmediği:** saygısızlık ve bağımsızlığına dokunulması.
- **Komşular:** Vaelghard düşman (yağma ve pusu; Vaelghard henüz karşılık verememiştir); Taşkök dost.
- **Kıtlık:** sınırını kapattığı için en az etkilenen bölge; kıtanın hâlâ en sağlıklı yeri. Misafirlik burada
  hâlâ bedava (§5.3). Buna karşılık bugün **göz dikilen** yer de burası (§9.3).

**Orbeyan Kervansarayı** — Gokyurt'un kapısı; buradan izinsiz geçilmez. Göçebelerin ticaret ihtiyacını
karşılar; yalnızca göçebelerin izin verdiği tüccarlar gelebilir. Onu göçebe kültürüne mensup, dışarıyla ve
bütün boylarla ilişkisi olan biri yönetir.
- *Kalp:* [Karar] işletmecisi **Kutlay Ana**, Arsalkan'dan bir beyin dul karısı. Dokuz kızı dokuz boya gelin
  gitti; bütün boylarla bağı budur. İzin bir **tamga**dır: boyun damgası keçeye basılır, kervan onu çadırının
  direğine asar. Tamgayı veren boy kervanın sözünden sorumludur.
- *Gelenek:* [Karar] kervansarayda kimse at üstünden konuşmaz; silah keçe kapının dışında kalır. Kutlay Ana'nın
  çadırına girmeden önce eşikteki suya el batırılır (Sogurtay suyundan bir avuç).
- *Kıtlık:* [Karar] otlak erken kuruyor, obalar hayvanını ucuza satıyor. Kürk ve et bol, tahıl yok. Obalar demir
  değil **kumaş ve un** istiyor; buraya un getiren kervanın tamgası bir yıl geçer.
- **[Yazar, Ç6]** Orbeyan'ın baharatı denizden gelmez: bozkırın kendi kuru otu (kekik, kımız mayası),
  **bozkır baharı**. Deniz baharatından ucuzdur.

### 10.2 Vaelghard Krallığı

Kuzey Krallığı da denir; halk kendine de Vaelghard der. Bugün Kral **Raegmund** yönetir; başkent **Vastrevar**.
Eski imparatorluğun en güçlü kalıntısı, en güçlü şehirleri burada; resmî devamı değil ama aynı kültürü taşır.

- **Dil:** resmî ve grameri kuvvetli; edebiyatı çoğunlukla roman, kanun ve tarih.
- **İnanç:** baskın inanç Septisizm; halk içinde başka inanış yoktur, bölge bu konuda çok katıdır. Krallık
  kilisenin koruyucusudur. Yalnızca dağ kabileleri kendi dinlerini yaşar ve Vaelghard'la savaşır.
- **Kervan girerken:** sınırdaki büroya girer, sıra bekler, kayıt evraklarını doldurur, mal ve yolcu beyanı
  verir, vergisini öder. İçerisi güvenli ve korunaklıdır. Dağlar ve göçebe sınırı tehlikelidir: bu iki yandan
  sık baskın alır, ordu baskınların hızına ve taktiğine yetişemez.
- **Ordu:** en resmî ve düzenli ordu; sıkı eğitimli, Vaelghard'a bağlı. Kervanları sık teftiş eder ama sorun
  yoksa sorun çıkarmaz; **rüşvet almaz, istemez.**
- **Asla affetmediği:** cahillik, pislik, imansızlık ve ülkesine ya da dinine saygısızlık. Her şey bir düzen
  içinde olmalıdır.
- **Komşular:** Orvahel'in müttefiki ve garantörü; **güney kentlerine borçlu** ve bundan hoşnut değil; bütün
  krallık ve beylikler ondan korkar.
- **Çelik ikilemi [Yazar, onaylandı T12]:** Ayazkaya'nın madenleri Ezmerak ve tüccarlar üzerinden Vaelghard'a
  akar; **Vaelghard bu madenlerin kaynağını görmezden gelir.** Yani Vaelghard ordusu, savaştığı dağlıların
  Kazrun çeliğini taşır. Bir Vaelghard subayı bunu bilir ama söylemez; bir dağlı bunu bilir ve güler.

**Vastrevar** — kralın şehri: burada her şeyin bir kaydı var. İmparatorluğun en büyük kentlerinden biriydi.
- *Kalp:* şehrin kalbi saray değil **Kayıt Bürosu**. Kral sarayda oturur, şehir büroda yaşar: her doğum, her
  vergi, her kapıdan giren kervan oraya yazılır. "Çadıreli" sözü buradan çıktı.
- *Gelenek:* kapıdaki kâtip kervanın adını deftere **bir kez** yazar; yanlış yazarsa ad öyle kalır. Vastrevar'da
  adı yanlış yazılmış eski kervanlar vardır ve bununla övünürler.
- *Kıtlık:* demir ve kumaş çıkarır, ekmeği güneyin kesesinden yer: buğday borçla gelir. Fırın kuyrukları uzar,
  kâtip kuyruğu da yazar.

**Auderin** — kıtanın en kuzeyi; kürkün ve uzun kışın kasabası. Ona çıkan yol kışın kapanır.
- *Kalp:* ötesinde daima kar var. Auderinliler karın içinde uyuyan eski şeylerin hikâyesini anlatır; kimse
  oraya gitmez, giden dönünce konuşmaz.
- *Gelenek:* ilk karda her ev kapısına bir kürk asar, son karda indirir. Kürk ne kadar uzun asılı kalırsa kış o
  kadar uzun sürmüş sayılır. **Bu yıllarda kürkler inmiyor.**
- *Kıtlık:* kuzey yolu her yıl biraz daha uzun kapalı kalıyor. Buğday gelmezse kürkü yerler: deriyi kaynatıp
  çorba yaparlar. Şarap bir yıldır görülmedi.

**Dravoss** — kralın ambarı ve cephaneliği.
- *Kalp:* imparatorluktan kalma büyük ambar. Buğday ve demir buradan orduya gider; hasat kayda geçmeden ambara
  girmez.
- *Gelenek:* ambar memuru mühürlemeden tek başak kesilmez. Mühürsüz başak saklayan köylü **Kızıl Ferman
  Darağacı**'nda asılır.
- *Kıtlık:* buğday üretir ama önce ordu, sonra başkent alır; köylüye kalan sayılmış ve azdır. Köyler buğdayı
  toprağa gömüp saklıyor, memurlar şişle toprağı yokluyor.

**Selvicar** — Gokyurt'a bakan sınır kasabası.
- *Kalp:* geçimi tahıl; derdi obaların akınları. Kütük suru her yıl biraz daha içeri çekildi.
- *Gelenek:* akşam çanı çalınca kapı kapanır; geç kalan dışarıda kalır ve kimse açmaz. Selvicarlı bir göçebeyle
  aynı sofraya oturmaz, ama atını ondan alır.
- *Kıtlık:* otlak erken kuruyunca obalar her yıl daha erken ve daha aç geliyor. Kasaba buğdayını surun içine
  taşıdı; sur dışındaki tarlalar ekilmiyor.

**Rivecande** — kuzeyin tek limanı; denize değil **Ayna Göl**'e bakar (§6.2).
- *Kalp:* rıhtımda göl gemileri ve dağlıların kayıkları. Kazrun çeliği Vaelghard'a yasal yoldan buradan girer
  (Kesgrav yolu).
- *Gelenek:* limanın ağzında bir zincir var; savaşta gerilir. Zinciri geren aile kuşaklardır aynı aile ve
  zincir onların adıyla anılır.
- *Kıtlık:* balık bol, tuz kıt. Mühürsüz tuz Rivecande'de yasak ama en çok burada satılıyor: tuzsuz balık bir
  gecede kokar.

### 10.3 Ezmerak Baronluğu ("Baron'un toprakları")

Ezmerak ve Golcavar'ı kapsayan bağımsız bölge. Kuzeye akan ticaretten beslenir; tarım için pek çok sulak yeri
vardır. Kültürü Vadi ile güney kentleri arasında; inanç Septisizm.

- **Hanedan:** imparatorluk zamanında bu toprakları **Dük Valdric** yönetiyordu. Piç oğlu **Aldemar** hanedanda
  yetişmesi uygun görülmeyip orduya verildi; imparatorluk çöktükten sonra Valdric'in öldüğünü öğrenince döndü ve
  hanedanın geri kalanını bir yemekte basıp öldürdü. **Kanlı Baron** namını ve toprakların yönetimini böyle
  aldı. Buna rağmen bölgeyi hiç olmadığı kadar iyi yönetti; refah arttı. Ordu yıllarında kaptığı
  hastalıklardan genç yaşta öldü ve yönetimi oğlu **Daveric**'e bıraktı. Daveric bugün artan ticarete odaklı,
  halkından biraz uzak bir lider; aradaki konumu hem Vadi hem Kuzey Krallığı için kritik ve bunu en faydacı
  şekilde yönetmeye çalışır.
- **Baron'un kanunu:** bölgeden geçen kervan mutlaka Ezmerak'a uğrar ve orada **en az bir öküz değerinde**
  ticaret yapar. Ezmerak halkı en çok **kandırılmaktan** nefret eder: aldatma, birini düelloya davet edip
  öldürmek için **kanunen haklı bir sebeptir**.
  **[Yazar, onaylandı T14]** Bu yasa kurucusunun bir yemekte akrabalarını aldatıp öldürmesinin gölgesidir:
  Daveric, babasının yükseldiği yolu herkese kapatarak kendi tahtını korur.
- **Mühürsüz tuz [Yazar, T11]:** Saldrek'ten (Ayazkaya) gelir. "Mühürsüz" demek Vaelghard'ın ya da baronun
  vergi mührünü taşımamak demek; bu yüzden **daha ucuzdur**. Satmak **Ezmerak'ta ve büyük şehirlerde
  yasaktır**; kervansaraylarda ve küçük yerlerde el altından satılır. Ezmerak'ın dağlılarla anlaşması tuzun ve
  çeliğin kapısıdır: yasal yoldan giren tuz orada mühürlenir.
- **Komşular:** bazı Vadi şehirleri ona borçlu; dağ kabileleriyle ticaret anlaşmaları var.
- **Sur:** Ezmerak taş surlu [Oyun]; doğudaki kütük surlar sık el değiştirmenin sonucu.

**Ezmerak** — Baron'un şehri: geçen her kervan burada ticaret yapar.
- *Kalp:* kale baronu dışarıdan değil **kendi halkından** korur. Kanlı Baron'un yemeği **Kırmızı Sofra** denen
  salonda oldu; salon bugün sözleşme mahkemesi, anlaşmalar aynı masada imzalanır. **Daveric o salonda yemek
  yemez.**
- *Gelenek:* kapıda **Öküz Kâtibi** oturur: kervanın yaptığı ticareti yazar ve bir **boynuz fiş** verir. Fişsiz
  çıkan kervan İki Bayrak Kulesi'nde ya da Golcavar yolunda iki katını öder.
- *Kıtlık:* sulak tarımı Ezmerak'ı korur; baron buğdayı Vadi'ye **borçla** satar. Vadi şehirleri bu yüzden ona
  borçlu: kıtlık baronun kesesini büyütüyor ve halk bunu biliyor.

**Golcavar** — baronluğun su tarlaları.
- *Kalp:* bataklık kurutulup kanallarla tarla yapıldı; **Kanlı Baron'un tek iyiliği** diye anılır. Balık ve
  iksir çıkar.
- *Gelenek:* kanal başında gece nöbet tutulur. Suyu kendi tarlasına çeviren, kanalın sahibine bir hasat
  borçlanır.
- *Kıtlık:* ambar dolu ama baronun. Köylü aç; buğday Ezmerak'a, oradan Vadi'ye gidiyor. Golcavar'da *"bizim
  ekmeğimiz borç olarak gider"* denir.

### 10.4 Tolvarin ve Kirsavel (batı sınırı, kervancıların adıyla "Çitler")

Husumetli iki sınır şehri; ikisi de bağımsız. Tolvarin Vadi kültürüne, Kirsavel göçebe kültürüne daha yakın;
ikisi de arada kalmış halklar. Sonuç: bitmek bilmeyen sınır kavgaları, güç arzusu, küçük savaşlar.

- Tolvarin'i **Lenart Bey**, Kirsavel'i **Vasko Bey** yönetir. İkisi de Vadi ağzıyla konuşur; Kirsavel göçebe
  dilini de.
- **İnançları Septisizm'in yasakladığı eski inançlardır** (§8.4): Tolvarin'de **toprak**, Kirsavel'de
  **hayvanlar** kutsaldır; ikisine zarar vermek büyük saygısızlıktır.
- **[Yazar, onaylandı T13]** Kavganın kökü inançlarında: Kirsavel'in kutsal sürüleri otlak arar, Tolvarin'in
  kutsal toprağı çiğnenmez. Her sınır ihlali iki tarafın da kutsalına yapılmış bir saygısızlıktır.
- Kervan bu bölgede kimsenin arsasına ve toprağına yanaşmamaya özen gösterir; bu yüzden çok kan döküldü.
- **[Yazar, Ç7]** Batı sınır kasabaları yoksulluktan kütük surludur; Tolvarin ise şehirdir, taş suru
  imparatorluktan kalmadır. **Savaş mültecileri bu topraklarda yoğundur ve ucuz işçi olarak çalıştırılır.**
- "Sınır halkları" yalnızca lore ve harita yazımında arada kaldıkları için birlikte sınıflandırıldı; **hiçbir
  yerde birlikte adlandırılmazlar.** [Karar, T38] Ortak adı yalnızca kervancılar koydu: **"Çitler"** — Tolvarin
  her tarlayı çitler, Kirsavel her otlağı; kervan çitler arasından geçer ve hiçbirine dokunmaz. Bir Tolvarinli
  ya da Kirsavelli bu adı duyunca kervancıyı yabancı sayar.
- **[Yazar, onaylandı T15]** **Bölünmüş Sancak Ovası** iki şehrin bir zamanlar tek sancak altından ayrıldığı
  yer; **Dönek Darağacı** taraf değiştirenlerin asıldığı yer.
- **[Yazar, onaylandı T30]** Haber kartlarındaki "iki beyliğin savaşı" en çok bu ikisinin savaşıdır.

**Tolvarin** — toprağın kutsal olduğu şehir.
- *Kalp:* şehrin ortasındaki **Ekin Taşı**: imparatorluktan önce de ekilen ilk tarla. Lenart Bey her bahar ilk
  sabanı orada sürer.
- *Gelenek:* kervan şehre girerken tekerleklerin çamurunu kapıda bırakır: yabancı toprak kutsal toprağa
  karışmasın. Kapıda bunun için bir oluk ve su var; yıkamayan kervan içeri alınmaz.
- *Kıtlık:* toprak kutsal ama ekin yetmiyor. Kirsavel'in sürüleri gece tarlaya iniyor. Mülteciler tarlada
  ucuza çalışıyor; Tolvarinli ekmeği onlardan esirgiyor ve bunu **toprağın hakkı** sayıyor.

**Kirsavel** — hayvanların kutsal olduğu kasaba.
- *Kalp:* geçimi tahıl ama zenginliği sürü: **sürü satılmaz, ödünç verilir.** Vasko Bey kendi atını kimseye
  vermez; atının adını herkes bilir, karısınınkini değil.
- *Gelenek:* kervanın hayvanları kapıda sayılır, çıkışta yeniden sayılır. Yolda ölen hayvanın hesabı sorulur;
  döven kervan kasabadan çıkarılır. Kirsavel'de öküz "değer" diye anılmaz: Ezmerak'ın "öküz değerinde ticaret"
  kuralı burada bir hakaret sayılır.
- *Kıtlık:* hayvan kesmek yasak, insan aç. Kutsal sürü insanlardan iyi besleniyor ve öfke Vasko Bey'e
  yöneliyor. Gizlice kesilen bir koyunun kemiği bulunursa bütün ev kasabadan atılır.

### 10.5 Ayazkaya (kuzeydoğu dağları)

Halk kendine **dağlılar** der; yaşamları dağlar ve madenlerle bütünleşmiştir.

- **Yönetim:** bölgeyi dağ kabileleri yönetir; yönetim **Droskal**'deki **Demirbalta** kabilesinindir. Zaman
  zaman öbür kabileler muhalefete geçer; kim güçlü çıkarsa o kazanır (hüküm sınaması §8.4). En güçlü ve en eski
  kabile **Droskal**, ikinci **Ulmarec**, üçüncü **Ulgras**.
- Kuzeybatı ve kuzeydoğu dağlarındaki kabileler **aynı çatı altındaki farklı kabileler**, aynı halkın iki kolu;
  ama haritada kuzeybatı dağları Taşkök'ündür ve Kovrast ile Kemersal dağlı sayılmaz (§7.2).
- **İnanç:** Dağın Nefesi burada en yüksek sesle yaşar. **Güçlü olmak çok önemlidir.**
- **Haydutluk burada bir geçim kaynağı değil, kültürdür.** Kervan yeterince korumalı olmalı ya da bölgede
  tanıdığı olmalı; yoksa her an pusuya düşer.
- **Geçitler:** Ulmarec ile Droskal arasında gizli geçitler var. Rivecande–Kesgrav yolu özellikle başka
  ülkelere karşı korunur. Bölgedeki her yolda bedel ödenmemişse ya da zayıfsan **bedeli tekrar tekrar
  ödersin**.
  **[Yazar, onaylandı T19]** Oyundaki **haydut kralları** en çok Ayazkaya'nın bedel kültürüdür: bir kabile bir
  yolu tutar, bedeli isteyen kabileye göre değişir. [Karar] "Haydut kralı" bir unvandır, bir kişi değil: bugün
  üç ünlüsü var, en ünlüsü Kesgrav yolunu tutan Demirbalta kolundan biri.
- **Asla affetmediği:** güçlerinin hafife alınması, fiziksel olarak tiye alınmak. Sorunlarını kavgayla
  çözerler.
- **Kazrun Ocağı** kıtanın en sağlam çeliğini üretir; **Saldrek Tuzlası** mühürsüz tuzun kaynağıdır.
- **Komşular:** Vaelghard'la düşman, öbür bölgelerle iletişim yok, Ezmerak'la ticaret anlaşmaları var.

**Brazdun** — Kazrun çeliğinin işlendiği maden kasabası.
- *Kalp:* madende demir ve değerli taş çıkar; kazan dağlıdır, kazancı kabile alır. Kazrun'un çeliği burada
  kılıç olur.
- *Gelenek:* yabancının silahı kapıda tartılır; hafif silah gülünç sayılır. Bir dağlıyla güreşmeyi reddeden
  kervan pazarlıkta hep kaybeder.
- *Kıtlık:* tahılı yağmayla ya da çelikle alır. Brazdun'un çeliği buğday karşılığı Vaelghard'a gidiyor:
  savaştığı düşmanın ekmeğini yiyor.

**Kesgrav** — Ayazkaya'nın Vaelghard'a açılan kapısı; bedel kapısı.
- *Kalp:* maden kasabası, demir çıkar. Rivecande yolunu dağlılar korur ve bedelini alır.
- *Gelenek:* **bedel taşı** — kervan bedelini yol başındaki taşa koyar, kabile gece alır. Bedel konmazsa yol
  sabah kapanır.
- *Kıtlık:* şarap ve buğday ister; ikisini de düşmanından alır. Kıtlıkta bedel yükseldi: artık para değil **un**
  isteniyor.

### 10.6 Taşkök (kuzeybatı dağları)

Merkezi **Harvek**. Haritadaki yerleri: Harvek, Zurek, Dornak, Velkrun Yıkıntısı. **Oynanabilir yerleşimi yok;
kervan oraya kadar nadiren çıkar** — çıkarsa hoş karşılanır. Kullanıcının tarifiyle "kuzeybatıdaki barışçıl dağ
ve orman beylikleri".

- **Geçim:** az sayıda ama değerli cevherli maden, ünlü odunlar; odunculuk, marangozluk ve kuyumculuk. Halk
  kıtanın geri kalanına göre mütevazı ve hoşgörülü yaşar.
- **Yönetim:** madenler bölge halkınındır. Daha adil bir yönetim: her yerleşimin bir beyi var, beylikler
  birbirine yardım eder ve konseylerinde birlikte karar alır.
- **İnanç:** madencilik ve odunculuk temelli eski inançlar baskın, azınlıkta göçebe inançları.
- **Komşular:** göçebelerle dost, ticaret anlaşmaları var.
- **Asla affetmediği:** çok sabırlıdır; onu yalnızca **ihanet ya da katliam** gibi büyük kötülükler
  öfkelendirir.
- **[Yazar, Ç2]** **Zurek** Mezrası dağ kabilesi kültüründendir: işçiliği kıymetli madenciler ve kuyumcular.
  (Zenginliğinin altında kadim bir şehir var, §3.2.)
- [Karar, T43] **Velkrun Yıkıntısı** Taşkök'ün imparatorluğa bağlandığı tek yerdi: imparatorluk orada bir
  **kereste ambarı** kurdu ve Taşkök'ün ünlü odunu başkentin çatılarına oradan gitti. Parçalanmada ambar
  yakıldı; Taşkök bir daha kimseye bağlanmadı. Harvek'in konseyi o günden beri bir kuralla toplanır:
  **odun satılır, orman satılmaz.**

### 10.7 Karaocak (doğu sıradağı)

Yerleri: **Vorgat** (oynanabilir maden kasabası), Kemrug, Kör Kazmalar Mezarlığı.

- [Karar, T37] Adı **Karaocak**: ocak hem maden kuyusu hem demirci ocağıdır; sıradağın karası kömürden ve
  isten. Taşkök'le aynı kökten gelir ama **Taşkök odunu, Karaocak cevheri yaşar.**
- [Karar, T44] **Kültür ve yönetim** Taşkök'ünkiyle akrabadır: madenler halkındır, her yerleşimin beyi var. Ama
  Karaocak tek başınadır. Vorgat'ın beyi bölgenin sözcüsüdür; Kemrug ona bağlı küçük bir ocaktır. **Konseyi
  yoktur, çünkü yardım isteyecek komşusu yoktur.**
- [Karar, T44] **Komşular:** batıda Avuçiçi, güneyde Gelgit Kıyısı. Avuçiçi'nin yolu Vorgat'tan geçer, zil
  oradan satılır. **Orvahel Karaocak'ın cevherini ister ama eski inancını şehrine sokmaz:** maden kapıda
  alınır, parası kapıda ödenir. Karaocaklı bunu bir aşağılama olarak bilir ve yine de satar; kıtlıkta başka
  alıcı yok.
- [Karar, T44] **Kör Kazmalar Mezarlığı:** ocakta gözünü kaybeden madencilerin mezarlığı. Karaocak'ta kör
  madenci kazmasını bırakmaz, ocağın karanlığında gözü olandan iyi yürür; öldüğünde kazmasıyla gömülür.
- [Karar] Madencilerin bugün çalıştığı galerilerin bir kısmı **kadimlerin açtığı** galerilerdir ve bunu bilen
  yalnızca en yaşlı ustadır; o da anlatmaz, çünkü anlatan ustanın ocağı kapanır.

**Vorgat** — zilin döküldüğü nehir kasabası; Avuçiçi yolu buradan başlar.
- *Kalp:* **Ocak Suyu** kıyısında; değerli taş ve balık çıkar. Kervan iki şey fark eder: **zil sesi** ve
  **isli hava**.
- *Gelenek:* Orvahel'in zillerini Vorgat'ın **eski inançlı** dökümcüleri döker. Dökümcü zili kutsamaz, yalnızca
  sesini dener; Orvahel zili kapıda kutsar. Karaocaklı kervanı hoş karşılar ama pazarlık etmez: **cevherin
  fiyatı ocağın derinliğidir.**
- *Kıtlık:* Orvahel cevheri ucuza alıyor; balık var, tahıl yok. Vorgatlı zil satıp ekmek alıyor ve bunu kendine
  yediremiyor.

### 10.8 Büyük Vadi

Halk arasında **Büyük Vadi**. Her şehir bir devlettir, hepsi birer **prenslik**; imparatorluk bölündüğünde bu
şehirlerin prensleri ve hanedanları bağımsızlık ilan edip yerlerini korudu.

- Kuzeydeki **Ondrelle ve Merigaud** daha mikro milliyetçi; **Belvanor, Ilsande ve Caramine** daha seküler,
  Yumruk ağırlıkta.
- **Dil:** imparatorluk dilini taşır, ama kullanımı Kuzey Krallığı'na göre daha günlük ve serbest.
- **Kervan girerken:** savaşları ve kıtlığı fark eder. Yollar çapulcu, haydut, yozlaşmış görevli ve açlıktan
  yollara inmiş vahşi hayvanlarla tehlikelidir.
- **Asla affetmediği:** eleştiri. Vadi halkı eleştiriye sabredemez, en çok ona öfkelenir.
- **[Yazar, onaylandı T23] Vadi buğday üretir ve aç kalır:** toprak kıtanın en verimlisi, ama bitmeyen prens
  savaşları hasadı yakıyor, yolları kesiyor ve köylüyü kaçırıyor. Kıtada en çok kıtlık ve mali zarar yaşayan
  bölge.
- **[Yazar, defter IV] Bugünkü savaşlar kimler arasında:** **lonca şehirleri kendi aralarında.** Devlet yok,
  ordu yok; her şehir **paralı bölük** tutuyor ve bölükler **ambarlar** için birbirine giriyor. Cephe diye bir
  şey yok, bir vadi boyunca süren kavga var. **Vaelghard** kuzeyden zaman zaman "düzen için" iniyor — asıl derdi
  **Kemersu'nun değirmenleri**; Vadi bunu işgal sayıyor, Vaelghard koruma.
- **[Yazar, defter IV]** Bu kıtlığın savaşıdır: kimse toprak istemiyor, herkes **ambar** istiyor — ve ambardan
  da çok **işgücü**. Dağılan paralı bölükler yolun asker kaçaklarının ana kaynağıdır (§12).
- **Lonca:** imparatorluk zamanında Tüccar Loncası'nın merkezi Merigaud'ydu; çöküşten sonra Orsolune'ye taşındı.
- **İpek:** Ilsande ve Duvenmor standart, iyi bir ipek üretir (§13.2).

**Ondrelle** — imparatorluk çökünce kendi şartını ilk yazan şehir.
- *Kalp:* çöküşte imparatorluk valisinin kapısını kapatıp şehrin anahtarını prense verdi; bedeli Akavan'ı
  tutmaktı. Prens ve kilise birlikte yönetir; Septisist ve mikro milliyetçi.
- *Gelenek:* Ondrelle ağzıyla konuşmayan yabancıya fiyat iki kez söylenir: önce yabancıya, sonra
  Ondrellelilere.
- *Kıtlık:* buğday ve bal var ama savaşa gidiyor. Kapı sıkı: aç mülteci içeri alınmaz, surun dibinde bekler.

**Merigaud** — loncanın eski evi. Adını yakılan başkentten alır (§4.1).
- *Kalp:* imparatorlukta loncanın merkezi buradaydı; lonca defterlerinin eski kopyaları hâlâ burada. Mikro
  milliyetçiliği bu mirastan gelir: başkent yanınca loncanın kâtipleri buraya kaçtı ve şehir başkentin
  defterlerini sakladı.
- *Gelenek:* lonca salonunda bir koltuk **boş** durur: lonca Orsolune'ye gitti, koltuk onun dönüşünü bekler.
  Oturmak yasak değil ama kimse oturmaz.
- *Kıtlık:* buğday üretir ama Ondrelle ve Belvanor'la savaşta; tarlalar sınırda yanıyor. Merigaudlu açlığa
  değil **Belvanor'a** kızıyor.

**Belvanor** — Yumruk'un doğduğu şehir.
- *Kalp:* prensi kiliseyi yanına alarak değil, **kiliseden ayrılarak** güç kazandı. Seküler; Yumruk'un ilk
  sayfası burada kilisenin kapısına çakıldı.
- *Gelenek:* kilisede soru sormak serbest: Okuyan'a herkes soru yazabilir, sorular bir taşa çakılır
  (**Soru Taşı**). Taşın dolması iyi sayılır.
- *Kıtlık:* şarap ve kumaş var, ekmek yok. Şarap Caramine'nin buğdayıyla takas ediliyor; anlaşma bozulursa
  Belvanor bir kış dayanmaz.

**Ilsande** — ipek şehri.
- *Kalp:* ipek loncası özgürlüğünü imparatorluktan satın aldı. Şehri prens yönetir ama ipek loncasına
  danışmadan karar vermez.
- *Gelenek:* dut ağacı kesilmez; kesenin eli tarlada bir gün bağlanır. İpek böceği evlerinin kapısı sessizce
  açılır.
- *Kıtlık:* **ipek yenmez.** Dut tarlası mı buğday tarlası mı kavgası Caramine'yle savaşın asıl sebebi.

**Caramine** — Vadi'nin güneydeki tahıl ambarı.
- *Kalp:* geçimi buğday ve şarap. Herkes Caramine'nin buğdayını istiyor: bu yüzden hem müttefiki (Belvanor) hem
  düşmanı (Ilsande) var.
- *Gelenek:* hasat şenliği kaldırıldı; yerine **sayım** yapılıyor. Ambarın kapısında her çuval sayılırken
  herkes susar.
- *Kıtlık:* buğday var ama kalmıyor: yarısı Belvanor'a, kalanı Ilsande'nin yaktığı tarlaların yerine.
  Caramineli tok ama korkulu.

**Liraven** — Vadi'nin batısındaki bataklık prensliği (Sisli Saz).
- *Kalp:* prensleri savaşlardan bataklığa kaçtı ve geri çıkmadı. Balık ve iksir çıkar. Masalı: bataklık prensi
  suyun altında ikinci bir şehir yönetir; sesini sisli sabahlarda duyarsın.
- *Gelenek:* bataklıkta ölen **suya bırakılır**, gömülmez — yolda ölenin mezarına ad konmaması kuralının
  bataklık hâli.
- *Kıtlık:* bataklık kuruyor, balık azaldı. Samuran ondan ekmek bekliyor, Liraven ona iksir gönderiyor.

**Akavan** — Ondrelle'in batı ucundaki arı kasabası (haritada batı sınırına düşer, siyasette Vadi).
- *Kalp:* geçimi bal ve tahıl; balmumu kilisenin mumu olur. **Orvahel'in bal isteği en çok Akavan'dan
  karşılanır.**
- *Gelenek:* kovanlar sınır taşlarının dibine konur; arıyı kızdırmamak için sınırda kavga edilmez. Batı
  sınırının tek sessiz parçası burası.
- *Kıtlık:* Ondrelle buğdayı savaşına çekiyor; Akavan'a bal kalıyor. **Bal ekmek değil:** çocuklar balla
  doyuyor, dişleri çürüyor.

**Samuran** — Liraven'e bağlı bataklık kasabası; şifacıların yeri.
- *Kalp:* bataklıkta yaşanır çünkü **bataklık açlığı en son hisseden yerdir**: balık, kurbağa, saz kökü.
  Bataklık otlarından iksir yapılır. Masalı: bataklığın dibinde imparatorluk yolu devam ediyor; durgun
  gecelerde yolun eski fenerleri suyun altında yanar.
- *Gelenek:* bataklık yolunu bilen rehber olmadan kervan girmez. Rehber parayla değil **iksir payıyla**
  tutulur.
- *Kıtlık:* mülteciler bataklığa sığınıyor; saz kökü bile azaldı. Samuran ekmeği Liraven'den bekliyor, Liraven
  kendi bataklığına bakıyor.

**Duvenmor Kervansarayı** — Vadi'nin kuzey kapısı; savaşta tarafsız tek yer.
- *Kalp:* hiçbir prensin değil: imparatorluk kervansarayı olarak kaldı. Kervansaray Kâtibi işletir; ne
  Septisist ne Yumruk olduğunu söyler. Savaşan prensliklerin elçileri burada buluşur. İpek burada da üretilir.
- *Gelenek:* içinde **kılıç çekilmez**; çeken bir daha giremez. Tarafsızlık yeminini Kâtip her yeni elçiye
  yüksek sesle okutur.
- *Kıtlık:* tarafsızlık ekmekle ödeniyor: iki taraf da kervansarayı beslerse tarafsız kalır. Biri vazgeçerse
  Duvenmor o tarafa düşer.

### 10.9 Avuçiçi (Orvahel)

**[Yazar, onaylandı T2]** Bölgenin adı **Avuçiçi** (El'in avucunun içi; açık el sembolüyle aynı imge).
**El kilisesinin baş şehri** Orvahel orada. Başında **Birinci Okuyucu V. Leon** var; imparatorluk dili
konuşulur, kutsal metin de bu dildedir.

- **Yalnızca Septisizm:** başka hiçbir dinî görüş bu topraklarda barınamaz. Başka dinden tüccarlar şehre
  sokulmaz.
- **Kervan girerken:** bölgede inançsızların idam edildiği bilinir. Yolcu kafileleri **bineklerine,
  vagonlarına ya da kendilerine zil takarak** ilerlemek zorundadır ki geldikleri bilinsin. Takmayan, izinsiz
  giren bir kâfir sayılıp olduğu yerde öldürülür. Bu sıkı önlemler yüzünden **çok güvenli bir bölgedir**:
  hiçbir yağma ya da saldırı haberi gelmez.
- **Ordu:** bütün kâfir şehirlerle düşmandır ama askerî gücü kendini korumaya yetecek kadardır; bölgesi dışında
  saldırgan değildir. Askerî yapısı dinî kültür temellidir; her asker El'in Kitabı'nı göğsüne bağlı, görünür
  biçimde taşır.
- **Asla affetmediği:** dinine hakaret ve saygısızlık.
- **Dört kuleli tapınak:** eski kilise inancının kıtadaki en büyük ve güçlü tapınağı, kıtanın en kutsal yeri.
  Dört kule, dört bir yanı gören ve saran muazzam bir dengeyi ve gücü temsil eder. **[Yazar, T7]** Eski
  başkentin yanmadan kalan tek yapısıdır; Orvahel onun çevresine kuruldu — **şehir genç, tapınak eski.**
- **Talep ve üretim [Yazar, Ç5]:** kervandan sürekli **gıda, kâğıt, tekstil** ve **bal** ister (Akavan'ın
  balmumu, mum); kendisi **iksir** üretir (manastır şifahaneleri). Kâğıt oyunda yeni bir maldır.
- **[Yazar, Ç14] İnançsızın kuralları:**
  - Suç işleyen inançsız **Kefaret Darağacı**'nda (Orvahel'in doğusu) asılır.
  - İnançsız şehre giremez. İnançsız tüccar ticaretini şehir girişinde, **ticaret loncasının aracıları**
    üzerinden, fazladan komisyon ödeyerek yapar.
  - Şehirde görülen inançsızın, ya da inançlı rolü yapıp yakalanan inançsızın **eli kesilir**: *"El'e inanmayan
    El'i taşıyamaz."* Eli kesilen kişi bunu oyunda yaşar: eli görünmez, iki elle yapılan işi yapamaz.
  - [Karar] Aracıların komisyonu loncanın Orvahel'deki en kârlı işidir; Septisist kâtipler aracıyı "El'in kapı
    eşiği" diye anar, inançsız tüccar ona "avuç" der.
  - [Karar] **Yumruk'tan olan biri inançsız değil, sapkındır** ve bu daha kötüdür: inançsız El'i bilmez, sapkın
    bilir ve bozar. Yumruk'tan bir kervan kapıda malını satar ve gönderilir; Kitap taşıyorsa **Kitap'ı elinden
    alınır** (eli değil, çünkü El'e inanır).
- **[Yazar, T10] İlk Sayfa Manastırı** (Orvahel'in güneyi): Okuyucular orada yetişir. [Karar, T45] Adı
  mezheplerin ayrılığından eskidir — Kitap'ın ilk sayfası orada yazıldı, öyle bilinir. Septisistler için
  manastır ilk sayfanın üstüne yazılmış bütün satırların bekçisidir; Yumruk ise adını kendi davasının kanıtı
  sayar: *"İlk sayfa oradaysa, öbür sayfalar sonradan gelmiştir."* Bir Yumruk vaizinin manastırın kapısına
  dokunması Avuçiçi'de hakaret sayılır.
- **[Yazar, onaylandı T16] İki Bayrak Kulesi** baronluk ile Avuçiçi'nin sınırıdır.
- **[Yazar, onaylandı T27]** Zil, Avuçiçi'ye giden her yolun başında satılır (Ezmerak, Vorgat, Seyvan); zil
  sesi Orvahel yolunun sesidir. [Karar] Küçük, tunç, ağzı geniş bir zil; tek ve kısa bir ses çıkarır, yürüyüşle
  çalar. Vorgat'ta dökülür, Orvahel kapısında kutsanır. **İnanmayan da takar: zil inancı değil geldiğini
  söyler.**
- **[Yazar, onaylandı T8] Mühür Savaşı Ovası** (Orvahel'in kuzeybatısı) büyük savaşın son meydanıdır.

**Orvahel** — El kilisesinin baş şehri.
- *Kalp:* kervan önce pusun içinden dört kuleyi görür, sonra zil sesini duyar. Doğu yolundan geliyorsa Kefaret
  Darağacı'nın altından geçer. Kapıda Kitap'ı göğsüne bağlamış askerler durur.
- *Gelenek:* yukarıdaki inançsız kuralları; zil; kapıda GG'nin yeniden damgalanması (§13.1).
- *Kıtlık:* kıtlığı en az hisseden şehir — Vaelghard fonluyor. Komşuların öfkesi bu yüzden Orvahel'e de
  yöneliyor.

### 10.10 Ors (güneybatı kıyısı)

**Ors** bölgesinde tek bir büyük şehir var: **Orsolune**. Yerlisi kendine **Orsian** der. Bölge, şehir ve güney
kıyısının **Ors sıradağları** aynı kökten gelir. **Seyvan Orsolune'ye bağlıdır.**

- **Yönetim:** **Orsolune Konseyi**: ticaret ağırlıklı, oligarşik (§9.2).
- **Mirsana** Ors'un parçasında durur ama bağımsız başka bir ticaret şehir devletidir.
- **İnanç:** Yumruk baskın. Gizli yaşayan inanç yoktur; azınlıklarla baskın gruplar arasında yönetimin
  kontrolünde, radikal olmayan bir çatışma vardır.
- **Kervan girerken:** paranın kokusunu alır. Her karar paradır, her nefes bir fırsat ve risktir. Çok hızlı
  yükselinir, çok hızlı düşülür. Tamah edilen tek şey güçtür ve güç parayla sağlanır.
- **Komşular:** Orsolune kimseyle savaşta değil; sağlam küçük bir ordusu ve güçlü kiralık ordu ilişkileri var.
  Kıtadaki pek çok şehirle gelişmiş ilişkileri, ticari anlaşmaları ve borç verdikleri var. Güney şehirleri hem
  ortak hem rakip; küçük entrikalar dışında açık savaş yok.
- **Ahlak:** en çok bir anlaşmaya ya da sözleşmeye uyulmamasına öfkelenir. Para gelecek yerden kaz esirgemez ve
  medenidir; hoşgörünün karşılığı olmayacağını fark edince sessizce uzaklaşır. **Asla izin verilmeyen şey
  dolandırıcılıktır:** sistem bir kere kirlenirse bir daha düzelmez. *Ya kitabına göre olur, ya da kitapta bir
  açık bulunur.*
- Tüccar Loncası'nın merkezi bugün Orsolune'dedir. **[Yazar, onaylandı T24]** Lonca güneye taşınınca Orsian
  sözleşme ahlakı kıtaya yayıldı: kurucunun loncaya borcu, kontrat cezaları ve itibar sistemi bu ahlakın
  oyundaki yüzüdür — **söz bozan kervanın adı her şehirde aynı defterde yazar.**
- **[Yazar, onaylandı T17] Kiralık Kılıçlar Ovası** (Mirsana yakını): Orsolune'nin paralı askerlerinin bir
  zaman sözleşmeyi bozduğu, Orsianların bunu hiç unutmadığı yer.
- [Karar] Orsolune çöküşte **imparatorluğun alacaklarını satın aldı** ve bankere dönüştü (§4.1).

**Orsolune** — kıtanın bankeri; kuzeyden gelen için borcun sahibi.
- *Kalp:* **Konsey Evi** ile **Lonca Evi**; ikisi aynı meydanda yüz yüze. Raviellon gemileri buradan kalkar.
- *Gelenek:* **el sıkışılmaz, imza atılır.** Sözleşme yazılmadan su bile satılmaz; yazılı söz bozulursa adın
  her şehirde aynı defterde yazar.
- *Kıtlık:* Orsolune aç değil, **açlığı satın alıyor**: buğdayı borçla veriyor. Kıtlık uzadıkça Orsolune
  büyüyor; kuzeyin öfkesi buna.

**Mirsana** — üç inancın tek pazarı; bağımsız şehir devleti, yedi tüccar evi sırayla yönetir.
- *Kalp:* baharat denizden Orsolune ve Zelmarin üzerinden gelir; Mirsana onu yerli kuru otlarla karıştırır ve
  kendi harmanı diye satar. Pazarın kuralı: **kimse kimin kilisesine gittiğini sormaz.** Günlük işi **Terazi**
  yürütür (§9.2).
- *Gelenek:* pazar günü üç inancın duası **aynı saatte** okunur, sırayla değil. Kim daha yüksek okuyacak diye
  bir kez kavga çıktı; o günden beri kimse yüksek okumuyor.
- *Kıtlık:* baharat çok, ekmek az: zengin baharat alıyor, fakir ekmek için kavga ediyor. Mirsana'da açlık bir
  inanç kavgası gibi görünüyor ama değil.

**Seyvan Kervansarayı** — altı yolun kavşağı; güneyden Avuçiçi'ne gidenin zil aldığı yer. Orsolune'ye bağlı.
- *Kalp:* kavşakta altı yolun her biri bir taşla işaretli; taşların üstünde gidilen yerin adı ve **bugünkü
  bedeli** yazar.
- *Gelenek:* Avuçiçi'ne giden zilini burada alır. Zilsiz bir kervan Seyvan'dan kuzeye çıkarsa kâtip onu
  uyarır — **bir kez**.
- *Kıtlık:* baharat ve mücevher var, buğday ve şarap yok. Kavşakta buğday taşıyan kervan "önce Seyvan'a satsın"
  diye bekletiliyor.

### 10.11 Gelgit Kıyısı (güneydoğu kıyısı)

[Karar, T39] Bölgenin adı **Gelgit Kıyısı**; haritadaki yerleri Zelmarin, **Vesperra Bağları**, **Gelgit
Taşları**. İlk haritada Ors'la aynı adla eşlenmişti: kıyı kültürü olarak benzer, siyaseten ayrı.

- **[Yazar]** **Zelmarin** Ors'a ait değildir: kendi kültürüyle ona benzeyen kültürlerin arasında bir şehirdir.
  Konseyle yönetilir; Orsolune ile ticaret anlaşması var. Septisizm ağırlıkta ama karışık. Raviellon'a ve uzak
  kıtalara giden gemiler Orsolune'nin yanında Zelmarin'den de kalkar.
- [Karar, T42] **Gelgit Taşları** Denizin İlk Gözyaşı'nın kıyıdaki yeridir (§8.4); Zelmarin'in "karışık" inancı
  buradan gelir.
- [Karar, T42] **Vesperra Bağları** kıyının şarabıdır; Zelmarin'in Orsolune'ye sattığı başlıca maldır.
  **Kıtlıkta bağ sökülüp yerine buğday ekilsin mi diye konsey ikiye bölünmüştür.**
- [Karar, T42] Zelmarin ile Karaocak komşudur: Vorgat'ın cevheri gemiye Zelmarin'den biner.

**Zelmarin** — Gelgit Kıyısı'nın liman şehri; denizden gelenle kilise arasında.
- *Kalp:* rıhtımda Raviellon gemileri, Vesperra şarabı ve Vorgat cevheri. Konsey kaptanlar ve bağ
  sahiplerinden oluşur.
- *Gelenek:* gemi kalkmadan önce kaptan Gelgit Taşları'na tuz ve bir dua bırakır; **sonra** kiliseye gider.
  İkisini de yapmayan kaptanla kimse yola çıkmaz.
- *Kıtlık:* limanda buğday gemisi bekleniyor; gelmezse bağlar sökülecek. Konsey ikiye bölündü.

---

## 11. Adı konmuş yerler (yol kenarının hafızası)

Haritada adı olan ama yerleşim olmayan yerler. Hepsi [Karar]; her biri bir olay kartı, bir durak ya da bir
NPC'nin ağzında bir cümle olarak kullanılabilir. **[Yazar]** Haritada adı olan her yer oynanabilir olmalı
(§16.2/1).

### 11.1 Yıkıntılar

| yer | ne |
|---|---|
| **Deli Kral Sarayı Yıkıntısı** (Vastrevar'ın doğusu) | Son imparatorun yazlık sarayı; büyücüler avlusunda yakıldı (§4.2). Halk yaklaşmaz: geceleri avluda kül kalktığı anlatılır. Vaelghard sarayı ne onarır ne yıkar. |
| **Velkrun Yıkıntısı** (Taşkök) | İmparatorluğun kereste ambarı; parçalanmada yakıldı. "Odun satılır, orman satılmaz" kuralının doğduğu yer (§10.6). |
| **Eski Darphane Yıkıntısı** (güney) | İmparatorluğun darphanesi; GG burada basıldı. Çöküşte kalıplar Orsolune'ye kaçırıldı. |
| **Sargalak Yıkıntısı** (bozkırın ortası) | İmparatorluk karakolu; obalar ilk akında yaktı. Taşları yurt ocağı olarak taşındı. Göçebe savaşının başladığı yer (§4.3). |
| **Tozkapı Yıkıntısı** | Kadimlerden bir kapı: bir duvarın ortasında, iki tarafı da açık. İçinden geçen tozlanır; toz yıkanınca çıkmaz derler. Taşları doğudan taşınmıştır ve kimse nasıl olduğunu bilmez (§1.2/4). |
| **Solgun Bahçe Yıkıntısı** (Vadi) | Bir prensin bahçesi; kıtlığın ilk yılında ilk solan yer. Sebebi büyü değil: bahçıvanları İllet'ten öldü ve kimse sulamadı. Vadi bunu bir işaret sayar. |
| **Hallecort Yıkıntısı** (kuzey kıyısı) | İmparatorluk balıkçı durağı; buzul yaklaşınca terk edildi. |

### 11.2 Taşlar ve kadim izler

| yer | ne |
|---|---|
| **Yıldızölçer Taşları** (Ors kıyısı) | Kadimlerden; gökyüzünü ölçer, kimse nasıl olduğunu bilmez. Ors'un kıyı takvimi bu taşlardan okunan güneşle başlar. Taşlar doğudan taşınmıştır. |
| **Bahçıvan Taşları** (Vadi) | Bir eski inancın taşları; çevresi kıtlıkta bile yeşil. Bahçıvan kimdi bilinmez; köylüler taşların dibine tohum gömer, kilise göz yumar. |
| **Altıkuşak Taşları** (batı kıyısı) | Altı halka taş; obaların dokuz boydan önceki altı eski kuşağının mezar yeri. Göçebeler oraya göç etmez, yalnızca uzaktan selam verir. |
| **İlk Nefes Taşları** (Saldrek'in güneydoğusu) | Dağlıların Kartalın Nefesi sınavının başladığı yer **[Yazar, onaylandı T18]**. |
| **Gelgit Taşları** (Gelgit Kıyısı) | Denizin İlk Gözyaşı'nın kıyıdaki yeri; gelgit örtüp açtıkça denizin ağladığı söylenir. |
| **Mühür Savaşı Ovası** (Orvahel'in kuzeybatısı) | Büyük savaşın son meydanı **[Yazar, onaylandı T8]**. |
| **Bölünmüş Sancak Ovası** (batı sınırı) | Tolvarin ile Kirsavel'in ayrıldığı yer **[Yazar, onaylandı T15]**. |
| **Kiralık Kılıçlar Ovası** (Mirsana yakını) | Orsolune'nin paralı askerlerinin sözleşmeyi bozduğu yer **[Yazar, onaylandı T17]**. |
| **Kırık Mızrak Çayırı** | Vaelghard ile Ezmerak'ın Kanlı Baron zamanında savaştığı yer; Baron kazandı ve baronluğun bağımsızlığı orada tanındı. |

### 11.3 Manastırlar

| yer | ne |
|---|---|
| **İlk Sayfa Manastırı** (Orvahel'in güneyi) | Okuyucular orada yetişir; adı iki mezhebin kavgasıdır (§10.9). |
| **Sessiz El Manastırı** (Ayazkaya sınırı) | Septisist; keşişler susma yemini eder, çünkü Kitap'ın eklenen satırlarını ezberler ve yanlış söylemekten korkar. Dağlılar keşişlere dokunmaz. |
| **Açık Kapı Manastırı** | Şifahane. Kapısı açlara ve hastalara açık, mezhebe bakılmaz. Ors'un parası, Septisist kâtiplerin eli: Orsolune bağış verir ve karşılığında borçlarını bağışlatır. |
| **Yamalı Çatı Manastırı** | Yoksul; her onarımda çatıya başka bir kervanın tahtası çakılır. Bekçi Kadın'ın burada bir gece kaldığı anlatılır. |
| **Taşsoluk Manastırı** | Dağın İlk Nefesi'nin eski yeri; kilise devraldı. Duvarlarındaki delikler rüzgârda soluk gibi ses çıkarır. Dağlılar burayı hâlâ kendi yerleri sayar. |

### 11.4 Darağaçları

| yer | ne |
|---|---|
| **Kefaret Darağacı** (Orvahel'in doğusu) | Suç işleyen inançsız orada asılır **[Yazar, Ç14]**. |
| **Kızıl Ferman Darağacı** (Vaelghard) | Mühürsüz buğday saklayan köylü orada asılır. Kıtlık sürdükçe kullanılıyor. |
| **Dönek Darağacı** (batı sınırı) | Taraf değiştirenlerin asıldığı yer **[Yazar, onaylandı T15]**. |
| **Sarmaşıklı Darağacı** (Belvanor yakını) | Artık kullanılmıyor: Belvanor Yumruk'a geçince kilise mahkemesi kapandı ve sarmaşık sardı. Sarmaşığı kesmek uğursuz sayılır. |
| **Kuru Halat Darağacı** (Gelgit Kıyısı) | Korsanların asıldığı yer. Halatı kuru kalır, çünkü deniz rüzgârı nemi tutmaz; kurumayan halat "masum asıldı" demek. |

### 11.5 Mezarlıklar

| yer | ne |
|---|---|
| **Kör Kazmalar Mezarlığı** (Karaocak) | Ocakta gözünü kaybeden madencilerin yeri; kazmasıyla gömülürler (§10.7). |
| **Yabancılar Mezarlığı** (Vadi) | Şehirde ölen ama şehre ait olmayanların yeri (yolda ölen değil). Taşlarına ad yazılır, şehir adı yazılmaz. |
| **Sancaksız Mezarlık** | Büyük savaşın kimsesizleri: bayraksız askerler, kaçaklar. Vaelghard onları gömdü ama sancak dikmedi. |
| **Leylak Mezarlığı** (Vadi) | Bir prensin İllet'te ölen ailesinin mezarlığı; her mezara bir leylak dikti. Leylaklar çoğaldı, şimdi koca bir koru. |
| **Tuzlu Çardak Mezarlığı** (kıyı) | Denizde ölenlerin anıldığı yer; mezarlar boş. Çardağa tuz asılır. |

### 11.6 Batıklar, kuleler, fenerler

| yer | ne |
|---|---|
| **Sessiz Kadırga Batığı** | Raviellon'dan gelen bir büyücü gemisi; mürettebatı sağ çıktı ve kimseyle konuşmadan yürüyüp gitti. Gemi hâlâ ses çıkarmaz, dalga bile vurmaz. |
| **Kanlı Direk Batığı** | Dağlı korsanların gemisi; Vaelghard batırdı. Direğe bağlanan kaptan ölmeden önce gemisini kendi kanıyla adlandırdı. |
| **Öksüz Göz Kulesi** (Karaocak–Gelgit arası) | Gözcü kulesi; bekçisi öldü, yerine kimse gelmedi. Kervanlar gece orada bir ışık görür. |
| **İki Bayrak Kulesi** | Baronluk ile Avuçiçi'nin sınırı **[Yazar, onaylandı T16]**. |
| **Grauth Feneri** (kuzeyin ucu) | Kuzey denizine giden yok; kime yol gösterdiği bilinmez. Yakan bir aile var, kuşaklardır; Vaelghard onlara buğday gönderir ve sormaz. |

[Karar] **Yarımköy** (Akavan ile Tolvarin arası): mülteci köyü. Adı yarım, çünkü yarısı her yıl gidiyor. Haritaya
eklenebilir. Mülteciler en çok Vadi'nin prens savaşlarından ve obaların akınlarından kaçar; batı sınırına
(Tolvarin, Kirsavel) ve bataklıklara (Samuran, Liraven) sığınırlar.

---

## 12. Yol: töre, tehlike, ad

### 12.1 Yolun töresi [Yazar, defter IV]

**Payını al, yolcuyu bırak.** Her şeyi almak kervanı öldürmek demektir, çünkü yüksüz kervan zaten ölür. Bu
yüzden *"ya paran ya canın — her şeyi bırak git"* bir çizgiyi aşmaktır ve **herkes bunu bilir.** Nadir olmalı
(yol kartlarının yüzde beşinden azı) ve **kim yaptıysa adı kalmalı**: böyle bir soygundan sonra o reisin adı
deftere geçer, bir daha karşına çıkınca tanınır.

- **Haydut neden mal istiyor:** çünkü parayla yiyecek alınamıyor. **Kıtlıkta altın bir söz, un bir gerçektir.**
  İki ayrı aile var ve ikisi de yolda: **eski haydut** hâlâ para ister (alışkanlık, ve şehirde harcayacağını
  sanır), **aç haydut** mal ister.
- **Kervan neden muhafız tutmuyor:** tutuyor — kervanın kendisi odur. Büyük bir muhafız bölüğü tutmak bir
  bölüğü beslemek demek ve kıtlıkta kimse bir bölüğü besleyemez. Zaten kaçakların çoğu öyle dağılmış
  bölüklerden. Kervan **az kişiyle, hızlı ve göze batmadan** gitmeye çalışır.

### 12.2 Asker kaçakları [Yazar, defter IV]

- **Kimden kaçıyorlar:** çoğu **Vadi'nin paralı bölüklerinden** (ödenmeyen maaş, dağılan bölük, kaçan
  komutan), bir kısmı **Vaelghard'ın inen birliklerinden** geri dönmemiş olanlar. Ortak yanları: silahları var,
  ekmekleri yok, geri dönecek yerleri yok.
- **Neden kaçıyorlar:** yalnız açlık değil. Ordu sana kötü şeyler yaptırır — hastaları öldürtür, karşı devletin
  malını yaktırır, masum insanları öldürtür — boş zamanında tarlada ve değirmende çalıştırır, ve ilk fırsatta
  ülken için ölmeni bekler. Herkes bunu kaldıramaz. **Ama kaçanların hepsi iyi yürekli de değil:** düzeni
  benimseyemeyen, başka problemleri olan, kendi birliğini ve çetesini kurmak isteyen yetenekli ama kötü
  insanlar da aralarında. Dışarıda yemek bulmak da daha zor; **kaçak olmak bir karar değil, bir sonuç.**
- **Nerede yoklar:** **Gokyurt'ta** bozkırda saklanacak yer yok ve otlak obalara ait — silahlı yabancı grup
  görülür görülmez atlılar üstüne gider; kaçak bozkıra girmez çünkü bozkırda kaçak yaşayamaz. **Vaelghard
  şehirleri civarında** krallık hâlâ işliyor ve kaçağı kendi kapısında asıyor; kaçaklar kuzeyden uzaklaşır,
  sınırın güneyinde yoğunlaşır. [Oyun] Bu iki yerde kaçak kartı çekilmez, haydut kartı normal ağırlıkta.
- **Yakalanırsa:** Vaelghard'da asılır. Vadi'de kimse uğraşmaz; bölük onu bulursa döver ve geri alır, çünkü
  **adam lazım**.
- **İhbar:** kervan ihbar edebilir, ama **ihbarın itibarla ilgili bir sonucu yoktur** — ne kazandırır ne
  kaybettirir. Sebebi: kaçağın iyisi de var kötüsü de, ve kimse hangisini ele verdiğini bilemez.
- **Nasıl görünürler: yarım üniforma.** Bölüğün rengi solmuş bir kuşak, sökülmüş bir nişan, hâlâ iyi bakılmış
  bir kılıç ve paramparça bir ayakkabı. **Asker gibi dururlar, dilenci gibi kokarlar.** Onları haydutlardan
  ayıran şey **düzen alışkanlığı**: sıraya girerler, biri konuşur, ötekiler susar.

### 12.3 Yolun ahlakı [Yazar, defter IV]

- **El açmak** kervanbaşılığın bittiğinin ilanıdır. Kervanbaşı pazarlık eder, borç alır, mal satar — el açmaz.
  Açtıysa kervanı yoktur, yalnızca arabaları vardır. [Oyun] İtibarı doğrudan düşürür ve deftere **yalnız ilk
  kez** yazılır: ikinci kez kimsenin umurunda değildir. Meyhaneci verir, çünkü meyhaneci herkese verir — ama
  bir daha sana oda fiyatını farklı söyler.
- **Dolandırmak** hırsızlıktan hafif, yalandan ağırdır. Yolda yalan söylemek olağan (herkes malını över), ama
  **bir yolcuyu** dolandırmak yolun töresini kırar: yolcu yolcuya güvenmek zorundadır. Yakalananın cezası
  dövülmek değil **dışarı atılmak**: meyhane kapısı o gün kapanır, ve anlatılır. Tüccar dolandırmak ayrı iş —
  orada herkes birbirini dolandırmaya çalışıyor sayılır.
- **Eksik el** pazar meydanının kenarından tutulur; iş bekleyenler orada durur. Lonca değil — lonca kalifiye
  adam verir ve pahalıdır, arabacı meydanda bulunur. Kıtlıkta meydan kalabalık ama **sağlam adam az**: fiyatın
  düşük olmamasının sebebi bu, aç bir adamı işe almak da bir risk.
- **Dağılma:** aç kalan tayfanın kervanı bırakıp gitmesini töre haklı bulur, **ama kervanbaşının adını
  lekeler.** *"Adamını aç bıraktı"* yolun en ağır sözlerinden; el tutma fiyatının her kayıpla yükselmesi
  bundan. Gidenler en yakın şehre gider ve çoğu oraya varamaz; bazıları **kaçakların yanına** katılır — yolda
  karşına çıkan silahlı grubun içinde bir zamanlar senin arabacın olabilir (görev Y-E13).

### 12.4 Kervanın adı [Yazar, defter IV]

**Ad bir sicildir.** Loncalar kervan adlarını tutar; teslim edilen yük ve ödenen borç o ada yazılır.
Kervanbaşı ölünce ad kalır, sicil kalır — oyunun soy sistemi budur. **Tanınma mesafelidir:** kendi bölgende
adın bilinir, komşu bölgede duyulmuştur, uzakta hiçbir şey ifade etmez. Bir ad **düşebilir**: borç ödenmez, yük
teslim edilmez, adam aç bırakılırsa lonca sicili kapatır ve yeni bir adla başlamak gerekir.

[Karar] **Ad nasıl konur:** kurucunun ilk yükünden ya da ilk yolundan. Ad bir kez Orsolune'nin lonca defterine
yazılınca değişmez. **Kervan adını taşımaz, ad kervanı taşır.**

### 12.5 Yolun düşmanları [Karar, T48]

Kıtlıkta yolu kesenler her bölgenin kendi aç insanlarıdır; kimin olduğu oranın tarihinden gelir. Oyunda
`EnemyCatalog.REGIONAL_BANDITS`.

| bölge | ön saf | arka saf / reis | neden |
|---|---|---|---|
| Büyük Vadi | Prens Kaçağı | Hasat Yağmacısı | bitmeyen prens savaşları, hasadı yanan köylü |
| Vaelghard | Garnizon Kaçağı | Silahlı Eşkıya | çember içindeki krallığın kaçak askeri; çeliği iyi |
| Ezmerak ve batı sınırı | Sınır Çapulcusu | Aç Sürgün (tehlike yükselince) | Tolvarin–Kirsavel kavgası, savaş mültecileri |
| Ayazkaya | Dağ Haydutu | Bedel Adamı (reis) | bedel kültürü, yolu tutan haydut kralları |
| Taşkök | Maden Kaçağı | Dağ Haydutu | kuzeybatı madenlerinden kaçanlar |
| Ors ve Gelgit Kıyısı | Kıyı Korsanı | Tuz Kaçakçısı | kıyı, mühürsüz tuz |
| Avuçiçi | Elsiz Sürgün | Garnizon Kaçağı | eli kesilip sürülenler; garantör Vaelghard'ın kaçakları |
| Gokyurt | Oba Yağmacısı | Bozkır Akıncısı | otlağı kuruyan obalar, atlı okçular |

---

## 13. Gündelik hayat

### 13.1 Para ve borç

- **GG (Gümüş Gard)** [Oyun, Yazar]: imparatorluğun parası, eski başkentin adını taşır.
  [Karar] Eski Darphane'nin kalıplarıyla bugün **Orsolune basıyor**; her yerde geçer ama **Orvahel GG'yi kapıda
  kendi mührüyle yeniden damgalar** — kutsal kentte yalnız damgalı GG geçer ve damga bir komisyondur.
- [Karar] Kıtlıkta GG'nin sorunu şudur: **geçer ama doyurmaz.** Köyde bir çuval un bir kese GG'den değerlidir;
  şehirde tam tersi. Kervanın bütün ekonomisi bu makasta yaşar.
- **Borç:** loncanın defteri her şehirde aynıdır; ödemeyen **Kara Defter**'e geçer (§8.7).

### 13.2 Mallar [Oyun]

Buğday, kumaş, demir, iksir, kürk, baharat, bal, ipek, mücevher, balık, şarap; kaçak **mühürsüz tuz**; nadir
**eski mühür**; yeni mal **kâğıt** (Orvahel).

- **İpek [Yazar]:** Ilsande ve Duvenmor standart, iyi bir ipek üretir. Deniz ötesinden gelen ipek daha iyidir,
  özel bir melez ipek böceğinden üretilir.
- **Baharat [Yazar]:** çok nadir lüks eşyalar, özel ipekler ve özellikle baharat uzak kıtalardan ya da
  Raviellon'dan liman kentlerine gelir. Orbeyan'ın baharatı denizden değil bozkırdandır (**bozkır baharı**,
  Ç6).
- **Çelik ve tuz:** Kazrun çeliği ve Saldrek tuzu Ayazkaya'dan; mühürsüz tuz yasak ve ucuz (§10.3).
- **Eski mühür:** Mühür Savaşı Ovası'nda düşen imparatorluk mühürlerinden biri (§4.3).
- [Karar] **Kıtlıkta değer sırası:** un > tuz > demir > kumaş > iksir > şarap > baharat > mücevher. Bir
  haydutun ne istediği, bir şehrin neyi esirgediği ve bir NPC'nin neye imrendiği bu sıradan okunur.

### 13.3 Yemek, sofra, soğuk

- [Karar] Günlük yemek: arpa ya da darı lapası, kuru soğan, tuzlanmış balık ya da et (varsa), kervansarayda
  ekmek. **Buğday ekmeği bir ödüldür**, gündelik değil. Şarap güneyde, kımız bozkırda, kaynatılmış ot çayı her
  yerde.
- [Karar] Sofra bir töredir: kervanda **önce hayvanlar** yemlenir, sonra insanlar yer (Kirsavel'de tersi
  düşünülemez bile). Yemek dağıtan kişi en son yer; en son yiyen kişi kervanda en çok saygı görür.
- **Tek sıcak kaynak kuralı [Yazar]:** dünyada yalnızca **ateş** sıcak renklidir (sanat kuralı
  `kurallar-sanat`). Bunun lore karşılığı: kıtlıkta sıcaklık bir servettir; bir ocağın başına oturmak için
  ödeme yapılır, kervansaraylarda "ateş hakkı" ayrı satılır.

### 13.4 Adlar

**Yer, güç ve kurum adları** bu belgedeki adlardır; yeni ad koyarken §0.2/2 geçerlidir (uydurma, ASCII,
birbirine benzemeyen).

**Kişi adları** oyunda kültür havuzlarından gelir (`CultureCatalog`, her kültürde 16 ad): göçebe, Vadi, dağ
kabilesi, liman, balıkçı. [Karar] Yeni bir NPC adı gerektiğinde **o havuzun tadına** uyulur ve havuza
eklenebilir. Hanedan ve kurum adlarında ise bu belgenin adları esastır: Raegmund, Daveric, Aldemar, Valdric,
Lenart, Vasko, Septimar, Leon, Kaytaş, Kutlay.

[Karar] **Unvanlar nasıl söylenir:** Vaelghard'da tam unvanla ("Kral Raegmund'un kâtibi"), Vadi'de kısaca
("prensin adamı"), Gokyurt'ta akrabalıkla ("Arsalkan'ın beyinin oğlu"), Ayazkaya'da kabileyle ("Demirbalta'dan"),
Ors'ta defterle ("üçüncü sandalye"), Avuçiçi'nde mertebeyle ("Kâtip").

### 13.5 Kervan hayatı [Oyun]

Tayfa ≠ parti; görevler ve savaş sınıfları; huylar; kırgınlık unutulmaz. **Ölümün kapıları savaş, açlık ve
vagon kaybıdır; olaylar öldürmez.** Dünyayı sallayan olaylar: bölgesel savaş, İllet, ticaret fuarı, haydut
haracı. Ton: aşınma, yas, hafıza.

---

## 14. Söyleyiş: kim nasıl konuşur

[Karar] Bir repliği doğru kılan şey bilgi değil **ses**tir. Her halk için: ne üzerine yemin eder, neyi övgü
sayar, neye küfreder, bir yabancıya nasıl hitap eder.

| halk | yemini | övgüsü | küfrü | yabancıya |
|---|---|---|---|---|
| **Vaelghard** | "kayda geçsin" | "düzgün adam" | "kayıtsız" | unvanla, soğuk, tam cümle |
| **Büyük Vadi** | "defterim şahit" | "işini bilir" | "beleşçi" | fiyatla; adını sormadan |
| **Gokyurt** | "Baikhan'ın altında" | "atını tanır" | "otlak bilmez" | misafir sayar, hediye bekler |
| **Ayazkaya** | "taş üstüne" | "ağır vurur" | "hafif" | ölçerek; az sözcükle |
| **Taşkök / Karaocak** | "ocak sönsün" | "eli iyi" | "acele" | sabırla, gülerek |
| **Ors / liman** | "imzam var" | "sözü senet" | "dolandırıcı" | koşullu, nazik, mesafeli |
| **Balıkçı kasabası** | "deniz duysun" | "ağı sağlam" | "karada kalmış" | hava durumuyla başlar |
| **Avuçiçi (Septisist)** | "sayfa açık" | "satırına uyar" | "sapkın" | zil sesine bakar, ada bakmaz |
| **Yumruk** | "ilk sayfa üstüne" | "soru sorar" | "ekleyici" | sorarak, eşit |
| **Tolvarin** | "toprak adına" | "sabanı düz sürer" | "çiğneyici" | kapıda yıkanmanı bekler |
| **Kirsavel** | "sürü adına" | "hayvanı besli" | "kasap" | hayvanını sayar |
| **Kovrast / Kemersal** | "orman duysun" | "izinsiz kesmez" | "baltacı" | yol gösterir, konuşmaz |

[Karar] **Aynı haberi her kültür farklı okur** [Oyun]: bu kuralın oyundaki ilk örneği haber kartlarıdır, ama
her metinde geçerlidir. Örnek — "Vaelghard Vadi'ye indi":

- Vaelghard kâtibi: *"Değirmenler kayda alındı."*
- Vadili prens adamı: *"Kuzey ambara girdi, adına düzen dedi."*
- Göçebe: *"Kendi otlağını bitirdi, komşusuna baktı."*
- Orsian: *"Buğdayın fiyatı bir hafta içinde değişir; kim borçlanacak diye bekliyoruz."*
- Septisist kâtip: *"Sayfa açık; düzen El'in satırıdır."*
- Yumruk Okuyanı: *"Kim yazdı bu satırı? Sor."*

---

## 15. Metin üretim kılavuzu

[Karar] Her kaynak türünün uzunluğu, sesi ve yasağı. **Hiçbiri yazarın sesiyle konuşmaz** (§0.2/1).

| tür | uzunluk | ses | yasak |
|---|---|---|---|
| **NPC sözü (şehir, taverna)** | 1–2 cümle | Konuşma dili; yalnızca kendi bildiğini söyler, yanılabilir. | Dünyayı özetlemek; "bilge anlatıcı" tonu; sayı vermek (fiyat hariç). |
| **Kamp sohbeti / tayfa sözü** | 1 cümle | Yorgun, kişisel; kendi geçmişine değer. | Lore anlatmak. Tayfa dünyayı değil kendini anlatır. |
| **Olay kartı metni** | 2–4 cümle | Şimdiki zaman, ikinci tekil; kervanın gördüğü şey. | Sonucu söylemek; duyguyu adlandırmak ("korktun"). |
| **Seçenek sonucu** | 1–2 cümle | Olanı anlatır, **ad anar** (`EventText` {who}/{town}). | Dersi söylemek, ahlak çıkarmak. |
| **Haber kartı** | 1–2 cümle + kültür okuması | Kulaktan dolma; kaynak belirsiz. | Kesinlik; tarih vermek. |
| **Kitap parçası** | 3–6 cümle | Bir yazarın elinden; kibirli, eksik, taraflı. Hangi şehirde yazıldığı anlaşılır. | Doğru olmak zorunda değil — ve asla tam doğru olmaz. |
| **Yazıt** | 1–2 satır | Kazınmış, kısa, fiilsiz olabilir. Bir kısmı silinmiş. | Tam cümle kurmak; açıklamak. |
| **Mezar taşı** | 1 satır | Yolda: **ad yok**, yalnızca taş. Şehirde: ad ve bir satır. | Yol mezarına ad yazmak (ihlal, §8.5). |
| **Dua** | 2–4 satır | Kendi inancının dilinde; istek değil **saygı** (Baikhan) ya da **okuma** (El). | Tanrının adını söylemek; gerçek dinî formül taklidi. |
| **Türkü / destan** | 4–8 satır | Göçebe: benzetme ve hayvan. Dağlı: kısa, vurgulu. Vadi: alaycı. | Kafiyeyi zorlamak; tarihî doğruluk. |
| **Lonca kaydı** | 1–3 satır | Kuru, sayısal, tarihli; kişiyi yalnızca adla anar. | Duygu. |
| **Çocuk masalı** | 3–5 cümle | Komşu bölgenin yaratığını anlatır (§3.5). | Yaratığı doğrulamak. |
| **İlan panosu / kontrat** | 1–2 satır | Şart ve bedel; ceza satırı mutlaka var. | Belirsizlik. |
| **Defter satırı (oyuncunun)** | 1 satır | Olanı kaydeder, yorumlamaz. Silinmez. | Övgü ya da suçlama. |

**Üç genel kural [Karar]:**

1. **Bir metin bir şey bilmez.** Her kaynağın bilgisi bölgesiyle ve kuşağıyla sınırlı (§2.5, §0.3).
2. **Kıtlık anlatılmaz, görünür.** "Açız" demeyen ama boş tezgâhı, sayılan çuvalı, inmemiş kürkü anan metin
   doğru metindir.
3. **Her metin bir şeyi feda eder.** Kıtlık kartlarında doğru seçenek yoktur (§5.5); bir repliğin de bedeli
   olmalı: söyleyen bir şey kaybeder, saklar ya da itiraf eder.

---

## 16. Karar günlüğü ve açık uçlar

### 16.1 Bu belge nasıl oluştu

- **Soru defteri I** (302 soru): https://claude.ai/artifact/GL3TcJUe1Agerti9VP6JbH — bölge cevapları.
- **Soru defteri II** (262 soru): https://claude.ai/artifact/MfVQJSzrrLb68TwZJSPQdh — 30 onay; mezhepler
  düzeltildi, her harita parçası kendi bölgesi oldu.
- **Soru defteri III** (144 soru): içeriği `tools/lore_defter3_banka.py`'de; 27 yerleşim taslağı ve kalan
  soruların önerili cevapları buradan geldi.
- **Soru defteri IV** (24 soru): https://claude.ai/artifact/DsC1PMXP2y4WnwH9mXgFHR — kıtlığın sebebi (İllet),
  altmış yılın çizgisi, deli kral, takvim, coğrafyanın adları, yolun töresi.
- **2026-11-07:** kullanıcı T49'u onayladı ve kalan bütün önerilerin kararını bana bıraktı
  (*"diğerleri için de sen kendi cevaplarını üret ve lore'a ekle"*). Dört belge bu belgede birleştirildi.

**Kullanıcı tarafından geçersiz kılınan ve bu belgeden silinen satırlar** (bir daha kullanılmaz):
kıtlığın sebebi olarak "uzayan kış" ve "solgunluk"; "kıtlık imparatorluğun son yıllarında başladı";
"deli kral kıtlığı büyücülere yükledi" ve "deli kral son imparatordan önceki imparatordu"; "Baikhan gök,
Gokana toprak"; "Gelgit Kıyısı balıkçıların yurdudur"; "kaçak ihbarı itibar kazandırır/kaybettirir";
"doğuda da göçebeler var"; beş bölümlü senaryo/kampanya sistemi; batı denizlerinin "Uzun Deniz / Sabah Denizi"
adları (kanon: Ağıt Denizi, Gelgit Denizi); Vadi nehrinin "Vael Suyu" adı (kanon: Kemersu);
yol sunaklarının dörde indirilmesi (kanon: oyundaki on sunak kalır).

### 16.2 Oyuna bağlanış (kod işi; her biri ayrı karar)

Kanonun oyunda görünmesi için gereken değişiklikler. Bu belge yalnızca kaydeder; iş listesi `CLAUDE.md` Ana
Hedefler ve `proje_takibi/`.

1. **Haritada adı olan her yer oynanabilir olmalı** [Yazar]. Bugün 27 yerleşim oynanabilir; obalar, kabileler,
   mezralar, manastırlar, kuleler ve harabeler yalnızca harita adı (görev T16-11).
2. **Avuçiçi'ne zil:** zilsiz kervan Orvahel yoluna girerse büyük tehlike ya da bir olay kartı; zil bir eşya ya
   da yol başında bir hazırlık; bölgede yağma yok.
3. **Orvahel kapısı:** Septisizm'den olmayan kervan şehre giremez, malları kapıda satılır; suç işleyen inançsız
   asılır; şehirde görülenin eli kesilir (kalıcı sakatlık, kart açılmadan görünür).
4. **Orvahel'in talebi** gıda, kâğıt, tekstil, bal; üretimi iksir; yeni mal kâğıt.
5. **Vaelghard sınır bürosu:** kayıt, beyan, vergi; teftiş sık, rüşvet işlemez.
6. **Ezmerak:** geçen kervana en az bir öküz değerinde ticaret zorunluluğu; aldatma = düello; Öküz Kâtibi ve
   boynuz fiş.
7. **Gokyurt:** beylere hediye ve izin (tamga); misafirlik bir gün bedava.
8. **Kuzeyde kış:** kuzeye çıkan kasaba yolları kardan kapanır; şehirler arası yollar açık kalır.
9. **Vadi yolları:** kıtlık ve mali zarar katmanı; yozlaşmış görevli ve aç hayvan olayları.
10. **Ayazkaya:** bedel ödenmemiş her yolda tekrar haraç; tanıdık ya da güç yoksa yağma; bedel taşı.
11. **Tılsımlı takılar:** nadir "kusursuz" (yalnızca artı) ve "aşırı" (çok artı, çok eksi) takılar.
12. **Yol sunakları** oyundaki on durak olarak kalır [Yazar, Ç9].
13. **Arınma ve şifa** kültüre göre: kilise, doğa ibadeti ya da şifahane; şifahanede hastalık da iyileşir
    (§8.2).
14. **Kilise ekranı** şehrin mezhebine göre: Septisizm ya da Yumruk.
15. **Kıtlık** (görev Y-C21): kıtayı saran dünya durumu ve haberleri; pazarda kıtlık fiyat katmanı ve satmak
    istemeyen satıcı; ulaştırma odaklı gelir; şehir başına moral/hâl — kervanın getirdiği yük onu düzeltir.
16. **Mühürsüz tuz** Ezmerak'ta ve büyük şehirlerde yasak, mühürlüden ucuz; yasak şehir listesi eklenir.
17. **Ayazkaya'da hüküm sınaması:** meydan okuyan dağa tırmanır, beyin yerleşkesinde düello eder.
18. **Senaryo sistemi yok** (2026-10-31): oyun kervanı ilerletmek ve ek görevlerden oluşur, konforlu final yok.
19. **Dağılan tayfa yolda karşına çıkar** (görev Y-E13, §12.3).
20. [Karar] **Takvimin üç adı** (§2.3) bir belge, bir ilan ya da bir replik nereden geldiğini söylemek için
    kullanılabilir: Vaelghard belgesi "Ferman yılı", lonca kaydı "çöküşten beri", göçebe "acı sudan beri".

### 16.3 Asla söylenmeyecekler

Oyunun hiçbir metni bunları doğrulamaz. Gizem bilgi eksikliği değil, **kasıtlı sessizlik**tir.

1. **Kadim uygarlığın sonu.** [Boş — cevabı kullanıcının] Oyunda hiç söylenmeyecek ama her şey ona bağlanacak.
   Benim duran önerim §1.2/3'teki omurgadır: kendilerine ait olmayan yaşamı almayı denediler. Kullanıcı
   kararını verene kadar hiçbir metin bu konuda ima bile vermez; yalnızca aynı gölge dört ayrı yerde düşer
   (kadimler, deli kral, aşan büyücü, İllet).
2. **Tanrı var mı.** Yok ve var denmez. Gerçekten doğaüstü olaylar çok nadirdir ve onlar da insanın idrak
   edemediği şeylerdir [Yazar].
3. **Bekçi Kadın gerçek mi.** Oyun asla doğrulamaz [Yazar].
4. **Öbürküler ne.** Hakkında hiçbir kaynak yok [Yazar]; oyunda birim yok, yalnızca stres ve moral.
5. **Merigard'ı kim yaktı.** Üç suçlama var, hiçbiri doğrulanmaz (§4.3).
6. **Vebanın hiç bulaşmadığı köylerin sebebi.** Bilinmez [Yazar].
7. **Kadim taşları batıya kim taşıdı.** Hiçbir kaynakta yok (§1.2/4).
8. **Yumruk'un ilk kâtibinin adı.** Yumruk bunu bilerek saklar (§8.1).
9. **Deli kralın hastalığının adı.** Yok; İllet değil, o kadarı biliniyor (§4.2).

### 16.4 Hâlâ kullanıcıya ait olan kararlar

1. **Kadim uygarlığın sonu** (yukarıda).
2. **Kampanya, hikâye ve o hikâyenin diyalogları.** Kullanıcı bunu kendi yazacak (2026-11-07). Bu belge o işin
   zeminidir: dünya, tarih, coğrafya, inanç, ses ve metin türleri hazır.
3. Bu belgedeki herhangi bir **[Karar]** satırı. Kullanıcı bir satırı kaldırırsa yerine onun sözü yazılır ve
   satır silinir — düzeltilen bilgi işaretlenmez, **silinir** (lore yazım kuralı).



