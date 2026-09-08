class_name Trait
extends Resource

## Darkest Dungeon tarzı huy: karakterin savaş dışı da taşıdığı küçük bir
## eğilim. "Basic seviyede" kalması bilinçli - kleptomanyaklık gibi
## olay-özel, dramatik huylar burada değil, ileride olay sonuçlarıyla
## (bkz. EventEffect.Type.GRANT_TRAIT) eklenir.

@export var trait_id: String = ""
## Saklanan sey ceviri anahtari (bkz. data/locale/game.csv); gosterilen
## metin asagidaki hesaplanan ozelliklerden okunur. Bu ayrim sayesinde
## bu alanlari okuyan ekranlarin hicbiri degismeden cevrilebilir oldu
## - bkz. CLAUDE.md Localization Rules.
@export var display_name_key: String = ""
@export var description_key: String = ""

var display_name: String:
	get: return tr(display_name_key)

var description: String:
	get: return tr(description_key)

@export var is_positive: bool = true

## Bu huyun daha çok kimde çıkacağını belirleyen stat - seed huy dağıtımı
## bu statın taban üstü/altı olmasına göre ağırlıklanır (bkz. TraitCatalog).
@export var affinity_stat: CharacterStats.Kind = CharacterStats.Kind.STRENGTH

## Küçük, kalıcı düzeltmeler - CharacterData'nın türetilmiş değerlerine
## sınıf/boy bonusuyla aynı yerde eklenir.
@export var hp_bonus: int = 0
@export var dodge_bonus: int = 0
@export var accuracy_bonus: int = 0
@export var crit_bonus: int = 0
@export var damage_bonus: int = 0
