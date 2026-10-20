# §6. Depo hijyeni

> Bu dosya `../YAPILACAKLAR.md` dizininin bir bölümü. Görev kimlikleri (ör. **8.2**, **12.2c**, **R0**) ve § başvuruları dizindekiyle aynı. Kurallar: `00_kurallar.md`. Başlamadan önce: `../00_BASLA_BURADAN.md`.

- [ ] **6.1 LFS ve `.gitattributes` ekle** (§5 H-1, H-9)
  - **Kısmen yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `32f9ac4`): .gitattributes eklendi (metin dosyaları LF, ikililer binary). Bu makinedeki core.autocrlf=true yüzünden CRLF'ye dönen iki spec JSON'u iki testi kırıyordu; artık geçiyor. LFS taşıması (`git lfs migrate`, geçmişi yeniden yazar) kullanıcı onayı bekliyor, yapılmadı. git-lfs 3.7.1 kurulu.
  - İkili dosyalar LFS'e gitsin.
  - Metin dosyaları için `eol=lf` tanımla (Windows'tan yapılacak commitler için gerekli).
  - Geçmişi yeniden yazmak (`git lfs migrate`) **kullanıcı onayı** ister (§7 madde 11).
- [x] **6.2 `.gitignore` boşluklarını doldur** (H-8)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `af1f044`): *.blend1, *.blend@, Thumbs.db, .DS_Store, *.log, *.orig eklendi; hiçbir dosyayla eşleşmeyen data_*/ satırı kaldırıldı.
  - Ekle: `*.blend1`, `*.blend@`, `Thumbs.db`, `.DS_Store`, `*.log`, `*.orig`.
  - `data_*/` satırını kaldır.
- [x] **6.3 `CLAUDE.md`'yi incelt** (H-11, 475 KB)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `2b13dcc`): Development Status'un Ana Hedefler sonrası kısmı (2130 satır, 148 KB) docs/history/FAZ_ANLATILARI.md'ye metin değişmeden taşındı; kayıpsızlık betikle doğrulandı. CLAUDE.md 480 KB'dan 332 KB'a indi. Kural bölümlerine (Art Rules, Wardrobe vb.) dokunulmadı: onlar kural ve gerekçe iç içe, ayıklamak kullanıcı onayı ister. Koddaki 'bkz. CLAUDE.md Faz N' başvuruları artık history dosyasına bakıyor.
  - Kurallar kalsın; faz anlatılarını `docs/history/` altına taşı.
  - **Kullanıcı onayı** iste.
