# İlk dört saat: oyuncu nerede kalır, nerede bırakır

Kaynak: 15 koşu (`build/playtest/toplam.txt`). Süre eşdeğer sayaçtır (`ALTYAPI.md`). Bırakma noktaları persona
beyanıdır; sayılar ölçümdür.

## Huni

| an | P1 acemi | P2 hayatta kalan | P3 ahlak (a / b) | P4 sömürücü |
|---|---|---|---|---|
| 0:10 | şehirde, 1 kart | 1 kart, 1 geri çekilme | 0-1 kart | avans alındı, borç 385 |
| 0:30 | erzak 0, 7 aç gece | 3 sefer, 1 kart | 1-2 sefer, 3-5 kart | 2 sefer, ilk kâr |
| 1:00 | 2 ölü, 2. kervan | 4 sefer, 1 ölü | 4 sefer, 9-11 kart | 5 sefer, 7 kart |
| 2:00 | 4 ölü, 3. kervan | 9 sefer, 3 ölü, 2. kervan | 8-9 sefer, borç 196 / 636 | 11 sefer, kadro 1 |
| 4:00 | 9 ölü, 5. kervan, 1 sefer | 20 sefer, borç 366 | 14-18 sefer, borç 744 / 1006 | 19 sefer, borç 473 |
| bırakma | **0:30** | **2:00** | **3:00 / 2:30** | **3:00** |

## İlkler (saniye, ortanca) ve hedefle farkı

Hedefler `docs/design_notes/ilk_on_dakika.md`'den: ilk karar 180 sn, ilk tehdit 600 sn, ilk kayıp riski ve ilk kâr
1800 sn.

| ölçü | hedef | P1 | P2 | P3a | P3b | P4 | sonuç |
|---|---|---|---|---|---|---|---|
| ilk karar | 180 | 489 | 499 | 677 | 587 | 404 | **hiçbiri tutmuyor (2,2-3,8 kat)** |
| ilk tehdit | 600 | 1085 | 499 | 2196 | 6032 | 1884 | yalnız P2 |
| ilk kayıp riski | 1800 | 1131 | 6369 | 2889 | 1353 | 10738 | P1, P3b |
| ilk kâr | 1800 | hiç | hiç | 1857 | 3458 | 1510 | yalnız P4 |
| ilk ölüm | — | 1837 | 2375 | 2274 (1 koşu) | 1603 / 11035 | 4027 | |

## Tempo

| ölçü | P1 | P2 | P3a | P3b | P4 | hedef |
|---|---|---|---|---|---|---|
| kart / saat | 11,7 | 7,8 | 10,1 | 9,6 | 7,2 | — |
| olaysız yol günü | %64 | %61 | %60 | %59 | %65 | — |
| tekrar oranı | 0,33 | 0,31 | 0,30 | 0,32 | 0,25 | — |
| "iyi şey" arası, ortalama gün | 8,2 | 3,8 | 6,8 | 6,7 | 5,8 | — |
| "iyi şey" arası, en uzun gün | 22 | 12 | 29 | 27 | 21 | ≤ 18 |
| seçeneksiz an | 2 | 11 | 2 | 2 | 3 | 0 |

Olaysız gün kıtlıkta bilerek bırakılmış bir kaynaktır (Quiet Day Rules); sorun sessizlik değil, sessizliğin
ardından gelen şeyin her seferinde aynı pusu olmasıdır.

## Hipotezler (etki sırasıyla)

Her öneri bir şey ekler ya da görünür kılar; hiçbiri baskıyı azaltmaz, hiçbiri bir sistemi kesmez.

### R-1 Dört saatte hiçbir profil büyümüyor
- **Kanıt [Ölçüm]:** Vagon 1, kadro 2 → 1. "Kervanı büyütmek: kese yetmiyor (150 GG)" 22-53 kez. Kese ortancası hiçbir
  kontrol noktasında 112'yi geçmedi. İlk kâr iki profilde hiç yok.
- **Öneri:** Büyümeyi ucuzlatmak değil, büyümenin ara basamağını görünür kılmak: var olan eşek ve yarım vagon
  seçenekleri kervan avlusunda "sıradaki adım" olarak fiyatıyla ve kaç sefer uzakta olduğuyla yazsın; ilk kârlı
  varışta defter bunu bir satırla ansın.
- **Sütun:** Defter unutmaz · Ticaret bilgi oyunudur.
- **Beklenen etki:** 2:00'deki bırakma (P2, P4) 3:00 sonrasına kayar. **Doğrulama:** aynı 15 koşuda "vagon > 1 olan
  kontrol noktası" 0'dan en az 4'e; `first_profit` eksik koşu 6'dan en çok 2'ye. **Maliyet:** M (IP-006). Fiyat
  değişirse kullanıcı kararı (K-03).

### R-2 Acemi ilk yolculukta 33-36 günlük yola çıkabiliyor ve ne olacağını gün olarak görmüyor
- **Kanıt [Ölçüm]:** P1'in 15 seferinden 11'i 33+ gün; 68 erzakla çıkıldı, erzak 9. yol gününde bitti. Planlayıcı
  "Eksik erzak: N birim (M GG)" diyor, gün demiyor. **[Gözlem]** Yol ekranındaki sorun satırı günü söylüyor ama
  yola çıktıktan sonra.
