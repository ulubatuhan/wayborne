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

## Vagon ölçüsü. İlk değeri (76x50) tayfa figürlerinden *kısaydı* - ekran
## görüntüsünde insanlar vagondan uzun duruyordu. Bir kervan vagonu bir
## insandan yüksektir.
const WAGON_SIZE: Vector2 = Vector2(132, 96)
const WAGON_FOLLOW_SPEED: float = 7.0

## Kervanın dizilişi: lider önde, isimli parti üyeleri onu simetrik bir
## muhafız düzeninde çevreler (biri hemen arkasında, biri ortalarda, biri
## vagonların gerisinde), vagonlar en arkada.
const FOLLOWER_GAP: float = 46.0
const MID_GUARD_GAP: float = 96.0
const REAR_GUARD_TRAIL: float = 50.0
## Simetrik muhafız düzeninde liderin önünden gelen en fazla kaç kişi -
## geri kalanı (üçüncüsü varsa) vagonların gerisinde nöbet tutar.
const FRONT_ESCORT_LIMIT: int = 2
## Aralıklar vagon genişliğinden ve öküzün boyundan büyük olmalı, yoksa
## öküz vagonun içinde yürüyor gibi duruyor.
const WAGON_GAP: float = 170.0
const WAGON_SPACING: float = 250.0

## Karakterin boyu görünürde de fark etsin diye gövde yüksekliği bu
## aralıkta ölçeklenir (bkz. CharacterData.MIN/MAX_HEIGHT_CM).
const BODY_MIN_HEIGHT: float = 62.0
const BODY_MAX_HEIGHT: float = 86.0
const BODY_WIDTH: float = 46.0

## Lider at üstünde: kervanın önünde gidiyor ve vagonlara bağlı değil
## (bkz. RoadCaravan'ın aynı kuralı). Atlı figür yayandan yüksek, o
## yüzden kendi ölçüsü var.
const MOUNTED_HEIGHT: float = 128.0
const MOUNTED_WIDTH: float = 150.0

## Yürüyüş fazının ilerleme hızı. Mesafeye bağlı, zamana değil: duran bir
## figürün ayakları oynarsa yerde kayıyor gibi duruyor.
const STEP_PER_UNIT: float = 0.034

## Öküzün vagonun ne kadar önünde yürüdüğü ve ölçüsü.
const OX_LEAD: float = 152.0
const OX_SIZE: Vector2 = Vector2(146.0, 86.0)

## Vagonu süren isimsiz tayfa (bkz. GameSession.PEOPLE_PER_WAGON) - adı
## olan parti üyelerinden görsel olarak ayrışsın diye soluk/nötr renkte,
## etiketsiz, sabit boyda.
const CREW_BODY_HEIGHT: float = 72.0
const CREW_GAP: float = 22.0

const LEADER_COLOR: Color = Color(0.85, 0.78, 0.55)
const GATE_COLOR: Color = Color(0.48, 0.48, 0.55)
const PROMPT_COLOR: Color = Color(1.0, 0.9, 0.5)

var _player: WalkFigure
## Vagonlar sahip olunan sayıya göre kuruluyor, parti üyeleri de
## isimleriyle yürüyor - kervanın büyüdüğü ekranda görülsün diye.
var _wagons: Array[WagonFigure] = []
var _followers: Array[WalkFigure] = []
## Her vagonun kendi tayfası: crew_index -> wagon_index ilişkisi
## GameSession.PEOPLE_PER_WAGON üzerinden hesaplanır (bkz. _follow_with_wagon).
var _crew: Array[WalkFigure] = []
var _spots: Array[Dictionary] = []
## Her vagonun öküzü - vagonla birlikte, onun bir tık önünde yürüyor.
var _oxen: Array[WalkFigure] = []
## Son karede liderin yürüdüğü yön - yürüyüş fazı ve bakış yönü bundan.
var _walk_direction: float = 0.0

@onready var _camera: Camera2D = $Camera2D
@onready var _status_label: Label = $HUD/TopBar/Row/StatusLabel
@onready var _party_button: Button = $HUD/TopBar/Row/PartyButton
@onready var _menu_button: Button = $HUD/TopBar/Row/MenuButton
@onready var _hint_label: Label = $HUD/HintBar/HintLabel

var _morale_bar: PulseBar
var _stress_bar: PulseBar

