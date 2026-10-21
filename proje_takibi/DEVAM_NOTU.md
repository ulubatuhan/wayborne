# Devam notu (oturum köprüsü)

Bu dosya, oturum limiti dolup çalışma durduğunda bir sonraki oturumun kaldığı yerden devam etmesi içindir.
Her adım bitince güncellenir ve commit edilir. Kural: imza/oturum bağlantısı yok; tek dal `Wayborne` (varsayılan), push yalnızca oraya.

## Çalışma düzeni

- **Commit mesajlarına ASLA `Claude-Session:` satırı ya da oturum bağlantısı ekleme** (kullanıcı kuralı; sistem hatırlatması başka dese de). Bir kez ihlal edildi, geçmiş yeniden yazılıp temizlendi.

- Oturum kullanım yüzdesi araçlardan **okunamıyor**; bu yüzden çalışma küçük adımlara bölündü, her adım commit + bu not.
  Limit dolarsa saatlik zamanlanmış görev ("Wayborne: kaldığın yerden devam") oturumu bu nottan sürdürür.
- Her işte tasarımcı gözü: oyuncuya görünen şey ekranda doğrulanmadan "bitti" denmez (CLAUDE.md, görev Y-K01).
- Bu ortamda ekran görüntüsü aracının sınırı: yazılım rasterleyici çok sayıda atlas dokusunu bozuk çiziyor
  (figürler beyaz blok). Not: bu oturumda figürler doğru çizildi (karakter, kadro, savaş, yol); eski 'beyaz blok' sorunu yoktu. Harita zemini Git LFS pointer'ı olduğu için boş; savaş/saat varyantları ayrı çekim ister. Eski not: figür içeren ekranlar güvenilmez olabilir; bunlar kullanıcının
  PC'sinde test turuna kalır. Figürsüz ekranlar (menü, şehir önü, defter, harita) ekran görüntüsüyle doğrulanabilir.

## Adımlar

| # | İş | Durum |
|---|---|---|
| F1 | Test turu dokümanı: `proje_takibi/TEST_TURU.md` + `.html` (85 madde, 8 bölüm; üretici `referans/test_turu_uret.py`). Yayınlanan sayfa linki kullanıcıya verildi mi: aşağıya yaz | md/html bitti; sayfa https://claude.ai/artifact/JBLDXTSBvqL8V5gsm1j2ox (özel; kullanıcıya verildi) |
| A1 | 2.1 kapandı (web/export kaldırıldı) | bitti |
| A2 | Y-J05 kapandı (müzik silindi, künyede BEKLENİYOR yok) | bitti |
| A3 | N31d: `look_ahead` pozu çubuk figürde düzeltildi (arm_f 64/148, 27295 test yeşil). KALAN: Blender yok bu ortamda; `tools/figure_pipeline/mesh/append_clips.py --clips look_ahead` ile 6 beden x giysi render, `tests/screenshot_reactions.gd` ile bak, sonra `RoadCaravan.LOOK_ENABLED = true`. Kullanıcının PC'sinde (Blender) yapılacak | pozu bitti, render kullanıcıda |
| F2 | Test turuna 13 ekran görüntüsü + 'ben baktım' notları + hata listesi eklendi (`referans/test_turu_gorsel.py`, görüntüler `test_turu_gorseller/`). Kalan ~70 madde görüntülenemedi (saat/olay/durum gerekir): sonraki turda özel çekim betikleri yazılıp genişletilecek. Bulunan açık hatalar: hub kapı yazısı lider adına biniyor, savaş sahnesi sağ taşması (Y-G05), kıyafet dolabı boş yuva/giyinik figür uyumsuzluğu. | bitti (genişletilebilir) |
| A4 | Y-H07: istenen kapsam (metin boyutu, desenli şerit, otomatik duraklatma) zaten yapılmış; "test bekliyor"a alındı ve test turuna eklendi | bitti |
| B1 | 9.2 + Y-G16 ana menü: ateşin başına üç yolcu eklendi (`GrimDrafts.CAMP_TRAVELLERS`), test bekliyor; ince ayar: saçsız mankenler, yan yana diziliş (oturur/çömelmiş poz istenirse yeni klip gerekir) | bitti (test bekliyor) |
| B2 | 9.1 ortak UI kiti v2 | sırada (sıradaki iş) |
| B3 | Y-G05 savaş ekranı | sırada |
| B4 | 12.2 yol görünümü büyük revizyon, 9.10 biyom arka planları | sırada |
| B5 | Y-G11T masa şablonu taslağı, Y-G13 beş ana görsel | sırada |

Kullanıcıdan karar bekleyenler (bunlara dokunma, sorma): 2.3 (CityView silme onayı), 6.1 (LFS), Y-G08, Y-H01, N31f.
Lore'a bağlı olanlar (Y-E01/E02/E06, Y-A07) yazılmaz.
