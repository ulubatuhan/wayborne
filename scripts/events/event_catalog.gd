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

## İsyanın moral eşiği. Burada duruyor çünkü hem olayın koşulu hem denge
## simülatörünün raporu aynı sayıyı okumalı - ayrı tutulduklarında simülatör
## "isyan ulaşılabilir" derken olay ateşlenmeyebilir.
##
## 25'ten 40'a çekildi: ölçüm düzeltilince moralin dibinin ~60, en kötü
## koşuda 35 olduğu görüldü, yani 25 hiçbir zaman görülmüyordu (bkz.
## CLAUDE.md Morale Rules).
const MUTINY_MORALE_THRESHOLD: int = 40

## Kadro içi kavganın stres eşiği. 70'ten 40'a indi: ölçüm, varış stresinin
## ortalama ~25 olduğunu ve 70'in hiçbir zaman görülmediğini gösterdi -
## moraldeki isyan eşiğiyle birebir aynı durum (bkz. CLAUDE.md Stress Rules).
const STRESS_BRAWL_THRESHOLD: int = 40

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
	_road_events.append(_wanderer_revenge())
	_road_events.append(_troubled_night())
	_road_events.append(_stress_brawl())
	_road_events.append(_forgotten_cache())
	_road_events.append(_traveling_tinker())
	_road_events.append(_scouted_pass())
	_road_events.append(_landslide())
	_road_events.append(_road_patrol())
	_road_events.append(_kin_encounter())
	_road_events.append(_culture_valley_dispute())
	_road_events.append(_culture_highland_challenge())
	_road_events.append(_culture_port_gossip())
	_road_events.append(_culture_fisher_catch())
	_road_events.append(_roadside_shrine())
	_road_events.append(_pilgrim_encounter())
	_road_events.append(_pilgrim_blessing())
	_road_events.append(_wild_animal())
	_road_events.append(_guard_patrol())
	_road_events.append(_route_diversion())
	_road_events.append(_forage())
	_road_events.append(_party_theft())
	_road_events.append(_party_investigation())
	_road_events.append(_military_convoy())
	_road_events.append(_refugee_column())
	_road_events.append(_merchant_caravan())
	_road_events.append(_regional_war_news())
	_road_events.append(_plague_outbreak_news())
	_road_events.append(_trade_fair_news())
	_road_events.append(_bandit_tribute_zone_news())
	_road_events.append(_bandit_tribute_toll())
	_road_events.append(_leave_the_wounded())
	_road_events.append(_left_behind_return())
	_road_events.append(_profiteer_recognized())
	_road_events.append(_frontier_outpost())
	_road_events.append(_mine_collapse())
	_road_events.append(_failing_bridge())
	_road_events.append(_grave_on_the_road())
	_road_events.append(_grave_keeper())
	_road_events.append(_grave_offering())
	_road_events.append(_deserter_plea())
	_road_events.append(_deserter_search())
	_road_events.append(_deserter_debt())
	_road_events.append(_carcass_on_road())
	_road_events.append(_wolves_follow())
	_road_events.append(_wolf_pack())
	_road_events.append(_creditor_rider())
	_road_events.append(_bailiffs_at_camp())
	return _road_events

## `event_id` ile tek bir olayı bulur - doğrudan sunulan (havuzdan
## çekilmeyen) olaylar için, bkz. `evt_route_diversion`'ın road_journey.gd
## `_apply_replan()`'dan çağrılması.
static func get_event(event_id: String) -> GameEvent:
	for event in get_road_events():
		if event.event_id == event_id:
			return event
	return null

## Yolda partiye katılabilecek biri. Şehirdeki tayfa ekranlarının yol
## karşılığı: kadro yalnızca şehirde değil, yolda da büyüyebilsin diye.
static func _road_wanderer() -> GameEvent:
	var event := _event("evt_road_wanderer", "EVT_WANDERER", 0.9)
	event.cooldown_days = 6
	# Yolcunun kim olduğu peşinen bilinmiyor: mizacı burada yuvarlanıyor,
	# seçeneklerin sonuçları o mizaca dallanıyor. Sezgisi kuvvetli bir parti
	# üyesi varsa ROLL_ENCOUNTER bir ipucu da bırakır.
	event.immediate_effects = _effects([
		EventEffect.make(EventEffect.Type.ROLL_ENCOUNTER, 0, "wanderer"),
	])
	event.choices = _choices([
		# Kervana almak: sadık biri kazanç, hırsız ileride soyar.
		_gated_choice(
			"EVT_WANDERER_OPT_HIRE", "EVT_WANDERER_OPT_HIRE_LOCKED",
			_conditions([
				EventCondition.make("party_slots_free", EventCondition.Op.GREATER_EQUAL, 1),
			]),
			_effects([EventEffect.make(EventEffect.Type.TRIGGER_RECRUIT, 0)])
		),
		# Doyurup yollamak: kimseyi almadan da mizaç önemli - kinci biri
		# doyurulduğunda küs gitmez.
		_choice_with_outcomes("EVT_WANDERER_OPT_FEED", _outcomes([
			_outcome_if("EVT_WANDERER_FEED_KIN", _conditions([
				EventCondition.make("wanderer_kin", EventCondition.Op.HAS_FLAG),
			]), _effects([
				EventEffect.make(EventEffect.Type.PROVISIONS, -3),
				EventEffect.make(EventEffect.Type.MORALE, 10),
				EventEffect.make(EventEffect.Type.REPUTATION, 3),
			]), 4.0),
			_outcome_if("EVT_WANDERER_FEED_THIEF", _conditions([
				EventCondition.make(
					NpcDisposition.get_flag("wanderer", NpcDisposition.THIEF),
					EventCondition.Op.HAS_FLAG
				),
			]), _effects([
				EventEffect.make(EventEffect.Type.PROVISIONS, -5),
				EventEffect.make(EventEffect.Type.MORALE, 2),
			]), 4.0),
			EventOutcome.make("EVT_WANDERER_FEED_PLAIN", _effects([
				EventEffect.make(EventEffect.Type.PROVISIONS, -3),
				EventEffect.make(EventEffect.Type.MORALE, 5),
			]), 1.0),
		])),
		# Görmezden gelmek: kinci biri bunu unutmaz, günler sonra döner.
		_choice_with_outcomes("EVT_WANDERER_OPT_IGNORE", _outcomes([
			_outcome_if("EVT_WANDERER_IGNORE_GRUDGE", _conditions([
				EventCondition.make(
					NpcDisposition.get_flag("wanderer", NpcDisposition.VENGEFUL),
					EventCondition.Op.HAS_FLAG
				),
			]), _effects([
				EventEffect.make(EventEffect.Type.MORALE, -2),
				EventEffect.make(EventEffect.Type.SET_FLAG, 0, "wanderer_scorned"),
				EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_wanderer_revenge"),
			]), 4.0),
			EventOutcome.make("EVT_WANDERER_IGNORE_PLAIN", _effects([
				EventEffect.make(EventEffect.Type.MORALE, -2),
			]), 1.0),
		])),
	])
	return event

## Görmezden gelinen kinci yolcu geri döner - kararın faturası hemen
## kesilmiyor, günler sonra kesiliyor (bkz. NpcDisposition).
static func _wanderer_revenge() -> GameEvent:
	var event := _event("evt_wanderer_revenge", "EVT_WANDERER_REVENGE", 3.0)
	event.triggered_only = true
	event.fire_only_once = true
	event.category = GameEvent.Category.CHAIN
	event.conditions = _conditions([
		EventCondition.make("wanderer_scorned", EventCondition.Op.HAS_FLAG),
	])
	event.choices = _choices([
		_choice("EVT_WANDERER_REVENGE_OPT_FIGHT", _effects([
			EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 0, "bandit"),
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "wanderer_scorned"),
		])),
		_choice("EVT_WANDERER_REVENGE_OPT_PAY", _effects([
			EventEffect.make(EventEffect.Type.GOLD, -120),
			EventEffect.make(EventEffect.Type.MORALE, -6),
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "wanderer_scorned"),
		])),
	])
	return event

static func _bandit_ambush() -> GameEvent:
	var event := _event("evt_bandit_ambush", "EVT_AMBUSH", 3.2)
	event.cooldown_days = 1
	# **Savaş seyrekti ve bu, oyunun en derin sisteminin en az görülen
	# sistemi olması demekti.** Taban ağırlık yükseltildi, bekleme
	# kısaltıldı ve tehlike çarpanı kademelendi - sakin bir yolda hâlâ
	# nadir, haydut yatağında neredeyse kaçınılmaz.
	#
	# Sıklık tek başına gelseydi savaş bir vergi olurdu; dengesi yolun
	# dikkat katmanı: kolonun önünde yürüyen oyuncu karşılaşmayı
	# uzaktan görüp hazırlanabiliyor ya da dönebiliyor (bkz.
	# RoadAttention.FRONT_SPOT_BONUS_DAYS).
	event.weight_modifiers = _modifiers([
		EventWeightModifier.make(_conditions([
			EventCondition.make("danger", EventCondition.Op.GREATER_EQUAL, 0.35),
		]), 1.8),
		EventWeightModifier.make(_conditions([
			EventCondition.make("danger", EventCondition.Op.GREATER_EQUAL, 0.6),
		]), 2.2),
	])
	# Faz 17 PR-6 eksiği: fidye sabit 120 GG'ydi, yolun tehlikesinden
	# bağımsız - haydut kadrosunun kendisi zaten danger/party_size/seviyeye
	# göre ölçekleniyordu (bkz. EnemyCatalog.build_bandit_squad, Ruin Rules)
	# ama fidye hiç ölçeklenmiyordu: tehlikeli bir yolda dövüşmek daha riskli
	# oluyordu, satın almaksa hep aynı ucuzluktaydı. Üç bant, yukarıdaki
	# weight_modifiers'ın **aynı** eşiklerini (0.35/0.6) paylaşıyor - aynı
	# sayıyı iki kez icat etmemek için. Bant, `_outcome_if`'in koşulu
	# üstünden `resolve_outcome`'ın ağırlıklı çekimiyle seçiliyor; LESS_THAN
	# (bkz. EventCondition.Op) bantların örtüşmesini (sınırda iki sonucun
	# birden "uygun" sayılıp rastgeleleşmesini) matematiksel olarak imkânsız
	# kılıyor. Kapı (requirements) en ucuz banda göre - tam tutar ancak
	# seçildikten sonra belli oluyor (GOLD effect'i zaten spend_or_owe
	# üstünden geçtiği için tutar kapıdaki kadar değilse fark borca yazılır,
	# force_spend ailesinin "gönüllü ödeme ama pazarlık payı tahminden
	# fazla çıkabilir" hali - EFF_GOLD_LOSS zaten gerçek sayıyı basıyor).
	var pay_choice := _gated_choice(
		"EVT_AMBUSH_OPT_PAY", "EVT_AMBUSH_OPT_PAY_LOCKED",
		_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 80)]),
		_effects([
			EventEffect.make(EventEffect.Type.MORALE, -5),
		])
	)
	pay_choice.outcomes = _outcomes([
		_outcome_if("EVT_AMBUSH_PAY_LOW", _conditions([
			EventCondition.make("danger", EventCondition.Op.LESS_THAN, 0.35),
		]), _effects([EventEffect.make(EventEffect.Type.GOLD, -80)]), 1.0),
		_outcome_if("EVT_AMBUSH_PAY_MID", _conditions([
			EventCondition.make("danger", EventCondition.Op.GREATER_EQUAL, 0.35),
			EventCondition.make("danger", EventCondition.Op.LESS_THAN, 0.6),
		]), _effects([EventEffect.make(EventEffect.Type.GOLD, -130)]), 1.0),
		_outcome_if("EVT_AMBUSH_PAY_HIGH", _conditions([
			EventCondition.make("danger", EventCondition.Op.GREATER_EQUAL, 0.6),
		]), _effects([EventEffect.make(EventEffect.Type.GOLD, -190)]), 1.0),
	])
	event.choices = _choices([
		pay_choice,
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
		# Kaçmak bir zar değil bir çeviklik meselesi - at sürüp gümrük
		# duvarını arkanda bırakabiliyor musun.
		_checked_choice(
			"EVT_CUSTOMS_OPT_RUN",
			SkillCheck.make(CharacterStats.Kind.AGILITY, SkillCheck.Source.LEADER, 0.0),
			"EVT_CUSTOMS_RUN_ESCAPE", _effects([
				EventEffect.make(EventEffect.Type.DANGER, 15),
				EventEffect.make(EventEffect.Type.MORALE, 5),
			]),
			"EVT_CUSTOMS_RUN_CAUGHT", _effects([
				EventEffect.make(EventEffect.Type.DOCUMENT_LOSE, 2),
				EventEffect.make(EventEffect.Type.GOLD, -150),
				EventEffect.make(EventEffect.Type.REPUTATION, -8),
			])
		),
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
		# Fırtınada yol almak Dayanıklılık meselesi - üç kademe check_tier'ın
		# üç değerine bire bir oturuyor: tam başarı fırtınayı sağ salim
		# geçer, kıl payı hasar bırakır, başarısızlık vagon kaybedebilir
		# (evt_landslide'ın ikinci kapısı - nadir kalması için tier 0'ın
		# kendisi zaten seyrek).
		_storm_press_on_choice(),
	])
	return event

