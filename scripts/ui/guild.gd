extends Control

## Tüccar Loncası: kontrat panosu. Haritadaki statik tüccar teklifleri
## artık burada kabul edilen kontratlara dönüşüyor - kabul edilince
## panodan kalkar (bkz. GameSession.accepted_contracts), kervan
## planlayıcıda yalnızca kabul edilenler seçilebilir olur. Sefere
## çıkılmadan süresi geçerse (advance_day) ya da yolda teslim edilemezse
## (finish_journey) itibar cezası uygulanır.

const HINT_COLOR: Color = Color(0.7, 0.72, 0.78)

var _session: GameSession
var _debt_panel: DebtPanel
var _rows: Array[Dictionary] = []

# İki sekme: pano ve borç defteri. Her sekme kendi kaydırma kutusunda,
# geri tuşu ikisinin de dışında - içerik uzadıkça çıkış ekrandan taşmasın
# (bkz. World Navigation Rules).
@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var _tabs: TabContainer = $MarginContainer/VBoxContainer/TabContainer
@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/TabContainer/ContractsTab/ContentContainer
@onready var _debt_container: VBoxContainer = $MarginContainer/VBoxContainer/TabContainer/DebtsTab/DebtContainer
@onready var _commission_container: VBoxContainer = $MarginContainer/VBoxContainer/TabContainer/CommissionsTab/CommissionContainer
@onready var _contract_list: VBoxContainer = _content.get_node("ContractList")
@onready var _accepted_title: Label = _content.get_node("AcceptedTitle")
@onready var _accepted_list: VBoxContainer = _content.get_node("AcceptedList")
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_session = GameState.get_session()
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_back_button.text = Nav.back_label()
	_back_button.pressed.connect(_on_back_pressed)
	_add_recruit_button(RecruitCatalog.VENUE_GUILD, Nav.GUILD)

	var location := WorldMapData.get_location_by_id(_session.current_location_id)
	_title_label.text = tr("UI_GUILD_TITLE") if location == null else tr("UI_GUILD_TITLE_CITY") % location.location_name
	_info_label.text = tr("UI_GUILD_HINT")
	_accepted_title.text = tr("UI_GUILD_ACCEPTED_TITLE")

	# Borç defteri kendi sekmesinde: alacaklı da kontrat da loncanın
	# defterinde durur. Mekanik Faz 9 A'da vardı ama hiçbir ekrana bağlı
	# değildi - kervan borca batıyor, faiz işliyor, itibar eriyor ve oyuncu
	# bunu göremiyordu. Panonun altına gömülü bir bölüm olarak da
	# görülmüyordu: kontrat listesi uzayınca aşağıda kalıyordu.
	_tabs.set_tab_title(0, tr("UI_GUILD_TAB_CONTRACTS"))
	_tabs.set_tab_title(1, tr("UI_GUILD_TAB_DEBTS"))
	_tabs.set_tab_title(2, tr("UI_GUILD_TAB_COMMISSIONS"))
	_tabs.current_tab = Nav.guild_initial_tab
	Nav.guild_initial_tab = 0

	_debt_panel = DebtPanel.new()
	_debt_container.add_child(_debt_panel)
	_debt_panel.setup(_session)
	_debt_panel.ledger_changed.connect(_rebuild)
	_session.wallet.balance_changed.connect(_on_wallet_changed)

	_rebuild()

func _on_wallet_changed(_new_balance: int) -> void:
	if _debt_panel != null:
		_debt_panel.refresh()

## Faz 17: lonca özel görevleri - kontrat panosunun sıradan MerchantOffer
## akışından ayrı, WorldEvents'e bağlı dört tek seferlik görev (bkz.
## GameSession.fulfill_commission). Hepsi her zaman görünür, kilitli
## olan kendi sebebiyle gösterilir - locked event choice/vagon satışı/
## craft'ın hepsinde tekrarlanan "disabled with reason" kuralı.
const COMMISSION_KINDS: Array[WorldEvents.Kind] = [
	WorldEvents.Kind.REGIONAL_WAR,
	WorldEvents.Kind.PLAGUE,
	WorldEvents.Kind.TRADE_FAIR,
	WorldEvents.Kind.BANDIT_TRIBUTE,
]
const COMMISSION_TITLE_KEYS: Dictionary = {
	WorldEvents.Kind.REGIONAL_WAR: "UI_COMMISSION_WAR_SUPPLY_TITLE",
	WorldEvents.Kind.PLAGUE: "UI_COMMISSION_PLAGUE_RELIEF_TITLE",
	WorldEvents.Kind.TRADE_FAIR: "UI_COMMISSION_TRADE_FAIR_TITLE",
	WorldEvents.Kind.BANDIT_TRIBUTE: "UI_COMMISSION_TRIBUTE_INTEL_TITLE",
}
const COMMISSION_DESC_KEYS: Dictionary = {
	WorldEvents.Kind.REGIONAL_WAR: "UI_COMMISSION_WAR_SUPPLY_DESC",
	WorldEvents.Kind.PLAGUE: "UI_COMMISSION_PLAGUE_RELIEF_DESC",
	WorldEvents.Kind.TRADE_FAIR: "UI_COMMISSION_TRADE_FAIR_DESC",
	WorldEvents.Kind.BANDIT_TRIBUTE: "UI_COMMISSION_TRIBUTE_INTEL_DESC",
}

