# Yarım kalan ve onay bekleyenler

Benim payım bitmiş ama kullanıcı onayı (taslak, tasarım notu, plan), indirme izni, lore ya da dış test bekleyen görevler; bir de kısmen yapılmış olanlar. Her birinde ne yapıldığı ve ne kaldığı yazıyor.


### İndirme durumu (2026-10-19)

Kullanıcı izniyle (yalnız CC0) indirilenler: Kenney UI Pack RPG Expansion, Fantasy UI Borders, Graveyard Kit, Impact Sounds, Castle Kit ve Poly Haven Lantern 01 (`araclar/indirilenler/`, kopyaları `wayborne/art_source`). İndirilmeyenler: MPFB2 (GPL, CC0 değil: Y-G04, Y-G12) ve Freesound sesleri (giriş gerekli). Hepsi CC0 ya da OFL; boyutlar yaklaşık, indirmeden önce lisans sayfası ve gerçek boyut kontrol edilir.

| Kaynak | Ne için | Görev | Lisans | Yaklaşık boyut |
|---|---|---|---|---|
| Kenney UI Pack RPG Expansion | panel çerçevesi, başlık şeridi, düğme durumları (mürekkep diline boyanır) | 9.1 | CC0 | ~1 MB |
| Kenney Fantasy UI Borders | 140 çerçeve, seçim köşebentleri | 9.1 | CC0 | ~2 MB |
| Kenney Graveyard Kit | mezar taşı, çit, kripta (dini sembol çıkarılır) | 9.12 | CC0 | ~5 MB |
| Poly Haven `Lantern_01` | fener amblemi ve menü feneri | Y-G08 | CC0 | ~20 MB (2K doku) |
| MPFB2 (Blender eklentisi) + temel varlık paketi | büst portre render'ı (figür hattıyla) | Y-G04 | GPL eklenti, CC0 varlık | ~60 MB |
| Kenney Impact Sounds | vuruş sesi katmanları | Y-H05 | CC0 | ~2 MB |
| Freesound CC0: `sword clash`, `arrow impact`, `campfire`, `large wooden door`, `chain rattle`, `winch` | vuruş, menü ateşi, şehir kapısı sesi | Y-H05, Y-G16, 12.2a | CC0 | ~10 MB; Freesound giriş istiyor, sen indirmelisin |
| Kenney Castle Kit (tam) | kapı sahnesinde alternatif sur ve kule | 12.2a (isteğe bağlı) | CC0 | ~10 MB |
| Y-H02 İlk 10 dakikanın çizelgesi | Hedefler 3/10/30 dk ve ilk on dakikanın akışı. Soru: ilk seferde ilk tehdidi yönetmen öne çeksin mi? | test sonrası | ☐ |
| Y-G13 Kimliği tanımlayan beş ana görsel (taslak) | 1 gece haritası ve fenerli atlı, 2 kamp ateşi, 3 tam ekran olay kartı, 4 defter ve kırık mühür, 5 kapıya varış. Soru: beşinin sırası mağazada bu mu (ilk ikisi yol ve olay kartı istenmişti)? | test sonrası | ☐ |
| Y-J04 Demo ve Next Fest planı | Fest boyunca demo (Şubat 2027), EA festten 4-10 hafta sonra; demo iki bölge 2-3 sefer. Kullanıcının festte EA fikri kurala takılıyor. Soru: kabul mü? | test sonrası | ☐ |

### Karar soruları (CK ve CI, ayrıntısı KALAN_ISLER.md)

Bu işleri toplu çalışmada yapmadım: ya senin kararın (CK) ya da lore ve içerik kararın (CI) gerekiyor. Her biri için
tek soru; cevabın gelince sırayla yapılır.

| Görev | Soru |
|---|---|
| 6.1 LFS ve `.gitattributes` | Büyük ikili dosyalar (atlas sayfaları, kasaba resimleri) Git LFS'e taşınsın mı? GitHub LFS kotası ücretli olabilir. |
| 2.1 Dışa aktarımdan test ve araçlar | `tests/` ve `tools/` dışa aktarımdan çıkarılsın mı (Web/PC derlemesi küçülür)? |
| Y-K03 Oyun ölçümü | Oyuncu testinde anonim süre verisi (Y-H02 dosyası) sana gönderilsin mi, yoksa yalnız yerelde mi kalsın? |
| 3.6, 3.4, 2.3 Ölü araç ve varlıklar | Kalan eski araç ve varlıklar arşive mi (`docs/history`), silinsin mi? |
| 4.4 Olay anahtarları | `event_catalog.gd`'de `"%s_TITLE"` ile kurulan anahtarlar kasıtlı bir istisna mı, yoksa açık yazılsın mı? |
| 2.5 Yıpranma efekti | Stres kenarı kaldırıldı, açlık kenarı kaldı (senin kararın). Açlık kenarı da kalksın mı? |
| 5.2, 5.4 Mipmap ve atlas paketleme | Doku ayarlarını içe aktarma tarafına almak ve atlasları sıkı paketlemek resimleri yeniden üretmek demek; şimdi mi, demo öncesi mi? |
| 8.7 Boğazın adı | Haritada geçici "Kesgrav Boğazı" yazıyor. Ne ad olsun? |
| Y-G03 Saç ve başlıklar | Saç modülleri (MPFB) indirme izni ve hangi saç stilleri? |
| Y-C12 Bölgesel itibar ve hizipler | Kaç hizip, hangileri (lore)? Bölge başına itibar mı, hizip başına mı? |
| Y-C13 Adı olan kişiler | Her şehirde 2-3 kişi: lonca ustası, tefeci, han sahibi. Adları ve kişilikleri sen mi yazarsın, ben taslak mı çıkarayım? |
| Y-B08 Günün satırı | Her akşam günün olayı deftere tek cümle. Oyuncu satırı düzeltebilsin mi (metin girişi)? |
| R3 Merak ve töre | Kervan töresi, anlatıcı ("yolun ruhu"), belirsiz işaretler, yol notları, tepeye çıkma: hangileri? |
| R5 Büyük sahneler | Kervan mahkemesi, sancak, yol şarkısı, çatallar: hangileri, hangi sırayla? |
| Y-C06 Ekipman 35+ parça | Yeni parçaların adları ve kültür dağılımı (lore) senden mi? |
| Y-C09 Bölgesel düşman kimlikleri | Bölge başına hangi düşmanlar (lore)? |
| Y-D04 Varis devralma sahnesi ve video | Sahnenin kurgusu: kısa sinematik mi, defter sayfası mı? |
| Y-E04 Yavaş açılan dünya sırrı | Sır ne (lore)? |
| Y-E08 Takvim | Şehirlerin bayram ve fuarları (lore); hac dönemi dinî sembolsüz nasıl anlatılsın? |
| Y-C18 Kampanya bölümleri | Bölüm metinleri sen mi yazarsın, taslak mı? |
| Y-I01, Y-I02, Y-I03 Ses, müzik, kâtip sesi | AI ses kullanılacak (Y-I03 cevabın). Hangi araç ve bütçe? Müzik dili için örnek parça? |
| Y-J03, Y-J12 Fragman ve basın kiti | Aralık'ta (senin notun); kliplenebilir anlar listesi hazır (Y-J09). |
| N32 Nemesis benzeri NPC hafızası | Sistem mi (adlı düşmanlar terfi eder, geri döner), hikâye kurgusu mu, ikisi mi? Uzun zincir altyapısı (Y-E02) buna zemin. |



