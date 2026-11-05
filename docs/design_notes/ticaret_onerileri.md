# Ticaret ve kasvet: öneriler, madde madde (2026-11-05)

Gerekçeler, ölçümler ve referanslar `ticaret_ve_kasvet.md`'de. Bu dosya **onay listesi**: her madde ayrı ayrı
kabul edilebilir ya da reddedilebilir. Madde numaraları kalıcıdır ("P5 onaylandı" demen yeter).

Her maddede: **Ne** · **Oyuncu ne görür** · **Kod** · **Kırılan** · **Neden** · **Boy** (S/M/L).

Sistem kaldırma kararı kullanıcınındır (CLAUDE.md, *derinleşme asla sadeleştirme* sınırı). Hiçbiri onaysız
uygulanmaz.

---

## A. PAZARLIK — en ucuz kaldırma, en büyük kip kazancı

### P1. Mini oyunu tek karara indir

**Ne.** Üç turlu teklif döngüsü kalkar. Yerine tek ekran, üç düğme: **Kabul et · Diren · Çık git**.
"Diren" **bir kez** atılır (Karizma zarı). Kazanırsan indirim; kaybedersen fiyat *artar* (tüccar sertleşir) ve
bölgesel itibar −1. İkinci kez direnilemez. Kaydıraç yok, sayı girme yok, sabır çubuğu yok.

Bugünkü kazanç aralığı **%20–45 indirim**. Öneri: **%0–15**, ortalama ~%6. Pazarlık bir gelir kaynağı değil,
küçük bir risk.

**Oyuncu ne görür.** Tezgâhta fiyat, altında üç düğme. İki tık, en çok üç.
Bugün: 3 tur × (kaydıraç sürükle + tık) + ültimatom = 7-8 etkileşim.

**Kod.** Silinen: `MAX_ROUNDS`, `current_patience`, `CREDIBLE_MARGIN`, `INSULT_MARGIN`,
`FLOOR_HARDEN_PER_ROUND`, `concessions`, `get_slider_range`, ültimatom akışı.
`haggling_session.gd` 215 → ~60 satır · `haggling_panel.gd` 227 → ~90 satır.
Korunan: `FLOOR_PER_CHARISMA`, `FLOOR_PER_REPUTATION`, `WALKOUT_REPUTATION_PENALTY`, yoldaki
`HAGGLE_FAIL_MORALE −8` ve `HAGGLE_HOURS 1.0`.

**Kırılan.** `test_haggling.gd` yeniden yazılır (288 → ~90 satır, 12 test → ~5). 39 çeviri anahtarının ~25'i
düşer. Codex'in *"Pazarlık: oyunun para basma noktası"* bölümü yeniden yazılır. `market.gd`'de 42, `road_journey.gd`'de
37 referans sadeleşir. **Başka hiçbir sistem pazarlığı okumuyor** — `MarketPricing`, `MarketConditions`, borç,
kontratlar, `Standing`, atölye hiç etkilenmez.

**Neden.** Üç turlu stat döngüsü bir optimizasyon oyunudur: ölçülebilir bir "doğru cevabı" vardır. Kıtlığın doğru
cevabı yoktur (`kitlik_tasarim_dersleri.md`). Kipin kendisi oyunla çelişiyor.

**Boy.** M.

---

### P2. Pazarlığın konusu fiyat değil, vicdan olsun

**Ne.** Kıtlık derinleştikçe (`Scarcity`) "Diren"in anlamı değişir: ısrar ettiğin satıcı da aç.
Diren → **başarılı** olursan malı alırsın **ama** o bölgede `Standing` −2 ve Defter'e bir satır düşer.
Kıtlık sığken bu olmaz; derinleştikçe her pazarlık bir seçim olur.

**Oyuncu ne görür.** Düğmenin metni değişir ("Diren" → "Üstele"), sonuç ekranında bir cümle:
*"Çuvalı aldın. Kadın arkandan baktı."* Ve Defter'de o satır.

**Kod.** `HagglingSession`'a kıtlık payı girdisi; `Standing` ve `CaravanLedger` çağrısı; 4-6 yeni çeviri satırı.

**Kırılan.** Yok (yeni dal).

**Neden.** Kıtlık derslerinin *"bedel adı olan birine düşer"* kuralının ticaret tarafı. Ticaret ahlaki bir eylem
olur; para basma noktası olmaktan çıkar.

**Boy.** S.

---

### P3. `scripts/ui/haggling.gd` silinsin

**Ne.** 104 satır, `scenes/game/haggling.tscn`, `Nav.HAGGLING` ve `test_selector.tscn` girdisiyle birlikte.

