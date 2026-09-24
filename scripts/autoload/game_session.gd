class_name GameSession
extends RefCounted

## Oyunun tüm değişken durumu tek yerde. RefCounted olduğu için
## autoload olmadan da örneklenip test edilebilir; GameState autoload'u
## yalnızca kalıcı bir örneği tutar.

const PROVISIONS_ITEM_ID: String = "provisions"
const PROVISIONS_ITEM_NAME: String = "ITEM_PROVISIONS_NAME"
const PROVISIONS_UNIT_PRICE: int = 4

var wallet: Wallet
## Kervanın kargosu artık tek bir paylaşılan havuz değil, vagon başına
## ayrı bir `Inventory` (bkz. CLAUDE.md #22 tasarım notu). `owned_wagon_count`
## uzunluğunda tutulur, `_sync_wagon_inventories()` vagon alınıp
## satıldıkça/kaybedildikçe büyütür ya da küçültür. Hangi vagonun ne
## taşıdığı Atölye'nin tarifleri açısından önemli değil - bu turda tek
## fark eden şey vagonların *toplamı*; okuyucular `get_total_quantity()`/
## `add_to_cargo()`/`remove_from_cargo_or_bags()` üzerinden erişir, tek
## bir vagonu doğrudan okumaz.
var wagon_inventories: Array[Inventory] = []
var caravan: CaravanState

## Borç defteri (bkz. DebtLedger). Kervan yok olmaz ama borca batabilir:
## kese eksiye düşer, açık hesap doğar, vadesi geçerse faiz ve itibar yer.
var debts: DebtLedger

## Pazarın zamana ve oyuncunun kendi ticaretine göre değişen katmanı
## (bkz. MarketConditions): enflasyon, mevsim, arz-talep baskısı ve
## ekonomik/politik şoklar. Fiyatın taban tablosu MarketPricing'de.
var market: MarketConditions

## Yolun o günkü hali (bkz. RouteConditions): sel, çığ, eşkıya. Coğrafya
## WorldMapData'da sabit durur, üstündeki ağ her gün değişir - kapanan bir
## geçit dolambaçlı yolu gerçek bir karara çevirir.
var route_conditions: RouteConditions

## Haritanın büyük, adlı olayları (bkz. WorldEvents): bölgesel savaş, veba,
## ticaret fuarı, haydut haracı. RouteConditions'ın doğal durumlarının
## aksine kendiliğinden atılmaz - yolda duyulan bir haber olayı
## (EventEffect.Type.WORLD_EVENT_START) başlatır.
var world_events: WorldEvents

## Ödemek zorunda olunan bedelin tek yolu - haraç, ceza, gümrük, faiz.
## Kese yetmezse eksiye düşer. İsteğe bağlı alışveriş bundan geçmez
## (bkz. Wallet.spend): oyuncu kendi isteğiyle borca batmaz, olaylar batırır.
func spend_or_owe(amount: int) -> void:
	wallet.force_spend(amount)

## Kesenin eksi bakiyesi ile defterdeki açık hesap aynı paradır; kese her
## değiştiğinde ikisi burada senkronlanır. Ayrı ayrı tutulsalardı oyuncu
## para kazanınca kese artıya geçer ama defterdeki açık hesap olduğu yerde
## kalır, borç iki kez sayılırdı.
func _on_balance_changed(new_balance: int) -> void:
	debts.sync_overdraft(maxi(0, -new_balance), total_days_elapsed)

## Toplam yük: açık hesap (eksi bakiye) + alınmış borçlar. Açık hesap zaten
## defterde olduğu için ayrıca eksi bakiye eklenmiyor.
func get_total_debt() -> int:
	return debts.get_total_owed()

## Borca ödeme: önce kesedeki para kadarı ödenir, fazlası istenmez.
func repay_debt(debt_id: String, amount: int) -> int:
	var payable := mini(maxi(0, amount), maxi(0, wallet.balance))
	if payable <= 0:
		return 0
	var paid := debts.pay(debt_id, payable)
	if paid > 0:
		wallet.spend(paid)
	return paid

## --- Lonca kredisi ---
##
## Oyuncunun *isteyerek* borçlandığı tek yol. `spend_or_owe` mecburi
## ödemedir (haraç, ceza, faiz) ve kervanı istemeden batırır; bu onun tersi:
## yola çıkmadan önce mal almak için bilerek alınan para.
##
## Üç kural bunu para basma düğmesi olmaktan çıkarıyor:
##
## 1. **Kredi hattı itibara bağlı.** Loncanın tanımadığı bir kervancıya
##    verilen para azdır; itibar arttıkça büyür, `LOAN_MAX_LIMIT`'te durur.
## 2. **Hattı *bütün* borçlar tüketir, açık hesap dahil.** Bu, en keskin
##    sömürüyü kapatıyor: borç alıp açık hesabı kapatmak, açık hesabın
##    vadesini bedavaya sıfırlayan bir yapılandırma olurdu (yapılandırmanın
##    ücreti varken). Hat zaten doluysa yeni kredi yok.
## 3. **Tahsis ücreti anaparaya biner ve itibara göre değişir.** 200
##    alırsan (orta itibarda) 220 borçlanırsın, yani zamanında ödesen bile
##    borçlanmak bedava değil - ve loncanın tanımadığı bir kervancı daha
##    kötü şartla borçlanır, tıpkı kredi hattının kendisi gibi.
const LOAN_BASE_LIMIT: int = 200
const LOAN_LIMIT_PER_REPUTATION: int = 25
const LOAN_MAX_LIMIT: int = 1200
## Ücret sabit değil, itibarla **daralan bir bant**: güvensiz bir kervancı
## %15 öder, `LOAN_FEE_REPUTATION_CAP`'e ulaşmış biri %5. Bant 20 itibarda
## tam ortadan (%10) geçiyor - eski sabit oranın değeriydi, bilerek: bu
## depoda zaten reputation=20 ile test edilen üç senaryo var
## (`test_city_commerce.gd`), ortalamayı oraya sabitlemek onları hiç
## dokunmadan doğru bırakıyor.
const LOAN_ORIGINATION_PERCENT_UNTRUSTED: int = 15
const LOAN_ORIGINATION_PERCENT_TRUSTED: int = 5
const LOAN_FEE_REPUTATION_CAP: int = 40
const LOAN_STEP: int = 25
const LOAN_MIN_AMOUNT: int = 25

## Loncanın kapıyı kapattığı nokta. Sıfırın altı "bu kervancı sözünü
## tutmadı" demek - ucuz paranın tam ihtiyaç duyulduğu anda çekilmesi
## bilerek: itibar, defterdeki tek gerçek teminat.
const LOAN_MIN_REPUTATION: int = 0

## Alacaklı adı bir çeviri anahtarı (bkz. DebtPanel'in creditor çözümü).
const LOAN_CREDITOR_KEY: String = "DEBT_CREDITOR_GUILD"

func get_credit_limit() -> int:
	var limit := LOAN_BASE_LIMIT + maxi(0, reputation) * LOAN_LIMIT_PER_REPUTATION
	return mini(limit, LOAN_MAX_LIMIT)

## Hattan geriye kalan: borcun her kuruşu (açık hesap dahil) onu yer.
func get_available_credit() -> int:
	return maxi(0, get_credit_limit() - get_total_debt())

## İtibara göre daralan tahsis ücreti yüzdesi - tam sayı aritmetiğiyle,
## aynı gerekçeyle `get_loan_principal` yukarı yuvarlıyor: oyuncunun
## gördüğü yüzde ile defterdeki tutar kuruşu kuruşuna aynı kalsın.
func get_loan_fee_percent() -> int:
	var spread := LOAN_ORIGINATION_PERCENT_UNTRUSTED - LOAN_ORIGINATION_PERCENT_TRUSTED
	var clamped := clampi(reputation, 0, LOAN_FEE_REPUTATION_CAP)
	return LOAN_ORIGINATION_PERCENT_UNTRUSTED - (spread * clamped) / LOAN_FEE_REPUTATION_CAP

## Alınan paranın üstüne binen ve defterde anapara olarak duran tutar.
## Ücret yukarı yuvarlanır, ama tam sayı aritmetiğiyle.
func get_loan_principal(amount: int) -> int:
	var fee := (amount * get_loan_fee_percent() + 99) / 100
	return amount + fee

## Kredi kapalıysa sebebini anlatan çeviri anahtarı; boşsa açık.
func get_loan_block_reason() -> String:
	if is_journey_active():
		return "UI_GUILD_LOAN_ON_ROAD"
	if reputation < LOAN_MIN_REPUTATION:
		return "UI_GUILD_LOAN_NO_TRUST"
	if get_available_credit() < LOAN_MIN_AMOUNT:
		return "UI_GUILD_LOAN_LINE_FULL"
	return ""

func can_borrow(amount: int) -> bool:
	if not get_loan_block_reason().is_empty():
		return false
	return amount >= LOAN_MIN_AMOUNT and amount <= get_available_credit()

## Parayı keseye yazar, anaparayı (ücretiyle) deftere. Başarısızsa hiçbir
## şey değişmez.
func borrow_from_guild(amount: int) -> bool:
	if not can_borrow(amount):
		return false
	var debt := debts.borrow(
		LOAN_CREDITOR_KEY, get_loan_principal(amount), total_days_elapsed
	)
	if debt == null:
		return false
	wallet.earn(amount)
	return true

## Henüz kimseye takılmamış ekipman: equipment_id -> adet. Kervan
## Avlusu'nda satın alınan Silah/Zırh ve yolda EventEffect.Type.
## GRANT_EQUIPMENT ile bulunan Yüzük/Kolye buraya düşer; karakter ekranı
## (equip_to_character) burdan alıp takar, çıkarınca (unequip_from_character)
## geri buraya koyar - Inventory'nin item_id->miktar deseninin ekipman
## karşılığı.
var equipment_inventory: Dictionary = {}

func add_equipment(equipment_id: String, quantity: int = 1) -> void:
	if quantity <= 0:
		return
	equipment_inventory[equipment_id] = get_equipment_count(equipment_id) + quantity

func get_equipment_count(equipment_id: String) -> int:
	return int(equipment_inventory.get(equipment_id, 0))

func remove_equipment(equipment_id: String, quantity: int = 1) -> bool:
	var current := get_equipment_count(equipment_id)
	if quantity <= 0 or current < quantity:
		return false
	var remaining := current - quantity
	if remaining > 0:
		equipment_inventory[equipment_id] = remaining
	else:
		equipment_inventory.erase(equipment_id)
	return true

## Karaktere bir parça takar: yeni parça depodan düşer, o slotta zaten
## takılı olan (varsa) depoya geri döner. Depoda yoksa hiçbir şey değişmez.
func equip_to_character(character: CharacterData, slot: String, equipment_id: String) -> bool:
	if character == null or not can_equip(character, equipment_id):
		return false
	if not remove_equipment(equipment_id, 1):
		return false
	var previous_id := character.get_equipped_id(slot)
	if not character.equip(slot, equipment_id):
		add_equipment(equipment_id, 1)
		return false
	if not previous_id.is_empty():
		add_equipment(previous_id, 1)
	return true

## Seviye kapısının tek kontrol noktası. Parça satın alınıp depoda
## bekleyebilir - kilitli olan kuşanmak, çünkü depo ortak ama seviye
## kişiseldir: kıdemli bir yoldaşın kuşandığı zırhı yeni katılan çırak
## giyemez (bkz. Equipment.required_level).
func can_equip(character: CharacterData, equipment_id: String) -> bool:
	if character == null:
		return false
	var piece := EquipmentCatalog.get_equipment(equipment_id)
	if piece == null:
		return false
	return character.level >= piece.required_level

## Karakterden bir parçayı çıkarıp depoya geri koyar.
func unequip_from_character(character: CharacterData, slot: String) -> bool:
	if character == null:
		return false
	var previous_id := character.get_equipped_id(slot)
	if previous_id.is_empty() or not character.unequip(slot):
		return false
	add_equipment(previous_id, 1)
	return true

## Kervanın şu an bulunduğu şehir.
var current_location_id: String = WorldMapData.START_LOCATION_ID

## Aktif sefer. journey_destination_id boşsa yolda değiliz.
var journey_origin_id: String = ""
var journey_destination_id: String = ""
var journey_total_days: int = 0
var journey_days_remaining: int = 0

var danger_level: float = 0.0
var reputation: int = 0

## Rotanın kendi tehlike tablosu (bkz. WorldMapData) sabit kalır ama
## kervan ne kadar deneyimli olursa olsun yollar günler geçtikçe daha
## tehlikeli hale gelir - erken oyunun kolaylığı geç oyunda sürmesin
## diye. caravan_planner.gd ve world_map.gd rotanın ham danger_level'ını
## göstermek yerine bunu okur, start_journey() de bununla çağrılır -
## ekranda görülen ile yaşanan tutarlı kalsın diye.
const DANGER_GROWTH_PER_DAY: float = 0.004
const DANGER_GROWTH_CAP: float = 1.6

func get_effective_danger(base_danger: float) -> float:
	var growth := minf(1.0 + DANGER_GROWTH_PER_DAY * float(total_days_elapsed), DANGER_GROWTH_CAP)
	return clampf(base_danger * growth, 0.0, 1.0)

## --- Rotanın o günkü hali ---
## Üç katman, üçü de ayrı: WorldMapData'nın sabit tablosu, yolun o günkü
## durumu (RouteConditions) ve kervanın deneyim eğrisi (get_effective_danger).
## Her ekran bu üçünü tek tek toplamak yerine bunları okur - biri unutulursa
## ekranda görülenle yolda yaşanan ayrışırdı.

func get_route_state(route: TravelRoute) -> RouteConditions.State:
	return route_conditions.get_state(route, total_days_elapsed)

func is_route_open(route: TravelRoute) -> bool:
	return route_conditions.is_open(route, total_days_elapsed)

func get_route_travel_days(route: TravelRoute) -> int:
	return route_conditions.get_travel_days(route, total_days_elapsed)

## Büyük dünya olaylarının (savaş/haraç, bkz. WorldEvents) payı
## RouteConditions'ın kendi durum delta'sının **yanına** ekleniyor, aynı
## headroom formülüyle (`base + delta * (1 - base)`) - iki katman aynı
## rotayı aynı anda vurabiliyor (bir çığ *ve* bir savaş), ikisi de tek bir
## nihai tehlike sayısına toplanıyor.
func get_route_danger(route: TravelRoute) -> float:
	if route == null:
		return 0.0
	var base := route_conditions.get_danger(route, total_days_elapsed)
	var route_key := RouteConditions.route_key(route.from_location_id, route.to_location_id)
	var world_delta := world_events.get_route_danger_delta(route_key, total_days_elapsed)
	var with_world_events := clampf(base + world_delta * (1.0 - base), 0.0, 1.0)
	return get_effective_danger(with_world_events)

## Bir olayın o yol üstünde hâlâ süren müdahalesi var mı (bkz. ROUTE_CHANGE).
func has_route_override(from_id: String, to_id: String) -> bool:
	return route_conditions.has_override(from_id, to_id, total_days_elapsed)

## Kapalı yol çıkmaz sokak değil: dolambaçlı yol varsa şehir dizisini döner.
func find_open_path(destination_id: String) -> Array[String]:
	return route_conditions.find_open_path(
		current_location_id, destination_id, total_days_elapsed
	)

## --- Soy: kervanın adı liderden uzun yaşar ---
## Oyunun kazanma koşulu bir süre `GOAL_GOLD = 5000` idi ve bu, oyunu
## kendi tezine rağmen bir ticaret simülasyonu olarak çerçeveliyordu:
## "asıl konu kervanı çeken insanların yıpranması" diyen bir oyunda hedef
## kesenin dolması olamaz. Hedef kaldırıldı; yerine geçen şey zaten
## kodda yarısı yazılı duran fikirdi - **lider ölür, kervanın adı kalır.**
##
## Oyuncu bir kervan yönetmiyor, bir kervan *adını* yol boyunca taşıyor.
## Her lider bir kuşak; kuşak değişiminde ad, defter ve insanlar kalır.
## Oyun ancak ada sahip çıkacak kimse kalmadığında biter (RUN_OVER_FLAG).
var caravan_name: String = ""

## Kaçıncı kuşak. Lider öldüğünde ve varis geçtiğinde artar - yani bu
## sayı "kaç kez yeniden başladın" değil, "bu ad kaç kez el değiştirdi".
var lineage_generation: int = 1

## Mevcut liderin dönemi bu günde başladı. Kampanya bölümleri bunu
## okuyabiliyor (bkz. build_campaign_context): hikâye kervanın toplam
## yaşına değil, *bu liderin* dönemine bakabilsin diye.
var leader_since_day: int = 0

## Kervanın hafızası - kim geldi, kim gitti, kim öldü, liderlik kime
## geçti. Hiçbir satır silinmiyor (bkz. CaravanLedger).
var ledger: CaravanLedger = CaravanLedger.new()

func get_caravan_name() -> String:
	if not caravan_name.is_empty():
		return caravan_name
	# Adı olmayan bir kayıt (ya da eski kayıt) liderinin adını taşır -
	# kervanlar zaten kurucusunun adıyla anılır.
	return get_player_character().character_name

func get_days_as_leader() -> int:
	return maxi(0, total_days_elapsed - leader_since_day)

## İlk şehir varışında bir kereye mahsus gösterilen atlanabilir ipucu
## katmanının bayrağı (bkz. city_map.gd, scripts/ui/onboarding_panel.gd).
const ONBOARDING_FLAG: String = "onboarding_seen"

## Kervan morali (CaravanState.morale) her seferde sıfırdan başlar - o
## anki seferin ruh hali. Stres bunun tam tersi: seferler arası kalıcı,
## yalnızca şehirde dinlenmek ya da kampta mola vermek azaltır. İkisi de
## ana ekranda ayrı birer çubukla gösterilir (bkz. world_hub.gd).
## Stresin **sahibi artık kişidir** (bkz. CharacterData.stress). Buradaki
## tavan onun takma adı: iki ayrı sayı tutmak, ikisi ayrıştığı gün
## kenetlemenin bir tarafta çalışıp öbüründe çalışmaması demekti.
const MAX_STRESS: int = CharacterData.MAX_STRESS

## Kadronun ortalamasına bakan **mercek**. Okunabilir ve yazılabilir
## olması bilinçli: HUD çubuğu, çıkış morali, olay bağlamı ve
## `evt_stress_brawl` hep "kadro ne hâlde" sorusunu soruyor ve bunun
## cevabı ortalamadır. Ama kimin kırılacağı sorusunun cevabı ortalama
## *değildir* - o yüzden kırılma zarı (bkz. resolve_stress_breaks) ve
## savaşta emir reddi artık kişinin kendi stresini okuyor.
##
## Yazmak kadronun tamamına aynı değeri dağıtıyor: "kervan bu hâlde"
## demenin tek anlamlı karşılığı bu. Boş kadroda yazmak hiçbir şey
## yapmaz, çünkü stres tutacak kimse yoktur.
var party_stress: int:
	get:
		if party.is_empty():
			return 0
		var total := 0
		for character in party:
			total += character.stress
		return int(round(float(total) / float(party.size())))
	set(value):
		var clamped := clampi(value, 0, MAX_STRESS)
		for character in party:
			character.stress = clamped

## Kadronun tamamını aynı miktarda yıpratır/dinlendirir - yol aşınması,
## açlık, kamp, ziyafet ve `EventEffect.Type.STRESS` bunu kullanır.
## Kenetleme kişi başına olduğu için tavana dayanmış biri artırmayı
## yutar, dibe inmiş biri azaltmayı: ortalama üzerinden tek bir
## kenetlemenin gizlediği tam da buydu.
func change_stress(delta: int) -> void:
	for character in party:
		character.change_stress(delta)

