# Bölüm 17 — Ticaretin odağı ve kasvet (kullanıcı onayı 2026-11-05)

Gerekçeler `docs/design_notes/ticaret_ve_kasvet.md`, madde madde öneriler
`docs/design_notes/ticaret_onerileri.md`. Kullanıcı 17 maddenin hepsini onayladı.

- [x] **P03 Ölü pazarlık sahnesi silindi**
  - `scripts/ui/haggling.gd` (104 satır), `scenes/game/haggling.tscn`, `Nav.HAGGLING`, test seçici girdisi ve düğmesi.
  - Bu sahne oyunun akışında hiç yoktu: yalnız F1 geliştirici panelinden açılıyordu. Oyuncunun gördüğü pazarlık
    `HagglingPanel`'in pazara ve yola gömülü hâli.

- [x] **P05 Erzağın şehirdeki stoğu**
  - **Asıl boşluk buydu:** erzak planlayıcıda sınırsızdı, kese yettiği sürece tam gereken sayı alınıyordu. Açlığın
    tek gerçek kapısı paraydı.
  - `Scarcity.provision_stock(location, day)` - yerleşim türü × bölge kıtlığı × günlük dalga; **hesaplanır,
    saklanmaz**. `GameSession.buy_provisions` alımın tek kapısı (stok, kese, kargo).
  - Oyuncunun o gün aldığı **kayda yazılıyor**: kayıt şehirde alındığı için yazılmasaydı kaydedip yükleyerek raf
    tazelenirdi.
  - Planlayıcıda yeni satır: "Bu şehirde yalnız %d erzak var."
  - **Ölçüm (2026-11-05):** şehir ort. 88 (74-109), kasaba 44, kervansaray 60; geç oyunda (300+ gün) şehir 60.
    Başlangıç kervanının ihtiyacı: 5 gün 15, 10 gün 30, 17 gün 51, 25 gün 75. Yani şehir uzun bir seferi ucu
    ucuna karşılıyor, kasaba karşılamıyor, kervan büyüdükçe hiçbir yer karşılamıyor.

- [x] **P09 Erzak sözü arza bağlandı (B yolu)**
  - *"Doğru stoklayan asla aç kalmaz"* → *"stok bulabilirsen aç kalmazsın."*
  - Planlayıcı doğru sayıyı söylemeye devam ediyor; `test_route_terrain` ve `test_temperature`'ın iddiaları
    **değişmedi** - ikisi de zaten "yeterli erzakla çıkan kervan aç kalmaz" diyordu, "yeterli erzak her zaman
    alınabilir" demiyordu. Sözün bozulmadan anlam değiştirmesi bu yüzden mümkün oldu.
  - Planlayıcı eksik erzakla yola çıkmayı hiç kilitlemiyor (iki basışlı onay zaten vardı): kıtlık bir çıkmaz değil
    bir karar.
  - **Kabul:** `tests/test_provision_stock.gd` (11 test), `tests/screenshot_provisioning.gd` üç kare
    (şehir / kasaba / geç oyun kıtlığı).

- [x] **P01 Pazarlık tek karara indi**
  - Üç tur, kaydıraçlı teklif, ciddiyet eşiği ve ültimatom kaldırıldı. Yerine üç düğme: **Kabul Et · Diren ·
    Çık git**. Direnmek **bir kez** atılır; şansı ekranda yazılı (%15-85).
  - Eski tasarımın hatası sömürü değil **kip**ti: üç turlu bir teklif döngüsünün ölçülebilir bir "doğru cevabı"
    vardır, kıtlığın yoktur. Codex'teki bölüm başlığı da itiraftı: *"Pazarlık: oyunun para basma noktası."*
  - Kazanç tavanı %45'ten **%15**'e indi. Kaybedilen direniş fiyatı %10 artırır ve 1 itibar yer - ama pazarlığı
    bitirmez: artmış fiyatı kabul etmek ya da kalkmak hâlâ oyuncunun kararı.
  - **Ekran görüntüsünde yakalanan kusur:** `DISCOUNT_BASE` yokken becerisiz bir kervanda "kazanırsan 19 GG,
    yoksa 21 GG" yazıyordu - istenen fiyat da 19'du. Kazancı görünmeyen bir risk düğmesi karar değil tuzaktır;
    %4 taban indirim eklendi ve kazancı yuvarlamada kaybolan masada düğme hiç gösterilmiyor
    (`push_is_worth_it`).

