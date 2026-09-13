class_name CityView
extends Control

## Şehrin kendisi: üstten bakışlı izometrik bir orta çağ kasabası.
##
## Öncesinde burada beş `Button` vardı, bir panelin içine elle konmuş
## koordinatlarla. Şehir oyunun karar merkezi (bkz. City Hub Rules) ama
## ekranda bir kasaba değil bir buton listesi duruyordu - "Excel'de oyun
## yapıyoruz" şikâyetinin şehirdeki karşılığı.
##
## Üç kural:
##
## 1. **Yerleşim tohumdan.** Sokaklar, sur, sivil evler ve beş mekânın
##    yeri `location_id`'den hesaplanıyor; her şehir farklı görünüyor ama
##    aynı şehir her gelişte aynı. Saklanmıyor - aynı gerekçe
##    `RouteTerrain`'de de var.
## 2. **Beş mekânın kendi mimarisi var.** Kilise çan kuleli ve taş,
##    taverna ahşap ve ışıklı, lonca sütunlu, kervan avlusu duvarlı ve
##    örs dumanlı, pazar ise bina değil - tenteli bir meydan. Oyuncu
##    yazıyı okumadan hangisinin ne olduğunu bilmeli.
## 3. **Üstüne gelince ne yapabileceğini söylüyor.** Balon, mekânın adını
##    ve orada yapılabilecek işleri taşıyor; tıklayınca o ekran açılıyor.
##    "Bir uyarı yalnızca oyuncuyu endişelendiriyorsa, hiç olmamasından
##    kötüdür" kuralının mekân karşılığı.
##
## Çizim sırası derinliğe göre (gx+gy): öndeki bina arkadakini kapatıyor.
## Tıklama de ters sırada yoklanıyor, yoksa arkadaki bina öndekinin
## üstünden basılabiliyor.

signal venue_pressed(scene_path: String)

## İzometrik karo ölçüsü. Genişlik/yükseklik oranı 2:1 - klasik "2:1
## izometrik", Town of Salem'in de kullandığı oran.
const TILE_W: float = 58.0
const TILE_H: float = 29.0

## Kasaba ızgarası. Beş mekân + sivil evler bunun içine yerleşiyor.
const GRID: int = 9

## Bina yüksekliği kat başına.
const STOREY: float = 26.0

## --- Palet ---
## Kasaba **gündüz**: ilk denemede zemin ve duvarlar koyuydu ve ekran
## görüntüsünde sonuç bir kasaba değil karanlık bir çukur gibi
## duruyordu - binalar birbirinden ayrılmıyordu. Üstten bakışlı bir
## kasabanın okunması ton farkına dayanıyor, o yüzden zemin açık,
## çatılar doygun.
const GROUND: Color = Color(0.52, 0.55, 0.38)
const GROUND_ALT: Color = Color(0.47, 0.51, 0.34)
const STREET: Color = Color(0.66, 0.60, 0.47)
const STREET_EDGE: Color = Color(0.50, 0.45, 0.35)
const WALL_STONE: Color = Color(0.68, 0.66, 0.60)
const WALL_STONE_SIDE: Color = Color(0.54, 0.52, 0.48)
const PLASTER: Color = Color(0.86, 0.81, 0.68)
const TIMBER: Color = Color(0.34, 0.25, 0.18)
const ROOF_TILE: Color = Color(0.64, 0.30, 0.22)
const ROOF_SLATE: Color = Color(0.36, 0.38, 0.46)
const ROOF_THATCH: Color = Color(0.62, 0.50, 0.26)
const WINDOW_LIT: Color = Color(0.98, 0.80, 0.44)

## Evlerin kasabayı doldurma oranı. Yüksek olunca mekânlar kalabalığın
## içinde kayboluyor - oyuncunun aradığı beş bina onlar.
const HOUSE_CHANCE: float = 0.38

const ROOF_COLORS: Array[Color] = [ROOF_TILE, ROOF_THATCH, ROOF_SLATE]

