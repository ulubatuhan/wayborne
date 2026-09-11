# -*- coding: utf-8 -*-
"""WAYBORNE CODEX - tam belgeyi kurar ve PDF'e basar."""

import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.platypus import (
    BaseDocTemplate, Frame, PageTemplate, PageBreak, Paragraph, Spacer, Table, TableStyle,
)

from codex_base import (
    S, para, sp, table, callout, codebox, HRule, ColorBar,
    INK, INK_SOFT, MUTED, GOLD, GOLD_PALE, PARCH, RULE, RED, GREEN, BLUE, ROW_ALT,
    PAGE_W, PAGE_H, MARGIN,
)
from codex_event import event_page, EFFECT_LABEL
from codex_events_data import EVENTS
from codex_body import ch1, ch2, ch3, part
from codex_body2 import ch4, ch5, ch6, ch7

BLUEBG = colors.HexColor("#EAEFF5")
REDBG = colors.HexColor("#F6EAE7")
GREENBG = colors.HexColor("#EAF0E8")

# Üretilen PDF, üreteciyle yan yana değil bir üst dizinde (docs/) durur -
# depoya girmiş olan dosyanın üzerine yazsın, yanına ikinci bir kopya
# bırakmasın diye.
OUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "Wayborne-Codex.pdf")


