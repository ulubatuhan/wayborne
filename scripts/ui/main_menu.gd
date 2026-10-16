extends Control

## Girişte seçilen dil tüm oyun için geçerli olur (bkz. scripts/ui/settings.gd
## - dil seçici artık burada değil, Ayarlar ekranında).
##
## Tayfa büyüklüğü ve karakterin kendisi artık burada değil, karakter
## oluşturma ekranında seçiliyor - "Yeni Oyun" oraya gider, oturum da
## orada kurulur.
##
## **Ekran bir gece kampı** (bkz. GrimDrafts.title): vagon, çadır, tek kamp
## ateşi; sağda koyu bir şerit - başlık, kervanın soy satırı (adı, kaçıncı
## kuşak olduğu, kaçıncı gün) ve kutusuz, mürekkep lekeli menü. Eskiden
## burada açılan bir defter vardı (kapak, sonra açık sayfa); oyunun asıl
## kaydı soy olduğu için onun yerini soy satırı aldı.
##
## **Bir "bir tuşa basın" evresiyle açılıyor, ayrı bir sahne olarak değil.**
## Sahne değişmeden yaşanan bir geçiş: önce yalnızca kamp ve nabız gibi atan
## bir davet metni, ilk girdide (klavye/fare/kol/dokunmatik fark etmez) aynı
## sahnede şerit beliriyor. Evre yalnızca **süreç içi** bir kez yaşanıyor -
## `_title_shown_this_run` bir statik değişken, yoksa Ayarlar'dan geri dönmek
## bile oyuncuyu yeniden "bir tuşa bas" ekranına düşürürdü.
##
## Kökün `mouse_filter`'ı `IGNORE` (bkz. `main_menu.tscn`): tam ekran bir kök
## `STOP`'ta kalırsa fare tıklaması ve dokunuş `_unhandled_input`'a hiç
## ulaşmıyor, klavye ise ulaşıyordu - "telefonda geçemiyorum" hatası buydu.

## Davet metninin nabız hızı ve parlaklık aralığı.
const PROMPT_PULSE_SECONDS: float = 1.35
const PROMPT_DIM_ALPHA: float = 0.35
const PROMPT_FONT_SIZE: int = 26
const PROMPT_GLOW_ALPHA: float = 0.6
const PROMPT_GLOW_SIZE: int = 14
const PROMPT_OUTLINE_SIZE: int = 2

const REVEAL_SECONDS: float = 0.45
const REVEAL_SLIDE_PX: float = 40.0

const ENTRY_CONTINUE: String = "UI_CONTINUE"
const ENTRY_PLAY: String = "UI_GRIM_NEW_LINEAGE"
const ENTRY_SAVES: String = "UI_MAIN_MENU_SAVES"
const ENTRY_SETTINGS: String = "UI_SETTINGS"
const ENTRY_QUIT: String = "UI_QUIT"

static var _title_shown_this_run: bool = false

var _entries: Array = []
var _scene: Control
var _strip: Control
var _menu: InkMenu
var _confirm_dialog: ConfirmationDialog
var _prompt_label: Label
var _prompt_tween: Tween
var _in_title_phase: bool = false

func _ready() -> void:
	Nav.go_root(Nav.MAIN_MENU)
	_entries = menu_entries(SaveManager.has_save(), SaveManager.has_any_save())
	_scene = GrimDrafts.title(-1, lineage(), _entries)
	add_child(_scene)
	# Kök sahneye eklendikten sonra boyut verilmezse (0,0) kalır (anchor tuzağı).
	_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scene.size = size
	_strip = _scene.get_meta("strip")
	_menu = _strip.get_meta("menu")
	_menu.chosen.connect(_on_entry_chosen)
	if _title_shown_this_run:
		_show_menu_immediately()
	else:
		_begin_title_phase()

## Hangi girdiler görünür: "Devam Et" yalnızca otomatik kayıt varsa, "Kayıtlar"
## yalnızca herhangi bir kayıt varsa - boş bir liste açmanın anlamı yok.
static func menu_entries(has_autosave: bool, has_any_save: bool) -> Array:
	var keys: Array = []
	if has_autosave:
		keys.append(ENTRY_CONTINUE)
	keys.append(ENTRY_PLAY)
	if has_any_save:
		keys.append(ENTRY_SAVES)
	keys.append(ENTRY_SETTINGS)
	keys.append(ENTRY_QUIT)
	return keys

## Şeridin soy satırı: bu adı kim taşıyor. Otomatik kayıt yoksa satır yok.
static func lineage() -> Dictionary:
	var summary := SaveManager.get_summary(SaveManager.AUTOSAVE_SLOT)
	if summary.is_empty() or String(summary.get("caravan_name", "")).is_empty():
		return {}
	return {
		"name": String(summary["caravan_name"]),
		"generation": int(summary.get("lineage_generation", 1)),
		"day": int(summary.get("total_days_elapsed", 0)) + 1,
	}

## --- "Bir tuşa basın" evresi ---

## Şerit saydam ve tıklanamaz, yalnızca kamp ve davet metni görünür. Müzik
## henüz yok - rüzgar çalıyor, ilk girdiye kadar tek ses o. `visible`
## yerine `modulate:a` kullanılıyor: görünmez bir kap çocuklarını dizmiyor,
## belirdiği karede menü üst üste binmiş açılıyordu (ölçüldü).
func _begin_title_phase() -> void:
	_in_title_phase = true
	_strip.modulate.a = 0.0
	_set_menu_mouse_ignore(true)
	set_process_unhandled_input(true)

	_prompt_label = Label.new()
	_prompt_label.text = tr("UI_TITLE_PROMPT")
	_prompt_label.label_settings = _build_prompt_label_settings()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.position.y -= 64.0
	_prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prompt_label)

	_prompt_tween = create_tween()
	_prompt_tween.set_loops()
	_prompt_tween.tween_property(_prompt_label, "modulate:a", PROMPT_DIM_ALPHA, PROMPT_PULSE_SECONDS)
	_prompt_tween.tween_property(_prompt_label, "modulate:a", 1.0, PROMPT_PULSE_SECONDS)

	AudioManager.play_ambience(AudioManager.AMBIENCE_WIND)

