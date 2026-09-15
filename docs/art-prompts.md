# Wayborne — Görsel Sahne Promptları (Gemini / görsel üretim)

Bu dosya, oyunun üç ana sahnesini bir görsel üretim modeline (Gemini,
Midjourney, vb.) çizdirmek için hazırlanmış promptları içerir.

**Nasıl kullanılır:** Önce "Ortak Bağlam"ı ver (oyunu ve sanat yönünü
anlatır), sonra çizdirmek istediğin sahnenin promptunu ekle. Ortak bağlamı
her seferinde tekrar vermek, üç sahnenin birbirine benzemesini sağlar -
oyunun en büyük görsel riski, her ekranın ayrı bir oyundan çıkmış gibi
durması.

**Önemli:** Üretilen görseller doğrudan oyuna girmez. Bunlar *konsept
resim*: oyunun şu anki `_draw()` tabanlı çizimini neye doğru götüreceğimizi
gösteren hedef. Oyun bunları referans alarak elle çizilmiş varlıklara
geçecek.

---

## Ortak Bağlam (her promptun başına ekle)

```
Bir bilgisayar oyunu için konsept görseli çiziyorsun.

OYUN: "Wayborne" — orta çağ Anadolu'sundan esinlenmiş, kervan ticareti ve
hayatta kalma oyunu. Oyuncu bir kervanbaşıdır: şehirden mal alır, yola
çıkar, yolda başına gelenlerle baş eder, öbür şehre varıp satar. Yolculuk
tehlikelidir — haydutlar, kurtlar, vergi görevlileri, çığ, fırtına,
açlık, kadronun morali ve tükenmişliği. Kervan mahvolabilir ama asla
tamamen yok olmaz; oyuncu hep dibe vurmuş bir kervanla devam edebilir.
Ton: romantik değil, yorgun ve gerçekçi. Zenginlik değil, dayanma
hikâyesi.

SANAT YÖNÜ (hepsinde aynı):
- Stil: "yassı-resimsel" (flat illustrative) — piksel sanat DEĞİL, 3D
  DEĞİL, fotogerçekçi DEĞİL. Düz renk alanları, katmanlı siluetler,
  yumuşak gradyanlar, koyu ve kararlı bir kontur ("mürekkep" hissi),
  tek yönden gelen ışık. Darkest Dungeon'ın mürekkep hissi + Kingdom Two
  Crowns'ın sakin katmanlı siluetleri.
- Palet: kırık beyaz kemik tonu, koyu mürekkep siyahı (saf siyah değil),
  soluk altın sarısı (tek vurgu rengi), kurumuş kan kırmızısı, yosun
  yeşili, soğuk çelik grisi, meşale turuncusu. Doygunluk düşük; renk
  bağırmıyor.
- Perspektif/derinlik: hava perspektifi şart — uzaktaki her şey gökyüzünün
  pusuna doğru soluyor. Derinlik renk doygunluğundan ve katman
  siluetlerinden geliyor, çizgi perspektifinden değil.
- Her nesne yere basar: gövdesi düz bir zeminde biten şekil olmaz, her
  şeyin altında basık bir temas gölgesi vardır.
- Metin/arayüz öğesi çizme (aksi belirtilmedikçe). Yazı, logo, ikon,
  watermark yok.
```

---

## 1. Yol Sahnesi (oyunun ana ekranı)

