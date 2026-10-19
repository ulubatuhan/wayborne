class_name MarketScale
extends Control

## Pazarın terazisi (görevler Y-G11T, 9.5; kullanıcı notları 2026-10-19):
## sol kefede sepetteki mallar, sağ kefede ödenecek altın. Mal ve altın
## çoğaldıkça kefedeki parça sayısı artar (en çok MAX_ITEMS / MAX_COINS parça,
## fazlası "+N"), yeni parça yukarıdan düşer ve oturur, kollar altın ile mal
## değerinin farkına göre yaylanarak eğilir: ağır olan taraf iner. Her eğri
## saf bir fonksiyon (Motion Rules): test aynı sayıyı okur. Reduce Motion
## açıkken her şey anında yerine oturur.

const MAX_ITEMS: int = 12
const MAX_COINS: int = 28
## Kaç altın bir sikke çizer; 186 altın ~19 sikke.
const COIN_UNIT: int = 10
## Kolun en çok eğimi (radyan) ve farkın kaç katında doyduğu.
const MAX_TILT: float = 0.22
const TILT_GAIN: float = 4.0
const SPRING_STIFFNESS: float = 90.0
const SPRING_DAMPING: float = 12.0
const DROP_SECONDS: float = 0.45
const DROP_HEIGHT: float = 90.0
const ITEM_SIZE: float = 40.0

const BRASS: Color = Color(0.62, 0.46, 0.22)
const BRASS_DARK: Color = Color(0.30, 0.21, 0.10)
const INK: Color = Color(0.05, 0.04, 0.04)
const COIN: Color = Color(0.93, 0.74, 0.30)

## [{texture: Texture2D, quantity: int}] ve altın; set_basket doldurur.
var _entries: Array[Dictionary] = []
var _gold: int = 0
var _goods_value: int = 0
var _tilt: float = 0.0
var _tilt_velocity: float = 0.0
var _target_tilt: float = 0.0
## Sol kefedeki parçaların doğuş zamanı (saniye, kendi saatimiz): düşme animasyonu.
var _item_born: Array[float] = []
var _coin_born: Array[float] = []
var _clock: float = 0.0

func _init() -> void:
	custom_minimum_size = Vector2(520, 500)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# --- saf fonksiyonlar (testin okuduğu sayılar) ---

## -1 (altın ağır) .. +1 (mal ağır): fark, büyüğe oranla, TILT_GAIN ile büyütülüp kenetlenir.
static func tilt_for(goods_value: int, gold: int) -> float:
	var top := maxi(1, maxi(goods_value, gold))
	return clampf(float(goods_value - gold) / float(top) * TILT_GAIN, -1.0, 1.0)

static func coin_count(gold: int) -> int:
	if gold <= 0:
		return 0
	return mini(MAX_COINS, maxi(1, int(ceil(float(gold) / float(COIN_UNIT)))))

## Sepetin mal çeşitlerine MAX_ITEMS parça dağıtır: her çeşit en az bir, kalan
## adetle orantılı. Dönen dizi sepetle aynı sırada, parça sayısı.
static func item_shares(quantities: Array[int]) -> Array[int]:
	var shares: Array[int] = []
	var total := 0
	for q in quantities:
		total += maxi(0, q)
	if total <= 0:
		for _q in quantities:
			shares.append(0)
		return shares
	var budget := mini(MAX_ITEMS, total)
	var given := 0
	for q in quantities:
		var s := 0 if q <= 0 else maxi(1, int(round(float(q) / float(total) * float(budget))))
		shares.append(s)
		given += s
	# Yuvarlama bütçeyi aştıysa en büyük payı kıs; azsa en büyüğe ekle.
	while given > budget:
		var big := shares.find(shares.max())
		shares[big] -= 1
		given -= 1
	while given < budget and not shares.is_empty():
		var big := shares.find(shares.max())
		shares[big] += 1
		given += 1
	return shares

