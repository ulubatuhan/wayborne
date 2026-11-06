# Altı oyuncu, altı günlük — ikinci profil turu

**Tarih:** 2026-11-05 · **Araç:** `tests/simulate_player_diaries.gd` ·
**Günlükler:** `docs/design_notes/oyuncu_gunlukleri/*.md` (6 profil × 2 koşu, 20 sefer sınırı) ·
**Ekran doğrulaması:** `tests/screenshot_diary_fixes.gd` · **Kilitler:** `tests/test_persona_fixes.gd`

Birinci tur (`oyuncu_profilleri.md`) yolu oynadı ve tek soru sordu: *kim hayatta kalıyor.* Bu tur farklı.
Altı profil şehrin ve yolun elinden geleni dener — taverna, pano, lonca avansı, pazar, takas, vagon
atölyesi, kilise, hekim, işe alma, kişilerin işleri, dövüş, kamp, yolda yiyecek arama — ve her biri
**bir oyun testçisi gibi günlük tutar.**

Kullanıcının bu tur koyduğu çerçeve raporun ölçütü:

> *"Sürekli ölmek keyifsiz ve istemediğimiz bir deneyim olsa da çaba göstererek, mücadele ederek az
> sayıda ölüm ile oyunu devam ettirebilmek de bir deneyim olmalı... Herkes öldüğünde de yeni bir kayıt
> ile baştan başlamak çok da koymamalı oyuncuya çünkü sonuçtan değil süreçten keyif ve haz vermeyi
> amaçlıyoruz."*

Yani ölçülen şey "kaç sefer dayandı" değil: **kaç ölümle kaç sefer yaşadı, yolda ne denedi, ve
denediğinde oyun ne cevap verdi.**

---

## 1. Günlüğün omurgası: oyunun kendi "neden olmuyor"ları

Wayborne'da kapalı düğme sebebini kendi yazısında söylüyor ("disabled with reason"):
`get_advance_block_reason`, `get_day_labour_block_reason`, `get_doctor_block_reason`,
`get_cargo_move_block_reason`, `debt_shut_out_reason`... otuz küsur kapı. Her biri tam olarak **"yapmak
istedim ama olmadı"** demek. Profil o kapıya her çarptığında günlüğe bir satır düşüyor.

Üç tür kayıt:

| tür | ne demek | kaynağı |
|---|---|---|
| `istedim` | bir şeyi denedi, oyun izin vermedi | oyunun kendi sebep yazısı |
| `keyif` | profilin aradığı şey gerçekleşti | her profilin kendi `keyif_yerleri` listesi |
| `anladım` | bir kararın sonucunu öğrendi | ölüm, sofra kipi değişimi, dövüş sonucu |

Toplam: **808 keyif · 1022 istedim · 103 anladım.** İstediği olmayan satırın keyif satırından fazla
olması bir hata değil, oyunun hâli: kıtlık oyunu çoğu kapıyı kapalı tutar. Önemli olan **hangi** kapı.

---

## 2. Altı profil

