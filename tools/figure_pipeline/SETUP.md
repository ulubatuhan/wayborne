# Figür hattı - ortam kurulumu

Bu dosya her oturumun aynı ortamı yeniden kurabilmesi için var (kılavuz bölüm 6).
Burada yazılanlar bu depo için gerçekten doğrulanmış adımlardır - tahmini değil.

## Blender / bpy

Bu ortamda ayrı bir `blender` CLI ikili dosyası **yok**. `bpy` pip paketi
kuruludur (`pip show bpy` → `5.0.1`) - bu, Blender'ın kendisinin Python
modülü olarak derlenmiş hali, ayrı bir kurulum değil. Her script
`python3 script.py` ile çalışır (`blender -b -P script.py` değil);
komut satırı argümanları gerekiyorsa normal `sys.argv` kullanılır
(kılavuzun `--` sonrası `sys.argv` önerisi burada da geçerli, yalnızca
`blender`'ın kendi argüman ayrıştırması aradan çıkıyor).

```bash
python3 -c "import bpy; print(bpy.app.version_string)"   # 5.0.1
```

**Sürüm notu:** kılavuz "Blender 4.2 LTS veya üstü" istiyor; burada 5.0.1
var - "üstü" koşulunu sağlıyor ama MPFB2 resmi olarak 4.2 hedefliyor.
Aşağıdaki duman testi bunun gerçekte çalıştığını doğruladı (bkz. MPFB2
bölümü) - tahmin edilmedi, ölçüldü.

## MPFB2

```bash
curl -sS -L -o /tmp/mpfb.zip \
  "https://extensions.blender.org/api/v1/extensions/?search=mpfb"  # once surumu/URL'i al
# gercek indirme (v2.0.17, bu oturumda dogrulanan surum):
curl -sS -L -o /tmp/mpfb.zip \
  "https://extensions.blender.org/download/sha256:4f0a879d64a39bf646fbf5f53601ac678855da329d650617dca5737548239a87/add-on-mpfb-v2.0.17.zip"
```

```python
import bpy
bpy.ops.extensions.package_install_files(
    filepath="/tmp/mpfb.zip", repo="user_default", enable_on_install=True
)
```

Kurulum sonrası modül yolu (bu oturumda doğrulandı):
`bl_ext.user_default.mpfb` — kılavuzun kendi tahmin ettiği biçimle birebir
aynı. Kaynak, her çalıştırmada şuraya açılıyor:
`~/.config/blender/<sürüm>/extensions/user_default/mpfb/` — API imzalarını
tahmin etmeden önce buradaki gerçek `services/*.py` dosyalarını oku.

**MakeHuman sistem varlık paketi henüz kurulmadı.** `create_human()`'ın
çalışması için ayrı bir varlık paketine ihtiyaç yok (temel mesh MPFB'nin
kendi `data/` klasöründe geliyor, `data/targets/` dolu) - duman testi bunu
kurmadan geçti. Hedefler (vücut şekillendirme target'ları) için bu paket
gerekebilir; Aşama 1 ilerledikçe eksik bir hedef hatasıyla karşılaşılırsa
`http://www.makehumancommunity.org/` üzerinden indirilecek (erişim bu
oturumda doğrulandı, HTTP 200).

**Duman testi** (kılavuz bölüm 6, "Bu çalışmadan devam etme"):

```python
from bl_ext.user_default.mpfb.services.humanservice import HumanService
basemesh = HumanService.create_human()                       # 19158 vertex, 0.42s
rig = HumanService.add_builtin_rig(basemesh, "game_engine")  # 53 kemik, 0.36s
```

Gerçek imza `add_builtin_rig(basemesh, rig_name, *, import_weights=True,
operator=None)` - kılavuzun yazdığı `add_standard_rig` değil (kılavuzun
kendi uyarısı doğru çıktı: "bu imzalar sürümler arasında değişebilir").
Kullanılan rig: `game_engine` (`data/rigs/standard/rig.game_engine.json`) -
kemik adları (`pelvis, spine_01-03, clavicle_l, upperarm_l, lowerarm_l,
hand_l, ...`) Quaternius'un UE4-tarzı adlandırmasına neredeyse birebir
uyuyor, bu da `config/bone_map.json`'u kolaylaştırıyor.

## Normal Python ortamı

```bash
pip install triangle          # kuruldu, doğrulandı (triangle-20250106)
pip install opencv-python-headless scikit-image OpenEXR   # Aşama 2-3'te gerekecek, henüz kurulmadı
```

`imageio` zaten kurulu (2.38.0) - kılavuzun EXR için verdiği `OpenEXR`
alternatifi olarak kullanılabilir, ayrıca doğrulanacak.

## Godot

`/tmp/Godot_v4.2.2-stable_linux.x86_64` (projede sabitlenmiş sürüm).
Gerçek render/çizim gerektiren her test şu kalıpla çalışır (donanımda GPU
yok, yazılım rasterleyici zorunlu):

```bash
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1280x720x24" \
  /tmp/Godot_v4.2.2-stable_linux.x86_64 --path . --rendering-driver opengl3 \
  --script res://<yol>.gd
```

**`SceneTree` alt sınıflarında `_process(delta: float) -> bool` imzası
zorunlu** (`-> void` değil) - aksi halde parse hatası.

## Klasör yapısı (bu oturumda açıldı)

```
tools/figure_pipeline/
  SETUP.md            # bu dosya
  PERF.md             # Aşama 0 sonucu
  config/             # varyant/bone-map/katman tanımları
  blender/            # bpy ile çalışan script'ler
  mesh/               # Blender dışı: kontur, üçgenleme, ağırlık örnekleme
  qa/                 # testler, perf script'leri
  sources/            # (henüz yok - dış varlık gerekirse LICENSES.md ile)
build/figures/         # üretilenler (git'e girmez - bkz. .gitignore)
assets/figures/        # teselerden geçmiş, oyuna giren çıktı (henüz boş)
```
