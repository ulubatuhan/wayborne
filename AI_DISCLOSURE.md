# AI Kullanım Bildirimi / AI Use Disclosure

*(Steam mağaza sayfası ve Steamworks içerik beyanı için hazırlanmıştır -
prepared for the Steam store page and the Steamworks content survey.)*

## Türkçe

**Wayborne**'un geliştirilmesinde yapay zeka araçları (Anthropic'in Claude
modelleri, Claude Code aracılığıyla) **destekleyici bir rol** içinde
kullanılmıştır. Her zaman bir insan geliştiricinin yönlendirmesi, gözetimi
ve onayı altında çalışmıştır:

- **Kodlama**: Oyun mantığının, sistemlerin ve testlerin yazılmasında,
  hata ayıklamada ve mimari kararlarda yardımcı araç olarak kullanılmıştır.
- **Sanat**: Oyundaki görseller dört kaynaktan gelir. (1) Yönetim ekranı arka
  planları, ikonlar, olay kartı illüstrasyonları ve yol/şehir/menü sahneleri
  için görsel üretim modelleriyle (Gemini) üretilmiş, bir insan tarafından
  seçilmiş ve işlenmiş yapay zeka görselleri. (2) Karakterler, hayvanlar,
  giysiler, eşyalar ve kasabalar: ücretsiz (CC0 / CC-BY) 3B paketlerden
  Blender'da giydirilip render edilmiş kareler; render hattının kodu yapay
  zeka desteğiyle yazılmıştır. (3) Bazı sahneler kod içinde tanımlı prosedürel
  çizim fonksiyonlarıyla (`_draw()`) üretilir. (4) CC0 doku ve yazı tipleri.
  Kullanılan tüm üçüncü taraf paketlerin üreticileri `CREDITS.md`'de.
- **Tasarım ve denge**: Oyun tasarımı, denge ölçümü ve dokümantasyonunun
  (bu depodaki `CLAUDE.md` dahil) hazırlanmasında kullanılmıştır.
- **Ses**: Arayüz ve ortam sesleri (`ui_*.wav`, rüzgâr, kapı gıcırtısı,
  tahta tıkırtısı) gerçek kayıt yerine matematiksel olarak (sinüs/gürültü
  dalgaları) üretilmiştir. Müzik: **[iki parçanın (`copper_for_the_traveler`,
  `high_noon_in_the_square`) kaynağı depoda kayıtlı değil; geliştirici
  doldurmalı - yayından önce bu satır kesinleşmeli]**. Her ses dosyasının
  kaynağı ve lisansı `data/assets/audio/KUNYE.tsv`'de; `test_audio_credits.gd`
  ticari kullanımı yasaklayan bir lisansı ve künyesiz bir dosyayı yakalar.

**Oyun içinde, oynanış sırasında dinamik olarak içerik üreten (canlı /
"live-generated") herhangi bir yapay zeka sistemi bulunmamaktadır.** Tüm
yapay zeka destekli çıktı, geliştirme sürecinde bir insan tarafından
incelenmiş, düzenlenmiş ve onaylanmıştır; nihai üründe yer alan hiçbir
içerik denetimsiz şekilde üretilmemiştir.

## English

The development of **Wayborne** made use of AI tools (Anthropic's Claude
models, via Claude Code) in a **supportive/assistive capacity**, always
under the direction, review, and approval of a human developer:

- **Coding**: used as an assistive tool for writing gameplay logic,
  systems, and tests, for debugging, and for architectural decisions.
- **Art**: the game's visuals come from four sources. (1) AI-generated images
  (Gemini image models) for management-screen backgrounds, icons, event-card
  illustrations and road/city/menu scenes, selected and processed by a human.
  (2) Characters, animals, clothing, props and towns: frames rendered in
  Blender from free (CC0 / CC-BY) 3D packs; the render pipeline code was
  written with AI assistance. (3) Some scenes are produced by procedural
  drawing functions (`_draw()`) defined in code. (4) CC0 textures and fonts.
  Every third-party pack's author is listed in `CREDITS.md`.
- **Design & balance**: used in drafting and organizing design
  documentation and balance measurements (including this repository's
  `CLAUDE.md`).
- **Audio**: interface and ambience sounds (`ui_*.wav`, wind, gate creak,
  wooden thud) are generated mathematically (sine/noise waveforms) rather
  than recorded. Music: **[the origin of the two tracks
  (`copper_for_the_traveler`, `high_noon_in_the_square`) is not recorded in
  the repository; the developer must fill this in - the line has to be final
  before release]**.

**This game contains no Live-Generated AI content** — no AI system
generates content dynamically while a person is playing. All AI-assisted
output was reviewed, edited, and approved by a human developer during
development; nothing in the shipped game was produced without human
oversight.