static func _storm_press_on_choice() -> EventChoice:
	var choice := EventChoice.new()
	choice.text_key = "EVT_STORM_OPT_PRESS_ON"
	choice.check = SkillCheck.make(CharacterStats.Kind.ENDURANCE, SkillCheck.Source.PARTY_BEST, 0.0)
	choice.outcomes = _outcomes([
		_outcome_if("EVT_STORM_PRESS_OK", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.GREATER_EQUAL, 2.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.MORALE, -5),
		]), 1.0),
		_outcome_if("EVT_STORM_PRESS_BAD", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.EQUAL, 1.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.WAGON_DAMAGE, 1),
			EventEffect.make(EventEffect.Type.PROVISIONS, -4),
			EventEffect.make(EventEffect.Type.MORALE, -12),
		]), 1.0),
		_outcome_if("EVT_STORM_PRESS_LOST", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.EQUAL, 0.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.WAGON_LOSE, 1),
			EventEffect.make(EventEffect.Type.PROVISIONS, -6),
			EventEffect.make(EventEffect.Type.MORALE, -16),
			EventEffect.make(EventEffect.Type.STRESS, 10),
		]), 1.0),
	])
	return choice

static func _spoiled_provisions() -> GameEvent:
	var event := _event("evt_spoiled_provisions", "EVT_SPOILED", 0.9)
	event.conditions = _conditions([
		EventCondition.make("provisions", EventCondition.Op.GREATER_EQUAL, 5),
	])
	# Levazımcı erzağı ölçülü dağıtır - bozulmayı erken fark eder, kayıp az.
	# Bu yüzden anlık kayıp artık sabit değil, seçeneklerin içinde.
	event.choices = _choices([
		# Levazımcı varsa bozulma daha o gün fark edilir.
		_gated_choice(
			"EVT_SPOILED_OPT_CATCH_EARLY", "EVT_SPOILED_OPT_CATCH_EARLY_LOCKED",
			_conditions([
				EventCondition.make("has_levazimci", EventCondition.Op.GREATER_EQUAL, 1),
			]),
			_effects([
				EventEffect.make(EventEffect.Type.PROVISIONS, -1),
				EventEffect.make(EventEffect.Type.MORALE, 2),
			])
		),
		# Otacı bozulmuşu yahniye çevirir: daha az besleyici, biraz moral
		# bozucu ama tamamen çöp değil.
		_gated_choice(
			"EVT_SPOILED_OPT_RECOOK", "EVT_SPOILED_OPT_RECOOK_LOCKED",
			_conditions([
				EventCondition.make("has_otaci", EventCondition.Op.GREATER_EQUAL, 1),
			]),
			_effects([
				EventEffect.make(EventEffect.Type.PROVISIONS, -2),
				EventEffect.make(EventEffect.Type.MORALE, -4),
			])
		),
		_choice("EVT_SPOILED_OPT_SHARE", _effects([
			EventEffect.make(EventEffect.Type.PROVISIONS, -4),
			EventEffect.make(EventEffect.Type.MORALE, -5),
		])),
		_choice("EVT_SPOILED_OPT_RATION", _effects([
			EventEffect.make(EventEffect.Type.PROVISIONS, -4),
			EventEffect.make(EventEffect.Type.MORALE, -15),
			EventEffect.make(EventEffect.Type.REPUTATION, -3),
			EventEffect.make(EventEffect.Type.PROVISIONS, 2),
		])),
	])
	return event

static func _stowaway() -> GameEvent:
	var event := _event("evt_stowaway", "EVT_STOWAWAY", 0.7)
	event.fire_only_once = true
	# Kaçak yolcu da yoldaki yolcu gibi: kim olduğu önceden bilinmiyor.
	event.immediate_effects = _effects([
		EventEffect.make(EventEffect.Type.ROLL_ENCOUNTER, 0, "stowaway"),
	])
	event.choices = _choices([
		_choice_with_outcomes("EVT_STOWAWAY_OPT_SHELTER", _outcomes([
			# Hırsıza kucak açmak pahalıya patlar.
			_outcome_if("EVT_STOWAWAY_SHELTER_THIEF", _conditions([
				EventCondition.make(
					NpcDisposition.get_flag("stowaway", NpcDisposition.THIEF),
					EventCondition.Op.HAS_FLAG
				),
			]), _effects([
				EventEffect.make(EventEffect.Type.PROVISIONS, -2),
				EventEffect.make(EventEffect.Type.GOLD, -90),
				EventEffect.make(EventEffect.Type.MORALE, -8),
			]), 4.0),
			# Çaresiz ya da sadık biri borcunu öder.
			EventOutcome.make("EVT_STOWAWAY_SHELTER_GRATEFUL", _effects([
				EventEffect.make(EventEffect.Type.PROVISIONS, -2),
				EventEffect.make(EventEffect.Type.MORALE, 4),
				EventEffect.make(EventEffect.Type.SET_FLAG, 0, "stowaway_helped"),
				EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_stowaway_repay"),
			]), 1.0),
		])),
		_choice_with_outcomes("EVT_STOWAWAY_OPT_TURN_IN", _outcomes([
			# Kinci birini ele vermek arkanda bir düşman bırakır.
			_outcome_if("EVT_STOWAWAY_TURN_IN_GRUDGE", _conditions([
				EventCondition.make(
					NpcDisposition.get_flag("stowaway", NpcDisposition.VENGEFUL),
					EventCondition.Op.HAS_FLAG
				),
			]), _effects([
				EventEffect.make(EventEffect.Type.GOLD, 30),
				EventEffect.make(EventEffect.Type.REPUTATION, -3),
				EventEffect.make(EventEffect.Type.MORALE, -6),
				EventEffect.make(EventEffect.Type.SET_FLAG, 0, "wanderer_scorned"),
				EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_wanderer_revenge"),
			]), 4.0),
			EventOutcome.make("EVT_STOWAWAY_TURN_IN_PLAIN", _effects([
				EventEffect.make(EventEffect.Type.GOLD, 30),
				EventEffect.make(EventEffect.Type.REPUTATION, -3),
				EventEffect.make(EventEffect.Type.MORALE, -6),
			]), 1.0),
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
		EventCondition.make("morale", EventCondition.Op.LESS_EQUAL, MUTINY_MORALE_THRESHOLD),
		EventCondition.make("merchants", EventCondition.Op.GREATER_EQUAL, 1),
	])
	# Uygun olmak yetmiyordu: moral eşiğin altına indiği 45 günde bile olay
	# ~25 rakip arasında ağırlıklı çekimi hiç kazanamıyordu, yani "katalogda
	# var, oyunda yok" durumu eşiği düzelttikten sonra da sürdü. Bir kriz
	# çekimde baskın olmalı - moral gerçekten dibe vurduğunda kervanın o gün
	# yaşayacağı şey isyandır, yol kenarındaki bir türbe değil.
	event.weight_modifiers = _modifiers([
		EventWeightModifier.make(_conditions([
			EventCondition.make("morale", EventCondition.Op.LESS_EQUAL, MUTINY_MORALE_THRESHOLD),
		]), 24.0),
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
		# Kandırmak: para vermeden söz vererek oyalamak. Dili kuvvetli biri
		# gerekiyor ve tutulmayan söz bedava değil - ilerisi için itibar yer.
		_gated_choice(
			"EVT_MUTINY_OPT_MANIPULATE", "EVT_MUTINY_OPT_MANIPULATE_LOCKED",
			_conditions([
				EventCondition.make(
					"effective_manipulation", EventCondition.Op.GREATER_EQUAL,
					NpcDisposition.MANIPULATE_CHARISMA_THRESHOLD
				),
			]),
			_effects([
				EventEffect.make(EventEffect.Type.MORALE, 22),
				EventEffect.make(EventEffect.Type.REPUTATION, -2),
				EventEffect.make(EventEffect.Type.STRESS, 5),
			])
		),
		# Sert konuşmak otorite meselesi - liderin kendi Karizma'sı, parti
		# ortalaması değil: bu onun tek başına aldığı bir risk.
		_checked_choice(
			"EVT_MUTINY_OPT_HARSH",
			SkillCheck.make(CharacterStats.Kind.CHARISMA, SkillCheck.Source.LEADER, 0.0),
			"EVT_MUTINY_HARSH_OBEY", _effects([
				EventEffect.make(EventEffect.Type.MORALE, 10),
			]),
			"EVT_MUTINY_HARSH_DESERT", _effects([
				EventEffect.make(EventEffect.Type.MERCHANT_LEAVE, 2),
				EventEffect.make(EventEffect.Type.MORALE, -10),
				EventEffect.make(EventEffect.Type.REPUTATION, -5),
			])
		),
	])
	return event

static func _abandoned_wagon() -> GameEvent:
	var event := _event("evt_abandoned_wagon", "EVT_ABANDONED", 0.8)
	event.choices = _choices([
		# Yağmalamak herkesin kabul edeceği bir şey değil: kervanda bunu
		# uğursuzluk sayan ya da ahlaken doğru bulmayan biri çıkabilir.
		# İnanç check'i - doğru duayı/ritüeli bilen biri ölü bir kervanı
		# lanet almadan yağmalar; tam başarı temiz geçer, kıl payı vicdan
		# sesine (objection) çarpar, başarısızlık uğursuzluk (omen) getirir.
		_abandoned_loot_choice(),
		_choice("EVT_ABANDONED_OPT_LEAVE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 3),
		])),
		# Sahibini aramak: vakit yer ama vicdanı da itibarı da temiz tutar.
		_choice("EVT_ABANDONED_OPT_SEARCH", _effects([
			EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
			EventEffect.make(EventEffect.Type.MORALE, 6),
			EventEffect.make(EventEffect.Type.REPUTATION, 3),
		])),
	])
	return event

static func _abandoned_loot_choice() -> EventChoice:
	var choice := EventChoice.new()
	choice.text_key = "EVT_ABANDONED_OPT_LOOT"
	choice.check = SkillCheck.make(CharacterStats.Kind.FAITH, SkillCheck.Source.PARTY_BEST, 0.0)
	choice.outcomes = _outcomes([
		_outcome_if("EVT_ABANDONED_LOOT_CLEAN", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.GREATER_EQUAL, 2.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.ITEM_ADD, 3, "test_furs"),
			EventEffect.make(EventEffect.Type.DANGER, 10),
			EventEffect.make(EventEffect.Type.MORALE, -3),
		]), 1.0),
		_outcome_if("EVT_ABANDONED_LOOT_OBJECTION", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.EQUAL, 1.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.ITEM_ADD, 3, "test_furs"),
			EventEffect.make(EventEffect.Type.MORALE, -8),
			EventEffect.make(EventEffect.Type.REPUTATION, -2),
		]), 1.0),
		_outcome_if("EVT_ABANDONED_LOOT_OMEN", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.EQUAL, 0.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.ITEM_ADD, 3, "test_furs"),
			EventEffect.make(EventEffect.Type.DANGER, 10),
			EventEffect.make(EventEffect.Type.MORALE, -12),
			EventEffect.make(EventEffect.Type.STRESS, 8),
		]), 1.0),
	])
	return choice

