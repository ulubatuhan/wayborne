extends Control

## Girişte seçilen dil tüm oyun için geçerli olur (bkz. scripts/ui/settings.gd
## - dil seçici artık burada değil, Ayarlar ekranında).
##
## Tayfa büyüklüğü ve karakterin kendisi artık burada değil, karakter
## oluşturma ekranında seçiliyor - "Yeni Oyun" oraya gider, oturum da
## orada kurulur.
##
## **Bir "bir tuşa basın" evresiyle açılıyor, ayrı bir sahne olarak değil.**
## İstenen şey sahne değişmeden yaşanan bir geçişti ("ekran siyahlanıp
## yeniden yüklenmemeli") - `MenuBackdrop`'u ayrı bir title-screen sahnesine
## taşıyıp oradan `change_scene_to_file` ile buraya geçmek tam da
## istenmeyen şeyi yapardı: manzara sıfırdan kurulur, kervanın döngüsü
## yeniden başlardı. Bunun yerine `MainMenu`'nün kendisi iki evreli: önce
## yalnızca nabız gibi atan bir davet metni, ilk girdide (klavye/fare/kol/
## dokunmatik fark etmez) aynı sahnede butonlar beliriyor. Evre yalnızca **süreç içi**
## bir kez yaşanıyor - `_title_shown_this_run` bir statik değişken (bkz.
## `Nav`'ın `recruit_venue`'sü, aynı GDScript özelliği), yoksa Ayarlar'dan
## geri dönmek bile oyuncuyu yeniden "bir tuşa bas" ekranına düşürürdü.
##
## **Dokunuşla (ve aslında fareyle de) geçilemiyordu - klavye hep
## çalışıyordu.** "Telefonda dokunarak geçemiyorum" diye bildirildi;
## ölçüldüğünde neden dokunmatığa özgü değil çıktı: sahnenin kök
## `Control`'ü (`MainMenu`'nün kendisi, tam ekran) kendi `mouse_filter`'ını
## hiç ayarlamamıştı, yani varsayılan `STOP`'ta kaldı. Butonlar/karartma/
## davet metni zaten `IGNORE`'du (aşağıdaki `_set_buttons_mouse_ignore`'un
## notu bunu anlatıyor) ama en dıştaki, tüm ekranı kaplayan kök hâlâ her
## işaretçi olayını kendi üstünde durduruyordu - klavye bu yoldan hiç
## geçmediği için etkilenmedi, fare tıklaması ve dokunuşun emüle ettiği
## fare tıklaması ikisi de `_unhandled_input`'a hiç ulaşamadan yutuluyordu.
## Kökün `mouse_filter`'ı da `IGNORE` olunca (bkz. `main_menu.tscn`) ikisi
## de düzeldi - `InputEventScreenTouch`'u da hedef listesine eklemek tek
## başına yetmezdi, çünkü sorun hangi olay türünün tanındığı değil, olayın
## hiç ulaşmamasıydı.

## Başlık ve butonların arkasındaki karartma. Manzaranın üstüne çıplak
## metin koymak, gökyüzünün açık olduğu yerde başlığı okunmaz yapıyor -
## olay kartının kendi opak kutusunu taşımasıyla aynı gerekçe.
const SCRIM_PAD: Vector2 = Vector2(56.0, 40.0)
const SCRIM_COLOR: Color = Color(0.04, 0.035, 0.045, 0.62)

## Davet metninin nabız hızı ve parlaklık aralığı - `PulseBar`'ın "değişimi
## göster" mantığının aynısı, burada sürekli tekrar eden bir davet için.
const PROMPT_PULSE_SECONDS: float = 1.35
const PROMPT_DIM_ALPHA: float = 0.35

## Davet metni artık düz varsayılan boyutta değil - küçüklüğü playtest'te
## "fark edilmiyor" diye geldi. Işıması `ArtPalette.TORCH`'tan: arka
## planın kendi güneşiyle aynı sıcak ton, yoksa metin manzaradan kopuk bir
## öge gibi durur (bkz. Art Rules'un "tek palet" ilkesi). Sıfır ofsetli
## geniş bir gölge Godot'un SDF font gölgesini bir hâleye çeviriyor - ayrı
## bir shader ya da ikinci bir Label gerekmiyor. İnce bir mürekkep dış
## çizgisi de var, yalnızca gökyüzü açıkken metnin okunurluğu düşmesin diye.
const PROMPT_FONT_SIZE: int = 26
const PROMPT_GLOW_ALPHA: float = 0.6
const PROMPT_GLOW_SIZE: int = 14
const PROMPT_OUTLINE_SIZE: int = 2

