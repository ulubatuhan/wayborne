# Wayborne: Sistem ve Mekanik Denetimi (Yönetmen Raporu 1)

**Tarih:** 2026-10-17 · **Kapsam:** Oyunun bugünkü kodundaki bütün oynanış sistemleri · **Yöntem:** Salt okuma. Oyun çalıştırılmadı. Sayılar koddan (dosya:satır) ya da `CLAUDE.md` içindeki simülatör ölçümlerinden alındı. "Tahmin" yazan yerler koddan çıkarılmış yaklaşık değerlerdir ve oyun içinde ölçülmeleri gerekir.
**Platform notu:** Wayborne bir PC oyunu. Web derlemesi yalnızca test için kullanılıyor; Web performansı bu raporda ölçüt olarak alınmadı.

---

## 0. Özet: on beş satırda

1. **Mimari olgun, içerik ince.** Kod tabanı yaklaşık 41.600 satır GDScript, testler 16.900 satır. Oysa dünya **5 şehir, 7 yol, 12 ticari mal, 59 olay ve 14 düşman şablonundan** ibaret. Onaylanmış haritada ise 128 yer var ve oyun bunlardan hiçbirini okumuyor.
2. **En güçlü sistemler:** olay motorunun okunabilirliği (kilitli seçeneğin sebebini, zarı kimin atacağını ve savaş riskini önceden söylemesi), soy, veraset ve defter tezi, erzak sözü ("doğru stoklarsan aç kalmazsın") ve ölçülerek ayarlanmış, mevkiye dayalı savaş.
3. **En zayıf an, oyuncunun en çok vakit geçirdiği an: yol.** Bir gün gerçek zamanda 45 saniye sürüyor (`journey_clock.gd:16`). Bir seferde ortalama 1–3 olay kartı ve yaklaşık 4 işaret çıkıyor. İşaretlerin tek çözümü doğru bölgeye yürümek. Seçim yoğunluğu düşük, dakikalarca yalnızca izleniyor.
4. **Gerilim katmanları çok, hissedilen gerilim az.** Kervanın yıpranması altı ayrı göstergeye bölünmüş: stres, moral, takat, kırgınlık, açlık ve tehlike. Tehlikeyi tek başına altı ayrı katman değiştiriyor. Oyuncu ise bunların çoğunu tek bir sayı ya da şişe olarak görüyor.
5. **Ödül döngüsü sığ.** Savaştan çıkan ganimet yalnızca altın (`road_journey.gd:37-38`). Ekipman 12 parça. Bandajın üretim tarifi var ama hiçbir yerde kullanılmıyor. Yolda iyileşme yok; can yalnızca şehirde doluyor. Kıyafet ganimete bağlanmadı.
6. **Kontratların hepsi aynı türde:** tüccara eşlik et. Her yön için sabit 3 teklif var (`world_map_data.gd:171-175`), toplam 42 teklif ve 6 lonca görevi. Pano her seferde aynı.
7. **Kampanya bir sayaç listesi.** 5 bölüm var ve finale ortalama 13–16. seferde ulaşılıyor (CLAUDE.md, Faz 24 tablosu). Finalden sonra yeni hiçbir şey açılmıyor. Kervanın sonu geldiğinde de bir sonraki oyuna taşınan bir şey (meta ilerleme) yok.
8. **Ölüm tezi güçlü ama nadir yaşanıyor.** Ölümün Kıyısı'nda hayatta kalma direnci %67'den başlıyor. Dört kişilik parti tehlikeli yolda %92 kazanıyor. Şehirde elle kayıt alınabildiği için sefer sefer yeniden yükleme mümkün. Ironman ya da zorluk seçimi yok.
9. **Onboarding yanlış konuları anlatıyor.** Dört konu var: stres, görev, huy, ekipman (`onboarding_panel.gd:65-70`). Ticaret, kontrat, yol dikkati, işaretler, sofra ve savaş hiç anlatılmıyor.
10. **Aşırı inşa edilmiş bölümler** (kesme ya da birleştirme adayları): kıyafet ve 3B kuşam hattı, vagon başına envanter ile Atölye (3 tarif), hub yürüyüş alanı, tüccar diyaloğu, 5 farklı kapasite büyütme yolu, 7 büyü (hiç doğmayan bir düşmanda) ve 6 katmanlı fiyat motoru.
11. **Eksik olan, türde beklenen sistemler:** yolda tedavi ve sarf malzemesi, sakatlık ve hastalık, eşya ganimeti, çeşitli görev türleri, adı olan karakterler ve hizipler, fiyat bilgisinin taşınması, zorluk ve ironman, meta ilerleme, harita ölçeğinde keşif.
12. **Planlanan işlerin dengesi bozuk.** `TODO/YAPILACAKLAR.md` içinde yaklaşık 75 görev var ve bunların yaklaşık 70'i sanat, görsel, isim, kod hijyeni ya da performans işi. Oynanışa dokunanlar yalnızca 8.3 (haritanın oyuna aktarılması), 11.1 ve onay bekleyen R0–R5 önerileri.
13. **Denge disiplini örnek düzeyde.** `simulate_journeys.gd` ve `simulate_career.gd` var. Ama yalnızca sayıları ölçüyorlar, "eğlenceli mi" sorusuna cevap veremiyorlar. Oyun hâlâ gerçek bir oyuncu tarafından uzun süre oynanmamış görünüyor.
14. **Önerilen öncelik:** önce içerik ve ödül (haritayı oyuna bağlamak, kontrat türleri, ganimet ve sarf malzemesi, yolun "insanlar" katmanı R1), sonra sadeleştirme (yıpranma göstergelerini ve kapasite yollarını birleştirmek), en son cila.
15. Ayrıntılar, dosya ve satır kanıtlarıyla birlikte aşağıda.

---

## 1. Oyunun gerçek döngüsü (dakikadan dakikaya)

### 1.1 Ana döngü

```
Karakter oluştur → Şehir (6 mekân + brifing) → Planlayıcı (rota, kontrat, vagon, erzak)
   → Yol (saat akar; tempo; liderin kolondaki yeri; işaretler; günlük sofra; günde ~%30 olay kartı;
          akşam kampı; bazen savaş; geri dönme ya da yön değiştirme)
   → Varış (ödeme, teslimat, itibar, XP, kırılma zarı, şehirde dinlenme, kampanya kontrolü, otomatik kayıt)
   → Şehir …
```

### 1.2 Zaman ve oturum uzunluğu (koddan hesaplandı)

| Ölçü | Değer | Kaynak |
|---|---|---|
| 1 oyun günü (1x hızda) | 45 sn gerçek zaman | `journey_clock.gd:16` |
| Hız seçenekleri | 0.5x / 1x / 1.5x / 3x | `journey_clock.gd:24` |
| Rota uzunlukları | 3–8 gün (7 kenar) | `world_map_data.gd:127-136` |
| Bir seferin yürüyüş süresi | 2,3–6 dk (1x), olay ve paneller hariç | hesap |
| Günlük olay ihtimali | `0.35 × (0.5 + tehlike)`; tehlike 0,35'te ≈ %30 | `event_engine.gd:8,29` |
| Sefer başına kart | ≈ 1–3 | hesap |
| Sefer başına işaret | ≈ 4 (saatte %3, en fazla 2 açık) | `road_signals.gd:59-69` |
| Kamp | 8 oyun saati, 0,5x hızda | `game_session.gd:1324`, CLAUDE.md Journey Time |
| Finale kadar | ortalama 13–16 sefer (~65–100 oyun günü) | CLAUDE.md Campaign Rules (Faz 24) |

**Tahmin:** Finale ulaşmak 3–5 saat sürüyor. Her seferin yarısı ya da daha fazlası, olaysız yürüyüşü izleyerek geçiyor. Şehir ziyareti 3–10 dakika (pazar, kontrat, planlayıcı).

