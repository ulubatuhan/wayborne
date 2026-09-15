extends RefCounted

## Yolun üç katmanı: dikkat, işaretler, tempo.
##
## Bu paketin koruduğu asıl iddia şu: **yürümek artık bir karar.** Yol
## uzun süre "tuşu basılı tut, günde bir kart açılsın" idi; tek girdi
## "ilerliyor musun" ve cevabı her zaman evetti.
##
## Üç katmanın üçü de UI'sız çekirdek olarak yazıldı (bkz. CLAUDE.md
## Testing - "UI-free cores"), o yüzden burada ekrana hiç dokunulmadan
## sınanabiliyorlar.

func suite_name() -> String:
	return "RoadLayers"

func run(t) -> void:
	_test_zones_are_exclusive(t)
	_test_attention_rewards_differ_per_zone(t)
	_test_signals_resolve_only_in_their_zone(t)
	_test_ignored_signals_escalate(t)
	_test_signals_are_bounded(t)
	_test_pushing_costs_stamina(t)

func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

## Lider aynı anda tek bir yerde olabilir - dikkatin sonlu olması bütün
## katmanın var olma sebebi.
func _test_zones_are_exclusive(t) -> void:
	t.eq(RoadAttention.zone_for(0.0), RoadAttention.ZONE_FRONT, "kolona bağlı lider öndedir")
	t.eq(RoadAttention.zone_for(0.5), RoadAttention.ZONE_WAGONS, "orta bölge vagonlardır")
	t.eq(RoadAttention.zone_for(1.0), RoadAttention.ZONE_REAR, "en geri kuyruktur")

	# Aralık dışı değerler kenetleniyor: ekran oranı hesaplarken kolon
	# uzunluğu sıfır olabiliyor (henüz yerleşmemiş kervan).
	t.eq(RoadAttention.zone_for(-3.0), RoadAttention.ZONE_FRONT, "negatif oran öne kenetlenir")
	t.eq(RoadAttention.zone_for(9.0), RoadAttention.ZONE_REAR, "taşan oran arkaya kenetlenir")

	var seen := {}
	for step in 21:
		seen[RoadAttention.zone_for(float(step) / 20.0)] = true
	t.eq(seen.size(), 3, "kolon boyunca üç bölgenin üçü de geçiliyor")

## Her bölgenin ödülü yalnızca kendi bölgesinde: bir yerde durup hepsini
## almak mümkün olsaydı seçim diye bir şey kalmazdı.
func _test_attention_rewards_differ_per_zone(t) -> void:
	t.ok(
		RoadAttention.spot_bonus_days(RoadAttention.ZONE_FRONT) > 0.0,
		"öndeyken karşılaşma daha uzaktan görünür"
	)
	t.eq(
		RoadAttention.spot_bonus_days(RoadAttention.ZONE_REAR), 0.0,
		"kuyruktayken öne dair bir avantaj yok"
	)
	t.ok(
		RoadAttention.wagon_wear_multiplier(RoadAttention.ZONE_WAGONS) < 1.0,
		"vagonların yanındayken aşınma azalır"
	)
	t.eq(
		RoadAttention.wagon_wear_multiplier(RoadAttention.ZONE_FRONT), 1.0,
		"başka bölgede vagon aşınması nötrdür"
	)
	t.ok(
		RoadAttention.stress_relief_per_day(RoadAttention.ZONE_REAR) > 0,
		"kuyrukla ilgilenmek stresi keser"
	)
	t.eq(
		RoadAttention.stress_relief_per_day(RoadAttention.ZONE_WAGONS), 0,
		"vagonlardayken kuyruk stresi kesilmez"
	)

## Bir işaret yalnızca kendi bölgesinde ilgilenilince kapanıyor.
func _test_signals_resolve_only_in_their_zone(t) -> void:
	var signals := RoadSignals.new()
	signals.open_signals = [{"kind": RoadSignals.KIND_WHEEL, "age_hours": 0.0}]

	# Yanlış bölge: kapanmaz, yaşlanır.
	var wrong := signals.tick(2.0, RoadAttention.ZONE_REAR, _rng(1))
	t.eq(wrong["resolved"].size(), 0, "yanlış bölgede durmak işareti kapatmaz")
	t.ok(signals.has_open(), "işaret açık kalır")

	# Doğru bölge: kapanır.
	var right := signals.tick(2.0, RoadAttention.ZONE_WAGONS, _rng(2))
	t.ok(right["resolved"].has(RoadSignals.KIND_WHEEL), "doğru bölgede işaret kapanır")
	t.not_ok(signals.has_open(), "kapanan işaret listeden çıkar")

	# Her türün kendi bölgesi var ve üçü birbirinden farklı.
	var zones := {}
	for kind in RoadSignals.ALL_KINDS:
		zones[RoadSignals.get_zone_for(kind)] = true
	t.eq(zones.size(), 3, "üç işaret türü üç ayrı bölgeye dağılır")

