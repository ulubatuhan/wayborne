class_name SkillCheck
extends Resource

## Faz 17: bir EventChoice'un arkasındaki stat zarı. Var olan mimariye
## yeni bir çözümleyici eklemeden oturuyor - EventEngine.resolve_check()
## zarı atıp sonucu ("check_tier": 0/1/2) context'in bir kopyasına yazıyor,
## EventOutcome'ların kendi `conditions`'ı bunu normal
## EventCondition.GREATER_EQUAL/EQUAL ile okuyor. Yani "skill-check" diye
## ayrı bir ikinci dallanma dili yok - mevcut ağırlıklı-sonuç mekanizması
## artık koşullu olarak bir zarın sonucunu da okuyabiliyor.
##
## "Bedava çıkış yoktur" aksiyomuyla çelişmiyor: saf kaynak-takası seçenekler
## (parayı öde, malı at) check taşımıyor, deterministik kalıyor. Check yalnızca
## *beceri* isteyen seçeneklere (ikna et, incele, kavgada ayır, niyet oku,
## doğru kararı ver, umudu koru) ekleniyor.

enum Source {
	## Yalnızca liderin kendi statı - "bunu tek başına göze aldı" kararları.
	LEADER,
	## Partideki en iyi değer - bir ekip işi, en uygun olan yapar.
	PARTY_BEST,
}

@export var stat: CharacterStats.Kind = CharacterStats.Kind.INTELLECT
@export var source: Source = Source.PARTY_BEST
## Zorluk: etkin stat değerine (taban 0, bkz. CharacterStats.get_effective_value)
## karşı bir eşik. 0 = ortalama bir karakter (statı 5) tam %50 civarında
## geçer; pozitif değer zorlaştırır, negatif kolaylaştırır.
@export var difficulty: float = 0.0

## Her etkin puan şansı bu kadar değiştirir. 6 seçildi: statı 10'a
## (effective +5) çıkarmış biri tabana göre %30 daha güçlü şansla girer -
## hissedilir ama tek başına hiçbir check'i garantiye almaz.
const CHANCE_PER_EFFECTIVE_POINT: float = 6.0
const MIN_CHANCE: int = 5
const MAX_CHANCE: int = 95
## Şansın en güvenli (düşük zar gerektiren) %15'i "tam başarı" sayılır -
## kıl payı geçmekle konuyu gerçekten hakkıyla çözmek arasındaki BG3/DOS2
## tarzı ayrım.
const CRITICAL_BAND: int = 15

## Başarı ihtimali (yüzde) - hem zar hem de butonun üstündeki "Zeka 12 · %72"
## önizlemesi **aynı** bu formülü okur, iki yerde iki formül olmasın diye.
static func compute_chance(effective_stat: float, difficulty: float) -> int:
	return clampi(
		int(round(50.0 + CHANCE_PER_EFFECTIVE_POINT * (effective_stat - difficulty))),
		MIN_CHANCE, MAX_CHANCE
	)

func get_chance(effective_stat: float) -> int:
	return compute_chance(effective_stat, difficulty)

## 0 = başarısızlık, 1 = kıl payı (normal başarı), 2 = tam başarı.
func roll(effective_stat: float, rng: RandomNumberGenerator) -> int:
	var chance := get_chance(effective_stat)
	var value := rng.randi_range(1, 100)
	if value > chance:
		return 0
	if value <= maxi(1, chance - CRITICAL_BAND):
		return 2
	return 1

## GameSession.build_event_context()'in okuduğu anahtar - "best_wisdom",
## "leader_faith" gibi. Sekiz statın hepsi için bu iki önek zaten context'te
## duruyor (bkz. GameSession._build_skill_check_context).
func get_context_key() -> String:
	var stat_name: String = String(CharacterStats.Kind.keys()[stat]).to_lower()
	var prefix := "leader" if source == Source.LEADER else "best"
	return "%s_%s" % [prefix, stat_name]

static func make(
	stat_kind: CharacterStats.Kind, source_kind: Source = Source.PARTY_BEST, difficulty_value: float = 0.0
) -> SkillCheck:
	var check := SkillCheck.new()
	check.stat = stat_kind
	check.source = source_kind
	check.difficulty = difficulty_value
	return check
