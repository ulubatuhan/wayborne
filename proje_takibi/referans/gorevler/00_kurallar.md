# §0. Önce oku: kurallar ve kararlar

> Bu dosya `../YAPILACAKLAR.md` dizininin bir bölümü. Görev kimlikleri (ör. **8.2**, **12.2c**, **R0**) ve § başvuruları dizindekiyle aynı. Kurallar: `00_kurallar.md`. Başlamadan önce: `../00_BASLA_BURADAN.md`.

### Kalıcı kurallar
- Kullanıcıya Türkçe yanıt ver.
- Kullanıcı açıkça istemedikçe PR açma.
- Asıl kontrol CI'dır. Her değişiklikten sonra şunları çalıştır ve CI'daki betik hatası taramasının geçtiğini doğrula:
  - `godot --headless --import`
  - `godot --headless --script res://tests/run_tests.gd`
- Repoya model kimliği yazma.
- Anahtar ve token'ları dosyaya ya da git'e yazma.
- Ücretli üretimden önce tahmini maliyeti söyle ve onay iste.
- Girdi dosyalarının üstüne yazma.
- Ticari referans görsellerin piksellerini repoya koyma.
- Yeni adlar başka eserlerden ya da gerçek tarihten alınmayacak. Birbirine fazla benzemeyecek. Gerçek dini figür veya yapı adı olmayacak.

### Platform (kullanıcı kararı, 2026-10-17)
- **Wayborne bir PC oyunu.** Web derlemesi yalnızca test için.
- Web performansı, Web paket boyutu ve Web VRAM sınırları **ölçüt değil**.
- Performans hedefleri PC için konur: orta sınıf ekran kartında 60 FPS.
- Web derlemesi çalışır kalmalı, ama onun için optimizasyon yapılmaz.

### İsim kuralı (kullanıcı kararı, 2026-10-17)
- Dosyalarda referans oyun'a özgü adlar **olmayacak**:
  - **"mezra"** referans oyunda geliyor, yeniden adlandırılacak.
  - **"referans oyun" / "referans oyun"** kısaltması geçmeyecek. Örnek: `tests/test_combat_dd.gd`.
- **"Grim" sorun değil.** `GrimTheme`, `scripts/ui/grim/` ve `UI_GRIM_*` olduğu gibi kalacak, yeniden adlandırma.

### Yönetmen seçimleri: kullanıcı kararları (2026-10-17)
Kaynak: yönetmen masası seçimleri, `../belgeler/yonetmen/secimler_2026-10-17.json`. Ayrıntı ve notlar: `13_yonetmen_onerileri.md`.
- **Kapsam:** Dikey dilim ya da kapsam kilidi yok. Oyun Aralık'tan önce bitecek; sonra pazarlama ve rötuş. Harita aktarımı kademeli değil, dünyanın tamamı ve hemen ("ya hep ya hiç"). Zindanlar küçük sürüm olmadan, tam.
- **Sıra:** İşler teknik önceliğe göre yapılır (`../YAPILACAKLAR.md` iş paketleri).
- **Takvim:** Hedef Şubat 2027 Next Fest. Steam hesabı ve sayfası Aralık'ta; pazarlama o zaman başlar. Kickstarter yok (Türkiye kısıtı).
- **Sanat:** Karakter ve giysi sistemi oturdu. UI, HUD ve menüler oturduktan sonra sanat bir süre bırakılır.
- **Hijyen:** Temizlik, kalite ve hijyen görevleri ertelenmez ("Temiz masa, temiz iş, hızlı süreç. 5S!").
- **Korunan sistemler (kesilmez, birleştirilmez):** beş kapasite yolu; hub yürüyüş alanı (asıl iş atölye ekranı); kıyafetlerin stat vermesi (zırh mı kıyafet mi, oyuncunun tercihi); büyücü ve büyüler (nadir olay olarak doğabilir); boy, kilo ve cinsiyetin statları, statların savaşı etkilemesi.
- **Şehir:** Kervan şehre girmez. Şehir ekranında insanlar ve şehir görünmeli; bu işi savaşın ve kıtlığın içinde yapmanın motivasyonu halklardır.
- **Ölüm:** Lider ölümü için ayrıca zorluk artışı yok.
- **Yol:** Yol o kadar dolu olmalı ki oyuncu hızlandırmak istemesin; yol dolunca 1.5x ve 3x kalkar.
- **Stres:** Ekran efekti ya da filtre yok; kırılma karakterin davranışıyla yaşatılır.
- **Dil:** Oyuncuya gösterilen nedenler sayı değil söz ("Moral −10" değil "Moral düşük").
- **Ses:** Sesler Gemini ile üretilebilir; ana menüde şarkı yok; müzik dili gerilimli olacak. AI ses ve görsel Steam beyanına yazılır; CC0 üreticileri de CREDITS'e eklenir.
- **Başlangıç:** Kervan babanındır; baba hastalık yüzünden kervanı borçlu olarak devreder.
- **Kampanya:** Bölümler henüz yazılmadı; sahneleme kararı bölümler yazıldıktan sonra.
- **Lore önce:** Olay, düşman, zindan ve bölüm yazımı lore ve tarihçe tamamlandıktan sonra.

### Görev şablonu (Y-A02)
Her yeni görev bu alanlarla yazılır. **Sütun** satırı zorunlu: görev, vaadin dört sütunundan en az birine hizmet ettiğini
adıyla söyler (Yol yaşar · İnsanlar aşınır · Defter unutmaz · Ticaret bilgi oyunudur). Hiçbirine hizmet etmiyorsa
gerekçesi yazılır. Ayrıntı: `wayborne/docs/design/TASARIM.md`.

```
- [ ] **<kimlik> <başlık>** (`C` | `CO` | `CK` | `CI` | `S`)
  - **Öncelik:** P0-P3 · **Dalga:** n · **Bağımlı:** ...
  - **Sütun:** Yol yaşar | İnsanlar aşınır | Defter unutmaz | Ticaret bilgi oyunudur
  - **Ne:** ...
  - **Neden:** ...
  - **Kabul:** ölçülebilir ölçüt; ekranda görülen iş için ekran görüntüsü (Y-K01)
```
