# Kalan işler

Başlanmamış görevler: kullanıcının işi (S), kullanıcı kararı (CK), kullanıcının içeriği ya da lore (CI) ve yeni eklenen oyun hissi alt görevleri (N31a-f). Her birinin neden beklediği 'Kim' satırında.

Toplam: **25** görev. Belgeler `referans/belge_uret.py` ile `referans/gorevler.json`'dan üretilir.

## Paket P00

### Y-E06 · Lore'u kapat, sonra içerik yaz

- **Durum:** açık · **Öncelik:** P1 · **Paket:** P00 · **Kim:** kullanıcının işi
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)

<details><summary>Görev metni</summary>

- [ ] **Y-E06 Lore'u kapat, sonra içerik yaz**
  - **Öncelik:** P1 · **Dalga:** 1
  - **Ne:** Önce lore: `SORULAR.md` coğrafya soruları, “Yolda doğan kim?” çelişkisi, şehir ve yer adlarının kesinleşmesi, tarihçe. Olay, düşman, zindan ve bölüm yazımı bundan sonra.
  - **Kullanıcı notu:** “kesinlikle öyle, lore'a odaklanacağız önce o yüzden.”
  - **Kabul:** SORULAR.md'de açık soru kalmadı; lore belgesi kullanıcı onaylı.

</details>

### Y-A06 · Haftalık playtest günlüğü ve beş dış oyuncu

- **Durum:** açık · **Öncelik:** P1 · **Paket:** P00 · **Kim:** kullanıcının işi
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)

<details><summary>Görev metni</summary>

- [ ] **Y-A06 Haftalık playtest günlüğü ve beş dış oyuncu**
  - **Öncelik:** P1 · **Dalga:** 1
  - **Ne:** Kullanıcı her hafta oyunu baştan bir saat oynar, sıkıldığı anları not eder ve oturumu video olarak kaydeder (devlog malzemesi). Ocak'tan önce beş dış oyuncu izlenerek oynatılır. Claude her döngüde bir oyun içi kontrol listesi hazırlar.
  - **Kullanıcı notu:** “Tamamdır, bunu da yapıp video alacağım hatta devlog olarak.”
  - **Kabul:** `docs/playtest/` altında tarihli günlük dosyaları; en az 5 dış oyuncu notu.
  - **Literatür:** R62, R78

</details>

## Paket P05

### Y-G03 · Saç ve başlıklar

- **Durum:** açık · **Öncelik:** P1 · **Paket:** P05 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** 2026-10-20 kullanıcı: lore'a bağlı değil.

<details><summary>Görev metni</summary>

- [ ] **Y-G03 Saç ve başlıklar**
  - **Öncelik:** P1 · **Dalga:** 6 · **İlgili:** 10.1, 10.2, 10.3
  - **Ne:** Kukuleta, kalpak, sarık, başörtüsü, miğfer, şapka; kültürlere göre dağılım. Gerçek dinî figür ya da yapıya gönderme yok.
  - **Kabul:** Yoldaki ve menülerdeki figürlerde kel manken kalmadı.
  - **Kaynaklar ve teknik (CC0 araştırması):** MakeHuman topluluk paketleri: **hair01** (CC0; 25 saç, örgüler), **bodyparts05** (CC0; sakal ve bıyık), **hats01** (CC0; çuval başlık, haydut için), **hats02** (CC0; miğferler, üzerindeki dinî sembol kaldırılıp yeniden dokulanır), **suits02** `monk_robe_hood` (CC0; kesimi sadeleştirilip kervan kukuletası olur). Künye zorunlu (CC-BY): **hats03** `elvs_charity_veil1` (başörtüsü), `mindfront_sherpa_hat` (kalpağa en yakın), **hats04** miğferler, hair02/03, bodyparts06. CC0 türban, sarık ve kalpak yok: Blender'da kapüşon kalıbından, torus ve kumaş simülasyonuyla modellenir; kalpak silindir ve kürk parçacığıyla. Mürekkep geçişinde kürk zaten taramaya döner, düşük detay yeter. `../ICERIK_IHTIYACLARI.md` G-1.

</details>

## Paket P07

### Y-C12 · Bölgesel itibar, hizipler ve jeopolitik yayılma

