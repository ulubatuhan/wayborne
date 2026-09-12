# -*- coding: utf-8 -*-
"""Olay ağacı sayfaları: bir olayın tetiklenmesinden sonuçlarına kadar."""

from reportlab.lib import colors
from reportlab.platypus import Table, TableStyle, Paragraph, Spacer, KeepTogether
from codex_base import (
    S, INK, INK_SOFT, MUTED, GOLD, GOLD_PALE, PARCH, RULE, RED, GREEN, BLUE,
    ROW_ALT, para, sp, HRule, ColorBar, table,
)

# Etki tipinin okunur adı ve işareti
EFFECT_LABEL = {
    "GOLD": "Kese", "PROVISIONS": "Erzak", "MORALE": "Moral", "STRESS": "Stres",
    "REPUTATION": "İtibar", "DANGER": "Tehlike", "TRAVEL_DAYS": "Yol günü",
    "WAGON_DAMAGE": "Vagon hasarı", "WAGON_LOSE": "VAGON KAYBI",
    "WAGON_REPAIR": "Vagon onarımı", "MERCHANT_LEAVE": "Tüccar ayrılır",
    "DOCUMENT_LOSE": "Evrak kaybı", "ITEM_ADD": "Mal", "ITEM_REMOVE": "Mal kaybı",
    "SET_FLAG": "Bayrak kur", "CLEAR_FLAG": "Bayrak sil",
    "UNLOCK_EVENT": "Zincir açar", "TRIGGER_COMBAT": "SAVAŞ AÇILIR",
    "TRIGGER_HAGGLING": "PAZARLIK AÇILIR", "TRIGGER_RECRUIT": "TAYFA EKRANI",
    "GRANT_TRAIT": "Huy verir", "GRANT_EQUIPMENT": "Ekipman verir",
    "MARKET_SHOCK": "Fiyat şoku", "ROUTE_CHANGE": "Yol durumu",
    "ROLL_ENCOUNTER": "Mizaç yuvarlanır",
}

# Etkinin oyuncu için iyi mi kötü mü olduğu - renklendirme için
GOOD = {"GOLD+", "PROVISIONS+", "MORALE+", "STRESS-", "REPUTATION+", "DANGER-",
        "TRAVEL_DAYS-", "WAGON_REPAIR", "ITEM_ADD", "GRANT_EQUIPMENT"}
BAD = {"GOLD-", "PROVISIONS-", "MORALE-", "STRESS+", "REPUTATION-", "DANGER+",
       "TRAVEL_DAYS+", "WAGON_DAMAGE", "WAGON_LOSE", "MERCHANT_LEAVE",
       "DOCUMENT_LOSE", "ITEM_REMOVE", "GRANT_TRAIT"}


def fx(kind, amount=0, note=""):
    """Tek bir etkiyi renkli metne çevirir."""
    label = EFFECT_LABEL.get(kind, kind)
    sign_key = kind + ("+" if amount > 0 else "-" if amount < 0 else "")
    if sign_key in GOOD or kind in GOOD:
        col = GREEN
    elif sign_key in BAD or kind in BAD:
        col = RED
    elif kind.startswith("TRIGGER") or kind in ("ROLL_ENCOUNTER", "UNLOCK_EVENT"):
        col = BLUE
    else:
        col = MUTED

    if amount:
        txt = f"{label} {amount:+d}"
    else:
        txt = label
    if note:
        txt += f" <font color='#7A7263'>({note})</font>"
    return f"<font color='{col.hexval()[2:]}'>{txt}</font>".replace("#", "")


# Bu etkilerde sayı bir "delta" değil bir ADETTİR: "VAGON KAYBI +1" yanlış
# okunuyor (bir vagon kazanmış gibi), doğrusu "VAGON KAYBI ×1".
COUNT_EFFECTS = {
    "WAGON_DAMAGE", "WAGON_LOSE", "WAGON_REPAIR", "MERCHANT_LEAVE",
    "DOCUMENT_LOSE", "ITEM_ADD", "ITEM_REMOVE", "TRAVEL_DAYS_COUNT",
}


def _effline(effects, has_outcomes=False):
    """Etki listesini tek satıra dizer."""
    parts = []
    for e in effects:
        kind = e[0]
        amount = e[1] if len(e) > 1 else 0
        note = e[2] if len(e) > 2 else ""
        label = EFFECT_LABEL.get(kind, kind)
        sign_key = kind + ("+" if amount > 0 else "-" if amount < 0 else "")
        if sign_key in GOOD or kind in GOOD:
            col = "#4A6B45"
        elif sign_key in BAD or kind in BAD:
            col = "#8E3B2F"
        elif kind.startswith("TRIGGER") or kind in ("ROLL_ENCOUNTER", "UNLOCK_EVENT"):
            col = "#3F5B77"
        else:
            col = "#7A7263"
        if not amount:
            txt = label
        elif kind in COUNT_EFFECTS:
            txt = f"{label} ×{abs(amount)}" if abs(amount) != 1 else label
        else:
            txt = f"{label} {amount:+d}"
        if note:
            txt += f" · {note}"
        parts.append(f'<font color="{col}">{txt}</font>')
    if parts:
        return "   ".join(parts)
    # Garanti etkisi olmayan bir seçenek: sonuç tablosuna dallanıyordur.
    if has_outcomes:
        return '<font color="#7A7263">→ sonuç tablosuna dallanır</font>'
    return '<font color="#7A7263">etki yok</font>'


