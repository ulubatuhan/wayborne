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
## İşaretin doğduğu yer ile görüşün kenarı arasında bırakılan pay (piksel).
const ENCOUNTER_EDGE_MARGIN: float = 90.0

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
	# Başka kervanlar (Y-B10): uzaktan görünür, zincirin devamı da.
	"evt_pilgrim_encounter": "traveler",
	"evt_convoy_search": "guard",
	"evt_convoy_repaid": "guard",
	"evt_refugee_gratitude": "traveler",
	"evt_rival_slander": "traveler",
	"evt_rogue_mage": "bandit",
}

## event_id -> `e6*.jpg` (Faz 22'nin olay kartı illüstrasyonları, bkz.
## docs/wayborne_gorsel_denetim.xlsx). `EVENT_ROAD_MARKER_KIND`'in
## kendi kuralı burada da geçerli: eşlemede olmayan bir olay resimsiz
## açılır, bu sessiz bir eksiklik değil - her yeni olay bir illüstrasyon
## istemez, kartın kendi metni yeter. Birden çok olay aynı sahneyi
## paylaşabiliyor (üç haber olayı da "yola çakılı bir haber", üç mezar
## olayı da aynı yol kenarı mezarı) - `ArtDraw.wagon()`'un "bir şey iki
## kez çizilirse iki farklı şey olur" kuralının tersten okunuşu: burada
## aynı şey gerçekten aynı, tek resim yeter.
const EVENT_CARD_ART: Dictionary = {
	"evt_wild_animal": "e6a_wildlife.jpg",
	"evt_wolf_pack": "e6b_wolves.jpg",
	"evt_wolves_follow": "e6b_wolves.jpg",
	"evt_bandit_ambush": "e6c_bandits.jpg",
	"evt_guard_patrol": "e6d_guard.jpg",
	"evt_customs_checkpoint": "e6d_guard.jpg",
	"evt_road_patrol": "e6d_guard.jpg",
	"evt_deserter_search": "e6d_guard.jpg",
	"evt_road_wanderer": "e6e_traveler.jpg",
	"evt_deserter_plea": "e6e_traveler.jpg",
	"evt_stowaway": "e6e_traveler.jpg",
	"evt_stowaway_repay": "e6e_traveler.jpg",
	"evt_kin_encounter": "e6e_traveler.jpg",
	"evt_merchant_caravan": "e6f_merchant.jpg",
	"evt_pilgrim_encounter": "e6g_pilgrim.jpg",
	"evt_pilgrim_blessing": "e6g_pilgrim.jpg",
	"evt_roadside_shrine": "e6h_shrine.jpg",
	"evt_culture_highland_challenge": "e6i_pass.jpg",
	"evt_scouted_pass": "e6i_pass.jpg",
	"evt_leave_the_wounded": "e6j_village.jpg",
	"evt_frontier_outpost": "e6k_outpost.jpg",
	"evt_mine_collapse": "e6l_mine.jpg",
	"evt_failing_bridge": "e6m_bridge.jpg",
	"evt_storm": "e6n_storm.jpg",
	"evt_landslide": "e6o_landslide.jpg",
	"evt_broken_axle": "e6p_wagon.jpg",
	"evt_abandoned_wagon": "e6p_wagon.jpg",
	"evt_troubled_night": "e6q_camp.jpg",
	"evt_grave_on_the_road": "e6r_grave.jpg",
	"evt_grave_keeper": "e6r_grave.jpg",
	"evt_grave_offering": "e6r_grave.jpg",
	"evt_creditor_rider": "e6s_creditor.jpg",
	"evt_bailiffs_at_camp": "e6s_creditor.jpg",
	"evt_deserter_debt": "e6s_creditor.jpg",
	"evt_regional_war_news": "e6t_news.jpg",
	"evt_plague_outbreak_news": "e6t_news.jpg",
	"evt_trade_fair_news": "e6t_news.jpg",
	"evt_bandit_tribute_zone_news": "e6t_news.jpg",
	"evt_bandit_tribute_toll": "e6t_news.jpg",
	"evt_route_diversion": "e6t_news.jpg",
	"evt_forgotten_cache": "e6u_cache.jpg",
}
## Kartın içindeki illüstrasyon şeridi - kare resmi genişliğe göre kırpıp
## geniş bir şerit gösteriyor (bkz. `_build_event_illustration`), kartın
## kendi metin+seçenek yüksekliğini ezmesin diye.
const CARD_ILLUSTRATION_HEIGHT: float = 200.0

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

## Liderin kolonda gezerken zemine göre hızı artık sabit piksel değil:
## figürünün (at ya da yaya) tempolu yürüyüşü - `RoadCaravan.
## get_leader_brisk_speed()`. 96/64 piksel 320'lik şeride göreydi; tam
## ekranda at yürüyüş kareleriyle dörtnala hızında kayıyordu.
## Manzaranın gün->piksel ölçeğinin yeni değere yumuşak geçiş süresi
## (saniye): tempo ya da saat hızı değişince manzara sıçramasın.
const WORLD_SCALE_EASE_SECONDS: float = 0.6
## Kervanın gün/saniye hızının yumuşatma süresi - kare kare oynayan
## mesafe ölçeği oynatmasın.
const DAY_RATE_EASE_SECONDS: float = 0.4
## Tutulan yönde liderin en az ekran hızı (oran). Kervan 3x'te liderin
## kendi hızından hızlı akabiliyor; ileri tutulan tuş lideri yine de
## kolonun önüne doğru götürmeli, kervanın gerisine düşürmemeli.
const LEADER_MIN_SCREEN_SHARE: float = 0.35

## Ortadaki karar kartının genişliği. EU4'ün olay kartı gibi: ekranın
## tamamını kaplamıyor, arkasında dünyanın durduğu görünüyor.
const CARD_WIDTH: float = 660.0
## Kart gövdesinin en fazla ne kadar yer kaplayacağı - uzun bir metin
## kartı ekran boyu uzatmasın diye kaydırma kutusuna giriyor.
const CARD_BODY_MAX_HEIGHT: float = 320.0

## Yol HUD'unun Waybook parçaları (bkz. Waybook UI Rules).
const TIME_DIAL_SIZE: float = 34.0
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
	# Kehanetin kendi ikonu yok: arkadan gelen, belirsiz bir iz (Y-B03).
	RoadSignals.KIND_OMEN: "r7b_straggler.png",
}
const SIGNAL_FLASH_SECONDS: float = 1.6
const SIGNAL_FADE_SECONDS: float = 0.8

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
## Dönüş bitince açılacak kart (tüccarların tepkisi) - bkz. _start_turn_if_needed.
var _turn_event_after: GameEvent = null
var _has_leader_target: bool = false
## Liderin kolondaki yeri = neye dikkat ettiği (bkz. RoadAttention).
## Kolona bağlıyken lider baştadır, yani ön bölgededir.
var _attention_zone: String = RoadAttention.ZONE_FRONT
## Yolun sürekli konuşan katmanı (bkz. RoadSignals) - modal değil,
## kart açmıyor, zamanı durdurmuyor.
var _signals: RoadSignals:
	get:
		return _journey.signals
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
## Yolda biriyle konuşma penceresi (katılmak isteyen yolcu).
var _talk_panel: DialoguePanel = null
## Yolda açılır dünya haritası (bkz. MapPopup); açıkken zaman durur.
var _map_popup: MapPopup = null
## Alt kontrol paneli (bkz. RoadControlPanel, _layout_panel).
var _control_panel: RoadControlPanel = null
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
## Kervanın yumuşatılmış gün/saniye hızı ve manzara ölçeğinin kurulup
## kurulmadığı (bkz. _update_world_scale).
var _day_rate: float = 0.0
var _world_scale_set: bool = false

var _clock_label: Label
var _speed_button: Button
## --- Yakınlaştırma ---
## Yolda yakınlaşıp uzaklaşılabiliyor: tekerlek, iki parmak ya da HUD'daki
## +/- düğmeleri (dokunmatik denklik). 1.0 şeridin kendisi; altına inmek
## (uzaklaşmak) şeridi küçültüyor ve şerit ekranın gördüğü fazlalığa
## manzarayı taşıyarak çiziyor (bkz. TravelBand.set_view_rect) - kenar hiç
## görünmüyor. Alt sınır oyuncunun "biraz daha geri çekilebilmeliyim"
## isteğine göre: kervan hâlâ okunuyor, ufuk belirgin biçimde açılıyor.
## Merkez liderin başı ve zemin çizgisi: göz kervandan kopmasın.
const ZOOM_MIN: float = 0.7
const ZOOM_MAX: float = 1.6
const ZOOM_DEFAULT: float = 1.0
const ZOOM_STEP: float = 0.1
const ZOOM_EASE: float = 8.0
## Süreç boyunca akılda: bir sonraki seferde de oyuncunun seçtiği yakınlık.
static var _zoom_target: float = ZOOM_DEFAULT
var _zoom: float = ZOOM_DEFAULT
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
## Metin kurmadan önce karşılaştırılan girdiler (görev 2.2): yalnızca gösterilen
## değer değişince tr() ve biçimleme çalışsın.
var _last_conditions_key: Array = []
var _last_progress_percent: int = -1
var _last_command_key: Array = []
var _last_talk_key: Array = []
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

## Alt şeritteki tek satırlık kayıt - listenin tamamı artık `_log_overlay`'de.
var _last_log_label: Label
var _log_button: Button
var _status_button: Button
## Moral/stres/tehlike sayı değil **nesne** (şişe, leke): bir orandan
## ibaret olan değeri rakam olarak okumak oyuncuyu her karede metin okumaya
## zorluyor. Sayı yine altında yazılı (bkz. SurvivalGauge).
var _morale_bar: SurvivalGauge
var _stress_bar: SurvivalGauge
var _danger_bar: SurvivalGauge
## Takat: temponun harcanan kaynağı. Görünmeyen bir kaynak kaynak
## değildir - oyuncu neyi harcadığını görmeden harcama kararı veremez.
var _stamina_bar: SurvivalGauge
## Liderin o an neye dikkat ettiği. Mekanik görünmezse hata gibi okunur.
var _attention_label: Label
## Dikkatin yeri bir ikon da taşıyor (baş/vagonlar/art) - etiket okunmadan
## bir bakışta. Açık bir yol işareti de kendi ikonuyla yanında duruyor.
var _attention_icon: TextureRect
var _signal_icon: TextureRect
var _signal_tween: Tween
var _time_dial: TimeDial
## Modal katmanı her karede içeriğe bakıyor (bkz. _refresh_modal); son
## durum burada tutuluyor ki görünürlük her karede yeniden atanmasın.
var _modal_open: bool = false

func _ready() -> void:
	AudioManager.play_track(AudioManager.TRACK_ROAD)
	_build_ui()
	_init_journey()
	get_viewport().size_changed.connect(_layout_panel)
	_layout_panel()

## Kullanıcı kararı (2026-10-18, işaretli ekran görüntüsü): sahnenin üstündeki
## boş gökyüzü şeridi kalkar, sahne o kadar yukarı kayar; altta açılan yer
## kontrol panelinin (RoadControlPanel). Şerit aynı boyda kalır: figürler
## ve manzara küçülmez, yalnızca kadraj kayar.
const SKY_CROP_SHARE: float = 0.19
const CONTROL_PANEL_SHARE: float = 0.27

func _layout_panel() -> void:
	var h := get_viewport_rect().size.y
	# Savaş bütün ekranı alıyor (taslak 9.8 + Y-G05): üstte tur madalyonu, altta
	# iki panel. Gökyüzü kırpması ve yolun kontrol paneli o sırada yok.
	var crop := 0.0 if _combat_holder != null and _combat_holder.visible else h * SKY_CROP_SHARE
	_world.offset_top = -crop
	_world.offset_bottom = -crop
	if _control_panel != null:
		_control_panel.custom_minimum_size = Vector2(0, h * CONTROL_PANEL_SHARE)

## Savaş sırasında yolun HUD'u (üst şerit, kontrol paneli, alt şerit) gizli,
## savaş paneli ekranın tamamında; savaş bitince her şey yerine döner.
func _set_combat_view(on: bool) -> void:
	_hud.visible = not on
	_layout_panel()

