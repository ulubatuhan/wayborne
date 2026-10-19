extends SceneTree

## Codex'in olay bölümü için katalog dökümü (görev Y-E07). Test değil: canlı
## kataloğu (EventCatalog.get_road_events) okunur metinleriyle birlikte
## docs/codex/events_export.json'a yazar. codex_main.py, elle yazılmış sayfası
## olmayan her olay için bu dökümden bir karar ağacı üretir; böylece Codex
## katalogla eşit kalır ve GDScript'i Python'dan ayrıştırmak gerekmez.
##   godot --headless --script res://tests/export_codex_events.gd

const OUT_PATH: String = "res://docs/codex/events_export.json"

func _initialize() -> void:
	TranslationServer.set_locale("tr")
	var events: Array = []
	for event in EventCatalog.get_road_events():
		events.append(_event(event))
	var file := FileAccess.open(ProjectSettings.globalize_path(OUT_PATH), FileAccess.WRITE)
	if file == null:
		push_error("yazılamadı: %s" % OUT_PATH)
	else:
		file.store_string(JSON.stringify({"events": events}, "  "))
		print("── %d olay yazıldı: %s" % [events.size(), OUT_PATH])
	quit()

func _event(event: GameEvent) -> Dictionary:
	var choices: Array = []
	for choice in event.choices:
		choices.append(_choice(choice))
	return {
		"id": event.event_id,
		"title": tr(event.title_key),
		"text": tr(event.text_key),
		"weight": event.base_weight,
		"cooldown": event.cooldown_days,
		"once": event.fire_only_once,
		"triggered_only": event.triggered_only,
		"conditions": _conditions(event.conditions),
		"modifiers": event.weight_modifiers.size(),
		"immediate": _effects(event.immediate_effects),
		"choices": choices,
	}

func _choice(choice: EventChoice) -> Dictionary:
	var outcomes: Array = []
	for outcome in choice.outcomes:
		outcomes.append({
			"label": tr(outcome.text_key),
			"weight": outcome.weight,
			"conditions": _conditions(outcome.conditions),
			"effects": _effects(outcome.effects),
		})
	var out := {
		"label": tr(choice.text_key),
		"requirements": _conditions(choice.requirements),
		"locked": tr(choice.unavailable_text_key) if not choice.unavailable_text_key.is_empty() else "",
		"effects": _effects(choice.effects),
		"outcomes": outcomes,
	}
	if choice.check != null:
		out["check"] = {
			"stat": CharacterStats.Kind.keys()[choice.check.stat],
			"difficulty": choice.check.difficulty,
		}
	return out

func _conditions(conditions: Array[EventCondition]) -> Array:
	var out: Array = []
	for condition in conditions:
		out.append({"key": condition.key, "op": EventCondition.Op.keys()[condition.op], "value": condition.value})
	return out

func _effects(effects: Array[EventEffect]) -> Array:
	var out: Array = []
	for effect in effects:
		out.append({"type": EventEffect.Type.keys()[effect.type], "amount": effect.amount, "text": effect.text_value})
	return out
