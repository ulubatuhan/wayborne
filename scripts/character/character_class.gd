class_name CharacterClass
extends Resource

## Bir karakterin savaştaki rolü: can bonusu ve kullanabildiği yetenekler.
## `class_name` GDScript'te ayrılmış bir kelime olduğu için görünen ad
## `display_name` alanında durur.

@export var class_id: String = ""
@export var display_name: String = ""
@export var description: String = ""

## Sınıfın taban cana kattığı sabit bonus (stat türevi canın üstüne).
@export var bonus_max_hp: int = 0

## SkillCatalog'daki yetenek kimlikleri. Sıra, savaş panelindeki buton
## sırasıdır.
@export var skill_ids: Array[String] = []
