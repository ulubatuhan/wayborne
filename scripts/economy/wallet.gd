class_name Wallet
extends RefCounted

signal balance_changed(new_balance: int)

var balance: int = 0

func _init(starting_balance: int = 0) -> void:
	balance = starting_balance

func can_afford(amount: int) -> bool:
	return balance >= amount

func spend(amount: int) -> bool:
	if not can_afford(amount):
		return false
	balance -= amount
	balance_changed.emit(balance)
	return true

func earn(amount: int) -> void:
	balance += amount
	balance_changed.emit(balance)
