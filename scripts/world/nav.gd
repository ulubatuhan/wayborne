class_name Nav
extends RefCounted

## Sahne yolları ve gezinme yığını.
##
## Eskiden burada tek bir `return_scene` string'i vardı ve bütün "geri"
## tuşları onu okuyordu. Tek bir string **yalnızca bir seviye geçmiş**
## tutabilir: gezinme iki seviye derinleştiği an (şehir → lonca → tayfa)
## o yuvanın üzerine yazılmak zorunda kalınıyor ve yazan ekran başka
## birinin çıkış yolunu yok ediyordu. Oyuncunun loncaya girip tayfa
## aradıktan sonra şehre bir daha çıkamamasının sebebi buydu.
##
## Aynı deliğe üç ayrı yama yapılmıştı - tayfa ekranı için ikinci bir
## değişken, karakter ekranı için sabitlenmiş bir hedef, yol ekranı için
## nokta tablosunda taşınan bir alan. Her yeni ekran dördüncü bir yama
## isteyecekti.
##
## Yığın bunu yapısal olarak çözer: derine inerken `open()` şu anki ekranı
## iter, `back()` bir tane çıkarır. Geri basmak yığını **her zaman
## küçültür**, o yüzden sonsuz bir döngü kurulamaz; derinlik sınırsızdır,
## o yüzden hiçbir ekran başkasının yolunu ezmez.

const WORLD_HUB: String = "res://scenes/world/world_hub.tscn"
const CITY_MAP: String = "res://scenes/world/city_map.tscn"
const MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"
const CHARACTER_CREATION: String = "res://scenes/ui/character_creation.tscn"
const SETTINGS: String = "res://scenes/ui/settings.tscn"
const GOAL_REACHED: String = "res://scenes/ui/goal_reached.tscn"

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

## Kök ekranlar: geri tuşları yoktur, kendi çıkışlarını kendileri taşır
## (şehir kapıdan yola, yol menüye). Bir köke varmak yığını temizler -
## oraya "geri" ile dönülmez, gidilir.
const ROOTS: Array[String] = [WORLD_HUB, CITY_MAP, MAIN_MENU]

## Yığın boşken geri basılırsa buraya düşülür. Asla çıkmazda kalınmaz.
const FALLBACK_ROOT: String = CITY_MAP

## Yığının makul üst sınırı. Aşılması bir ekranın kendini itmesi gibi bir
## hata demektir; sessizce büyümesindense burada kırpılır.
const MAX_DEPTH: int = 16

static var _stack: Array[String] = []

## Tayfa ekranını açan mekân (RecruitCatalog.VENUE_*). Aday havuzu ve
## ücretler buna göre değişir - bu bir gezinme değil, taşınan veri.
static var recruit_venue: String = "tavern"

## Karakter ekranını açan parti index'i - character.gd bunu okuyup hangi
## üyeyi göstereceğine karar verir. Parti değişmişse (biri yol verildi)
## ekran kendi tarafında sınırlara kırpar.
static var character_target_index: int = 0

## Bir köke git: yığın temizlenir. Kök ekranların `_ready`'si bunu çağırır,
## böylece oraya nasıl gelinirse gelinsin (kapıdan, varıştan, menüden)
## geçmiş sıfırlanır ve eski bir yol yanlışlıkla miras kalmaz.
static func go_root(scene_path: String) -> String:
	_stack.clear()
	return scene_path

## Bir alt ekrana in: gönderen ekran yığına itilir.
##
## Hedef bir kökse itilmez, temizlenir - köke inilmez, gidilir. Bunu
## burada yapmak kökün kendi `_ready`'sindeki `go_root`'u yedekler: bir
## ekran kapıyı `open()` ile açtığında da geçmiş doğru sıfırlanır, yoksa
## grafik "şehre geri basınca yola dönersin" gibi yalan bir kenar taşır.
static func open(from_scene: String, to_scene: String) -> String:
	if is_root(to_scene):
		return go_root(to_scene)
	if from_scene != to_scene and not from_scene.is_empty():
		_stack.append(from_scene)
		if _stack.size() > MAX_DEPTH:
			_stack.remove_at(0)
	return to_scene

## Geri: bir seviye çıkar. Yığın boşsa kökten birine düşülür - bir ekran
## "geri" tuşu gösterip hiçbir yere götürmemektense her zaman bir yere
## götürmeli.
static func back() -> String:
	if _stack.is_empty():
		return FALLBACK_ROOT
	return _stack.pop_back()

## Geri tuşunun *yazısı*: nereye döneceğini basmadan görebilmek için.
static func back_label() -> String:
	return label_for(peek())

## Geri basılınca varılacak ekran - yığın tüketilmeden.
static func peek() -> String:
	if _stack.is_empty():
		return FALLBACK_ROOT
	return _stack[_stack.size() - 1]

static func depth() -> int:
	return _stack.size()

static func is_root(scene_path: String) -> bool:
	return ROOTS.has(scene_path)

## Yalnızca testler ve yeni oyun için: gezinme geçmişi oyun durumu değil,
## o yüzden kayda yazılmaz ama yeni bir oyuna eskisinin geçmişiyle
## başlanmamalı.
static func reset() -> void:
	_stack.clear()

## Geri tuşunun yazısı hedefe göre değişir, yoksa oyuncu nereye
## döneceğini tuşa basmadan bilemiyor.
static func label_for(scene_path: String) -> String:
	if scene_path == WORLD_HUB:
		return String(TranslationServer.translate("UI_BACK_TO_ROAD"))
	if scene_path == CITY_MAP:
		return String(TranslationServer.translate("UI_BACK_TO_CITY"))
	if scene_path == MAIN_MENU:
		return String(TranslationServer.translate("UI_BACK_TO_MENU"))
	return String(TranslationServer.translate("UI_BACK"))

## Tayfa ekranı ortak; hangi mekândan girildiğini gönderen ekran bildirir.
## Yığın geldikten sonra bunun tek işi `recruit_venue`'yu taşımak.
static func open_recruit(venue: String, venue_scene: String) -> String:
	recruit_venue = venue
	return open(venue_scene, RECRUIT)
