extends SceneTree

## Oyun testi sürücüsü: bir oyuncu profilini, verilen gerçek oyun süresi
## eşdeğeri dolana kadar oynatır ve üç dosya yazar (olaylar.jsonl,
## ozet.json, gunluk.md). Test değil - hiç kırmızı dönmez.
##
##   godot --headless --script res://tests/playtest/playtest_driver.gd -- \
##     --profil tests/playtest/profiller/ornek.json --tohum 11 --saat 4 --cikti /tmp/pt/ornek
##
## NASIL OYNAR. Şehir, pazar, lonca, taverna, avlu ve planlayıcı ekranlarının
## çağırdığı `GameSession` kapılarını aynı sırayla çağırır; kartı
## `EventEngine` çeker, seçimi `EventResolver.resolve_choice` çözer, savaşı
## `CombatEncounter` oynatır. Hiçbir yerde altın, stres, gün ya da can
## doğrudan yazılmaz.
##
## HIZLANDIRILDI. Yol sahnesi (`road_journey.gd`) açılmaz: sahnenin
## `_process` döngüsü aynı `JourneyClock` + `JourneyController` ile, aynı
## sırada burada yürütülür (saat ilerlet -> yürü -> gece -> dolan gün ->
## kamp). Sahnenin kendi yazdığı birkaç kural (gece dayanıklılık borcu,
## savaş sonrası etkiler, kuyu/han molası) sahnedeki satırlarıyla birebir
## aynalanır; ayna listesi ve dışarıda kalanlar ALTYAPI.md'de.
## Gerçek süre bir sayaçtır (`_t`): yürüyüş adımı kadar saniye, artı okuma
## ve karar süreleri (aşağıdaki açık sabitler).

# --- Süre varsayımları (gerçek saniye, 1x; bkz. ALTYAPI.md "Kalibrasyon") ---
const ADIM_SN: float = 0.5
const OKUMA_KELIME_DK: float = 200.0
const KARAR_SN: float = 6.0
const OKUMADAN_SN: float = 3.0
const SONUC_SN: float = 4.0
const SOFRA_SN: float = 8.0
const KAMP_GECIS_SN: float = 6.0
const KAMP_PANEL_SN: float = 10.0
const GUNLUK_SN: float = 8.0
const HIKAYE_SN: float = 15.0
const MERHAMET_SN: float = 7.2
const HIZ_DUGMESI_SN: float = 1.0
const SAVAS_DIZILIS_SN: float = 8.0
const SAVAS_OYUNCU_SN: float = 5.0
const SAVAS_DUSMAN_SN: float = 1.35
const SAVAS_SONUC_SN: float = 5.0
const VARIS_OZET_SN: float = 15.0
const SEHIR_GIRIS_SN: float = 25.0
const SEHIR_EKRAN_SN: float = 20.0
const SEHIR_ISLEM_SN: float = 5.0
const HARITA_SN: float = 15.0
const PLAN_SN: float = 30.0
const YENI_KERVAN_SN: float = 90.0
const HALEF_SN: float = 20.0
const KERVAN_SONU_SN: float = 30.0
const YENIDEN_PLAN_SN: float = 12.0

const KONTROL_SN: Array[int] = [600, 1800, 3600, 7200, 14400]
const MAX_YOL_GUNU: int = 150
const FORAGE_CAP: int = 4
const AGIRLIK_SINIR: float = 2.5

# --- Yol sahnesinin sabitleri (road_journey.gd ile aynı sayılar) ---
const PACE_STEADY: float = 1.0
const PACE_FAST: float = 1.35
const PACE_SLOW: float = 0.70
const EVENT_HOURS: float = 1.5
const COMBAT_HOURS: float = 2.5
const HAGGLE_HOURS: float = 1.0
const RECRUIT_HOURS: float = 0.5
const REPLAN_HOURS: float = 2.0
const PACE_FAST_STRESS_PER_DAY: int = 3
const PACE_FAST_MORALE_PER_DAY: int = -2
const PACE_SLOW_MORALE_PER_DAY: int = 2
const NIGHT_STAMINA_PER_HOUR: float = 0.6
const DARK_DANGER: float = 0.05
const TORCH_BEAST_DANGER: float = -0.03
const CAMP_WATCH_DANGER: float = 0.06
const SIGNAL_DANGER_CAP: float = 0.35
const WELL_FATIGUE_RELIEF: int = 10
const WELL_STRESS_RELIEF: int = 2
const COMBAT_LOOT_BASE: int = 25
const COMBAT_LOOT_DANGER_BONUS: int = 60
const COMBAT_VICTORY_MORALE: int = 12
const COMBAT_VICTORY_REPUTATION: int = 4
const COMBAT_VICTORY_DANGER: int = -10
const GUARD_VICTORY_REPUTATION: int = -6
const COMBAT_DEFEAT_WAGON_DAMAGE: int = 2
const COMBAT_DEFEAT_MERCHANTS: int = 1
const COMBAT_DEFEAT_MORALE: int = -20
const COMBAT_DEFEAT_GOLD: int = -40
const COMBAT_STRESS_BASE: int = 8
const COMBAT_STRESS_PER_DOWN: int = 6
const COMBAT_VICTORY_STRESS_RELIEF: int = 4
const COMBAT_DEFEAT_STRESS: int = 15
const DOWNED_STRESS_MARK: int = 9
const RETREAT_MORALE: int = -3
const RETREAT_CARGO_SHARE: float = 0.34
const HAGGLE_FAIL_MORALE: int = -8
const HAGGLE_PUSH_MORALE: int = -3
const ROAD_RECRUIT_COST_MULTIPLIER: float = 1.25
const CHIEF_EVENT_ID: String = "evt_chief_returns"
const CHIEF_FIGHT_DANGER: float = 0.55
const CHIEF_HP_PER_RANK: int = 6
const CHIEF_KINDS: Array[String] = ["bandit_leader", "toll_man"]

const VARSAYILAN_SIRA: Array[String] = [
	"eksik_el", "sat", "borc_ode", "hekim", "tamir", "taverna", "dilencilik", "dolandiricilik",
	"solen", "zincir", "kilise", "ise_alma", "zanaat", "vagon_al", "vagon_sat", "kopek",
	"avans", "kontrat", "al", "gundelik_is",
]
const EKRAN: Dictionary = {
	"eksik_el": "avlu", "tamir": "avlu", "vagon_al": "avlu", "vagon_sat": "avlu", "kopek": "avlu",
	"sat": "pazar", "al": "pazar", "borc_ode": "borc", "hekim": "kilise", "kilise": "kilise",
	"taverna": "taverna", "dilencilik": "taverna", "dolandiricilik": "taverna", "solen": "taverna",
	"zincir": "taverna", "ise_alma": "ise_alma", "zanaat": "vagon", "avans": "lonca", "kontrat": "lonca",
	"gundelik_is": "planlayici",
}

var _profil: Dictionary = {}
var _w: Dictionary = {}
var _tohum: int = 1
var _butce: float = 4.0 * 3600.0
var _cikti: String = ""
var _events: Array[GameEvent] = []

var _rng_karar := RandomNumberGenerator.new()
var _rng_yaratim := RandomNumberGenerator.new()
var _rng_savas := RandomNumberGenerator.new()

var _s: GameSession = null
var _t: float = 0.0
var _kervan_t0: float = 0.0
var _kervan_no: int = 0
var _gun_once: int = 0
var _bitti: bool = false

# yol durumu
var _j: JourneyController = null
var _clock: JourneyClock = null
var _engine: EventEngine = null
var _terrain: RouteTerrain = null
var _route_key: String = ""
var _weather: String = ""
var _pace: float = PACE_STEADY
var _hungry: bool = false
var _camping: bool = false
var _camp_ends: float = 0.0
var _camp_night: int = -99
var _light_lit: bool = false
var _light_kind: String = ""
var _light_tried: int = -99
var _night_stamina_debt: float = 0.0
var _night_fatigue_debt: float = 0.0
var _signal_danger_bonus: float = 0.0
var _current_day: int = 0
var _yol_bitti: bool = false
var _foraged: int = 0
var _replanned: bool = false
var _combat_event: GameEvent = null

# kayıt
var _satirlar: PackedStringArray = PackedStringArray()
var _gunluk: Array[String] = []
var _kritik: Array[String] = []
var _engeller: Dictionary = {}
var _kart_sayac: Dictionary = {}
var _ilkler: Dictionary = {}
var _ilkler_oturum: Dictionary = {}
var _kontroller: Array[Dictionary] = []
var _kontrol_i: int = 0
var _iyi_gunler: Array[int] = []
var _olumler: Array[Dictionary] = []
var _hal_goren: Dictionary = {}
var _hal_gecis: Dictionary = {}
var _iz_durum: Dictionary = {}
var _iz: Dictionary = {"dogan": 0, "donen": 0, "sonen": 0, "iyi": 0, "kotu": 0}
var _bedel_goren: Dictionary = {}
var _ledger_i: int = 0
var _sehir_ekranlari: Dictionary = {}
var _kese_cikis: int = 0
var _sayac: Dictionary = {
	"sefer": 0, "kart": 0, "savas": 0, "savas_kazanilan": 0, "geri_cekilme": 0, "sehir": 0,
	"ac_gece": 0, "seceneksiz": 0, "bos_tur": 0, "olu": 0, "kamp": 0, "bedel": 0,
	"ise_alim": 0, "seviye": 0, "karli_varis": 0, "borc_kapama": 0, "kayipsiz_tehdit": 0,
	"okumadan": 0, "yol_gunu": 0, "kervan_sonu": 0, "varis_devri": 0, "vagon_kaybi": 0,
	"geri_donus": 0, "yiyecek_arama": 0, "gelisim": 0, "kilit": 0,
}

func _initialize() -> void:
	TranslationServer.set_locale("tr")
	if not _args():
		quit(1)
		return
	_rng_karar.seed = hash("karar|%d" % _tohum)
	_rng_yaratim.seed = hash("yaratim|%d" % _tohum)
	_rng_savas.seed = hash("savas|%d" % _tohum)
	_events = EventCatalog.get_road_events()
	DirAccess.make_dir_recursive_absolute(_cikti)
	# Eski soy arşivi koşuya özel: kuşak izleri yalnızca bu koşunun
	# kervanlarından gelir (aynı profil + tohum = aynı çıktı).
	LineageArchive.path = _cikti.path_join("soy_arsivi.json")
	if FileAccess.file_exists(LineageArchive.path):
		DirAccess.remove_absolute(LineageArchive.path)
	print("── oyun testi: %s · tohum %d · %.2f saat -> %s" % [String(_profil.get("id", "?")), _tohum, _butce / 3600.0, _cikti])

	var kilit := 0
	while _t < _butce and kilit < 3:
		_yeni_kervan()
		var bos := 0
		while _t < _butce and not _s.is_run_over() and bos < 3:
			_sehir()
			if _s.is_run_over() or _t >= _butce:
				break
			if _sefer():
				bos = 0
			else:
				bos += 1
				_sayac["kilit"] = int(_sayac["kilit"]) + 1
				_bekle_bir_gun()
		if _s.is_run_over():
			_kervan_sonu()
			kilit = 0
		elif bos >= 3:
			_olay("engel", "kervan kilitlendi: üç gün üst üste yola çıkılamadı", "", 0, 0)
			_kritik_not("KİLİT: kervan %d şehirden çıkamıyor (%s)" % [_kervan_no, _s.current_location_id])
			_gun_once += _s.total_days_elapsed
			kilit += 1
	_kontrol_al("son")
	_yaz()
	print("── bitti: %d sn · %d kervan · %d sefer · %d kart · %d ölüm" % [
		int(_t), _kervan_no, int(_sayac["sefer"]), int(_sayac["kart"]), int(_sayac["olu"])])
	quit()

func _args() -> bool:
	var args := OS.get_cmdline_user_args()
	var profil_yolu := ""
	var saat := 4.0
	var index := 0
	while index + 1 < args.size():
		var key := String(args[index])
		var value := String(args[index + 1])
		match key:
			"--profil":
				profil_yolu = value
			"--tohum":
				_tohum = int(value)
			"--saat":
				saat = float(value)
			"--cikti":
				_cikti = value
		index += 2
	if profil_yolu.is_empty() or _cikti.is_empty():
		printerr("kullanım: -- --profil <json> --tohum <int> --saat <float> --cikti <dizin>")
		return false
	_butce = saat * 3600.0
	profil_yolu = _mutlak(profil_yolu)
	_cikti = _mutlak(_cikti)
	if not FileAccess.file_exists(profil_yolu):
		printerr("profil bulunamadı: %s" % profil_yolu)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(profil_yolu))
	if not (parsed is Dictionary):
		printerr("profil okunamadı: %s" % profil_yolu)
		return false
	_profil = parsed
	var weights: Dictionary = _profil.get("agirliklar", {})
	_w = weights.duplicate()
	return true

