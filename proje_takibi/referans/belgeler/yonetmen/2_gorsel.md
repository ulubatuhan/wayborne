# Wayborne — Görsel Kimlik Denetimi (Sanat Yönetmeni Raporu)

> Tarih: 2026-10-17 · Kapsam: salt okuma; hiçbir dosya değiştirilmedi.
> Hedef platform: PC (Godot 4.2). Web derlemesi yalnızca test amaçlı; bu rapordaki performans/boyut önerileri PC ölçütüne göredir.

---

## 0. Tek paragraflık hüküm

Wayborne'da bugün **tek bir görsel kimlik yok, en az beş ayrı "üretim dili" yan yana duruyor**:
(1) yapay zekâ destekli, taramalı mürekkep illüstrasyonu (masa sahneleri, olay kartları, defter),
(2) Blender + Freestyle ile mürekkeplenmiş CC0 alçak poligon kasabalar (CityFront, ana menü kampı),
(3) `_draw()` ile çizilmiş düz vektör dünya (yolun gökyüzü, halkalı güneş, lolipop ağaçlar, çimen tutamları),
(4) mürekkepsiz, pürüzsüz gölgelendirilmiş 3B manken karakterler (MakeHuman tabanlı, kel, açık ten),
(5) sepya gravür dünya haritası ve taramalı atlı işaret.
Bunlardan **(1) ve (5) oyunun en güçlü ve en özgün varlıkları**; ikisi de aynı "gravür / mürekkep-parşömen" ailesinden geliyor. **(3) en zayıf**, (4) ise teknik olarak en pahalı ve en çok emek verilen ama stil olarak en uyumsuz parça. Önerim: kimliği haritanın ve olay kartlarının gravür diline kilitlemek, diğer her şeyi o dile çekmek (özellikle karakterlere ve yola mürekkep + tarama + kâğıt dokusu NPR geçişi), prosedürel dünya çizimini emekliye ayırmak ve referans oyun düzenini birebir taşıyan şehir ekranını kendi kervan merkezli kimliğine kaydırmak.

---

## 1. İncelenen görseller

Küçültülmüş kopyalar `scratchpad/img/` altında üretildi; asıl dosyalar:

