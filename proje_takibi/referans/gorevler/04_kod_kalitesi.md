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

- [x] **4.5 Ölü kod ve kopya mantık temizliği** (kullanıcı denetimi, 2026-11-02)
  - **Ne arandı:** hiç çağrılmayan fonksiyon/sabit (tek geçişli tanımlayıcı sayımı: `scripts/`, `tests/`, `.tscn`,
    `.tres`, `.json`, `.csv`, `.py`), aynı 6+ satırlık kod blokları, "iki satırlık işi on satırda yapan" kalıplar
    ve 60 satırı aşan fonksiyonlar.
  - **Silinenler:** 21 fonksiyon, 9 sabit, `UiIcon`'un `PIPS` modu + `ArtDraw.pip` (savaş mevkiyi yazıyla gösterdiği
    için çağrısı kalmamıştı), `_route_meta`'nın hiç okunmayan üç payı (`forest_share`, `mountain_share`,
    `caravan_road_share`). İkisi "ölü" değil **bağlanmamış mekanik** sanılabilirdi, ikisi de doğrulandı:
    `PRIMARY_MATCH_MULTIPLIER` (sınıf eşleşmesi Y-F09'da bilerek kaldırılmış) ve `HIGH_IS_BAD`
    (`BAND_KEYS` yönü zaten kendi sırasında taşıyor). `RoadSignals`'ın `KIND_RESOLVED/ESCALATED_KEYS` tabloları da
    `TRUTH_*` tablolarının eski sürümüydü; çeviri anahtarları yeni tablolarda yaşıyor, metin kaybı yok.
  - **Tek kaynağa inenler:** durum adı (`CombatUnit.status_name_key` - `CombatEncounter` ve `CombatPanel`'de birebir
    kopyaydı, yeni bir durum birine eklenip öbürüne eklenmeyince o ekran sessizce "kanama" diyordu), kaba tehlike
    bandı (`Wording.danger_band`), oyun içi menünün açılışı (`InGameMenu.open_in`), dokuz panelin modal iskeleti
    (`NodeUtil.modal_card`), iki panelin başlığı (`NodeUtil.panel_header`), `InkMenu`'nün satır kurulumu.
  - **Bilerek dokunulmayanlar:** `if koşul: return false` zincirleri (koruma zinciri - kısaltmak okunurluğu bozar),
    veri tablosu olan uzun fonksiyonlar (`SkillCatalog._ensure_built` gibi), `MarketScale`'in resim yüklenemezse
    devreye giren ikinci çizim yolu (yedek, ölü değil; kaldırmak tasarım kararı).
  - **Doğrulama:** 30602 test geçti, 0 kaldı; on modal panel ekran görüntüsüyle karşılaştırıldı. Net -414/+157 satır.