## Tek bir kişiyi yıpratır. Yolun "nerede durduğun = neye dikkat ettiğin"
## katmanı ve kişiye özel olaylar bunu kullanıyor.
func change_character_stress(character: CharacterData, delta: int) -> void:
	if character == null:
		return
	character.change_stress(delta)

## Kadrodaki olumsuz huy sayısı. Huy uzun süre yalnızca savaşta bir
## sayıyı bükeyordu - Darkest Dungeon'da ise affliction *görülür ve
## duyulur*. Yol katmanı bunu okuyup işaret sıklığını artırıyor:
## dağılmış bir kadro daha çok aksatır, daha çok geride kalır. Yeni bir
## sistem değil, var olan işaret katmanının çarpanı (bkz. RoadSignals).
func get_affliction_count() -> int:
	var total := 0
	for character in party:
		for trait_resource in character.get_traits():
			if not trait_resource.is_positive:
				total += 1
	return total

## Kadroda kırılma noktasını aşmış olanlar (bkz. CharacterData.is_stressed).
func get_stressed_characters() -> Array[CharacterData]:
	var stressed: Array[CharacterData] = []
	for character in party:
		if character.is_stressed():
			stressed.append(character)
	return stressed

## Yeni gelen sıfırla gelmiyor: batmış bir kervana katılan biri anlatılanları
## duyar, kadronun havasının bir kısmını üstlenir. Sıfırla gelseydi "birini
## gönder, yenisini tut" stresi tek hamlede düşüren bedava bir düğmeye
## dönerdi; bu payla her tur azalan bir getiri veriyor ve her turun ücreti
## var (bkz. hire_cost).
const NEWCOMER_STRESS_SHARE: float = 0.4

## Partiye katılmanın tek kapısı. `dismiss()`in karşılığı: yeni gelenin
## payı burada belirlenir, `party.append()` doğrudan çağrılırsa belirlenmez.
func add_to_party(character: CharacterData) -> void:
	if character == null or party.has(character):
		return
	# Payı *katılmadan önceki* ortalamadan alıyor: kendisi de ortalamaya
	# girdikten sonra okunsaydı kendi sıfırıyla kendi payını düşürürdü.
	var inherited := int(round(float(party_stress) * NEWCOMER_STRESS_SHARE))
	party.append(character)
	character.stress = clampi(inherited, 0, MAX_STRESS)
	_assign_character_id(character)
	ledger.record(
		CaravanLedger.KIND_JOINED, character.character_name,
		total_days_elapsed, lineage_generation, character.character_id
	)

## Kalıcı kimlik sayacı - kayda yazılıyor, yoksa yeniden yüklenen bir oturum
## aynı kimliği ikinci kez dağıtırdı.
var _next_character_serial: int = 1

func _assign_character_id(character: CharacterData) -> void:
	if character == null or not character.character_id.is_empty():
		return
	character.character_id = "c%d_%d" % [total_days_elapsed, _next_character_serial]
	_next_character_serial += 1

## Kadroya ziyafet: paralı stres rahatlaması. Birikme artık şehir varışının
## tek başına eritemeyeceği kadar hızlı (bkz. get_city_rest_relief), o yüzden
## oyuncunun kesesiyle müdahale edebileceği bir kolu olmalı - yoksa stres
## kaçınılmaz bir sayaca dönerdi. Ücret kişi başı, çünkü kalabalık kadroyu
## doyurmak pahalıdır.
const FEAST_COST_PER_HEAD: int = 45
const FEAST_STRESS_RELIEF: int = 22

## Ziyafet günde bir. Ölçüm gösterdi ki sınırsız bırakıldığında beş ziyafet
## 225 GG'ye stresi 90'dan 0'a indiriyordu - bir seferin net kazancının
## altında bir bedelle. Kadroyu bir akşamda beş kez ayıltamazsın; kalıcı
## stat parayla anında silinebiliyorsa kalıcı değildir.
##
## Günler yalnızca yolda ilerlediği için bu pratikte "şehir ziyareti başına
## bir ziyafet" demek. Kayda yazılıyor - yoksa kaydı yeniden yüklemek
## sayacı sıfırlayan bir sömürü olurdu.
var last_feast_day: int = -1

func has_feasted_today() -> bool:
	return last_feast_day == total_days_elapsed

func get_feast_cost() -> int:
	return FEAST_COST_PER_HEAD * maxi(1, party.size())

func can_afford_feast() -> bool:
	if party_stress <= 0 or has_feasted_today():
		return false
	return wallet.can_afford(get_feast_cost())

func throw_feast() -> bool:
	if not can_afford_feast():
		return false
	wallet.spend(get_feast_cost())
	change_stress(-FEAST_STRESS_RELIEF)
	last_feast_day = total_days_elapsed
	return true

## Taverna'da ödeyip öğrenilmedikçe bir rotanın tam tehlike yüzdesi
## bilinmez (bkz. tavern.gd, world_map.gd - kaba bir bant gösterirler).
## "from|to" anahtarlanır; rota simetrik olduğu için öğrenince iki yön
## de kaydedilir.
var known_routes: Dictionary = {}

func is_route_known(from_location_id: String, to_location_id: String) -> bool:
	return known_routes.has(_route_key(from_location_id, to_location_id))

func learn_route(from_location_id: String, to_location_id: String) -> void:
	known_routes[_route_key(from_location_id, to_location_id)] = true
	known_routes[_route_key(to_location_id, from_location_id)] = true

func _route_key(from_location_id: String, to_location_id: String) -> String:
	return "%s|%s" % [from_location_id, to_location_id]

## Savaş partisi. Oyuncunun kendi karakteri partiden çıkarılamaz -
## kim olduğu CharacterData.is_player'dan okunur, sırasından değil;
## sıralama savaştaki mevki sırasıdır ve oyuncu arkaya geçebilir.
## Bu, vagonların taşıdığı isimsiz tayfadan ayrı bir kavramdır: tayfa
## kargo kapasitesini belirler, parti ise savaşa giren adı olan kişilerdir.
##
## Kaç kişi taşıyabildiğin vagon sayısına bağlı (her vagonda iki kişi
## yatar), ama savaş alanı dört mevkiden ibaret olduğu için tavan
## MAX_PARTY_SIZE. Yani vagon almak partiye yer açar - kervansaraydaki
## vagon alımı böylece savaşa da dokunuyor.
const MAX_PARTY_SIZE: int = 4
const PEOPLE_PER_WAGON: int = 2

var party: Array[CharacterData] = []

func get_party_capacity() -> int:
	return clampi(owned_wagon_count * PEOPLE_PER_WAGON, 1, MAX_PARTY_SIZE)

func get_party() -> Array[CharacterData]:
	_ensure_party()
	return party

## Oyuncu partide arkaya geçebildiği için sıraya değil bayrağa bakılır.
func get_player_character() -> CharacterData:
	_ensure_party()
	for character in party:
		if character.is_player:
			return character
	return party[0]

## Karakter oluşturma ekranı çağırır; mevcut parti sıfırlanır.
func set_player_character(character: CharacterData) -> void:
	character.is_player = true
	party = [character]
	_assign_character_id(character)

## Oyunun sabit açılışı: parti her zaman iki kişi (oyuncu + rastgele bir
## yoldaş), bir vagon, rastgele bir şehir. Oyuncu bunların hiçbirini
## seçmiyor - açılış dengesi her yeni oyunda aynı kalsın, çeşitlilik
## yoldaşın kim çıktığından ve nerede uyandığından gelsin diye.
##
## Bir vagon tam iki kişilik yer açar (get_party_capacity), yani kadro
## baştan dolu: üçüncü kişi ancak kervansaraydan vagon alınca gelebilir.
const STARTING_WAGONS: int = 1
const STARTING_PARTY_SIZE: int = 2

func start_playthrough(player_character: CharacterData, rng: RandomNumberGenerator) -> void:
	# Kervan kurucusunun adını taşır; lider değişse de ad kalır.
	caravan_name = player_character.character_name
	lineage_generation = 1
	leader_since_day = 0
	ledger.entries.clear()
	# Defter boş başlamasın: adı senden önce taşıyan biri vardı.
	ledger.record(
		CaravanLedger.KIND_FOUNDER, _roll_founder_name(player_character, rng), 0, 0,
		"", "LEDGER_CAUSE_FOUNDER"
	)
	_assign_character_id(player_character)
	ledger.record(
		CaravanLedger.KIND_LED, player_character.character_name, 0, 1,
		player_character.character_id
	)

	owned_wagon_count = STARTING_WAGONS
	_sync_wagon_inventories()
	owned_wagon_damaged = 0

	set_player_character(player_character)
	add_to_party(RecruitCatalog.build_starting_companion(rng))
	# Tayfa adları liderin kültürüne ve kervanın adına bağlı - ikisi de
	# ancak şimdi belli.
	crew_names.clear()
	_crew_name_serial = 0
	crew_hungry_nights = 0
	_sync_crew_names()

	current_location_id = roll_starting_location(rng)
	_restock_current_location()

	campaign_chapter_index = 0
	journeys_completed = 0
	contracts_delivered = 0
	visited_location_ids = {current_location_id: true}

## Kurucunun adı oyuncunun kültür havuzundan; oyuncunun kendi adıyla
## çakışırsa bir sonrakine geçilir.
static func _roll_founder_name(player_character: CharacterData, rng: RandomNumberGenerator) -> String:
	var pool := player_character.get_culture().name_pool
	if pool.is_empty():
		return ""
	var index := rng.randi_range(0, pool.size() - 1)
	var name := String(pool[index])
	if name == player_character.character_name and pool.size() > 1:
		name = String(pool[(index + 1) % pool.size()])
	return name

## Başlangıç şehri rastgele - her playthrough haritanın başka bir
## köşesinden başlasın, ticaret zinciri (bkz. WorldMapData) farklı bir
## yönden çözülsün diye.
static func roll_starting_location(rng: RandomNumberGenerator) -> String:
	var locations := WorldMapData.get_locations()
	if locations.is_empty():
		return WorldMapData.START_LOCATION_ID
	return locations[rng.randi_range(0, locations.size() - 1)].location_id

func can_recruit() -> bool:
	_ensure_party()
	return party.size() < get_party_capacity()

## Ücreti keseden düşüp partiye katar. Kese yetmezse ya da parti doluysa
## false döner, hiçbir şey değişmez.
func recruit(character: CharacterData) -> bool:
	if not can_recruit():
		return false
	if not wallet.can_afford(character.hire_cost):
		return false
	wallet.spend(character.hire_cost)
	character.is_player = false
	character.heal_full()
	add_to_party(character)
	return true

## Oyuncunun kendisi çıkarılamaz. Kontrol sıraya göre değil bayrağa göre:
## oyuncu arkaya geçtiğinde kendini atabilmesi bir hataydı.
const DISMISSED_CAUSE_KEY: String = "LEDGER_CAUSE_DISMISSED"

## Kaybedilenler: ölenler ve gidenler - ama oyuncunun kendi isteğiyle
## gönderdikleri değil. Geride bırakılan, kırılıp giden, vagonuyla kaybolan
## sayılır; şehirde işten çıkarılan sayılmaz. Olay ve kampanya bağlamı aynı
## sayıyı okur.
func get_companions_lost() -> int:
	return ledger.count_of(CaravanLedger.KIND_DIED) \
		+ ledger.count_of_excluding_cause(CaravanLedger.KIND_DEPARTED, DISMISSED_CAUSE_KEY)

func dismiss(character: CharacterData, cause_key: String = DISMISSED_CAUSE_KEY) -> bool:
	if character == null or character.is_player:
		return false
	var index := party.find(character)
	if index < 0:
		return false
	party.remove_at(index)
	# Kervandan çıkmak defterden çıkmak değil: satır kalır, üstü çizilir.
	ledger.record(
		CaravanLedger.KIND_DEPARTED, character.character_name,
		total_days_elapsed, lineage_generation, character.character_id,
		cause_key, _ledger_location_id()
	)
	return true

## Defter satırının yeri: yoldaysak gidilen şehrin yolu, değilsek bulunulan
## şehir.
func _ledger_location_id() -> String:
	return journey_destination_id if is_journey_active() else current_location_id

## --- Savaşta ölüm ve liderliğin devri ---
## Ölümün iki kapısı var: savaş (bkz. CombatUnit'in Ölümün Kıyısı bölümü,
## herkes girebilir) ve açlık (bkz. apply_meal_distribution). Olay sonuçları
## hiçbir zaman öldürmez - ağır yaralar, can 1'de kenetlenir.
##
## Lider ölürse kervan dağılmaz: oyuncu hayatta kalanlardan birini seçer
## (kıdemli önceden seçili), hikâye onunla sürer. Kimse yoksa oyun biter - oyunun ilk gerçek game-over'ı bu,
## ve tek koşulu "ölen liderin yerine geçecek kimse kalmamış" olması.
const RUN_OVER_FLAG: String = "run_ended_leader_lost"

## Kıdem = hizmet süresi: deftere en erken katılan en kıdemli. Seviye
## eşitlikte karar verir. Eskiden kıdem seviyeydi, yani loncadan geç ama
## yüksek seviyeli tutulan biri kurucudan beri yürüyen bir yoldaşın önüne
## geçiyordu - "kıdem" kelimesinin tam tersi. Parti sırası değil: o sıra
## savaş mevkisi (bkz. Character & Party Rules).
func _compare_seniority(a: CharacterData, b: CharacterData) -> bool:
	var a_joined := get_join_day(a)
	var b_joined := get_join_day(b)
	if a_joined != b_joined:
		return a_joined < b_joined
	if a.level != b.level:
		return a.level > b.level
	return a.xp > b.xp

## Uzun süre birlikte yürümüş olanın yası daha ağır. Kırgınlık herkese
## eşit yazılıyor (ölüm görüldü), ama dün katılanla iki yüz gündür aynı
## yolu yürüyen aynı ölümü aynı yükle taşımıyor. Ağırlık kalıcı kırgınlığa
## değil strese biniyor - stres handa erir, kırgınlık erimez, ve Stress
## Rules'un ölçülmüş ayrılma tavanı böylece yerinde kalıyor.
const SHARED_GRIEF_DAYS: int = 30
const SHARED_GRIEF_STRESS: int = PASSED_OVER_STRESS / 3

func _apply_shared_grief(survivor: CharacterData, dead: Array[CharacterData]) -> void:
	for fallen in dead:
		if fallen == null or fallen == survivor:
			continue
		if get_shared_days(survivor, fallen) >= SHARED_GRIEF_DAYS:
			change_character_stress(survivor, SHARED_GRIEF_STRESS)

## İki kişinin aynı kervanda geçirdiği gün sayısı, defterden.
func get_shared_days(a: CharacterData, b: CharacterData) -> int:
	return maxi(0, total_days_elapsed - maxi(get_join_day(a), get_join_day(b)))

## Adayın, o an lider olan kişinin döneminde kaç gün hizmet ettiği.
## Veraset töreni bunu okuyor: lider öldükten sonra, varis atanmadan önce
## `leader_since_day` hâlâ düşenin dönemini gösteriyor.
func get_days_served_under_leader(candidate: CharacterData) -> int:
	return maxi(0, total_days_elapsed - maxi(get_join_day(candidate), leader_since_day))

## Kişinin deftere ilk katıldığı gün. Katılma satırı olmayan (partiye
## doğrudan yerleştirilmiş, ya da ilk lider) 0 sayılır: en eski dönemden.
func get_join_day(character: CharacterData) -> int:
	var earliest := -1
	for entry in ledger.entries_for_id(character.character_id, character.character_name):
		if String(entry.get("kind", "")) != CaravanLedger.KIND_JOINED:
			continue
		var day := int(entry.get("day", 0))
		if earliest < 0 or day < earliest:
			earliest = day
	return maxi(0, earliest)

## Savaşta kalıcı ölenleri partiden çıkarır, gerekiyorsa liderliği devreder.
## Dönen sözlük ekranın anlatması gerekenleri taşır:
##   dead_names       -> ölen karakterlerin adları
##   new_leader       -> liderlik devredildiyse yeni lider, yoksa null
##   run_over         -> ölen liderin yerine geçecek kimse kalmadı mı
func resolve_combat_deaths(
	dead: Array[CharacterData], cause_key: String = "LEDGER_CAUSE_COMBAT", location_id: String = ""
) -> Dictionary:
	var result := resolve_deaths(dead, cause_key, location_id)
	# Geriye dönük uyumlu yol (simülatörler, eski testler): varis seçilmeyi
	# beklemiyor, en kıdemli kendiliğinden geçiyor. Oyunun kendisi
	# `resolve_deaths()` + `SuccessionPanel` + `appoint_heir()` yolunu kullanır.
	if bool(result.get("awaiting_heir", false)):
		var candidates: Array = result["heir_candidates"]
		appoint_heir(candidates[0])
		result["new_leader"] = candidates[0]
		result["generation"] = lineage_generation
	return result

## Ölümün tek kapısı: savaş, açlık, geride bırakılmanın yol açtığı her ölüm
## buradan geçer. Satıra sebebi ve yeri yazar, hayatta kalanlara "ölüme
## tanık oldu" kırgınlığını ekler. Lider öldüyse varisi **seçmez** - aday
## listesini (kıdem sırasıyla) döner, seçim `appoint_heir()`'ın işi.
##
## Dönen sözlük:
##   dead_names       -> ölen karakterlerin adları
##   new_leader       -> her zaman null (seçim appoint_heir'da)
##   awaiting_heir    -> lider öldü ve yerine geçebilecek biri var
##   heir_candidates  -> kıdem sırasıyla adaylar
##   run_over         -> ölen liderin yerine geçecek kimse kalmadı mı
func resolve_deaths(
	dead: Array[CharacterData], cause_key: String, location_id: String = ""
) -> Dictionary:
	var result := {
		"dead_names": [], "new_leader": null, "run_over": false,
		"awaiting_heir": false, "heir_candidates": [],
	}
	if dead.is_empty():
		return result
	if location_id.is_empty():
		location_id = _ledger_location_id()

	var leader_died := false
	var died_count := 0
	for character in dead:
		if character == null or not party.has(character):
			continue
		died_count += 1
		result["dead_names"].append(character.character_name)
		ledger.record(
			CaravanLedger.KIND_DIED, character.character_name,
			total_days_elapsed, lineage_generation, character.character_id,
			cause_key, location_id
		)
		if character.is_player:
			leader_died = true
			character.is_player = false
		party.erase(character)

	for survivor in party:
		survivor.add_grievance(CharacterData.GRIEVANCE_WITNESSED_DEATH, died_count)
		_apply_shared_grief(survivor, dead)

	if not leader_died:
		return result

	if party.is_empty():
		result["run_over"] = true
		set_flag(RUN_OVER_FLAG)
		return result

	var candidates: Array[CharacterData] = party.duplicate()
	candidates.sort_custom(_compare_seniority)
	result["awaiting_heir"] = true
	result["heir_candidates"] = candidates
	return result

## Liderliği devreder. Sıra savaş mevkisi, liderlik ayrı bir bayrak - varis
## partide yerinden oynatılmıyor. Ad kalır, kuşak ilerler: oyuncu yeni bir
## kervan kurmuyor, aynı adı devralıyor. Kıdemliyi geçip başkasını seçmek
## kıdemliye bir kırgınlık ve stres bırakır - liderliğin kime geçtiği bir
## karar, bir bildirim değil. Yeni kuşak numarasını döner.
const PASSED_OVER_STRESS: int = 15

func appoint_heir(heir: CharacterData) -> int:
	if heir == null or not party.has(heir):
		return lineage_generation
	var candidates: Array[CharacterData] = party.duplicate()
	candidates.sort_custom(_compare_seniority)
	var senior: CharacterData = candidates[0]
	for character in party:
		character.is_player = false
	heir.is_player = true
	if senior != heir:
		senior.add_grievance(CharacterData.GRIEVANCE_PASSED_OVER)
		change_character_stress(senior, PASSED_OVER_STRESS)
	# Dönem sayacı sıfırlanıyor ki kampanya "bu liderin dönemi" diye sorabilsin.
	lineage_generation += 1
	leader_since_day = total_days_elapsed
	ledger.record(
		CaravanLedger.KIND_LED, heir.character_name,
		total_days_elapsed, lineage_generation, heir.character_id
	)
	return lineage_generation

