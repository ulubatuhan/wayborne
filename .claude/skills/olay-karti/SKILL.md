---
name: olay-karti
description: Wayborne'a yeni bir yol olay kartı yazmak ya da var olanı düzeltmek için kullan (EventCatalog, events.csv, seçenekler, sonuçlar, beceri kontrolü, kalite listesi). Kurallar kurallar-olay becerisinde; bu beceri iş akışıdır.
---

# Olay kartı yazmak

Önce `kurallar-olay` (Event Engine Rules, Event Character Rules) ve metin için `wayborne-metin`, dünya için
`wayborne-lore` yüklenir.

## 1. Kartı tasarla

- Hangi sütuna hizmet ettiğini yaz (Yol yaşar, İnsanlar aşınır, Defter unutmaz, Ticaret bilgi oyunudur).
- Kalite listesi (`EventQuality.problems()`, görev Y-E01): en az iki seçenek (zincir devamı hariç); cazip ama riskli
  bir seçenek (kontrol ya da birden çok ağırlıklı sonuç); bir beceri kontrolü; altın, erzak, moral, stres ve itibar
  dışında en az bir etki.
- Kıtlık kartlarında baskın seçenek olmaz; her seçenek bir şey feda eder, bedel adı olan birine düşer (Y-C22).
- Olaylar öldürmez (`PARTY_HP` 1'de durur). Savaş açan seçenek bunu düğmede söyler; bir kişiye düşen seçenek kimin
  olduğunu söyler; kilitli seçenek nedeniyle görünür.
- Yeni bir etki türü gerekirse `EventEffect.Type`'a **ve** `EventEffectApplier`'a eklenir.

## 2. Yaz

- Kod: `scripts/events/event_catalog.gd`. Var olan bir kartı örnek al (`grep -n "static func _" ...`; ör.
  `_event("evt_river_ford", "EVT_FORD_TITLE", "EVT_FORD_TEXT", 0.2)`), `get_road_events()` listesine ekle.
- Metin: `data/locale/events.csv` (etki satırları `game.csv`), anahtar olarak; `tr` ve `en` dolu, `%s`/`%d` sırası her
  dilde aynı. Düzyazı koda yazılmaz.
- Bir durağa bağlıysa `near_<durak>` bayrağı ve `EventWeightModifier` (Route Terrain & Weather Rules).

## 3. Doğrula

```bash
tools/test_ozet.sh                                                   # test_event_effects, test_event_quality, test_localization
godot --headless --script res://tests/report_event_quality.gd > /tmp/eq.log 2>&1; tail -20 /tmp/eq.log
```

Kartın ekranda nasıl göründüğü (`ekran-dogrula`, `screenshot_journey_screen.gd`). Codex için:
`godot --headless --script res://tests/export_codex_events.gd` sonra `python3 docs/codex/codex_main.py`.

## 4. Onaya sun

Kartlar bölge bölge **10'luk partilerle** kullanıcı onayına gider; onay gelmeden çok sayıda kart CSV'ye işlenmez.
Sunarken her kartın kimin ağzından olduğunu, seçeneklerini, bedellerini ve hangi anahtara gideceğini yaz.