# ---------------------------------------------------------------- BÖLÜM VIII
def ch8_engine():
    f = part("VIII", "Olay Motoru",
             "Yolun kalbi. Yirmi yedi kart, koşullu uygunluk, ağırlıklı çekim ve "
             "dallanan sonuçlar - EU4'ün olay bloğunun kervan karşılığı.")

    f += [
        para("Bir günün anatomisi", "h1"),
        para(
            "Yoldaki her gün aynı sırayla işler. Olay zarı <b>en son</b> atılır, çünkü "
            "olayın koşulları o günün erzağını, moralini ve stresini görmüş olmalı."
        ),
        codebox([
            "1.  Günlük olay ihtimali hesaplanır:",
            "        ihtimal = 0.35 × (0.5 + tehlike)     [tavan %95]",
            "        → %20 tehlikede %24,  %65 tehlikede %40,  %90 tehlikede %49",
            "",
            "2.  Zar geçerse UYGUNLUK FİLTRESİ çalışır. Bir kart uygun DEĞİLDİR eğer:",
            "        · triggered_only ve henüz UNLOCK_EVENT ile açılmadıysa",
            "        · fire_only_once ve daha önce çıktıysa",
            "        · bekleme süresi (cooldown) hâlâ doluysa",
            "        · kendi koşullarından biri sağlanmıyorsa",
            "",
            "3.  Uygun kartlar arasında AĞIRLIKLI ÇEKİM yapılır:",
            "        ağırlık = taban_ağırlık × (koşulu tutan her değiştiricinin çarpanı)",
            "",
            "4.  Kart açılır → immediate_effects hemen uygulanır (oyuncu seçmeden)",
            "5.  Oyuncu bir seçenek seçer → seçeneğin garanti etkileri uygulanır",
            "6.  Seçeneğin sonuç listesi varsa, KOŞULU TUTAN sonuçlar arasında",
            "    ikinci bir ağırlıklı çekim yapılır → o sonucun etkileri uygulanır",
            "7.  Kart 'çıktı' diye işaretlenir: bir-kez ve bekleme kayıtları güncellenir",
        ]),
        sp(5),
        callout(
            "Uygun olmak yetmez, çekimi de kazanmak gerekir",
            "Bu ders pahalıya öğrenildi. <tt>evt_mutiny</tt>'nin moral eşiği 25'ten 40'a "
            "indirildi ve olay <b>hâlâ hiç ateşlenmedi</b>: moralin eşiğin altına indiği 45 "
            "simüle günde bile kart, ~25 rakip arasında ağırlıklı çekimi bir kez bile "
            "kazanamadı. Yalnızca <b>×24</b>'lük bir ağırlık değiştiricisi eklenince göründü."
            "<br/><br/>"
            "Kural: bir olay “katalogda var ama oyunda yok” ise, <b>önce çekime bak</b>, "
            "yalnızca koşula değil.",
            accent=RED, bg=REDBG,
        ),
        sp(4),
        para("Kartın altı alanı", "h1"),
        table(
            ["Alan", "Ne yapar"],
            [
                ["<tt>base_weight</tt>", "Havuzdan çekilme ağırlığı. Havuzdaki değerler 0.6 - 3.0 arası."],
                ["<tt>conditions</tt>", "Uygunluk kapısı (EU4'ün “trigger”ı). Hepsi tutmalı."],
                ["<tt>weight_modifiers</tt>",
                 "Koşullu ağırlık çarpanı (EU4'ün MTTH modifier mantığı). Örn. tehlike ≥ %50 ise ×2."],
                ["<tt>cooldown_days</tt>", "Tekrar çıkabilmesi için geçmesi gereken gün. 0 = beklemesiz."],
                ["<tt>fire_only_once</tt>", "Oyun boyunca tek sefer."],
                ["<tt>triggered_only</tt>",
                 "Havuzdan <b>rastgele çekilmez</b>; yalnızca UNLOCK_EVENT açarsa uygun olur. "
                 "Zincir olaylarının temeli."],
                ["<tt>immediate_effects</tt>",
                 "Kart görünür görünmez, oyuncu seçim yapmadan uygulanır. Pratikte tek kullanımı "
                 "ROLL_ENCOUNTER: karşındakinin mizacını yuvarlamak."],
            ],
            widths=[38 * mm, 116 * mm],
        ),

        PageBreak(),
        para("Etki sözlüğü: dünyaya dokunmanın tek yolu", "h1"),
        para(
            "Bir olay dünyaya <b>yalnızca</b> bu yirmi beş etki üzerinden dokunabilir. Motor bu "
            "kelime dağarcığının dışına çıkamaz. Yeni bir etki gerekiyorsa enum'a eklenir "
            "<b>ve</b> uygulayıcıda karşılığı yazılır - yoksa <b>sessizce hiçbir şey yapmaz</b>."
        ),
        sp(3),
        table(
            ["Küme", "Etki", "Ne yapar"],
            [
                ["<b>Kaynak</b>", "GOLD", "Keseyi değiştirir (eksiye düşebilir → borç doğar)"],
                ["", "PROVISIONS", "Erzak ekler/çıkarır (asla sıfırın altına inmez)"],
                ["", "ITEM_ADD / ITEM_REMOVE", "Kargoya mal ekler/siler - <b>ağırlık sınırına tabi</b>"],
                ["<b>Kervan</b>", "WAGON_DAMAGE", "Vagonu hasarlı işaretler (varış ödemesini keser)"],
                ["", "WAGON_LOSE", "<b>Vagonu tamamen kaybeder</b> - MIN_WAGONS'a kenetli"],
                ["", "WAGON_REPAIR", "Yolda vagon onarır (avlunun yol karşılığı)"],
                ["", "MERCHANT_LEAVE", "Escort tüccar kervanı terk eder → kontrat teslim edilemez"],
                ["", "MORALE / STRESS", "İki ayrı stat (bkz. Bölüm III)"],
                ["<b>Yolculuk</b>", "TRAVEL_DAYS", "Yol süresini uzatır/kısaltır"],
                ["", "DANGER", "O seferin tehlikesini değiştirir (olay ihtimalini de etkiler)"],
                ["<b>Dünya</b>", "REPUTATION", "İtibar - oyunun en kıt kaynağı"],
                ["", "DOCUMENT_LOSE", "Evrak kaybı (gümrükte “evrak göster” kapanır)"],
                ["", "SET_FLAG / CLEAR_FLAG", "Kalıcı bayrak - sonraki olaylar okur"],
                ["", "UNLOCK_EVENT", "<b>triggered_only</b> bir kartı uygun hale getirir"],
                ["<b>Köprü</b>", "TRIGGER_COMBAT", "Savaş panelini açar (tür: bandit / wildlife / guard)"],
                ["", "TRIGGER_HAGGLING", "Pazarlık mini-oyununu açar"],
                ["", "TRIGGER_RECRUIT", "Tayfa ekranını açar"],
                ["<b>Karakter</b>", "GRANT_TRAIT", "Oyuncu karakterine huy verir (taze sayılır)"],
                ["", "GRANT_EQUIPMENT", "<b>Depoya</b> ekipman yazar - kimseye takmaz"],
                ["<b>Ekonomi</b>", "MARKET_SHOCK", "Süreli fiyat kayması: “şehir | mal | gün”, tutar = yüzde"],
                ["<b>Rota</b>", "ROUTE_CHANGE", "Yolun durumunu süreli değiştirir - <b>iki yöne birden</b>"],
                ["<b>İnsan</b>", "ROLL_ENCOUNTER", "Karşındakinin gizli mizacını ve kültür yakınlığını yuvarlar"],
            ],
            widths=[24 * mm, 40 * mm, 90 * mm],
        ),
        sp(4),
        callout(
            "Ölü bir etki tipi, eksik olandan daha kötüdür",
            "<tt>WAGON_LOSE</tt> uygulayıcıda tam olarak yazılmıştı ve <b>hiçbir olay onu "
            "kullanmıyordu</b>. Yani “kervan mahvolabilir” kuralının bu yarısı yalnızca kâğıt "
            "üstündeydi: 600 koşuda ortalama vagon kaybı tam olarak <b>0.00</b> çıkıyordu. "
            "Şimdi iki kapısı var (Fırtına ve Heyelan) ve ikisi de bilerek nadir - ölçülen "
            "oran ~40 seferde bir vagon. Kaybedilen bir vagon tekrarlayan bir ücret değil, "
            "hatırlanacak bir felaket olmalı.",
            accent=RED, bg=REDBG,
        ),

        PageBreak(),
        para("Mizaç: karşındakinin kim olduğunu bilmezsin", "h1"),
        para(
            "Yolda karşılaşılan birinin gizli bir mizacı vardır. <b>ROLL_ENCOUNTER</b> bunu "
            "kart açılır açılmaz bir bayrağa yazar; seçeneklerin sonuçları o bayrağa dallanır. "
            "Oyuncuya <i>söylenmez</i> - sezgisi kuvvetli bir parti üyesi yalnızca bir "
            "<b>ipucu</b> verebilir."
        ),
        sp(3),
        table(
            ["Mizaç", "Ağırlık", "Ne yapar"],
            [
                ["<b>Sadık</b>", "42.0 (%42)", "Borcunu öder, iyiliği unutmaz"],
                ["<b>Çaresiz</b>", "24.0 (%24)", "Zararsız; yardım görürse minnettar"],
                ["<b>Hırsız</b>", "18.0 (%18)", "Sabaha kese ya da erzak eksilir"],
                ["<b>Kinci</b>", "16.0 (%16)", "Reddedilirse susar, <b>günler sonra döner</b>"],
            ],
            widths=[26 * mm, 28 * mm, 100 * mm],
            align_center=[1],
        ),
        sp(3),
        para(
            "<b>Çoğu insan dürüsttür</b> (%66 sadık veya çaresiz) - yoksa kimseyi kervana "
            "almamak baskın strateji olurdu ve olayın “kararı” diye bir şey kalmazdı."
        ),
        sp(3),
        table(
            ["Eşik", "Değer", "Ne açar"],
            [
                ["Mizacı okuma", "etkin Sezgi ≥ 2", "Karşındakinin mizacına dair bir ipucu"],
                ["Manipülasyon", "etkin Karizma ≥ 2", "“Söz ver, oyala” gibi seçenekler"],
            ],
            widths=[32 * mm, 34 * mm, 88 * mm],
        ),
        sp(4),
        para("Kültür yakınlığı", "h2"),
        para(
            "<b>ROLL_ENCOUNTER</b> aynı anda karşılaşılan grubun kültürünü de yuvarlar ve "
            "<i>liderin</i> kültürüyle eşleşirse bir <tt>&lt;önek&gt;_kin</tt> bayrağı kurar. "
            "Bu, “Yolda Bir Oba” olayının bütün kültürlere açık olmasını sağlıyor - eskiden "
            "yalnızca Göçebe oyunculara açıktı ve dört kültürü olaydan dışlıyordu."
        ),
        sp(4),
        callout(
            "Kararın faturası hemen kesilmeyebilir",
            "Kinci bir yolcuyu görmezden gelmek o gün yalnızca <b>−2 moral</b>'dir - ucuz "
            "görünür. Ama bir bayrak kurulur ve <tt>triggered_only</tt> bir zincir olayı "
            "(“Tanıdık Bir Yüz”) açılır. Bedel <b>günler sonra, bambaşka bir yolda</b> gelir: "
            "ya 120 altın ya savaş.<br/><br/>"
            "Aynı zincir <i>iki ayrı olaydan</i> beslenir - yol kenarında kovduğun yolcu ve "
            "karakola verdiğin kaçak aynı bayrağı kurar. Bu yüzden oyuncu onu kimin "
            "gönderdiğini asla tam bilemez.",
        ),
        sp(4),
        para("Havuzun dağılımı", "h1"),
        table(
            ["Küme", "Kart sayısı", "Kartlar"],
            [
                ["Çatışma", "3", "Haydut Pususu · Yol Kesen Vahşi · Muhafız Devriyesi"],
                ["Kervan / lojistik", "6", "Gümrük · Kırılan Aks · Fırtına · Heyelan · Bozulan Erzak · Hasta Tüccar"],
                ["İnsan / mizaç", "5", "Yolcu · Kaçak · Oba · <i>iki zincir kartı</i>"],
                ["İç dünya / kriz", "4", "Huzursuzluk · Kamp Kavgası · Sıkıntılı Gece · Terk Edilmiş Vagon"],
                ["Curio", "2", "Yol Kenarı Türbesi · Gömülü Stok"],
                ["Rota", "2", "Bilinmeyen Kestirme · Yol Devriyesi"],
                ["Ticaret", "1", "Gezgin Demirci"],
                ["Kültür", "4", "Vadi · Dağ · Liman · Balıkçı"],
                ["<b>TOPLAM</b>", "<b>27</b>", "bunların 2'si yalnızca zincirle açılır"],
            ],
            widths=[36 * mm, 22 * mm, 96 * mm],
            align_center=[1],
        ),
    ]
    return f