## Mekânlar. `kind` mimariyi, `name_key`/`desc_key` balonu, `scene` de
## tıklayınca açılacak ekranı veriyor. Tek tablo: ekranda görünen bina ile
## açılan ekran ayrışamaz.
const VENUE_MARKET: String = "market"
const VENUE_GUILD: String = "guild"
const VENUE_TAVERN: String = "tavern"
const VENUE_YARD: String = "yard"
const VENUE_CHURCH: String = "church"

var _session: GameSession
var _city_id: String = ""
## Her biri {"kind", "gx", "gy", "w", "d", "storeys", "roof", "venue",
## "name_key", "desc_key", "scene", "bounds"}.
var _buildings: Array[Dictionary] = []
var _hovered: int = -1
var _tooltip: PanelContainer
var _tooltip_title: Label
var _tooltip_body: Label
var _time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(queue_redraw)
	_build_tooltip()

func setup(session: GameSession) -> void:
	_session = session
	_city_id = session.current_location_id
	_lay_out_city()
	queue_redraw()

func _process(delta: float) -> void:
	# Yalnızca duman ve ışık kıpırdıyor; sahne bunun dışında durağan.
	_time += delta
	if fmod(_time, 0.12) < delta:
		queue_redraw()

# --- Yerleşim ---

## Kasabayı kurar. Beş mekân sabit *rollerde* ama değişken yerlerde:
## şehir tohumu hangi köşeye ne düştüğünü belirliyor, yani Karakonak ile
## Demirkapı aynı kasaba değil.
func _lay_out_city() -> void:
	_buildings.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("city|%s" % _city_id)

	# Mekânlar ızgaranın dört köşesine ve ortasına dağılıyor; hangi rolün
	# hangi yuvaya düştüğü karıştırılıyor. Ortadaki yuva her zaman pazar:
	# bir orta çağ kasabasının merkezi meydanıdır ve oyuncu en çok oraya
	# gidiyor.
	var slots: Array[Vector2i] = [
		Vector2i(1, 1), Vector2i(GRID - 3, 1),
		Vector2i(1, GRID - 3), Vector2i(GRID - 3, GRID - 3),
	]
	# Fisher-Yates: tohumdan deterministik karıştırma.
	for index in range(slots.size() - 1, 0, -1):
		var swap := rng.randi_range(0, index)
		var carry := slots[index]
		slots[index] = slots[swap]
		slots[swap] = carry

	var venues: Array[Dictionary] = [
		{
			"kind": VENUE_CHURCH, "w": 2, "d": 2, "storeys": 2,
			"name_key": "UI_CITY_CHURCH", "desc_key": "UI_CITY_CHURCH_ACTIONS",
			"scene": Nav.CHURCH,
		},
		{
			"kind": VENUE_GUILD, "w": 2, "d": 2, "storeys": 2,
			"name_key": "UI_GUILD_TITLE", "desc_key": "UI_CITY_GUILD_ACTIONS",
			"scene": Nav.GUILD,
		},
		{
			"kind": VENUE_TAVERN, "w": 2, "d": 2, "storeys": 2,
			"name_key": "UI_TAVERN_TITLE", "desc_key": "UI_CITY_TAVERN_ACTIONS",
			"scene": Nav.TAVERN,
		},
		{
			"kind": VENUE_YARD, "w": 3, "d": 2, "storeys": 1,
			"name_key": "UI_CITY_YARD", "desc_key": "UI_CITY_YARD_ACTIONS",
			"scene": Nav.CARAVAN_YARD,
		},
	]
	for index in venues.size():
		var venue: Dictionary = venues[index].duplicate()
		venue["gx"] = slots[index].x
		venue["gy"] = slots[index].y
		venue["venue"] = true
		venue["roof"] = ROOF_SLATE
		_buildings.append(venue)

	var centre := int(GRID / 2) - 1
	_buildings.append({
		"kind": VENUE_MARKET, "gx": centre, "gy": centre, "w": 2, "d": 2,
		"storeys": 0, "venue": true, "roof": ROOF_TILE,
		"name_key": "UI_CITY_MARKET", "desc_key": "UI_CITY_MARKET_ACTIONS",
		"scene": Nav.ECONOMY,
	})

	# Sivil evler: mekânların arasını dolduruyorlar. "Binalar olsun
	# rastgele" - ama boş kalan karolara, mekânların üstüne değil.
	for gx in GRID:
		for gy in GRID:
			if _is_occupied(gx, gy) or _is_street(gx, gy):
				continue
			if rng.randf() > HOUSE_CHANCE:
				continue
			_buildings.append({
				"kind": "house", "gx": gx, "gy": gy, "w": 1, "d": 1,
				"storeys": 1 if rng.randf() < 0.65 else 2,
				"venue": false, "roof": ROOF_COLORS[rng.randi_range(0, 2)],
				"name_key": "", "desc_key": "", "scene": "",
			})

	# Derinlik sırası: arkadaki önce çizilecek.
	_buildings.sort_custom(
		func(a, b): return (int(a.gx) + int(a.gy)) < (int(b.gx) + int(b.gy))
	)

