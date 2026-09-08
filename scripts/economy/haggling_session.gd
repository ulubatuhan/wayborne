class_name HagglingSession
extends RefCounted

## Sıra tabanlı pazarlık. UI'dan bağımsız: sahne ağacı gerektirmez, doğrudan
## örneklenip test edilebilir.
##
## ESKİ TASARIMIN AÇIĞI: kabul eşiği sabırla birlikte düşüyordu ve sabrı en
## hızlı düşüren şey aşağılayıcı düşük tekliflerdi. Yani tüccarı çileden
## çıkarmak *ödüllendiriliyordu*; en iyi strateji taban fiyatı spam'lemek,
## sabır sıfıra inerken "son teklif" hakkıyla mutlak en düşük fiyatı almaktı.
## Karar diye bir şey kalmıyordu - bu, oyunun para basma noktasıydı.
##
## YENİ TASARIM: pazarlık hâlâ kazandırıyor ama kazancın bedeli var.
##   1. Taban (get_floor) senin becerinle açılır ve **her reddedilen teklifte
##      sertleşir** - tüccar direndikçe pazarlık payı kapanır. Sonsuz tur
##      atmak kâr getirmez; bir noktadan sonra kaybettirir.
##   2. Kabul eşiği sabır düştükçe tabana doğru iner (get_acceptable_threshold)
##      ama taban yukarı kaçtığı için ikisi ortada bir yerde buluşur. İyi
##      oynanan bir pazarlığın vardığı fiyat işte o buluşma noktasıdır.
##   3. Sabrı bitirmek bir ödül değil: anlaşma kopar, itibar yersin
##      (get_walkout_reputation_penalty) ve "son teklif" hakkın varsa bile
##      eline geçen fiyat sabırla pazarlık edilmiş fiyattan **kötüdür**
##      (FINAL_CHANCE_PENALTY). Öfke bir kaçış yolu, bir strateji değil.
##
## Karar şu hale gelir: bir tur daha zorlayıp biraz daha kazanmak mı,
## eldekini alıp masadan kalkmak mı.

enum State {
	IN_PROGRESS,
	FINAL_CHANCE,
	SUCCESS_DEAL,
	ANGER_QUIT,
}

const DEFAULT_STARTING_PATIENCE: float = 100.0
const PATIENCE_QUIT_THRESHOLD: float = 0.0

## Tüccarın gerçekten razı olabileceği en iyi fiyatın taban fiyata oranı.
## Beceri bunu aşağı çeker ama asla bedavaya inmez.
const FLOOR_BASE_RATIO: float = 0.80
const FLOOR_PER_SPEECH: float = 0.010
const FLOOR_PER_CHARISMA: float = 0.005
const FLOOR_PER_REPUTATION: float = 0.05
const FLOOR_MIN_RATIO: float = 0.55

## Her reddedilen teklif tabanı bu kadar sertleştirir - pazarlık payı kapanır.
## Uzatmanın bedeli budur; sonsuz tur atmak artık kârlı değil.
const FLOOR_HARDEN_PER_ROUND: float = 0.022

## Tabanın belirgin altındaki teklif hakaret sayılır: sabri fazladan yakar ve
## tüccarı fazladan sertleştirir. Eskiden tam tersi işe yarıyordu.
const INSULT_MARGIN: float = 0.85
const INSULT_PATIENCE_MULTIPLIER: float = 2.5
const INSULT_EXTRA_ROUNDS: int = 2

## Sabır bittiğinde "son teklif" hakkı devreye girerse tüccar tabanını değil,
## öfkeyle şişirilmiş halini verir. Bu çarpan olmadan tüccarı çileden
## çıkarmak yine en iyi strateji olurdu.
const FINAL_CHANCE_PENALTY: float = 1.20

## Masadan kalkmanın itibar bedeli - tüccarı çileden çıkarmak kasabada
## duyulur (bkz. market.gd _on_haggle_failed).
const WALKOUT_REPUTATION_PENALTY: int = 2

signal patience_changed(new_patience: float)
signal counter_offer_made(npc_offer: float)
signal final_chance_offered(locked_offer: float)
signal state_changed(new_state: State)

var base_price: float
var merchant_greed: float
var reputation: float
var player_speech: float
var player_charisma: float
var patience_drain_rate: float
var has_final_offer_perk: bool

