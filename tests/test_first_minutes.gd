extends RefCounted

## İlk dakikaların çizelgesi (Y-H02): dört ilk bir kez işaretlenir, oyun
## süresiyle ve kayıtta; olay seçimi ilk kararı, savaş açan etki ilk tehdidi
## işaretler; testlerde dosyaya yazılmaz.

func suite_name() -> String:
	return "FirstMinutes"

func run(t) -> void:
	var session := GameSession.new(200, 20, 1)
	t.not_ok(session.log_first_times, "oturum varsayılan olarak dosyaya yazmaz")
	session.play_seconds = 95.0
	t.ok(session.mark_first(GameSession.FIRST_DECISION), "ilk karar işaretlendi")
	session.play_seconds = 300.0
	t.not_ok(session.mark_first(GameSession.FIRST_DECISION), "ikinci kez işaretlenmez")
	t.eq(float(session.first_times[GameSession.FIRST_DECISION]), 95.0, "ilk anın süresi kalır")
	var reloaded := GameSession.new(0, 0, 1)
	reloaded.load_from_dict(session.to_save_dict())
	t.eq(reloaded.play_seconds, 300.0, "oyun süresi kayıtta")
	t.ok(reloaded.first_times.has(GameSession.FIRST_DECISION), "ilkler kayıtta")
	for mark in [GameSession.FIRST_DECISION, GameSession.FIRST_THREAT, GameSession.FIRST_LOSS_RISK, GameSession.FIRST_PROFIT]:
		t.ok(GameSession.FIRST_TARGETS.has(mark), "hedefi var: %s" % mark)
	var fresh := GameSession.new(200, 20, 1)
	var effects: Array[EventEffect] = [EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 40, "bandit")]
	EventEffectApplier.apply(effects, fresh)
	t.ok(fresh.first_times.has(GameSession.FIRST_THREAT), "savaş açan etki ilk tehdidi işaretler")
