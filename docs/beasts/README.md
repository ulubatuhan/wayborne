# Hayvan sprite'ları (at, öküz, kurt, ayı, yaban domuzu)

Hayvanlar da bir iskeletle çiziliyor (`scripts/character/beast_rig.gd`). Beş
tür aynı on altı kemiği paylaşıyor: gövde, boyun, baş, kuyruk ve dört bacağın
her birinin üst, alt ve ayak kemiği. Türler arasındaki fark oranlarda. Bir
türün gövde resmi geldiği an o tür yolda, köyde, savaşta ve yoldaki karşılaşma
işaretinde resimle çizilmeye başlıyor. Resmi gelmemiş tür eskisi gibi prosedürel
çizimde kalıyor.

## Yürüyen hayvan: deri (skin.tres)

Parçaya kesilmiş bir hayvan yürürken eklemlerinde ya boşluk açar ya parçaları
üst üste bindirir. Bu yüzden at, öküz ve kurt tek parça bir **deri** olarak
çiziliyor. Her derinlik katmanı (`skin_far.png` uzak bacaklar,
`skin_tail.png` kuyruk, `skin_main.png` geri kalanı) tek bir resim. Üstüne
kemiklere ağırlıkla bağlı bir üçgen ağı geriliyor (`skin.tres`), eklem
bükülünce ağ da bükülüyor. Bir türde `skin.tres` varsa aşağıdaki parçalar
okunmuyor.

Rigli bir glTF'ten üretmek için:

```
python3 tools/beast_skin.py Wolf.gltf wolf --out data/assets/characters/beasts
godot --headless --import
```

Araç modelin kendi skin ağırlıklarını on altı kemiğe eşliyor. Yeniden
boyamak için üç katman PNG'sini **aynı siluetin içinde** boyamak yeterli.
Ağ ve ağırlıklar aynı kalıyor, çünkü köşeler resmin piksellerine bağlı.

## Dosyalar nereye gider

```
data/assets/characters/beasts/<katman>/<parça>.png
```

- `<katman>`: `horse`, `ox`, `wolf`, `bear`, `boar`. Hayvanın üstüne binen
  takımlar da ayrı katman: `horse_tack` (eyer, dizgin), `ox_yoke`
  (boyunduruk yastığı, kayış).
- `<parça>`: `body`, `neck`, `head`, `tail`, `fore_upper`, `fore_lower`,
  `hind_upper`, `hind_lower`, `foot`.
- Uzak taraftaki bacaklar yakın bacağın resmini karartılmış kullanıyor.
  `<parça>_far.png` varsa onu kullanıyor. Aşağıdaki "tek parça" yolu uzak
  bacakları kendiliğinden ayrı kesiyor.

## İki yol

### 1. Tek parça resim (önerilen, Gemini için)

Hayvanın tamamı, yandan, sağa bakıyor, **yarım adımda**: dört bacak birbirinden
ayrı. Referans görsel:

| Dosya | Ne işe yarar |
|---|---|
| `<tür>_pose_reference.jpg` | 1536×1024. Hayvanın boyanacağı poz. Açık gri yakın bacaklar, koyu gri uzak bacaklar. Gemini'ye referans olarak ver. |

Resim pozla aynı bacak düzeninde olmalı. Konum ve boyut tutmak zorunda değil,
araç resmi pozun kutusuna oturtuyor. Arka planı kaldırıp PNG olarak ver:

```
python3 tools/beast_cut.py whole at.png horse
```

Oyundaki her at binicili, her öküz arabaya koşulu. Bu yüzden eyer, dizgin
ve boyunduruk hayvanın kendi resminde çiziliyor. Hazır promptlar
`docs/gemini-prompts-animals.md` içinde. Ayrı bir takım katmanı ileride
gerekirse kendi başına oturtulamaz. Hayvanın resmiyle **aynı tuvale**, aynı
yere çizilmeli (1536×1024):

```
python3 tools/beast_cut.py whole eyer.png horse_tack --species horse --no-fit
```

### 2. Parça sayfası (hassas çalışma için)

| Dosya | Ne işe yarar |
|---|---|
| `<tür>_sheet_template.png` | 1152×768, 3×3 hücre (384×256). Her hücrede bir parçanın tuvali, gri manken ve eklem işaretleri. |
| `<tür>_reference.png` | Mankenin dinlenme pozu. |
| `beast_rig_spec.json` | Tuval boyutları, pivotlar, eklemler. Araçların tek kaynağı. |

Kırmızı nokta: parçanın asıldığı eklem. Mavi nokta: kemiğin öbür ucu.
İşaretler ve manken son resimde kalmamalı.

```
python3 tools/beast_cut.py sheet kurt_sayfasi.png wolf
```

Her iki yolda da `--key` düz renkli bir arka planı köşe renginden siler. Sonra
`godot --headless --import`.

## Kurallar

- Yandan görünüş, sağa bakıyor, ışık sol üstten.
- Ayaklar yer çizgisinde. Ayak/toynak ekleminin altında bir şey kalmıyor.
- Arka plan tek renk düz gri. Gölge, zemin, çimen yok. Temas gölgesini oyun
  kendisi çiziyor.
- Yazı, logo, işaret yok.

## İskelet değişirse

```
godot --headless --script res://tests/export_rig_spec.gd
python3 tools/beast_templates.py
```

`tests/test_beast_rig.gd` `beast_rig_spec.json` güncel değilse kırılıyor.
