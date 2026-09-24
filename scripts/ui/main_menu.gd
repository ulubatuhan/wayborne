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

## Menü bir defterin sayfasında duruyor (bkz. Waybook UI Rules): başlık
## evresinde kapalı kapak, ilk girdide kapak açılıyor ve düğmeler sağ
## sayfada. Defter manzaranın üstünde kendi zeminini taşıyor - eski düz
## karartma kutusunun işini artık o yapıyor.
const BOOK_WIDTH_RATIO: float = 0.5
const BOOK_MAX_WIDTH: float = 1000.0
const BOOK_CENTER: Vector2 = Vector2(0.36, 0.40)
## Sayfa ve plaka bölgeleri, dokunun kendi boyutuna oranla (m2_spread.png /
## m1_cover.png üstünde ölçüldü). Yazı bu dikdörtgenlerin içinde kalıyor.
const SPREAD_LEFT_PAGE: Rect2 = Rect2(0.225, 0.15, 0.17, 0.56)
const SPREAD_RIGHT_PAGE: Rect2 = Rect2(0.555, 0.13, 0.26, 0.60)
const COVER_NAMEPLATE: Rect2 = Rect2(0.356, 0.268, 0.369, 0.116)
const COVER_LOWER: Rect2 = Rect2(0.14, 0.62, 0.72, 0.18)
const COVER_OPEN_SECONDS: float = 0.35

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
var _book: Control
var _cover: TextureRect
var _spread: TextureRect
var _left_page: VBoxContainer
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

## Manzara ve defter butonların **arkasına** giriyor: `add_child` onları
## en sona koyar, `move_child(…, 0)` en başa. Sahne dosyasına eklemek
## yerine kodda kurulmalarının sebebi `PulseBar`/`OnboardingPanel` ile
## aynı - sahnesiz bir bileşen tek bir yerde tanımlı kalıyor.
func _build_backdrop() -> void:
	var backdrop := MenuBackdrop.new()
	add_child(backdrop)
	move_child(backdrop, 0)
	_build_book()
	get_viewport().size_changed.connect(_layout_book)
	_layout_book()

## Kapak ve açık sayfa aynı `_book` düğümünün çocukları. Düğmelerin kutusu
## sağ sayfaya taşınıyor, başlık sol sayfaya - sahne dosyasındaki düğüm
## yolları (`$VBoxContainer/...`) değişmiyor, yalnızca ebeveynleri.
func _build_book() -> void:
	_book = Control.new()
	_book.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_book)
	move_child(_book, 1)

	_spread = _book_texture("m2_spread.png")
	_book.add_child(_spread)
	_cover = _book_texture("m1_cover.png")
	_book.add_child(_cover)

	_left_page = VBoxContainer.new()
	_left_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left_page.add_theme_constant_override("separation", 6)
	_spread.add_child(_left_page)
	var title := $VBoxContainer/TitleLabel as Label
	title.reparent(_left_page, false)
	title.add_theme_color_override("font_color", ArtPalette.UI_TEXT_ON_PAGE)
	title.add_theme_font_size_override("font_size", 34)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for line in _lineage_lines():
		_left_page.add_child(_page_label(line, false))

	_menu_box.reparent(_spread, false)
	_menu_box.add_theme_constant_override("separation", 10)
	_menu_box.set_anchors_preset(Control.PRESET_TOP_LEFT)

	var plate := _page_label("WAYBORNE", true)
	plate.name = "Nameplate"
	# Tek kelime: sarılırsa harf harf bölünüp plakadan taşıyordu.
	plate.autowrap_mode = TextServer.AUTOWRAP_OFF
	plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cover.add_child(plate)
	var lower := VBoxContainer.new()
	lower.name = "CoverLower"
	lower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for line in _lineage_lines():
		var label := _page_label(line, false)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", ArtPalette.UI_TEXT)
		lower.add_child(label)
	_cover.add_child(lower)