## GRANT_TRAIT'in ilk canlı kullanımı: kötü bir gece kervanın liderine
## kalıcı (ama taze - bkz. CharacterData.TRAIT_FRESH_WINDOW_DAYS) bir huy
## bırakabilir. Uykuyu iyi geçirmek İnanç'ın "umutsuzluğa direnç" tarafı -
## huzursuz bir gecede kendini toparlayabilmek irade meselesi.
static func _troubled_night() -> GameEvent:
	var event := _event("evt_troubled_night", "EVT_TROUBLED_NIGHT", 0.8)
	event.cooldown_days = 5
	event.choices = _choices([
		_choice("EVT_TROUBLED_NIGHT_OPT_WATCH", _effects([
			EventEffect.make(EventEffect.Type.PROVISIONS, -2),
			EventEffect.make(EventEffect.Type.MORALE, -3),
			EventEffect.make(EventEffect.Type.STRESS, 5),
		])),
		_checked_choice(
			"EVT_TROUBLED_NIGHT_OPT_SLEEP",
			SkillCheck.make(CharacterStats.Kind.FAITH, SkillCheck.Source.LEADER, 0.0),
			"EVT_TROUBLED_NIGHT_SLEEP_GOOD", _effects([
				EventEffect.make(EventEffect.Type.MORALE, 6),
				EventEffect.make(EventEffect.Type.STRESS, -8),
			]),
			"EVT_TROUBLED_NIGHT_SLEEP_BAD", _effects([
				EventEffect.make(EventEffect.Type.MORALE, -10),
				EventEffect.make(EventEffect.Type.STRESS, 12),
				EventEffect.make(EventEffect.Type.GRANT_TRAIT, 0, TraitCatalog.CLUMSY_FOOT),
			])
		),
	])
	return event

## Yüksek parti stresi kendi agresif olayını açıyor - DD'deki gibi,
## tükenmiş bir kadro birbirine düşebilir. `stress` bağlamı
## GameSession.build_event_context()'ten geliyor.
static func _stress_brawl() -> GameEvent:
	var event := _event("evt_stress_brawl", "EVT_BRAWL", 1.3)
	event.conditions = _conditions([
		EventCondition.make("stress", EventCondition.Op.GREATER_EQUAL, STRESS_BRAWL_THRESHOLD),
	])
	event.cooldown_days = 4
	event.choices = _choices([
		# Oyuncunun kendi örneği: "kavgada ayır" saf bir Güç meselesi -
		# aradaki iki kişiyi fiziksel olarak ayırabiliyor musun.
		_checked_choice(
			"EVT_BRAWL_OPT_INTERVENE",
			SkillCheck.make(CharacterStats.Kind.STRENGTH, SkillCheck.Source.LEADER, 0.0),
			"EVT_BRAWL_INTERVENE_OK", _effects([
				EventEffect.make(EventEffect.Type.MORALE, -5),
				EventEffect.make(EventEffect.Type.STRESS, -15),
			]),
			"EVT_BRAWL_INTERVENE_HURT", _effects([
				EventEffect.make(EventEffect.Type.MORALE, -8),
				EventEffect.make(EventEffect.Type.STRESS, -5),
				EventEffect.make(EventEffect.Type.STRESS, 6),
			])
		),
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
		# Toprağın altından her zaman hazine çıkmaz: burası bir mezarlık da
		# olabilir ve kazmanın bedeli maldan değil kadronun ruhundan çıkar.
		# Nereyi kazacağını doğru okumak Algı meselesi - iyi bir gözlemci
		# hazineyi bulur, vasat biri boşa kürek sallar, dikkatsiz biri
		# doğrudan bir mezara saplanır.
		_forgotten_cache_dig_choice(),
		# Otacı toprağı okur: mezar mı zula mı, kazmadan önce anlaşılır.
		_gated_choice(
			"EVT_CACHE_OPT_READ_GROUND", "EVT_CACHE_OPT_READ_GROUND_LOCKED",
			_conditions([
				EventCondition.make("has_otaci", EventCondition.Op.GREATER_EQUAL, 1),
			]),
			_effects([
				EventEffect.make(EventEffect.Type.GRANT_EQUIPMENT, 0, EquipmentCatalog.AMULET_WARD),
				EventEffect.make(EventEffect.Type.MORALE, 3),
			])
		),
		_choice("EVT_CACHE_OPT_LEAVE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 2),
		])),
	])
	return event

static func _forgotten_cache_dig_choice() -> EventChoice:
	var choice := EventChoice.new()
	choice.text_key = "EVT_CACHE_OPT_DIG"
	choice.check = SkillCheck.make(CharacterStats.Kind.PERCEPTION, SkillCheck.Source.PARTY_BEST, 0.0)
	choice.outcomes = _outcomes([
		_outcome_if("EVT_CACHE_DIG_RING", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.GREATER_EQUAL, 2.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.GRANT_EQUIPMENT, 0, EquipmentCatalog.RING_MARKSMAN),
		]), 1.0),
		_outcome_if("EVT_CACHE_DIG_AMULET", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.GREATER_EQUAL, 2.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.GRANT_EQUIPMENT, 0, EquipmentCatalog.AMULET_WARD),
		]), 1.0),
		_outcome_if("EVT_CACHE_DIG_NOTHING", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.EQUAL, 1.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.PROVISIONS, -2),
			EventEffect.make(EventEffect.Type.MORALE, -3),
		]), 1.0),
		_outcome_if("EVT_CACHE_DIG_GRAVE", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.EQUAL, 0.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.MORALE, -14),
			EventEffect.make(EventEffect.Type.STRESS, 12),
			EventEffect.make(EventEffect.Type.GRANT_TRAIT, 0, TraitCatalog.NAIVE),
		]), 1.0),
	])
	return choice

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
		# Demirci yalnızca silah satmaz: yoldaki asıl derdi olan hasarlı
		# vagonu da onarır. Şehre kadar beklemeye değer mi, orası kararın.
		_gated_choice(
			"EVT_TINKER_OPT_REPAIR", "EVT_TINKER_OPT_REPAIR_LOCKED",
			_conditions([
				EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 60),
				EventCondition.make("damaged_wagons", EventCondition.Op.GREATER_EQUAL, 1),
			]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -60),
				EventEffect.make(EventEffect.Type.WAGON_REPAIR, 1),
				EventEffect.make(EventEffect.Type.MORALE, 4),
			])
		),
		# Yedek parça: şimdi ucuz, ileride vagonu kırıldığında işe yarar.
		_gated_choice(
			"EVT_TINKER_OPT_PARTS", "EVT_TINKER_OPT_PARTS_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 35)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -35),
				EventEffect.make(EventEffect.Type.SET_FLAG, 0, "has_spare_parts"),
				EventEffect.make(EventEffect.Type.MORALE, 2),
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

## Kervanın arkasından geçit kapanır. Yolun *kendi tablosuna* dokunmuyor
## (bkz. RouteConditions): coğrafya sabit kalır, üstündeki ağ oynar. Bu
## kervanın kendi seferini bitirmesini engellemez - bedeli sonraki sefer
## o yoldan dönemeyecek olmak, yani ROUTE_CHANGE'in asıl amacı: haritayı
## sabit yedi kenar olmaktan çıkarmak.
static func _landslide() -> GameEvent:
	var event := _event("evt_landslide", "EVT_LANDSLIDE", 0.7)
	event.cooldown_days = 12
	event.choices = _choices([
		# Kervanın gerçekten vagon kaybedebildiği iki yerden biri.
		# EventEffect.Type.WAGON_LOSE applier'da işleniyordu ama hiçbir olay
		# onu söylemiyordu: 600 koşuda ortalama vagon kaybı tam olarak 0.00
		# çıkıyordu, yani "kervan mahvolabilir" kuralının bu yarısı yalnızca
		# kâğıt üstündeydi. Kayıp CaravanState.lose_wagons() tarafından
		# MIN_WAGONS'a kenetleniyor - oyuncunun kendi vagonu asla gitmez.
		# Vagonu göçük kayanın arasından itmek saf bir Güç meselesi.
		_checked_choice(
			"EVT_LANDSLIDE_OPT_PUSH",
			SkillCheck.make(CharacterStats.Kind.STRENGTH, SkillCheck.Source.PARTY_BEST, 0.0),
			"EVT_LANDSLIDE_PUSH_OK", _effects([
				EventEffect.make(EventEffect.Type.ROUTE_CHANGE, 14, "current|closed"),
				EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
				EventEffect.make(EventEffect.Type.WAGON_DAMAGE, 1),
				EventEffect.make(EventEffect.Type.STRESS, 4),
			]),
			"EVT_LANDSLIDE_PUSH_LOST", _effects([
				EventEffect.make(EventEffect.Type.ROUTE_CHANGE, 14, "current|closed"),
				EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
				EventEffect.make(EventEffect.Type.WAGON_LOSE, 1),
				EventEffect.make(EventEffect.Type.MORALE, -10),
				EventEffect.make(EventEffect.Type.STRESS, 8),
			])
		),
		_choice("EVT_LANDSLIDE_OPT_CLEAR", _effects([
			EventEffect.make(EventEffect.Type.ROUTE_CHANGE, 8, "current|slow"),
			EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 2),
			EventEffect.make(EventEffect.Type.MORALE, -4),
			EventEffect.make(EventEffect.Type.REPUTATION, 1),
		])),
	])
	return event

## Yolu temizleyen devriye - ROUTE_CHANGE'in ters yönü. Yolun hali yalnızca
## kötüye gitmiyorsa dinamik rota bir ceza mekaniği olmaktan çıkıp gerçek
## bir dünya katmanı oluyor.
static func _road_patrol() -> GameEvent:
	var event := _event("evt_road_patrol", "EVT_PATROL", 0.6)
	event.conditions = _conditions([
		# Bağlamdaki "danger" 0-1 arası bir oran, yüzde değil - 25 yazmak
		# olayın hiç ateşlenmemesi demekti (simülatör yakaladı).
		EventCondition.make("danger", EventCondition.Op.GREATER_EQUAL, 0.25),
	])
	event.cooldown_days = 10
	event.choices = _choices([
		_choice("EVT_PATROL_OPT_JOIN", _effects([
			EventEffect.make(EventEffect.Type.ROUTE_CHANGE, 12, "current|open"),
			EventEffect.make(EventEffect.Type.DANGER, -10),
			EventEffect.make(EventEffect.Type.REPUTATION, 2),
			EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
		])),
		# Faz 17 PR-6'nın kendi kapsam-dışı notu bunu "devriyeyle kavga"
		# olarak reddetmişti - ama olayın kendi metni zaten "haydutları
		# temizlemeye niyetliler" diyor ve OPT_JOIN'in hiç zar içermeyen
		# ROUTE_CHANGE/DANGER paketi o vaadi hiç ödemiyordu. Bu seçenek
		# evt_guard_patrol'ün "guard" (muhafızla kavga, kazanınca itibar
		# *kaybettirir*) dalıyla karışmıyor - burada dövüşülen kişi haydut,
		# muhafız değil, o yüzden zafer normal şekilde itibar kazandırır
		# (bkz. Combat Rules'un GUARD_VICTORY_REPUTATION istisnası).
		# Sonuç tamamen _on_combat_finished'in genel ödül/ceza paketinden
		# geliyor - evt_bandit_ambush'ın OPT_FIGHT'ıyla birebir aynı kalıp.
		_choice("EVT_PATROL_OPT_FIGHT", _effects([
			EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 0, "bandit"),
		])),
		_choice("EVT_PATROL_OPT_PASS", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 2),
		])),
	])
	return event