## Panelin okuduğu yol hâli (bkz. RoadControlPanel). Yalnızca okunur.
func _panel_state() -> Dictionary:
	if _session == null or _clock == null:
		return {}
	var destination := WorldMapData.get_location_by_id(_session.journey_destination_id)
	var biome := ArtPalette.FALLBACK_BIOME if _terrain == null else _terrain.biome_at(_terrain_day())
	var signals: Array = []
	for kind in _signals.get_open_kinds():
		signals.append(tr(RoadSignals.get_notice_key(kind)))
	var lines: Array = []
	for child in _log_list.get_children():
		if child is Label:
			lines.append((child as Label).text)
	var orders: Array = [
		"%s: %s" % [tr("UI_ROAD_ORDER_MEAL"), tr(MEAL_POLICY_LABELS.get(_session.meal_policy_mode, "UI_MEAL_POLICY_ALL"))],
		tr("UI_ROAD_CAMP_ORDER_ON" if _session.standing_camp_at_dusk else "UI_ROAD_CAMP_ORDER_OFF"),
	]
	var path := PackedVector2Array()
	var origin := _session.journey_origin_id
	var parts := _journey.terrain_key.split("|")
	if parts.size() == 2:
		path = WorldMapData.get_route_path(origin, String(parts[1] if String(parts[0]) == origin else parts[0]))
	return {
		"clock": tr("UI_ROAD_CLOCK") % [_current_day + 1, _clock.get_clock_text(), tr(JourneyClock.get_phase_key(_clock.get_phase()))],
		"destination": destination.location_name if destination != null else "",
		"days_left": _session.journey_days_remaining,
		"weather": tr(RouteWeather.name_key(_weather)),
		"terrain": tr(RouteTerrain.biome_name_key(biome)),
		"pace": tr(_pace_key),
		"signals": signals,
		"log": lines,
		"orders": orders,
		"origin": origin,
		"path": path,
		"progress": clampf(_terrain_day() / float(maxi(1, _journey.terrain_days)), 0.0, 1.0),
		"danger": _weathered_danger(),
		"hour": _clock.get_hour_of_day(),
	}

func _build_ui() -> void:
	_build_world_layer()
	_build_hud_layer()
	_build_modal_layer()
	_build_log_layer()
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
	_caravan.turn_finished.connect(_on_caravan_turn_finished)
	# Kamp ateşinin sesi (görev 12.2c): tutuşma ilk varanla, çıtırtı kamp
	# boyunca, kamp kalkıp herkes binince söner.
	_caravan.fire_lit.connect(_on_fire_lit)
	_caravan.fires_out.connect(_refresh_ambience)

	# Savaş yolun *yerine* açılıyor: aynı çerçeve, aynı ekran alanı.
	_combat_holder = VBoxContainer.new()
	_combat_holder.visible = false
	_world.add_child(_combat_holder)

	# Kenar lekeleri (stres, don, açlık) kullanıcı kararıyla kalktı (görev 2.5):
	# yıpranma sözle ve göstergelerle söyleniyor, ekranın kenarı temiz.

	# Konuşma baloncukları (görev R0/R1): kervanın üstünde, HUD'un altında.
	_balloon_layer = Control.new()
	_balloon_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_balloon_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_world.add_child(_balloon_layer)

## HUD: üstte zaman/durum şeridi, altta eylem şeridi, ikisinin arasında
## dünyanın göründüğü boşluk. Şeritler dışında hiçbir yer tıklamayı
## yutmuyor - aradaki boşluk `MOUSE_FILTER_IGNORE`.
func _build_hud_layer() -> void:
	_hud.add_child(_build_top_bar())
	_hud.add_child(WaybookTheme.hud_rule())

	# Boş - dünyanın göründüğü aralığı iki şerit arasında açık tutuyor.
	# Emir paneli artık burada değil, kendi serbest katmanında (bkz.
	# _build_orders_panel): bir Container'ın çocuğuyken elle taşınamıyordu.
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(middle)

	# Kontrol paneli (P18): göstergeler artık sağ üstte değil, panelin Durum
	# sekmesinde.
	_control_panel = RoadControlPanel.new().setup(_session, _panel_state, _build_gauge_plate())
	_control_panel.map_requested.connect(_open_map_popup)
	_hud.add_child(_control_panel)
	_hud.add_child(_build_bottom_bar())
	_build_orders_panel()

## Kervanın hali: dört nesne, sağ üstte, gökyüzünün önünde - kervanın ve
## yolun üstüne binmiyor. Şişe (moral, stres, takat) ve leke (tehlike);
## sayı her birinin altında yazılı (bkz. SurvivalGauge). Üst şeritteki
## metin şişelerinin yerini aldılar: şerit artık yalnızca zaman ve sayılar.
const GAUGE_PLATE_MARGIN: int = 14

func _build_gauge_plate() -> Control:
	var holder := MarginContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	holder.add_theme_constant_override("margin_top", GAUGE_PLATE_MARGIN)
	holder.add_theme_constant_override("margin_right", GAUGE_PLATE_MARGIN + 6)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", GrimTheme.plate_box(false, Vector4(14, 8, 14, 4)))
	plate.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.add_child(plate)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	plate.add_child(row)
	_morale_bar = SurvivalGauge.new().setup(SurvivalGauge.Kind.VIAL, ArtPalette.UI_GAUGE_MORALE, tr("UI_HUB_MORALE"))
	_stress_bar = SurvivalGauge.new().setup(SurvivalGauge.Kind.VIAL, ArtPalette.UI_GAUGE_STRESS, tr("UI_HUB_STRESS"), false)
	_danger_bar = SurvivalGauge.new().setup(SurvivalGauge.Kind.STAIN, ArtPalette.GRIM_CRIMSON, tr("UI_HUB_DANGER"), false)
	_stamina_bar = SurvivalGauge.new().setup(SurvivalGauge.Kind.VIAL, ArtPalette.UI_GAUGE_STAMINA, tr("UI_ROAD_STAMINA"))
	for gauge in [_morale_bar, _stress_bar, _danger_bar, _stamina_bar]:
		row.add_child(gauge)
	return holder

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
	_speed_button.tooltip_text = tr("UI_ROAD_SPEED_TOOLTIP")
	_speed_button.pressed.connect(_on_speed_pressed)
	row.add_child(_speed_button)

	for step in [-1, 1]:
		var zoom_button := Button.new()
		zoom_button.tooltip_text = tr("UI_ROAD_ZOOM_OUT" if step < 0 else "UI_ROAD_ZOOM_IN")
		zoom_button.pressed.connect(_step_zoom.bind(step))
		row.add_child(zoom_button)
		# "–"/"+" font glyph'i değil çizim: tek bir karakter fontun kendi
		# metrik boşluğuyla ortalanmıyor - UiIcon tam merkezde çiziyor.
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
	# Cevapları alttaki kontrol panelinin sekmelerinde (P18); bu düğme ve
	# Tab Durum sekmesini açar. Eski üstüne binen döküm katmanı (N23)
	# kaldırıldı: kontratlar Yük sekmesinde, defter Defter sekmesinde.
	_status_button = Button.new()
	_status_button.text = tr("UI_STATUS_OPEN")
	_status_button.tooltip_text = tr("UI_STATUS_TOOLTIP")
	_status_button.pressed.connect(_on_status_toggled.bind(true))
	row.add_child(_status_button)

	# Defterin tamamı: bir okuma, zamanı durdurmuyor.
	var waybook_button := Button.new()
	waybook_button.text = tr("UI_WAYBOOK_OPEN")
	waybook_button.pressed.connect(_show_waybook)
	row.add_child(waybook_button)

	# Açılır dünya haritası (görev N24); kısayolu M.
	var map_button := Button.new()
	map_button.text = tr("UI_ROAD_MAP_OPEN")
	map_button.tooltip_text = tr("UI_ROAD_MAP_TOOLTIP")
	map_button.pressed.connect(_open_map_popup)
	row.add_child(map_button)

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
	# UI kiti v2 (taslak 9.1): kartın kenarı kitin bakır-pas çerçevesi.
	frame.theme_type_variation = WaybookTheme.FRAMED_PANEL
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

## Durum sekmesi (true) ya da Kadro (false). Sahne değişmez, yol yürür.
func _on_status_toggled(pressed: bool) -> void:
	if _control_panel == null:
		return
	_control_panel.select_tab(RoadControlPanel.TAB_STATUS if pressed else RoadControlPanel.TAB_PARTY)

## Defter ve harita okumadır, karar değil: zamanı durdurmuyorlar, log ve
## durum katmanlarıyla aynı muamele (bkz. `_can_time_flow`).
const WAYBOOK_KEY: Key = KEY_L
const MAP_KEY: Key = KEY_M

## Kervan yolun neresindeyse haritada orada, gittiği yöne bakarak. Arazi
## seferin çıkışından ölçülüyor (bkz. JourneyController.terrain_day), yolun
## harita çizgisi de çıkıştan hedefe.
func _open_map_popup() -> void:
	if _map_popup != null or _session == null:
		return
	var origin := _session.journey_origin_id
	var destination := _session.journey_destination_id
	var path := PackedVector2Array()
	var parts := _journey.terrain_key.split("|")
	if parts.size() == 2:
		path = WorldMapData.get_route_path(origin, String(parts[1] if String(parts[0]) == origin else parts[0]))
	if path.is_empty() and origin != destination:
		path = WorldMapData.get_route_path(origin, destination)
	var progress := 0.0
	if _journey.terrain_days > 0:
		progress = clampf(_terrain_day() / float(_journey.terrain_days), 0.0, 1.0)
	_map_popup = MapPopup.new().setup(origin, destination, path, progress)
	_map_popup.view.hour = _clock.get_hour_of_day()
	_map_popup.view.trail = _session.map_trail
	_map_popup.view.camps = _session.journey_camps
	_map_popup.view.graves = _session.map_graves()
	_map_popup.closed.connect(func(): _map_popup = null)
	add_child(_map_popup)

func _show_waybook() -> void:
	for child in get_children():
		if child is WaybookPanel:
			return
	add_child(WaybookPanel.new().setup(_session))

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

	# Havaya karşı küçük kararlar (Y-B05) ve gece ışığı (Y-C20): günün havasına
	# ve saate göre yeniden kurulur.
	_weather_row = HBoxContainer.new()
	_weather_row.add_theme_constant_override("separation", 4)
	column.add_child(_weather_row)
	_light_row = HBoxContainer.new()
	_light_row.add_theme_constant_override("separation", 4)
	column.add_child(_light_row)

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
	var bottom_height := WaybookTheme.HUD_RULE_HEIGHT
	if _hud != null and _hud.get_child_count() > 0:
		var bottom := _hud.get_child(_hud.get_child_count() - 1) as Control
		if bottom != null:
			bottom_height = bottom.size.y
	var y := _orders_layer.size.y - bottom_height - WaybookTheme.HUD_RULE_HEIGHT - _command_panel.size.y - margin
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
	var can_push := _session == null or _session.can_push_pace() or is_equal_approx(_pace, PACE_FAST)
	for index in PACE_COMMAND_COUNT - 1:
		_pace_buttons[index].disabled = not _orders_enabled
	fast.disabled = not can_push or not _orders_enabled
	if _debt_button != null:
		_debt_button.disabled = not _orders_enabled
	_meal_policy_button.disabled = not _orders_enabled
	var command_key := [
		can_push, "" if _session == null else _session.meal_policy_mode, TranslationServer.get_locale()
	]
	if command_key != _last_command_key:
		_last_command_key = command_key
		fast.tooltip_text = (
			"%s (%d)" % [tr("UI_ROAD_CMD_FAST"), PACE_COMMAND_COUNT]
			if can_push else tr("UI_ROAD_ORDER_FAST_LOCKED")
		)
		if _session != null:
			_meal_policy_button.text = "%s: %s" % [
				tr("UI_ROAD_ORDER_MEAL"),
				tr(MEAL_POLICY_LABELS.get(_session.meal_policy_mode, "UI_MEAL_POLICY_ALL")),
			]
	if _session != null:
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
	var key := [locked, TranslationServer.get_locale()]
	if key == _last_talk_key:
		return
	_last_talk_key = key
	_talk_merchant_button.tooltip_text = (
		tr("UI_ROAD_CMD_TALK_MERCHANT_LOCKED") if locked
		else "%s (%d)" % [tr("UI_ROAD_CMD_TALK_MERCHANT"), PACE_COMMAND_COUNT + 1]
	)

