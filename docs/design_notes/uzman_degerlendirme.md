# Üç uzman profili: oyunu ürün olarak sınamak

**Tarih:** 2026-11-06 · **Araç:** `tests/simulate_expert_review.gd` (6 koşu × 40 sefer) ·
**Önceki turlar:** `oyuncu_profilleri.md` (beş profil), `oyuncu_gunlukleri.md` (altı profil + günlük)

Önceki iki tur oyuncuyu taklit etti: *kim keyif alıyor, kim ölüyor.* Bu tur oyunu **ürün olarak**
sınıyor: ilk oturum hunisi, içerik pisti, ustalık eğrisi, ve "bu oyun ne kadar dolgu".

---

## 0. Önce sınır: bu araç neyi ölçemez

Gerçek tutundurma göstergeleri (D1/D7/D30, iade oranı, inceleme dönüşümü, oturum sayısı) **insan
gerektirir**. Bir simülatörün ürettiği D1 sayısı uydurmadır ve bu raporda yoktur. Ölçülen şey oyunun
kendi durumundan hesaplanabilen **vekil göstergelerdir**; her birinin neyin vekili olduğu yanında
yazıyor.

Sektörel çerçeve de dürüstçe kurulmalı: yayımlanan PC tutundurma ölçütleri (D1 medyanı ~%9, D7
~%1,8) ezici çoğunlukla **ücretsiz/mobil biçimli** oyunlardan geliyor ve tek seferlik satılan bir PC
oyununa doğrudan uygulanamaz. Premium bir oyun için bağlayıcı olan üç şey var ve üçü de bu oyun için
geçerli:

1. **Steam iade penceresi: 14 gün ve 2 saat.** Oynanmamış erken erişim süresi de bu iki saate
   sayılıyor. Yani ilk iki saat ticari bir kapıdır, bir fikir değil.
2. **Medyan oturum süresi PC'de ~18 dakika, günlük medyan oynama ~32 dakika.** Oyun bu uzunlukta
   doğal bir duruş noktası vermiyorsa oyuncu yarıda bırakıp dönmez.
3. **İnceleme ve ağızdan ağıza yayılma anlatılabilirliğe bağlıdır.** Oyuncu olanı *anlatamıyorsa*
   oyun yayılmaz.

Bu raporun ölçtüğü vekiller tam olarak bu üçünün karşılıkları: huni (ilk oturum), seans şekli ve
kanca (duruş noktası), adlı sonuç (anlatılabilirlik).

---

## 1. Profiller

### A · Tutundurma Analisti
*Oyunu bir ürün hunisi olarak okur. "Oyuncu ilk oturumda neyi gördü, ne zaman yeni bir şey görmeyi
bıraktı, bıraktığında geride ne kaldı?"*

Ölçtükleri: ilk oturum hunisi · seans şekli · erken bırakma riski · içerik pisti · tekrar oranı ·
bırakma noktası · geri dönme kancası · boş tur oranı.

### B · Sistem Tasarımcısı
*Kararın gerçekten karar olup olmadığına bakar. "Beceri bir şeyi değiştiriyor mu, yoksa oyun
kendini mi oynuyor?"*

Ölçtükleri: karar yoğunluğu · tek seçenekli kart · **sahte seçim** (seçenekleri aynı etkiyi veren
kart) · beceri kontrolü oranı · üç politikanın karşılaştırması (acemi / dengeli / açgözlü) ·
ekonomi tıkanması · ödül aralığı.

### C · Zanaat Denetçisi
*Tek soru: bu oyun ne kadar dolgu?* Katalogun tamamı üzerinde durağan denetim.

Ölçtükleri: metin tekrarı · sözcük çeşitliliği (tür/jeton oranı) · seçenek biçimi dağılımı · etki
dili çeşitliliği · **yalnız sayı oynatan sonuç oranı** · **adı/yeri anan sonuç oranı** · yapay zekâ
yazım izleri · kalıplaşmış cümle açılışları.

---

## 2. Ölçüm

### A · Tutundurma

| gösterge | ölçülen | neyin vekili |
|---|---|---|
| ilk 3 seferde gerçek bir seçim | **6/6 koşu** | ilk oturumda "oyun bu" anı |
| ilk 3 seferde görülmemiş bir yer | **6/6** | keşif vaadi |
| ilk 3 seferde ilk gerçek kayıp | **6/6** | riskin kurulması |
| ilk 3 seferde ilk dövüş | **1/6** | sistemlerin tanıtımı |
| ilk oturumda kervan bitti | **0/6** | erken bırakma riski (düşük, iyi) |
| sefer başına oyun günü | **13,9** | seans uzunluğu |
| **içerik pisti** | **4,2. sefer** | yeni kart oranının düştüğü nokta |
| 40 seferde görülen katalog payı | **%56** (97 kartın) | gerçekten ulaşılan içerik |
| tekrar oranı | **%73** | aynı kartı tekrar görme |
| 40 seferde biten koşu | **0/6** | başarısızlık baskısı (yok) |
| koşu sonunda açıkta kalan | 11,3 yer · 4,7 kişi işi · 42,8 kart | geri dönme kancası |
| boş tur | **%19** şehir ziyareti | yapacak bir şey olmayan tur |

