class_name HagglingSession
extends RefCounted

## Sıra tabanlı pazarlık. UI'dan bağımsız: sahne ağacı gerektirmez, doğrudan
## örneklenip test edilebilir.
##
## TASARIMIN GEÇMİŞİ, çünkü iki kez aynı tuzağa düşüldü:
##
## 1. İLK TASARIM: kabul eşiği sabırla birlikte tabana iniyordu ve sabrı en
##    hızlı yakan şey aşağılayıcı dip tekliflerdi. Tüccarı çileden çıkarmak
##    *ödüllendiriliyordu*.
## 2. İKİNCİ TASARIM: eşik tabanın altına inmiyordu ve taban her reddedilen
##    teklifte sertleşiyordu. Sömürü kapanmıştı ama gizli bir kusur kaldı:
##    hem eşik hem taban yalnızca **kaç tur geçtiğinin** fonksiyonuydu. Yani
##    nasıl pazarlık ettiğin değil, kaç kez reddedildiğin önemliydi; ikisi
##    hep aynı noktada buluşuyordu ve oyuncunun tek işi o sayıyı bulmaktı.
##
## BU TASARIM: yolun kendisi önemli.
##   - Elinde **MAX_ROUNDS** kadar teklif hakkı var, o kadar. Sayılabilir ve
##     ekranda görünür; gizli bir eğriyi deneme yanılmayla bulmak yok.
##   - Tüccar yalnızca **ciddiye aldığı** bir tekliften sonra bir adım geri
##     çekilir (bkz. is_credible / concessions). Dip teklif hakkını yakar ama
##     tüccarı yaklaştırmaz - "aynı dip teklifi üç kez ver, üçüncüde kabul
##     ettir" işte bu yüzden çalışmıyor.
##   - Her reddedilen teklif tabanı ayrıca sertleştirir: uzatmanın bedeli var.
##   - Hakların bitince tüccar ültimatom verir: **ya listeden al ya çık.**
##     Çıkmak itibar yiyor ama az - masadan kalkmak bir felaket değil, bir
##     bedel.
##
## Sonuç bir gradyan: temkinli oyuncu ilk turda küçük bir indirim alır,
## nişan alan oyuncu üç turu doğru kullanıp tabana yaklaşır, açgözlü oyuncu
## ültimatoma çarpar ve liste fiyatını öder.

enum State {
	IN_PROGRESS,
	FINAL_CHANCE,
	SUCCESS_DEAL,
	ANGER_QUIT,
}

## Kaç teklif hakkın var. Üç, çünkü sayılabilir olması gerekiyor: oyuncu
## "bir hakkım kaldı" diyebilmeli, "sabır çubuğu ne kadar indi" diye
## tahmin etmemeli.
const MAX_ROUNDS: int = 3

## Sabır çubuğu artık kalan hakkın görüntüsü (bkz. current_patience).
const DEFAULT_STARTING_PATIENCE: float = 100.0

## Tüccarın gerçekten razı olabileceği en iyi fiyatın taban fiyata oranı.
## Beceri bunu aşağı çeker ama asla bedavaya inmez.
const FLOOR_BASE_RATIO: float = 0.80
const FLOOR_PER_SPEECH: float = 0.010
const FLOOR_PER_CHARISMA: float = 0.005
const FLOOR_PER_REPUTATION: float = 0.05
const FLOOR_MIN_RATIO: float = 0.55

## Her reddedilen teklif tabanı bu kadar sertleştirir - uzatmanın bedeli.
const FLOOR_HARDEN_PER_ROUND: float = 0.022

## Tüccarın "ciddi" saydığı teklif: o anki eşiğin bu oranının üstü. Ciddi bir
## teklif reddedilse bile tüccarı bir adım yaklaştırır; altındaki teklif
## yalnızca hakkını yakar. Sömürüyü kapatan asıl mekanizma bu.
const CREDIBLE_MARGIN: float = 0.85

## Tabanın belirgin altındaki teklif hakaret sayılır: tek hamlede iki hak yakar.
const INSULT_MARGIN: float = 0.85
const INSULT_ROUND_COST: int = 2

## Masadan kalkmanın itibar bedeli. Bilerek küçük: caydırıcı olmalı, cezalandırıcı
## değil - pazarlık denemek riskli olsun ama korkutucu olmasın.
const WALKOUT_REPUTATION_PENALTY: int = 1

signal patience_changed(new_patience: float)
signal counter_offer_made(npc_offer: float)
signal final_chance_offered(locked_offer: float)
signal state_changed(new_state: State)

var base_price: float
var merchant_greed: float
var reputation: float
var player_speech: float
var player_charisma: float
## Doğru bilinen "son teklif" yeteneği: ültimatom liste fiyatından değil,
## tüccarın o anki tabanından gelir. Hakları yakmayı ödüllendirmiyor -
## üç turu doğru kullanmak hâlâ daha ucuz (bkz. tests/test_haggling.gd).
var has_final_offer_perk: bool

var state: State = State.IN_PROGRESS
var p_start: float
var p_min: float
var final_price: float = 0.0

