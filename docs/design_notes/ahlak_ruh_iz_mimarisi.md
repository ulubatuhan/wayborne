# Ahlak · Ruh · İz — üç alt sistemin mimarisi

`docs/fable_sistem_promptu.md` promptunun cevabı (2026-11-10, depo `2a618c6`). Kod değil mimari: veri şeması,
tetikleme mantığı, sözde kod ve matris. Uygulama sırası §H'de; her adım kendi testiyle gelir.
Bölüm başlıkları (§A–§I) promptun istediği gibidir.

Üç alt sistemin tek cümlesi:

- **Ahlak** bir kararın bedelini *adı olan birine* yükler.
- **Ruh** o bedeli gören insanları yavaşça ve bazen geri dönülmez biçimde değiştirir.
- **İz** kararı dünyaya yazar, yol boyunca yayar ve oyuncunun sebebini kurabileceği biçimde geri getirir.

---

## §A · TEŞHİS

| # | Açık | Kanıt (dosya/alan/ölçüm) | Tür | Neden önemli | Hangi alt sistem kapatır |
|---|---|---|---|---|---|
| 1 | **Kadro 10. seferde 1'e iniyor ve orada kalıyor.** İnsanları konu alan oyunda insan yok. | `simulate_career`: üç politikada da kadro 2 → 1 (sefer 10) → 1 (sefer 40); `STARTING_PARTY_SIZE=2`, `PEOPLE_PER_WAGON=2`, vagon 3 ama kadro 1. | yarım-döngü | "İnsanlar aşınır" sütununun malzemesi tükeniyor; aşınacak kimse kalmıyor. Kaybedilen kişi geri gelmiyor çünkü işe almak yalnızca altınla ve altın hep eksi. | İz (minnet izi kapıya insan getirir) + Ruh (Boş Yer) |
| 2 | **Ahlaki kartların çoğu kadro koşulunun arkasında kilitli.** | `evt_elder_burden`, `evt_fever_quarantine`, `evt_taken_captive` → `party_size ≥ 3`; `evt_faith_tribunal`, `evt_leave_the_wounded` → `≥ 2`; `evt_faction_split` → `≥ 6`. Kariyer ortalaması kadro 1. | yarım-döngü | Oyunun en iyi ikilemleri, oyunun gerçekte hiç ulaşmadığı bir durumu bekliyor. | Ahlak (bedel taşıyıcısı kadro dışına da düşebilir: tayfa eli, şehir, yabancı, gelecekteki sen) |
| 3 | **Ustalık eğrisi ters.** Rastgele seçen acemi 40 sefer dayanıyor, altına koşan 33,8'de bitiyor; planı okuyan −22 GG. | `simulate_expert_review` B: acemi 40,0 sefer / −610 GG / %43 aç · dengeli 40,0 / −22 · açgözlü 33,8 / +177. | baskın-strateji | Okumak ile okumamak arasındaki fark dayanıklılıkta görünmüyor; oyun bilgiyi ödüllendirmiyor. Kötü oynamak öldürmüyor, yalnızca yoksullaştırıyor. | İz (açık hesapları okuyan oyuncu geri dönüşü *toplar*: bilgi oyununun ahlaki yüzü) |
| 4 | **"İyi bir şey arası 40,4 gün."** Kese kariyer boyunca eksi, borç hiç kapanmıyor. | `simulate_expert_review` B; `simulate_career`: kese 20. seferden sonra −67…−150, borç 104–206, dertsiz sefer %13–15, en uzun sakin dizi 4. | görünmeyen-birikim | Kıtlık hissi doğru ama *ritim* yok: baskı tek yönlü. Kayıp ancak bir kazançla ölçülür; kazanç yoksa kayıp gürültüye döner. | İz (iyi dönüşler: minnet, açılan kapı, tutulan söz) — hedef ≤ 15 gün |
| 5 | **Şehir ziyaretlerinin %43'ünde yapacak iş yok.** | `simulate_expert_review` A: "boş tur %43". | yarım-döngü | Şehir, yolun bedelinin tahsil edildiği yer olmalı; bugün yalnızca dükkân. | İz (şehir tarafı geri dönüşler: kapıda bekleyen, kapanan hesap) + Ruh (şehrin ruhu) |
| 6 | **İçerik 8,5. seferde tükeniyor; çekilen kartların %74'ü tekrar; 40 seferde 101 kartın 66'sı görülüyor.** | `simulate_expert_review` A; `simulate_career`: 1792 çekiliş, 66 farklı kart. | sonuçsuz-seçim | Tekrar eden kart ilk seferki cevabı *bilmiyor*. Aynı metin, aynı seçenek: oyuncu öğrenmiş, dünya öğrenmemiş. | Ahlak (yankı varyantı: ikinci geliş ilk cevabı bilerek gelir) |
| 7 | **Kararlar kaydediliyor ama yalnızca ölüm ekranı okuyor.** | `recent_decisions` (`RECENT_DECISION_COUNT=3`): `game_session.gd` + tek okuyucu `road_journey.gd:4227`. `note_decision()` her kartta çağrılıyor. | okunmayan-durum | İz sisteminin kancası zaten atılmış; ucunda bir şey yok. | İz (iz kaydının doğum noktası) |
| 8 | **Bağ ve kırgınlık olay motoruna hiç görünmüyor.** | `bonds`, `grievance`, `rapport`, `backstory`: `scripts/events/` içinde **0** dosya. Olay bağlamında (`build_event_context`) bunlardan anahtar yok. | okunmayan-durum | Kimin kime yakın olduğu, kimin neye kırgın olduğu, kimin neden yola düştüğü biliniyor ama hiçbir kart bunu bilmiyor. Bedel hep "en zayıf" ya da "lider"e düşüyor (`PARTY_HP` `weakest`). | Ahlak (bedel taşıyıcısı seçici) + Ruh |
| 9 | **Yolun hafızası yalnızca görsel.** | `route_memory` (trips, last_day, deaths): okuyucu yalnız UI (2 dosya). `road_memorials`: olay 0, UI 0, yalnız çizim. `seen_places`, `bought_here`: yalnız `game_session.gd`. | okunmayan-durum | Aynı yolda üç kişi gömmüş kervan o yola dördüncü kez girerken hiçbir şey olmuyor. "Yol yaşar" ama hatırlamıyor. | İz (yol taşıyıcılı iz) + Ruh (mezarın yanından geçmek) |
| 10 | **Aç bırakılan tayfanın izi tek bir fiyata iniyor.** | `crew_lost_to_hunger` → yalnız `CREW_HIRE_PER_LOST=6`; `crew_hungry_nights` → ölüm/dağılma hesabı + 1 UI. `crew_deserted_names` yazılıyor, okuyan yok (Y-E13 açık). | tek-girdili-sistem | Lore "adamını aç bıraktı yolun en ağır sözü" diyor; oyunda 6 GG. | İz (söz yayılır) + Ahlak (dağılan el yolda karşına çıkar) |
| 11 | **Vurgunculuğun tek sonucu tek bir kart.** | `profiteering_sales` → yalnız `evt_profiteer_recognized` (`≥3` satış, bir kez). `TRADE_PROFITEER_STANDING=-3`. | tek-girdili-sistem | Açgözlü politika +177 GG ile en kârlı ve geri dönüşü tek seferlik. Zalimliğin ödülü var, faturası yok. | İz (şehir taşıyıcılı kin, yayılır ve fiyat katmanına döner) |
| 12 | **Karizma'nın savaştaki karşılığı ölü.** | `simulate_journeys` "Sükûnet": Karizma 5/10/15, sakin ve kırılmış partide hep %53. | tek-girdili-sistem | Ölçüm, sistemin bağlı olmadığını gösteriyor. Liderin sözü savaşta bir şey ifade etmiyor. | Ruh (liderin sözü kırılmanın eşiğini taşır: §D-R4) |
| 13 | **Kırılma oluyor, ayrılık olmuyor.** | `simulate_journeys`: kırılma 0,07–0,36/sefer, "toplam ayrılık 0" (600 koşu). `BREAK_DEPARTURE_CHANCE=0.2`. | yarım-döngü | Ya simülatör partisi ayrılamayan tek kişiden oluşuyor ya da kapı kapalı; iki durumda da kırılmanın bedeli ölçülmüyor. | Ruh (durum makinesi; ölçüm aracı §G) |
| 14 | **Şehrin hâli insanlara dokunmuyor.** | `city_morale`: `scripts/events` 1 dosya, UI 0; kişi stresine, bağa ya da işe alınan adayın hâline etkisi yok. `MORALE_HUNGRY=30`. | tek-girdili-sistem | Aç bir şehre girmek yalnızca fiyatı değiştiriyor; insanı değiştirmiyor. | Ruh (şehrin ruhu ↔ kervanın ruhu) |
| 15 | **Söz verilebiliyor, söz tutulmuyor.** | "Söz ver, oyala" (`evt_mutiny`), "Ödeyeceğine söz ver" (`evt_creditor_rider`), "Fidye haberi bırak": hepsi `SET_FLAG` + tek zincir. Ant (`OATH_*`) yalnız göçebe ve dağlı yoldaşta, yalnız lider–yoldaş arasında. | sonuçsuz-seçim | Söz bu dünyada bir sicil (lore §12.4), oyunda bir bayrak. Vadesi, tanığı, bozulunca yayılması yok. | İz (söz = vadeli iz) + Ahlak |
| 16 | **Kervanın İllet taşıması oyuncuya hiç dönmüyor.** | `PlagueWorld.CARRY=0.006` kervanın taşıdığı hasta payı; `plague`, `plague_news` var; "kimin getirdiği" kaydı yok. | görünmeyen-birikim | Oyuncu bir şehre hastalık götürebiliyor ve bunu ne o biliyor ne şehir. Dünyanın en büyük kelebek etkisi sessiz. | İz (kuşak aşırı iz) |
| 17 | **Kuşak devri bir sayı.** | `legacy` (okuyucu 1 dosya), `lineage_generation` var; `appoint_heir` yalnız `PASSED_OVER_STRESS`. Varis, öncekinin *ne tür* bir kervanbaşı olduğunu devralmıyor. | görünmeyen-birikim | "Defter unutmaz" ama ad yalnızca bir etiket; babanın yaptıkları oğlun kapısını çalmıyor. | İz (kuşak izleri) + Ruh (lakap) |
| 18 | **Günün izleri yalnızca cümle üretiyor.** | `day_beats` (`BEAT_*`, `BEAT_WEIGHTS`): okuyucu yalnız `game_session.gd` (günlük cümlesi). | okunmayan-durum | O gün ne yaşandığının sınıflı kaydı zaten var; Ruh'un ihtiyaç duyduğu "tanıklık" girdisi bu. | Ruh (tanıklık girdisi) |

### Varsayımlarım

