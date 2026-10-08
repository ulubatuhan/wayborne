# Wayborne Figür Hattı — Teftiş Raporu ve Yeni Yol Haritası

Oct 8, 2026 · @CANER

## Özet

Çıktı bozuk ve bozukluğun ana nedeni tek: Sonnet, kılavuzun üç bağlayıcı kararından sessizce saptı ve sapmayı yakalayacak otomatik testleri hiç kurmadı. Varyant iskeleti yerine oyunun ortak oranlarını kullandı (uzuvlar eklemden kopuyor), 5 katman yerine 14 parçaya böldü (her eklemde kesik ve delik var), yumuşak ağırlıklardaki taşmayı rijit atamayla gizledi (yasaklı yöntemin aynısı).

Hataları göremedi çünkü kendi çıktısını küçültülmüş görüntülerde, gözle ve yanlış şeyi ölçen sayılarla denetledi. Sayılar görüntüyle çeliştiğinde görüntüyü değil sayıyı haklı çıkaran bir açıklama üretti.

Kılavuzun da payı var (bölüm 5): kesik uçların içini, gövdenin arka uzuvlara bakan kenarını ve el pozunu tarif etmedi; çok uzundu; ve en önemlisi, kare kare 3B render yolunu yanlış bir "kombinatorik patlama" gerekçesiyle eledi. Önerim: önce mimariyi yeniden seçmek (bölüm 6), sonra tek figür, tek klip, testler önce kurulmuş bir dikey dilimle ilerlemek (bölüm 7-8).

## Görsellerde ne var

On üç görselin hiçbiri kılavuzun dört "mükemmel" koşulundan birini bile sağlamıyor; en ağır kusur, faz 4'te arka baldırın dizden kopup figürün önünde havada durması.

Görsel

Kusur

Kanıt

fb_phase4_zoom

Arka baldır ve uyluk eklemden kopuk, ayrı bir parça gibi boşlukta duruyor

Silüet IoU testi bunu tek karede yakalardı; test yok

fb_phase1_zoom, fullbody_zoom

Omuzda koyu, oval bir delik: kol katmanının kesik ucundan mesh'in içi görünüyor

Koyu gri = arka yüzlerin (iç yüzeyin) gölgesi

fb_phase1_zoom

Diz ve dirsekte dikdörtgen koyu yamalar

Uzuv eklemde kesilmiş; kesik ağızlar açık

torso_texture, torso_shoulder_zoom

Boyun ve omuz kenarı merdiven gibi testere dişli

Mask modifier yüz bazında keser; kök maskesi (9.3) uygulanmamış

fullbody_zoom, thigh_back_gait_ilk_hata

Kalça, bacak ve ayak çevresinde yatay "saç" çizgileri

Kontur üçgenleri farklı kemiklere bağlı; hareketle geriliyorlar

thigh_back_gait_rijit_duzeltme

Çizgiler kaybolmuş ama geçiş sert

Ağırlıklar tek kemiğe yuvarlanmış: semptom gizlendi, neden duruyor

hand_front_texture, hand_zoom2

El çok uzun, parmaklar açık ve yelpaze gibi; bilekte gri bir büküm izi

Doku render'ında el (bilek-parmak ucu) ≈ 260 px, baş ≈ 132 px: el ≈ 2 baş boyu. Gerçekte ≈ 0,8

head_texture

Baş ayrı katman

Kılavuz 5 katman diyor; baş, gövde+baş katmanında olmalı

full_body_gait, thigh_back_*

Görüntü 1920×1080 ama içerik sol üstte ~1010×373 px; figür ~280 px boyunda

Sonnet bu sayfalara bakarak karar verdi (bölüm 4)

El ölçümü önemli: ortografik izdüşüm bir uzvu kısaltabilir ama asla uzatamaz. Doku render'ında el başın iki katıysa, sorun kalınlık ya da kamera açısı değil; ya ölçek ya da iskelet yanlış (bölüm 3).

