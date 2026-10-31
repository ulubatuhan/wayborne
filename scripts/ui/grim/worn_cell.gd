class_name WornCell
extends PanelContainer

## Envanter hücresi: ikon, miktar, ağırlık ve **durum**. Durum üç ayrı
## yıpranmadan oluşuyor - yırtık (kullanım), kırağı (soğuk), kir (yol) - ve
## hepsi aynı gölgelendiriciden (item_wear.gdshader) geçiyor. Bozulabilir mal
## (erzak, balık) köşesinde kaç gün kaldığını taşıyor.
##
## TASLAK: oyunda henüz bir eşya durumu ya da bozulma sistemi yok (Item
## yalnızca fiyat/ağırlık taşıyor). Hücre görünüşü bekliyor; verisi bir
## tasarım kararı - bkz. docs/ui/REDESIGN.md "Açık kararlar".

const SIDE: float = 84.0
const ICON: float = 52.0
const WEAR_SHADER: String = "res://scripts/ui/grim/item_wear.gdshader"

static var _material_cache: Shader

var item_id: String = ""

func setup(id: String, quantity: int, weight: float, condition: float,
		frost: float = 0.0, grime: float = 0.0, days_left: int = -1) -> WornCell:
	item_id = id
	custom_minimum_size = Vector2(SIDE, SIDE + 18)
	add_theme_stylebox_override("panel", _cell_box(condition))
	tooltip_text = "%s\n%s" % [tr(ItemCatalog.get_item(id).item_name_key) if ItemCatalog.get_item(id) != null else id,
		"%d%%" % roundi(condition * 100.0)]
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stack)
	var icon_box := CenterContainer.new()
	icon_box.custom_minimum_size = Vector2(SIDE - 8, ICON + 6)
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(icon_box)
	var icon := WaybookTheme.item_icon(id, ICON)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.material = wear_material(1.0 - condition, frost, grime)
	icon_box.add_child(icon)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(row)
	var q := WaybookTheme.label("×%d" % quantity, WaybookTheme.SMALL_SIZE, ArtPalette.GRIM_PARCHMENT)
	q.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(q)
	row.add_child(WaybookTheme.label("%.0f" % weight, WaybookTheme.SMALL_SIZE - 1, ArtPalette.GRIM_PARCHMENT_DIM))
	stack.add_child(_condition_bar(condition))
	if days_left >= 0:
		var rot := WaybookTheme.label(tr("UI_GRIM_DAYS_LEFT") % days_left, WaybookTheme.SMALL_SIZE - 2,
			ArtPalette.GRIM_CRIMSON.lightened(0.3) if days_left <= 2 else ArtPalette.GRIM_BILE.lightened(0.2))
		rot.position = Vector2(4, 2)
		add_child(rot)
		rot.top_level = false
	return self

static func wear_material(tatter: float, frost: float, grime: float) -> ShaderMaterial:
	if _material_cache == null:
		_material_cache = load(WEAR_SHADER)
	var m := ShaderMaterial.new()
	m.shader = _material_cache
	m.set_shader_parameter("tatter_mask", WaybookTheme.grim_texture("tatter_mask.png"))
	m.set_shader_parameter("frost_tex", WaybookTheme.grim_texture("frost_overlay.png"))
	m.set_shader_parameter("grime_tex", WaybookTheme.grim_texture("grime_overlay.png"))
	m.set_shader_parameter("tatter", clampf(tatter, 0.0, 1.0))
	m.set_shader_parameter("frost", clampf(frost, 0.0, 1.0))
	m.set_shader_parameter("grime", clampf(grime, 0.0, 1.0))
	return m

## Kenar rengi durumu söyler: sağlam pas, yıpranmış kehribar, harap kan.
static func condition_colour(condition: float) -> Color:
	if condition < 0.3:
		return ArtPalette.GRIM_CRIMSON
	if condition < 0.65:
		return ArtPalette.GRIM_AMBER.darkened(0.25)
	return ArtPalette.GRIM_RUST

func _cell_box(condition: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(ArtPalette.GRIM_CHARCOAL_SOFT, 0.92)
	box.border_color = condition_colour(condition)
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	box.set_content_margin_all(4)
	return box

func _condition_bar(condition: float) -> Control:
	var bar := ColorRect.new()
	bar.color = Color(ArtPalette.GRIM_IRON, 0.6)
	bar.custom_minimum_size = Vector2(SIDE - 8, 3)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := ColorRect.new()
	fill.color = condition_colour(condition).lightened(0.15)
	fill.size = Vector2((SIDE - 8) * clampf(condition, 0.0, 1.0), 3)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(fill)
	return bar
