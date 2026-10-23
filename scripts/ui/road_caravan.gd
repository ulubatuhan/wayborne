class_name RoadCaravan
extends Control

## Yolda yürüyen kervan: önde lider, arkasında parti, sonra öküzlerin
## çektiği vagonlar ve tayfa.
##
## **Lider vagonlara bağlı değil.** Önde gidiyor - atı varsa at üstünde,
## yoksa yayan. Kolondan ayrılıp geriye doğru yürüyebiliyor ("siz devam
## edin"), ama kervanın boyundan uzaklaşamıyor: bir kervan lideri yalnız
## başına yola çıkmaz, kolonun içinde dolaşır.
##
## Çizim ikiye ayrılmış durumda ve bu bilinçli:
##
## - İnsanlar ve hayvanlar ayrı `WalkFigure` düğümleri - kendi yürüyüş
##   fazları var, o yüzden hepsi aynı anda aynı adımı atmıyor. Bütün
##   kervanın tek ritimde yürümesi asker gibi duruyor, kervan gibi
##   durmuyor.
## - Vagonlar bu düğümün kendi `_draw()`'unda - tekerlek dönüşü yolun
##   hızına bağlı ve gövde figür değil araç.
##
## Zemin çizgisini kendisi hesaplamıyor, `TravelBand`'den alıyor
## (`ground_line_changed`). İkisi ayrı hesaplarsa kervan eğimli yolda
## havada ya da toprağın içinde yürüyor.

## Lider kolonun ne kadar önünde. Atlıysa daha önde: at yürüyüşü hızlı.
const LEAD_WALKING: float = 92.0
const LEAD_MOUNTED: float = 148.0

## Kolon aralıkları. **Hepsi boşluk, konum değil.** Yerleşim sabit
## adımlarla değil, her parçanın gerçek genişliğini tüketen bir imleçle
## kuruluyor (bkz. _layout): sabit adım kullanıldığında vagon genişliği
## ya da öküz boyu değişince çakışma geri geliyordu - iki kez yaşandı,
## önce iki vagon üst üste bindi, sonra arkadaki vagonun öküzü öndeki
## vagonun içine girdi. Boşluklar birbirine eklendiği için çakışma artık
## tasarım gereği imkânsız.
const GAP_TIGHT: float = 26.0
const GAP_NORMAL: float = 46.0
const GAP_WAGONS: float = 88.0
## Öküz ile çektiği vagon arasındaki ok mesafesi.
const HITCH_GAP: float = 22.0

## Yan yana en fazla iki kişi yürüyor. Aralarındaki mesafe **kişinin
## genişliğinden türetiliyor**, sabit değil: sabit bir 30 piksel,
## seksen piksel genişliğindeki bir figürde iki kişiyi üst üste
## bindiriyordu. Kolonun geri kalanında olduğu gibi burada da ölçü
## boşluk, konum değil.
const PAIR_GAP: float = 22.0
const MAX_ABREAST: int = 2

## Figür boyları (şeridin yüksekliğine oranlı, yoksa küçük ekranda dev
## gibi duruyorlar).
const PERSON_HEIGHT_RATIO: float = 0.19
const MOUNTED_HEIGHT_RATIO: float = 0.27
## Öküz de köpek/eşekle aynı tuzağa düşmüştü, bir kat daha derinden: 0.15
## kutu oranı ekranda öküzü bir insanın **%57'si** olarak çiziyordu, yani
## bir dana. Sebep iki payın üst üste binmesi - `FigureRig` insanı
## kutusunun %86'sına çiziyor, `BeastRig`'in öküz derisi ise kendi
## kutusunun yalnızca **%62'sine** (ölçüldü: 60/86/120 piksellik üç kutu,
## çizilen 37/53/75 - pay sabit, yani ölçek doğrusal). Hedef oyuncunun
## kendi ölçüsü: boynuzun ucu bir insanın **omzunda** (~%82), eşeğin
## kafasıyla aynı hiza. Hesap 0.82 * 0.86 * 0.19 / 0.617 = 0.217 diyor;
## ölçüm 0.222'de durdu (çizilen %84.6), çünkü hub'ın zaten doğru olan
## öküzü %85.5'te ve iki ekranın aynı hayvanı aynı oranda görmesi gerek -
## üstelik eşek %82.7'de, ve bir öküz bir eşekten iridir.
const OX_HEIGHT_RATIO: float = 0.222

## Köpek/eşek/yarım vagon kolonun en arkasında, tek sıra bir "sürü" olarak
## yürüyor - `world_hub.gd`'nin aynı kararının yol ekranındaki karşılığı
## (bkz. CLAUDE.md'nin "beş yeni tür" notu): tam kolon formülü (muhafız
## grubu, öküz-vagon birimi) en fazla 2 köpek + 3 eşek/yarım vagon için
## aşırıydı, sabit genişlikli basit bir kuyruk yeterli. Yarım vagon eşekle
## aynı hayvanla çiziliyor - ikisi de `GameSession.pack_inventory`'nin aynı
## kapasite havuzunu paylaşıyor, görsel olarak da ayrışmaları gerekmiyor.
## Bu iki oran `BeastRig`'in **nominal** `h`'si, çizilen yükseklik değil:
## bir dörtayaklının sırtı `SPECIES.back * h`'de durur, kafa daha yukarı
## çıkar, yani gerçek siluet `extent(species).size.y * h` kadardır (husky
## 0.57, eşek 0.85). İlk değerler (0.10/0.13) bu farkı atladığı için
## kutudan okunduğunda makul görünüp ekranda köpeği insanın %32'si,
## eşeği %47'si olarak çiziyordu - oyuncunun "ikisi de çok küçük"
## raporu buydu. Hedef oyuncunun kendi ölçüsü: eşeğin kafası
## (kulaklarıyla) bir insanın **omzu** hizasında (~%82), köpek **diz ile
## bel arasında** (~%45). Oranlar o hedeften geri hesaplanıp sonra gerçek
## karede ölçülerek düzeltildi - hesap `PERSON_HEIGHT_RATIO`'yu insanın
## boyu sanıyor, oysa o kutunun boyu: `FigureRig` bir insanı kutusunun
## ancak ~%86'sına çiziyor, yani yalnız hesapla kalmak ikisini de %10 iri
## bırakıyordu (bkz. world_hub.gd'nin aynı notu).
const DOG_HEIGHT_RATIO: float = 0.135
const DONKEY_HEIGHT_RATIO: float = 0.163
## Kutu eni / nominal `h` - `BeastRig.extent(species).size.x`'in kendisi.
const DOG_WIDTH_RATIO: float = 1.20
const DONKEY_WIDTH_RATIO: float = 1.40
const PACK_GAP: float = 18.0

## Bir vagonu **tek öküz** çeker. Bir süre çift öküzdü (bkz. Faz 10'un
## ART-C hattı) - tek hayvanın boyunduruk değil at koşumu gibi okunduğu
## gerekçesiyle - ama açıkça istenerek teke geri döndü (bkz. CLAUDE.md
## Art Rules). Eski çiftin geriye itme işaretleri (`PAIR_LEAD`/`RISE`/
## `DEPTH`/`SHADE`) bu yüzden kalkı: tek hayvan artık kendi tam boyutunda
## ve tam tonunda, koşumun tam ortasında duruyor.

## Yürüyüş temposu artık sabit bir sayı değil: her figür adımını zeminin
## kendi hızından alıyor (`WalkFigure.advance_ground`) - kadans = zemin
## hızı / o figürün çevrim başına yolu. Bunun öncesinde `STEP_RATE` (0.52
## çevrim/s) vardı ve 320 piksellik bir şeride göre ölçülmüştü; tam ekran
## 1080p'de insan 119 piksel olunca aynı 0.52 bacaklara zeminin iki katı
## yol yürütüyordu: yere basan ayak geriye kayıyordu (ay yürüyüşü). Hayvanlar
## da aynı sayıyı paylaşıyordu, oysa öküzün adımı insanınkinin yarısı.

## Vagon ölçüleri. Genişlik yükseklikten biraz fazla: bir kervan vagonu
## kareye yakındır, ilk ölçüde 1.6 katıydı ve balon gibi duruyordu.
const WAGON_WIDTH_RATIO: float = 0.21
const WAGON_HEIGHT_RATIO: float = 0.17
## Kamp ateşinin taş çemberi ve odunları (render, gerçek boy).
const CAMPFIRE_PROP: String = "bonfire"

## Çizilen yürüyen tayfa sayısı tavanlı: altı vagonlu bir kervanda on iki
## tayfa var ama her biri kendi poligonlarını çiziyor ve Web hedefinde
## bunun bedeli görünür. Arabacılar zaten vagonun üstünde çiziliyor;
## yürüyenler onların fazlası.
const MAX_WALKING_CREW: int = 4

## Kamp ateşi vagon başına bir tane. Tek ateş kolonun önündeydi (boş
## alan, hiçbir silüetin arkasına düşmüyordu); vagon başına çoğaltınca o
## kaçış yolu yok - her ateş kendi vagonunun **arkasına** (kuyruk yönüne)
## kayıyor, çünkü önü zaten o vagonun öküzü ve tayfasıyla dolu. Vagonlar
## arası boşluk (`GAP_WAGONS`) bunu rahatça karşılıyor; ölçüldü, en
## yakın komşu figüre değmiyor.
const CAMPFIRE_TRAIL_RATIO: float = 0.62
## Zemin çizgisinden biraz izleyiciye doğru (aşağı) - tam tekerleğin
## dibine oturmasın diye (bkz. Art Rules'un "yakın olan aşağıda" kuralı).
const CAMPFIRE_NEAR_OFFSET: float = 9.0
const FIRE_FLICKER_SPEED: float = 9.0

## İnsanlar ateşe yürüyor, hayvanlar ve lider yerinde kalıyor: öküz
## koşumdan çözülmüyor, lider nöbette kabul ediliyor. "İnsanlar" tayfanın
## ikisi de - yürüyen ve süren (bkz. `_driver_figures`'ın notu), yoksa
## tek kişilik bir ateş "kervandakiler toplandı" demiyordu. Süre
## `CAMP_HOURS` (8 oyun saati) yanında görünmeyecek kadar kısa olmamalı
## ama oyuncunun sabrını da sınamamalı.
##
## Süre figür başına: herkes kendi yoluna göre yürür (`_figure_gather_seconds`),
## ne en yavaşa ne en uzağa göre beklenir. Üst sınır `MAX_GATHER_SECONDS`:
## eskiden en uzak figürün tempolu hızı herkesi 30-60 saniyeye bağlıyordu ve
## sayaç yürüyüş bitmeden başlıyordu - ateşe varana kadar sabah oluyordu
## (görev 12.2c). Oyun hızı çarpanı yürüyüşe de uygulanıyor
## (`set_gather_time_scale`).
const CAMP_GATHER_SECONDS: float = 1.0
const MAX_GATHER_SECONDS: float = 3.0
## Üst sınır yüzünden tempolu hızın kaç katına çıkılabileceği: uzak bir figür
## 3 saniyeye sığmak için biraz koşar, ama kendi yürüyüşünden iki katından
## fazla değil (ondan sonrası yola ateşi yaklaştırarak, bkz. `_nearest_fire`).
const GATHER_JOG_FACTOR: float = 2.0
## Ateşin tutuşma süresi (gerçek saniye, oyun hızıyla ölçekli).
const IGNITE_SECONDS: float = 0.7
## Ateş resminin (bonfire/body.png) alt kısmı odun, üstü alev. Tutuşmadan
## önce yalnızca odun görünür; oran resmin yüksekliğinden (145 satırın
## ~100'ünden aşağısı).
const CAMPFIRE_LOGS_FROM: float = 0.72
## Attan inmenin/koltuktan inmenin süresi (gerçek saniye): sekiz karelik
## klip (FigureActions `dismount`/`climb_down`). Binmek aynı süre, tersten.
const TRANSITION_SECONDS: float = 1.5
## Klip gerçek zemine göre yazıldı, eyer/koltuk ise o atın ve vagonun kendi
## ölçüsünde: aradaki fark kalçaya eklenip ilk ayak yere değene kadar
## sönüyor (bkz. `_transition_hip`).
const SEAT_BLEND_U: Dictionary = {"dismount": 0.72, "climb_down": 0.62}

## Aynı ateşe birden fazla kişi geliyor (sürücü + yürüyen tayfa + sırayla
## dağılan parti). Hedefleri tek noktaya kenetlemek tek bir figür gibi
## görünmelerine yol açıyordu - "kervandakiler toplandı" hissi tam da bu
## yüzden kayboluyordu. Her koltuk ateşin etrafında küçük bir (x, y)
## kayma alıyor - yalnızca sağa/sola değil, ateşin önüne/arkasına da -
## böylece bir çember okunuyor, tek bir yatay sıra değil. `x` bileşenleri
## kasıtlı olarak birbirinden ayrı tutuluyor (bkz. `_fire_tolerance` ve
## `test_camp_gathering.gd`'nin üst üste binme testi): ayrım ekseni yine
## `x`, `y` yalnızca kümeyi ateşin tamamen etrafına yayıyor.
##
## Koltuklar ateşin **iki yanında**, odunu açık bırakarak: ilk sürüm
## (±2.3 birim) ateşin kendi genişliğinden darın kaldı ve altı kişilik bir
## ateşte herkes odunun üstünde, alevi örterek duruyordu (vitrin karesinde
## görüldü, Y-G13). Figürler ateşin üstüne çizildiği için önünde ya da
## arkasında oturmak yok; sıra soldan sağa dönüşümlü, içten dışa.
const CAMPFIRE_SEAT_SPACING: float = 15.0
const CAMPFIRE_SEATS: Array[Vector2] = [
	Vector2(-2.9, 0.4), Vector2(3.1, -0.3), Vector2(-4.7, -0.5),
	Vector2(4.9, 0.5), Vector2(-6.4, 0.1), Vector2(6.6, -0.4),
]

