# Oyuncu profilleri: kim oynuyor ve keyif alıyor mu? (2026-11-05)

Kullanıcı isteği: *"birkaç oyuncu profili oluştur... oyunu farklı açılardan
deneyimle... bu profillerin oyundan ne kadar keyif alacağını ve neleri eksik
bulacağını sapta... akademik araştırma yap ve gerekirse kendin yeni bir
çalışma üret."*

Araç: `tests/simulate_personas.gd` (beş profil × üç koşu × yirmi dört sefer,
artı bir ablasyon çalışması). Ekran doğrulaması:
`tests/screenshot_persona_gate.gd`.

---

## 1. Yöntem ve kaynakları

### 1.1 Profilleri neye dayandırdım

| kaynak | ne verdi | **sınırı** |
|---|---|---|
| **Quantic Foundry, 12 güdü / 6 küme** (Eylem, Sosyal, Ustalık, Başarı, Dalma, Yaratıcılık) | Profillerin neye değer verdiğini kümeleyen çerçeve; ~1.75M katılımcı | Bağımsız hakemli doğrulaması yok, veri kapalı; ayrıca kaçış (escapism) güdüsü modelden çıkarılmış. Burada **ölçek olarak değil**, ağırlıkları gerekçelendiren çerçeve olarak kullanıldı |
| **Öz-belirleme kuramı / PENS** (Ryan, Rigby, Przybylski 2006) | Yetkinlik · özerklik · ilişkililik: memnuniyetin üç ayağı | Johnson, Gardner, Perry (2018) yapıyı **kısmen** doğruladı: yetkinlik ile "sezgisel kontrol" tek yapı çıktı. Yani "yetkinlik" ölçümü saf değil |
| **BrainHex / Bartle eleştirisi** (Tondello ve ark.) | Yedi arketip veriye bakınca **üçe** iniyor: eylem · estetik · hedef; Bartle'ın dört tipi tip kuramından geliyor | Bu yüzden burada **"oyuncu tipi" iddiası yok.** Beş profil bir sınıflandırma değil, Wayborne'un kendi karar noktalarına göre seçilmiş tasarım araçları |
| **Prosedürel persona** (Holmgård, Green, Liapis, Togelius) | Personayı **fayda fonksiyonu** olarak yazıp oyunda davranan bir etmene çevirme yöntemi - bu aracın tam olarak yaptığı şey | Etmen insan değil: insanın yorulmasını, sıkılmasını, yanlış okumasını taklit etmez |
| **Gelişen persona** (Ariyurek, Surer, Betin-Can) | Sabit persona oyuncunun zamanla değişmesini kaçırır | Tek makalelik bir iddia; burada **ölçülerek** sınandı (bölüm 3.3) |

**Dürüst uyarı.** Literatürde persona tahminlerinin gerçek oyuncu
davranışıyla örtüştüğünü gösteren büyük bir ampirik çalışma bulamadım. Yani
bu rapor "oyuncular şöyle yapacak" demiyor; **"şu değerlere sahip bir
etmen şu duvara çarpıyor"** diyor. Duvar gerçek, etmen bir model.

### 1.2 Kendi ürettiğim çalışma

İki parça literatürde hazır değildi, bu yüzden kuruldu:

1. **Özerkliğin gözlemlenebilir ölçümü.** PENS özerkliği ankete sorar.
   Burada kartta **gerçekten açık olan seçenek sayısı** sayılıyor
   (`choice.is_available(context)`), ve kaç kartın tek seçenekle geldiği
   (`zorunlu`). Anket sormadan ölçülebilen en dürüst özerklik göstergesi.
2. **Ablasyon çalışması** (bölüm 3.4). Profil tablosu "Hikâyeci üçüncü
   seferde ölüyor" diyor ama **neden** demiyor: üç davranış aynı anda
   değişiyor. Üçünü tek tek çevirip ayırdım. Bu, raporun en keskin
   bulgusunu veren parça.

### 1.3 Ölçüm aracının kendisiyle ilgili üç düzeltme

*Bir rapor şaşırtıcıysa önce ölçüm aracından şüphelen* kuralı bu turda üç
kez işledi - üçü de rapora girmeden yakalandı:

