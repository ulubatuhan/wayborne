# Aşama 1 — MPFB2 Gövde Varyantları + Kemik Eşleme

**Sonuç:** 2 varyant (male_medium, female_medium) gerçek MPFB2 makrolarıyla üretildi,
bone_map.json 53/53 deform kemiğini eşsiz eşledi, her ikisi de boyama pozuna
retarget edilip gerçek govde üzerine paint_joints işaretlendi - görsel sapma yok.

## Bulunan ve düzeltilen iki gerçek hata

1. **`Skeleton2D.set_bone_setup_mode` yok** (perf testinde, Yol B) - bu
   Godot sürümünde böyle bir metod yok; gerçek API `Bone2D.apply_rest()`.
   Kılavuzun kendi uyarısı doğru çıktı: API imzaları tahmin edilmemeli,
   kurulu sürümden okunmalı.
2. **Varsayılan sahne küpü govdenin alt yarısını gizliyordu.** `make_variant.py`
   `bpy.ops.wm.read_factory_settings(use_empty=True)` çağırmadan `HumanService.
   create_human()`'ı çağırdı - Blender'ın fabrika başlangıç sahnesindeki 2x2x2
   "Cube" (dünya orijininde, tam kalça/ayak hizasında) debug render'da opak
   gri bir dikdörtgen olarak göründü. İlk bakışta "bacaklar render edilmiyor"
   gibi okundu - gerçekte bacaklar oradaydı, kübün **arkasında** kalıyordu.
   `quaternius_render.py` bu adımı zaten doğru yapıyordu (`import_outfit()`);
   `make_variant.py` bunu atlamıştı. Düzeltme: `build_human()`'ın ilk satırı.

Her ikisi de **görsel kontrol olmadan fark edilemezdi** - sayısal çıktılar
(bone_map raporu, `m` ölçek faktörü, `shoulder_y_deviation_px=0.0`) ikisinde
de "başarılı" görünüyordu, çünkü hiçbiri gövdenin gerçekten render'a girip
girmediğini ölçmüyordu. Kılavuzun kendi disiplini (14.6, "tek bir pozda...
bakmak hiçbir zaman yeterli değildir") burada da doğrulandı - sayısal test
yetmedi, gerçek render'a bakmak gerekti.

## Kapsam kararı: paint_joints bu turda kanonik oranlı

`rig_spec.json`'un `_scope_note` alanında belgelendi: bu varyantların
`paint_joints`'i kanonik `docs/wardrobe/rig_spec.json`'dan geliyor, yalnızca
bu varyantın ölçek faktörü `m` ile orantılı - kol/bacak **oranları** değil,
yalnızca **genel boy** varyanta özel. Gerekçe: `FigureRig.pose()` (oyunun
bugünkü, tüm karakterler için paylaşılan poz motoru) zaten yalnızca `height_scale`
gibi tek bir genel çarpanla çalışıyor, kişiye özel uzuv oranı parametresi
almıyor - bu yeni hat için icat edilen bir sınırlama değil, mevcut oyunun
zaten yaptığı şey. Her varyantın **gerçek ölçülmüş kemik uzunlukları**
(`measured_bone_lengths_px`) yine de kaydedildi - `FigureRig`'e per-limb IK
eklenmesi ayrı, kendi başına ölçülmesi gereken bir mimari karar (CLAUDE.md'nin
"paylaşılan sisteme ölçmeden kablolama" kuralı) ve bu turun kapsamı dışında.

## Kapı (bölüm 8.4) durumu

- [x] Her varyant için `.blend`, preset ve `rig_spec` üretildi
- [x] `bone_map.json` eşlenmemiş deform kemiği bırakmıyor (53/53, script kontrolü geçti)
- [x] Debug görüntüsünde eklem işaretleri görsel olarak doğru yerde (bkz. `contact_sheet_asama1.png`)
- [ ] **Kullanıcı varyantların yan yana contact sheet'ini onayladı** - bekleniyor

## Dosyalar

```
build/figures/variants/male_medium/   {male_medium.blend, rig_spec.json, bone_map_report.json, debug_joints.png, debug_render_raw.png, debug_marks.json}
build/figures/variants/female_medium/ (aynı yapı)
build/figures/variants/contact_sheet_asama1.png
```
