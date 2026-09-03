extends Control

## Sefer ekranı. Kervan planlayıcıdan gerçek bir seferle gelindiğinde
## kalıcı oturumu yürütür. Sentetik (sahte) sefer yalnızca F1 geliştirici
## panelinden doğrudan açıldığında kurulur - normal oyun akışında bu
## ekrana her zaman start_journey() çağırmış bir oturumla girilir, bu
## yüzden ek bir "dev girişi" bayrağına gerek yok: is_journey_active()
## zaten aynı ayrımı yapıyor.
const SYNTHETIC_JOURNEY_DAYS: int = 8
const SYNTHETIC_DANGER: float = 0.4
const SYNTHETIC_WAGONS: int = 4
const SYNTHETIC_MERCHANTS: Array = ["Deneme Tüccarı 1", "Deneme Tüccarı 2", "Deneme Tüccarı 3"]
const SYNTHETIC_PARTY_CULTURES: Array[String] = [
	CultureCatalog.HIGHLAND, CultureCatalog.NOMAD, CultureCatalog.VALLEY,
]

const LOCKED_COLOR: Color = Color(0.65, 0.6, 0.55)
const IMMEDIATE_COLOR: Color = Color(0.95, 0.8, 0.45)
const OUTCOME_COLOR: Color = Color(0.75, 0.85, 1.0)

## Pazarlık başarısız olursa tam bedel ödenir; başarı indirim demektir.
const HAGGLE_FAIL_MORALE: int = -8
const HAGGLE_DRAIN_RATE: float = 25.0

## Savaş sonuçları. Zafer yolu bir süre güvenli kılar ve yağma getirir;
## yenilgi ağır ama kervanı bitirmez (bkz. EventEffectApplier clamp'leri).
const COMBAT_LOOT_BASE: int = 25
const COMBAT_LOOT_DANGER_BONUS: int = 60
const COMBAT_VICTORY_MORALE: int = 12
const COMBAT_VICTORY_REPUTATION: int = 4
const COMBAT_VICTORY_DANGER: int = -10
## Muhafızlara karşı kazanmak haydutlara karşı kazanmak gibi değil - kervan
## kanunla çatışmış olur, zafer bile itibarı yükseltmez, kırar (bkz.
## evt_guard_patrol, _on_combat_finished).
const GUARD_VICTORY_REPUTATION: int = -6
const COMBAT_DEFEAT_WAGON_DAMAGE: int = 2
const COMBAT_DEFEAT_MERCHANTS: int = 1
const COMBAT_DEFEAT_MORALE: int = -20
const COMBAT_DEFEAT_GOLD: int = -40
const COMBAT_STRESS_BASE: int = 8
const COMBAT_STRESS_PER_DOWN: int = 6
const COMBAT_VICTORY_STRESS_RELIEF: int = 4
const COMBAT_DEFEAT_STRESS: int = 15

## Erzak tükenince moralin yanı sıra gerginlik de yükselir.
const FAMINE_STRESS: int = 6

## Yolda karşılaşılan biri şehirdeki kadar seçici değil ama pazarlık payı
## da bırakmıyor.
const ROAD_RECRUIT_COST_MULTIPLIER: float = 1.25

var _session: GameSession
var _engine: EventEngine
var _current_event: GameEvent
var _current_combat_kind: String = "bandit"
var _current_day: int = 0
var _is_live_journey: bool = false
var _pending_haggle_max: int = 0

var _seed_spin: SpinBox
var _state_label: Label
var _card_panel: VBoxContainer
var _haggle_holder: VBoxContainer
var _combat_holder: VBoxContainer
var _recruit_holder: VBoxContainer
var _log_list: VBoxContainer
var _advance_button: Button
var _draw_button: Button
var _reset_button: Button
var _camp_button: Button
var _arrive_button: Button
var _arrival_panel: VBoxContainer
var _enter_city_button: Button

@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer

func _ready() -> void:
	_build_ui()
	_init_journey()