- **Durum:** açık · **Öncelik:** P2 · **Paket:** P07 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C01, Y-E06

<details><summary>Görev metni</summary>

- [ ] **Y-C12 Bölgesel itibar, hizipler ve jeopolitik yayılma**
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-C01, Y-E06
  - **Ne:** Tek global itibar yerine bölge ve hizip başına itibar (lonca, şehir yönetimleri, inanç toplulukları, haydut kardeşlikleri). Kullanıcı notu: bölgeler birbirinden ağırlıklı etkilenir; bir yerde kazanılan 5 itibar komşuya 0,5 olarak yayılabilir. Yayılma jeopolitik ilişkilere (komşuluk, ittifak, düşmanlık) göre ağırlıklandırılır.
  - **Kullanıcı notu:** “Evet, kesinlikle haklısın bu konuda ama bir bölgede çok itibarlı olup diğer bölgede hiç tanınmamak da olmaz. Birazcık da etkilenmeli bu bölgeler  birbirinden. Yani aradaki ilişki ağırlıklı olmalı, bir yerde 5 itibar kazanıyorsam diğer tarafta bu 0.5 olabilir. Jeopolitik olarak dağılmalı bu ilişki yani.”
  - **Kabul:** İtibar matrisi veri dosyasında; yayılma testli; mevcut kilitler (kontrat, kredi, vagon) yeni sisteme taşındı.
  - **Literatür:** R76

</details>

### Y-C13 · Adı olan, hatırlayan kişiler

- **Durum:** açık · **Öncelik:** P2 · **Paket:** P07 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C01

<details><summary>Görev metni</summary>

- [ ] **Y-C13 Adı olan, hatırlayan kişiler**
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-C01
  - **Ne:** Her şehirde 2–3 tekrar eden kişi: lonca ustası, tefeci, han sahibi. Oyuncuyu hatırlar, görev verir, yaşlanır, ölebilir.
  - **Kabul:** Kişiler kayıtta; en az bir kişisel zinciri olan kişi her şehirde.
  - **Literatür:** R13, R14

</details>

## Paket P08

### R3 · Merak ve töre

- **Durum:** öneri · **Öncelik:** Öneri · **Paket:** P08 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/10b_yol_deneyimi_onerileri.md](referans/gorevler/10b_yol_deneyimi_onerileri.md)
- **Bağımlı:** R0
- **Son not:** Bir kısmı yönetmen seçimleriyle onaylandı (bkz. YAPILACAKLAR.md, §10b eşlemesi); kalan maddeler öneri.

<details><summary>Görev metni</summary>

- [ ] **R3 Merak ve töre:** #12 kervan töresi, #17 anlatıcı ("yolun ruhu"), #9 belirsiz işaretler, #10 yol notları, #22 tepeye çık (vista).

</details>

### R5 · Büyük sahneler

- **Durum:** öneri · **Öncelik:** Öneri · **Paket:** P08 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/10b_yol_deneyimi_onerileri.md](referans/gorevler/10b_yol_deneyimi_onerileri.md)
- **Bağımlı:** R0

<details><summary>Görev metni</summary>

- [ ] **R5 Büyük sahneler:** #21 kervan mahkemesi, #13 sancak, #14 yol şarkısı (ses varlığına bağlı), #11 çatallar (en riskli).

</details>

## Paket P09

### Y-C06 · Ekipmanı 12 parçadan 35'in üstüne çıkar

- **Durum:** açık · **Öncelik:** P2 · **Paket:** P09 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)

<details><summary>Görev metni</summary>

- [ ] **Y-C06 Ekipmanı 12 parçadan 35'in üstüne çıkar**
  - **Öncelik:** P2 · **Dalga:** 4
  - **Ne:** Ağırlık takılarda: huylarla sinerji kuran, bedeli olan, lanetli parçalar.
  - **Kabul:** En az 35 parça; denge ölçümü güncel.
  - **Kaynaklar ve teknik (CC0 araştırması):** Eşya ikonları: game-icons.net siyah siluetleri mürekkep stiline uygun ama CC BY 3.0 (her ikonun yazarı künyeye). Alternatif: 3B prop render + mürekkep geçişi (Poly Haven, Quaternius Fantasy Props, MakeHuman equipment01: yay, savaş çekici, kaba kılıç, hançer, CC0). `../ICERIK_IHTIYACLARI.md` G-7.
  - **Literatür:** R79