### 1.3 Karar yoğunluğu

| Faz | Gerçek kararlar | Not |
|---|---|---|
| Şehir | Ne alınacak, nereye satılacak (12 mal), hangi kontrat (rotaya göre 3 teklif), vagon, eşek, köpek alımı, tamir, alım satım, işe alma, ziyafet, arındırma, kıyafet, ekipman | Yoğun ama tekrarlı. Kontrat panosu ve rotalar sabit. |
| Planlayıcı | Rota (en fazla 4 komşu), erzak, eksik erzakla yola çıkma riski | Bilgi zengin: hava rezervi, tehlike, moral dökümü. |
| Yol, saat başına | Tempo (4 kademe), liderin bölgesi (3), kamp | Bölge kararı neredeyse kendiliğinden veriliyor: hep önde dur, işaret çıkınca oraya yürü. |
| Yol, gün başına | Sofra (kalıcı emir sayesinde çoğu gün sorulmuyor), %30 ihtimalle bir kart | Kalıcı emirler dikkat yükünü azaltıyor, ama karar yoğunluğunu da düşürüyor. |
| Savaş | Mevki, yetenek, hedef | En yoğun karar anı, ama seyrek. |

**Sonuç:** Kararların ağırlık merkezi şehirde ve olay kartında. Yolun kendisi, yani oyunun "yıldız" sahnesi, saniye başına en düşük karar yoğunluğuna sahip faz. Bu, TODO §10b'nin teşhisiyle de örtüşüyor (`YOL_DENEYIMI_ONERILERI.md` §1).

### 1.4 Gerilim ve ödül kaynakları

- **Gerilim:** erzak sayacı, tehlike çubuğu (savaş ihtimali), haydut ya da hayvan işaretinin yaklaşması, kalıcı ölüm ve veraset, borç vadesi, kontratın teslim süresi, kırılma zarı (şehre varışta).
- **Ödül:** varış ödemesi (moral ve hasara göre kırpılıyor, `game_session.gd:2659-2677`), ticaret kârı (asıl gelir), itibar, XP ve seviye, kazanılan vagonlar, kampanya bölümleri, savaştan altın.
- **Eksik olanlar:** somut ve görünür ödüller (eşya, nadir bulgu, yeni yer), sürpriz ve keşif, yoldaşın kişisel hikâyesi.

### 1.5 Döngünün düzleştiği yerler

1. **Olaysız günler:** "Sessiz gün" satırı (`road_journey.gd:2088`). Yaklaşık her 3 günün 2'si böyle geçiyor.
2. **İşaretler bir bulmaca değil.** Türü göründüğü anda çözümü belli: o bölgeye yürü. Tırmanmaları için 30 saat var (`road_signals.gd:59`). Ustalık gerektirmiyor.
3. **Rota tekrarı.** 5 şehir ve 7 kenar var. Her seferin ikinci yarısında aynı arazi tohumu ve aynı duraklar yeniden görülüyor. Pano değişmiyor. Kart havuzu yaklaşık 46 kart; bekleme süreleri ve kültüre bağlı koşullar yüzünden etkili havuz daha da küçük, 10–15 seferden sonra tekrar hissi kaçınılmaz.
4. **Finalden sonrası boş.** `is_finale` bir eşik, ondan sonra yeni bir şey açılmıyor (CLAUDE.md Campaign Rules).

---

## 2. Sistem envanteri

Her sistem için: **Ne yapar · Derinlik ve içerik · Bağlantılar · Geri bildirim · Zayıflıklar.** Puan (1–5): **D**erinlik, **G**örünürlük, **B**ağlantı, **E**tki (oyuncunun hissettiği).

### 2.1 Şehir merkezi ve mekânlar

- **Ne yapar:** Kararların verildiği yer. Altı mekân var: Kervan Avlusu, Pazar, Lonca, Taverna, Kilise, Kıyafet Dolabı (`grim/city_front.gd:24-30`). Yanında brifing paneli bulunuyor (bölüm, ihtiyaçlar, gidilebilecek yerler; `CityBriefModel`). Ayrıca harita, parti ekranı ve hub yürüyüş alanı var (`city_map.gd:139-154`).
- **Derinlik:** Yüksek (her mekânın kendi ekranı ve kararları var). Ama şehirler birbirinden yalnızca fiyat tablosuyla ayrılıyor (`world_map_data.gd:88-108`). Şehre özgü bir olay, kişi, hizmet ya da görev yok.
- **Geri bildirim:** İyi. "Her uyarı, sorunu çözen ekranı gösterir" kuralı uygulanmış (CLAUDE.md City Hub Rules).
- **Zayıflıklar:** 5 şehrin oynanışta bir kimliği yok, kültür yalnızca bir isim havuzundan ibaret. Kilise yalnızca arındırma yapıyor ve iki efsane metni gösteriyor (`church.gd:50`). Taverna dedikodu, ziyafet ve arındırma sunuyor; dedikodu da sadece rotanın tehlike yüzdesini satıyor (`tavern.gd:8-9`).
- **Puan:** D3 G4 B4 E3

### 2.2 Dünya, rotalar ve planlayıcı

- **Ne yapar:** 5 şehir ve 7 iki yönlü kenar (3–8 gün, tehlike 0,20–0,65; `world_map_data.gd:127-136`). `RouteConditions` her 6 günde bir yolu kapatıyor, yavaşlatıyor ya da tehlikeli hâle getiriyor (`route_conditions.gd:27-45`). Hiçbir şehrin tüm yolları aynı anda kapanmıyor. `WorldEvents` 4 türde dünya olayı üretiyor (savaş, veba, fuar, haraç; 8–30 gün). Tehlike zamanla büyüyor (günde +0,004, tavan ×1,6; `game_session.gd:445-446`).
- **Planlayıcı:** Hava rezervini kesin olarak hesaplıyor, kamp payını ve eksik erzakla çıkışın riskini gösteriyor, moral dökümünü veriyor. Türün en iyi planlayıcılarından biri.
- **Zayıflıklar:**
  - **Haritanın ölçeği:** Onaylı v3 haritada 128 yer var (`data/config/world_places.json`), ama kod bu dosyayı hiç okumuyor. Oyun hâlâ `test_loc_a…e` kimlikleriyle çalışıyor. Bütün ekonomi tabloları, kontrat üretimi ve bölgesel haydut çeşitleri 5 şehre göre elle yazılmış. TODO 8.3 ve 8.4 bunu aktaracak, ama ekonomi, kontrat ve olay tasarımının **yeniden** yapılması gerektiği hiçbir yerde yazmıyor.
  - Yol seçimi pratikte "en kısa ve en az tehlikeli" ya da "en kârlı mal zinciri" seçimine iniyor. Ağ küçük olduğu için keşif yok.
- **Puan:** D3 G4 B4 E2

### 2.3 Yol katmanı: saat, tempo, dikkat, işaretler, karşılaşma, kamp, plan değişikliği

- **Saat ve tempo:** Dur, Yavaş (0,70), Normal (1,0) ve Hızlı (1,35) kademeleri var (`road_journey.gd:216-220`). Hızlı tempo takat harcıyor (günde 26, `caravan_state.gd:89-95`), stres +3 ve moral −2 getiriyor (`road_journey.gd:234-236`). Hızın gerçek bir maliyeti var, bu iyi.
- **Dikkat (`RoadAttention`):** Kolon üç bölgeye ayrılıyor.
  - **Ön:** karşılaşma 0,55 gün önceden görünüyor.
  - **Vagonlar:** vagon aşınması ×0,45.
  - **Arka:** günlük stres −1 (`road_attention.gd:53-59`).
  - Ödüller küçük ve **neredeyse görünmez**. Arka bölgenin ödülü günde yalnızca 1 stres. Baskın strateji önde durmak ve işaret çıkınca oraya yürümek.
