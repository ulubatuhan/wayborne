class_name EventEffect
extends Resource

## Bir olayın dünyaya dokunabileceği tek yol. Motor bu kelime dağarcığının
## dışına çıkamaz; yeni bir etki gerekiyorsa buraya eklenir ve
## EventEffectApplier'da karşılığı yazılır.

enum Type {
	# Kaynak
	GOLD,
	PROVISIONS,
	ITEM_ADD,
	ITEM_REMOVE,
	# Kervan
	WAGON_DAMAGE,
	WAGON_LOSE,
	# Yolda vagon onarımı (bkz. evt_traveling_tinker). Şehirdeki kervansaray
	# onarımının yol karşılığı - amount kaç vagonun onarılacağı.
	WAGON_REPAIR,
	MERCHANT_LEAVE,
	MORALE,
	STRESS,
	# Yolculuk
	TRAVEL_DAYS,
	DANGER,
	# Dünya
	REPUTATION,
	DOCUMENT_LOSE,
	SET_FLAG,
	CLEAR_FLAG,
	UNLOCK_EVENT,
	# Sistem köprüsü
	TRIGGER_HAGGLING,
	TRIGGER_COMBAT,
	TRIGGER_RECRUIT,
	# Karakter
	GRANT_TRAIT,
	GRANT_EQUIPMENT,
	# Ekonomi: süreli fiyat şoku (grev, kıtlık, ambargo, bereket).
	# amount = yüzde değişim (+40 = %40 pahalanır), text_value =
	# "location_id|item_id|gün"; item_id boşsa şehrin tamamı etkilenir.
	MARKET_SHOCK,
	# Yolun durumunu bir süreliğine değiştirir: çığ geçidi kapatır, devriye
	# eşkıyayı temizler, sel yolu çamura boğar. amount = kaç gün sürer,
	# text_value = "from_id|to_id|durum" (open/slow/perilous/closed).
	# Durum iki yöne birden işler - çığ tek yönlü düşmez.
	ROUTE_CHANGE,
	# Karşılaşılan kişinin gizli mizacını ve kültür yakınlığını yuvarlar.
	# text_value = bayrak öneki (ör. "wanderer"). Sonuçlar bu bayraklara
	# bakar; oyuncu mizacı ancak sezgisi kuvvetliyse okuyabilir.
	ROLL_ENCOUNTER,
	# Haritanın büyük, adlı bir olayını başlatır (bkz. WorldEvents) - bölgesel
	# savaş, veba, ticaret fuarı, haydut haracı. amount = kaç gün sürer,
	# text_value = "kind|hedef" ("war"/"plague"/"trade_fair"/"bandit_tribute").
	# Hedef rota-türü olaylarda her zaman "current" (ROUTE_CHANGE'in aynı
	# kısayolu - kervanın o an üstünde olduğu yol), şehir-türü olaylarda
	# "current" kervanın gittiği şehri işaret eder.
	WORLD_EVENT_START,
	# Oyuncu dışındaki en yaralı yoldaşı yolda bırakır (bkz. evt_leave_the_
	# wounded). Kervandan çıkar ama ölmez; defterde üstü çizili, sebebiyle.
	LEAVE_BEHIND,
	# Tek bir kişinin canı: amount +iyileştirir/-yaralar, text_value kimi
	# seçeceğini söyler: "weakest" (en yaralı yoldaş), bir stat adı
	# ("strength", "agility"...) = o statta en iyi olan, boş = lider. Olaylar
	# öldürmez - can en az 1'de kenetlenir (ölüm savaşın ve açlığın işi).
	PARTY_HP,
	# Ayni ödeme: kervanın bir borcundan `amount` altın düşer - yük, vagon ya
	# da hizmetle ödenen borç (bkz. evt_bailiffs_at_camp). Eksi bir GOLD
	# etkisi borcu azaltmaz, spend_or_owe üzerinden *artırır*; borcu kapatan
	# başka bir etki yoktu. Hiçbir zaman altın üretmez.
	DEBT_SETTLE,
	# Kıyafet ganimeti (görev Y-C03): text_value = parça kimliği, amount = adet;
	# GRANT_EQUIPMENT gibi önce dolaba düşer, kime giydirileceği sonra seçilir.
	GRANT_OUTFIT,
	# Uzun zincir (görev Y-E02): text_value = "zincir|aşama|nerede", amount =
	# en az kaç gün sonra. nerede: "other_city" (başladığı şehirden başka bir
	# şehre giden yolda), "city:<id>" (o şehre giden yolda), "heir" (sonraki
	# kuşakta), boş = her yerde. Karşılık kartı `chain_<id>_ripe`'a bakar.
	CHAIN_ADVANCE,
	# Kapısından bir daha girilemeyen yer (Y-C29). text_value = yer kimliği;
	# boşsa seferin hedefi.
	BAN_LOCATION,
	# Ticaret lekesi (Y-C26): `amount` gün boyunca pazarlar kervana pahalı
	# satar, ucuza alır - adın kötüye çıktı.
	TRADE_STAIN,
	# Şehrin hâli (Y-C21): `amount` kadar; seferdeyse varılacak şehrin, değilse bulunulanın.
	CITY_MORALE,
	# Avuçiçi'nde inançsızın eli kesilir (lore defter III, Ç14): kervanın El'e
	# inanmayan bir yoldaşı kalıcı olarak tek elli kalır. Olaylar öldürmez.
	CUT_HAND,
	# Hizip itibarı (Y-C12, T16-07): text_value hizip (Standing.GUILD/CHURCH/
	# BROTHERHOOD), amount değişim.
	FACTION,
	# Yolun reisi (N32, T16-09): text_value "paid" - kartta olan reise boyun
	# eğildi, çetesi büyür (People.chief_paid).
	CHIEF_MEMORY,
	# Pusu savaşı (kullanıcı kararı 2026-11-07): TRIGGER_COMBAT'ın aynısı, tek
	# farkı savaşın "pusuya düşülmüş" başlaması - ilk round'da düşman önce
	# oynar (bkz. CombatEncounter.ambushed). Blöfü tutmayan kervanın bedeli.
	# Ayrı bir tür, çünkü `text_value` kadro türünü taşıyor ve oraya ikinci
	# bir anlam sıkıştırmak ("bandit|ambush") kataloğu okunmaz yapardı.
	TRIGGER_AMBUSH,
	# Yük yağması (kullanıcı kararı 2026-11-07): yol kesenin para değil
	# **mal** istemesi. amount = yüzde pay (100 = hepsi), text_value "all"
	# ise bırakılan tek mal da bırakılmaz (bkz. GameSession.plunder_cargo).
	# Erzağa dokunmaz - kervanı yolda öldürmek yağmacının da işine gelmez.
	CARGO_PLUNDER,
	# Blöfün bedeli (kullanıcı kararı 2026-11-07): "elindeki bir malı bu çok
	# değerli diye onları kandırıp sadece o malı vererek diğer eşyalarını ve
	# canını kurtarabilir". Yükün **en ucuz** kalemini bir adet verir -
	# oyuncu neyi vereceğini seçmez, blöfün tuttuğu şey zaten en ucuzunun
	# değerli görünmesidir.
	CARGO_DECOY,
	# Bedeli adı olan birine yükler (Ahlak alt sistemi, tasarım notu
	# docs/design_notes/ahlak_ruh_iz_mimarisi.md §D-A2). amount = asıl etkinin
	# büyüklüğü, text_value = "<ALT_ETKI>|<kural>" (ör. "PARTY_HP|en_kirgin",
	# "STRESS|bagi_olan", "LEAVE_BEHIND|yemini_yok"). Kural adları
	# BedelSecici.RULES'ta; taşıyıcının adı kart açılmadan seçeneğin üstünde
	# yazar ve sonuç metninde {bedel} olarak geçer.
	# Niye PARTY_HP'nin seçicisini genişletmek yetmedi: o seçici yalnız
	# "weakest", bir stat adı ya da lider seçebiliyor; bağ, kırgınlık, yemin
	# ve geçmiş okunamıyordu - oysa hepsi kayıtta duruyor.
	BEDEL,
	# Dünyada vadeli bir iz bırakır (İz alt sistemi, tasarım notu §C.3/§D-İ1).
	# amount = şiddet × 100 (0 ise türün kendi başlangıcı), text_value =
	# "<tur>|<tasiyici_tip>|<gecikme>|<donus>[|<donus_karti>]" - ör.
	# "minnet|sehir|kisa|yuz", "kin|sehir|uzun|fiyat". Taşıyıcının kimliği
	# verilmez, yerinden okunur: şehir/kişi izinin kimliği bulunulan (ya da
	# gidilen) şehir, yol izininki o yol, bölge izininki o bölge.
	# Yön `amount`ın işaretidir: eksi şiddet kervanın aleyhine bir izdir.
	# Niye SET_FLAG + UNLOCK_EVENT yetmedi: bayrak taşıyıcı, şiddet, vade,
	# sönme ve yayılma taşımaz - yani bir hesap değil, bir anahtardır.
	IZ_BIRAK,
	# Kişinin Ruh eksenini oynatır (Ruh alt sistemi, §C.3/§D-R2).
	# amount = adım × 4 (1 = 0,25; eksi değer iyileştirir),
	# text_value = "<eksen>|<kim>": eksen `kabuk`/`catlak`, kim `bedel`,
	# `lider`, `tanik`, `hepsi`. Stres uçucudur (handa bir gece siler),
	# huy ani ve ikilidir; eksen yavaştır ve yalnız doğru şeyle geri döner.
	RUH,
	# Vadeli bir söz açar (§C.3/§D-A5). amount = vade (gün), text_value =
	# "<kime tip>:<id>|<ne>|<miktar>" - ne: erzak, altin, teslim, donus.
	# Bugünkü sözler bayrak: vadesi, tanığı ve bozulunca yayılması yok
	# (teşhis A15). Söz bu dünyada bir sicildir (lore §12.4).
	SOZ,
}

@export var type: Type = Type.GOLD
@export var amount: int = 0
## item_id / flag adı / event_id gibi metinsel hedefler için.
@export var text_value: String = ""

static func make(type: Type, amount: int = 0, text_value: String = "") -> EventEffect:
	var effect := EventEffect.new()
	effect.type = type
	effect.amount = amount
	effect.text_value = text_value
	return effect
