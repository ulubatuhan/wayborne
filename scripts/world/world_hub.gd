extends Node2D

## Yan görünüşlü 2D alan: kervan liderini sağa sola yürütür, parti ve
## vagonlar peşinden gelir - kaç vagonun ve kaç yoldaşın varsa o kadarı
## çizilir. Vagona ve şehir kapısına yaklaşıp tıklayarak ilgili ekranlara
## geçilir. Fizik yok - düz bir şerit üzerinde konum aritmetiği.
## Geliştirici test menüsü artık yolun içinde değil, F1 ile her yerden
## açılan bir overlay (bkz. scripts/autoload/dev_panel.gd).

const GROUND_Y: float = 430.0
const WORLD_MIN_X: float = -160.0
const WORLD_MAX_X: float = 2100.0
const WALK_SPEED: float = 280.0
const INTERACT_RANGE: float = 150.0

const WAGON_SIZE: Vector2 = Vector2(76, 50)
const WAGON_FOLLOW_SPEED: float = 7.0

## Kervanın dizilişi: lider önde, parti arkasında, vagonlar en arkada.
const FOLLOWER_GAP: float = 46.0
const WAGON_GAP: float = 100.0
const WAGON_SPACING: float = 92.0

## Karakterin boyu görünürde de fark etsin diye gövde yüksekliği bu
## aralıkta ölçeklenir (bkz. CharacterData.MIN/MAX_HEIGHT_CM).
const BODY_MIN_HEIGHT: float = 52.0
const BODY_MAX_HEIGHT: float = 72.0
const BODY_WIDTH: float = 30.0

## Vagonu süren isimsiz tayfa (bkz. GameSession.PEOPLE_PER_WAGON) - adı
## olan parti üyelerinden görsel olarak ayrışsın diye soluk/nötr renkte,
## etiketsiz, sabit boyda.
const CREW_BODY_HEIGHT: float = 56.0
const CREW_GAP: float = 22.0

const SKY_COLOR: Color = Color(0.42, 0.52, 0.62)
const GROUND_COLOR: Color = Color(0.35, 0.31, 0.24)
const LEADER_COLOR: Color = Color(0.85, 0.78, 0.55)
const WAGON_COLOR: Color = Color(0.55, 0.38, 0.22)
const CREW_COLOR: Color = Color(0.42, 0.4, 0.36)
const GATE_COLOR: Color = Color(0.48, 0.48, 0.55)
const PROMPT_COLOR: Color = Color(1.0, 0.9, 0.5)

var _player: ColorRect
## Vagonlar sahip olunan sayıya göre kuruluyor, parti üyeleri de
## isimleriyle yürüyor - kervanın büyüdüğü ekranda görülsün diye.
var _wagons: Array[ColorRect] = []
var _followers: Array[ColorRect] = []
## Her vagonun kendi tayfası: crew_index -> wagon_index ilişkisi
## GameSession.PEOPLE_PER_WAGON üzerinden hesaplanır (bkz. _follow_with_wagon).
var _crew: Array[ColorRect] = []
var _spots: Array[Dictionary] = []

@onready var _camera: Camera2D = $Camera2D
@onready var _status_label: Label = $HUD/TopBar/Row/StatusLabel
@onready var _party_button: Button = $HUD/TopBar/Row/PartyButton
@onready var _menu_button: Button = $HUD/TopBar/Row/MenuButton
@onready var _hint_label: Label = $HUD/HintBar/HintLabel

var _morale_bar: PulseBar
var _stress_bar: PulseBar

