class_name RoadSignals
extends RefCounted

## Yolun sürekli konuşan katmanı.
##
## Olay kartı **günde bir kez**, şafakta çıkıyordu (bkz. JourneyClock.
## START_HOUR). Yani yolun 23 saati sessizdi ve "yolda yapacak bir şey
## yok" şikâyetinin asıl kaynağı buydu - kart eksikliği değil, kartlar
## arasındaki boşluk.
##
## İşaretler o boşluğu dolduruyor ve **modal değiller**: kart açmıyorlar,
## zamanı durdurmuyorlar, oyuncudan seçim istemiyorlar. Yol kenarında bir
## şey oluyor, oyuncu ya ilgileniyor ya ilgilenmiyor. İlgilenmek =
## liderin o bölgeye yürümesi (bkz. RoadAttention) - yani yeni bir girdi
## de icat edilmiyor, zaten var olan yürüyüş anlamlandırılıyor.
##
## **İhmal edilen bir işaret büyür.** Gıcırdayan tekerlek üç gün sonra
## kırılan akstır. Sonuç yine oyunun kendi diliyle ödenir: vagon hasarı,
## stres, tehlike artışı. Yeni bir ceza mekaniği yok.
##
## UI'sız ve tohumlanabilir: ekran yalnızca saat ve dikkat bölgesi
## veriyor, karşılığında ne olduğunu alıyor.

const KIND_WHEEL: String = "wheel"
const KIND_STRAGGLER: String = "straggler"
const KIND_SMOKE: String = "smoke"
## Kehanet (görev Y-B03): kervanın ardından gelen kuzgun, kızıl bir gök. Arkada
## görülür; gerçek mi, boş mu, ancak bakan bilir.
const KIND_OMEN: String = "omen"

## --- Belirsizlik (görev Y-B03) ---
## İşaretin türünü görmek ne olduğunu söylemez. Her işaret doğarken gizli bir
## "gerçek" çeker; ilgilenen (kendi bölgesine yürüyen) onu öğrenir ve gerçeğe
## göre sonucu alır, ihmal eden de gerçeğe göre bedelini öder - bazısı boştur.
## Gerçek kayda yazılır (yüklemek belirsizliği yeniden atmaz).
## Her tür: [[gerçek, ağırlık], ...]; ilk gerçek eski kayıtların varsayılanı.
const TRUTHS: Dictionary = {
	KIND_WHEEL: [["axle", 0.5], ["loose_load", 0.3], ["false_alarm", 0.2]],
	KIND_STRAGGLER: [["tired", 0.5], ["sick", 0.3], ["stranger", 0.2]],
	KIND_SMOKE: [["bandit_camp", 0.4], ["village_fire", 0.35], ["herders", 0.25]],
	KIND_OMEN: [["true_omen", 0.5], ["empty_omen", 0.5]],
}
## Gerçeğe göre metin anahtarları (tam yazılı).
const TRUTH_RESOLVED_KEYS: Dictionary = {
	"axle": "UI_ROAD_SIGNAL_WHEEL_FIXED", "loose_load": "UI_SIGNAL_LOOSE_LOAD_FIXED",
	"false_alarm": "UI_SIGNAL_FALSE_ALARM_FIXED", "tired": "UI_ROAD_SIGNAL_STRAGGLER_FIXED",
	"sick": "UI_SIGNAL_SICK_FIXED", "stranger": "UI_SIGNAL_STRANGER_FIXED",
	"bandit_camp": "UI_SIGNAL_BANDIT_CAMP_FIXED", "village_fire": "UI_SIGNAL_VILLAGE_FIRE_FIXED",
	"herders": "UI_SIGNAL_HERDERS_FIXED", "true_omen": "UI_SIGNAL_TRUE_OMEN_FIXED",
	"empty_omen": "UI_SIGNAL_EMPTY_OMEN_FIXED",
}
const TRUTH_ESCALATED_KEYS: Dictionary = {
	"axle": "UI_ROAD_SIGNAL_WHEEL_BROKE", "loose_load": "UI_SIGNAL_LOOSE_LOAD_LOST",
	"false_alarm": "UI_SIGNAL_FALSE_ALARM_GONE", "tired": "UI_ROAD_SIGNAL_STRAGGLER_LOST",
	"sick": "UI_SIGNAL_SICK_WORSE", "stranger": "UI_SIGNAL_STRANGER_STOLE",
	"bandit_camp": "UI_ROAD_SIGNAL_SMOKE_AMBUSH", "village_fire": "UI_SIGNAL_VILLAGE_FIRE_GUILT",
	"herders": "UI_SIGNAL_HERDERS_GONE", "true_omen": "UI_SIGNAL_TRUE_OMEN_CAME",
	"empty_omen": "UI_SIGNAL_EMPTY_OMEN_GONE",
}