# ---------------------------------------------------------------- OLAY AĞACI
def ch8_tree():
    f = [
        PageBreak(),
        para("OLAY AĞACI", "partnum"),
        para("Yirmi yedi kart, tek tek", "part"),
        ColorBar(height=2.6),
        sp(8),
        para(
            "Bundan sonraki sayfalarda havuzdaki her kart kendi sayfasında duruyor: ne zaman "
            "çıktığı, kart açılır açılmaz ne olduğu, hangi seçeneklerin hangi koşullarla "
            "açıldığı ve her seçeneğin hangi sonuçlara dallandığı.",
            "lead",
        ),
        sp(5),
        para("Sayfaları nasıl okumalı", "h2"),
        table(
            ["İşaret", "Anlamı"],
            [
                ["<font color='#23201B'><b>┃</b></font> Koyu bant",
                 "Bir <b>seçenek</b> - oyuncunun tıkladığı şey"],
                ["<font color='#9A7B3F'><b>┃</b></font> Altın bant",
                 "Bir <b>sonuç</b> - seçenekten sonra ağırlıklı çekilen dal"],
                ["<font color='#4A6B45'><b>yeşil</b></font>", "Oyuncunun lehine etki"],
                ["<font color='#8E3B2F'><b>kırmızı</b></font>", "Oyuncunun aleyhine etki"],
                ["<font color='#3F5B77'><b>mavi</b></font>", "Başka bir sistemi açan köprü"],
                ["<i>ağırlık</i>", "Sonucun çekim ağırlığı; yalnızca <b>koşulu tutan</b> sonuçlar yarışır"],
                ["<i>koşul</i>", "Bu dalın çekilebilmesi için gereken bayrak ya da değer"],
                ["<i>kilitliyken</i>", "Seçenek kapalıysa oyuncunun gördüğü sebep"],
            ],
            widths=[44 * mm, 110 * mm],
        ),
        sp(4),
        callout(
            "Ağırlıkları okurken",
            "Bir seçeneğin sonuçları arasındaki ağırlıklar <b>birbirine görelidir</b>. "
            "Örneğin Fırtına'nın “ilerle” seçeneğinde 1.0 / 1.0 / 0.4 ağırlıkları var: "
            "toplam 2.4, yani vagon kaybı ihtimali 0.4 ÷ 2.4 ≈ <b>%17</b>. Mizaca bağlı "
            "dallarda ağırlık 4.0'dır ve düz dal 1.0'dır; ama koşullu dal <i>yalnızca</i> "
            "mizaç tuttuğunda yarışa girer - tutmadığında düz dal tek başına kalır ve "
            "kesinlikle o çekilir.",
        ),
    ]

    for ev in EVENTS:
        f.append(PageBreak())
        f += event_page(ev)
    return f


