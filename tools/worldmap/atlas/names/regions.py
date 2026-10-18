"""Kullanıcının çizdiği kültür bölgeleri (ekran koordinatı 1932 px; harita = x * 2.1299)."""
import json
import math

K = 1.04 * 2.048
REG = {
    "dag_k": [(105,60),(250,5),(480,5),(560,60),(570,185),(400,220),(150,230),(100,150)],
    "dag_ke": [(1240,120),(1400,80),(1560,170),(1620,320),(1600,500),(1500,590),(1420,580),(1350,470),(1320,330),(1330,130)],
    "gocebe": [(140,300),(330,230),(500,280),(580,430),(590,620),(560,840),(450,870),(300,800),(180,740),(110,620),(90,450)],
    "imparatorluk": [(720,140),(870,100),(1050,130),(1200,280),(1290,450),(1310,600),(1250,700),(1100,760),(900,740),(780,660),(680,520),(645,360),(680,200)],
    "sinir_d": [(1330,760),(1420,710),(1540,730),(1590,830),(1560,920),(1460,950),(1360,910),(1310,830)],
    "sinir_b": [(440,950),(600,900),(730,920),(785,1000),(760,1090),(650,1130),(520,1100),(430,1020)],
    "vadi": [(1030,930),(1170,910),(1260,980),(1330,1150),(1360,1380),(1340,1580),(1270,1670),(1150,1690),(1040,1620),(970,1480),(960,1250),(980,1050)],
    "ahit": [(1505 + 110 * math.cos(a / 12 * 2 * math.pi), 1090 + 110 * math.sin(a / 12 * 2 * math.pi)) for a in range(12)],
    "maden": [(1640,960),(1760,940),(1830,1000),(1800,1130),(1700,1330),(1610,1530),(1530,1660),(1490,1640),(1520,1450),(1580,1250),(1620,1080)],
    "guney_b": [(780,1450),(950,1480),(1150,1560),(1310,1630),(1360,1760),(1330,1900),(1200,1932),(800,1932),(700,1850),(690,1650),(720,1520)],
    "guney_d": [(1640,1560),(1780,1530),(1880,1600),(1932,1932),(1580,1932),(1610,1760),(1670,1660)],
}
CULT = {"dag_k": "dag", "dag_ke": "dag", "maden": "dag_maden", "gocebe": "gocebe", "imparatorluk": "imparatorluk",
        "sinir_d": "sinir", "sinir_b": "sinir", "vadi": "vadi", "ahit": "ahit", "guney_b": "guney", "guney_d": "guney"}
ORDER = ["ahit", "sinir_d", "sinir_b", "dag_k", "dag_ke", "maden", "gocebe", "imparatorluk", "vadi", "guney_b", "guney_d"]


def inside(pt, poly):
    x, y = pt
    c = False
    for (x1, y1), (x2, y2) in zip(poly, poly[1:] + poly[:1]):
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            c = not c
    return c


def seg_dist(p, a, b):
    ax, ay = a; bx, by = b; px, py = p
    dx, dy = bx - ax, by - ay
    t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy + 1e-9)))
    return math.hypot(px - ax - t * dx, py - ay - t * dy)


def region_of(mx, my):
    p = (mx / K, my / K)
    hits = [r for r in ORDER if inside(p, REG[r])]
    if "vadi" in hits and "guney_b" in hits:
        hits = ["guney_b"] if p[1] > 1560 else ["vadi"]
    if hits:
        return hits[0], True
    best = min(REG, key=lambda r: min(seg_dist(p, a, b) for a, b in zip(REG[r], REG[r][1:] + REG[r][:1])))
    return best, False