Toplam: **34** görev. Belgeler `referans/belge_uret.py` ile `referans/gorevler.json`'dan üretilir.

## Paket P00

### Y-E06 · Lore'u kapat, sonra içerik yaz

- **Durum:** lore kapandı, hikâye kullanıcıda · **Öncelik:** P1 · **Paket:** P00 · **Kim:** kullanıcının işi
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** 2026-11-07: dünya kitabı tek belgede toplandı (docs/lore/SIDERIA.md). Dört parça (LORE, TARIHCE, SORULAR, ONERILER_III) birleştirildi ve silindi; bütün çelişkiler (Ç1-Ç14) çözüldü, onay bekleyen öneriler kullanıcının yetkisiyle karara bağlandı ([Karar]). Kalan: kadim uygarlığın sonu (kullanıcıda, oyunda hiç söylenmeyecek) ve oyunun hikâyesi, kampanyası ve diyalogları (kullanıcı kendisi yazacak). Olay, düşman ve metin yazımı artık SIDERIA.md'den üretilir.

<details><summary>Görev metni</summary>

- [ ] **Y-E06 Lore'u kapat, sonra içerik yaz**
  - **Lore kapandı, hikâye kullanıcıda** (2026-11-07): evrenin tek belgesi `docs/lore/SIDERIA.md`. Dört parça (LORE, TARIHCE, SORULAR, ONERILER_III) orada birleştirildi ve silindi; Ç1-Ç14 çözüldü, onay bekleyen öneriler kullanıcının yetkisiyle karara bağlandı.
  - **Öncelik:** P1 · **Dalga:** 1
  - **Ne:** Önce lore: coğrafya, tarih, inançlar, bölgeler ve yerleşimler tek belgede; sonra içerik. Olay, düşman ve diyalog yazımı o belgeden üretilir.
  - **Kullanıcı notu:** “kesinlikle öyle, lore'a odaklanacağız önce o yüzden.”
  - **Kabul:** SIDERIA.md'de açık lore sorusu kalmadı (kalan iki madde kullanıcıda: kadim uygarlığın sonu, hikâye ve kampanya).

</details>

### Y-R01 · Ahlak/Ruh/İz: §E'nin 50 satırını kartlara işle

- **Durum:** yapılacak · **Öncelik:** P1 · **Paket:** P00 · **Kim:** kullanıcının işi
- **Ayrıntı ve geçmiş:** [referans/gorevler/19_ahlak_ruh_iz.md](referans/gorevler/19_ahlak_ruh_iz.md)
- **Son not:** H1-H12 bitti (bkz. docs/design_notes/ahlak_ruh_iz_mimarisi.md). Mekanizma kurulu ve ölçülüyor; eksik olan hacim: 101 kartın yalnız on ikisi iz bırakıyor. simulate_career (40 sefer, sert politika): doğan 6,1 · dönen 2,5 · sönen 2,6 · dönüşe 34 gün; §G.2'nin hedefi 12-22 dönüş. Her kart §E matrisindeki satırına göre IZ_BIRAK alacak.

### Y-R02 · Yankı varyantlarını seçeneğe göre yaz

- **Durum:** yapılacak · **Öncelik:** P1 · **Paket:** P00 · **Kim:** kullanıcının işi
- **Ayrıntı ve geçmiş:** [referans/gorevler/19_ahlak_ruh_iz.md](referans/gorevler/19_ahlak_ruh_iz.md)
- **Son not:** H9'da 22 kartın her birine bir yankı cümlesi yazıldı (gövdenin sonuna). §D-A4 ayrıca cevaba göre varyant istiyor (<id>_YANKI_<secim>); bedel kayması zaten cevaba bakıyor, metin henüz bakmıyor.

### Y-R03 · Reddedilen fikirler: yeniden önerilmesin

- **Durum:** kapandı · **Öncelik:** P1 · **Paket:** P00 · **Kim:** kullanıcının işi
- **Ayrıntı ve geçmiş:** [referans/gorevler/19_ahlak_ruh_iz.md](referans/gorevler/19_ahlak_ruh_iz.md)
- **Son not:** §I'nin on üç maddesi (görünür ahlak çubuğu/karma puanı; akıl sağlığı sayacı ve yalan söyleyen arayüz; liderin kendi başına karar vermesi; olay kartıyla ölüm; bir sistemi kaldırarak dengelemek; her NPC ile tam ilişki grafiği; yoldaşlar arası aşk/evlilik/çocuk; rastgele kelebek etkileri; bölümlü ahlaki hikâye ve iyi/kötü son; şehir yönetimi katmanı; yamyamlık ve benzeri şok seçenekleri; yeni harcanabilir kaynak (vicdan/umut); hâl için yeni ikon seti ve renk kodu) **uygulanmadı ve uygulanmayacak**. Gerekçeleri tasarım notunun §I'sinde; dördü doğrudan anayasa ihlali (A1, A2, A4, A5). Yeniden öneri gelirse önce oraya bakılır.

## Paket P01

### Y-K02 · Otomatik ekran görüntüsü karşılaştırması

- **Durum:** iptal · **Öncelik:** P1 · **Paket:** P01 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Araç ve iş akışı hazır; GitHub Actions koşusu push sonrası (TEST_PLANI.md). | 2026-11-01 kullanıcı: gerek yok, kaldırıldı (tools/ci ve iş akışındaki karşılaştırma adımları silindi; fotoğraf çekimi ve betik hatası kapısı kaldı).

<details><summary>Görev metni</summary>

- [x] **Y-K02 Otomatik ekran görüntüsü karşılaştırması**
  - **İptal (kullanıcı, 2026-11-01):** gerek yok; karşılaştırma aracı (`tools/ci`) ve iş akışındaki karşılaştırma adımları
    silindi. `screenshots.yml` yalnızca fotoğraf çekip betik hatası arıyor.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `6868274`): Araç ve iş akışı hazır; GitHub Actions koşusu push sonrası (TEST_PLANI.md).
  - **Öncelik:** P1 · **Dalga:** 1
  - **Ne:** Kritik ekranlar her derlemede GitHub Actions'ta çekilip önceki sürümle karşılaştırılır; görsel bozulmalar yakalanır.
  - **Kabul:** CI'da görsel karşılaştırma adımı; fark raporu artefakt olarak.

</details>

## Paket P02

### 4.3 · Tekrarlanan yardımcıları birleştir