func _is_occupied(gx: int, gy: int) -> bool:
	for building in _buildings:
		var bx := int(building.gx)
		var by := int(building.gy)
		if gx >= bx and gx < bx + int(building.w) and gy >= by and gy < by + int(building.d):
			return true
	return false

## Ana yollar: ızgaranın ortasından geçen iki sokak. Evler onların üstüne
## kurulmuyor, yani kasabanın bir dolaşım şeması oluyor.
func _is_street(gx: int, gy: int) -> bool:
	var mid := int(GRID / 2)
	return gx == mid or gy == mid

# --- İzometrik dönüşüm ---

func _origin() -> Vector2:
	# Kasaba ekranın ortasına oturuyor; ızgaranın toplam genişliği
	# (GRID-1)*TILE_W, o yüzden sol yarısı kadar sağa kaydırıyoruz.
	return Vector2(size.x * 0.5, size.y * 0.5 - float(GRID) * TILE_H * 0.5 + TILE_H)

func _tile(gx: float, gy: float) -> Vector2:
	var o := _origin()
	return o + Vector2((gx - gy) * TILE_W * 0.5, (gx + gy) * TILE_H * 0.5)

## Bir karonun dört köşesi - zemin ve çatı yüzleri bundan.
func _tile_quad(gx: float, gy: float, w: float, d: float) -> PackedVector2Array:
	return PackedVector2Array([
		_tile(gx, gy),
		_tile(gx + w, gy),
		_tile(gx + w, gy + d),
		_tile(gx, gy + d),
	])

# --- Çizim ---

func _draw() -> void:
	if _buildings.is_empty():
		return
	var area := Rect2(Vector2.ZERO, size)
	# Kasabanın çevresi: şehir surunun dışındaki kır. Koyu bir hiçlik
	# yerine gerçek bir arazi olması, kasabanın bir yerde durduğunu
	# söylüyor.
	ArtDraw.gradient_band(
		self, area, Color(0.30, 0.36, 0.40), Color(0.36, 0.38, 0.28)
	)
	_draw_ground()
	_draw_walls()
	for index in _buildings.size():
		_draw_building(index, index == _hovered)
	ArtDraw.vignette(self, area, 0.06)

func _draw_ground() -> void:
	for gx in GRID:
		for gy in GRID:
			var color := GROUND if (gx + gy) % 2 == 0 else GROUND_ALT
			if _is_street(gx, gy):
				color = STREET
			draw_colored_polygon(_tile_quad(float(gx), float(gy), 1.0, 1.0), color)
			if _is_street(gx, gy):
				# Sokak kenarı: karoların birbirinden ayrılması için ince
				# bir kontur. Olmayınca sokak tek bir gri leke oluyor.
				var quad := _tile_quad(float(gx), float(gy), 1.0, 1.0)
				var closed := quad.duplicate()
				closed.append(quad[0])
				draw_polyline(closed, STREET_EDGE, 1.0)

