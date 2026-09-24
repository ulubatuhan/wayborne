# Wayborne - Gelişim Tarihçesi

Bu belge, projenin 2026-08-28 - 2026-09-23 tarihleri arasındaki geliştirme sürecini, önceki commit geçmişinden derlenmiş kronolojik bir özet olarak kaydeder. Depo, gizlilik nedeniyle tek bir commit'e birleştirildi; ayrıntılı tasarım gerekçeleri ve ölçümler hâlâ `CLAUDE.md`'nin "Development Status" bölümünde eksiksiz duruyor - bu belge yalnızca hangi değişikliğin hangi günde yapıldığının bir dökümüdür.

**Toplam kayıtlı adım sayısı:** 163

---


## 2026-08-28

- Initial commit
- Godot 4 proje iskeleti oluştur
- GitHub Pages otomatik deploy workflow'u ekle
- Ana sahneyi (main.tscn) ekle
- Placeholder tabanlı test sahne iskeleti ekle
- Deploy workflow'unda deprecated action sürümlerini güncelle
- project.godot: var olmayan ikon referansını kaldır
- Deploy workflow: geçersiz --import-project bayrağını düzelt
- Deploy workflow: Web export template'lerini indir
- Deploy workflow: export öncesi çıktı klasörünü oluştur
- Web export'ta threading'i kapat (GitHub Pages uyumluluğu)
- Deploy workflow: threading gereksinimini doğrulamak için geçici debug adımı
- Deploy workflow: debug adımını genişlet, gerçek hata metnini bul
- Deploy workflow: geçici debug adımını kaldır
- Cross-Origin Isolation service worker ekle (gerçek kök neden düzeltmesi)
- Ekonomi test sahnesinde alış/satış fiyatlarını ayrı göster
- Kingdom Come tarzı pazarlık (haggling) sistemi ekle

## 2026-08-31

- Harita / seyahat ve kervan planlama mekaniği ekle
- EU4 tarzı yol olayı motoru (event engine) ekle
- Autoload'ların yüklenememesini düzelt
- game_state.gd autoload'unu ayrıştırma anındaki tip bağımlılıklarından kurtar

## 2026-09-01

- Milestone 1: sistemleri tek oyun döngüsünde birleştir
- 2D dünya alanı: yürünen yol, vagon etkileşimi ve şehir haritası
- Geri tuşları nereye döndüklerini yazsın
- Faz 0: döngüyü kapat - kazanç, rota, fiyat, kapasite
- Faz 1: test iskelesini oyuna çevir
- Faz 2: ilerleme kalıcı olsun + Faz 3 hazırlık notu
- WorldMapData ve EventCatalog'a statik önbellek ekle
- Kalıcı vagon sahipliği + yeni oyunda parti büyüklüğü seçimi
- Faz 3.1: Taverna - rota dedikodusu
- Faz 3.2: Pazar Meydanı derinliği - stok, toptan alım, pazarlık
- Faz 3.3: Kervansaray - vagon onarımı ve alımı
- Faz 3.4: Tüccar Loncası - kontrat panosu
- CLAUDE.md: Faz 3 tamamlandı notu
- Karakter oluşturma, kültürler ve Darkest Dungeon tarzı çarpışma
- city_map: _session'ı tipli yap, şehir ekranının ayrıştırma hatasını gider
- ClassCatalog.get_class() Object'in metoduyla çakışıyordu

## 2026-09-02

- Pazarın geri tuşu, kervanın görünür kadrosu ve parti ekranı
- Faz 5: güvenlik ağı - CI ayrıştırma kapısı, testler ve simülatör
- Testleri her dalda koştur, main'e girmeden önce
- Test koşucusundaki Variant çıkarım hatasını gider
- Olay bağlamı partiyi kurmadan sayıyordu
- README yaz: oyun döngüsü, kod tabanı, geliştirme ve CI süreci
- Faz 6 PR-A: ilerleme veri katmanı - stat tavanı, XP/seviye, sınıflar, görevler
- Faz 6 PR-B: karakter ekranı, sınıf seçimi ve seviyeli tayfa
- Faz 6 PR-C: huylar (Trait) ve Kilise
- Faz 6 PR-D: stres/moral döngüsü ve kamp - Faz 6'nın son PR'ı
- resolve_stress_breaks(): Array.duplicate() Variant tuzağına düştü
- test_stress.gd: lambda dış değişkeni değere göre yakalıyordu, referansa göre değil
- Faz 7 PR-A: Equipment veri katmanı

## 2026-09-03

