# -*- coding: utf-8 -*-
"""Wayborne Codex - PDF üreteci (temel katman: font, stil, akış nesneleri)."""

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, Frame, PageTemplate, Paragraph, Spacer, Table, TableStyle,
    KeepTogether, PageBreak, NextPageTemplate, Flowable,
)

# --- Font: Türkçe glifleri (ş ğ ı İ) tam taşıyan Liberation ailesi.
# DejaVu'nun bu kurulumda italik varyantı yok; <i> etiketleri sessizce
# düz metne düşerdi, o yüzden gövde için tam aile olan Liberation seçildi.
LIB = "/usr/share/fonts/truetype/liberation"
DJV_DIR = "/usr/share/fonts/truetype/dejavu"
pdfmetrics.registerFont(TTFont("DJV", f"{LIB}/LiberationSans-Regular.ttf"))
pdfmetrics.registerFont(TTFont("DJV-B", f"{LIB}/LiberationSans-Bold.ttf"))
pdfmetrics.registerFont(TTFont("DJV-O", f"{LIB}/LiberationSans-Italic.ttf"))
pdfmetrics.registerFont(TTFont("DJV-BO", f"{LIB}/LiberationSans-BoldItalic.ttf"))
pdfmetrics.registerFont(TTFont("DJV-M", f"{DJV_DIR}/DejaVuSansMono.ttf"))
pdfmetrics.registerFont(TTFont("DJV-MB", f"{DJV_DIR}/DejaVuSansMono-Bold.ttf"))

# <b> / <i> etiketlerinin doğru varyanta bağlanması için aile kaydı
pdfmetrics.registerFontFamily("DJV", normal="DJV", bold="DJV-B",
                              italic="DJV-O", boldItalic="DJV-BO")
pdfmetrics.registerFontFamily("DJV-M", normal="DJV-M", bold="DJV-MB",
                              italic="DJV-M", boldItalic="DJV-MB")

# --- Renk paleti: mürekkep + parşömen + solgun altın ---
INK = colors.HexColor("#23201B")
INK_SOFT = colors.HexColor("#4A443A")
MUTED = colors.HexColor("#7A7263")
GOLD = colors.HexColor("#9A7B3F")
GOLD_PALE = colors.HexColor("#E8DEC6")
PARCH = colors.HexColor("#FBF7EF")
RULE = colors.HexColor("#C9BEA3")
RED = colors.HexColor("#8E3B2F")
GREEN = colors.HexColor("#4A6B45")
BLUE = colors.HexColor("#3F5B77")
ROW_ALT = colors.HexColor("#F4EFE4")

PAGE_W, PAGE_H = A4
MARGIN = 20 * mm

_ss = getSampleStyleSheet()


def _st(name, **kw):
    base = dict(fontName="DJV", fontSize=9.4, leading=14.2, textColor=INK,
                alignment=TA_JUSTIFY, spaceAfter=5)
    base.update(kw)
    return ParagraphStyle(name, parent=_ss["Normal"], **base)


S = {
    "title":    _st("title", fontName="DJV-B", fontSize=34, leading=40,
                    textColor=INK, alignment=TA_CENTER, spaceAfter=6),
    "subtitle": _st("subtitle", fontName="DJV", fontSize=12.5, leading=18,
                    textColor=MUTED, alignment=TA_CENTER, spaceAfter=4),
    "part":     _st("part", fontName="DJV-B", fontSize=23, leading=28,
                    textColor=INK, alignment=TA_LEFT, spaceAfter=2, spaceBefore=0),
    "partnum":  _st("partnum", fontName="DJV-B", fontSize=10, leading=13,
                    textColor=GOLD, alignment=TA_LEFT, spaceAfter=2),
    "h1":       _st("h1", fontName="DJV-B", fontSize=15, leading=20,
                    textColor=INK, alignment=TA_LEFT, spaceBefore=13, spaceAfter=5),
    "h2":       _st("h2", fontName="DJV-B", fontSize=11.2, leading=15.5,
                    textColor=GOLD, alignment=TA_LEFT, spaceBefore=10, spaceAfter=3),
    "h3":       _st("h3", fontName="DJV-B", fontSize=9.6, leading=13.5,
                    textColor=INK_SOFT, alignment=TA_LEFT, spaceBefore=7, spaceAfter=2),
    "body":     _st("body"),
    "lead":     _st("lead", fontSize=10.4, leading=16, textColor=INK_SOFT),
    "small":    _st("small", fontSize=8.3, leading=12, textColor=MUTED),
    "quote":    _st("quote", fontName="DJV-O", fontSize=9.6, leading=15,
                    textColor=INK_SOFT, leftIndent=10, rightIndent=8),
    "code":     _st("code", fontName="DJV-M", fontSize=8.2, leading=12.4,
                    textColor=INK, alignment=TA_LEFT),
    "cell":     _st("cell", fontSize=8.2, leading=11.4, alignment=TA_LEFT, spaceAfter=0),
    "cellb":    _st("cellb", fontName="DJV-B", fontSize=8.2, leading=11.4,
                    alignment=TA_LEFT, spaceAfter=0),
    "cellc":    _st("cellc", fontSize=8.2, leading=11.4, alignment=TA_CENTER, spaceAfter=0),
    "head":     _st("head", fontName="DJV-B", fontSize=8.2, leading=11.4,
                    textColor=colors.white, alignment=TA_LEFT, spaceAfter=0),
    "headc":    _st("headc", fontName="DJV-B", fontSize=8.2, leading=11.4,
                    textColor=colors.white, alignment=TA_CENTER, spaceAfter=0),
    "toc":      _st("toc", fontSize=9.4, leading=16, alignment=TA_LEFT, spaceAfter=0),
    "tocp":     _st("tocp", fontName="DJV-B", fontSize=9.8, leading=17,
                    alignment=TA_LEFT, spaceAfter=0, textColor=INK),
}

