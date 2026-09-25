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

## Bir vagonu **tek öküz** çeker. Bir süre çift öküzdü (bkz. Faz 10'un
## ART-C hattı) - tek hayvanın boyunduruk değil at koşumu gibi okunduğu
## gerekçesiyle - ama açıkça istenerek teke geri döndü (bkz. CLAUDE.md
## Art Rules). Eski çiftin geriye itme işaretleri (`PAIR_LEAD`/`RISE`/
## `DEPTH`/`SHADE`) bu yüzden kalkı: tek hayvan artık kendi tam boyutunda
## ve tam tonunda, koşumun tam ortasında duruyor.

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

## Kamp ateşi vagon başına bir tane. Tek ateş kolonun önündeydi (boş
## alan, hiçbir silüetin arkasına düşmüyordu); vagon başına çoğaltınca o
## kaçış yolu yok - her ateş kendi vagonunun **arkasına** (kuyruk yönüne)
## kayıyor, çünkü önü zaten o vagonun öküzü ve tayfasıyla dolu. Vagonlar
## arası boşluk (`GAP_WAGONS`) bunu rahatça karşılıyor; ölçüldü, en
## yakın komşu figüre değmiyor.
const CAMPFIRE_TRAIL_RATIO: float = 0.62
## Zemin çizgisinden biraz izleyiciye doğru (aşağı) - tam tekerleğin
## dibine oturmasın diye (bkz. Art Rules'un "yakın olan aşağıda" kuralı).
const CAMPFIRE_NEAR_OFFSET: float = 9.0
const FIRE_FLICKER_SPEED: float = 9.0

## İnsanlar ateşe yürüyor, hayvanlar ve lider yerinde kalıyor: öküz
## koşumdan çözülmüyor, lider nöbette kabul ediliyor. "İnsanlar" tayfanın
## ikisi de - yürüyen ve süren (bkz. `_driver_figures`'ın notu), yoksa
## tek kişilik bir ateş "kervandakiler toplandı" demiyordu. Süre
## `CAMP_HOURS` (8 oyun saati) yanında görünmeyecek kadar kısa olmamalı
## ama oyuncunun sabrını da sınamamalı.
const CAMP_GATHER_SECONDS: float = 1.3
## Toplanma/dönüş sırasında bacakların oynaması için figüre verilen
## görsel adım - `_speed * STEP_RATE`'in büyüklüğüyle aynı mertebede,
## kamp sırasında gerçek `_speed` sıfır olduğu için ayrıca besleniyor.
const CAMP_WALK_STEP: float = 1.8

## Aynı ateşe birden fazla kişi geliyor (sürücü + yürüyen tayfa + sırayla
## dağılan parti). Hedefleri tek noktaya kenetlemek tek bir figür gibi
## görünmelerine yol açıyordu - "kervandakiler toplandı" hissi tam da bu
## yüzden kayboluyordu. Her koltuk ateşin etrafında küçük bir (x, y)
## kayma alıyor - yalnızca sağa/sola değil, ateşin önüne/arkasına da -
## böylece bir çember okunuyor, tek bir yatay sıra değil. `x` bileşenleri
## kasıtlı olarak birbirinden ayrı tutuluyor (bkz. `_fire_tolerance` ve
## `test_camp_gathering.gd`'nin üst üste binme testi): ayrım ekseni yine
## `x`, `y` yalnızca kümeyi ateşin tamamen etrafına yayıyor.
const CAMPFIRE_SEAT_SPACING: float = 15.0
const CAMPFIRE_SEATS: Array[Vector2] = [
	Vector2(-0.6, 0.5), Vector2(0.7, -0.6), Vector2(-1.5, -0.3),
	Vector2(1.6, 0.4), Vector2(0.0, -1.1), Vector2(-2.3, 0.2),
]

var _anchor_x: float = 0.0
var _ground_y: float = 0.0
var _light: Color = Color.WHITE
var _speed: float = 0.0

## İkincil hareket (bkz. WalkFigure'ın OX_NOD_RATIO'su): vagonun brandası
## tekerleğin ritmiyle salınıyor, yağmurda ve fırtınada insanlar rüzgâra
## eğiliyor. Rüzgâr yalnızca insanları eğiyor - öküz ve vagon eğilmez,
## eğilen bir vagon devrilen bir vagondur.
const CANOPY_SWAY_RATIO: float = 0.03
const WIND_LEAN: Dictionary = {
	RouteWeather.RAIN: 0.035,
	RouteWeather.STORM: 0.07,
}
## Bora: eğilme sabit değil, figür başına kaydırılmış bir dalga - herkes
## aynı anda aynı açıya eğilirse rüzgâr değil kalıp okunur.
const GUST_AMPLITUDE: float = 0.35
const GUST_SPEED: float = 1.7
var _wind_lean: float = 0.0
var _anim_time: float = 0.0
## Vagonların yürüyüş genliği - figürlerin `_motion`'ının aynısı, aynı
## sönümle: kervan durunca branda bir karede donmasın.
var _wagon_motion: float = 0.0
## Liderin kolondaki yeri: 0 en önde, negatif geriye doğru.
var _leader_offset: float = 0.0
var _wagon_count: int = 1
var _wheel_angle: float = 0.0
var _scale: float = 1.0

