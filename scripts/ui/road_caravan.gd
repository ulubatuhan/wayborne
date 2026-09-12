class_name RoadCaravan
extends Control

## Yolda yürüyen kervan: önde lider, arkasında parti, sonra öküzlerin
## çektiği vagonlar ve tayfa.
##
## **Lider vagonlara bağlı değil.** Önde gidiyor - atı varsa at üstünde,
## yoksa yayan. Kolondan ayrılıp geriye doğru yürüyebiliyor ("siz devam
## edin"), ama kervanın boyundan uzaklaşamıyor: bir kervan lideri yalnız
## başına yola çıkmaz, kolonun içinde dolaşır.
##
## Çizim ikiye ayrılmış durumda ve bu bilinçli:
##
## - İnsanlar ve hayvanlar ayrı `WalkFigure` düğümleri - kendi yürüyüş
##   fazları var, o yüzden hepsi aynı anda aynı adımı atmıyor. Bütün
##   kervanın tek ritimde yürümesi asker gibi duruyor, kervan gibi
##   durmuyor.
## - Vagonlar bu düğümün kendi `_draw()`'unda - tekerlek dönüşü yolun
##   hızına bağlı ve gövde figür değil araç.
##
## Zemin çizgisini kendisi hesaplamıyor, `TravelBand`'den alıyor
## (`ground_line_changed`). İkisi ayrı hesaplarsa kervan eğimli yolda
## havada ya da toprağın içinde yürüyor.

## Lider kolonun ne kadar önünde. Atlıysa daha önde: at yürüyüşü hızlı.
const LEAD_WALKING: float = 92.0
const LEAD_MOUNTED: float = 148.0

## Kolon aralıkları. Vagon aralığı vagonun genişliğinden *belirgin* olarak
## büyük olmalı: ilk ölçülerde 132'ye 138 genişlik vardı ve iki vagon üst
## üste biniyordu - ekran görüntüsünde tek bir dev branda gibi duruyordu.
const PARTY_SPACING: float = 44.0
const WAGON_SPACING: float = 176.0
const OX_OFFSET: float = 58.0

## Figür boyları (şeridin yüksekliğine oranlı, yoksa küçük ekranda dev
## gibi duruyorlar).
const PERSON_HEIGHT_RATIO: float = 0.19
const MOUNTED_HEIGHT_RATIO: float = 0.27
const OX_HEIGHT_RATIO: float = 0.15

## Yürüyüş temposu: bir "gün/saniye"lik hız kaç adım. Sayının kendisi
## görsel; yolun gerçek hızı road_journey'de.
const STEP_RATE: float = 2.6

## Vagon ölçüleri. Genişlik yükseklikten biraz fazla: bir kervan vagonu
## kareye yakındır, ilk ölçüde 1.6 katıydı ve balon gibi duruyordu.
const WAGON_WIDTH_RATIO: float = 0.21
const WAGON_HEIGHT_RATIO: float = 0.17

## Çizilen yürüyen tayfa sayısı tavanlı: altı vagonlu bir kervanda on iki
## tayfa var ama her biri kendi poligonlarını çiziyor ve Web hedefinde
## bunun bedeli görünür. Arabacılar zaten vagonun üstünde çiziliyor;
## yürüyenler onların fazlası.
const MAX_WALKING_CREW: int = 4

var _anchor_x: float = 0.0
var _ground_y: float = 0.0
var _light: Color = Color.WHITE
var _speed: float = 0.0
## Liderin kolondaki yeri: 0 en önde, negatif geriye doğru.
var _leader_offset: float = 0.0
var _wagon_count: int = 1
var _wheel_angle: float = 0.0
var _detached: bool = false

var _leader: WalkFigure
var _leader_mounted: bool = false
var _party_figures: Array[WalkFigure] = []
var _crew_figures: Array[WalkFigure] = []
var _oxen: Array[WalkFigure] = []

## Altında bir şey çizmenin anlamı olmadığı boy. Bunun altında vagonun
## bütün ölçüleri piksel altına düşüyor ve çokgenlerin köşeleri aynı
## float'a çöküyor - Godot "Invalid polygon data, triangulation failed"
## basıp çizimi atlıyor, oyunu durdurmuyor. Yani ekran görüntüsü
## alınmadan hiç görülmeyecek bir hata; yapısal testler de görmüyor.
const MIN_DRAW_HEIGHT: float = 60.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Çapa ön ayarı boyutu *bir sonraki* yerleşim geçişinde veriyor, yani
	# `configure()` çağrıldığı anda boy hâlâ sıfır olabiliyor. Yeniden
	# boyutlanmayı dinlemezsek kolon o sıfır boyla yerleşip öyle kalıyordu:
	# figürler görünmez, vagonlar yarım piksel.
	resized.connect(_on_resized)

func _on_resized() -> void:
	_layout()
	queue_redraw()