func _rebuild() -> void:
	if _debt_panel != null:
		_debt_panel.refresh()
	_clear_children(_contract_list)
	_clear_children(_accepted_list)
	_clear_children(_commission_container)
	_rows.clear()

	for offer in _available_offers():
		_contract_list.add_child(_build_offer_row(offer))
	_refresh_offer_rows()

	for kind in COMMISSION_KINDS:
		_commission_container.add_child(_build_commission_row(kind))

	var accepted := _accepted_offers()
	_accepted_title.visible = not accepted.is_empty()
	if not accepted.is_empty():
		# **Teslimat nerede yapılır?** Hedefe varıldığı anda kendiliğinden -
		# ayrı bir tuş yok. Oyun bunu hiç söylemiyordu ve bir playtest
		# oyuncusu kontratı taşıdıktan sonra şehirde "teslim et" ekranı
		# aradı. Kabul ettiği yerde okuması gereken cümle bu.
		var how := Label.new()
		how.text = tr("UI_GUILD_DELIVERY_HINT")
		how.autowrap_mode = TextServer.AUTOWRAP_WORD
		how.modulate = HINT_COLOR
		_accepted_list.add_child(how)
	for offer in accepted:
		_accepted_list.add_child(_build_accepted_row(offer))

func _available_offers() -> Array[MerchantOffer]:
	var offers: Array[MerchantOffer] = []
	for offer in WorldMapData.get_offers_from_origin(_session.current_location_id):
		if _session.is_contract_accepted(offer.merchant_id):
			continue
		# Loncanın vagon-bağışı görevleri teslim edilince bir daha hiç
		# görünmez (bkz. GameSession.is_guild_wagon_quest_delivered) -
		# kargo görevleri de sıradan kontratlar da teslim edildikçe
		# panoya geri döner (bkz. accepted_contracts'ın kendi notu).
		if offer.grants_wagon_on_delivery and _session.is_guild_wagon_quest_delivered(offer.merchant_id):
			continue
		offers.append(offer)
	return offers

func _accepted_offers() -> Array[MerchantOffer]:
	var offers: Array[MerchantOffer] = []
	for merchant_id in _session.accepted_contracts:
		var offer := WorldMapData.get_offer_by_merchant_id(merchant_id)
		if offer != null and offer.origin_location_id == _session.current_location_id:
			offers.append(offer)
	return offers

func _build_offer_row(offer: MerchantOffer) -> HBoxContainer:
	var destination := WorldMapData.get_location_by_id(offer.destination_location_id)
	var destination_name := destination.location_name if destination != null else offer.destination_location_id
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var info_label := _row_label(_offer_line_text(offer, destination_name))
	row.add_child(info_label)

	var accept_button := _row_action()
	accept_button.pressed.connect(_on_accept_pressed.bind(offer))
	row.add_child(accept_button)

	_rows.append({"offer": offer, "accept_button": accept_button})
	return row

func _refresh_offer_rows() -> void:
	for row in _rows:
		var offer: MerchantOffer = row.offer
		var accept_button: Button = row.accept_button
		if _session.reputation < offer.required_reputation:
			accept_button.text = tr("UI_GUILD_NEED_REPUTATION") % offer.required_reputation
			accept_button.disabled = true
		else:
			accept_button.text = tr("UI_GUILD_ACCEPT")
			accept_button.disabled = false

func _build_accepted_row(offer: MerchantOffer) -> Label:
	var destination := WorldMapData.get_location_by_id(offer.destination_location_id)
	var destination_name := destination.location_name if destination != null else offer.destination_location_id
	var accepted_at: int = _session.accepted_contracts.get(offer.merchant_id, _session.total_days_elapsed)
	var days_left := maxi(0, accepted_at + offer.contract_deadline_days - _session.total_days_elapsed)

	var label := Label.new()
	label.text = _accepted_line_text(offer, destination_name, days_left)
	return label

