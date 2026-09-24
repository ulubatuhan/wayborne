class_name CaravanState
extends RefCounted

## Sefer sırasındaki canlı kervan. CaravanPlan seferi planlar,
## CaravanState onu yolda taşır ve olayların hasar verdiği yerdir.

const MIN_WAGONS: int = 1
const MAX_MORALE: int = 100

## Yolun kendisi yıpratır. Moral eskiden yalnızca kesikli olay darbeleriyle
## düşüyordu, o yüzden uzun bir sefer kısa bir seferden daha yorucu
## değildi ve moral tabanı hiç görülmüyordu (bkz. CLAUDE.md Morale Rules).
## Küçük tutuluyor: bir günü tek başına belirlemesin, ama on beş gün
## sonunda kendini göstersin.
const MORALE_DRAIN_PER_DAY: int = 2

## Aşınmanın altına inemeyeceği taban. Kervan yorulur ama yalnızca yürüdüğü
## için isyan etmez - dibe vurmak için gerçekten kötü şeyler olmalı.
##
## Bu yüzden taban isyan eşiğinin (EventCatalog.MUTINY_MORALE_THRESHOLD, 40)
## *üstünde* olmak zorunda. 35'te değildi: yeterince uzun bir yolda yalnızca
## yürümek isyanı uygun hale getirebiliyordu, yani kuralın kendisi kâğıt
## üstünde kalıyordu. Günlük aşınma 2'ye çıkınca bu sınır gerçek bir
## ihtimale dönüştü.
const MORALE_DRIFT_FLOOR: int = 45

var wagon_count: int = MIN_WAGONS
var damaged_wagons: int = 0
var merchant_names: Array[String] = []
var morale: int = MAX_MORALE
var documents: int = 0

## Sefer sonunda ödenecek escort ücreti burada tutulur; bir tüccar
## kervandan ayrılırsa merchant_names'ten düşer ve ücreti ödenmez.
var merchant_profit_by_name: Dictionary = {}

## Sefer başındaki tüccar listesinin değişmez kopyası: finish_journey()
## bunu merchant_names ile karşılaştırıp yolda kimin kaybedildiğini
## (kontratın teslim edilemediğini) bulur ve itibar cezası uygular.
var original_merchant_names: Array[String] = []

## Yabancı tüccarın gizli mizacı (bkz. NpcDisposition) - vagonuna diyalog
## yoluyla bakış (bkz. CLAUDE.md Ana Hedefler'in "#11" notu) bunu okur.
## İsimden türetilmiş sabit bir tohumla atanıyor: aynı isimli bir tüccarla
## ileride tekrar karşılaşmak hep aynı huyu buluyor - kalıcı bir kimlik,
## sefer başına yeniden zar değil. Sefer ortası kaydında `to_dict()` ile
## yazılıyor (bkz. Save & Menu Rules).
var merchant_disposition_by_name: Dictionary = {}

## Yabancı tüccarın vagonunda **gerçekten** taşıdığı yük (bkz.
## MerchantDialoguePanel) - mizacın aksine kalıcı bir kimlik değil, o
## seferin yükü: `merchant_name + journey_start_day`'den tohumlanıyor, aynı
## isimli tüccar farklı bir seferde farklı bir yük taşıyabiliyor ama aynı
## sefer içinde panel her açıldığında aynı yükü gösteriyor (bkz.
## RecruitCatalog'un `location + day` tohumlama deseni). #22'nin orijinal
## tasarım notu "gerçek bir cargo modeli" istiyordu - mizaç tek başına
## yalnızca kişilik anlatıyordu, yük değil. Salt okunur kalıyor: bu
## `Inventory` hiçbir zaman `GameSession.wagon_inventories`'e girmez, yazma
## yolu yok (bkz. Kervan Envanteri Rules'un "ekonomiye sızma riski yok"
## garantisi - bu envanter de aynı garantiyi taşıyor).
var merchant_cargo_by_name: Dictionary = {}