</details>

### Y-C09 · Bölgesel düşman kimlikleri

- **Durum:** açık · **Öncelik:** P2 · **Paket:** P09 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06, Y-C01

<details><summary>Görev metni</summary>

- [ ] **Y-C09 Bölgesel düşman kimlikleri**
  - **Öncelik:** P2 · **Dalga:** 4 · **Bağımlı:** Y-E06, Y-C01
  - **Ne:** Her bölgede 2–3 özgün düşman; 14 şablondan 25'in üstüne. Kullanıcı notu: önce lore ve tarihçe tamamlanmalı.
  - **Kullanıcı notu:** “Bu aşama için lore ve tarihçenin tamamlanması lazım gibi.”
  - **Kabul:** Bölge başına düşman tablosu; lore belgesine uyuyor.
  - **Kaynaklar ve teknik (CC0 araştırması):** İnsan düşmanlar MPFB ve MakeHuman CC0 ekipmanla (equipment01), hayvanlar G-3 kaynaklarıyla. Ayı için iyi CC0 model yok (bkz. içerik raporu).
  - **Literatür:** R15

</details>

## Paket P10

### Y-D04 · Varis devralma sahnesi ve kısa video

- **Durum:** açık · **Öncelik:** P1 · **Paket:** P10 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)

<details><summary>Görev metni</summary>

- [ ] **Y-D04 Varis devralma sahnesi ve kısa video**
  - **Öncelik:** P1 · **Dalga:** 4 · **İlgili:** Y-C14, Y-J03
  - **Ne:** Yas sahnesi, defterde ismin canlı mürekkeple üstünün çizilmesi, kırık mühür, varis için ilk kart. Kullanıcı notu: buraya kısa bir video sahne eklenebilir (bir strateji klasiğindeki veraset ara sahneleri gibi). Önce sahne tahtası (storyboard) kullanıcıya sunulur; video üretimi ücretliyse maliyet onayı alınır.
  - **Kullanıcı notu:** “Kesinlikle buraya bir küçük video sahne eklenebilir medieval total war 2 gibi.”
  - **Kabul:** Onaylı sahne tahtası; oyunda sahne ve video; atlanabilir ama ilk seferde tam oynar.
  - **Kaynaklar ve teknik (CC0 araştırması):** Ücretsiz yol: oyun içi gerçek zamanlı sahne ya da Blender Grease Pencil ve kâğıt kesik tekniğiyle kısa video (J03 araçları). Sesler: Freesound CC0 `quill writing`, `wax seal`, `book close`.
  - **Literatür:** R60, R22, R76

</details>

## Paket P11

### Y-E04 · Yavaş açılan dünya sırrı

- **Durum:** açık · **Öncelik:** P2 · **Paket:** P11 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06

<details><summary>Görev metni</summary>

- [ ] **Y-E04 Yavaş açılan dünya sırrı**
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** Y-E06
  - **Ne:** İnançlar, nefes inancı ve nadir görülen varlık: kenar notları, söylentiler, parça parça bulgular. Açıklama değil, ipucu.
  - **Kullanıcı notu:** “Kesinlikle.”
  - **Kabul:** Sır belgesi (yalnızca geliştirici için) ve oyuna dağıtılmış en az 15 ipucu.
  - **Literatür:** R37, R38, R9

</details>

### Y-E08 · Takvim: bayramlar, fuarlar, hac dönemi

- **Durum:** açık · **Öncelik:** P3 · **Paket:** P11 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06

<details><summary>Görev metni</summary>

- [ ] **Y-E08 Takvim: bayramlar, fuarlar, hac dönemi**
  - **Öncelik:** P3 · **Dalga:** 5 · **Bağımlı:** Y-E06
  - **Ne:** Şehirlere özgü bayram ve fuarlar, mevsimin bölgesel etkisi.
  - **Kabul:** Takvim verisi ve en az 5 takvim olayı.

</details>

### Y-C18 · Kampanya bölümlerini yaz

- **Durum:** açık · **Öncelik:** P2 · **Paket:** P11 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06

