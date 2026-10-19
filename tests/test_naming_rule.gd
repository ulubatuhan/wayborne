extends RefCounted

## İsim kuralı (görevler 1.1-1.5): depo dosyalarında başka bir oyunun adı
## ve onun terimleri geçmez. Kural iki kez sessizce kırıldı (yeni yazılan bir
## kural metni ve bir harita türü anahtarı), git grep'i hatırlayan olmadı;
## bu test hatırlıyor. Aranan sözcükler burada da düz yazılmıyor, karakter
## kodlarından kuruluyor - yoksa test kendini yakalardı.

const ROOTS: Array[String] = ["res://scripts", "res://tests", "res://data/locale", "res://data/config",
	"res://tools", "res://docs", "res://scenes"]
const EXTENSIONS: Array[String] = ["gd", "py", "md", "csv", "json", "tscn", "cfg", "txt", "yml"]
## Sözcükler: iki harfli kısaltma (yalnızca tek başına bir sözcükse),
## oyunun adının ilk sözcüğü ve oradaki yerleşim teriminin İngilizcesi.
const CODES: Array = [[100, 100], [100, 97, 114, 107, 101, 115, 116], [104, 97, 109, 108, 101, 116]]

func suite_name() -> String:
	return "NamingRule"

func run(t) -> void:
	var regex := RegEx.new()
	var words: Array[String] = []
	for code in CODES:
		var w := ""
		for c in code:
			w += String.chr(int(c))
		words.append(w)
	regex.compile("(?i)\\b" + words[0] + "\\b|" + words[1] + "|" + words[2])
	var hits: Array[String] = []
	var scanned := 0
	for root in ROOTS:
		scanned += _scan(root, regex, hits)
	t.ge(float(scanned), 100.0, "isim kuralı en az yüz dosyayı taradı")
	t.eq(hits.size(), 0, "isim kuralı: depo dosyalarında yasaklı sözcük yok %s" % str(hits.slice(0, 5)))

func _scan(dir_path: String, regex: RegEx, hits: Array[String]) -> int:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return 0
	var count := 0
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		var path := dir_path.path_join(name)
		if dir.current_is_dir():
			if not name.begins_with(".") and name != "__pycache__":
				count += _scan(path, regex, hits)
		elif EXTENSIONS.has(name.get_extension()):
			count += 1
			var text := FileAccess.get_file_as_string(path)
			var found := regex.search(text)
			if found != null:
				hits.append("%s: %s" % [path, found.get_string()])
		name = dir.get_next()
	return count
