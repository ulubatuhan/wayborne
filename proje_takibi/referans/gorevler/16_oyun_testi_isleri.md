# 16. Oyun testi turu (2026-11-02)

> Kullanıcının oyun testinden çıkan işler. Sırayla yapılır, açık bırakılmaz; kullanıcı bütün gerekli işlemleri onayladı.

| # | Alan | Görevler |
|---|---|---|
| 16 | Oyun testi turu | T16-01, T16-02, T16-03, T16-04, T16-05, T16-06, T16-07, T16-08, T16-09, T16-10, T16-11 |

- [ ] **T16-01 Kamp: vagondan ateşe normal yürüyüş hızı, en öndeki attan ateşe en fazla 10 sn**
  - **Ne:** Kamp kurulunca insanlar vagondan ateşe normal yürüyüş hızıyla yürür (koşmaz). En uzaktaki kişi, en öndeki at, ateşe en fazla 10 saniyede varır. Yürüyüş sırasında oyun saati gece bitmeyecek hızda akar.
  - **Kim:** C · **Eski:** 12.2c
- [ ] **T16-02 Balıkçı kültürü: tek yurt yok, balıkçı kasabaları balıkçı ve bölge kültürü karışık**
  - **Ne:** Kullanıcı: "Balıkçıların yurdu diye tek bir yer olmamalı, balıkçı kasabası olan yerler bu kültüre ve o bölgenin kültürüne sahiptir mix olarak." Lore'da Ç12 kapanır; balıkçı kültürünün başlangıcı ve balıkçı köyleri bu karışımı taşır.
  - **Kim:** C · **Eski:** Ç12
- [ ] **T16-03 Batıya giden yolda kervan sola yürür; geri dönen kervanın tamamı döner**
  - **Ne:** Kullanıcı: "Batıya giden yolda kervanın sola yürümesi. Bir noktada kervan geri dönmek isteyebilir, bunu yaparsa tüm kervan geriye dönebilmeli." Yol ekranı haritadaki yöne göre aynalanır: bant, işaretler, duraklar ve kapılar; yazılar ters dönmez.
  - **Kim:** C · **Eski:** Yol yönü hedefi
- [ ] **T16-04 Ana menü: öndeki iki yolcu net, ateş yumuşak**
  - **Ne:** Ana menüde öndeki iki yolcu bulanık, pikselli ve soluk; arka plandaki ateş köşeli tek renk parçalar. İkisi de düzelir, ekran görüntüsüyle doğrulanır.
  - **Kim:** CO · **Eski:** 9.2, Y-G16
- [ ] **T16-05 Kesik el her pozda tam silinsin**
  - **Ne:** Kesik elin durur pozun bazı karelerinde gövde katmanında kalan kısmı da silinir; her klipte el yok, bilekte sargı.
  - **Kim:** C · **Eski:** -
- [ ] **T16-06 Tavernada konaklama; oyun seçeneği boş ekrana girer, geri çıkılır**
  - **Ne:** Tavernada konaklama: para karşılığı gece kalmak (stres ve yorgunluk düşer, gün geçer). Oyun seçeneği: şimdilik oyunu olmayan bir ekrana girer, geri çıkılır.
  - **Kim:** C · **Eski:** N34
- [ ] **T16-07 Bölgesel itibar ve hizipler**
  - **Ne:** Bölgesel itibar ve hizipler (eski Y-C12). Kullanıcı onayına sunulur.
  - **Kim:** CO · **Eski:** Y-C12
- [ ] **T16-08 Bölgesel düşman kimlikleri**
  - **Ne:** Bölgesel düşman kimlikleri (eski Y-C09). Kullanıcı onayına sunulur.
  - **Kim:** CO · **Eski:** Y-C09
- [ ] **T16-09 Adı olan, kervanı hatırlayan kişiler ve NPC hafızası**
  - **Ne:** Adı olan, kervanı hatırlayan kişiler (eski Y-C13) ve NPC hafızası (eski N32). Varis devralma sahnesi (Y-D04) şimdilik atlandı. Kullanıcı onayına sunulur.
  - **Kim:** CO · **Eski:** Y-C13, N32
- [ ] **T16-10 Kod düzeni: iş akışlarını tek dosyada topla**
  - **Ne:** Kod düzeni (eski 4.3): testler, ekran görüntüleri ve ölçüm iş akışları tek dosyada toplanır.
  - **Kim:** C · **Eski:** 4.3
- [ ] **T16-11 Haritada adı olan her yer oynanabilir**
  - **Ne:** Haritada adı olan her yer (obalar, kabile yurtları, mezralar, manastırlar, kuleler, harabeler) bir durak, olay ya da ziyaret edilebilir yer olarak oyuna girer. Girdi: SIDERIA.md §16.2 ve places_v3.json.
  - **Kim:** C · **Eski:** Ana hedef