- [x] **P04 Tek stat: Karizma**
  - Eskiden `player_speech` yuvasına Zekâ, ikinci parametreye Karizma besleniyordu; ad ile içerik uyuşmuyordu ve
    "en iyisini al" ikisini aynı şeye indirgiyordu. Konuşma Karizma'dır; Zekâ'nın pazardaki işi fiyat defterini
    okumak.

- [x] **P02 Kıtlıkta konu fiyat değil (vicdan dalı)**
  - Bölge kıtlığı 0.45'i geçince "Diren" → **"Üstele"** olur, ekrana *"Karşındaki de aç."* düşer. Üsteleyip
    kazanmak malı verir, **o bölgedeki itibarı 2 puan düşürür** ve deftere `LEDGER_CAUSE_HAGGLE_INSISTED`
    satırı girer (`CaravanLedger.KIND_TRADE`).
  - Kıtlık derslerinin *"bedel adı olan birine düşer"* kuralının ticaret tarafı. Yolda (haydut, haraç)
    kıtlık geçilmiyor: orada vicdan dalı kapalı, bedel moral (-3).
  - **Kabul:** `tests/test_haggling.gd` (11 test, eski 12 testin tamamı yeniden yazıldı),
    `tests/screenshot_haggling.gd` dört kare (açılış / kaybedilmiş direniş / kıtlıkta Üstele / üstelenmiş).
  - Ölü çeviri anahtarları silindi (15 adet: `UI_HAGGLE_RANGE`, `_ROUNDS`, `_YOUR_OFFER`, `_SUBMIT`, `_REJECT`,
    `_LOG`, `_OPENING`, `_RULES`, `_INSULTED`, `_CREDIBLE`, `_NOT_CREDIBLE`, `_COUNTER`, `_ULTIMATUM`,
    `_FINAL`, `_YOU_OFFERED`). Codex bölümü yeniden yazıldı.

- [x] **P07 Görünür fiyat katmanı 7'den 3'e indi**
  - Satır notunda artık çarpan yok ve en çok **üç neden** yazılıyor (`PriceLayerText.MAX_MARKS`), en güçlüsü
    başta. Gizli on bir çarpan yerinde: kesilen tek şey, oyuncunun çözebileceği bir bilmece olduğu yanılsaması.
  - Yeni söz: **Kıtlık**, yalnız yiyecekte ve yalnız `Scarcity.HUNGRY_CITY_FROM` (0.50) üstünde, ilk sırada.
  - **Ekran görüntüsünde düşen iki deneme:** (1) çeviri CSV'si içe aktarılmadığı için ham anahtar
    (`UI_PRICE_TAG_SCAR...`) görünüyordu; (2) eşik 0.35'ken bölgelerin tabanı 0.12-0.55 olduğu için "Kıtlık"
    birinci günden itibaren her malın altında yazıyordu - **her yerde olan bir söz hiçbir şey söylemez.**
  - **Kabul:** `tests/screenshot_price_marks.gd` iki kare (sakin şehir / kıtlık şehri, yan yana).

- [x] **P14 Defter sattığını hatırlar**
  - Ticaret bugüne kadar hiçbir ahlaki iz bırakmıyordu: para ve stok değişiyor, kimse bir şey hatırlamıyordu.
  - İki yön, ikisi de `GameSession._remember_trade`'de: **iyilik** (vebalı şehre ilaç ya da aç şehre ≥3 yiyecek)
    bölgesel itibarı +2 yapar, şehrin adı olan üç kişisinin gönlünü artırır, deftere `LEDGER_CAUSE_TRADE_MERCY`
    yazar; **vurgun** (`is_profiteering_sale` - krizin şişirdiği fiyattan satmak) itibarı -3 yapar, kin biriktirir,
    `LEDGER_CAUSE_TRADE_PROFITEER` yazar.
  - Sıradan satış hiçbir şey yapmaz; yoksa defter alışveriş fişine dönerdi.
  - Yeni: `People.remember_trade(location_id, kindly)`, `Scarcity.HUNGRY_CITY_FROM`.

