# §4. Kod kalitesi

> Bu dosya `../YAPILACAKLAR.md` dizininin bir bölümü. Görev kimlikleri (ör. **8.2**, **12.2c**, **R0**) ve § başvuruları dizindekiyle aynı. Kurallar: `00_kurallar.md`. Başlamadan önce: `../00_BASLA_BURADAN.md`.

- [x] **4.1 Bayat yorumları düzelt** (§3A, 12 madde)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `b3d43ce`): Yolun menü yorumu, DevPanel, UserSettings, FigureRig, BeastRig yorumları düzeltildi; öteki yedi bayat yorum 3.1, 3.3, 3.4, 2.3 ile zaten gitmişti.
  - Örnek: `road_journey.gd:3025` "kayıt yapılamaz" diyor, oysa yapılabiliyor.
  - Örnek: `user_settings.gd:4` hâlâ `save.json` yolunu gösteriyor.
- [x] **4.2 Bayat belgeleri düzelt** (§3B)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `85c337b`): README (sekiz stat, borç ve ölüm kuralı, 56 paket, faz durumu, util ve config), REDESIGN durum satırı, event-window-blueprint durum satırı; CLAUDE.md'de CityView, silinen anahtarlar ve görsel, hedef platform, codex sayıları, scripts/util (commit 2b13dcc).
  - README: stat sayısı, borç, ölüm, paket sayısı, faz durumu.
  - `REDESIGN.md:3`.
  - CLAUDE.md'deki 5 yanlış cümle.
  - `event-window-blueprint.md`.
- [ ] **4.3 Tekrarlanan yardımcıları birleştir** (§3C)
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `3e35324`): reduce_motion NodeUtil'de; autoload kopyaları bilerek kaldı; CI birleştirme GitHub'da doğrulanamadığı için yapılmadı.
  - `TextureLoader.load_any` (5 kopya), `_reduce_motion` (4), `_clear_children` (8), işe alma düğmesi (3), `tr` sarmalayıcıları (4), `_with_mipmaps` (2).
  - CI adımlarını tek bir reusable workflow'a topla.
- [ ] **4.4 Olay anahtarlarını açık yaz** (§3D)
  - `event_catalog.gd:2173` anahtarları `"%s_TITLE"` ile çalışma anında kuruyor; CLAUDE.md kuralı bunu yasaklıyor.
  - Kasıtlı bir istisna olup olmadığını kullanıcıya sor.
