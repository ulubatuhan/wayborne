# Claude için başlangıç: bu dalı oku, anla, benimse

Bu dosya, bu dalda çalışmaya başlayacak Claude için yazıldı. Projenin, kodun, belgelerin ve yapılacakların nerede
olduğunu ve kullanıcının çalışma kurallarını tek yerde toplar. Önce bunu, sonra aşağıdaki okuma sırasını izle.

## 1. Bu dal ne?

- **Wayborne:** Godot 4.2.2 / GDScript ile yapılan 2D kervan oyunu. Ticaret, yol olayları, sıra tabanlı savaş, soy
  ve defter. Hedef **PC (Windows)**; Web derlemesi yalnızca test içindir.
- **Kaynak:** bu dal, kullanıcının bilgisayarındaki yerel çalışmanın (2026-10-17 → 2026-10-20) tamamıdır. `origin/main`
  (2026-10-16) üstüne 157 commit ekler.
- **Diğer dallar:** `main`, `dev`, `ui-hud-redesign`, `claude/merhaba-6bf7co` ve eski yerel dalların hepsi **bu dalın
  içinde**; bu dalda olmayan tek bir commit'leri yok (2026-10-20'de `git rev-list --count HEAD..<dal>` = 0).
  Kullanıcı onaylarsa bu dal ana hat olabilir ve diğerleri silinebilir. Silmeden önce kullanıcıya sor, sonra aynı
  denetimi bir kez daha yap: `git fetch --all && git rev-list --count HEAD..origin/<dal>`.
- **Push ve dal:** dalı kullanıcı kendisi gönderdi. Kullanıcı açıkça istemedikçe push yapma, dal açma ve geçmişi
  yeniden yazma.

## 2. Okuma sırası

1. **`CLAUDE.md`:** kural kitabı. Her sistemin bozulmaması gereken kuralları ve gerekçeleri burada; uzun ama
   bağlayıcı. Değiştirdiğin sistemin bölümünü işe başlamadan oku.
2. **`proje_takibi/SONRAKI_OTURUM_PLANI.md`:** en üstteki **DEVAM NOKTASI**, işin kaldığı yer.
3. **`proje_takibi/DEGISIKLIK_KAYDI.md`:** bütün yerel çalışmanın commit commit özeti ve kurallar.
4. **`TESLIM_2026-10-20.md`:** son günün teslim notu: ne yapıldı, nasıl çalıştırılır, bilinen eksikler.
5. Gerektikçe: `proje_takibi/KALAN_ISLER.md`, `YARIM_VE_ONAY_BEKLEYEN.md`, `TEST_BEKLEYEN.md`, `YAPILAN_ISLER.md`.

## 3. Klasör haritası