## Sur: kasabanın **arka** iki kenarında taş duvar, ön iki kenarında
## alçak bir istinat. Dördünü de tam boy çizmek ilk denemede yapılan
## hataydı: izometrik bakışta ön duvar kasabanın önüne geçiyor ve
## oyuncu binaları göremiyordu - bir sur değil, bir küvet.
func _draw_walls() -> void:
	var height := STOREY * 1.5
	var kerb := STOREY * 0.34
	var gate := int(GRID / 2)
	for step in GRID:
		_draw_wall_segment(float(step), -1.0, height, false)
		_draw_wall_segment(-1.0, float(step), height, false)
		# Ön kenarlar alçak; kapı boşluğu oyuncunun geldiği yönde.
		_draw_wall_segment(float(step), float(GRID), kerb, step == gate)
		_draw_wall_segment(float(GRID), float(step), kerb, false)

func _draw_wall_segment(gx: float, gy: float, height: float, is_gate: bool) -> void:
	if is_gate:
		return
	var top := _tile_quad(gx, gy, 1.0, 1.0)
	var lifted := PackedVector2Array()
	for point in top:
		lifted.append(point - Vector2(0.0, height))
	# Yan yüzler: sağ ve ön. İkisi farklı tonda, tek yönden ışık.
	draw_colored_polygon(PackedVector2Array([
		top[1], top[2], lifted[2], lifted[1]
	]), WALL_STONE_SIDE)
	draw_colored_polygon(PackedVector2Array([
		top[2], top[3], lifted[3], lifted[2]
	]), WALL_STONE_SIDE.darkened(0.12))
	draw_colored_polygon(lifted, WALL_STONE)

func _draw_building(index: int, hovered: bool) -> void:
	var building: Dictionary = _buildings[index]
	var gx := float(building.gx)
	var gy := float(building.gy)
	var w := float(building.w)
	var d := float(building.d)
	var kind := String(building.kind)

	var bounds := Rect2()
	match kind:
		VENUE_MARKET:
			bounds = _draw_market(gx, gy, w, d)
		VENUE_CHURCH:
			bounds = _draw_church(gx, gy, w, d)
		VENUE_TAVERN:
			bounds = _draw_tavern(gx, gy, w, d)
		VENUE_GUILD:
			bounds = _draw_guild(gx, gy, w, d)
		VENUE_YARD:
			bounds = _draw_yard(gx, gy, w, d)
		_:
			bounds = _draw_house(
				gx, gy, w, d, int(building.storeys), Color(building.roof)
			)

	_buildings[index]["bounds"] = bounds

	if hovered and bool(building.venue):
		# Seçili mekânın altını altın bir çizgiyle işaretliyoruz: fare
		# balonun kendisini kapattığında da hangi binanın seçildiği
		# belli olmalı.
		var quad := _tile_quad(gx, gy, w, d)
		var closed := quad.duplicate()
		closed.append(quad[0])
		draw_polyline(closed, ArtPalette.GOLD, 2.4)

