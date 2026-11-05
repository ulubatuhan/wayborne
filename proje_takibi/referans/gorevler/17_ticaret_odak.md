# Bölüm 17 — Ticaretin odağı ve kasvet (kullanıcı onayı 2026-11-05)

Gerekçeler `docs/design_notes/ticaret_ve_kasvet.md`, madde madde öneriler
`docs/design_notes/ticaret_onerileri.md`. Kullanıcı 17 maddenin hepsini onayladı.

- [x] **P03 Ölü pazarlık sahnesi silindi**
  - `scripts/ui/haggling.gd` (104 satır), `scenes/game/haggling.tscn`, `Nav.HAGGLING`, test seçici girdisi ve düğmesi.
  - Bu sahne oyunun akışında hiç yoktu: yalnız F1 geliştirici panelinden açılıyordu. Oyuncunun gördüğü pazarlık
    `HagglingPanel`'in pazara ve yola gömülü hâli.

- [x] **P05 Erzağın şehirdeki stoğu**
  - **Asıl boşluk buydu:** erzak planlayıcıda sınırsızdı, kese yettiği sürece tam gereken sayı alınıyordu. Açlığın
    tek gerçek kapısı paraydı.
  - `Scarcity.provision_stock(location, day)` - yerleşim türü × bölge kıtlığı × günlük dalga; **hesaplanır,
    saklanmaz**. `GameSession.buy_provisions` alımın tek kapısı (stok, kese, kargo).
  - Oyuncunun o gün aldığı **kayda yazılıyor**: kayıt şehirde alındığı için yazılmasaydı kaydedip yükleyerek raf
    tazelenirdi.
  - Planlayıcıda yeni satır: "Bu şehirde yalnız %d erzak var."
  - **Ölçüm (2026-11-05):** şehir ort. 88 (74-109), kasaba 44, kervansaray 60; geç oyunda (300+ gün) şehir 60.
    Başlangıç kervanının ihtiyacı: 5 gün 15, 10 gün 30, 17 gün 51, 25 gün 75. Yani şehir uzun bir seferi ucu
    ucuna karşılıyor, kasaba karşılamıyor, kervan büyüdükçe hiçbir yer karşılamıyor.

- [x] **P09 Erzak sözü arza bağlandı (B yolu)**
  - *"Doğru stoklayan asla aç kalmaz"* → *"stok bulabilirsen aç kalmazsın."*
  - Planlayıcı doğru sayıyı söylemeye devam ediyor; `test_route_terrain` ve `test_temperature`'ın iddiaları
    **değişmedi** - ikisi de zaten "yeterli erzakla çıkan kervan aç kalmaz" diyordu, "yeterli erzak her zaman
    alınabilir" demiyordu. Sözün bozulmadan anlam değiştirmesi bu yüzden mümkün oldu.
  - Planlayıcı eksik erzakla yola çıkmayı hiç kilitlemiyor (iki basışlı onay zaten vardı): kıtlık bir çıkmaz değil
    bir karar.
  - **Kabul:** `tests/test_provision_stock.gd` (11 test), `tests/screenshot_provisioning.gd` üç kare
    (şehir / kasaba / geç oyun kıtlığı).

- [x] **P01 Pazarlık tek karara indi**
  - Üç tur, kaydıraçlı teklif, ciddiyet eşiği ve ültimatom kaldırıldı. Yerine üç düğme: **Kabul Et · Diren ·
    Çık git**. Direnmek **bir kez** atılır; şansı ekranda yazılı (%15-85).
  - Eski tasarımın hatası sömürü değil **kip**ti: üç turlu bir teklif döngüsünün ölçülebilir bir "doğru cevabı"
    vardır, kıtlığın yoktur. Codex'teki bölüm başlığı da itiraftı: *"Pazarlık: oyunun para basma noktası."*
  - Kazanç tavanı %45'ten **%15**'e indi. Kaybedilen direniş fiyatı %10 artırır ve 1 itibar yer - ama pazarlığı
    bitirmez: artmış fiyatı kabul etmek ya da kalkmak hâlâ oyuncunun kararı.
  - **Ekran görüntüsünde yakalanan kusur:** `DISCOUNT_BASE` yokken becerisiz bir kervanda "kazanırsan 19 GG,
    yoksa 21 GG" yazıyordu - istenen fiyat da 19'du. Kazancı görünmeyen bir risk düğmesi karar değil tuzaktır;
    %4 taban indirim eklendi ve kazancı yuvarlamada kaybolan masada düğme hiç gösterilmiyor
    (`push_is_worth_it`).

- [x] **P04 Tek stat: Karizma**
  - Eskiden `player_speech` yuvasına Zekâ, ikinci parametreye Karizma besleniyordu; ad ile içerik uyuşmuyordu ve
    "en iyisini al" ikisini aynı şeye indirgiyordu. Konuşma Karizma'dır; Zekâ'nın pazardaki işi fiyat defterini
    okumak.

- [x] **P02 Kıtlıkta konu fiyat değil (vicdan dalı)**
  - Bölge kıtlığı 0.45'i geçince "Diren" → **"Üstele"** olur, ekrana *"Karşındaki de aç."* düşer. Üsteleyip
    kazanmak malı verir, **o bölgedeki itibarı 2 puan düşürür** ve deftere `LEDGER_CAUSE_HAGGLE_INSISTED`
    satırı girer (`CaravanLedger.KIND_TRADE`).
  - Kıtlık derslerinin *"bedel adı olan birine düşer"* kuralının ticaret tarafı. Yolda (haydut, haraç)
    kıtlık geçilmiyor: orada vicdan dalı kapalı, bedel moral (-3).
  - **Kabul:** `tests/test_haggling.gd` (11 test, eski 12 testin tamamı yeniden yazıldı),
    `tests/screenshot_haggling.gd` dört kare (açılış / kaybedilmiş direniş / kıtlıkta Üstele / üstelenmiş).
  - Ölü çeviri anahtarları silindi (15 adet: `UI_HAGGLE_RANGE`, `_ROUNDS`, `_YOUR_OFFER`, `_SUBMIT`, `_REJECT`,
    `_LOG`, `_OPENING`, `_RULES`, `_INSULTED`, `_CREDIBLE`, `_NOT_CREDIBLE`, `_COUNTER`, `_ULTIMATUM`,
    `_FINAL`, `_YOU_OFFERED`). Codex bölümü yeniden yazıldı.