- **İlk sürüm elle besliyordu** (`change_provisions`) ve 24 seferde 292 aç
  gün + moral 100 çıkarıyordu; imkânsız bir çift. Açlığın bedelini, ölümü ve
  morali `apply_meal_distribution` uyguluyor; elle beslemek o kapıyı
  atlıyordu. (P8'de de aynı ders: ekranın kapılarından geçmeyen bir
  simülatör var olmayan bir oyunu ölçer.)
- **"Aç gün" aslında bir karardı.** `crew_hungry`, PARTY_ONLY kipinde her
  gün doğrudur - tayfayı beslememek bir başarısızlık değil bir *tercih*.
  Onu acı sayınca Hayatta Kalan 300 günün 249'unda "aç" görünüyordu. Artık
  gerçek açlık (`hungry_names`) ile ihmal ayrı sayılıyor.
- **Ölen kervan on dokuz sefer daha "koşuyordu".** `is_run_over()`
  sorulmuyordu; ortalamalar boş seferlerle sulanıyordu. İz kipi
  (`--iz <profil>`) bunu tek bakışta gösterdi.

---

## 2. Profiller

Her profil bir **fayda fonksiyonu**dur: olay kartının seçeneklerini kendi
ağırlık tablosuyla puanlar, yolunu kendi ölçütüne göre seçer, erzağı kendi
güvenlik payıyla alır.

| profil | güdü kümesi | neye bakar | pazarlık | tayfayı besler | planlayıcıyı okur |
|---|---|---|---|---|---|
| **Tüccar** | Ustalık-Strateji | keseye; riski fiyatlar | evet | hayır | evet |
| **Hikâyeci** | Dalma-Hikâye | deftere; ize bakar, sayıya değil | hayır | **evet** | **hayır** |
| **Hayatta Kalan** | Ustalık-Meydan okuma | erzağa ve partiye; zorluğu arar | evet | hayır | evet |
| **Tamamlayıcı** | Başarı-Tamamlama | listeye: her kontrat, her şehir | evet | hayır | evet |
| **Merhametli** | İlişkililik | morale ve kişilere; ucuz çözümü seçmez | hayır | **evet** | **hayır** |

"Planlayıcıyı okur" bir karakter özelliği değil bir **ölçüm değişkeni**:
oyunun sayıya bakmayan oyuncuyu cezalandırıp cezalandırmadığını ayırmak
için var.

---

## 3. Ölçümler

### 3.1 Ana tablo (5 profil × 3 koşu × 24 sefer hedefi)

```
profil            kip     keyif  sefer  bitti  özerk  yetkin  teslim  şehir  kart  açgün  ihmal  ölüm
Tüccar            sabit    53.3   24.0      -   2.43    0.42    23.3    5.7  13.0    0.0   73.3   0.0
Tüccar            gelişen   53.3   24.0      -   2.43    0.42    23.3    5.7  13.0    0.0   73.3   0.0
Hikâyeci          sabit    18.5    3.3    3.3   2.06    0.48     1.0    4.0  10.3   36.3   36.3   3.0
Hikâyeci          gelişen   18.5    3.3    3.3   2.06    0.48     1.0    4.0  10.3   36.3   36.3   3.0
Hayatta Kalan     sabit     0.0   18.7   10.3   2.08    0.61    13.0    9.0  30.3   82.0  249.3   1.7
Hayatta Kalan     gelişen    4.1   18.7   10.3   2.16    0.59    12.3    8.7  30.3   66.3  231.7   1.7
Tamamlayıcı       sabit    17.9    9.3    9.3   2.14    0.80     6.0    8.3  23.7   49.3  159.7   2.7
Tamamlayıcı       gelişen   38.8   11.0    2.7   2.16    0.82    10.7   10.0  24.3   34.0  159.7   1.7
Merhametli        sabit    12.5    3.0    3.0   2.19    0.64     0.0    3.3  11.3   38.3   38.3   3.0
Merhametli        gelişen   13.1    3.0    3.0   2.21    0.64     0.0    3.3  11.0   38.0   38.0   3.0
```

`bitti` = kervanın öldüğü sefer ("-": yirmi dört seferi tamamladı).
`keyif` = profilin kendi güdü ağırlıklarıyla kurulmuş bileşke, 0-100.
**Bu bir anket puanı değil**: profilin değer verdiği şeylerin ne kadar
gerçekleştiğinin özeti. Profiller arası karşılaştırma için anlamlı,
"oyun şu kadar eğlenceli" iddiası için değil.

