class_name HagglingSession
extends RefCounted

## Tek kararlık pazarlık. UI'dan bağımsız: sahne ağacı gerektirmez, doğrudan
## örneklenip test edilebilir.
##
## TASARIMIN GEÇMİŞİ, çünkü üç kez yeniden yazıldı:
##
## 1. İLK TASARIM: kabul eşiği sabırla birlikte tabana iniyordu ve sabrı en
##    hızlı yakan şey aşağılayıcı dip tekliflerdi. Tüccarı çileden çıkarmak
##    *ödüllendiriliyordu*.
## 2. İKİNCİ TASARIM: eşik tabanın altına inmiyordu, taban her reddedilen
##    teklifte sertleşiyordu. Sömürü kapanmıştı ama hem eşik hem taban
##    yalnızca **kaç tur geçtiğinin** fonksiyonuydu: nasıl pazarlık ettiğin
##    değil, kaç kez reddedildiğin önemliydi.
## 3. ÜÇÜNCÜ TASARIM (üç tur, kaydıraçlı teklif, ciddiyet eşiği, ültimatom):
##    sömürüsü yoktu ve iyi çalışıyordu - ama **yanlış kipteydi.** Üç turlu
##    bir teklif döngüsünün ölçülebilir bir "doğru cevabı" vardır; oyuncu
##    karşılaştırır, optimize eder, turları sürer. Kıtlığın doğru cevabı
##    yoktur (bkz. `kitlik_tasarim_dersleri.md`). Üstelik Codex'teki bölümün
##    başlığı tasarımı itiraf ediyordu: *"Pazarlık: oyunun para basma
##    noktası."* Kıtlık oyununda para basan bir nokta vardı.
##
## BU TASARIM (P1, kullanıcı kararı 2026-11-05): **tek karar, geri dönüşü yok.**
##   - Üç düğme: *kabul et · diren · çık git*.
##   - "Diren" **bir kez** atılır. Şansı ekranda yazılı (`push_odds`) -
##     gizli bir eğriyi deneme yanılmayla bulmak yok, çünkü deneme hakkı da
##     yok. Kazanırsan indirim; kaybedersen tüccar sertleşir, fiyat **artar**
##     ve itibarın düşer.
##   - Kazanç küçük: en iyi hâlde `DISCOUNT_MAX` (%15), eskiden %45'ti.
##     Pazarlık bir gelir kaynağı değil, küçük bir risk.
##   - Masadan kalkmak itibar yiyor ama az: bir bedel, bir felaket değil.
##
## VE KITLIKTA KONU FİYAT DEĞİL (P2): kıtlık `CONSCIENCE_FROM`'u geçince
## "diren" artık **üstelemek** olur - karşındaki satıcı da aç. Kazansan bile
## o bölgede itibarın düşer ve deftere bir satır girer. Kıtlık derslerinin
## *"bedel adı olan birine düşer"* kuralının ticaret tarafı.

enum State {
	OFFERED,
	SUCCESS_DEAL,
	ANGER_QUIT,
}

## Kazanç aralığı. En iyi hâlde %15; eski tasarım %20-45 veriyordu - oyunun
## para bastığı yer orasıydı.
##
## `DISCOUNT_BASE` neden var: bir süre sıfırdı ve becerisiz bir kervanda
## direnip *kazanmak* bile fiyatı yuvarlamada hiç oynatmıyordu ("%39
## ihtimalle 19 GG, yoksa 21 GG" - ekran görüntüsünde yakalandı). Kazancı
## görünmeyen bir risk düğmesi karar değil, tuzaktır: taban kazanç
## direnmenin her zaman bir şey kazandırmasını sağlar, beceri onu büyütür.
const DISCOUNT_BASE: float = 0.04
const DISCOUNT_PER_CHARISMA: float = 0.006
const DISCOUNT_PER_REPUTATION: float = 0.05
const DISCOUNT_MAX: float = 0.15

## Direnmenin şansı. Ekranda yazılı: oyuncu kör zar atmıyor, bilerek
## atıyor - tek hakkı olduğu için bilmesi şart.
const PUSH_ODDS_BASE: float = 0.30
const PUSH_ODDS_PER_CHARISMA: float = 0.030
const PUSH_ODDS_PER_REPUTATION: float = 0.20
const PUSH_ODDS_MIN: float = 0.15
const PUSH_ODDS_MAX: float = 0.85

## Direnip kaybedince: tüccar sertleşir (fiyat artar) ve itibar düşer.
## Artış olmasaydı direnmek bedava bir kura olurdu.
const PUSH_FAIL_RAISE: float = 0.10
const PUSH_REPUTATION_PENALTY: int = 1

## Masadan kalkmanın itibar bedeli. Bilerek küçük: caydırıcı olmalı,
## cezalandırıcı değil.
const WALKOUT_REPUTATION_PENALTY: int = 1