def _meta_strip(items):
    """Olayın üstündeki küçük künye şeridi."""
    cells = []
    for k, v in items:
        cells.append(Paragraph(
            f'<font color="#7A7263" size="7">{k}</font><br/>'
            f'<font color="#23201B" size="8.4"><b>{v}</b></font>', S["cell"]))
    t = Table([cells], colWidths=[None] * len(cells))
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F2EEE3")),
        ("BOX", (0, 0), (-1, -1), 0.4, RULE),
        ("INNERGRID", (0, 0), (-1, -1), 0.4, RULE),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ]))
    return t


def _branch(label, effects, weight=None, condition=None, locked=None,
            kind="opt", has_outcomes=False):
    """Bir seçenek ya da sonuç dalı - solunda renkli bant."""
    accent = {"opt": INK, "out": GOLD, "chain": BLUE}.get(kind, INK)
    inner = []

    head = f"<b>{label}</b>"
    if weight is not None:
        head += f'  <font color="#7A7263" size="7.6">ağırlık {weight}</font>'
    inner.append(Paragraph(head, S["opt"] if kind == "opt" else S["out"]))

    if condition:
        inner.append(Paragraph(
            f'<font color="#3F5B77" size="7.8">koşul: {condition}</font>', S["cell"]))
    if locked:
        inner.append(Paragraph(
            f'<font color="#8E3B2F" size="7.8">kilitliyken: “{locked}”</font>', S["cell"]))

    inner.append(Paragraph(_effline(effects, has_outcomes), S["eff"]))

    t = Table([[inner]], colWidths=[None])
    t.setStyle(TableStyle([
        ("LINEBEFORE", (0, 0), (0, -1), 2.2, accent),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ]))
    return t


def _nested(flow, indent=14):
    """Bir dalı içeri girintiler (sonuçlar seçeneğin altına)."""
    t = Table([["", flow]], colWidths=[indent, None])
    t.setStyle(TableStyle([
        ("LEFTPADDING", (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (-1, -1), 0),
        ("TOPPADDING", (0, 0), (-1, -1), 0),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 0),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ]))
    return t


def event_page(ev):
    """Bir olayın tam sayfası: künye, anlatı, tetikleme, seçenek ağacı, tasarım notu."""
    out = []
    out.append(Paragraph(ev["title"], S["evt_title"]))
    out.append(Paragraph(ev["id"], S["evt_id"]))
    out.append(ColorBar(height=1.6, color=GOLD))
    out.append(sp(6))

    meta = [("Ağırlık", str(ev["weight"]))]
    meta.append(("Bekleme", f"{ev['cooldown']} gün" if ev.get("cooldown") else "yok"))
    meta.append(("Tekrar", ev.get("repeat", "sınırsız")))
    meta.append(("Tür", ev.get("kind", "Yol")))
    out.append(_meta_strip(meta))
    out.append(sp(7))

    if ev.get("flavor"):
        out.append(Paragraph(ev["flavor"], S["evt_flavor"]))
        out.append(sp(2))

    out.append(Paragraph("Ne zaman çıkar", S["h3"]))
    out.append(Paragraph(ev["trigger"], S["body"]))

    if ev.get("immediate"):
        out.append(Paragraph("Kart açılır açılmaz", S["h3"]))
        out.append(Paragraph(_effline(ev["immediate"]), S["eff"]))
        if ev.get("immediate_note"):
            out.append(Paragraph(ev["immediate_note"], S["small"]))
    out.append(sp(5))

    out.append(Paragraph("Karar ağacı", S["h3"]))
    for opt in ev["options"]:
        out.append(_branch(
            opt["label"], opt.get("effects", []),
            condition=opt.get("condition"), locked=opt.get("locked"), kind="opt",
            has_outcomes=bool(opt.get("outcomes"))))
        for o in opt.get("outcomes", []):
            out.append(_nested(_branch(
                o["label"], o.get("effects", []), weight=o.get("weight"),
                condition=o.get("condition"), kind="out")))
        out.append(sp(3))

    if ev.get("note"):
        out.append(sp(3))
        from codex_base import callout
        out.append(callout("Tasarım notu", ev["note"]))
    return out