### B · Sistemler

| gösterge | ölçülen |
|---|---|
| tek seçenekli kart | 3 / 97 (**%3**) |
| sahte seçim (seçenekler aynı etkiyi veriyor) | 4 (**%4**) |
| beceri kontrolü taşıyan kart | 62 (**%64**) |
| kart başına açık seçenek | **2,55** |
| zorunlu kart oranı | **%2** |

Üç politika, aynı tohumlar, 40 sefer:

| politika | sefer | ölüm | kese | teslimat | aç sefer |
|---|---|---|---|---|---|
| acemi (rastgele seçer) | 40,0 | 0,2 | **−290 GG** | 14,0 | **%26** |
| dengeli (plan okur) | 40,0 | 0,3 | **+238 GG** | 13,7 | %9 |
| açgözlü (altına koşar) | 40,0 | 0,5 | +264 GG | 11,7 | %11 |

Dayanıklılık farkı **0,0 sefer**; kese farkı **554 GG**. Ekonomi: seferlerin %9'unda gereken erzak
alınamıyor; iyi bir şey arası **34 gün**.

### C · Zanaat

| gösterge | ölçülen | okuma |
|---|---|---|
| benzersiz kart gövdesi | **97/97 (%100)** | kopyala-yapıştır yok |
| sözcük çeşitliliği (TTR) | **0,66** (1476 sözcük, 969 farklı) | yüksek |
| seçenek biçimi | 1:3 · 2:35 · 3:43 · 4:14 · 5:2 | şablon yok |
| kullanılan etki türü | **29** | geniş dil |
| **yalnız sayı oynatan sonuç** | **%37** (199 sonucun) | zayıf nokta |
| etkisiz sonuç ("hiçbir şey olmaz") | **0** | dolgu yok |
| **adı/yeri anan sonuç** | **0 (%0)** | **en büyük açık** |
| YZ yazım izleri | üçleme 2 · "sadece…değil" 0 · "bir yandan…öte yandan" 0 · tire yığılması 0 | temiz |
| en sık açılış | "Yolun kenarında" ×4 · "Yolun ortasında" ×3 · "Yol kenarında" ×3 | hafif kalıp |

---

## 3. Altı bulgu

### 1. İçerik pisti dört sefer, ama katalogun %44'ü hiç görünmüyor
Yeni kart oranı **4,2. seferde** düşüyor, çekilen kartların **%73'ü tekrar** — ve yine de 40 seferde
97 kartın yalnız %56'sı görülüyor. Yani oyun yeni görünmeyi erken bırakıyor **içerik bittiği için
değil, aynı kartları yeniden çektiği için.** Bu bir içerik üretme işi değil, bir **çekiliş ağırlığı**
işi; en ucuz ve en yüksek getirili düzeltme bu raporda.

### 2. Yetkin oyuncu için başarısızlık baskısı yok
Altı koşunun hiçbiri 40 seferde bitmedi; ölüm 0,2-0,5. Oyunun bütün omurgası — soy, defter, "taşıyacak
kimse kalmaması" — **yetkin oyuncuda hiç ateşlenmiyor.** Koşusu bitmeyen koşu tabanlı bir oyunda
"bir el daha" döngüsü yoktur. (Önceki turun bulgusu buydu ve dağılma kuralı bandı açtı; ama *dikkatli*
oyuncu hâlâ dokunulmaz.)

### 3. Ustalık görünüyor ama ödüllendirilmiyor
Beceri **kesede** (554 GG) ve **açlıkta** (%26 → %9) net görünüyor; **hayatta kalmada hiç
görünmüyor** (üçü de 40 sefer). Oyuncu iyi oynadığını ancak tabloya bakarsa anlar. Ustalığın
koruduğu şey tehlikede değilse ustalık hissedilmez.

### 4. Kararlar gerçek — bu oyun dolgu değil
%3 tek seçenekli, **%4 sahte seçim**, %64 beceri kontrolü, kart başına 2,55 açık seçenek. Metin
tarafında %100 benzersiz gövde, 0,66 çeşitlilik, sıfır etkisiz sonuç, sıfır yazım izi. Ölçebildiğim
her eksende bunun tersi: **el emeği.**

