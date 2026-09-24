extends RefCounted

## Düğmenin eldeki hissi ve olay seçeneklerinin ayrımı (SENSORY-012/013).
## Görünüşü ekran görüntüsü gösterir; burada kilitlenen: büyüme geniş
## düğmede zıplamaya dönmüyor, her düğmeye tek bir his takılıyor, ve
## "neredeyse" yalnızca gerçekten neredeyse olan kilide deniyor.

const FEEDBACK_PATH: String = "res://scripts/ui/button_feedback.gd"

func suite_name() -> String:
	return "UiFeel"

func run(t) -> void:
	_test_hover_growth_is_bounded(t)
	_test_feedback_attaches_once(t)
	_test_near_miss(t)

func _test_hover_growth_is_bounded(t) -> void:
	var feedback = load(FEEDBACK_PATH)
	t.ok(is_equal_approx(feedback.hover_scale(120.0), 1.03), "dar sekme %3 büyüyor")
	var wide: float = feedback.hover_scale(1000.0)
	t.ok((wide - 1.0) * 1000.0 <= feedback.HOVER_MAX_PIXELS + 0.001, "geniş sıra en çok birkaç piksel büyüyor")
	t.ok(wide > 1.0, "geniş sıra da tepki veriyor")
	t.ok(feedback.PRESS_SCALE < 1.0 and feedback.RELEASE_OVERSHOOT > 1.0, "basış içe, bırakış dışa")

func _test_feedback_attaches_once(t) -> void:
	var feedback = load(FEEDBACK_PATH)
	var button := Button.new()
	feedback.attach(button)
	feedback.attach(button)
	t.ok(button.has_meta(feedback.ATTACHED_META), "düğme işaretlendi")
	t.eq(button.get_child_count(), 0, "his iç çocuk - düğmenin çocuk sayısını değiştirmiyor")
	button.free()

func _test_near_miss(t) -> void:
	var choice := EventChoice.new()
	choice.requirements = [EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 100.0)]
	t.ok(choice.is_near_miss({"gold": 80}), "eşiğin çeyreği içinde: neredeyse")
	t.not_ok(choice.is_near_miss({"gold": 50}), "yarı yolda: neredeyse değil")
	t.not_ok(choice.is_near_miss({"gold": 120}), "açık seçenek neredeyse değil")
	t.not_ok(choice.is_near_miss({}), "bilinmeyen değer neredeyse değil")

	var small := EventChoice.new()
	small.requirements = [EventCondition.make("party_slots_free", EventCondition.Op.GREATER_EQUAL, 1.0)]
	t.ok(small.is_near_miss({"party_slots_free": 0}), "küçük eşikte bir birim eksik: neredeyse")

	var two := EventChoice.new()
	two.requirements = [
		EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 100.0),
		EventCondition.make("reputation", EventCondition.Op.GREATER_EQUAL, 10.0),
	]
	t.not_ok(two.is_near_miss({"gold": 95, "reputation": 9}), "iki eksik varken neredeyse değil")

	var flag := EventChoice.new()
	flag.requirements = [EventCondition.make("has_izci", EventCondition.Op.HAS_FLAG)]
	t.not_ok(flag.is_near_miss({"flags": {}}), "bayrak kilidi sayısal değil, neredeyse olamaz")