## Göçebe kültüründen bir oyuncu bozkırda akraba bir boyla karşılaşır -
## kültürün kendi perki (erzak tüketimi) dışında ilk kez olay tarafında
## da bir sahnesi oluyor (bkz. CultureCatalog).
## Yoldaki bir obayla karşılaşmak. Eskiden yalnızca Göçebe oyunculara
## açıktı; artık herkese açık ve fark, karşındakinin **seninle aynı
## kültürden** çıkıp çıkmadığında (bkz. ROLL_ENCOUNTER\'ın kin bayrağı).
## Hangi kültürden olursan ol, kendi boyunla karşılaşmak başka bir kapı açar.
static func _kin_encounter() -> GameEvent:
	var event := _event("evt_kin_encounter", "EVT_KIN", 0.8)
	event.cooldown_days = 8
	event.immediate_effects = _effects([
		EventEffect.make(EventEffect.Type.ROLL_ENCOUNTER, 0, "kin"),
	])
	event.choices = _choices([
		_choice_with_outcomes("EVT_KIN_OPT_TRADE", _outcomes([
			# Kendi boyun sana hem ucuza verir hem fazlasını katar.
			_outcome_if("EVT_KIN_TRADE_KIN", _conditions([
				EventCondition.make("kin_kin", EventCondition.Op.HAS_FLAG),
			]), _effects([
				EventEffect.make(EventEffect.Type.GOLD, -20),
				EventEffect.make(EventEffect.Type.PROVISIONS, 8),
				EventEffect.make(EventEffect.Type.MORALE, 4),
			]), 4.0),
			EventOutcome.make("EVT_KIN_TRADE_PLAIN", _effects([
				EventEffect.make(EventEffect.Type.GOLD, -20),
				EventEffect.make(EventEffect.Type.PROVISIONS, 4),
			]), 1.0),
		])),
		_choice_with_outcomes("EVT_KIN_OPT_GREET", _outcomes([
			_outcome_if("EVT_KIN_GREET_KIN", _conditions([
				EventCondition.make("kin_kin", EventCondition.Op.HAS_FLAG),
			]), _effects([
				EventEffect.make(EventEffect.Type.MORALE, 10),
				EventEffect.make(EventEffect.Type.REPUTATION, 4),
				EventEffect.make(EventEffect.Type.STRESS, -6),
			]), 4.0),
			EventOutcome.make("EVT_KIN_GREET_PLAIN", _effects([
				EventEffect.make(EventEffect.Type.MORALE, 4),
				EventEffect.make(EventEffect.Type.REPUTATION, 1),
			]), 1.0),
		])),
	])
	return event

## Faz 17'nin ilk skill-check pilotu: "Muhasebe Anlaşmazlığı" tam da bu
## işe biçilmiş - iki tüccarın defterini tutup kimin haklı olduğunu
## bulmak saf bir Zeka meselesi, parti kararı. Başarısızlık bedavaya
## değil: hesabı yanlış tutup yanlış tarafa hak verirsen itibar döner.
static func _culture_valley_dispute() -> GameEvent:
	var event := _event("evt_culture_valley_dispute", "EVT_VALLEY_DISPUTE", 0.8)
	event.conditions = _conditions([
		EventCondition.make("is_valley_culture", EventCondition.Op.GREATER_EQUAL, 1),
		EventCondition.make("merchants", EventCondition.Op.GREATER_EQUAL, 1),
	])
	event.cooldown_days = 8
	event.choices = _choices([
		_checked_choice(
			"EVT_VALLEY_DISPUTE_OPT_MEDIATE",
			SkillCheck.make(CharacterStats.Kind.INTELLECT, SkillCheck.Source.PARTY_BEST, 0.0),
			"EVT_VALLEY_DISPUTE_MEDIATE_RIGHT", _effects([
				EventEffect.make(EventEffect.Type.REPUTATION, 5),
				EventEffect.make(EventEffect.Type.GOLD, 30),
			]),
			"EVT_VALLEY_DISPUTE_MEDIATE_WRONG", _effects([
				EventEffect.make(EventEffect.Type.REPUTATION, -4),
				EventEffect.make(EventEffect.Type.MORALE, -2),
			])
		),
		_choice("EVT_VALLEY_DISPUTE_OPT_IGNORE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 1),
		])),
	])
	return event

## Faz 17 PR-6: aynı desen `evt_roadside_shrine`'ın - taban ağırlık düşük
## (dağ kabilesi mensubu her an meydan okuyabilir, ama nadiren) ve
## `near_mountain_pass` bayrağı (`road_journey.gd`'nin o günkü terrain
## segmentinden okuduğu) ağırlığı katlıyor: Güç Sınavı artık ekranda
## gerçekten bir dağ geçidi durağının önünden geçilen gün neredeyse kesin
## çekiliyor, geçidin gerçekte hiç görünmediği düz bir günde neredeyse hiç.
static func _culture_highland_challenge() -> GameEvent:
	var event := _event("evt_culture_highland_challenge", "EVT_HIGHLAND_CHALLENGE", 0.25)
	event.conditions = _conditions([
		EventCondition.make("is_highland_culture", EventCondition.Op.GREATER_EQUAL, 1),
	])
	event.weight_modifiers = _modifiers([
		EventWeightModifier.make(_conditions([
			EventCondition.make("near_mountain_pass", EventCondition.Op.GREATER_EQUAL, 1),
		]), 6.0),
	])
	event.cooldown_days = 8
	event.choices = _choices([
		# Dağ kabilesinin kendi "Güç Sınavı" - lider bizzat meydana çıkar.
		_checked_choice(
			"EVT_HIGHLAND_CHALLENGE_OPT_ACCEPT",
			SkillCheck.make(CharacterStats.Kind.STRENGTH, SkillCheck.Source.LEADER, 0.0),
			"EVT_HIGHLAND_CHALLENGE_WIN", _effects([
				EventEffect.make(EventEffect.Type.MORALE, 8),
				EventEffect.make(EventEffect.Type.REPUTATION, 3),
			]),
			"EVT_HIGHLAND_CHALLENGE_LOSE", _effects([
				EventEffect.make(EventEffect.Type.STRESS, 5),
				EventEffect.make(EventEffect.Type.MORALE, -3),
			])
		),
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
		# Dedikodu artık düz bir bahşiş değil: duyduğun şey bir hazinenin
		# yeri de olabilir, bir entrikanın ucu da, hiçbir şey de - hangisi
		# olduğunu süzülen sözden ayıklamak Bilgelik meselesi.
		_port_gossip_listen_choice(),
		_choice("EVT_PORT_GOSSIP_OPT_IGNORE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 1),
		])),
	])
	return event

static func _port_gossip_listen_choice() -> EventChoice:
	var choice := EventChoice.new()
	choice.text_key = "EVT_PORT_GOSSIP_OPT_LISTEN"
	choice.check = SkillCheck.make(CharacterStats.Kind.WISDOM, SkillCheck.Source.PARTY_BEST, 0.0)
	choice.outcomes = _outcomes([
		_outcome_if("EVT_PORT_GOSSIP_TREASURE", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.GREATER_EQUAL, 2.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.GOLD, 140),
			EventEffect.make(EventEffect.Type.MORALE, 6),
		]), 0.8),
		_outcome_if("EVT_PORT_GOSSIP_MYSTERY", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.GREATER_EQUAL, 2.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.GRANT_EQUIPMENT, 0, EquipmentCatalog.AMULET_COURAGE),
			EventEffect.make(EventEffect.Type.STRESS, 6),
		]), 0.7),
		_outcome_if("EVT_PORT_GOSSIP_INTRIGUE", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.EQUAL, 1.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.REPUTATION, 6),
			EventEffect.make(EventEffect.Type.MARKET_SHOCK, -25, "test_loc_c|test_cloth|18"),
		]), 1.0),
		_outcome_if("EVT_PORT_GOSSIP_NOTHING", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.EQUAL, 0.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.GOLD, 20),
			EventEffect.make(EventEffect.Type.REPUTATION, 1),
		]), 1.0),
	])
	return choice

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
##
## `RouteTerrain` yolun bazı parçalarını biyoma uygun bir "sunak" durağıyla
## çiziyor (bkz. `RouteTerrain.STOP_SHRINE`) ama bu olay o durağa hiç
## bakmıyordu - ekranda gerçek bir sunak dururken olay hiç ateşlenmeyebilir,
## sunak hiç yokken de ateşlenebilirdi; oyuncunun gördüğü işaretle çekilen
## kart birbirinden habersizdi. Taban ağırlık şimdi düşük (işaretsiz bir
## yerde de nadiren bir sunağa rastlanabilir) ve `near_shrine` bayrağı -
## `road_journey.gd`'nin o günkü terrain segmentinden okuyup context'e
## eklediği - `evt_forage`'ın İzci çarpanıyla aynı desende ağırlığı
## katlıyor: sunak durağının önünden geçilen gün olay neredeyse kesin
## çekiliyor, başka hiçbir gün neredeyse hiç çekilmiyor.
static func _roadside_shrine() -> GameEvent:
	var event := _event("evt_roadside_shrine", "EVT_SHRINE", 0.15)
	event.cooldown_days = 6
	event.weight_modifiers = _modifiers([
		EventWeightModifier.make(_conditions([
			EventCondition.make("near_shrine", EventCondition.Op.GREATER_EQUAL, 1),
		]), 8.0),
	])
	event.choices = _choices([
		_choice("EVT_SHRINE_OPT_PRAY", _effects([
			EventEffect.make(EventEffect.Type.STRESS, -10),
			EventEffect.make(EventEffect.Type.MORALE, 3),
		])),
		# Adakları almak bir İnanç meselesi - kutsalın öfkesini göze
		# alabilecek kadar sağlam bir vicdan mı, yoksa lanetten korkan biri mi.
		_checked_choice(
			"EVT_SHRINE_OPT_TAKE",
			SkillCheck.make(CharacterStats.Kind.FAITH, SkillCheck.Source.LEADER, 0.0),
			"EVT_SHRINE_TAKE_GOOD", _effects([
				EventEffect.make(EventEffect.Type.GOLD, 50),
			]),
			"EVT_SHRINE_TAKE_BAD", _effects([
				EventEffect.make(EventEffect.Type.STRESS, 15),
				EventEffect.make(EventEffect.Type.REPUTATION, -4),
			])
		),
	])
	return event

