class_name GrimNotice
extends PanelContainer

## Kötü haber bir mürekkep lekesi değil, masaya atılmış bir kart: yırtık
## parşömen, hafif eğik, köşesinde damga. Üç tür var ve renk anlamı taşıyor:
## OMEN (alamet - kehribar damga), LOSS (kayıp - kan damga), GAIN (kazanç -
## yosun damga). Kart yukarıdan düşer ve oturur (`drop_offset`), sonra
## kendi süresinde solar (`fade_alpha`) - ikisi de statik ve saf.

enum Severity { OMEN, LOSS, GAIN }

const WIDTH: float = 360.0
const DROP_SECONDS: float = 0.35
const HOLD_SECONDS: float = 6.0
const FADE_SECONDS: float = 1.2
const DROP_HEIGHT: float = 26.0

var severity: Severity = Severity.OMEN
var _age: float = 0.0
var _tilt: float = 0.0
var _stamp: Label

func setup(title: String, body: String, kind: Severity, tilt_degrees: float = -1.5) -> GrimNotice:
	severity = kind
	_tilt = deg_to_rad(tilt_degrees)
	custom_minimum_size = Vector2(WIDTH, 0)
	add_theme_stylebox_override("panel", WaybookTheme.notice_panel())
	mouse_filter = Control.MOUSE_FILTER_PASS
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var t := WaybookTheme.label(title, WaybookTheme.HEADING_SIZE - 2, ArtPalette.INK, true)
	t.remove_theme_color_override("font_shadow_color")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.autowrap_mode = TextServer.AUTOWRAP_WORD
	head.add_child(t)
	_stamp = WaybookTheme.label(stamp_text(kind), WaybookTheme.SMALL_SIZE, stamp_colour(kind), true)
	_stamp.remove_theme_color_override("font_shadow_color")
	_stamp.rotation = deg_to_rad(-8)
	head.add_child(_stamp)
	var b := WaybookTheme.label(body, WaybookTheme.BODY_SIZE - 1, Color(ArtPalette.INK, 0.86))
	b.remove_theme_color_override("font_shadow_color")
	b.autowrap_mode = TextServer.AUTOWRAP_WORD
	b.custom_minimum_size = Vector2(WIDTH - 72, 0)
	col.add_child(b)
	resized.connect(func(): pivot_offset = size * 0.5)
	return self

static func stamp_colour(kind: Severity) -> Color:
	match kind:
		Severity.LOSS:
			return ArtPalette.GRIM_CRIMSON
		Severity.GAIN:
			return ArtPalette.MOSS.darkened(0.2)
	return ArtPalette.GRIM_RUST

static func stamp_text(kind: Severity) -> String:
	match kind:
		Severity.LOSS:
			return TranslationServer.translate("UI_GRIM_STAMP_LOSS")
		Severity.GAIN:
			return TranslationServer.translate("UI_GRIM_STAMP_GAIN")
	return TranslationServer.translate("UI_GRIM_STAMP_OMEN")

## Ses imi: kayıp ağır mühür, alamet kalp atışı, kazanç sikke.
static func sound_cue(kind: Severity) -> String:
	match kind:
		Severity.LOSS:
			return "stamp"
		Severity.GAIN:
			return "coin"
	return "alert"

## Düşüş: yukarıdan gelir, hafifçe sekip oturur, sonra tam sıfır.
static func drop_offset(age: float) -> float:
	var u := clampf(age / DROP_SECONDS, 0.0, 1.0)
	if u >= 1.0:
		return 0.0
	var fall := (1.0 - u) * (1.0 - u)
	var bounce := sin(u * PI) * 0.18 * (1.0 - u)
	return -DROP_HEIGHT * fall + DROP_HEIGHT * bounce

static func fade_alpha(age: float) -> float:
	var fade_start := DROP_SECONDS + HOLD_SECONDS
	if age <= fade_start:
		return 1.0
	return clampf(1.0 - (age - fade_start) / FADE_SECONDS, 0.0, 1.0)

func set_age(age: float) -> void:
	_age = age
	_apply()

func _process(delta: float) -> void:
	_age += delta
	_apply()
	if fade_alpha(_age) <= 0.0:
		queue_free()

func _apply() -> void:
	rotation = _tilt
	position.y = get_meta("rest_y", position.y) + drop_offset(_age)
	modulate.a = fade_alpha(_age)
