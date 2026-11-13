class_name ScribeLines
extends RefCounted

## Kâtibin sesi (görev Y-I03).
##
## Oyunda anlatıcı yok (SIDERIA §0.2): her metnin bir söyleyeni var. Bu
## satırların söyleyeni kervanın kâtibi; defteri o tutar ve kritik anlarda
## deftere kısa, kuru bir satır düşer. Edebî olan akşamın günlük cümlesidir
## (oyuncu seçer, `DIARY_*`); kâtip seçmez, kaydeder. Sayı yazmaz, ad yazmaz:
## ad defterde zaten var, kâtibin işi o anın tonunu tutmak.
##
## Her an için üç satır; hangisinin düşeceği günden ve kervanın adından
## türer (aynı kayıt aynı satırı verir). Ses: `voice_path(key)` dosyası
## varsa çalınır, yoksa satır sessiz kalır (AudioManager'ın eksik dosya
## kuralı). Kayıt listesi: docs/ses/katip_satirlari.md.

const LINES: Dictionary = {
	"depart": ["SCRIBE_DEPART_1", "SCRIBE_DEPART_2", "SCRIBE_DEPART_3"],
	"death": ["SCRIBE_DEATH_1", "SCRIBE_DEATH_2", "SCRIBE_DEATH_3"],
	"wagon": ["SCRIBE_WAGON_1", "SCRIBE_WAGON_2", "SCRIBE_WAGON_3"],
	"lost": ["SCRIBE_LOST_1", "SCRIBE_LOST_2", "SCRIBE_LOST_3"],
	"won": ["SCRIBE_WON_1", "SCRIBE_WON_2", "SCRIBE_WON_3"],
	"hunger": ["SCRIBE_HUNGER_1", "SCRIBE_HUNGER_2", "SCRIBE_HUNGER_3"],
	"sacrifice": ["SCRIBE_SACRIFICE_1", "SCRIBE_SACRIFICE_2", "SCRIBE_SACRIFICE_3"],
	"cal_ilk_ot": ["SCRIBE_CAL_ILK_OT_1", "SCRIBE_CAL_ILK_OT_2", "SCRIBE_CAL_ILK_OT_3"],
	"cal_hac": ["SCRIBE_CAL_HAC_1", "SCRIBE_CAL_HAC_2", "SCRIBE_CAL_HAC_3"],
	"cal_panayir": ["SCRIBE_CAL_PANAYIR_1", "SCRIBE_CAL_PANAYIR_2", "SCRIBE_CAL_PANAYIR_3"],
	"cal_ondalik": ["SCRIBE_CAL_ONDALIK_1", "SCRIBE_CAL_ONDALIK_2", "SCRIBE_CAL_ONDALIK_3"],
	"cal_tas_gecesi": ["SCRIBE_CAL_TAS_GECESI_1", "SCRIBE_CAL_TAS_GECESI_2", "SCRIBE_CAL_TAS_GECESI_3"],
}

const VOICE_DIR: String = "res://data/assets/audio/voice/katip/"

static func has_moment(moment: String) -> bool:
	return LINES.has(moment)

static func pick(moment: String, seed_text: String) -> String:
	var keys: Array = LINES.get(moment, [])
	if keys.is_empty():
		return ""
	return String(keys[posmod(hash("%s|%s" % [moment, seed_text]), keys.size())])

static func voice_path(key: String) -> String:
	return VOICE_DIR + key.to_lower() + ".ogg"