var _anchor_x: float = 0.0
## Ölçeğin hesaplandığı çapa (ileri yöndeki) - negatifse `_anchor_x`.
var _scale_anchor_x: float = -1.0
var _ground_y: float = 0.0
## HUD katmanının dünyanın üstüne çizdiği bir panel varsa (bkz. "Kervan
## Emirleri"), o panelin sağ kenarı - kolon bunun solunda hiç durmuyor,
## sığmıyorsa `COLUMN_EDGE_MARGIN`'in yerine bu tavana göre küçülüyor.
## Sıfır (varsayılan) eski davranış: hiçbir çağıran bunu ayarlamazsa
## `COLUMN_EDGE_MARGIN` hiç değişmeden kullanılır.
var _safe_left: float = 0.0
var _light: Color = Color.WHITE
## Kervanın zemine göre hızı (bu düğümün pikseli/saniye). Bacaklar,
## tekerlek ve branda bundan; yol ekranı manzarayı aynı hızla kaydırıyor.
var _ground_speed: float = 0.0
## Dönüşte lider kendi yolunu sürüyor; adımı o yoldan (bkz. _advance_leader).
var _leader_last_x: float = 0.0

## İkincil hareket (bkz. WalkFigure'ın OX_NOD_RATIO'su): vagonun brandası
## tekerleğin ritmiyle salınıyor, yağmurda ve fırtınada insanlar rüzgâra
## eğiliyor. Rüzgâr yalnızca insanları eğiyor - öküz ve vagon eğilmez,
## eğilen bir vagon devrilen bir vagondur.
const CANOPY_SWAY_RATIO: float = 0.03
const WIND_LEAN: Dictionary = {
	RouteWeather.RAIN: 0.035,
	RouteWeather.STORM: 0.07,
}
## Bora: eğilme sabit değil, figür başına kaydırılmış bir dalga - herkes
## aynı anda aynı açıya eğilirse rüzgâr değil kalıp okunur.
const GUST_AMPLITUDE: float = 0.35
const GUST_SPEED: float = 1.7
var _wind_lean: float = 0.0
var _anim_time: float = 0.0
## Vagonların yürüyüş genliği - figürlerin `_motion`'ının aynısı, aynı
## sönümle: kervan durunca branda bir karede donmasın.
var _wagon_motion: float = 0.0
## Liderin kolondaki yeri: 0 en önde, negatif geriye doğru.
var _leader_offset: float = 0.0
var _wagon_count: int = 1
var _wheel_angle: float = 0.0
var _scale: float = 1.0

## Kervanın **en arkasındaki** noktanın çapaya uzaklığı, yürüyüş yönünde
## (geride kaldığı için eksi). Yolun başındaki kapı buna bakıyor: kervan
## yola çıktığında son vagon kapıdan yeni çıkmış olmalı, lider kapının önünde
## değil (lidere hizalı kapı, kervan kapıya giriyormuş gibi okunuyordu).
func get_rear_offset() -> float:
	if _leader == null:
		return 0.0
	if _heading < 0.0:
		return -(_lead_at(_scale) + _leader.size.x * 0.5)
	return -_walk_column(_scale, false)

## Yerleşimin hesapladığı vagon merkezleri. Çizim bunları okuyor,
## kendi aritmetiğini yapmıyor: iki ayrı formül tam olarak öküzün
## vagonun içine girmesine yol açan şeydi.
var _wagon_centres: Array[float] = []

## Kamp durumu. Ayrı bir yön değişkeni yok - `_camping`'in kendisi yön:
## herkesin sayacı (`_gather_walk`/`_gather_trans`) ona doğru akıyor.
var _camping: bool = false
var _camp_time: float = 0.0
## Her toplanan figürün kendi ilerleyişi: `_gather_walk` 0 kolonda, 1
## ateşte; inip binenlerin (`_gather_trans`) önce inişi bitiyor, sonra
## yürüyor, dönüşte önce yürüyüp sonra biniyor. Herkesin kendi sayacı var,
## çünkü sıra kişiye göre değişiyor - tek bir paylaşılan sayaç arabacıyı
## koltuktan doğrudan ateşe kaydırıyordu (kullanıcı raporu: "önce vagondan
## inmeli"). Yön yine `_camping`: kamp yarıda bozulursa herkes kaldığı
## yerden geri döner.
var _gather_walk: Dictionary = {}
var _gather_trans: Dictionary = {}
## Oyun hızı çarpanı: toplanma ve dönüş animasyonları gerçek saniyeyle değil
## bununla ölçekli akıyor (3x'te üç kat hızlı). Yol ekranı her karede yazar.
var _gather_time_scale: float = 1.0
## Ateş başına tutuşma ilerlemesi 0-1. Anahtar yoksa ateş yanmamıştır; ilk
## varan figürle ateşin kendisi tutuşuyor (görev 12.2c).
var _fire_ignite: Dictionary = {}
var _gather_clip: Dictionary = {}
## Toplanan her figürün kolondaki "ev" konumu ve ateşteki hedefi - ikisi
## arasında kendi `_gather_walk`'ı kadar ilerliyor. `_layout()` her çalıştığında
## tazeleniyor (bkz. `_layout`), o yüzden ekran yeniden boyutlanırsa bile
## bayat bir eve dönmüyor.
var _gather_homes: Dictionary = {}
var _gather_targets: Dictionary = {}
## Her toplanan figürün gittiği ateşin sırası - `_layout()` yeniden
## çalışırsa (bkz. `_place`'in kamp yönlendirmesi) hedefi aynı ateşe göre
## tazeleyebilmek için.
var _gather_fire_index: Dictionary = {}
## Aynı ateşe atanan figürler tek noktada üst üste binmesin diye her
## figürün oturduğu "koltuk" sırası - bkz. `_seat_offset`.
var _gather_seat_index: Dictionary = {}
var _gathering_figures: Array[WalkFigure] = []

var _leader: WalkFigure
var _leader_mounted: bool = false
## Atlı liderin inen hâli: kampta at yerinde kalıyor (binicisiz), lider bu
## figürle inip ateşe yürüyor. Kamp dışında görünmez.
var _leader_rider: WalkFigure
var _party_figures: Array[WalkFigure] = []
## Figür -> kişi (görev R0): sohbet, bağ ve baloncuk kimin kim olduğunu bilmeli.
## Tayfa figürleri burada yok (isimsiz yürürler, v2).
var _figure_character: Dictionary = {}
## İkişerli yürüyen her çiftin aralık çarpanı (R1 #2): dostlar sıkı, düşmanlar
## açık. Sıra savaş sırası olduğu için değişmez, yalnızca aralık.
var _pair_gap_scales: Array[float] = []

func set_pair_gap_scales(scales: Array[float]) -> void:
	_pair_gap_scales = scales
	_layout()
var _crew_figures: Array[WalkFigure] = []

## --- Yol tepkileri (görev N31d) ---
## Yolda bir işaret belirince o bölgeye en yakın yaya ileri bakar (göze siper);
## kervan durmuşken yayalar yorgun bekler. Yalnızca duran kervanda: yürüyen bir
## figürü duruş klibine sokmak ayağını zeminde kaydırırdı.
const LOOK_SECONDS: float = 2.8
const REACTION_CLIPS: Array[String] = ["look_ahead", "idle_tired"]
var _look_timers: Dictionary = {}
var _tired: bool = false

## Tepki verebilecek yayalar: kadro ve tayfa, kampa yürümeyen, başka bir
## klibin (iniş, biniş) ortasında olmayan.
func _reaction_walkers() -> Array[WalkFigure]:
	var out: Array[WalkFigure] = []
	for figure in _party_figures + _crew_figures:
		if figure == null or not figure.visible or _gather_homes.has(figure):
			continue
		var clip := figure.get_action()
		if clip.is_empty() or REACTION_CLIPS.has(clip):
			out.append(figure)
	return out

## Bakış tepkisi kapalı: 3B render'da el alnın önüne değil başın üstüne
## düşüyor ("eli başında" okunuyor). Poz düzelip yeniden render edilince açılır.
const LOOK_ENABLED: bool = true

## Bölgeye (RoadAttention: front/wagons/rear) en yakın yaya bakar.
func react_look(zone: String) -> void:
	if not LOOK_ENABLED or _ground_speed > 1.0 or _camping:
		return
	var walkers := _reaction_walkers()
	if walkers.is_empty():
		return
	var best: WalkFigure = walkers[0]
	var best_score := -INF
	var wagons := get_wagon_centres()
	var wagon_mid := 0.0
	for x in wagons:
		wagon_mid += x / float(wagons.size())
	for figure in walkers:
		var x := (figure.position.x + figure.size.x * 0.5) * _heading
		var score := x
		if zone == RoadAttention.ZONE_REAR:
			score = -x
		elif zone == RoadAttention.ZONE_WAGONS:
			score = -absf(figure.position.x + figure.size.x * 0.5 - wagon_mid)
		if score > best_score:
			best_score = score
			best = figure
	best.set_action("look_ahead")
	_look_timers[best] = LOOK_SECONDS

## Kervan durduğunda yorgun bekleyiş; yürümeye başlayınca biter.
func set_tired(on: bool) -> void:
	if on == _tired:
		return
	_tired = on
	for figure in _reaction_walkers():
		if not _look_timers.has(figure):
			figure.set_action("idle_tired" if on else "")

func _tick_reactions(delta: float) -> void:
	if _look_timers.is_empty():
		return
	for figure in _look_timers.keys():
		_look_timers[figure] = float(_look_timers[figure]) - delta
		# Kervan yürümeye başladıysa bakış hemen biter (kayan ayak olmasın).
		if float(_look_timers[figure]) <= 0.0 or _ground_speed > 1.0:
			_look_timers.erase(figure)
			if is_instance_valid(figure) and figure.get_action() == "look_ahead":
				figure.set_action("idle_tired" if _tired else "")
## Arabacılar - normalde `ArtDraw.wagon()`'un çizdiği sabit silüet, kamp
## sırasında gerçek birer figüre dönüşüyor (bkz. `configure`'daki not).
var _driver_figures: Array[WalkFigure] = []
## Vagon başına tek öküz - koşumun ölçüsünü bunlar belirliyor.
var _oxen: Array[WalkFigure] = []
## Boyunduruğun çizildiği katman: figürlerin *üstünde* (son çocuk), çünkü
## boyunduruk öküzün boynunun önünden geçer. Ok ise `_draw()`'da, öküzün
## arkasında kalır (görev 10.4).
var _harness: Control
## Köpek/eşek/yarım vagon "sürüsü" - kolonun en arkasında. `_pack_is_dog`
## aynı indekste hangi hayvanın çizildiğini tutuyor (WalkFigure kendi
## türünü dışarı vermiyor), sırası `configure()`'daki ekleme sırasıyla
## birebir aynı: önce köpekler, sonra eşekler/yarım vagonlar.
var _pack: Array[WalkFigure] = []
var _pack_is_dog: Array[bool] = []
## Yarım vagon: eşeğin arkasında render edilmiş tek akslı araba (PropArt
## "half_cart"). Eşekle araba tek birim - dönüşte birlikte aynalanıyor.
var _pack_has_cart: Array[bool] = []
## Her araba için {"x": çapa x, "unit": birim}.
var _carts: Array[Dictionary] = []
const CART_PROP: String = WagonFigure.CART_PROP
const CART_HITCH_M: float = WagonFigure.CART_HITCH_M
const CART_TAIL_M: float = WagonFigure.CART_TAIL_M

## Altında bir şey çizmenin anlamı olmadığı boy. Bunun altında vagonun
## bütün ölçüleri piksel altına düşüyor ve çokgenlerin köşeleri aynı
## float'a çöküyor - Godot "Invalid polygon data, triangulation failed"
## basıp çizimi atlıyor, oyunu durdurmuyor. Yani ekran görüntüsü
## alınmadan hiç görülmeyecek bir hata; yapısal testler de görmüyor.
const MIN_DRAW_HEIGHT: float = 60.0

## Kolon çapanın arkasına sığmıyorsa **küçülüyor**, taşmıyor. Zemin
## ölçüldü: 1920×320'lik şeritte iki vagonluk bir kervanın ikinci vagonu
## x = -264'te, yani ekranın dışındaydı; oyuncu kaç vagon alırsa alsın
## yolda hep tek vagon görüyordu. Önce çapa sağa kayıyor (bedava), sonra
## gerekirse kolon küçülüyor - ama bir yere kadar: altı vagonluk bir
## kervanı tamamen sığdırmak figürleri karınca boyuna indiriyor. Zeminde
## kalan taşma dürüst olan: uzun bir kervan görüş alanından uzundur.
const MIN_COLUMN_SCALE: float = 0.58
const COLUMN_EDGE_MARGIN: float = 20.0

## Kolonun çapadan geriye doğru istediği yer (ölçeklenmemiş). Şerit
## çapayı buna göre kaydırıyor.
signal column_length_changed(trailing_px: float)
## Kervanın geri dönüşü bitti - yol ekranı zamanı yeniden akıtıyor.
signal turn_finished
## Bir kamp ateşi tutuştu (ilk figür vardı) - ses için (görev 12.2c).
signal fire_lit(index: int)
## Kamp kalktı, bütün ateşler söndü.
signal fires_out

