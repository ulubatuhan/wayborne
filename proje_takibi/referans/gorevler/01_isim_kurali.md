# §1. İsim kuralı temizliği (karar verildi, hemen yapılabilir)

> Bu dosya `../YAPILACAKLAR.md` dizininin bir bölümü. Görev kimlikleri (ör. **8.2**, **12.2c**, **R0**) ve § başvuruları dizindekiyle aynı. Kurallar: `00_kurallar.md`. Başlamadan önce: `../00_BASLA_BURADAN.md`.

Kaynak: `KOD_DENETIMI.md` §6, N-5…N-9 (N-1…N-4 "grim" kapsamında, **yapılmayacak**).

- [x] **1.1 "mezra" yeniden adlandırması**
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `0dc0f02`): STOP_MEZRA / "mezra", near_mezra bayrağı, game.csv anahtarı STOP_MEZRA (İngilizce metin Village), world_places.json türü ih_mezra. Kayda sızma yok (durak türü kayda yazılmıyor, near_* bayrakları her gün yeniden hesaplanıyor). Ad önerim; haritanın kendi Türkçe adı zaten Mezra. Beğenilmezse tek toplu değiştirmeyle başka ada çevrilir.
  - Kod:
    - `scripts/travel/route_terrain.gd`: `STOP_MEZRA = "mezra"` ve satır 134, 136, 140, 249, 255
    - `near_mezra`: `scripts/events/event_resolver.gd:40`, `scripts/events/event_catalog.gd:1629,1639`
    - `scripts/ui/travel_band.gd:957,987` ve `scripts/ui/road_journey.gd:169,2074`
  - Testler: `tests/test_memory.gd:629-630`, `tests/test_route_terrain.gd:171`
  - Çeviri: `data/locale/game.csv:330` içindeki `STOP_MEZRA` anahtarı. Görünen metin de gözden geçirilmeli.
  - Veri: `data/config/world_places.json` içinde 12 adet `"kind": "ih_mezra"`.
  - Varlık: `data/assets/ui/waybook/e6j_mezra.jpg`. Dosya adını ve başvuruları birlikte değiştir.
  - Yeni ad oyuna özgü olmalı. Örnek: `STOP_MEZRA` / `"mezra"`. Kullanıcıya bir öneri sun.
  - **Önce doğrula** (§7 madde 2): `STOP_MEZRA` değeri kayıt dosyasına sızıyor mu? Bak: `GameSession.to_save_dict()`, `JourneyController.to_dict()`. Sızıyorsa eski kayıtları okumak için bir eşleme ekle.
- [x] **1.2 `tests/test_combat_dd.gd` dosyasını yeniden adlandır**
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `aa01c40`): tests/test_combat_core.gd, paket adı CombatCore, run_tests.gd kaydı ve koddaki yorum başvuruları.
  - Örnek ad: `test_combat_core.gd`.
  - `tests/run_tests.gd` içindeki kaydı da güncelle.
- [x] **1.3 Kod yorumlarındaki "referans oyun" ve "referans oyun" anmalarını kaldır**
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `35f65f5`): 48 anma (27 dosya) yeniden yazıldı; scripts, tests, tools, data altında metin dosyalarında kalan yok.
  - 27 "referans oyun" ve 29 "referans oyun" geçişi. Liste: §6 N-7, N-8.
  - Yorumun anlamını koru. "referans oyunda gibi" yerine mekaniği doğrudan anlat.
  - `art_palette.gd:144` içindeki "referans oyun #a02b19" yorumu da bu kapsamda.
- [ ] **1.4 Belgeleri temizle**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `8b9db66`): Codex PDF Windows yazı tipleriyle yeniden üretildi; metinde yasaklı sözcük yok (pypdf ile tarandı).
  - `CLAUDE.md`, `README.md`, `docs/ui/REDESIGN.md`, `GELISIM_GECMISI.md` (§6 N-9).
  - `docs/codex/codex_body.py` ve `codex_events_data.py`: oyuncuya dönük PDF metni üretiyorlar, öncelikli.
- [ ] **1.5 Doğrulama:** `git grep` ile yasak kelime taraması (liste: CLAUDE_BASLANGIC.md) hiçbir sonuç vermemeli. Sonra testleri ve CI'ı çalıştır.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `8b9db66`): git grep sıfır; kural tests/test_naming_rule.gd ile korunuyor.
