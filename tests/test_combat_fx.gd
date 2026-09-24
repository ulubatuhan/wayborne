extends RefCounted

## Savaşın hareket katmanı (SENSORY-006..011). Görünüşü ekran görüntüsü
## gösterir; burada kilitlenen şey sözleşme: her an başlıyor ve bitiyor,
## bitince tam nötre dönüyor, bir durum efekti kendi rengini taşıyor, düşen
## yere inmeden savaş kapanmıyor, sayı canın gerçek farkından çıkıyor.

const PANEL_PATH: String = "res://scripts/ui/combat_panel.gd"

func suite_name() -> String:
	return "CombatFx"

func run(t) -> void:
	_test_curves_start_and_end_at_rest(t)
	_test_status_barks_come_from_the_engine(t)
	_test_panel_drives_every_moment(t)
	_test_numbers_follow_real_hp(t)
	_test_fall_holds_the_continue_button(t)

func _test_curves_start_and_end_at_rest(t) -> void:
	t.eq(CombatFx.recoil(0.0), 0.0, "hamle yerinden başlıyor")
	t.eq(CombatFx.recoil(1.0), 0.0, "hamle yerine dönüyor")
	t.ok(CombatFx.recoil(0.4) > 0.0, "hamle ortasında ileride")
	t.ok(
		CombatFx.recoil(0.25) > CombatFx.recoil(0.75),
		"dönüş gidişten yumuşak (1-0.35u)"
	)
	t.eq(CombatFx.flash_at(ArtPalette.FX_FLASH_CRIT, 1.0), ArtPalette.FX_FLASH_NEUTRAL, "parlama nötre döner")
	t.eq(CombatFx.flash_at(ArtPalette.FX_FLASH_HIT, 0.0), ArtPalette.FX_FLASH_HIT, "parlama tam renkle başlar")
	t.eq(CombatFx.shake_at(6.0, 0.3), Vector2.ZERO, "sarsıntı süresi dolunca tam sıfır")
	t.eq(CombatFx.shake_at(0.0, 0.01), Vector2.ZERO, "genliksiz sarsıntı yok")
	# İki eksen ayrı frekansta, o yüzden sınır eksen başına: yatay zarfın
	# kendisi, dikey zarfın %60'ı.
	var early := CombatFx.shake_at(8.0, 0.01, 1.0)
	var late := CombatFx.shake_at(8.0, 0.2, 1.0)
	var late_envelope := 8.0 * exp(-0.2 / CombatFx.SHAKE_DECAY_SECONDS)
	t.ok(absf(early.x) <= 8.0 + 0.001 and absf(early.y) <= 4.8 + 0.001, "sarsıntı genliği aşmıyor")
	t.ok(
		absf(late.x) <= late_envelope + 0.001 and absf(late.y) <= late_envelope * 0.6 + 0.001,
		"sarsıntı üstel sönüyor"
	)
	t.ok(
		CombatFx.SHAKE_HIT < CombatFx.SHAKE_CRIT and CombatFx.SHAKE_CRIT < CombatFx.SHAKE_KILLED,
		"sarsıntı olayın ağırlığıyla büyüyor"
	)
	t.ok(
		CombatFx.RECOIL_HIT < CombatFx.RECOIL_MISS and CombatFx.RECOIL_MISS < CombatFx.RECOIL_CRIT,
		"kaçırma isabetten derin, kritikten sığ"
	)
	t.ok(CombatFx.CRIT_FLASH_MSEC > CombatFx.FLASH_MSEC, "kritik daha uzun parlıyor")
	t.eq(CombatFx.number_alpha(0.3), 1.0, "sayı önce tam görünür")
	t.eq(CombatFx.number_alpha(1.0), 0.0, "sayı sonunda kayboluyor")
	t.ok(CombatFx.number_offset(1.0).y < CombatFx.number_offset(0.2).y, "sayı yükseliyor")
	t.eq(CombatFx.fall_at(0.0), 0.0, "düşüş ayakta başlıyor")
	t.eq(CombatFx.fall_at(1.0), 1.0, "düşüş yerde bitiyor")

