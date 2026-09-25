extends Control

## Sefer ekranı. Kervan planlayıcıdan gerçek bir seferle gelindiğinde
## kalıcı oturumu yürütür. Sentetik (sahte) sefer yalnızca F1 geliştirici
## panelinden doğrudan açıldığında kurulur - normal oyun akışında bu
## ekrana her zaman start_journey() çağırmış bir oturumla girilir, bu
## yüzden ek bir "dev girişi" bayrağına gerek yok: is_journey_active()
## zaten aynı ayrımı yapıyor.
const SYNTHETIC_JOURNEY_DAYS: int = 8
const SYNTHETIC_DANGER: float = 0.4
const SYNTHETIC_WAGONS: int = 4
## Sentetik tüccarlar yalnızca F1 sahte seferinde görünür ama yine de
## ekrana basılıyor, o yüzden isimleri de çeviriden geliyor (bkz.
## test_localization.gd sabit metin taraması). Sayı çalışma anında
## ekleniyor, üç ayrı anahtar açmaya değmez.
const SYNTHETIC_MERCHANT_COUNT: int = 3
const SYNTHETIC_PARTY_CULTURES: Array[String] = [
	CultureCatalog.HIGHLAND, CultureCatalog.NOMAD, CultureCatalog.VALLEY,
]

const LOCKED_COLOR: Color = Color(0.65, 0.6, 0.55)
## Seçenek işaretleri (bkz. _mark_choice): stat amblemi ve savaş şeridi.
const CHOICE_ICON_SIZE: int = 22
const CHOICE_STRIPE_WIDTH: float = 4.0
## Şerit sekmenin süslü köşesinin içinde, koyu yüzünde duruyor - kenarda
## köşe süsünün üstüne biniyordu (ekran görüntüsünde ölçüldü).
const CHOICE_STRIPE_INSET_X: float = 14.0
const CHOICE_STRIPE_INSET_Y: float = 9.0
const IMMEDIATE_COLOR: Color = Color(0.95, 0.8, 0.45)
const OUTCOME_COLOR: Color = Color(0.75, 0.85, 1.0)

## Pazarlık başarısız olursa tam bedel ödenir; başarı indirim demektir.
const HAGGLE_FAIL_MORALE: int = -8

## Savaş sonuçları. Zafer yolu bir süre güvenli kılar ve yağma getirir;
## yenilgi ağır ama kervanı bitirmez (bkz. EventEffectApplier clamp'leri).
const COMBAT_LOOT_BASE: int = 25
const COMBAT_LOOT_DANGER_BONUS: int = 60
const COMBAT_VICTORY_MORALE: int = 12
const COMBAT_VICTORY_REPUTATION: int = 4
const COMBAT_VICTORY_DANGER: int = -10
## Muhafızlara karşı kazanmak haydutlara karşı kazanmak gibi değil - kervan
## kanunla çatışmış olur, zafer bile itibarı yükseltmez, kırar (bkz.
## evt_guard_patrol, _on_combat_finished).
const GUARD_VICTORY_REPUTATION: int = -6
const COMBAT_DEFEAT_WAGON_DAMAGE: int = 2
const COMBAT_DEFEAT_MERCHANTS: int = 1
const COMBAT_DEFEAT_MORALE: int = -20
const COMBAT_DEFEAT_GOLD: int = -40
const COMBAT_STRESS_BASE: int = 8
const COMBAT_STRESS_PER_DOWN: int = 6
const COMBAT_VICTORY_STRESS_RELIEF: int = 4
const COMBAT_DEFEAT_STRESS: int = 15

## Aç bir kervanın yavaşlaması (`HUNGRY_PACE_MULTIPLIER`) ve karşılaşmaya
## ulaşma payı artık `JourneyController`'da - yürüyüş formülü orada tek yerde.

## Yol artık tuşla değil akan zamanla ilerliyor (bkz. JourneyClock). Aşağıdaki
## süreler olayların "arka planda zamandan yemesi" içindir: bir olay kartını
## çözmek yolun bir parçasını tüketir, çarpışma daha fazlasını.
const EVENT_HOURS: float = 1.5
const COMBAT_HOURS: float = 2.5
const HAGGLE_HOURS: float = 1.0
const RECRUIT_HOURS: float = 0.5

## Kamp anlık bir tuş değil, yaşanan bir durum: ateş yanar, zaman akmaya
## devam eder ve sabah olunca kamp kendiliğinden kalkar. Faydası (erzak
## bedeli + stres rahatlaması) kalkarken uygulanır.
const CAMP_HOURS: float = GameSession.CAMP_HOURS

## Yolda karşılaşılan biri şehirdeki kadar seçici değil ama pazarlık payı
## da bırakmıyor.
const ROAD_RECRUIT_COST_MULTIPLIER: float = 1.25

## --- Yürümek ---
## Kervan seçilen tempoyla kendi yürür; oyuncunun eli kervanda değil
## liderde. Bir süre yol ancak D basılı tutulduğu sürece kat ediliyordu -
## o basış hiçbir karar taşımıyordu, yalnızca angaryayı ölçüyordu. Yoldaki
## gerçek kararlar tempo (yavaş/normal/hızlı/dur), liderin kolondaki yeri
## (bkz. RoadAttention), kamp ve dönüp dönmemek; giriş artık onlara gidiyor.
## Durmak yine günü durdurmaz: "Dur" temposunda erzak yenir, yol kısalmaz -
## oyalanmanın bedelini takvim ödetir, tıpkı eskisi gibi.
##
## Geri yürüme (eski A, 0.25 hızla) kaldırıldı; görülen bir tehlikeden
## kaçınmanın yolları Dur ve Geri Dön/Rota Değiştir (bkz. `_apply_replan`,
## bekleyen karşılaşmayı eski yolla birlikte geride bırakır).

## --- Yolda yaklaşan olay ---
## Günün olayı ("kurt var", "evrak isteyen bir görevli") artık kart olarak
## anında açılmıyor: önce yolda bir figür olarak görünüyor (bkz.
## RoadEncounter), kervan ona yaklaşınca kart açılıyor. Yalnızca bir
## *fiziksel karşılığı* olan olaylar bunu yapıyor (EVENT_ROAD_MARKER_KIND'de
## listelenenler) - kendi vagonunun bozulması, hava ya da parti içi bir
## mesele gibi yolda "görülecek" bir şeyi olmayan olaylar eskisi gibi
## anında açılıyor.
##
## `ENCOUNTER_APPROACH_DAYS` işaretin kervandan ne kadar önde belirdiği
## (gün cinsinden mesafe - `TravelBand.PIXELS_PER_DAY` ile piksele çevrilir).
## Küçük tutulmalı: büyürse oyuncu günün geri kalanını bir şeye doğru
## yürüyerek geçirir, bu bir onay adımı olmalı, ikinci bir yolculuk değil.
const ENCOUNTER_APPROACH_DAYS: float = 0.35

## "Kervan Emirleri" paneli manzaranın üstünde, sol altta duruyor (bkz.
## _build_hud_layer) ve dile/genişliğe göre kendi boyunu değiştiriyor.
## Kolon panelin sağından başlasın diye genişliği her karede
## `TravelBand`/`RoadCaravan`'a bildiriliyor - vagon panelin altına
## girerse kervanın kendisi görünmez olur, bu bir okunabilirlik hatası
## değil bir bilgi kaybıdır.
const ORDERS_PANEL_SAFE_MARGIN: float = 16.0

## event_id -> CombatFigure.ARCHETYPES kategorisi. Eşlemede olmayan her
## olay eskisi gibi davranır (hiç işaret yok, kart anında açılır) - bu
## sessiz bir eksiklik değil, çünkü o olayların yolda gösterilecek somut
## bir figürü yok (bkz. yukarıdaki not).
const EVENT_ROAD_MARKER_KIND: Dictionary = {
	"evt_wild_animal": "wildlife",
	"evt_wolf_pack": "wildlife",
	"evt_bandit_ambush": "bandit",
	"evt_deserter_search": "guard",
	"evt_bailiffs_at_camp": "guard",
	"evt_deserter_plea": "traveler",
	"evt_wanderer_revenge": "bandit",
	"evt_guard_patrol": "guard",
	"evt_customs_checkpoint": "guard",
	"evt_road_patrol": "guard",
	"evt_road_wanderer": "traveler",
	"evt_traveling_tinker": "traveler",
	"evt_kin_encounter": "traveler",
	"evt_culture_valley_dispute": "traveler",
	"evt_culture_highland_challenge": "traveler",
	"evt_culture_port_gossip": "traveler",
	"evt_culture_fisher_catch": "traveler",
	"evt_military_convoy": "guard",
	"evt_refugee_column": "traveler",
	"evt_merchant_caravan": "traveler",
}

## Her kategori birden fazla `CombatFigure` arketipine düşebiliyor (aynı
## haydut pususunun kadroda birkaç çeşidi olması gibi) - tekdüzeliği kırıyor
## ama günün sayısından türediği için bir kez seçilince karede değişmiyor.
const MARKER_ARCHETYPES: Dictionary = {
	"wildlife": ["wolf", "bear", "boar"],
	"bandit": ["bandit", "bandit_leader"],
	"guard": ["guard", "guard_sergeant"],
	"traveler": ["clerk", "hunter"],
}

## --- Kervan emirleri ---
## Her zaman görünen bir panel: tempo dört düğmeden biri, tüccar ve borç
## birer düğme. Eskiden F2'nin arkasında gizli bir menüydü - dokunmatik
## ekranda hiç açılamıyordu ve oyuncu temponun bir karar olduğunu
## göremiyordu. Tuşlar (1-6, F2 ile tempo döngüsü) yalnızca kısayol.
##
## Tempo yolun *hızını* çarpıyor. Normal tempo 1.0, yani emir vermeyen bir
## oyuncu için hiçbir şey değişmiyor - "durmadan ileri yürüyen oyuncu
## seferi planlayıcının söylediği günde bitirir" sözü aynen duruyor.
const PACE_CYCLE_KEY: Key = KEY_F2
const PACE_STEADY: float = 1.0
const PACE_FAST: float = 1.35
const PACE_SLOW: float = 0.70
const PACE_HALT: float = 0.0

## Hızlı tempo bedava değil, yavaş tempo boşuna değil: ikisi de zaten var
## olan kollardan geçiyor (stres ve moral), yeni bir sistem açmıyor.
## Olmasa "hızlan" her koşulda doğru cevap olurdu ve bir emir menüsü
## tek seçenekten oluşurdu.
## Savaşta yere düşen kişinin kendi üstünde kalan iz.
const DOWNED_STRESS_MARK: int = 9

## Görmezden gelinen bir işaretin bedeli.
const SIGNAL_STRAGGLER_STRESS: int = 5
## Birikmiş duman payının tavanı: yol tehlikeli olabilir, imkânsız olamaz.
const SIGNAL_DANGER_CAP: float = 0.35

const PACE_FAST_STRESS_PER_DAY: int = 3
const PACE_FAST_MORALE_PER_DAY: int = -2
const PACE_SLOW_MORALE_PER_DAY: int = 2

## Lider kolonda gezerken adım hızı (gün/saat cinsinden değil, kolondaki
## piksel/saat): kervanın boyu zaten sınırlı, bu yalnızca ne kadar çabuk
## arkaya inildiğini belirliyor.
const LEADER_WALK_SPEED: float = 46.0

## Ortadaki karar kartının genişliği. EU4'ün olay kartı gibi: ekranın
## tamamını kaplamıyor, arkasında dünyanın durduğu görünüyor.
const CARD_WIDTH: float = 660.0
## Kart gövdesinin en fazla ne kadar yer kaplayacağı - uzun bir metin
## kartı ekran boyu uzatmasın diye kaydırma kutusuna giriyor.
const CARD_BODY_MAX_HEIGHT: float = 320.0

## Yol HUD'unun Waybook parçaları (bkz. Waybook UI Rules).
const TIME_DIAL_SIZE: float = 34.0
const STRAP_HEIGHT: float = 14.0
## Şehre varışta yeni sahne mürekkepte bu kadar bekliyor (bkz. SceneInk).
const ARRIVAL_INK_HOLD: float = 0.6
const HUD_ICON_SIZE: float = 24.0
## Alt şeritteki yürüme ipucu ve son kayıt satırı - ikisi de `clip_text`
## sayesinde kendi asgari genişliği sıfıra düşen `Label`'lar, bu taban
## olmadan `HFlowContainer` onları neredeyse hiç yer vermeden sıkıştırıyordu.
const HUD_HINT_MIN_WIDTH: float = 220.0
const ZONE_ICONS: Dictionary = {
	RoadAttention.ZONE_FRONT: "r6a_front.png",
	RoadAttention.ZONE_WAGONS: "r6b_wagons.png",
	RoadAttention.ZONE_REAR: "r6c_rear.png",
}
const SIGNAL_ICONS: Dictionary = {
	RoadSignals.KIND_WHEEL: "r7a_wheel.png",
	RoadSignals.KIND_STRAGGLER: "r7b_straggler.png",
	RoadSignals.KIND_SMOKE: "r7c_smoke.png",
}
const SIGNAL_FLASH_SECONDS: float = 1.6
const SIGNAL_FADE_SECONDS: float = 0.8
const EDGE_STRESS_FILE: String = "g11_edge_bleed.png"
const EDGE_HUNGER_FILE: String = "g11_edge_scorch.png"
const EDGE_MAX_ALPHA: float = 0.85
const EDGE_COLD_FILE: String = "g11_edge_frost.png"
## Don kenarı soğuktan: kış mevsimi en çok, dağ geçidi kışın dışında da
## biraz. Hava bir sistem icat etmiyor (Route Terrain & Weather Rules) -
## don yalnızca görüntü, hiçbir sayıya dokunmuyor.
const EDGE_COLD_WINTER: float = 0.7
const EDGE_COLD_MOUNTAIN: float = 0.35
## Stres kırılma bölgesine yaklaşırken leke başlıyor (Stress Rules'un
## kavga eşiği 40), dolmuş bir kervanda tam koyulukta.
const EDGE_STRESS_FROM: float = 35.0
const EDGE_STRESS_FULL: float = 85.0
## Açlıktan can kaybı üçüncü gecede başlıyor (STARVATION_HP_LOSS_START_DAY);
## kenar ondan bir gece sonra tamamen kavrulmuş.
const EDGE_HUNGER_FULL_NIGHTS: int = 4

var _session: GameSession
## Seferin görsel olmayan durumu (mesafe, gün, tempo, kamp, saat, olay
## motoru) - bkz. JourneyController. Aşağıdaki alanlar ona açılan takma
## adlar: ekranın geri kalanı değişmeden okuyup yazabilsin, ama tek
## doğruluk kaynağı ve kaydedilen şey controller.
var _journey: JourneyController = JourneyController.new()
var _engine: EventEngine:
	get:
		return _journey.engine
	set(value):
		_journey.engine = value
var _current_event: GameEvent
## Yolda görünüp kartı henüz açılmamış olay - bkz. Yolda yaklaşan olay.
var _pending_event: GameEvent:
	get:
		return _journey.pending_event
	set(value):
		_journey.pending_event = value
var _pending_event_day_position: float:
	get:
		return _journey.pending_event_day_position
	set(value):
		_journey.pending_event_day_position = value
var _encounter: RoadEncounter = null
var _current_combat_kind: String = "bandit"
var _pending_combat_danger: float = 0.0
var _pre_combat_panel: PreCombatPanel = null
## Bu savaşa gerçekten katılanlar (bkz. PreCombatPanel) - dışarıda
## kalanlar risk almadığı için ne XP alır ne düşme izi taşır.
var _current_combat_party: Array[CharacterData] = []
var _current_day: int:
	get:
		return _journey.current_day
	set(value):
		_journey.current_day = value
var _hungry: bool:
	get:
		return _journey.hungry
	set(value):
		_journey.hungry = value
var _is_live_journey: bool = false
var _pending_haggle_max: int = 0
## Varış bir kez işlenir - bkz. _check_journey_end.
var _journey_finished: bool = false

var _clock: JourneyClock:
	get:
		return _journey.clock
	set(value):
		_journey.clock = value
var _band: TravelBand
var _caravan: RoadCaravan
## Yolun coğrafyası ve o günkü havası. İkisi de tohumdan hesaplanıyor,
## planlayıcının gösterdiğiyle birebir aynı (bkz. RouteTerrain,
## RouteWeather) - yolda başka bir arazi görülürse planlayıcı yalan
## söylemiş olur.
var _terrain: RouteTerrain
var _route_key: String = ""
var _weather: String = RouteWeather.CLEAR
var _pace: float:
	get:
		return _journey.pace
	set(value):
		_journey.pace = value
var _pace_key: String:
	get:
		return _journey.pace_key
	set(value):
		_journey.pace_key = value
## Liderin kolondaki yeri (0 = baş, eksi = geriye doğru). A/D, ok tuşları,
## kumanda ya da kervana dokunmak/tıklamak onu yürütür; kervanı değil.
var _leader_offset: float = 0.0
## Dokunma/tıklama hedefi: lider oraya kendi yürür, klavye girişi iptal eder.
var _leader_target: float = 0.0
var _has_leader_target: bool = false
## Liderin kolondaki yeri = neye dikkat ettiği (bkz. RoadAttention).
## Kolona bağlıyken lider baştadır, yani ön bölgededir.
var _attention_zone: String = RoadAttention.ZONE_FRONT
## Yolun sürekli konuşan katmanı (bkz. RoadSignals) - modal değil,
## kart açmıyor, zamanı durdurmuyor.
var _signals: RoadSignals = RoadSignals.new()
var _signal_rng: RandomNumberGenerator:
	get:
		return _journey.signal_rng
	set(value):
		_journey.signal_rng = value
## Duman görmezden gelindiğinde yolun tehlikesine eklenen pay.
var _signal_danger_bonus: float:
	get:
		return _journey.signal_danger_bonus
	set(value):
		_journey.signal_danger_bonus = value
var _command_panel: PanelContainer
var _orders_button: Button
## Panel varsayılan olarak kapalı başlıyor (bkz. Road Movement Rules'un
## Kontrol-7 notu) - bu, düğmenin gerçek durumu, `_command_panel.visible`
## savaş/kapanış gibi başka sebeplerle de false olabildiği için tek başına
## yetmiyor.
var _orders_open: bool = false
## Panel ilk kez açıldığında varsayılan bir konuma (eski, hep-açık halinin
## durduğu yere yakın) yerleşiyor; oyuncu bir kez sürükleyince bu bayrak
## true olur ve bir daha otomatik konumlanmaz.
var _orders_positioned: bool = false
var _orders_dragging: bool = false
var _orders_drag_offset: Vector2 = Vector2.ZERO
var _pace_buttons: Array[Button] = []
var _talk_merchant_button: Button
var _debt_button: Button
## Yan kanal açıkken emirler kilitli; her karede tazelenen düğmeler bu
## kilidi ezmesin diye ayrı tutuluyor.
var _orders_enabled: bool = true
var _meal_policy_button: Button
var _camp_order_button: Button
var _in_game_menu: InGameMenu = null
var _succession_panel: SuccessionPanel = null
var _meal_panel: MealDistributionPanel = null
var _merchant_dialogue_panel: MerchantDialoguePanel = null
var _camping: bool:
	get:
		return _journey.camping
	set(value):
		_journey.camping = value
var _camp_ends_at_hours: float:
	get:
		return _journey.camp_ends_at_hours
	set(value):
		_journey.camp_ends_at_hours = value
## Seferin toplam gün uzunluğu - ilerleme çubuğu bunun üzerinden hesaplanır.
var _journey_length_days: int:
	get:
		return _journey.journey_length_days
	set(value):
		_journey.journey_length_days = value
## Kat edilen yol, "gün" cinsinden. Konumun tek doğruluk kaynağı burası:
## `journey_days_remaining` artık bir sayaç değil, bundan *türetilen* bir
## gösterge (bkz. _sync_days_remaining). Ters sırada tutulsaydı bir olayın
## "yol +1 gün" etkisi bir sonraki karede silinirdi.
var _days_covered: float:
	get:
		return _journey.days_covered
	set(value):
		_journey.days_covered = value
