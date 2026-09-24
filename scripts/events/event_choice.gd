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

## Faz 17: null ise seçenek eskisi gibi deterministik kalır - hiçbir mevcut
## olay bundan etkilenmiyor. Doluysa `outcomes`'un ağırlıklı çekimi artık
## bu zarın sonucuna (context'teki "check_tier") koşullu olabilir - bkz.
## EventEngine.resolve_check().
@export var check: SkillCheck

func is_available(context: Dictionary) -> bool:
	return EventCondition.are_all_met(requirements, context)

## Butonun üstünde gösterilecek "Zeka · %72" gibi bir önizleme - check
## yoksa boş döner. `stat_value` çağıran tarafından context'ten okunur
## (bkz. road_journey.gd), çünkü EventChoice bir Resource, GameSession'a
## bağımlı değil. Oyuncuya "kaç" statın olduğu değil, neye bahse girdiği
## gösteriliyor - Faz 12'nin tehlike-etiketiyle aynı okunabilirlik ailesi.
## `roller_name` verilirse zar isimli birine bağlanır ("Elif · Sezgi · %62").
func get_check_preview(stat_value: float, roller_name: String = "") -> String:
	if check == null:
		return ""
	var stat_label := CharacterStats.kind_name(check.stat)
	var chance := check.get_chance(stat_value)
	if roller_name.is_empty():
		return "%s · %%%d" % [stat_label, chance]
	return String(TranslationServer.translate("UI_CHECK_PREVIEW_NAMED")) % [roller_name, stat_label, chance]

func get_hint_text(best_stat_value: float) -> String:
	if hint_text_key.is_empty() or best_stat_value < hint_threshold:
		return ""
	return hint_text_key

static func make(text_key: String, effects: Array[EventEffect]) -> EventChoice:
	var choice := EventChoice.new()
	choice.text_key = text_key
	choice.effects = effects
	return choice