## Kısayollar: 1-6 emirler, F2 tempoyu bir üst kademeye çeviriyor (kumandada
## LB). Hepsinin ekranda bir düğmesi var - tuş yalnızca kestirme.
func _input(event: InputEvent) -> void:
	_release_auto_pause(event)
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

	# Tab: kontrol panelinde Durum ile Kadro arasında gidip gelir.
	if key_event.keycode == KEY_TAB:
		var on_status := _control_panel != null and _control_panel.get_active_tab() == RoadControlPanel.TAB_STATUS
		_on_status_toggled(not on_status)
		accept_event()
		return

	if key_event.keycode == WAYBOOK_KEY:
		_show_waybook()
		accept_event()
		return

	if key_event.keycode == MAP_KEY:
		_open_map_popup()
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
	_engine.director = RoadDirector.new()
	_engine.director.heavy_scale = _session.get_event_severity()
	_current_event = null
	_journey_finished = false

	# Kontrol paneli `_build_ui()` sırasında kuruldu, ama o an henüz gerçek
	# oturum yoktu (`_session` burada ilk kez atanıyor). Gerçek oturum
	# eldeyken şimdi dolduruluyor.
	if _control_panel != null:
		_control_panel.set_session(_session)

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
	_terrain = RouteTerrain.build(_route_key, _journey_length_days, _session.journey_origin_id, _session.journey_season(), _session.journey_shortcut)
	_band.set_route(_terrain)
	_journey.terrain_key = _route_key
	_journey.terrain_days = _journey_length_days
	_band.set_heading(1.0, true)
	_refresh_memorials()
	_announce_route_memory()
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
	_refresh_pair_spacing()
	_caravan.set_heading(1.0)
	_caravan.set_leader_offset(0.0)
	_turn_event_after = null
	NodeUtil.clear_children(_card_panel)
	NodeUtil.clear_children(_haggle_holder)
	NodeUtil.clear_children(_combat_holder)
	_combat_holder.visible = false
	_set_combat_view(false)
	_band.visible = true
	NodeUtil.clear_children(_recruit_holder)
	NodeUtil.clear_children(_arrival_panel)
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
	if _engine != null and _engine.director != null:
		_engine.director.heavy_scale = _session.get_event_severity()
	_session.journey_snapshot = {}
	# Geri dönmüş bir seferde oturumun çıkışı ve hedefi aynı şehir; arazi
	# ve hava yolun kendi anahtarından (bkz. JourneyController.terrain_key).
	if _journey.terrain_key.is_empty():
		_journey.terrain_key = _route_key
		_journey.terrain_days = _journey_length_days
	elif _journey.terrain_key != _route_key or _journey.terrain_days != _terrain.total_days:
		_route_key = _journey.terrain_key
		_terrain = RouteTerrain.build(_route_key, maxi(1, _journey.terrain_days), _session.journey_origin_id, _session.journey_season(), _session.journey_shortcut)
		_band.set_route(_terrain)
	_band.set_heading(_journey.heading, true)
	_caravan.set_heading(_journey.heading)
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
	_refresh_signal_icon()
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
	NodeUtil.clear_children(_log_list)
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

	# Kamp kurulurken ve sökülürken insanlar yürürken saat kampın yavaş
	# akışında değil normal hızda akıyor; yürüyüş de oyun hızıyla hızlanıyor.
	_caravan.set_gather_time_scale(_clock.get_speed())
	if _can_time_flow():
		var transitioning := _caravan.is_camp_transitioning()
		var hours := _clock.advance(delta, maxf(1.0, _clock.get_speed()) if transitioning else -1.0)
		_advance_position(hours, delta)
		_tick_signals(hours)
		_tick_night(hours)
		_process_elapsed_days()
		_update_camp_state()
	else:
		_walk_direction = 0.0
		_caravan.set_ground_speed(0.0)
		_caravan.set_leader_motion(0.0, false)

	_update_chatter(delta)
	_update_light_glow()
	_refresh_time_ui()
	# Gece çökünce ortam değişir; çağrı aynı katmanda hiçbir şey yapmaz.
	_refresh_ambience()
	_refresh_modal()

## Kamp eylem paneli (Y-B12): diziliş ve akşamın iki eylemi; ardından belki
## bir hikâye. Nöbet ertesi günün tehlike payını düşürür.
const CAMP_WATCH_DANGER: float = 0.06
var _camp_panel: CampActionsPanel = null

func _open_camp_panel() -> void:
	_camp_panel = CampActionsPanel.new().setup(_session)
	_camp_panel.confirmed.connect(func(formation: Array, actions: Array):
		_session.log_beat(GameSession.BEAT_LOG_DECISION, "camp")
		_session.set_formation(formation[0], formation[1], formation[2])
		for action in _session.apply_camp_actions(actions):
			if action == GameSession.CAMP_ACTION_WATCH:
				_signal_danger_bonus = maxf(_signal_danger_bonus - CAMP_WATCH_DANGER, -SIGNAL_DANGER_CAP)
				_watch_day = _session.total_days_elapsed
			_add_log(tr("UI_CAMP_DONE") % tr(String(CampActionsPanel.ACTION_KEYS[action])), OUTCOME_COLOR)
		_camp_panel = null
		_refresh_state()
		var teller := _session.roll_camp_story()
		if teller != null:
			_open_story_panel(teller)
		else:
			_open_diary_panel())
	add_child(_camp_panel)

## Günün satırı (Y-B08): kampın son anı, hikâyeden sonra. Zaman durur.
var _diary_panel: DiaryPanel = null

func _open_diary_panel() -> void:
	_diary_panel = DiaryPanel.new().setup(_session.diary_candidates())
	_diary_panel.chosen.connect(func(key: String, args: Array):
		_session.log_beat(GameSession.BEAT_LOG_DECISION, "diary")
		_session.write_diary(key, args)
		if not key.is_empty():
			var entry := {"kind": CaravanLedger.KIND_DIARY, "cause": key, "args": args}
			_add_log(tr("UI_ROAD_DIARY_WRITTEN") % CaravanLedger.diary_text(entry), OUTCOME_COLOR)
		_diary_panel = null)
	add_child(_diary_panel)

## Kamp ateşi hikâyesi (R1 #3, Y-C17): bir karar anı, zaman durur.
var _story_panel: CampStoryPanel = null

func _open_story_panel(teller: CharacterData) -> void:
	_story_panel = CampStoryPanel.new().setup(teller)
	_story_panel.chosen.connect(func(choice: String):
		_session.resolve_camp_story(teller, choice)
		var key := "UI_ROAD_STORY_LISTENED" if choice == CampStory.CHOICE_LISTEN else ("UI_ROAD_STORY_OWN" if choice == CampStory.CHOICE_OWN_TALE else "UI_ROAD_STORY_SLEPT")
		_add_log(tr(key) % teller.character_name, OUTCOME_COLOR)
		_story_panel = null
		_open_diary_panel())
	add_child(_story_panel)

## --- Bedelli geri çekilme (Y-C07) ---
const RETREAT_MORALE: int = -3
const RETREAT_CARGO_SHARE: float = 0.34
var _combat_retreat_kind: String = ""

## Yük: her ticaret malının üçte biri bırakılır. Vagon: bir vagon feda edilir
## (enkazı yolda kalır). Artçı: bedeli savaşta ödendi. Bedava: ayı kovalamadı.
func _apply_retreat_cost(kind: String) -> void:
	if kind == CombatEncounter.RETREAT_CARGO:
		for item in ItemCatalog.get_trade_goods():
			if item.item_id == GameSession.PROVISIONS_ITEM_ID:
				continue
			var have := _session.get_total_quantity(item.item_id)
			if have > 0:
				_session.remove_from_cargo_or_bags(item.item_id, maxi(1, int(ceil(float(have) * RETREAT_CARGO_SHARE))))
		_add_log(tr("UI_ROAD_RETREAT_CARGO"), LOCKED_COLOR)
	elif kind == CombatEncounter.RETREAT_WAGON:
		if _session.caravan.lose_wagons(1) > 0:
			_session.add_memorial(GameSession.MEMORIAL_WRECK)
			_session.note_beat(GameSession.BEAT_WAGON)
			_add_log(tr("UI_ROAD_RETREAT_WAGON"), LOCKED_COLOR)
		else:
			_add_log(tr("UI_ROAD_RETREAT_NO_WAGON"), LOCKED_COLOR)
	elif kind == CombatEncounter.RETREAT_REARGUARD:
		_add_log(tr("UI_ROAD_RETREAT_REARGUARD"), LOCKED_COLOR)
	else:
		_add_log(tr("UI_ROAD_RETREAT_FREE"), OUTCOME_COLOR)

## Yoldaş notu: günlüğe satır, kişisi varsa başının üstünde baloncuk (R1 #4).
func _add_companion_note(note: Dictionary) -> void:
	var line: String = tr(String(note["key"])) % note["args"]
	_add_log(line, OUTCOME_COLOR)
	var who_id := String(note.get("who", ""))
	if who_id.is_empty() or _clock.get_speed() >= CHAT_BALLOON_MAX_SPEED or _balloon_layer.get_child_count() >= MAX_BALLOONS:
		return
	for character in _session.get_party():
		if character.character_id == who_id:
			var figure := _caravan.get_figure_of(character)
			if figure != null:
				_balloon_layer.add_child(RoadBalloon.new().setup(figure, line))

## Kolondaki çiftlerin aralığı bağlarından (R1 #2). Sıra oyuncusuz parti sırası.
func _refresh_pair_spacing() -> void:
	var walkers: Array[CharacterData] = []
	for character in _session.get_party():
		if not character.is_player:
			walkers.append(character)
	var scales: Array[float] = []
	var index := 0
	while index < walkers.size():
		if index + 1 < walkers.size():
			scales.append(CompanionLife.pair_gap_scale(_session.get_bond(walkers[index], walkers[index + 1])))
		else:
			scales.append(1.0)
		index += RoadCaravan.MAX_ABREAST
	_caravan.set_pair_gap_scales(scales)

## --- Yanına yürü, konuş (görev R1 #1, Y-B01) ---
## Lider bir yoldaşın yanında `CHAT_DWELL_SECONDS` gerçek saniye kalırsa yoldaş
## konuşur: baloncuk ve günlük satırı, bağ günde en fazla +1. Tıklama yok -
## yanında yürümek zaten karar (ve lideri o dikkat bölgesine taşır). Hızlı
## akışta baloncuk açılmaz, satır günlüğe düşer.
const CHAT_DWELL_SECONDS: float = 1.2
const CHAT_RADIUS_HEIGHTS: float = 0.9
const CHAT_BALLOON_MAX_SPEED: float = 1.5
const MAX_BALLOONS: int = 2
var _balloon_layer: Control
var _chat_target: CharacterData = null
var _chat_dwell: float = 0.0
var _chat_rng := RandomNumberGenerator.new()

func _update_chatter(delta: float) -> void:
	if _session == null or _caravan == null or _has_open_panel() or not _caravan.visible:
		_chat_dwell = 0.0
		return
	var near := _caravan.companions_near(_caravan.get_person_height() * CHAT_RADIUS_HEIGHTS)
	var who: CharacterData = near[0] if not near.is_empty() else null
	if who != _chat_target:
		_chat_target = who
		_chat_dwell = 0.0
		return
	if who == null or who.last_chat_day == _session.total_days_elapsed:
		return
	_chat_dwell += delta
	if _chat_dwell < CHAT_DWELL_SECONDS:
		return
	_chat_dwell = 0.0
	_chat_rng.seed = hash("chat|%s|%d" % [who.character_id, _session.total_days_elapsed])
	var picked := RoadChatter.pick(who, {
		"day": _session.total_days_elapsed, "weather": _weather,
		"night": JourneyClock.darkness_for_hour(_clock.get_hour_of_day()) > 0.5,
	}, _chat_rng)
	if picked.is_empty():
		return
	var first_meeting := who.rapport == 0
	RoadChatter.apply(who, picked, _session.total_days_elapsed)
	var line := tr(String(picked["key"]))
	_add_log(tr("UI_ROAD_CHAT_LINE") % [who.character_name, line])
	if first_meeting and not who.backstory_id.is_empty():
		_add_log(tr("UI_ROAD_CHAT_BACKSTORY") % [who.character_name, tr(String(CharacterData.BACKSTORY_LABEL_KEYS.get(who.backstory_id, "")))], OUTCOME_COLOR)
	if _clock.get_speed() < CHAT_BALLOON_MAX_SPEED and _balloon_layer.get_child_count() < MAX_BALLOONS:
		var figure := _caravan.get_figure_of(who)
		if figure != null:
			_balloon_layer.add_child(RoadBalloon.new().setup(figure, line))

