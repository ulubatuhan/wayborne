class_name RoadAttention
extends RefCounted

## Yolun karar katmanı: **nerede durduğun, neye dikkat ettiğindir.**
##
## Yol uzun süre şu şekilde çalışıyordu: tuşu basılı tut, saat işlesin,
## günde bir kez bir kart açılsın. Yürümek karar değildi - tek girdi
## "ilerliyor musun" idi ve cevabı her zaman evetti. Kervan lideri zaten
## kolondan ayrılıp ileri geri yürüyebiliyordu (`RoadCaravan.
## set_leader_offset`), ama bu tamamen kozmetikti.
##
## Artık mekanik. Kolonun üç bölgesi var ve lider aynı anda yalnızca
## birinde olabiliyor:
##
## | bölge    | gördüğün                        | göremediğin        |
## |----------|---------------------------------|--------------------|
## | ÖN       | yaklaşan karşılaşma, erken      | vagonlar ve kuyruk |
## | VAGONLAR | kırılmak üzere olan aks, kayan yük | ön ve kuyruk    |
## | ARKA     | geride kalan, dağılan tayfa     | ön ve vagonlar     |
##
## Frostpunk'ın "tek kadran" fikri kervan hâline getirilmiş: dikkat
## sonlu, nereye koyduğun bütün oyunun kararı. APM istemiyor - lider
## yürürken oyuncu zaten o tuşları kullanıyor.
##
## Bu sınıf **UI'sız**: ekran yalnızca liderin kolondaki oranını veriyor,
## karşılığında bölgeyi ve o bölgenin sayılarını alıyor. Testler bunu
## doğrudan örnekleyebiliyor (bkz. CLAUDE.md Testing - "UI-free cores").

const ZONE_FRONT: String = "front"
const ZONE_WAGONS: String = "wagons"
const ZONE_REAR: String = "rear"

## Bölge adı -> çeviri anahtarı. Tam yazılıyor, çalışma anında
## birleştirilmiyor (bkz. Localization Rules).
const ZONE_LABEL_KEYS: Dictionary = {
	ZONE_FRONT: "UI_ROAD_ZONE_FRONT",
	ZONE_WAGONS: "UI_ROAD_ZONE_WAGONS",
	ZONE_REAR: "UI_ROAD_ZONE_REAR",
}

## Kolonun neresi hangi bölge. Lider kolondan ayrılmadığında (offset 0)
## kolonun **başındadır**, yani ön bölgede - kervanı çeken kişi zaten
## öndedir. Geriye yürüdükçe sırayla vagonlara ve kuyruğa geçer.
const FRONT_UNTIL_RATIO: float = 0.25
const WAGONS_UNTIL_RATIO: float = 0.70

## Dikkatin ödülleri. Hepsi zaten var olan sistemlere bağlanıyor, yeni
## bir sistem icat edilmiyor (kültür perklerinin kuralıyla aynı).
##
## ÖN: karşılaşmayı bu kadar gün önce görürsün. Erken görmek kaçınma
## seçeneğini açan şey - savaşın sıklaşmasının dengesi bu, yoksa
## sıklaştırılmış savaş bir vergi olurdu.
const FRONT_SPOT_BONUS_DAYS: float = 0.55

## VAGONLAR: yol vagonu bu oranda daha yavaş yıpratır.
const WAGONS_WEAR_MULTIPLIER: float = 0.45

## ARKA: kuyrukla ilgilenmek günlük stres birikimini bu kadar keser.
const REAR_STRESS_RELIEF_PER_DAY: int = 1

static func get_zone_label(zone: String) -> String:
	if not ZONE_LABEL_KEYS.has(zone):
		return zone
	return String(TranslationServer.translate(String(ZONE_LABEL_KEYS[zone])))

## `offset_ratio`: liderin kolondaki yeri, 0 = en ön, 1 = en arka.
## Ekran bunu `-leader_offset / column_length` olarak veriyor.
static func zone_for(offset_ratio: float) -> String:
	var ratio := clampf(offset_ratio, 0.0, 1.0)
	if ratio < FRONT_UNTIL_RATIO:
		return ZONE_FRONT
	if ratio < WAGONS_UNTIL_RATIO:
		return ZONE_WAGONS
	return ZONE_REAR

## Karşılaşmayı kaç gün önceden görürsün. Yalnızca öndeyken; başka bir
## yerdeyken sıfır, yani işaret normal mesafede belirir.
static func spot_bonus_days(zone: String) -> float:
	return FRONT_SPOT_BONUS_DAYS if zone == ZONE_FRONT else 0.0

## Vagon aşınması çarpanı - 1.0 nötr.
static func wagon_wear_multiplier(zone: String) -> float:
	return WAGONS_WEAR_MULTIPLIER if zone == ZONE_WAGONS else 1.0

## Günlük stres birikiminden düşülen miktar.
static func stress_relief_per_day(zone: String) -> int:
	return REAR_STRESS_RELIEF_PER_DAY if zone == ZONE_REAR else 0
