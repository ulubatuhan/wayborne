# Fable 5.2 · Sistem Tasarım Promptu

**Ne işe yarar:** Aşağıdaki `PROMPT BAŞLANGICI` ve `PROMPT SONU` arasındaki metnin tamamını Fable 5.2'ye
yapıştır. İçindeki `[[ ... ]]` yer tutucularını doldurman gerekiyor; her birinin altında **hangi dosyadan**
geleceği ve **ben (Opus) üretebilir miyim** yazıyor. Doldurulmamış bir yer tutucu bırakma: Fable eksik
bağlamı uydurur ve bütün tasarım onun üstüne kurulur.

**Sıra:** (1) yer tutucuları doldur → (2) promptu Fable'a ver → (3) Fable'ın çıktısını bana getir → (4) ben
koda dökerim. Fable'dan kod istemiyoruz; mimari istiyoruz.

---

## PROMPT BAŞLANGICI

# GÖREV: KERVAN OYUNU İÇİN ÜÇ ALT SİSTEMİN MİMARİSİ

## 0. ÖNCE BUNU OKU

Bu bir "fikir üret" görevi değil. Elinde **çalışan, test edilmiş, 32.000 testi geçen bir oyun** var; ondan
istenen, bu oyunun kendi durumundan doğan ama bugün kimsenin okumadığı sonuçları bulup üç alt sistem olarak
tasarlaman. Çıktın doğrudan bir mühendise (Opus 5) verilecek ve koda dökülecek. Dolayısıyla:

- **Kod yazma.** Tek satır GDScript yazma. Mimari, veri şeması, algoritmik mantık, tetikleme koşulu,
  sözde kod ve matris yaz.
- **Var olanı yeniden icat etme.** §2'deki envanterde adı geçen her sistem çalışıyor. Onları *besle*,
  yerlerine yenisini koyma.
- **Varsayımlarını yaz.** Soru sorma, duraklama. Bilmediğin bir şey varsa §A'da "varsayım" olarak açıkça
  listele ve tasarıma devam et.
- **Sayı ver.** "Moral düşsün" bir tasarım değil. "Moral −6, üç gün içinde geri kazanılabilir, eşik 24'ün
  altına inerse X tetiklenir" bir tasarımdır.

---

## 1. ROL VE BAĞLAM

### 1.1 Kimsin

Sen **kıtlık, psikolojik çöküş ve kaynak yönetimi oyunlarında uzmanlaşmış kıdemli bir oyun mekaniği
mimarısın**. Uzmanlık alanların:

- **Baskı altında karar tasarımı:** oyuncunun elindeki her seçeneğin kötü olduğu, "doğru" cevabın
  bulunmadığı, bedelin her zaman adı olan birine düştüğü karar yapıları.
- **Gecikmeli sonuç mimarisi:** bir kararın bedelinin o anda değil, 3–40 oturum sonra, oyuncunun unuttuğu
  bir yerden geri gelmesi; ve geri geldiğinde **oyuncunun sebebini kendi başına kurabilmesi**.
- **Durum makineleri ve sürüklenme (drift) modelleri:** bir topluluğun moralinin, bir kişinin akıl
  sağlığının, bir şehrin açlığının zamanla ve olaylarla nasıl kayacağı; eşik, histerezis, geri dönülmez nokta.
- **Sayısal denge:** bir sistemi, simülatörle ölçülebilir kabul kriterleriyle birlikte tasarlamak.
- **Okunabilirlik:** gizli sistemleri, hiçbir öğretici ekran olmadan, oyuncunun **sezebileceği** hâle
  getirmek. Okunamayan derinlik derinlik değildir, gürültüdür.

Bir şeyi reddetmekten çekinmezsin: "bu fikir havalı ama bu oyunun omurgasını kırar" demek işinin parçası.

### 1.2 Hangi oyun

**Wayborne** — kıtlık içindeki tek bir kıtada (Sideria) geçen, kuşaklar süren bir **kervan simülasyonu**.
Godot 4.2 / GDScript, PC, tek oyunculu, 2B, Türkçe ve İngilizce.

**Vaat (değişmez):** *Bir kervanı kuşaklar boyu yolda tut. Her karar yola bir iz, her ölüm deftere bir satır olur.*

**Dört sütun (değişmez):**
1. **Yol yaşar** — yol bir menü değil, bir yer: hava, arazi, sıcaklık, zemin, karşılaşma, kamp.
2. **İnsanlar aşınır** — konu kervan değil, kervanı çeken insanlar ve onların yıpranması.
3. **Defter unutmaz** — hiçbir satır silinmez; ölenin adının üstü çizilir. Soy sistemi budur.
4. **Ticaret bilgi oyunudur** — fiyat değil, *neyin nerede ne kadar olduğunu bilmek* kazandırır.