<details><summary>Görev metni</summary>

- [ ] **Y-C18 Kampanya bölümlerini yaz**
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** Y-E06
  - **Ne:** Kullanıcı notu: bölümler henüz yazılmadı; bölüm sayısı ve sahneleme önerisi şimdilik onaylanmadı. Görev yalnızca bölümlerin yazılması. Sahneleme, final mekânı ve finalden sonrası, bölümler yazıldıktan sonra kullanıcıyla yeniden konuşulur.
  - **Kullanıcı notu:** “Evet bölümler yazılmadı o yüzden bana 8 bölüm var demen bile aslında uydurma bir veriye dayanıyor. Bu bölümler yazıldıktan sonra düşünülecek bir konu bu, onaylamıyorum bu konuyu o yüzden şu an. ama bölüm yazılacak gibi bir not alabilirsin.”
  - **Kabul:** Bölüm metinleri yazıldı ve kullanıcı onayladı.

</details>

## Paket P12

### Y-G04 · Büst portreler

- **Durum:** açık · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-G02, Y-G03
- **Son not:** MPFB2 eklentisi GPL lisanslı (CC0 değil); kullanıcının izni "CC0 ise indir" olduğu için indirilmedi. MPFB izni gelince figür hattıyla büst portre render edilir.

<details><summary>Görev metni</summary>

- [ ] **Y-G04 Büst portreler**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): MPFB2 yerelde kurulu değil; figür hattıyla yakın plan render + mürekkep geçişi için gerekli. Taslaklardaki (9.4, 9.6) portre yuvası bu render için.
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** Y-G02, Y-G03 · **İlgili:** 9.6, 9.7
  - **Ne:** Karakter, parti, taverna adayı ve mezar defteri için olay kartı üslubunda büst portreler.
  - **Kabul:** Portreler dört ekranda.
  - **Kaynaklar ve teknik (CC0 araştırması):** Portreler figür render'ının yakın planından mürekkep geçişiyle. Duruş ve tarama yönü için BHL, Rijksmuseum ve Met CC0 gravür portreleri yalnızca referans; kopyalanmaz. `../ICERIK_IHTIYACLARI.md` G-5.
  - **Literatür:** R26

</details>

## Paket P13

### Y-I01 · Ses tasarımı planı

- **Durum:** açık · **Öncelik:** P1 · **Paket:** P13 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)

<details><summary>Görev metni</summary>

- [ ] **Y-I01 Ses tasarımı planı**
  - **Öncelik:** P1 · **Dalga:** 6 · **İlgili:** Y-J05
  - **Ne:** Biyom ve gün saatine göre yol ambiyansı, tekerlek ve hayvan döngüleri, kamp ateşi, şehir uğultusu, kart açılış sesi. Kullanıcı notu: sesler Gemini ile üretiliyor ve sonuç iyi. Ses listesi ve üretim komutları hazırlanır; AI üretimi beyana girer (Y-J05).
  - **Kullanıcı notu:** “sesleri gemini ile yapıyorum ve güzel de sonuç alıyorum.”
  - **Kabul:** Ses listesi ve oyunda bağlı sesler.
  - **Kaynaklar ve teknik (CC0 araştırması):** Birincil CC0: Freesound (arama filtresi `license:"Creative Commons 0"`; indirilen seslerin listesi freesound.org/home/attribution), OpenGameArt CC0 paketleri (RPG Sound Pack, 80 CC0 RPG SFX, Kenney 50 RPG SFX, TinyWorlds ayak sesleri), Kenney ses paketleri, BigSoundBank. İkincil (atıfsız ama CC0 değil): Sonniss GDC paketi (YZ'ye örnek olarak verilmesi yasak → Gemini'ye beslenmez), Pixabay (hak talebinde kullanımı durdurma maddesi). Teknik: biyom × gün saati 30–90 sn döngüler, −20…−18 LUFS, döngü noktasında 1–2 sn eşit güç geçiş; bus yapısı `Master > Ambience > {Bed, Weather, Spot}`; Spot katmanında `AudioStreamRandomizer` (perde ±%5, ses ±3 dB, 8–25 sn aralık); olay kartı açılınca Ambience −6 dB; tekerlek gıcırtısının perdesi hıza bağlı, toynak adım başına randomizer. Gemini ile üretilen sesler künye dosyasında `kaynak: YZ (Gemini)`. `../ICERIK_IHTIYACLARI.md` S-1…S-6.
  - **Literatür:** R21

