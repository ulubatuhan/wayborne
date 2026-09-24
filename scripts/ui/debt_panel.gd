class_name DebtPanel
extends PanelContainer

## Borç defteri arayüzü. `DebtLedger` Faz 9 A'da yazıldı ama hiçbir ekrana
## bağlanmamıştı: kervan borca batabiliyor, faiz işliyor, vadesi geçince
## itibar yiyordu ve oyuncu bunların hiçbirini göremiyordu. Görünmeyen bir
## ceza oyuncu için hatadan ayırt edilemez.
##
## `PurificationPanel`/`HagglingPanel` deseni: sahnesiz, `.new()` ile
## kurulur, kendini koda göre inşa eder. Tüccar Loncası'na gömülü - alacaklı
## da kontrat da aynı defterde durur.
##
## Üç eylem var, üçü de kuralları `GameSession`/`DebtLedger`'dan okur:
##   - **Borç al**: yola çıkmadan mal alabilmek için (bkz. GameSession.
##     borrow_from_guild). Kredi hattı itibara bağlı ve *bütün* borçlar onu
##     tüketir; tahsis ücreti anaparaya biner.
##   - **Öde**: kesedeki para kadarı ödenir (bkz. GameSession.repay_debt).
##     Kısmi ödeme serbest; kapanan borç defterden düşer.
##   - **Yapılandır**: vade uzar, bedel anaparaya biner ve her seferinde
##     artar (bkz. Debt.get_restructure_fee). Para gerektirmez - anlamı
##     zaten "şimdi ödeyemiyorum".
##
## Panel kendi zemini çizmiyor artık - `guild.tscn`'in tüm ekranı kaplayan
## masa/defter arka planı (`BackgroundArt`) zaten "resmî senet" hissini
## veriyor, bir de panelin kendi dokusu üstüne binerse iki ayrı deri yüzeyi
## çakışırdı. Mühür ikonu tek başına kalan görsel imza - CLAUDE.md'nin borç
## senetlerini "soğuk balmumu mühürlerle bezenmiş" tarif ettiği yer.

signal ledger_changed

## `load()`, not `preload()` - a brand-new binary asset has no `.import`
## metadata on a fresh checkout yet (`.import` files are gitignored, CI
## regenerates them), and `preload()` resolves at parse time, before that
## metadata exists. That raced CI's single `--headless --import` pass:
## "Parse Error: ... has no resource loaders" on the very first import of
## this exact file. `load()` defers to `_ensure_built()`, which runs after
## import has settled.
## Borç bir mühürle bağlı bir senet: vadesi geçince mühür çatlıyor (G9 ->
## G9b). Başlıktaki mühür defterin bütününü, satırdaki mühür o borcu
## söylüyor; ikisi de `_severity_color`'ın tonunu alıyor.
const SEAL_INTACT_FILE: String = "g9_seal.png"
const SEAL_CRACKED_FILE: String = "g9b_seal_cracked.png"
const ROW_SEAL_SIZE: float = 30.0
const SEAL_SIZE: float = 56.0

const OVERDUE_COLOR: Color = Color(0.9, 0.45, 0.35)
const DUE_SOON_COLOR: Color = Color(0.9, 0.8, 0.4)
const SETTLED_COLOR: Color = Color(0.45, 0.8, 0.45)

## Bu kadar gün kalınca satır sarıya dönmeye **başlar** - tam eşikte değil,
## `_severity_color` bu sınırdan sıfıra doğru yumuşakça koyulaşıyor. Sabit
## bir eşik "yaklaşıyor" ile "yakın" arasında tek bir kareydi; oysa bir
## borcun baskısı gün gün büyür, o yüzden renk de gün gün büyümeli - aynı
## `PulseBar`ın "değişimi göster" mantığı, burada zamana yayılmış hâli.
const DUE_SOON_DAYS: int = 7

## Vadeyi bu kadar gün geçince satır tam `OVERDUE_SEVERE_COLOR`'a varır -
## sabit değil, `Debt.OVERDUE_PERIOD_DAYS` (ilk gecikme faizinin bindiği
## gün) ile aynı: renk gerçekten daha kötüye gittiği anda en koyusuna
## ulaşıyor, keyfi bir sayıda değil.
const OVERDUE_SEVERE_COLOR: Color = Color(0.72, 0.14, 0.12)
const OVERDUE_SEVERE_DAYS: int = Debt.OVERDUE_PERIOD_DAYS

var _session: GameSession
var _body: VBoxContainer
var _title_label: Label
var _purse_label: Label
var _summary_label: Label
var _rows: VBoxContainer
var _credit_label: Label
var _amount_spin: SpinBox
var _borrow_button: Button
var _refreshing_amount: bool = false

var _header_seal: TextureRect

func setup(session: GameSession) -> void:
	_session = session
	_ensure_built()
	refresh()

func _ensure_built() -> void:
	if _title_label != null:
		return

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 6)
	add_child(_body)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	_body.add_child(header)

	_title_label = Label.new()
	_title_label.text = tr("UI_DEBT_TITLE")
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.modulate = ArtPalette.GOLD
	header.add_child(_title_label)

	# Mühür yalnızca süs değil - "bu defter resmî" diyen tek görsel imza,
	# aynı balmumu mühür imparatorluk kontratlarının hikâye metninde zaten
	# tarif edildiği yer.
	_header_seal = WaybookTheme.picture(SEAL_INTACT_FILE, SEAL_SIZE)
	header.add_child(_header_seal)

	# Borç kararı (öde/yapılandır/borç al) kesedeki parayı bilmeden
	# verilemez - önceden bu ekranda hiç görünmüyordu, oyuncu miktarı
	# akılda tutmak ya da lonca sekmesinden çıkıp kontrol etmek zorunda
	# kalıyordu.
	_purse_label = Label.new()
	_body.add_child(_purse_label)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_body.add_child(_summary_label)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 4)
	_body.add_child(_rows)

	_build_borrow_row()

