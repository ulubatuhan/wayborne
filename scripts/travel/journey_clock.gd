class_name JourneyClock
extends RefCounted

## Sefer boyunca akan zaman. Sahne ağacına bağlı değil: yol ekranı her
## karede delta ile besler, arka plan ve olaylar buradan okur, test doğrudan
## örnekler.
##
## Oyun eskiden "Gün İlerlet" tuşuyla ilerliyordu; bu sınıf günü sürekli
## akan bir saate çeviriyor. Gün *mekaniği* değişmiyor - erzak tüketimi,
## kontrat süresi ve olay çekimi hâlâ gün başına işliyor. Saat yalnızca
## "kaç tam gün geçti" sorusunu cevaplıyor (bkz. take_elapsed_days), böylece
## mevcut günlük akış olduğu gibi korunuyor.

## Bir oyun günü 1x hızda kaç gerçek saniye sürer. Sefer birkaç dakikada
## bitsin ama gün geçişi de hissedilsin diye seçildi.
const REAL_SECONDS_PER_DAY: float = 45.0
const HOURS_PER_DAY: float = 24.0

## Oyuncunun seçebileceği hız çarpanları (bkz. yol ekranındaki tuşlar).
const SPEEDS: Array[float] = [1.0, 1.5, 3.0]
const DEFAULT_SPEED_INDEX: int = 0

## Sefer sabahın erken saatinde başlar - ilk gün baştan gece olmasın diye.
const START_HOUR: float = 6.0

enum Phase { DAWN, MORNING, NOON, AFTERNOON, EVENING, NIGHT }

## Evre sınırları: [başlangıç saati, evre]. Gece gün dönümünü aştığı için
## (20:00-05:00) get_phase sırayla değil aralık kontrolüyle çözer.
const PHASE_BOUNDS: Array = [
	[5.0, Phase.DAWN],
	[8.0, Phase.MORNING],
	[11.0, Phase.NOON],
	[14.0, Phase.AFTERNOON],
	[17.0, Phase.EVENING],
	[20.0, Phase.NIGHT],
]

## Seferin başından beri geçen toplam saat. Gün sayısı bundan türetilir -
## iki ayrı sayaç tutmak ikisinin ayrışması demekti.
var total_hours: float = START_HOUR

var speed_index: int = DEFAULT_SPEED_INDEX

## take_elapsed_days'in en son hangi güne kadar rapor verdiği.
var _days_reported: int = 0

func get_speed() -> float:
	return SPEEDS[clampi(speed_index, 0, SPEEDS.size() - 1)]

func set_speed_index(index: int) -> void:
	speed_index = clampi(index, 0, SPEEDS.size() - 1)

func cycle_speed() -> void:
	speed_index = (speed_index + 1) % SPEEDS.size()

## Gerçek zamanı oyun saatine çevirip ilerletir. Yol ekranı bunu _process'ten
## çağırır; delta gerçek saniye, dönüş o çağrıda eklenen oyun saati.
func advance(real_delta: float, speed_scale: float = -1.0) -> float:
	if real_delta <= 0.0:
		return 0.0
	var speed := get_speed() if speed_scale < 0.0 else speed_scale
	var hours := (real_delta / REAL_SECONDS_PER_DAY) * HOURS_PER_DAY * speed
	total_hours += hours
	return hours

## Bir olay/çarpışma/kamp zamandan yer. Saatin akışını beklemeden doğrudan
## ilerletir - "olay arka planda zamandan yesin" kuralı bu (bkz. yol ekranı).
func consume_hours(hours: float) -> void:
	if hours > 0.0:
		total_hours += hours

## Saatin başından beri tamamlanan ama henüz raporlanmamış gün sayısı.
## Çağıran her gün için günlük mekaniği (erzak, kontrat, olay) bir kez
## işletir; art arda çağrıda aynı gün iki kez dönmez. Bir karede birden
## fazla gün geçebilir (3x hızda ya da uzun bir olaydan sonra), o yüzden
## sayı dönüyor - bool değil.
## Gün sınırı gece yarısı değil START_HOUR (şafak): kervanın günü ilk
## ışıkla başlar. Gece yarısına göre sayarsak günlük mekanik - ve onunla
## birlikte o günün olayı - hep 00:00'da işlerdi, yani oyuncu hiçbir olayı
## gündüz yaşamazdı. Bu kaydırmayla günler sabah dönüyor.
func take_elapsed_days() -> int:
	var completed := _completed_days()
	var pending := completed - _days_reported
	if pending <= 0:
		return 0
	_days_reported = completed
	return pending