## --- Dönüş ---
## Kervan geri dönünce yerinde, sırayla dönüyor: lider önce atını çeviriyor,
## sonra kolon boyunca yeni başa sürüyor; her birim (muhafız çifti, tayfa-
## öküz-vagon, yük hayvanı) emir kendisine ulaşınca kendi merkezinde dönüyor.
## Sıra yeni bir diziliş değil: gerçek bir kervan yol ortasında sırasını
## değiştirmez, yerinde döner - arkadaki vagon artık öndedir. Birim, bir
## kâğıt figür gibi ince bir çizgiye inip öbür yüzüyle açılıyor ve dönerken
## yolun uzak şeridine doğru biraz yükseliyor: yandan bakışta derinlikte
## dönen bir şey böyle okunuyor.
const TURN_SECONDS: float = 10.0
const LEADER_PIVOT_SECONDS: float = 0.6
const UNIT_TURN_SECONDS: float = 1.3
## Dönen birimin uzak şeride kalkışı, şerit yüksekliğine oranlı.
const TURN_LIFT_RATIO: float = 0.03
## Dönerken ayaklar: yerinde bir çeyrek tur atmak da yürümektir - sakin
## bir yürüyüşün temposunda (1.6 çevrim/s'ydi: yerinde koşu).
const TURN_WALK_STEP: float = WalkFigure.WALK_CADENCE
## En ince hâlinde bile çokgen çökmesin (bkz. MIN_DRAW_HEIGHT'ın notu).
const MIN_TURN_WIDTH: float = 0.06

var _heading: float = 1.0
var _turn_from: float = 1.0
var _turning: bool = false
var _turn_time: float = 0.0
var _turn_leader_from: float = 0.0
var _turn_leader_to: float = 0.0
## Kolonun birimleri, önden arkaya, **ileri** yöndeki yerleşimde:
## {figures: Array[WalkFigure], wagon: int (-1 yok), centre: float}.
## `_walk_column` her yerleşimde yeniden dolduruyor.
var _units: Array[Dictionary] = []
## Her birimin yüzü: +1 ileri, -1 geri, arada dönüşün ortası.
var _unit_facing: Array[float] = []
## Birimin dönmeye başladığı an (dönüş saatinde) - emir dalga gibi iniyor.
var _unit_turn_start: Array[float] = []
var _unit_lift: Array[float] = []
var _figure_unit: Dictionary = {}
var _wagon_unit: Array[int] = []
## Liderin zemine göre hızı (şerit pikseli/saniye) ve kolonda kendi başına
## yürüyüp yürümediği - bkz. set_leader_motion.
var _leader_ground: float = 0.0
var _leader_walking: bool = false
var _leader_turn_scale: float = 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Çapa ön ayarı boyutu *bir sonraki* yerleşim geçişinde veriyor, yani
	# `configure()` çağrıldığı anda boy hâlâ sıfır olabiliyor. Yeniden
	# boyutlanmayı dinlemezsek kolon o sıfır boyla yerleşip öyle kalıyordu:
	# figürler görünmez, vagonlar yarım piksel.
	resized.connect(_on_resized)

func _on_resized() -> void:
	_layout()
	queue_redraw()
	if _harness != null:
		_harness.size = size

## Kervanı oturumdan kurar. Her çağrı figürleri yeniden yaratıyor, o yüzden
## sefer başında (ve parti değişince) çağrılmalı, karede değil.
func configure(session: GameSession, mounted_leader: bool = true) -> void:
	for child in get_children():
		child.queue_free()
	_party_figures.clear()
	_figure_character.clear()
	_crew_figures.clear()
	_driver_figures.clear()
	_oxen.clear()
	_pack.clear()
	_pack_is_dog.clear()
	_pack_has_cart.clear()
	_leader = null
	_leader_rider = null

	# Kamp durumu eski figürlere işaret ediyor olabilir - `queue_free()`
	# bu kareyi bitirene kadar onları serbest bırakmıyor, ama kamp/kayıt
	# durumu temizlenmezse `_process()` bir sonraki karede "previously
	# freed" bir düğüme erişmeye çalışır (bu tam olarak sefer başına bir
	# kez çağrılan bir fonksiyon olduğu için nadiren yakalanan bir hata -
	# yol ekranında hep tek bir `configure()` çağrısı vardır, çoklu şehir/
	# vagon karesi basan araçlarda ise `RoadCaravan` yeniden kullanılıyor).
	_camping = false
	_turning = false
	_units.clear()
	_unit_facing.clear()
	_unit_turn_start.clear()
	_unit_lift.clear()
	_figure_unit.clear()
	_wagon_unit.clear()
	_leader_walking = false
	_leader_turn_scale = 1.0
	_gathering_figures.clear()
	_gather_homes.clear()
	_gather_targets.clear()
	_gather_fire_index.clear()
	_gather_seat_index.clear()
	_gather_walk.clear()
	_gather_trans.clear()
	_gather_clip.clear()
	_fire_ignite.clear()

	_wagon_count = maxi(1, session.owned_wagon_count)
	_leader_mounted = mounted_leader

	var party := session.party
	var player := session.get_player_character()

	_leader = _make_figure(
		WalkFigure.KIND_MOUNTED if mounted_leader else WalkFigure.KIND_PERSON,
		_archetype_of(player), _height_scale_of(player), _skin_of(player), false, player
	)
	_leader.set_facing(1.0)
	if mounted_leader:
		_leader_rider = _make_figure(
			WalkFigure.KIND_PERSON, _archetype_of(player), _height_scale_of(player), _skin_of(player),
			false, player
		)
		_leader_rider.visible = false

	# Parti lideri takip ediyor; sıra savaş sırası (bkz. Character & Party
	# Rules), o yüzden kolonda gördüğün diziliş savaşta göreceğin diziliş.
	for character in party:
		if character == player:
			continue
		var figure := _make_figure(
			WalkFigure.KIND_PERSON, _archetype_of(character),
			_height_scale_of(character), _skin_of(character), true, character
		)
		_party_figures.append(figure)
		_figure_character[figure] = character


	for index in _wagon_count:
		_oxen.append(_make_figure(
			WalkFigure.KIND_OX, "bandit", 1.0, WalkFigure.FALLBACK_SKIN, false
		))

	# Vagon başına iki tayfa var (`PEOPLE_PER_WAGON`): biri sürüyor -
	# `ArtDraw.wagon` onu brandanın önünde çiziyor - biri yürüyor. Yani
	# yürüyen tayfa sayısı vagon sayısı kadar.
	var walking_crew := mini(MAX_WALKING_CREW, _wagon_count)
	for index in maxi(0, walking_crew):
		# Tayfa isimsiz: sınıfı yok, o yüzden nötr bir silüet paleti
		# taşıyorlar. Ten renkleri yine oyunun kendi tonlarından.
		_crew_figures.append(_make_figure(
			WalkFigure.KIND_PERSON, "bandit", 0.94 + float(index % 3) * 0.04,
			CharacterData.get_skin_tone_color(index), true
		))

	# Arabacı normalde `ArtDraw.wagon()`'un kendi çizdiği sabit bir silüet -
	# bkz. oradaki `draw_driver`. Kamp kurulunca o koltuğu gerçek bir figür
	# devralıyor (bkz. `_begin_gathering`), yoksa "kervandakiler ateşe
	# gelsin" sözü tek kişiyle (yürüyen tayfa) sınırlı kalırdı; sürücü de
	# aynı vagonun adamı. Görünmez başlıyor - kamp kurulana kadar sahnede
	# hiçbir işi yok, sabit silüet onun yerini tutuyor.
	for index in maxi(0, walking_crew):
		var driver := _make_figure(
			WalkFigure.KIND_PERSON, "bandit", 0.92 + float((index + 1) % 3) * 0.04,
			CharacterData.get_skin_tone_color(index + 2), false
		)
		driver.visible = false
		_driver_figures.append(driver)

	# Köpek/eşek/yarım vagon: üçü de kervanın kendi mülkü (bkz. GameSession
	# owned_dogs/owned_donkeys/owned_half_wagons), tayfa gibi isimsiz -
	# nötr bir palet yetiyor. Yarım vagon eşekle aynı figürle çiziliyor.
	for index in session.owned_dogs:
		_pack.append(_make_figure(
			WalkFigure.KIND_DOG, "bandit", 1.0, WalkFigure.FALLBACK_SKIN, false
		))
		_pack_is_dog.append(true)
		_pack_has_cart.append(false)
	for index in session.owned_donkeys + session.owned_half_wagons:
		_pack.append(_make_figure(
			WalkFigure.KIND_DONKEY, "bandit", 1.0, WalkFigure.FALLBACK_SKIN, false
		))
		_pack_is_dog.append(false)
		_pack_has_cart.append(index >= session.owned_donkeys and PropArt.has(CART_PROP))

	_harness = Control.new()
	_harness.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_harness.draw.connect(_draw_yokes)
	add_child(_harness)
	_harness.size = size
	_layout()

## `character` isimli bir kişi için (lider, parti): kıyafeti ve üstündeki
## sprite'lı kalemler yolda da görünsün. Tayfa ve öküz için null.
func _make_figure(
	kind: String, archetype: String, height_scale: float, skin: Color, pack: bool,
	character: CharacterData = null
) -> WalkFigure:
	var figure := WalkFigure.new()
	add_child(figure)
	var outfit: Dictionary = character.get_appearance_outfit() if character != null else {}
	var body_variant := character.get_body_variant_id() if character != null else ""
	if character == null and kind == WalkFigure.KIND_PERSON:
		body_variant = BodyFrames.CREW_BODY
		outfit = OutfitCatalog.with_rolled_hair(outfit, CharacterData.GENDER_MALE, get_child_count() * 7919)
	figure.set_kind(kind, archetype, height_scale, skin, pack, outfit, body_variant)
	figure.set_loadout(Wardrobe.loadout_for(character))
	# Faz kaydırması: aynı anda aynı adımı atan bir kervan yürüyüş kolu
	# gibi duruyor.
	figure.set_phase_offset(float(get_child_count()) * 1.27)
	return figure

func _archetype_of(character: CharacterData) -> String:
	if character == null:
		return "guard"
	return character.class_id if not character.class_id.is_empty() else "guard"

## Boy yolda görünüyor: karakter oluşturmada seçilen boy bir metin değil.
func _height_scale_of(character: CharacterData) -> float:
	if character == null:
		return 1.0
	return character.get_height_scale()

func _skin_of(character: CharacterData) -> Color:
	if character == null:
		return WalkFigure.FALLBACK_SKIN
	return CharacterData.get_skin_tone_color(character.skin_tone)

## `TravelBand`'in bildirdiği zemin çizgisi. Kervanın bastığı yer burası.
func set_ground_line(anchor_x: float, ground_y: float, scale_anchor_x: float = -1.0) -> void:
	_scale_anchor_x = scale_anchor_x
	# Çapa ön ayarına güvenmiyoruz. `PRESET_FULL_RECT` boyutu ancak
	# ebeveyn *yeniden boyutlanınca* çocuğa geçiriyor; manzara şeridi
	# kendi boyunu biz eklemeden önce aldığı için o bildirim hiç gelmiyor
	# ve kolon (0,0) boyunda kalıyordu - figürler görünmez, vagonlar
	# yarım piksel. Aynı sınıf hata OnboardingPanel'de de yaşandı
	# ("bir CanvasLayer Control değildir"): çapa, altında gerçek bir
	# dikdörtgen yoksa hiçbir şey yapmıyor.
	var host := get_parent_control()
	if host != null and host.size != size:
		size = host.size

	if is_equal_approx(_anchor_x, anchor_x) and is_equal_approx(_ground_y, ground_y):
		# Zemin çizgisi aynı olsa bile kolon henüz hiç yerleşmemiş
		# olabilir (bkz. _on_resized): erken çıkış o durumda figürleri
		# sıfır boyda bırakıyordu.
		if _leader != null and _leader.size.y > 1.0:
			return
	_anchor_x = anchor_x
	_ground_y = ground_y
	_layout()
	queue_redraw()

## HUD'un "Kervan Emirleri" paneli manzaranın üstünde, sol altta duruyor
## (bkz. road_journey.gd::_build_hud_layer) - kolon onun sağından
## başlamalı, yoksa panel arka vagonu (ve öküzünü) kapatır. Panel dile
## ve genişliğe göre kendi boyunu değiştirdiği için çağıran (road_journey.gd
## ::_sync_orders_panel_safe_left) bunu her karede yeniden okuyor - erken
## çıkış (`is_equal_approx`) değişmeyen bir değeri sessizce yok saydığı
## için bu ucuz.
func set_safe_left(px: float) -> void:
	var wanted := maxf(0.0, px)
	if is_equal_approx(_safe_left, wanted):
		return
	_safe_left = wanted
	_layout()
	queue_redraw()

func set_light(light: Color) -> void:
	if _light == light:
		return
	_light = light
	for child in get_children():
		var figure := child as WalkFigure
		if figure != null:
			figure.set_tint(light)
	queue_redraw()
	if _harness != null:
		_harness.queue_redraw()

## Kervanın zemine göre hızı (piksel/s, büyüklük). Yürüyüş fazı ve
## tekerlek dönüşü bundan; manzara da aynı sayıyla kaymalı, yoksa ayak
## zeminde kayar.
func set_ground_speed(px_per_second: float) -> void:
	_ground_speed = absf(px_per_second)

func get_ground_speed() -> float:
	return _ground_speed

## Yayan bir insanın boyu (bu düğümün pikseli) - kolon ölçeği dahil.
func get_person_height() -> float:
	return maxf(size.y, 1.0) * _scale * PERSON_HEIGHT_RATIO