- [x] **P17 Sessiz güne izin**
  - `RoadDirector`'un sessizlik rampası her sessiz günden sonra ihtimali büyütüyordu: üçüncü gün neredeyse kesin
    bir şey oluyordu, yani oyun hiçbir zaman susamıyordu. **Her dakika bir şey sunan oyun kasvetli değil
    meşguldür.**
  - Kıtlıkta rampa ve tavan kısılıyor (`SCARCITY_QUIET_RAMP` 0.16, `SCARCITY_MAX_QUIET_BOOST` 1.3), kıtlık
    derecesiyle kademeli olarak. Sıfırlanmıyor: yol büsbütün susmuyor, yalnız üç gün üst üste susabiliyor.
  - `chance_multiplier(context)` artık bağlamı okuyor; bağlamsız çağrı eski davranışı koruyor.
  - **Kabul:** `tests/test_trade_focus.gd` (8 test; P7, P14 ve P17 birlikte).

- [x] **P06 Takas**
  - Yeni ekran yok: `MarketScale`'in sağ kefesi takasta sikke yerine **senin verdiğin malı** taşıyor
    (`set_barter`). Fiyat değil **denklik** okunuyor; görsel dil buna zaten hazırdı.
  - `MODE_BARTER` alışın bir ödeme biçimi: sepet yerinde kalırken "Takas" / "Altınla Öde" arasında gidip
    geliniyor. Kargodan bir mala tıklamak onu sağ kefeye koyar, tekrar tıklamak bir tane daha ekler.
  - **Kuralın özü** `MarketPricing.barter_value`: verdiğin mal nakit sattığından çok eder
    (`BARTER_BONUS_BASE` %10), ve fark kıtlıkla büyür (`BARTER_BONUS_PER_SCARCITY` %45). Yani aç bir bölgede
    buğdayı sikkeye çevirip sikkeyle mal almak açık ara kötü bir hamle.
  - **Hiçbir sistem kesilmedi** (derinleşme, asla sadeleştirme): kese duruyor, vergi, geçiş ücreti ve hekim
    hâlâ altın istiyor. Söylenen şey "altını sil" değil, **"altın kötü bir takas aracı"**.
  - Takas da bir satıştır: `record_sale` çağrılıyor (şehrin hâli, defter, baskı), ama hazineden altın
    çekmiyor - altın el değiştirmiyor.
  - Ekranda kıtlıkta ayrı bir cümle: *"Burada sikke az şey ediyor: mal mala değişince malın daha çok
    sayılıyor."* Oyuncu farkı sayıdan değil cümleden anlamalı.
  - **Kabul:** `tests/test_trade_focus.gd`'ye üç test, `tests/screenshot_barter.gd` iki kare
    (altınla / takas).

- [x] **P16 Açlık ve yorgunluk bedende görünüyor**
  - Islaklık ve kar için yaptığımızın (Y-G25) karşılığı. `WalkFigure.set_wear(hunger, fatigue)` dört yerden
    konuşuyor: **çöken omuz** (`wear_hunch`), **kısalan adım** (`wear_step`), **incelen siluet** (`wear_bulk`),
    **soluklaşan ten** (`ArtDraw.worn_tint`) ve **çöken boy** (`wear_stoop`).
  - Yorgunluk adımı açlıktan çok kısaltır (aç insan yürür, yorgun insan sürüklenir); açlık incelttiği hâlde
    yorgunluk inceltmez (uyku kiloyu almaz).
  - Islaklık ve aşınma aynı `self_modulate` çarpanından geçiyor; ikisi de doğrudan yazmıyor
    (`_apply_body_tint`), yoksa yağmurda aç bir kervan tok görünürdü.
  - Sayılar var olan durumlardan okunuyor (`GameSession.body_hunger` = `consecutive_hungry_days` /
    `crew_hungry_nights`, `body_fatigue` = en yorgun kişinin yorgunluğu): çizim mekaniğin üstüne bir katman,
    yanına ikinci bir hakikat değil.
  - **Ekran görüntüsü yine düzeltti:** ilk değerlerle (0.085 rad eğim, soluk renk) dört hâl yan yana
    konduğunda fark görünmüyordu. Eğim 0.17'ye, renk payları %30'a çıktı ve `wear_stoop` eklendi - çünkü
    render edilmiş figürde kareler sabit olduğu için adım kısalması oraya hiç inmiyor, duruşun tek başına
    konuşması gerekiyordu.
  - **Kabul:** `tests/test_trade_focus.gd`'ye üç test, `tests/screenshot_wear.gd` dört hâl yan yana
    (tok · aç · yorgun · ikisi birden).

