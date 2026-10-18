"""Yer adları üç dilde. Özel ad: yalnızca İngiliz alfabesi (her dilde aynı),
Çincede okunuş yazımı. Tür sözcüğü dile göre değişir. Anlamlı adlar tam çevrilir.

    python3 -I names_i18n.py <çıktı.json>
"""
import json
import sys

FEAT = {  # tür: (tr, en, zh)
    "oba": ("{} Obası", "{} Camp", "{}营地"),
    "ruin": ("{} Yıkıntısı", "{} Ruins", "{}遗迹"),
    "pits": ("{} Ocağı", "{} Pits", "{}矿坑"),
    "salt": ("{} Tuzlası", "{} Saltworks", "{}盐场"),
    "light": ("{} Feneri", "{} Lighthouse", "{}灯塔"),
    "mill": ("{} Değirmeni", "{} Mill", "{}磨坊"),
    "farm": ("{} Çiftliği", "{} Farm", "{}农庄"),
    "log": ("{} Kesimliği", "{} Logging Camp", "{}伐木场"),
    "saw": ("{} Bıçkıhanesi", "{} Sawmill", "{}锯木坊"),
    "tower": ("{} Kulesi", "{} Tower", "{}塔"),
    "vine": ("{} Bağları", "{} Vineyards", "{}葡萄园"),
    "garden": ("{} Bahçeleri", "{} Gardens", "{}园"),
}

# id: (özel ad, Çince okunuş, tür ya da None)
PROPER = {
    # göçebe boyları
    7: ("Arsalkan", "阿尔萨尔坎", "oba"), 0: ("Kaynurak", "凯努拉克", "oba"), 1: ("Ebrusun", "埃布鲁松", "oba"),
    2: ("Sadirim", "萨迪里姆", "oba"), 3: ("Ilkatay", "伊尔卡泰", "oba"), 4: ("Burkasan", "布尔卡桑", "oba"),
    5: ("Otekur", "奥特库尔", "oba"), 6: ("Taragun", "塔拉贡", "oba"), 80: ("Yelbarik", "耶尔巴里克", "oba"),
    88: ("Sogurtay", "索古尔泰", "oba"), 29: ("Sugalik", "苏加利克", None), 18: ("Kemersal", "凯默萨尔", None),
    82: ("Tuylum", "图伊卢姆", None), 118: ("Sargalak", "萨尔加拉克", "ruin"),
    # dağ kabileleri
    16: ("Harvek", "哈尔维克", None), 20: ("Droskal", "德罗斯卡尔", None), 21: ("Ulgras", "乌尔格拉斯", None),
    24: ("Kazrun", "卡兹伦", "pits"), 25: ("Saldrek", "萨尔德雷克", "salt"), 22: ("Brazdun", "布拉兹敦", None),
    23: ("Kesgrav", "凯斯格拉夫", None), 26: ("Reskel", "雷斯克尔", None), 129: ("Grauth", "格劳斯", "light"),
    116: ("Velkrun", "维尔克伦", "ruin"), 83: ("Dornak", "多尔纳克", None), 84: ("Zurek", "祖雷克", None),
    61: ("Morvask", "莫尔瓦斯克", "mill"), 66: ("Gezar", "盖扎尔", "farm"), 69: ("Hulvad", "胡尔瓦德", "mill"),
    # dağ ve maden bölgesi
    38: ("Vorgat", "沃尔加特", None), 73: ("Kemrug", "凯姆鲁格", None), 63: ("Tuhrem", "图赫雷姆", "farm"),
    89: ("Grodan", "格罗丹", "log"), 91: ("Gurzan", "古尔赞", "saw"),
    # kuzey, eski imparatorluk
    47: ("Vastrevar", "瓦斯特雷瓦", None), 48: ("Dravoss", "德拉沃斯", None), 34: ("Selvicar", "塞尔维卡", None),
    35: ("Auderin", "奥德林", None), 46: ("Rivecande", "里维坎德", None), 27: ("Sallenz", "萨伦茨", None),
    28: ("Calvenna", "卡尔维娜", None), 17: ("Kovrast", "科夫拉斯特", None), 19: ("Ulmarec", "乌尔马雷克", None),
    100: ("Sentinara", "森蒂纳拉", "tower"), 101: ("Ferrant", "费兰特", "tower"), 121: ("Hallecort", "哈勒科特", "ruin"),
    74: ("Hestemar", "赫斯特马", None), 76: ("Ostiven", "奥斯蒂文", None), 78: ("Callorde", "卡洛德", None),
    79: ("Pelhaut", "佩尔奥", None), 81: ("Nostrel", "诺斯特雷尔", None), 87: ("Kordel", "科德尔", "log"),
    60: ("Vintaro", "文塔罗", "farm"), 70: ("Hasdren", "哈斯德伦", "mill"),
    # sınır halkları
    49: ("Tolvarin", "托尔瓦林", None), 50: ("Ezmerak", "埃兹梅拉克", None), 33: ("Kirsavel", "基尔萨维尔", None),
    36: ("Akavan", "阿卡万", None), 30: ("Tuzyali", "图兹亚利", None), 31: ("Neminsu", "内明苏", None),
    40: ("Samuran", "萨穆兰", None), 41: ("Golcavar", "戈尔贾瓦尔", None), 127: ("Yalaz", "亚拉兹", "light"),
    104: ("Vardas", "瓦尔达斯", "tower"), 68: ("Kumbag", "库姆巴格", "mill"),
    # vadi
    51: ("Merigaud", "梅里戈", None), 52: ("Belvanor", "贝尔瓦诺", None), 53: ("Ilsande", "伊尔桑德", None),
    58: ("Ondrelle", "翁德蕾尔", None), 37: ("Caramine", "卡拉明", None), 39: ("Liraven", "利拉文", None),
    90: ("Celvane", "塞尔瓦内", "log"), 85: ("Sennabel", "森娜贝尔", None), 67: ("Aubrenne", "奥布雷娜", "vine"),
    72: ("Sorrelay", "索雷莱", "vine"),
    # güney kentleri
    54: ("Orsolune", "奥尔索伦", None), 45: ("Zelmarin", "泽尔马林", None), 42: ("Mirsana", "米尔萨娜", None),
    32: ("Brezzane", "布雷扎内", None), 75: ("Ambrisal", "安布里萨尔", None), 77: ("Quellara", "奎拉拉", None),
    62: ("Limeral", "利梅拉尔", "garden"), 65: ("Vesperra", "维斯佩拉", "vine"),
    # eski ahit şehri
    59: ("Orvahel", "奥尔瓦赫尔", None),
}

