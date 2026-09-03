class_name EventCatalog
extends RefCounted

## Placeholder yol olayları. Tasarım kuralı: her seçenek bir kaynağı
## başka bir kaynakla takas eder, bedava çıkış yoktur. Kilitli seçenekler
## gizlenmez; oyuncu neye hazırlıksız yakalandığını görür.
##
## Şema oturduğunda bu tablo .tres kaynak dosyalarına taşınacak.
##
## Olaylar bir kez kurulup statik önbelleğe alınıyor: EventEngine bunları
## yalnızca okuyor (event_id/koşul/ağırlık), hiçbir yerde mutate etmiyor -
## bir-kez/bekleme takibi EventEngine örneğinin kendi sözlüklerinde,
## event_id string'iyle tutuluyor. Bu yüzden aynı GameEvent nesnelerini
## her sefer ekranı girişinde paylaşmak güvenli ve gereksiz yeniden
## inşayı önlüyor.

static var _road_events: Array[GameEvent] = []

static func get_road_events() -> Array[GameEvent]:
	if not _road_events.is_empty():
		return _road_events

	_road_events.append(_bandit_ambush())
	_road_events.append(_customs_checkpoint())
	_road_events.append(_broken_axle())
	_road_events.append(_storm())
	_road_events.append(_spoiled_provisions())
	_road_events.append(_stowaway())
	_road_events.append(_stowaway_repay())
	_road_events.append(_sick_merchant())
	_road_events.append(_mutiny())
	_road_events.append(_abandoned_wagon())
	_road_events.append(_road_wanderer())
	_road_events.append(_troubled_night())
	_road_events.append(_stress_brawl())
	_road_events.append(_forgotten_cache())
	_road_events.append(_traveling_tinker())
	_road_events.append(_scouted_pass())
	_road_events.append(_culture_nomad_kin())
	_road_events.append(_culture_valley_dispute())
	_road_events.append(_culture_highland_challenge())
	_road_events.append(_culture_port_gossip())
	_road_events.append(_culture_fisher_catch())
	_road_events.append(_roadside_shrine())
	_road_events.append(_wild_animal())
	_road_events.append(_guard_patrol())
	return _road_events

## Yolda partiye katılabilecek biri. Şehirdeki tayfa ekranlarının yol
## karşılığı: kadro yalnızca şehirde değil, yolda da büyüyebilsin diye.
static func _road_wanderer() -> GameEvent:
	var event := _event("evt_road_wanderer", "EVT_WANDERER", 0.9)
	event.cooldown_days = 6
	event.choices = _choices([
		_gated_choice(
			"EVT_WANDERER_OPT_HIRE", "EVT_WANDERER_OPT_HIRE_LOCKED",
			_conditions([
				EventCondition.make("party_slots_free", EventCondition.Op.GREATER_EQUAL, 1),
			]),
			_effects([EventEffect.make(EventEffect.Type.TRIGGER_RECRUIT, 0)])
		),
		_choice("EVT_WANDERER_OPT_FEED", _effects([
			EventEffect.make(EventEffect.Type.PROVISIONS, -3),
			EventEffect.make(EventEffect.Type.MORALE, 5),
		])),
		_choice("EVT_WANDERER_OPT_IGNORE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -2),
		])),
	])
	return event

static func _bandit_ambush() -> GameEvent:
	var event := _event("evt_bandit_ambush", "EVT_AMBUSH", 1.4)
	event.cooldown_days = 2
	# Tehlikeli yollarda ve morali düşük kervanlarda daha sık.
	event.weight_modifiers = _modifiers([
		EventWeightModifier.make(_conditions([
			EventCondition.make("danger", EventCondition.Op.GREATER_EQUAL, 0.5),
		]), 2.0),
	])
	event.choices = _choices([
		_gated_choice(
			"EVT_AMBUSH_OPT_PAY", "EVT_AMBUSH_OPT_PAY_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 120)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -120),
				EventEffect.make(EventEffect.Type.MORALE, -5),
			])
		),
		# Zar atılmıyor: gerçek savaş paneli açılıyor, sonucun etkilerini
		# road_journey.gd uyguluyor (bkz. _on_combat_finished).
		_choice("EVT_AMBUSH_OPT_FIGHT", _effects([
			EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 0),
		])),
		_choice("EVT_AMBUSH_OPT_HAGGLE", _effects([
			EventEffect.make(EventEffect.Type.TRIGGER_HAGGLING, 200),
		])),
	])
	return event

