# Wayborne: Ücretsiz Görsel Kaynak Araştırması (CC0 öncelikli)

Araştırma tarihi: 17.10.2026. Lisanslar kaynak sayfalarından okundu; hiçbir dosya indirilmedi.
İşaretler: **[D]** = lisans sayfası açılıp doğrulandı · **[K]** = kısmen doğrulandı / çelişki var · **[?]** = sayfa erişilemedi (403/429), indirmeden önce elle kontrol edin.

---

## 0. Önce okuyun: kritik bulgular

1. **Quaternius lisansı değişti [K].** `quaternius.com/license.html` artık **"Quaternius Asset License (QAL) v1.0"** gösteriyor ("Last updated: 8/28/2026"). Şartları: ticari kullanım serbest, **atıf gerekmiyor**, ama **varlıkları paket/stok dosyası olarak yeniden dağıtmak yasak** (Bölüm 3a), Quaternius'un onayladığını ima etmek yasak (3b). Bölüm 7: değişiklikler geriye işlemez, **"varlığı edindiğiniz andaki sürüm geçerlidir"**. Paket sayfaları (Medieval Village MegaKit, Fantasy Props MegaKit, Ultimate Modular Ruins, Ultimate Animated Animal Pack) hâlâ "CC0" yazıyor. Bu yüzden **elinizdeki eski indirmeler CC0 kalır**. **Yeni indirmeleri QAL kabul edin.** QAL, oyun içinde kullanım için CC0 kadar rahat, ancak "CC0" değil. Yapmanız gereken: her Quaternius indirmesinin tarihini, URL'sini ve sayfanın ekran görüntüsünü `CREDITS_LOG` dosyasına kaydedin.
2. **MakeHuman/MPFB [D]:** çekirdek varlıklar CC0. MPFB'nin kapalı kaynak oyunda kullanımına "Yes" deniyor. Topluluk paketleri **CC0 ve CC-BY karışık**, her paketi tek tek kontrol edin (bkz. §1).
3. **game-icons.net CC BY 3.0 [D].** Atıf zorunlu, CC0 değil.
4. **IM Fell English yalnızca `latin` alt kümesine sahip [D]** (latin-ext yok). Türkçe ğ/ş/İ/ı büyük olasılıkla eksik. Başlık fontu olarak test edin, gövde metni için EB Garamond kullanın (§7).
5. **Kullanılamaz (NC/ND):** David Rumsey Map Collection (CC BY-NC-SA 3.0), Old Book Illustrations sitesinin **metinleri** (CC BY-NC-SA 4.0; görseller değil), BHL'deki telifli eserler (çoğu CC BY-NC-SA), Internet Archive'daki "non-commercial" öğeler, hexaquo.at kodu (CC BY-SA, kopyalamak yerine tekniği referans alın).

---

## 1. MakeHuman/MPFB için saç, başlık ve sakal

**Kaynak:** MakeHuman Community Asset Packs, https://static.makehumancommunity.org/assets/assetpacks.html
**Lisans [D]:** https://static.makehumancommunity.org/about/license.html ("All core assets are shared under Creative Commons, CC0"). MPFB eklentisi GPL, MakeHuman AGPL, ancak bu lisanslar yazılımı kapsar, çıktıyı değil. Kapalı kaynak oyun: https://static.makehumancommunity.org/mpfb/faq/use_in_closed_source.html ("Yes"). CC-BY yükümlülüğü: https://static.makehumancommunity.org/oldsite/faq/what_do_i_need_to_do_when_i_use_a_ccby_asset.html (kapalı kaynak oyunda "about/legal" menüsünde yazar ve kaynak belirtilmeli).