- **Durum:** iptal · **Öncelik:** P2 · **Paket:** P02 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/04_kod_kalitesi.md](referans/gorevler/04_kod_kalitesi.md)
- **Son not:** reduce_motion NodeUtil'de; autoload kopyaları bilerek kaldı; CI birleştirme GitHub'da doğrulanamadığı için yapılmadı. | 2026-11-02: T16-10 görevine taşındı.

<details><summary>Görev metni</summary>

- [ ] **4.3 Tekrarlanan yardımcıları birleştir** (§3C)
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `3e35324`): reduce_motion NodeUtil'de; autoload kopyaları bilerek kaldı; CI birleştirme GitHub'da doğrulanamadığı için yapılmadı.
  - `TextureLoader.load_any` (5 kopya), `_reduce_motion` (4), `_clear_children` (8), işe alma düğmesi (3), `tr` sarmalayıcıları (4), `_with_mipmaps` (2).
  - CI adımlarını tek bir reusable workflow'a topla.

</details>

## Paket P07

### Y-C12 · Bölgesel itibar, hizipler ve jeopolitik yayılma

- **Durum:** iptal · **Öncelik:** P2 · **Paket:** P07 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C01, Y-E06
- **Son not:**  | 2026-11-02: T16-07 görevine taşındı.

<details><summary>Görev metni</summary>

- [ ] **Y-C12 Bölgesel itibar, hizipler ve jeopolitik yayılma**
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-C01, Y-E06
  - **Ne:** Tek global itibar yerine bölge ve hizip başına itibar (lonca, şehir yönetimleri, inanç toplulukları, haydut kardeşlikleri). Kullanıcı notu: bölgeler birbirinden ağırlıklı etkilenir; bir yerde kazanılan 5 itibar komşuya 0,5 olarak yayılabilir. Yayılma jeopolitik ilişkilere (komşuluk, ittifak, düşmanlık) göre ağırlıklandırılır.
  - **Kullanıcı notu:** “Evet, kesinlikle haklısın bu konuda ama bir bölgede çok itibarlı olup diğer bölgede hiç tanınmamak da olmaz. Birazcık da etkilenmeli bu bölgeler  birbirinden. Yani aradaki ilişki ağırlıklı olmalı, bir yerde 5 itibar kazanıyorsam diğer tarafta bu 0.5 olabilir. Jeopolitik olarak dağılmalı bu ilişki yani.”
  - **Kabul:** İtibar matrisi veri dosyasında; yayılma testli; mevcut kilitler (kontrat, kredi, vagon) yeni sisteme taşındı.
  - **Literatür:** R76

</details>

### Y-C13 · Adı olan, hatırlayan kişiler

- **Durum:** iptal · **Öncelik:** P2 · **Paket:** P07 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-C01
- **Son not:**  | 2026-11-02: T16-09 görevine taşındı.

<details><summary>Görev metni</summary>

- [ ] **Y-C13 Adı olan, hatırlayan kişiler**
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-C01
  - **Ne:** Her şehirde 2–3 tekrar eden kişi: lonca ustası, tefeci, han sahibi. Oyuncuyu hatırlar, görev verir, yaşlanır, ölebilir.
  - **Kabul:** Kişiler kayıtta; en az bir kişisel zinciri olan kişi her şehirde.
  - **Literatür:** R13, R14

</details>

### Y-C21 · Kıtayı saran kıtlık: ticaret değil ulaştırma, şehirlerin morali

- **Durum:** kısmen · **Öncelik:** P1 · **Paket:** P07 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06
- **Son not:** 2026-10-29 kullanıcı notu: kıtlığı tetikleyen kıta çapında bir olay, savaşların kökü; ticaret sınırlanır, odak kervanı ulaştırmak; şehir morali/mentali. Önce sebep (lore) ve ölçek kararı. | 2026-11-01: mekanik oyunda (Scarcity, şehir morali); sebep lore kararı bekliyor (defter III).

<details><summary>Görev metni</summary>