## Kaç teklif harcandı (hakaret ikisini birden yakar).
var rounds_used: int = 0
## Tüccarın kaç kez geri çekildiği - yalnızca ciddi tekliflerle artar.
var concessions: int = 0

## Kalan hakkın 0-100 arası görüntüsü; HagglingPanel'in çubuğu bunu okuyor.
## Ayrı bir kaynak değil, rounds_used'ın türevi - ikisi ayrı tutulsaydı
## kaçınılmaz olarak birbirinden kopardı.
var current_patience: float = DEFAULT_STARTING_PATIENCE

var _final_chance_used: bool = false
var _locked_offer: float = 0.0

func _init(
	p_base_price: float,
	p_merchant_greed: float,
	p_reputation: float,
	p_player_speech: float,
	p_player_charisma: float,
	p_has_final_offer_perk: bool = false
) -> void:
	base_price = p_base_price
	merchant_greed = clampf(p_merchant_greed, 0.0, 1.0)
	reputation = clampf(p_reputation, 0.0, 1.0)
	player_speech = p_player_speech
	player_charisma = p_player_charisma
	has_final_offer_perk = p_has_final_offer_perk

	# İtibarlı bir kervandan daha az sıyırılır.
	p_start = base_price * (1.0 + (merchant_greed * (1.0 - reputation)))
	p_min = get_floor()
	_sync_patience()

func get_rounds_left() -> int:
	return maxi(0, MAX_ROUNDS - rounds_used)

## Tüccarın razı olabileceği taban: becerinle açılır, her reddedilen teklifle
## kapanır. İtibar da tabanı biraz indirir - tanınan tüccar daha rahat verir.
func get_floor() -> float:
	var ratio := FLOOR_BASE_RATIO
	ratio -= player_speech * FLOOR_PER_SPEECH
	ratio -= player_charisma * FLOOR_PER_CHARISMA
	ratio -= reputation * FLOOR_PER_REPUTATION
	ratio += float(rounds_used) * FLOOR_HARDEN_PER_ROUND
	ratio = clampf(ratio, FLOOR_MIN_RATIO, 1.0)
	return clampf(base_price * ratio, 0.0, p_start)

func get_slider_range() -> Vector2:
	return Vector2(maxf(p_min * 0.6, 0.0), p_start * 1.2)

## Tüccarın şu an kabul edeceği en düşük fiyat. Liste fiyatından tabana doğru
## **taviz adımlarıyla** iner - geçen turlarla değil. Aradaki fark tasarımın
## kendisi: geri çekilmeyi kazanman gerekiyor, beklemen değil.
func get_acceptable_threshold() -> float:
	var floor_now := get_floor()
	var progress := clampf(float(concessions + 1) / float(MAX_ROUNDS), 0.0, 1.0)
	return maxf(floor_now, lerpf(p_start, floor_now, progress))

## Tüccarın ciddiye aldığı teklif. Reddedilse bile bir adım kazandırır.
func is_credible(player_offer: float) -> bool:
	return player_offer >= get_acceptable_threshold() * CREDIBLE_MARGIN

func is_insulting(player_offer: float) -> bool:
	return player_offer < get_floor() * INSULT_MARGIN

func get_walkout_reputation_penalty() -> int:
	return WALKOUT_REPUTATION_PENALTY

func submit_offer(player_offer: float) -> void:
	if state != State.IN_PROGRESS:
		return

	if player_offer >= get_acceptable_threshold():
		final_price = player_offer
		_set_state(State.SUCCESS_DEAL)
		return

	var insulting := is_insulting(player_offer)
	# Ciddiyet, teklifin *reddedilmeden önceki* eşiğe göre ölçülüyor - taban
	# sertleşmeden önce, yoksa oyuncu kendi tekliflerinin arkasından koşardı.
	var credible := not insulting and is_credible(player_offer)

	rounds_used += INSULT_ROUND_COST if insulting else 1
	if credible:
		concessions += 1
	p_min = get_floor()
	_sync_patience()

	if rounds_used >= MAX_ROUNDS:
		_open_ultimatum()
		return

	counter_offer_made.emit((player_offer + get_acceptable_threshold()) / 2.0)

## Haklar bitti: "ya listeden al ya çık." Yetenek yoksa fiyat liste fiyatıdır -
## açgözlü oyuncunun bütün kazancı burada geri alınıyor.
func _open_ultimatum() -> void:
	rounds_used = MAX_ROUNDS
	_sync_patience()
	_locked_offer = minf(get_floor(), p_start) if has_final_offer_perk else p_start
	_final_chance_used = true
	_set_state(State.FINAL_CHANCE)
	final_chance_offered.emit(_locked_offer)

func respond_to_final_offer(accept: bool) -> void:
	if state != State.FINAL_CHANCE:
		return

	if accept:
		final_price = _locked_offer
		_set_state(State.SUCCESS_DEAL)
	else:
		_set_state(State.ANGER_QUIT)

func _sync_patience() -> void:
	current_patience = DEFAULT_STARTING_PATIENCE * (
		float(get_rounds_left()) / float(MAX_ROUNDS)
	)
	patience_changed.emit(current_patience)

func _set_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(state)
