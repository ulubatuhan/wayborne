extends SceneTree

## Fable veri paketinin oyun tarafı: katalogları olduğu gibi döker.
##
## `tools/fable_paket.py` bunu çağırır, `FABLE_JSON ` ön ekli tek satırı
## ayrıştırır ve prompta gömer. Test değil; hiçbir şey doğrulamaz, yazar.
##
##   godot --headless --script res://tools/fable_dump.gd
##
## Neden Godot'tan: kataloglar GDScript'te kurulu (statik `_ensure_built`),
## Python'dan ayrıştırılırsa ilk ad değişikliğinde sessizce kayar.

func _init() -> void:
	TranslationServer.set_locale("tr")
	var veri := {}
	veri["olaylar"] = _events()
	veri["mallar"] = _items()
	veri["yerlesimler"] = _locations()
	veri["huylar"] = _traits()
	veri["siniflar"] = _classes()
	veri["gorevler"] = _duties()
	veri["kulturler"] = _cultures()
	veri["beceriler"] = _skills()
	veri["ekipman"] = _equipment()
	veri["haydutlar"] = _bandits()
	print("FABLE_JSON " + JSON.stringify(veri))
	quit()

func _effect_names(effects: Array) -> Array:
	var out: Array = []
	for e in effects:
		out.append(EventEffect.Type.keys()[e.type])
	return out

func _events() -> Array:
	var out: Array = []
	for event in EventCatalog.get_road_events():
		var secenekler: Array = []
		for choice in event.choices:
			var sonuc_etkileri: Array = []
			for outcome in choice.outcomes:
				for ad in _effect_names(outcome.effects):
					if not sonuc_etkileri.has(ad):
						sonuc_etkileri.append(ad)
			secenekler.append({
				"metin": tr(choice.text_key),
				"kontrol": "" if choice.check == null else "%s zor%s %s%s" % [
					CharacterStats.Kind.keys()[choice.check.stat], choice.check.difficulty,
					SkillCheck.Source.keys()[choice.check.source],
					"" if choice.check.ceiling >= SkillCheck.MAX_CHANCE else " tavan%d" % choice.check.ceiling],
				"kosul": choice.requirements.size(),
				"dogrudan_etki": _effect_names(choice.effects),
				"sonuc_sayisi": choice.outcomes.size(),
				"sonuc_etkileri": sonuc_etkileri,
			})
		var kosullar: Array = []
		for c in event.conditions:
			kosullar.append("%s %s %s" % [c.key, c.op, c.value])
		out.append({
			"id": event.event_id,
			"baslik": tr(event.title_key),
			"govde": tr(event.text_key),
			"kategori": event.category,
			"agirlik": event.base_weight,
			"tek_seferlik": event.fire_only_once,
			"bekleme_gun": event.cooldown_days,
			"yalniz_tetikle": event.triggered_only,
			"kosullar": kosullar,
			"secenekler": secenekler,
		})
	return out

func _items() -> Array:
	var out: Array = []
	for item in ItemCatalog.get_trade_goods():
		out.append({
			"id": item.item_id, "ad": tr(item.item_name_key), "fiyat": item.base_price,
			"agirlik": item.unit_weight, "raf_gun": item.shelf_days,
			"kacak": item.contraband, "nadir": item.rare,
		})
	return out

func _locations() -> Array:
	var out: Array = []
	for loc in WorldMapData.get_locations():
		var yollar: Array = []
		for r in WorldMapData.get_routes_from(loc.location_id):
			yollar.append(r.to_location_id)
		out.append({
			"id": loc.location_id, "ad": loc.location_name, "tur": loc.settlement_type,
			"bolge": loc.region, "kultur": loc.culture, "halklar": loc.peoples, "sur": loc.wall,
			"uretir": loc.produces, "ister": loc.demands, "komsular": yollar,
		})
	return out

func _traits() -> Array:
	var out: Array = []
	for t in TraitCatalog.get_traits():
		out.append({
			"id": t.trait_id, "ad": tr(t.display_name_key), "olumlu": t.is_positive,
			"metin": tr(t.description_key),
		})
	return out

func _classes() -> Array:
	var out: Array = []
	for c in ClassCatalog.get_classes():
		out.append({
			"id": c.class_id, "ad": tr(c.display_name_key), "gorev": c.duty_id,
			"can": c.bonus_max_hp, "beceriler": c.skill_ids,
		})
	return out

func _duties() -> Array:
	var out: Array = []
	for d in DutyCatalog.get_duties():
		out.append({
			"id": d.duty_id, "ad": tr(d.display_name_key),
			"stat": CharacterStats.Kind.keys()[d.primary_stat], "metin": tr(d.description_key),
		})
	return out

func _cultures() -> Array:
	var out: Array = []
	for c in CultureCatalog.get_cultures():
		var bonus: Array = []
		for kind in c.stat_bonuses:
			bonus.append("%s%+d" % [CharacterStats.Kind.keys()[kind], c.stat_bonuses[kind]])
		out.append({
			"id": c.culture_id, "ad": tr(c.culture_name_key), "tanim": tr(c.description_key),
			"ayricalik": tr(c.perk_text_key), "stat": bonus,
			"erzak_carpani": c.daily_provision_multiplier, "alis_carpani": c.buy_price_multiplier,
			"hasar_carpani": c.combat_damage_multiplier, "erzak_fiyat": c.provision_cost_multiplier,
			"haber_zorlugu": c.rumor_difficulty, "ad_havuzu": c.name_pool.size(),
		})
	return out

func _skills() -> Array:
	var out: Array = []
	for s in SkillCatalog.get_all_skills():
		out.append({
			"id": s.skill_id, "ad": tr(s.display_name_key), "hasar": s.base_damage,
			"sifa": s.heal_amount, "bekleme": s.cooldown_rounds,
		})
	return out

func _equipment() -> Array:
	var out: Array = []
	for e in EquipmentCatalog.get_all_equipment():
		out.append({"id": e.equipment_id, "ad": tr(e.display_name_key), "yuva": e.slot})
	return out

func _bandits() -> Dictionary:
	var out := {}
	for bolge in EnemyCatalog.REGIONAL_BANDITS:
		out[bolge] = EnemyCatalog.REGIONAL_BANDITS[bolge]
	return out
