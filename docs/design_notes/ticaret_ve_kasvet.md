# Ticaretin ağırlığı ve kasvet: tartı (2026-11-05)

Kullanıcı isteği: *"Oyunun odağını bozduğu için ticaret mekaniklerini biraz basitleştirmek istiyorum. Mesela borç
sistemi kalkabilir ya da sadeleştirilebilir belki. Pazarlık sistemi de basitleştirilebilir belki. Oyun aşırı
derecede kasvetli hissettirmeli ve yokluk içinde kıvranmalıyız."*

Bu bir değerlendirme notu, bir uygulama değil. Sistem kaldırma kararı kullanıcınındır (CLAUDE.md, "Kıtlığın üç
tasarım dersi" → *Sınır*).

---

## Kısa cevap

**Sorun ticaretin derinliği değil, ticaretin oyuncuyu soktuğu kip.** Pazarlık turları ve faizli borç defteri
oyuncuyu bir **muhasebe koltuğuna** oturtuyor: karşılaştır, optimize et, turları sür. Bu, oyunun geri kalanının
kurduğu yıpranma ve korku kipinin tam tersi. İkinci ve daha ağır sorun: **ticaret, oyunda kıtlığı ortadan
kaldırabilen tek sistem.** Pazarlıkta ustalaşan ve arbitraj öğrenen oyuncu acıkmayı bırakır.

Bu yüzden önerim "biraz basitleştirmek" değil, üç ayrı karar:

| | Karar | Neden |
|---|---|---|
| **Pazarlık** | Mini oyunu **çıkar**, kararı bırak | Çok turlu stat döngüsü bir optimizasyon oyunu; tek, geri alınamaz, bedeli adı olan birine düşen bir seçim aynı işi kasvetle yapar |
| **Borç** | Faiz ve defteri **çıkar**, yükü ve alacaklıyı **tut** | Borcun değerli yanı baskı; zararlı yanı aritmetik. Bunu oyunun kendi ölçümü zaten kanıtladı (aşağıda) |
| **Pazar** | **Dönüştür**: fiyat oyunu → bulunabilirlik oyunu | Kıtlığın en ucuz ve en karanlık hâli: altın var, tahıl yok |

Ve bir uyarı: aşağıdaki **"doğru stoklayan asla aç kalmaz" sözü, istenen hisle doğrudan çelişiyor.** İkisi birden
olmaz; bu bir kullanıcı kararı ve en önemlisi bu.

---

## 1. Teşhis: kip ve kaçış kapağı

### Kip (register)

Oyunun geri kalanı oyuncudan şunu ister: *bak, kat, dayan, birini feda et.* Ticaret katmanı şunu ister:
*karşılaştır, hesapla, en iyisini bul.* İkisi aynı oturumda yan yana durunca ikincisi birincisini yiyor, çünkü
optimizasyon kipi doyurucudur: ölçülebilir bir "doğru cevap" verir. Kıtlığın ise doğru cevabı yoktur - bu zaten
oyunun kendi yazılı dersi (`kitlik_tasarim_dersleri.md`, *Ahlaki zorunluluk: doğru seçenek yok*).

Dışarıdan aynı gözlem: *Sunless Sea* eleştirmenleri oyunun kalıcı ölümüyle ticaret/öğütme döngüsünün birbiriyle
çeliştiğini söylüyor - öğütme, ölümün ağırlığını hafifletiyor
([Failbetter forumu](https://community.failbettergames.com/t/an-interesting-review-with-thoughtful-criticisms/13042),
[Scientific Gamer](https://scientificgamer.com/thoughts-sunless-sea/)). *Pathologic 2*'nin açlık çubuğu da benzer
bir şikâyet aldı: PC Gamer için "sıkıcı bir idari iş"
([PC Gamer](https://www.pcgamer.com/pathologic-2-review/)), GameSpot için hikâyeden dikkat çalan bir yük
([GameSpot](https://www.gamespot.com/reviews/pathologic-2-review-the-big-sick/1900-6417158/)). Yani *sert yapmak*
ile *kasvetli yapmak* aynı şey değil; sertlik yanlış kipte idari yorgunluğa dönüşüyor.

### Kaçış kapağı

Jon Shafer, *At the Gates*'in kervanının oyunun merkezini gölgelediğini fark edip ekonomiyi kervandan geçemez hâle
getirdiğini ve satış fiyatını alış fiyatının %75'ine sabitlediğini yazıyor
([Steam geliştirici notu](https://steamcommunity.com/app/241000/discussions/0/1644290549108808367)). Wayborne'da
aynı risk daha büyük, çünkü kervan oyunun kendisi.

**Ölçü şu olmalı:** kıtlık bir *para* sorunu değil, bir *arz* sorunu. Para sorunu çözülebilir; arz sorunu
dayanılır. *This War of Mine*'ın para birimi hiç yok - değer, fiyat yerine kıtlık tarifiyle anlatılıyor
([Game Developer analizi](https://www.gamedeveloper.com/design/learning-and-improving-upon-this-war-of-mine-a-ux-ui-analysis)).
Bu, Wayborne için kopyalanacak tek en önemli karar.

---

## 2. Kanıt: oyunun kendi ölçümü borcu zaten mahkûm etti

`docs/design_notes/denge_baba_borcu.md` (Y-C14, 2026-10-19, `simulate_career`, 8 kervan × 40 sefer):

- İlk değerlerle (240 altın, 60 gün, %15 faiz, -3 itibar) borç **20. seferde 22 bine, 40. seferde milyonlara**
  çıktı; itibar -17'ye indi, loncanın kapıları kapandı, kampanya bölümleri 8/8'den 1/8'e düştü.
- Yumuşatmadan sonra (180 altın, 120 gün, %4, -1) borç dizginlendi **ama bölümler yine kapanmadı** ve sebebin borç
  olmadığı çıktı.

Yani faizli borç ya oyunu kilitliyor ya da zararsız hâle getirilince **hiçbir şey yapmıyor**. Bu, bir mekaniğin
taşıyamadığı ağırlığın altında ezilmesinin ders kitabı örneği. Aritmetik katman gitmeli.

Buna karşılık `ilk_on_dakika.md` borcu şöyle kullanıyor: *"0:00-1:00 Kervanın adı ve devir sahnesi: borç ve vade
(**karar değil, yük**)."* Bu iyi tasarım ve kalmalı. Borcun değerli yanı budur: oyun zaten borçlu başlar.

---

## 3. Üç karar, ayrı ayrı

### 3a. Pazarlık: mini oyunu çıkar, kararı bırak

Bugün: `haggling_session.gd` (215 satır) + `haggling.gd` (104) + `haggling_panel.gd` (227) = **546 satır**, çok
turlu, Karizma kontrollü bir fiyat döngüsü.

**Öneri.** Tek ekranlık bir karar: *kabul et* · *diren* · *çık git*. "Diren" bir Karizma zarı atar; kazanırsan
fiyat düşer, kaybedersen **itibarın o bölgede düşer** (`Standing`, T16-07 zaten var). Tur yok, sürükleme yok.
Kazanç küçülsün: pazarlık bir gelir kaynağı değil, bir risk.

**Asıl dönüşüm:** kıtlıkta pazarlığın konusu fiyat olmasın. *"Bu çuvalı bana ver"* dediğin kişi de aç. Pazarlık
kartı Karizma yerine bazen **vicdan** sorsun: ısrar edersen alırsın, ama o şehirde bir şey kapanır ve defterine bir
satır düşer. Bu, kıtlık derslerinin "bedel adı olan birine düşer" kuralının ticaret tarafı.

**Kazanç:** ~400 satır kod ve bir ekran eksilir; Karizma statı ve itibar bağı korunur (derinleşme, sadeleştirme
değil: karar kalır, tıklama gider).

### 3b. Borç: faizi ve defteri çıkar, alacaklıyı tut

Bugün: `debt.gd` (137) + `debt_ledger.gd` (156) + `debt_panel.gd` (327) = **620 satır** ve sayılardan oluşan bir
panel.

**Öneri: borç bir finansal araç olmaktan çıkıp bir yükümlülük olsun.**

- Faiz yok. Bileşik faiz yok. Ödeme planı yok.
- Yerine: **adı olan bir alacaklı** (akraba, lonca, bir bey) ve **bir vade**. Borcun karşılığı para değil, çoğu
  zaman bir **teslimat** olabilir: şu tahılı şu şehre götür, şu kişiyi yanında taşı.
- Vade geçerse aritmetik değil **sosyal** bir şey olur: bir şehrin pazarı sana kapanır, yolda alacaklının adamları
  seni bulur, ya da birini alıp giderler. Hepsi oyunda zaten var olan kollar (`Standing`, olay kartı, yol
  karşılaşması).
- Panel kalkar; borç **Defter'de bir satır** olarak yaşar. Dördüncü sütun: *Defter unutmaz.*

Bu, tarihsel olarak da doğru: ortaçağ ticari kredisi faiz tablosu değil, **güven ve itibar** üzerine kuruluydu;
borç mahkeme kayıtlarına ve gecikmiş ödemelere yazılırdı
([Enterprise & Society, geç ortaçağ kredisi](https://www.cambridge.org/core/journals/enterprise-and-society/article/uncertainty-staple-credit-and-the-measurement-of-later-medieval-business-confidence/508ECA5CD2EEC74939C7043CFD7B39D2),
[Reading Üniversitesi, ortaçağda paranın kullanılmaması](https://centaur.reading.ac.uk/30672/1/12%20Chapter%201839%20(1).pdf)).
Ve kıtlıkla doğrudan ilgili: 1315-16 Büyük Kıtlığı'nda köylülerin **yemek almak için borçlanması** ve eski
alacakların birden istenmesi mahkemelerde borç davası patlamasına yol açtı
([Agricultural History Review](https://bahs.org.uk/AGHR/ARTICLES/45n1a1.pdf)). Kıtlıkta borç, faiz oranı değil,
kapıya dayanan biridir.

**Baskıyı kaybetmiyoruz.** *Recettear*'ın haftalık taksiti bu yüzden işe yarar: kaçırırsan oyun biter
([Game Developer analizi](https://www.gamedeveloper.com/design/saving-the-world-through-profit-recettear-an-item-shop-s-tale-analysis-)).
Değerli olan takvim baskısıdır, faiz formülü değil.

### 3c. Pazar: fiyat oyunu → bulunabilirlik oyunu

Bugün: `market.gd` **1009 satır**, `market_conditions.gd` 365, `market_pricing.gd` 144, terazi çizimi 367.

Burada **silme değil, çevirme** öneriyorum ve bu en büyük his kazancı:

- **Çoğu şehirde çoğu mal yok.** Pazar ekranının en sık gösterdiği şey fiyat değil, *yok* olmalı. Stok tavanı
  `MarketConditions`'a bir alan; kıtlık derecesiyle düşüyor.
- **Altın değersizleşir, takas değer kazanır.** Yokluk arttıkça mal-mala değişim öne çıkar: "sana şunu veririm"
  tek bir satır, optimize edilecek bir tablo değil.
- **Fiyatı görmeden gitmek.** Dördüncü sütun *Ticaret bilgi oyunudur* - ama bilgi, görünen bir tablo değil,
  **eksikliği** olmalı. Bir şehirde ne olduğunu ancak varınca ya da birine sorarak (ve yanlış olabilecek bir
  haberle) öğren.

Bu üçü birlikte, ticaret sistemini kesmeden kıtlığı ticaretin içine taşır. Sütun kalır, kip değişir.

---

## 4. Ne eklenmeli (ucuzdan pahalıya)

1. **Stok: şehirde mal biter.** (S) En büyük his kazancı, en küçük iş. `MarketConditions`'a stok alanı.
2. **Borç bir ad ve bir teslimat olur.** (M) `Debt` sadeleşir, `DebtLedger` ve panel düşer, Defter satırı gelir.
3. **Pazarlık tek karara iner.** (M) `HagglingSession`'ın turları düşer, Karizma zarı ve itibar bedeli kalır.
4. **Takas.** (M) Para yetmediğinde mal-mala; yokluk arttıkça varsayılan hâle gelir.
5. **Defter sattığını hatırlar.** (S) Vebalı şehirde son ilacı satmak bir satır ve o şehirde bir tepki olur
   (`People`/`Standing` zaten var, T16-09).
6. **Haber eskiyebilir ve yanlış olabilir.** (M) Bilgi oyununun karanlık hâli.

---

## 5. Kaldırmanın gerçek bedeli — **ölçüldü**

Kod taraması (2026-11-05) sezgiyi **tersine çevirdi**: kullanıcının cümlesinde borç önce, pazarlık sonra geçiyor;
bağımlılıkta sıra tam tersi.

### Pazarlık bir **yaprak**

| | |
|---|---|
| Kod | `haggling_session.gd` 215 + `haggling_panel.gd` 227 + `haggling.gd` 104 = **546 satır** |
| Olay kartı | **1** (pusu, `event_catalog.gd:324`, `TRIGGER_HAGGLING`). "Pazarlık" diyen öbür iki kart (köy yemeği, kervansaray haydudu) düz Karizma kontrolü - `HagglingSession`'a hiç dokunmuyor, **kırılmaz** |
| Çeviri anahtarı | **39** |
| Test | **7 dosya** (`test_haggling.gd` 288 satır tamamen ölür, kalan 6'sı birer satır) |
| Codex | 1 bölüm |
| Başka okuyucu | **Yok.** `MarketPricing`, `MarketConditions`, borç, kontratlar, `Standing`, atölye - hiçbiri pazarlığı okumuyor |

Üstelik `scripts/ui/haggling.gd` (104 satır) **oyunun akışında bile değil**: yalnız `test_selector.tscn`'den
açılan bir geliştirici sahnesi. O, karar beklemeden silinebilir.

**Ve kendi belgemiz suçu itiraf ediyor:** Codex'teki bölümün başlığı *"Pazarlık: oyunun **para basma noktası**"*
(`docs/codex/codex_body2.py:118`). Teşhisin kanıtı bundan açık olamaz - kıtlık oyununda para basan bir nokta var.

Bir de yol boyu fark edilen tuhaflık: pazarda `HagglingSession`'ın `player_speech` yuvasına **Zekâ** besleniyor
(`market.gd:896`), Karizma ikinci parametre. Niyet buysa adı yanlış, değilse bu bir hata. Pazarlık sadeleşirken
ikisinden biri seçilmeli.

### Borç bir **omurga**

| | |
|---|---|
| Kod | `debt.gd` 137 + `debt_ledger.gd` 156 + `debt_panel.gd` 327 = **620 satır**, ama borca **44 kod dosyası** değiyor |
| Olay kartı | **3** + bir zincir (`evt_creditor_rider`, `evt_bailiffs_at_camp`, `evt_deserter_debt`) |
| Olay motoru | `EventEffect.Type.DEBT_SETTLE`, `EFF_WENT_INTO_DEBT`, ve `RoadDirector`'un kart önceliğini `debt_overdue` ile belirleyen dalı |
| Çeviri anahtarı | **51** |
| Test | **14 dosya** |
| Codex | **2 bölüm** + 5 ayrı yer |
| Başka okuyucu | Kökenlerin yarısı (`start_origins`: lonca vesayeti ×2, kaçakçı vade 30, dul ×0.5, ikisi sıfırlar), yola çıkış morali −10, **lonca hizip itibarı** (`Standing.GUILD`), kredi limiti, şehir özeti ihtiyaç listesi, miras sahnesi, 15 ekran satırı |

**Bu yüzden borç için "kaldır" değil "dönüştür" öneriyorum** (3b) - ve bu öneri o 44 bağlantının çoğunu
**korur**: üç olay kartı `debt_overdue` ve `debt >= 150` koşullarıyla çalışıyor; adı olan bir alacaklıya olan
vadesi geçmiş bir yükümlülük de "gecikmiş" ve "büyük" olabilir. Moral cezası, lonca itibarı kaybı, kökenlerin
farkı, Defter satırı - hepsi durur. Düşen yalnızca **aritmetik**: faiz, yapılandırma düğmesi, kredi alma satırı,
sayılardan oluşan panel.

Açık hesap (kese eksiye düşünce doğan borç) ayrı bir şey ve **kalmalı**: o bir kredi değil, sıfırın altına
inememenin adı.

### Pazarın yüzeyi: 7 görünür + 11 gizli

`market.gd` 1009 satır, sekmesiz üç sütun. Fiyatın **7 resmî katmanı** oyuncuya tooltip'te `×1.24` gibi
gösteriliyor; bunun **dışında 11 çarpan daha** var (kıtlık, kültür perki, Tellal indirimi, erzak çarpanı, toplu
indirim, tazelik, geri satış tavanı, ticaret lekesi, kapı komisyonu, aç şehir zammı, şehir hazinesi). Yani
oyuncuya bir elektronik tablonun yarısı gösteriliyor, yarısı gizleniyor.

**Bu, bilgi oyununun yanlış hâli.** Bilgi oyunu "çarpanları çöz" değil, "nerede ne var bilmiyorsun" olmalı. 7
katmanlı tooltip, Bölüm 3c'deki *bulunabilirlik* dönüşümünün en güçlü gerekçesi: görünür katman sayısı düşsün,
görünmeyen **stok** öne çıksın.

### Sıralama önerisi (bu bulgudan sonra)

1. **Önce pazarlık** - en ucuz kaldırma, en büyük kip kazancı, hiçbir sistem kırılmıyor.
2. **Sonra pazarın stoğu** - küçük iş, en büyük his kazancı.
3. **En son borç** - ve kaldırma değil dönüşüm; 44 bağlantı tek tek taşınacak bir göç işi.

---

## 5b. Çıkarmanın zamanlaması

*Unpacking*'in yaratıcı yönetmeni Wren Brier GDC 2023'te şunu söylüyor: çıkarma **prototip aşamasında** ucuzdur;
yapılmış içeriği kesmek pahalıdır
([GoNintendo özeti](https://www.gonintendo.com/contents/19398-unpacking-dev-discusses-subtractive-design-in-gdc-talk)).
Wayborne prototip aşamasında değil. Borç ve pazarlık kaldırılırsa kırılacaklar (tam listesi alt ajan taramasıyla
çıkarılıyor): çeviri anahtarları, bu sistemlere değen testler, `simulate_career`'ın ölçtüğü şeyler, Codex'in
ilgili bölümleri, olay kartları ve görev kayıtları. Bu, "sil gitsin" değil, bir göç işi.

Ayrıca **açılış borçta duruyor**: `ilk_on_dakika.md`'ye göre ilk anlamlı karar pazarda ya da panoda, ilk yük de
babadan kalan borç. İkisi de kalkarsa ilk on dakikanın yerine yeni bir şey konmalı. Benim önerim bunu
gerektirmiyor: borcun *yükü* ve pazarın *kararı* kalıyor, aritmetiği gidiyor.

David Sirlin'in çıkarma üzerine sözü burada işe yarıyor: çıkarmanın asıl faydası, ekibi **çekirdeğin ne olduğunu
söylemeye zorlamasıdır** ([Sirlin](http://sirlingames.squarespace.com/articles/subtractive-design.html)). Wayborne'un
çekirdeği zaten yazılı: *"Bir kervanı kuşaklar boyu yolda tut."* Bu cümlede fiyat yok. Ticaret, yolda kalmanın
aracı; amacı değil. Tartı bunu söylüyor.

---

## 6. Asıl çelişki: "doğru stoklayan asla aç kalmaz"

Oyunun en çok korunan sözü bu. Planlayıcı tam rezervi önceden hesaplıyor, `test_route_terrain` ve
`test_temperature` 80+ rota/mevsim kombinasyonunda kimsenin aç kalmadığını doğruluyor, hava ve soğuk payları bu
söz bozulmasın diye var.

**Bu söz, "yokluk içinde kıvranmalıyız" ile doğrudan çelişiyor.** Doğru stoklayabilen oyuncu, tanım gereği
kıvranmaz. Üç yol var ve bu **kullanıcı kararı**:

| | Söz | Sonuç |
|---|---|---|
| **A** | Olduğu gibi kalsın | Kıtlık his düzeyinde kalır: görüntü, metin, olay kartı. Mekanik güvenlik ağı durur. Dürüst ve adil, ama "kıvranmak" olmaz |
| **B** | Söz **arza** bağlansın | "Doğru stoklayan aç kalmaz" → *"stok bulabilirsen aç kalmazsın."* Planlayıcı doğru sayıyı söylemeye devam eder; **o sayıyı satın alamayabilirsin.** Oyuncuya haksızlık yok (hesap görünür), kıvranma var (mal yok) |
| **C** | Söz kalksın | En sert. Planlayıcının anlamı kalmaz, ölçüm altyapısının çoğu çöpe gider, oyun "hesaplanamaz" olur |

**Önerim B.** Sözü bozmadan anlamını değiştirir: açlık artık bir hesap hatası değil, bir dünya hâli. Oyuncu ne
gerektiğini bilir ve **bulamaz**. Kıtlığın en iyi tarifi budur.

---

## 7. Kasvet için referanslar ve her birinin verdiği somut ders

### Resim

- **Pieter Bruegel, *Karda Avcılar* (1565).** Dersi: **kıtlık yoklukla gösterilir, gösteriyle değil.** Koca bir av
  partisi dönüyor ve ellerinde *tek bir tilki* var; ağaçlar çıplak, kargalar dizili - ama aşağıda insanlar hâlâ
  paten kayıyor ve domuz ütülüyor. Felaket sahnesi değil, eksik bir sahne.
  ([Kunsthistorisches Museum](https://www.bruegel2018.at/en/the-hunters-in-the-snow/),
  [DailyArt](https://www.dailyartmagazine.com/pieter-bruegel-hunters-in-the-snow/)) Tablonun 1564/65'in sert kışına
  bağlandığı da söyleniyor ([Wikipedia, Batı sanatında kış manzaraları](https://en.wikipedia.org/wiki/Winter_landscapes_in_Western_art)).
  **Wayborne'a:** pazarda boş raf, vagonda tek çuval, ateşin başında eksik bir kişi. Oyun kıtlığı *saymamalı*,
  göstermeli.
- **Käthe Kollwitz, *Hunger* (1922) ve *Bread!* (1924).** Dersi: **kıtlığın yeri bedendir.** Kollwitz'in
  annesi çocuğunu kendi zayıflamış bedeninden besleyemez; *Bread!* açlıktan zayıf düşmüş bir çocuğu annesine
  yalvarırken gösterir. ([MoMA](https://www.moma.org/collection/works/489594),
  [Saint Louis Art Museum](https://www.slam.org/collection/objects/2964/),
  [Chazen dosyası](https://chazen.wisc.edu/wp-content/uploads/2020/12/Kollwitz-dossier.pdf))
  **Wayborne'a:** açlık bir çubukta değil, figürün üstünde görünmeli. Bugün ıslaklık, kar ve nefes buharı için
  yaptığımız şeyin (Y-G25) açlık ve yorgunluk karşılığı: çöken omuz, yavaşlayan adım, incelen siluet.

### Film

- **Béla Tarr, *Torinolu At* (2011).** Dersi: **tekdüzelik bir kaynaktır.** Aynı gün tekrar eder, her seferinde
  bir şey eksilerek; bütün filmde otuz civarı plan var ve tek bir müzik parçası baştan sona döner.
  ([eefb](https://eefb.org/perspectives/bela-tarrs-the-turin-horse-a-torinoi-loi-2010/),
  [Automachination](https://www.automachination.com/debase-acquire-bela-tarrs-the-turin-horse/))
  **Wayborne'a:** oyunun sessiz ve tekrar eden olmasına izin ver. Yol ekranı her dakika bir şey sunmak zorunda
  değil; "bugün de hiçbir şey olmadı, ve bir çuval daha azaldı" geçerli bir gün.
- **Aleksei German, *Tanrı Olmak Zor* (2013).** Dersi: **çamur bir dokudur, bir olay değil.**
  ([Klassiki](https://klassiki.online/hard-to-be-a-god-strugatsky-brothers-aleksei-german-podcast/))
  **Wayborne'a:** bugün eklediğimiz ıslaklık/çamur/kar katmanının yönü doğru; devamı kirin **kalıcı** olması -
  temizlenmeyen vagon, yıpranan giysi.

### Oyunlar

- **This War of Mine:** para birimi yok; değer, fiyatla değil kıtlık tarifiyle anlatılıyor
  ([Game Developer](https://www.gamedeveloper.com/design/learning-and-improving-upon-this-war-of-mine-a-ux-ui-analysis)).
  **Alınacak:** altının değersizleşmesi, takasın öne geçmesi.
- **Frostpunk:** sabit nüfusla yapılan deneme her ölümü pahalı yaptı ve senaryo yazarı "kıtlık anlatının kaynağı
  olabilir" dedi ([IGC 2018 özeti](https://www.invenglobal.com/articles/6528/igc-2018-empathize-with-numbers-the-process-of-frostpunk-scenario-writing)).
  Ama eleştirmenler tek bir kaynağın (kömür) bütün zorluğu yutabildiğini de yazdı
  ([RPG Site](https://www.rpgsite.net/review/7104-frostpunk-review)). **Alınacak:** yeri doldurulamaz insan;
  **kaçınılacak:** tek kaynağın her şeyi ezmesi (bizde bu erzak olabilir).
- **Pathologic 2:** tasarımcı Golubeva'ya göre oyun **eksik bir oynanış üzerine** kuruldu - oyuncunun yetişememesi
  amaçlandı ([Critical Distance](https://www.critical-distance.com/2020/07/01/pathologic/)); ekonomi bir
  elektronik tablo olarak başlayıp oyun testinden sonra elden geçirildi ve geliştirici "denge sadece matematiksel
  bir denklem değil" dedi ([EGM](https://egmnow.com/a-russian-crucible-pathologic-2-and-the-problem-of-video-game-difficulty/)).
  **Alınacak:** yetişememenin normal olması. **Kaçınılacak:** açlığın idari yorgunluğa dönüşmesi.
- **Darkest Dungeon:** bir eleştiri, kaybın yalnızca *zaman* maliyeti olduğunda dolgu malzemesine dönüştüğünü
  söylüyor ([The Gemsbok](https://thegemsbok.com/art-reviews-and-articles/darkest-dungeon-red-hook-critique-mechanics-design/)).
  **Alınacak:** her kaybın bir **adı** olsun; "bir sefer daha" bedeli yetmez.
- **The Long Dark:** bir oyuncu onu "kıtlığın değil bolluğun yönetimi" diye tanımlıyor
  ([RPGWatch](https://rpgwatch.com/forum/threads/the-long-dark-review-destructoid.37347/)).
  **Kaçınılacak:** depolanabilir bolluk. Wayborne'da vagon kapasitesi bunun kapısı.
- **At the Gates:** kervan merkezi gölgeleyince ekonomi kervandan koparıldı
  ([geliştirici notu](https://steamcommunity.com/app/241000/discussions/0/1644290549108808367)).
  **Alınacak:** ticaretin kârı, yolda kalmaya yetecek kadar olsun; servet biriktirmeye yetmesin.

### Tarih (kıtlığın gerçek dokusu)

- 1315-16 Büyük Kıtlığı'nda kredi **daraldı**: yiyecek için borçlanan köylü ve alacağını isteyen alacaklı
  mahkemeleri doldurdu ([AGHR](https://bahs.org.uk/AGHR/ARTICLES/45n1a1.pdf),
  [Brewminate özeti](https://brewminate.com/peasant-economic-agency-external-credit-and-the-14th-century-english-village/)).
- Floransalı tüccar-vakanüvis Giovanni Villani 1328 Toskana kıtlığında iaşe görevlisiydi; şehir kesesinden 60.000
  florin çıkarıldı ve Sicilya'dan tahıl getirildi ([Wikipedia](https://en.wikipedia.org/wiki/Giovanni_Villani)).
  **Wayborne'a:** kıtlıkta şehirler tahıl **ithal eder** - yani kervanın taşıdığı şey hayat kurtarır. Y-C21'in
  "şehrin moral durumu" fikrinin tarihsel karşılığı tam olarak budur.

---

## 8. Ne önermiyorum

- **Ticaretin tümden kalkmasını.** Dördüncü sütun ve kervanın var olma sebebi o. Kalkarsa oyun bir yürüyüş
  simülatörüne iner.
- **Bölgesel itibarın (`Standing`, T16-07) ya da şehir koşullarının sadeleşmesini.** Bunlar borcun ve pazarlığın
  **yerine geçecek** kolların ta kendisi; onları kesmek, elindeki tek alternatifi kesmek olur.
- **Zorluğu sayı büyüterek artırmayı.** Pathologic'in dersi: sert sayı, yanlış kipte kasvet değil angarya üretir.
- **Erzak formülünün bozulmasını.** Yukarıdaki B yolu sözü korur, yalnızca anlamını değiştirir.

---

## Karar beklenenler

1. **Pazarlık mini oyunu çıksın mı?** (önerim: evet, karar kalsın. En ucuzu: 546 satır, 1 olay kartı, 39 anahtar,
   7 test; başka hiçbir sistem okumuyor. `haggling.gd` zaten oyunda değil, karar beklemeden silinebilir)
2. **Pazarda stok tükenmesi ve takas eklensin mi?** (önerim: evet; en küçük iş, en büyük his kazancı)
3. **"Doğru stoklayan aç kalmaz" sözü için A, B, C?** (önerim: B - sözü arza bağla)
4. **Borcun faizi ve defteri çıkıp yerine adlı alacaklı + teslimat gelsin mi?** (önerim: evet ama **en son**;
   44 kod dosyası, 3 olay kartı, 51 anahtar, 14 test, 2 Codex bölümü. Dönüşüm bunların çoğunu korur, kaldırma
   korumaz)

Ek karar: pazarda pazarlık **Zekâ** ile mi **Karizma** ile mi yapılıyor? Bugün `player_speech` yuvasına Zekâ
besleniyor (`market.gd:896`) - niyet buysa adlandırma yanlış, değilse hata.
