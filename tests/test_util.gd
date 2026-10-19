extends RefCounted

## Ortak yardımcılar: NodeUtil, TextureLoader. Beş yerde ayrı ayrı yazılı
## olan mantığın tek kapıya inmesi (TODO görev 4.3); davranış aynı kalmalı.

const FIXTURE_DIR: String = "user://util_test/"

func suite_name() -> String:
	return "Util"

func run(t) -> void:
	_test_clear_children(t)
	_test_load_any(t)
	_test_with_mipmaps(t)
	_test_reduce_motion(t)
	_test_ambient_redraw(t)

func _test_clear_children(t) -> void:
	var parent := Node.new()
	for i in 3:
		parent.add_child(Node.new())
	t.eq(parent.get_child_count(), 3, "üç çocukla başlar")
	NodeUtil.clear_children(parent)
	# remove_child hemen ayırır: queue_free'yi beklemeden sayı sıfır.
	t.eq(parent.get_child_count(), 0, "çocukların hepsi hemen ayrılır")
	NodeUtil.clear_children(parent)
	t.eq(parent.get_child_count(), 0, "boş kapta tekrar çağrı zararsız")
	parent.free()

func _test_load_any(t) -> void:
	t.ok(TextureLoader.load_any("user://util_test/yok.png") == null, "olmayan dosya null döner")
	t.ok(TextureLoader.load_any("") == null, "boş yol null döner")

	# İçe aktarılmış bir doku: oyunun kendi resmi.
	var imported := TextureLoader.load_any("res://data/assets/fx/fire_01.png")
	t.ok(imported != null, "içe aktarılmış doku yüklenir")

	# İçe aktarılmamış PNG: doğrudan diskten (yeni bırakılmış resim, fikstür).
	DirAccess.make_dir_recursive_absolute(FIXTURE_DIR)
	var path := FIXTURE_DIR + "kare.png"
	var image := Image.create(4, 6, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.4, 0.6, 1.0))
	image.save_png(path)
	var from_disk := TextureLoader.load_any(path)
	t.ok(from_disk != null, "içe aktarılmamış PNG diskten okunur")
	if from_disk != null:
		t.eq(from_disk.get_size(), Vector2(4, 6), "diskten okunan dokunun boyutu doğru")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(FIXTURE_DIR)

	# Bozuk dosya: null, çökme yok.
	DirAccess.make_dir_recursive_absolute(FIXTURE_DIR)
	var bad_path := FIXTURE_DIR + "bozuk.png"
	var file := FileAccess.open(bad_path, FileAccess.WRITE)
	file.store_string("png değil")
	file.close()
	t.ok(TextureLoader.load_any(bad_path) == null, "bozuk dosya null döner")
	DirAccess.remove_absolute(bad_path)
	DirAccess.remove_absolute(FIXTURE_DIR)

func _test_with_mipmaps(t) -> void:
	t.ok(TextureLoader.with_mipmaps(null) == null, "null doku null kalır")
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var plain := ImageTexture.create_from_image(image)
	var result := TextureLoader.with_mipmaps(plain)
	t.ok(result != null, "mipmap'li kopya üretilir")
	if result != null:
		t.ok(result.get_image().has_mipmaps(), "kopyada mipmap var")
		t.eq(result.get_size(), plain.get_size(), "boyut değişmez")

## Ağaçta olmayan bir düğüm (ya da hiç düğüm) "hareketi azalt" demez:
## ayarlar okunamıyorsa hareket açık kalır (görev 4.3).
func _test_reduce_motion(t) -> void:
	t.not_ok(NodeUtil.reduce_motion(null), "düğüm yoksa hareket azaltılmaz")
	var loose := Node.new()
	t.not_ok(NodeUtil.reduce_motion(loose), "ağaçta olmayan düğüm hareketi azaltmaz")
	loose.free()

## Ortam animasyonu çizim temposu (görev 5.1, O-8): ağaçta olmayan (görünmeyen)
## düğüm için sayaç ilerlemez; görünende sayaç birikir ve eşikte sıfırlanır.
func _test_ambient_redraw(t) -> void:
	var item := Control.new()
	t.almost(NodeUtil.ambient_redraw(item, 0.0, 0.5), 0.0, "görünmeyen düğümde sayaç ilerlemez")
	item.free()
	t.ok(1.0 / NodeUtil.AMBIENT_REDRAW_HZ <= 0.05, "ortam animasyonu en az 20 Hz")
