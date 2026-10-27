# El çizimi süreci

Wayborne'un bütün görsellerini tablette elle yeniden çizmek için baştan sona yol: hangi uygulama, hangi tuval, nasıl
çizilir, nasıl adlandırılır, nereye yüklenir, yüklenince ne olur. Amaç, oyunun görsellerinin AI beyanından olabildiğince
kurtulması ve "içimize sinen" tek bir el.

Üç parça birlikte çalışır:

| Parça | Nerede | Ne |
|---|---|---|
| Takip dosyası | `docs/el_cizimi/el_cizimi_takip.xlsx` | 676 görselin listesi, öncelik, tahmini süre, durum |
| Şablon paketleri | `01_figur.zip` ... `10_efekt.zip` (depoda değil, sana ayrıca gönderilir) | her görselin hizalı referansı, katman haritası, adlı katmanlı PSD |
| Alım aracı | `tools/el_cizimi/al.py` | yüklediğin dosyayı doğrular ve oyuna işler |

Liste tek bir kaynaktan üretilir (`tools/el_cizimi/envanter.py`); oyuna yeni bir görsel girerse oradan Excel'e ve
şablonlara geçer. Eski çalışmalar, kullanılmayan dosyalar ve ham kaynak paketleri listede yok.

## 1. Hazırlık (bir kez)

- **Uygulama:** ibis Paint X (Android). Ücretsiz sürüm yeter; reklamsız sürüm çizim sırasında kesinti olmasın diye iyi.
- **Kalem ayarı:** Ayarlar → Kalem → basınç duyarlılığı açık; "Parmakla çizme"yi kapat, avuç içi reddi açık.
- **Fırçalar (öneri, başlangıç):**
  - Çizgi: *G Pen* ya da *Dip Pen (Hard)*, boyut tuvalin uzun kenarının ~%0,25'i (2048 tuvalde 5-6 px), stabilizatör 3-5.
  - Düz renk: *Doldurma aracı* (Referans: "Kanvas", boşluk kapatma 2) ya da sert *Pen*.
  - Gölge: aynı renk ailesinin bir koyusu, sert kenarlı. Oyunun dili mürekkep + az ton: bir parçada en fazla iki gölge
    tonu, gradyan yok (ışığı ve sisi oyun veriyor).
- **Renk:** oyunun paleti kasvetli ve az doygun (bkz. `docs/ui/STIL_REHBERI.md`, "Kasvet"). İlk birkaç çizimde birlikte
  bir palet sabitleyeceğiz; o palet ibis'e "Renk paleti" olarak kaydedilir.
- **Şablon paketlerini** tablete indir, bir klasöre aç. Her zipte bir `OKU_BENI.txt` var: o paketteki her kimlik, tuvali ve
  katmanları.

## 2. Bir görseli çizmek

### 2.1 Seç

Excel'de **Liste** sayfasını Öncelik'e göre süz. Önce **1**'ler: bugün yapay zekâ üretimi olanlar (ikonlar, olay
resimleri, göstergeler, ekran arka planları); bunlar bitince AI beyanı kalkar. Sonra **2**'ler: oyunda en çok görünenler.
Bir satırın "Önce bitmesi gereken" sütunu doluysa önce o (giysi bedenin üstüne oturur). Başladığında Durum → *Çizgi*.

### 2.2 Tuvali aç

Tuval boyutu Excel'deki **Tuval** sütununda ve şablonun sol üstünde yazar.

- **Çok katmanlı işler** (figür, hayvan, vagon, kapı, çok çeşitli sahne parçaları) için `<KİMLİK>.psd` hazır: Galerim →
  **+** → *PSD içe aktar*. Katmanlar adlı ve doğru sırada gelir; gizli `katman_haritasi` katmanı hangi parçanın hangi
  katmana gittiğini renkle gösterir. PSD açılmazsa: *Yeni tuval → Özel boyut*, katmanları Excel'in **Katman adları**
  sayfasındaki adlarla elle aç.
- **Tek katmanlı işler** için: *Yeni tuval → Özel boyut* (Tuval sütunundaki boyut).
- Uygulama bu boyutu açmazsa aynı **oranda** daha küçük bir tuval de olur (en az yarısı); araç ölçekler. Oran şaşarsa
  dosya geri çevrilir.

### 2.3 Referansı koy

