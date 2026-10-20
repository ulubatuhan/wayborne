# Yol Sahnesi: "Neden Oynanır?" Önerileri (teknik tasarım)

> **Doğrulama notu (2026-10-17):** Bu belgenin kod başvuruları kontrol edildi. Düzeltmeler ve öteki görevlerle (§11.1, §12.2, §10, §8) çapraz bağlantılar `../gorevler/10b_yol_deneyimi_onerileri.md` içinde, "Doğrulama ve düzeltmeler" bölümünde. Uygulamadan önce oku.


> **Not (2026-10-17, kullanıcı):** Wayborne bir **PC oyunu**. Web derlemesi yalnızca test için; Web performansı, Web paket boyutu ve Web VRAM sınırları **ölçüt değil**. Bu belgedeki Web gerekçeli maddeler PC açısından okunmalı; güncel öncelikler `../YAPILACAKLAR.md` dizininde.


**Tarih:** 2026-10-17
**Durum:** ÖNERİ. Hiçbir madde koda geçmedi. Kullanıcı onayı olmadan uygulanmaz.
**Kapsam:** Yol (kervan) sahnesinin, yani `road_journey.gd` ekranının, yürümenin ötesinde oyuncuya vereceği sebepler.
**Köken:** Kullanıcının "yolda yalnızca yürüyoruz, oyuncu bunu neden oynasın?" sorusu üzerine yapılan akademik tarama ve beyin fırtınası. Fikirlerden **#18 (hayalet kervanlar)** ve **#20 (yaşlanan lider)** kullanıcı tarafından elendi, bu belgede **yok**. Numaralar beyin fırtınasındaki numaralarla aynı tutuldu.

> Bu belge `YAPILACAKLAR.md` içindeki işlerden bağımsız bir **ek öneri** listesidir. Oraya §10 olarak bağlanmıştır.

---