func _ready() -> void:
	Nav.go_root(Nav.WORLD_HUB)
	# Sahne dosyasındaki yazı yalnızca editör içindir; oyuncunun gördüğü her
	# metin koddan, anahtarla gelir (bkz. Localization Rules).
	_party_button.text = tr("UI_HUB_PARTY")
	_menu_button.text = tr("UI_HUB_MENU")
	_hint_label.text = tr("UI_HUB_CONTROLS")
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
	_morale_bar.setup(tr("UI_HUB_MORALE"), Color(0.6, 0.75, 0.5))

	_stress_bar = PulseBar.new()
	row.add_child(_stress_bar)
	row.move_child(_stress_bar, _morale_bar.get_index() + 1)
	_stress_bar.setup(tr("UI_HUB_STRESS"), Color(0.8, 0.45, 0.4))

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

	_walk_direction = direction
	# Faz mesafeden sürülüyor: duran bir figürün ayakları oynamıyor,
	# yürüyeninki adım atıyor.
	_player.advance(delta, direction * WALK_SPEED * STEP_PER_UNIT)
	if is_zero_approx(direction):
		return

	_player.position.x = clampf(
		_player.position.x + direction * WALK_SPEED * delta,
		WORLD_MIN_X,
		WORLD_MAX_X
	)

func _follow_with_wagon(delta: float) -> void:
	var weight := minf(1.0, WAGON_FOLLOW_SPEED * delta)
	var leader_x := _player.position.x
	var escort_count := _followers.size()

	for index in escort_count:
		var follower := _followers[index]
		var follower_target := _follower_target_x(index, leader_x, escort_count, _wagons.size())
		var before := follower.position.x
		follower.position.x = lerpf(before, follower_target, weight)
		# Her figür kendi kat ettiği mesafeyle adım atıyor: lidere
		# yetişmeye çalışan biri hızlı, yerinde duran biri hiç.
		follower.advance(delta, (follower.position.x - before) * STEP_PER_UNIT / maxf(delta, 0.0001))

	for index in _wagons.size():
		var wagon := _wagons[index]
		var wagon_target := _wagon_target_x(index, leader_x, escort_count)
		var wagon_before := wagon.position.x
		wagon.position.x = lerpf(wagon_before, wagon_target, weight)
		wagon.roll(wagon.position.x - wagon_before)
		if index < _oxen.size():
			var ox := _oxen[index]
			var ox_before := ox.position.x
			ox.position.x = lerpf(ox_before, wagon.position.x + OX_LEAD, weight)
			ox.advance(delta, (ox.position.x - ox_before) * STEP_PER_UNIT / maxf(delta, 0.0001))
		_follow_wagon_crew(index, wagon_target, weight, delta)

## Öndeki muhafızlar arasında liderden uzaklaştıkça açılan mesafe -
## 0. muhafız (levazımcı/kıdemli) tam arkasında, 1.'si biraz daha geride.
func _front_escort_gap(index: int) -> float:
	return FOLLOWER_GAP if index <= 0 else MID_GUARD_GAP

## Aşağıdaki üç hedef formülü saf aritmetik: düğüm durumuna değil verilen
## sayılara bakıyorlar. Böylece hem her karede lerp hedefi hem de kervan
## kurulurken ilk konum olarak kullanılabiliyorlar - takipçiler eskiden
## hepsi aynı noktada kurulup ilk karelerde yerlerine kayıyordu (bkz.
## _build_crew_member'ın zaten kaçındığı aynı tuzak).
func _train_start_x(leader_x: float, escort_count: int) -> float:
	var front_count := mini(escort_count, FRONT_ESCORT_LIMIT)
	var front_span := _front_escort_gap(front_count - 1) if front_count > 0 else 0.0
	return leader_x - front_span - WAGON_GAP

func _wagon_target_x(wagon_index: int, leader_x: float, escort_count: int) -> float:
	return _train_start_x(leader_x, escort_count) - WAGON_SPACING * wagon_index

## FRONT_ESCORT_LIMIT'e kadar olan muhafızlar liderin arkasında yürür;
## üstündeki (üçüncü parti üyesi) vagonların gerisinde arka nöbetçidir.
func _follower_target_x(
	index: int, leader_x: float, escort_count: int, wagon_count: int
) -> float:
	if index < FRONT_ESCORT_LIMIT or wagon_count <= 0:
		return leader_x - _front_escort_gap(index)
	return _wagon_target_x(wagon_count - 1, leader_x, escort_count) - REAR_GUARD_TRAIL

