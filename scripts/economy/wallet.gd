class_name Wallet
extends RefCounted

signal balance_changed(new_balance: int)

var balance: int = 0

func _init(starting_balance: int = 0) -> void:
	balance = starting_balance

func can_afford(amount: int) -> bool:
	return balance >= amount

## İsteğe bağlı alışverişin kapısı: parası yoksa satın alma gerçekleşmez.
## Vagon almak, tayfa tutmak, mal almak bu yoldan geçer - oyuncu kendi
## isteğiyle borca batmaz.
func spend(amount: int) -> bool:
	if not can_afford(amount):
		return false
	balance -= amount
	balance_changed.emit(balance)
	return true

## Ödemek zorunda olunan şeyin yolu: haraç, ceza, borç faizi, gümrük.
## Kese eksiye düşebilir - kervan yok olmaz ama borca batabilir (bkz.
## CLAUDE.md Caravan Ruin Rules). Kesenin ne kadar eksiye düştüğünü döner;
## GameSession bunu açık hesap borcuna çevirir.
func force_spend(amount: int) -> int:
	if amount <= 0:
		return 0
	var before := balance
	balance -= amount
	balance_changed.emit(balance)
	if before >= 0:
		return maxi(0, -balance)
	return amount

func is_in_debt() -> bool:
	return balance < 0

func earn(amount: int) -> void:
	balance += amount
	balance_changed.emit(balance)