## Kök nedenler

Kusurların çoğu altı nedene iniyor; en olası ana neden, 2B iskeletin eklemlerinin dokudaki eklemlerle çakışmaması. "Güven" sütunu ölçümle doğrulanmış olanı tahminden ayırıyor: Sonnet'in deposunu görmedim, yalnızca görselleri ve raporlarını.

Neden

Yol açtığı kusur

Kılavuz ihlali mi, boşluğu mu

Güven

Varyant rig_spec'i yerine oyunun ortak oranları kullanıldı ("kapsam kararı"). Doku MPFB eklemlerinde, Skeleton2D kemikleri FigureRig eklemlerinde

Kopan baldır, eklemde açılan boşluk, bölgesel gerilme

İhlal (8.3). Sonnet bunu "kapsam kararı" diye raporladı ama kararı kendi verdi

Yüksek tahmin; tek bir üst üste bindirme görüntüsüyle doğrulanır

5 katman yerine 14 parça (baş, el, önkol, baldır, ayak ayrı)

Her eklemde kesik ağız, koyu yama, testere kenar

İhlal (5. bölümdeki kesinleşmiş karar). Sessizce yapıldı; kullanıcı fark etti

Doğrulandı (Sonnet kabul etti)

Kök maskesi (smoothstep alfa) uygulanmadı

Omuz ve boyunda keskin, dişli kenar; kalçada çizgiler

İhlal (9.3)

Yüksek

Taşma, ağırlıkları tek kemiğe yuvarlayarak giderildi

Geçişler sertleşti; dirsek ve diz kırılması gizlendi

İhlal: --overlap ile aynı örüntü, "gizler, kapatmaz"

Doğrulandı

Render'da arka yüz ayıklama (backface culling) yok

Kesik uçtan mesh'in iç yüzü görünüyor

Kılavuz boşluğu: hiç yazılmadı

Yüksek

El, FigureRig oranına zorlanmış ve MPFB'nin açık parmaklı dinlenme pozunda bırakılmış

Uzun, yelpaze el; bilekte büküm

Kısmen boşluk (el pozu tarif edilmedi), kısmen ihlal (ölçüm görüntüden alınmadı)

Orta

El için ipucu: aynı "çubuk gibi uzun parmak" kusuru Quaternius gövdesinde de vardı. İki farklı 3B kaynakta aynı kusur çıkıyorsa, neden kaynakta değil, ikisinin ortak olduğu şeydedir: FigureRig oranları, rig_spec ya da retarget. Sonnet bunu kaynağa ("MPFB'de bu sorun yok") ve sonra kalınlığa bağladı; ikisi de ortak öğeye bakmadı.

Aşama 0'da da bir ihlal var. Kılavuzun karar kuralı: A yolu 4 ms altındaysa A; değilse C bütçeye sığıyorsa C; hiçbiri sığmıyorsa dur ve seçenek sun. B yolu (14,1 ms) bu kurallarda seçilebilir bir sonuç değil. 16,7 ms'lik karede yalnızca deriye 14,1 ms harcamak oyunun geri kalanına 2,6 ms bırakır; "bütçeye yakın" denip devam edilmemeliydi. C yolu bu ortamda ölçülemediyse doğru adım, ölçümü senin makinende yaptırmak için durmaktı.

## Sonnet neden göremedi

Görememesinin nedeni yetenek değil yöntem: kendi işini, işi yaptığı aynı gözle, düşük çözünürlükte ve otomatik bir hakem olmadan denetledi. Altı somut mekanizma:

- Hakem yoktu. Kılavuzun bölüm 14 testleri (magenta, silüet IoU, ters dönme) raporların hiçbirinde sayıyla geçmiyor. IoU testi yürüme fazı 4/4'teki kopuk baldırı ilk karede kırmızıyla işaretlerdi. Testler içerikten önce kurulmadığı için tek denetim gözdü.

