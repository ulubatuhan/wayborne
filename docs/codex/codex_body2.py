# -*- coding: utf-8 -*-
"""Codex gövdesi, ikinci yarı: şehir, yol, savaş, ekonomi, kampanya."""

from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.platypus import PageBreak
from codex_base import S, para, sp, table, callout, codebox, ColorBar, GOLD, RED, GREEN, BLUE
from codex_body import part

BLUEBG = colors.HexColor("#EAEFF5")
REDBG = colors.HexColor("#F6EAE7")
GREENBG = colors.HexColor("#EAF0E8")


def ch4():
    f = part("IV", "Şehir",
             "Kararın verildiği yer. Yol, şehirde verilen kararın bedelinin ödendiği yerdir.")

    f += [
        para("Şehir bir kart destesi değildir", "h1"),
        para(
            "Bu bilinçli bir ayrım: <b>yol</b> kart tabanlıdır (olay çıkar, seçersin, "
            "sonucuna katlanırsın), <b>şehir</b> değildir. Şehirdeki her mekân kendi ekranını "
            "açar ve kendi kararını taşır. Sebebi basit - şehirde vaktin ve bilgin var; "
            "rastgele bir kartın seni yönlendirmesi için bir sebep yok."
        ),
        sp(3),
        table(
            ["Mekân", "Ne satar / ne yapar", "Asıl kararı"],
            [
                ["<b>Pazar Meydanı</b>",
                 "Mal alım-satımı, şehir başına stok sınırı, toptan pazarlık",
                 "Neyi nereye taşıyacaksın?"],
                ["<b>Tüccar Loncası</b>",
                 "Kontrat panosu · <b>Borçlar sekmesi</b> (kredi, ödeme, yapılandırma)",
                 "Hangi yükü, ne kadar süreye, hangi itibarla?"],
                ["<b>Taverna</b>",
                 "Rota dedikodusu (tehlike yüzdesi) · ziyafet · huy arındırma (pahalı) · tayfa",
                 "Bilgiye mi, dinlenmeye mi para vereceksin?"],
                ["<b>Kervan Avlusu</b>",
                 "Vagon al / sat / onar · <b>Demirci</b>: Silah ve Zırh tier'ları",
                 "Kervanı büyütmek mi, savaşçıyı güçlendirmek mi?"],
                ["<b>Kilise</b>", "Huy arındırma (ucuz)", "Taze bir huyu silmeye değer mi?"],
            ],
            widths=[30 * mm, 70 * mm, 54 * mm],
        ),
        sp(4),
        callout(
            "Şehir özeti: üç soruyu tek ekranda cevaplamak",
            "Şehir bir süre yalnızca beş kapı ve bir çıkıştı. Nereye gidebileceğini öğrenmek "
            "için bile taverna → dünya haritası → planlayıcı gezmek, kervanın neye ihtiyacı "
            "olduğunu öğrenmek içinse beş kapıyı tek tek açmak gerekiyordu.<br/><br/>"
            "Haritanın yanındaki özet paneli üç soruyu birden cevaplıyor: <b>(1)</b> hikâyenin "
            "neresindesin - açık kampanya bölümü, anlatısı ve hedeflerinin canlı sayacı; "
            "<b>(2)</b> kervanın neye ihtiyacı var - erzak kaç güne yetiyor, hasarlı vagon, "
            "kontratsızlık, yüksek stres, boş parti yeri, borç; <b>(3)</b> nereye gidilir - "
            "her komşu şehir için gün, tehlike, yolun o günkü hali ve o hedefe yazılı "
            "kontratların toplam ödemesi.<br/><br/>"
            "İki kural: her uyarı <b>onu çözen ekranı açar</b> (yalnızca endişelendiren bir "
            "uyarı hiç uyarmamaktan kötüdür), ve <b>ihtiyaç yoksa satır da yoktur</b> - "
            "yeşil tiklerden oluşan kalıcı bir kontrol listesi gürültüdür.",
        ),

        PageBreak(),
        para("Pazar: fiyatın iki katmanı", "h1"),
        para(
            "Fiyat sabit bir tablo değil. <b>Taban katman</b> pozisyoneldir - bir şehir "
            "ürettiğini ucuza verir, aradığını pahalıya alır. <b>Dinamik katman</b> bunun "
            "üstüne biner ve çarpar."
        ),
        codebox([
            "ALIŞ  = taban_fiyat × (0.6 eğer şehir üretiyorsa, yoksa 1.0) × dinamik",
            "SATIŞ = taban_fiyat × (1.7 eğer şehir arıyorsa, yoksa 0.5) × dinamik",
            "",
            "dinamik = enflasyon × mevsim × arz_talep_baskısı × şok",
            "          (hepsi birlikte 0.35 ile 3.0 arasına kenetlenir)",
        ]),
        sp(3),
        table(
            ["Katman", "Nasıl çalışır", "Sınır"],
            [
                ["<b>Enflasyon</b>", "Günde +%0.15, kümülatif", "×1.8'de durur"],
                ["<b>Mevsim</b>", "30 günlük dört mevsim; kış pahalı, sonbahar ucuz", "—"],
                ["<b>Arz-talep baskısı</b>",
                 "<b>Senin kendi ticaretin.</b> Almak o malın o şehirdeki fiyatını yükseltir "
                 "(birim başına +%1), satmak düşürür (−%0.8). Baskı günde %6 sönerek tabana döner.",
                 "±%45"],
                ["<b>Şok</b>", "Olaylardan gelen süreli fiyat kayması (grev, kıtlık, bereket)",
                 "×2.5"],
            ],
            widths=[34 * mm, 92 * mm, 28 * mm],
        ),
        sp(3),
        callout(
            "Arz-talep neden var?",
            "Tek bir rotayı sonsuza kadar sağıp geçinmeyi engellemek için. Aynı malı aynı "
            "şehirden defalarca alırsan fiyatı sen yükseltirsin; aynı şehre defalarca satarsan "
            "fiyatı sen düşürürsün. <b>Her yeni ticaret yolu "
            "<tt>consume_stock</tt>/<tt>record_sale</tt>'den geçmek zorundadır</b>, yoksa "
            "bu katmanın etrafından sessizce dolaşır.",
        ),
        sp(4),
        callout(
            "Örnek · Buğdayın yolculuğu",
            "Buğday taban fiyatı 5 GG. Karakonak buğday <b>üretir</b>, Demirkapı buğday "
            "<b>arar</b>.<br/><br/>"
            "<tt>Karakonak'ta alış  = 5 × 0.6 = <b>3 GG</b></tt><br/>"
            "<tt>Demirkapı'da satış = 5 × 1.7 = <b>9 GG</b></tt><br/>"
            "<tt>Birim kâr = 6 GG · 30 birim = <b>180 GG</b></tt><br/><br/>"
            "Ama 30 birim almak Karakonak'ta buğday fiyatını %30 yükseltir (birim başına %1), "
            "30 birim satmak Demirkapı'da %24 düşürür. Aynı turu hemen tekrarlarsan kâr "
            "belirgin biçimde erir; birkaç gün beklersen (günde %6 sönüm) fiyatlar tabana döner. "
            "<b>Kârın asıl kaynağı ticarettir, kontrat değil</b> - bu ölçüldü: yalnızca "
            "kontrat geliriyle koşan bir kervan sekizinci seferde batıyor.",
        ),

        PageBreak(),
        para("Pazarlık: oyunun para basma noktası", "h1"),
        para(
            "Aynı tuzağa <b>iki kez</b> düşüldüğü için buranın değişmezleri sayılardan daha "
            "önemli. İki bozuk tasarımın kaydı:"
        ),
        sp(2),
        table(
            ["Tasarım", "Ne yapıyordu", "Neden bozuktu"],
            [
                ["<b>Birinci</b>",
                 "Kabul eşiği, sabır azaldıkça mutlak asgariye doğru kayıyordu",
                 "Sabrı en hızlı yakan şey aşağılayıcı bir tekliftir - yani tüccarı "
                 "<b>çıldırtmak ödüllendiriliyordu</b>"],
                ["<b>İkinci</b>",
                 "Eşik tabanın altına inmiyor, taban her redde sertleşiyordu",
                 "Sömürü kapandı ama hem eşik hem taban <b>yalnızca tur sayısının</b> "
                 "fonksiyonuydu - yani <i>nasıl</i> pazarlık ettiğin değil, <i>kaç kez</i> "
                 "reddedildiğin önemliydi"],
            ],
            widths=[22 * mm, 60 * mm, 72 * mm],
        ),
        sp(4),
        para("Mevcut tasarım: önemli olan yol", "h2"),
        table(
            ["Kural", "Açıklama"],
            [
                ["<b>Teklif sayılabilir bir kaynaktır</b>",
                 "Üç tur, ekranda gösterilir. Deneme yanılmayla tersine çevrilecek gizli bir "
                 "eğri yok."],
                ["<b>Tüccar ancak ciddiye aldığı bir tekliften sonra taviz verir</b>",
                 "Lowball bir turu yakar ama tüccarı <i>kıpırdatmaz</i>. Eşik "
                 "<b>taviz sayısına</b> göre hesaplanır, tur sayısına göre değil - "
                 "“aynı dip teklifi üç kez tekrarla” tam olarak bu yüzden işlemez."],
                ["<b>Her red tabanı sertleştirir</b>",
                 "Tur başına +%2.2. Teklifleriniz makul olsa bile işi uzatmak size yer kaybettirir."],
                ["<b>Teklif bitince ültimatom gelir</b>",
                 "Liste fiyatını öde ya da git. “Son teklif” perki ültimatomu tüccarın o anki "
                 "tabanına yumuşatır - değerli, ama üç turu iyi kullanmaktan hâlâ kötü."],
                ["<b>Masadan kalkmak biraz itibar yer</b>",
                 "Yalnızca 1 puan. Bilerek küçük: bedelsiz olsa “kızdır, sonra yeniden aç” "
                 "bedava bir tekrar döngüsü olurdu; ama bozulan bir pazarlık felaket değil, "
                 "bir bedeldir."],
                ["<b>Beceri partiden okunur</b>",
                 "Zeka ve Karizma'nın <i>en iyisi</i> tabanı genişletir. İki ekran da bir süre "
                 "sıfır geçiyordu - bu, mini-oyunu tamamen karakter-kör yapmıştı."],
            ],
            widths=[54 * mm, 100 * mm],
        ),
        sp(4),
        callout(
            "Ölçülen gradyan · 135 GG liste fiyatı (taban 100, açgözlülük 0.5, itibar 0.3)",
            "<tt>Temkinli oyun  → ilk turda ~116 GG</tt><br/>"
            "<tt>Nişan alan oyun → 116 → 99 → <b>83 GG</b></tt><br/>"
            "<tt>Açgözlü oyun   → ültimatom: <b>135 GG</b> ya da git</tt><br/><br/>"
            "Usta bir konuşmacı (Zeka ve Karizma maksimum, güvenilir itibar) 100 listelik bir "
            "malı <b>68 GG</b>'ye alır. Yani mini-oyun hem beceriye hem karaktere duyarlı.",
        ),

        PageBreak(),
        para("Kontratlar ve borç", "h1"),
        para(
            "Lonca panosundaki teklifler statik veri değil, <b>oturum durumu</b>dur: kabul "
            "edilince panodan kalkar, süresi geçerse ya da yolda teslim edilemezse itibar "
            "cezası kesilir (kontrat başına 5 puan). Büyük kontratlar itibar ister."
        ),
        sp(3),
        para("Borç: kervan batabilir ama silinmez", "h2"),
        table(
            ["Kavram", "Kural"],
            [
                ["<b>İki harcama yolu</b>",
                 "<tt>spend()</tt> isteğe bağlı alışveriştir ve para yetmezse <b>başarısız olur</b> - "
                 "oyuncu kendini asla batıramaz. <tt>force_spend()</tt> ödemek <i>zorunda</i> "
                 "olduğun paradır (haraç, ceza, gümrük, faiz) ve keseyi eksiye iter."],
                ["<b>Açık hesap = eksi bakiye</b>",
                 "İkisi <b>aynı paradır</b> ve her bakiye değişiminde senkronlanır. Ayrı "
                 "tutulsalardı para kazandıkça kese düzelir ama defter eski borcu göstermeye "
                 "devam ederdi - oyuncu aynı borç için iki kez faturalandırılırdı."],
                ["<b>Vade ve faiz</b>",
                 "Vade 30 gün. Vadesi geçtikten sonra <b>her 10 günde +%15 faiz</b> ve 3 itibar."],
                ["<b>Yapılandırma</b>",
                 "Vadeyi 20 gün uzatır, bedeli anaparaya biner (%12) ve <b>her seferinde büyür</b> "
                 "(+%6) - sonsuza kadar ertelemek ucuz yol olmamalı."],
            ],
            widths=[34 * mm, 120 * mm],
        ),
        sp(4),
        para("Lonca kredisi: bilerek alınan borç", "h2"),
        para(
            "<tt>force_spend</tt> dünyanın dayattığı borçtur; kredi onun tersidir - yola "
            "çıkmadan mal almak için bilerek alınan para. Üç kural para basma düğmesi "
            "olmasını engelliyor:"
        ),
        codebox([
            "hat        = min(200 + 25 × itibar, 1200)",
            "kullanılabilir = hat − TOPLAM BORÇ        ← açık hesap dahil",
            "anapara    = alınan + ceil(alınan × %10)  ← tahsis ücreti",
            "vade       = 30 gün · itibar < 0 ise kredi tamamen kapalı",
        ]),
        sp(3),
        callout(
            "Ortadaki kural en keskin kaçamağı kapatıyor",
            "Açık hesabın vadesi <b>ilk eksiye düşüşte</b> kurulur. Eğer kredi hattını yalnızca "
            "<i>krediler</i> tüketseydi, borç alıp açık hesabı kapatmak vadeyi bedavaya "
            "sıfırlayan bir yapılandırma olurdu - oysa yapılandırmanın ücreti var ve her "
            "seferinde büyüyor. Hattı <b>bütün</b> borçlar tükettiği için bu numara işlemez.<br/><br/>"
            "Bir de oyuncunun gördüğü sayı meselesi: ücret bir ara kayan noktalı orandı ve "
            "<tt>200 × 0.1 = 20.000000000000004</tt> olduğu için “%10” yazan bir tabelanın "
            "altında 200'lük kredi deftere <b>221</b> yazıyordu. Yuvarlama artığı, oyuncuya "
            "ilan edilen bir sayıda hile yapmaktan ayırt edilemez.",
            accent=RED, bg=REDBG,
        ),
    ]
    return f


