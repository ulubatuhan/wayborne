# Olay Penceresi Yeniden Tasarımı — Mimari + Varlık Üretim Planı

**Durum:** Mimari ve varlık listesi onaylandı (§2, §8). Henüz hiçbir
Godot kodu yazılmadı ve ham görseller üretilmedi — sıradaki adım için
bkz. §8. `docs/art-prompts.md`'nin kardeşi: o dünya sahneleri
(yol/şehir/menü) için, bu **olay kartı arayüz kromu ve olay
illüstrasyonları** için.

**Kapsam:** EU4'ün olay penceresi yapısını ("başlık şeridi → merkez
resim → defter metni → dikey seçenek satırları") Waybook üslubuna
uyarlamak. Mevcut kod (`road_journey.gd::_render_card()` /
`_build_choice_button()`) `SEAL_PANEL`'i (g3_seal) düz bir çerçeve olarak
kullanıyor ve hiç illüstrasyon taşımıyor — bu belge o boşluğu dolduruyor.

---

## 1. Mimari

### 1.1 Kompozisyon hiyerarşisi

```
Modal/Center                              (mevcut - road_journey.tscn)
└── EventCard  [E_Frame_Master, dokuz-parça]
    ├── HeaderBanner  [E_Header_Banner]     ← YENİ katman
    │   └── TitleLabel (event.title_key)    (mevcut, taşındı)
    ├── IllustrationCanvas                  ← YENİ katman
    │   └── TextureRect (kategori resmi)    (mevcut hiç yok)
    ├── BodyScroll (mevcut, değişmedi)
    │   └── BodyLabel (event.text_key)
    └── ChoiceList (mevcut VBoxContainer)
        ├── ChoiceRow × N  [E_Choice_Row_Normal / _Hover]
        │   ├── StatEmblem (mevcut WaybookIcons.STAT_EMBLEMS)
        │   ├── ChoiceLabel (mevcut metin + check preview + danger etiketi)
        │   └── CombatStripe (mevcut ColorRect, UI_CHOICE_COMBAT)
        └── ...
```

**Karar (bkz. §2): kilitli seçenek çizgi taşımıyor.** Yalnızca solma -
mevcut `font_disabled_color`/`disabled = true` çözümü aynen kalıyor,
yeni bir katman eklenmiyor.

Hiçbir mevcut veri sözleşmesi değişmiyor: `GameEvent → EventChoice →
EventOutcome` ağacı, `EventCondition`, `SkillCheck`, `get_check_preview()`,
`_choice_triggers_combat()`, `_mark_choice()` — hepsi aynı kalıyor. Bu
tasarım yalnızca **görsel** katmanı ekliyor/değiştiriyor:

- `_render_card()` üç yeni çocuk kazanıyor (`HeaderBanner` önce, sonra
  `IllustrationCanvas`, `BodyScroll`/`ChoiceList` yerinde kalıyor).
- `_build_choice_button()` `Button`'ı bir `PanelContainer` + `Button`
  ikilisine çevirir **ya da** `Button`'ın kendi stilini yeni
  `theme_type_variation`'a (`EVENT_CHOICE_ROW`) çevirir — ikinci yol daha
  az kod değişikliği ister ve mevcut `_mark_choice()`'ın `add_child`
  ettiği şerit/amblem mekaniğini bozmaz. **Önerilen: ikinci yol.**
- `EventCard`'ın çerçevesi artık `SEAL_PANEL` değil, yeni `EVENT_CARD`
  varyasyonu (`E_Frame_Master`) — bkz. §3.

### 1.2 Illüstrasyon kaynağı — kategori, olay değil

