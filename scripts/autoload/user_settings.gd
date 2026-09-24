extends Node

## Autoload: oyuncunun oyun durumundan bağımsız tercihleri. Şimdilik tek
## tercih dil; kayıt dosyasından (user://save.json) ayrı tutuluyor çünkü
## dil "Yeni Oyun" dendiğinde sıfırlanmamalı.
##
## Desteklenen dillerin tek doğruluk kaynağı burası. Yeni bir dil eklemek
## iki adım: (1) SUPPORTED listesine bir satır, (2) her CSV'ye o kodda bir
## sütun + project.godot'un locale/translations dizisine üç .translation
## yolu. tests/test_localization.gd ikisinin ayrışmasına izin vermiyor.
##
## Bu dosyada bilerek hiçbir class_name'e başvurulmuyor - autoload'lar
## global script class cache hazır olmadan ayrıştırılıyor (bkz. CLAUDE.md
## Autoload rule).

const CONFIG_PATH: String = "user://settings.cfg"
const CONFIG_SECTION: String = "locale"
const CONFIG_KEY: String = "code"

## Ses. Dosyanın sahibi bu autoload olduğu için müzik seviyesi de
## buradan okunup yazılıyor - `AudioManager` sesi *çalar*, tercihi
## saklamaz. İki ayrı yazıcı olsaydı biri ötekinin bölümünü silerdi
## (config.load + set_value + save deseninin var olma sebebi tam bu).
const AUDIO_SECTION: String = "audio"
const AUDIO_KEY_MUSIC: String = "music_volume"
const DEFAULT_MUSIC_VOLUME: float = 0.7
## Hareket hassasiyeti: açıkken sahne geçişleri kaymak yerine mürekkepten
## belirir ve savaş sahnesi sarsılmaz. Bilgi taşıyan hiçbir şey (parlama,
## hasar sayısı, düşüş) kapanmıyor - yalnızca ekranın kendisinin oynaması.
const MOTION_SECTION: String = "motion"
const MOTION_KEY_REDUCE: String = "reduce"

## Boş bırakılan hücreler bu dile düşer (Godot'ta doğrulandı: eksik çeviri
## anahtarı basmaz, fallback locale'in metnini basar), bu yüzden İngilizce
## her zaman eksiksiz dolu olmalı.
const FALLBACK_LOCALE: String = "en"

## code: Godot locale kodu ve CSV sütun adı - ikisi birebir aynı olmalı.
## name: dilin kendi dilindeki adı (endonym) - dil seçici her zaman kendi
## dilinde okunur, oyuncu bilmediği bir dilde kendi dilini arayamaz.
const SUPPORTED: Array[Dictionary] = [
	{"code": "tr", "name": "Türkçe"},
	{"code": "en", "name": "English"},
	{"code": "de", "name": "Deutsch"},
	{"code": "fr", "name": "Français"},
	{"code": "es", "name": "Español"},
	{"code": "it", "name": "Italiano"},
	{"code": "pt_BR", "name": "Português (Brasil)"},
	{"code": "ru", "name": "Русский"},
	{"code": "pl", "name": "Polski"},
	{"code": "zh_CN", "name": "简体中文"},
	{"code": "ja", "name": "日本語"},
]

var reduce_motion: bool = false

func _ready() -> void:
	apply_saved_locale()
	reduce_motion = load_reduce_motion()

func load_reduce_motion() -> bool:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return false
	return bool(config.get_value(MOTION_SECTION, MOTION_KEY_REDUCE, false))

func set_reduce_motion(enabled: bool) -> void:
	reduce_motion = enabled
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value(MOTION_SECTION, MOTION_KEY_REDUCE, enabled)
	config.save(CONFIG_PATH)

func get_locale_codes() -> Array:
	var codes: Array = []
	for entry in SUPPORTED:
		codes.append(entry["code"])
	return codes

func get_locale_names() -> Array:
	var names: Array = []
	for entry in SUPPORTED:
		names.append(entry["name"])
	return names

func is_supported(code: String) -> bool:
	return get_locale_codes().has(code)

## Kaydedilmiş dil yoksa sistemin dili denenir - oyuncu Almanca bir
## makinede oyunu açtığında Türkçe karşılamak yerine kendi dilinde
## başlasın. O da desteklenmiyorsa fallback.
func apply_saved_locale() -> void:
	var saved := load_locale()
	if saved.is_empty():
		saved = _match_system_locale()
	set_locale(saved)

func set_locale(code: String) -> void:
	var resolved := code if is_supported(code) else FALLBACK_LOCALE
	TranslationServer.set_locale(resolved)
	save_locale(resolved)

func load_locale() -> String:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return ""
	var stored := str(config.get_value(CONFIG_SECTION, CONFIG_KEY, ""))
	return stored if is_supported(stored) else ""

func save_locale(code: String) -> void:
	var config := ConfigFile.new()
	# Var olan dosyayı okuyup üstüne yazıyoruz ki ileride eklenecek başka
	# tercihler (ses, tuş atamaları) bu yazımda silinmesin.
	config.load(CONFIG_PATH)
	config.set_value(CONFIG_SECTION, CONFIG_KEY, code)
	config.save(CONFIG_PATH)

func load_music_volume() -> float:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return DEFAULT_MUSIC_VOLUME
	return clampf(
		float(config.get_value(AUDIO_SECTION, AUDIO_KEY_MUSIC, DEFAULT_MUSIC_VOLUME)),
		0.0, 1.0
	)

func save_music_volume(volume: float) -> void:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value(AUDIO_SECTION, AUDIO_KEY_MUSIC, clampf(volume, 0.0, 1.0))
	config.save(CONFIG_PATH)

## "de_DE" gibi bölgeli bir sistem kodu önce tam eşleşme, sonra dil kökü
## ("de") olarak aranır - pt_BR gibi bölgeye bağlı bir kaydı da doğru
## yakalasın diye tam eşleşme önce deneniyor.
func _match_system_locale() -> String:
	var system_locale := OS.get_locale()
	if is_supported(system_locale):
		return system_locale

	var root := system_locale.split("_")[0]
	for entry in SUPPORTED:
		var code: String = entry["code"]
		if code == root or code.split("_")[0] == root:
			return code
	return FALLBACK_LOCALE
