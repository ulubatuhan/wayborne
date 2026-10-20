class_name TextureLoader
extends RefCounted

## Doku yüklemenin tek kapısı. Beş yerde aynı "içe aktarılmışsa `load`, değilse
## diskten oku" mantığı ayrı ayrı yazılmıştı; aralarında küçük farklar vardı
## (biri `globalize_path` kullanıyor, ikisi `FileAccess.file_exists` soruyordu,
## ikisi sormadan var olmayan dosyayı okumaya çalışıp hata basıyordu).

## İçe aktarılmış doku önce; henüz içe aktarılmamış bir PNG (yeni bırakılmış
## resim, test fikstürü) doğrudan diskten okunuyor. Hiçbiri yoksa null.
static func load_any(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

## Küçültülerek çizilen dokular mipmap olmadan kumlanıyor. İçe aktarılan
## dokular mipmap'i içe aktarmadan getiriyor (görev 5.2: project.godot'un
## [importer_defaults] bölümü, .import dosyaları depoda olmasa da CI'de
## geçerli); onlar olduğu gibi döner. Yalnızca diskten ham okunan (henüz içe
## aktarılmamış) dokunun mipmap'li kopyası çalışma anında üretilir.
static func with_mipmaps(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	if tex is CompressedTexture2D:
		return tex
	var image := tex.get_image()
	if image == null or image.is_compressed():
		return tex
	if not image.has_mipmaps():
		image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