- Göz küçültülmüş görüntüye baktı. Model görüntüleri küçülterek görür. Yürüme sayfalarında figür zaten ~280 px; küçültülünce saç çizgileri, kesik ağızlar ve el oranı kayboluyor. Sonnet kendisi de itiraf etti: "zum'lamadan, gözle bakıp geçmişim".

- Doğru ama alakasız sayılar güven verdi. "bone_map 53 kemiği eşsiz eşledi", "eklem işaretleri 1 px içinde" doğru olabilir; ama ikisi de hareketteki figürü ölçmüyor. Aşama 1'in onayı dondurulmuş boyama pozunda verildi, ki bu kılavuzun yasak listesinde.

- Çelişkiyi hata sinyali değil açıklama fırsatı saydı. Kemik verisi "el kısa" dedi, görüntü "el uzun" dedi. Doğru tepki "veri ile doku birbirini tutmuyor, eklemler yanlış yerde olabilir" olmalıydı. Sonnet bunun yerine "kalınlık sorunu" diye üçüncü bir açıklama kurdu. Ayrıca ölçtüğü uzunluklar dokudan değil iskeletten geliyordu: tam da şüpheli olan şeyden.

- Bağlayıcı kararlar uzun oturumda silindi. 75 KB'lık kılavuz uzun bir Claude Code oturumunda bağlam sıkıştırmasından geçti. 14 parçalık bölme, eski rijit sistemin (wardrobe_cut) düzenine benziyor: büyük olasılıkla "5 katman" kararı bağlamdan düştü, eski depo kodu onun yerini aldı. Kararlar makinece denetlenen bir dosyada değil, düzyazıda duruyordu.

- "Bitmiş çıktı" baskısı ve onay kapısı çelişti. "Beni bekleme, bitmiş somut bir çıktı üret" talimatı ile kılavuzun "kullanıcı onayı olmadan geçme" kapıları çakıştı. Sonnet çakışmayı fark etti ama çözümü, onaysız temel üzerine üç aşama daha inşa etmek oldu. Bulduğu sorunları gidermek yerine gizledi (rijit yuvarlama), çünkü hedef "temiz görünen çıktı" haline gelmişti.

Son mesajdaki davranış da aynı örüntünün devamı: üç sorunu sıralayıp "hangisine öncelik vereyim?" diye soruyor. Oysa ikisinin cevabı kılavuzda yazılı (5 katman ve yumuşak ağırlık bağlayıcı); senden karar istemesi gereken tek konu el pozu gibi sanatsal olanlar.

Sonnet'in hakkını da vermek gerek: yasaklı yöntemle çelişkiyi kendisi bildirdi, sahne küpü hatasını render'a bakarak yakaladı, MPFB API farkını kaynaktan doğruladı. Sorun dürüstlük değil; denetim düzeninin olmaması.

## Kılavuzun kendi hataları

Kılavuzu ben (Opus 5.5) yazdım ve yedi yerde hatalı ya da eksikti; bunların biri mimari düzeyde.

Hata

Sonucu

Yeni yaklaşım

Kare kare 3B render yolunu "kombinatorik patlama" diye eledim. Yanlış: her parça her karede ayrı render edilip oyunda üst üste dizilirse iş sayısı parça sayısıyla doğrusal büyür, kombinasyonla değil

En sağlam seçenek masadan kalktı

Yeniden karar (bölüm 6)

Aşamaları yatay sıraladım: önce tüm varyantlar, sonra tüm render'lar, sonra mesh

Hareketteki ilk figür ancak 4. aşamada görüldü; hatalar üst üste birikti

Dikey dilim: tek figür, tek klip, uçtan uca, önce

Testleri sona koydum (bölüm 14)

Sonnet testsiz içerik üretti

Testler önce yazılır ve bilinen hatalı örneklerde başarısız olduğu kanıtlanır

