---
name: denge-olcum
description: Wayborne'da bir oyun sayısını (fiyat, hasar, olasılık, eşik, stres, erzak, kariyer eşiği) değiştirmeden önce ve sonra ölçmek, denge raporu almak için kullan. simulate_journeys ve simulate_career'ı doğru koşturur, sonucu ölçüm kurallarına göre okur.
---

# Denge ölçümü

Kural kitabının özü: **bir mekanik indiğinde yeniden ölçülmezse, kimsenin görmediği bir denge değişikliğidir.**
Ölçülmüş tablolar ilgili kural becerisinde (Ruin Rules ve savaş: `kurallar-savas`; erzak, moral, stres, şehir:
`kurallar-ekonomi`, `kurallar-karakter`). Ölçülmüş ve korunan sistemler kesilmez (CLAUDE.md, Vaat ve Sütunlar).

## 1. Önce ölç

Değiştirmeden önce aynı tohumlarla taban çizgisini al; sonra değiştir, aynı komutu yeniden koş.

```bash
godot --headless --script res://tests/simulate_journeys.gd > /tmp/sim_j.log 2>&1   # tek sefer: kâr, moral, açlık, kazanma oranı
godot --headless --script res://tests/simulate_career.gd   > /tmp/sim_c.log 2>&1   # bir kervanın hayatı: 3 politika x 8 kervan x 40 sefer
grep -n "OLCUM" /tmp/sim_c.log | head
python3 -X utf8 tools/measure_report.py /tmp/sim_c.log > /tmp/olcum.md
```

Günlükler uzun: ekrana basma, dosyadan `grep`/`tail` ile oku.

## 2. Doğru oku

- **Rapor şaşırtıcıysa önce ölçüm aracından şüphelen.** Kural kitabında sekiz ölçüm hatası kayıtlı (moral
  `finish_journey()`'den sonra okundu, kültür ve olay çekişi aynı tohumdan, ekran aracı oyunun çerçevesini
  kurmadı, politika kontrat panosunu görmedi...).
- Tek politikaya bakma; üç politika birbirini yalanlayabilir. Yeni içerikten sonra rapor çöktüyse önce politikanın o
  içeriğe körlüğünü düzelt, içeriğin sayılarına sonra dokun.
- İki uçlu bir eğri tek düğmeyle ayarlanmaz (seviye ve kadro ölçekleri). Tahmin edilen düğme ölçülmeden değiştirilmez
  (Faz 15'te deathblow direnci yanlış düğmeydi).
- Sömürü olan yerde formülü değil sömürünün kapandığını doğrula (pazarlık, şölen, aynı ziyarette geri satış).
- "Doğru stoklayan aç kalmaz" sözü her erzak, hava, sıcaklık ve tempo değişikliğinden sonra yeniden sınanır
  (`test_provisions`, `test_route_terrain`, `test_temperature`).

## 3. Yaz

- Yeni tablo ilgili kural becerisinin başlığının altına, eski tablonun yanına ve **neden değiştiğiyle** yazılır.
  Hedef bandın dışında bilerek bırakılan hücre gerekçesiyle kaydedilir.
- CI'da haftalık ölçüm: `.github/workflows/olcum.yml`; son rapor `docs/olcum/`.
