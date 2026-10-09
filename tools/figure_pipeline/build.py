"""Figur hattinin tek komutu (Faz 6): klipleri disa aktar, eskiyen kareleri
render et, oyunun kare kumelerini paketle, testleri kos.

    python3 -I tools/figure_pipeline/build.py --all [--jobs 2] [--no-magenta]
    python3 -I tools/figure_pipeline/build.py --variants male_average --clips walk

Artimli: bir kare, joints.json'u kendi girdilerinin (config/*.json, varyantin
.blend'i, klip JSON'u, render betikleri) hepsinden yeniyse yeniden render
edilmez. Bir girdi degisirse yalniz ona bagli kareler yeniden uretilir.
"""
import glob
import json
import os
import subprocess
import sys
import time

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
OUT = os.path.join(ROOT, "build", "figures", "out")
CLIPS = os.path.join(ROOT, "build", "figures", "clips")
GODOT = os.environ.get("GODOT", "/tmp/Godot_v4.2.2-stable_linux.x86_64")
RENDER_INPUTS = [os.path.join(PIPE, "blender", n) for n in
                 ("render_frames.py", "render_clip.py", "fig_shading.py", "fig_weights.py")]


def arg(name, default=None):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else default


def mtime(path):
    return os.path.getmtime(path) if os.path.exists(path) else 0.0


def export_clips():
    rig = os.path.join(ROOT, "scripts", "character", "figure_rig.gd")
    newest_in = max(mtime(rig), mtime(os.path.join(PIPE, "config", "build.json")),
                    mtime(os.path.join(PIPE, "godot", "export_clips.gd")))
    outs = glob.glob(os.path.join(CLIPS, "*.json"))
    if outs and min(mtime(p) for p in outs) > newest_in:
        return
    subprocess.run([GODOT, "--headless", "--path", ROOT, "--script",
                    "res://tools/figure_pipeline/godot/export_clips.gd"], check=True,
                   stdout=subprocess.DEVNULL)


def stale_frames(variant, clip, n, magenta):
    deps = RENDER_INPUTS + glob.glob(os.path.join(PIPE, "config", "*.json"))
    deps += [os.path.join(ROOT, "build", "figures", "variants", variant, variant + ".blend"),
             os.path.join(CLIPS, clip + ".json")]
    newest = max(mtime(p) for p in deps)
    out = []
    for i in range(n):
        d = os.path.join(OUT, variant, clip, "f%02d" % i)
        done = mtime(os.path.join(d, "joints.json")) > newest
        if magenta and not os.path.exists(os.path.join(d, "magenta_front_arm.png")) \
                and not os.path.exists(os.path.join(d, "magenta_front_leg.png")):
            done = False
        if not done:
            out.append(i)
    return out


def main():
    build = json.load(open(os.path.join(PIPE, "config", "build.json")))
    variants = build["variants"] if "--all" in sys.argv else arg("--variants", "").split(",")
    clips = list(build["clips"]) if "--all" in sys.argv or "--clips" not in sys.argv else arg("--clips").split(",")
    jobs = int(arg("--jobs", "2"))
    magenta = "--no-magenta" not in sys.argv
    export_clips()
    todo = []
    mags = {}
    for v in variants:
        if not os.path.exists(os.path.join(ROOT, "build", "figures", "variants", v, v + ".blend")):
            subprocess.run([sys.executable, os.path.join(PIPE, "blender", "make_variant.py"),
                            os.path.join(PIPE, "config", "variants", v + ".json")], check=True)
        for c in clips:
            want_mag = magenta and build["clips"][c].get("magenta", True) \
                and v in build.get("magenta_variants", [v])
            frames = stale_frames(v, c, int(build["clips"][c]["frames"]), want_mag)
            mags[(v, c)] = want_mag
            if frames:
                todo.append((v, c, frames))
    print("render edilecek:", sum(len(f) for _, _, f in todo), "kare", [(v, c, len(f)) for v, c, f in todo],
          flush=True)
    running = []
    t0 = time.time()
    logdir = os.path.join(ROOT, "build", "figures", "logs")
    os.makedirs(logdir, exist_ok=True)
    while todo or running:
        while todo and len(running) < jobs:
            v, c, frames = todo.pop(0)
            cmd = [sys.executable, "-I", os.path.join(PIPE, "blender", "render_frames.py"),
                   "--variant", v, "--clip", c, "--frames", ",".join(map(str, frames))]
            if mags[(v, c)]:
                cmd.append("--magenta")
            log = open(os.path.join(logdir, "%s_%s.log" % (v, c)), "w")
            running.append(((v, c), subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)))
        time.sleep(2)
        for item in list(running):
            (v, c), p = item
            if p.poll() is not None:
                running.remove(item)
                print("%s/%s bitti (cikis %d) %.0f sn" % (v, c, p.returncode, time.time() - t0), flush=True)
                if p.returncode != 0:
                    raise SystemExit("render basarisiz: %s/%s - build/figures/logs" % (v, c))
    subprocess.run([sys.executable, "-I", os.path.join(PIPE, "mesh", "pack_frames.py"),
                    "--variants", ",".join(variants)], check=True)


if __name__ == "__main__":
    main()
