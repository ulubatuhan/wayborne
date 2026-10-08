## Faz 1.4: figuru 5 Sprite2D ile (ressam sirasi: back_arm, back_leg, torso_head,
## front_leg, front_arm) karelerin atlasindan oynatan kucuk oynatici. Dugumun
## orijini = capa (kalcanin altindaki zemin noktasi). class_name yok: tools/
## altindaki betik global sinif onbellegine girmesin (tests/ kurali ile ayni).
extends Node2D

var _meta: Dictionary = {}
var _sprites: Array[Sprite2D] = []
var _frame_ids: Array = []
var _cursor: int = 0
var _elapsed: float = 0.0
var fps: float = 12.0
var playing: bool = false

func setup(atlas_dir: String) -> void:
	_meta = JSON.parse_string(FileAccess.get_file_as_string(atlas_dir.path_join("atlas.json")))
	_frame_ids = _meta["frames"]
	for layer in _meta["layers"]:
		var img := Image.load_from_file(atlas_dir.path_join(_meta["atlas"][layer]["png"]))
		var spr := Sprite2D.new()
		spr.name = layer
		spr.texture = ImageTexture.create_from_image(img)
		spr.centered = false
		spr.region_enabled = true
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(spr)
		_sprites.append(spr)
	set_frame(0)

func frame_count() -> int:
	return _frame_ids.size()

func set_frame(i: int) -> void:
	_cursor = posmod(i, _frame_ids.size())
	var key := "f%02d" % int(_frame_ids[_cursor])
	for k in _sprites.size():
		var layer: String = _meta["layers"][k]
		var e = _meta["atlas"][layer]["frames"].get(key)
		var spr := _sprites[k]
		if e == null:
			spr.visible = false
			continue
		spr.visible = true
		var r: Array = e["rect"]
		spr.region_rect = Rect2(r[0], r[1], r[2], r[3])
		spr.position = Vector2(e["offset"][0], e["offset"][1])

func _process(delta: float) -> void:
	if not playing:
		return
	_elapsed += delta
	var step := 1.0 / fps
	while _elapsed >= step:
		_elapsed -= step
		set_frame(_cursor + 1)