## Faz 17 PR-4: loncanın iki özel vagon görevi altın yerine ayni ödül
## taşıyor (bkz. MerchantOffer.grants_wagon_on_delivery/cargo_reward_*),
## yani sıradan `UI_GUILD_OFFER`in "+%d GG" satırı burada anlamsız kalırdı
## ("0 altın kâr" okunurdu) - iki ayrı format anahtarı ödülü doğru anlatıyor.
func _offer_line_text(offer: MerchantOffer, destination_name: String) -> String:
	if offer.grants_wagon_on_delivery:
		return tr("UI_GUILD_WAGON_OFFER") % [
			tr(offer.merchant_name), destination_name, offer.contract_deadline_days,
		]
	if offer.cargo_reward_quantity > 0:
		var item := ItemCatalog.get_item(offer.cargo_reward_item_id)
		var item_name := item.item_name if item != null else offer.cargo_reward_item_id
		return tr("UI_GUILD_FREIGHT_OFFER") % [
			tr(offer.merchant_name), destination_name,
			offer.cargo_reward_quantity, item_name, offer.contract_deadline_days,
		]
	return tr("UI_GUILD_OFFER") % [
		offer.merchant_name, destination_name, offer.wagon_count,
		offer.potential_profit, offer.contract_deadline_days,
	]

func _accepted_line_text(offer: MerchantOffer, destination_name: String, days_left: int) -> String:
	if offer.grants_wagon_on_delivery:
		return tr("UI_GUILD_WAGON_ACCEPTED") % [tr(offer.merchant_name), destination_name, days_left]
	if offer.cargo_reward_quantity > 0:
		var item := ItemCatalog.get_item(offer.cargo_reward_item_id)
		var item_name := item.item_name if item != null else offer.cargo_reward_item_id
		return tr("UI_GUILD_FREIGHT_ACCEPTED") % [
			tr(offer.merchant_name), destination_name, offer.cargo_reward_quantity, item_name, days_left,
		]
	return tr("UI_GUILD_ACCEPTED") % [offer.merchant_name, destination_name, offer.potential_profit, days_left]

func _build_commission_row(kind: WorldEvents.Kind) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	row.add_child(_row_label("%s\n%s" % [
		tr(String(COMMISSION_TITLE_KEYS[kind])), tr(String(COMMISSION_DESC_KEYS[kind])),
	]))

	var button := _row_action()
	var block_reason := _session.get_commission_block_reason(kind)
	if block_reason.is_empty():
		button.text = tr("UI_COMMISSION_ACCEPT")
		button.pressed.connect(_on_commission_pressed.bind(kind))
	else:
		button.text = tr(block_reason)
		button.disabled = true
	row.add_child(button)
	return row

## Satırın metni kalan yeri alıyor ve sarılıyor; eylem düğmesi kendi
## genişliğini koruyor. Metnin sabit 440'lık bir asgarisi vardı ve
## sarılmıyordu - dar pencerede satır düğmeyi ekranın dışına itiyor, uzun
## kilit sebebi ("İtibar yetersiz (5 gerekli)") sekmenin kenarından
## taşıyordu (ölçüldü).
const ROW_TEXT_MIN_WIDTH: float = 240.0
const ROW_ACTION_MIN_WIDTH: float = 230.0

func _row_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size = Vector2(ROW_TEXT_MIN_WIDTH, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _row_action() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(ROW_ACTION_MIN_WIDTH, 0.0)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return button

func _on_commission_pressed(kind: WorldEvents.Kind) -> void:
	if _session.fulfill_commission(kind):
		_rebuild()

func _on_accept_pressed(offer: MerchantOffer) -> void:
	if _session.reputation < offer.required_reputation:
		return
	_session.accept_contract(offer)
	_rebuild()

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.back())

## Tayfa ekranı ortak; hangi mekândan girildiğini gönderen ekran bildirir
## (bkz. Nav.recruit_venue). Geri tuşu gezinme yığınından döner.
func _add_recruit_button(venue: String, own_scene: String) -> void:
	var button := Button.new()
	button.text = tr("UI_LOOK_FOR_CREW")
	button.pressed.connect(_on_recruit_button_pressed.bind(venue, own_scene))
	var container := _back_button.get_parent()
	container.add_child(button)
	container.move_child(button, _back_button.get_index())

func _on_recruit_button_pressed(venue: String, own_scene: String) -> void:
	get_tree().change_scene_to_file(Nav.open_recruit(venue, own_scene))
