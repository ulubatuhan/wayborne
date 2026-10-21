"""Test turu maddelerinin ekran görüntüleri ve 'ben baktım' notları.

Görüntüler `proje_takibi/test_turu_gorseller/` altında (yazılım rasterleyiciyle, 1600x900, `tests/screenshot_*.gd` araçlarıyla alındı).
Bir maddenin kaydı yoksa o ekran bu ortamda gösterilemedi (saat/olay/durum gerektiriyor ya da Git LFS dokuları yok): sizin gözünüz gerekir.
Biçim: kimlik -> {"img": [(dosya, altyazı)], "ben": bakıp gördüğüm, "estetik": size kalan zevk sorusu}
"""

G = {
    "9.2": {
        "img": [("menu_baslik.jpg", "Başlık evresi"), ("menu_ana.jpg", "Menü açık")],
        "ben": "Gece kampı katmanları çiziliyor (ay, uzak şehir, vagon, kütük ateşi, sandık); sağ şerit menü ve soy satırıyla düzgün, yazılar okunuyor.",
        "estetik": "Gökyüzü ve zemin çok karanlık mı, yoksa kasvet tam yerinde mi?",
    },
    "Y-G16": {
        "img": [("menu_ana.jpg", "Ateşin başındaki üç yolcu")],
        "ben": "Üç yolcu birer sandığın üstünde oturuyor (taslaktaki kompozisyon: ikisi ateşe yan dönük, biri ateşin ardında), kalçaları sandık kapağında, ayakları yerde. "
               "Taslağa göre figürler daha pikselli/yumuşak görünüyor ve giysi ayrıntısı az.",
        "estetik": "Figürlerin keskinliği ve ışığı taslaktaki kadar iyi mi, yoksa ateş ışığını güçlendirelim mi?",
    },
    "Y-H07": {
        "img": [("ayarlar.jpg", "Ayarlar ekranı")],
        "ben": "Yazı boyutu, renk körlüğü (desenli şerit) ve 'yolda bir şey belirince duraklat' anahtarları var, hizalı, taşma yok. "
               "Müzik kaydırıcısı bilerek duruyor (şarkılar sonra eklenecek).",
        "estetik": None,
    },
    "9.4": {
        "img": [("sehir.jpg", "Şehir: sol dört mekân düğmesi, sağda brifing, altta şerit"),
                ("pazar.jpg", "Pazar (terazi)"), ("taverna.jpg", "Taverna"), ("kilise.jpg", "Kilise"),
                ("dolap.jpg", "Kıyafet Dolabı + terzi tezgâhı")],
        "ben": "Mekânlar açılıyor, her biri kendi sahnesiyle; yazılar sığıyor, düğmeler görünür. Kıyafet dolabında kilitli satın alma "
               "'altın yetmiyor' nedeniyle soluk ve gerekçeli. Not: şehirde şu an tavernada 'Han' düğmesi yok (bu yerleşim türünde yok).",
        "estetik": "Taverna kalabalığı hâlâ düz gri-bej gölgeler; kasvetli bir han için yeterince canlı mı, yoksa figürleri çeşitlendirelim mi?",
    },
    "9.12": {
        "img": [("kilise.jpg", "Kilise ve mezarlık")],
        "ben": "Mezarlık sahnesi çiziliyor, mezar taşları ve ay görünüyor, metin okunuyor. 'Nöbet' hâli bu görüntüde yok (ölüm gerektirir).",
        "estetik": "Soldaki ay diski metin sütununa yakın duruyor; kompozisyonu rahatsız ediyor mu?",
    },
    "Y-C11": {
        "img": [("pazar.jpg", "Pazar satırlarında fiyat etiketleri")],
        "ben": "Her satırın altında kısa etiketler (Yerleşim · Pahalılık · Mevsim) görünüyor. Üstüne gelince açılan açıklamayı çekemedim.",
        "estetik": None,
    },
    "Y-C19": {
        "img": [("pazar.jpg", "Kaçak tuz satırı")],
        "ben": "'Mühürsüz tuz: kaçak, yalnızca kervansarayda bulunur' satırı listede, alış fiyatı yerine tire var. "
               "Toptan indirim ve geri satış sınırı bu görüntüde görünmez; onlar testlerle kanıtlı.",
        "estetik": None,
    },
    "Y-C10": {
        "img": [("taverna.jpg", "Taverna → Söylentiler sekmesi")],
        "ben": "'Tehlike: bilinmiyor (etrafa sor)' satırları ve 'söylenti satılmaz, konuş' açıklaması görünüyor.",
        "estetik": None,
    },
    "9.6": {
        "img": [("karakter.jpg", "Karakter ekranı")],
        "ben": "Üç sütun (kimlik, nitelikler, beceriler) düzgün; sekiz stat ikonlu ve çubuklu; kanama/yanma dirençleri, can ve stres satırı var. "
               "Figür çiziliyor (asa taşıyan çıplak başlı manken).",
        "estetik": "Figürün sahne içindeki boyu ve kutudaki boşluk (üst-alt) dengeli mi?",
    },
    "9.7": {
        "img": [("kadro.jpg", "Kadro ekranı")],
        "ben": "İki kart (1. ve 2. sıra), lider halkası, can çubuğu, altta seçili kişinin ayrıntısı; yetenekler 'bu sıradan kullanılamaz' diye soluk gerekçeli.",
        "estetik": "Kart boyutu ve çadır arka planı hoşunuza gidiyor mu?",
    },
    "12.2a": {
        "img": [("kapi_vastrevar_gece.jpg", "Vastrevar kapısı, gece (meşaleli)"),
                ("kapi_kirsavel_gunduz.jpg", "Kirsavel kapısı, gündüz"),
                ("kapi_belvanor_gunduz.jpg", "Belvanor kapısı, gündüz")],
        "ben": "Her şehrin kendi kapısı var ve oyuna bağlı (şehre gerçek bir girişte `GateArrival` açılıyor): Vastrevar ve Kirsavel birbirinden farklı, "
               "geceyi meşale ve ay, gündüzü gündüz resmi veriyor. Kapının açılıp şehrin belirmesini (solma) ve tıkla-geç davranışını bu araçla çekemedim.",
        "estetik": "Gece kapıları çok karanlık mı? Meşale ışığı kapıyı yeterince gösteriyor mu?",
    },
    "12.2e": {
        "img": [("yol.jpg", "Yol, fırtınada şafak"), ("durum.jpg", "Yol, öğleden sonra, Durum sekmesi")],
        "ben": "Katmanlı manzara (uzak sırt, kuru ot, öndeki karanlık tarla), yağmur, soluk güneş; kervan, öküzler, atlı lider çiziliyor. "
               "Gündüz/akşam sürümlerini bu araçla çekemedim.",
        "estetik": "Fırtınadaki kuru gövdeler 'direk' gibi duruyor: ağaç gibi mi okunuyor, yoksa dal ekleyelim mi?",
    },
    "10.1": {
        "img": [("yol.jpg", "Atlı lider (sağda)")],
        "ben": "Lider yandan, atın üstünde, mızrak sırtında; at ve binici birbirine oturuyor, havada değil.",
        "estetik": None,
    },
    "10.4": {
        "img": [("yol.jpg", "Vagonu çeken öküzler")],
        "ben": "Öküzler vagonun önünde, boyunduruk çizgisiyle bağlı; boyları insanla orantılı (omuz hizasında boynuz).",
        "estetik": None,
    },
    "N23": {
        "img": [("durum.jpg", "Yeni HUD")],
        "ben": "Üstte saat/hız/hava şeridi, altta sekmeler (Kadro/Durum/Yük/Harita/Defter) ve düğmeler; eski parçalar yok. "
               "Durum sekmesinde dört şişe/damla gösterge ve 'Sorunlar' listesi var.",
        "estetik": "Alt şerit düğme sayısı (10) kalabalık mı?",
    },
    "Y-H05": {
        "img": [("savas_kritik.jpg", "Savaş: kritik vuruş ve Ölümün Kıyısı"), ("savas_acilis.jpg", "Savaş açılışı")],
        "ben": "Kritik vuruşta 'Critical! -7' sayısı ve sarı parlama, hedef halkası; Ölümün Kıyısındaki dosta 'DOOR' etiketi ve kırmızı ton. "
               "Sağdaki düşmanların kadrajdan taşması düzeltildi.",
        "estetik": "Vuruş geri bildirimi (parlama + sayı) yeterince 'ağır' mı?",
    },
    "Y-C07": {
        "img": [("savas_kritik.jpg", "Geri çekilme düğmeleri")],
        "ben": "Dar durumda 'Yükü bırakıp kaç', 'Bir vagonu feda edip kaç' ve 'artçıyı tut' düğmeleri çıkıyor (ilk görüntüde gri/kilitli).",
        "estetik": None,
    },
    "Y-C08": {
        "img": [("savas_acilis.jpg", "Haydut kadrosu")],
        "ben": "Sıra listesinde Haydut Reisi, Okçusu ve iki Kesici var; reisin canı diğerlerinden yüksek (68). Kurt ve muhafızı çekemedim.",
        "estetik": None,
    },
}