- Faz 7 PR-B: Equipment UI + edinim
- Faz 7 PR-C: İzci bağlantısı + olay havuzu genişlemesi
- Faz 7 PR-D: Placeholder isimlerin lore'a dönüşümü
- .claude/settings.json: sık kullanılan salt-okunur MCP/git izinlerini allowlist'e ekle
- Faz 8 PR-A: Denge simülatörünü genişlet, gerçek bir görev bug'ı bul ve düzelt
- Faz 8 PR-B: Düşman çeşitliliği - vahşi hayvanlar, bölgesel haydutlar, muhafızlar
- Faz 8 PR-C: Tayfanın görünürlüğü - vagonları süren tayfa artık görünüyor
- Faz 8 PR-C2: Kervan formasyonu - simetrik muhafız, asimetrik tayfa
- Faz 8 PR-D: Hedef ve zorluk eğrisi
- Faz 8 PR-E: Onboarding - ilk şehir varışında atlanabilir ipucu katmanı

## 2026-09-04

- chore: attribution ayarlarını kapat

## 2026-09-08

- Kod taramasında çıkan dört hatayı düzelt
- İkinci tarama: sefer bitişi yarışı, gizli erzak hatası ve ölü kod
- Çeviri altyapısını 11 dile hazırla
- Katalog metinlerini çeviri anahtarlarına taşı
- JourneyClock: sefer zamanını akan bir saate çevir
- Sabit açılış: iki kişi, bir vagon, rastgele yoldaş ve şehir
- Playthrough: akan zaman, gündüz/gece, kamp ambiyansı
- Borç sistemi: kervan borca batabilir
- Envanter ağırlığı ve dinamik ekonomi
- Karakter-duyarlı olaylar: mizaç, kapasite ve kültür yakınlığı
- Pazarlığı yeniden tasarla: sömürüyü kapat, kararı geri getir
- Dinamik rotalar ve yolda değişebilen plan
- Haritada kapalı yol ile yol olmaması ayrımını netleştir

## 2026-09-09

- Pazarlık: gizli eğri yerine sayılabilir üç hak ve ültimatom
- Ekran katmanını çevrilebilir hale getir
- Simülatörün moral ölçümünü düzelt
- CLAUDE.md: moral tespitini düzelt
- Morali canlı bir stata çevir: günlük aşınma + dünyaya bağlı çıkış morali
- A-E denetimi: borç ekranı, çeviri kapsamı, kayıt sürümü
- CLAUDE.md: Faz 9 durumunu ve açık denge sorusunu güncelle
- Stres seferler arası biriksin: üç kol birden gerekti
- Ziyafeti günde bire indir: sınırsızken stresi parayla siliyordu
- Kinci yolcu zincirini uçtan uca test et

## 2026-09-10

- Ekranlardan çıkılamamasını düzelt: gezinme denetimi
- Erzak: tek formül, ve açlık artık doğru anı ölçüyor
- Kervan gerçekten mahvolabilsin: yıpranma kâğıttan çıktı
- Ölü kodu temizle, per-frame maliyeti düşür, CI'a tekrar denemesi ekle
- Seviye artık bir şey ifade ediyor: teçhizat kapısı + Karizma'ya karşılık

## 2026-09-11

- Gezinme yığını: menüde kilitlenme yapısal olarak imkânsız
- Şehirde üç yeni karar: vagon satışı, lonca kredisi, borçlar sekmesi
- Şehir karar merkezi oldu, sahnelerdeki 22 metin çeviriye açıldı
- Kampanya omurgası: sonu olan bir hikâye, bitmeyen bir ticaret
- Kariyer yayı simülatörü: kampanya eşikleri artık ölçülü
- Codex: oyunun tasarım belgesi depoya girdi

## 2026-09-12

- Yolu oyuncu yürüsün: kervan artık kendi kendine varmıyor
- Onboarding katmanı oyuncuyu kilitliyordu: taşma, ortalama, saydamlık
- Savaşa DD omurgası: zırh, hız zarı, Ölümün Kıyısı
- Savaş bir liste değil, bir alan
- Savaşçılar çizildi: silüetler, silahlar ve bir ortam
- Yolu yeniden çiz: arazi, hava, katmanlı manzara ve yürüyen kervan
- Şehri izometrik bir kasabaya çevir
- Şehir dışı yürüyüş alanını kervana çevir
- Durum efektleri: kanama, zehir, sersemletme
- Alan hedefleme, mevki kaydırma ve yolun derinlik sırası
- Kervan dizilişi: çakışma tasarım gereği imkânsız olsun
- Dengeyi yeniden ölç ve kural kitabını güncelle

## 2026-09-13

- Manzara nesnelerini yere oturt
- Kervan yola sığsın: çapa kolonla birlikte kaysın
- Öküz vagonuna koşulsun: aralarına kimse girmesin
- Öküzün hörgücü silüete girsin

## 2026-09-14

