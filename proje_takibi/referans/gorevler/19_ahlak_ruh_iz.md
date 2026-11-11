# Bölüm 19 — Ahlak, Ruh ve İz (Fable mimarisi)

Kaynak: `docs/design_notes/ahlak_ruh_iz_mimarisi.md` (Fable 5.2'nin cevabı, §A–§I).
Uygulama sırası §H'de; on iki adımın hepsi 2026-11-10/11'de işlendi (commit'ler `b37060c`…`0756f8b`).

## Yapılanlar (§H)

| adım | ne | commit |
|---|---|---|
| H1 | `BEDEL` etkisi ve bedel taşıyıcısı seçici | `b37060c` |
| H2 | Ahlaki kartların kadro kilidi açıldı (tayfa eli / gelecekteki sen) | `5a07cb5` |
| H3 | İz defteri çekirdeği (şema, tavan, sönme, kayıt v5, fiyat ve yüz dönüşü) | `a1029b9` |
| H4 | Açık Hesaplar sayfası + şehir özetinde "seni bekleyen var" | `c184451` |
| H5 | Ruh eksenleri (Kabuk, Çatlak) ve tanıklık tablosu | `3c3c273` |
| H6 | Hâl makinesi (Yorgun, Katı, Sönük) ve Sükûnet'in bağlanması | `4e2e5dd` |
| H7 | Ateş Başı (öncelik sıralı sessiz an) ve Boş Yer | `acab01d` |
| H8 | Yayılma + kalan dönüş biçimleri (kapı, aday, teklif, ret, düşman) + Y-E13 | `3baf1f9`, `dbe4fdd` |
| H9 | Yankı çözücü ve 22 kartın yankı cümlesi | `89c13ec` |
| H10 | Söz (vadeli iz) ve sertlik kapısı | `dd14e5f` |
| H11 | Şehrin ruhu köprüsü, kervanın huyu, Taş ve Gidici | `9a1c1a3` |
| H12 | Kuşak izleri, lakap ve ölçüm araçları (§G.4) + üç ahlak politikası | `0756f8b` |

## Açık işler

- **Y-R01** — §E'nin 50 satırını kartlara işle. Mekanizma kurulu ve ölçülüyor; eksik olan hacim.
- **Y-R02** — Yankı varyantlarını cevaba göre yaz (`<id>_YANKI_<secim>`).

## Reddedilenler (§I) — yeniden önerilmez (Y-R03)

Fable'ın kendi değerlendirmesiyle **uygulanmayan** on üç fikir. Dördü doğrudan anayasa ihlali olurdu;
gerekçelerin tamamı tasarım notunun §I'sinde.

1. Görünür ahlak çubuğu / karma puanı — oyuncu çubuğu oynar, insanı değil.
2. Akıl sağlığı sayacı (halüsinasyon, sahte kart, yalan söyleyen arayüz) — bilgi oyununu öldürür.
3. Liderin kendi başına karar vermesi — **A5 ihlali** (otomatik karar yasak); yerine maliyet çarpanı kondu.
4. Olay kartıyla ölüm — **A2 ihlali**; ölüm üç kapıdan gelir, `BEDEL`in canı 1'de kenetlenir.
5. Bir sistemi kaldırarak dengelemek — **A1 ihlali**; cevap gideri silmek değil, minnetin insan getirmesi oldu.
6. Her NPC ile tam ilişki grafiği — okunmaz ve kaydı şişirir; `People` zaten üç kişi + reis tutuyor.
7. Yoldaşlar arası aşk, evlilik, çocuk — kuşak adın devri üzerine kurulu, kan üzerine değil.
8. Rastgele kelebek etkileri — doğum kaydı olmayan dönüş rastgelelikten ayırt edilemez; her iz `kaynak` taşır.
9. Bölümlü ahlaki hikâye, iyi son / kötü son — **A4 ihlali**; tek son adı taşıyacak kimsenin kalmaması.
10. Şehir yönetimi katmanı — oyuncu kervanbaşı, kethüda değil.
11. Yamyamlık ve benzeri şok seçenekleri — şok bir kez çalışır, sonra menü maddesine döner.
12. Yeni harcanabilir kaynak (vicdan, umut puanı) — harcanabilir vicdan bir para birimidir.
13. Hâl için yeni ikon seti ve renk kodu — sanat borcu ağır, tek sıcak kaynak kuralını zorlar; hâl duruşla okunur.
