class_name RecruitPanel
extends VBoxContainer

## "Partiye Kat" bölümü. Taverna, lonca ve pazar meydanı aynı paneli
## kurar, yalnızca mekân kimliği değişir - aday havuzunu ve ücret
## eğilimini RecruitCatalog belirler.
##
## Panel kendini kodda kurar (bkz. HagglingPanel/CombatPanel deseni), bu
## yüzden ekranların .tscn dosyalarına düğüm eklemeye gerek yok.

signal party_changed()

const HINT_COLOR: Color = Color(0.7, 0.72, 0.78)
const LOCKED_COLOR: Color = Color(0.65, 0.6, 0.55)

var _session: GameSession
var _venue: String = RecruitCatalog.VENUE_TAVERN

var _title_label: Label
var _info_label: Label
var _party_list: VBoxContainer
var _candidate_list: VBoxContainer
var _built: bool = false

func setup(session: GameSession, venue: String, title: String) -> void:
	_ensure_built()
	_session = session
	_venue = venue
	_title_label.text = title
	refresh()

func refresh() -> void:
	if _session == null:
		return

	_clear_children(_party_list)
	var slot := 1
	for character in _session.get_party():
		_party_list.add_child(_build_party_row(character, slot))
		slot += 1

	_clear_children(_candidate_list)
	var required_reputation := RecruitCatalog.get_venue_required_reputation(_venue)
	if _session.reputation < required_reputation:
		_info_label.text = "Buradakiler tanımadıkları kimseyle yola çıkmaz. Gereken itibar: %d (senin: %d)" % [
			required_reputation, _session.reputation
		]
		return

	var candidates := _session.get_recruit_candidates(_venue)
	if candidates.is_empty():
		_info_label.text = "Şu an burada yola çıkmak isteyen kimse yok."
		return

	_info_label.text = "Parti %d/%d · %d vagon. Her vagonda iki kişi yatar; savaş alanı da dört mevkiden ibaret." % [
		_session.get_party().size(),
		_session.get_party_capacity(),
		_session.owned_wagon_count,
	]
	for candidate in candidates:
		_candidate_list.add_child(_build_candidate_row(candidate))

func _ensure_built() -> void:
	if _built:
		return
	_built = true

	add_theme_constant_override("separation", 6)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 18)
	add_child(_title_label)

	_info_label = Label.new()
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_info_label.modulate = HINT_COLOR
	add_child(_info_label)

	var party_title := Label.new()
	party_title.text = "Partin"
	add_child(party_title)

	_party_list = VBoxContainer.new()
	add_child(_party_list)

	_candidate_list = VBoxContainer.new()
	add_child(_candidate_list)

func _build_party_row(character: CharacterData, slot: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "%d. %s (sv. %d) — can %d · %s" % [
		slot, character.get_summary_line(), character.level, character.get_max_hp(), character.get_appearance_line()
	]
	label.custom_minimum_size = Vector2(520, 0)
	row.add_child(label)

	if slot > 1:
		var up_button := Button.new()
		up_button.text = "↑"
		up_button.pressed.connect(_on_move_up_pressed.bind(slot - 1))
		row.add_child(up_button)

	# Oyuncunun kendisi çıkarılamaz; kontrol sıraya değil bayrağa bakıyor.
	if not character.is_player:
		var dismiss_button := Button.new()
		dismiss_button.text = "Yol Ver"
		dismiss_button.pressed.connect(_on_dismiss_pressed.bind(character))
		row.add_child(dismiss_button)

	return row

func _build_candidate_row(candidate: CharacterData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "%s (sv. %d) — can %d · isabet %d · kaçınma %d — %d GG" % [
		candidate.get_summary_line(),
		candidate.level,
		candidate.get_max_hp(),
		candidate.stats.get_accuracy(),
		candidate.get_dodge(),
		candidate.hire_cost,
	]
	label.custom_minimum_size = Vector2(520, 0)
	row.add_child(label)

	var hire_button := Button.new()
	# Kilitli seçenek gizlenmez, sebebiyle gösterilir.
	if not _session.can_recruit():
		if _session.get_party_capacity() < GameSession.MAX_PARTY_SIZE:
			hire_button.text = "Vagonlarında yer yok"
		else:
			hire_button.text = "Parti dolu"
		hire_button.disabled = true
		hire_button.modulate = LOCKED_COLOR
	elif not _session.wallet.can_afford(candidate.hire_cost):
		hire_button.text = "Kese yetmiyor"
		hire_button.disabled = true
		hire_button.modulate = LOCKED_COLOR
	else:
		hire_button.text = "Partiye Kat"
		hire_button.pressed.connect(_on_hire_pressed.bind(candidate))
	row.add_child(hire_button)

	return row

func _on_hire_pressed(candidate: CharacterData) -> void:
	if _session.hire_recruit(_venue, candidate):
		refresh()
		party_changed.emit()

func _on_dismiss_pressed(character: CharacterData) -> void:
	if _session.dismiss(character):
		refresh()
		party_changed.emit()

func _on_move_up_pressed(index: int) -> void:
	if _session.swap_party_positions(index, index - 1):
		refresh()
		party_changed.emit()

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
