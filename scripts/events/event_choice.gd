class_name EventChoice
extends Resource

## EU4'teki "option" bloğu. requirements sağlanmazsa seçenek gizlenmez,
## gerekçesiyle birlikte devre dışı gösterilir: oyuncu kaçırdığı
## imkânı görsün, bir dahaki sefere ona göre hazırlansın.

@export var text_key: String = ""
@export var requirements: Array[EventCondition] = []
@export var unavailable_text_key: String = ""
## Seçenek seçilir seçilmez uygulanan, garantili etkiler.
@export var effects: Array[EventEffect] = []
## Boş değilse: koşulu sağlayanlar arasından ağırlıklı bir sonuç seçilir.
@export var outcomes: Array[EventOutcome] = []

func is_available(context: Dictionary) -> bool:
	return EventCondition.are_all_met(requirements, context)

static func make(text_key: String, effects: Array[EventEffect]) -> EventChoice:
	var choice := EventChoice.new()
	choice.text_key = text_key
	choice.effects = effects
	return choice
