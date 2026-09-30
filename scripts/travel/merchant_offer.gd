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

## Faz 17 PR-4: loncanın kendi özel vagon görevleri - kontrat panosunun
## sıradan kabul/taşı/teslim akışını aynen kullanıyor (bkz. GameSession.
## accept_contract/depart_with_contracts/finish_journey) ama karşılığında
## altın yerine ayni bir ödül veriyor: "ek vagon almış oluruz kervana bir
## nevi ya da yük" (kullanıcının kendi tarifi - WorldEvents'in anında
## tamamlanan lonca görevleriyle çakışmıyor, ayrı bir MerchantOffer akışı).
## Varsayılan false/boş - mevcut hiçbir kontrat bu iki alanı doldurmuyor,
## yani eski davranış birebir korunuyor.
@export var grants_wagon_on_delivery: bool = false
@export var cargo_reward_item_id: String = ""
@export var cargo_reward_quantity: int = 0

## Bazı tüccarlar vagon yerine kendi eşekleriyle gelir - kervanın paylaşılan
## vagon havuzuna (bkz. CaravanPlan.max_wagons, Campaign Rules'un "buying
## wagons crowds out contracts" bulgusu) hiç dokunmazlar. Varsayılan 0 -
## mevcut hiçbir kontrat bunu doldurmuyor, yani eski davranış birebir
## korunuyor. `wagon_count` bu tür bir teklifte kasıtlı olarak 0: hem
## `CaravanPlan.get_used_wagon_count()`'un yeni bir dal gerektirmeden
## doğru sonucu vermesini sağlıyor hem de "bir vagonu yok" gerçeğinin
## kendisi.
@export var donkey_count: int = 0

func uses_donkey_escort() -> bool:
	return donkey_count > 0