func _test_status_barks_come_from_the_engine(t) -> void:
	t.eq(CombatEncounter.status_bark(CombatUnit.STATUS_BLEED), CombatEncounter.BARK_STATUS_BLEED, "kanama barkı")
	t.eq(CombatEncounter.status_bark(CombatUnit.STATUS_BLIGHT), CombatEncounter.BARK_STATUS_BLIGHT, "zehir barkı")
	t.eq(CombatEncounter.status_bark(CombatUnit.STATUS_STUN), CombatEncounter.BARK_STATUS_STUN, "sersemlik barkı")
	for kind in [
		CombatEncounter.BARK_STATUS_BLEED, CombatEncounter.BARK_STATUS_BLIGHT,
		CombatEncounter.BARK_STATUS_STUN, CombatEncounter.BARK_BLEED_TICK,
		CombatEncounter.BARK_BLIGHT_TICK, CombatEncounter.BARK_STUN_SKIP,
	]:
		t.ok(CombatFx.status_color(kind).a > 0.0, "%s bir renk taşıyor" % kind)

	# Motorun kendisi: kanayan bir birimin turu açılınca tık barkı gelir,
	# sersem birimin turu atlanınca atlama barkı.
	var heard: Array = []
	var bleeding := _unit("Kanayan", true, 1)
	var foe := _unit("Hasım", false, 1)
	var players: Array[CombatUnit] = [bleeding]
	var enemies: Array[CombatUnit] = [foe]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var encounter := CombatEncounter.new(players, enemies, rng, "Haydutlar")
	encounter.unit_barked.connect(func(_unit, text, kind): heard.append([text, kind]))
	bleeding.apply_status(CombatUnit.STATUS_BLEED, 2, 3)
	encounter._begin_unit_turn(bleeding)
	t.ok(_heard(heard, CombatEncounter.BARK_BLEED_TICK), "kanama tıkı bark oluyor")
	t.ok(_heard_with_empty_text(heard, CombatEncounter.BARK_BLEED_TICK), "tık barkı balon açmıyor (metin boş)")
	heard.clear()
	foe.apply_status(CombatUnit.STATUS_STUN, 0, 1)
	encounter._begin_unit_turn(foe)
	t.ok(_heard(heard, CombatEncounter.BARK_STUN_SKIP), "sersemlik atlaması bark oluyor")

func _test_panel_drives_every_moment(t) -> void:
	var panel = _panel()
	var attacker: CombatUnit = panel._encounter.get_active_unit()
	var target: CombatUnit = (
		panel._encounter.enemy_units if attacker.is_player_side else panel._encounter.player_units
	)[0]

	panel._on_unit_barked(target, "", CombatEncounter.BARK_STATUS_BLEED)
	t.ok(panel._ring_states.has(target), "durum uygulaması halka açıyor")
	t.not_ok(panel._bark_texts.has(target), "metni boş bark balon açmıyor")
	t.eq(panel._flash_for_kind(CombatEncounter.BARK_BLEED_TICK), ArtPalette.FX_BLEED, "kanama tıkı kanama renginde")
	t.eq(panel._flash_for_kind(CombatEncounter.BARK_BLIGHT_TICK), ArtPalette.FX_BLIGHT, "zehir tıkı zehir renginde")

	panel._on_unit_barked(target, "vur", CombatEncounter.BARK_CRIT)
	t.eq(int(panel._flash_states[target]["duration"]), CombatFx.CRIT_FLASH_MSEC, "kritik parlaması uzun")
	t.ok(not panel._shake.is_empty(), "kritik sahneyi sarsıyor")

	# Canlı slota her karede basılıyor ve süre dolunca kendi kendine nötre
	# dönüyor - bir sonraki tazelemeyi beklemeden.
	var slot: CombatUnitSlot = panel._slot_by_unit[target]
	var start: int = int(panel._flash_states[target]["start"])
	t.ok(panel._animate(start + 10), "kritikten hemen sonra hâlâ canlanıyor")
	t.not_ok(slot._figure.modulate.is_equal_approx(ArtPalette.FX_FLASH_NEUTRAL), "canlı slot parlıyor")
	panel._animate(start + CombatFx.CRIT_FLASH_MSEC + 1000)
	t.ok(slot._figure.modulate.is_equal_approx(ArtPalette.FX_FLASH_NEUTRAL), "süre dolunca canlı slot nötr")
	t.not_ok(panel._flash_states.has(target), "süresi dolan parlama silindi")
	t.ok(panel._shake.is_empty(), "süresi dolan sarsıntı silindi")
	panel.free()

