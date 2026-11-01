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

## Kıtlık paleti (Y-G18, Y-C22): kıtlık derecesi arttıkça dünya solar ve
## kontrast sertleşir. Gokyurt'un derecesi en düşük, o yüzden en geç o solar.
## Yalnızca dünya: HUD bu katmanın üstünde, okunaklı kalır.
const SCARCITY_DESATURATE: float = 0.45
const SCARCITY_SQUEEZE: float = 0.25

static func grade_for(scarcity: float) -> Vector2:
	var d := clampf(scarcity, 0.0, 1.0)
	return Vector2(0.28 + d * SCARCITY_DESATURATE, 0.30 + d * SCARCITY_SQUEEZE)

func set_scarcity(scarcity: float) -> void:
	var g := grade_for(scarcity)
	(material as ShaderMaterial).set_shader_parameter("desaturate", g.x)
	(material as ShaderMaterial).set_shader_parameter("highlight_squeeze", g.y)

