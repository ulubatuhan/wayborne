# Wayborne stil rehberi (görev N11, Y-G01)

> **Wayborne, bir kervan kâtibinin defterine ve haritasına mürekkeple çizilmiş bir dünyadır.**

Bu cümle onaylı. Her yeni resim, ekran ve render ona karşı sınanır. Bir şey kâtibin defterinde ya da haritasında
duramıyorsa (parlak plastik, neon, temiz vektör, fotoğraf gerçekliği) yanlış yerdedir.

## Renk

Renk kaynağı tek: `scripts/ui/art_palette.gd`. Aşağıdaki kodlar oradan çevrildi. Yeni bir renk gerekiyorsa önce oraya
girer, sonra kullanılır.

| Rol | Ad | Kod | Kullanım |
|---|---|---|---|
| Mürekkep | `INK` | `#0E0D0F` | Kontur, en koyu gölge, sahne geçişi |
| Kömür | `GRIM_CHARCOAL` | `#121010` | Panel zemini |
| Yumuşak kömür | `GRIM_CHARCOAL_SOFT` | `#201C1A` | İkinci kat zemin, kart |
| Parşömen | `GRIM_PARCHMENT` | `#C4B08F` | Ana metin, kâğıt |
| Soluk parşömen | `GRIM_PARCHMENT_DIM` | `#8C785C` | İkincil metin, etiket |
| Kemik | `BONE` | `#E0D9C7` | Başlık, en açık metin |
| Kehribar | `GRIM_AMBER` | `#EDA852` | **Yalnızca ışık**: ateş, fener, pencere, seçili şey |
| Soluk altın | `GOLD_DIM` | `#856B38` | İnce çizgi, çerçeve |
| Kan | `BLOOD` | `#A8302B` | **Yalnızca kan, kayıp ve ana eylem** |
| Kızıl | `GRIM_CRIMSON` | `#992917` | Kan rengine yakın ama ikincil: uyarı yazısı |
| Pas | `GRIM_RUST` | `#734024` | Demir, eski ahşap |
| Demir | `GRIM_IRON` | `#454242` | Kilitli, kullanılamaz |
| Arduvaz | `GRIM_SLATE_LIGHT` | `#788A94` | Soğuk ışık, ay, kuzey |
| Kırağı | `GRIM_FROST` | `#CCE0ED` | Kar, buz |
| Safra | `GRIM_BILE` | `#8C9440` | Hastalık, zehir |

### İki kural

1. **Kırmızı yalnızca kan, kayıp ve ana eylem içindir.** Bunlar: can çubuğu, ölüm ve terk satırı, yola çıkış düğmesi,
   tehlike. Süs olarak kırmızı yok. Kırmızı her yerde olursa oyuncu gerçek kaybı göremez.
2. **Kehribar yalnızca ışık içindir.** Ateş, fener, pencere ve oyuncunun seçtiği şey (ışığın üstüne düştüğü yer). Kehribar
   bir yüzey rengi değildir. Duvarı, zemini ya da paneli kehribara boyamak ışığı öldürür.

## Ton

- **Üç ton.** Her nesne en çok üç tonla okunur: gölge, orta, ışık. Dördüncü ton gerekiyorsa o nesne iki nesnedir. Render
  hattı (`town_post.py`, `road_post.py`, figür paketleyicileri) tonları posterleştirir. Elle boyanan her şey de aynı
  sınırda kalır.
- **Tek sıcak ışık.** Bir sahnede tek bir sıcak kaynak vardır: ateş, han penceresi ya da batan güneş. Geri kalan her şey
  soğuk ortam ışığıdır (ay, sis, gece). Rengin tek kaynağı ışıktır: gölgeler mor-kömüre, uzaklar sisin rengine çekilir.
- **Uzaklık sisten gelir, keskinlikten değil.** Uzak katman mürekkepsiz ve puslu, yakın katman koyu ve mürekkepli. Göz
  kervanın ve meydanın düzlemine düşer.

## Çizgi

- **Kontur mürekkeptir.** Yakında kalın, uzakta ince. Render'larda parlaklık, derinlik ve maske kenarlarından türetilir;
  elle çizimde de aynı mantık geçerli.
- **Tarama, gölgenin dokusudur.** Geniş gölge alanları düz dolgu değil, ince tarama ya da kâğıt dokusuyla okunur.
  `town_post.py` kâğıt dokusunu (ambientCG Paper005) çarparak verir.
- **Bir gövdenin kenarı kapalıdır, bir eklemin içi kapalı değildir.** Parçalardan kurulan figürlerde iç kenara kontur
  çizilmez (bkz. CLAUDE.md, "The body carries no contour").

## Kâğıt ve kir

- Her tam ekran resim bir defter sayfasıdır. Üstünde kâğıt dokusu, kenar kararması, hafif kir (`grime_overlay.png`) ve
  tohumlu bir tane gürültüsü durur.
