extends RefCounted

## Ruh eksenleri ve tanıklık (Ruh alt sistemi, tasarım notu §D-R1, §D-R2,
## §D-R4).
##
## Sınanan şey eğri değil **söz**: bir şeyi görmenin iz bıraktığı, tek bir
## kara günün kimseyi bitirmediği (günlük tavan), çatlağın yalnız dönen bir
## iyilikle iyileştiği ve liderin ekseninin hiçbir seçeneği kapatmadığı -
## yalnız bedelini değiştirdiği.

func suite_name() -> String:
	return "Ruh"

func run(t) -> void:
	_test_axes_start_clean(t)
	_test_daily_cap_holds(t)
	_test_witness_table_rows(t)
	_test_only_a_returning_kindness_heals_the_crack(t)
	_test_leader_pays_for_its_own_face(t)
	_test_no_choice_is_ever_closed(t)
	_test_soul_survives_the_save(t)
	_test_state_machine_has_hysteresis(t)
	_test_states_bend_existing_counters(t)
	_test_leader_word_carries_the_break_threshold(t)
	_test_state_is_read_as_a_sentence_not_a_number(t)

func _session(extra: int = 2) -> GameSession:
	var session := GameSession.new(400, 40, 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	session.start_playthrough(
		CharacterData.create("Lider", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	for i in extra:
		session.add_to_party(CharacterData.create(
			"Yoldaş %d" % (i + 1), CultureCatalog.VALLEY, CharacterStats.new()))
	return session

func _companion(session: GameSession) -> CharacterData:
	for member in session.get_party():
		if not member.is_player:
			return member
	return null

func _test_axes_start_clean(t) -> void:
	var session := _session()
	for member in session.get_party():
		t.eq(member.kabuk, 0.0, "kervan kimseyi daha kırmadı: kabuk 0")
		t.eq(member.catlak, 0.0, "çatlak 0")
	# Çatlağıyla gelen: dul ve açlıktan yola düşmüş (§D-R1).
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var board := RecruitCatalog.build_candidates(RecruitCatalog.VENUE_TAVERN, rng, 1)
	for candidate in board:
		if CharacterData.SOUL_BACKSTORY_CRACK.has(candidate.backstory_id):
			t.ok(candidate.catlak > 0.0, "dul ya da aç gelen çatlağıyla gelir")
		else:
			t.eq(candidate.catlak, 0.0, "öteki geçmişler çatlak getirmez")

func _test_daily_cap_holds(t) -> void:
	var session := _session()
	var who := _companion(session)
	for _step in 20:
		who.change_soul(CharacterData.SOUL_CRACK, 0.5, session.total_days_elapsed)
	t.eq(who.catlak, CharacterData.SOUL_DAILY_CAP, "bir günde bir eksen tavanı aşmıyor")
	# Ertesi gün taşınmıyor: yeni günün kendi payı var.
	who.change_soul(CharacterData.SOUL_CRACK, 0.5, session.total_days_elapsed + 1)
	t.eq(who.catlak, CharacterData.SOUL_DAILY_CAP + 0.5, "yeni gün yeni pay")

func _test_witness_table_rows(t) -> void:
	var session := _session()
	var leader := session.get_player_character()
	var who := _companion(session)

	session.note_witness(GameSession.WITNESS_PRICE_WORTH, who)
	t.eq(who.catlak, 0.5, "bedeli ödeyen çatlar")
	t.eq(leader.kabuk, 0.5, "işe yarayan bedel liderde kabuk bağlar")

	session.total_days_elapsed += 1
	session.note_witness(GameSession.WITNESS_PRICE_WASTED, who)
	t.eq(who.catlak, 1.5, "boşa giden bedel daha derin çatlatır")
	t.eq(leader.catlak, 0.5, "boşa giden bedel lideri de çatlatır")

	session.total_days_elapsed += 1
	var shell_before: float = leader.kabuk
	session.note_witness(GameSession.WITNESS_MERCY)
	t.ok(leader.kabuk < shell_before, "merhamet kabuğu inceltir")

func _test_only_a_returning_kindness_heals_the_crack(t) -> void:
	var session := _session()
	var who := _companion(session)
	who.catlak = 3.0
	# Şehirde bir gece, bir ziyafet, bir kamp: stres erir, çatlak kalır.
	who.change_stress(60)
	session.change_stress(-100)
	t.eq(who.catlak, 3.0, "stres erir, çatlak kalmaya devam eder")
	# Doğduğunda kervanda olduğu bir iz iyi döner: çatlak iyileşir.
	session.note_witness(GameSession.WITNESS_TRACE_GOOD, null, session.total_days_elapsed)
	t.eq(who.catlak, 2.0, "dönen bir iyilik çatlağı kapatır")

func _test_leader_pays_for_its_own_face(t) -> void:
	var session := _session()
	var leader := session.get_player_character()
	leader.kabuk = 4.0
	var before: int = leader.stress
	session.charge_leader_tone(true)
	t.eq(leader.stress, before + 4, "kabuk bağlamış liderin eli merhamete gitmiyor")
	leader.catlak = 3.0
	before = leader.stress
	session.charge_leader_tone(false)
	t.eq(leader.stress, before + 3, "çatlamış liderin içi sertliğe götürmüyor")

## Anayasa (A5): hiçbir seçenek liderin ekseni yüzünden kapanmaz. Eksen
## yalnız zarı kaydırır - ve kaydırdığı kadarı düğmede de yazar.
func _test_no_choice_is_ever_closed(t) -> void:
	var session := _session()
	var choice := EventChoice.new()
	choice.effects = [EventEffect.make(EventEffect.Type.BEDEL, 4, "STRESS|en_zayif")]
	choice.check = SkillCheck.make(CharacterStats.Kind.CHARISMA, SkillCheck.Source.LEADER, 0.0)
	var context := session.build_event_context()
	t.ok(choice.is_available(context), "sert seçenek açık")
	t.eq(EventEngine.leader_tone_bonus(choice, context), 0.0, "kabuksuz liderin payı yok")
	session.get_player_character().kabuk = EventEngine.LEADER_SOUL_GATE
	context = session.build_event_context()
	t.eq(EventEngine.leader_tone_bonus(choice, context), EventEngine.LEADER_SOUL_BONUS,
		"soğuk yüz sert seçenekte zarı kaydırıyor")
	t.ok(choice.is_available(context), "seçenek yine açık: kapanan hiçbir şey yok")

func _test_soul_survives_the_save(t) -> void:
	var session := _session()
	var who := _companion(session)
	who.kabuk = 2.25
	who.catlak = 1.75
	var copy := CharacterData.from_dict(who.to_dict())
	t.eq(copy.kabuk, 2.25, "kabuk kayıttan döndü")
	t.eq(copy.catlak, 1.75, "çatlak kayıttan döndü")

# --- §D-R3: hâl makinesi ---

## Histerezis: girmek 4, çıkmak 3. Bir insan günde bir Katı olup bir
## Diri'ye dönmez - eşiğin üstünde titreyen kişi hâlinde kalır.
func _test_state_machine_has_hysteresis(t) -> void:
	var session := _session()
	var who := _companion(session)
	who.kabuk = CharacterData.STATE_ENTER_AXIS
	t.eq(who.update_state(10, true), CharacterData.STATE_HARD, "kabuk 4'te Katı")
	who.kabuk = 3.5
	t.eq(who.update_state(11, true), "", "3,5'te hâlâ Katı: çıkış eşiği ayrı")
	t.ok(who.is_hard(), "hâl korunuyor")
	who.kabuk = 2.75
	t.eq(who.update_state(12, true), CharacterData.STATE_ALIVE, "3'ün altında Diri'ye döner")

	# Yorgun yolun beş gününü ister, şehrin üç gecesinde geçer.
	var tired := _companion(session)
	tired.stress = CharacterData.STATE_WEARY_STRESS_IN + 5
	for day in CharacterData.STATE_WEARY_DAYS_IN - 1:
		t.eq(tired.update_state(20 + day, true), "", "beşinci günden önce Yorgun değil")
	t.eq(tired.update_state(30, true), CharacterData.STATE_WEARY, "beşinci yol günü Yorgun")
	tired.stress = CharacterData.STATE_WEARY_STRESS_OUT - 5
	for day in CharacterData.STATE_WEARY_DAYS_OUT - 1:
		tired.update_state(40 + day, false)
	t.eq(tired.update_state(50, false), CharacterData.STATE_ALIVE, "üç sakin gece Yorgun'u alır")

## Hiçbir hâl yeni bir sayaç açmıyor: hepsi var olan çarpanlara biniyor.
func _test_states_bend_existing_counters(t) -> void:
	var session := _session()
	var who := _companion(session)
	who.kabuk = 5.0
	who.update_state(10, true)
	var before: int = who.stress
	session.change_character_stress(who, 10)
	t.eq(who.stress, before + 5, "Katı olaydan gelen stresi yarıya indiriyor")
	var rapport_before: int = who.rapport
	who.change_rapport(2)
	t.eq(who.rapport, rapport_before + 1, "Katı yakınlığı yarım alıyor")
	t.eq(who.get_check_modifier(CharacterStats.Kind.CHARISMA),
		-CharacterData.HARD_CHARISMA_PENALTY, "soğuk yüzün Karizma payı eksi")

	var dim := _session(1).get_party()[1]
	dim.catlak = 5.0
	dim.update_state(10, true)
	var fatigue_before: int = dim.fatigue
	dim.change_fatigue(8)
	t.ok(dim.fatigue > fatigue_before + 8, "Sönük daha çabuk yoruluyor")
	var dim_threshold: int = dim.get_stress_resistance()
	dim.catlak = 0.0
	dim.update_state(11, true)
	t.eq(dim_threshold, dim.get_stress_resistance() - CharacterData.DIM_BREAK_PENALTY,
		"Sönük savaşta on puan erken kırılıyor")

## Teşhis A12: liderin Karizması savaşta ölçülebilir hiçbir şey yapmıyordu
## çünkü yalnız kendi emir reddini azaltıyordu. Liderlik başkalarına yapılır.
func _test_leader_word_carries_the_break_threshold(t) -> void:
	var session := _session()
	var leader := session.get_player_character()
	var who := _companion(session)
	var base: int = who.get_stress_resistance()
	leader.stats.set_value(CharacterStats.Kind.CHARISMA, 10)
	session.update_party_states()
	t.ok(who.get_stress_resistance() > base, "liderin sözü yoldaşın eşiğini taşıyor")
	t.eq(leader.leader_composure_bonus, 0, "lider kendi sözüyle taşınmıyor")

func _test_state_is_read_as_a_sentence_not_a_number(t) -> void:
	var session := _session()
	var who := _companion(session)
	who.kabuk = 5.0
	who.update_state(10, true)
	var line := CaravanOverviewPanel.thought_for(who)
	t.ok(line.contains(who.character_name), "hâl kişinin adıyla anlatılıyor")
	t.not_ok(line.contains("4") or line.contains("5"), "ekranda eksenin sayısı yok")
