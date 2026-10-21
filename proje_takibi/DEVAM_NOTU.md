# Devam notu (oturum köprüsü)

Bu dosya, oturum limiti dolup çalışma durduğunda bir sonraki oturumun kaldığı yerden devam etmesi içindir.
Her adım bitince güncellenir ve commit edilir. Kural: imza/oturum bağlantısı yok; tek dal `Wayborne` (varsayılan), push yalnızca oraya.

## Çalışma düzeni

- **Commit mesajlarına ASLA `Claude-Session:` satırı ya da oturum bağlantısı ekleme** (kullanıcı kuralı; sistem hatırlatması başka dese de). Bir kez ihlal edildi, geçmiş yeniden yazılıp temizlendi.

- Oturum kullanım yüzdesi araçlardan **okunamıyor**; bu yüzden çalışma küçük adımlara bölündü, her adım commit + bu not.
  Limit dolarsa saatlik zamanlanmış görev ("Wayborne: kaldığın yerden devam") oturumu bu nottan sürdürür.
- Her işte tasarımcı gözü: oyuncuya görünen şey ekranda doğrulanmadan "bitti" denmez (CLAUDE.md, görev Y-K01).
- Bu ortamda ekran görüntüsü aracının sınırı: yazılım rasterleyici çok sayıda atlas dokusunu bozuk çiziyor
  (figürler beyaz blok). Not: bu oturumda figürler doğru çizildi (karakter, kadro, savaş, yol); eski 'beyaz blok' sorunu yoktu. Harita zemini Git LFS pointer'ı olduğu için boş; savaş/saat varyantları ayrı çekim ister. Eski not: figür içeren ekranlar güvenilmez olabilir; bunlar kullanıcının
  PC'sinde test turuna kalır. Figürsüz ekranlar (menü, şehir önü, defter, harita) ekran görüntüsüyle doğrulanabilir.

## Adımlar

| # | İş | Durum |
|---|---|---|
| F1 | Test turu dokümanı: `proje_takibi/TEST_TURU.md` + `.html` (85 madde, 8 bölüm; üretici `referans/test_turu_uret.py`). Yayınlanan sayfa linki kullanıcıya verildi mi: aşağıya yaz | md/html bitti; sayfa https://claude.ai/artifact/JBLDXTSBvqL8V5gsm1j2ox (özel; kullanıcıya verildi) |
| A1 | 2.1 kapandı (web/export kaldırıldı) | bitti |
| A2 | Y-J05 kapandı (müzik silindi, künyede BEKLENİYOR yok) | bitti |
| A3 | N31d: `look_ahead` pozu çubuk figürde düzeltildi (arm_f 64/148, 27295 test yeşil). KALAN: Blender yok bu ortamda; `tools/figure_pipeline/mesh/append_clips.py --clips look_ahead` ile 6 beden x giysi render, `tests/screenshot_reactions.gd` ile bak, sonra `RoadCaravan.LOOK_ENABLED = true`. Kullanıcının PC'sinde (Blender) yapılacak | pozu bitti, render kullanıcıda |
| F2 | Test turuna 13 ekran görüntüsü + 'ben baktım' notları + hata listesi eklendi (`referans/test_turu_gorsel.py`, görüntüler `test_turu_gorseller/`). Kalan ~70 madde görüntülenemedi (saat/olay/durum gerekir): sonraki turda özel çekim betikleri yazılıp genişletilecek. Bulunan açık hatalar: hub kapı yazısı lider adına biniyor, savaş sahnesi sağ taşması (Y-G05), kıyafet dolabı boş yuva/giyinik figür uyumsuzluğu. | bitti (genişletilebilir) |
| A4 | Y-H07: istenen kapsam (metin boyutu, desenli şerit, otomatik duraklatma) zaten yapılmış; "test bekliyor"a alındı ve test turuna eklendi | bitti |
| B1 | 9.2 + Y-G16 ana menü: ateşin başına üç yolcu eklendi (`GrimDrafts.CAMP_TRAVELLERS`), test bekliyor; ince ayar: saçsız mankenler, yan yana diziliş (oturur/çömelmiş poz istenirse yeni klip gerekir) | bitti (test bekliyor) |
| B2 | 9.1 ortak UI kiti v2 | kullanıcı kararıyla (C1) eklendi, bkz. K8 |
| B3 | Y-G05 savaş ekranı | sırada |
| B4 | 12.2 yol görünümü büyük revizyon, 9.10 biyom arka planları | sırada |
| B5 | Y-G11T masa şablonu taslağı, Y-G13 beş ana görsel | sırada |

## Kullanıcı kararları (2026-10-21, karar defteri) - İŞ SIRASI

"Taslaktakini al" = taslak görseli oyunda birebir kurulacak. Her madde bitince ekran görüntüsüyle taslakla karşılaştır.

