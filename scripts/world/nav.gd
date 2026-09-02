class_name Nav
extends RefCounted

## Sahne yolları tek yerde, ve alt ekranların "geri" tuşunun nereye
## döneceğini taşıyan bağlam. Yola çıkan bir ekrandan girdiysen yola,
## şehirden girdiysen şehre dönersin.

const WORLD_HUB: String = "res://scenes/world/world_hub.tscn"
const CITY_MAP: String = "res://scenes/world/city_map.tscn"
const MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"
const CHARACTER_CREATION: String = "res://scenes/ui/character_creation.tscn"

const ECONOMY: String = "res://scenes/game/market.tscn"
const HAGGLING: String = "res://scenes/game/haggling.tscn"
const TRAVEL: String = "res://scenes/game/world_map.tscn"
const CARAVAN_PLANNER: String = "res://scenes/game/caravan_planner.tscn"
const JOURNEY: String = "res://scenes/game/road_journey.tscn"
const TAVERN: String = "res://scenes/game/tavern.tscn"
const CARAVAN_YARD: String = "res://scenes/game/caravan_yard.tscn"
const GUILD: String = "res://scenes/game/guild.tscn"
const CHURCH: String = "res://scenes/game/church.tscn"
const RECRUIT: String = "res://scenes/game/recruit.tscn"
const COMBAT: String = "res://scenes/game/combat.tscn"
const PARTY: String = "res://scenes/game/party.tscn"
const CHARACTER: String = "res://scenes/game/character.tscn"

## Alt ekranların "geri" tuşu buraya döner.
static var return_scene: String = WORLD_HUB

## Tayfa ekranını açan mekân (RecruitCatalog.VENUE_*). Aday havuzu ve
## ücretler buna göre değişir; gönderen ekran değiştirmekle yükümlü.
static var recruit_venue: String = "tavern"

## Karakter ekranını açan parti index'i - character.gd bunu okuyup hangi
## üyeyi göstereceğine karar verir. Parti değişmişse (biri yol verildi)
## ekran kendi tarafında sınırlara kırpar.
static var character_target_index: int = 0

## Geri tuşunun yazısı hedefe göre değişir, yoksa oyuncu nereye
## döneceğini tuşa basmadan bilemiyor.
static func label_for(scene_path: String) -> String:
	if scene_path == WORLD_HUB:
		return "Yola Dön"
	if scene_path == CITY_MAP:
		return "Şehre Dön"
	if scene_path == MAIN_MENU:
		return "Ana Menüye Dön"
	return "Geri"

static func return_label() -> String:
	return label_for(return_scene)
