# Pilot: tek rölanti çizimi bütün pozlara bükülebilir mi?

**Soru (kullanıcı, 2026-10-27):** bir karakter tek bir çizimle kullanılabilir mi? Duruşlar, hareketler, üstüne oturan
kıyafetler nasıl oluyor?

**Cevap: evet, bir şartla.** Gövde, kol, bacak, pantolon, gömlek, ceket, çizme, şapka, saç ve cüppe on dört pozun hepsinde
(yürüyüş, savaş duruşu, kılıç, mızrak, yay, darbe, savunma, kaçınma, binicilik, oturma, yere düşme, ölü) 3B render'a yakın
bükülüyor. Şart: **etek, elbise ve cüppe tek parça olarak çizilmeli**, beş derinlik katmanına bölünmemeli. Bölünen etek
adım açılınca ortadan yarıldı. Tek parça `etek` katmanı ise adımla birlikte açılıyor. Şablonlar ve envanter buna göre
güncellendi: bu yedi giysinin altı katmanı var.

## Nasıl denendi

Elle çizilmiş bir figür henüz yok. Yerine bir **yedek çizim** kullanıldı: bedenin ve giysilerin HD rölanti render'ı
mürekkep hattı ve dört düz tonla elle çizilmiş bir resme benzetildi. Gerçek çizim aynı beş katmanda, aynı eklemlerle
geleceği için bükülme davranışı aynı; yalnızca doku farklı. Saçtaki noktacıklar ve ceketteki ince çizgiler bu yedeğin
izi, yöntemin değil.

Yöntem (`tools/el_cizimi/pilot/figur_deri_pilot.py`, oyuna girecek HumanSkin'in Python ön örneği):

1. **Dinlenme iskeleti:** HD rölanti karesinin kendi eklemleri. Karede olmayanlar (arka diz ve bilek, ayak uçları)
   FigureRig'in rölanti pozundan ölçeklenip taşındı.
2. **Ağırlıklar:** her katman kendi kemiklerine bağlı (ön kol katmanı: üst kol, önkol, el...). Her piksel kemik
   parçalarına uzaklığıyla ağırlıklanıyor; dirsekte ve dizde iki kemik yumuşakça karışıyor. 3B ağırlık yok, gerek
   olmadı.
3. **Hedef poz:** oyunun kendi klipleri (`FigureActions`, `export_clips.gd`). Her kemik dinlenme açısından karedeki açıya
   döndürülüp ileri kinematikle yerine kondu.
4. **Çizim:** her katman 5 piksellik bir üçgen ızgarasıyla, doğrusal karışımlı deri (BeastSkin'in insan sürümü).
5. **Etek:** belden aşağısı kalçadan uzaklaştıkça uyluklara geçiyor. Önü o karede öndeki uyluğu, arkası arkadaki
   uyluğu izliyor. Bu yüzden etek adımla açılıyor.

## Sonuçlar

Her çiftte solda bugünkü 3B render karesi, sağda tek çizimin bükülmüş hâli.

| Dosya | Ne |
|---|---|
| `pilot_erkek_koylu.jpg` | köylü pantolonu, gömlek, deri çizme, keçe başlık |
| `pilot_erkek_korucu.jpg` | korucu pantolonu, bağcıklı gömlek, korucu ceketi, çizme, kısa saç |
| `pilot_kadin_etek.jpg` | uzun etek, köylü bluzu, ayakkabı, örgülü saç |
| `pilot_erkek_cubbe.jpg` | hacı cüppesi, kapüşon |
| `pilot_yuruyus_*.gif` | 24 karelik yürüyüş, render ve çizim yan yana |
| `pilot_etek_yuruyus.jpg` | eteğin yürüyüşte altı karesi |
| `pilot_eklem_yakin.jpg` | dirsek, diz ve omuz yakından (kılıç, yürüyüş, oturma, savunma) |
| `alim_denemesi_oyunda.jpg` | alım aracının oyun içi denemesi: vagon, öküz ve orman şeridi yedek "çizimle" değiştirildi |

**İyi gidenler:** yürüyüş ve bütün savaş pozları; giysinin bedene oturması (aynı kemikler, aynı ağırlıklar; render'daki
gibi kayma yok); çizmeler dizden ve bilekten doğru dönüyor; kapüşon ve şapka başla dönüyor; yere düşme ve ölü pozu.

**Zayıf kalanlar (oyuna geçerken çözülecek):**

- **Oturma:** uzun etek ve cüppe dizlerin üstünde kıvrılıyor; render'da kumaş dizlerin üstünden dökülüyor. Bu yedi
  giysi için ileride ikinci bir anahtar çizim (oturuş) eklenebilir. Kamp ateşi oturuşu da buna bağlı (Ana Hedefler).
- **Binicilik:** bacaklar atın arkasında kalıyor (oyunda da öyle), üst gövde doğru.
- **Büyük omuz açıları:** kol başın üstüne kalkınca ceketin omuz dikişi biraz uzuyor. Çizerin "eklemde bindirme"
  kuralı (SUREC.md §5) bunu kapatır.
- **İnce ve iri bedenler** henüz denenmedi. Plan: orta bedenin çizimi, render'daki ince ve iri silüetlerin satır başına
  genişlik oranıyla yatayda esnetilir. İlk gerçek beden çizimiyle birlikte denenecek.

## Oyuna geçiş (ilk gerçek beden çizimi gelince)

1. `HumanSkin` (GDScript, `BeastSkin`'in kardeşi): katman ızgarası, kemik ağırlıkları, `FigureRig` açılarıyla deri.
   Pilotun ağırlık ve etek kuralları birebir taşınır.
2. `WalkFigure._draw_person_frames`, bir kişinin bedeni ve giysileri için el çizimi deri varsa onu, yoksa bugünkü render
   karelerini kullanır. Sanat parça parça gelebilir; Wardrobe kuralı aynı.
3. Ölçü: `tests/screenshot_mannequin_walk.gd` ve yürüyüş testleri çizimli figür için de koşar; ayak kayması ve diz yönü
   testleri aynı kalır.