Akademik zemin birinci turun raporunda (§1): prosedürel persona (Holmgård ve ark. — persona bir fayda
fonksiyonudur), gelişen persona (Ariyurek ve ark.), ÖBK/PENS (Ryan, Rigby, Przybylski 2006; Johnson ve
ark. 2018'in kısmi doğrulaması), QF güdü kümeleri ve BrainHex eleştirisi (Tondello ve ark.) — ve
hepsinin sınırları. Bu turda beş profilin yerine altı yeni profil kuruldu, çünkü eskiler yalnız yolu
oynuyordu.

### Kâğıt Üstünde Tüccar
*Her seferi bir hesap olarak görür. Fiyat defterini okur, takası sever, riski fiyatlar.*

- **Keyif aldığı yerler:** ucuz aldığı malı pahalı satmak · fiyat defterinde bir şehri doğru hatırlamak
  · kıtlıkta takasın altından iyi çıktığını görmek · kontratı zamanında teslim etmek
- **Ölçüm:** 20/20 sefer · **0 ölüm** · 21 teslimat · 11,5 kart · 0 dövüş
- **Günlüğünden:** 261 "istedim" ile en çok engellenen profil — ama hiç ölmedi. Engellerin çoğu
  *büyüme* engeli (avans, işe alma), hayatta kalma engeli değil.
- **Eksik bulduğu:** 47 kez "Kredi hattı dolu", 32 kez "Lonca sana güvenmiyor". Avans sistemi tüccarı
  tam da en çok isteyeceği anda dışarıda bırakıyor ve ne zaman açılacağını söylemiyor.

### Defter Tutan
*Sayıya değil ize bakar. Tavernada oturur, kişileri tanır, deftere ne yazıldığını merak eder.*

- **Keyif aldığı yerler:** tavernada bir gece kalıp odadakileri dinlemek · adı olan birinin kervanı
  hatırlaması · defterde yeni bir satır görmek · daha önce görmediği bir kart çekmek · yolda bir mezarın
  yanından geçmek
- **Ölçüm:** 5 sefer · **2,5 ölüm** · 2/2 koşu bitti · 1 teslimat · 15 kart
- **Günlüğünden:** 12. gün *"herkesi besleyemiyoruz; sofra ekibe indirildi"*, 15. gün *"erzak eksik;
  yine de yola çıkılıyor"*, 55. gün *"Kervanbaşı açlıktan öldü"*. Kırk gün boyunca her gün bir şey
  denedi ve kırk gün boyunca durum kötüleşti.
- **Eksik bulduğu:** Hikâyeyi takip etmenin bir bedeli var ama bir geliri yok. Tavernada oturmak,
  kişileri tanımak ve kartları okumak hiçbir yerde para ya da erzak getirmiyor; bu profil oyunun en
  sevdiği şeyi yaparak ölüyor.

### Ucunda Yürüyen
*Zorluğu arar. Erzağı sayar, hava raporunu okur, yolda yiyecek arar.*

- **Keyif aldığı yerler:** bitmek üzereyken yiyecek bulmak · kimseyi kaybetmeden zor bir yolu bitirmek ·
  soğuk bir geceyi ateşle atlatmak · yaban hayvanını yenip et getirmek
- **Ölçüm:** 20/20 sefer · **0 ölüm** · 19 kart · **8,5 dövüş, 4 galibiyet** (en çok dövüşen profil)
- **Günlüğünden:** 24 kez "dövüş kayıpsız kazanıldı", 27 kez "bitmek üzereyken 9 erzak bulundu". Aradığı
  his oyunda var.
- **Eksik bulduğu:** Dövüşün yarısını kaybediyor ve **hiç kimse ölmüyor.** Ölümün Kıyısı kuralı
  kaybedilen dövüşü bedelsiz kılıyor; zorluğu arayan oyuncu için bu, zorluğun en büyük kaynağının
  sahte olması demek.

### Listeyi Kapatan
*Her kontratı, her şehri, her kartı ister. Defterdeki sayaçlara bakar.*

- **Keyif aldığı yerler:** görülmemiş bir şehre ilk kez girmek · defterdeki sayacın bir artması ·
  panodaki bütün ilanları almak · vagon alıp kervanı büyütmek
- **Ölçüm:** 20/20 sefer · **0 ölüm** · 19,5 teslimat · 16,5 kart · 13,5 taverna gecesi ·
  **232 keyif satırı** (en mutlu profil)
- **Günlüğünden:** 120 kez "yeni bir vagon alındı" — on iki koşuda, yani koşu başına on vagon.
- **Eksik bulduğu:** Vagon almanın bir sonu yok ve bir anlamı da kalmıyor: parti dört kişide tavanlı
  olduğu için 73 kez "Parti dolu" cevabı aldı. Büyüme sayacı artıyor ama büyüme bir şey değiştirmiyor.

### Bedeli Soran
*Kim ödüyor diye sorar. Herkesi besler, hastayı hekime götürür, kiliseye verir.*

- **Keyif aldığı yerler:** herkesin karnını doyurabilmek · hasta birini iyileştirmek · aç bir şehre
  yiyecek götürmek · kimseyi geride bırakmadan varmak
- **Ölçüm:** 6,5 sefer · **3,5 ölüm** · 2/2 koşu bitti · 48 aç gün · **17 gün yiyecek aradı, 12 gün
  şehirde çalıştı** (en çok çabalayan profil)
- **Günlüğünden:** Her kurtuluş yolunu denedi — sofra kipini indirdi, günlerce çalıştı, yolda aradı,
  kiliseye verdi — ve iki koşuda da öldü.
- **Eksik bulduğu:** Cömertliğin sürdürülebilir bir hâli yok. Oyun "herkesi besle" seçeneğini sunuyor
  ama o seçeneği seçen oyuncuya ayakta kalabileceği hiçbir gelir vermiyor.

### Vagonu Kuran *(yeni profil)*
*Kervanı bir atölye gibi görür. Vagon düzenler, üretir, ekipman takar.*

- **Keyif aldığı yerler:** vagonda bir şey üretmek · kargoyu düzenleyip yer kazanmak · bir yoldaşa doğru
  ekipmanı takmak · eşek ya da yarım vagon alıp kapasiteyi büyütmek
- **Ölçüm:** 20/20 sefer · **0 ölüm** · 13,5 teslimat · 5 üretim
- **Günlüğünden:** 20 seferde yalnız 5 kez bir şey üretebildi; **108 kez "Yeterli malzeme yok"** cevabı
  aldı. Oyundaki en çok çarpılan kapı bu.
- **Eksik bulduğu:** Atölye bir fiil değil, bir süs. Tarifler var, vagon var, ama girdileri pazarda
  aramanın bir yolu yok: hangi tarif için ne gerektiği üretim ekranında duruyor, satın alma ekranında
  durmuyor.

---

## 3. Tablo

| profil | sefer | ölen koşu | ölüm | parti aç gün | **ekip aç gün** | arama | işgünü | dövüş | kazan | yol uzaması | teslim | kart |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Kâğıt Üstünde Tüccar | 20,0 | 0/2 | 0,0 | 0,0 | 60,5 | 5,0 | 5,5 | 0,0 | 0,0 | ×1,16 | 21,0 | 11,5 |
| Defter Tutan | 5,0 | **2/2** | 2,5 | 19,0 | 19,0 | 8,0 | 7,0 | 0,5 | 0,5 | ×1,20 | 1,0 | 15,0 |
| Ucunda Yürüyen | 20,0 | 0/2 | 0,0 | 0,0 | 98,0 | 1,5 | 5,5 | 8,5 | 4,0 | ×1,10 | 10,0 | 19,0 |
| Listeyi Kapatan | 20,0 | 0/2 | 0,0 | 0,0 | 75,0 | 5,0 | 6,0 | 8,0 | 8,0 | ×1,20 | 19,5 | 16,5 |
| Bedeli Soran | 6,5 | **2/2** | 3,5 | 48,0 | 48,0 | 17,0 | 12,0 | 0,0 | 0,0 | ×1,21 | 4,0 | 21,5 |
| Vagonu Kuran | 20,0 | 0/2 | 0,0 | 0,0 | 69,0 | 3,0 | 7,0 | 0,0 | 0,0 | ×1,16 | 13,5 | 16,0 |

**En çok çarpılan kapılar** (altı profil, iki koşu):

| kez | ne istedi | oyun ne dedi |
|---|---|---|
| 108 | vagonda bir şey üretmek | Yeterli malzeme yok |
| 102 | kartta kapalı bir seçeneği seçmek | **Yeterli altının yok** |
| 73 | tayfaya biri katmak | Parti dolu |
| 56 | Mathis'in işini bitirmek | 4 tane eksik |
| 47 | loncadan mal avansı almak | Kredi hattı dolu |
| 39 | tayfaya biri katmak | Kese yetmiyor |
| 32 | loncadan mal avansı almak | Lonca sana güvenmiyor |
| 25 | panodaki bir ilanı almak | *(sebep yazmıyor)* yük yeri yok |

---

## 4. Ölçüm aracının üç kere yalan söylemesi

> *"Bir rapor şaşırtıcıysa önce ölçüm aracından şüphelen."* — Testing Rules

Bu turda kural üç kez devreye girdi; üçü de rapora girmeden önce yakalandı.

1. **"Dört profil sıfır ölümle 20 sefer bitirdi."** Doğru değildi: `TRIGGER_COMBAT` etkisini yalnızca
   `road_journey.gd` savaşa çeviriyor, simülatörde kart çekiliyor ve hiçbir şey olmuyordu. Kimse bir
   kez bile dövüşmemişti. `simulate_journeys.gd`'nin headless savaş politikası (yaralıyı iyileştir,
   yoksa en zayıfa en sert vur) araca taşındı; şimdi Ucunda Yürüyen 8,5 dövüş görüyor.

