# -*- coding: utf-8 -*-
"""Codex'in anlatı gövdesi: sistem sistem, örnekle."""

from reportlab.lib.units import mm
from reportlab.platypus import PageBreak, Spacer
from codex_base import (
    S, para, sp, table, callout, codebox, HRule, ColorBar,
    GOLD, GOLD_PALE, RED, GREEN, BLUE, RULE,
)

W = 170 * mm  # kullanılabilir genişlik


def part(num, title, blurb):
    return [
        para(f"BÖLÜM {num}", "partnum"),
        para(title, "part"),
        ColorBar(height=2.6),
        sp(8),
        para(blurb, "lead"),
        sp(6),
    ]


# =====================================================================
def ch1():
    f = part("I", "Oyun Nedir",
             "Wayborne bir kervan oyunu. Ama asıl konusu kervan değil, kervanı çekip "
             "çeviren insanlar ve onların yıpranması.")

    f += [
        para("İki ata", "h1"),
        para(
            "Oyun iki ayrı geleneğin kesişiminde duruyor ve bu kesişim tesadüf değil, "
            "tasarımın kendisi."
        ),
        sp(2),
        table(
            ["Kaynak", "Ne aldık", "Nerede görünür"],
            [
                ["<b>Darkest Dungeon</b>",
                 "Kadro kalıcı olarak yıpranır. İnsanlar kırılır, huy edinir, emir reddeder. "
                 "Dört mevkilik saf düzeni ve mevki-kilitli yetenekler.",
                 "Stres, huylar, kırılma, savaş sahası"],
                ["<b>Oregon Trail</b> tarzı kervan yönetimi",
                 "Kervan her gün yer. Yol uzadıkça kaynak erir. Kart değil, lojistik.",
                 "Erzak, vagon, moral aşınması, yol günü"],
                ["<b>EU4</b> olay kartları",
                 "Koşullu uygunluk, ağırlıklı çekim, seçenek → sonuç ağacı.",
                 "Yol olayları (Bölüm VIII)"],
            ],
            widths=[36 * mm, 84 * mm, 50 * mm],
        ),
        sp(8),

        para("Altı tasarım aksiyomu", "h1"),
        para(
            "Aşağıdaki altı cümle oyunun her sisteminde tekrar tekrar geçer. Bunlar üslup "
            "tercihi değil; her biri en az bir kez ihlal edildiği için yazıldı."
        ),
        sp(4),
    ]

    axioms = [
        ("1 · Kervan mahvolabilir ama yok olmaz",
         "Kese eksiye düşer, vagon uçuruma gider, yoldaş kervanı terk eder, savaş kaybedilir. "
         "Ama kimse ölmez ve son vagon asla gitmez. Savaşı kaybetmek yenilgi ekranı değil, "
         "yere düşenlerin 1 can ile ayağa kalkması demektir. Bu kural bir sınır değil bir "
         "vaat: oyuncu her şeyi kaybedebileceğini bilerek risk alır, ama kaydının silineceğini "
         "bilerek değil."),
        ("2 · Bedava çıkış yoktur",
         "Her olay seçeneği bir kaynağı başka bir kaynakla takas eder. Para, zaman, moral, "
         "stres, itibar, mal, risk - altı para birimi. Hiçbir seçenek altısını da bedavaya "
         "vermez. Gümrükte dürüst olmak bir gün yer, rüşvet itibar yer, kaçmak risk yer."),
        ("3 · Kilitli seçenek gizlenmez, sebebiyle gösterilir",
         "Kervanında Otacı yoksa “Otacı toprağı okusun” seçeneği ekrandan kalkmaz; soluk "
         "görünür ve altında <i>“Toprağı okuyacak otacın yok”</i> yazar. Oyuncu neye "
         "hazırlıksız yakalandığını öğrenmeden bir dahaki sefere hazırlanamaz. Aynı kural "
         "savaş yetenekleri, ekipman ve vagon satışı için de geçerli."),
        ("4 · Görünmeyen ceza hatadan ayırt edilemez",
         "Borç faizi işliyorsa oyuncu bunu bir ekranda görebilmeli. Sefere çıkış morali "
         "düşükse <i>neden</i> düşük olduğu yazmalı. Bir süre borç defteri hiçbir ekrana bağlı "
         "değildi: faiz işliyor, itibar eriyordu ve oyuncunun haberi yoktu. Bu bir denge "
         "sorunu değil, güven sorunudur."),
        ("5 · Rapor şaşırtıyorsa önce düzeneği şüphelen",
         "Bu dosyanın tarihinde <b>dört</b> ölçüm hatası var: moral kervan sıfırlandıktan sonra "
         "okunuyordu (hep 100 çıkıyordu), erzak düz bir stokla ölçülüyordu, kültür ile olay "
         "motoru aynı tohumdan türetiliyordu, kariyer probu pazar ticaretini hiç modellemiyordu. "
         "Dördü de oyunu değil ölçümü yanlış gösterdi."),
        ("6 · Sömürülebilen bir sistemde formül değil, sömürünün kapalılığı test edilir",
         "Pazarlık testleri “şu teklif şu fiyatı verir” demez; teklif aralığını baştan sona "
         "tarayıp sabırlı oyunun ulaşabileceği en iyi fiyatı bulur ve tüccarı kızdırmanın "
         "<b>kesinlikle daha kötü</b> olduğunu doğrular. Formül testi, bozuk tasarımı da "
         "mutlulukla onaylardı."),
    ]
    for t, b in axioms:
        f.append(callout(t, b))
        f.append(sp(4))

    f += [
        PageBreak(),
        para("Ana döngü", "h1"),
        para(
            "Oyun <b>şehirde başlar</b> ve şehre döner. Yol, şehirde verilen kararın bedelinin "
            "ödendiği yerdir. Döngünün tamamı şu sekiz adımdır:"
        ),
        sp(3),
        codebox([
            "<b>ŞEHİR</b>",
            "  1. Durum oku ....... Kervan neye muhtaç? Hikâye nerede? (CityBriefPanel)",
            "  2. Sat / Al ........ Talep edilen malı sat, üretilen malı al (Pazar)",
            "  3. Kontrat al ...... Gidilecek şehre yazılı teklifleri kabul et (Lonca)",
            "  4. Hazırlan ........ Vagon onar/al/sat, ekipman, tayfa, huy arındır, borç",
            "",
            "<b>PLANLAYICI</b>",
            "  5. Hedef seç ....... Rota, gün, tehlike, escort tüccarlar, erzak stoğu",
            "                       → çıkış morali burada hesaplanır ve sebebiyle gösterilir",
            "",
            "<b>YOL</b>  (her gün, sırayla)",
            "  6. a) Kontrat günü işler (süresi dolan varsa itibar yer)",
            "     b) Erzak tüketilir → beslenemezse AÇLIK (moral -10, stres +6)",
            "     c) Moral günlük aşınır (-2, tabanı 45)",
            "     d) Stres günlük artar (+2)",
            "     e) Olay zarı atılır → çıkarsa kart açılır, zaman durur",
            "",
            "<b>VARIŞ</b>",
            "  7. Ödeme hesaplanır (moral ve hasar kesintili) · XP dağıtılır",
            "     Stres kırılma zarı atılır → huy, bazen ayrılma",
            "     Şehir dinlenmesi stresi düşürür · Parti tam iyileşir",
            "  8. Kampanya bölümü kontrol edilir → kapanırsa ödül + bayrak",
            "     Oyun kaydedilir → 1. adıma dön",
        ]),
        sp(6),
        callout(
            "Sıralamanın kendisi bir tasarım kararı",
            "Yedinci adımda <b>kırılma zarı, şehir dinlenmesinden önce</b> atılır. Tersi olsaydı "
            "dinlenme stresi düşürür ve kırılma hiç yaşanmamış gibi olurdu - yolda biriken "
            "yıpranma kapıdan girer girmez silinirdi. Aynı şekilde kampanya kontrolü "
            "<b>en sonda</b> yapılır: ödeme yatmış, teslimat sayılmış, şehir görülmüş olmalı, "
            "yoksa her bölüm bir sefer geriden kapanırdı.",
            accent=BLUE, bg=__import__("reportlab").lib.colors.HexColor("#EAEFF5"),
        ),
    ]
    return f