- [x] **P08 Kâr tavanı: ölçüldü, asıl bulgu ölçüm aracıydı**
  - **İlk rapor:** kese kırk seferde 6948 GG'lik bir tepe yapıyor, son yirmi seferin ortalaması ilk yirminin
    2.09 katı. Yani ortada bir para musluğu var gibi görünüyordu.
  - **Asıl bulgu:** musluk oyunda değil, ölçüm aracındaydı. `simulate_career` satışı doğrudan
    `MarketPricing.get_sell_price` + `wallet.earn` ile yapıyordu; yani **geri satış tavanını**
    (`capped_sell_price`), tazeliği ve **şehir hazinesini** hiç uğramıyordu. Alış da piyasa durumunu, günü ve
    kıtlık çarpanını atlıyordu. *"Bir rapor şaşırtıcıysa önce ölçüm aracından şüphelen"* kuralının tam örneği.
  - **Araç ekranın kapılarından geçirildi, tablo tersine döndü:**

    | politika | kese ilk yarı | son yarı | oran | tepe |
    |---|---|---|---|---|
    | genişleyen | 154 | 127 | 0.82 | 1617 |
    | kontratçı | 157 | 92 | 0.59 | 1617 |
    | aşamalı | 150 | 95 | 0.64 | 1617 |

    Hedef "yatay, yükselen değil"di; eğri **düşüyor**. Ölüm oranı değişmedi (0.025-0.031) ve sekiz kervanın
    hepsi kırk seferi tamamladı: kıtlık kıvrandırıyor, öldürmüyor.
  - **Sayı ayarı gerekmedi.** P1'in pazarlık tavanı (%45 → %15), P5'in erzak stoğu ve var olan iki kapı
    (şehir hazinesi, `BUYBACK_SHARE`) zaten yetiyor.
  - Tek yeni kural, tema gereği eklendi: `CITY_GOLD_SCARCITY_DRAIN` - aç bir bölgenin şehri yalnız mal değil
    **para** da bulamaz. Takasla (P6) aynı cümleyi söylüyor. **Dürüst not:** bu sabitin ölçülen etkisi
    gürültünün içinde kaldı (0.65 → 0.82, sekiz kervanda); gerekçesi ölçüm değil, dünyanın tutarlılığı.
    Hazine artık günü de biliyor - yoksa geç oyunda uğranmamış her şehir hâlâ ilk günün parasıyla görünüyordu.
  - **Kabul:** `tests/test_trade_focus.gd`'ye üç regresyon testi (hazine kıtlıkla kurur, satış hazineyi
    aşamaz, aynı şehirde al-sat döngüsü para basamaz) ve `simulate_career`'a kalıcı "kâr tavanı" satırı.

- [x] **P10 Faiz ve yapılandırma kalktı**
  - Silinen: `OVERDUE_INTEREST_RATE`, `apply_overdue_interest`, `overdue_periods_applied`, bileşik birikim,
    `restructure` ve bütün `RESTRUCTURE_*` sabitleri.
  - Kalan: anapara, vade, alacaklı, gecikti mi. **Borç büyümez; ya ödersin ya ödemezsin.** Gecikmenin bedeli
    aritmetik değil sosyal: dönem başına itibar (`OVERDUE_REPUTATION_PENALTY` 3) ve P11'in kapıları.
  - Gerekçe oyunun kendi ölçümüydü: sert oranla borç kırkıncı seferde milyonlara çıkıp kariyeri kilitliyor,
    yumuşatılınca hiçbir şey yapmıyordu (`denge_baba_borcu.md`). Taşıyamadığı ağırlığın altında ezilen bir
    mekanik.
  - Aile borcunun "yumuşaklığı" artık faiz oranı değil itibar bedeli (`FATHER_DEBT_REPUTATION_PENALTY` 1):
    alacaklı akraba, adını sokakta çürütmez.