## Yerleşimin hesapladığı vagon merkezleri. Çizim bunları okuyor,
## kendi aritmetiğini yapmıyor: iki ayrı formül tam olarak öküzün
## vagonun içine girmesine yol açan şeydi.
var _wagon_centres: Array[float] = []

## Kamp durumu. `_gather_progress` 0 = herkes kendi kolon yerinde, 1 =
## herkes kendi ateşinde; kamp başlayınca 0→1'e, bitince 1→0'a akıyor.
## Ayrı bir yön değişkeni yok - `_camping`'in kendisi yön: doğru
## yöne akmayı `_process` karar veriyor.
var _camping: bool = false
var _gather_progress: float = 0.0
var _camp_time: float = 0.0
## Toplanan her figürün kolondaki "ev" konumu ve ateşteki hedefi - ikisi
## arasında `_gather_progress` kadar ilerliyor. `_layout()` her çalıştığında
## tazeleniyor (bkz. `_layout`), o yüzden ekran yeniden boyutlanırsa bile
## bayat bir eve dönmüyor.
var _gather_homes: Dictionary = {}
var _gather_targets: Dictionary = {}
## Her toplanan figürün gittiği ateşin sırası - `_layout()` yeniden
## çalışırsa (bkz. `_place`'in kamp yönlendirmesi) hedefi aynı ateşe göre
## tazeleyebilmek için.
var _gather_fire_index: Dictionary = {}
## Aynı ateşe atanan figürler tek noktada üst üste binmesin diye her
## figürün oturduğu "koltuk" sırası - bkz. `_seat_offset`.
var _gather_seat_index: Dictionary = {}
var _gathering_figures: Array[WalkFigure] = []

var _leader: WalkFigure
var _leader_mounted: bool = false
var _party_figures: Array[WalkFigure] = []
var _crew_figures: Array[WalkFigure] = []
## Arabacılar - normalde `ArtDraw.wagon()`'un çizdiği sabit silüet, kamp
## sırasında gerçek birer figüre dönüşüyor (bkz. `configure`'daki not).
var _driver_figures: Array[WalkFigure] = []
## Vagon başına tek öküz - koşumun ölçüsünü bunlar belirliyor.
var _oxen: Array[WalkFigure] = []

## Altında bir şey çizmenin anlamı olmadığı boy. Bunun altında vagonun
## bütün ölçüleri piksel altına düşüyor ve çokgenlerin köşeleri aynı
## float'a çöküyor - Godot "Invalid polygon data, triangulation failed"
## basıp çizimi atlıyor, oyunu durdurmuyor. Yani ekran görüntüsü
## alınmadan hiç görülmeyecek bir hata; yapısal testler de görmüyor.
const MIN_DRAW_HEIGHT: float = 60.0

## Kolon çapanın arkasına sığmıyorsa **küçülüyor**, taşmıyor. Zemin
## ölçüldü: 1920×320'lik şeritte iki vagonluk bir kervanın ikinci vagonu
## x = -264'te, yani ekranın dışındaydı; oyuncu kaç vagon alırsa alsın
## yolda hep tek vagon görüyordu. Önce çapa sağa kayıyor (bedava), sonra
## gerekirse kolon küçülüyor - ama bir yere kadar: altı vagonluk bir
## kervanı tamamen sığdırmak figürleri karınca boyuna indiriyor. Zeminde
## kalan taşma dürüst olan: uzun bir kervan görüş alanından uzundur.
const MIN_COLUMN_SCALE: float = 0.58
const COLUMN_EDGE_MARGIN: float = 20.0

## Kolonun çapadan geriye doğru istediği yer (ölçeklenmemiş). Şerit
## çapayı buna göre kaydırıyor.
signal column_length_changed(trailing_px: float)

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
	_driver_figures.clear()
	_oxen.clear()
	_leader = null

	# Kamp durumu eski figürlere işaret ediyor olabilir - `queue_free()`
	# bu kareyi bitirene kadar onları serbest bırakmıyor, ama kamp/kayıt
	# durumu temizlenmezse `_process()` bir sonraki karede "previously
	# freed" bir düğüme erişmeye çalışır (bu tam olarak sefer başına bir
	# kez çağrılan bir fonksiyon olduğu için nadiren yakalanan bir hata -
	# yol ekranında hep tek bir `configure()` çağrısı vardır, çoklu şehir/
	# vagon karesi basan araçlarda ise `RoadCaravan` yeniden kullanılıyor).
	_camping = false
	_gather_progress = 0.0
	_gathering_figures.clear()
	_gather_homes.clear()
	_gather_targets.clear()
	_gather_fire_index.clear()
	_gather_seat_index.clear()

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

	# Arabacı normalde `ArtDraw.wagon()`'un kendi çizdiği sabit bir silüet -
	# bkz. oradaki `draw_driver`. Kamp kurulunca o koltuğu gerçek bir figür
	# devralıyor (bkz. `_begin_gathering`), yoksa "kervandakiler ateşe
	# gelsin" sözü tek kişiyle (yürüyen tayfa) sınırlı kalırdı; sürücü de
	# aynı vagonun adamı. Görünmez başlıyor - kamp kurulana kadar sahnede
	# hiçbir işi yok, sabit silüet onun yerini tutuyor.
	for index in maxi(0, walking_crew):
		var driver := _make_figure(
			WalkFigure.KIND_PERSON, "bandit", 0.92 + float((index + 1) % 3) * 0.04,
			CharacterData.get_skin_tone_color(index + 2), false
		)
		driver.visible = false
		_driver_figures.append(driver)

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

