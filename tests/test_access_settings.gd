extends RefCounted

## Erişilebilirlik ve oynanış ayarları (Y-H07): metin boyu kademeleri temanın
## taban boyunu ölçekler, desenli şerit rengi okumadan ayrılır, ayarların
## yazısı var.

const SETTINGS_PATH: String = "res://scripts/autoload/user_settings.gd"

func suite_name() -> String:
	return "AccessSettings"

func run(t) -> void:
	var settings = load(SETTINGS_PATH)
	var scales: Array = settings.TEXT_SCALES
	t.eq(float(scales[settings.DEFAULT_TEXT_SCALE_INDEX]), 1.0, "varsayılan metin boyu bugünkü")
	t.eq(WaybookTheme.text_size_for(1.0), WaybookTheme.FONT_SIZE, "1.0 bugünkü taban boy")
	t.ok(WaybookTheme.text_size_for(1.3) > WaybookTheme.text_size_for(1.0), "büyük kademe büyütür")
	t.ok(WaybookTheme.text_size_for(0.9) < WaybookTheme.text_size_for(1.0), "küçük kademe küçültür")
	t.eq(PatternStripe.segment_count(40.0, false), 1, "desensiz şerit tek parça")
	t.ok(PatternStripe.segment_count(40.0, true) > 1, "desenli şerit kesik kesik")
	for key in ["UI_SETTINGS_TEXT_SIZE", "UI_SETTINGS_PATTERN_STRIPES", "UI_SETTINGS_AUTO_PAUSE", "UI_ROAD_AUTO_PAUSED"]:
		t.ok(String(TranslationServer.translate(key)) != key, "yazılı: %s" % key)