## Son karede hangi yöne yürüdüğümüz - ipucu satırı bunu gösteriyor.
var _walk_direction: float = 0.0

var _clock_label: Label
var _speed_button: Button
## --- Yakınlaştırma ---
## Yolda bir miktar yakınlaşıp uzaklaşılabiliyor: tekerlek, iki parmak ya
## da HUD'daki +/- düğmeleri (dokunmatik denklik). Alt sınır 1.0, çünkü
## şerit ekranın tamamını dolduruyor - daha uzağı manzaranın kenarını
## gösterirdi. Merkez liderin başı ve zemin çizgisi: yakınlaşan göz
## kervandan kopmasın.
const ZOOM_MIN: float = 1.0
const ZOOM_MAX: float = 1.6
const ZOOM_STEP: float = 0.1
const ZOOM_EASE: float = 8.0
## Süreç boyunca akılda: bir sonraki seferde de oyuncunun seçtiği yakınlık.
static var _zoom_target: float = ZOOM_MIN
var _zoom: float = ZOOM_MIN
var _pinch_points: Dictionary = {}  # index -> Vector2
var _pinch_distance: float = 0.0
var _progress_bar: ProgressBar

## _refresh_time_ui() her karede koşuyor; gösterilen değer değişmedikçe
## yeniden string kurmamak için son basılan değerler burada tutuluyor.
var _last_clock_text: String = ""
var _last_phase: JourneyClock.Phase = JourneyClock.Phase.DAWN
var _last_speed: float = -1.0
var _last_walk_hint: String = ""

var _seed_spin: SpinBox
var _dev_row: HBoxContainer
var _walk_hint: Label
var _conditions_label: Label
var _last_conditions: String = ""
var _state_label: Label
var _card_panel: VBoxContainer
var _haggle_holder: VBoxContainer
var _combat_holder: VBoxContainer
var _recruit_holder: VBoxContainer
var _replan_holder: VBoxContainer
var _replan_button: Button
## Faz 17 PR-6: borç defteri artık yolda da açılabiliyor - eskiden yalnızca
## Tüccar Loncası'ndan erişilebiliyordu, oysa road HUD'u borcu zaten
## gösteriyordu ama üstünde hiçbir şey yapılamıyordu.
var _debt_holder: VBoxContainer
var _debt_panel: DebtPanel
var _log_list: VBoxContainer
var _reset_button: Button
var _camp_button: Button
var _arrive_button: Button
var _arrival_panel: VBoxContainer
var _enter_city_button: Button
var _exit_button: Button

## --- Ekranın dört katmanı ---
## Yol ekranı uzun süre *kaydırılan bir metin sütunuydu*: manzara şeridi o
## sütunun bir satırı, olay kartı başka bir satırı, durum dökümü ve kayıt
## listesi geri kalanıydı. Şikâyet buydu - "oyun hâlâ text based RPG gibi".
## Sebep düzendi: dünya, ekranın küçük bir kutusuydu ve metin ekranı
## yutuyordu.
##
## Artık dünya ekranın kendisi (Kingdom Two Crowns yerleşimi): manzara tam
## ekran, HUD onun üstünde ince iki şerit, kararlar ekranın ortasında bir
## kart (EU4 yerleşimi), kayıt listesi ise bir tuşla açılan ayrı bir
## katman. Metin artık ekranı değil, ekranın kenarını kullanıyor.
@onready var _world: MarginContainer = $World
@onready var _hud: VBoxContainer = $Hud
## "Kervan Emirleri" paneli artık bir Container çocuğu değil - serbestçe
## sürüklenebilmesi için kendi düz katmanında duruyor (bkz. _build_orders_panel).
@onready var _orders_layer: Control = $OrdersLayer
@onready var _modal: Control = $Modal
@onready var _modal_center: CenterContainer = $Modal/Center
@onready var _log_overlay: MarginContainer = $LogOverlay
## Kervanın tam dökümü. Kendi katmanı, çünkü kayıt katmanıyla aynı anda
## açık olmaları anlamsız ama biri ötekini kapatmak zorunda da değil.
@onready var _status_overlay: MarginContainer = $StatusOverlay

## Alt şeritteki tek satırlık kayıt - listenin tamamı artık `_log_overlay`'de.
var _last_log_label: Label
var _log_button: Button
var _status_button: Button
var _status_panel: CaravanStatusPanel
var _help_button: Button
## Moral/stres/tehlike sayı değil **çubuk**: bir orandan ibaret olan üç
## değeri rakam olarak okumak, oyuncuyu her karede metin okumaya zorluyor.
## `PulseBar` şehir dışı HUD'da zaten bunu yapıyor (bkz. world_hub.gd) -
## aynı çubuk burada da kullanılıyor, yol ekranı kendi göstergesini icat
## etmiyor.
var _morale_bar: PulseBar
var _stress_bar: PulseBar
var _danger_bar: PulseBar
## Takat: temponun harcanan kaynağı. Görünmeyen bir kaynak kaynak
## değildir - oyuncu neyi harcadığını görmeden harcama kararı veremez.
var _stamina_bar: PulseBar
## Liderin o an neye dikkat ettiği. Mekanik görünmezse hata gibi okunur.
var _attention_label: Label
## Dikkatin yeri bir ikon da taşıyor (baş/vagonlar/art) - etiket okunmadan
## bir bakışta. Açık bir yol işareti de kendi ikonuyla yanında duruyor.
var _attention_icon: TextureRect
var _signal_icon: TextureRect
var _signal_tween: Tween
var _time_dial: TimeDial
## Kenar lekeleri: stres yükseldikçe mürekkep kenardan sızıyor, açlık
## gecesi uzadıkça sayfanın kenarı kavruluyor. Sayı değil his - sayısı
## zaten şişede yazılı.
var _stress_edge: Control
var _hunger_edge: Control
var _cold_edge: Control
## Modal katmanı her karede içeriğe bakıyor (bkz. _refresh_modal); son
## durum burada tutuluyor ki görünürlük her karede yeniden atanmasın.
var _modal_open: bool = false

func _ready() -> void:
	AudioManager.play_track(AudioManager.TRACK_ROAD)
	_build_ui()
	_init_journey()

func _build_ui() -> void:
	_build_world_layer()
	_build_hud_layer()
	_build_modal_layer()
	_build_log_layer()
	_build_status_layer()
	_refresh_exit_button()

## Dünya katmanı: manzara ve (savaş varsa) savaş sahnesi. `MarginContainer`
## çocuklarını kendi dikdörtgenine oturtuyor, yani ikisi de tam ekran -
## çapa ön ayarına güvenmek gerekmiyor (bkz. Art Rules'un çapa tuzağı).
func _build_world_layer() -> void:
	# Manzara şeridi: gökyüzü/zemin günün evresine göre değişir, dünya
	# kervanın altından akar (bkz. TravelBand).
	_band = TravelBand.new()
	_world.add_child(_band)
	# Yakınlaşan şerit dünya katmanının dışına taşmasın (HUD şeritlerinin
	# altına sızardı).
	_world.clip_contents = true

	# Kervan şeridin *çocuğu*: manzara arkada çizilir, figürler onun
	# üstünde. Ayrı bir kardeş düğüm olsaydı iki ayrı zemin çizgisi
	# hesaplanırdı ve eğimli yolda kervan havada yürürdü.
	_caravan = RoadCaravan.new()
	# `add_child` değil `add_actor_layer`: şerit ön plan katmanını her
	# zaman en üstte tutuyor, yoksa yolun önündeki çalılar kervanın
	# arkasına düşüyor ve figürler onların üzerinde yürüyor gibi
	# duruyor (bkz. TravelForeground).
	_band.add_actor_layer(_caravan)
	_band.ground_line_changed.connect(_caravan.set_ground_line)
	# Kolon uzadıkça çapa sağa kayıyor, yoksa satın alınan her vagon
	# ekranın solundan dışarı çıkıyor (bkz. TravelBand.CARAVAN_X_RATIO).
	_caravan.column_length_changed.connect(_band.set_column_length)

	# Savaş yolun *yerine* açılıyor: aynı çerçeve, aynı ekran alanı.
	_combat_holder = VBoxContainer.new()
	_combat_holder.visible = false
	_world.add_child(_combat_holder)

	# Kenar lekeleri dünyanın üstünde, HUD'un altında; savaşta da duruyor,
	# çünkü yıpranma savaşa girince geçmiyor.
	_stress_edge = _edge_overlay(EDGE_STRESS_FILE, ArtPalette.UI_EDGE_STRESS)
	_hunger_edge = _edge_overlay(EDGE_HUNGER_FILE, ArtPalette.UI_EDGE_HUNGER)
	_cold_edge = _edge_overlay(EDGE_COLD_FILE, ArtPalette.UI_EDGE_COLD)

## Kenar maskesi tek parça bir resim: ekranın tamamına geriliyor. Bir süre
## dokuz dilimliydi (kalınlık en boy oranından bağımsız kalsın diye) ama
## maskeler bütün bir çerçeve olarak boyandı ve oyuncu onları öyle görmek
## istedi - dilimlenince köşe süslemesi ile kenar ortası birbirinden koptu.
func _edge_overlay(file_name: String, tint: Color) -> Control:
	var frame := TextureRect.new()
	frame.texture = WaybookTheme.texture(file_name)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.modulate = Color(tint, 0.0)
	_world.add_child(frame)
	return frame

## Soğuğun koyuluğu (0..1): kış ve dağ toplanıyor, üstü kesiliyor.
static func cold_level(is_winter: bool, biome: String) -> float:
	var level := EDGE_COLD_WINTER if is_winter else 0.0
	if biome == ArtPalette.BIOME_MOUNTAIN:
		level += EDGE_COLD_MOUNTAIN
	return clampf(level, 0.0, 1.0)

## HUD: üstte zaman/durum şeridi, altta eylem şeridi, ikisinin arasında
## dünyanın göründüğü boşluk. Şeritler dışında hiçbir yer tıklamayı
## yutmuyor - aradaki boşluk `MOUSE_FILTER_IGNORE`.
func _build_hud_layer() -> void:
	_hud.add_child(_build_top_bar())
	_hud.add_child(WaybookTheme.strap_rule(STRAP_HEIGHT))

	# Boş - dünyanın göründüğü aralığı iki şerit arasında açık tutuyor.
	# Emir paneli artık burada değil, kendi serbest katmanında (bkz.
	# _build_orders_panel): bir Container'ın çocuğuyken elle taşınamıyordu.
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(middle)

	_hud.add_child(WaybookTheme.strap_rule(STRAP_HEIGHT))
	_hud.add_child(_build_bottom_bar())
	_build_orders_panel()

func _build_top_bar() -> PanelContainer:
	var bar := _make_bar()
	var row := _make_bar_row()
	bar.add_child(row)

	_time_dial = TimeDial.new()
	_time_dial.custom_minimum_size = Vector2(TIME_DIAL_SIZE, TIME_DIAL_SIZE)
	row.add_child(_time_dial)

	_clock_label = Label.new()
	_clock_label.custom_minimum_size = Vector2(150.0, 0.0)
	_clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_clock_label)

	# Zaman artık tuşla değil kendiliğinden akıyor; oyuncunun tek kontrolü
	# ne kadar hızlı aktığı (bkz. JourneyClock.SPEEDS).
	_speed_button = Button.new()
	_speed_button.theme_type_variation = WaybookTheme.ICON_TAB
	_speed_button.tooltip_text = tr("UI_ROAD_SPEED_TOOLTIP")
	_speed_button.pressed.connect(_on_speed_pressed)
	row.add_child(_speed_button)

	for step in [-1, 1]:
		var zoom_button := Button.new()
		zoom_button.theme_type_variation = WaybookTheme.ICON_TAB
		zoom_button.tooltip_text = tr("UI_ROAD_ZOOM_OUT" if step < 0 else "UI_ROAD_ZOOM_IN")
		zoom_button.pressed.connect(_step_zoom.bind(step))
		row.add_child(zoom_button)
		# "–"/"+" font glyph'i değil çizim: kulağın simetrik ICON_TAB'ı bile
		# tek bir karakterin fontun kendi metrik boşluğuyla ortalanmamasını
		# düzeltmiyor - UiIcon aynı chevron/check diliyle tam merkezde çiziyor.
		var zoom_icon := UiIcon.new()
		zoom_icon.setup(UiIcon.Kind.MINUS if step < 0 else UiIcon.Kind.PLUS, ArtPalette.UI_TEXT)
		zoom_button.add_child(zoom_icon)
		zoom_icon.fill_parent()

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.step = 0.001
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(110.0, 14.0)
	_progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Boyanmamış bir ProgressBar zoom düğmeleriyle koşullar metni arasında
	# koyu, tanımsız bir boşluk gibi okunuyordu ("dark empty gauge slot") -
	# HUD'un geri kalanı gibi temalanmadığı sürece bu bir kusurdan farksız.
	var progress_empty := StyleBoxFlat.new()
	progress_empty.bg_color = ArtPalette.UI_GAUGE_EMPTY
	progress_empty.corner_radius_top_left = 3
	progress_empty.corner_radius_top_right = 3
	progress_empty.corner_radius_bottom_left = 3
	progress_empty.corner_radius_bottom_right = 3
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = ArtPalette.UI_GAUGE_JOURNEY
	progress_fill.corner_radius_top_left = 3
	progress_fill.corner_radius_top_right = 3
	progress_fill.corner_radius_bottom_left = 3
	progress_fill.corner_radius_bottom_right = 3
	_progress_bar.add_theme_stylebox_override("background", progress_empty)
	_progress_bar.add_theme_stylebox_override("fill", progress_fill)
	row.add_child(_progress_bar)

	# Arazi, hava ve tempo. Hava yalnızca görsel değil (yolu yavaşlatıyor,
	# tehlikeyi büyütüyor), o yüzden okunabilir bir yerde durması şart -
	# görünmeyen bir ceza oyuncu için hatadan ayırt edilemez.
	_conditions_label = Label.new()
	_conditions_label.modulate = ArtPalette.UI_HUD_NOTE
	# Asgari genişlik olmadan, yanındaki genişleyen etiket bunu sıfıra
	# sıkıştırıyor ve `clip_text` yüzünden hiç görünmüyordu.
	# Takat çubuğu eklenince üst şerit taştı ve kervan sayıları
	# kırpılmaya başladı; koşul satırı daraltıldı. Şeridin dolduğu her
	# seferde önce *neyin* oraya ait olduğu sorulmalı - dikkat etiketi
	# bu yüzden alt şeride taşındı.
	# Ölçüldü (1280x720): sabit 372'lik koşul satırı ve dört şişe üst şeridin
	# asgari genişliğini 1582'ye çıkarıp HUD'u ekranın iki yanından
	# taşırıyordu - alt şerit de aynı sütunda olduğu için o da kırpılıyordu.
	# Koşul satırı artık kervan sayılarıyla kalan yeri paylaşıyor.
	# `clip_text` harfi ortadan kesiyordu ("...Weather: Clear · P") - alt
	# şeridin `_walk_hint`/`_last_log_label`'ında bulunan aynı düzeltme:
	# elips + tam metni tooltip'e taşımak.
	_conditions_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_conditions_label.custom_minimum_size = Vector2(150.0, 0.0)
	_conditions_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_conditions_label)

	_morale_bar = PulseBar.new()
	row.add_child(_morale_bar)
	_morale_bar.setup(tr("UI_HUB_MORALE"), ArtPalette.UI_GAUGE_MORALE, "r4a_morale.png")

	_stress_bar = PulseBar.new()
	row.add_child(_stress_bar)
	_stress_bar.setup(tr("UI_HUB_STRESS"), ArtPalette.UI_GAUGE_STRESS, "r4b_stress.png")

	# Tehlike de bir oran, o yüzden o da çubuk - ve yolun tehlikesi
	# oyuncunun en sık baktığı sayı olduğu için metin içinde kaybolmamalı.
	_danger_bar = PulseBar.new()
	row.add_child(_danger_bar)
	_danger_bar.setup(tr("UI_HUB_DANGER"), ArtPalette.UI_GAUGE_DANGER, "r4c_danger.png")

	_stamina_bar = PulseBar.new()
	row.add_child(_stamina_bar)
	_stamina_bar.setup(tr("UI_ROAD_STAMINA"), ArtPalette.UI_GAUGE_STAMINA, "r4d_stamina.png")


	# Kervanın sayıları tek satır: sarılmıyor, taşarsa kırpılıyor. Sarılan
	# bir döküm HUD'u yeniden metin duvarına çeviriyordu. `clip_text` ise
	# harfi ortadan kesiyordu ("Wagons: 1 (0...") - aynı elips + tooltip
	# düzeltmesi. Font da 12 px'ten (EB Garamond'un küçük gözü için okunaksız)
	# güvenlik tabanı 15 px'e çıktı.
	# Bu satır (altı sayı: altın/erzak/itibar/vagon/tüccar/evrak) komşu koşul
	# etiketinden çok daha uzun metin taşıyor ("Terrain...Pace" ~50 karakter,
	# bu satır ~95); eşit 50/50 pay bölüşümü onu neredeyse hep elipse
	# düşürüyordu. Asgari genişlik ve payı komşusundan büyük - HFlowContainer
	# geri kalan alanı stretch oranına göre bölüştürüyor.
	_state_label = Label.new()
	_state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_state_label.size_flags_stretch_ratio = 1.6
	_state_label.custom_minimum_size = Vector2(300.0, 0.0)
	_state_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_state_label.add_theme_font_size_override("font_size", 15)
	row.add_child(_state_label)

	# Geliştirici kutusu (tohum + sıfırla) yalnızca F1 sentetik seferinde
	# görünür; gerçek bir seferde oyuncunun önünde duracak işi yok.
	_dev_row = HBoxContainer.new()
	_dev_row.add_theme_constant_override("separation", 8)

	var seed_label := Label.new()
	seed_label.text = "Seed:"
	_dev_row.add_child(seed_label)

	_seed_spin = SpinBox.new()
	_seed_spin.min_value = 0
	_seed_spin.max_value = 999999
	_seed_spin.step = 1
	_seed_spin.value = 1234
	_dev_row.add_child(_seed_spin)

	_reset_button = Button.new()
	_reset_button.text = tr("EVT_TEST_RESET")
	_reset_button.pressed.connect(_on_reset_pressed)
	_dev_row.add_child(_reset_button)

	row.add_child(_dev_row)
	return bar

## Şeridin satırı akışlı: genişlik yetiyorsa tek satır (masaüstünde eskisi
## gibi), yetmiyorsa ikinci satıra iniyor. Tek satırlık bir `HBoxContainer`
## telefonun dikey ekranında asgari genişliğini ekranın iki katına çıkarıp
## HUD'u iki yandan kırpıyordu (oyuncunun ekran görüntüsünde ölçüldü).
func _make_bar_row() -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 4)
	return row

