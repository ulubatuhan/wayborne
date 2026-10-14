# Karanlık Arayüz Taslağı (ui-hud-redesign)

**Durum: onay bekliyor. Bu dal `main`'e birleştirilmedi.** Hiçbir mevcut
ekranın yerine geçmiyor; taslak bileşenler `scripts/ui/grim/` altında duruyor,
taslak ekranlar `tests/screenshot_grim_ui.gd` ile çiziliyor.

## 1. Referans analizi

`UI-HUD.rar` 45 görüntü taşıyordu: Darkest Dungeon (hamlet, savaş, envanter),
Frostpunk (üst kaynak şeridi, ısı haritası), This War of Mine (kişi kartları,
gece ekranı), The Banner Saga (kervan yürüyüşü, karar kartları), Kingdom Come:
Deliverance (envanter, parşömen menüler), Wartales (kamp ve ticaret).

**Telif kararı: referansların hiçbir pikseli oyuna girmedi.** İstem
"referans grafiklerden modüler atlas kesin" diyordu; bu görüntüler ticari
oyunlardan ekran görüntüleri, kesip oyunla dağıtmak telif ihlali olurdu.
Onlardan yalnızca **ölçüm** alındı (palet, yerleşim, oran) ve her doku
`tools/grim_ui_assets.py` ile tohumlu gürültüden sıfırdan üretildi. Yazı
yüzü IM Fell English SC (Igino Marini, OFL 1.1), binalar zaten oyunda olan
CC0 render'lar (PropArt).

Ölçülen ortak paydalar (k-means, her oyunun 6-10 karesi):

| Oyun | Baskın tonlar | Vurgu | Ders |
|---|---|---|---|
| Darkest Dungeon | `#020202` `#0d0a09` `#1e1412` `#322523` | kan `#a02b19` (%2) | Kırmızı neredeyse hiç yok; değerli olduğu için okunuyor. |
| Frostpunk | arduvaz `#505c66` `#738490` | buz `#cdd2d5` | Soğuk bir sistem soğuk renkte gösterilir. |
| KCD | parşömen `#c2ae90` `#d4c4aa` | kahve `#52413b` | Kâğıt yalnızca *belge* olan yerde. |
| Banner Saga | mor-gri `#302d34` | kızıl `#932a13` (%12) | Düz renk + tek vurgu. |
| This War of Mine | neredeyse siyah | — | Karanlık zemin, kurşun kalem çizgi. |

Sonuç: ekranın %60-80'i kömür; kırmızı yalnızca kayıp ve tehlike için;
kehribar yalnızca ışık kaynağı (fener, alev, üstüne gelinen şey).

## 2. Palet (ArtPalette.GRIM_*)

| Belirteç | Renk | Rol |
|---|---|---|
| `GRIM_CHARCOAL` | `#121010` | Zemin, çubuklar |
| `GRIM_CHARCOAL_SOFT` | `#201c1a` | Hücre, düğme zemini |
| `GRIM_PARCHMENT` / `_DIM` | `#c4b08f` / `#8c785c` | Metin, kâğıt |
| `GRIM_CRIMSON` | `#992917` | Kayıp, tehlike, açlık uyarısı |
| `GRIM_RUST` | `#734024` | Kenar, çerçeve (demir pası) |
| `GRIM_IRON` | `#454242` | Terazi, boş hücre |
| `GRIM_SLATE` / `_LIGHT` | `#4f5c66` / `#788a94` | Gökyüzü, cam, stres |
| `GRIM_AMBER` | `#eda852` | Işık: hover, fener, alev |
| `GRIM_ASH` / `GRIM_FROST` / `GRIM_BILE` | | Kül, kırağı, açlık sıvısı |

ArtPalette tek renk otoritesi olarak kalıyor (Art Rules); taslak kendi
renk sabiti tanımlamıyor.

## 3. Tipografi

- **Başlık:** IM Fell English SC - 1600'lerin Fell dökümünün yıpranmış,
  mürekkep yayılmış serifi. Yalnızca başlık, tabela, düğme ve büyük sayı.
  bütün Türkçe harfleri taşıyor (ğ ı İ ş ç ö ü â ölçüldü); taşımadığı her şey EB Garamond'a
  düşüyor (`GrimTheme.title_font()` fallback).
