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