func is_run_over() -> bool:
	return get_phase() == Phase.RUN_OVER

## Parti mevkilerini değiştirir; oyuncu da yer değiştirebilir - sırası
## savaştaki mevkisidir, kim olduğunu belirlemez.
func swap_party_positions(first_index: int, second_index: int) -> bool:
	if first_index == second_index:
		return false
	if first_index < 0 or second_index < 0:
		return false
	if first_index >= party.size() or second_index >= party.size():
		return false
	var temp := party[first_index]
	party[first_index] = party[second_index]
	party[second_index] = temp
	return true

# --- Görevler (Duty): kimin ne iş yaptığı, DutyCatalog.get_duty_power() ---

## Bir görevi bir karaktere verir; aynı görevi tutan başkası varsa
## boşa çıkar - bir görevin tek sahibi olabilir.
func assign_duty(character: CharacterData, duty_id: String) -> void:
	if character == null or not get_party().has(character):
		return
	for other in get_party():
		if other != character and other.duty_id == duty_id:
			other.duty_id = ""
	character.duty_id = duty_id

func get_duty_holder(duty_id: String) -> CharacterData:
	for character in get_party():
		if character.duty_id == duty_id:
			return character
	return null

## Görevin ham gücü: sahibi yoksa 1.0 (nötr - ne bonus ne ceza).
func get_duty_multiplier(duty_id: String) -> float:
	var holder := get_duty_holder(duty_id)
	if holder == null:
		return 1.0
	return DutyCatalog.get_duty_power(holder, duty_id)

## Yüzdesel indirimler için (pazar fiyatı, onarım bedeli gibi):
## 0.0 = indirim yok, tavan %20.
func get_duty_discount(duty_id: String) -> float:
	return clampf((get_duty_multiplier(duty_id) - 1.0) * 0.3, 0.0, 0.2)

## Tam sayı azaltmalar için (günlük erzak tüketimi, vagon hasarı gibi).
## get_duty_discount ile aynı taban: bir görevin kimsesiz kalması hiçbir
## zaman ceza değildir (bkz. DutyCatalog) - ama get_duty_power, kültür
## statı ilgili stat'ta eksiyse (ör. Göçebe'nin INTELLECT -1'i) 1.0'ın
## altına düşebiliyor. Taban olmadan bu, Levazımcı/Otacı gibi görevlere
## atanan kültürel açıdan uygunsuz biri için sonucu kimseye atamamaktan
## daha kötüye çeviriyordu (bkz. simulate_journeys.gd _report_duty_impact -
## bu tabanı olmayan hâliyle "azaltma -1" basıyordu). Sınama yatağı denge
## simülatöründe genişletilirken bu asimetri fark edildi.
func get_duty_flat_reduction(duty_id: String) -> int:
	return maxi(0, int(floor((get_duty_multiplier(duty_id) - 1.0) / 0.2)))

## Partideki en yüksek etkin stat değeri (bkz. CharacterStats.
## get_effective_value). Parti bir ekip: bir işi en uygun olan yapar,
## o yüzden "partide sezgisi kuvvetli biri var mı" sorusu ortalamaya
## değil en iyisine bakar.
## Faz 17: huylar (bkz. CharacterData.get_check_modifier) burada da,
## bir karakterin kendi etkin statına ekleniyor - stat + huy aynı formülde
## birleşiyor, tıpkı savaşın türetilmiş getter'larının hp/dodge/accuracy'yi
## huyla birlikte okuması gibi.
func get_best_effective_stat(kind: CharacterStats.Kind) -> float:
	var best := 0.0
	for character in get_party():
		var effective := character.stats.get_effective_value(kind) + character.get_check_modifier(kind)
		best = maxf(best, effective)
	return best

## `get_best_effective_stat()`'ın sahibi: sayı değil kişi. Bir zar "Sezgi
## %62" diye değil "Elif izleri okuyor, %62" diye sunulsun diye - karar
## isimli birine yapılan bir bahis olur.
func get_best_stat_holder(kind: CharacterStats.Kind) -> CharacterData:
	var best_character: CharacterData = null
	var best := -INF
	for character in get_party():
		var effective := character.stats.get_effective_value(kind) + character.get_check_modifier(kind)
		if effective > best:
			best = effective
			best_character = character
	return best_character

## Bir check'i kimin atacağı: lider check'inde lider, ortak çabada en iyisi.
func get_check_roller(check: SkillCheck) -> CharacterData:
	if check == null:
		return null
	if check.source == SkillCheck.Source.LEADER:
		return get_player_character()
	return get_best_stat_holder(check.stat)

## Liderin (bkz. CharacterData.is_player - liderlik devrinde bu bayrak
## yeni lidere taşınır, bkz. Lineage Rules) kendi etkin statı - "lider
## bunu tek başına göze aldı" diyen skill-check'ler için (bkz. SkillCheck.
## Source.LEADER). Lider yoksa (kuramsal olarak, kervan çöktüyse) 0 döner.
func get_leader_effective_stat(kind: CharacterStats.Kind) -> float:
	var player := get_player_character()
	if player == null:
		return 0.0
	return player.stats.get_effective_value(kind) + player.get_check_modifier(kind)

func party_has_trait(trait_id: String) -> bool:
	for character in get_party():
		if character.has_trait(trait_id):
			return true
	return false

## Zekası taban üstündeki bir huy (Sağduyulu/PRUDENT) kandırma gücüne
## ekleniyor - Karizma zaten manipülasyonun genel ekseni (bkz. Progression
## Rules), huy onun üstüne binen, herkeste çıkmayan bir keskinlik. Karizma'yı
## değiştirmiyoruz, üstüne bir pay ekliyoruz - stat kendi başına yeter,
## huy şansı olan için bir eşiği daha kolay geçirir.
const PRUDENT_MANIPULATION_BONUS: float = 1.5

func get_effective_manipulation() -> float:
	var bonus := PRUDENT_MANIPULATION_BONUS if party_has_trait(TraitCatalog.PRUDENT) else 0.0
	return get_best_effective_stat(CharacterStats.Kind.CHARISMA) + bonus

## --- Yabancı tüccarın vagonuna diyalog yoluyla bakış (bkz. CLAUDE.md Ana
## Hedefler'in "#11" notu) ---
## Kervana kabul edilmiş (eskort olarak taşınan) bir tüccarın vagonuna
## yolda tıklamak bir sohbet açar: izin iste / zorla bak / tekrar ikna et
## / vazgeç. Ödül ekonomik değil - mizacın kendisi (bkz. NpcDisposition),
## Event Character Rules'un zaten kurduğu "oyuncuya söylenmez, yalnızca
## Sezgi ile ipucu" kuralının aynısı. Bu yüzden ekonomiye sızma riski yok
## (bkz. Kervan Envanteri Rules'un "yazma yolu hiç yok" notu).

## Zorla bakmak izin gerektirmiyor ama bedelsiz değil - `HagglingSession.
## WALKOUT_REPUTATION_PENALTY`'nin aynı ailesinden küçük bir itibar bedeli.
const FORCE_LOOK_MERCHANT_REPUTATION_PENALTY: int = 2

## "Tekrar ikna et" - `evt_mutiny`'nin manipüle seçeneğiyle aynı vokabüler
## (get_effective_manipulation), yeni bir sistem icat etmiyor.
const MERCHANT_PERSUASION_BASE_CHANCE: float = 0.25
const MERCHANT_PERSUASION_PER_CHARISMA: float = 0.08
const MERCHANT_PERSUASION_MIN_CHANCE: float = 0.05
const MERCHANT_PERSUASION_MAX_CHANCE: float = 0.85

## LOYAL ve DESPERATE'in saklayacağı bir şey yok; THIEF ve VENGEFUL izin
## vermez - "izin iste" adımının cevabı.
func merchant_grants_permission(merchant_name: String) -> bool:
	var disposition := String(caravan.merchant_disposition_by_name.get(
		merchant_name, NpcDisposition.LOYAL
	))
	return disposition == NpcDisposition.LOYAL or disposition == NpcDisposition.DESPERATE

func attempt_merchant_persuasion(rng: RandomNumberGenerator) -> bool:
	var chance := clampf(
		MERCHANT_PERSUASION_BASE_CHANCE
			+ get_effective_manipulation() * MERCHANT_PERSUASION_PER_CHARISMA,
		MERCHANT_PERSUASION_MIN_CHANCE, MERCHANT_PERSUASION_MAX_CHANCE
	)
	return rng.randf() < chance

func force_look_merchant_wagon(merchant_name: String) -> void:
	caravan.merchant_known_by_name[merchant_name] = true
	change_reputation(-FORCE_LOOK_MERCHANT_REPUTATION_PENALTY)

func grant_merchant_look(merchant_name: String) -> void:
	caravan.merchant_known_by_name[merchant_name] = true

func is_merchant_known(merchant_name: String) -> bool:
	return bool(caravan.merchant_known_by_name.get(merchant_name, false))

## Mizaç yalnızca güçlü Sezgi ile okunur - `ROLL_ENCOUNTER`'ın "oyuncuya
## söylenmez, yalnızca ipucu" kuralının aynısı (bkz. Event Character
## Rules). Bilinmiyorsa (izin/zorla bakış henüz olmadıysa) boş döner.
func get_merchant_disposition_label(merchant_name: String) -> String:
	if not is_merchant_known(merchant_name):
		return ""
	if get_best_effective_stat(CharacterStats.Kind.PERCEPTION) < NpcDisposition.READ_PERCEPTION_THRESHOLD:
		return ""
	var disposition := String(caravan.merchant_disposition_by_name.get(
		merchant_name, NpcDisposition.LOYAL
	))
	return EventEffectApplier.tr_disposition(disposition)

## Vagonun **gerçek** yükü (bkz. CaravanState.merchant_cargo_by_name) -
## mizaç etiketiyle aynı kapıdan geçer (`is_merchant_known`): izin ya da
## zorla bakış olmadan görünmez. Salt okunur bir liste döner, hiçbir yazma
## yolu yok - `Inventory.get_all_entries()`'in kendisi de mutate etmiyor.
func get_merchant_cargo_entries(merchant_name: String) -> Array:
	if not is_merchant_known(merchant_name):
		return []
	var cargo: Inventory = caravan.merchant_cargo_by_name.get(merchant_name)
	if cargo == null:
		return []
	return cargo.get_all_entries()

## Olay kaynaklı stres darbelerine karşı - "dış olaylardan az etkilenir"
## (bkz. CLAUDE.md Faz 13). Bilerek `change_stress()`'in kendisine değil,
## yalnızca buraya eklendi: günlük yol aşınması, kamp ve tempo cezası
## Stress Rules'ta ölçülmüş sayılar - PRUDENT'ı oraya da bulaştırmak o
## ölçümü sessizce geçersiz kılardı. Yalnızca olay etkisi (EventEffect.
## Type.STRESS) bu kapıdan geçiyor, ve yalnızca stresi *yükselten* bir
## darbeyi hafifletiyor - bir olayın stres *azaltan* tarafını (dinlenme,
## iyi haber) kısmıyor değiliz.
const PRUDENT_EVENT_STRESS_RESIST: float = 0.7

func apply_event_stress(delta: int) -> void:
	if delta <= 0:
		change_stress(delta)
		return
	for character in party:
		var amount := delta
		if character.has_trait(TraitCatalog.PRUDENT):
			amount = int(round(float(delta) * PRUDENT_EVENT_STRESS_RESIST))
		character.change_stress(amount)

## Tüm partiye (ya da verilirse yalnızca `targets`'a) eşit XP dağıtır,
## kimin kaç seviye atladığını döner (isim -> seviye sayısı; hiç atlamayan
## kişi listede yer almaz). `targets` boşsa eski davranış: sefer varışı ve
## olay ödülleri hâlâ yoldaki herkese dağıtıyor. Savaş artık bir istisna -
## `PreCombatPanel`de dışarıda bırakılan kimse deneyim kazanmıyor, çünkü
## risk almadı.
func grant_party_xp(amount: int, targets: Array[CharacterData] = []) -> Dictionary:
	var levels_gained: Dictionary = {}
	if amount <= 0:
		return levels_gained
	var recipients := targets if not targets.is_empty() else get_party()
	for character in recipients:
		var gained := character.gain_xp(amount)
		if gained > 0:
			levels_gained[character.character_name] = gained
	return levels_gained

## DD tarzı kırılma zarı: her kırılabilir (bkz. CharacterData.is_stressed)
## karakter için bir kez atılır, çoğunlukla olumsuz bir huy bırakır,
## nadiren tam tersine olumlu bir huy verir. Ağır kırılan bir yoldaş
## (oyuncu hariç) kervandan ayrılabilir - kırılma huy vermeyi başaramasa
## bile (tavan dolu) ayrılık ihtimali işler, çünkü sorun huyun kendisi
## değil, karakterin dayanma noktasının aşılmış olması.
const BREAK_AFFLICTION_CHANCE: float = 0.85
const BREAK_DEPARTURE_CHANCE: float = 0.2

## Kırgınlık ayrılma zarını büyütür: aç bırakılan, savaşın dışında
## tutulup kaybı izleyen, liderlikte geçilen biri kırıldığında gitmeye daha
## yakındır. Yalnızca zaten kırılmış birinde işler - kırılma eşiğinin
## kendisine dokunmuyor, Stress Rules'un ölçülmüş tablosu korunuyor.
const GRIEVANCE_DEPARTURE_PER_POINT: float = 0.03
const MAX_BREAK_DEPARTURE_CHANCE: float = 0.6

func get_break_departure_chance(character: CharacterData) -> float:
	return minf(
		MAX_BREAK_DEPARTURE_CHANCE,
		BREAK_DEPARTURE_CHANCE + GRIEVANCE_DEPARTURE_PER_POINT * float(character.get_grievance_total())
	)