- [ ] **Y-C21 Kıtayı saran kıtlık: ticaret değil ulaştırma, şehirlerin morali**
  - **Öncelik:** P1 · **Dalga:** 2 · **Bağımlı:** Y-E06 · **İlgili:** Y-C12, Y-C15, Y-C13, Y-B06, Y-B07
  - **Ne:** Mekanik revizyon, üç parça:
    1. **Kıtlığın sebebi.** Kıtlığı başlatan, bütün kıtayı etkileyen bir olay olmalı: büyülü ve devasa bir olay ya da mevsimlerin değişmesi. Savaşların hepsi temelde bu kıtlıktan doğar. Sebep lore kararıdır (soru defteri v2'de soruldu). Oyunda dünyanın bir durumu olarak yaşar: hasat, stok ve fiyat katmanı, haber kartları ve savaş haberlerinin kökü. Lore'daki "Vadi kıtada en çok kıtlık yaşayan bölge" bilgisi bunun bölgesel yüzü olur.
    2. **Ticaret sınırlanır, odak ulaştırmak olur.** Oyunun merkezi al-sat kârı değil, kervanı bir noktadan öbürüne sağ salim götürebilmek. Pazarda az mal, yüksek fiyat ve satıcının satmak istememesi; kontrat ve ulaştırma geliri ana gelir; yük bir yerin hayatta kalması demek. Sistemler kesilmez (kullanıcının ilkesi: derinleşme, asla sadeleştirme): ticaret kalır ama kıt ve pahalı olur. "Ticaret bilgi oyunudur" sütunu kıtlıkta şu anlama gelir: nerede ne kaldığını bilmek.
    3. **Şehirlerin morali ve hâli.** Her şehir arka planda bir moral/mental durum taşır (açlık, umut, öfke gibi). Kervan oraya gıda ve gerekli malı ulaştırınca bu durum düzelir. Bu durum şehirdeki olayları (isyan, veba, yağma, bayram), kapıdaki karşılamayı, fiyatları, işe alınabilecek insanları ve şehrin kervana yaklaşımını değiştirir. Y-C12'nin bölgesel itibarıyla birlikte tasarlanır: itibar şehrin kervan hakkında ne düşündüğü, moral şehrin kendi hâli.
  - **His:** Kıtlık ve yokluk oyunda bütün ağırlığıyla hissedilmeli. Hiçbir şey kolay olmamalı: mekanikler ve ortam (görsel, ses, metin, şehir hâli, yol kenarındaki açlar) bu hissi birlikte aktarmalı.
  - **Kullanıcı notu:** "Kıtada kıtlığı tetikleyen bir olay olmalı. Bu büyülü devasa bir olay olabilir, mevsimler değişiklikler olabilir ama tüm kıta bundan etkilenmeli. Temelinde tüm savaşlar bu kıtlıktan sebep olarak çıkmalı. Kıtlık sebebiyle ticaret tarafı limite edilmeli, oyunun odağı ticaret yapmak değil kervanı gerçekten bir noktadan diğerine başarılı bir şekilde götürebilmek olmalı. Belki şehirlerin de morali, mentali tutulmalı arkaplanda ve kervanı oraya iletebilirsek bu statlara katkıda bulunuruz. bu statların seviyesi de o şehirde olan olayları ve bize yaklaşımlarını etkiler. Sonuç olarak o kıtlığı ve yokluğu oyunda cabasıya hissetmeliyiz! Yaptığımız hiçbir şey kolay olmamalı ve mekanikler+ortam bu hissi aktarmalı bize."
  - **Karar gerekenler:** kıtlığın sebebi ve başlangıcı (lore); kıtlık sabit mi, dalgalı mı, oyun boyunca kötüleşiyor mu; şehir moralinin kaç ekseni olacağı; ölçüm (simulate_career'da kârın düşüşü, sefer başı ölüm ve açlık).
  - **Kabul:** Dünyada bir kıtlık durumu ve kökü; savaş haberleri ona bağlı; pazarda kıtlık katmanı (`price_layers` yeni katman); şehir başına kayıtlı moral değeri, ulaştırmayla değişiyor, olay ağırlıklarını ve karşılamayı etkiliyor; simülatörde ticaret payı düştü, ulaştırma geliri öne geçti; ekran görüntüsüyle şehir hâli görünüyor.

</details>

### Y-C31 · Geçiş belgesi

- **Durum:** lore bekliyor · **Öncelik:** P2 · **Paket:** P07 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Bağımlı:** Y-E06
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-11-01: geçiş belgelerinin adları ve sahipleri defter III'te; cevap gelince yapılır.

<details><summary>Görev metni</summary>

- [ ] **Y-C31 Geçiş belgesi**
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-E06 · **Kim:** C
  - **Ne:** Orbeyan tamgası, Ezmerak boynuz fişi, Ayazkaya bedel taşı ve Avuçiçi zili tek sistem: yolun sahibi güce ödenir, karşılığında süreli belge alınır, deftere yazılır. Lore taslakları defter III'te onay bekliyor.
  - **Kullanıcı notu:** "Geçiş belgesi: Onay."
  - **Kabul:** Belgesiz geçişin bedeli ve belgenin süresi test edilir.

</details>

## Paket P09

### Y-C09 · Bölgesel düşman kimlikleri

- **Durum:** iptal · **Öncelik:** P2 · **Paket:** P09 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06, Y-C01
- **Son not:**  | 2026-11-02: T16-08 görevine taşındı.

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

### Y-D05 · Hafif meta ilerleme: güç değil çeşitlilik

- **Durum:** beklemede · **Öncelik:** P2 · **Paket:** P10 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-D03
- **Son not:** Açılımlar user://lineage_archive.json içinde. | 2026-10-19 karar: beklet: üstüne düşünülecek.

<details><summary>Görev metni</summary>

- [ ] **Y-D05 Hafif meta ilerleme: güç değil çeşitlilik**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `0428df4`): Açılımlar user://lineage_archive.json içinde.
  - **Öncelik:** P2 · **Dalga:** 4 · **Bağımlı:** Y-D03
  - **Ne:** Soy defterinde kuşak başarıları; yeni başlangıç kökenleri, kurucu huyları ve hikâye başlangıçları açılır. Güç veren açılım yok.
  - **Kabul:** En az 5 açılabilir başlangıç; açılımlar meta kayıtta.
  - **Literatür:** R9, R54

</details>

## Paket P11

### Y-E01 · Olay havuzunu 46'dan 120'nin üstüne çıkar

- **Durum:** sistem yapıldı, içerik lore bekliyor · **Öncelik:** P1 · **Paket:** P11 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06, Y-C01
- **Son not:** Kart yazımı lore sonrası 10luk partilerle; düzen docs/design_notes/olay_uretim_duzeni.md.

<details><summary>Görev metni</summary>

- [ ] **Y-E01 Olay havuzunu 46'dan 120'nin üstüne çıkar**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `cbe2b02`): Kart yazımı lore sonrası 10luk partilerle; düzen docs/design_notes/olay_uretim_duzeni.md.
  - **Öncelik:** P1 · **Dalga:** 5 · **Bağımlı:** Y-E06, Y-C01
  - **Ne:** Bölge başına 6–10 kart, yoldaş kartları, zincirler. Her kart oyuncunun kararını değiştirecek kadar farklı olmalı. Üretim düzeni için “Kullanıcının sorularına cevaplar” bölümüne bak.
  - **Kullanıcı notu:** “Sayıyı arttır demek kolay ama arttırabilecek misin?”
  - **Kabul:** En az 120 çekilebilir kart; her kart kalite listesinden geçti; simülatörde finale kadar tekrar oranı ölçüldü.
  - **Literatür:** R15, R48

</details>

### Y-E02 · Uzun zincirler: karşılık başka şehirde ya da sonraki kuşakta

- **Durum:** sistem yapıldı, içerik lore bekliyor · **Öncelik:** P1 · **Paket:** P11 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06
- **Son not:** 10 zincirin içeriği Y-E06 (lore) kapanınca yazılacak.

<details><summary>Görev metni</summary>

- [ ] **Y-E02 Uzun zincirler: karşılık başka şehirde ya da sonraki kuşakta**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `3069762`): 10 zincirin içeriği Y-E06 (lore) kapanınca yazılacak.
  - **Öncelik:** P1 · **Dalga:** 5 · **Bağımlı:** Y-E06
  - **Ne:** En az 10 çok seferli zincir; sonucu başka bir şehirde ya da varisin döneminde gelir.
  - **Kabul:** 10 zincir; kayıtta zincir durumu; testler.
  - **Literatür:** R24, R48

</details>

### Y-C18 · Kampanya bölümlerini yaz

- **Durum:** iptal · **Öncelik:** P2 · **Paket:** P11 · **Kim:** kullanıcının içeriği/lore'u gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06
- **Son not:**  2026-10-31: senaryo sistemi kaldırıldı (kullanıcı kararı); bölüm yazılmayacak.

<details><summary>Görev metni</summary>

- [ ] **Y-C18 Kampanya bölümlerini yaz**
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** Y-E06
  - **Ne:** Kullanıcı notu: bölümler henüz yazılmadı; bölüm sayısı ve sahneleme önerisi şimdilik onaylanmadı. Görev yalnızca bölümlerin yazılması. Sahneleme, final mekânı ve finalden sonrası, bölümler yazıldıktan sonra kullanıcıyla yeniden konuşulur.
  - **Kullanıcı notu:** “Evet bölümler yazılmadı o yüzden bana 8 bölüm var demen bile aslında uydurma bir veriye dayanıyor. Bu bölümler yazıldıktan sonra düşünülecek bir konu bu, onaylamıyorum bu konuyu o yüzden şu an. ama bölüm yazılacak gibi bir not alabilirsin.”
  - **Kabul:** Bölüm metinleri yazıldı ve kullanıcı onayladı.

</details>

### Y-A07 · Zindanlar: tam sürüm

- **Durum:** lore bekliyor · **Öncelik:** P2 · **Paket:** P11 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-E06, Y-C01
- **Son not:** docs/design_notes/zindanlar.md; uygulama onay ve lore sonrası. | 2026-10-19 karar: beklet: lore beklenecek.