## İzin verilmiş ya da zorla bakılmış tüccarlar - bir kez öğrenilen mizaç
## (ve kargo) aynı sefer içinde tekrar sorulmaz.
var merchant_known_by_name: Dictionary = {}

## Yabancı bir tüccarın vagonunda kaç farklı mal türü taşındığı ve her
## birinin miktar bandı. Küçük tutuluyor (1-3 tür, 3-14 birim) - bu bir
## alışveriş ekranı değil, "vagonuna baktım, şunu şunu taşıyor" hissi.
const MERCHANT_CARGO_ITEM_TYPES: int = 3
const MERCHANT_CARGO_MIN_QUANTITY: int = 3
const MERCHANT_CARGO_MAX_QUANTITY: int = 14

## Sefer başındaki anlık görüntü: kayıp/hasarı GameSession.finish_journey()
## oyuncunun kalıcı sahipliğine adil paylaştırabilsin diye tutulur -
## escort vagonları önce gider, oyuncunun kendi vagonu en son.
## --- Tempo bir tuş değil, harcanan bir kaynak ---
## Hız eskiden 1x/2x/3x butonuydu: bedava, geri alınabilir, sonuçsuz.
## Yani "hızlı git" hiçbir zaman bir karar değildi, çünkü yavaş gitmenin
## de hızlı gitmenin de bir bedeli yoktu.
##
## Şimdi zorlamak dayanıklılık yakıyor. Dayanıklılık bittiğinde kervan
## zorlayamıyor - dinlenmesi gerekiyor. Bu, takvimle (kontrat süresi,
## borç vadesi, mevsim) gerçek bir gerilim kuruyor: acelen varsa
## ödeyeceksin, yoksa günler seni yiyecek.
##
## Not: dayanıklılık **sefere ait**, kalıcı değil - stres o işi zaten
## yapıyor ve iki kalıcı yıpranma sayacı birbirini gölgelerdi.
const MAX_STAMINA: int = 100
const STAMINA_PUSH_COST_PER_DAY: int = 26
const STAMINA_RECOVER_PER_DAY: int = 9
const STAMINA_CAMP_RECOVERY: int = 34
## Bunun altında zorlanamaz. Sıfır değil: tam bitmiş bir kaynağın geri
## dönüşü belirsiz hissettiriyor, görünür bir eşik ise bir karar.
const STAMINA_PUSH_FLOOR: int = 12

var stamina: int = MAX_STAMINA

func can_push() -> bool:
	return stamina >= STAMINA_PUSH_FLOOR

## `pushing` o gün zorlanıp zorlanmadığı. Zorlanmayan gün dinlendiriyor
## ama zorlanan günün yaktığından az: tempo kazancı bedava geri alınamaz.
func apply_stamina_drift(pushing: bool) -> void:
	if pushing:
		stamina = maxi(0, stamina - STAMINA_PUSH_COST_PER_DAY)
	else:
		stamina = mini(MAX_STAMINA, stamina + STAMINA_RECOVER_PER_DAY)

func rest_at_camp() -> void:
	stamina = mini(MAX_STAMINA, stamina + STAMINA_CAMP_RECOVERY)

var wagons_at_start: int = MIN_WAGONS
var player_wagon_count_at_start: int = MIN_WAGONS