# =====================================================================
def ch5():
    f = part("V", "Yol",
             "Coğrafya sabittir; üstündeki ağ değildir. Yol, şehirde verilen kararın "
             "sınandığı yer.")

    f += [
        para("Harita: beş şehir, yedi kenar", "h1"),
        para(
            "Her şehir bir mal <b>üretir</b> (ucuza verir) ve başka birini <b>arar</b> "
            "(pahalıya alır). Bu, iki kapalı ticaret döngüsü oluşturur ve her şehrin en az "
            "iki komşusu vardır."
        ),
        sp(2),
        table(
            ["Şehir", "Üretir (ucuz)", "Arar (pahalı)", "Komşuları"],
            [
                ["<b>Karakonak</b>", "Buğday", "İşlenmiş Kürk", "Kurtboğazı, İpekevi, Demirkapı, Yeşilova"],
                ["<b>Kurtboğazı</b>", "İşlenmiş Kürk", "Demirci Malı Silah", "Karakonak, Demirkapı"],
                ["<b>İpekevi</b>", "Top Kumaş", "Otacı İksiri", "Karakonak, Yeşilova"],
                ["<b>Demirkapı</b>", "Demirci Malı Silah", "Buğday", "Karakonak, Kurtboğazı, Yeşilova"],
                ["<b>Yeşilova</b>", "Otacı İksiri", "Top Kumaş", "Karakonak, İpekevi, Demirkapı"],
            ],
            widths=[26 * mm, 32 * mm, 34 * mm, 62 * mm],
        ),
        sp(4),
        table(
            ["Rota", "Gün", "Taban tehlike"],
            [
                ["Karakonak ↔ Kurtboğazı", "3", "%20"],
                ["Karakonak ↔ İpekevi", "4", "%35"],
                ["Karakonak ↔ Demirkapı", "6", "%50"],
                ["Karakonak ↔ Yeşilova", "8", "%65"],
                ["Kurtboğazı ↔ Demirkapı", "4", "%30"],
                ["İpekevi ↔ Yeşilova", "5", "%40"],
                ["Demirkapı ↔ Yeşilova", "3", "%25"],
            ],
            widths=[70 * mm, 24 * mm, 32 * mm], align_center=[1, 2],
        ),
        sp(3),
        para(
            "Ayrıca tehlike <b>zamanla büyür</b>: <tt>total_days_elapsed</tt> arttıkça rotanın "
            "ham tehlikesi günde %0.4 ölçeklenir (tavan ×1.6). Erken oyunun kolaylığı geç "
            "oyunda sürmemeli.",
            "small",
        ),
        sp(5),

        para("Yolun o günkü hali: dinamik rota katmanı", "h1"),
        para(
            "Bu katman, <b>MarketPricing/MarketConditions</b> ayrımının birebir aynısıdır: "
            "sabit bir taban tablo (yedi kenar, yazılmış coğrafya) ve üstüne binen canlı bir "
            "katman. Katmanı bilmeyen bir çağıran eski, statik davranışı görür."
        ),
        sp(2),
        table(
            ["Durum", "Süre çarpanı", "Tehlike eklentisi", "Ortaya çıkma"],
            [
                ["<b>Açık</b>", "×1.0", "—", "çoğunluk"],
                ["<b>Yavaş</b> (çamur/sel)", "<b>×1.6</b>", "+0.05", "%15"],
                ["<b>Tehlikeli</b> (eşkıya)", "×1.0", "<b>+0.22</b>", "%13"],
                ["<b>Kapalı</b> (çığ)", "—", "—", "%5"],
            ],
            widths=[42 * mm, 30 * mm, 34 * mm, 34 * mm],
            align_center=[1, 2, 3],
        ),
        sp(3),
        table(
            ["Kural", "Neden"],
            [
                ["<b>Durumlar saklanmaz, hesaplanır</b>",
                 "Her rota <tt>rota_anahtarı + dönem</tt> tohumundan 6 günlük pencerede bir kez "
                 "yuvarlanır. Yani kaydı yeniden yüklemek kapalı bir geçidi açık "
                 "<b>yeniden yuvarlayamaz</b>. Yalnızca olay kaynaklı geçersiz kılmalar "
                 "(ROUTE_CHANGE) kayda yazılır."],
                ["<b>Pencere rotaya göre kaydırılır</b>",
                 "Yoksa dünyadaki bütün yollar aynı sabah değişirdi."],
                ["<b>Durum yönsüzdür</b>", "Çığ tek yöne düşmez; anahtar çifti sıralanır."],
                ["<b>Hiçbir şehir kapatılamaz</b>",
                 "Bir kapanma bir şehri çıkışsız bırakacaksa <b>Yavaş'a indirilir</b> - yol "
                 "zorla geçilebilir hale gelir, yok olmaz. Bu indirim <tt>get_state()</tt>'te "
                 "yapılır (ham zar <tt>get_raw_state()</tt>'te durur), çünkü süre, tehlike, "
                 "ekrandaki etiket ve yol bulucu <i>hepsi</i> aynı yerden okur - kervanın "
                 "üzerinde yürüdüğü yol asla “Geçit kapalı” diye görünmemeli."],
                ["<b>Kapalı yol çıkmaz sokak değil, dolambaçtır</b>",
                 "Açık ağ üzerinde genişlik-öncelikli arama yapılır; harita şehri griye "
                 "boyamak yerine <b>alternatifi gösterir</b>."],
                ["<b>Tehlike farkı boşluğa uygulanır</b>",
                 "<tt>yeni = taban + delta × (1 − taban)</tt>. Böylece eşkıya sakin bir yolu "
                 "gerçekten riskli yapar ama zaten ölümcül bir yolu %90'lık yazı-tura'ya çevirmez."],
            ],
            widths=[46 * mm, 108 * mm],
        ),

        PageBreak(),
        para("Zaman: akan saat, sayılan gün", "h1"),
        para(
            "Yol bir zamanlar tuşa basınca bir gün ilerliyordu. Şimdi sürekli akan bir saat "
            "üzerinde çalışıyor - ama <b>gün mekaniği değişmedi</b>."
        ),
        sp(2),
        table(
            ["Kural", "Açıklama"],
            [
                ["<b>Saat günü sayar, yerine geçmez</b>",
                 "Erzak, kontrat vadesi ve olay zarı hâlâ günde bir kez işler. "
                 "<tt>take_elapsed_days()</tt> “son sorduğumdan beri kaç tam gün doldu” "
                 "sorusunu cevaplar ve bir <i>sayı</i> döner, bool değil: 3× hızda ya da uzun "
                 "bir olaydan sonra tek karede birden fazla gün dolabilir."],
                ["<b>Gün şafakta döner, gece yarısında değil</b>",
                 "Sınır gece yarısı olunca bütün günlük olaylar 00:00'da ateşleniyordu - "
                 "oyuncu hiçbirini gün ışığında görmüyordu. Olaylar artık ~07:30 civarında iner."],
                ["<b>Olaylar zaman yer</b>",
                 "Kart çözmek, dövüşmek, pazarlık etmek ve yolda tayfa almak saat harcar "
                 "(1.0 - 2.5 saat). Kervan dururken arka plan ilerler."],
                ["<b>Karar anında zaman durur</b>",
                 "Olay kartı ya da yan panel (savaş/pazarlık/tayfa) açıkken saat akmaz."],
                ["<b>Kamp bir durum, bir an değil</b>",
                 "Kamp ateşi yanar ve saat akmaya devam eder; fayda süre dolunca uygulanır. "
                 "Yalnızca akşam/gece teklif edilir."],
                ["<b>Hız</b>", "1× / 1.5× / 3× · bir gün gerçek zamanda 45 saniye (1× hızda)"],
            ],
            widths=[46 * mm, 108 * mm],
        ),
        sp(4),
        para("Plan bir niyettir, taahhüt değil", "h1"),
        para(
            "Şehirde kurulan plan yolda değiştirilebilir. Ama kervan haritada ışınlanabileceği "
            "bir yerde değildir:"
        ),
        sp(2),
        table(
            ["Kural", "Açıklama"],
            [
                ["<b>Sapma bedeli</b>",
                 "Yeni mesafe = <b>zaten yürünen günler</b> + çıkış şehrinden yeni hedefe olan "
                 "rota. Geri dönmek ödenir."],
                ["<b>Nereye sapılabilir</b>",
                 "Yalnızca <b>çıkış şehrinden</b> ulaşılabilen ve o gün yolu açık olan şehirlere."],
                ["<b>Yeni bacak yeni seferdir</b>",
                 "Toplam ve kalan gün <i>ikisi de</i> sıfırlanır; yoksa ilerleme çubuğu dolu "
                 "kalır ve varış kontrolü anında ateşlenirdi."],
                ["<b>Terk edilen hedefin kontratları</b>",
                 "Teslim edilemez; hesap varışta kapanır. Özel bir şey gerekmez - bu, "
                 "başarısız teslimatın zaten kullandığı yoldur."],
                ["<b>Karar vermek bedava, kararın kendisi değil</b>",
                 "Panel açıkken zaman durur (baskı yok) ama kervanı döndürmek saatler yer."],
            ],
            widths=[42 * mm, 112 * mm],
        ),
        sp(4),
        callout(
            "Yoldan çıkışın tek yolu yolun kendi eylemleridir",
            "Canlı bir seferde yol ekranının çıkışı <b>ana menüye</b> gider, gezinme yığınına "
            "değil. Bir ara oyuncuyu şehir haritasına bırakıyordu - ama sefer hâlâ “aktif” "
            "görünüyordu ve planlayıcıdan başka hiçbir şey yol ekranına gitmediği için "
            "<b>yola bir daha girilemiyordu</b>. Yolu terk etmenin üç meşru yolu var: varmak, "
            "geri dönmek, sapmak.",
            accent=BLUE, bg=BLUEBG,
        ),
    ]
    return f


