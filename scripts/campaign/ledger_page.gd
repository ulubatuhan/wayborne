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

## Dosya adı: kervanın adı ve günü; dosya sistemine uymayan harfler atılır.
static func file_path(session: GameSession) -> String:
	var name := session.caravan_name.to_lower().validate_filename().replace(" ", "_")
	if name.is_empty():
		name = "kervan"
	return "%s/%s_gun%d.png" % [DIR, name, session.total_days_elapsed]
