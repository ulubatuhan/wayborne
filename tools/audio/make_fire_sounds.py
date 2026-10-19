"""Kamp ateşinin iki sesi, gerçek kayıt yerine üretilir (görev 12.2c).

    python -I tools/audio/make_fire_sounds.py

- `data/assets/audio/fire_crackle.wav`: 8 sn, kesintisiz dönen çıtırtı. Kahverengi
  gürültüden boğuk bir uğultu, üstünde rastgele çıtırtılar (kısa, sönümlü gürültü
  patlamaları) ve arada bir odun çatlaması. Döngünün iki ucu birbirine karışır,
  dikiş duyulmaz.
- `data/assets/audio/fire_ignite.wav`: 0,9 sn tutuşma: alçalan gürültü süpürmesi
  ve iki çıtırtı.

Diğer yer tutucu seslerle aynı yol (`wave` + sinüs/gürültü, harici araç yok,
tohumlu): gerçek bir CC0 kayıt gelince dosya değiştirilir, kod değişmez
(`AudioManager`). Künye: `data/assets/audio/KUNYE.tsv`.
"""
import math
import os
import random
import struct
import wave

RATE = 22050
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "assets", "audio")


def brown(n, rng, alpha=0.02):
    out, v = [], 0.0
    for _ in range(n):
        v = (v + rng.uniform(-1, 1) * alpha) * 0.998
        out.append(v)
    peak = max(abs(x) for x in out) or 1.0
    return [x / peak for x in out]


def lowpass(xs, k):
    out, v = [], 0.0
    for x in xs:
        v += (x - v) * k
        out.append(v)
    return out


def add_crackle(buf, at, rng, length_s, loud):
    n = int(length_s * RATE)
    decay = rng.uniform(80.0, 260.0)
    hp, prev = 0.0, 0.0
    for i in range(n):
        j = at + i
        if j >= len(buf):
            j -= len(buf)  # döngü: sona taşan çıtırtı başa sarar
        x = rng.uniform(-1, 1)
        hp = 0.6 * (hp + x - prev)  # yüksek geçiren: kuru, keskin
        prev = x
        buf[j] += hp * loud * math.exp(-decay * i / RATE)


def write(path, xs):
    peak = max(abs(x) for x in xs) or 1.0
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, x / peak * 0.85)) * 32767)) for x in xs))


def crackle_loop(seconds=8.0, seed=11):
    rng = random.Random(seed)
    n = int(seconds * RATE)
    base = lowpass(brown(n, rng), 0.08)
    buf = [b * 0.35 for b in base]
    t = 0.0
    while t < seconds:
        t += rng.expovariate(9.0)
        add_crackle(buf, int(t * RATE) % n, rng, rng.uniform(0.004, 0.02), rng.uniform(0.15, 0.6))
    t = 0.0
    while t < seconds:
        t += rng.expovariate(0.6)  # seyrek, büyük çatlama
        add_crackle(buf, int(t * RATE) % n, rng, rng.uniform(0.03, 0.06), rng.uniform(0.7, 1.0))
    # uçları karıştır: ilk ve son 0,2 sn'yi çaprazla ki döngü dikişsiz olsun
    m = int(0.2 * RATE)
    for i in range(m):
        a = i / m
        buf[i] = buf[i] * a + buf[n - m + i] * (1 - a)
    return buf[: n - m]


def ignite(seed=7):
    rng = random.Random(seed)
    n = int(0.9 * RATE)
    noise = [rng.uniform(-1, 1) for _ in range(n)]
    out = []
    v = 0.0
    for i, x in enumerate(noise):
        u = i / n
        k = 0.02 + 0.3 * (1 - u) ** 2  # süpürme: parlaktan boğuğa
        v += (x - v) * k
        env = math.sin(math.pi * min(1.0, u * 1.6)) * (1 - u) ** 0.5
        out.append(v * env)
    add_crackle(out, int(0.25 * RATE), rng, 0.02, 0.5)
    add_crackle(out, int(0.5 * RATE), rng, 0.015, 0.35)
    return out


if __name__ == "__main__":
    write(os.path.join(OUT, "fire_crackle.wav"), crackle_loop())
    write(os.path.join(OUT, "fire_ignite.wav"), ignite())
    print("yazildi: fire_crackle.wav, fire_ignite.wav")