- [x] **P11 Borcun bir adı ve bir teslimatı var**
  - `Debt` yeni alanlar taşıyor: `creditor_person_id`, `creditor_city_id` (bir yüz, `People`'ın tanıdığı kişi)
    ve `delivery_item_id/quantity/city_id` (karşılığı para değil yük).
  - **Vade geçerse sosyal bedel:** `GameSession.debt_shut_out_reason` - yüzü olan gecikmiş borcun şehrinde
    pazar sana kapanır. Yalnız o şehir, yalnız o borç: kurumsal borç (lonca, açık hesap) kimseye kapı kapatmaz,
    çünkü ortada kırılan bir **söz** yok. Vadesi gelmemiş borç da kapatmaz: borçlu olmak değil, sözü bozmak.
  - Teslimatlı borç parası ödense de kapanmıyor (`is_settled` yükü de sayıyor).

- [x] **P12 Borç paneli küçüldü, defter satırı geldi**
  - `debt_panel.gd` 327 → 145 satır: kredi hattı göstergesi, tutar kaydıracı, iki göstergeli önizleme, borç alma
    ve yapılandırma düğmeleri gitti. Kalan: satırlar ve tek bir **Öde** düğmesi.
  - **Yoldaki "Borç" emri kaldırıldı** (tempo -3.0, `_open_debt_panel`, `_debt_holder`, `_debt_button`): yolda
    borçla uğraşmak muhasebe kipinin ta kendisiydi.
  - Borç artık **Waybook'un özet sayfasında** da bir satır: kime · ne kadar · ne zamana kadar; vadesi geçen
    satır kızıla düşüyor. Dördüncü sütun: *Defter unutmaz.*
  - **Ekran görüntüsü iki hata yakaladı:** özet satırı ikinci argüman olarak kese bakiyesini basıyordu
    ("En yakın vade: 850 gün" - iki sayı da geçerli birer tamsayı olduğu için hiçbir test göremezdi); ve
    gecikme "-12 gün" diye okunuyordu, artık kendi cümlesini kuruyor.

- [x] **P13 Nakit kredi kalktı, mal avansı geldi**
  - `borrow_from_guild`, `can_borrow`, `get_loan_block_reason`, `get_available_credit_after_loan` silindi.
    Yerine `take_goods_advance` / `can_take_advance` / `get_advance_value` / `get_advance_block_reason`.
  - Nakit kredi **tam olarak bir kaçış kapağıydı**: para sıkışınca para alabilen oyuncu kıvranmaz ve P5'in
    erzak stoğuyla P9'un sözü anlamını kaybederdi. Lonca artık **yük** veriyor: şehrin ürettiği maldan
    istediğini alırsın, keseye tek kuruş girmez, borç deftere yazılır ve o malı taşımak zorundasın - yani
    avansın bir **ağırlığı** var.
  - Avans borcu `_bind_debt_to_lender` ile o şehrin tefecisine bağlanıyor: alacaklının adı var, etiketi değil.
  - **Açık hesap kaldı** (kullanıcı kararı): kese eksiye düşünce doğan borç bir kredi değil, sıfırın altına
    inememenin adı.
  - **Kabul:** `tests/test_debt.gd` yeniden yazıldı (borç büyümez, yüz ve teslimat), `test_city_commerce.gd`'nin
    dört kredi testi avansa çevrildi, `test_trade_focus.gd`'ye iki test, `tests/screenshot_debt.gd` iki kare
    (Lonca defteri + Waybook borç satırları).

- [x] **P15 Haber eskir ve yanlış olabilir — büyük kısmı zaten vardı, bir kısmı kullanıcı kararıyla çelişiyordu**
  - **Zaten vardı ve test altına alındı:** `price_book` tarihli (`get_price_age`, `PRICE_STALE_DAYS` 20),
    söylenti taze gelmez (`PRICE_RUMOR_MIN_AGE` 2 - `MAX_AGE` 6) ve dörtte bir yanlıştır
    (`PRICE_RUMOR_FALSE_CHANCE` 0.25); aynı şehri sorup sorup doğruya varmak kapalı; gördüğün fiyat
    söylenti değil görgüdür.
  - **Eklenen:** açık yol kenarı kervansarayında (Y-B14) biri bir pazardan söz ediyor
    (`_hear_serai_news`) - hedef şehir öncelikli, yoksa defterdeki en eski satır tazeleniyor.
  - **Yapılmayan ve nedeni:** önerinin *"tavernada ve kervansarayda haber **satın alınabilsin**"* kısmı
    kullanıcının N34 kararıyla doğrudan çelişiyor: *"tavernadan doğrudan dedikodu satın alınmasın."*
    Haber satılmıyor, **anlatılıyor** - kervansaray da aynı kurala tabi tutuldu. Kullanıcı N34'ü geri
    almak isterse satın alma tek bir düğmeyle açılır.