1. **VERİ-7 boş.** Oyuncu davranışını VERİ-6'daki vekil göstergelerden çıkardım; gerçek bir oturumda oyuncunun
   nerede durduğunu bilmiyorum. Özellikle "kadro 1" satırı simülatör politikasının (altın yetince işe alır)
   sonucu olabilir; gerçek oyuncu daha erken insan tutuyor olabilir. Tasarım iki duruma da dayanacak şekilde
   kuruldu (kadro 1'de de çalışır).
2. **`simulate_journeys`'in "hiç ateşlenmedi" listesi (49 kart) ölçüm aracının körlüğüdür**, kartların ölü
   olduğunun kanıtı değil: o araç tek seferi dünya durumu olmadan koşturuyor (yer, kervansaray, İllet, zincir
   yok). Güvendiğim sayı kariyer simülatörününki: 40 seferde 66 farklı kart, 35'i hiç görülmüyor.
3. `party` adı olan yoldaşları, `crew_names` adsız-adlı tayfa ellerini tutuyor; ikisini ayrı katman saydım.
4. `People` (şehir başına lonca/tefeci/taverna kişisi + bölge reisi) kalıcı ve yaşlanıyor; `remember_trade` ve
   `remember_deed` zaten bir "gönül" değeri tutuyor (`regard_here`). İz sistemi bunun üstüne oturur.
5. Kayıt yalnız şehirde yazıldığı için yolda doğan iz, o sefer bitmeden kalıcı değildir; sefer ortası
   otomatik kayıt bunu taşıyabiliyor varsaydım (`journey` bloğu).
6. Aynı kervanda adı olan yoldaş sayısı pratikte ≤ 6 (vagon × 2, savaş 4). İlişki ağı buna göre boyutlandı.
7. Yeni metinlerin tamamı çeviri anahtarı olarak girer (tr + en); sayıları ben verdim, metinleri vermedim.

---

## §B · MİMARİ

### B.1 Sorumluluk sınırları

| | Yapar | Yapmaz |
|---|---|---|
| **Ahlak** | Bir kartın seçeneğine *bedel taşıyıcısı* atar; kıtlığa göre seçenekleri sertleştirir; tekrar eden kartı *yankı* varyantına çevirir; söz verdirir. | Kart çekmez (o `RoadDirector`'ın işi). Yeni bir olay motoru değildir: var olan `GameEvent`/`EventChoice`/`EventOutcome` yapısının üstünde bir **çözücü katman**dır. |
| **Ruh** | Her kişide iki yavaş eksen (Kabuk, Çatlak) ve onlardan türeyen hâli tutar; tanıklığı işler; bağı ve Boş Yer'i yönetir; şehrin ruhunu kervana, kervanınkini şehre taşır; kamp ateşinde sessiz anı seçer. | Stresin, yorgunluğun, huyun yerini almaz. Oyuncu adına seçim yapmaz. Kimseyi öldürmez. |
| **İz** | Kararı kalıcı kayda çevirir; taşıyıcısına yazar; yol boyunca yayar; olgunlaşınca bir *geri dönüş biçimi* seçer; oyuncuya nedenini okutur. | Rastgele olay üretmez: her geri dönüşün bir doğum kaydı vardır. İtibarın (`Standing`) yerini almaz; onu besler. |

### B.2 Bileşenler ve akış

```
                         ┌───────────────────────── AHLAK ─────────────────────────┐
[RoadDirector] --kart--> [YankiCozucu] --varyant--> [SertlikKapisi] --seçenekler--> (oyuncu seçer)
     ^                        ^  |                        ^                              |
     | ağırlık                |  | "bu kartı daha önce      | scarcity_here               v
     | (iz_agirligi)          |  |  nasıl cevapladın"       |                     [BedelTasiyiciSecici]
     |                        |  v                          |                              |
     |                   [IzDefteri] <------------------ iz_birak -------------------------+
     |                        |                                                            |
     |                        | olgun izler                                        etkiler (EventEffectApplier)
     |                        v                                                            |
     +--------------- [GeriDonusSecici] ---fiyat/kapı/yüz/teklif/ret---> [Dünya]           v
                              |                                                    ┌──── RUH ────┐
                              +---- "döndü" (iyi/kötü) --------------------------> [TaniklikIsleyici]
                                                                                        |
[day_beats] --günün izleri--> [TaniklikIsleyici] --Kabuk/Çatlak--> [HalMakinesi] --hâl--> [BagAgi]
                                                                        |                    |
[city_morale] <--yük, lakap--- [SehirKoprusu] <--- kervanın huyu -------+                    |
      |                                                                                      v
      +---- şehrin ruhu ---> [SehirKoprusu] ---stres/Çatlak---> [HalMakinesi]         [AtesBasi]
                                                                                   (kampın sessiz anı)
```

### B.3 Mevcut sistemlere bağlantı noktaları

| Bağlantı | Var olan yer | Ne eklenir |
|---|---|---|
| İzin doğumu | `GameSession.note_decision(event_id, choice_key)` — her kartta zaten çağrılıyor | Çağrının sonuna `iz_birak` kancası. Yeni etki türü `IZ_BIRAK` ile kart da açıkça iz bırakabilir. |
| İzin şehir dışı doğumu | `beg_in_tavern`, `swindle_in_tavern`, `apply_meal_distribution`, `dismiss`, `appoint_heir`, `record_sale` (merhamet/vurgun), `apply_camp_actions`, `resolve_deaths`, kontrat kaybı, `advance_day` (borç gecikmesi) | Her biri tek satırlık `iz_birak` çağrısı; tablosu §E'de "tetikleyen karar" sütunu. |
| Bağlam anahtarları | `GameSession.build_event_context()` | `iz_*` ve `ruh_*` anahtarları (§C.4). Kartlar bunları mevcut `EventCondition` (key, op, value) ile okur. |
| Kart ağırlığı | `RoadDirector.weight_multiplier()` | `iz_agirligi` çarpanı: olgun bir izin geri dönüş kartı `DOMINO_WEIGHT` (2,5) ailesinden ağırlık alır. |
| Etkilerin uygulanması | `EventEffectApplier` | Dört yeni etki türü: `IZ_BIRAK`, `BEDEL`, `RUH`, `SOZ` (§C.3). |
| Ad doldurma | `EventText` (`{who}`, `{town}`) | `{bedel}` (taşıyıcının adı), `{eski}` (izin doğduğu yer/kişi). |
| Kişi hafızası | `People.remember_trade/deed`, `regard_here`, `chief_*` | Kişi taşıyıcılı izler `People`'a yazılır; yeni kişi rolü gerekmez. |
| Yol hafızası | `route_memory`, `road_memorials` | Yol taşıyıcılı izlerin okuduğu yer; yeni alan eklenmez, okuyucu eklenir. |
| Fiyat | `MarketPricing` katmanları (`LAYER_EVENT`), `TRADE_STAIN_*` | Şehir taşıyıcılı kin/minnet `LAYER_EVENT`'e ±%4–%12 yazar; yeni katman açılmaz. |
| Kişi durumu | `CharacterData` (stress, traits, grievances, rapport, backstory), `CompanionLife` (bonds) | `kabuk`, `catlak`, `hal`, `hal_gunu` alanları (§C.2). Kırılma huyları ve `BREAK_*` kipleri aynen kalır. |
| Günün tanıklığı | `day_beats` (`BEAT_DEATH`, `BEAT_HUNGER`, `BEAT_SACRIFICE`, `BEAT_MERCY`...) | Ruh'un günlük girdisi. Yeni iz türleri: `BEAT_PRICE` (biri bedel ödedi), `BEAT_RETURN` (bir iz döndü). |
| Şehir | `city_morale`, `CITY_MORALE` etkisi, `MORALE_PER_DELIVERY` | Şehrin ruh bandı (§C.5) ve iki yönlü köprü (§D-R6). |
| Kamp | `apply_camp_actions`, `CompanionLife.roll_action` (`ACTION_CHANCE 0,06`) | Zarın yerine öncelik sırası: kampın sessiz anı Ruh'tan seçilir (§D-R7). Zar yalnız hiçbir hâl yokken kalır. |
| Defter | `CaravanLedger` (`KIND_*`) | İki yeni tür: `KIND_TRACE` (açık hesap) ve `KIND_EPITHET` (lakap). İkisi de silinmez; kapanan hesabın üstü çizilmez, yanına karşılığı yazılır. |
| Kuşak | `appoint_heir`, `legacy`, `lineage_generation` | Varis kuşak izlerini ve önceki liderin lakabını devralır. |
| Ölçüm | `simulate_career`, `simulate_personas`, `simulate_expert_review` | Yeni metrikler ve üç ahlak politikası (§G). |

### B.4 Üç alt sistemin birbirine bağlandığı yerler

1. **Ahlak → İz:** her bedelli seçim bir iz doğurur; izin taşıyıcısı bedelin taşıyıcısıdır.
2. **Ahlak → Ruh:** bedelin ödendiğine *tanık olan* herkesin Kabuk/Çatlak'ı oynar (ödeyenin en çok).
3. **Ruh → Ahlak:** bedel taşıyıcısı seçici kişilerin hâlini, bağını ve kırgınlığını okur; liderin Kabuk'u
   merhametin stres maliyetini, Çatlak'ı sertliğin stres maliyetini değiştirir.
4. **Ruh → İz:** kervanın ortalama hâli bir **huy** üretir (Eli Açık / Eli Sıkı / Eli Kanlı); huy bir bölge
   izidir, yayılır ve yolda karşılanma biçimini değiştirir.
5. **İz → Ahlak:** olgun iz, kartın yankı varyantı ya da kendi geri dönüş kartı olarak gelir; ikinci ikilem
   birincinin cevabını bilir.
6. **İz → Ruh:** **Çatlak yalnızca dönen bir iyilikle iyileşir.** Dinlenmek stresi indirir, Çatlak'ı indirmez;
   bir yoldaşın Çatlak'ı ancak "yaptığımız bir işe yaradı" anında −1 düşer. Kabuk ise yalnız bedelli
   merhametle yumuşar. Bu, üç sistemi kapalı bir döngü yapan bağdır.

---

## §C · VERİ YAPILARI

### C.1 İz

```json
{
  "Iz": {
    "id":            "string · 'iz' + seri · benzersiz · KALICI",
    "tur":           "enum[minnet, kin, soz, soylenti, borc_kani, kutsal, hastalik, miras] · KALICI",
    "kaynak":        "string · 'event_id|choice_key' ya da 'eylem:<ad>' (beg, swindle, meal, dismiss, sale, heir, camp) · KALICI",
    "dogum_gunu":    "int · total_days_elapsed · KALICI",
    "dogum_yeri":    "string · location_id ya da 'yol:<from>|<to>' · KALICI",
    "tasiyici":      { "tip": "enum[kisi, sehir, bolge, hizip, yol, yoldas, soy]", "id": "string" },
    "bedel_odeyen":  "string|null · karakter kimliği ya da crew adı; {bedel} bunu doldurur · KALICI",
    "yon":           "int · +1 (lehine) | -1 (aleyhine) · KALICI",
    "siddet":        "float 0..1 · başlangıç değeri türe göre (§G) · KALICI",
    "gecikme":       "enum[ani, sefer, kisa, uzun, kusak] · KALICI",
    "olgunluk_gunu": "int · bu günden önce geri dönemez · KALICI",
    "sonme":         "float · gün başına şiddet kaybı; kusak izinde 0 · KALICI",
    "yayilma":       "int · 0 yayılmaz | N = N atlama (komşu yerleşim) · KALICI",
    "bilenler":      "string[] · izin ulaştığı location_id'ler (yayılma sonucu) · KALICI, en çok 8",
    "donus":         "enum[kart, yanki, fiyat, kapi, yuz, teklif, ret, dusman, aday, miras] · KALICI",
    "donus_karti":   "string|null · event_id; yoksa GeriDonusSecici türden seçer · KALICI",
    "okunur":        { "defter": "çeviri anahtarı|null", "replik": "çeviri anahtarı|null", "isaret": "enum[yok, yuz, kapi, fiyat]" },
    "durum":         "enum[acik, olgun, dondu, sondu, miras] · KALICI"
  }
}
```

- **Kim yazar:** `iz_birak` (tek giriş noktası). **Kim okur:** `GeriDonusSecici`, `build_event_context`,
  `MarketPricing`, `People`, defter ekranı, `RoadDirector`.
- **Kayıt maliyeti:** açık iz tavanı 15 (§D-İ3) + son 12 kapanmış iz (okunabilirlik için) + kuşak izi ≤ 6.
  İz başına ~260 bayt JSON → en çok ~9 KB. Kayıt yalnız şehirde yazıldığı için ek G/Ç yok.
- **Göç:** `SAVE_VERSION` 4 → 5. Eski kayıtta `izler` yoksa boş dizi; var olan bayrak zincirleri
  (`stowaway_helped`, `wanderer_scorned`, `deserters_hidden`...) **dokunulmadan** çalışmaya devam eder.

### C.2 Kişide Ruh alanları (`CharacterData`'ya eklenir)

```json
{
  "Ruh": {
    "kabuk":      "float 0..6 · adım 0,25 · varsayılan 0 · KALICI · yazar: TaniklikIsleyici",
    "catlak":     "float 0..6 · adım 0,25 · varsayılan geçmişe göre (§D-R1) · KALICI · yazar: TaniklikIsleyici",
    "hal":        "enum[diri, yorgun, kati, sonuk, tas, gidici] · KALICI · yazar: HalMakinesi",
    "hal_gunu":   "int · hâle girilen gün (histerezis sayacı) · KALICI",
    "son_tanik":  "string · son işlenen tanıklık türü (ateş başı anı için) · KALICI",
    "lakap":      "string|null · yalnız lider ve eski liderler; çeviri anahtarı · KALICI"
  }
}
```

- Okuyanlar: `BedelTasiyiciSecici`, `apply_event_stress` (Kabuk kalkanı), `get_break_departure_chance`
  (`gidici`), `CompanionLife` (bağ kazanımı), kadro ve karakter ekranı (yalnız duruş ve replik, sayı yok),
  `AtesBasi`.
- Kişi başına 6 alan, ~90 bayt.

### C.3 Yeni etki türleri (`EventEffect.Type`'a dört ek)

| Tür | `amount` | `text_value` | Ne yapar | Neden var olanlarla olmuyor |
|---|---|---|---|---|
| `BEDEL` | etkinin büyüklüğü | `"<etki>|<aday kuralı>"` örn. `"PARTY_HP|en_kirgin"`, `"STRESS|bagi_olan"`, `"LEAVE_BEHIND|yemini_yok"` | Asıl etkiyi `BedelTasiyiciSecici`'nin seçtiği kişiye uygular ve `{bedel}` adını doldurur. | `PARTY_HP` yalnız `weakest`/stat/lider seçebiliyor; bağ, kırgınlık, geçmiş, yemin okunamıyor (§A-8). |
| `IZ_BIRAK` | şiddet ×100 | `"<tur>|<tasiyici tipi>|<gecikme>|<donus>[|<donus_karti>]"` | Tek bir iz doğurur. | `SET_FLAG`+`UNLOCK_EVENT` taşıyıcı, şiddet, sönme ve yayılma taşımıyor. |
| `RUH` | ±adım ×4 (1 = 0,25) | `"<eksen>|<kim>"` eksen: `kabuk`/`catlak`; kim: `bedel`, `tanik`, `lider`, `hepsi` | Ekseni oynatır. | `STRESS` uçucu; `GRANT_TRAIT` ani ve ikili. |
| `SOZ` | vade (gün) | `"<kime tip>:<id>|<ne>|<miktar>"` ne: `erzak`, `altin`, `teslim`, `donus` | Vadeli bir söz izi açar; tutulursa minnet, bozulursa yayılan kin. | Bugünkü sözler bayrak; vadesi ve tanığı yok (§A-15). |

Dördü de **olayların öldürmeme kuralına** uyar: `BEDEL` yoluyla gelen `PARTY_HP` yine 1'de kenetlenir.

### C.4 Olay bağlamına eklenen anahtarlar (`build_event_context`)

| Anahtar | Tip | Anlamı |
|---|---|---|
| `iz_minnet_burada`, `iz_kin_burada` | float 0..1 | Bulunulan/gidilen yerde bilinen en güçlü minnet/kin izinin şiddeti. |
| `iz_soz_vadesi` | int | En yakın sözün vadesine kalan gün (yoksa 999). |
| `iz_acik` | int | Açık iz sayısı. |
| `iz_yolda_olu` | int | Bu yolda defterdeki ölü sayısı (`route_memory.deaths`). |
| `huy` | int −2..+2 | Kervanın huyu: −2 Eli Kanlı … +2 Eli Açık (§D-R5). |
| `ruh_kati`, `ruh_sonuk` | int | O hâldeki yoldaş sayısı. |
| `lider_kabuk`, `lider_catlak` | float | Liderin eksenleri. |
| `bos_yer` | int | Kampta hâlâ yeri tutulan (son 30 günde giden) kişi sayısı. |
| `sehir_ruhu` | int 0..3 | 0 Tok, 1 Dayanıyor, 2 Aç, 3 Kırılmış. |
| `yanki` | int | Bu kartın daha önce kaç kez cevaplandığı (kuşak boyunca). |
| `yanki_secim` | string | Son verilen cevabın `choice_key`'i. |
| `en_kirgin_var`, `bagli_cift_var` | bool | Bedel seçicinin aday bulup bulmadığı (seçeneği kilitlemek için). |

### C.5 Şehrin ruhu (türetilir, saklanmaz)

```json
{
  "SehirRuhu": {
    "bant": "enum[tok ≥60, dayaniyor 30..59, ac 15..29, kirilmis <15] · city_morale'den · SAKLANMAZ",
    "kapi": "enum[acik, kosullu, kapali] · bant + iz_kin_burada'dan · SAKLANMAZ",
    "aday_hali": "catlak başlangıcı +0/+1/+2/+3 (banda göre) · işe alınan adayın doğuşunda yazılır"
  }
}
```

### C.6 Kervan düzeyinde saklananlar (`GameSession`'a eklenir)

```json
{
  "izler":        "Iz[] · açık ≤15 + kapanmış ≤12 + kuşak ≤6 · KALICI",
  "iz_serisi":    "int · KALICI",
  "yankilar":     "{ event_id: { 'n': int, 'secim': string, 'gun': int } } · KALICI, soy boyunca",
  "bos_yerler":   "[{ 'ad': string, 'gun': int, 'nasil': enum[oldu, gitti, birakildi, kovuldu], 'bagli': string[] }] · ≤4 · KALICI",
  "huy_puani":    "float −10..+10 · KALICI (huy bunun bandıdır)",
  "agir_an_gunu": "int[] · son 5 ağır anın günü (boğulma önleyici) · KALICI",
  "lakaplar":     "[{ 'kusak': int, 'ad': string, 'lakap': string }] · KALICI"
}
```

---

## §D · TETİKLEME MANTIĞI

Sözde kod dilden bağımsızdır. Bütün zarlar `hash(caravan_name | gün | anahtar)` tohumludur: kaydı yükleyip
yeniden denemek sonucu değiştirmez (projenin var olan kuralı).

### D.1 Ahlak

#### D-A1 · İkilemin kontrol listesi (bir kart bu beşini taşımıyorsa ikilem değildir)

```
IKILEM_MI(kart):
  1. en az iki seçeneğin bedeli FARKLI TÜRDE (biri insan, biri mal/zaman/ad/gelecek)
  2. hiçbir seçenek bedelsiz değil  (yalnız MORALE ± olan seçenek bedelsiz sayılır)
  3. en az bir seçeneğin bedeli ADI OLAN birine düşüyor  (BEDEL etkisi ya da kişi taşıyıcılı iz)
  4. en az bir seçenek gecikmeli iz bırakıyor  (IZ_BIRAK, gecikme ≥ 'sefer')
  5. beceri kontrolü varsa başarısı bedeli SİLMİYOR, yalnız KÜÇÜLTÜYOR ya da BAŞKASINA KAYDIRIYOR
```

Bugünkü katalogda bu beşini taşıyan kart: 0. Dördünü taşıyan: 9 (`evt_leave_the_wounded`,
`evt_elder_burden`, `evt_wagon_for_town`, `evt_hunger_riot`, `evt_faith_tribunal`, `evt_deserter_plea`,
`evt_untouched_village`, `evt_penitent_procession`, `evt_starving_roadside`). İlk dilim bunları tamamlar.

#### D-A2 · Bedel taşıyıcısı seçici

```
BEDEL_TASIYICI_SEC(kural, aday_havuzu):
  # aday_havuzu: adı olan yoldaşlar (lider hariç) + adı yazılı tayfa elleri (crew_names)
  # Havuz boşsa taşıyıcı "gelecekteki sen"dir: bedel borç, söz ya da lakap olarak yazılır.
  HER aday İÇİN puan = 0
    kural == 'en_zayif'    : puan += 3 * (1 - can_orani)
    kural == 'en_kirgin'   : puan += 2 * kirginlik_agirligi          # grievances
    kural == 'bagi_olan'   : puan += 2 * en_guclu_bag(aday)           # bonds ≥ FRIENDS_AT
    kural == 'yemini_yok'  : puan += (yeminli ? -99 : 1)              # OATH_*: yeminliyi bırakamazsın
    kural == 'gecmisi_uyan': puan += (backstory == kartin_gecmisi ? 3 : 0)
    # her kuralda ortak düzeltmeler:
    puan += 0.5 * (MAX_RAPPORT - rapport)        # lidere uzak olan daha kolay harcanır
    puan += 1.0  EĞER hal ∈ {sonuk, gidici}
    puan -= 1.5  EĞER son 10 günde bedel ödediyse  # aynı kişi üst üste ödemez
    puan -= 2.0  EĞER tek kalan yoldaşsa VE kural != 'en_zayif'
  DÖN en yüksek puanlı aday        # eşitlikte: kervanda en kısa süre kalmış olan
  # Seçim RASTGELE DEĞİL: aynı durum aynı kişiyi verir. Oyuncu "neden o" sorusunu kendi kurabilir.
```

Kart açıldığında seçenek metni taşıyıcının adını **önceden** gösterir (`{bedel}`): oyuncu kimin ödeyeceğini
seçmeden önce bilir. Bilmeden ödetmek ikilem değil tuzaktır.

#### D-A3 · Sertlik kapısı (kıtlıkla sertleşme)

```
KOSUL sertlik_bandi:
  s = scarcity_here                       # Scarcity: bölge tabanı + mevsim + sürüklenme
  bant = 0 EĞER s < 0.30 | 1 EĞER s < 0.50 | 2 EĞER s < 0.70 | 3 AKSİ

SERTLESTIR(kart, bant):
  bant ≥ 1 : en ucuz seçeneğin kaynak bedeli × 1.25
  bant ≥ 2 : 'bedelsiz çıkış' türü seçenek (yalnız MORALE/STRESS) bir İZ kazanır
             (tur=soylenti, siddet 0.25, gecikme=kisa): "geçip gitti" de bir cevaptır
  bant ≥ 3 : beceri kontrolünün tavanı −10 (kandıracak kadar tok adam kalmadı)
             VE BEDEL etkilerinin büyüklüğü × 1.3
  # Hiçbir bantta seçenek SİLİNMEZ. Kıtlık seçeneği kaldırmaz, pahalılaştırır (A1, A5).
```

#### D-A4 · Yankı çözücü (tekrar etmeme kuralı)

```
YANKI_COZ(kart):
  n = yankilar[kart.id].n   (yoksa 0)
  n == 0 : kartı olduğu gibi ver
  n ≥ 1  : VARYANT = kart.id + '_yanki'      # varsa
           varyant yoksa → genel yankı kuralı:
             - gövde metninin sonuna taşıyıcının ağzından bir cümle eklenir (anahtar: <id>_YANKI_<secim>)
             - son seçilen seçeneğin bedeli × 1.3 ("geçen sefer de öyle demiştin")
             - seçilmemiş seçeneklerden birinin bedeli × 0.8 (dünya öteki cevabı bekliyor)
  n ≥ 3  : kartın ağırlığı × 0.25 ve artık yalnız 'iz_*' koşulu sağlanıyorsa gelir
  SEÇİMDEN SONRA: yankilar[kart.id] = { n+1, secim, gün }
AGIRLIK  yankı varyantı  x SEEN_CARD_WEIGHT yerine x 1.4   # görülmüş ama değişmiş kart yeni sayılır
```

İlk dilimde yazılacak özel yankı varyantları (22 kart): katalogda en çok dönen ve ahlaki ağırlığı olan
kartlar — `evt_refugee_column`, `evt_road_wanderer`, `evt_stowaway`, `evt_sick_merchant`,
`evt_abandoned_wagon`, `evt_mutiny`, `evt_customs_checkpoint`, `evt_guard_patrol`, `evt_military_convoy`,
`evt_pilgrim_encounter`, `evt_penitent_procession`, `evt_starving_roadside`, `evt_untouched_village`,
`evt_village_provisions`, `evt_provision_raid`, `evt_cargo_toll`, `evt_deserter_levy`, `evt_bandit_ambush`,
`evt_grave_on_the_road`, `evt_party_theft`, `evt_troubled_night`, `evt_spoiled_provisions`.

#### D-A5 · Söz

```
SOZ_VER(kime, ne, miktar, vade):
  iz = IZ(tur=soz, tasiyici=kime, yon=0, siddet=0.5, gecikme=vadeye göre, olgunluk=bugün+vade,
          sonme=0, yayilma=0, donus=kapi)
  defter: KIND_TRACE satırı ("<kime>'ye <ne> sözü, <vade> gün")
SOZ_KONTROL (her şehir varışında ve her gün sonunda):
  söz taşıyıcısının yerindeysen VE elinde yeterince <ne> varsa → oyuncuya SOR (otomatik ödenmez)
     tutuldu : iz.tur=minnet, yon=+1, siddet=0.7, yayilma=1 ; lider catlak −0.5 ; tanıkların rapport +1
     ertelendi (bir kez): vade +10 gün, siddet −0.1
  bugün > olgunluk VE tutulmadı:
     iz.tur=kin, yon=−1, siddet=0.8, yayilma=2, sonme=0.004 ; lider kabuk +0.5
     tanık yoldaşlardan yeminli olan varsa: GRIEVANCE_OATH_BROKEN (var olan kural)
SINIR  aynı anda en çok 3 açık söz. Dördüncü söz seçeneği sebebiyle kilitli:
       "Bu kadar söz bir ağza sığmaz."
```

### D.2 Ruh

#### D-R1 · Başlangıç ve eksenlerin anlamı

```
dogus(kisi):
  kabuk  = 0
  catlak = 0  + (backstory ∈ {widow, hungry} ? 1 : 0)  + sehir_ruhu_aday_hali   # 0..3
  hal    = diri
```

- **Kabuk**: görüp de bir şey yapmamanın, yaptırmanın, işe yarayan zalimliğin tortusu. *Yararlıdır.*
- **Çatlak**: çaresizliğin, kaybın, boşa giden iyiliğin tortusu. *Yararsızdır ama insandır.*

#### D-R2 · Tanıklık işleyici (gün sonunda, `day_beats` ve o günün `BEDEL`/`IZ` kayıtlarından)

| Tanıklık | Ödeyen | Tanık (aynı kampta) | Lider |
|---|---|---|---|
| Biri bedel ödedi, kervan kazandı (`BEAT_PRICE`, sonuç iyi) | Çatlak +0,5 | Kabuk +0,25 | Kabuk +0,5 |
| Biri bedel ödedi, boşa gitti | Çatlak +1 | Çatlak +0,5 | Çatlak +0,5 |
| Merhamet edildi, bedeli kervan ödedi (erzak, gün, altın) | — | Kabuk −0,25 | Kabuk −0,5 |
| Aç yabancıya sırt çevrildi (`sertlik_bandi ≥ 2`) | — | Kabuk +0,25; bağlı geçmişi olan (hungry/widow) Çatlak +0,5 | Kabuk +0,5 |
| Yoldaş öldü (`BEAT_DEATH`) | — | Çatlak +0,5; dostu (bağ ≥ 2) +1 | Çatlak +0,5 |
| Yoldaş geride bırakıldı / kovuldu | — | Çatlak +0,25; dostu +0,75 | Kabuk +0,75 |
| Tayfadan biri açlıktan gitti/öldü | — | Çatlak +0,25 | Kabuk +0,25 (ilk kez), Çatlak +0,5 (üçüncü ve sonrası) |
| Bir iz **iyi** döndü (`BEAT_RETURN`, yon +1) | — | Çatlak −1 (izin doğumunda kervandaysa), yoksa −0,25 | Çatlak −0,5 |
| Bir iz **kötü** döndü | — | Çatlak +0,25 | Kabuk +0,25 |
| Söz tutuldu | — | rapport +1 | Çatlak −0,5 |
| Sessiz gün + ateş + hikâye (`CAMP_ACTION_TALES`) | — | — | Kabuk −0,25 (en çok haftada bir) |

Günlük tavan: bir kişide eksen başına ±1,5. Fazlası ertesi güne **taşınmaz** (boğulma önleyici).

#### D-R3 · Hâl makinesi

```
              stres>60, 5 gün                       kabuk ≥ 4
   ┌──────┐ ───────────────────> ┌────────┐      ┌─────────────> ┌──────┐   kabuk = 6    ┌─────┐
   │ DİRİ │                      │ YORGUN │      │               │ KATI │ ─────────────> │ TAŞ │  (dönüş yok)
   └──────┘ <─────────────────── └────────┘      │               └──────┘                └─────┘
       │        stres<40, 3 gün                  │   <── kabuk < 3 (histerezis: girmek 4, çıkmak 3)
       │                                         │
       ├─────────────────────────────────────────┘
       │      catlak ≥ 4
       └───────────────────────> ┌───────┐   catlak = 6 VE dostu yok VE yeminli değil   ┌────────┐
                                 │ SÖNÜK │ ───────────────────────────────────────────> │ GİDİCİ │ (dönüş yok)
                                 └───────┘ <── catlak < 3                               └────────┘
```

| Hâl | Girdiği | Etkisi (hepsi var olan sayaçlara biner) | Çıkışı |
|---|---|---|---|
| **Diri** | varsayılan | — | — |
| **Yorgun** | stres > 60, art arda 5 yol günü | `DAILY_STRESS_GAIN` × 1,15; kamp eylemi verimi −%20 | stres < 40, art arda 3 gün (şehir geceleri sayılır) |
| **Katı** | Kabuk ≥ 4 | olaydan gelen stres artışı × 0,5; rapport kazanımı × 0,5; bağ kazanımı × 0,5; `CAMP_ACTION_TALES` ona işlemez; Karizma kontrolünde −1 etkin puan | Kabuk < 3 |
| **Sönük** | Çatlak ≥ 4 | yorgunluk artışı × 1,25; görev verimi −%15; savaşta kırılma eşiği −10 (var olan `BREAK_*` kipleri) | Çatlak < 3 |
| **Taş** | Kabuk = 6 | Katı'nın etkileri kalıcı; stres hiç 40'ı aşmaz; bağları 0'a çekilir (dostu da hasmı da kalmaz); `evt_mutiny` ailesine hiç katılmaz; bedel taşıyıcısı olarak **kendini öne sürer** ("ben yaparım") | yok |
| **Gidici** | Çatlak = 6, dostu (bağ ≥ 2) yok, yeminli değil | bir sonraki şehirde ayrılır; yolda ayrılmaz (A2: yolda bırakıp gitmek ölüm kapısı açar) | şehre varmadan önce bir iz iyi dönerse ya da biri dost olursa Sönük'e iner |

**Kişilik sürüklenmesi** (var olan kırılma huyu sistemi genişler, yerine geçmez): bir kişi Katı'ya **ilk**
girdiğinde ve yuvası varsa (`MAX_TRAITS=3`) %50 ile `prudent` (soğukkanlı okuma), %50 ile `off_putting`
kazanır; Sönük'e ilk girdiğinde %50 `wavering_faith`, %50 `reassuring` (acıyı tanıyan teselli eder).
Zar kişinin kimliğinden tohumlu. Taş `off_putting`'i zorunlu kılar; Gidici huy vermez.

#### D-R4 · Lider

```
Liderin eksenleri aynı tabloyla oynar. Liderde HAL YOKTUR; yalnız maliyet çarpanları vardır:
  merhamet seçeneğinin lider stresi  += round(lider_kabuk)          # "eli gitmiyor"
  sert seçeneğin lider stresi        += round(lider_catlak)         # "içi götürmüyor"
  lider_kabuk ≥ 4 : blöf ve tehdit kontrollerinde +1 etkin puan     # soğuk yüz
  lider_catlak ≥ 4: teselli/ikna kontrollerinde +1 etkin puan       # anlayan yüz
  Sükûnet (§A-12): savaşta her yoldaşın kırılma eşiği += 2 × (liderin etkin Karizması − 5),
                   tavan ±10; Taş bundan etkilenmez.
Hiçbir seçenek liderin ekseni yüzünden KAPANMAZ. Oyuncu her zaman her şeyi seçebilir; yalnız bedeli değişir.
```

#### D-R5 · Kervanın huyu (Ruh → İz)

```
huy_puani  her bedelli kararda oynar:  merhamet +1, sertlik −1, vurgun −1,5, tutulan söz +1,5, bozulan söz −2
           günde 0,02 sıfıra doğru söner (yaklaşık 50 günde 1 puan)
huy = −2 (≤ −6) Eli Kanlı | −1 (≤ −2,5) Eli Sıkı | 0 | +1 (≥ 2,5) Eli Açık | +2 (≥ 6) Kapısı Açık
BANT DEĞİŞTİĞİNDE: bölge taşıyıcılı bir SÖYLENTİ izi doğar (siddet 0.5, yayilma 3, sonme 0.006)
```

| Huy | Lehine | Aleyhine |
|---|---|---|
| **Eli Açık / Kapısı Açık** | aday havuzunda gönüllü çıkar (ücretsiz, Çatlak'ı yüksek); `People` gönlü +1; dilencilik verimi +%25; aç şehir kapısı açık | yolda yardım isteyen kart ağırlığı × 1,4; yağmacı "veren kervan" bilir: fidye tabanı +%15; `raid_deaf` payı +0,05 |
| **Eli Sıkı** | yağmacı pazarlığa yanaşmaz ama az ister: fidye tabanı −%15; yardım kartı ağırlığı × 0,7 | aday havuzu daralır (−1 aday); `People` gönlü −1; kafile/kervansaray ücreti +%20 |
| **Eli Kanlı** | haydut kartı ağırlığı × 0,75; blöf tavanı +10; tahsildar ve kethüda kartlarında "çekinir" seçeneği | aç şehir kapısı koşullu; gönüllü hiç çıkmaz; kontrat panosunda teklif −1; dost huylu NPC'ler adını sorar ve susar |

#### D-R6 · Şehrin ruhu ↔ kervanın ruhu

```
SEHRE_GIRIS(sehir):
  bant = sehir_ruhu(sehir)
  bant == ac        : her yoldaş stres +2 ; Katı/Taş olanlar 0 ; geçmişi 'hungry' olan catlak +0.25
  bant == kirilmis  : her yoldaş stres +4 ; Katı 2, Taş 0 ; lider kabuk +0.25 (alışırsın) ; geçmişi uyan catlak +0.5
  bant == tok       : her yoldaş stres −2 (bir kez, varışta)
YUK_INDIRINCE(sehir, yiyecek_birimi):
  city_morale += MORALE_PER_FOOD × birim   (var olan kural, tavan MORALE_FOOD_CAP)
  bant ∈ {ac, kirilmis} VE birim ≥ TRADE_MERCY_MIN_QUANTITY VE fiyat ≤ taban fiyat:
      IZ(minnet, sehir, yon +1, siddet 0.4 + 0.1 × bant, gecikme=kisa, yayilma=1)
      tanık yoldaşlar: catlak −0.25
  fiyat > taban × 1.3 (vurgun):
      IZ(kin, sehir, yon −1, siddet 0.5, gecikme=kisa, yayilma=2) ; huy_puani −1.5 ; lider kabuk +0.25
ADAY(sehir):  işe alınan kişinin catlak başlangıcı += bant (0..3) ; bant == kirilmis ise ücret × 0.5
              (aç şehrin adamı ucuzdur ve yarı kırıktır)
```

#### D-R7 · Ateş başı: kampın sessiz anı

```
ATES_BASI(kamp):
  # Her kampta EN ÇOK bir sessiz an. Zar yok; öncelik sırası var. İlk uyan gösterilir.
  1. bos_yer > 0 VE son gösterimden ≥ 3 kamp     → "yeri hâlâ açık": ateşin başında bir boşluk bırakılır
  2. biri bugün bedel ödedi                       → ödeyen ateşe en son gelir; dostu varsa yanına oturur
  3. hal değişti (bugün)                          → o hâlin duruşu (Katı: sırtı ateşe; Sönük: tabağı dolu)
  4. bugün bir iz iyi döndü                       → biri ötekinin pabucunu onarır / tayınını böler
  5. hasım çift (bağ ≤ −2) aynı ateşte            → aralarına biri oturur ya da oturmaz
  6. hiçbiri                                      → CompanionLife.roll_action (var olan %6 zar)
  Gösterim: figürlerin oturuş yeri ve duruşu + günlükte BİR cümle (BEAT_QUIET). Sayı yok, kutu yok.
```

**Boş Yer:** adı olan biri öldüğünde, bırakıldığında, kovulduğunda ya da gittiğinde `bos_yerler`'e 30 gün
(`SHARED_GRIEF_DAYS`) için yazılır. O süre boyunca: kampta yeri boş bırakılır; dostlarının günlük stresi +1
(var olan `SHARED_GRIEF_STRESS` yerine değil, onun görünen yüzü); `CAMP_ACTION_TALES` seçilirse hikâye onun
hikâyesi olur, deftere `KIND_STORY` düşer ve Boş Yer 10 gün erken kapanır. Kadro 1'e indiğinde bile Ruh'un
sahnesi boş kalmaz: liderin yanındaki boşluklar konuşur.

### D.3 İz

#### D-İ1 · Doğum

```
IZ_BIRAK(tur, tasiyici, yon, siddet, gecikme, donus, donus_karti=null):
  açık iz sayısı ≥ 15 → en zayıf (siddet × kalan ömür) 'ani/sefer' izi söndür; yoksa yeni izi YAZMA
  aynı kaynak + aynı taşıyıcı için açık iz varsa → yenisini açma, eskisinin siddet'ini +0.15 (tavan 1)
  olgunluk_gunu = bugün + GECIKME[gecikme].en_az
  sonme, yayilma = TUR_TABLOSU[tur]   (§G)
  defter satırı: yalnız gecikme ≥ 'kisa' VE siddet ≥ 0.4 ise (defter fişe dönmesin)

GECIKME = { ani: 0 gün | sefer: aynı sefer içinde, ≥ 1 gün | kisa: 15–70 gün (2–5 sefer)
          | uzun: 130–400 gün (10–30 sefer) | kusak: yalnız appoint_heir'den sonra }
ACIK_IZ_TAVANI = { sefer: 3 | kisa: 5 | uzun: 4 | kusak: 6 (miras) | toplam açık: 15 }
```

#### D-İ2 · Yayılma (söz yol alır)

```
IZ_YAY (her gün sonunda, yayilma > 0 olan izler için):
  hız = 1 atlama / 12 gün              # bir söylenti bir komşu yerleşime 12 günde varır
  her atlamada siddet × 0.75
  yön: önce kervansaraylara (NEWS_CARAVANSERAI_SHARE mantığı: her yerden yolcu var), sonra şehirlere
  SINIR: Avuçiçi (ahit) dışarıdan söylenti almaz; Gokyurt (gocebe) yalnız Orbeyan üzerinden alır;
         bölge sınırını geçen iz bir kez daha × 0.75  ("tanınma mesafelidir": kendi bölgende bilinir,
         komşuda duyulmuştur, uzakta hiçbir şey ifade etmez)
  bilenler dizisi 8'e varınca yayılma durur
```

#### D-İ3 · Olgunlaşma ve geri dönüş

```
GERI_DONUS_SEC (her gün sonunda ve her şehir varışında):
  adaylar = durum == acik VE bugün ≥ olgunluk_gunu VE kervan izin 'bilenler'inden birinde ya da
            taşıyıcısının yanında (kişi: aynı şehir; yol: aynı yol; bölge: aynı bölge; yoldaş: kervanda)
  adaylar boşsa DÖN
  BOĞULMA ÖNLEYİCİ:  bugün zaten bir ağır an yaşandıysa DÖN
                     son 5 günde 3 ağır an yaşandıysa DÖN
  seçilen = en yüksek (siddet × yön_dengesi)
     yön_dengesi: son dönen iz kötüyse iyi olana × 1.5, iyiyse kötü olana × 1.2   # ritim (§A-4)
  DONUS biçimine göre:
     kart    → RoadDirector'a iz_agirligi (x 2.5) ile donus_karti verilir
     yanki   → kartın yankı varyantı zorunlu varyant olur
     fiyat   → MarketPricing LAYER_EVENT: yon × (4% + 8% × siddet), süre 20 gün
     kapi    → şehir kapısı: yon −1 → koşullu giriş (bedel: yük ya da gün); yon +1 → konaklama bedava (1 gece)
     yuz     → People'dan bir kişi kapıda/tavernada bekler; ilk repliği izi adıyla anar
     teklif  → kontrat panosuna adı olan bir kişiden özel teklif (+1 teklif, RUSH değil, ücret × 1.2)
     ret     → bir hizmet sebebiyle kapanır (hekim, kafile, kredi, işe alma) — 1 ziyaret boyunca
     dusman  → yoldaki düşman kadrosuna tanıdık bir yüz katılır (Y-E13: dağılan el)
     aday    → işe alma havuzuna ücretsiz bir gönüllü (minnet izi)
     miras   → yalnız kuşak devrinde açılır
  durum = dondu ; BEAT_RETURN günün izlerine girer ; Ruh tanıklığı işler
  defterde açık hesabın YANINA karşılığı yazılır (üstü çizilmez)

IZ_SONME (her gün): siddet −= sonme ; siddet ≤ 0.05 → durum = sondu
   sönen iz defterde kalır: "kimse hatırlamadı" (çeviri anahtarı). Sönmek de bir sonuçtur.
```

#### D-İ4 · Kuşak devri

```
APPOINT_HEIR sonrası:
  lakap = LAKAP_SEC(huy_puani, lider_kabuk, lider_catlak, tutulan/bozulan söz, gömülen/bırakılan sayısı)
          # 12 lakaplık tablo; lonca kâtibi yazar, anlatıcı değil
  defter: KIND_EPITHET ("<ad>, <lakap>")
  açık izlerden siddet ≥ 0.5 olanlar → gecikme=kusak, tasiyici=soy, sonme=0, durum=miras  (en çok 6)
  varis: kabuk/catlak'ı kendi değerinde kalır; ama ilk 30 gün "babasının oğlu" çarpanı:
         huy_puani = önceki × 0.5  (ad temizlenmez, yarıya iner)
  kuşak izi yalnız BİR KEZ döner ve dönünce söner.
```

### D.4 Çatışma çözümü ve ritim

```
ÖNCELİK (aynı gün birden çok şey tetiklenirse):
  1. ölüm kapıları (savaş, açlık, vagon)        — her zaman önce
  2. domino zincirinin açık halkası             — DOMINO_WEIGHT korunur
  3. savaş garantisi (combat_due)               — korunur
  4. olgun iz geri dönüşü
  5. yankı varyantı
  6. sıradan çekiliş

AĞIR AN = BEDEL etkisi taşıyan kart | iz geri dönüşü (yon −1) | hâl geçişi (Taş/Gidici) | ölüm
BOĞULMA ÖNLEYİCİ:  günde ≤ 1 ağır an ; 5 günde ≤ 3 ağır an ; aynı kişi 10 günde ≤ 1 kez bedel öder
SESSİZLİK KOTASI:  her 4 yol gününde en az 1 kartsız gün garanti (RoadDirector'ın QUIET rampası
                   bunu zaten yapıyor; iz dönüşleri bu günü DELEMEZ)
İYİLİK KOTASI:     son iyi dönüşten bu yana 18 gün geçtiyse ve açık +1 yönlü olgun iz varsa,
                   o iz boğulma önleyiciyi bekletmeden döner  (§A-4: "iyi bir şey arası")
```

---

## §E · KELEBEK ETKİSİ MATRİSİ

Etiket: **İB** iyi niyetin bedeli · **ZÖ** zalimliğin ödülü · **N** nötr/karışık.
Gecikme: ani · sefer · kısa (2–5 sefer) · **uzun** (10+ sefer) · **kuşak**.
Her satırın sonunda sönme koşulu var; kuşak izleri bir kez döner ve söner.

| # | Tetikleyen karar | Anında görünen | Gizli iz (veri) | Gecikme | Geri dönüş biçimi | Taşıyıcı | Oyuncu nereden anlar | Şiddet · sönme | Etiket |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `evt_refugee_column`: erzak paylaş (−6) | moral +, itibar + | minnet, yon +1 | kısa | **aday**: kafileden biri bir sonraki şehirde kapında, ücretsiz; Çatlak 3 ile gelir | bölge | Adayın ilk sözü kafileyi anar; defterde açık hesabın yanına "geldi" | 0,5 · 0,006/gün (≈80 günde söner) | İB (bir ağız daha) |
| 2 | Aynı kart: taşıdıklarını ucuza al | mal, ticaret lekesi riski | kin, yon −1, yayılma 2 | kısa | **fiyat**: o bölgede satış −%8, 20 gün | bölge | Pazarda tüccar "senden alan aç kaldı derler" der; fiyat işareti | 0,5 · 0,005 | ZÖ (mal ucuza geldi) |
| 3 | Aynı kart: görmezden gel (kıtlık bandı ≥ 2) | moral − | söylenti, yon −1 | kısa | **yankı**: kart ikinci gelişinde kolonda geçen sefer bıraktığın biri var, tek başına | yol | Kartın gövdesindeki yeni cümle; tanıyan yoldaşın repliği | 0,25 · 0,008 | N |
| 4 | `evt_penitent_procession`: kıtlık fiyatından sat (+30 GG) | altın | kin + `profiteering_sales` | **uzun** | **ret**: Septisist şehirde kilisenin hekimi bir ziyaret bakmaz | hizip (kilise) | Hekim kapıda alayı adıyla anar | 0,6 · 0,002 (≈300 gün) | ZÖ |
| 5 | Aynı kart: ekmek ver (−6) | itibar +, stres − | minnet | **uzun** | **kapı**: Avuçiçi yolunda kafile ücretsiz alır (Septisist değilsen bile bir kez) | hizip (kilise) | Kafile başı ekmeği verenin adını söyler | 0,5 · 0,002 | İB (erzak gitti, dönüşü çok geç) |
| 6 | `evt_untouched_village`: kapıyı zorla | erzak, leke, savaş | kin, yayılma 3 | **uzun** | **kart**: o bölgede köy durağı kartları kapı açmaz ("senin gibisi geldi") — 2 kez | bölge | Köylü kapının arkasından adı söyler; defter | 0,8 · 0,002 | ZÖ (erzak şimdi) |
| 7 | Aynı kart: hastanı içeri almalarını iste, başarı | can + | hastalık izi (köy artık "uğramamış" değil) | **kuşak** | **miras**: varis o köyün yerinde boş bir köy bulur; bekçi kadın mezarları sayıyor | yol | Yıkıntı durağı + mezar sayısı; bekçinin tek cümlesi | 1,0 · 0 | İB (iyileşen bir kişi, sönen bir köy) |
| 8 | `evt_wagon_for_town`: bir vagonu ver | vagon −, şehir hâli + | minnet, yayılma 1 | kısa | **teklif**: o şehrin loncasından özel kontrat (ücret × 1,2) | şehir | Lonca kişisi "verdiğin araba hâlâ kapıda" der | 0,7 · 0,004 | İB (kapasite gitti) |
| 9 | Aynı kart: kıtlık fiyatından sat (+70) | altın, şehir hâli + | kin (şehir), minnet (kethüda) | kısa | **fiyat**: o şehirde alış +%10 · **yüz**: kethüda sana borçlu, bir sefer vergi yok | şehir + kişi | İki ayrı ses: pazar ve kethüda | 0,5 · 0,005 | ZÖ |
| 10 | Aynı kart: reddet | stres | kin, yayılma 1 | sefer | **kapı**: varışta koşullu giriş (yük ya da bir gün bekle) | şehir | Kapıdaki muhafız yol başındaki konuşmayı aktarır | 0,4 · 0,010 | N |
| 11 | `evt_hunger_riot`: kalabalığı yarıp geç | savaş, itibar − | kin, yayılma 2 | **uzun** | **düşman**: o bölgenin haydut kadrosuna "kapıda dövdüğün" biri katılır; +1 düşman, bir kez | bölge | Savaş öncesi düşmanın bağırdığı tek cümle | 0,7 · 0,003 | ZÖ (o gün içeri girdin) |
| 12 | Aynı kart: erzaktan dağıt (−10) | şehir hâli + | minnet | kısa | **kapı**: o şehirde bir gece bedava konaklama; **Çatlak −0,25** tanıklara | şehir | Meyhaneci "geçen kış kapıdaydım" der | 0,6 · 0,005 | İB |
| 13 | `evt_leave_the_wounded`: köylülere bırak | `LEAVE_BEHIND`, stres | yoldaş izi | kısa | **kart** `evt_left_behind_return` (var) + yeni dal: iyileştiyse **aday** olarak döner, Kabuk 3 ile; iyileşmediyse mezar | yoldaş | Defterde üstü çizili adın yanına "döndü" ya da köyün adı | 0,6 · 0,004 | N (taşımak bir gün ve erzaktı) |
| 14 | `evt_elder_burden`: köyde bırak | `LEAVE_BEHIND` | kin (dostu olan yoldaşta) | sefer | **yüz**: dostu ertesi kampta ateşe gelmez; bağ(lider) −1; kırgınlık | yoldaş | Ateş başı: boş yer + sırtı dönük figür | 0,5 · 0,02 | ZÖ (bir ağız eksildi) |
| 15 | Aynı kart: kendi tayınını ver | lider can −, stres + | minnet (yaşlının kendisi) | kısa | **yüz**: yaşlı bir sonraki tehlikeli kartta yolu bilir: `DANGER` −%10 o sefer | yoldaş | Yaşlının repliği; tehlike dökümünde yeni satır | 0,5 · 0,01 | İB (lider zayıfladı) |
| 16 | `evt_faith_tribunal`: teslim et | `LEAVE_BEHIND`, itibar + | kin (kervan içi), minnet (kilise) | **uzun** | **yanki**: kart ikinci gelişinde suçlanan sensin; geçen sefer teslim ettiğin için kimse seni savunmaz (kontrol −10) | hizip + soy | Suçlayan kâtip ilk davayı okur | 0,7 · 0,002 | ZÖ (o gün dertsiz geçtin) |
| 17 | Aynı kart: onu savun, başarısız | can −, leke | minnet (yoldaş): **yemin gibi bağ** | **uzun** | **yüz**: o yoldaş Gidici olmaz; kırılma ayrılığı %0 | yoldaş | Kadro ekranında adının yanında bağ işareti | 0,8 · 0 (yoldaş kervandayken sönmez) | İB (leke ve yara) |
| 18 | `evt_deserter_plea`: sakla | erzak − | minnet + risk | sefer | **kart** `evt_deserter_search` (var) → kurtulurlarsa **aday**/kılıç (var) + yeni: bölük komutanında kin | yol + bölge | Zincir zaten okunuyor; yeni: komutanın adı deftere | 0,6 · 0,006 | İB |
| 19 | Aynı kart: karakola haber ver | itibar, stres | kin (kaçaklar) | **uzun** | **düşman**: `evt_deserter_levy` geldiğinde bölük seni tanır: blöf seçeneği kapalı, sebebiyle | bölge | Bölüğün başı "bizi satan kervan" der | 0,6 · 0,003 | N (itibar bugün, yağma yarın) |
| 20 | `evt_stowaway`: kalmasına izin ver | erzak −, bayrak | minnet | kısa | **kart** `evt_stowaway_repay` (var) + yeni: reddedersen parayı, o kişi **yüz** olur (bir şehirde lonca kâtibi) | kişi | Var olan zincir + kâtibin selamı | 0,5 · 0,005 | İB |
| 21 | Aynı kart: ilk karakolda teslim et | altın, itibar + | kin | **kuşak** | **miras**: varis, teslim edilenin çocuğuyla bir kontratta karşılaşır; teklif tuzaklı (teslim yeri haydut kervansarayı) | soy | Teklifin altındaki ad; defterde eski satırla aynı soyadı | 0,8 · 0 | ZÖ |
| 22 | `beg_in_tavern` (el açmak) | erzak, itibar −1 | söylenti, yayılma 2 | kısa | **ret**: komşu iki şehirde lonca avans vermez (1 ziyaret) | bölge | Lonca kişisi "el açan ele mal verilmez" der | 0,4 · 0,008 | N |
| 23 | `swindle_in_tavern` başarı | altın (malın 9 katı) | kin (kişi), yayılma 1 | kısa | **yüz**: dolandırılan, bir sonraki şehrin meyhanesinde seni bekliyor: ya geri öde (2 katı) ya meyhane yasağı | kişi | Meyhaneci kapıda durdurur | 0,6 · 0,006 | ZÖ |
| 24 | `apply_meal_distribution`: yalnız parti (tayfa aç) | erzak yetti | kin (tayfa), `crew_hungry_nights` | sefer | **düşman** (Y-E13): giden el, o bölgenin kaçakları arasında; kadroyu ve yükünü bilir → pusu (ilk tur düşmanın) | yol | Düşman adını söyler; defterde giden elin adı | 0,6 · 0,004 | ZÖ (parti tok kaldı) |
| 25 | Aynı: yalnız tayfa (parti aç) | parti stresi | minnet (tayfa) | kısa | **ret'in tersi**: `CREW_HIRE` fiyatı −%30, bir kez; tayfadan biri **adı olan yoldaşa** terfi eder (ücretsiz aday) | yol | Meydanda el tutarken: "adamını doyuran kervan" | 0,5 · 0,006 | İB |
| 26 | `CAMP_ACTION_EAT_SEED` (tohumluğu yemek) | erzak +6 | borç kanı | **uzun** | **fiyat**: o tohumu bekleyen şehirde (kontratın hedefi) bir sonraki hasatta buğday +%12 ve şehir hâli −6 | şehir | Tahıl tüccarı boş tarlayı anlatır; açık hesap satırı | 0,5 · 0,002 | ZÖ (bugün doydun) |
| 27 | `CAMP_ACTION_BURN_PLANKS` Kovrast/Kemersal tepelerinde | ısı +6 °C | kutsal, yon −1 | kısa | **kapı**: tepe halkı rehber vermez; o yollar `slow` (2 sefer) | bölge | Rehberin yokluğu; yol kenarında kesilmiş ağaca bağlı bez | 0,6 · 0,006 | ZÖ (kimse donmadı) |
| 28 | `evt_hunting_trip` Kirsavel çevresinde (hayvan kutsal) | et | kutsal, yon −1 | sefer | **kapı**: Kirsavel kapısında hayvan sayımı tutmaz; bir gün bekletir ya da bir hayvan ister | şehir | Kapıdaki sayıcı postu görür | 0,5 · 0,01 | N |
| 29 | `evt_forage` Tolvarin toprağında (toprak kutsal) | erzak | kutsal | sefer | **fiyat**: Tolvarin'de alış +%8; Lenart Bey'in adamı tekerleğe bakar | şehir | Kapıdaki oluğun başında replik | 0,4 · 0,012 | N |
| 30 | Ezmerak'ta dolandırıcılık / sahte muafiyet (`evt_road_warden`) | altın kurtuldu | kin + **düello hakkı** | kısa | **kart**: Kırmızı Sofra'ya çağrı: ya 2 katını öde ya şafakta dövüş (tek kişilik savaş) | şehir | Öküz Kâtibi fişi vermez | 0,8 · 0,004 | ZÖ |
| 31 | Kontratı teslim etmemek (yük eksik) | itibar −3 | kin (kontrat sahibi), sicil | kısa | **yüz** + **ret**: o kişi şehirdeki lonca kişisiyse panoda teklif −2 | kişi | Panonun başındaki kişi adı okur | 0,6 · 0,005 | N |
| 32 | Baba borcunu vadesinde ödemek | altın − | minnet (aile) | **kuşak** | **miras**: varis `LOAN_ORIGINATION` güvenilir oranla (%5) başlar | soy | Tefecinin defterinde baba adının yanındaki işaret | 0,6 · 0 | İB (erken oyunda 180 GG ağır) |
| 33 | Baba borcunu hiç ödememek | altın elde kaldı | borç kanı | **kuşak** | **miras**: varise `evt_creditor_rider` ilk seferinde gelir; borç anaparayla | soy | Atlı babanın adını söyler | 0,7 · 0 | ZÖ |
| 34 | Yağmacıya üç kez para vermek (`RAID_PATIENCE`) | geçiş | söylenti "veren kervan" | kısa | **düşman**: dördüncü çete pazarlık etmez (var) + yeni: fidye tabanı +%15, huy −1 | hizip (kardeşlik) | Reisin ilk sözü: "senin kesen açıkmış" | 0,6 · gerçek dövüşle söner | N |
| 35 | Reise haraç vermek (`CHIEF_MEMORY paid`) | geçiş | reisin çetesi büyür (var) | **uzun** | **kart**: o reis bir şehrin yolunu tutar (`ROUTE_CHANGE perilous`); şehir hâli günde −0,5 | kişi (reis) | Şehirde "yolu besleyen kervan" denir; haber kartı | 0,7 · reis ölünce söner | ZÖ (kan dökmedin) |
| 36 | Reisi öldürmek | savaş, kayıp riski | minnet (bölge) + kin (kardeşlik) | **uzun** | **teklif**: bölge şehirlerinde özel kontrat; **düşman**: kardeşlik `BROTHERHOOD_DANGER` +%10 | bölge + hizip | İki ayrı ses | 0,7 · 0,003 | İB (yara ve yeni düşman) |
| 37 | `CARGO_DECOY` blöfü tutmak | yük kurtuldu | kin (çete), yayılma 1 | sefer | **düşman**: aynı yolda dönüşte çete bekler, ilk tur onların; blöf seçeneği kapalı | yol | "O sandığı açtık" | 0,6 · 0,02 | ZÖ |
| 38 | Mühürsüz tuzu şehre sokmak (`evt_customs_checkpoint` saklama başarı) | kâr × 1,9 | sicil + **bağımlılık** | kısa | **teklif**: kaçakçı seni arar (kârlı ama gümrük kartı ağırlığı × 1,5); Rivecande'de balıkçı minneti (tuzsuz balık kokar) | kişi + şehir | İki yüz: kaçakçı ve balıkçı | 0,5 · 0,006 | N |
| 39 | İlletli şehirden yük/yolcu taşımak (`PlagueWorld.CARRY`) | kontrat ücreti | hastalık izi "kim getirdi" | **uzun** | **kapı**: salgın varılan şehirde görünür olursa (`VISIBLE`) kapı kervana kapanır; bölgede yayılma 3 | şehir | Kapıdaki işaret + "hastalığı yol getirdi" sözü; defter | 0,9 · bağışıklık sönene kadar (~150 gün) | ZÖ (ücret) |
| 40 | Aynı durumda ilaç bırakmak (iksir × 3, kendi stoğundan) | iksir −, şehir ilaç stoğu + | minnet | **uzun** | **kapı**: o şehrin hekimi ücretsiz bakar; kilise itibarı +2 | şehir + hizip | Hekimin repliği | 0,6 · 0,002 | İB (iksir yolda hayat kurtarırdı) |
| 41 | `dismiss()` (yoldaşı kovmak) | ağız eksildi | kin (kişi) + Boş Yer | kısa | **yüz**: kovulan başka bir kervanda; bir kontratı senden önce kapar (panoda teklif −1, bir kez) | kişi | Panoda kovulanın adı | 0,5 · 0,006 | ZÖ |
| 42 | `appoint_heir`: kıdemliyi geçmek | `PASSED_OVER_STRESS` | kin (kıdemli), bağ −2 (var) | **uzun** | **yanki** `evt_mutiny`: geçilen kişi başı çeker; "otoriteni göster" tavanı −15 | yoldaş | Kartta adı geçer | 0,7 · kişi kervandayken 0,002 | N |
| 43 | Yol mezarına taş yığmak (`evt_grave_on_the_road`) | gün −, stres − | kutsal, yon +1 | **uzun** | **yüz**: Bekçi zinciri (var) + yeni: o yolda bir sonraki ölünü biri gömmüş bulursun; tanıklara Çatlak −0,5 | yol | Yol kenarında yeni taş yığını (`road_memorials`) | 0,5 · 0,002 | İB (gün ve vade) |
| 44 | Yol mezarına **ad yazmak** (yeni seçenek, töre ihlali) | yas kısalır: Boş Yer 15 gün | kutsal, yon −1, yayılma 2 | kısa | **ret**: o bölgede kafile seni almaz; Bekçi zinciri kapanır | bölge | Kervansarayda "ad yazan" diye anılırsın | 0,6 · 0,004 | ZÖ (yas çabuk bitti) |
| 45 | Tutulan söz (`SOZ`): alacaklıya, köye, yoldaşa | kaynak − | minnet, yayılma 1 | sefer | **fiyat**/**kapı**: sözün sahibinin şehrinde alış −%6, 20 gün; lider Çatlak −0,5 | kişi | Sözün sahibi kapıda sayar | 0,7 · 0,005 | İB |
| 46 | Bozulan söz | kaynak elde kaldı | kin, yayılma 2 | kısa | **ret**: iki şehirde söz seçeneği kilitli ("senin sözün burada geçmez"); yeminli yoldaşta kırgınlık | bölge | Kilitli seçeneğin sebep metni | 0,8 · 0,004 | ZÖ |
| 47 | Aç şehirde yiyeceği taban fiyattan satmak (merhamet satışı) | kâr yok | minnet (şehir) | kısa | **aday** + **kapı**: bir gönüllü, bir gece bedava | şehir | `KIND_TRADE` satırı zaten var; yanına karşılığı | 0,5 · 0,005 | İB |
| 48 | Üç kuşak boyunca aynı yolda ölü vermek (`route_memory.deaths ≥ 3`) | — | yol izi | **kuşak** | **miras**: yol kervanın adını alır: haritada kervancıların verdiği ad; o yolda stres −1/gün (bildik yol) ama aday bulmak zor ("o yol sizinkileri yer") | yol | Harita etiketi; arabacının repliği | 1,0 · 0 | N |
| 49 | Liderin lakabı: Eli Kanlı ile ölmek | — | miras | **kuşak** | **miras**: varise ilk 30 gün yağmacı az yanaşır (ağırlık × 0,75), gönüllü hiç çıkmaz | soy | Defterde `KIND_EPITHET`; ilk şehirde lonca kâtibi lakabı okur | 0,8 · 30 gün | ZÖ |
| 50 | Liderin lakabı: Kapısı Açık ile ölmek | — | miras | **kuşak** | **miras**: varise ilk şehirde bir gönüllü ve bir gece; yardım kartı ağırlığı × 1,4 (herkes babanı tanıyor) | soy | Aynı | 0,8 · 30 gün | İB |

**Sayım:** 50 satır · uzun gecikmeli 14 (4, 5, 6, 11, 16, 17, 19, 26, 35, 36, 39, 40, 42, 43) ·
kuşak aşırı 7 (7, 21, 32, 33, 48, 49, 50) · kısa 21 · sefer 8 · İB 17 · ZÖ 21 · N 12.

---

## §F · OKUNABİLİRLİK SÖZLEŞMESİ

### F.1 İlk karşılaşma anları

| Alt sistem | İlk sezme anı | Kaçıncı sefer | Nasıl kurulur |
|---|---|---|---|
| **Ahlak** | Bir seçeneğin metninde yoldaşının **adı** yazıyor: "Yükü {bedel} taşısın." | 1–2 | İlk dilemde `{bedel}` zorunlu; ad seçenekte, sonuçta değil. |
| **İz** | Bir şehirde biri seni **daha önce yaptığın bir şeyle** karşılıyor. | 2–4 | İlk üç seferde doğan ilk iz `kisa` gecikmenin alt ucunda (15 gün) ve `yuz` biçiminde döner: garanti. |
| **Ruh** | Kampta biri ateşe **gelmiyor**. | 3–5 | İlk bedel ödeyen yoldaş o gece Ateş Başı kural 2'yi tetikler: zorunlu. |

### F.2 Ekranlarda ne değişir

| Ekran | Yeni satır / işaret |
|---|---|
| **Olay kartı** | Bedelli seçeneğin altında taşıyıcının adı ve küçük portresi. Yankı varyantında gövdenin başında tek cümle, konuşanın adıyla. İz bırakan seçenekte seçenek metninin sonunda defter işareti (mürekkep lekesi). |
| **Defter** | Yeni sayfa **Açık Hesaplar**: her satır "ne oldu · nerede · kime" — sayı yok, şiddet yok. Dönen hesabın yanına karşılığı yazılır; sönenin yanına "kimse hatırlamadı". En çok 15 açık satır. |
| **Kadro / karakter** | Hâl bir sıfat olarak yazılır ("Katı", "Sönük"), yanında tek cümle ("Artık pek konuşmuyor."). Eksen sayısı gösterilmez. Bağ: en çok iki ad ("Yanında: Hilda · Uzak durduğu: Torgan"). |
| **Kamp** | Oturuş düzeni ve duruş (Ateş Başı). Boş Yer için ateşin çevresinde bir boşluk. |
| **Yol** | Yol kenarındaki anıtlara (var: mezar, taş yığını, enkaz, kül) yaklaşırken ilgili yoldaşın tek sözü. |
| **Şehir özeti** | Şehrin ruhu bir sıfatla (Tok / Dayanıyor / Aç / Kırılmış) ve kapının hâli. Açık hesabın varsa "Burada seni bekleyen var" satırı — boş turu dolduran satır bu. |
| **Taverna / lonca / kilise** | `People` kişisinin ilk repliği izi adıyla anar. Kapanan hizmetin düğmesi sebebiyle kilitli. |
| **Pazar** | Fiyat işaretine yeni bir sebep satırı ("adın burada biliniyor"); var olan katman dökümüne eklenir. |
| **Harita** | Kervanın adını alan yol (satır 48). Söylentinin vardığı şehirlerde küçük bir işaret yok — bilerek: oyuncu nereye vardığını gidince öğrenir. |
| **Kuşak devri** | Lakap satırı; lonca kâtibinin ağzından. |

### F.3 Sayı göstermeden durum gösterme

- **Duruş:** Katı sırtı ateşe dönük oturur; Sönük tabağına dokunmaz; Taş nöbeti istemeden alır; Gidici
  eşyasını toplamış yatar. Bunlar var olan `FigureActions` kliplerinden seçilir (oturma, ayakta bekleme,
  yürüyüş); yeni klip gerekirse **sanat borcu**dur (§H).
- **Replik:** her hâlin 6'şar kısa repliği; bölge ağzıyla (lore §14). Replik hâli *söylemez*, belli eder.
- **Eşya:** Boş Yer'de gidenin bir eşyası vagonun kenarında durur (var olan ekipman ikonlarından).
- **Sofra:** kim en son yiyor (lore §13.3: en son yiyen en çok saygı görür) — Taş hep en son yer.
- **Görsel yönlendirme (tek cümle):** bu hâller yeni ikon ya da renk istemez; mürekkep kontur, duruş ve
  ateşe uzaklıkla okunur; ateş tek sıcak kaynak olduğu için "ateşten uzak oturmak" kendiliğinden soğuk çizilir.

### F.4 Yanlış okunma riskleri

| Risk | Önlem |
|---|---|
| Oyuncu izi **rastgele olay** sanar. | Her geri dönüş, doğduğu yeri ve kişiyi **adıyla** anar; defterde iki satır yan yana durur. Adı anmayan geri dönüş hata sayılır (testle korunur). |
| Oyuncu Kabuk'u **ceza** sanar ve merhamete kaçar. | Katı'nın yararı açıkça yaşanır (stresin yarısı); ilk Katı yoldaş bir savaşı/krizi kurtarır şekilde kurulur. Zalimliğin ödülü görünür olmalı. |
| Oyuncu merhameti **en iyi strateji** sanar. | İyi niyetin bedeli tabloda zalimliğin ödülü kadar ağır (§E); ilk minnet dönüşü bir ağız getirir, bir kese değil. |
| "Açık Hesaplar" bir **görev listesine** döner. | Satırlarda yapılacak iş, vade sayacı, ödül yazmaz. Yalnız sözlerin vadesi gün olarak yazılır. |
| Hâl sıfatı **kalıcı hüküm** gibi okunur. | Katı/Sönük geri dönülebilir; karakter ekranındaki cümle bunu sezdirir ("şimdilik"). Taş/Gidici'ye bir adım kala tek seferlik bir Ateş Başı anı uyarır. |
| Bedel taşıyıcısı **keyfî** görünür. | Seçici rastgele değil; aynı durum aynı kişiyi verir ve kartta ad önceden görünür. |

---

## §G · DENGE VE ÖLÇÜM PLANI

### G.1 Ayar düğmeleri

| Sabit | Başlangıç | Makul aralık | Ne bozar |
|---|---|---|---|
| `IZ_ACIK_TAVAN` | 15 | 10–20 | Yüksekse defter okunmaz; düşükse izler doğmadan ölür. |
| `IZ_YAYILMA_GUN` (atlama başına) | 12 | 8–20 | Düşükse her şehir her şeyi bilir; yüksekse söylenti hiç varmaz. |
| `IZ_ATLAMA_KAYBI` | 0,75 | 0,6–0,85 | — |
| `GECIKME.kisa` | 15–70 gün | — | Alt uç 15'ten kısaysa "anında ceza" gibi okunur. |
| `GECIKME.uzun` | 130–400 gün | — | 400'ü aşarsa 40 seferlik kariyerde dönmez (kariyer ≈ 500 gün). |
| Tür tablosu (siddet · sönme · yayılma) | minnet 0,5·0,006·1 · kin 0,6·0,004·2 · söz 0,5·0·0 · söylenti 0,3·0,008·3 · kutsal 0,5·0,006·1 · hastalık 0,9·~0,006·3 · borç kanı 0,6·0,002·0 | ±%30 | Kin minnetten hızlı sönerse dünya affedici, yavaş sönerse kindar olur. Bugün **kin daha uzun yaşar, minnet daha yakına gider**. |
| `KABUK_KATI_ESIK` / çıkış | 4 / 3 | 3–5 | — |
| `CATLAK_SONUK_ESIK` / çıkış | 4 / 3 | 3–5 | — |
| Tanıklık adımları | §D-R2 tablosu | × 0,5–1,5 | Büyükse herkes 10 seferde Taş olur. |
| `KATI_STRES_KALKANI` | 0,5 | 0,4–0,7 | 0,4'ün altı Katı'yı baskın strateji yapar. |
| `HUY_SONME` | 0,02/gün | 0,01–0,04 | — |
| `IYILIK_KOTASI_GUN` | 18 | 12–25 | — |
| `AGIR_AN` sınırları | 1/gün, 3/5 gün | — | — |
| `YANKI_BEDEL_CARPANI` | 1,3 / 0,8 | 1,15–1,5 | — |
| `SOZ_ACIK_TAVAN` | 3 | 2–4 | — |

### G.2 Kabul kriterleri (40 seferlik kariyer, 8 kervan, üç ahlak politikası)

Yeni üç politika `simulate_personas`'a eklenir: **merhametli** (hep bedeli kendine alan seçenek),
**sert** (hep kaynağı koruyan seçenek), **hesapçı** (açık hesapları okuyup dönüşe göre rota kuran).

| Metrik | Bugün | Hedef | Araç |
|---|---|---|---|
| 40. seferde ortalama kadro | 1 | **2,2–3,5** (merhametli üst uçta, sert alt uçta) | `simulate_career` |
| İyi bir şey arası | 40,4 gün | **≤ 18 gün** | `simulate_expert_review` |
| Boş tur | %43 | **≤ %25** | `simulate_expert_review` |
| Çekilen kartların tekrar payı (yankı varyantı yeni sayılırsa) | %74 | **≤ %50** | `simulate_expert_review` |
| Dayanıklılık sırası | acemi > dengeli = açgözlü | **hesapçı ≥ dengeli > acemi**; fark ≥ 4 sefer | `simulate_expert_review` |
| Merhametli ile sert politikanın 40. sefer kesesi | — | **fark ≤ 250 GG**, ikisi de hayatta; merhametli daha kalabalık ve daha aç, sert daha tok ve daha yalnız | `simulate_personas` |
| Kariyer boyunca dönen iz | 0 | **12–22** (40 seferde); bunların %40–55'i iyi yönlü | yeni döküm |
| Sönerek kapanan iz payı | — | **%25–40** (hepsi dönerse dünya küçük, hiç dönmezse sistem görünmez) | yeni döküm |
| Geri dönülemez hâl geçişi (Taş + Gidici) | 0 | **2–5** / kariyer; 0 ise sistem görünmüyor, 8+ ise oyuncu umudunu kaybediyor | `simulate_career` |
| Aynı anda açık iz ortalaması | — | **5–9** | yeni döküm |
| Ağır an / sefer | — | **1,2–2,0** | `simulate_road_beats` |
| Aç sefer payı (dengeli) | %15 | **değişmemeli** (±3 puan): bu sistem açlığı artırmaz | `simulate_expert_review` |
| "Doğru stoklayan aç kalmaz" | tutuyor | **tutmalı** | var olan test |

### G.3 Bozulma işaretleri

- Kadro hedefi tutuyor ama aç sefer %25'i aşıyor → minnet çok ağız getiriyor; `aday` dönüşünün payını düşür.
- Sert politika 40 seferde > 400 GG önde → zalimliğin faturası geç ya da hafif; kin sönmesini 0,003'e indir.
- Merhametli politika 30 seferi göremiyor → iyi niyetin bedeli ölümcül; `IYILIK_KOTASI_GUN` 14'e.
- Herkes 15. seferde Katı → tanıklık adımlarını × 0,7.
- Dönen izlerin > %70'i aynı biçimde (`fiyat`) → GeriDonusSecici biçim çeşitliliği kuralı ekle
  (art arda iki aynı biçim yok).
- Açık Hesaplar hep 15'te tavanda → `gecikme=sefer` izleri deftere yazılmıyor olmalı; yazılıyorsa hata.

### G.4 Yeni ölçüm aracı ihtiyacı

1. **İz dökümü** (`simulate_career`'e ek çıktı): doğan / dönen / sönen iz sayısı türe, yöne ve gecikmeye göre;
   doğumdan dönüşe ortalama gün; biçim dağılımı.
2. **Hâl histogramı**: sefer 10/20/30/40'ta kaç kişi hangi hâlde; Taş ve Gidici geçişlerinin seferi.
3. **Nedensellik denetimi** (test, simülatör değil): dönen her izin metninde doğum yerinin ya da kişisinin adı
   geçiyor mu. Geçmiyorsa kırmızı.
4. **Kart başına görülme** kariyer simülatöründe (bugün yalnız tek sefer aracında var ve o araç kör, §A
   varsayım 2): kilitli kalan ahlaki kartların gerçekten açılıp açılmadığını gösterir.

---

## §H · UYGULAMA SIRASI

Her adım tek başına oynanabilir bir fark yaratır; büyük patlama yok. "Sanat borcu" yazan adımlar yeni görsel ister.

| # | Adım | Dosyalar | İş | Bağımlı | Hangi testle korunur | Risk |
|---|---|---|---|---|---|---|
| 1 | **Bedel taşıyıcısı.** `BEDEL` etkisi, seçici, `{bedel}` doldurma; var olan 9 kartın bedelli seçeneklerini buna bağla. | `event_effect.gd`, `event_effect_applier.gd`, `event_text.gd`, `game_session.gd` (seçici), `event_catalog.gd`, `events.csv` | orta | — | Yeni `test_bedel.gd`: aynı durum aynı kişiyi verir; yeminli bırakılamaz; aynı kişi 10 günde iki kez ödemez; ad seçenekte görünür. | `test_event_effects`'in "her etki türü işlenir" bekçisi yeni türü isteyecek. |
| 2 | **Kilidi aç.** `party_size` koşullu ahlaki kartlara "taşıyıcı tayfa eli / şehir / gelecekteki sen" dalı: kadro 1'de de gelirler. | `event_catalog.gd`, `events.csv` | küçük | 1 | `test_events`: kadro 1 bağlamında 6 kartın uygun olduğu. | Koşul gevşerse kartlar fazla sık gelir: ağırlıkları ölç. |
| 3 | **İz defteri (çekirdek).** Şema, `iz_birak`, sönme, tavan, kayıt (v5), `note_decision` kancası; yalnız `yuz` ve `fiyat` biçimi. | `game_session.gd`, yeni `scripts/campaign/trace.gd` ve `trace_ledger.gd`, `people.gd`, `market_pricing.gd` | büyük | — | Yeni `test_trace.gd`: doğum, tavan, sönme, kayıt gidiş-dönüş, eski kayıt göçü; `test_memory`'nin "her kalıcı alan kayıtta" bekçisi. | Kayıt sürümü; `SAVE_KEY_ALIASES`. |
| 4 | **Açık Hesaplar sayfası** + şehir özetinde "seni bekleyen var". | `caravan_ledger.gd`, `ledger_page.gd`, defter ekranı, `city_brief_model.gd`, `ui.csv` | orta | 3 | Ekran görüntüsü (Y-K01) + `test_city_commerce`: açık hesabı olan şehirde özet boş değil. | Defter sayfa düzeni. |
| 5 | **Ruh eksenleri ve tanıklık.** `kabuk`, `catlak`, tanıklık tablosu, `BEAT_PRICE`/`BEAT_RETURN`; hâl yok, yalnız eksen ve liderin maliyet çarpanları. | `character_data.gd`, `game_session.gd` (gün sonu), `event_effect_applier.gd` (`RUH`) | orta | 1, 3 | Yeni `test_ruh.gd`: günlük tavan; tablo satırları; lider seçeneği hiç kapanmaz. | Stres dengesi: `simulate_journeys` kırılma oranı ±%20'den fazla oynamamalı. |
| 6 | **Hâl makinesi** (Yorgun, Katı, Sönük) + kadro/karakter ekranında sıfat ve cümle; Sükûnet'in bağlanması (§A-12). | `character_data.gd`, `game_session.gd`, `combat_unit.gd`, kadro ve karakter ekranı | orta | 5 | `test_ruh.gd`: histerezis (girmek 4, çıkmak 3); `simulate_journeys` Sükûnet satırı artık düz değil. | Savaş kazanma tabloları (`kurallar-savas`): yeniden ölç. |
| 7 | **Ateş Başı ve Boş Yer.** Öncelik sıralı sessiz an; oturuş düzeni. | `companion_life.gd`, `camp_story.gd`, `road_journey.gd` (kamp sahnesi), `ui.csv` | orta · **sanat borcu: yok** (var olan oturma/ayakta klipleri), ateşe sırtı dönük oturuş yeni klip isterse küçük | 5, 6 | Ekran görüntüsü; `test_companion_life`: bedel ödeyen o gece kural 2'yi tetikler. | Kamp sahnesinin yerleşimi. |
| 8 | **Yayılma ve kalan dönüş biçimleri** (kapı, teklif, ret, aday, düşman) + Y-E13 (dağılan el). | `trace_ledger.gd`, `contract_board.gd`, `recruit_catalog.gd`, `enemy_catalog.gd`, `city_map.gd`, `road_director.gd` | büyük | 3 | `test_trace.gd`: yayılma hızı, bölge sınırı kaybı, Avuçiçi ve Gokyurt istisnası; her dönüş doğumunu adıyla anar (nedensellik denetimi). | En geniş dokunuş: dilim dilim (biçim başına bir commit). |
| 9 | **Yankı çözücü** + ilk 22 yankı varyantı. | `event_engine.gd`, `road_director.gd`, `event_catalog.gd`, `events.csv` | büyük (metin) | 3 | `test_events`: ikinci gelişte gövde ve en az bir bedel değişir; `simulate_expert_review` tekrar payı. | Metin hacmi (≈ 22 kart × 3 cevap); `wayborne-metin` denetimi. |
| 10 | **Söz** (`SOZ` etkisi, vade, tutma/bozma) + sertlik kapısı. | `event_effect*.gd`, `game_session.gd`, `event_catalog.gd` | orta | 3, 5 | `test_trace.gd`: vade, erteleme, bozulunca yayılma, 3 söz tavanı; sertlik hiçbir seçeneği silmez. | Var olan "söz" bayraklı kartların göçü: eski zincirler bozulmamalı. |
| 11 | **Şehrin ruhu köprüsü, huy ve Taş/Gidici.** | `game_session.gd`, `people.gd`, `recruit_catalog.gd`, `scarcity.gd` (okuma) | orta | 5, 6, 8 | `test_ruh.gd`: Gidici yolda ayrılmaz; Taş dönmez; huy bandı değişince söylenti doğar. | Geri dönülmez geçiş sayısı: §G hedefi 2–5. |
| 12 | **Kuşak izleri ve lakap** + ölçüm araçları (§G.4) + üç ahlak politikası. | `lineage_archive.gd`, `game_session.gd` (`appoint_heir`), `caravan_ledger.gd`, `simulate_*.gd` | orta | 3, 8, 11 | `test_lineage`: açık izler kuşağa geçer, bir kez döner; lakap deftere yazılır. | Soy sisteminin var olan testleri. |

Sanat borcu toplamı: defterde bir mürekkep lekesi işareti (adım 4), ateşe sırtı dönük oturuş (adım 7, gerekirse).
Bundan fazlasını isteyen bir adım yok.

---

## §I · REDDEDİLENLER

| Fikir | Neden reddedildi |
|---|---|
| **Görünür ahlak çubuğu / karma puanı.** | Oyuncu çubuğu oynar, insanı değil. `huy_puani` var ama ekranda yalnız başkalarının ağzından bir sıfat olarak çıkar. Sayı göstermek §F'yi ve "anlatıcı yok" kuralını (A3) kırar. |
| **Akıl sağlığı sayacı: halüsinasyon, sahte kart, bozuk arayüz.** | Oyuncuya yalan söyleyen arayüz bilgi oyununu (dördüncü sütun) öldürür: fiyat defterine güvenemeyen oyuncu ticaret yapamaz. Ayrıca kontrolü elinden alır. |
| **Liderin kendi başına karar vermesi** (Katı lider merhamet seçeneğini seçemez, Taş yoldaş emirsiz adam bırakır). | **Anayasa ihlali olurdu (A5, yasaklar: otomatik karar).** Yerine maliyet çarpanı kondu: her seçenek her zaman açık, yalnız bedeli değişiyor. |
| **Olay kartıyla ölüm** (açlık kartında birinin ölmesi, İlletin kartla öldürmesi, "birini feda et" kartı). | **Anayasa ihlali (A2).** `BEDEL` yoluyla gelen can kaybı 1'de kenetlenir; ölüm üç kapıdan gelir. "Feda" geride bırakmak, eli kesilmek, Gidici olmak olarak tasarlandı. |
| **Bir sistemi kaldırarak dengelemek** (dövüş garantisini gevşetmek, büyüme giderini silmek, pazarlığı kapatmak). | **Anayasa ihlali (A1).** Kese eksisi ve kadro 1 sorununa cevap gideri silmek değil, minnet izinin insan getirmesi oldu. |
| **Her NPC ile tam ilişki grafiği** (27 yerleşim × herkes). | Okunmaz ve kaydı şişirir. `People` zaten şehir başına üç kişi + bölge reisi tutuyor; izler onlara yazılır. Yeni kişi rolü açılmadı. |
| **Yoldaşlar arası aşk, evlilik, çocuk.** | Kuşak sistemi adın devri üzerine kurulu, kan üzerine değil ("ad kervanı taşır"). Aile simülasyonu ayrı bir oyun; bağ −3…+3 ekseni yetiyor. |
| **Rastgele kelebek etkileri** ("geçmişte bir şey yaptın, şimdi şans eseri…"). | Doğum kaydı olmayan geri dönüş rastgelelikten ayırt edilemez ve oyuncuyu küstürür. Her geri dönüş bir `kaynak` taşır; nedensellik denetimi testle korunur. |
| **Bölümlü ahlaki hikâye, "iyi son / kötü son".** | **Anayasa ihlali (A4).** Tek son adı taşıyacak kimsenin kalmaması. Lakap bir son değil, bir satır. |
| **Şehir yönetimi katmanı** (şehri besle, kanun çıkar, nüfus yönet). | Oyuncu bir kervanbaşı, bir kethüda değil. Şehrin ruhu kervanın getirdiği yükle değişir, emirle değil. |
| **Yamyamlık ve benzeri şok seçenekleri.** | Şok bir kez çalışır, sonra menü maddesine döner; kıtlığı ucuzlatır. Bu oyunun yokluğu tohumluğu yemek, tahtayı yakmak, mezara ad yazmak kadar küçük ve o kadar ağır olmalı. |
| **Yeni bir kaynak** ("vicdan", "umut" puanı, harcanabilir). | Harcanabilir vicdan bir para birimidir; Kabuk ve Çatlak harcanmaz, yalnız oluşur. Yeni kaynak ayrıca arayüz ve sanat yükü getirir. |
| **Hâl için yeni ikon seti ve renk kodu.** | Sanat borcu ağır ve tek sıcak kaynak kuralını (A6) zorlar. Hâl duruş, oturuş ve replikle okunur. |
