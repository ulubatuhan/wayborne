extends Control

## Girişte seçilen dil tüm oyun için geçerli olur.
const LOCALES: Array[String] = ["tr", "en"]
const LOCALE_NAMES: Array[String] = ["Türkçe", "English"]

## Yeni oyunda parti büyüklüğü vagon sayısını belirler: her vagonda en
## fazla iki kişi kalır, kalan kişi bir vagon daha gerektirir. Üst sınır
## (12 kişi) CaravanPlan.DEFAULT_MAX_WAGONS ile aynı vagon tavanına denk
## gelecek şekilde seçildi.
const MIN_PARTY_SIZE: int = 1
const MAX_PARTY_SIZE: int = 12
const PEOPLE_PER_WAGON: int = 2
const DEFAULT_STARTING_GOLD: int = 250
const DEFAULT_STARTING_PROVISIONS: int = 20

@onready var _continue_button: Button = $VBoxContainer/ContinueButton
@onready var _play_button: Button = $VBoxContainer/PlayButton
@onready var _party_size_spin: SpinBox = $VBoxContainer/PartyRow/PartySizeSpin
@onready var _party_wagon_label: Label = $VBoxContainer/PartyRow/PartyWagonLabel
@onready var _party_label: Label = $VBoxContainer/PartyRow/PartyLabel
@onready var _language_button: OptionButton = $VBoxContainer/LanguageRow/LanguageButton
@onready var _language_label: Label = $VBoxContainer/LanguageRow/LanguageLabel

var _confirm_dialog: ConfirmationDialog

func _ready() -> void:
	_continue_button.visible = SaveManager.has_save()
	_continue_button.pressed.connect(_on_continue_pressed)
	_play_button.pressed.connect(_on_play_pressed)

	_party_size_spin.min_value = MIN_PARTY_SIZE
	_party_size_spin.max_value = MAX_PARTY_SIZE
	_party_size_spin.value_changed.connect(_on_party_size_changed)

	_setup_language_selector()
	_refresh_party_wagon_label()

func _setup_language_selector() -> void:
	for i in range(LOCALES.size()):
		_language_button.add_item(LOCALE_NAMES[i], i)

	var current_locale := TranslationServer.get_locale().substr(0, 2)
	var selected := LOCALES.find(current_locale)
	_language_button.select(maxi(selected, 0))

	_language_button.item_selected.connect(_on_language_selected)
	_refresh_texts()

func _on_language_selected(index: int) -> void:
	if index < 0 or index >= LOCALES.size():
		return
	TranslationServer.set_locale(LOCALES[index])
	_refresh_texts()

func _refresh_texts() -> void:
	_language_label.text = tr("UI_LANGUAGE")
	_continue_button.text = tr("UI_CONTINUE")
	_play_button.text = tr("UI_PLAY")
	_party_label.text = tr("UI_PARTY_SIZE")
	_refresh_party_wagon_label()

func _on_party_size_changed(_value: float) -> void:
	_refresh_party_wagon_label()

func _refresh_party_wagon_label() -> void:
	var wagons := _wagons_for_party_size(int(_party_size_spin.value))
	_party_wagon_label.text = tr("UI_PARTY_WAGON_NOTE") % wagons

func _wagons_for_party_size(party_size: int) -> int:
	var wagons := ceili(float(party_size) / float(PEOPLE_PER_WAGON))
	return clampi(wagons, CaravanState.MIN_WAGONS, CaravanPlan.DEFAULT_MAX_WAGONS)

func _on_continue_pressed() -> void:
	var session = SaveManager.load_session()
	if session == null:
		return
	GameState.set_session(session)
	Nav.return_scene = Nav.CITY_MAP
	get_tree().change_scene_to_file(Nav.CITY_MAP)

func _on_play_pressed() -> void:
	if SaveManager.has_save():
		_confirm_new_game()
	else:
		_start_new_game()

func _confirm_new_game() -> void:
	if _confirm_dialog == null:
		_confirm_dialog = ConfirmationDialog.new()
		_confirm_dialog.confirmed.connect(_start_new_game)
		add_child(_confirm_dialog)
	_confirm_dialog.dialog_text = tr("UI_NEW_GAME_CONFIRM")
	_confirm_dialog.popup_centered()

func _start_new_game() -> void:
	SaveManager.delete_save()
	var wagon_count := _wagons_for_party_size(int(_party_size_spin.value))
	GameState.start_new_game(DEFAULT_STARTING_GOLD, DEFAULT_STARTING_PROVISIONS, wagon_count)
	Nav.return_scene = Nav.WORLD_HUB
	get_tree().change_scene_to_file(Nav.WORLD_HUB)
