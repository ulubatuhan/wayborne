extends RefCounted

## İlk seferin öğretimi (Y-H01): altı konu, her biri bir kez; bayrak kayıtta;
## her konunun cümlesi yazılı.

func suite_name() -> String:
	return "FirstTimeHint"

func run(t) -> void:
	t.eq(FirstTimeHint.TEXT_KEYS.size(), 6, "altı konu")
	for topic in FirstTimeHint.TEXT_KEYS:
		var key := String(FirstTimeHint.TEXT_KEYS[topic])
		t.ok(String(TranslationServer.translate(key)) != key, "cümle yazılı: %s" % topic)
		t.ok(FirstTimeHint.FLAGS.has(topic), "bayrağı var: %s" % topic)
	var session := GameSession.new(200, 20, 1)
	var host := Node.new()
	t.ok(FirstTimeHint.show_once(host, session, FirstTimeHint.TRADE), "ilk karşılaşmada gösterilir")
	t.not_ok(FirstTimeHint.show_once(host, session, FirstTimeHint.TRADE), "ikinci kez gösterilmez")
	t.eq(host.get_child_count(), 1, "tek fiş eklendi")
	var reloaded := GameSession.new(0, 0, 1)
	reloaded.load_from_dict(session.to_save_dict())
	t.not_ok(FirstTimeHint.show_once(host, reloaded, FirstTimeHint.TRADE), "yeniden yüklemeden sonra da gösterilmez")
	t.ok(FirstTimeHint.show_once(host, reloaded, FirstTimeHint.COMBAT), "başka konu ayrı")
	t.not_ok(FirstTimeHint.show_once(host, reloaded, "yok"), "bilinmeyen konu gösterilmez")
	host.free()
