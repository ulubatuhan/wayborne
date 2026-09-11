class_name CampaignCatalog
extends RefCounted

## Kampanyanın omurgası: sırayla geçilen bölümler. Oyunun bir sonu var,
## ama son bölüm bittiğinde oyun kapanmıyor - `GOAL_GOLD` ekranındaki gibi
## (bkz. goal_reached.tscn) hikâye biter, ticaret sürer. "Sonsuza kadar
## devam edilebilir" tasarım kararı buradan geçiyor: `is_finale` bir
## bitiş değil, bir **eşik**.
##
## Beş bölüm, beşi de oyunda zaten olan sistemlerin diliyle yazıldı - yeni
## bir görev mekaniği yok. Her bölüm oyuncuyu bir sonraki sistemi
## kullanmaya itiyor: önce yolu öğren, sonra kadro kur, sonra ağı gez,
## sonra defteri temizle, en sonunda sermayeyi kur. `EventCondition`
## yalnızca sabitle karşılaştırabildiği için hedefler `build_campaign_
## context()`'in hazır saydığı anahtarlara bakıyor.
##
## Bölüm bitince kurulan bayrak olay havuzuna açılıyor: bir kart
## `HAS_FLAG` ile "kervan artık tanınıyor" durumunu okuyabilir. Kampanyanın
## yola bağlanma yolu bu, ayrı bir sistem değil.

const CHAPTER_FIRST_ROAD: String = "ch_first_road"
const CHAPTER_A_COMPANY: String = "ch_company"
const CHAPTER_THE_NETWORK: String = "ch_network"
const CHAPTER_CLEAN_LEDGER: String = "ch_clean_ledger"
const CHAPTER_THE_HOUSE: String = "ch_house"

const FLAG_FIRST_ROAD: String = "campaign_first_road"
const FLAG_COMPANY: String = "campaign_company"
const FLAG_NETWORK: String = "campaign_network"
const FLAG_CLEAN_LEDGER: String = "campaign_clean_ledger"
const FLAG_HOUSE: String = "campaign_house"

## Hedef satırlarının okunur adı: bağlam anahtarı -> çeviri anahtarı.
## Anahtarlar bilerek tam yazılıyor (`"CAMPAIGN_KEY_%s" % key` değil):
## çalışma anında birleştirilen bir anahtarı ne tanımsız-anahtar taraması
## ne de kodda arama yapan bir çevirmen bulabilir (bkz. Localization Rules).
const OBJECTIVE_LABEL_KEYS: Dictionary = {
	"gold": "CAMPAIGN_OBJ_GOLD",
	"debt": "CAMPAIGN_OBJ_DEBT",
	"reputation": "CAMPAIGN_OBJ_REPUTATION",
	"days": "CAMPAIGN_OBJ_DAYS",
	"party_size": "CAMPAIGN_OBJ_PARTY_SIZE",
	"owned_wagons": "CAMPAIGN_OBJ_WAGONS",
	"journeys_completed": "CAMPAIGN_OBJ_JOURNEYS",
	"contracts_delivered": "CAMPAIGN_OBJ_CONTRACTS",
	"cities_visited": "CAMPAIGN_OBJ_CITIES",
}

## Tanınmayan bir anahtar ekranda ham haliyle görünür - sessizce boş
## kalmaktansa gürültülü olsun.
static func get_objective_label(context_key: String) -> String:
	if not OBJECTIVE_LABEL_KEYS.has(context_key):
		return context_key
	return String(TranslationServer.translate(String(OBJECTIVE_LABEL_KEYS[context_key])))

static var _chapters: Array[CampaignChapter] = []

static func get_chapters() -> Array[CampaignChapter]:
	_ensure_built()
	return _chapters

static func get_chapter(index: int) -> CampaignChapter:
	_ensure_built()
	if index < 0 or index >= _chapters.size():
		return null
	return _chapters[index]

static func get_chapter_by_id(chapter_id: String) -> CampaignChapter:
	for chapter in get_chapters():
		if chapter.chapter_id == chapter_id:
			return chapter
	return null

static func chapter_count() -> int:
	return get_chapters().size()