## departure_morale, kervanın yola hangi ruh haliyle çıktığı: dünyanın o
## günkü hali belirliyor (bkz. GameSession.get_departure_morale). Verilmezse
## eski davranış - dolu moralle çıkış - korunuyor, yani bu katmanı bilmeyen
## bir çağıran (testler, F1 sahte seferi) etkilenmiyor.
##
## journey_start_day, tüccarın kargosunun tohumu (bkz.
## merchant_cargo_by_name) - verilmezse (0) eski çağıranlar hâlâ
## deterministik, yalnızca hep aynı günden tohumlanmış bir yük görürler.
static func from_plan(
	plan: CaravanPlan, departure_morale: int = MAX_MORALE, journey_start_day: int = 0
) -> CaravanState:
	var state := CaravanState.new()
	state.morale = clampi(departure_morale, 0, MAX_MORALE)
	state.wagon_count = plan.get_total_wagon_count()
	state.wagons_at_start = state.wagon_count
	state.player_wagon_count_at_start = plan.player_wagon_count
	state.documents = plan.get_required_documents()
	for offer in plan.get_selected_offers():
		state.merchant_names.append(offer.merchant_name)
		state.merchant_profit_by_name[offer.merchant_name] = offer.potential_profit
		var disposition_rng := RandomNumberGenerator.new()
		disposition_rng.seed = hash("merchant_disposition|%s" % offer.merchant_name)
		state.merchant_disposition_by_name[offer.merchant_name] = NpcDisposition.roll(disposition_rng)
		state.merchant_cargo_by_name[offer.merchant_name] = _roll_merchant_cargo(
			offer.merchant_name, offer.wagon_count, journey_start_day
		)
	state.original_merchant_names = state.merchant_names.duplicate()
	return state

## Bir tüccarın vagonunun içeriğini tohumdan üretir - erzak hariç,
## `ItemCatalog.get_trade_goods()`'un tamamından 1-3 farklı mal, her biri
## kendi miktar bandında (bkz. MERCHANT_CARGO_*), büyük kontratlar (2
## vagonluk teklifler) orantılı daha kalabalık bir yük taşıyor.
static func _roll_merchant_cargo(merchant_name: String, offer_wagon_count: int, journey_start_day: int) -> Inventory:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("merchant_cargo|%s|%d" % [merchant_name, journey_start_day])

	# `Array.duplicate()` tip vermeden `:=` derleme hatası verir (bkz.
	# CLAUDE.md'nin `:=` / Variant tuzağı) - kaynağa açık tip veriliyor.
	var remaining: Array[Item] = []
	for item in ItemCatalog.get_trade_goods():
		if item.item_id != GameSession.PROVISIONS_ITEM_ID:
			remaining.append(item)

	var cargo := Inventory.new()
	var type_count := mini(MERCHANT_CARGO_ITEM_TYPES, remaining.size())
	for i in range(type_count):
		var index := rng.randi_range(0, remaining.size() - 1)
		var item: Item = remaining[index]
		remaining.remove_at(index)
		var quantity := rng.randi_range(MERCHANT_CARGO_MIN_QUANTITY, MERCHANT_CARGO_MAX_QUANTITY) * offer_wagon_count
		cargo.add_item(item, quantity)
	return cargo

## Sefer ortası kaydı: kervanın o anki hali. Tüccarın kargosu da yazılıyor -
## tohumdan yeniden üretilebilirdi ama yolda değişebilir, yazmak güvenli.
func to_dict() -> Dictionary:
	var cargo := {}
	for merchant_name in merchant_cargo_by_name:
		var inventory: Inventory = merchant_cargo_by_name[merchant_name]
		cargo[merchant_name] = inventory.to_save_array()
	var dispositions := {}
	for merchant_name in merchant_disposition_by_name:
		dispositions[merchant_name] = String(merchant_disposition_by_name[merchant_name])
	return {
		"wagon_count": wagon_count,
		"damaged_wagons": damaged_wagons,
		"merchant_names": merchant_names.duplicate(),
		"original_merchant_names": original_merchant_names.duplicate(),
		"morale": morale,
		"documents": documents,
		"stamina": stamina,
		"wagons_at_start": wagons_at_start,
		"player_wagon_count_at_start": player_wagon_count_at_start,
		"merchant_profit_by_name": merchant_profit_by_name.duplicate(),
		"merchant_disposition_by_name": dispositions,
		"merchant_cargo_by_name": cargo,
		"merchant_known_by_name": merchant_known_by_name.duplicate(),
	}