- **İşaretler (`RoadSignals`):** Üç tür var: tekerlek, geride kalan, duman. Çıkma ihtimali saatte %3, aynı anda en fazla 2, 30 saatte tırmanıyor. Tırmanınca bedeli 1 vagon hasarı, +5 stres ya da +0,18 tehlike (`road_journey.gd:1935-1948`). Olumsuz huylar sıklığı her biri için %35 artırıyor. **Kayıt eksik:** `to_dict` yok, sefer ortasında yükleme açık işaretleri siliyor (TODO 11.1, P0).
- **Yaklaşan karşılaşma:** Fiziksel karşılığı olan olaylar önce yolda bir işaret olarak beliriyor (`EVENT_ROAD_MARKER_KIND`, `road_journey.gd:117`). Kervan yaklaşınca kart açılıyor. Önden dikkat 0,55 gün erken uyarı veriyor ve geri dönerek kaçınma imkânı tanıyor. **Bu iyi bir fikir ama tek bir tuşla sınırlı:** kaçmanın bedeli günleri ve kontratı kaybetmek.
- **Kamp:** Akşam ya da gece kurulabiliyor. 8 saat sürüyor, 3 erzak harcıyor, stresi 8 azaltıyor, takati 34 yeniliyor. "Akşam kamp kur" kalıcı emri var.
- **Geri dönme ve yön değiştirme:** Bedeli 2 saat (`REPLAN_HOURS`). Kervanın dönüşü bir sahne olarak oynatılıyor (10 sn).
- **Genel zayıflık:** Dakika başına anlam düşük. Yoldaşların sesi yok, yol bir şey hatırlamıyor, merak uyandıran bir şey yok. Bunu §10b R0–R5 önerileri hedefliyor. **Bu raporun en büyük bulgusu olan "yol boş" teşhisi, planlı işler arasında yalnızca "öneri" statüsünde.**
- **Puan:** D3 G3 B4 E2

### 2.4 Arazi ve hava

- **Arazi (`RouteTerrain`):** Tohumdan üretiliyor ve kayda yazılmıyor. Biyom zinciri, 6 durak türü (köy, karakol, maden, geçit, tapınak, köprü; `route_terrain.gd:24-30`), durak ihtimali %55. Eğim hızı 0,75 ile 1,15 arasında değiştiriyor. Her durağın bir olay kartı var, kart o gün durağın yanından geçilirken ×6–×8 ağırlık kazanıyor. **Bu iyi bir bağlantı.**
- **Hava:** 5 tür (açık, kapalı, yağmur, sis, fırtına; `route_weather.gd:18-22`). Hız, tehlike ve morali etkiliyor. Açık hava tamamen nötr.
- **Zayıflıklar:** Aynı rota her seferinde aynı araziyi veriyor (tasarım gereği). Bu tekrar hissini artırıyor. Hava neredeyse yalnızca bir sayı değiştiriyor; havaya özgü bir karar (sığınmak, beklemek) yok.
- **Puan:** D3 G3 B4 E2

### 2.5 Olay motoru ve katalog

- **Ne yapar:** EU4 tarzı kartlar. Koşullar, ağırlık değiştiriciler, bekleme süreleri, tek seferlik olaylar, zincirler (`UNLOCK_EVENT` ve `triggered_only`), beceri kontrolleri (8 stat; `skill_check.gd`), adı belli bir kişiye düşen seçenekler. 27 etki türü var (`event_effect.gd:8-71`).
- **İçerik:**
  - **59 olay** (`event_catalog.gd:37-95`). **13'ü yalnızca tetiklenince çıkıyor** (zincir halkaları), yani havuzda **46** kart var.
  - Bunların bir kısmı koşula bağlı: kültür (4 kültür kartı), dünya olayı (firari, haraç), borç (alacaklı), kriz (vurguncu), stres veya moral eşiği (kavga, isyan), durak (5 kart). Bir oyuncunun gerçekte gördüğü düzenli havuz **yaklaşık 30–35 kart** (tahmin).
  - Savaş açan kart: **10** (`TRIGGER_COMBAT`, 11 çağrı yeri).
  - Metin hacmi: `events.csv` içinde 389 satır.
- **Bağlantılar:** Çok güçlü. Defter, kampanya bayrakları, dünya olayları, duraklar, biyom, kültür, görev sahipleri ve huylar olay bağlamına giriyor (`game_session.gd:3289`).
- **Geri bildirim:** Türün en iyilerinden biri. Kilitli seçenek sebebiyle gösteriliyor, "neredeyse" tutturulan seçenek vurgulanıyor, zarı kimin atacağı ve yüzdesi yazıyor, savaş açabilecek seçenekte kan şeridi ve tehlike yüzdesi var, haber kartları kültüre göre farklı anlatılıyor.
- **Zayıflıklar:**
  - **Hacim.** Sefer başına 1–3 kart çekiliyor ve finale kadar ~15 sefer var, yani 25–45 kart. Havuz 30–35 kart. Finale gelmeden tekrar başlıyor, finalden sonrası tamamen tekrar.
  - Kartların çoğu bir kaynağı başka bir kaynakla takas ediyor (altın, erzak, stres, moral). Hikâye taşıyan zincir sayısı az: gezgin ve intikamı, kaçak yolcu, hacı, firari, kurtlar, borç, mezar, soruşturma. Toplam yaklaşık 8.
  - Kartın kişilerle bağı zayıf. Adı geçen kişi yalnızca bedeli ödeyen kişi; yoldaşın kendi hikâyesi ya da kişisel kartı yok.
  - Codex olay bölümü kataloğun gerisinde kalmış (CLAUDE.md Ana Hedefler).
- **Puan:** D4 G5 B5 E3 (mimari 5, içerik hacmi 2)

### 2.6 Savaş

- **Ne yapar:** İki tarafta 4'er mevki. Hız zarı (d8), isabet ve kaçınma, kritik ×1,5, zırh (PROT), Ölümün Kıyısı ve ölümcül darbe zarı (direnç 67, İnanç ile en fazla 90). Durum etkileri: kanama, zehir, sersemletme, yanma, üşüme. Alan saldırıları, itme ve çekme, süreli değiştiriciler, emri reddetme (stres) (`combat_encounter.gd:69-92`; CLAUDE.md Combat Rules).
- **İçerik:**
  - **4 sınıf × 4 yetenek = 16 oyuncu yeteneği.** Sınıflar Sıra Neferi, Sekban, Kırıkçı ve Kalem Efendisi (`class_catalog.gd:10-13`). Her sınıfın bir destek ve bir bozma ekseni var, tek iyileştirici Kalem Efendisi.
  - **11 düşman yeteneği.**
  - **7 büyü, ama yalnızca hiç doğmayan `ROGUE_MAGE`'de** (`enemy_catalog.gd:54, 384`). Bu ölü içerik; yanma ve üşüme pratikte oyunda yok.
  - **15 düşman şablonu, 14'ü doğuyor.** 3 haydut, 2 bölgesel haydut, kurt, 2 kurt reisi, ayı, domuz, erkek geyik, geyik, 2 muhafız (`enemy_catalog.gd:8-58`).
  - **4 kadro türü:** haydut, yaban hayvanı, muhafız, av.
  - Kadro büyüklüğü, partiye ve seviyeye göre güç ölçekleniyor (`POWER_SCALE_PER_PARTY_MEMBER` 0,30, `POWER_SCALE_PER_LEVEL` 0,02).
