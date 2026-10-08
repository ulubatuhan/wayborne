#!/bin/sh
# Faz 1 kapi hazirligi: render'dan sonra her seyi sirayla uretir.
#   sh tools/figure_pipeline/qa/gate_faz1.sh
set -e
# Godot ikilisi PATH'te yok; GODOT ile degistirilebilir.
cd /home/user/wayborne
P=tools/figure_pipeline
python3 -I $P/mesh/posterize.py
python3 -I $P/mesh/build_atlas.py --src frames
python3 -I $P/mesh/build_atlas.py --src flat
for v in "" flat; do
  LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" \
    ${GODOT:-/tmp/Godot_v4.2.2-stable_linux.x86_64} --path . --rendering-driver opengl3 \
    --script res://$P/godot/capture_player.gd -- $v 2>&1 | grep -E "yakalandi|ERROR|SCRIPT" || true
done
python3 -I $P/qa/run_faz1.py
python3 -I $P/qa/run_faz1.py --src flat
python3 -I $P/qa/walk_gif.py
