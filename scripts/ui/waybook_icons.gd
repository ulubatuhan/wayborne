class_name WaybookIcons
extends RefCounted

## Kişilerin Waybook işaretleri tek tabloda: stat amblemleri (P3), görev
## amblemleri (P5), kırgınlık kenar notları (P4), sınıf amblemleri (K6),
## huy mühürleri (P2) ve açlık çetelesi (P6). Karakter ekranı, parti ekranı,
## kervan dökümü ve savaş alanı aynı kişiyi aynı işaretlerle göstersin diye -
## `ArtDraw.wagon()`'un "bir şekil iki yerde çizilirse iki farklı şekil
## olur" kuralının ikon karşılığı.
##
## Yalnızca resim: adı ve anlamı her zaman canlı metin olarak yanında ya da
## ipucunda duruyor.

const STAT_EMBLEMS: Dictionary = {
	CharacterStats.Kind.STRENGTH: "p3_strength.png",
	CharacterStats.Kind.AGILITY: "p3_agility.png",
	CharacterStats.Kind.ENDURANCE: "p3_endurance.png",
	CharacterStats.Kind.INTELLECT: "p3_intellect.png",
	CharacterStats.Kind.PERCEPTION: "p3_perception.png",
	CharacterStats.Kind.CHARISMA: "p3_charisma.png",
	CharacterStats.Kind.WISDOM: "p3_wisdom.png",
	CharacterStats.Kind.FAITH: "p3_faith.png",
}

const DUTY_EMBLEMS: Dictionary = {
	DutyCatalog.MUHAFIZ: "p5_guard.png",
	DutyCatalog.IZCI: "p5_scout.png",
	DutyCatalog.LEVAZIMCI: "p5_quartermaster.png",
	DutyCatalog.ARABACI: "p5_wagoner.png",
	DutyCatalog.TELLAL: "p5_crier.png",
	DutyCatalog.OTACI: "p5_herbalist.png",
}

const GRIEVANCE_MARKS: Dictionary = {
	CharacterData.GRIEVANCE_UNFED: "p4_unfed.png",
	CharacterData.GRIEVANCE_BENCHED: "p4_benched.png",
	CharacterData.GRIEVANCE_WITNESSED_DEATH: "p4_witnessed_death.png",
	CharacterData.GRIEVANCE_PASSED_OVER: "p4_passed_over.png",
}

const GRIEVANCE_LABEL_KEYS: Dictionary = {
	CharacterData.GRIEVANCE_UNFED: "UI_GRIEVANCE_UNFED",
	CharacterData.GRIEVANCE_BENCHED: "UI_GRIEVANCE_BENCHED",
	CharacterData.GRIEVANCE_WITNESSED_DEATH: "UI_GRIEVANCE_WITNESSED_DEATH",
	CharacterData.GRIEVANCE_PASSED_OVER: "UI_GRIEVANCE_PASSED_OVER",
}

const CLASS_EMBLEMS: Dictionary = {
	ClassCatalog.GUARD: "k6a_guard.png",
	ClassCatalog.HUNTER: "k6b_hunter.png",
	ClassCatalog.BREAKER: "k6c_breaker.png",
	ClassCatalog.CLERK: "k6d_clerk.png",
}

const VIRTUE_TOKEN: String = "p2_virtue.png"
const AFFLICTION_TOKEN: String = "p2_affliction.png"
const HUNGER_TALLY: String = "p6_tally.png"

## Dosyası olmayan bir anahtar (gelecekte eklenen bir görev, bir düşman
## "sınıfı") boş bir yer tutucu alır - satır hizası bozulmaz, oyun çökmez.
static func picture(table: Dictionary, key: Variant, height: float, tooltip: String = "") -> Control:
	var file_name := String(table.get(key, ""))
	if file_name == "":
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(height, height)
		return spacer
	var rect := WaybookTheme.picture(file_name, height)
	# Kare kutu: amblemlerin oranları farklı, satırlarda yanındaki sütun
	# kaymasın.
	rect.custom_minimum_size = Vector2(height, height)
	if tooltip != "":
		rect.tooltip_text = tooltip
		rect.mouse_filter = Control.MOUSE_FILTER_PASS
	return rect

static func trait_token(is_positive: bool, height: float) -> TextureRect:
	return WaybookTheme.picture(VIRTUE_TOKEN if is_positive else AFFLICTION_TOKEN, height)

## Bir kişinin kırgınlıkları: her tür için bir kenar notu ve kaç kez. Hiç
## yoksa boş bir satır - "ihtiyaç yoksa satır yok" (City Hub Rules).
static func grievance_row(character: CharacterData, height: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for key in GRIEVANCE_MARKS:
		var count := character.get_grievance(key)
		if count <= 0:
			continue
		var label_text := TranslationServer.translate(String(GRIEVANCE_LABEL_KEYS[key]))
		var mark := picture(GRIEVANCE_MARKS, key, height, "%s ×%d" % [label_text, count])
		row.add_child(mark)
		if count > 1:
			var times := Label.new()
			times.text = "×%d" % count
			times.add_theme_font_size_override("font_size", 13)
			row.add_child(times)
	return row

## Açlık çetelesi: art arda aç geçen her gece çetele çubuğuna (P6) bir
## çentik. Çubuk boş boyanmış - çentikleri oyunun kendisi atıyor, kaç gece
## olduğu resmin kendisi. Sayı da yanında ve ipucunda.
static func hunger_tally(character: CharacterData, height: float) -> Control:
	var nights := character.consecutive_hungry_days
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	if nights <= 0:
		return row
	var stick := TallyStick.new()
	stick.notches = nights
	stick.custom_minimum_size = Vector2(height * TALLY_LENGTH_RATIO, height * 0.6)
	stick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stick.tooltip_text = TranslationServer.translate("UI_HUNGRY_NIGHTS") % nights
	row.add_child(stick)
	var count := Label.new()
	count.text = str(nights)
	count.modulate = ArtPalette.BLOOD.lightened(0.35)
	row.add_child(count)
	return row

const TALLY_LENGTH_RATIO: float = 4.0
const TALLY_MAX_NOTCHES: int = 7

class TallyStick extends Control:
	var notches: int = 0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _draw() -> void:
		draw_texture_rect(WaybookTheme.texture(HUNGER_TALLY), Rect2(Vector2.ZERO, size), false)
		var shown := mini(notches, TALLY_MAX_NOTCHES)
		var step := size.x / float(TALLY_MAX_NOTCHES + 1)
		for index in shown:
			var x := step * float(index + 1)
			draw_line(Vector2(x - 1.5, 1.0), Vector2(x + 1.5, size.y - 1.0), ArtPalette.INK, 2.0)