- **Yapay zekâ:** Listedeki ilk kullanılabilir yetenek ve canı en düşük hedef (`combat_encounter.gd:351-362`). Çok basit ve tahmin edilebilir. Hasarı tamamen alan yoldaşlar bu yüzden ortaya çıkıyor (CLAUDE.md Ruin Rules).
- **Sonuçları (`road_journey.gd:2770-2830`):**
  - **Zafer:** 25 + tehlike × 60 altın, +12 moral, +4 itibar (muhafız yenilirse −6), −10 tehlike, XP yalnızca savaşa girenlere.
  - **Yenilgi:** −40 altın, 2 vagon hasarı, 1 tüccar kaybı, −20 moral, +15 stres.
  - **Eşya ganimeti yok.**
- **Kaçış:** Savaş içinde geri çekilme ya da kaçma yok. Kaçınmak ancak karttan ya da geri dönerek mümkün.
- **Denge (CLAUDE.md, beden ölçümü tablosu):** Tek kişi tehlikeli yolda %25. İki kişi %53. Dört kişi %92.
- **Zayıflıklar:**
  - Savaş seyrek, kesin oran ölçülmemiş. Pusu ağırlığı 3,2, yaban hayvanı 2,2. Kabaca her 2–4 seferde bir savaş çıktığı tahmin ediliyor.
  - Taktik çeşitlilik sınırlı: 16 yetenek ve 1 basit yapay zekâ.
  - Sarf malzemesi, ganimet ve kaçma seçeneği yok. Kazanmanın tek ödülü altın.
  - Kademeli derinlik var ama düşman kimliği az. Haydutun her yerde aynı 3 şablonu çıkıyor.
- **Puan:** D4 G4 B4 E3

### 2.7 Ölüm, veraset, soy ve kervanın sonu

- **Ne yapar:**
  - Ölümün iki kapısı var: savaş ve açlık (`resolve_deaths`, `game_session.gd:944`).
  - Lider ölürse `SuccessionPanel` açılıyor. Atlanamıyor, kıdemli varsayılan olarak seçili, kıdemliyi geçmek kırgınlık ve 15 stres bedeli getiriyor (`game_session.gd:996-1018`).
  - Kuşak sayacı ilerliyor. Kervanın adı korunuyor.
  - Kimse kalmazsa `RUN_OVER_FLAG` kaydediliyor ve kapanmış defter ekranı gösteriliyor (`road_journey.gd:2922-2940`).
- **Güçlü yanı:** Oyunun en özgün tezi. Defter, tanıklık, ortak yas ve kurucu satırı tutarlı bir bütün oluşturuyor.
- **Zayıflıklar:**
  - **Nadir yaşanıyor.** Dört kişilik parti %92 kazanıyor, Ölümün Kıyısı'nda %67 direnç var. Liderin ölmesi bir seferde nadir bir olay.
  - **Elle kayıt** (3 slot, şehirde) kalıcı ölümün etkisini zayıflatıyor. Yolda elle kayıt kapalı, ama bir önceki şehrin kaydına dönmek mümkün.
  - **Run over sonrası boşluk:** Defter kapanıyor ve sıfırdan yeni bir oyun başlıyor. Soydan bir sonraki oyuna hiçbir şey geçmiyor: ün, mezar, hatıra yok.
  - Tez, oyuncunun "kayıp yaşamasını" bekliyor, ama ekonomi ve savaş iyi oynayana kayıp yaşatmıyor. Finale "en az iki kayıp" kapısının konması (`campaign_catalog.gd:169`) bu çelişkinin dolaylı bir itirafı.
- **Puan:** D4 G4 B4 E3

### 2.8 Karakter: stat, sınıf, seviye, huy, görev, kültür, beden