## İçindekiler
1. [Neden bu belge: teşhis](#1-neden-bu-belge-teşhis)
2. [Akademik zemin (kısa)](#2-akademik-zemin-kısa)
3. [Tasarım sınırları (CLAUDE.md ile uyum)](#3-tasarım-sınırları-claudemd-ile-uyum)
4. [Ortak altyapı (önce bu)](#4-ortak-altyapı-önce-bu)
5. [Madde madde teknik tasarım](#5-madde-madde-teknik-tasarım)
   - A. İnsanlar: #1, #2, #3, #4
   - B. Hafıza: #5, #6, #7, #8, #19
   - C. Merak: #9, #10, #11, #22
   - D. Töre ve ifade: #12, #13, #14
   - E. Risk ve ritim: #15, #16, #17, #21
6. [Yeni EventCondition anahtarları ve EventEffect türleri](#6-yeni-eventcondition-anahtarları-ve-eventeffect-türleri)
7. [Kayıt, yerelleştirme, test, performans](#7-kayıt-yerelleştirme-test-performans)
8. [Uygulama sırası ve boyutlar](#8-uygulama-sırası-ve-boyutlar)
9. [Başarı ölçütleri](#9-başarı-ölçütleri)
10. [Doğrulanması gereken varsayımlar ve açık sorular](#10-doğrulanması-gereken-varsayımlar-ve-açık-sorular)
11. [Kaynaklar](#11-kaynaklar)

---

## 1. Neden bu belge: teşhis

Yolda bugün şunlar var: tempo (Dur/Yavaş/Normal/Hızlı), liderin kolondaki yeri (ön/vagonlar/arka), üç tür işaret (`RoadSignals`), kamp, sofra, geri dönüş, günde bir olay kartı.

Bunların hepsi **karar**, ama kararların **duygusal karşılığı** zayıf:

- **Kişiler görünmüyor, sayılar görünüyor.** Moral/stres/takat şişe ve leke olarak çiziliyor. Yoldaşın yüzü, sesi, ilişkisi yok. Oyunun tezi ("konu kervan değil, onu çeken insanlar") yolda sahnelenmiyor.
- **Yol hafızasız.** Kaybettiğin kişi, vagon, geçtiğin yer yolda iz bırakmıyor. Aynı rotayı ikinci kez yürümek ilkinden farksız.
- **Merak edilecek soru yok.** İşaretler ya "çöz" ya "ihmal et". Hiçbiri "bu ne?" sorusu sormuyor.
- **Oyuncunun kimliği yolda yok.** Kervan adı, kuşak, değerler yolda görünmüyor.

Bu belgenin önerileri yeni bir "sistem" eklemek yerine, **var olan sistemleri yolda görünür ve hissedilir yapmak** üzerine kurulu.

---

## 2. Akademik zemin (kısa)

Tam liste ve bağlantılar §11'de. Her maddenin hangi ihtiyaca/estetiğe hizmet ettiği ilgili bölümde kısaca belirtilir.

| Kavram | Kaynak | Bu belgedeki maddeler |
|---|---|---|
| Özerklik, yetkinlik, ilişkililik (SDT, PENS) | Ryan, Rigby, Przybylski | #1–#4 (ilişkililik), #12, #15, #16 (özerklik), #22 (yetkinlik) |
| Merak = bilgi boşluğu | Loewenstein; To ve ark. (oyun uyarlaması) | #9, #10, #11, #22 |
| Belirsizlik türleri (performans, analitik, anlatısal beklenti) | Costikyan | #9, #17 |
| Anlatı mimarisi: çağrıştırılan, sahnelenen, gömülü, ortaya çıkan | Jenkins | #5, #6, #8, #19 |
| Dört eğlence anahtarı (kolay, zor, insan, ciddi) | Lazzaro | #1–#4 (insan), #5–#7 (ciddi) |
| Deneyim önce, mekanik sonra | MDA (Hunicke, LeBlanc, Zubek) | Tüm belge |
| Yavaşlık estetiği ve "anlatısız yürüyüş sıkar" uyarısı | Navarro-Remesal; yürüme oyunu incelemeleri | #1–#10 |
| Prosedürel retorik | Bogost | #12, #21 |
| Başarısızlık paradoksu | Juul | #5, #8, #16, #21 |
| Hikâye üreten sistemler | Sylvester | #17 |

**Doğrulama notu:** Aramada Schell'in mercekleri, Salen & Zimmerman'ın "anlamlı oyun" tanımı ve Koster doğrulanamadı. Bu belge bunlara **dayanmıyor**.

---

## 3. Tasarım sınırları (CLAUDE.md ile uyum)

Her maddenin geçmesi gereken kapılar. Bir madde bunlardan birini bozuyorsa belgede açıkça işaretlenmiştir.

1. **Yeni sistem icat etme.** Etki mevcut kollardan geçer: moral, stres, erzak, vagon hasarı, rota tehlikesi, itibar, takat, grievance, ledger, bayraklar. (Road Layer Rules, kültür perklerinin kuralı.)
2. **Girdi bir karardır.** Karar taşımayan girdi otomatik olur; her karar görünür bir denetime sahip olur, tuş yalnızca kısayoldur. (Road Movement Rules.)
3. **Yolda dikkat sonludur.** Bir ödül yalnızca kendi bölgesinde kazanılır (ön/vagonlar/arka). Yeni mekanikler bu dengeyi bozmamalı: kimseye üç bölgeyi birden ödüllendiren bir yer verilmemeli.
4. **Modal olma.** Yol "kaydırılan metin sütunu" olmaktan çıkarıldı. Yeni içerik ekranı yutmamalı; mümkünse baloncuk, ikon, kısa satır. Modal kart yalnızca gerçek karar anlarında. (Road Screen Layout Rules.)
5. **Kervan yok olmaz; olay sonucu öldürmez.** Ölümün iki kapısı var: savaş ve açlık (`resolve_deaths`). Hiçbir yeni olay/etki doğrudan öldürmez. Son vagon kaybedilmez.
6. **Planlayıcı sözü: "doğru stoklarsan aç kalmazsın."** Yolun gün sayısını zorunlu olarak uzatan bir mekanik, `RouteWeather.forecast_extra_days()` rezervine katılmadıkça **yasak**. Gün sayısını kısaltan ya da oyuncunun gönüllü olarak harcadığı süre serbest.
7. **Tohumdan hesapla, saklama (arazi/hava).** Yeni yol verisi arazi gibi tohumdan türetilebiliyorsa saklanmaz; oyuncu eylemlerinden doğan veri (mezar, yaş) **saklanır**.
8. **Her yeni alan ya kayıtlı ya geçici.** `test_memory.gd::_test_every_persistent_field_is_saved` bunu zorluyor.
9. **Her metin çeviri anahtarı.** Çalışma anında birleştirilmiş anahtar yok; `test_localization.gd` sabit metin taraması var.
10. **İsim kuralı (kullanıcı kararı, bkz. `YAPILACAKLAR.md` §0):** yasaklı terimler dosyalarda geçmeyecek. Yeni adlar başka eserlerden/gerçek tarihten alınmayacak; gerçek dini figür/yapı adı olmayacak. Bu belgedeki tüm yeni adlar özgündür.
11. **Repoya model kimliği yazılmaz.** Ücretli görsel/ses üretimi için önceden maliyet söylenir ve onay istenir.
12. **Ortak kütüphaneleri çoğaltma.** `KOD_DENETIMI.md` §3-4'te tekrar eden yardımcılar listelendi (`_clear_children` 8 kopya, doku yükleyici 5 kopya). Yeni UI kodu bunları çoğaltmamalı.

---

## 4. Ortak altyapı (önce bu)

Birçok madde aynı birkaç parçaya ihtiyaç duyuyor. Bunlar önce ve bir kez yapılmalı; yoksa her madde kendi kopyasını yazar.

### 4.1 Figür → karakter eşlemesi (`RoadCaravan`)

**Sorun:** `road_caravan.gd` `_party_figures: Array[WalkFigure]` tutuyor, ama hangi figürün hangi `CharacterData` olduğunu **saklamıyor** (`_make_figure(..., character)` yalnızca kıyafet için okuyor). Tayfa figürleri `null` karakterle yaratılıyor.

**Öneri:**
```gdscript
# road_caravan.gd
var _figure_character: Dictionary = {}   # WalkFigure -> CharacterData (tayfa: null)
func get_character_of(figure: WalkFigure) -> CharacterData
func get_figure_of(character: CharacterData) -> WalkFigure
func companions_near(offset_px: float, radius_px: float) -> Array[CharacterData]
func get_column_position_ratio(character: CharacterData) -> float   # 0 ön, 1 arka
```
- `companions_near`, liderin kolon konumuna (`_leader_offset`) en yakın figürleri döndürür. Yarıçap `get_person_height() * 0.9` civarı (başlangıç değeri, ölçülecek).
- `get_column_position_ratio` `RoadAttention.zone_for()` ile aynı ölçüyü kullanır; **sohbetin dikkat bölgesini de belirlemesi** bu sayede bedava gelir (parti üyeleri vagonların arasına serpiştirilmiş, bkz. `road_caravan.gd:1408-1415`).
- Tayfa (isimli, `crew_names` var) için v2: figür indeksi → `crew_names[index]`. v1 yalnızca parti.

### 4.2 Konuşma baloncuğu (`RoadBalloon`)

- Yeni `Control`, `scripts/ui/road_balloon.gd`. `mouse_filter = IGNORE`.
- Konum: ilgili `WalkFigure`'ın başının üstü; yakınlaştırma (`ZOOM_MIN..ZOOM_MAX`) ve ölçek (`get_column_scale()`) ile birlikte ölçeklenir.
- Boyut: tek ya da iki satır, tahmini ≤ 90 karakter. Ekranın yarısını **yemez** (madde 4 sınırı).
- Süre: ~4 s gerçek zaman (oyun zamanı değil; 3x'te okunabilsin). Hız ≥ 1.5x iken yeni baloncuk açılmaz, **günlük satırına düşer** (kaybolmaz).
- Her baloncuk bir **günlük satırı** da yazar (`_add_log`), ve gerekirse Waybook'ta kişinin sayfasına.
- Aynı anda en fazla 2 baloncuk.
- Katman: `_hud` altındaki yeni `_balloon_layer`; kervan düğümlerinin üstünde, HUD şeritlerinin altında. `_build_world_layer()`'daki `MarginContainer` kuralına uy (çapa ön ayarı tuzağı, Art Rules).
- Gece/yakınlaştırma testleri için `tests/screenshot_road_balloon.gd` (resim, test değil).

### 4.3 `RoadChatter` (UI'sız çekirdek)

`RoadSignals`/`RoadAttention` ile aynı kalıpta, **sahne ağacından bağımsız** `RefCounted`:

```gdscript
class_name RoadChatter
extends RefCounted

# Bir kişi için bir replik seçer. Dönen: {key, topic, mood, unlocks_flag, rapport_delta}
static func pick(character: CharacterData, context: Dictionary,
		rng: RandomNumberGenerator) -> Dictionary
```
Öncelik sırası (ilk eşleşen kazanır, her biri kendi anahtar tablosundan):
1. En yüksek `grievance` (`get_top_grievance()`): `unfed`, `benched`, `witnessed_death`, `passed_over`.
2. Stres eşiği aşıldı / olumsuz huy (`trait_ids`, `is_positive == false`).
3. Geçmiş (bkz. 4.4 `backstory_id`).
4. Görev (`duty_id`: Muhafız, İzci, Levazımcı, Arabacı, Tellal, Otacı).
5. Kültür (`culture_id`).
6. Ortam: hava (`RouteWeather`), biyom (`RouteTerrain.biome_at`), durak, saat/evre.
7. Genel.

- Her kişinin `last_chat_day` / `last_topic` alanı var; aynı konu 3 gün tekrarlanmaz.
- Anahtar tabloları **GDScript sabitlerinde** (`const LINES_GRIEVANCE: Dictionary = {"unfed": [...]}`), metinler CSV'de. "Tam yazılıyor, çalışma anında birleştirilmiyor" kuralı (Localization Rules) gereği anahtarlar tek tek yazılır. Tahmini ilk paket: ~120 replik (tr + en).
- Dillerden yalnız tr/en dolu olacak, diğerleri CSV'de boş (mevcut desen).

### 4.4 Yoldaşın geçmişi (`backstory_id`) ve bağ (`rapport`)

`CharacterData` bugün geçmiş/neden tutmuyor. `RecruitCatalog` adaylarının **neden** geldiği yok. `CLAUDE.md` Ana Hedefler'de zaten "Yoldaş bulmak zor olmalı… her adayın **neden** geldiği bir satırla söylenir" hedefi var. Bu belge o hedefle **birleşir**.

```gdscript
# character_data.gd
const BACKSTORY_DEBTOR := "debtor"      # borçlu
const BACKSTORY_EXILE := "exile"        # sürgün
const BACKSTORY_WIDOW := "widow"        # dul
const BACKSTORY_FUGITIVE := "fugitive"  # kaçak
const BACKSTORY_HUNGRY := "hungry"      # aç
const BACKSTORY_KEYS := [...]
var backstory_id: String = ""
var rapport: int = 0              # 0..5; lider ile bağ
var last_chat_day: int = -99
var last_chat_topic: String = ""
```
- **Kayıt:** `to_dict`/`from_dict` genişler. Eski kayıtlarda `backstory_id` boşsa **`character_id` hash'inden deterministik atanır** (yeniden zar atılmaz; "kayıt dünyayı yeniden zar atmaz" iddiası, `test_memory.gd`).
- `SAVE_VERSION` artırmaya gerek yok: eklenen alanlar `.get` varsayılanıyla okunuyor (`_migrate_save` notu: "yalnızca alan eklendi, dönüştürme gerekmiyor"). Yalnızca bir alanın **anlamı** değişirse sürüm artar.
- `RecruitCatalog` aday üretiminde `backstory_id` seçilir; ağırlıklar `WorldEvents`'e (kıtlık → aç/borçlu çoğalır) bağlanabilir (Ana Hedefler'deki hedefle uyumlu, ayrı iş).
- **Rapport kapıları:** 1 = tanıştık, 3 = güven, 5 = sır. Kazanma: sohbet (+1, günde en fazla 1 kişi başına), kamp hikâyesi dinlemek (+1), yanında yürümek (zamanla, bkz. #1), ortak savaştan sağ çıkmak (+1). Kaybetme: grievance artışı (−1), `passed_over` (−2).

### 4.5 Ledger'a yeni satır türleri

`CaravanLedger.KIND_*` bugün: `joined, departed, died, led, founder`. Önerilen eklemeler:

| Tür | Anlamı | Çizili mi | Sayaçlara girer mi |
|---|---|---|---|
| `KIND_STORY` | Kamp hikâyesi anlatıldı (#3) | Hayır | Hayır |
| `KIND_DIARY` | Günün cümlesi (#7) | Hayır | Hayır |
| `KIND_CODE` | Töre benimsendi/bırakıldı (#12) | Hayır | Hayır |
| `KIND_VERDICT` | Kervan mahkemesi kararı (#21) | Hayır | Hayır |
| `KIND_MEMORIAL` | Yolda anıt dikildi (#5, #8) | Hayır | Hayır |

- `KIND_FOUNDER` deseni: **sayaçlara girmez**. `build_event_context()` yalnızca `KIND_DIED`/`KIND_DEPARTED` sayıyor; yeni türler bunları şişirmemeli.
- `KIND_LABEL_KEYS` ve `STRUCK_KINDS` güncellenir. `describe()` yeni türlerde `cause` alanını **kendi metin anahtarı** olarak kullanır.
- `record()` imzasına isteğe bağlı `text: String = ""` (serbest metin, #7) ve `extra: Dictionary = {}` eklenir. Girdi sözlük tabanlı olduğu için eski kayıtlar bozulmaz.
- `struck_line.gd` ve Waybook "defter" sayfası (`waybook_panel.gd::_fill_entries`) yeni türleri çizmeyi bilmeli.

### 4.6 `GameSession` genişlemeleri (hepsi kayıtlı)

```gdscript
var road_memorials: Array[Dictionary] = []      # #5, #6, #8
var field_notes: Dictionary = {}                 # #10: id -> {first_day, count, route_key}
var route_memory: Dictionary = {}                # #19: route_key -> {trips, last_day, ...}
var code_tenets: Array[String] = []              # #12
var bonds: Dictionary = {}                       # #2: "idA|idB" -> int
var banner: Dictionary = {}                      # #13
var storyteller_id: String = "balanced"          # #17
```
Hepsi `to_save_dict()`'e ve `load_from_dict()`'e girer; `test_memory.gd::_test_every_persistent_field_is_saved` listesine eklenir.

### 4.7 Yol anı sistemi: `RoadBeat` (isteğe bağlı birleştirme)

Baloncuk, kamp hikâyesi, anıt okuma, işaret açığa çıkması aynı soruyu soruyor: *"şimdi oyuncunun dikkatini küçük bir şeye çekebilir miyim?"* Her biri ayrı ayrı yapılırsa aynı karede üç şey patlar.

- `RoadBeat` (RefCounted, UI'sız): bir **kuyruk + soğuma** sağlar. `request(kind, priority, payload)`; kuyruk tek seferde yalnızca bir baloncuk/hatırlatma gösterir; açık modal kart varken beklemeye alır; zaman hızına duyarlıdır.
- Bu, `_can_time_flow()` mantığıyla (kart açıkken zaman durur) uyumlu çalışmalı.
- Önerilir ama **zorunlu değil**; basit ilk sürüm `RoadBalloon` içinde en fazla 2 baloncuk sınırı ile de çalışır.

---

## 5. Madde madde teknik tasarım

Her maddede: **Amaç → Mevcut yapıya bağlanış → Teknik tasarım → Sınır kapıları → Test → Boyut/Risk.**

Boyutlar: **S** (≈1-2 gün), **M** (≈3-5 gün), **L** (≈1-2 hafta), **XL** (2 hafta+). Bunlar kaba tahmindir, sanat/ses hariçtir.

---

### A. İNSANLAR

#### #1 Yanına yürü, konuş

**Amaç:** Yürümeyi "yoldaşlarla geçirilen zaman" yapmak. Liderin kolondaki yeri zaten tek doğrudan oyuncu girdisi; ona **anlam** vermek. SDT ilişkililik ihtiyacı (en az çalışılan, en boş alan).

**Mevcut yapı:** `RoadCaravan.set_leader_offset`, `RoadAttention.zone_for`, `_party_figures`, `CharacterData.grievances`, `NpcDisposition`, `CaravanLedger`.

**Teknik tasarım:**
- `road_journey.gd`'de `_process`/`_advance_position` içinde (kare başı string üretmeden, bkz. KOD_DENETIMI O-2): `RoadCaravan.companions_near(_leader_offset, radius)`.
- **Bekleme (dwell) mantığı:** lider bir yoldaşın yarıçapında ≥ **1.2 s (gerçek zaman)** kalırsa tetik. Tıklama gerekmez; "yanında yürümek" zaten karardır. Dokunmatikte mevcut "dokun/tıkla, lider oraya yürür" davranışı yeter.
- Tetik: `RoadChatter.pick(character, build_event_context(), rng)` → `RoadBalloon.show(figure, text_key)` + günlük satırı.
- **Soğuma:** kişi başına günde 1 konu; kişi başına `last_chat_day`.
- **Etki (mevcut kollar, küçük):**
  - `rapport += 1` (günde en fazla +1 kişi başına).
  - İlk karşılaşmada (`rapport` 0→1) yoldaşın geçmişi (`backstory_id`) tek satırla öğrenilir.
  - Yoldaşın **en üst grievance'ı** konuşulduysa ve lider uygun cevabı seçtiyse (v2, bkz. aşağı) o grievance 1 azalır.
- **v2: tek seçenekli kısa cevap.** Baloncukta iki küçük düğme ("Dinle" / "Geç") çıkabilir. "Dinle" 0.25 saat harcar (`consume_hours`), "Geç" hiçbir şey. Bu, girdiye gerçek bir maliyet/karar ekler (dikkat + zaman).
- **Dikkat bölgesiyle çatışma (kasıtlı gerilim):** Yoldaş vagonların arasında/arkasında yürüyorsa onunla konuşmak lideri o bölgeye taşır; ön bölgedeki erken keşif ödülü bu sırada kaybolur. "Dikkat sonludur" ilkesini **bedavaya** korur.
- 3x hızda baloncuk açılmaz (4.2); satır günlüğe düşer.

**Sınır kapıları:** 1 ✓ (yeni sistem yok), 2 ✓ (yürüme girdisi), 3 ✓ (bölge gerilimi), 4 ✓ (baloncuk). Rapport yeni bir sayaçtır ama `grievance`/`stress` ile aynı kategoride (kişi alanı).

**Yerelleştirme:** `CHAT_<KONU>_<n>` anahtarları (ui.csv ya da yeni `chat.csv`; locale dosyası bölünmesi kararı ayrı).

**Test:** `tests/test_road_chatter.gd`: seçim önceliği, soğuma, aynı konunun tekrarlanmaması, tohumlu belirlenimcilik, `rapport` sınırları, kayıt-yükleme. `test_touch_parity.gd` ile dokunmatik yolu.

**Boyut/Risk:** **M**. Risk: replik yazımı hacmi; tekrar hissi. Önlem: konu önceliği + 3 günlük konu soğuması + bağlam (hava, durak).

---

#### #2 Yoldaşlar birbirine konuşur; ilişki görünür

**Amaç:** Grievance ve bağların **yolda görünmesi**. "Dağılmış kadro" yalnızca sayı değil, görüntü olsun.

**Mevcut yapı:** `road_caravan.gd` `MAX_ABREAST = 2` (partiyi ikişerli yürütüyor, satır 1464-1475), `GAP_TIGHT/NORMAL/WAGONS`, `CharacterData.grievances`, kültür ve huylar, `AFFLICTION_SPAWN_BONUS` deseni.

**Teknik tasarım:**
- **Bağ verisi:** `CompanionBonds` (RefCounted, UI'sız). Anahtar `"idA|idB"` (sıralı). Değer −3…+3.
  - Başlangıç: aynı kültür +1; `reassuring` huy sahibi +1 komşularına; `off_putting` −1.
  - Artış: ortak savaştan sağ çıkma +1; birlikte kamp (`CAMP_HOURS` tamam) +0.5 (yuvarlama için sayaç); birlikte `passed_over` mağduru olmak +1 (ortak dert).
  - Düşüş: biri diğerinin `unfed` nedeniyse −1; `passed_over`'ı kazanan ile kaybeden −2; bir tarafın `thief` mizacı ortaya çıkması (#21).
  - Kayıt: `GameSession.bonds`, kişi ayrılınca/ölünce ilgili satırlar **silinmez**, çizili kalır (ledger ruhu) ama sayaçta etkisiz.
- **Görsel (yolda):**
  - Bağ ≥ +2 olan çift, `road_caravan.gd` yerleşiminde **yan yana (abreast)** yürür; `_layout()` partiyi dizerken çiftleri yakınlaştırır. Dizi sırası savaş sırası olduğu için (CLAUDE.md: "kolonda gördüğün diziliş savaşta göreceğin diziliş") **sıra değişmez**, yalnızca aralık (gap) değişir.
  - Bağ ≤ −2 olan çift: aradaki boşluk `GAP_NORMAL × 1.6`, yüzler farklı yöne (`WalkFigure.set_facing`).
  - Çiftin üstünde küçük bir ikon: düğüm (bağ) ya da çatlak (gerilim). Mevcut ikon seti: `WaybookIcons`. Yeni ikon gerekirse prosedürel `ArtDraw` ile.
- **Çift sohbeti:** iki kişilik baloncuk (`RoadBalloon` iki figüre bağlanır). Lider yakınlarında değilse **yalnızca günlüğe satır**, böylece "tanık olmak" bir dikkat işi olur.
- **Mekanik karşılık (küçük, mevcut kollar):**
  - Bağ ≥ +2 çift **arka bölgede** yan yana yürüyorsa günlük stres −1 (yalnızca ikisi için; `REAR_STRESS_RELIEF_PER_DAY` kalıbı).
  - Bağ ≤ −2 çift için `RoadSignals` doğum oranı `+AFFLICTION_SPAWN_BONUS`'a benzer küçük bir pay (+%10) alır; gerilim görünür sürtüşme yaratır.
- Savaşa etkisi **bu belgenin kapsamı dışı** (savaş dengesi ayrı karar).

**Sınır kapıları:** 1 ✓, 3 ✓ (arka bölgede dikkat), "savaş sırası değişmez" ✓.

**Test:** `test_companion_bonds.gd`: artış/azalış kuralları, simetri, ayrılan kişi, kayıt-yükleme; `tests/test_caravan_layout.gd` genişletilir: çiftlerin aralığı, üst üste binmeme (mevcut "iki şey aynı formülle yerleştirilirse aynı şeydir" testi).

**Boyut/Risk:** **M-L**. Risk: yerleşim hesabı (`_layout`) karmaşık; kamp toplanma/ters dönüş (`begin_turn`) ile etkileşim. Önlem: bağ aralığı yalnızca **yürüme** hâlinde uygulanır, kamp/dönüşte devre dışı.

---

#### #3 Kamp ateşi hikâyesi

**Amaç:** Kampı "stres azaltma düğmesi" olmaktan çıkarıp **bir kişinin geçmişini açan sahne** yapmak. Lazzaro "ciddi eğlence" (oyuncuyu ve dünyayı değiştirmek), SDT ilişkililik.

**Mevcut yapı:** `GameSession.CAMP_HOURS = 8`, `CAMP_PROVISIONS_COST = 3`, `CAMP_STRESS_RELIEF = 8`; kamp hızı 0.5x; `RoadCaravan` toplanma ve oturma (`CAMPFIRE_SEATS`); `_open_meal_panel()` akşam sofrası zaten ateşi sahne olarak ödünç alıyor; olay motoru `triggered_only` + `UNLOCK_EVENT`.

**Teknik tasarım:**
- **Tetik:** kamp başladıktan ~3 oyun saati sonra (`_camp_ends_at_hours - 5.0`), `CampStory` bir anlatıcı seçer:
  - Aday: `rapport ≥ gate(bölüm)` ve o bölüm daha anlatılmamış. Ağırlık: bekleyen en uzun süre anlatmamış kişi + yüksek stres/grievance (derdi olan konuşur).
  - Gün başına en fazla **1** hikâye; her kamp garanti değil (≈%60), yoksa ritüel olur.
- **Biçim:** `GameEvent` altyapısı yeniden kullanılır: kategori `CHAIN`, `triggered_only = true`, id: `evt_camp_story_<geçmiş>_<bölüm>`. Böylece `EventChoice`, `EventEffect`, kilitli seçenek sebebi, zar vb. hazır. Ana yoldaki günlük `roll_for_day`'den **ayrı** bir giriş: `engine.fire(event_id)`.
- **Seçenekler (3):** *Dinle* (rapport +1, hikâye ledger'a), *Sen anlat* (lider kendi hikâyesini paylaşır, tüm parti stresi küçük düşer; Karizma/Bilgelik kontrolü), *Uykuya çekil* (kısa yol, etkisiz).
- **Bölümler:** 3 bölüm/geçmiş: (1) tanış, (2) güven, (3) sır. Sır bölümü **kalıcı bir etki** verir: `GRANT_TRAIT` (olumlu huy) ya da bir `grievance`ın silinmesi ya da kişisel bir görev bayrağı (`story_<id>_secret`) ile açılan `triggered_only` olay.
- **Ledger:** `KIND_STORY`, `cause = text_key`; kişinin sayfasında "hikâyesi" olarak görünür, **çizilmez**. Ayrılan/ölen birinin hikâyesi kalır.
- **Yan etki:** hikâyeyi anlatan için `session.apply_event_stress(-n)` **parti geneline** yazıyor (`EventEffect.Type.STRESS` kişi değil parti). Bu yüzden kişisel rahatlama için yeni bir `PERSON_STRESS` etki türü gerekli (bkz. §6).
- **Görsel:** anlatıcının figürü ateşin karşı koltuğunda öne çıkar (`CAMPFIRE_SEATS` ayrı koltuk), diğerlerine yüz çevirir. Yeni klip gerekmiyor; mevcut `WalkFigure` ayakta/oturma pozlarıyla yeterli.
- **Yazım hacmi:** 5 geçmiş × 3 bölüm × ~70 kelime × 2 dil = **15 hikâye**. Bu belgenin en pahalı içerik kalemi; tek bir yazara/geçişe bölünmeli.

**Sınır kapıları:** 1 ✓ (olay altyapısı), 4 ✓ (kısa kart, kamp zaten durgun), 5 ✓ (öldürmez). Kamp zamanını uzatmaz.

**Test:** seçim kuralları (rapport kapısı, günde 1), bir bölümün iki kez anlatılmaması, ledger satırı, kayıt-yükleme, `simulate_journeys.gd`'de dağılım.

**Boyut/Risk:** **L** (altyapı M, içerik L). Risk: yazım kalitesi; sürekli aynı ritim. Önlem: ilk sürümde yalnızca bölüm 1-2.

---

#### #4 Yoldaşlar kendi kararını verir (görünür özerk davranış)

**Amaç:** Kadronun yalnızca "kaynak" değil **özneler** olduğunu göstermek. Oyuncu bazen yalnızca **tanık** olur. Oyunun tezini (insanların aşınması) yolda canlı kılar.

**Mevcut yapı:** `RoadSignals` (şu an 3 anonim tür), `AFFLICTION_SPAWN_BONUS`, `CharacterData.stress`, `is_stressed`, olumsuz huylar, grievance, `KIND_DEPARTED`, `NpcDisposition`.

**Teknik tasarım:**
- Günlük `_run_day()` sonunda, sofradan **sonra**, `CompanionAction.roll(session, rng)`:
  - Aday: `stress ≥ eşik`, `grievance_total ≥ 2`, ya da olumsuz huy.
  - Olasılık: kişi başına ≤ %6/gün; günde toplam ≤ 1; `cooldown` 4 gün.
  - Eylemler (hepsi **görünür** ve **geri alınabilir**, öldürmez):
    - `shares_ration`: kendi payını tayfaya verir (erzak −1, o kişide açlık biriktirir; moral +).
    - `drifts_behind`: **adlı** geride kalan işareti (`RoadSignals.KIND_STRAGGLER`, bugün anonim). Arka bölgede ilgilenilmezse (`ESCALATE_HOURS` dolunca) kişi kervandan **ayrılır** (`KIND_DEPARTED`, sebep anahtarı), ölmez.
    - `prays`: ateş başında sessiz kalır (stres −2 kendisinde, moral +1 çevresinde).
    - `steals_bread`: gizlice erzak alır (kişi `thief` mizaçlıysa); fark etmek için Sezgi eşiği; fark edilirse #21'e kapı açılır.
    - `sings`: moral +1/gün, #14 ile bağ.
- **Gösterim:** baloncuk + günlük + ikon (HUD işaret ikonu zaten var, `_signal_icon`). Adlı işaret: `RoadSignals.open_signals` sözlüğüne `person_id` alanı eklenir.
- **Yan bulgu (KOD_DENETİMİ'ne eklenecek):** `RoadSignals` **kaydedilmiyor** (`to_dict` yok). Sefer ortası kayıt yüklenirse açık işaretler silinir. Adlı işaret eklenmeden önce `to_dict/from_dict` yazılmalı.
- **Oyuncu müdahalesi:** `drifts_behind` için mevcut çözüm (arka bölgeye yürü) aynı; yeni girdi yok.

**Sınır kapıları:** 3 ✓ (arka bölgede ilgilen), 5 ✓ (ayrılma ölüm değil, kervan asla boşalmaz: son parti üyesi ayrılamaz, `party.size() > 1` koşulu).

**Test:** olasılık/cooldown, günde ≤1, son üye ayrılamaz, `RoadSignals` kayıt-yükleme, adlı işaretin çözümü.

**Boyut/Risk:** **M**. Risk: "oyun beni cezalandırıyor" hissi. Önlem: her eylemin **önceden hissedilir** işaretleri (yüksek stres görünür, baloncukta dolaylı ima) ve her birinin telafisi.

---

### B. HAFIZA

#### #5 Ölüler yolda kalır (mezarlar)

**Amaç:** Oyunun tezini ("adın ölümden uzun yaşaması") **yolun kendisine** işlemek. Aynı rotayı ikinci kez yürümek **farklı** olsun. Jenkins "gömülü ve ortaya çıkan anlatı"; Lazzaro "ciddi eğlence".

**Mevcut yapı:**
- `RouteTerrain` tohumdan hesaplanır, saklanmaz; "aynı iki şehir hep aynı yol". Yani **anıt koordinatı kararlıdır**.
- `GameSession.resolve_deaths()` ölümün tek kapısı; ledger yazıyor (`cause`, `location`).
- `TravelBand.screen_position_for_day()` / `screen_x_for_day()` / `_draw_stops()` günden ekran konumuna tek kapı.
- `JourneyController.terrain_day()` kervanın arazideki gün konumu (geri dönüşte bile doğru).
- `road_journey.gd:2860` ölüm sonucunu işliyor; `_handle_death_outcome`.
- Waybook'ta "Düşenler" sayfası zaten planlı (`YAPILACAKLAR.md` §9.11).

**Veri:**
```gdscript
# GameSession.road_memorials: Array[Dictionary]
{
  "id": "mem_<serial>",
  "kind": "grave",                 # grave | wreck | cairn | note
  "route_key": "a|b",              # RouteConditions.route_key: YÖNSÜZ
  "terrain_day": 2.35,             # RouteTerrain günü (gün cinsinden, ondalık)
  "character_id": "...",           # ledger ile bağ
  "name": "Kara Ayşe",
  "generation": 2,
  "died_day": 41,                  # total_days_elapsed
  "cause_key": "LEDGER_CAUSE_WOLVES",
  "journeys_ago_decay": 0          # yaş için; sayaç değil, died_day'dan türetilir
}
```
- **`route_key` yönsüzdür** ve arazi de yönsüz kurulur (`RouteTerrain.build(route_key)`), yani A→B ve B→A seferinde aynı `terrain_day` ekseni kullanılır. Anıt `terrain_day()` ile yazılır ve **aynı** `screen_x_for_day()` ile çizilir; yön ne olursa tutarlıdır (bkz. §10, doğrulanacak).
- **Oluşturma:** `resolve_deaths(dead, cause_key, location_id, memorial_ctx := {})`. `memorial_ctx = {route_key, terrain_day}`: yol ekranı verir (`_route_key`, `_journey.terrain_day()`). Şehirde ya da yolsuz ölüm (yok) → anıt yok. Açlık ölümü de `_run_day` içinde, aynı bağlam.
- **Sınır:** rota başına ≤ **6** görünür anıt; daha eskiler tek bir "Adsız yığın" (`cairn`) olarak birleşir. Çizim maliyeti ve görsel gürültü sınırlı.
- **Yaşlanma (görsel):** `GameSession.total_days_elapsed - died_day` → yosun/solma alfa. Kuşak farkı (`lineage_generation - generation`) ≥ 2 ise taş "eski" çizilir. Saklanan ek sayaç yok.

**Çizim:**
- `TravelBand._draw_memorials()` (`_draw_stops` ile aynı desen: `screen_x_for_day`, `_ground_y_at_screen`, ufuk/paralaks tuzakları için `_draw_stops` yorumuna bak).
- **Sanat bağımlılığı:** `data/assets/props` içinde mezar/yığın/sancak **yok** (kontrol edildi: `signpost`, `well`, `torch`, `tent` var). v1: **prosedürel** (`ArtDraw` ile taş yığını, ahşap direk). v2: render edilmiş prop + `props.tres`. Görsel üretim maliyet/onay kuralına tabi.

**Etkileşim (dikkatin gerçek ödülü):**
- Kervan anıta ≤ 0.1 gün yaklaşınca, **lider ön bölgedeyse** ad + sebep okunur (günlük satırı + baloncuk). Vagonlar/arka bölgedeyse yalnızca siluet görülür. "Okumak için orada olmak" ilkesi.
- **Anma (opsiyonel karar):** HUD emir paneline bağlamsal "Anma" düğmesi (anıtın yanında beliriyor): 0.5 oyun saati; o kişiye `witnessed_death` grievance'ı olanlardan 1 tanesi silinir; stres −2 (kişisel, bkz. `PERSON_STRESS`). **Maliyeti zaman** (takvim ödemesi). Her anıt için yalnızca bir kez.
- **Olay bağı:** `EventResolver.stop_context()` kalıbıyla `near_memorial` bayrağı. `evt_grave_visit` (düşük taban ağırlık, ×8 değiştirici):
  - *Başında dur* (stres −, moral +).
  - *Taşı yenile* (erzak/zaman maliyeti, anıt "bakımlı" olur ve yaşlanmaz).
  - *Mezarı soy* (altın/eşya +, itibar −, `grave_robbed` bayrağı; sonradan bir kinci (`vengeful`) olayına bağlanabilir).
- **Planlayıcı:** `caravan_planner.gd` rota satırına "Yolda 2 anıt" (ve en yakın isimler). Gitmeden önce duygusal ağırlık.
- **Dünya haritası:** `world_map.gd` rota çizgisi üzerinde küçük mezar işareti; ipucu "Burada X yatıyor".
- **Waybook "Düşenler" sayfası** (§9.11) bu veriyi okur: rütbeli mezar işareti, kuşak.

**Sınır kapıları:** 7 ✓ (oyuncu eylemi → saklanır), 8 ✓, 5 ✓. Bir kervan ölümle yok olmadığı için anıt sayısı sınırsız büyümez (rota başına 6).

**Test:** `test_road_memorials.gd`: ölümde anıt oluşur, rota/gün doğru; kayıt-yükleme; şehir ölümü anıt üretmez; 6 sınırı ve birleştirme; `terrain_day` yön bağımsızlığı (tersine seferde aynı ekran konumu); `screenshot_memorials.gd`.

**Boyut/Risk:** **L**. Risk: yön/koordinat uyuşmazlığı (§10b), sanat. En yüksek duygusal getiri/maliyet oranı bu madde.

---

#### #6 Önceki liderin izi (dönüm taşı)

**Amaç:** Veraset anını **yolda** kalıcı kılmak. Kuşak sayacı yalnız sayı olmasın.

**Mevcut yapı:** `appoint_heir()`, `lineage_generation`, `SuccessionPanel`, `get_days_as_leader()`, `KIND_LED`.

**Tasarım:**
- Veraset (`appoint_heir`) anında, eski liderin son ölüm konumunda (#5 anıtı) `kind = "cairn"` + `note` alanı olarak **dönüm taşı** dikilir. İçerik: kervan adı, kuşak no, lider adı, hizmet günü, ve **#7'den son günlük cümlesi** varsa o.
- Yeni lider taşı ilk kez ön bölgede okuduğunda `leader_legacy_read` bayrağı: tek seferlik küçük moral (+4) ve baloncukta eski liderin sözü. Sayı abartılmamalı (yas, ödül değil).
- Lider ölümü yolda değilse (şehirde ayrılma) dönüm taşı **şehre varışta** yolun son noktasına dikilmez; yalnızca ledger/Waybook'ta kalır.
- Dünya haritasında kuşak başına bir işaret zinciri (rota üstünde "kuşak çizgisi").

**Test:** veraset sonrası anıt, `note` içeriği #7'den, tek seferlik okuma.

**Boyut/Risk:** **S** (#5 ve #7 hazırsa).

---

#### #7 Günün cümlesi (kervan defteri)

**Amaç:** Oyuncuya **ifade** alanı vermek ve kuşaklar arası aktarımı oyuncunun kendi sesiyle kurmak. Kayıp hissini veraset sahnesinde **okunur** yapmak.

**Mevcut yapı:** `CaravanLedger` (hiçbir satır silinmez), Waybook defter sayfası, `SuccessionPanel` ("hizmet günü", "savaşa alınmadı" gibi okunan tanıklık), koşu bitiş ekranı (`RUN_OVER_BOOK_HEIGHT`).

**Teknik tasarım:**
- **Tetik:** akşam evresi başlayınca (`JourneyClock.Phase.EVENING`) ya da kamp başlangıcında, **isteğe bağlı**, modal değil; HUD alt şeridinde küçük bir "Deftere yaz" düğmesi belirir, ertesi şafakta kaybolur. Zaman akmaya devam eder (okuma/yazma yalnızca bir arayüz işi; zamanı durdurmaz, `_can_time_flow` etkilenmez). İsteğe bağlı küçük bir kalem/defter ikonu.
- **Giriş iki kipli:**
  1. **Hazır cümleler (varsayılan):** o günün günlüğünden türetilmiş **3 hazır cümle**. Kategori: o günün en ağır olayı (savaş, kayıp, açlık, güzel ticaret, sessiz gün). Ton: *Umutlu / Sert / Yas*. Şablon anahtarları: `DIARY_<KATEGORİ>_<TON>_<n>`; yerleştirilen değişken yalnızca bir ad ya da sayı (`%s`).
  2. **Serbest metin (isteğe bağlı):** tek satır, **≤ 80 karakter**, `LineEdit`. Çeviri anahtarı **değil**; kullanıcı metni olarak saklanır. Yasak karakter/uzunluk temizliği, kayıt boyutu korunur. İlk sürümde kapalı bırakılabilir.
- **Kayıt:** `ledger.record(KIND_DIARY, author_name, day, generation, author_id, cause_key_or_empty, location_id)` ve `text` alanı. Günde en fazla 1.
- **Okuma noktaları:**
  - `SuccessionPanel`: devralan kişi "Son sözler" bölümünde düşen liderin **son 3 cümlesini** okur.
  - Koşu sonu ekranı (kimse kalmadı): defterin son sayfaları.
  - Waybook defter sayfası: tarih sırası, kuşak şeridi (`_ribbon(generation)` zaten var).
  - #6 dönüm taşı: son cümle.
- **Mekanik etki:** bilinçli olarak **yok denecek kadar az**: yazılan günde lider stresi −1 (ritüel). Asıl getiri anlam. "Yaz ve ödül al" döngüsüne dönüşmemeli (aşırı gerekçelendirme riski).

**Sınır kapıları:** 4 ✓ (modal değil), 9 ✓ (hazır cümleler çeviri anahtarı; serbest metin ayrı kategori ve test taramasından muaf), "yeni sistem yok" ✓ (ledger).

**Test:** günde 1 sınırı, kayıt-yükleme, `describe()` yeni tür, `SuccessionPanel` son sözler, boş defter.

**Boyut/Risk:** **M**. Risk: serbest metin içerik denetimi (yoksa riski düşük); bu yüzden v1 hazır cümleler.

---

#### #8 Yol enkazları

**Amaç:** Kaybedilen vagonun **yolda kalan bir iz** bırakması; geri dönüş/ikinci geçiş için gerekçe. Juul: kayıp ben'e ait olsun.

**Mevcut yapı:** `WAGON_LOSE`/`WAGON_DAMAGE` etkileri, `_apply_wagon_losses_to_ownership`, `owned_half_wagons`, TODO §9.10 "Kervan enkazı eşyası", planlı "Eşya bozulması" hedefi (Ana Hedefler).

**Teknik tasarım:**
- Vagon kaybında `road_memorials`'a `kind = "wreck"` ve **kaybedilen kargonun kısa dökümü** (`[{item_id, qty}]`, en fazla 6 satır) yazılır.
- Çizim: #5 ile aynı hat; kırık tekerlek, devrik brandası (prosedürel v1).
- **Arama (karar):** enkazın yanında bağlamsal "Enkazı ara" düğmesi, 1.5 saat. Sonuç: `died_day`'den geçen güne göre **bozulabilir mallar çürümüş**, dayanıklılar duruyor (planlı "Eşya bozulması" ile birleşince anlamlı; o gelene dek yalnızca yaş eşiği: >10 gün ise yarısı kayıp). Risk: eşkıya yuvası (`EVENT_ROAD_MARKER_KIND` "bandit" işareti, savaş).
- **Kurtarma:** yeterince sağlam enkaz **yarım vagon** (`owned_half_wagons`) olarak onarılıp geri alınabilir (onarım bedeli, saat). "Son vagon kaybedilmez" kuralı bozulmaz (bu bir kazanç).
- Enkaz sayısı sınırı #5 ile ortak (rota başına ≤ 6 anıt).

**Test:** kayıp → enkaz, arama sonuçları yaş eşiğine göre, kurtarma ile `owned_half_wagons` artışı.

**Boyut/Risk:** **M**. "Eşya bozulması" gelmeden yaş mantığı basit kalmalı.

---

#### #19 Yol seni hatırlar

**Amaç:** Aynı rotayı tekrar yürümenin **başka** bir deneyim olması: tanıdıklık ve tanınma. Bu, tekrar oynanabilirliğin ucuz bir kaynağı.

**Mevcut yapı:** `RouteConditions.route_key`, `known_routes`, taverna dedikodusu, itibar, `JourneyController.terrain_key`.

**Teknik tasarım:**
```gdscript
# GameSession.route_memory[route_key] = {"trips": 3, "last_day": 120, "deaths": 1, "wrecks": 0}
```
- Sefer bitince `trips += 1`; `deaths/wrecks` anıt sayılarından türetilebilir (saklamaya gerek yok; yalnız `trips`, `last_day`).
- **Aşinalık kademeleri:**
  - `trips ≥ 2` "Tanıdık": omen açığa çıkma süresi kısalır (#9), İzci olmadan da bir kademe fazla ipucu.
  - `trips ≥ 4` "Bildik yol": durak olaylarında tanıyan kişi varyantları (örn. mola yerinin sahibi adınla karşılar, `route_trips` koşulu), küçük fiyat indirimi (`market_pricing` zaten kültür çarpanı alıyor, yeni çarpan **eklenmez**, yalnızca metin/küçük sadakat).
  - **Çentik:** her 3 seferde yol kenarındaki yön işaretine (`signpost`) kervan adının çentiği (prosedürel/ikon).
- **İki ucu keskin:** tanınan kervan aynı rotada soyguncular için de ipucudur: `RouteConditions` eşkıya sıklığına **küçük** bir artış (aynı rotada üst üste ≥3 sefer ve yüksek kargo değeri). Bu "yeni ceza sistemi" **değil**, mevcut danger kolu (`headroom` kuralı).
- Planlayıcı rota satırı: "Bu yol: 4. sefer. Tanıdık."

**Sınır kapıları:** 1 ✓ (danger kolu, kayıt), 6 ✓ (süre uzatmaz), tohumdan arazi bozulmaz.

**Test:** sayaç, kayıt-yükleme, kademe sınırı, tehlike artışı kenetli (`DISRUPTION_CHANCE_CAP` mantığı).

**Boyut/Risk:** **S-M**.

---

### C. MERAK

#### #9 Ufukta bir şey var (belirsiz işaretler)

**Amaç:** Bilgi boşluğu merakı: oyuncu *gitmeden önce tahmin etsin*. Loewenstein'a göre merak, boşluğun **kapanabilir** olduğuna inanıldığında çalışır; bu yüzden her işaret kısmi bir ipucu verir.

**Mevcut yapı:** `RoadSignals` (3 tür, çözülebilir), `EVENT_ROAD_MARKER_KIND` + `RoadEncounter` (yola konmuş işaret), `FRONT_SPOT_BONUS_DAYS = 0.55`, İzci görevi (ücretsiz tehlike gösterimi), `best_perception` bağlamı.

**Teknik tasarım:**
- Üç yeni **omen** türü: `KIND_OMEN_LIGHT` (ufukta ışık/silüet), `KIND_OMEN_SMELL` (koku: duman, çürüme, tütsü), `KIND_OMEN_SOUND` (çan, davul, uluma).
- Her omen doğarken **gerçek kimliğini** (`truth`) tohumlu RNG ile seçer: örn. `merchant`, `pilgrim`, `ambush`, `wildlife`, `ruin`, `patrol`, `lost_child`, `shrine`, `nothing`. Dağılım `RoadStoryteller` profiline (#17) bağlı.
- **Üç netlik kademesi:**
  1. **Belirsiz:** "?" ikon + yön ve kategori ipucu ("ışık, yolun sağında").
  2. **Sezilmiş:** tür ailesi ("insan", "hayvan", "yapı").
  3. **Netleşmiş:** kimlik. Netleşince mevcut **bekleyen olay + yol işareti** hattına bağlanır: `truth → event_id`, `_pending_event` ve `RoadEncounter` figürü (mevcut `EVENT_ROAD_MARKER_KIND`).
- **Netleşme nasıl:** lider **ön bölgede** durdukça (ya da omen'e yaklaşıldıkça) kademeler zamanla açılır (varsayılan: her ≈ 2 oyun saati). İzci (`has_izci`) kademeyi 1 yukarıdan başlatır; yüksek Sezgi (`best_perception ≥ eşik`) ipucu satırı ekler; #19 "Tanıdık yol" bir kademe verir. İhmal edilirse omen **gece olayına** dönüşür ve `truth` yine uygulanır (pusu ise pusu). Yani merak ödülü **gerçek ve ihmalin bedeli gerçek**.
- **Kayıt:** `open_signals` zaten kaydedilmiyor (§10); omen için `to_dict/from_dict` **zorunlu**, `truth` tohum durumu olarak saklanır ("kayıt zar atmaz" iddiası).
- HUD: mevcut `_signal_icon` kademeye göre farklı doku (soru işareti → silüet → kimlik). Tooltip kısmi ipucu.
- `FRONT` bölgesinin ödülü zaten "karşılaşmayı erken gör"; omen bunu **bir sorudan bir cevaba** çevirir, yeni ödül icat etmez.

**Sınır kapıları:** 3 ✓ (ön bölge), 4 ✓ (modal değil), 5 ✓ (pusu yine savaş yoluyla).

**Test:** truth dağılımı tohumlu, kademe süreleri, İzci/Sezgi/aşinalık modifikatörleri, ihmalde `truth` uygulanması, kayıt-yükleme.

**Boyut/Risk:** **L**. Risk: 3x hızda anlaşılmaz; omen sayısını `MAX_OPEN = 2` ile paylaşmak gerek (toplam açık sınırı). 

---

#### #10 Yol notları (gördüklerin koleksiyonu)

**Amaç:** Keşfi **kalıcı** yapmak; "bu yolculukta ne gördüm?" sorusuna bir sayfa. Merak (Easy Fun) ve uzun vadeli hedef.

**Mevcut yapı:** `WaybookPanel` (sol/sağ sayfa, `_fill_entries`, `_fill_summary`), `CombatFigure.ARCHETYPES` (hayvan/haydut/muhafız/katip siluetleri), `WaybookIcons`, `RouteTerrain.get_stops()`, hava (`RouteWeather`), `known_routes`.

**Teknik tasarım:**
- `GameSession.field_notes[id] = {first_day, count, route_key}`.
- **Kayıt kaynakları (kancalar):**
  - Bir yol işareti (`RoadEncounter`) sunulduğunda: `note_id = "creature_<kind>"` / `"person_<kind>"`.
  - Kervan bir durağı geçerken (`terrain.get_stops()`): `stop_<tür>`.
  - Hava tipi ilk kez yaşandığında: `weather_<tip>`.
  - Omen `truth` açığa çıktığında (#9): `omen_<truth>`.
  - Vista (#22) ziyaret edildiğinde.
- **UI:** Waybook'ta yeni sekme/sayfa "Yol Notları". Kilitli girdi **siyah siluet + "?"**; açılmış girdi `CombatFigure` ya da durak ikonuyla çizilmiş, ilk görüldüğü gün ve rota. Biyom başına tamamlama yüzdesi.
- **Ödül (bilgi, güç değil):** biyom sayfası tamamlanınca o biyomda omen netleşme süresi kısalır (yeni sayı yok, #9'un parametresi). "Bilgi, bilgi ile ödüllendirilir."
- **Taverna köprüsü:** taverna zaten rota dedikodusu **satıyor**; defterdeki girdileri tavernacıya **anlatarak** küçük altın/dedikodu karşılığı (v2).

**Test:** kanca başına tek kayıt, tekrarın sayacı artırması, kayıt-yükleme, siluet/kilit durumu (`test_localization`'a dahil).

**Boyut/Risk:** **M**. Risk: Waybook sayfa düzeni (yeni sekme).

---

#### #11 Çatallar ve görünmeyen rota

**Amaç:** Yolun ortasında **tek, anlamlı bir rota kararı**. Belirsizlik (bilinmeyen patika) ve risk-ödül.

**Mevcut yapı:** `RouteTerrain.STOP_*` listesi, `terrain_key`, `JourneyController.start_leg/start_return_leg`, `divert_journey`/`turn_back`, `JourneyController.to_dict`, `known_routes`, İzci.

**Planlayıcı sözü (kapı 6) nedeniyle kritik kural:** çatal **yolu uzatamaz**. Yalnız **kısaltır** ya da gün sayısını **değiştirmez**; maliyeti risktir.

**Teknik tasarım:**
- Yeni durak türü `STOP_FORK = "fork"` (`_pick_stop` ağırlıkları, `STOP_CHANCE` içinde; başlangıç: yol başına en fazla 1).
- Kervan çatala varınca kart ("Yol ikiye ayrılıyor"):
  - **Bildik yol:** hiçbir şey değişmez.
  - **Kısa patika:** kalan yol −0.5…−1 gün (kenetli), **o parçanın** rota tehlikesi çarpanı ×1.4, parçada bir *keşif durağı* garantili. Bilinmeyen: patikanın ne olduğu, çatalda yalnızca ipucu (Sezgi/İzci ya da `field_notes`/`route_memory` bilgisi ile **önizleme**).
- **Saklama:** seçim `JourneyController`'a `fork_choice: String` olarak yazılır ve `to_dict()`'te taşınır. Arazi hâlâ tohumdan: patikanın kuyruk arazisi `hash("terrain|%s|fork|%s" % [route_key, choice])` ile **belirlenimci** kurulur (kayıt zar atmaz).
- `RouteTerrain.build_tail(key, from_day, variant)`: çatal gününden sonrasını yeniden kurar; gün sayısı kısalır → `journey_length_days` ve `terrain_days` güncellenir; `CaravanPlan` rezervi **fazla** kalır (güvenli yön).
- Görsel: yol kenarında `signpost`/iki yönlü direk prop'u (zaten var).
- Geri dönüş: kervan geri dönerse aynı çatalı ters yönde geçer; seçilmiş yol kalıcı.

**Test:** kısaltma kenetli, planlayıcı rezervi asla yetersiz kalmaz (`test_route_terrain.gd`'nin 80 kombinasyonu genişler), kayıt-yükleme, geri dönüşte aynı kuyruk.

**Boyut/Risk:** **L-XL** (arazi yeniden kurma + kayıt + planlayıcı etkileşimi). Bu listedeki en teknik riskli madde. Sonraya bırakılmalı.

---

#### #22 Tepeye çık: ufuk (vista)

**Amaç:** Yürümeyi **keşfin** parçası yapmak: yükseğe çıkıp yola ve ileriye bakmak. Yetkinlik ve merak ödülü; **estetik** bir an (yavaşlık estetiği, anlatısız uzun yürüyüşün sıkıcılığına karşı küçük bir ödül).

**Mevcut yapı:** `RouteTerrain.slope_at`, `pass` durağı, `TravelBand` yakınlaştırma (`ZOOM_MIN 0.7`), `biome_blend_at`, `FigureActions` (`dismount`/`climb_down` klipleri), uzak paralaks `PARALLAX_FAR`.

**Teknik tasarım:**
- `RouteTerrain.get_vistas()`: eğimi yüksek parçalarda / `pass` duraklarında tohumdan **vista noktaları** (`{day, kind}`), saklanmaz. Ziyaret edilmişler `field_notes`'a (#10) ve ayrı bir `visited_vistas` kümesine (rota başına) yazılır (kayıtlı).
- **Eylem:** lider vista noktasının yakınında (≤ 0.15 gün) ve **ön bölgedeyken** bağlamsal "Tepeye çık" düğmesi (HUD emir paneli).
- **Maliyet:** 1.5 oyun saati; kervan **Dur** temposuna geçer (takvim ödeniyor).
- **Sonuç:**
  1. **Kamera:** geçici olarak yakınlaştırma 0.55'e iner (`_zoom` kısa süre ZOOM_MIN altı), uzak paralaks sağa yavaşça kayar; ardından geri döner. Yeni sanat gerekmez.
  2. **Önizleme:** önümüzdeki ~1.5 günün araziyi/durağını ve (varsa) omen `truth` kademesini 1 yükseltir.
  3. **Gizli durak:** vista noktasında tohumlu %35 ihtimalle gizli bir durak/kaynak açılır (kaynak: erzak/otlak: `provisions +`, `forage` olayına bağlı); `field_notes` girdisi.
- Tekrar edilemez: aynı vista rota başına **bir kez**.
- Güvenlik: lider dağdayken kervanın saldırıya uğrama riski için mevcut `pending_event` dondurma mantığı yeter (kart açılırsa tırmanış kesilir).

**Test:** vista noktaları tohumlu belirlenimci, tek seferlik, saat maliyeti, ön bölge koşulu, kamera durumu geri döner.

**Boyut/Risk:** **M**. Düşük teknik risk, yüksek "an" değeri.

---

### D. TÖRE VE İFADE

#### #12 Kervan töresi

**Amaç:** Oyuncu **kurallarla** kim olduğunu söylesin. Prosedürel retorik: oyun, kurallarıyla bir dünya görüşü savunur. Ahlaki bir karar, sayısal bir bedeli de olsun.

**Mevcut yapı:** `MEAL_MODE_*` (sofra emri zaten kalıcı bir değerler kararı), `standing_camp_at_dusk`, `LEAVE_BEHIND` etkisi, grievance anahtarları, kültür perkleri, `RoadSignals.KIND_STRAGGLER`, `CampaignCatalog` hedefleri `EventCondition` okuyor.

**Tasarım:** Birbirini dışlayan **çiftler**; her çiftten biri seçilir. Her seçim yalnızca mevcut kollara dokunur (kapı 1).

| Çift | A | B |
|---|---|---|
| Geride kalan | **Beklenir:** `RoadSignals` geride kalan işareti `ESCALATE_HOURS +10`, kayıp riski azalır; bedel: işaret açıkken tempo ×0.95 | **Beklenmez:** işaret ihmalde kişi **sessizce** ayrılır (kartsız), ama o gün tempo bonusu ×1.03 ve diğerlerinde `unfed`/`benched` grievance birikmesi hafifler |
| Sofra | **Önce çalışan:** `MEAL_MODE_CREW_ONLY`'a eğilim; parti `unfed` grievance'ı kolay birikir | **Önce zayıf:** yaralı/aç önce; stres yüksek olanların sofrası korunur |
| Ganimet | **Eşit pay:** moral +, her savaş zaferinde küçük `morale` | **Liderin payı:** altın +%10, `benched`/`passed_over` grievance'ına yatkınlık |
| Yaralı | **Taşırız:** `LEAVE_BEHIND` seçeneği kilitli; tempo ×0.97 yaralı varken | **Bırakırız:** `LEAVE_BEHIND` açık; kalan moral düşer, `witnessed_death` kolay |
| Yabancı | **Kapı herkese:** `TRIGGER_RECRUIT` olayları artar, `thief` mizaç riski | **Yalnız bizden:** yolda aday azalır ama sadakat yüksek |
| Ölü | **Gömeriz:** ölüm sonrası 1 saat (mezar #5 otomatik "bakımlı") | **Yola devam:** zaman kazanılır, `witnessed_death` stresi artar |

- **Slotlar:** `lineage_generation`'a bağlı: 1. kuşak 1 slot, 2. kuşak 2 slot, … en fazla 4. **Veraset anında** miras alınan töre korunur ya da **bir tanesi** değiştirilir (değiştirmek `grievance` bedeli ister: "adet değişti").
- **Kültür etkileşimi:** her yoldaşın kültürü (`CultureCatalog`) bazı töreleri benimser/yadırgar: uyuşmayanlarda küçük günlük moral sürtünmesi, uyuşanlarda küçük bağ. Bu **yeni sistem değil**, `Morale Rules` kolu.
- **UI:** emir paneline "Töre" düğmesi; `CodePanel` (SuccessionPanel/`OnboardingPanel` sahnesiz deseninde). Çiftler yan yana kart; her seçenekte **ne olacağı açıkça** yazar (legibility kuralı: "risk önizlemesi her zaman açık"). Ahlaki **ağırlık** gecikmeli hissedilir (grievance sonradan).
- **Ledger:** `KIND_CODE` (benimsendi/bırakıldı), çizilmez.
- **Olay bağlamı:** `code_wait_stragglers`, `code_carry_wounded`, … (0/1) anahtarları; olaylar töreye göre dallanabilir.

**Sınır kapıları:** 1 ✓ (her etki mevcut kol), 2 ✓ (karar), 5 ✓, 6 ✓ (hiçbiri yolu **zorunlu** uzatmaz; "Beklenir" tempo ×0.95 **yalnız işaret açıkken** ve rezerv dışı küçük; **ölçülmeli**, gerekirse rezerve eklenir).

**Test:** her töre için etki birim testi; veraset korunumu; slot kuralı; çelişen tören çifti aynı anda seçilemez; planlayıcı rezervi `simulate_journeys.gd` ile.

**Boyut/Risk:** **L**. Risk: denge (altı çift × etki). Önlem: v1'de yalnız **3 çift**.

---

#### #13 Kervan adı ve sancak

**Amaç:** Kimlik yolda **görünsün**. Kuşak başına bir iz: soy görsel olsun.

**Mevcut yapı:** `caravan_name`, `lineage_generation`, karakter oluşturma ekranı, `ArtDraw.wagon`, `WagonFigure`, şehir kapısı (`city_gate`).

**Tasarım:**
- `GameSession.banner = {emblem: "star|wolf|wheel|...", primary: color_id, secondary: color_id, generation_marks: n}` (**prosedürel**, kervan adından deterministik varsayılan + oyuncu seçimi).
- **Yol:** lider atının üstünde sancak/flama (`WalkFigure.KIND_MOUNTED` üstüne ince bir overlay), baş vagonun brandasında amblem. #5 anıtlarında küçük tabelada amblem.
- **Kuşak izi:** her veraset sancağa bir şerit/yıldız ekler (`generation_marks`); eski liderlerin renk şeritleri kalır (soy görsel).
- **Şehir:** `CityView` varışta "Wayborne kervanı geliyor!" gibi kısa bir tanıma satırı, itibar kademesine göre ton (iyi/kötü).
- **Oyuncu düzenlemesi:** Kervan Avlusu (`caravan_yard.gd`) ya da karakter oluşturmada sancak seçici. **Veraset:** yeni lider amblemi değiştiremez, ama **ikincil rengi** seçebilir (kimlik süreklilik + yenilik).
- Adlandırma kuralı: amblem adları özgün; gerçek yapı/dini figür yok.

**Sınır kapıları:** 9 ✓ (amblem adları anahtar), 10 ✓.

**Test:** deterministik varsayılan, kayıt-yükleme, kuşak izi.

**Boyut/Risk:** **M** (çoğu sanat/UI). Mekanik etkisi yok denecek kadar az; bu bilinçli.

---

#### #14 Yol şarkısı (uyarlanabilir ses)

**Amaç:** Yolun **sesini** moral/kültür/kamp ile bağlamak (duyum estetiği, MDA). Yoldaşların şarkı söylemesi insan tezine hizmet eder.

**Mevcut yapı:** `AudioManager` (**sentezlenmiş yer tutucular**), kültür kataloğu, moral, kamp, hava. Gerçek ses planlı (Ana Hedefler: seslendirme/ses).

**Teknik tasarım (ses varlığına bağlı):**
- **Katmanlı müzik (stem):** yol teması + tehlike katmanı (`danger_level`) + moral katmanı + gece katmanı + kamp katmanı. `AudioManager`'a `set_road_state(morale, danger, phase, camping, weather)`.
- **Söyleyen yoldaş:** `sings` (#4) eylemi ya da kültür bayrağı: moral ≥ eşik iken kısa vokal motifi; yalnız ateş başında/gün sonu.
- **Kamp şarkısı seçimi (v2):** kamp başında 3 küçük seçenek (partideki kültürlere göre); seçim kültürel bir `rapport +` / moral +1 verir.
- **Zaman çizelgesi bağı:** tüm ses işi **gerçek seslendirme ve müzik** tamamlanmadan anlamsız. v1: yalnız stem **mantığı** + sentez yer tutucuyla test; varlık üretimi maliyet/onay kuralına tabi.

**Sınır kapıları:** ses üretimi ayrı onay; kod kısmı `AudioManager` genişlemesi.

**Test:** `set_road_state` geçişleri yumuşak (ani kesme yok), karışım sınırları.

**Boyut/Risk:** **L** (asıl yük varlık). Kod tarafı **S-M**. En çok dış bağımlılığı olan madde.

---

### E. RİSK VE RİTİM

#### #15 "Bir gün daha yürü" (gece yürüyüşü)

**Amaç:** Akşam gelince **gerçek bir karar**: kamp mı, yürümeye devam mı? Risk-ödül; ilerleme baskısı (kontrat, borç, mevsim) ile dinlenme arasında gerilim.

**Mevcut yapı:** `JourneyClock.is_camp_time()`, `darkness_for_hour`, `standing_camp_at_dusk` emri (alacakaranlıkta otomatik kamp), `CaravanState.stamina` (+ `STAMINA_PUSH_COST_PER_DAY`, `can_push`), `RoadAttention.FRONT_SPOT_BONUS_DAYS`, `RoadSignals.SPAWN_CHANCE_PER_HOUR`, fener (`LanternGlow`, grim).

**Teknik tasarım:**
- Akşam (`EVENING` başı) bağlamsal karar: **Kamp kur** / **Yürümeye devam (gece yürüyüşü)**. `standing_camp_at_dusk` açıksa otomatik kamp (mevcut emir korunur; emrin gece yürüyüşü karşılığı: "Fenerle yürü").
- Gece yürüyüşü durumu `JourneyController.night_march: bool` (to_dict'e girer). Sonuçları:
  - **Hız:** tempo aynı (planlayıcı sözü korunur), ama **görüş** düşük: ön bölge keşif bonusu (`FRONT_SPOT_BONUS_DAYS`) **sıfırlanır**, omen netleşme (#9) yavaşlar.
  - **İşaret oranı:** `SPAWN_CHANCE_PER_HOUR × 1.5`; `ESCALATE_HOURS − 8`.
  - **Takat:** saatlik `stamina` düşüşü (mevcut "Hızlı" günlük 26'ya orantılı, saat başı ≈ 26/24 ≈ 1.1; kamp yokken **gecelik** yaklaşık 9-10 puan). Yetersizse kervan kendiliğinden kamp kurar (mevcut "takat bitince normale dön" mantığı).
  - **Uykusuzluk sayacı:** üst üste gece yürüyüşü `consecutive_night_marches` (kayıtlı): her fazladan gece stres +1/gün, moral −1/gün (escalating, ceza metni yok, kendi kendini öğretir: Animal-Crossing tipi kümülatif risk).
- **Ödül:**
  - 6-8 saat daha yol: `days_covered` artar (kontrat süresi/borç vadesi baskısı hafifler).
  - **Gece-özel karşılaşmalar:** havuzda `is_night` bağlamı ile ağırlıklanan olaylar (gece kervanı = yüksek kâr ticaret olayı, ışık çiçekleri, kaçakçı). Mevcut olay havuzuna `night_march` koşulu ile eklenir.
- **UI:** akşam kartı yerine **küçük bağlamsal düğme** (modal yok): HUD alt şeritte "Kamp kur · Yürümeye devam". Gece yürürken HUD'da fener nesnesi (SurvivalGauge'ın yanında), TravelBand'de zaten gece karanlığı var.
- **Planlayıcı sözü:** gece yürüyüşü yolu **kısaltır**; erzak rezervi zaten fazlaysa güvenli yön. (Kampın 3 erzak maliyeti atlanacağı için ince bir kazanç; denge ölçümü gerekli.)

**Test:** `JourneyController` yeni alan kayıt, takat kuralı, gece işaret oranları, `consecutive_night_marches` döngüsü, kamp atlandığında erzak/stres, `simulate_journeys` dağılımı.

**Boyut/Risk:** **M**. Risk: kampı gereksiz kılma (dominant strateji). Önlem: kümülatif ceza + takat; ölçüm.

---

#### #16 Nehir geçidi

**Amaç:** **Okunabilir bir risk anı**: oyuncu ne olacağını okuyarak karar verir ("bilmek"), sonuç zarla değil kararla şekillenir. Oregon Trail tipi ikon an; Costikyan'ın performans/analitik belirsizliği.

**Mevcut yapı:** `RouteTerrain.STOP_BRIDGE` + `evt_failing_bridge`, `RouteWeather` (tohumdan hava dizisi), `Inventory`/ağırlık, Arabacı görevi, `WAGON_DAMAGE`, `ITEM_REMOVE`, `Dayanıklılık` statı, durak olayı kalıbı (`stop_context` → `near_<stop>`).

**Teknik tasarım:**
- Yeni durak `STOP_FORD = "ford"` (marsh/lake/forest biyomlarında ağırlıklı, `_pick_stop` tablosu).
- **Su seviyesi** tohumdan: son 3 günün `RouteWeather` yağış sayısı + biyom ⇒ `low/normal/high` (belirlenimci, saklanmaz). Kervan geçide yaklaşırken (ön bölgede) seviye **önceden** görünür (siluet/ikon).
- Kart (durak olayı kalıbı, `evt_river_ford`, taban ağırlık düşük, `near_ford` ×8):
  - **Geç:** vagon başına zar (Arabacı, Dayanıklılık, `wagon_count`); sonuç: hasar, bir kargo kalemi kaybı, **yük hayvanı kaybı** (köpek/eşek). **Hiçbir vagon yok olmaz**, öldürmez.
  - **Yük hafiflet:** belirli kalemleri karaya bırakır (sonradan geri dönülebilir: #8'in "enkaz/yığın" olarak yol kenarında kalır), geçiş güvenli.
  - **Bekle:** 1 gün (erzak yer), seviye tohumdan bir sonraki güne göre değişebilir (belirlenimci).
  - **Köprü ara:** +kısa sapma (zaten bir köprü durağı varsa); +1 gün (**gönüllü uzatma**, kapı 6'ya uygun).
- **Yeni EventEffect gerekmez:** `WAGON_DAMAGE`, `ITEM_REMOVE` yeter. Vagon başı döngü için `EventEffectApplier`'a `wagon_loop` küçük bir yardımcı.
- **Görsel v2:** vagonlar suya sırayla girer, `TravelBand` su şeridi, figürler ıslak (renk). v1: yalnızca kart + log.

**Test:** su seviyesi tohumlu belirlenimci, vagon başı kuralı, "kimse ölmez" garantisi, bekleme gün maliyeti.

**Boyut/Risk:** **M** (kart v1) / **L** (görsel v2).

---

#### #17 Anlatıcı: yolun ruhu

**Amaç:** Tekrar oynanabilirlik ve **tempo yönetimi**: olay sıklığı ve tonu bir "yönetmen" tarafından şekillensin. Hikâye üreten sistem (Sylvester); gerilim/rahatlama eğrisi (Flow).

**Mevcut yapı:** `EventEngine.roll_for_day(current_day, context)`, `GameEvent.get_weight(context)`, `EventWeightModifier`, `cooldown_days`, `RoadSignals.SPAWN_CHANCE_PER_HOUR`, `simulate_journeys.gd` (ölçüm donanımı), `EventEngine.to_dict` (durum kaydediliyor).

**Teknik tasarım:**
```gdscript
class_name RoadStoryteller extends RefCounted
# Profil: {id, label_key, weight_mult_by_category, signal_rate_mult, omen_truth_weights, relief_after_peak}
```
- **Profiller:**
  - **Dengeli** (varsayılan): bugünkü davranışa **birebir** eşit (çarpanlar 1.0). Kayıtlı oyunlar etkilenmez.
  - **Cömert:** yolcu/ticaret/hediye olayları ×1.5, pusu ×0.7, omen `truth` içinde `merchant/pilgrim` ağırlığı yüksek.
  - **Zalim:** pusu ×1.4, kıtlık/hasar olayları ×1.3, işaret oranı ×1.2; ama **ödül de** ×1.2.
  - **Şakacı:** tersine dönüşlü olaylar (korkulan şey zararsız, zararsız görünen şey tuzak), görece nötr denge.
  - **Hafızalı:** olay ağırlıkları **ledger ve grievance'a** bakar (ölen biri varsa mezar olayı, `passed_over` varsa kinci geri dönüşü): nedensellik zinciri.
- **Yönetmen (L4D tipi):** `tension` değeri (0-1): son 3 günün savaş/hasar/ölüm/stres yüküne göre; yüksekse rahatlama olayları (`relief`) ağırlığı artar, düşükse gerilim. Kategori etiketi her `GameEvent`'e eklenir (`tone: calm | build | peak | relief`; bugün yok, yeni alan).
- **Entegrasyon:** `EventEngine`'e `set_weight_hook(Callable)`; hook `(event, context) -> float` çarpanı döndürür. `roll_for_day` ağırlığı `get_weight(context) * hook(...)`. Hook yoksa davranış **birebir** aynı (güvenli yön). Yönetmen durumu (`tension`, `last_peak_day`) `engine.to_dict()` yanına yazılır.
- **Seçim:** yeni oyun başlarken (`character_creation`) ve oyun içi menüde değiştirilebilir (kaybetmeden); kayıtlı `storyteller_id`.
- **Garantiler (test):** hangi profil olursa olsun "kervan yok olmaz", "olay öldürmez", planlayıcı sözü (olay sıklığı erzak yemez; hava/tempo rezervi bozulmaz).

**Ölçüm:** `simulate_journeys.gd` her profil için: sefer başına olay, savaş, ölüm, sefer sonu altın dağılımı; "Dengeli"nin bugünkü ölçümle **eşitliği** regresyon olarak.

**Boyut/Risk:** **M-L**. Düşük teknik risk (hook), yüksek tasarım/dengeleme yükü.

---

#### #21 Kervan mahkemesi

**Amaç:** **Ahlaki ağırlık** ve tüm kadronun tanıklığı. Oyunun tezi (insanlar, güven, aşınma) en yoğun noktada.

**Mevcut yapı:** `NpcDisposition` (`thief`, `vengeful`), grievance, `LEAVE_BEHIND`, `MealDistributionPanel` (ateşi sahne ödünç alan akış), `SuccessionPanel` (sahnesiz tam ekran desen), bond (#2), ledger.

**Tetikleyiciler (en az biri):** (a) #4 `steals_bread` fark edilir; (b) `thief` mizaçlı alınmış yoldaş kervana zarar verdi; (c) bir yoldaşta `grievance_total ≥ 4` ve firar girişimi; (d) savaşta çok erken düşüp kaçan (`downed` sayacı); (e) töre ihlali (#12).

**Teknik tasarım:**
- **v1 (olay kartı tabanlı):** `evt_camp_trial` (`CHAIN`, `triggered_only`), kamp ateşi sahnesinde, kısa kart: suçlanan ad, suçlama, **iki üç tanık replik**; seçenekler: *Affet / Uyar (rapport −1, itibar küçük −) / Pay kes (sofra emri o kişi için SELF_ONLY) / Kov (LEAVE_BEHIND; #5 "sürülen" anıtı)*. **Ölüm yok**.
- **v2 (`CourtPanel` sahnesi):**
  - Suçlanan figür ateşin bir yanında, tanıklar halkada (kamp koltukları `CAMPFIRE_SEATS`).
  - Her tanığın **eğilimi** belirlenimci ve görünür: `bond(akusatör)`, `bond(suçlanan)`, kendi grievance'ı, kültürü, huyları. Sezgi eşiği ile "kim ne düşünüyor" ipucu (hint).
  - Suçun **gerçekliği** gizli (`NpcDisposition` ile bağlı); yüksek Sezgi/Zeka ipucu verir ("doğrulama").
  - Karar sonrası her tanık, karar kendi eğilimine uyuyorsa küçük rahatlama (stres −1), uymuyorsa grievance +1: **herkes bir tarafa düşer**.
- **Ledger:** `KIND_VERDICT` (suçlanan, karar, kuşak), çizilmez. Emsal: aynı suçta ikinci kez farklı karar vermek **tutarsızlık** (küçük `morale` bedeli); ilk karar #12 töre benimsemeye bağlanabilir ("içtihat").
- **Kapılar:** kervanın en az 3 üyesi varken; son üye suçlanamaz; kimse ölmez; ayrılış yalnızca ledger `departed`.

**Test:** tetikleyici koşulları, tanık eğilim fonksiyonu belirlenimci, karar → grievance/rapport etkileri, kimse ölmez ve son üye kapısı, ledger satırı.

**Boyut/Risk:** **M** (v1) / **XL** (v2 sahne). v1 yeterince güçlü; v2 ancak tez-merkezli sahne olarak bakılmalı.

---

## 6. Yeni EventCondition anahtarları ve EventEffect türleri

### 6.1 Bağlama eklenecek anahtarlar (`build_event_context()`)

`EventCondition` yalnızca **sayısal sabitle** karşılaştırır (bkz. `party_slots_free` notu); bu yüzden 0/1 ya da sayı olarak hazır verilir.

| Anahtar | Anlam | Madde |
|---|---|---|
| `near_memorial` | Kervan bir anıta ≤ 0.1 gün | #5, #8 |
| `memorial_count_on_route` | Bu rotadaki anıt sayısı | #5 |
| `route_trips` | Bu rotanın sefer sayısı | #19 |
| `max_rapport` | Partideki en yüksek rapport | #1, #3 |
| `has_unseen_story` | Anlatılmamış hikâyesi olan yoldaş | #3 |
| `night_march` | Gece yürüyüşü açık | #15 |
| `consecutive_night_marches` | Üst üste gece sayısı | #15 |
| `near_ford`, `ford_level` (0/1/2) | Geçit ve su seviyesi | #16 |
| `near_fork` | Çatal | #11 |
| `code_<tenet>` (0/1) | Benimsenen töre | #12 |
| `diary_entries` | Deftere yazılmış gün sayısı | #7 |
| `max_bond`, `min_bond` | Çift bağ aralığı | #2 |
| `storyteller_tension` | Yönetmen gerilimi (0..1, ×100) | #17 |
| `trial_ready` | Mahkeme tetikleyicisi koşuyor | #21 |

### 6.2 Yeni `EventEffect.Type` önerileri

| Tür | Gerekçe | Madde |
|---|---|---|
| `PERSON_STRESS` | Mevcut `STRESS` **tüm partiye** (`apply_event_stress`) yazıyor; kişisel rahatlama/yük gerek | #3, #5, #21 |
| `RAPPORT` | Bir kişinin lidere bağını değiştirir | #1, #3 |
| `CLEAR_GRIEVANCE` | Belirli grievance'ı 1 azaltır | #1, #5 |
| `ADD_MEMORIAL` | Anıt dikmek | #5, #6, #8 |
| `RECORD_LEDGER` | Ledger'a belirli türde satır | #3, #7, #12, #21 |

Her yeni tür `EventEffectApplier`'da tek kapıdan uygulanır (`EventResolver` tek çözüm yolu ilkesi); `event_effect.gd` enum'una ve `test_event_effects.gd`'ye eklenir.

---

## 7. Kayıt, yerelleştirme, test, performans

### 7.1 Kayıt
- `SAVE_VERSION` artırmak **gerekmez** (eklenenler yalnızca yeni alan); yine de her yeni alan `to_save_dict` + `load_from_dict` + `_test_every_persistent_field_is_saved` listesinde olmalı.
- **Sefer ortası kayıt:** `JourneyController.to_dict()` yeni alanlar: `night_march`, `consecutive_night_marches`, `fork_choice`, omen/işaret listesi (şu an **yok**, bkz. §10).
- **Kayıt zar atmaz:** omen `truth`, anlatıcı `tension`, vista sonuçları tohum/durumla saklanır.
- `test_save_migration.gd`'ye eski kaydın (yeni alanlar yok) sorunsuz yüklendiği testler.

### 7.2 Yerelleştirme
- Yeni anahtarlar `data/locale/ui.csv` / `game.csv` / `events.csv`; tr + en dolu, diğer diller boş (mevcut desen).
- **Hacim tahmini (ilk sürüm):** chatter ~120 satır, kamp hikâyesi 15 hikâye, günün cümlesi şablonları ~45, töre ~18 metin, vista/omen/ford ~60, olay kartları ~12. **Toplam ~300 anahtar** (tr+en = 600 hücre).
- İçerik yazımı ayrı bir iş akışı olarak yürütülmeli.
- `test_localization.gd` yeni sabit metinleri taramalı; **serbest metin** (günün cümlesi, kullanıcı yazısı) taramanın dışında, ayrı kategoride.

### 7.3 Test
Yeni paketler (`tests/run_tests.gd` listesine eklenir):
`test_road_chatter.gd`, `test_companion_bonds.gd`, `test_road_memorials.gd`, `test_road_omens.gd`, `test_field_notes.gd`, `test_caravan_code.gd`, `test_night_march.gd`, `test_ford.gd`, `test_storyteller.gd`, `test_camp_trial.gd`. `simulate_journeys.gd` genişletilir (profil başı dağılım, rapport büyümesi, omen çözülme, gece yürüyüşü benimsemesi). Resim araçları: `screenshot_memorials.gd`, `screenshot_road_balloon.gd`, `screenshot_camp_story.gd` (test değil, resim; bir yapı geçişi **göremez**, yerleşim hatasını resim gösterir).
- CI sırası: `godot --headless --import` sonra `godot --headless --script res://tests/run_tests.gd` (YAPILACAKLAR §0).

### 7.4 Performans (özellikle Web)
- **Kare başı string üretme yok** (KOD_DENETİMİ O-2). Baloncuk metni yalnızca gösterildiğinde kurulur; HUD sayıları "değer değişince" kalıbıyla.
- `_draw_memorials()` ≤ 6 anıt/rota ve görüş dışı atlama (`_draw_stops` gibi).
- `companions_near` her karede **tarama** yapmaz; liderin offset'i değiştiğinde ya da 0.1 s'de bir.
- Yeni sürekli `queue_redraw` bileşeni **eklenmez** (KOD_DENETİMİ O-8).

---

## 8. Uygulama sırası ve boyutlar

Beyin fırtınasındaki öncelik: **#1+#3 → #5 → #12 → #17 → #7**. Teknik bağımlılıkla birleşince aşağıdaki faz planı çıkıyor.

| Faz | İçerik | Bağımlılık | Boyut |
|---|---|---|---|
| **R0 Altyapı** | 4.1 figür→karakter eşlemesi, 4.2 `RoadBalloon`, 4.3 `RoadChatter` iskeleti, 4.4 `backstory_id`/`rapport`, 4.5 ledger türleri, 4.6 `GameSession` alanları, §6.2 `PERSON_STRESS/RAPPORT/CLEAR_GRIEVANCE/RECORD_LEDGER`, `RoadSignals` kayıt düzeltmesi | Yok | **M-L** |
| **R1 İnsanlar** | #1 (yanına yürü), #3 (kamp hikâyesi, 1-2 bölüm), #2 (bağlar, yan yana yürüme), #4 (özerk eylemler) | R0 | **L** |
| **R2 Hafıza** | #5 (mezarlar; prosedürel görsel), #7 (günün cümlesi, hazır cümleler), #6 (dönüm taşı), #8 (enkaz), #19 (aşinalık) | R0; #6 ← #5, #7 | **L** |
| **R3 Merak ve töre** | #12 (3 çift), #17 (anlatıcı + yönetmen), #9 (omen), #10 (yol notları), #22 (vista) | R1/R2 | **L-XL** |
| **R4 Risk** | #15 (gece yürüyüşü), #16 (geçit kartı) | R3 (#17, #9 ile etkileşim) | **M** |
| **R5 Büyük sahneler** | #21 (mahkeme v1 kart → v2 sahne), #13 (sancak), #14 (ses, varlık bağımlı), #11 (çatal) | R1-R4; sanat/ses | **XL** |

**Kural:** her faz kendi içinde `simulate_journeys.gd` ölçümü ve kullanıcı onayı ile kapanır (CLAUDE.md disiplini: "ölçülmeden değiştirilmez"). Her fazın sonunda ekran görüntüsü kullanıcıya sunulur.

**İlk dilim önerisi (en küçük "yürüme artık yürüme değil" dilimi):**
R0 + #1 (yalnız baloncuk + rapport) + #5 (yalnız prosedürel mezar + ad okuma). Bu iki parça birleşince yolda **kişi** ve **hafıza** aynı anda görünür; oyunun tezi ilk kez yolda sahnelenir.

---

## 9. Başarı ölçütleri

Telemetri yok (oyun yerel); ölçüm **simülasyon** ve **oyun testi** ile.

| Ölçüt | Hedef | Yöntem |
|---|---|---|
| Yolda "kişi" teması | Sefer başına ≥ 3 tanık olunan insan anı (baloncuk, hikâye, çift davranışı) | `simulate_journeys.gd` sayaçları |
| Dikkat dağılımı | Üç bölgenin her birinde zamanın ≥ %15'i | Yeni sayaç (`_attention_zone` süre dağılımı) |
| 3x hız kullanımı | Oyun testi sonuçlarında 3x'te geçirilen yol oranı düşmeli | Oyun testi gözlemi, dev paneli (F1) sayacı |
| Defter doluluğu | Kuşak başına ≥ 5 günlük cümlesi (opsiyonel yazı olduğu için gerçekçi hedef) | Kayıt analizi |
| Anıt etkisi | İkinci geçişte anıt okuma/anma oranı | Dev sayacı |
| Denge regresyonu | "Dengeli" anlatıcıda seferler bugünkü ölçümle **eşit** | `simulate_journeys.gd` karşılaştırma |
| Planlayıcı sözü | Doğru stoklayan kervan hiçbir madde yüzünden açlıktan ölmez | `test_route_terrain.gd` (80 kombinasyon) genişletilmiş |

---

## 10. Doğrulanması gereken varsayımlar ve açık sorular

**Kodda gördüklerim, ama uygulamadan önce bir kez daha doğrulanmalı:**
1. **Arazi yönü:** `RouteTerrain.build(route_key)` yönsüz anahtarla kuruluyor (`road_journey.gd:1462`). A→B ve B→A seferlerinde `terrain_day` ekseninin aynı mı yoksa ters mi okunduğu (anıt konumunun iki yönde tutarlı çıkması için) test edilmeli. `JourneyController.heading/leg_origin_day` yalnızca **geri dönüşü** kapsıyor.
2. **Parti figürlerinin kolondaki dağılımı:** `road_caravan.gd:1408-1415` partiyi vagonların arasına yerleştiriyor gibi; #1'in "dikkat bölgesi gerilimi" bu varsayıma dayanıyor. Gerçek dağılım ekran görüntüsüyle doğrulanmalı.
3. **`RoadSignals` kaydedilmiyor** (`to_dict` yok, kodda aranıp bulunamadı). Sefer ortası kayıt yüklenince açık işaretler kaybolur. Omen ve adlı işaretten **önce** düzeltilmeli. (Bu, `KOD_DENETIMI.md`'ye ayrı bir madde olarak eklenebilir.)
4. **`EventEffect.Type.STRESS` kişiye değil partiye uygulanıyor** (`session.apply_event_stress`). `PERSON_STRESS` gerçekten gerekli mi, yoksa `apply_event_stress` kişi parametresi mi almalı?
5. **Waybook sayfa yapısı:** `waybook_panel.gd` sol/sağ iki sayfalı. Yeni "Yol Notları" ve "Düşenler" sekmesi bu yapıya sığıyor mu, yoksa sayfa gezinmesi mi gerekiyor?
6. **`PropArt`'ta mezar/yığın/sancak prop'u yok.** Prosedürel (`ArtDraw`) ile mi başlanacak, yoksa render prop için üretim onayı mı alınacak?
7. **`RecruitCatalog` adayları kalıcı kimliksiz** ("her şehir varışında yeniden atılıyor"). `backstory_id`'nin işe alma anında mı, aday üretiminde mi atanacağı. (Aday üretiminde atanması, "neden geldi" satırıyla birleşir.)
8. **`CaravanLedger` yükleme yolu:** `to_array/from_array` yeni alanları (`text`, `extra`) taşıyor mu? Kodda yalnızca `record()` ve okuma yolları okundu.
9. **Tayfa figürleri `null` karakterle yaratılıyor** ama isimleri var (`crew_names`). Tayfa ile sohbet (v2) için figür→isim eşlemesinin vagon/figür indeksiyle güvenilir olup olmadığı.
10. **Çevrilmiş diller:** tr/en dışındaki diller CSV'de boş. Boş çevirinin oyunda nasıl göründüğü (`UI_LANGUAGE_UNTRANSLATED_SUFFIX` ile İngilizceye düşme) yeni metinler için de yeterli mi.

**Kullanıcıya sorulacak kararlar:**
- Günün cümlesinde **serbest metin** (#7) açılsın mı, yoksa yalnızca hazır cümleler mi?
- Sancak (#13) sanat/ses (#14) için **ücretli üretim** yapılacak mı (maliyet önceden çıkarılıp onaya sunulacak)?
- Anlatıcı profili (#17) **oyun başında kilitli mi**, oyun içinde değiştirilebilir mi?
- Kamp hikâyesi (#3) içerik yazımı için ayrı bir yazı akışı kurulacak mı (~15 hikâye)?
- Mahkeme (#21) **v1 (kart)** ile mi başlanacak, v2 sahne ayrı karar mı?

---

## 11. Kaynaklar

- Ryan, R. M., Rigby, C. S., Przybylski, A. (2006). *The Motivational Pull of Video Games: A Self-Determination Theory Approach.* Motivation and Emotion. [Özet](https://pure.ewha.ac.kr/en/publications/the-motivational-pull-of-video-games-a-self-determination-theory-/)
- Tyack, A., Mekler, E. (SDT incelemesi; ilişkililiğin az incelendiği). [Frontiers](https://www.frontiersin.org/journals/virtual-reality/articles/10.3389/frvir.2022.847120/pdf)
- Yee, N. (2006). *Motivations of Play in Online Games* ve Quantic Foundry Gamer Motivation Model. [Referans](https://quanticfoundry.com/wp-content/uploads/2019/04/Gamer-Motivation-Model-Reference.pdf)
- Lazzaro, N. *Four Keys to Fun.* [Özet](https://roadtovr.com/nicole-lazzaro-four-keys-fun-virtual-reality/)
- Jenkins, H. *Game Design as Narrative Architecture.* [Özet](https://summit.sfu.ca/item/209)
- Loewenstein bilgi boşluğu kuramının oyun uyarlaması (To ve ark., 2018). [DiGRA](https://dl.digra.org/index.php/dl/article/download/793/793)
- Costikyan, G. (2013). *Uncertainty in Games.* MIT Press. [Tanıtım](https://jesperjuul.net/ludologist/?p=1786)
- Juul, J. (2013). *The Art of Failure.* MIT Press. [Özet](https://bigthink.com/neuropsych/play-video-games-to-fail/)
- Hunicke, LeBlanc, Zubek. *MDA: A Formal Approach to Game Design and Game Research.* [PDF](https://users.cs.northwestern.edu/%7Ehunicke/MDA.pdf)
- Sweetser, P., Wyeth, P. (2005). *GameFlow.* [PDF](https://ntnu.no/wiki/download/attachments/112986425/GameFlow.pdf?api=v2)
- Bogost, I. (2007). *Persuasive Games* (prosedürel retorik). [Özet](https://en.wikipedia.org/wiki/Procedural_rhetoric)
- Yürüme oyunları ve yavaşlık estetiği (Muscat ve ark.; Navarro-Remesal). [Özet](https://blogs.tuni.fi/playlab/game-research-highlights/the-design-of-the-walker-game-experience/)
- Sylvester, T. (2013). *Designing Games.* O'Reilly (hikâye üreten sistem yaklaşımı için ikincil kaynak).
- Meier'in "ilginç kararlar" tanımı ve eleştirisi. [Game Developer](https://www.gamedeveloper.com/design/all-games-are-about-choices)

**Doğrulanamayanlar (bu belge dayanmıyor):** Schell'in mercekleri, Salen & Zimmerman'ın "anlamlı oyun" tanımı, Koster. Bunlar için ayrı bir tarama gerekir.

**Depo içi dayanaklar:** `CLAUDE.md` (Road Layer Rules, Road Movement Rules, Road Encounter Rules, Route Terrain & Weather Rules, Lineage Rules, Ana Hedefler), `scripts/travel/*`, `scripts/ui/road_*.gd`, `scripts/events/*`, `scripts/campaign/caravan_ledger.gd`, `scripts/character/character_data.gd`, `docs/design_notes/akademik_kaynak_onerileri.md`, `TODO/belgeler/KOD_DENETIMI.md`.
