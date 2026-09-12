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

## Kolon aralıkları. **Hepsi boşluk, konum değil.** Yerleşim sabit
## adımlarla değil, her parçanın gerçek genişliğini tüketen bir imleçle
## kuruluyor (bkz. _layout): sabit adım kullanıldığında vagon genişliği
## ya da öküz boyu değişince çakışma geri geliyordu - iki kez yaşandı,
## önce iki vagon üst üste bindi, sonra arkadaki vagonun öküzü öndeki
## vagonun içine girdi. Boşluklar birbirine eklendiği için çakışma artık
## tasarım gereği imkânsız.
const GAP_TIGHT: float = 26.0
const GAP_NORMAL: float = 46.0
const GAP_WAGONS: float = 88.0
## Öküz ile çektiği vagon arasındaki ok mesafesi.
const HITCH_GAP: float = 22.0

## Yan yana en fazla iki kişi yürüyor. Aralarındaki mesafe **kişinin
## genişliğinden türetiliyor**, sabit değil: sabit bir 30 piksel,
## seksen piksel genişliğindeki bir figürde iki kişiyi üst üste
## bindiriyordu. Kolonun geri kalanında olduğu gibi burada da ölçü
## boşluk, konum değil.
const PAIR_GAP: float = 22.0
const MAX_ABREAST: int = 2

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

## Yerleşimin hesapladığı vagon merkezleri. Çizim bunları okuyor,
## kendi aritmetiğini yapmıyor: iki ayrı formül tam olarak öküzün
## vagonun içine girmesine yol açan şeydi.
var _wagon_centres: Array[float] = []

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

	# Vagon başına iki tayfa var (`PEOPLE_PER_WAGON`): biri sürüyor -
	# `ArtDraw.wagon` onu brandanın önünde çiziyor - biri yürüyor. Yani
	# yürüyen tayfa sayısı vagon sayısı kadar.
	var walking_crew := mini(MAX_WALKING_CREW, _wagon_count)
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