## Bir vagonun tayfası (bkz. GameSession.PEOPLE_PER_WAGON) vagonun etrafında
## dağınık yürür - isimli muhafızların aksine düzenli bir sıra tutmazlar,
## kervan resimlerindeki gibi bazısı önde bazısı yanında yürür (bkz.
## _crew_offset).
func _follow_wagon_crew(
	wagon_index: int, wagon_target_x: float, weight: float, delta: float
) -> void:
	for crew_slot in GameSession.PEOPLE_PER_WAGON:
		var crew_index := wagon_index * GameSession.PEOPLE_PER_WAGON + crew_slot
		if crew_index >= _crew.size():
			continue
		var crew_member := _crew[crew_index]
		var offset := _crew_offset(wagon_index, crew_slot)
		var crew_target := wagon_target_x + WAGON_SIZE.x * 0.5 + offset.x
		var before := crew_member.position.x
		crew_member.position.x = lerpf(before, crew_target, weight)
		crew_member.position.y = lerpf(
			crew_member.position.y, GROUND_Y - CREW_BODY_HEIGHT + offset.y, weight
		)
		crew_member.advance(
			delta, (crew_member.position.x - before) * STEP_PER_UNIT / maxf(delta, 0.0001)
		)

## Vagon başına asimetrik bir konum üretir - vagon+mevki'ye göre sabit
## (aynı tayfa her karede aynı yerde yürür) ama sıra hissi vermez: değişen
## mesafe, hafif dikey kayma ve vagondan vagona değişen yön.
func _crew_offset(wagon_index: int, crew_slot: int) -> Vector2:
	var alternates := (wagon_index + crew_slot) % 2 == 0
	var lead := CREW_GAP * (0.7 if crew_slot == 0 else 1.8)
	var side_kick := 8.0 if alternates else -8.0
	var drift := -6.0 if crew_slot == 0 else 9.0
	return Vector2(-lead + side_kick, drift)

## Şehrin dışındaki kır. Öncesinde iki dikdörtgen (bir gökyüzü, bir
## zemin) ve on dört çizgiden oluşuyordu; yol ekranıyla aynı şikâyetin
## aynı sebebi. Artık `HubScenery` çiziyor: aynı palet, aynı fırçalar,
## yani oyunun geri kalanıyla aynı dünya.
func _build_scenery() -> void:
	var scenery := HubScenery.new()
	scenery.z_index = -20
	add_child(scenery)
	scenery.setup(
		Rect2(
			Vector2(WORLD_MIN_X - 500.0, GROUND_Y - 620.0),
			Vector2(WORLD_MAX_X - WORLD_MIN_X + 1100.0, 1020.0)
		),
		GROUND_Y,
		GameState.get_session().current_location_id
	)

func _build_spots() -> void:
	_add_spot(
		_gate_label(),
		Vector2(1720.0, GROUND_Y - 230.0),
		Vector2(150.0, 230.0),
		GATE_COLOR,
		Nav.CITY_MAP
	)

## Kapının üstünde jenerik bir "Şehir Kapısı" değil, girilecek şehrin adı
## yazar - oyuncu yolda dururken nerede olduğunu okumak için HUD'a bakmak
## zorunda kalmasın. Şehir bilinmiyorsa (bozuk kayıt) jenerik etikete düşer.
func _gate_label() -> String:
	var session: GameSession = GameState.get_session()
	var location := WorldMapData.get_location_by_id(session.current_location_id)
	if location == null:
		return tr("UI_HUB_CITY_GATE")
	return tr("UI_HUB_CITY_GATE_NAMED") % location.location_name

func _add_spot(
	spot_name: String,
	position: Vector2,
	size: Vector2,
	color: Color,
	scene_path: String
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
	prompt.text = tr("UI_HUB_INTERACT")
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
		"prompt": prompt,
	})

