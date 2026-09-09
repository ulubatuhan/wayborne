class_name Debt
extends RefCounted

## Kervanın bir alacaklıya olan borcu. Oyunun "kervan yok olmaz ama sürünür"
## kuralının parasal ayağı: kese eksiye düşebilir, kervan borca batabilir ve
## bu borcu bir ay içinde ödemek ya da yapılandırmak zorundadır.
##
## Sahne ağacına bağlı değil, RefCounted (bkz. CharacterData deseni) -
## doğrudan örneklenip test edilebilir, to_dict/from_dict ile kaydedilir.

## Borcun nereden geldiği - alacaklının baskı biçimi buna göre değişir.
const SOURCE_OVERDRAFT: String = "overdraft"
const SOURCE_LOAN: String = "loan"
const SOURCE_PENALTY: String = "penalty"

## Vade: "bir ay içinde ödemeli".
const DEFAULT_TERM_DAYS: int = 30

## Vadesi geçince her gecikme döneminde anaparaya eklenen faiz oranı ve
## dönem uzunluğu. Gecikme cezasız kalmamalı ama borç da kartopu gibi
## büyüyüp oyunu kilitlememeli - bu yüzden oran ılımlı.
const OVERDUE_PERIOD_DAYS: int = 10
const OVERDUE_INTEREST_RATE: float = 0.15
const OVERDUE_REPUTATION_PENALTY: int = 3

## Yapılandırma: vade uzar ama anapara bir miktar şişer. Her yapılandırmada
## bedel artar - sonsuza kadar erteleyip borçtan kaçmak mümkün olmamalı.
const RESTRUCTURE_TERM_DAYS: int = 20
const RESTRUCTURE_FEE_RATE: float = 0.12
const RESTRUCTURE_FEE_GROWTH: float = 0.06

var debt_id: String = ""
var creditor_name: String = ""
var source: String = SOURCE_LOAN

## Kalan anapara. Faiz buna işlenir, ayrı bir alan tutulmaz - oyuncunun
## gördüğü tek sayı "ne kadar borçluyum" olsun.
var principal: int = 0

## GameSession.total_days_elapsed cinsinden son ödeme günü.
var due_day: int = 0

## Kaç kez yapılandırıldı - her seferinde bedel artar (bkz. get_restructure_fee).
var restructure_count: int = 0

## Vadesi geçtikten sonra kaç gecikme dönemi işletildiği; aynı dönem iki kez
## faiz işlememesi için tutuluyor.
var overdue_periods_applied: int = 0

static func create(
	debt_id: String, creditor_name: String, principal: int, due_day: int,
	source: String = SOURCE_LOAN
) -> Debt:
	var debt := Debt.new()
	debt.debt_id = debt_id
	debt.creditor_name = creditor_name
	debt.principal = maxi(0, principal)
	debt.due_day = due_day
	debt.source = source
	return debt

func is_settled() -> bool:
	return principal <= 0

func is_overdue(current_day: int) -> bool:
	return not is_settled() and current_day > due_day

func get_days_remaining(current_day: int) -> int:
	return due_day - current_day

## Vadeyi kaç gecikme dönemi aştığı. Faiz bu sayı üzerinden işler.
func get_overdue_periods(current_day: int) -> int:
	if not is_overdue(current_day):
		return 0
	return int(floor(float(current_day - due_day) / float(OVERDUE_PERIOD_DAYS))) + 1

## Henüz işlenmemiş gecikme dönemlerinin faizini anaparaya ekler ve kaç
## dönem işlendiğini döner (itibar cezası çağıranın işi - bkz. DebtLedger).
func apply_overdue_interest(current_day: int) -> int:
	var periods := get_overdue_periods(current_day)
	var pending := periods - overdue_periods_applied
	if pending <= 0:
		return 0
	for _index in pending:
		principal += maxi(1, int(round(float(principal) * OVERDUE_INTEREST_RATE)))
	overdue_periods_applied = periods
	return pending

func get_restructure_fee() -> int:
	var rate := RESTRUCTURE_FEE_RATE + RESTRUCTURE_FEE_GROWTH * float(restructure_count)
	return maxi(1, int(round(float(principal) * rate)))

## Vadeyi uzatır, bedeli anaparaya ekler ve gecikme sayacını sıfırlar -
## yapılandırılan borç artık "gecikmiş" değil, yeni vadeli bir borçtur.
func restructure(current_day: int) -> void:
	principal += get_restructure_fee()
	due_day = current_day + RESTRUCTURE_TERM_DAYS
	restructure_count += 1
	overdue_periods_applied = 0

## Ödenen miktarı düşer, gerçekten ödenen tutarı döner (borçtan fazlası
## alınmaz).
func pay(amount: int) -> int:
	var paid := mini(maxi(0, amount), principal)
	principal -= paid
	return paid

func to_dict() -> Dictionary:
	return {
		"debt_id": debt_id,
		"creditor_name": creditor_name,
		"source": source,
		"principal": principal,
		"due_day": due_day,
		"restructure_count": restructure_count,
		"overdue_periods_applied": overdue_periods_applied,
	}

static func from_dict(data: Dictionary) -> Debt:
	var debt := Debt.new()
	debt.debt_id = str(data.get("debt_id", ""))
	debt.creditor_name = str(data.get("creditor_name", ""))
	debt.source = str(data.get("source", SOURCE_LOAN))
	debt.principal = maxi(0, int(data.get("principal", 0)))
	debt.due_day = int(data.get("due_day", 0))
	debt.restructure_count = maxi(0, int(data.get("restructure_count", 0)))
	debt.overdue_periods_applied = maxi(0, int(data.get("overdue_periods_applied", 0)))
	return debt
