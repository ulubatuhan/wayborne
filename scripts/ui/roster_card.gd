class_name RosterCard
extends Button

## Parti ekranının kadro kartı (taslak 9.7): kişi boydan, kartın tabanına
## basarak duruyor; sağ üstte seviye rozeti, altında küçük-büyük harfli adı,
## durum sözcüğü, yeşil can ve kehribar stres çizgisi.
##
## Kart bir `Button`: tıklama, dokunma ve klavye (odak + kabul) aynı
## `pressed` sinyaline düşüyor, ayrı bir giriş yolu yok. İçindeki her şey
## fareyi yok sayıyor ki tıklama kartın kendisine ulaşsın.
##
## Kenar kartın durumunu söylüyor: seçili kart altın, Ölümün Kıyısındaki
## (ya da ölmüş) kişinin kartı kan rengi ve adı üstü çizili (StruckLine -
## defterle aynı çizgi). Seçili *ve* kıyıdaki kart kan kenarını koruyor,
## seçim dışına altın bir halka olarak çiziliyor.

## Kart dik bir kart: dört kişi yan yana sığacak genişlikte, sırada az
## kişi varken yayılıp yatay bir levhaya dönmüyor (ilk ekran görüntüsü).
## Ölçüler taslağın (y_97_kadro_karti.png, 1080p): 380x640 kart, 60 px rozet.
## Mevki yazısı kartta yok (sıra soldan sağa zaten mevki); ipucunda duruyor.
const CARD_MIN_SIZE: Vector2 = Vector2(380.0, 620.0)
const CARD_PADDING: int = 22
const NAME_FONT_SIZE: int = 34
const STATUS_FONT_SIZE: int = 22
const BADGE_SIZE: float = 62.0
const BADGE_FONT_SIZE: int = 30
const HP_BAR_HEIGHT: float = 10.0
const STRESS_BAR_HEIGHT: float = 5.0
## Figürün ayak altındaki gölge: kişi kartın tabanına basıyor, havada
## asılı durmuyor.
const FLOOR_SHADOW_WIDTH_RATIO: float = 0.42
const FLOOR_SHADOW_HEIGHT: float = 12.0

## Kan rengi koyu kart zemininde okunmuyordu (BLOOD ~2.7:1); yazı ve kenar
## aynı kanın açılmış tonu.
const BLOOD_LIGHTEN: float = 0.3
const HP_COLOR: Color = ArtPalette.UI_GAUGE_MORALE
const HP_HURT_COLOR: Color = ArtPalette.BLOOD
const STRESS_COLOR: Color = ArtPalette.GOLD_DIM
## Boş çizginin yatağı: UI_GAUGE_EMPTY kart zemininde kayboluyordu (stresi
## sıfır olanın çizgisi hiç görünmüyordu).
const BAR_TRACK_ALPHA: float = 0.14

var character: CharacterData
var selected: bool = false:
	set(value):
		selected = value
		_apply_frame()
		queue_redraw()

var _at_deaths_door: bool = false
var _blood_text: Color = ArtPalette.BLOOD.lightened(BLOOD_LIGHTEN)
var _figure: FigurePreview

func _init() -> void:
	text = ""
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = CARD_MIN_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	clip_contents = false

## `rank` savaştaki mevki (1 = en önde).
func setup(person: CharacterData, rank: int) -> RosterCard:
	character = person
	_at_deaths_door = is_at_deaths_door(person)
	tooltip_text = "%s\n%s" % [tr("UI_PARTY_CARD_RANK") % rank, tr("UI_PARTY_CARD_TOOLTIP") % [
		person.current_hp, person.get_max_hp(), person.stress, CharacterData.MAX_STRESS
	]]
	_build(rank)
	_apply_frame()
	return self

## Ölümün Kıyısı: can bandının en altı (bkz. get_condition_label_key) ya
## da ölüm. Saf fonksiyon - ekran ve test aynı soruyu sorsun diye.
static func is_at_deaths_door(person: CharacterData) -> bool:
	return not person.is_alive() or person.get_condition_label_key() == "UI_HP_BAND_CRITICAL"

