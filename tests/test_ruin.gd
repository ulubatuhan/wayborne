extends RefCounted

## "Kervan mahvolabilir ama yok olmaz" kuralının ölçülebilir yarısı.
##
## Bu paket, sistemlerin *ulaşılabilir* olduğunu iddia ediyor - formüllerin
## şu sayıyı verdiğini değil. Denetimde çıkan tablo şuydu: 600 koşuda
## ortalama vagon kaybı 0.00, üç ve dört kişilik parti her tehlikede %100
## kazanıyor, seviye atladıkça parti *zayıflıyordu*. Yani yıpranma
## kâğıt üstündeydi.

func suite_name() -> String:
	return "Ruin"

func run(t) -> void:
	_test_wagon_loss_is_reachable(t)
	_test_wagon_loss_never_takes_the_last_wagon(t)
	_test_squad_grows_with_party(t)
	_test_danger_changes_the_squad(t)
	_test_scaling_rises_but_stays_bounded(t)
	_test_drift_alone_cannot_mutiny(t)

## WAGON_LOSE applier'da işleniyordu ama hiçbir olay onu söylemiyordu.
## Bir efekt türünün katalogda karşılığı yoksa sessizce ölüdür.
func _test_wagon_loss_is_reachable(t) -> void:
	var events_using_loss := 0
	for event in EventCatalog.get_road_events():
		if _event_uses_wagon_loss(event):
			events_using_loss += 1
	t.ok(events_using_loss > 0, "en az bir olay vagon kaybettirebiliyor")

func _event_uses_wagon_loss(event: GameEvent) -> bool:
	for effect in event.immediate_effects:
		if effect.type == EventEffect.Type.WAGON_LOSE:
			return true
	for choice in event.choices:
		for effect in choice.effects:
			if effect.type == EventEffect.Type.WAGON_LOSE:
				return true
		for outcome in choice.outcomes:
			for effect in outcome.effects:
				if effect.type == EventEffect.Type.WAGON_LOSE:
					return true
	return false

## Kayıp gerçek olmalı ama oyuncunun kendi vagonu asla gitmemeli - kervan
## sürünebilir, yok olamaz.
func _test_wagon_loss_never_takes_the_last_wagon(t) -> void:
	var caravan := CaravanState.new()
	caravan.wagon_count = 4
	t.eq(caravan.lose_wagons(2), 2, "kaybedilebilir vagonlar gerçekten gidiyor")
	t.eq(caravan.wagon_count, 2, "sayım doğru")

	t.eq(caravan.lose_wagons(99), 2 - CaravanState.MIN_WAGONS, "yalnızca fazlası gider")
	t.eq(caravan.wagon_count, CaravanState.MIN_WAGONS, "son vagon kalır")

	t.eq(caravan.lose_wagons(5), 0, "son vagon hiçbir koşulda alınamaz")
	t.eq(caravan.wagon_count, CaravanState.MIN_WAGONS, "sayım değişmez")

## Yalnız yolcu dört haydutla karşılaşmaz, ama dolu kervan da iki kişiyle
## geçiştirmez.
func _test_squad_grows_with_party(t) -> void:
	var previous := 0
	for party_size in [1, 2, 3, 4]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		var squad := EnemyCatalog.build_bandit_squad(0.9, party_size, rng, 1)
		t.le(
			float(squad.size()), float(party_size + 1),
			"%d kişilik partiye en fazla %d düşman" % [party_size, party_size + 1]
		)
		t.le(
			float(squad.size()), float(EnemyCatalog.MAX_SQUAD_SIZE),
			"kadro savaş alanının dört mevkisini aşmaz"
		)
		t.ge(float(squad.size()), float(previous), "kadro parti büyüdükçe küçülmez")
		previous = squad.size()

## Tehlike kadroyu değiştirmeli. Eskiden kırpma mevkiye göre yapıldığı için
## yalnız bir yolcuya her zaman iki kesici geliyordu: o oyuncu için sakin
## bir yol ile eşkıya kaynayan bir yol birebir aynıydı.
func _test_danger_changes_the_squad(t) -> void:
	var calm := _squad_ids(0.2, 1)
	var grim := _squad_ids(0.9, 1)
	t.ok(calm != grim, "yalnız yolcu için de tehlike kadroyu değiştirir")
	t.ok(grim.has(_leader_name()), "eşkıya kaynayan yolda reis karşına çıkar")
	t.ok(not calm.has(_leader_name()), "sakin yolda reis çıkmaz")

func _leader_name() -> String:
	return EnemyCatalog.get_enemy(EnemyCatalog.LEADER).display_name

## CombatUnit düşman kimliğini taşımıyor; görünen ad kadronun kimlerden
## kurulduğunu ayırt etmeye yetiyor.
func _squad_ids(danger: float, party_size: int) -> Array[String]:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var names: Array[String] = []
	for unit in EnemyCatalog.build_bandit_squad(danger, party_size, rng, 1):
		names.append(unit.display_name)
	return names

## Ölçek iki yönde de artmalı ama ikisi de sınırsız olmamalı: seviye kolu
## çok dik olduğunda seviye atlamak partiyi zayıflatıyordu (ölçüldü:
## sv1 %98 → sv15 %52).
func _test_scaling_rises_but_stays_bounded(t) -> void:
	t.ok(
		EnemyCatalog.get_power_scale(10) > EnemyCatalog.get_power_scale(1),
		"düşman seviyeyle güçlenir"
	)
	t.ok(
		EnemyCatalog.get_power_scale(1, 4) > EnemyCatalog.get_power_scale(1, 1),
		"dolu kervan daha büyük çete çeker"
	)
	t.le(
		EnemyCatalog.get_power_scale(15, 1), 1.5,
		"seviye kolu oyuncunun büyümesini geçecek kadar dik değil"
	)
	t.eq(
		EnemyCatalog.get_power_scale(1, 1), 1.0,
		"seviye 1 / tek kişide ölçek nötr"
	)

## Yıpranma yolun bedeli, isyanın sebebi değil (bkz. Morale Rules).
func _test_drift_alone_cannot_mutiny(t) -> void:
	var caravan := CaravanState.new()
	for _day in 200:
		caravan.apply_daily_drift()
	t.ok(
		caravan.morale > EventCatalog.MUTINY_MORALE_THRESHOLD,
		"iki yüz gün yürümek bile tek başına isyana yetmez"
	)