func _book_texture(file_name: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = WaybookTheme.texture(file_name)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

func _page_label(text: String, engraved: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", ArtPalette.UI_TEXT_ON_PAGE)
	if engraved:
		label.add_theme_font_size_override("font_size", 18)
	return label

## Kapağın ve sol sayfanın söylediği: bu defteri kim taşıyor. Otomatik
## kayıt yoksa kapak boş bir defter olduğunu söylüyor - isim ve kuşak
## canlı metin, görselde hiçbir yazı yok (Localization Rules).
func _lineage_lines() -> Array[String]:
	var summary := SaveManager.get_summary(SaveManager.AUTOSAVE_SLOT)
	var lines: Array[String] = []
	if summary.is_empty() or String(summary.get("caravan_name", "")).is_empty():
		lines.append(tr("UI_WAYBOOK_UNWRITTEN"))
		return lines
	lines.append(String(summary["caravan_name"]))
	lines.append(tr("UI_WAYBOOK_GENERATION") % int(summary.get("lineage_generation", 1)))
	lines.append(tr("UI_WAYBOOK_DAYS") % int(summary.get("total_days_elapsed", 0)))
	return lines

## Defterin boyu ekrana göre; kapak açık defterin sağ yarısının üstünde
## duruyor, sırtı ortada - açılınca sola doğru katlanıyor.
func _layout_book() -> void:
	var view := get_viewport_rect().size
	var spread_size := _spread.texture.get_size()
	var cover_size := _cover.texture.get_size()
	var width := minf(view.x * BOOK_WIDTH_RATIO, BOOK_MAX_WIDTH)
	var height := width * spread_size.y / spread_size.x
	_spread.size = Vector2(width, height)
	_spread.position = view * BOOK_CENTER - _spread.size * 0.5
	var cover_height := height * 0.98
	_cover.size = Vector2(cover_height * cover_size.x / cover_size.y, cover_height)
	_cover.position = Vector2(_spread.position.x + width * 0.5, _spread.position.y + (height - cover_height) * 0.5)
	_cover.pivot_offset = Vector2(0.0, cover_height * 0.5)
	_place(_left_page, SPREAD_LEFT_PAGE, _spread.size)
	_place(_menu_box, SPREAD_RIGHT_PAGE, _spread.size)
	_place(_cover.get_node("Nameplate") as Control, COVER_NAMEPLATE, _cover.size)
	_place(_cover.get_node("CoverLower") as Control, COVER_LOWER, _cover.size)

func _place(control: Control, ratio: Rect2, parent_size: Vector2) -> void:
	control.position = ratio.position * parent_size
	control.size = ratio.size * parent_size
	control.custom_minimum_size = Vector2(ratio.size.x * parent_size.x, 0.0)

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
	_spread.modulate.a = 0.0
	_cover.visible = true
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
	_cover.visible = false
	_spread.modulate.a = 1.0

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

## Kapak sırtından sola katlanıyor (x ölçeği 1 → 0), sonra açık sayfa
## beliriyor. Aynı sahne, aynı manzara - yalnızca defter açılıyor.
func _reveal_menu() -> void:
	var open := create_tween()
	open.tween_property(_cover, "scale:x", 0.0, COVER_OPEN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	open.tween_callback(func() -> void: _cover.visible = false)
	open.tween_property(_spread, "modulate:a", 1.0, REVEAL_SECONDS)

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
	# Sefer ortasında alınmış bir otomatik kayıt yola döner (bkz. Nav.resume_scene).
	SceneInk.go(Nav.resume_scene(session))

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
	SceneInk.go(Nav.open(Nav.MAIN_MENU, Nav.CHARACTER_CREATION))

func _on_saves_pressed() -> void:
	SceneInk.go(Nav.open(Nav.MAIN_MENU, Nav.SAVES))

func _on_settings_pressed() -> void:
	SceneInk.go(Nav.open(Nav.MAIN_MENU, Nav.SETTINGS))

func _on_quit_pressed() -> void:
	get_tree().quit()