## İhmal edilen işaret büyüyor - katmanın asıl dişi bu. Büyümeseydi
## işaretler bir dekor olurdu.
func _test_ignored_signals_escalate(t) -> void:
	var signals := RoadSignals.new()
	signals.open_signals = [{"kind": RoadSignals.KIND_STRAGGLER, "age_hours": 0.0}]

	var before := signals.tick(
		RoadSignals.ESCALATE_HOURS - 1.0, RoadAttention.ZONE_FRONT, _rng(3)
	)
	t.eq(before["escalated"].size(), 0, "eşiğin altında büyüme yok")
	t.ok(signals.has_open(), "ama işaret hâlâ açık ve yaşlanıyor")

	var after := signals.tick(2.0, RoadAttention.ZONE_FRONT, _rng(4))
	t.ok(
		after["escalated"].has(RoadSignals.KIND_STRAGGLER),
		"eşik aşılınca işaret büyür"
	)
	# Aynı tik yeni bir işaret de doğurabiliyor, o yüzden "liste boş"
	# demek yanlış olurdu: sınanan şey *büyüyenin* düşmüş olması.
	t.not_ok(
		signals.get_open_kinds().has(RoadSignals.KIND_STRAGGLER),
		"büyüyen işaret açık listeden düşer"
	)

## İki koruma: aynı anda çok fazla işaret olmaz (kovalanamayan bir
## gürültü seçim değil çaresizliktir) ve aynı tür iki kez açılmaz.
func _test_signals_are_bounded(t) -> void:
	var signals := RoadSignals.new()
	var rng := _rng(12345)
	# Dikkati hiçbir işaretin bölgesinde olmayan bir yere sabitlemek
	# mümkün değil (üç bölge, üç tür), o yüzden çözülme olacak; sınanan
	# şey her an açık sayının tavanı aşmaması.
	for _step in 400:
		signals.tick(1.0, RoadAttention.ZONE_FRONT, rng)
		t.le(
			signals.open_signals.size(), RoadSignals.MAX_OPEN,
			"açık işaret sayısı tavanı aşmaz"
		)
		var kinds := signals.get_open_kinds()
		var unique := {}
		for kind in kinds:
			unique[kind] = true
		t.eq(unique.size(), kinds.size(), "aynı tür iki kez açılmaz")

	# Uzun bir tik, kısa tiklerin toplamı kadar iş yapmalı: ihtimal
	# süreyle ölçekleniyor, yoksa 3x hızda oynayan oyuncu daha az işaret
	# görürdü.
	var fast := RoadSignals.new()
	var appeared := 0
	var fast_rng := _rng(777)
	for _step in 100:
		appeared += (fast.tick(6.0, RoadAttention.ZONE_FRONT, fast_rng)["appeared"] as Array).size()
	t.ok(appeared > 0, "uzun tiklerde de işaret çıkar")

## Tempo artık harcanan bir kaynak: zorlamak takat yakıyor, bitince
## zorlanamıyor.
func _test_pushing_costs_stamina(t) -> void:
	var caravan := CaravanState.new()
	t.eq(caravan.stamina, CaravanState.MAX_STAMINA, "sefer tam takatle başlar")
	t.ok(caravan.can_push(), "dolu takatle zorlanabilir")

	var pushes := 0
	while caravan.can_push() and pushes < 50:
		caravan.apply_stamina_drift(true)
		pushes += 1
	t.ok(pushes > 1, "bir günde tükenmiyor - zorlamak bir kaynak, bir düğme değil")
	t.not_ok(caravan.can_push(), "takat eşiğin altına inince zorlanamaz")

	# Dinlenmek geri kazandırıyor ama zorlamanın yaktığından az: tempo
	# kazancı bedava geri alınamaz.
	t.ok(
		CaravanState.STAMINA_RECOVER_PER_DAY < CaravanState.STAMINA_PUSH_COST_PER_DAY,
		"normal tempoda toparlanmak zorlamaktan yavaştır"
	)
	var before := caravan.stamina
	caravan.apply_stamina_drift(false)
	t.ok(caravan.stamina > before, "zorlamayan gün takat toplar")

	caravan.rest_at_camp()
	t.ok(caravan.can_push(), "kamp zorlamanın çıkışını açar")
	t.le(caravan.stamina, CaravanState.MAX_STAMINA, "takat tavanı aşmaz")
