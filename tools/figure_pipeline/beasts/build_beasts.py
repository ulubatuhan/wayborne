"""Hayvan hattinin tek komutu: eksik ya da eskimis turleri render et, paketle.

    python3 -I tools/figure_pipeline/beasts/build_beasts.py [--species horse,wolf] [--jobs 1]

Artimli, insan hattinin build.py'si gibi: bir turun kareleri, kendi
girdilerinin (bu klasordeki betikler + beasts.json + ortak golgelendirme +
model dosyasi) hepsinden yeniyse yeniden render edilmez.
"""
import glob
import json
import os
import subprocess
import sys
import time

ROOT = "/home/user/wayborne"
PIPE = os.path.join(ROOT, "tools", "figure_pipeline")
HERE = os.path.join(PIPE, "beasts")
OUT = os.path.join(ROOT, "build", "beasts", "out")
MODELS = os.path.join(ROOT, "art_source", "models", "animals")


def mtime(p):
    return os.path.getmtime(p) if os.path.exists(p) else 0.0


def stale(species, cfg):
    deps = glob.glob(os.path.join(HERE, "*.py")) + [os.path.join(HERE, "beasts.json"),
                                                   os.path.join(PIPE, "blender", "fig_shading.py"),
                                                   os.path.join(MODELS, cfg["species"][species]["model"])]
    newest = max(mtime(p) for p in deps if not p.endswith("pack_beasts.py") and not p.endswith("build_beasts.py"))
    for clip, c in cfg["clips"].items():
        for i in range(int(c["frames"])):
            if mtime(os.path.join(OUT, species, clip, "f%02d" % i, "joints.json")) <= newest:
                return True
    return False


def main():
    cfg = json.load(open(os.path.join(HERE, "beasts.json")))
    species = list(cfg["species"])
    if "--species" in sys.argv:
        species = sys.argv[sys.argv.index("--species") + 1].split(",")
    jobs = int(sys.argv[sys.argv.index("--jobs") + 1]) if "--jobs" in sys.argv else 1
    todo = [s for s in species if stale(s, cfg)]
    print("render edilecek turler:", todo, flush=True)
    logdir = os.path.join(ROOT, "build", "beasts", "logs")
    os.makedirs(logdir, exist_ok=True)
    running = []
    t0 = time.time()
    while todo or running:
        while todo and len(running) < jobs:
            s = todo.pop(0)
            log = open(os.path.join(logdir, s + ".log"), "w")
            running.append((s, subprocess.Popen([sys.executable, "-I", os.path.join(HERE, "render_beast.py"),
                                                 "--species", s], stdout=log, stderr=subprocess.STDOUT)))
        time.sleep(2)
        for item in list(running):
            s, p = item
            if p.poll() is not None:
                running.remove(item)
                print("%s bitti (cikis %d) %.0f sn" % (s, p.returncode, time.time() - t0), flush=True)
                if p.returncode != 0:
                    raise SystemExit("render basarisiz: %s - build/beasts/logs" % s)
    subprocess.run([sys.executable, "-I", os.path.join(HERE, "pack_beasts.py"), "--species", ",".join(species)],
                   check=True)


if __name__ == "__main__":
    main()