static func _customs_checkpoint() -> GameEvent:
	var event := _event("evt_customs_checkpoint", "EVT_CUSTOMS", 1.2)
	event.choices = _choices([
		_gated_choice(
			"EVT_CUSTOMS_OPT_PAPERS", "EVT_CUSTOMS_OPT_PAPERS_LOCKED",
			_conditions([EventCondition.make("documents", EventCondition.Op.GREATER_EQUAL, 1)]),
			_effects([
				EventEffect.make(EventEffect.Type.REPUTATION, 3),
				EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
			])
		),
		_gated_choice(
			"EVT_CUSTOMS_OPT_BRIBE", "EVT_CUSTOMS_OPT_BRIBE_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 80)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -80),
				EventEffect.make(EventEffect.Type.REPUTATION, -2),
			])
		),
		_choice_with_outcomes("EVT_CUSTOMS_OPT_RUN", _outcomes([
			EventOutcome.make("EVT_CUSTOMS_RUN_ESCAPE", _effects([
				EventEffect.make(EventEffect.Type.DANGER, 15),
				EventEffect.make(EventEffect.Type.MORALE, 5),
			]), 1.0),
			EventOutcome.make("EVT_CUSTOMS_RUN_CAUGHT", _effects([
				EventEffect.make(EventEffect.Type.DOCUMENT_LOSE, 2),
				EventEffect.make(EventEffect.Type.GOLD, -150),
				EventEffect.make(EventEffect.Type.REPUTATION, -8),
			]), 1.4),
		])),
	])
	return event

static func _broken_axle() -> GameEvent:
	var event := _event("evt_broken_axle", "EVT_AXLE", 1.0)
	event.conditions = _conditions([
		EventCondition.make("wagons", EventCondition.Op.GREATER_EQUAL, 2),
	])
	event.choices = _choices([
		_gated_choice(
			"EVT_AXLE_OPT_REPAIR", "EVT_AXLE_OPT_REPAIR_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 60)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -60),
				EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
			])
		),
		_choice("EVT_AXLE_OPT_PUSH_ON", _effects([
			EventEffect.make(EventEffect.Type.WAGON_DAMAGE, 1),
			EventEffect.make(EventEffect.Type.MORALE, -8),
		])),
		_choice("EVT_AXLE_OPT_DUMP", _effects([
			EventEffect.make(EventEffect.Type.ITEM_REMOVE, 3, "test_cloth"),
			EventEffect.make(EventEffect.Type.MORALE, -4),
		])),
	])
	return event

static func _storm() -> GameEvent:
	var event := _event("evt_storm", "EVT_STORM", 1.1)
	event.cooldown_days = 3
	event.choices = _choices([
		_choice("EVT_STORM_OPT_SHELTER", _effects([
			EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
			EventEffect.make(EventEffect.Type.PROVISIONS, -3),
		])),
		_choice_with_outcomes("EVT_STORM_OPT_PRESS_ON", _outcomes([
			EventOutcome.make("EVT_STORM_PRESS_OK", _effects([
				EventEffect.make(EventEffect.Type.MORALE, -5),
			]), 1.0),
			EventOutcome.make("EVT_STORM_PRESS_BAD", _effects([
				EventEffect.make(EventEffect.Type.WAGON_DAMAGE, 1),
				EventEffect.make(EventEffect.Type.PROVISIONS, -4),
				EventEffect.make(EventEffect.Type.MORALE, -12),
			]), 1.0),
		])),
	])
	return event

static func _spoiled_provisions() -> GameEvent:
	var event := _event("evt_spoiled_provisions", "EVT_SPOILED", 0.9)
	event.conditions = _conditions([
		EventCondition.make("provisions", EventCondition.Op.GREATER_EQUAL, 5),
	])
	event.immediate_effects = _effects([
		EventEffect.make(EventEffect.Type.PROVISIONS, -4),
	])
	event.choices = _choices([
		_choice("EVT_SPOILED_OPT_SHARE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -5),
		])),
		_choice("EVT_SPOILED_OPT_RATION", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -15),
			EventEffect.make(EventEffect.Type.REPUTATION, -3),
			EventEffect.make(EventEffect.Type.PROVISIONS, 2),
		])),
	])
	return event