**Dünyanın hâli:** İmparatorluk altmış yıl önce çöktü. Otuz beş yıl barış oldu, sonra **İllet** (veba) çıktı
ve çalışacak insanı aldı; ambarlar bir daha dolmadı. Kırkıncı yılda **kıtlık** başladı, bugün yirmi yaşında.
Kıtlık en kötü hâlinde ama düzen hâlâ kırılmadı: devletler "idare ediyor". Bütün savaşlar bu kıtlıktan doğuyor;
kimse toprak istemiyor, herkes **ambar** ve **işgücü** istiyor. Oyunun işi artık ucuza alıp pahalıya satmak
değil: **yükü ve insanı bir yerden öbürüne sağ ulaştırmak.**

### 1.3 Ton pusulası (yalnızca sana, oyuna asla girmez)

Hedef his şu üç oyunun kesişimidir: **Frostpunk**'ın "her çözüm bir şeyi feda eder" yönetim ahlakı,
**This War of Mine**'ın "hayatta kalmak seni kim yapıyor" psikolojik bedeli, **Oregon Trail**'in
"yol seni her gün biraz daha eksiltir" kümülatif aşınması.

> **MUTLAK KURAL:** Bu üç ad, başka hiçbir gerçek eser, kişi, tarih ya da yer adı **oyunun içine giremez**.
> Ne bir kart metninde, ne bir değişken adında, ne bir yorum satırında, ne de senin çıktının oyuna girecek
> kısmında. Bu adlar yalnızca bu paragrafta, senin tonu ayarlaman için var. Depoda bir test bu kuralı
> bekçiliyor. Esinlenilir; referans verilmez, taklit edilmez.

### 1.4 Tasarımın anayasası (ihlal edilemez)

Bunlardan birini kıran bir öneri, ne kadar iyi olursa olsun **reddedilir**. Bir önerin bunlardan birine
yaklaşıyorsa, §I'da "neden ihlal etmiyor" diye açıklaman gerekir.

| # | Kural | Neden |
|---|---|---|
| A1 | **Derinleşme, asla sadeleştirme.** Bir sorunu "şu sistemi kaldıralım" diye çözmek yasak. Çözüm sistemi *bedelli* yapmaktır. | Kullanıcının ilkesi. Ölçülmüş ve korunan sistemler kesilmez. |
| A2 | **Olaylar öldürmez.** Yoldaki hiçbir kart kimseyi öldüremez. Ölümün yalnızca üç kapısı var: **savaş, açlık, vagonuyla kaybolmak.** | Kart ölümü keyfî hissettiriyor; ölüm oyuncunun ihmalinden doğmalı. Kalıcı sakatlık (kesilen el gibi) serbesttir. |
| A3 | **Anlatıcı yok.** Oyunda hiçbir metin yazarın ağzından konuşmaz. Her cümleyi dünyanın içinden biri söyler ya da yazar: bir NPC, bir kitabın yazarı, bir yazıtı kazıyan el, bir lonca kâtibi. Her kaynak eksik ya da yanlı olabilir. | Dünya bilgisi parça parça ve güvenilmez biçimde verilir; bilgi oyununun temeli. |
| A4 | **Senaryo ve kampanya sistemi yok.** Bölümlü bir hikâye yok, konforlu bir final yok. Oyun kıtlık içinde kervanı ilerletmek ve ek görevlerle geçer. Tek gerçek son: **adı taşıyacak kimsenin kalmaması.** | Kullanıcı kararı. Hikâyeyi kullanıcı kendisi yazacak; sen sistem tasarlıyorsun. |
| A5 | **Güç ve ödül kesilmez, bedelli olur.** Büyüme serbesttir ama kendi krizini doğurur. "Doğru stoklayan aç kalmaz" sözü korunur: ustalık ödüllendirilir. | Oyuncunun ustalığı cezalandırılmaz; yalnızca ihmali cezalandırılır. |
| A6 | **Tek sıcak kaynak.** Dünyada yalnızca **ateş** sıcak renklidir. Önerdiğin hiçbir görsel geri bildirim bu kuralı kırmaz (arayüz hariç; arayüz okunaklı kalır). | Sanat yönetimi kuralı. |
| A7 | **Oyun dili Türkçe ve İngilizce, metinler CSV'de.** Yeni her metin bir çeviri anahtarıdır. Metinlerde "han" sözcüğü kullanılmaz; **kervansaray** denir. | Yerelleştirme hattı ve lore kararı. |
| A8 | **Kaydetme yalnızca şehirde olur.** Yolda kayıt yok (sefer ortası otomatik kayıt hariç). Yolun bedeli geri alınamaz. | Kararların ağırlığı buradan geliyor. |
| A9 | **Her yeni sistem ekranda görünür.** Oyuncunun göremediği bir sistem yoktur. Her önerinin bir "oyuncu bunu nereden okur" cevabı olmak zorunda. | Projenin "bir iş ekranda görününce biter" kuralı. |

---

## 2. ELDEKİ OYUN: NE VAR, NE ÇALIŞIYOR