## Can bandı "Dinç"in altındaysa yara var.
static func is_wounded(person: CharacterData) -> bool:
	return person.get_condition_label_key() != "UI_HP_BAND_HEALTHY"

func _build(rank: int) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, CARD_PADDING)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	column.add_child(_build_stage(rank))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 8.0)
	column.add_child(spacer)

	column.add_child(_build_name())

	var status := Label.new()
	status.text = tr("UI_PARTY_CARD_LEADER") if character.is_player else tr(character.get_condition_label_key())
	status.add_theme_font_size_override("font_size", STATUS_FONT_SIZE)
	var hurt := not character.is_player and is_wounded(character)
	status.add_theme_color_override("font_color", _blood_text if hurt else ArtPalette.UI_TEXT_DIM)
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(status)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 14.0)
	column.add_child(gap)

	var hp_ratio := float(character.current_hp) / float(maxi(1, character.get_max_hp()))
	column.add_child(_bar(hp_ratio, HP_HURT_COLOR if is_wounded(character) else HP_COLOR, HP_BAR_HEIGHT))
	var bar_gap := Control.new()
	bar_gap.custom_minimum_size = Vector2(0.0, 12.0)
	column.add_child(bar_gap)
	var stress_ratio := float(character.stress) / float(CharacterData.MAX_STRESS)
	column.add_child(_bar(stress_ratio, STRESS_COLOR, STRESS_BAR_HEIGHT))

	_ignore_mouse(margin)

## Figürün durduğu sahne: figür, ayak gölgesi, seviye rozeti.
func _build_stage(_rank: int) -> Control:
	var stage := Control.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var shadow := Control.new()
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow.draw.connect(_draw_floor_shadow.bind(shadow))
	stage.add_child(shadow)

	_figure = FigurePreview.new()
	_figure.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.add_child(_figure)
	_figure.show_character(character)
	if _at_deaths_door:
		_figure.set_tint(ArtPalette.UI_TINT_DISABLED)

	var badge := Control.new()
	badge.custom_minimum_size = Vector2(BADGE_SIZE, BADGE_SIZE)
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.offset_left = -BADGE_SIZE
	badge.offset_right = 0.0
	badge.offset_top = 0.0
	badge.offset_bottom = BADGE_SIZE
	badge.draw.connect(_draw_badge.bind(badge))
	stage.add_child(badge)
	return stage

func _build_name() -> Control:
	if _at_deaths_door:
		var struck := NameStrike.new()
		struck.setup(character.character_name, false)
		struck.tint = ArtPalette.BLOOD.lightened(0.15)
		_style_name(struck.label)
		return struck
	var label := Label.new()
	label.text = character.character_name
	_style_name(label)
	return label

func _style_name(label: Label) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_override("font", GrimTheme.title_font())
	label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	label.add_theme_color_override("font_color", ArtPalette.UI_TEXT)

func _bar(ratio: float, colour: Color, height: float) -> Control:
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0.0, height)
	var fill := clampf(ratio, 0.0, 1.0)
	bar.draw.connect(func() -> void:
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Color(ArtPalette.BONE_DIM, BAR_TRACK_ALPHA))
		if fill > 0.0:
			bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar.size.x * fill, bar.size.y)), colour)
	)
	return bar

func _draw_floor_shadow(target: Control) -> void:
	var width := target.size.x * FLOOR_SHADOW_WIDTH_RATIO
	var centre := Vector2(target.size.x * 0.5, target.size.y - FLOOR_SHADOW_HEIGHT * 0.35)
	var points := PackedVector2Array()
	for step in 32:
		var angle := TAU * float(step) / 32.0
		points.append(centre + Vector2(cos(angle) * width * 0.5, sin(angle) * FLOOR_SHADOW_HEIGHT * 0.5))
	target.draw_colored_polygon(points, Color(ArtPalette.INK, 0.75))