## Kıtlık bu derecenin üstündeyse pazarlığın konusu fiyat değil vicdandır
## (P2): karşındaki de aç, ısrar etmenin bedeli bölgede ödenir.
const CONSCIENCE_FROM: float = 0.45
const CONSCIENCE_STANDING_COST: int = 2

signal state_changed(new_state: State)

var base_price: float
var merchant_greed: float
var reputation: float
var player_charisma: float
## Bölgenin kıtlık derecesi (`Scarcity.at`), 0-1. Yalnızca pazarda verilir;
## yolda (haydut, haraç) kıtlığın vicdanla ilgisi yok.
var scarcity: float = 0.0

var state: State = State.OFFERED
## Tüccarın istediği fiyat: itibarlı bir kervandan daha az sıyrılır.
var list_price: float = 0.0
var final_price: float = 0.0
var pushed: bool = false
var push_won: bool = false

func _init(
	p_base_price: float = 0.0,
	p_merchant_greed: float = 0.5,
	p_reputation: float = 0.0,
	p_player_charisma: float = 0.0,
	p_scarcity: float = 0.0
) -> void:
	setup(p_base_price, p_merchant_greed, p_reputation, p_player_charisma, p_scarcity)

func setup(
	p_base_price: float,
	p_merchant_greed: float,
	p_reputation: float,
	p_player_charisma: float,
	p_scarcity: float = 0.0
) -> void:
	base_price = p_base_price
	merchant_greed = clampf(p_merchant_greed, 0.0, 1.0)
	reputation = clampf(p_reputation, 0.0, 1.0)
	player_charisma = p_player_charisma
	scarcity = clampf(p_scarcity, 0.0, 1.0)
	list_price = base_price * (1.0 + (merchant_greed * (1.0 - reputation)))
	state = State.OFFERED
	pushed = false
	push_won = false
	final_price = 0.0

## Direnç kazanılırsa ödenecek fiyat. İndirim **liste fiyatından**, taban
## fiyattan değil: oyuncunun gördüğü sayıdan iniyor, gizli bir tabandan değil.
func push_price() -> float:
	return maxf(0.0, list_price * (1.0 - discount()))

## Direnç kaybedilirse ödenecek fiyat.
func raised_price() -> float:
	return list_price * (1.0 + PUSH_FAIL_RAISE)

## Şu an ödenecek fiyat: direnilmediyse liste, kazanıldıysa indirimli,
## kaybedildiyse artmış.
func current_price() -> float:
	if not pushed:
		return list_price
	return push_price() if push_won else raised_price()

func discount() -> float:
	var d := DISCOUNT_BASE
	d += player_charisma * DISCOUNT_PER_CHARISMA
	d += reputation * DISCOUNT_PER_REPUTATION
	return clampf(d, 0.0, DISCOUNT_MAX)

## Kazanmanın oyuncunun gördüğü sayıda bir karşılığı var mı. Çok ufak bir
## alışverişte indirim yuvarlamada kayboluyor; o zaman direnmek saf zarar
## olur ve düğme gösterilmez (bkz. `DISCOUNT_BASE`).
func push_is_worth_it() -> bool:
	return int(round(push_price())) < int(round(list_price))

func push_odds() -> float:
	var odds := PUSH_ODDS_BASE
	odds += player_charisma * PUSH_ODDS_PER_CHARISMA
	odds += reputation * PUSH_ODDS_PER_REPUTATION
	return clampf(odds, PUSH_ODDS_MIN, PUSH_ODDS_MAX)

func can_push() -> bool:
	return state == State.OFFERED and not pushed and push_is_worth_it()

## Kıtlıkta "diren" üstelemeye dönüşüyor: karşındaki de aç (P2).
func is_conscience() -> bool:
	return scarcity >= CONSCIENCE_FROM

## Üstelemenin bölgesel itibar bedeli; vicdan dalı kapalıysa sıfır.
func conscience_standing_cost() -> int:
	return CONSCIENCE_STANDING_COST if is_conscience() else 0

func get_walkout_reputation_penalty() -> int:
	return WALKOUT_REPUTATION_PENALTY

func get_push_reputation_penalty() -> int:
	return PUSH_REPUTATION_PENALTY

## Tek hak. `rng` dışarıdan: tohum çağıranın (test ve simülatör aynı zarı
## atabilsin diye). Döner: kazanıldı mı.
func push(rng: RandomNumberGenerator) -> bool:
	if not can_push():
		return false
	pushed = true
	push_won = rng.randf() < push_odds()
	return push_won

func accept() -> void:
	if state != State.OFFERED:
		return
	final_price = current_price()
	_set_state(State.SUCCESS_DEAL)

func walk_away() -> void:
	if state != State.OFFERED:
		return
	_set_state(State.ANGER_QUIT)

func _set_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(state)
