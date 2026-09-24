extends Control

## Parti ekranı: kimler yanında, ne kadar dayanıklılar, hangi mevkide
## duruyorlar. Sıralama savaştaki mevki sırasıdır (1 = en önde), bu yüzden
## burada sıra değiştirmek savaşı doğrudan etkiler.
##
## Tayfa toplama burada değil - o mekâna bağlı (bkz. RecruitPanel). Burası
## eldekini görüp düzenlediğin yer.

const HINT_COLOR: Color = Color(0.7, 0.72, 0.78)
const PERK_COLOR: Color = Color(0.75, 0.85, 1.0)
const HURT_COLOR: Color = Color(0.9, 0.55, 0.45)
const LOCKED_COLOR: Color = Color(0.6, 0.6, 0.6)
## Sıralama tuşları kare: içlerindeki ikon çizim, metin değil, o yüzden
## genişliği metin belirlemiyor - kendi yerini istemesi gerekiyor.
const MOVE_BUTTON_SIZE: float = 34.0

var _session: GameSession

@onready var _info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	$MarginContainer/VBoxContainer/TitleLabel.text = tr("UI_PARTY_TITLE")
	_session = GameState.get_session()
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_back_button.text = Nav.back_label()
	_back_button.pressed.connect(_on_back_pressed)
	_refresh()

func _refresh() -> void:
	var party := _session.get_party()
	_info_label.text = tr("UI_PARTY_HINT") % [
		party.size(),
		_session.get_party_capacity(),
		_session.owned_wagon_count,
	]

	_clear_children(_content)
	_content.add_child(_build_ledger())
	for index in party.size():
		_content.add_child(_build_member_card(party[index], index, party.size()))

## Kervan defteri: kim geldi, kim gitti, kim öldü, liderlik kime geçti.
##
## **Ayrılan bir isim silinmiyor, üstü çiziliyor** (bkz. CaravanLedger).
## Parti listesinin üstünde duruyor çünkü kervanın kim olduğu sorusunun
## cevabı yalnızca şu an yanında yürüyenler değil - buraya kadar kimlerle
## geldiğin de o cevabın parçası.
const LEDGER_RECENT_LIMIT: int = 8
const STRUCK_COLOR: Color = Color(0.55, 0.52, 0.55)

func _build_ledger() -> VBoxContainer:
	var box := VBoxContainer.new()

	var title := Label.new()
	title.text = tr("UI_LEDGER_TITLE")
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)

	var heading := Label.new()
	heading.text = tr("UI_LEDGER_GENERATION") % [
		_session.lineage_generation, _session.get_caravan_name()
	]
	heading.modulate = PERK_COLOR
	box.add_child(heading)

	var entries := _session.ledger.recent(LEDGER_RECENT_LIMIT)
	if entries.is_empty():
		var empty := Label.new()
		empty.text = tr("UI_LEDGER_EMPTY")
		empty.modulate = HINT_COLOR
		box.add_child(empty)
		return box

	for entry in entries:
		var line := Label.new()
		# Sebebi olan satır kendi cümlesini taşıyor ("... kurtlara düştü,
		# Kurtboğazı yakınlarında"); olmayan eski biçimde kalıyor.
		if String(entry.get("cause", "")).is_empty():
			line.text = "%s · %s — %s" % [
				tr("UI_LEDGER_DAY") % int(entry.get("day", 0)),
				String(entry.get("name", "")),
				CaravanLedger.get_kind_label(String(entry.get("kind", ""))),
			]
		else:
			line.text = CaravanLedger.describe(entry)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD
		# Üstü çizili satır soluk: kaybın kaydı duruyor ama artık
		# yanında yürüyen biri değil.
		if _session.ledger.is_struck(entry):
			line.modulate = STRUCK_COLOR
		box.add_child(line)

	return box