# =====================================================================
def ch6():
    f = part("VI", "Savaş",
             "Dört mevkilik iki saf, inisiyatif sırası, mevki-kilitli yetenekler. "
             "Kaybetmek ölüm değil, yıpranmadır.")

    f += [
        para("Saha", "h1"),
        codebox([
            "DÜŞMAN          4     3     2     1   │   1     2     3     4          PARTİ",
            "                ←  arka        ön  ←  │  →  ön        arka  →",
            "",
            "Her yetenek İKİ mevki listesi taşır:",
            "   usable_positions  : kullanan nerede durmalı",
            "   target_positions  : nereye ulaşabilir",
        ]),
        sp(3),
        para(
            "Örnek: <b>Sapan</b> yalnızca 3. veya 4. mevkiden kullanılır ama düşmanın 2, 3, 4. "
            "mevkilerine ulaşır - arkadan atış. <b>Kalkan Darbesi</b> 1-2'den kullanılır ve "
            "1-2'ye ulaşır - göğüs göğüse. Kullanılamayan bir yetenek <b>gizlenmez</b>, "
            "sebebiyle soluk gösterilir; olay seçenekleriyle aynı kural."
        ),
        sp(4),
        para("Çözüm sırası", "h2"),
        codebox([
            "1. İnisiyatif sırası kurulur (10 + etkin Çeviklik, rastgelelik payıyla)",
            "2. Sıra gelen birim KIRILMIŞSA:",
            "      red_ihtimali = max(%5, %20 − 1.5 × etkin Karizma) → sıra atlanabilir",
            "3. Yetenek seçilir (mevki uygun değilse kilitli gösterilir)",
            "4. İsabet: hedefin kaçınması isabetten düşülür, %5-%95 arasına kenetlenir",
            "5. Kritik → hasar ×1.5",
            "6. Hasar = yeteneğin tabanı ± sapma + hasar bonusu",
            "      × yetkinlik ölçeği (+%50'ye kadar) × kültür çarpanı",
            "7. Biri düşerse saflar sıkışır (rank repacking)",
            "8. Tur numarası ilerler → bütün süreli değiştiriciler bir azalır",
        ]),
        sp(4),
        callout(
            "Süreli değiştiriciler: bir yeteneğin kendi vuruşunun ötesine uzanmasının tek yolu",
            "Bir yetenek <tt>modifier_stat</tt> (isabet / kaçınma / hasar), "
            "<tt>modifier_amount</tt> ve <tt>modifier_rounds</tt> taşıyabilir. Savaş çözümü "
            "<b>her zaman</b> <tt>get_effective_*</tt> değerlerini okur - bir yetenek onları "
            "değiştirmiş olabileceği için ham alanlar asla doğrudan okunmaz.<br/><br/>"
            "Hasarı, iyileştirmesi olmayan ve hedefi düşman olmayan bir yetenek "
            "(kendine/dosta) <b>isabet zarı atmadan</b> değiştiricisini uygular - "
            "“Siper Al” gibi.",
        ),

        PageBreak(),
        para("Düşman kadroları", "h1"),
        para(
            "Üç tür, tek giriş noktasından dağıtılır. Tür, <tt>TRIGGER_COMBAT</tt> etkisinin "
            "metin değerinden akar (boş = haydut, böylece eski olay tanımları değişmeden çalışır)."
        ),
        sp(2),
        table(
            ["Düşman", "Can", "İsabet", "Kaçınma", "Krit", "Hasar", "İnisiyatif", "Mevki"],
            [
                ["Haydut Kesicisi", "27", "78", "6", "5", "4", "8", "1"],
                ["Haydut Okçusu", "22", "82", "9", "7", "3", "11", "3"],
                ["<i>Dağ Haydutu</i> (Kurtboğazı)", "32", "76", "5", "5", "7", "7", "1"],
                ["<i>Silahlı Eşkıya</i> (Demirkapı)", "24", "88", "8", "10", "4", "11", "3"],
                ["Kurt", "19", "80", "13", "6", "3", "14", "1"],
                ["Ayı", "<b>62</b>", "72", "3", "3", "9", "5", "1"],
                ["Yaban Domuzu", "33", "76", "6", "4", "6", "10", "1"],
                ["Şehir Muhafızı", "31", "82", "7", "4", "5", "9", "1"],
            ],
            widths=[46 * mm, 16 * mm, 18 * mm, 20 * mm, 14 * mm, 18 * mm, 22 * mm, 14 * mm],
            align_center=[1, 2, 3, 4, 5, 6, 7],
        ),
        sp(3),
        para(
            "Bölge reskin'leri aynı kadro şeklini korur, yalnızca yöre teçhizatını değiştirir: "
            "Kurtboğazı'nın haydutları daha ağır (32 can, +7 hasar), Demirkapı'nınkiler daha "
            "keskin (88 isabet, %10 krit).",
            "small",
        ),
        sp(4),
        para("İki ölçekleme knobu", "h2"),
        codebox([
            "güç_ölçeği = (1 + 0.02 × (ortalama_seviye − 1)) × (1 + 0.10 × (parti − 1))",
            "             └─ seviyeye göre ────┘   └─ parti büyüklüğüne göre ─┘",
        ]),
        callout(
            "Neden iki knob? Çünkü biri eğrinin iki ucunu birden şekillendiremez",
            "<b>Seviye knobu</b> “seviye atlamak ilerleme gibi hissettiriyor mu” sorusunu, "
            "<b>parti knobu</b> “dolu bir kervan dokunulmaz mı” sorusunu cevaplıyor. Yalnızca "
            "düşman gücünü ayarlamak dolu partiyi dengeledi ve yalnız yolcuyu %0'a düşürdü - "
            "%100 kadar bozuk, çünkü geriye karar diye bir şey kalmıyor.<br/><br/>"
            "<b>Seviye ölçeklemesi oyuncunun kendi büyümesinin altında kalmalı.</b> "
            "%8/seviyede düşmanlar 2.12 katına çıkıyordu ve ölçülen eğri <i>tersine döndü</i> "
            "(seviye 1: %98, seviye 15: %52) - oyuncunun canı yalnızca Dayanıklılık afiniteli "
            "sınıflarda büyüyor, karışık bir partide ortalama +%25. %2/seviyede eğri yeniden "
            "yükseliyor.",
            accent=GREEN, bg=GREENBG,
        ),
        sp(4),
        para("Ölçülen kazanma oranı (seviye 1)", "h2"),
        table(
            ["Parti", "%20 tehlike", "%40", "%65", "%90"],
            [["1", "%42", "%45", "%5", "%5"],
             ["2", "%100", "%72", "%23", "%23"],
             ["3", "%100", "%93", "%57", "%57"],
             ["4", "%100", "%100", "%88", "%88"]],
            widths=[24 * mm, 32 * mm, 28 * mm, 28 * mm, 28 * mm],
            align_center=[0, 1, 2, 3, 4],
        ),
        sp(2),
        para(
            "Yalnız bir yolcunun haydut kaynayan bir yolda neredeyse hiç şansı yok - bu bir "
            "gözden kaçma değil, kasıtlı mesaj: oyun seni iki kişiyle başlatır, parti 1 "
            "yalnızca birini kovarsan oluşur, ve savaşı kaybetmek ölüm değil yıpranmadır.",
            "small",
        ),
        sp(3),
        callout(
            "Kadro parti boyutuna kırpılırken sıralama önemlidir",
            "Kadro mevki sırasına göre kırpıldığında yalnız yolcu <b>her zaman</b> iki kesici "
            "çekiyor, reisi hiç görmüyordu - yani sakin bir yol ile haydut kaynayan bir yol "
            "onun için <i>birebir aynıydı</i>. Kimlik listesi artık öncelik sırasına göre "
            "yazılıyor (yüksek tehlikede reis başa alınır) ve sondan kırpılıyor. Ham tehdide "
            "göre kırpmak da denendi ve karşılaşmayı düzleştirdi - her seferinde okçuyu "
            "düşürüp üç yakın dövüşçü bırakıyor, mevki tasarımını siliyordu.",
        ),
    ]
    return f