static func from_dict(data: Dictionary) -> CaravanState:
	var state := CaravanState.new()
	state.wagon_count = maxi(MIN_WAGONS, int(data.get("wagon_count", MIN_WAGONS)))
	state.damaged_wagons = clampi(int(data.get("damaged_wagons", 0)), 0, state.wagon_count)
	for merchant_name in (data.get("merchant_names", []) as Array):
		state.merchant_names.append(String(merchant_name))
	for merchant_name in (data.get("original_merchant_names", []) as Array):
		state.original_merchant_names.append(String(merchant_name))
	state.morale = clampi(int(data.get("morale", MAX_MORALE)), 0, MAX_MORALE)
	state.documents = maxi(0, int(data.get("documents", 0)))
	state.stamina = clampi(int(data.get("stamina", MAX_STAMINA)), 0, MAX_STAMINA)
	state.wagons_at_start = maxi(MIN_WAGONS, int(data.get("wagons_at_start", state.wagon_count)))
	state.player_wagon_count_at_start = maxi(
		MIN_WAGONS, int(data.get("player_wagon_count_at_start", MIN_WAGONS))
	)
	var profits: Dictionary = data.get("merchant_profit_by_name", {})
	for merchant_name in profits:
		state.merchant_profit_by_name[String(merchant_name)] = int(profits[merchant_name])
	var dispositions: Dictionary = data.get("merchant_disposition_by_name", {})
	for merchant_name in dispositions:
		state.merchant_disposition_by_name[String(merchant_name)] = String(dispositions[merchant_name])
	var cargo: Dictionary = data.get("merchant_cargo_by_name", {})
	for merchant_name in cargo:
		var inventory := Inventory.new()
		inventory.load_from_array(cargo[merchant_name] as Array)
		state.merchant_cargo_by_name[String(merchant_name)] = inventory
	var known: Dictionary = data.get("merchant_known_by_name", {})
	for merchant_name in known:
		state.merchant_known_by_name[String(merchant_name)] = bool(known[merchant_name])
	return state

func get_healthy_wagon_count() -> int:
	return maxi(0, wagon_count - damaged_wagons)

## Oyuncunun kendi vagonu asla kaybedilmez: kervan yıkılabilir ama yok olmaz.
func lose_wagons(count: int) -> int:
	var removable := maxi(0, wagon_count - MIN_WAGONS)
	var actually_lost := mini(count, removable)
	wagon_count -= actually_lost
	damaged_wagons = mini(damaged_wagons, wagon_count)
	return actually_lost

## Yolda onarım (bkz. evt_traveling_tinker): şehirdeki kervansaray
## onarımının yol karşılığı. Gerçekten onarılan vagon sayısını döner -
## hasarlıdan fazlası onarılamaz.
func repair_wagons(count: int) -> int:
	var repaired := mini(maxi(0, count), damaged_wagons)
	damaged_wagons -= repaired
	return repaired

func damage_wagons(count: int) -> int:
	var damageable := maxi(0, wagon_count - damaged_wagons)
	var actually_damaged := mini(count, damageable)
	damaged_wagons += actually_damaged
	return actually_damaged

func remove_merchants(count: int) -> Array[String]:
	var removed: Array[String] = []
	for i in range(mini(count, merchant_names.size())):
		removed.append(merchant_names.pop_back())
	return removed

func change_morale(delta: int) -> void:
	morale = clampi(morale + delta, 0, MAX_MORALE)

## Yolda geçen her günün kendi bedeli. Yalnızca tabanın üstündeyken işler:
## yürümenin tek başına kervanı isyana sürüklememesi gerekiyor, oraya
## inmek için olayların da kötü gitmesi lazım.
func apply_daily_drift() -> void:
	if morale <= MORALE_DRIFT_FLOOR:
		return
	morale = maxi(MORALE_DRIFT_FLOOR, morale - MORALE_DRAIN_PER_DAY)

func lose_documents(count: int) -> int:
	var actually_lost := mini(count, documents)
	documents -= actually_lost
	return actually_lost
