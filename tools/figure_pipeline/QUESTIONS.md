# QUESTIONS — kullanıcı kararı bekleyenler (Faz 0)

Ana kapı (rapor başlığındaki tek karar): **yol A mı B mi** — bkz. DECISION.md §6.
Aşağıdakiler yoldan bağımsız ya da yola bağlı alt sorular; Faz 1'e başlamadan yanıt gerekir.

1. **Hedef makine ve fps.** Projede tanımlı değil (`project.godot`: `max_fps` yok). Varsayım 60 fps / kullanıcının makinesi. (Faz 5 ölçümü ve B yolunun C-GPU kuralı buna bağlı.)
2. **Varyant sayısı ve parça sayısı.** Bellek tablosu 2/4/6 varyant ve 40 parça/varyant varsayıyor (POSTMORTEM örneği); gerçek sayılar belirsiz.
3. **Render çözünürlüğü ve kare sayısı (yol A).** 1× (kutu ≈119 px) mi 2× mi; yürüme çevrimi 24 / 32 / 48 kare mi? (Bellek: DECISION.md §3. Web hedefi sürüyorsa tablo indirme boyutudur.)
4. **Sürekli girdiler için politika (yol A).** `motion` geçişi (0,12/0,25 sn): (a) duran↔yürüme arası ani geçiş, (b) sprite çapraz geçişi, (c) ek yarım-genlik seti. `lean` (≤5,4°, rüzgâr): (a) hiç, (b) tüm-figür dönüşü ile yaklaşık, (c) ek set. Atlı lider (`seated`): ayrı render seti mi, bu dilimin dışında mı?
5. **Ayakların yere basması (iki yol).** FigureRig uyluk=kaval=120 birim; MPFB uyluk 109,9 / baldır 114,7 (önceki iskelet ölçümü, yalnız karşılaştırma). Faz 1 "kemik ölçeği asla değişmez, yalnızca dönüş" der; açılar kopyalanınca ayaklar yerden kopar/gömülür. Kalça (kök) yüksekliğini her karede ayak yere değecek şekilde ayarlamak (ölçek değil, öteleme) serbest mi?
6. *(Faz 1 sonunda, sanatsal)* El pozu: A gevşek / B yarı kapalı / C yumruk.

## Faz 1 kapısında açılanlar (ayrıntı: FAZ1_GATE.md)