| Yer | Ne |
|---|---|
| `scripts/` | Oyun kodu. Alt klasörlerin anlamı `CLAUDE.md` "Folder Structure"da (economy, travel, events, character, combat, world, ui, campaign, util, autoload). |
| `scenes/` | Godot sahneleri. Çoğu ekran kodla kuruluyor; sahne yolları `scripts/world/nav.gd`'de. |
| `data/config/`, `data/locale/` | JSON yapılandırma; çeviri CSV'leri (tr kaynak, en yedek, 11 dil sütunu). |
| `data/assets/` | Oyunun okuduğu bütün resim, ses, yazı tipi. Figür kare atlasları `data/assets/characters/frames/`. |
| `tests/` | `run_tests.gd` (headless test koşucusu), `simulate_*.gd` (denge raporları, test değil), `screenshot_*.gd` (görüntü araçları, test değil), `record_loop.gd` (döngü videosu). |
| `tools/` | Üretim hatları: `figure_pipeline/` (Blender figür/giysi/hayvan render + paketleme, kuralları `RULES.md`), `ui_scenes/` (kasaba, kapı, yol, taverna render), `npr/` (mürekkep geçişi), `worldmap/` (dünya haritası hattı, `run_all.sh`), `measure_report.py`, `playtest_report.py`, `waybook_assets.py`. |
| `art_source/` | Kaynak modeller ve dokular (CC0 paketler, MakeHuman giysileri; lisanslar klasörlerin içinde). |
| `docs/` | Tasarım belgeleri: `lore/`, `design_notes/`, `ui/` (REDESIGN, STIL_REHBERI), `history/` (kapanmış fazların anlatıları, `FAZ_ANLATILARI.md`), `codex/` (Codex PDF'inin kaynağı), `playtest/` (döngü kontrol listesi), `olcum/` (ölçüm raporları), `steam/`. |
| `proje_takibi/` | **Yapılacaklar ve proje takibi** (aşağıda). |
| `.github/workflows/` | `tests.yml` (her dal ve PR), `deploy.yml` (main → Web/Pages), `screenshots.yml`, `olcum.yml` (ölçüm raporu, elle ve haftalık). |

### proje_takibi/

Bu klasör kullanıcının bilgisayarındaki `xx/TODO/` klasörünün depoya alınmış kopyasıdır. Kopyalanırken başka bir
oyunun adı ve kısaltması "referans oyun", küçük köy türünün eski İngilizce adı "mezra" olarak değiştirildi (kural 5.1).
Kaynak belgelerinde bu oyunun adı geçen üç `.docx` dışarıda bırakıldı; içerikleri
`referans/belgeler/ART_IKINCI_TUR_REFERANSLARI.md` ve çıkarılmış görsellerde duruyor. Bundan sonra **asıl kayıt bu
klasördür**; belgelerdeki `xx/TODO/...` yolları buraya karşılık gelir.

| Dosya | Amacı |
|---|---|
| `SONRAKI_OTURUM_PLANI.md` | Oturum planları ve **DEVAM NOKTASI** notları (en yenisi en üstte). |
| `DEGISIKLIK_KAYDI.md` | Bütün değişikliklerin commit listesi; yeni sohbet için kurallar. |
| `YAPILAN_ISLER.md`, `TEST_BEKLEYEN.md`, `YARIM_VE_ONAY_BEKLEYEN.md`, `KALAN_ISLER.md` | Görev durumuna göre dört liste. **Elle düzenlenmez:** `referans/belge_uret.py` üretir. |
| `referans/gorevler.json` | **Görev kaydı**, tek doğru kaynak. Her görevin kimliği, başlığı, durumu, notu ve commit'i burada. Durum değerleri: `açık`, `kısmen`, `test bekliyor`, `bitti`, `beklemede`, `onaylandı, uygulanacak`, `kullanıcıda` vb. |
| `referans/belge_uret.py` | Kayıttan dört durum belgesini üretir: `cd proje_takibi && python -X utf8 referans/belge_uret.py`. |
| `referans/gorevler/` | Görevlerin ayrıntılı bölüm metinleri (`00_kurallar.md`, `01_...` → `14_yeni_dunya.md`). |
| `referans/belgeler/` | Denetimler (`KOD_DENETIMI.md`), yönetmen incelemesi (`yonetmen/`), kaynak araştırmaları, sanat referansları. |
| `referans/taslaklar/` | Onaylanan ama henüz uygulanmamış görsel taslaklar (9.1, 9.2/Y-G16, Y-G05, Y-G13, Y-G11T, 12.2, 9.10). |
| `referans/referanslar/` | Kullanıcının verdiği görsel referanslar. |
| `referans/harita_final/` | Son dünya haritası çıktıları ve GeoJSON. |
| `referans/kontrol_goruntuleri/` | Denetimde kullanılan ekran görüntüleri. |
| `ICERIK_IHTIYACLARI.md`, `KONTROL_BELGESI.md`, `test_ve_onay_ekleri.md` | Kullanıcıdan beklenen içerikler (lore, adlar); kontrol listeleri. |

## 4. Kullanıcının çalışma kuralları (hafızadan, bağlayıcı)

1. **Yasak adlar.** Başka bir oyunun adı ve kısaltması (iki harf, küçük ya da büyük) ve küçük köy türünün o oyundan
   gelen İngilizce adı hiçbir depo dosyasında, dosya adında, sınıf ya da değişken adında geçmez. Yerine "referans oyun"
   ve "mezra" kullanılır. "grim" (GrimTheme, `scripts/ui/grim/`) **serbesttir**. Her teslimden önce `git grep` ile
   tara.
2. **Commit iletilerinde Claude imzası ya da Co-Authored-By satırı yok.** Push yalnızca kullanıcı isteyince.
3. **Görsel kurallar.** Doygun yeşil, mavi ve mor yok. Dini sembol yok (cami, minare, haç, kilise yerine çan kulesi).
   Havada duran nesne yok. Oturuyor denen figür gerçekten oturuyor, tutuyor denen gerçekten tutuyor görünmeli.
4. **Görsel değişiklik ancak gerçek ekranın görüntüsüyle "bitti" sayılır** (CLAUDE.md, Y-K01). Test geçmesi yetmez:
   `tests/screenshot_*.gd` ile çek, eleştirel gözle bak, düzelt, tekrar bak.
5. **Kullanıcı bilgisayarı kullanırken Godot penceresi açma.** Ekran dışı çalıştırma serbest:
   `--position 20000,20000 --rendering-driver opengl3`. Blender `-b` serbest.
6. **İndirme izne bağlı.** Onaylılar: CC0 paketler ve MPFB (MakeHuman) Blender eklentisi. CC0 olmayan varlık
   sorulmadan oyuna girmez.
7. **Kullanım sınırı.** Uzun işlerde her iş sonunda kullanımı kontrol et. Kullanıcı genelde 5 saatlik pencerede %80,
   haftalıkta %85 sınırı koyuyor. Sınırda işi bitir, not al, dur.
8. **Özerklik.** Lore'a bağlı olmayan işleri onay sayfası hazırlamadan yap. Notları güncel tut: görev kaydı +
   `belge_uret.py`, `DEGISIKLIK_KAYDI.md`, DEVAM NOKTASI.
9. **Anahtar, token ve parola dosyaya yazılmaz.**
10. **Asla sadeleştirme, derinleştir.** Korunan sistemler kesilmez ve birleştirilmez: beş kapasite yolu, merkez
    yürüyüş alanı, kıyafet statları, haydut büyücü ve büyüler, beden statları. Kervan şehre girmez.
11. **Takvim.** Oyun Aralık'tan önce bitmeli. Steam sayfası Aralık'ta, Steam Next Fest Şubat 2027. Kickstarter yok.
12. **Dünya.** Eski beş yer tutucu şehir unutuldu. Harita v3'ün 12 şehri, 12 kasabası ve 3 kervansarayı oynanabilir.
    Kuzey-güney 61 oyun günü. Her yerleşimin kendi menü resmi var.
13. **Dil.** Kullanıcı Türkçe yazar; yanıtlar Türkçe. Oyuncuya dönük sebepler sayıyla değil sözle yazılır (Y-H03).

## 5. Durum (2026-10-20 akşamı)

- **Testler:** `godot --headless --script res://tests/run_tests.gd` → 27301 geçti, 0 kaldı.
- **Son gün yapılanlar** (ayrıntı `TESLIM_2026-10-20.md` ve `proje_takibi/DEGISIKLIK_KAYDI.md`):
  - 5.4 atlas sıkı paketleme;
  - Y-G02 mürekkep (eşya, yol, figür konturu);
  - Y-G12 yakın plan HD kareler;
  - Y-H03 kalanı, N31e kar;
  - Y-K03 ölçüm raporu ve izinli oyuncu ölçümü;
  - Y-K01 döngü videosu betiği;
  - 8.9 harita hattının baştan koşturulması;
  - 2.5/3.4/3.6 temizlik;
  - kullanıcı kararıyla çivili kâğıt notların (ilk kez ipuçları, ipucu baloncuğu ve pazar fişi dokusu) kaldırılması.
- **Yarım ya da eksik:**
  - **N31d bakma pozu.** 3B render'da el yüzün önünde. `RoadCaravan.LOOK_ENABLED = false`. Öneri: ön kolu daha az
    bük (`FigureActions` `look_ahead` `arm_f`, ör. `[70, 165]`), önce `tests/screenshot_poses.gd` çubuk figürüyle dene,
    sonra Blender'da yeniden render et ve ekle (`tools/figure_pipeline/mesh/append_clips.py --clips look_ahead`),
    ardından `tests/screenshot_reactions.gd` ile bak.
  - **Öğretici notlar yok.** Kullanıcı kendisi yazacak; eski ipucu sistemi silindi.
  - **8.9 harita.** Yeniden koşturulan haritada elle düzeltilmiş yol katmanı yok (`tools/worldmap/README.md`).
  - **6.1 LFS.** Geniş LFS kuralları geri alındı (gerekçe `.gitattributes`'ta). Yalnızca harita karoları LFS'te.
    Karar kullanıcıda.
  - **Gardırop yuvaları.** Figür giyinikken giysi yuvaları "boş" yazıyor; incelenmedi.
  - **Bekleyen kararlar.** Y-G06 kazıma efektleri beklemede. N31f ortam sesleri kullanıcıda. Y-G03 lore'a bağlı
    olmamalı.
  - **Onaylı ama uygulanmamış taslaklar:** 9.1 UI kiti örnekleri (köşebentsiz), 9.2/Y-G16 menü kampı, Y-G05 savaş
    ekranı, Y-G13 beş ana görsel, Y-G11T, 12.2 ve 9.10 yol revizyonu.
- **Lore'a bağlı işler:** `docs/lore/LORE.md` ve `TARIHCE.md`'deki [Boş] satırlar kullanıcıdan bekleniyor
  (`proje_takibi/referans/ICERIK_IHTIYACLARI.md`).

## 6. Depoda olmayanlar

- **`build/` (gitignore).** Blender render çıktıları (figür kareleri, HD kareler, kasaba sahneleri). Hatlarla yeniden
  üretilebilir. Oyunun okuduğu paketlenmiş sonuçlar `data/assets/` altında, depoda.
- **Kullanıcının bilgisayarında (`xx/`):**
  - `Harita_Calismasi/`: harita hattının girdileri ve çıktıları, yaklaşık 1 GB.
  - `video/dongu_2026-10-20.avi`: döngü videosu, 800 MB.
  - `araclar/`: Godot 4.2.2 konsol ve Blender 4.2.23.
  - `TODO/`: bu klasörün temizlenmemiş aslı.
- **Araç yolları:** betiklerde yollar ortam değişkeni ya da argümanla verilir (`WAYBORNE_ROOT`, `CM_FIELDS` vb.). Bu
  makinede Godot `xx/araclar/godot/Godot_v4.2.2-stable_win64_console.exe`, Blender
  `xx/araclar/blender/blender-4.2.23-windows-x64/blender.exe`.

## 7. Çalıştırma kısa yolu

```bash
godot --headless --import            # iki kez; ilk koşu 1 ile bitebilir
godot --headless --script res://tests/run_tests.gd
godot --path . --resolution 1920x1080 --position 20000,20000 --rendering-driver opengl3 --script res://tests/screenshot_journey_screen.gd
godot --headless --script res://tests/simulate_career.gd   # denge ve OLCUM satırları
```

Kare atlası yeniden paketlendiyse sayfa adları değişir. `--import` yeni dosyaları atlarsa
`--headless --editor --quit-after 30000` kullan; meşgul makinede 3000 kare yetmiyor.

## 8. Bu dalı benimsemek için önerilen ilk adımlar

1. `CLAUDE.md`'yi ve bu dosyayı oku; `git log --oneline origin/main..HEAD` ile işi gör.
2. Testleri koştur; 0 kalan bekleniyor.
3. Kullanıcıya diğer dalların bu dalın içinde olduğunu göster (bölüm 1'deki komut). Onay gelirse varsayılan dalı
   bu dal yap, sonra diğerlerini sil (`git push origin --delete <dal>`). İkisi de kullanıcının açık onayıyla.
4. Sonra DEVAM NOKTASI'ndan devam et.