1. Katman penceresi → *Fotoğraf ekle* → `<KİMLİK>_ref.jpg`. "Tuvale sığdır"ı seç: şablon tuvalle aynı boyutta, tam oturur.
2. Bu katmanı **en alta** al, opaklığı **%35**, kilitle. Adını `referans` yap (araç bu adı yok sayar).
3. Referanstaki işaretler kılavuzdur, uyulması gereken çizgilerdir:
   - **Mavi yatay çizgi:** yer. Ayak, tekerlek, kapı tabanı bunun üstünde.
   - **Mavi halkalar (figür):** eklemler (omuz, dirsek, el, kalça, diz, bilek, boyun). Oyun kolu ve bacağı bu
     noktalardan büker; eklem kayarsa diz yanlış yerden kırılır.
   - **Kırmızı artılar (eşya):** dönme ve oturma noktaları (teker göbeği, arabacı koltuğu, branda tabanı).
   - **Renkli çerçeveler (eşya):** her parçanın sınırı. Parça çerçevesinden taşarsa taşan kısım kesilir.
   - **Mavi hatlar (kasaba):** tıklama alanları (pazar, han, lonca...). Binaların dış hatları bu çizgilerde kalsın.
   - **Kırmızı dikey kenarlar (yol):** sol kenar sağ kenara bağlanır; yol ekranda döşenerek sonsuz akar.
   - **Paftanın kenarları (harita):** komşu paftayla birleşir; kıyı, nehir ve yol kenarda kesilmeden geçsin.

### 2.4 Çiz

- **Her parça kendi katmanında.** Katman adı şablondakiyle aynı kalsın. Bir parçanın çizgisini ve rengini ayrı tutmak
  istersen o adla bir **klasör** aç, içine istediğin kadar katman koy: araç klasörü tek katman sayar.
- **Çizgi önce** (Durum → *Çizgi*), sonra **düz renk çizginin altına** (Durum → *Renk*), sonra az gölge.
- **Saydamlık:** arka planı boyama. PNG ile teslim edilen ikon, eşya ve sahne parçalarının çevresi saydam kalır.
  Tam ekran resimler (kasaba, olay, ekran arka planı, harita) baştan sona boyanır.
- **Gri ile çizilecekler:** beden, saç ve temel takım (atlet, büstiyer, şort) gri tonlarla çizilir; oyun ten ve saç
  rengini kendisi çarpar. Renkli çizilirse her ten ve saç o rengin üstüne biner. Bulutlar da gri.
- **Lore'un iki sınırı:** dini simge yok (mezar, sunak, kilise: taş, bez, adak; haç, hilal yok), uzak şehirde kubbe ve
  minare yok (sur, kapı, ambar).

### 2.5 Teslim et

- Bitince `referans` ve `katman_haritasi` katmanlarını **gizle** (silmen de olur).
- **Çok katmanlı:** Paylaş → **PSD** olarak kaydet. **Tek katmanlı:** Paylaş → **PNG (saydam)**.
- **Dosya adı = kimlik**, birebir: `KYF-peasant_shirt-E.psd`, `ARY-item_silk.png`, `KSB-akavan-gunduz.png`. Büyük-küçük
  harf ve tire aynı.
- Durum → *Bitti*.

PSD dışa aktaramıyorsan her katmanı ayrı PNG olarak da verebilirsin: `<KİMLİK>__<katman>.png`
(örnek `ESY-covered_wagon__teker_on.png`). Hepsi aynı tuval boyutunda olmalı.

## 3. Yükleme (GitHub, tablet tarayıcısından)

GitHub'ın Android uygulaması dosya yükleyemiyor; tarayıcı kullan (Chrome).

1. `github.com/ulubatuhan/wayborne` aç, sağ üstten **masaüstü sitesi**ni işaretle.
2. Dal seçicisinden **Wayborne**'u seç.
3. `art_source/el_cizimi/gelen/` klasörüne gir.
4. **Add file → Upload files** → dosyaları seç (birden çok olabilir). Bir dosya en fazla 25 MB; PSD büyükse katmanları
   `__katman.png` olarak ver.
5. Commit mesajı: `El çizimi: <KİMLİK>` (birden çoksa `El çizimi: 5 ikon`). **Commit directly to the Wayborne branch**.
6. Bana yaz: "gelen'e yükledim". İstersen kendi Excel'ini de aynı klasöre `el_cizimi_takip.xlsx` adıyla yükle; senin
   girdilerin esas alınır.
7. Durum → *Yüklendi*.

## 4. Yükleyince ne oluyor

Ben `python3 -I tools/el_cizimi/al.py` çalıştırırım. Araç:

1. dosya adından kimliği okur, envanterde bulamazsa geri çevirir,
2. tuval oranını, katman adlarını, boşluğu ve saydamlığı denetler (hata ve uyarıları sana iletirim),
3. çizimi şablonun tuvaline ölçekler, `art_source/el_cizimi/islenmis/<KİMLİK>/<katman>.png` olarak saklar (el çiziminin
   kalıcı kaynağı; oyun dosyaları istenirse hep buradan yeniden üretilir),
4. türüne göre oyuna işler:

| Tür | Oyuna nasıl girer |
|---|---|
| Tek resim (ikon, olay resmi, gösterge, ekran arka planı, kasaba resmi) | oyunun kendi boyutuna küçültülür, aynı dosyanın yerine |
| Yol şeridi | küçültülür, sol-sağ kenarı birbirine karıştırılır (dikişsiz döşenir) |
| Eşya, kapı | her katman kendi çerçevesinden kesilir; dönme noktaları ve ölçek değişmez |
| Hayvan | üç katman deriye yazılır; oyun aynı ızgarayla büker, kod değişmez |
| Harita paftası | 2x2 karo; üst seviye karolar ve küçük seviyeler yeniden üretilir |
| Figür | kemik hattına girer (bkz. 5) |
| Yeni parça (Excel: Koda bağlantı gerekir) | saklanır; oyuna bağlanması ayrı bir kod işi, ben yaparım |

5. aslını `art_source/el_cizimi/arsiv/`e taşır, Excel'de durumu **Oyunda** yapar,
6. ilgili ekranın **gerçek görüntüsünü** alırım ve sana gösteririm; görüntüde doğru görünmeyen iş "oyunda" sayılmaz.

## 5. Figürler: tek çizim, oyun büker

Bir kişi oyunda 159 karede görünüyor (yürüyüş, binicilik, saldırılar, isabet, düşüş, oturma...), altı beden çeşidinde ve
63 giysiyle. Hepsini kare kare çizmek imkânsız; onun yerine:

- **Yalnızca orta kilolu erkek ve kadın beden** çizilir, **yalnızca rölanti pozunda**, beş derinlik katmanında
  (`arka_kol`, `arka_bacak`, `govde`, `on_bacak`, `on_kol`).
- Her giysi ve saç da aynı pozda, aynı beş katmanda, **bedenin üstüne oturarak** çizilir (beden şablonda soluk durur;
  giysi katmanına beden çizilmez).
- Oyun her katmanı kemik ağırlıklarıyla büker: kol omuzdan ve dirsekten, bacak kalçadan ve dizden döner. Giysi aynı
  kemiklere bağlı olduğu için bedenle birlikte hareket eder.
- İnce ve iri bedenler orta bedenden türetilir.

Bükülerek çalışabilmesi için figür çizerken:

- **Eklemler yerinde:** omuz, dirsek, kalça ve diz şablonun halkalarında. Kol ve bacak referanstaki gibi düz; dirseği
  bükük çizilmiş bir kol açılırken yamulur.
- **Gizlenen yeri de çiz:** uzak kol ve uzak bacak gövdenin arkasında kalsa bile tam çizilir (yürürken görünür). Kolun
  altında kalan gövde, koltuk altı, kalçanın arkası boş bırakılmaz.
- **Eklemde bindirme:** üst kolun ucu dirseğin biraz altına, önkolun başı dirseğin biraz üstüne uzansın; bükülünce
  arada boşluk açılmasın. Aynısı diz ve omuz için.
- **Etek, elbise, cüppe tek parça:** bu yedi giysinin (uzun etek, katlı etek, iki elbise, üç cüppe) altıncı bir `etek`
  katmanı var, iki bacağın da önünde. Giysinin bacakları örten bütün kısmı oraya çizilir, bacak katmanlarına bölünmez;
  bölünen etek adım açılınca ortadan yarılıyor (pilotta görüldü). Oyun eteğin önünü öndeki uyluğa, arkasını arkadakine
  bağlar; etek adımla açılır.
- **Kumaş dökümü sade:** büyük kıvrımlar ve gölge ceplerini oyun bükerken sürükler; düz renk ve az çizgi en iyi bükülür.

Pilot sonucu ve bunun neden işe yaradığı: `docs/el_cizimi/pilot/` (bkz. `PILOT.md`).

## 6. İlerleme ve AI beyanı

- Excel'in **Özet** sayfası kategori ve öncelik başına ilerlemeyi, kalan tahmini saati ve kalan AI kaynaklı görsel
  sayısını formülle hesaplar.
- Öncelik 1 bitince (`AI kaynaklı kalan` = 0) `AI_DISCLOSURE.md`'deki sanat maddesi yeniden yazılır: AI görseller
  yerine "el çizimi, render ve prosedürel".
- Takip dosyası ve şablonlar yeniden üretilebilir:
  `python3 -I tools/el_cizimi/sablon_uret.py <klasör>`, `python3 -I tools/el_cizimi/takip_excel.py`
  (senin girdilerin korunur).

## 7. Sık karşılaşılanlar

| Durum | Ne yap |
|---|---|
| "tuval oranı şablonla aynı değil" | Tuvali Excel'deki boyutla yeniden aç, çizimi *Tuval → Yeniden boyutlandır* ile değil, *Taşı/Ölçekle* ile oturt |
| "eksik katman" | Katman adını kontrol et (Türkçe karakter yok: `govde`, `on_kol`) |
| "saydam olması gereken resim tamamen opak" | Kâğıt/arka plan katmanını gizle ya da sil |
| "katmanın bir kısmı çerçevesinin dışında kaldı" | O parçayı şablondaki renkli çerçevenin içine çek |
| PSD 25 MB'tan büyük | Katmanları `<KİMLİK>__<katman>.png` olarak ayrı yükle |