2. **"148 kez kapalı seçenek, sebep yazmıyor."** Doğru değildi: kilitli seçenek sebebini ekranda
   söylüyor (`choice.unavailable_text_key`, bkz. `road_journey.gd _build_choice_button`); sebep
   yazmayan benim simülatörümdü. Düzeltilince ortaya **gerçek** bulgu çıktı: 102 kez *"Yeterli altının
   yok"* — yolda kapalı seçeneklerin açık ara birinci sebebi yoksulluk.

3. **"Sıfır aç gün."** Yarı doğruydu: `hungry_names` yalnız adı olan partiyi sayıyor. `crew_hungry`
   ayrı bir alan ve hayatta kalan dört profilde **60–98 gün** doğru. Yani o profiller
   *isimsiz ekibi aç bırakarak* yaşıyorlardı ve bunu kimse fark etmiyordu. Ölçüm ikiye ayrıldı.

---

## 5. Düzeltilen kusurlar

Hepsi testle kilitlendi (`tests/test_persona_fixes.gd`, 32 055 geçti) ve oyuncunun gördüğü olanlar
gerçek ekran görüntüsüyle doğrulandı (`tests/screenshot_diary_fixes.gd`).

### K1 · Gecikme kat edilen yolu siliyordu *(gerçek hata)*
`TRAVEL_DAYS` etkisi yalnız `journey_days_remaining`'i artırıyordu; `journey_total_days` yerinde
kalınca `get_days_travelled() = total − remaining` negatife düşüp sıfıra kırpılıyordu. **On gün yürüyen
kervan bir gecikme kartı çekince yol ekranında başlangıç noktasına dönmüş görünüyordu** ve ne kadar yol
aldığını bir daha göremiyordu. Günlükte 4 günlük bir yolun 40 güne çıktığı ve ilerlemenin hiç
görünmediği koşu bunu açığa çıkardı. Yeni `GameSession.extend_journey()` kalan günle toplam günü
birlikte değiştiriyor; kısaltma (kestirme) da aynı muhasebeyi tutuyor, yürünen gün geri alınmıyor.
Ölçüldü: yol planlanandan ortalama ×1,10–×1,21 uzuyor, yani kaçak bir büyüme yok — görünürlük
sorunuydu.