### 5. Ama hiçbir sonuç kimseyi anmıyor
199 sonuç, **sıfırı** bir kişinin ya da yerin adını geçiriyor; %37'si yalnız bir sayı oynatıyor.
Oyunun dördüncü sütunu *"Defter unutmaz"* — ama defterin yazdığı şeyler isimsiz. Bu hem bir zanaat
açığı hem bir tutundurma kaldıracı: insanlar **anlatabildikleri** şeyi anlatır.

### 6. Ritim seyrek, ve her beş şehirden biri boş
İyi bir şey arası 34 gün; şehir ziyaretlerinin %19'unda alınacak/yapılacak bir şey yok. Premium bir
oyunda "hiçbir şey olmayan tur" doğrudan oturum sonu demektir.

---

## 4. Tutundurma ölçütleri — bu oyun için yedi madde

Kullanıcının sorusu: *oyunu deneyim katan, bir serüvenin içinde tutan, retention'ı yüksek hale
getirecek kriterler nedir?* Bu oyun için, ölçülenlere dayanarak:

1. **İlk iki saat bir kapıdır.** Steam'in iade kuralı 14 gün / 2 saat ve erken erişim süresi de
   sayılıyor. İlk 2 saatte oyuncu şunları görmeli: gerçek bir seçim ✅, görülmemiş bir yer ✅, bir
   kayıp ✅, ve **oyunun kendine özgü sistemi** (dövüş ❌ 1/6, dağılma ❌, soy devri ❌). Oyun kendi
   imzasını ilk oturumda göstermiyor.
2. **Oturum bir varışta bitmeli, ve bitişte bir şey yarım kalmalı.** Doğal duruş noktası var (şehre
   varış) ama yarım kalan şey **adlandırılmıyor**: oyuncu "Kirsavel'de Mathis dört kürk bekliyor"
   diye kapatmalı, "40 kart daha var" diye değil.
3. **Yenilik eğrisi dördüncü seferden sonra düşmemeli.** Ölçülen 4,2. Hedef: yeni kart oranı ilk 15
   seferde 1/sefer'in altına inmemeli.
4. **Koşu bitebilmeli.** Başarısızlık baskısı olmayan bir oyunda yeniden başlamanın anlamı yoktur —
   ve bu oyunun bütün vaadi yeniden başlamanın üstüne kurulu.
5. **Ustalık görünür olmalı.** Beceri yalnız tabloda değil ekranda da karşılık bulmalı: "bu seferi
   şu yüzden atlattın."
6. **Anlatılabilirlik.** Her sonucun bir adı olmalı. Anlatılamayan oyun yayılmaz.
7. **Ölü tur olmamalı.** Her şehir ziyareti en az bir karar sunmalı (%19 → hedef %0).

---

## 5. Öneriler (etkiye göre sıralı)

### U1 — Çekiliş görülmemiş kartı kayırsın *(küçük, en yüksek getiri)*
`RoadDirector`/`EventEngine` ağırlığına "bu kervan bunu gördü mü" payı: görülmemiş kart ×2, son
N seferde görülen ×0,4. `seen_event_ids` zaten var (Ö4). Beklenen etki: içerik pisti 4 → 15+ sefer,
tekrar oranı %73 → %40 civarı, **tek satırlık içerik üretmeden**.

### U2 — Sonuçlar bir adı ansın *(orta, zanaatın en büyük açığı)*
199 sonucun sıfırı bir ad geçiriyor; `{place}`, `{nemesis}` gibi yer tutucular var ama neredeyse
kullanılmıyor. Her sonuç metni **kim/nerede** söylesin: "Bedel Lorenz'e düştü", "Bunu Kirsavel'de
anlatacaklar". Mekanik değişiklik değil, metin işi — ve hem dördüncü sütunu hem anlatılabilirliği
doğrudan besler.

### U3 — Yetkin oyuncuya da bir son olsun *(orta, kullanıcı kararı)*
40 seferde hiçbir koşu bitmiyor. Üç yol var, üçü de sistem kesmez: kıtlığın zamanla ağırlaşan
derecesi (`Scarcity` kayması zaten var, eğimi artırılabilir), yaşlanma/kuşak baskısı, ya da
büyüyen kervanın kendi krizleri (Y-C24). **Hangisinin seçileceği bir tasarım kararı** — ölçüm
yalnızca "şu an hiçbiri ısırmıyor" diyor.

### U4 — Boş turu kapat *(küçük)*
Şehir ziyaretlerinin %19'unda yapacak bir şey yok. Şehir özeti zaten ihtiyaçları biliyor; hiçbir
şey yapılamıyorsa en az bir **bedelli** seçenek sunulmalı (gündelik iş, el açmak, kişilerin işi).
Bunların hepsi var — görünmüyorlar.

