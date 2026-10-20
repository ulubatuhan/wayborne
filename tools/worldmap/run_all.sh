#!/bin/bash
# Dünya haritası hattı baştan sona (görev 8.9). Yeniden koşturma 2026-10-20'de
# doğrulandı: kıyı, göl, kent, yol ve orman son haritayla aynı yerde.
#
#   bash tools/worldmap/run_all.sh <girdi kökü> <çıktı klasörü>
#
# <girdi kökü>: zemin teslim paketi (images/base_map_4096.jpg, images/mask_*.png,
#   data/world.json, out/world_zemin.json, out/layout_v2.json, out/layout.json.foot.npy).
#   Eski pakette yol dosyasının adı out/world_kcd.json: world_zemin.json olarak kopyalanır.
# <çıktı klasörü>: depo dışında (fields.npz ~ yüzlerce MB, map_16384.png ~200 MB).
# Gerekenler: numpy, scipy, opencv, pillow, pycairo; yazı tipleri IM FELL English SC,
# EB Garamond, Grenze Gotisch. Kullanıcı site-packages'ı gerekebildiği için `-I` yok.
# Bir adımın çıktısı varsa o adım atlanır (karolar dahil); baştan için klasörü sil.
set -e
W="$(cd "$(dirname "$0")" && pwd)"
K="$1"
R="$2"
[ -n "$K" ] && [ -n "$R" ] || { sed -n 2,14p "$0"; exit 1; }
mkdir -p "$R/full"
cd "$R"
[ -f fields.npz ] || python -X utf8 "$W/zemin/vg_fields.py" "$K" 0 0 4096 fields.npz
[ -f layout_v3.json ] || python -X utf8 "$W/zemin/vg_layout_v3.py" "$K/out/layout_v2.json" fields.npz "$W/atlas/names" layout_v3.json
export CM_FIELDS="$R/fields.npz"
[ -f full/scene.pkl ] || python -X utf8 "$W/cm/cm_full.py" prep fields.npz "$W/atlas/places.json" layout_v3.json full
[ -f full/scene_final.pkl ] || python -X utf8 "$W/cm/cm_full.py" finalize full
[ -f full/roads_clean.npy ] || python -X utf8 "$W/cm/cm_full.py" roads full
# Karolar: Tolkien tepeleri açık, eski kabartma gölgesi kapalı (kapatılmazsa
# dağlar koyu gölge lekesi olarak çıkıyor - ilk yeniden koşturma tam bunu yaptı).
export CM_OUT=2 CM_PEAKS=1 CM_RELIEF=0
for ty in 0 1 2 3; do
  for tx in 0 1 2 3; do
    python -X utf8 "$W/cm/cm_full.py" tile full $tx $ty >> full/tiles.log 2>&1 &
  done
  wait
done
python -X utf8 "$W/cm/cm_full.py" stitch full >> full/tiles.log 2>&1
echo "harita: $R/full/map_16384.png, map_4096.jpg"