**Oyuncu ne görür.** Hiçbir şey — bu sahne **oyunun akışında değil**, yalnız F1 geliştirici menüsünden açılıyor.

**Kırılan.** `test_navigation.gd`'de 2 satır.

**Neden.** Ölü yüzey. P1 onaylanmasa bile silinebilir.

**Boy.** S. **Bu madde diğerlerinden bağımsız.**

---

### P4. Pazarlık Zekâ mı Karizma mı?

**Ne.** Bugün `market.gd:896` `HagglingSession`'ın `player_speech` yuvasına **Zekâ** besliyor, Karizma ikinci
parametre. Ad ile içerik uyuşmuyor. Üç yol:

| | Seçenek | Anlamı |
|---|---|---|
| a | **Karizma** olsun (önerim) | "Konuşma" Karizma'dır; tek stat, tek anlam |
| b | Zekâ kalsın, ad `player_judgement` olsun | Fiyatı bilmek Zekâ işidir |
| c | İkisi de kalsın, ağırlıklar belgelensin | Bugünkü hâl, yalnız yazılı |

**Önerim (a)**, ve Zekâ'nın pazardaki işi **fiyat defterini okumak** olsun (bkz. P15).

**Boy.** S.

---

## B. PAZAR — kesme yok, çevirme var

### P5. Şehirde mal biter ⭐ *en küçük iş, en büyük his kazancı*

**Ne.** Bugün `MarketConditions` **fiyatı** değiştiriyor ama **stok yok**: kesen yettiği sürece istediğin kadar
alırsın. Öneri: mal başına stok, kıtlık derecesine ve şehrin durumuna bağlı. `Scarcity` (50 satır) zaten var.

Ölçü önerisi (kıtlık sığken): başkentte 3-4 mal stoklu, kasabada 1-2, kervansarayda hiç. Kıtlık derinleştikçe
hepsi düşer; erzak en önce biter.

**Stok hesaplanır, saklanmaz** — `MarketConditions`'ın doğal durumları gibi tohumdan. Yoksa kaydı yeniden yükleyip
rafı doldurmak mümkün olurdu.

**Oyuncu ne görür.** Tezgâhta fiyatın yerinde çoğu zaman **"yok"**. Erzak bulunan şehir bir olaydır. Altının
anlamı düşer: cebin dolu, çuvalın boş.

**Kod.** `MarketConditions`'a stok fonksiyonu; `market.gd`'de engel satırı — **zaten var** ("stok yok" engeli
yazılı ama hiç tetiklenmiyor); `CaravanPlanner`'a uyarı satırı.

**Kırılan.** `simulate_career` yeniden ölçülür (kervan artık istediğini alamaz). P9 ile birlikte düşünülmeli.

**Neden.** *This War of Mine*'ın tek en önemli kararı: para birimi yok, değer kıtlık tarifiyle anlatılıyor.
Kıtlık bir **para** sorunu değil **arz** sorunu olmalı — para sorunu çözülür, arz sorununa dayanılır.

**Boy.** S.

---

### P6. Takas

**Ne.** Para yetmediğinde ya da şehrin hazinesi bittiğinde mal-mala değişim. Kıtlık derinleştikçe varsayılan hâl
olur; altın yalnız vergi, geçiş ücreti ve hekimde iş görür.

**Oyuncu ne görür.** `MarketScale`'in (351 satır) bir kefesinde senin malın, öbüründe onunki. Fiyat yok,
**denklik** var — kolun eğimi zaten değeri gösteriyor, görsel dil buna hazır.

**Kod.** Yeni ekran yok; `market.gd`'nin fişine bir kip ve terazinin ikinci kefesine mal.

**Kırılan.** Yok.

**Neden.** Altının değersizleşmesi kıtlığın en somut ifadesi. Ve oyuncuyu "en kârlı" yerine "neyden vazgeçebilirim"
sorusuna taşır.

**Boy.** M.

---

### P7. Görünür fiyat katmanı 7'den 3'e insin

**Ne.** Bugün oyuncu tooltip'te **7 resmî katmanı** `×1.24` gibi sayılarla görüyor (yer, yerleşim, enflasyon,
mevsim, baskı, olay, dünya); **11 çarpan daha gizli** (kıtlık, kültür perki, Tellal indirimi, erzak çarpanı, toplu
indirim, tazelik, geri satış tavanı, ticaret lekesi, kapı komisyonu, aç şehir zammı, şehir hazinesi).