## Butonlar beliriken her biri öncekinden bu kadar geç başlıyor - tek
## seferde hepsinin birden açılması "belirmek" değil "anahtarı çevirmek"
## gibi duruyordu.
const REVEAL_STAGGER_SECONDS: float = 0.09
const REVEAL_SECONDS: float = 0.45
const REVEAL_SLIDE_PX: float = 14.0

static var _title_shown_this_run: bool = false

@onready var _menu_box: VBoxContainer = $VBoxContainer
@onready var _continue_button: Button = $VBoxContainer/ContinueButton
@onready var _play_button: Button = $VBoxContainer/PlayButton
@onready var _saves_button: Button = $VBoxContainer/SavesButton
@onready var _settings_button: Button = $VBoxContainer/SettingsButton
@onready var _quit_button: Button = $VBoxContainer/QuitButton

var _confirm_dialog: ConfirmationDialog
var _scrim: ColorRect
var _prompt_label: Label
var _prompt_tween: Tween
var _in_title_phase: bool = false

func _ready() -> void:
	Nav.go_root(Nav.MAIN_MENU)
	_build_backdrop()
	_continue_button.visible = SaveManager.has_save()
	# Elle kayıt yuvaları otomatik kayıttan ayrı sayılıyor (bkz.
	# SaveManager'ın başındaki not) - "Devam Et" hâlâ yalnızca otomatik
	# kaydı okuyor, "Kayıtlar" hepsini listeliyor. Hiç kayıt yoksa
	# (ne otomatik ne elle) düğme de gizli - boş bir liste açmanın anlamı
	# yok, tıpkı Devam Et'in kendisi gibi.
	_saves_button.visible = SaveManager.has_any_save()
	_continue_button.pressed.connect(_on_continue_pressed)
	_play_button.pressed.connect(_on_play_pressed)
	_saves_button.pressed.connect(_on_saves_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	_refresh_texts()

	if _title_shown_this_run:
		_show_menu_immediately()
	else:
		_begin_title_phase()

## Manzara ve karartma butonların **arkasına** giriyor: `add_child` onları
## en sona koyar, `move_child(…, 0)` en başa. Sahne dosyasına eklemek
## yerine kodda kurulmalarının sebebi `PulseBar`/`OnboardingPanel` ile
## aynı - sahnesiz bir bileşen tek bir yerde tanımlı kalıyor.
func _build_backdrop() -> void:
	var backdrop := MenuBackdrop.new()
	add_child(backdrop)
	move_child(backdrop, 0)

	_scrim = ColorRect.new()
	_scrim.color = SCRIM_COLOR
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scrim)
	move_child(_scrim, 1)
	_fit_scrim()
	# Butonların kutusu yerleşim geçişinden önce doğru boyunu bilmiyor
	# (dil değişince metin de değişiyor), o yüzden karartma onu izliyor.
	_menu_box.resized.connect(_fit_scrim)
	_menu_box.item_rect_changed.connect(_fit_scrim)

func _fit_scrim() -> void:
	_scrim.position = _menu_box.position - SCRIM_PAD
	_scrim.size = _menu_box.size + SCRIM_PAD * 2.0

## --- "Bir tuşa basın" evresi ---

