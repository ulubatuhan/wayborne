class_name CampaignChapter
extends Resource

## Kampanyanın bir bölümü. Oyunun sonu olan bir hikâyesi var, ama son
## bölüm bittiğinde oyun **bitmiyor**: ticaret sonsuza kadar sürebiliyor
## (bkz. CampaignCatalog ve GameSession.advance_campaign).
##
## Hedefler bilerek yeni bir dil icat etmiyor: `EventCondition` neyse o.
## Olay tetikleyicileri zaten düz bir bağlam sözlüğüne bakan, ucuz ve test
## edilmiş bir yapı - bölüm hedefleri de aynı cümleleri kuruyor. Yeni bir
## "quest condition" dili yazmak, aynı işi yapan iki kelime dağarcığı
## demek olurdu ve ikisi ilk günden ayrışmaya başlardı.
##
## Okudukları bağlam farklı ama: `GameSession.build_campaign_context()`
## kervanın **ömrünü** anlatır (kaç sefer, kaç şehir, kaç teslimat),
## `build_event_context()` ise o anki yolu. Bölüm hedefi yol bağlamını
## okusaydı, her varışta kervan sıfırlandığı için tamamlanıp
## tamamlanmamaya geri dönerdi.

@export var chapter_id: String = ""
@export var title_key: String = ""

## Ne olup bittiği (anlatı) ve ne yapılması gerektiği (tek satır hedef).
@export var summary_key: String = ""
@export var objective_key: String = ""

@export var objectives: Array[EventCondition] = []

## Bölüm bittiğinde kurulan bayrak. Olaylar bunu `HAS_FLAG` ile okuyabilir,
## yani hikâye ilerledikçe yolda yeni kartlar açılabilir - kampanyanın
## olay havuzuna bağlanma biçimi bu, ayrı bir mekanizma değil.
@export var completion_flag: String = ""

@export var reward_gold: int = 0
@export var reward_reputation: int = 0

## Son bölüm. Bittiğinde epilog gösterilir ve oyun serbest ticarete geçer.
@export var is_finale: bool = false

func is_complete(context: Dictionary) -> bool:
	return EventCondition.are_all_met(objectives, context)

## Hedeflerin tek tek durumu. İlerlemeyi "tamam/değil" diye göstermek bir
## sayaç hedefinde ("2000 altın biriktir") oyuncuya hiçbir şey söylemez,
## o yüzden sayısal karşılaştırmalarda mevcut değer de taşınıyor.
func describe_progress(context: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for condition in objectives:
		var row := {
			"key": condition.key,
			"met": condition.is_met(context),
			"numeric": false,
			"current": 0.0,
			"target": condition.value,
		}
		if _is_numeric(condition.op) and context.has(condition.key):
			row["numeric"] = true
			row["current"] = float(context[condition.key])
		rows.append(row)
	return rows

func _is_numeric(op: int) -> bool:
	return op == EventCondition.Op.GREATER_EQUAL or op == EventCondition.Op.LESS_EQUAL

static func make(
	chapter_id: String, title_key: String, summary_key: String,
	objective_key: String, objectives: Array[EventCondition],
	completion_flag: String, reward_gold: int = 0, reward_reputation: int = 0,
	is_finale: bool = false
) -> CampaignChapter:
	var chapter := CampaignChapter.new()
	chapter.chapter_id = chapter_id
	chapter.title_key = title_key
	chapter.summary_key = summary_key
	chapter.objective_key = objective_key
	chapter.objectives = objectives
	chapter.completion_flag = completion_flag
	chapter.reward_gold = reward_gold
	chapter.reward_reputation = reward_reputation
	chapter.is_finale = is_finale
	return chapter