</details>

### Y-I02 · Yeni müzik dili: gerilim ve katmanlar

- **Durum:** açık · **Öncelik:** P2 · **Paket:** P13 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06

<details><summary>Görev metni</summary>

- [ ] **Y-I02 Yeni müzik dili: gerilim ve katmanlar**
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** Y-E06 · **İlgili:** Y-B02, Y-G16
  - **Ne:** Kullanıcı notu: eski şarkılar tarihçe belli olmadan yapıldı; ses tasarım tarzı tamamen değişecek, şarkılar çok daha gerilimli olacak ve ana menüde şarkı olmayacak. Gerilimde açılan katmanlar (Y-B02 eğrisine bağlı), ölüm ve yas teması.
  - **Kullanıcı notu:** “bu şarkılar yapıldığında tarihçe belli değildi. artık çok daha gerilim dolu şarkılar olacak ve ana menüde şarkı olmamalı mesela. ses tasarım tarzımız tamamen değişecek yani.”
  - **Kabul:** Yeni müzik kılavuzu; ana menüde müzik yok, ambiyans var.
  - **Kaynaklar ve teknik (CC0 araştırması):** CC0 müzik: RandomMind (OpenGameArt) “Lament for a Warrior's Soul” yas teması adayı; OpenGameArt CC0 dark ambient drone'lar. Hazır stem yok: drone + Freesound CC0 tek vuruşlardan (frame drum, taiko, bodhran) 90 BPM döngüler + CC0 cello drone ve bowed metal gerilim katmanı, hepsi aynı tonalitede. Godot 4.2'de `AudioStreamSynchronized` yok (4.3+): ya sürüm yükseltme (P00 kararı) ya da aynı anda başlatılan birden çok `AudioStreamPlayer`. FreePD kapandı, kullanılmaz. `../ICERIK_IHTIYACLARI.md` S-7.
  - **Literatür:** R18

</details>

### Y-I03 · Kâtibin sesi: kısa anlatıcı satırları

- **Durum:** açık · **Öncelik:** P3 · **Paket:** P13 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)

<details><summary>Görev metni</summary>

- [ ] **Y-I03 Kâtibin sesi: kısa anlatıcı satırları**
  - **Öncelik:** P3 · **Dalga:** 6 · **İlgili:** Y-J05
  - **Ne:** Kritik anlarda kısa, kuru anlatıcı satırları; önce Türkçe ve İngilizce. Kullanıcı kararı: AI ile seslendirilebilir; beyan edilir.
  - **Kullanıcı notu:** “görüntülerde ai içerği mevcut zaten, yani hali hazırda ai beyanı koymam lazım değil mi? o zaman sesi de yaparız ai ile sorun yok.”
  - **Kabul:** Satır listesi ve kayıtlar; beyan güncel.
  - **Kaynaklar ve teknik (CC0 araştırması):** CC0 anlatıcı sesi yok. Kokoro-82M (Apache-2.0) yalnızca İngilizce, Türkçe yok; Piper `lessac` sesi ticari kullanıma kapalı. Gemini sesi Steam beyanına girer. `../ICERIK_IHTIYACLARI.md` S-8.
  - **Literatür:** R22

</details>

## Paket P15

### Y-J01T · Steam sayfası Aralık'ta

- **Durum:** açık · **Öncelik:** P1 · **Paket:** P15 · **Kim:** kullanıcının işi
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-G13

<details><summary>Görev metni</summary>

- [ ] **Y-J01T Steam sayfası Aralık'ta**
  - **Öncelik:** P1 · **Dalga:** 7 · **Bağımlı:** Y-G13
  - **Köken:** onaylanmayan **J01** önerisinin altındaki kullanıcı notu.
  - **Ne:** Kullanıcı notundan türetildi: geliştirici hesabı ücreti şimdi harcanmayacak; sayfa Aralık gibi açılacak ve pazarlama o zaman başlayacak. Hazırlık şimdiden: sayfa metni, etiket önerisi, görsel listesi. Next Fest kaydı için Valve'ın son tarihleri kontrol edilir.
  - **Kullanıcı notu:** “steam hesabı para gerekitiriyor biraz ve şu an istemiyorum bunu harcamayı. aralık gibi açmak istiyorum sayfayı. bu yüzden de pazarlamasını o zaman bırakıyorum.”
  - **Kabul:** Aralık'ta Coming Soon sayfası açık; Next Fest kaydı yapıldı.
  - **Literatür:** R56, R61