func set_weather(weather: String) -> void:
	_wind_lean = float(WIND_LEAN.get(weather, 0.0))

## Bir figürün o anki rüzgâr eğilmesi. Saf fonksiyon (test sahnesiz okur).
static func wind_lean_at(base: float, time: float, index: int) -> float:
	if is_zero_approx(base):
		return 0.0
	return base * (1.0 + GUST_AMPLITUDE * sin(time * GUST_SPEED + float(index) * 1.3))

## Brandanın salınımı (piksel). Genlik sıfırsa tam sıfır - duran kervanın
## brandası kıpırdamaz.
static func canopy_sway_at(wheel_angle: float, index: int, wagon_h: float, motion: float) -> float:
	return sin(wheel_angle * 2.0 + float(index) * 0.9) * wagon_h * CANOPY_SWAY_RATIO * motion

## Kervan kendi temposuyla yürüyor; oyuncunun doğrudan yürüttüğü tek beden
## lider, kolon boyunca. Sınır kolonun uzunluğu: lider kervanı bırakıp
## gidemiyor.
func set_leader_offset(offset: float) -> void:
	_leader_offset = clampf(offset, -_column_length(), 0.0)
	_layout()

func get_leader_offset() -> float:
	return _leader_offset

func get_column_length() -> float:
	return _column_length()

## Ekrandaki bir x (bu düğümün yerel uzayında) liderin kolondaki hangi
## yerine düşüyor - dokunarak/tıklayarak yürümenin hedefi. Aynı sınır
## `set_leader_offset`'inki: kolonun dışına tıklamak ucuna yürütür.
func leader_offset_for_x(x: float) -> float:
	return clampf(x - (_anchor_x + _lead_at(_scale)), -_column_length(), 0.0)

## Kamp kurulunca/kalkınca çağrılır. Ateşler burada değil `_draw()`'da
## çiziliyor (bkz. `_draw_campfires`); bu yalnızca kimin nereye
## yürüyeceğini belirliyor. Yön ayrı bir bayrak değil - `_gather_progress`
## `_camping`'e doğru akıyor, `_advance_gather` kararı orada veriyor.
func set_camping(camping: bool) -> void:
	if _camping == camping:
		return
	_camping = camping
	if camping:
		_begin_gathering()

## Ateşe kimin gideceği: tayfanın **ikisi de** - sürücü ve yürüyen -
## kendi vagonunun ateşine gidiyor (bkz. `_driver_figures`'ın notu, ikisi
## de vagon `i`'nin adamı). Parti üyeleri ateşler arasında sırayla
## dağıtılıyor - hepsi aynı ateşte toplanmak kalabalık, hiçbiri gitmemek
## de eksik dururdu. Lider nöbette kabul ediliyor, öküzler koşumdan
## çözülmüyor - ikisi de katılmıyor.
func _begin_gathering() -> void:
	_gathering_figures.clear()
	_gather_homes.clear()
	_gather_targets.clear()
	_gather_fire_index.clear()
	_gather_seat_index.clear()
	if _wagon_centres.is_empty():
		return
	var fire_count := _wagon_centres.size()
	# Ateş başına kaç koltuk dolduğu - üst üste binmesinler diye (bkz.
	# CAMPFIRE_SEATS'in notu).
	var seats_taken: Dictionary = {}

	for index in _driver_figures.size():
		if index >= fire_count:
			break
		_assign_driver_gather(_driver_figures[index], index, seats_taken)
	for index in _crew_figures.size():
		if index >= fire_count:
			break
		_assign_gather(_crew_figures[index], index, seats_taken)
	for index in _party_figures.size():
		_assign_gather(_party_figures[index], index % fire_count, seats_taken)

func _take_seat(fire_index: int, seats_taken: Dictionary) -> int:
	var seat := int(seats_taken.get(fire_index, 0))
	seats_taken[fire_index] = seat + 1
	return seat

func _assign_gather(figure: WalkFigure, fire_index: int, seats_taken: Dictionary) -> void:
	if figure == null:
		return
	var seat := _take_seat(fire_index, seats_taken)
	_gathering_figures.append(figure)
	_gather_fire_index[figure] = fire_index
	_gather_seat_index[figure] = seat
	_gather_homes[figure] = figure.position
	_gather_targets[figure] = _campfire_target(figure, fire_index, seat)