## Sahne canlı kalıyor (bkz. dosya başındaki not): butonlar ve karartma
## saydam ve tıklanamaz, yalnızca manzara ve davet metni görünür. Müzik de
## henüz yok - `AudioManager.play_ambience` rüzgarı çalıyor, ilk girdiye
## kadar tek ses o.
##
## `visible = false` değil `modulate:a = 0` kullanılıyor - **bilerek**.
## `VBoxContainer` çocuklarını yalnızca görünürken diziyor; sahne henüz ilk
## yerleşim geçişini yapmadan `visible`'ı kapatırsak butonlar hiç
## dizilmeden kalıyor ve `_reveal_menu()` hepsini aynı (0,0) civarındaki
## bayat konumdan okuyup üst üste bindiriyordu - ölçüldü, tam bu oldu.
## Saydam ama görünür bir kutu her zaman doğru dizili kalıyor.
func _begin_title_phase() -> void:
	_in_title_phase = true
	_menu_box.modulate.a = 0.0
	_set_buttons_enabled(false)
	_set_buttons_mouse_ignore(true)
	_scrim.visible = false
	set_process_unhandled_input(true)

	_prompt_label = Label.new()
	_prompt_label.text = tr("UI_TITLE_PROMPT")
	_prompt_label.label_settings = _build_prompt_label_settings()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.position.y -= 64.0
	_prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prompt_label)

	_prompt_tween = create_tween()
	_prompt_tween.set_loops()
	_prompt_tween.tween_property(_prompt_label, "modulate:a", PROMPT_DIM_ALPHA, PROMPT_PULSE_SECONDS)
	_prompt_tween.tween_property(_prompt_label, "modulate:a", 1.0, PROMPT_PULSE_SECONDS)

	AudioManager.play_ambience(AudioManager.AMBIENCE_WIND)

func _build_prompt_label_settings() -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font_size = PROMPT_FONT_SIZE
	settings.font_color = ArtPalette.BONE
	settings.outline_size = PROMPT_OUTLINE_SIZE
	settings.outline_color = Color(ArtPalette.INK, 0.7)
	settings.shadow_size = PROMPT_GLOW_SIZE
	settings.shadow_offset = Vector2.ZERO
	settings.shadow_color = Color(ArtPalette.TORCH, PROMPT_GLOW_ALPHA)
	return settings

## Menü sahnesiz bir kere daha açıldığında (Ayarlar'dan dönüş gibi) evre
## hiç yaşanmadan doğrudan bu hâle geçiyor - eski davranışın aynısı.
func _show_menu_immediately() -> void:
	AudioManager.play_track(AudioManager.TRACK_ROAD)
	_menu_box.modulate.a = 1.0
	_set_buttons_enabled(true)
	_scrim.visible = true

func _set_buttons_enabled(enabled: bool) -> void:
	_continue_button.disabled = not enabled
	_play_button.disabled = not enabled
	_saves_button.disabled = not enabled
	_settings_button.disabled = not enabled
	_quit_button.disabled = not enabled

## `disabled` yalnızca "pressed" sinyalini susturur - düğme hâlâ varsayılan
## mouse_filter'ıyla (STOP) fareyi kendi dikdörtgeninde durdurur, saydam
## olsa da. Tuş basımı bunu hiç görmüyor (doğrudan _unhandled_input'a
## düşüyor), bu yüzden klavye/kol zaten çalışırken bir tık yalnızca ekranın
## boş kısımlarında işe yarıyordu - oyuncunun tam olarak butonların
## durduğu yere tıklaması en olası davranış. Başlık evresinde düğmeler
## fareyi de görmezden gelmeli ki tık, tuş basımıyla aynı yoldan geçsin.
func _set_buttons_mouse_ignore(ignore: bool) -> void:
	var filter := Control.MOUSE_FILTER_IGNORE if ignore else Control.MOUSE_FILTER_STOP
	_continue_button.mouse_filter = filter
	_play_button.mouse_filter = filter
	_saves_button.mouse_filter = filter
	_settings_button.mouse_filter = filter
	_quit_button.mouse_filter = filter

## Klavye, fare, kol ya da dokunmatik - hangisiyle oynadığı önemli değil,
## ilki geçişi başlatıyor. `echo`'yu eleniyor yoksa tuşu basılı tutmak
## onlarca kez tetiklerdi (yalnızca bir kez tetiklenmesi gerektiği için
## önemli, aksi hâlde _begin_transition çoklu çağrıdan zarar görmez ama
## gereksiz). `InputEventScreenTouch`'un burada ayrıca sayılması, tek
## başına dokunuşun fareye emülasyonuna (`InputEventMouseButton`) bel
## bağlamamak için - emülasyon proje ayarına bağlı, kapalıyken ya da
## ikincil bir parmak için hiç üretilmeyebilir.
func _unhandled_input(event: InputEvent) -> void:
	if not _in_title_phase:
		return
	var qualifies: bool = (
		(event is InputEventKey and event.pressed and not event.echo)
		or (event is InputEventJoypadButton and event.pressed)
		or (event is InputEventMouseButton and event.pressed)
		or (event is InputEventScreenTouch and event.pressed)
	)
	if not qualifies:
		return
	get_viewport().set_input_as_handled()
	_begin_transition()