```
[ORTAK BAĞLAM]

SAHNE: Yan görünüş (side-scroller), yatay 16:9 geniş kare. Kamera yolun
yanında, hafif uzakta; kervan soldan sağa yürüyor.

KOMPOZİSYON (katman katman, arkadan öne):
1. Gökyüzü: üstten alta gradyan. Günün evresi = şafak (soluk turuncu ufuk,
   hâlâ mavimsi üst). Ufkun az üstünde soluk bir güneş, çevresinde yumuşak
   bir hale.
2. Uzak sırtlar: neredeyse pusun içinde, tek renk siluet tepeler.
3. Orta sırtlar: biraz daha koyu, biraz daha belirgin.
4. Ağaç hattı: çam ormanı. Ağaçlar tek tek okunuyor ama detaysız — üçgen
   katmanlı iğne yapraklı siluetler. Yakındakiler daha büyük ve daha
   doygun, uzaktakiler soluk.
5. Zemin: ufuktan öne doğru açılan bir çayır/toprak gradyanı. Ufka değdiği
   kenar düz bir çizgi değil, hafif dalgalı.
6. Yol: zeminden biraz daha açık ve daha az doygun toprak bir şerit, iki
   yanında koyu bank. Üstünde tekerlek izleri ve çakıl.
7. En önde (kameraya en yakın): alçak otlar, küçük taşlar, çamur birikintisi.
   Burada uzun hiçbir şey olmayacak — ağaç yok, kaya yok; öndeki uzun bir
   nesne sahneyi kapatır.

KERVAN (sahnenin kalbi, sağ tarafta, yolun üstünde):
- En önde atlı bir lider: yorgun, sade giyimli bir kervanbaşı. Gösterişli
  zırh yok; yıpranmış yün ve deri.
- Arkasında yaya birkaç yoldaş: biri mızraklı bir muhafız, biri sırt
  çantalı bir levazımcı. Hepsi yorgun ama dik.
- Onların arkasında iki öküz arabası: kemerli branda örtülü, ahşap
  tekerlekli. Her arabayı bir çift öküz çekiyor; öküzün omzunda belirgin
  bir hörgüç var (atla karışmasın) ve arabaya bir ok/boyunduruk ile
  bağlı — hayvanla araba arasında boşluk yok, koşum görünüyor.
- Her arabanın öküzünün başında yürüyen bir arabacı.
- Figürler detaylı portre değil: okunaklı siluetler, yüz hatları minimum.

ATMOSFER: Hafif yağmur. İnce, eğik, kısa damlalar; yolda küçük su
birikintileri ve yansımalar. Işık yumuşak ve düşük.

UZAKTA: Sol uzakta, pusun içinde, arkada bıraktığımız şehrin küçük
silueti — sur çizgisi ve birkaç kule. Sağ uzakta, daha da soluk, gidilen
şehrin silueti.

HİSSİYAT: "Uzun bir yolun ortasındayız, hava bozuk, ama yürüyoruz."
Kahramanlık değil, süreklilik.
```

**Varyasyon istersen** (aynı promptu koruyup şu satırı değiştir):
- `Günün evresi = öğle, açık hava` → sıcak, net, gölgeler kısa
- `Günün evresi = gece, kamp kurulmuş` → kervan durmuş, bir kamp ateşi,
  ateşin etrafında oturan figürler, ateşin yere vuran turuncu ışık havuzu,
  gökyüzünde yıldızlar ve hilal
- `Biyom = bozkır` → ağaç hattı seyrek ve bodur, sarı-kahve zemin
- `Biyom = dağ geçidi` → arkada karlı tepeler, yol iki kaya kütlesi arasından
- `Biyom = bataklık` → cılız ağaçlar, sis bantları, durgun su

---

## 2. Şehir Sahnesi (kararların verildiği yer)