<details><summary>Görev metni</summary>

- [ ] **Y-A07 Zindanlar: tam sürüm**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `b76bb93`): docs/design_notes/zindanlar.md; uygulama onay ve lore sonrası.
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** Y-E06, Y-C01
  - **Ne:** Rota dışı zindan, hazine ve mistik yaratık (Temmuz pitch'inin çekirdeği) tam sürüm olarak tasarlanır ve uygulanır; küçük ara sürüm yok. Önce tasarım notu: giriş (haritada yer, söylenti, olay), yapı (oda ya da aşama dizisi), savaş, ganimet, kayıp ve stres kuralları, kervanın zindan dışında beklemesi. Tasarım notu kullanıcı onayından sonra uygulanır.
  - **Neden:** Zindanlar konuşmalarda hiç ele alınmadı; keşif ve ganimet açığını kapatır.
  - **Kullanıcı notu:** “Sıra zindanlara gelecek fakat bende küçük sürüm diye bir şey yok, tam gaz devam. Solo indie olduğum için istediğim gibi ilerleyebiliyorum ve claude, gemini, google ai sayesinde fazlasıyla da hızlı ilerliyor çalışmalar.”
  - **Kabul:** Onaylı tasarım notu; haritadaki en az bir bölgede oynanabilir zindan; kayıt ve yükleme testi.
  - **Kaynaklar ve teknik (CC0 araştırması):** Yapılar: Quaternius Ultimate Modular Ruins ve Modular Dungeon (yeni indirme QAL), Kenney Castle Kit (CC0). Ses: OpenGameArt “Loopable Dungeon Ambience”, “Dripping water loop” (indirmeden önce lisans sayfası kontrol edilir).
  - **Literatür:** R9

</details>

## Paket P12

### Y-G11T · Masa ekranı şablonunu görsel taslakla göster

- **Durum:** onaylandı, uygulanacak · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Oyunun kendi resim, yazı yüzü ve paletiyle; uygulama kararı taslaktan sonra 9.1e işlenir. | 2026-10-19: terazi oyunda (9.5 notuna bakın); masa şablonu onayı sürüyor. | 2026-10-19 karar: terazi tamamen referans görseldeki gibi (Gemini içeriği; kırpılabilir ya da başka yöntem). Terazi durumları (denge/mal ağır/altın ağır) onaylandı. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş).

<details><summary>Görev metni</summary>

- [ ] **Y-G11T Masa ekranı şablonunu görsel taslakla göster**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Oyunun kendi resim, yazı yüzü ve paletiyle; uygulama kararı taslaktan sonra 9.1e işlenir.
  - **Öncelik:** P2 · **Dalga:** 6 · **İlgili:** 9.1, 9.5
  - **Köken:** onaylanmayan **G11** önerisinin altındaki kullanıcı notu.
  - **Ne:** Kullanıcı notundan türetildi: “bunu görmem lazım, yazıyla anlaşılmıyor.” Sol liste, ortada metafor nesnesi, sağda kervan düzeni pazar ekranı üzerinde görsel taslak olarak hazırlanıp sunulur. Uygulama kararı taslaktan sonra.
  - **Kullanıcı notu:** “bunu görmem lazım, yazıyla anlaşılmıyor.”
  - **Kabul:** Taslak kare kullanıcıya sunuldu; karar 9.1'e işlendi.

</details>

### Y-G06 · Gravür efektleri; parlak efektleri kaldır

- **Durum:** beklemede · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-G01
- **Son not:** Kaba bir yön taslağı: tarama ve mürekkep dili, parlak mor/mavi yok. Gerçek dokular onaydan sonra Krita + David Revoy 2023 CC0 fırçalarıyla; eski efekt onaylı karşılığı gelince kalkar. | 2026-10-19 karar: "hiç olmamış": baştan yapılacak. | 2026-10-20 kullanıcı kararı: gravür efektleri beğenilmedi, kaldırıldı; efektler şimdilik eksik kalsın. Taslak (gravur_efekt_taslak.py, y_g06_gravur_efektler.png) silindi; oyuna hiç girmemişti.

<details><summary>Görev metni</summary>

- [ ] **Y-G06 Gravür efektleri; parlak efektleri kaldır**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Kaba bir yön taslağı: tarama ve mürekkep dili, parlak mor/mavi yok. Gerçek dokular onaydan sonra Krita + David Revoy 2023 CC0 fırçalarıyla; eski efekt onaylı karşılığı gelince kalkar.
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** Y-G01
  - **Ne:** Kullanıcı notu: yerine ne konacağı çok önemli. Önce her efekt için (kan, duman, sis, kritik, büyü, yanma, donma, zehir) gravür karşılığının örnek karesi hazırlanır, onaydan sonra eskisi kaldırılır. 14 Ekim kararları korunur: yanan adam gerçekçi yanar, donma bölgesel buzlanma, zehir yeşil sis.
  - **Kullanıcı notu:** “yerine ne koyacağımız çok önemli ama”
  - **Kabul:** Her efektin onaylı örneği ve oyundaki karşılığı; parlak mor ve mavi efekt kalmadı.
  - **Kaynaklar ve teknik (CC0 araştırması):** Hazır CC0 mürekkep sıçrama dokusu yok: Krita'da David Revoy 2023 fırça kitiyle (CC0; 2025 kitinin lisansı çelişkili, kullanılmaz) kendimiz üretiriz. Kritik mührü özgün tasarım. Godot'ta `CPUParticles2D` + mürekkep dokuları. `../ICERIK_IHTIYACLARI.md` G-6.
  - **Literatür:** R20

</details>

### 9.2 · Ana menü gece kampı, katmanlı

- **Durum:** iptal · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/09_art_ikinci_tur.md](referans/gorevler/09_art_ikinci_tur.md)
- **Bağımlı:** 9.1
- **Son not:** Mor-lacivert gök ve tek ateş ışığı resmin kendisinden; duman ayrı katman; sağda arayüz için karanlık sade alan. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş). | 2026-11-02: T16-04 görevine taşındı.

<details><summary>Görev metni</summary>

- [ ] **9.2 Ana menü gece kampı, katmanlı** (A-25, A-19, A-10, A-17)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Mor-lacivert gök ve tek ateş ışığı resmin kendisinden; duman ayrı katman; sağda arayüz için karanlık sade alan.
  - Mor-lacivert gök ve tek ateş ışığı.
  - Duman ayrı katmanda.
  - Arayüze karanlık, sade bir alan bırakılacak.

</details>

### Y-G16 · Ana menü: kamp ateşi ve üç yorgun yolcu

