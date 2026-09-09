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
## Sentetik tüccarlar yalnızca F1 sahte seferinde görünür ama yine de
## ekrana basılıyor, o yüzden isimleri de çeviriden geliyor (bkz.
## test_localization.gd sabit metin taraması). Sayı çalışma anında
## ekleniyor, üç ayrı anahtar açmaya değmez.
const SYNTHETIC_MERCHANT_COUNT: int = 3
const SYNTHETIC_PARTY_CULTURES: Array[String] = [
	CultureCatalog.HIGHLAND, CultureCatalog.NOMAD, CultureCatalog.VALLEY,
]

const LOCKED_COLOR: Color = Color(0.65, 0.6, 0.55)
const IMMEDIATE_COLOR: Color = Color(0.95, 0.8, 0.45)
const OUTCOME_COLOR: Color = Color(0.75, 0.85, 1.0)

## Pazarlık başarısız olursa tam bedel ödenir; başarı indirim demektir.
const HAGGLE_FAIL_MORALE: int = -8

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

## Yol artık tuşla değil akan zamanla ilerliyor (bkz. JourneyClock). Aşağıdaki
## süreler olayların "arka planda zamandan yemesi" içindir: bir olay kartını
## çözmek yolun bir parçasını tüketir, çarpışma daha fazlasını.
const EVENT_HOURS: float = 1.5
const COMBAT_HOURS: float = 2.5
const HAGGLE_HOURS: float = 1.0
const RECRUIT_HOURS: float = 0.5

## Kamp anlık bir tuş değil, yaşanan bir durum: ateş yanar, zaman akmaya
## devam eder ve sabah olunca kamp kendiliğinden kalkar. Faydası (erzak
## bedeli + stres rahatlaması) kalkarken uygulanır.
const CAMP_HOURS: float = 8.0

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
## Varış bir kez işlenir - bkz. _check_journey_end.
var _journey_finished: bool = false

var _clock: JourneyClock
var _band: TravelBand
var _camping: bool = false
var _camp_ends_at_hours: float = 0.0
## Seferin toplam gün uzunluğu - ilerleme çubuğu bunun üzerinden hesaplanır.
var _journey_length_days: int = 1

var _clock_label: Label
var _speed_button: Button
var _progress_bar: ProgressBar

