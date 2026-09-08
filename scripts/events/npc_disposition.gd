class_name NpcDisposition
extends RefCounted

## Yolda karşılaşılan birinin gizli mizacı. Bir yolcuyu kervana almak ya da
## bir kaçak yolcuyu affetmek tek başına iyi ya da kötü bir karar değil -
## kimi aldığına bağlı. Mizaç oyuncuya söylenmez; sezgisi kuvvetli bir
## parti üyesi ancak *ipucu* verebilir.
##
## Mizaç bir bayrağa yazılır (bkz. EventEffect.Type.ROLL_ENCOUNTER) ve
## olayın sonuçları o bayrağa bakar. Kararın faturası hemen kesilmeyebilir:
## kinci biri yemek verilmediğinde susar, günler sonra döner (triggered_only
## bir olayla, bkz. EventCatalog).

const LOYAL: String = "loyal"
const THIEF: String = "thief"
const VENGEFUL: String = "vengeful"
const DESPERATE: String = "desperate"

const ALL: Array[String] = [LOYAL, THIEF, VENGEFUL, DESPERATE]

## Çoğu insan dürüsttür - yoksa kimseyi almamak baskın strateji olurdu ve
## olayın kararı diye bir şey kalmazdı.
const WEIGHTS: Dictionary = {
	LOYAL: 42.0,
	DESPERATE: 24.0,
	THIEF: 18.0,
	VENGEFUL: 16.0,
}

## Mizacı okuyabilmek için gereken Sezgi'nin etkin değeri (bkz.
## CharacterStats.get_effective_value). Taban 5'te sıfır olduğu için bu
## eşik "sezgisine yatırım yapmış biri" demek.
const READ_PERCEPTION_THRESHOLD: float = 2.0

## Manipülasyon (kandırma, söz verme, oyalama) için gereken Karizma eşiği.
const MANIPULATE_CHARISMA_THRESHOLD: float = 2.0

static func roll(rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for disposition in ALL:
		total += float(WEIGHTS[disposition])

	var pick := rng.randf() * total
	var cursor := 0.0
	for disposition in ALL:
		cursor += float(WEIGHTS[disposition])
		if pick <= cursor:
			return disposition
	return LOYAL

## Bayrak adı: "<önek>_<mizaç>". Olayların koşulları bunu okur.
static func get_flag(prefix: String, disposition: String) -> String:
	return "%s_%s" % [prefix, disposition]

## Mizacın oyuncuya gösterilecek adı - yalnızca okunabildiğinde gösterilir.
static func get_label_key(disposition: String) -> String:
	match disposition:
		THIEF:
			return "DISPOSITION_THIEF"
		VENGEFUL:
			return "DISPOSITION_VENGEFUL"
		DESPERATE:
			return "DISPOSITION_DESPERATE"
		_:
			return "DISPOSITION_LOYAL"

## İyi niyetli mi - "aldığın kişi sana zarar verir mi" sorusunun cevabı.
## Çaresiz biri kötü niyetli değildir ama yükü de hafif değildir.
static func is_trustworthy(disposition: String) -> bool:
	return disposition == LOYAL or disposition == DESPERATE
