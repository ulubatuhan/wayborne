class_name Equipment
extends Resource

## Kademeli ekipman parçası. Silah/Zırh, Kervan Avlusu'nda
## parayla alınan kalıcı tier yükseltmeleridir (yalnızca pozitif bonus,
## bkz. EquipmentCatalog). Yüzük/Kolye ise yolda bulunan,
## ödünlü tılsımlardır - bir stat artarken başka biri düşer.
##
## Bonus alanları Trait'inkiyle birebir aynı isimlerde: CharacterData'nın
## türetilmiş değerleri huy ve ekipman bonusunu aynı yerde toplar (bkz.
## CharacterData._equipment_bonus_sum).

@export var equipment_id: String = ""
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

## EquipmentCatalog.SLOT_* değerlerinden biri.
@export var slot: String = ""
## Silah/Zırh için yükseltme kademesi; Yüzük/Kolye'de anlamsız (1 kalır).
@export var tier: int = 1
## Kervan Avlusu'nda satılan parçalarda > 0; yolda bulunan tılsımlarda 0
## (pazarda satılmaz, yalnızca EventEffect.Type.GRANT_EQUIPMENT verir).
@export var price: int = 0

## Bu parçayı kuşanabilmek için gereken seviye. Seviye modeli:
## seviye atlamak *stat vermez*, daha iyi teçhizatın kapısını açar - can,
## hasar ve isabet Demirci'den gelir, seviyeden değil. Wayborne'da tier'lerin
## tek kapısı paraydı, yani seviye ekipman ekseninde hiçbir şey ifade
## etmiyordu; oysa o eksen ölçülen en güçlü eksen (donanımsız %47,
## tam donanımlı %75).
@export var required_level: int = 1

@export var hp_bonus: int = 0
@export var dodge_bonus: int = 0
@export var accuracy_bonus: int = 0
@export var crit_bonus: int = 0
@export var damage_bonus: int = 0

## Huy sinerjisi (görev Y-C06): kuşanan bu huyu taşıyorsa `synergy_bonuses`
## (aynı beş alan) ayrıca eklenir. Yeni bir sistem değil: huy zaten
## CharacterData'nın aynı türetilmiş değerlerine yazıyor.
@export var synergy_trait: String = ""
@export var synergy_bonuses: Dictionary = {}
## Bedel: yoldaki her gün kuşanana bu kadar stres (stresin kendi kapısından,
## `GameSession.change_character_stress`). Gücün bir bedeli var.
@export var daily_stress: int = 0
## Lanetli: kuşanılınca çıkarılamaz, üstüne başka parça da takılamaz; bağı
## yalnız kilise çözer (`GameSession.lift_curse`), parça o zaman yok olur.
@export var cursed: bool = false

func synergy_bonus(field: String, has_trait: bool) -> int:
	if not has_trait or synergy_trait.is_empty():
		return 0
	return int(synergy_bonuses.get(field, 0))