# ---------------------------------------------------------------- EK
def appendix():
    f = [
        PageBreak(),
        para("EK", "partnum"),
        para("Sayı Tabloları", "part"),
        ColorBar(height=2.6),
        sp(8),
        para(
            "Bu tablolardaki her sayı ayarlanmak üzere konmuş bir yer tutucudur. Değişmez "
            "olanlar sayılar değil, sayıların ne yaptığıdır.",
            "lead",
        ),
        sp(5),

        para("Kervan ve ekonomi", "h1"),
        table(
            ["Sabit", "Değer"],
            [
                ["Başlangıç: kese / erzak / vagon / parti", "250 GG · 20 · 1 · 2 kişi"],
                ["Vagon başına kargo", "50 birim"],
                ["Vagon başına tayfa (ağız)", "2"],
                ["Azami parti / azami vagon", "4 kişi · 6 vagon"],
                ["Vagon fiyatı", "150 + 60 × (sahip olunan − 1)"],
                ["Vagon satış oranı / hasarlı ek indirim", "%55 · ×0.6"],
                ["Vagon onarımı", "hasarlı başına 30 GG"],
                ["Erzak birim fiyatı", "4 GG"],
                ["Kontrat kaybı cezası", "5 itibar"],
                ["Kontrat vadesi", "yol günü + 10 gün"],
                ["Büyük kontrat itibar şartı", "5"],
                ["Şehir başına mal stoğu", "30 birim (her varışta dolar)"],
                ["Altın hedefi (bir kereye mahsus ekran)", "5000 GG"],
            ],
            widths=[86 * mm, 68 * mm],
        ),
        sp(4),
        para("Moral, stres, borç", "h1"),
        table(
            ["Sabit", "Değer"],
            [
                ["Azami moral / günlük aşınma / aşınma tabanı", "100 · −2 · 45"],
                ["Azami stres / günlük yol stresi", "100 · +2"],
                ["Şehir dinlenmesi", "−14, günde %2 eriyerek −6'ya"],
                ["Kamp: erzak / stres", "3 birim · −8"],
                ["Ziyafet: kişi başı / rahatlama / karne", "45 GG · −22 · günde 1"],
                ["Yeni tayfanın stres payı", "%40"],
                ["Kırılma: illet / erdem / ayrılma", "%85 · %15 · %20"],
                ["İsyan moral eşiği / ağırlık çarpanı", "40 · <b>×24</b>"],
                ["Kavga stres eşiği", "40"],
                ["Çıkış morali tabanı", "45"],
                ["Borç vadesi", "30 gün"],
                ["Gecikme: dönem / faiz / itibar", "10 gün · %15 · 3 puan"],
                ["Yapılandırma: vade / ücret / büyüme", "+20 gün · %12 · her seferinde +%6"],
                ["Kredi hattı", "200 + 25 × itibar, tavan 1200"],
                ["Kredi tahsis ücreti", "%10 (tam sayı aritmetiği)"],
            ],
            widths=[86 * mm, 68 * mm],
        ),

        PageBreak(),
        para("Savaş", "h1"),
        table(
            ["Sabit", "Değer"],
            [
                ["Saf başına mevki", "4"],
                ["İsabet kenetlemesi", "%5 - %95"],
                ["Kritik çarpanı", "×1.5"],
                ["Emir reddi tabanı / tabanın tabanı", "%20 · %5"],
                ["Sükûnet (Karizma)", "1.5 × etkin değer, reddin üstünden düşülür"],
                ["Düşman: seviye başına / parti üyesi başına", "+%2 · +%10"],
                ["Yetkinlik ölçeği", "+%50'ye kadar"],
            ],
            widths=[86 * mm, 68 * mm],
        ),
        sp(4),
        para("Yol ve zaman", "h1"),
        table(
            ["Sabit", "Değer"],
            [
                ["Rota durum penceresi", "6 gün (rotaya göre kaydırılır)"],
                ["Durum ihtimalleri: kapalı / yavaş / tehlikeli", "%5 · %15 · %13 (kışın ×2.2)"],
                ["Bozulma tavanı", "%55"],
                ["Yavaş yolun süre çarpanı", "×1.6"],
                ["Tehlikeli yolun tehlike eklentisi", "+0.22 (boşluğa uygulanır)"],
                ["Tehlike büyümesi", "günde +%0.4, tavan ×1.6"],
                ["Gerçek zamanda bir gün", "45 saniye (1× hızda)"],
                ["Hız kademeleri", "1× / 1.5× / 3×"],
                ["Gün dönümü saati", "06:00 (şafak)"],
                ["Günlük olay ihtimali", "0.35 × (0.5 + tehlike), tavan %95"],
            ],
            widths=[86 * mm, 68 * mm],
        ),
        sp(4),
        para("Mallar", "h1"),
        table(
            ["Mal", "Taban fiyat", "Birim ağırlık", "Üreten şehir", "Arayan şehir"],
            [
                ["Erzak", "4 GG", "0.5", "—", "— <i>(ağırlıktan muaf)</i>"],
                ["Buğday", "5 GG", "1.0", "Karakonak", "Demirkapı"],
                ["Top Kumaş", "12 GG", "1.5", "İpekevi", "Yeşilova"],
                ["Otacı İksiri", "20 GG", "0.5", "Yeşilova", "İpekevi"],
                ["İşlenmiş Kürk", "30 GG", "2.0", "Kurtboğazı", "Karakonak"],
                ["Demirci Malı Silah", "40 GG", "2.5", "Demirkapı", "Kurtboğazı"],
            ],
            widths=[38 * mm, 24 * mm, 24 * mm, 34 * mm, 34 * mm],
            align_center=[1, 2],
        ),
        sp(5),

        para("Son söz", "h1"),
        para(
            "Bu belgedeki her ölçülmüş sayının arkasında bir düzeltme var, ve düzeltmelerin "
            "çoğu oyunda değil <b>ölçümde</b> yapıldı. Moral kervan sıfırlandıktan sonra "
            "okunuyordu. Erzak, oyuncunun asla stoklamayacağı düz bir miktarla ölçülüyordu. "
            "Kültür ile olay motoru aynı tohumdan türetildiği için bir kültür olayı "
            "sistematik olarak on iki kat nadir görünüyordu. Kariyer probu, gelirin çoğunun "
            "geldiği pazar ticaretini hiç modellemiyordu."
        ),
        sp(2),
        para(
            "Dördü de aynı dersi verdi ve o ders bu codex'in belki de tek taşınabilir "
            "bulgusu: <b>bir rapor şaşırtıyorsa, önce düzeneği şüphelen.</b>"
        ),
        sp(6),
        HRule(),
        sp(3),
        para(
            "Wayborne Codex · sürüm 1 · 2198 doğrulamalık test paketiyle eşzamanlı "
            "olarak hazırlandı.",
            "small",
        ),
    ]
    return f


