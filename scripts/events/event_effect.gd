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
	MERCHANT_LEAVE,
	MORALE,
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
