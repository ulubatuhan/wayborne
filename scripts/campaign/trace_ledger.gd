class_name TraceLedger
extends RefCounted

## İzlerin defteri: doğuran, söndüren, olgunlaşanı bulan tek yer.
## (İz alt sistemi, tasarım notu §D.3; şema `Trace`'te.)
##
## Tek giriş noktası `leave()`: bir iz başka hiçbir yerde doğmaz. Tek çıkış
## noktası `ripe_here()`: geri dönüşü `GameSession` seçer ve uygular.
##
## Tavanlar defterin okunabilirliği içindir, kaydın boyutu için değil: açık
## hesaplar sayfası 15 satırdan uzunsa kimse okumaz; bir karar iz bırakmadan
## kayboluyorsa da sistem görünmez. Kapanmış izlerin son 12'si saklanır
## (karşılığı yazılabilsin diye), kuşak izleri ayrı tutulur.

const MAX_OPEN: int = 15
const MAX_CLOSED: int = 12
const MAX_LEGACY: int = 6
## Gecikme başına açık iz tavanı: aynı anda beş "kısa vadeli" hesaptan fazlası
## ritmi boğar.
const MAX_OPEN_BY_DELAY: Dictionary = {
	Trace.DELAY_NOW: 3,
	Trace.DELAY_JOURNEY: 3,
	Trace.DELAY_SHORT: 5,
	Trace.DELAY_LONG: 4,
	Trace.DELAY_GENERATION: MAX_LEGACY,
}
## Aynı kaynaktan ikinci kez iz doğmaz; var olanın şiddeti bu kadar artar.
const REPEAT_BUMP: float = 0.15
## Bu şiddetin altına inen iz söner: "kimse hatırlamadı" da bir sonuçtur.
const FADE_FLOOR: float = 0.05
## Deftere yazılma eşiği (§D-İ1): kısa vadeden kısa izler ve zayıf izler
## açık hesaplar sayfasına girmez, yoksa defter fişe döner.
const LEDGER_MIN_SEVERITY: float = 0.4

var traces: Array[Trace] = []
var serial: int = 0

func open_traces() -> Array[Trace]:
	var out: Array[Trace] = []
	for trace in traces:
		if trace.is_open():
			out.append(trace)
	return out

func open_count() -> int:
	return open_traces().size()

## Yeni bir iz doğurur ve onu döner; doğmadıysa null.
##
## `seed_text` zarın tohumu (kervan adı + gün + kaynak): kaydı yükleyip
## yeniden denemek aynı olgunluk gününü verir - projenin var olan kuralı.
func leave(
	tur: String, tasiyici_tip: String, tasiyici_id: String, yon: int,
	kaynak: String, day: int, birth_place: String, gecikme: String, donus: String,
	seed_text: String, siddet_override: float = -1.0, donus_karti: String = "",
	bedel_odeyen: String = ""
) -> Trace:
	# Aynı kaynak + aynı taşıyıcı için açık iz varsa yenisi açılmaz: tekrar
	# eden bir davranış yeni bir hesap değil, aynı hesabın büyümesidir.
	var existing := find_open(kaynak, tasiyici_tip, tasiyici_id)
	if existing != null:
		existing.siddet = minf(1.0, existing.siddet + REPEAT_BUMP)
		return existing
	if not _make_room(gecikme):
		return null
	var table: Dictionary = Trace.TYPE_TABLE.get(tur, Trace.TYPE_TABLE[Trace.TYPE_GRATITUDE])
	var trace := Trace.new()
	serial += 1
	trace.id = "iz%d" % serial
	trace.tur = tur
	trace.kaynak = kaynak
	trace.dogum_gunu = day
	trace.dogum_yeri = birth_place
	trace.tasiyici_tip = tasiyici_tip
	trace.tasiyici_id = tasiyici_id
	trace.bedel_odeyen = bedel_odeyen
	trace.yon = 1 if yon >= 0 else -1
	trace.siddet = clampf(siddet_override if siddet_override > 0.0 else float(table["siddet"]), 0.05, 1.0)
	trace.gecikme = gecikme
	trace.olgunluk_gunu = day + _delay_days(gecikme, seed_text)
	trace.sonme = float(table["sonme"])
	trace.yayilma = int(table["yayilma"])
	trace.donus = donus
	trace.donus_karti = donus_karti
	trace.durum = Trace.STATE_LEGACY if gecikme == Trace.DELAY_GENERATION else Trace.STATE_OPEN
	trace.add_knower(birth_place)
	traces.append(trace)
	return trace

func find_open(kaynak: String, tasiyici_tip: String, tasiyici_id: String) -> Trace:
	for trace in traces:
		if trace.is_open() and trace.kaynak == kaynak \
				and trace.tasiyici_tip == tasiyici_tip and trace.tasiyici_id == tasiyici_id:
			return trace
	return null

func get_trace(id: String) -> Trace:
	for trace in traces:
		if trace.id == id:
			return trace
	return null

## Her gün: şiddet erir, eriyen söner.
func advance_day(_day: int) -> void:
	for trace in traces:
		if trace.durum != Trace.STATE_OPEN or trace.sonme <= 0.0:
			continue
		trace.siddet -= trace.sonme
		if trace.siddet <= FADE_FLOOR:
			trace.siddet = 0.0
			trace.durum = Trace.STATE_FADED
	_trim_closed()