func resolve_stress_breaks(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	# Kopya üzerinde geziniyoruz: dismiss() partiden çıkarabiliyor, canlı
	# diziyi gezerken elemanı silmek sıradaki karakteri atlatırdı. Array.
	# duplicate() eleman tipini statik olarak taşımıyor - açık tip
	# yazılmazsa character Variant'a düşüp altındaki grant_trait() çağrısının
	# dönüş tipini çıkaramıyor (bkz. CLAUDE.md'deki := / Variant tuzağı).
	var stressed_party: Array[CharacterData] = get_party().duplicate()
	for character in stressed_party:
		if not character.is_stressed():
			continue

		var affliction := rng.randf() < BREAK_AFFLICTION_CHANCE
		var trait_id := TraitCatalog.roll_break_trait(character.stats, rng, not affliction)
		var granted := character.grant_trait(trait_id, total_days_elapsed)

		var departed := false
		if affliction and not character.is_player \
				and rng.randf() < get_break_departure_chance(character):
			var cause := "LEDGER_CAUSE_BROKE"
			var top := character.get_top_grievance()
			if top == CharacterData.GRIEVANCE_UNFED or top == CharacterData.GRIEVANCE_PASSED_OVER:
				cause = "LEDGER_CAUSE_BROKE_GRIEVANCE"
			departed = dismiss(character, cause)

		results.append({
			"character_name": character.character_name,
			"affliction": affliction,
			"trait_id": trait_id if granted else "",
			"departed": departed,
		})
	return results

## Yolda mola: bir günü kaybederek stresi belirgin azaltır - şehre
## varmadan nefes almanın tek yolu (bkz. road_journey.gd _on_camp_pressed).
## Gün ilerletme/erzak tüketimi çağıran tarafın işi, burada yalnızca
## kampın kendi payı var.
const CAMP_PROVISIONS_COST: int = 3
## Kamp eskiden 20 götürüyordu. Ölçüm bunun stresi tek başına sildiğini
## gösterdi: sefer başına ~25 stres, kamp -20, varış -14 -> her sefer kamp
## kuran oyuncuda stres 12 sefer boyunca 20'nin üstüne çıkmıyordu. Yani
## eşiği ve varış rahatlamasını düzeltmek sorunu çözmüyor, yalnızca yerini
## değiştiriyordu.
##
## Artık kamp birikmeyi **yavaşlatıyor**, silmiyor: bir gecelik mola bir
## seferin yükünün üçte birini alıyor. Kesenin kolu (ziyafet) ondan güçlü,
## çünkü onun bir bedeli var.
const CAMP_STRESS_RELIEF: int = 8

## Yolda geçen her günün gerginlik bedeli - CaravanState.MORALE_DRAIN_PER_DAY'in
## stres karşılığı. Uzun süre yoktu ve fark edilmiyordu, çünkü yerini bir hata
## dolduruyordu: açlık cezası doğru stoklanmış her seferde de işlediği için
## sefer başına ~25 stres birikiyordu. Açlık düzeltilince (bkz. Provision
## Rules) varış stresi 8'e düştü ve stresin seferler arası birikmesi -
## kalıcı olmasının bütün anlamı - yeniden ortadan kalktı.
##
## Küçük tutuluyor: bir seferin yükünü olaylar ve savaş belirlemeli, yol
## yalnızca tabanı koymalı.
const ROAD_STRESS_PER_DAY: int = 2

## Faz 17 PR-3'ün bilerek dar bırakılan ilk kancası, tamamlandı: taban
## `ROAD_STRESS_PER_DAY` her karakterde aynıydı, Demir/Zayıf Bünye'nin
## kendi dayanıklılığı yalnızca kırılma *eşiğine* bakıyordu, günün
## kendisinin yıpratma hızına hiç değmiyordu. `change_stress()`'in
## kadronun tamamına aynı değeri dağıtan genel kapısı bilerek
## dokunulmadan kalıyor (famine/kamp/ziyafet/EventEffect.STRESS hâlâ
## uniform) - yalnızca yolun *kendi* günlük payı artık kişi başına
## `CharacterData.get_daily_stress_gain_multiplier()`'ı okuyor.
func _apply_road_stress_day() -> void:
	for character in party:
		var delta := int(round(
			float(ROAD_STRESS_PER_DAY) * character.get_daily_stress_gain_multiplier()
		))
		character.change_stress(delta)

## Otacı'nın görevi tam bu - "kampta yaraları ve gerginliği sarar" (bkz.
## DutyCatalog) - tutan biri varsa kampın rahatlatma payını büyütür.
func make_camp() -> Dictionary:
	var paid := mini(CAMP_PROVISIONS_COST, get_provisions())
	change_provisions(-paid)
	var relief := CAMP_STRESS_RELIEF + get_duty_flat_reduction(DutyCatalog.OTACI) * 2
	change_stress(-relief)
	# Kamp takati de tazeliyor: zorlamanın bedeli var ama çıkışı da var,
	# yoksa bir kez zorlayan kervan seferin geri kalanını sürünerek
	# bitirirdi (bkz. CaravanState'in tempo bölümü).
	caravan.rest_at_camp()
	return {"provisions_spent": paid, "stress_relief": relief}

func heal_party() -> void:
	for character in party:
		character.heal_full()

## Kayıtsız/eski bir oturumda bile savaşa sokacak birinin bulunması için
## varsayılan bir karakter kurar.
func _ensure_party() -> void:
	if party.is_empty():
		var culture := CultureCatalog.get_cultures()[0]
		var fallback := CharacterData.create(
			culture.name_pool[0], culture.culture_id, CharacterStats.new()
		)
		fallback.is_player = true
		party = [fallback]

# --- Kültür perkleri: tek yerden okunur, ekranlar formülü kopyalamaz ---

func get_player_culture() -> Culture:
	return get_player_character().get_culture()

func get_daily_provision_multiplier() -> float:
	return get_player_culture().daily_provision_multiplier

## Yolda bir günün erzak faturası. Planlayıcının gösterdiği sayıyla aynı
## formülden çıkar (bkz. CaravanPlan.daily_consumption) - kültür perki ve
## levazımcı indirimi dahil, yoksa planlayıcı yolda yenmeyecek bir sayı
## gösterir.
func get_daily_provision_consumption() -> int:
	var party := get_party()
	return CaravanPlan.daily_consumption(
		party.size(),
		owned_wagon_count,
		caravan.merchant_names.size(),
		get_daily_provision_multiplier(),
		get_duty_flat_reduction(DutyCatalog.LEVAZIMCI),
		CaravanPlan.height_adjustment_for(party)
	)

## Akşam sofrası: erzak artık her gün sessizce, herkese eşit dağılmıyor -
## oyuncu kime yediğini seçiyor (bkz. `MealDistributionPanel`). "Ekip"
## (isimli parti) ve "kervan" (vagon tayfası + kervana katılan tüccarlar -
## isimsiz, tek tek hedeflenemez) ayrı iki lokma: toplam ihtiyaç hâlâ
## `get_daily_provision_consumption()`'dan geliyor - erzak hesabının tek
## yerde durması kuralı burada da geçerli, bu yalnızca o toplamı kime
## dağıtacağını seçiyor.
const MEAL_MODE_ALL: String = "all"
const MEAL_MODE_PARTY_ONLY: String = "party_only"
const MEAL_MODE_CREW_ONLY: String = "crew_only"
const MEAL_MODE_SPECIFIC: String = "specific"
const MEAL_MODE_SELF_ONLY: String = "self_only"

## Kişi başına açlığın bedeli - kim aç kaldıysa doğrudan onun stresine
## işler (bkz. Stress Rules'un "stres bir kişiye ait" maddesi), ortalamaya
## değil. Kervan/tayfa aç kalırsa kimse kişisel bir stres almaz (isimsiz),
## ama moral bir kez düşer - herkes bunu hissediyor.
const PERSONAL_HUNGER_STRESS: int = 6
## Art arda aç geçen üçüncü günden itibaren her aç gün can yer. Doğru
## stoklayıp herkesi doyuran bir kervanda sayaç hiç artmaz (bkz. Provision
## Rules'un "correct stocking never starves" sözü) - bu yalnızca seçilerek
## ya da kıtlıkla aç bırakılanı bulur.
const STARVATION_HP_LOSS_START_DAY: int = 3
const STARVATION_HP_LOSS_PER_DAY: int = 4
const MEAL_HUNGER_MORALE_PENALTY: int = -8
## Tayfanın açlığı da birikiyor. Eskiden tayfayı aç bırakmak, tek bir
## isimli kişiyi aç bırakmakla aynı tek seferlik moral düşüşüydü - ve
## tayfa ağızların çoğu olduğu için "yalnızca ekip yesin" hep en ucuz
## seçimdi; isimsizler hiç sayılmıyordu. Art arda her aç gece moral biraz
## daha düşüyor, ve üçüncü geceden itibaren her gece tayfadan biri açlıktan
## ölüyor - deftere adıyla.
const CREW_HUNGER_MORALE_PER_NIGHT: int = 3
const MAX_CREW_HUNGER_MORALE_PENALTY: int = -20
var crew_hungry_nights: int = 0

## Bu kip seçilirse sofraya kim oturuyor - dağıtımın kendisi ve sofra
## ekranının kâseleri aynı cevabı okuyor, iki yerde iki ayrı kural olmasın.
func get_meal_fed_party(mode: String, selected: Array[CharacterData] = []) -> Array[CharacterData]:
	var named_party := get_party()
	var fed: Array[CharacterData] = []
	match mode:
		MEAL_MODE_CREW_ONLY:
			pass
		MEAL_MODE_SPECIFIC:
			for character in named_party:
				if selected.has(character):
					fed.append(character)
		MEAL_MODE_SELF_ONLY:
			var leader := get_player_character()
			if leader != null:
				fed.append(leader)
		_:
			fed = named_party.duplicate()
	return fed

func meal_feeds_crew(mode: String) -> bool:
	return mode != MEAL_MODE_PARTY_ONLY and mode != MEAL_MODE_SELF_ONLY

## Dağıtım sonucu: kim beslendi, kim aç kaldı, kervan aç kaldı mı. Ekran
## bunu isimlerle anlatıyor - bkz. Faz 14 hazırlık notu, "her metrik bir
## isim taşımalı, ortalama değil".
func apply_meal_distribution(mode: String, selected: Array[CharacterData] = []) -> Dictionary:
	var named_party := get_party()
	var party_mouths := named_party.size()
	var other_mouths := owned_wagon_count * PEOPLE_PER_WAGON + caravan.merchant_names.size()
	var total_mouths := maxi(1, party_mouths + other_mouths)
	var full_total := get_daily_provision_consumption()
	var party_share := int(round(float(full_total) * float(party_mouths) / float(total_mouths)))
	var other_share := full_total - party_share

	var fed_party := get_meal_fed_party(mode, selected)
	var feed_other := meal_feeds_crew(mode)
	var intended := full_total

	match mode:
		MEAL_MODE_PARTY_ONLY:
			intended = party_share
		MEAL_MODE_CREW_ONLY:
			intended = other_share
		MEAL_MODE_SPECIFIC:
			var per_head := 0.0 if party_mouths <= 0 else float(party_share) / float(party_mouths)
			intended = other_share + int(round(per_head * fed_party.size()))
		MEAL_MODE_SELF_ONLY:
			var self_share := 0.0 if party_mouths <= 0 else float(party_share) / float(party_mouths)
			intended = int(round(self_share))

	var actual := -change_provisions(-intended)
	# Erzak niyet edilenden de azsa (kese gerçekten boşsa) seçim anlamını
	# kaybediyor - o gece kimse gerçekten karnını doyurmuyor.
	var starved := actual < intended

	var hungry_party: Array[CharacterData] = []
	var crew_hungry := starved or not feed_other
	if starved:
		hungry_party = named_party.duplicate()
	else:
		for character in named_party:
			if not fed_party.has(character):
				hungry_party.append(character)

	var hungry_names: Array[String] = []
	var starving: Array[CharacterData] = []
	for character in hungry_party:
		character.change_stress(PERSONAL_HUNGER_STRESS)
		hungry_names.append(character.character_name)
		character.consecutive_hungry_days += 1
		# Kırgınlık yalnızca bir *seçimin* bedeli: erzak gerçekten bittiyse
		# kimse kimseyi aç bırakmadı, herkes birlikte aç kaldı.
		if not starved:
			character.add_grievance(CharacterData.GRIEVANCE_UNFED)
		if character.consecutive_hungry_days >= STARVATION_HP_LOSS_START_DAY:
			character.apply_damage(STARVATION_HP_LOSS_PER_DAY)
			if not character.is_alive():
				starving.append(character)
	for character in fed_party:
		if not starved:
			character.consecutive_hungry_days = 0

	# Açlık öldürebilir. Kimi doyurduğun sadece bir stres düğmesi olsaydı
	# "bu gece kim yiyecek" ahlaki bir seçim değil bir ayar olurdu.
	var death_outcome := resolve_deaths(starving, "LEDGER_CAUSE_STARVED")

	crew_hungry_nights = crew_hungry_nights + 1 if crew_hungry else 0
	var crew_starved: Array[String] = []
	if crew_hungry and crew_hungry_nights >= STARVATION_HP_LOSS_START_DAY:
		var starved_name := _starve_one_crew_member()
		if not starved_name.is_empty():
			crew_starved.append(starved_name)

	if crew_hungry:
		caravan.change_morale(get_crew_hunger_morale_penalty(crew_hungry_nights))
	elif not hungry_party.is_empty():
		caravan.change_morale(MEAL_HUNGER_MORALE_PENALTY)

	var fed_names: Array[String] = []
	if not starved:
		fed_names = _character_names(fed_party)
	return {
		"consumed": actual,
		"fed_names": fed_names,
		"hungry_names": hungry_names,
		"crew_hungry": crew_hungry,
		"crew_hungry_nights": crew_hungry_nights,
		"crew_starved_names": crew_starved,
		"death_outcome": death_outcome,
	}

## İlk aç gece tek seferlik düşüş; sonraki her art arda gece biraz daha.
static func get_crew_hunger_morale_penalty(nights: int) -> int:
	return maxi(
		MAX_CREW_HUNGER_MORALE_PENALTY,
		MEAL_HUNGER_MORALE_PENALTY - CREW_HUNGER_MORALE_PER_NIGHT * maxi(0, nights - 1)
	)

## Son vagonun tayfasından biri açlıktan ölür. Vagon onu hemen başka bir
## elle doldurur (tüketim vagon sayısından hesaplanıyor, isim listesinden
## değil), ama yeni adla - ölen ad bir daha dönmez. Kayıt ölüm anında
## değiştiği için yeniden yüklemek de onu geri getirmez.
func _starve_one_crew_member() -> String:
	if crew_names.is_empty():
		return ""
	var crew_name: String = crew_names.pop_back()
	ledger.record(
		CaravanLedger.KIND_DIED, crew_name, total_days_elapsed, lineage_generation,
		"", "LEDGER_CAUSE_STARVED", _ledger_location_id()
	)
	_sync_crew_names()
	return crew_name

func _character_names(characters: Array[CharacterData]) -> Array[String]:
	var names: Array[String] = []
	for character in characters:
		names.append(character.character_name)
	return names

func get_provision_cost_multiplier() -> float:
	return get_player_culture().provision_cost_multiplier

## Faz 17 PR-3'ün bilerek dar bırakılan üçüncü kancası, tamamlandı: kültür
## perki tek çarpandı, hiçbir huy pazarda hissedilmiyordu. Partinin
## tamamındaki Basiretli/Saf huyları toplanıyor - "en keskin pazarlıkçı"
## değil, kervanın genel şöhreti/deneyimi; her ikisi de bir sistemi asla
## tamamen kapatamaz (bkz. MIN/MAX), taban (huysuz kervan) tam 1.0.
const MIN_TRAIT_PRICE_MULTIPLIER: float = 0.85
const MAX_TRAIT_PRICE_MULTIPLIER: float = 1.15

func get_trait_price_multiplier() -> float:
	var total := 0
	for character in party:
		for trait_resource in character.get_traits():
			if trait_resource.affinity_stat == CharacterStats.Kind.INTELLECT:
				total += trait_resource.price_discount_percent
	return clampf(
		1.0 - float(total) / 100.0, MIN_TRAIT_PRICE_MULTIPLIER, MAX_TRAIT_PRICE_MULTIPLIER
	)

func get_buy_price_multiplier() -> float:
	return get_player_culture().buy_price_multiplier * get_trait_price_multiplier()

func get_rumor_cost_multiplier() -> float:
	return get_player_culture().rumor_cost_multiplier

## Tüm seferler boyunca ilerleyen gün sayacı (bkz. road_journey.gd
## _on_advance_day). journey_days_remaining bir seferin kalan gününü
## sayar, bu ise hiç sıfırlanmaz - kontrat panosunun süre takibi için.
var total_days_elapsed: int = 0

## Tüccar Loncası'nda kabul edilen ama henüz sefere çıkılmamış kontratlar
## (merchant_id -> kabul edildiği gün). Sefere çıkılınca depart_with_
## contracts() ile kaldırılır - artık kervanın kendi mekanikleri
## (yolda ayrılma, varışta ödeme) geçerlidir. Süresi geçerse advance_day()
## itibar cezasıyla kaldırır.
var accepted_contracts: Dictionary = {}

## --- İtibar ---
## İtibarın tek yönlü olduğu bir dönem yaşandı ve oyunu kilitliyordu:
## kaybettiren *altı* kol vardı (teslim edilemeyen kontrat, vadesi geçen
## borç, muhafızla çatışma, gümrükte yakalanma, pazarlıktan kalkmak,
## olaylar) ve kazandıran tek kol olayların keyfine kalmıştı. Kervanın
## asıl işi - kontratı teslim etmek - itibar *hiç* getirmiyordu, yani
## oyuncu doğru oynadıkça bile sayı aşağı gidiyordu. Kariyer ölçümü de
## bunu görmüştü: 20. seferde ortalama itibar ~1.
##
## Teslimat artık kazandırıyor ve kayıp cezası düştü: dört kontratın
## üçünü teslim eden bir kervan net **artıda** çıkar (3×2 − 1×3 = +3).
const REPUTATION_PENALTY_PER_LOST_CONTRACT: int = 3
const REPUTATION_PER_DELIVERED_CONTRACT: int = 2
## İtibarın dibi. Simülatörde -44'e kadar inen bir kervan gördük: o
## noktadan sonra bütün kapılar kapalı ve oyuncunun elinde onu geri
## çevirecek hiçbir kol yok, yani oyun sessizce bitmiş oluyor. Dip,
## "toparlanabilir bir kötü durum" ile "kilitlenme" arasındaki sınır.
const MIN_REPUTATION: int = -20
const MAX_REPUTATION: int = 100

## İtibarın **tek** değişim kapısı - dip ve tavan burada uygulanıyor.
## Doğrudan `reputation += x` yazmak, o dibi olmayan tek bir yol bırakmak
## demek (aynı gerekçe `Inventory.add_item`'ın ağırlık kontrolünü kendi
## içinde tutmasında da var).
func change_reputation(delta: int) -> int:
	var before := reputation
	reputation = clampi(reputation + delta, MIN_REPUTATION, MAX_REPUTATION)
	return reputation - before

func accept_contract(offer: MerchantOffer) -> void:
	accepted_contracts[offer.merchant_id] = total_days_elapsed

func is_contract_accepted(merchant_id: String) -> bool:
	return accepted_contracts.has(merchant_id)

## Yalnızca oyuncunun şu an bulunduğu şehirde kabul edilmiş ve o şehirden
## çıkan kontratları döner - kontrat başka bir şehirde kabul edilmişse
## oyuncu oraya dönmeden onu yola çıkaramaz.
func get_accepted_offers_for_destination(destination_location_id: String) -> Array[MerchantOffer]:
	var offers: Array[MerchantOffer] = []
	for merchant_id in accepted_contracts:
		var offer := WorldMapData.get_offer_by_merchant_id(merchant_id)
		if offer == null:
			continue
		if offer.destination_location_id != destination_location_id:
			continue
		if offer.origin_location_id != current_location_id:
			continue
		offers.append(offer)
	return offers

## Yola çıkılan kontratlar panodan düşer - artık kervanın kendi
## mekanikleri geçerlidir (bkz. CaravanState.original_merchant_names).
func depart_with_contracts(offers: Array[MerchantOffer]) -> void:
	for offer in offers:
		accepted_contracts.erase(offer.merchant_id)

## Sefer gününü ilerletir, süresi geçen kontratları panodan düşürüp
## itibar cezası uygular. Süresi geçenlerin merchant_id listesini döner
## (bkz. road_journey.gd - günlüğe not düşer).
func advance_day() -> Array[String]:
	total_days_elapsed += 1

	# Vadesi geçen borçlara faiz biner ve itibar yer. Tek giriş noktası
	# burası - başka yerden çağrılırsa aynı gecikme iki kez cezalandırılırdı.
	change_reputation(-debts.advance_to_day(total_days_elapsed))
	# Arz-talep baskısı tabana çekilir, süresi dolan fiyat şokları düşer.
	market.advance_day(total_days_elapsed)
	# Süresi dolan yol kapanmaları/temizlenmeleri defterden düşer; doğal
	# hava ve eşkıya durumları hesaplandığı için bakım gerektirmez.
	route_conditions.advance_day(total_days_elapsed)
	# Süresi dolan büyük dünya olayları (savaş/veba/fuar/haraç) düşer.
	world_events.advance_day(total_days_elapsed)
	# Yolun kendisi yıpratır - yalnızca yoldayken (bkz.
	# CaravanState.apply_daily_drift). Stres de aynı yerden, aynı gerekçeyle:
	# uzun bir sefer kısa bir seferden yorucu olmalı ve bu yıpranma olay
	# zarına bağlı olmamalı.
	if is_journey_active():
		caravan.apply_daily_drift()
		_apply_road_stress_day()

	var expired: Array[String] = []
	for merchant_id in accepted_contracts.keys():
		var offer := WorldMapData.get_offer_by_merchant_id(merchant_id)
		if offer == null:
			continue
		var accepted_at: int = accepted_contracts[merchant_id]
		if total_days_elapsed > accepted_at + offer.contract_deadline_days:
			expired.append(merchant_id)

	for merchant_id in expired:
		accepted_contracts.erase(merchant_id)
		change_reputation(-REPUTATION_PENALTY_PER_LOST_CONTRACT)

	return expired

## Oyuncunun kalıcı olarak sahip olduğu vagon sayısı ve bunların kaç
## tanesinin hasarlı olduğu. Şehirdeyken geçerli olan bu; sefer sırasında
## CaravanState.wagon_count (escort dahil havuz) geçerli - sefer bitince
## kayıp/hasar buraya taşınır (bkz. _apply_wagon_losses_to_ownership).
var owned_wagon_count: int = 1
var owned_wagon_damaged: int = 0

## Kervansaray fiyatları: yeni vagon sahip olunan vagon sayısı arttıkça
## kademeli pahalanır, onarım hasarlı vagon başına sabit ücrettir.
const WAGON_PURCHASE_BASE_COST: int = 150
const WAGON_PURCHASE_COST_STEP: int = 60
const WAGON_REPAIR_COST_PER_WAGON: int = 30

func get_next_wagon_cost() -> int:
	return WAGON_PURCHASE_BASE_COST + (owned_wagon_count - CaravanState.MIN_WAGONS) * WAGON_PURCHASE_COST_STEP

func can_buy_wagon() -> bool:
	return owned_wagon_count < CaravanPlan.DEFAULT_MAX_WAGONS

## Başarısızsa (kese yetmez ya da limit dolu) false döner, hiçbir şey
## değişmez.
func buy_wagon() -> bool:
	if not can_buy_wagon():
		return false
	var cost := get_next_wagon_cost()
	if not wallet.can_afford(cost):
		return false
	wallet.spend(cost)
	owned_wagon_count += 1
	_sync_wagon_inventories()
	return true

## Elden çıkarılan vagon aldığı parayı asla geri getirmez - yoksa alıp
## satmak, sefer başına kapasiteyi bedavaya açıp kapatan bir düğme olurdu.
## Hasarlı bir vagon daha da az eder ve avlu **önce onu** alır: bir enkazı
## onarmak yerine satmak gerçek bir seçenek olsun diye. Onarım (30/vagon)
## her zaman sat-ve-yeniden-al'dan ucuz, o yüzden bu bir kaçamak değil.
const WAGON_RESALE_FACTOR: float = 0.55
const WAGON_DAMAGED_RESALE_FACTOR: float = 0.6

## Satılacak vagon, en son alınan vagondur: onu almak `get_next_wagon_cost`
## bir kademe geriden neye mal olduysa o.
func get_wagon_sale_value() -> int:
	if not _has_wagon_to_spare():
		return 0
	var paid := get_next_wagon_cost() - WAGON_PURCHASE_COST_STEP
	var value := float(paid) * WAGON_RESALE_FACTOR
	if owned_wagon_damaged > 0:
		value *= WAGON_DAMAGED_RESALE_FACTOR
	return maxi(1, int(round(value)))

func _has_wagon_to_spare() -> bool:
	return owned_wagon_count > CaravanState.MIN_WAGONS

## Satışın neden kapalı olduğunu anlatan anahtar; boşsa satış açık.
## Kilitli seçenek *sebebiyle birlikte* gösterilir (bkz. World Navigation
## Rules'un kilitli seçim kuralı), gizlenmez.
func get_wagon_sale_block_reason() -> String:
	if is_journey_active():
		return "UI_YARD_SELL_ON_ROAD"
	if not _has_wagon_to_spare():
		return "UI_YARD_SELL_LAST_WAGON"
	# Kervandan kimse atılmaz (bkz. Ruin Rules); o yüzden kadroyu kapasitenin
	# üstünde bırakacak *gönüllü* satış en baştan kapalı.
	var capacity_after := clampi(
		(owned_wagon_count - 1) * PEOPLE_PER_WAGON, 1, MAX_PARTY_SIZE
	)
	if party.size() > capacity_after:
		return "UI_YARD_SELL_PARTY_TOO_BIG"
	if get_cargo_weight() > float(owned_wagon_count - 1) * CARGO_PER_WAGON:
		return "UI_YARD_SELL_CARGO_TOO_HEAVY"
	return ""

func can_sell_wagon() -> bool:
	return get_wagon_sale_block_reason().is_empty()

## Başarısızsa hiçbir şey değişmez. Önce hasarlı vagon gider.
func sell_wagon() -> bool:
	if not can_sell_wagon():
		return false
	var value := get_wagon_sale_value()
	owned_wagon_count -= 1
	if owned_wagon_damaged > 0:
		owned_wagon_damaged -= 1
	owned_wagon_damaged = clampi(owned_wagon_damaged, 0, owned_wagon_count)
	wallet.earn(value)
	_sync_wagon_inventories()
	return true

func get_repair_cost() -> int:
	var base := owned_wagon_damaged * WAGON_REPAIR_COST_PER_WAGON
	return int(round(base * (1.0 - get_duty_discount(DutyCatalog.ARABACI))))

## Tüm hasarlı vagonları tek seferde onarır. Başarısızsa (hasar yok ya
## da kese yetmez) false döner.
func repair_wagons() -> bool:
	if owned_wagon_damaged <= 0:
		return false
	var cost := get_repair_cost()
	if not wallet.can_afford(cost):
		return false
	wallet.spend(cost)
	owned_wagon_damaged = 0
	return true

## Vagon başına taşınabilecek yük. Yalnızca pazardan alınan mallara
## uygulanır; erzak kendi sefer formülüyle sınırlı, kapasiteye dahil değil.
const CARGO_PER_WAGON: float = 50.0

## Sefer sonu ödemesi: moral ve hasar ne kadar düşükse ücret o kadar
## kısılır ama asla sıfırlanmaz - kervan ağır kayıp yaşayabilir, aç kalmaz.
const MIN_MORALE_PAYOUT_FACTOR: float = 0.5
const DAMAGE_PENALTY_PER_WAGON: float = 0.08
const MIN_DAMAGE_PAYOUT_FACTOR: float = 0.4

var _flags: Dictionary = {}
var _provisions_item: Item

func _init(starting_gold: int = 250, starting_provisions: int = 20, starting_wagon_count: int = 1) -> void:
	wallet = Wallet.new(starting_gold)
	wagon_inventories = []
	caravan = CaravanState.new()
	debts = DebtLedger.new()
	market = MarketConditions.new()
	route_conditions = RouteConditions.new()
	world_events = WorldEvents.new()
	wallet.balance_changed.connect(_on_balance_changed)
	owned_wagon_count = clampi(starting_wagon_count, CaravanState.MIN_WAGONS, CaravanPlan.DEFAULT_MAX_WAGONS)
	_sync_wagon_inventories()

	_provisions_item = Item.new()
	_provisions_item.item_id = PROVISIONS_ITEM_ID
	# item_name artık hesaplanan (salt-okunur) bir özellik; saklanan şey
	# anahtar (bkz. CLAUDE.md Localization Rules).
	_provisions_item.item_name_key = PROVISIONS_ITEM_NAME
	_provisions_item.base_price = PROVISIONS_UNIT_PRICE

	if starting_provisions > 0:
		add_to_cargo(_provisions_item, starting_provisions)

	_restock_current_location()

## Şehrin mevcut pazar stoğu (item_id -> kalan miktar). Yalnızca
## current_location_id şehri için geçerli; her varışta (finish_journey()
## ve ilk kuruluş) o şehrin Location.stock_per_item'ından tam dolu
## başlar - günlük bir ekonomi simülasyonu yok, placeholder için bu
## yeterli. Listede olmayan mallar sınırsız kabul edilir.
var market_stock: Dictionary = {}

## -1 = sınırsız.
func get_market_stock(item_id: String) -> int:
	return market_stock.get(item_id, -1)

## Alım hem stoğu düşürür hem o malı o şehirde pahalandırır - bir rotayı
## sonsuza kadar sağmayı engelleyen şey bu baskı (bkz. MarketConditions).
## total_price (Faz 17 PR-5) ödediğin toplam altın: şehrin kendi hazinesine
## akar, tek doğru kaynak burası olduğu için ayrı bir "settle" çağrısına
## gerek yok - consume_stock zaten alışın tek kapısı.
func consume_stock(item_id: String, quantity: int, total_price: int = 0) -> void:
	if market_stock.has(item_id):
		market_stock[item_id] = maxi(0, market_stock[item_id] - quantity)
	market.record_purchase(current_location_id, item_id, quantity)
	if total_price > 0:
		market.earn_city_gold(current_location_id, total_price)

## Satış tersini yapar: aynı malı aynı şehre boca etmek getirisini düşürür.
## total_price şehrin hazinesinden çıkan altın (bkz. can_city_afford_sale -
## sınırı UI'da kontrol et, burası yalnızca kaydeder ve hiçbir zaman
## eksiye düşürmez).
func record_sale(item_id: String, quantity: int, total_price: int = 0) -> void:
	# Önce okunuyor: satış baskıyı değiştirmeden önceki şok hali sayılır.
	if is_profiteering_sale(item_id):
		profiteering_sales += 1
	market.record_sale(current_location_id, item_id, quantity)
	if total_price > 0:
		market.spend_city_gold(current_location_id, total_price)

## Krizden kâr etmenin sayacı. Veba vurmuş ya da yolunda savaş olan bir
## şehre, fiyatı o kriz yüzünden şişmiş bir malı satmak - dünya bunu
## hatırlıyor (bkz. evt_profiteer_recognized). Kayda yazılıyor.
var profiteering_sales: int = 0

func is_city_in_crisis(location_id: String) -> bool:
	if world_events.has_kind_on_city(WorldEvents.Kind.PLAGUE, location_id, total_days_elapsed):
		return true
	for entry in world_events.get_active_by_kind(WorldEvents.Kind.REGIONAL_WAR, total_days_elapsed):
		if (String(entry["target"]).split("|") as Array).has(location_id):
			return true
	return false

func is_profiteering_sale(item_id: String) -> bool:
	return is_city_in_crisis(current_location_id) \
		and market.is_shocked(current_location_id, item_id, total_days_elapsed)

## Şu an bulunduğun şehrin altın hazinesi - satışların tavanı.
func get_city_gold_reserve() -> int:
	return market.get_city_gold(current_location_id)

## Şehir bu toplam fiyatı ödeyebilir mi? market.gd satış öncesi bunu sorar -
## "disabled with reason" kuralı: hazine yetmiyorsa satış hiç başlamaz,
## kısmi bir satışın kendini iki kez açıklaması gerekmesin diye (bkz.
## Kervan Envanteri Rules'un add_to_cargo'daki "hep ya da hiç" ilkesi).
func can_city_afford_sale(total_price: int) -> bool:
	return get_city_gold_reserve() >= total_price

func _restock_current_location() -> void:
	market_stock.clear()
	var location := WorldMapData.get_location_by_id(current_location_id)
	if location != null:
		for item_id in location.stock_per_item:
			market_stock[item_id] = location.stock_per_item[item_id]
	_restock_recruits()

## Şehirdeki partiye katılabilecek adaylar (mekân -> aday listesi).
## Pazar stoğuyla aynı ritimde, her varışta bir kez tazelenir; tohum
## şehir + gün olduğu için aynı varışta ekran kapatıp açmak listeyi
## değiştirmez.
var recruit_candidates: Dictionary = {}

## Bu varışta tutulan adayların **üretildikleri sıradaki** indisleri (mekân ->
## Array[int]). Adaylar tohumdan yeniden üretildiği için kayda kimlerin
## tutulduğu yazılmalı; varışta temizlenir.
var hired_recruit_indices: Dictionary = {}

func _restock_recruits() -> void:
	recruit_candidates.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d" % [current_location_id, total_days_elapsed])
	var player_level := get_player_character().level
	# "Arkada yaşayan ve gelişen bir dünya" (bkz. RecruitCatalog.
	# get_world_growth_levels) - seferler tamamlandıkça meydanda/tavernada/
	# loncada bekleyenler de biraz daha tecrübeli çıkar.
	var world_growth := RecruitCatalog.get_world_growth_levels(journeys_completed)
	for venue in [
		RecruitCatalog.VENUE_MARKET, RecruitCatalog.VENUE_TAVERN, RecruitCatalog.VENUE_GUILD
	]:
		var candidates: Array[CharacterData] = RecruitCatalog.build_candidates(
			venue, rng, player_level, world_growth
		)
		# Bu varışta zaten tutulmuş olanlar yeniden çekilen listeden düşer;
		# yoksa şehirde alınan bir kayıt, tutulmuş bir yoldaşı panoya geri
		# getirip ikinci kez tutulabilir kılıyordu (aynı kişi iki kez).
		var hired: Array = hired_recruit_indices.get(venue, [])
		var sorted_hired := hired.duplicate()
		sorted_hired.sort()
		sorted_hired.reverse()
		for index in sorted_hired:
			if int(index) >= 0 and int(index) < candidates.size():
				candidates.remove_at(int(index))
		recruit_candidates[venue] = candidates

func get_recruit_candidates(venue: String) -> Array[CharacterData]:
	var candidates: Array[CharacterData] = []
	for candidate in recruit_candidates.get(venue, []):
		candidates.append(candidate)
	return candidates

## Adayı partiye katar ve mekânın listesinden düşürür. İtibar, kese ya da
## parti sınırı yetmezse false döner, hiçbir şey değişmez.
func hire_recruit(venue: String, candidate: CharacterData) -> bool:
	if reputation < RecruitCatalog.get_venue_required_reputation(venue):
		return false
	if not recruit_candidates.get(venue, []).has(candidate):
		return false
	var list_index: int = recruit_candidates[venue].find(candidate)
	if not recruit(candidate):
		return false
	var original_index := _original_candidate_index(venue, list_index)
	if not hired_recruit_indices.has(venue):
		hired_recruit_indices[venue] = []
	hired_recruit_indices[venue].append(original_index)
	recruit_candidates[venue].erase(candidate)
	return true

## Listedeki konumu, daha önce tutulanlar çıkarılmadan önceki üretim
## sırasına çevirir.
func _original_candidate_index(venue: String, list_index: int) -> int:
	var hired: Array = (hired_recruit_indices.get(venue, []) as Array).duplicate()
	hired.sort()
	var original := list_index
	for index in hired:
		if int(index) <= original:
			original += 1
	return original

func get_provisions() -> int:
	return get_total_quantity(PROVISIONS_ITEM_ID)

## Negatif miktarlarda sıfırın altına inmez; her iki yönde de gerçekten
## değişen miktarı döner.
##
## Ekleme tarafı add_item'ın dönüşünü yok sayıyordu: envanterde boş slot
## kalmamışsa (Inventory.max_slots) ve erzak girişi tükendiği için silinmişse
## ekleme sessizce başarısız oluyor, buna rağmen delta "eklendi" diye
## dönüyordu - olay günlüğü "Erzak +5" yazarken kervan aç kalırdı. Bugün
## katalogda max_slots'tan az mal olduğu için tetiklenmiyor, mal eklendikçe
## gerçek olur.
func change_provisions(delta: int) -> int:
	if delta > 0:
		return delta if add_to_cargo(_provisions_item, delta) else 0

	var removable := mini(-delta, get_provisions())
	if removable > 0:
		remove_from_cargo_or_bags(PROVISIONS_ITEM_ID, removable)
	return -removable

func has_flag(flag: String) -> bool:
	return _flags.has(flag)

func set_flag(flag: String) -> void:
	_flags[flag] = true

func clear_flag(flag: String) -> void:
	_flags.erase(flag)

# --- Sefer ---

## Oturumun evresi. Ayrı saklanmıyor, var olan tek doğruluk kaynaklarından
## türetiliyor (sefer hedefi, soy tükenme bayrağı): ayrı bir alan tutulsaydı
## sefer alanlarını doğrudan yazan her yol (geliştirici seferi, testler) onu
## da güncellemeyi unutabilir ve iki gerçek birbirinden kopardı.
enum Phase { CITY, JOURNEY, RUN_OVER }

func get_phase() -> Phase:
	if has_flag(RUN_OVER_FLAG):
		return Phase.RUN_OVER
	if not journey_destination_id.is_empty():
		return Phase.JOURNEY
	return Phase.CITY

func is_journey_active() -> bool:
	return get_phase() == Phase.JOURNEY

## Yol ekranının `JourneyController.to_dict()` anlık görüntüsü. Sefer
## ortası kaydı bunu taşır; yol ekranı açılırken doluysa sefer kaldığı
## yerden devam eder, boşsa yeni başlar. Varışta temizlenir.
var journey_snapshot: Dictionary = {}

## --- Sefere çıkış morali ---
## Moral artık her seferde dolu başlamıyor. Kervan yola dünyanın o günkü
## haliyle çıkıyor: bereketli bir ilkbaharda, borcu olmayan, tanınan bir
## kervanın kadrosu keyifli; kıtlık kol gezen bir kışta, alacaklıları
## kapıda bekleyen yorgun bir kadro değil.
##
## Kaynakların hepsi zaten var olan sistemler - yeni bir "savaş/salgın"
## mekaniği icat edilmiyor: darlık MarketConditions'ın şok+mevsim+enflasyon
## katmanı (kıtlık, ambargo, grev hepsi MARKET_SHOCK), yorgunluk kalıcı
## stres, güvensizlik vadesi geçmiş borç, gurur ise itibar.
##
## Stres ile moral ayrı stat olmaya devam ediyor (bkz. CLAUDE.md Stress
## Rules): stres burada moralin *başlangıcını* etkiliyor, moral olup
## bitince stres'e dönüşmüyor. Biri kervanın kalıcı yıpranması, diğeri o
## seferin ruh hali.
const DEPARTURE_MORALE_FLOOR: int = 45
const DEPARTURE_HARDSHIP_WEIGHT: int = 30
const DEPARTURE_STRESS_WEIGHT: int = 25
const DEPARTURE_OVERDUE_DEBT_PENALTY: int = 10
const DEPARTURE_REPUTATION_BONUS_CAP: int = 8
const DEPARTURE_REPUTATION_PER_POINT: float = 0.5

## Faz 17 PR-3'ün bilerek dar bırakılan ikinci kancası, tamamlandı: "Güven
## Verici" adı zaten bir moral vaadiydi ama huy yalnızca savaşta bir dodge
## puanı veriyordu - kervanın dışına hiç taşmıyordu. Parti çapında toplanıyor
## (yalnızca lider değil): bir yoldaşın huzur verici hâli bütün kadroya
## sirayet eder, itibarın "gurur" payıyla aynı aile - küçük ve tavanlı, tek
## bir huy asla hardship/stres payını ezmesin diye.
const DEPARTURE_TEMPERAMENT_BONUS_CAP: int = 6

func get_departure_temperament_bonus() -> int:
	var total := 0
	for character in party:
		for trait_resource in character.get_traits():
			if trait_resource.affinity_stat == CharacterStats.Kind.CHARISMA:
				total += trait_resource.morale_bonus
	return clampi(total, -DEPARTURE_TEMPERAMENT_BONUS_CAP, DEPARTURE_TEMPERAMENT_BONUS_CAP)

func get_departure_morale() -> int:
	var morale := float(CaravanState.MAX_MORALE)
	morale -= market.get_hardship(current_location_id, total_days_elapsed) * float(DEPARTURE_HARDSHIP_WEIGHT)
	morale -= (float(party_stress) / float(MAX_STRESS)) * float(DEPARTURE_STRESS_WEIGHT)
	if not debts.get_overdue_debts(total_days_elapsed).is_empty():
		morale -= float(DEPARTURE_OVERDUE_DEBT_PENALTY)
	morale += clampf(
		float(reputation) * DEPARTURE_REPUTATION_PER_POINT,
		0.0, float(DEPARTURE_REPUTATION_BONUS_CAP)
	)
	morale += float(get_departure_temperament_bonus())
	return clampi(int(round(morale)), DEPARTURE_MORALE_FLOOR, CaravanState.MAX_MORALE)

## Çıkış moralini oluşturan kalemler - planlayıcı ekranı oyuncuya bunu
## gösteriyor. Neden düşük moralle yola çıktığını göremeyen oyuncu için
## mekanik görünmez bir cezadan ibaret kalırdı.
func get_departure_morale_breakdown() -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	var hardship := market.get_hardship(current_location_id, total_days_elapsed)
	if hardship > 0.0:
		lines.append({
			"key": "UI_MORALE_HARDSHIP",
			"amount": -int(round(hardship * float(DEPARTURE_HARDSHIP_WEIGHT))),
		})
	if party_stress > 0:
		lines.append({
			"key": "UI_MORALE_STRESS",
			"amount": -int(round((float(party_stress) / float(MAX_STRESS)) * float(DEPARTURE_STRESS_WEIGHT))),
		})
	if not debts.get_overdue_debts(total_days_elapsed).is_empty():
		lines.append({"key": "UI_MORALE_OVERDUE_DEBT", "amount": -DEPARTURE_OVERDUE_DEBT_PENALTY})
	var pride := int(clampf(
		float(reputation) * DEPARTURE_REPUTATION_PER_POINT,
		0.0, float(DEPARTURE_REPUTATION_BONUS_CAP)
	))
	if pride > 0:
		lines.append({"key": "UI_MORALE_REPUTATION", "amount": pride})
	var temperament := get_departure_temperament_bonus()
	if temperament != 0:
		lines.append({"key": "UI_MORALE_TEMPERAMENT", "amount": temperament})
	return lines

## Planlayıcıda onaylanan kervanı yola çıkarır.
func start_journey(destination_id: String, days: int, danger: float, plan: CaravanPlan) -> void:
	if get_phase() == Phase.RUN_OVER:
		push_error("start_journey: run is over, cannot open a new journey")
		return
	journey_origin_id = current_location_id
	journey_destination_id = destination_id
	journey_total_days = maxi(1, days)
	journey_days_remaining = journey_total_days
	danger_level = danger
	caravan = CaravanState.from_plan(plan, get_departure_morale(), total_days_elapsed)

## Yolun ortasında planı değiştirmek. Şehirde kurulan plan bir niyet, bir
## taahhüt değil: geçit kapanır, erzak biter, kervan zarar görür ve hedef
## değişir. Kervan bulunduğu noktadan **yeni bir yola** girer; geride
## bıraktığı hedefe yazılı kontratlar teslim edilemez, faturası varışta
## kesilir (bkz. _apply_undelivered_contract_penalty).
##
## Yeni sefer nereden başlıyor sayılıyor? Kervanın gerçekte durduğu yer bir
## şehir değil, iki şehir arasında bir nokta. Bunu yol üstünde geçirilen
## günle temsil ediyoruz: dönüş/sapma süresi hedefin çıkış şehrine olan
## mesafesi ile o ana kadar yürünen mesafenin toplamı.
const MIN_DIVERT_DAYS: int = 1

func get_days_travelled() -> int:
	return maxi(0, journey_total_days - journey_days_remaining)

## Geri dön: yürünen yol kadar geri yürünür. Her zaman mümkün - kervanın
## geldiği yolu bulamaması diye bir şey yok.
func turn_back() -> bool:
	if not is_journey_active() or journey_origin_id.is_empty():
		return false
	var travelled := get_days_travelled()
	journey_destination_id = journey_origin_id
	journey_total_days = maxi(MIN_DIVERT_DAYS, travelled)
	journey_days_remaining = journey_total_days
	return true

## Yolda hedef değiştir. Yalnızca çıkış şehrinden ulaşılabilen ve o gün
## açık olan bir hedefe sapılabilir - kervan haritanın ortasında ışınlanmaz,
## bildiği yola geri çıkıp oradan gider.
func can_divert_to(destination_id: String) -> bool:
	if not is_journey_active() or journey_origin_id.is_empty():
		return false
	if destination_id == journey_destination_id or destination_id == journey_origin_id:
		return false
	var route := WorldMapData.get_route(journey_origin_id, destination_id)
	return route != null and is_route_open(route)

func divert_journey(destination_id: String) -> bool:
	if not can_divert_to(destination_id):
		return false
	var route := WorldMapData.get_route(journey_origin_id, destination_id)
	var total := maxi(MIN_DIVERT_DAYS, get_days_travelled() + get_route_travel_days(route))
	journey_destination_id = destination_id
	journey_total_days = total
	journey_days_remaining = total
	danger_level = get_route_danger(route)
	return true

## Hedefe varıldığında çağrılır: escort ücretini öder, sefer sırasındaki
## kayıp/hasarı oyuncunun kalıcı vagon sahipliğine taşır, konumu günceller
## ve seferi temizler (escort ettiği tüccarlar hedefe ulaşıp ayrılmıştır).
## Ödeme dökümünü döner.
func finish_journey() -> Dictionary:
	# Şehirde herkes yer - tayfanın aç gece sayacı burada kapanır.
	crew_hungry_nights = 0
	var payout := _calculate_arrival_payout()
	wallet.earn(payout.net)
	_apply_wagon_losses_to_ownership()
	_apply_guild_wagon_quest_rewards()
	payout["lost_contracts"] = _apply_undelivered_contract_penalty()

	# Kariyer sayaçları: kampanya bölümleri bunlara bakıyor (bkz.
	# build_campaign_context). Teslim edilen = yola çıkarken yazılı olan
	# eksi yolda kaybedilen.
	journeys_completed += 1
	var delivered := maxi(
		0, caravan.original_merchant_names.size() - int(payout["lost_contracts"])
	)
	contracts_delivered += delivered
	# Teslimat **varışta kendiliğinden** oluyor - ayrı bir "teslim et"
	# ekranı yok, çünkü kervan malı zaten getirdi. Ama bunu hiçbir yer
	# söylemiyordu: bir playtest oyuncusu Demirkapı'dan Kurtboğazı'na
	# kontrat taşıdı ve "Contracts Deliver kısmını bulamadım" diye yazdı.
	# Görünmeyen bir teslimat, olmayan bir teslimattan ayırt edilemez -
	# aynı kural görünmeyen ceza için de yazılıydı (bkz. DebtPanel).
	payout["delivered_contracts"] = delivered

	# Teslim edilen her kontrat itibar kazandırır. Bu, kaybettiren kolun
	# (bkz. REPUTATION_PENALTY_PER_LOST_CONTRACT) eksik olan karşılığı:
	# olmadığı sürece oyuncunun itibarı yalnızca *düşebiliyordu*, yani
	# doğru oynamanın bir ödülü yoktu ve tek kötü sefer tayfa toplamayı
	# kalıcı olarak kilitliyordu.
	payout["reputation_gained"] = change_reputation(
		delivered * REPUTATION_PER_DELIVERED_CONTRACT
	)

	# XP hesabı sıfırlanmadan önce yapılmalı: moral ve kontrat kaybı seferin
	# "başarılı" mı "başarısız" mı sayıldığını belirliyor (bkz. _calculate_journey_xp).
	var journey_xp := _calculate_journey_xp(
		journey_total_days, danger_level,
		caravan.morale / float(CaravanState.MAX_MORALE),
		payout["lost_contracts"]
	)
	payout["xp_awarded"] = journey_xp
	payout["levels_gained"] = grant_party_xp(journey_xp)

	# Kırılma zarı stres hâlâ sefer boyunca biriktiği haliyle atılır, şehir
	# dinlenmesi bundan sonra gelir - aksi halde rahatlama kırılmayı hiç
	# yaşanmamış gösterirdi.
	var stress_rng := RandomNumberGenerator.new()
	stress_rng.seed = hash("%s|%d|stress" % [current_location_id, total_days_elapsed])
	payout["stress_breaks"] = resolve_stress_breaks(stress_rng)
	change_stress(-get_city_rest_relief())

	if not journey_destination_id.is_empty():
		current_location_id = journey_destination_id
	visited_location_ids[current_location_id] = true
	journey_snapshot = {}
	journey_origin_id = ""
	journey_destination_id = ""
	journey_total_days = 0
	journey_days_remaining = 0
	danger_level = 0.0
	caravan = CaravanState.new()
	hired_recruit_indices = {}
	_restock_current_location()
	heal_party()

	# Kampanya en sona bırakılıyor: bölüm hedefleri varışın *sonucunu*
	# okumalı (ödeme yatmış, teslimat sayılmış, şehir görülmüş olmalı),
	# yoksa bir bölüm hep bir sefer geriden kapanırdı.
	payout["campaign_chapters"] = advance_campaign()

	return payout

## Yolda kervandan ayrılan (teslim edilemeyen) her kontrat için itibar
## cezası uygular. Kaç kontratın kaybedildiğini döner.
func _apply_undelivered_contract_penalty() -> int:
	var lost := 0
	for merchant_name in caravan.original_merchant_names:
		if not caravan.merchant_names.has(merchant_name):
			lost += 1
	change_reputation(-lost * REPUTATION_PENALTY_PER_LOST_CONTRACT)
	return lost

## Sefer sırasındaki kayıp/hasar kervanın havuzundan (oyuncu + escort
## tüccarların vagonları birlikte) uygulanıyor. Buradan oyuncunun payına
## düşeni çıkarır: escort vagonları önce kaybedilir/hasar alır, oyuncunun
## kendi vagonu yalnızca escort tükendikten sonra etkilenir.
func _apply_wagon_losses_to_ownership() -> void:
	var escort_at_start := maxi(0, caravan.wagons_at_start - caravan.player_wagon_count_at_start)
	var total_lost := maxi(0, caravan.wagons_at_start - caravan.wagon_count)
	var escort_lost := mini(total_lost, escort_at_start)
	var player_lost := total_lost - escort_lost

	var escort_remaining := escort_at_start - escort_lost
	var escort_damaged := mini(caravan.damaged_wagons, escort_remaining)
	var player_damaged := caravan.damaged_wagons - escort_damaged

	var new_count := maxi(CaravanState.MIN_WAGONS, owned_wagon_count - player_lost)
	_record_crew_lost_with_wagons(owned_wagon_count - new_count)
	owned_wagon_count = new_count
	_sync_wagon_inventories()
	owned_wagon_damaged = clampi(owned_wagon_damaged + player_damaged, 0, owned_wagon_count)

## Faz 17 PR-4: loncanın iki özel vagon görevi (bkz. WorldMapData.
## get_guild_wagon_quests) sıradan bir MerchantOffer gibi kabul edilir ve
## taşınır - altın yerine ayni ödül verir, bu yüzden finish_journey()'nin
## kendi kayıp-kontratı bittikten (_apply_wagon_losses_to_ownership) sonra
## ayrı bir kapıdan geçer. Yolda kaybedilirse (caravan.merchant_names'ten
## düşmüşse) hiçbir ödül verilmez - sıradan bir kontrat gibi yalnızca
## itibar cezası alır (_apply_undelivered_contract_penalty zaten geçti).
##
## Yalnızca **vagon bağışları** kalıcı olarak kilitleniyor - bkz.
## WorldMapData'nın kendi notu: bir vagon kalıcı bir kapasite artışı,
## sınırsız tekrar satın alma eğrisini bedavaya delerdi. Kargo görevleri
## bu sözlüğe hiç girmiyor, o yüzden sıradan bir kontrat gibi teslim
## edildikçe panoya geri dönüyor (bkz. guild.gd'nin _available_offers'ı) -
## piyasada zaten alınıp satılan bir malın sınırını `MarketConditions`
## zaten taşıyor.
var _delivered_wagon_quest_ids: Dictionary = {}  # merchant_id -> true

func is_guild_wagon_quest_delivered(merchant_id: String) -> bool:
	return _delivered_wagon_quest_ids.has(merchant_id)

func _apply_guild_wagon_quest_rewards() -> void:
	for offer in WorldMapData.get_guild_wagon_quests():
		if offer.grants_wagon_on_delivery and is_guild_wagon_quest_delivered(offer.merchant_id):
			continue
		if not caravan.original_merchant_names.has(offer.merchant_name):
			continue
		if not caravan.merchant_names.has(offer.merchant_name):
			continue
		if offer.grants_wagon_on_delivery:
			_delivered_wagon_quest_ids[offer.merchant_id] = true
			owned_wagon_count += 1
			_sync_wagon_inventories()
		if offer.cargo_reward_quantity > 0:
			var item := ItemCatalog.get_item(offer.cargo_reward_item_id)
			if item != null:
				add_to_cargo_or_bag(item, offer.cargo_reward_quantity)

## Şehre varış her zaman rahatlatır - kırılma riski sıfırlanmaz ama stres
## seviyesi geri çekilir.
## Şehirde dinlenmek eskiden 35 götürüyordu - tipik bir sefer ~25-30 stres
## biriktirdiği için stres seferden sefere **hiç birikmiyordu** ve
## evt_stress_brawl (stres >= 40) hiç ateşlenmiyordu.
##
## Artık dinlenmek seferin getirdiğinin bir kısmını alıyor, hepsini değil:
## fark birikiyor. Üstelik rahatlama günlerle eriyor - aynı han odası aynı
## kadroya on sefer sonra daha az iyi geliyor - ki "birikme gittikçe artsın".
## Taban var: dinlenmek hiçbir zaman tamamen işe yaramaz hale gelmemeli.
const CITY_REST_STRESS_RELIEF: int = 14
const CITY_REST_RELIEF_DECAY_PER_DAY: float = 0.02
const CITY_REST_RELIEF_MIN: int = 6

func get_city_rest_relief() -> int:
	var decayed := float(CITY_REST_STRESS_RELIEF) - float(total_days_elapsed) * CITY_REST_RELIEF_DECAY_PER_DAY
	return maxi(CITY_REST_RELIEF_MIN, int(round(decayed)))

const JOURNEY_XP_BASE: int = 15
const JOURNEY_XP_PER_DAY: float = 4.0
const JOURNEY_XP_DANGER_BONUS: float = 40.0
const JOURNEY_XP_FAILURE_FACTOR: float = 0.25
const JOURNEY_SUCCESS_MORALE_RATIO: float = 0.5

## Başarı ölçütü kervanın hiç yok olmaması değil (o zaten garanti) - moral
## yarının altına düşmeden ve hiç kontrat kaybetmeden varmak. Tutmazsa
## sefer yine tamamlanmış sayılır ama XP'nin yalnızca çeyreği kazanılır.
func _calculate_journey_xp(days: int, danger: float, morale_ratio: float, lost_contracts: int) -> int:
	var base := float(JOURNEY_XP_BASE) + float(days) * JOURNEY_XP_PER_DAY + danger * JOURNEY_XP_DANGER_BONUS
	var succeeded := morale_ratio >= JOURNEY_SUCCESS_MORALE_RATIO and lost_contracts == 0
	var factor := 1.0 if succeeded else JOURNEY_XP_FAILURE_FACTOR
	return maxi(0, int(round(base * factor)))

func _calculate_arrival_payout() -> Dictionary:
	var gross := 0
	for merchant_name in caravan.merchant_names:
		gross += caravan.merchant_profit_by_name.get(merchant_name, 0)

	var morale_factor := lerpf(
		MIN_MORALE_PAYOUT_FACTOR, 1.0, caravan.morale / float(CaravanState.MAX_MORALE)
	)
	var damage_factor := maxf(
		MIN_DAMAGE_PAYOUT_FACTOR, 1.0 - caravan.damaged_wagons * DAMAGE_PENALTY_PER_WAGON
	)
	var net := int(round(gross * morale_factor * damage_factor))

	return {
		"gross": gross,
		"morale_factor": morale_factor,
		"damage_factor": damage_factor,
		"net": net,
	}

## Vagon sayısı her değiştiğinde vagon envanterleri dizisi de büyür/küçülür
## - vagon almak yeni, boş bir vagon envanteri açar; vagon kaybetmek/satmak
## kalan vagonun kargosunu diğer vagonlara dağıtır (bkz. `add_to_cargo` -
## bir tek yığın gerekirse birden fazla vagona bölünür), sığmayan kısım
## vagonla birlikte gerçekten kaybolur (bkz. CLAUDE.md Ruin Rules).
## --- Tayfanın adları ---
## Vagonları süren tayfa savaşmaz, partiye girmez (bkz. Character & Party
## Rules: tayfa ≠ savaş partisi) ama adsız da değil. Bir vagon uçurumdan
## düştüğünde bir kapasite sayısı değil iki isim kaybedilir. İsimler
## liderin kültür havuzundan, `caravan_name|sıra` tohumuyla - aynı kervan
## hep aynı tayfayı çıkarır, kayıt yüklemek yeniden atmaz.
var crew_names: Array[String] = []
## Kaçıncı tayfa adının atılacağı. Sıra indeksiyle atmak, ölen ya da
## vagonuyla kaybolan bir adın yerine birebir aynı adı getiriyordu - ölü
## biri yeniden işe başlıyordu. Sayaç yalnızca artar; ilk atışlar eskisiyle
## aynı (sayaç o ana kadar indeksle eşit).
var _crew_name_serial: int = 0

func _sync_crew_names() -> void:
	var target := owned_wagon_count * PEOPLE_PER_WAGON
	while crew_names.size() < target:
		crew_names.append(_roll_crew_name(_crew_name_serial))
		_crew_name_serial += 1
	while crew_names.size() > target:
		crew_names.pop_back()

func _roll_crew_name(index: int) -> String:
	var leader := get_player_character() if not party.is_empty() else null
	var culture := leader.get_culture() if leader != null else CultureCatalog.get_culture(CultureCatalog.NOMAD)
	var pool: Array[String] = culture.name_pool if culture != null else []
	if pool.is_empty():
		return ""
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|crew|%d" % [caravan_name, index])
	return pool[rng.randi_range(0, pool.size() - 1)]

## Bir vagonun tayfası (vagon sırası 0'dan).
func get_wagon_crew_names(wagon_index: int) -> Array[String]:
	var names: Array[String] = []
	for offset in PEOPLE_PER_WAGON:
		var index := wagon_index * PEOPLE_PER_WAGON + offset
		if index >= 0 and index < crew_names.size():
			names.append(crew_names[index])
	return names

## Kaybedilen vagonların tayfası deftere ölü olarak yazılır - satılan
## vagonunki yazılmaz, onlar parasını alıp ayrılır, kaybedilmez.
func _record_crew_lost_with_wagons(wagons_lost: int) -> void:
	for _i in wagons_lost * PEOPLE_PER_WAGON:
		if crew_names.is_empty():
			return
		var crew_name: String = crew_names.pop_back()
		ledger.record(
			CaravanLedger.KIND_DIED, crew_name, total_days_elapsed, lineage_generation,
			"", "LEDGER_CAUSE_WAGON_LOST", _ledger_location_id()
		)

func _sync_wagon_inventories() -> void:
	_sync_crew_names()
	while wagon_inventories.size() < owned_wagon_count:
		var wagon_inventory := Inventory.new()
		wagon_inventory.weight_limit = CARGO_PER_WAGON
		# Erzak kargo ağırlığına dahil değil (bkz. get_cargo_weight), o
		# yüzden her vagonda ağırlık kısıtından muaf.
		wagon_inventory.exempt_item_ids = [PROVISIONS_ITEM_ID]
		wagon_inventories.append(wagon_inventory)
	while wagon_inventories.size() > owned_wagon_count:
		var removed: Inventory = wagon_inventories.pop_back()
		for entry in removed.get_all_entries():
			add_to_cargo(entry.item, entry.quantity)

func get_cargo_capacity() -> float:
	return owned_wagon_count * CARGO_PER_WAGON

## Bir vagonun ne kadar dolu olduğu - bkz. `get_caravan_theoretical_speed()`,
## artık yalnızca bilgilendirici değil, yolun gerçek yürüyüş hızını da
## belirliyor (bkz. road_journey.gd'nin `_walk_at()`'i).
const WAGON_LOAD_SPEED_PENALTY: float = 0.35
const WAGON_MIN_SPEED_FACTOR: float = 0.55

func get_wagon_speed_factor(wagon_index: int) -> float:
	if wagon_index < 0 or wagon_index >= wagon_inventories.size():
		return 1.0
	var wagon_inventory := wagon_inventories[wagon_index]
	var load_ratio := clampf(wagon_inventory.get_total_weight() / CARGO_PER_WAGON, 0.0, 1.0)
	return clampf(1.0 - WAGON_LOAD_SPEED_PENALTY * load_ratio, WAGON_MIN_SPEED_FACTOR, 1.0)

## Adı `DutyCatalog.get_condition_multiplier()`'la aynı fikri taşıyor
## (kırılmış ya da canının yarısının altında biri daha az katkı verir) -
## burada görev gücüne değil, o kişinin yürüyüşe kattığı hıza uygulanıyor.
## Aynı formülü ikinci kez yazmak yerine doğrudan çağırıyor: iki sistem de
## "kondisyon" kelimesini aynı sayıyla anlamalı.
func get_party_condition_speed_factor() -> float:
	var slowest := 1.0
	for character in get_party():
		slowest = minf(slowest, DutyCatalog.get_condition_multiplier(character))
	return slowest

## Bir kervan en yavaş tekerleğinden ya da en bitkin/yaralı yolcusundan
## hızlı gidemez - "teorik hızı" vagonların yük faktörleriyle partinin
## kondisyon faktörünün **en düşüğü**. Vagon yoksa (kuramsal, oyun her
## zaman en az bir vagonla başlar) tam hız varsayılır; parti her zaman en
## az bir kişi (oyuncu) içerir.
##
## Bu sayı `CaravanOverviewPanel`de gösteriliyordu ama bir süre yalnızca
## bilgilendiriciydi (bkz. Provision Rules'un `travel_reserve_days`'i -
## planlayıcı artık bu payı önceden istiyor, tam olarak havanın yaptığı
## gibi). Tam kondisyonda ve boş vagonda çarpan tam 1.0, yani eski
## davranış aynen.
func get_caravan_theoretical_speed() -> float:
	var slowest := get_party_condition_speed_factor()
	for index in wagon_inventories.size():
		slowest = minf(slowest, get_wagon_speed_factor(index))
	return slowest

func get_cargo_weight() -> float:
	var total := 0.0
	for wagon_inventory in wagon_inventories:
		total += wagon_inventory.get_total_weight()
	return total

func get_cargo_space_remaining() -> float:
	return maxf(0.0, get_cargo_capacity() - get_cargo_weight())

## Bir yığın tek bir vagona sığmak zorunda değil - alım kervanın *toplam*
## kargosuna sığmalı, tek bir vagonun kapasitesine değil. Önce her vagonun
## ne kadarını alabileceği planlanır (get_max_addable, hiçbir şeyi
## değiştirmez); toplam sığmıyorsa hiçbir vagona dokunulmaz - "hepsi ya da
## hiçbiri", yarım yamalak bir alım kafa karıştırır.
func add_to_cargo(item: Item, quantity: int) -> bool:
	if quantity <= 0:
		return false
	var remaining := quantity
	var plan: Array[Dictionary] = []
	for wagon_inventory in wagon_inventories:
		if remaining <= 0:
			break
		var addable := wagon_inventory.get_max_addable(item)
		if addable <= 0:
			continue
		var take := mini(remaining, addable)
		plan.append({"wagon": wagon_inventory, "quantity": take})
		remaining -= take
	if remaining > 0:
		return false
	for step in plan:
		var wagon_inventory: Inventory = step.wagon
		wagon_inventory.add_item(item, int(step.quantity))
	return true

## Vagonlara sığmayan küçük bir kazanç (bkz. Faz 13 evt_forgotten_cache gibi
## olay ödülleri) tamamen kaybolmasın diye - kişisel çantalara (bkz.
## CharacterData.personal_inventory) taşan bir son çare. Alım/pazarlık
## kasıtlı olarak bunu çağırmıyor - orada oyuncunun "kargo dolu" diye
## bilgilendirilmesi gerekiyor, sessizce çantaya kaymaması.
func add_to_cargo_or_bag(item: Item, quantity: int) -> bool:
	if add_to_cargo(item, quantity):
		return true
	for character in get_party():
		if character.personal_inventory.add_item(item, quantity):
			return true
	return false

## Vagonlar + kişisel çantalar toplamında bir malın kaç birimi var -
## "şehre gittiğimizde vagonlarımızın ve çantamızın toplamı" sorusunun
## tek bir malı için karşılığı.
func get_total_quantity(item_id: String) -> int:
	var total := 0
	for wagon_inventory in wagon_inventories:
		total += wagon_inventory.get_quantity(item_id)
	for character in get_party():
		total += character.personal_inventory.get_quantity(item_id)
	return total

## Kargo bittikçe çantalara devam eder, hepsi tükenene kadar. Talep edilen
## toplamdan azı varsa hiçbir şey eksiltmez (hepsi ya da hiçbiri, `add_to_
## cargo`nun ayna kuralı) - satış/craft ekranı önce `get_total_quantity`
## ile sorar, burası yalnızca gerçekten yeterince varken çağrılır.
func remove_from_cargo_or_bags(item_id: String, quantity: int) -> bool:
	if quantity <= 0 or get_total_quantity(item_id) < quantity:
		return false
	var remaining := quantity
	for wagon_inventory in wagon_inventories:
		if remaining <= 0:
			break
		var take := mini(remaining, wagon_inventory.get_quantity(item_id))
		if take > 0:
			wagon_inventory.remove_item(item_id, take)
			remaining -= take
	for character in get_party():
		if remaining <= 0:
			break
		var take := mini(remaining, character.personal_inventory.get_quantity(item_id))
		if take > 0:
			character.personal_inventory.remove_item(item_id, take)
			remaining -= take
	return true

## Vagonlar + kişisel çantalar toplamı, tek bir listeye eritilmiş - pazar
## ve kargo dökümü ekranlarının okuduğu şey (bkz. Inventory.get_all_entries
## ile aynı şekil: {"item": Item, "quantity": int}).
func get_total_inventory_entries() -> Array:
	var totals: Dictionary = {}
	for wagon_inventory in wagon_inventories:
		_merge_entries(totals, wagon_inventory.get_all_entries())
	for character in get_party():
		_merge_entries(totals, character.personal_inventory.get_all_entries())
	return totals.values()

func _merge_entries(totals: Dictionary, entries: Array) -> void:
	for entry in entries:
		var item: Item = entry.item
		if totals.has(item.item_id):
			totals[item.item_id].quantity += int(entry.quantity)
		else:
			totals[item.item_id] = {"item": item, "quantity": int(entry.quantity)}

## Atölye kervanın herhangi bir ekranı değil, **o vagonun kendisi** -
## oyuncu yolda vagona yürüyüp tıklar (bkz. world_hub.gd'nin vagon
## etkileşim noktaları). Bu yüzden bir tarif kervanın toplamından değil,
## yalnızca **o vagonun kendi envanterinden** okur/yazar: malzemeyi hangi
## vagona yüklediğin ilk kez gerçekten anlam kazanıyor - kumaş başka bir
## vagondaysa bu vagonda bandaj sarılamaz. Kilitli bir tarif "sebebiyle
## birlikte" gösterilir, aynı kural her yerde.
func get_craft_block_reason_in_wagon(wagon_index: int, recipe: CraftingRecipe) -> String:
	if wagon_index < 0 or wagon_index >= wagon_inventories.size():
		return "UI_CRAFT_MISSING_MATERIAL"
	if recipe.effect == CraftingRecipe.Effect.WAGON_REPAIR and owned_wagon_damaged <= 0:
		return "UI_CRAFT_NO_DAMAGE"
	var wagon_inventory := wagon_inventories[wagon_index]
	for item_id in recipe.inputs:
		if wagon_inventory.get_quantity(String(item_id)) < int(recipe.inputs[item_id]):
			return "UI_CRAFT_MISSING_MATERIAL"
	return ""

func can_craft_in_wagon(wagon_index: int, recipe: CraftingRecipe) -> bool:
	return get_craft_block_reason_in_wagon(wagon_index, recipe).is_empty()

## Malzemeleri o vagondan tüketir ve tarifin sonucunu uygular - onarım
## kervanın genel hasar sayacını düşürür (vagon başına hasar takibi yok,
## bkz. owned_wagon_damaged), bir eşya üretimi doğrudan aynı vagona yazılır.
## O vagon (girdiler tüketildikten sonra bile) çıktıyı almayacak kadar
## doluysa - küçük bir bandajın olması beklenmez ama imkânsız değil -
## `add_to_cargo_or_bag` son çare: üretilen mal hâlâ hiçbir yerde
## kaybolmaz. Başarısızsa (malzeme yetersiz ya da gereksiz bir onarım)
## hiçbir şey değişmez.
func craft_in_wagon(wagon_index: int, recipe_id: String) -> bool:
	var recipe := RecipeCatalog.get_recipe(recipe_id)
	if recipe == null or not can_craft_in_wagon(wagon_index, recipe):
		return false

	var wagon_inventory := wagon_inventories[wagon_index]
	for item_id in recipe.inputs:
		wagon_inventory.remove_item(String(item_id), int(recipe.inputs[item_id]))

	match recipe.effect:
		CraftingRecipe.Effect.WAGON_REPAIR:
			owned_wagon_damaged = maxi(0, owned_wagon_damaged - 1)
		CraftingRecipe.Effect.ITEM:
			var output := ItemCatalog.get_item(recipe.output_item_id)
			if output != null and not wagon_inventory.add_item(output, recipe.output_quantity):
				add_to_cargo_or_bag(output, recipe.output_quantity)
	return true

## Kervan Envanteri Rules'un kalan parçası: "Kervan Yükü" - hangi vagonun
## ne taşıdığını **bilerek** dağıtmak için ayrı bir ekran (bkz.
## CaravanCargoPanel). `quantity` -1 ise (varsayılan) "elindeki her şeyi
## taşı" - tek tıkla tam yığın taşımanın eski davranışı birebir korunuyor;
## pozitif bir değer verilirse **kısmi** miktar taşınır. Ne kadar istenirse
## istensin işlem yine hep ya da hiçtir (`add_to_cargo`'nun aynı kuralı):
## istenen miktarın tamamı ya taşınır ya da hiçbir şey değişmez - "yarım
## taşınmış bir yığın iki farklı sayıyı iki kez göstermek zorunda kalır"
## endişesi büyüklüğü oyuncu seçtiği için de geçerliliğini koruyor, çünkü
## seçilen miktar da kendi içinde bölünmüyor. Craft'ın "malzeme yanlış
## vagondaysa orada craftlanamaz" kısıtı burada da geçerli - bu ekranın
## bütün amacı o kısıtı bilerek yönetebilmek, kısmi miktar yalnızca ne
## kadarını yönettiğine bir kadran ekliyor.
func get_cargo_move_block_reason(from_index: int, item_id: String, to_index: int, quantity: int = -1) -> String:
	if from_index < 0 or from_index >= wagon_inventories.size():
		return "UI_CARGO_MOVE_INVALID"
	if to_index < 0 or to_index >= wagon_inventories.size():
		return "UI_CARGO_MOVE_INVALID"
	if from_index == to_index:
		return "UI_CARGO_MOVE_INVALID"
	var item := ItemCatalog.get_item(item_id)
	if item == null:
		return "UI_CARGO_MOVE_INVALID"
	var available := wagon_inventories[from_index].get_quantity(item_id)
	if available <= 0:
		return "UI_CARGO_MOVE_INVALID"
	var resolved := available if quantity < 0 else quantity
	if resolved <= 0 or resolved > available:
		return "UI_CARGO_MOVE_INVALID"
	if wagon_inventories[to_index].get_max_addable(item) < resolved:
		return "UI_CARGO_MOVE_NO_ROOM"
	return ""

func can_move_cargo_between_wagons(from_index: int, item_id: String, to_index: int, quantity: int = -1) -> bool:
	return get_cargo_move_block_reason(from_index, item_id, to_index, quantity).is_empty()

## Başarısızsa (bkz. get_cargo_move_block_reason) hiçbir şey değişmez -
## önce hedefin istenen miktarı alabileceği doğrulanıyor, sonra kaynaktan
## çıkarılıyor. `quantity` -1 ise elindeki tamamı taşınır.
func move_cargo_between_wagons(from_index: int, item_id: String, to_index: int, quantity: int = -1) -> bool:
	if not can_move_cargo_between_wagons(from_index, item_id, to_index, quantity):
		return false
	var item := ItemCatalog.get_item(item_id)
	var resolved := wagon_inventories[from_index].get_quantity(item_id) if quantity < 0 else quantity
	wagon_inventories[from_index].remove_item(item_id, resolved)
	wagon_inventories[to_index].add_item(item, resolved)
	return true

## Kalıcı kayıt yalnızca şehir varışında alınır (bkz. SaveManager,
## scripts/ui/road_journey.gd), o noktada sefer hiç aktif değildir ve
## finish_journey() zaten kervanı temizleyip kayıp/hasarı sahiplik
## alanlarına taşımıştır. Bu yüzden journey_*/caravan hiç serileştirilmiyor
## - saklayacak anlamlı bir durumları yok; owned_wagon_* kalıcı olduğu
## için serileştiriliyor.
##
## v2 -> v3: tek paylaşılan `inventory` vagon başına ayrı `Inventory`'lere
## bölündü (bkz. wagon_inventories). Eski kayıtların "inventory" anahtarı
## hâlâ okunuyor (bkz. load_from_dict) - `_migrate_save`de değil, orada
## çünkü dönüşüm vagonların senkron edilmiş olmasını gerektiriyor ve o
## sıra load_from_dict'in kendi akışında.
const SAVE_VERSION: int = 3

func to_save_dict() -> Dictionary:
	var wagon_inventory_data: Array = []
	for wagon_inventory in wagon_inventories:
		wagon_inventory_data.append(wagon_inventory.to_save_array())

	var party_data: Array = []
	for character in party:
		party_data.append(character.to_dict())

	return {
		"version": SAVE_VERSION,
		"gold": wallet.balance,
		"wagon_inventories": wagon_inventory_data,
		"current_location_id": current_location_id,
		"reputation": reputation,
		"flags": _flags.duplicate(),
		"owned_wagon_count": owned_wagon_count,
		"owned_wagon_damaged": owned_wagon_damaged,
		"known_routes": known_routes.duplicate(),
		"total_days_elapsed": total_days_elapsed,
		"accepted_contracts": accepted_contracts.duplicate(),
		"party": party_data,
		"caravan_name": caravan_name,
		"lineage_generation": lineage_generation,
		"leader_since_day": leader_since_day,
		"ledger": ledger.to_array(),
		"last_feast_day": last_feast_day,
		"fulfilled_commission_starts": _fulfilled_commission_starts.duplicate(),
		"delivered_wagon_quest_ids": _delivered_wagon_quest_ids.duplicate(),
		"equipment_inventory": equipment_inventory.duplicate(),
		"debts": debts.to_save_array(),
		"market": market.to_save_dict(),
		"route_conditions": route_conditions.to_save_dict(),
		"world_events": world_events.to_save_dict(),
		"campaign_chapter_index": campaign_chapter_index,
		"journeys_completed": journeys_completed,
		"contracts_delivered": contracts_delivered,
		"visited_location_ids": visited_location_ids.duplicate(),
		"market_stock": market_stock.duplicate(),
		"hired_recruit_indices": hired_recruit_indices.duplicate(true),
		"next_character_serial": _next_character_serial,
		"profiteering_sales": profiteering_sales,
		"crew_names": crew_names.duplicate(),
		"crew_name_serial": _crew_name_serial,
		"crew_hungry_nights": crew_hungry_nights,
		# Sefer ortası kaydı (bkz. Save & Menu Rules): yalnızca sefer açıkken
		# yazılır - şehirde alınan bir kayıt bu bloğu hiç taşımaz.
		"journey": _journey_save_block(),
	}

func _journey_save_block() -> Dictionary:
	if not is_journey_active():
		return {}
	return {
		"origin_id": journey_origin_id,
		"destination_id": journey_destination_id,
		"total_days": journey_total_days,
		"days_remaining": journey_days_remaining,
		"danger_level": danger_level,
		"caravan": caravan.to_dict(),
		"controller": journey_snapshot.duplicate(true),
	}

func _load_journey_block(block: Dictionary) -> void:
	if block.is_empty() or String(block.get("destination_id", "")).is_empty():
		return
	journey_origin_id = String(block.get("origin_id", ""))
	journey_destination_id = String(block.get("destination_id", ""))
	journey_total_days = maxi(1, int(block.get("total_days", 1)))
	journey_days_remaining = clampi(int(block.get("days_remaining", journey_total_days)), 0, journey_total_days)
	danger_level = clampf(float(block.get("danger_level", 0.0)), 0.0, 1.0)
	caravan = CaravanState.from_dict(block.get("caravan", {}) as Dictionary)
	journey_snapshot = (block.get("controller", {}) as Dictionary).duplicate(true)

## Çağıranın taze bir GameSession.new(0, 0) üzerinde çağırması beklenir -
## sıfır başlangıç erzağıyla, aksi halde erzak iki kere eklenir.
## Kayıttaki sürüm numarası. Şu ana kadar her alan `.get(key, default)` ile
## okunduğu için eski kayıtlar kendiliğinden açılıyor (bkz.
## tests/test_save_migration.gd) ve sürüme bakmaya gerek kalmıyor. Ama
## "yazılıp hiç okunmayan" bir alan, gerçekten göç gerektiren ilk değişiklikte
## kimsenin aklına gelmez - o yüzden okuma noktası ve göç kancası şimdiden
## burada duruyor.
func get_save_version(data: Dictionary) -> int:
	return int(data.get("version", 0))

## Sürümden sürüme taşıma. Bugün yapacak bir şey yok: `.get` varsayılanları
## alan eklemelerini zaten karşılıyor. Bir alanın **anlamı** değiştiğinde
## (yeniden adlandırma, birim değişikliği, bölünme) buraya bir dal eklenir.
func _migrate_save(data: Dictionary) -> Dictionary:
	var version := get_save_version(data)
	if version >= SAVE_VERSION:
		return data
	# v0 (sürümsüz) -> v1: yalnızca alan eklendi, dönüştürme gerekmiyor.
	#
	# v1 -> v2: stres kadronun tek bir sayısıyken kişiye taşındı (bkz.
	# CharacterData.stress). Bu, bir alanın **anlamının** değiştiği ilk
	# durum - `.get` varsayılanlarının karşılayamadığı tam olarak bu, ve
	# `_migrate_save`'in var olma sebebi. Eski ortalama kadronun her
	# üyesine dağıtılıyor: bilgi zaten ortalamaydı, kimin ne kadar
	# yıprandığını geriye dönük uydurmak yanlış olurdu.
	if version < 2 and data.has("party_stress"):
		var legacy_stress := clampi(int(data["party_stress"]), 0, MAX_STRESS)
		for entry in data.get("party", []):
			if entry is Dictionary and not entry.has("stress"):
				entry["stress"] = legacy_stress
	return data

func load_from_dict(raw_data: Dictionary) -> void:
	var data := _migrate_save(raw_data)
	# Kese eksi kaydedilmiş olabilir (borca batmış kervan) - earn() negatifi
	# de taşır, ayrıca kenetleme yok.
	wallet.earn(int(data.get("gold", 0)))
	debts.load_from_array(data.get("debts", []) as Array)
	market.load_from_dict(data.get("market", {}) as Dictionary)
	route_conditions.load_from_dict(data.get("route_conditions", {}) as Dictionary)
	world_events.load_from_dict(data.get("world_events", {}) as Dictionary)

	# Vagonlar önce senkron edilir - kargo yalnızca vagonlar gerçek
	# sayısındayken doğru sığar (bkz. `_sync_wagon_inventories`). Eskiden
	# envanter, vagon sayısı düzeltilmeden önce yükleniyordu; tek vagonluk
	# taze bir GameSession'a üç vagonluk bir kargoyu yüklemek o an fazla
	# olan kısmı sessizce düşürüyordu - vagon sayısını önce okumak bunu da
	# düzeltiyor.
	owned_wagon_count = clampi(
		int(data.get("owned_wagon_count", 1)), CaravanState.MIN_WAGONS, CaravanPlan.DEFAULT_MAX_WAGONS
	)
	_sync_wagon_inventories()

	if data.has("wagon_inventories"):
		var saved_wagons: Array = data["wagon_inventories"]
		for index in mini(saved_wagons.size(), wagon_inventories.size()):
			wagon_inventories[index].load_from_array(saved_wagons[index] as Array)
	else:
		# v2 ve öncesi: tek paylaşılan envanter. `add_to_cargo` kendiliğinden
		# vagonlara bölüp dağıtıyor.
		for entry in data.get("inventory", []):
			var item := ItemCatalog.get_item(String(entry.get("item_id", "")))
			var quantity := int(entry.get("quantity", 0))
			if item != null and quantity > 0:
				add_to_cargo(item, quantity)

	current_location_id = String(data.get("current_location_id", WorldMapData.START_LOCATION_ID))
	reputation = int(data.get("reputation", 0))
	_flags = (data.get("flags", {}) as Dictionary).duplicate()
	owned_wagon_damaged = clampi(int(data.get("owned_wagon_damaged", 0)), 0, owned_wagon_count)
	known_routes = (data.get("known_routes", {}) as Dictionary).duplicate()
	total_days_elapsed = int(data.get("total_days_elapsed", 0))

	# Kampanyayı bilmeyen bir kayıt ilk bölümden başlar ve sayaçları sıfır
	# görür - bölümler zaten varışta değerlendirildiği için eski bir kayıt
	# oynanmaya devam edince kendiliğinden yerine oturur.
	campaign_chapter_index = clampi(
		int(data.get("campaign_chapter_index", 0)), 0, CampaignCatalog.chapter_count()
	)
	journeys_completed = maxi(0, int(data.get("journeys_completed", 0)))
	contracts_delivered = maxi(0, int(data.get("contracts_delivered", 0)))
	visited_location_ids = (data.get("visited_location_ids", {}) as Dictionary).duplicate()
	# Bulunduğun şehri görmemiş sayılmak olmaz; eski kayıtlar için de doğru.
	visited_location_ids[current_location_id] = true

	accepted_contracts = {}
	for merchant_id in (data.get("accepted_contracts", {}) as Dictionary):
		accepted_contracts[merchant_id] = int(data["accepted_contracts"][merchant_id])

	party.clear()
	for entry in data.get("party", []):
		party.append(CharacterData.from_dict(entry))
	_ensure_party()

	caravan_name = String(data.get("caravan_name", ""))
	lineage_generation = maxi(1, int(data.get("lineage_generation", 1)))
	leader_since_day = maxi(0, int(data.get("leader_since_day", 0)))
	ledger.load_from_array(data.get("ledger", []) as Array)
	last_feast_day = int(data.get("last_feast_day", -1))
	_fulfilled_commission_starts = {}
	for kind_id in (data.get("fulfilled_commission_starts", {}) as Dictionary):
		_fulfilled_commission_starts[int(kind_id)] = int(data["fulfilled_commission_starts"][kind_id])
	_delivered_wagon_quest_ids = {}
	for merchant_id in (data.get("delivered_wagon_quest_ids", {}) as Dictionary):
		_delivered_wagon_quest_ids[str(merchant_id)] = true

	equipment_inventory = {}
	var equipment_data: Dictionary = data.get("equipment_inventory", {})
	for equipment_id in equipment_data:
		equipment_inventory[str(equipment_id)] = int(equipment_data[equipment_id])

	hired_recruit_indices = {}
	var hired_data: Dictionary = data.get("hired_recruit_indices", {})
	for venue in hired_data:
		var indices: Array = []
		for index in (hired_data[venue] as Array):
			indices.append(int(index))
		hired_recruit_indices[str(venue)] = indices
	profiteering_sales = maxi(0, int(data.get("profiteering_sales", 0)))

	# Kimliği olmayan (eski kayıttan gelen) herkes kimliğini burada alır;
	# sayaç kayıttakinden ve partidekinin en büyüğünden küçük olamaz.
	_next_character_serial = maxi(1, int(data.get("next_character_serial", 1)))
	for character in party:
		_assign_character_id(character)

	crew_names.clear()
	for crew_name in (data.get("crew_names", []) as Array):
		crew_names.append(String(crew_name))
	# Eski kayıtta sayaç yok: listedeki ad sayısından başlamak en fazla
	# bir kez eski bir adı tekrar edebilir, hiçbir zaman mevcut birini ezmez.
	_crew_name_serial = maxi(int(data.get("crew_name_serial", 0)), crew_names.size())
	crew_hungry_nights = maxi(0, int(data.get("crew_hungry_nights", 0)))
	_sync_crew_names()

	_restock_current_location()
	# Pazar stoğu en son: kayıtta varsa tazelenmiş tam stoğun üstüne yazılır,
	# yoksa (eski kayıt) şehrin tam stoğu kalır. Yazılmasaydı şehirde
	# alınan bir kayıt, boşaltılmış pazarı yeniden doldururdu.
	if data.has("market_stock"):
		market_stock.clear()
		var stock_data: Dictionary = data["market_stock"]
		for item_id in stock_data:
			market_stock[str(item_id)] = maxi(0, int(stock_data[item_id]))

	_load_journey_block(data.get("journey", {}) as Dictionary)

## Koşulların baktığı düz sözlük. Her olay değerlendirmesinde bir kez
## kurulur, tek tek koşullar bunun üzerinde tahsisatsız çalışır.
func build_event_context() -> Dictionary:
	# Kültür kimliği ve parti boyutu bir kez okunuyor: ikisi de partiyi
	# baştan tarıyor ve aşağıda beş kültür bayrağı + iki parti alanı
	# tarafından paylaşılıyor. Sözlük yol günü başına tüm olay kataloğu
	# için kurulduğundan tekrarlı tarama boşuna.
	var culture_id := _player_culture_id()
	var party_size := get_party().size()
	var context := {
		"gold": wallet.balance,
		# Borç olaylara açık: alacaklı baskısı, tefeci teklifi ve
		# "borcun varken ne yaparsın" kararları bunlara bakar.
		"debt": get_total_debt(),
		"debt_overdue": 1.0 if not debts.get_overdue_debts(total_days_elapsed).is_empty() else 0.0,
		"provisions": get_provisions(),
		"wagons": caravan.wagon_count,
		"healthy_wagons": caravan.get_healthy_wagon_count(),
		"damaged_wagons": caravan.damaged_wagons,
		"merchants": caravan.merchant_names.size(),
		"morale": caravan.morale,
		"stress": party_stress,
		"documents": caravan.documents,
		"danger": danger_level,
		"days_remaining": journey_days_remaining,
		"reputation": reputation,
		# party_size, get_party() üzerinden okunur (yukarıda): partiyi henüz
		# kimse okumadıysa kurar. Doğrudan party.size() okumak taze bir
		# oturumda 0 döndürüyordu, yani koşullar olmayan bir boş yer görüyordu.
		"party_size": party_size,
		# Koşullar başka bir anahtarla karşılaştırma yapamadığı için boş
		# yer sayısı hazır veriliyor (bkz. evt_road_wanderer).
		"party_slots_free": maxi(0, get_party_capacity() - party_size),
		# Defterin olay havuzuna açılan hafızası (bkz. CaravanLedger başlığı):
		# yol kimin öldüğünü, kimin gittiğini, kaçıncı kuşakta olduğunu okuyabilir.
		"companions_died": ledger.count_of(CaravanLedger.KIND_DIED),
		"companions_departed": ledger.count_of(CaravanLedger.KIND_DEPARTED),
		"companions_lost": get_companions_lost(),
		"lineage_generation": lineage_generation,
		"days_as_leader": get_days_as_leader(),
		"profiteering_sales": profiteering_sales,
		"weakest_companion_hp_ratio": _weakest_companion_hp_ratio(),
		"flags": _flags,
		# EventCondition yalnızca sabitle karşılaştırabildiği için (bkz.
		# party_slots_free üstteki not) İzci varlığı ve oyuncunun kültürü
		# önceden 0/1'e çevrilip hazır veriliyor - bkz. evt_scouted_pass,
		# evt_culture_*.
		# Altı görevin hepsi bağlamda: bir olayın sonucu "kervanda aşçı/
		# levazımcı/otacı var mı" sorusuna bakabilsin diye (bkz. evt_spoiled_
		# provisions). Eskiden yalnızca İzci vardı.
		"has_muhafiz": 1.0 if get_duty_holder(DutyCatalog.MUHAFIZ) != null else 0.0,
		"has_izci": 1.0 if get_duty_holder(DutyCatalog.IZCI) != null else 0.0,
		"has_levazimci": 1.0 if get_duty_holder(DutyCatalog.LEVAZIMCI) != null else 0.0,
		"has_arabaci": 1.0 if get_duty_holder(DutyCatalog.ARABACI) != null else 0.0,
		"has_tellal": 1.0 if get_duty_holder(DutyCatalog.TELLAL) != null else 0.0,
		"has_otaci": 1.0 if get_duty_holder(DutyCatalog.OTACI) != null else 0.0,
		# Karşındakini okumak ve kandırmak partinin en iyisine bakar.
		"best_perception": get_best_effective_stat(CharacterStats.Kind.PERCEPTION),
		"best_charisma": get_best_effective_stat(CharacterStats.Kind.CHARISMA),
		"best_intellect": get_best_effective_stat(CharacterStats.Kind.INTELLECT),
		# Sağduyulu (Zeka'nın huyu) Karizma'nın üstüne bir kandırma payı
		# bindiriyor - bkz. PRUDENT_MANIPULATION_BONUS.
		"effective_manipulation": get_effective_manipulation(),
		"is_nomad_culture": 1.0 if culture_id == CultureCatalog.NOMAD else 0.0,
		"is_valley_culture": 1.0 if culture_id == CultureCatalog.VALLEY else 0.0,
		"is_highland_culture": 1.0 if culture_id == CultureCatalog.HIGHLAND else 0.0,
		"is_port_culture": 1.0 if culture_id == CultureCatalog.PORT else 0.0,
		"is_fisher_culture": 1.0 if culture_id == CultureCatalog.FISHER else 0.0,
	}
	context.merge(_build_world_event_context())
	# Godot 4.2'de Dictionary.merged() yok (4.3+), o yüzden in-place merge().
	context.merge(_build_skill_check_context())
	return context

## --- Lonca özel görevleri (bkz. Faz 17 PR-4) ---
## Haritanın büyük olaylarına (bkz. WorldEvents) bağlı, tek seferlik dört
## görev - kontrat panosunun sıradan tüccar tekliflerinden ayrı bir tab'da
## yaşarlar (bkz. guild.gd). Bir kontratın aksine yolda taşınmazlar:
## kervan hangi şehirdeyse orada anında tamamlanır - "lonca, olan biteni
## zaten duymuş, senden yalnızca kanıtı/katkıyı istiyor" kurgusu, MerchantOffer'ın
## kabul/teslim/süre mimarisini tekrar icat etmeden. Karşılığında ödediği
## kaynak (erzak/eşya/altın) ve ödülü (altın+itibar) WorldEvents.Kind
## başına sabit.
const COMMISSION_WAR_SUPPLY_PROVISIONS: int = 15
const COMMISSION_WAR_SUPPLY_REWARD_GOLD: int = 90
const COMMISSION_WAR_SUPPLY_REWARD_REPUTATION: int = 4

const COMMISSION_PLAGUE_ITEM_ID: String = "test_potion"
const COMMISSION_PLAGUE_ITEM_COUNT: int = 3
const COMMISSION_PLAGUE_REWARD_GOLD: int = 110
const COMMISSION_PLAGUE_REWARD_REPUTATION: int = 5

const COMMISSION_TRADE_FAIR_COST_GOLD: int = 80
const COMMISSION_TRADE_FAIR_REWARD_GOLD: int = 140
const COMMISSION_TRADE_FAIR_REWARD_REPUTATION: int = 2

const COMMISSION_TRIBUTE_COST_GOLD: int = 50
const COMMISSION_TRIBUTE_REWARD_REPUTATION: int = 6

## Loncanın harita çapında haberi var mı - kervanın hangi şehirde/rotada
## olduğuna bakmaz (bkz. WorldEvents.get_active_by_kind).
## Oyuncu dışındaki en yaralı yoldaşın can oranı; yoldaş yoksa 1.0
## (kimse "geride bırakılacak kadar" yaralı değil).
func _weakest_companion_hp_ratio() -> float:
	var weakest := 1.0
	for character in party:
		if character.is_player:
			continue
		weakest = minf(weakest, float(character.current_hp) / float(maxi(1, character.get_max_hp())))
	return weakest

func has_active_world_event(kind: WorldEvents.Kind) -> bool:
	return not world_events.get_active_by_kind(kind, total_days_elapsed).is_empty()

## Faz 17 PR-8: bir görev, o haberin **bir** kez sunduğu bir katkı - ölçüm
## sırasında bulunan gerçek bir sömürü kapatıldı burada: `fulfill_commission`
## hiçbir tekrar koruması taşımıyordu, yani aynı olay 8-30 gün boyunca
## açık kaldığı sürece (ör. Ticaret Fuarı Sponsorluğu, 80 harcayıp 140
## kazandıran) sınırsızca tekrarlanabiliyordu - pazarlığın "aynı düşük
## teklifi üç kez yapmak" kapatılması gibi bir kapatma burada hiç yoktu.
## Anahtar olayın **kendi `started_day`'i**: aynı olay sürerken bir daha
## alınamaz, ama süresi dolup *yeni* bir haber gelince (farklı `started_day`)
## tekrar açılır - "haber tekrar geldi, katkı da tekrar mümkün" mantığı.
var _fulfilled_commission_starts: Dictionary = {}  # int(Kind) -> son katkının started_day'i

func _has_unfulfilled_commission_instance(kind: WorldEvents.Kind) -> bool:
	var already := int(_fulfilled_commission_starts.get(int(kind), -1))
	for entry in world_events.get_active_by_kind(kind, total_days_elapsed):
		if int(entry["started_day"]) != already:
			return true
	return false

## Disabled-with-reason kuralı (bkz. CLAUDE.md'nin kilitli seçenek/vagon
## satışı/craft'ın hepsinde tekrarlanan deseni): boş dönerse görev alınabilir.
func get_commission_block_reason(kind: WorldEvents.Kind) -> String:
	if not has_active_world_event(kind):
		return "UI_COMMISSION_NO_EVENT"
	if not _has_unfulfilled_commission_instance(kind):
		return "UI_COMMISSION_ALREADY_FULFILLED"
	match kind:
		WorldEvents.Kind.REGIONAL_WAR:
			if get_provisions() < COMMISSION_WAR_SUPPLY_PROVISIONS:
				return "UI_COMMISSION_NEED_PROVISIONS"
		WorldEvents.Kind.PLAGUE:
			if get_total_quantity(COMMISSION_PLAGUE_ITEM_ID) < COMMISSION_PLAGUE_ITEM_COUNT:
				return "UI_COMMISSION_NEED_ITEM"
		WorldEvents.Kind.TRADE_FAIR:
			if wallet.balance < COMMISSION_TRADE_FAIR_COST_GOLD:
				return "UI_COMMISSION_NEED_GOLD"
		WorldEvents.Kind.BANDIT_TRIBUTE:
			if wallet.balance < COMMISSION_TRIBUTE_COST_GOLD:
				return "UI_COMMISSION_NEED_GOLD"
	return ""

## Tek kapı: dört görevin hepsi buradan geçer. Kaynak zaten yeterli
## değilse (get_commission_block_reason boş değilse) hiçbir şey yapmadan
## false döner - yarım uygulanan bir görev (parayı al, ödülü verme)
## kargo/craft'ın "hepsi ya da hiçbiri" kuralını bozardı.
func fulfill_commission(kind: WorldEvents.Kind) -> bool:
	if not get_commission_block_reason(kind).is_empty():
		return false
	match kind:
		WorldEvents.Kind.REGIONAL_WAR:
			change_provisions(-COMMISSION_WAR_SUPPLY_PROVISIONS)
			wallet.earn(COMMISSION_WAR_SUPPLY_REWARD_GOLD)
			change_reputation(COMMISSION_WAR_SUPPLY_REWARD_REPUTATION)
		WorldEvents.Kind.PLAGUE:
			remove_from_cargo_or_bags(COMMISSION_PLAGUE_ITEM_ID, COMMISSION_PLAGUE_ITEM_COUNT)
			wallet.earn(COMMISSION_PLAGUE_REWARD_GOLD)
			change_reputation(COMMISSION_PLAGUE_REWARD_REPUTATION)
		WorldEvents.Kind.TRADE_FAIR:
			wallet.spend(COMMISSION_TRADE_FAIR_COST_GOLD)
			wallet.earn(COMMISSION_TRADE_FAIR_REWARD_GOLD)
			change_reputation(COMMISSION_TRADE_FAIR_REWARD_REPUTATION)
		WorldEvents.Kind.BANDIT_TRIBUTE:
			wallet.spend(COMMISSION_TRIBUTE_COST_GOLD)
			change_reputation(COMMISSION_TRIBUTE_REWARD_REPUTATION)
	var active := world_events.get_active_by_kind(kind, total_days_elapsed)
	if not active.is_empty():
		_fulfilled_commission_starts[int(kind)] = int(active[0]["started_day"])
	return true

## Faz 17: büyük dünya olaylarının (bkz. WorldEvents) mevcut yol/hedef şehir
## üstündeki payı - haber olayları (evt_regional_war_news ve kardeşleri)
## aynı türden ikinci bir olayın üstüne binmesin diye ("<X>_active" olarak
## okunuyorsa haber olayı kendi koşulunda bunu LESS_EQUAL 0 ile tersine
## çevirir), haraç tahsildarı olayı (evt_bandit_tribute_toll) da bu bayrağı
## doğrudan okuyor.
func _build_world_event_context() -> Dictionary:
	var route_key := ""
	if not journey_origin_id.is_empty() and not journey_destination_id.is_empty():
		route_key = RouteConditions.route_key(journey_origin_id, journey_destination_id)
	return {
		"route_has_regional_war": 1.0 if world_events.has_kind_on_route(
			WorldEvents.Kind.REGIONAL_WAR, route_key, total_days_elapsed
		) else 0.0,
		"route_has_bandit_tribute": 1.0 if world_events.has_kind_on_route(
			WorldEvents.Kind.BANDIT_TRIBUTE, route_key, total_days_elapsed
		) else 0.0,
		"destination_has_plague": 1.0 if world_events.has_kind_on_city(
			WorldEvents.Kind.PLAGUE, journey_destination_id, total_days_elapsed
		) else 0.0,
		"destination_has_trade_fair": 1.0 if world_events.has_kind_on_city(
			WorldEvents.Kind.TRADE_FAIR, journey_destination_id, total_days_elapsed
		) else 0.0,
	}

## Faz 17: SkillCheck'in okuduğu genel sözlük - sekiz statın hepsi için
## "en iyisi" (parti) ve "lider" değeri. Üstteki elle yazılmış best_perception/
## best_charisma/best_intellect anahtarları bilerek silinmedi (eski olaylar
## ve testler hâlâ onları okuyor) - bu yalnızca SkillCheck.get_context_key()'in
## okuduğu, sekiz statın hepsini kapsayan genel katman.
func _build_skill_check_context() -> Dictionary:
	var context := {}
	for kind in CharacterStats.KIND_ORDER:
		var stat_name: String = String(CharacterStats.Kind.keys()[kind]).to_lower()
		context["best_%s" % stat_name] = get_best_effective_stat(kind)
		context["leader_%s" % stat_name] = get_leader_effective_stat(kind)
	return context

func _player_culture_id() -> String:
	var player := get_player_character()
	return player.culture_id if player != null else ""

# --- Kampanya ---
#
# Oyunun sonu olan bir hikâyesi var ama son bölüm oyunu kapatmıyor
# (bkz. CampaignCatalog). Bölüm hedefleri `EventCondition` ile yazılıyor -
# yeni bir görev dili icat etmemek bilinçli - ama okudukları bağlam
# ayrı: burası kervanın **ömrünü** anlatır, `build_event_context()` ise
# o anki yolu. Bölüm hedefi yol bağlamına baksaydı, her varışta kervan
# sıfırlandığı için tamamlanıp tamamlanmamaya geri dönerdi.

var campaign_chapter_index: int = 0
var journeys_completed: int = 0
var contracts_delivered: int = 0

## Görülen şehirler kümesi (location_id -> true). Sayısı kampanya
## bağlamında `cities_visited` olarak duruyor.
var visited_location_ids: Dictionary = {}

func build_campaign_context() -> Dictionary:
	return {
		"gold": wallet.balance,
		"debt": get_total_debt(),
		"reputation": reputation,
		"days": total_days_elapsed,
		"party_size": get_party().size(),
		"owned_wagons": owned_wagon_count,
		"journeys_completed": journeys_completed,
		"contracts_delivered": contracts_delivered,
		"cities_visited": visited_location_ids.size(),
		# Soy: hikâye kervanın toplam yaşına değil, bu liderin dönemine de
		# bakabiliyor. Bir bölüm "şu kadar gün bu adı taşı" diyebilir.
		"lineage_generation": lineage_generation,
		"days_as_leader": get_days_as_leader(),
		"companions_lost": get_companions_lost(),
		"flags": _flags,
	}

func get_current_chapter() -> CampaignChapter:
	return CampaignCatalog.get_chapter(campaign_chapter_index)

## Hikâye bitti mi? Bitmesi oyunun bitmesi değil - kese, yol ve pazar
## olduğu gibi durur (bkz. CampaignCatalog'un `is_finale` notu).
func is_campaign_finished() -> bool:
	return campaign_chapter_index >= CampaignCatalog.chapter_count()

## Şehre varışta çağrılır. Tamamlanan bölümleri sırayla kapatır - tek
## varışta birden fazla bölüm bitebilir, çünkü uzun bir sefer iki hedefi
## birden karşılayabilir ve oyuncuyu "bir varış = bir bölüm" diye
## bekletmenin bir sebebi yok. Kapanan bölümlerin listesini döner.
##
## Bölüm bir kez kapandı mı bir daha değerlendirilmez: hedef "2500 altın"
## ise, parayı sonra harcamak hikâyeyi geri almaz.
func advance_campaign() -> Array[CampaignChapter]:
	var completed: Array[CampaignChapter] = []
	while not is_campaign_finished():
		var chapter := get_current_chapter()
		if chapter == null or not chapter.is_complete(build_campaign_context()):
			break
		campaign_chapter_index += 1
		if not chapter.completion_flag.is_empty():
			set_flag(chapter.completion_flag)
		if chapter.reward_gold > 0:
			wallet.earn(chapter.reward_gold)
		change_reputation(chapter.reward_reputation)
		completed.append(chapter)
	return completed