func _ready() -> void:
	Nav.return_scene = Nav.WORLD_HUB
	_party_button.pressed.connect(_on_party_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_build_status_bars()

	_build_scenery()
	_build_spots()
	_build_caravan()

	_camera.make_current()
	_refresh_status()

## Moral seferin kendi ruh hali, stres seferler arası kalıcı - ikisi de
## burada, kervanın "ana ekranında", ayrı birer soluk/parlak çubukla
## gösteriliyor (bkz. PulseBar).
func _build_status_bars() -> void:
	var row := _status_label.get_parent()

	_morale_bar = PulseBar.new()
	row.add_child(_morale_bar)
	row.move_child(_morale_bar, _status_label.get_index() + 1)
	_morale_bar.setup("Moral", Color(0.6, 0.75, 0.5))

	_stress_bar = PulseBar.new()
	row.add_child(_stress_bar)
	row.move_child(_stress_bar, _morale_bar.get_index() + 1)
	_stress_bar.setup("Stres", Color(0.8, 0.45, 0.4))

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
	var weight := minf(1.0, WAGON_FOLLOW_SPEED * delta)

	for index in _followers.size():
		var follower := _followers[index]
		var follower_target := _player.position.x - FOLLOWER_GAP * (index + 1)
		follower.position.x = lerpf(follower.position.x, follower_target, weight)

	var train_start := _player.position.x - FOLLOWER_GAP * _followers.size() - WAGON_GAP
	for index in _wagons.size():
		var wagon := _wagons[index]
		var wagon_target := train_start - WAGON_SPACING * index
		wagon.position.x = lerpf(wagon.position.x, wagon_target, weight)
		_follow_wagon_crew(index, wagon_target, weight)

## Bir vagonun tayfası (bkz. GameSession.PEOPLE_PER_WAGON) o vagonun önünde,
## yan yana yürür - vagon kendi kendine gitmiyormuş gibi görünmesin diye.
func _follow_wagon_crew(wagon_index: int, wagon_target_x: float, weight: float) -> void:
	for crew_slot in GameSession.PEOPLE_PER_WAGON:
		var crew_index := wagon_index * GameSession.PEOPLE_PER_WAGON + crew_slot
		if crew_index >= _crew.size():
			continue
		var crew_member := _crew[crew_index]
		var crew_target := wagon_target_x + WAGON_SIZE.x * 0.5 - CREW_GAP * (crew_slot + 1)
		crew_member.position.x = lerpf(crew_member.position.x, crew_target, weight)

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

## Kervanı sahiplik durumuna göre kurar: sahip olunan her vagon için bir
## vagon ve GameSession.PEOPLE_PER_WAGON kadar tayfa, partideki her kişi
## için bir gövde. Oyuncu partisi tek kişiyle başlar, tayfa topladıkça
## arkasında yürüyenler çoğalır.
func _build_caravan() -> void:
	var session: GameSession = GameState.get_session()
	var party := session.get_party()

	for index in maxi(1, session.owned_wagon_count):
		var wagon := _build_wagon(index)
		_wagons.append(wagon)
		for crew_slot in GameSession.PEOPLE_PER_WAGON:
			_crew.append(_build_crew_member(wagon.position.x, crew_slot))

	_player = _build_person(party[0], true)
	for index in range(1, party.size()):
		_followers.append(_build_person(party[index], false))

## Sadece ilk vagon etkileşim noktası - kervanın yükü tek envanterde.
func _build_wagon(index: int) -> ColorRect:
	var wagon := ColorRect.new()
	wagon.color = WAGON_COLOR
	wagon.position = Vector2(
		-WAGON_GAP - WAGON_SPACING * index, GROUND_Y - WAGON_SIZE.y
	)
	wagon.size = WAGON_SIZE
	add_child(wagon)

	var wagon_label := Label.new()
	wagon_label.text = "Vagon %d" % (index + 1)
	wagon_label.position = Vector2(0.0, -26.0)
	wagon_label.size = Vector2(WAGON_SIZE.x, 24.0)
	wagon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wagon.add_child(wagon_label)

	if index > 0:
		return wagon

	var wagon_prompt := Label.new()
	wagon_prompt.text = "▼ tıkla ya da E"
	wagon_prompt.position = Vector2(-40.0, WAGON_SIZE.y + 6.0)
	wagon_prompt.size = Vector2(WAGON_SIZE.x + 80.0, 24.0)
	wagon_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wagon_prompt.modulate = PROMPT_COLOR
	wagon_prompt.visible = false
	wagon.add_child(wagon_prompt)

	# Vagon hareket ettiği için kendi kaydı ayrı tutulur.
	_spots.append({
		"name": "Vagon",
		"rect": Rect2(),
		"scene": Nav.ECONOMY,
		"return": Nav.WORLD_HUB,
		"prompt": wagon_prompt,
		"follows_wagon": true,
	})
	return wagon

## wagon_x, o vagonun o anki x'i - _follow_wagon_crew'daki hedef formülüyle
## aynısı kullanılır ki ilk karede kervan konumundan içeri kaymasın.
func _build_crew_member(wagon_x: float, crew_slot: int) -> ColorRect:
	var body := ColorRect.new()
	body.color = CREW_COLOR
	body.size = Vector2(BODY_WIDTH, CREW_BODY_HEIGHT)
	body.position = Vector2(
		wagon_x + WAGON_SIZE.x * 0.5 - CREW_GAP * (crew_slot + 1),
		GROUND_Y - CREW_BODY_HEIGHT
	)
	add_child(body)
	return body

## Gövde yüksekliği karakterin boyundan, rengi ten renginden geliyor -
## oluşturma ekranında seçilenler yolda da görünsün diye.
func _build_person(character: CharacterData, is_leader: bool) -> ColorRect:
	var height_ratio := inverse_lerp(
		float(CharacterData.MIN_HEIGHT_CM),
		float(CharacterData.MAX_HEIGHT_CM),
		float(character.height_cm)
	)
	var body_height := lerpf(BODY_MIN_HEIGHT, BODY_MAX_HEIGHT, clampf(height_ratio, 0.0, 1.0))

	var body := ColorRect.new()
	body.color = CharacterData.get_skin_tone_color(character.skin_tone)
	body.size = Vector2(BODY_WIDTH, body_height)
	body.position = Vector2(0.0, GROUND_Y - body_height)
	if not is_leader:
		body.position.x = -FOLLOWER_GAP
	add_child(body)

	var label := Label.new()
	label.text = character.character_name if is_leader else character.character_name.split(" ")[0]
	label.position = Vector2(-45.0, -28.0)
	label.size = Vector2(BODY_WIDTH + 90.0, 24.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_leader:
		label.modulate = LEADER_COLOR
	body.add_child(label)
	return body

func _get_spot_rect(spot: Dictionary) -> Rect2:
	if spot.get("follows_wagon", false):
		return Rect2(_wagons[0].position, WAGON_SIZE)
	return spot.rect

func _update_prompts() -> void:
	for spot in _spots:
		spot.prompt.visible = _is_in_range(spot)

func _is_in_range(spot: Dictionary) -> bool:
	var rect := _get_spot_rect(spot)
	var player_center := _player.position.x + _player.size.x * 0.5
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
	_status_label.text = "%s · Kese: %d GG · Erzak: %d · Vagon: %d · Parti: %d/%d" % [
		location_name,
		session.wallet.balance,
		session.get_provisions(),
		session.owned_wagon_count,
		session.get_party().size(),
		session.get_party_capacity(),
	]
	_morale_bar.set_value(session.caravan.morale, CaravanState.MAX_MORALE)
	_stress_bar.set_value(session.party_stress, GameSession.MAX_STRESS)

func _on_party_pressed() -> void:
	Nav.return_scene = Nav.WORLD_HUB
	get_tree().change_scene_to_file(Nav.PARTY)

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(Nav.MAIN_MENU)