func _build_bottom_bar() -> PanelContainer:
	var bar := _make_bar()
	var row := _make_bar_row()
	bar.add_child(row)

	# Yolu oyuncu yürüyor: bunu söylemeyen bir ekran, oyuncuya "kontrol
	# bende değil" dedirtiyordu (ilk şikâyet tam olarak buydu). `clip_text`
	# bir Label'ın asgari genişliğini metinden bağımsız sıfıra düşürüyor -
	# `HFlowContainer` da her çocuğa yalnızca kendi asgarisi kadar yer
	# ayırdığı için, altyazı hiçbir zaman taşmadan bir piksele kadar
	# sıkışabiliyordu (P0 - oyuncunun A/D'yi öğrendiği tek yer buydu).
	# Taban genişlik onu sıfıra inmekten koruyor, `OVERRUN_TRIM_ELLIPSIS`
	# de taşan kısmı "…" ile kesip tam metni `tooltip_text`'te tutuyor.
	_walk_hint = Label.new()
	_walk_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_walk_hint.custom_minimum_size = Vector2(HUD_HINT_MIN_WIDTH, 0.0)
	_walk_hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_walk_hint.clip_text = true
	row.add_child(_walk_hint)

	# Dikkat bir çubuk değil çünkü oran değil, bir *yer*: üç bölgeden
	# biri. Çubuk yapmak "biraz öndeyim" gibi olmayan bir ara durum
	# uydururdu. Yeri de üst şerit değil alt şerit: oyuncunun ellerinin
	# olduğu yer burası, yürüme ipucunun tam yanı - dikkat zaten
	# yürüyerek değiştiriliyor.
	_attention_icon = WaybookTheme.picture(ZONE_ICONS[RoadAttention.ZONE_FRONT], HUD_ICON_SIZE)
	row.add_child(_attention_icon)

	_attention_label = Label.new()
	_attention_label.modulate = ArtPalette.UI_HUD_NOTE
	_attention_label.clip_text = true
	_attention_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# Yürüme ipucu boşken etiket sıfıra çöküyordu: alt şeritteki diğer
	# her şey gibi kendi yerini istemesi gerekiyor.
	_attention_label.custom_minimum_size = Vector2(200.0, 0.0)
	row.add_child(_attention_label)

	# Açık bir işaret yoksa gizli; varsa kendi bölgesine yürünmesi gereken
	# şeyin resmi. Büyüyünce kan, yetişilince yosun rengiyle bir an parlıyor.
	_signal_icon = WaybookTheme.picture(SIGNAL_ICONS[RoadSignals.KIND_WHEEL], HUD_ICON_SIZE)
	_signal_icon.mouse_filter = Control.MOUSE_FILTER_PASS
	_signal_icon.visible = false
	row.add_child(_signal_icon)

	row.add_child(VSeparator.new())

	# Kayıt listesinin tamamı yerine **son satırı**. Listenin kendisi
	# `_log_overlay`'de, bir tuşla açılıyor: yolda okunması gereken şey
	# son ne olduğu, bütün defter değil.
	_last_log_label = Label.new()
	_last_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_last_log_label.custom_minimum_size = Vector2(HUD_HINT_MIN_WIDTH, 0.0)
	_last_log_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_last_log_label.clip_text = true
	_last_log_label.modulate = ArtPalette.UI_HUD_NOTE
	row.add_child(_last_log_label)

	_camp_button = Button.new()
	_camp_button.text = tr("UI_ROAD_MAKE_CAMP")
	_camp_button.tooltip_text = tr("UI_ROAD_CAMP_TOOLTIP")
	_camp_button.pressed.connect(_on_camp_pressed)
	row.add_child(_camp_button)

	_replan_button = Button.new()
	_replan_button.text = tr("UI_ROAD_REPLAN")
	_replan_button.tooltip_text = tr("UI_ROAD_REPLAN_TOOLTIP")
	_replan_button.pressed.connect(_on_replan_pressed)
	row.add_child(_replan_button)

	# Emir paneli artık kapalı başlıyor ve bu düğmeyle açılıp kapanıyor
	# (bkz. _build_orders_panel) - sürekli açık kalan hali dar ekranda ve
	# dikeyde kervanın kendisini kapatıyordu (bkz. `set_safe_left`'in
	# kendi notu). Kontrol-2'nin "her zaman görünen panel" kararının
	# tersi, ama aynı kuralın (her kararın görünür bir kontrolü var) bir
	# başka okunuşu: panelin kendisi artık o kontrol, düğme onu açıp
	# kapatan kontrol.
	_orders_button = Button.new()
	_orders_button.text = tr("UI_ROAD_ORDERS_OPEN")
	_orders_button.tooltip_text = tr("UI_ROAD_ORDERS_TOOLTIP")
	_orders_button.toggle_mode = true
	_orders_button.toggled.connect(_on_orders_toggled)
	row.add_child(_orders_button)

	# Playtest: *"status, map, inventory, my contracts gibi"* düğmeler.
	# Dördü de aynı soruyu soruyor - kervan ne durumda - ve cevabı tek bir
	# dökümde duruyor (bkz. CaravanStatusPanel). Dört ayrı ekran, bir
	# ekranın dört sekmesi kadar bile bilgi vermezdi.
	_status_button = Button.new()
	_status_button.text = tr("UI_STATUS_OPEN")
	_status_button.tooltip_text = tr("UI_STATUS_TOOLTIP")
	_status_button.toggle_mode = true
	_status_button.toggled.connect(_on_status_toggled)
	row.add_child(_status_button)

	# Aynı kısayol, aynı katman şeklinde şehirde de açılıyor (bkz.
	# city_map.gd'nin `_show_help`'i) - playtest'in *"kesinlikle bir
	# kısayol tuşuyla"* isteği ekrana bağlı değil.
	_help_button = Button.new()
	_help_button.text = tr("UI_HELP_OPEN")
	_help_button.tooltip_text = tr("UI_HELP_TOOLTIP")
	_help_button.pressed.connect(_show_help)
	row.add_child(_help_button)

	# Defterin tamamı: yardım katmanı gibi bir okuma, zamanı durdurmuyor.
	var waybook_button := Button.new()
	waybook_button.text = tr("UI_WAYBOOK_OPEN")
	waybook_button.pressed.connect(_show_waybook)
	row.add_child(waybook_button)

	_log_button = Button.new()
	_log_button.text = tr("EVT_TEST_LOG")
	_log_button.toggle_mode = true
	_log_button.toggled.connect(_on_log_toggled)
	row.add_child(_log_button)

	# Varış artık mesafe kapanır kapanmaz beliriyor (bkz. _walk_at) -
	# oyuncu görünmez bir duvara dayanıp beklemiyor.
	_arrive_button = Button.new()
	_arrive_button.text = tr("UI_ROAD_ARRIVE")
	_arrive_button.visible = false
	_arrive_button.pressed.connect(_on_arrive_pressed)
	row.add_child(_arrive_button)

	# Çıkış her zaman görünür ve hiçbir kaydırma kutusunun içinde değil
	# (bkz. World Navigation Rules). Hedefi seferin canlı olup olmamasına
	# göre _refresh_exit_button() belirler.
	_exit_button = Button.new()
	_exit_button.pressed.connect(_on_back_pressed)
	row.add_child(_exit_button)

	return bar

## Kararların katmanı: olay kartı, pazarlık, tayfa teklifi, rota değişimi
## ve varış özeti. Hepsi ekranın ortasında **tek** bir çerçevede açılıyor;
## EU4'ün olay kartı tam olarak bu - dünyayı karartıp önüne bir kart
## koymak, kartın seçeneklerini de kartın içine almak.
func _build_modal_layer() -> void:
	var frame := PanelContainer.new()
	frame.theme_type_variation = WaybookTheme.SEAL_PANEL
	frame.custom_minimum_size = Vector2(CARD_WIDTH, 0.0)
	_modal_center.add_child(frame)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	frame.add_child(column)

	_card_panel = VBoxContainer.new()
	_card_panel.add_theme_constant_override("separation", 8)
	column.add_child(_card_panel)

	_haggle_holder = VBoxContainer.new()
	column.add_child(_haggle_holder)

	_recruit_holder = VBoxContainer.new()
	_recruit_holder.add_theme_constant_override("separation", 6)
	column.add_child(_recruit_holder)

	_replan_holder = VBoxContainer.new()
	_replan_holder.add_theme_constant_override("separation", 4)
	column.add_child(_replan_holder)

	_debt_holder = VBoxContainer.new()
	_debt_holder.add_theme_constant_override("separation", 6)
	column.add_child(_debt_holder)

	_arrival_panel = VBoxContainer.new()
	_arrival_panel.add_theme_constant_override("separation", 4)
	column.add_child(_arrival_panel)

	_enter_city_button = Button.new()
	_enter_city_button.text = tr("UI_ROAD_ENTER_CITY")
	_enter_city_button.visible = false
	_enter_city_button.pressed.connect(_on_enter_city_pressed)
	column.add_child(_enter_city_button)

## Kayıt katmanı: bir tuşla açılıyor, listenin kendisi kaydırma kutusunda,
## kapatma tuşu kutunun *dışında* (bkz. World Navigation Rules).
func _build_log_layer() -> void:
	var frame := PanelContainer.new()
	_log_overlay.add_child(frame)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	frame.add_child(column)

	var title := Label.new()
	title.text = tr("EVT_TEST_LOG")
	title.modulate = ArtPalette.GOLD
	column.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)

	_log_list = VBoxContainer.new()
	_log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_log_list)

	var close_button := Button.new()
	close_button.text = tr("UI_CANCEL")
	close_button.pressed.connect(_on_log_closed)
	column.add_child(close_button)

## HUD şeritlerinin ortak çerçevesi - iki şerit iki ayrı stil kurmasın.
func _make_bar() -> PanelContainer:
	var bar := PanelContainer.new()
	bar.theme_type_variation = WaybookTheme.HUD_BAR
	return bar

## Kervanın dökümü: bir tuş, bir katman. Şehre girmek ya da sahne
## değiştirmek gerekmiyor - yol yürümeye devam ediyor, oyuncu üstüne
## bakıyor. Kapatma tuşu kaydırma kutusunun dışında (bkz. `setup`).
func _build_status_layer() -> void:
	var frame := PanelContainer.new()
	_status_overlay.add_child(frame)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	frame.add_child(column)

	_status_panel = CaravanStatusPanel.new()
	_status_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_status_panel)
	_status_panel.setup(_session)

	var close_button := Button.new()
	close_button.text = tr("UI_CANCEL")
	close_button.pressed.connect(_on_status_closed)
	column.add_child(close_button)

## Döküm **açıldığı anda** tazeleniyor, her karede değil: yol her saniye
## değişiyor ama panel yalnızca bakılırken var.
func _on_status_toggled(pressed: bool) -> void:
	if pressed:
		_status_panel.refresh()
	_status_overlay.visible = pressed

func _on_status_closed() -> void:
	_status_button.button_pressed = false
	_status_overlay.visible = false

## Şehirdekiyle aynı kapı (bkz. city_map.gd'nin `_show_help`'i): bir kereye
## mahsus otomatik gösterimin bayrağına dokunmadan, isteğe bağlı yeniden
## açılıyor. Zamanı durdurmuyor - bu bir okuma, bir karar değil, log ve
## durum katmanlarıyla aynı muamele (bkz. `_can_time_flow`).
const WAYBOOK_KEY: Key = KEY_L

func _show_waybook() -> void:
	for child in get_children():
		if child is WaybookPanel:
			return
	add_child(WaybookPanel.new().setup(_session))

func _show_help() -> void:
	for child in get_children():
		if child is OnboardingPanel:
			return
	add_child(OnboardingPanel.new())

func _on_log_toggled(pressed: bool) -> void:
	_log_overlay.visible = pressed

func _on_log_closed() -> void:
	_log_button.button_pressed = false
	_log_overlay.visible = false

## Ortadaki kart yalnızca içinde bir şey varken görünüyor. Görünürlüğü her
## karede *içerikten* okumak, onu açıp kapatan yedi ayrı çağrı yerinin
## birini unutmaktan daha güvenli - unutulan bir tanesi ekranı karartıp
## boş bir kart bırakırdı.
func _refresh_modal() -> void:
	var open := (
		_card_panel.get_child_count() > 0
		or _haggle_holder.get_child_count() > 0
		or _recruit_holder.get_child_count() > 0
		or _replan_holder.get_child_count() > 0
		or _debt_holder.get_child_count() > 0
		or _arrival_panel.get_child_count() > 0
	)
	# Boş bir `VBoxContainer` bile ayırıcı boşluk üretiyor: beş boş
	# taşıyıcı kartın altına görünür bir boşluk ekliyordu. Gizli çocuk
	# yer kaplamıyor.
	_card_panel.visible = _card_panel.get_child_count() > 0
	_haggle_holder.visible = _haggle_holder.get_child_count() > 0
	_recruit_holder.visible = _recruit_holder.get_child_count() > 0
	_replan_holder.visible = _replan_holder.get_child_count() > 0
	_debt_holder.visible = _debt_holder.get_child_count() > 0
	_arrival_panel.visible = _arrival_panel.get_child_count() > 0

	if open == _modal_open:
		return
	_modal_open = open
	_modal.visible = open

## Emirler tek yerde tanımlı: hem düğmeler hem tuş eşlemesi buradan
## okunuyor, yoksa ekranda yazan sayı ile işe yarayan sayı ayrışır. İlk
## dördü tempo, sırası yavaştan hızlıya - döngü tuşu da bu sırayı izliyor.
const COMMANDS: Array[Dictionary] = [
	{"key": "UI_ROAD_CMD_HALT", "pace": PACE_HALT, "pace_key": "UI_ROAD_PACE_HALT", "short": "UI_ROAD_ORDER_HALT"},
	{"key": "UI_ROAD_CMD_SLOW", "pace": PACE_SLOW, "pace_key": "UI_ROAD_PACE_SLOW", "short": "UI_ROAD_ORDER_SLOW"},
	{"key": "UI_ROAD_CMD_MARCH", "pace": PACE_STEADY, "pace_key": "UI_ROAD_PACE_STEADY", "short": "UI_ROAD_ORDER_STEADY"},
	{"key": "UI_ROAD_CMD_FAST", "pace": PACE_FAST, "pace_key": "UI_ROAD_PACE_FAST", "short": "UI_ROAD_ORDER_FAST"},
	{"key": "UI_ROAD_CMD_TALK_MERCHANT", "pace": -2.0, "pace_key": "", "short": "UI_ROAD_CMD_TALK_MERCHANT"},
	{"key": "UI_ROAD_CMD_DEBT", "pace": -3.0, "pace_key": "", "short": "UI_ROAD_CMD_DEBT"},
]
const PACE_COMMAND_COUNT: int = 4
## Sofra emrinin düğmede ve kayıtta kısa adı.
const MEAL_POLICY_LABELS: Dictionary = {
	GameSession.MEAL_MODE_ALL: "UI_MEAL_POLICY_ALL",
	GameSession.MEAL_MODE_PARTY_ONLY: "UI_MEAL_POLICY_PARTY",
	GameSession.MEAL_MODE_CREW_ONLY: "UI_MEAL_POLICY_CREW",
	GameSession.MEAL_MODE_SPECIFIC: "UI_MEAL_POLICY_SPECIFIC",
	GameSession.MEAL_MODE_SELF_ONLY: "UI_MEAL_POLICY_SELF",
}

## Panel artık `_orders_layer`'ın (bir Container değil, düz bir `Control`)
## çocuğu - Container yönetimindeyken `.position` elle değiştirilemiyordu,
## sürüklemenin ön şartı bu. `_command_panel` alanına atanıyor, hiçbir yere
## `add_child` edilerek döndürülmüyor: çağıran (_build_hud_layer) tek yaptığı
## bunu çağırmak.
## Panelin sürüklenebilir hale gelmesiyle genişliği kervanın önünü kapatan
## asıl değişken oldu (bkz. `_sync_orders_panel_safe_left()`), o yüzden
## gövdesi mümkün olduğunca dar: dört tempo düğmesi tek sırada değil 2x2
## ızgarada, ve zemin `HUD_BAR`'ın kendi yarı saydamlığından da bir adım
## daha saydam - panel dünyanın üstünde asılı duran ince bir katman
## olarak okunsun, opak bir kutu değil.
const ORDERS_PANEL_ALPHA: float = 0.58

func _build_orders_panel() -> void:
	_command_panel = PanelContainer.new()
	_command_panel.theme_type_variation = WaybookTheme.HUD_BAR
	var bg := ArtPalette.UI_HUD_BAR
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(bg.r, bg.g, bg.b, ORDERS_PANEL_ALPHA)
	panel_style.set_content_margin_all(6)
	_command_panel.add_theme_stylebox_override("panel", panel_style)
	_command_panel.visible = false

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	_command_panel.add_child(column)

	var title := Label.new()
	title.text = tr("UI_ROAD_COMMANDS_TITLE")
	title.modulate = ArtPalette.GOLD
	# Başlık aynı zamanda sürükleme tutamacı. Label varsayılan olarak
	# MOUSE_FILTER_IGNORE ile geliyor - STOP olmadan `gui_input` hiç
	# tetiklenmez ve sürükleme hiçbir zaman başlamaz.
	title.mouse_filter = Control.MOUSE_FILTER_STOP
	title.gui_input.connect(_on_orders_title_gui_input)
	column.add_child(title)

	# Tempo tek bir seçim: dört düğme, biri hep basılı. ButtonGroup basılı
	# olanı kendisi bırakıyor, ekran ayrıca bir "hangisi seçili" tutmuyor.
	# 2x2 ızgara - tek sıradaki dört düğme panelin genişliğini kervanın
	# önünü kapatacak kadar büyütüyordu (bkz. `_sync_orders_panel_safe_left`).
	var pace_row := GridContainer.new()
	pace_row.columns = 2
	pace_row.add_theme_constant_override("h_separation", 4)
	pace_row.add_theme_constant_override("v_separation", 4)
	column.add_child(pace_row)
	var group := ButtonGroup.new()
	_pace_buttons.clear()
	for index in PACE_COMMAND_COUNT:
		var button := Button.new()
		button.theme_type_variation = WaybookTheme.HUD_GHOST_BUTTON
		button.toggle_mode = true
		button.button_group = group
		button.text = tr(String(COMMANDS[index].short))
		button.tooltip_text = "%s (%d)" % [tr(String(COMMANDS[index].key)), index + 1]
		button.pressed.connect(_issue_command.bind(index))
		pace_row.add_child(button)
		_pace_buttons.append(button)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 4)
	column.add_child(action_row)
	_talk_merchant_button = Button.new()
	_talk_merchant_button.theme_type_variation = WaybookTheme.HUD_GHOST_BUTTON
	_talk_merchant_button.text = tr("UI_ROAD_ORDER_MERCHANT")
	_talk_merchant_button.pressed.connect(_issue_command.bind(PACE_COMMAND_COUNT))
	action_row.add_child(_talk_merchant_button)
	_debt_button = Button.new()
	_debt_button.theme_type_variation = WaybookTheme.HUD_GHOST_BUTTON
	_debt_button.text = tr("UI_ROAD_ORDER_DEBT")
	_debt_button.tooltip_text = "%s (%d)" % [tr("UI_ROAD_CMD_DEBT"), PACE_COMMAND_COUNT + 2]
	_debt_button.pressed.connect(_issue_command.bind(PACE_COMMAND_COUNT + 1))
	action_row.add_child(_debt_button)

	# Kalıcı emirler: bir kez verilip hatırlanıyor (bkz. GameSession'daki
	# "Kalıcı emirler" notu). Sofra düğmesi emri değiştiriyor, yemeği
	# dağıtmıyor; akşam kampı bir anahtar.
	var standing_row := HBoxContainer.new()
	standing_row.add_theme_constant_override("separation", 4)
	column.add_child(standing_row)
	_meal_policy_button = Button.new()
	_meal_policy_button.theme_type_variation = WaybookTheme.HUD_GHOST_BUTTON
	_meal_policy_button.text = tr("UI_ROAD_ORDER_MEAL")
	_meal_policy_button.tooltip_text = tr("UI_ROAD_ORDER_MEAL_TOOLTIP")
	_meal_policy_button.pressed.connect(_open_meal_policy_panel)
	standing_row.add_child(_meal_policy_button)
	_camp_order_button = Button.new()
	_camp_order_button.theme_type_variation = WaybookTheme.HUD_GHOST_BUTTON
	_camp_order_button.text = tr("UI_ROAD_ORDER_CAMP_DUSK")
	_camp_order_button.tooltip_text = tr("UI_ROAD_ORDER_CAMP_DUSK_TOOLTIP")
	_camp_order_button.toggle_mode = true
	_camp_order_button.toggled.connect(_on_camp_order_toggled)
	standing_row.add_child(_camp_order_button)

	_orders_layer.add_child(_command_panel)