### 3.2 En büyük bulgu: yalnız bir profil oyunu bitiriyor

**Tüccar 24 seferin 24'ünü tamamlıyor; Hikâyeci ve Merhametli üçüncü
seferde ölüyor.** Tamamlayıcı dokuzuncu, Hayatta Kalan onuncu civarında.

Bu bir zorluk meselesi değil, bir **kip** meselesi: oyun şu an yalnız
optimize eden oyuncuyu ödüllendiriyor. Kıtlık oyununun istediği his
("yokluk içinde kıvranmak") sağlanıyor - ama kıvranma payı eşit değil:
hesap yapan kıvranıyor, hesap yapmayan **ölüyor**.

Yan bulgu: Tüccar'ın bile `yetkin` değeri 0.42 (seferlerin %42'sinde kese
büyüyor) ve moral dibi 0.7. Kazanan bile rahat değil - bu **tasarım
gereği doğru**.

### 3.3 Gelişen persona gerçekten fark yaratıyor mu?

Ariyurek ve ark.'nın iddiası ölçüldü. Sonuç **karışık ve dürüstçe zayıf**:

- Tüccar ve Hikâyeci'de **hiçbir fark yok** - uyarlama tetiği (vagon kaybı,
  ölüm, eksi kese) ya hiç gelmiyor ya da ölüm zaten her şeyi bitiriyor.
- Tamamlayıcı'da **belirgin fark**: keyif 17.9 → 38.8, aç gün 49 → 34,
  ölüm 2.7 → 1.7. Canı yanınca riskten kaçan oyuncu daha uzun yaşıyor.
- Hayatta Kalan'da küçük fark (0 → 4.1).

Yani: **gelişen persona yalnız hayatta kalabilen profillerde ölçülebiliyor.**
Üçüncü seferde ölen bir profilin gelişecek zamanı yok. Bu, makalenin
iddiasına karşı değil ama onu sınırlandırıyor - ve bulgu, aracın kendisinden
çok oyun hakkında konuşuyor.

### 3.4 Ablasyon: hangi davranış öldürüyor?

Hikâyeci'nin üç davranışı tek tek çevrildi (4 koşu, tek değişkenli):

```
değişiklik                 sefer  açgün  ölüm  teslim  kese
taban (Hikâyeci)            3.0   39.5   3.2     0.8     31
reads_planner = true        3.0   39.5   3.2     0.8     31
haggle = true               3.0   42.0   3.2     0.5    -14
feed_all = false           11.2   65.0   3.0     3.8      4
üçü birden (Tüccar gibi)    8.5   37.0   2.5     3.0     32
```

Üç sonuç, üçü de beklenmedik:

1. **Tayfayı beslemek tek başına kervanı öldürüyor.** `feed_all = false`
   dayanıklılığı 3 seferden 11.2'ye çıkarıyor - neredeyse dört katı.
   Öbür iki değişken yanında bu bir **düğme değil bir duvar**.
2. **Planlayıcıyı okumak hiçbir şey değiştirmiyor.** Çünkü kese ve raf
   hiçbir yola yetmiyorsa ceza bütün yollara eşit biniyor ve sıralama
   değişmiyor. *Uyarı var ama yönlendirecek bir seçenek yok* - bölüm 4'ün
   konusu.
3. **Pazarlık etmek işe yaramıyor** (3.0 → 3.0, kese 31 → −14). P1'de
   pazarlığın tavanını %45'ten %15'e indirdik; para basma noktası kapandı,
   ama **zordaki oyuncu için bir kurtuluş yolu da kalmadı**. Bu, P1'in
   bilerek ödediği bedelin ölçülmüş hâli - geri alınması önerilmiyor,
   ama bilinmesi gerekiyor.

---

## 4. Ekranda doğrulama (Y-K01): uyarı var mı?

Simülatör sayıyı görür, oyuncu ekranı görür. Ölümcül ilk sefer gerçek
planlayıcı ekranında fotoğraflandı (`tests/screenshot_persona_gate.gd`;
Orbeyan Kervansarayı → Selvicar, 35 gün, açılış kervanı).

**Beklentim yanlış çıktı: ekran açıkça uyarıyor.** Planlayıcıda yazanlar:

