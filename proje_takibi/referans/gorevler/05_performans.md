# §5. Performans

> Bu dosya `../YAPILACAKLAR.md` dizininin bir bölümü. Görev kimlikleri (ör. **8.2**, **12.2c**, **R0**) ve § başvuruları dizindekiyle aynı. Kurallar: `00_kurallar.md`. Başlamadan önce: `../00_BASLA_BURADAN.md`.

- [ ] **5.1 `_process` döngülerinin gereksiz çalışmasını durdur**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `9d924e7`): Ortam animasyonları görünmezken çizilmiyor ve en çok 30 Hz; terazi dengede işlemeyi bırakıyor; kumanda ve geçiş elle denenecek.
  - `GamepadCursor` kumanda yokken çalışmasın (O-6).
  - `SceneInk` yalnız sahne geçişinde çalışsın (O-7).
  - `SurvivalGauge`, `AshFall`, `SmokeWisps`, `LanternGlow` ve `TradeScales` değer değişmezken yeniden çizmesin (O-8).
- [ ] **5.2 Mipmap'leri içe aktarma ayarıyla üret** (O-4)
  - Çalışma anındaki `_with_mipmaps` kopyalamasını kaldır.
  - Ayar tüm projeye mi, belirli klasörlere mi uygulanacak, kullanıcıya sor (§7 madde 10).
- [ ] **5.3 `BodyFrames` önbelleğine çıkarma politikası ekle** (O-9). Önce bellek kullanımını ölç.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `9534722`): LRU çıkarma (96 küme) ve ölçüm raporu.
- [ ] **5.4 Karakter frame atlaslarını sıkı paketle** (O-3)
  - En yüksek VRAM ve indirme kazancı burada: doluluk %18,7, sayfa sayısı 3–5 kat azalabilir.
  - Önce hücre gerekçesini doğrula (§7 madde 9).
  - LFS'ten (6.1) sonra yap, çünkü tüm frame setleri yeniden yazılacak.
- [x] **5.5 Gömülü base64 içeren 8 `.gltf` dosyasını `.glb`'ye çevir** (O-12, depodan ~7 MB tasarruf)
  - **Yapıldı** (`yerel/yapilacaklar-p01-p04`, commit `5c47fbd`): Sekiz hayvan .gltf dosyası kayıpsız çevirici (tools/gltf_to_glb.py, JSON aynı ve ikili veri birebir, doğrulandı) ile .glb oldu: 25 MB -> 16 MB. beasts.json ve beast_skin örneği güncellendi; Blender'da Horse.glb içe aktarımı denendi (6 nesne, 13 eylem). Render hattı baştan sona koşturulmadı.