## Kervan tempoyla kendi yürür; giriş yalnızca lideri kolon içinde
## gezdirir (bkz. yukarıdaki "Yürümek" notu). Kampta kervan durur, lider
## yine gezebilir.
##
## Mesafe geçen oyun saatinden ölçülüyor, gerçek kareden değil: hız tuşu
## (0.5x-3x) hem saati hem yolu aynı oranda hızlandırır, yoksa hızlı akışta
## günler yola göre daha hızlı akar ve kervan hep aç kalırdı.
func _advance_position(hours: float, delta: float) -> void:
	_walk_direction = 0.0
	if hours <= 0.0:
		_caravan.set_ground_speed(0.0)
		return
	var before := _terrain_day()
	# Kamp kalkınca kervan herkes yerine dönüp binene kadar beklemiyordu:
	# dönenler kayan zeminin üstünde ekrandaki yerlerine akıyor, manzara
	# bir anda hızlanıyor gibi görünüyordu (kullanıcı raporu). Saat akıyor,
	# yol beklemekte.
	if not _camping and not _caravan.is_breaking_camp():
		_walk_at(_pace, hours)
	var day_step := absf(_terrain_day() - before)
	if delta > 0.0:
		_update_world_scale(delta, day_step / delta)
	# Kervanın zemine göre hızı (şerit pikseli/saniye) - manzara bununla
	# kayıyor, bacaklar ve tekerlek bununla adım atıyor, lider buna göre
	# yürüyor (bkz. _move_leader). Üçü aynı sayı: ayak zeminde kaymaz.
	var column_speed := 0.0
	if delta > 0.0:
		column_speed = day_step * _band.get_pixels_per_day() / delta
	_caravan.set_ground_speed(column_speed)
	_band.set_dust_motion(column_speed / maxf(_caravan.get_walk_ground_speed(), 1.0))
	# Yorgun bekleyiş (N31d): kervan durmuş ve kamp yok.
	_caravan.set_tired(column_speed < 1.0 and not _camping and not _caravan.is_breaking_camp())
	_move_leader(delta, column_speed)

## Manzaranın gün->piksel ölçeği. Kervan normal tempoda sakin bir
## yürüyüşle (`WalkFigure.WALK_CADENCE`) ilerleyecek kadar: zemin
## figürün boyuna göre ölçülüyor, ekranın boyuna göre değil. Hızlı tempoda
## ya da hızlandırılmış saatte gerçek mesafe (gün) aynen birikiyor ama
## manzara en yavaş yürüyenin (genelde öküz) tempolu yürüyüşünü
## aşmıyor - ölçek küçülüyor. Bacak hızlansaydı kervan koşardı, manzara
## hızlansa bacak yetişmezdi ve ayak kayardı. Yavaş ucunda da tersi:
## ağır bir yürüyüşün altına inmiyor.
## Manzaranın ekranda kayacağı hız: doğal hız, ağır yürüyüş ile en yavaş
## yürüyenin tempolu yürüyüşü arasına kenetli. Saf fonksiyon - test okuyor.
static func scenic_ground_speed(natural_px_s: float, amble_px_s: float, brisk_px_s: float) -> float:
	if natural_px_s <= 0.0:
		return 0.0
	return clampf(natural_px_s, minf(amble_px_s, brisk_px_s), brisk_px_s)

## Manzara ölçeği kervan yürümüyorken (kamp, "Dur" emri) ya da yürüyüş yeni
## başlarken değişmemeli: `hedef = zemin hızı / gün hızı` ve gün hızı sıfıra
## yaklaşırken hedef sonsuza gidiyordu - ölçek patlıyor, duraklar (kule)
## kamp kurulunca kadrajdan bir anda kaçıyordu (görev 12.2b). Saf fonksiyon.
static func world_scale_holds(day_rate: float, eased_day_rate: float) -> bool:
	return day_rate <= 1e-5 or eased_day_rate < day_rate * 0.5

func _update_world_scale(delta: float, day_rate: float) -> void:
	var blend := 1.0 - exp(-delta / DAY_RATE_EASE_SECONDS)
	_day_rate = lerpf(_day_rate, day_rate, blend)
	if _world_scale_set and world_scale_holds(day_rate, _day_rate):
		return
	var natural := _caravan.get_walk_ground_speed() * JourneyClock.REAL_SECONDS_PER_DAY
	if natural <= 0.0:
		return
	var target := _band.get_pixels_per_day() if _world_scale_set else natural
	if _day_rate > 1e-5:
		var ground := scenic_ground_speed(
			_day_rate * natural,
			_caravan.get_amble_ground_speed(), _caravan.get_brisk_ground_speed()
		)
		target = ground / _day_rate
	if not _world_scale_set:
		_world_scale_set = true
		_band.set_pixels_per_day(target)
		return
	var current := _band.get_pixels_per_day()
	_band.set_pixels_per_day(lerpf(current, target, 1.0 - exp(-delta / WORLD_SCALE_EASE_SECONDS)))

## Klavye/kumanda yönü dokunma hedefinden önce gelir: ikisi aynı anda
## verilirse eldeki tuş kazanır ve hedef unutulur.
func _move_leader(delta: float, column_speed: float) -> void:
	# Lider ateşte (ya da atından inip biniyor): kolonda gezdirilecek biri yok.
	if _caravan.is_leader_at_camp():
		_has_leader_target = false
		_caravan.set_leader_motion(_journey.heading * column_speed, false)
		return
	var direction := 0.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction -= 1.0
	direction = clampf(direction + GamepadCursor.get_move_axis(), -1.0, 1.0)

	var heading := _journey.heading
	var goal_direction := 0.0
	if not is_zero_approx(direction):
		_has_leader_target = false
		goal_direction = direction
	elif _has_leader_target:
		# Hedef kolonun bir yeri; ekranda hangi yöne düştüğü kervanın
		# yüzüne bağlı (geri dönüşte kolon aynalı).
		var gap := _leader_target - _leader_offset
		if absf(gap) < 0.5:
			_has_leader_target = false
		else:
			goal_direction = signf(gap) * heading
	var ground := heading * column_speed
	if is_zero_approx(goal_direction):
		_caravan.set_leader_motion(ground, false)
		return
	var screen := leader_screen_speed(goal_direction, heading, column_speed, _leader_ground_speed())
	var step := screen * delta * heading
	var target := _leader_offset + step
	if _has_leader_target and is_zero_approx(direction):
		target = move_toward(_leader_offset, _leader_target, absf(step))
		if is_equal_approx(target, _leader_target):
			_has_leader_target = false
	var previous := _leader_offset
	_leader_offset = clampf(target, -_caravan.get_column_length(), 0.0)
	_caravan.set_leader_offset(_leader_offset)
	# Figürün yüzü ve adımı zemine göre hızından: kolonun sonuna varıp duran
	# lider kervanla birlikte yürür, geriye giden lider arkasını döner.
	var moved := (_leader_offset - previous) * heading / maxf(delta, 0.0001)
	_caravan.set_leader_motion(ground + moved, true)
	_refresh_attention_zone()

## Liderin kolondaki ekran hızı (piksel/saniye, işaretli). Lider **zemine
## göre** her iki yönde aynı hızla gidiyor: kervanın ters yönüne giderken
## kolonun akışı buna eklenir, kervanla aynı yöne giderken çıkar. Eskiden
## ekran hızı sabitti (oyun saati başına), yani geri giden lider zemine
## göre neredeyse yerinde sayıyor, ileri gelen koşuyordu - "at ile geri
## dönmek istediğimde yavaşım" şikâyeti tam buydu.
static func leader_screen_speed(
	direction: float, heading: float, column_speed: float, ground_speed: float
) -> float:
	var screen := direction * ground_speed - heading * column_speed
	var floor_speed := ground_speed * LEADER_MIN_SCREEN_SHARE
	if screen * direction < floor_speed:
		screen = direction * floor_speed
	return screen

func _leader_ground_speed() -> float:
	return _caravan.get_leader_brisk_speed()

## Kervanın arazideki şimdiki günü (bkz. JourneyController.terrain_day).
func _terrain_day() -> float:
	return _journey.terrain_day()

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
	_band.set_view_rect(visible_rect_in(_band, _world.get_global_rect()))

## Ekranın bir dikdörtgeninin (global) bir düğümün yerel uzayındaki karşılığı -
## ölçeklenmiş şeridin o an gördüğü alan.
static func visible_rect_in(node: CanvasItem, global_rect: Rect2) -> Rect2:
	var xf := node.get_global_transform() if node.is_inside_tree() else node.get_transform()
	var inv := xf.affine_inverse()
	return Rect2(inv * global_rect.position, Vector2.ZERO).expand(inv * global_rect.end)

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
	var terrain_factor := 1.0 if _terrain == null else _terrain.speed_factor_at(_terrain_day())
	# Fırtınada sığınan kervan beklerken yürümez (Y-B05).
	if _clock.total_hours < _shelter_until_hours:
		return
	var weather_multiplier := RouteWeather.pace_multiplier(_weather) * _weather_call_rate()
	var effective := JourneyController.effective_rate(
		rate, weather_multiplier,
		_session.get_caravan_theoretical_speed(), terrain_factor, _hungry
	)
	_journey.walk(effective, hours)
	_sync_days_remaining()
	_session.set_road_position(_route_key, _session.journey_origin_id, _terrain_day(), maxi(1, _journey.terrain_days))
	_read_nearby_memorials()
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
		hours, _attention_zone, _signal_rng, _session.get_affliction_count(), _role_cover(),
		_night_signal_scale()
	)
	for kind in outcome["appeared"]:
		_session.log_beat(GameSession.BEAT_LOG_INFO, "signal:" + String(kind))
		_caravan.react_look(RoadSignals.get_zone_for(String(kind)))
		_add_log(tr(RoadSignals.get_notice_key(String(kind))))
		_auto_pause()
	for i in (outcome["resolved"] as Array).size():
		var kind := String(outcome["resolved"][i])
		var by_zone := String(outcome["resolved_by_role"][i])
		if not by_zone.is_empty():
			var holder := _session.get_duty_holder(_role_for_zone(by_zone))
			if holder != null:
				_add_log(tr("UI_ROAD_ROLE_ATTENDED") % holder.character_name, OUTCOME_COLOR)
		_apply_signal_resolution(String(outcome["resolved_truths"][i]))
		_flash_signal_icon(kind, ArtPalette.UI_SIGNAL_RESOLVED)
	for i in (outcome["escalated"] as Array).size():
		var kind := String(outcome["escalated"][i])
		_apply_signal_escalation(kind, String(outcome["escalated_truths"][i]))
		_flash_signal_icon(kind, ArtPalette.UI_SIGNAL_ESCALATED)
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
##
## Görev Y-B03: sonuç işaretin türüne değil gizli gerçeğine göre. Bazı gerçekler
## boştur (yanlış alarm, çobanlar, boş kehanet) - ihmal ücretsiz kalır, ama
## hangisi olduğunu bilmek için bakmak gerekir.
func _apply_signal_escalation(_kind: String, truth: String) -> void:
	_add_log(tr(String(RoadSignals.TRUTH_ESCALATED_KEYS.get(truth, ""))), LOCKED_COLOR)
	match truth:
		"axle":
			_session.caravan.damage_wagons(1)
		"loose_load":
			_lose_some_cargo(2)
		"tired":
			_session.change_stress(SIGNAL_STRAGGLER_STRESS)
		"sick":
			_session.change_stress(SIGNAL_STRAGGLER_STRESS + 2)
			_session.caravan.change_morale(-3)
		"stranger":
			_session.change_provisions(-3)
		"bandit_camp":
			# Duman bir pusunun habercisi: görmezden gelinirse yolun
			# tehlikesi artıyor, yani savaş ihtimali yükseliyor.
			_signal_danger_bonus = minf(
				_signal_danger_bonus + RoadSignals.SMOKE_DANGER_DELTA, SIGNAL_DANGER_CAP
			)
		"village_fire":
			_session.caravan.change_morale(-2)
		"true_omen":
			_signal_danger_bonus = minf(_signal_danger_bonus + SIGNAL_OMEN_DANGER, SIGNAL_DANGER_CAP)
	_refresh_state()