**Önceki oturumun gönderdiği ekranlar (gonderilen/)**
- `D:\Users\u90238\Desktop\xx\Wayborne_Codespace_Arsiv\gonderilen\ana_menu.png` (16 Eki)
- `...\gonderilen\yol_after.png` (16 Eki, en güncel yol ekranı)
- `...\gonderilen\oyunda_1_savas.png`, `oyunda_2_yolda.png` (3 Eki)
- `...\gonderilen\onay_oyun.png`, `walk_all_variants.png` (9 Eki — yürüyüş döngüleri, beden varyantları)
- `...\gonderilen\combat_fx.png`, `reactions.png` (14 Eki — durum efektleri, tepki pozları)
- `...\gonderilen\beasts.png` (28 Eyl), `game_hub.png` (4 Eki)
- `...\gonderilen\city_map_1920x1080.png`, `world_map_1920x1080__2.png`, `character_1920x1080.png`, `market_1920x1080__2.png`, `party_1920x1080.png`, `recruit_1920x1080__2.png`, `wardrobe_1920x1080.png` (25 Eyl–9 Eki; bir kısmı grim kit'e geçişle eskimiş olabilir, aşağıda belirtildi)
- `...\gonderilen\27_wayborne_harita_onizleme.jpg` (16 Eki)

**Kullanıcının yüklediği referans/şikâyet görselleri (yuklenen/)**
- `...\yuklenen\30070.jpg`, `30071.jpg` (16 Eki — son harita, telefonda)
- `...\yuklenen\30029.jpg`, `30030.jpg`, `29977.jpg`, `29848.jpg` (harita referansları, "dağlar dikit gibi durmasın", yurt şikâyeti, pikselli manken figür)
- `...\yuklenen\29591.jpg` (manken render karşılaştırması)
- `...\yuklenen\30028.jpg` (renkli bölge işaretli harita), `1792142820823.jpg` (illüstratif kale haritası), `30056.jpg`, `29857.jpg` (sepya fantastik harita), `1792043964954.jpg`, `1792043960928.jpg` (Oregon Trail 2021 yol ekranları)

**Depo**
- `D:\Users\u90238\Desktop\xx\wayborne\docs\ui\mockups\2_town_demirkapi_hover.jpg`, `1_town_kurtbogazi.jpg`, `3_title.jpg`, `4_trade.jpg`, `6_hud.jpg`, `8_yol_02_orman_sabah.jpg`, `8_yol_10_kamp.jpg`
- `D:\Users\u90238\Desktop\xx\wayborne\art_source\waybook\A0_style_anchor.jpg`
- `D:\Users\u90238\Desktop\xx\wayborne\data\assets\ui\waybook\e6b_wolves.jpg`, `b2_market.jpg`
- `D:\Users\u90238\Desktop\xx\wayborne\docs\ui\REDESIGN.md`, `CLAUDE.md` (Art Rules, Rendered Road Rules, Prop Rules, Waybook UI Rules, Motion Rules), `AI_DISCLOSURE.md`

**TODO**
- `D:\Users\u90238\Desktop\xx\TODO\harita_final\harita_onizleme_4096.jpg` (+ merkez kırpımı)
- `D:\Users\u90238\Desktop\xx\TODO\referanslar\atli_isaret\gorseller\atli_sayfa.png`, `atli_onizleme_haritada.jpg`
- `D:\Users\u90238\Desktop\xx\TODO\belgeler\ART_IKINCI_TUR_REFERANSLARI.md` (§2–§5)
- `D:\Users\u90238\Desktop\xx\TODO\YAPILACAKLAR.md`, `gorevler\10_yol_figurleri.md`, `gorevler\12_sehir_ve_yol_gorunumu.md`

---

## 2. Beş üretim dili — tutarlılık haritası

| # | Dil | Nerede | Çizgi | Gölge/ton | Doku | Kalite | Kimliğe katkı |
|---|---|---|---|---|---|---|---|
| 1 | Taramalı mürekkep illüstrasyonu (AI destekli, `art_source/waybook`) | Masa sahneleri (B1–B10), olay kartları (E6*), A0 stil çapası, ikonlar | Kalın-ince mürekkep, çapraz tarama | Sepya + tek sıcak ışık (mum) | Kâğıt lekesi, kahve halkası | Yüksek | **Çok güçlü** |
| 2 | Freestyle'lı Blender CC0 kasaba | CityFront (5 şehir), ana menü kampı | Tek kalınlık, düzgün, "teknik çizim" | Düz, toon | Hafif kir | Orta | Orta; oyuncak/maket hissi |
| 3 | Prosedürel `_draw()` vektör | Yol gökyüzü, güneş/ay, sırtlar, lolipop ağaç, ot tutamı, eski izometrik şehir | Yok veya kalın düz kontur | Düz dolgu, bantlaşan gradyan | Yok | Düşük | **Negatif** |
| 4 | 3B manken render (MakeHuman + giysi parçaları) | Yol figürleri, savaş, gardırop, karakter | Yok | Pürüzsüz, fotoğrafik-plastik | Yok | Teknik olarak iyi | Uyumsuz; "Oregon Trail" klonu hissi |
| 5 | Sepya gravür harita + taramalı atlı | Final dünya haritası, atlı işaret | İnce, gravür | Tarama, gri-yeşil deniz | Parşömen | Yüksek | **Çok güçlü** |

Ek olarak UI katmanı: kömür panel + ince altın kenar + kan kırmızısı ana eylem + Grenze Gotisch / IM Fell / EB Garamond. Bu katman kendi içinde tutarlı ama **referans oyun'ın UI'ının neredeyse birebir kopyası** (bkz. §6).

**Sonuç:** CLAUDE.md'nin kendi dersi — *"bir ekran tedavi görünce, görmeyen ekranlar artık yanlıştır"* — bugün oyunun tamamı için geçerli. Harita ve olay kartları çıtayı yükseltti; yol ve karakterler bu çıtanın altında kaldı.

---

## 3. Ekran ekran değerlendirme

### 3.1 Ana menü (`gonderilen\ana_menu.png`, `mockups\3_title.jpg`)
- **İyi:** Sağda koyu şerit (Wartales düzeni), tek ışık kaynağı kamp ateşi, soy satırı ("Demirtaş kervanı · 3. kuşak · 214. gün") — hikâyeyi tek satırda anlatıyor; Grenze Gotisch logo okunaklı ve karakterli.
- **Zayıf:** Ekranın %70'i boş siyah. Ateş alçak poligon koni yığını; sandık havada asılı gibi; uzak kale tek kalınlıkta Freestyle çizgisiyle **tel kafes** gibi duruyor. Ay düz disk. Kervan tek vagon, insan yok — "kervan" oyununun açılış sahnesinde kervan yok.
- **Karar:** Ana menü, oyunun hero sahnesi olmalı (bkz. §9, hero 2). Bugünkü haliyle bir Steam fragmanının ilk 3 saniyesini taşıyamaz.

### 3.2 Yol ekranı (`gonderilen\yol_after.png`, `mockups\8_yol_02_orman_sabah.jpg`, `8_yol_10_kamp.jpg`, `game_hub.png`)
- **Kompozisyon iyi:** Alçak kamera, yolun ortada yatay bant olması, önde koyu bulanık tarla (Oregon Trail 2021'den doğru alınmış ders; `yuklenen\1792043964954.jpg`, `1792043960928.jpg`). Kervan kolonunun uzunluğu kendi başına güçlü bir siluet fikri.
- **Ama uygulama kimliği bozuyor:**
  - Güneş/ay **eş merkezli halkalarla bantlaşan** bir hale (8 bitlik gradyan bantlaşması) — kullanıcının "hele ki güneş" şikâyeti haklı (12.2e).
  - Orta katmanda **lolipop/bulut ağaçlar** ve koni çamlar: render edilmiş katmanlarla prosedürel çizim karışıyor; iki prodüksiyon aynı karede.
  - Figürler **çıplak/kel manken** gibi okunuyor (ten rengi gövde, beyaz/bej tunik). Koyu, puslu bir dünyada en parlak şey insan derisi — göz yanlış yere gidiyor.
  - Kervanın altındaki kütük/çubuklar (12.2d) ve yarım kesik nesneler kompozisyonun en okunur bölgesini kirletiyor.
  - Öküzler siyah kütle olarak iyi siluet veriyor; ama koşum görünmüyor (10.4), arabacı eski siluet (10.3) — figür dili vagon üstünde bile ikiye bölünmüş.
  - Üst bar yoğun düz metin ("Gold: 250 GP · Provisions: 20 · ..."): HUD hiyerarşisi yok; altta 8 eşit düğme.
- **Grim HUD taslağı (`mockups\6_hud.jpg`)** üst bar ve alt şeridi toparlıyor (ikonlu düğme, kızıl "Geri Dön", parşömen haber kartları); bu yön doğru. Ancak altındaki dünya hâlâ prosedürel ve aynı halkalı ay.

### 3.3 Şehir (CityFront) (`mockups\2_town_demirkapi_hover.jpg`, `1_town_kurtbogazi.jpg`; eski: `gonderilen\city_map_1920x1080.png`)
- Eski izometrik şehir (pastel, oyuncak blok) + masa sahnesi kolajı tamamen kopuktu; CityFront büyük bir sıçrama.
- **İyi:** Her şehrin kendi ışık iklimi (Demirkapı kızıl is, Kurtboğazı soğuk mavi kar); hover'da bina vurgusu; levhalar ve kadro kartları okunaklı.
- **Zayıf:**
  - Quaternius/Kenney kitlerinin silueti tanınabilir; aynı kuyu/çeşme ve aynı yarı ahşap ev iki şehirde de önde. Yakın kamera (12.1) bunu büyütüyor.
  - Freestyle çizgisi tek kalınlıkta; olay kartlarının taramalı, elden çıkmış mürekkebiyle yan yana "CAD çıktısı" gibi.
  - Düzen referans oyun mezra'in birebir aynısı: sol üst kızıl sancak + arma, sağ üst kadro kartları, alt şerit, sağ altta kızıl "Embark/Yola Çık". Kullanıcı bunu istedi; ama kimlik açısından risk (bkz. §6).

### 3.4 Dünya haritası ve atlı işaret (`TODO\harita_final\harita_onizleme_4096.jpg`, `atli_sayfa.png`, `atli_onizleme_haritada.jpg`)
- Oyunun **en iyi görsel varlığı.** Carta Marina / Tolkien geleneğinde gravür dağlar, noktalı orman kütleleri, gri-yeşil deniz, küçük kale piktogramları; 4096 px'te bile tutarlı ve el yapımı hissi veriyor. Kullanıcının referansları (`yuklenen\29857.jpg`, `30056.jpg`, `30029.jpg`) doğru özümsenmiş.
- **Zayıf / düzeltilecek:**
  - Tam görünümde dağ ve orman dokusu çok yoğun ve **tekdüze gri**; uzaktan bir "kum kağıdı" yüzeyine dönüşüyor. Bölge kimliği (kuzey bozkırı, doğu ormanları, güney sıradağlar) renk/ton farkıyla hiç okunmuyor — kullanıcının renkli bölge işaretli referansı (`yuklenen\30028.jpg`) tam da bunu istiyor.
  - Deniz düz, bulanık gri; kıyı çizgisi (çift kontur, dalga çizgisi) yok — kıyı gravür haritalarda en çok emek verilen yerdir.
  - Atlı işaret: halftone tarama ve fener halesi çok iyi bir fikir; ama binicinin uzuvları silindir manken (aynı (4) sorunu), at gövdesi düşük poligon. Ölçekte (haritada ~40 px) okunuyor, fakat yakın planda "3B maket" görünüyor.
  - Önizlemedeki yer adı ("Vastrevar") **sans-serif, geniş aralıklı** bir yazıyla; oyunun üç yüzüyle (Grenze / IM Fell / EB Garamond) çelişiyor. Haritada IM Fell English SC kullanılmalı.
  - Eski oyun içi B6 parşömen haritası (`world_map_1920x1080__2.png`) AI-mürekkep ailesinden; yeni gravür haritası ondan daha ince çizgili. 8.1 ile değiştirilirken çerçeve (masa, kağıt kenarı) korunmalı ki "nesne olarak harita" fikri kaybolmasın.

### 3.5 Masa sahneli yönetim ekranları (karakter, parti, taverna, gardırop, pazar)
(`character_1920x1080.png`, `party_1920x1080.png`, `recruit_1920x1080__2.png`, `wardrobe_1920x1080.png`, `market_1920x1080__2.png`)
- **Arka planlar mükemmel** (çadır içi, fener, terazi, mum) — en tutarlı illüstrasyon ailesi.
- **Önündeki UI bir veri dökümü:** karakter ekranı tek sütun düz liste; parti ekranı paragraf paragraf metin; taverna adayları tek satırlık uzun metin; pazar 12 satır × 6 düğme ("Buy / Haggle / Sell / Add to Basket"). Kullanıcının ilk şikâyeti olan *"Excel'de oyun yapıyoruz"* bu ekranlarda hâlâ geçerli.
- Portre yok; karakterin yüzü yok. Gardıropta çıplak manken bir askıda — giydirme ekranının kahramanı en çirkin görünen öğe.
- Metin kontrastı düşük (gri-bej metin, koyu kahve üstünde; 1080p'de ~14–16 px).
- `mockups\4_trade.jpg` (Tezgâh / Terazi / Senin Yükün) doğru yön: terazi bir metafor ve görsel; üç blok, net hiyerarşi. Diğer masa ekranları bu kalıba çekilmeli.

### 3.6 Savaş (`oyunda_1_savas.png`, `combat_fx.png`, `reactions.png`)
- Yan yana dört-dört dizilim, mevki etiketleri, kırmızı can çubukları, altın seçim çerçevesi: işlevsel.
- **Ama sahne boş:** figürler ekran yüksekliğinin ~%15'i, arka plan siyah degrade + tek ince altın çizgi; mekân yok. referans oyunda savaşı satan şey büyük figürler ve mekân arka planıdır; burada ikisi de yok.
- Düşmanlar kırmızı göz bantlı aynı figürün kopyası; sınıf silueti yalnız silahla ayrılıyor.
- Durum efektleri (yanma, zehir, üşüme) **gövdenin üstünde** — doğru kural (Motion Rules). Fakat mermi/büyü efektleri (mor füze, mavi ışın, yeşil bulut) jenerik mobil-oyun parıltısı; gravür dünyasıyla çelişiyor.

### 3.7 Yaratıklar (`beasts.png`)
- Gri, düz renkli, düşük poligon "kâğıt kesme" hayvanlar; kurt/ayı/domuz siluetleri iyi ama renk ve gölge dili insanlarla ve haritayla ortak değil. Olay kartındaki kurtlar (`e6b_wolves.jpg`) ile yoldaki kurt aynı oyunun hayvanı gibi durmuyor.

---

## 4. Boyutlara göre değerlendirme

### 4.1 Okunabilirlik
- **Güçlü:** CityFront levhaları, yeni HUD şişeleri (sayı + ad), mevki etiketleri, haritada kan kırmızısı "buradasın".
- **Zayıf:** Masa ekranlarında küçük, düşük kontrastlı gövde metni; uzun tek satırlar; aynı ağırlıkta başlık ve gövde. Her ekranda 3 katmanlı tipografi hiyerarşisi (başlık şeridi / bölüm başlığı / gövde) tutarlı uygulanmalı.
- Harita: 4096 px'te yer adları ufak; oyunda zoom seviyelerine göre etiket yoğunluğu (LOD) gerekir.

### 4.2 Siluet
- Kervan kolonu (öküz–vagon–yürüyen) **oyunun imza silueti olabilir**; menüde ve yolda henüz yeterince büyük ve kontrastlı gösterilmiyor.
- İnsan figürleri kel ve saçsız → kafalar yumurta; başlık/saç yok. Siluet okuması için baş aksesuarı (kukuleta, kalpak, sarık, miğfer) en ucuz ve en etkili kazanç.
- Sınıflar silahla ayrılıyor; giysi dilinin de sınıf silueti taşıması gerek (muhafız: geniş omuz/kalkan; avcı: kukuleta/yay; katip: uzun cübbe).

### 4.3 Palet
- UI paleti tutarlı (kömür %60–80, kırmızı yalnız kayıp/tehlike, kehribar yalnız ışık) — iyi kural, korunmalı.
- Dünya paleti dağınık: yolda pastel mavi gök + gri-yeşil; şehirlerde doygun kızıl/mavi; harita sepya; karakterler açık bej-beyaz. **Ortak "kâğıt beyazı" ve "mürekkep siyahı" tanımlanmalı**; tüm sahneler bu ikisinin arasında, saat/biyom/hava ise bir renk derecelendirmesi (grade) olarak gelmeli.

### 4.4 Işık ve atmosfer
- Tek sıcak kaynak + vinyet kuralı (menü, masa sahneleri, kamp) doğru ve tutarlı.
- Gece kampı ateşinin çevresine düşen ışık iyi; ama güneş/ay haleleri bantlaşıyor (shader ile dither veya boyalı hale dokusu gerekli).
- Yağmur/sis/kül gibi hava efektlerinin gravür dilinde (çizgi yağmur, taramalı sis) çizilmesi kimliği güçlendirir.

### 4.5 Hareket ve animasyon
- Motion Rules çok olgun: mesafeye bağlı yürüme, mürekkepten sahne geçişi, düğme tepkisi, ölüm düşüşü, Reduce Motion. Bu tür küçük bir ekip için nadir görülen bir disiplin.
- **8 fazlı yürüme döngüsü** büyük figürlerde (savaş, gardırop) titrek görünür; yolda yeterli. Savaşta 12–16 kare ya da kareler arası harmanlama (frame blending) önerilir.
- Binicinin kol sallaması (10.2), koşumun görünmemesi (10.4) "kukla" hissi veriyor — bunlar küçük ama ekran görüntüsünde göze ilk batan hatalar.
- Eksik olan "anlatı hareketi": harita üzerinde atlının fenerinin titreşmesi, mürekkep izinin yol boyunca çizilmesi, olay kartının masaya düşmesi, defterde ismin üstünün çizilmesi. Bunlar zaten tasarlanmış (StruckLine, GrimNotice) — fragmanda öne çıkarılmalı.

### 4.6 UI hiyerarşisi ve kullanılabilirlik
- CityFront ve grim HUD: hiyerarşi var (sol kimlik, sağ kadro, alt eylem, tek kızıl ana eylem).
- Masa ekranları: hiyerarşi yok; her şey aynı punto, aynı renk, aynı ağırlık. Ana eylem (ör. "Yola çık", "Satın al") ikincil eylemlerden ayrışmıyor.
- Pazarda her satıra 4 düğme: sepete ekleme ve doğrudan alımın aynı satırda olması bilişsel yük. Tek tıklama satır seçimi + sağ panelde tek eylem kutusu (miktar, al/sat/pazarlık) daha temiz.

---

## 5. Amatör görünen vs. özgün görünen

**Amatör görünenler (önce bunlar gitmeli)**
1. Bantlaşan eş merkezli güneş/ay haleleri.
2. Lolipop/bulut ağaçlar ve koni çamlar (prosedürel orta katman).
3. Kel, ten renkli manken figürler (yolda "çıplak insanlar" gibi okunuyor).
4. Alçak poligon koni kamp ateşi, havada sandık.
5. Satır satır düğme dizileri (pazar), paragraf paragraf karakter listesi (parti).
6. Mor/mavi parlak büyü mermileri.
7. Kervan altındaki kütük/çubuklar, yarım kesik yol kenarı nesneleri.
8. Haritada sans-serif yer adı.

**Özgün görünenler (kimliğin çekirdeği)**
1. Gravür dünya haritası + fenerli atlı.
2. Taramalı mürekkep olay kartları ve masa sahneleri (kurtlar, defter, terazi).
3. Defter/soy fikri: üstü çizilen isimler, mühür, kırık mühür, "3. kuşak · 214. gün".
4. Uzun kervan kolonu silueti ve kamp ateşi etrafında toplanma.
5. Tally stick (açlık çentiği) gibi "resmin kendisi sayı" ikonları.

---

## 6. Tür liderleriyle karşılaştırma

| Oyun | Ne satıyor | Wayborne nerede |
|---|---|---|
| referans oyun | Kalın mürekkepli, elle boyanmış, büyük figürler; Mignola gölgeleri | UI düzeni neredeyse birebir alınmış; figür ve arka plan kalitesi yok. **Risk:** Steam'de "referans oyun klonu ama daha zayıf" etiketi. |
| The Banner Saga | Rotoskop animasyon, uzun kervan yürüyüşü, pastel ama melankolik manzara | Konu olarak en yakın akraba. Banner Saga'nın yürüyüş sahnesi kervan silüetini ekranın %60'lık bir panoramada küçük ama net gösterir; Wayborne'un yolu bunu yapmalı. |
| Pentiment | Tek bir tarihî görsel kaynağa (el yazması, gravür) sadakat; UI = sayfa | Wayborne'un harita + defter + olay kartı üçlüsü bu sadakati yakalayabilir. En doğru model. |
| 80 Days / Heaven's Vault (Inkle) | Az ama tutarlı stil; harita = oyunun merkezi; tipografi kimlik taşır | Harita merkezli yolculuk; Wayborne haritayı bir menü değil, ana sahne yapmalı. |
| Sunless Sea | Karanlık, tek ışık, harita keşfi, metin + illüstrasyon portresi | Olay kartları bu dili zaten konuşuyor; portre eksik. |
| KCD harita | Elle çizilmiş, renkli ama tarihî kartografi; zoom'da detay | Final harita bu kalitede; renk/bölge kimliği eksik. |
| Oregon Trail (2021) | Yol düzeni | Düzen alınmış; stil (yumuşak 3B) de farkında olmadan alınmış — figürler oraya ait. |

**Özet:** Wayborne'un referans oyunda alması gereken şey sistem (stres, ölüm, mevki); görsel olarak Pentiment + Banner Saga + Inkle haritası çizgisine gitmesi hem daha özgün hem de mevcut en iyi varlıklarıyla uyumlu.

---

## 7. Steam testi: "Bu kapsül ve ekran görüntüsü satar mı?"

- **Bugünkü haliyle hayır.** Mağaza sayfasındaki ilk 4 ekran görüntüsü bugün şunlar olurdu: halkalı ay altındaki yol (zayıf), CityFront (referans oyunda benzer, kit binalar), masa ekranı (metin dökümü), savaş (boş, küçük figürler). İlk görüntüde kimse "bu ne oyunu" sorusuna cevap alamaz.
- **Satacak olanlar:** (1) gravür harita üzerinde fenerli atlının gece yürüyüşü, (2) bir olay kartının tam ekran illüstrasyonu ve seçenekleri, (3) mürekkep defterde üstü çizilen bir isim + kırık mühür, (4) gün batımında uzun kervan kolonunun panoraması (yeniden çizilmiş yol), (5) şehir kapısına varış.
- **Kapsül (header capsule 920×430 ve ana kapsül 616×353):** Oyun içi ekran değil, ayrı bir anahtar görsel (key art) gerekir: olay kartı stilinde, fenerli bir arabacı, arkasında uzanan kervan, yolun bir harita çizgisine dönüştüğü kompozisyon; logo Grenze Gotisch, sepya üstüne kan kırmızısı aksan. Küçük kapsülde (231×87) yalnız logo + fener okunmalı.
- **Fragman açılışı:** Haritada bir mürekkep çizgisinin çizilmesi → çizginin ucunda atlı → kamera yolun içine "dalar" → yol sahnesi. Bu geçiş oyunun iki katmanını (harita/yol) tek görüntüde anlatır.

---

## 8. Üretim fizibilitesi (küçük ekip)

| Hat | Güçlü | Zayıf | Wayborne'da kullanım önerisi |
|---|---|---|---|
| **3B → 2B render** (Blender, mevcut figür ve kasaba hattı) | Modüler giysi/ekipman, yön, animasyon, tutarlı ölçek; hat zaten kurulu ve testli | Stil "3B" kokuyor; NPR geçişi olmadan illüstrasyonla uyuşmaz | **Hareket eden her şey için koru** (insan, hayvan, vagon, kasaba) ama tek bir NPR geçişiyle: değişken kalınlıkta mürekkep konturu, 3 ton, tarama gölgesi, kâğıt dokusu. Atlı işaretteki halftone tarama zaten bu yönün kanıtı. |
| **Elle boyama** | En özgün sonuç | Küçük ekip için yavaş; tutarlılık sanatçıya bağlı | Yalnız logo, kapsül/key art ve birkaç hero sahnenin son rötuşu. |
| **AI destekli illüstrasyon** (mevcut waybook hattı) | Hızlı, stil çapasıyla tutarlı; olay kartları için ideal | Tekrarlanan motif, anatomik hata, hukuki/etik algı; Steam beyanı zorunlu | Statik illüstrasyon için (olay kartı, masa sahnesi, mekân sahibi portresi, key art taslağı) **kilitli stil çapası + insan rötuşu**. Animasyonlu/modüler varlıklar için kullanma. |
| **Prosedürel `_draw()`** | Bedava, sonsuz varyasyon | Kimliği en çok zayıflatan katman | Yalnız yedek (fallback) ve UI işaretleri (pip, chevron). Dünya çizimi olarak emekliye ayır. |

**Kritik risk — AI beyanı:** `wayborne\AI_DISCLOSURE.md` "oyundaki tüm görseller ... prosedürel çizim fonksiyonlarıyla (`_draw()`) üretilir" diyor. Bu artık doğru değil: `art_source/waybook/` üretilmiş sayfalar (CLAUDE.md: *"Raw generated sheets"*, *"The generator stops at ~1376 px"*), harita için AI büyütme denemeleri (`gonderilen\18_ai_buyutme.jpg`, `20_buyutme_modelleri.jpg`) ve CC0 3B kitler var. Steam'in "önceden üretilmiş AI içerik" beyanı ve CREDITS güncellenmeden mağaza sayfası açılmamalı. Ayrıca CC0 kit binalar (Quaternius, Kenney) oyuncular tarafından tanınır; ön planda değiştirilmeden kullanılmamalı.

**Bütçe önerisi (kaba, tek kişi + AI):**
- NPR geçişi (karakter + hayvan + vagon + kasaba için ortak Blender post/Godot shader): 1–2 hafta.
- Yol katmanlarının yeniden üretimi (5 biyom × 4 katman, NPR ile): 2–3 hafta.
- Saç/baş aksesuarı seti (6–10 parça × 6 beden): 1 hafta (hat hazır).
- Masa ekranlarının UI düzeni (grim kit v2): 2–3 hafta.
- Key art + kapsül seti: 1 hafta (AI taslak + elle rötuş veya ücretli illüstratör).

---

## 9. Somut öneriler

### 9.1 Kimlik kararı (önce bu)
- **Tek cümlelik stil tanımı:** *"Wayborne, bir kervan kâtibinin defterine ve haritasına mürekkeple çizilmiş bir dünyadır."* Her görsel karar bu cümleye karşı sınanır: kâğıt mı, mürekkep mi, tek ışık mı?
- **Stil rehberi (1 sayfa):** kâğıt beyazı + mürekkep siyahı (hex), 3 ton kuralı, kontur kalınlığı (yakın 3 px, orta 2 px, uzak 0 — pus), tarama yönü (45°, tek yön; gölgede çapraz), tek sıcak ışık + vinyet, kırmızı yalnız kan/kayıp/ana eylem, kehribar yalnız ışık. 12.2e madde 1'deki "tek sayfalık stil rehberi" bu olsun; §9 ve §12 aynı belgeye bağlansın.

### 9.2 Ekle
1. **Ortak NPR geçişi** (render sonrası): mürekkep konturu (derinlik + normal kenar), 3 tonlu tarama, kâğıt dokusu çarpımı. Karakter, hayvan, vagon, kasaba, yol katmanları hepsi aynı geçişten çıksın. Atlı işaretin halftone'u referans.
2. **Saç ve baş aksesuarları** (kukuleta, kalpak, sarık, başörtüsü, miğfer, şapka) — kel manken sorununu ve siluet sorununu birden çözer; kültürlere göre ayrışma da sağlar.
3. **Portreler:** karakter, parti, taverna adayı, mezar defteri için büst portresi (olay kartı stili, AI destekli + rötuş; ya da figür render'ından yakın plan + NPR). referans oyunda değil Sunless Sea'nin kart portresi gibi.
4. **Savaş arka planları:** biyom başına bir mekân plakası (yol, orman açıklığı, geçit, harabe) — yol katmanlarının yeniden kullanımıyla ucuz. Figürleri ekran yüksekliğinin %30–35'ine büyüt.
5. **Gravür FX:** kan = mürekkep sıçraması, duman/sis = tarama, kritik = kırmızı mühür damgası ("ölüm mührü", `g9_seal` ailesi), büyü = sepya üzerine tek renk mürekkep fırçası.
6. **Haritada bölge kimliği:** her bölgeye hafif bir renk yıkaması (suluboya, %10–15 opaklık), kıyıya çift kontur + dalga çizgileri, deniz için gravür yatay çizgi tarama; yer adları IM Fell English SC.
7. **Harita–yol köprüsü:** haritada kervanın geçtiği yol mürekkeple "çizilsin" (kalıcı iz = oyuncunun hikâyesi); kamp yerleri küçük ateş işareti olarak kalsın.

### 9.3 Çıkar
1. Prosedürel güneş/ay diski ve halkaları → boyalı hale dokusu veya yalnız ışık bandı (12.2e'nin önerisi doğru).
2. Prosedürel lolipop ağaç ve koni çam (orta katman) → render + NPR.
3. Prosedürel sırtlar → yalnız fallback.
4. Gardıroptaki çıplak manken → en az iç çamaşırı/keten gömlek varsayılan katmanı; asla çıplak ten.
5. Pazardaki satır başına 4 düğme → seçim + tek eylem paneli.
6. Parlak mor/mavi VFX.
7. Ön planda değiştirilmemiş CC0 kit binalar (en az çatı/cephe malzemesi değişimi + NPR).

### 9.4 Birleştir
1. Kurt: olay kartı (`e6b_wolves.jpg`) ile savaş/yol kurdu aynı renk ve konturda olsun.
2. Vagon: menü, yol, kamp, şehir kapısı ve atlı işaret aynı vagon render'ından.
3. Fener: atlı işaretin feneri = yoldaki kervan feneri = menüdeki ışık kaynağı = UI'ın kehribar aksanı. **Fener, oyunun görsel motifi olsun** (logo yanında küçük fener amblemi bile olabilir).
4. Tipografi: harita, HUD, defter, kartlar aynı üç yüz; harita önizlemesindeki sans-serif kaldırılsın.
5. Masa ekranları: `mockups\4_trade.jpg`'deki üç bloklu düzen (sol liste / orta metafor nesnesi / sağ kervan) tüm mekânlara şablon.

### 9.5 Şehir ekranı için ayrı not
- referans oyun düzeninin birebir kopyası kısa vadede işlevsel ama kimlik açısından borç. Önerim: **kervan merkezli şehir**. Şehrin önünde (kapı dışında) kervanın kamp kurduğu meydan ön planda; şehir arka planda. Mekânlar levha olarak kalsın ama "kadro kartları" kervanın kendisinin yanında dursun. Böylece her şehirde ön plan (kervan) sabit, arka plan (şehir) değişir — üretim de ucuzlar, kimlik de "kervan" olur.
- 12.1 (kamera geri) ve 12.2a (şehir kapısı) aynı Blender sahnesinden çıkarılmalı: kapı sahnesi = şehir ekranının daha geniş planı.

---

## 10. Kimliği tanımlayacak 5 "hero" görsel

1. **Gece haritası ve fenerli atlı** — Gravür harita, saate göre kararır (8.10), yerleşimlerde küçük ışıklar (8.11), atlının feneri haritada sıcak bir nokta; arkasında mürekkeple çizilmiş yol izi. *Kapsül ve fragman açılışı.*
2. **Kamp ateşi panoraması** — Gece, uzun kervan kolonu yarım daire kurmuş, ateş ilk varanla yanar (12.2c), figürler NPR'li, sis taramalı; ana menü de bu sahnenin bir karesi. *Ana menü + mağaza ekran görüntüsü 1.*
3. **Olay kartı** — Tam ekran taramalı illüstrasyon (kurtlar, köprü, fırtına), altında seçenekler kan şeridi/stat amblemiyle. *Mağaza ekran görüntüsü 2; oyunun "anlatı" yüzü.*
4. **Defter ve mühür** — Kuşaklar arası soy defteri; bir ismin üstünün canlı mürekkeple çizildiği an, kırık mühür, mezar işareti. *Oyunun duygusal imzası; fragman kapanışı.*
5. **Şehir kapısına varış** — Kervan kapıya yaklaşırken kapı kanadı kalkar, şehrin kendi mimari dili, toz perdesi ve akşam ışığı (12.2a). *Mağaza ekran görüntüsü 3; dünyanın ölçeği.*

(Savaş, figürler büyütülüp mekân arka planı ve mühür damgası eklenmeden hero listesine girmemeli.)

---

## 11. Mevcut görev listesiyle ilişki ve öncelik önerisi

| Görev | Görüşüm | Öncelik önerisi |
|---|---|---|
| 12.2e yol estetiği | Haklı; ama önce NPR geçişi ve stil rehberi kararı verilmeli, yoksa yeniden prosedürel cila olur | **P1, ilk iş stil rehberi + 1 biyom deneme karesi** |
| 12.2d çubuklar, 10.1–10.4 figür hataları | Ekran görüntüsüne en çok batan küçük hatalar; ucuz | P1, hemen |
| 12.2a şehir kapısı | Hero 5; şehir ekranı geniş planıyla aynı sahneden | P1 |
| 12.1 şehir kamerası | §9.5 kararıyla birlikte | P1 |
| 8.1–8.2, 8.10–8.11 harita | Hero 1; bölge renk yıkaması ve tipografi düzeltmesi eklenmeli | P1 |
| §9.1 grim kit v2 | Doğru; masa ekranlarının metin dökümü sorununu çözen asıl iş | P2 → **P1'e çek** |
| §9.6 karakter ekranı, §9.7 roster | Portre ve saç/aksesuar olmadan yarım kalır | P2, portre işiyle birlikte |
| §9.8 savaş | Figür büyütme + arka plan + mühür; şu an en zayıf ekran | P2 |
| §9.3 şehir durum varyantları (6 şehir × 4 varyant) | Küçük ekip için pahalı; önce kervan merkezli şehir kararını ver | P3 / ertele |
| §9.13 ve §1 isim temizliği | referans oyun izlerini temizlemek doğru; görsel benzerlik (§6) de aynı riskin parçası | P1 |
| — (yeni) AI beyanı ve CREDITS güncellemesi | Mağaza sayfası öncesi zorunlu | **P1, yeni madde** |
| — (yeni) Key art + kapsül seti | Mağaza sayfası öncesi | P2, yeni madde |
| — (yeni) Ortak NPR geçişi | Tutarlılığın anahtarı | **P1, yeni madde** |
| — (yeni) Saç/baş aksesuarı seti | En ucuz, en görünür kazanç | P1, yeni madde |

---

## 12. Son söz

Wayborne'un teknik altyapısı (figür hattı, kurallar, testler, hareket disiplini) bir indie için olağanüstü; görsel sorun yetenek değil **karar** sorunu. Harita ve olay kartları oyunun ne olmak istediğini zaten söylüyor: bir kâtibin defterine mürekkeple çizilmiş, fenerle aydınlanan bir yol. Yeni içerik üretmeden önce mevcut 3B ve prosedürel katmanları o dile çekecek tek bir NPR geçişi ve tek sayfalık bir stil rehberi, sonraki tüm art işlerinin israf olmamasını sağlar.