## Liderin (at ya da yaya) tempolu yürüyüşü: kolonda gezerken zemine göre
## hızı - dörtnal yok, koşu yok.
func get_leader_brisk_speed() -> float:
	return 0.0 if _leader == null else _leader.brisk_ground_speed()

## Normal tempoda (sakin kervan yürüyüşü) zeminin hızı: insanın kadansı
## `WalkFigure.WALK_CADENCE` olacak kadar.
func get_walk_ground_speed() -> float:
	return WalkFigure.WALK_CADENCE * FigureRig.CYCLE_DISTANCE_RATIO * get_person_height()

## Kolonun hiçbir üyesinin tempolu yürüyüşü aşmadığı en yüksek zemin hızı:
## en yavaş yürüyen üyenin tavanı. Öküz vagonu koşturamaz.
func get_brisk_ground_speed() -> float:
	var limit := WalkFigure.BRISK_CADENCE * FigureRig.CYCLE_DISTANCE_RATIO * get_person_height()
	for child in get_children():
		var figure := child as WalkFigure
		if figure == null or not figure.visible or _gather_homes.has(figure):
			continue
		var brisk := figure.brisk_ground_speed()
		if brisk > 0.0:
			limit = minf(limit, brisk)
	return limit

## En ağır yürüyüşün (kadansın alt sınırı) zemin hızı: en hızlı adım atan
## üyenin tabanı - bunun altında herkes yerinde sürünür gibi.
func get_amble_ground_speed() -> float:
	return WalkFigure.AMBLE_CADENCE * FigureRig.CYCLE_DISTANCE_RATIO * get_person_height()

func set_weather(weather: String) -> void:
	_wind_lean = float(WIND_LEAN.get(weather, 0.0))
	_rain = float(RouteWeather.visuals(weather).rain)

## Yağmurda tekerlekten çamur (görev N31e): her tekerleğin arka altından
## geriye ve yukarı küçük topaklar, tekerleğin dönüşüyle - zar yok, aynı an
## hep aynı resim. Duran tekerlek çamur atmaz.
const MUD_FLECKS: int = 5
const MUD_COLOR: Color = Color(0.20, 0.15, 0.10)
var _rain: float = 0.0

## Bir topağın yolu (tekerlek yarıçapı birimiyle, ileri +x): u 0..1 ömür.
static func mud_fleck(u: float) -> Vector2:
	return Vector2(-0.7 - u * 1.7, -0.12 - sin(u * PI) * 0.85 + u * 0.1)

func _draw_mud(centre: float, wagon_w: float, wagon_h: float, index: int) -> void:
	var amount := _rain * clampf(_wagon_motion, 0.0, 1.0)
	if amount <= 0.01:
		return
	var r := wagon_h * ArtDraw.WAGON_WHEEL_RATIO
	var mud := MUD_COLOR * _light
	for wheel_x in [centre - wagon_w * 0.30, centre + wagon_w * 0.30]:
		for k in MUD_FLECKS:
			var u := fposmod(_wheel_angle * 0.32 + float(k) / float(MUD_FLECKS) + float(index) * 0.37, 1.0)
			var p := mud_fleck(u) * r + Vector2(wheel_x, _ground_y)
			draw_circle(p, maxf(1.0, r * 0.07 * (1.0 - u * 0.5)), Color(mud, 0.85 * amount * (1.0 - u)))

## Bir figürün o anki rüzgâr eğilmesi. Saf fonksiyon (test sahnesiz okur).
static func wind_lean_at(base: float, time: float, index: int) -> float:
	if is_zero_approx(base):
		return 0.0
	return base * (1.0 + GUST_AMPLITUDE * sin(time * GUST_SPEED + float(index) * 1.3))

## Brandanın salınımı (piksel). Genlik sıfırsa tam sıfır - duran kervanın
## brandası kıpırdamaz.
static func canopy_sway_at(wheel_angle: float, index: int, wagon_h: float, motion: float) -> float:
	return sin(wheel_angle * 2.0 + float(index) * 0.9) * wagon_h * CANOPY_SWAY_RATIO * motion

## Kervan kendi temposuyla yürüyor; oyuncunun doğrudan yürüttüğü tek beden
## lider, kolon boyunca. Sınır kolonun uzunluğu: lider kervanı bırakıp
## gidemiyor.
func set_leader_offset(offset: float) -> void:
	_leader_offset = clampf(offset, -_column_length(), 0.0)
	_layout()

func get_leader_offset() -> float:
	return _leader_offset

## Işık halesinin durduğu figür: kamptaysa yürüyen binici, değilse atlı lider
## (Y-C20; `get_leader_figure()` her zaman at).
func get_visible_leader_figure() -> WalkFigure:
	return _leader_rider if _leader_rider != null and _leader_rider.visible else _leader

func get_character_of(figure: WalkFigure) -> CharacterData:
	return _figure_character.get(figure)

func get_figure_of(character: CharacterData) -> WalkFigure:
	for figure in _figure_character:
		if _figure_character[figure] == character:
			return figure
	return null

## Liderin yanında (yatay uzaklığı `radius` pikselden az) yürüyen yoldaşlar,
## en yakından uzağa. Lider kampta atından inmişse yaya figürü ölçülür.
func companions_near(radius: float) -> Array[CharacterData]:
	var out: Array[CharacterData] = []
	var leader: WalkFigure = _leader_rider if _leader_rider != null and _leader_rider.visible else _leader
	if leader == null:
		return out
	var at := leader.position.x + leader.size.x * 0.5
	var near: Array = []
	for figure in _figure_character:
		var f: WalkFigure = figure
		if not f.visible:
			continue
		var d := absf(f.position.x + f.size.x * 0.5 - at)
		if d <= radius:
			near.append([d, _figure_character[figure]])
	near.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	for entry in near:
		out.append(entry[1])
	return out

func get_column_length() -> float:
	return _column_length()

## Ekrandaki bir x (bu düğümün yerel uzayında) liderin kolondaki hangi
## yerine düşüyor - dokunarak/tıklayarak yürümenin hedefi. Aynı sınır
## `set_leader_offset`'inki: kolonun dışına tıklamak ucuna yürütür.
func leader_offset_for_x(x: float) -> float:
	if _heading < 0.0:
		return clampf(_reverse_head_x() - x, -_column_length(), 0.0)
	return clampf(x - (_anchor_x + _lead_at(_scale)), -_column_length(), 0.0)

## Geri dönmüş kolonda liderin en öndeki yeri: kolon yerinde döndüğü için
## eski kuyruk artık baş, lider onun da önünde.
func _reverse_head_x() -> float:
	return _anchor_x - _walk_column(_scale, false) - _lead_at(_scale)

## Kervanın yüzü: +1 hedefe, -1 geri. Kayıttan dönüş ve sefer başı için -
## anında, dönüşsüz. Yolda dönmek `begin_turn`.
func set_heading(heading: float) -> void:
	_heading = -1.0 if heading < 0.0 else 1.0
	_turn_from = _heading
	_turning = false
	for index in _unit_facing.size():
		_unit_facing[index] = _heading
		_unit_lift[index] = 0.0
	_leader_turn_scale = 1.0
	if _leader != null:
		_leader.set_facing(_heading)
	_layout()
	queue_redraw()

func get_heading() -> float:
	return _heading if not _turning else -_turn_from

func is_turning() -> bool:
	return _turning

## Birimlerin o anki yüzleri, önden arkaya - test okuyor.
func get_unit_facings() -> Array[float]:
	return _unit_facing.duplicate()

## Dönüşü başlatır (bkz. TURN_SECONDS'ın notu). Emir dalgası kolonun o anki
## başından kuyruğa iniyor: her birim, önündeki boydan oranlı bir anda döner.
func begin_turn(heading: float) -> void:
	var target := -1.0 if heading < 0.0 else 1.0
	if _turning or is_equal_approx(target, _heading):
		return
	if _leader == null:
		_heading = target
		return
	_turn_from = _heading
	_turning = true
	_turn_time = 0.0
	_leader_walking = false
	_turn_leader_from = get_leader_centre() - _anchor_x
	var trailing := _walk_column(_scale, false)
	var lead := _lead_at(_scale)
	# Yeni baş: eski kuyruğun da önü (ileri dönüşte eski yerleşimin başı).
	_turn_leader_to = -trailing - lead if target < 0.0 else lead
	var front := lead if _turn_from > 0.0 else -trailing - lead
	var span := maxf(1.0, trailing + lead)
	var wave := TURN_SECONDS - LEADER_PIVOT_SECONDS - UNIT_TURN_SECONDS
	_unit_turn_start.resize(_units.size())
	for index in _units.size():
		var centre: float = float(_units[index].centre) - _anchor_x
		var along := clampf((front - centre) * _turn_from / span, 0.0, 1.0)
		_unit_turn_start[index] = LEADER_PIVOT_SECONDS + along * wave

## Yol ekranı her karede liderin zemine göre hızını veriyor: kolonda kendi
## başına yürüyorsa (`walking`) yüzü ve adımı bundan, yoksa kervanla aynı
## adımı atıyor. Zemine göre: geri giden lider arkasını döner, kervandan
## yavaş geri çekilen lider hâlâ ileri yürür - ikisi de gördüğün şey.
func set_leader_motion(ground_px_s: float, walking: bool) -> void:
	_leader_ground = ground_px_s
	_leader_walking = walking

## Oyun hızı çarpanı (yol ekranı her karede yazar): toplanma ve dönüş
## yürüyüşü bununla hızlanıyor. 1'in altı yok - ağır çekimde insanlar
## sürünmesin, kamp zaten yavaş akışta kurulabiliyor.
func set_gather_time_scale(scale: float) -> void:
	_gather_time_scale = maxf(1.0, scale)

## Kamp kurulunca/kalkınca çağrılır. Ateşler burada değil `_draw()`'da
## çiziliyor (bkz. `_draw_campfires`); bu yalnızca kimin nereye
## yürüyeceğini belirliyor. Yön ayrı bir bayrak değil - sayaçlar
## `_camping`'e doğru akıyor, `_advance_gather` kararı orada veriyor.
func set_camping(camping: bool) -> void:
	if _camping == camping:
		return
	_camping = camping
	# Dönüş yarıdayken yeniden kurulan kamp toplanmayı baştan kurmuyor:
	# herkes kendi sayacıyla kaldığı yerden ateşe döner.
	if camping and _gathering_figures.is_empty():
		_begin_gathering()

## Ateşe kimin gideceği: lider (atlıysa önce attan iniyor), tayfanın
## **ikisi de** - sürücü (önce koltuktan iniyor) ve yürüyen -
## kendi vagonunun ateşine gidiyor (bkz. `_driver_figures`'ın notu, ikisi
## de vagon `i`'nin adamı). Parti üyeleri ateşler arasında sırayla
## dağıtılıyor - hepsi aynı ateşte toplanmak kalabalık, hiçbiri gitmemek
## de eksik dururdu. Lider nöbette kabul ediliyor, öküzler koşumdan
## çözülmüyor - ikisi de katılmıyor.
func _begin_gathering() -> void:
	_gathering_figures.clear()
	_gather_homes.clear()
	_gather_targets.clear()
	_gather_fire_index.clear()
	_gather_seat_index.clear()
	_gather_walk.clear()
	_gather_trans.clear()
	_gather_clip.clear()
	_fire_ignite.clear()
	if _wagon_centres.is_empty():
		return
	var fire_count := _wagon_centres.size()
	# Ateş başına kaç koltuk dolduğu - üst üste binmesinler diye (bkz.
	# CAMPFIRE_SEATS'in notu).
	var seats_taken: Dictionary = {}

	# Lider kervanın başında; en yakın ateş baştaki vagonunki.
	if _leader_mounted and _leader_rider != null:
		var rider_h := _leader.size.y * WalkFigure.MOUNT_RIDER_RATIO
		_leader_rider.size = Vector2(rider_h * 0.6, rider_h)
		_leader_rider.set_facing(_leader.get_facing())
		_assign_transition(_leader_rider, "dismount", 0, seats_taken)
		_leader.set_riderless(true)
	elif _leader != null:
		_assign_gather(_leader, 0, seats_taken)
	for index in _driver_figures.size():
		if index >= fire_count:
			break
		_assign_transition(_driver_figures[index], "climb_down", index, seats_taken)
	for index in _crew_figures.size():
		if index >= fire_count:
			break
		_assign_gather(_crew_figures[index], index, seats_taken)
	for index in _party_figures.size():
		var figure := _party_figures[index]
		_assign_gather(figure, _nearest_fire(figure, seats_taken), seats_taken)

## Parti üyesinin en yakın ateşi (yer olanlar arasında). Eskiden üyeler
## ateşler arasında sırayla dağıtılıyordu: 20 vücut boyu öteye yürüyen biri
## oluyordu (görev 12.2c). Her ateşin koltuğu sınırlı, dolanı atlıyoruz.
func _nearest_fire(figure: WalkFigure, seats_taken: Dictionary) -> int:
	var centre := figure.position.x + figure.size.x * 0.5
	var best := 0
	var best_dist := INF
	var any_free := false
	for index in _wagon_centres.size():
		if int(seats_taken.get(index, 0)) < CAMPFIRE_SEATS.size():
			any_free = true
	for index in _wagon_centres.size():
		if any_free and int(seats_taken.get(index, 0)) >= CAMPFIRE_SEATS.size():
			continue
		var dist := absf(_campfire_position(index).x - centre)
		if dist < best_dist:
			best_dist = dist
			best = index
	return best

func _take_seat(fire_index: int, seats_taken: Dictionary) -> int:
	var seat := int(seats_taken.get(fire_index, 0))
	seats_taken[fire_index] = seat + 1
	return seat

