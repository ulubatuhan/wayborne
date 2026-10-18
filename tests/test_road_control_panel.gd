extends RefCounted

## Yol kontrol paneli (P18, görevler N16-N23): sekmeler, sorun listesi ve
## sahnenin yukarı kayması. Panel yalnızca okur; burada da yalnızca ne
## söylediği sınanır, nasıl göründüğü ekran görüntüsünün işi
## (screenshot_journey_screen.gd, 01_panel_*).

func suite_name() -> String:
	return "RoadControlPanel"

func run(t) -> void:
	_test_tabs(t)
	_test_problems(t)
	_test_layout_shares(t)

func _session() -> GameSession:
	var session := GameSession.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	session.start_playthrough(CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	return session

func _test_tabs(t) -> void:
	var session := _session()
	var panel := RoadControlPanel.new().setup(session, func(): return {}, null)
	t.eq(panel.get_active_tab(), RoadControlPanel.TAB_PARTY, "panel kadroyla açılır")
	panel.select_tab(RoadControlPanel.TAB_LOG)
	t.eq(panel.get_active_tab(), RoadControlPanel.TAB_LOG, "sekme seçilir")
	panel.select_tab(99)
	t.eq(panel.get_active_tab(), RoadControlPanel.TAB_LOG, "aralık dışı sekme son sekmeye kenetlenir")
	t.eq(RoadControlPanel.TAB_KEYS.size(), 5, "beş sekme: kadro, durum, yük, harita, defter")
	panel.free()

func _test_problems(t) -> void:
	var session := _session()
	session.journey_days_remaining = 0
	var quiet := RoadControlPanel.problems_for(session, {})
	t.eq(quiet.size(), 0, "dolu erzakla, sağlam kadroyla dert yok")
	session.journey_days_remaining = 999
	var short := RoadControlPanel.problems_for(session, {})
	t.ok(short.size() >= 1, "erzak yolu karşılamıyorsa söylenir")
	var hurt := session.get_party()[0]
	hurt.current_hp = 1
	t.ok(RoadControlPanel.problems_for(session, {}).size() > short.size(), "ağır yaralı söylenir")
	var with_signal := RoadControlPanel.problems_for(session, {"signals": ["işaret"]})
	t.ok(with_signal.has("işaret"), "açık yol işaretleri derde eklenir")

func _test_layout_shares(t) -> void:
	# Gökyüzü şeridi kalkar, panel onun açtığı yere oturur: kayma panelden
	# büyük olursa sahnenin altı panelin arkasında kaybolmaz, ama sahne
	# panelin üstünde kalmalı (kervan ekran ortasının altında değil).
	var road: Script = load("res://scripts/ui/road_journey.gd")
	t.ok(road.SKY_CROP_SHARE > 0.0, "sahne yukarı kayar")
	t.ok(road.CONTROL_PANEL_SHARE >= road.SKY_CROP_SHARE, "panel açılan yeri doldurur")
	t.le(road.CONTROL_PANEL_SHARE, 0.34, "panel ekranın üçte birini geçmez")