- **Statlar:** 8 tane: altısı savaş için, Bilgelik ve İnanç ise savaş dışı. Etkin değer 10'dan sonra yarıya iniyor.
- **Seviye:** En yüksek 20 (`character_data.gd:44`). Her seviyede 1 stat puanı, 2 yetkinlik puanı ve direnç geliyor. İkinci sınıf seviye 7'de açılıyor. Ekipman kademeleri seviye 3 ve 6'da kilitli.
- **Huylar:** 16 tane (her stat için bir erdem, bir zaaf), en fazla 3 huy (`character_data.gd:99`). Kazanılan huy 5 gün "taze" kalıyor ve bu sürede arındırılabiliyor. Huyların savaş, beceri kontrolü, emir reddi, XP, ölümcül darbe, stres, moral ve fiyat kancaları var.
- **Görevler:** 6 tane (Muhafız, İzci, Levazımcı, Arabacı, Tellal, Otacı). Etkileri küçük çarpanlar.
- **Kültürler:** 5 tane. Her birinin stat eğilimi, 16 isimlik havuzu ve tek bir perki var.
- **Beden:** Boy, cinsiyet ve kilo savaş sayılarını ve erzak payını değiştiriyor.
- **Güçlü yanı:** Her şey tek bir yere bağlı (`CharacterData` sarmalayıcıları). Seviye ile ekipman merdiveni ölçülmüş: tehlikeli yolda %33, %70 ve %88 (CLAUDE.md Progression Rules).
- **Zayıflıklar:**
  - **Çok sayıda küçük etken ±0,5–±3 ile yığılıyor**: 8 stat, 16 huy, 6 görev, 5 kültür, 3 beden göstergesi, 12 ekipman, ~50 kıyafet. Oyuncu bunların çoğunu hissedemiyor.
  - Kişilik olarak yoldaşın sadece huyu ve kırgınlığı var. Geçmişi, kişisel hedefi ya da yoldaşlar arası ilişkisi yok (öneri R0 #4.4).
  - Sınıflar yalnızca savaş rolünü belirliyor. Yolda ya da şehirde sınıfa özgü bir eylem yok, oradaki rol görevlere bırakılmış.
- **Puan:** D4 G3 B4 E3

### 2.9 Ekipman ve kıyafet

- **Ekipman:** 4 slot (silah, zırh, yüzük, kolye), **12 parça** (CLAUDE.md, `EquipmentCatalog`). Silah ve zırh 3 kademede Demirci'den satın alınıyor. Yüzük ve kolye yalnızca olaylardan bulunuyor (`GRANT_EQUIPMENT`).
- **Kıyafet:** 6 slot ve **yaklaşık 50 parça** (`outfit_catalog.gd`). Statları küçük (tam bir korucu takımı yaklaşık bir zırh kademesi ediyor). Terzi stoğu şehir ve güne göre değişiyor, terzi %40'a geri alıyor. Ayrı bir Kıyafet Dolabı ekranı var.
- **Zayıflıklar:**
  - **12 parçalık ekipman bir RPG ödül döngüsü için çok az.** Kademe 3'ten sonra aranacak bir şey kalmıyor.
  - Kıyafet ekipmana paralel ikinci bir stat sistemi gibi duruyor. Etkileri çakışıyor ve oyuncunun karar yükünü artırıyor.
  - Kıyafet ganimete bağlanmadı (`GRANT_OUTFIT` yok; Ana Hedefler).
  - Görsel hat çok büyük: 3B render, 6 beden × 50 giysi, kalite kontrol araçları (CLAUDE.md Wardrobe & Rig Rules, yaklaşık 800 satırlık kural metni). Oynanışa katkısı ise küçük.
- **Puan:** Ekipman D2 G4 B4 E3 · Kıyafet D2 G4 B2 E1 (görsel etkisi yüksek)

### 2.10 Stres, moral, takat ve kırgınlık

- **Stres:** Kişiye ait ve seferden sefere kalıcı (0–100). Yolda günde +2. Savaş 8 + düşen başına 6. Şehirde dinlenme 14'ten başlayıp azalıyor (en az 6). Kamp −8. Ziyafet −22, ama günde bir kez (`game_session.gd:645-656, 2636-2642`). Şehre varışta kırılma zarı: %85 olumsuz huy, %15 olumlu huy, %20 + kırgınlık × %3 ihtimalle ayrılma (`game_session.gd:1268-1276`).
- **Moral:** Sefere ait. Her seferde 100'den başlıyor, günde −2, taban 45. İsyan eşiği 40 (`caravan_state.gd:15,25`; `event_catalog.gd:24`). Ödeme çarpanına (0,5–1,0) ve XP başarısına giriyor.
- **Takat:** Hızlı tempo için bir kaynak.
- **Kırgınlık:** 4 tür (aç bırakılmak, savaştan uzak tutulmak, ölüme tanık olmak, liderlikte geçilmek). Kalıcı; yalnızca kırılma anında ayrılma ihtimalini artırıyor.
- **Güçlü yanı:** Stres ve kırılma, referans oyun'ın dramasını kervana taşıyor. Ölçülmüş bir tablo var (CLAUDE.md Stress Rules).
- **Zayıflıklar:**
  - **Dört gösterge yaklaşık aynı soruyu soruyor:** "kervan yorgun mu?". Moral her seferde sıfırlandığı için pratikte bir ödeme çarpanından ibaret. İsyan çok nadir (600 koşuda 6 kez).
  - Kırgınlık görünmez bir değişken; yalnızca nadir bir kırılma anında ve bir düşünce satırında ortaya çıkıyor.
  - Kırılma yalnızca şehre varışta oluyor. Yolda stresin dramatik bir anı yok; yol kenarı yıpranma efekti de kullanıcı isteğiyle kaldırıldı (TODO 2.5).
- **Puan:** D4 G3 B4 E3

### 2.11 Erzak, sofra ve açlık

- **Ne yapar:** Tek bir formül var (`CaravanPlan.daily_consumption`). Ağız sayısı: parti + vagon başına 2 tayfa + tüccarlar + hayvanlar. Akşam sofrası 5 seçenek sunuyor (herkes, yalnızca parti, yalnızca tayfa, seçilmiş kişiler, yalnızca lider; `game_session.gd:1421-1425`). Açlığın 3. gününden itibaren her gece 4 can kaybı ve ölüm var. Tayfa adıyla ölüyor. Kalıcı sofra emri kriz anında yeniden soruluyor.
- **Güçlü yanı:** Oregon Trail omurgası sağlam. "Doğru stoklayan aç kalmaz" sözü testle korunuyor.
- **Zayıflıklar:**
  - Doğru stoklayan için sofra kararı **hiç gerçek bir karar olmuyor**. Kalıcı emir "herkes" ve oyun sorulmadan akıyor. Açlık ikilemi yalnızca kötü planlamada ya da kazada ortaya çıkıyor.
  - Erzakın tek bir türü var. Bozulma, yolda erzak toplamaya ait bir karar ya da avın erzak getirmesi yok. Av savaşı bile erzak vermiyor; yalnızca ilk bölümdeki altın, moral, itibar ve tehlike etkileri genel kural olarak uygulanıyor (genel kod yolu, `road_journey.gd:2808-2814`).
- **Puan:** D3 G4 B5 E3

### 2.12 Ekonomi: pazar, fiyat, şehir hazinesi, pazarlık

- **Mallar:** Erzak, 11 ticari mal (tahıl, kumaş, demir, iksir, kürk, baharat, bal, ipek, mücevher, balık, şarap) ve bandaj (`item_catalog.gd:46-66`).
- **Fiyat katmanları:**
  1. Bir şehrin ürettiği mal ×0,6 alış, aradığı mal ×1,7 satış (`market_pricing.gd:15-17`).
  2. Enflasyon (günde +%0,15, tavan ×1,8).
  3. Mevsim (30 günlük mevsimler).
  4. Arz-talep baskısı (birim başına ±%1, sınır ±%45, günde %6 sönme).
  5. Piyasa şokları.
  6. Dünya olayları.
  7. Şehir hazinesi (varsayılan 260, tavan 900, `market_conditions.gd:20-75`).
- **Pazarlık:** 3 hak. Tüccar yalnızca ciddi bir tekliften sonra taviz veriyor, her ret tabanı sertleştiriyor, sonunda ültimatom geliyor. Zeka ve Karizma tabanı genişletiyor. Pazarlıktan çıkıp gitmek 1 itibar kaybettiriyor (`haggling_session.gd:44-71`). Sepet pazarlığı da var.
- **Güçlü yanı:** Sömürülere karşı test edilmiş, sağlam bir ekonomi.
- **Zayıflıklar:**
  - **12 mal ve 5 şehirden oluşan sabit bir üretim ve talep tablosu.** Optimal döngü birkaç seferde çözülüyor (ör. kumaş: İpekevi → Yeşilova). Bundan sonra ekonomi bir rutine dönüşüyor.
  - **Altı katmanın çoğu oyuncuya görünmüyor.** Yalnızca şok işareti ve şehir hazinesi gösteriliyor. Mevsim ve enflasyon sessizce fiyatı değiştiriyor.
  - Fiyat bilgisi yalnızca o an bulunulan şehirde görünüyor. Başka şehirlerin fiyatını öğrenmek, not etmek ya da tahmin etmek için oyunda bir araç bulamadım (doğrulanmalı).
  - Mallar yalnızca birer sayı. Bozulma (Ana Hedefler'de planlı), kaçak mal, özel alıcı ya da nadir mal yok.
- **Puan:** D4 G2 B4 E3

### 2.13 Kontratlar, lonca ve özel görevler

- **Kontratlar:** Her yön için 3 profil: 1 vagon (30 + gün × 8), 2 vagon (70 + gün × 14, itibar 5) ve eşekli tüccar (18 + gün × 5) (`world_map_data.gd:171-175`). 14 yönde **42 teklif**, son tarih yol süresi + 10 gün. Ödeme varışta yapılıyor ve moral ile hasara göre kırpılıyor. Teslim edilmeyen her kontrat −3, teslim edilen her kontrat +2 itibar.
- **Lonca vagon görevleri:** 6 görev (2 kez vagon bağışı, 4 kargo görevi).
- **Lonca özel görevleri (commission):** 4 tane, dünya olaylarına bağlı ve anında tamamlanıyor (`game_session.gd:3370-3384`).
- **Zayıflıklar:**
  - **Tek tür görev: eşlik.** Teslimat süresi zorlayıcı değil (+10 gün tampon). Gizli kargo, tehlikeli yük, kişi taşıma, keşif, kurtarma ya da bir şeyi ele geçirme gibi türler yok.
  - **Pano sabit**, tüccar isimleri bile deterministik. Tekrar hissinin ana kaynaklarından biri.
  - Kontrat ile yol arasında olay bağı zayıf. Eşlik edilen tüccarın kendi yolda kartı yok; tüccar diyaloğu yalnızca mizacı ortaya çıkarıyor.
- **Puan:** D2 G4 B3 E3

### 2.14 Borç ve lonca kredisi

- **Ne yapar:** Kese eksiye düşebiliyor. Vade 30 gün; geciken her 10 gün için %15 faiz ve 3 itibar kaybı. Yeniden yapılandırma ücreti %12'den başlayıp her seferinde %6 artıyor (`debt.gd:17-30`). Kredi sınırı 200 + itibar × 25 (en fazla 1200), komisyon %15'ten %5'e iniyor (`game_session.gd:133-151`). Ayni ödeme (`DEBT_SETTLE`) ve alacaklı atlısıyla icra memurları zinciri var.
- **Geri bildirim:** İyi. İki sütunlu önizleme ve renk gradyanı var.
- **Zayıflıklar:** Büyük ölçüde isteğe bağlı bir sistem. Borç çoğu zaman yalnızca zorunlu harcamalarda ya da gönüllü krediyle doğuyor. Animal Crossing'deki gibi baskı yaratan bir ana borç yok. Oyuncu borca girmezse sistem hiç devreye girmiyor. Karmaşıklığına göre etkisi orta.
- **Puan:** D4 G4 B3 E2

### 2.15 İtibar

- **Ne yapar:** Tek ve küresel bir sayı (−20 ile 100 arası). Kontratları, loncadan işe almayı, krediyi, vagon eşiklerini (20 ve 45) ve kampanyayı kilitliyor.
- **Zayıflıklar:** Şehir, kültür ya da hizip başına ayrı itibar yok. Muhafız yenmek ya da vurgunculuk yapmak aynı sayıyı etkiliyor. Bir dünya ve siyaset hissi oluşmuyor. Faz 11'den sonra iyi oynayan oyuncuda hızla 50–90'a çıkıyor ve kısıtlama olmaktan çıkıyor (CLAUDE.md Campaign Rules, PR-8).
- **Puan:** D2 G4 B4 E2

### 2.16 Vagon, hayvan, kargo ve atölye

- **Vagon:** Her biri 50 ağırlık taşıyor, 2 tayfa ve 2 parti yeri getiriyor. Satın alma 150'den başlıyor ve her alımda 60 artıyor. Tamir 30. Satış değeri %55 (`game_session.gd:1791-1898`).
- **Kapasiteyi büyütmenin 5 yolu var:**
  1. Satın alınan vagon.
  2. Kazanılan vagon (seviye 4 ve 8, itibar 20 ve 45).
  3. Lonca vagon bağışı.
  4. Eşek (+15, en fazla 3).
  5. Yarım vagon (+25, en fazla 3).
- **Köpek:** En fazla 2. Sezgiye +0,6 ve morale +2 veriyor (`game_session.gd:1916-2036`).
- **Vagon başına envanter:** Mal vagonlara dağıtılıyor, aralarında taşınabiliyor, her karakterin kişisel bir çantası var.
- **Atölye:** **3 tarif** (bandaj, branda tamiri, kürkten bandaj; `recipe_catalog.gd`).
- **Zayıflıklar:**
  - **Bandajın hiçbir tüketicisi yok.** Kodda bandajı kullanan bir iyileştirme ya da savaş eylemi bulunmuyor (`grep` ile yalnızca `item_catalog` ve `recipe_catalog`'da geçiyor). Üretim zinciri bir yere varmıyor.
  - Vagon başına envanterin tek gerekçesi bu atölye kısıtı. Bu yüzden ayrı bir "Kervan Yükü" ekranı (taşıma okları) ve çok satırlık bir kod çıkmış. Oyuncuya gelen kazanç neredeyse sıfır.
  - Beş kapasite yolu birbirinden ayırt edilmesi zor küçük farklarla karar yükü yaratıyor.
- **Puan:** Vagon D3 G4 B5 E4 · Atölye ve envanter bölünmesi D1 G2 B1 E1

### 2.17 İşe alma

- **Ne yapar:** 3 mekân var:
  - **Meydan:** 2 aday, seviye −3 ile −1 arası, 40 altın.
  - **Taverna:** 3 aday, seviye −1 ile +1 arası, 70 altın.
  - **Lonca:** 2 aday, seviye 0 ile +3 arası, 140 altın, itibar 5 gerekli (`recruit_catalog.gd:31-44`).
  - Adaylar her varışta tohumdan bir kez atılıyor. Yolda gezgin ya da hacı ile de katılım olabiliyor.
  - Parti büyüklüğü en fazla 4 ve vagon sayısına bağlı.
- **Zayıflıklar:**
  - Aday bir istatistik kartından ibaret: adayın neden geldiği, ne istediği yok (Ana Hedefler'de bu bir hedef olarak yazılı).
  - İşe almak kolay ve ucuz. Bu, "kayıp acı vermeli" teziyle çelişiyor; ölen birinin yerine kolayca biri alınabiliyor.
- **Puan:** D2 G4 B3 E3

### 2.18 Kampanya

- **Ne yapar:** 5 bölüm (`campaign_catalog.gd:84-171`):
  1. İlk Yol: 1 sefer, 1 teslimat.
  2. Bir Kadro: parti 3, vagon 2.
  3. Ağ: 4 şehir, itibar 5.
  4. Temiz Defter: borç 0, 8 teslimat.
  5. Kendi Hanın: 60 gün liderlik, 4 vagon, itibar 15, 2 kayıp.
  - Ödüller 50, 120, 200, 250 altın ve 1, 2, 2, 3, 5 itibar.
  - Bölümler bayrak koyarak olay havuzunu da etkiliyor.
- **Zayıflıklar:**
  - **Bölümler bir sayaç listesi.** Sahne, karakter, bir yere varış ya da bir seçim içermiyor. Hikâye ile mekanik arasında bir köprü kurmuyor.
  - 8/8 kervan finale ulaşıyor (Faz 24). Kampanya ne bir zorluk ne de bir yön sunuyor.
  - Finalden sonra serbest ticaret dışında hiçbir şey yok.
- **Puan:** D1 G4 B3 E2

### 2.19 Defter ve Waybook

- **Ne yapar:** Hiçbir satır silinmiyor; ayrılan ya da ölen kişinin üstü çiziliyor. Her satırda sebep ve yer var. Kurucu satırı bulunuyor. Olay ve kampanya bağlamına giriyor. Waybook paneli (L tuşu) ve şehirdeki yas kreplerini taşıyor.
- **Zayıflıklar:** Pasif bir kayıt. Oyuncunun yazabileceği bir şey yok ("günün cümlesi", öneri #7). Dünyada da bir izi yok (mezarlar, öneri #5).
- **Puan:** D3 G4 B4 E3

### 2.20 Kayıt

- 4 slot: 1 otomatik, 3 elle (`save_manager.gd:27-28`). Atomik yazılıyor ve yedeği tutuluyor. Sefer ortasında otomatik kayıt var. Yolda elle kayıt alınamıyor.
- Kayıt dünyanın zarlarını yeniden atmıyor. Bütün kalıcı alanların kaydedildiğini bir test kontrol ediyor. **İstisna: `RoadSignals` (P0 hata, TODO 11.1).**
- **Tasarım açısından eksik:** Ironman yok, şehirde elle kayıt alıp sefere yeniden başlamak mümkün.

### 2.21 Onboarding ve zorluk

- **Onboarding:** İlk şehir varışında bir kez açılan 4 konu var (stres, görev, huy, ekipman; `onboarding_panel.gd:65-70`). F3 ile yeniden açılabiliyor. Kampanyanın 1. bölümü örtük bir öğretici işlevi görüyor.
  - **Anlatılmayanlar:** Ticaret döngüsü (üret, ara), kontrat ve teslimatın nasıl işlediği, planlayıcı ve erzak, yol dikkati ve işaretler, tempo ve takat, sofra, savaşın temelleri, veraset.
- **Zorluk:** **Seçilebilir bir zorluk ya da mod yok.** Kodda "difficulty" yalnızca beceri kontrolünün iç parametresi olarak geçiyor. Zorluk eğrisi rota tehlikesine, tehlikenin zamanla büyümesine ve partiye göre düşman ölçeklemesine bağlı. Akademik notlarda "Kader Modu" önerisi var (`docs/design_notes/akademik_kaynak_onerileri.md` C3), uygulanmamış.
- **Puan:** Onboarding D1 G2 E1 · Zorluk D2 E2

---

## 3. Aşırı inşa edilmiş sistemler: kesme ve birleştirme adayları

Ölçüt: Kod, kural ve test hacmi ile oyuncunun hissettiği etki arasındaki oran.

| # | Sistem | Neden fazla | Öneri |
|---|---|---|---|
| 1 | **Atölye ve vagon başına envanter ve "Kervan Yükü" ekranı** | 3 tarif. Bandajın tüketicisi yok. Hangi malın hangi vagonda olduğu yalnızca atölye için önemli. | Kesin ya da tek ve ortak bir kargo havuzuna geri birleştirin. Bandajı yolda iyileştirme olarak kullanmak ancak §4'teki sarf sistemi gelirse anlamlı olur. |
| 2 | **Kıyafet statları ve terzi ekonomisi** | Ekipmana paralel ikinci bir stat sistemi, ~50 parça ve küçük bonuslar. 3B hat zaten bitmiş. | Kıyafeti tamamen görsel yapın, statları ekipmana bırakın. Ya da kıyafeti ekipmanın "zırh" slotuyla birleştirin. Görsel varlıklar kalsın. |
| 3 | **Hub yürüyüş alanı** (`world_hub.gd`, 836 satır) | Şehir ile kapı arasında fazladan bir katman. İşlevi vagona yürüyüp atölyeyi açmak. | Atölye kesilirse hub gereksiz kalıyor. Kapıya basmak doğrudan planlayıcıyı açabilir. |
| 4 | **Tüccar diyaloğu** (izin, zorla bakma, ikna) | Ödülü yalnızca bilgi (mizaç ve kargo), ama bu bilgiyle verilecek bir karar yok. | Kesin ya da mizacı yolda bir olaya bağlayın (hırsız tüccar kaçar vb.). |
| 5 | **Beş kapasite büyütme yolu** | Vagon, kazanılan vagon, bağış, eşek ve yarım vagon küçük farklarla aynı işi görüyor. | İkiye indirin: vagon (satın alma ve kilometre taşı) ve yük hayvanı. Köpek ayrı kalabilir (moral ve sezgi). |
| 6 | **Yıpranma göstergeleri: stres, moral, takat, kırgınlık, açlık** | Oyuncu hepsini ayrı ayrı izleyemiyor. Moral her seferde sıfırlanıyor. | Morali "yolun ruh hâli" olarak takatle birleştirin. Stresi kişiye ait tutun. Kırgınlığı görünür kılın (portrede, yolda; R1). |
| 7 | **Tehlikeye giren 6 katman** (taban, zamanla büyüme, rota durumu, hava, dünya olayı, duman işareti) | Oyuncu yalnızca tek bir yüzde görüyor. Hangi katmanın ne kadar eklediği planlayıcıda ayrıntılı gösterilmiyor (doğrulanmalı). | Ya döküm gösterin ya da katmanları azaltın. |
| 8 | **Fiyatta 7 katman** | Mevsim, enflasyon ve baskı görünmüyor. Oyuncu bunu yalnızca "fiyat değişti" diye algılıyor. | Görünür kılın (bir şehir fiyat defteri) ya da sadeleştirin. |
| 9 | **Büyüler ve `ROGUE_MAGE`** | 7 büyü, yanma ve üşüme durumları, render edilmiş klipler. Bunları kullanan düşman hiç doğmuyor (`enemy_catalog.gd:54`). | Ya lore kararıyla bir olaya bağlayın ya da dondurun. Bakım maliyeti var. |
| 10 | **Beden göstergeleri** (cinsiyet ve kilo savaş sayılarına giriyor) | Oyuncu fark etmiyor, ama her denge ölçümünü kaydırıyor (CLAUDE.md body A/B). | Etkiyi yalnızca erzak payına bırakın, savaştan çıkarın. |
| 11 | **Kültüre göre çerçevelenmiş haber metinleri** (4 kart × 5 metin) | Etkisi düşük, yazım maliyeti var. | Mevcut hâliyle kalsın, ama yeni içerikte örnek alınmasın. |
| 12 | **Görevler (6) ile sınıflar (4) iki ayrı rol sistemi** | Sınıfın ana görevi zaten var (`duty_id`). | Görevi sınıfa bağlı bir yetenek yapın ya da görev sayısını 4'e indirin. |

**Genel not:** `CLAUDE.md` 7.345 satır. Kural kitabının büyüklüğü de bir aşırı inşa belirtisi. Her yeni sistem 4–6 dosyaya, 2 teste ve bir ölçüm tablosuna dokunuyor. TODO 6.3 bunun inceltilmesini zaten öneriyor. Bu bir kod işi değil, **yönetmenlik işi**: kuralları sistem sayısını azaltarak inceltin.

---

## 4. Eksik sistemler (türde beklenenler)

Karşılaştırma: referans oyun, Oregon Trail, Battle Brothers, Wartales, King of the Castle / Banner Saga.

| Eksik | Neden önemli | Mevcut kancalar |
|---|---|---|
| **Yolda tedavi ve sarf malzemesi** (bandaj, iksir, erzak türleri) | Bugün can yalnızca şehirde doluyor. Yolda kaynak yönetimi tek boyutlu (erzak). | Bandaj tarifi var, `test_potion` bir ticari mal olarak var, `PARTY_HP` etkisi var. |
| **Sakatlık ve hastalık** | Kalıcı yıpranma ve zor kararlar (Banner Saga, referans oyun). | Ana Hedefler'de tasarlanmış, uygulanmamış. |
| **Savaş ganimeti ve eşya** | Kazanmanın tek ödülü altın. Ekipman 12 parçada tıkanıyor. | `GRANT_EQUIPMENT`, kıyafet dolabı. |
| **Görev türleri** (taşıma, kurtarma, av, gizli yük, kişi taşıma) | Kontratların tek türlülüğü tekrarın ana kaynağı. | `MerchantOffer` alanları, olay zincirleri. |
| **Adı olan karakterler, hizipler, bölgesel itibar** | Dünyanın "yaşadığı" hissi. | `WorldEvents`, kültürler, `NpcDisposition`. |
| **Yoldaşın kendi hikâyesi ve ilişkileri** | Tezi ("konu onu çekenler") sahneliyor. | Öneri R0/R1 (`backstory_id`, `rapport`, kamp hikâyesi). |
| **Keşif ve harita ölçeği** | 128 yerlik harita hazır, ama oyunda 5 şehir var. | TODO 8.3 ve 8.4. |
| **Fiyat bilgisi ve ticaret defteri** | Ticaret bir bilgi oyunu. Bugün yalnızca bulunulan şehrin fiyatı görünüyor (doğrulanmalı). | Taverna dedikodusu altyapısı. |
| **Zorluk ve ironman** | Kalıcı ölüm tezinin ağırlığı için şart. | `SaveManager` slotları. |
| **Meta ilerleme ve miras** (run over sonrası) | Tekrar oynanabilirlik ve kaybın anlamı. | Defter, kurucu satırı (yeni oyun eski soyun mezarından başlayabilir). |
| **Savaşta kaçış ve geri çekilme** | Kayıp ile kaçış arasındaki gerçek ikilem. | `MERCHANT_LEAVE` ve yenilgi bedelleri. |
| **Yönetmen / anlatıcı** (gerilim temposu) | Kart ritmi tamamen rastgele. | Öneri #17, `EventEngine` ağırlık kancası. |
| **Ses ve müzik içeriği** | Atmosfer oyunu için kritik. Bugün yer tutucu var. | Ana Hedefler'de yazılı. |

---

## 5. Zorluk eğrisi, hedefler ve tekrar oynanabilirlik

- **Zorluk eğrisi:**
  - Tehlike zamanla büyüyor (günde +0,004).
  - Düşman seviyeye göre %2 ölçekleniyor, partiye göre %30.
  - Şehirde dinlenmenin stres rahatlatması azalıyor.
  - Başlangıç partisi (2 kişi) tehlikeli yolda %53 kazanıyor. Bu, ilk saatlerin en riskli dönem olduğu anlamına geliyor. Sonra eğri hızla yumuşuyor (4 kişilik parti, kademe 3 ekipman: %88–92).
  - **Sonuç:** Zorluk ters bir U çiziyor. Erken dönem sert, orta dönem rahat, geç dönem tekrarlı. Geç dönemde yeni bir tehdit (yeni düşman türü, bölge ya da kriz) yok.
- **Hedefler:**
  - **Kısa vadeli:** bu seferin kârı ve teslimat.
  - **Orta vadeli:** vagon ve kadro büyütmek, ekipman kademesi.
  - **Uzun vadeli:** 5 bölüm ve soyun sürmesi.
  - Uzun vadeli hedef bir sayaç listesi olduğu için duygusal bir çekim yaratmıyor. "Kendi Hanın" finali bir mekân ya da sahne olarak oyunda yok.
- **Tekrar oynanabilirlik kancaları:** Rastgele başlangıç şehri ve yoldaş, 5 kültür, 4 sınıf, tohumlu arazi ve hava, olay zarları.
  - **Zayıf olanlar:** Sabit 5 şehirlik harita, sabit kontrat panosu, aynı 46 kart, run over sonrası hiçbir şey taşınmıyor, zorluk seçimi yok.
  - İkinci bir oyun ilkinden pek farklı hissettirmiyor.

---

## 6. Planlanan işlerle ilişki (TODO klasörü)

| Bölüm | Görev sayısı | Oynanışa etkisi |
|---|---|---|
| §1 İsim, §3 Atıl kod, §4 Kalite, §5 Performans, §6 Hijyen | 24 | Yok |
| §2 Yüksek etkili | 5 | 2.5 (yıpranma efektini kaldırmak) görsel bir değişiklik |
| §8 Dünya haritası | 11 | **8.3 ve 8.4 oynanışı kökten değiştirecek**, ama ekonomi, kontrat ve olay tasarımı planlanmamış |
| §9 Art ikinci tur | 13 | Yok (sunum) |
| §10, §12 Figür ve yol görünümü | 11 | 12.2c (kamp yürüyüşü) bir hata; geri kalanı görsel |
| §10b Yol deneyimi R0–R5 | 6 | **Yüksek**, ama durumu "öneri" |
| §11 Hata | 1 | 11.1 kayıt hatası (P0) |

**Değerlendirme:** Projenin bir sonraki dönemi neredeyse tamamen sunuma ayrılmış. Bu raporun bulgularına göre darboğaz görsel değil; **içerik hacmi, ödül çeşitliliği ve yolun anlamı**. Haritanın oyuna aktarılması (8.3) bir fırsat. Dünyayı 128 yere çıkarmak, kontrat, olay ve ekonomi tasarımını yeniden yapmayı gerektiriyor ve bu tasarım işi şu an planda yok.

---

## 7. Öncelikli öneriler (yönetmen gözüyle)

**A. İçerik ve ödül (önce):**
1. **Harita aktarımını (8.3) bir tasarım projesi olarak ele alın.** 128 yerden 12–20 oynanabilir yerleşim ve bölge seçin, bölgelere özgü mal, düşman ve olay belirleyin. Kontrat ve fiyat tablolarını veriden (JSON) okuyun.
2. **Kontrat türlerini çeşitlendirin.** En az 4 tür olsun: eşlik, kargo (süre baskılı), kişi taşıma (yolda kartı olan), av veya kurtarma. Panoyu her varışta tohumdan yeniden üretin.
3. **Ganimet ve sarf malzemesi ekleyin.** Savaş ve olaylardan eşya, kıyafet ve iksir düşsün. Bandaj ve iksir yolda kullanılabilsin (iyileştirme, Ölümün Kıyısı'na karşı direnç). Ekipmanı 12'den en az 30 parçaya çıkarın (trinket ağırlıklı).
4. **Olay havuzunu genişletin:** bölge başına 5–10 kart, yoldaş kartları ve zincirler. 46 → 100+ hedefi.

**B. Yolun anlamı (eş zamanlı):**
5. **§10b R0 ve R1'i "öneri" olmaktan çıkarıp ana iş yapın.** Önerilen ilk dilim: baloncuk ve rapport ile prosedürel mezar. Bu, tezi sahneleyen tek plan.
6. **İşaretleri bir bulmaca yapın.** İşaret türleri ve belirsizlik (omen #9) eklenebilir. Ya da dikkat ödülleri büyütülerek görünür kılınabilir (arka bölgenin günlük −1 stresi hissedilmiyor).

**C. Sadeleştirme:**
7. §3'teki 1, 3, 4 ve 5 numaralı adayları kesin ya da birleştirin. Moral ve takati birleştirin, kıyafeti görsele indirin.
8. Tehlike ve fiyat katmanlarının dökümünü gösterin ya da katman sayısını azaltın.

**D. Çerçeve:**
9. **Onboarding'i baştan yazın.** İlk seferi rehberli yapın: ticaret, kontrat, planlayıcı, dikkat, sofra, savaş.
10. **Zorluk ve ironman seçeneği ekleyin.** Kalıcı ölümün ağırlığı için ölmek mümkün olmalı. İsteğe bağlı olarak ölümcül darbe direncini zorluğa bağlayın.
11. **Run over sonrası miras:** Yeni kervan eskisinin defterini, mezarlarını ve ününü görsün.
12. **Kampanya bölümlerini sahneleyin.** Her bölümde bir kart zinciri ve bir karar olsun. Finalde "Han" bir mekân olarak yer alsın.

---

## 8. Kanıt dizini (sık başvurulan dosyalar)

- Olay kataloğu: `scripts/events/event_catalog.gd:37-95` (59 olay), olay ağırlıkları ise `_event(...)` satırlarında (110–2120).
- Olay motoru: `scripts/events/event_engine.gd:8-33`.
- Yol: `scripts/ui/road_journey.gd` (3.152 satır). Sabitler 33–285, gün döngüsü 1979–2094, savaş sonucu 2770–2830, run over 2922–2940.
- İşaretler ve dikkat: `scripts/travel/road_signals.gd`, `scripts/travel/road_attention.gd`.
- Dünya: `scripts/travel/world_map_data.gd:88-190`.
- Oturum: `scripts/autoload/game_session.gd` (3.185 satır). Kredi 133–220, stres 537–690, ölüm ve veraset 861–1019, sofra 1421–1650, vagon ve hayvanlar 1791–2036, varış 2423–2677.
- Savaş: `scripts/combat/combat_encounter.gd`, `scripts/combat/enemy_catalog.gd`, `scripts/combat/skill_catalog.gd`.
- Kampanya: `scripts/campaign/campaign_catalog.gd:84-171`.
- Ekonomi: `scripts/economy/item_catalog.gd:46-66`, `market_conditions.gd:20-75`, `haggling_session.gd:44-71`, `debt.gd:12-30`, `recipe_catalog.gd`.
- Onboarding: `scripts/ui/onboarding_panel.gd:65-70`.
- Kayıt: `scripts/autoload/save_manager.gd:27-28`.
- Ölçüm tabloları: `CLAUDE.md` (Ruin, Progression, Stress, Campaign Rules).
- Planlı işler: `TODO/YAPILACAKLAR.md`, `TODO/belgeler/YOL_DENEYIMI_ONERILERI.md`.

**Kod hacmi (satır):** ui 23.608 · autoload 4.067 · character 4.067 (bunun 2.056'sı rig ve kıyafet) · events 3.168 · travel 2.121 · combat 2.001 · world 1.182 · economy 1.012 · campaign 377 · tests 16.921. Kodun %57'si UI ve sunum.