- **Durum:** iptal · **Öncelik:** P2 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Figürler oyunun karelerinden, ride karesinin oturuşuyla; gerçek sürümde FigureActions a sit_tired (kambur, elleri ateşe) klibi yazılıp MPFB hattıyla render edilir. Menüde müzik yok, ateş ve gece ambiyansı. | 2026-10-19 karar: sağdaki iki figür oturuyor gibi değil: bağdaş kurmuş ya da sandık/kutu üstünde otursunlar. | 2026-10-20: taslak MPFB oturuş klibi (sit_box) ile yeniden: üç yolcu sandığın üstünde gerçekten oturuyor (kalça kapakta, uyluk yatay, ayaklar yerde), ateşe dönük. y_g16_menu_kamp.png. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş). | 2026-11-02: T16-04 görevine taşındı.

<details><summary>Görev metni</summary>

- [ ] **Y-G16 Ana menü: kamp ateşi ve üç yorgun yolcu**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Figürler oyunun karelerinden, ride karesinin oturuşuyla; gerçek sürümde FigureActions a sit_tired (kambur, elleri ateşe) klibi yazılıp MPFB hattıyla render edilir. Menüde müzik yok, ateş ve gece ambiyansı.
  - **Öncelik:** P2 · **Dalga:** 6 · **İlgili:** 9.2
  - **Ne:** Ana menü kamp ateşi panoramasından bir kare; fener ışığı kısılır. Kullanıcı notu: ateş başında oturan, yorgunluktan bitmiş ve ısınmaya çalışan üç kişilik kervan ekibi. Ana menüde şarkı yok (Y-I02).
  - **Kullanıcı notu:** “ana menüye kervan ekibi de katılmalı, ateş başında oturan, yorgunluktan ölmüş ve ısınmaya çalışan 3 kişi.”
  - **Kabul:** Yeni ana menü onaylı; üç figür ateş başında.
  - **Kaynaklar ve teknik (CC0 araştırması):** Ana menüde müzik yok: gece ormanı ve ateş çıtırtısı ambiyansı (Freesound CC0 `campfire`, `forest night`), yaklaşık −22 LUFS. `../ICERIK_IHTIYACLARI.md` S-1.

</details>

### Y-G23 · Soy sonu: ufukta yürüyen adlar

- **Durum:** iptal · **Öncelik:** P3 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/15_film_kervan_fikirleri.md](referans/gorevler/15_film_kervan_fikirleri.md)
- **Bağımlı:** Y-D03
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı. | 2026-10-31: LineageProcession: bitiş panelinde ölenler ufukta yükleriyle yürür, adları üstü çizili. tests/screenshot_lineage_end.gd. | 2026-10-31 onay turu: Kullanıcı (onay turu): Red - kaldırıldı.

<details><summary>Görev metni</summary>

- [x] **Y-G23 Soy sonu: ufukta yürüyen adlar**
  - **Onay turu (2026-10-31):** iptal. Kullanıcı (onay turu): Red - kaldırıldı.
  - **Durum (2026-10-31):** test bekliyor. LineageProcession: bitiş panelinde ölenler ufukta yükleriyle yürür, adları üstü çizili. tests/screenshot_lineage_end.gd.
  - **Öncelik:** P3 · **Dalga:** 6 · **Bağımlı:** Y-D03 · **Kim:** CO
  - **Ne:** Soy bitince üstü çizili adların sahipleri ufukta siluet olarak yürür. Ortaçağın ölüm dansı geleneğinden; filmin karesinden değil.
  - **Kullanıcı notu:** "Soy sonu: ufukta adlar: Onay."
  - **Kabul:** Bitiş ekranının görüntüsü onaylandı.

</details>

## Paket P14

### Y-H02 · İlk 10 dakikanın çizelgesi

- **Durum:** ölçüm hazır, dış oyuncu testi bekliyor · **Öncelik:** P1 · **Paket:** P14 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** docs/design_notes/ilk_on_dakika.md; dört ilk gerçek oyunda user://playtest_times.json a yazılır.

<details><summary>Görev metni</summary>

- [ ] **Y-H02 İlk 10 dakikanın çizelgesi**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `46fa60b`): docs/design_notes/ilk_on_dakika.md; dört ilk gerçek oyunda user://playtest_times.json a yazılır.
  - **Öncelik:** P1 · **Dalga:** 6
  - **Ne:** İlk 3 dakikada ilk anlamlı karar; 10 dakikaya kadar ilk tehdit; 30 dakikaya kadar ilk kayıp tehlikesi ve ilk kârlı varış.
  - **Kabul:** Dış oyuncu testlerinde süreler ölçüldü.
  - **Literatür:** R78, R59

</details>

### Y-H06 · Kumanda, Steam Deck ve Xbox

- **Durum:** denetim yazıldı, uygulama sonra (P3) · **Öncelik:** P3 · **Paket:** P14 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Sanal imleç bugün her ekranı kumandayla çalıştırıyor; eksikler (odak gezinmesi, tuş simgeleri, savaş ve pazar kısayolları, 1280x800 taraması) sıralı.

<details><summary>Görev metni</summary>