func _build_ui() -> void:
	var title := Label.new()
	title.text = tr("EVT_TEST_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(title)

	var controls_row := HBoxContainer.new()
	controls_row.add_theme_constant_override("separation", 8)

	var seed_label := Label.new()
	seed_label.text = "Seed:"
	controls_row.add_child(seed_label)

	_seed_spin = SpinBox.new()
	_seed_spin.min_value = 0
	_seed_spin.max_value = 999999
	_seed_spin.step = 1
	_seed_spin.value = 1234
	controls_row.add_child(_seed_spin)

	_reset_button = Button.new()
	_reset_button.text = tr("EVT_TEST_RESET")
	_reset_button.pressed.connect(_on_reset_pressed)
	controls_row.add_child(_reset_button)

	_advance_button = Button.new()
	_advance_button.text = tr("EVT_TEST_ADVANCE")
	_advance_button.pressed.connect(_on_advance_day)
	controls_row.add_child(_advance_button)

	_camp_button = Button.new()
	_camp_button.text = "Kamp Kur"
	_camp_button.tooltip_text = "Bir gün kaybedip stresi azaltır."
	_camp_button.pressed.connect(_on_camp_pressed)
	controls_row.add_child(_camp_button)

	_draw_button = Button.new()
	_draw_button.text = tr("EVT_TEST_DRAW")
	_draw_button.pressed.connect(_on_force_draw)
	controls_row.add_child(_draw_button)

	_content.add_child(controls_row)
	_content.add_child(HSeparator.new())

	var state_title := Label.new()
	state_title.text = tr("EVT_TEST_STATE")
	_content.add_child(state_title)

	_state_label = Label.new()
	_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content.add_child(_state_label)

	_content.add_child(HSeparator.new())

	_card_panel = VBoxContainer.new()
	_card_panel.add_theme_constant_override("separation", 6)
	_content.add_child(_card_panel)

	_haggle_holder = VBoxContainer.new()
	_content.add_child(_haggle_holder)

	_combat_holder = VBoxContainer.new()
	_content.add_child(_combat_holder)

	_recruit_holder = VBoxContainer.new()
	_content.add_child(_recruit_holder)

	_arrive_button = Button.new()
	_arrive_button.text = "Şehre Var"
	_arrive_button.visible = false
	_arrive_button.pressed.connect(_on_arrive_pressed)
	_content.add_child(_arrive_button)

	_arrival_panel = VBoxContainer.new()
	_arrival_panel.add_theme_constant_override("separation", 4)
	_content.add_child(_arrival_panel)

	_enter_city_button = Button.new()
	_enter_city_button.text = "Şehre Gir"
	_enter_city_button.visible = false
	_enter_city_button.pressed.connect(_on_enter_city_pressed)
	_content.add_child(_enter_city_button)

	_content.add_child(HSeparator.new())

	var log_title := Label.new()
	log_title.text = tr("EVT_TEST_LOG")
	_content.add_child(log_title)

	_log_list = VBoxContainer.new()
	_content.add_child(_log_list)

	var back_button := Button.new()
	back_button.text = Nav.return_label()
	back_button.pressed.connect(_on_back_pressed)
	_content.add_child(back_button)

func _init_journey() -> void:
	var live_session: GameSession = GameState.get_session()

	if live_session.is_journey_active():
		_is_live_journey = true
		_session = live_session
		_current_day = maxi(0, _session.journey_total_days - _session.journey_days_remaining)
		_reset_button.visible = false
		_seed_spin.editable = false
	else:
		_is_live_journey = false
		_start_synthetic_journey()

	_engine = EventEngine.new(EventCatalog.get_road_events(), int(_seed_spin.value))
	_current_event = null
	_clear_children(_card_panel)
	_clear_children(_haggle_holder)
	_clear_children(_combat_holder)
	_clear_children(_recruit_holder)
	_clear_children(_arrival_panel)
	_arrive_button.visible = false
	_enter_city_button.visible = false
	_set_journey_controls_enabled(true)
	_refresh_state()

	if _is_live_journey:
		var destination := WorldMapData.get_location_by_id(_session.journey_destination_id)
		var destination_name := "?" if destination == null else destination.location_name
		_add_log("%s yolundasın: %d gün, tehlike %d%%." % [
			destination_name,
			_session.journey_days_remaining,
			int(_session.danger_level * 100.0),
		])
	else:
		_add_log("Deneme seferi: %d gün yol, tehlike %d%%." % [
			_session.journey_days_remaining,
			int(_session.danger_level * 100.0),
		])

func _start_synthetic_journey() -> void:
	_session = GameSession.new()
	_session.journey_destination_id = WorldMapData.START_LOCATION_ID
	_session.journey_total_days = SYNTHETIC_JOURNEY_DAYS
	_session.journey_days_remaining = SYNTHETIC_JOURNEY_DAYS
	_session.danger_level = SYNTHETIC_DANGER
	_session.caravan.wagon_count = SYNTHETIC_WAGONS
	_session.caravan.documents = SYNTHETIC_WAGONS

	var merchants: Array[String] = []
	for merchant_name in SYNTHETIC_MERCHANTS:
		merchants.append(merchant_name)
	_session.caravan.merchant_names = merchants

	# Dev seferinde savaşı denemek için dolu bir kadro kurulur; gerçek
	# oyunda parti karakter oluşturma ve tayfa toplamayla büyür.
	var test_party: Array[CharacterData] = []
	for index in SYNTHETIC_PARTY_CULTURES.size():
		var culture := CultureCatalog.get_culture_or_default(SYNTHETIC_PARTY_CULTURES[index])
		test_party.append(CharacterData.create(
			culture.name_pool[index % culture.name_pool.size()],
			culture.culture_id,
			CharacterStats.new()
		))
	_session.party = test_party

	_current_day = 0

func _on_reset_pressed() -> void:
	if _is_live_journey:
		return
	_clear_children(_log_list)
	_init_journey()

func _on_advance_day() -> void:
	if _current_event != null:
		return

	_current_day += 1
	_session.journey_days_remaining = maxi(0, _session.journey_days_remaining - 1)
	_advance_contracts_and_provisions()

	var event := _engine.roll_for_day(_current_day, _session.build_event_context())
	if event == null:
		_add_log("Gün %d: %s" % [_current_day, tr("EVT_TEST_QUIET_DAY")])
	else:
		_present_event(event)

	_refresh_state()
	_check_journey_end()

## Kamp: günü ilerletir, erzak yer, ama olay çekmez - o günü dinlenerek
## geçirdiğin garanti, karşılığında stres belirgin azalır (bkz.
## GameSession.make_camp). "21. nasıl daha az maliyetli olacaksa" kararı:
## yeni bir gün döngüsü kurmak yerine mevcut gün ilerletme akışını
## paylaşıyor, yalnızca olay çekimini atlayıp kampın kendi payını ekliyor.
func _on_camp_pressed() -> void:
	if _current_event != null:
		return

	_current_day += 1
	_session.journey_days_remaining = maxi(0, _session.journey_days_remaining - 1)
	_advance_contracts_and_provisions()

	var camp_result := _session.make_camp()
	_add_log(
		"Gün %d: Kamp kuruldu (erzak -%d), kadro biraz soluklandı (stres -%d)." % [
			_current_day, camp_result.provisions_spent, camp_result.stress_relief
		],
		OUTCOME_COLOR
	)

	_refresh_state()
	_check_journey_end()

func _advance_contracts_and_provisions() -> void:
	var expired_contracts := _session.advance_day()
	for _merchant_id in expired_contracts:
		_add_log("Loncadaki bir kontratın süresi doldu, itibarın düştü.")

	# Yol her gün erzak yer: parti büyüdükçe saat daha hızlı işler.
	# Göçebe kültürü az yer (bkz. Culture.daily_provision_multiplier).
	var daily_consumption := 1 + _session.caravan.merchant_names.size()
	daily_consumption = maxi(1, int(round(daily_consumption * _session.get_daily_provision_multiplier())))
	# Levazımcı ölçülü dağıtır: gücüne göre günlük tüketimden düşer.
	daily_consumption = maxi(1, daily_consumption - _session.get_duty_flat_reduction(DutyCatalog.LEVAZIMCI))
	_session.change_provisions(-daily_consumption)
	if _session.get_provisions() <= 0:
		_session.caravan.change_morale(-10)
		_session.change_stress(FAMINE_STRESS)
		_add_log("Gün %d: Erzak tükendi, moral düşüyor." % _current_day)

func _on_force_draw() -> void:
	if _current_event != null:
		return

	var event := _engine.draw_event(_current_day, _session.build_event_context())
	if event == null:
		_add_log(tr("EVT_TEST_NO_EVENT"))
		return
	_present_event(event)

func _present_event(event: GameEvent) -> void:
	_current_event = event
	_engine.mark_fired(event, _current_day)
	EventBus.road_event_fired.emit(event)

	_add_log("── %s" % tr(event.title_key))

	if not event.immediate_effects.is_empty():
		var immediate := EventEffectApplier.apply(event.immediate_effects, _session)
		_apply_side_channels(immediate)
		for line in immediate.lines:
			_add_log("   %s" % line, IMMEDIATE_COLOR)

	_render_card(event)
	_refresh_state()

func _render_card(event: GameEvent) -> void:
	_clear_children(_card_panel)

	var title := Label.new()
	title.text = tr(event.title_key)
	_card_panel.add_child(title)

	var body := Label.new()
	body.text = tr(event.text_key)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	_card_panel.add_child(body)

	var context := _session.build_event_context()
	for choice in event.choices:
		_card_panel.add_child(_build_choice_button(choice, context))

func _build_choice_button(choice: EventChoice, context: Dictionary) -> Button:
	var button := Button.new()
	var available := choice.is_available(context)

	if available:
		button.text = tr(choice.text_key)
		button.pressed.connect(_on_choice_pressed.bind(choice))
	else:
		# Kilitli seçenek gizlenmez: oyuncu neyi kaçırdığını görsün.
		button.text = "%s — %s" % [tr(choice.text_key), tr(choice.unavailable_text_key)]
		button.disabled = true
		button.modulate = LOCKED_COLOR

	return button

func _on_choice_pressed(choice: EventChoice) -> void:
	var resolved_event := _current_event
	_current_event = null
	_clear_children(_card_panel)

	_add_log("   → %s" % tr(choice.text_key))

	if not choice.effects.is_empty():
		var result := EventEffectApplier.apply(choice.effects, _session)
		_apply_side_channels(result)
		for line in result.lines:
			_add_log("      %s" % line)

	var outcome := _engine.resolve_outcome(choice, _session.build_event_context())
	if outcome != null:
		_add_log("   %s" % tr(outcome.text_key), OUTCOME_COLOR)
		var outcome_result := EventEffectApplier.apply(outcome.effects, _session)
		_apply_side_channels(outcome_result)
		for line in outcome_result.lines:
			_add_log("      %s" % line)

	if resolved_event.xp_value > 0:
		_session.grant_party_xp(resolved_event.xp_value)

	EventBus.road_event_resolved.emit(resolved_event, choice)
	_refresh_state()
	_check_journey_end()

func _apply_side_channels(result: EventEffectApplier.Result) -> void:
	for event_id in result.unlocked_event_ids:
		_engine.unlock_event(event_id)
		_add_log("      (yeni olay açıldı)")

	if not result.combat_requests.is_empty():
		var enemy_kind := "bandit"
		if not result.combat_kinds.is_empty():
			enemy_kind = result.combat_kinds[0]
		_open_combat(int(result.combat_requests[0]), enemy_kind)
		return

	if not result.recruit_requests.is_empty():
		_open_recruit_offer()
		return

	if not result.haggling_requests.is_empty():
		_open_haggling(int(result.haggling_requests[0]))

## Yolda karşılaşılan biri partiye katılmayı teklif ediyor. Şehirdeki
## tayfa ekranıyla aynı havuzdan (RecruitCatalog) üretiliyor, yalnızca
## teklif tek kişilik ve anlık.
func _open_recruit_offer() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d|%d" % [int(_seed_spin.value), _current_day])
	var candidates := RecruitCatalog.build_candidates(
		RecruitCatalog.VENUE_TAVERN, rng, _session.get_player_character().level
	)
	if candidates.is_empty() or not _session.can_recruit():
		_add_log("      Yolcu fikrini değiştirdi ve yoluna gitti.")
		return

	var candidate := candidates[0]
	# Yolda pazarlık gücü yok: ücret şehirdekinden biraz yüksek.
	candidate.hire_cost = int(round(candidate.hire_cost * ROAD_RECRUIT_COST_MULTIPLIER))

	_set_journey_controls_enabled(false)
	_clear_children(_recruit_holder)

	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.text = "%s — can %d · isabet %d · kaçınma %d — %d GG istiyor." % [
		candidate.get_summary_line(),
		candidate.get_max_hp(),
		candidate.get_accuracy(),
		candidate.get_dodge(),
		candidate.hire_cost,
	]
	_recruit_holder.add_child(info)

	var hire_button := Button.new()
	if _session.wallet.can_afford(candidate.hire_cost):
		hire_button.text = "Partiye Kat (%d GG)" % candidate.hire_cost
		hire_button.pressed.connect(_on_road_recruit_accepted.bind(candidate))
	else:
		hire_button.text = "Kese yetmiyor"
		hire_button.disabled = true
		hire_button.modulate = LOCKED_COLOR
	_recruit_holder.add_child(hire_button)

	var decline_button := Button.new()
	decline_button.text = "Vazgeç"
	decline_button.pressed.connect(_on_road_recruit_declined)
	_recruit_holder.add_child(decline_button)

func _on_road_recruit_accepted(candidate: CharacterData) -> void:
	if _session.recruit(candidate):
		_add_log("      %s partine katıldı." % candidate.character_name, OUTCOME_COLOR)
	_close_recruit_offer()

func _on_road_recruit_declined() -> void:
	_add_log("      Yolcuyla yollarınız ayrıldı.")
	_close_recruit_offer()

func _close_recruit_offer() -> void:
	_clear_children(_recruit_holder)
	_set_journey_controls_enabled(true)
	_refresh_state()
	_check_journey_end()

## Bir olay savaş istediğinde Darkest Dungeon tarzı panel açılır; sonuç
## kervana etkilerle yansır. Panel açıkken gün ilerletilemez.
## enemy_kind EnemyCatalog.build_squad'ın kadro türü (bkz. EventEffect.Type.
## TRIGGER_COMBAT'in text_value'su); bölge (bkz. EnemyCatalog.build_bandit_squad'ın
## region_id'si) sefer hedefinden okunuyor - haydut kadrosu gidilen yöreye
## göre reskin oluyor.
func _open_combat(danger_percent: int, enemy_kind: String = "bandit") -> void:
	var danger := _session.danger_level if danger_percent <= 0 else danger_percent / 100.0
	_current_combat_kind = enemy_kind
	_set_journey_controls_enabled(false)
	_clear_children(_combat_holder)

	var panel := CombatPanel.new()
	_combat_holder.add_child(panel)
	panel.combat_finished.connect(_on_combat_finished)
	panel.start_combat(
		_session.get_party(), danger, null, _session.party_stress,
		enemy_kind, _session.journey_destination_id
	)

func _on_combat_finished(victory: bool, xp_awarded: int, downed_count: int) -> void:
	if xp_awarded > 0:
		_session.grant_party_xp(xp_awarded)
		_add_log("      Kadro %d tecrübe kazandı." % xp_awarded, OUTCOME_COLOR)

	# Her çarpışma bir miktar gerginlik bırakır; düşen her yoldaş bunu
	# katlar. Zafer bunu biraz yumuşatır, yenilgi daha da ağırlaştırır.
	var stress_delta := COMBAT_STRESS_BASE + downed_count * COMBAT_STRESS_PER_DOWN
	stress_delta += -COMBAT_VICTORY_STRESS_RELIEF if victory else COMBAT_DEFEAT_STRESS

	var effects: Array[EventEffect] = [
		EventEffect.make(EventEffect.Type.STRESS, stress_delta),
	]
	if victory:
		var loot := COMBAT_LOOT_BASE + int(round(_session.danger_level * COMBAT_LOOT_DANGER_BONUS))
		effects.append(EventEffect.make(EventEffect.Type.GOLD, loot))
		effects.append(EventEffect.make(EventEffect.Type.MORALE, COMBAT_VICTORY_MORALE))
		var reputation_delta := GUARD_VICTORY_REPUTATION if _current_combat_kind == "guard" else COMBAT_VICTORY_REPUTATION
		effects.append(EventEffect.make(EventEffect.Type.REPUTATION, reputation_delta))
		effects.append(EventEffect.make(EventEffect.Type.DANGER, COMBAT_VICTORY_DANGER))
	else:
		effects.append(EventEffect.make(EventEffect.Type.GOLD, COMBAT_DEFEAT_GOLD))
		effects.append(EventEffect.make(EventEffect.Type.WAGON_DAMAGE, COMBAT_DEFEAT_WAGON_DAMAGE))
		effects.append(EventEffect.make(EventEffect.Type.MERCHANT_LEAVE, COMBAT_DEFEAT_MERCHANTS))
		effects.append(EventEffect.make(EventEffect.Type.MORALE, COMBAT_DEFEAT_MORALE))

	var result := EventEffectApplier.apply(effects, _session)
	for line in result.lines:
		_add_log("      %s" % line, OUTCOME_COLOR if victory else LOCKED_COLOR)

	_clear_children(_combat_holder)
	_set_journey_controls_enabled(true)
	_refresh_state()
	_check_journey_end()

## Bir olay pazarlık istediğinde gerçek pazarlık paneli açılır:
## anlaşırsan anlaştığın fiyatı, anlaşamazsan tam bedeli ödersin.
func _open_haggling(max_price: int) -> void:
	_pending_haggle_max = max_price
	_set_journey_controls_enabled(false)
	_clear_children(_haggle_holder)

	var intro := Label.new()
	intro.text = "Pazarlık: karşı taraf %d GG istiyor." % max_price
	_haggle_holder.add_child(intro)

	var panel := HagglingPanel.new()
	_haggle_holder.add_child(panel)
	panel.deal_made.connect(_on_haggle_deal)
	panel.haggling_failed.connect(_on_haggle_failed)
	panel.start_haggling(float(max_price), 0.5, 0.3, 0, 0, HAGGLE_DRAIN_RATE, false)

func _on_haggle_deal(price: int) -> void:
	var paid := mini(price, _session.wallet.balance)
	if paid > 0:
		_session.wallet.spend(paid)
	_add_log("      Pazarlık tuttu: %d GG ödendi." % paid, OUTCOME_COLOR)
	_close_haggling()

func _on_haggle_failed() -> void:
	var paid := mini(_pending_haggle_max, _session.wallet.balance)
	if paid > 0:
		_session.wallet.spend(paid)
	_session.caravan.change_morale(HAGGLE_FAIL_MORALE)
	_add_log("      Pazarlık koptu: tam bedel %d GG ödendi." % paid)
	_close_haggling()

func _close_haggling() -> void:
	_clear_children(_haggle_holder)
	_pending_haggle_max = 0
	_set_journey_controls_enabled(true)
	_refresh_state()
	_check_journey_end()

func _check_journey_end() -> void:
	if _session.journey_days_remaining <= 0 and _current_event == null:
		_finish_journey()

func _finish_journey() -> void:
	_set_journey_controls_enabled(false)
	_add_log("Sefer tamamlandı. %d gün sürdü." % _current_day)
	EventBus.journey_finished.emit(_current_day)

	if _is_live_journey:
		_arrive_button.visible = true

func _on_arrive_pressed() -> void:
	var payout: Dictionary = _session.finish_journey()
	_arrive_button.visible = false
	_render_arrival_summary(payout)
	EventBus.caravan_changed.emit()

	# Sefer içinde kayıt yok: yolda alınan riskin geri alınamaması
	# olayları anlamlı kılıyor. Sentetik dev seferi gerçek kaydı kirletmez.
	if _is_live_journey:
		SaveManager.save_session(_session)

	_enter_city_button.visible = true

func _render_arrival_summary(payout: Dictionary) -> void:
	_clear_children(_arrival_panel)

	var title := Label.new()
	title.text = "Varış: Sefer Kazancı"
	_arrival_panel.add_child(title)

	_arrival_panel.add_child(_make_summary_label(
		"Escort ücreti (brüt): %d GG" % payout.gross
	))
	_arrival_panel.add_child(_make_summary_label(
		"Moral çarpanı: %d%%" % int(round(payout.morale_factor * 100.0))
	))
	_arrival_panel.add_child(_make_summary_label(
		"Hasar çarpanı: %d%%" % int(round(payout.damage_factor * 100.0))
	))

	var net_label := _make_summary_label("Net kazanç: %d GG" % payout.net)
	net_label.modulate = OUTCOME_COLOR
	_arrival_panel.add_child(net_label)

	var xp_awarded: int = payout.get("xp_awarded", 0)
	if xp_awarded > 0:
		var xp_label := _make_summary_label("Sefer tecrübesi: %d XP" % xp_awarded)
		xp_label.modulate = OUTCOME_COLOR
		_arrival_panel.add_child(xp_label)

	var lost_contracts: int = payout.get("lost_contracts", 0)
	if lost_contracts > 0:
		var penalty_label := _make_summary_label(
			"Teslim edilemeyen kontrat: %d (itibar -%d)" % [
				lost_contracts, lost_contracts * GameSession.REPUTATION_PENALTY_PER_LOST_CONTRACT
			]
		)
		penalty_label.modulate = LOCKED_COLOR
		_arrival_panel.add_child(penalty_label)

	for entry in (payout.get("stress_breaks", []) as Array):
		var break_data: Dictionary = entry
		var break_label := _make_summary_label(_stress_break_line(break_data))
		break_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		break_label.modulate = LOCKED_COLOR if break_data.affliction else OUTCOME_COLOR
		_arrival_panel.add_child(break_label)

	_add_log("Şehre varıldı. Net kazanç: %d GG." % payout.net, OUTCOME_COLOR)

## Kırılan bir yoldaşın varış özetindeki tek satırlık dökümü - huy
## kazandıysa adı, ayrıldıysa bunun da belirtilmesi lazım, oyuncu neden
## bir yoldaşını kaybettiğini anlasın.
func _stress_break_line(break_data: Dictionary) -> String:
	var character_name: String = break_data.character_name
	var trait_id: String = break_data.trait_id
	var trait_resource := TraitCatalog.get_trait(trait_id) if not trait_id.is_empty() else null
	var trait_note := " (%s)" % trait_resource.display_name if trait_resource != null else ""

	if break_data.departed:
		return "%s stresten kırıldı ve kervandan ayrıldı%s." % [character_name, trait_note]
	if trait_resource != null:
		var kind := "olumlu bir" if trait_resource.is_positive else "yeni bir"
		return "%s stresten kırıldı, %s huy edindi%s." % [character_name, kind, trait_note]
	return "%s stresten kırıldı." % character_name

func _make_summary_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label

func _on_enter_city_pressed() -> void:
	Nav.return_scene = Nav.CITY_MAP

	if _session.has_reached_goal():
		_session.set_flag(GameSession.GOAL_FLAG)
		if _is_live_journey:
			SaveManager.save_session(_session)
		get_tree().change_scene_to_file(Nav.GOAL_REACHED)
		return

	get_tree().change_scene_to_file(Nav.CITY_MAP)

func _set_journey_controls_enabled(enabled: bool) -> void:
	_advance_button.disabled = not enabled
	_draw_button.disabled = not enabled
	_camp_button.disabled = not enabled

func _refresh_state() -> void:
	var caravan := _session.caravan
	_state_label.text = "Gün %d · Kalan yol: %d gün · Tehlike: %d%%\nAltın: %d GG · Erzak: %d · İtibar: %d\nVagon: %d (%d hasarlı) · Tüccar: %d · Evrak: %d · Moral: %d · Stres: %d" % [
		_current_day,
		_session.journey_days_remaining,
		int(_session.danger_level * 100.0),
		_session.wallet.balance,
		_session.get_provisions(),
		_session.reputation,
		caravan.wagon_count,
		caravan.damaged_wagons,
		caravan.merchant_names.size(),
		caravan.documents,
		caravan.morale,
		_session.party_stress,
	]

func _add_log(text: String, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	if color != Color.WHITE:
		label.modulate = color
	_log_list.add_child(label)

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.return_scene)