41+ olayın her birine özel bir resim sipariş etmek hem üretim maliyeti
hem de tekrar-kullanım ilkesiyle (bkz. CLAUDE.md Art Rules: "a shape
drawn in two places is two different shapes" — tersi de geçerli, aynı
sahne iki yerde iki kez çizilmemeli) çelişir. Oyun zaten olayları
**kategoriye** göre gruplamış durumda — `road_journey.gd`'nin
`EVENT_ROAD_MARKER_KIND` / `MARKER_ARCHETYPES` sözlükleri, olayı yolda
beliren fiziksel işaretin hangi silüeti taşıyacağını seçiyor
(wildlife/bandit/guard/traveler). Illüstrasyon sistemi **aynı
kategorizasyonu** okuyor, ikinci bir sınıflandırma icat etmiyor. Fiziksel
karşılığı olmayan olaylar (kervan-içi, hava, dünya haberi) için altı yeni
kategori eklendi — tam liste §4'te.

### 1.3 Neden `SEAL_PANEL`'in kendisi değil de yeni bir `E_Frame_Master`

`tools/waybook_assets.py`'ın kendi notu: *"R5 (event card parchment) is
not shipped: the event card is the sealed binding, dark ground, bone
text — a light parchment card would need every card line recoloured and
fought the seal frame."* Yani açık renkli bir parşömen kart **daha önce
denenmiş ve bilerek terk edilmişti** — bu doğru karardı, geri
alınmıyor. `E_Frame_Master` o kararın **devamı**: aynı koyu mühürlü cilt
ailesi (g3_seal'ın "geri alınamaz karar" ağırlığı), yalnızca başlık
şeridi ve resim penceresi için ek pay taşıyan, dikey olarak uzamış bir
varyant. Yeni bir görsel dil icat edilmiyor, var olanı genişletiyor.

---

## 2. Tasarım kararı — çözüldü

**Kilitli seçenek çizgi taşımayacak, yalnızca solacak.** G5'in "mürekkep
karalama" fikri daha önce (kalıcı kilitli menü düğmeleri için) playtest'te
reddedilmişti (CLAUDE.md, Waybook UI Rules: *"the player rejected it in
playtest ('güzel gözükmüyor, silik olması yeterli')"*). Olay kartı
bağlamında dar bir versiyonu önerilmişti (§2'nin eski hali) ama karar
**hayır** - hiçbir yeni işaret eklenmiyor. `E_Choice_Row_Locked` varlığı
**listeden çıkarıldı**; kilitli bir seçenek `_build_choice_button()`'ın
zaten yaptığı gibi yalnızca soluyor (`font_disabled_color`,
`disabled = true`) - `_mark_choice()`'a hiçbir yeni katman eklenmiyor.
Beş varlık dörde indi: **E_Frame_Master, E_Header_Banner,
E_Choice_Row_Normal, E_Choice_Row_Hover.**

`art_source/waybook/G5_disabled_scratchout.jpg` kullanılmıyor, orphan
kalmaya devam ediyor.

---

## 3. Dört çekirdek varlık

Üretim tarifi mevcut G-serisiyle **birebir aynı**: düz orta gri
(`~rgb(140,140,140)`, `key()` fonksiyonunun zaten kilitlendiği ton) arka
plan üstünde mürekkep-çizgi + suluboya lekeli "gravür" üslubu (bkz.
`G2_binding_frame.jpg`/`G3_seal_frame.jpg`/`G4_button_tab.jpg` — kroşe
tarama gölgeler, eskitilmiş deri/pirinç, dikiş izleri). **Bu, dünya
sahneleri için `docs/art-prompts.md`'nin "yassı-resimsel" stilinden
ayrı bir tarif** — orası boyalı bir manzara, burası boyanmış bir nesne.

Ortak ön-ek (dördünün de promptunun başına ekle):

```
Bir masaüstü/web oyunu için UI çerçeve dokusu çiziyorsun (ikon değil,
arayüz malzemesi). Düz, tekdüze orta gri arka plan (yaklaşık
RGB 140,140,140) — bu arka plan sonradan şeffaflığa dönüştürülecek,
o yüzden ARKA PLANDA gradyan, doku, gölge OLMASIN, yalnızca nesnenin
kendisi. Stil: elle çizilmiş gravür/İngiliz av kitabı illüstrasyonu -
ince mürekkep kontur çizgileri, kroşe (cross-hatch) gölgeleme, hafif
suluboya lekesi renklendirme. Malzeme: eskimiş koyu bordo/kestane deri,
donuk pirinç/bronz metal (parlak değil, lekeli), paslı demir kelepçe/
menteşe, kalın dikiş izi. Palet: CLAUDE.md'nin ArtPalette paleti - kemik
(BONE, #E1D9C7), mürekkep siyahı (INK, #0E0D0F, saf siyah değil), soluk
altın (GOLD, #DCB357), kurumuş kan (BLOOD, #A83029). Fotogerçekçi değil,
3D değil, parlak/cilalı değil - her zaman mat ve eskimiş. Metin, logo,
watermark ÇİZME.
```

| Asset ID | Kaynak dosya | Sevkiyat dosyası | Boyut/dilim | Açıklama | Prompt (ön-eke ekle) |
|---|---|---|---|---|---|
| **E_Frame_Master** | `art_source/waybook/E1_card_frame.jpg` | `data/assets/ui/waybook/e1_frame.png` | Kaynak 1024×1536 (dikey), dokuz-parça dilim ~96px (SEAL_SLICE'ın 78'inden biraz geniş — kart artık daha uzun, orantı korunmalı), içerik payı ~72px | Dikey, uzamış bir mühürlü cilt çerçevesi — g3_seal'ın aynı köşe pirinç plakaları + orta kenar kelepçeleri, ama üstte başlık şeridine yer açan ekstra bir enine kesim çizgisi (ince bir menteşe/kelepçe ile ayrılmış "üst göz"), ortada resim penceresine yer açan ikinci bir kesim. Orta gri pencere üç ayrı bölgede: üstte dar (başlık), ortada geniş (resim), altta en geniş (metin+seçenekler). | `SAHNE: Dikey dikdörtgen bir sandık/mühür kapağı çerçevesi, üç yatay bölmeye ayrılmış (ince pirinç bir çıta her bölmeyi ayırıyor): en üstte dar bir şerit, ortada kare bir pencere, altta en uzun pencere. Dört köşede g3'teki gibi nakışlı pirinç plakalar, kenarlarda eskimiş bordo deri şerit, üstte ve ortada birer demir kelepçe/mandal (kapağın "mühürlü" olduğunu gösteren). Orta gri pencereler tamamen boş ve düz kalsın - üstlerine hiçbir şey çizme, onlar sonradan oyunun kendi metni/resmiyle dolduruluyor.` |
| **E_Header_Banner** | `art_source/waybook/E2_header_banner.jpg` | `data/assets/ui/waybook/e2_banner.png` | Kaynak 1536×384 (yatay şerit), dokuz-parça yalnızca yatay dilim ~120px uçlarda, orta döşenir | Yatay bir "isim plakası" şeridi — R1'in HUD kayışıyla aynı aile (perçinli deri kuşak) ama iki ucu sivri/kalkan biçimli kapanan bir levha, ortası düz gri (başlık metni oraya gelecek). | `SAHNE: Yatay, ince bir pirinç isim plakası/levha - iki ucu üçgen/kalkan şeklinde sivrilerek kapanıyor (bir zırh göğüs plakasının üst kenarı gibi), uçlarında birer küçük perçin. Levhanın ortası (yaklaşık %70'i) tamamen düz, boş, tekdüze gri kalsın - metin oraya bindirilecek. Levhanın kendisi hafif kabartma/rölyef hissi versin (kenarları biraz daha koyu, ortası biraz daha açık ton) ama gerçek bir gölge/gradyan ARKA PLANA değil yalnızca levhanın metaline uygulansın.` |
| **E_Choice_Row_Normal** | `art_source/waybook/E3_choice_row_normal.jpg` | `data/assets/ui/waybook/e3_row_normal.png` | Kaynak 1536×256 (yatay şerit), dokuz-parça simetrik dilim ~48px (IconTab'ın simetri dersini uygula - kulak YOK) | Dar, yatay bir "defter satırı" şeridi — G4'ün kulak/asimetrisi yok (Faz 21'de default düğmeler zaten bu hataya düştü ve düzeltildi, tekrarlanmasın), düz iki uçlu, hafif kabartmalı ince deri kenarlıklı çizgili kâğıt hissi. | `SAHNE: Yatay, dar (kart genişliğinde) bir "defter satırı" - L1'deki çizgili muhasebe kâğıdının dokusu (ince yatay cetvel çizgileri, lekeli sararmış kâğıt) ince bir koyu deri çerçeve içinde. ÇERÇEVE SİMETRİK olmalı - sol ve sağ kenar birbirinin aynı, G4'teki gibi bir "kulak" ya da çıkıntı OLMASIN. Üst ve alt kenarda ince bir dikiş izi. Sol kenarda küçük bir boşluk bırak (bir stat amblemi ikonu oraya bindirilecek).` |
| **E_Choice_Row_Hover** | `art_source/waybook/E4_choice_row_hover.jpg` | `data/assets/ui/waybook/e4_row_hover.png` | E_Choice_Row_Normal ile birebir aynı kesim/dilim | Aynı satır, yalnızca kenarlık soluk altına (GOLD) dönmüş ve kâğıt zemini hafif aydınlanmış — üstüne gelinen bir satır "seçilmeye hazır" okunsun. | `[E_Choice_Row_Normal promptunun BİREBİR AYNISI], tek fark: deri çerçevenin rengi koyu bordo yerine sıcak soluk altın/pirinç tonunda (#DCB357 civarı), ve kâğıdın üstünde çok hafif bir sıcak ışık havuzu var - sanki bir mum ona yaklaşmış gibi.` |

**Kilitli satır (§2):** ayrı bir varlık yok. `EVENT_CHOICE_ROW`
varyasyonunun `disabled` state'i `_ghost_button`/`_minimal_button`'ın
zaten kurduğu kalıbı izler - `E_Choice_Row_Normal`'ın aynısı, yalnızca
`ArtPalette.UI_TINT_DISABLED` ile soluklaştırılmış (`modulate_color`
üzerinden, ayrı bir kaynak dosya gerektirmeden). `art_source/waybook/
G5_disabled_scratchout.jpg` ve `A0_style_anchor.jpg` bu tasarımın dışında
kalıyor, orphan.

---

## 4. Seçenek satırının "kilitli" ve "savaş açabilir" katmanları

Kod tarafında değişmeyecek olan (hatırlatma, üretime etkisi yok):
`_mark_choice()`'ın kan şeridi (`UI_CHOICE_COMBAT`) ve stat amblemi
zaten var — yeni `E_Choice_Row_*` yalnızca bunların **üstüne bindiği
zemin**. Kilit sebebi metni (`unavailable_text_key`) hâlâ düğmenin
`font_disabled_color`'ıyla canlı okunuyor; kilitli satır (§2) yalnızca
soluyor, metni gizlemiyor — "disabled with reason" sözleşmesi
bozulmuyor, yeni bir görsel katman eklenmiyor.

---

## 5. Sanat Stili Temel Şablonu — olay illüstrasyonları

Bu, dört çekirdek varlığın dışında ayrıca hazırlanan beşinci parça: tek
bir dosya değil, **her illüstrasyon promptunun
başına eklenen sabit blok**. `docs/art-prompts.md`'nin "Ortak Bağlam"
deseninin aynısı — ama iki fark var:

1. Bu bir *sahne* değil bir *vinyet*: resmin kendisi kartın dar
   penceresine (yaklaşık kare, ~1:1) oturacak, tam ekran değil.
2. Arka plan tamamen dolu değil — kenarlara doğru `ArtPalette.INK`'e
   soluyan bir vinyet (koyu çerçeve içine "gömülü" bir resim hissi,
   masa sahnelerinin `BackgroundScrim`'iyle aynı "kenar okumayı
   bozmasın" mantığı).

```
[docs/art-prompts.md'nin "Ortak Bağlam"ı - OYUN ve SANAT YÖNÜ paragrafları
birebir aynen buraya eklenir, tekrar yazılmıyor]

EK KURAL (yalnızca olay kartı illüstrasyonları için):
FORMAT: Kare veya kareye yakın (1:1 ile 4:5 arası), TEK bir an/sahne -
EU4'ün olay resimleri gibi "bu olayın kalbi olan tek kare", bir manzara
panoraması değil.
VİNYET: Resmin kenarları (özellikle dört köşe) yumuşakça `ArtPalette.INK`
koyu tonuna doğru kararıp kayboluyor - resmin kendi çerçevesi yok, kart
çerçevesinin (E_Frame_Master) penceresine gömülüyor.
KOMPOZİSYON: Sahnenin öznesi (kişi/hayvan/yapı) kadrajın ortasında veya
alt-üçte-birinde, kameraya yakın - bir olay kartı "bak, bu oldu" der,
uzak bir manzara değil.
METİN/İKON: Kesinlikle yok.
```

Her kategori promptu bu bloğun **altına tek bir SAHNE satırı** ekler
(bkz. `docs/art-prompts.md`'nin "Varyasyon istersen" deseni — ortak
bağlamı tekrar yazmadan yalnızca değişen satırı ver).

---

## 6. Olay ağacına göre illüstrasyon kategorileri (dosya adları dahil)

21 kategori, mevcut kodun kendi sınıflandırmasından (`EVENT_ROAD_MARKER_KIND`,
`MARKER_ARCHETYPES`, `RouteTerrain` durakları) türetildi — yeni bir taksonomi
icat edilmedi. Kaynak dosyalar `art_source/waybook/E6<harf>_illus_<ad>.jpg`,
sevkiyat `data/assets/ui/waybook/e6<harf>_<ad>.jpg` (nine-slice değil, düz
JPG — `WaybookTheme.picture()`'ın zaten yaptığı gibi oranı koruyarak
ölçekleniyor, dilim gerekmiyor). Kaynak boyut: 1536×1536 (kare, kartın
resim penceresinden daha yüksek çözünürlükte üretilip küçültülüyor —
G-serisinin 1024→256 küçültme oranıyla aynı disiplin).

| # | Kategori | Dosya (kaynak / sevkiyat) | SAHNE satırı (§5 şablonunun altına ekle) |
|---|---|---|---|
| a | wildlife_ambush | `E6a_illus_wildlife.jpg` / `e6a_wildlife.jpg` | `SAHNE: Alacakaranlık bir orman kenarında, ağaçların arasında iki-üç çift parlayan hayvan gözü ve belli belirsiz bir gövde silüeti - hangi hayvan olduğu net değil, yalnızca "bir şey izliyor" hissi. Kervanın kendisi kadrajda yok, bu onun gördüğü şey.` |
| b | wolf_pack | `E6b_illus_wolves.jpg` / `e6b_wolves.jpg` | `SAHNE: Karla kaplı yol kenarında, sırtlarını kamburlaştırmış 3-4 kurt, dişleri hafif görünür, kervanın izini takip ediyor gibi yan yan bakıyorlar. Soğuk mavi-gri gece ışığı.` |
| c | bandit_ambush | `E6c_illus_bandits.jpg` / `e6c_bandits.jpg` | `SAHNE: Yolu kesen, yüzleri bezle sarılı, kılıç/mızrak taşıyan 2-3 haydut - kameraya yakın, tehditkâr bir duruşla yolu kapatmışlar. Arka planda sarp kayalık bir geçit.` |
| d | guard_checkpoint | `E6d_illus_guard.jpg` / `e6d_guard.jpg` | `SAHNE: Mızraklı, tolgalı bir muhafız (ya da küçük bir devriye), elini kaldırmış "dur" işareti veriyor - arkasında bir sancak direği ya da basit bir kontrol bariyeri.` |
| e | traveler_wanderer | `E6e_illus_traveler.jpg` / `e6e_traveler.jpg` | `SAHNE: Tek başına, sırt çantalı, yorgun bir yolcu - yolun kenarında durmuş, kervana doğru bakıyor, ne dost ne düşman, belirsiz bir duruş.` |
| f | merchant_caravan | `E6f_illus_merchant.jpg` / `e6f_merchant.jpg` | `SAHNE: Karşı yönden gelen, yüklü bir başka kervan - bir-iki öküz arabası ve birkaç yaya tüccar, uzaktan selamlaşır gibi el kaldırmışlar.` |
| g | pilgrim | `E6g_illus_pilgrim.jpg` / `e6g_pilgrim.jpg` | `SAHNE: Sade kumaş cübbeli, elinde bir asa/tespih olan yalnız bir hacı, başı hafif eğik, yürüyor - kutsal bir sükûnet hissi, tehdit değil.` |
| h | roadside_shrine | `E6h_illus_shrine.jpg` / `e6h_shrine.jpg` | `SAHNE: Yol kenarında küçük, taştan yapılmış eski bir sunak/adak yeri - üstünde soluk kurdeleler, birkaç bozuk para, yanmış bir mum kalıntısı. Kimse yok, yalnızca yapı.` |
| i | mountain_pass | `E6i_illus_pass.jpg` / `e6i_pass.jpg` | `SAHNE: İki dik kayalığın arasından geçen dar bir dağ geçidi, yol yukarı doğru kıvrılıyor, uzakta karlı bir zirve.` |
| j | hamlet_wounded | `E6j_illus_hamlet.jpg` / `e6j_hamlet.jpg` | `SAHNE: Küçük, birkaç kulübeden oluşan bir yol köyü (hamlet) - bir kulübenin önünde yere çökmüş, yaralı görünen bir figür, yardım bekler gibi.` |
| k | frontier_outpost | `E6k_illus_outpost.jpg` / `e6k_outpost.jpg` | `SAHNE: Ahşap çitlerle çevrili küçük bir sınır karakolu - basit bir gözetleme kulesi, birkaç çadır, üstünde soluk bir bayrak.` |
| l | mine_collapse | `E6l_illus_mine.jpg` / `e6l_mine.jpg` | `SAHNE: Dağ yamacına açılmış bir maden girişi - ahşap destekler yarı çökmüş, girişten toz/duman çıkıyor, yakında terk edilmiş bir kazma.` |
| m | failing_bridge | `E6m_illus_bridge.jpg` / `e6m_bridge.jpg` | `SAHNE: Bir dereyi geçen eski ahşap köprü - tahtalardan biri kırık, sallanıyor gibi bir açıyla çizilmiş, altında hızlı akan su.` |
| n | storm_weather | `E6n_illus_storm.jpg` / `e6n_storm.jpg` | `SAHNE: Yolun üstünde toplanan koyu, kabarık fırtına bulutları, uzakta bir şimşek çakması, rüzgârda yatan birkaç ağaç - kervan kadrajda değil, yalnızca gökyüzü onu bekliyor.` |
| o | landslide | `E6o_illus_landslide.jpg` / `e6o_landslide.jpg` | `SAHNE: Dağ yolunu kısmen kapatan taze bir toprak/kaya heyelanı - kayalar ve devrilmiş bir ağaç yolun bir şeridini tıkamış, toz hâlâ havada.` |
| p | broken_wagon | `E6p_illus_wagon.jpg` / `e6p_wagon.jpg` | `SAHNE: Yol kenarına yatmış, bir tekerleği kırık, terk edilmiş görünen bir öküz arabası - eşyaları etrafa saçılmış, sahibi ortada yok.` |
| q | camp_night | `E6q_illus_camp.jpg` / `e6q_camp.jpg` | `SAHNE: Gece, bir kamp ateşinin çevresinde oturan birkaç kervan figürü - ateşin turuncu ışığı yüzlerini aydınlatıyor, gerginlik ya da yorgunluk hissi (kapalı bir yüz ifadesi, birbirinden uzak oturuş).` |
| r | wayside_grave | `E6r_illus_grave.jpg` / `e6r_grave.jpg` | `SAHNE: Yol kenarında basit, taştan bir mezar işareti/haç - üstünde eskimiş bir çiçek ya da kurdele, sessiz ve terk edilmiş.` |
| s | creditor_rider | `E6s_illus_creditor.jpg` / `e6s_creditor.jpg` | `SAHNE: Atlı, resmi kıyafetli, elinde mühürlü bir tomar/senet tutan bir alacaklı temsilcisi - kervanın yolunu kesmiş, sert bir duruş.` |
| t | world_news | `E6t_illus_news.jpg` / `e6t_news.jpg` | `SAHNE: Yol kenarındaki bir ilan direğine/ağaca çivilenmiş, mühürlü bir haber kâğıdı yakın plan - etrafında toplanmış birkaç meraklı yolcunun sırtı/silueti.` |
| u | forgotten_cache | `E6u_illus_cache.jpg` / `e6u_cache.jpg` | `SAHNE: Toprağın altından yarı görünen, eski, pas tutmuş bir sandık/torba - yosun ve toprakla yarı örtülü, uzun süredir orada duruyormuş hissi.` |

### 6.1 Tam olay → dosya eşleşmesi (58 olay)

*(kategori başlıkları tekrar edilmiyor, her satır az önceki tablodaki
dosyayı okur — bir olayın birden fazla kategoriyle eşleşmesi kasıtlı
çift-etiketleme, §6.2'de açıklanıyor)*

**a — wildlife_ambush:** `evt_wild_animal`

**b — wolf_pack:** `evt_carcass_on_road`, `evt_wolves_follow`, `evt_wolf_pack`

**c — bandit_ambush:** `evt_bandit_ambush`, `evt_wanderer_revenge`, `evt_bandit_tribute_toll`

**d — guard_checkpoint:** `evt_deserter_search`, `evt_bailiffs_at_camp`, `evt_guard_patrol`, `evt_customs_checkpoint`, `evt_road_patrol`, `evt_military_convoy`

**e — traveler_wanderer:** `evt_deserter_plea`, `evt_road_wanderer`, `evt_traveling_tinker`, `evt_kin_encounter`, `evt_refugee_column`, `evt_culture_valley_dispute`, `evt_culture_highland_challenge`†, `evt_culture_port_gossip`, `evt_culture_fisher_catch`

**f — merchant_caravan:** `evt_merchant_caravan`

**g — pilgrim:** `evt_pilgrim_encounter`, `evt_pilgrim_blessing`

**h — roadside_shrine:** `evt_roadside_shrine`

**i — mountain_pass:** `evt_culture_highland_challenge`†

**j — hamlet_wounded:** `evt_leave_the_wounded`

**k — frontier_outpost:** `evt_frontier_outpost`

**l — mine_collapse:** `evt_mine_collapse`

**m — failing_bridge:** `evt_failing_bridge`

**n — storm_weather:** `evt_storm`

**o — landslide:** `evt_landslide`

**p — broken_wagon:** `evt_broken_axle`, `evt_abandoned_wagon`

**q — camp_night:** `evt_troubled_night`, `evt_stress_brawl`, `evt_mutiny`, `evt_party_theft`, `evt_party_investigation`, `evt_stowaway`, `evt_stowaway_repay`, `evt_spoiled_provisions`, `evt_forage`, `evt_scouted_pass`

**r — wayside_grave:** `evt_grave_on_the_road`, `evt_grave_keeper`, `evt_grave_offering`

**s — creditor_rider:** `evt_creditor_rider`, `evt_deserter_debt`, `evt_left_behind_return`

**t — world_news:** `evt_regional_war_news`, `evt_plague_outbreak_news`, `evt_trade_fair_news`, `evt_bandit_tribute_zone_news`

**u — forgotten_cache:** `evt_forgotten_cache`, `evt_profiteer_recognized`, `evt_sick_merchant`, `evt_route_diversion`

† `evt_culture_highland_challenge` kasıtlı olarak iki kategoride: olay
hem "traveler" tipi bir kültürel karşılaşma (motor tarafında
`EVENT_ROAD_MARKER_KIND`'da böyle işaretli) hem de `RouteTerrain`'in
"pass" durağına bağlı (bkz. CLAUDE.md Route Terrain & Weather Rules).
Hangi resmin gösterileceği koddaki durak bayrağına (`near_mountain_pass`)
öncelik verir — durak varsa `i`, yoksa `e`.

### 6.2 Kapsam dışı bırakılanlar

`evt_route_diversion` ve `evt_bandit_tribute_zone_news` gibi bazı
olaylar `triggered_only` (yalnızca bir zincirin/dünya olayının tetiklediği,
oyuncunun asla rastgele çekmediği) - onlar da tabloya dahil, çünkü kart
onlar için de açılıyor, yalnızca havuzdan çekilme ağırlıkları yok. Codex'in
kendi belgeleme borcu (bkz. CLAUDE.md Faz 17 PR-9'un notu, 41 karttan
29'u belgeli) bu tabloyu etkilemiyor - burada 58 olayın hepsi sayıldı.

---

## 7. Üretim hattı entegrasyonu (yalnızca not — kod değil)

`tools/waybook_assets.py`'a eklenecek olan (bu belge onaylanınca, ayrı
bir PR'da):

- `_build_event_card()` fonksiyonu: `E1`-`E4` için `_filled_frame()`/
  `key()`/`_set_margins()` çağrıları — G-serisininkiyle birebir aynı
  kalıp, yalnızca dosya adları yeni.
- `_build_event_illustrations()`: `E6a`-`E6u` için düz `background()`/
  `icon()` benzeri bir ölçekleme (nine-slice yok) — `B10_city_desk_bg.jpg`
  için zaten kullanılan Lanczos+unsharp büyütme/küçültme yolunu izler.
- `WaybookTheme`'e yeni sabitler: `EVENT_CARD` (`PanelContainer`
  varyasyonu), `EVENT_CHOICE_ROW` (`Button` varyasyonu; normal/hover
  state'leri E3/E4'ten, disabled state'i §2 gereği E3'ün
  `UI_TINT_DISABLED` ile modüle edilmiş hali — ayrı kaynak dosya yok),
  `EventIllustrations.FILE_BY_EVENT_ID` (bu belgenin §6.1 tablosunun
  GDScript karşılığı - `Dictionary[String, String]`, bilinmeyen bir
  `event_id` `""` döner ve `IllustrationCanvas` o zaman gizlenir, boş bir
  kutu göstermez).
- `test_waybook_theme.gd`'ye: her `event_id`'nin (event_catalog.gd'den
  taranan) `FILE_BY_EVENT_ID`'de bir karşılığı olduğunu kilitleyen bir
  test — yeni bir olay eklenip kategori atanmayı unutulursa CI kırılır
  (aynı disiplin: `test_event_effects::_test_every_effect_type_is_handled`).

---

## 8. Sonraki adım

**Onaylandı:** (1) kilitli seçenek yalnızca soluyor, çizgi yok — §2, (2)
dört çekirdek varlık + 21 illüstrasyon promptu bu haliyle üretime giriyor.

Sıradaki iş, bu oturumun **yapamayacağı** tek parça: bu belgedeki 25
promptun (4 çekirdek + 21 illüstrasyon) bir görsel üretim modeline
(Gemini/FLUX) verilip ham JPG'lerin üretilmesi — bu oturumda görsel
üretim aracı yok, promptlar kopyala-yapıştıra hazır ama çalıştırmak
kullanıcı tarafında. Ham dosyalar `art_source/waybook/`'a (bu belgedeki
`E1`-`E4`/`E6a`-`E6u` adlarıyla) eklenince sıradaki iki adım burada
yapılabilir: `tools/waybook_assets.py`'ın §7'deki genişlemesi, ve ancak
ondan sonra `road_journey.gd`'nin gerçek kod değişikliği.