</details>

### Y-J02 · Kapsül sanatı

- **Durum:** açık · **Öncelik:** P1 · **Paket:** P15 · **Kim:** kullanıcının işi
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-G08

<details><summary>Görev metni</summary>

- [ ] **Y-J02 Kapsül sanatı**
  - **Öncelik:** P1 · **Dalga:** 7 · **Bağımlı:** Y-G08
  - **Ne:** Logo, fener amblemi ve kervan silueti; küçük boyutta okunur. İnsan eliyle yapılması önerilir. Ücretliyse önce maliyet tahmini ve onay.
  - **Kullanıcı notu:** “olabilir.”
  - **Kabul:** Kapsül seti (bütün Steam boyutları) onaylı.
  - **Kaynaklar ve teknik (CC0 araştırması):** Steam kapsül ölçüleri: Header 920×430, Small 462×174, Main 1232×706, Vertical 748×896; yalnızca sanat ve logo, metin yok. `../ICERIK_IHTIYACLARI.md` G-9.
  - **Literatür:** R58, R59, R70

</details>

### Y-J03 · Fragman ve menü öncesi açılış videosu

- **Durum:** açık · **Öncelik:** P1 · **Paket:** P15 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-D04, Y-G13

<details><summary>Görev metni</summary>

- [ ] **Y-J03 Fragman ve menü öncesi açılış videosu**
  - **Öncelik:** P1 · **Dalga:** 7 · **Bağımlı:** Y-D04, Y-G13
  - **Ne:** Kanca ilk 10–15 saniyede: “kervan başı ölür, varis devralır”; oyun içi görüntü. Kullanıcı notu: bu türün oyuncuları menüden önce oynayan fragmanları seviyor; aynı malzemeden oyunun açılışında atlanabilir bir giriş videosu.
  - **Kullanıcı notu:** “bu türde oyun oynayanlar menü öncesi fragmanları beğeniyor.”
  - **Kabul:** Mağaza fragmanı ve oyun açılış videosu.
  - **Kaynaklar ve teknik (CC0 araştırması):** Ham görüntü Godot `--write-movie` ile; Blender Grease Pencil (haritada mürekkep çizgisinin akarak ilerlemesi, Build modifier) ve VSE kurgu; Krita çerçeve animasyonu; kâğıt kesik tekniği: sprite parçaları düzlemlere, 12 fps. `../ICERIK_IHTIYACLARI.md` G-10.
  - **Literatür:** R60

</details>

### Y-J10 · Fiyat ve Erken Erişim zamanı kararı

- **Durum:** açık · **Öncelik:** P2 · **Paket:** P15 · **Kim:** kullanıcının işi
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)

<details><summary>Görev metni</summary>

- [ ] **Y-J10 Fiyat ve Erken Erişim zamanı kararı**
  - **Öncelik:** P2 · **Dalga:** 7
  - **Ne:** Kullanıcı sorusu: 2–5 $ fiyat da çok görülüyor. Karar, oyunun gerçek oynanma süresi ölçüldükten sonra verilir. Erken Erişime içerik hazırken girilir; çıkış haftası büyük çıkışlarla çakışmaz.
  - **Kullanıcı notu:** “fiyattan emin miyiz? 2-5 usd arası fiyat da çok görüyorum indie oyunlarda.”
  - **Kabul:** Fiyat kararı ve gerekçesi yazıldı.
  - **Literatür:** R27, R28, R31

</details>

### Y-J12 · Basın kiti, web sitesi, e-posta listesi, Discord

- **Durum:** açık · **Öncelik:** P2 · **Paket:** P15 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-J01T

<details><summary>Görev metni</summary>