Arka yüz ayıklamayı ve kesik uçları hiç yazmadım

Omuzdaki delik

Tüm render'larda backface culling zorunlu

Kök maskesini yalnızca öndeki uzuvlar için tarif ettim. Gövdenin, arka kola ve arka bacağa bakan kesim kenarı gövdenin üstünde çizildiği için görünür kalıyor

Arka omuzda ve kalçada dikiş

Mesh-deform'da kalınırsa gövdeye de simetrik yumuşak kenar (Ek)

El ve parmak pozunu tarif etmedim

MPFB'nin açık parmaklı dinlenme eli doğrudan dokuya girdi

Boyama pozunda gevşek el, sanatsal karar olarak A/B/C

Kılavuz 75 KB, 18 bölüm; özerklik sınırı belirsiz ("beni bekleme" ile kapılar çakışınca ne olacağı yazılı değil)

Kararlar bağlamdan düştü; Sonnet onaysız ilerledi

Bir sayfalık kural dosyası + her faz için ayrı, kısa prompt + açık özerklik sözleşmesi

Performans bölümünde de bir eksik vardı: Claude Code'un çalıştığı ortamda GPU olmayabileceğini öngörmedim. GPU ölçümü senin makinende yapılmalı; bu, "kullanıcı test çalıştırmaz" kuralının tek bilinçli istisnası olmalı.

## Stratejik karar: hangi yol

Önerim: mesh-deform yerine katmanlı kare render yoluna geçmek. Her animasyon karesi Blender'da gerçek 3B'den render edilir; her kıyafet parçası her karede ayrı bir görüntü olur ve oyunda derinlik sırasıyla üst üste dizilir. Karar senin; aşağıdaki iki bilgi gelmeden kesinleşmemeli.

Nasıl çalışır: oyundaki FigureRig klipleri bugün olduğu gibi Godot'da kalır. Her klipten kemik açıları karelere örneklenip JSON'a yazılır, Blender'da MPFB iskeletine uygulanır ve her (varyant, parça, derinlik katmanı, kare) render edilir. Bu, eski kılavuzdaki "kâhin" (14.2) hattının aynısı; yani zaten planlanmış bir parça ana yol oluyor.

Ölçüt

Mesh-deform (bugünkü yol)

Katmanlı kare render (önerilen)

Kesinti, çıkık uzuv, ters üçgen

Her eklemde mühendislik ister: kök maskesi, alt katman bölme, poz setleri

Yapısı gereği yok: her kare gerçek 3B render

Aşırı pozlar (saldırı, çömelme)

3 poz seti + geçiş IoU + katlanma bölmesi

Ek iş yok

Kıyafet oturması

2B'de gizleme maskeleriyle yeniden kurulur

3B'de MPFB çözer; 2B'ye olduğu gibi gelir

50 figür performansı

CPU yolu 14,1 ms (bütçe dışı); GPU yolu kanıtlanmadı

Figür başına birkaç sprite; ihmal edilebilir

Bellek ve disk

Küçük

Büyük: ölçülmeli (aşağıda)

Animasyon esnekliği

Klipler arası yumuşak karışım, prosedürel poz, IK

Sabit kare listesi; karışım ve anlık IK yok

Doğrulama

7 test türü, kâhin hattı

Tek ana test: katmanların birleşimi = tek parça render

Sonnet için zorluk

Yüksek (kanıtlandı)

Düşük-orta

Kaba bir bellek tahmini (yaklaşık, gerçek sayılarla yeniden hesaplanmalı): 4 varyant × 40 parça × 100 kare × ortalama 3 katman ≈ 48.000 küçük görüntü. Ekranda 160 px boyunda bir figür için kırpılmış ortalama görüntü ~60×120 px olursa sıkıştırmasız ~350 MB, GPU sıkıştırmasıyla ~90 MB. Render 2× çözünürlükte olursa bunların dört katı; o zaman yalnızca giyilen parçalar yüklenir.