## Rüzgar sönerken yol müziği yükseliyor (iki ayrı çalıcı, bkz.
## AudioManager), davet metni soluyor, butonlar mürekkep gibi yukarıdan
## aşağıya belirir - hiçbiri sahne değiştirmeden, `MenuBackdrop` hiç
## kesilmeden sürüyor.
func _begin_transition() -> void:
	_in_title_phase = false
	_title_shown_this_run = true
	set_process_unhandled_input(false)

	AudioManager.play_sfx(AudioManager.SFX_THUD)
	AudioManager.stop_ambience()
	AudioManager.play_track(AudioManager.TRACK_ROAD)

	if _prompt_tween != null and _prompt_tween.is_valid():
		_prompt_tween.kill()
	var prompt := _prompt_label
	var fade_out := create_tween()
	fade_out.tween_property(prompt, "modulate:a", 0.0, 0.4)
	fade_out.tween_callback(prompt.queue_free)

	_reveal_menu()

func _reveal_menu() -> void:
	_scrim.visible = true
	_scrim.modulate.a = 0.0
	create_tween().tween_property(_scrim, "modulate:a", 1.0, REVEAL_SECONDS)

	# Kutunun kendisi zaten görünürdü (bkz. `_begin_title_phase`'in notu) -
	# yalnızca saydamlığı kaldırılıyor, çocukların gerçek dizilimine hiç
	# dokunulmadan.
	_menu_box.modulate.a = 1.0
	_set_buttons_enabled(true)
	_set_buttons_mouse_ignore(false)

	var index := 0
	for child in _menu_box.get_children():
		if not (child is Control) or not child.visible:
			continue
		var control := child as Control
		control.modulate.a = 0.0
		var home_y := control.position.y
		control.position.y = home_y - REVEAL_SLIDE_PX
		var delay := index * REVEAL_STAGGER_SECONDS
		var reveal := create_tween()
		reveal.set_parallel(true)
		reveal.tween_property(control, "modulate:a", 1.0, REVEAL_SECONDS).set_delay(delay)
		reveal.tween_property(control, "position:y", home_y, REVEAL_SECONDS).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		index += 1

func _refresh_texts() -> void:
	_continue_button.text = tr("UI_CONTINUE")
	_play_button.text = tr("UI_PLAY")
	_saves_button.text = tr("UI_MAIN_MENU_SAVES")
	_settings_button.text = tr("UI_SETTINGS")
	_quit_button.text = tr("UI_QUIT")

func _on_continue_pressed() -> void:
	var session = SaveManager.load_session()
	if session == null:
		return
	GameState.set_session(session)
	get_tree().change_scene_to_file(Nav.go_root(Nav.CITY_MAP))

func _on_play_pressed() -> void:
	if SaveManager.has_save():
		_confirm_new_game()
	else:
		_open_character_creation()

func _confirm_new_game() -> void:
	if _confirm_dialog == null:
		_confirm_dialog = ConfirmationDialog.new()
		_confirm_dialog.confirmed.connect(_open_character_creation)
		add_child(_confirm_dialog)
	_confirm_dialog.dialog_text = tr("UI_NEW_GAME_CONFIRM")
	_confirm_dialog.popup_centered()

## Kayıt yalnızca karakter oluşturma tamamlanınca silinir; oyuncu geri
## dönerse eski kaydı yerinde durur.
func _open_character_creation() -> void:
	get_tree().change_scene_to_file(Nav.open(Nav.MAIN_MENU, Nav.CHARACTER_CREATION))

func _on_saves_pressed() -> void:
	get_tree().change_scene_to_file(Nav.open(Nav.MAIN_MENU, Nav.SAVES))

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(Nav.open(Nav.MAIN_MENU, Nav.SETTINGS))

func _on_quit_pressed() -> void:
	get_tree().quit()
