# -*- coding: utf-8 -*-
"""TODO belgelerini görev kaydından üretir (2026-10-19 düzeni).

Kaynak: referans/gorevler.json (durum), referans/gorevler/*.md (her görevin ayrıntılı
metni), referans/test_ve_onay_ekleri.md (akşam koşusunun komutları, indirme ve karar
listeleri). Çıktı TODO kökünde dört belge:
  YAPILAN_ISLER.md                 durum "bitti"
  TEST_BEKLEYEN.md                 durum "test bekliyor" (+ akşam koşusunun nasıl yapılacağı)
  YARIM_VE_ONAY_BEKLEYEN.md        kısmen yapılmış ya da taslağı/planı onayda olanlar
  KALAN_ISLER.md                   hiç başlanmamış ya da kullanıcı/lore/izin bekleyenler

    python -X utf8 referans/belge_uret.py      (TODO klasöründen)

Bir görevin durumu değişince gorevler.json'da durumunu ve notunu güncelle, betiği yeniden koştur.
"""
import io
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
TODO = os.path.dirname(HERE)
G = json.load(open(os.path.join(HERE, "gorevler.json"), encoding="utf-8"))["gorevler"]
KIM = {"C": "Claude tek başına", "CO": "Claude yapar, kullanıcı görsel/tasarım onayı verir",
       "CK": "kullanıcı kararı gerekir", "CI": "kullanıcının içeriği/lore'u gerekir", "S": "kullanıcının işi"}

_blocks = {}


def section_text(task):
    """Görevin bölüm dosyasındaki ayrıntılı metni (madde başlığından bir sonraki maddeye)."""
    rel = task.get("dosya", "")
    path = os.path.join(HERE, rel.replace("referans/", "")) if rel else ""
    if not path or not os.path.exists(path):
        return ""
    if path not in _blocks:
        _blocks[path] = io.open(path, encoding="utf-8").read().split("\n")
    lines = _blocks[path]
    tid = re.escape(task["id"])
    start = None
    for i, line in enumerate(lines):
        if re.match(r"\s*- \[[ x]\] \*\*" + tid + r"\b", line):
            start = i
            break
    if start is None:
        return ""
    indent = len(lines[start]) - len(lines[start].lstrip())
    out = [lines[start].strip()]
    for line in lines[start + 1:]:
        if not line.strip():
            break
        lead = len(line) - len(line.lstrip())
        if lead <= indent and (line.lstrip().startswith("- [") or line.startswith("#")):
            break
        out.append(line)
    return "\n".join(out)


def entry(task, extra=""):
    ref = task.get("dosya", "").replace("gorevler/", "referans/gorevler/")
    text = section_text(task)
    parts = [f"### {task['id']} · {task['baslik']}", "",
             f"- **Durum:** {task['durum']} · **Öncelik:** {task.get('oncelik', '-')} · **Paket:** {task.get('paket', '-')}"
             f" · **Kim:** {KIM.get(task.get('kim', ''), task.get('kim', ''))}",
             f"- **Ayrıntı ve geçmiş:** [{ref}]({ref})"]
    if task.get("bagimli"):
        parts.append(f"- **Bağımlı:** {', '.join(task['bagimli'])}")
    if task.get("not"):
        parts.append(f"- **Son not:** {task['not']}")
    if extra:
        parts.append(extra)
    if text:
        parts += ["", "<details><summary>Görev metni</summary>", "", text, "", "</details>"]
    return "\n".join(parts) + "\n"


DONE = {"bitti"}
TEST = {"test bekliyor", "kamera ayarlandı, render akşam"}
OPEN = {"açık", "öneri", "karar bekliyor"}


def bucket(t):
    if t["durum"] in DONE:
        return "done"
    if t["durum"] in TEST:
        return "test"
    if t["durum"] in OPEN and not t["id"].startswith("N31") and t.get("kim") in ("S", "CK", "CI"):
        return "rest"
    if t["durum"] in OPEN:
        return "rest"
    return "half"


def write(name, title, intro, tasks):
    tasks = sorted(tasks, key=lambda t: (t.get("paket", ""), t.get("sira", 0)))
    body = [f"# {title}", "", intro, "", f"Toplam: **{len(tasks)}** görev. Belgeler `referans/belge_uret.py` ile "
            "`referans/gorevler.json`'dan üretilir.", ""]
    pkg = None
    for t in tasks:
        if t.get("paket") != pkg:
            pkg = t.get("paket")
            body += [f"## Paket {pkg}", ""]
        body.append(entry(t))
    io.open(os.path.join(TODO, name), "w", encoding="utf-8", newline="\n").write("\n".join(body))


def main():
    groups = {"done": [], "test": [], "half": [], "rest": []}
    for t in G:
        groups[bucket(t)].append(t)
    ek = io.open(os.path.join(HERE, "test_ve_onay_ekleri.md"), encoding="utf-8").read()
    test_part, onay_part = ek.split("<!-- ONAY -->")
    write("YAPILAN_ISLER.md", "Yapılan işler",
          "Bitmiş ve doğrulanmış (testi ya da kullanıcı onayı geçmiş) görevler. Kod dalı: `wayborne`, "
          "`yerel/yapilacaklar-p05-p06` (önceki tur `yerel/yapilacaklar-p01-p04`). Push edilmedi.", groups["done"])
    write("TEST_BEKLEYEN.md", "Test bekleyenler",
          "Kodu yazılmış, commit edilmiş ama Godot açılmadığı için henüz test edilmemiş görevler. Akşam koşusu bu "
          "belgenin başındaki adımlarla yapılır; her görevin altında neyin görülmesi gerektiği yazıyor.\n\n" + test_part,
          groups["test"])
    write("YARIM_VE_ONAY_BEKLEYEN.md", "Yarım kalan ve onay bekleyenler",
          "Benim payım bitmiş ama kullanıcı onayı (taslak, tasarım notu, plan), indirme izni, lore ya da dış test "
          "bekleyen görevler; bir de kısmen yapılmış olanlar. Her birinde ne yapıldığı ve ne kaldığı yazıyor.\n\n"
          + onay_part, groups["half"])
    write("KALAN_ISLER.md", "Kalan işler",
          "Başlanmamış görevler: kullanıcının işi (S), kullanıcı kararı (CK), kullanıcının içeriği ya da lore (CI) ve "
          "yeni eklenen oyun hissi alt görevleri (N31a-f). Her birinin neden beklediği 'Kim' satırında.", groups["rest"])
    print({k: len(v) for k, v in groups.items()})


if __name__ == "__main__":
    main()