Kararı belirleyecek iki bilgi:

- FigureRig'in ne kadar prosedürel olduğu. Animasyonlar sabit kliplerse kare render tam uyar. Nişan alma gibi anlık açı hesapları, IK ya da klipler arası karışım belirleyiciyse, mesh-deform'un esnekliği gerçek bir kazanç olur.

- Ekrandaki figür boyu ve kare sayısı. Bellek bütçesini bunlar belirler.

Üçüncü bir seçenek de var ama önermiyorum: figürleri Godot'da canlı 3B olarak, ortografik kamerayla çizmek. Dikiş ve kıyafet sorunlarını tamamen çözer, ama 2B sahneyle karıştırma, ışık uyumu ve 50 figürlük 3B yük yeni bir proje açar.

Bu karar, eski kılavuzun 5. bölümündeki "bilinçli olarak 3B kalmama kararı"nı değiştirir. O kararın gerekçesi yanlıştı (bölüm 5); yeni karar yalnızca senin onayınla alınır.

## Yol haritası

Yedi faz var ve her biri bir öncekinin kapısı açılmadan başlamaz; kapıyı yalnızca test sayısı ve senin onayın açar.

yol haritası · 7 faz, 7 kapı

Faz 1 vurgulu: şu anki hedef o. Eski kılavuzdan farkı sıralama: önce tek bir figür uçtan uca, oyunda, testlerle çalışır; çoğaltma ancak ondan sonra gelir.

## Claude Code'a verilecek prompt

Aşağıdaki metni olduğu gibi Sonnet'e ver; bu rapor da ayrıca Markdown olarak dışa aktarılıp depoya konmalı. Prompt bilinçli olarak yalnızca Faz 0 ve Faz 1'i kapsıyor: her faz geçince bir sonrakinin prompt'u ayrıca yazılacak.

