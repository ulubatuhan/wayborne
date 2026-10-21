"""`gorevler.json`'daki 'test bekliyor' görevlerinden ekran ekran test turu dokümanı üretir.

Çalıştır: python -X utf8 proje_takibi/referans/test_turu_uret.py
Çıktı: proje_takibi/TEST_TURU.md ve proje_takibi/TEST_TURU.html (onay kutulu, tarayıcıda açılır).
Her görev kimliği tam bir kez geçer; json'da 'test bekliyor' olup burada olmayan varsa betik hata verir.
"""
import html
import json
import os
import sys

BURASI = os.path.dirname(os.path.abspath(__file__))
KOK = os.path.dirname(BURASI)

# (ekran, kimlik, nasıl ulaşılır, ne görmeli, ne bozuksa not al)
# Ekran sırası = turun sırası: menüden başlayıp şehre, yola, savaşa, deftere.
EKRANLAR = [
    ("1. Ana menü ve yeni oyun", [
        ("Y-D01", "Ana menü → Yeni Soy. Açılan ekranda zorluk bölümüne bak.",
         "Kader Modu seçeneği ve üç açık ayar (ölümcül vuruş direnci, açlık hasarı, olay sertliği) yazıyla görünür; Standart seçiliyken eskisi gibi oynanır. Kader Modunda oyun içi menüde elle kayıt kapalı ve nedeni yazıyor.",
         "Gizli bir zorluk ya da nedensiz kilitli düğme"),
        ("Y-D03", "Bir oyunu bitir (ya da DevPanel F1 ile soyu bitir) → yeni oyun.",
         "Önceki soyun mezarları yola/haritaya soluk döner, itibarın bir payı gelir, deftere eski soyun adı yazılır. `user://lineage_archive.json` oluşur.",
         "Mezarlar hiç görünmüyor ya da itibar sıfırlanmıyor"),
        ("Y-H07", "Ana menü → Ayarlar; sonra yol ve savaşta etkisine bak.",
         "Metin boyutu dört kademe (menüler büyür/küçülür, taşma yok); desenli şerit açıkken savaştaki kan şeridi parçalı çiziliyor; otomatik duraklatma açıkken yol işareti/karşılaşma işaretinde zaman bir tuş ya da tıklamaya kadar duruyor. Hızlandırma seçeneği yok. Ayarlar kayıt dosyasında değil `settings.cfg`'de.",
         "Büyük metinde taşan düğme ya da duraklatma kapalıyken zamanın durması"),
        ("Y-A01", "Doküman kontrolü: `CLAUDE.md` en üstü.",
         "Vaat cümlesi ve dört sütun yazılı. Cümle sizin sesinizle uyuşuyor mu? Uyuşmuyorsa değiştirin (kutu 'öneri, onay bekliyor' diyor).",
         "Cümle size yabancı geliyor"),
    ]),
    ("2. Şehir ekranı ve mekânlar", [
        ("9.3", "Bir şehre gir; sabah/gündüz/akşam/gece için DevPanel F1 ile saati değiştir.",
         "Şehir önü resmi saate göre değişiyor, şehir adı ve ihtiyaç levhaları okunuyor.",
         "Saat değişse de resim aynı"),
        ("N33", "Pazar, lonca, taverna, han, kilise ekranlarını sırayla aç (saat değiştirerek).",
         "Her mekânın arka planı günün evresine uyuyor; geçişte kesilme/titreme yok.",
         "Bir mekân hep aynı evrede kalıyor"),
        ("9.4", "Şehirden sırayla: Pazar, Lonca, Taverna, Han, Kilise, Terzi, Kıyafet Dolabı.",
         "Hepsi aynı görsel dilde (koyu masa, ince çizgili paneller); metin okunur; geri düğmesi her zaman görünür.",
         "Gri/kutu ekran, taşan yazı, ulaşılamayan geri düğmesi"),
        ("9.12", "Kilise → mezarlık bölümü; ölüm olmuşsa 'nöbet' hâli.",
         "Mezarlık arka planı iki hâlde (sakin / nöbet) görünüyor.",
         "Arka plan boş ya da yanlış hâl"),
        ("12.2a", "Şehir kapısı: yola çıkarken ve şehre varırken kapıyı izle.",
         "Kapı sur geçidi olarak çizili (düz renk kutu değil); kanat lider yaklaşınca kalkıyor.",
         "Düz dikdörtgen ya da kanat takılıyor"),
        ("Y-C16", "Taverna/Meydan/Lonca → işe alım panosu (birkaç şehirde).",
         "Pano çoğu zaman 1-2 kişi; her adayın neden geldiği yazıyor; savaş/veba haberinde bir kişi eksik; fiyatlar önceki sürümden pahalı.",
         "Pano hep dolu ya da adayın hikâyesi yok"),
        ("Y-C10", "Pazar: bir şehre ilk varışta ve 20+ gün sonra komşu fiyatlarına bak; taverna'da sohbet et.",
         "Gördüğün fiyatların yanında 'kaç gün önce' yazıyor, 20 günden eskiler soluk. Söylenti bazen yalan çıkıyor.",
         "Tarihsiz fiyat ya da hep doğru söylenti"),
        ("Y-C11", "Pazar satırının üstüne gel.",
         "Fiyat satırında kısa etiketler (mevsim, arz baskısı, haber vb.), üstüne gelince katman başına bir cümle.",
         "Fiyat değişti ama nedeni yazmıyor"),
        ("Y-C19", "Pazar: balık, kaçak tuz ve mühür alıp satmayı dene; 20+ adet toptan al; aldığın şeyi hemen geri sat.",
         "Balık yolda bozuluyor; kaçak tuz yalnız han'da alınıyor; toptan alımda indirim; aynı ziyarette geri satış alış fiyatının en çok %90'ı.",
         "Alıp aynı yerde satarak kâr edebiliyorsun"),
        ("Y-C02", "Tüccar Loncası → kontrat panosu (iki şehirde karşılaştır).",
         "Pano her varışta farklı 4-7 ilan; teslimat, refakat, yolcu, kaçak yük türleri; acil olanlar kısa süreli ve daha yüksek ücretli.",
         "Her seferinde aynı ilanlar"),
        ("Y-C05", "Kilise → hekim (yaralı/hasta bir yoldaşla; veba şehrine varış).",
         "Hekim altın + şehrin ilaç stoğundan bir birim harcıyor; stok yoksa kilitli ve nedeni yazıyor. Veba şehrine varışta bulaşma olabiliyor.",
         "Stok bitince bile iyileştiriyor"),
        ("Y-F04T", "Bir vagona yürü/tıkla (hub'da vagon etkileşimi) → atölye.",
         "Vagonun kendi yükü ve tarif listesi; yapılamayan tarif nedeniyle kilitli; başka vagondaki malzeme sayılmıyor.",
         "Tarif başka vagonun malzemesini kullanıyor"),
        ("Y-F03", "Atölyede her tarifi bir kez yap (sargı, branda onarımı, kürk şapka, balık yağı, meşale).",
         "Her ürünün bir kullanım yeri var (sargı savaşta/kampta, yağ fenerde, meşale gece yürüyüşünde).",
         "Üretilip hiçbir işe yaramayan eşya"),
    ]),
    ("3. Karakter, kadro ve defter kartları", [
        ("9.6", "Karakter ekranı (kadrodan bir kişi).",
         "Stat ve yetkinlik bölümü yeni görsel dilde; sekiz stat okunuyor; kıyafet önizlemesi yanında.",
         "Taşan satır, kesik yazı"),
        ("9.7", "Kadro (party) ekranı ve yol altındaki Kadro sekmesi.",
         "Kişi kartında seviye rozeti net; kart içeriği kesilmiyor.",
         "Rozet okunmuyor"),
        ("Y-F09", "Karakter ekranı → görev ata (öncü / ortancı / artçı).",
         "Üç rol var (altı eski görev bu rollerin altında etki olarak duruyor); sınıf görev gücünü çarpmıyor; eski kayıt yüklenince roller doğru dağılıyor.",
         "Eski kayıtta görev kaybolması"),
        ("Y-C17", "Yoldaşın karakter ekranı; kampta bağ yüksekse kamp hikâyesi.",
         "Her yoldaşın geçmişi ve kişisel hedefi (tanıdıkça) yazıyor; kamp hikâyesi üç bölüm; üçüncüsü (sır) en ağır kırgınlığı hafifletiyor.",
         "Hikâye hiç açılmıyor"),
        ("Y-F01", "Yolda hızlı tempo, gece yürüyüşü, kamp; karakter kartında takat.",
         "Her kişinin yorgunluğu ayrı; en yorgun kişi kervanın takatini bağlıyor ve adı yazıyor; kamp -30, şehir -60.",
         "Yorgunluk hızı değiştiriyor (değiştirmemeli)"),
    ]),
    ("4. Planlayıcı ve dünya haritası", [
        ("Y-F10", "Şehirden yol seçip planlayıcıyı aç.",
         "Tehlike yüzdesinin dökümü: taban, yol durumu, dünya olayı, zamanla büyüme satırları.",
         "Tek bir sayı, nedensiz"),
        ("Y-B13", "Aynı rotayı farklı mevsimlerde planla; 5+ günlük rotada kestirme seç.",
         "İlkbaharda bataklık, yazın kuruma, kışın dağda yavaşlama; kestirme -%20 gün ve tehlike +; erzak rezervi buna göre.",
         "Erzak kestirmede yetmiyor"),
        ("8.5", "Haritayı aç (M) ve kenti/yolları gez.",
         "Kent adlarının altında yol çizgisi okumayı bozmuyor; adlar IM Fell yazı tipinde ve okunur.",
         "Yazı yol çizgisine biniyor"),
        ("8.7", "Haritada boğazı bul.",
         "Boğazın kesin bir adı var (geçici 'Kesgrav Boğazı' kalmamış olmalı; ad lore'a uyuyor mu?).",
         "Yer tutucu ad"),
        ("8.10", "Haritayı gündüz/akşam/gece aç (saat değiştir).",
         "Harita akşam sıcak, gece mavi-gri kararıyor; yazı her saatte okunuyor.",
         "Gece harita okunmaz oluyor"),
        ("8.11", "Haritayı akşam/gece aç, yakınlaş.",
         "Şehir ve yerleşimlerde küçük ışıklar akşam belirir (şehir 6-12, kasaba 3-5, köy 1-2, harabede yok); yakınlaşınca boyutları sabit.",
         "Işık harabelerde de var ya da hiç yok"),
        ("Y-G09", "Bir sefer bitir, haritaya bak.",
         "Bitmiş yolun ince mürekkep izi ve kamp yerleri haritada kalıyor.",
         "İz yok ya da kayıttan yüklenince kayboluyor"),
        ("N29", "Vadi şehri çevresindeki yola çık.",
         "Vadiye özgü yeşil çayır katmanı (kuru ot değil); biyom geçişi yumuşak.",
         "Vadi hâlâ kuru bozkır"),
        ("N30", "Bozkırdan geçen uzun bir yola çık.",
         "Duraklar arası en az 6 gün; 35 günlük yolda 5 durak yok.",
         "Durak peş peşe"),
    ]),
    ("5. Yol: yürüyüş, figürler, kamp", [
        ("10.1", "Yola çık, atlı lideri yandan izle.",
         "Binici atın sırtında biraz geride, eğerin üstünde oturuyor; dönüşte de aynı.",
         "Binici atın boynunda/önünde"),
        ("10.2", "Yürürken liderin kollarına bak.",
         "Atlı lider yürür gibi kol sallamıyor; kollar sakin (oturma/ride dinlenme karesi).",
         "Kollar sallanıyor"),
        ("10.4", "Vagonu çeken öküze bak.",
         "Çeki oku öküzün boynuna uzanıyor, boyunduruk öküzün üstünde çizili; öküz vagona bağlı okunuyor.",
         "Öküz vagondan kopuk"),
        ("12.2b", "Bir yol durağının (kule vb.) yanında kamp kur.",
         "Kamp başlayınca durak kadrajdan kaçmıyor, yerinde duruyor.",
         "Durak bir anda uçuyor"),
        ("12.2c", "Akşam kamp kur; ateşe yürüyüşü izle (1x hızda).",
         "Herkes en çok ~3 sn'de ateşe varıyor; kamp süresi herkes oturunca başlıyor; sabah olmadan ateşteler.",
         "Yürüyüş uzun sürüyor, sabah oluyor"),
        ("12.2e", "Yol sahnesini gündüz/akşam/yağmurda izle.",
         "Çimen, yol, arka plan ve ışık tek prodüksiyon gibi; zemin kaymıyor, yol ortada.",
         "Yol 'Excel gibi' ya da zemin kayıyor (kararını yaz: yeniden tasarım gerekir mi?)"),
        ("Y-B09", "Yolda bir süre bekle ve hızlandırma düğmesini ara.",
         "Hızlandırma yok (yalnızca 0.5x ve 1x); yol boş gelmiyor: yaklaşık 60-90 sn'de bir karar ya da bilgi var.",
         "Boş sessiz dakikalar"),
        ("N23", "Yolda eski HUD parçalarını ara.",
         "Eski üst/alt bar kalıntısı yok; yalnızca gösterge plakası ve kontrol paneli var.",
         "Çift gösterge, üst üste binen yazı"),
        ("5.1", "Menüde, şehirde, yolda 2-3 dakika dur; kumanda ve sahne geçişlerini dene.",
         "Ortam animasyonu görünmezken çizilmiyor; terazi dengedeyken titremiyor; kumandada her şey çalışıyor; sahne geçişi bozulmuyor.",
         "Kumanda ya da geçiş bozuldu"),
    ]),
    ("6. Yol: insanlar, işaretler, hava, gece", [
        ("R0", "Lideri bir yoldaşın yanına yürüt ve bekle.",
         "Yoldaşın başında kısa söz balonu; satır log'a da yazılıyor; aynı anda en çok iki balon.",
         "Balon çıkmıyor ya da üst üste biniyor"),
        ("Y-B01", "Birkaç gün yürü; farklı yoldaşlarla yan yana ol.",
         "Konu seçimi: kırgınlık > stres > geçmiş > görev > kültür > hava > sohbet; aynı konu birkaç gün dinleniyor.",
         "Hep aynı cümle"),
        ("R1", "Kampta hikâye (bağ yüksek) ve dostluk/rekabet.",
         "Dostlar kolonda yakın yürür, rakipler uzak; sıkıntılı biri bazen kendi başına bir şey yapar (ekmeğini paylaşır, dua eder).",
         "Kimse hiç kendi kendine davranmıyor"),
        ("Y-B02", "Uzun bir yolda 'sessiz' günler ve ağır bir karttan sonraki günü izle.",
         "Sessiz günler birikince kart ihtimali artıyor; ağır karttan sonra rahatlık; gece işaretler sıklaşıyor (ateş/nöbet/fener bunu azaltıyor).",
         "Üç sessiz gün arka arkaya ya da iki ağır kart arka arkaya"),
        ("Y-B03", "Yolda duman/gıcırtı/arkada kuş gibi işaretlere git ve görmezden gel (iki ayrı sefer).",
         "Gidince gerçek yüzü ve küçük ödülü açılıyor; görmezden gelince o gerçeğin bedeli ödeniyor; bazı gerçekler bedelsiz.",
         "İşaretin türü cevabı veriyor"),
        ("Y-B04", "Rol sahibi (öncü/ortancı/artçı) varken lideri başka bölgede tut.",
         "Rol sahibi kendi bölgesindeki işareti liderin yerine yakalayabiliyor (saatlik ~%3.5).",
         "Rol hiçbir fark yaratmıyor"),
        ("Y-B05", "Farklı havalarda emir panelindeki küçük kararlar.",
         "Her hava 1-2 tek tıkla karar (erken çık, yağmurdan önce it, çamur kestirmesi, fener, fırtınada sığın); sonuçları yazılı.",
         "Karar etkisiz ya da erzak sözü bozuluyor"),
        ("Y-C20", "Geceye kadar yürü; fener/meşale yak ve yakma.",
         "Işıksız gece takat ve tehlike bedeli; fener gece 1 yağ, meşale 2; liderde parıltı.",
         "Gece bedelsiz"),
        ("R4", "Nehir geçidi olan bir yol (ford) ve gece yürüyüşü.",
         "Su seviyesi (düşük/orta/yüksek) kartta; doğru geçiş seçeneği açık, yanlış olanlar nedenle kilitli; kimse ölmüyor, vagon kaybolmuyor.",
         "Geçişte ölüm/vagon kaybı"),
        ("Y-B10", "Yolda başka kervanlarla karşılaş (birkaç sefer).",
         "Askerî konvoy (borç/arama), mülteci (yoldaş), hacı, rakip tüccar (bilgi/iftira) kartları.",
         "Karşılaşma hiç olmuyor"),
        ("Y-B06", "Yolda av, köy durağı ve toplama.",
         "Vahşi hayvan zaferi +10 erzak; köyde birim fiyat şehirden pahalı; toplama +10 erzak ve +1 gün.",
         "Erzak bedava geliyor"),
        ("Y-B07", "Akşam sofra panelini aç (şarap/bal/balık varken).",
         "Çeşni yalnızca panel açıkken teklif ediliyor; erzak payı ve planlayıcının sözü değişmiyor.",
         "Standing order çeşni harcıyor"),
        ("Y-B12", "Kampta nöbet ve formasyon.",
         "Öncü +1 stres/gün; nöbet ertesi günün tehlikesini düşürüyor; akşam en çok iki eylem.",
         "Kamp panelinde sıkışma"),
        ("Y-B08", "Akşam kampında 'günün satırı' (defter cümlesi).",
         "O günün en ağır olayına göre üç cümle sunuluyor; birini seçiyorsun ya da hiçbirini; yazmıyorsun.",
         "Cümleler sayı içeriyor ya da yazı kutusu çıkıyor"),
        ("Y-B11", "Biri öldükten/vagon kaybından sonra o yoldan tekrar geç.",
         "Mezar, kayıp vagonun enkazı, kamp külü yolda görünüyor; geçerken log'a satır (lider önde ise ad ve neden).",
         "Anıtlar yerinde değil/yönden bağımsız kayıyor"),
        ("R2", "Yukarıdaki üç madde birlikte: mezar + gün satırı + kamp külü.",
         "Defter ve yol aynı hafızayı gösteriyor.",
         "Defterde olup yolda görünmeyen"),
        ("Y-F05", "Tüccar refakat al; yolda kartlar.",
         "Hırsız tüccar gece kaçıyor, çaresiz olan tehlikede dönmek istiyor, kinci kavga çıkarıyor, sadık erzak paylaşıyor.",
         "Tüccar hiç tepki vermiyor"),
        ("Y-C15", "Orta ve geç oyunda (10. ve 25. sefer sonrası) kart dağılımı.",
         "Pusu, savaş/veba/haraç haberleri, rakip kervan ve gümrük sıklaşıyor.",
         "Oyun hiç sertleşmiyor"),
        ("Y-F07T", "Nadir olay: haydut büyücü (zor bulunur).",
         "Çok nadir ve bir kez çıkıyor; tehlikeli yolda; savaşta ilk yıkıcı büyü.",
         "Her sefer çıkıyor"),
        ("Y-D06", "Kırılmış bir yoldaşla bir sefer.",
         "Dört kip (öne atılır, alay çeker, reddeder, yakındakine saldırır) son kötü huya göre; ekran efekti yok; yolda kırılma kartı.",
         "Kırılma sadece sayı"),
        ("Y-H04", "Her paneli aç ve Esc ile çık; karar panellerinde Esc'e bas.",
         "Hiçbir ekranda sıkışma yok: paneller Esc'e yanıt veriyor; karar panelleri (devralma, kader) yutuyor.",
         "Çıkılamayan ekran"),
    ]),
    ("7. Savaş", [
        ("Y-H05", "Savaşta vuruş, kritik ve öldürme anları.",
         "Kritikte sahne hedefe yaklaşıyor ve defter satırı çıkıyor; öldürme anında kısa duraklama sonra düşüş; vuruş/kritik/öldürme sesleri çeşitli ve perde oynuyor.",
         "Ses hep aynı ya da yakınlaştırma takılıyor"),
        ("Y-C07", "Dar durumda geri çekil.",
         "Savaş paneli geri çekilmeyi teklif ediyor: yükün üçte biri, bir vagon feda (enkaz yolda kalır) ya da artçı; savaş kaybı cezası yok, hafif moral kaybı.",
         "Geri çekilme bedelsiz ya da seçenek çıkmıyor"),
        ("Y-C08", "Haydut reisi, kurt ve muhafızla birer savaş.",
         "Reis liderine, kurt en yaralıya saldırıyor, muhafız ölümün kıyısındakini bitirmiyor.",
         "Hepsi aynı hedefi seçiyor"),
        ("Y-C03", "Zaferden sonra ganimet ekranı.",
         "Düşman türüne göre ganimet listesi; mal/kıyafet/ekipman ilgili depolara düşüyor.",
         "Ganimet hep aynı"),
        ("Y-C04", "Sargı ve iksirle savaş içi tedavi; kampta yara sarma.",
         "Sargı +8 can ve kanamayı keser, iksir +12 can; kullanılanlar kargodan düşüyor; kamp sargısı çift bakım.",
         "Eşya düşmüyor"),
    ]),
    ("8. Defter ve paylaşım", [
        ("9.11", "L ile defter. 'Düşenler' sayfası.",
         "Kurucu ve ölüler rütbeye göre mezar işaretiyle listeli; dinî simge yok.",
         "Çizgiler okunmuyor"),
        ("DFT1", "Defter sayfasında cetvel çizgilerini oku.",
         "Sayfa metni cetvel çizgilerine oturuyor ve okunur.",
         "Satırlar çizgiye binmiş"),
        ("Y-E07", "Defterde 'sayfayı kaydet' düğmesi.",
         "Sol sayfa soyun özetine dönüyor ve PNG `user://defter_sayfalari/` altına yazılıyor; defter eski hâline dönüyor.",
         "Dosya yok ya da defter bozuk kaldı"),
    ]),
]