- [ ] **Y-H06 Kumanda, Steam Deck ve Xbox**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f3e22fb`): Sanal imleç bugün her ekranı kumandayla çalıştırıyor; eksikler (odak gezinmesi, tuş simgeleri, savaş ve pazar kısayolları, 1280x800 taraması) sıralı.
  - **Öncelik:** P3 · **Dalga:** 7
  - **Ne:** Kullanıcı notu: sonra eklenecek ama listede dursun. Tam kumanda desteği, Steam Deck uyumluluk denetimi, Xbox.
  - **Kullanıcı notu:** “bu daha sonra eklememiz gereken bir şey değil mi? listeye ekleyebiliriz yine de. steam deck, xbox.”
  - **Kabul:** Bütün ekranlar kumandayla oynanıyor.

</details>

## Paket P15

### Y-G13 · Kimliği tanımlayan beş ana görsel

- **Durum:** onaylandı, uygulanacak · **Öncelik:** P1 · **Paket:** P15 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-G02, Y-G07
- **Son not:** Hepsi oyunun kendi resimleri ve bugünkü taslaklardan; olay kartı gerçek kart düzeniyle (savaş şeridi, mühür). | 2026-10-19 karar: kapıda vagonun ışığı ortama uymuyor; olay kartının kendi arka planı olmayacak, kart mevcut sahnenin (yol, taverna, şehir) içinde, olay görseli kartın içinde (EU4 gibi). Diğerleri güzel. | 2026-10-20 kullanıcı: taslak onaylandı (bugünkü pakette değil, sonraki iş).

<details><summary>Görev metni</summary>

- [ ] **Y-G13 Kimliği tanımlayan beş ana görsel**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Hepsi oyunun kendi resimleri ve bugünkü taslaklardan; olay kartı gerçek kart düzeniyle (savaş şeridi, mühür).
  - **Öncelik:** P1 · **Dalga:** 7 · **Bağımlı:** Y-G02, Y-G07 · **İlgili:** 8.10, 12.2a, 12.2c
  - **Ne:** Gece haritası ve fenerli atlı; kamp ateşi panoraması; tam ekran olay kartı; defter ve kırık mühür; şehir kapısına varış. Mağaza görüntüleri ve fragman bunlardan çıkar.
  - **Kabul:** Beş görsel onaylı.
  - **Literatür:** R58, R59

</details>

### Y-J14 · Mağaza ekran görüntüsü seti

- **Durum:** Aralık (kullanıcı notu), Y-G13 taslakları hazır · **Öncelik:** P2 · **Paket:** P15 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Bağımlı:** Y-G13, Y-G05
- **Son not:** Kullanıcı: pazarlama işleri Aralıkta. Beş ana görsel onaylanınca oyunun gerçek ekranlarından (screenshot araçları) beş kare alınır.

<details><summary>Görev metni</summary>

- [ ] **Y-J14 Mağaza ekran görüntüsü seti**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `-`): Kullanıcı: pazarlama işleri Aralıkta. Beş ana görsel onaylanınca oyunun gerçek ekranlarından (screenshot araçları) beş kare alınır.
  - **Öncelik:** P2 · **Dalga:** 7 · **Bağımlı:** Y-G13, Y-G05
  - **Ne:** Beş ana görselden beş ekran görüntüsü; ilk ikisi yol ve olay kartı. Kullanıcı notu: pazarlama işleri Aralık'ta.
  - **Kullanıcı notu:** “tamam zaten bu pazarlama işlerini hemen yapmayacağız. Aralık gibi yapılacak.”
  - **Kabul:** Beş ekran görüntüsü onaylı.
  - **Literatür:** R58

</details>

### Y-J09 · Kliplenebilir anlar listesi

- **Durum:** liste yazıldı, kayıtlar Aralıkta · **Öncelik:** P2 · **Paket:** P15 · **Kim:** Claude tek başına
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Beş an: kırılma, varis devralma, alacaklı atlısı, kurt sürüsü, açlık gecesi; her biri için tetikleme ve kayıt hazırlığı.

<details><summary>Görev metni</summary>

- [ ] **Y-J09 Kliplenebilir anlar listesi**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `f5e6c40`): Beş an: kırılma, varis devralma, alacaklı atlısı, kurt sürüsü, açlık gecesi; her biri için tetikleme ve kayıt hazırlığı.
  - **Öncelik:** P2 · **Dalga:** 7
  - **Ne:** Kırılma, varis devralma, alacaklı atlısı, kurt sürüsü, açlık gecesi; her biri net başlangıç ve sonu olan sahne.
  - **Kabul:** Liste ve her an için kayıt.
  - **Literatür:** R22, R11

</details>

## Paket P18

### N32 · Nemesis benzeri NPC hafıza sistemi: tasarım

- **Durum:** iptal · **Öncelik:** P2 · **Paket:** P18 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Son not:** Kullanıcı isteği (2026-10-19): Shadow of Mordor/War Nemesis; lore'a bağlı. | 2026-11-02: T16-09 görevine taşındı.

<details><summary>Görev metni</summary>

- [ ] **N32 Nemesis benzeri NPC hafıza sistemi: tasarım** (`CK`)
  - **Sütun:** Defter unutmaz · Yol yaşar
  - **Ne:** Shadow of Mordor/War'un Nemesis sisteminden esinle, yolda karşılaşılan kişilerin (eşkıya reisi, muhafız çavuşu, tüccar, yoldaş adayı) oyuncuyu hatırlaması: kaçan ya da yenilen düşman adıyla, yarasıyla ve kinle geri döner; terfi eder, çetesi büyür; kurtarılan ya da kandırılan kişi sonra iyilikle ya da intikamla karşına çıkar. Sistem olarak mı, hikâye kurgusu olarak mı (ya da ikisi) yapılacağı kullanıcı kararı.
  - Mevcut zemin: `CaravanLedger` (dünyanın hafızası), `NpcDisposition` ve `ROLL_ENCOUNTER`, gecikmeli zincir olaylar (`evt_wanderer_revenge`), `EnemyCatalog` yöre reskin'leri, şikâyetler (grievances). Kural: yeni sistem icat etmez, olay sözlüğüyle (`EventEffect`) konuşur; adlı NPC'ler kayıtta tutulur, yeniden yüklemeyle değişmez.
  - **Kabul:** `docs/design_notes/nemesis_npc_plani.md` (seçenekler, lore'a bağımlılık, maliyet) ve kullanıcı kararından sonra alt görevler. Lore'a bağlı (Lore önce kuralı).

</details>

### N31d · Figür tepkileri: bakma ve yorgun bekleyiş

- **Durum:** kısmen · **Öncelik:** P2 · **Paket:** P18 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N31
- **Son not:** N31 planından (docs/design_notes/oyun_hissi_plani.md). | 2026-10-20: look_ahead (alına siper) ve idle_tired klipleri tanımlı, yol bağlı (işarette en yakın yaya bakar, duran kervanda yorgun bekleyiş; yalnız duran kervanda, kayan ayak olmasın). Commit 8f7b27a. Render kuyrukta (figlogs/react_batch.sh); bitince append_clips ve yol görüntüsü. | 2026-10-20 10:5x: iki klip 276 kare setine eklendi. idle_tired açık (duran kervan). look_ahead 3B render'da el alnın önü yerine başın üstüne düşüyor, iki deneme (125/262, 118/238) tutmadı; RoadCaravan.LOOK_ENABLED=false. Çubuk figür ile 3B arasındaki farkı ölç (tests/screenshot_reactions.gd), sonra yeniden render. | 2026-10-20: look_ahead 92/206 ile yeniden render edildi ve eklendi ama poz hâlâ yanlış: el yüzün önünde/başın üstünde (journey_shots/tepkiler.png). LOOK_ENABLED kapalı. Öneri: ön kolu daha az bük (ör. arm_f [70, 165]) ve önce screenshot_poses çubuk figürüyle dene, sonra figlogs/look_batch.sh.

<details><summary>Görev metni</summary>

- [ ] **N31d Figür tepkileri: bakma ve yorgun bekleyiş** (`CO`) - look ve idle_tired klipleri, sinyalde en yakın figür bakar. (M, P2) §4.

</details>

### N31f · Durum tablolu ortam sesi ve savaş müziği

- **Durum:** kullanıcıda · **Öncelik:** P1 · **Paket:** P18 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N31
- **Son not:** N31 planından (docs/design_notes/oyun_hissi_plani.md). | 2026-10-20: ortam tablosu (ateş, rüzgâr) ve savaşta müzik kısma. Yağmur/orman/şehir kayıtları yok. | 2026-10-20 kullanıcı: ortam sesleri kullanıcıya bırakıldı. | 2026-10-21 kullanıcı kararı: yağmur, orman ve şehir kayıtlarını kullanıcı getirecek; gelince ortam tablosuna bağlanır (play_ambience eksik dosyayı atlıyor).

<details><summary>Görev metni</summary>

- [ ] **N31f Durum tablolu ortam sesi ve savaş müziği** (`CO`) - hava × saat × yer ortam tablosu, savaşta müzik kısılır. (M, P1) §6.

</details>

### N34 · Konaklama, mini oyun ve sohbetle öğrenilen bilgi: yerleşimde kalmak

- **Durum:** iptal · **Öncelik:** P2 · **Paket:** P18 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N33, Y-C13
- **Son not:** Kullanıcı isteği (2026-10-19), akşam düşünme ve geliştirme görevi. Taverna dedikodusu satın alınmaz, sohbetle edinilir. | 2026-10-20: söylenti satın alma kalktı; yol ve fiyat haberi sohbette (rol, içki, liman kültürü, tellal). Commit dee753b. Kalan: konaklama, mini oyunlar, adlı NPC hafızası (Y-C13/N32 lore'a bağlı). | 2026-11-02: T16-06 görevine taşındı.

<details><summary>Görev metni</summary>

- [ ] **N34 Konaklama, mini oyun ve sohbetle öğrenilen bilgi: yerleşimde kalmak** (`CO`)
  - **Sütun:** İnsanlar aşınır · Defter unutmaz · Ticaret bilgi oyunudur
  - **Kullanıcı isteği (2026-10-19):** Şehirde, kasabada, kervansarayda konaklama ve mini oyun sunan, NPC sohbeti katan bir sistem için fikirler düşünülsün ve geliştirilsin. **Tavernadan doğrudan dedikodu satın alınmasın; bilgi konuşarak, sohbet ederek edinilsin.**
  - **Bugün:** Taverna söylentiyi parayla satıyor (`GameSession.buy_price_rumor`, Y-C10: komşu şehrin fiyatları, dörtte biri yalan); ziyafet (`throw_feast`, günde bir); `PurificationPanel`; yoldaş sohbeti yolda (`RoadChatter`, Y-B01) ve kamp hikâyeleri (`CampStory`, Y-C17); adlı kişiler Y-C13 ve hafıza N32 henüz yok.
  - **Düşünülecek fikirler:**
    1. **Sohbet bilgi kapısıdır, satın alma değil.** Taverna "Söylenti" düğmesi kalkar; yerine tezgâhta oturup sohbet: NPC'nin ilgisi (rapport, `CharacterData.rapport` mantığı) ve karşılıklı tercih (ona bir içki, bir haber, bir iyilik) bilgiyi açar. Bilgi parça parça gelir ve yalan olabilir (Y-C10'un yalan oranı korunur); doğrulamak için yolda bakmak gerekir.
    2. **Sohbet yapısı:** konu seçenekleri (yol, fiyat, kişi, borç, söylenti), NPC'nin huyu ve kültürü ne söyleyeceğini ve ne saklayacağını belirler; aynı NPC her ziyarette hatırlar (Y-C13 adlı kişiler, N32 hafıza). `EventEffect` sözlüğüyle konuşur; yeni sistem icat etmez.
    3. **Konaklama:** kalmak bir karar (zaman, kese, erzak): oda ya da avlu yeri, bir ya da birkaç gece; stres iner (`CAMP_STRESS_RELIEF`'ten büyük ama paralı), saat ilerler (N33 evreleri), geceleyin NPC'ler değişir (gündüz tüccar, gece yolcu ve kaçakçı). Kervansarayda avlu, kasabada han, şehirde pansiyon: üç tür farklı fiyat ve risk (hırsızlık, dedikodu). Kervanın kendisi şehir dışında kalır (Y-G10T kararı).
    4. **Mini oyun adayları** (hepsi mevcut kollara bağlı, zar gibi mekanik küçük): zar/kemik oyunu (kese riski, Karizma), kart/taş oyunu (Zeka, bilgi kazanma), içki yarışı (Dayanıklılık, bilgi karşılığı), el falı ya da hikâye yarışı (kültürel; dinî sembolsüz), arm wrestling (Güç, itibar). Her biri 30-60 sn, kaybı küçük ve bilgi/itibar/stres kazandırır; gerçek para kumarı değil.
    5. **Sabah-gün-akşam-gece ile bağ (N33):** sohbet ve mini oyun saate bağlı: gündüz pazar ve lonca, akşam han ve oyun, gece sır ve kaçakçılık.
    6. **Dedikodu nereden gelir:** NPC'nin bildiği = dünya durumu (`WorldEvents`, fiyat şokları, rota durumu, defter); ne kadarını söyleyeceği güven ve ilgiye bağlı. Böylece Y-C10 fiyat söylentisi ve yol haberi aynı kapıdan geçer.
  - **Riskler:** metin üretimi çok (NPC başına konu × güven kademesi): Y-E06 lore kapanmadan içerik yazılmaz; önce sistem iskeleti ve 2-3 örnek NPC. Mini oyunlar ekran ve test yükü getirir: önce ikisi (zar, taş oyunu).
  - **Kabul:** Tasarım notu (sohbet modeli, konaklama kuralları, mini oyun listesi ve bedelleri, taverna söylentisinin yeni biçimi) kullanıcı onayına; onaydan sonra iskelet: bir yerleşimde sohbetle bilgi alma, bir gece konaklama, bir mini oyun; kayıt ve yükleme testi.
  - **Bağlı:** Y-C10, Y-C13, Y-C17, Y-B01, N32, N33, Y-E06 (içerik).

</details>

## Paket P20

### IP-003 · Garantili karşılaşmada tür dönüşümü (karar K-04)

- **Durum:** yapılacak · **Öncelik:** P1 · **Paket:** P20 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/20_oyun_testi_ve_satis_plani.md](referans/gorevler/20_oyun_testi_ve_satis_plani.md)
- **Son not:** İş kartı: docs/playtest/2026-11-12/07_opus_uygulama_plani.md (grep -n '^## IP-003' -A60).

### IP-006 · Kervan avlusunda sıradaki adım (karar K-03)

- **Durum:** yapılacak · **Öncelik:** P1 · **Paket:** P20 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/20_oyun_testi_ve_satis_plani.md](referans/gorevler/20_oyun_testi_ve_satis_plani.md)
- **Son not:** İş kartı: docs/playtest/2026-11-12/07_opus_uygulama_plani.md (grep -n '^## IP-006' -A60).

### IP-013 · Borcun yüzü (karar K-05)

- **Durum:** yapılacak · **Öncelik:** P1 · **Paket:** P20 · **Kim:** kullanıcı kararı gerekir
- **Ayrıntı ve geçmiş:** [referans/gorevler/20_oyun_testi_ve_satis_plani.md](referans/gorevler/20_oyun_testi_ve_satis_plani.md)
- **Son not:** İş kartı: docs/playtest/2026-11-12/07_opus_uygulama_plani.md (grep -n '^## IP-013' -A60).

### K-PLAN · Satış planı kararları K-01…K-10

- **Durum:** yapılacak · **Öncelik:** P1 · **Paket:** P20 · **Kim:** kullanıcının işi
- **Ayrıntı ve geçmiş:** [referans/gorevler/20_oyun_testi_ve_satis_plani.md](referans/gorevler/20_oyun_testi_ve_satis_plani.md)
- **Son not:** Karar listesi: docs/playtest/2026-11-12/06_is_plani.md §5. K-03, K-04, K-05 Dalga 1'in üç kartını bekletiyor.