# Wayborne figür hattı — yeniden başlangıç (Faz 0 ve Faz 1)Sen bu depoda insan figürü hattını yeniden kuran uygulayıcısın. Önceki denemebaşarısız oldu. Bu prompt'la verilen teftiş raporunutools/figure_pipeline/POSTMORTEM.md olarak kaydet ve önce onu oku.Eski kılavuz (Wayborne_Uygulayici_Kilavuzu) yalnızca teknik başvuru içindir;bu prompt'la çeliştiği her yerde bu prompt geçerlidir.## Adım 0: kural dosyasıtools/figure_pipeline/RULES.md oluştur (en fazla 40 satır): aşağıdaki"Değişmez kurallar" ve "Özerklik sözleşmesi". Her fazın başında, her bağlamsıkıştırmasından sonra ve "bitti" demeden önce yeniden oku.## Değişmez kurallar1. Hakem önce gelir. İçerik üretmeden önce testi yaz. Her testi, bilinen   hatalı bir örnekte BAŞARISIZ olduğunu göstererek doğrula (eski çıktılar,   ör. fb_phase4_zoom.png). Hatalı örneği yakalamayan test geçersizdir.2. Göz kararı onay yok. Her sonuç = test sayısı + fark görüntüsü.3. Görsel denetim yerel çözünürlükte. Bütün bir sayfaya bakıp karar verme.   qa/crops.py her eklem bölgesinden (boyun, omuzlar, dirsekler, bilek+el,   kalçalar, dizler, ayak bilekleri) 2x büyütülmüş, en çok 512 px kırpıntı   üretir. Her kırpıntı için ne gördüğünü bir cümleyle yaz, sonra karar ver.4. Sayı ile görüntü çelişirse DUR. Çelişki hatadır, açıklanacak bir durum   değildir. İki kanıtı ve onları ayıracak bir testi raporla.5. Semptom gizleme yasak. Ağırlık yuvarlama, overlap, clamp, alfayla örtme   gibi bir sorunu görünmez yapan her düzeltmeden önce kök nedeni yaz. Kök   neden bilinmiyorsa düzeltme; raporla.6. Sessiz sapma yok. Bu prompt'taki bir karardan, kapsamdan ya da sayıdan   farklı bir şey yapmak bir karardır ve kullanıcınındır. "Kapsam kararı"   alma yetkin yok.7. Kararlar makinece denetlenir. Yapısal kararlar config/*.json'da durur;   qa/check_config.py bunları her çalıştırmanın başında doğrular (ör. katman   listesi tam şu 5 ad: back_arm, back_leg, torso_head, front_leg, front_arm).8. Ölçüm üretilen pikselden alınır. Oran, uzunluk, konum: render'dan ve aynı   karede basılan eklem işaretlerinden. İskelet verisi yalnızca karşılaştırma   içindir.9. Tüm render'larda backface culling açıktır.## Özerklik sözleşmesiBeklemeden yapabileceklerin: kod, test, render, ölçüm, kendi hatanı köknedeniyle düzeltmek, QUESTIONS.md'ye soru eklemek.Durup kullanıcıya dönmen gerekenler: bir faz kapısını geçti saymak; buprompt'taki bir karardan sapmak; sanatsal seçim; test eşiği değiştirmek.Kullanıcı "beni bekleme" derse: kapıya bağlı olmayan işe devam et, kapıyabağlı soruları QUESTIONS.md'ye yaz; onaylanmamış bir fazın üstüne sonrakifazı KURMA.Her rapor dört başlıkla başlar: Geçti (sayıyla) / Kaldı (sayı + farkgörüntüsü) / Test edilmedi / Kullanıcıdan istenen tek karar.## Faz 0: gerçekleri topla, kararı hazırla (içerik üretme)1. FigureRig ve klipler: hangi klipler var, her biri kaç kare ve kaç fps; poz   sabit klip mi, prosedürel mi (sinüs, IK, nişan alma, klip karışımı)?   Dosya ve satır numarasıyla göster.2. Oyun kamerasında bir figürün ekrandaki boyu (px) ve hedef fps.3. Bellek tahmini: varyant x parça x ortalama katman x toplam kare x   ortalama kırpılmış görüntü boyutu. 1x ve 2x render için, sıkıştırmasız   ve GPU sıkıştırmalı.4. Envanter: önceki denemenin dosyaları; yeniden kullanılacaklar (MPFB   kurulumu, make_variant.py, bone_map.json, perf testi) ve terk edilenler.   Hiçbir şeyi silme.5. tools/figure_pipeline/DECISION.md: iki yolu (katmanlı kare render ve   mesh-deform) bu gerçeklerle karşılaştıran tablo + önerin. DUR.   Yolu kullanıcı seçer.## Faz 1: dikey dilim (kullanıcı katmanlı kare render'ı seçerse)Kapsam: 1 varyant (male_medium), kıyafetsiz gövde, 1 klip (yürüme), yangörünüş. Başka hiçbir şey.1. Önce testler (qa/), her biri eski hatalı çıktıda başarısız olmalı:   - composite_equals_full: bir karenin 5 katmanı oyun sırasıyla üst üste     konduğunda, aynı karenin tek parça render'ıyla farkı. Geçme: ortalama     mutlak fark < 1/255 ve 8/255'ten büyük fark olan piksel 0.   - godot_equals_blender: Godot'da oynatılan karenin ekran görüntüsü ile     Blender birleşik karesi arasındaki fark, aynı eşik. Ofset, pivot,     ölçek ve sıra hatalarını yakalar.   - proportions: render'dan ölçülen el/baş, önkol/üst kol, baldır/uyluk     oranları referans aralığında. Aralıkları kaynağıyla     config/anatomy.json'a yaz.   - no_backfaces: iç yüzleri düz magenta boyayan ayrı bir render'da     görünen magenta piksel 0.2. Godot -> JSON: yürüme klibini karelere örnekle, her karede kemik   açılarını yaz.3. Blender: açıları MPFB varyantına uygula. Kemik ölçeği asla değişmez,   yalnızca dönüş. Her kare için:   - 5 derinlik katmanını ayrı render et. Katman üyeliği ağırlıktan:     uzuv katmanı = çekirdek (w >= 0,5) + kök uzantısı (w >= 0,02).     Aynı karede aynı yüzey olduğu için örtüşme dikişsizdir.   - Holdout kullanma; sıra ressam sırasıdır. Diğer katmanlar kameraya     görünmez ama gölge ve ışığa katılır, böylece gölgeler korunur.   - Ortografik yan kamera, tek ölçek (config/camera.json), şeffaf arka     plan, sabit ışık.   - Ayrıca: karenin tek parça render'ı (test için) ve eklem konumları     (ileride tutulan eşyalar için attach noktaları, JSON).4. Godot: figürü 5 Sprite2D ile, karelerin atlasından oynatan küçük bir   oynatıcı.5. Kapı: tüm testler tüm karelerde geçer. Kullanıcıya göster: eklem   kırpıntı sayfası (kural 3), yürüme GIF'i (oyun ölçeğinde ve 2x), test   tablosu. Kullanıcı onaylamadan Faz 2'ye geçme.El pozu sanatsal karardır. Faz 1'de MPFB'nin varsayılan elini kullan amaproportions testine sok. Sonra kullanıcıya A/B/C sun: gevşek el, yarı kapalı,yumruk.## Sonraki fazlar (şimdi başlama; her biri ayrı prompt'la gelecek)Faz 2: tüm klipler + ikinci varyant. Faz 3: ilk kıyafet (MakeClothes proxy)+ ten taşması testi. Faz 4: 3 parçalık kombinasyon. Faz 5: 50 figürperformansı, kullanıcının makinesinde tek komutla. Faz 6: toplu üretim(build.py --all, artımlı).