## Faz 17 PR-9: iki yaratılış efsanesinin (bkz. CLAUDE.md Church ekranının
## MYTH_HIGHLAND/MYTH_FISHER metinleri) yoldaki karşılığı - doruğa ya da
## kıyıya yürüyen bir hacı. `evt_road_wanderer`'dan farklı: kervana katılmak
## istemiyor, yalnızca birkaç günlük eşlik istiyor, o yüzden `TRIGGER_RECRUIT`
## açmıyor. `evt_wanderer_revenge`'in "karar gecikmeli sonuç doğurur" kalıbının
## olumlu ucu - iyi bir seçim de günler sonra bir karşılık bulabilir, kötü bir
## seçimin tekelinde olmayan bir mekanik (bkz. _pilgrim_blessing).
static func _pilgrim_encounter() -> GameEvent:
	var event := _event("evt_pilgrim_encounter", "EVT_PILGRIM", 0.7)
	event.cooldown_days = 8
	event.choices = _choices([
		_choice("EVT_PILGRIM_OPT_ESCORT", _effects([
			EventEffect.make(EventEffect.Type.PROVISIONS, -2),
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "pilgrim_escorted"),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_pilgrim_blessing"),
		])),
		# Doğru yolu tarif etmek erzak harcamadan da mümkün, ama Bilgelik
		# ister - hangi efsanenin hangi yöne baktığını gerçekten mi
		# biliyorsun, yoksa tahmin mi ediyorsun.
		_checked_choice(
			"EVT_PILGRIM_OPT_GUIDE",
			SkillCheck.make(CharacterStats.Kind.WISDOM, SkillCheck.Source.LEADER, 0.0),
			"EVT_PILGRIM_GUIDE_GOOD", _effects([
				EventEffect.make(EventEffect.Type.MORALE, 4),
				EventEffect.make(EventEffect.Type.SET_FLAG, 0, "pilgrim_escorted"),
				EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_pilgrim_blessing"),
			]),
			"EVT_PILGRIM_GUIDE_BAD", _effects([
				EventEffect.make(EventEffect.Type.MORALE, -1),
			])
		),
		_choice("EVT_PILGRIM_OPT_IGNORE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -1),
		])),
	])
	return event

## Hacının teşekkürü - `evt_wanderer_revenge`'in bir faturaya dönüşmesi gibi,
## bu da günler sonra gelir, ama bir bedel değil bir karşılık.
static func _pilgrim_blessing() -> GameEvent:
	var event := _event("evt_pilgrim_blessing", "EVT_PILGRIM_BLESSING", 3.0)
	event.triggered_only = true
	event.fire_only_once = true
	event.category = GameEvent.Category.CHAIN
	event.conditions = _conditions([
		EventCondition.make("pilgrim_escorted", EventCondition.Op.HAS_FLAG),
	])
	event.choices = _choices([
		_choice("EVT_PILGRIM_BLESSING_OPT_ACCEPT", _effects([
			EventEffect.make(EventEffect.Type.STRESS, -8),
			EventEffect.make(EventEffect.Type.MORALE, 5),
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "pilgrim_escorted"),
		])),
	])
	return event

## Doğada karşılaşılan bir tehdit - haydut pususundan ayrı bir tetikleyici,
## kadrosu EnemyCatalog.build_wildlife_squad'tan gelir (bkz. Faz 8 PR-B).
## Kaçmak/beslemek savaşsız atlatır ama bedelsiz değil - besleme erzak
## yer, kaçış tehlikeyi artırır (ürkütülen hayvanlar iz bırakır).
static func _wild_animal() -> GameEvent:
	var event := _event("evt_wild_animal", "EVT_WILD", 2.2)
	event.cooldown_days = 2
	# Vahşi hayvan tehlikeyle değil ıssızlıkla gelir, ama sıklık
	# gerekçesi haydutunkiyle aynı (bkz. _bandit_ambush).
	event.weight_modifiers = _modifiers([
		EventWeightModifier.make(_conditions([
			EventCondition.make("danger", EventCondition.Op.GREATER_EQUAL, 0.4),
		]), 1.6),
	])
	event.choices = _choices([
		_choice("EVT_WILD_OPT_FIGHT", _effects([
			EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 0, "wildlife"),
		])),
		_choice("EVT_WILD_OPT_FEED", _effects([
			EventEffect.make(EventEffect.Type.PROVISIONS, -3),
			EventEffect.make(EventEffect.Type.MORALE, 2),
		])),
		# Kaçmak Çeviklik meselesi - hayvanı gerçekten geride bırakabiliyor
		# musun, yoksa peşine mi takıyorsun.
		_checked_choice(
			"EVT_WILD_OPT_FLEE",
			SkillCheck.make(CharacterStats.Kind.AGILITY, SkillCheck.Source.LEADER, 0.0),
			"EVT_WILD_FLEE_OK", _effects([
				EventEffect.make(EventEffect.Type.DANGER, 4),
				EventEffect.make(EventEffect.Type.MORALE, -1),
			]),
			"EVT_WILD_FLEE_BAD", _effects([
				EventEffect.make(EventEffect.Type.DANGER, 12),
				EventEffect.make(EventEffect.Type.MORALE, -6),
				EventEffect.make(EventEffect.Type.STRESS, 5),
			])
		),
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
		# Devriyeden kaçmak da bir Çeviklik meselesi - aynı vokabüler,
		# aynı stat, farklı bir bağlam.
		_checked_choice(
			"EVT_GUARD_PATROL_OPT_RUN",
			SkillCheck.make(CharacterStats.Kind.AGILITY, SkillCheck.Source.LEADER, 0.0),
			"EVT_GUARD_PATROL_RUN_ESCAPE", _effects([
				EventEffect.make(EventEffect.Type.DANGER, 10),
			]),
			"EVT_GUARD_PATROL_RUN_CAUGHT", _effects([
				EventEffect.make(EventEffect.Type.GOLD, -120),
				EventEffect.make(EventEffect.Type.REPUTATION, -10),
				EventEffect.make(EventEffect.Type.DOCUMENT_LOSE, 1),
			])
		),
		_choice("EVT_GUARD_PATROL_OPT_RESIST", _effects([
			EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 0, "guard"),
		])),
	])
	return event

## Rota değişince o yöne gitmeyecek tüccarlar bunu fark eder - En-Route
## Plan Rules'un zaten yaptığı sessiz kesintiyi (bkz.
## `_apply_undelivered_contract_penalty()`) hikâyeleştiriyor. Havuzdan
## hiç çekilmez (`triggered_only`, taban ağırlığı 0) - road_journey.gd
## `_apply_replan()`'dan, kervan gerçekten yön değiştirdiği anda doğrudan
## sunulur, bir olay değil bir sonuç olduğu için.
static func _route_diversion() -> GameEvent:
	var event := _event("evt_route_diversion", "EVT_ROUTE_DIVERSION", 0.0)
	event.triggered_only = true
	event.choices = _choices([
		_gated_choice(
			"EVT_ROUTE_DIVERSION_OPT_PAY", "EVT_ROUTE_DIVERSION_OPT_PAY_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 60)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -60),
			])
		),
		_choice("EVT_ROUTE_DIVERSION_OPT_IGNORE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -8),
		])),
	])
	return event

## Bölgeyi bilen biri - İzci ya da rotanın kendi biyomu - kervanı
## besleyebilir. Yeni bir sistem değil: `EventEffect.Type.PROVISIONS`
## zaten var, burada yalnızca yeni bir kapı. Zaman zaten her olay gibi
## `_present_event()`'in `EVENT_HOURS`'u üzerinden tüketiliyor.
static func _forage() -> GameEvent:
	var event := _event("evt_forage", "EVT_FORAGE", 1.1)
	event.cooldown_days = 3
	event.weight_modifiers = _modifiers([
		EventWeightModifier.make(_conditions([
			EventCondition.make("has_izci", EventCondition.Op.GREATER_EQUAL, 1),
		]), 1.6),
	])
	event.choices = _choices([
		_choice("EVT_FORAGE_OPT_GATHER", _effects([
			EventEffect.make(EventEffect.Type.PROVISIONS, 6),
		])),
		_choice("EVT_FORAGE_OPT_SKIP", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 1),
		])),
	])
	return event

## Kervan içi hırsızlık - `NpcDisposition`'ın gizli-mizaç + zincir
## deseninin (bkz. `evt_wanderer_revenge`) parti-içi versiyonu. Kim
## aldığı hemen söylenmez; ertesi güne değil, `UNLOCK_EVENT` ile açılan
## soruşturmaya bırakılır.
static func _party_theft() -> GameEvent:
	var event := _event("evt_party_theft", "EVT_PARTY_THEFT", 1.0)
	event.cooldown_days = 10
	event.choices = _choices([
		_choice("EVT_PARTY_THEFT_OPT_INVESTIGATE", _effects([
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "theft_pending"),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_party_investigation"),
			EventEffect.make(EventEffect.Type.MORALE, -4),
		])),
		_choice("EVT_PARTY_THEFT_OPT_SHRUG", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -6),
		])),
	])
	return event

## Soruşturma: herkes suçlayabilir - Faz 13'te bu %50/%50 bir kumardı,
## Sezgisi kuvvetli bir parti seçmeden *önce* bir ipucu görüyordu (bkz.
## `EventChoice.hint_text_key`) ama ipucu zarı değiştirmiyordu, yalnızca
## bilgilendiriyordu. Faz 17 bunu **tamamlıyor**: ipucu artık gerçek bir
## Sezgi check'inin önizlemesi - kaldırılmadı, çünkü "neye bahse
## giriyorsun" sorusunu check'in kendi yüzde gösterimiyle birlikte iki
## kez, iki farklı açıdan söylüyor (flavor + sayı).
static func _party_investigation() -> GameEvent:
	var event := _event("evt_party_investigation", "EVT_PARTY_INVESTIGATION", 2.0)
	event.triggered_only = true
	event.conditions = _conditions([
		EventCondition.make("theft_pending", EventCondition.Op.HAS_FLAG),
	])
	var accuse := _checked_choice(
		"EVT_PARTY_INVESTIGATION_OPT_ACCUSE",
		SkillCheck.make(CharacterStats.Kind.PERCEPTION, SkillCheck.Source.PARTY_BEST, 0.0),
		"EVT_PARTY_INVESTIGATION_ACCUSE_RIGHT", _effects([
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "theft_pending"),
			EventEffect.make(EventEffect.Type.REPUTATION, 2),
		]),
		"EVT_PARTY_INVESTIGATION_ACCUSE_WRONG", _effects([
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "theft_pending"),
			EventEffect.make(EventEffect.Type.MORALE, -10),
			EventEffect.make(EventEffect.Type.STRESS, 6),
		])
	)
	accuse.hint_text_key = "EVT_PARTY_INVESTIGATION_HINT"
	accuse.hint_stat = CharacterStats.Kind.PERCEPTION
	accuse.hint_threshold = 2.0
	event.choices = _choices([
		accuse,
		_choice("EVT_PARTY_INVESTIGATION_OPT_DROP", _effects([
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "theft_pending"),
			EventEffect.make(EventEffect.Type.MORALE, -3),
		])),
	])
	return event

## Askeri konvoy - `EVENT_ROAD_MARKER_KIND`'de mevcut "guard" kategorisini
## yeniden kullanır (bkz. road_journey.gd), yeni bir figür çizmiyor.
static func _military_convoy() -> GameEvent:
	var event := _event("evt_military_convoy", "EVT_MILITARY_CONVOY", 0.7)
	event.cooldown_days = 8
	event.choices = _choices([
		_choice("EVT_MILITARY_CONVOY_OPT_YIELD", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -1),
		])),
		_gated_choice(
			"EVT_MILITARY_CONVOY_OPT_ESCORT", "EVT_MILITARY_CONVOY_OPT_ESCORT_LOCKED",
			_conditions([EventCondition.make("has_muhafiz", EventCondition.Op.GREATER_EQUAL, 1)]),
			_effects([
				EventEffect.make(EventEffect.Type.REPUTATION, 3),
				EventEffect.make(EventEffect.Type.GOLD, 40),
			])
		),
	])
	return event

## Mülteci kolonu - mevcut "traveler" kategorisini yeniden kullanır
## (bkz. `evt_road_wanderer`).
static func _refugee_column() -> GameEvent:
	var event := _event("evt_refugee_column", "EVT_REFUGEE_COLUMN", 0.7)
	event.cooldown_days = 8
	event.choices = _choices([
		_gated_choice(
			"EVT_REFUGEE_COLUMN_OPT_SHARE", "EVT_REFUGEE_COLUMN_OPT_SHARE_LOCKED",
			_conditions([EventCondition.make("provisions", EventCondition.Op.GREATER_EQUAL, 6)]),
			_effects([
				EventEffect.make(EventEffect.Type.PROVISIONS, -6),
				EventEffect.make(EventEffect.Type.MORALE, 6),
				EventEffect.make(EventEffect.Type.REPUTATION, 2),
			])
		),
		_choice("EVT_REFUGEE_COLUMN_OPT_PASS", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -2),
		])),
	])
	return event