func _completed_days() -> int:
	return int(floor((total_hours - START_HOUR) / HOURS_PER_DAY))

## Gün içindeki saat, 0.0-24.0.
func get_hour_of_day() -> float:
	return fposmod(total_hours, HOURS_PER_DAY)

func get_phase() -> Phase:
	var hour := get_hour_of_day()
	# Gece gün dönümünü aştığı için önce onu eliyoruz.
	if hour < PHASE_BOUNDS[0][0] or hour >= PHASE_BOUNDS[PHASE_BOUNDS.size() - 1][0]:
		return Phase.NIGHT
	var result: Phase = Phase.NIGHT
	for bound in PHASE_BOUNDS:
		if hour >= float(bound[0]):
			result = bound[1]
	return result

## Evrenin içinde ne kadar ilerlediğimiz (0.0-1.0) - arka plan renklerini
## evreler arasında yumuşak geçirmek için (bkz. gündüz/gece katmanı).
func get_phase_progress() -> float:
	var hour := get_hour_of_day()
	var start := 0.0
	var end := 0.0
	if hour < PHASE_BOUNDS[0][0]:
		# Gece yarısından şafağa: bir önceki günün 20:00'sinden sayılır.
		start = PHASE_BOUNDS[PHASE_BOUNDS.size() - 1][0] - HOURS_PER_DAY
		end = PHASE_BOUNDS[0][0]
	elif hour >= PHASE_BOUNDS[PHASE_BOUNDS.size() - 1][0]:
		start = PHASE_BOUNDS[PHASE_BOUNDS.size() - 1][0]
		end = PHASE_BOUNDS[0][0] + HOURS_PER_DAY
	else:
		for index in range(PHASE_BOUNDS.size() - 1):
			if hour >= float(PHASE_BOUNDS[index][0]) and hour < float(PHASE_BOUNDS[index + 1][0]):
				start = PHASE_BOUNDS[index][0]
				end = PHASE_BOUNDS[index + 1][0]
				break
	if end <= start:
		return 0.0
	return clampf((hour - start) / (end - start), 0.0, 1.0)

## Kamp yalnızca hava kararmaya başlayınca anlamlı - gündüz durup ateş
## yakmak kervanı yavaşlatmaktan başka işe yaramaz (bkz. yol ekranı).
func is_camp_time() -> bool:
	var phase := get_phase()
	return phase == Phase.EVENING or phase == Phase.NIGHT

## "Gün 3 · 14:30" gibi tek satırlık gösterim.
func get_clock_text() -> String:
	var hour := get_hour_of_day()
	var hours := int(floor(hour))
	var minutes := int(floor((hour - float(hours)) * 60.0))
	return "%02d:%02d" % [hours, minutes]

static func get_phase_key(phase: Phase) -> String:
	match phase:
		Phase.DAWN:
			return "PHASE_DAWN"
		Phase.MORNING:
			return "PHASE_MORNING"
		Phase.NOON:
			return "PHASE_NOON"
		Phase.AFTERNOON:
			return "PHASE_AFTERNOON"
		Phase.EVENING:
			return "PHASE_EVENING"
		_:
			return "PHASE_NIGHT"

func to_dict() -> Dictionary:
	return {
		"total_hours": total_hours,
		"speed_index": speed_index,
		"days_reported": _days_reported,
	}

func load_from_dict(data: Dictionary) -> void:
	total_hours = maxf(0.0, float(data.get("total_hours", START_HOUR)))
	speed_index = clampi(int(data.get("speed_index", DEFAULT_SPEED_INDEX)), 0, SPEEDS.size() - 1)
	_days_reported = maxi(0, int(data.get("days_reported", 0)))
