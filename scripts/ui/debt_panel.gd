class_name DebtPanel
extends VBoxContainer

## Borcun **defter satırları**: kime · ne kadar · ne zamana kadar (P12,
## kullanıcı kararı 2026-11-05).
##
## Eskiden 327 satırlık bir ekrandı: kredi hattı göstergesi, tutar
## kaydıracı, iki göstergeli önizleme, borç alma düğmesi, yapılandırma
## düğmesi. Üçü birden gitti:
##   - **Faiz ve yapılandırma** P10'da kaldırıldı; borç büyümüyor.
##   - **Nakit kredi** P13'te kaldırıldı; lonca artık mal avansı veriyor
##     (`GameSession.take_goods_advance`) - para değil yük, ve o yükü
##     taşımak zorundasın.
##   - **Yoldaki "Borç" emri** P12'de kaldırıldı: yolda borçla uğraşmak
##     muhasebe kipinin ta kendisi.
##
## Kalan: satırlar ve tek bir **Öde** düğmesi. Dördüncü sütun -
## *Defter unutmaz.*
##
## Panel kendi zemini çizmiyor - `guild.tscn`'in masa/defter arka planı
## (`BackgroundArt`) zaten "resmî senet" hissini veriyor. Mühür ikonu tek
## başına kalan görsel imza: CLAUDE.md'nin borç senetlerini "soğuk balmumu
## mühürlerle bezenmiş" tarif ettiği yer.
##
## `load()`, not `preload()` - a brand-new binary asset has no `.import`
## metadata on a fresh checkout yet (`.import` files are gitignored, CI
## regenerates them), and `preload()` resolves at parse time, before that
## metadata exists.

## Borç bir mühürle bağlı bir senet: vadesi geçince mühür çatlıyor.
const SEAL_INTACT_FILE: String = "g9_seal.png"
const SEAL_CRACKED_FILE: String = "g9b_seal_cracked.png"
const ROW_SEAL_SIZE: float = 30.0

## Planlayıcının uyarı turuncusuyla aynı rol - ArtPalette.UI_WARNING.
const OVERDUE_COLOR: Color = ArtPalette.UI_WARNING
const DUE_SOON_COLOR: Color = Color(0.9, 0.8, 0.4)

## Bu kadar gün kalınca satır sarıya dönmeye **başlar** - tam eşikte değil,
## `_severity_color` bu sınırdan sıfıra doğru yumuşakça koyulaşıyor. Bir
## borcun baskısı gün gün büyür, o yüzden renk de gün gün büyümeli.
const DUE_SOON_DAYS: int = 7

## Vadeyi bu kadar gün geçince satır tam `OVERDUE_SEVERE_COLOR`'a varır -
## keyfi değil, `Debt.OVERDUE_PERIOD_DAYS` ile aynı: itibarın ilk kez
## kesildiği gün.
const OVERDUE_SEVERE_COLOR: Color = Color(0.72, 0.14, 0.12)
const OVERDUE_SEVERE_DAYS: int = Debt.OVERDUE_PERIOD_DAYS

signal ledger_changed

var _session: GameSession
var _summary_label: Label
var _rows: VBoxContainer
var _built: bool = false

func setup(session: GameSession) -> void:
	_session = session
	_ensure_built()
	refresh()

func _ensure_built() -> void:
	if _built:
		return
	_built = true
	add_theme_constant_override("separation", 6)
	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_summary_label)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 4)
	add_child(_rows)

func refresh() -> void:
	if _session == null or not _built:
		return
	NodeUtil.clear_children(_rows)
	var debts := _session.debts.get_debts()
	# İkinci sayı **en yakın vade**, kese değil. Bir tur kese bakiyesi
	# yazıldı ve ekranda "En yakın vade: 850 gün" olarak göründü - yalnız
	# ekran görüntüsü yakaladı, çünkü iki sayı da geçerli birer tamsayı.
	if debts.is_empty():
		_summary_label.text = tr("UI_DEBT_NONE")
	else:
		var soonest := _session.debts.get_soonest_due_in_days(_session.total_days_elapsed)
		# Eksi gün sayısı "-12 gün" diye okunuyordu (ekran görüntüsü);
		# gecikme kendi cümlesini kurmalı.
		_summary_label.text = tr(
			"UI_DEBT_SUMMARY_OVERDUE" if soonest < 0 else "UI_DEBT_SUMMARY"
		) % [_session.get_total_debt(), absi(soonest)]
	for debt in debts:
		_rows.add_child(_build_row(debt))

## Bir borç satırının rengi - vade yaklaştıkça sarıya, vade geçtikçe
## kırmızıdan koyu bir kızıla kayıyor. İki ayrı bant kendi içinde sürekli:
## satır tek bir karede sıçramıyor, gün gün koyulaşıyor.
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
	var tone := _severity_color(days_left, overdue)

	var seal := WaybookTheme.picture(SEAL_CRACKED_FILE if overdue else SEAL_INTACT_FILE, ROW_SEAL_SIZE)
	seal.modulate = tone
	row.add_child(seal)

	var label := Label.new()
	# Alacaklı adı ya bir çeviri anahtarı (lonca, açık hesap) ya da adı olan
	# bir kişinin adı (P11); anahtar çözülemezse kendisi basılır, bu da
	# okunabilir bir isimdir - ve bir yüz bir yüzdeden korkutucudur.
	var creditor := String(TranslationServer.translate(debt.creditor_name))
	if debt.is_delivery():
		var item := ItemCatalog.get_item(debt.delivery_item_id)
		var goods := item.item_name if item != null else debt.delivery_item_id
		label.text = tr("UI_DEBT_ROW_DELIVERY") % [
			creditor, debt.delivery_quantity, tr(goods), debt.principal, days_left
		]
	elif overdue:
		label.text = tr("UI_DEBT_ROW_OVERDUE") % [creditor, debt.principal, -days_left]
	else:
		label.text = tr("UI_DEBT_ROW") % [creditor, debt.principal, days_left]
	# Yazının rengi doğrudan, `.modulate` üstünden değil - font_color'ı
	# ikinci kez çarpmasın diye.
	label.add_theme_color_override("font_color", tone)
	label.custom_minimum_size = Vector2(380, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var payable := mini(debt.principal, maxi(0, _session.wallet.balance))
	var pay_button := Button.new()
	pay_button.text = tr("UI_DEBT_PAY") % payable
	pay_button.disabled = payable <= 0
	pay_button.pressed.connect(_on_pay_pressed.bind(debt.debt_id, payable))
	row.add_child(pay_button)

	return row

func _on_pay_pressed(debt_id: String, amount: int) -> void:
	if _session.repay_debt(debt_id, amount) > 0:
		refresh()
		ledger_changed.emit()
