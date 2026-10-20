# Sonraki oturum planı (limit sıfırlanınca)
## BUGÜNÜN PLANI (2026-10-20 öğleden sonra) - kullanıcı onaylı kapsam ve sınırlar

Sınırlar (kullanıcı): HAFTALIK kullanım en fazla %85 (sabah %59'du). 13:00-18:00 penceresi en fazla %80,
18:00-23:00 penceresi en fazla %100 - ama haftalık %85 önce dolarsa orada dur. Her iş sonunda get_usage; kullanıcının
"devam et" demesini bekleme. 17:30'da bilgisayar uykuya giriyor, internet yok; eve varıp açana kadar hiçbir şey
çalışmaz: 17:20'ye kadar her şey commit'li, arka planda yarıda kalacak render olmasın (yeniden başlatılabilir olsun).

Kapsam dışı: N31f (kullanıcıda), onaylanan taslakların oyuna uygulanması (9.1, 9.2/Y-G16, Y-G05, Y-G13, Y-G11T,
12.2, 9.10), lore işleri, Y-G03 (lore'a bağlı değil ama bugünkü listede yok).

ÖĞLEDEN SONRA (13:07-17:20, pencere %80):
   [12:38 durum: 1. adım BİTTİ - 2.5, 3.4, 3.6 commit 2f814b7]
   [13:35 durum: commit 3671325. Y-G02 eşya+yol hafif geçiş uygulandı (light_pass; tam geçiş zemini bozuyordu),
    turkuaz çatılar arduvaza. Y-G12 hattı ve oyun kodu hazır; ARKA PLANDA: figlogs/hd_batch.sh (hd_done.txt,
    BITTI) -> sonra figlogs/look3_batch.sh (look3_done.txt; bakma pozu 92/206 yeniden render + append + import).
    HD bitince: python -X utf8 tools/figure_pipeline/mesh/pack_hd.py, import (önbellek), test, karakter ekranı /
    gardırop / konuşma portresi görüntüsü (yakın plan keskin mi), commit. Look bitince tests/screenshot_reactions.gd
    ile denetle; el alnın önündeyse RoadCaravan.LOOK_ENABLED=true, commit.
    Sonra 5. adım: Y-H03 kalanı (şehir brifingi, karakter ekranı) ve N31e kar. Figür karelerine mürekkep (siluet
    konturu katmanı) akşam 5.4 ile; CLAUDE.md'de bedenin konturu bir kez reddedildi - yalnız birleşik siluet, dikişsiz.]
1. 13:07-13:50 2.5 açlık lekesi; 3.4/3.6/2.3 kullanılmayan varlıklar ve ölü araçlar (grep + test ile doğrula, sil,
   üretim hattından çıkar); 2.1 not. Testler, commit.
2. 13:50-14:30 Y-G12 hat değişikliği (render_frames/render_outfits ölçek seçeneği, *_hd kümeleri, FigurePreview) ve
   render'ı arka planda başlat (yalnız idle 1 kare, 6 beden + giysiler; 17:00'den önce bitmeli).
3. 14:30-15:00 N31d: elin 3B yerini kare verisinden ölç, açıyı düzelt; look_ahead render'ı Y-G12'nin ardına kuyruğa.
4. 15:00-16:30 Y-G02 mürekkep geçişi: kasaba/kapı/taverna/mezarlık (town_post), yol şeritleri, eşyalar; önce bir
   örnek karşılaştırma, sonra hepsi. Figür karelerine uygulama akşam 5.4 ile tek geçişte.
5. 16:30-17:15 Y-H03 kalanı (şehir brifingi, karakter ekranı), N31e kar. Hd ve look render'larını içe aktar, ekranda
   denetle, commit.
6. 17:15-17:20 Notlar, DEVAM NOKTASI, commit; arka planda iş kalmasın.

AKŞAM (bilgisayar açılınca, ~19:00-23:00, haftalık %85 tavanı):
7. 5.4 atlas sıkı paketleme + figür karelerine mürekkep geçişi (tek geçiş, bütün setler), testler, boyut raporu.
8. 8.9 harita hattı baştan (arka plan), karolarla karşılaştırma.
9. Y-K03 ölçüm raporu; Y-K01 5 dk oynanış videosu (Godot --write-movie, ekran dışı).
10. Tam testler, ekran görüntüsü turu.
11. GIT'E PUSH YOK, DAL AÇMA YOK (kullanıcı 2026-10-20: "en son tüm dosyaları yeni bir branche ben açacağım").
    6.1: geçmişi yeniden yazma (git lfs migrate) YAPILMAZ; yalnızca .gitattributes'a LFS izleme kuralları (png, jpg,
    ogg, wav, mp3, glb, npz, pdf) eklenir ki kullanıcının açacağı yeni dalda dosyalar LFS'e girsin. Çalışma ağacı
    temiz ve commit'li bırakılır; README güncel; teslim notu TESLIM_2026-10-20.md (yapılanlar, nasıl çalıştırılır,
    testler, bilinen eksikler, LFS notu: yeni dalda git lfs install gerekir).
