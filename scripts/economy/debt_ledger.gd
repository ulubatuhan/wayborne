class_name DebtLedger
extends RefCounted

## Kervanın borç defteri: kime ne kadar borçlu, hangi vadeyle. Kese
## (Wallet) eksiye düştüğünde de burada bir "açık hesap" borcu doğar -
## oyuncunun gördüğü tek yer burası olsun diye.
##
## Gün ilerlemesi tek giriş noktasından işler (advance_to_day): vadesi
## geçen borçlara faiz bindirir ve kaç itibar kaybedildiğini döner. Bu
## çağrıyı GameSession.advance_day() yapar, başka kimse yapmamalı - yoksa
## aynı gecikme dönemi iki kez cezalandırılırdı.

## Kese eksiye düştüğünde açılan hesabın alacaklısı. Tek bir açık hesap
## tutulur; kese daha da eksiye giderse anapara büyür, yeni borç açılmaz.
const OVERDRAFT_DEBT_ID: String = "overdraft"
const OVERDRAFT_CREDITOR_KEY: String = "DEBT_CREDITOR_MONEYLENDER"

var debts: Array[Debt] = []

var _next_loan_index: int = 1

func get_debts() -> Array[Debt]:
	return debts

func get_debt(debt_id: String) -> Debt:
	for debt in debts:
		if debt.debt_id == debt_id:
			return debt
	return null

func has_debt() -> bool:
	return get_total_owed() > 0

func get_total_owed() -> int:
	var total := 0
	for debt in debts:
		total += debt.principal
	return total

func get_overdue_debts(current_day: int) -> Array[Debt]:
	var overdue: Array[Debt] = []
	for debt in debts:
		if debt.is_overdue(current_day):
			overdue.append(debt)
	return overdue

## En yakın vadeli borcun kaç gün kaldığı; borç yoksa -1.
func get_soonest_due_in_days(current_day: int) -> int:
	var soonest := -1
	for debt in debts:
		if debt.is_settled():
			continue
		var remaining := debt.get_days_remaining(current_day)
		if soonest < 0 or remaining < soonest:
			soonest = remaining
	return soonest

func add_debt(debt: Debt) -> void:
	if debt == null or debt.is_settled():
		return
	debts.append(debt)

## Yeni bir borç açar (tefeci, tüccar, ceza). debt_id verilmezse sıradan
## üretilir - aynı alacaklıdan iki kez borç alınabilsin diye.
func borrow(
	creditor_name: String, amount: int, current_day: int,
	source: String = Debt.SOURCE_LOAN, debt_id: String = ""
) -> Debt:
	if amount <= 0:
		return null
	var resolved_id := debt_id
	if resolved_id.is_empty():
		resolved_id = "loan_%d" % _next_loan_index
		_next_loan_index += 1
	var debt := Debt.create(
		resolved_id, creditor_name, amount, current_day + Debt.DEFAULT_TERM_DAYS, source
	)
	debts.append(debt)
	return debt

## Açık hesap, kesenin eksi bakiyesinin **aynası**dır - ayrı bir para değil.
## GameSession keseyi her değiştiğinde buraya senkronlar (bkz.
## _on_balance_changed), böylece ikisi asla ayrışmaz ve borç iki kez
## sayılmaz. Vade ilk eksiye düşüşte kurulur; sonra daha da batmak vadeyi
## ötelemez - sayaç ilk günden işliyor.
func sync_overdraft(amount: int, current_day: int) -> void:
	var existing := get_debt(OVERDRAFT_DEBT_ID)
	if amount <= 0:
		if existing != null:
			existing.principal = 0
			_prune_settled()
		return

	if existing == null:
		debts.append(Debt.create(
			OVERDRAFT_DEBT_ID, OVERDRAFT_CREDITOR_KEY, amount,
			current_day + Debt.DEFAULT_TERM_DAYS, Debt.SOURCE_OVERDRAFT
		))
		return
	existing.principal = amount

## Borca ödeme yapar; gerçekten ödenen tutarı döner. Kapanan borç defterden
## düşer - ödenmiş bir borcun listede durması oyuncuyu yanıltırdı.
func pay(debt_id: String, amount: int) -> int:
	var debt := get_debt(debt_id)
	if debt == null:
		return 0
	var paid := debt.pay(amount)
	_prune_settled()
	return paid

## Vadeyi uzatır. Bedeli anaparaya biner (bkz. Debt.restructure) - para
## gerektirmez, çünkü yapılandırmanın anlamı zaten "şimdi ödeyemiyorum".
func restructure(debt_id: String, current_day: int) -> bool:
	var debt := get_debt(debt_id)
	if debt == null or debt.is_settled():
		return false
	debt.restructure(current_day)
	return true

## Günlük işleyiş: vadesi geçen her borca işlenmemiş gecikme faizini bindirir.
## Toplam itibar cezasını döner (çağıran itibarı düşürür) - ceza burada
## uygulanmıyor çünkü DebtLedger oturumun geri kalanını tanımıyor.
func advance_to_day(current_day: int) -> int:
	var reputation_penalty := 0
	for debt in debts:
		var periods := debt.apply_overdue_interest(current_day)
		reputation_penalty += periods * Debt.OVERDUE_REPUTATION_PENALTY
	return reputation_penalty

func _prune_settled() -> void:
	var remaining: Array[Debt] = []
	for debt in debts:
		if not debt.is_settled():
			remaining.append(debt)
	debts = remaining

func to_save_array() -> Array:
	var data: Array = []
	for debt in debts:
		data.append(debt.to_dict())
	return data

func load_from_array(data: Array) -> void:
	debts.clear()
	var highest := 0
	for entry in data:
		var debt := Debt.from_dict(entry)
		if debt.is_settled():
			continue
		debts.append(debt)
		# Kayıttan dönen "loan_N" kimliklerinin üstüne yazmamak için sayacı
		# en büyüğün ötesine taşı.
		if debt.debt_id.begins_with("loan_"):
			highest = maxi(highest, debt.debt_id.trim_prefix("loan_").to_int())
	_next_loan_index = highest + 1