## Kredi hattı defterin *üstünde* durur: borcun ne kadarının hâlâ
## alınabilir olduğu, borcun kendisiyle aynı ekranda okunmazsa oyuncu
## hattın borçla tükendiğini fark edemez.
func _build_borrow_row() -> void:
	_body.add_child(HSeparator.new())

	_credit_label = Label.new()
	_credit_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_body.add_child(_credit_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_body.add_child(row)

	_amount_spin = SpinBox.new()
	_amount_spin.min_value = GameSession.LOAN_MIN_AMOUNT
	_amount_spin.step = GameSession.LOAN_STEP
	_amount_spin.value = GameSession.LOAN_MIN_AMOUNT
	_amount_spin.custom_minimum_size = Vector2(110, 0)
	_amount_spin.value_changed.connect(_on_amount_changed)
	row.add_child(_amount_spin)

	_borrow_button = Button.new()
	_borrow_button.pressed.connect(_on_borrow_pressed)
	row.add_child(_borrow_button)

func refresh() -> void:
	if _session == null:
		return
	_ensure_built()
	_purse_label.text = tr("UI_PURSE") % _session.wallet.balance

	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()

	_refresh_borrow_row()

	var any_overdue := not _session.debts.get_overdue_debts(_session.total_days_elapsed).is_empty()
	_header_seal.texture = WaybookTheme.texture(SEAL_CRACKED_FILE if any_overdue else SEAL_INTACT_FILE)

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

func _refresh_borrow_row() -> void:
	# SpinBox.value'ya yazmak `value_changed` yayar, o da buraya döner;
	# bayrak olmadan kendi kendini çağıran bir tazeleme olurdu.
	if _refreshing_amount:
		return
	_refreshing_amount = true
	_do_refresh_borrow_row()
	_refreshing_amount = false

func _do_refresh_borrow_row() -> void:
	var available := _session.get_available_credit()
	_credit_label.text = tr("UI_GUILD_LOAN_LINE") % [
		available, _session.get_credit_limit(), _session.get_loan_fee_percent()
	]

	var reason := _session.get_loan_block_reason()
	if not reason.is_empty():
		# Kilitli seçenek sebebiyle birlikte gösterilir, gizlenmez.
		_amount_spin.editable = false
		_borrow_button.disabled = true
		_borrow_button.text = tr(reason)
		return

	_amount_spin.editable = true
	_amount_spin.max_value = available
	if _amount_spin.value > available:
		_amount_spin.value = available

	var amount := int(_amount_spin.value)
	_borrow_button.disabled = not _session.can_borrow(amount)
	_borrow_button.text = tr("UI_GUILD_LOAN_TAKE") % [
		amount, _session.get_loan_principal(amount), Debt.DEFAULT_TERM_DAYS
	]

func _on_amount_changed(_new_value: float) -> void:
	_refresh_borrow_row()

func _on_borrow_pressed() -> void:
	if not _session.borrow_from_guild(int(_amount_spin.value)):
		return
	refresh()
	ledger_changed.emit()

## Bir borç satırının rengi - vade yaklaştıkça sarıya, vade geçtikçe
## kırmızıdan koyu bir kızıla kayıyor. İki ayrı bant (yaklaşan/geçmiş)
## kendi içinde sürekli: satır tek bir karede sarıdan kırmızıya
## sıçramıyor, gün gün koyulaşıyor.
func _severity_color(days_left: int, overdue: bool) -> Color:
	if overdue:
		var overdue_days := -days_left
		var t := clampf(float(overdue_days) / float(OVERDUE_SEVERE_DAYS), 0.0, 1.0)
		return OVERDUE_COLOR.lerp(OVERDUE_SEVERE_COLOR, t)
	if days_left <= DUE_SOON_DAYS:
		var t := 1.0 - clampf(float(days_left) / float(DUE_SOON_DAYS), 0.0, 1.0)
		return Color.WHITE.lerp(DUE_SOON_COLOR, t)
	return Color.WHITE

func _build_row(debt: Debt) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var days_left := debt.get_days_remaining(_session.total_days_elapsed)
	var overdue := debt.is_overdue(_session.total_days_elapsed)

	var seal := WaybookTheme.picture(SEAL_CRACKED_FILE if overdue else SEAL_INTACT_FILE, ROW_SEAL_SIZE)
	seal.modulate = _severity_color(days_left, overdue)
	row.add_child(seal)

	var label := Label.new()
	# Alacaklı adı bir çeviri anahtarı (açık hesap) ya da düz bir isim
	# (tüccar) olabilir; anahtar çözülemezse kendisi basılır, bu da
	# okunabilir bir isimdir.
	var creditor := String(TranslationServer.translate(debt.creditor_name))
	if overdue:
		label.text = tr("UI_DEBT_ROW_OVERDUE") % [creditor, debt.principal, -days_left]
	else:
		label.text = tr("UI_DEBT_ROW") % [creditor, debt.principal, days_left]
	label.modulate = _severity_color(days_left, overdue)
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
