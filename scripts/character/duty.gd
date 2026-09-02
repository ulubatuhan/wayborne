class_name Duty
extends Resource

## Kervan yolundaki iş: sınıftan (savaştaki rol) ayrı bir kavram - bir
## karakterin görevi onu yolda/şehirde neyin uzmanı yaptığını belirler.
## DutyCatalog.get_duty_power() bunun gücünü hesaplar; GameSession o gücü
## fiyat/tüketim/onarım gibi somut sistemlere çevirir.

@export var duty_id: String = ""
@export var display_name: String = ""
@export var description: String = ""

## Görevin gücünü hangi statın etkin değeri belirler (bkz.
## CharacterStats.get_effective_value).
@export var primary_stat: CharacterStats.Kind = CharacterStats.Kind.STRENGTH