Tavan dolarsa düşürme sırası: önce 8.9, sonra Y-K01 videosu; teslim notu ve temiz çalışma ağacı her durumda hazırlanır.

## DEVAM NOKTASI (2026-10-20 16:10) - TESLİM: bu dal GitHub'a yeni dal olarak gidiyor
- Kullanıcı bugün başka iş yapmayacak. Bu dal (yerel/yapilacaklar-p05-p06) bütün çalışmayı taşıyor; diğer bütün dallar
  bunun içinde (HEAD..<dal> = 0). Yeni Claude önce CLAUDE_BASLANGIC.md'yi okusun.
- 15:15'ten sonra: çivili kâğıt fiş (G8) ipucu baloncuğundan ve pazar fişinden kalktı, düz panel (46dd8c1). Geniş LFS
  kuralları geri alındı (ddc6f89; gerekçe .gitattributes). TODO klasörü proje_takibi/ olarak depoya alındı (yasak
  kelimeler temizlendi; üç .docx dışarıda), CLAUDE_BASLANGIC.md yazıldı, CLAUDE.md başına yönlendirme eklendi.
- Son test: 27301 geçti, 0 kaldı. GitHub uygunluğu: en büyük dosya 2,2 MB, yasak kelime ve anahtar taraması temiz.
- Sıradaki iş için aşağıdaki 15:15 notunun "Açık" maddeleri geçerli (N31d bakma pozu ilk sırada); "Sorulacak" maddesi
  kapandı (düz panele geçildi).

## DEVAM NOKTASI (2026-10-20 15:15, 5 saatlik pencere %72, haftalık %72)
- Öğleden sonra planı ve akşam listesinin çoğu bitti, hepsi commit'li, arka planda iş YOK, çalışma ağacı temiz.
  Bitti: 2.5/3.4/3.6, Y-G02 (eşya+yol+figür konturu), Y-G12 (HD idle), Y-H03 kalanı, N31e, 5.4, 8.9, Y-K03, Y-K01
  (video xx/video/dongu_2026-10-20.avi), 6.1 LFS kuralları, README. Son test: 27302 geçti, 0 kaldı.
- Kullanıcı kararı (14:00 civarı): çivili ipucu fişleri kaldırıldı (af53ca7); öğretici notları kendisi yazacak.
- Açık: N31d bakma pozu hâlâ yanlış (el yüzün önünde; journey_shots/tepkiler.png). LOOK_ENABLED kapalı. Öneri: ön kolu
  daha az bük (ör. FigureActions look_ahead arm_f [70, 165]), önce tests/screenshot_poses.gd ile çubuk figürde dene,
  sonra figlogs/look_batch.sh (~35 dk) + screenshot_reactions.gd.
- Sorulacak: ipucu baloncukları (tooltip) ve pazarın alım-satım fişi de aynı çivili kâğıt dokusunu (g8_slip) kullanıyor;
  düz koyu panele mi geçsin?
- Fark edilen (bugünden önceki davranış): gardıropta figür giyinik görünürken giysi yuvaları "boş" yazıyor.
- Akşama kalan: TESLIM_2026-10-20.md yazıldı; push YOK, dal YOK. İstenirse N31d poz düzeltmesi.

## DEVAM NOKTASI (2026-10-20 10:55, 5 saatlik kullanım %78 - durdum)
- Kapılar ve evreler bitti ve commit edildi. N31d: idle_tired açık; look_ahead kapalı (RoadCaravan.LOOK_ENABLED) -
  3B render'da el başın üstünde. Önce tests/screenshot_reactions.gd ile ön kol açısını ölç (çubuk figür ile 3B farklı),
  sonra figlogs/look_batch.sh ile yeniden render ve LOOK_ENABLED=true.
- Sıradaki: Y-G12 (yakın plan için yüksek çözünürlüklü idle kümesi, plan aşağıda 09:15 notunda), Y-H03 kalanı
  (şehir brifingi, karakter ekranı), Y-H07 kapsamı.
- Kullanıcı kararı bekleyen: 6.1 LFS taşıması, 2.5 açlık kenar lekesi, 3.4/3.6 ölü varlıklar, 2.1 DevPanel PC.