## Başlığa basılı tutmak paneli sürüklemeye başlatır/bitirir - gerçek hareket
## `_input()`'ta izleniyor, çünkü sürüklenen fare kolayca başlığın kendi
## sınırlarının dışına çıkar ve `gui_input` orada artık tetiklenmez.
func _on_orders_title_gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_orders_dragging = true
		_orders_positioned = true
		_orders_drag_offset = _command_panel.position - get_global_mouse_position()
	else:
		_orders_dragging = false

## Panel `_orders_layer`'ın dışına hiç çıkmasın - dışarı sürüklenen bir panel
## kapatma düğmesine bile erişilemez hale gelirdi.
func _clamp_orders_position(pos: Vector2) -> Vector2:
	if _orders_layer == null or _command_panel == null:
		return pos
	var max_pos := _orders_layer.size - _command_panel.size
	return Vector2(
		clampf(pos.x, 0.0, maxf(0.0, max_pos.x)),
		clampf(pos.y, 0.0, maxf(0.0, max_pos.y)),
	)

## Panel ilk kez açıldığında eski, hep-açık halinin durduğu köşeye yakın bir
## yerde beliriyor - alt şeridin gerçek yüksekliği (dinamik) `_hud`'un son
## çocuğundan okunuyor, sabit bir sayı tahmin edilmiyor.
func _default_orders_position() -> Vector2:
	var margin := ORDERS_PANEL_SAFE_MARGIN
	if _orders_layer == null or _command_panel == null:
		return Vector2(margin, margin)
	var bottom_height := STRAP_HEIGHT
	if _hud != null and _hud.get_child_count() > 0:
		var bottom := _hud.get_child(_hud.get_child_count() - 1) as Control
		if bottom != null:
			bottom_height = bottom.size.y
	var y := _orders_layer.size.y - bottom_height - STRAP_HEIGHT - _command_panel.size.y - margin
	return Vector2(margin, maxf(margin, y))

## Emir paneli açılıp kapanır (bkz. `_orders_button`) - sürüklenmiş bir
## paneli her açılışta sıfırlamıyor, yalnızca hiç konumlanmamışsa
## varsayılana yerleşiyor.
func _on_orders_toggled(pressed: bool) -> void:
	_orders_open = pressed
	if pressed and _command_panel != null:
		_command_panel.reset_size()
		if _orders_positioned:
			_command_panel.position = _clamp_orders_position(_command_panel.position)
		else:
			_command_panel.position = _default_orders_position()
			_orders_positioned = true
	_refresh_command_panel()
	_sync_orders_panel_safe_left()

## Tempo düğmeleri tempoyu *gösteriyor* da: tempo yalnızca düğmeyle
## değişmiyor (dayanıklılık bitince kervan kendi normale dönüyor, kaydın
## yüklenmesi), o yüzden basılı düğme her karede tempodan okunuyor.
## Hızlanamayan kervanın "Hızlı"sı kilitli, sebebi yanında - saklanmıyor.
func _refresh_command_panel() -> void:
	if _pace_buttons.is_empty():
		return
	# Panel yalnızca oyuncu düğmeyle açtıysa görünür - ve savaş yolun
	# yerini alınca (band gizlenince) onun üstünde durmamalı.
	_command_panel.visible = _orders_open and _band.visible
	for index in PACE_COMMAND_COUNT:
		var selected := is_equal_approx(_pace, float(COMMANDS[index].pace))
		if _pace_buttons[index].button_pressed != selected:
			_pace_buttons[index].set_pressed_no_signal(selected)
	var fast := _pace_buttons[PACE_COMMAND_COUNT - 1]
	var can_push := _session == null or _session.caravan.can_push() or is_equal_approx(_pace, PACE_FAST)
	for index in PACE_COMMAND_COUNT - 1:
		_pace_buttons[index].disabled = not _orders_enabled
	fast.disabled = not can_push or not _orders_enabled
	if _debt_button != null:
		_debt_button.disabled = not _orders_enabled
	fast.tooltip_text = (
		"%s (%d)" % [tr("UI_ROAD_CMD_FAST"), PACE_COMMAND_COUNT]
		if can_push else tr("UI_ROAD_ORDER_FAST_LOCKED")
	)
	_meal_policy_button.disabled = not _orders_enabled
	if _session != null:
		_meal_policy_button.text = "%s: %s" % [
			tr("UI_ROAD_ORDER_MEAL"),
			tr(MEAL_POLICY_LABELS.get(_session.meal_policy_mode, "UI_MEAL_POLICY_ALL")),
		]
		if _camp_order_button.button_pressed != _session.standing_camp_at_dusk:
			_camp_order_button.set_pressed_no_signal(_session.standing_camp_at_dusk)
	_refresh_talk_merchant_row()

## Eskort tüccarı yoksa düğme kilitli ama sebebiyle birlikte görünüyor -
## kilitli olay seçimi/ekipman/vagon satışıyla aynı kural.
func _refresh_talk_merchant_row() -> void:
	if _talk_merchant_button == null or _session == null:
		return
	var locked := _session.caravan.merchant_names.is_empty()
	_talk_merchant_button.disabled = locked or not _orders_enabled
	_talk_merchant_button.tooltip_text = (
		tr("UI_ROAD_CMD_TALK_MERCHANT_LOCKED") if locked
		else "%s (%d)" % [tr("UI_ROAD_CMD_TALK_MERCHANT"), PACE_COMMAND_COUNT + 1]
	)

## Kısayollar: 1-6 emirler, F2 tempoyu bir üst kademeye çeviriyor (kumandada
## LB). Hepsinin ekranda bir düğmesi var - tuş yalnızca kestirme.
func _input(event: InputEvent) -> void:
	if _orders_dragging:
		# Fare sürüklenirken tutamacın (başlığın) sınırlarını kolayca aşar -
		# `gui_input` orada artık tetiklenmediği için hareketi burada, tüm
		# ekranın girdisinde izliyoruz, tıpkı bırakmayı da.
		var motion := event as InputEventMouseMotion
		if motion != null:
			_command_panel.position = _clamp_orders_position(
				get_global_mouse_position() + _orders_drag_offset
			)
			_sync_orders_panel_safe_left()
			return
		var release := event as InputEventMouseButton
		if release != null and release.button_index == MOUSE_BUTTON_LEFT and not release.pressed:
			_orders_dragging = false
			return

	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == PACE_CYCLE_KEY:
		if _orders_accept_input():
			_cycle_pace()
		accept_event()
		return

	# Tab: kervanın dökümü - bir tuşla açılıp kapanan bir katman.
	if key_event.keycode == KEY_TAB:
		_status_button.button_pressed = not _status_button.button_pressed
		accept_event()
		return

	if key_event.keycode == KEY_F3:
		_show_help()
		accept_event()
		return

	if key_event.keycode == WAYBOOK_KEY:
		_show_waybook()
		accept_event()
		return

	if key_event.keycode == KEY_ESCAPE:
		# Başka bir panel (olay kartı, savaş, pazarlık, tayfa teklifi,
		# yeniden planlama) açık değilken Esc oyun içi menüyü açar - bkz.
		# InGameMenu.
		if _in_game_menu == null and _current_event == null and not _has_open_panel():
			_open_in_game_menu()
			accept_event()
		return

	var index := key_event.keycode - KEY_1
	if index >= 0 and index < COMMANDS.size() and _orders_accept_input():
		_issue_command(index)
		accept_event()

## Düğmeler kilitliyse kısayol da kilitli: aynı emrin iki kapısı ayrı
## kurallara uymamalı.
func _orders_accept_input() -> bool:
	return _command_panel != null and _command_panel.visible and _orders_enabled

func _cycle_pace() -> void:
	var current := 0
	for index in PACE_COMMAND_COUNT:
		if is_equal_approx(_pace, float(COMMANDS[index].pace)):
			current = index
	var next := (current + 1) % PACE_COMMAND_COUNT
	if _pace_buttons[next].disabled:
		next = 0
	_issue_command(next)

func _issue_command(index: int) -> void:
	var command: Dictionary = COMMANDS[index]
	var pace := float(command.pace)
	if is_equal_approx(pace, -2.0):
		if not _talk_merchant_button.disabled:
			_open_merchant_dialogue()
		return
	if is_equal_approx(pace, -3.0):
		_open_debt_panel()
		return
	if index < PACE_COMMAND_COUNT and _pace_buttons[index].disabled:
		return
	if is_equal_approx(_pace, pace):
		_refresh_command_panel()
		return
	_pace = pace
	_pace_key = String(command.pace_key)
	_add_log(tr("UI_ROAD_CMD_ISSUED") % tr(String(command.key)), OUTCOME_COLOR)
	_refresh_command_panel()

func _init_journey() -> void:
	var live_session: GameSession = GameState.get_session()
	# Her sefer taze bir controller ile başlar; sefer ortası kaydından
	# gelindiyse aşağıda kaydın durumuyla doldurulur.
	_journey = JourneyController.new()

	if live_session.is_journey_active():
		_is_live_journey = true
		_session = live_session
		_current_day = maxi(0, _session.journey_total_days - _session.journey_days_remaining)
		_reset_button.visible = false
		_seed_spin.editable = false
	else:
		_is_live_journey = false
		_start_synthetic_journey()

	# Tohum kutusu yalnızca sentetik seferi tekrarlanabilir kılmak için var.
	# Canlı seferde de onun değeri (sabit 1234) kullanılıyordu, yani gerçek
	# oyunda *her sefer aynı olay dizisini* çekiyordu - yol kendini tekrar
	# ediyordu ve sebebi bir geliştirici kutusuydu. Canlı sefer artık
	# hedeften ve geçen günden tohum alıyor: aynı kaydı yeniden yükleyen
	# oyuncu aynı yolu bulur (sefer ortası kaydı zarın *durumunu* taşıyor,
	# tohumunu değil - bkz. EventEngine.to_dict - o yüzden bu bir yeniden-zar
	# atma kapısı açmıyor), ama her yeni sefer başka bir yoldur.
	_dev_row.visible = not _is_live_journey
	var engine_seed := int(_seed_spin.value)
	if _is_live_journey:
		engine_seed = hash("%s|%s|%d" % [
			_session.journey_origin_id,
			_session.journey_destination_id,
			_session.total_days_elapsed,
		])

	_refresh_exit_button()
	_engine = EventEngine.new(EventCatalog.get_road_events(), engine_seed)
	_current_event = null
	_journey_finished = false

	# Durum paneli `_build_ui()` sırasında kuruldu, ama o an henüz gerçek
	# oturum yoktu (`_session` burada ilk kez atanıyor) - panel de sessizce
	# boş kaldı. Gerçek oturum eldeyken şimdi dolduruluyor.
	_status_panel.set_session(_session)

	# Saat sefer başına sıfırlanır: gün sayısı ve evre buradan akar.
	_clock = JourneyClock.new()
	_journey_length_days = maxi(1, _session.journey_total_days)
	_days_covered = float(_current_day)
	_walk_direction = 0.0
	_camping = false
	_band.set_camping(false)
	_caravan.set_camping(false)

	# Yolun coğrafyası: planlayıcı hangi araziyi gösterdiyse yolda o
	# görünüyor, çünkü ikisi de aynı `route_key`'den hesaplanıyor. Sentetik
	# seferde iki uç da aynı şehir; anahtar yine tutarlı çıkıyor.
	_route_key = RouteConditions.route_key(
		_session.journey_origin_id, _session.journey_destination_id
	)
	_terrain = RouteTerrain.build(_route_key, _journey_length_days)
	_band.set_route(_terrain)
	_pace = PACE_STEADY
	_pace_key = "UI_ROAD_PACE_STEADY"
	_leader_offset = 0.0
	_has_leader_target = false
	_attention_zone = RoadAttention.ZONE_FRONT
	_signals.clear()
	_signal_danger_bonus = 0.0
	# İşaretler seferin kendi tohumundan: aynı kaydı yeniden yükleyen
	# oyuncu aynı yolu bulsun (bkz. Route Rules'un aynı gerekçesi).
	_signal_rng.seed = hash("%s|%s|signals" % [
		_session.journey_origin_id, _session.journey_destination_id
	])
	_refresh_command_panel()
	_refresh_weather()

	# Kervan parti ve vagon sayısından kuruluyor; bu yüzden sefer başında
	# bir kez (yolda bir yoldaş katılırsa yine) çağrılıyor, karede değil.
	_caravan.configure(_session)
	_caravan.set_leader_offset(0.0)
	_clear_children(_card_panel)
	_clear_children(_haggle_holder)
	_clear_children(_combat_holder)
	_combat_holder.visible = false
	_band.visible = true
	_clear_children(_recruit_holder)
	_clear_children(_arrival_panel)
	_pending_event = null
	_clear_encounter()
	_arrive_button.visible = false
	_enter_city_button.visible = false
	_set_journey_controls_enabled(true)

	if _is_live_journey and not _session.journey_snapshot.is_empty():
		_restore_journey_snapshot()
		return

	_refresh_state()

	if _is_live_journey:
		var destination := WorldMapData.get_location_by_id(_session.journey_destination_id)
		var destination_name := "?" if destination == null else destination.location_name
		_add_log(tr("UI_ROAD_DEPART") % [
			destination_name,
			_session.journey_days_remaining,
			int(_session.danger_level * 100.0),
		])
	else:
		_add_log(tr("UI_ROAD_SYNTHETIC") % [
			_session.journey_days_remaining,
			int(_session.danger_level * 100.0),
		])

## Sefer ortası kaydından dönüş: saat, mesafe, tempo, kamp, olay motoru ve
## yolda bekleyen karşılaşma kayıttan okunur (bkz. JourneyController).
## Arazi ve hava zaten tohumdan hesaplandığı için yeniden yazılmıyor.
func _restore_journey_snapshot() -> void:
	_journey.load_from_dict(_session.journey_snapshot, EventCatalog.get_road_events())
	_session.journey_snapshot = {}
	_sync_days_remaining()
	_refresh_weather()
	_band.set_camping(_camping)
	_caravan.set_camping(_camping)
	if _pending_event != null:
		var kind: String = EVENT_ROAD_MARKER_KIND.get(_pending_event.event_id, "")
		if kind.is_empty():
			var event := _pending_event
			_pending_event = null
			_present_event(event)
		else:
			_spawn_encounter(kind)
	_refresh_state()
	var destination := WorldMapData.get_location_by_id(_session.journey_destination_id)
	_add_log(tr("UI_ROAD_RESUMED") % [
		"?" if destination == null else destination.location_name,
		_session.journey_days_remaining,
	])

## Sefer ortası otomatik kaydı. Yalnızca sakin bir anda alınır: açık bir
## kart, savaş, pazarlık ya da karar paneli varken değil - yüklenen bir kayıt
## yarım kalmış bir kararın ortasına düşmesin, ve bir kararı yeniden
## denemek için kayıt yüklemek bir kapı olmasın. Günün kararı (sofra ve
## günün olayı) çözüldükten sonra çağrılıyor, yani fiilen günde bir kez.
func _autosave_journey() -> void:
	if not _is_live_journey or _journey_finished or _current_event != null or _has_open_panel():
		return
	_session.journey_snapshot = _journey.to_dict()
	SaveManager.save_session(_session)
	_session.journey_snapshot = {}

func _start_synthetic_journey() -> void:
	_session = GameSession.new()
	_session.journey_destination_id = WorldMapData.START_LOCATION_ID
	_session.journey_total_days = SYNTHETIC_JOURNEY_DAYS
	_session.journey_days_remaining = SYNTHETIC_JOURNEY_DAYS
	_session.danger_level = SYNTHETIC_DANGER
	_session.caravan.wagon_count = SYNTHETIC_WAGONS
	_session.caravan.documents = SYNTHETIC_WAGONS

	var merchants: Array[String] = []
	for index in SYNTHETIC_MERCHANT_COUNT:
		merchants.append(tr("UI_ROAD_SYNTHETIC_MERCHANT") % (index + 1))
	_session.caravan.merchant_names = merchants

	# Dev seferinde savaşı denemek için dolu bir kadro kurulur; gerçek
	# oyunda parti karakter oluşturma ve tayfa toplamayla büyür.
	var test_party: Array[CharacterData] = []
	for index in SYNTHETIC_PARTY_CULTURES.size():
		var culture := CultureCatalog.get_culture_or_default(SYNTHETIC_PARTY_CULTURES[index])
		test_party.append(CharacterData.create(
			culture.name_pool[index % culture.name_pool.size()],
			culture.culture_id,
			CharacterStats.new()
		))
	_session.party = test_party

	_current_day = 0

func _on_reset_pressed() -> void:
	if _is_live_journey:
		return
	_clear_children(_log_list)
	_init_journey()

## Zaman akıyor: her karede saat ilerler, dolan her gün için günlük mekanik
## (erzak, kontrat, olay) bir kez işler. Bir karede birden fazla gün
## geçebilir (3x hızda ya da uzun bir olaydan sonra), o yüzden döngü.
##
## Ortada çözülmemiş bir olay ya da açık bir panel varsa zaman durur -
## oyuncu karar verirken kervan yol almamalı.
func _process(delta: float) -> void:
	if _clock == null:
		return
	_apply_zoom(delta)

	if _can_time_flow():
		var hours := _clock.advance(delta)
		_advance_position(hours)
		_tick_signals(hours)
		_process_elapsed_days()
		_update_camp_state()
	else:
		_walk_direction = 0.0

	_refresh_time_ui()
	_refresh_modal()

## Kervan tempoyla kendi yürür; giriş yalnızca lideri kolon içinde
## gezdirir (bkz. yukarıdaki "Yürümek" notu). Kampta kervan durur, lider
## yine gezebilir.
##
## Mesafe geçen oyun saatinden ölçülüyor, gerçek kareden değil: hız tuşu
## (0.5x-3x) hem saati hem yolu aynı oranda hızlandırır, yoksa hızlı akışta
## günler yola göre daha hızlı akar ve kervan hep aç kalırdı.
func _advance_position(hours: float) -> void:
	_walk_direction = 0.0
	if hours <= 0.0:
		return
	_move_leader(hours)
	if _camping:
		return
	_walk_at(_pace, hours)

## Klavye/kumanda yönü dokunma hedefinden önce gelir: ikisi aynı anda
## verilirse eldeki tuş kazanır ve hedef unutulur.
func _move_leader(hours: float) -> void:
	var direction := 0.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction -= 1.0
	direction = clampf(direction + GamepadCursor.get_move_axis(), -1.0, 1.0)

	var step := LEADER_WALK_SPEED * hours
	var target := _leader_offset
	if not is_zero_approx(direction):
		_has_leader_target = false
		target = _leader_offset + direction * step
	elif _has_leader_target:
		target = move_toward(_leader_offset, _leader_target, step)
		if is_equal_approx(target, _leader_target):
			_has_leader_target = false
	else:
		return
	_leader_offset = clampf(target, -_caravan.get_column_length(), 0.0)
	_caravan.set_leader_offset(_leader_offset)
	_refresh_attention_zone()

## Kervana dokunmak/tıklamak lideri oraya yürütür. Dünya katmanları fareyi
## yoksaydığı için tıklama buraya ancak hiçbir düğmeye değmediyse düşer.
static func step_zoom_value(current: float, direction: int) -> float:
	return clampf(snappedf(current + ZOOM_STEP * direction, ZOOM_STEP / 2.0), ZOOM_MIN, ZOOM_MAX)

func _step_zoom(direction: int) -> void:
	_zoom_target = step_zoom_value(_zoom_target, direction)

## Tekerlek, trackpad ve iki parmak. Tıklayarak yürümeden önce bakılıyor:
## iki parmakla sıkıştırmak lideri yürütmemeli.
func _handle_zoom_input(event: InputEvent) -> bool:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and (
		mouse.button_index == MOUSE_BUTTON_WHEEL_UP or mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN
	):
		_step_zoom(1 if mouse.button_index == MOUSE_BUTTON_WHEEL_UP else -1)
		return true
	var magnify := event as InputEventMagnifyGesture
	if magnify != null:
		_zoom_target = clampf(_zoom_target * magnify.factor, ZOOM_MIN, ZOOM_MAX)
		return true
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			_pinch_points[touch.index] = touch.position
		else:
			_pinch_points.erase(touch.index)
		_pinch_distance = _current_pinch_distance()
		return _pinch_points.size() >= 2
	var drag := event as InputEventScreenDrag
	if drag != null and _pinch_points.has(drag.index):
		_pinch_points[drag.index] = drag.position
		var distance := _current_pinch_distance()
		if _pinch_distance > 0.0 and distance > 0.0:
			_zoom_target = clampf(_zoom_target * distance / _pinch_distance, ZOOM_MIN, ZOOM_MAX)
		_pinch_distance = distance
		return _pinch_points.size() >= 2
	return false