## Sürücü normalde koltuğu hiç terk etmiyor (bkz. ArtDraw.wagon()'un
## sabit silüeti) - kamp onu ilk kez sahneye çıkarıyor, o yüzden "ev"i
## mevcut bir konum değil, oturduğu koltuğun kendisi (bkz.
## `_driver_bench_position`). Aynı çağrı figürü görünür de yapıyor -
## `configure()` onu gizli kurmuştu, sahneye ilk kez burada giriyor.
func _assign_driver_gather(figure: WalkFigure, wagon_index: int, seats_taken: Dictionary) -> void:
	if figure == null:
		return
	figure.visible = true
	var bench := _driver_bench_position(wagon_index)
	# `bench` koltuğun kendisi (gövde hizası), figürün *ayağının bastığı*
	# nokta değil - `_place()`'in `ground_y - height` deseninin aynısı,
	# yoksa figür koltuğun tepesinden başlayıp gerçek zeminin altına
	# gömülür.
	var home := Vector2(bench.x - figure.size.x * 0.5, bench.y - figure.size.y)
	figure.position = home
	var seat := _take_seat(wagon_index, seats_taken)
	_gathering_figures.append(figure)
	_gather_fire_index[figure] = wagon_index
	_gather_seat_index[figure] = seat
	_gather_homes[figure] = home
	_gather_targets[figure] = _campfire_target(figure, wagon_index, seat)

## Figürün ateşteki hedefi. Taban çizgisi her zaman **gerçek zemin**
## (`_ground_y - height`), figürün o an durduğu yer değil - tayfa ve
## parti için ikisi zaten aynı (`_place()` onları oraya koyuyor), ama
## arabacı koltuktan (yükseltilmiş bir taban) geliyor: hedef koltuk
## yüksekliğini korusaydı arabacı ateşin yanında havada asılı kalırdı.
## Aynı hedef hem gidişte hem dönüşte kullanıldığı için (bkz.
## `_advance_gather`'ın home/dest çifti) düzeltme iki yönü de kapsıyor -
## arabacı ateşe inerken alçalıyor, dönerken yeniden koltuğa çıkıyor.
## `seat` aynı ateşe gelen ikinci/üçüncü kişiyi ateşin etrafında bir
## çembere yayıyor (bkz. CAMPFIRE_SEATS'in notu) - yoksa hepsi aynı
## noktaya biner. Taban çizgisi yine gerçek zemin: `y` bileşeni oradan bir
## sapma, ateşin kendi çizim noktasından değil - yoksa ateş her koltuk
## için ayrı bir zemin tanımlamış olurdu.
func _campfire_target(figure: WalkFigure, fire_index: int, seat: int) -> Vector2:
	var fire := _campfire_position(fire_index)
	var seat_ratio: Vector2 = CAMPFIRE_SEATS[seat % CAMPFIRE_SEATS.size()]
	var offset := seat_ratio * CAMPFIRE_SEAT_SPACING * _scale
	return Vector2(
		fire.x + offset.x - figure.size.x * 0.5, _ground_y + offset.y - figure.size.y
	)

## Bir vagonun ateşinin durduğu yer. Ateş vagonun **kuyruk yönüne**
## kayıyor (bkz. CAMPFIRE_TRAIL_RATIO'nun notu) - önü zaten öküz ve
## tayfayla dolu.
func _campfire_position(index: int) -> Vector2:
	if index < 0 or index >= _wagon_centres.size():
		return Vector2(_anchor_x, _ground_y)
	var wagon_w := maxf(size.y, 1.0) * _scale * WAGON_WIDTH_RATIO
	return Vector2(
		_wagon_centres[index] - wagon_w * CAMPFIRE_TRAIL_RATIO,
		_ground_y + CAMPFIRE_NEAR_OFFSET * _scale
	)

## Arabacının normalde oturduğu koltuk - `ArtDraw.wagon_driver_seat()`'in
## aynısı, aynı yerde iki kez hesaplanmasın diye oradan okunuyor. Kamp
## kurulunca gerçek figür tam bu noktadan "kalkıp" ateşe yürüyor.
func _driver_bench_position(index: int) -> Vector2:
	if index < 0 or index >= _wagon_centres.size():
		return Vector2(_anchor_x, _ground_y)
	var height := maxf(size.y, 1.0) * _scale
	var wagon_w := height * WAGON_WIDTH_RATIO
	var wagon_h := height * WAGON_HEIGHT_RATIO
	return ArtDraw.wagon_driver_seat(Vector2(_wagon_centres[index], _ground_y), wagon_w, wagon_h)

## `_layout()`'un sonunda çağrılıyor (bkz. oradaki not): kamp sırasında
## bir yeniden boyutlanma vagon merkezlerini kaydırırsa, dönüş yürüyüşü
## artık doğru olmayan eski bir noktaya değil güncel ateşe gider.
func _refresh_gather_targets() -> void:
	if _gathering_figures.is_empty():
		return
	for figure in _gathering_figures:
		if _gather_fire_index.has(figure):
			_gather_targets[figure] = _campfire_target(
				figure, int(_gather_fire_index[figure]), int(_gather_seat_index.get(figure, 0))
			)

