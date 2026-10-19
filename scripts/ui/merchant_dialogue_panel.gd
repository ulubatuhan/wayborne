class_name MerchantDialoguePanel
extends Node

## Kervana kabul edilmiş (eskort) bir tüccarla yolda açılan sohbet - bkz.
## CLAUDE.md Ana Hedefler'in "#11" notu. Yol ekranının emir panelindeki
## "Tüccarla Konuş" komutuyla açılıyor (bkz. road_journey.gd). Görünüşü
## `DialoguePanel`: portreli konuşma penceresi (kullanıcı isteği 2026-10-19,
## NPC konuşmaları hep bu pencerede).
##
## Birden çok tüccar eskort edilebildiği için önce kervanbaşı "kiminle?" diye
## sorar; bir tüccar seçilince portre onunkine döner. İzin isteme adımı
## otomatik: mizaca göre ya izin verilir ya reddedilir (bkz. GameSession.
## merchant_grants_permission). Reddedilirse üç yol: Zorla Bak / Tekrar İkna
## Et / Vazgeç - kullanıcının kendi tarifiyle: "izin verirse görüntüleriz, izin
## vermezse zor kullanarak bakabilir, tekrar ikna etmeye çalışabilir ya da
## vazgeçebiliriz."
##
## Ödül bilgi: mizaç (Sezgi eşiğiyle okunabildiği kadarıyla, bkz.
## GameSession.get_merchant_disposition_label) ve vagonun gerçek yükü (bkz.
## GameSession.get_merchant_cargo_entries). Yazılabilecek bir envanter yok:
## bu `Inventory` hiçbir zaman `GameSession.wagon_inventories`'e girmez.

signal closed

var _session: GameSession
var _rng: RandomNumberGenerator
var _panel: DialoguePanel
var _selected_merchant: String = ""

func setup(session: GameSession, rng: RandomNumberGenerator = null) -> void:
	_session = session
	_rng = rng if rng != null else RandomNumberGenerator.new()
	_panel = DialoguePanel.new()
	add_child(_panel)
	_panel.choice_made.connect(_on_choice)
	_panel.closed.connect(func() -> void:
		closed.emit()
		queue_free())
	var names := _session.caravan.merchant_names
	if names.size() == 1:
		_selected_merchant = names[0]
		_panel.open(_merchant_character(_selected_merchant), tr("UI_MERCHANT_ROLE"), "", [])
		_show_merchant()
	else:
		_panel.open(_session.get_player_character(), tr("UI_PANEL_LEADER"), "", [], true, "")
		_show_list()

## Tüccarın yüzü: adından tohumlanan bir kılık, her bakışta aynı kişi.
func _merchant_character(merchant_name: String) -> CharacterData:
	return DialoguePanel.stranger(tr(merchant_name), "merchant|%s|%d" % [merchant_name, _session.journey_start_day])

func _show_list() -> void:
	_selected_merchant = ""
	_panel.set_speaker(_session.get_player_character(), tr("UI_PANEL_LEADER"), "")
	var names := _session.caravan.merchant_names
	if names.is_empty():
		_panel.say(tr("UI_MERCHANT_DIALOGUE_NONE"), [{"id": "bye", "text": tr("UI_TALK_BYE")}])
		return
	var choices: Array = []
	for merchant_name in names:
		var text := tr(merchant_name)
		if _session.is_merchant_known(merchant_name):
			var disposition := _session.get_merchant_disposition_label(merchant_name)
			text += " · " + (disposition if not disposition.is_empty() else tr("UI_MERCHANT_DIALOGUE_UNREADABLE"))
		choices.append({"id": "m:" + merchant_name, "text": text})
	choices.append({"id": "bye", "text": tr("UI_TALK_BYE")})
	_panel.say(tr("UI_MERCHANT_DIALOGUE_PICK"), choices)

## Detay görünümüne her girişte mizaç yeniden sorulmaz - bir kez bilinen
## bir mizaç sefer boyunca bilinir (bkz. GameSession.is_merchant_known).
func _show_merchant() -> void:
	_panel.set_speaker(_merchant_character(_selected_merchant), tr("UI_MERCHANT_ROLE"))
	if not _session.is_merchant_known(_selected_merchant) and _session.merchant_grants_permission(_selected_merchant):
		_session.grant_merchant_look(_selected_merchant)
	var tail: Array = []
	if _session.caravan.merchant_names.size() > 1:
		tail.append({"id": "back", "text": tr("UI_MERCHANT_DIALOGUE_BACK")})
	tail.append({"id": "bye", "text": tr("UI_TALK_BYE")})
	if _session.is_merchant_known(_selected_merchant):
		_panel.say(_result_text(), tail)
		return
	var choices: Array = [
		{"id": "force", "text": tr("UI_MERCHANT_DIALOGUE_FORCE_SHORT"), "cost": tr("UI_MERCHANT_DIALOGUE_REP_COST") % GameSession.FORCE_LOOK_MERCHANT_REPUTATION_PENALTY},
		{"id": "persuade", "text": tr("UI_MERCHANT_DIALOGUE_PERSUADE")},
	]
	_panel.say(tr("UI_MERCHANT_DIALOGUE_REFUSED"), choices + tail)

## Mizaç ve vagonun yükü tek metinde (salt okuma: al/sat yolu yok, #22).
func _result_text() -> String:
	var lines: Array[String] = []
	var disposition := _session.get_merchant_disposition_label(_selected_merchant)
	lines.append(tr("UI_MERCHANT_DIALOGUE_VAGUE") if disposition.is_empty() else tr("UI_MERCHANT_DIALOGUE_RESULT") % disposition)
	var entries := _session.get_merchant_cargo_entries(_selected_merchant)
	if entries.is_empty():
		lines.append(tr("UI_MERCHANT_DIALOGUE_CARGO_EMPTY"))
	else:
		var goods: Array[String] = []
		for entry in entries:
			var item: Item = entry.item
			goods.append(tr("UI_STATUS_CARGO_ITEM") % [item.item_name, int(entry.quantity)])
		lines.append(tr("UI_MERCHANT_DIALOGUE_CARGO_TITLE") + " " + ", ".join(goods))
	return "\n\n".join(lines)

func _on_choice(id: String) -> void:
	if id.begins_with("m:"):
		_selected_merchant = id.substr(2)
		_show_merchant()
		return
	match id:
		"force":
			_session.force_look_merchant_wagon(_selected_merchant)
			_show_merchant()
		"persuade":
			if _session.attempt_merchant_persuasion(_rng):
				_session.grant_merchant_look(_selected_merchant)
			_show_merchant()
		"back":
			_show_list()
		_:
			_panel.close()
