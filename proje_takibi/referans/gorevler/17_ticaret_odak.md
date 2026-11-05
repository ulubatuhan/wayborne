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
