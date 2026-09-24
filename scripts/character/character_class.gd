class_name CharacterClass
extends Resource

## Bir karakterin savaştaki rolü: can bonusu ve kullanabildiği yetenekler.
## `class_name` GDScript'te ayrılmış bir kelime olduğu için görünen ad
## `display_name` alanında durur.

@export var class_id: String = ""
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


## Sınıfın taban cana kattığı sabit bonus (stat türevi canın üstüne).
@export var bonus_max_hp: int = 0

## SkillCatalog'daki yetenek kimlikleri. Sıra, savaş panelindeki buton
## sırasıdır.
@export var skill_ids: Array[String] = []

## Seviye atlarken otomatik dağıtımın önceliklendirdiği statlar (bkz.
## CharacterData._auto_allocate_level_up).
@export var stat_affinity: Array[CharacterStats.Kind] = []

## Bu sınıfın "ana" kervan görevi - DutyCatalog.get_duty_power() eşleşince
## görev gücünü katlar. Boş bırakılırsa sınıfın hiçbir görevde bonusu olmaz.
@export var duty_id: String = ""