### K2 · Yolda yiyecek aramak yalnız zaten kurtulacak olanı kurtarıyordu
Verim yalnızca **en iyi sezgiye** bakıyordu: altı kişilik kervan bir kişilik kadar buluyordu. Bir arama
günü bir yol günü yiyor; getirisi o günün erzağını aşmazsa aramak durumu **kötüleştiriyordu**. Yeni
`FORAGE_PER_EXTRA_HAND = 0,35` ile fazladan her el payı büyütüyor. Arama hâlâ çare değil, bedelli bir
erteleme — ama artık büyük kervan için de gerçek bir tutunma hamlesi.

### K3 · Üç kapı sebep söylemeden ölüyordu
Oyunun kendi kuralı tutulmuyordu. `get_lodging_block_reason`, `get_feast_block_reason`,
`get_church_donation_block_reason` eklendi; ekranlar yazıyor. Şölen için üç ayrı sebep (kimse yorgun
değil · bugün zaten verildi · kese yetmiyor) tek bir soluk düğmeye çıkıyordu.
**Ekranda doğrulandı:** *"Geceyi burada geçir (15 GG) — Kese yetmiyor"*, *"Kadroya Ziyafet Çek (90 GG) —
Kimsenin böyle bir geceye ihtiyacı yok"*, *"Bağış yap (30 GG) — Kese yetmiyor"*.

### K4 · Teslimat kaç tane eksik olduğunu söylemiyordu
Günlüklerin en çok çarpılan ikinci kapısıydı (180+ kez). `get_chain_block_reason` ve sayılı
`get_chain_missing_text` eklendi; düğme artık *"Teslim et — 4 tane eksik"* diyor.

### K5 · Emirler paneli kadro listesinin üstüne biniyordu
Varsayılan konum alttaki **en ince** şeridin yüksekliğine göre hesaplanıyordu, bütün HUD yığınına göre
değil; panel ilk yoldaşın satırını örtüyordu. Ekran görüntüsüyle bulundu ve düzeltildi.

### K6 · Açlık kararsızdı (önceki turdan devam)
Yolda erzak bitince oyuncunun elinde hiçbir hamle yoktu; açlıktan ölmek bir karar değil bir şanssızlıktı.
**Yiyecek ara** emri yola geldi (biyom ve mevsim paylı, bedeli bir gün + stres).
**Ekranda doğrulandı:** emir panelinde *"Yiyecek ara (+6 erzak, 1 gün)"* — kazancını da bedelini de
yazıyor, ve bozkır payını hesaba katıyor.

