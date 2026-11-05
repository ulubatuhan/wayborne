class_name Debt
extends RefCounted

## Kervanın bir alacaklıya olan borcu. Oyunun "kervan yok olmaz ama sürünür"
## kuralının parasal ayağı: kese eksiye düşebilir ve kervan borca batabilir.
##
## Sahne ağacına bağlı değil, RefCounted (bkz. CharacterData deseni) -
## doğrudan örneklenip test edilebilir, to_dict/from_dict ile kaydedilir.
##
## **FAİZ KALDIRILDI (P10, kullanıcı kararı 2026-11-05).** Oyunun kendi
## ölçümü faizi mahkûm etti: sert oranla borç kırkıncı seferde milyonlara
## çıkıp kariyeri kilitliyordu (`docs/design_notes/denge_baba_borcu.md`),
## yumuşatılınca **hiçbir şey yapmaz** oldu. Taşıyamadığı ağırlığın altında
## ezilen bir mekanikti. Yapılandırma (vade uzatma) da onunla gitti: faiz
## yokken "bedel ödeyip erteleme" diye bir şey kalmıyor.
##
## Kalan: anapara, vade, alacaklı, gecikti mi. **Borç büyümez; ya ödersin ya
## ödemezsin.** Gecikmenin bedeli aritmetik değil **sosyal**: her gecikme
## döneminde itibar düşer, alacaklının adamı yolda bulur, kampa mübaşir
## gelir (var olan kartlar).
##
## **VE BORCUN BİR ADI VAR (P11).** `creditor_person_id` boş değilse alacaklı
## genel bir etiket değil, `People`'ın tanıdığı **bir kişi**dir: adı, şehri,
## hatırladığı şey. Ortaçağ ticari kredisi bir faiz tablosu değil güven ve
## itibardı; ve dramatik olarak **bir yüz, bir yüzdeden korkutucudur.**
##
## Karşılığı da para olmak zorunda değil: `delivery_item_id` doluysa borç bir
## **teslimat**tır - *"şu tahılı Drazvor'a götür"*. Böylece borç kervanın
## varlık sebebine döner.

## Borcun nereden geldiği - alacaklının baskı biçimi buna göre değişir.
const SOURCE_OVERDRAFT: String = "overdraft"
const SOURCE_LOAN: String = "loan"
## Mal avansı (P13): lonca para değil **yük** verir, karşılığında teslimat
## ister. Kaçış kapağı olan nakit kredinin yerini alıyor.
const SOURCE_ADVANCE: String = "advance"

## Vade: "bir ay içinde ödemeli".
const DEFAULT_TERM_DAYS: int = 30

## Gecikme dönemi ve dönem başına itibar bedeli. Faiz gitti, bu kaldı:
## gecikme cezasız olmamalı ama bedeli borcun kendisi değil **adın**.
const OVERDUE_PERIOD_DAYS: int = 10
const OVERDUE_REPUTATION_PENALTY: int = 3

var debt_id: String = ""
var creditor_name: String = ""
var source: String = SOURCE_LOAN

## Alacaklı bir kişiyse `People`'daki kimliği (P11). Boşsa alacaklı bir
## kurumdur (lonca, açık hesap) ve `creditor_name` çeviri anahtarıdır.
var creditor_person_id: String = ""
## Alacaklının şehri: vade geçerse pazarı sana kapanan yer burası.
var creditor_city_id: String = ""

## Borcun karşılığı mal ise (P11, P13): malın kimliği, adedi ve nereye
## götürüleceği. Boşsa borç para borcudur.
var delivery_item_id: String = ""
var delivery_quantity: int = 0
var delivery_city_id: String = ""

## Kalan anapara. Artık büyümüyor - yalnızca ödeme küçültür.
var principal: int = 0

## GameSession.total_days_elapsed cinsinden son ödeme günü.
var due_day: int = 0

## İtibar bedeli kaç gecikme dönemi için kesildi; aynı dönem iki kez
## kesilmesin diye tutuluyor.
var overdue_periods_charged: int = 0

## Dönem başına itibar cezası. Varsayılan loncaya olan borcun sertliği;
## aile borcu (babadan kalan, Y-C14) yumuşak: alacaklı akraba, adını
## sokakta çürütmez.
var reputation_penalty: int = OVERDUE_REPUTATION_PENALTY

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

