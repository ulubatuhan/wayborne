class_name Duty
extends Resource

## Kervan yolundaki iş: sınıftan (savaştaki rol) ayrı bir kavram - bir
## karakterin görevi onu yolda/şehirde neyin uzmanı yaptığını belirler.
## DutyCatalog.get_duty_power() bunun gücünü hesaplar; GameSession o gücü
## fiyat/tüketim/onarım gibi somut sistemlere çevirir.

@export var duty_id: String = ""

## Saklanan şey çeviri anahtarı (bkz. data/locale/game.csv); gösterilen
## metin aşağıdaki hesaplanan özelliklerden okunur. Bu ayrım sayesinde
## display_name/description okuyan ekranların hiçbiri değişmek zorunda
## kalmadan çevrilebilir hale geldi - bkz. CLAUDE.md Localization Rules.
@export var display_name_key: String = ""
@export var description_key: String = ""

var display_name: String:
	get: return tr(display_name_key)

var description: String:
	get: return tr(description_key)

## Görevin gücünü hangi statın etkin değeri belirler (bkz.
## CharacterStats.get_effective_value).
@export var primary_stat: CharacterStats.Kind = CharacterStats.Kind.STRENGTH