static func _ensure_built() -> void:
	if not _chapters.is_empty():
		return

	# 1. Yolu tanı: bir sefer tamamla, bir teslimat yap.
	_chapters.append(CampaignChapter.make(
		CHAPTER_FIRST_ROAD,
		"CAMPAIGN_FIRST_ROAD_TITLE",
		"CAMPAIGN_FIRST_ROAD_SUMMARY",
		"CAMPAIGN_FIRST_ROAD_OBJECTIVE",
		[
			EventCondition.make("journeys_completed", EventCondition.Op.GREATER_EQUAL, 1),
			EventCondition.make("contracts_delivered", EventCondition.Op.GREATER_EQUAL, 1),
		],
		FLAG_FIRST_ROAD, 50, 1
	))

	# 2. Kadro kur: bir vagon daha ve yanında yürüyecek insanlar.
	_chapters.append(CampaignChapter.make(
		CHAPTER_A_COMPANY,
		"CAMPAIGN_COMPANY_TITLE",
		"CAMPAIGN_COMPANY_SUMMARY",
		"CAMPAIGN_COMPANY_OBJECTIVE",
		[
			EventCondition.make("party_size", EventCondition.Op.GREATER_EQUAL, 3),
			EventCondition.make("owned_wagons", EventCondition.Op.GREATER_EQUAL, 2),
		],
		FLAG_COMPANY, 120, 2
	))

	# 3. Ağı gez: haritadaki beş şehrin dördünü gör, itibar kazan.
	# İtibar eşiği ölçümle 8'den 5'e indi: 8'de bu bölüm dördüncüyle
	# *aynı* seferde kapanıyordu (ikisinin de ortancası 19. sefer) ve
	# birlikte kapanan iki bölüm iki perde değildir.
	_chapters.append(CampaignChapter.make(
		CHAPTER_THE_NETWORK,
		"CAMPAIGN_NETWORK_TITLE",
		"CAMPAIGN_NETWORK_SUMMARY",
		"CAMPAIGN_NETWORK_OBJECTIVE",
		[
			EventCondition.make("cities_visited", EventCondition.Op.GREATER_EQUAL, 4),
			EventCondition.make("reputation", EventCondition.Op.GREATER_EQUAL, 5),
		],
		FLAG_NETWORK, 200, 2
	))

	# 4. Defteri temizle: borçsuz ve teslimatı oturmuş bir kervan.
	# Borç oyunun cezalandırıcı kolu; onu bir kez kapatmak gerçek bir dönüm.
	# Teslimat eşiği 12'ye çıkarmak denendi ve **geri alındı**: bölümü
	# ayırdı ama finali yarıya düşürdü (6/8 → 3/8). Sebep zincirleme:
	# oyuncu dördüncü bölüm kapanana kadar yalın kervanla teslimat
	# yapıyor, sonra genişliyor; dördüncüyü geciktirmek genişlemeyi de
	# geciktiriyor ve final kırk seferin dışında kalıyordu. Üçüncü
	# bölümden ayrılma işi itibar eşiğinin inmesiyle yapıldı.
	_chapters.append(CampaignChapter.make(
		CHAPTER_CLEAN_LEDGER,
		"CAMPAIGN_CLEAN_LEDGER_TITLE",
		"CAMPAIGN_CLEAN_LEDGER_SUMMARY",
		"CAMPAIGN_CLEAN_LEDGER_OBJECTIVE",
		[
			EventCondition.make("debt", EventCondition.Op.LESS_EQUAL, 0),
			EventCondition.make("contracts_delivered", EventCondition.Op.GREATER_EQUAL, 8),
		],
		FLAG_CLEAN_LEDGER, 250, 3
	))

	# 5. Kendi hanını kur - hikâyenin sonu. Sonrasında oyun kapanmıyor:
	# epilog gösterilir ve serbest ticaret sürer (bkz. is_finale).
	_chapters.append(CampaignChapter.make(
		CHAPTER_THE_HOUSE,
		"CAMPAIGN_HOUSE_TITLE",
		"CAMPAIGN_HOUSE_SUMMARY",
		"CAMPAIGN_HOUSE_OBJECTIVE",
		[
			EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 2500),
			EventCondition.make("owned_wagons", EventCondition.Op.GREATER_EQUAL, 4),
			EventCondition.make("reputation", EventCondition.Op.GREATER_EQUAL, 15),
		],
		FLAG_HOUSE, 0, 5, true
	))
