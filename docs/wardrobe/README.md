# Kuşam (giysi / zırh / silah) sprite'ları

Karakterler bir iskeletle (`scripts/character/figure_rig.gd`) çiziliyor. Her
giyilebilir kalem, iskeletin kemiklerine takılan küçük PNG parçalarından
oluşuyor. Kalem kuşanıldığında (karakter ekranı → Görünüm ve Kuşam / Ekipman)
yolda, köyde, savaşta ve önizlemelerde aynı anda görünüyor.

## Dosyalar nereye gider

```
data/assets/characters/wardrobe/<kalem_id>/<parça>.png
```

- `<kalem_id>`: oyundaki kimlik. Kıyafetler `OutfitCatalog`'da (`hat_felt`,
  `hat_hood`, `shirt_linen`, `shirt_dyed`, `jacket_wool`, `jacket_leather`,
  `gloves_leather`, `pants_wool`, `pants_canvas`, `shoes_boots`,
  `shoes_sandals`), ekipman `EquipmentCatalog`'da (`weapon_tier_1..3`,
  `armor_tier_1..3`, `amulet_*`). Yeni bir kalem için önce katalogda bir
  girdi açılıyor.
- `<parça>`: `head`, `torso`, `upper_arm`, `forearm`, `hand`, `thigh`,
  `shin`, `foot`, `weapon`. Bir kalem yalnızca kapladığı parçaları taşır
  (çizme: `shin` + `foot`; kılıç: `weapon`; ceket: `torso` + `upper_arm` +
  `forearm`).
- Arka kol/bacak ön uzvun resmini karartılmış kullanır. Farklı olmalıysa
  `<parça>_back.png` ekle (ör. `foot_back.png`).
- Ten katmanı isteğe bağlı: `wardrobe/body/<parça>.png` açık gri çizilir,
  oyun karakterin ten rengiyle boyar.

## Şablonlar

| Dosya | Ne işe yarar |
|---|---|
| `part_sheet_template.png` | 768×1152, 3×3 hücre (256×384). Her hücrede bir parçanın tuvali, gri manken ve eklem işaretleri. Gemini'ye referans görsel olarak ver, giysiyi mankenin üstüne boyat. |
| `templates/<parça>.png` | Tek bir parçanın tuvali (şeffaf). |
| `rig_reference.png` | Mankenin dinlenme pozu, yandan, sağa bakıyor. |
| `rig_spec.json` | Tuval boyutları, pivotlar, kemik yönleri. Araçların tek kaynağı. |

Kırmızı nokta: parçanın asıldığı eklem (pivot). Mavi nokta: kemiğin öbür
ucu. İşaretler ve gri manken son resimde **kalmamalı**.

Kurallar: yandan görünüş, sağa bakıyor; kalem mankenin üstünde onun ölçüsünde;
ışık sol üstten; çizim tuvalin dışına taşmıyor; arka plan şeffaf (Gemini JPG
verir - arka planı sen kaldırıyorsun).

## Ekleme

Parça sayfası (hücreleri doldurulmuş, arka planı kaldırılmış PNG):

```
python3 tools/wardrobe_ingest.py sheet ceket_sayfasi.png jacket_wool
```

Tek parça (ör. yalnız bir kılıç resmi):

```
python3 tools/wardrobe_ingest.py part kilic.png weapon_tier_2 weapon
```

Arka planı kaldırılmamış, düz renkli bir resim için `--key` ekle. Sonra
`godot --headless --import`.

## İskelet değişirse

```
godot --headless --script res://tests/export_rig_spec.gd
python3 tools/wardrobe_templates.py
```

`tests/test_wardrobe.gd` `rig_spec.json` güncel değilse kırılıyor.