# id: (tr, en, zh) - anlamı olan adlar, her dilde çevrilir
DESC = {
    122: ("Altıkuşak Taşları", "Six-Belt Stones", "六带石阵"),
    131: ("Kanlı Direk Batığı", "Bloody Mast Wreck", "血桅沉船"),
    125: ("İlk Nefes Taşları", "First Breath Stones", "初息石阵"),
    113: ("Kör Kazmalar Mezarlığı", "Graveyard of the Blind Picks", "盲镐墓地"),
    97: ("Taşsoluk Manastırı", "Stonebreath Monastery", "石息修道院"),
    103: ("Öksüz Göz Kulesi", "Orphan Eye Tower", "孤眼塔"),
    106: ("Kuru Halat Darağacı", "Dry Rope Gallows", "枯绳绞架"),
    107: ("Kızıl Ferman Darağacı", "Red Edict Gallows", "赤诏绞架"),
    119: ("Deli Kral Sarayı Yıkıntısı", "Ruins of the Mad King's Palace", "疯王宫殿遗迹"),
    114: ("Sancaksız Mezarlık", "Bannerless Graveyard", "无旗墓地"),
    130: ("Sessiz Kadırga Batığı", "Silent Galley Wreck", "静默桨帆船沉骸"),
    109: ("Dönek Darağacı", "Turncoat Gallows", "叛徒绞架"),
    128: ("Yaşlı Martı Feneri", "Old Gull Lighthouse", "老鸥灯塔"),
    99: ("Geribakan Kulesi", "Lookback Tower", "回望塔"),
    102: ("İki Bayrak Kulesi", "Two Banners Tower", "双旗塔"),
    115: ("Tozkapı Yıkıntısı", "Dustgate Ruins", "尘门遗迹"),
    93: ("Sessiz El Manastırı", "Monastery of the Silent Hand", "静手修道院"),
    96: ("Yamalı Çatı Manastırı", "Patched Roof Monastery", "补顶修道院"),
    133: ("Bölünmüş Sancak Ovası", "Field of the Split Banner", "裂旗原"),
    64: ("Hasırlı Çiftlik", "Reedmat Farm", "苇席农庄"),
    71: ("Taşgözü Değirmeni", "Stone-Eye Mill", "石眼磨坊"),
    105: ("Sarmaşıklı Darağacı", "Ivy Gallows", "常春藤绞架"),
    123: ("Bahçıvan Taşları", "Gardener's Stones", "园丁石阵"),
    120: ("Solgun Bahçe Yıkıntısı", "Ruins of the Faded Garden", "凋园遗迹"),
    86: ("Erguvan Kesimliği", "Redbud Logging Camp", "紫荆伐木场"),
    111: ("Leylak Mezarlığı", "Lilac Graveyard", "丁香墓地"),
    132: ("Kırık Mızrak Çayırı", "Broken Spear Meadow", "断矛草甸"),
    124: ("Yıldızölçer Taşları", "Starmeasurer Stones", "量星石阵"),
    126: ("Gelgit Taşları", "Tide Stones", "潮汐石阵"),
    98: ("Kıyıgözü Kulesi", "Shore-Eye Tower", "岸眼塔"),
    117: ("Eski Darphane Yıkıntısı", "Old Mint Ruins", "旧铸币厂遗迹"),
    92: ("Tersane Kesimliği", "Shipwrights' Logging Camp", "船坞伐木场"),
    95: ("Açık Kapı Manastırı", "Open Door Monastery", "开门修道院"),
    110: ("Yabancılar Mezarlığı", "Strangers' Graveyard", "异乡人墓地"),
    112: ("Tuzlu Çardak Mezarlığı", "Salt Arbor Graveyard", "盐棚墓地"),
    134: ("Kiralık Kılıçlar Ovası", "Field of Hired Swords", "佣剑原"),
    108: ("Kefaret Darağacı", "Atonement Gallows", "赎罪绞架"),
    94: ("İlk Sayfa Manastırı", "Monastery of the First Page", "首页修道院"),
    135: ("Mühür Savaşı Ovası", "Field of the Seal War", "封印之战原"),
}


def build():
    out = {}
    for i, (name, zh, feat) in PROPER.items():
        assert name.isascii() and name.isalpha(), name
        if feat:
            t, e, z = FEAT[feat]
            out[i] = {"tr": t.format(name), "en": e.format(name), "zh": z.format(zh), "proper": name, "proper_zh": zh}
        else:
            out[i] = {"tr": name, "en": name, "zh": zh, "proper": name, "proper_zh": zh}
    for i, (t, e, z) in DESC.items():
        assert i not in out
        out[i] = {"tr": t, "en": e, "zh": z}
    return out


if __name__ == "__main__":
    o = build()
    json.dump({str(k): v for k, v in o.items()}, open(sys.argv[1], "w"), ensure_ascii=False, indent=1)
    print(len(o))