Öneri: oyuncu **sayıyı değil nedeni** görsün — en çok üç kelime: *"kıtlık · mevsim · burada aranıyor"*. Gizli on
bir çarpan **kalsın** (dünyanın derinliği onlar), görünür yüzey elektronik tablo olmaktan çıksın.

**Oyuncu ne görür.** Satır notunda çarpan yok, sıfat var.

**Kod.** `price_layer_text.gd` (44 satır) yeniden yazılır. `MarketPricing`'e dokunulmaz.

**Kırılan.** 36 `UI_PRICE_*` anahtarının bir kısmı; `test_wording.gd`.

**Neden.** Bilgi oyunu "çarpanları çöz" değil, "nerede ne var bilmiyorsun" olmalı.

**Boy.** S.

---

### P8. Kâr tavanı: servet biriktirilemesin

**Ne.** Ticaretin kârı **yolda kalmaya** yetsin, servete yetmesin. Yeni araç gerekmiyor: P5'in stoğu, şehir
hazinesi (`CITY_GOLD_DEFAULT 260 / MAX 900 / REGEN %5`) ve geri satış tavanı (`BUYBACK_SHARE`) zaten var,
ayarlanacak.

**Ölçü.** `simulate_career`, 40 sefer sonunda kesenin eğrisi: hedef **yatay**, yükselen değil.

**Kırılan.** Denge ölçümü yeniden koşar; vagon alım eşikleri (`WAGON_PURCHASE_BASE_COST`) gözden geçirilir.

**Neden.** *At the Gates* dersi: kervan ekonomisi merkezi gölgeleyince ekonomi kervandan koparıldı.

**Boy.** M (çoğu ölçüm).

---

## C. ERZAK SÖZÜ — tek karar, en önemlisi

### P9. "Doğru stoklayan asla aç kalmaz"

Oyunun en korunan sözü. Planlayıcı tam rezervi önceden hesaplıyor; `test_route_terrain` ve `test_temperature`
80+ rota/mevsim kombinasyonunda kimsenin aç kalmadığını doğruluyor. **Bu söz "yoklukta kıvranmak" ile doğrudan
çelişiyor:** doğru stoklayabilen oyuncu tanım gereği kıvranmaz.

| | Yol | Sonuç | Bedel |
|---|---|---|---|
| **A** | Söz olduğu gibi kalsın | Kıtlık his düzeyinde kalır (görüntü, metin, kart). Mekanik güvenlik ağı durur. Dürüst ve adil, ama "kıvranmak" olmaz | Yok |
| **B** ⭐ | Söz **arza** bağlansın | *"Stok bulabilirsen aç kalmazsın."* Planlayıcı doğru sayıyı söylemeye devam eder; **o sayıyı satın alamayabilirsin.** Haksızlık yok (hesap görünür), kıvranma var (mal yok) | `test_route_terrain` / `test_temperature` iddiaları yeniden yazılır: "yeterli erzakla çıkan aç kalmaz" — "yeterli erzak her zaman alınabilir" değil |
| **C** | Söz kalksın | En sert; planlayıcının anlamı kalmaz, ölçüm altyapısının çoğu çöpe gider | L, ve geri dönüşü zor |

**Önerim B.** Sözü bozmadan anlamını değiştirir: açlık bir hesap hatası olmaktan çıkıp dünya hâli olur.
**P5 olmadan B'nin anlamı yok** — ikisi tek karardır.

---

## D. BORÇ — en son, ve kaldırma değil dönüşüm

Hatırlatma: borca **44 kod dosyası** değiyor; 3 olay kartı + zincir, 2 `EventEffect` türü, `RoadDirector`'un kart
öncelik dalı, 51 çeviri anahtarı, 14 test dosyası, 2 Codex bölümü, kökenlerin yarısı, yola çıkış morali, lonca
hizip itibarı, 15 ekran satırı. Aşağıdaki dönüşüm bunların **çoğunu korur**.

### P10. Faiz kalksın

**Ne.** Silinen: `OVERDUE_INTEREST_RATE 0.15`, `OVERDUE_PERIOD_DAYS 10`, `overdue_periods_applied`, bileşik
birikim, `restructure` (vade uzatma) düğmesi.
Kalan: `principal`, `due_day`, `creditor`, `overdue` (evet/hayır).

**Oyuncu ne görür.** Borç büyümez. Ya ödersin ya ödemezsin.

**Kırılan.** `test_debt.gd`'nin faiz testleri (269 satırın yarısı), `denge_baba_borcu.md` tarihçeye düşer.
**Korunan:** `OVERDUE_REPUTATION_PENALTY 3`, lonca hizip itibarı kaybı, yola çıkış morali −10, üç olay kartı
(koşulları `debt_overdue` ve `debt >= 150` — ikisi de durur).