func _draw_badge(target: Control) -> void:
	var radius := BADGE_SIZE * 0.5 - 2.0
	var centre := target.size * 0.5
	target.draw_circle(centre, radius, Color(ArtPalette.INK, 0.55))
	target.draw_arc(centre, radius, 0.0, TAU, 48, ArtPalette.GOLD, 2.0, true)
	var font := GrimTheme.title_font()
	var number := str(character.level)
	var text_size := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, BADGE_FONT_SIZE)
	var baseline := centre.y + (font.get_ascent(BADGE_FONT_SIZE) - font.get_descent(BADGE_FONT_SIZE)) * 0.5
	target.draw_string(
		font, Vector2(centre.x - text_size.x * 0.5, baseline), number,
		HORIZONTAL_ALIGNMENT_LEFT, -1, BADGE_FONT_SIZE, ArtPalette.GOLD
	)

## Kartın kutusu her durumda aynı; yalnızca kenarın rengi ve kalınlığı
## değişiyor. Odak çerçevesi yok: klavyede odak seçimi taşıyor (bkz.
## party.gd), altın kenar zaten odağın göstergesi.
func _apply_frame() -> void:
	var normal := _frame_box(false)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", _frame_box(true))
	add_theme_stylebox_override("pressed", normal)
	add_theme_stylebox_override("hover_pressed", normal)
	add_theme_stylebox_override("disabled", normal)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _draw() -> void:
	if selected and _at_deaths_door:
		draw_style_box(_selection_ring(), Rect2(Vector2.ZERO, size))

func _frame_box(hover: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = ArtPalette.UI_PANEL_FILL
	box.set_corner_radius_all(WaybookTheme.FRAME_RADIUS)
	box.shadow_color = Color(ArtPalette.INK, 0.5)
	box.shadow_size = 8
	box.set_content_margin_all(0)
	if _at_deaths_door:
		box.border_color = _blood_text if hover else ArtPalette.BLOOD.lightened(0.15)
		box.set_border_width_all(2)
	elif selected:
		box.border_color = ArtPalette.GOLD
		box.set_border_width_all(2)
	else:
		box.border_color = ArtPalette.GOLD if hover else Color(ArtPalette.GOLD_DIM, 0.9)
		box.set_border_width_all(1)
	return box

## Kıyıdaki kart seçiliyken kan kenarının dışında altın bir halka.
func _selection_ring() -> StyleBoxFlat:
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.border_color = ArtPalette.GOLD
	ring.set_border_width_all(2)
	ring.set_corner_radius_all(WaybookTheme.FRAME_RADIUS + 2)
	ring.set_expand_margin_all(4)
	return ring

func _ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)

## Kartın üstü çizili adı: defterin aynı mürekkep darbesi (StruckLine), iki
## farkla. Ad küçük-büyük harfli başlık yüzünde (IM Fell SC) ve o yüzün
## satır kutusu kitap yüzününkinden derin - StruckLine'ın "satırın %55'i"
## darbeyi harflerin ayağına indiriyordu (ilk ekran görüntüsü: altı çizili
## okunuyordu). Darbe burada taban çizgisinden yukarı, küçük harflerin
## ortasından geçiyor; rengi kenarla aynı kan.
class NameStrike extends StruckLine:
	## Taban çizgisinden yukarı, yükselişin (ascent) bu payı kadar.
	const STRIKE_LIFT_RATIO: float = 0.4
	const NAME_STRIKE_HEIGHT_RATIO: float = 0.1

	var tint: Color = ArtPalette.BLOOD

	func _draw_strike() -> void:
		if progress <= 0.0:
			return
		var texture := WaybookTheme.texture(STRIKE_FILE)
		if texture == null:
			return
		var font := label.get_theme_font("font")
		var font_size := label.get_theme_font_size("font_size")
		var text_width := minf(font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x, size.x)
		var height := font.get_height(font_size) * NAME_STRIKE_HEIGHT_RATIO
		var ascent := font.get_ascent(font_size)
		var y := ascent * (1.0 - STRIKE_LIFT_RATIO) - height * 0.5
		var x0 := _text_left(text_width) - STRIKE_OVERHANG
		var full := text_width + STRIKE_OVERHANG * 2.0
		var tex_size := texture.get_size()
		_ink.draw_texture_rect_region(
			texture, Rect2(x0, y, full * progress, height),
			Rect2(0.0, 0.0, tex_size.x * progress, tex_size.y), tint
		)
