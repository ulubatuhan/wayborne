#!/usr/bin/env python3
"""Lore soru defteri (II): harita v3 üstüne kurulmuş, cevapları saklayan tek sayfa.

Defter I (302 soru) bölge sorularıyla cevaplandı; defter II onların işlendiği lore'un onay listesini,
çelişkilerini, kıtlık sorularını, takip sorularını ve I'in kalan sorularını taşır.

Kullanıcının kalan lore ve tarihçeyi yazması için soruları haritadaki gerçek bölgelere,
27 yerleşime ve atlasın adı konmuş yerlerine bağlar. Harita karoları (zoom 1), şehir önü
resimleri (gündüz) ve `settlements.json` ile `places_v3.json` sayfaya gömülür; cevaplar
sayfanın `db` deposuna (`answers/<soru kimliği>`) yazılır, Claude oradan okur.

    python3 -I tools/lore_soru_sayfasi.py <çıktı.html>
"""
import base64
import io
import json
import math
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAP_W = 16012.0
MAP_PX = 1700          # gömülen harita genişliği
THUMB = (360, 203)     # şehir önü küçük resmi

# places_v3 (4096 ölçeği) -> settlements.json (16012): en küçük karelerle ölçüldü, hata 0.
def place_to_map(x, y):
    return 4.0 * x - 186.0, 4.0 * y - 165.0

REGION_K = 1.04 * 2.048   # tools/worldmap/atlas/names/regions.py: ekran -> atlas

REGIONS = {
    "gocebe": "Gokyurt",
    "imparatorluk": "Vaelghard Krallığı",
    "sinir": "Sınır halkları",
    "dag": "Ayazkaya",
    "dag_maden": "Taşkök?",
    "vadi": "Büyük Vadi",
    "ahit": "Orvahel",
    "guney": "Ors ve güney",
}
REGION_POLY_KEYS = {"dag_k": "dag", "dag_ke": "dag", "maden": "dag_maden", "gocebe": "gocebe",
                    "imparatorluk": "imparatorluk", "sinir_d": "sinir", "sinir_b": "sinir", "vadi": "vadi",
                    "ahit": "ahit", "guney_b": "guney", "guney_d": "guney"}
TYPE_LABEL = {"ic_city": "Şehir", "ic_freecity": "Serbest şehir", "ic_portcity": "Liman şehri",
              "it_town": "Kasaba", "it_swamptown": "Bataklık kasabası", "it_minetown": "Maden kasabası",
              "it_rivertown": "Nehir kasabası", "it_markettown": "Pazar kasabası",
              "ik_caravanserai": "Kervansaray"}
WALL_LABEL = {"stone": "taş sur", "wood": "kütük sur", "felt": "sur yok, keçe yurtlar"}
GOODS = {"test_grain": "buğday", "test_cloth": "kumaş", "test_weapon": "demir", "test_potion": "iksir",
         "test_furs": "kürk", "spice": "baharat", "honey": "bal", "silk": "ipek", "jewelry": "mücevher",
         "fish": "balık", "wine": "şarap"}
PLACE_KIND = {"ia_abbey": "Manastır", "ir_ruins": "Harabe", "is_stones": "Dikili taşlar", "ib_battle": "Savaş alanı",
              "ig_gallows": "Darağacı", "ig_graveyard": "Mezarlık", "iw_tower": "Gözcü kulesi",
              "ip_lighthouse": "Fener", "ix_wreck": "Batık", "ix_mountaintribe": "Dağ kabilesi",
              "in_yurtcamp": "Oba", "ie_deepmine": "Derin maden", "ie_saltmine": "Tuzla",
              "iv_fishvillage": "Balıkçı köyü", "iv_farm": "Çiftlik", "ih_mezra": "Mezra", "il_lumber": "Kereste kampı"}


def load_regions():
    src = open(os.path.join(ROOT, "tools/worldmap/atlas/names/regions.py"), encoding="utf-8").read()
    ns = {"math": math}
    exec(src.split("def inside")[0].replace("import json\nimport math\n", ""), ns)
    out = []
    for key, poly in ns["REG"].items():
        pts = []
        for sx, sy in poly:
            mx, my = place_to_map(sx * REGION_K, sy * REGION_K)
            pts.append([round(mx / MAP_W, 4), round(my / MAP_W, 4)])
        out.append({"key": REGION_POLY_KEYS[key], "pts": pts})
    return out


def b64(img, fmt="JPEG", q=78):
    buf = io.BytesIO()
    img.save(buf, fmt, quality=q, optimize=True, progressive=True)
    return base64.b64encode(buf.getvalue()).decode()


def map_image():
    full = Image.new("RGB", (2048, 2048))
    for x in range(2):
        for y in range(2):
            full.paste(Image.open(os.path.join(ROOT, f"data/assets/map/tiles/1/{x}_{y}.jpg")), (x * 1024, y * 1024))
    side = round(2048 * MAP_W / 16384.0)
    return full.crop((0, 0, side, side)).resize((MAP_PX, MAP_PX), Image.LANCZOS)


