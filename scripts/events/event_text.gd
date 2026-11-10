class_name EventText
extends RefCounted

## Olay metninde ad anma (U2, uzman ölçümü 2026-11-07).
##
## Zanaat denetçisi profili oyunda ölçülebilir tek büyük boşluğu buldu:
## kataloğun 193 sonucundan **hiçbiri** bir kişinin ya da bir yerin adını
## anmıyordu. Metinler doğru, kısa ve tutumluydu ama kimsenin başına
## gelmiyordu - "Haydutlar geri çekilir." cümlesi her kervanda, her yolda,
## her kuşakta aynı cümle. Oyunun vaadi ("her karar yola bir iz, her ölüm
## deftere bir satır olur") adsız bir sonuçta tutulamaz.
##
## Niye yer adını metne gömmedik: bir kart her yolda açılabiliyor. Kovrast
## adını `evt_bandit_ambush`in metnine yazmak kartı o yola çivilerdi. Bu
## yüzden ad **çalışma anında** geliyor; metin yalnızca yerini işaretliyor.
##
## Türkçe çekim tuzağı: ad bir ortak ada yapışık yazılıyor ("{town} yolunda",
## "{town} sınırında"), ek özel ada değil ortak ada biniyor. Böylece ünlü
## uyumu ve kesme işareti sorunu hiç doğmuyor; metin yazarının Kovrast'ta /
## Zurek'te ayrımını düşünmesi gerekmiyor.
##
## Bu sınıf yeni bir doldurucu değil, **tek kapı**: önce `People.fill_names`
## (zincir kartlarının eski işaretleri - {place}, {off}, {nemesis}, {scar}),
## sonra bu dosyanın işaretleri, en sonda temizlik. Eskiden `fill_names`
## karşılığı olmayan bir işareti olduğu gibi geri veriyordu, yani adı
## bilinmeyen bir reisin kartı ekrana "{nemesis}" yazabiliyordu; `_strip`
## o kapıyı da kapatıyor.
##
## Kural: ekrana hiçbir zaman çözülmemiş bir işaret çıkmaz. Testi
## `test_event_text.gd` tutuyor - katalogdaki her metni boş bir oturumla
## doldurup küme parantezi arıyor.

## Kervandan, cümlenin öznesi olan kişi.
const WHO: String = "{who}"
## Yolun gittiği adı bilinen yerleşim.
const TOWN: String = "{town}"
## Bu seçimin bedelini ödeyen kişi (Ahlak, BEDEL etkisi). Kart açılırken
## seçeneğin üstünde zaten yazıyor; sonuç metni aynı adı anar ki bedelin
## kime düştüğü iki kez görünsün.
const BEARER: String = "{bedel}"

## Bütün işaretler (eski zincir işaretleri dahil) - `_strip` ve test bu
## listeyi tarıyor.
const TOKENS: Array = [WHO, TOWN, BEARER, "{place}", "{off}", "{nemesis}", "{scar}"]

## Bir olay metnini (kart başlığı, gövde, seçenek, sonuç) adlarla doldurur.
##
## `check` verilirse `{who}` zarı **gerçekten atan** kişi olur (lider
## check'inde lider, ortak çabada statı en iyi olan) - ad böylece süs
## değil, olanın öznesi. Check yoksa partiden tohumlanmış biri seçilir:
## `seed_key` aynı kaldıkça aynı kişi gelir, yani kaydı yükleyip aynı
## cümleyi başka bir adla okumak mümkün değil.
static func fill(text: String, session: GameSession, check: SkillCheck = null, seed_key: String = "") -> String:
	if text.is_empty() or not text.contains("{"):
		return text
	if session == null:
		return _strip(text)
	var filled: String = session.people.fill_names(text)
	if filled.contains(WHO):
		filled = filled.replace(WHO, person_name(session, check, seed_key))
	if filled.contains(TOWN):
		filled = filled.replace(TOWN, place_name(session))
	if filled.contains(BEARER) and not session.last_bearer_name.is_empty():
		filled = filled.replace(BEARER, session.last_bearer_name)
	return _strip(filled)

## Çözülemeyen işaretleri temizler: işaretin kendisi ve peşindeki tek
## boşluk gider. "{nemesis} adamları yolu kesmiş." -> "adamları yolu
## kesmiş." Cümle biraz kısalır ama kırılmaz; ekranda küme parantezi
## görünmez. Boş bir ada denk gelen `replace` de aynı boşluğu bıraktığı
## için önce çift boşluk sıkıştırılıyor.
static func _strip(text: String) -> String:
	var out := text
	for token in TOKENS:
		out = out.replace(String(token) + " ", "")
		out = out.replace(String(token), "")
	while out.contains("  "):
		out = out.replace("  ", " ")
	return out.replace(" .", ".").replace(" ,", ",").strip_edges()

static func person_name(session: GameSession, check: SkillCheck = null, seed_key: String = "") -> String:
	if session == null:
		return ""
	if check != null:
		var roller := session.get_check_roller(check)
		if roller != null and not roller.character_name.is_empty():
			return roller.character_name
	var party := session.get_party()
	if party.is_empty():
		return ""
	var key := seed_key if not seed_key.is_empty() else session.caravan_name
	var index := absi(hash("%s|%d" % [key, party.size()])) % party.size()
	return party[index].character_name

## Yolun adı olan yeri: seferde gidilen şehir, şehirdeyken bulunulan şehir.
## Gidilen yer her zaman adı bilinen bir yerleşim, yani seferin her gününde
## anılacak bir ad var - yoldaki "şurada bir yerde" belirsizliği cümlenin
## kendi işi ("{town} yolunda" = o şehre giden yolda).
static func place_name(session: GameSession) -> String:
	if session == null:
		return ""
	var location_id := session.journey_destination_id if session.is_journey_active() else session.current_location_id
	if location_id.is_empty():
		return ""
	var location := WorldMapData.get_location_by_id(location_id)
	return location.location_name if location != null else ""