7. **[KARAR: (a), uygulandı]** **FigureRig yürüyüşü ters (ay yürüyüşü).** `figure_rig.gd` `_leg`: `ankle.x = hip.x + cos(faz)·adım·yön`, ayak `sin(faz)>0` iken havada; `walk_figure.gd:164` fazı zamanla ARTIRIYOR. Yerdeki ayağın kalçaya göre hızı `−sin(faz)·adım` > 0 → yerdeki ayak ÖNE kayıyor, havadaki geri gidiyor. Klip bunu birebir taşıyor (f00→f12: yerdeki ayak x 120→197). Seçenek: (a) oyunda `_leg`'i düzelt (oyunun tüm insan figürleri değişir, ayrı iş); (b) yalnız bu hatta kareleri ters sırayla oynat (oyunla uyuşmaz); (c) olduğu gibi bırak.
8. **AA kenar fazlası (composite_equals_full 0/24).** Kök neden: üst üste binen kök uzantısı yüzeyi dış siluette iki katmanda kısmi kapsama → 2a−a²; ayrıca iç kenarlarda arka katmanın örtülü kısmının ortalamaya girmesi. AA kapalıyken 24/24 eşit. Seçenek: AA kapalı / örnek düzeyinde holdout (prompt holdout'u yasaklıyor) / eşik değişikliği / daha dar örtüşme.
9. **Ön kol / üst kol = 1,06** (aralık 0,70–0,90). MPFB male_medium'un kendi oranı (üst kol 0,146H). Seçenek: MPFB `measure-upperarm-length` modifikatörü ile varyant / aralığı değiştir / kabul.
10. **no_backfaces testi zayıf.** 256 örnekle 24/24 geçiyor ama ön kol katmanında omuz arkasında (x=148) magenta piksel duruyor (253,72,253 α≈0,56); birleşimde gövdeyle karışınca yeşil > 0,35 olup sayılmıyor. AA kapalıyken 3–4 px geometrik. Normal render'da o pikselde ön kol katmanı boş (iç yüz kesildi, arkadaki gövde katmanı görünüyor), birleşim = tek parça. Test her katmanı ayrı saysın mı (eşik/test değişikliği = kullanıcı kararı)?
11. **Duruş (FigureRig'in kendisinden).** Geçiş karesinde basan diz 22,7°, sallanan 69,7° bükük; sallanan ayak düz tabanla basan ayağın tam üstünde (x farkı 0,8 px) → çömelmiş/sekiyor görünüm. Kaynak klip; aktarım sadık. Değiştirilsin mi?

12. **Hayvanlar da ay yürüyüşü yapıyor.** `BeastRig` (`beast_rig.gd:235,439`) ve prosedürel `walk_figure.gd:_draw_quad_leg` aynı `cos(faz)` adımını kullanıyor. Kullanıcının seçtiği (a) yalnız FigureRig'i kapsıyordu; hayvanlar ayrı karar (skin'ler ve `PAINT_PHASE` etkilenir).

## Faz 3'te açılanlar (giysi modülleri; ayrıntı: build/figures/garments_qa/male_average_walk/)

13. **Ten taşması: çıplak beden giysinin kenarından görünüyor (skin_bleed 0/3).** Deneme: `shoes03` + `male_casualsuit01`, male_average, yürüme f00/f03/f05. Taşma 25/31/30 px; çoğu ayak ucu ve topukta (ayakkabı), az kısmı boyun yakası ve bilek manşetinde. Hakem geçerli: aynı karelerde sıra ters çevrilince 5131/4544/3897 px yakalıyor. **Kök neden:** 3B'de MPFB giysinin altındaki bedeni silme grubuyla (`Delete.<giysi>`) gizliyor; 2B bindirmede beden çıplak çiziliyor ve pozlanmış beden bazı yerlerde giysinin dışına taşıyor (parmak ayakkabının önünden, kol kenarı manşetten). Giysiyi şişirmek/örtüşme semptom gizleme olur. Seçenekler:
    - (a) **Bedeni silme gruplarına göre bölmek**: her giysi için bedenin "bu giysinin altında kalan" kapsamı ayrı render edilir; oyun giyilen giysilerin altındaki beden parçasını çizmez. 3B'deki doğruyu birebir taşır, beden belleği artmaz; ama parça sınırlarında AA dikişi riski var (Q8 ile aynı aile) ve WalkFigure çizimi parçalara göre kurulmalı.
    - (b) **Kıyafet seti başına ayrı beden render'ı**: kesin, ama bellek set sayısıyla çarpılır.
    - (c) Kabul (taşma 1-2 px kenar, oyun ölçeğinde ~5 kat küçülür).
14. **Kıyafet kaynağı (sanatsal).** MPFB CC0 paketindeki giysiler modern (kot, tişört, spor ayakkabı; bkz. scratchpad/thumbs). Gri gölgeye indirgenip oyunda yeniden boyandığı için desen/logo görünmüyor, yalnız siluet ve kıvrım kalıyor; yine de kesim modern (yakalı gömlek, düz paça). Seçenek: bu paketle siluet olarak yetin / Wayborne'a özel MakeClothes giysileri modellenip eklensin / ikisi.
15. **Pantolon paçasının içi (no_backfaces 0/3, 1-3 px).** Arka bilekte paçanın açık ucundan iç yüz görünüyor. Geometrik (açık tüp); ciddi değil ama test eşiği 0.