## Rol sahiplerinin baktığı bölgeler ve saatlik ihtimalleri (Y-B04): görev
## gücüyle ölçeklenir; rolü boş olan bölge kapsanmaz.
func _role_cover() -> Dictionary:
	var cover := {}
	for role in DutyCatalog.ROLES:
		var holder := _session.get_duty_holder(role)
		if holder != null:
			cover[String(DutyCatalog.ROLE_ZONES[role])] = RoadSignals.ROLE_RESOLVE_PER_HOUR * DutyCatalog.get_duty_power(holder, role)
	return cover

## --- Yolun hafızası (görevler Y-B11, R2) ---
const MEMORIAL_READ_DAYS: float = 0.08
var _read_memorial_ids: Dictionary = {}

func _refresh_memorials() -> void:
	if _band == null or _session == null:
		return
	var list: Array = []
	for m in _session.memorials_on(_route_key):
		list.append({"day": GameSession.day_for_share(_route_key, _session.journey_origin_id, float(m["share"]), maxi(1, _journey.terrain_days)), "kind": String(m["kind"])})
	_band.set_memorials(list)

## Yanından geçilen anıt bir kez okunur; ön bölgede olan adını ve sebebini
## okur, başka yerde olan yalnızca bir taş görür (dikkat sonludur).
func _read_nearby_memorials() -> void:
	var here := _terrain_day()
	for m in _session.memorials_on(_route_key):
		var id := String(m["id"])
		if _read_memorial_ids.has(id) or String(m["kind"]) == GameSession.MEMORIAL_ASH:
			continue
		var day := GameSession.day_for_share(_route_key, _session.journey_origin_id, float(m["share"]), maxi(1, _journey.terrain_days))
		if absf(day - here) > MEMORIAL_READ_DAYS:
			continue
		_read_memorial_ids[id] = true
		if _attention_zone != RoadAttention.ZONE_FRONT:
			_add_log(tr("UI_MEM_GLIMPSE"))
			continue
		var kind := String(m["kind"])
		if kind == GameSession.MEMORIAL_WRECK:
			_add_log(tr("UI_MEM_WRECK_READ") % (_session.total_days_elapsed - int(m["day"])), OUTCOME_COLOR)
		else:
			var cause := String(m.get("cause", ""))
			var key := "UI_MEM_CAIRN_READ" if kind == GameSession.MEMORIAL_CAIRN else "UI_MEM_GRAVE_READ"
			_add_log(tr(key) % [String(m["name"]), tr(cause) if not cause.is_empty() else "", int(m.get("generation", 1))], OUTCOME_COLOR)

## Yolun seni hatırlaması (R2 #19): sefer başında bir satır.
func _announce_route_memory() -> void:
	var memory: Dictionary = _session.route_memory.get(_route_key, {})
	var trips := int(memory.get("trips", 0))
	if trips <= 0:
		return
	var graves := 0
	for m in _session.memorials_on(_route_key):
		if String(m["kind"]) == GameSession.MEMORIAL_GRAVE or String(m["kind"]) == GameSession.MEMORIAL_CAIRN:
			graves += 1
	_add_log(tr("UI_MEM_ROUTE_KNOWN") % [trips, _session.total_days_elapsed - int(memory.get("last_day", 0))])
	if graves > 0:
		_add_log(tr("UI_MEM_ROUTE_GRAVES") % graves, OUTCOME_COLOR)

## --- Havaya karşı küçük kararlar (görev Y-B05) ---
var _weather_row: HBoxContainer
var _light_row: HBoxContainer
var _weather_call: String = ""
var _weather_call_day: int = -99
var _shelter_until_hours: float = -1.0

func _weather_call_rate() -> float:
	if _weather_call_day != _session.total_days_elapsed:
		return 1.0
	if _weather_call == WeatherCalls.LIGHT_IN_FOG:
		# Işık sisin yavaşlığını kaldırır.
		return 1.0 / maxf(0.01, RouteWeather.pace_multiplier(_weather))
	return WeatherCalls.rate_multiplier(_weather_call)

func _refresh_weather_calls() -> void:
	if _weather_row == null:
		return
	NodeUtil.clear_children(_weather_row)
	if _weather_call_day == _session.total_days_elapsed:
		var chosen := Label.new()
		chosen.text = tr(String(WeatherCalls.LABEL_KEYS.get(_weather_call, "")))
		chosen.modulate = ArtPalette.UI_HUD_NOTE
		_weather_row.add_child(chosen)
		return
	for call in WeatherCalls.options_for(_weather):
		var button := Button.new()
		button.theme_type_variation = WaybookTheme.HUD_GHOST_BUTTON
		button.text = tr(String(WeatherCalls.LABEL_KEYS[call]))
		if call == WeatherCalls.LIGHT_IN_FOG:
			var reason := _best_light_reason()
			button.disabled = not reason.is_empty()
			button.tooltip_text = tr(reason) if not reason.is_empty() else ""
		button.pressed.connect(_on_weather_call.bind(call))
		_weather_row.add_child(button)

func _on_weather_call(call: String) -> void:
	_weather_call = call
	_weather_call_day = _session.total_days_elapsed
	if call == WeatherCalls.EARLY_START:
		_session.caravan.stamina = clampi(_session.caravan.stamina + WeatherCalls.EARLY_START_STAMINA, 0, CaravanState.MAX_STAMINA)
		_session.change_party_fatigue(GameSession.FATIGUE_EARLY_START)
	elif call == WeatherCalls.BEAT_THE_RAIN:
		_session.change_stress(WeatherCalls.BEAT_THE_RAIN_STRESS)
	elif call == WeatherCalls.SLOW_IN_FOG:
		_signal_danger_bonus = maxf(_signal_danger_bonus - WeatherCalls.SLOW_FOG_DANGER, -SIGNAL_DANGER_CAP)
	elif call == WeatherCalls.LIGHT_IN_FOG:
		_light(_best_light_kind())
	elif call == WeatherCalls.SHELTER:
		_shelter_until_hours = _clock.total_hours + WeatherCalls.SHELTER_HOURS
		# Sığınan kervan fırtınanın moral ısırığını yemez.
		_session.caravan.change_morale(-RouteWeather.morale_bite(_weather))
	if WeatherCalls.damages_wagon(call, _session.total_days_elapsed, _route_key):
		_session.caravan.damage_wagons(1)
		_add_log(tr("UI_WX_WAGON_HURT"), LOCKED_COLOR)
	_add_log(tr("UI_WX_CHOSEN") % tr(String(WeatherCalls.LABEL_KEYS[call])), OUTCOME_COLOR)
	_refresh_weather_calls()
	_refresh_state()

## --- Gece yürüyüşü ve ışık (görev Y-C20) ---
## Kervan gece de yürür (kamp kurmadıkça); karanlıkta yürümek takat yer ve yolu
## tekinsizleştirir. Fener (yağ) ya da meşale (iki tane) o geceyi aydınlatır:
## risk kalkar, ışık yolda görünür. Meşale daha parlak ve hayvanı ürkütür.
const NIGHT_STAMINA_PER_HOUR: float = 0.6
const DARK_DANGER: float = 0.05
const TORCH_BEAST_DANGER: float = -0.03
var _light_kind: String = ""
var _light_night: int = -99
var _night_stamina_debt: float = 0.0
var _night_fatigue_debt: float = 0.0
var _light_glow: Control

func _is_dark() -> bool:
	return JourneyClock.darkness_for_hour(_clock.get_hour_of_day()) >= 0.5

func _best_light_kind() -> String:
	if _session.get_light_block_reason(GameSession.LIGHT_LANTERN).is_empty():
		return GameSession.LIGHT_LANTERN
	return GameSession.LIGHT_TORCH

func _best_light_reason() -> String:
	return _session.get_light_block_reason(_best_light_kind())

func _light(kind: String) -> void:
	if _session.light_for_night(kind):
		_light_kind = kind
		_light_night = _session.total_days_elapsed
		_light_lit = true
		_add_log(tr("UI_LIGHT_LIT_LANTERN" if kind == GameSession.LIGHT_LANTERN else "UI_LIGHT_LIT_TORCH"), OUTCOME_COLOR)
	_refresh_light_row()

func _refresh_light_row() -> void:
	if _light_row == null:
		return
	NodeUtil.clear_children(_light_row)
	if not _is_dark() or _camping or _light_lit:
		return
	for kind in [GameSession.LIGHT_LANTERN, GameSession.LIGHT_TORCH]:
		var button := Button.new()
		button.theme_type_variation = WaybookTheme.HUD_GHOST_BUTTON
		button.text = tr("UI_LIGHT_LANTERN" if kind == GameSession.LIGHT_LANTERN else "UI_LIGHT_TORCH")
		var reason := _session.get_light_block_reason(kind)
		button.disabled = not reason.is_empty()
		button.tooltip_text = tr(reason) if not reason.is_empty() else tr("UI_LIGHT_TOOLTIP")
		button.pressed.connect(_light.bind(kind))
		_light_row.add_child(button)

## Saat başı: karanlıkta ışıksız yürümek takat yer; şafakta ışık söner.
func _tick_night(hours: float) -> void:
	if _light_lit and not _is_dark():
		_light_lit = false
		_light_kind = ""
		_refresh_light_row()
	if _is_dark() and not _camping and not _light_lit and _light_row != null and _light_row.get_child_count() == 0:
		_refresh_light_row()
	if _is_dark() and not _camping and not _light_lit:
		_night_stamina_debt += NIGHT_STAMINA_PER_HOUR * hours
		var whole := int(_night_stamina_debt)
		if whole > 0:
			_night_stamina_debt -= whole
			_session.caravan.stamina = maxi(0, _session.caravan.stamina - whole)
		# Karanlıkta yürüyen beden de yorulur (Y-F01).
		_night_fatigue_debt = _session.accrue_night_fatigue(
			_night_fatigue_debt + GameSession.FATIGUE_NIGHT_PER_HOUR * hours
		)

## Yanan ışık yolda görünür: liderin başı hizasında yumuşak bir hale.
func _update_light_glow() -> void:
	if _balloon_layer == null or _caravan == null:
		return
	if _light_glow == null:
		_light_glow = Control.new()
		_light_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_light_glow.draw.connect(func():
			var torch := _light_kind == GameSession.LIGHT_TORCH
			var radius := (90.0 if torch else 64.0)
			var colour := Color(1.0, 0.62, 0.25) if torch else Color(1.0, 0.82, 0.5)
			for i in 5:
				var share := 1.0 - float(i) / 5.0
				_light_glow.draw_circle(Vector2.ZERO, radius * share, Color(colour, 0.06 + 0.05 * float(i))))
		_balloon_layer.add_child(_light_glow)
		_balloon_layer.move_child(_light_glow, 0)
	var leader := _caravan.get_visible_leader_figure()
	var show := _light_lit and _is_dark() and leader != null and _caravan.visible
	_light_glow.visible = show
	if not show:
		return
	var head := leader.get_global_transform_with_canvas() * Vector2(leader.size.x * 0.75, leader.size.y * 0.2)
	_light_glow.position = _balloon_layer.get_global_transform_with_canvas().affine_inverse() * head
	_light_glow.queue_redraw()

## Gecenin tehlike payı: ışıksız karanlık biraz tekinsiz, meşale hayvanı ürkütür.
func _night_danger_delta() -> float:
	if not _is_dark() or _camping:
		return 0.0
	if not _light_lit:
		return DARK_DANGER
	return TORCH_BEAST_DANGER if _light_kind == GameSession.LIGHT_TORCH else 0.0

## Akşam ve gece yol daha çok konuşur (Y-B02, kullanıcı notu); önlem alınmışsa
## (ateş yanıyor, nöbet kuruldu, fener ya da meşale yanıyor) artış düşer.
const NIGHT_SIGNAL_SCALE: float = 1.5
var _watch_day: int = -99
var _light_lit: bool = false

