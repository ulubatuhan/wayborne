class_name Equipment
extends Resource

## Darkest Dungeon tarzı ekipman parçası. Silah/Zırh, Kervan Avlusu'nda
## parayla alınan kalıcı tier yükseltmeleridir (yalnızca pozitif bonus,
## bkz. EquipmentCatalog). Yüzük/Kolye ise yolda bulunan, DD trinket'i
## gibi ödünlü tılsımlardır - bir stat artarken başka biri düşer.
##
## Bonus alanları Trait'inkiyle birebir aynı isimlerde: CharacterData'nın
## türetilmiş değerleri huy ve ekipman bonusunu aynı yerde toplar (bkz.
## CharacterData._equipment_bonus_sum).

@export var equipment_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
## EquipmentCatalog.SLOT_* değerlerinden biri.
@export var slot: String = ""
## Silah/Zırh için yükseltme kademesi; Yüzük/Kolye'de anlamsız (1 kalır).
@export var tier: int = 1
## Kervan Avlusu'nda satılan parçalarda > 0; yolda bulunan tılsımlarda 0
## (pazarda satılmaz, yalnızca EventEffect.Type.GRANT_EQUIPMENT verir).
@export var price: int = 0

@export var hp_bonus: int = 0
@export var dodge_bonus: int = 0
@export var accuracy_bonus: int = 0
@export var crit_bonus: int = 0
@export var damage_bonus: int = 0