### K7 · Baştan başlamak bilgiyi de siliyordu (önceki turdan devam)
`LineageArchive` artık görülen kartları ve fiyat defterini taşıyor. Yeni kervan daha **güçlü** değil,
daha **bilgili** başlıyor: fiyatlar "kulaktan dolma" (`PRICE_SOURCE_RUMOR`) ve eskimiş olarak geliyor.
Kıtlık aynı sertlikte kalıyor; kaybedilen tek şey ilerleme, öğrenilenler değil. Kullanıcının
*"sonuçtan değil süreçten keyif"* cümlesinin mekanik karşılığı bu.

---

## 6. Baş bulgu: oyunun ortası yok

Kullanıcının istediği bant şu: **çaba göstererek, az sayıda ölümle devam edebilmek.** Ölçüm o bandın
var olmadığını söylüyor.

- Dört profil: **20/20 sefer, sıfır ölüm.** Hiç zorlanmadılar.
- İki profil: **iki koşunun ikisinde de kervan bitti**, ortalama 5–6,5 seferde.
- Arada hiçbir şey yok.

Ayıran değişken beceri değil, **tek bir başlangıç kararı**: sofrayı herkese mi açtın. Herkesi besleyen
ölüyor, isimsiz ekibi aç bırakan ölümsüz oluyor. Oyuncunun yolda verdiği hiçbir karar bu ikiliği
değiştirmiyor.

Arkasındaki sebep aritmetik: **ticaret dışında, günlük tüketimi aşan tek bir gelir yok.**

| hamle | getirisi | bedeli | net |
|---|---|---|---|
| şehirde bir gün çalışmak | ×1,4 günlük erzak | 1 gün (= 1 günlük erzak) | +0,4 gün |
| yolda yiyecek aramak | bir günlük erzak civarı | 1 yol günü + stres | ≈ 0 |
| dövüşü kazanmak | 25–85 GG | stres, yara, yarısı kaybediliyor | küçük |
| satmak | sınırsız | sermaye gerekir | **tek gerçek gelir** |

Sermayesi olmayan ya da vicdanı kriz fiyatından satmaya izin vermeyen oyuncu için **matematiksel
olarak** ayakta kalmanın yolu yok. Bedeli Soran 17 gün yiyecek aradı, 12 gün çalıştı ve yine de öldü;
daha iyi oynayabileceği bir yol yoktu. Bu bir denge ayarı değil, eksik bir sistem.

---

## 7. Öneriler

Sıralama etkisine göre. Hiçbiri bir sistemi kesmiyor; hepsi **derinleştiriyor** (kullanıcının ilkesi).
Birinciler kullanıcının kararını bekliyor, çünkü yeni sistem açıyorlar.

### G1 — Ticaret dışı bir gelir: kervanı kiraya vermek *(kullanıcı kararı gerekiyor)*
Oyunun en büyük açığı. Kervan bir şehirde **ücretle yük taşıyan** olabilmeli: sermaye koymadan,
teslimat başına ödeme. Düşük kâr, yüksek güvenlik, itibar gerektirir. Böylece Defter Tutan ve Bedeli
Soran profilleri *oyunun sevdikleri kısmını oynayarak* ayakta kalabilir. Ticaret kesilmez; ticaret hâlâ
zenginliğin tek yolu olur, bu yalnızca **yoksulluğun tabanı** olur.
→ Kıtlık hedefiyle (Y-C21) birebir uyumlu: "kervanı bir noktadan öbürüne sağ salim ulaştırmak".

### G2 — İsimsiz ekibin açlığı deftere geçsin *(kullanıcı kararı gerekiyor)*
Hayatta kalan dört profil ekibi 60–98 gün aç bıraktı ve **hiçbir satır yazılmadı.** "Defter unutmaz"
sütunu burada tutulmuyor: adı olmayanın açlığı bedava. Öneri: ekip üst üste aç kaldıkça defterde adsız
bir satır biriksin ("üçüncü hafta, arabacılar yine kuru ekmek"), moral düşsün, ve bir eşikten sonra
tayfadan biri **ad kazanarak** ayrılsın ya da kalsın — isimsizlik bir muafiyet değil, bir seçim olsun.

### G3 — Vagon atölyesine girdi yolu aç
108 kez "Yeterli malzeme yok", 20 seferde 5 üretim. Tarifin girdileri pazarda görünmüyor. Öneri: pazar
ekranında bir mal, bilinen bir tarifin girdisiyse işaretlensin ("İp — Sargı için gerekli"); üretim
ekranında eksik girdi "nereden alınır" bilgisiyle gelsin. Yeni sistem değil, var olan sistemi
görünür kılmak.