def town_thumb(sid):
    p = os.path.join(ROOT, "data/assets/ui/towns", sid, "background_day.jpg")
    if not os.path.exists(p):
        return None
    im = Image.open(p).convert("RGB")
    w, h = im.size
    tw, th = THUMB
    s = max(tw / w, th / h)
    im = im.resize((round(w * s), round(h * s)), Image.LANCZOS)
    left = (im.width - tw) // 2
    return b64(im.crop((left, (im.height - th) // 2, left + tw, (im.height - th) // 2 + th)), q=70)


SETTLEMENT_TYPE_Q = {
    "ic_city": "Şehrin kalbi neresi: kale, kilise, lonca, pazar? Ünlü bir aile ya da kişi var mı?",
    "ic_freecity": "Neden 'serbest'? Kimden, ne zaman ve hangi bedelle özgürlüğünü aldı? Kim yönetiyor (konsey, lonca, seçilmiş biri)?",
    "ic_portcity": "Hangi denize açılır, gemileri nereye gider? Rıhtımda kimler var (yabancı tüccar, korsan, büyücü)?",
    "it_town": "Kasabanın geçimi ne ve bugünkü derdi ne?",
    "it_swamptown": "Bataklıkta neden yaşanır? Bataklığın halk arasında anlatılan bir masalı var mı?",
    "it_minetown": "Madende ne çıkar, kimler kazar, kazancı kim alır?",
    "it_rivertown": "Nehrin adı ne? Nehir kasabaya ne getirir, ne alır?",
    "it_markettown": "Bu pazarda başka yerde bulunmayan ne satılır? Pazarın kuralı ne?",
    "ik_caravanserai": "Kim yaptırdı, kim işletir? Kervansarayın kuralı ne (silah, ödeme, sığınma, kavga)?",
}


# ---------------------------------------------------------------- soru bankası (defter II, 2026-10-30)

ONAY = ["Onaylıyorum", "Düzeltilmeli", "Reddediyorum"]


def q(qid, text, hint="", choices=None, at=None, prio=False, draft="", draft_label=""):
    d = {"id": qid, "t": text}
    if hint:
        d["h"] = hint
    if choices:
        d["c"] = choices
    if at:
        d["at"] = at
    if prio:
        d["p"] = 1
    if draft:
        d["d"] = draft
    if draft_label:
        d["dl"] = draft_label
    return d


def onay(no, title, draft, prio=False, at=None):
    return q(f"onay.{no.lower()}", f"{no} · {title}", choices=ONAY, draft=draft, prio=prio, at=at)


ONAY_GROUPS = [
    ("inanc", "İnanç ve kilise", [
        ("T1", "Eski görüşün ve reformcuların adı", "\"Eski Ahit\" yerine İlk Sayfa: El'in yazdığını ilk yazıldığı gibi okuyanlar. Reformcuların adı Yeni Okuma: aynı kitabı yeniden okuyan, sayfanın kenarına not düşmeyi meşru sayanlar. Halk ağzında sembollerinden: \"Açık Avuçlar\" ve \"Yumruklar\".\nGerekçe: inancın dili zaten sayfa ve yazı; başı Birinci Okuyucu; Orvahel'in yanında bir İlk Sayfa Manastırı var. Alternatif çift: Açık El ve Yumruk.", True),
        ("T2", "Orvahel'in kutsal bölgesinin adı", "Avuçiçi: El'in avucunun içi, açık el sembolüyle aynı imge. Diğer adaylar: Okuyucu Toprağı, Sayfa Yurdu.", True),
        ("T3", "V. Leon \"The Pure\" sıfatının Türkçesi", "Lekesiz: El'in yazısını bozmamış, sayfayı kirletmemiş olan."),
        ("T4", "Kilisenin dereceleri", "Birinci Okuyucu > Okuyucular (şehir kiliselerinin başları) > Kâtipler (rahipler: Kitap'ı kopyalar, okutur, arınmayı yürütür) > Çıraklar."),
        ("T6", "Kilise imparatorlukla yayıldı", "El kilisesi imparatorluğun dini oldu ve onun yollarıyla yayıldı; pagan inançları imparatorluk düzeniyle birlikte yuttu."),
        ("T22", "Şamanlar Baikhan'ın tek kurumu", "Kitapları yok; sözle ve sudan okurlar. Sogurtay suyu kutsaldır."),
        ("T21", "Sogurtay buluşması", "Boyların tek ortak zamanı: beyler orada görüşür, kan davaları barışa bağlanır, hanlık iddiaları orada duyulur."),
        ("T20", "Ayazkaya'da hükmün tanınması", "Bir kabile beyinin hükmü Kartalın Nefesi Zirvesi'ne tırmanıp dönmesiyle tanınır: güç sınavı bir dua değil, bir taç giyme."),
        ("T25", "Kervan iki inancın arasında", "Kervan yazan ama yola ait: defter onu kaydeder (El), yol onu sahiplenir (Baikhan). \"Yolda doğan\" iki dünyanın da çocuğu."),
    ]),
    ("yerler", "Haritadaki yerlere hikâye", [
        ("T7", "Dört kuleli tapınak", "Merigard'ın yanmadan kalan tek yapısı; Orvahel onun çevresine kuruldu. Şehir genç, tapınak eski."),
        ("T8", "Mühür Savaşı Ovası", "Büyük savaşın son meydanı. Oyundaki nadir \"eski mühür\" imparatorluğun orada düşen mühürlerinden biri.", False, "Mühür Savaşı Ovası"),
        ("T9", "Kefaret Darağacı", "Avuçiçi'nde inançsızların asıldığı yer.", False, "Kefaret Darağacı"),
        ("T10", "İlk Sayfa Manastırı", "Eski görüşün okulu; Okuyucular orada yetişir.", False, "İlk Sayfa Manastırı"),
        ("T15", "Bölünmüş Sancak Ovası ve Dönek Darağacı", "Tolvarin ile Kirsavel'in bir zamanlar tek sancak altından ayrıldığı yer; Dönek Darağacı iki şehir arasında taraf değiştirenlerin asıldığı yer.", False, "Bölünmüş Sancak Ovası"),
        ("T16", "İki Bayrak Kulesi", "Ezmerak Baronluğu ile Avuçiçi'nin sınırı: bir yanda baronun, öbür yanda Kitap'ın bayrağı.", False, "İki Bayrak Kulesi"),
        ("T17", "Kiralık Kılıçlar Ovası", "Orsolune'nin paralı askerlerinin bir zaman sözleşmeyi bozduğu yer; Orsianlar bunu hiç unutmadı.", False, "Kiralık Kılıçlar Ovası"),
        ("T18", "İlk Nefes Taşları", "Dağlıların Kartalın Nefesi'ne giden sınavının başladığı yer.", False, "İlk Nefes Taşları"),
        ("T27", "Avuçiçi zilleri", "Zil Avuçiçi'ne giden yolların başında satılır: Ezmerak, Vorgat, Seyvan. Zil sesi Orvahel yolunun sesi."),
    ]),
    ("baglar", "Bölgeler arası bağlar", [
        ("T5", "Ortak ticaret dili", "Vadi dili kıtanın ortak ticaret dili. Bir liman insanının \"beş dili\": imparatorluk dili, vadi dili, göçebe dili, dağlıların dili ve deniz ötesinden bir dil."),
        ("T11", "Mühürsüz tuz", "Saldrek'ten (Ayazkaya) gelir. \"Mühürsüz\": Vaelghard'ın ya da baronun vergi mührü yok. Ezmerak'tan yasal girdiğinde mühürlenir; kervansaraylarda mühürsüz satılır."),
        ("T12", "Vaelghard'ın çeliği", "Vaelghard ordusu savaştığı dağlıların Kazrun çeliğini taşır. Bir Vaelghard subayı bunu bilir ama söylemez; bir dağlı bilir ve güler."),
        ("T13", "Tolvarin–Kirsavel kavgasının kökü", "Kirsavel'in kutsal sürüleri otlak arar, Tolvarin'in kutsal toprağı çiğnenmez. Her sınır ihlali iki tarafın kutsalına saygısızlık."),
        ("T14", "Ezmerak'ın düello yasası", "Aldatmayı ölümle cezalandıran yasa, Kanlı Baron'un bir yemekte akrabalarını aldatıp öldürmesinin gölgesi: Daemon babasının yükseldiği yolu herkese kapatarak tahtını korur."),
        ("T19", "Haydut kralları", "Oyundaki haydut kralları (yolu tutup haraç alan güçler) en çok Ayazkaya'nın bedel kültürü: bir kabile bir yolu tutar, bedel kabileye göre değişir."),
        ("T23", "Bereketli ama aç Vadi", "Harita Vadi'yi bereketli, kanon en aç bölge diyor. İkisi birlikte doğru: toprak kıtanın en verimlisi, ama bitmeyen prens savaşları hasadı yakıyor, yolları kesiyor, köylüyü kaçırıyor."),
        ("T24", "Orsian sözleşme ahlakı", "Lonca Orsolune'ye taşınınca bu ahlak kıtanın ticaret kuralı oldu: kontrat cezası, borç ve itibar onun oyundaki yüzü."),
        ("T28", "Çember içindeki Vaelghard", "Batıda göçebeler, kuzeyde ve doğuda dağlılar, güneyde borçlu olduğu güney. Kıtanın en güçlü ordusu hiçbir cephede kazanamıyor."),
        ("T29", "\"Çadıreli\" kimin ağzı", "Vaelghard'ın: kayıt bürosunda adı olmayan, vergi vermeyen halka verilmiş ad."),
        ("T30", "\"İki beyliğin savaşı\"", "Oyunun haber kartlarındaki bu savaş en çok Tolvarin ile Kirsavel'in savaşı."),
        ("T26", "İmparatorluk ne zaman çöktü", "Alex imparatorluk ordusunda hizmet etti, döndü, hüküm sürdü, genç öldü; oğlu bugün hüküm sürüyor. Çöküş 30-50 yıl önce: yaşayanların hafızasında. NPC'ler \"babamın zamanı\", \"dedemin zamanı\" der."),
    ]),
]


def place_at(places, name, zoom=3.2):
    for p in places:
        if p["d"] == name:
            mx, my = place_to_map(p["x"], p["y"])
            return [round(mx / MAP_W, 4), round(my / MAP_W, 4), zoom]
    return None


def settlement_at(settlements, sid, zoom=3.2):
    for s in settlements:
        if s["id"] == sid:
            return [round(s["pos"][0] / MAP_W, 4), round(s["pos"][1] / MAP_W, 4), zoom]
    return None


KNOWN = {
    "vastrevar": "Vaelghard'ın başkenti, Kral Reynald. İmparatorluğun en büyük kentlerinden biriydi.",
    "auderin": "Vaelghard. Kıtanın en kuzeyi; kuzey kasaba yolları kışın kapanır, yalnızca atla gidilir.",
    "dravoss": "Vaelghard şehri.",
    "selvicar": "Vaelghard kasabası, Gokyurt sınırında (göçebe baskınları).",
    "rivecande": "Vaelghard limanı. Kesgrav yolu dağlıların koruduğu yol.",
    "serai_orbeyan": "Gokyurt'un ticaret kapısı; yalnızca göçebelerin izin verdiği tüccarlar gelir; göçebe kültüründen, bütün boylarla bağı olan biri işletir.",
    "tolvarin": "Bağımsız; Leon Bey. Toprak kutsal; tarım ve işçilik inancı. Kirsavel ile kavgalı.",
    "kirsavel": "Bağımsız; Vasko Bey. Hayvanlar kutsal; göçebe inancına benzer eski inanç; göçebe dili de konuşulur.",
    "akavan": "Ondrelle'e bağlı.",
    "samuran": "Liraven'e bağlı.",
    "ezmerak": "Ezmerak Baronluğu, Baron Daemon. Geçen kervan en az bir öküz değerinde ticaret yapar; aldatma düello sebebi. Bazı Vadi şehirleri ona borçlu.",
    "golcavar": "Ezmerak Baronluğu.",
    "brazdun": "Ayazkaya maden kasabası.",
    "kesgrav": "Ayazkaya maden kasabası; Rivecande yolunu dağlılar korur.",
    "vorgat": "Cevaba göre Taşkök'ün (haritadaki yeri çelişki Ç1).",
    "merigaud": "Prenslik; mikro milliyetçi, eski görüş. İmparatorlukta loncanın merkeziydi. Ondrelle ve Belvanor ile savaşta.",
    "ondrelle": "Prenslik; mikro milliyetçi, eski görüş. Akavan ona bağlı. Merigaud ve Belvanor ile savaşta.",
    "belvanor": "Prenslik; seküler, reformcu. Caramine ile anlaşmalı; Merigaud ve Ondrelle ile savaşta.",
    "ilsande": "Prenslik; seküler, reformcu; standart ipek. Caramine ile savaşta.",
    "caramine": "Prenslik; seküler, reformcu. Belvanor ile anlaşmalı, Ilsande ile savaşta.",
    "liraven": "Vadi prensliği; Samuran ona bağlı.",
    "serai_duvenmor": "Vadi; standart ipek.",
    "orvahel": "El kilisesinin baş şehri, Birinci Okuyucu V. Leon. Zil kuralı; inançsız tüccar kapıda satar. Dört kuleli tapınak. Merigard'ın yerinde, Vaelghard kurdu.",
    "orsolune": "Ors'un tek büyük şehri, Orsolune Konseyi. Loncanın merkezi; Raviellon gemileri buradan kalkar.",
    "serai_seyvan": "Orsolune'ye bağlı.",
    "zelmarin": "Bağımsız, konseyle yönetilir; eski görüş ağır ama karışık; Orsolune ile ticaret anlaşması; Raviellon gemileri.",
    "mirsana": "Bağımsız ticaret şehir devleti; reformcu ve eski inanç karışık.",
}

SETTLEMENT_EXTRA = {
    "auderin": q("yer.auderin.x", "Auderin kıtanın en kuzeydeki yerleşimi. Daima karlı kuzeyin kıyısında yaşamak nasıl bir şey, ötesinde ne olduğuna inanılır?"),
    "orsolune": q("yer.orsolune.x", "Kuzeyden gelen bir kervan için Orsolune neyi temsil eder (yolun sonu, denizin kapısı, borcun sahibi)?"),
    "ezmerak": q("yer.ezmerak.x", "Ezmerak iç kaleli. Kale kimi kime karşı koruyor? Kanlı Baron'un yemeği hangi salonda oldu, o salon bugün ne?"),
    "rivecande": q("yer.rivecande.x", "Rivecande kuzeyin limanı; büyük iç suyun kıyısında. Bu su açık denize bağlı mı, gemiler nereye gider?", at=[0.62, 0.36, 3]),
    "serai_seyvan": q("yer.seyvan.x", "Seyvan altı yolun kavşağında ve Orsolune'ye bağlı. Avuçiçi'ne giden hacılar burada mı zil alır?"),
    "serai_duvenmor": q("yer.duvenmor.x", "Duvenmor Vadi'nin kuzey kapısında, savaşan prensliklerin arasında. Kimin? Savaşta tarafsız mı?"),
    "mirsana": q("yer.mirsana.x", "Mirsana baharat satıyor. Baharat ona denizden mi, başka bir yoldan mı geliyor?"),
    "serai_orbeyan": q("yer.orbeyan.x", "Orbeyan'ı işleten kişinin adı ve hikâyesi. Göçebe izni nasıl alınır (bir mühür, bir eşya, bir söz)?", prio=True),
    "vastrevar": q("yer.vastrevar.x", "Vastrevar'da kral sarayı, kilise ve sınır bürosunun merkezi: şehrin kalbi hangisi? Reynald'ın hanedanının adı?"),
    "orvahel": q("yer.orvahel.x", "Orvahel'e kervan geldiğinde ilk gördüğü ne: kapı, zil satıcısı, darağacı, tapınağın kuleleri?"),
}

PLACE_Q = {
    "Deli Kral Sarayı Yıkıntısı": ("Deli kral kimdi, sarayı neden burada ve neden yıkıntı? Halk buraya yaklaşır mı?", True),
    "Eski Darphane Yıkıntısı": ("Burada kim, hangi parayı bastı? GG'nin kökeni burası mı?", True),
    "Gelgit Taşları": ("Denizin İlk Gözyaşı ile ilgili mi? Güneydoğu kıyısındaki bu taşlarda ne yapılır?", False),
    "Yıldızölçer Taşları": ("Gökyüzünü ölçen taşlar. Kim dikti: kadim uygarlık mı, eski inançlar mı? Takvimle ilgisi var mı?", False),
    "Altıkuşak Taşları": ("Altı kuşak kimin altı kuşağı? Batı kıyısındaki bu taşların hikâyesi?", False),
    "Bahçıvan Taşları": ("Bahçıvan kim? Taşların çevresinde ne yetişir? Kıtlıkta burası hâlâ yeşil mi?", False),
    "Sessiz El Manastırı": ("Adı El'i anıyor. Kim yaşar, neden sessiz (yemin, ceza, ölüm)? İlk Sayfa'nın mı Yeni Okuma'nın mı?", True),
    "Açık Kapı Manastırı": ("Kapısı kime açık: yolculara mı, kaçaklara mı, açlara mı? Şifahane burası olabilir mi?", False),
    "Yamalı Çatı Manastırı": ("Yoksul bir manastır mı, yıkılıp yeniden yapılan mı? Bekçi Kadın'la ilgisi?", False),
    "Taşsoluk Manastırı": ("Taşın soluğu: Dağın İlk Nefesi'nden kilisenin devraldığı bir yer mi?", False),
    "Kırık Mızrak Çayırı": ("Hangi savaş, kimler arasında, kim kazandı?", False),
    "Kızıl Ferman Darağacı": ("Kimin fermanı, kim asıldı?", False),
    "Sarmaşıklı Darağacı": ("Artık kullanılmıyor mu? Neden sarmaşık bürüdü?", False),
    "Kuru Halat Darağacı": ("Bu darağacının bir hikâyesi?", False),
    "Yabancılar Mezarlığı": ("Kimler 'yabancı' sayılıp buraya gömülür? Yolda ölenlerin işaretsiz mezarı kuralıyla ilişkisi?", True),
    "Sancaksız Mezarlık": ("Sancaksız ölenler kim: bayraksız askerler, kaçaklar, haydutlar, büyük savaşın kimsesizleri?", False),
    "Kör Kazmalar Mezarlığı": ("Madencilerin mezarlığı mı? Neden 'kör'?", False),
    "Leylak Mezarlığı": ("Bu mezarlığın hikâyesi?", False),
    "Tuzlu Çardak Mezarlığı": ("Kıyıda, denizde ölenlerin mezarlığı mı?", False),
    "Tozkapı Yıkıntısı": ("Hangi çağdan: kadim uygarlık, eski inançlar, imparatorluk? Neyin kapısıydı?", False),
    "Velkrun Yıkıntısı": ("Hangi çağdan? Daima karlı kuzeyin ucunda neden bir yapı vardı?", False),
    "Sargalak Yıkıntısı": ("Hangi çağdan? Gokyurt'un ortasında kim yaşadı?", False),
    "Solgun Bahçe Yıkıntısı": ("Bir zamanlar bir bahçe mi, bir saray mı? Neden solgun? Kıtlıkla bir ilgisi var mı?", True),
    "Hallecort Yıkıntısı": ("Hangi çağdan? Kim terk etti?", False),
    "Sessiz Kadırga Batığı": ("Hangi gemi, nereden geliyordu? Sessiz kalmasının sebebi?", False),
    "Kanlı Direk Batığı": ("Korsan mı, savaş gemisi mi? Batığın masalı?", False),
    "Öksüz Göz Kulesi": ("Neden öksüz? Kimse nöbet tutmuyor mu?", False),
    "Grauth Feneri": ("Kuzeyin en ucundaki fener. Kime yol gösterir, kim yakar?", False),
}


def build_questions(settlements, places, region_names):
    secs = []
    at_p = lambda name, z=3.2: place_at(places, name, z)
    at_s = lambda sid, z=3.2: settlement_at(settlements, sid, z)

    # 1. Onay bekleyenler
    items = []
    for key, title, rows in ONAY_GROUPS:
        qs = []
        for row in rows:
            no, t, d = row[0], row[1], row[2]
            prio = len(row) > 3 and row[3] is True
            place = row[4] if len(row) > 4 else None
            qs.append(onay(no, t, d, prio=prio, at=at_p(place) if place else None))
        items.append({"kind": "plain", "key": key, "title": title, "qs": qs})
    secs.append({"id": "onay", "title": "Onay bekleyenler",
                 "lead": "Cevaplarından kurduğum bağlar ve senin istediğin ad önerileri. Her biri lore belgesinde numarasıyla işaretli; onaylanan kanona geçer, düzeltmeni yazarsan ona göre değiştiririm, reddedilen silinir.",
                 "items": items})

    # 2. Kıtlık
    kit = [
        q("kitlik.sebep", "Kıtlığı ne başlattı?", prio=True,
          choices=["Uzayan kış (a)", "Solgunluk (b)", "İkisi: mevsimleri büyü değiştirdi", "Başka"],
          draft="(a) Uzayan kış: kış kuzeydoğudan gelir; bir zamandır her yıl biraz daha erken gelip biraz daha geç gidiyor. Kuzeydoğu buzulları ilerliyor, buzdaki eski yaratıklar ışığa yaklaşıyor. Yazlar kısalınca hasat yetişmiyor, otlak erken kuruyor; obalar güneybatıya her yıl daha erken göçüyor, Vaelghard'ın kuzey yolları daha uzun kapalı kalıyor.\n(b) Solgunluk: büyülü bir olay toprağın yaşam enerjisini çekiyor. Ekin büyüyor ama başakta tane yok, hayvan doğuruyor ama yavru zayıf. Kadim uygarlığı bitiren güçle aynı aileden: biri yeniden uyandırdı ya da hiç bitmedi. Öbürkülerin yoğun olduğu yerlerde ağır.\nHer iki durumda da herkes başka okur: kilise El'in sayfayı kapattığını, şamanlar doğaya saygısızlığı, Orsianlar fiyat eğrisini, dağlılar dağın nefesini tuttuğunu söyler.",
          draft_label="Önerim (T31)"),
        q("kitlik.zaman", "Kıtlık ne zaman başladı?", prio=True,
          choices=["İmparatorluğun son yıllarında, hâlâ sürüyor", "Çöküşten sonra, son on yıllarda", "Birkaç yıl önce", "Başka"],
          draft="İmparatorluğun son yıllarında başladı ve sürüyor. Büyük savaş ilk kıtlık savaşıydı: otlağı kuruyan obalar Han'ın çağrısına bu yüzden uydu; imparatorluk aç şehirlerini besleyemediği için dağıldı. Bugünkü Vadi savaşları, dağlı yağmaları ve göçebe akınları aynı açlığın devamı.",
          draft_label="Önerim (T32)"),
        onay("T33", "Deli kral ve kıtlık", "Deli kral kıtlığı büyücülere yükleyip onları katletti. Tarih kitapları ona \"deli\" der; o gün aç halk ona alkış tuttu. Kıtlık büyüyle geldiyse onu anlayabilecek tek insanlar böylece gitti."),
        onay("T34", "Kıtlıkta kim ne ister", "Orvahel gıda, kâğıt, tekstil ister; Vadi buğday üretir ama savaş yüzünden aç kalır; Vaelghard güneye borçlanarak beslenir; Orsolune kıtlıkta borç verip zenginleşir. Orsian ahlakı (dolandırma, ama kitaptaki açığı kullan) en çok burada sınanır."),
        q("kitlik.seyir", "Oyun boyunca kıtlık nasıl değişsin?",
          choices=["Sabit bir zemin", "Mevsimle dalgalanır", "Yavaşça kötüleşir", "Bir gün bitebilir (bir son)", "Başka"]),
        q("kitlik.ad", "Kıtlığa halklar ne ad veriyor? Her kültür başka okur (kilise, şaman, Orsian, dağlı).",
          hint="Örnek biçim: Vaelghard'da resmî bir ad, Gokyurt'ta bir doğa sözcüğü, Ors'ta bir muhasebe deyimi."),
        q("kitlik.moral", "Şehirlerin arka planda tuttuğu hâl kaç eksenli olsun?",
          choices=["Tek değer (umut ya da çaresizlik)", "İki: açlık ve öfke", "Üç: açlık, öfke, inanç", "Başka"],
          draft="Kervanın ulaştırdığı yük bu değeri düzeltir; değer şehirdeki olayları (isyan, veba, yağma, bayram), kapıdaki karşılamayı, fiyatları, işe alınabilecek insanları ve şehrin kervana yaklaşımını değiştirir. Bölgesel itibarla (görev Y-C12) birlikte: itibar şehrin kervan hakkında ne düşündüğü, hâl şehrin kendi durumu.",
          draft_label="Görev notu (Y-C21)"),
        q("kitlik.ticaret", "Ticaret ne kadar sınırlansın?",
          choices=["Pazarda az mal ve yüksek fiyat", "Satıcılar gıdayı satmak istemez", "Bazı mallar hiç bulunmaz", "Hepsi, şehrin hâline göre", "Başka"],
          draft="Sistemler kesilmez (derinleşme, asla sadeleştirme): ticaret kalır ama kıt ve pahalı. \"Ticaret bilgi oyunudur\" sütunu kıtlıkta: nerede ne kaldığını bilmek.",
          draft_label="Görev notu (Y-C21)"),
        q("kitlik.his", "Kıtlığı en çok hangi anlar hissettirmeli? (yol kenarında açlar, boş pazar tezgâhı, kapıda yalvaran çocuk, kervandan yük çalınması, sofrada ne olduğu...)"),
        q("kitlik.odul", "Üç konuşmadan çıkan derslerden biri 'güçlenme ve ödül mekaniklerini kaldırmak' diyor. Senin ilken 'derinleşme, asla sadeleştirme'. Hangisi?", prio=True,
          choices=["Güç ve ödül kalsın ama her biri bedelli olsun", "Bazı ödül sistemleri gerçekten kalksın (hangileri, yaz)", "Başka"],
          draft="Önerim: seviye, ekipman, yetkinlik ve kazanılan vagonlar silinmez; her güçlenmenin yanına bir ağırlık eklenir (vagon ağız getirir, ün haraç ister, dolu kese haydut çeker). Ayrıntı: docs/design_notes/kitlik_tasarim_dersleri.md.",
          draft_label="Önerim (Y-C22)"),
        q("kitlik.kampanya", "Kampanya bölümlerinin metinleri ticaret dilinde (\"dolu bir kese\", \"para kazandırır\"). Ulaştırma ve hayatta kalma diline çevrilsin mi?",
          choices=["Evet, kıtlık diline çevrilsin", "Kalsın", "Başka"]),
    ]
    secs.append({"id": "kitlik", "title": "Kıtlık", "lead": "29 Ekim notunun lore yanı: kıtlığın sebebi, zamanı ve oyunda nasıl hissedileceği. Mekanik iş görev Y-C21'de; buradaki cevaplar onun girdisi.",
                 "items": [{"kind": "plain", "key": "kitlik", "title": "Kıtayı saran kıtlık", "qs": kit}]})

    # 3. Çelişkiler
    con = [
        q("cel2.taskok", "Ç1 · Taşkök haritada nerede? Cevabında Harvek, Zurek ve Vorgat Taşkök'ün, \"kuzeybatıdaki barışçıl dağ/orman beylikleri\". Haritada Harvek ve Zurek kuzeybatı dağlarında, Vorgat ve gri \"dağ ve maden\" bölgesi doğu sıradağında, kıtanın öbür ucunda.",
          choices=["Taşkök kuzeybatıda; Vorgat başka bölgeye geçer", "Taşkök doğu sıradağında; Harvek ve Zurek oraya taşınır", "Taşkök iki parçalı", "Başka"], prio=True, at=at_p("Harvek", 2.2),
          hint="'Haritada göster' Harvek'e götürür. Vorgat güneydoğuda, Orsolune'nin kuzeydoğusunda."),
        q("cel2.ayazkaya", "Ç2 · Ayazkaya'nın kuzeybatı kolu: Taşkök kuzeybatıdaysa oradaki Kovrast ve Kemersal kabileleri kimin?",
          choices=["Ayazkaya'nın kuzeybatı kolu (Taşkök'ün komşusu)", "Taşkök'ün beylikleri", "Başka"], at=at_p("Kovrast", 2.6)),
        q("cel2.merigard", "Ç3 · İmparatorluğun başkenti Merigard ile Vadi şehri Merigaud neredeyse aynı ad.",
          choices=["Eski başkentin adı değişsin", "Merigaud'nun adı değişsin", "İkisi kalsın: Merigaud adını eski başkentten almış", "Başka"], prio=True,
          draft="Eski başkent için aday adlar: Aldamere, Kaelvaris, Sorvanthe. Üçüncü seçenekte bağ şöyle olur: Merigaud imparatorlukta loncanın merkeziydi ve başkentin \"küçük kardeşi\" diye anılırdı; mikro milliyetçiliği o mirası sahiplenmekten gelir.",
          draft_label="Önerim"),
        q("cel2.adlar", "Ç4 · Bazı adlar gerçek tarihten ya da başka eserlerden tanıdık: Vlad ve Reynald (tarihî), Daemon (başka bir fantastik eser), Alex (gündelik). Leon iki kişide (Tolvarin'in beyi ve Birinci Okuyucu). Ad kuralı uydurma ad istiyor.",
          choices=["Hepsine yeni ad öner", "Yalnızca tanıdık olanlar değişsin", "Yalnızca iki Leon ayrışsın", "Kalsınlar", "Başka"], prio=True,
          draft="Aday adlar (aynı bölgenin dil tadında):\n- Vlad → Valdric, Vorlath\n- Alex (Kanlı Baron) → Aldemar, Askel\n- Daemon → Daveric, Demaris\n- Reynald → Raegmund, Rhaedric\n- Tolvarin'in Leon Bey'i → Levent Bey ya da Lenart Bey (Birinci Okuyucu V. Leon kalır)",
          draft_label="Önerim"),
        q("cel2.orvahel", "Ç5 · Orvahel kanonda gıda, kâğıt ve tekstil istiyor; oyunda iksir ve kumaş üretip şarap, bal ve mücevher istiyor. Oyunda kâğıt diye bir mal yok.",
          choices=["Veri kanona uysun (kâğıt yeni mal olsun)", "İkisi birleşsin", "Başka"],
          draft="Birleşik öneri: Orvahel iksir üretir (manastır şifahaneleri), kumaşı değil. Gıda, kâğıt (Kitap kopyalanır), kumaş ve bal ister. Şarap ve mücevher düşer: Kitap taşıyan bir kentin lüksü değil.",
          draft_label="Önerim"),
        q("cel2.baharat", "Ç6 · Orbeyan oyunda baharat üretiyor; kanonda baharat denizden liman kentlerine gelir.",
          choices=["Orbeyan'dan baharatı kaldır", "Bozkırın kendi baharı (kekik, kuru ot)", "Kara yoluyla uzaktan gelir", "Başka"]),
        q("cel2.tolvarin", "Ç7 · Tolvarin oyunda taş surlu; kanonda batı sınırı yoksulluktan kütük surlu.",
          choices=["Tolvarin kütük olsun", "Şehir olduğu için taş kalsın, kasabalar kütük", "Başka"], at=at_s("tolvarin")),
        q("cel2.gocebebaslangic", "Ç8 · Göçebe kültürü Selvicar ve Vastrevar'da (Vaelghard, düşman) başlayabiliyor.",
          choices=["Orbeyan ve Kirsavel olsun", "Kalsın (sürgün ya da tutsak göçebe)", "Başka"]),
        q("cel2.sunak", "Ç9 · Kanonda yol sunakları çok nadir ve yalnızca Vadi'nin dış kıyılarında ve köy yollarında; oyunda haritanın her yerinde 10 sunak durağı var.",
          choices=["Sayı ve yer kanona uysun", "Kalsın", "Başka"]),
        q("cel2.ezmerak", "Ç10 · Kanon: Ezmerak'tan geçmeden kuzeye yol yok. Oyunun yol ağında Vadi'den kuzeye batıdan da (Duvenmor, Akavan, Tolvarin, Orbeyan, Selvicar) gidiliyor.",
          choices=["Kural yalnızca doğu yolu için", "Yol ağı değişsin", "Başka"], at=at_s("ezmerak", 2.4)),
        q("cel2.akavan", "Ç11 · Akavan ve Samuran kanonda Ondrelle ve Liraven'e bağlı; oyunda bölgeleri \"sınır\", surları kütük.",
          choices=["Bölgeleri Vadi olsun", "Haritadaki bölge kalsın, bağlılık siyasi", "Başka"]),
        q("cel2.balikci", "Ç12 · Balıkçı Kasabası kültürünün başlangıç yerleri arasında dağdaki maden kasabası Brazdun var. Balıkçıların yurdu neresi?",
          choices=["Vaelghard'ın göl kıyısı (Rivecande, Dravoss)", "Bataklık kasabaları (Golcavar, Samuran, Liraven)", "Güney kıyısı", "Başka"]),
        q("cel.kultur", "Haritada sekiz bölge var, oyunda beş oynanabilir kültür. Ne yapalım?",
          choices=["Beş kalsın, diğerleri yalnızca NPC", "Vaelghard ve Ors da oynanabilir olsun", "Her bölge oynanabilir olsun", "Başka"], prio=True),
        q("cel.esleme", "Oynanabilir beş kültür hangi bölgelerin halkı?",
          draft="Bildiğimiz: Göçebe Boyları = Gokyurt; Vadi Loncaları = Büyük Vadi; Dağ Kabilesi = Ayazkaya (\"geçitleri koruyan\" birebir). Açık: Liman Şehri Orsolune mi Zelmarin mi; Balıkçı Kasabası Ç12.",
          draft_label="Bildiğimiz"),
        q("cel.deniz", "'Denizin İlk Gözyaşı' efsanesi kimin?",
          choices=["Balıkçıların", "Güney limanlarının", "Bütün kıyı halklarının", "Başka"]),
        q("cel.nefes", "Dağın İlk Nefesi küçük bir inanış ama kilise ekranında Denizin İlk Gözyaşı ile eşit okutuluyor. Metin değişsin mi?",
          choices=["Değişsin, Nefes daha kısa ve ikinci planda", "Kalsın, kilise ikisini de 'El'in sayfası' diye eşit okutur", "Başka"]),
        q("cel.yoldadogan", "'Yolda doğan' ana karakter kuşak sisteminde kim?",
          choices=["Kurucu (baba)", "İlk lider (oyuncunun ilk karakteri)", "Her lider", "Kervanın adının kendisi", "Başka"], prio=True),
        q("cel.isaret", "'İşaretsiz Mezar' kartında 'bir işaret koy' seçeneği var. Yolda ölenin mezarına ad konmaz. Taş yığmak saygı mı, kural ihlali mi?",
          choices=["Taş yığmak saygı, ad yazmak ihlal", "Her işaret ihlal; seçenek kalksın", "Başka"]),
    ]
    secs.append({"id": "celiskiler", "title": "Çelişkiler", "lead": "İki kaynağın tutmadığı yerler. Seçenek işaretlemek yeter; istersen gerekçe yaz.",
                 "items": [{"kind": "plain", "key": "celiskiler", "title": "Karar bekleyenler", "qs": con}]})

    # 4. Takip soruları
    fol = [
        q("takip.han", "Büyük Han'ın adı ve kişiliği.", prio=True),
        q("takip.sogurtay", "Sogurtay şamanları: adları, ritüelleri, Baikhan ile Gokana'yla ilişkileri. Suyun tadına varmak neyi ölçer?"),
        q("takip.eskiinanc", "Tolvarin'in toprak inancının ve Kirsavel'in hayvan inancının adları; tanrıları ya da kutsal varlıkları var mı?"),
        q("takip.reform", "Reformcular nasıl doğdu, önderleri kim, bir başları var mı? Yumruk neyi anlatıyor?", prio=True),
        q("takip.okuyucu", "Birinci Okuyucu nasıl seçilir? \"V. Leon\": önceki dört Leon kimdi?"),
        q("takip.hanedan", "Vaelghard'ın kraliyet hanedanının adı; Reynald'ın ailesi, varisi."),
        q("takip.konsey", "Orsolune Konseyi kaç kişi, nasıl oluşur, başında biri var mı? Zelmarin'in konseyi ve Mirsana'yı kim yönetiyor?"),
        q("takip.diller", "Dağlıların, Taşkök'ün ve Orsianların dilleri: ayrı diller mi, vadi dilinin lehçeleri mi?"),
        q("takip.imparatorluk", "İmparatorluğun adı ve imparatorun unvanı.", prio=True),
        q("takip.merigard", "Merigard'ı kim yaktı?", choices=["Göçebe orduları", "Kendi halkı (isyan, açlık)", "Kuzeyin (bugünkü Vaelghard'ın) orduları", "Bilinmiyor, herkes başkasını suçluyor", "Başka"], prio=True),
        q("takip.delikral", "Deli kral imparator muydu, bir krallığın kralı mı? Katliam çöküşten ne kadar önce?", prio=True),
        q("takip.ayazkayasavas", "Ayazkaya'nın Vaelghard'la savaşı ne zaman ve neden başladı?"),
        q("takip.kartal", "Kartalın Nefesi Zirvesi haritada tam nerede? (Ulmarec ile Droskal arası)", at=at_p("Droskal", 2.6)),
        q("takip.liman", "Liman Şehri kültürü Orsolune mi, Zelmarin mi, ikisi mi?", choices=["Orsolune", "Zelmarin", "İkisi", "Başka"]),
        q("takip.zil", "Avuçiçi'nin zili nasıl bir zil: kim satar, nasıl ses çıkarır, inanmayan da takabilir mi?"),
        q("takip.kapi", "İlk Sayfa'dan olmayan bir kervan Orvahel'e gelince ne olur? Yeni Okuma'dan biri de \"inançsız\" sayılır mı?",
          choices=["Evet, yalnızca İlk Sayfa girer", "Yeni Okuma girer, öbürleri giremez", "Başka"], prio=True),
        q("takip.mülteci", "Savaş mültecileri en çok nereden kaçıyor (Vadi savaşları, göçebe akınları, dağ yağmaları)? Bir mülteci kampı ya da köyü haritada olsun mu?"),
        q("takip.altin", "Ezmerak'ın \"öküz değerinde ticaret\" kuralı: kim denetler, uymayan kervana ne olur?"),
    ]
    secs.append({"id": "takip", "title": "Takip soruları", "lead": "Bölge cevaplarının açtığı yeni sorular: adı verilmemiş kişiler, kurumların içi, tarihin eksik halkaları.",
                 "items": [{"kind": "plain", "key": "takip", "title": "Takip", "qs": fol}]})

    # 5. Yerleşimler
    items = []
    order = ["imparatorluk", "gocebe", "sinir", "dag", "dag_maden", "vadi", "ahit", "guney"]
    for s in sorted(settlements, key=lambda s: (order.index(s["region"]), s["pos"][1])):
        sid = s["id"]
        qs = [
            q(f"yer.{sid}.kimlik", f"Tek cümleyle: Sideria'da '{s['proper_name']}' denince akla ilk ne gelir?", prio=True,
              draft=KNOWN.get(sid, ""), draft_label="Bildiğimiz"),
            q(f"yer.{sid}.tur", SETTLEMENT_TYPE_Q[s["map_kind"]]),
            q(f"yer.{sid}.gelenek", "Bir yerel gelenek, bir yasak ya da halkın anlattığı bir hikâye."),
            q(f"yer.{sid}.kitlik", "Kıtlık bu yerde nasıl görünüyor? Ne eksik, ne bol, kime kızılıyor?"),
        ]
        if sid in SETTLEMENT_EXTRA:
            qs.insert(1, SETTLEMENT_EXTRA[sid])
        items.append({"kind": "settlement", "key": sid, "title": s["proper_name"], "qs": qs})
    secs.append({"id": "yerlesimler", "title": "Yerleşimler", "lead": "Oyundaki 27 yerleşim. Yönetimleri bölge cevaplarından çıktı, kartın üstünde 'Bildiğimiz' kutusunda. Resim oyundaki şehir önü görüntüsü (gündüz).", "items": items})

    # 6. Adı konmuş yerler
    items = []
    by_name = {p["d"]: p for p in places}
    for name, (text, prio) in PLACE_Q.items():
        p = by_name[name]
        mx, my = place_to_map(p["x"], p["y"])
        slug = "".join(ch for ch in name.lower().replace("ı", "i").replace("ş", "s").replace("ğ", "g").replace("ü", "u")
                       .replace("ö", "o").replace("ç", "c").replace("i̇", "i") if ch.isalnum())
        items.append({"kind": "place", "key": slug, "title": name, "sub": PLACE_KIND.get(p["k"], ""),
                      "pos": [round(mx / MAP_W, 4), round(my / MAP_W, 4)],
                      "qs": [q(f"iz.{slug}", text, prio=prio)]})
    group = {
        "Balıkçı köyleri, obalar, mezralar, çiftlikler": "Haritada adı olan her yer oynanabilir olacak. Bu küçük yerlerden hikâyesi olmasını istediğin var mı? Adını ve hikâyesini yaz.",
        "Kalan fener ve kuleler": "Yalaz ve Yaşlı Martı fenerleri; Kıyıgözü, Geribakan, Sentinara, Ferrant, Vardas kuleleri. Herhangi birinin hikâyesi?",
    }
    for i, (title, text) in enumerate(group.items()):
        items.append({"kind": "group", "key": f"grup{i}", "title": title, "qs": [q(f"iz.grup{i}", text)]})
    secs.append({"id": "izler", "title": "Adı konmuş yerler", "lead": "Atlasta adı var, hikâyesi yok. Hikâyesini önerdiklerim 'Onay bekleyenler'de; burada kalanlar.", "items": items})

    # 7. Coğrafya
    geo = [
        q("cog.denizler", "Kıtayı saran denizlerin adları. Batı denizi, kuzeydeki koylar, doğu denizi ve güneydoğudaki boğaz tek bir deniz mi, ayrı denizler mi?", prio=True, at=[0.5, 0.5, 1]),
        q("cog.guneydogu", "Güneydoğudaki boğazın ötesindeki kara nedir?",
          choices=["Sideria'nın kopmuş bir parçası", "Raviellon", "İki büyük kıtadan birinin ucu", "Başka"], at=[0.93, 0.95, 3], prio=True),
        q("cog.icsu", "Kıtanın ortasındaki büyük iç sular (Rivecande ile Dravoss arası): tuzlu mu tatlı mı, adları ne? Vaelghard'ın gölleri bunlar mı?", at=[0.55, 0.38, 2.4]),
        q("cog.sirt", "Doğuyu kuzeyden güneye kesen büyük sıradağın adı ne? Ors sıradağları onun güney ucu mu?", at=[0.8, 0.55, 1.8], prio=True),
        q("cog.kuzeybati", "Kuzeybatının karlı dağlarının adı ne?", at=[0.12, 0.05, 3]),
        q("cog.ormanlar", "Büyük ormanların adları: Taşkök'ün ünlü odunları hangi ormandan, binlerce yıllık ağaçlar hangisinde?", at=[0.6, 0.78, 2]),
        q("cog.nehirler", "Ana nehirlerin adları ve kaynakları? Vorgat'ın nehri?"),
        q("cog.adalar", "Kuzeydoğu ve doğu kıyısındaki küçük adalar: 'güney tüccarlarının bildiği adalar' bunlar mı? Kimse yaşıyor mu?", at=[0.93, 0.3, 2.6]),
        q("cog.bataklik", "Bataklık kasabaları üç yerde (Samuran, Liraven, Golcavar). Bataklıkların halk arasındaki adı ve masalı? Ezmerak'ın sulak tarımı bunlardan mı?"),
        q("cog.issiz", "Haritada ıssız bırakılmış, yerleşimsiz bölgeler var mı? Halk oralara neden gitmez?", hint="Öbürkülerin 'orada bir şey var' denilen yerleri olabilir."),
        q("cog.buzul", "Buzullar ve içlerindeki yaratıklar haritada nerede belirgin olsun? Bir buzul kapısı, bir donmuş vadi adı?"),
    ]
    secs.append({"id": "cografya", "title": "Su, dağ, orman", "lead": "Haritada çizili ama adı konmamış büyük yapılar. 'Haritada göster' ilgili yere götürür.",
                 "items": [{"kind": "plain", "key": "cografya", "title": "Coğrafya", "qs": geo}]})

    # 8. Bugün
    now = [
        q("bugun.el", "The Hand (El) ne?", choices=["Tanrının kendisi", "Tanrının bir sıfatı", "Adı bilinmeyen tanrının eli", "Başka"], prio=True),
        q("bugun.bekci", "Bekçi Kadın'ın iki inançtaki adları ('yolcu' anlamına gelen).", prio=True),
        q("bugun.baikhan", "Baikhan ve Gokana: inancın adı mı, varlıklar mı, yerler mi?",
          choices=["Baikhan gök, Gokana toprak", "Baikhan yol/inanç, Gokana ölülerin yeri", "İkisi de varlık", "Başka"], prio=True),
        q("bugun.lonca", "Tüccar Loncası kime bağlı? Kilise ve krallarla ilişkisi, kendi askeri?", prio=True,
          draft="Merkezi imparatorlukta Merigaud, bugün Orsolune. Orsolune kıtanın çoğuna borç veriyor; Vaelghard ona borçlu.", draft_label="Bildiğimiz"),
        q("bugun.haydut", "Haydut kralı bir kişi mi, bir unvan mı? Bugün kaç tane var, en ünlüsü kim, nerede?",
          draft="Önerim T19: en çok Ayazkaya'nın bedel kültürü.", draft_label="Bağ"),
        q("bugun.gg", "Para birimi GG: açılımı ne, kim basıyor, her yerde geçer mi?", prio=True, hint="Haritada bir 'Eski Darphane Yıkıntısı' var; Orsolune kıtanın bankeri."),
        q("bugun.kervanad", "Kervanlara ad nasıl konur? Kurucunun adından mı, bir olaydan mı, bir yemin mi?"),
        q("bugun.buyucuparti", "Bir büyücü kervanın kadrosuna katılabilsin mi?", choices=["Evet, nadir ve pahalı", "Hayır, yalnızca düşman ya da olay", "Başka"]),
        q("bugun.avci", "Büyücü avcıları oyunda olsun mu? Kime hizmet ederler (Vaelghard, kilise, Orvahel)?", choices=["Düşman", "Kiralanabilir sınıf", "Yalnızca olay kartı", "Başka"]),
        q("bugun.obur", "Öbürkülere halk her bölgede ne ad veriyor? (peri, hayalet, ruh dışında yerel adlar)"),
        q("bugun.yaratik", "Kurtadam, vampir ya da dev hayvan masalları belirli bölgelere mi bağlı? Hangisi nerede anlatılır?"),
        q("bugun.takvim", "Takvimin adı ne, yıl neyle başlar, yıllar nasıl sayılır? (İmparatorluğun çöküşünden mi, bir Birinci Okuyucu'dan mı?)", prio=True),
        q("bugun.olum", "Yol dışında ölüler nasıl gömülür: kilise mezarlığı, Baikhan'da doğaya bırakma, dağda yakma?"),
        q("bugun.borc", "Borç ve itibar kültürü: borcunu ödemeyene ne olur? Loncanın kara defteri?",
          draft="Ors'ta sözleşmeyi bozmak en büyük suç; dolandırıcılığa asla izin verilmez. Ezmerak'ta aldatma düello sebebi.", draft_label="Bildiğimiz"),
        q("bugun.sifahane", "Şifahaneler kimin: kilisenin mi, loncanın mı, bağımsız hekimlerin mi? Doğada arınma Gokyurt'ta ve Taşkök'te nasıl yapılır?"),
    ]
    secs.append({"id": "bugun", "title": "Bugünün dünyası", "lead": "İnanç ve kurumların açık kalan uçları.", "items": [{"kind": "plain", "key": "bugun", "title": "Bugün", "qs": now}]})

    past = [
        q("gecmis.imp.sure", "İmparatorluk ne kadar sürdü, en geniş hâliyle haritanın neresini kapsadı? Güney ve Gokyurt içinde miydi?", at=[0.45, 0.22, 1.6]),
        q("gecmis.birlik", "Göçebe birliği imparatorluğu nasıl dize getirdi? Hangi han, hangi savaşlar?", prio=True,
          draft="Bildiğimiz: tarihte boyların birlikte davrandığı tek olay; han birliği topladı, ordular birleşti; savaş bitince herkes obasına döndü. Sonunda Merigard yakıldı.", draft_label="Bildiğimiz"),
        q("gecmis.asimilasyon", "Asimilasyonun sırası: kilise önce hangi bölgeleri, hangi inançları yuttu? Kimler direndi (Tolvarin, Kirsavel, Taşkök)?"),
        q("gecmis.kadim.yurt", "Kadim uygarlığın yurdu haritanın neresiydi? Antik tapınaklar nerede yoğun?", prio=True),
        q("gecmis.kadim.son", "Kadim uygarlığın sonu nasıl oldu? (Kimse bilmiyor ama sen biliyorsun; oyunda hiç doğrudan söylenmeyecek.) Kıtlıkla bir bağı var mı?"),
        q("gecmis.kayip", "Kayıp çağ ne kadar sürdü? Ondan geriye bir şey hatırlanıyor mu (bir şarkı, bir sözcük, bir yasak)?"),
        q("gecmis.raviellon", "Raviellon'la ilk temas ne zaman, kim kurdu? Büyü okulu ne zamandan beri var?"),
        q("gecmis.guney", "Güney ticaret kentleri imparatorluğa bağlı mıydı? Orsolune ne zaman bankere dönüştü?"),
        q("gecmis.lonca", "Tüccar Loncası nasıl kuruldu, ilk defteri kim açtı?"),
        q("gecmis.savaslar", "Kırık Mızrak Çayırı hangi savaşın alanı? (Mühür Savaşı, Bölünmüş Sancak ve Kiralık Kılıçlar için önerilerim onay bölümünde.)"),
        q("gecmis.cag", "Çağların halk arasındaki adları (örneğin 'imparatorluk günleri', 'yangın yılı', 'açlık çağı')."),
    ]
    secs.append({"id": "gecmis", "title": "Geçmiş", "lead": "Bugünden geriye. Oyunda hiçbiri anlatıcının ağzından söylenmeyecek; yalnızca NPC'lerin, kitapların ve yazıtların parçaları olarak.",
                 "items": [{"kind": "plain", "key": "gecmis", "title": "Geçmiş", "qs": past}]})
    return secs


TITLE = "Sideria Soru Defteri II"
LEDE = ("Bölge cevapların işlendi. Bu defter üç şey soruyor: cevaplarından kurduğum bağları onaylıyor musun, "
        "iki kaynağın tutmadığı yerlerde hangisi geçerli, ve hâlâ boş kalanlar. Yeşil kutular önerim ya da bildiğimiz; "
        "cevabın yazdıkça kaydedilir. Kırmızı 'öncelikli' olanlar başka işlerin önünü açıyor.")


def main(out):
    st = json.load(open(os.path.join(ROOT, "data/config/settlements.json"), encoding="utf-8"))
    settlements = st["settlements"]
    places = json.load(open(os.path.join(ROOT, "tools/worldmap/atlas/places_v3.json"), encoding="utf-8"))
    region_names = {}
    for s in settlements:
        region_names.setdefault(s["region"], []).append(s["proper_name"])
    for p in places:
        if p["k"] in ("in_yurtcamp",):
            region_names.setdefault("gocebe", []).insert(0, p["d"].replace(" Obası", ""))
        if p["k"] == "ix_mountaintribe":
            region_names.setdefault("dag", []).insert(0, p["d"])

    data = {
        "regions": REGIONS,
        "polys": load_regions(),
        "settlements": [{
            "id": s["id"], "name": s["proper_name"], "region": s["region"], "type": TYPE_LABEL[s["map_kind"]],
            "wall": WALL_LABEL.get(s.get("wall"), ""), "pos": [round(s["pos"][0] / MAP_W, 4), round(s["pos"][1] / MAP_W, 4)],
            "big": s["type"] == "city",
            "produces": [GOODS.get(g, g) for g in s["produces"]], "demands": [GOODS.get(g, g) for g in s["demands"]],
            "neighbours": len(s["neighbours"]),
        } for s in settlements],
        "places": [],
        "sections": build_questions(settlements, places, region_names),
        "summary": open(os.path.join(ROOT, "docs/lore/LORE_OZET.txt"), encoding="utf-8").read(),
    }
    for p in places:
        if p["k"] in PLACE_KIND and p["k"] not in ("it_town",):
            mx, my = place_to_map(p["x"], p["y"])
            data["places"].append({"n": p["d"], "k": PLACE_KIND[p["k"]], "pos": [round(mx / MAP_W, 4), round(my / MAP_W, 4)]})
    thumbs = {}
    for s in settlements:
        t = town_thumb(s["id"])
        if t:
            thumbs[s["id"]] = t
    tmpl = open(os.path.join(ROOT, "tools/lore_soru_sayfasi.html"), encoding="utf-8").read()
    html = (tmpl.replace("__TITLE__", TITLE).replace("__LEDE__", LEDE).replace("__MAP__", b64(map_image(), q=80))
            .replace("__DATA__", json.dumps(data, ensure_ascii=False))
            .replace("__THUMBS__", json.dumps(thumbs)))
    open(out, "w", encoding="utf-8").write(html)
    total = sum(len(i["qs"]) for sec in data["sections"] for i in sec["items"])
    print(out, f"{len(html) / 1e6:.2f} MB", total, "soru")


if __name__ == "__main__":
    main(sys.argv[1])