## Başka bir tüccar kervanı - mevcut "traveler" kategorisini yeniden
## kullanır.
static func _merchant_caravan() -> GameEvent:
	var event := _event("evt_merchant_caravan", "EVT_MERCHANT_CARAVAN", 0.7)
	event.cooldown_days = 8
	event.choices = _choices([
		# Yol üstü takas Karizma meselesi - iyi bir pazarlıkçı kervandan
		# kervana geçerken bile kâr çıkarır.
		_checked_choice(
			"EVT_MERCHANT_CARAVAN_OPT_TRADE",
			SkillCheck.make(CharacterStats.Kind.CHARISMA, SkillCheck.Source.PARTY_BEST, 0.0),
			"EVT_MERCHANT_CARAVAN_TRADE_GOOD", _effects([
				EventEffect.make(EventEffect.Type.GOLD, 30),
			]),
			"EVT_MERCHANT_CARAVAN_TRADE_FLAT", _effects([
				EventEffect.make(EventEffect.Type.GOLD, -10),
			])
		),
		_choice("EVT_MERCHANT_CARAVAN_OPT_WAVE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 1),
		])),
	])
	return event

## Faz 17: haritanın büyük, adlı olayları (bkz. WorldEvents) yolda duyulan
## bir haberle başlıyor - RouteConditions'ın doğal durumları gibi
## kendiliğinden atılmıyorlar, `WORLD_EVENT_START` etkisini taşıyan bu beş
## olay onları başlatıyor. Her "haber" olayının koşulu aynı türden bir
## olayın o hedefte zaten aktif olmadığını (`route_has_X`/`destination_has_X`
## <= 0) şart koşuyor - yoksa aynı yol/şehir üst üste savaşa/vebaya
## girip tehlike ya da fiyat sınırsızca katlanabilirdi.

## Bölgesel savaş: gidilen yolun tehlikesine süreli bir pay ekler
## (bkz. WorldEvents.ROUTE_DANGER_DELTA) - yeni bir olay zinciri icat
## etmiyor, ambush/wildlife ağırlıkları zaten danger'a bağlı (bkz. Ruin
## Rules), o yüzden savaş bölgesi "daha çok haydut/devriye" olarak
## kendiliğinden hissettiriyor.
static func _regional_war_news() -> GameEvent:
	var event := _event("evt_regional_war_news", "EVT_WAR_NEWS", 0.35)
	event.cooldown_days = 20
	event.conditions = _conditions([
		EventCondition.make("route_has_regional_war", EventCondition.Op.LESS_EQUAL, 0.0),
	])
	event.immediate_effects = _effects([
		EventEffect.make(EventEffect.Type.WORLD_EVENT_START, 24, "war|current"),
	])
	event.choices = _choices([
		_choice("EVT_WAR_NEWS_OPT_BRACE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -4),
			EventEffect.make(EventEffect.Type.STRESS, 3),
		])),
		_choice("EVT_WAR_NEWS_OPT_IGNORE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -1),
		])),
	])
	return event

## Veba: varılacak şehirde süreli bir fiyat şoku (bkz. WorldEvents.
## CITY_PRICE_MULTIPLIER, gerçek fiyat etkisi MarketConditions.add_shock
## üstünden - iki ayrı fiyat motoru icat edilmedi).
static func _plague_outbreak_news() -> GameEvent:
	var event := _event("evt_plague_outbreak_news", "EVT_PLAGUE_NEWS", 0.3)
	event.cooldown_days = 20
	event.conditions = _conditions([
		EventCondition.make("destination_has_plague", EventCondition.Op.LESS_EQUAL, 0.0),
	])
	event.immediate_effects = _effects([
		EventEffect.make(EventEffect.Type.WORLD_EVENT_START, 18, "plague|current"),
	])
	event.choices = _choices([
		_choice("EVT_PLAGUE_NEWS_OPT_WORRY", _effects([
			EventEffect.make(EventEffect.Type.STRESS, 4),
		])),
		_choice("EVT_PLAGUE_NEWS_OPT_IGNORE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -1),
		])),
	])
	return event

## Ticaret fuarı - vebanın olumlu ikizi, aynı vokabüler (MARKET_SHOCK'ın
## kendisi, WorldEvents üstünden), ters yönde.
static func _trade_fair_news() -> GameEvent:
	var event := _event("evt_trade_fair_news", "EVT_TRADE_FAIR_NEWS", 0.3)
	event.cooldown_days = 20
	event.conditions = _conditions([
		EventCondition.make("destination_has_trade_fair", EventCondition.Op.LESS_EQUAL, 0.0),
	])
	event.immediate_effects = _effects([
		EventEffect.make(EventEffect.Type.WORLD_EVENT_START, 12, "trade_fair|current"),
	])
	event.choices = _choices([
		_choice("EVT_TRADE_FAIR_NEWS_OPT_HURRY", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 3),
		])),
		_choice("EVT_TRADE_FAIR_NEWS_OPT_IGNORE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, 1),
		])),
	])
	return event

## Haydut kralının haraç bölgesi - yoldaki gerçek tahsildarla karşılaşma
## ayrı bir olay (`evt_bandit_tribute_toll`), bu yalnızca haberi veriyor
## ve rota tehlikesine bir pay ekliyor.
static func _bandit_tribute_zone_news() -> GameEvent:
	var event := _event("evt_bandit_tribute_zone_news", "EVT_TRIBUTE_NEWS", 0.3)
	event.cooldown_days = 20
	event.conditions = _conditions([
		EventCondition.make("route_has_bandit_tribute", EventCondition.Op.LESS_EQUAL, 0.0),
	])
	event.immediate_effects = _effects([
		EventEffect.make(EventEffect.Type.WORLD_EVENT_START, 20, "bandit_tribute|current"),
	])
	event.choices = _choices([
		_choice("EVT_TRIBUTE_NEWS_OPT_BRACE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -3),
		])),
		_choice("EVT_TRIBUTE_NEWS_OPT_IGNORE", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -1),
		])),
	])
	return event

## Gerçek tahsildarla karşılaşma - yalnızca haraç bölgesi aktifken çekilir
## (`route_has_bandit_tribute >= 1`). Öde ya da diren: direniş gerçek
## savaşı açıyor (TRIGGER_COMBAT), pazarlık haydut pususunun kendi
## OPT_HAGGLE'ıyla aynı vokabüleri kullanmıyor çünkü burada pazarlık
## payı yok - bir haraç, teklif değil.
static func _bandit_tribute_toll() -> GameEvent:
	var event := _event("evt_bandit_tribute_toll", "EVT_TRIBUTE_TOLL", 1.6)
	event.cooldown_days = 3
	event.conditions = _conditions([
		EventCondition.make("route_has_bandit_tribute", EventCondition.Op.GREATER_EQUAL, 1.0),
	])
	event.choices = _choices([
		_gated_choice(
			"EVT_TRIBUTE_TOLL_OPT_PAY", "EVT_TRIBUTE_TOLL_OPT_PAY_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 70)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -70),
			])
		),
		_choice("EVT_TRIBUTE_TOLL_OPT_RESIST", _effects([
			EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 0, "bandit"),
		])),
	])
	return event

## Faz 18: ilk "verimli seçim, düzgün insanın yapmayacağı seçim" kartı.
## Bir köyün önünden geçerken ağır yaralı bir yoldaş: onu köylülere
## bırakmak kervanı hızlandırır ve erzak kazandırır, taşımak yavaşlatır,
## iyileştirmek pahalıdır. Aynı zamanda konak durağının ilk mekanik
## karşılığı (bkz. near_hamlet).
static func _leave_the_wounded() -> GameEvent:
	var event := _event("evt_leave_the_wounded", "EVT_LEAVE_WOUNDED", 0.3)
	event.cooldown_days = 10
	event.conditions = _conditions([
		EventCondition.make("weakest_companion_hp_ratio", EventCondition.Op.LESS_EQUAL, 0.35),
		EventCondition.make("party_size", EventCondition.Op.GREATER_EQUAL, 2),
	])
	event.weight_modifiers = _modifiers([
		EventWeightModifier.make(_conditions([
			EventCondition.make("near_hamlet", EventCondition.Op.GREATER_EQUAL, 1),
		]), 6.0),
	])
	event.choices = _choices([
		_choice("EVT_LEAVE_WOUNDED_OPT_LEAVE", _effects([
			EventEffect.make(EventEffect.Type.LEAVE_BEHIND),
			EventEffect.make(EventEffect.Type.PROVISIONS, 6),
			EventEffect.make(EventEffect.Type.STRESS, 8),
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "companion_left_behind"),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_left_behind_return"),
		])),
		_choice("EVT_LEAVE_WOUNDED_OPT_CARRY", _effects([
			EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
			EventEffect.make(EventEffect.Type.MORALE, -6),
		])),
		_gated_choice(
			"EVT_LEAVE_WOUNDED_OPT_HEALER", "EVT_LEAVE_WOUNDED_OPT_HEALER_LOCKED",
			_conditions([EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 60)]),
			_effects([
				EventEffect.make(EventEffect.Type.GOLD, -60),
				EventEffect.make(EventEffect.Type.PARTY_HP, 20, "weakest"),
			])
		),
	])
	return event

## Geride bırakılanın haberi, günler sonra. Bir fatura değil bir hesap:
## köy onu ya ayağa kaldırdı ya gömdü - oyuncu hangisi olduğunu seçmiyor.
static func _left_behind_return() -> GameEvent:
	var event := _event("evt_left_behind_return", "EVT_LEFT_BEHIND_RETURN", 3.0)
	event.triggered_only = true
	event.category = GameEvent.Category.CHAIN
	event.conditions = _conditions([
		EventCondition.make("companion_left_behind", EventCondition.Op.HAS_FLAG),
	])
	event.choices = _choices([
		_choice_with_outcomes("EVT_LEFT_BEHIND_RETURN_OPT_LISTEN", _outcomes([
			EventOutcome.make("EVT_LEFT_BEHIND_RETURN_RECOVERED", _effects([
				EventEffect.make(EventEffect.Type.STRESS, -6),
				EventEffect.make(EventEffect.Type.PROVISIONS, 4),
				EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "companion_left_behind"),
			]), 1.0),
			EventOutcome.make("EVT_LEFT_BEHIND_RETURN_BURIED", _effects([
				EventEffect.make(EventEffect.Type.STRESS, 10),
				EventEffect.make(EventEffect.Type.MORALE, -4),
				EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "companion_left_behind"),
			]), 1.0),
		])),
	])
	return event

## Krizden kâr etmenin dünyadaki hafızası (bkz. GameSession.
## profiteering_sales): vebalı ya da savaşın kestiği bir şehre şişmiş fiyatla
## mal satan kervanı bir mülteci kolu tanıyor.
static func _profiteer_recognized() -> GameEvent:
	var event := _event("evt_profiteer_recognized", "EVT_PROFITEER", 1.2)
	event.cooldown_days = 20
	event.conditions = _conditions([
		EventCondition.make("profiteering_sales", EventCondition.Op.GREATER_EQUAL, 3),
		EventCondition.make("profiteer_reckoned", EventCondition.Op.NOT_HAS_FLAG),
	])
	event.choices = _choices([
		_choice("EVT_PROFITEER_OPT_RESTITUTION", _effects([
			EventEffect.make(EventEffect.Type.GOLD, -80),
			EventEffect.make(EventEffect.Type.REPUTATION, 3),
			EventEffect.make(EventEffect.Type.STRESS, -4),
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "profiteer_reckoned"),
		])),
		_choice("EVT_PROFITEER_OPT_IGNORE", _effects([
			EventEffect.make(EventEffect.Type.REPUTATION, -4),
			EventEffect.make(EventEffect.Type.STRESS, 6),
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "profiteer_reckoned"),
		])),
	])
	return event

