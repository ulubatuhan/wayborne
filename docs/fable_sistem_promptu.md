<!-- ÜRETİLMİŞ DOSYA. Elle düzenleme: kaynak docs/fable_promptu_sablon.md,
     üretici tools/fable_paket.py. Üretim: 2026-11-10 14:16 · depo 5df5bae -->

> **Kullanım:** aşağıdaki metnin tamamını (bu satır dahil değil) Fable 5.2'ye yapıştır.
> Oyunun bugünkü durumu, 101 kartın tamamı, kataloglar, dünya kitabı ve ölçüm raporları içinde
> gömülü; Fable'ın ayrıca dosya istemesine gerek yok. Tek boş alan VERİ-7 (senin oyun notların).

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
- **Veri elinde.** §3'te oyunun bugünkü durumu (kayıt alanları, sabitler, 101 kartın tamamı, kataloglar,
  27 yerleşim, dünya kitabı ve ölçüm raporları) depodan çıkarılmış hâliyle duruyor. Dosya isteme, soru
  sorma; cevabın orada.
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

## 3. VERİ: OYUNUN BUGÜNKÜ HÂLİ

Aşağıdaki altı bölüm **depodan otomatik çıkarıldı**, elle yazılmadı; oyunun bugünkü gerçek durumudur.
Hiçbirini atlama, hiçbirini "örnek" sanma. Bir şeyi tasarlarken "acaba var mı" diye merak edersen cevabı
burada: yoksa yok.

### VERİ-1 · OTURUM VE SEFER DURUMU

Oyunun bütün kalıcı durumu tek bir nesnede (`GameSession`, RefCounted) duruyor; ekranlar onu `GameState.get_session()` ile okur. Sinyal yolu (event bus) **yok**: dinleyicisi olmadığı için kaldırıldı.

**Kayda yazılan alanlar (kalıcı durum — kaydetme yalnızca şehirde olur)**

```
accepted_contracts, banned_locations, bonds, bought_here, burned_warmth_day, caravan_name
city_morale, combat_roster_ids, contracts_delivered, crew_hungry_nights, crew_lost_to_hunger, crew_missing
crew_name_serial, crew_names, current_location_id, day_beats, debts, delivered_wagon_quest_ids
difficulty, earned_wagon_milestones, equipment_inventory, event_chains, fate_mode, first_times
flags, fulfilled_commission_starts, gold, hired_recruit_indices, journal, journey
journey_camps, journeys_completed, known_routes, last_beg_day, last_clock_hour, last_feast_day
last_feast_evening_day, last_fire_day, last_mercy_day, last_story_day, last_swindle_day, leader_since_day
ledger, legacy, lineage_generation, map_trail, market, market_stock
meal_policy_ids, meal_policy_mode, memorial_serial, next_character_serial, origin_id, outfit_inventory
owned_dogs, owned_donkeys, owned_half_wagons, owned_wagon_count, owned_wagon_damaged, pack_inventory
party, people, perishable_days, plague, plague_news, play_seconds
price_book, profiteering_sales, provisions_bought_day, provisions_bought_today, provisions_bought_where, raids_bought_off
recent_card_ids, recent_decisions, reputation, road_memorials, route_conditions, route_memory
seen_event_ids, seen_places, standing, standing_camp_at_dusk, standing_milestones_reached, tailor_sold
tavern_banned_day, total_days_elapsed, trade_stain_until_day, version, visited_location_ids, wagon_inventories
world_events
```

**GameSession - kervanın bütün kalıcı durumu · ayar sabitleri (`scripts/autoload/game_session.gd`)**