## Kolonun toplam boyu - lider bu kadar geriye gidebiliyor. Yerleşimle
## aynı boşluklardan hesaplanıyor: ayrı bir tahmin tutmak, liderin
## kolonun ucundan taşmasına ya da kuyruğa hiç ulaşamamasına yol
## açardı.
func _column_length() -> float:
	var height := maxf(size.y, 1.0)
	var lead := LEAD_MOUNTED if _leader_mounted else LEAD_WALKING
	var person_w := height * PERSON_HEIGHT_RATIO * 0.9
	var wagon_w := height * WAGON_WIDTH_RATIO
	var ox_w := height * OX_HEIGHT_RATIO * 2.0
	var groups := int(ceil(float(_party_figures.size()) / float(MAX_ABREAST)))
	return (
		lead
		+ float(groups) * (float(MAX_ABREAST) * (person_w + PAIR_GAP) + GAP_NORMAL)
		+ float(_wagon_count) * (ox_w + HITCH_GAP + wagon_w + GAP_WAGONS)
		+ GAP_TIGHT
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

## Kolonun yerleşimi: çapadan geriye doğru yürüyen bir imleç.
##
## Her parça kendi genişliği kadar yer tüketiyor ve araya bir boşluk
## giriyor, yani **çakışma tasarım gereği imkânsız**. Sabit adımlı ilk
## sürümde öyle değildi: `WAGON_SPACING` vagon genişliğinden bağımsızdı,
## bir ölçü değişince arkadaki vagonun öküzü öndeki vagonun içine
## giriyordu.
##
## Diziliş kuralları:
## - Lider en önde ve kolondan bağımsız.
## - Parti üyeleri **kolon boyunca dağılıyor**, en fazla ikişer yan yana:
##   hepsini liderin arkasına dizmek bir muhafız duvarı yapıyordu.
## - Tayfa kendi vagonunun *yanında* yürüyor, arkasında değil - kervanın
##   en arkasında yürüyen isimsiz bir kuyruk, sürüklenen bir grup gibi
##   duruyordu.
func _layout() -> void:
	if _leader == null or _ground_y <= 0.0 or size.y < MIN_DRAW_HEIGHT:
		return
	_wagon_centres.clear()
	var height := maxf(size.y, 1.0)
	var person_h := height * PERSON_HEIGHT_RATIO
	var person_w := person_h * 0.9
	var mounted_h := height * MOUNTED_HEIGHT_RATIO
	var ox_h := height * OX_HEIGHT_RATIO
	var ox_w := ox_h * 2.0
	var wagon_w := height * WAGON_WIDTH_RATIO

	var lead := LEAD_MOUNTED if _leader_mounted else LEAD_WALKING
	var leader_h := mounted_h if _leader_mounted else person_h
	_place(_leader, _anchor_x + lead + _leader_offset, leader_h, leader_h * 1.6)

	# Parti üyeleri kolon boyunca ikişerli gruplar hâlinde dağılıyor.
	var placed := 0
	var cursor := _anchor_x

	# Önce liderin hemen arkasındaki muhafız grubu.
	cursor = _place_escort_group(cursor, placed, person_h, person_w)
	placed += MAX_ABREAST

	for index in _wagon_count:
		# Bir vagon birimi, önden arkaya: [öküz] [tayfa] [vagon].
		# Yürüyen tayfa **vagonun önünde**, öküzle vagon arasında. Yanına
		# koymak gövdeyle örtüşüyordu; arkasına koymak da tam olarak
		# istenmeyen şeydi - vagonların arkasında sürüklenen isimsiz bir
		# kuyruk.
		if index < _oxen.size():
			cursor -= ox_w * 0.5
			_place(_oxen[index], cursor, ox_h, ox_w)
			cursor -= ox_w * 0.5 + GAP_TIGHT

		cursor = _place_crew(index, cursor, person_h, person_w)
		cursor -= HITCH_GAP

		var wagon_centre := cursor - wagon_w * 0.5
		_wagon_centres.append(wagon_centre)
		cursor -= wagon_w + GAP_WAGONS

		# Vagonlar arasına bir parti grubu daha serpiştiriyoruz: parti
		# kolon boyunca dağılıyor, hepsi liderin arkasında toplanmıyor.
		if placed < _party_figures.size() and index < _wagon_count - 1:
			cursor = _place_escort_group(cursor, placed, person_h, person_w)
			placed += MAX_ABREAST

	# Artakalan parti üyeleri en arkada, ama tayfayla aynı hizada değil.
	while placed < _party_figures.size():
		cursor = _place_escort_group(cursor, placed, person_h, person_w)
		placed += MAX_ABREAST

## İkişerli bir muhafız grubu yerleştirir ve imleci grubun tükettiği
## kadar geriye alır.
func _place_escort_group(
	cursor: float, from_index: int, person_h: float, person_w: float
) -> float:
	var count := mini(MAX_ABREAST, _party_figures.size() - from_index)
	if count <= 0:
		return cursor
	var step := person_w + PAIR_GAP
	for slot in count:
		_place(
			_party_figures[from_index + slot],
			cursor - float(slot) * step, person_h, person_w
		)
	return cursor - float(count - 1) * step - person_w - GAP_NORMAL

## Tek bir tayfa figürünü imlecin bulunduğu yere koyar ve imleci onun
## genişliği kadar geriye alır. O tayfa yoksa (vagon sayısına göre
## tayfa tavanı dolmuşsa) imleç olduğu gibi dönüyor - boşluk bile
## bırakmıyor, yoksa var olmayan bir kişi için kolonda delik kalırdı.
func _place_crew(
	crew_index: int, cursor: float, person_h: float, person_w: float
) -> float:
	if crew_index >= _crew_figures.size():
		return cursor
	_place(_crew_figures[crew_index], cursor - person_w * 0.5, person_h * 0.95, person_w)
	return cursor - person_w - GAP_TIGHT

func _place(figure: WalkFigure, x: float, height: float, width: float) -> void:
	figure.size = Vector2(width, height)
	figure.position = Vector2(x - width * 0.5, _ground_y - height)

func _draw() -> void:
	if _ground_y <= 0.0 or size.y < MIN_DRAW_HEIGHT:
		return
	var height := size.y
	var wagon_w := height * WAGON_WIDTH_RATIO
	var wagon_h := height * WAGON_HEIGHT_RATIO

	for index in _wagon_centres.size():
		# Merkez yerleşimden geliyor, burada yeniden hesaplanmıyor.
		# Vagon gövdesi `ArtDraw`'da: aynı vagon şehir dışı yürüyüş
		# alanında da çiziliyor ve iki kopya tutulunca aynı kervan iki
		# ekranda iki farklı şey oluyordu.
		ArtDraw.wagon(
			self, Vector2(_wagon_centres[index], _ground_y), wagon_w, wagon_h,
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