- **Gövde:** EB Garamond (oyunun mevcut kitap yüzü) - okunurluk başlığa
  feda edilmiyor.

## 4. Bileşenler (`scripts/ui/grim/`)

| Bileşen | Ne yapar | Oyunda neyi okur |
|---|---|---|
| `GrimTheme` | Yazı yüzü, dokular, düz kutular, ses imi tablosu | — |
| `GrimTownView` | DD tarzı yan görünüm şehir; hover'da fenerle aydınlanan bina, tabela, sis | `venue_pressed(scene_path)` - CityView ile aynı sinyal |
| `SurvivalGauge` | Şişe (sıvı çekilir, cam çatlar), alev (küçülür, mavileşir), kan lekesi (yayılır) - **sayı yanında kalıyor** | Moral, açlık, derman (stamina), tehlike, sıcaklık |
| `GrimNotice` | Masaya atılmış yırtık parşömen kart; düşer, oturur, solar; ALAMET / KAYIP / KAZANÇ damgası | Defter satırları, olay sonuçları |
| `TradeScales` | Terazi: kol, istenen ile teklif arasındaki *göreli* farka eğilir | `HagglingSession` |
| `MarketMeter` | Stok çentikleri + fiyat baskısı oku + şok noktası | `MarketConditions` (stok, çarpan, `is_shocked`) |
| `WornCell` + `item_wear.gdshader` | Envanter hücresi; yırtık / kırağı / kir aynı gölgelendiricide | **Henüz veri yok** (bkz. §8) |
| `AshFall`, `SmokeWisps`, `LanternGlow` | Atmosfer; hepsi saf zaman fonksiyonu | — |
| `InkMenu` | Kutusuz menü: hover'da mürekkep darbesi + kan çentiği | Ana menü |
| `GrimDrafts` | Beş taslak ekranı kurar; `from_session()` modeli GameSession'dan doldurur | — |

## 5. Taslak ekranlar

1. **Şehir merkezi** - yan görünüm sokak, altı mekân bir bina. Üst şerit:
   şehir, kese, borç, erzak (+kaç gün), saat kadranı, tarih/mevsim, hava,
   etkin değiştiriciler (veba, kıtlık, fuar), kişi başına can/stres.
   Alt şerit: Kadro, Defter, Harita, Kervan, Kapıdan Çık. Tıklanan bina
   sahne değiştirmez; yanında bağlam menüsü açılır (o mekânın bugünkü
   durumu + Gir/Kapat). Haberler sağ üste kart olarak düşer.
2. **Başlık** - mevcut MenuBackdrop karartılmış; kül, duman, fener ışığı;
   IM Fell başlık; kutusuz mürekkep menüsü.
3. **Ticaret** - üç sütun: tezgâh (stok/baskı ölçeğiyle), ortada terazi,
   senin yükün. Kıtlık ve şok her satırda görünüyor.
4. **Envanter** - her vagon kendi ızgarası + ceplerin ızgarası; ağırlık /
   kapasite başlıkta; hücrede miktar, ağırlık, durum çubuğu, bozulabilir
   malda kalan gün.
5. **Yol göstergeleri** - beş organik gösterge sol altta bir plakada,
   haberler sağ üstte.

## 6. Etkileşim durumları

| Durum | Görsel | Ses imi |
|---|---|---|
| Normal | Pas kenar, parşömen yazı | — |
| Hover | Kehribar kenar/yazı; bina fenerle aydınlanır, öbürleri kararır; menüde mürekkep darbesi | `ui_hover` (kumaş fısıltısı) |
| Basılı | Kan kenarı, koyu zemin | `ui_press` (demir mandal) |
| Kilitli | Soluk, **sebebi yanında** (Event Engine Rules) | — |
| Sayfa/ekran geçişi | SceneInk (mevcut) | `ui_page` |
| Para hareketi | Terazi oturur | `ui_coin` |
| Kayıp kartı | Kart düşer, damga | `ui_stamp` |
| Alamet kartı | Kart düşer | `ui_alert` (iki vuruşlu kalp atışı) |

