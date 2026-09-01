class_name MerchantOffer
extends Resource

@export var merchant_id: String = ""
@export var merchant_name: String = ""
@export var origin_location_id: String = ""
@export var destination_location_id: String = ""
@export var potential_profit: int = 0
@export var wagon_count: int = 1

## Tüccar Loncası'nda kabul edildikten kaç gün sonra kontrat süresi
## dolar (bkz. GameSession.advance_day). Kabul edilmeden bu alan
## anlamsızdır.
@export var contract_deadline_days: int = 15
## Bu kontratı kabul edebilmek için gereken itibar (bkz. GameSession.
## reputation). Daha kârlı/büyük kontratlar daha yüksek itibar ister.
@export var required_reputation: int = 0