## Kolonun toplam boyu - lider bu kadar geriye gidebiliyor. Yerleşimle
## aynı boşluklardan hesaplanıyor: ayrı bir tahmin tutmak, liderin
## kolonun ucundan taşmasına ya da kuyruğa hiç ulaşamamasına yol
## açardı.
func _column_length() -> float:
	return _lead_at(_scale) + _walk_column(_scale, false)

func _lead_at(scale: float) -> float:
	return scale * (LEAD_MOUNTED if _leader_mounted else LEAD_WALKING)

## Şeridin çapayı yerleştirmek için okuduğu değer - bilerek
## **ölçeklenmemiş**: kervan çapaya göre küçülüyor, çapa da kervana göre
## kaysaydı ikisi birbirini kovalardı.
func get_trailing_length() -> float:
	return _walk_column(1.0, false)

## Kolonun çapaya sığmak için küçüldüğü oran (1.0 = küçülme yok).
func get_column_scale() -> float:
	return _scale

## Kervanın **en önündeki** noktanın çapaya uzaklığı (piksel). Lider
## çapanın üstünde değil, `_lead_at()` kadar önünde duruyor - yani çapa
## kolonun ortasına yakın bir yer, burnu değil.
##
## Yolda yaklaşan bir olay bunu okuyor: tetik çapaya bağlıyken görevli
## önce liderin *yanından geçiyor*, kart ancak arkadaki vagona
## geldiğinde açılıyordu. Karşılaşma, karşılaşılan şey kervanın burnuna
## değdiğinde başlamalı.
func get_front_offset() -> float:
	if _leader == null:
		return 0.0
	return _lead_at(_scale) + _leader.size.x * 0.5

## Yerleşimin hesapladığı vagon merkezleri - çizim de test de bunu okuyor,
## kimse kendi aritmetiğini yapmıyor.
func get_wagon_centres() -> Array[float]:
	return _wagon_centres

## Öküzlerin merkezleri, vagonlarla aynı sırada. Testin öküzün gerçekten
## kendi vagonuna koşulu olduğunu doğrulayabilmesi için.
func get_ox_centres() -> Array[float]:
	var centres: Array[float] = []
	for ox in _oxen:
		centres.append(ox.position.x + ox.size.x * 0.5)
	return centres

## Ateşlerin merkezleri, vagonlarla aynı sırada - `_wagon_centres` gibi
## test bunu okuyor, kendi aritmetiğini yapmıyor.
func get_campfire_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for index in _wagon_centres.size():
		positions.append(_campfire_position(index))
	return positions

## Şu an ateşe/kolona doğru yürüyen biri var mı - testin "kamp bitti,
## herkes yerine döndü" iddiasını doğrulaması için.
func is_gathering() -> bool:
	return not _gathering_figures.is_empty()

## Parti/tayfa/liderin merkezleri - `get_wagon_centres()`/`get_ox_centres()`
## ile aynı desen: test kendi aritmetiğini yapmadan gerçek konumu okuyor.
func get_party_centres() -> Array[float]:
	var centres: Array[float] = []
	for figure in _party_figures:
		centres.append(figure.position.x + figure.size.x * 0.5)
	return centres

func get_crew_centres() -> Array[float]:
	var centres: Array[float] = []
	for figure in _crew_figures:
		centres.append(figure.position.x + figure.size.x * 0.5)
	return centres

## Arabacıların merkezleri - kamp dışında anlamsız (görünmezler, bkz.
## `configure`'daki not), kamp sırasında/dönüşünde `_party_centres` ile
## aynı desende okunuyor.
func get_driver_centres() -> Array[float]:
	var centres: Array[float] = []
	for figure in _driver_figures:
		centres.append(figure.position.x + figure.size.x * 0.5)
	return centres

func get_leader_centre() -> float:
	if _leader == null:
		return 0.0
	return _leader.position.x + _leader.size.x * 0.5

func _process(delta: float) -> void:
	if _leader == null:
		return
	_camp_time += delta
	_advance_gather(delta)

	# Faz herkeste ilerliyor; duran bir figür de `advance(0)` alıyor ki
	# ayaklarını yan yana toplasın. Toplanan figürler burada atlanıyor -
	# onların fazını `_advance_gather` kendi adım büyüklüğüyle sürüyor,
	# çünkü kamp sırasında gerçek `_speed` zaten sıfır (bkz. orası).
	_anim_time += delta
	var step := _speed * STEP_RATE
	var figure_index := 0
	for child in get_children():
		var figure := child as WalkFigure
		if figure == null:
			continue
		figure_index += 1
		figure.set_lean(wind_lean_at(_wind_lean, _anim_time, figure_index))
		if _gather_homes.has(figure):
			continue
		figure.advance(delta, step)

	var was_swaying := _wagon_motion > 0.0
	_wagon_motion = WalkFigure.ease_motion(_wagon_motion, not is_zero_approx(_speed), delta)
	if not is_zero_approx(_speed):
		_wheel_angle = fmod(_wheel_angle + delta * _speed * 4.2, TAU)
	# Yeniden çizim üç sebepten gerekebilir: tekerlek dönüyor, ateş
	# titriyor, ya da biri hâlâ ateşe/koluna yürüyor - üçü de kendi
	# koşuluyla bağımsız.
	if not is_zero_approx(_speed) or was_swaying or _camping or not _gathering_figures.is_empty():
		queue_redraw()