func _assign_gather(figure: WalkFigure, fire_index: int, seats_taken: Dictionary) -> void:
	if figure == null:
		return
	var seat := _take_seat(fire_index, seats_taken)
	_gathering_figures.append(figure)
	_gather_fire_index[figure] = fire_index
	_gather_seat_index[figure] = seat
	_gather_homes[figure] = figure.position
	_gather_targets[figure] = _campfire_target(figure, fire_index, seat)
	_gather_walk[figure] = 0.0

## Oturduğu yerden inen biri: arabacı koltuktan (`climb_down`), lider attan
## (`dismount`). "Ev"i oturduğu yerin hemen yanında, yerde duran hâli; iniş
## o noktada oynuyor, sonra yürüyüş oradan ateşe. Sürücü ve inen lider
## normalde sahnede değil (koltuğu `ArtDraw.wagon()`'un sabit silüeti,
## eyeri atlı figür tutuyor) - görünür olmaları burada.
func _assign_transition(figure: WalkFigure, clip: String, fire_index: int, seats_taken: Dictionary) -> void:
	if figure == null:
		return
	figure.visible = true
	_gather_clip[figure] = clip
	_gather_trans[figure] = 0.0
	var home := _transition_home(figure)
	figure.position = home
	var seat := _take_seat(fire_index, seats_taken)
	_gathering_figures.append(figure)
	_gather_fire_index[figure] = fire_index
	_gather_seat_index[figure] = seat
	_gather_homes[figure] = home
	_gather_targets[figure] = _campfire_target(figure, fire_index, seat)
	_gather_walk[figure] = 0.0
	figure.set_transition(clip, 0.0, _transition_hip(figure, 0.0))

## Oturulan yer, bu düğümün uzayında: kalçanın oturduğu nokta.
func _transition_seat(figure: WalkFigure) -> Vector2:
	if figure == _leader_rider and _leader != null:
		return _leader.position + Vector2(_leader.get_saddle_x(), _leader.get_saddle_y())
	return _driver_bench_position(int(_gather_fire_index.get(figure, _driver_figures.find(figure))))

## İnen kişinin yerde durduğu yer: oturduğu yerin hizasında, ayağı zeminde
## (`_place()`'in `ground_y - height` deseni).
func _transition_home(figure: WalkFigure) -> Vector2:
	var seat := _transition_seat(figure)
	return Vector2(seat.x - figure.size.x * 0.5, _ground_y - figure.size.y)

## Klibin `u` anında kalça, figürün kendi uzayında. Klip gerçek zeminde
## yazılmış (kalça yerden `transition_hip_height` yukarıda); başta kalça
## tam eyerde/koltukta olsun diye aradaki fark ekleniyor ve ayak yere
## değerken (`SEAT_BLEND_U`) sönüyor - bitişte kişi tam zeminde ayakta.
func _transition_hip(figure: WalkFigure, u: float) -> float:
	var clip := String(_gather_clip.get(figure, ""))
	var h := figure.person_height()
	var ground := figure.size.y
	var hip := ground - WalkFigure.transition_hip_height(clip, u, h)
	var seat_local := _transition_seat(figure).y - figure.position.y
	var start := ground - WalkFigure.transition_hip_height(clip, 0.0, h)
	var fade := smoothstep(0.0, float(SEAT_BLEND_U.get(clip, 0.7)), u)
	return hip + (seat_local - start) * (1.0 - fade)

## Figürün ateşteki hedefi. Taban çizgisi her zaman **gerçek zemin**
## (`_ground_y - height`), figürün o an durduğu yer değil - tayfa ve
## parti için ikisi zaten aynı (`_place()` onları oraya koyuyor), ama
## arabacı koltuktan (yükseltilmiş bir taban) geliyor: hedef koltuk
## yüksekliğini korusaydı arabacı ateşin yanında havada asılı kalırdı.
## Aynı hedef hem gidişte hem dönüşte kullanıldığı için (bkz.
## `_advance_gather`'ın home/dest çifti) düzeltme iki yönü de kapsıyor -
## arabacı ateşe inerken alçalıyor, dönerken yeniden koltuğa çıkıyor.
## `seat` aynı ateşe gelen ikinci/üçüncü kişiyi ateşin etrafında bir
## çembere yayıyor (bkz. CAMPFIRE_SEATS'in notu) - yoksa hepsi aynı
## noktaya biner. Taban çizgisi yine gerçek zemin: `y` bileşeni oradan bir
## sapma, ateşin kendi çizim noktasından değil - yoksa ateş her koltuk
## için ayrı bir zemin tanımlamış olurdu.
func _campfire_target(figure: WalkFigure, fire_index: int, seat: int) -> Vector2:
	var fire := _campfire_position(fire_index)
	var seat_ratio: Vector2 = CAMPFIRE_SEATS[seat % CAMPFIRE_SEATS.size()]
	var offset := seat_ratio * CAMPFIRE_SEAT_SPACING * _scale
	return Vector2(
		fire.x + offset.x - figure.size.x * 0.5, _ground_y + offset.y - figure.size.y
	)

## Bir vagonun ateşinin durduğu yer. Ateş vagonun **kuyruk yönüne**
## kayıyor (bkz. CAMPFIRE_TRAIL_RATIO'nun notu) - önü zaten öküz ve
## tayfayla dolu.
func _campfire_position(index: int) -> Vector2:
	if index < 0 or index >= _wagon_centres.size():
		return Vector2(_anchor_x, _ground_y)
	var wagon_w := maxf(size.y, 1.0) * _scale * WAGON_WIDTH_RATIO
	# Kuyruk yönü vagonun yüzüne göre: dönmüş vagonun arkası sağında.
	var facing := 1.0 if _wagon_turn(index).x >= 0.0 else -1.0
	return Vector2(
		_wagon_centres[index] - facing * wagon_w * CAMPFIRE_TRAIL_RATIO,
		_ground_y + CAMPFIRE_NEAR_OFFSET * _scale
	)

## Yolda arabacı koltuğunda oturan gerçek figür: inip binme klibinin
## (`climb_down`) ilk karesi, kalça koltukta, yüzü vagonun yüzü. Eskiden
## koltukta `ArtDraw.wagon()`'un düz bir silüeti (bir daire ve bir dörtgen)
## duruyordu; kamp kurulunca yerine bu figür geçiyordu, yani yolda eski
## manken görünüyordu (oyuncu bildirdi). Kamp toplanması sırasında figür
## `_advance_gather`'ındır; burası onu yalnızca toplanma dışında tutar.
func _seat_driver(index: int, delta: float) -> void:
	var figure := _driver_figures[index]
	if index >= _wagon_centres.size():
		figure.visible = false
		return
	figure.visible = true
	var seat := _driver_bench_position(index)
	figure.position = Vector2(seat.x - figure.size.x * 0.5, _ground_y - figure.size.y)
	figure.set_facing(1.0 if _wagon_turn(index).x >= 0.0 else -1.0)
	figure.set_transition("climb_down", 0.0, seat.y - figure.position.y)
	figure.advance(delta, 0.0)

## Arabacının normalde oturduğu koltuk - `ArtDraw.wagon_driver_seat()`'in
## aynısı, aynı yerde iki kez hesaplanmasın diye oradan okunuyor. Kamp
## kurulunca gerçek figür tam bu noktadan "kalkıp" ateşe yürüyor.
func _driver_bench_position(index: int) -> Vector2:
	if index < 0 or index >= _wagon_centres.size():
		return Vector2(_anchor_x, _ground_y)
	var height := maxf(size.y, 1.0) * _scale
	var wagon_w := height * WAGON_WIDTH_RATIO
	var wagon_h := height * WAGON_HEIGHT_RATIO
	var seat := ArtDraw.wagon_driver_seat(Vector2(_wagon_centres[index], _ground_y), wagon_w, wagon_h)
	var turn := _wagon_turn(index)
	seat.x = turn.y + turn.x * (seat.x - turn.y)
	return seat

## `_layout()`'un sonunda çağrılıyor (bkz. oradaki not): kamp sırasında
## bir yeniden boyutlanma vagon merkezlerini kaydırırsa, dönüş yürüyüşü
## artık doğru olmayan eski bir noktaya değil güncel ateşe gider.
func _refresh_gather_targets() -> void:
	if _gathering_figures.is_empty():
		return
	for figure in _gathering_figures:
		if _gather_trans.has(figure):
			_gather_homes[figure] = _transition_home(figure)
		if _gather_fire_index.has(figure):
			_gather_targets[figure] = _campfire_target(
				figure, int(_gather_fire_index[figure]), int(_gather_seat_index.get(figure, 0))
			)

## Kolonun toplam boyu - lider bu kadar geriye gidebiliyor. Yerleşimle
## aynı boşluklardan hesaplanıyor: ayrı bir tahmin tutmak, liderin
## kolonun ucundan taşmasına ya da kuyruğa hiç ulaşamamasına yol
## açardı.
func _column_length() -> float:
	return _lead_at(_scale) + _walk_column(_scale, false)

func _lead_at(scale: float) -> float:
	return scale * (LEAD_MOUNTED if _leader_mounted else LEAD_WALKING)

## Şeridin çapayı yerleştirmek için okuduğu değer - bilerek
## **ölçeklenmemiş**: kervan çapaya göre küçülüyor, çapa da kervana göre
## kaysaydı ikisi birbirini kovalardı.
func get_trailing_length() -> float:
	return _walk_column(1.0, false)

## Kolonun çapaya sığmak için küçüldüğü oran (1.0 = küçülme yok).
func get_column_scale() -> float:
	return _scale

## Kervanın **en önündeki** noktanın çapaya uzaklığı (piksel). Lider
## çapanın üstünde değil, `_lead_at()` kadar önünde duruyor - yani çapa
## kolonun ortasına yakın bir yer, burnu değil.
##
## Yolda yaklaşan bir olay bunu okuyor: tetik çapaya bağlıyken görevli
## önce liderin *yanından geçiyor*, kart ancak arkadaki vagona
## geldiğinde açılıyordu. Karşılaşma, karşılaşılan şey kervanın burnuna
## değdiğinde başlamalı.
func get_front_offset() -> float:
	if _leader == null:
		return 0.0
	if _heading < 0.0:
		return _walk_column(_scale, false) + _lead_at(_scale) + _leader.size.x * 0.5
	return _lead_at(_scale) + _leader.size.x * 0.5

## Yerleşimin hesapladığı vagon merkezleri - çizim de test de bunu okuyor,
## kimse kendi aritmetiğini yapmıyor.
func get_wagon_centres() -> Array[float]:
	return _wagon_centres

## Öküzlerin merkezleri, vagonlarla aynı sırada. Testin öküzün gerçekten
## kendi vagonuna koşulu olduğunu doğrulayabilmesi için.
func get_ox_centres() -> Array[float]:
	var centres: Array[float] = []
	for ox in _oxen:
		centres.append(ox.position.x + ox.size.x * 0.5)
	return centres

## Köpek/eşek/yarım vagon sürüsünün merkezleri - `get_ox_centres()` ile
## aynı desen, test kendi aritmetiğini yapmadan gerçek konumu okuyor.
func get_pack_centres() -> Array[float]:
	var centres: Array[float] = []
	for figure in _pack:
		centres.append(figure.position.x + figure.size.x * 0.5)
	return centres

## Ateşlerin merkezleri, vagonlarla aynı sırada - `_wagon_centres` gibi
## test bunu okuyor, kendi aritmetiğini yapmıyor.
func get_campfire_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for index in _wagon_centres.size():
		positions.append(_campfire_position(index))
	return positions

## Şu an ateşe/kolona doğru yürüyen biri var mı - testin "kamp bitti,
## herkes yerine döndü" iddiasını doğrulaması için.
func is_gathering() -> bool:
	return not _gathering_figures.is_empty()

## Kamp kalktı ama herkes daha yerine dönmedi, binmedi: kervan bu sürede
## yürümüyor (bkz. road_journey `_advance_position`). Yürüseydi dönenler
## kayan bir zeminin üstünde ekran konumlarına akardı.
func is_breaking_camp() -> bool:
	return not _camping and not _gathering_figures.is_empty()

## Lider ateşte ya da inip biniyor: kolonda gezdirilemez.
func is_leader_at_camp() -> bool:
	return _gather_homes.has(_leader_rider) or _gather_homes.has(_leader)

## İnen liderin merkezi (kamp dışında anlamsız, görünmez).
func get_leader_rider_centre() -> float:
	if _leader_rider == null:
		return 0.0
	return _leader_rider.position.x + _leader_rider.size.x * 0.5

func get_leader_rider() -> WalkFigure:
	return _leader_rider

func get_leader_figure() -> WalkFigure:
	return _leader

func get_driver_figures() -> Array[WalkFigure]:
	return _driver_figures

## Parti/tayfa/liderin merkezleri - `get_wagon_centres()`/`get_ox_centres()`
## ile aynı desen: test kendi aritmetiğini yapmadan gerçek konumu okuyor.
func get_party_centres() -> Array[float]:
	var centres: Array[float] = []
	for figure in _party_figures:
		centres.append(figure.position.x + figure.size.x * 0.5)
	return centres

func get_crew_centres() -> Array[float]:
	var centres: Array[float] = []
	for figure in _crew_figures:
		centres.append(figure.position.x + figure.size.x * 0.5)
	return centres

## Arabacıların merkezleri - kamp dışında anlamsız (görünmezler, bkz.
## `configure`'daki not), kamp sırasında/dönüşünde `_party_centres` ile
## aynı desende okunuyor.
func get_driver_centres() -> Array[float]:
	var centres: Array[float] = []
	for figure in _driver_figures:
		centres.append(figure.position.x + figure.size.x * 0.5)
	return centres