Bu envanter **gerçektir**, hepsi kodda çalışıyor ve testlerle korunuyor. Tasarımın bunların **üstüne** oturmalı.

### 2.1 Sayılar

| | |
|---|---|
| Yol olay kartı | **101** (hepsi seçenekli, beceri kontrollü, ağırlıklı sonuçlu) |
| Olay etkisi türü | **~30** (aşağıda) |
| Ticaret malı | **18** + kaçak mühürsüz tuz + nadir eski mühür |
| Savaş becerisi | **33** · düşman kadroları bölgesel |
| Huy (trait) | **16** (tohum huylar + kırılma huyları) |
| Karakter sınıfı | **4** · görev (duty) **3** · kültür **5** |
| Ekipman | **36** · kıyafet parçası **45** |
| Yerleşim | **27** (12 şehir, 12 kasaba, 3 kervansaray) · yol **41** · bölge **11** |
| Test | 32.375 (hepsi geçiyor) |

### 2.2 Çalışan sistemler (yeniden icat etme)

**Oturum durumu — `GameSession`** (tek büyük durum nesnesi, yüzlerce alan):
kese (GG), envanter ve yük, kervan (vagon sayısı/kapasitesi/hasarı), erzak, moral, bayraklar, **itibar**
(genel + bölgesel + hizip), sefer durumu, **şehir morali**, **İllet dünya hâli**, **borç defteri** (faiz,
vade, temerrüt), **kontrat panosu**, kariyer kademesi, **soy ve varis**, **kervan defteri** (hiçbir satırı
silmez), **NPC hafızası** (hatırlayan kişiler), kıtlık sürüklenmesi (`Scarcity.DRIFT_PER_DAY` 0,00055,
tavan 0,45), vagon bakım gideri (ilk 2 vagon bedava, sonrası 0,5 GG/vagon/gün), kalabalık moral cezası
(8 kişiden sonra kişi başı −2, tavan −12), yağmacı sabrı, fidye tabanı, görülen kart hafızası (son 12).

**İnsanlar:** `CharacterData` + `CharacterStats` (Güç, Çeviklik, Dayanıklılık, Zekâ, Sezgi, Karizma, İnanç),
**stres**, **yorgunluk**, **kırgınlık** (unutulmaz), açlıktan ölüm, aç kalınca **dağılma** (tayfa kervanı
bırakıp gider), seviye ve ekipman kapısı, kamp hikâyeleri, yoldaş günlük davranışları.

**Olay motoru:** `EventCatalog` (101 kart) → `EventEngine` (günlük çekiliş) → `RoadDirector` (ağırlıklandırma:
**görülmemiş kartı kayırma**, savaş borcu, korunan yol) → `EventResolver` → `EventEffectApplier`.
`SkillCheck` (stat + zorluk + tavan). `EventText` sonuç metinlerine **kişi ve yer adı doldurur**
(`{who}`, `{town}`). `NpcDisposition` karşılaşılan kişinin gizli mizacını tutar. Kart zincirleri var.

**`EventEffect.Type` — bir kartın dünyaya dokunabildiği her yer:**
`GOLD, PROVISIONS, ITEM_ADD, ITEM_REMOVE, WAGON_DAMAGE, WAGON_LOSE, WAGON_REPAIR, MERCHANT_LEAVE, MORALE,
STRESS, TRAVEL_DAYS, DANGER, REPUTATION, DOCUMENT_LOSE, SET_FLAG, CLEAR_FLAG, UNLOCK_EVENT,
TRIGGER_HAGGLING, TRIGGER_COMBAT, TRIGGER_AMBUSH, TRIGGER_RECRUIT, GRANT_TRAIT, GRANT_EQUIPMENT,
MARKET_SHOCK` (şehir/mal/gün bazlı fiyat şoku), `ROUTE_CHANGE` (yolu kapat/yavaşlat/tehlikeli yap),
`CARGO_PLUNDER, CARGO_DECOY` ve kişi mizacını yuvarlayan etkiler.

