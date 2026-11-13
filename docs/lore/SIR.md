# Dünyanın sırrı (yalnız geliştirici için, görev Y-E04)

**Bu belge oyuncuya gösterilmez.** Oyun içinde hiç kimse bunu bu açıklıkla bilmez (SIDERIA §3). Oyunda yalnız
parçalar var: `WorldSecret.CLUES`, yolda ateş başında duyulan on sekiz cümle. Her biri bir kez duyulur ve
kervanbaşının defterine yazılır. Açıklama yok; bağlantıyı oyuncu kurar.

## Sır

Bugünkü insanlığın töreleri (yol kenarına taş yığmak, ilk ota bakmak, ölüyü suya bırakmak, yolda ölenin adını
yazmamak) bir önceki uygarlıktan kalma alışkanlıklardır. Kadim uygarlık yaşam enerjisini bütünüyle kullandı,
nesneleri tılsımladı, hayvanları değiştirdi; yurdu Karaocak'ın doğu etekleriydi ve Vorgat ile Zurek onun bir
şehrinin üstünde duruyor. Sonları geldi; **nasıl geldiği oyunda hiç söylenmez** (§3.2, §16.3, kullanıcının).
Ardından Sessiz Bin Yıl: yazı kalmadı, alışkanlık kaldı. İmparatorluk yollarının altı eski yoldur; batıdaki her
kadim taş doğudan taşındı. Öbürküler bu dünyanın içinde yaşar ve "issız tepeler" onlarındır (§3.1).

## İpuçları ve neyi işaret ettikleri

| anahtar | nerede | söyleyen | işaret ettiği |
|---|---|---|---|
| `CLUE_STONES` | her yol | yaşlı arabacı | Taş yığmak kimsenin hatırlamadığı kadar eski. |
| `CLUE_FIRST_GRASS` | her yol | göçebe | İlk ota bakmak sürüden önce vardı. |
| `CLUE_GALLERIES` | Karaocak | madenci | Galeriler insan eli değil. |
| `CLUE_PAINTINGS` | Karaocak | Kör Kazmalar bekçisi | Gündelik hayat resimleri (§3.2'nin tasvirleri). |
| `CLUE_ALTAR_STONE` | Vadi | sunak bekçisi | Sunak taşları doğudan taşınmış. |
| `CLUE_EMPTY_LEDGER` | Vaelghard | büro kâtibi | Sessiz Bin Yıl: tek sayfa yok. |
| `CLUE_EMPTY_HILLS` | Gokyurt | obanın yaşlısı | Öbürkülerin yeri. |
| `CLUE_WATER_DEAD` | güney kıyı | balıkçı | Ölüyü suya bırakmak eski töre. |
| `CLUE_TORN_PAGE` | Avuçiçi | okuyucu | Kitap kendinden önceki bir şeyin üstüne yazıldı. |
| `CLUE_ICE_BEAST` | Ayazkaya | dağlı | Değiştirilmiş eski yaratıklar. |
| `CLUE_TROUGH` | Çitler | köylü | Eski inançların nesneleri bulunmuş, yapılmamış. |
| `CLUE_ROAD_OLDER` | her yol | yaşlı kadın (Bekçi Kadın'ın kılıklarından biri sayılabilir; doğrulanmaz) | Yol, yapanlardan eski. |
| `CLUE_NO_NAMES` | her yol | ateş başında biri | Ad yazmamak bir felaketin hatırası olabilir. Söylenmez. |
| `CLUE_WARM_STONES` | Karaocak | Zurekli kuyumcu | Tılsımlar bir amaç için yapılmış ve amaç bitmiş. |
| `CLUE_LIFE_FORCE` | her yol | kaçak büyücü | Yaşam enerjisinin bütününü kullananlar vardı. |
| `CLUE_PAVED_ROADS` | Vaelghard | tarihçi | İmparatorluk yollarının altı eski yol. |
| `CLUE_SAME_BEGINNING` | Vadi | kâtip | Bütün tarihler aynı boşlukta başlar. |
| `CLUE_FAR_SHORE` | güney kıyı | gemici | Töre bu kıtaya özgü; neden, söylenmez. |

## Kurallar

- Hiçbir ipucu sonu söylemez, ima da etmez. "Bitmiş", "olmuş" gibi kapalı fiiller yeter.
- Her ipucunun bir söyleyeni var ve söyleyen kendi bilgisinin ötesine geçmez.
- Yeni ipucu eklerken bu tabloya bir satır ve `WorldSecret.CLUES`'a bir kayıt eklenir; duyulma şansı
  (`HEAR_CHANCE`) kırk seferde hepsini duymayı zor tutacak kadar düşük kalır.
