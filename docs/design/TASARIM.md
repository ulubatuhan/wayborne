# Wayborne: tasarım belgesi

> **Durum:** vaat ve sütunlar öneri, kullanıcı onayı bekliyor (görevler Y-A01, Y-A02). Onaylanınca bu kutu ve
> CLAUDE.md başındaki kutu birlikte kalkar.

## Vaat

**Bir kervanı kuşaklar boyu yolda tut. Her karar yola bir iz, her ölüm deftere bir satır olur.**

Bu cümle her yeni özelliğin sınavıdır. Bir sistem yola ya da deftere iz bırakmıyorsa, neden var olduğu sorulur.

## Dört sütun

Sütunların üstünde kullanıcının ilkesi durur: **derinleşme, asla sadeleştirme.** Bir sistem sadeleştirerek çözülmez.
Ölçülmüş ve korunan sistemler kesilmez: beş kapasite yolu, hub yürüyüş alanı, kıyafet statları, haydut büyücü, beden
statları.

| Sütun | Ne demek | Bugün oyunda nerede |
|---|---|---|
| **Yol yaşar** | Yol bir bekleme ekranı değil. Hava, arazi, işaretler, karşılaşmalar ve kamp yolu doldurur. Yol yeterince dolu olunca hızlandırma (1.5x, 3x) kalkar. | Haritadan gelen arazi ve duraklar, yol işaretleri, dikkat bölgeleri, kamp, olay kartları, yol kontrol paneli |
| **İnsanlar aşınır** | Kervandakiler bir kaynak değil, kişi. Stres, açlık, kırgınlık ve yara kalıcı iz bırakır. Ölüm gerçek. | Kişi başına stres, kırgınlıklar, açlıktan ölüm, Ölümün Kıyısı, kırılma huyları |
| **Defter unutmaz** | Kervanın adı liderden uzun yaşar. Ölen ve ayrılan defterde çizili kalır; dünya geçmişi hatırlar. | Soy (kuşak), veraset sahnesi, defter, olayların defteri okuması |
| **Ticaret bilgi oyunudur** | Para fiyat farkından değil, bilgiden kazanılır: hangi şehir ne ister, hangi yol kapalı, hangi söylenti doğru. | Pazar, arz ve talep, piyasa şokları, kontratlar, taverna söylentisi, yol durumu |

Her yeni görev, hizmet ettiği sütunu adıyla yazar (`TODO/gorevler/00_kurallar.md`, görev şablonu).

## Çekirdek döngü

1. **Şehir:** pazar, lonca (kontrat ve borç), taverna (söylenti, işe alma), kervan avlusu, kilise, terzi. Her
   yerleşimin kendi tesisleri ve kendi resmi var. Kasabada lonca ve avlu yok, kervansarayda lonca ve kilise yok.
2. **Plan:** hedef, vagon, refakat edilen tüccarlar, erzak (planlayıcı havayı, eğimi ve kamp emrini hesaba katar:
   doğru stoklayan aç kalmaz).
3. **Yol:** günler gerçek zamanda akar (1x hızda bir gün 45 saniye). Lider kolonda yürür ve dikkat bölgesi seçer.
   Hava, arazi, işaret, olay kartı, karşılaşma ve savaş yolda olur. Kamp akşam kurulur.
4. **Varış:** teslim, ödeme, itibar, kırılma, iyileşme, bölüm ilerlemesi. Döngü yeniden başlar.

Kampanya bir hikâyedir ama oyunun sonu değildir: final bir eşiktir, sonrasında ticaret sürer. Tek gerçek son, kervanın
adını taşıyacak kimsenin kalmamasıdır.

## Dünya

- Tek kıta, 27 oynanabilir yerleşim (12 şehir, 12 kasaba, 3 kervansaray), 41 yol. Kuzeyden güneye 61 gün.
- Kültürler ve bölgeler (benzetmeler yalnızca ton içindir, ad ve imge alınmaz):
  - Vadi: bereketli, loncalar.
  - Kuzey imparatorluğu: koyu taş, düzen.
  - Sınır halkları: ahşap ve tedirginlik.
  - Dağ kabileleri ve madenler.
  - Güney liman kentleri: ticaret.
  - Göçebe boylar.
  - Ahit: tapınak kenti.
- Lore ve tarihçe: `docs/lore/LORE.md`, `docs/lore/TARIHCE.md`. Olay, düşman, zindan ve bölüm yazımı lore kapandıktan
  sonra yapılır.

## Ton

Stil cümlesi (onaylı): **Wayborne, bir kervan kâtibinin defterine ve haritasına mürekkeple çizilmiş bir dünyadır.**
Ayrıntı: `docs/ui/STIL_REHBERI.md`. Oyuncuya nedenler sayıyla değil sözle söylenir ("Moral −10" değil "moral düşük").
Stres ekran efektiyle değil davranışla yaşatılır.

## Kapsam ve takvim

- PC oyunu; Web yalnızca test için.
- Hedef: Şubat 2027 Next Fest. Steam sayfası ve pazarlama Aralık'ta. Kickstarter yok.
- Kapsam kilidi yok; dünyanın tamamı oyunda.

## Bağlantılar

- Kurallar ve sistemlerin "neden"i: `CLAUDE.md`.
- Mekaniklerin düz anlatımı: `docs/Wayborne-Codex.pdf` (üretilir: `docs/codex/`).
- Görevler: `TODO/YAPILACAKLAR.md` (depo dışında).
- Mağaza metni taslağı: `docs/steam/MAGAZA_METNI.md`.
