# Akademik Kaynak Analizi - Wayborne'a Uygulanabilir Öneriler

Kaynak: "Wayborne — Akademik Kaynak Analizi ve Sistem Tasarımı Raporu" (16 sayfa,
11 akademik kaynak: Abatangelo, Savaş, de Smale/Kors/Sandovar, Geslin/Jégou/Beaudoin,
Bialas/Tekofsky/Spronck, Joosten/van Lankveld/Spronck, Kobyłczyk, Hložánek, Bogost,
Homs Puchal, Brückner).

**Bu bir uygulama kaydı değil, bir öneri belgesi.** Hiçbir madde koda geçmedi;
CLAUDE.md'nin kendi disiplini (bir sistem ölçülmeden/karara bağlanmadan değiştirilmez)
burada da geçerli - aşağıdakiler değerlendirilip onaylanınca CLAUDE.md'ye ve koda
girer, o zamana kadar burada bir teklif olarak duruyor.

## Önce söylenmesi gereken: rapor başka bir "Wayborne" için yazılmış

Rapor "Sideria" evreninde geçen, `Writbound`/`Renewed` adlı iki din, `Baikhan` adlı
göçebe kültür, `Vessarn`/`Coldmere` bölgeleri, bir "sanity" stat'ı, `world_lore.md`/
`game_design.md` adlı kaynak dosyaları olan **farklı bir projeden** bahsediyor. Bunların
hiçbiri bizim depomuzda yok - bizim oyunumuzda din yok, beş kültür var (Göçebe/Vadi
Loncaları/Dağ Kabilesi/Liman Şehri/Balıkçı Kasabası), "sanity" değil stres+moral ayrımı
var, `world_lore.md` diye bir dosya hiç yok. Muhtemelen aynı raporu paralel bir
projede de kullanıyorsun ya da rapor genel bir şablon üstünden yazıldı.

Aşağıda raporun **somut lore referanslarını değil, altında yatan genellenebilir
bulguyu ve mekanik kalıbı** aldım, bizim gerçek sistemlerimize (dosya adı, fonksiyon
adı, mevcut kural referanslı) çevirdim. Bir öneri "Baikhan'da X olsun" diyorsa, ben
onu "Göçebe kültüründe X olsun" ya da genel bir mekanik olarak yeniden kurdum -
hiçbir yerde Sideria'nın kendi ismini/lore'unu almadım.

## Önemli bir çelişki - ve nasıl çözüldü

Raporun 2.3 ve 5.4 bölümleri "ahlaki sonucu asla anında sayı olarak gösterme,
belirsiz bırak" diyor (TWoM'un hiçbir gösterge taşımaması). Bizim kendi CLAUDE.md'miz
ise Road Encounter Rules'ta tam tersini söylüyor: **"a fight the player couldn't see
coming is a legibility bug"** - savaşa açılan bir seçenek kan şeridiyle işaretleniyor,
zar atan seçenek statın amblemini taşıyor, kilitli bir seçenek sebebiyle gösteriliyor.

Bunlar aslında çelişmiyor, çünkü **iki farklı an**dan bahsediyorlar:

- **Karardan önce ne riske girdiğini bilmek** (bizim "legibility" kuralımız) -
  buna dokunmuyorum, bu oyunun kendi kimliği ve doğru.
- **Karardan sonra bunun ahlaki ağırlığının ne olduğunu öğrenmek** (raporun
  "asla anında +10/-10 gösterme" kuralı) - burada zaten bizim de örneklerimiz var:
  `NpcDisposition` mizacı oyuncuya hiç söylenmiyor, `evt_wanderer_revenge` günler
  sonra geliyor, `EventChoice.hint_text_key` bir *ipucu*, sonucun garantisi değil.

Yani rapor bize yeni bir kural getirmiyor, zaten yaptığımız bir ayrımı isimlendiriyor.
Aşağıdaki önerilerde bunu koruyorum: risk önizlemesi her zaman açık, sonucun ahlaki
ağırlığı zaman zaman gecikmeli/dolaylı kalabilir.