func _mutlak(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	if path.is_absolute_path():
		return path
	return ProjectSettings.globalize_path("res://").path_join(path)

# --- Profil okuma ------------------------------------------------------

func _pf(bolum: String, key: String, varsayilan: float) -> float:
	var section: Dictionary = _profil.get(bolum, {})
	return float(section.get(key, varsayilan))

func _ps(bolum: String, key: String, varsayilan: String) -> String:
	var section: Dictionary = _profil.get(bolum, {})
	return String(section.get(key, varsayilan))

func _pb(bolum: String, key: String, varsayilan: bool) -> bool:
	var section: Dictionary = _profil.get(bolum, {})
	return bool(section.get(key, varsayilan))

func _wt(key: String, varsayilan: float = 0.0) -> float:
	return float(_w.get(key, varsayilan))

func _okuma() -> float:
	return clampf(float(_profil.get("okuma", 1.0)), 0.0, 1.0)

func _ahlak() -> String:
	return String(_profil.get("ahlak", ""))

func _sira() -> Array[String]:
	var section: Dictionary = _profil.get("sehir", {})
	var raw: Array = section.get("sira", VARSAYILAN_SIRA)
	var out: Array[String] = []
	for entry in raw:
		out.append(String(entry))
	return out

# --- Süre ve kayıt ------------------------------------------------------

func _ilerle(saniye: float) -> void:
	_t += saniye
	if _s != null:
		# Oyunun kendi sayacı (GameState._process) burada dönmüyor; ilkler
		# aynı alana eşdeğer saniyeyle düşsün diye sürücü besliyor.
		_s.play_seconds = _t - _kervan_t0
	while _kontrol_i < KONTROL_SN.size() and _t >= float(KONTROL_SN[_kontrol_i]):
		_kontrol_al(str(KONTROL_SN[_kontrol_i]))
		_kontrol_i += 1

func _gun() -> int:
	return _gun_once + (_s.total_days_elapsed if _s != null else 0)

func _yer() -> String:
	if _s == null:
		return ""
	if _s.is_journey_active():
		return "%s>%s" % [_s.journey_origin_id, _s.journey_destination_id]
	return _s.current_location_id

func _stres_ort() -> float:
	var party := _s.get_party()
	if party.is_empty():
		return 0.0
	var total := 0
	for member in party:
		total += member.stress
	return snappedf(float(total) / float(party.size()), 0.1)

func _olay(tur: String, ne: String, neden: String = "", acik: int = -1, toplam: int = -1) -> void:
	var row := {
		"t_sn": int(round(_t)), "gun": _gun(), "kervan_no": _kervan_no,
		"kusak": _s.lineage_generation if _s != null else 0, "yer": _yer(), "tur": tur,
		"ne": ne, "neden": neden, "acik_secenek": acik, "toplam_secenek": toplam,
		"kese": _s.wallet.balance if _s != null else 0,
		"erzak": _s.get_provisions() if _s != null else 0,
		"moral": _s.caravan.morale if _s != null else 0,
		"kadro": _s.get_party().size() if _s != null else 0,
		"stres_ort": _stres_ort() if _s != null else 0.0,
	}
	_satirlar.append(JSON.stringify(row))
	if acik >= 0 and acik <= 1 and (tur == "kart" or tur == "rota"):
		_sayac["seceneksiz"] = int(_sayac["seceneksiz"]) + 1

func _engel(ne: String, reason: String, from_game: bool = false) -> void:
	var said := reason
	var spoken := tr(reason)
	if spoken != reason:
		said = spoken
	elif from_game:
		said = reason
	elif reason.begins_with("UI_"):
		said = "[çevirisi yok: %s]" % reason
	else:
		said = "[sürücü] %s" % reason
	var tally := "%s | %s" % [ne, said]
	_engeller[tally] = int(_engeller.get(tally, 0)) + 1
	_olay("engel", ne, said)

func _ilk(mark: String) -> void:
	if not _ilkler.has(mark):
		_ilkler[mark] = int(round(_t))

func _iyi(ne: String) -> void:
	_iyi_gunler.append(_gun())
	_ilk("ilk_iyi_sey")
	if _gunluk.size() < 4000:
		_gunluk.append("- %s · gün %d · iyi: %s" % [_saat_metni(_t), _gun(), ne])

func _kritik_not(text: String) -> void:
	_kritik.append("- %s · gün %d · %s" % [_saat_metni(_t), _gun(), text])

func _saat_metni(saniye: float) -> String:
	var total := int(saniye)
	return "%d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]

func _kelime(key: String) -> int:
	if key.is_empty():
		return 0
	return tr(key).split(" ", false).size()

## Parti, iz defteri ve ölüm defterindeki değişiklikleri satıra döker.
func _izle() -> void:
	if _s == null:
		return
	for member in _s.get_party():
		var id := member.character_id if not member.character_id.is_empty() else member.character_name
		var key := "%d|%s" % [_kervan_no, id]
		var onceki := String(_hal_goren.get(key, CharacterData.STATE_ALIVE))
		if member.hal != onceki:
			var gecis := "%s>%s" % [onceki, member.hal]
			_hal_gecis[gecis] = int(_hal_gecis.get(gecis, 0)) + 1
			_olay("hal_degisim", "%s: %s -> %s" % [member.character_name, onceki, member.hal])
			if member.hal == CharacterData.STATE_STONE or member.hal == CharacterData.STATE_LEAVING:
				_kritik_not("%s artık '%s'" % [member.character_name, member.hal])
		_hal_goren[key] = member.hal
		var price_day := member.last_price_day
		if _bedel_goren.has(key) and int(_bedel_goren[key]) != price_day:
			_sayac["bedel"] = int(_sayac["bedel"]) + 1
			_ilk("ilk_bedel")
		_bedel_goren[key] = price_day
	for trace in _s.traces.traces:
		var tkey := "%d|%s" % [_kervan_no, trace.id]
		var once := String(_iz_durum.get(tkey, ""))
		if once.is_empty():
			_iz["dogan"] = int(_iz["dogan"]) + 1
			_ilk("ilk_iz")
		if once != trace.durum:
			if trace.durum == Trace.STATE_RETURNED:
				_iz["donen"] = int(_iz["donen"]) + 1
				_iz["iyi" if trace.yon > 0 else "kotu"] = int(_iz["iyi" if trace.yon > 0 else "kotu"]) + 1
				_olay("iz_donus", "%s izi döndü (%s, %s)" % [trace.tur, "iyi" if trace.yon > 0 else "kötü", trace.donus],
					"doğum günü %d, kaynak %s" % [trace.dogum_gunu, trace.kaynak])
				_ilk("ilk_iz_donus")
				if trace.yon > 0:
					_iyi("iyi yönlü iz dönüşü (%s)" % trace.tur)
			elif trace.durum == Trace.STATE_FADED:
				_iz["sonen"] = int(_iz["sonen"]) + 1
		_iz_durum[tkey] = trace.durum
	var entries: Array = _s.ledger.entries
	while _ledger_i < entries.size():
		var entry: Dictionary = entries[_ledger_i]
		_ledger_i += 1
		if String(entry.get("kind", "")) != CaravanLedger.KIND_DIED:
			continue
		var how := CaravanLedger.describe(entry)
		_olumler.append({"kim": String(entry.get("name", "")), "nasil": how, "sebep": String(entry.get("cause", "")),
			"gun": _gun(), "t_sn": int(round(_t)), "kervan_no": _kervan_no})
		_sayac["olu"] = int(_sayac["olu"]) + 1
		_ilk("ilk_olum")
		_olay("olum", how)
		_kritik_not("ÖLÜM: %s" % how)
		_gelis("olum")

func _gelis(tetik: String) -> void:
	var table: Dictionary = _profil.get("gelisim", {})
	if not table.has(tetik):
		return
	var shift: Dictionary = table[tetik]
	var parts: Array[String] = []
	for key in shift:
		var name := String(key)
		_w[name] = clampf(_wt(name) + float(shift[key]), -AGIRLIK_SINIR, AGIRLIK_SINIR)
		parts.append("%s %+.2f" % [name, float(shift[key])])
	_sayac["gelisim"] = int(_sayac["gelisim"]) + 1
	_olay("gelisim", "ağırlık kaydı: %s" % tetik, ", ".join(parts))

# --- Yeni kervan, varis, kervan sonu ----------------------------------

func _yeni_kervan() -> void:
	_kervan_no += 1
	_kervan_t0 = _t
	var karakter: Dictionary = _profil.get("karakter", {})
	var stats := CharacterStats.new()
	var dagit: Dictionary = karakter.get("statlar", {})
	var kalan := 8
	var kinds: Array = CharacterStats.Kind.keys()
	for index in kinds.size():
		var name := String(kinds[index]).to_lower()
		var puan := mini(kalan, int(dagit.get(name, 0)))
		if puan > 0:
			stats.add_value(index, puan)
			kalan -= puan
	var ad := "%s %d" % [String(karakter.get("ad", "Kervanbaşı")), _kervan_no] if _kervan_no > 1 else String(karakter.get("ad", "Kervanbaşı"))
	var hero := CharacterData.create(
		ad, String(karakter.get("kultur", CultureCatalog.NOMAD)), stats, CharacterData.DEFAULT_HEIGHT_CM, 1,
		String(karakter.get("sinif", ClassCatalog.GUARD))
	)
	hero.grant_trait(TraitCatalog.roll_seed_trait(hero.stats, _rng_yaratim), 0)
	hero.heal_full()
	_s = GameSession.new(250, 20, GameSession.STARTING_WAGONS)
	_s.start_playthrough(hero, _rng_yaratim)
	_s.inherit_father_caravan()
	_s.fate_mode = bool(karakter.get("kader", false))
	var koken := String(karakter.get("koken", StartOrigins.FATHER))
	if not StartOrigins.is_unlocked(koken, LineageArchive.unlocked_origins()):
		koken = StartOrigins.FATHER
	StartOrigins.apply(_s, koken)
	LineageArchive.apply_to(_s, LineageArchive.latest())
	_s.set_meal_policy(_sofra_kipi())
	_ledger_i = _s.ledger.entries.size()
	_ilerle(YENI_KERVAN_SN)
	_olay("rota", "yeni kervan kuruldu (%s, %s, köken %s)" % [hero.culture_id, hero.class_id, koken])
	if _kervan_no > 1:
		_kritik_not("YENİ KERVAN %d: %s'de başladı" % [_kervan_no, _s.current_location_id])
	_izle()

func _kervan_sonu() -> void:
	_izle()
	_ilk("ilk_kervan_sonu")
	_sayac["kervan_sonu"] = int(_sayac["kervan_sonu"]) + 1
	_olay("olum", "kervan bitti: defter kapandı (sefer %d, gün %d)" % [_s.journeys_completed, _s.total_days_elapsed])
	_kritik_not("KERVAN SONU: %d. kervan, %d sefer, %d gün" % [_kervan_no, _s.journeys_completed, _s.total_days_elapsed])
	# Oyunun kendi çağrısı (road_journey.gd _show_run_over).
	LineageArchive.record(_s)
	for mark in _s.first_times:
		if not _ilkler_oturum.has(mark):
			_ilkler_oturum[mark] = snappedf(float(_s.first_times[mark]) + _kervan_t0, 0.1)
	_gun_once += _s.total_days_elapsed
	_ilerle(KERVAN_SONU_SN)

func _olum_sonucu(outcome: Dictionary) -> void:
	_izle()
	if bool(outcome.get("run_over", false)):
		_yol_bitti = true
		return
	if bool(outcome.get("awaiting_heir", false)):
		var raw: Array = outcome.get("heir_candidates", [])
		if raw.is_empty():
			return
		var heir: CharacterData = raw[0]
		if _okuma() >= 0.5:
			for entry in raw:
				var candidate: CharacterData = entry
				if candidate.level > heir.level:
					heir = candidate
		var kusak := _s.appoint_heir(heir)
		_sayac["varis_devri"] = int(_sayac["varis_devri"]) + 1
		_ilk("ilk_varis_devri")
		_ilerle(HALEF_SN)
		_olay("varis", "%s kervanın başına geçti (kuşak %d)" % [heir.character_name, kusak],
			"en kıdemli aday" if heir == raw[0] else "en yüksek seviyeli aday", raw.size(), raw.size())
		_kritik_not("VARİS: %s, kuşak %d" % [heir.character_name, kusak])

# --- Şehir -------------------------------------------------------------

func _ekran(ad: String) -> void:
	if _sehir_ekranlari.has(ad):
		return
	_sehir_ekranlari[ad] = true
	_ilerle(SEHIR_EKRAN_SN)

func _islem(tur_ne: String, neden: String = "") -> void:
	_ilerle(SEHIR_ISLEM_SN)
	_olay("sehir", tur_ne, neden)

func _sehir() -> void:
	_sehir_ekranlari.clear()
	_sayac["sehir"] = int(_sayac["sehir"]) + 1
	_s.people.ensure_city(_s.current_location_id, _s.total_days_elapsed)
	_s.people.greet_city(_s.current_location_id, _s.total_days_elapsed)
	_s.record_seen_prices(_s.current_location_id)
	_ilerle(SEHIR_GIRIS_SN)
	var acik := 0
	for verb in _sira():
		if _t >= _butce or _s.is_run_over():
			break
		var once := _satirlar.size()
		match verb:
			"eksik_el":
				_v_eksik_el()
			"sat":
				_v_sat()
			"borc_ode":
				_v_borc_ode()
			"hekim":
				_v_hekim()
			"tamir":
				_v_tamir()
			"taverna":
				_v_taverna()
			"dilencilik":
				_v_dilencilik()
			"dolandiricilik":
				_v_dolandiricilik()
			"solen":
				_v_solen()
			"zincir":
				_v_zincir()
			"kilise":
				_v_kilise()
			"ise_alma":
				_v_ise_alma()
			"zanaat":
				_v_zanaat()
			"vagon_al":
				_v_vagon_al()
			"vagon_sat":
				_v_vagon_sat()
			"kopek":
				_v_kopek()
			"avans":
				_v_avans()
		if _satirlar.size() > once:
			acik += 1
		_izle()
	if _s.wallet.balance < 30:
		_gelis("kese_dibi")

func _v_eksik_el() -> void:
	while _s.crew_missing > 0:
		_ekran("avlu")
		var reason := _s.get_crew_hire_block_reason()
		if not reason.is_empty():
			_engel("eksik el tutmak", reason)
			return
		if not _s.hire_crew_hand():
			return
		_islem("eksik el tutuldu")

func _satis_fiyati(item: Item, here: Location) -> int:
	return _s.capped_sell_price(item.item_id, MarketPricing.get_sell_price(
		item, here, _s.market, _s.total_days_elapsed))

func _alis_fiyati(item: Item, here: Location) -> int:
	var price := float(MarketPricing.get_buy_price(item, here, _s.market, _s.total_days_elapsed))
	price *= _s.get_buy_price_multiplier()
	price *= Scarcity.buy_factor(item.item_id, _s.scarcity_here())
	if item.item_id == GameSession.PROVISIONS_ITEM_ID:
		price *= _s.get_provision_cost_multiplier()
	price *= 1.0 - _s.get_duty_discount(DutyCatalog.TELLAL)
	return maxi(1, int(round(price)))

func _v_sat() -> void:
	var here := WorldMapData.get_location_by_id(_s.current_location_id)
	if here == null:
		return
	var dipte := _s.wallet.balance < int(_pf("sehir", "kese_dibi", 30.0))
	var entries: Array = _s.get_total_inventory_entries().duplicate()
	var sold_any := false
	for entry in entries:
		var item: Item = (entry as Dictionary).item
		if item == null or item.item_id == GameSession.PROVISIONS_ITEM_ID:
			continue
		# Okuyan oyuncu yalnızca talep edilen yere satar; okumayan ya da
		# kesesi dipte olan elindekini çıkarır.
		var talep := here.demands.has(item.item_id)
		var okur := _rng_karar.randf() < _okuma()
		if not talep and okur and not dipte:
			continue
		if not talep and here.produces.has(item.item_id) and not dipte:
			continue
		var quantity := _s.get_total_quantity(item.item_id)
		if quantity <= 0:
			continue
		_ekran("pazar")
		var shut := _s.debt_shut_out_reason()
		if not shut.is_empty():
			_engel("pazarda satmak", shut)
			return
		var block := MarketPricing.sell_block_reason(item, here)
		if not block.is_empty():
			_engel("%s satmak" % item.item_name, block)
			continue
		if _ahlak() == "merhametli" and _s.is_profiteering_sale(item.item_id):
			_islem("kriz fiyatına satmaktan vazgeçildi: %s" % item.item_name, "ahlak: merhametli")
			continue
		var unit := _satis_fiyati(item, here)
		var reserve := _s.get_city_gold_reserve()
		var affordable := int(floor(float(reserve) / float(maxi(1, unit))))
		if affordable < quantity:
			_engel("elindekinin tamamını satmak", tr("UI_MARKET_CITY_CANNOT_AFFORD") % [reserve, affordable], true)
		quantity = mini(quantity, affordable)
		if quantity <= 0:
			continue
		var total := unit * quantity
		_s.remove_from_cargo_or_bags(item.item_id, quantity)
		_s.wallet.earn(total)
		_s.record_sale(item.item_id, quantity, total)
		sold_any = true
		_islem("%d %s satıldı (%d GG)" % [quantity, item.item_name, total],
			"talep var" if talep else ("kese dipte" if dipte else "okumadan"))
	if _sayac["sefer"] > 0 and _s.wallet.balance > _kese_cikis and _kese_cikis >= 0:
		_sayac["karli_varis"] = int(_sayac["karli_varis"]) + 1
		_ilk("ilk_karli_varis")
		_iyi("kârlı varış (%d -> %d GG)" % [_kese_cikis, _s.wallet.balance])
	_kese_cikis = -1
	if sold_any:
		_izle()

func _v_borc_ode() -> void:
	var reserve := int(_pf("sehir", "borc_sonrasi_kese", 120.0))
	var debts: Array[Debt] = []
	debts.append_array(_s.debts.get_debts())
	for debt in debts:
		if debt.is_delivery() or debt.is_settled():
			continue
		var payable := mini(debt.principal, _s.wallet.balance - reserve)
		var overdue := debt.is_overdue(_s.total_days_elapsed)
		if overdue:
			payable = mini(debt.principal, maxi(0, _s.wallet.balance - 20))
		if payable <= 0:
			if overdue:
				_engel("vadesi geçmiş borcu ödemek", "kese yetmiyor")
			continue
		_ekran("borc")
		var before := _s.debts.get_debts().size()
		var paid := _s.repay_debt(debt.debt_id, payable)
		if paid <= 0:
			continue
		_islem("%s borcuna %d GG ödendi" % [debt.creditor_name, paid], "vadesi geçmiş" if overdue else "kese elverdi")
		if _s.debts.get_debts().size() < before:
			_sayac["borc_kapama"] = int(_sayac["borc_kapama"]) + 1
			_ilk("ilk_borc_kapama")
			_iyi("bir borç kapandı (%s)" % debt.creditor_name)

func _v_hekim() -> void:
	for character in _s.get_party():
		for key in character.ailments.keys():
			var id := String(key)
			if id.is_empty():
				continue
			_ekran("kilise")
			var reason := _s.get_doctor_block_reason(character, id)
			if reason.is_empty():
				if _s.treat_ailment(character, id):
					_islem("%s hekime götürüldü (%s)" % [character.character_name, id])
			else:
				_engel("%s'i iyileştirmek" % character.character_name, reason)

func _v_tamir() -> void:
	var cost := _s.get_repair_cost()
	if cost <= 0:
		return
	_ekran("avlu")
	if not _s.wallet.can_afford(cost):
		_engel("vagonu onarmak", "UI_NOT_ENOUGH_GOLD")
		return
	if _s.repair_wagons():
		_islem("vagonlar onarıldı (%d GG)" % cost)

func _v_taverna() -> void:
	_ekran("taverna")
	var reason := _s.get_lodging_block_reason()
	if not reason.is_empty():
		_engel("tavernada kalmak", reason)
		return
	# Konaklama bir gün yer: yorgun ya da gergin değilse okuyan oyuncu kalmaz.
	var yorgun := _stres_ort() >= _pf("sehir", "konaklama_stres", 25.0) or _s.caravan.morale < 60
	if not yorgun and not _pb("sehir", "her_sehirde_konakla", false):
		return
	if _s.wallet.balance - _s.get_lodging_cost() < int(_pf("sehir", "konaklama_sonrasi_kese", 40.0)):
		_engel("tavernada kalmak", "sonrasına erzak parası kalmıyor")
		return
	var heard := _s.lodge_night()
	_islem("tavernada bir gece kalındı (%d GG, %d haber)" % [_s.get_lodging_cost(), heard.size()], "stres ya da moral")

func _v_dilencilik() -> void:
	var reason := _s.get_beg_block_reason("bartender")
	if reason == "UI_BEG_NOT_HUNGRY":
		return
	_ekran("taverna")
	if not reason.is_empty():
		_engel("el açmak", reason)
		return
	if _ahlak() == "sert" and _s.wallet.balance > 20:
		return
	var alms := _s.beg_in_tavern("bartender")
	_s.mark_first(GameSession.FIRST_BEGGED)
	_islem("meyhaneciye el açıldı (%d)" % alms, "kervan aç")

func _v_dolandiricilik() -> void:
	var reason := _s.get_swindle_block_reason("patron")
	_ekran("taverna")
	if not reason.is_empty():
		_engel("bir malı yutturmak", reason)
		return
	var odds := _s.get_swindle_odds()
	var esik := _pf("sehir", "dolandiricilik_esik", 0.35)
	if _rng_karar.randf() < _okuma() and odds < esik:
		_olay("sehir", "yalan denenmedi (oran %d%%)" % int(round(odds * 100.0)), "oran eşiğin altında")
		return
	var con := _s.swindle_in_tavern("patron", "konuk_%d" % _s.total_days_elapsed)
	if bool(con.get("caught", false)):
		_islem("dolandırırken yakalanıldı", "oran %d%%" % int(round(odds * 100.0)))
	else:
		_islem("bir mal %d GG'ye yutturuldu" % int(con.get("gold", 0)), "oran %d%%" % int(round(odds * 100.0)))

func _v_solen() -> void:
	if _s.caravan.morale >= int(_pf("sehir", "solen_moral", 55.0)):
		return
	_ekran("taverna")
	var reason := _s.get_feast_block_reason()
	if not reason.is_empty():
		_engel("şölen kurmak", reason)
		return
	if _s.throw_feast():
		_islem("şölen kuruldu (%d GG)" % _s.get_feast_cost(), "moral düşük")

func _v_zincir() -> void:
	for person in _s.people.city_people(_s.current_location_id):
		var id := String(person.get("id", ""))
		if id.is_empty() or not bool(person.get("alive", false)):
			continue
		var chain := _s.people.offer_chain(id, _s.total_days_elapsed)
		if chain.is_empty():
			continue
		_ekran("taverna")
		var who := String(person.get("name", id))
		var reason := _s.get_chain_block_reason(id)
		if reason.is_empty():
			if _s.deliver_chain(id):
				_islem("%s'in istediği getirildi" % who)
		else:
			var missing := _s.get_chain_missing_text(id)
			_engel("%s'in işini bitirmek" % who, missing if not missing.is_empty() else reason, not missing.is_empty())

func _v_kilise() -> void:
	_ekran("kilise")
	var reason := _s.get_church_donation_block_reason()
	if not reason.is_empty():
		_engel("kiliseye vermek", reason)
		return
	if _s.wallet.balance < int(_pf("sehir", "bagis_kese", 150.0)):
		return
	if _s.donate_to_church():
		_islem("kiliseye verildi")

func _v_ise_alma() -> void:
	_ekran("ise_alma")
	if not _s.can_recruit():
		_engel("tayfaya biri katmak",
			"UI_RECRUIT_NO_WAGON_ROOM" if _s.get_party_capacity() < GameSession.MAX_PARTY_SIZE else "UI_RECRUIT_PARTY_FULL")
		return
	var venue := _ps("sehir", "ise_alma_yer", RecruitCatalog.VENUE_MARKET)
	var candidates := _s.get_recruit_candidates(venue)
	if candidates.is_empty():
		_engel("tayfaya biri katmak", "bu yerde aday yok (%s)" % venue)
		return
	var pick: CharacterData = null
	for candidate in candidates:
		if _s.wallet.balance - candidate.hire_cost < int(_pf("sehir", "ise_alma_sonrasi_kese", 60.0)):
			continue
		if pick == null or candidate.level > pick.level:
			pick = candidate
	if pick == null:
		_engel("tayfaya biri katmak", "UI_NOT_ENOUGH_GOLD")
		return
	if _s.hire_recruit(venue, pick):
		_sayac["ise_alim"] = int(_sayac["ise_alim"]) + 1
		_ilk("ilk_ise_alim")
		_islem("%s kervana katıldı (%d GG, seviye %d)" % [pick.character_name, pick.hire_cost, pick.level], "en yüksek seviyeli aday")
		_iyi("işe alım: %s" % pick.character_name)
	else:
		_engel("tayfaya biri katmak", "aday alınamadı (itibar ya da yer)")

func _v_zanaat() -> void:
	var last := "üretilecek bir tarif yok"
	for recipe in RecipeCatalog.get_recipes():
		var reason := _s.get_craft_block_reason_in_wagon(0, recipe)
		if reason.is_empty():
			_ekran("vagon")
			if _s.craft_in_wagon(0, recipe.recipe_id):
				_islem("vagonda üretildi: %s" % recipe.recipe_id)
			return
		last = reason
	_ekran("vagon")
	_engel("vagonda bir şey üretmek", last)

func _v_vagon_al() -> void:
	_ekran("avlu")
	var reserve := int(_pf("sehir", "vagon_sonrasi_kese", 150.0))
	if _s.can_buy_wagon() and _s.wallet.balance - _s.get_next_wagon_cost() >= reserve:
		if _s.buy_wagon():
			_islem("yeni bir vagon alındı")
			return
	if _s.can_buy_donkey() and _s.wallet.balance - _s.get_next_donkey_cost() >= reserve:
		if _s.buy_donkey():
			_islem("bir eşek alındı")
			return
	if _s.can_buy_half_wagon() and _s.wallet.balance - _s.get_next_half_wagon_cost() >= reserve:
		if _s.buy_half_wagon():
			_islem("yarım vagon alındı")
			return
	_engel("kervanı büyütmek", "vagon, eşek ya da yarım vagon için kese yetmiyor (sıradaki vagon %d GG)" % _s.get_next_wagon_cost())

func _v_vagon_sat() -> void:
	if _s.wallet.balance >= int(_pf("sehir", "kese_dibi", 30.0)):
		return
	_ekran("avlu")
	var reason := _s.get_wagon_sale_block_reason()
	if not reason.is_empty():
		_engel("vagon satmak", reason)
		return
	var value := _s.get_wagon_sale_value()
	if _s.sell_wagon():
		_islem("bir vagon satıldı (%d GG)" % value, "kese dipte")
		_kritik_not("vagon satıldı (kese dipte)")

func _v_kopek() -> void:
	if not _s.can_adopt_dog():
		return
	if _s.wallet.balance - _s.get_next_dog_cost() < int(_pf("sehir", "vagon_sonrasi_kese", 150.0)):
		return
	_ekran("avlu")
	if _s.adopt_dog():
		_islem("bir köpek alındı")

func _v_avans() -> void:
	_ekran("lonca")
	var reason := _s.get_advance_block_reason()
	if not reason.is_empty():
		_engel("loncadan mal avansı almak", reason)
		return
	var here := WorldMapData.get_location_by_id(_s.current_location_id)
	if here == null or here.produces.is_empty():
		return
	if _s.wallet.balance > int(_pf("sehir", "avans_kese", 80.0)):
		return
	var item := ItemCatalog.get_item(String(here.produces[0]))
	if item == null:
		return
	var quantity := int(_pf("sehir", "avans_adet", 5.0))
	if _s.can_take_advance(item, quantity):
		if _s.take_goods_advance(item, quantity):
			_islem("loncadan avans alındı: %d %s" % [quantity, item.item_name], "kese az")
	else:
		_engel("loncadan mal avansı almak", "bu kadarını taşıyacak yer ya da kredi yok")

## Yola çıkılamayan gün: oyuncunun elindeki gün geçirme yolları.
func _bekle_bir_gun() -> void:
	if _s.get_lodging_block_reason().is_empty():
		_s.lodge_night()
		_islem("yol açılsın diye bir gece beklendi (taverna)")
		return
	if _s.get_day_labour_block_reason().is_empty() and _s.work_a_day() > 0:
		_islem("yol açılsın diye bir gün çalışıldı")
		return
	_engel("şehirde gün geçirmek", "ne konaklayacak ne çalışacak yol var")

# --- Yola çıkış ---------------------------------------------------------

func _plan_for(destination: Location, days: int) -> CaravanPlan:
	var plan := CaravanPlan.new(destination, days, _s.get_wagon_capacity(), _s.owned_wagon_count)
	plan.caravan_party_size = _s.get_party().size()
	plan.provision_multiplier = _s.get_daily_provision_multiplier()
	plan.provision_reduction = _s.get_duty_flat_reduction(DutyCatalog.LEVAZIMCI)
	return plan

func _rota_sec(routes: Array[TravelRoute]) -> TravelRoute:
	var rota: Dictionary = _profil.get("rota", {})
	if _rng_karar.randf() >= _okuma():
		_sayac["okumadan"] = int(_sayac["okumadan"]) + 1
		var blind: TravelRoute = routes[_rng_karar.randi_range(0, routes.size() - 1)]
		_olay("rota", "%s yolu seçildi" % blind.to_location_id, "haritayı okumadan", routes.size(), routes.size())
		return blind
	var board := _s.get_contract_board()
	var best: TravelRoute = routes[0]
	var best_score := -99999.0
	var best_why := ""
	var istah := _pf("yol", "risk_istahi", 0.5)
	for candidate in routes:
		var contracts := 0
		for offer in board:
			if offer.destination_location_id == candidate.to_location_id and offer.is_open_to(_s.reputation):
				contracts += 1
		var destination := WorldMapData.get_location_by_id(candidate.to_location_id)
		var unseen := not _s.visited_location_ids.has(candidate.to_location_id)
		var days := _s.get_route_travel_days(candidate)
		var danger := _s.get_route_danger(candidate)
		var parts := {
			"kontrat": float(rota.get("kontrat", 1.5)) * float(contracts),
			"yeni_yer": float(rota.get("yeni_yer", 1.0)) * (1.0 if unseen else 0.0),
			"gun": float(rota.get("gun", -0.3)) * float(days),
			"tehlike": float(rota.get("tehlike", -1.5)) * danger * 10.0 * (1.0 - istah),
		}
		# Elindeki malı talep eden şehir.
		var talep := 0.0
		if destination != null:
			for entry in _s.get_total_inventory_entries():
				var item: Item = (entry as Dictionary).item
				if item != null and destination.demands.has(item.item_id):
					talep += 1.0
		parts["talep"] = float(rota.get("talep", 1.0)) * talep
		if bool(rota.get("erzak_kontrol", true)) and destination != null:
			var need := _plan_for(destination, days).get_provisions_shortfall(0)
			var reach := _s.get_provisions() + mini(
				int(floor(float(maxi(0, _s.wallet.balance)) / float(maxi(1, GameSession.PROVISIONS_UNIT_PRICE)))),
				maxi(0, _s.get_provision_stock()))
			if need > reach:
				parts["erzak_yetmez"] = -20.0 * float(need - reach) / float(maxi(1, need))
		var score := _rng_karar.randf() * 0.01
		var top := ""
		var top_value := 0.0
		for key in parts:
			score += float(parts[key])
			if absf(float(parts[key])) > absf(top_value):
				top_value = float(parts[key])
				top = String(key)
		if score > best_score:
			best_score = score
			best = candidate
			best_why = "%s (%+.1f)" % [top, top_value]
	_olay("rota", "%s yolu seçildi (%d gün, tehlike %d%%)" % [
		best.to_location_id, _s.get_route_travel_days(best), int(round(_s.get_route_danger(best) * 100.0))],
		best_why, routes.size(), routes.size())
	return best

func _kontrat_al(plan: CaravanPlan, destination: Location) -> void:
	var limit := int(_pf("sehir", "kontrat_sinir", 2.0))
	var taken := 0
	for offer in _s.get_contract_board():
		if offer.destination_location_id != destination.location_id:
			continue
		_ekran("lonca")
		if taken >= limit:
			break
		if not offer.is_open_to(_s.reputation):
			_engel("panodaki bir ilanı almak", "itibar yetmiyor")
			continue
		if not plan.can_add_offer(offer):
			_engel("panodaki bir ilanı almak", "yük yeri yok")
			continue
		_s.accept_contract(offer)
		plan.toggle_merchant(offer)
		taken += 1
		_islem("kontrat alındı: %s (%d GG, %d gün)" % [tr(offer.merchant_name), offer.potential_profit, offer.contract_deadline_days])

func _mal_al(origin: Location, destination: Location, reserved: float, erzak_parasi: int) -> void:
	var share := _pf("sehir", "mal_payi", 0.35)
	var budget := int(floor(float(maxi(0, _s.wallet.balance - erzak_parasi)) * share))
	if budget <= 0:
		return
	var okur := _rng_karar.randf() < _okuma()
	var wanted: Array[Item] = []
	for item_id in origin.produces:
		var item := ItemCatalog.get_item(String(item_id))
		if item == null or item.item_id == GameSession.PROVISIONS_ITEM_ID:
			continue
		if okur and destination != null and not destination.demands.has(item.item_id):
			continue
		wanted.append(item)
	if wanted.is_empty() and okur:
		_olay("sehir", "mal alınmadı", "gidilen yer buranın malını istemiyor")
		return
	for item in wanted:
		_ekran("pazar")
		var shut := _s.debt_shut_out_reason()
		if not shut.is_empty():
			_engel("pazardan mal almak", shut)
			return
		var block := MarketPricing.buy_block_reason(item, origin)
		if not block.is_empty():
			_engel("%s almak" % item.item_name, block)
			continue
		var unit := _alis_fiyati(item, origin)
		var affordable := int(floor(float(budget) / float(wanted.size()) / float(unit)))
		var by_space := int(floor(maxf(0.0, _s.get_cargo_space_remaining() - reserved) / maxf(0.1, item.unit_weight)))
		var stock := _s.get_market_stock(item.item_id)
		if affordable > 0 and by_space <= 0:
			_engel("mal almak", "vagonda yer kalmadı")
			continue
		if affordable > 0 and stock == 0:
			_engel("mal almak", "pazarda stok yok")
			continue
		var quantity := mini(affordable, by_space)
		if stock >= 0:
			quantity = mini(quantity, stock)
		if quantity <= 0:
			continue
		var subtotal := MarketPricing.bulk_total(unit, quantity)
		if not _s.wallet.can_afford(subtotal):
			continue
		if _s.add_to_cargo(item, quantity):
			_s.consume_stock(item.item_id, quantity, subtotal)
			_s.wallet.spend(subtotal)
			_islem("%d %s alındı (%d GG)" % [quantity, item.item_name, subtotal],
				"gidilen yer istiyor" if okur else "okumadan: buranın malı")

func _erzak_al(plan: CaravanPlan) -> void:
	var margin := _pf("sehir", "erzak_payi", 1.2)
	if _rng_karar.randf() >= _okuma():
		# Planlayıcıdaki sayıyı okumayan oyuncu göz kararı alır.
		margin *= _rng_karar.randf_range(0.5, 1.1)
	var shortfall := plan.get_provisions_shortfall(_s.get_provisions())
	var camp_extra := 0
	if _ps("yol", "kamp", "her_gece") == "her_gece":
		# Kamp günü uzatır: planlayıcının saydığı gün yürüyüş günüdür.
		camp_extra = int(ceil(float(plan.travel_days) * 0.5 * float(_s.get_daily_provision_consumption()) * (margin - 1.0)))
	var wanted := int(ceil(float(shortfall) * margin)) + camp_extra
	if shortfall <= 0 and margin <= 1.0:
		return
	_ekran("planlayici")
	if wanted > 0:
		var got := _s.buy_provisions(wanted)
		if got > 0:
			_islem("%d erzak alındı" % got, "planlayıcı açığı %d" % shortfall)
		elif shortfall > 0:
			_engel("erzak almak", "şehrin erzak stoğu bitti" if _s.get_provision_stock() == 0 else "UI_NOT_ENOUGH_GOLD")
	if plan.get_provisions_shortfall(_s.get_provisions()) <= 0:
		return
	if _sira().has("gundelik_is"):
		var worked := 0
		var cap := int(_pf("sehir", "gundelik_is_gun", 3.0))
		while worked < cap and plan.get_provisions_shortfall(_s.get_provisions()) > 0:
			var reason := _s.get_day_labour_block_reason()
			if not reason.is_empty():
				_engel("şehirde bir gün çalışmak", reason)
				break
			var earned := _s.work_a_day()
			if earned <= 0:
				break
			worked += 1
			_s.buy_provisions(plan.get_provisions_shortfall(_s.get_provisions()))
			_islem("bir gün çalışıldı (%d GG)" % earned, "erzak açığı")
	if plan.get_provisions_shortfall(_s.get_provisions()) > 0:
		_olay("sehir", "erzak eksik; yine de yola çıkılıyor (açık %d)" % plan.get_provisions_shortfall(_s.get_provisions()),
			"başka çıkış yok")

func _sefer() -> bool:
	var origin := WorldMapData.get_location_by_id(_s.current_location_id)
	if origin == null:
		return false
	var open_routes: Array[TravelRoute] = []
	var kapali := 0
	for candidate in WorldMapData.get_routes_from(_s.current_location_id):
		if _s.is_route_open(candidate) and not _s.is_banned(candidate.to_location_id):
			open_routes.append(candidate)
		else:
			kapali += 1
	_ilerle(HARITA_SN)
	if open_routes.is_empty():
		_engel("yola çıkmak", "buradan açık bir yol yok (%d kapalı)" % kapali)
		return false
	var route := _rota_sec(open_routes)
	var destination := WorldMapData.get_location_by_id(route.to_location_id)
	if destination == null:
		return false
	var days := _s.get_route_travel_days(route)
	var danger := _s.get_route_danger(route)
	var shortcut := _pb("yol", "kisayol", false) and RouteTerrain.shortcut_available(days)
	if shortcut:
		danger = RouteTerrain.shortcut_danger(danger)
		days = RouteTerrain.shortcut_days(days)
	var plan := _plan_for(destination, days)
	plan.cargo_room = _s.get_cargo_space_remaining()
	_kese_cikis = _s.wallet.balance
	var sira := _sira()
	if sira.has("kontrat"):
		_kontrat_al(plan, destination)
	var erzak_parasi := plan.get_provisions_shortfall(_s.get_provisions()) * GameSession.PROVISIONS_UNIT_PRICE
	if sira.has("al"):
		_mal_al(origin, destination, plan.get_contract_cargo_load(), erzak_parasi)
	_s.set_meal_policy(_sofra_kipi())
	_erzak_al(plan)
	_ilerle(PLAN_SN)
	if _s.is_run_over():
		return false
	_s.depart_with_contracts(plan.get_selected_offers())
	_s.start_journey(destination.location_id, days, danger, plan, shortcut)
	_olay("rota", "yola çıkıldı: %s -> %s (%d gün%s)" % [origin.location_id, destination.location_id, days,
		", kısayol" if shortcut else ""], "erzak %d, günlük %d" % [_s.get_provisions(), _s.get_daily_provision_consumption()])
	_yol()
	return true

# --- Yol: road_journey.gd'nin döngüsü ----------------------------------

func _sofra_kipi() -> String:
	match _ps("yol", "sofra", "duruma_gore"):
		"herkes":
			return GameSession.MEAL_MODE_ALL
		"ekip":
			return GameSession.MEAL_MODE_PARTY_ONLY
		"kendim":
			return GameSession.MEAL_MODE_SELF_ONLY
	if _s == null:
		return GameSession.MEAL_MODE_ALL
	var have := _s.get_provisions()
	if have >= _s.daily_provisions_for_mode(GameSession.MEAL_MODE_ALL):
		return GameSession.MEAL_MODE_ALL
	if _ahlak() == "merhametli":
		return GameSession.MEAL_MODE_ALL
	if have >= _s.daily_provisions_for_mode(GameSession.MEAL_MODE_PARTY_ONLY):
		return GameSession.MEAL_MODE_PARTY_ONLY
	return GameSession.MEAL_MODE_SELF_ONLY if _ahlak() == "sert" else GameSession.MEAL_MODE_PARTY_ONLY

func _terrain_from() -> String:
	return _s.journey_origin_id if _j.terrain_from.is_empty() else _j.terrain_from

func _build_terrain() -> void:
	_terrain = RouteTerrain.build(_route_key, _j.journey_length_days, _terrain_from(), _s.journey_season(), _s.journey_shortcut)

func _biome() -> String:
	return "" if _terrain == null else _terrain.biome_at(_j.terrain_day())

func _refresh_weather() -> void:
	var biome := ArtPalette.FALLBACK_BIOME
	var climate := ""
	if _terrain != null:
		biome = _terrain.biome_at(_j.terrain_day())
		climate = String(_terrain.segment_at(_j.terrain_day()).get("climate", ""))
	_weather = RouteWeather.at(_route_key, _s.total_days_elapsed + 1, biome)
	_s.set_road_sky(_route_key, _s.total_days_elapsed + 1, biome, climate, _weather)

func _is_dark() -> bool:
	return JourneyClock.darkness_for_hour(_clock.get_hour_of_day()) >= 0.5

func _weathered_danger() -> float:
	var base := _s.danger_level
	var weathered := clampf(base + RouteWeather.danger_delta(_weather) * (1.0 - base), 0.0, 1.0)
	var night := 0.0
	if _is_dark() and not _camping:
		night = DARK_DANGER if not _light_lit else (TORCH_BEAST_DANGER if _light_kind == GameSession.LIGHT_TORCH else 0.0)
	return clampf(weathered + (_signal_danger_bonus + night) * (1.0 - weathered), 0.0, 1.0)

func _yol() -> void:
	_j = JourneyController.new()
	_clock = JourneyClock.new()
	_engine = EventEngine.new(_events, hash("%s|%s|%d" % [
		_s.journey_origin_id, _s.journey_destination_id, _s.total_days_elapsed]))
	_engine.director = RoadDirector.new()
	_engine.director.heavy_scale = _s.get_event_severity()
	_j.journey_length_days = maxi(1, _s.journey_total_days)
	_j.days_covered = 0.0
	_route_key = RouteConditions.route_key(_s.journey_origin_id, _s.journey_destination_id)
	_j.lay_road(_s.journey_origin_id, _s.journey_destination_id, _route_key, _j.journey_length_days)
	_build_terrain()
	_pace = PACE_STEADY
	_hungry = false
	_camping = false
	_camp_night = -99
	_light_lit = false
	_light_kind = ""
	_light_tried = -99
	_night_stamina_debt = 0.0
	_night_fatigue_debt = 0.0
	_signal_danger_bonus = 0.0
	_current_day = 0
	_yol_bitti = false
	_foraged = 0
	_replanned = false
	_refresh_weather()
	var varildi := false
	var gun_basi := _s.total_days_elapsed
	while _t < _butce and not _yol_bitti and not _s.is_run_over():
		if _s.total_days_elapsed - gun_basi > MAX_YOL_GUNU:
			_olay("engel", "yol bitmiyor: %d gündür yoldayız" % MAX_YOL_GUNU, "sürücü koruması")
			_kritik_not("KİLİT: sefer %d günde bitmedi" % MAX_YOL_GUNU)
			break
		var hours := _clock.advance(ADIM_SN)
		_ilerle(ADIM_SN)
		if not _camping:
			_pace = _tempo()
			_walk(hours)
			if _j.has_arrived():
				varildi = true
				break
		_tick_night(hours)
		while not _yol_bitti and not _s.is_run_over() and _clock.take_one_day():
			_run_day()
		if _yol_bitti or _s.is_run_over():
			break
		if _j.has_arrived():
			varildi = true
			break
		_update_camp()
	if _s.is_run_over() or not varildi:
		return
	_var()

func _tempo() -> float:
	var wanted := _ps("yol", "tempo", "sabit")
	if wanted == "duruma_gore":
		var daily := maxi(1, _s.get_daily_provision_consumption())
		var days_food := float(_s.get_provisions()) / float(daily)
		if days_food < float(_s.journey_days_remaining) and _s.can_push_pace():
			wanted = "hizli"
		elif _s.caravan.morale < 35 and days_food > float(_s.journey_days_remaining) * 1.5:
			wanted = "yavas"
		else:
			wanted = "sabit"
	if wanted == "hizli":
		return PACE_FAST if _s.can_push_pace() else PACE_STEADY
	if wanted == "yavas":
		return PACE_SLOW
	return PACE_STEADY

func _walk(hours: float) -> void:
	if hours <= 0.0 or is_zero_approx(_pace):
		return
	var terrain_factor := 1.0 if _terrain == null else _terrain.speed_factor_at(_j.terrain_day())
	var effective := JourneyController.effective_rate(
		_pace, RouteWeather.pace_multiplier(_weather), _s.get_caravan_theoretical_speed(), terrain_factor, _hungry)
	_j.walk(effective, hours)
	_j.sync_days_remaining(_s)
	_s.set_road_position(_route_key, _terrain_from(), _j.terrain_day(), maxi(1, _j.terrain_days))

func _tick_night(hours: float) -> void:
	if _light_lit and not _is_dark():
		_light_lit = false
		_light_kind = ""
	if not _is_dark() or _camping or _light_lit:
		return
	if _pb("yol", "isik", true) and _light_tried != _s.total_days_elapsed:
		_light_tried = _s.total_days_elapsed
		var kind := GameSession.LIGHT_LANTERN if _s.get_light_block_reason(GameSession.LIGHT_LANTERN).is_empty() else GameSession.LIGHT_TORCH
		var reason := _s.get_light_block_reason(kind)
		if reason.is_empty():
			if _s.light_for_night(kind):
				_light_kind = kind
				_light_lit = true
				_olay("kamp", "gece için ışık yakıldı (%s)" % kind, "karanlıkta yürüyüş")
				return
		else:
			_engel("gece ışık yakmak", reason)
	_night_stamina_debt += NIGHT_STAMINA_PER_HOUR * hours
	var whole := int(_night_stamina_debt)
	if whole > 0:
		_night_stamina_debt -= whole
		# road_journey.gd _tick_night'ın kendi satırı (sahnenin kuralı).
		_s.caravan.stamina = maxi(0, _s.caravan.stamina - whole)
	_night_fatigue_debt = _s.accrue_night_fatigue(_night_fatigue_debt + GameSession.FATIGUE_NIGHT_PER_HOUR * hours)

func _run_day() -> void:
	_current_day += 1
	_sayac["yol_gunu"] = int(_sayac["yol_gunu"]) + 1
	_refresh_weather()
	var bite := RouteWeather.morale_bite(_weather)
	if bite != 0:
		_s.caravan.change_morale(bite)
	var pushing := is_equal_approx(_pace, PACE_FAST)
	_s.caravan.apply_stamina_drift(pushing)
	_s.apply_pace_fatigue_day(pushing)
	if pushing and not _s.can_push_pace():
		_pace = PACE_STEADY
		_olay("engel", "hızlı tempo sürdürülemedi", tr("UI_ROAD_PACE_EXHAUSTED"))
	if pushing:
		_s.change_stress(PACE_FAST_STRESS_PER_DAY)
		_s.caravan.change_morale(PACE_FAST_MORALE_PER_DAY)
	elif is_equal_approx(_pace, PACE_SLOW):
		_s.caravan.change_morale(PACE_SLOW_MORALE_PER_DAY)
	var relief := RoadAttention.stress_relief_per_day(RoadAttention.ZONE_FRONT)
	if relief > 0:
		_s.change_stress(-relief)

	var wagons_before := _s.caravan.wagon_count
	_s.advance_day()
	if not _s.pending_trace_card.is_empty():
		_engine.unlock_event(_s.pending_trace_card)
		_s.pending_trace_card = ""

	_yiyecek_ara()
	var mode := _s.meal_policy_mode
	var selected: Array[CharacterData] = _s.get_meal_policy_selected()
	if _s.meal_needs_decision():
		mode = _sofra_kipi()
		selected = []
		_s.set_meal_policy(mode, selected)
		_ilerle(SOFRA_SN)
		_olay("sofra", "akşam sofrası: %s" % mode, "erzak %d, günlük ihtiyaç %d" % [
			_s.get_provisions(), _s.get_daily_provision_consumption()], 3, 4)
	var result := _s.apply_meal_distribution(mode, selected)
	var hungry_names: Array = result.get("hungry_names", [])
	_hungry = not hungry_names.is_empty() or bool(result.get("crew_hungry", false))
	if _hungry:
		_sayac["ac_gece"] = int(_sayac["ac_gece"]) + 1
		_ilk("ilk_ac_gece")
		_gelis("aclik")
		if int(_sayac["ac_gece"]) == 1:
			_kritik_not("ilk aç gece")
	for name_text in (result.get("crew_deserted_names", []) as Array):
		_olay("olum", "%s gece yola düştü (ekipten ayrıldı)" % String(name_text))
	if not (result.get("cargo_left_behind", []) as Array).is_empty():
		_olay("engel", "sürülemeyen vagonun yükü yolda kaldı", "ekip eksik")
	var death_outcome: Dictionary = result.get("death_outcome", {})
	if not (death_outcome.get("dead_names", []) as Array).is_empty():
		_olum_sonucu(death_outcome)
	_izle()
	if _yol_bitti or _s.is_run_over():
		return
	_after_meal()
	if _s.caravan.wagon_count < wagons_before:
		_vagon_kaybi()
	_aclikta_don()

func _vagon_kaybi() -> void:
	_sayac["vagon_kaybi"] = int(_sayac["vagon_kaybi"]) + 1
	_ilk("ilk_vagon_kaybi")
	_kritik_not("vagon kaybı")
	_gelis("vagon_kaybi")

func _yiyecek_ara() -> void:
	if not _pb("yol", "yiyecek_ara", true) or _foraged >= FORAGE_CAP:
		return
	if _s.get_provisions() >= _s.get_daily_provision_consumption() * 2:
		return
	var reason := _s.get_forage_block_reason()
	if not reason.is_empty():
		_engel("yolda yiyecek aramak", reason)
		return
	var found := _s.forage_a_day(_biome())
	if found <= 0:
		return
	_foraged += 1
	_sayac["yiyecek_arama"] = int(_sayac["yiyecek_arama"]) + 1
	_ilerle(SEHIR_ISLEM_SN)
	_olay("kamp", "yolda yiyecek arandı: %d erzak" % found, "erzak iki günün altında")

func _aclikta_don() -> void:
	if _replanned or _ps("yol", "sapma", "asla") != "aclikta":
		return
	if not _hungry or _s.get_provisions() > 0:
		return
	if _s.get_days_travelled() >= _s.journey_days_remaining:
		return
	if not _s.turn_back():
		return
	_replanned = true
	_j.start_return_leg(_s.journey_total_days)
	_clock.consume_hours(REPLAN_HOURS)
	_j.sync_days_remaining(_s)
	_sayac["geri_donus"] = int(_sayac["geri_donus"]) + 1
	_ilerle(YENIDEN_PLAN_SN)
	_olay("rota", "geri dönüldü: %s" % _s.journey_destination_id, "erzak bitti, varış geri dönüşten uzak", 2, 2)
	_kritik_not("yoldan geri dönüldü (açlık)")
	if not _s.caravan.original_merchant_names.is_empty():
		var diversion := EventCatalog.get_event("evt_route_diversion")
		if diversion != null:
			_present(diversion)

func _after_meal() -> void:
	var context := _s.build_event_context()
	var segment: Dictionary = {} if _terrain == null else _terrain.segment_at(_j.terrain_day())
	var stop := String(segment.get("stop", RouteTerrain.STOP_NONE))
	context.merge(EventResolver.stop_context(stop, String(segment.get("stop_state", ""))), true)
	_use_stop(segment)
	if stop == RouteTerrain.STOP_FORD and _terrain != null:
		var water_biome := _terrain.biome_at(minf(float(_j.terrain_days), _j.terrain_day() + 0.5))
		context["water_level"] = float(RouteFord.water_level(_route_key, _s.total_days_elapsed + 1, water_biome))
	context.merge(EventResolver.biome_context(_biome()), true)
	var event := _engine.roll_for_day(_current_day, context)
	if event == null:
		_sayac["bos_tur"] = int(_sayac["bos_tur"]) + 1
		return
	_present(event)

func _use_stop(segment: Dictionary) -> void:
	var stop := String(segment.get("stop", RouteTerrain.STOP_NONE))
	if stop != RouteTerrain.STOP_WELL and stop != RouteTerrain.STOP_SERAI:
		return
	var stop_day := float(segment.get("to_day", 0.0))
	if absf(_j.terrain_day() - stop_day) > 1.0 or _j.used_stop_days.has(stop_day):
		return
	_j.used_stop_days.append(stop_day)
	if stop == RouteTerrain.STOP_WELL:
		for member in _s.get_party():
			member.change_fatigue(-WELL_FATIGUE_RELIEF)
		_s.change_stress(-WELL_STRESS_RELIEF)
		_olay("kamp", "kuyu başında mola", "yol üstü durak")
		return
	var state := String(segment.get("stop_state", RouteTerrain.SERAI_OPEN))
	if state == RouteTerrain.SERAI_OPEN:
		for member in _s.get_party():
			member.change_fatigue(-WELL_FATIGUE_RELIEF)
		_s.change_stress(-GameSession.CAMP_STRESS_RELIEF)
		_s.hear_price_rumor(_s.journey_destination_id)
		_olay("kamp", "kervansarayda mola", "yol üstü durak")
	else:
		_olay("kamp", "kervansaray: %s" % state, "yol üstü durak")

# --- Kart ---------------------------------------------------------------

func _etki_uygula(effects: Array[EventEffect]) -> EventEffectApplier.Result:
	var before := _s.journey_days_remaining
	var result := EventEffectApplier.apply(effects, _s)
	var delta := _s.journey_days_remaining - before
	if delta != 0:
		_j.journey_length_days = maxi(1, _j.journey_length_days + delta)
	_j.sync_days_remaining(_s)
	return result

func _present(event: GameEvent) -> void:
	_s.log_beat(GameSession.BEAT_LOG_INFO, "card:" + event.event_id)
	_clock.consume_hours(EVENT_HOURS)
	_engine.mark_fired(event, _current_day)
	if event.event_id == CHIEF_EVENT_ID:
		_s.people.active_chief = _s.people.chief_in(_s.journey_region())
	if not EventCatalog.PLACE_EVENTS.values().has(event.event_id):
		_s.people.active_place_name = ""
	_sayac["kart"] = int(_sayac["kart"]) + 1
	_kart_sayac[event.event_id] = int(_kart_sayac.get(event.event_id, 0)) + 1
	_ilk("ilk_kart")
	_combat_event = event
	var wagons_before := _s.caravan.wagon_count
	if not event.immediate_effects.is_empty():
		_side(_etki_uygula(event.immediate_effects))
	var context := _s.build_event_context()
	var available: Array[EventChoice] = []
	for choice in event.choices:
		if choice.is_available(context):
			available.append(choice)
		else:
			_engel("kartta kapalı seçenek (%s)" % event.event_id, choice.unavailable_text_key)
	if available.is_empty():
		_olay("kart", "%s: seçilecek seçenek yok" % event.event_id, "", 0, event.choices.size())
		return
	var okudu := _rng_karar.randf() < _okuma()
	var best: EventChoice = available[0]
	var neden := ""
	if not okudu:
		best = available[_rng_karar.randi_range(0, available.size() - 1)]
		neden = "okumadan seçti"
		_sayac["okumadan"] = int(_sayac["okumadan"]) + 1
		_ilerle(OKUMADAN_SN)
	else:
		var best_score := -99999.0
		for choice in available:
			var katki := {}
			var score := _puan(choice, katki) + _rng_karar.randf() * 0.01
			if score > best_score:
				best_score = score
				best = choice
				neden = _katki_metni(katki, score)
		var words := _kelime(event.title_key) + _kelime(event.text_key)
		for choice in event.choices:
			words += _kelime(choice.text_key)
		_ilerle(float(words) / OKUMA_KELIME_DK * 60.0 + KARAR_SN)
	_s.note_beat(GameSession.BEAT_EVENT, [tr(event.title_key)])
	_s.log_beat(GameSession.BEAT_LOG_DECISION, "card:" + event.event_id)
	var resolution := EventResolver.resolve_choice(_s, _engine, event, best, _etki_uygula)
	var sonuc := ""
	if resolution.outcome != null:
		sonuc = " => %s" % tr(resolution.outcome.text_key).left(90)
		_ilerle(float(_kelime(resolution.outcome.text_key)) / OKUMA_KELIME_DK * 60.0 + SONUC_SN)
	_olay("kart", "%s: %s%s" % [event.event_id, tr(best.text_key).left(90), sonuc], neden, available.size(), event.choices.size())
	if not resolution.levels_gained.is_empty():
		_seviye(resolution.levels_gained)
	for result in resolution.get_results():
		_side(result)
		if _yol_bitti or _s.is_run_over():
			break
	_combat_event = null
	if _s.caravan.wagon_count < wagons_before:
		_vagon_kaybi()
	_izle()

func _seviye(levels: Dictionary) -> void:
	_sayac["seviye"] = int(_sayac["seviye"]) + levels.size()
	_ilk("ilk_seviye")
	_iyi("seviye: %s" % ", ".join(PackedStringArray(levels.keys())))

func _side(result: EventEffectApplier.Result) -> void:
	if result == null:
		return
	for event_id in result.unlocked_event_ids:
		_engine.unlock_event(event_id)
	if not result.combat_requests.is_empty():
		var kind := "bandit"
		if not result.combat_kinds.is_empty():
			kind = result.combat_kinds[0]
		var ambushed := not result.combat_ambushes.is_empty() and bool(result.combat_ambushes[0])
		_savas(int(result.combat_requests[0]), kind, ambushed)
		return
	if not result.recruit_requests.is_empty():
		_yol_ise_alma()
		return
	if not result.haggling_requests.is_empty():
		_yol_pazarlik(int(result.haggling_requests[0]))

func _katki_ekle(katki: Dictionary, key: String, value: float) -> float:
	katki[key] = float(katki.get(key, 0.0)) + value
	return value

func _katki_metni(katki: Dictionary, score: float) -> String:
	var top := ""
	var top_value := 0.0
	for key in katki:
		if absf(float(katki[key])) > absf(top_value):
			top_value = float(katki[key])
			top = String(key)
	if top.is_empty():
		return "etkisi görünmeyen seçenek (puan %.2f)" % score
	return "%s (%+.2f), toplam %.2f" % [top, top_value, score]

func _puan(choice: EventChoice, katki: Dictionary) -> float:
	var total := _etki_puani(choice.effects, 1.0, katki)
	var weight_sum := 0.0
	for outcome in choice.outcomes:
		weight_sum += maxf(0.01, outcome.weight)
	if weight_sum > 0.0:
		for outcome in choice.outcomes:
			total += _etki_puani(outcome.effects, maxf(0.01, outcome.weight) / weight_sum, katki)
		total += _katki_ekle(katki, "risk", _wt("risk") * minf(1.0, float(choice.outcomes.size()) * 0.5)
			* (0.5 + _pf("yol", "risk_istahi", 0.5)))
	var tone := EventEngine.choice_tone(choice)
	if tone == EventEngine.TONE_MERCY:
		total += _katki_ekle(katki, "merhamet", _wt("merhamet") * 2.0 + (1.5 if _ahlak() == "merhametli" else 0.0))
	elif tone == EventEngine.TONE_HARSH:
		total += _katki_ekle(katki, "sert", _wt("sert") * 2.0 + (1.5 if _ahlak() == "sert" else 0.0))
	return total

func _etki_puani(effects: Array[EventEffect], share: float, katki: Dictionary) -> float:
	var total := 0.0
	for effect in effects:
		var amount := float(effect.amount)
		var key := ""
		var value := 0.0
		match effect.type:
			EventEffect.Type.GOLD:
				key = "altin"
				value = amount * 0.02 * _wt("altin")
			EventEffect.Type.PROVISIONS:
				key = "erzak"
				value = amount * 0.25 * _wt("erzak")
			EventEffect.Type.MORALE:
				key = "moral"
				value = amount * 0.1 * _wt("moral")
			EventEffect.Type.STRESS:
				key = "stres"
				value = amount * 0.1 * _wt("stres")
			EventEffect.Type.REPUTATION, EventEffect.Type.FACTION:
				key = "itibar"
				value = amount * 0.5 * _wt("itibar")
			EventEffect.Type.PARTY_HP:
				key = "insan"
				value = amount * 0.08 * _wt("insan")
			EventEffect.Type.TRAVEL_DAYS:
				key = "zaman"
				value = amount * 0.6 * _wt("zaman")
			EventEffect.Type.DANGER:
				key = "risk"
				value = amount * 0.05 * _wt("risk")
			EventEffect.Type.TRIGGER_COMBAT, EventEffect.Type.TRIGGER_AMBUSH:
				key = "savas"
				value = 3.0 * _wt("savas")
			EventEffect.Type.WAGON_LOSE:
				key = "vagon"
				value = -6.0 * _wt("vagon", 1.0)
			EventEffect.Type.WAGON_DAMAGE:
				key = "vagon"
				value = -1.5 * _wt("vagon", 1.0)
			EventEffect.Type.WAGON_REPAIR:
				key = "vagon"
				value = 1.5 * _wt("vagon", 1.0)
			EventEffect.Type.LEAVE_BEHIND, EventEffect.Type.CUT_HAND:
				key = "insan"
				value = -4.0 * maxf(0.3, _wt("insan"))
			EventEffect.Type.TRIGGER_RECRUIT:
				key = "insan"
				value = 1.5 * _wt("insan")
			EventEffect.Type.ITEM_ADD, EventEffect.Type.GRANT_EQUIPMENT, EventEffect.Type.GRANT_OUTFIT:
				key = "mal"
				value = 0.6 * _wt("mal", 0.5) * maxf(1.0, amount)
			EventEffect.Type.ITEM_REMOVE:
				key = "mal"
				value = -0.6 * _wt("mal", 0.5) * maxf(1.0, amount)
			EventEffect.Type.CARGO_PLUNDER, EventEffect.Type.DOCUMENT_LOSE:
				key = "mal"
				value = -3.0 * _wt("mal", 0.5)
			EventEffect.Type.MERCHANT_LEAVE, EventEffect.Type.BAN_LOCATION, EventEffect.Type.TRADE_STAIN:
				key = "itibar"
				value = -2.0 * maxf(0.2, _wt("itibar"))
			EventEffect.Type.DEBT_SETTLE:
				key = "altin"
				value = 1.0 * _wt("altin")
			EventEffect.Type.CITY_MORALE:
				key = "merhamet"
				value = amount * 0.1 * _wt("merhamet")
			EventEffect.Type.BEDEL:
				key = "bedel"
				value = 3.0 * _wt("bedel")
			EventEffect.Type.IZ_BIRAK:
				key = "iz"
				var tur := effect.text_value.split("|")[0].strip_edges()
				var yon := 0.3
				if tur == Trace.TYPE_GRATITUDE:
					yon = 1.0
				elif tur == Trace.TYPE_GRUDGE or tur == Trace.TYPE_BLOOD_DEBT:
					yon = -1.0
				value = 1.5 * yon * _wt("iz")
			EventEffect.Type.SOZ:
				key = "iz"
				value = 1.0 * _wt("soz", _wt("iz"))
		if not key.is_empty():
			total += _katki_ekle(katki, key, value * share)
	return total

func _yol_ise_alma() -> void:
	_clock.consume_hours(RECRUIT_HOURS)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d|%d" % [_tohum, _current_day + _s.total_days_elapsed * 31])
	var candidates := RecruitCatalog.build_candidates(
		RecruitCatalog.VENUE_TAVERN, rng, _s.get_player_character().level,
		RecruitCatalog.get_world_growth_levels(_s.journeys_completed))
	if candidates.is_empty() or not _s.can_recruit():
		_engel("yoldaki yolcuyu almak", tr("UI_ROAD_TRAVELLER_LEFT"), true)
		return
	var candidate: CharacterData = candidates[0]
	candidate.hire_cost = int(round(candidate.hire_cost * ROAD_RECRUIT_COST_MULTIPLIER))
	_ilerle(KARAR_SN + 6.0)
	if not _s.wallet.can_afford(candidate.hire_cost):
		_engel("yoldaki yolcuyu almak", "UI_NOT_ENOUGH_GOLD")
		return
	if _wt("insan") < 0.3:
		_olay("kart", "yoldaki yolcu geri çevrildi", "insan ağırlığı düşük", 2, 2)
		return
	if _s.recruit(candidate):
		_sayac["ise_alim"] = int(_sayac["ise_alim"]) + 1
		_ilk("ilk_ise_alim")
		_olay("kart", "yoldaki yolcu kervana katıldı: %s (%d GG)" % [candidate.character_name, candidate.hire_cost], "insan", 2, 2)
		_iyi("yolda işe alım: %s" % candidate.character_name)

func _yol_pazarlik(max_price: int) -> void:
	_clock.consume_hours(HAGGLE_HOURS)
	var haggle := HagglingSession.new(
		float(max_price), 0.5, 0.3, _s.get_best_effective_stat(CharacterStats.Kind.CHARISMA), 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("haggle|%f|%f" % [float(max_price), 0.3])
	_ilerle(KARAR_SN * 2.0)
	var pushed := false
	if haggle.can_push() and (_rng_karar.randf() >= _okuma() or haggle.push_odds() >= 0.5 - _pf("yol", "risk_istahi", 0.5) * 0.3):
		pushed = true
		if not haggle.push(rng):
			_s.caravan.change_morale(HAGGLE_PUSH_MORALE)
	if haggle.state == HagglingSession.State.ANGER_QUIT:
		_s.spend_or_owe(max_price)
		_s.caravan.change_morale(HAGGLE_FAIL_MORALE)
		_olay("kart", "pazarlık bozuldu: %d GG ödendi" % max_price, "direnildi" if pushed else "", 2, 2)
		return
	if haggle.state == HagglingSession.State.OFFERED:
		haggle.accept()
	var price := int(round(haggle.final_price)) if haggle.final_price > 0.0 else int(round(haggle.current_price()))
	_s.spend_or_owe(price)
	_olay("kart", "pazarlık: %d GG ödendi (tavan %d)" % [price, max_price], "direnildi" if pushed else "direnmeden kabul", 2, 2)

# --- Savaş: CombatPanel + road_journey._on_combat_finished --------------

func _savas(danger_percent: int, kind: String, ambushed: bool) -> void:
	var danger := _weathered_danger() if danger_percent <= 0 else float(danger_percent) / 100.0
	var chief_fight := ""
	if _combat_event != null and _combat_event.event_id == CHIEF_EVENT_ID and not _s.people.active_chief.is_empty():
		chief_fight = _s.people.active_chief
		danger = maxf(danger, CHIEF_FIGHT_DANGER)
	_s.log_beat(GameSession.BEAT_LOG_COMBAT_START, kind)
	var ordered := _s.get_remembered_combat_order()
	var party: Array[CharacterData] = []
	for character in ordered:
		if _s.is_in_remembered_roster(character) and party.size() < CombatEncounter.MAX_SIDE_SIZE:
			party.append(character)
	if party.is_empty():
		for character in ordered:
			if party.size() < CombatEncounter.MAX_SIDE_SIZE:
				party.append(character)
	if party.is_empty():
		return
	_s.remember_combat_roster(party)
	_clock.consume_hours(COMBAT_HOURS)
	CombatUnit.deathblow_offset = _s.get_deathblow_offset()

	var units: Array[CombatUnit] = []
	var position := 1
	var level_total := 0
	for character in party:
		units.append(CombatUnit.from_character(character, position, character.is_stressed()))
		level_total += character.level
		position += 1
	var average_level := int(round(float(level_total) / float(maxi(1, units.size()))))
	var biome := _biome()
	var enemies := EnemyCatalog.build_squad(kind, _s.journey_destination_id, danger, units.size(), _rng_savas, average_level, biome)
	var guard: CharacterData = null
	for character in party:
		if character.duty_id == DutyCatalog.MUHAFIZ:
			guard = character
			break
	if guard != null:
		var bonus := int(round(10.0 * (DutyCatalog.get_duty_power(guard, DutyCatalog.MUHAFIZ) - 1.0)))
		if bonus > 0:
			for unit in units:
				unit.apply_modifier("accuracy", bonus, 1)
	var encounter := CombatEncounter.new(units, enemies, _rng_savas, EnemyCatalog.get_kind_label(kind))
	encounter.ambushed = ambushed
	var squad_had_chief := false
	if kind == "bandit":
		for unit in encounter.enemy_units:
			if CHIEF_KINDS.has(unit.figure_kind):
				squad_had_chief = true
				if not chief_fight.is_empty():
					var chief := _s.people.person(chief_fight)
					unit.display_name = String(chief.get("name", unit.display_name))
					unit.max_hp += CHIEF_HP_PER_RANK * int(chief.get("rank", 0))
					unit.current_hp = unit.max_hp
				break
	encounter.start()
	var used := {}
	var actions := 0
	var retreat_at := _pf("yol", "geri_cekil_can", 0.25)
	while not encounter.is_over() and actions < 400:
		if not encounter.is_player_turn():
			break
		if _geri_cekil(encounter, retreat_at):
			break
		if not _savas_hamlesi(encounter, used):
			break
		actions += 1
	var enemy_steps := int(ceil(float(actions) * float(enemies.size()) / float(maxi(1, units.size()))))
	_ilerle(SAVAS_DIZILIS_SN + float(actions) * SAVAS_OYUNCU_SN + float(enemy_steps) * SAVAS_DUSMAN_SN + SAVAS_SONUC_SN)

	var victory := encounter.state == CombatEncounter.State.VICTORY
	var retreat_kind := encounter.retreat_kind if encounter.state == CombatEncounter.State.RETREAT else ""
	var xp := 0
	for unit in encounter.enemy_units:
		if not unit.is_alive():
			xp += unit.xp_value
	var downed := encounter.get_downed_count()
	var dead := encounter.get_dead_characters()
	encounter.write_back_party()
	if victory:
		var loot_rng := RandomNumberGenerator.new()
		loot_rng.seed = hash("loot|%s|%d|%d" % [kind, encounter.round_number, encounter.enemy_units.size()])
		var drops := LootTable.roll(kind, danger, loot_rng)
		if not drops.is_empty():
			LootTable.apply(_s, drops)
	for item_id in used:
		_s.remove_from_cargo_or_bags(String(item_id), mini(int(used[item_id]), _s.get_total_quantity(String(item_id))))

	# --- road_journey._on_combat_finished ---
	_s.log_beat(GameSession.BEAT_LOG_COMBAT_END, "won" if victory else "lost")
	_chief_sonrasi(kind, chief_fight, victory, squad_had_chief)
	_s.note_beat(GameSession.BEAT_WON if victory else GameSession.BEAT_LOST, [EnemyCatalog.get_kind_label(kind)])
	if xp > 0:
		var gained := _s.grant_party_xp(xp, party)
		if not gained.is_empty():
			_seviye(gained)
	if victory and dead.is_empty():
		for fighter in party:
			fighter.change_rapport(1)
		_s.companion_notes = []
		_s.bond_group(party, CompanionLife.SHARED_FIGHT)
	var wagons_before := _s.caravan.wagon_count
	if not dead.is_empty():
		var outcome := _s.resolve_deaths(dead, "LEDGER_CAUSE_COMBAT_%s" % kind.to_upper(), _s.journey_destination_id)
		_olum_sonucu(outcome)
	_s.apply_combat_fatigue(party)
	var injury_rng := RandomNumberGenerator.new()
	injury_rng.seed = hash("injury|%s|%d" % [_route_key, _s.total_days_elapsed])
	for fighter in party:
		if _s.get_party().has(fighter) and fighter.current_hp <= 1:
			_s.roll_injury(fighter, injury_rng)
	if not victory or not dead.is_empty():
		for character in _s.get_party():
			if not party.has(character):
				character.add_grievance(CharacterData.GRIEVANCE_BENCHED)
	if downed > 0:
		var by_stress: Array[CharacterData] = party.duplicate()
		by_stress.sort_custom(func(a: CharacterData, b: CharacterData) -> bool: return a.stress > b.stress)
		for index in mini(downed, by_stress.size()):
			_s.change_character_stress(by_stress[index], DOWNED_STRESS_MARK)
	var stress_delta := COMBAT_STRESS_BASE + downed * COMBAT_STRESS_PER_DOWN
	stress_delta += -COMBAT_VICTORY_STRESS_RELIEF if victory else COMBAT_DEFEAT_STRESS
	var effects: Array[EventEffect] = [EventEffect.make(EventEffect.Type.STRESS, stress_delta)]
	if not retreat_kind.is_empty():
		_geri_cekilme_bedeli(retreat_kind)
		effects.append(EventEffect.make(EventEffect.Type.MORALE, RETREAT_MORALE))
	elif victory:
		effects.append(EventEffect.make(EventEffect.Type.GOLD, COMBAT_LOOT_BASE + int(round(_s.danger_level * COMBAT_LOOT_DANGER_BONUS))))
		effects.append(EventEffect.make(EventEffect.Type.MORALE, COMBAT_VICTORY_MORALE))
		effects.append(EventEffect.make(EventEffect.Type.REPUTATION, GUARD_VICTORY_REPUTATION if kind == "guard" else COMBAT_VICTORY_REPUTATION))
		effects.append(EventEffect.make(EventEffect.Type.DANGER, COMBAT_VICTORY_DANGER))
		var meat := GameSession.combat_victory_provisions(kind)
		if meat > 0:
			effects.append(EventEffect.make(EventEffect.Type.PROVISIONS, meat))
	else:
		var plunder_rng := RandomNumberGenerator.new()
		plunder_rng.seed = hash("plunder|%s|%d" % [_route_key, _s.total_days_elapsed])
		_s.plunder_cargo(GameSession.DEFEAT_PLUNDER_SHARE, plunder_rng)
		effects.append(EventEffect.make(EventEffect.Type.GOLD, COMBAT_DEFEAT_GOLD))
		effects.append(EventEffect.make(EventEffect.Type.WAGON_DAMAGE, COMBAT_DEFEAT_WAGON_DAMAGE))
		effects.append(EventEffect.make(EventEffect.Type.MERCHANT_LEAVE, COMBAT_DEFEAT_MERCHANTS))
		effects.append(EventEffect.make(EventEffect.Type.MORALE, COMBAT_DEFEAT_MORALE))
	_etki_uygula(effects)

	_sayac["savas"] = int(_sayac["savas"]) + 1
	_ilk("ilk_savas")
	var sonuc := "kazanıldı" if victory else ("geri çekilindi (%s)" % retreat_kind if not retreat_kind.is_empty() else "kaybedildi")
	if victory:
		_sayac["savas_kazanilan"] = int(_sayac["savas_kazanilan"]) + 1
	if not retreat_kind.is_empty():
		_sayac["geri_cekilme"] = int(_sayac["geri_cekilme"]) + 1
	_olay("savas", "%s (%d düşman, tehlike %d%%%s): %s · %d hamle · %d yere düştü · %d öldü" % [
		kind, enemies.size(), int(round(danger * 100.0)), ", pusu" if ambushed else "", sonuc, actions, downed, dead.size()],
		"savaş kartı")
	if victory and downed == 0 and dead.is_empty():
		_sayac["kayipsiz_tehdit"] = int(_sayac["kayipsiz_tehdit"]) + 1
		_iyi("tehditten kayıpsız çıkıldı (%s)" % kind)
	elif not victory:
		_kritik_not("savaş %s (%s)" % [sonuc, kind])
	if _s.caravan.wagon_count < wagons_before:
		_vagon_kaybi()
	_izle()

func _chief_sonrasi(kind: String, chief_fight: String, victory: bool, squad_had_chief: bool) -> void:
	if kind != "bandit":
		return
	var people := _s.people
	if not chief_fight.is_empty():
		if victory:
			people.chief_killed(chief_fight, _s.total_days_elapsed)
		else:
			people.chief_paid(chief_fight)
		return
	if not victory or not squad_had_chief:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("chief_escape|%s|%d" % [_route_key, _s.total_days_elapsed])
	if rng.randf() >= People.CHIEF_ESCAPE_CHANCE:
		return
	var place := WorldMapData.get_location_by_id(_s.journey_destination_id)
	var cultures: Array[String] = []
	if place != null:
		cultures = place.peoples
	people.chief_escaped(_s.journey_region(), _s.total_days_elapsed, cultures)

func _geri_cekilme_bedeli(kind: String) -> void:
	if kind == CombatEncounter.RETREAT_CARGO:
		for item in ItemCatalog.get_trade_goods():
			if item.item_id == GameSession.PROVISIONS_ITEM_ID:
				continue
			var have := _s.get_total_quantity(item.item_id)
			if have > 0:
				_s.remove_from_cargo_or_bags(item.item_id, maxi(1, int(ceil(float(have) * RETREAT_CARGO_SHARE))))
	elif kind == CombatEncounter.RETREAT_WAGON:
		if _s.caravan.lose_wagons(1) > 0:
			_s.add_memorial(GameSession.MEMORIAL_WRECK)
			_s.note_beat(GameSession.BEAT_WAGON)

func _geri_cekil(encounter: CombatEncounter, esik: float) -> bool:
	if esik <= 0.0 or not encounter.can_retreat():
		return false
	var hp := 0
	var max_hp := 0
	var healthiest: CombatUnit = null
	for unit in encounter.player_units:
		hp += maxi(0, unit.current_hp)
		max_hp += unit.max_hp
		if unit.is_alive() and (healthiest == null or unit.current_hp > healthiest.current_hp):
			healthiest = unit
	if max_hp <= 0 or float(hp) / float(max_hp) > esik:
		return false
	var kind := CombatEncounter.RETREAT_CARGO
	if _s.get_cargo_item_count() <= 0:
		kind = CombatEncounter.RETREAT_REARGUARD
	return encounter.retreat(kind, healthiest)

func _savas_hamlesi(encounter: CombatEncounter, used: Dictionary) -> bool:
	var unit := encounter.get_active_unit()
	if unit == null:
		return false
	var wounded: CombatUnit = null
	for candidate in encounter.player_units:
		if not candidate.is_alive() or float(candidate.current_hp) > float(candidate.max_hp) * 0.5:
			continue
		if wounded == null or candidate.current_hp < wounded.current_hp:
			wounded = candidate
	if wounded != null:
		for skill in unit.skills:
			if not skill.is_heal():
				continue
			for candidate in encounter.get_valid_targets(unit, skill):
				if candidate == wounded:
					return encounter.use_skill(skill, candidate)
		if float(wounded.current_hp) <= float(wounded.max_hp) * 0.3:
			for kind in [CombatEncounter.CONSUMABLE_POTION, CombatEncounter.CONSUMABLE_BANDAGE]:
				if _s.get_total_quantity(kind) - int(used.get(kind, 0)) > 0 and encounter.use_consumable(kind, wounded):
					used[kind] = int(used.get(kind, 0)) + 1
					return true
	var best_skill: CombatSkill = null
	var best_target: CombatUnit = null
	for skill in unit.skills:
		if skill.is_heal():
			continue
		var targets := encounter.get_valid_targets(unit, skill)
		if targets.is_empty():
			continue
		if best_skill == null or skill.base_damage > best_skill.base_damage:
			best_skill = skill
			best_target = targets[0]
			for candidate in targets:
				if candidate.current_hp < best_target.current_hp:
					best_target = candidate
	if best_skill != null:
		return encounter.use_skill(best_skill, best_target)
	var living: Array[CombatUnit] = []
	for candidate in encounter.player_units:
		if candidate.is_alive():
			living.append(candidate)
	if living.size() >= 2 and encounter.swap_player_positions(living[0], living[1]):
		return true
	return encounter.pass_turn()

# --- Kamp ---------------------------------------------------------------

func _kamp_ister() -> bool:
	var night := int(floor((_clock.total_hours - 12.0) / JourneyClock.HOURS_PER_DAY))
	if night == _camp_night:
		return false
	match _ps("yol", "kamp", "her_gece"):
		"asla":
			return false
		"yorulunca":
			if _s.get_caravan_stamina() >= 45 and _stres_ort() < 45.0:
				return false
	_camp_night = night
	return true

func _update_camp() -> void:
	if not _camping:
		if not _clock.is_camp_time() or not _kamp_ister():
			return
		# road_journey._on_camp_pressed
		_camping = true
		_s.note_campfire()
		_s.log_beat(GameSession.BEAT_LOG_CAMP_START)
		_clock.set_speed_index(_clock.camp_speed_index())
		_sayac["kamp"] = int(_sayac["kamp"]) + 1
		# Ateşe yürüyüş: sahnede saat bu sırada 0.05 ölçekle akar.
		_clock.advance(KAMP_GECIS_SN, maxf(1.0, _clock.get_speed()) * JourneyController.CAMP_WALK_CLOCK_SCALE)
		_ilerle(KAMP_GECIS_SN)
		_camp_ends = _clock.total_hours + GameSession.CAMP_HOURS
		_s.set_road_position(_route_key, _terrain_from(), _j.terrain_day(), maxi(1, _j.terrain_days))
		_s.add_memorial(GameSession.MEMORIAL_ASH)
		_s.companion_notes = []
		_s.bond_group(_s.get_party(), CompanionLife.SHARED_CAMP)
		_kamp_paneli()
		return
	if _clock.total_hours < _camp_ends:
		return
	var camp_result := _s.make_camp()
	_s.log_beat(GameSession.BEAT_LOG_CAMP_END)
	_camping = false
	_olay("kamp", "kamp bozuldu (erzak -%d, stres -%d)" % [
		int(camp_result.get("provisions_spent", 0)), int(camp_result.get("stress_relief", 0))], "sekiz saat dinlenildi")
	if _pb("yol", "hiz_geri_al", true):
		_clock.set_speed_index(JourneyClock.DEFAULT_SPEED_INDEX)
		_ilerle(HIZ_DUGMESI_SN)
	_izle()

func _kamp_paneli() -> void:
	var party := _s.get_party()
	var formation: Array = [null, null, null]
	for index in mini(3, party.size()):
		formation[index] = party[index]
	var wanted: Array = (_profil.get("yol", {}) as Dictionary).get("kamp_isleri", [GameSession.CAMP_ACTION_WATCH, GameSession.CAMP_ACTION_WOUNDS])
	var actions: Array = []
	var okudu := _rng_karar.randf() < _okuma()
	if okudu:
		var hurt := false
		for member in party:
			if float(member.current_hp) < float(member.get_max_hp()) * 0.7:
				hurt = true
		for action in wanted:
			var id := String(action)
			if actions.size() >= GameSession.CAMP_ACTION_LIMIT:
				break
			if id == GameSession.CAMP_ACTION_WOUNDS and not hurt:
				continue
			if id == GameSession.CAMP_ACTION_REPAIR and _s.caravan.damaged_wagons <= 0:
				continue
			if _s.can_camp_action(id):
				actions.append(id)
			else:
				_engel("kampta %s" % id, "kamp işi yapılamıyor")
		if actions.size() < GameSession.CAMP_ACTION_LIMIT and _s.get_provisions() < _s.get_daily_provision_consumption() * 2 \
				and not actions.has(GameSession.CAMP_ACTION_HUNT):
			actions.append(GameSession.CAMP_ACTION_HUNT)
	_s.log_beat(GameSession.BEAT_LOG_DECISION, "camp")
	_s.set_formation(formation[0], formation[1], formation[2])
	var done := _s.apply_camp_actions(actions)
	for action in done:
		if action == GameSession.CAMP_ACTION_WATCH:
			_signal_danger_bonus = maxf(_signal_danger_bonus - CAMP_WATCH_DANGER, -SIGNAL_DANGER_CAP)
	_ilerle(KAMP_PANEL_SN if okudu else OKUMADAN_SN)
	_olay("kamp", "kamp kuruldu: %s" % (", ".join(PackedStringArray(done)) if not done.is_empty() else "iş seçilmedi"),
		"profilin kamp işleri" if okudu else "okumadan onayladı", GameSession.CAMP_ACTIONS.size(), GameSession.CAMP_ACTIONS.size())
	for name in _s.swear_oaths():
		_olay("kamp", "ant içildi: %s" % String(name))
	var mercy := _s.roll_small_mercy()
	if not mercy.is_empty():
		_s.receive_small_mercy(mercy)
		_ilerle(MERHAMET_SN)
		_olay("kamp", "küçük bir merhamet anı", String(mercy.get("key", mercy.get("kind", ""))))
	var teller := _s.roll_camp_story()
	if teller != null:
		var choice := CampStory.CHOICE_LISTEN if _wt("insan") >= 0.3 or _ahlak() == "merhametli" else CampStory.CHOICE_SLEEP
		_s.resolve_camp_story(teller, choice)
		_ilerle(HIKAYE_SN if choice == CampStory.CHOICE_LISTEN else OKUMADAN_SN)
		_olay("kamp", "%s hikâye anlattı: %s" % [teller.character_name, choice], "insan ağırlığı", 3, 3)
	var candidates := _s.diary_candidates()
	_s.log_beat(GameSession.BEAT_LOG_DECISION, "diary")
	if candidates.is_empty():
		_s.write_diary("")
	else:
		var pick: Dictionary = candidates[_rng_karar.randi_range(0, candidates.size() - 1)]
		var args: Array = pick.get("args", [])
		_s.write_diary(String(pick.get("key", "")), args)
		_ilerle(GUNLUK_SN)
	_izle()

# --- Varış --------------------------------------------------------------

func _var() -> void:
	# road_journey._on_arrive_pressed
	_s.last_clock_hour = _clock.get_hour_of_day()
	var wagons_before := _s.owned_wagon_count
	var party_before := _s.get_party().size()
	var payout := _s.finish_journey()
	_sayac["sefer"] = int(_sayac["sefer"]) + 1
	_ilk("ilk_varis")
	_ilerle(VARIS_OZET_SN)
	var levels: Dictionary = payout.get("levels_gained", {})
	if not levels.is_empty():
		_seviye(levels)
	var breaks: Array = payout.get("stress_breaks", [])
	_olay("rota", "varıldı: %s · brüt %d, net %d · teslim %d, kayıp kontrat %d · %d gün" % [
		_s.current_location_id, int(payout.get("gross", 0)), int(payout.get("net", 0)),
		int(payout.get("delivered_contracts", 0)), int(payout.get("lost_contracts", 0)), int(payout.get("journey_days", 0))],
		"aç gün %d, kırılma %d" % [int(payout.get("hungry_days", 0)), breaks.size()])
	for entry in breaks:
		var brk: Dictionary = entry
		_olay("hal_degisim", "stres kırılması: %s%s" % [String(brk.get("character_name", "")),
			" (kervandan ayrıldı)" if bool(brk.get("departed", false)) else ""])
		if bool(brk.get("departed", false)):
			_kritik_not("%s stres kırılmasıyla ayrıldı" % String(brk.get("character_name", "")))
	for name in (payout.get("left_quietly", []) as Array):
		_olay("hal_degisim", "%s sessizce ayrıldı" % String(name))
		_kritik_not("%s sessizce ayrıldı (gidici)" % String(name))
	if _s.owned_wagon_count < wagons_before:
		_vagon_kaybi()
	if _s.get_party().size() < party_before and breaks.is_empty():
		_olay("hal_degisim", "kadro varışta küçüldü (%d -> %d)" % [party_before, _s.get_party().size()])
	_izle()

# --- Çıktı --------------------------------------------------------------

func _kontrol_al(ad: String) -> void:
	var cards := int(_sayac["kart"])
	var unique := _kart_sayac.size()
	var snapshot := {
		"ad": ad, "t_sn": int(round(_t)), "gun": _gun(), "kervan_no": _kervan_no,
		"kusak": _s.lineage_generation if _s != null else 0,
		"sefer": int(_sayac["sefer"]), "kart": cards, "farkli_kart": unique,
		"tekrar_orani": snappedf(1.0 - float(unique) / float(maxi(1, cards)), 0.001),
		"kese": _s.wallet.balance if _s != null else 0,
		"borc": _s.get_total_debt() if _s != null else 0,
		"kadro": _s.get_party().size() if _s != null else 0,
		"vagon": _s.owned_wagon_count if _s != null else 0,
		"itibar": _s.reputation if _s != null else 0,
		"olu": int(_sayac["olu"]), "ac_gece": int(_sayac["ac_gece"]), "bos_tur": int(_sayac["bos_tur"]),
		"savas": int(_sayac["savas"]), "sehir": int(_sayac["sehir"]), "seceneksiz": int(_sayac["seceneksiz"]),
		"erzak": _s.get_provisions() if _s != null else 0,
		"moral": _s.caravan.morale if _s != null else 0,
		"stres_ort": _stres_ort() if _s != null else 0.0,
	}
	_kontroller.append(snapshot)
	_gunluk.append("")
	_gunluk.append("### %s (%s)" % [ad if ad == "son" else "%s sn" % ad, _saat_metni(_t)])
	_gunluk.append("")
	_gunluk.append(("Gün %d, %d. kervan, %d. kuşak. %d sefer bitti, %d kart görüldü (%d farklı, tekrar %%%d). "
		+ "Kese %d GG, borç %d GG, kadro %d, vagon %d. Şimdiye dek %d ölüm, %d aç gece, %d boş yol günü, %d savaş.") % [
		snapshot["gun"], _kervan_no, snapshot["kusak"], snapshot["sefer"], cards, unique,
		int(round(float(snapshot["tekrar_orani"]) * 100.0)), snapshot["kese"], snapshot["borc"], snapshot["kadro"],
		snapshot["vagon"], snapshot["olu"], snapshot["ac_gece"], snapshot["bos_tur"], snapshot["savas"]])
	_gunluk.append("")

func _aralik_ozeti() -> Dictionary:
	if _iyi_gunler.is_empty():
		return {"adet": 0, "ortalama_gun": -1.0, "en_uzun_gun": _gun(), "ortanca_gun": -1.0}
	var gaps: Array[int] = []
	var onceki := 0
	for day in _iyi_gunler:
		gaps.append(day - onceki)
		onceki = day
	gaps.append(_gun() - onceki)
	var total := 0
	var longest := 0
	for gap in gaps:
		total += gap
		longest = maxi(longest, gap)
	var sorted := gaps.duplicate()
	sorted.sort()
	return {
		"adet": _iyi_gunler.size(), "ortalama_gun": snappedf(float(total) / float(gaps.size()), 0.01),
		"en_uzun_gun": longest, "ortanca_gun": float(sorted[sorted.size() / 2]),
	}

func _sirali(counts: Dictionary, limit: int) -> Array:
	var keys: Array = counts.keys()
	keys.sort_custom(func(a, b) -> bool:
		if int(counts[a]) == int(counts[b]):
			return String(a) < String(b)
		return int(counts[a]) > int(counts[b]))
	var out: Array = []
	for index in mini(limit, keys.size()):
		out.append({"ne": String(keys[index]), "adet": int(counts[keys[index]])})
	return out

func _yaz() -> void:
	_izle()
	for mark in _s.first_times:
		if not _ilkler_oturum.has(mark):
			_ilkler_oturum[mark] = snappedf(float(_s.first_times[mark]) + _kervan_t0, 0.1)
	var hal := {}
	var kabuk := 0.0
	var catlak := 0.0
	var lakaplar: Array = []
	var party := _s.get_party()
	for member in party:
		hal[member.hal] = int(hal.get(member.hal, 0)) + 1
		kabuk += member.kabuk
		catlak += member.catlak
		if not member.lakap.is_empty():
			lakaplar.append("%s: %s" % [member.character_name, member.lakap])
	for entry in _s.lakaplar:
		lakaplar.append(str(entry))
	var acik_iz := 0
	for trace in _s.traces.traces:
		if trace.durum != Trace.STATE_RETURNED and trace.durum != Trace.STATE_FADED:
			acik_iz += 1
	var donen := int(_iz["donen"])
	var cards := int(_sayac["kart"])
	var ozet := {
		"profil": String(_profil.get("id", "")), "profil_adi": String(_profil.get("ad", "")), "tohum": _tohum,
		"butce_sn": int(_butce), "t_sn": int(round(_t)), "gun": _gun(),
		"hizlandirildi": "yol sahnesi açılmadı: road_journey.gd döngüsü JourneyClock + JourneyController ile aynalandı; süre eşdeğer sayaç",
		"ilkler_oturum": _ilkler_oturum, "ilkler_surucu": _ilkler,
		"huni": _kontroller,
		"iyi_sey_arasi": _aralik_ozeti(),
		"sayaclar": _sayac,
		"ac_gece": int(_sayac["ac_gece"]), "seceneksiz_an": int(_sayac["seceneksiz"]),
		"olumler": _olumler, "kervan_sayisi": _kervan_no, "kusak": _s.lineage_generation,
		"hal_histogrami": hal, "hal_gecisleri": _hal_gecis,
		"kabuk_ort": snappedf(kabuk / float(maxi(1, party.size())), 0.01),
		"catlak_ort": snappedf(catlak / float(maxi(1, party.size())), 0.01),
		"iz": {"dogan": int(_iz["dogan"]), "donen": donen, "sonen": int(_iz["sonen"]), "acik": acik_iz,
			"iyi": int(_iz["iyi"]), "kotu": int(_iz["kotu"]),
			"iyi_payi": snappedf(float(int(_iz["iyi"])) / float(maxi(1, donen)), 0.01)},
		"bedel_odeyen": int(_sayac["bedel"]), "yanki": _s.yankilar.size(),
		"huy_bandi": _s.temper_band(), "huy": _s.temper_label(), "lakaplar": lakaplar,
		"engeller_ilk10": _sirali(_engeller, 10), "engel_cesidi": _engeller.size(),
		"kart_gorulme": _kart_sayac, "farkli_kart": _kart_sayac.size(),
		"tekrar_orani": snappedf(1.0 - float(_kart_sayac.size()) / float(maxi(1, cards)), 0.001),
		"son_agirliklar": _w,
	}
	var file := FileAccess.open(_cikti.path_join("olaylar.jsonl"), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_satirlar) + "\n")
		file.close()
	file = FileAccess.open(_cikti.path_join("ozet.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(ozet, "  ") + "\n")
		file.close()
	var lines: Array[String] = []
	lines.append("# Oyun testi günlüğü: %s (tohum %d)" % [String(_profil.get("ad", _profil.get("id", ""))), _tohum])
	lines.append("")
	lines.append("%s" % String(_profil.get("aciklama", "")))
	lines.append("")
	lines.append("Eşdeğer süre %s, %d gün, %d kervan, %d sefer, %d kart, %d savaş, %d ölüm. **Hızlandırıldı:** yol sahnesi açılmadı, süre sayaçtır."
		% [_saat_metni(_t), _gun(), _kervan_no, int(_sayac["sefer"]), cards, int(_sayac["savas"]), int(_sayac["olu"])])
	lines.append("")
	lines.append("## Kritik anlar")
	lines.append("")
	if _kritik.is_empty():
		lines.append("- (yok)")
	lines.append_array(_kritik)
	lines.append("")
	lines.append("## En çok çarpılan kapılar")
	lines.append("")
	for entry in _sirali(_engeller, 10):
		lines.append("- %d× %s" % [int(entry["adet"]), String(entry["ne"])])
	lines.append("")
	lines.append("## Kontrol noktaları ve iyi şeyler")
	lines.append_array(_gunluk)
	file = FileAccess.open(_cikti.path_join("gunluk.md"), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(lines) + "\n")
		file.close()