Sesler `tools/grim_ui_assets.py` ile sentezlenmiş yer tutucular (mevcut
rüzgâr/kapı seslerinin yöntemi); AudioManager'a henüz bağlı değil.

**Hareket kuralları korunuyor (Motion Rules):** her eğri statik ve saf,
dinlenmede başlayıp dinlenmede bitiyor (`test_grim_ui.gd`); "Hareketi
Azalt" açıkken kül/duman/titreme dondurulabilir (`set_time`), bilgi taşıyan
hareket (kartın düşüşü) kalır.

## 7. Projenin kurallarıyla çatışmalar - onayınız gereken yerler

1. **Şehir menüsü masa sahnesinden (B10) çizilmiş sokağa geçiyor.** Ana
   Hedefler'deki "DD tarzı şehir" maddesi bunu istiyordu ama Faz 22 şehri
   B10'a yeni taşımıştı; ikisi aynı anda yaşayamaz. Taslak sokağı öneriyor.
2. **Deri yok, ama doku geri geliyor - yalnızca resim olan yerde.**
   Oyuncu deri ve doku kaplı kontrolleri reddetmişti. Taslakta bütün
   kontroller hâlâ düz kutu (StyleBoxFlat); doku yalnızca haber kartının
   kâğıdı, mürekkep lekesi ve envanter yıpranma katmanlarında.
3. **Yeni bir yazı yüzü.** "One book face for every language" kuralı
   gövde için korunuyor; IM Fell yalnızca başlıkta. CJK dillerinde başlık
   da kitap yüzüne düşer.
4. **HUD çubuğundan organik göstergeye.** PulseBar şişeleri zaten vardı;
   SurvivalGauge onların büyük, çatlayan/sönen hâli. Sayı korunuyor.

## 8. Açık tasarım kararları (veri yok)

- **Eşya durumu ve bozulma.** `Item` yalnızca fiyat ve ağırlık taşıyor.
  Hücre yıpranmayı çizebiliyor ama oyun onu hesaplamıyor. Seçenekler:
  (a) yalnızca bozulabilir mallar (balık, erzak) gün sayar; (b) her yığın
  bir durum taşır, satış fiyatını düşürür; (c) yalnızca görsel - yolda
  geçen gün kadar kir, kışın kırağı. Önerim (a) + (c).
- **Sıcaklık.** Soğuk kenarı (G11 frost) oyuncunun isteğiyle kaldırılmıştı.
  Alev göstergesi bir sıcaklık sayısı istiyor; mevsim + biyom + kamp
  ateşinden türetilebilir ama yeni bir sistem. Onay olmadan bağlanmaz.
- **Açlık.** Oyunda "tokluk" sayısı yok, aç geçen gece sayısı var
  (`consecutive_hungry_days`). Şişe gece sayısını ters orantıyla
  gösterebilir.

## 9. Onaydan sonra uygulama sırası

1. GrimTheme'in kalıcı parçalarını WaybookTheme'e taşı (başlık yüzü,
   GRIM paleti), `test_waybook_theme.gd`'yi güncelle.
2. Ses imlerini AudioManager.SFX_PATHS'e ekle; ButtonFeedback hover/press'e bağla.
3. Şehir: `city_map.tscn`'de CityView yerine GrimTownView; CityBriefPanel
   bağlam menüsüne ve üst şeride dağılır. `test_navigation.gd` grafiği.
4. Yol HUD'u: PulseBar → SurvivalGauge; defter olayları → GrimNotice.
5. Pazar: TradeScales HagglingPanel'e, MarketMeter satırlara.
6. Envanter: §8'deki karar verildikten sonra.
7. Ana menü: InkMenu + kül/duman.

## Dosyalar

- `tools/grim_ui_assets.py` - bütün dokular ve ses imleri (tohumlu, yeniden üretilebilir)
- `data/assets/ui/grim/*.png`, `data/assets/audio/ui_*.wav`
- `data/assets/fonts/IMFellEnglishSC.ttf` + `IMFell-OFL.txt`
- `scripts/ui/grim/*` - bileşenler ve taslak ekranlar
- `tests/test_grim_ui.gd` - sözleşmeler (62 doğrulama)
- `tests/screenshot_grim_ui.gd` - taslak ekran görüntüleri