# =====================================================================
def ch2():
    f = part("II", "Karakter",
             "Altı stat, beş kültür, dört sınıf, altı görev, on iki huy, on iki ekipman. "
             "Hepsi tek bir soruyu cevaplıyor: bu kervanı kim çekiyor?")

    f += [
        para("Altı stat ve azalan getiri", "h1"),
        para(
            "Statlar 1-15 arasında. Ama <b>yalnızca ilk 10 puan tam değerinde sayılır</b>; "
            "onun üstü yarım sayılır. Formül:"
        ),
        codebox(["etkin_değer(stat) = min(stat, 10) − 5 + 0.5 × max(0, stat − 10)"]),
        para(
            "Başlangıç değeri 5 olduğu için <b>etkin değer taban 5'te tam olarak sıfırdır</b>. "
            "Bu, her türetilmiş formülün <i>taban + katsayı × etkin_değer</i> biçiminde "
            "yazılabilmesini sağlar: taze bir karakter (hepsi 5) bu sistem hiç yokmuş gibi "
            "davranır, yavaşlama yalnızca 10'u aşınca devreye girer."
        ),
        sp(3),
        table(
            ["Stat değeri", "1", "5", "8", "10", "12", "15"],
            [["<b>Etkin değer</b>", "−4", "<b>0</b>", "+3", "+5", "+6", "+7.5"]],
            align_center=[1, 2, 3, 4, 5, 6],
        ),
        sp(3),
        callout(
            "Neden yavaşlama var?",
            "Tek bir stata yatırılan her puanın aynı değerde olması, tek bir statı "
            "maksimuma çıkarmayı baskın strateji yapardı. Onuncu puandan sonra getiri yarıya "
            "düşünce, ikinci bir stata geçmek matematiksel olarak cazip hale gelir - "
            "kural “maxlanmış bir stat oyunu domine etmemeli” diye konuldu.",
        ),
        sp(5),

        para("Türetilmiş değerler", "h1"),
        para(
            "Bu formüller <b>yalnızca CharacterStats içinde</b> yaşar. Karakter ekranı da savaş "
            "motoru da aynı yerden okur; ikinci bir kopya çıkarsa ekranda görülen sayı ile "
            "savaşta kullanılan sayı ayrışır."
        ),
        sp(2),
        table(
            ["Türetilmiş", "Formül", "Taban", "Besleyen stat"],
            [
                ["Azami can", "40 + 4 × etkin", "40", "Dayanıklılık"],
                ["İnisiyatif", "10 + 1 × etkin", "10", "Çeviklik"],
                ["İsabet", "80 + 2 × etkin", "80", "Sezgi"],
                ["Kaçınma", "10 + 2 × etkin", "10", "Çeviklik"],
                ["Kritik şansı", "7 + 1 × etkin", "7", "Sezgi"],
                ["Hasar bonusu", "5 + 1 × etkin", "5", "Güç"],
                ["Destek gücü", "5 + 1 × etkin", "5", "Zeka"],
                ["<b>Sükûnet</b>", "1.5 × etkin", "0", "<b>Karizma</b>"],
            ],
            widths=[34 * mm, 44 * mm, 22 * mm, 70 * mm],
            align_center=[2],
        ),
        sp(4),
        callout(
            "Karizma'nın hikâyesi: ölü bir statın diriltilmesi",
            "Altı stattan beşi savaşa bir şey veriyordu, Karizma hiçbir şey vermiyordu - ve "
            "Kalem Efendisi'nin afinitesinin yarısı olduğu için o sınıfın seviye puanlarının "
            "yarısı savaşta ölü harcamaydı. Çözüm <b>araştırmadan geldi</b>: Wartales'in "
            "Willpower'ı da seviyeyle büyümez ama ölü değildir; dump-stat literatürü de "
            "Karizma'nın D&D'de <i>moral ve tayfa sistemleri önemsizleşince</i> öldüğünü, "
            "reçetenin o sistemleri canlandırmak olduğunu söyler. Wayborne'da o sistemler "
            "zaten canlıydı (stres, kırılma, emir reddi). Karizma yeni bir sayıya değil "
            "<b>onlara</b> bağlandı: kırılmış bir savaşçının emri reddetme ihtimalinden "
            "1.5 × etkin Karizma düşülür.<br/><br/>"
            "<b>Ölçüm:</b> sakin bir partide Karizma hiçbir şey değiştirmiyor (5, 10, 15'te "
            "de kazanma oranı %45 - gizli bir evrensel bonus değil). Kırılmış bir partide "
            "%33 → %38 → %45. Reddi asla sıfırlamıyor (taban %5), çünkü bir sistemi tamamen "
            "kapatan stat o sistemi siler.",
            accent=GREEN, bg=__import__("reportlab").lib.colors.HexColor("#EAF0E8"),
        ),

        PageBreak(),
        para("Boy ve ten rengi", "h1"),
        para(
            "Görünüş burada süs değil. Boy 155-200 cm arası seçilir ve <b>mekanik bir takas</b> "
            "taşır: uzun olan daha çok can, daha az kaçınma; kısa olan tersi."
        ),
        sp(2),
        table(
            ["Boy", "Eşik", "Can bonusu", "Kaçınma bonusu"],
            [
                ["Uzun", "≥ 182 cm", "+3", "−2"],
                ["Orta", "167-181 cm", "0", "0"],
                ["Kısa", "≤ 166 cm", "−2", "+4"],
            ],
            align_center=[1, 2, 3],
        ),
        sp(3),
        para(
            "Ten rengi tamamen görsel - ama görünür: karakter oluşturmada seçilen boy ve ten, "
            "yol ekranında liderin arkasında yürüyen figürlerde birebir çizilir.",
            "small",
        ),
        sp(6),

        para("Beş kültür", "h1"),
        para(
            "Her kültür bir stat eğilimi, bir isim havuzu ve <b>tam olarak bir</b> mekanik perk "
            "taşır. Perk kuralı katı: <i>her perk zaten var olan bir sisteme bağlanır, yeni "
            "sistem icat etmez.</i>"
        ),
        sp(2),
        table(
            ["Kültür", "Stat eğilimi", "Mekanik perk", "Bağlandığı sistem"],
            [
                ["<b>Göçebe Boyları</b>", "Çeviklik +2, Dayanıklılık +1, Zeka −1",
                 "Günlük erzak <b>×0.7</b>", "Erzak formülü"],
                ["<b>Vadi Loncaları</b>", "Zeka +2, Karizma +1, Güç −1",
                 "Pazarda alım <b>×0.9</b>", "Pazar fiyatı"],
                ["<b>Dağ Kabilesi</b>", "Güç +2, Dayanıklılık +1, Karizma −1",
                 "Savaş hasarı <b>×1.15</b>", "Savaş çözümü"],
                ["<b>Liman Şehri</b>", "Karizma +2, Sezgi +1, Dayanıklılık −1",
                 "Dedikodu fiyatı <b>×0.6</b>", "Taverna rota bilgisi"],
                ["<b>Balıkçı Kasabası</b>", "Dayanıklılık +2, Sezgi +1, Çeviklik −1",
                 "Erzak fiyatı <b>×0.75</b>", "Erzak satın alma"],
            ],
            widths=[34 * mm, 48 * mm, 40 * mm, 38 * mm],
        ),
        sp(3),
        para(
            "Her kültürün ayrıca <b>kendi yol olayı</b> var (Bölüm VIII): Vadi'nin muhasebe "
            "anlaşmazlığı, Dağ'ın güç sınavı, Liman'ın rıhtım dedikodusu, Balıkçı'nın şanslı "
            "ağı. Göçebe'nin karşılığı ise “Yolda Bir Oba” - ama o olay <b>bütün kültürlere "
            "açık</b>: fark, karşılaştığın obanın seninle aynı kültürden çıkıp çıkmamasında.",
        ),
        sp(6),

        para("Dört sınıf", "h1"),
        para(
            "Sınıf savaş rolüdür ve iki şey taşır: <b>stat afinitesi</b> (otomatik puan dağıtımı "
            "buna göre harcar) ve <b>ana kervan görevi</b> (o görevi gerçekten üstlenirse "
            "daha iyi yapar)."
        ),
        sp(2),
        table(
            ["Sınıf", "Can", "Afinite", "Ana görev", "Yetenekleri"],
            [
                ["<b>Sıra Neferi</b>", "+6", "Dayanıklılık, Güç", "Muhafız",
                 "Kalkan Darbesi · Mızrak · Sapan · Toparla · Siper Al"],
                ["<b>Sekban</b>", "+2", "Çeviklik, Sezgi", "İzci",
                 "Ok Atışı · Ayak Bağı · Nişanlı Atış · Geri Çekil"],
                ["<b>Kırıkçı</b>", "+8", "Güç, Dayanıklılık", "Arabacı",
                 "Balyoz · Kalkan Kır · Öfke · Savuran Vuruş"],
                ["<b>Kalem Efendisi</b>", "0", "Zeka, Karizma", "Levazımcı",
                 "Coşturan Söz · Hesap Gör · Keskin Söz · Defter Tut"],
            ],
            widths=[30 * mm, 14 * mm, 30 * mm, 22 * mm, 74 * mm],
            align_center=[1],
        ),
        sp(3),
        para(
            "Not: kod tarafında <tt>class_name</tt> ayrılmış bir kelime olduğu için görünen ad "
            "<tt>display_name</tt> alanında durur - katalog kaynaklarının prose değil "
            "<b>çeviri anahtarı</b> tutması kuralının bir örneği.",
            "small",
        ),

        PageBreak(),
        para("Altı kervan görevi", "h1"),
        para(
            "Görev, savaş sınıfından <b>ayrıdır</b>. Herkes her görevi üstlenebilir; sınıfı "
            "eşleşen daha iyi yapar. Bir görev aynı anda tek kişide olur ve <b>görevsiz olmak "
            "asla ceza değildir</b> - çarpan 1.0'da kalır."
        ),
        sp(2),
        table(
            ["Görev", "Besleyen stat", "Ne yapar", "Nerede okunur"],
            [
                ["<b>Muhafız</b>", "Dayanıklılık", "Savaş açılış isabetini artırır", "CombatEncounter"],
                ["<b>İzci</b>", "Sezgi",
                 "Sefer süresini kısaltır · tehlikeyi ücretsiz tam gösterir · kestirme açar",
                 "Planlayıcı, harita, evt_scouted_pass"],
                ["<b>Levazımcı</b>", "Zeka", "Günlük erzak tüketimini düşürür",
                 "Erzak formülü, evt_spoiled"],
                ["<b>Arabacı</b>", "Güç", "Vagon onarım maliyetini ve hasarı düşürür", "Kervan Avlusu"],
                ["<b>Tellal</b>", "Karizma", "Pazarlık ve dedikodu fiyatını düşürür", "Pazarlık, Taverna"],
                ["<b>Otacı</b>", "Zeka", "Kamp stres rahatlamasını artırır · toprağı okur",
                 "make_camp, evt_cache, evt_spoiled"],
            ],
            widths=[24 * mm, 26 * mm, 62 * mm, 58 * mm],
        ),
        sp(4),
        para("Görev gücü formülü", "h2"),
        codebox([
            "güç = (1.0 + 0.05 × etkin_değer(görevin_statı)) × sınıf_çarpanı",
            "",
            "sınıf_çarpanı =  1.5   sınıfın ana görevi eşleşiyorsa",
            "                 1.25  ikinci sınıfı (multiclass) eşleşiyorsa",
            "                 1.0   eşleşme yoksa",
        ]),
        sp(3),
        callout(
            "Örnek · Levazımcı seçimi",
            "Kalem Efendisi, Zeka 12 (etkin +6). Levazımcı Zeka'dan besleniyor ve Kalem "
            "Efendisi'nin ana görevi.<br/>"
            "<tt>güç = (1.0 + 0.05 × 6) × 1.5 = 1.30 × 1.5 = <b>1.95</b></tt><br/><br/>"
            "Aynı görevi Zeka 5 (etkin 0) olan bir Kırıkçı üstlenseydi:<br/>"
            "<tt>güç = (1.0 + 0) × 1.0 = <b>1.00</b></tt><br/><br/>"
            "Yani doğru kişiye doğru görevi vermek erzak tüketimini neredeyse iki katı "
            "verimli kılıyor. Ama yanlış kişiye vermek de <b>hiçbir şey kaybettirmiyor</b> - "
            "bu, “görevsiz olmak ceza değildir” kuralının matematiksel karşılığı.",
        ),
        sp(5),

        para("On iki huy", "h1"),
        para(
            "Darkest Dungeon tarzı kalıcı kişilik izleri. Her stat için bir <b>erdem</b> ve bir "
            "<b>illet</b>. Bir karakter en fazla <b>3 huy</b> taşır."
        ),
        sp(2),
        table(
            ["Stat", "Erdem", "Etkisi", "İllet", "Etkisi"],
            [
                ["Güç", "Pazı Gücü", "Hasar +2", "Cılız Kol", "Hasar −2"],
                ["Çeviklik", "Çevik Adım", "Kaçınma +3", "Beceriksiz Ayak", "Kaçınma −3"],
                ["Dayanıklılık", "Demir Bünye", "Can +4", "Zayıf Bünye", "Can −4"],
                ["Zeka", "Basiretli", "İsabet +2", "Saf", "İsabet −2"],
                ["Sezgi", "Keskin Göz", "İsabet +3, Krit +1", "Miyop", "İsabet −3"],
                ["Karizma", "Güven Verici", "Kaçınma +2", "İtici", "Kaçınma −2"],
            ],
            widths=[26 * mm, 32 * mm, 34 * mm, 32 * mm, 30 * mm],
        ),
        sp(4),
        para("Huy nereden gelir, nasıl gider", "h2"),
        table(
            ["Kaynak", "Nasıl"],
            [
                ["<b>Doğuştan</b>", "Karakter oluşturulurken statlara <b>orantılı ağırlıkla</b> "
                 "yuvarlanır - tabandan uzak bir stat, o stata uyan huya meyleder. "
                 "Garanti değil, eğilim."],
                ["<b>Olaydan</b>", "GRANT_TRAIT etkisi (Sıkıntılı Gece, Gömülü Stok). "
                 "Her zaman oyuncu karakterini hedefler."],
                ["<b>Kırılmadan</b>", "Şehre varışta stresli her karakter için zar atılır: "
                 "%85 illet, <b>%15 erdem</b> - Darkest Dungeon'daki gibi zorluk bazen "
                 "insanı sağlamlaştırır."],
                ["<b>Arındırma</b>", "Yalnızca <b>5 gün içinde</b> kazanılmış “taze” huy silinebilir. "
                 "Kilise'de ucuz, Tavernada pahalı (60 GG). Köklenmiş bir huy kalıcıdır."],
            ],
            widths=[30 * mm, 124 * mm],
        ),
        sp(3),
        callout(
            "Kritik uygulama kuralı",
            "Savaş motoru huy bonuslarını <b>CharacterData'nın sarmalayıcı getter'larından</b> "
            "okumak zorundadır (<tt>get_max_hp()</tt>, <tt>get_dodge()</tt>…), doğrudan "
            "<tt>character.stats.get_X()</tt>'ten değil. Aksi halde huy bonusları "
            "<b>sessizce uygulanmaz</b> - hiçbir hata vermez, sadece çalışmaz. Ekipman "
            "bonusları da aynı sarmalayıcılardan geçer.",
            accent=RED, bg=__import__("reportlab").lib.colors.HexColor("#F6EAE7"),
        ),

        PageBreak(),
        para("Ekipman: dört slot, on iki parça", "h1"),
        para(
            "İki farklı felsefe aynı sistemde: <b>Silah ve Zırh</b> parayla alınan, yalnızca "
            "artı bonuslu kalıcı yükseltmeler; <b>Yüzük ve Kolye</b> ise satın alınamayan, "
            "yalnızca yolda bulunan ödünlü tılsımlar (bir stat artar, biri düşer)."
        ),
        sp(2),
        table(
            ["Parça", "Slot", "Tier", "Fiyat", "Seviye", "Bonus"],
            [
                ["Kervan Kılıcı", "Silah", "1", "150 GG", "1", "Hasar +2"],
                ["Ustalık Kılıcı", "Silah", "2", "350 GG", "<b>3</b>", "Hasar +4"],
                ["Şahin Kılıcı", "Silah", "3", "650 GG", "<b>6</b>", "Hasar +6"],
                ["Deri Zırh", "Zırh", "1", "150 GG", "1", "Can +4"],
                ["Zincir Gömlek", "Zırh", "2", "350 GG", "<b>3</b>", "Can +8"],
                ["Plaka Zırh", "Zırh", "3", "700 GG", "<b>6</b>", "Can +14"],
                ["Nişancı Yüzüğü", "Yüzük", "—", "bulunur", "1", "İsabet +5, <font color='#8E3B2F'>Kaçınma −2</font>"],
                ["Kumarbaz Yüzüğü", "Yüzük", "—", "bulunur", "1", "Krit +3, <font color='#8E3B2F'>İsabet −3</font>"],
                ["Tılsımlı Yüzük", "Yüzük", "—", "bulunur", "1", "Hasar +2, <font color='#8E3B2F'>Can −3</font>"],
                ["Muska", "Kolye", "—", "bulunur", "1", "Kaçınma +3, <font color='#8E3B2F'>Hasar −1</font>"],
                ["Kurt Dişi Kolye", "Kolye", "—", "bulunur", "1", "Can +3, <font color='#8E3B2F'>Kaçınma −2</font>"],
                ["Cesaret Muskası", "Kolye", "—", "bulunur", "1", "Krit +2, <font color='#8E3B2F'>Can −2</font>"],
            ],
            widths=[34 * mm, 20 * mm, 14 * mm, 22 * mm, 18 * mm, 46 * mm],
            align_center=[2, 3, 4],
        ),
        sp(4),
        callout(
            "Seviye kapısı neden var? (Darkest Dungeon modeli)",
            "Tier'lar bir süre <b>yalnızca parayla</b> kapalıydı: seviye 1 bir parti, parayı "
            "denkleştirdiği an tier 3 kuşanabiliyordu. Yani seviye, oyunun en güçlü ekseni "
            "üzerinde hiçbir anlam taşımıyordu.<br/><br/>"
            "Çözüm rakip oyunlardan geldi ve <b>ilk sezgiyi tersine çevirdi</b>. Darkest "
            "Dungeon'da resolve seviyesi <i>hiç stat büyütmez</i> - yalnızca Demirci'den "
            "alınacak teçhizatın ve Lonca'dan alınacak yetenek seviyelerinin <b>kapısıdır</b>. "
            "Seviye gücün kendisi değil, gücün anahtarıdır. Wayborne'da da öyle oldu: "
            "tier 2 → seviye 3, tier 3 → seviye 6.<br/><br/>"
            "Trinket'ler (Yüzük/Kolye) kapısız kaldı: onlar bulunur, satın alınmaz - "
            "kullanamadığın bir DD curio'su ödül sayılmaz.",
        ),
        sp(4),
        para("Ölçülen merdiven", "h2"),
        para("%65 tehlikede, iki kişilik partiyle:"),
        table(
            ["Basamak", "Kazanma oranı"],
            [["Seviye 1 + tier 1 teçhizat", "%33"],
             ["Seviye 3 + tier 2 teçhizat", "%70"],
             ["Seviye 6 + tier 3 teçhizat", "%88"]],
            widths=[80 * mm, 40 * mm], align_center=[1],
        ),
        sp(3),
        para(
            "<b>Basamakları ayrı ayrı değil birlikte ölç.</b> Sorunu bu kadar uzun saklayan "
            "şey tam olarak buydu: seviye raporu “düz” diyordu, ekipman raporu “güçlü” "
            "diyordu, hiçbiri ikisinin <i>birbirine bağlı olmadığını</i> söylemiyordu.",
            "small",
        ),
        sp(5),
        para("Deponun tek kapısı", "h2"),
        para(
            "Bir ekipman parçası asla doğrudan bir karaktere verilmez. Önce kervanın ortak "
            "deposuna (<tt>equipment_inventory</tt>) düşer; depo ile karakter arasındaki "
            "tek geçiş <tt>equip_to_character()</tt> / <tt>unequip_from_character()</tt>'dır. "
            "Bir slotu yükseltmek eski parçayı otomatik olarak depoya geri koyar. Bu yüzden "
            "GRANT_EQUIPMENT etkisi - GRANT_TRAIT'in aksine - kimseyi hedeflemez: ekipman, "
            "hangi karaktere takılacağı seçilene kadar nötr kalmalı."
        ),

        PageBreak(),
        para("Seviye, yetkinlik ve multiclass", "h1"),
        table(
            ["Kavram", "Değer / kural"],
            [
                ["Azami seviye", "20"],
                ["XP eğrisi", "taban 50, her seviyede <b>×1.25</b> büyür"],
                ["Seviye başına", "1 stat puanı + <b>2 yetkinlik puanı</b>"],
                ["Otomatik dağıtım", "Varsayılan açık. Yoldaşlarda açık kalır, oyuncu kendininkini "
                 "kapatabilir. Puanları sınıfın afinitesine ve kendi yeteneklerine harcar."],
                ["Multiclass", "<b>Seviye 7</b>'de açılır; iki sınıfın yetenek listeleri birleşir"],
                ["Yetkinlik", "Yetenek başına 0-100. O birimin hasarını/iyileştirmesini "
                 "<b>+%50'ye kadar</b> ölçekler ve bekleme süresini kısaltır."],
            ],
            widths=[36 * mm, 118 * mm],
        ),
        sp(4),
        callout(
            "Yetkinlik neden karakterde durur, yetenekte değil?",
            "<tt>CombatSkill</tt> nesneleri <b>paylaşılan tekil kaynaklardır</b> - bütün "
            "karakterler aynı “Kalkan Darbesi” nesnesini okur. Yetkinliği o nesnenin üstüne "
            "yazmak, bir karakterin yatırımını o yeteneği kullanan <i>herkese</i> sızdırırdı. "
            "Aynı sebeple düşman seviye ölçeklemesi de <tt>EnemyTemplate</tt>'in kendisine "
            "değil, yalnızca o savaş için kurulan <tt>CombatUnit</tt>'e uygulanan bir "
            "<tt>power_scale</tt> çarpanıdır.",
        ),
        sp(4),
        para("Tayfa adayları: üç mekân, üç havuz", "h1"),
        table(
            ["Mekân", "Aday sayısı", "Stat fazlası", "Taban ücret", "Seviye aralığı", "İtibar"],
            [
                ["<b>Meydan</b>", "2", "+2", "40 GG", "oyuncunun 3-1 altı", "—"],
                ["<b>Taverna</b>", "3", "+5", "70 GG", "oyuncunun 1 altı - 1 üstü", "—"],
                ["<b>Lonca</b>", "2", "+9", "140 GG", "oyuncu seviyesi - 3 üstü", "<b>5</b>"],
            ],
            widths=[26 * mm, 24 * mm, 24 * mm, 24 * mm, 40 * mm, 18 * mm],
            align_center=[1, 2, 3, 5],
        ),
        sp(3),
        para(
            "Adaylar <b>şehir varışı başına bir kez</b>, <tt>lokasyon + gün</tt> tohumundan "
            "yuvarlanır - ekranı kapatıp açmak yeniden zar attırmaz. Verilen seviye gerçek XP "
            "olarak işlenir, yani otomatik dağıtım puanlarını tıpkı seviye atlayan bir yoldaş "
            "gibi harcar. Ücret ayrıca seviye başına 10 GG artar.",
            "small",
        ),
    ]
    return f


