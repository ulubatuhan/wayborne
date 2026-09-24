class_name Trait
extends Resource

## Darkest Dungeon tarzı huy: karakterin savaş dışı da taşıdığı küçük bir
## eğilim. "Basic seviyede" kalması bilinçli - kleptomanyaklık gibi
## olay-özel, dramatik huylar burada değil, ileride olay sonuçlarıyla
## (bkz. EventEffect.Type.GRANT_TRAIT) eklenir.

@export var trait_id: String = ""
## Saklanan sey ceviri anahtari (bkz. data/locale/game.csv); gosterilen
## metin asagidaki hesaplanan ozelliklerden okunur. Bu ayrim sayesinde
## bu alanlari okuyan ekranlarin hicbiri degismeden cevrilebilir oldu
## - bkz. CLAUDE.md Localization Rules.
@export var display_name_key: String = ""
@export var description_key: String = ""

var display_name: String:
	get: return tr(display_name_key)

var description: String:
	get: return tr(description_key)

@export var is_positive: bool = true

## Bu huyun daha çok kimde çıkacağını belirleyen stat - seed huy dağıtımı
## bu statın taban üstü/altı olmasına göre ağırlıklanır (bkz. TraitCatalog).
@export var affinity_stat: CharacterStats.Kind = CharacterStats.Kind.STRENGTH

## Küçük, kalıcı düzeltmeler - CharacterData'nın türetilmiş değerlerine
## sınıf/boy bonusuyla aynı yerde eklenir.
@export var hp_bonus: int = 0
@export var dodge_bonus: int = 0
@export var accuracy_bonus: int = 0
@export var crit_bonus: int = 0
@export var damage_bonus: int = 0

## --- Faz 17: davranışsal kancalar (Project Zomboid/DD tarzı psikolojik
## etkiler) ---
## Her huy kendi affinity_stat'ının check'lerine küçük bir pay ekler/çıkarır
## - `_build_skill_check_context()`'in okuduğu `best_<stat>`/`leader_<stat>`
## değerlerine karakterin kendi huy toplamı üstünden eklenir (bkz.
## CharacterData.get_check_modifier). Bir huy bir check'i asla tek başına
## kazandırmaz/kaybettirmez - şansı birkaç yüzde puan kaydırır, tıpkı
## Karizma'nın stres reddine olan payı gibi.
@export var check_bonus: float = 0.0
## Sarsılmış/sağlam biri emir de daha kolay/zor reddeder - yalnızca zaten
## kırılmış (CombatUnit.is_stressed) bir birimde devreye girer, kırılma
## eşiğini kendisi değiştirmez (bkz. CombatEncounter._try_refuse_order).
@export var refusal_bonus: int = 0
## Yalnızca Bilgelik'in huyları doldurur - CharacterData.get_xp_bonus_percent()'in
## stat payının üstüne biner.
@export var xp_gain_bonus_percent: int = 0
## Yalnızca İnanç'ın huyları doldurur - CharacterData.get_deathblow_resist_bonus()'un
## stat payının üstüne biner.
@export var deathblow_resist_bonus: int = 0
## Yalnızca Dayanıklılık'ın huyları doldurur - CharacterData.get_stress_resistance()'ın
## stat payının üstüne biner.
@export var stress_resistance_bonus: int = 0

## --- PR-3'ün bilerek dar bırakılan üç kancası, tamamlandı ---
## Yalnızca Karizma'nın huyları doldurur - GameSession.
## get_departure_temperament_bonus()'un okuduğu, kervanın çıkış moraline
## eklenen küçük bir pay. Aynı stat_resistance_bonus'un Dayanıklılık'ta
## yaptığını Karizma'da yapıyor: "Güven Verici" adının kendisi zaten bir
## moral etkisi vaat ediyordu, savaşın dışına hiç taşmamıştı.
@export var morale_bonus: int = 0
## Yalnızca Zeka'nın huyları doldurur - GameSession.get_trait_price_
## multiplier()'ın okuduğu, pazar alış fiyatına eklenen küçük bir indirim/
## zam yüzdesi. Pozitif = indirim (Basiretli pazarlıkta da keskin), negatif
## = zam (Saf kolay kandırılır) - diğer üç stat-özel alanla aynı işaret
## kuralı: virtue'de pozitif, affliction'da negatif.
@export var price_discount_percent: int = 0
