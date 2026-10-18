class_name RecruitButton
extends RefCounted

## Mekân ekranlarının (Pazar, Taverna, Lonca) "Tayfa Ara" düğmesi.
## Tayfa ekranı ortak; hangi mekândan girildiğini gönderen ekran bildirir
## (bkz. Nav.recruit_venue). Geri tuşu gezinme yığınından döner.
## Düğme geri düğmesinin hemen önüne konur.
static func add_before(back_button: Control, venue: String, own_scene: String) -> void:
	var button := Button.new()
	button.text = TranslationServer.translate("UI_LOOK_FOR_CREW")
	button.pressed.connect(func() -> void: SceneInk.go(Nav.open_recruit(venue, own_scene)))
	var container := back_button.get_parent()
	container.add_child(button)
	container.move_child(button, back_button.get_index())