func _current_pinch_distance() -> float:
	if _pinch_points.size() < 2:
		return 0.0
	var points: Array = _pinch_points.values()
	return (points[0] as Vector2).distance_to(points[1] as Vector2)

## Şerit kendi yerinde ölçekleniyor; merkez liderin başı ve zemin çizgisi.
func _apply_zoom(delta: float) -> void:
	_zoom = lerpf(_zoom, _zoom_target, minf(1.0, ZOOM_EASE * delta))
	if absf(_zoom - _zoom_target) < 0.001:
		_zoom = _zoom_target
	_band.pivot_offset = _caravan.position + Vector2(
		_caravan.get_leader_centre(), _caravan.get_ground_y()
	)
	_band.scale = Vector2(_zoom, _zoom)

func _unhandled_input(event: InputEvent) -> void:
	if _band != null and _band.visible and _handle_zoom_input(event):
		get_viewport().set_input_as_handled()
		return
	var position := Vector2.ZERO
	var mouse := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		position = mouse.position
	elif touch != null and touch.pressed:
		position = touch.position
	else:
		return
	if _clock == null or _current_event != null or _has_open_panel() or not _band.visible:
		return
	var local := _caravan.get_global_transform_with_canvas().affine_inverse() * position
	_leader_target = _caravan.leader_offset_for_x(local.x)
	_has_leader_target = true
	get_viewport().set_input_as_handled()

## Yolun tek yürüme kapısı. Tempo, hava ve kervanın kendi kondisyonu
## burada çarpılıyor - iki ayrı yerde çarpılırsa biri güncellenmeyi
## unutuyor.
##
## Havanın ve kondisyonun yolu yavaşlatması erzak sözünü bozmuyor çünkü
## planlayıcı bu payı önceden istiyor (bkz. CaravanPlan.travel_reserve_days,
## RouteWeather.forecast_extra_days'in condition_factor'ü); tam kondisyonda,
## açık havada ve normal tempoda çarpan tam 1.0, yani eski davranış aynen.
##
## `get_caravan_theoretical_speed()` vagonun yüküyle partinin en yorgun/
## yaralı üyesinin **en yavaşını** okur (bkz. o fonksiyonun kendi notu) -
## kervan en yavaş tekerleğinden ya da en bitkin yolcusundan hızlı gidemez.
## Bu sayı `CaravanOverviewPanel`de zaten gösteriliyordu, sadece
## bilgilendiriciydi; artık gerçek yürüyüşü de belirliyor.
func _walk_at(rate: float, hours: float) -> void:
	if is_zero_approx(rate):
		return
	_walk_direction = signf(rate)
	# Faz 17 PR-6: eğim artık yalnızca çizilen bir yol değil, gerçek bir
	# yavaşlatıcı/hızlandırıcı - RouteWeather.forecast_extra_days() aynı
	# çarpanı planlayıcının erzak payına ekliyor, yoksa tırmanışlı bir
	# rotada "doğru stoklayan asla aç kalmaz" sözü sessizce bozulurdu.
	var terrain_factor := 1.0 if _terrain == null else _terrain.speed_factor_at(_days_covered)
	var effective := JourneyController.effective_rate(
		rate, RouteWeather.pace_multiplier(_weather),
		_session.get_caravan_theoretical_speed(), terrain_factor, _hungry
	)
	_journey.walk(effective, hours)
	_sync_days_remaining()
	_check_pending_event_reached()
	# Varış mesafeyle olur, günle değil - ve **o anda** olmalı. Eskiden
	# yalnızca gün dönerken sınanıyordu: mesafe kapandıktan sonra kervan
	# ilerlemiyor ama hiçbir şey de olmuyordu, yani oyuncu görünmez bir
	# duvara dayanıp bir sonraki günü bekliyordu.
	_check_journey_end()

## Liderin kolondaki oranı -> bölge. Kolona bağlıyken (offset 0) lider
## kolonun başındadır; geriye yürüdükçe vagonlara, sonra kuyruğa geçer.
func _refresh_attention_zone() -> void:
	var column := _caravan.get_column_length()
	var ratio := 0.0 if column <= 0.0 else clampf(-_leader_offset / column, 0.0, 1.0)
	_attention_zone = RoadAttention.zone_for(ratio)

## İşaretler saatle yaşıyor, günle değil - asıl boşluk günlerin arası
## değil, kartlar arasındaki 23 saatti.
func _tick_signals(hours: float) -> void:
	var outcome := _signals.tick(
		hours, _attention_zone, _signal_rng, _session.get_affliction_count()
	)
	for kind in outcome["appeared"]:
		_add_log(tr(RoadSignals.get_notice_key(String(kind))))
	for kind in outcome["resolved"]:
		_add_log(tr(RoadSignals.get_resolved_key(String(kind))), OUTCOME_COLOR)
		_flash_signal_icon(String(kind), ArtPalette.UI_SIGNAL_RESOLVED)
	for kind in outcome["escalated"]:
		_apply_signal_escalation(String(kind))
		_flash_signal_icon(String(kind), ArtPalette.UI_SIGNAL_ESCALATED)
	if _signal_tween == null:
		_refresh_signal_icon()

## Açık işaretlerin ilki, kendi ikonu ve ipucuyla; yoksa ikon gizli.
func _refresh_signal_icon() -> void:
	var kinds := _signals.get_open_kinds()
	_signal_icon.visible = not kinds.is_empty()
	if kinds.is_empty():
		return
	_signal_icon.texture = WaybookTheme.texture(SIGNAL_ICONS[kinds[0]])
	_signal_icon.modulate = Color.WHITE
	_signal_icon.tooltip_text = tr(RoadSignals.get_notice_key(kinds[0]))

## Kapanan bir işaret bir an kendi sonucunun renginde görünüp sönüyor;
## ardından ikon kalan açık işarete dönüyor.
func _flash_signal_icon(kind: String, tint: Color) -> void:
	if _signal_tween != null and _signal_tween.is_valid():
		_signal_tween.kill()
	_signal_icon.texture = WaybookTheme.texture(SIGNAL_ICONS[kind])
	_signal_icon.visible = true
	_signal_icon.modulate = tint
	_signal_tween = create_tween()
	_signal_tween.tween_interval(SIGNAL_FLASH_SECONDS)
	_signal_tween.tween_property(_signal_icon, "modulate:a", 0.0, SIGNAL_FADE_SECONDS)
	_signal_tween.finished.connect(func() -> void:
		_signal_tween = null
		_refresh_signal_icon()
	)

## İhmal edilen işaretin bedeli oyunun kendi diliyle ödeniyor: vagon
## hasarı, stres, tehlike. Yeni bir ceza mekaniği yok.
func _apply_signal_escalation(kind: String) -> void:
	_add_log(tr(RoadSignals.get_escalated_key(kind)), LOCKED_COLOR)
	match kind:
		RoadSignals.KIND_WHEEL:
			_session.caravan.damage_wagons(1)
		RoadSignals.KIND_STRAGGLER:
			_session.change_stress(SIGNAL_STRAGGLER_STRESS)
		RoadSignals.KIND_SMOKE:
			# Duman bir pusunun habercisi: görmezden gelinirse yolun
			# tehlikesi artıyor, yani savaş ihtimali yükseliyor.
			_signal_danger_bonus = minf(
				_signal_danger_bonus + RoadSignals.SMOKE_DANGER_DELTA, SIGNAL_DANGER_CAP
			)
	_refresh_state()

## `journey_days_remaining` artık bağımsız bir sayaç değil, kat edilen
## yoldan türetilen bir gösterge - HUD, sapma maliyeti (get_days_travelled)
## ve varış kontrolü hep aynı mesafeyi okusun diye. Geri yürüyen bir kervan
## için "kalan yol" gerçekten uzar.
func _sync_days_remaining() -> void:
	_journey.sync_days_remaining(_session)

func _can_time_flow() -> bool:
	return not _journey_finished and _current_event == null and not _has_open_panel()

## Günler tek tek alınıyor: bir kart ya da sofra paneli açılınca kalan
## gün saatte **bekler**, kaybolmaz. Eskiden hepsi birden alınıp açık bir
## panelde bırakılıyordu - ve yolda bekleyen bir karşılaşma varken hiç
## işlenmiyordu: işaretin önünde durmak günleri erzaksız geçiriyordu.
## Bekleyen karşılaşma artık günü durdurmuyor, yalnızca o günün yeni bir
## olay çekmesini (bkz. `_on_meal_confirmed`).
func _process_elapsed_days() -> void:
	while not _journey_finished and _current_event == null and not _has_open_panel():
		if not _clock.take_one_day():
			return
		_run_day()

## Gün, yolun değil takvimin birimi: erzak yenir, kontrat süresi işler,
## günün olayı çekilir. Kalan yolu artık burası eksiltmiyor - onu yürümek
## eksiltiyor (bkz. _advance_position). Oyalanan kervan günü de erzağı da
## harcar, mesafeyi kapatmaz; Oregon Trail'in bütün gerilimi bu farkta.
func _run_day() -> void:
	_current_day += 1
	_refresh_weather()
	_apply_daily_pace_and_weather()

	var expired_contracts := _session.advance_day()
	for _merchant_id in expired_contracts:
		_add_log(tr("UI_ROAD_CONTRACT_EXPIRED"))

	# Kalıcı sofra emri: durum değişmediyse (erzak yetiyor, kimse açlığın
	# can aldığı eşikte değil) sofra sorulmadan kurulur. Değiştiyse panel
	# açılır - bir emir kimseyi oyuncunun haberi olmadan öldürmemeli.
	if _session.meal_needs_decision():
		_open_meal_panel()
	else:
		_add_log(tr("UI_ROAD_MEAL_STANDING") % tr(
			MEAL_POLICY_LABELS.get(_session.meal_policy_mode, "UI_MEAL_POLICY_ALL")
		))
		_serve_meal(_session.meal_policy_mode, _session.get_meal_policy_selected())
		_after_meal()

## Emir kipi: yemek dağıtılmıyor, yalnızca kalıcı sofra emri değişiyor.
## Sofra paneliyle aynı ekran - kâseler emrin ne demek olduğunu gösteriyor.
func _open_meal_policy_panel() -> void:
	if _meal_panel != null or not _orders_enabled:
		return
	_meal_panel = MealDistributionPanel.new()
	_meal_panel.confirmed.connect(_on_meal_policy_confirmed)
	_meal_panel.cancelled.connect(_on_meal_policy_cancelled)
	add_child(_meal_panel)
	_meal_panel.setup(_session, true)

func _on_meal_policy_confirmed(mode: String, selected: Array) -> void:
	var typed_selected: Array[CharacterData] = []
	for character in selected:
		typed_selected.append(character)
	_session.set_meal_policy(mode, typed_selected)
	_meal_panel = null
	_add_log(tr("UI_ROAD_CMD_ISSUED") % tr(MEAL_POLICY_LABELS.get(mode, "UI_MEAL_POLICY_ALL")), OUTCOME_COLOR)
	_refresh_command_panel()

func _on_meal_policy_cancelled() -> void:
	_meal_panel = null

func _on_camp_order_toggled(pressed: bool) -> void:
	_session.standing_camp_at_dusk = pressed
	_add_log(tr("UI_ROAD_CAMP_ORDER_ON" if pressed else "UI_ROAD_CAMP_ORDER_OFF"), OUTCOME_COLOR)

## Akşam sofrası artık `_run_day()`'in sessizce uyguladığı bir formül değil,
## oyuncuya sorulan bir karar - `_meal_panel != null` `_has_open_panel()`'e
## girdiği için takvim ve `_check_journey_end()` bu ekranda da durur, tıpkı
## bir olay kartı gibi. Günün olay çekimi karardan *sonra* gelir
## (bkz. `_on_meal_confirmed`), aksi hâlde iki karar aynı anda açılırdı.
func _open_meal_panel() -> void:
	_meal_panel = MealDistributionPanel.new()
	_meal_panel.confirmed.connect(_on_meal_confirmed)
	add_child(_meal_panel)
	# Kamp ateşi bu kararın sahnesi - kervanın mekanik "Kamp Kur" hâli
	# değişmiyor (`_camping` dokunulmuyor), yalnızca görsel ateş+toplanma
	# ödünç alınıyor. Zaten kamp kuruluysa üstüne binmiyoruz.
	if not _camping:
		_band.set_camping(true)
		_caravan.set_camping(true)
	_meal_panel.setup(_session)

func _on_meal_confirmed(mode: String, selected: Array) -> void:
	var typed_selected: Array[CharacterData] = []
	for character in selected:
		typed_selected.append(character)
	# Sofrada verilen karar yeni kalıcı emir olur.
	_session.set_meal_policy(mode, typed_selected)
	_serve_meal(mode, typed_selected)
	_meal_panel = null
	if not _camping:
		_band.set_camping(false)
		_caravan.set_camping(false)
	_after_meal()

func _serve_meal(mode: String, typed_selected: Array[CharacterData]) -> void:
	var result := _session.apply_meal_distribution(mode, typed_selected)
	_hungry = not (result.get("hungry_names", []) as Array).is_empty() or result.get("crew_hungry", false)
	for name_text in (result.get("hungry_names", []) as Array):
		_add_log(tr("UI_ROAD_MEAL_HUNGRY") % name_text, LOCKED_COLOR)
	if result.get("crew_hungry", false):
		_add_log(tr("UI_ROAD_MEAL_CREW_HUNGRY"), LOCKED_COLOR)
	for name_text in (result.get("crew_starved_names", []) as Array):
		_add_log(tr("UI_ROAD_MEAL_CREW_STARVED") % name_text, LOCKED_COLOR)
	var death_outcome: Dictionary = result.get("death_outcome", {})
	if not (death_outcome.get("dead_names", []) as Array).is_empty():
		_handle_death_outcome(death_outcome)

## Sofradan sonra günün geri kalanı: olay çekimi, kayıt.
func _after_meal() -> void:
	var context := _session.build_event_context()
	# Günün durağı olay bağlamına bayrak olarak giriyor (near_shrine,
	# near_hamlet, near_mine...): durak olaylarının ağırlığı ekranda gerçekten
	# o durak geçilirken artıyor - bkz. EventResolver.stop_context.
	var stop: String = RouteTerrain.STOP_NONE if _terrain == null else _terrain.segment_at(_days_covered).stop
	context.merge(EventResolver.stop_context(stop), true)
	# Yolda zaten bir karşılaşma bekliyorsa ikincisi çekilmiyor: iki işaret
	# aynı anda yola dizilmesin, önceki çözülmeden sıradaki gelmesin.
	var event: GameEvent = null if _pending_event != null else _engine.roll_for_day(_current_day, context)
	if event == null and _pending_event != null:
		pass
	elif event == null:
		_add_log(tr("UI_ROAD_DAY_LINE") % [_current_day, tr("EVT_TEST_QUIET_DAY")])
	else:
		_queue_event(event)

	_refresh_state()
	_check_journey_end()
	_autosave_journey()

func _on_speed_pressed() -> void:
	_clock.cycle_speed()
	_refresh_time_ui()

## Kamp bir tuş değil bir durum: ateş yanar, zaman akmaya devam eder,
## süre dolunca kendiliğinden kalkar ve faydası o an uygulanır.
func _update_camp_state() -> void:
	if not _camping or _clock.total_hours < _camp_ends_at_hours:
		return

	var camp_result := _session.make_camp()
	_add_log(
		tr("UI_ROAD_CAMP_STRUCK") % [
			camp_result.provisions_spent, camp_result.stress_relief
		],
		OUTCOME_COLOR
	)
	_camping = false
	_band.set_camping(false)
	_caravan.set_camping(false)
	_refresh_state()

## Hava günden ve rotadan hesaplanıyor, saklanmıyor: aynı kaydı yeniden
## yükleyen oyuncu aynı havayı buluyor (bkz. RouteWeather). Biyom da
## okunuyor, çünkü gölde sis, dağda fırtına daha sık.
func _refresh_weather() -> void:
	var biome := ArtPalette.FALLBACK_BIOME
	if _terrain != null:
		biome = _terrain.biome_at(_days_covered)
	# Gün numarası **yalnızca** `total_days_elapsed + 1`. İlk yazışta
	# `+ _current_day` de ekliyordum ve bu sessiz bir hataydı: `advance_day()`
	# zaten her gün `total_days_elapsed`'i artırıyor, yani ikisini toplamak
	# hava dizisini E+1, E+3, E+5 diye atlatıyordu. Planlayıcının tahmini
	# E+1, E+2, E+3 üzerinden hesaplandığı için hava payı yolda yaşananla
	# örtüşmez ve "doğru stokladım, yine aç kaldım" geri gelirdi.
	_weather = RouteWeather.at(_route_key, _session.total_days_elapsed + 1, biome)
	_band.set_weather(_weather)
	if _caravan != null:
		_caravan.set_weather(_weather)

func _refresh_time_ui() -> void:
	if _clock == null:
		return

	_sync_orders_panel_safe_left()
	var phase := _clock.get_phase()
	_band.set_phase(phase, _clock.get_phase_progress())

	var progress := _get_route_progress()
	_band.set_route_progress(progress, _days_covered)
	_progress_bar.value = progress
	_progress_bar.tooltip_text = tr("UI_ROAD_PROGRESS_TOOLTIP") % int(round(progress * 100.0))
	_position_encounter()

	# Kervan şeritten ışığı ve yürüme hızını alıyor: iki ayrı yerde
	# hesaplanırsa gece kervanı gündüz aydınlatılmış görünür.
	_caravan.set_light(_band.get_light())
	# Bacak fazı da saatin hız çarpanını taşımalı - taşımadığı sürece
	# `_days_covered` (dolayısıyla arka planın `_world_x`'i) 3x'te üç kat
	# hızlı akarken bacaklar hep aynı, sabit hızda sallanıyordu: kervan
	# ekranda kayıyormuş gibi görünüyordu, tempo değişse de değişmese de.
	# `_clock.get_speed()` 1x'te 1.0 olduğu için varsayılan davranış
	# hiç değişmiyor.
	_caravan.set_speed(0.0 if _camping else absf(_walk_direction) * _pace * _clock.get_speed())

	# Metin yalnızca *gösterilen değer* değişince kuruluyor. Buradaki yorum
	# uzun süre bunu vaat ediyordu ama kod her karede string biçimliyor,
	# sonra eskisiyle karşılaştırıyordu - yani tahsisat zaten yapılmış
	# oluyordu. Saat dakikada bir değişir, kare başına değil; Web hedefinde
	# saniyede 180 gereksiz string demekti.
	_time_dial.set_hour(_clock.get_hour_of_day())
	var clock_text := _clock.get_clock_text()
	if clock_text != _last_clock_text or phase != _last_phase:
		_last_clock_text = clock_text
		_last_phase = phase
		_clock_label.text = tr("UI_ROAD_CLOCK") % [
			_current_day + 1, clock_text, tr(JourneyClock.get_phase_key(phase))
		]

	var speed := _clock.get_speed()
	if not is_equal_approx(speed, _last_speed):
		_last_speed = speed
		_speed_button.text = "%sx" % String.num(speed, 1).trim_suffix(".0")

	# Kamp yalnızca hava kararınca anlamlı; gündüz durup ateş yakmak
	# kervanı yavaşlatmaktan başka işe yaramaz.
	_camp_button.disabled = (
		_camping or not _clock.is_camp_time() or not _can_time_flow()
	)
	# Akşam kampı emri: yalnızca akşam evresinde - kamp sekiz saat sürdüğü
	# için bittiğinde gece olur, yani aynı akşam ikinci kez yakılmaz (bir
	# kayıt yüklendikten sonra da). Bir kart ya da panel açıksa bekler.
	if (
		_session.standing_camp_at_dusk and not _camp_button.disabled
		and _clock.get_phase() == JourneyClock.Phase.EVENING
	):
		_on_camp_pressed()

	_refresh_walk_hint()
	_refresh_conditions()
	_refresh_command_panel()

