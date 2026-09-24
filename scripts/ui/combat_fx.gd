class_name CombatFx
extends RefCounted

## Savaşın hareket eğrileri - saf fonksiyonlar, hiçbir düğüm tutmuyor.
##
## `CombatPanel` slotlarını her `_refresh()`'te yeniden kurduğu için bir
## Tween figüre bağlanamıyor (bkz. panelin kendi notu). Önceki katman bu
## yüzden bir parlamayı/kaymayı yalnızca `bind()` anında basıyordu: efekt
## bir sonraki tazelemeye kadar donuk bir renk olarak kalıyor, sonra tek
## karede kayboluyordu - "az önce oldu" değil, "bir süre öyleydi". Artık
## panel her karede canlı slotlara bu eğrilerden okunan değeri basıyor;
## eğriler burada, çünkü test sahnesiz okuyabilmeli ve aynı sayı iki yerde
## yazılmamalı.

const FLASH_MSEC: int = 500
## Kritik daha uzun parlıyor: oyuncunun "bu farklıydı" demesi için.
const CRIT_FLASH_MSEC: int = 750
const RECOIL_MSEC: int = 260
const FALL_MSEC: int = 300
const RING_MSEC: int = 250
const SHAKE_MSEC: int = 250
const SHAKE_DECAY_SECONDS: float = 0.12
const NUMBER_MSEC: int = 900
const NUMBER_RISE: float = 28.0
## Sayı sonuna kadar tam görünür, son %40'ta sönüyor.
const NUMBER_FADE_FROM: float = 0.6

## Saldıranın hamlesi, figür genişliğine oranla. Kaçırma isabetten derin:
## boşluğa savrulan kılıç bir adım fazla götürür.
const RECOIL_HIT: float = 0.06
const RECOIL_MISS: float = 0.09
const RECOIL_CRIT: float = 0.10

## Sarsıntı (piksel). Yalnızca figürler sarsılır, arayüz asla - okunan
## şey titrememeli.
const SHAKE_HIT: float = 3.0
const SHAKE_CRIT: float = 6.0
const SHAKE_KILLED: float = 8.0

## Düşüş açısı (radyan): figür ayak ucundan yere devriliyor.
const FALL_ANGLE: float = 1.25

## Başlangıçtan bu yana geçen oran; 1 ve üstü "bitti".
static func progress(start_msec: int, duration_msec: int, now_msec: int) -> float:
	if duration_msec <= 0:
		return 1.0
	return maxf(0.0, float(now_msec - start_msec) / float(duration_msec))

## Hamle: ileri gidip geri geliyor, dönüşü gidişinden yumuşak (1-0.35u).
## Başında ve sonunda tam sıfır - kayma yerinden kopmuyor.
static func recoil(u: float) -> float:
	if u <= 0.0 or u >= 1.0:
		return 0.0
	return sin(PI * u) * (1.0 - 0.35 * u)

## Parlama tutulup sönüyor (u²): ilk anda neredeyse tam renk, sonra hızla
## nötre. Doğrusal bir sönüm vuruşun anını bulandırıyordu.
static func flash_at(color: Color, u: float) -> Color:
	if u >= 1.0:
		return ArtPalette.FX_FLASH_NEUTRAL
	return color.lerp(ArtPalette.FX_FLASH_NEUTRAL, clampf(u, 0.0, 1.0) * clampf(u, 0.0, 1.0))

## Sarsıntı: üstel sönen, iki eksende farklı frekanslı bir titreşim.
## Süresi dolunca tam sıfır.
static func shake_at(amplitude: float, elapsed_seconds: float, seed_value: float = 0.0) -> Vector2:
	if amplitude <= 0.0 or elapsed_seconds < 0.0 or elapsed_seconds * 1000.0 >= SHAKE_MSEC:
		return Vector2.ZERO
	var envelope := amplitude * exp(-elapsed_seconds / SHAKE_DECAY_SECONDS)
	return Vector2(
		sin(elapsed_seconds * 83.0 + seed_value) * envelope,
		cos(elapsed_seconds * 71.0 + seed_value * 1.7) * envelope * 0.6
	)

## Düşüş yerçekimi gibi hızlanıyor (u²).
static func fall_at(u: float) -> float:
	var clamped := clampf(u, 0.0, 1.0)
	return clamped * clamped

## Hasar/iyileşme sayısı: hızla yükselip yavaşlıyor, sonunda sönüyor.
static func number_offset(u: float) -> Vector2:
	var clamped := clampf(u, 0.0, 1.0)
	return Vector2(0.0, -NUMBER_RISE * (1.0 - (1.0 - clamped) * (1.0 - clamped)))

static func number_alpha(u: float) -> float:
	if u >= 1.0:
		return 0.0
	if u <= NUMBER_FADE_FROM:
		return 1.0
	return 1.0 - (u - NUMBER_FADE_FROM) / (1.0 - NUMBER_FADE_FROM)

static func recoil_magnitude(kind: String) -> float:
	match kind:
		CombatEncounter.BARK_CRIT: return RECOIL_CRIT
		CombatEncounter.BARK_MISS: return RECOIL_MISS
		CombatEncounter.BARK_HIT: return RECOIL_HIT
	return 0.0

static func shake_amplitude(kind: String) -> float:
	match kind:
		CombatEncounter.BARK_CRIT: return SHAKE_CRIT
		CombatEncounter.BARK_KILLED: return SHAKE_KILLED
		CombatEncounter.BARK_HIT: return SHAKE_HIT
	return 0.0

static func flash_duration(kind: String) -> int:
	return CRIT_FLASH_MSEC if kind == CombatEncounter.BARK_CRIT else FLASH_MSEC

## Durumun halkası/tık rengi. Bilinmeyen tür şeffaf - görünmez ama kırılmaz.
static func status_color(kind: String) -> Color:
	match kind:
		CombatEncounter.BARK_STATUS_BLEED, CombatEncounter.BARK_BLEED_TICK:
			return ArtPalette.FX_BLEED
		CombatEncounter.BARK_STATUS_BLIGHT, CombatEncounter.BARK_BLIGHT_TICK:
			return ArtPalette.FX_BLIGHT
		CombatEncounter.BARK_STATUS_STUN, CombatEncounter.BARK_STUN_SKIP:
			return ArtPalette.FX_STUN
	return Color(0, 0, 0, 0)

static func is_status_application(kind: String) -> bool:
	return (
		kind == CombatEncounter.BARK_STATUS_BLEED
		or kind == CombatEncounter.BARK_STATUS_BLIGHT
		or kind == CombatEncounter.BARK_STATUS_STUN
	)

static func starts_fall(kind: String) -> bool:
	return kind == CombatEncounter.BARK_KILLED or kind == CombatEncounter.BARK_DOWNED
