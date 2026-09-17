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
- **Sanat**: Oyundaki tüm görseller elle çizilmiş dokular değil, kod
  içinde tanımlı prosedürel çizim fonksiyonlarıyla (`_draw()`) üretilir;
  yapay zeka bu çizim fonksiyonlarının yazılmasında destek olmuştur.
- **Tasarım ve denge**: Oyun tasarımı, denge ölçümü ve dokümantasyonunun
  (bu depodaki `CLAUDE.md` dahil) hazırlanmasında kullanılmıştır.
- **Ses**: Yer tutucu ses efektleri, gerçek kayıt yerine matematiksel
  olarak (sinüs/gürültü dalgaları) üretilmiştir; bu üretim kodunun
  yazılmasında da destekleyici olarak kullanılmıştır.

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
- **Art**: none of the game's visuals are hand-illustrated textures —
  everything is produced by procedural drawing functions (`_draw()`)
  defined in code; AI assisted in writing those drawing functions.
- **Design & balance**: used in drafting and organizing design
  documentation and balance measurements (including this repository's
  `CLAUDE.md`).
- **Audio**: placeholder sound effects are generated mathematically
  (sine/noise waveforms) rather than recorded; AI assisted in writing
  that generation code.

**This game contains no Live-Generated AI content** — no AI system
generates content dynamically while a person is playing. All AI-assisted
output was reviewed, edited, and approved by a human developer during
development; nothing in the shipped game was produced without human
oversight.