static func _stowaway() -> GameEvent:
	var event := _event("evt_stowaway", "EVT_STOWAWAY", 0.7)
	event.fire_only_once = true
	event.choices = _choices([
		_choice("EVT_STOWAWAY_OPT_SHELTER", _effects([
			EventEffect.make(EventEffect.Type.PROVISIONS, -2),
			EventEffect.make(EventEffect.Type.MORALE, 4),
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "stowaway_helped"),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_stowaway_repay"),
		])),
		_choice("EVT_STOWAWAY_OPT_TURN_IN", _effects([
			EventEffect.make(EventEffect.Type.GOLD, 30),
			EventEffect.make(EventEffect.Type.REPUTATION, -3),
			EventEffect.make(EventEffect.Type.MORALE, -6),
		])),
	])
	return event

static func _stowaway_repay() -> GameEvent:
	var event := _event("evt_stowaway_repay", "EVT_STOWAWAY_REPAY", 3.0)
	event.triggered_only = true
	event.fire_only_once = true
	event.category = GameEvent.Category.CHAIN
	event.conditions = _conditions([
		EventCondition.make("stowaway_helped", EventCondition.Op.HAS_FLAG),
	])
	event.choices = _choices([
		_choice("EVT_STOWAWAY_REPAY_OPT_ACCEPT", _effects([
			EventEffect.make(EventEffect.Type.GOLD, 200),
			EventEffect.make(EventEffect.Type.MORALE, 8),
		])),
		_choice("EVT_STOWAWAY_REPAY_OPT_REFUSE", _effects([
			EventEffect.make(EventEffect.Type.REPUTATION, 8),
			EventEffect.make(EventEffect.Type.MORALE, 12),
		])),
	])
	return event

static func _sick_merchant() -> GameEvent:
	var event := _event("evt_sick_merchant", "EVT_SICK", 0.9)
	event.conditions = _conditions([
		EventCondition.make("merchants", EventCondition.Op.GREATER_EQUAL, 1),
	])
	event.choices = _choices([
		_gated_choice(
			"EVT_SICK_OPT_TREAT", "EVT_SICK_OPT_TREAT_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 90)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -90),
				EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
				EventEffect.make(EventEffect.Type.MORALE, 10),
				EventEffect.make(EventEffect.Type.REPUTATION, 5),
			])
		),
		_choice("EVT_SICK_OPT_LEAVE", _effects([
			EventEffect.make(EventEffect.Type.MERCHANT_LEAVE, 1),
			EventEffect.make(EventEffect.Type.MORALE, -18),
			EventEffect.make(EventEffect.Type.REPUTATION, -6),
		])),
	])
	return event

static func _mutiny() -> GameEvent:
	var event := _event("evt_mutiny", "EVT_MUTINY", 2.0)
	event.conditions = _conditions([
		EventCondition.make("morale", EventCondition.Op.LESS_EQUAL, 25),
		EventCondition.make("merchants", EventCondition.Op.GREATER_EQUAL, 1),
	])
	event.cooldown_days = 4
	event.choices = _choices([
		_gated_choice(
			"EVT_MUTINY_OPT_PAY", "EVT_MUTINY_OPT_PAY_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 100)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -100),
				EventEffect.make(EventEffect.Type.MORALE, 30),
			])
		),
		_choice_with_outcomes("EVT_MUTINY_OPT_HARSH", _outcomes([
			EventOutcome.make("EVT_MUTINY_HARSH_OBEY", _effects([
				EventEffect.make(EventEffect.Type.MORALE, 10),
			]), 1.0),
			EventOutcome.make("EVT_MUTINY_HARSH_DESERT", _effects([
				EventEffect.make(EventEffect.Type.MERCHANT_LEAVE, 2),
				EventEffect.make(EventEffect.Type.MORALE, -10),
				EventEffect.make(EventEffect.Type.REPUTATION, -5),
			]), 1.2),
		])),
	])
	return event

