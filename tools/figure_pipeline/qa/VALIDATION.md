# Hakemlerin dogrulanmasi (kural 1) — icerik uretilmeden ONCE

Her test bilinen hatali ornekte BASARISIZ, ozdes/dogru ornekte GECER olmali.
Kanitlar: `build/figures/faz1/validation/` (`validation.json`, fark goruntuleri).
Yeniden uretmek: `python3 -I qa/validate_tests_on_old.py` ve
`python3 -I blender/validate_old_backfaces.py` (+ birlestirme, bkz. asagi).

| Test | Bilinen hatali ornek | Sonuc | Ozdes cift |
|---|---|---|---|
| composite_equals_full | eski 14 katman (layers/*/texture.png, eski sira) vs eski tek parca (debug_render_raw.png), ayni kamera/malzeme/poz | **DUSTU**: ort. 1,58/255, 34.871 piksel > 8/255, maks 120/255 | gecti (0 / 0) |
| godot_equals_blender | mutasyon (eski denemede Blender'in kare kare birlesik karesi yok): 1 px ofset / ters katman sirasi / %1 olcek (sol-ust pivot) | **3/3 DUSTU**: 19.721 / 31.167 / 75.129 piksel > 8/255 | gecti (0 / 0) |
| proportions | eski render + ayni karede projekte edilen eski isaretler (debug_marks.json) | **DUSTU**: el/bas 1,818 (aralik 0,70-0,95), onkol/ust kol 0,915 (0,70-0,90), baldir/uyluk 1,121 (0,88-1,12); isaretler silhouette icinde | — |
| no_backfaces | eski yontem (14 katman, Mask modifier, culling yok) magenta modda yeniden render (blender/validate_old_backfaces.py) | **DUSTU**: birlesikte 18.902 magenta piksel; eski tek parca govdede bile 270 (bilekte katlanma: eski retarget) | — |
| check_config | eski kararlar (selftest_check_config.py) | **5/5 YAKALADI**: 14 parca, on=_l, rijit, culling kapali, kemik olcegi serbest | gercek config gecer |

Bilinen olcum siniri: proportions'in profil-tabanli cene bulucusu eski goruntude
(bas omuzlara gomuk) ceneyi ~20 px asagida buldu (crop ile goruldu). Bu bas boyunu
buyutur, el/bas oranini KUCULTUR; eski cikti buna ragmen dustu. Yeni hatta cene,
ayni karede basilan mesh orta-hat isaretinden okunur (`chin`), profil yalniz yedek.
