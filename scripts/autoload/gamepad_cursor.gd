extends CanvasLayer

## Kumandayla oynanan bir oturumda fareyi sağ çubuğa taşıyan sanal imleç.
## Xbox tarayıcısından oynanabilirlik isteğiyle geldi: `city_view.gd`,
## `combat_unit_slot.gd` gibi ekranların çoğu gerçek `Button` değil,
## fare koordinatına bakan `_gui_input` ile çalışıyor - bunları teker
## teker "kumandayla da çalışsın" diye yeniden yazmak yerine, gerçek
## bir fare gibi davranan sahte olaylar üretmek tek seferlik bir çözüm:
## `Input.parse_input_event()` motorun kendi olay hattına gerçek bir
## `InputEventMouseMotion`/`InputEventMouseButton` gibi giriyor, yani
## fareyle çalışan her şey (Button'lar dahil) hiçbir ek kod olmadan
## kumandayla da çalışıyor.
##
## **Sayfa açılışında devrede değil.** Oyuncu bir kumanda tuşuna basana
## ya da sağ çubuğu ölü bölgenin dışına itene kadar gerçek tarayıcı
## imleci kalıyor - masaüstünde fareyle oynayan birine bu katman hiç
## görünmüyor. İlk kumanda girdisi geldiği an gerçek imleç gizleniyor
## (`Input.MOUSE_MODE_HIDDEN`) ve bu katman devreye giriyor; gerçek fare
## tekrar oynadığı an eski hâline dönüyor. **İki imleç asla aynı anda
## görünmüyor** - geçiş hangi girdinin son kullanıldığına bakıyor.
##
## Eşleme (Xbox düzeni):
## - Sağ çubuk: imleç
## - A: sol tık
## - B: Esc'in karşılığı (panel kapatma, iptal)
## - X: E'nin karşılığı (şehir kapısı/vagon etkileşimi)
## - LB: F2'nin karşılığı (yolda tempoyu bir kademe değiştirir)
## - RT/LT: yolda ileri/geri (`get_move_axis()` - `road_journey.gd` ve
##   `world_hub.gd` kendi A/D okumalarına bunu topluyor, burada değil)
##
## **Autoload rule'a uyuyor**: `class_name`'e hiç dokunmuyoruz
## (ne `GamepadCursorIcon`'a ne kendi olası bir isme), imleç simgesi
## runtime `load()` ile kuruluyor.

const DEADZONE: float = 0.22
const TRIGGER_DEADZONE: float = 0.08
## Merkezden uca px/sn. 1920 genişliğinde uçtan uca ~1.3 saniye -
## TV'den oynanan bir menüde çabuk ama fren tutulabilir.
const CURSOR_SPEED: float = 1500.0
## Merkeze yakın hassas, uca yakın hızlı: doğrusal olsaydı ince nişan
## almak (küçük bir butona basmak) neredeyse imkansız olurdu.
const CURSOR_CURVE: float = 1.6
const ICON_SCRIPT: String = "res://scripts/ui/gamepad_cursor_icon.gd"

var _active: bool = false
var _device: int = -1
var _position: Vector2 = Vector2.ZERO
## Kendi ürettiğimiz olayı kendi `_input()`'umuzda "gerçek fare kullanıldı,
## kumanda modundan çık" sanmamak için. `Input.parse_input_event()` olayı
## aynı çağrı içinde senkron dağıtıyor, o yüzden çağrının etrafına
## konan bu bayrak güvenilir.
var _synthetic: bool = false
var _icon: Control
var _held: Dictionary = {}

func _ready() -> void:
	layer = 4096
	process_mode = Node.PROCESS_MODE_ALWAYS
	_icon = load(ICON_SCRIPT).new()
	add_child(_icon)
	_icon.visible = false

func _input(event: InputEvent) -> void:
	if _synthetic or not _active:
		return
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_deactivate()