```
PROVISIONS_ITEM_ID                 = "provisions"
PROVISIONS_ITEM_NAME               = "ITEM_PROVISIONS_NAME"
PROVISIONS_UNIT_PRICE              = 4
LOAN_BASE_LIMIT                    = 200   # alırsan (orta itibarda) 220 borçlanırsın, yani zamanında ödesen bile borçlanmak bedava değil - ve loncanın tanımadığı bir kervancı daha kötü şartla borçlanır, tıpkı kredi hattının kendisi gibi.
LOAN_LIMIT_PER_REPUTATION          = 25
LOAN_MAX_LIMIT                     = 1200
LOAN_ORIGINATION_PERCENT_UNTRUSTED = 15   # depoda zaten reputation=20 ile test edilen üç senaryo var (`test_city_commerce.gd`), ortalamayı oraya sabitlemek onları hiç dokunmadan doğru bırakıyor.
LOAN_ORIGINATION_PERCENT_TRUSTED   = 5
LOAN_FEE_REPUTATION_CAP            = 40
LOAN_STEP                          = 25
LOAN_MIN_AMOUNT                    = 25
LOAN_MIN_REPUTATION                = 0   # Loncanın kapıyı kapattığı nokta. Sıfırın altı "bu kervancı sözünü tutmadı" demek - ucuz paranın tam ihtiyaç duyulduğu anda çekilmesi bilerek: itibar, defterdeki tek gerçek teminat.
LOAN_CREDITOR_KEY                  = "DEBT_CREDITOR_GUILD"   # Alacaklı adı bir çeviri anahtarı.
ADVANCE_MIN_VALUE                  = 25   #  **Açık hesap kaldı.** Kese eksiye düşünce doğan borç bir kredi değil, *sıfırın altına inememenin adı*; o iyi çalışıyor.
CURSE_LIFT_PRICE                   = 60   # Lanetin kilisedeki bedeli. Bir taze huyu arındırmaktan pahalı: bir bağ koparılıyor, parça da gömülüyor (depoya dönmez).
TAILOR_MIN_PIECES                  = 3
TAILOR_HALF_CHANCE_PRICE           = 40.0   # Fiyatı bu kadar olan bir giysinin tezgâhta bulunma ihtimali yarı yarıya.
OUTFIT_RESALE_FACTOR               = 0.4   # Satış: terzi ikinci el giysiyi fiyatının bu payına alır - al-sat bir para kapısı olmasın diye satış her zaman alıştan çok aşağıda.
RAID_PATIENCE                      = 3   # para veriyor"), ve dördüncü çete pazarlık etmez. Sayaç gerçek bir dövüşle sıfırlanır. Kuşak boyunca taşınır, sefere bağlı değil: yolun hafızası şehirde silinmez.
COMBAT_SAFE_REGIONS                = ["ahit", "gocebe"]   # yolu (kullanıcı, 2026-11-07: "aşırı korunan bir yer orası, lore'da açıklamıştım"), Gokyurt (`gocebe`) obaların kendi törelerinin yürüdüğü bozkır - yolu kesen, obanın kanına girer.
GUARDED_REGION                     = "imparatorluk"   # Kuzey Krallığı (Vaelghard). Krallığın *şehirleri arasındaki* yol devriyeli; garanti yalnız iki ucu da krallık şehri olan yollarda kalkar - krallıktan sınıra çıkan yol hâlâ yoldur (kullanıcı: "kuzey krallığı şehirleri ...
RECENT_CARD_MEMORY                 = 12   # Niye iki ayrı kayıt: `seen_event_ids` soy boyunca birikir ("bu kartı hiç gördün mü"), bu halka yakın geçmişi tutar ("bunu yeni gördün"). İkisi ayrı sönüm katsayısı alıyor; biri unutmaz, öbürü unutur.
RECENT_DECISION_COUNT              = 3   # Merhametli profilleri ölüyordu ama **hangi kararın öldürdüğü** görünmüyordu; oyuncunun hatayı öğrenmesi için gereken tek şey buydu. Defter neyin olduğunu yazıyor, bu neyi seçtiğini.
BROTHERHOOD_DANGER_SHARE           = 0.01   # Kardeşlikle arası iyi olan kervana yol daha az pusu kurar, kılıç çekmiş olana daha çok (±%20). Kardeşlik bölge tanımaz: haraç kralları birbirine haber verir.
BROTHERHOOD_DANGER_LIMIT           = 0.2
DANGER_GROWTH_PER_DAY              = 0.004   # diye. caravan_planner.gd ve world_map.gd rotanın ham danger_level'ını göstermek yerine bunu okur, start_journey() de bununla çağrılır - ekranda görülen ile yaşanan tutarlı kalsın diye.
DANGER_GROWTH_CAP                  = 1.6
CONVOY_SPEED_PENALTY_PER_WAGON     = 0.05   # Artık uzayan kolon yavaşlar ve dikkat çeker - büyümek bir karar, bir düğme değil. (Y-C24, "büyüme kendi krizini doğursun".) Bedeller kesmiyor, ekliyor: vagon hâlâ kapasite ve parti yeri açıyor.
CONVOY_MIN_SPEED_FACTOR            = 0.70
CONVOY_DANGER_PER_WAGON            = 0.045
CONVOY_DANGER_MAX                  = 0.20
DANGER_PART_BASE                   = "base"   # her biri {"part", "value" (adımdan sonraki tehlike), "delta", "arg"}. Son adımın değeri get_route_danger ile birebir (test_world_map_data); planlayıcı bunu yazar, bir gizli ceza hatadan ayırt edilemez.
DANGER_PART_STATE                  = "state"
DANGER_PART_WORLD                  = "world"
DANGER_PART_GROWTH                 = "growth"
DANGER_PART_CONVOY                 = "convoy"
DANGER_PART_BROTHERHOOD            = "brotherhood"
ONBOARDING_FLAG                    = "onboarding_seen"   # İlk şehir varışında bir kereye mahsus gösterilen atlanabilir ipucu katmanının bayrağı (bkz. city_map.gd, scripts/ui/onboarding_panel.gd).
MAX_STRESS                         = CharacterData.MAX_STRESS   # Stresin **sahibi artık kişidir** (bkz. CharacterData.stress). Buradaki tavan onun takma adı: iki ayrı sayı tutmak, ikisi ayrıştığı gün kenetlemenin bir tarafta çalışıp öbüründe çalışmaması demekti.
FATIGUE_PUSH_PER_DAY               = 8   # (`get_caravan_theoretical_speed`, `JourneyController.effective_rate`). Yalnızca gönüllü hızlı tempoyu kilitler ve kilit kervanı normale indirir - normal tempoda "doğru stoklayan asla aç kalmaz" aynen durur.
FATIGUE_VANGUARD_PER_DAY           = 4
FATIGUE_MIDDLE_RELIEF_PER_DAY      = 4   # Kervanın ortasında (ortancı) yürüyen günü dinlenerek geçirir.
FATIGUE_COMBAT                     = 8
FATIGUE_EARLY_START                = 4
FATIGUE_NIGHT_PER_HOUR             = 0.5   # Işıksız gece yürüyüşü: saat başı pay birikir, 4'lük dilimlerle yazılır (iri bedenin %25'i yuvarlamada kaybolmasın diye).
FATIGUE_NIGHT_CHUNK                = 4
FATIGUE_CAMP_RELIEF                = 30   # Kamp ateşi başındakileri dinlendirir; kampta herkes ateşe varır.
FATIGUE_CITY_RELIEF                = 60   # Şehirde bir gece: yorgunluğun çoğu gider, tamamı değil - çok zorlanan öncü bir sonraki sefere biraz yorgun çıkar.
NEWCOMER_STRESS_SHARE              = 0.4   # gönder, yenisini tut" stresi tek hamlede düşüren bedava bir düğmeye dönerdi; bu payla her tur azalan bir getiri veriyor ve her turun ücreti var (bkz. hire_cost).
FEAST_COST_PER_HEAD                = 45   # oyuncunun kesesiyle müdahale edebileceği bir kolu olmalı - yoksa stres kaçınılmaz bir sayaca dönerdi. Ücret kişi başı, çünkü kalabalık kadroyu doyurmak pahalıdır.
FEAST_STRESS_RELIEF                = 22
MAX_MAP_TRAIL                      = 120   # Kervanın haritadaki izi (görev Y-G09): biten seferlerin yolları ve kamp kurulan yerler. Defterin haritadaki karşılığı - kayda yazılıyor, sınırlı.
MAX_JOURNEY_CAMPS                  = 300
LODGING_COST_PER_HEAD              = 6   # yorgunluk tamamen gider, yaralar dörtte bir kapanır, stres biraz iner ve bir gün geçer (dünya yürür: borç vadesi, kontrat süresi, veba, şehrin hâli). Kıtlık oda fiyatını da yükseltir; ziyafetten ucuz ama günü yer. Def...
LODGING_STRESS_RELIEF              = 6
LODGING_HEAL_SHARE                 = 0.25
BEG_BASE                           = 14   # **Dilencilik.** Yalnızca meyhanecinin karşısında ve **aç karna**: tok bir kervanbaşı el açmaz. Kullanıcının iki şartı da burada.
BEG_PER_CHARISMA                   = 1.1
BEG_STRESS                         = 5
BEG_REPUTATION                     = -1
BEG_CITY_FLOOR                     = 0.15   # Aç bir şehir veremez; kıtlığın en somut cümlesi bu.
HUNGRY_LARDER_DAYS                 = 2   # bir kez bile tetiklenmedi. Doğrusu **ambarın dibi**: erzak önümüzdeki birkaç günü çıkarmıyorsa bu kervan açtır. Tok karna el açılmaz, ama "tok" demek dolu bir ambar demek.
SWINDLE_BASE_ODDS                  = 0.12   # Kontrol iki ayağı birden okuyor - kurgu Zeka, anlatım Karizma. Bu, Haggling Rules'un "ikisinin iyisini al" tuzağı değil: iki ayrı katkı toplanıyor, ve ağırlık Zeka'da.
SWINDLE_PER_WITS                   = 0.055
SWINDLE_PER_CHARISMA               = 0.03
SWINDLE_MIN_ODDS                   = 0.10
SWINDLE_MAX_ODDS                   = 0.80
SWINDLE_PRICE_FACTOR               = 9   # Malın "aslında ne ettiği" ile satıldığı fiyat arasındaki uçurum.
SWINDLE_CAUGHT_REPUTATION          = -3
SWINDLE_CAUGHT_STRESS              = 8
MAX_PARTY_SIZE                     = 4   # yatar), ama savaş alanı dört mevkiden ibaret olduğu için tavan MAX_PARTY_SIZE. Yani vagon almak partiye yer açar - kervansaraydaki vagon alımı böylece savaşa da dokunuyor.
PEOPLE_PER_WAGON                   = 2
STARTING_WAGONS                    = 1   #  Bir vagon tam iki kişilik yer açar (get_party_capacity), yani kadro baştan dolu: üçüncü kişi ancak kervansaraydan vagon alınca gelebilir.
STARTING_PARTY_SIZE                = 2
FATHER_DEBT_ID                     = "father_debt"   # akışı (karakter oluşturma) start_playthrough'tan sonra çağırır; borçsuz başlangıç isteyen testler çağırmaz. Tutar ve vade ölçülecek (akşam testi, simulate_career) - onay paketinde kullanıcıya soruluyor.
FATHER_DEBT_PRINCIPAL              = 180
FATHER_DEBT_TERM_DAYS              = 120
FATHER_DEBT_REPUTATION_PENALTY     = 1   # Aile borcunun gecikme bedeli yumuşak: alacaklı akraba, adını sokakta çürütmez. (Faiz P10'da kaldırıldığı için yumuşaklığın tek ölçüsü bu.)
FATHER_CREDITOR_KEY                = "DEBT_CREDITOR_FATHER"
FATHER_CAUSE_KEY                   = "LEDGER_CAUSE_FATHER"
DISMISSED_CAUSE_KEY                = "LEDGER_CAUSE_DISMISSED"   # Oyuncunun kendisi çıkarılamaz. Kontrol sıraya göre değil bayrağa göre: oyuncu arkaya geçtiğinde kendini atabilmesi bir hataydı.
RUN_OVER_FLAG                      = "run_ended_leader_lost"   # Lider ölürse kervan dağılmaz: oyuncu hayatta kalanlardan birini seçer (kıdemli önceden seçili), hikâye onunla sürer. Kimse yoksa oyun biter - oyunun ilk gerçek game-over'ı bu, ve tek koşulu "ölen liderin yerine geçece...
SHARED_GRIEF_DAYS                  = 30   # yolu yürüyen aynı ölümü aynı yükle taşımıyor. Ağırlık kalıcı kırgınlığa değil strese biniyor - stres handa erir, kırgınlık erimez, ve Stress Rules'un ölçülmüş ayrılma tavanı böylece yerinde kalıyor.
SHARED_GRIEF_STRESS                = PASSED_OVER_STRESS / 3
PASSED_OVER_STRESS                 = 15   # kervan kurmuyor, aynı adı devralıyor. Kıdemliyi geçip başkasını seçmek kıdemliye bir kırgınlık ve stres bırakır - liderliğin kime geçtiği bir karar, bir bildirim değil. Yeni kuşak numarasını döner.
VANGUARD_DAILY_STRESS              = 1   # --- Kamp: ertesi günün dizilişi ve akşam eylemleri (görev Y-B12) --- Öncü önde gider ve bunun bedelini taşır: her yol günü stresi artar (ilk iz onun, ilk ok da). Bu yüzden kampta kimin önde yürüyeceği bir karar.
CAMP_ACTION_LIMIT                  = 2
CAMP_ACTION_WATCH                  = "watch"
CAMP_ACTION_WOUNDS                 = "wounds"
CAMP_ACTION_REPAIR                 = "repair"
CAMP_ACTION_HUNT                   = "hunt"
CAMP_ACTION_TALES                  = "tales"
CAMP_ACTION_BURN_CANVAS            = "burn_canvas"   # Son çareler (Y-C23): kervanı son eşyalarını yakmaya, yemeye iten eylemler. Yakılan şey o gecenin soğuğunu kırar; yenen tohum bugünü kurtarır.
CAMP_ACTION_EAT_SEED               = "eat_seed"
CAMP_ACTION_BURN_FURS              = "burn_furs"
CAMP_ACTION_BURN_PLANKS            = "burn_planks"
CAMP_ACTIONS                       = [CAMP_ACTION_WATCH, CAMP_ACTION_WOUNDS, CAMP_ACTION_REPAIR, CAMP_ACTION_HUNT, CAMP_ACTION_TALES,
BURN_WARMTH_C                      = 6.0
SEED_EATEN                         = 6
FURS_BURNED                        = 2
CAMP_WOUND_HEAL_SHARE              = 0.25
CAMP_HUNT_PROVISIONS               = 2
CAMP_TALES_STRESS                  = -2
PRUDENT_MANIPULATION_BONUS         = 1.5   # Rules), huy onun üstüne binen, herkeste çıkmayan bir keskinlik. Karizma'yı değiştirmiyoruz, üstüne bir pay ekliyoruz - stat kendi başına yeter, huy şansı olan için bir eşiği daha kolay geçirir.
FORCE_LOOK_MERCHANT_REPUTATION_PENALTY = 2   # Zorla bakmak izin gerektirmiyor ama bedelsiz değil - `HagglingSession. WALKOUT_REPUTATION_PENALTY`'nin aynı ailesinden küçük bir itibar bedeli.
MERCHANT_PERSUASION_BASE_CHANCE    = 0.25   # "Tekrar ikna et" - `evt_mutiny`'nin manipüle seçeneğiyle aynı vokabüler (get_effective_manipulation), yeni bir sistem icat etmiyor.
MERCHANT_PERSUASION_PER_CHARISMA   = 0.08
MERCHANT_PERSUASION_MIN_CHANCE     = 0.05
MERCHANT_PERSUASION_MAX_CHANCE     = 0.85
PRUDENT_EVENT_STRESS_RESIST        = 0.7   # Type.STRESS) bu kapıdan geçiyor, ve yalnızca stresi *yükselten* bir darbeyi hafifletiyor - bir olayın stres *azaltan* tarafını (dinlenme, iyi haber) kısmıyor değiliz.
BREAK_AFFLICTION_CHANCE            = 0.85   # (oyuncu hariç) kervandan ayrılabilir - kırılma huy vermeyi başaramasa bile (tavan dolu) ayrılık ihtimali işler, çünkü sorun huyun kendisi değil, karakterin dayanma noktasının aşılmış olması.
BREAK_DEPARTURE_CHANCE             = 0.2
GRIEVANCE_DEPARTURE_PER_POINT      = 0.03   # tutulup kaybı izleyen, liderlikte geçilen biri kırıldığında gitmeye daha yakındır. Yalnızca zaten kırılmış birinde işler - kırılma eşiğinin kendisine dokunmuyor, Stress Rules'un ölçülmüş tablosu korunuyor.
MAX_BREAK_DEPARTURE_CHANCE         = 0.6
CAMP_PROVISIONS_COST               = 3   # varmadan nefes almanın tek yolu (bkz. road_journey.gd _on_camp_pressed). Gün ilerletme/erzak tüketimi çağıran tarafın işi, burada yalnızca kampın kendi payı var.
CAMP_HOURS                         = 8.0   # Kampın sürdüğü oyun saati: o saatlerde kervan yol almıyor. Yol ekranı ve planlayıcının akşam kampı payı aynı sayıyı okuyor.
CAMP_STRESS_RELIEF                 = 8   # Artık kamp birikmeyi **yavaşlatıyor**, silmiyor: bir gecelik mola bir seferin yükünün üçte birini alıyor. Kesenin kolu (ziyafet) ondan güçlü, çünkü onun bir bedeli var.
HOSPITALITY_REGION                 = "gocebe"   # konsey öder. Öbür bölgelerin kervansaraylarında da eskiden böyleydi; kıtlıkta kaldırıldı. Oyunda gün yalnızca yolda aktığı için bir gece olarak çevrilir: bir kamp gecesinin dinlenmesi ve kervanın bir günlük sofrası.
ROAD_STRESS_PER_DAY                = 2   #  Küçük tutuluyor: bir seferin yükünü olaylar ve savaş belirlemeli, yol yalnızca tabanı koymalı.
MEAL_MODE_ALL                      = "all"   # `get_daily_provision_consumption()`'dan geliyor - erzak hesabının tek yerde durması kuralı burada da geçerli, bu yalnızca o toplamı kime dağıtacağını seçiyor.
MEAL_MODE_PARTY_ONLY               = "party_only"
MEAL_MODE_CREW_ONLY                = "crew_only"
MEAL_MODE_SPECIFIC                 = "specific"
MEAL_MODE_SELF_ONLY                = "self_only"
PERSONAL_HUNGER_STRESS             = 6   # işler (bkz. Stress Rules'un "stres bir kişiye ait" maddesi), ortalamaya değil. Kervan/tayfa aç kalırsa kimse kişisel bir stres almaz (isimsiz), ama moral bir kez düşer - herkes bunu hissediyor.
STARVATION_HP_LOSS_START_DAY       = 3   # stoklayıp herkesi doyuran bir kervanda sayaç hiç artmaz (bkz. Provision Rules'un "correct stocking never starves" sözü) - bu yalnızca seçilerek ya da kıtlıkla aç bırakılanı bulur.
STARVATION_HP_LOSS_PER_DAY         = 4
MEAL_HUNGER_MORALE_PENALTY         = -8
CREW_HUNGER_MORALE_PER_NIGHT       = 3   # seçimdi; isimsizler hiç sayılmıyordu. Art arda her aç gece moral biraz daha düşüyor, ve üçüncü geceden itibaren her gece tayfadan biri açlıktan ölüyor - deftere adıyla.
MAX_CREW_HUNGER_MORALE_PENALTY     = -20
CREW_DESERT_FROM                   = STARVATION_HP_LOSS_START_DAY   # Kademe: üçüncü aç geceden itibaren her gece bir el **ayrılır** (yürüyebilen gider), yedinciden itibaren artık **ölür** (yürüyecek hâli kalmamıştır). Önce seni bırakırlar, sonra seninle ölürler.
CREW_STARVE_FROM                   = 7
CREW_DEATH_SHARE_EARLY             = 0.15   # Geç gecelerde yalnız ölüm olması da aynı kusurun öbür yüzü - aç bir ekipte her gece hem bırakan hem düşen vardır; değişen oran. Pay hiçbir zaman 1,0'e varmaz: kervanı bırakıp gitmek her gece mümkün kalır.
CREW_DEATH_SHARE_LATE              = 0.65
CREW_DEATH_SHARE_MAX               = 0.85
HUNT_PROVISIONS                    = 10   # Av: yabani hayvana karşı kazanılan savaş et getirir. Köy durağı erzak satar (şehirden pahalı - evt_village_provisions). Toplayıcılık zaman yer (evt_forage'un "topla" seçeneği bir gün uzatır).
FORAGE_BASE                        = 6   #  Bedava değil: bozkırda ve çölde az bulunur, kış payı düşürür, ve kaybedilen gün vadeleri yaklaştırır. Bolluk yolu değil, **ölmeme yolu**.
FORAGE_PER_PERCEPTION              = 0.7
FORAGE_BIOME_SHARE                 = {
FORAGE_WINTER_SHARE                = 0.55
FORAGE_STRESS                      = 3
FORAGE_PER_EXTRA_HAND              = 0.35   # aramak durumu kötüleştiriyordu. Fazladan her el payı büyütür - böylece aramak büyük kervan için de gerçek bir tutunma hamlesi olur, ama hâlâ çare değil bedelli bir erteleme.
FEAST_EVENING_INTERVAL             = 7   # Bu bir seçim olduğu için yalnızca sofra açıkken sorulur; kalıcı emir çeşniyi kendiliğinden açmaz. Bolluk varken de her FEAST_EVENING_INTERVAL günde bir "ziyafet akşamı" sofrayı açar, çeşni varsa.
MEAL_EXTRAS                        = [
MIN_TRAIT_PRICE_MULTIPLIER         = 0.85   # tamamındaki Basiretli/Saf huyları toplanıyor - "en keskin pazarlıkçı" değil, kervanın genel şöhreti/deneyimi; her ikisi de bir sistemi asla tamamen kapatamaz (bkz. MIN/MAX), taban (huysuz kervan) tam 1.0.
MAX_TRAIT_PRICE_MULTIPLIER         = 1.15
AVUCICI_REGION                     = "ahit"   # ticaret loncasının aracılarıyla, fazladan komisyon ödeyerek yapar. Kervanın inancı kervanbaşınınki (Y-C34). Şehirde görülen ya da inançlı rolü yapan inançsızın eli kesilir (olay kartı `evt_avucici_hand`).
GATE_BROKER_COMMISSION             = 0.2
TRADE_STAIN_BUY                    = 1.25   # Ticaret lekesi (Y-C26, kullanıcı notu: köyü zorla basan kervan "ticari eylemlerde ciddi oranda dezavantajlı" olmalı): bir süre pazar kervana pahalı satar, ucuza alır. Kayıtta; süre dolunca kalkar.
TRADE_STAIN_SELL                   = 0.8
NEWS_CULTURE_SHARE                 = 0.5   # Tavernada sohbetle haber alma şansına eklenen pay (N34): liman kültürü (söylentiye yakın) ve tellal (dedikoduyu toplayan). Satın alma yok.
NEWS_TELLAL_SHARE                  = 0.6
NEWS_CARAVANSERAI_SHARE            = 0.2   # Kervansarayda her yerden yolcu var (Y-C28): söylenti şehirdekinden kolay.
REPUTATION_PENALTY_PER_LOST_CONTRACT = 3   #  Teslimat artık kazandırıyor ve kayıp cezası düştü: dört kontratın üçünü teslim eden bir kervan net **artıda** çıkar (3×2 − 1×3 = +3).
REPUTATION_PER_DELIVERED_CONTRACT  = 2
MIN_REPUTATION                     = int(Standing.MIN_VALUE)   # Dibi artık `Standing` uyguluyor (bölgesel itibar, T16-07); buradaki sabit "eşiği olmayan kapı" işareti (bkz. RecruitCatalog.VENUE_MARKET_PROFILE). İkisi ayrı yerde -20 yazılıydı: dip değişse meydan yanlış yerde kapanı...
STANDING_MILESTONES                = [10, 25, 50]   # geçildiğinde deftere bir satır düşüyor ve bir daha düşmüyor.  Kâr tavanı korunuyor - verilen şey para değil, tanınma.
WAGON_PURCHASE_BASE_COST           = 150   # Kervansaray fiyatları: yeni vagon sahip olunan vagon sayısı arttıkça kademeli pahalanır, onarım hasarlı vagon başına sabit ücrettir.
WAGON_PURCHASE_COST_STEP           = 60
WAGON_REPAIR_COST_PER_WAGON        = 30
WAGON_RESALE_FACTOR                = 0.55   # Hasarlı bir vagon daha da az eder ve avlu **önce onu** alır: bir enkazı onarmak yerine satmak gerçek bir seçenek olsun diye. Onarım (30/vagon) her zaman sat-ve-yeniden-al'dan ucuz, o yüzden bu bir kaçamak değil.
WAGON_DAMAGED_RESALE_FACTOR        = 0.6
MAX_DOGS                           = 2   # fazlası bu payı bir stat'ı geçersiz kılacak noktaya taşırdı - "bir stat bir sistemi asla tamamen kapatmaz" kuralının tersi: burada kapatılmaması gereken şey statın kendisinin anlamı.
DOG_ADOPTION_BASE_COST             = 80
DOG_ADOPTION_COST_STEP             = 40
DOG_PROVISION_SHARE                = 0.4   # Bir insan gibi besleniyor - CaravanPlan.daily_consumption'ın erzak formülüne tam bir ağız değil, kesirli bir pay olarak giriyor (bkz. get_pack_animal_provision_mouths). Bir köpek bir insan kadar yemiyor.
PACK_ANIMAL_PROVISION_SHARE        = 0.3   # Eşek/yarım vagonun kendi çeken hayvanı da besleniyor, köpekten daha küçük bir payla - kervanın asıl mürettebatı değiller.
DOG_PERCEPTION_BONUS_PER_DOG       = 0.6   # effective_stat`/`get_leader_effective_stat` yalnızca PERCEPTION için bunu ekliyor, o yüzden "iz sürme/awareness" dışındaki hiçbir check etkilenmiyor.
MAX_DOG_PERCEPTION_BONUS           = 1.2
DOG_MORALE_BONUS_PER_DOG           = 2   # "Küçük ölçüde" moral katkısı - DEPARTURE_TEMPERAMENT_BONUS_CAP'in (6) yarısı büyüklüğünde bir tavan, hardship/stres payını asla ezmesin diye.
MAX_DONKEYS                        = 3   # Eşek satın almak "ekstradan hacim" - kendi vagonu yok, kervanın ortak yük fazlasına (bkz. pack_inventory) katkı veriyor.
DONKEY_PURCHASE_BASE_COST          = 50
DONKEY_PURCHASE_COST_STEP          = 20
CARGO_PER_DONKEY                   = 15.0
MAX_HALF_WAGONS                    = 3   # eklemiyor), parti kapasitesi açmıyor, yalnızca eşek gibi kervanın ortak yük fazlasına katkı veriyor, biraz daha fazlasıyla (tam bir vagonun yarısı kadar, adından da bu).
HALF_WAGON_PURCHASE_BASE_COST      = 90
HALF_WAGON_PURCHASE_COST_STEP      = 30
CARGO_PER_HALF_WAGON               = 25.0
CARGO_PER_WAGON                    = 50.0   # Vagon başına taşınabilecek yük. Yalnızca pazardan alınan mallara uygulanır; erzak kendi sefer formülüyle sınırlı, kapasiteye dahil değil.
MIN_MORALE_PAYOUT_FACTOR           = 0.5   # Sefer sonu ödemesi: moral ve hasar ne kadar düşükse ücret o kadar kısılır ama asla sıfırlanmaz - kervan ağır kayıp yaşayabilir, aç kalmaz.
DAMAGE_PENALTY_PER_WAGON           = 0.08
MIN_DAMAGE_PAYOUT_FACTOR           = 0.4
TRADE_MERCY_STANDING               = 2   # krizin şişirdiği fiyattan satmak bir kin. İkisi de deftere yazılıyor, bölgesel itibara ve o şehrin adı olan kişilerinin gönlüne dokunuyor. Sıradan bir satış hiçbir şey yapmaz - yoksa defter alışveriş fişine döner.
TRADE_PROFITEER_STANDING           = -3
TRADE_MERCY_MIN_QUANTITY           = 3   # Kaç adet "bir iyilik" sayılır: tek bir çuval buğdayla aç bir şehri kurtardığını iddia etmek ucuz olurdu.
ROAD_PLAGUE_NEWS_CHANCE            = 0.3   # Yolda veba haberi (Y-C25, kullanıcı notu: "yolda ya da şehirde"): karşıdan gelen yolcular gittiğin yerin ya da onun komşusunun hâlini söyler.
MORALE_START                       = 50.0
MORALE_DRIFT                       = 2.0
MORALE_PER_FOOD                    = 0.5
MORALE_FOOD_CAP                    = 15.0
MORALE_PER_DELIVERY                = 6.0
MORALE_HUNGRY                      = 30.0
HUNGRY_FOOD_SELL_RISE              = 0.4   # Aç şehir yiyeceğe çok verir: moral düştükçe yiyeceğin satış fiyatı artar.
PLAGUE_CATCH_UP_DAYS               = 400   # Eski kayıt: model yoksa kurulur ve kaydın gününe kadar ilerletilir.
NEUTRAL_GROUND_ID                  = "serai_duvenmor"
HOLY_CITY_ID                       = "orvahel"
CONVOY_FEE                         = 10   # Kafile: panodaki yöne giden kafileye bir sonraki seferde katılırsın; yavaş ama güvenli. Avuçiçi'ne (Orvahel) giden hacı kafilesi yalnızca Septisistleri alır. Sürücü: bir seferlik arabacı; görevde arabacı yoksa onun iş...
CONVOY_DANGER                      = 0.7
CONVOY_EXTRA_DAYS                  = 1
DRIVER_FEE                         = 30
HIRED_DRIVER_POWER                 = 1.4
FLAG_HIRED_DRIVER                  = "hired_driver"
DOMINO_LINKS                       = ["axle", "long_road", "hunger", "fever"]   # bitirir, açlık ateş getirir (FEVER_HUNGRY_BONUS), ateşli biri savaşta düşer. Zincirin açık halkaları dertler listesinde tek cümle; RoadDirector sonraki halkanın kartına ağırlık verir. ---
DOMINO_KEYS                        = {
GOLD_DANGER_PER                    = 6000.0   # - vagon çoğaltmak kıtlıkta çok ağız ve uzaktan görünen bir kervan demek, - ün aç şehirde yüke el konmasını getirir (evt_cargo_seized), - kalabalık kadro hiziplere bölünür (evt_faction_split). ---
GOLD_DANGER_CAP                    = 0.12
WAGON_DANGER_FROM                  = 2
WAGON_DANGER_EACH                  = 0.02
REGION_CREEDS                      = {   # inanç o bölgenin inançları arasından rastgele gelir (kullanıcı kararı 2026-11-01); şehrin baskın inancı iki kat ağırdır. Zar karakterin kimliğinden: aynı kişi her yüklemede aynı inançta.
PLACE_CREEDS                       = {   # Şehrin baskın inancı (LORE §4 tablosu); listede olmayan bölgenin ilki sayılır.
MERCY_CHANCE                       = 0.12   # Nadir olması ağırlığını korur: zar düşük ve iki lütuf arasında en az bir hafta. Tohum kervan ve günden: aynı akşamı yeniden yüklemek sonucu değiştirmez. Lütuf günün izine girer, günlük o akşam onu yazabilir.
MERCY_MIN_GAP_DAYS                 = 7
MERCY_STRESS                       = -3
MERCY_KINDS                        = ["blanket", "hum", "ox", "bread", "stars"]
MERCY_TEXT_KEYS                    = {
BEAT_DEATH                         = "death"   # edebi bir cümleye döner ve oyuncu üç cümleden birini deftere yazar (ya da o gün hiçbirini). Cümlelerde sayı yok (Y-H03'ün dil kılavuzu); adlar cümlenin içinde, anahtar defterde.
BEAT_WAGON                         = "wagon"
BEAT_LOST                          = "lost"
BEAT_WON                           = "won"
BEAT_HUNGER                        = "hunger"
BEAT_STORY                         = "story"
BEAT_EVENT                         = "event"
BEAT_QUIET                         = "quiet"
BEAT_MERCY                         = "mercy"
BEAT_SACRIFICE                     = "sacrifice"
BEAT_WEIGHTS                       = {   # Hangi iz günün satırı olur: en ağır olanı.
DIARY_KEYS                         = {   # İz türü başına üç cümle (anahtarlar tam yazılı, Localization Rules).
CAREER_MID_JOURNEYS                = 10
CAREER_LATE_JOURNEYS               = 25
WEAR_HUNGER_DAYS                   = 4.0   #  Kollwitz dersi: kıtlığın yeri bedendir, çubuk değil. Aynı sayı çubukta bir idari iş, bedende bir korku.
MEMORIAL_GRAVE                     = "grave"   # külü yolda kalır ve kayda yazılır. Konum yönsüz: yol anahtarının ilk şehrinden ölçülen pay (0-1) - öbür yönden gelen aynı yerde görür. Yol başına MEMORIALS_PER_ROUTE; taşarsa önce en eski kül, sonra enkaz düşer.
MEMORIAL_CAIRN                     = "cairn"
MEMORIAL_WRECK                     = "wreck"
MEMORIAL_ASH                       = "ash"
MEMORIALS_PER_ROUTE                = 8
CHAIN_DONE                         = -1
FIRST_DECISION                     = "first_decision"   # GameState her karede ekler) ve dört ilkin ne zaman yaşandığı. Dış oyuncu testlerinde ölçmek için; ilk kez işaretlenince user://playtest_times.json'a da bir satır düşer. Kayıtta.
FIRST_THREAT                       = "first_threat"
FIRST_LOSS_RISK                    = "first_loss_risk"
FIRST_PROFIT                       = "first_profit"
FIRST_BEGGED                       = "first_begged"   # Kervanbaşının ilk kez el açtığı gün (bkz. beg_in_tavern).
FIRST_TARGETS                      = {   # Çizelgenin hedefi (saniye): ilk karar 3 dk, ilk tehdit 10 dk, ilk kayıp tehlikesi ve ilk kârlı varış 30 dk.
PLAYTEST_LOG                       = "user://playtest_times.json"
PLAYTEST_BEATS                     = "user://playtest_beats.jsonl"   # dosyasına bir satır: tools/playtest_report.py boş dakikaları, savaşın ve kampın süresini ve ekran başına zamanı buradan çıkarır. Yalnızca gerçek oyun yazar (log_first_times'ın kapısı); testler ve simülatörler yazmaz.
BEAT_LOG_DECISION                  = "decision"
BEAT_LOG_INFO                      = "info"
BEAT_LOG_COMBAT_START              = "combat_start"
BEAT_LOG_COMBAT_END                = "combat_end"
BEAT_LOG_CAMP_START                = "camp_start"
BEAT_LOG_CAMP_END                  = "camp_end"
BEAT_LOG_SESSION                   = "session"   # Oturum başı (Y-K03): tools/measure_report.py oturum uzunluğunu bununla ayırır.
DIFFICULTY_EASY                    = 0   # Kader Modu: tek kayıt, elle kayıt yok (şehirde de). Ayarlar açık, gizli zorluk yok: ölümcül darbe direnci, açlık şiddeti, olay sertliği; her biri kolay/standart/zor. Standart bugünkü denge. Yeni oyunda seçilir, kayıtta.
DIFFICULTY_STANDARD                = 1
DIFFICULTY_HARD                    = 2
DIFFICULTY_KEYS                    = ["deathblow", "hunger", "events"]
DEATHBLOW_OFFSETS                  = [10, 0, -12]
HUNGER_DAMAGE                      = [2, 4, 6]
EVENT_SEVERITY                     = [0.75, 1.0, 1.3]
FEVER_CHANCE_PER_DAY               = 0.01   # --- Sakatlık, hastalık ve hekim (görev Y-C05) ---
FEVER_HUNGRY_BONUS                 = 0.03
PLAGUE_ARRIVAL_CHANCE              = 0.25
INJURY_CHANCE                      = 0.5
DOCTOR_FEE_INJURY                  = 25
DOCTOR_FEE_SICKNESS                = 40
PLAGUE_MEDICINE_DRAIN              = 2
DEFEAT_PLUNDER_SHARE               = 0.25   # Kaybedilen dövüşte yükün bir payı gider: haydut altını alır ama asıl istediği maldır. Kaybedilenlerin listesi döner ([{item_id, quantity}]).
CHURCH_FEE_SHARE                   = 0.01   # Kilisenin hekimi kiliseyle arası iyi olana ucuz bakar (T16-07): kilise itibarının her puanı %1, en çok %25.
CHURCH_FEE_LIMIT                   = 0.25
CHURCH_DONATION                    = 30   # Kiliseye bağış (T16-07): kesesi olan kervan kilise topluluğunda ad yapar. Kıtlıkta kilise sofra kurar; bağış o sofraya gider, şehrin hâli de biraz düzelir (Y-C21).
CHURCH_DONATION_STANDING           = 2
LIGHT_LANTERN                      = "lantern"   # --- Gece ışığı (görev Y-C20) --- Fener: fener + bir yağ; meşale: iki meşale. Bir gece yanar. Hangisi yanacak oyuncunun seçimi; ikisi de yoksa düğme sebebiyle kilitli.
LIGHT_TORCH                        = "torch"
TORCHES_PER_NIGHT                  = 2
ROT_SHARE                          = 0.25   # ortalama yaşı (gün). Raf ömrünü geçince her yol günü stoğun ROT_SHARE'i çürür (en az bir birim). Taze alım yaşı ağırlıklı ortalamayla düşürür - bir tane taze balık bütün eski stoğu tazelemez.
BUYBACK_SHARE                      = 0.9   # Aynı ziyarette alınıp geri satılan mal alış fiyatının üstünden satılmaz (görev Y-C19 sömürü kapısı): kendi alımın pazarın fiyatını şişirir, o şişkin fiyattan aynı tezgâha geri satmak para basmak olurdu. item_id -> bir...
PRICE_SOURCE_SEEN                  = "seen"   # pazar hep gerçek fiyattan alır satar. Her giriş: {"day", "source" ("seen"/"rumor"), "accurate", "buy": {id: fiyat}, "sell": {id: fiyat}}. "accurate" ekranda gösterilmez - yanlış söylentiyi oyuncu pazarda öğrenir.
PRICE_SOURCE_RUMOR                 = "rumor"
PRICE_STALE_DAYS                   = 20
PRICE_RUMOR_FALSE_CHANCE           = 0.25
PRICE_RUMOR_MIN_AGE                = 2   # Söylenti taze gelmez: kulaktan kulağa geçene kadar birkaç gün eskir.
PRICE_RUMOR_MAX_AGE                = 6
DAY_LABOUR_PROVISION_FACTOR        = 1.4   # yaklaşır, erzak tükenir), karşılığında yalnız o günün ekmeği gelir. Zenginleşmeye yol yok: kazanılan erzak, bir günlük tüketimin biraz üstü - ve yalnız gerçekten aç kervana açık.
DAY_LABOUR_STRESS                  = 4
DAY_LABOUR_MIN_PROVISIONS          = 1
DEPARTURE_MORALE_FLOOR             = 45   # Rules): stres burada moralin *başlangıcını* etkiliyor, moral olup bitince stres'e dönüşmüyor. Biri kervanın kalıcı yıpranması, diğeri o seferin ruh hali.
DEPARTURE_HARDSHIP_WEIGHT          = 30
DEPARTURE_STRESS_WEIGHT            = 25
DEPARTURE_OVERDUE_DEBT_PENALTY     = 10
DEPARTURE_REPUTATION_BONUS_CAP     = 8
DEPARTURE_REPUTATION_PER_POINT     = 0.5
DEPARTURE_TEMPERAMENT_BONUS_CAP    = 6   # (yalnızca lider değil): bir yoldaşın huzur verici hâli bütün kadroya sirayet eder, itibarın "gurur" payıyla aynı aile - küçük ve tavanlı, tek bir huy asla hardship/stres payını ezmesin diye.
RANSOM_FLOOR_PROVISIONS            = 35   #  Taban, pazarlıkla inilebilecek en düşük noktadır: bir kervancı iyi konuşarak fidyeyi buraya indirebilir, altına indiremez.
RANSOM_FLOOR_GOLD                  = RANSOM_FLOOR_PROVISIONS * PROVISIONS_UNIT_PRICE
RAID_DEAF_SHARE                    = 0.2   #  Tohum kervanın adı ve gün: aynı gün her bakışta aynı cevabı verir, kaydı yükleyip "bu sefer konuşur mu" diye yeniden zar atmak yok.
UPKEEP_FREE_WAGONS                 = 2   # oyuncunun kesesi +86'dan -4770 GG'ye düştü, aç sefer %6'dan %41'e, boş tur %28'den %81'e çıktı. Bu bir son değil sefalettir - oyun bitmiyor, yalnız iflas etmiş hâlde sürüyordu. Baskı dörtte bire indi.
UPKEEP_GOLD_PER_WAGON_DAY          = 0.5
CROWD_MORALE_FROM                  = 8   # Ağız sayısı bunu aşınca moral düşmeye başlar.
CROWD_MORALE_EACH                  = 2
CROWD_MORALE_CAP                   = 12
MIN_DIVERT_DAYS                    = 1   # şehir değil, iki şehir arasında bir nokta. Bunu yol üstünde geçirilen günle temsil ediyoruz: dönüş/sapma süresi hedefin çıkış şehrine olan mesafesi ile o ana kadar yürünen mesafenin toplamı.
WAGON_LEVEL_MILESTONES             = [4, 8]
WAGON_REPUTATION_MILESTONES        = [20, 45]
CITY_REST_STRESS_RELIEF            = 14   # fark birikiyor. Üstelik rahatlama günlerle eriyor - aynı han odası aynı kadroya on sefer sonra daha az iyi geliyor - ki "birikme gittikçe artsın". Taban var: dinlenmek hiçbir zaman tamamen işe yaramaz hale gelmemeli.
CITY_REST_RELIEF_DECAY_PER_DAY     = 0.02
CITY_REST_RELIEF_MIN               = 6
JOURNEY_XP_BASE                    = 15
JOURNEY_XP_PER_DAY                 = 4.0
JOURNEY_XP_DANGER_BONUS            = 40.0
JOURNEY_XP_FAILURE_FACTOR          = 0.25
JOURNEY_SUCCESS_MORALE_RATIO       = 0.5
LATE_RUSH_PAY_SHARE                = 0.5   # Varışta emanet yük teslim edilir (görev Y-C02): yükü eksik olan kontrat teslim edilmemiş sayılır (kervandan düşer, cezası olağan yoldan); acele kontrat geç kaldıysa ücretin yarısı. Kalan emanet yük kervandan iner.
CREW_HIRE_BASE                     = 35   # Eksik el parayla kapanır, ama fiyat sabit değil: adamını aç bırakan kervanın sözü dolaşır (`crew_lost_to_hunger`). Yolda tasarruf ettiğin erzağı şehirde altınla ödüyorsun - kaçış kapısı var ama bedava değil.
CREW_HIRE_PER_LOST                 = 6
CREW_HIRE_MAX                      = 120
WAGON_LOAD_SPEED_PENALTY           = 0.35   # Bir vagonun ne kadar dolu olduğu - bkz. `get_caravan_theoretical_speed()`, artık yalnızca bilgilendirici değil, yolun gerçek yürüyüş hızını da belirliyor (bkz. road_journey.gd'nin `_walk_at()`'i).
WAGON_MIN_SPEED_FACTOR             = 0.55
SAVE_VERSION                       = 4   # hâlâ okunuyor (bkz. load_from_dict) - `_migrate_save`de değil, orada çünkü dönüşüm vagonların senkron edilmiş olmasını gerektiriyor ve o sıra load_from_dict'in kendi akışında.
COMMISSION_WAR_SUPPLY_PROVISIONS   = 15   # kabul/teslim/süre mimarisini tekrar icat etmeden. Karşılığında ödediği kaynak (erzak/eşya/altın) ve ödülü (altın+itibar) WorldEvents.Kind başına sabit.
COMMISSION_WAR_SUPPLY_REWARD_GOLD  = 90
COMMISSION_WAR_SUPPLY_REWARD_REPUTATION = 4
COMMISSION_PLAGUE_ITEM_ID          = "test_potion"
COMMISSION_PLAGUE_ITEM_COUNT       = 3
COMMISSION_PLAGUE_REWARD_GOLD      = 110
COMMISSION_PLAGUE_REWARD_REPUTATION = 5
COMMISSION_TRADE_FAIR_COST_GOLD    = 80
COMMISSION_TRADE_FAIR_REWARD_GOLD  = 140
COMMISSION_TRADE_FAIR_REWARD_REPUTATION = 2
COMMISSION_TRIBUTE_COST_GOLD       = 50
COMMISSION_TRIBUTE_REWARD_REPUTATION = 6
```

**JourneyController - bir seferin durumu · ayar sabitleri (`scripts/travel/journey_controller.gd`)**

```
PACE_STEADY                        = 1.0
HUNGRY_PACE_MULTIPLIER             = 0.85
ENCOUNTER_TRIGGER_EPSILON          = 0.01
CAMP_PENDING                       = -1.0   # Kamp kuruldu ama herkes henüz ateşe varmadı: `camp_ends_at_hours` bu değerde bekler, sayaç herkes vardığında başlar (bkz. camp_ends_at).
CAMP_WALK_CLOCK_SCALE              = 0.05   # akışta (günde 45 sn) bu on saniyede 5 oyun saati geçirir, yirmi adımlık yol gecenin yarısını yerdi. 0.05'te on saniye on altı oyun dakikası: hayvanı bağlamak, yükü indirmek, ateşi tutuşturmak kadar.
```

**CaravanState - vagon ve kapasite · ayar sabitleri (`scripts/travel/caravan_state.gd`)**

```
MIN_WAGONS                         = 1
MAX_MORALE                         = 100
MORALE_DRAIN_PER_DAY               = 2   # değildi ve moral tabanı hiç görülmüyordu (bkz. CLAUDE.md Morale Rules). Küçük tutuluyor: bir günü tek başına belirlemesin, ama on beş gün sonunda kendini göstersin.
MORALE_DRIFT_FLOOR                 = 45   # yürümek isyanı uygun hale getirebiliyordu, yani kuralın kendisi kâğıt üstünde kalıyordu. Günlük aşınma 2'ye çıkınca bu sınır gerçek bir ihtimale dönüştü.
MERCHANT_CARGO_ITEM_TYPES          = 3   # Yabancı bir tüccarın vagonunda kaç farklı mal türü taşındığı ve her birinin miktar bandı. Küçük tutuluyor (1-3 tür, 3-14 birim) - bu bir alışveriş ekranı değil, "vagonuna baktım, şunu şunu taşıyor" hissi.
MERCHANT_CARGO_MIN_QUANTITY        = 3
MERCHANT_CARGO_MAX_QUANTITY        = 14
MAX_STAMINA                        = 100   #  Not: dayanıklılık **sefere ait**, kalıcı değil - stres o işi zaten yapıyor ve iki kalıcı yıpranma sayacı birbirini gölgelerdi.
STAMINA_PUSH_COST_PER_DAY          = 26
STAMINA_RECOVER_PER_DAY            = 9
STAMINA_CAMP_RECOVERY              = 34
STAMINA_PUSH_FLOOR                 = 12   # Bunun altında zorlanamaz. Sıfır değil: tam bitmiş bir kaynağın geri dönüşü belirsiz hissettiriyor, görünür bir eşik ise bir karar.
```

**JourneyClock - gün ve saat · ayar sabitleri (`scripts/travel/journey_clock.gd`)**

```
REAL_SECONDS_PER_DAY               = 45.0   # Bir oyun günü 1x hızda kaç gerçek saniye sürer. Sefer birkaç dakikada bitsin ama gün geçişi de hissedilsin diye seçildi.
HOURS_PER_DAY                      = 24.0
SPEEDS                             = [0.5, 1.0]   # Hızlandırma kalktı (görev Y-B09, kullanıcı kararı): yol hızlandırmak istenmeyecek kadar dolu olmalı. Ölçüm: tests/simulate_road_beats.gd (1x'te dakika başına karar/bilgi anı). Yavaşlatma ve duraklatma (Dur temposu) ka...
DEFAULT_SPEED_INDEX                = 1
START_HOUR                         = 6.0   # Sefer sabahın erken saatinde başlar - ilk gün baştan gece olmasın diye.
PHASE_BOUNDS                       = [   # Evre sınırları: [başlangıç saati, evre]. Gece gün dönümünü aştığı için (20:00-05:00) get_phase sırayla değil aralık kontrolüyle çözer.
DUSK_DARK_FROM                     = 17.0   # Gecenin koyulaştığı ve açıldığı saatler (bkz. darkness_for_hour).
DUSK_DARK_FULL                     = 21.0
DAWN_DARK_FULL                     = 4.0
DAWN_DARK_UNTIL                    = 7.0
```

**GameSession · genel API yüzeyi (sistemlerin dokunabildiği yer)**

```
spend_or_owe(amount: int) -> void
get_total_debt() -> int
repay_debt(debt_id: String, amount: int) -> int
settle_debts_in_kind(amount: int) -> int
get_credit_limit() -> int
get_available_credit() -> int
get_available_credit_after_repay(amount: int) -> int
get_loan_fee_percent() -> int
get_loan_principal(amount: int) -> int
get_advance_block_reason() -> String
get_advance_block_detail() -> String
can_take_advance(item: Item, quantity: int) -> bool
get_advance_value(item: Item, quantity: int) -> int
take_goods_advance(item: Item, quantity: int) -> bool
add_equipment(equipment_id: String, quantity: int = 1) -> void
get_equipment_count(equipment_id: String) -> int
remove_equipment(equipment_id: String, quantity: int = 1) -> bool
equip_to_character(character: CharacterData, slot: String, equipment_id: String) -> bool
can_equip(character: CharacterData, equipment_id: String) -> bool
lift_curse(character: CharacterData, slot: String) -> bool
get_unequip_block_reason(character: CharacterData, slot: String) -> String
unequip_from_character(character: CharacterData, slot: String) -> bool
get_tailor_stock() -> Dictionary
get_outfit_buy_price(piece_id: String) -> int
get_outfit_sell_price(piece_id: String) -> int
get_outfit_buy_block_reason(piece_id: String) -> String
buy_outfit(piece_id: String) -> bool
sell_outfit(piece_id: String) -> bool
add_outfit(piece_id: String, quantity: int = 1) -> void
get_outfit_count(piece_id: String) -> int
remove_outfit(piece_id: String, quantity: int = 1) -> bool
wear_outfit(character: CharacterData, piece_id: String) -> bool
take_off_outfit(character: CharacterData, slot: String) -> bool
get_outfit_choices(character: CharacterData, slot: String) -> Array[String]
combat_guarantee_applies() -> bool
journey_needs_combat() -> bool
deserters_on_this_road() -> bool
get_cargo_item_count() -> int
note_combat_triggered() -> void
note_raid_faced(event: GameEvent) -> void
note_event_seen(event_id: String) -> void
get_seen_event_count() -> int
note_decision(event_id: String, choice_key: String) -> void
note_road_place(place_id: String, place_name: String) -> void
journey_region() -> String
current_region() -> String
credit_standing() -> int
trade_standing() -> int
change_faction_standing(faction_id: String, delta: int) -> int
brotherhood_danger_factor() -> float
get_effective_danger(base_danger: float) -> float
get_convoy_speed_factor() -> float
get_convoy_danger_share() -> float
get_route_state(route: TravelRoute) -> RouteConditions.State
is_route_open(route: TravelRoute) -> bool
get_route_travel_days(route: TravelRoute) -> int
get_route_danger(route: TravelRoute) -> float
get_route_danger_breakdown(route: TravelRoute) -> Array[Dictionary]
has_route_override(from_id: String, to_id: String) -> bool
find_open_path(destination_id: String) -> Array[String]
get_caravan_name() -> String
get_days_as_leader() -> int
change_stress(delta: int) -> void
get_max_stress_character() -> CharacterData
change_character_stress(character: CharacterData, delta: int) -> void
change_party_fatigue(delta: int) -> void
change_character_fatigue(character: CharacterData, delta: int) -> void
get_most_fatigued_character() -> CharacterData
get_caravan_stamina() -> int
get_stamina_binder() -> CharacterData
can_push_pace() -> bool
apply_pace_fatigue_day(pushing: bool) -> void
accrue_night_fatigue(debt: float) -> float
apply_combat_fatigue(fighters: Array[CharacterData]) -> void
get_affliction_count() -> int
add_to_party(character: CharacterData) -> void
record_journey_camp(at: Vector2) -> void
get_lodging_cost() -> int
regard_here(role: String) -> int
can_deliver_chain(person_id: String) -> bool
get_chain_block_reason(person_id: String) -> String
get_chain_missing_text(person_id: String) -> String
deliver_chain(person_id: String) -> bool
can_afford_lodging() -> bool
get_lodging_block_reason() -> String
is_city_open_to_lodging() -> bool
lodge_night() -> Array[String]
has_feasted_today() -> bool
get_feast_cost() -> int
can_afford_feast() -> bool
has_begged_today() -> bool
is_caravan_hungry() -> bool
get_beg_block_reason(role: String) -> String
get_beg_yield() -> int
beg_in_tavern(role: String) -> int
is_tavern_banned() -> bool
has_swindled_today() -> bool
get_swindle_item() -> Item
get_mark_purse(person_id: String) -> int
get_swindle_odds() -> float
get_swindle_block_reason(role: String) -> String
swindle_in_tavern(role: String, person_id: String) -> Dictionary
get_feast_block_reason() -> String
throw_feast() -> bool
is_route_known(from_location_id: String, to_location_id: String) -> bool
learn_route(from_location_id: String, to_location_id: String) -> void
get_party_capacity() -> int
get_party() -> Array[CharacterData]
get_player_character() -> CharacterData
set_player_character(character: CharacterData) -> void
start_playthrough(player_character: CharacterData, rng: RandomNumberGenerator) -> void
inherit_father_caravan() -> void
get_father_name() -> String
can_recruit() -> bool
recruit(character: CharacterData) -> bool
get_companions_lost() -> int
dismiss(character: CharacterData, cause_key: String = DISMISSED_CAUSE_KEY) -> bool
get_shared_days(a: CharacterData, b: CharacterData) -> int
get_days_served_under_leader(candidate: CharacterData) -> int
get_join_day(character: CharacterData) -> int
resolve_combat_deaths(dead: Array[CharacterData], cause_key: String = "LEDGER_CAUSE_COMBAT", location_id: String = "") -> Dictionary
resolve_deaths(dead: Array[CharacterData], cause_key: String, location_id: String = "") -> Dictionary
appoint_heir(heir: CharacterData) -> int
is_run_over() -> bool
swap_party_positions(first_index: int, second_index: int) -> bool
assign_duty(character: CharacterData, duty_id: String) -> void
get_duty_holder(duty_id: String) -> CharacterData
can_camp_action(action: String) -> bool
set_formation(vanguard: CharacterData, middle: CharacterData, rear: CharacterData) -> void
apply_camp_actions(actions: Array) -> Array[String]
get_duty_multiplier(duty_id: String) -> float
get_duty_discount(duty_id: String) -> float
get_duty_flat_reduction(duty_id: String) -> int
get_best_effective_stat(kind: CharacterStats.Kind) -> float
get_best_stat_holder(kind: CharacterStats.Kind) -> CharacterData
get_check_roller(check: SkillCheck) -> CharacterData
get_leader_effective_stat(kind: CharacterStats.Kind) -> float
party_has_trait(trait_id: String) -> bool
get_effective_manipulation() -> float
merchant_grants_permission(merchant_name: String) -> bool
attempt_merchant_persuasion(rng: RandomNumberGenerator) -> bool
force_look_merchant_wagon(merchant_name: String) -> void
grant_merchant_look(merchant_name: String) -> void
is_merchant_known(merchant_name: String) -> bool
get_merchant_disposition_label(merchant_name: String) -> String
get_merchant_cargo_entries(merchant_name: String) -> Array
apply_event_stress(delta: int) -> void
grant_party_xp(amount: int, targets: Array[CharacterData] = []) -> Dictionary
get_break_departure_chance(character: CharacterData) -> float
resolve_stress_breaks(rng: RandomNumberGenerator) -> Array[Dictionary]
make_camp() -> Dictionary
heal_party() -> void
get_player_culture() -> Culture
get_daily_provision_multiplier() -> float
get_daily_provision_consumption() -> int
daily_provisions_for_mode(mode: String) -> int
set_meal_policy(mode: String, selected: Array[CharacterData] = []) -> void
get_meal_policy_selected() -> Array[CharacterData]
meal_needs_decision() -> bool
get_forage_yield(biome: String = "", day: int = -1) -> int
get_forage_block_reason() -> String
can_forage() -> bool
forage_a_day(biome: String = "") -> int
get_meal_mouths() -> int
get_meal_extras() -> Array[Dictionary]
is_feast_evening() -> bool
serve_meal_extras(item_ids: Array) -> Array[Dictionary]
get_remembered_combat_order() -> Array[CharacterData]
is_in_remembered_roster(character: CharacterData) -> bool
remember_combat_roster(chosen: Array[CharacterData]) -> void
get_meal_fed_party(mode: String, selected: Array[CharacterData] = []) -> Array[CharacterData]
meal_feeds_crew(mode: String) -> bool
apply_meal_distribution(mode: String, selected: Array[CharacterData] = []) -> Dictionary
get_provision_cost_multiplier() -> float
get_trait_price_multiplier() -> float
get_buy_price_multiplier() -> float
unbelieving_companion() -> CharacterData
debt_shut_out_reason(location_id: String = "") -> String
is_shut_out(location_id: String = "") -> bool
stain_trade(days: int) -> void
is_trade_stained() -> bool
get_news_chance_bonus() -> float
is_at_caravanserai() -> bool
change_reputation(delta: int) -> int
accept_contract(offer: MerchantOffer) -> void
get_contract_board(location_id: String = "") -> Array[MerchantOffer]
find_offer(merchant_id: String) -> MerchantOffer
is_contract_accepted(merchant_id: String) -> bool
get_accepted_offers_for_destination(destination_location_id: String) -> Array[MerchantOffer]
depart_with_contracts(offers: Array[MerchantOffer]) -> void
advance_day() -> Array[String]
get_next_wagon_cost() -> int
get_wagon_capacity() -> int
can_buy_wagon() -> bool
buy_wagon() -> bool
get_wagon_sale_value() -> int
get_wagon_sale_block_reason() -> String
can_sell_wagon() -> bool
sell_wagon() -> bool
get_repair_cost() -> int
repair_wagons() -> bool
get_next_dog_cost() -> int
can_adopt_dog() -> bool
adopt_dog() -> bool
get_dog_perception_bonus() -> float
get_dog_morale_bonus() -> int
get_next_donkey_cost() -> int
can_buy_donkey() -> bool
buy_donkey() -> bool
get_next_half_wagon_cost() -> int
can_buy_half_wagon() -> bool
buy_half_wagon() -> bool
get_pack_animal_provision_mouths() -> float
get_extra_cargo_capacity() -> float
get_market_stock(item_id: String) -> int
consume_stock(item_id: String, quantity: int, total_price: int = 0) -> void
record_sale(item_id: String, quantity: int, total_price: int = 0) -> void
has_plague(location_id: String) -> bool
learn_plague(location_id: String) -> void
write_journal(text: String) -> void
```

**JourneyController · genel API yüzeyi**

```
walk(effective: float, hours: float) -> void
sync_days_remaining(session: GameSession) -> void
has_arrived() -> bool
has_reached_pending(front_offset_days: float) -> bool
lay_road(origin_id: String, destination_id: String, key: String, length_days: int) -> void
terrain_day_at(leg_day: float) -> float
terrain_day() -> float
start_leg(length_days: int) -> void
start_return_leg(length_days: int) -> void
to_dict() -> Dictionary
load_from_dict(data: Dictionary, events: Array[GameEvent]) -> void
```


> **Bundan çıkarman gereken:** oyunun bugün *hangi durumu takip ettiği*. Tasarımının ham maddesi bu liste.
> §4.1'deki tarama tam olarak burada yapılacak: bu alanlardan hangisi yazılıyor da kimse okumuyor?

### VERİ-2 · OLAY SİSTEMİ VE KATALOGUN TAMAMI

Bir yol günü şöyle işliyor: `EventEngine` günlük şansı hesaplar → `RoadDirector` katalogu ağırlıklandırır (görülmemiş kartı kayırır, savaş borcunu gözetir, korunan yolda yağmayı kısar) → kart çıkar → oyuncu seçer → `SkillCheck` (varsa) → ağırlıklı `EventOutcome` → `EventEffectApplier` etkileri uygular → `EventText` metindeki `{who}` ve `{town}` yerine gerçek kişi ve yer adını koyar.

**EventEffect.Type — bir kartın dünyaya dokunabildiği her yer**

```gdscript
enum Type {
	# Kaynak
	GOLD,
	PROVISIONS,
	ITEM_ADD,
	ITEM_REMOVE,
	# Kervan
	WAGON_DAMAGE,
	WAGON_LOSE,
	# Yolda vagon onarımı (bkz. evt_traveling_tinker). Şehirdeki kervansaray
	# onarımının yol karşılığı - amount kaç vagonun onarılacağı.
	WAGON_REPAIR,
	MERCHANT_LEAVE,
	MORALE,
	STRESS,
	# Yolculuk
	TRAVEL_DAYS,
	DANGER,
	# Dünya
	REPUTATION,
	DOCUMENT_LOSE,
	SET_FLAG,
	CLEAR_FLAG,
	UNLOCK_EVENT,
	# Sistem köprüsü
	TRIGGER_HAGGLING,
	TRIGGER_COMBAT,
	TRIGGER_RECRUIT,
	# Karakter
	GRANT_TRAIT,
	GRANT_EQUIPMENT,
	# Ekonomi: süreli fiyat şoku (grev, kıtlık, ambargo, bereket).
	# amount = yüzde değişim (+40 = %40 pahalanır), text_value =
	# "location_id|item_id|gün"; item_id boşsa şehrin tamamı etkilenir.
	MARKET_SHOCK,
	# Yolun durumunu bir süreliğine değiştirir: çığ geçidi kapatır, devriye
	# eşkıyayı temizler, sel yolu çamura boğar. amount = kaç gün sürer,
	# text_value = "from_id|to_id|durum" (open/slow/perilous/closed).
	# Durum iki yöne birden işler - çığ tek yönlü düşmez.
	ROUTE_CHANGE,
	# Karşılaşılan kişinin gizli mizacını ve kültür yakınlığını yuvarlar.
	# text_value = bayrak öneki (ör. "wanderer"). Sonuçlar bu bayraklara
	# bakar; oyuncu mizacı ancak sezgisi kuvvetliyse okuyabilir.
	ROLL_ENCOUNTER,
	# Haritanın büyük, adlı bir olayını başlatır (bkz. WorldEvents) - bölgesel
	# savaş, veba, ticaret fuarı, haydut haracı. amount = kaç gün sürer,
	# text_value = "kind|hedef" ("war"/"plague"/"trade_fair"/"bandit_tribute").
	# Hedef rota-türü olaylarda her zaman "current" (ROUTE_CHANGE'in aynı
	# kısayolu - kervanın o an üstünde olduğu yol), şehir-türü olaylarda
	# "current" kervanın gittiği şehri işaret eder.
	WORLD_EVENT_START,
	# Oyuncu dışındaki en yaralı yoldaşı yolda bırakır (bkz. evt_leave_the_
	# wounded). Kervandan çıkar ama ölmez; defterde üstü çizili, sebebiyle.
	LEAVE_BEHIND,
	# Tek bir kişinin canı: amount +iyileştirir/-yaralar, text_value kimi
	# seçeceğini söyler: "weakest" (en yaralı yoldaş), bir stat adı
	# ("strength", "agility"...) = o statta en iyi olan, boş = lider. Olaylar
	# öldürmez - can en az 1'de kenetlenir (ölüm savaşın ve açlığın işi).
	PARTY_HP,
	# Ayni ödeme: kervanın bir borcundan `amount` altın düşer - yük, vagon ya
	# da hizmetle ödenen borç (bkz. evt_bailiffs_at_camp). Eksi bir GOLD
	# etkisi borcu azaltmaz, spend_or_owe üzerinden *artırır*; borcu kapatan
	# başka bir etki yoktu. Hiçbir zaman altın üretmez.
	DEBT_SETTLE,
	# Kıyafet ganimeti (görev Y-C03): text_value = parça kimliği, amount = adet;
	# GRANT_EQUIPMENT gibi önce dolaba düşer, kime giydirileceği sonra seçilir.
	GRANT_OUTFIT,
	# Uzun zincir (görev Y-E02): text_value = "zincir|aşama|nerede", amount =
	# en az kaç gün sonra. nerede: "other_city" (başladığı şehirden başka bir
	# şehre giden yolda), "city:<id>" (o şehre giden yolda), "heir" (sonraki
	# kuşakta), boş = her yerde. Karşılık kartı `chain_<id>_ripe`'a bakar.
	CHAIN_ADVANCE,
	# Kapısından bir daha girilemeyen yer (Y-C29). text_value = yer kimliği;
	# boşsa seferin hedefi.
	BAN_LOCATION,
	# Ticaret lekesi (Y-C26): `amount` gün boyunca pazarlar kervana pahalı
	# satar, ucuza alır - adın kötüye çıktı.
	TRADE_STAIN,
	# Şehrin hâli (Y-C21): `amount` kadar; seferdeyse varılacak şehrin, değilse bulunulanın.
	CITY_MORALE,
	# Avuçiçi'nde inançsızın eli kesilir (lore defter III, Ç14): kervanın El'e
	# inanmayan bir yoldaşı kalıcı olarak tek elli kalır. Olaylar öldürmez.
	CUT_HAND,
	# Hizip itibarı (Y-C12, T16-07): text_value hizip (Standing.GUILD/CHURCH/
	# BROTHERHOOD), amount değişim.
	FACTION,
	# Yolun reisi (N32, T16-09): text_value "paid" - kartta olan reise boyun
	# eğildi, çetesi büyür (People.chief_paid).
	CHIEF_MEMORY,
	# Pusu savaşı (kullanıcı kararı 2026-11-07): TRIGGER_COMBAT'ın aynısı, tek
	# farkı savaşın "pusuya düşülmüş" başlaması - ilk round'da düşman önce
	# oynar (bkz. CombatEncounter.ambushed). Blöfü tutmayan kervanın bedeli.
	# Ayrı bir tür, çünkü `text_value` kadro türünü taşıyor ve oraya ikinci
	# bir anlam sıkıştırmak ("bandit|ambush") kataloğu okunmaz yapardı.
	TRIGGER_AMBUSH,
	# Yük yağması (kullanıcı kararı 2026-11-07): yol kesenin para değil
	# **mal** istemesi. amount = yüzde pay (100 = hepsi), text_value "all"
	# ise bırakılan tek mal da bırakılmaz (bkz. GameSession.plunder_cargo).
	# Erzağa dokunmaz - kervanı yolda öldürmek yağmacının da işine gelmez.
	CARGO_PLUNDER,
	# Blöfün bedeli (kullanıcı kararı 2026-11-07): "elindeki bir malı bu çok
	# değerli diye onları kandırıp sadece o malı vererek diğer eşyalarını ve
	# canını kurtarabilir". Yükün **en ucuz** kalemini bir adet verir -
	# oyuncu neyi vereceğini seçmez, blöfün tuttuğu şey zaten en ucuzunun
	# değerli görünmesidir.
	CARGO_DECOY,
}
```

**RoadDirector - kart çekilişinin ağırlıkları (`scripts/events/road_director.gd`)**

```
QUIET_RAMP                         = 0.5
MAX_QUIET_BOOST                    = 2.0
RELIEF_HEAVY_WEIGHT                = 0.35
RELIEF_CHANCE                      = 0.8
STRAIN_HEAVY_WEIGHT                = 0.7
STRAIN_LIGHT_WEIGHT                = 1.2
STRAIN_STRESS                      = 60.0
SCARCITY_QUIET_FROM                = 0.45   #  Rampa sıfırlanmıyor, *kısılıyor*: kıtlık en ağır günde bile yol büsbütün susmaz, yalnız üç gün üst üste susabilir hâle gelir.
SCARCITY_QUIET_RAMP                = 0.16
SCARCITY_MAX_QUIET_BOOST           = 1.3
COMBAT_DUE_FROM_DAYS               = 3.0   #  Ötekiler sıfırlanmıyor, kısılıyor: koşulu sağlayan tek kart dövüşsüz olabilir ve o zaman yolun susması, kartın gelmemesinden iyidir.
COMBAT_DUE_WEIGHT                  = 3.5
COMBAT_DUE_OTHER_WEIGHT            = 0.2
GUARDED_ROAD_WEIGHT                = 0.3   # başına o yolları %77 oranında yine haydutlu bırakıyordu, yani "aşırı korunan yer" ekranda hissedilmiyordu. Sıfır değil: muhafız da her yeri tutamaz, kutsal yolda bir soygun hikâye olur.
UNSEEN_CARD_WEIGHT                 = 2.4   # Domino bunun üstünde kalır (DOMINO_WEIGHT 2,5 > RECENT_CARD_WEIGHT'in bastırması): bir zincirin ikinci halkası yeni görülmüş olsa bile gelir, çünkü zincirin kopması tekrardan daha kötüdür.
RECENT_CARD_WEIGHT                 = 0.35
SEEN_CARD_WEIGHT                   = 0.8
DOMINO_WEIGHT                      = 2.5   # Zincirin halkası -> sonraki halkayı getiren kartlar.
DOMINO_NEXT                        = {
```

**EventEngine - günlük çekiliş (`scripts/events/event_engine.gd`)**

```
DEFAULT_DAILY_EVENT_CHANCE         = 0.35
MAX_DAILY_EVENT_CHANCE             = 0.95
```

**SkillCheck - beceri kontrolü (`scripts/events/skill_check.gd`)**

```
CHANCE_PER_EFFECTIVE_POINT         = 6.0   # Her etkin puan şansı bu kadar değiştirir. 6 seçildi: statı 10'a (effective +5) çıkarmış biri tabana göre %30 daha güçlü şansla girer - hissedilir ama tek başına hiçbir check'i garantiye almaz.
MIN_CHANCE                         = 5
MAX_CHANCE                         = 95
CRITICAL_BAND                      = 15   # Şansın en güvenli (düşük zar gerektiren) %15'i "tam başarı" sayılır - kıl payı geçmekle konuyu gerçekten hakkıyla çözmek arasındaki BG3/DOS2 tarzı ayrım.
```

**Katalogun tamamı: 101 yol kartı**

```
id                         başlık                             ağr seçenekler (kontrol | etkiler)
evt_bandit_ambush          Haydut Pususu                      3.2 Fidyeyi öde{FACTION+GOLD+MORALE} / Direnç göster{FACTION+TRIGGER_COMBAT} / Pazarlığa otur{TRIGGER_HAGGLING}
evt_customs_checkpoint     Gümrük Kontrolü                    1.2 Evrakları göster{ITEM_REMOVE+REPUTATION+TRAVEL_DAYS} / Mühürsüz tuzu balyaların altına sakla [INTELLECT zor0 PARTY_BEST]{GOLD+ITEM_REMOVE+REPUTATION+TRAVEL_DAYS} / Rüşvet ver (80 GG){GOLD+REPUTATION} / Bariyeri zorla geç [AGILITY zor0 LEADER]{DANGER+DOCUMENT_LOSE+GOLD+ITEM_REMOVE+MORALE+REPUTATION}
evt_broken_axle            Kırılan Aks                        1.0 Düzgün tamir ettir (60 GG, 1 gün){GOLD+TRAVEL_DAYS} / Böyle devam et{MORALE+WAGON_DAMAGE} / Yükü hafiflet{ITEM_REMOVE+MORALE}  <koşul:wagons 0 2>
evt_storm                  Fırtına                            1.1 Sığınak ara ve bekle{PROVISIONS+TRAVEL_DAYS} / Fırtınaya rağmen ilerle [ENDURANCE zor0 PARTY_BEST]{MORALE+PARTY_HP+PROVISIONS+STRESS+WAGON_DAMAGE+WAGON_LOSE}
evt_spoiled_provisions     Bozulan Erzak                      0.9 Levazımcı çuvalları erkenden yokladı{MORALE+PROVISIONS+STRESS} / Otacı bozulanı yahniye çevirsin{MORALE+PROVISIONS+STRESS} / Kalanı herkese eşit paylaştır{MORALE+PROVISIONS} / Tüccarların payını kes{MORALE+PROVISIONS+REPUTATION}  <koşul:provisions 0 5>
evt_stowaway               Kaçak Yolcu                        0.7 Kervanda kalmasına izin ver{GOLD+MORALE+PROVISIONS+SET_FLAG+UNLOCK_EVENT} / İlk karakolda teslim et{GOLD+MORALE+REPUTATION+SET_FLAG+UNLOCK_EVENT}  <tek>
evt_stowaway_repay         Bir Borcun Karşılığı               3.0 Keseyi kabul et (200 GG){GOLD+MORALE} / Parayı reddet{MORALE+REPUTATION}  <tek,zincir,koşul:stowaway_helped 4 0>
evt_sick_merchant          Hasta Tüccar                       0.9 Hekim çağır (90 GG, 1 gün){GOLD+MORALE+REPUTATION+TRAVEL_DAYS} / Bir kervansarayda bırak{MERCHANT_LEAVE+MORALE+REPUTATION} / Kendi otacın baksın (zarlı, Bilgelik) [WISDOM zor0 PARTY_BEST]{ITEM_REMOVE+MERCHANT_LEAVE+MORALE+REPUTATION+STRESS+TRAVEL_DAYS}  <koşul:merchants 0 1>
evt_mutiny                 Kervanda Huzursuzluk               2.0 Fazladan pay dağıt (100 GG){GOLD+MORALE} / Söz ver, oyala{MORALE+REPUTATION+STRESS} / Otoriteni göster [CHARISMA zor0 LEADER]{MERCHANT_LEAVE+MORALE+REPUTATION}  <koşul:morale 1 40;merchants 0 1>
evt_abandoned_wagon        Terk Edilmiş Vagon                 0.8 Yükü al [FAITH zor0 PARTY_BEST]{DANGER+GRANT_OUTFIT+ITEM_ADD+MORALE+REPUTATION+STRESS} / Dokunma, yoluna devam et{MORALE} / Sahibini ara{MORALE+REPUTATION+TRAVEL_DAYS}
evt_road_wanderer          Yol Kenarındaki Yolcu              0.9 Konuş, partine katmayı düşün{TRIGGER_RECRUIT} / Erzak ver, yoluna gönder{MORALE+PROVISIONS+REPUTATION} / Görmezden gel{MORALE+SET_FLAG+UNLOCK_EVENT}
evt_wanderer_revenge       Tanıdık Bir Yüz                    3.0 Hesabı burada kapat{CLEAR_FLAG+TRIGGER_COMBAT} / İstediğini ver, geç git{CLEAR_FLAG+GOLD+MORALE}  <tek,zincir,koşul:wanderer_scorned 4 0>
evt_troubled_night         Sıkıntılı Gece                     0.8 Nöbet tut, uyumaya kalkma{MORALE+PROVISIONS+STRESS} / Uyumaya çalış [FAITH zor0 LEADER]{GRANT_TRAIT+MORALE+PARTY_HP+STRESS}
evt_stress_brawl           Kamp Kavgası                       1.3 Araya gir, ayır [STRENGTH zor0 LEADER]{MORALE+PARTY_HP+STRESS} / Kendi hallerine bırak{GOLD+MORALE+STRESS+WAGON_DAMAGE}  <koşul:stress 0 40>
evt_forgotten_cache        Gömülü Stok                        0.7 Kaz, bak neymiş [PERCEPTION zor0 PARTY_BEST]{GRANT_EQUIPMENT+GRANT_OUTFIT+GRANT_TRAIT+MORALE+PROVISIONS+STRESS} / Otacı toprağı okusun{GRANT_EQUIPMENT+MORALE} / Dokunma, tuhaf bir his var{MORALE}
evt_traveling_tinker       Gezgin Demirci                     0.7 Bir silah satın al (120 GG){GOLD+GRANT_EQUIPMENT} / Hasarlı vagonu onart (60 GG){GOLD+MORALE+WAGON_REPAIR} / Yedek parça al (35 GG){GOLD+MORALE+SET_FLAG} / Damgasız kılıcı al (40 GG, zarlı, Zeka) [INTELLECT zor0 PARTY_BEST]{GOLD+GRANT_EQUIPMENT+MORALE} / İlgilenmiyorsun{MORALE}
evt_scouted_pass           Bilinmeyen Bir Kestirme            0.9 İzci'nin bildiği kestirmeden git{DANGER+TRAVEL_DAYS} / İzci olmadan patikaya sap (zarlı, Sezgi) [PERCEPTION zor0 LEADER]{DANGER+MORALE+TRAVEL_DAYS+WAGON_DAMAGE} / Ana yolda kal{MORALE}  <koşul:days_remaining 0 2>
evt_landslide              Heyelan                            0.7 Enkazın kenarından sıyrılıp geç [STRENGTH zor0 PARTY_BEST]{MORALE+ROUTE_CHANGE+STRESS+TRAVEL_DAYS+WAGON_DAMAGE+WAGON_LOSE} / Tayfayı indir, yolu bir nebze aç{MORALE+REPUTATION+ROUTE_CHANGE+TRAVEL_DAYS}
evt_road_patrol            Yol Devriyesi                      0.6 Devriyeye katıl, yolu temizlemelerine yardım et{DANGER+REPUTATION+ROUTE_CHANGE+TRAVEL_DAYS} / Kılıcını çek, haydutları birlikte temizleyin{TRIGGER_COMBAT} / Selam ver, kendi hızında devam et{MORALE}  <koşul:danger 0 0.25>
evt_kin_encounter          Yolda Bir Oba                      0.8 Erzak için pazarlık et{GOLD+MORALE+PROVISIONS} / Selam ver, ateşlerine otur{GRANT_EQUIPMENT+MORALE+PROVISIONS+REPUTATION+STRESS}
evt_culture_valley_dispute Muhasebe Anlaşmazlığı              0.8 Defterleri iste, hakemlik yap [INTELLECT zor0 PARTY_BEST]{GOLD+MORALE+REPUTATION} / Kendi aralarında halletsinler{MORALE}  <koşul:is_valley_culture 0 1;merchants 0 1>
evt_culture_highland_challenge Güç Sınavı                         0.2 Meydan oku, kabul et [STRENGTH zor0 LEADER]{MORALE+PARTY_HP+REPUTATION+STRESS} / Reddet, vaktin yok{MORALE}  <koşul:is_highland_culture 0 1>
evt_culture_port_gossip    Rıhtım Dedikodusu                  0.8 Dinle, sonra bu haberi başkasına sat [WISDOM zor0 PARTY_BEST]{GOLD+GRANT_EQUIPMENT+ITEM_ADD+MARKET_SHOCK+MORALE+REPUTATION+STRESS} / Vaktin yok, geç{MORALE}  <koşul:is_port_culture 0 1>
evt_culture_fisher_catch   Şanslı Ağ                          0.8 Ağı at, avlanmaya vakit ayır{MORALE+PROVISIONS+STRESS} / Nehrin derin kolunda ağ at (zarlı, Dayanıklılık) [ENDURANCE zor0 PARTY_BEST]{GRANT_EQUIPMENT+MORALE+PARTY_HP+PROVISIONS+TRAVEL_DAYS} / Vakit kaybetme, devam et{MORALE}  <koşul:is_fisher_culture 0 1>
evt_roadside_shrine        Yol Kenarı Türbesi                 0.1 Dur, dua et{GRANT_EQUIPMENT+MORALE+STRESS} / Adakları al [FAITH zor0 LEADER]{GOLD+REPUTATION+STRESS+TRADE_STAIN}
evt_pilgrim_encounter      Yolun Hacısı                       0.7 Yanına al, birkaç gün eşlik et{PROVISIONS+SET_FLAG+UNLOCK_EVENT} / Yol tarif et, kendi hâline bırak [WISDOM zor0 LEADER]{MORALE+SET_FLAG+UNLOCK_EVENT} / Görmezden gel, yoluna devam et{MORALE}
evt_pilgrim_blessing       Hacının Vedası                     3.0 Kutsamayı kabul et{CLEAR_FLAG+MORALE+STRESS}  <tek,zincir,koşul:pilgrim_escorted 4 0>
evt_wild_animal            Yol Kesen Vahşi                    2.2 Kovala, gerekirse dövüş{TRIGGER_COMBAT} / Biraz erzak bırak, sakince uzaklaş{MORALE+PROVISIONS} / Aceleyle etrafından dolaş [AGILITY zor0 LEADER]{DANGER+MORALE+STRESS}
evt_guard_patrol           Muhafız Devriyesi                  0.9 Rüşvet ver, sessizce geç (100 GG){GOLD+REPUTATION} / Aralarından zorla geç [AGILITY zor0 LEADER]{DANGER+DOCUMENT_LOSE+GOLD+REPUTATION} / Direniş göster{TRIGGER_COMBAT}  <koşul:reputation 1 10>
evt_route_diversion        Bozulan Anlaşmalar                 0.0 Zararını öde (60 GG){GOLD} / Umursama, yoluna git{MORALE}  <zincir>
evt_forage                 Yol Kenarı                         1.1 Topla (bir gün kaybedersin){PROVISIONS+TRAVEL_DAYS} / Ormanın derinine dal (zarlı, Sezgi) [PERCEPTION zor0 PARTY_BEST]{GRANT_EQUIPMENT+MORALE+PARTY_HP+PROVISIONS+TRAVEL_DAYS} / Durma, yürümeye devam et{MORALE}
evt_village_provisions     Mezranın ambarı                    0.2 Biraz al (30 altın, 6 erzak){GOLD+PROVISIONS} / Bolca al (70 altın, 15 erzak){GOLD+PROVISIONS} / Bolca al, ama pazarlık et [CHARISMA zor0 PARTY_BEST]{GOLD+MORALE+PROVISIONS+REPUTATION+TRADE_STAIN} / Geç{STRESS}
evt_merchant_night_flight  Gecenin kaçağı                     0.7 Peşine düş [PERCEPTION zor0 PARTY_BEST]{GOLD+MERCHANT_LEAVE+MORALE+PROVISIONS+STRESS} / Bırak gitsin{MERCHANT_LEAVE+PROVISIONS}  <koşul:merchant_thief 0 1>
evt_merchant_cold_feet     Korkan tüccar                      0.8 Onu ikna et [CHARISMA zor0 LEADER]{MERCHANT_LEAVE+MORALE} / Cesaretine para ver (30 altın){GOLD} / Bırak dönsün{MERCHANT_LEAVE}  <koşul:merchant_desperate 0 1;danger 0 0.4>
evt_merchant_grudge        Eski hesap                         0.6 Arabacının yanında dur{MORALE+REPUTATION} / Tüccarın hakkını ver{STRESS} / İkisini de dinle, hüküm ver [WISDOM zor0 LEADER]{MERCHANT_LEAVE+REPUTATION+STRESS}  <koşul:merchant_vengeful 0 1>
evt_merchant_shares_bread  Sadık tüccarın ekmeği              0.9 Teşekkür et, kabul et{MORALE+PROVISIONS} / Teşekkür et, geri çevir{MORALE+REPUTATION}  <koşul:merchant_loyal 0 1;provisions 1 12>
evt_river_ford             Irmak geçidi                       0.2 Geç (sular alçak ya da orta) [ENDURANCE zor0 PARTY_BEST]{MORALE+PARTY_HP+PROVISIONS+WAGON_DAMAGE} / Sel suyuna rağmen geç [ENDURANCE zor0 PARTY_BEST]{PARTY_HP+PROVISIONS+STRESS+WAGON_DAMAGE} / Yükü hafiflet, öyle geç (biraz erzak kıyıda kalır){PROVISIONS} / Suların çekilmesini bekle (bir gün){MORALE+TRAVEL_DAYS}  <koşul:near_ford 0 1>
evt_broken_outburst        Taşan bardak                       0.9 Yanına git, sakinleştir [CHARISMA zor0 LEADER]{MORALE+PARTY_HP+STRESS} / Bırak boşalsın{MORALE+STRESS} / Ertesi gün kervanın ucunda yalnız yürüsün{MORALE+STRESS}  <koşul:broken_count 0 1>
evt_rogue_mage             Yolu kesen büyücü                  0.1 Kılıçları çek{TRIGGER_COMBAT} / Bedeli öde (90 altın){GOLD+STRESS} / Arabaları çevir, kaç [AGILITY zor0 LEADER]{TRAVEL_DAYS+TRIGGER_COMBAT+WAGON_DAMAGE}  <tek,koşul:danger 0 0.35>
evt_convoy_repaid          Konvoyun borcu                     3.0 Dinle, teşekkür et{DANGER+MORALE}  <tek,zincir>
evt_convoy_search          Kayıp sandık                       3.0 Sandığın izini yok et [INTELLECT zor0 PARTY_BEST]{GOLD+REPUTATION+STRESS+TRADE_STAIN} / İtiraf et, sandığı ver{GOLD+REPUTATION} / Aramaya izin verme{REPUTATION+TRIGGER_COMBAT}  <tek,zincir>
evt_refugee_gratitude      Doyurduğunuz kafile                3.0 Kervana al{TRIGGER_RECRUIT} / Teşekkür et, yolunu ayır{MORALE+PROVISIONS}  <tek,zincir>
evt_rival_slander          Rakibin dili                       3.0 Herkesin önünde cevap ver [CHARISMA zor0 PARTY_BEST]{REPUTATION+TRADE_STAIN} / Duymazdan gel{REPUTATION}  <tek,zincir>
evt_party_theft            Eksilen Eşya                       1.0 Araştır - kim aldığını bul{MORALE+SET_FLAG+UNLOCK_EVENT} / Boş ver, kervan devam etsin{MORALE}
evt_party_investigation    Suçlama                            2.0 Açıkça suçla [PERCEPTION zor0 PARTY_BEST]{CLEAR_FLAG+MORALE+REPUTATION+STRESS} / Soruşturmayı bırak{CLEAR_FLAG+MORALE}  <zincir,koşul:theft_pending 4 0>
evt_military_convoy        Askeri Konvoy                      0.7 Kenara çek, geçmelerini bekle{MORALE} / Eskort teklif et (Muhafız gerekir){GOLD+REPUTATION+UNLOCK_EVENT} / Artçıdan düşen sandığı al (zarlı, Çeviklik) [AGILITY zor0 PARTY_BEST]{GOLD+REPUTATION+TRADE_STAIN+TRIGGER_COMBAT+UNLOCK_EVENT}
evt_refugee_column         Mülteci Kolonu                     0.7 Erzak paylaş (-6 erzak){MORALE+PROVISIONS+REPUTATION+UNLOCK_EVENT} / Taşıyabildiklerini ucuza al (30 GG, zarlı, Sezgi) [PERCEPTION zor0 PARTY_BEST]{GOLD+ITEM_ADD+MORALE+REPUTATION+TRADE_STAIN} / Görmezden gel, geçip git{MORALE}
evt_merchant_caravan       Karşıdan Gelen Kervan              0.7 Teklifi kabul et, alışveriş yap [CHARISMA zor0 PARTY_BEST]{GOLD+UNLOCK_EVENT} / Yolu sor (10 altın){DANGER+GOLD} / Elini salla, geç git{MORALE}
evt_regional_war_news      Bölgesel Savaş Haberi              0.3 Kadroyu uyar, tetikte olun{MORALE+STRESS} / Haberi ciddiye alma{MORALE+STRESS}  <koşul:route_has_regional_war 1 0>
evt_plague_outbreak_news   İllet Haberi                       0.3 Endişelen, kadro tedirgin olur{STRESS} / Haberi ciddiye alma{MORALE}  <koşul:destination_has_plague 1 0>
evt_trade_fair_news        Ticaret Fuarı Haberi               0.3 Kadroya müjdele, adımlar hızlansın{MORALE+PROVISIONS} / Haberi ciddiye alma{MORALE}  <koşul:destination_has_trade_fair 1 0>
evt_bandit_tribute_zone_news Haydut Haracı Haberi               0.3 Kadroyu uyar, tetikte olun{MORALE+STRESS} / Haberi ciddiye alma{MORALE+STRESS}  <koşul:route_has_bandit_tribute 1 0>
evt_avucici_hand           El'in Kapısı                       1.2 Ona Kitap'ı as, duayı fısılda; inançlı gibi geçsin [CHARISMA zor0 PARTY_BEST]{CUT_HAND+GOLD+MORALE+STRESS} / Onu kapı dışında bırak, dönüşte alırsın{MORALE+STRESS+TRAVEL_DAYS} / Geri dön; bu kapıdan girmeyeceğiz{MORALE+PROVISIONS+REPUTATION}  <koşul:avucici_unbeliever 0 1>
evt_chief_returns          {nemesis} yolu tutmuş              2.4 Yüzleş{FACTION+TRIGGER_COMBAT} / Haracını ver (90 GG){CHIEF_MEMORY+FACTION+GOLD+MORALE} / Geri çekil, yolu dolaş (bir gün){STRESS+TRAVEL_DAYS}  <koşul:chief_here 0 1>
evt_place_village          {place}                            0.0 Erzak al (20 GG, 6 erzak){GOLD+PROVISIONS} / Oturup yolu sor{DANGER+STRESS} / Durma, geç git{MORALE}  <koşul:place_here 0 1>
evt_place_shrine           {place}                            0.0 Dinlen, sessizce otur{STRESS} / Adak bırak (10 GG){FACTION+GOLD+MORALE} / Durma, geç git{MORALE}  <koşul:place_here 0 1>
evt_place_ruin             {place}                            0.0 Yıkıntıyı kurcala{GOLD+PARTY_HP+STRESS} / Yükseğe çık, yolu gözle{DANGER} / Durma, geç git{MORALE}  <koşul:place_here 0 1>
evt_place_mine             {place}                            0.0 Demir al (30 GG, 3 demir){GOLD+ITEM_ADD} / Durma, geç git{MORALE}  <koşul:place_here 0 1>
evt_bandit_tribute_toll    Haraç Tahsildarları                1.6 Haracı öde (140 GG){FACTION+GOLD} / Haracı erzakla öde (35 erzak){FACTION+MORALE+PROVISIONS} / Direniş göster{FACTION+TRIGGER_COMBAT}  <koşul:route_has_bandit_tribute 0 1>
evt_road_warden            Mühürlü Bekçi                      0.1 Öde (40 GG){GOLD} / Erzakla öde (6 erzak){MORALE+PROVISIONS} / Muafiyet kâğıdın olduğunu söyle [CHARISMA zor0 LEADER]{GOLD+MORALE+REPUTATION+TRADE_STAIN} / Loncaya şikâyet edeceğini söyle [INTELLECT zor0 LEADER]{GOLD+REPUTATION+SET_FLAG+TRIGGER_COMBAT}  <koşul:route_has_bandit_tribute 6 1>
evt_taken_captive          Gece Götürülen                     0.2 Peşlerine düş [PERCEPTION zor0 PARTY_BEST]{CHAIN_ADVANCE+PARTY_HP+STRESS+TRAVEL_DAYS} / Fidye haberi bırak (100 GG){GOLD+STRESS} / Yola devam et{LEAVE_BEHIND+MORALE+STRESS}  <koşul:party_size 0 3;danger 0 0.3>
evt_captive_strangers      Esirlikten İki Yüz                 6.0 Birini kervana al{CHAIN_ADVANCE+TRIGGER_RECRUIT} / Önce sorgula, sonra birini al [PERCEPTION zor0 PARTY_BEST]{CHAIN_ADVANCE+STRESS+TRIGGER_RECRUIT} / Doyurup yolla (3 erzak){CHAIN_ADVANCE+MORALE+PROVISIONS} / Geri çevir{CHAIN_ADVANCE+STRESS}  <koşul:chain_captive_ripe 0 1>
evt_wandering_players      Gezgin Oyuncular                   0.3 Sofrayı paylaş (4 erzak){MORALE+PROVISIONS+STRESS} / Gördükleri yolları sor [CHARISMA zor0 PARTY_BEST]{DANGER+MORALE} / Tüccarlar için oynasınlar, haracı sen topla (+15 GG){GOLD+MERCHANT_LEAVE+REPUTATION} / Gönder{MORALE}
evt_penitent_procession    Yalınayak Alay                     0.2 Ekmek ver (6 erzak){PROVISIONS+REPUTATION+STRESS} / Reddet{STRESS} / Kıtlık fiyatından sat (6 erzak, +30 GG){GOLD+PROVISIONS+REPUTATION+SET_FLAG} / Duaya katıl [FAITH zor0 PARTY_BEST]{STRESS+TRAVEL_DAYS}
evt_hidden_guide           Kısa Yolu Bilen                    0.2 Peşine takıl (4 erzak){GOLD+PROVISIONS+TRAVEL_DAYS+TRIGGER_COMBAT} / Önce sına [PERCEPTION zor0 PARTY_BEST]{MORALE+PROVISIONS+STRESS+TRAVEL_DAYS} / Reddet{STRESS}  <koşul:days_remaining 0 2>
evt_untouched_village      İlletin Uğramadığı Köy             0.3 Kapının dışından alışveriş (30 GG, +6 erzak){GOLD+PROVISIONS} / Hastanı içeri almalarını iste [CHARISMA zor0 LEADER]{PARTY_HP+PROVISIONS+REPUTATION} / Kapıyı zorla [STRENGTH zor0 PARTY_BEST]{PROVISIONS+REPUTATION+TRADE_STAIN+TRIGGER_COMBAT} / Uzaktan geç{STRESS}  <koşul:plague_here 0 1>
evt_serai_open             Açık Kervansaray                   2.0 Gerçek yatak (20 GG){GOLD+MORALE+STRESS} / Avluda yat{STRESS} / Yolcuları dinle [PERCEPTION zor0 PARTY_BEST]{DANGER+STRESS} / Ahırdan saman ve arpa al{PROVISIONS+REPUTATION}  <koşul:serai_open 0 1>
evt_serai_ruin             Harabe Kervansaray                 2.0 İçeride geceyi geçir{MORALE+STRESS} / Harabeyi ara [PERCEPTION zor0 PARTY_BEST]{GOLD+ITEM_ADD+PARTY_HP} / Devam et{STRESS}  <koşul:serai_ruin 0 1>
evt_serai_bandit           Haydut Elindeki Kervansaray        2.0 Öde (240 GG){GOLD} / Erzakla öde (35 erzak){PROVISIONS} / Dolaş (+1 gün){TRAVEL_DAYS} / Yolcu gibi pazarlık et [CHARISMA zor0 LEADER]{GOLD+TRIGGER_COMBAT} / Kervansarayı geri al (savaş){DANGER+TRIGGER_COMBAT}  <koşul:serai_bandit 0 1>
evt_duvenmor_quarrel       Duvenmor'dan Önceki Gece           1.5 Yut{STRESS} / Surların dışında, şafakta hesaplaş [STRENGTH zor0 LEADER]{MORALE+PARTY_HP+REPUTATION} / İçeride kılıcını çek (Duvenmor'a bir daha giremezsin){BAN_LOCATION+MORALE+REPUTATION}  <koşul:dest_neutral_ground 0 1;days_remaining 1 1>
evt_pilgrim_caravan        Avuçiçi Kafilesi                   1.2 Kafileye katıl (yavaş ama güvenli, kurallı){DANGER+MORALE+STRESS+TRAVEL_DAYS} / Septisist gibi davran ve katıl [CHARISMA zor0 LEADER]{DANGER+GOLD+MORALE+PARTY_HP+REPUTATION+STRESS+TRAVEL_DAYS} / Kendi yolunuza devam edin{STRESS}  <koşul:dest_holy 0 1;days_remaining 0 2>
evt_faith_tribunal         Sapkınlık Suçlaması                0.2 Onu savun [CHARISMA zor0 LEADER]{MORALE+PARTY_HP+REPUTATION+STRESS+TRADE_STAIN} / Kiliseye bağış yap (60 GG){GOLD+STRESS} / Teslim et{LEAVE_BEHIND+MORALE+REPUTATION}  <koşul:party_size 0 2>
evt_elder_burden           Yükü Ağır Olan                     0.3 Köyde bırak{LEAVE_BEHIND+MORALE} / Taşı (bir gün, 4 erzak){PROVISIONS+TRAVEL_DAYS} / Kendi tayınını ver (kervanbaşı zayıflar){PARTY_HP+STRESS} / Otacı baksın, yürüyebilsin [WISDOM zor0 PARTY_BEST]{PARTY_HP+STRESS+TRAVEL_DAYS}  <koşul:party_size 0 3;scarcity_here 0 0.4;weakest_companion_hp_ratio 1 0.6>
evt_fever_quarantine       Ateşli                             0.3 Ayrı ateşte yatsın{MORALE+PARTY_HP} / Kimse ayrılmaz [ENDURANCE zor0 PARTY_BEST]{PARTY_HP+STRESS} / Köydeki şifacıya bırak (20 GG){GOLD+LEAVE_BEHIND}  <koşul:party_size 0 3;plague_here 0 1>
evt_wagon_for_town         Aç Kapı                            0.5 Bir vagonu ver{CITY_MORALE+REPUTATION+WAGON_LOSE} / Bir vagonu kıtlık fiyatından sat (+70 GG){CITY_MORALE+GOLD+REPUTATION+WAGON_LOSE} / Reddet{CITY_MORALE+STRESS} / Pazarlık et: vagon değil, yarım yük [CHARISMA zor0 LEADER]{CITY_MORALE+PROVISIONS+REPUTATION+WAGON_LOSE}  <koşul:city_morale 6 30;wagons 0 2;days_remaining 1 2>
evt_starving_roadside      Yol Kenarındakiler                 0.3 Erzaktan ver (6 erzak){MORALE+PROVISIONS} / Durmadan geç{MORALE+STRESS} / Onlarla birlikte avlan [PERCEPTION zor0 PARTY_BEST]{MORALE+PROVISIONS+STRESS+TRAVEL_DAYS} / En güçlüsünü kervana al (bir ağız daha){PROVISIONS+TRIGGER_RECRUIT}  <koşul:scarcity_here 0 0.5>
evt_hunger_riot            Kapıda Kalabalık                   1.5 Erzaktan dağıt (10 erzak){CITY_MORALE+PROVISIONS+REPUTATION} / Kalabalığı yarıp geç (savaş){CITY_MORALE+REPUTATION+TRIGGER_COMBAT} / Dışarıda bir gün bekle{STRESS+TRAVEL_DAYS} / Kalabalıkla konuş [CHARISMA zor0 LEADER]{CITY_MORALE+REPUTATION+TRIGGER_COMBAT}  <koşul:city_morale 6 20;days_remaining 1 1>
evt_cargo_seized           Ünün Bedeli                        1.2 Yükten ver (12 erzak){CITY_MORALE+PROVISIONS+REPUTATION} / Kethüdaya kese ver (60 GG){GOLD} / Reddet [CHARISMA zor0 LEADER]{CITY_MORALE+PROVISIONS+REPUTATION+TRADE_STAIN+TRIGGER_COMBAT}  <koşul:reputation 0 40;city_morale 6 35;days_remaining 1 1>
evt_faction_split          İki Ateş                           0.6 Eskilerin ateşine otur{MORALE+STRESS} / Yenilerin ateşine otur{MORALE+STRESS} / İki ateşi bir et [CHARISMA zor0 LEADER]{LEAVE_BEHIND+MORALE+PROVISIONS+STRESS}  <koşul:party_size 0 6>
evt_leave_the_wounded      Köyün Kapısında                    0.3 Köylülere bırak{LEAVE_BEHIND+PROVISIONS+SET_FLAG+STRESS+UNLOCK_EVENT} / Taşıyın, kimseyi bırakmıyoruz{MORALE+TRAVEL_DAYS} / Köyün şifacısına 60 GG öde{GOLD+PARTY_HP}  <koşul:weakest_companion_hp_ratio 1 0.35;party_size 0 2>
evt_left_behind_return     Köyden Haber                       3.0 Ne olduğunu sor{CLEAR_FLAG+MORALE+PROVISIONS+STRESS}  <zincir,koşul:companion_left_behind 4 0>
evt_profiteer_recognized   Tanıyan Gözler                     1.2 Farkı geri öde (80 GG){GOLD+REPUTATION+SET_FLAG+STRESS} / Bakmadan geç{REPUTATION+SET_FLAG+STRESS}  <koşul:profiteering_sales 0 3;profiteer_reckoned 5 0>
evt_frontier_outpost       Sınır Karakolu                     0.2 Yazıyla, fermanla tartış [INTELLECT zor0 PARTY_BEST]{GOLD+REPUTATION} / Harcı öde (25 GG){GOLD} / En dayanıklınız garnizonla nöbet tutsun{DANGER+PARTY_HP+REPUTATION}
evt_mine_collapse          Göçük                              0.2 En dayanıklınız şafta insin [ENDURANCE zor0 PARTY_BEST]{GOLD+PARTY_HP+REPUTATION+STRESS} / Hep birlikte kazın{PROVISIONS+REPUTATION+TRAVEL_DAYS} / Yolunuza devam edin{MORALE+STRESS}
evt_failing_bridge         Çürük Köprü                        0.2 Irmağı oku, sığ geçidi bul [WISDOM zor0 LEADER]{MORALE+PARTY_HP+PROVISIONS+WAGON_DAMAGE} / En çevikleriniz tahtaları önce yürüsün{MORALE+PARTY_HP} / Yukarıdaki sağlam köprüye dolaşın{TRAVEL_DAYS}
evt_grave_on_the_road      İşaretsiz Mezar                    0.8 Dur, dağılan taşları yeniden yığ{MORALE+SET_FLAG+STRESS+TRAVEL_DAYS+UNLOCK_EVENT} / Başını eğ ve geç{SET_FLAG+STRESS+UNLOCK_EVENT}  <koşul:companions_died 0 1;grave_seen 5 0>
evt_grave_keeper           Mezarların Bekçisi                 3.0 Onu dinle [WISDOM zor1 LEADER]{CLEAR_FLAG+REPUTATION+SET_FLAG+STRESS+UNLOCK_EVENT} / Yolumuz uzun, kusura bakma{CLEAR_FLAG}  <zincir,koşul:grave_seen 4 0>
evt_grave_offering         Bekçinin Adağı                     3.0 Erzaktan bir pay bırak{CLEAR_FLAG+GRANT_TRAIT+PROVISIONS} / Teşekkür et ve yürü{CLEAR_FLAG}  <zincir,koşul:grave_seen 4 0;keeper_trusted 4 0>
evt_deserter_plea          Cepheden Kaçanlar                  1.6 Onları sakla{PROVISIONS+SET_FLAG+UNLOCK_EVENT} / Bir sonraki karakolda haber ver{REPUTATION+SET_FLAG+STRESS} / Geri çevir{SET_FLAG+STRESS}  <koşul:route_has_regional_war 0 1;deserters_met 5 0>
evt_deserter_search        Devriye Arıyor                     3.0 Görmedik de, yüzüne bak [CHARISMA zor1.5 PARTY_BEST]{CLEAR_FLAG+SET_FLAG+TRIGGER_COMBAT+UNLOCK_EVENT} / Onları teslim et{CLEAR_FLAG+STRESS}  <zincir,koşul:deserters_hidden 4 0>
evt_deserter_debt          Kurtarılanların Borcu              3.0 Biri kervana katılsın{CLEAR_FLAG+TRIGGER_RECRUIT} / Taşıdıkları kılıcı al{CLEAR_FLAG+GRANT_EQUIPMENT}  <tek,zincir,koşul:deserters_hidden 4 0;deserters_safe 4 0>
evt_carcass_on_road        Yol Kenarında Leş                  0.9 Kes, erzağa kat{PROVISIONS+SET_FLAG+UNLOCK_EVENT} / Yak, kokusu yayılmasın{MORALE}  <koşul:danger 0 0.3;wolf_scent 5 0>
evt_wolves_follow          Peşimizdekiler                     3.0 Eti bırak, sürü onu alsın{CLEAR_FLAG+PROVISIONS} / Nöbet tut, kaç tane olduklarını say [PERCEPTION zor1 LEADER]{SET_FLAG+UNLOCK_EVENT+WAGON_DAMAGE}  <zincir,koşul:wolf_scent 4 0>
evt_wolf_pack              Sürü                               3.0 Silahları çek{CLEAR_FLAG+TRIGGER_COMBAT} / Bir vagonun öküzünü onlara bırak{CLEAR_FLAG+WAGON_DAMAGE}  <zincir,koşul:wolf_scent 4 0;wolves_counted 4 0>
evt_creditor_rider         Alacaklının Atlısı                 1.5 Ödeyeceğine söz ver{SET_FLAG+STRESS+UNLOCK_EVENT} / Kov gitsin{REPUTATION+SET_FLAG+UNLOCK_EVENT}  <koşul:debt_overdue 0 1;debt 0 150;creditor_warned 5 0>
evt_bailiffs_at_camp       İcra Memurları                     3.0 Erzaktan teslim et, borçtan düşülsün{CLEAR_FLAG+DEBT_SETTLE+PROVISIONS} / Mühlet iste [CHARISMA zor2 LEADER]{CLEAR_FLAG+REPUTATION+STRESS+UNLOCK_EVENT} / Kampa sokma{CLEAR_FLAG+TRIGGER_COMBAT}  <zincir,koşul:creditor_warned 4 0;debt_overdue 0 1>
evt_hunting_trip           Av Fırsatı                         1.0 Sessizce yaklaş, avlan [PERCEPTION zor0 PARTY_BEST]{MORALE+PARTY_HP+TRIGGER_COMBAT} / Rahatsız etme, yoluna devam et{MORALE}
evt_deserter_levy          Maaşsız Bölük                      1.9 Hepsini indir{CARGO_PLUNDER+MORALE+STRESS} / Diren{TRIGGER_COMBAT} / Bir sandığı paha biçilmez diye yuttur [INTELLECT zor2.5 PARTY_BEST tavan70]{CARGO_DECOY+STRESS+TRIGGER_AMBUSH}  <koşul:deserters_here 0 1;cargo_items 0 1>
evt_cargo_toll             Para Değil, Mal                    1.8 Yarısını bırak{CARGO_PLUNDER+FACTION+MORALE} / Yükü koru{FACTION+TRIGGER_COMBAT} / Bir kalemi paha biçilmez diye yuttur [INTELLECT zor2.5 PARTY_BEST tavan70]{CARGO_DECOY+STRESS+TRIGGER_AMBUSH}  <koşul:cargo_items 0 2>
evt_road_ultimatum         Ya Paran Ya Canın                  0.9 Her şeyi bırak, yürü{CARGO_PLUNDER+GOLD+MORALE+STRESS} / Hiçbir şey bırakma{TRIGGER_COMBAT} / Tek bir malı canının bedeli diye sun [INTELLECT zor2.5 PARTY_BEST tavan70]{CARGO_DECOY+STRESS+TRIGGER_AMBUSH}  <koşul:danger 0 0.35;cargo_items 0 1>
evt_provision_raid         Un İsteyenler                      1.7 İstedikleri unu ver{MORALE+PROVISIONS} / Daha azına ikna etmeye çalış [CHARISMA zor1 PARTY_BEST]{MORALE+PROVISIONS+STRESS} / Kileri koru{TRIGGER_COMBAT}  <koşul:provisions 0 35>
```


> **Bundan çıkarman gereken:** bir kartın dünyaya dokunabildiği bütün yüzey ve bugün gerçekten ne
> anlatıldığı. Yeni bir etki türü önermeden önce listede eşdeğeri olup olmadığına bak; 101 kartın
> hepsinin seçenekleri yukarıda, aynı ikilemi yeniden yazma.

### VERİ-3 · İNSANLAR

Tayfa ile parti ayrıdır: kervanda herkes yürür, savaşa dört kişi girer. Her kişi bir kültür, bir sınıf, bir görev, huylar ve ekipman taşır; stres, yorgunluk ve kırgınlık biriktirir.

**Kültürler (oyuncu başlangıcı buradan seçilir)**

```
nomad    Göçebe Boyları     Yolda günlük erzak tüketimin stat AGILITY+2,ENDURANCE+1,INTELLECT-1,WISDOM+1 · erzak×0.7 alış×1 hasar×1 haber×1
valley   Vadi Loncaları     Pazardan alımlarda %10 indir stat INTELLECT+2,CHARISMA+1,STRENGTH-1,FAITH-1 · erzak×1 alış×0.9 hasar×1 haber×1
highland Dağ Kabilesi       Savaşta verdiğin hasar %15 f stat STRENGTH+2,ENDURANCE+1,CHARISMA-1,FAITH+1 · erzak×1 alış×1 hasar×1.15 haber×1
port     Liman Şehri        Tavernada sohbette yol ve pa stat CHARISMA+2,PERCEPTION+1,ENDURANCE-1,WISDOM+1 · erzak×1 alış×1 hasar×1 haber×0.6
fisher   Balıkçı Kasabası   Erzak satın alımların %25 uc stat ENDURANCE+2,PERCEPTION+1,AGILITY-1,FAITH+1 · erzak×1 alış×1 hasar×1 haber×1
```

**Sınıflar ve görevler**

```
guard        Sıra Neferi      görev=muhafiz    can+6   beceri: shield_bash, spear_thrust, sling_shot, brace
hunter       Sekban           görev=izci       can+2   beceri: arrow_shot, leg_tie, aimed_shot, step_back
breaker      Kırıkçı          görev=arabaci    can+8   beceri: sledge_strike, shield_break, rage, sweeping_blow
clerk        Kalem Efendisi   görev=levazimci  can+0   beceri: rousing_speech, cutting_word, keep_ledger, blight_flask

görev vanguard   Öncü           ana stat PERCEPTION · Kervanın önünde yürür: iz okur, yolu kısaltır, ilk kılıcı çeker, yaban
görev middle     Ortancı        ana stat STRENGTH · Vagonların arasında yürür: tekerleğe, yüke ve erzağa bakar (arabacı, l
görev rear       Artçı          ana stat WISDOM · Kervanın ardında yürür: yaralıya, geride kalana ve peşinden geleni far
```

**Huylar (16) — tohum huyları ve kırılma huyları**

```
mighty_arm           Pazı Gücü        olumlu · Kolundaki güç vuruşlarına yansır.
weak_arm             Cılız Kol        OLUMSUZ · Vuruşlarında beklenen ağırlık yok.
nimble_step          Çevik Adım       olumlu · Ayakları hep bir adım önde.
clumsy_foot          Beceriksiz Ayak  OLUMSUZ · Kaçınması gereken yerde tökezler.
iron_constitution    Demir Bünye      olumlu · Yaraya da açlığa da dayanıklı - yolun günlük yıpranması da ona daha az işler.
frail_constitution   Zayıf Bünye      OLUMSUZ · Küçük bir darbe bile ağır geçer - yolun günlük yıpranması da onu daha çok yorar.
prudent              Basiretli        olumlu · Vurmadan önce düşünür, isabeti artar. Sözünü iyi tartar - hem başkasını kandırma
naive                Saf              OLUMSUZ · Sırası gelince kararsız kalır, tüccar karşısında da kolay kandırılır.
sharp_eye            Keskin Göz       olumlu · Zayıf noktayı hep bulur.
nearsighted          Miyop            OLUMSUZ · Uzaktaki hedefi hep ıskalar.
reassuring           Güven Verici     olumlu · Yanındakiler onunla daha rahat savaşır, huzuru kervanın moraline de sirayet eder
off_putting          İtici            OLUMSUZ · Yanındakiler tedirgin, saf biraz bozuk; huzursuzluk kervanın moraline de sirayet
keen_mind            Keskin Zihin     olumlu · Tecrübeden çıkardığı ders kalıcı - daha hızlı öğrenir.
dull_wit             Kalın Kafa       OLUMSUZ · Aynı hatayı tekrar tekrar yapar - tecrübesi az iz bırakıyor.
steadfast_faith      Sarsılmaz İnanç  olumlu · Ölümün eşiğinde bile inancı onu ayakta tutuyor.
wavering_faith       Sarsılmış İnanç  OLUMSUZ · İnancı sarsılmış - ölümün eşiğinde tutunacak daha az şeyi var.
```

**CharacterData - kişi, stres, yorgunluk, kırgınlık (`scripts/character/character_data.gd`)**

```
MIN_HEIGHT_CM                      = 155
MAX_HEIGHT_CM                      = 250   # Oyuncunun seçebileceği tavan (kullanıcı kararı: 2,5 m). Doğal tavan `NATURAL_MAX_HEIGHT_CM`: rastgele çekilen adaylar onu aşmaz, yoksa her meydanda devler dolaşırdı.
NATURAL_MAX_HEIGHT_CM              = 200
DEFAULT_HEIGHT_CM                  = 172
TALL_THRESHOLD_CM                  = 182   # Boyun eşiği: bunun üstü "uzun", altı "kısa" sayılır.
SHORT_THRESHOLD_CM                 = 166
HP_BAND_HEALTHY_RATIO              = 0.75   # `get_condition_label_key()`'in bantları - doc'un dört sıfatı (Dinç/ Yaralı/Ağır Yaralı/Ölümün Kıyısında), oranın kendisiyle.
HP_BAND_WOUNDED_RATIO              = 0.50
HP_BAND_BADLY_WOUNDED_RATIO        = 0.25
SKIN_TONE_NAMES                    = [   # Anahtar tutulur, metin okunduğu yerde çözülür - `const` içinde tr() çağrılamaz (bkz. CLAUDE.md Localization Rules).
MAX_LEVEL                          = 20
XP_BASE                            = 50
XP_GROWTH                          = 1.25
STAT_POINTS_PER_LEVEL              = 1
SKILL_POINTS_PER_LEVEL             = 2
MULTICLASS_UNLOCK_LEVEL            = 7
MAX_SKILL_PROFICIENCY              = 100
GENDER_FEMALE                      = 0   # zaten yaptığı gibi birkaç türetilmiş sayıyı büker - bkz. aşağıdaki `get_gender_*_bonus`/`get_body_weight_*_bonus`. `skin_tone`'un yanına, aynı index-tabanlı üslupla eklendi.
GENDER_MALE                        = 1
GENDER_NAMES                       = ["GENDER_FEMALE", "GENDER_MALE"]
BODY_WEIGHT_LEAN                   = 0
BODY_WEIGHT_AVERAGE                = 1
BODY_WEIGHT_HEAVY                  = 2
BODY_WEIGHT_NAMES                  = [
MAX_TRAITS                         = 3
TRAIT_FRESH_WINDOW_DAYS            = 5   # Yalnızca "taze" (bkz. is_trait_fresh) bir huy tavernada/kilisede silinebilir - eski huylar kalıcılaşır.
PERSONAL_BAG_CAPACITY              = 5.0   # add_to_cargo_or_bag) ve şehirdeki toplam envanter (bkz. GameSession. get_total_inventory_entries) buna da bakar - "kısıtlı" sözü tam burada: kapasitesi bir vagonun onda biri kadar.
MAX_XP_BONUS_PERCENT               = 40   # eski davranış birebir korunur), tavan/taban var ki hiçbir stat XP eğrisinin kendisini anlamsızlaştırmasın (bkz. CLAUDE.md'nin "bir stat bir sistemi asla tamamen kapatmaz" tekrarlayan kuralı).
MIN_XP_BONUS_PERCENT               = -40
GENDER_HP_BONUS                    = [-2, 2]  # kadın, erkek
GENDER_DODGE_BONUS                 = [3, -3]
GENDER_CRIT_BONUS                  = [2, 0]
GENDER_DAMAGE_BONUS                = [0, 1]
WEIGHT_HP_BONUS                    = [-2, 0, 4]  # ince, orta, iri
WEIGHT_DODGE_BONUS                 = [3, 0, -4]
WEIGHT_DAMAGE_BONUS                = [-1, 0, 2]
WEIGHT_PROVISION_FACTOR            = [0.9, 1.0, 1.15]
CHECK_LEAN                         = 0.5   # bir kaynak olarak paylaşıyor, büyüklüğü de huylarınkiyle aynı (TraitCatalog.CHECK_BONUS_MAGNITUDE, 0.5) tutuldu ki iki kaynak aynı ölçekte okunsun. `SkillCheck`'in kendisi hiç değişmiyor.
MAX_STRESS                         = 100   #  `GameSession.party_stress` artık bu değerlerin **ortalamasına bakan bir mercek**: okunabilir, yazılabilir, ama sahibi burası.
BACKSTORY_DEBTOR                   = "debtor"   # Yoldaşın geçmişi (görev R0): neden yola düştüğü. Kervana mecbur olanlar katılır (Ana Hedefler: borçlu, sürgün, dul, kaçak, aç). Boşsa kimlikten tohumlanır - kayıt yüklemek geçmişi yeniden atmaz.
BACKSTORY_EXILE                    = "exile"
BACKSTORY_WIDOW                    = "widow"
BACKSTORY_FUGITIVE                 = "fugitive"
BACKSTORY_HUNGRY                   = "hungry"
BACKSTORY_KEYS                     = [BACKSTORY_DEBTOR, BACKSTORY_EXILE, BACKSTORY_WIDOW, BACKSTORY_FUGITIVE, BACKSTORY_HUNGRY]
BACKSTORY_LABEL_KEYS               = {
MAX_RAPPORT                        = 5   # Liderle bağ (0-5): 1 tanıştık, 3 güven, 5 sır. Sohbet, ortak savaş ve kamp hikâyesi artırır; şikâyet azaltır.
BREAK_RECKLESS                     = "reckless"   # efektiyle değil. Kip son kötü huyunun statından: güç/çeviklik öne atılır, dayanıklılık/inanç bütün darbeyi üstüne çeker, zeka/bilgelik emre uymaz, sezgi/karizma arkadaşına saldırır. Kötü huyu yoksa emre uymaz.
BREAK_MARTYR                       = "martyr"
BREAK_DEFIANT                      = "defiant"
BREAK_LASHES_OUT                   = "lashes_out"
GRIEVANCE_UNFED                    = "unfed"
GRIEVANCE_BENCHED                  = "benched"
GRIEVANCE_WITNESSED_DEATH          = "witnessed_death"
GRIEVANCE_PASSED_OVER              = "passed_over"
GRIEVANCE_KEYS                     = [
OATH_CULTURES                      = ["nomad", "highland"]   # bırakmaz (bkz. GameSession.get_break_departure_chance). Lider sözü bozarsa (aç bırakmak, savaştan uzak tutmak, liderlikte geçmek) bağ sıfırlanır ve kırgınlık ağırdır.
OATH_RAPPORT                       = 3
OATH_BROKEN_WEIGHT                 = 3
GRIEVANCE_OATH_BROKEN              = "oath_broken"
OATH_BREAKERS                      = ["unfed", "benched", "passed_over"]
TWO_HANDED_WEAPONS                 = ["bow", "maul", "spear_shield"]   # İki el isteyen silah türleri (CombatFigure.ARCHETYPES "weapon").
CREED_SEPTISM                      = "septisizm"   # Kervanbaşının inancı (Y-C34, kullanıcı kararı: "kervanın inancı kervan başının inancına göre"). Boşsa kültürden ve doğduğu yerden türetilir.
CREED_FIST                         = "yumruk"
CREED_BAIKHAN                      = "baikhan"
CREED_OLD                          = "eski"
CREED_NAME_KEYS                    = {
DAILY_STRESS_GAIN_PER_RESIST_POINT = -0.06   # %6'da tek huy tavan/tabana tam oturuyor (±5*0.06=±0.30) - "bir huy görünür olmalı" kuralı (bkz. Road Layer Rules'un aynı gerekçesi) küçük bir tabanda ancak böyle tutulabiliyordu.
MIN_DAILY_STRESS_GAIN_MULT         = 0.7
MAX_DAILY_STRESS_GAIN_MULT         = 1.3
MAX_FATIGUE                        = 100   # ortasında yürümek indirir (kaynakların hepsi GameSession'da). Stresle karışmaz: stres seferler boyu biriken yıpranma, yorgunluk bir uykuda büyük ölçüde geçen beden.
FATIGUE_HEAVY_GAIN_MULT            = 1.25   # İri beden zaten çok yiyor (WEIGHT_PROVISION_FACTOR); yorgunluk aynı eksende: artışlar %25 fazla yazılır. Kaynakların hepsi 4'ün katı, yani yuvarlama payı yutmaz (4 -> 5, 8 -> 10).
FATIGUE_COMBAT_THRESHOLD           = 60   # Savaş cezası (kullanıcı kararı: küçük, yalnızca yüksek yorgunlukta): eşikte isabet ve kaçınma -2, ağır eşikte -4. Dertlerin -2..-4'üyle aynı ölçek; savaşı yorgunluk değil karar belirlesin.
FATIGUE_COMBAT_SEVERE              = 85
FATIGUE_COMBAT_PENALTY             = 2
RESIST_PER_LEVEL                   = 3   #  Tavan var: hiçbir seviye bir sistemi tamamen kapatmamalı - aynı kural `CombatUnit`'in MIN/MAX_STATUS_CHANCE'ında da var.
MAX_STATUS_RESIST                  = 80
AILMENTS                           = {   # Yarı kalıcı dert: gün sayar, kendi kendine geçer ya da hekimde iyileşir. Etkisi huy, ekipman ve kıyafetle aynı alanlardan (savaş aynı sarmalayıcıları okur). Hastalık her yol günü stres de yazar. Kayıtta.
INJURIES                           = ["broken_arm", "twisted_ankle", "deep_cut"]
```

**CharacterStats - yedi stat (`scripts/character/character_stats.gd`)**

```
BASE_VALUE                         = 5
MIN_VALUE                          = 1
MAX_VALUE                          = 15
KIND_ORDER                         = [
```

**CaravanLedger - defter (`scripts/campaign/caravan_ledger.gd`)**

```
KIND_JOINED                        = "joined"   # Satır türleri. Kimlikler kayda yazıldığı için sabit.
KIND_DEPARTED                      = "departed"
KIND_DIED                          = "died"
KIND_LED                           = "led"
KIND_FOUNDER                       = "founder"   # kalmasın, tezini ilk satırından söylesin diye: devraldığın ad zaten birinin üstü çizili adıydı. Hiçbir sayaca girmiyor (kampanya/olay bağlamı `KIND_DIED`'ı sayıyor, bunu değil) - kurucu senin kaybın değil, mirasın.
KIND_STORY                         = "story"   # Yolun hafızası (görev R0): kamp hikâyesi, günün cümlesi, töre, mahkeme kararı, yolda dikilen anıt. Hiçbiri çizili değil, hiçbir sayaca girmez (KIND_FOUNDER gibi); `cause` kendi metin anahtarını taşır.
KIND_DIARY                         = "diary"
KIND_CODE                          = "code"
KIND_VERDICT                       = "verdict"
KIND_MEMORIAL                      = "memorial"
KIND_TRADE                         = "trade"   # Ticaretin deftere düşen izi (P2, P14): kıtlıkta üstelenen bir pazarlık, aç bir şehirde satılan son ilaç. Defterin dördüncü sütunu ticarete de bakıyor - *Defter unutmaz.*
KIND_LABEL_KEYS                    = {   # Tür -> çeviri anahtarı. Tam yazılıyor, çalışma anında birleştirilmiyor (çeviri tarayıcısı ve çevirmen anahtarı arayınca bulabilsin diye).
STRUCK_KINDS                       = [KIND_DEPARTED, KIND_DIED, KIND_FOUNDER]   # Üstü çizili sayılan türler: kervandan ayrılmış olmak.
STORY_PAGE_KINDS                   = [KIND_STORY, KIND_DIARY, KIND_CODE, KIND_VERDICT, KIND_MEMORIAL]   # Ateş başı hikâyeleri, günün cümleleri, töre, karar ve anıtlar: düşmeyen, çizilmeyen hatıralar (Düşenler sayfasının sağı).
```

**Savaş becerileri (33)**

```
shield_bash(6), spear_thrust(9), sling_shot(7), brace(-), arrow_shot(8), leg_tie(4), aimed_shot(10), step_back(-), sledge_strike(14), shield_break(6), rage(-), sweeping_blow(7), rousing_speech(+9), cutting_word(3), keep_ledger(-), blight_flask(3), bandit_cleave(8), bandit_arrow(6), bandit_order(11), wolf_bite(7), bear_claw(10), boar_charge(10), stag_charge(13), deer_kick(3), fire_bolt(8), ray_of_frost(5), magic_missile(6), poison_spray(3), burning_hands(5), sleep_spell(1), arcane_shield(-), guard_strike(8), guard_order(10)
```

**Ekipman (36)**

```
weapon_tier_1[weapon], weapon_tier_2[weapon], weapon_tier_3[weapon], armor_tier_1[armor], armor_tier_2[armor], armor_tier_3[armor], ring_marksman[ring], ring_gambler[ring], ring_charmed[ring], amulet_ward[amulet], amulet_wolf_fang[amulet], amulet_courage[amulet], weapon_spear[weapon], weapon_axe[weapon], weapon_old_blade[weapon], armor_gambeson[armor], armor_scale[armor], armor_lamellar[armor], ring_iron_band[ring], ring_hawk[ring], ring_steady_hand[ring], ring_bloodstone[ring], ring_debtor[ring], ring_silent[ring], ring_salt_seal[ring], ring_widow[ring], ring_drowned[ring], amulet_bear_claw[amulet], amulet_wayfarer_stone[amulet], amulet_raven_feather[amulet], amulet_ash_locket[amulet], amulet_ancient_eye[amulet], amulet_salt_charm[amulet], amulet_horse_hair[amulet], amulet_wolf_skull[amulet], amulet_copper_coin[amulet]
```


> **Bundan çıkarman gereken:** bir kişinin bugün taşıdığı bütün alanlar. Psikolojik alt sistem (`Ruh`)
> bunların **üstüne** oturmalı: var olan stres, yorgunluk, kırgınlık ve huy sistemini besle, yerine yenisini
> koyma.

### VERİ-4 · EKONOMİ VE DÜNYA

Kervan malı ucuza alıp pahalıya satar ama kıtlıkta asıl gelir **ulaştırmadır**: kontrat, teslimat ve şehrin hâli. Her şehrin ürettiği ve istediği mal, sur türü, bölgesi ve halkı var.

**Ticaret malları (18)**

```
provisions     Erzak               4 GG · ağırlık 0.5  raf 0    
test_grain     Buğday              5 GG · ağırlık 1    raf 0    
test_cloth     Top Kumaş          12 GG · ağırlık 1.5  raf 0    
test_weapon    Demir              40 GG · ağırlık 2.5  raf 0    
test_potion    Otacı İksiri       20 GG · ağırlık 0.5  raf 0    
test_furs      İşlenmiş Kürk      30 GG · ağırlık 2    raf 0    
spice          Baharat            35 GG · ağırlık 0.4  raf 0    
honey          Bal                15 GG · ağırlık 1.2  raf 0    
silk           İpek               45 GG · ağırlık 0.6  raf 0    
jewelry        Mücevher           60 GG · ağırlık 0.2  raf 0    
fish           Balık               8 GG · ağırlık 1    raf 6    
wine           Şarap              18 GG · ağırlık 1.8  raf 0    
contraband_salt Mühürsüz tuz       22 GG · ağırlık 0.8  raf 0    KAÇAK
lantern        Fener              24 GG · ağırlık 1    raf 0    
lantern_oil    Fener yağı          3 GG · ağırlık 0.3  raf 0    
torch          Meşale              2 GG · ağırlık 0.5  raf 0    
paper          Kâğıt              10 GG · ağırlık 0.4  raf 0    
steppe_spice   Bozkır baharı      20 GG · ağırlık 0.4  raf 0
```

**Yerleşimler (27) — bölge, tür, sur, üretim, talep, komşular**

```
akavan           Akavan       vadi       town   sur=wood   üretir:honey,test_grain         ister:test_cloth,fish          -> serai_duvenmor,tolvarin
auderin          Auderin      imparatorluk town   sur=wood   üretir:test_furs                ister:test_grain,wine          -> vastrevar
belvanor         Belvanor     vadi       city   sur=stone  üretir:wine,test_cloth          ister:test_weapon,jewelry,spice -> ilsande,merigaud,mirsana
brazdun          Brazdun      dag        town   sur=stone  üretir:test_weapon,jewelry      ister:test_grain,test_cloth    -> kesgrav
caramine         Caramine     vadi       town   sur=wood   üretir:wine,test_grain          ister:fish,test_furs           -> ilsande,serai_seyvan
dravoss          Dravoss      imparatorluk city   sur=stone  üretir:test_weapon,test_grain   ister:wine,honey,test_potion   -> selvicar
ezmerak          Ezmerak      sinir      city   sur=stone  üretir:honey,test_furs          ister:test_grain,test_cloth,spice -> ondrelle,orvahel,golcavar
golcavar         Golcavar     sinir      town   sur=wood   üretir:test_potion,fish         ister:test_grain,test_weapon   -> ezmerak,rivecande
ilsande          Ilsande      vadi       city   sur=stone  üretir:silk,wine                ister:test_furs,test_weapon,honey -> belvanor,caramine,serai_seyvan,mirsana
kesgrav          Kesgrav      dag        town   sur=stone  üretir:test_weapon              ister:test_grain,wine          -> brazdun,rivecande
kirsavel         Kirsavel     sinir      town   sur=wood   üretir:test_grain               ister:test_weapon,test_potion  -> samuran,serai_orbeyan,tolvarin
liraven          Liraven      vadi       town   sur=wood   üretir:fish,test_potion         ister:test_grain,test_cloth    -> merigaud,mirsana,samuran
merigaud         Merigaud     vadi       city   sur=stone  üretir:test_grain,wine          ister:test_weapon,test_furs,fish -> liraven,belvanor,serai_duvenmor
mirsana          Mirsana      guney      town   sur=stone  üretir:spice,test_cloth         ister:test_grain,fish          -> liraven,belvanor,ilsande,samuran
ondrelle         Ondrelle     vadi       city   sur=stone  üretir:test_grain,honey         ister:test_weapon,fish,test_cloth -> ezmerak,orvahel,serai_duvenmor
orsolune         Orsolune     guney      city   sur=stone  üretir:spice,fish               ister:test_furs,test_weapon,test_grain -> orvahel,serai_seyvan,vorgat,zelmarin
orvahel          Orvahel      ahit       city   sur=stone  üretir:test_potion              ister:test_grain,paper,test_cloth,honey -> ezmerak,ondrelle,orsolune,serai_seyvan,vorgat,zelmarin
rivecande        Rivecande    imparatorluk city   sur=stone  üretir:fish,test_furs           ister:test_grain,wine,spice    -> golcavar,kesgrav,vastrevar
samuran          Samuran      vadi       town   sur=wood   üretir:test_potion,fish         ister:test_grain,test_cloth    -> kirsavel,liraven,mirsana
selvicar         Selvicar     imparatorluk town   sur=wood   üretir:test_grain               ister:test_cloth,wine          -> dravoss,serai_orbeyan,vastrevar
serai_duvenmor   Duvenmor Kervansarayı vadi       caravanserai sur=stone  üretir:silk,wine                ister:spice,test_furs          -> akavan,merigaud,ondrelle
serai_orbeyan    Orbeyan Kervansarayı gocebe     caravanserai sur=felt   üretir:test_furs,steppe_spice   ister:test_cloth,test_weapon   -> kirsavel,selvicar,tolvarin
serai_seyvan     Seyvan Kervansarayı guney      caravanserai sur=stone  üretir:spice,jewelry            ister:wine,test_grain          -> caramine,ilsande,orsolune,orvahel,vorgat,zelmarin
tolvarin         Tolvarin     sinir      city   sur=stone  üretir:test_furs,test_grain     ister:test_weapon,test_cloth,wine -> akavan,kirsavel,serai_orbeyan
vastrevar        Vastrevar    imparatorluk city   sur=stone  üretir:test_weapon,test_cloth   ister:spice,wine,silk,jewelry  -> auderin,rivecande,selvicar
vorgat           Vorgat       dag_maden  town   sur=wood   üretir:jewelry,fish             ister:test_grain,test_cloth    -> orsolune,orvahel,serai_seyvan,zelmarin
zelmarin         Zelmarin     guney      city   sur=stone  üretir:jewelry,spice            ister:test_grain,wine,test_furs -> vorgat,orsolune,orvahel,serai_seyvan
```

**Bölgesel haydut kimlikleri (yolu kesen, oranın kendi aç insanıdır)**

```json
{
 "ahit": {
  "melee": "handless_exile",
  "second": "garrison_deserter"
 },
 "dag": {
  "leader": "toll_man",
  "melee": "mountain_bandit"
 },
 "dag_maden": {
  "melee": "mine_runaway",
  "second": "mountain_bandit"
 },
 "gocebe": {
  "melee": "oba_raider",
  "ranged": "steppe_rider"
 },
 "guney": {
  "melee": "coast_corsair",
  "ranged": "smuggler"
 },
 "imparatorluk": {
  "melee": "garrison_deserter",
  "ranged": "armed_brigand"
 },
 "sinir": {
  "extra": "hungry_exile",
  "melee": "border_raider"
 },
 "vadi": {
  "melee": "valley_deserter",
  "ranged": "valley_forager"
 }
}
```

**Scarcity - kıtlık sürüklenmesi (`scripts/travel/scarcity.gd`)**

```
REGION_BASE                        = {
SEASON_SWING                       = 0.12
YEAR_DAYS                          = 360
WINTER_PEAK_DAY                    = 300   # Kış ortası (en ağır gün) yılın bu günü.
DRIFT_PER_DAY                      = 0.00055   # sonunda tavana yaklaşılıyor; Vadi gibi tabanı yüksek bir bölge o noktada neredeyse yokluğa iniyor. Birinci yılda fark küçük (gün 360'ta 0,14 yerine 0,20): erken oyun aynı kalıyor, geç oyun ısırıyor.
DRIFT_CAP                          = 0.45
FOOD_ITEMS                         = ["provisions", "test_grain", "fish", "honey"]
FOOD_PRICE_RISE                    = 0.6   # Fiyat: yiyecek kıtlıkla en çok pahalanır, öbür mallar az.
GOODS_PRICE_RISE                   = 0.2
STOCK_WITHHELD                     = 0.6   # Pazarda satılmayan pay: satıcı satmak istemez.
HUNGRY_CITY_FROM                   = 0.5   # Bir şehrin "aç" sayıldığı kıtlık derecesi (P14): bunun üstünde yiyecek satmak bir alışveriş değil bir iyiliktir ve hatırlanır.
PROVISION_BASE_STOCK               = 150   # Bir şehrin bir günde satabileceği erzak (ticaret payı 1.0 iken, bolluk).
PROVISION_SCARCITY_BITE            = 0.88   # Kıtlık bu payı yiyor: derece 1'de taban stoğun yalnızca %12'si kalır.
PROVISION_MIN_STOCK                = 0   # Yiyecek kıtlıkta en önce biter: bu pay, genel `STOCK_WITHHELD`'den sert. Gerekçe (Y-C21): "kervanın ulaştırdığı yük şehrin hâlini düzeltir" - şehirlerde yiyecek olsaydı kervanın taşıdığı şeyin anlamı kalmazdı.
PROVISION_DAY_SWING                = 0.35   # Günden güne dalgalanma payı: aynı şehir her gün aynı sayıyı vermez. Tohum şehir + gün, yani gün içinde sabit.
```

**MarketPricing - fiyat (`scripts/economy/market_pricing.gd`)**

```
PRODUCE_BUY_MULTIPLIER             = 0.6
DEMAND_SELL_MULTIPLIER             = 1.7
BASE_SELL_MULTIPLIER               = 0.5
CONTRABAND_BUY_MULTIPLIER          = 0.55   # Kaçak mal (Y-C19): kervansarayda kaçakçıdan ucuz, şehirde ve kasabada pahalı satılır - kâr yüksek, bedeli gümrük. Nadir mal yalnız şehirde.
CONTRABAND_SELL_MULTIPLIER         = 1.9
RARE_SELL_MULTIPLIER               = 1.6
BULK_MIN_QUANTITY                  = 20   # Toplu alım: bir seferde BULK_MIN_QUANTITY ve üstü alana indirim.
BULK_DISCOUNT                      = 0.06
BARTER_BONUS_BASE                  = 0.10   #  Ve oyuncuyu "en kârlısı hangisi" yerine **"neyden vazgeçebilirim"** sorusuna taşıyor: teraziye koyduğun şey kervanın kendi yükü.
BARTER_BONUS_PER_SCARCITY          = 0.45
FRESHNESS_FULL_SHARE               = 0.25   # fiyatına, sonra raf ömrünün sonuna kadar FRESHNESS_FLOOR'a iner. Çürüme (GameSession.spoil_perishables) miktarı yer, bu fiyatı: üç günlük balık hâlâ balıktır ama tezgâhta tazesi gibi satılmaz.
FRESHNESS_FLOOR                    = 0.6
LAYER_PLACE                        = "place"   # da arar), yerleşim türü, enflasyon, mevsim, arz baskısı, olay şoku, dünya olayı. Hepsi her zaman listede; ekran yalnızca 1.0'dan sapanı işaretler. Çarpımları (toplam kenetlenmediyse) fiyatın kendisi - test bunu sınar.
LAYER_SETTLEMENT                   = "settlement"
LAYER_INFLATION                    = "inflation"
LAYER_SEASON                       = "season"
LAYER_PRESSURE                     = "pressure"
LAYER_EVENT                        = "event"
LAYER_WORLD                        = "world"
LAYERS                             = [
```

**MarketConditions - şehrin hâli (`scripts/economy/market_conditions.gd`)**

```
INFLATION_PER_DAY                  = 0.0015   # Günlük bileşik değil doğrusal artış: uzun bir oyunda fiyatlar tırmanır ama kontrolden çıkmaz. Tavan, geç oyunun tamamen ulaşılmaz olmasını engelliyor.
INFLATION_CAP                      = 1.8
SEASON_LENGTH_DAYS                 = 30
SEASON_MULTIPLIERS                 = {   # Mal başına mevsim çarpanı: [ilkbahar, yaz, sonbahar, kış]. Hasat sonbaharda tahılı ucuzlatır, kış kürkü pahalandırır. Listede olmayan mal mevsimden etkilenmez.
PRESSURE_PER_UNIT_BOUGHT           = 0.010   # Alım fiyatı yukarı iter, satış aşağı - bir şehri sürekli boşaltmak orayı pahalılaştırır. Bu, tek bir rotayı sonsuza kadar sağmayı (cheat farming) engelleyen şey.
PRESSURE_PER_UNIT_SOLD             = 0.008
PRESSURE_LIMIT                     = 0.45
PRESSURE_DECAY_PER_DAY             = 0.06   # Baskı her gün bu oranda tabana geri çeker - pazar zamanla kendini toparlar.
CITY_GOLD_DEFAULT                  = 260.0   # geri süzülür - aynı "pressure decays toward baseline" deyimi, ikinci kez icat edilmeden. Yani ne sürekli MAX'a sürüklenen ne de sonsuza dek tükenmiş kalan bir hazine.
CITY_GOLD_MAX                      = 900.0
CITY_GOLD_REGEN_RATE               = 0.05
SHOCK_LIMIT                        = 2.5   # Süreli fiyat şoku: bir şehirde bir malın (ya da tüm malların) fiyatını bir süre için değiştirir. EventEffect.Type.MARKET_SHOCK bunu kurar.
TOTAL_MULTIPLIER_MIN               = 0.35   # Toplam çarpanın sıkıştırıldığı aralık - katmanlar üst üste binip fiyatı saçmalaştırmasın diye.
TOTAL_MULTIPLIER_MAX               = 3.0
CITY_GOLD_SCARCITY_DRAIN           = 0.55   # Ve bu, takasla (P6) aynı cümleyi söylüyor: altın kıtlıkta işe yaramaz. Şehrin alacak parası kalmayınca mal mala değişmek bir seçenek değil, tek yol olur.
HARDSHIP_WINTER                    = 0.30   # Kervanın yola hangi moralle çıktığını bu belirliyor (bkz. GameSession.get_departure_morale): bereketli bir ilkbaharda kadro keyifli, kıtlık kol gezen bir kışta değil.
HARDSHIP_AUTUMN_RELIEF             = -0.10
HARDSHIP_PER_SHOCK_STEP            = 0.60
HARDSHIP_INFLATION_WEIGHT          = 0.35
MEDICINE_ITEM                      = "test_potion"   # --- Şehrin ilaç stoğu (görev Y-C05) --- Hekim stoktan ilaç harcar. Stok yavaş dolar (MEDICINE_REGEN_DAYS'te bir); kervanın şehre sattığı iksir (ilaç) stoğu artırır; veba onu eritir.
MEDICINE_CITY                      = 4
MEDICINE_TOWN                      = 2
MEDICINE_REGEN_DAYS                = 10
```

**Debt - borç (`scripts/economy/debt.gd`)**

```
SOURCE_OVERDRAFT                   = "overdraft"   # Borcun nereden geldiği - alacaklının baskı biçimi buna göre değişir.
SOURCE_LOAN                        = "loan"
SOURCE_ADVANCE                     = "advance"   # Mal avansı (P13): lonca para değil **yük** verir, karşılığında teslimat ister. Kaçış kapağı olan nakit kredinin yerini alıyor.
DEFAULT_TERM_DAYS                  = 30   # Vade: "bir ay içinde ödemeli".
OVERDUE_PERIOD_DAYS                = 10   # Gecikme dönemi ve dönem başına itibar bedeli. Faiz gitti, bu kaldı: gecikme cezasız olmamalı ama bedeli borcun kendisi değil **adın**.
OVERDUE_REPUTATION_PENALTY         = 3
```

**DebtLedger - borç defteri (`scripts/economy/debt_ledger.gd`)**

```
OVERDRAFT_DEBT_ID                  = "overdraft"   # Kese eksiye düştüğünde açılan hesabın alacaklısı. Tek bir açık hesap tutulur; kese daha da eksiye giderse anapara büyür, yeni borç açılmaz.
OVERDRAFT_CREDITOR_KEY             = "DEBT_CREDITOR_MONEYLENDER"
```

**PlagueWorld - İllet dünya hâli (`scripts/travel/plague_world.gd`)**

```
POPULATION                         = {"city": 9000, "town": 3000, "caravanserai": 400}
BETA                               = 0.12   # Bulaşma: günlük temas katsayısı; bölgenin yatkınlığıyla çarpılır.
GAMMA                              = 0.09   # Hastalık ~10 gün sürer.
MU                                 = 0.010   # Hastaların günlük ölüm payı.
ROUTE_MIX                          = 0.02   # Komşu şehirden yolla sızma (yol günü başına söner).
IMMUNITY_FADE                      = 0.0065   # İyileşmişin bağışıklığı söner: ~150 günde sağlama döner.
CARRY                              = 0.006   # Kervanın taşıdığı hasta payı.
VISIBLE                            = 0.02   # Bu payın üstü "vebalı" sayılır: kapıda görülür, hekim yetişemez.
SEED_CITIES                        = 2   # Salgının başladığı şehir sayısı (en yatkın bölgelerden).
SEED_SHARE                         = 0.015
```

**ContractBoard - kontrat panosu (`scripts/travel/contract_board.gd`)**

```
ID_PREFIX                          = "c"
MIN_OFFERS                         = 4
MAX_OFFERS                         = 7
KIND_WEIGHTS                       = {   # Tür ağırlıkları: teslimat en sık (kullanıcı notu).
RUSH_CHANCE                        = 0.25
RUSH_PAY                           = 1.35
DELIVERY_DAY_PAY                   = 11
DELIVERY_PER_CARGO                 = 2
PASSENGER_DAY_PAY                  = 4
WAGON_RENT_PER_DAY                 = 6
CONTRABAND_PAY                     = 1.7
```


> **Bundan çıkarman gereken:** kervanın yaşadığı maddi gerçeklik ve haritanın dokusu. Bölgesiz bir tasarım
> bu oyunda yarım tasarımdır: her öneri "hangi şehirde, hangi bölgede, kimin yüzünden" sorusuna cevap vermeli.

### VERİ-5 · DÜNYA KİTABI (LORE)

Aşağıdaki belge evrenin tek kanonudur. Tamamı burada; özellikle §1.2 (beş omurga), §5 (kıtlık), §10
(bölgeler ve yerleşimler), §12 (yolun töresi), §14 (söyleyiş: kim neye yemin eder, neye küfreder) ve §15
(metin üretim kılavuzu) senin için.

~~~~markdown
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
   bittiler. Deli kral kendisine ait olmayan bir ömür istedi, veremeyenleri yaktı ve sonunda kendini yaktı;
   imparatorluk onunla bitti. Fazlasını zorlayan
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
| 0 | **İmparatorluk çöker.** Savaşın son yılında imparator kendini bir ayinle yakar; başkent Merigard yakılır, halkı sürülür. |
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

[Karar] **Asimilasyonun sırası:** önce Vadi'nin köy inançları, sonra kıyıların deniz inanışı, sonra dağın
nefesi, **en son bozkır**. Direnenler: Tolvarin, Kirsavel, Taşkök ve Gokyurt. Ayazkaya'nın inanışını kilise
yuttu ama dağlı bırakmadı — bugün Dağın Nefesi'nin en yüksek sesle yaşadığı yer orası (§8.4). **Son sıra
imparatorluğu bitirdi:** bozkıra uzanan el dokuz boyu birleştirdi (§4.3).

### 4.2 Deli kral [Yazar, defter IV + Karar]

**[Yazar, defter IV]** Deli kral **imparatorluğun son yöneticisiydi**. "Kral" denmesi bir hakarettir: halk ona
imparator demeyi bıraktı. **Katliam kıtlıktan öncedir** — kıtlık çöküşten kırk yıl sonra başlar, yani katliamın
sebebi açlık değildir.

**[Karar] Neden katletti.** Son imparator hastalandı. İllet değil (ondan yirmi beş yıl önce), adı konmamış bir
hastalık: eli tutmaz oldu, sonra ayağı. Raviellon'da eğitilmiş büyücüleri saraya çağırdı ve onlardan tek bir şey
istedi: **ömür.** Büyü yaşam enerjisidir; bir büyücü kendi enerjisini harcar, başkasının ömrünü uzatmaz —
kadimlerin bile yapamadığı şey budur. Büyücüler bunu söylediler. İmparator sözlerini ihanet, denemelerini ise
"yapabiliyorlar ama yapmıyorlar"ın kanıtı saydı. Hepsini yazlık sarayının avlusunda yaktırdı.

[Karar] Katliam, boylarla savaş başlamadan önceydi. Böylece imparator, ona o ayinin işlemeyeceğini
söyleyebilecek herkesi kendi eliyle yakmış oldu.

**[Yazar, 2026-11-07] Sonu:** **savaşın sonlarında kendini bir ayinle yakarak ölümsüz kılmaya çalıştı ve
öldü.** [Karar] Aynı avluda, büyücüleri yaktırdığı yerde. Ayini kimse yürütmedi, çünkü yürütecek kimse
kalmamıştı; nasıl yapılacağını büyücülerin ağzından duyduğu kadarını saraydaki kâtiplere yazdırmıştı. Ondan
sonra emir verecek kimse kalmadı: başkent bir yıl içinde düştü (§4.3). Yani **imparatorluk onunla bitti** —
hastalığından değil, ölümsüzlük denemesinden. Tarihe "deli" diye geçen adam dünyanın tek doğru sözünü duyan
ve ona inanmayan adamdır.

[Karar] Bu, dünyanın tekrar eden günahının en açık hâlidir (§1.2/3): kendine ait olmayan yaşamı almak. Kadimler
denedi ve bittiler; imparator denedi ve imparatorluk bitti. **Oyun bu bağı hiçbir yerde kurmaz.**

Hiçbir kaynak bunu böyle anlatmaz:

| kim | nasıl anlatır |
|---|---|
| Vaelghard kanun kitabı | Hastalık aklını aldı, taht sahipsiz kaldı, düzeni kuzey devraldı. Yangın bir kaza olarak yazılır. (Krallığın mirasçılık iddiasının temeli bu paragraftır.) |
| Göçebe destanı | Kendisine ait olmayan bir ömür istedi; gök aklını aldı, sonunda kendi ateşini kendi yaktı. Destan büyücüleri hiç anmaz. |
| Orsian muhasebe defteri | Büyücülerin malları saraya geçti ve hiçbir borç kapanmadı. Orsian'a sorarsan deliliğin bir satırı vardır ve o satır ödenmemiştir. |
| Avuçiçi | Söz konusu bile edilmez. Kâtip "o yıllar Kitap'a yazılmadı" der. |
| Raviellon | Hiçbir şey. Kimse cevap vermiyor; büyücülerin bugün bile Sideria'dan uzak durmasının sebebi budur. |
| Büyücü avcıları | Kendi aralarında: "görev tamamlandı" der, kimden emir aldıklarını söylemezler (§3.6). |

- **[Harita]** Sarayının yıkıntısı Vastrevar'ın doğusunda: **Deli Kral Sarayı Yıkıntısı** (§11).

### 4.3 Çöküş ve büyük savaş [Yazar]

- **[Yazar, 2026-11-07] Savaşın sebebi asimilasyondur:** imparatorluk göçebe boylarını **tek tek** asimile
  etmeye çalıştı; **boylar direndi ve sonunda dokuz boy birleşip imparatorlukla savaştı.**
- **[Yazar] Göçebe boyları tarihte bir kez birlikte davranır:** Han birliği toplar, ordular birleşir ve
  imparatorluğa karşı savaşır. İmparatorluk dize gelir ve parçalanır. Savaş bitince her boy obasına döner.
  [Karar] Birlik **Sogurtay konseyinde** kuruldu: tek tek konuşulan boyların hepsinin bir arada bulunduğu tek
  yer orası (§8.3).
  [Karar] **Asimilasyon nasıl yürüdü:** imparatorluğun yöntemi her yerde aynıydı — bir inancı Kitap'a bir sayfa
  olarak katmak (§4.1, §8.1). Bozkırda bu, oba oba yapıldı: bir beye "imparatorluğun beyi" denildi, obaya bir
  kâtip gönderildi, Sogurtay suyundan okumak "Kitap'ın bir satırı" ilan edildi, otlak deftere yazıldı. Her oba
  yalnız direndi ve yalnız kaybetti; sıra yeterince obaya gelince han dokuzu birleştirdi. **Baikhan'ın hiç
  asimile edilememesinin sebebi bu savaştır**, inancın gücü değil.
  [Karar] **Ordular şehirlere değil ambarlara saldırdı.** İmparatorluk ordusu yerinden kalkamadı, çünkü kendini
  besleyemiyordu. Bugünün Vadi savaşları aynı şeyi tekrar ediyor (§1.2/1).
  [Karar] **Sargalak Yıkıntısı** (§11.1) bozkırdaki imparatorluk karakolu: kâtiplerin ve defterlerin durduğu
  yer, obaların ilk akında yaktığı yer.
- **Büyük savaşın sonunda** Merigard'ın halkı sürülür, şehir yakılır.
  [Karar] **Kim yaktı:** herkes başkasını suçlar ve oyun hiçbirini doğrulamaz. Vaelghard göçebeleri suçlar;
  göçebeler açlıktan ayaklanan kendi halkını; Vadi, Vaelghard'ın ordusunu (başkenti yakıp Orvahel'i kurmak
  için). Hakikat: göçebe birliği şehri kuşattı, açlık kapıyı içeriden açtı, yangını kimin başlattığı bilinmiyor.
- **[Yazar, T7]** Dört kuleli tapınak yangından kalan tek yapıdır: **şehir genç, tapınak eski.**
- **[Yazar, onaylandı T8]** Son meydan muharebesi **Mühür Savaşı Ovası**'nda olur; düşen imparatorluk mühürleri
  bugün nadir "eski mühür" olarak elden ele geçer.
- **[Yazar]** Baikhan yolu bu güç sayesinde hiçbir zaman asimile edilemedi: asimilasyon savaşla kesildi.
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
| **Deli Kral Sarayı Yıkıntısı** (Vastrevar'ın doğusu) | Son imparatorun yazlık sarayı. Avlusunda iki kez ateş yakıldı: önce büyücüler, sonra savaşın sonunda kendini ölümsüz kılmaya çalışan imparatorun kendisi (§4.2). Halk yaklaşmaz: geceleri avluda kül kalktığı anlatılır. Vaelghard sarayı ne onarır ne yıkar. |
| **Velkrun Yıkıntısı** (Taşkök) | İmparatorluğun kereste ambarı; parçalanmada yakıldı. "Odun satılır, orman satılmaz" kuralının doğduğu yer (§10.6). |
| **Eski Darphane Yıkıntısı** (güney) | İmparatorluğun darphanesi; GG burada basıldı. Çöküşte kalıplar Orsolune'ye kaçırıldı. |
| **Sargalak Yıkıntısı** (bozkırın ortası) | İmparatorluk karakolu: bozkıra gönderilen kâtiplerin ve otlağı yazdıkları defterlerin durduğu yer. Obalar ilk akında yaktı; taşları yurt ocağı olarak taşındı. Göçebe savaşının başladığı yer (§4.3). |
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
- **2026-11-07, aynı gün iki düzeltme [Yazar]:** (1) göçebe savaşının sebebi **asimilasyondur** — imparatorluk
  boyları tek tek asimile etmeye çalıştı, boylar direndi, sonunda dokuz boy birleşip savaştı (benim "otlak
  bedeli ve kurak yıl" gerekçem düştü); (2) **deli imparator savaşın sonlarında kendini bir ayinle yakarak
  ölümsüz kılmaya çalıştı ve öldü** (benim "hastalığından bir yıl sonra öldü" satırım düştü).

**Kullanıcı tarafından geçersiz kılınan ve bu belgeden silinen satırlar** (bir daha kullanılmaz):
kıtlığın sebebi olarak "uzayan kış" ve "solgunluk"; "kıtlık imparatorluğun son yıllarında başladı";
"deli kral kıtlığı büyücülere yükledi" ve "deli kral son imparatordan önceki imparatordu"; "Baikhan gök,
Gokana toprak"; "Gelgit Kıyısı balıkçıların yurdudur"; "kaçak ihbarı itibar kazandırır/kaybettirir";
"doğuda da göçebeler var"; beş bölümlü senaryo/kampanya sistemi; batı denizlerinin "Uzun Deniz / Sabah Denizi"
adları (kanon: Ağıt Denizi, Gelgit Denizi); Vadi nehrinin "Vael Suyu" adı (kanon: Kemersu);
yol sunaklarının dörde indirilmesi (kanon: oyundaki on sunak kalır); göçebe savaşının sebebi olarak otlak
bedeli ve kurak yıl (kanon: asimilasyon); deli imparatorun hastalığından ölmesi (kanon: ölümsüzlük ayini).

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
~~~~

> **Bundan çıkarman gereken:** önerdiğin her olayın, kişinin ve sonucun hangi bölgede, kimin ağzından,
> hangi inançla olacağı. Oyun içi örnek metin yazarsan §14'teki sese uy ve asla anlatıcı olma.

### VERİ-6 · ÖLÇÜM RAPORLARI (oyunun gerçek davranışı)

Bunlar tahmin değil, simülatör çıktısıdır. Teşhisin (§A) bunlara dayanmak zorunda; bir sayıya dayanmayan
teşhis genel oyun tasarımı lafıdır.

### Kariyer

*Kariyer yayı: 3 politika × 8 kervan × 40 sefer*

```
── Wayborne kariyer simülasyonu (8 kervan × 40 sefer)
   Politika: pazarda al-sat, yalnızca gidilen hedefe kontrat,
   fazla parayı vagona ve kadroya yatır.
── Kariyer eğrisi · genişleyen politika (8 kervanın ortalaması)
   sefer │   kese  itibar  vagon  kadro  teslimat  şehir   borç   gün
       1 │    403       0      1      2         1      2    150    15
       5 │     29      -1      2      2         4      4     82    86
      10 │     46      -7      2      1         9      6    104   161
      20 │    -67      -5      3      1        18     10    156   294
      30 │   -150      -4      3      1        24     11    206   431
      40 │    -67      -3      3      1        33     13    147   521
   denge (Y-C24) · genişleyen: dertsiz sefer 42/320 (%13), en uzun sakin dizi 4
   kâr tavanı (P8) · genişleyen: kese ilk yarı ort. 42, son yarı ort. -88 (oran -2.06), tepe 1534
   tehdit kartı (Y-C15) evreye göre: erken 122 · orta 274 · geç 224
   kariyer boyunca: 1792 çekiliş, 66 farklı kart, tekrar oranı 27.15
OLCUM {"arcs":8,"cards_per_leg":5.6,"days_per_leg":13.04,"deaths_per_leg":0.056,"legs":320,"minutes_per_leg":9.78,"policy":"genişleyen"}
── Kariyer eğrisi · kontratçı politika (8 kervanın ortalaması)
   sefer │   kese  itibar  vagon  kadro  teslimat  şehir   borç   gün
       1 │    403       0      1      2         1      2    150    15
       5 │     29      -1      2      2         4      4     82    86
      10 │     30      -5      3      1         9      6    113   161
      20 │    -80      -5      3      1        18     10    155   303
      30 │    -71      -2      3      1        25     12    141   395
      40 │     -3      -1      3      1        33     14    111   486
   denge (Y-C24) · kontratçı: dertsiz sefer 47/320 (%15), en uzun sakin dizi 4
   kâr tavanı (P8) · kontratçı: kese ilk yarı ort. 33, son yarı ort. -52 (oran -1.56), tepe 1534
   tehdit kartı (Y-C15) evreye göre: erken 120 · orta 272 · geç 202
   kariyer boyunca: 1687 çekiliş, 66 farklı kart, tekrar oranı 25.56
OLCUM {"arcs":8,"cards_per_leg":5.27,"days_per_leg":12.17,"deaths_per_leg":0.031,"legs":320,"minutes_per_leg":9.13,"policy":"kontratçı"}
── Kariyer eğrisi · aşamalı politika (8 kervanın ortalaması)
   sefer │   kese  itibar  vagon  kadro  teslimat  şehir   borç   gün
       1 │    403       0      1      2         1      2    150    15
       5 │     29      -1      2      2         4      4     82    86
      10 │     30      -5      3      1         9      6    113   161
      20 │    -66      -4      3      1        18      9    155   298
      30 │   -123      -3      3      1        23     12    179   409
      40 │    -81      -5      3      1        31     13    147   510
   denge (Y-C24) · aşamalı: dertsiz sefer 46/320 (%14), en uzun sakin dizi 4
   kâr tavanı (P8) · aşamalı: kese ilk yarı ort. 33, son yarı ort. -74 (oran -2.25), tepe 1534
   tehdit kartı (Y-C15) evreye göre: erken 120 · orta 281 · geç 218
   kariyer boyunca: 1751 çekiliş, 65 farklı kart, tekrar oranı 26.94
OLCUM {"arcs":8,"cards_per_leg":5.47,"days_per_leg":12.76,"deaths_per_leg":0.044,"legs":320,"minutes_per_leg":9.57,"policy":"aşamalı"}
```

### Uzman

*Uzman denetimi: tutundurma, sistem, zanaat*

```
── Wayborne uzman değerlendirmesi (6 koşu × 40 sefer)
   Ölçülen şey vekil göstergelerdir; gerçek D1/D7 insan ister.
── A · Tutundurma Analisti
   İlk oturum hunisi (ilk 3 sefer, 6 koşu) - oyuncu neyi gördü:
     gerçek bir seçim          6/6 koşu
     görülmemiş bir yer        6/6 koşu
     ilk gerçek kayıp          6/6 koşu
     ilk dövüş                 4/6 koşu
     ilk oturumda kervan bitti 0/6 koşu  (erken bırakma riski)
   Seans şekli: sefer başına 14.3 oyun günü · koşu başına 40.0 sefer
   İçerik pisti: 8.5. seferde yeni kart oranı 0.5/sefer'in altına iniyor
     40 seferde katalogun %59'i görülüyor (101 kart var)
     çekilen kartların %74'i tekrar
   Bırakma noktası: hiçbir koşu bitmedi (40 sefer sınırına kadar)
   Geri dönme kancası (koşu bittiğinde açıkta kalan):
     görülmemiş yer 11.0 · bitmemiş kişi işi 2.2 · görülmemiş kart 41.2
   Boş tur: şehir ziyaretlerinin %43'inde alacak/yapacak bir şey yok
── B · Sistem Tasarımcısı
   Karar kalitesi (katalogun tamamı, 101 kart):
     tek seçenekli kart            3 (%3) - seçim değil, bildirim
     seçenekleri aynı etkiyi veren 2 (%2) - sahte seçim
     beceri kontrolü taşıyan       66 (%65)
   Ustalık eğrisi ve baskın strateji (aynı tohumlar, 6 koşu):
     acemi (rastgele seçer)    40.0 sefer ·  0.5 ölüm ·   -610 GG · 15.8 teslimat · %43 aç sefer
     dengeli (plan okur)       40.0 sefer ·  0.2 ölüm ·    -22 GG · 17.3 teslimat · %15 aç sefer
     açgözlü (altına koşar)    33.8 sefer ·  0.5 ölüm ·    177 GG · 10.7 teslimat · %14 aç sefer
     dayanıklılık farkı 6.2 sefer (acemi (rastgele seçer) önde) · kese farkı 788 GG
   Ekonomi: seferlerin %15'inde gereken erzak alınamıyor · iyi bir şey arası 40.4 gün
   Karar yoğunluğu: kart başına 2.35 açık seçenek · zorunlu kart oranı %3
── C · Zanaat Denetçisi: "bu oyun ne kadar dolgu?"
   Metin: 101 kart gövdesi, 101'i benzersiz (%100) · 1566 sözcük, 1029 farklı (çeşitlilik 0.66)
   Seçenek biçimi: 1 seçenek: 3 kart · 2 seçenek: 35 kart · 3 seçenek: 47 kart · 4 seçenek: 14 kart · 5 seçenek: 2 kart
   Etki dili: 31 farklı etki türü kullanılıyor · 207 sonuçtan %21'i yalnız sayı oynatıyor
     etkisiz sonuç (hiçbir şey olmaz) 0 (%0)
     adı/yeri anan sonuç 199 (%96) · yazısı olmayan 0 · çevrilmemiş 0
   Yazım izleri (101 kartta): üç'leme (a, b ve c) 2 · "sadece ... değil" 0 · "bir yandan ... öte yandan" 0 · uzun tire yığılması 0
   En sık açılış: "Yolun kenarında" ×4 · "Yolun ortasında" ×3 · "Yol kenarında" ×3
```

### Sefer

*Tek sefer ekonomisi ve olay dağılımı*

```
── Wayborne sefer simülasyonu (200 koşu × 3 tehlike seviyesi)
   (net = kontrat geliri − erzak − escort; ticaret kârı dahil değil)
  Tehlike %20
    net kazanç      ortalama    40.0 GG   (en kötü -204, en iyi 164)
    varış morali    ortalama    74.4
    moralin dibi    ortalama    73.7   (en kötü 8 · isyan eşiği 40)
    isyan eşiğine indi  %5.0 koşuda
    erzak           243 GG stoklandı · tükendi %24.5 koşuda
    vagon kaybı     ortalama    0.01
    teslim edilemeyen kontrat  0.26
    varışta stres   ortalama    25.1 · kırılma 0.07/sefer · toplam ayrılık 0
  Tehlike %40
    net kazanç      ortalama    12.8 GG   (en kötü -256, en iyi 164)
    varış morali    ortalama    71.2
    moralin dibi    ortalama    70.0   (en kötü 7 · isyan eşiği 40)
    isyan eşiğine indi  %9.5 koşuda
    erzak           243 GG stoklandı · tükendi %25.5 koşuda
    vagon kaybı     ortalama    0.03
    teslim edilemeyen kontrat  0.47
    varışta stres   ortalama    32.7 · kırılma 0.12/sefer · toplam ayrılık 0
  Tehlike %65
    net kazanç      ortalama   -76.9 GG   (en kötü -256, en iyi 152)
    varış morali    ortalama    58.6
    moralin dibi    ortalama    57.8   (en kötü 0 · isyan eşiği 40)
    isyan eşiğine indi  %21.0 koşuda
    erzak           243 GG stoklandı · tükendi %15.0 koşuda
    vagon kaybı     ortalama    0.03
    teslim edilemeyen kontrat  1.18
    varışta stres   ortalama    50.5 · kırılma 0.36/sefer · toplam ayrılık 0
── Olay ateşlenme sıklığı (600 koşu toplamı)
    evt_merchant_cold_feet          0  ⚠ hiç ateşlenmedi
    evt_merchant_grudge             0  ⚠ hiç ateşlenmedi
    evt_merchant_shares_bread       0  ⚠ hiç ateşlenmedi
    evt_river_ford                  0  ⚠ hiç ateşlenmedi
    evt_broken_outburst             0  ⚠ hiç ateşlenmedi
    evt_convoy_repaid               0  ⚠ hiç ateşlenmedi
    evt_convoy_search               0  ⚠ hiç ateşlenmedi
    evt_profiteer_recognized        0  ⚠ hiç ateşlenmedi
    evt_left_behind_return          0  ⚠ hiç ateşlenmedi
    evt_leave_the_wounded           0  ⚠ hiç ateşlenmedi
    evt_faction_split               0  ⚠ hiç ateşlenmedi
    evt_avucici_hand                0  ⚠ hiç ateşlenmedi
    evt_chief_returns               0  ⚠ hiç ateşlenmedi
    evt_place_village               0  ⚠ hiç ateşlenmedi
    evt_place_shrine                0  ⚠ hiç ateşlenmedi
    evt_place_ruin                  0  ⚠ hiç ateşlenmedi
    evt_cargo_seized                0  ⚠ hiç ateşlenmedi
    evt_hunger_riot                 0  ⚠ hiç ateşlenmedi
    evt_starving_roadside           0  ⚠ hiç ateşlenmedi
    evt_wagon_for_town              0  ⚠ hiç ateşlenmedi
    evt_fever_quarantine            0  ⚠ hiç ateşlenmedi
    evt_elder_burden                0  ⚠ hiç ateşlenmedi
    evt_faith_tribunal              0  ⚠ hiç ateşlenmedi
    evt_pilgrim_caravan             0  ⚠ hiç ateşlenmedi
    evt_duvenmor_quarrel            0  ⚠ hiç ateşlenmedi
    evt_serai_bandit                0  ⚠ hiç ateşlenmedi
    evt_serai_ruin                  0  ⚠ hiç ateşlenmedi
    evt_serai_open                  0  ⚠ hiç ateşlenmedi
    evt_untouched_village           0  ⚠ hiç ateşlenmedi
    evt_captive_strangers           0  ⚠ hiç ateşlenmedi
    evt_taken_captive               0  ⚠ hiç ateşlenmedi
    evt_bandit_tribute_toll         0  ⚠ hiç ateşlenmedi
    evt_place_mine                  0  ⚠ hiç ateşlenmedi
    evt_grave_on_the_road           0  ⚠ hiç ateşlenmedi
    evt_deserter_levy               0  ⚠ hiç ateşlenmedi
    evt_bailiffs_at_camp            0  ⚠ hiç ateşlenmedi
    evt_cargo_toll                  0  ⚠ hiç ateşlenmedi
    evt_grave_keeper                0  ⚠ hiç ateşlenmedi
    evt_grave_offering              0  ⚠ hiç ateşlenmedi
    evt_deserter_plea               0  ⚠ hiç ateşlenmedi
    evt_road_ultimatum              0  ⚠ hiç ateşlenmedi
    evt_deserter_search             0  ⚠ hiç ateşlenmedi
    evt_wanderer_revenge            0  ⚠ hiç ateşlenmedi
    evt_deserter_debt               0  ⚠ hiç ateşlenmedi
    evt_wolves_follow               0  ⚠ hiç ateşlenmedi
    evt_route_diversion             0  ⚠ hiç ateşlenmedi
    evt_creditor_rider              0  ⚠ hiç ateşlenmedi
    evt_wolf_pack                   0  ⚠ hiç ateşlenmedi
    evt_merchant_night_flight       0  ⚠ hiç ateşlenmedi
    evt_pilgrim_blessing            1
    evt_road_warden                 1
    evt_refugee_gratitude           2
    evt_culture_highland_challenge    3
    evt_failing_bridge              4
    evt_rival_slander               4
    evt_party_investigation         4
    evt_stowaway_repay              5
    evt_hidden_guide                5
    evt_culture_fisher_catch        5
    evt_culture_port_gossip         6
    evt_stress_brawl                6
    evt_mine_collapse               7
    evt_plague_outbreak_news        8
    evt_culture_valley_dispute      8
    evt_rogue_mage                  9
    evt_frontier_outpost            9
    evt_village_provisions          9
    evt_penitent_procession        10
    evt_roadside_shrine            11
    evt_trade_fair_news            11
    evt_wandering_players          12
    evt_bandit_tribute_zone_news   12
    evt_road_patrol                14
    evt_regional_war_news          15
    evt_mutiny                     17
    evt_landslide                  22
    evt_pilgrim_encounter          23
    evt_provision_raid             24
    evt_road_wanderer              25
    evt_military_convoy            26
    evt_forgotten_cache            26
    evt_carcass_on_road            28
    evt_refugee_column             29
    evt_stowaway                   30
    evt_scouted_pass               30
    evt_troubled_night             31
    evt_merchant_caravan           33
    evt_abandoned_wagon            34
    evt_hunting_trip               35
    evt_sick_merchant              37
    evt_spoiled_provisions         37
    evt_kin_encounter              38
    evt_storm                      38
    evt_broken_axle                42
    evt_customs_checkpoint         43
    evt_traveling_tinker           46
    evt_party_theft                50
    evt_guard_patrol               58
    evt_forage                     86
    evt_wild_animal               155
    evt_bandit_ambush             298
── Yol yönetmeni (Y-B02): 300 sefer x 30 gün, tehlike 0.4
   yönetmen kapalı: kart/gün 0.32, üç sessiz gün 0.101/gün, art arda iki ağır kart 0.072/kart
   yönetmen açık: kart/gün 0.38, üç sessiz gün 0.096/gün, art arda iki ağır kart 0.030/kart
── Savaş dengesi (kazanma oranı: parti büyüklüğü × yol tehlikesi)
   Hedef: yalnız yolcu sakin yolda zorlanmasın ama eşkıya kaynayan
   yolda gerçekten kaybedebilsin; dolu parti güçlü olsun, dokunulmaz olmasın.
    parti\tehlike   %20   %40   %65   %90 
    1 kişi           57%   57%   25%   25% 
    2 kişi          100%   67%   53%   53% 
    3 kişi          100%  100%   77%   77% 
    4 kişi          100%  100%   92%   92% 
── Bölge başına kazanma oranı (Y-C09/T16-08: bölgesel haydut kimlikleri;
   2 ve 3 kişilik parti, tehlike %40 ve %65; bölgesiz satır karşılaştırma)
    (bölgesiz)      67%   53%  100%   77% 
    vadi            82%   57%   95%   77% 
    imparatorluk    73%   42%   93%   72% 
    dag             47%   47%   87%   52% 
    sinir           57%   43%   95%   77% 
    guney           57%   48%   85%   67% 
    ahit            75%   40%   93%   73% 
    gocebe          62%   42%   97%   52% 
    dag_maden       52%   43%   95%   55% 
── Seviye dengesi (2 kişilik parti, tehlike %50, düşman da seviyeye göre büyür)
   Hedef: seviye 1 ~%%40-55, seviye 15 ~%%75-88 kazanmalı - Sekban/Kırıkçı/Kalem
   Efendisi katılımıyla dört sınıf da dönüşümlü test ediliyor.
    seviye  1: %43 kazanıyor (26/60)
    seviye  5: %65 kazanıyor (39/60)
    seviye 10: %68 kazanıyor (41/60)
    seviye 15: %73 kazanıyor (44/60)
── Ekipman etkisi (tehlike %50)
    donanımsız 1 kişi                      %63 kazanıyor (38/60)
    tam donanımlı (T3+yüzük+kolye) 1 kişi  %87 kazanıyor (52/60)
── Tek parça taraması (Y-C06; tehlike %50, donanımsızla aynı tohumlar; * huyuyla)
    donanımsız                     %63
    weapon_tier_3                  %80 (+17)
    weapon_tier_2                  %77 (+13)
    ring_marksman                  %75 (+12)
    ring_hawk *                    %75 (+12)
    weapon_spear                   %75 (+12)
    weapon_axe                     %75 (+12)
    armor_tier_3                   %72 (+8)
    weapon_old_blade               %72 (+8)
    amulet_ancient_eye             %70 (+7)
    amulet_bear_claw *             %70 (+7)
    ring_widow                     %70 (+7)
    ring_bloodstone                %70 (+7)
    ring_steady_hand *             %70 (+7)
    armor_lamellar *               %70 (+7)
    weapon_tier_1                  %70 (+7)
    amulet_wolf_skull              %68 (+5)
    amulet_bear_claw               %68 (+5)
    armor_lamellar                 %67 (+3)
    ring_salt_seal *               %67 (+3)
    ring_silent *                  %67 (+3)
    ring_hawk                      %65 (+2)
    ring_charmed                   %65 (+2)
    armor_tier_2                   %65 (+2)
    amulet_copper_coin *           %63 (+0)
    amulet_horse_hair *            %63 (+0)
    amulet_ash_locket              %63 (+0)
    amulet_wayfarer_stone *        %63 (+0)
    amulet_wayfarer_stone          %63 (+0)
    armor_tier_1                   %63 (+0)
    ring_salt_seal                 %63 (+0)
    ring_debtor                    %63 (+0)
    ring_gambler                   %63 (+0)
    ring_iron_band *               %63 (+0)
    armor_gambeson                 %63 (+0)
    ring_iron_band                 %63 (+0)
    armor_scale                    %63 (+0)
    ring_silent                    %62 (-2)
    ring_drowned                   %62 (-2)
    ring_steady_hand               %62 (-2)
    amulet_copper_coin             %62 (-2)
    amulet_wolf_fang               %62 (-2)
    amulet_salt_charm              %60 (-3)
    amulet_salt_charm *            %60 (-3)
    amulet_courage                 %58 (-5)
    amulet_horse_hair              %58 (-5)
    amulet_raven_feather *         %58 (-5)
    amulet_raven_feather           %58 (-5)
    amulet_ward                    %55 (-8)
── Beden etkisi (tehlike %50) - cinsiyet ve kilo birbirini yemeli
    kadın · orta  %55 kazanıyor (33/60)
    erkek · orta  %70 kazanıyor (42/60)
    kadın · ince  %47 kazanıyor (28/60)
    erkek · iri   %83 kazanıyor (50/60)
── İlerleme merdiveni (seviye teçhizatın kapısını açar, tehlike %65)
    seviye  1 + tier 1 teçhizat: %68 kazanıyor (41/60)
    seviye  3 + tier 2 teçhizat: %90 kazanıyor (54/60)
    seviye  6 + tier 3 teçhizat: %98 kazanıyor (59/60)
── Sükûnet: Karizma'nın savaştaki karşılığı (tehlike %50)
    sakin parti: Karizma  5 → %53   Karizma 10 → %53   Karizma 15 → %53   
    kırılmış parti: Karizma  5 → %53   Karizma 10 → %53   Karizma 15 → %53   
── Görev sağlık kontrolü (Sıra Neferi, seviye 1 ve 10)
    seviye 1 Sıra Neferi:
      Guard        çarpan 1.05 · indirim %2 · azaltma 0
      Scout        çarpan 1.00 · indirim %0 · azaltma 0
      Quartermaster çarpan 0.95 · indirim %0 · azaltma 0
      Wagoner      çarpan 1.00 · indirim %0 · azaltma 0
      Crier        çarpan 1.00 · indirim %0 · azaltma 0
      Herbalist    çarpan 0.95 · indirim %0 · azaltma 0
    seviye 10 Sıra Neferi:
      Guard        çarpan 1.38 · indirim %11 · azaltma 1
      Scout        çarpan 1.00 · indirim %0 · azaltma 0
      Quartermaster çarpan 0.95 · indirim %0 · azaltma 0
      Wagoner      çarpan 1.00 · indirim %0 · azaltma 0
      Crier        çarpan 1.00 · indirim %0 · azaltma 0
      Herbalist    çarpan 0.95 · indirim %0 · azaltma 0
```


> **Bundan çıkarman gereken:** oyunun bugün nerede tıkandığı. Birkaç satır özellikle dikkat ister —
> kadro sayısının seferler boyunca nasıl değiştiği, kesenin kariyer boyunca hangi yöne gittiği, içerik
> pistinin kaçıncı seferde tükendiği, hangi oyuncu profilinin daha uzun dayandığı ve "iyi bir şey arası"
> kaç gün olduğu. Bunların bir kısmı tasarım açığının doğrudan kanıtıdır.

### VERİ-7 · OYUNCU GÖZLEMİ (tek boş alan)

[[ Gerçek oyun oturumlarından notlar: nerede sıkıldı, nerede durdu, neyi anlamadı, ne hissetti.
Bu blok boş kalabilir; boşsa oyuncu davranışını VERİ-6'daki vekil göstergelerden çıkar ve bunu
§A'da varsayım olarak belirt. ]]

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
- ❌ **Sanat işi üretme.** Çizim, ikon, palet, sprite, animasyon üretimi senin işin değil; oyunun bütün
  görselleri elle çiziliyor ve ayrı bir programda yürüyor (714 kalem, ~2000 saat). Bir mekanik görünür
  olmak zorunda olduğu için (§1.4-A9) bir görsele ihtiyaç duyuyorsa, **yalnızca yönlendir**: "bu durum
  şu ekranda şöyle bir işaretle okunmalı" de, bir cümleyi geçme ve var olan görsel dilden iste
  (mürekkep kontur, az ton, tek sıcak kaynak ateş). Yeni görsel yükü getiren öneriler §H'de "sanat borcu"
  diye işaretlenmeli; bedeli ağırsa §I'ya düşer.

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