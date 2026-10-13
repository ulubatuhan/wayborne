extends RefCounted

## Render edilmiş eşyalar (PropArt): oyunun okuduğu her eşya pakette var,
## katmanları ve milleri yerinde, vagon ArtDraw.wagon'un kutusuna oturuyor.
## Görünüşü değil düzeni sınıyor - görünüş için screenshot araçları.

const REQUIRED := {
	"covered_wagon": ["body", "canopy", "load", "wheel", "wheel_front"],
	"half_cart": ["body", "canopy", "load", "wheel"],
	"city_gate": ["body", "gate"],
	"windmill": ["body", "blades"],
	"mill_wooden": ["body", "blades"],
	"bonfire": ["body"],
	"house_1": ["body"], "house_2": ["body"], "hay": ["body"], "well": ["body"],
	"outpost": ["body"], "tent": ["body"], "torch": ["body"], "mine": ["body"],
	"crate_mv": ["body"], "barrels_mv": ["body"], "signpost": ["body"],
	"market_cart": ["body"], "sawmill": ["body"],
	"iso_inn": ["body"], "iso_bell_tower": ["body"], "iso_house_3": ["body"],
	"iso_stable": ["body"], "iso_market_stand_1": ["body"], "iso_market_stand_2": ["body"],
	"iso_house_1": ["body"], "iso_house_2": ["body"],
}

func suite_name() -> String:
	return "Props"

func run(t) -> void:
	_test_every_used_prop_is_packed(t)
	_test_pivots_sit_on_their_parts(t)
	_test_wagon_fits_the_procedural_box(t)
	_test_missing_prop_falls_back_silently(t)

func _test_every_used_prop_is_packed(t) -> void:
	for id in REQUIRED:
		t.ok(PropArt.has(id), "%s pakette" % id)
		for layer in REQUIRED[id]:
			t.ok(PropArt.texture(id, layer) != null, "%s/%s resmi var" % [id, layer])

## Dönen parçanın mili kendi resminin içinde olmalı - dışındaysa tekerlek
## ya da kanat yörüngede döner.
func _test_pivots_sit_on_their_parts(t) -> void:
	for pair in [["covered_wagon", "wheel", "wheel_back"], ["covered_wagon", "wheel_front", "wheel_front"],
			["half_cart", "wheel", "wheel_front"], ["windmill", "blades", "hub"], ["mill_wooden", "blades", "hub"]]:
		var r := PropArt.layer_rect(pair[0], pair[1], Vector2.ZERO, 1.0)
		var p := PropArt.pivot(pair[0], pair[2], Vector2.ZERO, 1.0)
		t.ok(r.grow(-r.size.x * 0.3).has_point(p), "%s %s mili parçanın ortasında" % [pair[0], pair[1]])

## Model ArtDraw.wagon'un oranlarıyla kuruldu: aynı h aynı kutu. Kolon,
## ok ve arabacı koltuğu bu kutuya bağlı.
func _test_wagon_fits_the_procedural_box(t) -> void:
	var h := 100.0
	var k := PropArt.scale_for_height("covered_wagon", h, ArtDraw.WAGON_MODEL_H)
	var b := PropArt.bounds("covered_wagon", Vector2.ZERO, k)
	t.ok(absf(b.end.y) < h * 0.03, "vagon yere basıyor (alt kenar %.1f)" % b.end.y)
	t.ok(absf(-b.position.y - h * 1.24) < h * 0.08, "branda tepesi ~1.24h (%.1f)" % -b.position.y)
	var w := h * 1.235
	t.ok(b.size.x < w * 1.35 and b.size.x > w * 0.9, "boy vagon eni civarında (%.1f / %.1f)" % [b.size.x, w])

func _test_missing_prop_falls_back_silently(t) -> void:
	t.not_ok(PropArt.has("no_such_prop"), "olmayan eşya yok sayılır")
	t.eq(PropArt.bounds("no_such_prop", Vector2.ZERO, 1.0), Rect2(), "boş dikdörtgen")
