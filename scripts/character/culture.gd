class_name Culture
extends Resource

## Karakterin geldiği kültür. Stat eğilimi, isim havuzu ve tek bir
## mekanik perk taşır - perkler mevcut sistemlere (erzak, fiyat, savaş,
## dedikodu) bağlanır, yeni bir sistem icat etmez.

@export var culture_id: String = ""
@export var culture_name: String = ""
@export var description: String = ""

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

@export var perk_text: String = ""

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