# Ekranda göz gerektirmeyen: testle ya da belgeyle kanıtlanmış, tek satırlık kabul.
OTOMATIK = [
    ("1.4", "Codex PDF Windows yazı tipleriyle yeniden üretildi; yasaklı sözcük taraması temiz."),
    ("1.5", "`git grep` yasaklı kelime taraması sıfır; kural `tests/test_naming_rule.gd` ile korunuyor."),
    ("4.3", "`reduce_motion` NodeUtil'de; autoload kopyaları bilerek bırakıldı."),
    ("4.4", "Olay anahtarları açık yazılı (tarama testi geçiyor)."),
    ("5.2", "Mipmap'ler `project.godot` içe aktarma ayarıyla üretiliyor (CI'de her doku için geçerli)."),
    ("5.3", "`BodyFrames` önbelleği LRU çıkarma politikalı (96 küme) ve ölçüm raporu var."),
    ("Y-A02", "Görev şablonuna zorunlu 'Sütun' satırı eklendi."),
    ("Y-E03", "59 kart incelendi; 7 karta cazip-riskli zarlı seçenek eklendi."),
    ("Y-F11", "CLAUDE.md kayıpsız inceltildi; tarihçe `docs/history/` altında."),
    ("Y-J13", "Çeviri sırası ve 50 terimlik sözlük yazıldı."),
    ("Y-G14", "IM Fell yazı tipi Türkçe harflerin hepsini taşıyor (ölçüldü)."),
    ("Y-G15", "Savaş kurdu kartın rengine çekildi; vagon zaten tek kaynak."),
    ("Y-K02", "Otomatik ekran görüntüsü karşılaştırma aracı ve iş akışı hazır (rapor amaçlı)."),
    ("N31", "Oyun hissi incelemesi tamamlandı; alt görevler N31a-f açıldı."),
    ("N31a", "Beat kaydı ve boş dakika raporu (`tests/simulate_road_beats.gd`); oyuncu ölçümü yalnız izinle."),
    ("N31b", "Işık modeli ve sis şeridi kodda."),
    ("N31c", "Ses otobüsleri, çeşitleme ve ayar kaydırıcıları: Ayarlar'dan müzik/efekt kaydırıcılarını deneyin (müzik yok, efektler ve rüzgâr var)."),
]