| Paket | Lisans | İşe yarayan içerik |
|---|---|---|
| hair01 | CC0 [D] | 25 saç (low-poly/stilize): örgüler (`elvs_*_braid`), `culturalibre_hair_01/02/05/06`, `o4saken_long01`, `rehmanpolanski_hair_bun_brown`, `cortu_short_messy_hair` |
| hair02, hair03 | **CC-BY** | yüksek poligonlu saçlar, atıf gerekir |
| bodyparts05 | CC0 [D] | sakal ve bıyık: `rehmanpolanski_beard_viking`, `rehmanpolanski_moustache_viking`, `wdg_scruffy_beard`, `grinsegold_beard_sigmund_wip`, `culturalibre_faun_beard` (MPFB2'de "clothes" olarak yüklenir) |
| bodyparts06 | **CC-BY** | ek sakal ve bıyıklar |
| hats01 | CC0 [D] | cloche, newsboy cap, `jujube_bag_on_head` (çuval başlık, haydut/cüzzamlı için uygun) |
| hats02 | CC0 [D] | miğfer: `culturalibre_warrior_helmet`, `grinsegold_corinthian_helmet`, `javherre_..._templar_knight_helmet` (dini sembolü kaldırıp yeniden dokulayın) |
| hats03 | **CC-BY** [D] | `culturalibre_cl_don_quixote_hat`, `elvs_charity_veil1` (başörtüsü/peçe), `elvs_male_flat_cap1`, `mindfront_knitted_hat_01`, `mindfront_sherpa_hat` (kürk kalpağa en yakın aday), `maciekg_wizard_hat`, `elvs_witchy_hallows_hat1` (geniş kenarlı) |
| hats04 | **CC-BY** [D] | `maciekg_horned_helmet`, `maciekg_leather_helmet`, `culturalibre_warrior_helmet_02` |
| suits02 | CC0 [D] | **`monk_robe_hood` / `_hood_down` / `_hood_off` (Donitz)**: kapüşon ve cüppe. Dini kesimi sadeleştirip "kervan pelerini" olarak kullanın. `viking_tunic/pants/boots` (RehmanPolanski) |
| equipment01 | CC0 [D] | `culturalibre_wooden_bow`, `culturalibre_war_hammer`, `joepal_crude_sword`, `o4saken_dagger` |

**Bulunamayanlar:** CC0 türban, sarık, kalpak ve kukuleta (ayrı başlık). **Teknik:** MPFB'nin "MakeClothes" iş akışıyla temel bir başlık modeli yapın: kapüşon kalıbını (`monk_robe_hood`) kesip türban ve sarık için Blender'da torus + Cloth simülasyonu kullanın. Kalpak için silindir + hair particle (kürk) kullanıp 3 açıda render alın. Ink pass'te kürk dokusu zaten tarama çizgisine dönüşür, dolayısıyla düşük detay yeterli. CC-BY paketleri ancak "Credits → Asset Licenses" ekranında yazar adıyla anılacaksa kullanın.

---

## 2. Ortaçağ 3B prop ve yapıları

| Kaynak | Lisans (kontrol edilen sayfa) | Ne için |
|---|---|---|
| **Kenney** https://kenney.nl | CC0 [D], https://kenney.nl/support ("Attribution is not required") | **Castle Kit** (duvar, kule, kapı, köprü; 75 dosya), **Survival Kit** (çadır, kamp ateşi, fıçı; 80), **Fantasy Town Kit** (ortaçağ kasaba ve duvar; 160), **Graveyard Kit** (mezar taşı, çit, kripta; 90). Hepsi CC0 [D] |
| **Quaternius** https://quaternius.com | eski: CC0 / yeni: QAL v1.0 [K] (§0) | **Medieval Village MegaKit** (300+ modüler duvar/çatı/kapı; Standard ücretsiz, %60-70), **Fantasy Props MegaKit** (pazar tezgâhı, sandık, mobilya, alet, yiyecek), **Ultimate Modular Ruins Pack** (90 model; zindan ve yol kenarı harabeleri, CC0 yazıyor), Modular Dungeon Pack, Medieval Weapons |
| **Poly Haven** https://polyhaven.com/models | CC0 [D], https://polyhaven.com/license (logo/render/metin hariç) | API'den doğrulanan modeller: `Lantern_01`, `WoodenTable_01/02/03`, `WoodenChair_01`, `CheeseBox_01` (tahta kutu), `brass_pot_01/02`, `ceramic_pot`, `boulder_01`, `bark_debris_01`. Fotogerçekçi olduklarından ink pass ile uyumlu, yakın plan event kartları için iyi |
| **Poly Pizza** https://poly.pizza | **KARIŞIK** [K] | Quaternius ve Kenney modelleri CC0. "Poly by Google" arşivi çoğunlukla **CC-BY**. Arama sayfasında "Licence" açılır menüsü var (varsayılan "All"), **CC0 seçin** ve her model sayfasındaki lisansı ayrıca okuyun. Örnek arama: `wagon`, `cart`, `Broken Cart` (Quaternius), `Wagon Wheel`, `Barrel` |
| **OpenGameArt** https://opengameart.org | **KARIŞIK** [D] (FAQ): CC0, CC-BY, CC-BY-SA, GPL, OGA-BY | https://opengameart.org/art-search-advanced → License(s): yalnızca **CC0**, Art Type: **3D Art**. CC-BY-SA ve GPL'den kaçının (paylaşım zorunluluğu) |
| **Sketchfab** https://sketchfab.com | **KARIŞIK** [?] | Lisans filtresi sayfası doğrulanamadı. "Downloadable" + lisans filtresinde "CC0" seçin. Standard/Editorial/NC/ND lisanslı modelleri **kullanmayın** |

**Teknik (ortak NPR hattı):** glTF/FBX'i Blender'a alın. Yapılar için yandan görünüş (side-view oyun) + 3/4 açıdan 2 render yeterli. Malzemeleri tek renk (orta gri) Diffuse'a indirin: zaten dokuyu değil, ışık ve gölgeyi kullanacaksınız. Render pass'leri: Depth, Normal, Diffuse Light. Compositor'da Depth+Normal Sobel → mürekkep kontur, ışık değerini 3 eşiğe bölüp 45° / 135° / çapraz tarama dokusu, en sonda kâğıt dokusunu Multiply ile ekleyin. Aynı kamera ve ışık ayarını (tek sıcak fener ışığı, soldan) tüm propler için şablon `.blend` dosyasında sabitleyin.

---

## 3. Rig'li ve animasyonlu hayvanlar

| Hayvan | Kaynak | Lisans |
|---|---|---|
| at, eşek, boğa/öküz, geyik, erkek geyik, kurt, köpek | **Quaternius Ultimate Animated Animal Pack**, https://quaternius.com/packs/ultimateanimatedanimals.html: "12 animals, 12+ animations" (Gallop, Walk, Attack, Death...), FBX/OBJ/Blend/glTF | sayfada CC0 [D], site geneli QAL [K]. Sayfa hayvan adlarını listelemiyor, elinizdeki paketten teyit edin |
| inek, at, lama, domuz, köpek (pug) | **LowPoly Animated Animals**, https://quaternius.itch.io/lowpoly-animated-animals | CC0 [D]. Yorumlarda bazı animasyonların eksik olduğu bildiriliyor |
| **yaban domuzu** | https://opengameart.org/content/boar (Teh_Bucket): rig'li, yürüme + saldırı, .blend, ~1k tris | CC0 [D] |
| kurt | https://opengameart.org/content/3d-wolf (NewDLC): rig'li, FBX/Blend, animasyon belirsiz | CC0 [D] |
| geyik | https://opengameart.org/content/deer-low-poly-rigged (crownjoshua): rig'li, .blend/.obj/.3ds | CC0 [D] |
| ayı, at, köpek, kurt, geyik, aurochs (öküz yerine) | **"CC0 3D Animals/Creatures"** koleksiyonu, https://opengameart.org/content/cc0-3d-animals-creatures ("White Bear (Low poly)", "Rigged Horse", "Dog Low Poly (Rigged)", "Auroch") | koleksiyon CC0. **Her öğenin kendi sayfasını kontrol edin** |

**Teknik:** Hayvanları Blender'da NLA'ya alıp yürüme ve koşu döngülerini **yalnızca yan profilden** (side-view) 8-12 karede render edin. 8 yön gerekmiyor. Ayı ve yaban domuzu için animasyon yoksa basit bir yürüme döngüsünü Rigify ile kendiniz kurun. Kurt ve köpek animasyonları ortak iskelete retarget edilebilir. Hayvan siluetinde mürekkep konturu kalın tutun (2 px), iç detayı yalnızca taramaya bırakın.

---

## 4. Dokular, HDRI, kâğıt ve mürekkep

| Kaynak | Lisans | Ne için |
|---|---|---|
| **Poly Haven** (textures, HDRIs) | CC0 [D] | arama terimleri: dirt, path, mud, rocky, snow, grass, wood planks, fabric, leather (tekil doku adları doğrulanmadı). HDRI: overcast, dusk ve gece sahneleri (fener dışı dolgu ışığı için düşük yoğunlukta) |
| **ambientCG** https://ambientcg.com | CC0 [D], https://docs.ambientcg.com/license/ (atıf gerekmez, önerilen metin var) | kategoriler: Ground, Rock, Snow, Wood, Fabric, Leather, **Paper**, Cardboard. Godot için MIT lisanslı bir ambientCG eklentisi var (Godot Asset Library #1326) |
| **TextureCan** https://www.texturecan.com | CC0 1.0 [D], https://www.texturecan.com/terms/ | **Paper kategorisi**: eski oksitlenmiş gazete kâğıdı (Paper 0027), buruşuk paket kâğıdı (0006), katlanmış kâğıt (0024). **Defter/harita kâğıdı zemini için en iyi CC0 aday** |
| **David Revoy Krita fırçaları** | 2023 kiti: CC0 (BlenderNation ve yazarın arşivi). 2025-01 kiti: metin "CC-0", altbilgi "CC-BY 4.0 + AI derivation prohibited" → **çelişkili [K]** | mürekkep ve kalem fırçaları ile elle tarama. Fırça bir araçtır, çizdiğiniz çıktı sizindir. Çelişki yüzünden 2023 kitini tercih edin |

**Tarama dokuları (hatching TAM):** Hazır ve güvenilir bir CC0 set bulunamadı. Bunları **kendiniz üretin**: Krita veya Inkscape'te 3 ton (seyrek 45°, yoğun 45°, 45°+135° çapraz), 512×512 döşenebilir doku. Gerçek kâğıt doku taraması (kendi kâğıdınızın 600 dpi taraması) en özgün sonucu verir ve lisans riski sıfırdır.

---

## 5. Kamu malı illüstrasyon ve harita referansları

| Kaynak | Lisans durumu | Kullanım |
|---|---|---|
| **Wikimedia Commons** https://commons.wikimedia.org | dosya bazında [D], https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia (garanti yok; her dosyanın etiketini okuyun, PD-Art bazı ülkelerde sorunlu olabilir) | **Carta Marina** (Olaus Magnus, 1539): https://commons.wikimedia.org/wiki/File:Carta_Marina.jpeg, **PD Mark 1.0 [D]**, 5016×3715. Kaynak kurum (James Ford Bell Library) atıf istiyor, gönüllü olarak verin |
| **Old Book Illustrations** https://www.oldbookillustrations.com | görseller: kullanım sınırı yok [D] (https://www.oldbookillustrations.com/terms-of-use/). **Açıklama metinleri CC BY-NC-SA, kopyalamayın**. Toplu indirici yasak | gravür ve ahşap baskı; teknik (Techniques) ve konu (Subjects) gezinmesi var |
| **Biodiversity Heritage Library** | [D] https://about.biodiversitylibrary.org/help/copyright-and-reuse/: PD eserlerde "commercial reuse" serbest; telifli olanlar çoğunlukla CC BY-NC-SA | kurt, ayı, at, geyik gravürleri; anatomi ve duruş referansı. Önerilen atıf: "Image from the Biodiversity Heritage Library. Contributed by [kurum]" |
| **Rijksmuseum** https://data.rijksmuseum.nl/policy | [D] eser başına: PD/CC0 serbest, CC BY 4.0 atıf ister, "restricted" kullanılamaz | Rembrandt dönemi gravürler, harita, kalabalık sahneleri |
| **The Met Open Access** https://github.com/metmuseum/openaccess | veri seti CC0 [D]; görseller koleksiyon sayfasında CC0 ikonu ile işaretli. Politika sayfası 429 döndü [?] | Dürer ahşap baskıları, ortaçağ el yazması |
| **British Library Flickr Commons** | "No known copyright restrictions" [?] (Flickr sayfaları erişilemedi) | 1 milyon kitap illüstrasyonu, süs harfleri, vinyetler |
| **Public Domain Review** https://publicdomainreview.org | [D] iki katmanlı etiket: eser (PD Worldwide...) + dijital kopya ("No Additional Rights", "Non-commercial"...). **Yalnızca "No Additional Rights" olanları kullanın** | seçilmiş gravür, marjinalya ve harita yazıları |
| **Internet Archive** | [D] https://help.archive.org/help/rights/: hak garantisi vermez, öğe bazında kontrol gerekir | 1500-1800 arası basılı kitapların taramaları |
| **David Rumsey Maps** | **CC BY-NC-SA 3.0, KULLANMAYIN** | yalnızca göz atma |
| Rawpixel PD, NGA, Library of Congress, Openverse | [?] lisans sayfaları 403 döndü | indirmeden önce elle kontrol edin. Rawpixel'de yalnızca "CC0/Public Domain" rozetli olanlar uygundur |

**Doğrudan kullanılabilecekler / yalnızca referans olarak kullanılacaklar:**
- *Doğrudan (izleme/kolaj):* PD Mark, CC0 ve Rijks/Met CC0 işaretli görseller. Carta Marina'nın **deniz canavarı, gemi, dalga taraması ve rüzgâr yüzleri** dokuları harita süsleri için izlenebilir. **Ancak gerçek yer adları ve kıyı şekilleri dünyanıza girmesin**: yalnızca süsleri ve hat tekniğini alın, kıyıları kendiniz çizin. Kilise, haç ve aziz figürlerini çıkarın.
- *Yalnızca referans:* BHL hayvan gravürlerinden duruş ve tarama yönünü öğrenin, **elle yeniden çizin** (ince çizgi örüntüsü üretim hattınızın mürekkep stiliyle tutarlı olsun). Dini sahne içeren el yazması marjinalyalarını yalnızca kompozisyon fikri için kullanın.
- Her kullanılan PD görsel için: kaynak URL, kurum, eser, tarih ve lisans etiketi `CREDITS_LOG`'a girsin.

---

## 6. NPR / mürekkep shader ve teknikleri

| Kaynak | Lisans | Not |
|---|---|---|
| **godotshaders.com** | site kuralı [D] https://godotshaders.com/license/: **her shader için ayrı lisans**, CC0, MIT veya GPLv3. Lisans yalnızca kodu kapsar, ekran görüntülerini kapsamaz. **GPLv3 olanlardan kaçının** | |
| Post-Process Outline (Depth/Normal) | **CC0 [D]** https://godotshaders.com/shader/post-process-outline-depth-normal/ | yalnızca Godot 4.x (normal buffer). 3B önizleme ve kontur testi için |
| Advanced Hatching Shader | **CC0 [D]** https://godotshaders.com/shader/advanced-hatching-shader/ | luma'ya göre 3 tarama dokusu (eşik 0.5/0.6) seçer; ekran tabanlı, 4.3 notu var |
| Hatching shader | **MIT [D]** https://godotshaders.com/shader/hatching-shader/ | ışık + Fresnel + gürültülü açı + sinüs çizgi. "Düşük FPS titreme" efekti event kartı animasyonları için güzel. MIT: lisans metnini dağıtıma ekleyin |
| Sobel Outline / Object Outline / 3D Pixel art outline | MIT (arama sonucu, sayfa başlığında yazıyor) [K] | alternatif kontur shader'ları |
| 2D crosshatching (canvas_item) | lisans doğrulanmadı [?] | 2B sprite'a normal map ile tarama. Kullanmadan önce sayfasındaki lisansı okuyun |
| hexaquo.at cross-hatching yazısı | **CC BY-SA** (site altbilgisi) | **kodu kopyalamayın**, RGB kanal başına tarama yönü tekniğini öğrenip kendiniz yazın |
| **Blender Freestyle / Grease Pencil Line Art** | Blender GPL, **"What you create with Blender is your sole property"** [D] https://www.blender.org/about/license/ | Line Art: kontur, kesişim ve kırık çizgileri; bake edilip elle düzeltilebilir. Freestyle: offline render kontur |

**Önerilen hat:** Sprite'ları Blender'da önceden pişirin (offline, hızlı ve deterministik): Line Art/Freestyle kontur + compositor tarama + kâğıt Multiply. Godot'da yalnızca sahne seviyesinde (a) kâğıt dokusu overlay'i, (b) tek fener ışığı için CanvasItem ışık maskesi, (c) kırmızı kanal dışında desatürasyon (kırmızı = kan/kayıp kuralı) çalışsın. Böylece çalışma zamanında GPL koduna ihtiyaç kalmaz.

---

## 7. Arayüz: ikon, çerçeve ve font

| Kaynak | Lisans | Yükümlülük / kullanım |
|---|---|---|
| **game-icons.net** | **CC BY 3.0** [D] https://game-icons.net/about.html | **Atıf zorunlu**: "Icons made by {yazar}. Available on https://game-icons.net". Her ikonun yazarını kaydedin. Siyah siluetler mürekkep stiline çok uygun, kenarlara "ink bleed" filtresi uygulayın |
| **Kenney UI Pack (RPG Expansion)** | CC0 [D] https://kenney.nl/assets/ui-pack-rpg-expansion | 85 dosya: panel, düğme, slider |
| **Kenney Fantasy UI Borders** | CC0 [D] https://kenney.nl/assets/fantasy-ui-borders | 140 dosya: dekoratif çerçeveler; defter sayfası kenarları için yeniden boyayın |
| Süsleme, mühür, defter öğeleri | PD gravürler (§5): Old Book Illustrations "Ornaments and Patterns", BL Flickr vinyetleri | balmumu mühür: kendi tasarımınızı yapın (CC0 kaliteli kaynak bulunamadı) |

**Fontlar (SIL OFL 1.1 [D], https://openfontlicense.org/open-font-license-official-text/):** oyunla birlikte paketlenebilir. **Her kopyada telif bildirimi ve OFL metni bulunmalı** (Koşul 2), font tek başına satılamaz (1). Değiştirirseniz Reserved Font Name kullanılamaz (3). Pratikte `fonts/LICENSES/` klasörüne `OFL.txt` koyup Credits'te listeleyin.

| Font | Alt kümeler (Google Fonts METADATA.pb [D]) | Rol |
|---|---|---|
| IM Fell English (ve DW Pica, Double Pica, French Canon, Great Primer) | **yalnızca latin** | başlık ve süs; Türkçe glifleri test edin, eksikse yalnızca İngilizce başlıkta kullanın |
| **EB Garamond** | latin, latin-ext, **cyrillic(-ext)**, greek | **ana gövde metni**: Türkçe + Rusça kapsar |
| Cormorant Garamond | latin-ext, cyrillic | daha süslü başlık alternatifi |
| Old Standard TT | latin-ext, cyrillic | 19. yy matbaa havası, defter rakamları |
| **Noto Serif SC** | **chinese-simplified**, cyrillic, latin-ext | Çince yerelleştirme. Godot'da fallback font olarak EB Garamond'un arkasına bağlayın |

---

## 8. Capsule, key art ve kısa video

- **Steam capsule kuralları [D]** https://partner.steamgames.com/doc/store/assets/standard: yalnızca sanat + oyun logosu, inceleme alıntısı ya da başka metin yok. Boyutlar: Header 920×430, Small 462×174, Main 1232×706, Vertical 748×896. **Capsule art insan eliyle yapılmalı.** Önerilen: kendi elinizle mürekkep çizim (ya da tutarlılık için oyun içi render üzerine elle boyama). Satın alınan/üretilen AI görsel Steam **Content Survey**'de beyan gerektirir (https://partner.steamgames.com/doc/gettingstarted/contentsurvey, "Pre-Generated" kategorisi; sayfayı ayrıca okuyun [?]).
- **Video araçları (çıktı sizindir):** Blender [D] (Grease Pencil ile kağıt kesik/"cut-out" animasyonu, VSE ile kurgu), Krita [D] ("What you create with Krita is your sole property", çerçeve animasyonu), OpenToonz (Modified BSD [D], MyPaint fırçaları ayrı lisanslı). Kdenlive (GPL) kurgu için kullanılabilir [?].
- **Paper-cut teknik:** Mevcut sprite render'larını parçalara ayırıp (gövde, kol, araba tekerleği) Blender'da düzlemlere doku olarak yapıştırın. Kamera sabit, parallax katmanları (kâğıt kalınlığı gölgesiyle) ve tek fener ışığı kullanın, 12 fps "stop-motion" hissi verin. Harita sahnesi için Carta Marina tarzı kendi haritanız üzerinde mürekkep çizgisinin "akarak" ilerlediği bir Grease Pencil "Build" modifier animasyonu.
- Ses ve müzik bu raporun kapsamı dışında.

---

## 9. Atıf kaydı (CREDITS_LOG)

Her varlık için tek satır (CSV veya TOML): `dosya_yolu | kaynak_adı | yazar | URL | lisans | lisans_sayfası_URL | indirme_tarihi | değişiklik_notu`.
- **CC0/PD:** yasal zorunluluk yok, ama gönüllü teşekkür için yazar adını tutun (Kenney, Quaternius, Poly Haven, ambientCG, MakeHuman katkıcıları: culturalibre, RehmanPolanski, Donitz, WDG, grinsegold, javherre, Teh_Bucket, NewDLC, crownjoshua...).
- **CC-BY / game-icons / MakeHuman CC-BY paketleri / Rijks CC BY:** oyun içi "Credits → Lisanslar" ekranında **zorunlu**: yazar, eser adı, lisans adı + bağlantısı, "değiştirildi" notu.
- **OFL / MIT:** lisans metni dağıtım klasörüne konur.
- **Quaternius:** indirme tarihi ve lisans sayfasının ekran görüntüsü (CC0 ile QAL ayrımı için).

---

## 10. İyi CC0 / ücretsiz-ticari kaynak bulunamayanlar (geliştiriciye kalan)

1. **Türban, sarık, kalpak, kukuleta, başörtüsü** (CC0 MPFB varlığı yok; yalnızca CC-BY `elvs_charity_veil1`, `mindfront_sherpa_hat`). Bunları kendiniz modellemeniz gerekiyor.
2. **Kaliteli rig'li ve animasyonlu ayı**: yalnızca "White Bear (Low poly)" var, rig ve animasyon durumu doğrulanmadı.
3. **Öküz ve eşek**: Quaternius paketinde boğa ve eşek olabilir (doğrulanmadı). Kervan öküzü için boğa modelini yeniden şekillendirmeniz gerekebilir.
4. **Kervan arabası / kapalı vagon** (ortaçağ tarzı, CC0, yüksek kaliteli): yalnızca Quaternius "Cart/Broken Cart" ve Poly by Google (CC-BY) bulundu.
5. **Hazır 3 tonlu tarama doku seti (TAM)** ve **mürekkep lekesi/sıçrama dokuları**: kendiniz üretin.
6. **Balmumu mühür, defter cetveli ve hesap tablosu öğeleri**: kendiniz tasarlayın.
7. **Pazar tezgâhı ve çadır çeşitliliği** (oryantal/bozkır tarzı): Kenney ve Quaternius genelde Batı ortaçağı tarzında.
8. **Capsule ve key art**: insan eliyle yapılmalı (siz veya bir illüstratör).
9. Doğrulanamayanlar: Rawpixel, NGA, LoC, BL Flickr, Met politika sayfası, Sketchfab lisans filtresi. Bunları indirmeden önce elle kontrol edin.
