# Oyun denetimi (2026-10-21): önceki oturumun işleri oyunda mı?

Yöntem: görev kaydı, `taslaklar/` içindeki her taslak görsel, commit geçmişi ve oyunun gerçek ekranlarından alınan
ekran görüntüleri yan yana karşılaştırıldı. Ayrıca `data/assets` ve `scripts` için yetim tarama yapıldı.

Önemli: görev dosyalarındaki "Kısmen yapıldı ... arayuz_taslaklari.py yeniden üretir" notları bir kısmında eski kalmış.
9.3, 9.6, 9.7, 9.11, 9.12 sonradan `4af6c2f` ile oyuna girdi. Karar ekrana bakılarak verildi, nota bakılarak değil.

## A. Oyunda ve bağlı (doğrulandı)

| İş | Kanıt |
|---|---|
| 9.2 ana menü gece kampı | ekran; Y-G16 üç yolcu 2026-10-21'de bağlandı |
| 9.6 karakter ekranı (üç sütun, stat ikonları, dirençler) | ekran, taslakla aynı düzen |
| 9.11 defter, Düşenler sayfası, mezar işaretleri | kod (`WaybookPanel`, `GraveMark`), testler; ekran aracı bozuk (E) |
| 9.12 kilise mezarlığı, sakin ve nöbet | ekran + `church.gd` iki resmi seçiyor |
| 12.2a şehir kapıları, 27 yerleşim x gece/gündüz | ekran (`GateArrival`, şehre girişte) |
| 12.2e yol: 6 biyomun render katmanları, saat ve hava ışığı | ekran + `data/assets/ui/road/` |
| N33 şehir gün evreleri (sabah/gündüz/akşam/gece) | `background_*.jpg` + `CityFront.background_path` |
| Canlı taverna, oturan konuklar, konuşma portresi | ekran |
| Pazar terazisi (Y-G11T taslağının seçilen hali) | ekran |
| Savaş arka planı ve stilize can/stres çubukları | ekran |
| Yol paneli: küçük harita, yük özeti, sahnedeki olay kartı | ekran |
| Y-G02 figür konturu, Y-G12 yakın plan HD kareler | ekran |
| Y-H05 vuruş/kritik/öldürme sesleri | `data/assets/audio/combat/` + `AudioManager` |
| Y-G08 fener amblemi, N23 eski Tab paneli kalktı | ekran |

Yetim tarama: oyunca hiç kullanılmayan varlık klasörü ya da betik yok (dinamik adlar dahil kontrol edildi).

## B. Kısmen: taslakta var, oyunda eksik

| İş | Eksik olan |
|---|---|
| 9.3 şehir durum varyantları | "gri" ve "kriz" varyantları; pencere ışığı, ışık huzmesi, hasar, kalabalık katmanları |
| 9.7 kadro kartı | taslaktaki seviye rozeti, stres çubuğu ve durum yazısı (yaralı / Ölümün Kıyısında kırmızı kenar) |
| 9.4 mekân ekranları | ortak iskelet, büyük sahip portresi, mimariden yuvalar (taslak dosyası `y_94_mekan.png` repoda yok) |

## C. Onaylı ama oyunda hiç yok (uygulanacak)

| İş | Not |
|---|---|
| 9.1 UI kiti v2 | deneme `git stash`'te (kullanıcı durdurdu) |
| Y-G05 savaş ekranı | taslak `y_98_savas.png`: tur madalyonu, kritik mührü, alttaki iki panel, büyük figürler |
| 12.2 yol görünümü revizyonu, 9.10 biyom varyantları | Y-G07 ile birlikte |
| Y-G11T masa ekranı şablonu | pazarda terazi biçimi var; diğer masa ekranları yok |
| Y-G13 beş vitrin görseli | oyun dışı (mağaza) |

## D. Değişiklik istenmiş, yeni yön kullanıcıdan

9.5 pazar (üstte mal kartları, altta vagonlar), 9.8 savaş, 9.9 yol HUD'u (sağ üstte gösterge levhası), Y-G10T şehirde
insanlar.

## E. Araç hatası (oyunu etkilemiyor)

`tests/screenshot_waybook.gd` çalışmıyor: `--script` kipinde autoload'lar yokken `WaybookPanel` `AudioManager`'ı anıyor,
derleme hatasıyla takılıyor. Oyunda autoload var; `WaybookPages` testleri geçiyor.
