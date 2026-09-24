class_name Culture
extends Resource

## Karakterin geldiği kültür. Stat eğilimi, isim havuzu ve tek bir
## mekanik perk taşır - perkler mevcut sistemlere (erzak, fiyat, savaş,
## dedikodu) bağlanır, yeni bir sistem icat etmez.

@export var culture_id: String = ""
## Saklanan sey ceviri anahtari (bkz. data/locale/game.csv); gosterilen
## metin asagidaki hesaplanan ozelliklerden okunur. Bu ayrim sayesinde
## bu alanlari okuyan ekranlarin hicbiri degismeden cevrilebilir oldu
## - bkz. CLAUDE.md Localization Rules.
@export var culture_name_key: String = ""
@export var description_key: String = ""

var culture_name: String:
	get: return tr(culture_name_key)

var description: String:
	get: return tr(description_key)


## CharacterStats.Kind -> bonus. Eksi değerler de olabilir.
@export var stat_bonuses: Dictionary = {}

@export var name_pool: Array[String] = []

# --- Perkler: her kültürün tek ve net bir avantajı var ---

## Yolda günlük erzak tüketimi çarpanı (göçebeler az yer).
@export var daily_provision_multiplier: float = 1.0
## Erzak satın alma fiyatı çarpanı (balıkçılar ucuza kurutulmuş balık bulur).
@export var provision_cost_multiplier: float = 1.0
## Pazardan mal alma fiyatı çarpanı (vadi loncaları iyi anlaşma yapar).
@export var buy_price_multiplier: float = 1.0
## Savaşta verilen hasar çarpanı (dağ kabilesi sert vurur).
@export var combat_damage_multiplier: float = 1.0
## Tavernadaki rota dedikodusu fiyat çarpanı (liman şehri her dedikoduyu duyar).
@export var rumor_cost_multiplier: float = 1.0

## Perkin oyuncuya gösterilen metni - anahtar saklanır, metin hesaplanır
## (bkz. CLAUDE.md Localization Rules: katalog kaynakları prose değil
## anahtar tutar).
@export var perk_text_key: String = ""

var perk_text: String:
	get: return tr(perk_text_key)

func get_stat_bonus(kind: CharacterStats.Kind) -> int:
	return int(stat_bonuses.get(kind, 0))

## Kültür bonuslarını uygulanmış yeni bir stat seti döner; verilen taban
## değiştirilmez.
func apply_to(base_stats: CharacterStats) -> CharacterStats:
	var stats := base_stats.copy()
	for kind in CharacterStats.KIND_ORDER:
		stats.add_value(kind, get_stat_bonus(kind))
	return stats

## "Güç +2 · Zeka -1" gibi tek satırlık özet.
func get_bonus_summary() -> String:
	var parts: Array[String] = []
	for kind in CharacterStats.KIND_ORDER:
		var bonus := get_stat_bonus(kind)
		if bonus != 0:
			parts.append("%s %+d" % [CharacterStats.kind_name(kind), bonus])
	return " · ".join(parts)