```
[ORTAK BAĞLAM]

SAHNE: Üstten bakışlı 2:1 izometrik bir orta çağ kasabası. Tek kare,
kasabanın tamamı görünüyor. Gündüz, açık hava — kasaba okunabilir olmalı,
karanlık bir çukur gibi durmamalı.

KOMPOZİSYON:
- Kasabayı bir sur duvarı çevreliyor, bir yerinde kemerli bir ana kapı var;
  kapıdan dışarı bir yol uzanıp kadraj dışına çıkıyor (kervanın geldiği yol).
- İçeride toprak sokaklar bir ızgara değil, hafif düzensiz bir ağ
  oluşturuyor. Sokaklar zeminden daha açık renkte.
- Sivil evler: sıkışık, iki katlı, alt katı taş/sıva üst katı ahşap
  çatkılı (yarım kirişli), kiremit ya da saz çatılı. Birbirinin aynısı
  değiller: çatı renkleri ve yükseklikleri değişiyor.
- Kasabanın içinde BEŞ ÖNEMLİ YAPI var ve her biri mimarisinden tanınmalı,
  yazı okumaya gerek kalmadan:
  1. PAZAR MEYDANI — bina değil, açık bir meydan: çizgili bez tenteler,
     tezgâhlar, küpler, çuvallar, top kumaşlar, alışveriş eden insanlar.
  2. TÜCCAR LONCASI — en gösterişli sivil yapı: taş, sütunlu bir giriş,
     düzgün kesme taş, belki bir bayrak/sancak.
  3. TAVERNA — ahşap ağırlıklı, alçak ve geniş, pencerelerinden sıcak sarı
     ışık sızıyor, kapısında asılı bir tabela levhası (üzerinde yazı yok,
     sadece bir şekil), dışarıda birkaç fıçı.
  4. KERVAN AVLUSU — duvarlarla çevrili geniş bir avlu: içinde arabalar,
     bağlı öküzler/atlar, saman, bir demirci köşesi (örs, ocak, incecik
     yükselen duman).
  5. KİLİSE/MABET — taş, en yüksek yapı, çan kulesi, dar uzun pencereler,
     sade bir haç ya da soyut bir sembol.
- Kasabanın içinde küçük hayat detayları: kuyu, birkaç ağaç, çamaşır ipi,
  gezinen insanlar, bir köpek, arabasını süren biri.

IŞIK: Tek yönden (sol üstten) gelen güneş; her yapının bir aydınlık bir de
gölgeli yüzü var, yere uzun olmayan net gölgeler düşüyor.

DERİNLİK: Öndeki yapılar arkadakileri kısmen kapatıyor; kasabanın uzak ucu
hafifçe pusa doğru soluyor.

HİSSİYAT: Küçük ama canlı, işleyen bir kasaba. Masalsı değil; çalışan,
tozlu, gerçek bir yer.
```

---

## 3. Ana Menü (oyunun kapağı)

```
[ORTAK BAĞLAM]

SAHNE: Oyunun ana menü arka planı. Tek kare, 16:9. Bu bir "kapak resmi":
oyunun ne olduğunu tek bakışta anlatmalı.

KOMPOZİSYON:
- Geniş, boş, biraz ürkütücü bir manzara. Alçak bir tepenin üstünden
  bakıyoruz.
- Ortada-sağda, aşağıda, küçük görünen bir kervan: bir atlı, birkaç yaya,
  iki öküz arabası. Kadrajda KÜÇÜKLER — manzara onlardan çok daha büyük.
  Bu oranın kendisi oyunun konusu: dünya büyük, kervan küçük.
- Kervan, ufka doğru kıvrılarak uzanan bir toprak yolun üstünde.
- Uzakta, yolun bittiği yerde, pusun içinde bir şehir silueti: sur ve
  kuleler. Ulaşılacak yer görünüyor ama uzak.
- Gökyüzü kadrajın çoğunu kaplıyor: gün batımı. Alt tarafta sıcak turuncu
  ve soluk altın, yukarı çıkıldıkça derin mavi-mor. Birkaç uzun, yatay,
  koyu bulut şeridi.
- Ön planda, kadrajın alt kenarında, koyu siluet halinde birkaç kuru ot ve
  bir yol taşı/kilometre taşı — çerçeveyi kapatıyor.

IŞIK: Arkadan (ufuktan) gelen ışık. Kervan ve ön plan neredeyse siluet;
kenarlarında ince sıcak bir kontur ışığı var.

KOMPOZİSYON NOTU: Kadrajın SOL ÜÇTE BİRİ görece sade ve koyu kalmalı —
oyunun adı ve menü tuşları oraya gelecek. Oraya önemli bir görsel öğe
koyma.

HİSSİYAT: Yolun başındaki an. Umut değil tam olarak; kararlılık. Yorgun
bir güzellik.
```

---

## Çalışmayan promptlar için notlar

Görsel modeller şu üç şeyde tökezliyor, tekrar denerken bunları açıkça
yaz:

1. **Öküz at gibi çıkıyor.** "Omzunda belirgin bir hörgüç olan öküz,
   boynuzları yana açık, ata benzemeyen" diye ısrar et.
2. **Kervan çok kalabalık/kahramanca çıkıyor.** "En fazla iki araba, altı
   kişi, kimse zırhlı değil, kimse poz vermiyor" ekle.
3. **Stil 3D'ye ya da fotogerçekçiye kayıyor.** "Düz renk alanları, koyu
   kontur, gölgelendirme yok, doku yok" diye tekrarla; "vector
   illustration" ya da "flat illustration" kelimelerini ekle.
