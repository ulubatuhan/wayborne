class_name BeastSkin
extends Resource

## Bir hayvanın "deri" resmi: tek parça çizilmiş bir resim ve üstüne gerilmiş,
## kemiklere ağırlıkla bağlı bir üçgen ağı (Spine/DragonBones'un "mesh +
## weights" yöntemi). Parçalara kesilmiş sprite'lar her eklemde ya ayrılır
## ya üst üste biner - her parça kendi pivotunda ayrı döndüğü için. Ağda bir
## köşe birden çok kemiği ağırlığıyla izler; eklem bükülür, hiçbir şey
## kopmaz (`tools/beast_skin.py` üretir, `BeastRig` çizer).
##
## Bütün konumlar `ref_h` ölçeğinde, sağa bakan hayvan için: x ileri, y aşağı,
## yer y = 0, x = 0 omuzla kalçanın ortası. Katmanlar alttan üste; uzak
## bacaklar (`layer_far`) ayrı bir resim, yoksa yakın bacağın arkasında
## kalan kısmı hiç çizilmemiş olurdu.

@export var ref_h: float = 256.0
@export var joint_names: PackedStringArray
@export var joint_points: PackedVector2Array
@export var layer_textures: PackedStringArray
@export var layer_far: PackedInt32Array
## Katman k'nın köşeleri [offsets[k], offsets[k+1]) aralığında; üçgen
## dizinleri katmanın kendi köşelerine göre.
@export var layer_vertex_offsets: PackedInt32Array
@export var layer_index_offsets: PackedInt32Array
@export var vertices: PackedVector2Array
@export var uvs: PackedVector2Array
@export var indices: PackedInt32Array
@export var bone_names: PackedStringArray
## Köşe başına üç etki: `bone_names` dizini ve ağırlığı (toplamı 1).
@export var bone_ids: PackedInt32Array
@export var bone_weights: PackedFloat32Array

const INFLUENCES: int = 3

var _joints: Dictionary = {}

func joint(name: String) -> Vector2:
	if _joints.is_empty():
		for i in joint_names.size():
			_joints[joint_names[i]] = joint_points[i]
	return _joints.get(name, Vector2.ZERO)

func has_joint(name: String) -> bool:
	joint("")
	return _joints.has(name)

func layer_count() -> int:
	return layer_textures.size()

var _layer_uvs: Array[PackedVector2Array] = []
var _layer_indices: Array[PackedInt32Array] = []

## Katmanın UV'leri ve üçgenleri - her karede yeniden dilimlenmesin diye bir
## kez kesilip saklanıyor.
func layer_uvs(layer: int) -> PackedVector2Array:
	_slice_layers()
	return _layer_uvs[layer]

func layer_indices(layer: int) -> PackedInt32Array:
	_slice_layers()
	return _layer_indices[layer]

func _slice_layers() -> void:
	if not _layer_uvs.is_empty():
		return
	for layer in layer_count():
		_layer_uvs.append(uvs.slice(layer_vertex_offsets[layer], layer_vertex_offsets[layer + 1]))
		_layer_indices.append(indices.slice(layer_index_offsets[layer], layer_index_offsets[layer + 1]))
