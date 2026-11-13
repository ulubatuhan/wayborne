class_name WorldSecret
extends RefCounted

## Yavaş açılan dünya sırrı (görev Y-E04).
##
## Sırrın kendisi geliştirici belgesinde (docs/lore/SIR.md); oyunda hiç kimse
## onu bu açıklıkla bilmez (SIDERIA §3). Oyuncuya yalnızca parçalar düşer:
## yolda, ateş başında birinin söylediği tek bir cümle. Her ipucu bir kez
## duyulur, kervanbaşının defterine yazılır ve sıradaki duyulana kadar orada
## bekler. Açıklama yok, bağlantıyı oyuncu kurar.
##
## `region` boşsa her yolda duyulabilir; doluysa yalnız o bölgeye giden yolda.

const CLUES: Array = [
	{"key": "CLUE_STONES", "region": ""},
	{"key": "CLUE_FIRST_GRASS", "region": ""},
	{"key": "CLUE_GALLERIES", "region": "dag_maden"},
	{"key": "CLUE_PAINTINGS", "region": "dag_maden"},
	{"key": "CLUE_ALTAR_STONE", "region": "vadi"},
	{"key": "CLUE_EMPTY_LEDGER", "region": "imparatorluk"},
	{"key": "CLUE_EMPTY_HILLS", "region": "gocebe"},
	{"key": "CLUE_WATER_DEAD", "region": "guney"},
	{"key": "CLUE_TORN_PAGE", "region": "ahit"},
	{"key": "CLUE_ICE_BEAST", "region": "dag"},
	{"key": "CLUE_TROUGH", "region": "sinir"},
	{"key": "CLUE_ROAD_OLDER", "region": ""},
	{"key": "CLUE_NO_NAMES", "region": ""},
	{"key": "CLUE_WARM_STONES", "region": "dag_maden"},
	{"key": "CLUE_LIFE_FORCE", "region": ""},
	{"key": "CLUE_PAVED_ROADS", "region": "imparatorluk"},
	{"key": "CLUE_SAME_BEGINNING", "region": "vadi"},
	{"key": "CLUE_FAR_SHORE", "region": "guney"},
]

## Yol gününde bir ipucu duyulma şansı. Seyrek: kırk seferde on sekizin
## hepsini duymak zor olmalı, yoksa sır bir görev listesine döner. Ölçüm
## (simulate_career, 40 sefer): 0,08'de 14 ipucu, 0,025'te 10,5; kalanı başka
## bölgelerin yolunda ya da varisin döneminde bekler.
const HEAR_CHANCE: float = 0.025

## Bu bölgede duyulabilecek, henüz duyulmamış ilk ipucu (sırası belgedeki).
static func next_clue(seen: Array, region: String) -> String:
	for clue in CLUES:
		var key := String(clue["key"])
		if seen.has(key):
			continue
		var where := String(clue["region"])
		if where.is_empty() or where == region:
			return key
	return ""