func _build_member_card(character: CharacterData, index: int, party_size: int) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 4)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)

	var portrait := ColorRect.new()
	portrait.color = CharacterData.get_skin_tone_color(character.skin_tone)
	portrait.custom_minimum_size = Vector2(28, 28)
	header.add_child(portrait)

	var name_label := Label.new()
	name_label.text = "%d. %s" % [index + 1, character.get_summary_line()]
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.custom_minimum_size = Vector2(460, 0)
	header.add_child(name_label)

	# Oyuncunun kendisi çıkarılamaz ama her mevkiye geçebilir; bu yüzden
	# kontrol sıraya değil is_player bayrağına bakıyor.
	if index > 0:
		header.add_child(_build_move_button(UiIcon.Kind.CHEVRON_UP, index, index - 1))
	if index < party_size - 1:
		header.add_child(_build_move_button(UiIcon.Kind.CHEVRON_DOWN, index, index + 1))

	var character_button := Button.new()
	character_button.text = tr("UI_PARTY_OPEN_CHARACTER")
	character_button.pressed.connect(_on_character_pressed.bind(index))
	header.add_child(character_button)

	if character.is_player:
		var you_label := Label.new()
		you_label.text = tr("UI_PARTY_YOU")
		you_label.modulate = LOCKED_COLOR
		header.add_child(you_label)
	else:
		var dismiss_button := Button.new()
		dismiss_button.text = tr("UI_DISMISS")
		dismiss_button.pressed.connect(_on_dismiss_pressed.bind(character))
		header.add_child(dismiss_button)

	card.add_child(header)

	var hp_label := Label.new()
	hp_label.text = tr("UI_PARTY_MEMBER") % [
		character.level, character.current_hp, character.get_max_hp(), character.get_appearance_line()
	]
	if character.current_hp < character.get_max_hp():
		hp_label.modulate = HURT_COLOR
	card.add_child(hp_label)

	var stats_label := Label.new()
	stats_label.text = _stats_line(character)
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	card.add_child(stats_label)

	var derived_label := Label.new()
	derived_label.text = tr("UI_STATLINE") % [
		character.stats.get_initiative(),
		character.get_accuracy(),
		character.get_dodge(),
		character.get_crit_chance(),
		character.get_damage_bonus(),
	]
	derived_label.modulate = HINT_COLOR
	card.add_child(derived_label)

	var perk_label := Label.new()
	perk_label.text = character.get_culture().perk_text
	perk_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	perk_label.modulate = PERK_COLOR
	card.add_child(perk_label)

	for skill in character.get_skills():
		card.add_child(_build_skill_label(skill, index + 1))

	card.add_child(HSeparator.new())
	return card

## Yön oku bir *karakter* değil, çizim: `↑`/`↓` varsayılan fontta yok ve
## bu iki tuş ekranda boş kutu olarak duruyordu (bkz. `UiIcon`). İkon
## tuşun içine çocuk olarak giriyor, çünkü `Button.icon` bir `Texture2D`
## istiyor - elimizde doku değil bir `_draw()` var.
func _build_move_button(icon_kind: int, from_index: int, to_index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(MOVE_BUTTON_SIZE, 0.0)
	button.pressed.connect(_on_move_pressed.bind(from_index, to_index))
	button.tooltip_text = tr(
		"UI_PARTY_MOVE_UP" if icon_kind == UiIcon.Kind.CHEVRON_UP else "UI_PARTY_MOVE_DOWN"
	)

	var icon := UiIcon.new()
	icon.setup(icon_kind, ArtPalette.GOLD)
	button.add_child(icon)
	icon.fill_parent()
	return button

## Yetenek bu mevkiden kullanılamıyorsa gizlenmiyor, sebebiyle
## gösteriliyor - savaş panelindeki kuralın aynısı.
func _build_skill_label(skill: CombatSkill, position: int) -> Label:
	var label := Label.new()
	label.text = "  • %s (%s)" % [skill.display_name, skill.get_position_summary()]
	if not skill.can_use_from(position):
		label.text += tr("UI_COMBAT_BAD_POSITION")
		label.modulate = LOCKED_COLOR
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	return label

func _stats_line(character: CharacterData) -> String:
	var parts: Array[String] = []
	for kind in CharacterStats.KIND_ORDER:
		parts.append("%s %d" % [
			CharacterStats.kind_name(kind), character.stats.get_value(kind)
		])
	return " · ".join(parts)

func _on_move_pressed(from_index: int, to_index: int) -> void:
	if _session.swap_party_positions(from_index, to_index):
		_refresh()

func _on_dismiss_pressed(character: CharacterData) -> void:
	if _session.dismiss(character):
		_refresh()

## Karakter ekranı yalnızca buradan açılıyor ve buraya dönüyor - dönüş
func _on_character_pressed(index: int) -> void:
	Nav.character_target_index = index
	get_tree().change_scene_to_file(Nav.open(Nav.PARTY, Nav.CHARACTER))

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.back())