## Karakol durağının kartı: Zeka check'i (defterle, yazıyla tartışmak) ya
## da isimli bir bedel - en dayanıklı olan garnizonla geceyi nöbette geçirir.
static func _frontier_outpost() -> GameEvent:
	var event := _event("evt_frontier_outpost", "EVT_OUTPOST", 0.25)
	event.cooldown_days = 6
	event.weight_modifiers = _modifiers([
		EventWeightModifier.make(_conditions([
			EventCondition.make("near_outpost", EventCondition.Op.GREATER_EQUAL, 1),
		]), 6.0),
	])
	event.choices = _choices([
		_checked_choice(
			"EVT_OUTPOST_OPT_ARGUE",
			SkillCheck.make(CharacterStats.Kind.INTELLECT, SkillCheck.Source.PARTY_BEST, 0.0),
			"EVT_OUTPOST_ARGUE_GOOD", _effects([
				EventEffect.make(EventEffect.Type.REPUTATION, 2),
			]),
			"EVT_OUTPOST_ARGUE_BAD", _effects([
				EventEffect.make(EventEffect.Type.GOLD, -40),
				EventEffect.make(EventEffect.Type.REPUTATION, -1),
			])
		),
		_choice("EVT_OUTPOST_OPT_PAY", _effects([
			EventEffect.make(EventEffect.Type.GOLD, -25),
		])),
		_choice("EVT_OUTPOST_OPT_WATCH", _effects([
			EventEffect.make(EventEffect.Type.PARTY_HP, -8, "endurance"),
			EventEffect.make(EventEffect.Type.REPUTATION, 3),
			EventEffect.make(EventEffect.Type.DANGER, -5),
		])),
	])
	return event

## Maden durağının kartı: göçükte kalanlar. En dayanıklı olan şafta iner
## (Dayanıklılık check'i) - başarırsa madenciler borcunu öder, başaramazsa
## o kişi yaralı çıkar. Yürüyüp geçmek de bir seçim, sesi duyduktan sonra.
static func _mine_collapse() -> GameEvent:
	var event := _event("evt_mine_collapse", "EVT_MINE", 0.25)
	event.cooldown_days = 8
	event.weight_modifiers = _modifiers([
		EventWeightModifier.make(_conditions([
			EventCondition.make("near_mine", EventCondition.Op.GREATER_EQUAL, 1),
		]), 6.0),
	])
	event.choices = _choices([
		_checked_choice(
			"EVT_MINE_OPT_DESCEND",
			SkillCheck.make(CharacterStats.Kind.ENDURANCE, SkillCheck.Source.PARTY_BEST, 0.0),
			"EVT_MINE_DESCEND_GOOD", _effects([
				EventEffect.make(EventEffect.Type.GOLD, 60),
				EventEffect.make(EventEffect.Type.REPUTATION, 2),
			]),
			"EVT_MINE_DESCEND_BAD", _effects([
				EventEffect.make(EventEffect.Type.PARTY_HP, -15, "endurance"),
				EventEffect.make(EventEffect.Type.STRESS, 6),
			])
		),
		_choice("EVT_MINE_OPT_DIG", _effects([
			EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
			EventEffect.make(EventEffect.Type.PROVISIONS, -3),
			EventEffect.make(EventEffect.Type.REPUTATION, 3),
		])),
		_choice("EVT_MINE_OPT_WALK_ON", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -3),
			EventEffect.make(EventEffect.Type.STRESS, 3),
		])),
	])
	return event

## Köprü durağının kartı: çürümüş bir köprü. Lider ırmağı okuyup sığ bir
## geçit bulabilir (Bilgelik), en çevik olan tahtaları önce yürüyüp
## sınayabilir (isimli bir risk), ya da kervan dolaşır.
static func _failing_bridge() -> GameEvent:
	var event := _event("evt_failing_bridge", "EVT_BRIDGE", 0.25)
	event.cooldown_days = 6
	event.weight_modifiers = _modifiers([
		EventWeightModifier.make(_conditions([
			EventCondition.make("near_bridge", EventCondition.Op.GREATER_EQUAL, 1),
		]), 6.0),
	])
	event.choices = _choices([
		_checked_choice(
			"EVT_BRIDGE_OPT_FORD",
			SkillCheck.make(CharacterStats.Kind.WISDOM, SkillCheck.Source.LEADER, 0.0),
			"EVT_BRIDGE_FORD_GOOD", _effects([
				EventEffect.make(EventEffect.Type.MORALE, 2),
			]),
			"EVT_BRIDGE_FORD_BAD", _effects([
				EventEffect.make(EventEffect.Type.WAGON_DAMAGE, 1),
				EventEffect.make(EventEffect.Type.PROVISIONS, -3),
			])
		),
		_choice("EVT_BRIDGE_OPT_TEST", _effects([
			EventEffect.make(EventEffect.Type.PARTY_HP, -5, "agility"),
			EventEffect.make(EventEffect.Type.MORALE, 1),
		])),
		_choice("EVT_BRIDGE_OPT_DETOUR", _effects([
			EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
		])),
	])
	return event

## --- Zincir A: İşaretsiz Mezar ---
## Defteri okuyan ilk zincir: kervan birini gömmüşse (companions_died)
## yolda işaretsiz bir mezar çıkabilir, ve kuşak ilerledikçe daha sık
## çıkar. Mezara bakmak bir gün yer; bakıp bakmadığın mezarın bekçisi
## tarafından hatırlanır. Zincirin sonu bayrakları temizler, yani sonraki
## kuşaklar aynı yolu yeniden yürüyebilir.
static func _grave_on_the_road() -> GameEvent:
	var event := _event("evt_grave_on_the_road", "EVT_GRAVE", 0.8)
	event.cooldown_days = 20
	event.conditions = _conditions([
		EventCondition.make("companions_died", EventCondition.Op.GREATER_EQUAL, 1),
		EventCondition.make("grave_seen", EventCondition.Op.NOT_HAS_FLAG),
	])
	event.weight_modifiers = _modifiers([
		EventWeightModifier.make(_conditions([
			EventCondition.make("lineage_generation", EventCondition.Op.GREATER_EQUAL, 2),
		]), 2.0),
	])
	event.choices = _choices([
		_choice("EVT_GRAVE_OPT_TEND", _effects([
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "grave_seen"),
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "grave_tended"),
			EventEffect.make(EventEffect.Type.STRESS, -6),
			EventEffect.make(EventEffect.Type.MORALE, 4),
			EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_grave_keeper"),
		])),
		_choice("EVT_GRAVE_OPT_PASS", _effects([
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "grave_seen"),
			EventEffect.make(EventEffect.Type.STRESS, 4),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_grave_keeper"),
		])),
	])
	return event

static func _grave_keeper() -> GameEvent:
	var event := _event("evt_grave_keeper", "EVT_GRAVE_KEEPER", 3.0)
	event.triggered_only = true
	event.category = GameEvent.Category.CHAIN
	event.conditions = _conditions([
		EventCondition.make("grave_seen", EventCondition.Op.HAS_FLAG),
	])
	# Bekçiyi dinlemek Bilgelik ister; ama bekçi yalnızca mezara bakanı
	# güvenilir bulur - iyi bir dinleyici olmak geçip gitmiş olmayı silmez.
	var listen := EventChoice.new()
	listen.text_key = "EVT_GRAVE_KEEPER_OPT_LISTEN"
	listen.check = SkillCheck.make(CharacterStats.Kind.WISDOM, SkillCheck.Source.LEADER, 1.0)
	listen.outcomes = _outcomes([
		_outcome_if("EVT_GRAVE_KEEPER_TRUST", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.GREATER_EQUAL, 1.0),
			EventCondition.make("grave_tended", EventCondition.Op.HAS_FLAG),
		]), _effects([
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "keeper_trusted"),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_grave_offering"),
		])),
		_outcome_if("EVT_GRAVE_KEEPER_KIND", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.GREATER_EQUAL, 1.0),
			EventCondition.make("grave_tended", EventCondition.Op.NOT_HAS_FLAG),
		]), _effects([
			EventEffect.make(EventEffect.Type.REPUTATION, 1),
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "grave_seen"),
		])),
		_outcome_if("EVT_GRAVE_KEEPER_COLD", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.EQUAL, 0.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.STRESS, 5),
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "grave_seen"),
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "grave_tended"),
		])),
	])
	event.choices = _choices([
		listen,
		_choice("EVT_GRAVE_KEEPER_OPT_LEAVE", _effects([
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "grave_seen"),
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "grave_tended"),
		])),
	])
	return event

static func _grave_offering() -> GameEvent:
	var event := _event("evt_grave_offering", "EVT_GRAVE_OFFERING", 3.0)
	event.triggered_only = true
	event.category = GameEvent.Category.CHAIN
	event.conditions = _conditions([
		EventCondition.make("grave_seen", EventCondition.Op.HAS_FLAG),
		EventCondition.make("keeper_trusted", EventCondition.Op.HAS_FLAG),
	])
	var clear := [
		EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "grave_seen"),
		EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "grave_tended"),
		EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "keeper_trusted"),
	]
	event.choices = _choices([
		_gated_choice(
			"EVT_GRAVE_OFFERING_OPT_GIVE", "EVT_GRAVE_OFFERING_OPT_GIVE_LOCKED",
			_conditions([EventCondition.make("provisions", EventCondition.Op.GREATER_EQUAL, 5)]),
			_effects([
				EventEffect.make(EventEffect.Type.PROVISIONS, -5),
				EventEffect.make(EventEffect.Type.GRANT_TRAIT, 0, TraitCatalog.STEADFAST_FAITH),
			] + clear)
		),
		_choice("EVT_GRAVE_OFFERING_OPT_WALK", _effects(clear)),
	])
	return event

## --- Zincir B: Firariler ---
## Bölgesel savaşın yolda bir yüzü: cepheden kaçmış iki genç. Onları
## saklamak iyilik, ama devriye gelir; yalanın tutarsa bir borç doğar,
## tutmazsa kanunla dövüşürsün (muhafız zaferi itibar kaybettirir).
static func _deserter_plea() -> GameEvent:
	var event := _event("evt_deserter_plea", "EVT_DESERTER", 1.6)
	event.cooldown_days = 15
	event.conditions = _conditions([
		EventCondition.make("route_has_regional_war", EventCondition.Op.GREATER_EQUAL, 1),
		EventCondition.make("deserters_met", EventCondition.Op.NOT_HAS_FLAG),
	])
	event.choices = _choices([
		_choice("EVT_DESERTER_OPT_HIDE", _effects([
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "deserters_met"),
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "deserters_hidden"),
			EventEffect.make(EventEffect.Type.PROVISIONS, -6),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_deserter_search"),
		])),
		_choice("EVT_DESERTER_OPT_REPORT", _effects([
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "deserters_met"),
			EventEffect.make(EventEffect.Type.REPUTATION, 2),
			EventEffect.make(EventEffect.Type.STRESS, 6),
		])),
		_choice("EVT_DESERTER_OPT_REFUSE", _effects([
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "deserters_met"),
			EventEffect.make(EventEffect.Type.STRESS, 3),
		])),
	])
	return event