# =====================================================================
def ch7():
    f = part("VII", "Kampanya",
             "Sonu olan bir hikâye, bitmeyen bir ticaret. Beş perde, sırayla, varışta.")

    f += [
        para("İki mimari karar", "h1"),
        table(
            ["Karar", "Gerekçe"],
            [
                ["<b>Hedefler yeni bir dil icat etmez</b>",
                 "Bölüm hedefleri, olay tetikleyicileriyle <b>aynı</b> yapıyı kullanır "
                 "(<tt>EventCondition</tt>). İkinci bir “görev koşulu” kelime dağarcığı "
                 "yazmak, aynı işi yapan iki dil demek olurdu ve ikisi ilk günden ayrışmaya "
                 "başlardı."],
                ["<b>Ama okudukları bağlam ayrıdır</b>",
                 "Kampanya bağlamı kervanın <b>ömrünü</b> anlatır (kaç sefer, kaç teslimat, "
                 "kaç şehir, kaç vagon); olay bağlamı o anki <i>yolu</i> anlatır (tehlike, "
                 "kalan gün, moral). Bölüm hedefi yol bağlamını okusaydı, <tt>finish_journey()</tt> "
                 "kervanı sıfırladığı için her varışta tamamlanıp tamamlanmamaya geri dönerdi."],
            ],
            widths=[46 * mm, 108 * mm],
        ),
        sp(4),
        para("Beş perde", "h1"),
        table(
            ["#", "Perde", "Hedefler", "Ödül"],
            [
                ["I", "<b>İlk Yol</b>", "1 sefer tamamla · 1 kontrat teslim et", "50 GG, +1 itibar"],
                ["II", "<b>Bir Kadro</b>", "3 kişi · 2 vagon", "120 GG, +2 itibar"],
                ["III", "<b>Ağ</b>", "4 ayrı şehir gör · itibar 5", "200 GG, +2 itibar"],
                ["IV", "<b>Temiz Defter</b>", "Borç sıfır · 8 kontrat teslim", "250 GG, +3 itibar"],
                ["V", "<b>Kendi Hanın</b>", "2500 GG · 4 vagon · itibar 15", "+5 itibar · <b>FİNAL</b>"],
            ],
            widths=[10 * mm, 34 * mm, 68 * mm, 42 * mm],
        ),
        sp(4),
        table(
            ["Kural", "Açıklama"],
            [
                ["<b>Kapanan bölüm bir daha açılmaz</b>",
                 "Bölümler indeksle ilerler ve yeniden değerlendirilmez - “2500 altın birik­tir” "
                 "hedefi, para sonradan harcanınca geri alınmaz. Bir alışverişin geri alabildiği "
                 "ilerleme, ilerleme değildir."],
                ["<b>Final bir eşiktir, durak değil</b>",
                 "Son perde epilog gösterir; kese, yollar ve pazar aynen devam eder. "
                 "Bu, kazanılan altın hedefi ekranındaki “Devam Et”le aynı şekil."],
                ["<b>Bölümler varışta kapanır, birden fazlası aynı anda kapanabilir</b>",
                 "Kontrol <tt>finish_journey()</tt>'in <b>sonunda</b> çalışır - ödeme yatmış, "
                 "teslimat sayılmış, yeni şehir kaydedilmiş olmalı. Uzun bir sefer iki perdeyi "
                 "birden karşılarsa ikisi de kapanır."],
                ["<b>Her bölüm bitişte bir bayrak kurar</b>",
                 "Bir olay <tt>HAS_FLAG</tt> ile kendini o bayrağa kilitleyebilir - kampanya, "
                 "paralel bir sistem icat etmek yerine zaten var olan olay havuzuna bağlanır."],
                ["<b>İlerleme kayda yazılır</b>",
                 "Yeniden yüklemekle tekrar oynanabilen bir şey ilerleme değildir."],
            ],
            widths=[50 * mm, 104 * mm],
        ),

        PageBreak(),
        para("Ölçüm: hikâye ne kadar sürüyor?", "h1"),
        para(
            "8 kervan × 40 sefer, kampanyayı izleyen bir oyuncu politikasıyla (teslimat "
            "yaparken yalın kal, defter temizlenince genişle):"
        ),
        sp(2),
        table(
            ["Perde", "Kapanan", "En erken", "Ortanca", "En geç"],
            [
                ["İlk Yol", "8/8", "1", "<b>1</b>", "1"],
                ["Bir Kadro", "7/8", "5", "<b>11</b>", "20"],
                ["Ağ", "6/8", "8", "<b>16</b>", "36"],
                ["Temiz Defter", "6/8", "8", "<b>17</b>", "38"],
                ["Kendi Hanın", "5/8", "22", "<b>30</b>", "40"],
            ],
            widths=[42 * mm, 26 * mm, 28 * mm, 28 * mm, 26 * mm],
            align_center=[1, 2, 3, 4],
        ),
        sp(3),
        para(
            "Yani tam bir hikâye kabaca <b>otuz sefer / 180 oyun günü</b> sürüyor ve kervanların "
            "dörtte biri bitiremiyor - kervanın mahvolabildiği bir oyunda kabul edilebilir, "
            "ama canı yakarsa geri dönülecek bir sayı."
        ),
        sp(4),
        para("Ölçümün üç bulgusu (sayılardan değerli)", "h2"),
        callout(
            "1 · İtibar oyunun en kıt kaynağı",
            "20. seferde ortalama itibar <b>1</b>, 30. seferde <b>11</b>. Üçüncü ve beşinci "
            "perdenin gerçek kapısı bu. İtibara kapı koyan her yeni içerik, oyunun en yavaş "
            "hareket eden statına kapı koyuyor demektir.",
        ),
        sp(3),
        callout(
            "2 · Vagon almak kontratı kovuyor",
            "Kervanın vagon tavanı <b>toplam</b> tavandır - oyuncunun kendi vagonları tüccar "
            "slotlarını yer. Beş vagonlu bir kervanda escort'a tek slot kalıyor ve teslimat "
            "sayısı <b>11'de donuyor</b>; yalın kalan bir kervan <b>41</b> teslimata ulaşıyor. "
            "Bu bir hata değil gerçek bir ödünleşim (kendi malını mı taşırsın, başkasınınkini "
            "mi) - ama iki orta perdenin ters yönlere çektiği ve oyuncunun onları sıralaması "
            "gerektiği anlamına geliyor.",
        ),
        sp(3),
        callout(
            "3 · Aynı anda kapanan iki perde tek perdedir",
            "Üçüncü ve dördüncü perde ikisi de 19. seferde kapanıyordu. Üçüncünün itibar "
            "eşiğini 8'den 5'e indirmek onları ayırdı. Dördüncünün kontrat eşiğini 12'ye "
            "<i>çıkarmak</i> da denendi ve <b>geri alındı</b>: perdeyi ayırdı ama finali yarıya "
            "düşürdü (6/8 → 3/8), çünkü dördüncüyü geciktirmek beşincinin ihtiyacı olan "
            "genişleme evresini de geciktiriyor. <b>Erken kapıyı ayarla, geç olanı değil.</b>",
            accent=RED, bg=REDBG,
        ),
        sp(3),
        para(
            "Bir de temiz bir <b>olumsuz sonuç</b>: simüle oyuncuyu bir perde erken genişletmek "
            "sonucu hiç değiştirmedi (final yine 5/8, ortanca yine 30). Yani finalin "
            "başarısızlık oranı politikanın değil gerçek zorluğun ölçüsü.",
            "small",
        ),
    ]
    return f