## Zemin çizgisi, bu düğümün yerel uzayında - yakınlaştırmanın dikey
## ekseni: zemin yerinde kalsın, kervan ayağının altından kaymasın.
func get_ground_y() -> float:
	return _ground_y

func get_leader_centre() -> float:
	if _leader == null:
		return 0.0
	return _leader.position.x + _leader.size.x * 0.5

func _process(delta: float) -> void:
	if _leader == null:
		return
	_camp_time += delta
	_advance_gather(delta)
	_tick_reactions(delta)

	# Faz herkeste ilerliyor; duran bir figür de `advance(0)` alıyor ki
	# ayaklarını yan yana toplasın. Toplanan figürler burada atlanıyor -
	# onların fazını `_advance_gather` kendi yollarından sürüyor, çünkü
	# kamp sırasında kervanın zemin hızı zaten sıfır (bkz. orası).
	_anim_time += delta
	if _turning:
		_advance_turn(delta)
	var figure_index := 0
	for child in get_children():
		var figure := child as WalkFigure
		if figure == null:
			continue
		figure_index += 1
		figure.set_lean(wind_lean_at(_wind_lean, _anim_time, figure_index))
		if _gather_homes.has(figure):
			continue
		if figure == _leader:
			_advance_leader(delta)
			continue
		var driver_index := _driver_figures.find(figure)
		if driver_index >= 0:
			_seat_driver(driver_index, delta)
			continue
		# Her birim kendi yüzüne doğru yürüyor; dönmekte olan yerinde adım
		# atıyor. Duran bir figürün yüzü `advance` değiştirmiyor, o yüzden
		# ayrıca veriliyor - yoksa durmuş, dönmüş bir vagonun tayfası eski
		# yöne bakardı.
		var unit := int(_figure_unit.get(figure, -1))
		var facing := _heading
		var turning_now := false
		if unit >= 0 and unit < _unit_facing.size():
			facing = 1.0 if _unit_facing[unit] >= 0.0 else -1.0
			turning_now = absf(_unit_facing[unit]) < 0.999
		if turning_now:
			figure.advance(delta, TURN_WALK_STEP * facing)
		else:
			figure.advance_ground(delta, _ground_speed * facing)
		figure.set_facing(facing)

	var was_swaying := _wagon_motion > 0.0
	var rolling := _ground_speed > 0.5
	_wagon_motion = WalkFigure.ease_motion(_wagon_motion, rolling, delta)
	if rolling:
		# Tekerlek yolda kaymadan dönüyor: açı = yol / yarıçap (bkz.
		# ArtDraw.wagon'un wheel_r'si). Sabit bir çarpandı ve tekerlek de
		# ayaklar gibi zemin hızından bağımsız dönüyordu.
		var wheel_r := maxf(size.y, 1.0) * _scale * WAGON_HEIGHT_RATIO * ArtDraw.WAGON_WHEEL_RATIO
		_wheel_angle = fmod(_wheel_angle + delta * _ground_speed / maxf(wheel_r, 1.0), TAU)
	# Yeniden çizim üç sebepten gerekebilir: tekerlek dönüyor, ateş
	# titriyor, ya da biri hâlâ ateşe/koluna yürüyor - üçü de kendi
	# koşuluyla bağımsız.
	if rolling or was_swaying or _camping or _turning or not _gathering_figures.is_empty():
		queue_redraw()
		if _harness != null:
			_harness.queue_redraw()

## Lider: dönüşte kendi yolu (çevir, sonra yeni başa sür), yolda kendi
## zemin hızı, yoksa kervanın adımı. Üçünde de adım zeminden - at da insan
## da yerde kaymıyor.
func _advance_leader(delta: float) -> void:
	var x := _leader.position.x
	var moved := (x - _leader_last_x) / maxf(delta, 0.0001)
	_leader_last_x = x
	if _turning:
		var target := -_turn_from
		if _turn_time <= LEADER_PIVOT_SECONDS:
			_leader.advance(delta, 0.0)
			_leader.set_facing(_turn_from if _leader_turn_scale_sign() > 0.0 else target)
		else:
			# Dönüşte zaman durmuş, manzara kaymıyor: ekrandaki yol zemindeki yol.
			_leader.advance_ground(delta, absf(moved) * target)
			_leader.set_facing(target)
		return
	if _leader_walking:
		_leader.advance_ground(delta, _leader_ground)
		return
	_leader.advance_ground(delta, _ground_speed * _heading)
	if _ground_speed <= 0.5:
		return
	_leader.set_facing(_heading)

func _leader_turn_scale_sign() -> float:
	return signf(_leader_turn_scale) if not is_zero_approx(_leader_turn_scale) else 1.0

## Dönüşün bir karesi: birimlerin yüzü dalgayla, liderin yeri yoluyla.
func _advance_turn(delta: float) -> void:
	_turn_time += delta
	for index in _units.size():
		var start := _unit_turn_start[index] if index < _unit_turn_start.size() else 0.0
		var p := clampf((_turn_time - start) / UNIT_TURN_SECONDS, 0.0, 1.0)
		var eased := p * p * (3.0 - 2.0 * p)
		_unit_facing[index] = _turn_from * cos(PI * eased)
		_unit_lift[index] = sin(PI * eased)
	var pivot := clampf(_turn_time / LEADER_PIVOT_SECONDS, 0.0, 1.0)
	_leader_turn_scale = cos(PI * pivot)
	if _turn_time >= TURN_SECONDS:
		_finish_turn()
		return
	_layout()

func _finish_turn() -> void:
	_turning = false
	_heading = -_turn_from
	_turn_from = _heading
	for index in _unit_facing.size():
		_unit_facing[index] = _heading
		_unit_lift[index] = 0.0
	_leader_turn_scale = 1.0
	_leader_offset = 0.0
	_leader.set_facing(_heading)
	_layout()
	queue_redraw()
	turn_finished.emit()

## Liderin çapaya göre yeri: dönüşte yolunun üstünde, yoksa kolondaki yeri.
func _leader_rel_x() -> float:
	var lead := _lead_at(_scale)
	if _turning:
		var ride := TURN_SECONDS - LEADER_PIVOT_SECONDS - UNIT_TURN_SECONDS * 0.5
		var t := clampf((_turn_time - LEADER_PIVOT_SECONDS) / ride, 0.0, 1.0)
		t = t * t * (3.0 - 2.0 * t)
		return lerpf(_turn_leader_from, _turn_leader_to, t)
	if _heading < 0.0:
		return -_walk_column(_scale, false) - lead - _leader_offset
	return lead + _leader_offset

## Toplanma ve dönüş: her figürün `_gather_walk`'ı kampa göre 0↔1 arası
## akıyor, ekrandaki yeri ev-ateş arasında bu oranla enterpole ediliyor;
## inip binenlerin önce/sonra kendi klibi var (`_gather_trans`). Figürün kendi yürüyüş fazı da burada sürülüyor -
## Zemin hızından değil, çünkü kamp sırasında kervan duruyor: adım her
## figürün kendi yolundan.
func _advance_gather(real_delta: float) -> void:
	if _gathering_figures.is_empty():
		return
	var delta := real_delta * _gather_time_scale
	var trans_rate := 1.0 / TRANSITION_SECONDS
	var settled := true
	for figure in _gathering_figures:
		var walk_rate := 1.0 / _figure_gather_seconds(figure)
		var has_trans := _gather_trans.has(figure)
		var walk := float(_gather_walk.get(figure, 0.0))
		var trans := float(_gather_trans.get(figure, 1.0))
		# Gidişte önce iniş, sonra yürüyüş; dönüşte önce yürüyüş, sonra biniş.
		if _camping:
			if has_trans and trans < 1.0:
				trans = minf(1.0, trans + delta * trans_rate)
			else:
				walk = minf(1.0, walk + delta * walk_rate)
		elif walk > 0.0:
			walk = maxf(0.0, walk - delta * walk_rate)
		elif has_trans:
			trans = maxf(0.0, trans - delta * trans_rate)
		_gather_walk[figure] = walk
		if has_trans:
			_gather_trans[figure] = trans
		var home: Vector2 = _gather_homes.get(figure, figure.position)
		var dest: Vector2 = _gather_targets.get(figure, home)
		var before := figure.position
		figure.position = home.lerp(dest, _ease_gather(walk))
		if has_trans and walk <= 0.0 and trans < 1.0:
			figure.set_transition(String(_gather_clip[figure]), trans, _transition_hip(figure, trans))
			figure.advance(delta, 0.0)
		else:
			if figure.is_in_transition():
				figure.set_transition("", 0.0, 0.0)
			figure.advance_ground(delta, (figure.position.x - before.x) / maxf(delta, 0.0001))
		if _camping and walk >= 1.0:
			# Yerine varan ateşe dönüyor (koltuğu yürüdüğü yönün ötesinde olabilir).
			var fire_x := _campfire_position(int(_gather_fire_index.get(figure, 0))).x
			figure.set_facing(1.0 if fire_x >= figure.position.x + figure.size.x * 0.5 else -1.0)
		if walk > 0.0 or (has_trans and trans > 0.0):
			settled = false

	_update_fires(delta)

	# Dönüş bittiyse toplanma tamamen bitmiştir - kayıtlar temizleniyor.
	# Sürücüler ve inen lider gizleniyor: koltuğu yeniden `ArtDraw.wagon()`'un
	# sabit silüeti, eyeri atlı figür tutuyor (bkz. `_draw()`'daki
	# `driver_gone`); ikisi aynı anda görünürse aynı kişi iki kez sahnede olur.
	if not _camping and settled:
		for figure in _gather_trans:
			(figure as WalkFigure).set_transition("", 0.0, 0.0)
		for figure in _driver_figures:
			figure.visible = false
		if _leader_rider != null:
			_leader_rider.visible = false
		if _leader != null:
			_leader.set_riderless(false)
		_gathering_figures.clear()
		_gather_homes.clear()
		_gather_targets.clear()
		_gather_fire_index.clear()
		_gather_seat_index.clear()
		_gather_walk.clear()
		_gather_trans.clear()
		_gather_clip.clear()
		_fire_ignite.clear()
		fires_out.emit()

## Bir ateş, ilk kendi figürü ona vardığında tutuşuyor; hiç figürü atanmamış
## bir ateş (vagonu boş) ilk varan herhangi biriyle. Tutuşan ateş kamp
## sökülene kadar yanıyor.
func _update_fires(delta: float) -> void:
	if not _camping:
		return
	var arrived_at: Dictionary = {}
	var assigned_to: Dictionary = {}
	var anyone := false
	for figure in _gathering_figures:
		var fire_index := int(_gather_fire_index.get(figure, -1))
		assigned_to[fire_index] = true
		if float(_gather_walk.get(figure, 0.0)) >= 1.0:
			arrived_at[fire_index] = true
			anyone = true
	for index in _wagon_centres.size():
		var lit := arrived_at.has(index) or (anyone and not assigned_to.has(index))
		if lit or _fire_ignite.has(index):
			var was_lit := _fire_ignite.has(index)
			_fire_ignite[index] = minf(1.0, float(_fire_ignite.get(index, 0.0)) + delta / IGNITE_SECONDS)
			if not was_lit:
				fire_lit.emit(index)

## Ateşin tutuşma ilerlemesi: 0 yanmıyor (yalnızca odun), 1 tam alev.
func get_fire_ignite(index: int) -> float:
	return float(_fire_ignite.get(index, 0.0))

## Kamp kuruldu mu: herkes kendi ateşine vardı (kamp sayacı bundan sonra
## başlıyor - görev 12.2c). Toplanacak kimse yoksa kamp kurulu sayılır.
func is_camp_settled() -> bool:
	if not _camping:
		return false
	for figure in _gathering_figures:
		if float(_gather_walk.get(figure, 0.0)) < 1.0:
			return false
	return true

## Kamp kurulurken ya da sökülürken yürüyüş sürüyor mu (saat bu sırada
## kampın yavaş akışında değil, normal hızda akıyor).
func is_camp_transitioning() -> bool:
	return (_camping and not is_camp_settled()) or is_breaking_camp()

## Bir figürün ateşe yürüyüş süresi: kendi yolu ve kendi tempolu hızı. En
## uzağa yürüyenin en hızlı anı (smoothstep'in tepesi ortalamanın 1.5 katı)
## tempolu yürüyüşün `GATHER_JOG_FACTOR` katını geçmesin; ama hiçbir yürüyüş
## `MAX_GATHER_SECONDS`'ı aşmasın.
func _figure_gather_seconds(figure: WalkFigure) -> float:
	var home: Vector2 = _gather_homes.get(figure, figure.position)
	var dest: Vector2 = _gather_targets.get(figure, home)
	var dist := absf(dest.x - home.x)
	var brisk := figure.brisk_ground_speed()
	if dist <= 0.0 or brisk <= 0.0:
		return CAMP_GATHER_SECONDS
	return clampf(1.5 * dist / (brisk * GATHER_JOG_FACTOR), CAMP_GATHER_SECONDS, MAX_GATHER_SECONDS)

## Toplanmanın en uzun yürüyüşü (gerçek saniye, oyun hızı çarpanından önce).
func gather_seconds() -> float:
	var longest := CAMP_GATHER_SECONDS
	for figure in _gathering_figures:
		longest = maxf(longest, _figure_gather_seconds(figure))
	return longest

## Toplanmanın (ya da dönüşün) tamamı: inip binenler yürüyüşten önce/sonra
## kendi klibini oynuyor.
func settle_seconds() -> float:
	return gather_seconds() + (TRANSITION_SECONDS if not _gather_trans.is_empty() else 0.0)

