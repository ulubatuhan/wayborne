class_name SaveSlotsPanel
extends VBoxContainer

## Kayıt yuvalarının listesi. `DebtPanel`/`PurificationPanel` deseni:
## sahnesiz, `.new()` ile kurulur, iki farklı yerden aynı bileşen
## kullanılır - ana menüdeki `saves.tscn` bunu tek başına gösterir,
## `InGameMenu` da aynısını kendi içine gömer. İki ayrı liste yazmak
## demek yuva numaralandırmasının er ya da geç birbirinden sapması
## demekti (bkz. `CaravanPlan.daily_consumption()`'ın aynı gerekçesi).
##
## Yuva 0 her zaman otomatik kayıt - elle üstüne yazılmaz, yalnızca
## Yükle/Sil sunar. Diğer yuvalar `can_save` doğruysa "Buraya Kaydet"
## de sunar; sefer sürerken (`can_save = false`) hiçbiri sunmaz, çünkü
## `SaveManager.save_session` sefer alanlarını hiç taşımıyor - o an
## yazmak sefer bilgisini sessizce kaybettirir (bkz. SaveManager'ın
## başındaki not).

## Bir yuva değiştiğinde (kaydedildi/silindi) ya da yüklenip sahne
## değişmesi gerektiğinde. `loaded` sahne değişimini çağırana bırakıyor:
## bu bileşen `change_scene_to_file` çağırmıyor, çünkü aynı bileşen bir
## overlay'in içinde de yaşıyor olabilir.
signal loaded(session)
signal changed

const ROW_SEPARATION: float = 6.0

var _can_save: bool = true
var _rows: VBoxContainer
var _note_label: Label

func setup(can_save: bool) -> void:
	_can_save = can_save
	_ensure_built()
	refresh()

func _ensure_built() -> void:
	if _rows != null:
		return
	add_theme_constant_override("separation", 8)

	_note_label = Label.new()
	_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_note_label.visible = false
	add_child(_note_label)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", ROW_SEPARATION)
	add_child(_rows)

func refresh() -> void:
	_ensure_built()
	_note_label.visible = not _can_save
	if not _can_save:
		_note_label.text = tr("UI_SAVES_CANT_SAVE_JOURNEY")

	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()

	for slot in SaveManager.SLOT_COUNT:
		_rows.add_child(_build_row(slot))

func _build_row(slot: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var summary := SaveManager.get_summary(slot)
	var label := Label.new()
	label.custom_minimum_size = Vector2(420, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.text = _row_text(slot, summary)
	row.add_child(label)

	var occupied := not summary.is_empty()
	var is_autosave := slot == SaveManager.AUTOSAVE_SLOT

	if _can_save and not is_autosave:
		var save_button := Button.new()
		save_button.text = tr("UI_SAVES_SAVE_HERE")
		save_button.pressed.connect(_on_save_pressed.bind(slot))
		row.add_child(save_button)

	var load_button := Button.new()
	load_button.text = tr("UI_SAVES_LOAD")
	load_button.disabled = not occupied
	load_button.pressed.connect(_on_load_pressed.bind(slot))
	row.add_child(load_button)

	if not is_autosave:
		var delete_button := Button.new()
		delete_button.text = tr("UI_SAVES_DELETE")
		delete_button.disabled = not occupied
		delete_button.pressed.connect(_on_delete_pressed.bind(slot))
		row.add_child(delete_button)

	return row

func _row_text(slot: int, summary: Dictionary) -> String:
	var slot_name := tr("UI_SAVES_SLOT_AUTOSAVE") if slot == SaveManager.AUTOSAVE_SLOT \
		else tr("UI_SAVES_SLOT_MANUAL") % slot
	if summary.is_empty():
		return "%s — %s" % [slot_name, tr("UI_SAVES_EMPTY")]

	var location := WorldMapData.get_location_by_id(String(summary.get("current_location_id", "")))
	var location_name := tr("UI_CITY_FALLBACK_NAME") if location == null else location.location_name
	var caravan_name := String(summary.get("caravan_name", ""))
	if caravan_name.is_empty():
		caravan_name = tr("UI_CITY_FALLBACK_NAME")
	return "%s — %s" % [slot_name, tr("UI_SAVES_ROW") % [
		caravan_name,
		int(summary.get("lineage_generation", 1)),
		int(summary.get("total_days_elapsed", 0)),
		int(summary.get("gold", 0)),
		location_name,
	]]

func _on_save_pressed(slot: int) -> void:
	SaveManager.save_session(GameState.get_session(), slot)
	refresh()
	changed.emit()

func _on_load_pressed(slot: int) -> void:
	var session = SaveManager.load_session(slot)
	if session == null:
		return
	loaded.emit(session)

func _on_delete_pressed(slot: int) -> void:
	SaveManager.delete_save(slot)
	refresh()
	changed.emit()