static func _abandoned_wagon() -> GameEvent:
	var event := _event("evt_abandoned_wagon", "EVT_ABANDONED", 0.8)
	event.choices = _choices([
		_choice("EVT_ABANDONED_OPT_LOOT", _effects([
			EventEffect.make(EventEffect.Type.ITEM_ADD, 3, "test_furs"),
			EventEffect.make(EventEffect.Type.DANGER, 10),
			EventEffect.make(EventEffect.Type.MORALE, -3),
		])),
		_choice("EVT_ABANDONED_OPT_LEAVE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 3),
		])),
	])
	return event

## GRANT_TRAIT'in ilk canlı kullanımı: kötü bir gece kervanın liderine
## kalıcı (ama taze - bkz. CharacterData.TRAIT_FRESH_WINDOW_DAYS) bir huy
## bırakabilir.
static func _troubled_night() -> GameEvent:
	var event := _event("evt_troubled_night", "EVT_TROUBLED_NIGHT", 0.8)
	event.cooldown_days = 5
	event.choices = _choices([
		_choice("EVT_TROUBLED_NIGHT_OPT_WATCH", _effects([
			EventEffect.make(EventEffect.Type.PROVISIONS, -2),
			EventEffect.make(EventEffect.Type.MORALE, -3),
			EventEffect.make(EventEffect.Type.STRESS, 5),
		])),
		_choice_with_outcomes("EVT_TROUBLED_NIGHT_OPT_SLEEP", _outcomes([
			EventOutcome.make("EVT_TROUBLED_NIGHT_SLEEP_GOOD", _effects([
				EventEffect.make(EventEffect.Type.MORALE, 6),
				EventEffect.make(EventEffect.Type.STRESS, -8),
			]), 1.4),
			EventOutcome.make("EVT_TROUBLED_NIGHT_SLEEP_BAD", _effects([
				EventEffect.make(EventEffect.Type.MORALE, -10),
				EventEffect.make(EventEffect.Type.STRESS, 12),
				EventEffect.make(EventEffect.Type.GRANT_TRAIT, 0, TraitCatalog.CLUMSY_FOOT),
			]), 1.0),
		])),
	])
	return event

## Yüksek parti stresi kendi agresif olayını açıyor - DD'deki gibi,
## tükenmiş bir kadro birbirine düşebilir. `stress` bağlamı
## GameSession.build_event_context()'ten geliyor.
static func _stress_brawl() -> GameEvent:
	var event := _event("evt_stress_brawl", "EVT_BRAWL", 1.3)
	event.conditions = _conditions([
		EventCondition.make("stress", EventCondition.Op.GREATER_EQUAL, 70),
	])
	event.cooldown_days = 4
	event.choices = _choices([
		_choice("EVT_BRAWL_OPT_INTERVENE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -5),
			EventEffect.make(EventEffect.Type.STRESS, -15),
		])),
		_choice_with_outcomes("EVT_BRAWL_OPT_IGNORE", _outcomes([
			EventOutcome.make("EVT_BRAWL_IGNORE_FIZZLE", _effects([
				EventEffect.make(EventEffect.Type.STRESS, -5),
			]), 1.0),
			EventOutcome.make("EVT_BRAWL_IGNORE_ESCALATE", _effects([
				EventEffect.make(EventEffect.Type.MORALE, -12),
				EventEffect.make(EventEffect.Type.STRESS, 10),
				EventEffect.make(EventEffect.Type.GOLD, -30),
			]), 1.3),
		])),
	])
	return event

## Yol kenarında gömülü bir stok - kazmak vakit ve erzak yer ama bazen
## bir tılsımla ödüllenir; sonuç tablosu Terkedilmiş Vagon'un aksine
## kazanç garantili değil (bkz. EventOutcome ağırlıklı seçim).
static func _forgotten_cache() -> GameEvent:
	var event := _event("evt_forgotten_cache", "EVT_CACHE", 0.7)
	event.cooldown_days = 5
	event.choices = _choices([
		_choice_with_outcomes("EVT_CACHE_OPT_DIG", _outcomes([
			EventOutcome.make("EVT_CACHE_DIG_RING", _effects([
				EventEffect.make(EventEffect.Type.GRANT_EQUIPMENT, 0, EquipmentCatalog.RING_MARKSMAN),
			]), 1.0),
			EventOutcome.make("EVT_CACHE_DIG_AMULET", _effects([
				EventEffect.make(EventEffect.Type.GRANT_EQUIPMENT, 0, EquipmentCatalog.AMULET_WARD),
			]), 1.0),
			EventOutcome.make("EVT_CACHE_DIG_NOTHING", _effects([
				EventEffect.make(EventEffect.Type.PROVISIONS, -2),
				EventEffect.make(EventEffect.Type.MORALE, -3),
			]), 1.2),
		])),
		_choice("EVT_CACHE_OPT_LEAVE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 2),
		])),
	])
	return event

