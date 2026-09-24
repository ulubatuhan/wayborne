extends RefCounted

## Faz 17: SkillCheck'in kendisi ve EventEngine.resolve_check()'in mevcut
## ağırlıklı-sonuç mimarisine nasıl oturduğu - yeni bir çözümleyici icat
## edilmedi, yalnızca context'e "check_tier" yazıldı.

func suite_name() -> String:
	return "SkillCheck"

func run(t) -> void:
	_test_chance_formula(t)
	_test_chance_clamped(t)
	_test_roll_tiers_are_seed_reproducible(t)
	_test_context_key(t)
	_test_resolve_check_no_check_passthrough(t)
	_test_resolve_check_writes_tier(t)
	_test_resolve_check_does_not_mutate_original_context(t)
	_test_outcome_conditions_read_tier(t)

func _test_chance_formula(t) -> void:
	t.eq(SkillCheck.compute_chance(0.0, 0.0), 50, "taban statta (etkin 0) şans %50")
	t.ok(SkillCheck.compute_chance(5.0, 0.0) > 50, "yüksek etkin stat şansı artırır")
	t.ok(SkillCheck.compute_chance(-4.0, 0.0) < 50, "düşük etkin stat şansı azaltır")
	t.eq(
		SkillCheck.compute_chance(3.0, 1.0), SkillCheck.compute_chance(2.0, 0.0),
		"zorluk ve etkin stat aynı farkta aynı şansı verir"
	)

func _test_chance_clamped(t) -> void:
	t.eq(SkillCheck.compute_chance(100.0, 0.0), SkillCheck.MAX_CHANCE, "şans tavanı aşılmaz")
	t.eq(SkillCheck.compute_chance(-100.0, 0.0), SkillCheck.MIN_CHANCE, "şans tabanın altına inmez")

func _test_roll_tiers_are_seed_reproducible(t) -> void:
	var check := SkillCheck.make(CharacterStats.Kind.CHARISMA, SkillCheck.Source.PARTY_BEST, 0.0)
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 777
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 777

	var tiers_a: Array[int] = []
	var tiers_b: Array[int] = []
	for _i in 20:
		tiers_a.append(check.roll(3.0, rng_a))
	for _i in 20:
		tiers_b.append(check.roll(3.0, rng_b))
	t.eq(tiers_a, tiers_b, "aynı seed aynı zar dizisini üretir")

	# Statistiksel olarak: yeterli örnekte üç kademe de görünmeli (overwhelming-
	# margin deseni, bkz. CLAUDE.md Testing bölümü).
	var big_rng := RandomNumberGenerator.new()
	big_rng.seed = 42
	var seen: Dictionary = {}
	for _i in 500:
		seen[check.roll(0.0, big_rng)] = true
	t.eq(seen.size(), 3, "yeterli örnekte başarısızlık/kıl payı/tam başarı üçü de çıkar")

func _test_context_key(t) -> void:
	var leader_check := SkillCheck.make(CharacterStats.Kind.FAITH, SkillCheck.Source.LEADER)
	t.eq(leader_check.get_context_key(), "leader_faith", "lider check'i doğru anahtarı okur")

	var party_check := SkillCheck.make(CharacterStats.Kind.WISDOM, SkillCheck.Source.PARTY_BEST)
	t.eq(party_check.get_context_key(), "best_wisdom", "parti check'i doğru anahtarı okur")

func _test_resolve_check_no_check_passthrough(t) -> void:
	var engine := EventEngine.new([], 1)
	var choice := EventChoice.new()
	var context := {"gold": 100}
	var result := engine.resolve_check(choice, context)
	t.not_ok(result.has("check_tier"), "check yoksa check_tier eklenmez")
	t.eq(result.get("gold"), 100, "context'in geri kalanı korunur")

func _test_resolve_check_writes_tier(t) -> void:
	var engine := EventEngine.new([], 2)
	var choice := EventChoice.new()
	choice.check = SkillCheck.make(CharacterStats.Kind.INTELLECT, SkillCheck.Source.PARTY_BEST, 0.0)
	var context := {"best_intellect": 5.0}
	var result := engine.resolve_check(choice, context)
	t.ok(result.has("check_tier"), "check varsa check_tier eklenir")
	t.ok(int(result["check_tier"]) in [0, 1, 2], "check_tier üç kademeden biridir")

func _test_resolve_check_does_not_mutate_original_context(t) -> void:
	var engine := EventEngine.new([], 3)
	var choice := EventChoice.new()
	choice.check = SkillCheck.make(CharacterStats.Kind.STRENGTH, SkillCheck.Source.PARTY_BEST, 0.0)
	var context := {"best_strength": 0.0}
	engine.resolve_check(choice, context)
	t.not_ok(context.has("check_tier"), "orijinal context değişmez, yalnızca kopya döner")

## Bunun ispatladığı şey: check_tier normal EventCondition ile okunabiliyor,
## yeni bir koşul tipi icat edilmedi.
func _test_outcome_conditions_read_tier(t) -> void:
	var success_outcome := EventOutcome.make("success", [] as Array[EventEffect])
	success_outcome.conditions = [EventCondition.make("check_tier", EventCondition.Op.GREATER_EQUAL, 1.0)]
	var fail_outcome := EventOutcome.make("fail", [] as Array[EventEffect])
	fail_outcome.conditions = [EventCondition.make("check_tier", EventCondition.Op.EQUAL, 0.0)]

	var success_context := {"check_tier": 2}
	t.ok(success_outcome.is_available(success_context), "başarı koşulu tam başarıda sağlanır")
	t.not_ok(fail_outcome.is_available(success_context), "başarısızlık koşulu başarıda sağlanmaz")

	var fail_context := {"check_tier": 0}
	t.not_ok(success_outcome.is_available(fail_context), "başarı koşulu başarısızlıkta sağlanmaz")
	t.ok(fail_outcome.is_available(fail_context), "başarısızlık koşulu başarısızlıkta sağlanır")