## Kervanı sahiplik durumuna göre kurar: sahip olunan her vagon için bir
## vagon ve GameSession.PEOPLE_PER_WAGON kadar tayfa, partideki her kişi
## için bir gövde. Oyuncu partisi tek kişiyle başlar, tayfa topladıkça
## arkasında yürüyenler çoğalır. İsimli parti üyeleri _order_escorts()'un
## belirlediği muhafız sırasıyla eklenir - _follow_with_wagon o sırayı
## (0: hemen arkada, 1: ortalarda, 2: vagonların gerisinde) okur.
func _build_caravan() -> void:
	var session: GameSession = GameState.get_session()
	var party := session.get_party()
	var escorts := _order_escorts(session, party)
	var wagon_count := maxi(1, session.owned_wagon_count)
	# Lider her zaman x=0'da kuruluyor (bkz. _build_person); kervanın geri
	# kalanı ilk karede yerine kaymasın diye ilk konumunu her karede
	# kullanılan hedef formülünden alıyor. Ekleme sırası çizim sırasıdır -
	# vagonlar ve tayfa önce, insanlar üstlerine.
	var leader_x := 0.0

	for index in wagon_count:
		var wagon_x := _wagon_target_x(index, leader_x, escorts.size())
		_wagons.append(_build_wagon(index, wagon_x))
		# Vagonu çeken öküz. Olmadığı ilk ekran görüntüsünde vagonlar
		# kendi kendine yürüyor gibi duruyordu - kervan resmindeki en
		# temel öge eksikti.
		_oxen.append(_build_ox(wagon_x))
		for crew_slot in GameSession.PEOPLE_PER_WAGON:
			_crew.append(_build_crew_member(wagon_x, index, crew_slot))

	_player = _build_person(party[0], true)
	for index in escorts.size():
		var follower := _build_person(escorts[index], false)
		follower.position.x = _follower_target_x(index, leader_x, escorts.size(), wagon_count)
		_followers.append(follower)

## Lideri saymadan geri kalan parti üyelerini muhafız sırasına dizer: en
## önde levazımcı görevini taşıyan (yoksa en kıdemli - en yüksek seviyeli)
## kişi, o her zaman liderin hemen arkasında yürür (bkz. CLAUDE.md'nin
## "quartermaster gibi" notu). Geri kalanlar mevcut parti sırasını korur.
func _order_escorts(session: GameSession, party: Array[CharacterData]) -> Array[CharacterData]:
	var escorts: Array[CharacterData] = []
	for index in range(1, party.size()):
		escorts.append(party[index])
	if escorts.is_empty():
		return escorts

	var second := session.get_duty_holder(DutyCatalog.LEVAZIMCI)
	if second == null or not escorts.has(second):
		second = escorts[0]
		for candidate in escorts:
			if candidate.level > second.level:
				second = candidate

	var ordered: Array[CharacterData] = [second]
	for candidate in escorts:
		if candidate != second:
			ordered.append(candidate)
	return ordered

## Sadece ilk vagon etkileşim noktası - kervanın yükü tek envanterde.
func _build_wagon(index: int, wagon_x: float) -> WagonFigure:
	var wagon := WagonFigure.new()
	wagon.position = Vector2(wagon_x, GROUND_Y - WAGON_SIZE.y)
	add_child(wagon)
	wagon.setup(WAGON_SIZE, index == 0)

	var wagon_label := Label.new()
	wagon_label.text = tr("UI_HUB_WAGON") % (index + 1)
	wagon_label.position = Vector2(0.0, -26.0)
	wagon_label.size = Vector2(WAGON_SIZE.x, 24.0)
	wagon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wagon.add_child(wagon_label)

	if index > 0:
		return wagon

	var wagon_prompt := Label.new()
	wagon_prompt.text = tr("UI_HUB_INTERACT")
	wagon_prompt.position = Vector2(-40.0, WAGON_SIZE.y + 6.0)
	wagon_prompt.size = Vector2(WAGON_SIZE.x + 80.0, 24.0)
	wagon_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wagon_prompt.modulate = PROMPT_COLOR
	wagon_prompt.visible = false
	wagon.add_child(wagon_prompt)

	# Vagon hareket ettiği için kendi kaydı ayrı tutulur.
	_spots.append({
		"name": tr("UI_HUB_WAGON_SPOT"),
		"rect": Rect2(),
		"scene": Nav.ECONOMY,
		"prompt": wagon_prompt,
		"follows_wagon": true,
	})
	return wagon

