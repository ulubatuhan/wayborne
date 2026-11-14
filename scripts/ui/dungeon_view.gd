class_name DungeonView
extends Control

## Galeride iken yol manzarasının yerine geçen görünüş (Y-A07 derinleşme):
## bulunulan seviyenin bölge resmi (savaşla aynı resim, `CombatBackdrop`) ve
## önünde meşalenin ışığında duran kadro. Kervan ağızda kaldığı için yolun
## şeridi, kervan ve hava burada görünmez; kart, harita ve savaş bunun üstüne
## açılır.
##
## Kadro savaş figürüyle çizilir (`CombatFigure`): yolda nasıl görünüyorsa
## galeride ve savaşta da öyle (Art Rules: bir şekil iki yerde iki şekildir).

const FIGURE_SIZE: Vector2 = Vector2(150.0, 290.0)
## Ayakların bastığı çizgi (yüksekliğin payı): savaştaki kadroyla aynı yer.
const FEET_LINE: float = 0.60
## Kadronun ortası (enin payı): meşale ortada, kadro onu taşıyor.
const PARTY_CENTRE: float = 0.42

var _backdrop: CombatBackdrop
var _figures: Control
var _look: String = ""
var _party_ids: Array = []

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_backdrop = CombatBackdrop.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)
	_figures = Control.new()
	_figures.set_anchors_preset(Control.PRESET_FULL_RECT)
	_figures.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_figures)
	resized.connect(_place)

## `look`: "<ağız>_<bölge>" (DungeonMap.look). Boşsa görünüş gizlenir.
func show_for(look: String, party: Array[CharacterData]) -> void:
	visible = not look.is_empty()
	if look != _look:
		_look = look
		_backdrop.biome = CombatBackdrop.DUNGEON_PREFIX + look
	var ids: Array = []
	for person in party:
		ids.append(person.character_id)
	if ids != _party_ids:
		_party_ids = ids
		_build_party(party)

func _build_party(party: Array[CharacterData]) -> void:
	for child in _figures.get_children():
		child.queue_free()
	for i in party.size():
		var person := party[i]
		var figure := CombatFigure.new()
		figure.size = FIGURE_SIZE
		figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var depth := float(i) / float(maxi(1, CombatEncounter.MAX_SIDE_SIZE - 1))
		figure.setup(person.class_id, true, "normal", depth, person.get_appearance_outfit(),
			Wardrobe.loadout_for(person), CharacterData.get_skin_tone_color(person.skin_tone),
			person.get_height_scale(), person.get_body_variant_id())
		figure.set_missing_hand(person.missing_hand)
		_figures.add_child(figure)
	_place()

## Kadro savaştaki gibi: önde lider sağda, arkadakiler solda.
func _place() -> void:
	var count := _figures.get_child_count()
	var step := FIGURE_SIZE.x * 1.05
	var right := size.x * PARTY_CENTRE + step * float(count - 1) * 0.5
	for i in count:
		var figure := _figures.get_child(i) as Control
		figure.position = Vector2(right - step * float(i) - FIGURE_SIZE.x * 0.5, size.y * FEET_LINE - FIGURE_SIZE.y)