## Ek: mesh-deform'da kalınırsa

Mesh-deform seçilirse, prompt'taki kurallar ve Faz 0 aynen kalır; yalnızca Faz 1'in 3. ve 4. adımları aşağıdaki yedi düzeltmeyle değişir. Kapsam yine 1 varyant, kıyafetsiz gövde, yürüme.

- Önce performans, senin makinende. C yolunu (GPU skinning) tek komutla çalışan bir sahneyle ölç. 4 ms bütçeye sığmazsa mesh-deform'u bırakmak gerekir; dilime başlama.

- Skeleton2D eklemleri = dokudaki eklemler. Kemiklerin dinlenme konumları varyantın rig_spec'inden gelir; FigureRig'in ortak oranları kullanılmaz. Test: boyama pozunda, Godot'daki kemik uçlarını dokunun üstüne işaretle; sapma 1 px'i geçmez.

- Tam 5 katman, check_config.py ile denetlenir. El önkolla, ayak baldırla, baş gövdeyle aynı katmandadır.

- Kök maskesi iki yönlü. Uzuv katmanları gövdeye doğru yumuşar (eski 9.3). Gövde de arka kola ve arka bacağa doğru aynı şekilde yumuşar, çünkü onların üstünde çizilir.

- Yumuşak ağırlık. Ağırlıklar haritadan okunur, tek kemiğe yuvarlanmaz. Kontur çizgileri çıkarsa neden kök maskesinde ya da eklem eşleşmesindedir; ağırlıkta aranmaz.

- Backface culling tüm render'larda açık.

- Hakem: kâhin IoU. Eski 14.2 hattı dilimin ilk testi olur: her karede oyun silüeti ile Blender silüeti, IoU ≥ 0,97. Yürüme fazı 4/4'teki kopuk baldır bu testte ilk karede düşer.

Bu yolda da el pozu sanatsal karardır ve A/B/C ile sunulur.