## Kervanı oturumdan kurar. Her çağrı figürleri yeniden yaratıyor, o yüzden
## sefer başında (ve parti değişince) çağrılmalı, karede değil.
func configure(session: GameSession, mounted_leader: bool = true) -> void:
	for child in get_children():
		child.queue_free()
	_party_figures.clear()
	_crew_figures.clear()
	_oxen.clear()
	_leader = null

	_wagon_count = maxi(1, session.owned_wagon_count)
	_leader_mounted = mounted_leader

	var party := session.party
	var player := session.get_player_character()

	_leader = _make_figure(
		WalkFigure.KIND_MOUNTED if mounted_leader else WalkFigure.KIND_PERSON,
		_archetype_of(player), _height_scale_of(player), _skin_of(player), false
	)
	_leader.set_facing(1.0)

	# Parti lideri takip ediyor; sıra savaş sırası (bkz. Character & Party
	# Rules), o yüzden kolonda gördüğün diziliş savaşta göreceğin diziliş.
	for character in party:
		if character == player:
			continue
		_party_figures.append(_make_figure(
			WalkFigure.KIND_PERSON, _archetype_of(character),
			_height_scale_of(character), _skin_of(character), true
		))


	for index in _wagon_count:
		_oxen.append(_make_figure(
			WalkFigure.KIND_OX, "bandit", 1.0, WalkFigure.FALLBACK_SKIN, false
		))

	var walking_crew := mini(MAX_WALKING_CREW, _wagon_count * GameSession.PEOPLE_PER_WAGON - _wagon_count)
	for index in maxi(0, walking_crew):
		# Tayfa isimsiz: sınıfı yok, o yüzden nötr bir silüet paleti
		# taşıyorlar. Ten renkleri yine oyunun kendi tonlarından.
		_crew_figures.append(_make_figure(
			WalkFigure.KIND_PERSON, "bandit", 0.94 + float(index % 3) * 0.04,
			CharacterData.get_skin_tone_color(index), true
		))

	_layout()

func _make_figure(
	kind: String, archetype: String, height_scale: float, skin: Color, pack: bool
) -> WalkFigure:
	var figure := WalkFigure.new()
	add_child(figure)
	figure.set_kind(kind, archetype, height_scale, skin, pack)
	# Faz kaydırması: aynı anda aynı adımı atan bir kervan yürüyüş kolu
	# gibi duruyor.
	figure.set_phase_offset(float(get_child_count()) * 1.27)
	return figure

func _archetype_of(character: CharacterData) -> String:
	if character == null:
		return "guard"
	return character.class_id if not character.class_id.is_empty() else "guard"

## Boy yolda görünüyor: karakter oluşturmada seçilen boy bir metin değil.
func _height_scale_of(character: CharacterData) -> float:
	if character == null:
		return 1.0
	return clampf(
		float(character.height_cm) / float(CharacterData.DEFAULT_HEIGHT_CM), 0.86, 1.14
	)

func _skin_of(character: CharacterData) -> Color:
	if character == null:
		return WalkFigure.FALLBACK_SKIN
	return CharacterData.get_skin_tone_color(character.skin_tone)

## `TravelBand`'in bildirdiği zemin çizgisi. Kervanın bastığı yer burası.
func set_ground_line(anchor_x: float, ground_y: float) -> void:
	# Çapa ön ayarına güvenmiyoruz. `PRESET_FULL_RECT` boyutu ancak
	# ebeveyn *yeniden boyutlanınca* çocuğa geçiriyor; manzara şeridi
	# kendi boyunu biz eklemeden önce aldığı için o bildirim hiç gelmiyor
	# ve kolon (0,0) boyunda kalıyordu - figürler görünmez, vagonlar
	# yarım piksel. Aynı sınıf hata OnboardingPanel'de de yaşandı
	# ("bir CanvasLayer Control değildir"): çapa, altında gerçek bir
	# dikdörtgen yoksa hiçbir şey yapmıyor.
	var host := get_parent_control()
	if host != null and host.size != size:
		size = host.size

	if is_equal_approx(_anchor_x, anchor_x) and is_equal_approx(_ground_y, ground_y):
		# Zemin çizgisi aynı olsa bile kolon henüz hiç yerleşmemiş
		# olabilir (bkz. _on_resized): erken çıkış o durumda figürleri
		# sıfır boyda bırakıyordu.
		if _leader != null and _leader.size.y > 1.0:
			return
	_anchor_x = anchor_x
	_ground_y = ground_y
	_layout()
	queue_redraw()

func set_light(light: Color) -> void:
	if _light == light:
		return
	_light = light
	for child in get_children():
		var figure := child as WalkFigure
		if figure != null:
			figure.set_tint(light)
	queue_redraw()

## Kervanın o anki yürüyüş hızı (gün/saat cinsinden değil, görsel tempo:
## 0 durgun, 1 normal). Yürüyüş fazı ve tekerlek dönüşü bundan.
func set_speed(speed: float) -> void:
	_speed = speed

