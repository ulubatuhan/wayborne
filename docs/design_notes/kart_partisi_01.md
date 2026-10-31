# Kart partisi 1: film ve kervan fikirleri (onay bekliyor)

Görevler Y-E09, Y-E10, Y-E11, Y-E12, Y-C26, Y-B14, Y-C29. Kural: kartlar 10'luk partiyle onaya gider; onay gelmeden
oyuna (CSV ve katalog) girmez. Her kart kalite listesinden geçecek biçimde yazıldı (iki ve üstü seçenek, cazip ama
riskli bir seçenek, bir beceri kontrolü, beş temel eksenin dışında bir etki). Yeni etki türü gerekmiyor; gerektiği
yerde yazıyor.

Kısaltmalar: GG altın, E erzak, M moral, S stres, İ itibar. "Kime düşer" düğmede yazar (Event Engine Rules).

## 1. Yol bekçisi (Y-E09) · `evt_road_warden`

Bir karakolun önünde mühürlü bir bekçi "yol bedeli" ister. Mühür gerçek, bedel uydurma.
Gelir: karakol ya da açık kervansaray durağında (`near_outpost`, `serai_open`), haraç bölgesi olmayan yolda.

- **Öde (40 GG).** Geçersin.
- **Erzakla öde (6 E).** Geçersin; M -2.
- **Muafiyetini göster** (Karizma, kervan başı). Başarı: bedelsiz geçersin. Başarısızlık: bekçi iki katını ister
  (80 GG, yoksa borç), İ -1.
- **Loncaya şikâyet edeceğini söyle** (Zeka) · cazip ve riskli. Başarı: bekçi çekilir, İ +1, bekçi seni hatırlar
  (bayrak, ileride intikam kartı). Başarısızlık: bekçi yanındakileri çağırır, savaş (muhafız).

## 2. Esir düşen (Y-E10, zincirin başı) · `evt_taken_captive`

Bir pusudan sonra en zayıf yoldaş kayıp: haydutlar götürmüş. Kim olduğu düğmede yazar.

- **Peşine düş** (Sezgi, en iyi izci). Başarı: iz bulunur, zincir sürer (yol 1 gün uzar). Başarısızlık: iz soğur,
  S +6, zincir yine de sürer ama geç.
- **Fidye için haber bırak** (100 GG, mezra ya da karakolda). Zincir kısa yoldan kapanır.
- **Yola devam et** · cazip ve ağır. Yoldaş geride kalır (`LEAVE_BEHIND`, sebep "esir"), bütün kervana kırgınlık.

Zincirin ikinci halkası (`CHAIN_ADVANCE`, 3-6 gün sonra): yoldaş kaçmış olarak döner, yanında gizli sebepleri
olan iki yabancı (`ROLL_ENCOUNTER`). İkisi de katılmak ister; birinin sebebi sonra ortaya çıkar.

## 3. Gezgin oyuncular (Y-E11) · `evt_wandering_players`

Akşam, ateşin başına üç gezgin oyuncu gelir; bir gece ateşi paylaşmak isterler.

- **Sofrayı paylaş (4 E).** Bütün kadroda S -6, M +5; günlüğe bir "küçük lütuf" cümlesi.
- **Haber sor** (Karizma). Başarı: bir komşu yolun tehlikesi ve bir pazarın fiyatı öğrenilir.
- **Tüccarlar için oynasınlar, haracı sen topla** · cazip ve riskli. +15 GG; bir tüccar bunu kendine hakaret sayar
  ve sonraki şehirde ayrılır.
- **Gönder.** M -2.

## 4. Tövbe alayı (Y-E11) · `evt_penitent_procession`

Yol boyunca yalınayak yürüyen bir alay ekmek ister. Septisist bir lider bunu dua olarak, Yumruk'tan biri gösteriş
olarak okur (kültüre ve inanca göre iki metin).

- **Ekmek ver (6 E).** İ +2, S -3.
- **Reddet.** S +4.
- **Kıtlık fiyatından sat** · cazip ve kirli. +30 GG, İ -3, kıtlıktan kâr sayacı +1 (dünya bunu hatırlar).
- **Duaya katıl** (İnanç). Başarı: bütün kadroda S -5. Başarısızlık: yarım gün kaybolur.

