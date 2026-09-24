# Wayborne Codex - üreteç

`docs/Wayborne-Codex.pdf` elle yazılmış bir PDF değil, buradaki Python
betiklerinden üretiliyor. Kaynağın depoda durmasının sebebi basit: kaynağı
olmayan bir PDF, oyun değiştiğinde güncellenemez - yalnızca eskir.

## Üretme

```bash
pip install reportlab
python3 docs/codex/codex_main.py
```

Çıktı doğrudan `docs/Wayborne-Codex.pdf` üzerine yazılır; betiğin yanına
ikinci bir kopya bırakmaz.

## Dosyalar

| dosya | ne var içinde |
|---|---|
| `codex_base.py` | Font kaydı, renk paleti, paragraf stilleri, akış nesneleri (`callout`, `codebox`, `table`, `HRule`, `ColorBar`) |
| `codex_body.py` | I-III. bölümler: Oyun Nedir, Karakter, Kervan |
| `codex_body2.py` | IV-VII. bölümler: Şehir, Yol, Savaş, Kampanya |
| `codex_main.py` | VIII. bölüm (Olay Motoru), olay ağacı bölümü, ek, kapak, içindekiler, sayfa şablonu ve `build()` |
| `codex_event.py` | Bir olayın tam sayfasını çizen işleyici (künye şeridi, karar ağacı, etki renklendirmesi) |
| `codex_events_data.py` | Yirmi yedi olay kartının içeriği - `scripts/events/event_catalog.gd`'nin okunur karşılığı |

## Font

Gövde **Liberation Sans** (Regular/Bold/Italic/BoldItalic), kod ve etki
satırları **DejaVu Sans Mono**. DejaVu'nun italik varyantı her kurulumda
bulunmuyor; eksik olduğunda `<i>` etiketleri sessizce düz metne düşer, o
yüzden gövde için tam aile olan Liberation seçildi. İkisi de Türkçe
gliflerin (ş ğ ı İ ç ö ü â) tamamını taşıyor.

## Bakım

`codex_events_data.py` katalogun aynası, türetilmişi değil: `event_catalog.gd`
değiştiğinde buradaki karşılığı elle güncellenmeli. Bu bilinçli bir seçim -
GDScript kaynağını Python'dan ayrıştırmak, codex'in anlatmak istediği
"bu olay neden böyle tasarlandı" notlarını zaten üretemezdi.