- Xbox kumanda desteği: sağ çubuk sanal imleç, RT/LT yürüyüş (#38)
- Savaş yolda bir sahne, yaklaşan olaylar önceden yolda görünsün (#39)

## 2026-09-15

- Yol ekranı: dünya ekranın kendisi, kararlar ortada bir kart (#40)
- Moral, stres ve tehlike HUD'da çubuk olsun (#41)
- Konsept görsellere göre sanat geçişi: ön plan, çift öküz, ana menü (#42)
- Şehri de yolun ve menünün diline getir (#43)

## 2026-09-16

- Omurgayı soya taşı, yolu karar katmanına çevir, oyuna ses gir (#44)
- Playtest 14.09.2026: font kapsamı, erzak riski, teslimat, kervan dökümü, yardım (#45)
- Kamp: 0.5x hız varsayılanı, vagon başına ateş, kadro ateşe yürüsün (#46)
- Kamp: arabacı da ateşe gelsin, aynı ateştekiler üst üste binmesin (#47)
- Kamp ateşi etrafında tam çember toplanma + tek öküz kervanı (#48)
- Ana menü kervanı yol üzerinde yürüsün + lonca kredisinde itibara bağlı ücret (#49)
- "Bir tuşa basın" başlık evresi + kapı sesi + ortam/SFX altyapısı (#50)
- Ana menü: yol ve kervan aynı yönde yürüsün (#51)
- Başlık davetini büyüt, ışılt ve oyunun adına bağla (#52)
- Altı playtest bulgusunu düzelt: görsel, kamp, hız, borç, kayıt sistemi (#53)
- Faz 12 PR-A/B/C: tehlike okunabilirliği, liderlik töreni, piyasa şoku görünürlüğü (#54)

## 2026-09-17

- Faz 13: yol olayları, savaş yorumları, boya bağlı açlık, kıyafet sistemi (#55)
- Faz 14: herkes ölebilir, isimli açlık, akşam sofrası, savaş kadrosu, defter hafızası (#56)
- Faz 15: kill-sponge dengesini ölç ve retune et, vagon envanteri + Atölye (#57)
- Atölye'yi doğru yere taşı: vagona, şehre değil (#58)
- LICENSE ve AI kullanım bildirimi ekle (#59)
- Faz 16 hazırlık notu: backlog triyajı, kıyafet kapsamı, iki yeni tasarım notu (#60)
- Faz 16: kıyafet + genel kervan ekranı + rota/hava denetimi (#61)
- Faz 16-B: Tüccarla diyalog + vagon/parti kondisyonunun yol hızını belirlemesi (#62)

## 2026-09-18

- Faz 16-C/D: Lonca, Pazar, Taverna ve Kervan Avlusu'na masa sahnesi arka planı (#63)
- Fix: giriş ekranı ne dokunuşla ne fareyle geçilemiyordu, yalnızca klavye (#64)
- Fix: CityView'in kasaba önündeki boş bandı gri çerçeve gibi görünüyordu
- Fix: kasabanın iki yanındaki gri şeritler - ham viewport clear_color'ı
- Şehir haritasına altın kenarlıklı bir çerçeve + menü arka planı promptu
- Fix real source of the city menu's gray strip: unpainted screen margin
- Remove conflicting FULL_RECT anchor on CityView
- City menu: square map, welcome heading, and the real gray-strip fix
- City menu: move brief below the map, fix real text overflow

## 2026-09-19

- Şehir haritasını harita-solda/menü-sağda düzenine geri döndür, üstteki ipucu yazısını kaldır

## 2026-09-20

- Faz 17 PR-1: Sekiz stat omurgası - Bilgelik ve İnanç eklendi

## 2026-09-22

- Faz 17 PR-2: Skill-check omurgası - tüm event kartlarına stat check
- Faz 17 PR-3: Huy sistemi ultra genişleme - 16 huy + davranışsal kancalar
- Faz 17 PR-4: WorldEvents (bölgesel savaş/veba/ticaret fuarı/haydut haracı) + lonca özel görevleri
- Faz 17 PR-5: Ekonomi derinliği - şehir hazinesi, sepetli pazarlık, altı yeni mal
- Faz 17 PR-6: Yol katmanı - eğim gerçek bir hız çarpanı, yolda borç defteri, arazi-bağlı savaş
- Faz 17 PR-7: Savaş animasyon katmanı
- Faz 17 PR-8: Sayı ve denge turu
- Faz 17 PR-9: İçerik ve lore turu

## 2026-09-23

- Faz 17 PR-3: huyların bilerek dar bırakılan üç kancasını tamamla
- Faz 17 PR-4: loncaya vagon/kargo ödüllü kabul-taşı-teslim görevi ekle
- Faz 17 PR-6: evt_road_patrol savaş dalı + haydut fidyesi ölçeklendirmesi
- Faz 17 PR-7: kaçırma barkı/parlaması ekle
- Kervan Envanteri Rules'un kalan parçası: "Kervan Yükü" ekranı
- CLAUDE.md temizliği: kampanya sadeleştirme + reddedilen notları sil
- CLAUDE.md: Ana Hedefler'deki bayat notu düzelt (geçit artık bağlı)
- Dört ekranı tam kapasite derinleştir: gerçek tüccar kargosu, moral+erzak, kısmi kargo taşıma, lonca görev havuzu
