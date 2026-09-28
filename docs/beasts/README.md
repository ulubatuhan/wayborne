# Hayvan sprite'ları (at, öküz, kurt, ayı, yaban domuzu, beyaz at, eşek,
# erkek geyik, geyik, husky)

Hayvanlar da bir iskeletle çiziliyor (`scripts/character/beast_rig.gd`). On
tür aynı on altı kemiği paylaşıyor: gövde, boyun, baş, kuyruk ve dört bacağın
her birinin üst, alt ve ayak kemiği. Türler arasındaki fark oranlarda. Bir
türün gövde resmi geldiği an o tür yolda, köyde, savaşta ve yoldaki karşılaşma
işaretinde resimle çizilmeye başlıyor. Resmi gelmemiş tür eskisi gibi prosedürel
çizimde kalıyor. Beyaz at, eşek, erkek geyik, geyik ve husky'nin sanatı bitti
ama hiçbir oyun mekaniğine henüz bağlanmadı - bkz. CLAUDE.md Ana Hedefler.

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

**Yeni bir tür eklemenin sırası:** önce `BeastRig.SPECIES`/`SPECIES_ORDER`'a
bir giriş (prosedürel yedek poz + `godot --headless --script
res://tests/export_rig_spec.gd` ile `docs/beasts/beast_rig_spec.json`'ı
tazele), sonra `beast_skin.py`. Araç `--species` seçeneklerini bu JSON'dan
okuyor - motorun henüz bilmediği bir tür için skin üretilemez, kasıtlı bir
sıralama.

**`SPECIES_BACK` bir ölçüm değil, bir tasarım kararı.** `skeleton()` ham
glTF'in withers yüksekliğini bu orana **zorlayarak** ölçekliyor - yani
"gerçek dünyada bu hayvan ne kadar büyük" sorusuna değil, "oyunda insan
figürünün yanında ne kadar büyük okunmalı" sorusuna cevap. At/kurt için
zaten böyle seçilmişti (.66 / .50); yeni bir tür eklerken de ham model
oranlarını ölçüp uyarlamak yerine ailenin içine (kurt .50 - at .66 arası)
oturan bir hedef seçilir.

**Bir hayvanın rijit bir eki olabilir** (geyiğin boynuzu gibi) - ayrı,
skin'siz bir mesh, tek bir kemiğe (`Head`) rijit bağlı. `load_model()` bunu
otomatik buluyor (o kemiğin ebeveyn zincirinde olan, skin'siz her mesh) ve
tam ağırlıkla o kemiğe katıyor - ayrı bir sistem gerekmiyor, "bir hayvan
bütün boyanır, sonra kesilir" ilkesinin bir uzantısı.

**Tek karede çok fazla tür basmayın.** Bu ortamın yazılım rasterleyicisi
(llvmpipe, Vulkan yok) aynı karede otuzu aşan eşsiz `Texture2D` etkin
olduğunda bir dokuyu değil bir öncekini çiziyor - veri/kod tarafı tamamen
doğruyken bile. `screenshot_beast_rig.gd` bu yüzden at/öküz/kurt'u ve beş
yeni türü **ayrı karelere** basıyor (bkz. o dosyanın başındaki not). Yeni
bir tür eklerken aynı karede çok fazla eşsiz doku birikmediğinden emin
olun, ya da kendi ayrı karesine basın.

## Dosyalar nereye gider

```
data/assets/characters/beasts/<katman>/<parça>.png
```

- `<katman>`: `horse`, `ox`, `wolf`, `bear`, `boar`, `horse_white`,
  `donkey`, `stag`, `deer`, `husky`. Hayvanın üstüne binen takımlar da ayrı
  katman: `horse_tack` (eyer, dizgin), `ox_yoke` (boyunduruk yastığı,
  kayış).
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
