extends RefCounted

## Kâtibin sesi (Y-I03): her anın üç satırı var ve çevrilmiş; satır olaydan
## kuyruğa düşer, aynı satır iki kez düşmez.

func suite_name() -> String:
	return "Kâtip"

func run(t) -> void:
	for moment in ScribeLines.LINES:
		var keys: Array = ScribeLines.LINES[moment]
		t.eq(keys.size(), 3, "her an üç satır: %s" % moment)
		for key in keys:
			t.ne(TranslationServer.translate(key), key, "satır çevrilmiş: %s" % key)
	t.eq(ScribeLines.pick("death", "a|1"), ScribeLines.pick("death", "a|1"), "aynı gün aynı satır")
	t.eq(ScribeLines.pick("yok", "a"), "", "bilinmeyen an boş")
	var session := GameSession.new(200, 20, 1)
	session.note_scribe("death")
	session.note_scribe("death")
	t.eq(session.scribe_queue.size(), 1, "aynı satır iki kez düşmez")
	session.scribe_queue.clear()
	session.total_days_elapsed = 59
	session.advance_day()
	t.ok(session.scribe_queue.size() >= 1, "hac yürüyüşü başlayınca kâtip yazar")
	for period in SideriaCalendar.PERIODS:
		t.ok(ScribeLines.has_moment("cal_" + String(period)), "her dönemin satırı var: %s" % period)