### G4 — Kişilerin istedikleri pazara taşınsın
Kişinin ne istediği **kendi şehrinde** yazıyor; malı ise **başka şehirde** alıyorsun. Bilgi var, kararın
verildiği yerde yok. Öneri: açık istekler yol ekranındaki deftere ve pazar ekranına bir satır olarak
geçsin ("Kirsavel'de Mathis 4 kürk bekliyor, 12 gün kaldı"). K4 ile birlikte zincir sistemi ilk kez
oynanabilir olur.

### G5 — Kaybedilen dövüşün bir bedeli olsun
Ucunda Yürüyen 8,5 dövüşün yarısını kaybetti ve **kimse ölmedi.** Zorluğu arayan oyuncu için oyunun en
sert görünen sistemi sahte. Ölümün Kıyısı kuralı korunsun (ölüm kurada olmasın), ama kayıp bir yara,
bir ekipman, bir mal ya da kalıcı bir sakatlıkla ödensin — yere düşen biri bedelsiz kalkmasın.

### G6 — Vagon büyümesinin bir anlamı olsun
120 vagon alındı; parti dört kişide tavanlı olduğu için 73 kez "Parti dolu". Sayaç artıyor, oyun
değişmiyor. Öneri: vagon sayısı arttıkça **gözle görülür bir bedel** gelsin (kolon uzar, tempo düşer,
isimsiz ağız artar, haydut ilgisi artar) — büyümek bir karar olsun, bir düğme değil.
→ "Çözülemeyen problem" dersiyle (Y-C24) aynı yöne bakıyor: büyüme kendi krizini doğursun.

### G7 — Avansın kapısı ne zaman açılacağını söylesin
79 kez reddedildi ("Kredi hattı dolu", "Lonca sana güvenmiyor") ve hiçbirinde *ne yapması gerektiği*
yazmıyordu. Öneri: sebebin yanına eşik yazılsın ("İtibar 12 gerekiyor, sende 7").

### G8 — Panodaki ilanın neden alınamadığı yazılsın
Günlükteki tek kalan sessiz kapı (25 kez). `CaravanPlan.can_add_offer` zaten sebebi biliyor; ekrana
çıkmıyor.

---

## 7a. Günlüklerin kendisi

Altı günlüğün tamamı `docs/design_notes/oyuncu_gunlukleri/` altında, gün gün. Bir örnek — Defter
Tutan'ın birinci koşusunun sonu:

```
- 12. gün · serai_orbeyan · anladım — herkesi besleyemiyoruz; sofra ekibe indirildi
- 15. gün · serai_orbeyan · anladım — erzak eksik; yine de yola çıkılıyor
- 55. gün · serai_orbeyan · anladım — Kervanbaşı açlıktan öldü
- 55. gün · selvicar · anladım — kervan bitti; defter kapandı ve yeni bir soy başlayacak
```

Kırk gün boyunca her gün bir şey denendi. Oyun kırk gün boyunca aynı cevabı verdi.

---

## 8. Yöntemin sınırları

- **Altı profil altı oyuncu değildir.** Her biri bir fayda fonksiyonu; gerçek oyuncu tutarsızdır,
  sıkılır, fikir değiştirir. Bu araç *mekaniğin cevabını* ölçer, eğlenceyi değil.
- **Savaş politikası tek.** Açgözlü politika (yaralıyı iyileştir, en zayıfa en sert vur) bir oyuncunun
  politikası değil; dövüş sayıları yön gösterir, kesin değildir.
- **Koşu başına 20 sefer sınırı var.** Hayatta kalan dört profilin "20/20" sonucu "sonsuza kadar yaşar"
  demek değil, "yirmi seferde ölmedi" demektir.
- **İki koşu azdır.** Tohumlar sabit (770000, 771013); eğilimi gösterir, dağılımı değil.
- Ekran doğrulaması dört karede yapıldı; G1–G8 önerilerinin hiçbiri henüz uygulanmadı.

---

## 9. Kullanıcının kararları ve uygulanan hâli (2026-11-06)

Sekiz önerinin yedisi kabul edildi, biri reddedildi. Hepsi oyunda,
testli (`tests/test_persona_fixes.gd`, süit 32 129 geçti) ve oyuncunun
gördüğü her biri gerçek ekran görüntüsüyle doğrulandı
(`tests/screenshot_g_fixes.gd`).