func _build_prompt_label_settings() -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font_size = PROMPT_FONT_SIZE
	settings.font_color = ArtPalette.GRIM_PARCHMENT
	settings.outline_size = PROMPT_OUTLINE_SIZE
	settings.outline_color = Color(ArtPalette.INK, 0.7)
	settings.shadow_size = PROMPT_GLOW_SIZE
	settings.shadow_offset = Vector2.ZERO
	settings.shadow_color = Color(ArtPalette.GRIM_AMBER, PROMPT_GLOW_ALPHA)
	return settings

func _show_menu_immediately() -> void:
	AudioManager.play_track(AudioManager.TRACK_ROAD)
	_strip.modulate.a = 1.0
	_set_menu_mouse_ignore(false)

## Başlık evresinde menü satırları da fareyi görmemeli, yoksa tık satırın
## üstünde yutulur ve geçişi başlatmaz (tuş basımı bu yoldan hiç geçmiyor).
func _set_menu_mouse_ignore(ignore: bool) -> void:
	var filter := Control.MOUSE_FILTER_IGNORE if ignore else Control.MOUSE_FILTER_STOP
	for row in _menu.get_children():
		(row as Control).mouse_filter = filter

## Başlık evresinde ilk girdi geçişi başlatır; menüde yukarı/aşağı vurguyu
## gezdirir, onay seçer (fareye ek olarak klavye ve kol).
func _unhandled_input(event: InputEvent) -> void:
	if _in_title_phase:
		var qualifies: bool = (
			(event is InputEventKey and event.pressed and not event.echo)
			or (event is InputEventJoypadButton and event.pressed)
			or (event is InputEventMouseButton and event.pressed)
			or (event is InputEventScreenTouch and event.pressed)
		)
		if qualifies:
			get_viewport().set_input_as_handled()
			_begin_transition()
		return
	if event.is_action_pressed("ui_down"):
		_menu.move_focus(1)
	elif event.is_action_pressed("ui_up"):
		_menu.move_focus(-1)
	elif event.is_action_pressed("ui_accept") and _menu.focused_index() >= 0:
		_on_entry_chosen(_menu.focused_index())
	else:
		return
	get_viewport().set_input_as_handled()

## Rüzgar sönerken yol müziği yükseliyor, davet metni soluyor, şerit sağdan
## süzülerek beliriyor - sahne değişmeden, kamp hiç kesilmeden.
func _begin_transition() -> void:
	_in_title_phase = false
	_title_shown_this_run = true

	AudioManager.play_sfx(AudioManager.SFX_THUD)
	AudioManager.stop_ambience()
	AudioManager.play_track(AudioManager.TRACK_ROAD)

	if _prompt_tween != null and _prompt_tween.is_valid():
		_prompt_tween.kill()
	var prompt := _prompt_label
	var fade_out := create_tween()
	fade_out.tween_property(prompt, "modulate:a", 0.0, 0.4)
	fade_out.tween_callback(prompt.queue_free)

	_set_menu_mouse_ignore(false)
	var home_x := _strip.position.x
	_strip.position.x = home_x + REVEAL_SLIDE_PX
	var reveal := create_tween().set_parallel(true)
	reveal.tween_property(_strip, "modulate:a", 1.0, REVEAL_SECONDS)
	reveal.tween_property(_strip, "position:x", home_x, REVEAL_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_entry_chosen(index: int) -> void:
	if _in_title_phase or index < 0 or index >= _entries.size():
		return
	match String(_entries[index]):
		ENTRY_CONTINUE:
			_on_continue_pressed()
		ENTRY_PLAY:
			_on_play_pressed()
		ENTRY_SAVES:
			SceneInk.go(Nav.open(Nav.MAIN_MENU, Nav.SAVES))
		ENTRY_SETTINGS:
			SceneInk.go(Nav.open(Nav.MAIN_MENU, Nav.SETTINGS))
		ENTRY_QUIT:
			get_tree().quit()

func _on_continue_pressed() -> void:
	var session = SaveManager.load_session()
	if session == null:
		return
	GameState.set_session(session)
	# Sefer ortasında alınmış bir otomatik kayıt yola döner (bkz. Nav.resume_scene).
	SceneInk.go(Nav.resume_scene(session))

func _on_play_pressed() -> void:
	if SaveManager.has_save():
		_confirm_new_game()
	else:
		_open_character_creation()

func _confirm_new_game() -> void:
	if _confirm_dialog == null:
		_confirm_dialog = ConfirmationDialog.new()
		_confirm_dialog.confirmed.connect(_open_character_creation)
		add_child(_confirm_dialog)
	_confirm_dialog.dialog_text = tr("UI_NEW_GAME_CONFIRM")
	_confirm_dialog.popup_centered()

## Kayıt yalnızca karakter oluşturma tamamlanınca silinir; oyuncu geri
## dönerse eski kaydı yerinde durur.
func _open_character_creation() -> void:
	SceneInk.go(Nav.open(Nav.MAIN_MENU, Nav.CHARACTER_CREATION))