**Neden.** Oyunun kendi ölçümü faizi mahkûm etti: sert oranla borç 40. seferde **milyonlara** çıktı ve kariyeri
kilitledi; yumuşatılınca **hiçbir şey yapmaz** oldu. Taşıyamadığı ağırlığın altında ezilen bir mekanik.

**Boy.** M.

---

### P11. Borç bir **ada** ve bir **teslimata** bağlansın

**Ne.** Alacaklı genel bir etiket (`DEBT_CREDITOR_MONEYLENDER`) değil, **bir kişi** olsun: adı, bulunduğu şehir,
hatırladığı şey. `People` sistemi (T16-09) zaten var.
Borcun karşılığı çoğu zaman para değil **teslimat**: *"Şu tahılı Drazvor'a götür."* Böylece borç kontrat
sistemiyle aynı şey olur ve kervanın varlık sebebine döner.

**Vade geçerse** aritmetik değil **sosyal** bir şey olur — hepsi var olan kollar:
- o şehrin pazarı sana kapanır (`Standing`),
- alacaklının adamı yolda bulur (`evt_creditor_rider` zaten var),
- kampa mübaşir gelir (`evt_bailiffs_at_camp` zaten var),
- birini alıp giderler (yeni, tek kart).

**Oyuncu ne görür.** Bir yüz ve bir tarih. Sayı tablosu değil.

**Kırılan.** `Debt` yeniden yazılır; kökenlerin borç ayarı (`start_origins`: lonca vesayeti ×2, kaçakçı vade 30,
dul ×0.5) tutar ama anlamı değişir.

**Neden.** Ortaçağ ticari kredisi faiz tablosu değil **güven ve itibar**dı; 1315-16 kıtlığında borç, yiyecek için
borçlanan köylü ve kapıya dayanan alacaklıydı. Ve dramatik olarak: bir yüz, bir yüzdeden korkutucudur.

**Boy.** L.

---

### P12. Borç paneli kalksın, Defter satırı gelsin

**Ne.** `debt_panel.gd` (327 satır) ve üç açılış yeri (Lonca sekmesi, yol emri, miras paneli) gider. Borç
**Defter'de** yaşar: *kime · ne kadar · ne zamana kadar*. Ödeme Lonca'da tek düğme.
**Yoldaki "Borç" emri kalkar** (bugün tempo bedeli −3.0): yolda borçla uğraşmak muhasebe kipinin ta kendisi.

**Oyuncu ne görür.** Borç bir ekran değil, defterinde bir satır.

**Kırılan.** `guild.tscn`'in `DebtsTab`'ı sadeleşir; `road_journey.gd:4286 _open_debt_panel` düşer;
`road_control_panel.gd:412` ve `city_brief_model.gd:35-44` satırları kalır (ihtiyaç listesi iyi çalışıyor).

**Neden.** Dördüncü sütun: *Defter unutmaz.*

**Boy.** M.

---

### P13. Lonca **kredisi** kalksın mı? *(ayrı karar)*

Bugün: itibara bağlı limit (`200 + itibar×25`, tavan 1200), tahsis ücreti %15→%5.

| | |
|---|---|
| **Lehte** | Para sıkışınca bir çıkış yolu oyuncuya nefes verir; itibarın somut bir karşılığı olur |
| **Aleyhte** | **Bu tam olarak kaçış kapağı.** Borç alıp mal alabilen oyuncu kıvranmaz; P5 ve P9'un etkisini sıfırlar |

**Önerim: kalksın.** Yerine lonca sana **mal avansı** versin, karşılığında teslimat istesin (P11'le aynı
mekanik). Para değil yük — ve o yükü taşımak zorundasın.

**Açık hesap kalsın.** Kese eksiye düşünce doğan borç bir kredi değil, *sıfırın altına inememenin adı*; o iyi
çalışıyor.

**Boy.** M.

---

## E. KASVETİ BÜYÜTENLER — ticaret dışı, ucuz, yüksek etki

### P14. Defter sattığını hatırlar

**Ne.** Vebalı şehirde son ilacı satmak → Defter'e satır + o şehirde `Standing` ve `People` tepkisi.
İki sistem de var (T16-09, `Standing`); yalnız ticaret olayları bağlanacak.

**Neden.** Ticaret ahlaki bir eylem olur. Kullanıcının kendi notu: *"sattığımız şey onların tedavi edebildiğini
değiştirir."*

**Boy.** S.

---

### P15. Haber eskir ve yanlış olabilir

