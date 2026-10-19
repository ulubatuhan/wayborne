class_name EventQuality
extends RefCounted

## Kart kalite listesi (görev Y-E01): yeni kartlar bölge bölge 10'luk partiler
## hâlinde yazılır ve her biri bu listeden geçer. Liste kartın verisinden
## okunur, yazarın beyanından değil:
## - en az iki seçenek (tek seçenek karar değil);
## - cazip ama riskli bir seçenek: zarlı (beceri kontrolü) ya da birden çok
##   ağırlıklı sonucu olan bir seçenek (bkz. Event Engine Rules);
## - bir beceri kontrolü (kimin attığı önceden söylenir);
## - kaynak takası tek başına kart sayılmaz: en az bir seçenek altın/erzak/
##   moral/stres/itibar dışında bir şeye dokunmalı (bayrak, zincir, savaş,
##   kişi, yol, pazar...).
## Yalnızca tetiklenen zincir kartları (triggered_only) bir öncekinin devamı
## olduğu için "tek seçenek" kuralından muaf.

const PROBLEM_FEW_CHOICES: String = "few_choices"
const PROBLEM_NO_RISK: String = "no_risky_choice"
const PROBLEM_NO_CHECK: String = "no_skill_check"
const PROBLEM_TRADE_ONLY: String = "resource_trade_only"

const TARGET_DRAWABLE: int = 120

const RESOURCE_TYPES: Array[int] = [
	EventEffect.Type.GOLD, EventEffect.Type.PROVISIONS, EventEffect.Type.MORALE,
	EventEffect.Type.STRESS, EventEffect.Type.REPUTATION,
]

static func problems(event: GameEvent) -> Array[String]:
	var out: Array[String] = []
	if event.choices.size() < 2 and not event.triggered_only:
		out.append(PROBLEM_FEW_CHOICES)
	var risky := false
	var checked := false
	var beyond_resources := false
	for choice in event.choices:
		if choice.check != null:
			checked = true
			risky = true
		if choice.outcomes.size() >= 2:
			risky = true
		for effect in _all_effects(choice):
			if not RESOURCE_TYPES.has(int(effect.type)):
				beyond_resources = true
	if not risky:
		out.append(PROBLEM_NO_RISK)
	if not checked:
		out.append(PROBLEM_NO_CHECK)
	if not beyond_resources:
		out.append(PROBLEM_TRADE_ONLY)
	return out

static func passes(event: GameEvent) -> bool:
	return problems(event).is_empty()

## Çekilebilir kart: yolda zarla gelebilen (zincir devamı olmayan).
static func drawable_count(events: Array[GameEvent]) -> int:
	var count := 0
	for event in events:
		if not event.triggered_only:
			count += 1
	return count

static func _all_effects(choice: EventChoice) -> Array[EventEffect]:
	var out: Array[EventEffect] = []
	out.append_array(choice.effects)
	for outcome in choice.outcomes:
		out.append_array(outcome.effects)
	return out