# ---------------------------------------------------------------- KAPAK
def cover():
    return [
        Spacer(1, 52 * mm),
        para("WAYBORNE", "title"),
        sp(2),
        para("C O D E X", "subtitle"),
        sp(10),
        ColorBar(height=2.4),
        sp(14),
        para(
            "Bir kervan oyununun bütün mekaniklerinin, çalışma prensiplerinin ve "
            "yol olaylarının tam dökümü",
            "subtitle",
        ),
        Spacer(1, 60 * mm),
        table(
            None,
            [
                ["Bölüm sayısı", "8 bölüm + olay ağacı + ek"],
                ["Olay kartı", "27 (2'si zincir)"],
                ["Etki sözlüğü", "25 tip"],
                ["Şehir / rota", "5 şehir · 7 kenar"],
                ["Karakter", "6 stat · 5 kültür · 4 sınıf · 6 görev · 12 huy · 12 ekipman"],
                ["Kampanya", "5 perde, sonu olan hikâye + sonsuz ticaret"],
            ],
            widths=[40 * mm, 114 * mm],
            label_column=True,
        ),
    ]


def toc():
    rows = [
        ("I", "Oyun Nedir", "İki ata, altı tasarım aksiyomu, ana döngü"),
        ("II", "Karakter", "Statlar, kültürler, sınıflar, görevler, huylar, ekipman, seviye"),
        ("III", "Kervan", "Vagonlar, erzak, moral ve stres, kırılma"),
        ("IV", "Şehir", "Beş mekân, pazar fiyatı, pazarlık, kontrat ve borç"),
        ("V", "Yol", "Harita, dinamik rota katmanı, zaman, plan değişikliği"),
        ("VI", "Savaş", "Saha, çözüm sırası, düşman kadroları, ölçekleme"),
        ("VII", "Kampanya", "Beş perde, ölçülen süre, üç bulgu"),
        ("VIII", "Olay Motoru", "Bir günün anatomisi, etki sözlüğü, mizaç"),
        ("—", "Olay Ağacı", "Yirmi yedi kartın tek tek dökümü"),
        ("—", "Ek", "Sayı tabloları"),
    ]
    f = [
        PageBreak(),
        para("İÇİNDEKİLER", "partnum"),
        para("Codex", "part"),
        ColorBar(height=2.6),
        sp(10),
    ]
    data = []
    for num, title, desc in rows:
        data.append([
            Paragraph(f'<font color="#9A7B3F"><b>{num}</b></font>', S["tocp"]),
            Paragraph(f"<b>{title}</b>", S["tocp"]),
            Paragraph(f'<font color="#7A7263">{desc}</font>', S["toc"]),
        ])
    t = Table(data, colWidths=[16 * mm, 40 * mm, 98 * mm])
    t.setStyle(TableStyle([
        ("LEFTPADDING", (0, 0), (-1, -1), 2),
        ("RIGHTPADDING", (0, 0), (-1, -1), 2),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LINEBELOW", (0, 0), (-1, -2), 0.4, RULE),
    ]))
    f.append(t)
    return f