- Kir ve yıpranma bir bilgi taşıyorsa (açlık yanığı gibi) çerçevenin kenarında durur, sahnenin ortasında değil.

## Yerleşimler (P17)

Her yerleşim kendi sahnesine sahiptir (`tools/ui_scenes/settlement_towns.py`). Sahneler ortak bir iskelet üstüne kurulur:
meydan önde, han ve terzi sağda, lonca ve tapınak arkada, avlu solda, sur ya da çit en arkada. Bu iskelet levhaların ve
kadro kartlarının yerini sabit tutar. Yerel görünüş beş girdiden türer:

| Girdi | Ne değiştirir |
|---|---|
| Kültür | Taş mı ahşap mı, kule rengi, sancak, ağaç cinsi, ışığın rengi |
| Enlem | Kuzeyde karlı tepe, soğuk ışık |
| Tür | Şehir: sur, kapı, lonca, kale. Kasaba: çit, az ev. Kervansaray: dört yanı duvarlı avlu |
| Alt tür | Liman: açık deniz ufku, fener. Özgür şehir: kale yok, lonca kuleleri yüksek. Maden: kaya, demirci. Bataklık: sis, eğri ağaç. Nehir: su değirmeni |
| Mallar | Fıçı, saman ve değirmen, çuval, renkli tente |

Kültürlerin dili, kullanıcının benzetmeleri ve coğrafya birlikte:

- **Vadi** (Tyrell gibi): bereketli, sıcak altın ışık, yeşil tepeler, çit ve bahçe, açık taş.
- **Kuzey imparatorluğu** (Nilfgaard gibi): koyu taş, kara kuleler, kızıl sancak, soğuk mor gece. En kuzeyde kar.
- **Sınır halkları**: ahşap çit ve ahşap gözcü kuleleri, eğri ağaçlar, kızıl alacakaranlık.
- **Dağ kabileleri ve madenler**: karlı sırt, kaya, iğne yapraklı orman, mavi ay ışığı.
- **Güney** (Essos gibi): sıcak turuncu-mor ufuk, kum rengi zemin, düz damlı evler, renkli tenteler.
- **Ahit** (Orvahel): soluk taş, ay ışığı, şehrin ortasında dört kuleli büyük tapınak.
- **Göçebeler** (Türkler gibi): bozkır kervansarayı, çadırlar, ateş, geniş amber gök.

## Yazı (görev Y-G14)

Oyunun her yüzeyinde (harita, arayüz, defter, kart) aynı üç yazı yüzü; başka yüz eklenmez.

| Yüz | Nerede | Not |
|---|---|---|
| EB Garamond | gövde: bütün arayüz metni, defter satırları, kart metni | latin-ext ve Kiril; CJK için Noto Serif SC/JP arkasında |
| IM Fell English SC | başlıklar ve harita yazıları (kent adları, `patch_labels.py`) | Türkçe harflerin hepsi var (ölçüldü) |
| Grenze Gotisch | yalnızca vitrin: ana menü başlığı, büyük bölüm başlıkları | gövdede kullanılmaz |

Sans-serif hiçbir yerde yok; motorun kendi yazısı yalnızca son yedek. `test_waybook_theme` yazı klasöründe bu üçü ve
CJK yedekleri dışında yüz bırakmaz.

## Fener motifi (görev Y-G08)

Fener oyunun görsel motifi: karanlıkta taşınan tek sıcak ışık. Rengi `ArtPalette.UI_ACCENT` (kehribar) ailesinden;
başka bir sıcak vurgu icat edilmez.

| Yer | Durum |
|---|---|
| Haritadaki atlı işaretin feneri (8.11, `belgeler/ATLI_ISARET.md`) | var |
| Yoldaki kervan feneri: gece lider figürde ışık halesi (Y-C20, `light_for_night`) | var |
| Menünün ışık kaynağı: kamp ateşi, fener ışığı kısılır (Y-G16 taslağı) | taslak |
| Arayüzün kehribar vurgusu (`UI_ACCENT`: seçili, ana eylem, başlık) | var |
| Logo yanında küçük fener amblemi (ana menü başlığı) | var: Poly Haven `Lantern_01` (CC0), `tools/ui_scenes/lantern_emblem.py` + `lantern_emblem_post.py` -> `data/assets/ui/grim/lantern_emblem.png` |

## Ne yapılmaz

- Dünyanın kendi kurumu olmayan bir şey (cami, minare, kubbe) ufka konmaz (bkz. CLAUDE.md, Art Rules).
- Deri doku yok (oyuncu reddetti).
- Ekran üstünde stres ya da soğuk kenarı yok (oyuncu reddetti). Yalnızca açlık yanığı kalır.
- Ölçeksiz büyütme yok: bir resim gerektiğinden küçükse yeniden render edilir, gerilmez.
