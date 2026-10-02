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

## Bir kalem nasıl çizdirilir: bütün figür, sonra kesilir

**Dokuz ayrı hücreyi eklem işaretlerine hizalı istemek yedi tur üst üste
başarısız oldu** - hayvanların çarptığı duvarın aynısı (bkz. CLAUDE.md'nin
"An animal is painted whole, then cut" maddesi). Tek, bütün bir yandan
görünüş bir ressamın da, bir görüntü modelinin de, bir 3B render'ın da
güvenilir biçimde verebildiği şey; dokuz hizalı hücre değil.

O yüzden kalem **bir kez, giyilmiş hâlde**, `docs/wardrobe/paint_pose_reference.png`
üstüne çiziliyor; `tools/wardrobe_cut.py` her boyalı pikseli altındaki kemiğe
verip parça tuvallerine döndürüyor.

| Dosya | Ne işe yarar |
|---|---|
| `paint_pose_reference.png` | **768×1152. Ressama verilen şablon budur.** Gerçek manken, boyama pozunda, yandan, sağa bakıyor. Üstüne boyanır, yeniden boyutlandırılmaz. |
| `paint_pose_<cinsiyet>_<kilo>.png` | Aynı poz, altı beden varyantı, eklem işaretleriyle - bizim içindir, ressama verilmez. |
| `rig_spec.json` | Tuval boyutları, pivotlar, `rest_joints`, `paint_joints`. Araçların tek kaynağı. |
| `rig_reference.png` | Dinlenme pozu: her parça PNG'sinin *içinde* durduğu poz. Boyamak için değil - orada arka uzuv tam olarak ön uzvun arkasında. |
| `part_sheet_template.png`, `templates/<parça>.png` | Eski 3×3 yolu. Duruyor, ama yeni kalem için kullanılmıyor. |

Kurallar: yandan görünüş, sağa bakıyor; kalem mankenin üstünde, onun
ölçüsünde, pozunda; ışık sol üstten; **yalnızca kalemin kendisi çizilir,
altındaki beden değil** - her kalem `Wardrobe.SLOT_LAYERS`'da kendi
katmanı, gövdenin bir kopyasını taşıyan bir ceket altındaki gömleği boyar;
tuval boyutu değişmez.

Her kalem için hazır prompt: `docs/gemini-prompts-wardrobe.md`.
Hayvanlar: `docs/gemini-prompts-animals.md`.

## Ekleme

```
python3 tools/wardrobe_cut.py ceket.png jacket_wool
python3 tools/wardrobe_cut.py kilic.png weapon_tier_2 --only weapon
python3 tools/wardrobe_cut.py kukulete.jpg hat_hood --key      # düz arka planlı JPG
```

Sonra `godot --headless --import`.

Araç bir arka uzvu (`<parça>_back.png`) ancak resimde gerçekten göründüyse
yazıyor; görünmediyse atlıyor ve oyun kendi kuralıyla ön resmi karartarak
kullanıyor (`Wardrobe.BACK_SHADE`) - yarım bir kol resmi, doğru karartılmış
bir kopyadan daha kötü.

Pozun kendisi uzuvları açmak için seçildi: dinlenme pozunda arka uzuv tam
olarak ön uzvun arkasına gizlenir, oradan kesilen bir ceketin arka kolu diye
bir şey olmaz. Bacaklar `cos(faz)` ile, kollar `sin(faz)` ile açıldığı için
tek bir yürüyüş karesi ikisini birden açamıyor - `FigureRig.paint_pose()`
bacakları kendi en geniş fazından, kolları kendininkinden alıp birleştiriyor.

Eski 3×3 yolu hâlâ çalışıyor (`tools/wardrobe_ingest.py sheet|part`), ama
yeni kalem için kullanılmıyor.

## İskelet ya da manken değişirse

```
godot --headless --script res://tests/export_rig_spec.gd
python3 tools/wardrobe_mannequin.py
python3 tools/wardrobe_paint_reference.py
python3 tools/wardrobe_templates.py          # yalnızca eski 3×3 yolu için
```

`tests/test_wardrobe.gd` `rig_spec.json` güncel değilse kırılıyor. Boyama
pozu değişirse **o pozda çizilmiş her teslimat geçersiz olur** - kesme aracı
pikselleri pozun kendi kemik bölgelerine göre dağıtıyor, yani eski bir
resim yeni bir poza göre kesilirse parçalar kayar.
