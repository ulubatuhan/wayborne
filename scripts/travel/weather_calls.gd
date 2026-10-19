class_name WeatherCalls
extends RefCounted

## Havaya karşı küçük kararlar (görev Y-B05): kart değil, günün havasına göre
## bir-iki tek tıklık seçenek. Her biri mevcut bir kolu çevirir: yürüme hızı,
## takat, stres, vagon hasarı ihtimali, tehlike. Açık hava da artık tamamen
## nötr değil (erken yola düşmek). Yavaşlatan seçenekler gönüllü - planlayıcının
## erzak sözü bunlara dayanmaz; hızlandıranlar sözü bozmaz.
## Zar gün + seçenekten tohumlu: yeniden yüklemek çamuru kurutmaz.

const EARLY_START: String = "early_start"
const BEAT_THE_RAIN: String = "beat_the_rain"
const MUD_SHORTCUT: String = "mud_shortcut"
const SLOW_IN_FOG: String = "slow_in_fog"
const LIGHT_IN_FOG: String = "light_in_fog"
const SHELTER: String = "shelter"
const PRESS_ON: String = "press_on"

const OPTIONS: Dictionary = {
	"clear": [EARLY_START],
	"overcast": [BEAT_THE_RAIN],
	"rain": [MUD_SHORTCUT],
	"fog": [SLOW_IN_FOG, LIGHT_IN_FOG],
	"storm": [SHELTER, PRESS_ON],
}
const RATE: Dictionary = {
	EARLY_START: 1.1, BEAT_THE_RAIN: 1.08, MUD_SHORTCUT: 1.15,
	SLOW_IN_FOG: 0.8, LIGHT_IN_FOG: 1.0, SHELTER: 1.0, PRESS_ON: 1.0,
}
## Vagon hasarı ihtimali (seçildiği gün bir kez atılır).
const DAMAGE_CHANCE: Dictionary = {MUD_SHORTCUT: 0.25, PRESS_ON: 0.3}
const EARLY_START_STAMINA: int = -8
const BEAT_THE_RAIN_STRESS: int = 2
const SHELTER_HOURS: float = 6.0
## Siste yavaşlamak o günün tehlike payını düşürür.
const SLOW_FOG_DANGER: float = 0.04
const LABEL_KEYS: Dictionary = {
	EARLY_START: "UI_WX_EARLY_START", BEAT_THE_RAIN: "UI_WX_BEAT_RAIN", MUD_SHORTCUT: "UI_WX_MUD_SHORTCUT",
	SLOW_IN_FOG: "UI_WX_SLOW_FOG", LIGHT_IN_FOG: "UI_WX_LIGHT_FOG", SHELTER: "UI_WX_SHELTER", PRESS_ON: "UI_WX_PRESS_ON",
}

static func options_for(weather: String) -> Array[String]:
	var out: Array[String] = []
	for option in OPTIONS.get(weather, []):
		out.append(String(option))
	return out

static func rate_multiplier(call: String) -> float:
	return float(RATE.get(call, 1.0))

## Bu gün bu seçenek vagonu hırpaladı mı - gün ve seçenekten tohumlu.
static func damages_wagon(call: String, day: int, salt: String) -> bool:
	var chance := float(DAMAGE_CHANCE.get(call, 0.0))
	if chance <= 0.0:
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("weather_call|%s|%s|%d" % [salt, call, day])
	return rng.randf() < chance
