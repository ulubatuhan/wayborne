extends Control

## Tüccar Loncası: kontrat panosu. Haritadaki statik tüccar teklifleri
## artık burada kabul edilen kontratlara dönüşüyor - kabul edilince
## panodan kalkar (bkz. GameSession.accepted_contracts), kervan
## planlayıcıda yalnızca kabul edilenler seçilebilir olur. Sefere
## çıkılmadan süresi geçerse (advance_day) ya da yolda teslim edilemezse
## (finish_journey) itibar cezası uygulanır.

var _session: GameSession
var _rows: Array[Dictionary] = []

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var _contract_list: VBoxContainer = $MarginContainer/VBoxContainer/ContractList
@onready var _accepted_title: Label = $MarginContainer/VBoxContainer/AcceptedTitle
@onready var _accepted_list: VBoxContainer = $MarginContainer/VBoxContainer/AcceptedList
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_session = GameState.get_session()
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_back_button.text = Nav.return_label()
	_back_button.pressed.connect(_on_back_pressed)
	_add_recruit_button(RecruitCatalog.VENUE_GUILD, Nav.GUILD)

	var location := WorldMapData.get_location_by_id(_session.current_location_id)
	_title_label.text = "Tüccar Loncası" if location == null else "%s Tüccar Loncası" % location.location_name
	_info_label.text = "Kabul ettiğin kontrat panodan kalkar; sefere çıkmadan süresi geçerse ya da yolda teslim edilmezse itibarın düşer."

	_rebuild()

func _rebuild() -> void:
	_clear_children(_contract_list)
	_clear_children(_accepted_list)
	_rows.clear()

	for offer in _available_offers():
		_contract_list.add_child(_build_offer_row(offer))
	_refresh_offer_rows()

	var accepted := _accepted_offers()
	_accepted_title.visible = not accepted.is_empty()
	for offer in accepted:
		_accepted_list.add_child(_build_accepted_row(offer))

func _available_offers() -> Array[MerchantOffer]:
	var offers: Array[MerchantOffer] = []
	for offer in WorldMapData.get_offers_from_origin(_session.current_location_id):
		if _session.is_contract_accepted(offer.merchant_id):
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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var info_label := Label.new()
	info_label.text = "%s → %s — %d vagon — +%d GG — %d gün süre" % [
		offer.merchant_name,
		destination.location_name if destination != null else offer.destination_location_id,
		offer.wagon_count,
		offer.potential_profit,
		offer.contract_deadline_days,
	]
	info_label.custom_minimum_size = Vector2(440, 0)
	row.add_child(info_label)

	var accept_button := Button.new()
	accept_button.pressed.connect(_on_accept_pressed.bind(offer))
	row.add_child(accept_button)

	_rows.append({"offer": offer, "accept_button": accept_button})
	return row

func _refresh_offer_rows() -> void:
	for row in _rows:
		var offer: MerchantOffer = row.offer
		var accept_button: Button = row.accept_button
		if _session.reputation < offer.required_reputation:
			accept_button.text = "İtibar yetersiz (%d gerekli)" % offer.required_reputation
			accept_button.disabled = true
		else:
			accept_button.text = "Kontratı Kabul Et"
			accept_button.disabled = false

func _build_accepted_row(offer: MerchantOffer) -> Label:
	var destination := WorldMapData.get_location_by_id(offer.destination_location_id)
	var accepted_at: int = _session.accepted_contracts.get(offer.merchant_id, _session.total_days_elapsed)
	var days_left := maxi(0, accepted_at + offer.contract_deadline_days - _session.total_days_elapsed)

	var label := Label.new()
	label.text = "%s → %s — +%d GG — %d gün kaldı" % [
		offer.merchant_name,
		destination.location_name if destination != null else offer.destination_location_id,
		offer.potential_profit,
		days_left,
	]
	return label

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
	get_tree().change_scene_to_file(Nav.return_scene)

## Tayfa ekranı ortak; hangi mekândan girildiğini gönderen ekran bildirir
## (bkz. Nav.recruit_venue). Geri tuşu buraya döner.
func _add_recruit_button(venue: String, own_scene: String) -> void:
	var button := Button.new()
	button.text = "Tayfa Ara"
	button.pressed.connect(_on_recruit_button_pressed.bind(venue, own_scene))
	var container := _back_button.get_parent()
	container.add_child(button)
	container.move_child(button, _back_button.get_index())

func _on_recruit_button_pressed(venue: String, own_scene: String) -> void:
	Nav.recruit_venue = venue
	Nav.return_scene = own_scene
	get_tree().change_scene_to_file(Nav.RECRUIT)