static func _deserter_search() -> GameEvent:
	var event := _event("evt_deserter_search", "EVT_DESERTER_SEARCH", 3.0)
	event.triggered_only = true
	event.category = GameEvent.Category.CHAIN
	event.conditions = _conditions([
		EventCondition.make("deserters_hidden", EventCondition.Op.HAS_FLAG),
	])
	var lie := _checked_choice(
		"EVT_DESERTER_SEARCH_OPT_LIE",
		SkillCheck.make(CharacterStats.Kind.CHARISMA, SkillCheck.Source.PARTY_BEST, 1.5),
		"EVT_DESERTER_SEARCH_LIE_GOOD", _effects([
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "deserters_safe"),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_deserter_debt"),
		]),
		"EVT_DESERTER_SEARCH_LIE_BAD", _effects([
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "deserters_hidden"),
			EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 0, "guard"),
		])
	)
	event.choices = _choices([
		lie,
		_choice("EVT_DESERTER_SEARCH_OPT_HANDOVER", _effects([
			EventEffect.make(EventEffect.Type.REPUTATION, 1),
			EventEffect.make(EventEffect.Type.STRESS, 8),
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "deserters_hidden"),
		])),
	])
	return event

static func _deserter_debt() -> GameEvent:
	var event := _event("evt_deserter_debt", "EVT_DESERTER_DEBT", 3.0)
	event.triggered_only = true
	event.fire_only_once = true
	event.category = GameEvent.Category.CHAIN
	event.conditions = _conditions([
		EventCondition.make("deserters_hidden", EventCondition.Op.HAS_FLAG),
		EventCondition.make("deserters_safe", EventCondition.Op.HAS_FLAG),
	])
	var clear := [
		EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "deserters_met"),
		EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "deserters_hidden"),
		EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "deserters_safe"),
	]
	event.choices = _choices([
		_gated_choice(
			"EVT_DESERTER_DEBT_OPT_JOIN", "EVT_DESERTER_DEBT_OPT_JOIN_LOCKED",
			_conditions([EventCondition.make("party_slots_free", EventCondition.Op.GREATER_EQUAL, 1)]),
			_effects([EventEffect.make(EventEffect.Type.TRIGGER_RECRUIT, 0)] + clear)
		),
		_choice("EVT_DESERTER_DEBT_OPT_GIFT", _effects([
			EventEffect.make(EventEffect.Type.GRANT_EQUIPMENT, 0, EquipmentCatalog.WEAPON_TIER_1),
		] + clear)),
	])
	return event

## --- Zincir C: Kurt Yılı ---
## Yol kenarında taze bir leş: kesip erzağa katmak cazip, ama et kokusu
## peşine sürü takar. Etin bedeli bir sonraki kartta geri ödenebilir
## (eti bırak), ya da sürüyle yüzleşmek gerekir. Zincirin sonu gerçek bir
## vahşi hayvan savaşı - ormanda üç kurtluk bir sürü (bkz. build_wildlife_
## squad'ın biyom parametresi).
static func _carcass_on_road() -> GameEvent:
	var event := _event("evt_carcass_on_road", "EVT_CARCASS", 0.9)
	event.cooldown_days = 12
	event.conditions = _conditions([
		EventCondition.make("danger", EventCondition.Op.GREATER_EQUAL, 0.3),
		EventCondition.make("wolf_scent", EventCondition.Op.NOT_HAS_FLAG),
	])
	event.choices = _choices([
		_choice("EVT_CARCASS_OPT_BUTCHER", _effects([
			EventEffect.make(EventEffect.Type.PROVISIONS, 10),
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "wolf_scent"),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_wolves_follow"),
		])),
		_choice("EVT_CARCASS_OPT_BURN", _effects([
			EventEffect.make(EventEffect.Type.MORALE, -2),
		])),
	])
	return event

static func _wolves_follow() -> GameEvent:
	var event := _event("evt_wolves_follow", "EVT_WOLVES_FOLLOW", 3.0)
	event.triggered_only = true
	event.category = GameEvent.Category.CHAIN
	event.conditions = _conditions([
		EventCondition.make("wolf_scent", EventCondition.Op.HAS_FLAG),
	])
	# Saymak sürüyü durdurmuyor, yalnızca ne geldiğini bildiriyor - zar
	# tutmazsa bir kurt gece bir koşum hayvanını yaralıyor.
	var count := _checked_choice(
		"EVT_WOLVES_FOLLOW_OPT_COUNT",
		SkillCheck.make(CharacterStats.Kind.PERCEPTION, SkillCheck.Source.LEADER, 1.0),
		"EVT_WOLVES_FOLLOW_COUNTED", _effects([
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "wolves_counted"),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_wolf_pack"),
		]),
		"EVT_WOLVES_FOLLOW_SURPRISED", _effects([
			EventEffect.make(EventEffect.Type.WAGON_DAMAGE, 1),
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "wolves_counted"),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_wolf_pack"),
		])
	)
	event.choices = _choices([
		_gated_choice(
			"EVT_WOLVES_FOLLOW_OPT_DROP", "EVT_WOLVES_FOLLOW_OPT_DROP_LOCKED",
			_conditions([EventCondition.make("provisions", EventCondition.Op.GREATER_EQUAL, 10)]),
			_effects([
				EventEffect.make(EventEffect.Type.PROVISIONS, -10),
				EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "wolf_scent"),
			])
		),
		count,
	])
	return event

static func _wolf_pack() -> GameEvent:
	var event := _event("evt_wolf_pack", "EVT_WOLF_PACK", 3.0)
	event.triggered_only = true
	event.category = GameEvent.Category.CHAIN
	event.conditions = _conditions([
		EventCondition.make("wolf_scent", EventCondition.Op.HAS_FLAG),
		EventCondition.make("wolves_counted", EventCondition.Op.HAS_FLAG),
	])
	var clear := [
		EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "wolf_scent"),
		EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "wolves_counted"),
	]
	event.choices = _choices([
		_choice("EVT_WOLF_PACK_OPT_FIGHT", _effects([
			EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 0, "wildlife"),
		] + clear)),
		_gated_choice(
			"EVT_WOLF_PACK_OPT_OX", "EVT_WOLF_PACK_OPT_OX_LOCKED",
			_conditions([EventCondition.make("wagons", EventCondition.Op.GREATER_EQUAL, 2)]),
			_effects([EventEffect.make(EventEffect.Type.WAGON_DAMAGE, 2)] + clear)
		),
	])
	return event

## --- Borç krizi ---
## Vadesi geçmiş bir borç artık yalnızca faiz ve itibar olarak işlemiyor:
## önce alacaklının atlısı gelip uyarıyor, sonra icra memurları kampa
## geliyor. Ödeme ayni (DEBT_SETTLE): erzak teslim edilir ve borçtan düşülür.
## Vagon teslimi bilerek yok - yolda kaybedilen vagonun tayfası deftere ölü
## yazılıyor, el konulan bir vagon için bu yanlış bir hatıra olurdu.
static func _creditor_rider() -> GameEvent:
	var event := _event("evt_creditor_rider", "EVT_CREDITOR", 1.5)
	event.cooldown_days = 15
	event.conditions = _conditions([
		EventCondition.make("debt_overdue", EventCondition.Op.GREATER_EQUAL, 1.0),
		EventCondition.make("debt", EventCondition.Op.GREATER_EQUAL, 150),
		EventCondition.make("creditor_warned", EventCondition.Op.NOT_HAS_FLAG),
	])
	event.choices = _choices([
		_choice("EVT_CREDITOR_OPT_PROMISE", _effects([
			EventEffect.make(EventEffect.Type.STRESS, 3),
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "creditor_warned"),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_bailiffs_at_camp"),
		])),
		_choice("EVT_CREDITOR_OPT_DISMISS", _effects([
			EventEffect.make(EventEffect.Type.REPUTATION, -1),
			EventEffect.make(EventEffect.Type.SET_FLAG, 0, "creditor_warned"),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_bailiffs_at_camp"),
		])),
	])
	return event

static func _bailiffs_at_camp() -> GameEvent:
	var event := _event("evt_bailiffs_at_camp", "EVT_BAILIFFS", 3.0)
	event.triggered_only = true
	event.category = GameEvent.Category.CHAIN
	event.conditions = _conditions([
		EventCondition.make("creditor_warned", EventCondition.Op.HAS_FLAG),
		EventCondition.make("debt_overdue", EventCondition.Op.GREATER_EQUAL, 1.0),
	])
	var plead := EventChoice.new()
	plead.text_key = "EVT_BAILIFFS_OPT_PLEAD"
	plead.check = SkillCheck.make(CharacterStats.Kind.CHARISMA, SkillCheck.Source.LEADER, 2.0)
	plead.outcomes = _outcomes([
		_outcome_if("EVT_BAILIFFS_PLEAD_FULL", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.EQUAL, 2.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "creditor_warned"),
		])),
		_outcome_if("EVT_BAILIFFS_PLEAD_NARROW", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.EQUAL, 1.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.REPUTATION, -1),
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "creditor_warned"),
		])),
		# Yalvarmak tutmazsa memurlar gitmiyor: bayrak kalıyor, bir sonraki
		# günlerde yeniden gelebilirler.
		_outcome_if("EVT_BAILIFFS_PLEAD_FAIL", _conditions([
			EventCondition.make("check_tier", EventCondition.Op.EQUAL, 0.0),
		]), _effects([
			EventEffect.make(EventEffect.Type.REPUTATION, -3),
			EventEffect.make(EventEffect.Type.STRESS, 10),
			EventEffect.make(EventEffect.Type.UNLOCK_EVENT, 0, "evt_bailiffs_at_camp"),
		])),
	])
	event.choices = _choices([
		_gated_choice(
			"EVT_BAILIFFS_OPT_STORES", "EVT_BAILIFFS_OPT_STORES_LOCKED",
			_conditions([EventCondition.make("provisions", EventCondition.Op.GREATER_EQUAL, 20)]),
			_effects([
				EventEffect.make(EventEffect.Type.PROVISIONS, -20),
				EventEffect.make(EventEffect.Type.DEBT_SETTLE, 80),
				EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "creditor_warned"),
			])
		),
		plead,
		_choice("EVT_BAILIFFS_OPT_RESIST", _effects([
			EventEffect.make(EventEffect.Type.CLEAR_FLAG, 0, "creditor_warned"),
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

## Faz 17: skill-check'e bağlı iki kademeli bir seçenek - "başarı" (kıl payı
## ya da tam, check_tier >= 1) ve "başarısızlık" (check_tier == 0). Üç
## kademeyi ayrı ayrı okumak isteyen olaylar (evt_storm, evt_forgotten_cache,
## evt_culture_port_gossip) bunu kullanmaz, `_outcome_if` ile elle üç dal
## kurar - ama ikisi de aynı vokabüleri (check_tier koşulu) okur.
static func _checked_choice(
	text_key: String, check: SkillCheck,
	success_key: String, success_effects: Array[EventEffect],
	fail_key: String, fail_effects: Array[EventEffect]
) -> EventChoice:
	var choice := EventChoice.new()
	choice.text_key = text_key
	choice.check = check
	choice.outcomes = _outcomes([
		_outcome_if(success_key, _conditions([
			EventCondition.make("check_tier", EventCondition.Op.GREATER_EQUAL, 1.0),
		]), success_effects, 1.0),
		_outcome_if(fail_key, _conditions([
			EventCondition.make("check_tier", EventCondition.Op.EQUAL, 0.0),
		]), fail_effects, 1.0),
	])
	return choice

## Koşullu sonuç: yalnızca koşulu sağlandığında çekilebilir. Mizaca
## (bkz. NpcDisposition) ve partinin kapasitesine göre dallanan olaylar
## bununla kuruluyor.
static func _outcome_if(
	text_key: String, conditions: Array[EventCondition],
	effects: Array[EventEffect], weight: float = 1.0
) -> EventOutcome:
	var outcome := EventOutcome.make(text_key, effects, weight)
	outcome.conditions = conditions
	return outcome

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