### U5 — İlk oturum oyunun imzasını göstersin *(küçük)*
İlk üç seferde dövüş 1/6. Oyunun kendine özgü anları (dağılma, soy devri, dövüş) ilk iki saatte en
az birer kez görünmeli — zorlamayla değil, ilk seferlerde ağırlıklarını artırarak.

### U6 — Ustalığı ekranda söyle *(küçük)*
Varışta "şu kadar az aç gün geçirdin", "planı okuduğun için şu kadar erzak arttı" gibi bir satır.
Ölçümde beceri 554 GG ve %26→%9 açlık farkı yaratıyor; oyuncu bunu hiçbir yerde okumuyor.

### U7 — Sayı-only sonuçları azalt *(sürekli)*
Sonuçların %37'si yalnız altın/moral/stres/itibar oynatıyor. Bunların bir kısmı bir **nesneye,
kişiye ya da yere** bağlansın (bir mal gitsin, biri kırılsın, bir yol kapansın) — etki dili zaten
29 türlü, kullanılmıyor.

---

## 6. Yöntemin sınırları

- **Simülatör gerçek tutundurma ölçemez.** Buradaki her sayı bir vekildir; D1/D7/iade/inceleme
  için oyuncu gerekir.
- **Altı koşu azdır.** Tohumlar sabit; eğilimi gösterir, dağılımı değil.
- **Tek sofra politikası.** Üç politika da `MEAL_MODE_PARTY_ONLY` oynuyor; cömert oyuncunun eğrisi
  `oyuncu_gunlukleri.md`'de.
- **Zanaat denetimi metni okur, anlamaz.** "Yalnız sayı oynatan sonuç" bir kalite yargısı değil bir
  biçim sayımıdır; iyi yazılmış bir sayı sonucu da olabilir.
- **Dövüş politikası tek.** Dövüş sayıları yön gösterir, kesin değildir.

---

## 7. İkinci tur: U1-U7 uygulandıktan sonraki ölçüm (2026-11-07)

Aynı araç, aynı tohumlar (6 koşu × 40 sefer). Katalog 97 → 100 kart (üç yol
kesen kart eklendi), sonuç sayısı 193 → 205.

| ölçü | önce | sonra | not |
|---|---|---|---|
| içerik pisti | 4,2 sefer | 6,3 sefer | U1 çalıştı; yeni kartların sık çekilmesi bir kısmını geri aldı |
| katalogun görüldüğü pay | %56 | %58 | |
| tekrar oranı | %73 | %75 | yol kesme garantisi her seferde bir kart harcıyor |
| adı/yeri anan sonuç | %0 | **%96** | U2 |
| yalnız sayı oynatan sonuç | %37 | **%22** | U7 |
| sahte seçim | %4 | %2 | U7'nin yan etkisi |
| ilk üç seferde dövüş | 1/6 | **4/6** | U5 |
| boş tur | %19 | %28 | aşağıya bak |
| 40 seferde biten koşu | 0/6 | 0/6 | U3 kısmen |

**Boş tur neden arttı?** İki sebep, ikisi de gerçek. Yol kesenler kervanı
fakirleştiriyor (alacak parası kalmıyor), ve ölçüm aracı U4'ün önerisini
baştan görmüyordu - araç düzeltildi (kiler üç günün altına inince gündelik
işe gidiliyor) ve sayı %34'ten %28'e indi. Kalanı ekonominin kendisi.

**U3'ün dürüst durumu.** Seçilen kol kıtlığın derinleşmesi oldu (kayma
0,0004 → 0,00055/gün, tavan 0,2 → 0,45). 40 seferde kimse bitmiyor ama
**90 sefer ölçüldüğünde**: acemi 68,3 seferde, açgözlü 75,5 seferde bitiyor;
plan okuyan 90'ı da tamamlıyor (kese +86 GG, aç sefer %6). Yani kıtlık
dikkatsizi ve açgözlüyü artık öldürüyor, **yetkin oyuncuyu öldürmüyor**.
Raporun saydığı öbür iki kol (yaşlanma/kuşak baskısı, büyüyen kervanın kendi
krizleri - Y-C24) hâlâ açık ve bu kullanıcı kararı.

**İlk dövüş neden 4/6'da kaldı?** "Üst üste ödeyenle pazarlık biter" eşiği
3'ten 2'ye indirildi ve ölçüm **değişmedi**. Sebebi kusur değil, mekaniğin
kendisi: kalan iki koşuda kervan ödemiyor, *blöf yapıyor* ve blöf tutuyor
(zeki kervancı malı yutturup canını kurtarır - kullanıcı kararı 2026-11-07).
Eşik gevşek olanda (3) bırakıldı.