static func default_truth(kind: String) -> String:
	var table: Array = TRUTHS.get(kind, [])
	return String(table[0][0]) if not table.is_empty() else ""

static func roll_truth(kind: String, rng: RandomNumberGenerator) -> String:
	var table: Array = TRUTHS.get(kind, [])
	var roll := rng.randf()
	var acc := 0.0
	for entry in table:
		acc += float(entry[1])
		if roll <= acc:
			return String(entry[0])
	return default_truth(kind)

static func truth_of(entry: Dictionary) -> String:
	var truth := String(entry.get("truth", ""))
	return truth if not truth.is_empty() else default_truth(String(entry.get("kind", "")))

## Hangi bölgede ilgilenilirse çözülür. İşaretin bölgesi, onun *nerede*
## olduğudur: tekerlek vagonlarda, geride kalan kuyrukta, ufuktaki duman
## önde.
const KIND_ZONES: Dictionary = {
	KIND_WHEEL: RoadAttention.ZONE_WAGONS,
	KIND_STRAGGLER: RoadAttention.ZONE_REAR,
	KIND_SMOKE: RoadAttention.ZONE_FRONT,
	KIND_OMEN: RoadAttention.ZONE_REAR,
}

## Metin anahtarları - tam yazılıyor (bkz. Localization Rules).
const KIND_NOTICE_KEYS: Dictionary = {
	KIND_WHEEL: "UI_ROAD_SIGNAL_WHEEL",
	KIND_STRAGGLER: "UI_ROAD_SIGNAL_STRAGGLER",
	KIND_SMOKE: "UI_ROAD_SIGNAL_SMOKE",
	KIND_OMEN: "UI_ROAD_SIGNAL_OMEN",
}
const KIND_RESOLVED_KEYS: Dictionary = {
	KIND_WHEEL: "UI_ROAD_SIGNAL_WHEEL_FIXED",
	KIND_STRAGGLER: "UI_ROAD_SIGNAL_STRAGGLER_FIXED",
	KIND_SMOKE: "UI_ROAD_SIGNAL_SMOKE_FIXED",
	KIND_OMEN: "UI_SIGNAL_EMPTY_OMEN_FIXED",
}
const KIND_ESCALATED_KEYS: Dictionary = {
	KIND_WHEEL: "UI_ROAD_SIGNAL_WHEEL_BROKE",
	KIND_STRAGGLER: "UI_ROAD_SIGNAL_STRAGGLER_LOST",
	KIND_SMOKE: "UI_ROAD_SIGNAL_SMOKE_AMBUSH",
	KIND_OMEN: "UI_SIGNAL_EMPTY_OMEN_GONE",
}

const ALL_KINDS: Array[String] = [KIND_WHEEL, KIND_STRAGGLER, KIND_SMOKE, KIND_OMEN]

## Kaç saat ilgilenilmezse büyür. Bir günden uzun, çünkü oyuncunun
## kolonda yürüyüp gitmesine zaman tanımalı; iki günden kısa, çünkü
## unutulabilecek kadar uzun bir tehdit tehdit değildir.
const ESCALATE_HOURS: float = 30.0

## Saat başına yeni işaret çıkma ihtimali. Düşük görünüyor ama bir sefer
## 6 gün × 24 saat: ölçüldü, sefer başına ortalama ~4 işaret çıkıyor -
## yani yol konuşuyor ama gevezelik etmiyor.
const SPAWN_CHANCE_PER_HOUR: float = 0.03

## Aynı anda en fazla bu kadar açık işaret. Üstü, oyuncunun hepsini
## kovalayamayacağı bir gürültüye dönüyor ve seçim yapmak yerine
## çaresizlik hissettiriyor.
const MAX_OPEN: int = 2

## Duman görmezden gelinirse yolun tehlikesi bu kadar artar (headroom'a
## uygulanır, bkz. Route Rules - toplamın kendisine değil).
const SMOKE_DANGER_DELTA: float = 0.18

## Kadrodaki her olumsuz huy işaret sıklığını bu kadar artırıyor. Huy
## uzun süre yalnızca savaşta bir sayıyı bükeyordu; oysa olumsuz huy
## *görülür* olmalı. Dağılmış bir kadro yolda daha çok aksatıyor,
## daha çok geride kalıyor - yeni bir sistem değil, var olan katmanın
## çarpanı.
const AFFLICTION_SPAWN_BONUS: float = 0.35

## Açık işaretler: her biri {kind, age_hours}.
var open_signals: Array[Dictionary] = []

func has_open() -> bool:
	return not open_signals.is_empty()

func get_open_kinds() -> Array[String]:
	var kinds: Array[String] = []
	for entry in open_signals:
		kinds.append(String(entry["kind"]))
	return kinds