## Kefenin içinde piramit dizilişi: alt sıra geniş, üst sıralar daralır.
## Konumlar kefe merkezine göre, y yukarı doğru eksi.
static func pyramid(count: int, spacing: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var row := 0
	var left := count
	var width := maxi(1, int(ceil((sqrt(8.0 * float(maxi(1, count)) + 1.0) - 1.0) / 2.0)))
	while left > 0:
		var in_row := mini(left, maxi(1, width - row))
		for k in in_row:
			out.append(Vector2((float(k) - float(in_row - 1) * 0.5) * spacing, -float(row) * spacing * 0.82))
		left -= in_row
		row += 1
	return out

## Yaylı eğim: bir adım. Yeni konum ve hız; hedefte durgun kalır.
static func spring_step(position: float, velocity: float, target: float, dt: float) -> Vector2:
	var accel := (target - position) * SPRING_STIFFNESS - velocity * SPRING_DAMPING
	var v := velocity + accel * dt
	return Vector2(position + v * dt, v)

## Düşen parçanın dikey kayması: yukarıdan iner, bir kez sekip yerine oturur.
static func drop_offset(age: float) -> float:
	if age <= 0.0:
		return -DROP_HEIGHT
	if age >= DROP_SECONDS:
		return 0.0
	var u := age / DROP_SECONDS
	if u < 0.7:
		var f := u / 0.7
		return -DROP_HEIGHT * (1.0 - f * f)
	return -sin((u - 0.7) / 0.3 * PI) * 6.0

# --- durum ---

## Sepet: [{texture, quantity}], sepetin altın karşılığı (ödenecek) ve malın
## bilinen değeri (en iyi satış fiyatıyla); fark eğimi verir.
func set_basket(entries: Array[Dictionary], gold: int, goods_value: int) -> void:
	_entries = entries
	var quantities: Array[int] = []
	for entry in entries:
		quantities.append(int(entry.get("quantity", 0)))
	var shares := item_shares(quantities)
	var wanted_items := 0
	for s in shares:
		wanted_items += s
	_gold = gold
	_goods_value = goods_value
	_target_tilt = tilt_for(goods_value, gold)
	_grow(_item_born, wanted_items)
	_grow(_coin_born, coin_count(gold))
	if _reduced():
		_tilt = _target_tilt * MAX_TILT
		_tilt_velocity = 0.0
	set_process(true)
	queue_redraw()

func _grow(born: Array[float], wanted: int) -> void:
	while born.size() < wanted:
		born.append(-1000.0 if _reduced() else _clock)
	while born.size() > wanted:
		born.pop_back()

func _reduced() -> bool:
	return is_inside_tree() and NodeUtil.reduce_motion(self)

func _process(delta: float) -> void:
	_clock += delta
	var step := spring_step(_tilt, _tilt_velocity, _target_tilt * MAX_TILT, delta)
	_tilt = step.x
	_tilt_velocity = step.y
	var settled := absf(_tilt - _target_tilt * MAX_TILT) < 0.001 and absf(_tilt_velocity) < 0.002
	var dropping := false
	for born in _item_born + _coin_born:
		if _clock - born < DROP_SECONDS:
			dropping = true
			break
	queue_redraw()
	if settled and not dropping:
		set_process(false)

## Test için: yayı hedefe oturtur.
func settle_now() -> void:
	_tilt = _target_tilt * MAX_TILT
	_tilt_velocity = 0.0
	for i in _item_born.size():
		_item_born[i] = -1000.0
	for i in _coin_born.size():
		_coin_born[i] = -1000.0
	queue_redraw()

func get_tilt() -> float:
	return _tilt

# --- çizim ---

## Render edilmiş parçalar (tools/ui_scenes/market_scale_scene.py): sütun,
## mil çevresinde dönen kol, kolun ucunda dik asılı kefe, sikke. Yoksa
## prosedürel çizime düşer (sanat parça parça gelebilir).
var _art: Dictionary = {}

func _part(name: String) -> Texture2D:
	if not _art.has(name):
		_art[name] = TextureLoader.load_any(MarketScaleArt.DIR + name + ".png")
	return _art[name]

func _draw() -> void:
	var column := _part("column")
	var beam := _part("beam")
	var pan := _part("pan")
	if column == null or beam == null or pan == null:
		_draw_procedural()
		return
	# Bütün terazi alanın içine sığsın: kol + iki kefe genişliği, iğneden ayağa yükseklik.
	var span_w := float(beam.get_width()) + float(pan.get_width())
	var span_h := (MarketScaleArt.COLUMN_FOOT.y - MarketScaleArt.COLUMN_PIVOT.y) + MarketScaleArt.BEAM_PIVOT.y
	var k := minf(size.x / span_w, size.y / span_h) * 0.98
	var pivot := Vector2(size.x * 0.5, MarketScaleArt.BEAM_PIVOT.y * k + (size.y - span_h * k) * 0.5)
	draw_texture_rect(column, Rect2(pivot - MarketScaleArt.COLUMN_PIVOT * k, Vector2(column.get_size()) * k), false)
	# Kol: pozitif eğim = mal ağır = sol uç iner.
	var angle := -_tilt
	var hook := MarketScaleArt.BEAM_LEFT_HOOK - MarketScaleArt.BEAM_PIVOT
	var left_hook := pivot + (hook * k).rotated(angle)
	var right_hook := pivot + (Vector2(-hook.x, hook.y) * k).rotated(angle)
	_draw_sprite_pan(pan, left_hook, k, true)
	_draw_sprite_pan(pan, right_hook, k, false)
	draw_set_transform(pivot, angle, Vector2(k, k))
	draw_texture(beam, -MarketScaleArt.BEAM_PIVOT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Kefe askısından dik asılır; mal ya da altın kefenin tabanına oturur, kefenin
## ön yüzü malın altını örter (önce mal, sonra kefe).
func _draw_sprite_pan(pan: Texture2D, hook: Vector2, k: float, goods: bool) -> void:
	var origin := hook - MarketScaleArt.PAN_HOOK * k
	var floor_at := origin + MarketScaleArt.PAN_FLOOR * k
	var radius := MarketScaleArt.PAN_RADIUS * k
	if goods:
		_draw_goods_at(floor_at, radius, radius * 0.5)
	else:
		_draw_coins_at(floor_at, radius, k)
	draw_texture_rect(pan, Rect2(origin, Vector2(pan.get_size()) * k), false)

func _draw_goods_at(floor_at: Vector2, radius: float, item: float) -> void:
	var quantities: Array[int] = []
	for entry in _entries:
		quantities.append(int(entry.get("quantity", 0)))
	var shares := item_shares(quantities)
	var total_shown := 0
	for s in shares:
		total_shown += s
	var spots := pyramid(total_shown, item * 0.92)
	var index := 0
	for e in _entries.size():
		var tex: Texture2D = _entries[e].get("texture")
		for _k in shares[e]:
			if index >= spots.size() or tex == null:
				break
			var age := _clock - (_item_born[index] if index < _item_born.size() else -1000.0)
			var at := floor_at + spots[index] + Vector2(0.0, -item * 0.42 + drop_offset(age) * item / ITEM_SIZE)
			draw_texture_rect(tex, Rect2(at - Vector2(item, item) * 0.5, Vector2(item, item)), false)
			index += 1
	var total := 0
	for q in quantities:
		total += q
	if total > total_shown:
		draw_string(ThemeDB.fallback_font, floor_at + Vector2(radius * 0.75, -radius * 1.1), "+%d" % (total - total_shown),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.93, 0.85, 0.7))

func _draw_coins_at(floor_at: Vector2, radius: float, _k: float) -> void:
	var coin := _part("coin")
	var count := coin_count(_gold)
	var w := radius * 0.36
	var spots := pyramid(count, w * 0.78)
	for i in count:
		var age := _clock - (_coin_born[i] if i < _coin_born.size() else -1000.0)
		var at := floor_at + spots[i] * Vector2(1.0, 0.42) + Vector2(0.0, -w * 0.15 + drop_offset(age) * w / 18.0)
		if coin != null:
			draw_texture_rect(coin, Rect2(at - Vector2(w, w) * 0.5, Vector2(w, w)), false)
		else:
			draw_set_transform(at, 0.0, Vector2(1.0, 0.42))
			draw_circle(Vector2.ZERO, w * 0.5, COIN)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _gold > 0:
		draw_string(ThemeDB.fallback_font, floor_at + Vector2(-radius * 1.0, -radius * 1.15), "%d" % _gold,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, COIN)

func _draw_procedural() -> void:
	var w := size.x
	var pivot := Vector2(w * 0.5, size.y * 0.16)
	var arm := w * 0.40
	var hang := size.y * 0.34
	# Direk ve ayak
	draw_rect(Rect2(pivot.x - 5, pivot.y, 10, size.y * 0.74), BRASS_DARK)
	draw_rect(Rect2(pivot.x - 5, pivot.y, 10, size.y * 0.74), INK, false, 2.0)
	draw_polygon(PackedVector2Array([Vector2(pivot.x - 70, size.y - 6), Vector2(pivot.x + 70, size.y - 6),
		Vector2(pivot.x + 34, size.y * 0.90), Vector2(pivot.x - 34, size.y * 0.90)]), PackedColorArray([BRASS_DARK]))
	# Kol: eğimle döner (pozitif eğim = mal ağır = sol uç iner)
	var dir := Vector2(cos(_tilt), -sin(_tilt))
	var left_end := pivot - dir * arm
	var right_end := pivot + dir * arm
	draw_line(left_end, right_end, BRASS, 7.0)
	draw_line(left_end, right_end, INK, 2.0)
	draw_circle(pivot, 12.0, BRASS)
	draw_arc(pivot, 12.0, 0.0, TAU, 20, INK, 2.0)
	_draw_pan(left_end, hang, true)
	_draw_pan(right_end, hang, false)

func _draw_pan(anchor: Vector2, hang: float, goods: bool) -> void:
	var radius := size.x * 0.17
	var centre := anchor + Vector2(0.0, hang)
	for a in [-0.8, 0.0, 0.8]:
		var rim := centre + Vector2(sin(a) * radius * 0.92, -radius * 0.18)
		draw_line(anchor, rim, Color(BRASS, 0.9), 1.5)
	draw_circle(anchor, 5.0, BRASS)
	# Kefenin içi: parçalar kefenin ÖN kenarının arkasında kalsın diye önce parçalar, sonra ön kenar.
	if goods:
		_draw_goods(centre, radius)
	else:
		_draw_coins(centre, radius)
	var bowl := PackedVector2Array()
	for i in range(0, 21):
		var t := PI * float(i) / 20.0
		bowl.append(centre + Vector2(cos(t) * radius, sin(t) * radius * 0.42))
	draw_colored_polygon(bowl, BRASS)
	draw_polyline(bowl, INK, 2.5)
	draw_line(centre + Vector2(-radius, 0), centre + Vector2(radius, 0), INK, 2.0)

func _draw_goods(centre: Vector2, radius: float) -> void:
	var quantities: Array[int] = []
	for entry in _entries:
		quantities.append(int(entry.get("quantity", 0)))
	var shares := item_shares(quantities)
	var total_shown := 0
	for s in shares:
		total_shown += s
	var spots := pyramid(total_shown, ITEM_SIZE * 0.92)
	var index := 0
	for e in _entries.size():
		var tex: Texture2D = _entries[e].get("texture")
		for _k in shares[e]:
			if index >= spots.size() or tex == null:
				break
			var age := _clock - (_item_born[index] if index < _item_born.size() else -1000.0)
			var at := centre + spots[index] + Vector2(0.0, -ITEM_SIZE * 0.45 + drop_offset(age))
			draw_texture_rect(tex, Rect2(at - Vector2(ITEM_SIZE, ITEM_SIZE) * 0.5, Vector2(ITEM_SIZE, ITEM_SIZE)), false)
			index += 1
	var total := 0
	for q in quantities:
		total += q
	if total > total_shown:
		draw_string(ThemeDB.fallback_font, centre + Vector2(radius * 0.55, -radius * 0.55), "+%d" % (total - total_shown),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.93, 0.85, 0.7))

func _draw_coins(centre: Vector2, radius: float) -> void:
	var count := coin_count(_gold)
	var spots := pyramid(count, 21.0)
	for i in count:
		var age := _clock - (_coin_born[i] if i < _coin_born.size() else -1000.0)
		var at := centre + spots[i] * Vector2(1.0, 0.6) + Vector2(0.0, -9.0 + drop_offset(age))
		draw_set_transform(at, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, 13.0, COIN)
		draw_arc(Vector2.ZERO, 13.0, 0.0, TAU, 18, INK, 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _gold > 0:
		draw_string(ThemeDB.fallback_font, centre + Vector2(-radius * 0.9, -radius * 0.9), "%d" % _gold,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, COIN)
