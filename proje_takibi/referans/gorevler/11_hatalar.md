# §11. Hata ve kayıt (test edilerek kapatılacak)

> Bu dosya `../YAPILACAKLAR.md` dizininin bir bölümü. Görev kimlikleri (ör. **8.2**, **12.2c**, **R0**) ve § başvuruları dizindekiyle aynı. Kurallar: `00_kurallar.md`. Başlamadan önce: `../00_BASLA_BURADAN.md`.

- [x] **11.1 `RoadSignals` kaydedilmiyor; sefer ortasında kayıt yüklenince açık işaretler kayboluyor.**
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `133f20d`): Açık işaretler JourneyController'a taşındı ve sefer kaydında 'signals' alanı olarak yazılıyor; eski kayıtta alan yoksa boş liste. Yeni paket RoadSignalsSave (tür ve yaş birebir, kayıt dosyasından geçiş, eski kayıt, yüklemeden sonra büyüme); alan okuma satırı çıkarılınca 4 doğrulama kırılıyor (mutasyonla doğrulandı).
  - **Gelen uyarı, aynen:** "RoadSignals kaydedilmiyor. Sefer ortası kayıt yüklenince açık işaretler kayboluyor. Omen ve adlı işaretten önce düzeltilmeli."
  - **Kanıt:**
    - Açık işaretler `RoadSignals.open_signals` (`scripts/travel/road_signals.gd:83`) içinde tutuluyor.
    - O nesne yalnız yol ekranında yaşıyor: `scripts/ui/road_journey.gd:369` `var _signals := RoadSignals.new()`; `:1472` `_signals.clear()`.
    - Sefer kaydını yazan `GameSession._journey_save_block()` (`scripts/autoload/game_session.gd:3084-3095`) yalnızca şunları içeriyor: `origin_id`, `destination_id`, `total_days`, `days_remaining`, `danger_level`, `caravan`, `controller`. İşaretler yok.
    - Yükleme: çağrı `:3285`, fonksiyon `_load_journey_block()` `:3097`.
  - **Çözüm:**
    1. `RoadSignals`'a `to_dict()` / `from_dict()` ekle: `open_signals` (tür, bölge, yaş/saat, büyüme durumu) ve RNG tohumu ya da sayaç.
    2. `_journey_save_block()` içine `"signals"` alanı olarak yaz.
    3. Yükleme sırasında `road_journey.gd` ekranı `_signals`'ı oturumdaki kayıttan kursun, `clear()` ile sıfırlamasın.
    4. Eski kayıtlarda alan yoksa boş listeyle başlasın; geriye dönük uyumluluk testi olsun.
  - **Öncelik:** "Omen" ve "adlı işaret" özelliklerinden önce yapılmalı, çünkü onlar da aynı açık işaret listesine dayanacak.
  - **Test (zorunlu):** `tests/` altında yeni bir paket:
    - (a) Sefer başlat, en az bir işaret açılana kadar ilerle (tohumlu RNG).
    - (b) `to_save_dict()` → `from_save_dict()` ile kaydet ve yükle.
    - (c) Açık işaret türleri ve yaşları birebir aynı mı?
    - (d) Yüklemeden sonra işaret, ihmal edilince yine büyüyor mu?
    - (e) `signals` alanı olmayan eski kayıt yükleniyor mu?
  - Ardından `godot --headless --script res://tests/run_tests.gd` çalıştır; CI'daki betik-hatası taraması da geçmeli.
