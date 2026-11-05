class_name HagglingPanel
extends VBoxContainer

## Pazarlığın tek kararlık arayüzü (P1, kullanıcı kararı 2026-11-05).
## Pazar ekranı ve yol olaylarının `TRIGGER_HAGGLING` etkisi bunu kullanır,
## böylece pazarlık tek bir yerde durur.
##
## Üç düğme: **kabul et · diren · çık git**. Kaydıraç yok, tur yok, sabır
## çubuğu yok, ültimatom yok - hepsi kaldırıldı (gerekçe
## `HagglingSession`'ın başlığında). Direnmenin şansı ekranda yazılı:
## oyuncunun tek hakkı var, kör zar atmamalı.
##
## Kıtlıkta "diren" **üstelemek** olur (P2): karşındaki de aç. Düğmenin
## yazısı ve sonuç cümlesi değişir, bedeli çağıran uygular
## (`conscience_standing_cost` sinyalle taşınır).

signal deal_made(price: int)
## Masadan kalkmanın itibar bedeli birlikte taşınır: paneli açan ekran
## cezayı kendi bağlamına göre uygular (şehir tüccarını kızdırmak kasabada
## duyulur, yoldaki haydudu kızdırmak duyulmaz - bkz. market.gd/road_journey.gd).
signal haggling_failed(reputation_penalty: int)
## Direnmenin sonucu. **Pazarlık burada bitmiyor:** kaybetsen de fiyat
## artmış hâliyle masada duruyor, kabul etmek ya da kalkmak hâlâ senin
## kararın. Bu yüzden `haggling_failed` değil ayrı bir sinyal - o sinyal
## çağıranlarda "anlaşma bitti" demek.
## `reputation_cost` kaybedince, `standing_cost` kıtlıkta üsteleyip
## kazanınca (P2); çağıran ikisini kendi bağlamında uygular.
signal push_resolved(won: bool, reputation_cost: int, standing_cost: int)

var _session: HagglingSession
var _rng := RandomNumberGenerator.new()
var _built: bool = false

var _price_label: Label
var _odds_label: Label
var _accept_button: Button
var _push_button: Button
var _walk_button: Button
var _result_label: Label

func _ready() -> void:
	_ensure_built()

## Yeni bir pazarlık açar. Panel sahneye girmeden de çağrılabilir.
## `scarcity` yalnızca pazarda verilir: yolda (haydut, haraç) kıtlığın
## vicdanla ilgisi yok.
func start_haggling(
	base_price: float,
	merchant_greed: float,
	reputation: float,
	player_charisma: float,
	scarcity: float = 0.0,
	seed_value: int = 0
) -> void:
	_ensure_built()
	_rng.seed = seed_value if seed_value != 0 else hash("haggle|%f|%f" % [base_price, reputation])
	_session = HagglingSession.new(
		base_price, merchant_greed, reputation, player_charisma, scarcity
	)
	_session.state_changed.connect(_on_state_changed)
	_result_label.text = ""
	_refresh()
	# Kendi perdesi yok - salt gövde. Ağaca eklenmeden çağrılabildiği için
	# `present` ağaçta değilse sessizce no-op kalır.
	WaybookTheme.present(self, null, self)

func _ensure_built() -> void:
	if _built:
		return
	_built = true
	add_theme_constant_override("separation", 8)

	_price_label = Label.new()
	_price_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_price_label)

	_odds_label = Label.new()
	_odds_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_odds_label.modulate = ArtPalette.UI_TEXT_DIM
	add_child(_odds_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_accept_button = Button.new()
	_accept_button.pressed.connect(_on_accept_pressed)
	_push_button = Button.new()
	_push_button.pressed.connect(_on_push_pressed)
	_walk_button = Button.new()
	_walk_button.text = tr("UI_HAGGLE_WALK")
	_walk_button.pressed.connect(_on_walk_pressed)
	row.add_child(_accept_button)
	row.add_child(_push_button)
	row.add_child(_walk_button)
	add_child(row)

	_result_label = Label.new()
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_result_label)

func _refresh() -> void:
	if _session == null:
		return
	_price_label.text = tr("UI_HAGGLE_PRICE") % int(round(_session.current_price()))
	_accept_button.text = tr("UI_HAGGLE_ACCEPT")
	# Üstelemenin yazısı kıtlıkta değişiyor: konusu fiyat değil, karşındaki
	# insan (P2).
	_push_button.text = tr("UI_HAGGLE_INSIST" if _session.is_conscience() else "UI_HAGGLE_PUSH")
	_push_button.visible = _session.can_push()
	if _session.can_push():
		_odds_label.text = tr("UI_HAGGLE_ODDS") % [
			int(round(_session.push_odds() * 100.0)),
			int(round(_session.push_price())),
			int(round(_session.raised_price())),
		]
		if _session.is_conscience():
			_odds_label.text += "\n" + tr("UI_HAGGLE_CONSCIENCE")
	else:
		_odds_label.text = ""
	# Boş etiket bir satırlık boşluk bırakıyordu (ekran görüntüsünde
	# yakalandı): direniş çözülünce fiyatla düğmeler yan yana kalsın.
	_odds_label.visible = not _odds_label.text.is_empty()

func _on_push_pressed() -> void:
	if _session == null or not _session.can_push():
		return
	var won := _session.push(_rng)
	_result_label.text = tr("UI_HAGGLE_PUSH_WON" if won else "UI_HAGGLE_PUSH_LOST")
	if won and _session.is_conscience():
		_result_label.text += "\n" + tr("UI_HAGGLE_CONSCIENCE_DONE")
	# Kaybedince hem fiyat artıyor hem itibar düşüyor: direnmek bedava bir
	# kura olmamalı. Kazanıp da kıtlıkta üstelediysen bedel bölgede.
	push_resolved.emit(
		won,
		0 if won else _session.get_push_reputation_penalty(),
		_session.conscience_standing_cost() if won else 0
	)
	_refresh()

func _on_accept_pressed() -> void:
	if _session != null:
		_session.accept()

func _on_walk_pressed() -> void:
	if _session != null:
		_session.walk_away()

func _on_state_changed(new_state: HagglingSession.State) -> void:
	_accept_button.disabled = true
	_push_button.visible = false
	_walk_button.disabled = true
	match new_state:
		HagglingSession.State.SUCCESS_DEAL:
			var price := int(round(_session.final_price))
			_result_label.text = tr("UI_HAGGLE_DEAL") % price
			deal_made.emit(price)
		HagglingSession.State.ANGER_QUIT:
			_result_label.text = tr("UI_HAGGLE_WALKOUT")
			haggling_failed.emit(_session.get_walkout_reputation_penalty())