var _seed_spin: SpinBox
var _state_label: Label
var _card_panel: VBoxContainer
var _haggle_holder: VBoxContainer
var _combat_holder: VBoxContainer
var _recruit_holder: VBoxContainer
var _replan_holder: VBoxContainer
var _replan_button: Button
var _log_list: VBoxContainer
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

	# Manzara şeridi: gökyüzü/zemin günün evresine göre değişir, dünya
	# kervanın altından akar (bkz. TravelBand).
	_band = TravelBand.new()
	_band.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(_band)

	var time_row := HBoxContainer.new()
	time_row.add_theme_constant_override("separation", 10)

	_clock_label = Label.new()
	_clock_label.custom_minimum_size = Vector2(210.0, 0.0)
	time_row.add_child(_clock_label)

	# Zaman artık tuşla değil kendiliğinden akıyor; oyuncunun tek kontrolü
	# ne kadar hızlı aktığı (bkz. JourneyClock.SPEEDS).
	_speed_button = Button.new()
	_speed_button.tooltip_text = tr("UI_ROAD_SPEED_TOOLTIP")
	_speed_button.pressed.connect(_on_speed_pressed)
	time_row.add_child(_speed_button)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.step = 0.001
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(200.0, 0.0)
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_row.add_child(_progress_bar)

	_content.add_child(time_row)

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

	_camp_button = Button.new()
	_camp_button.text = tr("UI_ROAD_MAKE_CAMP")
	_camp_button.tooltip_text = tr("UI_ROAD_CAMP_TOOLTIP")
	_camp_button.pressed.connect(_on_camp_pressed)
	controls_row.add_child(_camp_button)

	_replan_button = Button.new()
	_replan_button.text = tr("UI_ROAD_REPLAN")
	_replan_button.tooltip_text = tr("UI_ROAD_REPLAN_TOOLTIP")
	_replan_button.pressed.connect(_on_replan_pressed)
	controls_row.add_child(_replan_button)

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

	_replan_holder = VBoxContainer.new()
	_replan_holder.add_theme_constant_override("separation", 4)
	_content.add_child(_replan_holder)

	_arrive_button = Button.new()
	_arrive_button.text = tr("UI_ROAD_ARRIVE")
	_arrive_button.visible = false
	_arrive_button.pressed.connect(_on_arrive_pressed)
	_content.add_child(_arrive_button)

	_arrival_panel = VBoxContainer.new()
	_arrival_panel.add_theme_constant_override("separation", 4)
	_content.add_child(_arrival_panel)

	_enter_city_button = Button.new()
	_enter_city_button.text = tr("UI_ROAD_ENTER_CITY")
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
	_journey_finished = false

	# Saat sefer başına sıfırlanır: gün sayısı ve evre buradan akar.
	_clock = JourneyClock.new()
	_journey_length_days = maxi(1, _session.journey_total_days)
	_camping = false
	_band.set_camping(false)
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
		_add_log(tr("UI_ROAD_DEPART") % [
			destination_name,
			_session.journey_days_remaining,
			int(_session.danger_level * 100.0),
		])
	else:
		_add_log(tr("UI_ROAD_SYNTHETIC") % [
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
	for index in SYNTHETIC_MERCHANT_COUNT:
		merchants.append(tr("UI_ROAD_SYNTHETIC_MERCHANT") % (index + 1))
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

## Zaman akıyor: her karede saat ilerler, dolan her gün için günlük mekanik
## (erzak, kontrat, olay) bir kez işler. Bir karede birden fazla gün
## geçebilir (3x hızda ya da uzun bir olaydan sonra), o yüzden döngü.
##
## Ortada çözülmemiş bir olay ya da açık bir panel varsa zaman durur -
## oyuncu karar verirken kervan yol almamalı.
func _process(delta: float) -> void:
	if _clock == null:
		return

	if _can_time_flow():
		_clock.advance(delta)
		_process_elapsed_days()
		_update_camp_state()

	_refresh_time_ui()

func _can_time_flow() -> bool:
	return not _journey_finished and _current_event == null and not _has_open_panel()

func _process_elapsed_days() -> void:
	var days := _clock.take_elapsed_days()
	for _index in days:
		if _journey_finished:
			return
		_run_day()
		# Gün içinde bir olay çıktıysa kalan günler beklemeli: oyuncu karar
		# verene kadar kervan ilerlemez.
		if _current_event != null or _has_open_panel():
			return

func _run_day() -> void:
	_current_day += 1
	_session.journey_days_remaining = maxi(0, _session.journey_days_remaining - 1)
	_advance_contracts_and_provisions()

	var event := _engine.roll_for_day(_current_day, _session.build_event_context())
	if event == null:
		_add_log(tr("UI_ROAD_DAY_LINE") % [_current_day, tr("EVT_TEST_QUIET_DAY")])
	else:
		_present_event(event)

	_refresh_state()
	_check_journey_end()

func _on_speed_pressed() -> void:
	_clock.cycle_speed()
	_refresh_time_ui()

## Kamp bir tuş değil bir durum: ateş yanar, zaman akmaya devam eder,
## süre dolunca kendiliğinden kalkar ve faydası o an uygulanır.
func _update_camp_state() -> void:
	if not _camping or _clock.total_hours < _camp_ends_at_hours:
		return

	var camp_result := _session.make_camp()
	_add_log(
		tr("UI_ROAD_CAMP_STRUCK") % [
			camp_result.provisions_spent, camp_result.stress_relief
		],
		OUTCOME_COLOR
	)
	_camping = false
	_band.set_camping(false)
	_refresh_state()

func _refresh_time_ui() -> void:
	if _clock == null:
		return

	var phase := _clock.get_phase()
	_band.set_phase(phase, _clock.get_phase_progress())
	_band.set_route_progress(_get_route_progress())

	# Metin her karede yeniden kurulmuyor: saat dakikada bir, hız yalnızca
	# değişince. Bunlar _process'ten çağrıldığı için her karede string
	# biçimlendirmek boşuna tahsisat olurdu.
	var clock_text := tr("UI_ROAD_CLOCK") % [
		_current_day + 1, _clock.get_clock_text(), tr(JourneyClock.get_phase_key(phase))
	]
	if clock_text != _clock_label.text:
		_clock_label.text = clock_text

	var speed_text := "%sx" % String.num(_clock.get_speed(), 1).trim_suffix(".0")
	if speed_text != _speed_button.text:
		_speed_button.text = speed_text

	_progress_bar.value = _get_route_progress()

	# Kamp yalnızca hava kararınca anlamlı; gündüz durup ateş yakmak
	# kervanı yavaşlatmaktan başka işe yaramaz.
	_camp_button.disabled = (
		_camping or not _clock.is_camp_time() or not _can_time_flow()
	)

func _get_route_progress() -> float:
	if _journey_length_days <= 0:
		return 1.0
	var travelled := float(_journey_length_days - _session.journey_days_remaining)
	return clampf(travelled / float(_journey_length_days), 0.0, 1.0)

## Kamp: günü ilerletir, erzak yer, ama olay çekmez - o günü dinlenerek
## geçirdiğin garanti, karşılığında stres belirgin azalır (bkz.
## GameSession.make_camp). "21. nasıl daha az maliyetli olacaksa" kararı:
## yeni bir gün döngüsü kurmak yerine mevcut gün ilerletme akışını
## paylaşıyor, yalnızca olay çekimini atlayıp kampın kendi payını ekliyor.
func _on_camp_pressed() -> void:
	if _camping or _current_event != null or not _clock.is_camp_time():
		return

	# Kamp anlık bir kazanç değil, geçirilen bir süre: ateş yanar, zaman
	# akmaya devam eder (oyuncu isterse hızlandırır) ve süre dolunca
	# _update_camp_state faydayı uygular. Gün ilerlemesi kendiliğinden
	# olur - saat gece yarısını geçince günlük mekanik zaten işler.
	_camping = true
	_camp_ends_at_hours = _clock.total_hours + CAMP_HOURS
	_band.set_camping(true)
	_add_log(tr("UI_ROAD_CAMP_LIT"), OUTCOME_COLOR)
	_refresh_state()

func _advance_contracts_and_provisions() -> void:
	var expired_contracts := _session.advance_day()
	for _merchant_id in expired_contracts:
		_add_log(tr("UI_ROAD_CONTRACT_EXPIRED"))

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
		_add_log(tr("UI_ROAD_FAMINE") % _current_day)

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
	# Olay arka planda zamandan yer: kervan kartı çözerken duruyor,
	# saat ilerliyor, arka plan da buna göre değişiyor.
	_clock.consume_hours(EVENT_HOURS)
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
		_add_log(tr("UI_ROAD_EVENT_UNLOCKED"))

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
	_clock.consume_hours(RECRUIT_HOURS)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d|%d" % [int(_seed_spin.value), _current_day])
	var candidates := RecruitCatalog.build_candidates(
		RecruitCatalog.VENUE_TAVERN, rng, _session.get_player_character().level
	)
	if candidates.is_empty() or not _session.can_recruit():
		_add_log(tr("UI_ROAD_TRAVELLER_LEFT"))
		return

	var candidate := candidates[0]
	# Yolda pazarlık gücü yok: ücret şehirdekinden biraz yüksek.
	candidate.hire_cost = int(round(candidate.hire_cost * ROAD_RECRUIT_COST_MULTIPLIER))

	_set_journey_controls_enabled(false)
	_clear_children(_recruit_holder)

	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.text = tr("UI_ROAD_RECRUIT_OFFER") % [
		candidate.get_summary_line(),
		candidate.get_max_hp(),
		candidate.get_accuracy(),
		candidate.get_dodge(),
		candidate.hire_cost,
	]
	_recruit_holder.add_child(info)

	var hire_button := Button.new()
	if _session.wallet.can_afford(candidate.hire_cost):
		hire_button.text = tr("UI_ROAD_RECRUIT_ACCEPT") % candidate.hire_cost
		hire_button.pressed.connect(_on_road_recruit_accepted.bind(candidate))
	else:
		hire_button.text = tr("UI_NOT_ENOUGH_GOLD")
		hire_button.disabled = true
		hire_button.modulate = LOCKED_COLOR
	_recruit_holder.add_child(hire_button)

	var decline_button := Button.new()
	decline_button.text = tr("UI_CANCEL")
	decline_button.pressed.connect(_on_road_recruit_declined)
	_recruit_holder.add_child(decline_button)

func _on_road_recruit_accepted(candidate: CharacterData) -> void:
	if _session.recruit(candidate):
		_add_log(tr("UI_ROAD_RECRUIT_JOINED") % candidate.character_name, OUTCOME_COLOR)
	_close_recruit_offer()

func _on_road_recruit_declined() -> void:
	_add_log(tr("UI_ROAD_RECRUIT_DECLINED"))
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
	_clock.consume_hours(COMBAT_HOURS)
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
		_add_log(tr("UI_ROAD_PARTY_XP") % xp_awarded, OUTCOME_COLOR)

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
	_clock.consume_hours(HAGGLE_HOURS)
	_set_journey_controls_enabled(false)
	_clear_children(_haggle_holder)

	var intro := Label.new()
	intro.text = tr("UI_ROAD_HAGGLE_INTRO") % max_price
	_haggle_holder.add_child(intro)

	var panel := HagglingPanel.new()
	_haggle_holder.add_child(panel)
	panel.deal_made.connect(_on_haggle_deal)
	panel.haggling_failed.connect(_on_haggle_failed)
	panel.start_haggling(
		float(max_price),
		0.5,
		0.3,
		_session.get_best_effective_stat(CharacterStats.Kind.INTELLECT),
		_session.get_best_effective_stat(CharacterStats.Kind.CHARISMA),
		false
	)

## Anlaşılan bedel kesende yoksa da ödenir: fark açık hesaba yazılır
## (bkz. GameSession.spend_or_owe). Eskiden "kasada ne varsa o kadarı"
## alınıyordu - parası olmayan kervan haraçtan bedavaya kurtuluyordu.
func _on_haggle_deal(price: int) -> void:
	_session.spend_or_owe(price)
	_add_log(tr("UI_ROAD_HAGGLE_WON") % price, OUTCOME_COLOR)
	_close_haggling()

## Yolda pazarlık koparsa itibar cezası yok: karşındaki haydut, kasabada
## kimseye şikâyet etmeyecek (bkz. HagglingPanel.haggling_failed). Bedel
## burada tam haracı ödemek - ve ödeyecek paran yoksa borçlanmak.
func _on_haggle_failed(_reputation_penalty: int) -> void:
	var paid := _pending_haggle_max
	_session.spend_or_owe(paid)
	_session.caravan.change_morale(HAGGLE_FAIL_MORALE)
	_add_log(tr("UI_ROAD_HAGGLE_LOST") % paid)
	_close_haggling()

func _close_haggling() -> void:
	_clear_children(_haggle_holder)
	_pending_haggle_max = 0
	_set_journey_controls_enabled(true)
	_refresh_state()
	_check_journey_end()

## Sefer yalnızca ortada çözülmemiş bir olay ve açık bir yan kanal paneli
## (savaş/pazarlık/tayfa) yokken bitebilir.
##
## Yan kanal kontrolü olmadan şu zincir işliyordu: son gün bir olay çıkıp
## oyuncu "Direnç göster" derse _on_choice_pressed savaşı açıyor, sonra
## aynı çağrının sonunda buraya geliyor - _current_event çoktan null
## olduğu için sefer bitmiş sayılıyor ve savaş paneli ekrandayken "Şehre
## Var" beliriyordu. Oyuncu varınca finish_journey() kervanı sıfırlayıp
## ödemeyi yapıp kaydediyor; ardından savaş bitince ödülleri (altın,
## moral, itibar) kapanmış bir sefere uygulanıyor ve buradan ikinci kez
## _finish_journey() çağrılıp varış bir daha işlenebiliyordu - ikinci bir
## kırılma zarı ve ikinci bir kayıt dahil.
func _check_journey_end() -> void:
	if _journey_finished or _current_event != null or _has_open_panel():
		return
	if _session.journey_days_remaining <= 0:
		_finish_journey()

func _has_open_panel() -> bool:
	return (
		_combat_holder.get_child_count() > 0
		or _haggle_holder.get_child_count() > 0
		or _recruit_holder.get_child_count() > 0
		or _replan_holder.get_child_count() > 0
	)

## --- Yolda planı değiştirmek ---
## Şehirde kurulan plan bir niyet, bir taahhüt değil: geçit kapanır, erzak
## biter, kervan hırpalanır ve hedef değişir. Karar verirken zaman durur
## (bkz. _can_time_flow → _has_open_panel), kararın kendisi zaman yer -
## kervanı döndürmek bedava değil.
const REPLAN_HOURS: float = 2.0

func _on_replan_pressed() -> void:
	if _journey_finished or _current_event != null or _has_open_panel():
		return
	_set_journey_controls_enabled(false)
	_build_replan_panel()

func _build_replan_panel() -> void:
	_clear_children(_replan_holder)

	var title := Label.new()
	var destination := WorldMapData.get_location_by_id(_session.journey_destination_id)
	title.text = tr("UI_ROAD_REPLAN_TITLE") % [
		destination.location_name if destination != null else _session.journey_destination_id,
		_session.journey_days_remaining,
	]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	_replan_holder.add_child(title)

	var origin := WorldMapData.get_location_by_id(_session.journey_origin_id)
	if origin != null:
		var back_button := Button.new()
		back_button.text = tr("UI_ROAD_TURN_BACK") % [
			origin.location_name, maxi(GameSession.MIN_DIVERT_DAYS, _session.get_days_travelled())
		]
		back_button.pressed.connect(_on_turn_back_pressed)
		_replan_holder.add_child(back_button)

	# Sapılabilecek hedefler çıkış şehrinden ölçülüyor: kervan haritanın
	# ortasında ışınlanmaz, bildiği yola geri çıkıp oradan gider (bkz.
	# GameSession.can_divert_to).
	for route in WorldMapData.get_routes_from(_session.journey_origin_id):
		if not _session.can_divert_to(route.to_location_id):
			continue
		var target := WorldMapData.get_location_by_id(route.to_location_id)
		var total_days := _session.get_days_travelled() + _session.get_route_travel_days(route)
		var divert_button := Button.new()
		divert_button.text = tr("UI_ROAD_DIVERT") % [
			target.location_name if target != null else route.to_location_id,
			maxi(GameSession.MIN_DIVERT_DAYS, total_days),
			int(_session.get_route_danger(route) * 100.0),
		]
		divert_button.pressed.connect(_on_divert_pressed.bind(route.to_location_id))
		_replan_holder.add_child(divert_button)

	var warning := Label.new()
	warning.text = tr("UI_ROAD_REPLAN_WARNING")
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD
	_replan_holder.add_child(warning)

	var cancel_button := Button.new()
	cancel_button.text = tr("UI_ROAD_REPLAN_CANCEL")
	cancel_button.pressed.connect(_close_replan)
	_replan_holder.add_child(cancel_button)

func _on_turn_back_pressed() -> void:
	if not _session.turn_back():
		_close_replan()
		return
	_apply_replan(tr("UI_ROAD_TURNED_BACK"))

func _on_divert_pressed(destination_id: String) -> void:
	if not _session.divert_journey(destination_id):
		_close_replan()
		return
	_apply_replan(tr("UI_ROAD_DIVERTED"))

func _apply_replan(log_format: String) -> void:
	_clock.consume_hours(REPLAN_HOURS)
	# Yeni bacak yeni bir sefer: ilerleme çubuğu ve varış kontrolü yeni
	# toplam güne göre okunmalı, yoksa çubuk dolu kalır ve sefer bitmiş
	# görünürdü.
	_journey_length_days = maxi(1, _session.journey_total_days)
	var destination := WorldMapData.get_location_by_id(_session.journey_destination_id)
	_add_log(log_format % (
		destination.location_name if destination != null else _session.journey_destination_id
	), OUTCOME_COLOR)
	_close_replan()

func _close_replan() -> void:
	_clear_children(_replan_holder)
	_set_journey_controls_enabled(true)
	_refresh_state()
	_check_journey_end()

func _finish_journey() -> void:
	_journey_finished = true
	_set_journey_controls_enabled(false)
	_add_log(tr("UI_ROAD_JOURNEY_DONE") % _current_day)
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
	title.text = tr("UI_ROAD_ARRIVAL_TITLE")
	_arrival_panel.add_child(title)

	_arrival_panel.add_child(_make_summary_label(
		tr("UI_ROAD_ESCORT_FEE") % payout.gross
	))
	_arrival_panel.add_child(_make_summary_label(
		tr("UI_ROAD_MORALE_MULTIPLIER") % int(round(payout.morale_factor * 100.0))
	))
	_arrival_panel.add_child(_make_summary_label(
		tr("UI_ROAD_DAMAGE_MULTIPLIER") % int(round(payout.damage_factor * 100.0))
	))

	var net_label := _make_summary_label(tr("UI_ROAD_NET") % payout.net)
	net_label.modulate = OUTCOME_COLOR
	_arrival_panel.add_child(net_label)

	var xp_awarded: int = payout.get("xp_awarded", 0)
	if xp_awarded > 0:
		var xp_label := _make_summary_label(tr("UI_ROAD_JOURNEY_XP") % xp_awarded)
		xp_label.modulate = OUTCOME_COLOR
		_arrival_panel.add_child(xp_label)

	var lost_contracts: int = payout.get("lost_contracts", 0)
	if lost_contracts > 0:
		var penalty_label := _make_summary_label(
			tr("UI_ROAD_LOST_CONTRACTS") % [
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

	_add_log(tr("UI_ROAD_ARRIVED") % payout.net, OUTCOME_COLOR)

## Kırılan bir yoldaşın varış özetindeki tek satırlık dökümü - huy
## kazandıysa adı, ayrıldıysa bunun da belirtilmesi lazım, oyuncu neden
## bir yoldaşını kaybettiğini anlasın.
func _stress_break_line(break_data: Dictionary) -> String:
	var character_name: String = break_data.character_name
	var trait_id: String = break_data.trait_id
	var trait_resource := TraitCatalog.get_trait(trait_id) if not trait_id.is_empty() else null
	var trait_note := " (%s)" % trait_resource.display_name if trait_resource != null else ""

	if break_data.departed:
		return tr("UI_STRESS_BROKE_LEFT") % [character_name, trait_note]
	if trait_resource != null:
		var kind := tr("UI_STRESS_VIRTUE") if trait_resource.is_positive else tr("UI_STRESS_AFFLICTION")
		return tr("UI_STRESS_BROKE_TRAIT") % [character_name, kind, trait_note]
	return tr("UI_STRESS_BROKE") % character_name

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

## Bir yan kanal paneli (savaş/pazarlık/tayfa) açıkken zaman durur ve
## eylemler kilitlenir - olay çözülmeden yol devam etmemeli.
func _set_journey_controls_enabled(enabled: bool) -> void:
	_draw_button.disabled = not enabled
	_camp_button.disabled = not enabled
	_speed_button.disabled = not enabled
	# Plan yalnızca yolda değiştirilebilir: varış işlendikten sonra ortada
	# değiştirilecek bir sefer kalmıyor.
	_replan_button.disabled = not enabled or not _session.is_journey_active()

func _refresh_state() -> void:
	var caravan := _session.caravan
	_state_label.text = tr("UI_ROAD_STATE") % [
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
