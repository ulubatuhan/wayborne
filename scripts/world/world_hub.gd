extends Node2D

## Yan görünüşlü 2D alan: kervan liderini sağa sola yürütür, vagon peşinden
## gelir. Vagona ve şehir kapısına yaklaşıp tıklayarak ilgili ekranlara
## geçilir. Fizik yok - düz bir şerit üzerinde konum aritmetiği.
## Geliştirici test menüsü artık yolun içinde değil, F1 ile her yerden
## açılan bir overlay (bkz. scripts/autoload/dev_panel.gd).

const GROUND_Y: float = 430.0
const WORLD_MIN_X: float = -160.0
const WORLD_MAX_X: float = 2100.0
const WALK_SPEED: float = 280.0
const INTERACT_RANGE: float = 150.0

const LEADER_SIZE: Vector2 = Vector2(34, 62)
const WAGON_SIZE: Vector2 = Vector2(76, 50)
const WAGON_GAP: float = 100.0
const WAGON_FOLLOW_SPEED: float = 7.0

const SKY_COLOR: Color = Color(0.42, 0.52, 0.62)
const GROUND_COLOR: Color = Color(0.35, 0.31, 0.24)
const LEADER_COLOR: Color = Color(0.85, 0.78, 0.55)
const WAGON_COLOR: Color = Color(0.55, 0.38, 0.22)
const GATE_COLOR: Color = Color(0.48, 0.48, 0.55)
const PROMPT_COLOR: Color = Color(1.0, 0.9, 0.5)

var _player: ColorRect
var _wagon: ColorRect
var _spots: Array[Dictionary] = []

@onready var _camera: Camera2D = $Camera2D
@onready var _status_label: Label = $HUD/TopBar/Row/StatusLabel
@onready var _menu_button: Button = $HUD/TopBar/Row/MenuButton
@onready var _hint_label: Label = $HUD/HintBar/HintLabel

func _ready() -> void:
	Nav.return_scene = Nav.WORLD_HUB
	_menu_button.pressed.connect(_on_menu_pressed)

	_build_scenery()
	_build_spots()
	_build_caravan()

	_camera.make_current()
	_refresh_status()

func _process(delta: float) -> void:
	_move_player(delta)
	_follow_with_wagon(delta)
	_update_prompts()
	_camera.position = Vector2(_player.position.x, GROUND_Y - 150.0)

func _move_player(delta: float) -> void:
	var direction := 0.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction -= 1.0

	if is_zero_approx(direction):
		return

	_player.position.x = clampf(
		_player.position.x + direction * WALK_SPEED * delta,
		WORLD_MIN_X,
		WORLD_MAX_X
	)

func _follow_with_wagon(delta: float) -> void:
	var target_x := _player.position.x - WAGON_GAP
	var weight := minf(1.0, WAGON_FOLLOW_SPEED * delta)
	_wagon.position.x = lerpf(_wagon.position.x, target_x, weight)

func _build_scenery() -> void:
	var sky := ColorRect.new()
	sky.color = SKY_COLOR
	sky.position = Vector2(WORLD_MIN_X - 400.0, GROUND_Y - 900.0)
	sky.size = Vector2(WORLD_MAX_X - WORLD_MIN_X + 900.0, 900.0)
	sky.z_index = -20
	add_child(sky)

	var ground := ColorRect.new()
	ground.color = GROUND_COLOR
	ground.position = Vector2(WORLD_MIN_X - 400.0, GROUND_Y)
	ground.size = Vector2(WORLD_MAX_X - WORLD_MIN_X + 900.0, 400.0)
	ground.z_index = -10
	add_child(ground)

	# Yol boyunca mesafe hissi veren işaretler.
	for i in range(14):
		var marker := ColorRect.new()
		marker.color = GROUND_COLOR.lightened(0.12)
		marker.position = Vector2(WORLD_MIN_X + i * 170.0, GROUND_Y + 26.0)
		marker.size = Vector2(60.0, 6.0)
		marker.z_index = -9
		add_child(marker)

func _build_spots() -> void:
	_add_spot(
		"Şehir Kapısı",
		Vector2(1720.0, GROUND_Y - 230.0),
		Vector2(150.0, 230.0),
		GATE_COLOR,
		Nav.CITY_MAP,
		Nav.CITY_MAP
	)