## Kolon panelin altına girmesin diye onun genişliğini her karede
## `TravelBand`/`RoadCaravan`'a bildiriyor. İkisinin de kendi setter'ı
## değişmeyen bir değeri sessizce yok sayıyor, o yüzden her karede
## çağırmak ucuz.
func _sync_orders_panel_safe_left() -> void:
	if _command_panel == null or _band == null or _caravan == null or _orders_layer == null:
		return
	# Panel artık sürüklenebilir - sabit bir sol-alt konum bir varsayım
	# değil. Kervanın önünü yalnızca panel gerçekten ekranın sol yarısında
	# duruyorken kapatır; oyuncu onu sağa/yukarı taşırsa bıraktığı boşluğu
	# kervan geri alır.
	var safe_left := 0.0
	if (
		_command_panel.visible
		and _orders_layer.size.x > 1.0
		and _command_panel.position.x < _orders_layer.size.x * 0.5
	):
		safe_left = _command_panel.position.x + _command_panel.size.x + ORDERS_PANEL_SAFE_MARGIN
	_band.set_safe_left(safe_left)
	_caravan.set_safe_left(safe_left)

## Arazi, hava ve tempo. Hava mekanik olarak yolu yavaşlatıp tehlikeyi
## büyüttüğü için burada yazması şart: görünmeyen bir ceza oyuncu için
## hatadan ayırt edilemez (aynı gerekçe planlayıcının moral dökümünde de
## var).
func _refresh_conditions() -> void:
	var biome := ArtPalette.FALLBACK_BIOME
	if _terrain != null:
		biome = _terrain.biome_at(_days_covered)
	var text := "%s · %s · %s" % [
		tr("UI_ROAD_TERRAIN_NOW") % tr(RouteTerrain.biome_name_key(biome)),
		tr("UI_ROAD_WEATHER") % tr(RouteWeather.name_key(_weather)),
		tr("UI_ROAD_PACE_LABEL") % tr(_pace_key),
	]
	if text == _last_conditions:
		return
	_last_conditions = text
	_conditions_label.text = text
	_conditions_label.tooltip_text = text

## Oyuncunun ne yaptığını ve neyi yapmadığını tek satırda söyler: duran
## kervan "bekliyor" değil, *yol almıyor* - ve bunu görmezse oyuncu ekranın
## bozuk olduğunu sanıyor.
func _refresh_walk_hint() -> void:
	var key := "UI_ROAD_WALK_IDLE"
	if _camping:
		key = "UI_ROAD_WALK_CAMPING"
	elif _walk_direction > 0.0:
		key = "UI_ROAD_WALK_FORWARD"

	var text := tr(key)
	if text == _last_walk_hint:
		return
	_last_walk_hint = text
	_walk_hint.text = text
	# Dar bir şeritte cümle kesilebiliyor - tam metin en azından hover'da
	# okunabiliyor.
	_walk_hint.tooltip_text = text
	_walk_hint.modulate = (
		LOCKED_COLOR if is_zero_approx(_walk_direction) and not _camping else Color.WHITE
	)

func _get_route_progress() -> float:
	if _journey_length_days <= 0:
		return 1.0
	return clampf(_days_covered / float(_journey_length_days), 0.0, 1.0)

## Kamp: günü ilerletir, erzak yer, ama olay çekmez - o günü dinlenerek
## geçirdiğin garanti, karşılığında stres belirgin azalır (bkz.
## GameSession.make_camp). "21. nasıl daha az maliyetli olacaksa" kararı:
## yeni bir gün döngüsü kurmak yerine mevcut gün ilerletme akışını
## paylaşıyor, yalnızca olay çekimini atlayıp kampın kendi payını ekliyor.
func _on_camp_pressed() -> void:
	if _camping or _current_event != null or not _clock.is_camp_time():
		return

	# Kamp anlık bir kazanç değil, geçirilen bir süre: ateş yanar, zaman
	# akmaya devam eder (oyuncu isterse hızlandırır) ve süre dolunca
	# _update_camp_state faydayı uygular. Gün ilerlemesi kendiliğinden
	# olur - saat gece yarısını geçince günlük mekanik zaten işler.
	_camping = true
	_camp_ends_at_hours = _clock.total_hours + CAMP_HOURS
	# Kamp kendi hızını öneriyor: 8 saatlik bir mola 1x'te dakikalarca
	# beklemek demek, oysa kampın kendi görüntüsü (ateş, dinlenen kervan)
	# bu kadar uzun izlenecek bir şey değil. Oyuncu isterse yine
	# değiştirir - bu yalnızca varsayılan, kilit değil.
	_clock.set_speed_index(_clock.camp_speed_index())
	_band.set_camping(true)
	_caravan.set_camping(true)
	_add_log(tr("UI_ROAD_CAMP_LIT"), OUTCOME_COLOR)
	_refresh_state()

## Havanın ve temponun günlük bedeli. Hepsi *zaten var olan* kollardan
## geçiyor - moral ve stres - yani hava ayrı bir hesap defteri açmıyor
## (aynı kural kültür perklerinde de var: hiçbir perk yeni sistem icat
## etmez).
##
## Tehlike kolu da havadan besleniyor ama orada değil: rota tehlikesi
## `GameSession.get_route_danger()` üzerinden okunuyor, bkz. oradaki
## hava deltası.
func _apply_daily_pace_and_weather() -> void:
	var bite := RouteWeather.morale_bite(_weather)
	if bite != 0:
		_session.caravan.change_morale(bite)

	# Tempo artık bir tuş değil harcanan bir kaynak: zorlamak dayanıklılık
	# yakıyor, yakıt bitince kervan kendi kendine normale dönüyor. Yavaş
	# gitmek de bedava değil - takvim yiyor (kontrat, borç, mevsim).
	var pushing := is_equal_approx(_pace, PACE_FAST)
	_session.caravan.apply_stamina_drift(pushing)
	if pushing and not _session.caravan.can_push():
		_pace = PACE_STEADY
		_pace_key = "UI_ROAD_PACE_STEADY"
		_add_log(tr("UI_ROAD_PACE_EXHAUSTED"), LOCKED_COLOR)

	if pushing:
		_session.change_stress(PACE_FAST_STRESS_PER_DAY)
		_session.caravan.change_morale(PACE_FAST_MORALE_PER_DAY)
	elif is_equal_approx(_pace, PACE_SLOW):
		_session.caravan.change_morale(PACE_SLOW_MORALE_PER_DAY)

	# Kuyrukla ilgilenmek günün stres birikimini kesiyor - dikkatin
	# üçüncü ödülü (bkz. RoadAttention).
	var relief := RoadAttention.stress_relief_per_day(_attention_zone)
	if relief > 0:
		_session.change_stress(-relief)

## Havanın tehlike kolu. Delta *başlıktaki paya* uygulanıyor - aynı kural
## `RouteConditions`'ın tehlike deltasında da var (`base + delta * (1-base)`):
## sisli bir yol sessiz yolu gerçekten riskli kılıyor ama zaten ölümcül
## olanı yazı-turaya çevirmiyor.
##
## Saklanan `danger_level`'a *yazmıyoruz*: yazsak her gün üstüne binerdi
## ve on günlük bir sefer sonunda tehlike havadan değil aritmetikten
## yüzde doksana çıkardı.
## Görmezden gelinen dumanın payı da aynı kuralla biniyor: başlıktaki
## paya, toplamın kendisine değil.
func _weathered_danger() -> float:
	var base := _session.danger_level
	var weathered := clampf(
		base + RouteWeather.danger_delta(_weather) * (1.0 - base), 0.0, 1.0
	)
	return clampf(weathered + _signal_danger_bonus * (1.0 - weathered), 0.0, 1.0)

## Olayların etkileri hep buradan geçer. Sebebi tek bir tip: TRAVEL_DAYS
## (`yol +1 gün`) `journey_days_remaining`'e yazıyor, ama o alan artık kat
## edilen yoldan türetiliyor - doğrudan yazılan değer bir sonraki karede
## silinirdi. Fark burada yakalanıp yolun *uzunluğuna* ekleniyor: yol
## gerçekten uzuyor, kervan da onu yürümek zorunda kalıyor.
func _apply_effects(effects: Array[EventEffect]) -> EventEffectApplier.Result:
	var before := _session.journey_days_remaining
	var result := EventEffectApplier.apply(effects, _session)
	var delta := _session.journey_days_remaining - before
	if delta != 0:
		_journey_length_days = maxi(1, _journey_length_days + delta)
	_sync_days_remaining()
	return result

## Günün olayı fiziksel bir karşılığı olan türdense (bkz.
## EVENT_ROAD_MARKER_KIND) kartı hemen açmaz: kervanın biraz önüne yolda
## görünen bir işaret koyar (bkz. RoadEncounter), kartın açılışı
## `_check_pending_event_reached()`'e kalır. Fiziksel karşılığı olmayan bir
## olay (kendi vagonun, hava, parti içi bir mesele) eskisi gibi anında açılır.
func _queue_event(event: GameEvent) -> void:
	var kind: String = EVENT_ROAD_MARKER_KIND.get(event.event_id, "")
	if kind.is_empty():
		_present_event(event)
		return

	_pending_event = event
	# Öndeyken karşılaşma daha uzaktan görünür: işaret daha ileriye
	# konur, yani oyuncunun hazırlanacak (ya da geri dönecek) yolu olur.
	# Savaşın sıklaşmasının dengesi bu - sıklaştırılmış ama kaçınılamayan
	# bir savaş mekanik değil vergidir.
	_pending_event_day_position = minf(
		_days_covered + ENCOUNTER_APPROACH_DAYS
			+ RoadAttention.spot_bonus_days(_attention_zone),
		float(_journey_length_days)
	)
	_spawn_encounter(kind)

func _spawn_encounter(kind: String) -> void:
	_clear_encounter()
	var archetypes: Array = MARKER_ARCHETYPES.get(kind, ["clerk"])
	var archetype: String = archetypes[absi(hash("%d|%s" % [_current_day, kind])) % archetypes.size()]
	_encounter = RoadEncounter.new()
	_encounter.setup(archetype)
	# `add_child` değil `add_actor_layer`: kervanla aynı kuralı okuyor,
	# ön plandaki çalıların arkasına düşmesin diye (bkz. yukarıdaki not).
	_band.add_actor_layer(_encounter)
	_position_encounter()

## Şerit her karede dünyayı kaydırdığı için işaretin ekran konumu da her
## karede yeniden okunmalı - `_refresh_time_ui()`'den çağrılıyor.
func _position_encounter() -> void:
	if _encounter == null:
		return
	_encounter.set_screen_position(_band.screen_position_for_day(_pending_event_day_position))

## İşaretin kartı açtığı nokta kervanın **burnu** - tetik çapaya bağlıyken
## (çapa liderin arkasında, bkz. RoadCaravan.get_front_offset) görevli önce
## liderin yanından geçiyor, kart ancak arkadaki vagona ulaşınca açılıyordu.
## Hesap `JourneyController.has_reached_pending()`'de; burnun gün cinsinden
## payı `_check_pending_event_reached()`'den veriliyor.

func _clear_encounter() -> void:
	if _encounter == null:
		return
	_encounter.queue_free()
	_encounter = null

## Kervan işarete yeterince yaklaştı mı - `_walk_at()`'in her çağrısında
## sınanıyor, çünkü mesafe yalnızca orada ilerliyor. Geriye yürüyen bir
## kervan işaretten uzaklaşır ve hiçbir şey tetiklenmez; tekrar yaklaşınca
## aynı kontrol yine çalışır.
func _check_pending_event_reached() -> void:
	var front_days := 0.0 if _caravan == null else _caravan.get_front_offset() / TravelBand.PIXELS_PER_DAY
	if not _journey.has_reached_pending(front_days):
		return
	var event := _pending_event
	_pending_event = null
	_clear_encounter()
	_present_event(event)

func _present_event(event: GameEvent) -> void:
	_current_event = event
	# Olay arka planda zamandan yer: kervan kartı çözerken duruyor,
	# saat ilerliyor, arka plan da buna göre değişiyor.
	_clock.consume_hours(EVENT_HOURS)
	_engine.mark_fired(event, _current_day)

	_add_log("—— %s" % tr(event.title_key))

	if not event.immediate_effects.is_empty():
		var immediate := _apply_effects(event.immediate_effects)
		_apply_side_channels(immediate)
		for line in immediate.lines:
			_add_log("   %s" % line, IMMEDIATE_COLOR)

	_render_card(event)
	_refresh_state()

func _render_card(event: GameEvent) -> void:
	_clear_children(_card_panel)

	var title := Label.new()
	title.text = tr(event.title_key)
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = ArtPalette.GOLD
	_card_panel.add_child(title)

	# Gövde kaydırma kutusunda, seçenekler **dışında**: uzun bir olay metni
	# seçenekleri kartın altından taşırmasın (bkz. World Navigation
	# Rules'un kaydırma maddesi - orada çıkış tuşu, burada karar tuşları).
	var body_scroll := ScrollContainer.new()
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.custom_minimum_size = Vector2(0.0, 0.0)
	_card_panel.add_child(body_scroll)

	var body := Label.new()
	body.text = tr(event.text_key)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size = Vector2(CARD_WIDTH - 40.0, 0.0)
	body_scroll.add_child(body)
	# Sarılan bir etiketin asgari boyu yerleşim geçmeden bir satır
	# görünür, o yüzden kutunun boyu metnin *gerçek* yüksekliğinden
	# sonra kırpılıyor - kısa metin kısa kart, uzun metin kaydırılan kart.
	body_scroll.custom_minimum_size = Vector2(
		0.0, minf(body.get_combined_minimum_size().y, CARD_BODY_MAX_HEIGHT)
	)

	var context := _session.build_event_context()
	for choice in event.choices:
		_card_panel.add_child(_build_choice_button(choice, context))

func _build_choice_button(choice: EventChoice, context: Dictionary) -> Button:
	# Görünüm WaybookTheme'in düğme sekmesinden geliyor: EU4'ün kartında
	# seçenek bir satır değil bir tuş, ve kilitli olan üstü çizili sekme.
	var button := Button.new()
	var available := choice.is_available(context)
	var label := tr(choice.text_key)
	var hint_key := choice.get_hint_text(_session.get_best_effective_stat(choice.hint_stat))
	if not hint_key.is_empty():
		label = "%s (%s)" % [label, tr(hint_key)]
	if choice.check != null:
		var stat_value: float = float(context.get(choice.check.get_context_key(), 0.0))
		var roller := _session.get_check_roller(choice.check)
		var roller_name := roller.character_name if roller != null else ""
		label = "%s — %s" % [label, choice.get_check_preview(stat_value, roller_name)]
	var target := EventEffectApplier.get_choice_target(choice, _session)
	if target != null:
		label = tr("UI_ROAD_CHOICE_TARGET") % [label, target.character_name]
	if _choice_triggers_combat(choice):
		# %12 kazanma oranı bir dengesizlik değil bir okunabilirlik sorunu:
		# oyuncu göze aldığı riski seçmeden *önce* görsün, savaş panelinde
		# değil. Sayı zaten var - HUD'daki tehlike çubuğunun aynısı
		# (_weathered_danger) - burada yalnızca karar anında da görünür
		# kılınıyor.
		label = tr("UI_ROAD_CHOICE_DANGER") % [label, roundi(_weathered_danger() * 100.0)]

	if available:
		button.text = label
		button.pressed.connect(_on_choice_pressed.bind(choice))
	else:
		# Kilitli seçenek gizlenmez: oyuncu neyi kaçırdığını görsün. Az
		# kalmışsa sebebi vurgu renginde - "neredeyse" ile "çok uzak" aynı
		# gri olunca hangi eksiğin kapatılmaya değdiği okunmuyordu.
		button.text = "%s — %s" % [label, tr(choice.unavailable_text_key)]
		button.disabled = true
		if choice.is_near_miss(context):
			button.add_theme_color_override("font_disabled_color", ArtPalette.UI_ACCENT)
		# "Çok uzak" durumda `modulate` uygulanmıyor artık: düğmenin dokusunu
		# ve yazısını birlikte karartıp sebebi okunaksız kılıyordu (~2.8:1);
		# `disabled = true` temanın kendi ölçülmüş kontrastını zaten sağlıyor.

	_mark_choice(button, choice)
	return button

## Seçeneğin türü metinden önce, bir bakışta: savaş açabilen seçeneğin
## solunda kan renginde bir şerit, zara bağlı seçeneğin başında zarı atan
## statın amblemi (bkz. WaybookIcons.STAT_EMBLEMS - karakter ekranının
## aynı amblemi). Metin hâlâ her şeyi söylüyor; işaret yalnızca gözü
## doğru seçeneğe götürüyor.
func _mark_choice(button: Button, choice: EventChoice) -> void:
	if choice.check != null:
		var emblem := String(WaybookIcons.STAT_EMBLEMS.get(choice.check.stat, ""))
		if not emblem.is_empty():
			button.icon = WaybookTheme.texture(emblem)
			button.add_theme_constant_override("icon_max_width", CHOICE_ICON_SIZE)
	if _choice_triggers_combat(choice):
		var stripe := ColorRect.new()
		stripe.color = ArtPalette.UI_CHOICE_COMBAT
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stripe.anchor_top = 0.0
		stripe.anchor_bottom = 1.0
		stripe.offset_left = CHOICE_STRIPE_INSET_X
		stripe.offset_right = CHOICE_STRIPE_INSET_X + CHOICE_STRIPE_WIDTH
		stripe.offset_top = CHOICE_STRIPE_INSET_Y
		stripe.offset_bottom = -CHOICE_STRIPE_INSET_Y
		button.add_child(stripe)

## Savaşı doğrudan tetikleyen seçenek mi - tehlike etiketi yalnızca bunlara
## eklenir - garantili `effects` içinde ya da bir sonucun içinde olsun.
func _choice_triggers_combat(choice: EventChoice) -> bool:
	for effect in choice.effects:
		if effect.type == EventEffect.Type.TRIGGER_COMBAT:
			return true
	# Zarı tutmazsa savaşa dönen bir seçenek de (evt_deserter_search'ün
	# yalanı) seçilmeden önce söylesin - kural "savaş açabilen seçenek",
	# "savaşı garanti eden seçenek" değil.
	for outcome in choice.outcomes:
		for effect in outcome.effects:
			if effect.type == EventEffect.Type.TRIGGER_COMBAT:
				return true
	return false

func _on_choice_pressed(choice: EventChoice) -> void:
	var resolved_event := _current_event
	_current_event = null
	_clear_children(_card_panel)

	_add_log("   » %s" % tr(choice.text_key))

	# Çözümün sırası (etkiler → zar → sonuç → XP) tek yerde: EventResolver.
	# Ekran yalnızca sonucu anlatıyor ve yan kanalları açıyor.
	var resolution := EventResolver.resolve_choice(
		_session, _engine, resolved_event, choice, _apply_effects
	)
	if resolution.choice_result != null:
		_apply_side_channels(resolution.choice_result)
		for line in resolution.choice_result.lines:
			_add_log("      %s" % line)
	if resolution.outcome != null:
		_add_log("   %s" % tr(resolution.outcome.text_key), OUTCOME_COLOR)
		if resolution.outcome_result != null:
			_apply_side_channels(resolution.outcome_result)
			for line in resolution.outcome_result.lines:
				_add_log("      %s" % line)

	_refresh_state()
	_check_journey_end()
	_autosave_journey()

