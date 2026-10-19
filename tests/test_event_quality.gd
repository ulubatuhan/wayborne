extends RefCounted

## Kart kalite listesi (Y-E01): liste kartın verisini okur; tek seçenekli,
## risksiz ve yalnızca kaynak takası olan kartı yakalar, iyi kartı geçirir.

func suite_name() -> String:
	return "EventQuality"

func run(t) -> void:
	var trade := GameEvent.new()
	trade.event_id = "q_trade"
	var only := EventChoice.new()
	only.effects = [EventEffect.make(EventEffect.Type.GOLD, 10)]
	trade.choices = [only]
	var found := EventQuality.problems(trade)
	t.ok(found.has(EventQuality.PROBLEM_FEW_CHOICES), "tek seçenek yakalanır")
	t.ok(found.has(EventQuality.PROBLEM_NO_RISK), "risksiz kart yakalanır")
	t.ok(found.has(EventQuality.PROBLEM_TRADE_ONLY), "yalnızca kaynak takası yakalanır")

	var good := GameEvent.new()
	good.event_id = "q_good"
	var safe := EventChoice.new()
	safe.effects = [EventEffect.make(EventEffect.Type.MORALE, -2)]
	var bold := EventChoice.new()
	bold.check = SkillCheck.new()
	var win: Array[EventEffect] = [EventEffect.make(EventEffect.Type.SET_FLAG, 0, "x")]
	var lose: Array[EventEffect] = [EventEffect.make(EventEffect.Type.GOLD, -5)]
	bold.outcomes = [EventOutcome.make("A", win, 1.0), EventOutcome.make("B", lose, 1.0)]
	good.choices = [safe, bold]
	t.ok(EventQuality.passes(good), "iki seçenekli, zarlı, bayrağa dokunan kart geçer")

	var chained := GameEvent.new()
	chained.triggered_only = true
	chained.choices = [only]
	t.not_ok(EventQuality.problems(chained).has(EventQuality.PROBLEM_FEW_CHOICES), "zincir devamı tek seçenekli olabilir")
	t.ok(EventQuality.drawable_count(EventCatalog.get_road_events()) > 0, "katalogda çekilebilir kart sayılır")