## Gövde + beşik çatı. Bütün binaların iskeleti bu; mekânlar üstüne
## kendi ayrıntısını ekliyor.
func _draw_box(
	gx: float, gy: float, w: float, d: float, height: float,
	wall: Color, roof: Color, gabled: bool = true
) -> Rect2:
	var base := _tile_quad(gx, gy, w, d)
	var top := PackedVector2Array()
	for point in base:
		top.append(point - Vector2(0.0, height))

	draw_colored_polygon(PackedVector2Array([
		base[1], base[2], top[2], top[1]
	]), wall.darkened(0.22))
	draw_colored_polygon(PackedVector2Array([
		base[2], base[3], top[3], top[2]
	]), wall.darkened(0.38))
	draw_colored_polygon(top, wall)

	var lowest := top[0].y
	if gabled:
		# Beşik çatı: iki eğik yüz ve bir mahya. Düz bir üst yüz bina
		# değil kutu okuyor.
		var ridge_h := maxf(10.0, (TILE_H * (w + d)) * 0.22)
		var ridge_a := (top[0] + top[1]) * 0.5 - Vector2(0.0, ridge_h)
		var ridge_b := (top[3] + top[2]) * 0.5 - Vector2(0.0, ridge_h)
		draw_colored_polygon(PackedVector2Array([
			top[0], top[1], ridge_a
		]), roof.lightened(0.08))
		draw_colored_polygon(PackedVector2Array([
			top[1], top[2], ridge_b, ridge_a
		]), roof)
		draw_colored_polygon(PackedVector2Array([
			top[2], top[3], ridge_b
		]), roof.darkened(0.16))
		draw_colored_polygon(PackedVector2Array([
			top[3], top[0], ridge_a, ridge_b
		]), roof.darkened(0.28))
		draw_line(ridge_a, ridge_b, roof.darkened(0.42), 1.6)
		lowest = minf(ridge_a.y, ridge_b.y)
	else:
		draw_colored_polygon(top, roof)

	var min_x := base[3].x
	var max_x := base[1].x
	return Rect2(
		Vector2(min_x, lowest),
		Vector2(max_x - min_x, base[2].y - lowest)
	)

func _draw_house(
	gx: float, gy: float, w: float, d: float, storeys: int, roof: Color
) -> Rect2:
	var height := STOREY * float(maxi(1, storeys))
	var bounds := _draw_box(gx, gy, w, d, height, PLASTER, roof)
	# Ahşap dikmeler: yalnızca iki katlılarda, yani kasabada bir doku
	# çeşitliliği oluyor.
	if storeys > 1:
		var base := _tile_quad(gx, gy, w, d)
		for lane in [0.3, 0.7]:
			var bottom: Vector2 = base[1].lerp(base[2], lane)
			draw_line(bottom, bottom - Vector2(0.0, height), TIMBER, 1.8)
	return bounds

## Kilise: yüksek nef + çan kulesi + külah. Şehirde en yüksek silüet o
## olmalı, çünkü oyuncu onu ararken tek bakışta bulmalı.
func _draw_church(gx: float, gy: float, w: float, d: float) -> Rect2:
	var bounds := _draw_box(
		gx, gy, w, d, STOREY * 2.1, WALL_STONE.lightened(0.10), ROOF_SLATE
	)
	var tower_h := STOREY * 3.6
	var tower := _draw_box(
		gx, gy + d - 1.0, 1.0, 1.0, tower_h,
		WALL_STONE.lightened(0.14), ROOF_SLATE, false
	)
	# Külah: kulenin üstünde ince bir piramit.
	var top := _tile_quad(gx, gy + d - 1.0, 1.0, 1.0)
	var lifted := PackedVector2Array()
	for point in top:
		lifted.append(point - Vector2(0.0, tower_h))
	var apex := (lifted[0] + lifted[2]) * 0.5 - Vector2(0.0, STOREY * 1.5)
	draw_colored_polygon(PackedVector2Array([lifted[0], lifted[1], apex]), ROOF_SLATE.lightened(0.12))
	draw_colored_polygon(PackedVector2Array([lifted[1], lifted[2], apex]), ROOF_SLATE)
	draw_colored_polygon(PackedVector2Array([lifted[2], lifted[3], apex]), ROOF_SLATE.darkened(0.18))
	draw_colored_polygon(PackedVector2Array([lifted[3], lifted[0], apex]), ROOF_SLATE.darkened(0.26))
	# Çan penceresi ve tepedeki alem.
	var bell := (lifted[1] + lifted[2]) * 0.5 + Vector2(0.0, STOREY * 0.55)
	draw_arc(bell, 5.0, PI, TAU, 10, ArtPalette.INK, 2.0)
	draw_line(apex, apex - Vector2(0.0, 9.0), ArtPalette.GOLD_DIM, 2.0)
	return bounds.merge(tower).merge(Rect2(apex - Vector2(8.0, 12.0), Vector2(16.0, 20.0)))

