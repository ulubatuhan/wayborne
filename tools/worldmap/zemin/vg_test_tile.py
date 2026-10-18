"""Tek bölge deneme render: python3 -I vg_test_tile.py <vgf> <layout> <x0> <y0> <size> <out> <res>"""
import json, os, subprocess, sys
import numpy as np
from PIL import Image
vgf, layout, x0, y0, size, out, res = sys.argv[1], sys.argv[2], *map(int, sys.argv[3:6]), sys.argv[6], int(sys.argv[7])
HERE = os.path.dirname(os.path.abspath(__file__))
os.makedirs(out, exist_ok=True)
f = np.load(os.path.join(vgf, "fields.npz"))
crop = {k: f[k][y0:y0+size, x0:x0+size] for k in f.files if f[k].ndim == 2 and f[k].shape == (4096, 4096)}
np.savez_compressed(os.path.join(out, "fields.npz"), x0=x0, y0=y0, size=size, **crop)
A = Image.open(os.path.join(vgf, "albedo_full.png"))
A.crop((int(x0*1.25), int(y0*1.25), int((x0+size)*1.25), int((y0+size)*1.25))).save(os.path.join(out, "albedo.png"))
t = np.array(json.load(open(os.path.join(vgf, "trees_full.json"))), np.float32)
sel = (t[:,0]>=x0)&(t[:,0]<x0+size)&(t[:,1]>=y0)&(t[:,1]<y0+size)
json.dump([[float(a-x0), float(b-y0), int(c)] for a,b,c in t[sel]], open(os.path.join(out, "trees.json"), "w"))
env = dict(os.environ, VG_CAM_SCALE=str(size))
if not os.path.exists(os.path.join(out, "albedo_r.png")):
  subprocess.run([sys.executable, "-I", os.path.join(HERE, "vg_ink_scene.py"), out, layout, "16", str(res)], env=env, check=True)
subprocess.run([sys.executable, "-I", os.path.join(HERE, "vg_ink_post.py"), out, layout, os.path.join(out, "map.png")], check=True)