func _night_signal_scale() -> float:
	if JourneyClock.darkness_for_hour(_clock.get_hour_of_day()) < 0.5:
		return 1.0
	if _camping or _light_lit or _watch_day == _session.total_days_elapsed:
		return 1.0
	return NIGHT_SIGNAL_SCALE

func _role_for_zone(zone: String) -> String:
	for role in DutyCatalog.ROLE_ZONES:
		if String(DutyCatalog.ROLE_ZONES[role]) == zone:
			return String(role)
	return ""

## İlgilenilen işaretin gerçeği ortaya çıkar; iyi gerçekler küçük bir ödül.
const SIGNAL_OMEN_DANGER: float = 0.08
const SIGNAL_FOREWARNED: float = 0.05

func _apply_signal_resolution(truth: String) -> void:
	_add_log(tr(String(RoadSignals.TRUTH_RESOLVED_KEYS.get(truth, ""))), OUTCOME_COLOR)
	match truth:
		"bandit_camp", "true_omen":
			# Önceden görülen tehlike: yol biraz daha az tekinsiz.
			_signal_danger_bonus = maxf(_signal_danger_bonus - SIGNAL_FOREWARNED, -SIGNAL_DANGER_CAP)
		"village_fire":
			_session.caravan.change_morale(3)
			_session.change_reputation(1)
		"herders":
			_session.change_provisions(2)
		"stranger":
			_session.caravan.change_morale(2)
	_refresh_state()

## Gevşeyen yükten düşen: en ağır ticaret malından birkaç birim.
func _lose_some_cargo(units: int) -> void:
	var heaviest: Item = null
	for item in ItemCatalog.get_trade_goods():
		if item.item_id == GameSession.PROVISIONS_ITEM_ID or _session.get_total_quantity(item.item_id) <= 0:
			continue
		if heaviest == null or item.unit_weight > heaviest.unit_weight:
			heaviest = item
	if heaviest != null:
		_session.remove_from_cargo_or_bags(heaviest.item_id, mini(units, _session.get_total_quantity(heaviest.item_id)))
	else:
		_session.caravan.change_morale(-2)

## `journey_days_remaining` artık bağımsız bir sayaç değil, kat edilen
## yoldan türetilen bir gösterge - HUD, sapma maliyeti (get_days_travelled)
## ve varış kontrolü hep aynı mesafeyi okusun diye. Geri yürüyen bir kervan
## için "kalan yol" gerçekten uzar.
func _sync_days_remaining() -> void:
	_journey.sync_days_remaining(_session)

func _can_time_flow() -> bool:
	return (
		not _journey_finished and _current_event == null and not _has_open_panel()
		and not _caravan.is_turning() and not _auto_paused
	)

## Y-H07: yolda bir işaret ya da karşılaşma belirince zaman (ayar açıksa)
## oyuncu bir tuşa ya da tıklamaya basana kadar bekler.
var _auto_paused: bool = false

func _auto_pause() -> void:
	if not UserSettings.auto_pause_events or _auto_paused or not _is_live_journey:
		return
	_auto_paused = true
	_add_log(tr("UI_ROAD_AUTO_PAUSED"))

func _release_auto_pause(event: InputEvent) -> void:
	if not _auto_paused:
		return
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_auto_paused = false

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
	for note in _session.companion_notes:
		_add_companion_note(note)
	for note in _session.ailment_notes:
		_add_log(tr(String(note["key"])) % note["args"], LOCKED_COLOR)
	for item_id in _session.last_spoiled:
		var spoiled := ItemCatalog.get_item(String(item_id))
		_add_log(tr("UI_ROAD_GOODS_SPOILED") % [int(_session.last_spoiled[item_id]), spoiled.item_name if spoiled != null else String(item_id)])

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
	var extras: Array = _meal_panel.chosen_extras if _meal_panel != null else []
	for extra in _session.serve_meal_extras(extras):
		var dish := tr(String(extra["key"])) % [int(extra["units"]), absi(int(extra["amount"]))]
		_add_log(tr("UI_ROAD_MEAL_EXTRA_SERVED") % dish, OUTCOME_COLOR)
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
	# near_mezra, near_mine...): durak olaylarının ağırlığı ekranda gerçekten
	# o durak geçilirken artıyor - bkz. EventResolver.stop_context.
	var stop: String = RouteTerrain.STOP_NONE if _terrain == null else _terrain.segment_at(_terrain_day()).stop
	context.merge(EventResolver.stop_context(stop), true)
	# Irmak geçidi (R4 #16): su seviyesi bağlama girer; ön bölgede olan onu
	# önceden okur.
	if stop == RouteTerrain.STOP_FORD:
		var water_biome := _terrain.biome_at(minf(float(_journey.terrain_days), _terrain_day() + 0.5))
		var level := RouteFord.water_level(_route_key, _session.total_days_elapsed + 1, water_biome)
		context["water_level"] = float(level)
		if _attention_zone == RoadAttention.ZONE_FRONT:
			_add_log(tr("UI_FORD_SEEN") % tr(RouteFord.LEVEL_KEYS[level]))
	# Aynı desenin arazi hali (bkz. evt_hunting_trip) - o günün biyomu
	# stop_context'in yanına.
	var biome := "" if _terrain == null else _terrain.biome_at(_terrain_day())
	context.merge(EventResolver.biome_context(biome), true)
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
	if not _camping:
		return
	if _camp_ends_at_hours == JourneyController.CAMP_PENDING:
		# Herkes ateşe varınca kamp sayacı başlıyor.
		_camp_ends_at_hours = JourneyController.camp_ends_at(
			_camp_ends_at_hours, _clock.total_hours, _caravan.is_camp_settled(), CAMP_HOURS
		)
		if _camp_ends_at_hours == JourneyController.CAMP_PENDING:
			return
		_add_log(tr("UI_ROAD_CAMP_SETTLED") % _clock.get_clock_text(), OUTCOME_COLOR)
		_record_camp_on_map()
		# Kampın külü yolda kalır (Y-B11).
		_session.set_road_position(_route_key, _session.journey_origin_id, _terrain_day(), maxi(1, _journey.terrain_days))
		_session.add_memorial(GameSession.MEMORIAL_ASH)
		_refresh_memorials()
		_session.companion_notes = []
		_session.bond_group(_session.get_party(), CompanionLife.SHARED_CAMP)
		for note in _session.companion_notes:
			_add_companion_note(note)
		_refresh_pair_spacing()
		_open_camp_panel()
		return
	if _clock.total_hours < _camp_ends_at_hours:
		return

	var camp_result := _session.make_camp()
	_add_log(
		tr("UI_ROAD_CAMP_STRUCK") % [
			camp_result.provisions_spent, camp_result.stress_relief
		],
		OUTCOME_COLOR
	)
	_add_log(tr("UI_ROAD_CAMP_BREAK") % _clock.get_clock_text(), OUTCOME_COLOR)
	_session.log_beat(GameSession.BEAT_LOG_CAMP_END)
	_camping = false
	_band.set_camping(false)
	_caravan.set_camping(false)
	_refresh_state()

## Yol ekranından çıkılınca (varış, menü, yükleme) kamp ateşinin sesi
## yanında gitmesin: şehirde çıtırtı duyuluyordu.
func _exit_tree() -> void:
	AudioManager.stop_ambience()
	AudioManager.set_combat_duck(false)

## Kampın haritadaki yeri (görev Y-G09): yolun çizgisinde kervanın durduğu nokta.
func _record_camp_on_map() -> void:
	var state := _panel_state()
	var path: PackedVector2Array = state.get("path", PackedVector2Array())
	if path.size() >= 2:
		_session.record_journey_camp(WorldMapView.point_along(path, float(state.get("progress", 0.0))))

func _on_fire_lit(_index: int) -> void:
	AudioManager.play_sfx(AudioManager.SFX_FIRE_IGNITE)
	AudioManager.play_ambience(AudioManager.AMBIENCE_FIRE)

## Hava günden ve rotadan hesaplanıyor, saklanmıyor: aynı kaydı yeniden
## yükleyen oyuncu aynı havayı buluyor (bkz. RouteWeather). Biyom da
## okunuyor, çünkü gölde sis, dağda fırtına daha sık.
func _refresh_weather() -> void:
	var biome := ArtPalette.FALLBACK_BIOME
	if _terrain != null:
		biome = _terrain.biome_at(_terrain_day())
	# Gün numarası **yalnızca** `total_days_elapsed + 1`. İlk yazışta
	# `+ _current_day` de ekliyordum ve bu sessiz bir hataydı: `advance_day()`
	# zaten her gün `total_days_elapsed`'i artırıyor, yani ikisini toplamak
	# hava dizisini E+1, E+3, E+5 diye atlatıyordu. Planlayıcının tahmini
	# E+1, E+2, E+3 üzerinden hesaplandığı için hava payı yolda yaşananla
	# örtüşmez ve "doğru stokladım, yine aç kaldım" geri gelirdi.
	_weather = RouteWeather.at(_route_key, _session.total_days_elapsed + 1, biome)
	_band.set_weather(_weather)
	_band.set_winter(_session.journey_season() == MarketConditions.Season.WINTER)
	if _caravan != null:
		_caravan.set_weather(_weather)
	_refresh_weather_calls()
	_refresh_ambience()

## Ortam sesi (N31f): hava, gece ve kamp ateşinden; ateş yanarken ateş.
## Kampta ateşin sesi ateşin kendisine bağlı (yanınca `_on_fire_lit`, sönünce
## `fires_out` buraya döner); kamp sürerken tablo karışmaz.
func _refresh_ambience() -> void:
	if _clock == null or (_camping and not _caravan.is_breaking_camp()):
		return
	var night := JourneyClock.darkness_for_hour(_clock.get_hour_of_day()) > 0.5
	AudioManager.set_road_ambience(_weather, night, false)

## Yolun sonundaki kapı: varılacak yerleşimin kapısı (geri dönüşte yolun başı).
## Kapı gününün kendisi yolun ucu; geçit, varışta kolonun başındaki atlının tam önünde.
func _sync_arrival_gate() -> void:
	var heading := _journey.heading
	var place := WorldMapData.get_location_by_id(_session.journey_destination_id)
	var prop_id := place.gate_prop_id() if place != null else ""
	var end_day := float(_journey.terrain_days) if heading > 0.0 else 0.0
	var leader := _caravan.get_leader_figure()
	var head := _caravan.get_front_offset() - (leader.size.x * 0.5 if leader != null else 0.0)
	_band.set_arrival_gate(prop_id, end_day, head)