## Yumuşak geçiş (smoothstep): doğrusal enterpolasyon yürüyüşü başta ve
## sonda aniden kesiyor, figür ateşin dibinde fren yapmış gibi duruyordu.
func _ease_gather(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

## Kolonun yerleşimi: çapadan geriye doğru yürüyen bir imleç.
##
## Her parça kendi genişliği kadar yer tüketiyor ve araya bir boşluk
## giriyor, yani **çakışma tasarım gereği imkânsız**. Sabit adımlı ilk
## sürümde öyle değildi: `WAGON_SPACING` vagon genişliğinden bağımsızdı,
## bir ölçü değişince arkadaki vagonun öküzü öndeki vagonun içine
## giriyordu.
##
## Diziliş kuralları:
## - Lider en önde ve kolondan bağımsız.
## - Parti üyeleri **kolon boyunca dağılıyor**, en fazla ikişer yan yana:
##   hepsini liderin arkasına dizmek bir muhafız duvarı yapıyordu.
## - Tayfa kendi vagonunun *yanında* yürüyor, arkasında değil - kervanın
##   en arkasında yürüyen isimsiz bir kuyruk, sürüklenen bir grup gibi
##   duruyordu.
func _layout() -> void:
	if _leader == null or _ground_y <= 0.0 or size.y < MIN_DRAW_HEIGHT:
		return
	# Yolda katılan bir yoldaş boyunduruk katmanından sonra eklenebilir:
	# katman her zaman en üstte (son çocuk) kalır.
	if _harness != null:
		move_child(_harness, -1)
		_harness.size = size
		_harness.queue_redraw()
	_wagon_centres.clear()
	# Ölçek önce: kolon çapanın arkasına sığmıyorsa taşmak yerine
	# küçülüyor. Her terim boşluk ya da yüksekliğe oranlı bir genişlik
	# olduğu için uzunluk ölçekte doğrusal - yani tek bir çarpan yetiyor.
	var scale_anchor := _anchor_x if _scale_anchor_x < 0.0 else _scale_anchor_x
	var room := maxf(1.0, scale_anchor - maxf(COLUMN_EDGE_MARGIN, _safe_left))
	_scale = clampf(
		room / maxf(1.0, _walk_column(1.0, false)), MIN_COLUMN_SCALE, 1.0
	)

	_walk_column(_scale, true)
	_sync_unit_state()
	_apply_unit_turns()
	var leader_h := maxf(size.y, 1.0) * _scale * (
		MOUNTED_HEIGHT_RATIO if _leader_mounted else PERSON_HEIGHT_RATIO
	)
	_place(_leader, _anchor_x + _leader_rel_x(), leader_h, leader_h * 1.6)
	_turn_figure(_leader, _leader_turn_scale if _turning else 1.0)
	column_length_changed.emit(get_trailing_length())

	# Arabacılar kolonun kendi yerleşiminde yer tutmuyor (koltukları
	# vagonun üstü, `_walk_column`'un imleci oraya hiç uğramıyor), o
	# yüzden boyları burada ayrıca veriliyor - aynı formül `_walk_column`
	# tayfaya ne veriyorsa (bkz. oradaki person_h/person_w).
	var height := maxf(size.y, 1.0) * _scale
	var person_h := height * PERSON_HEIGHT_RATIO
	var person_w := person_h * 0.9
	for driver in _driver_figures:
		driver.size = Vector2(person_w, person_h)

	# Kamp sırasında bir yeniden boyutlanma vagon merkezlerini kaydırabilir;
	# ateş hedefleri de tazelenmeli, yoksa dönüş yürüyüşü artık doğru
	# olmayan eski bir noktaya yönelir.
	_refresh_gather_targets()

## Birim sayısı yerleşimden geliyor; yüz dizileri ona uyuyor. Yeni gelen
## birim (yolda katılan bir yoldaş) kervanın o anki yüzüyle doğuyor.
func _sync_unit_state() -> void:
	var fill := _heading
	while _unit_facing.size() < _units.size():
		_unit_facing.append(fill)
		_unit_lift.append(0.0)
	while _unit_turn_start.size() < _units.size():
		_unit_turn_start.append(0.0)
	_unit_facing.resize(_units.size())
	_unit_lift.resize(_units.size())
	_unit_turn_start.resize(_units.size())

## İleri yerleşimin üstüne her birimin yüzü: birim kendi merkezinde
## aynalanıyor (s = -1 tam dönmüş), dönüşün ortasında incelip uzak şeride
## kalkıyor.
func _apply_unit_turns() -> void:
	var lift_px := maxf(size.y, 1.0) * _scale * TURN_LIFT_RATIO
	for index in _units.size():
		var unit: Dictionary = _units[index]
		var facing := _unit_facing[index]
		var lift := _unit_lift[index] * lift_px
		var centre: float = unit.centre
		for figure in unit.figures:
			var walker := figure as WalkFigure
			if _gather_homes.has(walker):
				var home: Vector2 = _gather_homes[walker]
				var home_centre := home.x + walker.size.x * 0.5
				home.x = centre + facing * (home_centre - centre) - walker.size.x * 0.5
				_gather_homes[walker] = home
				continue
			var fx := walker.position.x + walker.size.x * 0.5
			walker.position.x = centre + facing * (fx - centre) - walker.size.x * 0.5
			walker.position.y -= lift
			_turn_figure(walker, facing)

## Figürün kâğıt dönüşü: genişliği |s|, ayaklarının ortasından.
func _turn_figure(figure: WalkFigure, facing: float) -> void:
	if figure == null:
		return
	figure.pivot_offset = Vector2(figure.size.x * 0.5, figure.size.y)
	figure.scale = Vector2(maxf(absf(facing), MIN_TURN_WIDTH), 1.0)

## Okun iki ucu, ekranda (dönüş ve kalkış uygulanmış): vagonun ön dingili ve
## öküzün boynu. Öküzün çizimi kutusunun yaklaşık %62'sini dolduruyor
## (bkz. `DRAWN_BEAST_SHARE`): boyun gidiş yönünde kutunun `OX_NECK_SHARE`
## payı ilerde, yerden `OX_NECK_HEIGHT_SHARE` yukarıda.
const OX_NECK_SHARE: float = 0.30
const OX_NECK_HEIGHT_SHARE: float = 0.46

func _hitch_points(index: int, wagon_w: float, wagon_h: float) -> Dictionary:
	if index >= _oxen.size() or index >= _wagon_centres.size() or _oxen[index] == null:
		return {}
	var ox := _oxen[index]
	var turn := _wagon_turn(index)
	var dir := 1.0 if turn.x >= 0.0 else -1.0
	var front_local := _wagon_centres[index] + wagon_w * 0.48
	var front_x := turn.y + turn.x * (front_local - turn.y)
	var ox_cx := ox.position.x + ox.size.x * 0.5
	var ground := ox.position.y + ox.size.y
	return {
		"start": Vector2(front_x, _ground_y - turn.z - wagon_h * 0.34),
		"neck": Vector2(ox_cx + dir * absf(turn.x) * ox.size.x * OX_NECK_SHARE,
			ground - ox.size.y * OX_NECK_HEIGHT_SHARE),
		"dir": dir,
		"h": ox.size.y,
	}

func _draw_yokes() -> void:
	if _ground_y <= 0.0 or size.y < MIN_DRAW_HEIGHT:
		return
	var height := size.y * _scale
	var wagon_w := height * WAGON_WIDTH_RATIO
	var wagon_h := height * WAGON_HEIGHT_RATIO
	for index in _wagon_centres.size():
		var hitch := _hitch_points(index, wagon_w, wagon_h)
		if not hitch.is_empty():
			ArtDraw.yoke(_harness, hitch.neck, float(hitch.h), float(hitch.dir), _light)

## Bir vagon biriminin yüzü ve merkezi - çizim aynayı bundan kuruyor.
func _wagon_turn(index: int) -> Vector3:
	if index < 0 or index >= _wagon_unit.size():
		return Vector3(_heading, 0.0, 0.0)
	return _unit_turn(_wagon_unit[index])

## Bir birimin kâğıt dönüşü: (genişlik işaretli, birim merkezi, kalkış).
func _unit_turn(unit: int) -> Vector3:
	if unit < 0 or unit >= _units.size():
		return Vector3(_heading, 0.0, 0.0)
	var facing := _unit_facing[unit]
	var width := maxf(absf(facing), MIN_TURN_WIDTH) * (1.0 if facing >= 0.0 else -1.0)
	var lift := _unit_lift[unit] * maxf(size.y, 1.0) * _scale * TURN_LIFT_RATIO
	return Vector3(width, float(_units[unit].centre), lift)

## Kolonun tek aritmetiği: imleç çapadan geriye yürür, her parça kendi
## genişliğini tüketir, araya boşluk girer. `place` yanlışsa hiçbir şey
## yerleştirilmiyor, yalnızca tüketilen uzunluk dönüyor.
##
## Ölçmek ve yerleştirmek **aynı** fonksiyon çünkü ayrı yazıldıklarında
## ayrıştılar: ölçen kopya vagon birimindeki yürüyen tayfayı ve iki dar
## boşluğu saymıyordu, yani kolon her vagonda 66 piksel eksik ölçülüyor
## ve sığdığı sanılan kervanın kuyruğu ekrandan taşıyordu. Bu dosyanın
## kendi kuralı: iki yerde hesaplanan bir şey iki farklı şeydir - vagon
## merkezleri de tam bu yüzden yerleşimden okunuyor.
func _walk_column(scale: float, place: bool) -> float:
	var height := maxf(size.y, 1.0) * scale
	var person_h := height * PERSON_HEIGHT_RATIO
	var person_w := person_h * 0.9
	var ox_h := height * OX_HEIGHT_RATIO
	var ox_w := ox_h * 2.0
	var wagon_w := height * WAGON_WIDTH_RATIO
	var gap_tight := GAP_TIGHT * scale
	var gap_normal := GAP_NORMAL * scale
	var gap_wagons := GAP_WAGONS * scale
	var hitch_gap := HITCH_GAP * scale
	var pair_gap := PAIR_GAP * scale

	var start := _anchor_x if place else 0.0
	var cursor := start
	var placed := 0
	if place:
		_units.clear()
		_figure_unit.clear()
		_wagon_unit.clear()

	# Parti üyeleri kolon boyunca ikişerli gruplar hâlinde dağılıyor.
	# Önce liderin hemen arkasındaki muhafız grubu.
	cursor = _walk_escort_group(
		cursor, placed, person_h, person_w, pair_gap, gap_normal, place
	)
	placed += MAX_ABREAST

	for index in _wagon_count:
		# Bir vagon birimi, önden arkaya: [tayfa] [öküz] [vagon].
		#
		# **Öküzle vagonun arasına hiçbir şey girmez** - orası koşum yeri.
		# Tayfa bir ara oraya konmuştu (vagonun yanı gövdeyle örtüşüyordu,
		# arkası da istenmeyen isimsiz kuyruğu üretiyordu) ve sonuç ekranda
		# apaçıktı: öküzle vagon arası vagonun kendisinden neredeyse iki
		# kat genişti ve ortada bir adam duruyordu, yani öküz o vagonu
		# çeken hayvan gibi değil başıboş bir hayvan gibi okunuyordu.
		# Yürüyen tayfa artık öküzün **başında**, onu yederek yürüyor -
		# öküz arabası zaten böyle sürülür.
		var unit_start := cursor
		var unit_figures: Array = []
		if index < _crew_figures.size():
			unit_figures.append(_crew_figures[index])
			if place:
				_place(
					_crew_figures[index], cursor - person_w * 0.5,
					person_h * 0.95, person_w
				)
			cursor -= person_w + gap_tight

		if index < _oxen.size():
			unit_figures.append(_oxen[index])
			cursor -= ox_w * 0.5
			if place:
				_place(_oxen[index], cursor, ox_h, ox_w)
			cursor -= ox_w * 0.5
		cursor -= hitch_gap

		if place:
			_wagon_centres.append(cursor - wagon_w * 0.5)
			_wagon_unit.append(_units.size())
			_register_unit(unit_figures, index, (unit_start + cursor - wagon_w) * 0.5)
		cursor -= wagon_w + gap_wagons

		# Vagonlar arasına bir parti grubu daha serpiştiriyoruz: parti
		# kolon boyunca dağılıyor, hepsi liderin arkasında toplanmıyor.
		if placed < _party_figures.size() and index < _wagon_count - 1:
			cursor = _walk_escort_group(
				cursor, placed, person_h, person_w, pair_gap, gap_normal, place
			)
			placed += MAX_ABREAST

	# Artakalan parti üyeleri en arkada, ama tayfayla aynı hizada değil.
	while placed < _party_figures.size():
		cursor = _walk_escort_group(
			cursor, placed, person_h, person_w, pair_gap, gap_normal, place
		)
		placed += MAX_ABREAST

	# Köpek/eşek/yarım vagon sürüsü en arkada, tek sıra - `configure()`'ın
	# ekleme sırasıyla aynı (önce köpekler, sonra eşekler/yarım vagonlar).
	var pack_gap := PACK_GAP * scale
	if place:
		_carts.clear()
	var px_per_m := height * PERSON_HEIGHT_RATIO * 0.86 / 1.73
	for index in _pack.size():
		var is_dog: bool = _pack_is_dog[index] if index < _pack_is_dog.size() else false
		var pack_h := height * (DOG_HEIGHT_RATIO if is_dog else DONKEY_HEIGHT_RATIO)
		# Kutu eni türün kendi `extent()`'inden: köpek 1.2, eşek 1.4 kat
		# nominal `h`. Tek bir 1.3 ikisine birden uyduğu için seçilmişti,
		# ama eşeğinkini %7 dar bırakıyordu - kolon aralığı o kadar sıkışık
		# hesaplanıyordu (çizim taşmıyor, `Control` kırpmıyor; sıkışan şey
		# yanındaki hayvana kalan boşluk).
		var pack_w := pack_h * (DOG_WIDTH_RATIO if is_dog else DONKEY_WIDTH_RATIO)
		cursor -= pack_w * 0.5
		var donkey_x := cursor
		var with_cart: bool = _pack_has_cart[index] if index < _pack_has_cart.size() else false
		cursor -= pack_w * 0.5
		if with_cart:
			var cart_x := donkey_x - CART_HITCH_M * px_per_m
			cursor = minf(cursor, cart_x - CART_TAIL_M * px_per_m)
			if place:
				_place(_pack[index], donkey_x, pack_h, pack_w)
				_carts.append({"x": cart_x, "unit": _units.size()})
				_register_unit([_pack[index]], -1, (donkey_x + pack_w * 0.5 + cursor) * 0.5)
		elif place:
			_place(_pack[index], donkey_x, pack_h, pack_w)
			_register_unit([_pack[index]], -1, donkey_x)
		cursor -= pack_gap

	return start - cursor

func _register_unit(figures: Array, wagon: int, centre: float) -> void:
	for figure in figures:
		_figure_unit[figure] = _units.size()
	_units.append({"figures": figures, "wagon": wagon, "centre": centre})

## İkişerli bir muhafız grubu; imleci grubun tükettiği kadar geriye alır.
func _walk_escort_group(
	cursor: float, from_index: int, person_h: float, person_w: float,
	pair_gap: float, gap_normal: float, place: bool
) -> float:
	var count := mini(MAX_ABREAST, _party_figures.size() - from_index)
	if count <= 0:
		return cursor
	var group := from_index / MAX_ABREAST
	if group < _pair_gap_scales.size():
		pair_gap *= _pair_gap_scales[group]
	var step := person_w + pair_gap
	if place:
		var figures: Array = []
		for slot in count:
			_place(
				_party_figures[from_index + slot],
				cursor - float(slot) * step, person_h, person_w
			)
			figures.append(_party_figures[from_index + slot])
		_register_unit(figures, -1, cursor - float(count - 1) * step * 0.5)
	return cursor - float(count - 1) * step - person_w - gap_normal

## `lift` figürü zemin çizgisinden yukarı alır: yolun karşı tarafında
## duran bir şey kameradan uzaktır, uzak olan da yukarıda durur.
##
## Toplanan bir figür (bkz. `_begin_gathering`) burada **atlanıyor**: onun
## ekrandaki yerini `_advance_gather`'ın enterpolasyonu yönetiyor, bu
## fonksiyon üstüne yazarsa yarı yoldaki figür ateşe/koluna anında
## ışınlanır. Yalnızca "ev" hedefi tazeleniyor - ölçek değişmiş olabilir -
## dönüş yürüyüşü güncel noktaya gitsin diye.
func _place(
	figure: WalkFigure, x: float, height: float, width: float, lift: float = 0.0
) -> void:
	figure.size = Vector2(width, height)
	var home := Vector2(x - width * 0.5, _ground_y - height - lift)
	if _gather_homes.has(figure):
		_gather_homes[figure] = home
		return
	figure.position = home

func _draw() -> void:
	if _ground_y <= 0.0 or size.y < MIN_DRAW_HEIGHT:
		return
	var height := size.y * _scale
	var wagon_w := height * WAGON_WIDTH_RATIO
	var wagon_h := height * WAGON_HEIGHT_RATIO

	for index in _wagon_centres.size():
		# Merkez yerleşimden geliyor, burada yeniden hesaplanmıyor.
		# Vagon gövdesi `ArtDraw`'da: aynı vagon şehir dışı yürüyüş
		# alanında da çiziliyor ve iki kopya tutulunca aynı kervan iki
		# ekranda iki farklı şey oluyordu.
		var centre := _wagon_centres[index]
		# Dönüş: vagon birimi kendi merkezinde aynalanıyor (bkz.
		# `_apply_unit_turns`); ok ve gövde aynı dönüşümle, ayrı hesap yok.
		var turn := _wagon_turn(index)
		draw_set_transform(Vector2(turn.y * (1.0 - turn.x), -turn.z), 0.0, Vector2(turn.x, 1.0))
		# Koşum oku vagondan *önce*: kalas gövdenin altından çıkıyor.
		# Okun ucu öküzün boynunda (görev 10.4): sabit boylu ok büyüyen
		# öküzün ancak sağrısına yetişiyordu, boyunduruk da oradaydı.
		var hitch := _hitch_points(index, wagon_w, wagon_h)
		if not hitch.is_empty():
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			ArtDraw.hitch_pole(self, hitch.start, hitch.neck, wagon_h, _light)
			draw_set_transform(Vector2(turn.y * (1.0 - turn.x), -turn.z), 0.0, Vector2(turn.x, 1.0))
		# Sürücü koltuğu boş çizilir yalnızca gerçek bir figür onu
		# devralmışsa (bkz. `_assign_transition`) - ikisi aynı anda
		# çizilirse aynı kişi iki kez görünür.
		var driver_gone := index < _driver_figures.size() and _driver_figures[index].visible
		ArtDraw.wagon(
			self, Vector2(centre, _ground_y), wagon_w, wagon_h,
			_wheel_angle, _light, index == 0, not driver_gone,
			canopy_sway_at(_wheel_angle, index, wagon_h, _wagon_motion)
		)
		_draw_mud(centre, wagon_w, wagon_h, index)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_carts(height)

	if _camping or is_breaking_camp():
		# Ateşler vagonlardan *sonra* çiziliyor (aynı `_draw()` çağrısı,
		# yani üstlerine biner) ama figürlerden *önce*: figürler bu
		# fonksiyondan sonra, ayrı çocuklar olarak çiziliyor, yani ateşin
		# başında toplanan biri alevin önünde duruyor - tam istenen sıra.
		_draw_campfires()

	# Liderin başı her zaman işaretli: kolonda serbestçe yürüyen tek
	# beden o, oyuncu hangisinin kendisi olduğunu karıştırmasın.
	if _leader == null:
		return
	# Başının hemen üstünde: çapadan hesaplanan bir yükseklik geniş bir
	# şeritte liderin çok üstünde, havada asılı kalıyordu.
	var marker := Vector2(get_leader_centre(), _leader.position.y - 4.0)
	draw_colored_polygon(PackedVector2Array([
		marker + Vector2(-5.0, -9.0), marker + Vector2(5.0, -9.0), marker,
	]), Color(ArtPalette.GOLD, 0.85))

## Yarım vagonlar: eşeğin (çocuk düğüm, sonra çiziliyor) altında kalıyor,
## yani oklar eşeğin iki yanından geçiyor gibi okunuyor.
func _draw_carts(height: float) -> void:
	if _carts.is_empty():
		return
	var px_per_m := height * PERSON_HEIGHT_RATIO * 0.86 / 1.73
	var k := px_per_m / PropArt.ppm(CART_PROP)
	# Tekerlek yolu vagonunkiyle aynı hızda katediyor; açı yarıçapların oranıyla.
	var wheel_tex := PropArt.texture(CART_PROP, "wheel")
	var wheel_r := maxf(wheel_tex.get_width() * k * 0.5, 1.0) if wheel_tex != null else 1.0
	var spin := _wheel_angle * height * WAGON_HEIGHT_RATIO * ArtDraw.WAGON_WHEEL_RATIO / wheel_r
	for cart in _carts:
		var turn := _unit_turn(int(cart.unit))
		draw_set_transform(Vector2(turn.y * (1.0 - turn.x), -turn.z), 0.0, Vector2(turn.x, 1.0))
		var base := Vector2(float(cart.x), _ground_y)
		ArtDraw.ellipse(self, base, Vector2(px_per_m * 0.9, px_per_m * 0.12), Color(0.0, 0.0, 0.0, 0.2))
		PropArt.draw_layer(self, CART_PROP, "body", base, k, _light)
		PropArt.draw_layer(self, CART_PROP, "canopy", base, k, _light)
		PropArt.draw_layer(self, CART_PROP, "load", base, k, _light)
		PropArt.draw_layer_rotated(self, CART_PROP, "wheel", base, k, "wheel_front", spin, _light)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Kamp ateşi vagon başına bir tane (bkz. `_campfire_position`'ın notu).
## Önceden yolun tamamı tek bir ateşi paylaşıyordu ve o ateş kolonun
## önünde, boş alanda duruyordu - hiçbir silüetin arkasına düşmeden.
## Vagon başına çoğaltınca o kaçış yolu kapandı, bu yüzden her ateş artık
## kendi vagonunun *arkasında* (bkz. yukarıdaki not) duruyor; çizim,
## rengi ve titreme deseni tek ateşin aynısı.
func _draw_campfires() -> void:
	var glow_radius := size.y * 0.24
	var flicker := 0.88 + 0.12 * sin(_camp_time * FIRE_FLICKER_SPEED)
	for index in _wagon_centres.size():
		var fire := _campfire_position(index)
		# Tutuşma: 0'da yalnızca odun yığını, 1'de tam alev (ilk figür varınca
		# başlıyor, bkz. `_update_fires`).
		var lit := get_fire_ignite(index)
		var flame_h := 22.0 * flicker * _scale * lit
		if lit > 0.0:
			# İki katman: geniş ve soluk bir haleyle sahnenin geneli ısınıyor
			# (bkz. "sıcak bir ortam" - tek dar bir ışık çemberi yalnızca
			# ateşin kendisini aydınlatıyordu, etrafındaki toplanmayı değil),
			# dar ve parlak olan ateşin hemen dibini.
			ArtDraw.light_pool(self, fire, glow_radius * 2.1, ArtPalette.TORCH, 0.05 * flicker * lit, 0.60)
			ArtDraw.light_pool(self, fire, glow_radius, ArtPalette.TORCH, 0.11 * flicker * lit, 0.48)
		# Odun + alev: taş çember ve odunlar render (PropArt); alev titrediği
		# için parlaklığı oynuyor.
		if PropArt.has(CAMPFIRE_PROP):
			var px_per_m := size.y * _scale * PERSON_HEIGHT_RATIO * 0.86 / 1.73
			var glow := Color(0.86 + 0.14 * flicker, 0.84 + 0.12 * flicker, 0.80 + 0.10 * flicker)
			_draw_bonfire(fire + Vector2(0.0, 3.0 * _scale),
				px_per_m / PropArt.ppm(CAMPFIRE_PROP), glow, lit)
			if lit > 0.0:
				_draw_sparks(fire, lit)
			continue
		for side in [-1.0, 1.0]:
			draw_line(
				fire + Vector2(-14.0 * side, 2.0) * _scale, fire + Vector2(9.0 * side, -7.0) * _scale,
				Color(0.32, 0.24, 0.18), 3.5 * _scale
			)
		if lit <= 0.0:
			continue
		draw_colored_polygon(PackedVector2Array([
			fire + Vector2(-8.0, 0.0) * _scale, fire + Vector2(0.0, -flame_h),
			fire + Vector2(8.0, 0.0) * _scale,
		]), Color(0.92, 0.42, 0.16, 0.92))
		draw_colored_polygon(PackedVector2Array([
			fire + Vector2(-4.5, 0.0) * _scale, fire + Vector2(0.5, -flame_h * 0.66),
			fire + Vector2(4.5, 0.0) * _scale,
		]), Color(1.0, 0.82, 0.40, 0.95))
		_draw_sparks(fire, lit)

## Ateş resmi (odun altta, alev üstte tek resim): odun her zaman, alev
## tutuşma ilerlemesi kadar boyuyla ve opaklığıyla - alevin tabanı odunda
## sabit, tepesi yükseliyor.
func _draw_bonfire(base: Vector2, k: float, tint: Color, lit: float) -> void:
	var tex := PropArt.texture(CAMPFIRE_PROP, "body")
	var r := PropArt.layer_rect(CAMPFIRE_PROP, "body", base, k)
	if tex == null or r.size == Vector2.ZERO:
		return
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	var split := r.position.y + r.size.y * CAMPFIRE_LOGS_FROM
	draw_texture_rect_region(
		tex, Rect2(r.position.x, split, r.size.x, r.end.y - split),
		Rect2(0.0, h * CAMPFIRE_LOGS_FROM, w, h * (1.0 - CAMPFIRE_LOGS_FROM)), tint
	)
	if lit <= 0.0:
		return
	var flame_full := split - r.position.y
	var flame_h := flame_full * lit
	draw_texture_rect_region(
		tex, Rect2(r.position.x, split - flame_h, r.size.x, flame_h),
		Rect2(0.0, 0.0, w, h * CAMPFIRE_LOGS_FROM), Color(tint.r, tint.g, tint.b, lit)
	)

## Tutuşurken yükselen birkaç kıvılcım: yalnızca ilk anlarda, alev
## oturunca kesiliyor. Konumları ilerlemeye ve sıraya bağlı, rastgele değil
## (her karede aynı kıvılcım aynı yerde yürüsün).
func _draw_sparks(fire: Vector2, lit: float) -> void:
	if lit >= 1.0:
		return
	for i in 5:
		var phase := fmod(lit * 2.2 + float(i) * 0.19, 1.0)
		var x := (float(i) - 2.0) * 5.0 * _scale + sin(phase * 6.0 + float(i)) * 4.0 * _scale
		var y := -phase * 38.0 * _scale
		draw_circle(fire + Vector2(x, y), 1.6 * _scale, Color(1.0, 0.78, 0.35, 1.0 - phase))