**Ne.** `price_book` ziyaret edilen şehirlerin **tarihli** kaydını zaten tutuyor. Üstüne: tavernada ve
kervansarayda haber satın alınabilsin — ucuz haber eski ya da yanlış olsun.

**Neden.** Dördüncü sütun (*Ticaret bilgi oyunudur*) bir tablo olmadan servis edilir; ve P7 ile birlikte bilgi,
görünen bir sayı olmaktan çıkıp **eksikliğe** döner.

**Boy.** M.

---

### P16. Açlık ve yorgunluk **bedende** görünsün ⭐

**Ne.** Bugün ıslaklık, kar ve nefes buharı için yaptığımızın (Y-G25) açlık/yorgunluk karşılığı: çöken omuz,
kısalan adım, incelen siluet, soluklaşan ten. Altyapı hazır — `WalkFigure.set_weather_coat`'un yanına
`set_wear(hunger, fatigue)`.

**Neden.** Kollwitz dersi: **kıtlığın yeri bedendir, çubuk değil.** Açlığı çubukla anlatmak, *Pathologic 2*'nin
"idari iş" eleştirisine giden yoldur; bedende göstermek aynı sayıyı korkutucu yapar.

**Boy.** M. **Ticaret kararlarından bağımsız — bugün başlanabilir.**

---

### P17. Sessiz güne izin ver

**Ne.** `simulate_road_beats` bugün dakikada bir karar/bilgi anı hedefliyor (60-90 sn). Kıtlıkta bu hedef
**gevşesin**: *"bugün de hiçbir şey olmadı ve bir çuval azaldı"* geçerli bir gün olsun, günün sonunda tek satır.

**Kod.** Bir sayı + `RoadDirector`'un sessiz gün dalının yeniden ayarı.

**Neden.** Tarr dersi: tekdüzelik bir kaynaktır. Her dakika bir şey sunan oyun kasvetli değil meşguldür.

**Boy.** S.

---

## Özet tablo

| # | Madde | Boy | Bağımsız mı | Önerim |
|---|---|---|---|---|
| P1 | Pazarlık tek karara insin | M | evet | **evet** |
| P2 | Pazarlığın konusu vicdan olsun | S | P1'den sonra | evet |
| P3 | Ölü `haggling.gd` silinsin | S | **evet** | evet, hemen |
| P4 | Pazarlık Zekâ mı Karizma mı | S | evet | Karizma |
| P5 | Şehirde mal biter | S | **evet** | **evet, ilk** |
| P6 | Takas | M | P5'ten sonra | evet |
| P7 | Görünür katman 7→3 | S | evet | evet |
| P8 | Kâr tavanı | M | P5'ten sonra | evet |
| P9 | Erzak sözü A/B/C | M | P5 ile birlikte | **B** |
| P10 | Faiz kalksın | M | evet | evet |
| P11 | Borç ad + teslimat | L | P10'dan sonra | evet |
| P12 | Borç paneli → Defter | M | P11'den sonra | evet |
| P13 | Lonca kredisi kalksın mı | M | evet | kalksın |
| P14 | Defter sattığını hatırlar | S | **evet** | evet |
| P15 | Haber eskir, yanlış olabilir | M | evet | evet |
| P16 | Açlık bedende görünsün | M | **evet** | **evet** |
| P17 | Sessiz güne izin | S | **evet** | evet |

## Önerdiğim uygulama sırası

1. **P3** (ölü dosya) — karar bile gerektirmiyor
2. **P5 + P9/B** (stok + söz) — tek iş, en büyük his kazancı
3. **P1 + P4** (pazarlık) — en ucuz kaldırma
4. **P7, P14, P17** (üç küçük iş)
5. **P2, P6** (vicdan + takas)
6. **P16** (açlık bedende) — diğerlerinden bağımsız, istenirse öne alınabilir
7. **P8** (ölçüm + ayar)
8. **P10 → P11 → P12 → P13** (borç göçü, en son)

## Ne önermiyorum, tekrar

- Ticaretin tümden kalkması (dördüncü sütun ve kervanın varlık sebebi)
- `Standing`'in ya da şehir koşullarının sadeleşmesi (borcun ve pazarlığın yerine geçecek kollar tam olarak onlar)
- Kontrat sisteminin kaldırılması (P11 onu borçla birleştiriyor, güçlendiriyor)
- Zorluğu sayı büyüterek artırmak (yanlış kipte kasvet değil angarya üretir)
- Atölyenin kaldırılması (6 tarifin altısının da bir tüketicisi var, `OUTPUT_USES` testle sınanıyor)