func _process(delta: float) -> void:
	var devices := Input.get_connected_joypads()
	if devices.is_empty():
		if _active:
			_deactivate()
		_device = -1
		return
	if _device == -1 or not devices.has(_device):
		_device = devices[0]

	var stick := Vector2(
		Input.get_joy_axis(_device, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(_device, JOY_AXIS_RIGHT_Y)
	)
	var moved := stick.length() > DEADZONE
	var any_button := (
		Input.is_joy_button_pressed(_device, JOY_BUTTON_A)
		or Input.is_joy_button_pressed(_device, JOY_BUTTON_B)
		or Input.is_joy_button_pressed(_device, JOY_BUTTON_X)
		or Input.is_joy_button_pressed(_device, JOY_BUTTON_LEFT_SHOULDER)
	)
	if not _active and (moved or any_button):
		_activate()

	if _active and moved:
		var shaped := stick.normalized() * pow(stick.length(), CURSOR_CURVE)
		_position += shaped * CURSOR_SPEED * delta
		var bounds := get_viewport().get_visible_rect().size
		_position = _position.clamp(Vector2.ZERO, bounds)
		_icon.position = _position
		_send_mouse_motion()

	if _active:
		_poll(JOY_BUTTON_A, _on_a_changed)
		_poll(JOY_BUTTON_B, _on_b_changed)
		_poll(JOY_BUTTON_X, _on_x_changed)
		_poll(JOY_BUTTON_LEFT_SHOULDER, _on_lb_changed)

## Kumandanın basılı/bırakılmış tuşlarını tek yerden okuyup yalnızca
## *değiştiği* karede bir kere haber veriyor - `_process` her karede
## çalıştığı için ham durumu doğrudan okumak tuşu basılı tutarken
## sürekli tetiklerdi.
func _poll(button: JoyButton, on_change: Callable) -> void:
	var pressed := Input.is_joy_button_pressed(_device, button)
	var was: bool = _held.get(button, false)
	if pressed == was:
		return
	_held[button] = pressed
	on_change.call(pressed)

func _on_a_changed(pressed: bool) -> void:
	_synthetic_click(pressed)

func _on_b_changed(pressed: bool) -> void:
	_synthetic_key(KEY_ESCAPE, pressed)

func _on_x_changed(pressed: bool) -> void:
	_synthetic_key(KEY_E, pressed)

func _on_lb_changed(pressed: bool) -> void:
	_synthetic_key(KEY_F2, pressed)

## Yolda ileri/geri: tetikler analog, `road_journey.gd`/`world_hub.gd`
## kendi A/D + ui_left/ui_right toplamına bunu ekliyor. Kumanda modu
## (sanal imleç) hiç açılmamış olsa bile çalışır - oyuncu doğrudan
## tetiklerle yürümeye başlayabilir, önce çubuğu oynatması gerekmez.
func get_move_axis() -> float:
	if _device == -1:
		return 0.0
	var right := Input.get_joy_axis(_device, JOY_AXIS_TRIGGER_RIGHT)
	var left := Input.get_joy_axis(_device, JOY_AXIS_TRIGGER_LEFT)
	if right < TRIGGER_DEADZONE:
		right = 0.0
	if left < TRIGGER_DEADZONE:
		left = 0.0
	return clampf(right - left, -1.0, 1.0)

func _activate() -> void:
	_active = true
	_position = get_viewport().get_visible_rect().size * 0.5
	_icon.position = _position
	_icon.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _deactivate() -> void:
	_active = false
	_icon.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _send_mouse_motion() -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = _position
	ev.global_position = _position
	_dispatch(ev)

func _synthetic_click(pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = _position
	ev.global_position = _position
	_dispatch(ev)

func _synthetic_key(keycode: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = pressed
	_dispatch(ev)

func _dispatch(ev: InputEvent) -> void:
	_synthetic = true
	Input.parse_input_event(ev)
	_synthetic = false