## DEVAM NOKTASI (2026-10-20 09:15, 5 saatlik kullanım %66)
- Arka planda: kapı batch'i (figlogs/gates_done.txt), ardından N31d render'ı (figlogs/react_batch.sh ->
  figlogs/react_done.txt, BITTI satırı). Kapılar bitince: data/assets/ui/gates/* denetle (mor gece yok mu; tame_palette
  kapılarda da geçerli) ve commit; GateArrival'ı şehir görüntüsünde kontrol et. Tepkiler bitince: içe aktar, testler
  (test_outfit klip listesi), yol görüntüsünde "Dur" temposunda yorgun bekleyiş ve işarette bakış.
- Y-G12 planı (yakın plan bulanıklığı: karakter ekranı, gardırop, konuşma portresi): yalnız `idle` 1 karesini 2-3x
  çözünürlükte render eden ayrı bir küme (`body_<v>_hd`, `outfit_<item>_<v>_hd`); render_frames/render_outfits'e
  `--scale` (camera px_per_meter ve canvas çarpanı) ve pack adımında `_hd` kimliği; FigurePreview duran figürde hd kümesi
  varsa onu çizer, yoksa bugünkü kare. Maliyet: 6 beden x ~45 giysi x 1 kare, varyant başına birkaç dakika.
- Sonra: Y-H07 kapsamı, Y-H03 kalanı (planlayıcı, brifing, karakter ekranı), 5.4 atlas sıkı paket (6.1 LFS kararından sonra).

## DEVAM NOKTASI (2026-10-20 08:40)
- Kullanıcı kararları (08:1x): köşebentler ve gravür efektleri kaldırıldı, efektler şimdilik eksik; %80'e kadar çalış.
- Bitti bu sabah: evre resimleri (81) ve commit, mor gökler arduvaza, sabah ılık; yol balonu; N31c ses otobüsleri ve
  Kenney CC0 arayüz sesleri; 4.4 açık anahtarlar; N31a beat kaydı; N31e toz/çamur; N31f ortam tablosu ve savaşta müzik
  kısma; N23 eski Tab paneli kaldırıldı; Y-H03 etki satırları sözle.
- Arka planda: kapı batch'i (figlogs/gates_done.txt, 54 render) - bitince kapıları denetle ve commit et, GateArrival'ı
  şehir görüntüsünde kontrol et.
- Kalan lore'suz: N31d (look/idle_tired klipleri, render), 5.2 mipmap (frames .import), 5.4 atlas sıkı paket (6.1 LFS
  sonrası), Y-E07 Codex dışa aktarımı ve PDF, Y-H07 kapsamı, Y-G04 (Y-G03 saç lore'a bağlı), N34 (tasarım + iskelet).

## DEVAM NOKTASI (2026-10-20 02:35, limit %98)
- Arka planda: evre batch'i (figlogs/phases_done.txt, 81 sahne, sonra tabanlar yeniden mürekkep, BITTI) ve ardından kapı batch'i (figlogs/gates_done.txt). Bitince: birkaç şehir ve evreyi görsel kontrol et (yeşil ve pembe bastırılmış, akşam mor değil), data/assets/ui/towns/*/background_*.jpg ve data/assets/ui/gates/* commit, GateArrival'ı şehir görüntüsünde kontrol et, background_path için test ekle, 9.3/N33/12.2a durumlarını güncelle.
- Yol ekranı ekran görüntüsü (balon ve güneş halesi) henüz alınmadı.
- Sıradaki lore'suz işler: N31a-f, 4.4, 5.2, 5.4, Y-G04 (büst portre), N34, 6.1/2.1/3.4/3.6 temizlikleri, Y-K03.
- Bilinen: figür kareleri yakın planda bulanık (2x render takibi).

KULLANICI TALİMATI (2026-10-20): kalan 100+ görevden lore kısıtı olmayan, yapılabilen HER görevi yap; onay bekleme, onay belgesi hazırlama; kaliteli iş, görsel kontrolü titiz yap; notları ve kayıtları güncel tut.

## ŞU AN SÜREN İŞ (2026-10-19 gece, onay paketi kararları) - limitten sonra buradan devam

Kullanıcı: "tüm bu çalışmaları yap, en son onayıma sun". Kararlar `referans/gorevler.json` notlarında.
Bitti (commit ad6a3a5): taverna tam ekran ve rotalı roller, demir fenerler, lavta elde; pazar masa düzeni ve
render terazi (`tools/ui_scenes/market_scale_scene.py`); `DialoguePanel` (taverna sohbeti, yolda tüccar ve yolcu).
Bitti (sonraki commit): 9.8 savaş arka planı biyomdan + stilize can/stres; 9.9 alt panelde küçük harita ve yük özeti;
olay kartı sahnenin içinde, kart içi görsel (EventVignette).
Taslaklar (TODO/referans/taslaklar, betikler aynı yerde): Y-G16 menü kampı sandıkta oturan yolcular (bitti);
Y-G13 kapıda vagon gece ışığı ve gölge, olay kartı oyunun kendi ekranı (bitti); Y-G10T sahnelenmiş halk, gece 4 kişi,
akşam 9 kişi, ışık bölgeden (bitti, iki görsel).
KALAN: Y-G06 gravür efektleri baştan (gravur_efekt_taslak.py: tarama/mürekkep, parlak renk yok); 9.1 UI kitini
önceki düzeltmeyle (köşebent ortası boş) ilgili sahnelerde örnek; 9.3 dört evre x kültür şehir varyantları (N33 ile,
render_all_towns); en son testler, ekran görüntüleri ve TEK onay sayfası (Artifact, onay_paketi gibi; seçimler
kopyalanıp sohbete yapıştırılır - sayfa seçimleri saklamıyor). Taslak işleri henüz commitlenmedi (TODO git değil).
OTURMA DURUŞU (kullanıcı 2026-10-20: kamp taslağında "sandıkta oturmak mı bu?" - değil; ride duruşu ata binme).
MPFB 2.0.17 izinle kuruldu (araclar/indirilenler/mpfb, sha256 doğrulandı, Blender 4.2 user_default, duman testi
geçti). Yapılacak: FigureActions'a `sit_box` ve `sit_cross` klipleri; figür hattı Linux yollarıyla yazılı
(ROOT=/home/user, 8 sabit yol) ve build/figures yerelde yok -> yolları ortamdan okut, varyant .blend'lerini
make_variant.py ile kur, yalnız kampta/tavernada giyilen giysileri fit et, yeni klipleri render et, mevcut
frames.tres atlaslarına EKLEYEN bir birleştirme aracı yaz (eski klipler yeniden render edilmeden). Sonra kamp
taslağı ve taverna oturanları bu kliple.
Bilinen sınır: yakın planda figür kareleri bulanık (kareler ~150 px için render); keskinlik için gövde/giysi
kareleri 2x render edilmeli (uzun Blender işi) - onay sayfasında söylenecek.


Kullanıcı 2026-10-19'da yarım bıraktığım işleri tam bitirmemi istedi ("tam çalışma"). Taslakla yetinmek, tek yerleşimde
bırakmak ve oyuna bağlamamak kabul değil. Önce `DEGISIKLIK_KAYDI.md`, sonra bu dosya.

## Dilimler (sırayla; her dilimden sonra kullanım kontrolü, %80'de dur)

1. **27 yerleşimin hepsi (şehir, kasaba, kervansaray):**
   - 12.1: `python -X utf8 wayborne/tools/ui_scenes/render_all_towns.py` (Blender -b, ~1,5-2 saat), sonra `test_grim_ui`.
   - N33: sabah/gündüz/akşam/gece render'ı, hepsi için; maske ortak.
   - Y-G10T halk katmanı, 12.2a kapı (`settlement_gates.py` hepsi için + render + post), 9.3 kriz/gri türetmesi.
   - 9.12 mezarlık ve kiliseye bağlama.
2. **9.x ekranları oyuna uygulama:** 9.1 UI kiti temaya (seçim köşebendi ortası boş düzelt), 9.4 mekân iskeleti, 9.5 pazar,
   9.6 karakter, 9.7 kadro kartı, 9.8/Y-G05 savaş ekranı, 9.9 yol HUD'u, 9.11 düşenler sayfası, 9.2/Y-G16 menü kampı,
   12.2/12.2e yol ışığı (N31b). Taslaklar `referans/taslaklar/`.
3. **Kapsamı daralmış işleri genişlet:** Y-H03 (kalan satırlar ve ekranlar), Y-H07 (elle boylu yazılar, diğer renk işaretleri,
   tüm karar kartlarında duraklama), Y-H05 mürekkep sıçraması (Y-G06 efektleri), Y-E07 (dışa aktarımı koştur, PDF üret).
4. **Y-G12:** MPFB2'yi indir/kur (render çıktısı CC0), yüksek çözünürlüklü manken; Y-G04 büst portre aynı hatla.
5. **8.7:** `tools/worldmap/cm/patch_labels.py` ile karolara Drazvor Boğazı'nı bas. Defter (DFT1) lekelerindeki ızgara kalıntıları.
6. **Akşam koşusu:** `TEST_BEKLEYEN.md` baştan sona.

## Yapılmadı ve nedeni (açık yazılı)

Y-A07, Y-J04, Y-J09, Y-H06, Y-H02 (ilk 10 dk akışı), N31, N33, N34: yalnız plan, liste ya da görev. Kod ya da üretim yok.
CK ve CI görevleri kullanıcı kararı ya da lore bekliyor (`KALAN_ISLER.md`).
