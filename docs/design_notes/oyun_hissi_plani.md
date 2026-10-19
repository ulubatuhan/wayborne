# Oyun hissi incelemesi ve planı (N31)

Sütun: Yol yaşar · İnsanlar aşınır. Altı alan; her birinde bugün ne var (dosya, sınıf), eksik ne, öneri, maliyet
(S küçük, M orta, L büyük) ve öncelik. Öneriler yeni sistem icat etmez, var olan kapılardan geçer. Sonuçtaki alt
görevler `TODO/gorevler/14_yeni_dunya.md`'de N31a-N31f olarak.

## 1. Ölçüm

| | |
|---|---|
| Bugün | `simulate_journeys`, `simulate_career` (tekrar oranı, Y-E01), `simulate_attention`, `simulate_road_beats` (yolda dakikada karar/bilgi anı, Y-B09), ilk dakikaların çizelgesi (`GameSession.first_times`, Y-H02), `perf_50.gd` |
| Eksik | Tepki süresi (tıklamadan ekrana); kamp ve savaşın gerçek süresi; oturum başına "boş dakika" (karar yokken geçen süre) |
| Öneri | `play_seconds` yanında beat kaydı: her karar/bilgi anı gerçek saniyeyle (yalnız oyuncu testinde); `playtest_report.py` boş dakikaları ve savaş/kamp sürelerini de yazsın. Godot profilerinden kare süresi kanıtı (60 FPS hedefi, PC) |
| Maliyet / öncelik | M / P1 (Y-K03 ile birlikte) |

## 2. Renk teorisi, ışık, sis, son işlem

| | |
|---|---|
| Bugün | `ArtPalette` tek renk kaynağı, dört gün evresi × biyom; `STIL_REHBERI.md`; harita gece tonu (`map_tint_for_hour`); yol katmanları `_light` ile çarpılıyor, pus gökten; kasaba render'ı town_post (gök, sis, mürekkep, kâğıt) |
| Eksik | Güneş disk olarak çiğ (12.2e); evre başına tek renk derecelendirmesi yolun tüm katmanlarında değil; uzak-orta arası sis şeridi yok; şehir varyantları (9.3) |
| Öneri | 12.2e taslağındaki ışık modeli: ufuk bandı + hale + bulut kenarı, evre başına tek derecelendirme (uzak soğuk, ön sıcak), ayrı sis şeridi; CityFront'ta saat ve kriz varyantı (town_post gök adımı) |
| Maliyet / öncelik | M / P1 (12.2 onayına bağlı) |

## 3. Tepkili ses

| | |
|---|---|
| Bugün | `AudioManager`: müzik çapraz geçişi, ortam katmanı, tek seferlik ses (`play_sfx`, eksik dosyada sessiz); kapı gıcırtısı, tahta tok sesi, ateş tutuşması (sentez); vuruş ses kimlikleri (Y-H05, dosyalar yok) |
| Eksik | Para, kart açılışı, adım, tekerlek, yük indirme, düğme sesleri; çeşitleme (`AudioStreamRandomizer`); ses otobüsleri (müzik/ortam/efekt/arayüz) ve ayarları |
| Öneri | Ses otobüsleri + Ayarlar'da dört kaydırıcı; her `play_sfx` kimliği bir randomizer (perde ±%5-8, tekrarsız); öncelik listesi: vuruş (3 katman), para, kart, ateş döngüsü, adım/tekerlek (yürüyüş hızına bağlı) |
| Maliyet / öncelik | M / P1 (CC0 kayıtlar indirme izni bekliyor) |

## 4. Tepkili animasyon

| | |
|---|---|
| Bugün | `ButtonFeedback` (üstüne gelince büyüme, basınca çökme), `CombatFx` (geri tepme, parlama, sarsıntı, düşüş, kritik yakınlaşması), figür tepki klipleri, rüzgârda eğilme, branda salınımı, kampa iniş-biniş klipleri, dönüş dalgası |
| Eksik | Yol olaylarına figür tepkisi (sinyal belirince başını çevirme, haydut görününce durma); kervanın "duruşu" (Dur temposunda yorgun bekleyiş); varışta kapı önünde durma (12.2a) |
| Öneri | `WalkFigure` için iki kısa klip: `look` (baş çevirme) ve `idle_tired`; sinyal ve karşılaşma işaretinde en yakın figür bakar; Dur'da `idle_tired` |
| Maliyet / öncelik | M (klip + render) / P2 |

## 5. Tepkili parçacıklar

| | |
|---|---|
| Bugün | `StatusFx` (alev, kor, sis, buz kırığı, nefes, damla), kamp ateşi kıvılcımları, yol tozu (`_draw_dust`), grim kül ve kırağı dokuları |
| Eksik | Toz tempoya bağlı değil; tekerlek çamuru (yağmur), ayak altında kar; savaşta mürekkep sıçraması (Y-G06 onayı bekliyor) |
| Öneri | Toz yoğunluğu `scenic_ground_speed` ile; yağmurda tekerlekten çamur (CPUParticles2D, mürekkep dokusu); savaşta gravür sıçraması Y-G06 onayından sonra |
| Maliyet / öncelik | S-M / P2 |

## 6. Müzik ve ortam

| | |
|---|---|
| Bugün | Menü ve yol aynı parça, şehir ayrı; başlıkta rüzgâr ortamı; kullanıcı kararları: ana menüde şarkı yok (Y-I02), müzik dili gerilimli |
| Eksik | Ortam katmanları (rüzgâr, ateş, yağmur, şehir uğultusu, gece ormanı) duruma göre geçmiyor; savaşta müzik değişimi yok |
| Öneri | Ortam = hava × saat × yer tablosu (`AudioManager.ambience_for(weather, hour, place)`), çapraz geçişli; savaşta müzik kısılır, davul katmanı; menüde ateş + gece ormanı (Y-G16) |
| Maliyet / öncelik | M / P1 (kayıtlar Y-I01 planından) |

## Alt görevler (listeye eklendi)

- N31a Ölçüm: beat kaydı ve boş dakika raporu (M, P1)
- N31b Işık modeli ve sis şeridi koda (12.2e onayı sonrası) (M, P1)
- N31c Ses otobüsleri, çeşitleme, Ayarlar kaydırıcıları (M, P1)
- N31d Figür tepkileri: bakma ve yorgun bekleyiş (M, P2)
- N31e Tempoya bağlı toz, çamur ve kar parçacıkları (S, P2)
- N31f Durum tablolu ortam sesi ve savaş müziği (M, P1)
