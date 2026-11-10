class_name LedgerPage
extends RefCounted

## Paylaşılabilir defter sayfası (görev Y-E07): soyun özeti, ekran görüntüsüne
## uygun tek bir sayfa. Satırlar burada, yerleşim ve dışa aktarma
## `WaybookPanel`'de; satırlar yalnızca defterden ve oturumdan okunur, yeni
## bir kayıt alanı yok.

const DIR: String = "user://defter_sayfalari"
const LOST_LINES: int = 8

static func lines(session: GameSession) -> Array[String]:
	var out: Array[String] = []
	out.append(TranslationServer.translate("UI_LEDGER_PAGE_HEAD") % [
		session.caravan_name, session.lineage_generation, session.total_days_elapsed])
	out.append(TranslationServer.translate("UI_LEDGER_PAGE_JOURNEYS") % [
		session.journeys_completed, session.contracts_delivered])
	var leaders: Array[String] = []
	for entry in session.ledger.entries:
		if String(entry.get("kind", "")) == CaravanLedger.KIND_LED:
			leaders.append(String(entry.get("name", "")))
	if not leaders.is_empty():
		out.append(TranslationServer.translate("UI_LEDGER_PAGE_LEADERS") % ", ".join(leaders))
	var lost: Array[String] = []
	for entry in session.ledger.entries:
		var kind := String(entry.get("kind", ""))
		if kind == CaravanLedger.KIND_DIED or kind == CaravanLedger.KIND_DEPARTED:
			lost.append(CaravanLedger.describe(entry))
	if not lost.is_empty():
		out.append(TranslationServer.translate("UI_LEDGER_PAGE_LOST"))
		out.append_array(lost.slice(maxi(0, lost.size() - LOST_LINES)))
	var graves := session.map_graves().size()
	if graves > 0:
		out.append(TranslationServer.translate("UI_LEDGER_PAGE_GRAVES") % graves)
	return out

## --- Açık Hesaplar (İz alt sistemi, tasarım notu §H adım 4) ---
##
## Defterin bu sayfası bir bilanço değil, bir hatırlatma: dünyada kervanın
## adına yazılmış, karşılığı henüz gelmemiş ne varsa burada durur. Şiddet
## sayısı **yazılmaz** (§F: sayı göstermeden durum göstermek); satır yalnız
## nerede, ne ve sırasının gelip gelmediğini söyler. Üstü çizilmez: karşılığı
## geldiğinde yanına yazılır, sönerse "kimse hatırlamadı" denir.
##
## Her satır: {"text", "note", "bad"}.
static func account_rows(session: GameSession) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if session == null:
		return rows
	for trace in session.traces.traces:
		if trace.gecikme == Trace.DELAY_NOW or trace.gecikme == Trace.DELAY_JOURNEY:
			continue
		var cause := String(Trace.LEDGER_CAUSE_KEYS.get(trace.tur, "LEDGER_TRACE_RUMOR"))
		rows.append({
			"text": TranslationServer.translate("UI_WAYBOOK_ACCOUNT_ROW") % [
				_account_where(trace), TranslationServer.translate(cause)],
			"note": _account_note(trace, session.total_days_elapsed),
			"bad": trace.yon < 0,
		})
	return rows

static func _account_where(trace: Trace) -> String:
	var location := WorldMapData.get_location_by_id(trace.tasiyici_id)
	if location != null:
		return location.location_name
	if trace.tasiyici_id.is_empty():
		return TranslationServer.translate("UI_WAYBOOK_ACCOUNT_SOMEWHERE")
	return trace.tasiyici_id

static func _account_note(trace: Trace, day: int) -> String:
	match trace.durum:
		Trace.STATE_RETURNED:
			return TranslationServer.translate("UI_WAYBOOK_ACCOUNT_ANSWERED") % (trace.donus_gunu + 1)
		Trace.STATE_FADED:
			return TranslationServer.translate("UI_WAYBOOK_ACCOUNT_FADED")
		_:
			if day >= trace.olgunluk_gunu:
				return TranslationServer.translate("UI_WAYBOOK_ACCOUNT_RIPE")
			return TranslationServer.translate("UI_WAYBOOK_ACCOUNT_WAITING")

## Dosya adı: kervanın adı ve günü; dosya sistemine uymayan harfler atılır.
static func file_path(session: GameSession) -> String:
	var name := session.caravan_name.to_lower().validate_filename().replace(" ", "_")
	if name.is_empty():
		name = "kervan"
	return "%s/%s_gun%d.png" % [DIR, name, session.total_days_elapsed]