func _apply_side_channels(result: EventEffectApplier.Result) -> void:
	for event_id in result.unlocked_event_ids:
		_engine.unlock_event(event_id)
		_add_log(tr("UI_ROAD_EVENT_UNLOCKED"))

	if not result.combat_requests.is_empty():
		var enemy_kind := "bandit"
		if not result.combat_kinds.is_empty():
			enemy_kind = result.combat_kinds[0]
		_open_combat(int(result.combat_requests[0]), enemy_kind)
		return

	if not result.recruit_requests.is_empty():
		_open_recruit_offer()
		return

	if not result.haggling_requests.is_empty():
		_open_haggling(int(result.haggling_requests[0]))

## Yolda karşılaşılan biri partiye katılmayı teklif ediyor. Şehirdeki
## tayfa ekranıyla aynı havuzdan (RecruitCatalog) üretiliyor, yalnızca
## teklif tek kişilik ve anlık.
func _open_recruit_offer() -> void:
	_clock.consume_hours(RECRUIT_HOURS)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d|%d" % [int(_seed_spin.value), _current_day])
	var candidates := RecruitCatalog.build_candidates(
		RecruitCatalog.VENUE_TAVERN, rng, _session.get_player_character().level,
		RecruitCatalog.get_world_growth_levels(_session.journeys_completed)
	)
	if candidates.is_empty() or not _session.can_recruit():
		_add_log(tr("UI_ROAD_TRAVELLER_LEFT"))
		return

	var candidate := candidates[0]
	# Yolda pazarlık gücü yok: ücret şehirdekinden biraz yüksek.
	candidate.hire_cost = int(round(candidate.hire_cost * ROAD_RECRUIT_COST_MULTIPLIER))

	_set_journey_controls_enabled(false)
	_clear_children(_recruit_holder)

	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.text = tr("UI_ROAD_RECRUIT_OFFER") % [
		candidate.get_summary_line(),
		candidate.get_max_hp(),
		candidate.get_accuracy(),
		candidate.get_dodge(),
		candidate.hire_cost,
	]
	_recruit_holder.add_child(info)

	var hire_button := Button.new()
	if _session.wallet.can_afford(candidate.hire_cost):
		hire_button.text = tr("UI_ROAD_RECRUIT_ACCEPT") % candidate.hire_cost
		hire_button.pressed.connect(_on_road_recruit_accepted.bind(candidate))
	else:
		# `modulate` yazıyı da karartıp sebebi okunaksız kılıyordu;
		# `disabled = true` temanın kendi ölçülmüş kontrastını sağlıyor.
		hire_button.text = tr("UI_NOT_ENOUGH_GOLD")
		hire_button.disabled = true
	_recruit_holder.add_child(hire_button)

	var decline_button := Button.new()
	decline_button.text = tr("UI_CANCEL")
	decline_button.pressed.connect(_on_road_recruit_declined)
	_recruit_holder.add_child(decline_button)

func _on_road_recruit_accepted(candidate: CharacterData) -> void:
	if _session.recruit(candidate):
		_add_log(tr("UI_ROAD_RECRUIT_JOINED") % candidate.character_name, OUTCOME_COLOR)
	_close_recruit_offer()

func _on_road_recruit_declined() -> void:
	_add_log(tr("UI_ROAD_RECRUIT_DECLINED"))
	_close_recruit_offer()

func _close_recruit_offer() -> void:
	_clear_children(_recruit_holder)
	_set_journey_controls_enabled(true)
	_refresh_state()
	_check_journey_end()

## Bir olay savaş istediğinde Darkest Dungeon tarzı panel açılır; sonuç
## kervana etkilerle yansır. Panel açıkken gün ilerletilemez.
## enemy_kind EnemyCatalog.build_squad'ın kadro türü (bkz. EventEffect.Type.
## TRIGGER_COMBAT'in text_value'su); bölge (bkz. EnemyCatalog.build_bandit_squad'ın
## region_id'si) sefer hedefinden okunuyor - haydut kadrosu gidilen yöreye
## göre reskin oluyor.
func _open_combat(danger_percent: int, enemy_kind: String = "bandit") -> void:
	_pending_combat_danger = _weathered_danger() if danger_percent <= 0 else danger_percent / 100.0
	_current_combat_kind = enemy_kind
	_set_journey_controls_enabled(false)

	# Kimin bu çarpışmaya gireceğini ve hangi sırada dizileceğini artık
	# oyuncu seçiyor (bkz. PreCombatPanel) - `_pre_combat_panel != null`
	# `_has_open_panel()`'e girdiği için takvim burada da durur.
	_pre_combat_panel = PreCombatPanel.new()
	_pre_combat_panel.confirmed.connect(_on_pre_combat_confirmed)
	add_child(_pre_combat_panel)
	# Son savaşın kadrosu ve sırası hatırlanıyor: değişen bir şey yoksa
	# tek dokunuşla onaylanır.
	var ordered := _session.get_remembered_combat_order()
	var benched: Array[CharacterData] = []
	for character in ordered:
		if not _session.is_in_remembered_roster(character):
			benched.append(character)
	_pre_combat_panel.setup(ordered, benched)

func _on_pre_combat_confirmed(ordered: Array) -> void:
	_pre_combat_panel = null
	_current_combat_party.clear()
	for character in ordered:
		_current_combat_party.append(character)
	_session.remember_combat_roster(_current_combat_party)

	_clock.consume_hours(COMBAT_HOURS)
	_clear_children(_combat_holder)

	# Savaş yolun *yerine* açılıyor: şerit gizlenip savaş sahnesi onun
	# çerçevesinde beliriyor - önceden savaş, şerit görünür kalırken
	# ekranın altına eklenen ayrı bir blok gibi duruyordu.
	_band.visible = false
	_combat_holder.visible = true

	var panel := CombatPanel.new()
	_combat_holder.add_child(panel)
	panel.combat_finished.connect(_on_combat_finished)
	# Faz 17 PR-6: o günkü arazi vahşi hayvan kadrosunun kompozisyonunu da
	# eğiyor (bkz. EnemyCatalog.build_wildlife_squad) - "kurt sürüsü" orman
	# geçitlerinde, tekil ayı dağ geçitlerinde daha olası.
	var current_biome := "" if _terrain == null else _terrain.biome_at(_days_covered)
	panel.start_combat(
		_current_combat_party, _pending_combat_danger, null,
		_current_combat_kind, _session.journey_destination_id, current_biome
	)

func _on_combat_finished(
	victory: bool, xp_awarded: int, downed_count: int, dead_characters: Array
) -> void:
	if xp_awarded > 0:
		# Yalnızca bu savaşa girenler (bkz. PreCombatPanel) - risk almayan
		# deneyim de kazanmaz.
		_session.grant_party_xp(xp_awarded, _current_combat_party)
		_add_log(tr("UI_ROAD_PARTY_XP") % xp_awarded, OUTCOME_COLOR)

	# Ölüm artık savaşta herkesi bulabilir, lideri de yoldaşı da - kural
	# tersine çevrildi (bkz. CombatUnit.can_enter_deaths_door). Sonucunu
	# oturum uygular: her ölen partiden çıkar, liderlik yalnızca *lider*
	# öldüyse devredilir. Kimse ölmediyse bu tamamen sessiz - eski
	# davranış aynen sürüyor.
	if not dead_characters.is_empty():
		_report_combat_deaths(dead_characters)

	# Savaşın dışında tutulan biri, kaybı ya da bir ölümü uzaktan izledi -
	# bunu unutmaz (bkz. CharacterData.GRIEVANCE_BENCHED).
	if not victory or not dead_characters.is_empty():
		for character in _session.get_party():
			if not _current_combat_party.has(character):
				character.add_grievance(CharacterData.GRIEVANCE_BENCHED)

	# Her çarpışma bir miktar gerginlik bırakır; düşen her yoldaş bunu
	# katlar. Zafer bunu biraz yumuşatır, yenilgi daha da ağırlaştırır.
	# Yere düşüp hayatta kalan yoldaş da kalıcı bir iz bırakıyor: kendi
	# stresi ayrıca artıyor ve bu, şehir varışındaki kırılma zarını
	# besliyor - ölüm artık gerçek bir olasılık olduğu için bu ayrı iz
	# hâlâ anlamlı, ölümün yerini almıyor.
	_apply_downed_marks(downed_count)

	var stress_delta := COMBAT_STRESS_BASE + downed_count * COMBAT_STRESS_PER_DOWN
	stress_delta += -COMBAT_VICTORY_STRESS_RELIEF if victory else COMBAT_DEFEAT_STRESS

	var effects: Array[EventEffect] = [
		EventEffect.make(EventEffect.Type.STRESS, stress_delta),
	]
	if victory:
		var loot := COMBAT_LOOT_BASE + int(round(_session.danger_level * COMBAT_LOOT_DANGER_BONUS))
		effects.append(EventEffect.make(EventEffect.Type.GOLD, loot))
		effects.append(EventEffect.make(EventEffect.Type.MORALE, COMBAT_VICTORY_MORALE))
		var reputation_delta := GUARD_VICTORY_REPUTATION if _current_combat_kind == "guard" else COMBAT_VICTORY_REPUTATION
		effects.append(EventEffect.make(EventEffect.Type.REPUTATION, reputation_delta))
		effects.append(EventEffect.make(EventEffect.Type.DANGER, COMBAT_VICTORY_DANGER))
	else:
		effects.append(EventEffect.make(EventEffect.Type.GOLD, COMBAT_DEFEAT_GOLD))
		effects.append(EventEffect.make(EventEffect.Type.WAGON_DAMAGE, COMBAT_DEFEAT_WAGON_DAMAGE))
		effects.append(EventEffect.make(EventEffect.Type.MERCHANT_LEAVE, COMBAT_DEFEAT_MERCHANTS))
		effects.append(EventEffect.make(EventEffect.Type.MORALE, COMBAT_DEFEAT_MORALE))

	var result := _apply_effects(effects)
	for line in result.lines:
		_add_log("      %s" % line, OUTCOME_COLOR if victory else LOCKED_COLOR)

	_clear_children(_combat_holder)
	_combat_holder.visible = false
	_band.visible = true
	_set_journey_controls_enabled(true)
	_refresh_state()
	_check_journey_end()

## Yere düşenler kendi stresini alıyor. Kimin düştüğü savaş panelinden
## sayı olarak geliyor (isim değil), o yüzden en yorgun olanlardan
## başlanıyor: zaten en kırılgan olanı kırmak, rastgele birini
## kırmaktan hem daha okunur hem daha adil. Kayıt da bunu isimle söylüyor -
## "parti stresi +N" değil, "X hâlâ o vuruşu hissediyor" (bkz. Faz 14
## hazırlık notu, "her metrik bir isim taşımalı, ortalama değil").
func _apply_downed_marks(downed_count: int) -> void:
	if downed_count <= 0:
		return
	# Bu savaşa girmeyen biri düşemez - iz yalnızca gerçekten savaşanlar
	# arasından seçilir (bkz. PreCombatPanel).
	var ordered: Array[CharacterData] = _current_combat_party.duplicate()
	ordered.sort_custom(func(a, b): return a.stress > b.stress)
	for index in mini(downed_count, ordered.size()):
		var character := ordered[index]
		_session.change_character_stress(character, DOWNED_STRESS_MARK)
		_add_log(tr("UI_ROAD_DOWNED_MARK") % character.character_name, LOCKED_COLOR)

## Savaşta ölenleri oturuma bildirir ve sonucunu oyuncuya *anlatır*.
## Sessiz bir ölüm hatadan ayırt edilemez: kimin öldüğü, liderliğin kime
## geçtiği ya da oyunun bittiği kayda tek tek yazılıyor.
func _report_combat_deaths(dead_characters: Array) -> void:
	var typed: Array[CharacterData] = []
	for entry in dead_characters:
		var character: CharacterData = entry
		typed.append(character)
	var cause := "LEDGER_CAUSE_COMBAT_%s" % _current_combat_kind.to_upper()
	_death_from_combat = true
	_handle_death_outcome(_session.resolve_deaths(typed, cause, _session.journey_destination_id))
	_death_from_combat = false

## Ölümün ekrandaki tek kapısı - savaş da açlık da buradan geçer. Kimin
## öldüğünü sebebiyle yazar; lider öldüyse varisi oyuncuya seçtirir.
func _handle_death_outcome(outcome: Dictionary) -> void:
	var dead_names: Array = outcome.get("dead_names", [])
	# Defterin kendi satırı - sebebiyle ve yeriyle, "öldü" değil.
	var recent_deaths := _session.ledger.recent(dead_names.size() + 2).filter(
		func(entry): return String(entry.get("kind", "")) == CaravanLedger.KIND_DIED
	)
	for index in mini(dead_names.size(), recent_deaths.size()):
		_add_log(CaravanLedger.describe(recent_deaths[index]), LOCKED_COLOR)

	if outcome.get("run_over", false):
		# Oyunun ilk gerçek sonu: ölen liderin yerine geçecek kimse yok.
		# Sefer burada kapanır, varış ekranı hiç açılmaz.
		_add_log(tr("UI_ROAD_RUN_OVER"), LOCKED_COLOR)
		_journey_finished = true
		_set_journey_controls_enabled(false)
		_arrive_button.visible = false
		_show_run_over()
		return

	if outcome.get("awaiting_heir", false):
		var candidates: Array[CharacterData] = []
		for candidate in (outcome.get("heir_candidates", []) as Array):
			candidates.append(candidate)
		var fallen_name := String(dead_names[0]) if not dead_names.is_empty() else ""
		_open_succession_panel(
			fallen_name, _fallen_leader_line(fallen_name), candidates,
			_succession_testimony(candidates)
		)

## Ölüm bir savaştan mı geldi - törenin "savaşın dışında tutuldu" satırı
## yalnızca o zaman anlamlı (açlıkta kimse savaşın dışında tutulmadı).
var _death_from_combat: bool = false

## Her aday için törenin söyleyeceği: düşen liderin döneminde kaç gün
## hizmet etti, liderin öldüğü savaşın dışında mı tutuldu.
func _succession_testimony(candidates: Array[CharacterData]) -> Dictionary:
	var testimony := {}
	for candidate in candidates:
		testimony[candidate] = {
			"served_days": _session.get_days_served_under_leader(candidate),
			"benched": _death_from_combat and not _current_combat_party.has(candidate),
		}
	return testimony

## Düşen liderin defterdeki satırı (sebep ve yer), törende adının altında.
func _fallen_leader_line(fallen_name: String) -> String:
	for entry in _session.ledger.recent(6):
		if String(entry.get("kind", "")) == CaravanLedger.KIND_DIED \
				and String(entry.get("name", "")) == fallen_name:
			return CaravanLedger.describe(entry)
	return ""

## Kervanı sürecek kimse kalmadı. Ana menüye dönmekten başka bir çıkış
## sunulmuyor ve kayıt silinmiyor - "Devam Et"in kapalı bir seferi
## yüklememesi için `RUN_OVER_FLAG` kayda giriyor (bkz. GameSession).
const RUN_OVER_BOOK_HEIGHT: float = 220.0

func _show_run_over() -> void:
	_clear_children(_arrival_panel)
	# Defter kapandı ve bağlandı: adı taşıyacak kimse kalmadı. Görselde yazı
	# yok, son söz aşağıdaki canlı metin.
	var book := WaybookTheme.picture("m3_closed.png", RUN_OVER_BOOK_HEIGHT)
	book.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_arrival_panel.add_child(book)
	var title := Label.new()
	title.text = tr("UI_ROAD_RUN_OVER_TITLE")
	_arrival_panel.add_child(title)

	var body := Label.new()
	body.text = tr("UI_ROAD_RUN_OVER_BODY")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.modulate = LOCKED_COLOR
	_arrival_panel.add_child(body)

	if _is_live_journey:
		SaveManager.save_session(_session)

## Bir olay pazarlık istediğinde gerçek pazarlık paneli açılır:
## anlaşırsan anlaştığın fiyatı, anlaşamazsan tam bedeli ödersin.
func _open_haggling(max_price: int) -> void:
	_pending_haggle_max = max_price
	_clock.consume_hours(HAGGLE_HOURS)
	_set_journey_controls_enabled(false)
	_clear_children(_haggle_holder)

	var intro := Label.new()
	intro.text = tr("UI_ROAD_HAGGLE_INTRO") % max_price
	_haggle_holder.add_child(intro)

	var panel := HagglingPanel.new()
	_haggle_holder.add_child(panel)
	panel.deal_made.connect(_on_haggle_deal)
	panel.haggling_failed.connect(_on_haggle_failed)
	panel.start_haggling(
		float(max_price),
		0.5,
		0.3,
		_session.get_best_effective_stat(CharacterStats.Kind.INTELLECT),
		_session.get_best_effective_stat(CharacterStats.Kind.CHARISMA),
		false
	)

## Anlaşılan bedel kesende yoksa da ödenir: fark açık hesaba yazılır
## (bkz. GameSession.spend_or_owe). Eskiden "kasada ne varsa o kadarı"
## alınıyordu - parası olmayan kervan haraçtan bedavaya kurtuluyordu.
func _on_haggle_deal(price: int) -> void:
	_session.spend_or_owe(price)
	_add_log(tr("UI_ROAD_HAGGLE_WON") % price, OUTCOME_COLOR)
	_close_haggling()

## Yolda pazarlık koparsa itibar cezası yok: karşındaki haydut, kasabada
## kimseye şikâyet etmeyecek (bkz. HagglingPanel.haggling_failed). Bedel
## burada tam haracı ödemek - ve ödeyecek paran yoksa borçlanmak.
func _on_haggle_failed(_reputation_penalty: int) -> void:
	var paid := _pending_haggle_max
	_session.spend_or_owe(paid)
	_session.caravan.change_morale(HAGGLE_FAIL_MORALE)
	_add_log(tr("UI_ROAD_HAGGLE_LOST") % paid)
	_close_haggling()

func _close_haggling() -> void:
	_clear_children(_haggle_holder)
	_pending_haggle_max = 0
	_set_journey_controls_enabled(true)
	_refresh_state()
	_check_journey_end()

## Sefer yalnızca ortada çözülmemiş bir olay ve açık bir yan kanal paneli
## (savaş/pazarlık/tayfa) yokken bitebilir.
##
## Yan kanal kontrolü olmadan şu zincir işliyordu: son gün bir olay çıkıp
## oyuncu "Direnç göster" derse _on_choice_pressed savaşı açıyor, sonra
## aynı çağrının sonunda buraya geliyor - _current_event çoktan null
## olduğu için sefer bitmiş sayılıyor ve savaş paneli ekrandayken "Şehre
## Var" beliriyordu. Oyuncu varınca finish_journey() kervanı sıfırlayıp
## ödemeyi yapıp kaydediyor; ardından savaş bitince ödülleri (altın,
## moral, itibar) kapanmış bir sefere uygulanıyor ve buradan ikinci kez
## _finish_journey() çağrılıp varış bir daha işlenebiliyordu - ikinci bir
## kırılma zarı ve ikinci bir kayıt dahil.
func _check_journey_end() -> void:
	if _journey_finished or _current_event != null or _pending_event != null or _has_open_panel():
		return
	# Varış artık "gün bitti" değil, "mesafe kapandı" demek.
	if _journey.has_arrived():
		_finish_journey()

func _has_open_panel() -> bool:
	return (
		_combat_holder.get_child_count() > 0
		or _haggle_holder.get_child_count() > 0
		or _recruit_holder.get_child_count() > 0
		or _replan_holder.get_child_count() > 0
		or _debt_holder.get_child_count() > 0
		or _in_game_menu != null
		or _succession_panel != null
		or _meal_panel != null
		or _pre_combat_panel != null
		or _merchant_dialogue_panel != null
	)

## Sefer sürerken kayıt hiç yapılamaz - `SaveManager`in başındaki not:
## `to_save_dict()` sefer alanlarını hiç taşımıyor, yazmak sefer bilgisini
## sessizce kaybettirir. F1'in sentetik seferi de aynı ekranı paylaştığı
## için aynı kural geçerli.
func _open_in_game_menu() -> void:
	if _in_game_menu != null:
		return
	_in_game_menu = InGameMenu.new()
	_in_game_menu.dismissed.connect(_on_in_game_menu_dismissed)
	add_child(_in_game_menu)
	_in_game_menu.setup(false)