## 5. Kılavuz (Y-E12) · `evt_hidden_guide`

Bir yabancı bataklıktan ya da dağdan bir gün kısa bir yol bildiğini söyler; karşılığında erzak ister. Kiralanmaz,
yalnızca yolda çıkar. Mizacı gizli (sadık, çaresiz, hırsız, intikamcı); yüksek Sezgisi olan bir ipucu alır.

- **Kabul et (4 E).** Sadıksa yol 1 gün kısalır. Çaresizse erzakla kaybolur (8 E). Hırsızsa bir yük çalınır.
  İntikamcıysa pusuya götürür (savaş).
- **Önce sına** (Sezgi). Başarı: mizacı açık söylenir, sonra karar.
- **Reddet.** Hiçbir şey.

## 6. Vebanın uğramadığı köy (Y-C26) · `evt_untouched_village`

Veba dönemindeki bir bölgede, bir mezranın kapısı sıkı kapalı. Köyde kimse hasta değil; neden kimse bilmiyor ve
oyun söylemez.

- **Kapının dışından alışveriş.** Erzak alırsın ama iki katı fiyata.
- **Hastanı içeri sokmayı dene** (Karizma) · cazip ve riskli. Başarı: hastalıklı yoldaşın hastalığı geçer.
  Başarısızlık: köy kervanın yükünden bir parçayı yakar.
- **Zorla gir** (Güç). Başarı: erzak alınır, İ -4. Başarısızlık: köy muhafızlarıyla savaş.
- **Uzaktan geç.** S +2.

## 7. Açık kervansaray (Y-B14) · `evt_serai_open`

Eskimiş ama açık bir kervansaray; sahibi yalnız.

- **Gerçek yatak (20 GG).** Bütün kadroda yorgunluk -20, S -6.
- **Avluda yat.** Bedava; yorgunluk -6.
- **Yolcuları dinle** (Sezgi). Başarı: iki yolun tehlikesi öğrenilir.
- **Ahırdan saman al** · cazip ve riskli. +4 E; sahip görürse bir dahaki kervansarayda adın kötü (İ -2).

## 8. Harabe kervansaray (Y-B14) · `evt_serai_ruin`

Kapısı göğe açık bir harabe; akşam olmak üzere.

- **İçeride geceyi geçir.** Fırtına ve soğuktan korunur (S -4); duvarın dibinde işaretsiz bir mezar.
- **Harabeyi ara** (Sezgi) · cazip ve riskli. Başarı: eski bir mühür ya da bir takı. Başarısızlık: bir duvar çöker,
  arayan kişi yaralanır (adı düğmede).
- **Yola devam et.** Yorgunluk +4.

## 9. Haydut elindeki kervansaray (Y-B14) · `evt_serai_bandit`

Kulede koyu bir bez. Kapıda silahlı adamlar geçiş bedeli istiyor.

- **Öde (50 GG ya da 8 E).** Geçersin.
- **Dolaş.** Yol 1 gün uzar.
- **Yolcu gibi pazarlık et** (Karizma). Başarı: yarı bedel. Başarısızlık: savaş.
- **Saldır** · cazip ve riskli. Savaş; kazanırsan kervansaraydaki ganimet ve yolun tehlikesi bir süre düşer.

## 10. Duvenmor'da kavga (Y-C29) · `evt_duvenmor_quarrel`

Duvenmor'a varmadan bir gece önce, aynı yöne giden rakip bir kervanın başı kervana hakaret eder. Yarın ikiniz de
Duvenmor'dasınız; kervansarayın içinde kılıç çekilmez.

- **Yut.** S +6.
- **Surların dışında, şafakta hesaplaş** (Güç, kervan başı). Başarı: İ +2, M +4. Başarısızlık: kervan başı yaralanır.
- **İçeride kılıcını çek** · cazip ve kalıcı. M +6, ama Duvenmor'a bir daha giremezsin (yasak kayda yazılır, giriş
  nedeniyle kilitli görünür), İ -3.

Onay için her kartta: Onay, Düzenle (ne değişsin), Red.