### G1 — reddedildi
> *"Oyunun ticaret odağını arttırıyor, istemiyorum ve tüccar konvoyu almaktan
> tek farkı erzak ücreti vermiyorsun gibi herhalde. Hoşuma gitmedi, hissi
> zayıflatıyor."*

Gerekçe yerinde: önerilen "kervanı ücretle yük taşımaya vermek" mekanik
olarak var olan tüccar konvoyunun bir kopyasıydı ve kıtlık hissini
yumuşatıyordu. **Yapılmadı.** Yerine ortadaki bandı G2'nin dağılma kuralı
açtı (aşağıda ölçüldü).

### G2 — dağılma *(geliştirildi ve uygulandı)*
> *"Bir ekip 60 gün aç kalıp bir arada kalamamalı. Dağılmalı. Deftere de
> yazılmalı tabii."*

Öneri bir defter satırıydı; kullanıcı onu bir **mekaniğe** çevirdi. Kodda
bulunan delik şuydu: tayfa üçüncü aç geceden itibaren zaten ölüyordu, ama
`_sync_crew_names()` boşalan eli **anında ve bedavaya** dolduruyordu, çünkü
hedefi vagon sayısıydı. Tüketim ve kapasite de vagondan hesaplandığı için
aç bırakmanın tek bedeli bir defter satırıydı.

Yeni kural — *el sayısı gerçektir*:

| | eski | yeni |
|---|---|---|
| aç gece 3+ | biri ölür, yeri bedava dolar | bir el **ayrılır**, yeri **boş kalır** |
| aç gece 7+ | aynı | artık ölür (yürüyecek hâli kalmamıştır) |
| tüketim | vagon sayısından | **el sayısından** (kervan küçülerek yaşar) |
| taşıma gücü | vagon sayısından | **sürülebilen** vagondan |
| yeri doldurmak | kendiliğinden | şehirde parayla; fiyat kaç eli aç bıraktığına bağlı |

Sürülemeyen vagonun yükü sürülebilenlere taşınır, sığmayan yolda kalır
("domino" dersi, Y-C23). Lider her zaman bir vagonu kendi sürebilir -
yoksa son elini kaybeden kervan kilitlenirdi.

**Ölçüm (aynı tohumlar, aynı altı profil):**

| profil | sefer | ölen koşu | ölüm | ayrılan el | tutulan el | teslimat |
|---|---|---|---|---|---|---|
| Kâğıt Üstünde Tüccar | 20,0 (=) | 0/2 (=) | 0,0 (=) | 7,5 | 2,5 | 21,0 → **10,0** |
| Defter Tutan | 5,0 (=) | 2/2 (=) | 2,5 (=) | 3,0 | 0,0 | 1,0 (=) |
| Ucunda Yürüyen | 20,0 (=) | 0/2 (=) | 0,0 (=) | 10,0 | 6,5 | 15,0 → **11,0** |
| Listeyi Kapatan | 20,0 (=) | 0/2 (=) | 0,0 (=) | 11,0 | 6,5 | 19,5 → **15,5** |
| **Bedeli Soran** | 6,5 → **12,0** | 2/2 → **1/2** | 3,5 → **1,0** | 8,0 | 2,5 | 4,0 → 5,5 |
| Vagonu Kuran | 20,0 (=) | 0/2 (=) | 0,0 (=) | 7,5 | 2,5 | 19,0 → **10,0** |

İki şey birden oldu:

1. **Aradaki bant açıldı.** Herkesi besleyen Bedeli Soran artık 6,5 değil
   **12 sefer** yaşıyor, ölümü 3,5'ten **1,0'e** düşüyor ve iki koşunun
   yalnız birinde bitiyor. Kullanıcının istediği hâl bu:
   *çaba göstererek, az sayıda ölümle devam edebilmek.*
2. **Bedava hayatta kalma bitti.** Dört "ölümsüz" profil hâlâ ölmüyor, ama
   artık **yarı yarıya az taşıyor**: teslimatları 21→10, 19→10, 19,5→15,5.
   Ekibi aç bırakmak kervanı öldürmüyor, **küçültüyor** - bugünün erzağını
   yarının yüküyle ödüyorsun.

En çok çarpılan kapı da değişti: artık **"eksik el tutmak — Kese yetmiyor"**
(152 kez). Bedel ısırıyor.

