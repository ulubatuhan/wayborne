class_name DebtPanel
extends VBoxContainer

## Borç defteri arayüzü. `DebtLedger` Faz 9 A'da yazıldı ama hiçbir ekrana
## bağlanmamıştı: kervan borca batabiliyor, faiz işliyor, vadesi geçince
## itibar yiyordu ve oyuncu bunların hiçbirini göremiyordu. Görünmeyen bir
## ceza oyuncu için hatadan ayırt edilemez.
##
## `PurificationPanel`/`HagglingPanel` deseni: sahnesiz, `.new()` ile
## kurulur, kendini koda göre inşa eder. Tüccar Loncası'na gömülü - alacaklı
## da kontrat da aynı defterde durur.
##
## İki eylem var, ikisi de `DebtLedger`'ın kendi kurallarını çağırır:
##   - **Öde**: kesedeki para kadarı ödenir (bkz. GameSession.repay_debt).
##     Kısmi ödeme serbest; kapanan borç defterden düşer.
##   - **Yapılandır**: vade uzar, bedel anaparaya biner ve her seferinde
##     artar (bkz. Debt.get_restructure_fee). Para gerektirmez - anlamı
##     zaten "şimdi ödeyemiyorum".

signal ledger_changed

const OVERDUE_COLOR: Color = Color(0.9, 0.45, 0.35)
const DUE_SOON_COLOR: Color = Color(0.9, 0.8, 0.4)
const SETTLED_COLOR: Color = Color(0.45, 0.8, 0.45)

## Bu kadar gün kalınca satır sarıya döner - "yaklaşıyor" hissi.
const DUE_SOON_DAYS: int = 7

var _session: GameSession
var _title_label: Label
var _summary_label: Label
var _rows: VBoxContainer

func setup(session: GameSession) -> void:
	_session = session
	_ensure_built()
	refresh()

func _ensure_built() -> void:
	if _title_label != null:
		return
	add_theme_constant_override("separation", 6)

	_title_label = Label.new()
	_title_label.text = tr("UI_DEBT_TITLE")
	add_child(_title_label)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_summary_label)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 4)
	add_child(_rows)

func refresh() -> void:
	if _session == null:
		return
	_ensure_built()

	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()

	var total := _session.get_total_debt()
	if total <= 0:
		_summary_label.text = tr("UI_DEBT_NONE")
		_summary_label.modulate = SETTLED_COLOR
		return

	var soonest := _session.debts.get_soonest_due_in_days(_session.total_days_elapsed)
	_summary_label.modulate = Color.WHITE
	_summary_label.text = tr("UI_DEBT_SUMMARY") % [total, maxi(0, soonest)]

	for debt in _session.debts.get_debts():
		_rows.add_child(_build_row(debt))

func _build_row(debt: Debt) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var days_left := debt.get_days_remaining(_session.total_days_elapsed)
	var overdue := debt.is_overdue(_session.total_days_elapsed)

	var label := Label.new()
	# Alacaklı adı bir çeviri anahtarı (açık hesap) ya da düz bir isim
	# (tüccar) olabilir; anahtar çözülemezse kendisi basılır, bu da
	# okunabilir bir isimdir.
	var creditor := String(TranslationServer.translate(debt.creditor_name))
	if overdue:
		label.text = tr("UI_DEBT_ROW_OVERDUE") % [creditor, debt.principal, -days_left]
		label.modulate = OVERDUE_COLOR
	else:
		label.text = tr("UI_DEBT_ROW") % [creditor, debt.principal, days_left]
		if days_left <= DUE_SOON_DAYS:
			label.modulate = DUE_SOON_COLOR
	label.custom_minimum_size = Vector2(340, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	row.add_child(label)

	var payable := mini(debt.principal, maxi(0, _session.wallet.balance))
	var pay_button := Button.new()
	pay_button.text = tr("UI_DEBT_PAY") % payable
	pay_button.disabled = payable <= 0
	pay_button.pressed.connect(_on_pay_pressed.bind(debt.debt_id, payable))
	row.add_child(pay_button)

	var restructure_button := Button.new()
	restructure_button.text = tr("UI_DEBT_RESTRUCTURE") % debt.get_restructure_fee()
	restructure_button.tooltip_text = tr("UI_DEBT_RESTRUCTURE_TOOLTIP")
	restructure_button.pressed.connect(_on_restructure_pressed.bind(debt.debt_id))
	row.add_child(restructure_button)

	return row

func _on_pay_pressed(debt_id: String, amount: int) -> void:
	if _session.repay_debt(debt_id, amount) > 0:
		refresh()
		ledger_changed.emit()

func _on_restructure_pressed(debt_id: String) -> void:
	if _session.debts.restructure(debt_id, _session.total_days_elapsed):
		refresh()
		ledger_changed.emit()