func _on_in_game_menu_dismissed() -> void:
	_in_game_menu = null

## Yabancı tüccarın vagonuna diyalog yoluyla bakış (bkz. CLAUDE.md Ana
## Hedefler'in "#11" notu) - emir panelinin "Tüccarla Konuş" düğmesi.
## Eskort yoksa `_talk_merchant_button` zaten kilitli gösteriliyor (bkz.
## `_refresh_talk_merchant_row`), o yüzden burada tekrar sınamaya gerek
## yok - komut yalnızca gerçekten açılabildiğinde tetiklenir.
func _open_merchant_dialogue() -> void:
	if _merchant_dialogue_panel != null:
		return
	_merchant_dialogue_panel = MerchantDialoguePanel.new()
	_merchant_dialogue_panel.closed.connect(_on_merchant_dialogue_closed)
	add_child(_merchant_dialogue_panel)
	_merchant_dialogue_panel.setup(_session)

func _on_merchant_dialogue_closed() -> void:
	_merchant_dialogue_panel = null

## Faz 17 PR-6: borç defteri artık yolda da açılıyor - `DebtPanel` zaten
## sahnesiz bir `PanelContainer` (`guild.tscn`'in Borçlar sekmesindeki
## aynı bileşen), Road Screen Layout Rules'un "kararlar tek bir çerçeveli
## kart içinde" kuralına uyduğu için doğrudan `_debt_holder`'a gömülüyor -
## `MerchantDialoguePanel`'in aksine kendi arka planı/backdrop'u yok,
## bu yüzden ayrı bir tam ekran katman değil, modal kartın bir parçası.
func _open_debt_panel() -> void:
	if _debt_panel != null:
		return
	_clear_children(_debt_holder)

	var title := Label.new()
	title.text = tr("UI_ROAD_DEBT_TITLE")
	title.modulate = ArtPalette.GOLD
	_debt_holder.add_child(title)

	_debt_panel = DebtPanel.new()
	_debt_holder.add_child(_debt_panel)
	_debt_panel.setup(_session)

	var close_button := Button.new()
	close_button.text = tr("UI_CANCEL")
	close_button.pressed.connect(_close_debt_panel)
	_debt_holder.add_child(close_button)

func _close_debt_panel() -> void:
	_clear_children(_debt_holder)
	_debt_panel = null

## Liderlik devrinin töreni (bkz. SuccessionPanel) - `_has_open_panel()`'e
## eklendiği için `_check_journey_end()` ve zaman akışı bu ekranda durur,
## aynı `_in_game_menu`'nün yaptığı gibi.
func _open_succession_panel(
	fallen_name: String, fallen_line: String, candidates: Array[CharacterData],
	testimony: Dictionary = {}
) -> void:
	_succession_panel = SuccessionPanel.new()
	_succession_panel.heir_chosen.connect(_on_heir_chosen)
	_succession_panel.dismissed.connect(_on_succession_dismissed)
	add_child(_succession_panel)
	_succession_panel.setup(
		_session.get_caravan_name(), fallen_name, fallen_line,
		candidates, _session.lineage_generation + 1, testimony
	)

func _on_heir_chosen(heir) -> void:
	var character: CharacterData = heir
	_session.appoint_heir(character)
	_add_log(tr("UI_ROAD_NEW_LEADER") % character.character_name, OUTCOME_COLOR)

func _on_succession_dismissed() -> void:
	_succession_panel = null
	_check_journey_end()

## --- Yolda planı değiştirmek ---
## Şehirde kurulan plan bir niyet, bir taahhüt değil: geçit kapanır, erzak
## biter, kervan hırpalanır ve hedef değişir. Karar verirken zaman durur
## (bkz. _can_time_flow → _has_open_panel), kararın kendisi zaman yer -
## kervanı döndürmek bedava değil.
const REPLAN_HOURS: float = 2.0

func _on_replan_pressed() -> void:
	if _journey_finished or _current_event != null or _has_open_panel():
		return
	_set_journey_controls_enabled(false)
	_build_replan_panel()

func _build_replan_panel() -> void:
	_clear_children(_replan_holder)

	var title := Label.new()
	var destination := WorldMapData.get_location_by_id(_session.journey_destination_id)
	title.text = tr("UI_ROAD_REPLAN_TITLE") % [
		destination.location_name if destination != null else _session.journey_destination_id,
		_session.journey_days_remaining,
	]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	_replan_holder.add_child(title)

	var origin := WorldMapData.get_location_by_id(_session.journey_origin_id)
	if origin != null:
		var back_button := Button.new()
		back_button.text = tr("UI_ROAD_TURN_BACK") % [
			origin.location_name, maxi(GameSession.MIN_DIVERT_DAYS, _session.get_days_travelled())
		]
		back_button.pressed.connect(_on_turn_back_pressed)
		_replan_holder.add_child(back_button)

	# Sapılabilecek hedefler çıkış şehrinden ölçülüyor: kervan haritanın
	# ortasında ışınlanmaz, bildiği yola geri çıkıp oradan gider (bkz.
	# GameSession.can_divert_to).
	for route in WorldMapData.get_routes_from(_session.journey_origin_id):
		if not _session.can_divert_to(route.to_location_id):
			continue
		var target := WorldMapData.get_location_by_id(route.to_location_id)
		var total_days := _session.get_days_travelled() + _session.get_route_travel_days(route)
		var divert_button := Button.new()
		divert_button.text = tr("UI_ROAD_DIVERT") % [
			target.location_name if target != null else route.to_location_id,
			maxi(GameSession.MIN_DIVERT_DAYS, total_days),
			int(_session.get_route_danger(route) * 100.0),
		]
		divert_button.pressed.connect(_on_divert_pressed.bind(route.to_location_id))
		_replan_holder.add_child(divert_button)

	var warning := Label.new()
	warning.text = tr("UI_ROAD_REPLAN_WARNING")
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD
	_replan_holder.add_child(warning)

	var cancel_button := Button.new()
	cancel_button.text = tr("UI_ROAD_REPLAN_CANCEL")
	cancel_button.pressed.connect(_close_replan)
	_replan_holder.add_child(cancel_button)

func _on_turn_back_pressed() -> void:
	if not _session.turn_back():
		_close_replan()
		return
	_apply_replan(tr("UI_ROAD_TURNED_BACK"))

func _on_divert_pressed(destination_id: String) -> void:
	if not _session.divert_journey(destination_id):
		_close_replan()
		return
	_apply_replan(tr("UI_ROAD_DIVERTED"))

func _apply_replan(log_format: String) -> void:
	_clock.consume_hours(REPLAN_HOURS)
	# Yeni bacak yeni bir sefer: ilerleme çubuğu ve varış kontrolü yeni
	# toplam güne göre okunmalı, yoksa çubuk dolu kalır ve sefer bitmiş
	# görünürdü.
	# Yeni bacak sıfırdan yürünür: kervan çıkış şehrine döndü ya da başka
	# bir yola saptı, kat edilmiş mesafe o yola ait değil. Eski yolda
	# beliren bir işaret de o yolla birlikte geride kalıyor - kervan artık
	# oraya hiç gitmeyecek.
	_journey.start_leg(_session.journey_total_days)
	_clear_encounter()
	_sync_days_remaining()
	var destination := WorldMapData.get_location_by_id(_session.journey_destination_id)
	_add_log(log_format % (
		destination.location_name if destination != null else _session.journey_destination_id
	), OUTCOME_COLOR)
	_close_replan()

	# Kervandaki tüccarlar bunu fark eder - En-Route Plan Rules'un zaten
	# yaptığı sessiz kesintiyi (varışta uygulanan itibar cezası) burada
	# hikâyeleştiriyoruz. original_merchant_names sefer başından beri
	# değişmez, yani "aboard tüccar var mı" sorusunun cevabı hâlâ doğru.
	if not _session.caravan.original_merchant_names.is_empty():
		var diversion_event := EventCatalog.get_event("evt_route_diversion")
		if diversion_event != null:
			_present_event(diversion_event)

func _close_replan() -> void:
	_clear_children(_replan_holder)
	_set_journey_controls_enabled(true)
	_refresh_state()
	_check_journey_end()

func _finish_journey() -> void:
	_journey_finished = true
	_set_journey_controls_enabled(false)
	_add_log(tr("UI_ROAD_JOURNEY_DONE") % _current_day)

	if _is_live_journey:
		_arrive_button.visible = true

func _on_arrive_pressed() -> void:
	# Şehrin gökyüzü varılan saatten (bkz. GameSession.last_clock_hour).
	_session.last_clock_hour = _clock.get_hour_of_day()
	var payout: Dictionary = _session.finish_journey()
	_arrive_button.visible = false
	_render_arrival_summary(payout)

	# Varışın kaydı. Sefer boyunca yalnızca sakin anlarda otomatik kayıt
	# var (bkz. _autosave_journey) - elle kayıt yok, yolda alınan riskin geri
	# alınamaması olayları anlamlı kılıyor. Sentetik dev seferi gerçek kaydı
	# kirletmez.
	if _is_live_journey:
		SaveManager.save_session(_session)

	_enter_city_button.visible = true

func _render_arrival_summary(payout: Dictionary) -> void:
	_clear_children(_arrival_panel)

	var title := Label.new()
	title.text = tr("UI_ROAD_ARRIVAL_TITLE")
	_arrival_panel.add_child(title)

	_arrival_panel.add_child(_make_summary_label(
		tr("UI_ROAD_ESCORT_FEE") % payout.gross
	))
	_arrival_panel.add_child(_make_summary_label(
		tr("UI_ROAD_MORALE_MULTIPLIER") % int(round(payout.morale_factor * 100.0))
	))
	_arrival_panel.add_child(_make_summary_label(
		tr("UI_ROAD_DAMAGE_MULTIPLIER") % int(round(payout.damage_factor * 100.0))
	))

	var net_label := _make_summary_label(tr("UI_ROAD_NET") % payout.net)
	net_label.modulate = OUTCOME_COLOR
	_arrival_panel.add_child(net_label)

	# Teslim edilen kontratlar. Bu satır uzun süre yoktu ve teslimat
	# varışta kendiliğinden olduğu için oyuncu şehirde bir "teslim et"
	# tuşu arıyordu - playtest'te tam olarak bu yaşandı. Kaybedilen
	# kontratın satırı vardı, kazanılanınki yoktu: yalnızca cezayı
	# gösteren bir özet, oyuna hak ettiğinden kötü bir yüz veriyor.
	var delivered: int = payout.get("delivered_contracts", 0)
	if delivered > 0:
		var delivered_label := _make_summary_label(tr("UI_ROAD_DELIVERED") % delivered)
		delivered_label.modulate = OUTCOME_COLOR
		_arrival_panel.add_child(delivered_label)

	# İtibar oyunun en kıt kaynağı (bkz. Reputation Rules) ve kazanıldığı
	# yer burası - ama kazanç hiç yazılmıyordu.
	var reputation_gained: int = payout.get("reputation_gained", 0)
	if reputation_gained > 0:
		var reputation_label := _make_summary_label(
			tr("UI_ROAD_REPUTATION_GAINED") % reputation_gained
		)
		reputation_label.modulate = OUTCOME_COLOR
		_arrival_panel.add_child(reputation_label)

	var xp_awarded: int = payout.get("xp_awarded", 0)
	if xp_awarded > 0:
		var xp_label := _make_summary_label(tr("UI_ROAD_JOURNEY_XP") % xp_awarded)
		xp_label.modulate = OUTCOME_COLOR
		_arrival_panel.add_child(xp_label)

	var lost_contracts: int = payout.get("lost_contracts", 0)
	if lost_contracts > 0:
		var penalty_label := _make_summary_label(
			tr("UI_ROAD_LOST_CONTRACTS") % [
				lost_contracts, lost_contracts * GameSession.REPUTATION_PENALTY_PER_LOST_CONTRACT
			]
		)
		penalty_label.modulate = LOCKED_COLOR
		_arrival_panel.add_child(penalty_label)

	for entry in (payout.get("stress_breaks", []) as Array):
		var break_data: Dictionary = entry
		var break_label := _make_summary_label(_stress_break_line(break_data))
		break_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		break_label.modulate = LOCKED_COLOR if break_data.affliction else OUTCOME_COLOR
		_arrival_panel.add_child(break_label)

	_add_log(tr("UI_ROAD_ARRIVED") % payout.net, OUTCOME_COLOR)

## Kırılan bir yoldaşın varış özetindeki tek satırlık dökümü - huy
## kazandıysa adı, ayrıldıysa bunun da belirtilmesi lazım, oyuncu neden
## bir yoldaşını kaybettiğini anlasın.
func _stress_break_line(break_data: Dictionary) -> String:
	var character_name: String = break_data.character_name
	var trait_id: String = break_data.trait_id
	var trait_resource := TraitCatalog.get_trait(trait_id) if not trait_id.is_empty() else null
	var trait_note := " (%s)" % trait_resource.display_name if trait_resource != null else ""

	if break_data.departed:
		return tr("UI_STRESS_BROKE_LEFT") % [character_name, trait_note]
	if trait_resource != null:
		var kind := tr("UI_STRESS_VIRTUE") if trait_resource.is_positive else tr("UI_STRESS_AFFLICTION")
		return tr("UI_STRESS_BROKE_TRAIT") % [character_name, kind, trait_note]
	return tr("UI_STRESS_BROKE") % character_name

func _make_summary_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label

## Varış her zaman şehre çıkar. Eskiden burada bir "zenginlik hedefi"
## ekranı vardı (kese 5000'e ulaşınca); kaldırıldı, çünkü oyunun hedefi
## kesenin dolması değil adın yolda kalması (bkz. GameSession'ın soy
## bölümü). Oyunun tek gerçek sonu hâlâ var ve o da burada değil:
## liderin ölüp yerine geçecek kimsenin kalmaması (_show_run_over).
func _on_enter_city_pressed() -> void:
	# `city_map.gd` bunu okuyup kapı sesini çalıyor - bkz. Nav'daki not,
	# neden bir is_journey_active() kontrolü değil de taşınan bir bayrak.
	Nav.city_gate_opening = true
	# Şehre giriş mürekkepte bir an bekliyor: "vardık" anı (bkz. SceneInk).
	SceneInk.hold_next(ARRIVAL_INK_HOLD)
	SceneInk.go(Nav.go_root(Nav.CITY_MAP))

## Bir yan kanal paneli (savaş/pazarlık/tayfa) açıkken zaman durur ve
## eylemler kilitlenir - olay çözülmeden yol devam etmemeli.
func _set_journey_controls_enabled(enabled: bool) -> void:
	_camp_button.disabled = not enabled
	_speed_button.disabled = not enabled
	_orders_enabled = enabled
	_refresh_command_panel()
	# Plan yalnızca yolda değiştirilebilir: varış işlendikten sonra ortada
	# değiştirilecek bir sefer kalmıyor.
	_replan_button.disabled = not enabled or not _session.is_journey_active()

## Ortalama kimin kırılmak üzere olduğunu saklıyor (bkz. Stress Rules'un
## "stres bir kişiye ait" maddesi): şişede en yıpranmış kişinin çentiği.
## Kimse ortalamadan belirgin yukarıda değilse çentik gereksiz gürültü.
const STRESS_MARKER_MIN_GAP: int = 5

func _refresh_stress_marker() -> void:
	var worst := _session.get_max_stress_character()
	if worst == null or worst.stress - _session.party_stress < STRESS_MARKER_MIN_GAP:
		_stress_bar.set_marker(-1.0)
		return
	_stress_bar.set_marker(
		worst.stress, tr("UI_HUD_STRESS_WORST") % [worst.character_name, worst.stress]
	)

func _refresh_state() -> void:
	var caravan := _session.caravan
	# Oranlar çubukta, sayılar tek satırda. İkisi birden metinde olduğunda
	# üst şerit bir döküm sayfasına dönüyordu.
	_morale_bar.set_value(caravan.morale, CaravanState.MAX_MORALE)
	_stress_bar.set_value(_session.party_stress, GameSession.MAX_STRESS)
	_refresh_stress_marker()
	_danger_bar.set_value(_weathered_danger() * 100.0, 100.0)
	_stamina_bar.set_value(caravan.stamina, CaravanState.MAX_STAMINA)
	_attention_label.text = tr("UI_ROAD_ATTENTION") % RoadAttention.get_zone_label(
		_attention_zone
	)
	_attention_label.tooltip_text = _attention_label.text
	_attention_icon.texture = WaybookTheme.texture(ZONE_ICONS.get(
		_attention_zone, ZONE_ICONS[RoadAttention.ZONE_WAGONS]
	))
	_refresh_edges()
	if _signal_tween == null:
		_refresh_signal_icon()

	_state_label.text = tr("UI_ROAD_CHIPS") % [
		_session.wallet.balance,
		_session.get_provisions(),
		_session.reputation,
		caravan.wagon_count,
		caravan.damaged_wagons,
		caravan.merchant_names.size(),
		caravan.documents,
	]
	_state_label.tooltip_text = _state_label.text

## Kenar lekelerinin koyuluğu. Eşiğin altında hiçbir şey görünmüyor: sakin
## bir kervanın ekranı temiz kalsın, leke ancak bir şey ters gidince gelsin.
func _refresh_edges() -> void:
	_stress_edge.modulate.a = EDGE_MAX_ALPHA * clampf(
		(_session.party_stress - EDGE_STRESS_FROM) / (EDGE_STRESS_FULL - EDGE_STRESS_FROM), 0.0, 1.0
	)
	var hungry_nights := 0
	for character in _session.party:
		hungry_nights = maxi(hungry_nights, character.consecutive_hungry_days)
	_hunger_edge.modulate.a = EDGE_MAX_ALPHA * clampf(
		float(hungry_nights) / float(EDGE_HUNGER_FULL_NIGHTS), 0.0, 1.0
	)
	var is_winter := MarketConditions.get_season(_session.total_days_elapsed) == MarketConditions.Season.WINTER
	var biome := _terrain.biome_at(_days_covered) if _terrain != null else ""
	_cold_edge.modulate.a = EDGE_MAX_ALPHA * cold_level(is_winter, biome)

func _add_log(text: String, color: Color = Color.WHITE) -> void:
	# Alt şerit yalnızca son satırı gösteriyor; defterin tamamı kayıt
	# katmanında duruyor (bkz. _build_log_layer).
	if _last_log_label != null:
		_last_log_label.text = text
		_last_log_label.tooltip_text = text
		_last_log_label.modulate = ArtPalette.UI_HUD_NOTE if color == Color.WHITE else color

	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	if color != Color.WHITE:
		label.modulate = color
	_log_list.add_child(label)

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

## Yol bir kök ekrandır: sefer başlayınca yığın temizlenir, çünkü yoldan
## "geri" diye bir şey yok - varılır, dönülür ya da rota değiştirilir.
## Canlı seferde çıkış ana menüye gider; eskiden şehir haritasına
## dönüyordu ve sefer `is_journey_active()` olarak açık kaldığı için
## oyuncu kervanının bulunmadığı şehre düşüyor, yola bir daha
## dönemiyordu. Sentetik F1 seferi oyun akışının parçası değil, o yüzden
## orada normal geri davranışı korunur.
func _refresh_exit_button() -> void:
	if _exit_button == null:
		return
	# Canlı seferde tuş artık dosdoğru ana menüye gitmiyor, oyun içi menüyü
	# açıyor (bkz. InGameMenu) - etiketi de artık "ana menüye dön" değil
	# "menü" diyor, aksi hâlde tuş söylediğini yapmıyor gibi dururdu.
	_exit_button.text = (
		tr("UI_INGAME_MENU_TITLE") if _is_live_journey else Nav.label_for(Nav.peek())
	)

func _on_back_pressed() -> void:
	if _is_live_journey:
		_open_in_game_menu()
	else:
		SceneInk.go(Nav.back())
