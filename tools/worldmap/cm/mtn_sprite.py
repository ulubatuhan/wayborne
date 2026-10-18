"""Tek bir sıradağ figürü: gerçek yükseklik verisi -> 3B yüzey -> yandan/yukarıdan
ortografik kamera, mürekkep kontur (Freestyle), sonra 3 ton.

    python3 -I mtn_sprite.py <dem.npy> <cx> <cy> <w> <h> <out.png> [elev_deg]
"""
import math
import sys

import bpy
import numpy as np
from scipy import ndimage as ndi


def build(dem_p, cx, cy, w, h, out, elev=38.0, snow=None):
    D = np.load(dem_p).astype(np.float32) if isinstance(dem_p, str) else dem_p
    a = D[cy - h // 2:cy + h // 2, cx - w // 2:cx + w // 2]
    a = ndi.gaussian_filter(a, 0.5)
    yy, xx = np.mgrid[0:h, 0:w]
    r = np.sqrt(((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2)
    fall = np.clip((1.0 - r) / 0.45, 0, 1) ** 1.2
    a = (a - np.percentile(a, 5)) / 1000.0               # km
    z = np.clip(a, 0, None) * fall
    zcut = 0.18 * float(z.max())                         # etek: gerçek yükselti eğrisinden kesilir
    step = 0.09                                          # km / piksel
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    verts = [((x - w / 2) * step, (h / 2 - y) * step, float(z[y, x]) * 3.0) for y in range(h) for x in range(w)]
    faces = [(y * w + x, y * w + x + 1, (y + 1) * w + x + 1, (y + 1) * w + x) for y in range(h - 1) for x in range(w - 1)
             if min(z[y, x], z[y, x + 1], z[y + 1, x], z[y + 1, x + 1]) > zcut]
    me = bpy.data.meshes.new("m")
    me.from_pydata(verts, [], faces)
    me.update()
    for p in me.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new("m", me)
    sc.collection.objects.link(ob)
    mat = bpy.data.materials.new("rock")
    mat.use_nodes = True
    nt = mat.node_tree
    bs = nt.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (0.8, 0.8, 0.8, 1)
    if snow is not None:
        # yüksek yerler bembeyaz; ince-mürekkep dönüşümünde gölgeli kar da açık kalsın diye kırmızı kanala işaret
        geo = nt.nodes.new("ShaderNodeNewGeometry")
        sep = nt.nodes.new("ShaderNodeSeparateXYZ")
        ramp = nt.nodes.new("ShaderNodeValToRGB")
        nt.links.new(geo.outputs["Position"], sep.inputs[0])
        mr = nt.nodes.new("ShaderNodeMapRange")
        zmax = float(z.max()) * 3.0
        mr.inputs[1].default_value = zmax * snow
        mr.inputs[2].default_value = zmax * snow + 0.15
        nt.links.new(sep.outputs["Z"], mr.inputs[0])
        nt.links.new(mr.outputs[0], ramp.inputs[0])
        ramp.color_ramp.elements[0].color = (0.8, 0.8, 0.8, 1)
        ramp.color_ramp.elements[1].color = (1.0, 0.55, 0.55, 1)
        nt.links.new(ramp.outputs[0], bs.inputs["Base Color"])
    mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 1.0
    me.materials.append(mat)
    # ışık: kuzeybatıdan, alçak
    sun = bpy.data.lights.new("s", "SUN")
    sun.energy = 3.0
    sun.angle = math.radians(8)
    so = bpy.data.objects.new("s", sun)
    so.rotation_euler = (math.radians(50), 0, math.radians(-70))
    sc.collection.objects.link(so)
    # kamera: güneyden kuzeye bakar, yatayla elev derece
    cam = bpy.data.cameras.new("c")
    cam.type = "ORTHO"
    cam.ortho_scale = w * step * 1.05
    co = bpy.data.objects.new("c", cam)
    t = math.radians(90 - elev)
    co.rotation_euler = (t, 0, 0)
    co.location = (0, -60 * math.sin(t), 60 * math.cos(t))
    sc.collection.objects.link(co)
    sc.camera = co
    sc.world = bpy.data.worlds.new("w")
    sc.world.color = (1, 1, 1)
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 16
    sc.cycles.device = "CPU"
    sc.render.film_transparent = True
    sc.render.resolution_x = 1200
    sc.render.resolution_y = int(1200 * (h * math.sin(math.radians(elev)) + 30) / w) + 200
    sc.render.use_freestyle = True
    sc.render.line_thickness_mode = "ABSOLUTE"
    sc.render.line_thickness = 1.1
    vl = sc.view_layers[0]
    for old in list(vl.freestyle_settings.linesets):
        vl.freestyle_settings.linesets.remove(old)
    ls = vl.freestyle_settings.linesets.new("l")
    ls.linestyle = bpy.data.linestyles.new("ink")
    ls.select_by_visibility = True
    ls.select_by_edge_types = True
    ls.select_silhouette = True
    ls.select_border = False
    ls.select_crease = True
    vl.freestyle_settings.crease_angle = math.radians(118)
    ls.linestyle.color = (0.02, 0.015, 0.01)
    sc.render.filepath = out
    sc.view_settings.view_transform = "Standard"
    bpy.ops.render.render(write_still=True)


def library(dem_dir, out_dir, n_per=4, seed=3):
    import glob, json, os
    rng = np.random.default_rng(seed)
    os.makedirs(out_dir, exist_ok=True)
    meta = []
    k = 0
    for f in sorted(glob.glob(os.path.join(dem_dir, "*.npy"))):
        if "alaska" in f:
            continue
        D = np.load(f).astype(np.float32)
        # pencere bir doruğun üstüne ortalanır: yumuşatılmış yüksekliğin yerel tepeleri
        hs = ndi.gaussian_filter(D, 12)
        pk = (hs == ndi.maximum_filter(hs, 151))
        pk[:240] = 0; pk[-240:] = 0; pk[:, :240] = 0; pk[:, -240:] = 0
        ys, xs = np.nonzero(pk)
        if not len(xs):
            continue
        for i in range(n_per):
            j = int(rng.integers(len(xs)))
            w = int(rng.integers(80, 120)) * 2; h = int(rng.integers(60, 80)) * 2
            for snow in (None, 0.55):
                name = "m%02d%s" % (k, "s" if snow else "")
                p = os.path.join(out_dir, name + "_raw.png")
                if not os.path.exists(p):
                    build(D, int(xs[j]), int(ys[j]), w, h, p, 38.0, snow)
                meta.append(dict(name=name, w=w, h=h, snow=bool(snow), src=os.path.basename(f)))
            k += 1
    json.dump(meta, open(os.path.join(out_dir, "meta.json"), "w"), indent=1)


if __name__ == "__main__":
    a = sys.argv[1:]
    if a[0] == "lib":
        library(a[1], a[2])
    else:
        build(a[0], int(a[1]), int(a[2]), int(a[3]), int(a[4]), a[5], float(a[6]) if len(a) > 6 else 38.0)