func _test_numbers_follow_real_hp(t) -> void:
	var panel = _panel()
	var unit: CombatUnit = panel._encounter.enemy_units[0]
	unit.current_hp -= 5
	panel._on_unit_barked(unit, "vur", CombatEncounter.BARK_CRIT)
	panel._spawn_hp_numbers()
	t.eq(panel._numbers.size(), 1, "can farkı bir sayı doğuruyor")
	var label: Label = panel._numbers[0]["label"]
	t.eq(label.text, "-5", "sayı canın gerçek farkı")
	t.ok(label.modulate.is_equal_approx(ArtPalette.FX_CRIT), "kritik vuruşun sayısı kritik renginde")
	panel._spawn_hp_numbers()
	t.eq(panel._numbers.size(), 1, "değişmeyen can ikinci sayı doğurmuyor")
	var healed: CombatUnit = panel._encounter.player_units[0]
	healed.current_hp -= 4
	panel._hp_seen[healed] = healed.current_hp
	healed.current_hp += 3
	panel._spawn_hp_numbers()
	var heal_label: Label = panel._numbers[1]["label"]
	t.eq(heal_label.text, "+3", "iyileşme artıyla")
	t.ok(heal_label.modulate.is_equal_approx(ArtPalette.FX_HEAL), "iyileşme iyileşme renginde")
	panel._animate(Time.get_ticks_msec() + CombatFx.NUMBER_MSEC + 100)
	t.eq(panel._numbers.size(), 0, "süresi dolan sayılar kalkıyor")
	panel.free()

func _test_fall_holds_the_continue_button(t) -> void:
	var panel = _panel()
	var unit: CombatUnit = panel._encounter.enemy_units[0]
	panel._on_unit_barked(unit, "düştü", CombatEncounter.BARK_KILLED)
	t.ok(panel.falls_pending(), "düşüş başladı")
	panel._continue_button.visible = true
	var start: int = int(panel._fall_states[unit]["start"])
	panel._animate(start + 50)
	t.ok(panel._continue_button.disabled, "düşen yere inmeden Devam kilitli")
	panel._on_continue_pressed()
	t.ok(panel._continue_button.visible, "kilitliyken Devam savaşı kapatmıyor")
	panel._animate(start + CombatFx.FALL_MSEC + 10)
	t.not_ok(panel.falls_pending(), "düşüş bitti")
	t.not_ok(panel._continue_button.disabled, "düşüş bitince Devam açılıyor")
	panel.free()

# --- yardımcılar ---

func _panel():
	var panel = load(PANEL_PATH).new()
	panel._ready()
	var party: Array[CharacterData] = []
	for index in 2:
		var character := CharacterData.create("P%d" % index, CultureCatalog.get_cultures()[0].culture_id, CharacterStats.new())
		character.is_player = index == 0
		party.append(character)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	panel.start_combat(party, 0.4, rng, "bandit", "")
	return panel

func _unit(name: String, player_side: bool, position: int) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.display_name = name
	unit.is_player_side = player_side
	unit.position = position
	unit.max_hp = 30
	unit.current_hp = 30
	return unit

func _heard(heard: Array, kind: String) -> bool:
	for entry in heard:
		if String(entry[1]) == kind:
			return true
	return false

func _heard_with_empty_text(heard: Array, kind: String) -> bool:
	for entry in heard:
		if String(entry[1]) == kind and String(entry[0]).is_empty():
			return true
	return false