## Silah/Zırh'ı yalnızca Kervan Avlusu satmaz - yolda geçen bir gezgin
## demirci de bir tanesini elden çıkarabilir, biraz daha pahalıya.
static func _traveling_tinker() -> GameEvent:
	var event := _event("evt_traveling_tinker", "EVT_TINKER", 0.7)
	event.cooldown_days = 6
	event.choices = _choices([
		_gated_choice(
			"EVT_TINKER_OPT_BUY", "EVT_TINKER_OPT_BUY_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 120)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -120),
				EventEffect.make(EventEffect.Type.GRANT_EQUIPMENT, 0, EquipmentCatalog.WEAPON_TIER_1),
			])
		),
		_choice("EVT_TINKER_OPT_IGNORE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 1),
		])),
	])
	return event

## İzci varsa (bkz. DutyCatalog.IZCI, caravan_planner.gd) kervan zaten
## öndeki kestirmeyi biliyor - burada da işe yarıyor, ücretsiz bir gün
## kazandırıyor ama tehlikeyi biraz artırıyor. İzci yoksa seçenek kilitli.
static func _scouted_pass() -> GameEvent:
	var event := _event("evt_scouted_pass", "EVT_SCOUT_PASS", 0.9)
	event.conditions = _conditions([
		EventCondition.make("days_remaining", EventCondition.Op.GREATER_EQUAL, 2),
	])
	event.cooldown_days = 4
	event.choices = _choices([
		_gated_choice(
			"EVT_SCOUT_OPT_SHORTCUT", "EVT_SCOUT_OPT_SHORTCUT_LOCKED",
			_conditions([EventCondition.make("has_izci", EventCondition.Op.GREATER_EQUAL, 1)]),
			_effects([
				EventEffect.make(EventEffect.Type.TRAVEL_DAYS, -1),
				EventEffect.make(EventEffect.Type.DANGER, 5),
			])
		),
		_choice("EVT_SCOUT_OPT_MAIN_ROAD", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 2),
		])),
	])
	return event

## Göçebe kültüründen bir oyuncu bozkırda akraba bir boyla karşılaşır -
## kültürün kendi perki (erzak tüketimi) dışında ilk kez olay tarafında
## da bir sahnesi oluyor (bkz. CultureCatalog).
static func _culture_nomad_kin() -> GameEvent:
	var event := _event("evt_culture_nomad_kin", "EVT_NOMAD_KIN", 0.8)
	event.conditions = _conditions([
		EventCondition.make("is_nomad_culture", EventCondition.Op.GREATER_EQUAL, 1),
	])
	event.cooldown_days = 8
	event.choices = _choices([
		_choice("EVT_NOMAD_KIN_OPT_TRADE", _effects([
			EventEffect.make(EventEffect.Type.GOLD, -20),
			EventEffect.make(EventEffect.Type.PROVISIONS, 4),
		])),
		_choice("EVT_NOMAD_KIN_OPT_GREET", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 4),
			EventEffect.make(EventEffect.Type.REPUTATION, 1),
		])),
	])
	return event

static func _culture_valley_dispute() -> GameEvent:
	var event := _event("evt_culture_valley_dispute", "EVT_VALLEY_DISPUTE", 0.8)
	event.conditions = _conditions([
		EventCondition.make("is_valley_culture", EventCondition.Op.GREATER_EQUAL, 1),
		EventCondition.make("merchants", EventCondition.Op.GREATER_EQUAL, 1),
	])
	event.cooldown_days = 8
	event.choices = _choices([
		_choice("EVT_VALLEY_DISPUTE_OPT_MEDIATE", _effects([
			EventEffect.make(EventEffect.Type.REPUTATION, 5),
			EventEffect.make(EventEffect.Type.GOLD, 30),
		])),
		_choice("EVT_VALLEY_DISPUTE_OPT_IGNORE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 1),
		])),
	])
	return event

