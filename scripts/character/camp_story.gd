class_name CampStory
extends RefCounted

## Kamp ateşi hikâyesi (görev R1 #3) ve yoldaşın kişisel zinciri (Y-C17).
## Her geçmişin üç bölümü var: tanış (bağ 1), güven (bağ 3), sır (bağ 5).
## Kamp kurulunca, kapısı açık ve hikâyesi bitmemiş biri `TELL_CHANCE` ile
## anlatır; gün başına bir. Dinlemek bağı artırır, deftere satır yazar ve
## bölümü ilerletir; sır bölümü anlatanın en ağır şikâyetini siler ve
## yükünü hafifletir. Kendi hikâyeni anlatmak bütün kadroyu biraz rahatlatır.
## Kişisel hedef (goal) geçmişten gelir; karakter ekranı okuyabilir.

const TELL_CHANCE: float = 0.6
const CHAPTER_GATES: Array[int] = [1, 3, 5]
const LISTEN_RAPPORT: int = 1
const SECRET_STRESS: int = -8
const OWN_TALE_STRESS: int = -3

const STORY_KEYS: Dictionary = {
	"debtor": ["STORY_DEBTOR_1", "STORY_DEBTOR_2", "STORY_DEBTOR_3"],
	"exile": ["STORY_EXILE_1", "STORY_EXILE_2", "STORY_EXILE_3"],
	"widow": ["STORY_WIDOW_1", "STORY_WIDOW_2", "STORY_WIDOW_3"],
	"fugitive": ["STORY_FUGITIVE_1", "STORY_FUGITIVE_2", "STORY_FUGITIVE_3"],
	"hungry": ["STORY_HUNGRY_1", "STORY_HUNGRY_2", "STORY_HUNGRY_3"],
}
const GOAL_KEYS: Dictionary = {
	"debtor": "GOAL_DEBTOR", "exile": "GOAL_EXILE", "widow": "GOAL_WIDOW",
	"fugitive": "GOAL_FUGITIVE", "hungry": "GOAL_HUNGRY",
}

const CHOICE_LISTEN: String = "listen"
const CHOICE_OWN_TALE: String = "own_tale"
const CHOICE_SLEEP: String = "sleep"

static func next_key(character: CharacterData) -> String:
	if not STORY_KEYS.has(character.backstory_id) or character.story_chapter >= 3:
		return ""
	return String(STORY_KEYS[character.backstory_id][character.story_chapter])

static func can_tell(character: CharacterData) -> bool:
	if character.is_player or next_key(character).is_empty():
		return false
	return character.rapport >= CHAPTER_GATES[character.story_chapter]

## Bu kamp kim anlatır (ya da null). En stresli olan önce: derdi olan konuşur.
static func pick_teller(party: Array[CharacterData], rng: RandomNumberGenerator) -> CharacterData:
	var best: CharacterData = null
	for character in party:
		if can_tell(character) and (best == null or character.stress > best.stress):
			best = character
	if best == null or rng.randf() >= TELL_CHANCE:
		return null
	return best