## Borcu bir yüze bağlar (P11). `city_id` vade geçerse pazarı kapanan yer.
func bind_to_person(person_id: String, city_id: String) -> void:
	creditor_person_id = person_id
	creditor_city_id = city_id

## Borcun karşılığını mala çevirir (P11, P13): para değil yük.
func set_delivery(item_id: String, quantity: int, city_id: String) -> void:
	delivery_item_id = item_id
	delivery_quantity = maxi(0, quantity)
	delivery_city_id = city_id

func is_delivery() -> bool:
	return not delivery_item_id.is_empty() and delivery_quantity > 0

func has_face() -> bool:
	return not creditor_person_id.is_empty()

func is_settled() -> bool:
	return principal <= 0 and not is_delivery()

func is_overdue(current_day: int) -> bool:
	return not is_settled() and current_day > due_day

func get_days_remaining(current_day: int) -> int:
	return due_day - current_day

## Vadeyi kaç gecikme dönemi aştığı. İtibar bedeli bu sayı üzerinden kesilir.
func get_overdue_periods(current_day: int) -> int:
	if not is_overdue(current_day):
		return 0
	return int(floor(float(current_day - due_day) / float(OVERDUE_PERIOD_DAYS))) + 1

## Henüz kesilmemiş gecikme dönemlerinin sayısını döner ve işaretler.
## İtibarı düşürmek çağıranın işi (bkz. DebtLedger) - borç oturumun geri
## kalanını tanımıyor.
func claim_overdue_periods(current_day: int) -> int:
	var periods := get_overdue_periods(current_day)
	var pending := periods - overdue_periods_charged
	if pending <= 0:
		return 0
	overdue_periods_charged = periods
	return pending

## Ödenen miktarı düşer, gerçekten ödenen tutarı döner (borçtan fazlası
## alınmaz).
func pay(amount: int) -> int:
	var paid := mini(maxi(0, amount), principal)
	principal -= paid
	return paid

## Teslimat yapıldı: yük düşer. Dönen, gerçekten sayılan adet.
func deliver(quantity: int) -> int:
	var given := mini(maxi(0, quantity), delivery_quantity)
	delivery_quantity -= given
	if delivery_quantity <= 0:
		delivery_item_id = ""
		delivery_city_id = ""
	return given

func to_dict() -> Dictionary:
	return {
		"debt_id": debt_id,
		"creditor_name": creditor_name,
		"source": source,
		"creditor_person_id": creditor_person_id,
		"creditor_city_id": creditor_city_id,
		"delivery_item_id": delivery_item_id,
		"delivery_quantity": delivery_quantity,
		"delivery_city_id": delivery_city_id,
		"principal": principal,
		"due_day": due_day,
		"overdue_periods_charged": overdue_periods_charged,
		"reputation_penalty": reputation_penalty,
	}

static func from_dict(data: Dictionary) -> Debt:
	var debt := Debt.new()
	debt.debt_id = str(data.get("debt_id", ""))
	debt.creditor_name = str(data.get("creditor_name", ""))
	debt.source = str(data.get("source", SOURCE_LOAN))
	debt.creditor_person_id = str(data.get("creditor_person_id", ""))
	debt.creditor_city_id = str(data.get("creditor_city_id", ""))
	debt.delivery_item_id = str(data.get("delivery_item_id", ""))
	debt.delivery_quantity = maxi(0, int(data.get("delivery_quantity", 0)))
	debt.delivery_city_id = str(data.get("delivery_city_id", ""))
	debt.principal = maxi(0, int(data.get("principal", 0)))
	debt.due_day = int(data.get("due_day", 0))
	# Eski kayıtlar alanı "overdue_periods_applied" adıyla tutuyordu (faizli
	# tasarım); sayı aynı anlamı taşıdığı için okunuyor.
	debt.overdue_periods_charged = maxi(0, int(data.get(
		"overdue_periods_charged", data.get("overdue_periods_applied", 0)
	)))
	debt.reputation_penalty = int(data.get("reputation_penalty", OVERDUE_REPUTATION_PENALTY))
	return debt