static func _culture_highland_challenge() -> GameEvent:
	var event := _event("evt_culture_highland_challenge", "EVT_HIGHLAND_CHALLENGE", 0.8)
	event.conditions = _conditions([
		EventCondition.make("is_highland_culture", EventCondition.Op.GREATER_EQUAL, 1),
	])
	event.cooldown_days = 8
	event.choices = _choices([
		_choice_with_outcomes("EVT_HIGHLAND_CHALLENGE_OPT_ACCEPT", _outcomes([
			EventOutcome.make("EVT_HIGHLAND_CHALLENGE_WIN", _effects([
				EventEffect.make(EventEffect.Type.MORALE, 8),
				EventEffect.make(EventEffect.Type.REPUTATION, 3),
			]), 1.4),
			EventOutcome.make("EVT_HIGHLAND_CHALLENGE_LOSE", _effects([
				EventEffect.make(EventEffect.Type.STRESS, 5),
				EventEffect.make(EventEffect.Type.MORALE, -3),
			]), 1.0),
		])),
		_choice("EVT_HIGHLAND_CHALLENGE_OPT_DECLINE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -2),
		])),
	])
	return event

static func _culture_port_gossip() -> GameEvent:
	var event := _event("evt_culture_port_gossip", "EVT_PORT_GOSSIP", 0.8)
	event.conditions = _conditions([
		EventCondition.make("is_port_culture", EventCondition.Op.GREATER_EQUAL, 1),
	])
	event.cooldown_days = 8
	event.choices = _choices([
		_choice("EVT_PORT_GOSSIP_OPT_LISTEN", _effects([
			EventEffect.make(EventEffect.Type.GOLD, 20),
			EventEffect.make(EventEffect.Type.REPUTATION, 3),
		])),
		_choice("EVT_PORT_GOSSIP_OPT_IGNORE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 1),
		])),
	])
	return event

static func _culture_fisher_catch() -> GameEvent:
	var event := _event("evt_culture_fisher_catch", "EVT_FISHER_CATCH", 0.8)
	event.conditions = _conditions([
		EventCondition.make("is_fisher_culture", EventCondition.Op.GREATER_EQUAL, 1),
	])
	event.cooldown_days = 8
	event.choices = _choices([
		_choice("EVT_FISHER_CATCH_OPT_GATHER", _effects([
			EventEffect.make(EventEffect.Type.PROVISIONS, 5),
			EventEffect.make(EventEffect.Type.MORALE, 2),
		])),
		_choice("EVT_FISHER_CATCH_OPT_SKIP", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -1),
		])),
	])
	return event

## DD tarzı bir "curio": kültürden bağımsız, dua etmek güvenli bir stres
## azaltıcı, adakları almaksa kumarlı bir kazanç.
static func _roadside_shrine() -> GameEvent:
	var event := _event("evt_roadside_shrine", "EVT_SHRINE", 0.8)
	event.cooldown_days = 6
	event.choices = _choices([
		_choice("EVT_SHRINE_OPT_PRAY", _effects([
			EventEffect.make(EventEffect.Type.STRESS, -10),
			EventEffect.make(EventEffect.Type.MORALE, 3),
		])),
		_choice_with_outcomes("EVT_SHRINE_OPT_TAKE", _outcomes([
			EventOutcome.make("EVT_SHRINE_TAKE_GOOD", _effects([
				EventEffect.make(EventEffect.Type.GOLD, 50),
			]), 1.0),
			EventOutcome.make("EVT_SHRINE_TAKE_BAD", _effects([
				EventEffect.make(EventEffect.Type.STRESS, 15),
				EventEffect.make(EventEffect.Type.REPUTATION, -4),
			]), 1.3),
		])),
	])
	return event