func _refresh_time_ui() -> void:
	if _clock == null:
		return

	_sync_orders_panel_safe_left()
	var phase := _clock.get_phase()
	_band.set_phase(phase, _clock.get_phase_progress())

	var progress := _get_route_progress()
	# Şerit arazinin kendi gününü okuyor, bacağınkini değil: geri dönen
	# kervan aynı yolu ters yönde yürüyor (bkz. JourneyController.heading).
	var terrain_day := _terrain_day()
	_band.set_route_progress(
		terrain_day / maxf(1.0, float(_journey.terrain_days)), terrain_day
	)
	_sync_arrival_gate()
	_progress_bar.value = progress
	var percent := int(round(progress * 100.0))
	if percent != _last_progress_percent:
		_last_progress_percent = percent
		_progress_bar.tooltip_text = tr("UI_ROAD_PROGRESS_TOOLTIP") % percent
	_position_encounter()

	# Kervan şeritten ışığı ve yürüme hızını alıyor: iki ayrı yerde
	# hesaplanırsa gece kervanı gündüz aydınlatılmış görünür.
	_caravan.set_light(_band.get_light())
	# Bacak hızı burada verilmiyor: `_advance_position` kervanın gerçek
	# zemin hızını (manzaranın kaydığı pikseli) doğrudan veriyor.

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
		biome = _terrain.biome_at(_terrain_day())
	var key := [biome, _weather, _pace_key, TranslationServer.get_locale()]
	if key == _last_conditions_key:
		return
	_last_conditions_key = key
	var text := "%s · %s · %s" % [
		tr("UI_ROAD_TERRAIN_NOW") % tr(RouteTerrain.biome_name_key(biome)),
		tr("UI_ROAD_WEATHER") % tr(RouteWeather.name_key(_weather)),
		tr("UI_ROAD_PACE_LABEL") % tr(_pace_key),
	]
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
	_session.log_beat(GameSession.BEAT_LOG_CAMP_START)
	_camp_ends_at_hours = JourneyController.CAMP_PENDING
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
	# Zorlanan gün kişileri de yorar; kervanın takati en yorgunun (Y-F01).
	# Kilit yalnızca hızlı tempoyu indirir, normal tempoyu asla yavaşlatmaz.
	_session.apply_pace_fatigue_day(pushing)
	if pushing and not _session.can_push_pace():
		_pace = PACE_STEADY
		_pace_key = "UI_ROAD_PACE_STEADY"
		var binder := _session.get_stamina_binder()
		if binder != null:
			_add_log(tr("UI_ROAD_PACE_EXHAUSTED_BY") % binder.character_name, LOCKED_COLOR)
		else:
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
	return clampf(weathered + (_signal_danger_bonus + _night_danger_delta()) * (1.0 - weathered), 0.0, 1.0)

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
	_auto_pause()
	# Öndeyken karşılaşma daha uzaktan görünür: işaret daha ileriye
	# konur, yani oyuncunun hazırlanacak (ya da geri dönecek) yolu olur.
	# Savaşın sıklaşmasının dengesi bu - sıklaştırılmış ama kaçınılamayan
	# bir savaş mekanik değil vergidir.
	# İşaret görüşün içinde doğuyor: manzaranın ölçeği figür boyuna bağlı
	# olduğu için (bkz. _update_world_scale) büyük ekranda yarım gün
	# ekranın dışına düşebilir - görülmeyen bir uyarı uyarı değil.
	var room := _band.visible_room_ahead() - ENCOUNTER_EDGE_MARGIN
	var visible_days := maxf(0.05, room / _band.get_pixels_per_day())
	_pending_event_day_position = minf(
		_days_covered + minf(
			ENCOUNTER_APPROACH_DAYS + RoadAttention.spot_bonus_days(_attention_zone),
			visible_days
		),
		float(_journey_length_days)
	)
	_spawn_encounter(kind)

func _spawn_encounter(kind: String) -> void:
	_clear_encounter()
	var archetypes: Array = MARKER_ARCHETYPES.get(kind, ["clerk"])
	var archetype: String = archetypes[absi(hash("%d|%s" % [_current_day, kind])) % archetypes.size()]
	_encounter = RoadEncounter.new()
	_encounter.setup(archetype)
	# Karşılaşılan şey gelen kervana bakıyor - kervan geri dönmüşse sağa.
	_encounter.set_facing(-_journey.heading)
	# `add_child` değil `add_actor_layer`: kervanla aynı kuralı okuyor,
	# ön plandaki çalıların arkasına düşmesin diye (bkz. yukarıdaki not).
	_band.add_actor_layer(_encounter)
	_position_encounter()

## Şerit her karede dünyayı kaydırdığı için işaretin ekran konumu da her
## karede yeniden okunmalı - `_refresh_time_ui()`'den çağrılıyor.
func _position_encounter() -> void:
	if _encounter == null:
		return
	_encounter.set_screen_position(_band.screen_position_for_day(
		_journey.terrain_day_at(_pending_event_day_position)
	))

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
	var front_days := 0.0 if _caravan == null else _caravan.get_front_offset() / _band.get_pixels_per_day()
	if not _journey.has_reached_pending(front_days):
		return
	var event := _pending_event
	_pending_event = null
	_clear_encounter()
	_present_event(event)

func _present_event(event: GameEvent) -> void:
	_current_event = event
	_session.log_beat(GameSession.BEAT_LOG_INFO, "card:" + event.event_id)
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
	NodeUtil.clear_children(_card_panel)

	var title := Label.new()
	title.text = tr(event.title_key)
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = ArtPalette.GOLD
	_card_panel.add_child(title)

	var illustration := _build_event_illustration(event.event_id)
	if illustration != null:
		_card_panel.add_child(illustration)

	# Gövde kaydırma kutusunda, seçenekler **dışında**: uzun bir olay metni
	# seçenekleri kartın altından taşırmasın (bkz. World Navigation
	# Rules'un kaydırma maddesi - orada çıkış tuşu, burada karar tuşları).
	var body_scroll := ScrollContainer.new()
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.custom_minimum_size = Vector2(0.0, 0.0)
	_card_panel.add_child(body_scroll)

	var body := Label.new()
	body.text = tr(_framed_text_key(event))
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
	var first := true
	for choice in event.choices:
		var button := _build_choice_button(choice, context)
		# Taslak 9.1: kartın ilk seçeneği ana eylem (kırmızı); kilitliyse değil.
		if first and not button.disabled:
			button.theme_type_variation = WaybookTheme.PRIMARY_BUTTON
		first = false
		_card_panel.add_child(button)

## Aynı haber kartının gövdesini liderin kültürüne göre çerçeveler (bkz.
## EventCatalog.get_culture_framed_text_key'in kendi yorumu) - haber
## dışındaki olaylarda ve varyantı olmayan bir kültürde boş döner, çağıran
## eski `event.text_key`'e düşer, hiçbir davranış kırılmaz.
func _framed_text_key(event: GameEvent) -> String:
	var leader := _session.get_player_character()
	var culture_id := leader.culture_id if leader != null else ""
	var framed := EventCatalog.get_culture_framed_text_key(event.event_id, culture_id)
	return framed if not framed.is_empty() else event.text_key

## Kartın illüstrasyonu - `EVENT_CARD_ART`'ta yoksa `null` (kart resimsiz
## açılır, aynı `EVENT_ROAD_MARKER_KIND`'in eşlemede olmayan olayı hiç
## işaretlememesi gibi). Kare resim `STRETCH_KEEP_ASPECT_COVERED` ile
## kırpılıp `clip_contents` içinde sabit bir yüksekliğe oturuyor - kartın
## kendi genişliğini dolduran geniş bir şerit, kareyi olduğu gibi basıp
## kartı ekrandan taşırmıyor.
func _build_event_illustration(event_id: String) -> Control:
	var file_name: String = EVENT_CARD_ART.get(event_id, "")
	var path := "res://data/assets/ui/waybook/" + file_name
	if file_name.is_empty() or not ResourceLoader.exists(path):
		# Kendi resmi olmayan olay da resimsiz açılmaz: kervanın yürüdüğü yolun
		# manzarası (kullanıcı notu: olaya ait görsel kartın içinde, EU4 gibi).
		var biome := _terrain.look_at(_terrain_day()) if _terrain != null else ""
		if not EventVignette.available(biome):
			return null
		var vignette := EventVignette.new()
		vignette.biome = biome
		vignette.darkness = JourneyClock.darkness_for_hour(_clock.get_hour_of_day())
		vignette.custom_minimum_size = Vector2(CARD_WIDTH - 40.0, CARD_ILLUSTRATION_HEIGHT)
		return vignette
	var frame := Control.new()
	frame.clip_contents = true
	frame.custom_minimum_size = Vector2(CARD_WIDTH - 40.0, CARD_ILLUSTRATION_HEIGHT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := TextureRect.new()
	picture.texture = load(path)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(picture)
	return frame

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
		# Y-H07: renk körlüğü ayarında şerit desenli (kesik kesik).
		var stripe := PatternStripe.new()
		stripe.colour = ArtPalette.UI_CHOICE_COMBAT
		stripe.patterned = UserSettings.pattern_stripes
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
	if resolved_event != null:
		_session.note_beat(GameSession.BEAT_EVENT, [tr(resolved_event.title_key)])
		_session.log_beat(GameSession.BEAT_LOG_DECISION, "card:" + resolved_event.event_id)
	NodeUtil.clear_children(_card_panel)

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
	# Konuşma penceresi (kullanıcı isteği: NPC konuşmaları portreli pencerede):
	# solda yolcunun kendisi, sağda teklifi, altta katıl ya da geç.
	var text := tr("UI_ROAD_RECRUIT_OFFER") % [
		candidate.get_summary_line(),
		candidate.get_max_hp(),
		candidate.get_accuracy(),
		candidate.get_dodge(),
		candidate.hire_cost,
	]
	var hire := {"id": "hire", "text": tr("UI_ROAD_RECRUIT_JOIN"), "cost": tr("UI_TALK_COST") % candidate.hire_cost}
	if not _session.wallet.can_afford(candidate.hire_cost):
		hire["locked"] = tr("UI_NOT_ENOUGH_GOLD")
	var cls := candidate.get_character_class()
	_talk_panel = DialoguePanel.new()
	add_child(_talk_panel)
	# Kapatmak (Esc, Kapat) geçmek demek; karar bir kez verilir.
	var decided := [false]
	_talk_panel.choice_made.connect(func(id: String) -> void:
		decided[0] = true
		if id == "hire":
			_on_road_recruit_accepted(candidate)
		else:
			_on_road_recruit_declined()
		_talk_panel.close())
	_talk_panel.closed.connect(func() -> void:
		_talk_panel = null
		if not decided[0]:
			_on_road_recruit_declined())
	_talk_panel.open(candidate, cls.display_name if cls != null else "", text, [
		hire, {"id": "decline", "text": tr("UI_ROAD_RECRUIT_DECLINE")},
	], true, "")

func _on_road_recruit_accepted(candidate: CharacterData) -> void:
	if _session.recruit(candidate):
		_add_log(tr("UI_ROAD_RECRUIT_JOINED") % candidate.character_name, OUTCOME_COLOR)
	_close_recruit_offer()

func _on_road_recruit_declined() -> void:
	_add_log(tr("UI_ROAD_RECRUIT_DECLINED"))
	_close_recruit_offer()

func _close_recruit_offer() -> void:
	NodeUtil.clear_children(_recruit_holder)
	_set_journey_controls_enabled(true)
	_refresh_state()
	_check_journey_end()

## Bir olay savaş istediğinde savaş paneli açılır; sonuç
## kervana etkilerle yansır. Panel açıkken gün ilerletilemez.
## enemy_kind EnemyCatalog.build_squad'ın kadro türü (bkz. EventEffect.Type.
## TRIGGER_COMBAT'in text_value'su); bölge (bkz. EnemyCatalog.build_bandit_squad'ın
## region_id'si) sefer hedefinden okunuyor - haydut kadrosu gidilen yöreye
## göre reskin oluyor.
func _open_combat(danger_percent: int, enemy_kind: String = "bandit") -> void:
	_pending_combat_danger = _weathered_danger() if danger_percent <= 0 else danger_percent / 100.0
	_current_combat_kind = enemy_kind
	_session.log_beat(GameSession.BEAT_LOG_COMBAT_START, enemy_kind)
	AudioManager.set_combat_duck(true)
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
	NodeUtil.clear_children(_combat_holder)

	# Savaş yolun *yerine* açılıyor: şerit gizlenip savaş sahnesi onun
	# çerçevesinde beliriyor - önceden savaş, şerit görünür kalırken
	# ekranın altına eklenen ayrı bir blok gibi duruyordu.
	_band.visible = false
	_combat_holder.visible = true
	_set_combat_view(true)

	var panel := CombatPanel.new()
	_combat_holder.add_child(panel)
	panel.combat_finished.connect(_on_combat_finished)
	CombatUnit.deathblow_offset = _session.get_deathblow_offset()
	_combat_retreat_kind = ""
	panel.retreated.connect(func(kind): _combat_retreat_kind = String(kind))
	# Ganimet ve sarf (Y-C03, Y-C04).
	panel.consumables = {
		CombatEncounter.CONSUMABLE_BANDAGE: _session.get_total_quantity(CombatEncounter.CONSUMABLE_BANDAGE),
		CombatEncounter.CONSUMABLE_POTION: _session.get_total_quantity(CombatEncounter.CONSUMABLE_POTION),
	}
	panel.set_loot_context(_current_combat_kind, _pending_combat_danger)
	panel.loot_rolled.connect(func(drops):
		var lines := LootTable.apply(_session, drops)
		if not lines.is_empty():
			_add_log(tr("UI_ROAD_LOOT") % ", ".join(lines), OUTCOME_COLOR))
	panel.consumables_used.connect(func(used):
		for item_id in used:
			_session.remove_from_cargo_or_bags(String(item_id), mini(int(used[item_id]), _session.get_total_quantity(String(item_id)))))
	# Faz 17 PR-6: o günkü arazi vahşi hayvan kadrosunun kompozisyonunu da
	# eğiyor (bkz. EnemyCatalog.build_wildlife_squad) - "kurt sürüsü" orman
	# geçitlerinde, tekil ayı dağ geçitlerinde daha olası.
	var current_biome := "" if _terrain == null else _terrain.biome_at(_terrain_day())
	panel.start_combat(
		_current_combat_party, _pending_combat_danger, null,
		_current_combat_kind, _session.journey_destination_id, current_biome,
		"" if _terrain == null else _terrain.look_at(_terrain_day())
	)

func _on_combat_finished(
	victory: bool, xp_awarded: int, downed_count: int, dead_characters: Array
) -> void:
	_session.log_beat(GameSession.BEAT_LOG_COMBAT_END, "won" if victory else "lost")
	AudioManager.set_combat_duck(false)
	# Günün satırı (Y-B08): kazanılan ya da kaybedilen savaş, düşmanın adıyla.
	_session.note_beat(GameSession.BEAT_WON if victory else GameSession.BEAT_LOST,
		[EnemyCatalog.get_kind_label(_current_combat_kind)])
	if xp_awarded > 0:
		# Yalnızca bu savaşa girenler (bkz. PreCombatPanel) - risk almayan
		# deneyim de kazanmaz.
		_session.grant_party_xp(xp_awarded, _current_combat_party)
		_add_log(tr("UI_ROAD_PARTY_XP") % xp_awarded, OUTCOME_COLOR)
	# Birlikte sağ çıkan bağlanır (R1 #2).
	if victory and dead_characters.is_empty():
		# Ortak savaştan sağ çıkmak liderle bağı da artırır (R0 4.4).
		for fighter in _current_combat_party:
			fighter.change_rapport(1)
		_session.companion_notes = []
		_session.bond_group(_current_combat_party, CompanionLife.SHARED_FIGHT)
		for note in _session.companion_notes:
			_add_companion_note(note)
		_refresh_pair_spacing()

	# Ölüm artık savaşta herkesi bulabilir, lideri de yoldaşı da - kural
	# tersine çevrildi (bkz. CombatUnit.can_enter_deaths_door). Sonucunu
	# oturum uygular: her ölen partiden çıkar, liderlik yalnızca *lider*
	# öldüyse devredilir. Kimse ölmediyse bu tamamen sessiz - eski
	# davranış aynen sürüyor.
	if not dead_characters.is_empty():
		_report_combat_deaths(dead_characters)

	# Savaşa girenler yorulur (Y-F01).
	_session.apply_combat_fatigue(_current_combat_party)

	# Kıyı'ya kadar düşüp kalkan sakatlanabilir (Y-C05).
	var injury_rng := RandomNumberGenerator.new()
	injury_rng.seed = hash("injury|%s|%d" % [_route_key, _session.total_days_elapsed])
	for fighter in _current_combat_party:
		if _session.get_party().has(fighter) and fighter.current_hp <= 1:
			var injury := _session.roll_injury(fighter, injury_rng)
			if not injury.is_empty():
				_add_log(tr("UI_AILMENT_INJURED") % [fighter.character_name, tr(String(CharacterData.AILMENTS[injury]["key"]))], LOCKED_COLOR)

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
	if not _combat_retreat_kind.is_empty():
		# Bedelli geri çekilme (Y-C07): yenilginin bedeli yerine seçilen bedel.
		_apply_retreat_cost(_combat_retreat_kind)
		effects.append(EventEffect.make(EventEffect.Type.MORALE, RETREAT_MORALE))
	elif victory:
		var loot := COMBAT_LOOT_BASE + int(round(_session.danger_level * COMBAT_LOOT_DANGER_BONUS))
		effects.append(EventEffect.make(EventEffect.Type.GOLD, loot))
		effects.append(EventEffect.make(EventEffect.Type.MORALE, COMBAT_VICTORY_MORALE))
		var reputation_delta := GUARD_VICTORY_REPUTATION if _current_combat_kind == "guard" else COMBAT_VICTORY_REPUTATION
		effects.append(EventEffect.make(EventEffect.Type.REPUTATION, reputation_delta))
		effects.append(EventEffect.make(EventEffect.Type.DANGER, COMBAT_VICTORY_DANGER))
		# Av (görev Y-B06): yabani hayvan savaşı et getirir.
		var meat := GameSession.combat_victory_provisions(_current_combat_kind)
		if meat > 0:
			effects.append(EventEffect.make(EventEffect.Type.PROVISIONS, meat))
	else:
		effects.append(EventEffect.make(EventEffect.Type.GOLD, COMBAT_DEFEAT_GOLD))
		effects.append(EventEffect.make(EventEffect.Type.WAGON_DAMAGE, COMBAT_DEFEAT_WAGON_DAMAGE))
		effects.append(EventEffect.make(EventEffect.Type.MERCHANT_LEAVE, COMBAT_DEFEAT_MERCHANTS))
		effects.append(EventEffect.make(EventEffect.Type.MORALE, COMBAT_DEFEAT_MORALE))

	var result := _apply_effects(effects)
	for line in result.lines:
		_add_log("      %s" % line, OUTCOME_COLOR if victory else LOCKED_COLOR)

	NodeUtil.clear_children(_combat_holder)
	_combat_holder.visible = false
	_set_combat_view(false)
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
	NodeUtil.clear_children(_arrival_panel)
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
		# Soy bitti: izi arşive yazılır, yeni kervan okur (Y-D03).
		LineageArchive.record(_session)

## Bir olay pazarlık istediğinde gerçek pazarlık paneli açılır:
## anlaşırsan anlaştığın fiyatı, anlaşamazsan tam bedeli ödersin.
func _open_haggling(max_price: int) -> void:
	_pending_haggle_max = max_price
	_clock.consume_hours(HAGGLE_HOURS)
	_set_journey_controls_enabled(false)
	NodeUtil.clear_children(_haggle_holder)

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
	NodeUtil.clear_children(_haggle_holder)
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
		or _talk_panel != null
		or _map_popup != null
		or _story_panel != null
		or _camp_panel != null
		or _diary_panel != null
	)