## Toplanma ve dönüş: `_gather_progress` kampa göre 0↔1 arası akıyor,
## her toplanan figürün ekrandaki yeri ev-ateş arasında bu oranla
## enterpole ediliyor. Figürün kendi yürüyüş fazı da burada sürülüyor -
## `_speed`'den değil, çünkü kamp sırasında gerçek `_speed` sıfır.
func _advance_gather(delta: float) -> void:
	if _gathering_figures.is_empty():
		return
	var target := 1.0 if _camping else 0.0
	var moving := not is_equal_approx(_gather_progress, target)
	if moving:
		var step := delta / CAMP_GATHER_SECONDS
		_gather_progress = clampf(
			_gather_progress + (step if _camping else -step), 0.0, 1.0
		)
	var eased := _ease_gather(_gather_progress)
	for figure in _gathering_figures:
		var home: Vector2 = _gather_homes.get(figure, figure.position)
		var dest: Vector2 = _gather_targets.get(figure, home)
		var new_position: Vector2 = home.lerp(dest, eased)
		var walk_step := 0.0
		if moving:
			walk_step = CAMP_WALK_STEP if new_position.x >= figure.position.x else -CAMP_WALK_STEP
		figure.position = new_position
		figure.advance(delta, walk_step)

	# Dönüş bittiyse toplanma tamamen bitmiştir - kayıtlar temizleniyor,
	# yoksa bir sonraki kampa kadar boşuna taşınırlar. Sürücüler ayrıca
	# gizleniyor: koltuğu artık yeniden `ArtDraw.wagon()`'un sabit
	# silüeti tutuyor (bkz. `_draw()`'daki `driver_gone`), ikisi aynı
	# anda görünürse aynı kişi iki kez sahnede olur.
	if not _camping and is_zero_approx(_gather_progress):
		for figure in _driver_figures:
			figure.visible = false
		_gathering_figures.clear()
		_gather_homes.clear()
		_gather_targets.clear()
		_gather_fire_index.clear()
		_gather_seat_index.clear()