## Doğada karşılaşılan bir tehdit - haydut pususundan ayrı bir tetikleyici,
## kadrosu EnemyCatalog.build_wildlife_squad'tan gelir (bkz. Faz 8 PR-B).
## Kaçmak/beslemek savaşsız atlatır ama bedelsiz değil - besleme erzak
## yer, kaçış tehlikeyi artırır (ürkütülen hayvanlar iz bırakır).
static func _wild_animal() -> GameEvent:
	var event := _event("evt_wild_animal", "EVT_WILD", 1.0)
	event.cooldown_days = 3
	event.choices = _choices([
		_choice("EVT_WILD_OPT_FIGHT", _effects([
			EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 0, "wildlife"),
		])),
		_choice("EVT_WILD_OPT_FEED", _effects([
			EventEffect.make(EventEffect.Type.PROVISIONS, -3),
			EventEffect.make(EventEffect.Type.MORALE, 2),
		])),
		_choice("EVT_WILD_OPT_FLEE", _effects([
			EventEffect.make(EventEffect.Type.DANGER, 8),
			EventEffect.make(EventEffect.Type.MORALE, -3),
		])),
	])
	return event

## Düşük itibarlı bir kervan şehir muhafızlarının dikkatini çekiyor - kadrosu
## EnemyCatalog.build_guard_squad'tan gelir. Direnişte zafer bile itibarı
## yükseltmez, kırar (bkz. road_journey.gd GUARD_VICTORY_REPUTATION) -
## kanunla çatışmanın haydutla çatışmaktan farkı burada.
static func _guard_patrol() -> GameEvent:
	var event := _event("evt_guard_patrol", "EVT_GUARD_PATROL", 0.9)
	event.conditions = _conditions([
		EventCondition.make("reputation", EventCondition.Op.LESS_EQUAL, 10),
	])
	event.cooldown_days = 5
	event.choices = _choices([
		_gated_choice(
			"EVT_GUARD_PATROL_OPT_BRIBE", "EVT_GUARD_PATROL_OPT_BRIBE_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 100)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -100),
				EventEffect.make(EventEffect.Type.REPUTATION, -2),
			])
		),
		_choice_with_outcomes("EVT_GUARD_PATROL_OPT_RUN", _outcomes([
			EventOutcome.make("EVT_GUARD_PATROL_RUN_ESCAPE", _effects([
				EventEffect.make(EventEffect.Type.DANGER, 10),
			]), 1.0),
			EventOutcome.make("EVT_GUARD_PATROL_RUN_CAUGHT", _effects([
				EventEffect.make(EventEffect.Type.GOLD, -120),
				EventEffect.make(EventEffect.Type.REPUTATION, -10),
				EventEffect.make(EventEffect.Type.DOCUMENT_LOSE, 1),
			]), 1.3),
		])),
		_choice("EVT_GUARD_PATROL_OPT_RESIST", _effects([
			EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 0, "guard"),
		])),
	])
	return event

static func _event(event_id: String, key_prefix: String, base_weight: float) -> GameEvent:
	var event := GameEvent.new()
	event.event_id = event_id
	event.title_key = "%s_TITLE" % key_prefix
	event.text_key = "%s_TEXT" % key_prefix
	event.base_weight = base_weight
	return event

static func _choice(text_key: String, effects: Array[EventEffect]) -> EventChoice:
	return EventChoice.make(text_key, effects)

static func _gated_choice(
	text_key: String,
	locked_key: String,
	requirements: Array[EventCondition],
	effects: Array[EventEffect]
) -> EventChoice:
	var choice := EventChoice.make(text_key, effects)
	choice.requirements = requirements
	choice.unavailable_text_key = locked_key
	return choice

static func _choice_with_outcomes(text_key: String, outcomes: Array[EventOutcome]) -> EventChoice:
	var choice := EventChoice.new()
	choice.text_key = text_key
	choice.outcomes = outcomes
	return choice

static func _conditions(items: Array) -> Array[EventCondition]:
	var result: Array[EventCondition] = []
	for item in items:
		result.append(item)
	return result

static func _effects(items: Array) -> Array[EventEffect]:
	var result: Array[EventEffect] = []
	for item in items:
		result.append(item)
	return result

static func _outcomes(items: Array) -> Array[EventOutcome]:
	var result: Array[EventOutcome] = []
	for item in items:
		result.append(item)
	return result

static func _choices(items: Array) -> Array[EventChoice]:
	var result: Array[EventChoice] = []
	for item in items:
		result.append(item)
	return result

static func _modifiers(items: Array) -> Array[EventWeightModifier]:
	var result: Array[EventWeightModifier] = []
	for item in items:
		result.append(item)
	return result
