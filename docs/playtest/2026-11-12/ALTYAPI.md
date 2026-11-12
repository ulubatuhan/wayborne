# Oyun testi altyapısı

## Ne koşuyor

`tests/playtest/playtest_driver.gd` bir profil dosyasını (`tests/playtest/profiller/*.json`) okur ve oyunu baştan
oynar: karakter kurar, şehirde sırayla iş görür, rota seçer, yola çıkar, kamp kurar, sofrayı seçer, kartları ve
savaşları çözer, ölünce varisle ya da yeni kervanla sürer. Yalnız `GameSession`'ın açık kapılarını,
`EventEngine`/`EventResolver`'ı ve `CombatEncounter`'ı çağırır; duruma doğrudan yazmaz. Bir kapı kapalıysa nedenini
"engel" olarak kaydeder.

```bash
godot --headless --script res://tests/playtest/playtest_driver.gd -- \
  --profil tests/playtest/profiller/p2_hayatta_kalan.json --tohum 101 --saat 4 --cikti build/playtest/p2/101
python3 tools/playtest_toplam.py > build/playtest/toplam.txt
```

Çıktı: `olaylar.jsonl` (her karar), `ozet.json` (sayaçlar, huni, ilkler, izler), `gunluk.md`. Hepsi `build/` altında,
depoya girmez. Bir dört saatlik koşu duvar saatinde bir dakikadan kısa sürer.

## Hızlandırıldı: ne gerçek, ne değil

- **Gerçek:** kurallar, kartlar, zarlar, savaş motoru, ekonomi, ölüm ve varis. Oyunun kendi kodu koşar.
- **Hızlandırıldı:** yol sahnesi açılmaz. Süre bir sayaçtır: yol günü 45 sn (`JourneyClock.REAL_SECONDS_PER_DAY`),
  karar başına 6 sn, okuma 200 kelime/dk (profilin `okuma` katsayısıyla), şehir ekranı 20 sn, plan 30 sn.
  "4 saat" bu sayacın 14 400 saniyesidir.
- **Görülmeyen:** çizim, ses, kumanda, yürüyüş, dikkat işaretleri (`RoadSignals`), yoldaki elle hareket. Bunlar için
  dört ekran aracı koşturuldu (`screenshot_menu`, `screenshot_journey_screen`, `screenshot_city_moods`,
  `screenshot_combat`) ve yol ile kart görüntüsüne bakıldı; bir saatlik gerçek sahne turu yapılmadı (IP-008).

## Profiller

Sekiz profil dörde indirildi (kullanıcı kararı, 2026-11-12); üçüncüsü aynı tohumlarla iki kez koşan bir ikizdir.

| dosya | kim | neyi ölçer |
|---|---|---|
| `p1_acemi` | İlk kez oynayan; okumaz, uyarıyı geçer, haritaya bakmaz | retention, ilk yarım saat |
| `p2_hayatta_kalan` | Erzağı sayar, kısa yol seçer, yolda arar | kıtlık ve çaresizlik |
| `p3a_merhametli` / `p3b_sert` | Kartı okur; aynı tohumda iki ahlak | ahlak, iz, yankı, bedel |
| `p4_somurucu` | Baskın stratejiyi arar: avans, yutturma, kısa sefer | ustalık eğrisi, sömürü, ticaret |

Tohumlar 101, 202, 303. Toplam 15 koşu, 60 saat eşdeğeri.

Kapsam dışı kalanlar: yalnız dövüşen profil, yalnız anlatı okuyan profil, kumanda ve atmosfer profili. Dövüş ve
anlatı öbür profillerin içinde ölçüldü; kumanda ve ses ölçülmedi.

## Sınırlar

Profiller sentetiktir: kural tabanlı bir sürücü ve onun üstüne yazılmış bir yorum. Sıkılmaz, merak etmez, bir
resme bakıp vazgeçmez. "Bırakırdım" satırları ölçüm değil, persona beyanıdır ve öyle etiketlendi. Acemi profili
uç bir alt sınırdır: planlayıcının iki basışlı uyarısını her seferinde geçer; gerçek bir acemi ikinci ölümden
sonra öğrenir.

Etiketler: **[Ölçüm]** sürücünün saydığı sayı · **[Gözlem]** ekran görüntüsünde ya da günlükte görülen ·
**[Persona beyanı]** profilin ağzından yorum · **[Tahmin]** ölçülmemiş çıkarım.