# Bulunan hatalar: (durum, başlık, ayrıntı). durum: "düzeldi" ya da "açık".
HATALAR = [
    ("düzeldi", "Yeni oyun ekranında Türkçe kalan iki başlık", "'Kimlik' ve 'Statlar' yazıları İngilizce arayüzde Türkçe çıkıyordu; çeviri anahtarına bağlandı."),
    ("düzeldi", "Hub: kapı yazısı lider adının üstüne biniyordu", "Etiket yukarı alındı (aşağıdaki kapı görüntüsü eski hâli; yeni çekim sizin PC'nizde doğrulanacak)."),
    ("düzeldi", "Savaş sahnesi taşması", "1920 genişlikte üçüncü düşman yarım, dördüncü görünmüyordu; mevki aralığı artık sığacak kadar daralıyor, dört düşman da kadrajda (görüntüler yeni)."),
    ("açık", "Kıyafet Dolabı: boş yuvalar ama figür giyinik", "Altı yuva 'boş' diyor, figür ise yelek, eldiven, bot giymiş; taban kıyafet mi, bir uyumsuzluk mu araştırılacak."),
    ("not", "Bu ortamda gösterilemeyenler", "Dünya haritasının zemini (Git LFS dokuları indirilmedi, harita boş koyu görünüyor), saat/hava/gece varyantları, kamp, "
     "olay kartı zincirleri, defter sayfaları: bunlar bu araçla çekilemedi, kullanıcının bakışına kaldı."),
]