## Yolun oyun içi menüsü: sefer sürerken elle kayıt kapalı (`setup(false)`),
## çünkü bir kararın hemen önüne alınan elle kayıt, sonucu beğenmeyince
## yeniden denemenin kapısı olurdu - bkz. `SaveManager`in başındaki not.
## Otomatik kayıt ayrı: sakin anlarda yuva 0'a yazılıyor. F1'in sentetik
## seferi de aynı ekranı paylaştığı için aynı kural geçerli.
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
	NodeUtil.clear_children(_debt_holder)

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
	NodeUtil.clear_children(_debt_holder)
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
	NodeUtil.clear_children(_replan_holder)

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
	# Kervan aynı yolu ters yönde yürüyecek: arazi değişmiyor, yön değişiyor.
	_journey.start_return_leg(_session.journey_total_days)
	_apply_replan(tr("UI_ROAD_TURNED_BACK"))

func _on_divert_pressed(destination_id: String) -> void:
	if not _session.divert_journey(destination_id):
		_close_replan()
		return
	# Sapma başka bir yol: arazisi o yolun kendi anahtarından (planlayıcının
	# gösterdiği), bacak onun başından ve hedefe doğru.
	_journey.start_leg(_session.journey_total_days)
	_journey.heading = 1.0
	_journey.leg_origin_day = 0.0
	_route_key = RouteConditions.route_key(
		_session.journey_origin_id, _session.journey_destination_id
	)
	_journey.terrain_key = _route_key
	_journey.terrain_days = _journey_length_days
	_terrain = RouteTerrain.build(_route_key, _journey_length_days, _session.journey_origin_id, _session.journey_season(), _session.journey_shortcut)
	_band.set_route(_terrain)
	_refresh_memorials()
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
	var diversion_event: GameEvent = null
	if not _session.caravan.original_merchant_names.is_empty():
		diversion_event = EventCatalog.get_event("evt_route_diversion")
	_start_turn_if_needed(diversion_event)

## Kervanın yüzü bacağın yönüyle aynı değilse kervan döner: sırayla, on
## saniyede (bkz. RoadCaravan.begin_turn). Kamera hemen ters çapaya kayıyor,
## dönüş bitene kadar zaman durur - dönüşün bedeli zaten `REPLAN_HOURS`
## olarak saatten düşüldü. Tüccarların tepkisi dönüş bittikten sonra: oyuncu
## dönüşü kartın arkasından değil kendi gözüyle görsün.
func _start_turn_if_needed(after_event: GameEvent) -> void:
	if is_equal_approx(_caravan.get_heading(), _journey.heading) and not _caravan.is_turning():
		if after_event != null:
			_present_event(after_event)
		return
	_turn_event_after = after_event
	_has_leader_target = false
	_band.set_heading(_journey.heading)
	_caravan.begin_turn(_journey.heading)
	_add_log(tr("UI_ROAD_TURNING"))

func _on_caravan_turn_finished() -> void:
	_leader_offset = _caravan.get_leader_offset()
	_refresh_attention_zone()
	_refresh_state()
	var event := _turn_event_after
	_turn_event_after = null
	if event != null and not _journey_finished:
		_present_event(event)

func _close_replan() -> void:
	NodeUtil.clear_children(_replan_holder)
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
	NodeUtil.clear_children(_arrival_panel)

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

	# Büyüyen kervanın kazandığı vagon (bkz. GameSession.
	# grant_earned_wagons). Teslimat satırıyla aynı gerekçe: sessizce
	# olan bir ödül, olmayan bir ödülden ayırt edilemez.
	var wagons_earned: int = payout.get("wagons_earned", 0)
	if wagons_earned > 0:
		var wagon_label := _make_summary_label(tr("UI_ROAD_WAGON_EARNED") % wagons_earned)
		wagon_label.modulate = OUTCOME_COLOR
		_arrival_panel.add_child(wagon_label)

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
	# Kervanın takati en yorgun kişiye bağlı (Y-F01): çubuk sayacı değil
	# türetilmiş değeri gösterir, ipucu bağlayanın adını söyler.
	var stamina := _session.get_caravan_stamina()
	_stamina_bar.set_value(stamina, CaravanState.MAX_STAMINA)
	# Y-H03: göstergenin ipucu önce söz, sonra sayı.
	_morale_bar.set_reason(Wording.gauge_tooltip(tr("UI_HUB_MORALE"), Wording.MORALE, caravan.morale,
		CaravanState.MAX_MORALE, Wording.reasons(_session, Wording.MORALE)))
	_stress_bar.set_reason(Wording.gauge_tooltip(tr("UI_HUB_STRESS"), Wording.STRESS, _session.party_stress,
		GameSession.MAX_STRESS, Wording.reasons(_session, Wording.STRESS)))
	var no_reasons: Array[String] = []
	_danger_bar.set_reason(Wording.gauge_tooltip(tr("UI_HUB_DANGER"), Wording.DANGER, _weathered_danger() * 100.0,
		100.0, no_reasons))
	var stamina_reasons: Array[String] = []
	var binder := _session.get_stamina_binder()
	if binder != null:
		stamina_reasons.append(tr("UI_FATIGUE_MOST_TIRED") % [binder.character_name, binder.fatigue])
	_stamina_bar.set_reason(Wording.gauge_tooltip(tr("UI_ROAD_STAMINA"), Wording.STAMINA, stamina,
		CaravanState.MAX_STAMINA, stamina_reasons))
	_attention_label.text = tr("UI_ROAD_ATTENTION") % RoadAttention.get_zone_label(
		_attention_zone
	)
	_attention_label.tooltip_text = _attention_label.text
	_attention_icon.texture = WaybookTheme.texture(ZONE_ICONS.get(
		_attention_zone, ZONE_ICONS[RoadAttention.ZONE_WAGONS]
	))
	if _signal_tween == null:
		_refresh_signal_icon()

	# N23: üst şeridin sayı satırı kalktı - kese, erzak, itibar, vagon, tüccar
	# ve evrak denetim panelinin Durum sekmesinde (RoadControlPanel).
	_state_label.visible = false

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