## Taverna: ahşap karkas, iki kat, ışıklı pencereler ve sarkan tabela.
## Şehirde ışık sızdıran tek bina o - akşam bakınca hangisi olduğu
## okunuyor.
func _draw_tavern(gx: float, gy: float, w: float, d: float) -> Rect2:
	var height := STOREY * 2.0
	var bounds := _draw_box(gx, gy, w, d, height, PLASTER.darkened(0.06), ROOF_THATCH)
	var base := _tile_quad(gx, gy, w, d)
	for lane in [0.22, 0.5, 0.78]:
		var bottom: Vector2 = base[1].lerp(base[2], lane)
		draw_line(bottom, bottom - Vector2(0.0, height), TIMBER, 2.2)
	# Pencereler: iki katta üçer, hafifçe titreyen sıcak ışık.
	var flicker := 0.86 + 0.14 * sin(_time * 2.1)
	for storey in 2:
		for lane in [0.30, 0.70]:
			var spot: Vector2 = base[1].lerp(base[2], lane) - Vector2(
				0.0, STOREY * (0.55 + float(storey))
			)
			draw_rect(
				Rect2(spot - Vector2(3.5, 5.0), Vector2(7.0, 9.0)),
				Color(WINDOW_LIT, flicker), true
			)
	# Tabela: kapının yanında sarkan bir levha.
	var post: Vector2 = base[1].lerp(base[2], 0.08) - Vector2(0.0, STOREY * 1.2)
	draw_line(post, post + Vector2(12.0, 0.0), TIMBER, 2.0)
	draw_rect(Rect2(post + Vector2(7.0, 1.0), Vector2(10.0, 12.0)), ROOF_TILE, true)
	return bounds

## Lonca: geniş taş salon, merdiven ve sancak. Görkemli olması gerekiyor,
## çünkü kontratlar ve kredi orada.
func _draw_guild(gx: float, gy: float, w: float, d: float) -> Rect2:
	var height := STOREY * 2.2
	var bounds := _draw_box(gx, gy, w, d, height, WALL_STONE, ROOF_SLATE)
	var base := _tile_quad(gx, gy, w, d)
	# Sütunlar: ön yüzde dört tane.
	for lane in [0.16, 0.38, 0.62, 0.84]:
		var bottom: Vector2 = base[1].lerp(base[2], lane)
		draw_line(
			bottom, bottom - Vector2(0.0, height * 0.78),
			WALL_STONE.lightened(0.18), 3.4
		)
	# Basamaklar.
	for step in 3:
		var a: Vector2 = base[1] + Vector2(float(step) * 3.0, float(step) * 1.6)
		var b: Vector2 = base[2] + Vector2(float(step) * 3.0, float(step) * 1.6)
		draw_line(a, b, WALL_STONE.darkened(0.10), 2.6)
	# Sancak: loncanın altın rengi.
	var mast: Vector2 = base[1].lerp(base[2], 0.5) - Vector2(0.0, height)
	draw_line(mast, mast - Vector2(0.0, STOREY * 1.1), TIMBER, 2.0)
	draw_colored_polygon(PackedVector2Array([
		mast - Vector2(0.0, STOREY * 1.1),
		mast - Vector2(-14.0, STOREY * 0.95),
		mast - Vector2(0.0, STOREY * 0.72),
	]), ArtPalette.GOLD_DIM)
	return bounds.merge(Rect2(mast - Vector2(4.0, STOREY * 1.2), Vector2(20.0, STOREY * 1.3)))