def yukle():
    ham = json.load(open(os.path.join(BURASI, "gorevler.json"), encoding="utf-8"))["gorevler"]
    return {g["id"]: g for g in ham}


def main():
    gorevler = yukle()
    bekleyen = {k for k, g in gorevler.items() if g["durum"] == "test bekliyor"}
    gecen = {}
    for ekran, satirlar in EKRANLAR:
        for kimlik, *_ in satirlar:
            gecen.setdefault(kimlik, ekran)
    for kimlik, _ in OTOMATIK:
        gecen.setdefault(kimlik, "otomatik")
    eksik = sorted(bekleyen - set(gecen))
    fazla = sorted(set(gecen) - bekleyen)
    if eksik or fazla:
        print("EKSİK:", eksik)
        print("FAZLA (artık test bekliyor değil):", fazla)
        if eksik:
            return 1

    md = ["# Test turu: ekran ekran kontrol listesi",
          "",
          "Bu liste `gorevler.json`'daki **test bekliyor** görevlerinden üretildi (`proje_takibi/referans/test_turu_uret.py`).",
          "Kod yazıldı ve otomatik testlerden geçti; eksik olan **sizin gözünüzün** onayı. Her madde: nereye gidilir, ne görülmeli, bozuksa ne not edilir.",
          "",
          "**Nasıl çalıştırılır:** depoyu klonlayın (Git LFS kurulu olsun), `project.godot`'u Godot 4.2.2'de açın, ilk açılışta içe aktarma bitince",
          "editörü kapatıp bir kez daha açın, Play'e basın. Geliştirici paneli: **F1** (saat/soy gibi şeyleri değiştirir). Defter: **L**, harita: **M**,",
          "emir paneli: **F2**, yardım: **F3**, Durum sekmesi: **Tab**.",
          "",
          "Bir maddeyi onayladığınızda bana 'X tamam' demeniz yeter; ben kaydı 'bitti' yaparım. Bozuksa maddenin yanına ne gördüğünüzü yazın.",
          ""]
    sayac = 0
    for ekran, satirlar in EKRANLAR:
        md += [f"## {ekran}", ""]
        for kimlik, nasil, gorulmeli, bozuk in satirlar:
            g = gorevler.get(kimlik, {})
            sayac += 1
            md += [f"- [ ] **{kimlik}** {g.get('baslik', '')}",
                   f"  - Nereye: {nasil}",
                   f"  - Görmeli: {gorulmeli}",
                   f"  - Bozuksa: {bozuk}"]
        md.append("")
    md += ["## 9. Otomatik kanıtlı (gözle bakmanız gerekmeyen)", "",
           "Bu görevlerin kabulü testle ya da belgeyle yapıldı. Onay vermeniz yeterli; itirazınız yoksa kapatırım.", ""]
    for kimlik, ne in OTOMATIK:
        g = gorevler.get(kimlik, {})
        md.append(f"- [ ] **{kimlik}** {g.get('baslik', '')}: {ne}")
        sayac += 1
    md += ["", f"Toplam madde: {sayac}.", ""]
    open(os.path.join(KOK, "TEST_TURU.md"), "w", encoding="utf-8", newline="\n").write("\n".join(md))

    # HTML: onay kutularını tarayıcı (yerel depolama) hatırlar.
    def esc(s):
        return html.escape(s)
    govde = []
    for ekran, satirlar in EKRANLAR:
        govde.append(f"<section><h2>{esc(ekran)}</h2>")
        for kimlik, nasil, gorulmeli, bozuk in satirlar:
            g = gorevler.get(kimlik, {})
            govde.append(
                f'<label class="m"><input type="checkbox" id="c-{esc(kimlik)}"><span class="k">'
                f'<b>{esc(kimlik)}</b> {esc(g.get("baslik", ""))}</span>'
                f'<span class="r"><i>Nereye</i> {esc(nasil)}</span>'
                f'<span class="r"><i>Görmeli</i> {esc(gorulmeli)}</span>'
                f'<span class="r b"><i>Bozuksa</i> {esc(bozuk)}</span></label>')
        govde.append("</section>")
    govde.append("<section><h2>9. Otomatik kanıtlı</h2>")
    for kimlik, ne in OTOMATIK:
        g = gorevler.get(kimlik, {})
        govde.append(
            f'<label class="m"><input type="checkbox" id="c-{esc(kimlik)}"><span class="k">'
            f'<b>{esc(kimlik)}</b> {esc(g.get("baslik", ""))}</span><span class="r">{esc(ne)}</span></label>')
    govde.append("</section>")
    sablon = open(os.path.join(BURASI, "test_turu_sablon.html"), encoding="utf-8").read()
    cikti = sablon.replace("{{GOVDE}}", "\n".join(govde)).replace("{{TOPLAM}}", str(sayac))
    if len(sys.argv) > 1:  # yayın için çıplak parça (sarmalayıcı yayın sırasında eklenir)
        open(sys.argv[1], "w", encoding="utf-8", newline="\n").write(cikti)
    tam = ('<!doctype html>\n<html lang="tr">\n<head>\n<meta charset="utf-8">\n'
           '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n</head>\n<body>\n'
           + cikti + "\n</body>\n</html>\n")
    open(os.path.join(KOK, "TEST_TURU.html"), "w", encoding="utf-8", newline="\n").write(tam)
    print("madde:", sayac, "| ekran bölümü:", len(EKRANLAR))
    return 0


if __name__ == "__main__":
    sys.exit(main())