**Savaş:** sıra tabanlı; pusu (düşman önce vurur), durum etkileri, alan becerileri, "Ölümün Kıyısı",
bölgesel haydut kimlikleri (Vadi'de Prens Kaçağı, Ayazkaya'da Bedel Adamı, Avuçiçi'nde Elsiz Sürgün...).

**Ekonomi:** fiyat katmanları, `MarketConditions`, arz-stok, tek kararlık pazarlık (Karizma), kıtlık fiyat
katmanı, satmak istemeyen satıcı, borç göçü, kontrat cezaları, itibar.

**Yol:** `JourneyController` (mesafe, takvim, tempo, kamp, saat), hava, arazi, sıcaklık, yol durumu, sapma ve
geri dönüş, zemin (ıslaklık/çamur/kar), ıslanma, efekt katmanı, karşılaşma zamanlaması, yol dikkat sistemi.

**Dünya:** 27 yerleşim ekranı (pazar, taverna, lonca, kilise, kervan avlusu, kadro, işe alma, gardırop),
harita, şehir özeti paneli, İlan Panosu, bölgesel itibar ve hizipler.

**Lore:** tek belge, 16 bölüm (`docs/lore/SIDERIA.md`): dünya, zaman, coğrafya, 11 bölge, 27 yerleşim,
inançlar, yolun töresi, gündelik hayat, **söyleyiş** (kim neye yemin eder, neye küfreder) ve
**metin üretim kılavuzu** (14 kaynak türü için uzunluk, ses, yasak).

### 2.3 Bilinen açık hedefler (çakışma, tamamla)

Bu işler zaten karara bağlanmış ve sırada; tasarımın bunları **kapsayabilir** ama yok sayamaz:
kıtlığın ağırlık merkezini ulaştırmaya kaydırmak; "ahlaki zorunluluk / yenilmez çevre ve domino /
çözülemeyen problem" üç tasarım dersi; bölgesel itibarın derinleşmesi; dağılan tayfanın yolda silahlı bir
grubun içinde karşına çıkması; haritada adı olan her yerin oynanabilir olması.

---

## 3. VERİ GİRDİ ŞABLONU

Aşağıdaki blokların içeriği sana ayrıca verilecek. **Her bloğu oku, hiçbirini atlama.** Bir blok boşsa, o
alanda varsayım yaptığını §A'da belirt.

> **[[VERİ-1 · OTURUM DURUMU]]**
> Kaynak: `scripts/autoload/game_session.gd` (kervanın bütün kalıcı durumu) ve
> `scripts/travel/journey_controller.gd` (bir seferin durumu).
> Buraya yapıştır:
> ```
> [[ game_session.gd ve journey_controller.gd dosyalarının tam içeriği ]]
> ```
> **Bu veriden çıkarman gereken:** oyunun bugün *hangi durumu takip ettiği*. Tasarımının ham maddesi bu.

> **[[VERİ-2 · OLAY SİSTEMİ]]**
> Kaynak: `scripts/events/` klasörünün tamamı (`event_catalog.gd`, `event.gd`, `event_effect.gd`,
> `event_effect_applier.gd`, `event_engine.gd`, `road_director.gd`, `event_resolver.gd`, `skill_check.gd`,
> `event_text.gd`, `npc_disposition.gd`).
> ```
> [[ scripts/events/ altındaki dosyaların tam içeriği ]]
> ```
> **Bu veriden çıkarman gereken:** bir kartın dünyaya dokunabildiği bütün yüzey; yeni bir etki türü
> önerirken var olanı yeniden adlandırmamak için.

> **[[VERİ-3 · İNSANLAR]]**
> Kaynak: `scripts/character/character_data.gd`, `character_stats.gd`, `trait_catalog.gd`,
> `class_catalog.gd`, `duty_catalog.gd`, `culture_catalog.gd`, `companion_life.gd`, `camp_story.gd`;
> `scripts/campaign/caravan_ledger.gd`, `lineage_archive.gd`, `people.gd`.
> ```
> [[ bu dosyaların tam içeriği ]]
> ```
> **Bu veriden çıkarman gereken:** bir kişinin bugün taşıdığı bütün alanlar (stat, huy, stres, yorgunluk,
> kırgınlık, görev, sınıf, kültür, ekipman) — psikolojik alt sistemin bunların **üstüne** oturmalı.

> **[[VERİ-4 · EKONOMİ VE DÜNYA DURUMU]]**
> Kaynak: `scripts/economy/` (özellikle `market_conditions.gd`, `market_pricing.gd`, `debt_ledger.gd`,
> `standing.gd`), `scripts/travel/plague_world.gd`, `scripts/travel/contract_board.gd`,
> `data/config/settlements.json`.
> ```
> [[ bu dosyaların tam içeriği ]]
> ```

> **[[VERİ-5 · LORE VE SES]]**
> Kaynak: `docs/lore/SIDERIA.md` (tamamı; özellikle §1.2 beş omurga, §5 kıtlık, §10 bölgeler ve yerleşimler,
> §12 yolun töresi, §14 söyleyiş, §15 metin üretim kılavuzu, §16.3 asla söylenmeyecekler).
> ```
> [[ SIDERIA.md tam metni ]]
> ```
> **Bu veriden çıkarman gereken:** önerdiğin her olayın, kişinin ve sonucun **hangi bölgede, kimin ağzından,
> hangi inançla** olacağı. Bölgesiz bir tasarım bu oyunda yarım tasarımdır.

> **[[VERİ-6 · ÖLÇÜM RAPORLARI]]**
> Kaynak: `tests/simulate_career.gd`, `simulate_journeys.gd`, `simulate_personas.gd`,
> `simulate_expert_review.gd`, `simulate_player_diaries.gd` araçlarının son çıktıları.
> ```
> [[ son ölçüm çıktıları: kariyer yayı, sefer ekonomisi, oyuncu profilleri, uzman denetimi ]]
> ```
> **Bu veriden çıkarman gereken:** oyunun bugünkü **gerçek** davranışı — tahmin değil ölçüm. Teşhisin (§A)
> buna dayanmak zorunda.
> **Bugün elimizde olan ölçümlerden birkaçı (bunlar kesin):**
> - Bir kervanın gördüğü içerik ~6,3–8,2 seferde tekrar etmeye başlıyor (görülmemiş kartı kayırma sonrası).
> - Sonuç metinlerinin %96'sı bir kişiyi ya da yeri adıyla anıyor.
> - Muaf olmayan her yolda en az bir dövüş garantisi %100 tutuyor; ilk yağma ortalama 2. günde.
> - Kıtlık eğrisi + büyüme gideri acemi oyuncunun koşusunu ~70. seferde bitiriyor; planını okuyan oyuncu
>   hayatta kalıyor ama −271 GG ve %14 aç seferle, yani bıçak sırtında.

> **[[VERİ-7 · OYUNCU GÖZLEMİ]]** *(varsa)*
> ```
> [[ gerçek oyun oturumlarından notlar: nerede sıkıldı, nerede durdu, neyi anlamadı, ne hissetti ]]
> ```

---

## 4. ÇALIŞMA YÖNTEMİ

Tasarıma başlamadan önce bu üç adımı **bu sırayla** yap. Çıktında da bu sıra görünsün.

### 4.1 Adım 1 — Durum yüzeyi ile sonuç yüzeyini karşılaştır (teşhis)

Bu oyunun en büyük tasarım açığı muhtemelen "eksik sistem" değil, **okunmayan durum**. Şunu tara:

1. **Takip edilen ama okunmayan durum:** `GameSession` hangi alanı tutuyor da hiçbir sistem onu okumuyor?
   (Örnek biçimi: *"`crew_hungry_nights` sayılıyor ama yalnızca ölüm hesabında okunuyor; hiçbir kart, hiçbir
   NPC, hiçbir fiyat onu bilmiyor."*) Her böyle alan bir **kelebek etkisi fırsatı**dır.
2. **Sonucu olmayan seçim:** hangi kart seçenekleri yalnızca anlık kaynak değiştiriyor, hiçbir gecikmeli iz
   bırakmıyor?
3. **Tek girdili sistem:** hangi sistem yalnızca bir şeyden besleniyor? (Tek girdili sistem sığdır.)
4. **Geri bildirimi olmayan birikim:** oyuncunun biriktirdiği ama göremediği ne var?
5. **Baskın strateji:** ölçüm raporlarında hangi davranış her zaman kazanıyor? Onu *yasaklama* (A1), ona
   **bedel** tasarla.

Bu adımın çıktısı §A tablosudur: **en az 12, en çok 20 satır**, her biri bir dosya/alan adına bağlı.

### 4.2 Adım 2 — Üç alt sistemi tasarla

Bulduğun açıkların üstüne şu üç alt sistemi kur. Üçü **birbirine bağlı** olmalı: birinin çıktısı öbürünün
girdisi olmalı, yoksa üç ayrı özellik yazmış olursun, bir sistem değil.

#### Alt sistem I — AHLAKİ İKİLEM MOTORU (`Ahlak`)

Kıtlıkta doğru seçenek yoktur: her seçenek bir şeyi feda eder ve **bedel adı olan birine düşer**.

Tasarlaman gereken:
- İkilemin **anatomisi**: bir ikilem ne zaman ikilemdir (iki iyi seçenek bir ikilem değildir; bedelsiz bir
  iyilik de değildir). Bunu bir kontrol listesine dök.
- **Bedel taşıyıcısı** kavramı: her seçimin bedelini *kimin* ödediği (bir yoldaş adıyla, bir şehir, bir
  yabancı, gelecekteki kendin, defterdeki bir satır). Bedel taşıyıcısının seçimi rastgele olamaz; kervanın
  durumundan türemeli (kim en zayıf, kim en kırgın, kim en borçlu).
- **Tekrar etmeme kuralı**: aynı ikilem aynı kervana iki kez aynı biçimde gelmez; ikinci kez geldiğinde
  oyuncunun ilk cevabını **bilerek** gelir.
- İkilemlerin **kıtlık derecesine** göre sertleşmesi (`Scarcity` sürüklenmesine bağlanmalı).
- Bir ikilemin mevcut `EventEffect` türleriyle nasıl ifade edileceği; yeni bir etki türü gerekiyorsa
  **adıyla ve gerekçesiyle** öner.

#### Alt sistem II — PSİKOLOJİK DEĞİŞİM (`Ruh`)

Kervanı çeken insanlar aşınır, değişir ve bazen geri dönmez. Bugün stres, yorgunluk, huy ve kırgınlık var;
eksik olan **bunların birbirine dönüşmesi ve kalıcı iz bırakması**.

Tasarlaman gereken:
- Bir kişinin **psikolojik durum makinesi**: durumlar, eşikler, geçiş koşulları, geri dönülebilir ve
  **geri dönülemez** geçişler. Histerezis kullan (düşmesi kolay, çıkması zor).
- **Kişilik sürüklenmesi**: yaşananların huy kazandırması/kaybettirmesi; hangi olay hangi huyu doğurur.
  (Bugün "kırılma huyu" var — onu genişlet, yerine yenisini koyma.)
- **İlişki ağı**: yoldaşlar arası bağ ve kırgınlık; kimin kimin yanında durduğu; birinin ölümünün ya da
  dağılmasının ötekilere ne yaptığı. Ağın karmaşıklığı okunabilirliği aşmasın (en fazla N bağ; N'i sen seç
  ve gerekçelendir).
- **Kervanbaşının kendisi**: oyuncunun taşıdığı kişi de aşınır mı, nasıl? (Dikkat: oyuncunun elinden kontrol
  alınmaz; A5'i kırma.)
- **Şehrin ruhu**: şehir morali bugün var; onu insanların psikolojisine bağla (aç bir şehre girmek kervanın
  ruhuna ne yapar, kervanın getirdiği yük şehre ne yapar).
- **Sessiz anlar**: psikolojinin yalnızca kriz anında değil, kamp ateşinde ve boş günde de görünmesi.

#### Alt sistem III — KELEBEK ETKİSİ AĞI (`Iz`)

Küçük bir kararın, çok sonra, **oyuncunun sebebini kurabileceği** biçimde geri gelmesi.

Tasarlaman gereken:
- **İz (trace) kaydı**: bir kararın dünyada bıraktığı kalıcı veri; şeması, ömrü, kime/nereye yazıldığı.
- **Gecikme sınıfları**: anında / aynı sefer / 2–5 sefer / 10+ sefer / kuşak sonrası. Her sınıf için kaç iz
  aynı anda "açık" olabilir (oyuncu boğulmasın).
- **Yayılma kuralları**: bir iz nasıl bölgeye, loncaya, bir aileye, bir hizbe yayılır; nasıl söner.
- **Geri dönüş biçimleri**: iz geri geldiğinde ne olur (bir kart, bir fiyat, bir kapı, bir yüz, bir düşman,
  bir teklif, bir ret).
- **Nedensellik okunabilirliği**: oyuncu "bu neden oldu" sorusunu nasıl cevaplayacak? (Defter satırı,
  NPC'nin ağzından bir cümle, itibar ekranında bir iz.) **Bu madde zorunlu**: okunamayan kelebek etkisi
  rastgelelikten ayırt edilemez ve oyuncuyu küstürür.
- **Kelebek etkisi matrisi**: §E'de tablo olarak.

### 4.3 Adım 3 — Her öneriyi beş alanla kapat

Hiçbir öneri bu beşi taşımadan çıktına giremez:

1. **Ne** — bir cümlede mekanik.
2. **Hangi durumdan besleniyor** — `GameSession`'ın hangi alanı, hangi eşik.
3. **Oyuncu bunu nereden okur** — ekranda hangi satır, hangi yüz, hangi sayı (A9).
4. **Bedeli kim öder** — adı olan bir taşıyıcı.
5. **Nasıl ölçülür** — hangi simülatörle, hangi sayı hangi aralıkta çıkarsa "çalışıyor" sayılır.

---

## 5. ÇIKTI FORMATI

Çıktın Markdown olacak ve **tam olarak** şu dokuz bölümden oluşacak. Bölüm başlıklarını birebir kullan.

### §A · TEŞHİS (12–20 satır tablo)

| # | Açık | Kanıt (dosya/alan/ölçüm) | Tür | Neden önemli | Hangi alt sistem kapatır |
|---|---|---|---|---|---|

`Tür` şunlardan biri: `okunmayan-durum` · `sonuçsuz-seçim` · `tek-girdili-sistem` · `görünmeyen-birikim` ·
`baskın-strateji` · `yarım-döngü`.
Tablonun altına **"Varsayımlarım"** başlığı ve madde madde varsayımların.

### §B · MİMARİ

Üç alt sistemin yapısı. Her biri için:
- **Sorumluluk sınırı** (ne yapar, ne yapmaz),
- **Bileşenler** ve aralarındaki akış — metin tabanlı UML:
  ```
  [Bileşen] --(ne taşır)--> [Bileşen]
  ```
- **Mevcut sistemlere bağlantı noktaları**: hangi var olan sınıf/dosya nereden çağırır, hangi veriyi okur.
  Burada gerçek dosya adlarını kullan (`game_session.gd`, `event_effect_applier.gd`, `road_director.gd`...).
- **Üç alt sistemin birbirine bağlandığı yerler** (en az üç bağ, açıkça).

### §C · VERİ YAPILARI

JSON Schema tarzı, alan alan. Her alan için: ad, tip, aralık/enum, varsayılan, **kalıcı mı** (kayda yazılır
mı), kim yazar, kim okur. Örnek:

```json
{
  "Iz": {
    "id": "string · benzersiz",
    "kaynak_karar": "string · event_id|secenek_index",
    "dogum_gunu": "int · total_days_elapsed",
    "gecikme_sinifi": "enum[ani, sefer, kisa, uzun, kusak]",
    "tasiyici": { "tip": "enum[kisi, sehir, bolge, lonca, hizip]", "id": "string" },
    "siddet": "float 0..1",
    "sonme_hizi": "float · gün başına",
    "okunabilirlik": { "defter_satiri": "string|null", "npc_repligi_anahtari": "string|null" }
  }
}
```

Kalıcı her alan için **kayda yazma maliyetini** de belirt (bu oyunda kayıt JSON ve yalnızca şehirde yazılır).

### §D · TETİKLEME MANTIĞI

Sözde kod. GDScript değil, dilden bağımsız. Her alt sistem için en az bir ana döngü ve bir karar fonksiyonu.
Koşulları şu biçimde yaz (mevcut koşul sistemiyle uyumlu):

```
KOSUL  kriz_esigi:
  erzak_gun < 2  VE  moral < 30  VE  kiyafet_sicaklik_yetersiz
  VE  son_3_gunde_kart_cekilmedi
AGIRLIK  x2.4  eger  bolge == "vadi"
```

Ayrıca: **çatışma çözümü** (iki sistem aynı anda tetiklenirse hangisi kazanır), **boğulma önleyici**
(aynı gün kaç ağır an olabilir), **sessizlik kotası** (oyuncunun nefes aldığı boş gün garantisi).

### §E · KELEBEK ETKİSİ MATRİSİ (en az 40 satır)

Bu bölüm çıktının kalbi. Tablo:

| Tetikleyen karar | Anında görünen | Gizli iz (veri) | Gecikme | Geri dönüş biçimi | Taşıyıcı | Oyuncu nereden anlar | Şiddet |
|---|---|---|---|---|---|---|---|

Kurallar:
- En az **40 satır**; en az **8 tanesi** uzun gecikmeli (10+ sefer) ve **4 tanesi** kuşak aşırı.
- Her satır gerçek bir oyun durumuna bağlı olmalı (uydurma sistem adı kullanma).
- En az 10 satır **iyi niyetin bedeli** olmalı (doğru olanı yapmak seni zayıflatır), en az 10 satır
  **zalimliğin ödülü** (yanlış olan işe yarar) — ikisi dengeli olmazsa ahlak sistemi vaaz verir.
- Her satırın **sönme** koşulu olmalı: hiçbir iz sonsuza kadar sürmez (kuşak izleri hariç).

### §F · OKUNABİLİRLİK SÖZLEŞMESİ

Oyuncu bu üç sistemi **öğretici ekran olmadan** nasıl öğrenir? Şunları ver:
- Her alt sistem için **ilk karşılaşma anı** (oyuncunun sistemi ilk kez sezdiği an, kaçıncı seferde).
- Hangi ekranda hangi yeni satır/işaret görünür (mevcut ekranlar: yol, kamp, kadro, karakter, defter,
  pazar, taverna, lonca, kilise, kervan avlusu, harita, şehir özeti, İlan Panosu).
- **Sayı göstermeden durum gösterme** yöntemleri (yüz, duruş, replik, eşyanın hâli) — bu oyun sayıyı sever
  ama insanı sayıyla göstermez.
- Yanlış anlaşılma riskleri: oyuncunun sistemi *yanlış* okuyacağı yerler ve bunu nasıl önlediğin.

### §G · DENGE VE ÖLÇÜM PLANI

Her alt sistem için:
- **Ayar düğmeleri** (tune edilebilir sabitler), başlangıç değerleri ve makul aralıkları.
- **Kabul kriteri**: hangi simülatör (`simulate_career`, `simulate_journeys`, `simulate_personas`),
  hangi metrik, hangi aralık. Örnek: *"40 seferlik kariyerde geri dönülemez psikolojik geçiş sayısı 2–5
  arasında olmalı; 0 ise sistem görünmüyor, 8+ ise oyuncu umudunu kaybediyor."*
- **Bozulma işaretleri**: sistem yanlış ayarlanırsa ölçümde ne görünür.
- **Yeni ölçüm aracı gerekiyorsa** ne ölçeceğini tarif et (aracı ben yazarım).

### §H · UYGULAMA SIRASI

Mühendise verilecek sıra. Her adım için: hangi dosyalar, ne kadar iş (küçük/orta/büyük), neye bağımlı,
**hangi testle korunur**, risk notu. En fazla 12 adım. İlk adım tek başına oynanabilir bir fark yaratmalı
(büyük patlama yok, dilim dilim).

### §I · REDDEDİLENLER

Düşündüğün ama **bilerek reddettiğin** en az 6 fikir ve gerekçesi. Anayasayı (§1.4) ihlal ettiği için
reddettiklerini ayrıca işaretle. Bu bölüm boş olamaz: neyi yapmadığını bilmek, neyi yaptığını bilmek kadar
önemli.

---

## 6. YASAKLAR

- ❌ GDScript, Python ya da başka bir dilde **çalışır kod** yazma. Sözde kod serbest.
- ❌ Gerçek bir eser, kişi, marka ya da tarihî olay adı kullanma (§1.3).
- ❌ Var olan bir sistemi "kaldıralım/sadeleştirelim" önerisi (§1.4-A1).
- ❌ Oyuncuyu kart ölümüyle cezalandıran mekanik (§1.4-A2).
- ❌ Anlatıcı ağzından açıklama, öğretici ekran, "sistem size şunu söylüyor" kutusu (§1.4-A3, §F).
- ❌ Rastgeleliğe dayanan "derinlik". Her rastgelelik tohumlanabilir ve gerekçeli olmalı.
- ❌ Oyuncunun kontrolünü elinden alan otomatik karar (karakter oyuncu yerine seçim yapmaz).
- ❌ "Şöyle bir sistem olabilir" muğlaklığı. Sayı, eşik, aralık ver.
- ❌ Çıktıyı kısaltmak için tabloları örnek birkaç satırla geçiştirme. İstenen satır sayıları alt sınırdır.

---

## 7. KALİTE ÇITASI

Çıktın şu testi geçmeli — kendin uygula, geçmiyorsa düzelt:

1. **Mühendis testi:** Opus bu belgeyi okuyup sana tek bir soru sormadan kodlamaya başlayabiliyor mu?
2. **Teşhis testi:** §A'daki her satır gerçek bir dosya/alan/ölçüme bağlı mı, yoksa genel oyun tasarımı
   lafı mı?
3. **Bedel testi:** §E'de iyi niyetin bedeli ile zalimliğin ödülü dengeli mi? Sistem vaaz veriyor mu?
4. **Okunabilirlik testi:** her gizli sistemin bir görünür yüzü var mı (§F)?
5. **Anayasa testi:** §1.4'teki dokuz kuraldan biri kırılıyor mu?
6. **Bağ testi:** üç alt sistem birbirini besliyor mu, yoksa üç ayrı özellik mi?
7. **Kıtlık testi:** her öneri "kıtlık ve yokluk her mekanikte hissedilir" ilkesine hizmet ediyor mu, yoksa
   kıtlığı unutturan bir oyuncak mı?

## 8. DİL VE UZUNLUK

- **Türkçe** yaz. Teknik terimleri Türkçe kullan (durum makinesi, eşik, sürüklenme, tetikleyici, taşıyıcı);
  yerleşik İngilizce terimi parantezle bir kez ver.
- Oyun içi örnek metin yazarken bölgenin ağzıyla yaz (VERİ-5 §14 "söyleyiş") ve asla anlatıcı olma.
- Uzunluk **sınırlı değil**. Kısa tutmaya çalışma; §E ve §D'de cömert ol. Ama dolgu yazma: her paragraf ya
  bir karar ya bir sayı taşısın.
- Bölüm başlıklarını (§A–§I) birebir koru; ben bu belgeyi bölüm bölüm işleyeceğim.

**Şimdi başla. §A ile aç.**

## PROMPT SONU

---

## Yer tutucu doldurma listesi (bu kısım Fable'a gitmez)

| Yer tutucu | Nereden | Ben üretebilir miyim |
|---|---|---|
| `[[VERİ-1]]` | `scripts/autoload/game_session.gd`, `scripts/travel/journey_controller.gd` | ✅ paket hâlinde hazırlarım |
| `[[VERİ-2]]` | `scripts/events/*.gd` (10 dosya) | ✅ |
| `[[VERİ-3]]` | `scripts/character/*.gd` (seçili 9 dosya) + `scripts/campaign/*.gd` | ✅ |
| `[[VERİ-4]]` | `scripts/economy/*.gd`, `plague_world.gd`, `contract_board.gd`, `settlements.json` | ✅ |
| `[[VERİ-5]]` | `docs/lore/SIDERIA.md` | ✅ (hazır, tek dosya) |
| `[[VERİ-6]]` | Simülatörleri koşturup çıktılarını almak | ✅ koştururum (~10 dk) |
| `[[VERİ-7]]` | Senin kendi oyun oturumu notların | ❌ yalnızca sen |

**Bağlam bütçesi uyarısı:** VERİ-1 ile VERİ-4 arası ham kod epey büyük. Hepsini birden vermek yerine
iki tur öneririm: önce VERİ-1, 2, 5, 6 (tasarımın omurgası); Fable'ın §A teşhisi geldikten sonra, eksik
gördüğü yerler için VERİ-3 ve 4. İstersen ben her veri bloğunu ayrı dosya olarak paketleyeyim.