## Yumuşak geçiş (smoothstep): doğrusal enterpolasyon yürüyüşü başta ve
## sonda aniden kesiyor, figür ateşin dibinde fren yapmış gibi duruyordu.
func _ease_gather(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

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
	# Ölçek önce: kolon çapanın arkasına sığmıyorsa taşmak yerine
	# küçülüyor. Her terim boşluk ya da yüksekliğe oranlı bir genişlik
	# olduğu için uzunluk ölçekte doğrusal - yani tek bir çarpan yetiyor.
	var room := maxf(1.0, _anchor_x - COLUMN_EDGE_MARGIN)
	_scale = clampf(
		room / maxf(1.0, _walk_column(1.0, false)), MIN_COLUMN_SCALE, 1.0
	)

	var leader_h := maxf(size.y, 1.0) * _scale * (
		MOUNTED_HEIGHT_RATIO if _leader_mounted else PERSON_HEIGHT_RATIO
	)
	_place(
		_leader, _anchor_x + _lead_at(_scale) + _leader_offset,
		leader_h, leader_h * 1.6
	)
	_walk_column(_scale, true)
	column_length_changed.emit(get_trailing_length())

	# Arabacılar kolonun kendi yerleşiminde yer tutmuyor (koltukları
	# vagonun üstü, `_walk_column`'un imleci oraya hiç uğramıyor), o
	# yüzden boyları burada ayrıca veriliyor - aynı formül `_walk_column`
	# tayfaya ne veriyorsa (bkz. oradaki person_h/person_w).
	var height := maxf(size.y, 1.0) * _scale
	var person_h := height * PERSON_HEIGHT_RATIO
	var person_w := person_h * 0.9
	for driver in _driver_figures:
		driver.size = Vector2(person_w, person_h)

	# Kamp sırasında bir yeniden boyutlanma vagon merkezlerini kaydırabilir;
	# ateş hedefleri de tazelenmeli, yoksa dönüş yürüyüşü artık doğru
	# olmayan eski bir noktaya yönelir.
	_refresh_gather_targets()

## Kolonun tek aritmetiği: imleç çapadan geriye yürür, her parça kendi
## genişliğini tüketir, araya boşluk girer. `place` yanlışsa hiçbir şey
## yerleştirilmiyor, yalnızca tüketilen uzunluk dönüyor.
##
## Ölçmek ve yerleştirmek **aynı** fonksiyon çünkü ayrı yazıldıklarında
## ayrıştılar: ölçen kopya vagon birimindeki yürüyen tayfayı ve iki dar
## boşluğu saymıyordu, yani kolon her vagonda 66 piksel eksik ölçülüyor
## ve sığdığı sanılan kervanın kuyruğu ekrandan taşıyordu. Bu dosyanın
## kendi kuralı: iki yerde hesaplanan bir şey iki farklı şeydir - vagon
## merkezleri de tam bu yüzden yerleşimden okunuyor.
func _walk_column(scale: float, place: bool) -> float:
	var height := maxf(size.y, 1.0) * scale
	var person_h := height * PERSON_HEIGHT_RATIO
	var person_w := person_h * 0.9
	var ox_h := height * OX_HEIGHT_RATIO
	var ox_w := ox_h * 2.0
	var wagon_w := height * WAGON_WIDTH_RATIO
	var gap_tight := GAP_TIGHT * scale
	var gap_normal := GAP_NORMAL * scale
	var gap_wagons := GAP_WAGONS * scale
	var hitch_gap := HITCH_GAP * scale
	var pair_gap := PAIR_GAP * scale

	var start := _anchor_x if place else 0.0
	var cursor := start
	var placed := 0

	# Parti üyeleri kolon boyunca ikişerli gruplar hâlinde dağılıyor.
	# Önce liderin hemen arkasındaki muhafız grubu.
	cursor = _walk_escort_group(
		cursor, placed, person_h, person_w, pair_gap, gap_normal, place
	)
	placed += MAX_ABREAST

	for index in _wagon_count:
		# Bir vagon birimi, önden arkaya: [tayfa] [öküz] [vagon].
		#
		# **Öküzle vagonun arasına hiçbir şey girmez** - orası koşum yeri.
		# Tayfa bir ara oraya konmuştu (vagonun yanı gövdeyle örtüşüyordu,
		# arkası da istenmeyen isimsiz kuyruğu üretiyordu) ve sonuç ekranda
		# apaçıktı: öküzle vagon arası vagonun kendisinden neredeyse iki
		# kat genişti ve ortada bir adam duruyordu, yani öküz o vagonu
		# çeken hayvan gibi değil başıboş bir hayvan gibi okunuyordu.
		# Yürüyen tayfa artık öküzün **başında**, onu yederek yürüyor -
		# öküz arabası zaten böyle sürülür.
		if index < _crew_figures.size():
			if place:
				_place(
					_crew_figures[index], cursor - person_w * 0.5,
					person_h * 0.95, person_w
				)
			cursor -= person_w + gap_tight

		if index < _oxen.size():
			cursor -= ox_w * 0.5
			if place:
				_place(_oxen[index], cursor, ox_h, ox_w)
			cursor -= ox_w * 0.5
		cursor -= hitch_gap

		if place:
			_wagon_centres.append(cursor - wagon_w * 0.5)
		cursor -= wagon_w + gap_wagons

		# Vagonlar arasına bir parti grubu daha serpiştiriyoruz: parti
		# kolon boyunca dağılıyor, hepsi liderin arkasında toplanmıyor.
		if placed < _party_figures.size() and index < _wagon_count - 1:
			cursor = _walk_escort_group(
				cursor, placed, person_h, person_w, pair_gap, gap_normal, place
			)
			placed += MAX_ABREAST

	# Artakalan parti üyeleri en arkada, ama tayfayla aynı hizada değil.
	while placed < _party_figures.size():
		cursor = _walk_escort_group(
			cursor, placed, person_h, person_w, pair_gap, gap_normal, place
		)
		placed += MAX_ABREAST

	return start - cursor

## İkişerli bir muhafız grubu; imleci grubun tükettiği kadar geriye alır.
func _walk_escort_group(
	cursor: float, from_index: int, person_h: float, person_w: float,
	pair_gap: float, gap_normal: float, place: bool
) -> float:
	var count := mini(MAX_ABREAST, _party_figures.size() - from_index)
	if count <= 0:
		return cursor
	var step := person_w + pair_gap
	if place:
		for slot in count:
			_place(
				_party_figures[from_index + slot],
				cursor - float(slot) * step, person_h, person_w
			)
	return cursor - float(count - 1) * step - person_w - gap_normal

## `lift` figürü zemin çizgisinden yukarı alır: yolun karşı tarafında
## duran bir şey kameradan uzaktır, uzak olan da yukarıda durur.
##
## Toplanan bir figür (bkz. `_begin_gathering`) burada **atlanıyor**: onun
## ekrandaki yerini `_advance_gather`'ın enterpolasyonu yönetiyor, bu
## fonksiyon üstüne yazarsa yarı yoldaki figür ateşe/koluna anında
## ışınlanır. Yalnızca "ev" hedefi tazeleniyor - ölçek değişmiş olabilir -
## dönüş yürüyüşü güncel noktaya gitsin diye.
func _place(
	figure: WalkFigure, x: float, height: float, width: float, lift: float = 0.0
) -> void:
	figure.size = Vector2(width, height)
	var home := Vector2(x - width * 0.5, _ground_y - height - lift)
	if _gather_homes.has(figure):
		_gather_homes[figure] = home
		return
	figure.position = home

func _draw() -> void:
	if _ground_y <= 0.0 or size.y < MIN_DRAW_HEIGHT:
		return
	var height := size.y * _scale
	var wagon_w := height * WAGON_WIDTH_RATIO
	var wagon_h := height * WAGON_HEIGHT_RATIO

	for index in _wagon_centres.size():
		# Merkez yerleşimden geliyor, burada yeniden hesaplanmıyor.
		# Vagon gövdesi `ArtDraw`'da: aynı vagon şehir dışı yürüyüş
		# alanında da çiziliyor ve iki kopya tutulunca aynı kervan iki
		# ekranda iki farklı şey oluyordu.
		var centre := _wagon_centres[index]
		# Koşum oku vagondan *önce*: kalas gövdenin altından çıkıyor.
		ArtDraw.draught_pole(
			self, Vector2(centre + wagon_w * 0.48, _ground_y),
			HITCH_GAP * _scale * 1.7, wagon_h, _light
		)
		# Sürücü koltuğu boş çizilir yalnızca gerçek bir figür onu
		# devralmışsa (bkz. `_assign_driver_gather`) - ikisi aynı anda
		# çizilirse aynı kişi iki kez görünür.
		var driver_gone := index < _driver_figures.size() and _driver_figures[index].visible
		ArtDraw.wagon(
			self, Vector2(centre, _ground_y), wagon_w, wagon_h,
			_wheel_angle, _light, index == 0, not driver_gone,
			canopy_sway_at(_wheel_angle, index, wagon_h, _wagon_motion)
		)

	if _camping:
		# Ateşler vagonlardan *sonra* çiziliyor (aynı `_draw()` çağrısı,
		# yani üstlerine biner) ama figürlerden *önce*: figürler bu
		# fonksiyondan sonra, ayrı çocuklar olarak çiziliyor, yani ateşin
		# başında toplanan biri alevin önünde duruyor - tam istenen sıra.
		_draw_campfires()

	# Liderin başı her zaman işaretli: kolonda serbestçe yürüyen tek
	# beden o, oyuncu hangisinin kendisi olduğunu karıştırmasın.
	if _leader == null:
		return
	# Başının hemen üstünde: çapadan hesaplanan bir yükseklik geniş bir
	# şeritte liderin çok üstünde, havada asılı kalıyordu.
	var marker := Vector2(get_leader_centre(), _leader.position.y - 4.0)
	draw_colored_polygon(PackedVector2Array([
		marker + Vector2(-5.0, -9.0), marker + Vector2(5.0, -9.0), marker,
	]), Color(ArtPalette.GOLD, 0.85))

## Kamp ateşi vagon başına bir tane (bkz. `_campfire_position`'ın notu).
## Önceden yolun tamamı tek bir ateşi paylaşıyordu ve o ateş kolonun
## önünde, boş alanda duruyordu - hiçbir silüetin arkasına düşmeden.
## Vagon başına çoğaltınca o kaçış yolu kapandı, bu yüzden her ateş artık
## kendi vagonunun *arkasında* (bkz. yukarıdaki not) duruyor; çizim,
## rengi ve titreme deseni tek ateşin aynısı.
func _draw_campfires() -> void:
	var glow_radius := size.y * 0.24
	var flicker := 0.88 + 0.12 * sin(_camp_time * FIRE_FLICKER_SPEED)
	var flame_h := 22.0 * flicker * _scale
	for index in _wagon_centres.size():
		var fire := _campfire_position(index)
		# İki katman: geniş ve soluk bir haleyle sahnenin geneli ısınıyor
		# (bkz. "sıcak bir ortam" - tek dar bir ışık çemberi yalnızca
		# ateşin kendisini aydınlatıyordu, etrafındaki toplanmayı değil),
		# dar ve parlak olan ateşin hemen dibini.
		ArtDraw.light_pool(self, fire, glow_radius * 2.1, ArtPalette.TORCH, 0.05 * flicker, 0.60)
		ArtDraw.light_pool(self, fire, glow_radius, ArtPalette.TORCH, 0.11 * flicker, 0.48)
		# Odun + alev: alev üç dilim, en içi en açık.
		for side in [-1.0, 1.0]:
			draw_line(
				fire + Vector2(-14.0 * side, 2.0) * _scale, fire + Vector2(9.0 * side, -7.0) * _scale,
				Color(0.32, 0.24, 0.18), 3.5 * _scale
			)
		draw_colored_polygon(PackedVector2Array([
			fire + Vector2(-8.0, 0.0) * _scale, fire + Vector2(0.0, -flame_h),
			fire + Vector2(8.0, 0.0) * _scale,
		]), Color(0.92, 0.42, 0.16, 0.92))
		draw_colored_polygon(PackedVector2Array([
			fire + Vector2(-4.5, 0.0) * _scale, fire + Vector2(0.5, -flame_h * 0.66),
			fire + Vector2(4.5, 0.0) * _scale,
		]), Color(1.0, 0.82, 0.40, 0.95))
