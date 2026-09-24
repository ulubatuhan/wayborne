extends Node

## Düğmenin eldeki hissi: üstüne gelince hafifçe büyür, basınca içe göçer,
## bırakınca bir an taşıp yerine oturur. Bir tuşun basılabilir olduğunu
## yalnızca rengi söylüyordu - defterin sayfasındaki mühürlü bir sekme
## gibi değil, ekrandaki bir dikdörtgen gibi.
##
## `UiTheme` her düğmeye kendiliğinden bir tane ekliyor (`SceneInk`'in ve
## `RowButton`'ın deseni: hiçbir ekran hatırlamak zorunda değil). Tween'ler
## düğmenin kendisine ait - düğme silinince onlar da gider, sahipsiz bir
## animasyon kalmaz. Kilitli düğme kıpırdamaz: basılamayan bir şeyin
## basılıyormuş gibi davranması yalan olur.
##
## `class_name` yok: `UiTheme` autoload'u bunu yüklüyor ve autoload'lar
## global sınıf önbelleği hazır olmadan ayrıştırılıyor (bkz. proje
## kurallarının Autoload maddesi) - kendi sınıf adını anan bir betik orada
## derlenemiyordu (ölçüldü). Yol üzerinden yükleniyor.
##
## Yalnızca `scale` oynuyor, konum değil: kap (container) konumu her
## yerleşimde yeniden yazar ama ölçeğe dokunmaz, ve merkez `pivot_offset`
## her boyut değişiminde yeniden hesaplanıyor.

const HOVER_SECONDS: float = 0.12
const PRESS_SECONDS: float = 0.06
const RELEASE_SECONDS: float = 0.08
const PRESS_SCALE: float = 0.96
const RELEASE_OVERSHOOT: float = 1.02
## Üstüne gelme büyümesi en çok %3, ama geniş bir sıra düğmesinde yüzde
## değil piksel sayılır: 1000 piksellik bir satırın %3'ü 30 piksel - bir
## zıplama. Bu yüzden kenar başına en çok 3 px (toplam 6).
const HOVER_MAX: float = 0.03
const HOVER_MAX_PIXELS: float = 6.0
const ATTACHED_META: StringName = &"_button_feedback"
const SELF_PATH: String = "res://scripts/ui/button_feedback.gd"

var _button: BaseButton
var _tween: Tween
var _hovered: bool = false
var _host: BaseButton

## Büyüme oranı genişliğe bağlı: dar sekme %3, geniş sıra birkaç piksel.
static func hover_scale(width: float) -> float:
	if width <= 0.0:
		return 1.0 + HOVER_MAX
	return 1.0 + minf(HOVER_MAX, HOVER_MAX_PIXELS / width)

## Bir düğmeye bir kez takılır; zaten takılıysa dokunmaz. Ertelenmiş:
## düğüm ağaca girerken (`node_added`) ebeveyn hâlâ çocuklarını kuruyor,
## o anda çocuk eklemek motorun "ebeveyn meşgul" hatasıdır. İç (internal)
## çocuk olarak ekleniyor - `get_children()` onu görmez, yani düğmenin
## çocuklarını sayan hiçbir kod bundan etkilenmez.
static func attach(button: BaseButton) -> void:
	if button.has_meta(ATTACHED_META):
		return
	button.set_meta(ATTACHED_META, true)
	var feedback: Node = load(SELF_PATH).new()
	feedback.name = "ButtonFeedback"
	feedback._host = button
	feedback._install.call_deferred()

## Ertelenmiş kurulum: düğme bu arada silindiyse düğüm de kendini siliyor,
## sahipsiz kalmıyor.
func _install() -> void:
	if not is_instance_valid(_host):
		# Kendi çağrısının içinde `free()` kilitli bir nesneyi silmek olur.
		queue_free()
		return
	_host.add_child(self, false, Node.INTERNAL_MODE_BACK)

func _ready() -> void:
	_button = get_parent() as BaseButton
	if _button == null:
		return
	_button.mouse_entered.connect(_on_entered)
	_button.mouse_exited.connect(_on_exited)
	_button.button_down.connect(_on_down)
	_button.button_up.connect(_on_up)
	_button.resized.connect(_recentre)
	_recentre()

func _recentre() -> void:
	_button.pivot_offset = _button.size * 0.5

func _on_entered() -> void:
	_hovered = true
	if _still():
		return
	_animate(hover_scale(_button.size.x), HOVER_SECONDS)

func _on_exited() -> void:
	_hovered = false
	if _reduce_motion():
		_button.scale = Vector2.ONE
		return
	_animate(1.0, HOVER_SECONDS)

func _on_down() -> void:
	if _still():
		return
	_animate(PRESS_SCALE, PRESS_SECONDS)

func _on_up() -> void:
	if _still():
		return
	_kill()
	_recentre()
	var rest := hover_scale(_button.size.x) if _hovered else 1.0
	_tween = _button.create_tween()
	_tween.tween_property(_button, "scale", Vector2.ONE * RELEASE_OVERSHOOT, RELEASE_SECONDS * 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_button, "scale", Vector2.ONE * rest, RELEASE_SECONDS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Kilitli düğme ve "hareketi azalt" ayarı: ikisinde de ölçek oynamaz.
func _still() -> bool:
	if _button.disabled or _reduce_motion():
		_kill()
		_button.scale = Vector2.ONE
		return true
	return false

func _animate(target: float, seconds: float) -> void:
	_kill()
	_recentre()
	_tween = _button.create_tween()
	_tween.tween_property(_button, "scale", Vector2.ONE * target, seconds) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _kill() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

func _reduce_motion() -> bool:
	if not is_inside_tree():
		return false
	var settings := get_node_or_null("/root/UserSettings")
	return settings != null and bool(settings.get("reduce_motion"))
