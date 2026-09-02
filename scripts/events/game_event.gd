class_name GameEvent
extends Resource

## EU4 olay kartının karşılığı: koşullu uygunluk (trigger), ağırlık
## değiştiricileri (MTTH modifier mantığı), anında etkiler ve seçenekler.

enum Category {
	ROAD,
	CHAIN,
}

@export var event_id: String = ""
@export var title_key: String = ""
@export var text_key: String = ""
@export var category: Category = Category.ROAD

## Havuzdan çekilme ağırlığı. weight_modifiers ile bağlama göre ölçeklenir.
@export var base_weight: float = 1.0
@export var weight_modifiers: Array[EventWeightModifier] = []

## Uygunluk koşulları (EU4 "trigger").
@export var conditions: Array[EventCondition] = []

## true ise oyun boyunca yalnızca bir kez çıkar.
@export var fire_only_once: bool = false
## Tekrar çıkabilmesi için geçmesi gereken gün sayısı (0 = beklemesiz).
@export var cooldown_days: int = 0
## true ise havuzdan rastgele çekilmez, yalnızca UNLOCK_EVENT ile açılır.
@export var triggered_only: bool = false

## Kart gösterilir gösterilmez, oyuncu seçim yapmadan uygulanan etkiler.
@export var immediate_effects: Array[EventEffect] = []

@export var choices: Array[EventChoice] = []

## Kart çıkınca partiye (oyuncu karakterine) verilen XP. Katalogdaki
## olayların çoğu bu varsayılanı kullanır, tek tek ayarlanmamış.
@export var xp_value: int = 10

func is_eligible(context: Dictionary) -> bool:
	return EventCondition.are_all_met(conditions, context)

func get_weight(context: Dictionary) -> float:
	var weight := base_weight
	for modifier in weight_modifiers:
		if modifier.applies(context):
			weight *= modifier.multiplier
	return maxf(weight, 0.0)