**Dürüst kalan:** Defter Tutan hâlâ iki koşuda da bitiyor (5 sefer). Onun
sorunu açlık değil gelirsizlik; G1 tam olarak onu çözecekti ve reddedildi.
Aradaki fark can alıcı: Bedeli Soran 29 gün şehirde çalıştı ve 26 gün yolda
yiyecek aradı, Defter Tutan 7 ve 8. **Can simitleri işe yarıyor ama
kullanılmaları gerekiyor**; tavernada oturup kart okuyarak geçinen bir
oyuncu hâlâ ölüyor. Bunun kabul edilebilir olup olmadığı bir tasarım
kararı - sistem değil, tempo meselesi.

### G5 — yenilginin kalıcı bedeli *(uygulandı)*
Yere düşen artık bedelsiz kalkmıyor: zar **hangi** yaranın geleceğine
atılıyor, gelip gelmeyeceğine değil (eskiden %50). Ölümün Kıyısı kuralı
duruyor - ölüm hâlâ kurada değil. Kaybedilen dövüşte haydut yükten de
alıyor (`plunder_cargo`, payın dörtte biri, bir mal rastgele bağışlanır);
erzağa dokunmuyor, çünkü açlık ayrı bir sistem ve yenilgi onu
tetiklememeli.

### G6 — kolonun boyu *(uygulandı)*
İlk vagon bedava. Sonraki her vagon hızı %5 düşürüyor (taban ×0,70) ve
tehlikeyi %4,5 artırıyor (tavan +%20). Planlayıcının tehlike dökümü payı
**adıyla** yazıyor: *"4 vagonluk kolon göze batıyor +7"* - gizli bir ceza
hatadan ayırt edilemez. Vagon hâlâ kapasite ve parti yeri açıyor: sistem
kesilmedi, bedeli eklendi. G2 ile birlikte büyük kervan açlığa da kırılgan
hâle geliyor ("büyüme kendi krizini doğursun", Y-C24).

### G3 — atölyenin girdileri *(uygulandı)*
Üretim düğmesi artık *"Yeterli malzeme yok — eksik: 2 Top Kumaş"* diyor; ve
pazarda o mal *"Bandaj Sar için"* diye işaretleniyor. Bilgi artık alımın
yapıldığı yerde. (Onarım tarifinde sebep hasar yokluğuysa malzeme listesi
eklenmiyor - yanıltıcı olurdu.)

### G4 — bekleyen kişiler *(uygulandı)*
`People.open_requests()` / `who_wants()` ile açık istekler tek yerden
okunuyor; pazarda o malın satırında *"Mathis ×4 bekliyor (Kirsavel, 12
gün)"* yazıyor. Teslimat düğmesi de kaç tane eksik olduğunu söylüyor (K4).

### G7 — avansın eşiği *(uygulandı)*
`get_advance_block_detail()`: *"Lonca sana güvenmiyor: 12 itibar gerekiyor,
sende 7"*, *"Kredi hattında 30 GG kaldı, en az 60 GG gerekiyor"*.

### G8 — pano ilanı *(kullanıcının istediği gibi)*
> *"Alınmaya çalıştığında bir uyarı verebilir."*

Kutucuk artık **kapatılmıyor**; tıklanıyor ve olmuyorsa sebebini yazıyor
(*"Bu yük vagonlara sığmıyor: önce yer aç."* / *"Bu ilan için boş vagon
yok."*). Ölü bir kutucuk oyuncuya neyin eksik olduğunu öğretmiyordu.

### Ekranda doğrulananlar
`tests/screenshot_g_fixes.gd`, beş kare: kervansarayda *"Eksik el: 3. Boşta
duran vagon yük alamaz…"* + *"El tut (65 GG)"*; yol durumunda *"3 el eksik ·
2 vagon sürülemiyor"*; pazarda *"Bandaj Sar için"*; planlayıcıda *"4 vagonluk
kolon göze batıyor +7"* ve *"Toplam vagon: 4 · 3 el eksik · 2 vagon
sürülemiyor"*; atölyede *"eksik: 2 Top Kumaş"*.

Ekran görüntüsü üç küçük kusur daha yakaladı ve üçü de düzeltildi:
planlayıcı kolonun payını sayısız basıyordu (iki parçalı anahtar tek
argümanla biçimlendiriliyordu); pazarın not satırı dar olduğu için eyleme
dönüşen notlar kesiliyordu (artık başa alınıyor, tam metin ipucunda); ve
onarım tarifinde "hasar yok" cevabının yanına malzeme listesi ekleniyordu.
