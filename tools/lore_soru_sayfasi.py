#!/usr/bin/env python3
"""Lore soru defteri: harita v3 üstüne kurulmuş, cevapları saklayan tek sayfa.

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
    "gocebe": "Göçebe boyları",
    "imparatorluk": "Kuzeyin eski imparatorluğu",
    "sinir": "Sınır halkları",
    "dag": "Dağ kabileleri",
    "dag_maden": "Dağ kabileleri ve madenler",
    "vadi": "Vadi",
    "ahit": "Eski Ahit kutsal kenti",
    "guney": "Güney kentleri",
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


# ---------------------------------------------------------------- soru bankası

def q(qid, text, hint="", choices=None, at=None, prio=False):
    d = {"id": qid, "t": text}
    if hint:
        d["h"] = hint
    if choices:
        d["c"] = choices
    if at:
        d["at"] = at
    if prio:
        d["p"] = 1
    return d


REGION_EXTRA = {
    "gocebe": [
        q("bolge.gocebe.yon", "Haritada göçebelerin bozkırı kıtanın kuzeybatısında. İlk cevabında (C1) 'doğudaki göçebe boylar' demiştin. Hangisi geçerli?",
          choices=["Harita geçerli: göçebeler kuzeybatıda", "Doğuda da bir boy kolu var", "Başka"], prio=True),
        q("bolge.gocebe.han", "Arsalkan Obası haritada hanın obası. Bugün bir han var mı? Kaç boy var ve onları ne bir arada tutuyor?",
          hint="Obalar: Kaynurak, Ebrusun, Sadirim, Ilkatay, Burkasan, Otekur, Taragun, Yelbarik, Sogurtay, Arsalkan."),
        q("bolge.gocebe.birlik", "İmparatorluğu dize getiren göçebe birliği bugün hâlâ var mı, dağıldıysa neden?", prio=True),
        q("bolge.gocebe.orbeyan", "Orbeyan Kervansarayı bozkırın tek kalıcı yeri. Göçebeler kalıcı bir yere neden izin verdi, kim işletiyor?"),
        q("bolge.gocebe.goc", "Obalar mevsimle nereye göçer? Kervan yolları göç yollarıyla kesişince ne olur?"),
        q("bolge.gocebe.yabanci", "Bozkırda yabancı bir kervan nasıl karşılanır? Misafirlik kuralı, geçiş bedeli ya da yasak?"),
    ],
    "imparatorluk": [
        q("bolge.imp.bugun", "Bölge 'eski' imparatorluk diye işaretli ama kullanıcı notu 'askerî açıdan güçlü' diyor. Bugün burada ne var?",
          choices=["İmparatorluğun küçülmüş ama ayakta kalmış hâli", "Onun yerine kurulmuş yeni bir krallık", "Birbirine düşman prenslikler", "Başka"], prio=True),
        q("bolge.imp.baskent", "Vastrevar kuzeyin en büyük şehri. İmparatorluğun başkenti miydi? Değilse başkent neredeydi?", prio=True),
        q("bolge.imp.ordu", "Oyunda bu bölgede garnizon askerleri çıkıyor. Ordu kime bağlı, neyi koruyor, kervana nasıl davranıyor?"),
        q("bolge.imp.kilise", "Kuzeyin El kilisesiyle ilişkisi: kilisenin koruyucusu mu, rakibi mi?"),
        q("bolge.imp.kar", "Kar yalnızca kuzeybatı dağlarında. Kuzeyde kış hayatı ve kervan yolları nasıl değişir?"),
    ],
    "sinir": [
        q("bolge.sinir.neyin", "Sınır halkları iki parça: batıda (Tolvarin, Kirsavel, Akavan, Samuran) ve doğuda (Ezmerak, Golcavar). Hangi güçlerin arasında kalmışlar?", prio=True),
        q("bolge.sinir.ayni", "Batı ve doğu sınır halkları aynı halk mı, yoksa yalnızca 'arada kalmış' oldukları için mi aynı adı taşıyorlar?",
          choices=["Aynı halk, imparatorluk dağılınca bölündü", "Farklı halklar, kader ortak", "Başka"]),
        q("bolge.sinir.agac", "Sınır kasabalarının çoğu kütük surlu. Taş sur neden yok: yoksulluk mu, sık el değiştirme mi, gelenek mi?"),
        q("bolge.sinir.multeci", "Savaş mültecileri ve haydut kralları bu bölgede mi yoğun?"),
    ],
    "dag": [
        q("bolge.dag.iki", "Dağ kabileleri iki yerde: kuzeybatının ucundaki karlı dağlar ve kuzeydoğu dağları (Brazdun, Kesgrav). Aynı halkın iki kolu mu?"),
        q("bolge.dag.kabileler", "Kabileler: Harvek, Kovrast, Kemersal, Ulmarec, Droskal, Ulgras. Bunlardan biri ya da birkaçı öne çıksın mı (en güçlüsü, en eskisi, düşmanı)?"),
        q("bolge.dag.nefes", "Dağın İlk Nefesi'nin dağı hangisi? Güç sınavı nerede yapılır?", prio=True, at=[0.79, 0.11, 3]),
        q("bolge.dag.gecit", "Dağ Kabilesi'nin 'koruduğu geçitler' hangileri? Geçit bedeli, kabile ile kervan arasındaki anlaşma?"),
    ],
    "dag_maden": [
        q("bolge.maden.kimin", "Doğu sıradağındaki madenler kimin? Kabilelerin mi, bir beyin mi, loncanın mı?", prio=True),
        q("bolge.maden.ocak", "Kazrun Ocağı (derin maden) ve Saldrek Tuzlası: ne çıkıyor, kim çalışıyor? Mühürsüz tuzun kaynağı Saldrek mi?",
          at=[0.72, 0.24, 3]),
        q("bolge.maden.buzul", "Eski yaratıkların kalıntısı buzullardan çıkıyor. Buzullar bu dağlarda mı, kuzeybatı dağlarında mı?"),
        q("bolge.maden.vorgat", "Vorgat bölgenin tek oynanabilir yeri ve bir nehir kasabası. Nehrin adı ne, nereye akar?"),
    ],
    "vadi": [
        q("bolge.vadi.lonca", "Tüccar Loncası'nın merkezi Vadi'de mi? Hangi şehirde?", prio=True),
        q("bolge.vadi.serbest", "Vadi'de üç serbest şehir var (Ondrelle, Belvanor, Ilsande). Kimden serbestler, bunu nasıl kazandılar?", prio=True),
        q("bolge.vadi.ipek", "Ilsande ve Duvenmor ipek üretiyor. Sideria ipeği nasıl yapılır ve denizden gelen 'özel ipek'ten farkı ne?"),
        q("bolge.vadi.kayitsiz", "Vadi halkı kiliseye bağlı ama kayıtsız. Bu kayıtsızlık şehirde nasıl görünür (boş kilise, pazarlıkla bağış, kâtiplerin alayı)?"),
    ],
    "ahit": [
        q("bolge.ahit.ad", "'Eski Ahit' Türkçede gerçek bir kutsal kitabın adı (Tevrat'ın Hristiyan adı). Ad kuralına göre gerçek dinî imge kullanılmıyor. Ne yapalım?",
          choices=["Adı değiştir (önerini yaz)", "Ahit kalsın, 'Eski' düşsün", "Olduğu gibi kalsın", "Başka"], prio=True),
        q("bolge.ahit.kimin", "Orvahel kimin kutsal kenti?",
          choices=["El kilisesinin baş şehri", "Kiliseden eski bir inancın kenti", "Kadim uygarlıktan kalma bir yer", "Başka"], prio=True),
        q("bolge.ahit.tapinak", "Şehrin ortasında dört kuleli büyük bir tapınak var. Kime adanmış, dört kule neyi temsil ediyor?"),
        q("bolge.ahit.kavsak", "Orvahel altı yolun buluştuğu yer. Hacılar, ticaret, vergi: kutsal kent kervana ne ister?"),
    ],
    "guney": [
        q("bolge.guney.birlik", "Güney kentleri (Orsolune, Zelmarin, Mirsana, Seyvan) bir ticaret birliği mi, birbirinin rakibi mi?",
          choices=["Bir birlik/konsey", "Rakip kent devletleri", "Biri diğerlerine hükmediyor", "Başka"], prio=True),
        q("bolge.guney.buyucu", "Büyücüler güney kentlerinde kabul görüyor. Bir güney şehrinde büyücü nasıl yaşar, ne iş yapar, kim korur?"),
        q("bolge.guney.raviellon", "Raviellon'a ve uzak kıtalara hangi limandan gemi kalkar? Yolculuk ne kadar sürer, neden zordur?"),
        q("bolge.guney.hosgoru", "Güneyin hoşgörüsünün sınırı nerede? Neye asla izin verilmez?"),
    ],
}

COMMON_REGION = [
    ("ad", "Bu bölgenin halkın ağzındaki kendi adı ne? (Haritada yalnızca bir tanım var: '{label}'.)", True),
    ("yonetim", "Bugün kim yönetiyor (krallık, prenslik, beylik, boy, konsey, kilise)? Merkezi hangi yerleşim?", True),
    ("halk", "Halkın kendine verdiği ad ve dilinin tadı. Haritadaki adlar ({names}) bu tadı doğru taşıyor mu?", False),
    ("inanc", "Baskın inanç ne? Gizlice yaşayan ya da azınlıkta kalan inançlar?", False),
    ("ilkizlenim", "Bir kervan bu bölgeye girince neyi hemen fark eder? (bir gelenek, bir yasak, bir tehlike, bir koku, bir ses)", False),
    ("komsu", "Komşularıyla ilişkisi: kimle düşman, kimle ortak, kime borçlu?", False),
    ("ofke", "Bu bölgenin halkının en çok neye öfkelenir, neyi asla affetmez?", False),
]

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

SETTLEMENT_EXTRA = {
    "vastrevar": q("yer.vastrevar.x", "Vastrevar haritada kuzeyin en büyük şehri ve koyu taş surlu. Kuzeyin bugünkü gücü burada mı oturuyor?"),
    "auderin": q("yer.auderin.x", "Auderin kıtanın en kuzeydeki yerleşimi (Orsolune'ye 61 gün). Dünyanın kuzey ucunda yaşamak nasıl bir şey, ötesinde ne olduğuna inanılır?"),
    "orsolune": q("yer.orsolune.x", "Orsolune kıtanın en güneyi. Kuzeyden gelen bir kervan için Orsolune neyi temsil eder (yolun sonu, denizin kapısı, zenginlik)?"),
    "orvahel": q("yer.orvahel.x", "Orvahel'e altı yol çıkıyor, kıtanın en büyük kavşağı. Kutsallığı mı yolları çekti, yollar mı kutsallığı?"),
    "ezmerak": q("yer.ezmerak.x", "Ezmerak iç kaleli bir sınır şehri. Kale kimi kime karşı koruyor? Lonca buradan Orvahel'e 'sınır karakolu vagonu' gönderiyor."),
    "rivecande": q("yer.rivecande.x", "Rivecande kuzeyin limanı; büyük iç suyun kıyısında. Bu su açık denize bağlı mı, gemiler nereye gider?", at=[0.62, 0.36, 3]),
    "serai_seyvan": q("yer.seyvan.x", "Seyvan altı yolun kavşağında ve güneyin kervansarayı. Güneyin bütün ticareti buradan mı geçiyor?"),
    "serai_duvenmor": q("yer.duvenmor.x", "Duvenmor vadinin kuzey kapısında. Kervansarayın adı bir kişiden mi geliyor?"),
    "mirsana": q("yer.mirsana.x", "Mirsana bir pazar kasabası ve baharat satıyor. Baharat ona denizden mi, başka bir yoldan mı geliyor?"),
}

PLACE_Q = {
    "Deli Kral Sarayı Yıkıntısı": ("Deli kral kimdi, sarayı neden burada ve neden yıkıntı? Halk buraya yaklaşır mı?", True),
    "Eski Darphane Yıkıntısı": ("Burada kim, hangi parayı bastı? GG'nin kökeni burası mı?", True),
    "İlk Nefes Taşları": ("Adı Dağın İlk Nefesi'ni çağırıyor ama doğu kıyısında, dağdan uzakta duruyor. Bağlantı ne?", True),
    "Gelgit Taşları": ("Denizin İlk Gözyaşı ile ilgili mi? Güneydoğu kıyısındaki bu taşlarda ne yapılır?", False),
    "Yıldızölçer Taşları": ("Gökyüzünü ölçen taşlar. Kim dikti: kadim uygarlık mı, eski inançlar mı? Takvimle ilgisi var mı?", False),
    "Altıkuşak Taşları": ("Altı kuşak kimin altı kuşağı? Batı kıyısındaki bu taşların hikâyesi?", False),
    "Bahçıvan Taşları": ("Bahçıvan kim? Taşların çevresinde ne yetişir?", False),
    "Sessiz El Manastırı": ("Adı El'i anıyor. Kim yaşar, neden sessiz (yemin, ceza, ölüm)?", True),
    "İlk Sayfa Manastırı": ("'El'in yazdığı ilk sayfa' mı? Kilisenin doğduğu yer burası mı?", True),
    "Açık Kapı Manastırı": ("Kapısı kime açık: yolculara mı, kaçaklara mı, büyücülere mi?", False),
    "Yamalı Çatı Manastırı": ("Yoksul bir manastır mı, yıkılıp yeniden yapılan mı? Bekçi Kadın'la ilgisi?", False),
    "Taşsoluk Manastırı": ("Taşın soluğu: Dağın İlk Nefesi'nden kilisenin devraldığı bir yer mi?", False),
    "Kırık Mızrak Çayırı": ("Hangi savaş, kimler arasında, kim kazandı?", False),
    "Bölünmüş Sancak Ovası": ("Bir ordunun bölündüğü yer mi? İmparatorluğun dağılışıyla ilgisi?", True),
    "Kiralık Kılıçlar Ovası": ("Paralı askerlerin savaşı mı, ihaneti mi?", False),
    "Mühür Savaşı Ovası": ("Hangi mühür için savaşıldı? Oyundaki nadir 'eski mühür' eşyası buradan mı?", True),
    "Kızıl Ferman Darağacı": ("Kimin fermanı, kim asıldı?", False),
    "Kefaret Darağacı": ("Kefaret: kilisenin cezası mı? Arınma ritüeliyle bağı?", False),
    "Dönek Darağacı": ("Dönekler kimdi: inancını mı, efendisini mi değiştirdiler?", False),
    "Sarmaşıklı Darağacı": ("Artık kullanılmıyor mu? Neden sarmaşık bürüdü?", False),
    "Kuru Halat Darağacı": ("Bu darağacının bir hikâyesi?", False),
    "Yabancılar Mezarlığı": ("Kimler 'yabancı' sayılıp buraya gömülür? Yolda ölenlerin işaretsiz mezarı kuralıyla ilişkisi?", True),
    "Sancaksız Mezarlık": ("Sancaksız ölenler kim: bayraksız askerler, kaçaklar, haydutlar?", False),
    "Kör Kazmalar Mezarlığı": ("Madencilerin mezarlığı mı? Neden 'kör'?", False),
    "Leylak Mezarlığı": ("Bu mezarlığın hikâyesi?", False),
    "Tuzlu Çardak Mezarlığı": ("Kıyıda, denizde ölenlerin mezarlığı mı?", False),
    "Tozkapı Yıkıntısı": ("Hangi çağdan: kadim uygarlık, eski inançlar, imparatorluk? Neyin kapısıydı?", False),
    "Velkrun Yıkıntısı": ("Hangi çağdan? Kuzeyin ucunda neden bir yapı vardı?", False),
    "Sargalak Yıkıntısı": ("Hangi çağdan? Bozkırın ortasında kim yaşadı?", False),
    "Solgun Bahçe Yıkıntısı": ("Bir zamanlar bir bahçe mi, bir saray mı? Neden solgun?", False),
    "Hallecort Yıkıntısı": ("Hangi çağdan? Kim terk etti?", False),
    "Sessiz Kadırga Batığı": ("Hangi gemi, nereden geliyordu? Sessiz kalmasının sebebi?", False),
    "Kanlı Direk Batığı": ("Korsan mı, savaş gemisi mi? Batığın masalı?", False),
    "Öksüz Göz Kulesi": ("Neden öksüz? Kimse nöbet tutmuyor mu?", False),
    "İki Bayrak Kulesi": ("Hangi iki bayrak? İki gücün sınırı mı?", False),
    "Grauth Feneri": ("Kuzeyin en ucundaki fener. Kime yol gösterir, kim yakar?", False),
}


def build_questions(settlements, places, region_names):
    secs = []
    # Bölgeler
    items = []
    for key, label in REGIONS.items():
        names = ", ".join(region_names.get(key, [])[:6]) or "-"
        qs = [q(f"bolge.{key}.{suffix}", text.format(label=label, names=names), prio=prio)
              for suffix, text, prio in COMMON_REGION]
        qs += REGION_EXTRA.get(key, [])
        items.append({"kind": "region", "key": key, "title": label, "qs": qs})
    secs.append({"id": "bolgeler", "title": "Bölgeler", "lead": "Kullanıcının 16 Ekim renk işaretlemesindeki sekiz kültür bölgesi. Her bölgenin haritadaki sınırı gösteriliyor.", "items": items})

    # Yerleşimler
    items = []
    order = ["imparatorluk", "gocebe", "sinir", "dag", "dag_maden", "vadi", "ahit", "guney"]
    for s in sorted(settlements, key=lambda s: (order.index(s["region"]), s["pos"][1])):
        sid = s["id"]
        qs = [
            q(f"yer.{sid}.kimlik", f"Tek cümleyle: Sideria'da '{s['proper_name']}' denince akla ilk ne gelir?", prio=True),
            q(f"yer.{sid}.yonetim", "Kim yönetir, kime bağlıdır?"),
            q(f"yer.{sid}.tur", SETTLEMENT_TYPE_Q[s["map_kind"]]),
            q(f"yer.{sid}.gelenek", "Bir yerel gelenek, bir yasak ya da halkın anlattığı bir hikâye."),
        ]
        if sid in SETTLEMENT_EXTRA:
            qs.insert(1, SETTLEMENT_EXTRA[sid])
        items.append({"kind": "settlement", "key": sid, "title": s["proper_name"], "qs": qs})
    secs.append({"id": "yerlesimler", "title": "Yerleşimler", "lead": "Oyundaki 27 yerleşim, bölgelerine göre kuzeyden güneye. Resim, oyundaki şehir önü görüntüsü (gündüz).", "items": items})

    # Adı konmuş yerler
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
        "Balıkçı köyleri, obalar, mezralar, çiftlikler": "Haritadaki küçük yerlerden hikâyesi olmasını istediğin var mı? Adını ve hikâyesini yaz.",
        "Kalan fener ve kuleler": "Yalaz ve Yaşlı Martı fenerleri; Kıyıgözü, Geribakan, Sentinara, Ferrant, Vardas kuleleri. Herhangi birinin hikâyesi?",
    }
    for i, (title, text) in enumerate(group.items()):
        items.append({"kind": "group", "key": f"grup{i}", "title": title, "qs": [q(f"iz.grup{i}", text)]})
    secs.append({"id": "izler", "title": "Adı konmuş yerler", "lead": "Atlasta adı var, hikâyesi yok. Ad bir şey vaat ediyor; cevabın o vaadi doldurur. Bilmediğin yeri boş bırak.", "items": items})

    # Deniz, su, dağ
    geo = [
        q("cog.denizler", "Kıtayı saran denizlerin adları. Batı denizi, kuzeydeki koylar, doğu denizi ve güneydoğudaki boğaz tek bir deniz mi, ayrı denizler mi?", prio=True, at=[0.5, 0.5, 1]),
        q("cog.guneydogu", "Güneydoğudaki boğazın ötesindeki kara nedir? (Sideria ile arasında yol yok, 'deniz orası' demiştin.)",
          choices=["Sideria'nın kopmuş bir parçası", "Raviellon", "İki büyük kıtadan birinin ucu", "Başka"], at=[0.93, 0.95, 3], prio=True),
        q("cog.icsu", "Kıtanın ortasındaki büyük iç sular (Rivecande ile Dravoss arası): tuzlu mu tatlı mı, adları ne, üstlerinde gemi var mı?", at=[0.55, 0.38, 2.4]),
        q("cog.sirt", "Doğuyu kuzeyden güneye kesen büyük sıradağın adı ne? Geçitleri kaç tane?", at=[0.8, 0.55, 1.8], prio=True),
        q("cog.kuzeybati", "Kuzeybatının karlı dağlarının adı ne?", at=[0.12, 0.05, 3]),
        q("cog.ormanlar", "Büyük ormanların adları: doğudaki sıradağ ormanları, güneydeki ormanlar. Binlerce yıllık ağaçlar hangisinde?", at=[0.6, 0.78, 2]),
        q("cog.nehirler", "Ana nehirlerin adları ve kaynakları?"),
        q("cog.adalar", "Kuzeydoğu ve doğu kıyısındaki küçük adalar: 'güney tüccarlarının bildiği adalar' bunlar mı? Kimse yaşıyor mu?", at=[0.93, 0.3, 2.6]),
        q("cog.bataklik", "Bataklık kasabaları üç yerde (Samuran, Liraven, Golcavar). Bataklıkların halk arasındaki adı ve masalı?"),
        q("cog.issiz", "Haritada ıssız bırakılmış, yerleşimsiz bölgeler var mı? Halk oralara neden gitmez?", hint="Öbürkülerin 'orada bir şey var' denilen yerleri olabilir."),
        q("cog.iklim", "İklim haritadan ölçülüyor: kuzey soğuk, güney sıcak. Kışın kapanan geçitler ya da mevsimlik yollar olsun mu?"),
    ]
    secs.append({"id": "cografya", "title": "Su, dağ, orman", "lead": "Haritada çizili ama adı konmamış büyük yapılar. 'Haritada göster' ilgili yere götürür.",
                 "items": [{"kind": "plain", "key": "cografya", "title": "Coğrafya", "qs": geo}]})

    # Çelişkiler
    con = [
        q("cel.kultur", "Haritada sekiz kültür bölgesi var, oyunda beş oynanabilir kültür. Ne yapalım?",
          choices=["Beş kalsın, diğerleri yalnızca NPC", "Kuzey imparatorluğu ve sınır halkları da oynanabilir olsun", "Sekizi de oynanabilir olsun", "Başka"], prio=True),
        q("cel.esleme", "Oynanabilir beş kültür hangi bölgelerin halkı? Göçebe → göçebe boyları ve Vadi → Vadi açık. Liman Şehri güney kentleri mi? Balıkçı Kasabası hangi kıyı? Dağ Kabilesi her iki dağ bölgesi mi?", prio=True),
        q("cel.baharat", "Baharat (C15) denizden liman kentlerine gelir. Ama oyunda bozkırdaki Orbeyan Kervansarayı da baharat üretiyor.",
          choices=["Orbeyan'a baharat kara yoluyla, uzak doğudan gelir", "Orbeyan'dan baharatı kaldır", "Bozkırın kendi baharatı var (otlar)", "Başka"]),
        q("cel.deniz", "'Denizin İlk Gözyaşı' efsanesi kimin? Oyunda balıkçıların; bir soru metninde Baikanlara bağlanmıştı.",
          choices=["Balıkçıların", "Güney limanlarının", "Bütün kıyı halklarının", "Başka"]),
        q("cel.nefes", "Dağın İlk Nefesi küçük bir inanış ama kilise ekranında Denizin İlk Gözyaşı ile eşit okutuluyor. Metin değişsin mi?",
          choices=["Değişsin, Nefes daha kısa ve ikinci planda", "Kalsın, kilise ikisini de 'El'in sayfası' diye eşit okutur", "Başka"]),
        q("cel.hiyerarsi", "Siyasi birimler: oyun 'beylik', C1 'prenslik', C6 'kral' ve 'konsey' diyor. Üçü birlikte nasıl duruyor?", prio=True,
          hint="Örnek: krallar > prensler > beyler; ya da her bölgenin kendi sözcüğü (kuzeyde prens, sınırda bey)."),
        q("cel.yoldadogan", "'Yolda doğan' ana karakter kuşak sisteminde kim?",
          choices=["Kurucu (baba)", "İlk lider (oyuncunun ilk karakteri)", "Her lider", "Kervanın adının kendisi", "Başka"], prio=True),
        q("cel.isaret", "'İşaretsiz Mezar' kartında 'bir işaret koy' seçeneği var. Yolda ölenin mezarına ad konmaz. Taş yığmak saygı mı, kural ihlali mi?",
          choices=["Taş yığmak saygı, ad yazmak ihlal", "Her işaret ihlal; seçenek kalksın", "Başka"]),
        q("cel.s11", "Önceki soru listesinde S11 yoktu: atlandı mı, cevabı mı eksik?"),
    ]
    secs.append({"id": "celiskiler", "title": "Çelişkiler", "lead": "İki kaynağın tutmadığı yerler. Seçenek işaretlemek yeter; istersen gerekçe yaz.",
                 "items": [{"kind": "plain", "key": "celiskiler", "title": "Karar bekleyenler", "qs": con}]})

    # Bugün
    now = [
        q("bugun.el", "The Hand (El) ne?", choices=["Tanrının kendisi", "Tanrının bir sıfatı", "Adı bilinmeyen tanrının eli", "Başka"], prio=True),
        q("bugun.kilise", "Kilisenin yapısı: başında kim var, rahiplerin dereceleri, nerede oturur?", prio=True),
        q("bugun.sembol", "Kilisenin sembolü ne? (Öneri: açık el ya da mühür basan el; kubbe ve minare yok, bina çan kulesi.)"),
        q("bugun.bekci", "Bekçi Kadın'ın iki inançtaki adları ('yolcu' anlamına gelen).", prio=True),
        q("bugun.baikhan", "Baikhan ve Gokana: inancın adı mı, varlıklar mı, yerler mi?",
          choices=["Baikhan gök, Gokana toprak", "Baikhan yol/inanç, Gokana ölülerin yeri", "İkisi de varlık", "Başka"], prio=True),
        q("bugun.lonca", "Tüccar Loncası kime bağlı? Kilise ve krallarla ilişkisi ne? Loncanın kendi askeri var mı?", prio=True),
        q("bugun.haydut", "Haydut kralı bir kişi mi, bir unvan mı? Bugün kaç tane var, en ünlüsü kim, nerede?"),
        q("bugun.gg", "Para birimi GG: açılımı ne, kim basıyor, her yerde geçer mi?", prio=True, hint="Haritada bir 'Eski Darphane Yıkıntısı' var."),
        q("bugun.kervanad", "Kervanlara ad nasıl konur? Kurucunun adından mı, bir olaydan mı, bir yemin mi?"),
        q("bugun.buyucuparti", "Bir büyücü kervanın kadrosuna katılabilsin mi?", choices=["Evet, nadir ve pahalı", "Hayır, yalnızca düşman ya da olay", "Başka"]),
        q("bugun.avci", "Büyücü avcıları oyunda olsun mu?", choices=["Düşman", "Kiralanabilir sınıf", "Yalnızca olay kartı", "Başka"]),
        q("bugun.arinma", "Huy arındırma mistik mi, toplumsal mı?", choices=["Toplumsal bir yüzleşme ve kefaret", "Kilisenin inandığı ama kanıtsız bir mucize", "Başka"]),
        q("bugun.obur", "Öbürkülere halk her bölgede ne ad veriyor? (peri, hayalet, ruh dışında yerel adlar)"),
        q("bugun.yaratik", "Kurtadam, vampir ya da dev hayvan masalları belirli bölgelere mi bağlı? Hangisi nerede anlatılır?"),
        q("bugun.dil", "Sideria'da ortak bir ticaret dili var mı? Liman insanı 'beş dil' öğrenir: hangileri?"),
        q("bugun.takvim", "Takvimin adı ne, yıl neyle başlar, yıllar nasıl sayılır?", prio=True),
        q("bugun.olum", "Yol dışında ölüler nasıl gömülür: kilise mezarlığı, Baikhan'da doğaya bırakma, dağda yakma?"),
        q("bugun.borc", "Borç ve itibar kültürü: borcunu ödemeyene ne olur? Loncanın kara defteri?"),
    ]
    secs.append({"id": "bugun", "title": "Bugünün dünyası", "lead": "Siyaset, inanç ve kurumlar bugün.", "items": [{"kind": "plain", "key": "bugun", "title": "Bugün", "qs": now}]})

    past = [
        q("gecmis.imp.ad", "İmparatorluğun adı ne?", prio=True),
        q("gecmis.imp.sure", "Ne kadar sürdü, en geniş hâliyle haritanın neresini kapsadı?", at=[0.45, 0.22, 1.6]),
        q("gecmis.delikral", "Deli kral kimdi? Büyücüleri neden katletti, nerede, ne oldu sonunda?", prio=True),
        q("gecmis.birlik", "Göçebe birliği imparatorluğu nasıl dize getirdi? Hangi savaş, hangi han?", prio=True),
        q("gecmis.yollar", "Ana yollar imparatorluğun yolları mı? Yolların üstündeki sunaklar ondan eski mi?", choices=["Evet, ikisi de", "Yollar daha eski", "Başka"]),
        q("gecmis.parcalanma", "İmparatorluk dağıldıktan sonra ne oldu? Prenslikler, iç savaşlar, sınır halklarının doğuşu?"),
        q("gecmis.kilise", "Kilise ne zaman, nerede doğdu: imparatorluktan önce mi, onunla mı, sonra mı?", prio=True,
          choices=["İmparatorluktan önce", "İmparatorlukla birlikte (resmî din)", "Dağılıştan sonra", "Başka"]),
        q("gecmis.asimilasyon", "Asimilasyonun sırası: kilise önce hangi bölgeleri, hangi inançları yuttu? Direnen oldu mu?"),
        q("gecmis.ahit", "Kutsal kent Orvahel'in tarihi: kim kurdu, ne zaman kutsal oldu?"),
        q("gecmis.kadim.yurt", "Kadim uygarlığın yurdu haritanın neresiydi? Antik tapınaklar nerede yoğun?", prio=True),
        q("gecmis.kadim.son", "Kadim uygarlığın sonu nasıl oldu? (Kimse bilmiyor ama sen biliyorsun; oyunda hiç doğrudan söylenmeyecek.)"),
        q("gecmis.kayip", "Kayıp çağ ne kadar sürdü? Ondan geriye bir şey hatırlanıyor mu (bir şarkı, bir sözcük, bir yasak)?"),
        q("gecmis.raviellon", "Raviellon'la ilk temas ne zaman, kim kurdu? Büyü okulu ne zamandan beri var?"),
        q("gecmis.guney", "Güney ticaret kentleri nasıl zenginleşti? Bir zamanlar imparatorluğa bağlı mıydılar?"),
        q("gecmis.lonca", "Tüccar Loncası nasıl kuruldu, ilk defteri kim açtı?"),
        q("gecmis.savaslar", "Haritadaki dört savaş alanının (Kırık Mızrak, Bölünmüş Sancak, Kiralık Kılıçlar, Mühür Savaşı) zaman sırası ve hangi çağa ait oldukları?"),
        q("gecmis.veba", "Tarihte bilinen büyük bir veba, kıtlık ya da kuraklık var mı? Halk onu nasıl anar?"),
        q("gecmis.cag", "Çağların halk arasındaki adları (örneğin 'imparatorluk günleri', 'dağılış', 'kilise çağı')."),
    ]
    secs.append({"id": "gecmis", "title": "Geçmiş", "lead": "Bugünden geriye doğru. Oyunda hiçbiri anlatıcının ağzından söylenmeyecek; yalnızca NPC'lerin, kitapların ve yazıtların parçaları olarak.",
                 "items": [{"kind": "plain", "key": "gecmis", "title": "Geçmiş", "qs": past}]})
    return secs


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
    html = (tmpl.replace("__MAP__", b64(map_image(), q=80))
            .replace("__DATA__", json.dumps(data, ensure_ascii=False))
            .replace("__THUMBS__", json.dumps(thumbs)))
    open(out, "w", encoding="utf-8").write(html)
    total = sum(len(i["qs"]) for sec in data["sections"] for i in sec["items"])
    print(out, f"{len(html) / 1e6:.2f} MB", total, "soru")


if __name__ == "__main__":
    main(sys.argv[1])
