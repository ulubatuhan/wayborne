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

## Karar önizlemesi: bu seçeneğin sonucu partinin Zeka'sına ya da
## Sezgi'sine bakılarak tahmin edilebiliyorsa (Fallout: New Vegas'ın
## skill-check önizlemesi gibi), buraya bir ipucu anahtarı ve eşiği
## yazılır - Faz 12'nin tehlike-etiketiyle aynı aile: seçmeden *önce*
## göster. `hint_text_key` boşsa hiçbir şey eklenmez, yani mevcut hiçbir
## olay bundan etkilenmiyor.
@export var hint_text_key: String = ""
@export var hint_stat: CharacterStats.Kind = CharacterStats.Kind.INTELLECT
@export var hint_threshold: float = 2.0

func is_available(context: Dictionary) -> bool:
	return EventCondition.are_all_met(requirements, context)

func get_hint_text(best_stat_value: float) -> String:
	if hint_text_key.is_empty() or best_stat_value < hint_threshold:
		return ""
	return hint_text_key

static func make(text_key: String, effects: Array[EventEffect]) -> EventChoice:
	var choice := EventChoice.new()
	choice.text_key = text_key
	choice.effects = effects
	return choice
