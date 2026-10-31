"""Sessizlik anlarının beden sesleri, gerçek kayıt yerine üretilir (görev Y-H08).

    python -I tools/audio/make_body_sounds.py

Bir feda kararından sonra müzik ve ortam sesi kesilir, yalnızca bunlar duyulur:
- `body/step_%d.wav` (3): toprakta ağır bir adım, boğuk düşük gürültü patlaması.
- `body/breath_%d.wav` (2): yavaş bir nefes, süzülmüş gürültünün kabarıp sönmesi.
- `body/crawl_%d.wav` (2): toprağa sürtünen beden, kısa sürtünme dizisi.

`make_fire_sounds.py` ile aynı yol (`wave` + gürültü, harici araç yok, tohumlu).
Gerçek bir CC0 kayıt gelince dosya değiştirilir, kod değişmez. Künye: `KUNYE.tsv`.
"""
import math
import os
import random
import struct
import wave

RATE = 22050
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "assets", "audio", "body")


def lowpass(samples, k):
    out, v = [], 0.0
    for s in samples:
        v += (s - v) * k
        out.append(v)
    return out


def write(name, samples, gain):
    peak = max(1e-6, max(abs(s) for s in samples))
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(32767 * gain * s / peak)) for s in samples))


def step(rng):
    n = int(RATE * 0.22)
    noise = lowpass([rng.uniform(-1, 1) for _ in range(n)], 0.06)
    return [noise[i] * math.exp(-i / (RATE * 0.045)) for i in range(n)]


def breath(rng):
    n = int(RATE * 1.6)
    noise = lowpass([rng.uniform(-1, 1) for _ in range(n)], 0.18)
    return [noise[i] * math.sin(math.pi * i / n) ** 2 for i in range(n)]


def crawl(rng):
    n = int(RATE * 0.9)
    noise = lowpass([rng.uniform(-1, 1) for _ in range(n)], 0.35)
    return [noise[i] * (0.4 + 0.6 * abs(math.sin(7.0 * math.pi * i / n))) * math.sin(math.pi * i / n) for i in range(n)]


def main():
    os.makedirs(OUT, exist_ok=True)
    for k in range(3):
        write("step_%d.wav" % k, step(random.Random(100 + k)), 0.55)
    for k in range(2):
        write("breath_%d.wav" % k, breath(random.Random(200 + k)), 0.35)
        write("crawl_%d.wav" % k, crawl(random.Random(300 + k)), 0.4)


if __name__ == "__main__":
    main()