## Lider kolondan ayrıldığında A/D onu yürütüyor, kervanı değil. Sınır
## kolonun uzunluğu: lider kervanı bırakıp gidemiyor.
func set_leader_offset(offset: float) -> void:
	_leader_offset = clampf(offset, -_column_length(), 0.0)
	_layout()

func get_leader_offset() -> float:
	return _leader_offset

func get_column_length() -> float:
	return _column_length()

func set_detached(detached: bool) -> void:
	_detached = detached
	queue_redraw()

func _column_length() -> float:
	var lead := LEAD_MOUNTED if _leader_mounted else LEAD_WALKING
	return (
		lead + float(_party_figures.size()) * PARTY_SPACING
		+ float(_wagon_count) * WAGON_SPACING + 40.0
	)

func _process(delta: float) -> void:
	if _leader == null:
		return
	# Faz herkeste ilerliyor; duran bir figür de `advance(0)` alıyor ki
	# ayaklarını yan yana toplasın.
	var step := _speed * STEP_RATE
	for child in get_children():
		var figure := child as WalkFigure
		if figure != null:
			figure.advance(delta, step)
	if not is_zero_approx(_speed):
		_wheel_angle = fmod(_wheel_angle + delta * _speed * 4.2, TAU)
		queue_redraw()

## Kolonun yerleşimi. Hepsi çapadan (kervanın ekrandaki sabit noktası)
## geriye doğru; lider öne.
func _layout() -> void:
	if _leader == null or _ground_y <= 0.0 or size.y < MIN_DRAW_HEIGHT:
		return
	var height := maxf(size.y, 1.0)
	var person_h := height * PERSON_HEIGHT_RATIO
	var mounted_h := height * MOUNTED_HEIGHT_RATIO
	var ox_h := height * OX_HEIGHT_RATIO

	var lead := LEAD_MOUNTED if _leader_mounted else LEAD_WALKING
	var leader_h := mounted_h if _leader_mounted else person_h
	_place(_leader, _anchor_x + lead + _leader_offset, leader_h, leader_h * 1.6)

	var cursor := _anchor_x
	for figure in _party_figures:
		_place(figure, cursor, person_h, person_h * 0.9)
		cursor -= PARTY_SPACING

	# Vagonlar ve onları çeken öküzler; öküz vagonun önünde.
	var wagon_w := height * WAGON_WIDTH_RATIO
	for index in _wagon_count:
		var wagon_x := cursor - float(index) * WAGON_SPACING - wagon_w * 0.5
		if index < _oxen.size():
			_place(_oxen[index], wagon_x + wagon_w * 0.5 + OX_OFFSET, ox_h, ox_h * 2.0)

	var crew_base := cursor - float(_wagon_count) * WAGON_SPACING
	for index in _crew_figures.size():
		# Tayfa düzenli sıra tutmuyor (bkz. world_hub'ın _crew_offset'i):
		# vagonun yanında dağınık yürüyorlar.
		var jitter := sin(float(index) * 2.4) * 26.0
		_place(_crew_figures[index], crew_base + jitter - float(index) * 34.0, person_h * 0.95, person_h * 0.9)

func _place(figure: WalkFigure, x: float, height: float, width: float) -> void:
	figure.size = Vector2(width, height)
	figure.position = Vector2(x - width * 0.5, _ground_y - height)

func _draw() -> void:
	if _ground_y <= 0.0 or size.y < MIN_DRAW_HEIGHT:
		return
	var height := size.y
	var wagon_w := height * WAGON_WIDTH_RATIO
	var wagon_h := height * WAGON_HEIGHT_RATIO
	var cursor := _anchor_x - float(_party_figures.size()) * PARTY_SPACING

	for index in _wagon_count:
		var x := cursor - float(index) * WAGON_SPACING - wagon_w * 0.5
		# Vagon `ArtDraw`'da: aynı vagon şehir dışı yürüyüş alanında da
		# çiziliyor ve iki kopya tutulunca aynı kervan iki ekranda iki
		# farklı şey oluyordu.
		ArtDraw.wagon(
			self, Vector2(x, _ground_y), wagon_w, wagon_h,
			_wheel_angle, _light, index == 0
		)

	if _detached:
		# Lider kolondan ayrıldığında kervanın başı işaretli: oyuncu
		# hangisinin kendisi olduğunu karıştırmasın.
		var lead := LEAD_MOUNTED if _leader_mounted else LEAD_WALKING
		var marker := Vector2(_anchor_x + lead + _leader_offset, _ground_y - height * 0.40)
		draw_colored_polygon(PackedVector2Array([
			marker + Vector2(-5.0, -9.0), marker + Vector2(5.0, -9.0), marker,
		]), Color(ArtPalette.GOLD, 0.85))