# ---------------------------------------------------------------- ŞABLON
class Doc(BaseDocTemplate):
    def __init__(self, path, **kw):
        BaseDocTemplate.__init__(self, path, pagesize=A4,
                                 leftMargin=MARGIN, rightMargin=MARGIN,
                                 topMargin=MARGIN + 6 * mm, bottomMargin=MARGIN,
                                 title="Wayborne Codex", author="Wayborne")
        frame = Frame(self.leftMargin, self.bottomMargin,
                      self.width, self.height, id="main",
                      leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)
        self.addPageTemplates([
            PageTemplate(id="cover", frames=[frame], onPage=_cover_bg),
            PageTemplate(id="main", frames=[frame], onPage=_page_furniture),
        ])


def _cover_bg(canv, doc):
    canv.saveState()
    canv.setFillColor(PARCH)
    canv.rect(0, 0, PAGE_W, PAGE_H, stroke=0, fill=1)
    canv.setStrokeColor(GOLD)
    canv.setLineWidth(1.2)
    canv.rect(12 * mm, 12 * mm, PAGE_W - 24 * mm, PAGE_H - 24 * mm, stroke=1, fill=0)
    canv.restoreState()


def _page_furniture(canv, doc):
    canv.saveState()
    canv.setFillColor(PARCH)
    canv.rect(0, 0, PAGE_W, PAGE_H, stroke=0, fill=1)
    # üst şerit
    canv.setStrokeColor(RULE)
    canv.setLineWidth(0.5)
    canv.line(MARGIN, PAGE_H - MARGIN - 2 * mm, PAGE_W - MARGIN, PAGE_H - MARGIN - 2 * mm)
    canv.setFont("DJV", 7.4)
    canv.setFillColor(MUTED)
    canv.drawString(MARGIN, PAGE_H - MARGIN + 1.5 * mm, "WAYBORNE CODEX")
    # alt sayfa numarası
    canv.setFont("DJV-B", 8.4)
    canv.setFillColor(GOLD)
    canv.drawCentredString(PAGE_W / 2.0, MARGIN - 6 * mm, str(canv.getPageNumber()))
    canv.restoreState()


def build():
    from reportlab.platypus import NextPageTemplate
    story = []
    story += cover()
    story.append(NextPageTemplate("main"))
    story += toc()
    for chapter in (ch1, ch2, ch3, ch4, ch5, ch6, ch7, ch8_engine):
        story.append(PageBreak())
        story += chapter()
    story += ch8_tree()
    story += appendix()

    doc = Doc(OUT)
    doc.build(story)
    print("YAZILDI:", OUT)


if __name__ == "__main__":
    build()
