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



Toplam: **16** görev. Belgeler `referans/belge_uret.py` ile `referans/gorevler.json`'dan üretilir.

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

### Y-G08 · Fener, oyunun görsel motifi

- **Durum:** kısmen · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/13_yonetmen_onerileri.md](referans/gorevler/13_yonetmen_onerileri.md)
- **Son not:** Emblem oyunda (ana menü başlığı). Menünün ışık kaynağı yalnızca taslakta (Y-G16), oyunda değil: beş yerin dördü. | 2026-10-21 kullanıcı kararı: motif ateş ve fener birlikte. Menüde ateş kalır, fener yolda (kervan feneri, atlı işaret) ve arayüz kehribar vurgusunda motif olur; 'beş yer' bu tanıma göre yeniden sayılacak.

<details><summary>Görev metni</summary>

- [ ] **Y-G08 Fener, oyunun görsel motifi**
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `3784072`): Beş yerden üçü var, biri taslakta (menü), logo amblemi Poly Haven Lantern_01 indirmesine bağlı.
  - **Öncelik:** P1 · **Dalga:** 6 · **İlgili:** 8.11, Y-C20
  - **Ne:** Atlı işaretin feneri, yoldaki kervan feneri, menünün ışık kaynağı, arayüzün kehribar vurgusu, logo yanında küçük amblem.
  - **Kabul:** Motif stil rehberinde; beş yerde uygulanmış.
  - **Kaynaklar ve teknik (CC0 araştırması):** Fener modeli: Poly Haven `Lantern_01` (CC0), render ve mürekkep geçişi.
  - **Literatür:** R58

</details>

### Y-G17 · Tek sıcak kaynak: kural ve bütün sahnelerin denetimi

- **Durum:** kısmen · **Öncelik:** P1 · **Paket:** P12 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_film_kervan_fikirleri.md](referans/gorevler/14_film_kervan_fikirleri.md)
- **Bağımlı:** Y-C22
- **Son not:** 2026-10-31 kullanıcı: fikir listesi cevabı.

<details><summary>Görev metni</summary>

- [ ] **Y-G17 Tek sıcak kaynak: kural ve bütün sahnelerin denetimi**
  - **Öncelik:** P1 · **Dalga:** 6 · **Bağımlı:** Y-C22 · **Kim:** CO
  - **Ne:** Dünyada sıcak renk yalnızca bir ışık kaynağından gelir: ateş, fener, meşale, pencere ışığı, defter sayfası. Kural `kurallar-sanat` Art Rules'a yazıldı. Kalan: yol, şehir, savaş, hub, kervansaray ve kart görsellerinin denetim listesi, aykırı olanların sırayla düzeltilmesi; her düzeltme ekran görüntüsüyle.
  - **Kullanıcı notu:** "Tek sıcak kaynak: Onay. Bunu gene kurallara yaz çünkü buna göre çok düzenleme gerekecek."
  - **Kabul:** Denetim listesi `docs/ui/` altında; her sahne için önce ve sonra görüntüsü.

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

- **Durum:** kısmen · **Öncelik:** P2 · **Paket:** P18 · **Kim:** Claude yapar, kullanıcı görsel/tasarım onayı verir
- **Ayrıntı ve geçmiş:** [referans/gorevler/14_yeni_dunya.md](referans/gorevler/14_yeni_dunya.md)
- **Bağımlı:** N33, Y-C13
- **Son not:** Kullanıcı isteği (2026-10-19), akşam düşünme ve geliştirme görevi. Taverna dedikodusu satın alınmaz, sohbetle edinilir. | 2026-10-20: söylenti satın alma kalktı; yol ve fiyat haberi sohbette (rol, içki, liman kültürü, tellal). Commit dee753b. Kalan: konaklama, mini oyunlar, adlı NPC hafızası (Y-C13/N32 lore'a bağlı).

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