# Olay ağacı stilleri
S["evt_title"] = _st("evt_title", fontName="DJV-B", fontSize=13.5, leading=17,
                     textColor=INK, alignment=TA_LEFT, spaceAfter=1)
S["evt_id"] = _st("evt_id", fontName="DJV-M", fontSize=7.6, leading=10,
                  textColor=MUTED, alignment=TA_LEFT, spaceAfter=0)
S["evt_flavor"] = _st("evt_flavor", fontName="DJV-O", fontSize=9, leading=13.6,
                      textColor=INK_SOFT, alignment=TA_LEFT, spaceAfter=3)
S["opt"] = _st("opt", fontName="DJV-B", fontSize=9.2, leading=13,
               textColor=INK, alignment=TA_LEFT, spaceAfter=1)
S["optlock"] = _st("optlock", fontSize=8.2, leading=11.6, textColor=RED,
                   alignment=TA_LEFT, spaceAfter=1)
S["out"] = _st("out", fontSize=8.6, leading=12.4, textColor=INK_SOFT,
               alignment=TA_LEFT, spaceAfter=1)
S["eff"] = _st("eff", fontName="DJV-M", fontSize=8, leading=11.6,
               textColor=INK, alignment=TA_LEFT, spaceAfter=0)


class HRule(Flowable):
    """İnce yatay çizgi."""

    def __init__(self, width=None, thickness=0.6, color=RULE, space=3):
        Flowable.__init__(self)
        self._w = width
        self._t = thickness
        self._c = color
        self._space = space
        self.height = thickness + space

    def wrap(self, aw, ah):
        self._aw = self._w or aw
        return (self._aw, self.height)

    def draw(self):
        self.canv.setStrokeColor(self._c)
        self.canv.setLineWidth(self._t)
        self.canv.line(0, self._space, self._aw, self._space)


class ColorBar(Flowable):
    """Bölüm başlığı altındaki kalın altın bant."""

    def __init__(self, width=None, height=2.4, color=GOLD):
        Flowable.__init__(self)
        self._w, self.height, self._c = width, height, color

    def wrap(self, aw, ah):
        self._aw = self._w or aw
        return (self._aw, self.height)

    def draw(self):
        self.canv.setFillColor(self._c)
        self.canv.rect(0, 0, self._aw, self.height, stroke=0, fill=1)


def para(text, style="body"):
    return Paragraph(text, S[style])


def sp(h=4):
    return Spacer(1, h)


def callout(title, text, accent=GOLD, bg=GOLD_PALE):
    """Kenarında renkli bant olan vurgulu kutu."""
    inner = []
    if title:
        inner.append(Paragraph(f"<b>{title}</b>", S["h3"]))
    inner.append(Paragraph(text, S["body"]))
    t = Table([[inner]], colWidths=[None])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), bg),
        ("LINEBEFORE", (0, 0), (0, -1), 2.6, accent),
        ("LEFTPADDING", (0, 0), (-1, -1), 9),
        ("RIGHTPADDING", (0, 0), (-1, -1), 9),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ]))
    return t


def codebox(lines):
    body = "<br/>".join(lines)
    t = Table([[Paragraph(body, S["code"])]], colWidths=[None])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F2EEE3")),
        ("BOX", (0, 0), (-1, -1), 0.5, RULE),
        ("LEFTPADDING", (0, 0), (-1, -1), 9),
        ("RIGHTPADDING", (0, 0), (-1, -1), 9),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
    ]))
    return t


def table(headers, rows, widths=None, align_center=None, font_size=8.2,
          label_column=False):
    """Başlıklı, alternatif satır gölgeli tablo.

    `headers` None ise başlık bandı hiç çizilmez - künye/şartname tarzı
    iki sütunlu listeler için. Boş dizgeli bir başlık geçmek, metinsiz
    siyah bir bant bırakıyordu.
    """
    align_center = align_center or []
    hstyle = lambda i: S["headc"] if i in align_center else S["head"]
    cstyle = lambda i: S["cellc"] if i in align_center else S["cell"]

    has_head = headers is not None
    data = []
    if has_head:
        data.append([Paragraph(str(h), hstyle(i)) for i, h in enumerate(headers)])
    for r in rows:
        data.append([
            Paragraph(str(c), S["cellb"] if (label_column and i == 0) else cstyle(i))
            for i, c in enumerate(r)
        ])

    t = Table(data, colWidths=widths, repeatRows=1 if has_head else 0)
    style = [
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LINEBELOW", (0, 0), (-1, -1), 0.35, RULE),
        ("BOX", (0, 0), (-1, -1), 0.5, RULE),
    ]
    if has_head:
        style.append(("BACKGROUND", (0, 0), (-1, 0), INK))
    first_body = 1 if has_head else 0
    for i in range(first_body, len(data)):
        if (i - first_body) % 2 == 1:
            style.append(("BACKGROUND", (0, i), (-1, i), ROW_ALT))
    t.setStyle(TableStyle(style))
    return t