## Kervan Avlusu: duvarlı bir avlu, açık kapı, içinde bir vagon ve
## demircinin bacası. Bina değil bir *alan* olması bilinçli - oyuncu
## vagonunu oraya bırakıyor.
func _draw_yard(gx: float, gy: float, w: float, d: float) -> Rect2:
	var base := _tile_quad(gx, gy, w, d)
	draw_colored_polygon(base, STREET.darkened(0.10))
	var wall_h := STOREY * 0.9
	# Avlu duvarı: arka iki kenar (ön açık, oyuncu içini görüyor).
	for edge in [[0, 1], [0, 3]]:
		var a: Vector2 = base[edge[0]]
		var b: Vector2 = base[edge[1]]
		draw_colored_polygon(PackedVector2Array([
			a, b, b - Vector2(0.0, wall_h), a - Vector2(0.0, wall_h)
		]), WALL_STONE_SIDE)

	# Demirci: bacası tüten küçük bir kulübe.
	var forge_bounds := _draw_box(
		gx, gy, 1.0, 1.0, STOREY * 1.2, PLASTER.darkened(0.18), ROOF_TILE
	)
	var chimney: Vector2 = _tile(gx + 0.7, gy + 0.3) - Vector2(0.0, STOREY * 1.9)
	draw_rect(Rect2(chimney - Vector2(3.0, 10.0), Vector2(6.0, 12.0)), WALL_STONE_SIDE, true)
	for puff in 3:
		var rise := fmod(_time * 14.0 + float(puff) * 12.0, 36.0)
		draw_circle(
			chimney + Vector2(sin(rise * 0.16) * 5.0, -10.0 - rise),
			3.0 + rise * 0.10, Color(0.72, 0.72, 0.70, 0.34 * (1.0 - rise / 36.0))
		)

	# Avludaki vagon: iki tekerlek ve bir branda. Küçük, çünkü izometrik
	# ölçekte bir vagon küçüktür.
	var cart := _tile(gx + w - 0.9, gy + d - 0.6)
	draw_rect(Rect2(cart - Vector2(13.0, 10.0), Vector2(26.0, 8.0)), TIMBER, true)
	draw_arc(cart + Vector2(-9.0, 0.0), 5.0, 0.0, TAU, 10, TIMBER.darkened(0.2), 2.0)
	draw_arc(cart + Vector2(9.0, 0.0), 5.0, 0.0, TAU, 10, TIMBER.darkened(0.2), 2.0)
	draw_arc(cart - Vector2(0.0, 10.0), 13.0, PI, TAU, 14, Color(0.80, 0.75, 0.63), 3.0)

	var bounds := Rect2(base[3], Vector2(base[1].x - base[3].x, base[2].y - base[0].y))
	return bounds.merge(forge_bounds)

## Pazar: bina değil meydan. Tenteli tezgâhlar, bir kuyu ve kalabalık
## izlenimi veren birkaç silüet.
func _draw_market(gx: float, gy: float, w: float, d: float) -> Rect2:
	var base := _tile_quad(gx, gy, w, d)
	draw_colored_polygon(base, STREET.lightened(0.06))
	var closed := base.duplicate()
	closed.append(base[0])
	draw_polyline(closed, STREET_EDGE, 1.2)

	# Kuyu: meydanın ortası.
	var well := _tile(gx + w * 0.5, gy + d * 0.5)
	ArtDraw.ellipse(self, well, Vector2(11.0, 6.0), WALL_STONE_SIDE)
	ArtDraw.ellipse(self, well - Vector2(0.0, 3.0), Vector2(8.0, 4.0), Color(0.16, 0.18, 0.20))
	draw_line(well - Vector2(9.0, 3.0), well - Vector2(9.0, 18.0), TIMBER, 2.0)
	draw_line(well + Vector2(9.0, -3.0), well + Vector2(9.0, -18.0), TIMBER, 2.0)
	draw_line(well - Vector2(9.0, 18.0), well + Vector2(9.0, -18.0), TIMBER, 2.0)

	# Tezgâhlar: çizgili tenteler. Renkleri şehir tohumundan, yani her
	# kasabanın pazarı biraz başka renk.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("stalls|%s" % _city_id)
	var spots: Array[Vector2] = [
		Vector2(0.35, 0.22), Vector2(1.45, 0.30),
		Vector2(0.28, 1.42), Vector2(1.52, 1.38),
	]
	for spot in spots:
		var at := _tile(gx + spot.x, gy + spot.y)
		var awning := Color(0.70, 0.30, 0.26).lerp(
			Color(0.28, 0.42, 0.58), rng.randf()
		)
		draw_rect(Rect2(at - Vector2(12.0, 8.0), Vector2(24.0, 8.0)), TIMBER, true)
		draw_colored_polygon(PackedVector2Array([
			at - Vector2(15.0, 8.0), at - Vector2(0.0, 19.0), at + Vector2(15.0, -8.0),
		]), awning)
		# Tezgâhta mal: iki küçük denk.
		draw_rect(Rect2(at - Vector2(8.0, 12.0), Vector2(6.0, 5.0)), ROOF_THATCH, true)
		draw_rect(Rect2(at + Vector2(2.0, -12.0), Vector2(6.0, 5.0)), ROOF_TILE.darkened(0.1), true)

	var min_x := base[3].x
	return Rect2(
		Vector2(min_x, base[0].y - 24.0),
		Vector2(base[1].x - min_x, base[2].y - base[0].y + 24.0)
	)

