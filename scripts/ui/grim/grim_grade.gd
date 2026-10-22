class_name GrimGrade
extends ColorRect

## Dünya katmanının üstüne serilen kasvetli renk geçişi (grim_grade.gdshader).
## Yol ve hub ekranı kullanıyor; şehir resimleri aynı tonu town_post'ta,
## kapı kesitleri pack_some'da alıyor. HUD'un altında kalmalı: yazı ve
## göstergeler rengini korur.

const SHADER: Shader = preload("res://scripts/ui/grim/grim_grade.gdshader")

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 50
	var m := ShaderMaterial.new()
	m.shader = SHADER
	material = m
