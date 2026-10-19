# -*- coding: utf-8 -*-
"""Elle yazılmış sayfası olmayan olaylar için otomatik karar ağacı (görev Y-E07).

Kaynak: events_export.json - Godot'un kendisi yazar
(`godot --headless --script res://tests/export_codex_events.gd`), yani GDScript
Python'dan ayrıştırılmaz. codex_events_data.py'deki elle yazılmış sayfalar
önceliklidir (tasarım notları onlarda); burada üretilen sayfa yalnızca
katalogda olup codex'te olmayan olayları kapatır, böylece Codex katalogla eşit
kalır.
"""

import json
import os
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))
EXPORT_PATH = os.path.join(HERE, "events_export.json")

OP_TEXT = {
    "GREATER_EQUAL": "≥", "LESS_EQUAL": "≤", "EQUAL": "=", "NOT_EQUAL": "≠",
    "LESS_THAN": "<", "GREATER_THAN": ">",
}
STAT_TEXT = {
    "STRENGTH": "Güç", "AGILITY": "Çeviklik", "ENDURANCE": "Dayanıklılık", "INTELLECT": "Zeka",
    "PERCEPTION": "Sezgi", "CHARISMA": "Karizma", "WISDOM": "Bilgelik", "FAITH": "İnanç",
}


def _num(v):
    return str(int(v)) if float(v).is_integer() else f"{v:g}"


def _condition_text(c):
    op = c["op"]
    if op == "HAS_FLAG":
        return f"<b>{c['key']}</b> bayrağı var"
    if op == "NOT_HAS_FLAG":
        return f"<b>{c['key']}</b> bayrağı yok"
    return f"<b>{c['key']}</b> {OP_TEXT.get(op, op)} {_num(c['value'])}"


def _conditions(conds):
    return ", ".join(_condition_text(c) for c in conds)


def _effects(effects):
    out = []
    for e in effects:
        if e.get("text"):
            out.append((e["type"], int(e["amount"]), e["text"]))
        else:
            out.append((e["type"], int(e["amount"])))
    return out


def _trigger(ev):
    parts = []
    if ev["triggered_only"]:
        parts.append("Yalnızca bir zincirle açılır (<b>UNLOCK_EVENT</b>).")
    if ev["conditions"]:
        parts.append("Koşul: " + _conditions(ev["conditions"]) + ".")
    elif not ev["triggered_only"]:
        parts.append("Koşulsuz - her gün havuzda.")
    if ev.get("modifiers"):
        parts.append(f"{ev['modifiers']} ağırlık çarpanı var (duraklar, görevler ya da durum).")
    return " ".join(parts)


def _option(ch):
    label = escape(ch["label"])
    if ch.get("check"):
        stat = STAT_TEXT.get(ch["check"]["stat"], ch["check"]["stat"])
        label += f" <font color='#7A7263'>({stat} zarı, zorluk {_num(ch['check']['difficulty'])})</font>"
    opt = {"label": label, "effects": _effects(ch["effects"])}
    if ch["requirements"]:
        opt["condition"] = _conditions(ch["requirements"])
        opt["locked"] = escape(ch.get("locked") or "Koşul tutmuyor")
    outs = []
    for o in ch["outcomes"]:
        entry = {"label": escape(o["label"]), "weight": _num(o["weight"]), "effects": _effects(o["effects"])}
        if o["conditions"]:
            entry["condition"] = _conditions(o["conditions"])
        outs.append(entry)
    if outs:
        opt["outcomes"] = outs
    return opt


def auto_events(known_ids):
    """Katalogda olup elle yazılmamış olayların sayfa sözlükleri."""
    if not os.path.exists(EXPORT_PATH):
        return []
    with open(EXPORT_PATH, encoding="utf-8") as f:
        data = json.load(f)
    out = []
    for ev in data.get("events", []):
        if ev["id"] in known_ids:
            continue
        page = {
            "id": ev["id"], "title": escape(ev["title"]), "weight": _num(ev["weight"]),
            "cooldown": int(ev["cooldown"]),
            "repeat": "bir kez" if ev["once"] else "sınırsız",
            "kind": "Yol · zincir" if ev["triggered_only"] else "Yol",
            "flavor": escape(ev["text"]).replace(chr(10), "<br/>"),
            "trigger": _trigger(ev),
            "options": [_option(ch) for ch in ev["choices"]],
            "note": "Bu sayfa katalogdan otomatik üretildi (tests/export_codex_events.gd). "
                    "Tasarım notu elle yazıldığında codex_events_data.py'ye taşınır.",
        }
        if ev["immediate"]:
            page["immediate"] = _effects(ev["immediate"])
        out.append(page)
    return out


def catalog_ids():
    if not os.path.exists(EXPORT_PATH):
        return None
    with open(EXPORT_PATH, encoding="utf-8") as f:
        return [ev["id"] for ev in json.load(f).get("events", [])]
