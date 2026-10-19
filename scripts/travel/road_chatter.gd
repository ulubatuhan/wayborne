class_name RoadChatter
extends RefCounted

## Yolda bir yoldaşın söylediği (görev R0/R1 #1, Y-B01): sahne ağacından
## bağımsız çekirdek (RoadSignals/RoadAttention kalıbı). Kişinin taşıdığına
## göre bir konu seçer; öncelik sırası: en üst şikâyet, stres, geçmiş, görev,
## kültür, ortam, genel. Aynı konu `TOPIC_COOLDOWN_DAYS` gün tekrarlanmaz.
## Anahtarlar tek tek yazılı (Localization Rules: çalışma anında birleştirme yok).

const TOPIC_COOLDOWN_DAYS: int = 3
const RAPPORT_PER_CHAT: int = 1

const GRIEVANCE_LINES: Dictionary = {
	"unfed": ["CHAT_GRIEVANCE_UNFED_1", "CHAT_GRIEVANCE_UNFED_2"],
	"benched": ["CHAT_GRIEVANCE_BENCHED_1", "CHAT_GRIEVANCE_BENCHED_2"],
	"witnessed_death": ["CHAT_GRIEVANCE_DEATH_1", "CHAT_GRIEVANCE_DEATH_2"],
	"passed_over": ["CHAT_GRIEVANCE_PASSED_1", "CHAT_GRIEVANCE_PASSED_2"],
}
const STRESS_LINES: Array[String] = ["CHAT_STRESS_1", "CHAT_STRESS_2", "CHAT_STRESS_3"]
const BACKSTORY_LINES: Dictionary = {
	"debtor": ["CHAT_BACKSTORY_DEBTOR_1", "CHAT_BACKSTORY_DEBTOR_2"],
	"exile": ["CHAT_BACKSTORY_EXILE_1", "CHAT_BACKSTORY_EXILE_2"],
	"widow": ["CHAT_BACKSTORY_WIDOW_1", "CHAT_BACKSTORY_WIDOW_2"],
	"fugitive": ["CHAT_BACKSTORY_FUGITIVE_1", "CHAT_BACKSTORY_FUGITIVE_2"],
	"hungry": ["CHAT_BACKSTORY_HUNGRY_1", "CHAT_BACKSTORY_HUNGRY_2"],
}
const DUTY_LINES: Dictionary = {
	"muhafiz": ["CHAT_DUTY_MUHAFIZ_1"], "izci": ["CHAT_DUTY_IZCI_1"],
	"levazimci": ["CHAT_DUTY_LEVAZIMCI_1"], "arabaci": ["CHAT_DUTY_ARABACI_1"],
	"tellal": ["CHAT_DUTY_TELLAL_1"], "otaci": ["CHAT_DUTY_OTACI_1"],
}
const CULTURE_LINES: Dictionary = {
	"nomad": ["CHAT_CULTURE_NOMAD_1"], "valley": ["CHAT_CULTURE_VALLEY_1"],
	"highland": ["CHAT_CULTURE_HIGHLAND_1"], "port": ["CHAT_CULTURE_PORT_1"],
	"fisher": ["CHAT_CULTURE_FISHER_1"],
}
const WEATHER_LINES: Dictionary = {
	"rain": ["CHAT_WEATHER_RAIN_1"], "storm": ["CHAT_WEATHER_STORM_1"], "fog": ["CHAT_WEATHER_FOG_1"],
}
const NIGHT_LINES: Array[String] = ["CHAT_NIGHT_1", "CHAT_NIGHT_2"]
const GENERIC_LINES: Array[String] = ["CHAT_GENERIC_1", "CHAT_GENERIC_2", "CHAT_GENERIC_3", "CHAT_GENERIC_4"]

## Seçim: {"key", "topic"}; konuşacak bir şey yoksa boş sözlük (olmaz - genel
## her zaman var). `context`: "day", "weather", "night" (bool).
static func pick(character: CharacterData, context: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var day := int(context.get("day", 0))
	var candidates: Array = []
	var grievance := character.get_top_grievance()
	if not grievance.is_empty() and GRIEVANCE_LINES.has(grievance):
		candidates.append(["grievance_" + grievance, GRIEVANCE_LINES[grievance]])
	if character.is_stressed():
		candidates.append(["stress", STRESS_LINES])
	if BACKSTORY_LINES.has(character.backstory_id):
		candidates.append(["backstory", BACKSTORY_LINES[character.backstory_id]])
	if DUTY_LINES.has(character.duty_id):
		candidates.append(["duty", DUTY_LINES[character.duty_id]])
	if CULTURE_LINES.has(character.culture_id):
		candidates.append(["culture", CULTURE_LINES[character.culture_id]])
	var weather := String(context.get("weather", ""))
	if WEATHER_LINES.has(weather):
		candidates.append(["weather", WEATHER_LINES[weather]])
	if bool(context.get("night", false)):
		candidates.append(["night", NIGHT_LINES])
	candidates.append(["generic", GENERIC_LINES])
	for candidate in candidates:
		var topic := String(candidate[0])
		# Genel konu soğumaz: konuşacak bir şey her zaman var.
		if topic != "generic" and topic == character.last_chat_topic \
				and day - character.last_chat_day < TOPIC_COOLDOWN_DAYS:
			continue
		var lines: Array = candidate[1]
		return {"key": String(lines[rng.randi_range(0, lines.size() - 1)]), "topic": topic}
	return {}

## Sohbetin kişide bıraktığı: konu ve gün yazılır, bağ günde en fazla bir artar.
static func apply(character: CharacterData, picked: Dictionary, day: int) -> bool:
	if picked.is_empty():
		return false
	var first_today := character.last_chat_day != day
	character.last_chat_topic = String(picked["topic"])
	character.last_chat_day = day
	if first_today:
		character.rapport = mini(CharacterData.MAX_RAPPORT, character.rapport + RAPPORT_PER_CHAT)
	return first_today