static func get_zone_for(kind: String) -> String:
	return String(KIND_ZONES.get(kind, RoadAttention.ZONE_WAGONS))

static func get_notice_key(kind: String) -> String:
	return String(KIND_NOTICE_KEYS.get(kind, ""))

static func get_resolved_key(kind: String) -> String:
	return String(KIND_RESOLVED_KEYS.get(kind, ""))

static func get_escalated_key(kind: String) -> String:
	return String(KIND_ESCALATED_KEYS.get(kind, ""))

## Bir zaman dilimini işler. Dönen sözlük ekranın anlatması gerekenler:
##   appeared  -> yeni çıkan işaret türleri
##   resolved  -> lider ilgilendiği için kapanan türler
##   escalated -> ihmal edildiği için büyüyen türler
##
## `attention_zone` liderin o an baktığı yer. Bir işaret **yalnızca**
## kendi bölgesinde ilgilenilince çözülür: dikkat sonlu olmasaydı bütün
## katman bedava olurdu.
func tick(
	hours: float, attention_zone: String, rng: RandomNumberGenerator,
	affliction_count: int = 0
) -> Dictionary:
	var result := {"appeared": [], "resolved": [], "escalated": [], "resolved_truths": [], "escalated_truths": []}
	if hours <= 0.0:
		return result

	# Önce çözülme: aynı tik içinde çıkan bir işaret hemen çözülmesin,
	# yoksa doğru bölgede durmak işaretleri hiç göstermeden yutardı.
	var survivors: Array[Dictionary] = []
	for entry in open_signals:
		var kind := String(entry["kind"])
		if get_zone_for(kind) == attention_zone:
			result["resolved"].append(kind)
			result["resolved_truths"].append(truth_of(entry))
			continue
		entry["age_hours"] = float(entry["age_hours"]) + hours
		if float(entry["age_hours"]) >= ESCALATE_HOURS:
			result["escalated"].append(kind)
			result["escalated_truths"].append(truth_of(entry))
			continue
		survivors.append(entry)
	open_signals = survivors

	# Sonra doğuş. Saat başına atılıyor ama tik bir saatten uzun
	# olabiliyor (3x hız, uzun bir olay), o yüzden ihtimal süreyle
	# ölçekleniyor - yoksa hızlı oynayan oyuncu daha az işaret görürdü.
	var affliction_scale := 1.0 + float(maxi(0, affliction_count)) * AFFLICTION_SPAWN_BONUS
	var chance := clampf(SPAWN_CHANCE_PER_HOUR * hours * affliction_scale, 0.0, 1.0)
	if open_signals.size() < MAX_OPEN and rng.randf() < chance:
		var kind := _roll_kind(rng)
		if not get_open_kinds().has(kind):
			open_signals.append({"kind": kind, "age_hours": 0.0, "truth": roll_truth(kind, rng)})
			result["appeared"].append(kind)

	return result

func clear() -> void:
	open_signals.clear()

## Sefer ortası kaydı için (bkz. JourneyController.to_dict). Açık işaretlerin
## tür ve yaşı yazılır; zar durumu işaretlerin değil seferin (signal_rng).
func to_dict() -> Dictionary:
	var entries: Array = []
	for entry in open_signals:
		entries.append({"kind": String(entry["kind"]), "age_hours": float(entry["age_hours"]), "truth": truth_of(entry)})
	return {"open": entries}

## Eski kayıtta alan yok: boş liste. Bilinmeyen tür, eksi ya da sayı olmayan
## yaş ve MAX_OPEN üstü girdiler atılır; bozuk bir kayıt işaret katmanını
## bozmasın.
func from_dict(data: Dictionary) -> void:
	open_signals.clear()
	for raw in data.get("open", []) as Array:
		if not (raw is Dictionary):
			continue
		var kind := String((raw as Dictionary).get("kind", ""))
		if not ALL_KINDS.has(kind) or get_open_kinds().has(kind):
			continue
		var age := float((raw as Dictionary).get("age_hours", 0.0))
		if is_nan(age) or is_inf(age):
			age = 0.0
		if open_signals.size() >= MAX_OPEN:
			break
		var truth := String((raw as Dictionary).get("truth", ""))
		var known := false
		for option in TRUTHS.get(kind, []):
			if String(option[0]) == truth:
				known = true
		open_signals.append({"kind": kind, "age_hours": maxf(0.0, age), "truth": truth if known else default_truth(kind)})

## Türler eşit ağırlıkta: biri ötekinden sık çıksaydı oyuncu tek bir
## bölgede durmayı öğrenir ve dikkat kararı ölürdü.
func _roll_kind(rng: RandomNumberGenerator) -> String:
	return ALL_KINDS[rng.randi_range(0, ALL_KINDS.size() - 1)]