## wagon_x, o vagonun o anki x'i - _follow_wagon_crew'daki hedef formülüyle
## aynısı (_crew_offset dahil) kullanılır ki ilk karede kervan konumundan
## içeri kaymasın.
func _build_ox(wagon_x: float) -> WalkFigure:
	var ox := WalkFigure.new()
	ox.size = OX_SIZE
	ox.position = Vector2(wagon_x + OX_LEAD, GROUND_Y - OX_SIZE.y)
	add_child(ox)
	ox.set_kind(WalkFigure.KIND_OX, "bandit")
	ox.set_phase_offset(wagon_x * 0.02)
	return ox

func _build_crew_member(wagon_x: float, wagon_index: int, crew_slot: int) -> WalkFigure:
	var offset := _crew_offset(wagon_index, crew_slot)
	var body := WalkFigure.new()
	body.size = Vector2(BODY_WIDTH, CREW_BODY_HEIGHT)
	body.position = Vector2(
		wagon_x + WAGON_SIZE.x * 0.5 + offset.x,
		GROUND_Y - CREW_BODY_HEIGHT + offset.y
	)
	add_child(body)
	# Tayfa isimsiz: sınıfı yok, nötr bir silüet paleti taşıyor.
	body.set_kind(
		WalkFigure.KIND_PERSON, "bandit", 0.95,
		CharacterData.get_skin_tone_color(wagon_index * 2 + crew_slot), true
	)
	body.set_phase_offset(float(wagon_index * 3 + crew_slot) * 1.31)
	return body

## Gövde yüksekliği karakterin boyundan, rengi ten renginden geliyor -
## oluşturma ekranında seçilenler yolda da görünsün diye. Lider at
## üstünde: kervanın önünde gidiyor ve vagonlara bağlı değil.
func _build_person(character: CharacterData, is_leader: bool) -> WalkFigure:
	var height_ratio := inverse_lerp(
		float(CharacterData.MIN_HEIGHT_CM),
		float(CharacterData.MAX_HEIGHT_CM),
		float(character.height_cm)
	)
	var body_height := lerpf(BODY_MIN_HEIGHT, BODY_MAX_HEIGHT, clampf(height_ratio, 0.0, 1.0))
	var body_width := BODY_WIDTH
	if is_leader:
		body_height = MOUNTED_HEIGHT
		body_width = MOUNTED_WIDTH

	var body := WalkFigure.new()
	body.size = Vector2(body_width, body_height)
	# x'i çağıran belirliyor (bkz. _build_caravan): lider 0'da kalır,
	# takipçiler kendi hedef konumlarında kurulur.
	body.position = Vector2(0.0, GROUND_Y - body_height)
	add_child(body)
	body.set_kind(
		WalkFigure.KIND_MOUNTED if is_leader else WalkFigure.KIND_PERSON,
		character.class_id,
		clampf(float(character.height_cm) / float(CharacterData.DEFAULT_HEIGHT_CM), 0.86, 1.14),
		CharacterData.get_skin_tone_color(character.skin_tone),
		not is_leader
	)

	var label := Label.new()
	label.text = character.character_name if is_leader else character.character_name.split(" ")[0]
	label.position = Vector2(-45.0, -28.0)
	label.size = Vector2(body_width + 90.0, 24.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
			_hint(tr("UI_HUB_TOO_FAR") % spot.name)
		return

func _try_interact_nearest() -> void:
	for spot in _spots:
		if _is_in_range(spot):
			_enter_spot(spot)
			return

func _enter_spot(spot: Dictionary) -> void:
	get_tree().change_scene_to_file(Nav.open(Nav.WORLD_HUB, spot.scene))

func _hint(text: String) -> void:
	_hint_label.text = text

func _refresh_status() -> void:
	var session: GameSession = GameState.get_session()
	var location := WorldMapData.get_location_by_id(session.current_location_id)
	# Türkçeye özgü harf taşımadığı için sabit metin taramasından kaçmıştı.
	var location_name := tr("UI_HUB_ON_THE_ROAD") if location == null else location.location_name
	var debt_note := ""
	if session.get_total_debt() > 0:
		debt_note = tr("UI_HUD_DEBT") % session.get_total_debt()
	_status_label.text = (tr("UI_HUB_HUD") + debt_note) % [
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
	get_tree().change_scene_to_file(Nav.open(Nav.WORLD_HUB, Nav.PARTY))

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(Nav.go_root(Nav.MAIN_MENU))