var state: State = State.IN_PROGRESS
var current_patience: float = DEFAULT_STARTING_PATIENCE
var p_start: float
var p_min: float
var final_price: float = 0.0

## Kaç teklif reddedildi - taban bununla sertleşir.
var rounds_used: int = 0

var _final_chance_used: bool = false
var _locked_offer: float = 0.0

func _init(
	p_base_price: float,
	p_merchant_greed: float,
	p_reputation: float,
	p_player_speech: float,
	p_player_charisma: float,
	p_patience_drain_rate: float = 1.0,
	p_has_final_offer_perk: bool = false
) -> void:
	base_price = p_base_price
	merchant_greed = clampf(p_merchant_greed, 0.0, 1.0)
	reputation = clampf(p_reputation, 0.0, 1.0)
	player_speech = p_player_speech
	player_charisma = p_player_charisma
	patience_drain_rate = p_patience_drain_rate
	has_final_offer_perk = p_has_final_offer_perk

	# İtibarlı bir kervandan daha az sıyırılır.
	p_start = base_price * (1.0 + (merchant_greed * (1.0 - reputation)))
	p_min = get_floor()
	current_patience = DEFAULT_STARTING_PATIENCE

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

## Tüccarın şu an kabul edeceği en düşük fiyat: sabır tükendikçe tabana doğru
## iner ama **tabanın altına asla inmez**. Taban da her turda yukarı kaçtığı
## için ikisi ortada buluşur; sömürünün kaynağı olan "sabrı bitir, dibi al"
## yolu böyle kapanıyor.
func get_acceptable_threshold() -> float:
	var floor_now := get_floor()
	var softness := 1.0 - clampf(current_patience / DEFAULT_STARTING_PATIENCE, 0.0, 1.0)
	return maxf(floor_now, lerpf(p_start, floor_now, softness))

func is_insulting(player_offer: float) -> bool:
	return player_offer < get_floor() * INSULT_MARGIN

func get_walkout_reputation_penalty() -> int:
	return WALKOUT_REPUTATION_PENALTY

func submit_offer(player_offer: float) -> void:
	if state != State.IN_PROGRESS:
		return

	var insulting := is_insulting(player_offer)
	var drain := _calculate_patience_drain(player_offer)
	if insulting:
		drain *= INSULT_PATIENCE_MULTIPLIER

	current_patience -= drain
	patience_changed.emit(current_patience)

	if current_patience <= PATIENCE_QUIT_THRESHOLD:
		current_patience = 0.0
		# Sabrı bitiren teklif de bir reddedilen tekliftir: tüccarı önce
		# sertleştir, son teklifi *ondan sonra* hesapla. Aksi halde ilk
		# hamlede hakaret edip çıkışta el değmemiş tabanı almak mümkündü.
		_harden(insulting)
		_locked_offer = minf(get_floor() * FINAL_CHANCE_PENALTY, p_start)

		if has_final_offer_perk and not _final_chance_used:
			_final_chance_used = true
			_set_state(State.FINAL_CHANCE)
			final_chance_offered.emit(_locked_offer)
		else:
			_set_state(State.ANGER_QUIT)
		return

	var threshold := get_acceptable_threshold()
	if player_offer >= threshold:
		final_price = player_offer
		_set_state(State.SUCCESS_DEAL)
		return

	_harden(insulting)
	var npc_counter_offer := (player_offer + get_acceptable_threshold()) / 2.0
	counter_offer_made.emit(npc_counter_offer)

func respond_to_final_offer(accept: bool) -> void:
	if state != State.FINAL_CHANCE:
		return

	if accept:
		final_price = _locked_offer
		_set_state(State.SUCCESS_DEAL)
	else:
		_set_state(State.ANGER_QUIT)

## Reddedilen her teklif tüccarı sertleştirir; hakaret fazladan sertleştirir.
func _harden(insulting: bool) -> void:
	rounds_used += 1
	if insulting:
		rounds_used += INSULT_EXTRA_ROUNDS
	p_min = get_floor()

## Teklif tüccarın istediğinden ne kadar uzaksa sabır o kadar hızlı biter.
func _calculate_patience_drain(player_offer: float) -> float:
	var price_range := p_start - get_floor()
	if price_range <= 0.0:
		return patience_drain_rate

	var delta_price := absf(p_start - player_offer)
	var normalized := clampf(delta_price / price_range, 0.0, 2.0)
	return (normalized * normalized) * patience_drain_rate

func _set_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(state)