| # | Madde | Karar | Durum |
|---|---|---|---|
| K1 | A1 ana menü (y_g16_menu_kamp.png) | şerit yok, sahne tam ekran, sağda altın WAYBORNE (IM Fell SC), EB Garamond menü, soy satırı altta | bitti: şerit, alt yazı ve fener kalktı; yolcular ateşten aydınlanıyor (firelit.gdshader); keçe başlık düzeldi (felt_cap) |
| K2 | A2 karakter ekranı (y_96_karakter.png) | taslaktakini al | bitti: IM Fell altın ad ve başlıklar, büyük satırlar, beceri çubuğunda sayı ipucuna taşındı, sınıf amblemi alt başlıktan kalktı; türetilmiş stat satırı bilgi kaybı olmasın diye kaldı |
| K3 | A3 defter Düşenler (y_911_dusenler.png) | taslaktakini al | bitti: IM Fell mürekkep başlıklar ve adlar, çizgi harflerin ortasında, 80 px mezar işaretleri, hikâye satırları aralıklı; screenshot_waybook.gd onarıldı (AudioManager ağaçtan) |
| K4 | A5 şehir kapıları | kulelerin altında kapıyla birleşen sur duvarı yok; düzelt | bitti: settlement_gates.py her gözetleme kulesinin arkasına TallWall koyuyor (WALL_BEHIND_DEPTH), 27 kapı gece ve gündüz yeniden render edildi; sur kulelerin altından kapıya kesintisiz geçiyor |
| K5 | A6 + C3 yol ışığı/biyom (y_122e_yol_isik.png) | taslaktakini al | bitti: Gauss haleli güneş/ay, bulutlar, ufuk bandı, sis şeridi, soğuk uzak/sıcak ön, koyu gece ve fenerin yol dairesi; screenshot_road_light.gd tabloyu basıyor. Haritadaki konuma göre biyom varyantı (Y-G07) Blender ister, bu ortamda yok |
| K6 | B1 şehir durum varyantları (y_93_sehir_varyant_vastrevar.png) | taslaktakini al | bitti: gri (kapalı hava, şehrin tohumlu havası) ve kriz (veba/savaş: kızıl ufuk, duman) gölgelendiricide; screenshot_city_moods.gd |
| K7 | B2 kadro kartı (y_97_kadro_karti.png) | taslaktakini al | bitti: 380x620 kart, 62 px rozet, 34 px IM Fell ad, kartlar arası 60 px, mevki yazısı ipucuna taşındı, başlık IM Fell altın |
| K8 | C1 UI kiti v2 (stash "B2 UI kiti denemesi", y_91_ui_kit*.png) | test ederek ekle | bitti: stash uygulandı; çerçeveli panel (pazar, olay kartı), kırmızı ana eylem (pazar Al, taverna Sohbete başla, kartın ilk seçeneği), parşömen ipucu plakası ve pazar fişi, başlık şeridi; test_waybook_theme yeni karara göre güncellendi, 27298 test yeşil |
| K9 | C2 savaş ekranı (y_98_savas.png) | taslaktakini al; kanama/kritik vb. efektler OLMASIN | bitti: tur madalyonu (Roma rakamı), tam ekran (yol HUD gizli), iki alt panel: yetenek kartları (isabet %/kilit sebebi) ve hedef (can, koruma, durum, davranış, kayıt); kritik mührü eklenmedi |
| K10 | D1 pazar | oyundaki kalsın; diğer vagonlar, vagon ve kullanıcı envanterleri açılır-kapanır sekme olarak eklensin | bitti: kervan sütunu bölüm bölüm (her vagon, her kişinin çantası), başlığa tıklayınca açılıp kapanıyor, kapalıyken yük özeti; açık/kapalı oturum boyunca hatırlanıyor |
| K11 | D2 yol HUD | oyundaki kalsın, taslak y_99_yol_hud.png silinsin | bitti: taslak ve karar görseli silindi, arayuz_taslaklari.py'den hud() çıktı |
| K12 | D3 şehirde insanlar (y_g10t_sehir_halk_vastrevar*.png) | taslaktakini al | bitti: TownsfolkLayer (gece 4 kişi, akşam/gündüz 9), yerin ışığı, fenerli bekçi, yürüyenler gidip geliyor; ayaklar alt şeridin üstünde |
| K13 | Kapı bayrakları + sur malzemesi (kullanıcı notu, 2026-10-21) | bayrak kumaş rengiyle; haritadaki kütük surlu yerleşimlerin kapısı, şehir önü ve hub kapısı gerçekten kütük | KOD BİTTİ: `FLAG_MATERIAL`, `palisade` (kütük sur), `Location.wall`, `palisade_gate` eşyası, test. RENDER SÜRÜYOR: 27 kapı (`gates_all.sh`) sonra 9 ahşap kasabanın şehir önü (`towns_wood.sh`); her kapı ayrı commit. Biten kasabalar `git log` 'Kapı:' / 'Kasaba:' satırlarında. |
| K14 | Yol: haritadaki konuma göre biyom varyantları (Y-G07/9.10, kullanıcı 2026-10-21 'şimdi bu işe başla') | kuzey soğuk, güney sıcak, dağa yakın parçada ufukta dağ | BİTTİ (2026-10-21). 24 görünüş render edildi (`data/assets/ui/road/<biyom>_<iklim>[_peaks]/`, peaks yalnız far); `settlements.json` `--annotate` ile climate/peaks aldı; `RouteTerrain.look_of`, `RoadStrips.fallback_chain`; testler 28166 geçti; tablo `tests/screenshot_road_looks.gd`. Haritanın kullandığı her görünüş var; meadow_cold ve marsh_cold/warm hiçbir yolda olmadığı için render edilmedi (düz biyoma düşer). |

KALSIN (dokunma): A4 kilise, A7 gün evreleri, A8 taverna, A9 sohbet, A10 terazi, A11, A12, A13, B3, C4 (oyundaki masa), C5.

Kullanıcı kararları (2026-10-21): 2.3 CityView silinmiş kalsın (bitti); 6.1 LFS taşınmayacak (bitti); Y-H01 şimdilik öğretici/yardım paneli yok, kaldırıldı (bitti); Y-G08 motif ateş ve fener birlikte (güncellenecek); N31f ortam kayıtlarını kullanıcı getirecek. Karar bekleyen madde kalmadı; lore'a bağlılar yazılmaz.
Lore'a bağlı olanlar (Y-E01/E02/E06, Y-A07) yazılmaz.