---

## A - Düşük maliyet, yüksek etki (önce bunlar)

### A1. Borç ve haraç kararları iki gösterge açsın (Frostpunk'ın "iki ekranlı" kuralı)

Rapor 2.1: bir kural onaylandığında hem bireysel hem toplu bir etki aynı anda
görünsün, metinle değil sayının kendisiyle.

Bizde tam karşılığı var: `DebtLedger`, borç kabul etme, `WorldEvents` lonca
görevleri. Şu an bir borç alındığında yalnızca tek bir sonuç gösteriliyor (kese
değişimi). Öneri: `DebtPanel`'de bir borç alınırken/geri ödenirken **iki satır**
gösterilsin - solda o anki nakit etkisi (kese), sağda **itibar/güven** üstündeki
kalıcı etkisi (`get_credit_limit()`'in bir sonraki borç için ne kadar daraldığı).
İkisi zaten hesaplanıyor (`get_loan_fee_percent()` itibara bağlı) - eksik olan tek
şey bunu aynı anda, iki ayrı sayıyla göstermek. **Maliyet: düşük** (UI satırı,
mevcut fonksiyonları okuyor).

### A2. HP/stres sayı değil sıfat olarak da gösterilsin

Rapor 2.2: TWoM sağlığı "45/100" değil "Sick"/"Wounded" gösterir - ham sayı hiç
ekrana çıkmaz.

Biz sayıyı **saklamayacağız** (Waybook UI Rules zaten "wear shows... never as a
number" derken açlık/stres kenar lekesi için bu ilkeyi kısmen uyguluyor, ama can
puanı hâlâ çıplak "HP 50/50"). Öneri: can barının **yanına**, sayıyı silmeden, bir
sıfat etiketi eklensin - "Dinç" (>%75) → "Yaralı" (%50-75) → "Ağır Yaralı" (%25-50)
→ "Ölümün Eşiğinde" (Death's Door'un kendisi zaten bu adı taşıyor, K2 "cracked door"
ikonuyla). Sayıyı **kaldırmak** değil, **yanına eklemek** öneriyorum - bizim
oyunumuzda sayı şeffaflığı (haggling'in "gizli formülü ezberletme" karşıtı disiplini
gibi) bilinçli bir tercih, TWoM'un tam tersi felsefesi burada tam kopyalanmamalı.
**Maliyet: düşük** (bir eşikleme fonksiyonu + bir Label).

### A3. Haraç/gümrük kaçırma riski kümülatif artsın (Animal Crossing'in borç döngüsü)

Rapor 4.4: gümrük kaçırmanın yakalanma riski her kullanımda sessizce artıyor (%5 →
%35), hiçbir uyarı metni yok - oyuncu bunu **hissederek** öğreniyor.

Bunun tam karşılığı zaten var: `WorldEvents.Kind.BANDIT_TRIBUTE` (haraç bölgesi) ve
`_fulfilled_commission_starts`'ın "aynı örnek bir kez" deseni. Öneri: yeni bir yol
olayı - haraç bölgesinde geçen bir kontrol noktasında "gümrük kaçır" seçeneği -
`GameSession`'da rota başına bir sayaç tutsun (`smuggle_attempts_by_route`, mevcut
`_fulfilled_commission_starts`'ın Dictionary deseni), her denemede yakalanma zarının
eşiği yükselsin. Yakalanırsa itibar cezası + `DEBT_SETTLE`'ın tersi bir zorla haraç
(`spend_or_owe`). Hiçbir yeni `EventEffect.Type` gerekmiyor - `EventCondition`'ın
context'ten okuduğu bir sayaç ve mevcut `GOLD`/`REPUTATION` etkileri yeterli.
**Maliyet: düşük-orta** (bir yeni event + bir sayaç alanı, `test_memory.gd`'nin
"her alan kayıtlı ya da geçici" kontrolüne girer).

### A4. Kervan büyüdükçe haritadaki "güvenli alan" görsel olarak küçülsün

Rapor 2.5 (Little Nightmares'ın büyüme metaforunu tersine çevirmesi): kervan
büyüdükçe ekrandaki oranı büyüsün ama etrafındaki boşluk küçülsün - "güçlendim"
değil "sıkıştım" hissi.

Biz bunu **mekanik olarak zaten yapıyoruz** - `POWER_SCALE_PER_PARTY_MEMBER`
(Ruin Rules) kervan büyüdükçe düşmanı da güçlendiriyor, ölçülmüş ve kayıtlı. Eksik
olan yalnızca bunun **görsel yankısı**. Öneri: `world_map.gd`'de kervan ikonunun
etrafındaki "bilinen tehlike" halkasının yarıçapı `owned_wagon_count`'a ters
orantılı küçülsün - saf görsel, hiçbir yeni sayı icat etmiyor, zaten doğru olan bir
mekanik gerçeği görünür kılıyor (tam olarak "Nothing painted ships unread"
disiplininin tersi: burada zaten var olan ama hiç çizilmemiş bir gerçek var).
**Maliyet: çok düşük.**

### A5. Aynı dünya olayı, kültüre göre farklı çerçevelensin (Lakoff'un çerçeveleme tezi)

Rapor 2.6: Balance of Power hiçbir tarafı "doğru" göstermeden bir dünya görüşünü
kurala gömüyor; aynı olay iki farklı NPC'nin ağzından iki farklı çerçeveyle
anlatılabilir.

Bizim `WorldEvents` haberleri (`evt_regional_war_news` vb.) ve kültür bağlamı
(`is_*_culture` bayrakları, `build_event_context()`) zaten var. Öneri: aynı haber
kartının gövde metni, kervanın lideri hangi kültürdense ona göre **farklı bir
çeviri anahtarına** düşsün (`UI_EVT_REGIONAL_WAR_NEWS_NOMAD` vs `_SETTLED` gibi) -
olayın etkisi (rota tehlikesi, fiyat) **hiç değişmiyor**, yalnızca anlatım perspektifi
değişiyor. Saf içerik/lokalizasyon işi, sıfır yeni mekanik, sıfır dengesizlik riski.
**Maliyet: düşük** (CSV'ye birkaç varyant + `_t()`'nin okuduğu anahtarı kültüre göre
seçen bir satır).

---

## B - Zaten yaptığımızı doğrulayan bulgular (iş değil, teyit)

Rapor birkaç yerde bizim **zaten** kararlaştırdığımız bir tasarımı bağımsız olarak
doğruluyor - bunları değiştirmeye gerek yok, tam tersine "neden böyle" sorusuna
akademik bir referans kazandırıyor:

- **"Kültür taktikte değil davranışta konuşmalı"** (Bialas + Brückner, Bölüm 5.2/5.6) -
  CLAUDE.md'nin kendi kuralı zaten bu: "her kültür perk'i mevcut bir sisteme
  eklemlenir, yeni bir sistem icat etmez" ve kültür etkisi hep küçük bir çarpan
  (`buy_price_multiplier`, `combat_damage_multiplier` - asla bir savaş kilidi ya da
  taktik farkı). Rapor bunu iki ayrı ampirik çalışmayla doğruluyor; bizim tarafımızda
  yapılacak bir şey yok, yalnızca bu disiplinin **neden** doğru olduğuna dair bir
  gerekçe kazandık.
- **Belirsizlik bırakma (Apophenia)** - `NpcDisposition` oyuncuya hiç söylenmiyor,
  yalnızca yüksek Sezgi bir ipucu veriyor; `evt_wanderer_revenge` günler sonra geliyor.
  Rapor 2.7-IV'ün istediği tam olarak bu.
- **Nedensellik zinciri (Causality)** - `CharacterData.grievances`, ledger'ın
  `GRIEVANCE_WITNESSED_DEATH`/`PASSED_OVER` gibi kalıcı izleri, `evt_pilgrim_blessing`
  zinciri - bir kararın başka bir karakterin geleceğini etkilemesi zaten var.
- **Ufku hiç ulaşılamaz tutmak (sublime)** - `TravelBand`'in `PARALLAX_FAR = 0.10`'u
  zaten en uzak katmanı neredeyse sabit tutuyor; rapor bunun "büyük bir gücün asla
  tam sahiplenilemediği" hissini ürettiğini söylüyor - biz bunu ölçmeden, sezgiyle
  zaten doğru yapmışız.
- **Üç katmanlı yol sahnesi**nin ilk iki katmanı (atmosferik + ortam-dolgu) zaten var:
  `RouteWeather` (bölgeye göre değişen hava), `TravelForeground`'un `hash(cell)`
  tabanlı, tıklanamayan sahne dolgusu. Eksik olan yalnızca üçüncü katman - bkz. C1.

---

## C - Orta maliyet, gerçek yeni içerik

### C1. Yolda tıklanabilir, opsiyonel "iz" objeleri (üçüncü katman)

Rapor 3.4: seeker/wanderer ikiliğini aynı sahnede besleyen üçüncü katman -
3-4 yolculukta bir, tıklanabilir ama asla zorunlu olmayan bir iz (terk edilmiş
kamp ateşi, kırık tekerlek). Tıklamak küçük bir metin/ipucu verir, bazen bir
sonraki şehirdeki olayı önceden haber verir, bazen hiçbir şeye bağlanmaz.

Bu, bizim `RoadSignals`in (üç tür: wheel/straggler/smoke, `RoadAttention`
bölgesine bağlı, sessizce büyüyen) **doğal bir dördüncü kardeşi**. Ama
`RoadSignals` zaten "görmezden gelinirse büyüyen bir tehdit" - burada istenen
farklı: **ödülsüz, tehditsiz, saf atmosferik bir keşif**. Öneri: `TravelBand`'e
düşük sıklıkta (gün başına küçük bir olasılık, `RouteTerrain`'in stop/biome
bilgisine bağlı olmayan, bağımsız bir tohumdan) bir `RoadTrace` prop'u eklensin -
tıklanınca `CityBriefPanel`'in "anı" satırlarına benzer kısa bir flavor metni açar,
hiçbir `EventEffect` tetiklemez. **Kasıtlı olarak bazen** (küçük bir olasılıkla) o
günün olay havuzuna hafif bir `EventWeightModifier` ekler (Apophenia'nın "bazen
hiçbir şeye bağlanmaz" ilkesi - her iz bir ipucu olursa ipucu olmaktan çıkar).
**Maliyet: orta** (yeni bir prop havuzu + flavor metin CSV'si + opsiyonel weight
modifier kancası); **risk: düşük** (mekanik olarak hiçbir şeyi bozamaz, saf katma).

### C2. Otacı triyaj ikilemi - Frostpunk'ın "Care House" karşılığı

Rapor 4.1: iki+ karakter aynı anda hasta, şifacının kapasitesi bir kişi/gün.
"Herkese biraz bakım" (hepsi hayatta ama yavaş, moral düşük) vs "en umutluya
odaklan" (biri hızlı iyileşir, diğeri risk altında).

Bizim `DutyCatalog.OTACI`su ve `PARTY_HP`/`STRESS` efektleri zaten bu ikilemi
kurmaya yeter, hiçbir yeni `EventEffect.Type` gerekmiyor. Öneri: yeni bir yol
olayı - iki parti üyesi aynı anda yaralı/hasta bayrağı taşıyorsa tetiklenir
(`build_event_context()`'e küçük bir sayaç eklenir). "Herkese biraz" seçeneği
küçük bir `PARTY_HP` iyileştirmesi + hafif `STRESS` düşüşü (herkes), "birine
odaklan" seçeneği (Otacı'nın kendisi seçer, oyuncu değil - `get_best_effective_stat`
zaten "en iyi" karakteri bulabiliyor) hedeflenen kişiye büyük iyileşme, diğerine
`GRIEVANCE_BENCHED`. **Homs Puchal'ın Dramatism ilkesi** (doğru cevap yok) burada
doğal olarak sağlanıyor çünkü ikisi de gerçek bir bedel taşıyor. **Maliyet: düşük**
(tek bir yeni event, mevcut vokabülerle).

### C3. Kader Modu - kampanya başında zorluk "kişiliği" seçimi

Rapor 2.7-V (RimWorld'ün Cassandra/Phoebe/Randy Storyteller'ları): tutarlı artan
zorluk / uzun sakin + ani sert / tamamen kaotik - üç farklı ritim.

Bizde `DANGER_GROWTH_PER_DAY`, `RoadSignals`in eskalasyon hızı ve
`EventWeightModifier`'lar zaten birer sayı. Öneri: karakter oluşturmada isteğe
bağlı bir "yolun mizacı" seçimi - üç sabit çarpan seti (bugünkü ayarlar = "Tutarlı",
+%50 sakin aralık/-%50 ani sıçrama = "Dingin-Sert", rastgele dağılım = "Kaotik").
**Bu, `simulate_journeys.gd`'nin ölçüm disiplinine göre yapılmalı** - CLAUDE.md'nin
kendi kuralı gereği (bir denge değişikliği ölçülmeden gönderilmez), üç modun da
mevcut win-rate/starvation tablolarını yeniden üretmesi gerekir. **Maliyet: orta**
(üç sabit set + seçim UI'ı + üç modun tam yeniden ölçümü - Ruin Rules'un tablosu
kadar bir iş).

---

## D - Yüksek maliyet, mimari, tartışmalı (dikkatli değerlendir)

### D1. Yedinci bir görev: "Emniyet/Nöbetçi" - kervan içi disiplin ağacı

Rapor 2.8/4.6 (Frostpunk'ın Order kategorisi): dışarıdaki tehditle içerideki
güvensizlik arasında bir gerilim - gece nöbeti, sıkı disiplin, muhbir ağı, zorla
ikna. Her biri kısa vadede güvenlik kazandırır, uzun vadede güven/moral yakar.

Bu, mevcut altı görevin (`MUHAFIZ/İZCİ/LEVAZIMCI/ARABACI/TELLAL/OTACI`) yanına
**gerçekten yeni bir yedinci sistem** ister - CLAUDE.md'nin kültür perk'leri için
koyduğu "yeni sistem icat etme" kısıtı görevler için o kadar katı değil (Duty
sistemi zaten genişlemeye açık tasarlandı, İzci Faz 7'de son eklenendi), ama yine
de: `get_duty_power()`/`get_duty_multiplier()` ailesine yeni bir üye, en az bir
yeni `EventEffect` ya da context bayrağı, ve **muhbir ağının** "bir NPC'nin başka
birini ihbar ettiğini öğrenmesi kalıcı bir ilişki hasarı" kısmı `grievances`
sistemine yeni bir tür (`GRIEVANCE_INFORMED_ON`?) ister.

**Değerlendirme:** rapor bunu kendisi de "kervan 12 vagon/80 kişiye yaklaştıkça
anlamlı" bir MVP-sonrası genişleme olarak sınıflandırıyor (Bölüm 6, madde 4) -
biz de aynı yere koyuyorum. Küçük bir kervanda gereksiz bir sistem, büyük bir
kervanda gerçekten ilginç olabilir. **Önerim: şimdi değil, kervan
büyüklüğü/kampanya derinliği gerçekten oraya evrildiğinde tekrar gündeme
getirilsin - Ana Hedefler listesine "değerlendirilecek, karara bağlanmadı" olarak
eklenebilir, hemen inşa edilmesin.**

### D2. Renk-duygu formülüne göre bölge paleti tazelemesi

Rapor 3.3: doygunluk/parlaklık valence'ı, renk çeşitliliği arousal'ı belirliyor;
somut bir bölge×duygu tablosu öneriyor.

Bizim `ArtPalette`'imiz zaten beş biyom + dört gün evresi + danger-tabanlı
efektler taşıyor (Art Rules, "one palette, one set of brushes"). Raporun formülü
bunu **tazelemek** için bir ölçüt sunuyor ama mevcut paletin kendisi zaten
playtest'ten geçmiş, kasıtlı seçimler (bkz. Art Rules'un onlarca "ölçüldü, düzeltildi"
notu). **Değerlendirme: düşük öncelik** - mevcut palet bozuk değil, bu yalnızca
onu revize etmek isterseniz kullanılacak bir çerçeve. Zorla uygulanacak bir şey
değil.

### D3. Deneyime bağlı renk yoğunluğu (ilk 2 saat abartı, sonra sade)

Rapor 3.3'ün ikincil bulgusu: renk etkisi neredeyse yalnızca deneyimsiz
oyuncularda görülüyor.

**Önerilmiyor.** Bizim kendi tasarım tarihimiz (Motion Rules, Art Rules) hep
netlik ve tutarlılık yönünde - "aynı şey iki yerde farklı görünürse iki farklı
şey olur" ilkesi burada ters yönde çalışır: deneyimli/deneyimsiz oyuncuya farklı
bir görsel dil göstermek, `OnboardingPanel`'in zaten yaptığı "bir kez göster, bir
daha sorma" ilkesinin ötesine geçip kalıcı bir ikilik yaratır - test edilmesi
zor, playtest bulgusu da (~%5 etki boyutu) bunu haklı çıkarmaya yetmiyor. Rapor
metninde geçtiği için buraya not düştüm, ama önermiyorum.

---

## Öncelik sıralaması (rapordaki Bölüm 6'nın bizim mimarimize göre uyarlanmış hali)

1. **A5** (kültüre göre haber çerçeveleme) ve **A4** (küçülen güvenli alan) -
   sıfıra yakın mühendislik, mevcut bir gerçeği görünür kılıyor.
2. **A1** (iki gösterge) ve **A2** (sıfat etiketi) - küçük UI işi, okunabilirliği
   doğrudan artırıyor.
3. **A3** (kümülatif kaçakçılık riski) ve **C2** (Otacı triyajı) - birer yeni
   event, mevcut vokabülerle, içerik ekibinin (senin) elle yazacağı asıl iş
   yalnızca prompt/metin, mekanik hazır.
4. **C1** (üçüncü katman iz objeleri) - orta iş, RoadSignals'ın yanına yeni bir
   sistem ama küçük ve izole.
5. **C3** (Kader Modu) - gerçek değer taşıyor ama `simulate_journeys.gd` ile tam
   yeniden ölçüm istiyor, acele etmeye değmez.
6. **D1** (Emniyet görevi/disiplin ağacı) - saklanacak bir fikir, şimdi değil.
7. **D2/D3** - referans olarak kalsın, aktif iş değil.

## Görsel/prompt işiyle kesişen tek nokta

C1'in "iz objeleri" ve A5'in kültüre-göre-çerçeveleme'si dışında bu raporun
hiçbir önerisi şu an üstünde çalıştığın Gemini teslimatını (kıyafet parça
sayfaları, p3_agility/p5_scout) etkilemiyor - oraya dokunmadan devam edebilirsin.
C1 ileride gündeme gelirse kendi küçük bir prop seti (birkaç "iz" objesi
illüstrasyonu) isteyecek, ama bu ayrı ve daha sonraki bir tur.