# --- Etkileşim ---

func _build_tooltip() -> void:
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Kendi opak arka planı: varsayılan tema saydam bırakıyor ve balon
	# kasabanın üstünde okunmuyordu (aynı hata OnboardingPanel'de de
	# yaşandı).
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.07, 0.08, 0.96)
	style.border_color = ArtPalette.GOLD_DIM
	style.set_border_width_all(1)
	style.set_content_margin_all(8)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	_tooltip.add_theme_stylebox_override("panel", style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	_tooltip.add_child(column)

	_tooltip_title = Label.new()
	_tooltip_title.modulate = ArtPalette.GOLD
	column.add_child(_tooltip_title)

	_tooltip_body = Label.new()
	_tooltip_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	_tooltip_body.custom_minimum_size = Vector2(230.0, 0.0)
	column.add_child(_tooltip_body)

	add_child(_tooltip)

func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		_update_hover(motion.position)
		return

	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var index := _building_at(click.position)
	if index < 0:
		return
	var scene := String(_buildings[index].scene)
	if not scene.is_empty():
		venue_pressed.emit(scene)

func _update_hover(at: Vector2) -> void:
	var index := _building_at(at)
	if index == _hovered:
		if index >= 0:
			_place_tooltip(at)
		return
	_hovered = index
	if index < 0:
		_tooltip.visible = false
		queue_redraw()
		return

	var building: Dictionary = _buildings[index]
	_tooltip_title.text = tr(String(building.name_key))
	_tooltip_body.text = tr(String(building.desc_key))
	_tooltip.visible = true
	_place_tooltip(at)
	queue_redraw()

## Balon imlecin yanında ama **her zaman ekranın içinde**: kenara yakın
## bir binada dışarı taşarsa oyuncu ne yapabileceğini okuyamaz, yani
## balonun varlık sebebi ortadan kalkar.
func _place_tooltip(at: Vector2) -> void:
	var wanted := at + Vector2(16.0, 14.0)
	var box := _tooltip.get_combined_minimum_size()
	_tooltip.position = Vector2(
		clampf(wanted.x, 4.0, maxf(4.0, size.x - box.x - 4.0)),
		clampf(wanted.y, 4.0, maxf(4.0, size.y - box.y - 4.0))
	)

## Öndeki bina kazanıyor: liste derinlik sırasında (arkadan öne) olduğu
## için tersten yokluyoruz. Aksi hâlde arkadaki bina öndekinin üstünden
## tıklanabiliyor - kutular üst üste biniyor, bu kaçınılmaz.
func _building_at(at: Vector2) -> int:
	for index in range(_buildings.size() - 1, -1, -1):
		var building: Dictionary = _buildings[index]
		if not bool(building.venue):
			continue
		var bounds: Rect2 = building.get("bounds", Rect2())
		if bounds.size.x > 0.0 and bounds.has_point(at):
			return index
	return -1
