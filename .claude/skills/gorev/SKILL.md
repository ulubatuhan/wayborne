---
name: gorev
description: Wayborne'un görev kaydına (proje_takibi/) iş eklemek, bir görevin durumunu ya da notunu değiştirmek, bir görevi aramak ve üretilmiş TODO belgelerini yenilemek için kullan. Kullanıcı "yapılacaklara not et", "hedeflere ekle", "görevi kapat" dediğinde.
---

# Görev kaydı

Tek kaynak `proje_takibi/referans/gorevler.json` (durum) ve `proje_takibi/referans/gorevler/*.md` (her görevin
ayrıntılı metni). `KALAN_ISLER.md`, `YAPILAN_ISLER.md`, `TEST_BEKLEYEN.md`, `YARIM_VE_ONAY_BEKLEYEN.md` üretilir:
**elle düzenlenmez ve bağlama alınmaz** (Çalışma düzeni).

## Bulmak

```bash
grep -n '"Y-C21"' proje_takibi/referans/gorevler.json
grep -n "Y-C21" proje_takibi/referans/gorevler/*.md
```

Benzer bir görev varsa yenisini açma; onunkini derle ve notunu güncelle (kullanıcının isteği).

## Görev kaydı (gorevler.json, `gorevler` listesi)

```json
{"id": "Y-C24", "baslik": "...", "bolum": "13", "alan": "Yönetmen: Sistemler ve mekanikler", "oncelik": "P1",
 "durum": "açık", "bagimli": ["Y-C21"], "dosya": "gorevler/13_yonetmen_onerileri.md", "dalga": 2,
 "paket": "P07", "sira": 84, "kim": "CK", "not": "2026-10-30 kullanıcı: ..."}
```

- `oncelik`: P0 hata/engel, P1 yüksek, P2 orta, P3 düşük, Öneri (onay bekleyen).
- `kim`: C Claude tek başına, CO Claude yapar + kullanıcı görsel onayı, CK kullanıcı kararı gerekir, CI kullanıcının
  içeriği/lore'u gerekir, S kullanıcının işi.
- `durum`: açık, kısmen, test bekliyor, bitti, beklemede, öneri, lore bekliyor... (var olan değerlerden seç).
- `paket`: `paketler` listesindeki bir P kimliği; paketin `gorevler` dizisine de eklenir.
- Dosya `indent=1` ile yazılır, `ensure_ascii=False`.

## Ayrıntı metni (gorevler/<dosya>.md)

Görev bloğu biçimi: `- [ ] **<id> <başlık>**` satırı ve altında girintili ayrıntı. Bölümün başındaki tablo
satırına (ör. `| 2 | Dünya, ekonomi ve kontratlar | ... |`) yeni kimlik eklenir. Python'la yazarken tırnakları
kaçışlı (`\"`) yazma; bir kez dosyaya `\"` sızdı.

## Üret ve kaydet

```bash
python3 -I proje_takibi/referans/belge_uret.py
```

- Kullanıcının bir hedefi CLAUDE.md "Ana Hedefler"e de girer (bir madde, görev kimliğiyle).
- `proje_takibi/DEVAM_NOTU.md`'deki ilgili satır güncellenir.
- Commit mesajında imza, oturum satırı ya da bağlantı olmaz (kullanıcı kuralı).
