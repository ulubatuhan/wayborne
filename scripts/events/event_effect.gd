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
