"""Yeni bir klibi oyundaki bütün bedenlere ve giysilere ekler (2026-11-01).

    python3 -I tools/figure_pipeline/add_clip.py --clip sit_fire [--jobs 4] [--no-pack]

Sıra: beden varyantı (make_variant), beden render'ı (render_frames), giysiler
(render_outfits, bir bedenin bütün kalemleri tek süreçte), sonra paket
(append_clips). Neden tek süreçte: ölçüm, süreç başına kurulum ~2,5 dk, kalem
başına render ~1 sn; kalem kalem çağırmak 13 saat, beden başına çağırmak
dakikalar. Bedenler `--jobs` işçiyle paralel (giydirme tek çekirdekte koşar).
Biten iş (çıktı klasörü dolu) atlanır: yarıda kesilirse yeniden çalıştırmak
kaldığı yerden sürdürür. Blender: setup_blender.sh (/root/bpyenv).
"""
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
BPY = os.environ.get("WAYBORNE_BPY", "/root/bpyenv/bin/python")
FRAMES = os.path.join(ROOT, "data", "assets", "characters", "frames")
ENV = dict(os.environ, WAYBORNE_ROOT=ROOT)


def arg(name, default=None):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else default


def items_for(variant):
    """Oyunda o bedene paketlenmiş kalemler (HD olmayan kümeler)."""
    suffix = "_" + variant
    return sorted(d[len("outfit_"):-len(suffix)] for d in os.listdir(FRAMES)
                  if d.startswith("outfit_") and d.endswith(suffix))


def run(cmd, log):
    with open(log, "a") as f:
        return subprocess.run(cmd, cwd=ROOT, env=ENV, stdout=f, stderr=subprocess.STDOUT).returncode


def do_variant(variant, clip, logdir):
    log = os.path.join(logdir, variant + ".log")
    blend = os.path.join(ROOT, "build", "figures", "variants", variant, variant + ".blend")
    if not os.path.exists(blend):
        run([BPY, os.path.join(PIPE, "blender", "make_variant.py"), os.path.join(PIPE, "config", "variants", variant + ".json")], log)
    if not os.path.isdir(os.path.join(ROOT, "build", "figures", "out", variant, clip, "f00")):
        run([BPY, os.path.join(PIPE, "blender", "render_frames.py"), "--variant", variant, "--clip", clip], log)
    todo = [it for it in items_for(variant)
            if not os.path.isdir(os.path.join(ROOT, "build", "figures", "outfits", variant, it, clip, "f00"))]
    if todo:
        run([BPY, os.path.join(PIPE, "blender", "render_outfits.py"), "--variant", variant,
             "--items", ",".join(todo), "--clips", clip], log)
    left = [it for it in items_for(variant)
            if not os.path.isdir(os.path.join(ROOT, "build", "figures", "outfits", variant, it, clip, "f00"))]
    print("%s: %d kalem, eksik %d %s" % (variant, len(items_for(variant)), len(left), left[:5]), flush=True)
    return variant, left


def main():
    clip = arg("--clip")
    jobs = int(arg("--jobs", "4"))
    build = json.load(open(os.path.join(PIPE, "config", "build.json")))
    variants = [v for v in build["variants"] if os.path.isdir(os.path.join(FRAMES, "body_" + v))]
    logdir = os.path.join(ROOT, "build", "figures", "logs", "add_clip_" + clip)
    os.makedirs(logdir, exist_ok=True)
    with ThreadPoolExecutor(jobs) as pool:
        results = list(pool.map(lambda v: do_variant(v, clip, logdir), variants))
    if any(left for _v, left in results):
        print("eksik kalem var; paketleme yine yapılır, eksik kalemin kümesi değişmez (append_clips)")
    if "--no-pack" not in sys.argv:
        subprocess.run([sys.executable, "-I", os.path.join(PIPE, "mesh", "append_clips.py"), "--clips", clip,
                        "--variants", ",".join(variants)], cwd=ROOT, env=ENV, check=True)
    print("bitti:", clip, variants)


if __name__ == "__main__":
    main()