## Burada (bu yerde / bu yolda / bu bölgede) bugün dönebilecek izler, en
## ağırdan hafife.
func ripe_here(day: int, place_id: String, region: String, route_id: String) -> Array[Trace]:
	var out: Array[Trace] = []
	for trace in traces:
		if trace.durum != Trace.STATE_OPEN or not trace.is_ripe(day):
			continue
		if _is_here(trace, place_id, region, route_id):
			out.append(trace)
	out.sort_custom(func(a: Trace, b: Trace) -> bool: return a.siddet > b.siddet)
	return out

func _is_here(trace: Trace, place_id: String, region: String, route_id: String) -> bool:
	match trace.tasiyici_tip:
		Trace.BEARER_ROAD:
			return not route_id.is_empty() and trace.tasiyici_id == route_id
		Trace.BEARER_REGION:
			return not region.is_empty() and trace.tasiyici_id == region
		Trace.BEARER_COMPANION, Trace.BEARER_LINE:
			return true
		_:
			# Kişi, şehir ve hizip izleri izin ulaştığı yerlerde karşına çıkar.
			return not place_id.is_empty() and (trace.tasiyici_id == place_id or trace.knows(place_id))

## Burada bilinen en güçlü izin şiddeti (olay bağlamı için); yoksa 0.
func strength_here(tur: String, place_id: String) -> float:
	var best := 0.0
	for trace in traces:
		if trace.durum != Trace.STATE_OPEN or trace.tur != tur:
			continue
		if trace.tasiyici_id == place_id or trace.knows(place_id):
			best = maxf(best, trace.siddet)
	return best

## Dönüşü işlenmiş iz kapanır. Kapanmak unutulmak değildir: defterde kalır.
func mark_returned(trace: Trace, day: int) -> void:
	if trace == null:
		return
	trace.durum = Trace.STATE_RETURNED
	trace.donus_gunu = day
	_trim_closed()

## Açık hesaplar sayfasına girecek izler (§D-İ1: defter fişe dönmesin).
func ledger_worthy() -> Array[Trace]:
	var out: Array[Trace] = []
	for trace in traces:
		if not trace.is_open():
			continue
		if trace.gecikme == Trace.DELAY_NOW or trace.gecikme == Trace.DELAY_JOURNEY:
			continue
		if trace.siddet >= LEDGER_MIN_SEVERITY:
			out.append(trace)
	return out

## Tavan dolduysa yer açar: en ucuz "anlık/sefer" izi söndürülür. Yer
## açılamıyorsa yeni iz **yazılmaz** - eski bir hesabı yeni bir hesap için
## silmek defteri yalancı yapardı.
func _make_room(gecikme: String) -> bool:
	var by_delay := 0
	for trace in open_traces():
		if trace.gecikme == gecikme:
			by_delay += 1
	var delay_cap := int(MAX_OPEN_BY_DELAY.get(gecikme, MAX_OPEN))
	if by_delay >= delay_cap and not _fade_cheapest(gecikme):
		return false
	if open_count() >= MAX_OPEN and not _fade_cheapest(""):
		return false
	return true

func _fade_cheapest(gecikme: String) -> bool:
	var victim: Trace = null
	for trace in traces:
		if trace.durum != Trace.STATE_OPEN:
			continue
		var short_lived := trace.gecikme == Trace.DELAY_NOW or trace.gecikme == Trace.DELAY_JOURNEY
		if not short_lived and (gecikme.is_empty() or trace.gecikme != gecikme):
			continue
		if victim == null or trace.siddet < victim.siddet:
			victim = trace
	if victim == null:
		return false
	victim.durum = Trace.STATE_FADED
	return true

func _trim_closed() -> void:
	var closed: Array[Trace] = []
	for trace in traces:
		if trace.durum == Trace.STATE_RETURNED or trace.durum == Trace.STATE_FADED:
			closed.append(trace)
	var excess := closed.size() - MAX_CLOSED
	if excess <= 0:
		return
	# En eski kapanmışlar düşer: defterin hafızası sonsuz değil, sonuncular.
	closed.sort_custom(func(a: Trace, b: Trace) -> bool: return a.dogum_gunu < b.dogum_gunu)
	for index in excess:
		traces.erase(closed[index])

func _delay_days(gecikme: String, seed_text: String) -> int:
	var span: Array = Trace.DELAY_DAYS.get(gecikme, Trace.DELAY_DAYS[Trace.DELAY_SHORT])
	var low := int(span[0])
	var high := int(span[1])
	if high <= low:
		return low
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|iz|%s" % [seed_text, gecikme])
	return rng.randi_range(low, high)

func to_dict() -> Dictionary:
	var rows: Array = []
	for trace in traces:
		rows.append(trace.to_dict())
	return {"izler": rows, "seri": serial}

func from_dict(data: Dictionary) -> void:
	traces.clear()
	serial = int(data.get("seri", 0))
	var rows: Array = data.get("izler", [])
	for row in rows:
		if row is Dictionary:
			traces.append(Trace.from_dict(row))