- [ ] **Y-J12 Basın kiti, web sitesi, e-posta listesi, Discord**
  - **Öncelik:** P2 · **Dalga:** 7 · **Bağımlı:** Y-J01T
  - **Ne:** waybornegame.com'da tek sayfa: fragman, görseller, Steam bağlantısı, e-posta kaydı; indirilebilir basın kiti.
  - **Kabul:** Site ve basın kiti yayında.
  - **Literatür:** R59

</details>

### Y-J08 · Düzenli devlog

- **Durum:** açık · **Öncelik:** P2 · **Paket:** P15 · **Kim:** kullanıcının işi
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-J01T

<details><summary>Görev metni</summary>

- [ ] **Y-J08 Düzenli devlog**
  - **Öncelik:** P2 · **Dalga:** 7 · **Bağımlı:** Y-J01T
  - **Ne:** Harita süreci, oyunda yaşanan hikâyeler, defter sayfaları, haftalık playtest videoları (Y-A06). Aralık'ta sayfa açılınca başlar.
  - **Kabul:** Yayın takvimi; ilk üç devlog.
  - **Literatür:** R11, R56

</details>

### Y-J06 · Görünür AI sanatını elle yeniden çizme (sonra)

- **Durum:** açık · **Öncelik:** P2 · **Paket:** P15 · **Kim:** kullanıcının işi
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)

<details><summary>Görev metni</summary>

- [ ] **Y-J06 Görünür AI sanatını elle yeniden çizme (sonra)**
  - **Öncelik:** P2 · **Dalga:** 7
  - **Ne:** Kullanıcı notu: oyun bittikten sonra, belki Kasım sonu; görseller elle yeniden çizilebilir ve içerik “AI üretimi” değil “AI destekli” olur. Hazırlık: AI ile üretilen görsellerin listesi tutulur. Not: AI çıktısının üzerinden çizilen görseller de beyan formunda bildirilmeye devam edebilir; form doldurulurken güncel Steam metnine bakılır.
  - **Kullanıcı notu:** “Bu daha sonra yapılacka bir düzenleme ve emin değilim. önce oynu bitirelim sonra aynı görselleri elle çizebilirim yani sonuç olarak içerik ai üretimi değil, ai destekli olur. ama Kasım sonunda filan olabilir bu anca.”
  - **Kabul:** AI görsel listesi güncel; yeniden çizim kararı verildi.
  - **Literatür:** R70, R71, R69

</details>

## Paket P18

### N32 · Nemesis benzeri NPC hafıza sistemi: tasarım

- **Durum:** açık · **Öncelik:** P2 · **Paket:** P18 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Son not:** Kullanıcı isteği (2026-10-19): Shadow of Mordor/War Nemesis; lore'a bağlı.

<details><summary>Görev metni</summary>

- [ ] **N32 Nemesis benzeri NPC hafıza sistemi: tasarım** (`CK`)
  - **Sütun:** Defter unutmaz · Yol yaşar
  - **Ne:** Shadow of Mordor/War'un Nemesis sisteminden esinle, yolda karşılaşılan kişilerin (eşkıya reisi, muhafız çavuşu, tüccar, yoldaş adayı) oyuncuyu hatırlaması: kaçan ya da yenilen düşman adıyla, yarasıyla ve kinle geri döner; terfi eder, çetesi büyür; kurtarılan ya da kandırılan kişi sonra iyilikle ya da intikamla karşına çıkar. Sistem olarak mı, hikâye kurgusu olarak mı (ya da ikisi) yapılacağı kullanıcı kararı.
  - Mevcut zemin: `CaravanLedger` (dünyanın hafızası), `NpcDisposition` ve `ROLL_ENCOUNTER`, gecikmeli zincir olaylar (`evt_wanderer_revenge`), `EnemyCatalog` yöre reskin'leri, şikâyetler (grievances). Kural: yeni sistem icat etmez, olay sözlüğüyle (`EventEffect`) konuşur; adlı NPC'ler kayıtta tutulur, yeniden yüklemeyle değişmez.
  - **Kabul:** `docs/design_notes/nemesis_npc_plani.md` (seçenekler, lore'a bağımlılık, maliyet) ve kullanıcı kararından sonra alt görevler. Lore'a bağlı (Lore önce kuralı).

</details>