- `Gerekli erzak: 111 birim` / `Envanterdeki erzak: 20 birim`
- `Eksik erzak: 91 birim (364 GG)`
- `Bu şehirde yalnız 69 erzak var.` *(P5'in satırı, çalışıyor)*
- **`Kervan bu yolda 31 gün aç kalır: moral düşer, stres birikir. Karar senin.`**
- Düğme: `Erzak eksik — yine de yola çık`

Yani bilgi eksik değil. **Eksik olan şey bedelin ölçeği.** Ekran "moral
düşer, stres birikir" diyor; bu, atlatılabilir bir rahatsızlık gibi okunuyor.
Ölçüm ise aynı kararın kervanı **üç sefer içinde bitirdiğini** söylüyor.
Uyarının kendisi değil, **şiddeti** yanlış.

Karşılaştırma için kısa yol: aynı kervan, aynı gün, 6 günlük yol →
`Gerekli erzak: 21 birim`, elde 20. Yani oyun aslında doğru ilk hamleyi
sunuyor; yalnız yanlış hamlenin ne kadar yanlış olduğunu söylemiyor.

---

## 5. Profil profil: neyden keyif alır, neyi eksik bulur

### Tüccar — oyunun şu an hizmet ettiği oyuncu
- **Keyif:** fiyat defteri, pazar katmanları, kontrat seçimi, takasın
  kıtlıkla büyüyen payı. 24 seferi bitiriyor, itibar 46'ya çıkıyor.
- **Eksik bulacağı:** `yetkin` 0.42 - çabasının yarısı karşılıksız.
  Özerkliği en yüksek (2.43) ve zorunlu kart oranı sıfır: karar bolluğu
  var. Asıl şikâyeti "kazandığımı göremiyorum" olur; kese yatay
  (P8'in kasıtlı sonucu) ve zenginleşme yok.

### Hikâyeci — oyunun şu an kaybettiği oyuncu
- **Keyif:** sefer başına 13.9 defter satırı, 24 seferde 38 farklı kart
  görecek kadar çeşit. Kart havuzu bu profile cömert.
- **Eksik bulacağı:** **üçüncü seferde ölüyor.** Anlatıyı takip etmek için
  gereken şey (hayatta kalmak) onun oynamak istediği şeyle (herkesi
  beslemek, sayıya bakmamak) çelişiyor. Ölmeden önce 1 kontrat teslim
  ediyor ve 4 şehir görüyor - hikâyenin başlamasına bile vakit yok.

### Hayatta Kalan — en uzun süre kıvranan
- **Keyif:** 30 farklı kart, 18.7 sefer, sürekli bir eşiğin kıyısında
  durma hissi. `yetkin` 0.61: emeğinin karşılığını en çok bu profil
  görüyor.
- **Eksik bulacağı:** 82 aç gün ve yine de ölüm. Zorluğu arıyor ama
  zorluğun *okunabilir* olmasını da ister; moral dibi 0 ve ölümün hangi
  karardan geldiği ekranda izlenemiyor.

### Tamamlayıcı — gelişmeye en açık profil
- **Keyif:** 20.5 defter satırı/sefer, 24 farklı kart, 10 şehir.
  Uyarlanınca keyif iki katına çıkıyor (17.9 → 38.8): **ders alabilen
  oyuncu ödüllendiriliyor**, oyunun öğretme kanalı çalışıyor.
- **Eksik bulacağı:** liste yok. Kaç kart var, kaç şehir var, kaç kontrat
  türü var - hiçbiri sayılabilir değil. Tamamlanacak bir şey görmeden
  tamamlayamaz.

### Merhametli — en hızlı cezalandırılan
- **Keyif:** özerkliği en yüksek ikinci (2.19), zorunlu kart oranı en
  düşük (0.06): ahlaki karar alanı gerçekten açık. Kıtlık kartlarının
  "doğru cevabı yok" tasarımı bu profile tam oturuyor.
- **Eksik bulacağı:** üç sefer. Merhamet (herkesi beslemek) oyunun en
  pahalı tercihi ve bunu önceden görmenin yolu yok. 0 kontrat teslim
  ediyor - yani oyunun ana döngüsüne hiç giremiyor.

---

## 6. Öneriler

Önceliklendirilmiş; her biri ölçümden çıkıyor ve **hiçbiri bir sistemi
kesmiyor** (derinleşme, asla sadeleştirme).

### Ö1. Uyarının şiddeti gerçeğe uysun · S · *en yüksek öncelik*
Planlayıcıdaki `Kervan bu yolda 31 gün aç kalır: moral düşer, stres
birikir` satırı bedeli küçültüyor. Aç gün sayısı
`STARVATION_HP_LOSS_START_DAY`'i geçiyorsa cümle **ölümü adıyla** ansın:
*"Bu yolda N gün aç kalınır. Dördüncü günden sonra açlık öldürmeye başlar."*
Yeni mekanik yok, var olan eşiği söylemek.

### Ö2. Sofra kipi bir duvar değil, görünür bir karar olsun · M
Ablasyonun en sert sonucu: `feed_all` tek başına dayanıklılığı 3→11 sefer
değiştiriyor. Bu ağırlıkta bir karar bir alt menüde durmamalı. Öneri:
ilk sefere çıkmadan önce planlayıcıda sofra kipi **görünsün** ve her kipin
günlük erzak maliyeti yan yana yazılsın ("Herkes: 7/gün · Yalnız parti:
3/gün"). Karar yine oyuncunun, ama kör değil.

### Ö3. Zordaki oyuncuya bir çıkış · M
Pazarlığın tavanı %15'e inince (P1) zordaki oyuncunun elinde hiçbir
kurtarma kolu kalmadı - ablasyonda `haggle = true` hiçbir şey değiştirmiyor.
Pazarlığı geri büyütmek **önerilmiyor** (para basma noktası oydu); yerine
kıtlığa uygun bir çıkış: aç bir kervan şehirde **gündelik iş** yapabilsin
(bir gün çalış, bir öğün kazan). Zaman ödenir, para değil - kıtlık kipini
bozmaz.

### Ö4. Tamamlayıcıya sayılabilir bir şey · S
Defterde "gördüğün kart / toplam", "gezdiğin yer / toplam", "teslim edilen
kontrat" sayaçları. Veri zaten var (`visited_location_ids`,
`EventCatalog`, `contracts_delivered`); yalnız gösterilmiyor. Bu profilin
keyfi uyarlanınca iki katına çıkıyor - sayaç o öğrenmeyi hızlandırır.

### Ö5. Ölümün nedeni defterde okunabilsin · S
Hayatta Kalan ve Merhametli ölüyor ama hangi kararın öldürdüğü görünmüyor.
Defterin ölüm satırı zaten `cause` taşıyor (`LEDGER_CAUSE_STARVED`);
ölümden sonraki özette **son üç karar** gösterilsin. Oyuncunun hatayı
öğrenmesi için gereken tek şey bu.

### Ö6. İlk seferin güvenli yolu işaretlensin · S
Oyun doğru ilk hamleyi zaten sunuyor (6 günlük yol, 21 erzak) ama
ayırt etmiyor. Haritada ilk seferde erzağın yettiği yollar farklı
çizilsin - bir el tutma değil, bir **okunabilirlik** düzeltmesi.

### Ö7. Tüccar'a "kazandım" anı · M
`yetkin` 0.42 ve kese yatay: kazanç hissi yok. Para ile değil **ad** ile
ödüllendirilsin - bölgesel itibar eşikleri geçildiğinde deftere ve şehre
yazılan bir satır (P14'ün altyapısı hazır). Kâr tavanı korunur, emeğin
karşılığı görünür olur.

---

## 7. Bu raporun sınırları

- Beş etmen, beş oyuncu değil. İnsan yorulur, sıkılır, yanlış okur, menüyü
  bulamaz - hiçbiri modellenmedi.
- `keyif` bileşkesi benim kurduğum bir ağırlıklandırma; profiller arası
  karşılaştırma için anlamlı, mutlak bir eğlence ölçüsü değil.
- Üçer koşu azdır. Yön güçlü (3 sefere karşı 24 sefer gürültü değil), ama
  ondalıklar oynak.
- Savaş kartları etmen tarafından oynanmıyor (`TRIGGER_COMBAT` otomatik
  çözülüyor); savaş odaklı bir profil bu araçla ölçülemez.
- Profiller **yolu** oynuyor: taverna, lonca sohbeti, karakter ekranı ve
  şehrin kişileriyle bağ bu koşuda yok. Dalma ve ilişkililik ölçümleri bu
  yüzden olduğundan düşük.
