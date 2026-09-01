class_name CultureCatalog
extends RefCounted

## Beş kültür. Her biri bir stat eğilimi, bir isim havuzu ve tek bir
## mekanik perk taşır; perkler mevcut sistemlere bağlanır (erzak tüketimi,
## erzak fiyatı, pazar fiyatı, savaş hasarı, dedikodu fiyatı).
##
## Tablo bir kez kurulup statik önbelleğe alınır (bkz. ItemCatalog deseni).

const NOMAD: String = "nomad"
const VALLEY: String = "valley"
const HIGHLAND: String = "highland"
const PORT: String = "port"
const FISHER: String = "fisher"

static var _cultures: Array[Culture] = []
static var _culture_by_id: Dictionary = {}

static func get_cultures() -> Array[Culture]:
	_ensure_built()
	return _cultures

static func get_culture(culture_id: String) -> Culture:
	_ensure_built()
	return _culture_by_id.get(culture_id)

## Kültür bulunamazsa oyunun çökmemesi için ilk kültüre düşer.
static func get_culture_or_default(culture_id: String) -> Culture:
	var culture := get_culture(culture_id)
	if culture != null:
		return culture
	return get_cultures()[0]

static func _ensure_built() -> void:
	if not _cultures.is_empty():
		return

	_cultures.append(_make(
		NOMAD,
		"Göçebe Boyları",
		"Bozkırda doğdun; yol senin evin, kervan senin obandır.",
		{
			CharacterStats.Kind.AGILITY: 2,
			CharacterStats.Kind.ENDURANCE: 1,
			CharacterStats.Kind.INTELLECT: -1,
		},
		["Arslan", "Bayra", "Kutalmış", "Yaruk", "Tegin", "Sarıca", "Bozkurt", "Alpagut"],
		"Yolda günlük erzak tüketimin %30 az."
	))
	_cultures[-1].daily_provision_multiplier = 0.7

	_cultures.append(_make(
		VALLEY,
		"Vadi Loncaları",
		"Taş köprüler ve lonca defterleri arasında büyüdün; rakam senin dilin.",
		{
			CharacterStats.Kind.INTELLECT: 2,
			CharacterStats.Kind.CHARISMA: 1,
			CharacterStats.Kind.STRENGTH: -1,
		},
		["Gerhardt", "Aldric", "Mathis", "Roswitha", "Benedikt", "Hilda", "Konrad", "Elsbeth"],
		"Pazardan alımlarda %10 indirim."
	))
	_cultures[-1].buy_price_multiplier = 0.9

	_cultures.append(_make(
		HIGHLAND,
		"Dağ Kabilesi",
		"Geçitleri koruyan bir kabiledensin; kavga senin için pazarlıktan kolaydır.",
		{
			CharacterStats.Kind.STRENGTH: 2,
			CharacterStats.Kind.ENDURANCE: 1,
			CharacterStats.Kind.CHARISMA: -1,
		},
		["Torgan", "Kaval", "Berku", "Ardıç", "Doruk", "Sarp", "Yıldırak", "Kayra"],
		"Savaşta verdiğin hasar %15 fazla."
	))
	_cultures[-1].combat_damage_multiplier = 1.15

	_cultures.append(_make(
		PORT,
		"Liman Şehri",
		"Rıhtımda beş dil öğrendin; her geminin taşıdığı dedikoduyu bilirsin.",
		{
			CharacterStats.Kind.CHARISMA: 2,
			CharacterStats.Kind.PERCEPTION: 1,
			CharacterStats.Kind.ENDURANCE: -1,
		},
		["Nicolo", "Zara", "Emric", "Salda", "Vito", "Mira", "Andrea", "Kosta"],
		"Tavernada rota dedikodusu %40 ucuz."
	))
	_cultures[-1].rumor_cost_multiplier = 0.6

	_cultures.append(_make(
		FISHER,
		"Balıkçı Kasabası",
		"Ağ onarmayı yürümeden önce öğrendin; sabır ve tuz senin sermayen.",
		{
			CharacterStats.Kind.ENDURANCE: 2,
			CharacterStats.Kind.PERCEPTION: 1,
			CharacterStats.Kind.AGILITY: -1,
		},
		["Baran", "Yelda", "Marta", "Tarık", "Sena", "Duran", "İlkay", "Poyraz"],
		"Erzak satın alımların %25 ucuz."
	))
	_cultures[-1].provision_cost_multiplier = 0.75

	for culture in _cultures:
		_culture_by_id[culture.culture_id] = culture

static func _make(
	culture_id: String, culture_name: String, description: String,
	stat_bonuses: Dictionary, name_pool: Array, perk_text: String
) -> Culture:
	var culture := Culture.new()
	culture.culture_id = culture_id
	culture.culture_name = culture_name
	culture.description = description
	culture.stat_bonuses = stat_bonuses
	var names: Array[String] = []
	for entry in name_pool:
		names.append(entry)
	culture.name_pool = names
	culture.perk_text = perk_text
	return culture