func _add_spot(
	spot_name: String,
	position: Vector2,
	size: Vector2,
	color: Color,
	scene_path: String,
	return_scene: String
) -> void:
	var body := ColorRect.new()
	body.color = color
	body.position = position
	body.size = size
	add_child(body)

	var name_label := Label.new()
	name_label.text = spot_name
	name_label.position = Vector2(position.x - 40.0, position.y - 34.0)
	name_label.size = Vector2(size.x + 80.0, 28.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(name_label)

	var prompt := Label.new()
	prompt.text = "▼ tıkla ya da E"
	prompt.position = Vector2(position.x - 40.0, position.y + size.y + 6.0)
	prompt.size = Vector2(size.x + 80.0, 24.0)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.modulate = PROMPT_COLOR
	prompt.visible = false
	add_child(prompt)

	_spots.append({
		"name": spot_name,
		"rect": Rect2(position, size),
		"scene": scene_path,
		"return": return_scene,
		"prompt": prompt,
	})

func _build_caravan() -> void:
	_wagon = ColorRect.new()
	_wagon.color = WAGON_COLOR
	_wagon.position = Vector2(-WAGON_GAP, GROUND_Y - WAGON_SIZE.y)
	_wagon.size = WAGON_SIZE
	add_child(_wagon)

	var wagon_label := Label.new()
	wagon_label.text = "Vagon"
	wagon_label.position = Vector2(0.0, -26.0)
	wagon_label.size = Vector2(WAGON_SIZE.x, 24.0)
	wagon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wagon.add_child(wagon_label)

	var wagon_prompt := Label.new()
	wagon_prompt.text = "▼ tıkla ya da E"
	wagon_prompt.position = Vector2(-40.0, WAGON_SIZE.y + 6.0)
	wagon_prompt.size = Vector2(WAGON_SIZE.x + 80.0, 24.0)
	wagon_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wagon_prompt.modulate = PROMPT_COLOR
	wagon_prompt.visible = false
	_wagon.add_child(wagon_prompt)

	# Vagon hareket ettiği için kendi kaydı ayrı tutulur.
	_spots.append({
		"name": "Vagon",
		"rect": Rect2(),
		"scene": Nav.ECONOMY,
		"return": Nav.WORLD_HUB,
		"prompt": wagon_prompt,
		"follows_wagon": true,
	})

	_player = ColorRect.new()
	_player.color = LEADER_COLOR
	_player.position = Vector2(0.0, GROUND_Y - LEADER_SIZE.y)
	_player.size = LEADER_SIZE
	add_child(_player)

	var leader_label := Label.new()
	leader_label.text = "Kervan Lideri"
	leader_label.position = Vector2(-45.0, -28.0)
	leader_label.size = Vector2(LEADER_SIZE.x + 90.0, 24.0)
	leader_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player.add_child(leader_label)

func _get_spot_rect(spot: Dictionary) -> Rect2:
	if spot.get("follows_wagon", false):
		return Rect2(_wagon.position, WAGON_SIZE)
	return spot.rect

func _update_prompts() -> void:
	for spot in _spots:
		spot.prompt.visible = _is_in_range(spot)

func _is_in_range(spot: Dictionary) -> bool:
	var rect := _get_spot_rect(spot)
	var player_center := _player.position.x + LEADER_SIZE.x * 0.5
	return absf(rect.get_center().x - player_center) <= INTERACT_RANGE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_interact_at(get_global_mouse_position())
		return

	if event.is_action_pressed("ui_accept"):
		_try_interact_nearest()
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_try_interact_nearest()

func _try_interact_at(world_position: Vector2) -> void:
	for spot in _spots:
		if not _get_spot_rect(spot).has_point(world_position):
			continue
		if _is_in_range(spot):
			_enter_spot(spot)
		else:
			_hint("%s çok uzakta - yaklaş." % spot.name)
		return

func _try_interact_nearest() -> void:
	for spot in _spots:
		if _is_in_range(spot):
			_enter_spot(spot)
			return

func _enter_spot(spot: Dictionary) -> void:
	Nav.return_scene = spot.get("return", Nav.WORLD_HUB)
	get_tree().change_scene_to_file(spot.scene)

func _hint(text: String) -> void:
	_hint_label.text = text

func _refresh_status() -> void:
	var session: GameSession = GameState.get_session()
	var location := WorldMapData.get_location_by_id(session.current_location_id)
	var location_name := "Yolda" if location == null else location.location_name
	_status_label.text = "%s · Kese: %d GG · Erzak: %d · Vagon: %d" % [
		location_name,
		session.wallet.balance,
		session.get_provisions(),
		session.caravan.wagon_count,
	]

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(Nav.MAIN_MENU)