# =====================================================================
def ch3():
    f = part("III", "Kervan",
             "Vagonlar, ağızlar, erzak, moral ve stres. Kervan bir envanter değil, her gün "
             "beslenmesi gereken bir topluluk.")

    f += [
        para("Vagon = kargo + parti yeri + iki ağız", "h1"),
        para(
            "Vagon almak üç şeyi birden değiştirir ve <b>üçüncüsü bir maliyettir</b>:"
        ),
        sp(2),
        table(
            ["Vagon sayısı", "Kargo kapasitesi", "Parti kapasitesi", "Beslenen tayfa"],
            [
                ["1", "50 birim", "2 kişi", "2"],
                ["2", "100 birim", "4 kişi (tavan)", "4"],
                ["3", "150 birim", "4 kişi", "6"],
                ["4", "200 birim", "4 kişi", "8"],
                ["6 (azami)", "300 birim", "4 kişi", "12"],
            ],
            align_center=[0, 1, 2, 3],
        ),
        sp(3),
        para(
            "<b>Tayfa ≠ parti.</b> Tayfa vagonları sürer ve kargo kapasitesini belirler "
            "(vagon başına 2 kişi). Parti ise isimli karakterlerdir ve <b>yalnızca onlar "
            "savaşır</b>. Savaş sahasında dört mevki olduğu için parti tavanı 4'tür; "
            "yani ikinci vagondan sonra alınan vagonlar parti yeri açmaz, sadece kargo "
            "ve ağız ekler."
        ),
        sp(4),
        table(
            ["İşlem", "Fiyat", "Kural"],
            [
                ["Vagon al", "150 + 60 × (sahip olunan − 1)", "Azami 6"],
                ["Vagon sat", "ödenen bedelin <b>%55'i</b>", "Hasarlıysa ayrıca ×0.6 · hasarlı olan önce gider"],
                ["Vagon onar", "hasarlı başına 30 GG", "Arabacı görevi indirim yapar"],
            ],
            widths=[30 * mm, 50 * mm, 74 * mm],
        ),
        sp(3),
        callout(
            "Satış neden alış fiyatını geri vermez?",
            "Verseydi al-sat bedava bir kapasite düğmesi olurdu: sefer öncesi vagon al, "
            "sefer sonrası sat. %55 amortisman bunu kapatıyor. Aynı şekilde <b>onarım her "
            "zaman sat-yeniden-al'dan ucuz</b> kalmalı, yoksa onarım ölü bir mekanik olurdu - "
            "test bunu formül varsayarak değil, aralığı tarayarak doğruluyor.<br/><br/>"
            "Satış kapalıysa <b>sebebiyle</b> gösterilir: son vagon, yolda olmak, kadronun "
            "sığmaması, yükün sığmaması. Yolda vagon kaybetmek kadroyu kapasitenin üstünde "
            "bırakabilir (kimse atılmaz) - ama bunu sessizce yapan bir <i>düğme</i> oyuncuya "
            "hata gibi görünürdü.",
        ),

        PageBreak(),
        para("Erzak: oyunun Oregon Trail omurgası", "h1"),
        para(
            "Kervan her gün yer, gün iyi geçse de kötü geçse de. Günlük tüketim <b>tek bir "
            "formülden</b> hesaplanır ve hem planlayıcı hem yol aynı formülü okur."
        ),
        codebox([
            "ağızlar   = isimli_parti + (vagon_sayısı × 2) + escort_tüccarlar",
            "tüketim   = max(1, round(ağızlar × kültür_çarpanı) − levazımcı_indirimi)",
        ]),
        sp(3),
        callout(
            "Örnek · Göçebe bir kervan",
            "3 parti üyesi, 2 vagon, 2 escort tüccar. Oyuncu Göçebe (×0.7), kervanda Zeka 10 "
            "bir Levazımcı var (indirim 1).<br/><br/>"
            "<tt>ağızlar = 3 + (2 × 2) + 2 = 9</tt><br/>"
            "<tt>tüketim = max(1, round(9 × 0.7) − 1) = max(1, 6 − 1) = <b>5 birim/gün</b></tt>"
            "<br/><br/>"
            "Aynı kervan Vadi kültüründe ve Levazımcısız olsaydı: <tt>round(9 × 1.0) = "
            "<b>9 birim/gün</b></tt> - neredeyse iki katı. Sekiz günlük bir seferde bu "
            "40 birime karşı 72 birim, yani 128 GG fark.",
        ),
        sp(4),
        callout(
            "Açlık “depo sıfırlandı” değil, “bugün besleyemedik” demektir",
            "Bu ayrım bir hata olarak keşfedildi. Eski koşul <tt>erzak ≤ 0</tt> idi; yani "
            "planlayıcının istediği kadarını <i>tam olarak</i> alan bir oyuncu son öğünden "
            "sonra sıfıra iniyor ve <b>her seferde</b> açlık cezası yiyordu (−10 moral, "
            "+6 stres). Ölçüldü: 16 gün/parti kombinasyonunun <b>16'sı da</b> aç kalıyordu.<br/><br/>"
            "Bu, varış moralinin neden ~55'te takılı durduğunun da cevabıydı - gizli bir "
            "sefer vergisi morali ayarlanmış gibi gösteriyordu. Şimdi açlık, o gün "
            "<i>gerçekten dağıtılabilen</i> miktar günün ihtiyacından azsa ateşlenir.",
            accent=RED, bg=__import__("reportlab").lib.colors.HexColor("#F6EAE7"),
        ),
        sp(4),
        para(
            "Erzak <b>kargo ağırlığından muaftır</b>: kendi sefer formülü var ve mal taşıma "
            "kapasitesini yemesi gerekmiyor. Ama diğer her şey ağırlık sınırına tabidir - "
            "ve bu sınır <tt>Inventory.add_item</tt>'ın <b>içinde</b> yaşar, yani bir olay "
            "ödülü de pazar alımıyla aynı kurala uyar. Yalnızca pazar ekranı kontrol ettiği "
            "sürece her şey o kontrolün etrafından dolaşıyordu.",
        ),

        PageBreak(),
        para("Moral ve stres: bilerek iki ayrı stat", "h1"),
        para(
            "Bu ikisini karıştırmak oyunun en kolay yapılacak tasarım hatası olurdu. "
            "Ayrımı akılda tutmanın yolu: <b>moral o seferin ruh hali, stres kervanın kalıcı "
            "yıpranması</b>."
        ),
        sp(2),
        table(
            ["", "MORAL", "STRES"],
            [
                ["Kapsam", "O sefere ait", "Parti geneli, kalıcı"],
                ["Başlangıç", "Her seferin başında yeniden hesaplanır", "Seferden sefere devreder"],
                ["Tavan / taban", "100 / aşınma tabanı 45", "100 / 0"],
                ["Günlük değişim", "−2 (yol aşınması)", "+2 (yol stresi)"],
                ["Ne yapar", "Varış ödemesini keser · isyanı açar",
                 "Kırılmayı, emir reddini ve kavgayı açar"],
                ["Nasıl düşer", "Olaylar, dinlenme yok", "Şehir dinlenmesi, kamp, ziyafet, olaylar"],
            ],
            widths=[28 * mm, 62 * mm, 64 * mm],
        ),
        sp(4),
        para("Sefere çıkış morali dünyanın halinden gelir", "h2"),
        para(
            "Moral 100'den başlamaz. <tt>get_departure_morale()</tt> onu <b>zaten var olan "
            "sistemlerden</b> besler - yeni bir “savaş/veba” mekaniği icat etmeden:"
        ),
        codebox([
            "çıkış_morali = 100",
            "   − 30 × zorluk        (mevsim, fiyat şokları, enflasyon)",
            "   − 25 × (stres / 100)",
            "   − 10                 (vadesi geçmiş borç varsa)",
            "   + min(8, itibar × 0.5)",
            "   ve asla 45'in altına inmez",
        ]),
        para(
            "Planlayıcı ekranı bu sayıyı <b>sebepleriyle birlikte</b> gösterir. Görünmeyen "
            "bir ceza oyuncu için hatadan ayırt edilemez.",
            "small",
        ),
        sp(4),
        callout(
            "İsyan eşiğinin hikâyesi: üç adım ve bir ölçüm hatası",
            "Uzun süre “moral hiç düşmüyor” sanıldı. Bu bir <b>ölçüm hatasıydı</b>: simülatör "
            "morali <tt>finish_journey()</tt>'den <i>sonra</i> okuyordu, o çağrı da kervanı "
            "sıfırlıyor - yani raporlanan sayı her koşuda tam olarak 100.0 çıkıyordu.<br/><br/>"
            "Düzeltilince gerçek tablo göründü: moral 100'den ~60'a düşüyor ama "
            "<tt>evt_mutiny</tt> hiçbir koşulda ateşlenmiyor. Üç sebep birlikte çalışıyordu - "
            "moral her seferde 100'den başlıyor, günlük aşınma yok, olay havuzunun moral "
            "bilançosu neredeyse başabaş (+192 / −199).<br/><br/>"
            "Çözüm üç adım oldu: <b>(1)</b> günlük aşınma eklendi, <b>(2)</b> eşik 25'ten 40'a "
            "indi, <b>(3)</b> olaya ×24 ağırlık çarpanı verildi - çünkü eşik tek başına yetmedi, "
            "kart 25 rakip arasında çekimi hiç kazanamıyordu. <b>Sonuç:</b> varış morali ~55, "
            "koşuların %7.5-10.5'i eşiğe iniyor, 600 koşuda 6 isyan.",
        ),

        PageBreak(),
        para("Stres: birikmesi gereken sayı", "h1"),
        para(
            "Stres uzun süre <b>hiç birikmedi</b>: bir sefer ~25 getiriyor, şehir varışı 35 "
            "siliyordu. Yani sayı her döngüde sıfırlanıyor ve kavga olayı hiç ateşlenmiyordu. "
            "Düzeltme tek bir kola dokunmakla olmadı."
        ),
        sp(2),
        table(
            ["Kol", "Eski", "Yeni", "Neden"],
            [
                ["Kavga eşiği", "70", "<b>40</b>", "Ölçülen varış stresi ~25 idi; 70 hiç görülmüyordu"],
                ["Şehir dinlenmesi", "35", "<b>14</b>, günlerle eriyor (taban 6)",
                 "Aynı han odası on sefer sonra daha az iyi gelmeli"],
                ["Kamp rahatlaması", "20", "<b>8</b>",
                 "20'de her sefer kamp kuran oyuncuda stres <i>hâlâ</i> hiç birikmiyordu"],
            ],
            widths=[28 * mm, 18 * mm, 46 * mm, 62 * mm],
        ),
        sp(3),
        para(
            "<b>Ders:</b> bir stat kıpırdamıyorsa, onu <i>artıran</i> şeye dokunmadan önce "
            "azaltan her şeyi tek tek say. İlk iki kol tek başına yetmedi ve bu ancak "
            "ölçülünce görüldü.",
            "small",
        ),
        sp(4),
        para("Stresin üç kolu: bedava-yavaş, paralı-karneli, şanslı", "h2"),
        table(
            ["Kol", "Nerede", "Bedeli", "Etkisi"],
            [
                ["<b>Kamp</b>", "Yolda, akşam/gece",
                 "3 erzak + saatler (yol süresi uzamaz ama vakit akar)", "−8 stres (Otacı artırır)"],
                ["<b>Ziyafet</b>", "Taverna", "Kişi başı 45 GG, <b>günde bir kez</b>",
                 "−22 stres"],
                ["<b>Şehir dinlenmesi</b>", "Her varışta, otomatik", "yok",
                 "−14, günlerle eriyerek −6'ya"],
                ["<b>Olaylar</b>", "Türbe, oba, iyi uyku", "değişken", "−6 … −10"],
                ["<b>Yeni tayfa</b>", "Tayfa ekranı", "ücret + yoldaşın kaybı",
                 "Ortalamayı seyreltir (yeni gelen %40 pay ile gelir)"],
            ],
            widths=[28 * mm, 30 * mm, 52 * mm, 44 * mm],
        ),
        sp(4),
        callout(
            "Ziyafet neden günde bir kez?",
            "Karnesiz hali <b>oyunun en büyük sömürüsüydü</b>: beş ziyafet stresi 90'dan 0'a "
            "indiriyordu, toplam 225 altına - bir seferin net gelirinden az. Bir kadroyu bir "
            "akşamda beş kez ayıltamazsın, ve altının anında sildiği bir stat kalıcı değildir. "
            "Günler yalnızca yolda ilerlediği için “günde bir” pratikte “şehir ziyareti başına "
            "bir” demek. <tt>last_feast_day</tt> kayda yazılır - yoksa oyunu yeniden yüklemek "
            "sayacı sıfırlardı, ve <b>yeniden yüklemekle sıfırlanabilen bir kol, kol değildir</b>.",
        ),
        sp(4),
        para("Ölçülen stres eğrisi", "h2"),
        para("On iki ardışık sefer boyunca (her biri ~25 stres getiriyor):"),
        table(
            ["Oyun tarzı", "1 / 6 / 12 sefer sonra", "Kavga eşiğindeki sefer oranı"],
            [
                ["Hiç müdahale yok", "11 / 69 / 88 (tavan)", "%84"],
                ["Sefer başına bir kamp", "4 / 22 / 49", "%43"],
                ["Bir kamp + ziyafet", "4 / 22 / 28 (plato)", "%37, ~43 altın"],
                ["Sefer başına iki kamp", "0 / 0 / 1", "%0"],
            ],
            widths=[42 * mm, 54 * mm, 58 * mm],
        ),
        sp(2),
        para(
            "Son satır bir gözden kaçma değil, bilerek: geceleri, yiyeceği ve gün ışığını "
            "harcayıp bir seferde iki kez kamp kuran bir oyuncu stresi <i>bastırabilmeli</i>. "
            "“Birini kov, birini tut” da sömürü değil, çünkü <b>domine edilmiş</b> durumda: "
            "sekiz işe alımla stres 90'dan 6'ya iner ama sekiz işe alım aynı işi yapan "
            "ziyafetlerden çok daha pahalıdır - üstüne her yoldaşın seviyesi, huyları ve "
            "ekipmanı gider.",
            "small",
        ),
        sp(4),
        para("Kırılma: kim, ne zaman, nasıl", "h1"),
        para(
            "Kırılma <b>kişiseldir</b>, global bir eşik değil. Her karakterin kendi direnci "
            "Dayanıklılığından gelir; parti stresi <i>o kişinin</i> çizgisini aştığında o kişi "
            "kırılmış sayılır. Yüksek dirençli biri sakin kalırken düşük dirençli biri çoktan "
            "kırılmış olabilir."
        ),
        codebox([
            "Şehre varışta, kırılmış her karakter için:",
            "   %85 → bir illet huyu",
            "   %15 → bir ERDEM huyu   (zorluk bazen insanı sağlamlaştırır)",
            "   ayrıca afetli bir yoldaş (asla oyuncu) %20 ihtimalle kervanı terk edebilir",
            "",
            "Savaşta, kırılmış birimin sırası geldiğinde:",
            "   red_ihtimali = max(%5, %20 − 1.5 × etkin_Karizma)",
            "   → sıra atlanır, günlüğe yazılır, oyuncuya seçenek sunulmaz",
        ]),
    ]
    return f