- **Öneri:** Planlayıcıdaki eksik satırına ve onay düğmesine gün eklemek: "Erzak 9 gün yeter, yol 36 gün: 27 gün aç
  yürürsün." Yasak yok, kilit yok; yalnız sayı.
- **Sütun:** İnsanlar aşınır. **Beklenen etki:** P1'in ilk ölümü 0:30'dan 1:00 sonrasına; açlık ölümü payı %85'ten
  %50'nin altına (acemi profili uyarıyı günle okursa %50 ihtimalle döner diye ayarlanır). **Doğrulama:** sürücüde
  `okuma` düşük profilin uyarıyı geçme olasılığı metnin gün içerip içermediğine bağlanır; P1 yeniden koşar.
  **Maliyet:** S (IP-001).

### R-3 Erzak bitince karar da bitiyor: 20+ günlük ölüm yürüyüşü
- **Kanıt [Ölçüm]:** P1'de 83 aç gece; kervanbaşı öldükten sonra varis 23 gün aynı sofrayı aynı boş çuvalla seçti.
  Bu sürede gelen kartın %15'i aynı isyan kartı.
- **Öneri:** Açlığın kendi kartları: aç gece 2, 4 ve 6'da çıkan üç yeni kart (koşum hayvanını kesmek, yükü yemek ya
  da yakmak, birini önden göndermek). Hepsi bir şeyi feda eder, hepsi iz bırakır. İsyan kartı aynı seferde iki
  kereden fazla çıkmaz.
- **Sütun:** İnsanlar aşınır · Defter unutmaz. **Beklenen etki:** aç yürüyüşte karar aralığı 1 günden 2-3 günde bire;
  isyan tekrarı 21'den en çok 6'ya. **Doğrulama:** P1 ve P4 yeniden koşar; `kart_gorulme`. **Maliyet:** M (IP-004,
  IP-005). Y-C23 ile aynı aile.

### R-4 İlk karar 7-11. dakikada
- **Kanıt [Ölçüm]:** İlk karar 404-677 sn; hedef 180 sn. Karakter kurma 90 sn, şehir ve plan 240-400 sn; yolda ilk
  kart 2. günden önce gelmiyor.
- **Öneri:** Yeni bir şey açıklamadan, ilk sefere çıkış kapısında tek bir küçük karar: kapıdaki sayım memuru ilk
  çıkışta bir soru sorar (ne taşıdığını söyle / sus). Bir iz bırakır, ilk varışta kapıda döner.
- **Sütun:** Yol yaşar · Defter unutmaz. **Beklenen etki:** ilk karar ≤ 240 sn; ilk iz dönüşü ilk saatin içinde.
  **Doğrulama:** `first_decision` ortancası; `iz.donen` ≥ 1 (1:00 kontrol noktasında). **Maliyet:** M (IP-007).

### R-5 Kısa sefer döngüsü ve her seferde aynı pusu
- **Kanıt [Ölçüm]:** P2'nin günlükteki her seferi ve P4'ün seferlerinin çoğu 2 gün. Her seferde en az bir dövüş kuralı
  kısa seferle birleşince pusu 2 günde bir geliyor: P2'de 19 pusu / 20 sefer. 43 savaşın 39'u geri çekilme.
- **Öneri:** Garantili karşılaşma kartı çekerken son üç seferde görülmüş karşılaşma türünü geri sıraya atsın
  (görülmemişi kayıran çekiliş kartlarda zaten var; karşılaşmaya da uygulanır). Dövüş sıklığı değişmez.
- **Sütun:** Yol yaşar. **Beklenen etki:** en çok görülen kartın payı %20'den %10'un altına. **Doğrulama:**
  `kart_gorulme`. **Maliyet:** S (IP-003). Dövüş oranına dokunan her şey kullanıcı kararı (K-04).

### R-6 Meşale kapısı her gece çarpıyor
- **Kanıt [Ölçüm]:** "İki meşale yok" koşu başına 85-105 kez; hiçbir profil bir gece bile ışık yakamadı.
  Meşale pazarda satılmıyor, tarifle üretiliyor (1 bez); "üretmek: yeterli malzeme yok" kapısı da 20-61 kez
  çarptı. **[Ölçüm]** Bezin başlangıç şehirlerinde bulunup bulunmadığı ayrılmadı. **[Tahmin]**
- **Öneri:** Önce ölç (IP-002): bez nerede satılıyor, sürücü neden alamadı. Oyunda erişilemiyorsa bu bir hata.
- **Maliyet:** S.

### R-7 Kişilerin istekleri hiç tamamlanmıyor
- **Kanıt [Ölçüm]:** "X'in işini bitirmek: 4 tane eksik" 41-184 kez; tamamlanan zincir sıfır.
- **Öneri:** İsteğin istediği malı şehir özetinde "nerede bulunur" bilgisiyle birlikte yazmak (haber olarak; kesin
  yer değil, yön). Ticaret bilgi oyunudur sütununa tam oturur.
- **Doğrulama:** tamamlanan zincir ≥ 1 / koşu. **Maliyet:** M (IP-009).
