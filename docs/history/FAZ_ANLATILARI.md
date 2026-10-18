# Faz anlatıları (CLAUDE.md'den taşındı)

Bu dosya, `CLAUDE.md`'nin "Development Status" bölümünün Ana Hedefler'den sonraki kısmıdır: Faz 0-27'nin kapanış anlatıları, ölçümler ve
çözülmüş-sorun kayıtları. **Metin olduğu gibi, tek harf değişmeden taşındı** (TODO görev 6.3 / Y-F11).
Kurallar `CLAUDE.md`'de kalır; bu belge "neden böyle karar verildi, hangi ölçüm neyi gösterdi" sorusunun yanıtıdır. Koddaki
"bkz. CLAUDE.md Faz 13" gibi başvurular artık buraya bakar.

---

**Kapandı (Faz 25):** şehir kapısı artık render edilmiş bir sur geçidi
(bkz. Prop Rules) - `ColorRect` yer tutucusu yalnızca eşya paketi yoksa
çiziliyor. Gemini kapı prompt'u (`docs/gemini-prompts-gate.md`) kullanılmadı.

**Kapandı (Faz 16):** kıyafet seçiminin `WalkFigure`/`CombatFigure`'a
bağlanması, genel kervan yönetimi ekranı (`CaravanOverviewPanel`),
`evt_roadside_shrine`'ın gerçek sunak durağına bağlanması, yabancı
tüccarın vagonuna diyalog yoluyla bakış (`MerchantDialoguePanel`),
vagonun ve partinin kondisyonunun yolun gerçek yürüyüş hızını belirlemesi
- beşi de aşağıdaki Faz 16 anlatısında ve Route Terrain & Weather
Rules'ta.

Faz 0-3 tamamlandı. Oyun bir tur dönüyor (kazanç ödeniyor, harita tam
bağlı, fiyat şehre göre değişiyor, kargo kapasitesi var), test iskelesi
oyuna çevrildi (`scenes/game/`, F1 dev paneli), ilerleme kalıcı
(`SaveManager`), şehrin dört lokasyonu artık gerçek ekranlar - kart
tabanlı değil, her biri kendi kararını taşıyor:

- **Pazar Meydanı** (`market.gd`): şehir başına stok sınırı
  (`Location.stock_per_item` / `GameSession.market_stock`, her varışta
  dolar), miktar seçili toptan alım, `HagglingPanel` üzerinden bulk
  pazarlık.
- **Tüccar Loncası** (`guild.gd`): kontrat panosu. Teklifler artık
  statik veri değil, `GameSession.accepted_contracts`'ta tutulan
  oturum durumu - kabul edilince panodan kalkar, sefere çıkılmadan
  süresi geçerse (`MerchantOffer.contract_deadline_days`, `advance_day()`)
  ya da yolda teslim edilemezse (`CaravanState.original_merchant_names`,
  `finish_journey()`) itibar cezası uygulanır. Büyük kontratlar itibar
  ister (`required_reputation`).
- **Taverna** (`tavern.gd`): rota dedikodusu. `GameSession.known_routes`
  öğrenilmedikçe dünya haritası tehlikeyi yalnızca kaba bir bant
  (düşük/orta/yüksek) gösterir, tam yüzde parayla öğrenilir.
- **Kervan Avlusu** (`caravan_yard.gd`): vagon onarımı ve alımı.
  Oyuncu artık kalıcı olarak vagon sahibi (`GameSession.owned_wagon_count`
  / `owned_wagon_damaged`, karakter oluşturmada tayfa sayısından
  hesaplanır);
  sefer sırasındaki kayıp/hasar escort vagonlarına öncelikli uygulanıp
  varışta sahipliğe taşınır (bkz. `_apply_wagon_losses_to_ownership`).

Faz 4 (karakter + combat) tamamlandı. Oyuna artık bir "sen" girdi:

- **Karakter oluşturma** (`character_creation.gd`, `Nav.CHARACTER_CREATION`):
  kültür, isim (kültür havuzundan rastgele ya da elle), boy, ten rengi,
  6 stata dağıtılan puan ve tayfa büyüklüğü. Ana menüdeki "Yeni Oyun"
  artık doğrudan oyunu başlatmıyor, buraya getiriyor; kayıt yalnızca
  bu ekran tamamlanınca siliniyor.
- **Combat** (`scripts/combat/`, `CombatPanel`): sıra tabanlı,
  4 mevkilik iki saf, inisiyatif sırası, mevki kilitli yetenekler.
  Haydut pususunun "Direnç göster" seçeneği artık zar atmıyor, gerçek
  savaşı açıyor (`TRIGGER_COMBAT`). F1 panelindeki "combat" girişi de
  bağlandı (`scenes/game/combat.tscn`).
- **Tayfa toplama** (`RecruitCatalog`, `RecruitPanel`, `recruit.gd`):
  meydan/taverna/lonca aynı ekranı farklı havuz ve fiyatla açar
  (`Nav.recruit_venue`), lonca itibar ister. Yolda da bir aday çıkabilir
  (`evt_road_wanderer` → `TRIGGER_RECRUIT`).

Faz 5 (güvenlik ağı) tamamlandı: CI artık her push/PR'da testleri koşturup
Godot'un sessizce geçtiği ayrıştırma hatalarını yakalıyor (`tests.yml`),
314 doğrulamalık yedi paket ve `simulate_journeys.gd` denge simülatörü var.

Faz 6 ("Karakterin Yolculuğu") tamamlandı - dört PR'lık bir hat:

- **PR-A (veri katmanı)** stat tavanını 15'e çıkardı ve 10 üstünü
  yavaşlattı (`CharacterStats.get_effective_value`), XP/seviye eğrisini,
  dört sınıfı (Sıra Neferi/Sekban/Kırıkçı/Kalem Efendisi) ve on iki yeni
  yeteneği, süreli stat değiştiricileri (`CombatSkill.modifier_*`),
  yetkinlik (per-skill continuous investment) ve altı kervan görevini
  (`Duty`/`DutyCatalog`) getirdi - dördü (Muhafız/Levazımcı/Arabacı/Tellal)
  canlı sistemlere bağlandı, Otacı PR-D'nin kamp/stres sistemine bağlandı;
  İzci hâlâ katalogda hazır ama bağlanmadı (ev sistemi
  `caravan_planner.gd`/`world_map.gd`, henüz okunmadı).
- **PR-B (karakter ekranı)** bu veri katmanını ilk kez oynanabilir kıldı:
  yeni `Nav.CHARACTER` ekranı (stat/yetkinlik yatırımı, görev ataması,
  multiclass, Faz 7'ye kilitli ekipman yer tutucuları), karakter
  oluşturmada sınıf seçimi, seviyeli/sınıflı tayfa adayları.
- **PR-C (huylar + Kilise)** on iki huy (`Trait`/`TraitCatalog`, her stat
  için bir olumlu bir olumsuz), karakter kurulurken statlarla orantılı
  ağırlıklı seed huy (`roll_seed_trait`), `EventEffect.Type.GRANT_TRAIT`
  (ilk kullanımı `evt_troubled_night`) ve yalnızca beş gün içinde
  kazanılmış ("taze") huyları silen `PurificationPanel`'i getirdi -
  Taverna'da pahalı, yeni Kilise'de (`Nav.CHURCH`) ucuz.
- **PR-D (stres/moral döngüsü + kamp)** `GameSession.party_stress`'i
  (bkz. Stress Rules) getirdi: dayanıklılığa göre kişisel kırılma direnci,
  şehir varışında toplu kırılma zarı (`resolve_stress_breaks` - çoğunlukla
  huy, nadiren tam tersi, ağır kırılan bir yoldaş kervandan ayrılabilir),
  savaşta emir reddi (`CombatUnit.is_stressed`), yolda yeni bir "Kamp Kur"
  eylemi (`GameSession.make_camp`) ve yüksek stresin kendi olayını
  (`evt_stress_brawl`) açması. `world_hub.gd`'nin HUD'una moral ve stresi
  gösteren iki `PulseBar` eklendi.

Faz 7 ("Kervanın Donanımı") tamamlandı - dört PR'lık bir hat:

- **PR-A (equipment veri katmanı)** dört slotu (Silah/Zırh/Yüzük/Kolye,
  `EquipmentCatalog.SLOT_*`) ve on iki parçayı getirdi: Silah/Zırh üçer
  tier'lik kalıcı yükseltme (yalnızca pozitif bonus), Yüzük/Kolye üçer
  ödünlü tılsım (bir stat artar, biri düşer). Bonus
  alanları `Trait`'inkiyle birebir aynı isimlerde - `CharacterData.
  get_max_hp()/get_dodge()/get_accuracy()/get_crit_chance()/
  get_damage_bonus()` huy bonusunun yanına `_equipment_bonus_sum`'ı da
  topluyor, `CombatUnit.from_character` hiç değişmeden bunu otomatik görür.
- **PR-B (equipment UI + edinim)** `character.gd`'nin dört kilitli
  placeholder slotunu gerçek bir equip paneline çevirdi. `GameSession.
  equipment_inventory` kimseye takılmamış parçaların ortak deposu
  (`Inventory`'nin item_id->miktar deseninin karşılığı);
  `equip_to_character()`/`unequip_from_character()` karakterle depo
  arasındaki transferi tek yerde topluyor. Kervan Avlusu'na "Demirci"
  bölümü eklendi (Silah/Zırh parayla satılıyor); `EventEffect.Type.
  GRANT_EQUIPMENT` bulunan parçayı - `GRANT_TRAIT`'in aksine - doğrudan
  bir karaktere değil depoya yazıyor, çünkü ekipman hangi karaktere
  takılacağı seçilene kadar nötr kalmalı.
- **PR-C (İzci + olay havuzu)** altı görevin son bağlanmayanını
  (`DutyCatalog.IZCI`) canlı sistemlere bağladı: `world_map.gd` İzci
  varsa rota tehlikesini ücretsiz tam gösteriyor, `caravan_planner.gd`
  sefer süresini İzci'nin `get_duty_flat_reduction`'ı kadar kısaltıyor.
  Olay havuzu 13'ten 22'ye çıktı - ekipman bulma/edinme (`evt_forgotten_
  cache`, `evt_traveling_tinker`), İzci (`evt_scouted_pass`), beş
  kültürün her birine bir sahne (`evt_culture_*` - kültürlerin mekanik
  perki dışında ilk kez olay tarafında da göründüğü yer) ve bir
  curio (`evt_roadside_shrine`). `GameSession.build_event_context()`'e
  `has_izci` ve beş `is_*_culture` bayrağı eklendi.
- **PR-D (placeholder → lore)** `item_catalog.gd`'deki `test_` önekli
  id'ler (kayıt uyumluluğu için sabit) artık gerçek isimler taşıyor
  (Buğday, Top Kumaş, Demirci Malı Silah, Otacı İksiri, İşlenmiş Kürk).
  `world_map_data.gd`'nin beş şehri de aynı şekilde gerçek isimlere
  kavuştu (Karakonak/Kurtboğazı/İpekevi/Demirkapı/Yeşilova -
  `location_id`'ler yine sabit), tüccar isimleri "Tüccar 12" gibi çıplak
  numaralar yerine kültürlerin kendi isim havuzlarından deterministik
  seçiliyor.

Faz 8 ("Vizyon ve Denge") sürüyor - rakip oyunların (kadro yıpratan sıra tabanlı oyunlar,
Oregon Trail tarzı kervan yönetimi) vizyonu doğrultusunda içerik/denge
boşluklarını dolduran bir hat:

- **PR-A (denge simülatörü)** `simulate_journeys.gd`'yi Faz 6-7 içeriğini
  gerçekten alıştıran bir araca çevirdi (bkz. Testing bölümü) - bulduğu
  `get_duty_flat_reduction()` asimetrisini düzeltti.
- **PR-B (düşman çeşitliliği)** yolda yalnızca haydut çıkma tekdüzeliğini
  kırdı: vahşi hayvan (Kurt/Ayı/Domuz), bölgeye göre haydut reskin'i
  (Kurtboğazı → Dağ Haydutu, Demirkapı → Silahlı Eşkıya), şehir muhafızı/
  çavuşu (zafer itibar *kaybettirir* - bkz. Combat Rules). Tek giriş
  noktası `EnemyCatalog.build_squad(enemy_kind, region_id, ...)`,
  `enemy_kind` `EventEffect.Type.TRIGGER_COMBAT`'in `text_value`'sundan
  `EventEffectApplier.Result.combat_kinds` üzerinden akıyor.
- **PR-C (tayfanın görünürlüğü)** `world_hub.gd`'de vagonları süren
  isimsiz tayfayı (`GameSession.PEOPLE_PER_WAGON`) ilk kez görünür kıldı.
- **PR-C2 (kervan formasyonu)** diziliş mantığını ikiye ayırdı: isimli
  parti üyeleri artık simetrik bir muhafız düzeninde - levazımcı görevini
  taşıyan kişi (yoksa en kıdemli) her zaman liderin hemen arkasında
  (bkz. `world_hub.gd`'nin `_order_escorts()`) - tayfaysa artık düzenli
  sıra tutmuyor, vagon başına asimetrik/dağınık bir konumda yürüyor
  (`_crew_offset()`).
- **PR-D (hedef ve zorluk eğrisi)** üç parça: `GameSession.
  get_effective_danger(base_danger)` rotanın ham `danger_level`'ını
  `total_days_elapsed`'e göre büyütüyor (`DANGER_GROWTH_PER_DAY`,
  `DANGER_GROWTH_CAP` tavanlı) - erken oyunun kolaylığı geç oyunda
  sürmesin diye; caravan_planner.gd/world_map.gd/tavern.gd artık rotanın
  ham değeri yerine bunu okuyor. Oyunun kendi felsefesinde yenilgi
  yok, bu yüzden "hedef ekranı" bir game-over değil: kese `GameSession.
  GOAL_GOLD`'a ulaşınca (`has_reached_goal()`, bir kereye mahsus -
  `GOAL_FLAG`) şehre varışta `goal_reached.tscn` açılıyor, "Devam Et" ile
  oyun kaldığı yerden sürüyor. Ana menüye "Ayarlar" (dil seçici artık
  burada, `settings.tscn`) ve "Çıkış" eklendi.
- **PR-E (onboarding)** karakter oluşturmadan sonraki ilk şehir varışında
  bir kereye mahsus, atlanabilir bir ipucu katmanı (`OnboardingPanel`,
  `GameSession.ONBOARDING_FLAG`) stres/görev/huy/ekipman sistemlerini
  tanıtıyor - `PulseBar` gibi sahnesiz, `.new()` ile kurulan bir bileşen,
  `city_map.gd`'nin ilk `_ready()`'sinden tetikleniyor.

Faz 9 ("Derinleşen Dünya") tamamlandı - Codex incelemesinin açtığı yedi
başlık, hepsi aynı desende: sabit bir taban tablo + üstüne binen dinamik
bir katman, ve katmanın sömürülemeyeceğini kanıtlayan bir test paketi.

- **A (borç)** kese eksiye düşebiliyor; `DebtLedger` vade, faiz ve yapılandırma
  taşıyor, açık hesap kesenin eksi bakiyesinin *aynası* (iki kez sayılmasın diye).
- **B (ağırlık)** kargo sınırı artık `Inventory.add_item`'in içinde, yani olay
  ödülü de pazar alımıyla aynı kurala tabi. Erzak muaf.
- **C (ekonomi)** `MarketConditions`: enflasyon, mevsim, oyuncunun kendi
  ticaretinin yarattığı arz-talep baskısı ve `MARKET_SHOCK` olayları.
- **D-E (karakter-duyarlı olaylar)** `NpcDisposition` + `ROLL_ENCOUNTER`: yolda
  karşılaştığın kişinin gizli mizacı kararın sonucunu belirliyor, sezgisi
  kuvvetli biri okuyabiliyor, kinci biri günler sonra dönebiliyor.
- **F (pazarlık)** bkz. Haggling Rules - oyunun para basma noktası kapatıldı.
- **G (dinamik rotalar + yolda değişen plan)** bkz. Route Rules ve En-Route
  Plan Rules. `RouteConditions` sabit yedi kenarı her hafta başka bir ağa
  çeviriyor (`ROUTE_CHANGE` ile `evt_landslide`/`evt_road_patrol` de bu
  katmandan geçiyor), `divert_journey()`/`turn_back()` şehirde kurulan planı
  bir taahhüt olmaktan çıkarıyor.

- **H (çeviri)** ekran, savaş ve olay katmanlarındaki ~300 sabit Türkçe
  metni anahtara taşıdı; oyunun tamamı 11 dile açık. `test_localization.gd`
  üç yeni koruma kazandı (sabit metin taraması, tanımsız anahtar taraması,
  yer tutucu imzası) ve üçü de gerçek artık yakaladı - sonuncusu İngilizce
  bir savaş satırındaki argüman sırası hatasını.
- **I (moral)** bkz. Morale Rules. Moral ölü bir stattı; artık yol her gün
  yıpratıyor, çıkış morali dünyanın haline bağlı ve `evt_mutiny` ilk kez
  gerçekten ateşleniyor.
- **A-E denetimi** "tamamlandı" işaretli aşamalarda üç eksik buldu ve
  kapattı: borç defterinin hiçbir ekrana bağlı olmaması (`DebtPanel`),
  çeviri taramasının yalnızca ui/world'ü kapsaması, ve `SAVE_VERSION`'ın
  yazılıp hiç okunmaması.

Faz 10 ("Oyun bir şeye benzesin") tamamlandı - iki hat, biri savaşın
derinliği biri oyunun görüntüsü.

**Savaş derinliği hattı (CMB-1..CMB-5).** Zırh (PROT), her round yeniden
atılan hız zarı ve Ölümün Kıyısı (yalnızca lider ölür, kıdemliye devir,
varis yoksa oyun biter); savaş alanı görünümü (liste değil saf düzeni);
durum efektleri (kanama/zehir/sersemletme, dirençler, zincirlenemeyen
sersemletme, üst üste binmeyen DoT); alan hedefleme ve mevki kaydırma.
Denge yeniden ölçüldü ve tablo düştü - sebebi hiç ölçülmemiş olan CMB-1
çıktı (bkz. Ruin Rules).

**Sanat hattı (ART-A..ART-D).** Oyunun tamamı `ColorRect`'ten çizilmiş
görsele geçti: tek palet ve tek fırça seti (`ArtPalette`/`ArtDraw`),
katmanlı paralaks bir yol (arazi ve hava veriden geliyor, yağmur hem
görünüyor hem yolu yavaşlatıyor), eklemli yürüyen figürler ve atlı bir
lider, üstten bakışlı izometrik bir şehir (beş mekânın kendi mimarisi,
üstüne gelince ne yapabileceğini söyleyen balon). Kervan emirleri
(F2 + sayı) ve liderin kolondan ayrılıp gezebilmesi de bu hatta geldi.

Sırada: elle çizilmiş varlıklar (her şey hâlâ `_draw()` ile çiziliyor -
`ArtPalette` kalır, çizim fonksiyonları dokuya yerini bırakır) ve
Ruin Rules'un işaretlediği tek denge sorusu (iki kişilik parti %65
tehlikede %12).

Faz 11 ("Playtest 14.09.2026") - bir dış oyuncunun ilk elden bulduğu beş
gerçek eksik, hepsi küçük ama biri projeyi baştan sona kesiyordu:

- **Font kapsamı.** Savaşın mevki belirteçleri (`●○`) boş kutu olarak
  çıkıyordu - playtest bunu fotoğrafladı. Taradığında aynı hata on bir
  yerde daha çıktı (parti sıralama okları, brifingin tamamlandı tiki, yol
  kaydının ayırıcıları...). Hepsi `UiIcon`'a taşındı (bkz. Art Rules) ve
  `test_localization.gd` artık her CSV hücresini ve her ekran dizesini
  fontun kapsamına karşı sınıyor - bir daha aynı hata sessizce giremez.
- **Erzak kilidi risk oldu.** "Yetersiz erzak - yola çıkılamaz" oyunun
  kendi tezine (kervan ruined olabilir ama kararı oyuncu verir) aykırıydı.
  Artık iki basışlık bir onay: ilki kaç gün aç kalınacağını söylüyor,
  ikincisi kabul ediyor (bkz. Provision Rules).
- **Teslimat görünür oldu.** Kontrat teslimi varışta kendiliğinden oluyor
  ama hiçbir ekran bunu söylemiyordu - playtest "teslim et" ekranı aradı.
  Varış özeti artık teslim sayısını ve kazanılan itibarı yazıyor, lonca
  panosu kabul edilen kontratın yanına teslimatın nasıl işlediğini
  anlatan bir satır ekliyor (bkz. Reputation Rules).
- **Kervan dökümü.** "My Caravan Status" isteğine ve "status/map/
  inventory/contracts gibi düğmeler" fikrine tek cevap:
  `CaravanStatusPanel`, yol ekranında `Tab` ile açılan, kadro/vagon/erzak/
  kargo/kontrat/defter dökümü (bkz. Road Screen Layout Rules).
- **İsteğe bağlı yardım.** Sistem anlatımı (`OnboardingPanel`) bir kereye
  mahsus otomatik açılıyordu, bir daha bulunamıyordu. Şehirde ve yolda
  `F3` ya da bir "Yardım" tuşu artık aynı katmanı bayrağa dokunmadan
  yeniden açıyor.

**Bilerek uygulanmadı, not olarak duruyor:** playtest yürürken küçük
rastgele ödüller ya da mini-oyunlar önerdi, ama kendi sözleriyle *"erken
bir fikir olabilir, dursun bir köşede"* dedi ve oyunun text-tabanlı mı
olduğundan bile emin değildi. `RoadSignals` zaten üç olumsuz tür
taşıyor (bkz. Road Layer Rules) ve dördüncü, olumlu bir tür eklemek
mimari olarak ucuz - ama bu, playtest'in kendi hedefiyle çelişen bir
mekaniği inşa etmek olurdu. Fikir burada duruyor, bir görev değil.

Faz 12 ("Dışarıdan bakış") - oyunun kendi Codex'i beş farklı yapay zeka
modeline "bunu sıfırdan sen yapsaydın nasıl olurdu" diye soruldu; beşi de
birbirinden habersiz aynı iki şeye parmak bastı: dünya sahneleri (menü/yol/
şehir/savaş) ile yönetim ekranlarının (pazar/lonca/karakter...) iki ayrı
prodüksiyon gibi görünmesi, ve `RoadAttention`'ın taşıdığı karmaşıklığa
göre az iş yapması. İkincisi ciddiye alınmadı - oyunun kendi Road Layer
Rules'u bu mekaniği zaten playtest edilmiş, kasıtlı derinleştirilmiş bir
sistem olarak kaydediyor, kısa bir özetten görüp verilen bir oybirliği onu
sökmeye yetmez. Düşük riskli, kaynağı ne olursa olsun uygulanabilir üç
öneri alındı:

- **Tehlike artık seçilmeden önce görünüyor.** %12'lik bir kazanma oranı
  dengesizlik değildi, okunabilirlik sorunuydu - bkz. Event Engine Rules'un
  `_choice_triggers_combat()` maddesi.
- **Liderlik devri bir sahne oldu**, bir log satırı olmaktan çıktı - bkz.
  Lineage Rules'un `SuccessionPanel` maddesi.
- **Piyasa şoku artık görünür.** `add_shock()`'un hiç okunmayan
  `label_key`'i ve hiç çağrılmayan `get_active_shocks()`'u vardı - bkz.
  Economy Rules'un `is_shocked()` maddesi.

Geri kalan öneriler (stres/moral birleşmesi, rota/hava sadeleştirmesi, borç
sisteminin kapsamı, ekipmanın kargoya dönüşmesi, kampanya bölümlerinin
sadeleşmesi, ve en büyüğü - iki katmanlı "defter" sanat yönüne geçiş)
bilerek uygulanmadı: her biri oyunun zaten ölçülmüş ya da test edilmiş bir
sistemine dokunuyor ve iki taraf da modeller arasında gerçek savunucular
buldu. Karar oyuncuda, görev değil.

Faz 13 hazırlık notu (CLAUDE.md) - kervanla ilgili yıllar önce tutulmuş 26
notun triyajı. Her not mevcut sistemlere karşı üç kefeye ayrıldı:

**Zaten karşılanıyor, yeni iş gerekmiyor:** kervanın uzun süre yüksek
stresle dağılması (bkz. Stress Rules'un `resolve_stress_breaks`/
`evt_stress_brawl`/`evt_mutiny` üçlüsü), kararların gecikmeli sonuç
doğurması (bkz. Event Character Rules'un `evt_wanderer_revenge` zinciri -
mevcut bayrak/tetikleme vokabülerinin kendisi bu), sıra tabanlı
kombat (bkz. Combat Rules/CMB-1..CMB-5), göç sırasında bölgeye göre değişen,
tükenmeyen arkaplan çeşitliliği (bkz. Art Rules'un `hash(cell index)`
maddesi ve Route Terrain & Weather Rules), karizmaya bağlı pazar fiyatı +
partideki ticaret gücünden faydalanma (bkz. Haggling Rules ve Tellal
görevinin `get_duty_discount`'u), eylem sırasında zamanın eyleme göre akması
(bkz. Journey Time Rules'un `consume_hours` maddesi), ve "gelişme başarma
hissi" (bkz. Progression Rules'un ölçülen merdiveni). Rota uzayıp da
teslimat deadline'ı içinde kalırsa yine başarılı sayılması da zaten
`TRAVEL_DAYS` + kontrat deadline mekaniğinin doğal sonucu.

**Mevcut, kasıtlı tasarlanmış bir sistemle çelişiyor:** "stres parti
genelinde, moral bireysel" notu bugünkü sistemin **tam tersi** -
Stress Rules'un kendi tarihi tam olarak bunun (tek paylaşılan bir stat)
iki kez denenip iki kez başarısız olduğunu, bugünkü ayrımın (stres kişide,
moral seferde) o başarısızlıklardan sonra kasıtlı seçildiğini kaydediyor.
Not eski bir fikir olarak kalıyor, uygulanmadı.

**Faz 13 - oyuncunun kendi rafine ettiği son karar, uygulandı** (görev
listesi #112-#119, hepsi tamamlandı):

- Rota değişince o yöne gitmeyecek tüccarların tepki vermesi
  (`evt_route_diversion`, `triggered_only` - `road_journey.gd`'nin
  `_apply_replan()`'ından doğrudan sunulur, havuzdan çekilmez) - En-Route
  Plan Rules'un zaten yaptığı kesintiyi hikâyeleştiriyor.
- Bölge/duty bilgisine bağlı toplama-av olayı (`evt_forage` - İzci varsa
  ağırlığı ×1.6) - yeni bir sistem değil, `EventEffect.Type.PROVISIONS` +
  mevcut `RouteTerrain`/`has_izci` bayrağı.
- Kervan hızına açlığın etkisi (`road_journey.gd`'nin `_hungry` bayrağı,
  `HUNGRY_PACE_MULTIPLIER`) - tempo zaten hava çarpanına bağlıydı (bkz.
  Road Layer Rules'un "Pace is a resource" maddesi), aynı kalıba erzak
  eklendi: `_advance_contracts_and_provisions()`'ın kendi açlık koşulu
  `_walk_at()`'ın hız formülüne giriyor.
- Kombatta kısa, sessiz yorum balonları (isabet/kritik/düşüş/emir reddi
  anında) - seslendirme değil, yalnızca metin. `CombatEncounter.unit_barked`
  sinyali `CombatPanel._bark_texts`'te gerçek zaman damgasıyla tutuluyor,
  çünkü `CombatUnitSlot`'lar her `_refresh()`'te yeniden kuruluyor - bir
  Tween'in üzerinde kalabileceği kalıcı bir düğüm yok.
- Karar önizlemesi: Zeka/Sezgi'ye göre sonuç ipucu (`EventChoice.
  hint_text_key`/`hint_stat`/`hint_threshold`) - Faz 12'nin tehlike
  etiketiyle aynı okunabilirlik ailesi: ipucu zarı değiştirmiyor, yalnızca
  oyuncuyu bilgilendiriyor (New Vegas'ın skill-check önizlemesi gibi).
  `evt_party_investigation`'ın suçlama seçeneği ilk kullanımı.
- Kervan-içi hırsızlık/cinayet soruşturma zinciri (`evt_party_theft` →
  `UNLOCK_EVENT` → `evt_party_investigation`) - `NpcDisposition` ve
  `evt_wanderer_revenge`'in zincir deseninin parti-içi versiyonu; suçlama
  %50 doğru %50 yanlış bir kumar, hint bunu değiştirmiyor.
- Yeni yol konvoyu türleri (`evt_military_convoy`, `evt_refugee_column`,
  `evt_merchant_caravan`) - mevcut `EVENT_ROAD_MARKER_KIND`'a "guard"/
  "traveler" kategorileriyle yeni girişler, yeni bir figür çizmiyor.
- Görev gücüne kişisel kondisyon etkisi (`DutyCatalog.
  get_condition_multiplier()`) - kırılmış (`CharacterData.is_stressed()`)
  ya da canının yarısının altındaki bir görevli göreve daha az katkı verir;
  sağlıklı/dinç varsayılan (tam can, sıfır stres) çarpanı 1.0'da tuttuğu
  için mevcut hiçbir ölçüm/test etkilenmedi.

**Aynı triyajın kervanla ilgili dört notu da uygulandı** (kullanıcının
kendi önceliklendirmesiyle):

- **Boya bağlı açlık (#2).** "1.90 boyunda bir erkek ile 1.60 boyunda bir
  kadının açlığı aynı olmamalı" - `CharacterData.get_provision_weight()`
  uzun/kısa boy için ±%15, `CaravanPlan.daily_consumption()`'ın altıncı
  (varsayılan 0) parametresi olarak eklendi; `test_provisions.gd`'nin düz
  tam sayı çağrıları hiç değişmeden geçiyor.
- **Kıyafet sistemi (#14) - şimdilik yalnızca sistem, kullanıcının kendi
  isteğiyle.** Altı slot (şapka/gömlek/ceket/eldiven/pantolon/ayakkabı),
  `OutfitCatalog`/`OutfitPiece`, `CharacterData.outfit` - tamamen kozmetik,
  hiçbir derived getter bunu okumuyor (Equipment'ın aksine). Karakter
  oluşturmada boydan bir önizleme penceresi (`OutfitPreview`, basit bir
  `_draw()` taslağı - gerçek sprite'lar Faz 12'nin büyük sanat kararına
  bağlı) ve her slot için sağa/sola kaydırma (`OutfitCatalog.cycle()`).
  Seçenekler kasıtlı az; "önce sistemi kur, seçenekleri sonra ekle" burada
  tam olarak budur.
- **Arkada yaşayan dünya (#15).** Adaylar her şehir varışında bir seed'den
  yeniden atıldığı için (bkz. RecruitCatalog'un kendi notu) kalıcı bir
  kimlikleri yok - büyüme, `RecruitCatalog.get_world_growth_levels(
  journeys_completed)` ile dünyanın kendi seviyesinin zamanla yükselmesi
  olarak modellendi: on sefer önce meydanda karşılaşılan biriyle bugün
  karşılaşılan eşdeğer aday artık biraz daha tecrübeli çıkıyor. Hem şehir
  (`GameSession._restock_recruits`) hem yol (`evt_road_wanderer`) aynı
  fonksiyonu okuyor.
- **Manipülasyon (#19/#20) bir huy olarak, yedinci stat değil.** Kullanıcı
  bunu açıkça bir `Trait` istedi ("zekası yüksek kişilerde çıkan bir huy").
  Yeni bir huy eklemek `test_traits.gd`'nin kilitlediği on iki parçalık
  katalog şeklini bozardı, o yüzden mevcut `PRUDENT` (Zeka huyu) davranışı
  genişletildi: `GameSession.get_effective_manipulation()` PRUDENT'lı bir
  parti için Karizma'ya `PRUDENT_MANIPULATION_BONUS` ekliyor
  (`evt_mutiny`'nin manipüle seçeneği artık bunu okuyor - düşük zekalıları
  ikna kolaylığı) ve `GameSession.apply_event_stress()` PRUDENT'lı
  karakterlerin olay kaynaklı stresini `PRUDENT_EVENT_STRESS_RESIST`
  kadar hafifletiyor (dıştan gelen ikna/motivasyon etkilerine direnç).
  Bu ikinci fonksiyon kasıtlı dar: yalnızca `EventEffectApplier`'ın
  `STRESS` dalı bunu çağırıyor, yol yıpranması/kamp/tempo hâlâ
  `change_stress()`'i doğrudan okuyor - Stress Rules'un ölçülmüş dengesi
  bu fonksiyona hiç dokunulmadan korunuyor.

**#22 (vagon-bazlı envanter + loot crafting) - tasarlandı burada, uygulandı
Faz 15'te (bkz. Development Status'un Faz 15 girişi ve CLAUDE.md Kervan
Envanteri Rules).** Kullanıcının notu ilk triyajdaki "paylaşılan tek
envanter" okumasını düzeltiyor: istenen, kervanın **kendi** vagonlarının
her birinin ayrı bir envanteri olması ve bunların bir crafting sistemine
girdi olması; başkasının (yabancı bir tüccarın) vagonu ise izin verilirse
salt-okunur görüntülenebilir, hiç kullanılamaz. Tasarım notu:

- `Inventory` bugün tek bir `item_id -> miktar` sözlüğü ve tek bir ağırlık
  tavanı (`owned_wagon_count`'a bağlı - bkz. Economy Rules'un "Weight
  binds" maddesi). Yeniden tasarım bunu `GameSession.wagon_inventories:
  Array[Inventory]` yapar - `owned_wagon_count` uzunluğunda, her biri
  kendi tavanına sahip. Pazar/kargo ekranlarının okuduğu "toplam" bir
  toplama fonksiyonundan gelir, tek envanterin yerini almaz; bu yüzden
  mevcut hiçbir ekran aynı anda kırılmaz - yalnızca yeni bir "Kervan Yükü"
  ekranı vagon vagon dağıtımı gösterir/değiştirir.
- Crafting: bir tarif belirli vagonlardaki belirli malzemeleri tüketip
  yeni bir eşya üretir (`RecipeCatalog` + `EventEffect`/ekran eylemi,
  Equipment'ın "parça asla doğrudan karaktere değil önce depoya" kuralıyla
  aynı aile - tarif sonucu önce ilgili vagona yazılır). Hangi vagonun
  girdiyi taşıdığı önemli, yani oyuncu yükünü vagonlar arasında bilerek
  dağıtmak zorunda kalır - "hangi vagonda ne var" ilk kez anlam kazanır.
- Yabancı vagonlar (diğer tüccarların) hiçbir zaman `wagon_inventories`'e
  girmez; ayrı, salt-okunur bir görünüm alır (bir olay ya da lonca
  etkileşimiyle "izin verilirse" açılan bir pencere) - yazma yolu hiç yok,
  yani ekonomiye sızma riski yok.
- **O zaman ertelenme sebebi, ilk PR'ında geçerliliğini korudu.** Bu, tek
  `Inventory`'nin kasıtlı sadeliğini bozan ve ağırlık/kargo testlerinin
  çoğunu yeniden yazan en büyük değişikliklerden biriydi - Faz 15
  `test_game_session.gd`'nin iki ağırlık testini gerçekten yeniden yazdı
  ve kendi PR'ını, kendi test paketini (`test_wagon_inventory.gd`) aldı,
  tam bu notun istediği gibi. Uygulanan şekliyle tek fark: "yabancı vagon
  salt-okunur görünümü" ve ayrı bir "Kervan Yükü" ekranı bu turda da
  kapsam dışı bırakıldı - kullanıcının asıl istediği (vagon başına
  envanter + kişisel çanta + şehirde toplam görünüm + basit bir craft
  menüsü) mevcut ekranların (pazar, Kervan Avlusu) üstüne bindirildi,
  yeni bir ekran icat edilmedi.

**Plana alınmadı, oyuncunun kendi isteğiyle bilerek beklemede (rejected
değil, backlog):** seslendirmeli anlatım ve kombat nidaları (#7, #11 -
gerçek ses kaydı; `AudioManager`'ın şu an sentezlenmiş placeholder'lardan
ibaret olduğu bir prodüksiyon/bütçe kararı - Faz 13 PR-D bunun **metin**
karşılığını zaten kurdu, seslendirme üstüne eklenecek bir katman); iki
dini yaratılış efsanesi + fragman (#12 - lore yönü, şehir mimarisinde din
motifinin bilerek reddedildiği Art Rules'daki cami/minare geri alımıyla
gerginlik taşıyor, fragman da bu kod tabanının işi değil). Üçü de
"sonra üstüne çalışacağız" notuyla plana geri dönebilir - kapatılmadı,
yalnızca beklemede.

Faz 14 ("This War of Mine hissi") - oyunun kendi "çok vanilya, dümdüz bir
kervan oyunu gibi" itirafından doğan bir hat: sanat olmadan da hissettirecek
beş sistemsel değişiklik, hepsi mevcut vokabüleri genişleterek, yeni bir
sistem icat etmeden.

- **A. Herkes ölebilir.** `CombatUnit.can_enter_deaths_door()` tersine
  çevrildi - artık `is_player_character and not is_dead` değil,
  `is_player_side and not is_dead`: Ölümün Kıyısı'na oyuncu tarafındaki
  **herkes** girer, `is_player_character` alanı tamamen kaldırıldı. Zar
  (`deathblow_resist`, varsayılan %67) hâlâ aynı - önce hayata tutunma
  şansı, tutmazsa kalıcı ölüm. `write_back_party()`/`get_dead_characters()`/
  `GameSession.resolve_combat_deaths()` hiç değişmedi, çünkü zaten
  genelciydi (yalnızca kimin lider olduğuna, "kim öldü"ye değil bakıyordu) -
  tek kilit `can_enter_deaths_door()`'daydı. Ölçüm sürpriz çıktı: bkz.
  Ruin Rules'un "kill-sponge" notu - tablo düşmedi, yükseldi, çünkü Kıyı'da
  duran biri artık sahadan çıkmıyor ve düşman AI'ının "en zayıfı vur"
  kuralı yüzünden sağlıklı yoldaşları koruyan bir süngere dönüşüyor.
- **B. İsimli açlık/stres.** `_apply_downed_marks()` artık kimi işaretlediğini
  kayda yazıyor ("X bu çarpışmadan sarsılmış çıktı"), sayı olarak değil.
  Asıl derinleşme C'de - açlığın artık isimle geldiği yer orası.
- **C. Akşam sofrası.** `_run_day()`'in sessizce uyguladığı tek bir
  `daily_consumption` artık bir karar: `MealDistributionPanel` her gün
  beş seçenek sunuyor (herkese/yalnızca ekibe/yalnızca kervana/belirli
  kişilere/yalnızca lidere dağıt), `GameSession.apply_meal_distribution()`
  toplamı (hâlâ `get_daily_provision_consumption()`'dan - formül tek yerde
  kuralı bozulmadı) gruplar arasında bölüştürüp aç kalanı **isimle**
  bildiriyor. Kamp ateşi kararın sahnesi: `RoadCaravan.set_camping()`'in
  görsel ateş+toplanma animasyonu ödünç alınıyor (mekanik "Kamp Kur" hâli
  dokunulmadan), panelin arka planı `SuccessionPanel`in tam siyahı değil
  yolun kendi `%55` alfalı perdesi - ateş arkada görünsün diye.
- **D. Savaş öncesi kadro.** `PreCombatPanel` her çarpışmadan önce kimin
  katılacağını ve bu çarpışmaya özel sırayı soruyor - `party.tscn`'nin
  genel marş sırasına dokunmuyor. Dışarıda kalan risk almaz, XP de
  almaz (`grant_party_xp()`'in artık isteğe bağlı `targets` parametresi);
  düşen izi de (B) yalnızca gerçekten savaşanlardan seçiliyor
  (`_current_combat_party`, tüm parti değil).
- **E. Defter artık kendiliğinden geliyor.** `CaravanLedger` hiçbir satırı
  silmiyordu ama pasifti - yalnızca yol ekranında `Tab`'la açılan
  `CaravanStatusPanel`de görünüyordu. `CityBriefPanel._build_memory()`
  en son üstü çizili satırı (öldü/ayrıldı) her şehir varışında hikâye
  bloğunun sonuna ekliyor - "no need, no row" burada da geçerli, hiç
  üstü çizili satır yoksa blok da yok.

**Bilerek bu turda yapılmayan:** A'nın açtığı denge sorusu (parti 4'ün her
tehlike seviyesinde %100 kazanması) ölçüldü ve kaydedildi ama retune
edilmedi - iki değişikliği aynı pasta ölçmeden üst üste bindirmek bu
dosyanın kendi kuralı. `DEFAULT_DEATHBLOW_RESIST`'i düşürmek en olası
yön, ama kendi ölçümünü ister.

Faz 15 ("Ölçüm ve vagonlar") - Faz 14'ün kendi açık uçlarından biri, ve
kullanıcının uzun süredir istediği en büyük backlog kalemi (#22), aynı
turda:

- **A. Kill-sponge retune - ama tahmin edilen kol değil.** Faz 14'ün notu
  `DEFAULT_DEATHBLOW_RESIST`'i en olası düzeltme diye işaretlemişti. Ölçüm
  bunu çürüttü: direnci 67'den 33'e (ölümcül vuruş zarının neredeyse
  yazı-tura olduğu bir sertliğe) indirmek parti 4'ü hiç kıpırdatmadı
  (%100/%100/%98/%98). Asıl sebep aritmetikti: `EnemyCatalog._build_units()`
  kadroyu `MAX_SQUAD_SIZE`'da (4) kırptığı için parti 3 ile parti 4 zaten
  aynı sayıda düşmanla dövüşüyordu - dördüncü kişi karşılıksız bir fazla
  vurucuydu. Gerçek kol `POWER_SCALE_PER_PARTY_MEMBER` (0.10 → 0.30) çıktı;
  tam ölçüm ve tablo Ruin Rules'ta. `DEFAULT_DEATHBLOW_RESIST` hiç
  değişmedi.
- **B. Kervan Envanteri + Atölye (#22'nin kendisi).** `GameSession.
  wagon_inventories` tek paylaşılan `Inventory`'nin yerini aldı,
  `CharacterData.personal_inventory` küçük bir kişisel taşkın alanı açtı,
  `get_total_quantity()`/`get_total_inventory_entries()` ikisini şehirde
  tek bir toplam olarak gösterdi - kullanıcının kendi tarifiyle "vagonlarımızın
  ve çantamızın toplamı." **İlk sürüm Atölye'yi yanlış yere koydu** - Kervan
  Avlusu'na bir düğme, kervanın toplamını okuyan bir panel - ve düzeltildi:
  craft menüsünün şehirle hiçbir ilgisi yok, oyuncu yolda ilgili vagona
  yürüyüp tıklıyor (`world_hub.gd`'nin artık her vagon için ayrı bir
  etkileşim noktası olması - eskiden yalnızca ilk vagondu, tek paylaşılan
  envanterin kalıntısı bir varsayımdı), açılan `WagonPanel` yalnızca **o
  vagonun** envanterini ve craft menüsünü gösteriyor - `GameSession.
  craft_in_wagon()` kervanın toplamından değil, tıklanan vagonun kendi
  `Inventory`'sinden okuyup yazıyor. Bu, #22'nin asıl istediği şeydi:
  malzeme yanlış vagondaysa orada craftlanamaz. Tam ölçüm, tasarım
  gerekçesi ve neyin bilerek kapsam dışı bırakıldığı (yabancı vagon
  görünümü, ayrı bir "Kervan Yükü" ekranı) Kervan Envanteri Rules'ta.
- **C. Ana menünün tıkla-geç açığı.** "Bir tuşa basın" evresinde düğmeler
  saydamdı ama `disabled` bir düğmenin varsayılan `mouse_filter`'ını
  (`STOP`) değiştirmiyor - fare tıklaması klavye basımının hiç görmediği
  bu yolu (GUI hit-testing) izlediği için, düğmelerin durduğu yere
  tıklamak sessizce yutuluyordu; boş bir alana tıklamak çalışıyordu. Evre
  boyunca düğmelerin `mouse_filter`'ı da `IGNORE`'a çevrilip menü açılırken
  geri alınıyor (bkz. `main_menu.gd`'nin `_set_buttons_mouse_ignore`).

### Çözülmüş: stres eşiği (kayıt için)

`evt_stress_brawl` stres ≥ 70 istiyordu, simülatörde varış stresi ~25'ti -
olay katalogda vardı, oyunda yoktu. Üç kolun üçü birden gerekti (bkz.
Stress Rules): eşik 40'a indi, varış rahatlaması 35'ten 14'e indi ve
günlerle eriyor, kamp rahatlaması 20'den 8'e indi. Üçüncüsü ölçmeden
görünmüyordu: ilk ikisi tek başına yetmiyordu çünkü her sefer kamp kuran
oyuncuda stres hâlâ hiç birikmiyordu.

Sonuç: `evt_stress_brawl` 600 koşuda 2 kez ateşleniyor, playthrough
demosunda dört bacak sonunda stres 18 (eskiden 0).

### Çözülmüş: isyan eşiği (kayıt için)

Bir süre "moral hiç düşmüyor" sanıldı; bu bir **ölçüm hatasıydı**.
`simulate_journeys.gd` morali `finish_journey()`'den *sonra* okuyordu, o
çağrı da kervanı sıfırlıyor (`CaravanState.new()`, moral yeniden 100) - yani
raporlanan sayı seferin morali değil, sıfırlanmış bir kervanınkiydi ve her
koşuda tam olarak 100.0 çıkıyordu. Düzeltildi; simülatör artık varış moralini
*ve* seferin dip noktasını ayrı ayrı basıyor.

Gerçek tablo (200 koşu × 3 tehlike seviyesi):

| tehlike | varış morali | seferin dibi | en kötü | isyan eşiğine (≤25) inen |
|---|---|---|---|---|
| %20 | 62.3 | 61.9 | 37 | %0 |
| %40 | 62.4 | 62.1 | 35 | %0 |
| %65 | 60.3 | 60.0 | 35 | %0 |

Yani moral gerçekten düşüyor (100 → ~60) ama `evt_mutiny` hiçbir koşulda
ateşlenmiyor: katalogda var, oyunda yok. Üç sebep birlikte çalışıyor -
moral her seferde 100'den başlıyor (tasarım gereği: moral o seferin ruh
hali, kalıcı olan stres), günlük bir aşınma yok (yalnızca kesikli olay
darbeleri), ve olay havuzunun moral bilançosu neredeyse başabaş
(+192 / -199).

**Uygulanan çözüm (2+1):** günlük moral aşınması + eşiğin 40'a inmesi.
Üçüncü bir adım da gerekti - eşik tek başına yetmedi, olay ağırlıklı çekimi
hiç kazanamıyordu (bkz. Morale Rules'un son maddesi). Sonuç: varış morali
~55, seferin dibi ~54 (en kötü 20), koşuların %7.5-10.5'i eşiğe iniyor ve
`evt_mutiny` 600 koşuda 6 kez ateşleniyor.

Faz 16 hazırlık notu (CLAUDE.md) - Faz 12'nin dışarıdan-bakış triyajından
kalan altı öneri ve Faz 15'in vagon envanteri tasarım notunun karşılanmayan
iki parçası, oyuncunun kendi elemesiyle karara bağlandı:

**Ana hedeflere terfi etti (artık backlog değil, aktif yol haritasının
parçası):**
- **İki katmanlı "defter" sanat yönüne geçiş** - Faz 12'de "en büyüğü"
  diye işaretlenen öneri, mevcut prosedürel `_draw()` sanatından farklı
  bir görsel kimlik.
- **Gerçek seslendirme + savaş nidaları** (#7, #11) - `AudioManager`'ın
  bugünkü sentezlenmiş placeholder'larının yerini gerçek kayıt alacak;
  Faz 13 PR-D'nin kısa metin yorumları (`unit_barked`) bunun metin
  karşılığı olarak zaten kurulu.
- **İki dini yaratılış efsanesi + fragman/sinematik** (#12).

Üçünün de ne zaman ele alınacağı ayrı bir sıralama kararı - "oyun her an
inşa halinde" olduğu için artık "playtest sonrası" gibi bir eşiğe
bağlanmıyorlar.

**Kıyafet seçimi artık oyunun geri kalanında da görünüyor (Faz 16).**
`OutfitCatalog`/`OutfitPiece` bir süre yalnızca `OutfitPreview`'da
(karakter oluşturmadaki boydan önizleme) okunuyordu - `WalkFigure` (dünya)
ve `CombatFigure` (savaş) `CharacterData.outfit`'e hiç bakmıyordu, yani bir
kıyafet seçimi şu ekranın dışında görünmüyordu. Üç dosyanın da (önizleme +
iki gerçek figür) aynı mantığı okuması için tek doğruluk kaynağı
`OutfitCatalog`'a taşındı: `resolve_color()` (bir slotta parça seçiliyse
onun rengi, değilse verilen fallback), `resolve_torso_color()` (ceket
gömleğin üstünü kapatır - `CaravanPlan.daily_consumption()`'ın "tek
formül, tek yer" kuralının kıyafet karşılığı) ve `resolve_headgear()`
(bir şapkanın `head_shape`'i varsa - `hat_hood`→"hood", `hat_felt`→"cap" -
figür gerçekten farklı bir kafa silüeti çiziyor, kendi rengiyle).
`WalkFigure.set_kind()` ve `CombatFigure.setup()` artık bir `outfit`
parametresi alıyor (varsayılanı boş sözlük); `world_hub.gd`
`character.outfit`'i doğrudan geçiyor, `CombatUnit.outfit` (`from_character`'da
kopyalanan, `from_enemy`'de hiç dokunulmayan - düşmanın kıyafeti yok) aynı
bilgiyi savaş tarafına taşıyor, `CombatUnitSlot.bind()` onu `CombatFigure`'a
iletiyor.
**Her çözümleyici, override yokken tam olarak eski değeri döner** - bu
sistemin en önemli garantisi: kıyafetsiz bir karakter (tayfa, her düşman,
kıyafet seçmemiş bir oyuncu) bu sistem hiç var olmadan önceki hâliyle
birebir aynı çiziliyor, `test_outfit.gd`'nin `override` alanını doğrudan
sınadığı satır bunu kilitliyor. Savaş silüeti küçük ölçekte ayrı bir
ayakkabı/eldiven şekli taşımadığı için `CombatFigure` yalnızca gövde
(ceket/gömlek), bacak (pantolon) ve baş (şapka) alanlarını okuyor;
`WalkFigure` altı slotun tamamını (eldiven/ayakkabı dahil) okuyor - hangi
figürün hangi slotu okuduğu, o figürün gerçekten çizdiği bir şekle karşılık
gelip gelmediğine bağlı, eksiksizlik uğruna yeni bir şekil icat edilmedi.
`Equipment` (kılıç/zırh gibi combat parçaları) tamamen ayrı bir sistem
kalır - `outfit` kozmetik, `equipped` savaşı etkiler; ikisi de karaktere
görsel bir katman eklerken birbirine karışmaz (yukarıdaki "reddedildi"
maddesinin gerekçesi). Gerçek sprite'lar geldiğinde (kullanıcının kendi
sözleriyle "tek tek çizip vereceğim") her slotun kendi rengi zaten kendi
parçasına ait - `OutfitPiece.color`'ın yerini `OutfitPiece.texture`
almasını, hangi figürün hangi `Sprite2D`'yi hangi slotta göstereceğini
bu aynı altı-slot mimarisi belirleyecek; yapı değişmez, yalnızca `_draw()`
çağrıları `TextureRect`/`Sprite2D`'ye yer açar (Art Rules'un genel sprite
geçiş kuralı).

Faz 16 böylece fiilen başladı - kıyafet, genel kervan ekranı,
`evt_roadside_shrine`'ın rota coğrafyasına bağlanması (bkz. Route Terrain
& Weather Rules), yabancı tüccarın vagonuna diyalog yoluyla bakış ve
vagon/parti kondisyonunun yolun gerçek hızını belirlemesi - beşi de
tamamlandı.

**Yabancı tüccarın vagonuna bakış bir diyalog mekaniği olarak uygulandı:
`MerchantDialoguePanel`** (bkz. Kervan Envanteri Rules'un "#22'nin
karşılanmayan" notu). F2 emir menüsünün yeni bir komutu - "Tüccarla
Konuş" - eskort tüccar yoksa kilitli gösteriliyor, kendi sebebiyle
(`UI_ROAD_CMD_TALK_MERCHANT_LOCKED`), aynı "disabled with reason" kuralı
olay seçimi/ekipman/vagon satışında geçerli olduğu gibi burada da.
Birden çok eskort varsa önce bir liste, sonra seçilen tüccarın kendi
görünümü. Kervana kabul edilmiş (eskort olarak taşınan) bir tüccarla
konuşmak izin sorusunu otomatik sorar: `NpcDisposition.LOYAL`/`DESPERATE`
her zaman izin verir, `THIEF`/`VENGEFUL` vermez (bkz.
`GameSession.merchant_grants_permission()`). Reddedilirse üç yol açılır -
**Zorla Bak** (izin gerektirmiyor ama küçük bir itibar bedeli var,
`HagglingSession.WALKOUT_REPUTATION_PENALTY`'nin aynı ailesinden),
**Tekrar İkna Et** (`get_effective_manipulation()` - `evt_mutiny`'nin
manipüle seçeneğiyle aynı vokabüler, yeni bir sistem icat etmiyor) ve
**Vazgeç** (listeye dönüş, hiçbir bedeli yok). **Ödül ekonomik değil,
bilgi**: mizacın kendisi - ve o bile Sezgi eşiğiyle sınırlı
(`NpcDisposition.READ_PERCEPTION_THRESHOLD`), Event Character Rules'un
zaten kurduğu "oyuncuya söylenmez, yalnızca ipucu" kuralının aynısı. Bu
yüzden `#22`'nin tasarım notunun "yazma yolu hiç yok, ekonomiye sızma
riski yok" garantisi burada da geçerli - görüntülenecek bir envanter bile
icat edilmedi, çünkü mizaç zaten kendi başına yeterli bir ödül. Mizaç
tüccarın isminden türetilmiş sabit bir tohumla atanıyor
(`CaravanState.from_plan()`): aynı isimli bir tüccarla ileride tekrar
karşılaşmak hep aynı huyu buluyor.

**Genel bir kervan yönetimi ekranı uygulandı: `CaravanOverviewPanel`.**
Kervan burada gerçekten sembolize ediliyor - her vagon kendi simgesiyle
(`CaravanWagonIcon`, `ArtDraw.wagon()`'u üçüncü bir bağlamda kullanan aynı
fırça, bkz. Art Rules'un "a shape drawn in two places is two different
shapes" maddesi), altında o vagonun yükü/kapasitesi, tayfa sayısı ve
hesaplanan hızı; ayrı bir satırda kervanın **teorik hızı** - vagonların en
düşük hız faktörü (bir kervan en yavaş tekerleğinden hızlı gidemez, bkz.
`GameSession.get_caravan_theoretical_speed()`). Kervan Avlusu'ndan
("Kervan Dökümü" düğmesi, `WagonPanel`'inkiyle aynı sahnesiz `CanvasLayer`
deseni) açılıyor - `CaravanStatusPanel`'in yol ekranındaki salt-okunur
dökümüyle akraba ama onun yerine geçmiyor, o bir Tab paneli, bu ayrı bir
ekran.
**İlk sürümdeki bilinçli sapma**: istenen "açlık/moral" yerine yalnızca
**stres** gösteriliyordu - Stress Rules'un kendi ayrımı gereği moral o
seferin ruh hali (yalnızca bir yolculuk sırasında anlamlı), stres kalıcı
olan (her zaman okunabilir); şehirden açılan bir ekranda seferin *anlık*
moralini göstermek sefer dışındayken anlamsız bir sayı olurdu, ve kalıcı
bir açlık stat'ı da hiç var olmadı (açlık yalnızca yolda anlık bir olay).

**Sonradan tamamlandı: sapma "moral yok" değil "yanlış moral" sorunuymuş.**
Planlayıcı zaten "bugün yola çıksan moral ne olurdu" sorusunun gerçek bir
cevabını taşıyordu (`GameSession.get_departure_morale()`) - şehirden
sorulabilecek moral zaten buydu, seferin anlık moralinin *yerine* değil,
onun *yokluğunda* okunabilecek doğru sayı. Yeni bir "Sefer Hazırlığı"
bölümü bunu (ve kendi dökümünü, `get_departure_morale_breakdown()` -
planlayıcının `_refresh_departure_morale()`'ıyla aynı format, aynı çeviri
anahtarı `UI_PLANNER_DEPARTURE_MORALE`, iki ekranda iki farklı sayı
okunmasın diye) ekliyor. Açlık için de aynı mantık: kalıcı bir açlık stat'ı
icat etmek yerine **erzak otonomisi** gösteriliyor - toplam erzak günlük
tüketime bölününce kaç gün dayanacağı (`GameSession.get_total_quantity`/
`get_daily_provision_consumption`), yani "şu an aç mısın" değil "yeterince
stokladın mı" sorusunun cevabı, `PROVISIONS_WARNING_DAYS`'in altına inince
kırmızıya dönüyor - `DebtPanel`'in vade rengi gibi bir aciliyet gradyanı
değil ama aynı "gizli bir eşik bir hatadan farksızdır" disiplini. Stres
kaldırılmadı, yanına eklendi: kalıcı olan (stres) ve o gün sorulabilecek
olan (çıkış morali, erzak otonomisi) artık aynı ekranda, hangisinin ne
anlama geldiği karışmadan yan yana duruyor. Kervandaki herkesin kısa bir
"düşüncesi" (stres/can okunarak seçilen bir satır, Faz 13 PR-D'nin kısa
savaş yorumlarıyla aynı disiplin - metin, yeni sistem değil) da burada.
**Vagon hızı artık yolun gerçek yürüyüş hızını da belirliyor - iki karar
aynı pastada, ama ölçülerek.** `get_caravan_theoretical_speed()` sadece
vagonların yük faktörünü değil, partinin kendi kondisyonunu da okuyor:
`get_party_condition_speed_factor()` `DutyCatalog.get_condition_
multiplier()`'ın aynı formülünü (kırılmış ya da canının yarısının
altındaki biri daha az katkı verir) görev gücüne değil yürüyüş hızına
uyguluyor - aynı "kondisyon" kelimesi iki sistemde de aynı sayı olsun
diye, formül ikinci kez yazılmadı. Kervanın teorik hızı ikisinin
**en düşüğü**; `road_journey.gd`'nin tek yürüme kapısı `_walk_at()`
artık bunu tempo ve havanın yanına üçüncü çarpan olarak ekliyor - tam
kondisyonda ve boş vagonda çarpan tam 1.0, yani eski davranış aynen.
Ruin Rules'un "measure before wiring into balance" disiplini burada da
işletildi: bu yavaşlama Provision Rules'un "correct stocking never
starves" sözünü bozabilirdi, o yüzden `RouteWeather.forecast_extra_days()`
bir `condition_factor` parametresi aldı ve hava ile kondisyonu **aynı
günlük yürüyüşte çarpıyor** - ikisini ayrı ayrı hesaplayıp toplamak
bileşik yavaşlamayı hafife alırdı (weather_avg × condition ≠ weather_avg +
condition - 1). Alanın adı da bu yüzden `CaravanPlan.weather_reserve_
days`'ten `travel_reserve_days`'e değişti: artık ikisinin bileşik payını
taşıyor. Planlayıcı bunu **yola çıkış anındaki** kondisyonla hesaplıyor
(can zaten tam - `finish_journey()` şehir varışında iyileştiriyor -,
stres ve vagon yükü o an ne ise); sefer ortasında alınan bir yara bu
tahmini aşabilir, ama bu weather'ın kendisinin de paylaşmadığı bir risk
değil - `HUNGRY_PACE_MULTIPLIER` gibi geri besleme etkileri de hiç
forecast edilmiyor, aynı kabul.

**Faz 16-C: oyunun ilk elle çizilmiş (AI-üretimli) sanat varlığı.** Art
Rules'un uzun süredir yazdığı "henüz asset dosyası yok" cümlesi artık tam
doğru değil - `data/assets/ui/ledger_mockup/` bir masa sahnesi taşıyor,
Gemini ile üretilmiş. **İlk deneme (deri kaplı bir `StyleBoxTexture`,
panelin kendi zemini) kullanıcının kendi referans görseliyle hiç
örtüşmüyordu** - küçük, düz bir doku parçasıydı, referansın zengin "masa
başında duruyorsun" sahnesi değildi. Doğru çözüm panelin kendi zemini
değil, **`guild.tscn`'in tüm ekranını kaplayan tek bir arka plan
illüstrasyonu** çıktı (`guild_desk_bg.jpg` - açık bir defter, mum, mürekkep
hokkası, balmumu mühür, altın sikkeler): `BackgroundArt` (`TextureRect`,
`STRETCH_KEEP_ASPECT_COVERED` + `EXPAND_IGNORE_SIZE`, oran ne gelirse
gelsin kırpılarak dolduruyor) `MarginContainer`'ın **altında**, aynı sırada
bir `BackgroundScrim` (%35 siyah) ile - metin defterin boş sayfalarının
üstünde okunur kalsın diye. `DebtPanel` artık kendi zeminini çizmiyor -
panelin deri dokusu masa arka planıyla çakışırdı, tek görsel imza olarak
yalnızca başlığın yanındaki mühür ikonu kaldı.
**İkinci bir tuzak, `MapPanel`'in aynısı (bkz. Art Rules):**
`TabContainer`'ın varsayılan `panel` stylebox'ı - koyu gri, yarı saydam bir
kutu - sekme içeriğinin arkasına otomatik çiziliyor ve tam defterin boş
sayfalarının üstüne oturuyor, sahneyi görünmez kılıyordu. Aynı çözüm:
`TabContainer` artık açık bir `StyleBoxEmpty` (`theme_override_styles/
panel`) taşıyor. Bu ekranın dışındaki hiçbir yer bu sahneye geçmedi -
kullanıcı "genel gri arka plan sorununu da çözelim" dediğinde bilerek
**ekran ekran arka plan görseli** yolu seçildi (kod-tabanlı tek bir Theme
kaynağı değil), yani her önemli yönetim ekranı (Pazar, Taverna, Kervan
Avlusu) kendi Gemini sahnesini isteyecek - aynı üretim tarifi (stil satırı
sabit, masadaki nesneler ekrana göre değişir, merkezde metin için sakin/
boş bir bölge) tekrar kullanılabilir ama her biri kendi turu. Kilim deseni
hâlâ **kullanılmadı** - kenar motifleri "S" harfini tekrarlıyor, üretim
hatası, Localization Rules'un "hiçbir görselde yazı olmaz" kuralını ihlal
ediyor.

**Aynı tarif üç yönetim ekranına daha uygulandı: Pazar Meydanı, Taverna,
Kervan Avlusu.** `market.tscn`/`tavern.tscn`/`caravan_yard.tscn` Lonca ile
aynı iskeleti (`MarginContainer` > `VBoxContainer` > başlık/liste/geri
düğmesi) paylaştığı için aynı `BackgroundArt`/`BackgroundScrim` ikilisi
değişmeden tekrar kullanıldı - stil satırı sabit tutuldu (aynı ink-wash
palet), yalnızca masadaki nesneler ekrana göre değişti (terazi/çuval/
kavanoz Pazar'da, maşrapa/harita/hançer Taverna'da, nal/urgan/tekerlek
Kervan Avlusu'nda). Hiçbiri `TabContainer` kullanmadığı için Lonca'daki
gri panel tuzağı burada hiç oluşmadı - üçü de ekstra bir `StyleBoxEmpty`
gerektirmedi.

Faz 17 ("Temel") - oyuncunun elle tuttuğu, sayfa sayfa okunmuş bir "Wayborne
Codex 2" çıktısından toplanan onlarca notun triyajı sonunda kararlaştırılan,
çok PR'lık bir hat. Triyaj üç kefeye ayrıldı (zaten karşılanan, mevcut kasıtlı
tasarımla çelişen, gerçek yeni iş) ve iki büyük madde - her karara stat
check'i işlemek, huy sistemini davranışsal bir ikinci katmana genişletmek -
oyuncunun kendi kararıyla **onaylandı ve büyütüldü**: "3-4 event değil tüm
eventlere", "ayrı bir kefeye koyma, mevcut kefeyi genişlet, ultra geliştir".
Dokuz PR'lık bir plana döküldü, her biri kendi commit'iyle gönderiliyor.

**PR-1 (sekiz stat omurgası) tamamlandı.** `CharacterStats` altıdan sekize
çıktı: mevcut altısı (Güç/Çeviklik/Dayanıklılık/Zeka/Sezgi/Karizma) savaşın
omurgası kalıyor, iki yenisi (**Bilgelik**, **İnanç**) kasıtlı olarak savaşa
hiç dokunmuyor - her biri kendi "dünya" alanını açıyor. Gerekçe Divinity:
Original Sin 2'den geliyor: attribute'lar savaşı açar, civil stat'lar dünyayı
açar, ikisi ayrı bütçedir - aksi halde (altı stat check'e girseydi) her check
Zeka/Karizma'ya düşer, kalan statlar dump stat olurdu; bu tam olarak
Progression Rules'un zaten kaydettiği dump-stat tuzağı. Sekiz stat, sekiz
check alanı garantiliyor.

- **Bilgelik** = "yargı": tecrübeden öğrenme hızı. `CharacterData.
  get_xp_bonus_percent()` (taban 0, ±%40 tavanlı) `gain_xp()`'in kazandığı
  miktarı ölçekliyor - Bilgelik 5'te (taban) `round(amount * 1.0)` yani eski
  davranışla birebir aynı, dosyanın her formülünün kendi kuralı.
- **İnanç** = "irade": Ölümün Kıyısı'nda hayata tutunma. `CharacterData.
  get_deathblow_resist_bonus()` `CombatUnit.DEFAULT_DEATHBLOW_RESIST`'in
  (67, Faz 15-A'nın ölçüp doğru bulduğu sabit - **dokunulmadı**) üstüne
  kişisel bir ek biner, `MAX_DEATHBLOW_RESIST` (90) tavanlı - "bir stat bir
  sistemi asla tamamen kapatmaz" kuralı burada da geçerli, en dindar
  karakter bile ölümsüz olamaz.
- Bu iki formül **bilerek dar tutuldu**: "öğüt verme" (Bilgelik) ve
  "umutsuzluğa direnç/ritüel" (İnanç) PR-2'nin (skill-check) ve PR-3'ün
  (huy/arındırma) işi - her PR'ın diff'i kendi iddiasıyla sınırlı kalsın
  diye, tıpkı Equipment'ın PR-A/PR-B ayrımındaki disiplin gibi.
- Beş kültürün `stat_bonuses`'ına birer küçük eğilim eklendi (Göçebe
  Bilgelik +1 - oyuncunun kendi isteği, arazi/yıldız okuma; Vadi İnanç -1 -
  dünyevi lonca hesabı; Dağ İnanç +1 - ayin bağlı kabile; Liman Bilgelik +1
  - rıhtımın gördüğü dünya çeşitliliği; Balıkçı İnanç +1 - fırtınaya karşı
  dua). Sınıfların `stat_affinity`'sine bilerek dokunulmadı - bu iki stat
  otomatik dağıtımda yalnızca sınıf yatkınlığı tavan yaptıktan sonra
  (`_pick_stat_to_invest`'in `KIND_ORDER` yedeği) devreye giriyor, yani asıl
  büyümeleri oyuncunun kendi elle yatırımıyla.
- `character_creation.gd`'nin `STAT_POINTS`'i 6'dan 8'e çıktı - altı stat
  için oran 1.0 puan/stat'tı, sekiz stat aynı oranı koruyor. Karakter
  oluşturma ve karakter ekranının stat bölümleri zaten `KIND_ORDER` üzerinden
  genel döngüyle kuruluyordu (bkz. Faz 6 PR-B), yani iki yeni satır hiçbir
  ekran kodunu değiştirmeden kendiliğinden belirdi - genel döngü kuralının
  ödediği faiz.
- Eski kayıtlar dokunulmadan yükleniyor: `CharacterStats.from_dict()`
  eksik `"wisdom"`/`"faith"` anahtarlarını `BASE_VALUE`'ya (5) düşürüyor,
  ki bu zaten "bu sistem hiç yokmuş gibi davran" değeri - ayrı bir migrasyon
  kancası gerekmedi, `test_save_migration.gd` bunu doğrudan sınıyor.

**PR-2 (skill-check omurgası) tamamlandı.** Oyuncunun kendi sözleriyle: *"her
kararın arkasında bir skill check mekanizması olmalı"* ve *"3-4 event değil
tüm eventlere, oyunun temeline işle."* Bu, yeni bir çözümleyici icat etmeden
yapıldı - `SkillCheck` (`scripts/events/skill_check.gd`) mevcut ağırlıklı-
sonuç mimarisinin (`EventOutcome`/`EventCondition`) üstüne oturuyor.

- **Zar, context'e yazılan bir sayı.** `EventEngine.resolve_check(choice,
  context)` `choice.check` varsa context'in bir **kopyasını** alıp içine
  `"check_tier"` (0 = başarısızlık, 1 = kıl payı, 2 = tam başarı) yazıyor -
  orijinal context değişmiyor. `EventOutcome.conditions` bunu sıradan bir
  `GREATER_EQUAL`/`EQUAL` koşuluyla okuyor, yani check_tier `EventCondition`in
  zaten bildiği bir anahtardan farksız. `road_journey.gd`'nin `_on_choice_
  pressed()`'ı artık `resolve_check()`'i `resolve_outcome()`'dan önce
  çağırıyor; `playthrough_demo.gd`/`simulate_journeys.gd`/`simulate_career.gd`
  üçü de aynı sırayı taklit edecek şekilde güncellendi - yoksa simülatör her
  check'i her zaman başarısızlık okurdu (bkz. Testing'in "harnessten önce
  oyundan şüphelen" disiplini).
- **Şans formülü** `SkillCheck.compute_chance(effective_stat, difficulty) =
  clamp(round(50 + 6*(effective_stat - difficulty)), 5, 95)` - taban statta
  (etkin değer 0) %50, hiçbir stat şansı 5/95'in dışına çıkaramıyor (hit
  chance'in kendi MIN/MAX'ıyla aynı "bir sistemi hiçbir stat kapatamaz"
  kuralı). Başarı bandının üst %15'i "tam başarı" (tier 2), kalanı "kıl payı"
  (tier 1).
- **İki kaynak, iki farklı anlam.** `SkillCheck.Source.LEADER` yalnızca
  liderin kendi statını okur (kişisel bir kumar - kaçmak, sunaktan bir şey
  almak, kalabalığı sakinleştirmek); `PARTY_BEST` partideki en iyi statı
  okur (ortak bir çaba - defter incelemek, fırtınada yol almak, dedikoduyu
  çözmek). `get_leader_effective_stat()` `CharacterData.is_player`
  bayrağını okuyor, yani liderlik `SuccessionPanel` ile el değiştirse bile
  doğru kişiyi bulmaya devam ediyor - ayrı bir "succession-aware" mantık
  gerekmedi.
- **Context anahtarları jenerik üretildi.** `GameSession.
  _build_skill_check_context()` `CharacterStats.KIND_ORDER`'ın sekiz
  statının hepsi için `best_<stat>`/`leader_<stat>` yazıyor - yeni bir stat
  (bkz. Wisdom/Faith) eklendiğinde bu fonksiyonun kendi kodu değişmeden
  otomatik kapsanıyor, `character_creation.gd`'nin `KIND_ORDER` döngüsüyle
  aynı disiplin.
- **`EventChoice.get_check_preview()`** düğme metnine `"Stat · %XX"` ekliyor -
  Faz 13 PR-E'nin hint sistemiyle aynı aile ("New Vegas'ın skill-check
  önizlemesi"): zarı değiştirmiyor, yalnızca oyuncuyu neye bahse girdiği
  konusunda bilgilendiriyor. `evt_party_investigation`'ın suçlama seçeneği
  bunun ilk gerçek örneği: Faz 13'te ipucu (`hint_text_key`/`hint_stat`)
  yalnızca flavor'du, zar hâlâ %50/%50'ydi. Faz 17 bunu **tamamlıyor** - ipucu
  artık gerçek bir Sezgi check'inin önizlemesi, kaldırılmadı, çünkü "neye
  bahse giriyorsun" sorusunu iki farklı açıdan (flavor + yüzde) söylüyor.
- **On altı olay check'e bağlandı, sekiz statın hepsi en az bir yerde
  kullanılıyor** - hiçbir stat "check havuzunda hiç görünmeyen" bir dump
  stat kalmasın diye (Progression Rules'un zaten kaydettiği dump-stat
  tuzağının check tarafındaki karşılığı):
  - **Güç**: `evt_landslide` (vagonu göçükten itmek), `evt_culture_
    highland_challenge` (dağ kabilesinin Güç Sınavı), `evt_stress_brawl`
    (kavgaya araya girmek - oyuncunun kendi verdiği örnek).
  - **Çeviklik**: `evt_customs_checkpoint`/`evt_guard_patrol` (kaçmak),
    `evt_wild_animal` (sıyrılmak).
  - **Dayanıklılık**: `evt_storm` (fırtınada yol almak, üç kademeli).
  - **Zeka**: `evt_culture_valley_dispute` (defter hakemliği).
  - **Sezgi**: `evt_party_investigation` (suçlamak), `evt_forgotten_cache`
    (nereyi kazacağını okumak, dört sonuçlu).
  - **Karizma**: `evt_mutiny` (sert emir), `evt_merchant_caravan` (yol
    takası).
  - **Bilgelik**: `evt_culture_port_gossip` (dedikoduyu ayıklamak, dört
    sonuçlu).
  - **İnanç**: `evt_troubled_night` (huzursuz gece), `evt_roadside_shrine`
    (adakları almak).
- **İki kalıp, seçeneğin kaç dalı olduğuna göre.** `_checked_choice()` iki
  kademeli (başarı = `check_tier >= 1`, başarısızlık = `check_tier == 0`) -
  çoğu dönüşüm bunu kullanıyor. Üç kademeyi ayrı ayrı okumak isteyen olaylar
  (`evt_storm`, `evt_forgotten_cache`, `evt_culture_port_gossip`)
  `_outcome_if()` ile elle üç (ya da dört) dal kuruyor - ikisi de aynı
  `check_tier` koşulunu okuyor, farklı olan yalnızca kaç dal olduğu.
- **Her check kasıtlı olarak dar bırakıldı: yalnızca gerçek bir belirsizlik
  taşıyan seçenekler dönüştürüldü.** Önceden ya sabit bir ağırlıklı zar
  (`evt_forgotten_cache`, `evt_landslide`, `evt_culture_highland_challenge`,
  `evt_culture_port_gossip`, `evt_roadside_shrine`, `evt_guard_patrol`,
  `evt_merchant_caravan` - hepsi stat'tan bağımsız sabit bir olasılıkla
  çekiliyordu) ya da hiç zar içermeyen deterministik bir sonuçtu
  (`evt_wild_animal`'ın kaçışı, `evt_stress_brawl`'ın araya girmesi) - şimdi
  ikisi de partinin gerçek yetkinliğini okuyor. **Kasıtlı olarak
  dönüştürülmeyenler** üç ailede toplanıyor, üçü de mevcut kasıtlı
  tasarımlarla çelişmemek için: mizaç-tabanlı olaylar (`evt_road_wanderer`,
  `evt_stowaway` ve zincirleri) - `NpcDisposition` zaten kimlik-açığa-çıkarma
  mekaniği, statla karışırsa iki sistem bulanıklaşır; kaynak-kilitli
  deterministik alışverişler (`evt_broken_axle`'ın onarımı, `evt_sick_
  merchant`'ın tedavisi, `evt_traveling_tinker`'ın alışverişi) - "altın öde,
  garanti sonuç al" burada kasıtlı bir tasarım, üstüne bir zar bindirmek
  Provision Rules'un "doğru stoklama asla açlık çekmez" sözüyle aynı aileden
  bir garantiyi bozardı; ve `evt_bandit_ambush`'ın OPT_HAGGLE'ı - zaten
  `TRIGGER_HAGGLING`'i açıyor, yani gerçek `HagglingSession`'ın kendi
  ret/ultimatum mekaniği zaten oradaki "pazarlık reddedilebilir" sorusunu
  cevaplıyor, ikinci bir zar eklemek aynı belirsizliği iki kez modellemek
  olurdu.

**PR-3 (huy sistemi ultra genişleme) tamamlandı.** Oyuncunun kendi sözleriyle:
*"Kervan görevleri/huylar, üstüne ekle ama ayrı bir kefeye koyma, mevcut
kefeyi genişlet, ultra geliştir"* ve *"Project Zomboid gibi olmalı, [başka bir oyunda]
olduğu gibi psikolojik etkileri olan trait/perkler de olmalı."* İki iş
birlikte: on iki huyluk katalog on altıya çıktı (Bilgelik/İnanç'ın kendi
huyları), ve her huy - eski on iki dahil - artık savaşın dışına da taşan
küçük bir davranışsal kanca taşıyor.

- **On altı huy, sekiz stat.** `KEEN_MIND`/`DULL_WIT` (Bilgelik) ve
  `STEADFAST_FAITH`/`WAVERING_FAITH` (İnanç) mevcut on ikiye eklendi -
  "bir stat bir virtue bir affliction" kuralı bozulmadı, yalnızca sekiz
  stata genişledi. `test_traits.gd`'nin katalog testi artık her stat×kutup
  kombinasyonunun tam bir kez dolu olduğunu da doğruluyor (`seen_stats`),
  yalnızca sayıyı değil.
- **`check_bonus` - her huy artık PR-2'nin skill-check sistemine bağlı.**
  `TraitCatalog._make()` her huyun `check_bonus`'unu `is_positive`'ten
  jenerik türetiyor (±0.5, `CHECK_BONUS_MAGNITUDE`) - bir virtue kendi
  `affinity_stat`'ının check'lerini biraz kolaylaştırır, bir affliction
  biraz zorlaştırır. Bu, huy başına elle yazılmış bir flavor mekaniği
  icat etmeden **on altı huyun tamamını** aynı anda check sistemine
  bağladı. `GameSession.get_best_effective_stat()`/
  `get_leader_effective_stat()` artık `stats.get_effective_value(kind)`'a
  `character.get_check_modifier(kind)`'ı ekliyor - `SkillCheck`'in kendisi
  hiç değişmedi, yalnızca ona giden sayı huyu da taşıyor.
- **`refusal_bonus` - "irrasyonel davranış" katmanı.** Aynı jenerik
  türetme (`REFUSAL_BONUS_MAGNITUDE`, ±2): bir virtue zaten kırılmış
  (`CombatUnit.is_stressed`) bir birimi biraz sakinleştirir, bir affliction
  biraz tetikler. **Kasıtlı olarak yalnızca zaten kırılmış bir birimde
  devreye giriyor** - kırılma eşiğinin kendisini (`get_stress_resistance()`)
  değiştirmiyor, yalnızca eşiği aşmış birinin o an ne kadar dinleyeceğini.
  `CombatEncounter._try_refuse_order()`'ın formülü `clampi(STRESS_REFUSAL_
  CHANCE - composure + refusal_bonus, MIN, MAX)` oldu - yeni `MAX_STRESS_
  REFUSAL_CHANCE` (95) sağlam huyların da bu ihtimali asla sıfırlayamamasını
  garanti ediyor, "bir stat bir sistemi asla tamamen kapatmaz" kuralının
  huy tarafındaki aynısı.
- **Üç stat-özel pay, yalnızca kendi statının huylarında dolu.**
  `xp_gain_bonus_percent` (Keskin Zihin/Kalın Kafa) `get_xp_bonus_percent()`'in
  Bilgelik payının üstüne biniyor; `deathblow_resist_bonus` (Sarsılmaz/
  Sarsılmış İnanç) `get_deathblow_resist_bonus()`'un İnanç payının üstüne;
  `stress_resistance_bonus` (Demir/Zayıf Bünye - **mevcut** iki huya
  eklendi, yeni huy değil) `get_stress_resistance()`'ın Dayanıklılık
  payının üstüne. Üçü de PR-1'in zaten kurduğu üç formülün **aynısı** -
  yeni bir paralel sistem değil, aynı formüle huyun kendi payını eklemek.
  Taban stat 5'te, huysuz bir karakterde üçü de tam sıfır - "fresh
  character unchanged" garantisi burada da geçerli.
- **Üç kanca, sonradan tamamlandı (task listesinin ilk taslağında "ölçmeden
  bağlanmadı" diye ertelenmişti, ayrı bir geçişte kapatıldı).** Günlük stres
  kazancı, çıkış morali ve pazar fiyatı - üçü de Stress/Morale/Economy
  Rules'un **global** sabitlerini (`ROAD_STRESS_PER_DAY`,
  `get_departure_morale()`, `get_buy_price_multiplier()`) taşıyordu ve o
  sabitlere doğrudan bir huy çarpanı eklemek onların ölçülmüş tablolarını
  sessizce geçersiz kılardı. Çözüm sabitleri değiştirmek değil, **her formüle
  kendi küçük, tavanlı payını eklemek** oldu - tıpkı `check_bonus`/
  `refusal_bonus`'un zaten yaptığı gibi:
  - **Günlük stres artık kişiye göre bükülüyor, partiye göre değil.**
    `CharacterData.get_daily_stress_gain_multiplier()` yalnızca Demir/Zayıf
    Bünye'nin (Dayanıklılık) zaten var olan `stress_resistance_bonus`'unu
    okuyor - üçüncü bir alan icat etmek yerine PR-3'ün ilk turunun kurduğu
    aynı alana ikinci bir formül bindirildi, tıpkı `deathblow_resist_bonus`/
    `xp_gain_bonus_percent`'in kendi statlarına iki formül bindirmesi gibi.
    `GameSession._apply_road_stress_day()` artık `change_stress(ROAD_
    STRESS_PER_DAY)`'i tek seferde çağırmak yerine partiyi tek tek dolaşıp
    her karakterin kendi çarpanını uyguluyor - `ROAD_STRESS_PER_DAY`'in
    kendisi (2) hiç değişmedi, yalnızca kime ne kadarının işlediği değişti.
    **Ölçülen bir tuzak**: ilk katsayı (±%1/puan) `round()`'un içinde tamamen
    kayboluyordu - `round(2*0.95)` ve `round(2*1.05)` ikisi de 2'ye
    yuvarlanıyor, yani huy hiçbir günde gözlemlenebilir bir fark
    yaratmıyordu. Küçük bir günlük taban (`ROAD_STRESS_PER_DAY = 2`), her
    yuvarlamanın bağımsız olduğu bir formülde, ancak orantısız büyük bir
    yüzde ile hayatta kalıyor: katsayı ±%6/puan'a çıkarıldı - ±5 puanlık tek
    bir huy artık çarpanı doğrudan kendi tavanına (`0.7`/`1.3`) itiyor, tek
    bir günde bile farklı yuvarlanmış bir delta üretiyor.
  - **Çıkış morali artık kervanın mizacını da okuyor.** "Güven Verici"nin
    kendi adı zaten bir moral vaadiydi ama huy yalnızca savaşta bir dodge
    puanıydı. `GameSession.get_departure_temperament_bonus()` partideki
    her Karizma huyunun yeni `morale_bonus` alanını topluyor
    (`DEPARTURE_TEMPERAMENT_BONUS_CAP` = 6 tavanlı - bir tek huy hardship/
    stres payını ezmesin diye) ve `get_departure_morale()`'e eklendi;
    `get_departure_morale_breakdown()` de yeni bir `UI_MORALE_TEMPERAMENT`
    satırı kazandı - "rakam görünüyorsa nedeni de görünmeli" kuralı burada
    da geçerli.
  - **Fiyat artık partinin şeytan tüccarlığını da okuyor.** Tedbirli
    (PRUDENT)/Saf (NAIVE) - Zeka'nın huyları - zaten savaş isabetini
    etkiliyordu, "kurnazlık" pazara hiç taşınmamıştı.
    `GameSession.get_trait_price_multiplier()` partideki her Zeka huyunun
    yeni `price_discount_percent` alanını toplayıp `MIN/MAX_TRAIT_PRICE_
    MULTIPLIER` (0.85-1.15) tavanlı bir çarpana çeviriyor;
    `get_buy_price_multiplier()` artık `get_player_culture().
    buy_price_multiplier * get_trait_price_multiplier()` - kültür payının
    yanına ikinci bir çarpan olarak bindirildi, tek çağıran (`market.gd`)
    hiç değişmedi.
  Üçü de aynı garantiyi taşıyor: huysuz bir karakterde/partide üç formül de
  tam olarak eski davranışı üretiyor (çarpan 1.0, pay 0) - "fresh character
  unchanged" kuralı bu geç bağlanan kancalarda da bozulmadı. Sinyal sıklığı
  (Road Layer Rules'un `AFFLICTION_SPAWN_BONUS`'u) bilerek dokunulmadı -
  zaten jenerik bir "kaç affliction taşıyorsun" sayacı, huy başına ayrı bir
  pay eklemek aynı sistemi iki kez modellemek olurdu.

**PR-4 (görev mimarisi + büyük dünya olayları) tamamlandı.** Oyuncunun kendi
sözleriyle: *"gerekirse tüm görev yapısını baştan yaz ama daha büyük
olayları hesaba ve oyuna kat."* `DutyCatalog`'un altı kervan görevi
(Muhafız/İzci/Levazımcı/Arabacı/Tellal/Otacı) zaten altı canlı sisteme
bağlı, sağlam bir mimari - baştan yazmayı gerektiren bir kusuru yoktu, o
yüzden bu PR "görev" kelimesinin RPG anlamını (lonca görevi/commission)
karşılayan, gerçekten eksik olan katmana odaklandı: haritanın büyük, adlı
olayları ve loncanın onlara bağlı özel görevleri.

- **`WorldEvents` (`scripts/travel/world_events.gd`) `MarketConditions`'ın
  "süreli şok" desenini genelliyor.** Dört tür - Bölgesel Savaş, Veba,
  Ticaret Fuarı, Haydut Haracı - ikisi rota hedefli (savaş/haraç), ikisi
  şehir hedefli (veba/fuar). **Kendiliğinden atılmıyor** - `RouteConditions`'ın
  doğal durumlarının aksine bir "hava" değil, yolda duyulan bir haberle
  başlıyor: `EventEffect.Type.WORLD_EVENT_START` (yeni bir etki tipi,
  `ROUTE_CHANGE`'in "current" kısayol kuralını aynen kullanıyor) beş yeni
  yol kartından biri (`evt_regional_war_news` ve dört kardeşi) çekilince
  devreye giriyor. Her "haber" olayının koşulu aynı türden bir olayın o
  hedefte zaten aktif olmadığını şart koşuyor (`route_has_X <= 0`), yoksa
  aynı yolda üst üste savaş açılıp tehlike sınırsızca katlanabilirdi.
- **Rota tehlikesine payı `RouteConditions`'ın kendi headroom formülüyle**
  (`base + delta * (1 - base)`) ekleniyor - `GameSession.get_route_danger()`
  artık `world_events.get_route_danger_delta()`'yı da bu formüle katıyor,
  iki katman (çığ/eşkıya *ve* savaş) aynı anda aynı rotayı vurabiliyor.
  Ambush/wildlife ağırlıkları zaten danger'a bağlı olduğu için (bkz. Ruin
  Rules) savaş bölgesi ayrı bir savaş mekaniği icat etmeden "daha çok
  haydut" olarak kendiliğinden hissettiriyor.
- **Şehir çapındaki fiyat etkisi (veba/fuar) `MarketConditions.add_shock()`'un
  kendisi üstünden** - `WorldEvents.CITY_PRICE_MULTIPLIER` yalnızca büyüklüğü
  taşıyor, gerçek fiyat mekaniği ikinci bir motor olarak yazılmadı.
- **Harita görünürlüğü** `world_map.gd`'ye eklendi - `_city_event_suffix()`/
  `_route_event_suffix()` şehir düğmesine/rota özetine olayın adını ve
  (dolaylı olarak, `WorldEvents.get_active`'in `until_day`'i üstünden)
  süresini ekliyor, "gizli bir ceza bir hatadan farksızdır" kuralının
  (bkz. Economy Rules'un piyasa şoku maddesi) aynısı burada da geçerli.
  `world_map.gd` kod-tabanlı bir yönetim ekranı olduğu için (`_draw()`'lı
  dünya sahneleri değil) bu yalnızca düğme metnine bir satır ekliyor, yeni
  bir çizim gerekmedi.
- **Lonca özel görevleri (`guild.gd`'nin üçüncü sekmesi, "Özel Görevler")**
  `MerchantOffer`'ın kabul/taşı/teslim mimarisini tekrar icat etmiyor -
  dört görev kervan hangi şehirdeyse orada **anında** tamamlanıyor
  ("lonca olan biteni zaten duymuş, senden yalnızca katkıyı istiyor"
  kurgusu). Her biri bir `WorldEvents.Kind`'a bağlı (aktif değilse kilitli,
  kendi sebebiyle - `get_commission_block_reason()`, locked event choice/
  vagon satışı/craft'ın hepsinde tekrarlanan "disabled with reason" kuralı)
  ve haritanın **her yerinde** duyulabiliyor - kervanın o an nerede olduğuna
  bakmıyor (`WorldEvents.get_active_by_kind`), çünkü lonca haberi şehirler
  arası taşır. Cepheye Erzak (erzak öder, altın+itibar kazandırır), Veba
  İlacı (Otacı İksiri öder), Fuar Sponsorluğu (altın yatırır, kârıyla
  geri alır), Haraç Bölgesi İstihbaratı (altın öder, yalnızca itibar
  kazandırır - istihbarat ekonomik değil bilgi ödülü). `GameSession.
  fulfill_commission()` tek kapı: `get_commission_block_reason()` boş
  değilse hiçbir şey yapmadan false döner - "hepsi ya da hiçbiri" kuralı,
  yarım uygulanan bir görev (parayı al, ödülü verme) craft'ın/kargonun
  aynı kuralını bozardı.
- **Bilerek kapsam dışı bırakılan (ölçmeden bağlanmadı):** savaş/haraç
  bölgelerinin kendi road kartı zincirleri (askeri kervan/mülteci kolonu
  gibi) - `evt_military_convoy`/`evt_refugee_column` zaten "traveler"
  kategorisinde var, WorldEvents'e bağlı yeni bir zincir açmak bu PR'ın
  kapsamını aşardı, gerçek bir follow-up.
- **Sonradan tamamlandı: `MerchantOffer` tarzı "kabul et, taşı, teslim
  et" iki lonca vagon görevi.** Yukarıdaki "iki paralel taşıma mekaniği
  icat etmek yerine anında-tamamlanan tasarım seçildi" kararı doğruydu ve
  duruyor - `fulfill_commission()`'ın dört görevi hâlâ WorldEvents'e bağlı,
  hâlâ anında. Ama oyuncunun kendi önerisi ("lonca görevleri olabilir,
  çakışmaz, ek vagon almış oluruz kervana bir nevi ya da yük") gerçekten
  ayrı bir ihtiyaca işaret ediyordu: kontrat panosunun **kendi**
  kabul/taşı/teslim mimarisi altınla ödüyor, ama loncanın oyuncuya
  *ayni* (bir vagon, bir yük) ödediği hiçbir yol yoktu. Çözüm ikinci bir
  taşıma mekaniği icat etmedi - `MerchantOffer`'ın kendisine iki alan
  eklendi (`grants_wagon_on_delivery: bool`, `cargo_reward_item_id`/
  `cargo_reward_quantity`, üçü de varsayılan false/boş - mevcut 28
  kontratın hiçbiri dokunulmadı) ve `WorldMapData.get_guild_wagon_quests()`
  bu alanları dolduran iki sabit teklifi kayda geçirdi
  (`_register_offer()`, `_offers_by_origin`/`_offer_by_merchant_id`'e
  sıradan bir kontrat gibi yazılıyor). Sonuç: kabul, planlayıcıda seçim,
  yolda taşınma, varışta teslim/kayıp - hepsi **aynı** kodu kullanıyor,
  hiçbir ekran ayrı bir "vagon görevi" dalı bilmiyor.
  - **Vagon Bağışı** (Karakonak → Yeşilova, haritanın en uzun/tehlikeli
    tek kenarı - 8 gün, %65 tehlike, itibar 25) teslim edilince
    `owned_wagon_count += 1` - kalıcı, gerçek bir vagon, `WAGON_PURCHASE_
    COST_STEP`'in her seferinde biraz daha pahalılaştırdığı satın alma
    yolunu tamamen atlıyor.
  - **Fazla Yük Sevkiyatı** (Demirkapı → Yeşilova, kısa/güvenli bir kenar -
    3 gün, %25 tehlike, itibar 10) teslim edilince 5 birim mücevher
    (`add_to_cargo_or_bag()`, `evt_forgotten_cache`'in loot ödülüyle aynı
    kapı) veriyor.
  - **Sonradan tekrar genişletildi: iki görev bir havuza döndü, ve havuzun
    iki ailesi artık farklı tekrar kurallarına sahip.** İlk sürümün "tek
    tek görev" hâli ("iki lonca vagon görevi") tekrar oynanınca sığ kaldı
    - aynı iki isim, hiç değişmeyen iki rota. `WorldMapData.
    get_guild_wagon_quests()` artık altı teklif döndürüyor: **iki vagon
    bağışı** (Vagon Bağışı'nın yanına Sınır Karakolu Vagonu, a→d, 6 gün,
    %50 tehlike, itibar 20 - haritanın üst-orta tehlike bandından ikinci
    bir kalıcı vagon, tek bir rotaya bağımlı kalmasın diye) ve **dört kargo
    görevi** (Fazla Yük Sevkiyatı'nın yanına Baharat Taşımacılığı a→b,
    Bal Taşımacılığı b→d, İpek Taşımacılığı c→e - her biri kendi çıkış
    şehrinin gerçekten ürettiği malı taşıyor, `test_world_map_data.gd`
    bunu doğrudan sınıyor). **Vagon bağışları hâlâ kalıcı olarak bir
    kereye mahsus** (aşağıdaki gerekçe hiç değişmedi - bir vagon kalıcı
    bir kapasite artışı, satın alma eğrisini bedavaya delerdi), ama
    **kargo görevleri artık sıradan bir kontrat gibi tekrar tekrar teslim
    edilebilir**: mücevher/baharat/bal/ipek kalıcı bir kapasite değil,
    zaten piyasada alınıp satılan bir mal - sınırını `MarketConditions`
    (arz-talep baskısı, şehir hazinesi) zaten taşıyor, ikinci bir "bir
    kereye mahsus" kilidi burada içeriği tekdüzeleştirmekten başka bir
    işe yaramazdı. `GameSession._apply_guild_wagon_quest_rewards()` ve
    `guild.gd`'nin pano filtresi artık yalnızca
    `offer.grants_wagon_on_delivery` doğruysa `_delivered_wagon_quest_
    ids`'e bakıyor - bir kargo görevi o sözlüğe hiç girmiyor, o yüzden
    teslim edildikçe panoya sıradan bir kontrat gibi geri dönüyor.
  - **İsim çakışması gerçek bir risk, çözümü bilinçli.** `CaravanState.
    merchant_names`/`original_merchant_names` teslimatı **isimle**
    eşleştiriyor (bkz. kendi notu), ve sıradan kontratların ismi
    kültürlerin isim havuzundan geliyor. Altı vagon görevinin de
    `merchant_name`'i o yüzden havuzdan gelmiyor - her biri kendi çeviri
    anahtarını taşıyor (`UI_GUILD_WAGON_GRANT_NAME`/`_GRANT2_NAME`/
    `_FREIGHT_NAME`/`_FREIGHT_SPICE_NAME`/`_FREIGHT_HONEY_NAME`/
    `_FREIGHT_SILK_NAME`), ki bir kültür ismiyle asla çakışamasın
    (`test_world_map_data.gd`'nin `_test_guild_wagon_quests`'i bunu
    doğrudan tüm isim havuzlarına karşı sınıyor). Ama `merchant_name`
    altı farklı ekranda (planlayıcı, dünya haritası, tüccar diyaloğu,
    kervan durumu, olay etki satırı, lonca'nın kendisi) **çevrilmeden**
    basılıyor - hepsi kültür isimlerinin proper noun olduğu varsayımıyla
    yazılmış. Çözüm o altı yeri tek tek `tr()` (statik `event_effect_
    applier.gd`'de `_t()`, `tr()`'nin `Object` örnek metodu olduğu,
    static bir fonksiyondan çağrılamadığı için - bkz. Autoload kuralı)
    ile sarmaktı, isim havuzundan gelen bir dizeyi değil: Godot'un
    `tr()`'si tanımsız bir anahtarda dizeyi **olduğu gibi** döner, yani
    sıradan bir kültür ismi (CSV'de hiç tanımlı değil) bu sarmalamadan
    hiç etkilenmiyor - yalnızca vagon görevinin gerçek anahtarı
    çözülüyor. Bir prose-exemption (kültür/recruit katalogları gibi)
    eklemek daha kısa yol olurdu ama gerçek İngilizce/diğer dil
    oyuncularına Türkçe bir görev başlığı bırakırdı - "asla kestirmeye
    kaçma" burada tam olarak bu ayrımı gerektirdi.
  - **Vagon bağışları kalıcı olarak bir kereye mahsus.** Sıradan bir
    kontrat teslim edilince panoya geri döner (aynı `merchant_id` tekrar
    kabul edilebilir - bu, escort gelirinin asıl kaynağı olan kasıtlı bir
    tasarım), ama bir vagon **sınırsız tekrar edilebilir** olsaydı
    `fulfill_commission()`'ın Faz 17 PR-8'de kapattığı sömürünün aynısı
    olurdu - `owned_wagon_count`'un kendi artan maliyet eğrisini (bkz.
    Caravan Ruin Rules) bedavaya delen bir döngü. `GameSession.
    _delivered_wagon_quest_ids` (merchant_id -> true, kaydediliyor) her
    vagon bağışı `merchant_id`'si için **en fazla bir kez** çalışıyor;
    `guild.gd` ayrıca teslim edilmiş bir vagon bağışını panodan tamamen
    düşürüyor (`is_guild_wagon_quest_delivered()`), yani oyuncu onu bir
    daha hiç görmüyor bile - kargo görevleri bu iki kapıdan hiç geçmiyor.
  - **Yolda kaybedilirse ödül yok, yalnızca itibar cezası** - sıradan bir
    kontratla aynı kader (`_apply_undelivered_contract_penalty()` zaten
    geçmiş oluyor), iki aile için de aynen geçerli.
    `_apply_guild_wagon_quest_rewards()` `caravan.merchant_names`'te
    (teslim edilen) hâlâ var mı diye bakıyor, yalnızca `original_
    merchant_names`'te (taşınmaya başlanan) olması yetmiyor.
  - `tests/test_world_map_data.gd`'nin `_test_guild_wagon_quests`'i havuzun
    şeklini kilitliyor (altı görev, iki bağış, dört kargo; her biri gerçek
    bir rotaya oturuyor; her kargo görevinin ödül malı kendi çıkış
    şehrinin ürettiği mal; isim çakışmaması; tekil `merchant_id`);
    `tests/test_game_session.gd`'nin `_test_guild_wagon_quest_rewards`'ı
    gerçek akışı (kabul → planla → yola çık → teslim et) uçtan uca
    koşturup ailelerin iki farklı davranışını doğruluyor: bir vagon bağışı
    teslim edince ödül verir ve ikinci teslimatta asla vermez (kayıt
    round-trip'i dahil - kayıttan sonra da kilitli kalır, ikinci bir vagon
    bağışı da aynı şekilde çalışır); bir kargo görevi de teslim edince
    ödül verir ama **hiçbir zaman** kalıcı olarak kilitlenmez - aynı
    oturumda ikinci kez kabul edilip teslim edilince ödül ikinci kez de
    gelir; ikisi de yolda kaybedilirse hiç ödül vermez.

**Faz 17 PR-5 ("Ekonomi Derinliği") tamamlandı** - üç bağımsız iyileştirme,
üçü de mevcut vokabüleri genişletiyor, yeni bir fiyat/pazarlık motoru icat
etmeden:

- **Şehrin kendi hazinesi var - satış artık bedava para değil.**
  `MarketConditions._city_gold` (`location_id -> rezerv`) her şehri kendi
  altın kesesiyle tutuyor - `get_city_gold()`/`earn_city_gold()`/
  `spend_city_gold()`. Oyuncu **alım** yaptıkça şehir zenginleşir (rezerv
  MAX'ta kenetlenir), **satış** yaptıkça boşalır (0'da kenetlenir - bir
  şehir asla borçlanmaz). `advance_day()` her gün rezervi kendi tabanına
  (`CITY_GOLD_DEFAULT`) doğru süzüyor - **arz-talep baskısının "pressure
  decays toward baseline" deyiminin aynısı**, ikinci kez icat edilmeden:
  ne sürekli MAX'a sürüklenen ne sonsuza dek tükenmiş kalan bir hazine.
  `GameSession.consume_stock()`/`record_sale()` - ticaretin zaten tek
  kapısı olan iki fonksiyon (bkz. Economy Rules'un "her yeni ticaret yolu
  bu kapılardan geçmeli" kuralı) - artık isteğe bağlı bir `total_price`
  parametresi alıyor ve şehrin hazinesini otomatik günceller; parametre
  verilmezse (varsayılan 0) hazineye hiç dokunulmaz, yani `total_price`
  bilmeyen hiçbir eski çağıran (ya da simülatörlerin kendi ticaret
  döngüsü) kırılmadı. `GameSession.can_city_afford_sale()` satış öncesi
  sorulan soru - `market.gd`'nin `_on_sell_pressed()`'ı hazine yetmiyorsa
  satışı **hiç başlatmıyor** (hep ya da hiç - Kervan Envanteri Rules'un
  `add_to_cargo`'daki "kısmi bir işlem kendini iki kez açıklamak zorunda
  kalmasın" ilkesinin aynısı) ve oyuncuya kaç birim alabileceğini
  söylüyor. Hazine artık görünür de - `_city_gold_label`, piyasa şokunun
  zaten kurduğu "gizli bir tavan bir hatadan farksızdır" kuralı (bkz.
  Economy Rules) burada da geçerli. Simülatörler (`simulate_journeys.gd`/
  `simulate_career.gd`/`playthrough_demo.gd`) `can_city_afford_sale`'i
  kontrol etmeden doğrudan `wallet.earn()` çağırmaya devam ediyor -
  kasıtlı: bu sınır yalnızca **etkileşimli pazar ekranının** bir kapısı,
  hazinenin kendisi 0'ın altına hiç düşmediği için (`_set_city_gold`'un
  kenetlemesi) simülatörler güvenle çalışmaya devam ediyor, yalnızca
  o şehrin hazinesi sıfırda kalıyor - kırılmıyor.
- **Sepet: toptan pazarlık artık tek maldan çoklu mala genişledi.**
  Faz 3'ün "miktar seçili toptan alım... HagglingPanel üzerinden bulk
  pazarlık" notu tek bir *mal türü* içindi; `market.gd`'nin her satırına
  eklenen "Sepete Ekle" düğmesi artık **birden çok mal türünü** tek bir
  sepette biriktiriyor. Sepet iki yolla kapanabiliyor: **Toptan Satın Al**
  (sticker fiyattan, pazarlıksız, hızlı) ya da **Sepeti Pazarla** (tek bir
  `HagglingSession`, taban fiyat sepetin sticker toplamı - tek bir anlaşma
  fiyatı kazanılır, o fiyat sepetteki her kaleme kendi sticker payı
  oranında dağıtılır, yalnızca şehir hazinesi muhasebesi için). İkisi de
  **hep ya da hiç**: stok ya da kargo yetmezse hiçbir kalem uygulanmaz -
  tek maldaki `add_to_cargo`'nun zaten kurduğu ilkenin çoklu-mal hali.
  Tekli ve sepetli pazarlık aynı `HaggleHolder`'ı paylaştığı için ikisi
  aynı anda açık olamaz (`_haggling_active` bayrağı ikisini de kilitliyor).
- **Kaydırma konumu artık korunuyor.** Envanter ızgarası ya da sepet her
  alım/satımda yeniden kuruluyordu (kayıt sayısı değiştikçe içerik boyu
  değişiyor), bu da `ScrollContainer`'ı her tık sonrası en tepeye
  fırlatıyordu - sepet dolduran ya da art arda alışveriş yapan bir oyuncu
  sürekli sayfanın başına savruluyordu. `_with_preserved_scroll()`
  konumu kenetleyip işlemi çalıştırıp `set_deferred` ile geri veriyor -
  konteynerlerin yeni boyutu aynı karede henüz oturmayabileceği için
  (Art Rules'un anchor-preset tuzağıyla aynı "layout henüz hazır değil"
  ailesi) gecikmeli çağrı gerekiyor.
- **Altı yeni mal, ikinci bir ticaret döngüsü.** İlk katman (Karakonak-
  Kurtboğazı-Demirkapı üçgeni + İpekevi-Yeşilova ikilisi) beş şehri iki
  kapalı döngüde bağlıyordu; Faz 17 PR-5 bunun üstüne, aynı beş şehri tek
  bir **beşgen halkada** birbirine bağlayan altı yeni malı ekledi:
  Baharat (Karakonak - kervan kavşağının kendi ticareti), Bal (Kurtboğazı
  - dağ arıcılığı), İpek (İpekevi - adından dolayı zaten kendi ürünü),
  Mücevher (Demirkapı - "demir kapı"nın ince işçiliği), Balık ve Şarap
  (Yeşilova - verimli/kıyı ova, tek şehrin iki ihracatı, yeni bir kural
  gerektirmiyor). Zincir a→(baharat)→b→(bal)→c→(ipek)→d→(mücevher)→
  e→(balık,şarap)→a - her mal tam olarak bir şehir tarafından üretiliyor,
  en az bir başka şehir tarafından aranıyor (`test_second_trade_loop_is_
  closed` bunu doğrudan sınıyor). Ağırlık/fiyat ilişkisi kasıtlı:
  mücevher en pahalı ve en hafif (gerçek bir lüks), balık en ucuz (bir
  taşra iaşesi), şarap en ağır (fıçı - taşımanın kendisi bir maliyet).
  Bal ve şarabın kendi mevsim çarpanı da var (`MarketConditions.
  SEASON_MULTIPLIERS`) - kovan hasadı yaz sonu/sonbahar, bağ hasadı
  sonbahar, ikisi de kışın kıtlaşıp pahalanıyor, mevcut mevsim sisteminin
  aynı formülüyle.
- **"Demirci Malı Silah" artık "Demir".** `test_weapon` hiçbir zaman gerçek
  bir savaş silahı değildi - `Equipment` (kılıç/zırh gibi combat parçaları)
  tamamen ayrı bir sistem, bu yalnızca bir kargo kalemiydi ve adı bunu
  gizliyordu, "silah" adında bir mal satmak equipment sistemiyle karışan
  bir izlenim veriyordu. İsim artık "Demir" (İngilizce "Iron") - Demirkapı
  ("demir kapı") şehrinin zaten ürettiği hammadde, adı coğrafyasıyla da
  örtüşüyor. `item_id` ("test_weapon") kayıt uyumluluğu için dokunulmadı -
  yalnızca `ITEM_WEAPON_NAME`'in çeviri metni değişti, aynı kural Faz 7
  PR-D'nin item_id'leri sabit tutup yalnızca ismi lore'a çevirdiği kural.

**Faz 17 PR-6 ("Yol Katmanı") tamamlandı** - `RouteTerrain`'in çizilip hiç
okunmayan verilerini gerçek mekaniğe bağlayan, borcu yola taşıyan ve savaşın
kompozisyonunu araziye bağlayan dört değişiklik, hepsi mevcut vokabüleri
genişletiyor:

- **Eğim artık gerçekten yavaşlatıyor/hızlandırıyor.** `RouteTerrain.slope`
  Faz 10'dan beri vardı ama yalnızca çizimi eğdiriyordu - "bir yol durağının
  hiçbir olay tarafından okunmaması dekordur, mekanik değil" ilkesinin
  (bkz. Route Terrain & Weather Rules) eğim tarafındaki eksik parçasıydı.
  `RouteTerrain.speed_factor_at(day)` tırmanışta düşen, inişte hafifçe
  yükselen bir çarpan döndürüyor (`MIN/MAX_SLOPE_SPEED_FACTOR`, 0.75-1.15 -
  bir sistemi hiçbir eğim tamamen kapatamaz kuralı burada da geçerli).
  `road_journey.gd`'nin tek yürüme kapısı `_walk_at()` bunu tempo/hava/
  kondisyonun yanına dördüncü çarpan olarak ekliyor; `RouteWeather.
  forecast_extra_days()` de **aynı çarpanı aynı günlük yürüyüşün içinde**
  okuyor, yoksa tırmanışlı bir rotada "doğru stoklayan asla aç kalmaz" sözü
  (bkz. Provision Rules) sessizce bozulurdu - hava/kondisyon payının zaten
  kurduğu "ayrı ayrı hesaplayıp toplamak bileşik yavaşlamayı hafife alır"
  disiplininin üçüncü tekrarı. `test_route_terrain.gd`'nin hava-yalnız ve
  hava+kondisyon testlerinin kendi elle yürüyüş simülasyonları da eğim
  çarpanını okuyacak şekilde güncellendi - `forecast_extra_days()` artık
  eğimi *her zaman* hesaba kattığı için (terrain verildiğinde, açma/kapama
  bayrağı yok) o testlerin kendi "gerçek yürüyüş" taklidi de güncel
  formülle uyuşmak zorundaydı, yoksa reserve gerçek yürüyüşten daha az
  hesaplanıp iniş eğimli bir rotada açlığa yol açabilirdi - PR sırasında
  gerçekten yakalanan bir regresyon, düzeltilmeden önce 12 assertion kırıktı.
- **Borç defteri artık yolda da açılıyor.** `DebtPanel` (bir `PanelContainer`,
  `CanvasLayer` değil) daha önce yalnızca Tüccar Loncası'nın bir sekmesinden
  erişilebiliyordu - road HUD'u borç toplamını zaten gösteriyordu ama
  üstünde hiçbir şey yapılamıyordu. F2 emir menüsüne yedinci bir komut
  eklendi ("Borç defterine bak") ve panel doğrudan `Modal/Center`'ın
  çerçeveli kartına gömülüyor (Road Screen Layout Rules'un "kararlar tek
  bir kart içinde" kuralı) - `MerchantDialoguePanel`'in aksine kendi
  backdrop'u olmadığı için tam ekran bir katman değil. `_talk_merchant_
  row_number`'ın eklenmesi ayrı bir düzeltme: "Tüccarla Konuş" satırının
  numarası `COMMANDS.size()`'a sabitliydi, yani listenin **son** satırı
  olduğu varsayımına dayanıyordu - borç komutu ardına eklenince o varsayım
  kırılırdı (satır numarası 7 basardı ama tüccar komutu hâlâ 6. sırada
  kalırdı). Kendi sıra numarasını inşa sırasında saklamak varsayımı
  tamamen ortadan kaldırdı.
- **Vahşi hayvan kadrosu artık geçtiği araziye bağlı.** `EnemyCatalog.
  build_wildlife_squad()` yeni bir `biome` parametresi alıyor (varsayılan
  "", yani eski davranış birebir sürüyor): orman üçüncü bir kurt ekliyor
  ("kurt sürüsü", `RouteTerrain.BIOME_FOREST` gerçek dünyada kurtların
  yaşadığı arazi), dağ ayı ihtimalini %35'ten %55'e çıkarıyor. `build_
  squad()`'ın tek giriş noktası zincirine (`combat_panel.gd` → `road_
  journey.gd`) aynı parametre eklendi, `road_journey.gd` o günkü `_terrain.
  biome_at(_days_covered)`'ı geçiyor - aynı "hangi arazide olduğun savaşın
  görselini de kompozisyonunu da belirliyor" ilkesi.
- **"Güç Sınavı" artık gerçek bir dağ geçidinden geçilirken çekiliyor.**
  `evt_culture_highland_challenge` (dağ kabilesinin kendi meydan okuması,
  Faz 17 PR-2'nin STRENGTH check pilotu) `evt_roadside_shrine`'ın kurduğu
  aynı desende - taban ağırlık düşürüldü (0.8 → 0.25, işaretsiz bir yerde
  de nadiren meydan okunabilir) ve `near_mountain_pass` bayrağı (`road_
  journey.gd`'nin `_run_day()`'inin `near_shrine`'la aynı yerden, `_terrain.
  segment_at(_days_covered).stop == RouteTerrain.STOP_PASS` okuyarak
  eklediği) ağırlığı ×6 katlıyor - Route Terrain & Weather Rules'un "beş yol
  durağının hâlâ mekanik karşılığı yok" notundaki altı duraktan biri artık
  gerçek bir olaya bağlı, kalan dördü (konak/karakol/maden/köprü) hâlâ
  salt görsel, ayrı bir follow-up.
- **Sonradan tamamlandı: `evt_road_patrol`'ün kendi vaadini tutmayan savaş
  dalı.** İlk turun gerekçesi ("devriyeyle gerginlik zaten `evt_guard_
  patrol`/`evt_customs_checkpoint`'in kendi muhafız-savaşı mekaniğinde
  var") doğruydu ama yanlış karşılaştırmayı yapıyordu: `evt_road_patrol`
  devriyeyle *kavga* değil, devriyeyle **birlikte** haydutlarla dövüşmeyi
  soruyor - olayın kendi metni zaten "bu güzergâhtaki eşkıyayı temizlemeye
  niyetliler" diyor, ama katılmak (`EVT_PATROL_OPT_JOIN`) hiç zar
  içermeyen, risksiz bir `ROUTE_CHANGE`/`DANGER`/`REPUTATION` paketiydi -
  olay kendi vaadini hiç ödemiyordu. Üçüncü bir seçenek
  (`EVT_PATROL_OPT_FIGHT`) eklendi: tek etkisi `TRIGGER_COMBAT` (tür
  "bandit", "guard" değil) - `evt_bandit_ambush`'ın `OPT_FIGHT`'ıyla
  birebir aynı kalıp, zar atılmıyor, gerçek savaş paneli açılıyor.
  Haydut türünde olduğu için zafer normal şekilde itibar **kazandırıyor**
  (guard'ın aksine, bkz. Combat Rules'un `GUARD_VICTORY_REPUTATION`
  istisnası) - iki savaş dalı hem enemy kind'ı hem itibar yönü bakımından
  gerçekten ayrışıyor, aynı belirsizliği iki kez modellemiyor.
  `EVT_PATROL_OPT_JOIN` hiç değişmeden kaldı (o hâlâ "kâğıt işi, muharebe
  değil" senaryosu), `EVT_PATROL_OPT_PASS` de öyle.
- **Sonradan tamamlandı: haydut fidyesi artık yolun tehlikesine göre
  ölçekleniyor.** `evt_bandit_ambush`'ın fidyesi sabit 120 GG'ydi,
  `build_bandit_squad`'ın kendisi zaten danger/party_size/seviyeye göre
  ölçeklenirken (bkz. Ruin Rules) fidye bundan tamamen bağımsızdı -
  tehlikeli bir yolda dövüşmek daha riskli oluyordu ama satın almak hep
  aynı ucuzluktaydı. Fidye artık üç banda ayrılıyor (80/130/190 GG),
  aynı olayın kendi `weight_modifiers`'ının zaten kullandığı 0.35/0.6
  eşiklerini paylaşarak (aynı sayıyı iki kez icat etmemek için).
  Ölçekleme `EventChoice.outcomes`'un koşullu ağırlıklı çekimiyle
  (`_outcome_if`, `evt_storm`'un üç kademeli deseniyle aynı aile)
  yapılıyor - ama bir **yeni ilkel** gerektirdi: `EventCondition.Op` üç
  ayrı GREATER_EQUAL/LESS_EQUAL bandı örtüşmeden ifade edemiyordu (aynı
  eşiği paylaşan bir alt bant LESS_EQUAL ile bir üst bant GREATER_EQUAL
  ile sınırda ikisi birden "uygun" sayılırdı, ki `EventEngine.
  resolve_outcome`'ın ağırlıklı çekimi o noktada artık belirlenimci
  değil rastgele olurdu). `EventCondition.Op.LESS_THAN` eklendi - kesin,
  örtüşmeyen bir üst sınır. Kapı (`requirements`, "yeterli altının yok"
  kilidi) en ucuz banda göre kuruluyor, tam tutar ancak seçildikten sonra
  belli oluyor - `GOLD` etkisi zaten `spend_or_owe` üstünden geçtiği için
  (bkz. `_apply_gold`) tutar tahmin edilenden fazla çıkarsa fark borca
  yazılıyor, sessizce başarısız olmuyor. `evt_bandit_ambush`'ın diğer iki
  kolu (savaş, pazarlık) hiç değişmedi - Faz 17 PR-2'nin kaydettiği
  "aynı belirsizliği iki kez modellemek olurdu" gerekçesi hâlâ geçerli,
  bu PR yalnızca üçüncü kolun (öde) kendi iç ölçeklenmesini ekliyor.
  `tests/test_event_engine.gd`'nin iki yeni testi bunları kilitliyor:
  devriye olayının haydut türünde savaş açtığı, fidyenin üç bandının
  doğru tutarı verdiği ve sınırda (0.35/0.6) her zaman tam olarak bir
  bandın uygun olduğu (LESS_THAN'in tüm amacı).

**Faz 17 PR-7 ("Savaş Animasyon Katmanı") tamamlandı.** Faz 13 PR-D'nin
kısa yorum balonları (`unit_barked`) savaşın *ne* olduğunu söylüyordu ama
ekranın kendisi hâlâ tamamen durağandı - bir isabet ile bir kaçırma aynı
kareyi çiziyordu, yalnızca metin farklıydı. Bu PR yeni bir animasyon motoru
icat etmeden aynı sinyali görsel bir tepkiye çeviriyor.

- **Mimari zorunluluk barkla birebir aynı: `CombatUnitSlot` (ve içindeki
  `CombatFigure`) her `CombatPanel._refresh()`'te yeniden kuruluyor.** Bir
  `Tween`i figürün kendisine bağlamak, figür bir sonraki tazelemede
  silinince Tween'i de birlikte öldürür (bkz. `CombatPanel`'in kendi bark
  yorumu - "slotlar her `_refresh()`'te yeniden kuruluyor"). Çözüm de
  barkla birebir aynı: `CombatPanel._flash_states`/`_lunge_states`
  (`CombatUnit -> {değer, expires_at}`), gerçek zaman damgasıyla panelde
  tutulan, her yeni slota `bind()`'tan hemen sonra yeniden uygulanan bir
  durum - `_apply_pending_animation(slot, unit)` `_apply_pending_bark`'ın
  yanına eklendi, aynı `_refresh_side()` döngüsünde.
- **Sinyal metni değil, makine tarafından okunabilir bir tür taşıyor
  artık.** `CombatEncounter.unit_barked(unit, text, kind)` üçüncü bir
  argüman kazandı - yedi adlandırılmış sabit (`BARK_HIT`/`BARK_CRIT`/
  `BARK_REFUSE`/`BARK_DEATHS_DOOR`/`BARK_SURVIVED`/`BARK_KILLED`/
  `BARK_DOWNED`), yedi `unit_barked.emit()` çağrısının her biri kendi
  türünü taşıyor. Çeviri anahtarına (`tr("CBT_BARK_CRIT")`) göre eşleşen
  bir UI, dil değişince ya da metin yeniden yazılınca sessizce kırılırdı -
  Localization Rules'un "mantık çeviri metnine göre dallanmaz" kuralının
  aynısı, combat'ın kendi bark sistemine ilk kez uygulanışı.
- **Parlama:** `CombatFigure.set_flash(color)` doğrudan `Control.modulate`'i
  yazıyor - yeni bir çizim yolu değil, var olan silüetin üstüne bindirilen
  bir renk çarpanı. Yedi tür, yedi renk (`CombatPanel.FLASH_*`) - kritik
  ve "hayatta kaldı" `1.0`'ın üstünde modulate değerleri kullanıyor
  (Godot bunu kenetlemiyor), aynı zeminin üstünde ucuz bir "parlama"
  hissi için yeni bir blend modu icat etmeden. Kilit ayrım: `_figure`'ın
  kendi `modulate`'i (parlama, geçici) ile `CombatUnitSlot`'un kendi
  `modulate`'i (düşmüş/ölü soluklaşması, kalıcı) **iki ayrı düğümde**
  duruyor - Godot'ta çocuk `modulate`'i ebeveynle çarpımsal birleştiği
  için ikisi çakışmadan üst üste biniyor: soluk bir figür bark alınca
  yine de parlıyor, yalnızca daha soluk bir taban üstünden.
- **Kayma yalnızca isabet/kritikte, yalnızca saldıranda.** `CombatFigure.
  set_lunge(offset)` `_draw()`'ın en başına bir `draw_set_transform(
  Vector2(_lunge, 0.0))` ekliyor - `_lunge` sıfırken tamamen no-op,
  eski çizim birebir aynı kalıyor (Godot'un kendi kuralı: bir
  `draw_set_transform` yalnızca o `_draw()` çağrısı içinde geçerli, bir
  sonraki karede otomatik sıfırlanıyor, elle bir "geri al" gerekmiyor).
  Yön saldıranın tarafından geliyor (oyuncu +, düşman -) - hedeften değil,
  çünkü hamleyi yapan saldıran, tepki veren hedef. `CombatPanel.
  _on_unit_barked()` bunu `_encounter.get_active_unit()`'i saldıran sayarak
  kuruyor: bark sinyali `unit_barked.emit(target, ...)` şeklinde *hedef*
  üstünden geliyor (bkz. `combat_encounter.gd`'nin `_resolve_on_target()`'ı),
  yani "kim vurdu" bilgisi sinyalde yok - ama `_resolve_skill()`'in tüm
  zinciri sırası gelen birimin turu içinde senkron çalıştığı için `get_
  active_unit()` o an hâlâ doğru saldıranı gösteriyor. Ret (`BARK_REFUSE`)
  kasıtlı olarak yalnızca soluk bir parlama üretiyor, kayma üretmiyor -
  reddin kendisi bir hamle değil, sırasını harcayan bir hiçlik.
- **Süreler bark'tan kısa, kasıtlı.** `FLASH_DURATION_MSEC` (500) ve
  `LUNGE_DURATION_MSEC` (260) `BARK_DURATION_MSEC`'in (2200) çok altında -
  bir vuruşun "az önce oldu" hissi anlık olmalı, balonun okunacak kadar
  ekranda kalması gereken metniyle aynı ritimde değil. Süresi geçmiş bir
  kayıt `_apply_pending_animation` tarafından nötre (`FLASH_NEUTRAL`,
  kayma 0) döndürülüp sözlükten siliniyor - `_apply_pending_bark`'ın süre
  dolunca unutma kuralının aynısı.
- **`tests/test_combat_core.gd`'nin `_test_bark_drives_flash_and_lunge`'ı**
  bunu `_test_battlefield_is_a_field_not_a_list`'in kurduğu sahnesiz panel
  üstünde doğruluyor - motoru koşturmaya gerek yok, `_on_unit_barked`/
  `_flash_for_kind`/`_apply_pending_animation` saf birer eşleme:
  her tanınan tür kendi rengini dönüyor, tanınmayan tür (gelecekte
  eklenecek bir bark) nötre düşüyor; isabet hem hedefte parlama hem
  saldıranda saldıranın tarafına işaretli bir kayma bırakıyor; ret hiç
  kayma üretmiyor; süresi geçmiş bir kayıt uygulanınca nötre dönüp
  kendini siliyor.
- **Sonradan tamamlandı: "kaçırma" barkı/parlaması.** İlk turda motorun
  böyle bir bark'ı hiç yoktu - `_resolve_on_target()` bir kaçırmayı
  yalnızca kayda yazıyordu, `unit_barked` hiç emit etmiyordu, yani bir
  isabet ile bir kaçırma aynı (hareketsiz) kareyi paylaşıyordu; PR-7'nin
  kendi kapsamı "mevcut sinyali görselleştir" olduğu için yeni bir sinyal
  eklemek o turun dışında bırakılmıştı. `CombatEncounter.BARK_MISS`
  eklendi, `_resolve_on_target()`'ın isabet kontrolü başarısız olduğu
  dalda hedefe doğru emit ediliyor - isabet/kritikle **aynı sözleşme**
  (hedef üstünden), yeni bir mekanizma değil.
  `CombatPanel.FLASH_MISS` (soğuk bir mavi-beyaz, `FLASH_HIT`'in sıcak
  kırmızısının kasıtlı tersi - "temas etmedi" hissi) `_flash_for_kind`'a
  eklendi. **Kayma tarafı bu PR'ın kendi kuralını genişletiyor, bozmuyor:**
  "kayma yalnızca isabet/kritikte, çünkü `BARK_DEATHS_DOOR`/`SURVIVED`/
  `KILLED`/`DOWNED` birer *sonuç* anlatır, taze bir hamle değil" kuralının
  gerekçesi bir kaçırmaya da aynen uyuyor - saldıran gerçekten kılıcını
  salladı, yalnızca değmedi; bu HIT/CRIT'in "taze hamle" kategorisi, DEATHS
  _DOOR'un "sonuç" kategorisi değil. O yüzden `BARK_MISS` de `BARK_HIT`/
  `BARK_CRIT`'in yanına, kayma üreten kümeye eklendi - kuralın kendisi
  değişmedi, kapsamı doğru genişledi.
  `tests/test_combat_core.gd`'nin `_test_bark_drives_flash_and_lunge`'ı
  genişletildi: kaçırmanın kendi rengini döndüğü ve isabetle aynı şekilde
  saldıranda kayma bıraktığı, ikisi de saf eşleme üstünden (motoru
  koşturmadan) doğrulanıyor.

**Faz 17 PR-8 ("Sayı ve denge turu") tamamlandı.** PR-1..7 sekiz stata,
skill-check omurgasına, on altı huya, dünya olaylarına/lonca görevlerine,
ekonomiye ve yol katmanına dokundu - bu PR onları tek tek doğrulamak yerine
`simulate_journeys.gd`/`simulate_career.gd`'yi cari kod üstünde yeniden
koşturup bu dosyadaki ölçülmüş sayılardan hangisi hâlâ doğru diye sordu.

- **Savaş dengesi hiç kaymadı.** `simulate_journeys.gd`'nin kazanma oranı
  tablosu (parti × tehlike) Ruin Rules'un Faz 15'te retune edilmiş tablosuyla
  **rakam rakam aynı** (1: %53/55/23/23, 2: %100/68/43/43, 3: %100/95/68/68,
  4: %100/100/92/92) - PR-1..3'ün yeni stat/huy/check katmanı savaşın kendi
  formüllerine hiç sızmadı, tıpkı tasarlandığı gibi (Bilgelik/İnanç combat'a
  bilerek dokunmuyor, huyların `check_bonus`/`refusal_bonus`'u check ve
  stres reddi için, hasar/isabet için değil).
- **Kampanya bölümleri gerçekten kaydı - ama bu bir Faz 17 regresyonu
  değil.** `simulate_career.gd` artık tüm bölümleri 8/8 kapatıyor, final
  ortancası 30. seferden 12. sefere indi. Kök neden Faz 17'de değil: Faz
  11'in "teslimat itibar kazandırsın" düzeltmesi (bkz. Reputation Rules)
  doğruydu ve kalıyor, ama Campaign Rules'un "itibar en kıt kaynak" bulgusu
  o düzeltmeden **önceki** haliyle ölçülmüştü ve hiç yeniden koşulmamıştı -
  sekiz fazdır. Tam ölçüm, kök neden ve *neden finalin itibar barını geri
  yükseltmenin yanlış tepki olduğu* Campaign Rules'un kendi tablosunun
  altında.
- **Gerçek bir sömürü bulundu ve kapatıldı: `fulfill_commission()`'ın hiç
  tekrar koruması yoktu.** Aynı dünya olayı açık kaldığı sürece (8-30 gün)
  aynı lonca görevi sınırsızca tekrarlanabiliyordu - Ticaret Fuarı
  Sponsorluğu tek başına döngüde çağrılırsa çağrı başına +60 altın +2 itibar
  basıyordu. `GameSession._fulfilled_commission_starts` artık aktif olayın
  kendi `started_day`'ini anahtar alıp aynı haber örneğinin ikinci kez
  tamamlanmasını `UI_COMMISSION_ALREADY_FULFILLED` ile kilitliyor - süresi
  dolup *yeni* bir haber gelince (farklı `started_day`) tekrar açılıyor.
  Kaydedilip yükleniyor (`fulfilled_commission_starts`, eksik anahtar boş
  sözlüğe düşüyor - eski bir kayıt sömürüyü miras almıyor).
  `tests/test_world_events.gd`'ye iki test eklendi: aynı olay sürerken
  ikinci tamamlamanın parayı/itibarı değiştirmediği, yeni bir örnekte
  tekrar açıldığı. `simulate_career.gd` `fulfill_commission()`'ı hiç
  çağırmıyor, yani bu sömürü ölçümdeki itibar sıçramasının kaynağı değildi
  - aynı geçişte bulunmuş ayrı, gerçek bir bulgu.
- **Bilerek dokunulmayan:** finalin `reputation >= 15`/`days_as_leader >=
  60` eşikleri. Reputation Rules'un kendi tezi "iyi oynamak itibarı
  hareket ettirsin" - finalin daha erken kapanması bu tezin **çalıştığının**
  kanıtı, bastırılacak bir yan etki değil. Bu dosyanın kendi tarihi (üçüncü/
  dördüncü bölüm eşiği ayarı) final eşiklerinin özenli, çok politikalı ölçüm
  istediğini zaten gösteriyor - "tablo bayatlamış" ile "eşik yanlış" ayrı
  sorular, ikincisi bu turun kapsamında değil.

**Faz 17 PR-9 ("İçerik ve lore turu") tamamlandı - Faz 12'nin triyajında
"kalıcı olarak reddedilmeyen, beklemede" diye işaretlenip Faz 16'da aktif
yol haritasına terfi eden son kalem: iki dini yaratılış efsanesi (#12).
Fragman/sinematik yarısı kasıtlı olarak dışarıda bırakıldı - CLAUDE.md'nin
kendi notu bunun "bu kod tabanının işi değil" olduğunu zaten söylüyor.**

- **İki efsane, Kilise'nin yeni bir bölümü - şehir siluetine hiç
  dokunmadan.** Art Rules'un cami/minare geri alımı ("Wayborne'un böyle bir
  kurumu yok, ufuktaki bir ibadet yeri oyunun kendi lore'unun dışından bir
  şey söyler") mimariye ait bir kural, metne değil - `church.gd`'nin zaten
  var olan, salt metinsel ekranı efsanelerin doğal evi. `MYTH_HIGHLAND_*`/
  `MYTH_FISHER_*` (`game.csv`, kültür katalog içeriğiyle aynı dosya) dağ
  kabilesinin doruk-nefesi ve balıkçı kasabasının deniz-gözyaşı
  gelenekleri - ikisi de `CultureCatalog`'un PR-1'de zaten kurduğu İnanç
  eğilimine (HIGHLAND +1 "ayin bağlı kabile", FISHER +1 "fırtınaya karşı
  dua") bir karşılık. Kilise **ikisini birden** anlatır, birini seçmez -
  beş kültürden hiçbirinin oyunun "resmi" kültürü olmaması gibi. Label'lar
  `church.gd`'nin `_build_myths()`'inde kod içinde kuruluyor,
  `.tscn`'e elle eklenmiyor - gerçek prose taşıyan her yeni label'ın
  `autowrap_mode` unutması Art Rules'un kendi kayıtlı tarihi (`TitleLabel`/
  `InfoLabel` overflow bug'ı), tek bir yardımcı fonksiyonun içine kapatmak
  bunu bir daha unutulamaz kılıyor.
- **Efsaneler yalnızca metin değil - yolda bir karşılığı da var:
  `evt_pilgrim_encounter` → `evt_pilgrim_blessing`.** `evt_wanderer_
  revenge`'in "karar gecikmeli sonuç doğurur" kalıbının **olumlu ucu** -
  doruğa ya da kıyıya yürüyen bir hacıya eşlik etmek (ya da Bilgelik
  check'iyle doğru yolu tarif etmek) günler sonra bir teşekkür açar,
  bir fatura değil. `evt_road_wanderer`'dan kasıtlı farkı: hacı kervana
  katılmak istemiyor, yalnızca eşlik istiyor, o yüzden `TRIGGER_RECRUIT`
  hiç açılmıyor. `tests/test_event_effects.gd`'ye `_test_pilgrim_blessing_
  chain` eklendi, `_test_vengeful_wanderer_chain`'in aynı deseni (bayrak +
  `UNLOCK_EVENT`, sonra `triggered_only` olayın uygun hale gelmesi, bayrak
  temizlenince zincirin kapanması) - farklı duygu, aynı mimari.
- **Beş kültürün isim havuzu 8'den 16'ya çıktı.** Sekiz isim, oyun boyunca
  onlarca tayfa/yoldaş/aday çekildiğinde hızla tekrar etmeye başlıyordu -
  saf içerik zenginleştirmesi, hiçbir formüle dokunmuyor
  (`test_culture.gd`'nin kendi asgari-4 kontrolü değişmeden geçiyor).
- **Codex'in olay bölümü Faz 17'nin (ve ondan önceki birkaç fazın) kendi
  gerisinde kaldığı bulundu ve kısmen kapatıldı.** `docs/codex/README`'nin
  kendi kuralı net: "yeni ya da retune edilen bir olay `codex_events_data.
  py`'de elle işlenmeli, otomatik türetilmiyor." Ölçüm: canlı katalog
  bugün 41 kart döndürüyor (`EventCatalog.get_road_events()`), codex'in
  özet tablosu hâlâ 27 diyordu - bu PR'ın kendi eklediği iki kart dışında
  kalan fark (World Events haberleri, soruşturma zinciri, toplama/av gibi
  birkaç fazdır eklenen kartlar) **bu turun işi değil**, önceden var olan,
  ayrı bir belgeleme borcu. `evt_roadside_shrine`'ın codex girişi de hâlâ
  Faz 17 PR-2'nin İnanç check'inden önceki eski ağırlıklı-sonuç haliyle
  duruyor - aynı borcun bir örneği daha, dokunulmadı. Bu turda yapılan:
  iki yeni kartın (`evt_pilgrim_encounter`/`evt_pilgrim_blessing`) tam
  girişi eklendi, özet tablo ve kapak sayfası 27→29 (bu ekin kapsadığı
  gerçek sayı) olarak düzeltildi ve **tablonun altına, kapsamadığı 41'i
  açıkça söyleyen bir dipnot eklendi** - sessizce yanlış bir sayı bırakmak
  yerine, neyin belgelenmediğini söylemek (`UI_COMMISSION_NO_EVENT`'in
  "disabled with reason" kuralının belgeleme tarafındaki karşılığı).
  Etki sözlüğü sayısı da düzeltildi (25 → 26, `WORLD_EVENT_START`
  eksikti). PDF `python3 docs/codex/codex_main.py` ile yeniden üretildi.
- **Bilerek kapsam dışı bırakılan:** codex'in 12+ kartlık geri kalan
  belgeleme borcunun tam kapatılması (ayrı, büyük bir follow-up - her
  kart kendi flavor/trigger/note metnini istiyor, tahmin edilerek
  yazılmadı); fragman/sinematik (#12'nin kendi notu zaten "bu kod
  tabanının işi değil" diyor).

**Faz 18 ("Hafıza ve bedel") tamamlandı.** Dışarıdan-bakış bir tasarım
incelemesi yirmi üç öneri döndürdü; kodeks güncellemesi (#23)
oyuncunun isteğiyle ertelendi, kalan yirmi ikisi uygulandı. Ortak tez
oyunun kendi codex cümlesi: konu kervan değil, onu çekenler ve aşınmaları.
Üç eksen üzerinden - kaynak yönetiminden ahlaki muhasebeye, yıpranmadan
hafızaya, zorluktan trajediye:

- **Kaydın bütünlüğü.** Atomik yazım + `.bak` yedeği; yeniden yüklemenin
  tutulmuş bir yoldaşı klonlaması ve boşaltılmış pazarı doldurması
  kapatıldı; her kalıcı alanın kayda girdiğini söyleyen yansımalı bir test.
- **Kişilerin kimliği.** `character_id` - aynı adı taşıyan iki ölü artık
  tek bir geçmişte birleşmiyor.
- **Defter bir hatıra.** Her satır sebebini ve yerini taşıyor, ilk satırı
  oyuncudan önce adı taşıyan kurucu; olay havuzu defteri okuyor (bu dosya
  bunu yıllardır iddia ediyordu, kod yapmıyordu).
- **Ahlaki muhasebe.** Kırgınlık (aç bırakılmak, savaşın dışında tutulmak,
  ölüm görmek, liderlikte geçilmek), bilerek aç bırakılanın ölebilmesi,
  varisin seçilmesi (kıdemliyi geçmenin bedeliyle), vagonuyla birlikte
  kaybolan isimli tayfa, krizden kâr etmenin dünyadaki hafızası, skill-check
  önizlemesinde zarı atan kişinin adı.
- **Trajedi kartları.** `evt_leave_the_wounded` - verimli seçimin düzgün bir
  insanın yapmayacağı seçim olduğu ilk kart; karakol/maden/köprü kartlarıyla
  birlikte yolun bütün durak türleri artık mekanik taşıyor.
- **Mimari.** `EventResolver` (tek çözüm yolu, dört kopyanın yerine),
  `JourneyController` (seferin görsel olmayan çekirdeği), `CityBriefModel`
  (brifingin düğümsüz yarısı), `GameSession.Phase` (türetilmiş evre), sefer
  ortası otomatik kaydı.
- **Finalin hafıza kapısı.** Ölçüldü, bkz. Campaign Rules.

**Faz 19 ("Sistem mimarisi incelemesi") tamamlandı.** Dört aşamalı bir
inceleme (Bogost'un prosedürel retoriği; Frostpunk, This War of Mine ve
benzerlerinin karşılaştırması) sistemlerin ne *söylediğini* denetledi ve
on beş biletlik bir backlog çıkardı; her bilet kendi PR'ıyla, sırayla
birleştirildi:

- **Korumalar önce.** Her olay etkisi tipinin uygulayıcıda karşılandığını
  (T-01) ve her süreli değiştirici adının motorca bilindiğini (T-02) sınayan
  testler - ikisi de yalnızca yazılı bir kural olarak duruyordu.
- **Sınıf kimliği (T-02..T-04).** Zırh değiştiricisi, kendine kaydırma, sınıf
  başına tek destek ve tek bozma ekseni, tek şifacı. Denge yeniden ölçüldü;
  bir hücre bandın bir savaş dışında, sebebi Ruin Rules'ta.
- **Kayıp satın alınamaz (T-05).** İşten çıkarmak finalin kayıp kapısını
  artık açmıyor.
- **İsimsizler sayılır (T-06).** Aç bırakılan tayfa birikir ve ölür, adıyla.
- **Veraset (T-07, T-08).** Kıdem hizmet süresi; tören adaylar hakkında
  defterin bildiğini söylüyor; uzun süre birlikte yürüyenin yası ağır.
- **Geride bırakılan önceden adıyla (T-09).**
- **Zincirler (T-10, T-11, T-14).** İşaretsiz Mezar (defteri okur),
  Firariler (bölgesel savaşı okur), Kurt Yılı (vahşi hayvan savaşıyla
  biter), borç krizi (alacaklının atlısı → icra memurları). Denge
  simülatörü taze oturumlarla çalıştığı için ilk üçünün son halkalarına
  ulaşamıyor; hepsinin uçtan uca testi var.
- **Borç ayni ödenebilir (T-13).** `DEBT_SETTLE`, vokabülerde borcu azaltan
  ilk etki.
- **Ortalamanın sakladığı kişi (T-12).** Stres şişesinde en yıpranmış
  kişinin çentiği.

İncelemeden bilerek sapılan tek yer: borç krizinde "vagon teslim et"
seçeneği yok - yolda kaybedilen vagonun tayfası deftere ölü yazılıyor, el
konulan bir vagon için bu yanlış bir hatıra olurdu.


**Faz 20 ("Duyu") tamamlandı.** Bir Principal Technical Artist / UI-UX
incelemesi dört sütunda (geçişler, prosedürel animasyon, savaş efekti,
düğme hissi) on dört biletlik bir SENSORY backlog'u çıkardı; her bilet
kendi PR'ıyla, sırayla birleştirildi. Kurallar Motion Rules'ta:

- **Renk tek yerden (001).** Savaş efektlerinin renkleri `ArtPalette.FX_*`.
- **Sahne geçişi (002).** `SceneInk.go` - kırk beş çağrı yeri tek kapıda;
  derine inmek sayfayı sola, geri dönmek sağa çeviriyor, köke gitmek
  mürekkebe batıyor.
- **Şehir yolun saatinde (003).** Varış saati kayda yazılıyor, gökyüzü ve
  gece örtüsü ondan.
- **Yürüyüş (004/005).** Kopmasız duruş, branda salınımı, öküzün baş
  sallaması, yağmurda ve fırtınada rüzgâra eğilme.
- **Savaş (006-011).** Karede sürülen parlama ve hamle, düşüş (Devam'ı
  tutuyor), yalnızca figürlerin sarsıntısı, gerçek can farkından hasar
  sayıları, durum halkaları ve tıkları, sersemlik yayları, "Hareketi Azalt"
  ayarı.
- **Düğme ve seçenek (012/013).** Her düğmede eldeki his; savaş açan
  seçenekte kan şeridi, zara bağlı seçenekte stat amblemi, "neredeyse"
  kilitte vurgu rengi.

**Faz 21 ("Kontrol") tamamlandı.** Soru şuydu: A/D ile mi yürüyelim, yoksa
kervan kendiliğinden yürüsün ve biz emir mi verelim? Cevap bütün oyuna
uygulanan tek kural oldu: girdi bir karardır; karar taşımayan sürekli
girdi otomatiğe döner; her kararın görünür bir kontrolü vardır, tuş
yalnızca kısayoldur. Beş PR, kurallar Road Movement Rules'ta:

- **Kontrol-1:** kervan emredilen tempoda kendiliğinden yürüyor, A/D ve
  dokunma yalnızca lideri kolonda yürütüyor. Geri yürüme ve "kolona
  ineceğim" emri kaldırıldı. Günler tek tek işleniyor, işaretin önünde
  durmak artık bedava gün değil.
- **Kontrol-2:** F2'nin arkasındaki emir menüsü her zaman görünen bir
  panele dönüştü: tempo, Tüccar ve Borçlar.
- **Kontrol-3:** kalıcı emirler. Sofra politikası, akşam kampı ve savaş
  kadrosu hatırlanıyor; durum değişince oyun yeniden soruyor.
- **Kontrol-4:** hub'da dokunarak yürüme ve dokunmatik denklik testi.
- **Kontrol-5:** simülatörler koşturuldu. Yol ekranından geçmedikleri için
  sayıları değişmedi, çünkü normal tempo eski tam tempo yürüyüşünün
  aynısı. Ölçülen tek yeni risk akşam kampı emrinin erzak sözünü
  bozmasıydı; planlayıcıya kamp payı eklendi.

**At/öküz/kurdun ilk gerçek `BeastRig` sanatı geldi - ve parça olarak
değil, deri olarak.** Kaynak CC0 bir 3D paket (Quaternius); öküz boğa
modelinden. İlk sürüm her hayvanı dokuz parçaya kesip `part_transform()`'ın
tersiyle tuvallerine oturttu. Dinlenme pozunda kusursuzdu, yürürken değildi:
her parça kendi pivotunda döndüğü için diz ve omuzlarda boşluk açıldı.
Parçalara pay (`OVERLAP_PX`) eklemek boşluğu kapadı ama bu kez parçaları üst
üste bindirdi. İki sonuç da aynı yöntemin iki yüzüydü, eşikle çözülecek bir
şey değildi. Çözüm 2D iskelet animasyonunun kendi yöntemi oldu: tek parça
resim, kemik ağırlıklı ağ, doğrusal karışımlı deri (bkz. Wardrobe & Rig
Rules'un "one skin" maddesi, `tools/beast_skin.py`). Ağırlıklar modelin
kendi skin ağırlıklarından geliyor. Eklem kıvrımları ölçülerek giderildi:
ağırlık yayılımı ve bacak köküne bağlanan menteşe bandı ile, 16 fazda ters
dönen opak üçgen at ve öküzde sıfır, kurtta birkaç tane. Kurtunkiler koltuk
altında, dört kat yakınlıkta bile görünmüyor. Kurt zaten savaşta dinlenme
pozunda duruyor. Yürürken bacak adımı boyunu aşınca kaval kemiği gerilmek
yerine ayak hafifçe kalkıyor. Baş sallama ve kuyruk salınımı da ucu kaydırmak
yerine döndürüyor. Kemik boyları yürüyüş boyunca sabit, bunu da test
kilitliyor. `tests/screenshot_beast_rig.gd` yürüyüşün sekiz fazını basıyor.
Ayı ve domuz bu pakette yok.

**Aynı pakette referans olarak duran beyaz at, eşek, erkek geyik (stag),
geyik (deer) ve husky de aynı yöntemle, birebir aynı çalışma yürütülerek
skin'e kavuştu.** İki gerçek hata bu turda bulundu ve düzeltildi, ikisi de
`tools/beast_skin.py`'da:

- **`load_model()` "ilk mesh taşıyan node"yu alıyordu, skin taşıyanı değil.**
  Geyiğin boynuzu (`Stag_Horns`) ayrı, kemiksiz bir mesh - `Head` kemiğine
  rijit bağlı - ve node sırasında gövdeden (skin taşıyan asıl mesh) önce
  geliyordu, o yüzden araç boynuzu gövde sanıp çökmüştü. Düzeltme iki parça:
  skin taşıyan node'u `n.skin != null` ile bulmak (mesh'i değil), ve rijit
  ekleri (boynuz gibi) ait oldukları kemiğe tam ağırlıkla, kendi dünya
  dönüşümüyle deriye katmak - `beast_skin.py`'ın kendi "bir hayvan bütün
  boyanır, sonra kesilir" ilkesinin genellemesi: boynuz da hayvanın bir
  parçası, ayrı bir sistemi hak etmiyor.
- **Ölçek bir ölçüm değil, bir tasarım hedefi** - `SPECIES_BACK` her türün
  gerçek glTF oranlarından değil, oyunda ne kadar iri okunması gerektiğinden
  geliyor (at .66, kurt .50 zaten böyle seçilmişti). Beş yeni tür için de
  aynı disiplinle seçildi (donkey .55, stag .60, deer .48, husky .40,
  horse_white ata özdeş .66) - ham model oranlarını ölçüp ona göre
  ölçeklemek yanlış soruyu cevaplardı, "bu hayvan oyunda ne kadar büyük
  görünmeli" sorusunun cevabı asla ham geometriden gelmiyor.

**Üçüncü bir bulgu koddan değil, ekrandan geldi - ve harnessin kendisi
suçluydu, oyun değil.** Sekiz türü (at/öküz/kurt/beyaz at/eşek/stag/deer/
husky) tek bir karede, sekiz yürüyüş fazı × üç katman ile basan ilk deneme
her sütunda **en son çizilen türü, kendinden bir önceki türün resmiyle**
gösterdi - eşek deer'in, deer stag'in, husky de deer'in (sıralama
değiştirilince hangisi son sıradaysa o) resmiyle çıktı. Yarım saatlik bir
ölçüm zinciri (köşe verisi doğru, doku RID'i doğru ve türe özel, doku
piksel içeriği doğru - hatta husky'nin dokusu tamamen kırmızıya boyanıp
yeniden denendi, yine de bir önceki türün rengiyle çıktı) her uygulama
katmanının doğru çalıştığını gösterdi. Beş yeni türü tek başına, at/öküz/
kurt'suz basan bir deneme sorunu tamamen ortadan kaldırdı - yazılım
rasterleyicisinin (bu ortamda Vulkan yok, llvmpipe) aynı karede otuzu aşan
eşsiz `Texture2D` ile karşılaşınca bir dokuyu değil bir öncekini kullanması,
uygulama kodunun hiçbir yerinde görünmeyen bir render-katmanı sınırıydı.
`screenshot_beast_rig.gd` artık **iki ayrı kareye** basıyor - at/öküz/kurt
(gerçek `WalkFigure`/`CombatFigure` yolu, `beast_gait_sweep.png`) ve beş
yeni tür (`BeastRig`'in kendisinden, `WalkFigure`'a henüz bağlanmadıkları
için - `beast_gait_sweep_new_species.png`) - aynı "harnessten önce oyundan
şüphelen" disiplininin (bkz. Testing) bu turdaki karşılığı, ama ters yönde:
bu kez şüphelenilmesi gereken oyun değil, ekrana basan aracın kendisiydi.

**Beş yeni türün dördüne (beyaz at, husky, eşek/yarım vagon, erkek
geyik/geyik) oyuncunun kendi tarifiyle gerçek mekanik verildi - "ne işe
yarayacakları henüz kararlaştırılmadı" notu artık dördü için kapandı.**
Domuz ve ayı o sırada bekliyordu (kendi skin paketleri yoktu); husky/eşek/at
tarafında yeni bir çizim yolu icat edilmedi - `WalkFigure`'ın zaten var
olan `_draw_beast_sprites()` kapısı (bkz. Wardrobe & Rig Rules'un "one
skin" maddesi) iki yeni `KIND_DOG`/`KIND_DONKEY` sabitiyle doğrudan
`BeastRig.HUSKY`/`DONKEY`'e açılıyor - üçüncü bir tür (deer/stag) zaten
var olan `CombatFigure.ARCHETYPES` tablosuna birer satır olarak girdi.

**Sonradan tamamlandı: ayı ve yaban domuzu da gerçek deri sanatına
kavuştu.** Ayı rigsiz bir meshti - ölçülen ayak/sağrı/burun noktalarından
bir iskelet oturtulup kemik ısısıyla ağırlıklandırıldı, kutup ayısı
dokusu orman ayısı kahvesine çevrildi; domuzun kemikleri Quaternius
adlarına eşlendi. `beast_skin.py` bunun için GLB ve dokulu malzeme okumayı
öğrendi (kurt çıktısı bayt bayt aynı kaldı - üçüncü bir tür eklemek ilk
ikisinin skin'ini bozmadı). `data/assets/characters/beasts/bear/` ve
`.../boar/` artık `horse`/`ox`/`wolf` ile birebir aynı üçlü dosya setini
(`skin.tres`, `skin_main/tail/far.png`) taşıyor, `BeastRig.has_sprites()`
bunu otomatik görüp savaşta skinli çiziyor - `enemy_id` doğrudan
`figure_kind`'a aktığı için (`"bear"`/`"boar"`, `BeastRig.BEAR`/`BOAR` ile
birebir) hiçbir ek kod gerekmedi, tam olarak "bir tür yalnızca gövdesinin
resmi varsa sprite'a geçer" kuralının vaat ettiği şey. `test_beast_rig.gd`'nin
`SKINNED` dizisi ikisini de kapsıyor. Domuz ve ayı artık bu paragrafın
üstündeki "hâlâ bekliyor" notuna dahil değil.

- **Beyaz at, atın kendi bir varyantı - ayrı bir tür değil.** "Bazen
  beyaz bazen kahve, rastgele" sözü `WalkFigure.set_kind()`'ta bir kez
  atılan bir zarla karşılanıyor (`WHITE_HORSE_CHANCE`, %30 - "bazen" bir
  azınlık olsun diye, yarı yarıya değil) ve `_horse_species`'te
  saklanıyor: `_draw()` her karede çağrıldığı için zarı `_draw_quadruped`
  içinde atmak her kareyi farklı bir ata çevirirdi (titreme). `set_kind`
  bir figürün ömründe bir kez çağrıldığı için (bkz. `road_caravan.gd`/
  `world_hub.gd`'nin `configure()`/`_build_*` desenleri) seçim kalıcı -
  aynı at seferin başından sonuna aynı renkte kalıyor. `KIND_MOUNTED`
  (biniciyi taşıyan at) da aynı zarı paylaşıyor, ikinci bir kopya değil.
- **Husky, kervana katılan bir refakatçi - parti üyesi değil.** Kullanıcı
  "partiye en fazla iki köpek" dedi, ama proje kendi Character & Party
  Rules'unda "parti" kelimesini kasıtlı dar tutuyor (savaş alanının dört
  mevkisi, `MAX_PARTY_SIZE`). Bir köpeği o sisteme sokmak yeni bir
  mevzilenme/savaş kuralı icat etmek demekti - "iz sürme/awareness ve
  küçük moral" tarifi zaten destek bir rol, dövüşen biri değil. Bunun
  yerine `GameSession.owned_dogs` (tavan `MAX_DOGS` 2) kervanın kendi
  varlığı: Kervan Avlusu'nda "Köpek Sahiplen" (satış tuşunun aynı kod-içi
  sıra düğmesi deseni), her sahiplenmede artan bir bedel. Bir insan gibi
  besleniyor - `CaravanPlan.daily_consumption()` `height_adjustment`'ın
  aynı desenini tekrarlayan yeni bir opsiyonel `animal_mouths` payı aldı
  (varsayılan 0.0, eski çağıranlar hiç değişmeden geçiyor), köpek bu paya
  `DOG_PROVISION_SHARE` (0.4 - tam bir insan ağzından az) kadar katkı
  veriyor. "İz sürme/awareness" `get_best_effective_stat`/
  `get_leader_effective_stat`'ın yalnızca Sezgi (PERCEPTION) için okuduğu
  küçük, tavanlı bir pay (`get_dog_perception_bonus`, en fazla 1.2) -
  huyların `check_bonus`'uyla aynı "stat + küçük ek" formülü, başka
  hiçbir stat'ı etkilemiyor. "Küçük ölçüde moral" `get_departure_morale()`
  ve dökümüne (`UI_MORALE_DOGS`) eklenen ayrı, küçük bir terim - kervanın
  mizacının (`DEPARTURE_TEMPERAMENT_BONUS_CAP`) yarısı büyüklüğünde.
  Dünyada `world_hub.gd`'nin kolonunun en arkasında, tek sıra bir "sürü"
  olarak yürüyor - tam kolon formülü yerine (en fazla 2+3+3=8 hayvan için
  aşırıydı) sabit genişlikli, araya boşluk giren basit bir kuyruk, `_column_
  positions()`'ın "her parça kendi genişliğini tüketir" kuralının küçük
  ölçekli bir uygulaması.
- **Eşek ve "yarım vagon" ikisi de "ek hacim", tek bir havuzu paylaşıyor -
  `owned_wagon_count`'a hiç dokunmuyorlar.** Kullanıcının eşek tarifi iki
  parçalıydı: kervana ekstra hacim katan bir satın alma, ve tüccarların
  vagon yerine tercih edebileceği tek tekerlekli bir "yarım vagon" türü.
  Gerçek bir ikinci vagon *türü* eklemek (kendi tayfası, kendi WagonPanel
  etkileşim noktası, `wagon_inventories`'in vagon-indeksli her yerini
  genelleştirmek) bu turun kapsamını kat kat aşardı - `_sync_wagon_
  inventories()`'in kendi değişmezi (`wagon_inventories.size() ==
  owned_wagon_count`) tam da bunun için var, WagonPanel/world_hub'ın vagon
  etkileşim noktaları bu sayıya kilitli. Bunun yerine ikisi de (`owned_
  donkeys`, tavan 3; `owned_half_wagons`, tavan 3, biraz daha pahalı ve
  biraz daha çok kapasiteli - eşekten "yarım vagon"a giden fark tam da bu)
  `GameSession.pack_inventory` adında **üçüncü bir toplama havuzuna**
  katkı veriyor - kişisel çantanın (`CharacterData.personal_inventory`)
  zaten kurduğu ikinci-havuz desenine üçüncü bir örnek. `get_cargo_
  capacity()`/`get_cargo_weight()`/`add_to_cargo()`/`get_total_quantity()`/
  `remove_from_cargo_or_bags()`/`get_total_inventory_entries()`'in hepsi
  `wagon_inventories`'in yanına `pack_inventory`'yi de okuyor -
  `add_to_cargo()`'da vagonların *hemen ardından*, kişisel çantaların
  aksine (o bir son çare, bu normal kapasitenin parçası).
  **Bir tuzak burada yakalandı**: `Inventory.weight_limit == 0.0` "sınırsız"
  demek (kendi tanımı, boş/testler için) - eşek/yarım vagon hiç yoksa
  `pack_inventory`'nin gerçek kapasitesi sıfır olmalıydı ama önce yanlışlıkla
  sınırsız okundu, yani `add_to_cargo` kapasite aşan hiçbir isteği
  reddetmiyordu (`test_wagon_inventory.gd`/`test_game_session.gd`'nin beş
  testi bunu hemen yakaladı). Düzeltme `add_to_cargo`'nun `pack_inventory`'yi
  yalnızca `weight_limit > 0.0` iken havuza katması - "gerçek bir ek
  kapasite yoksa sınırsız değil, hiç yok" ayrımı. Dünyada eşekler/yarım
  vagonlar da husky'yle aynı arka sürüde yürüyor (`WalkFigure.KIND_DONKEY`),
  ayrı bir figür icat edilmedi.
  **Sonradan tamamlandı: tüccarların vagon yerine eşekle gelmesi**
  (kullanıcının "1 tüccar 1-2 eşek" tarifi). Çözüm `MerchantOffer`'ın 28+
  kalemlik sabit teklif tablosunu elle genişletmek ya da rastgele bir
  bayrak eklemek değil - üçüncü bir **profil**: `WorldMapData.
  _offers_for_direction()` her yönde zaten iki profil üretiyordu
  ("1 vagon", "2 vagon"); artık üçüncüyü de üretiyor - `MerchantOffer.
  donkey_count` (varsayılan 0, `uses_donkey_escort()` bunu okuyan tek
  yer) dolu, `wagon_count` kasıtlı olarak 0. Kısa/güvenli bir yol tek
  eşekle yürünür, uzun bir yol yükünü ikiye böler (`travel_days <= 4` ->
  1, değilse 2) - vagon tekliflerinin uzunluğa göre büyüyen kârıyla aynı
  mantık. `CaravanPlan.get_used_wagon_count()`'a hiç dokunulmadı: zaten
  yalnızca `wagon_count`'u topluyordu, sıfır olan bir teklif kendiliğinden
  havuza hiç girmiyor - Campaign Rules'un "buying wagons crowds out
  contracts" çelişkisine hiç girmeyen, yalın (az vagonlu) bir kervanın da
  alabileceği tek kontrat türü budur. Kâr da bilerek en küçük vagonlu
  teklikften az (`18 + gün*5` vs `30 + gün*8`) - eşekle taşınan yük gerçekten
  daha az, bedava bir üstünlük değil. Üç ekranın gösterdiği metin
  (`caravan_planner.gd`, `guild.gd`, `world_map.gd`) `uses_donkey_escort()`
  doğruysa "vagon" yerine "eşek" okuyor (`UI_PLANNER_DONKEYS`/
  `UI_GUILD_OFFER_DONKEY`/`UI_MAP_CONTRACT_LINE_DONKEY`) - kilitli bir
  seçeneğin sebebiyle gösterilmesiyle aynı "gizli bir davranış farkı bir
  hatadan farksızdır" disiplini. Bilerek dokunulmayan: kervanın kendi
  vagon/eşek/yarım-vagon sürüsünün aksine (bkz. yukarısı), eşekli bir
  tüccar yolda **ayrı bir figür olarak çizilmiyor** - bugün hiçbir
  escort-vagonlu tüccar da (1 ya da 2 vagonluk olsun) kendi ox+wagon
  birimiyle ayrıca çizilmiyor, `RoadCaravan._wagon_count` yalnızca
  oyuncunun **kendi** `owned_wagon_count`'unu okuyor. Eşekli tüccara özel
  bir görsel eklemek, görünmez kalan vagonlu tüccarların yanında haksız
  bir asimetri yaratırdı - `test_world_map_data.gd`'nin
  `_test_donkey_escorted_offers`'ı vagon tüketmediğini, doğru sayıda
  eşek taşıdığını ve doğru miktarda kazandırdığını kilitliyor.
- **Erkek geyik (stag) ve geyik (deer) yeni bir "avlanma" eventiyle
  (`evt_hunting_trip`) geliyor - ikisi de gerçek bir savaş açıyor, yeni
  bir kombat sistemi değil.** Orman/dağ biyomunda ağırlığı büyüyen bir
  yol kartı (`EventResolver.biome_context`, `stop_context`'in aynı
  deseni - `road_journey.gd`'nin `_after_meal()`'ı artık günün biyomunu
  da bağlama katıyor). Yaklaşmak Sezgi'ye bağlı bir skill-check
  (`SkillCheck.Source.PARTY_BEST` - "ortak bir çaba", tek bir kumarcı
  değil, tıpkı fırtınada yol almak gibi); başarı `EnemyCatalog.KIND_HUNT`
  türünde gerçek bir savaş açıyor, başarısızlık cezasız (hayvan sezip
  kaçıyor - bu bir tehdit değil bir fırsat, `evt_wild_animal`'ın "kaçmak"
  seçeneğinin tersine tehlike artırmıyor). `EnemyCatalog.build_hunt_squad()`
  her zaman tam bir erkek geyik + bir ya da iki geyik veriyor (kalabalık
  parti iki geyikle karşılaşıyor - `build_wildlife_squad`'ın parti
  büyüklüğüne göre eğme deseninin aynısı), asla karışık değil. Denge
  kullanıcının kendi tarifini kelimesi kelimesine karşılıyor: geyik zayıf
  (`damage_bonus` 2, `DEER_KICK` 3±2 hasar - "çok bir damage vurmayacak"),
  erkek geyik ağır (`damage_bonus` 10, `STAG_CHARGE` 13±5 hasar + sersemletme
  - ayıdan (`damage_bonus` 9) bile biraz daha sert, çünkü ayı nadir/tekil
  bir curio, erkek geyik kadronun her zaman içinde). Gerçek bir savaş
  karesinde (seviye 5, Dayanıklılık yatırımlı bir karakter, 62 can)
  ölçüldü: tek bir Boynuz Hücumu 20 hasar verdi, can 35/62'ye indi - "yarım
  canından tek vuruşta rahatlıkla indirebilmeli" isteği doğrulandı. İkisi
  de `BeastRig`'in zaten var olan skin sanatını (Faz "beş yeni tür")
  kullanıyor - `CombatFigure.ARCHETYPES`'a "stag"/"deer" birer satır
  olarak eklendi, `EnemyTemplate.enemy_id` doğrudan `BeastRig.STAG`/`DEER`
  ile aynı dize olduğu için (`CombatUnit.figure_kind = template.enemy_id`)
  yeni bir eşleme tablosu gerekmedi - `EnemyCatalog.get_kind_label`in zaten
  kurduğu "kadro türü → görünen ad" disiplininin aynısı.

**Düzeltildi: köpek/eşek/yarım vagon sefer sırasında hiç görünmüyordu.**
Yukarıdaki iş yalnızca `world_hub.gd`'ye (şehir dışı yürüme alanı) bağlanmıştı
- oyuncunun oynadığı gerçek yol ekranı `scripts/ui/road_caravan.gd`'nin
(`RoadCaravan`) kendi ayrı, paralaks arka planlı çizim yolu (bkz. bu
dosyanın kendi "Çizim ikiye ayrılmış durumda" notu), ve o dosyaya hiç
dokunulmamıştı - tam olarak "aynı şey iki yerde çizilirse iki farklı şey
olur" kuralının bir örneği daha (bkz. `RoadCaravan`/`menu_backdrop.gd`'nin
öküz-çifti kaldırımı gibi). Oyuncu köpek sahiplenip eşek satın alıp yola
çıktığında ikisi de kervanın **hiçbir** görsel temsilinde yoktu.
`RoadCaravan._walk_column()`'ın kendi "her parça kendi genişliğini tüketir"
kuralına yeni bir kuyruk eklendi: köpek/eşek/yarım vagon kolonun **en
arkasında**, tek sıra bir sürü olarak (`DOG_HEIGHT_RATIO`/
`DONKEY_HEIGHT_RATIO`, `world_hub.gd`'nin aynı "tam kolon formülü bu kadar
az hayvan için aşırı" kararı) - yarım vagon eşekle aynı figürle çiziliyor,
ikisi zaten `GameSession.pack_inventory`'nin aynı kapasite havuzunu
paylaşıyor. `get_pack_centres()` `get_ox_centres()`'le aynı desende test
okuyor; `tests/test_caravan_layout.gd`'nin yeni testi dört hayvanın da
çizildiğini ve hepsinin son vagondan geride, üst üste binmeden durduğunu
doğruluyor.

Faz 22 ("İkinci sanat turu") - Gemini'den ikinci bir toplu teslimat geldi:
91 dosya, üç arşiv halinde (21 olay kartı illüstrasyonu, 10 yönetim ekranı
arka planı ve harita, 57 ikonun yeniden çekimi, 12 yeni ekipman ikonu).
Görev sanatı üretmek değildi - elde olanı denetlemek, kendi düzeltebileceğini
düzeltmek, geri kalanını `docs/wayborne_gorsel_denetim.xlsx`'e (prompt
listesiyle aynı biçimde, bir "Durum" sütunu eklenmiş) dökmekti.

- **Tam denetim, dosya dosya.** `tools/waybook_ingest_v2.py` yeni teslimatı
  işleyen araç - `waybook_assets.py`'nin `crop_to_alpha`/`unpaper`'ını
  yeniden kullanıyor, kendi kırpma fonksiyonunu icat etmiyor (bkz. "Art
  arrives through one pipeline" kuralı). Eski turdan farklı: bu kez
  simler zaten kendi alfa kanalını taşıyor (gönderen kendi arka plan
  kaldırmasını yapmış), yani iş `key()` değil `crop_to_alpha` + boy.
- **Kompozit bir ızgara kanıt değildir - denetim tek dosya okumakla
  yapıldı.** Onlarca küçük ikonu tek bir PNG'de yan yana basıp o kompoziti
  okumak birkaç kez **yanlış** eşleşme gösterdi (bir hücrenin etiketiyle
  içeriği tutmuyor okundu) - dosyaların kendisi her zaman doğruydu, tek
  tek okununca doğrulandı. Artık bu dosyanın kendi kuralı: bir dosyanın
  içeriğini onaylamak o dosyayı tek başına okumakla olur, kompozit bir
  ızgara yalnızca kabaca göz atmak için.
- **Üç gerçek kusur bulundu, üçü de otomatik düzeltilebildi.**
  `item_grain.png`/`k4a_bleed.png`'in arkasında düz, keyleme sırasında
  atlanmış bir kart kalmıştı (`unpaper`'ın `PAPER_MIN`'inin altında bir
  gri - açık beyaz değil); `p4_witnessed_death.png`/`p3_endurance.png`'de
  aynı sınıf kusur ama gradyanlı, tek renk örneklemeyle silinmiyordu.
  `waybook_ingest_v2.py`'nin `_key_from_seed`'i kartın üstünden birkaç
  nokta örnekleyip oradan taşkın dolduruyor - dördü de artık temiz.
- **İki ikon kendi dosya adıyla uyuşmuyordu, düzeltilmedi.** `p3_agility.png`
  "sıçrayan bir tavşan" yerine `p3_strength`'in neredeyse eşi bir
  "yumruk + halka" taşıyordu; `p5_scout.png` "eldivenli yumruk üstünde
  şahin" yerine ufka bakan bir insan portresi taşıyordu (ailenin geri
  kalanı hep nesne, insan değil). İkisi de **kullanılmadı** - mevcut,
  doğru konulu eski ikonlar yerinde kaldı. Yanlış bir resim, eksik bir
  resimden daha kötü: biri boş göze çarpar, öbürü sessizce yanlış
  öğretir. `p3_intellect` (terazi) ve `p4_passed_over` (kırık mühür)
  de prompt'tan sapıyor ama önceki turdan beri **aynı** sapmayla
  zaten oyunda - yeni bir karar değil, daha yüksek çözünürlükte aynı
  karar, dokunulmadı.
- **Olay kartları ilk kez bir resim taşıyor.** `EventCatalog`'un 60'tan
  fazla `evt_*`'i içinden 40'ı `EVENT_CARD_ART` tablosuyla bir `e6*.jpg`'ye
  eşlendi (`road_journey.gd`) - eşlemede olmayan olay eskisi gibi resimsiz
  açılıyor, `EVENT_ROAD_MARKER_KIND`'in "her olay bir işaret istemez"
  kuralının aynısı. Kare resim `STRETCH_KEEP_ASPECT_COVERED` ile
  `CARD_ILLUSTRATION_HEIGHT` (200px) yüksekliğinde kırpılıp kartın
  başlığıyla gövdesi arasına giriyor - üç haber olayı (savaş/veba/fuar)
  ve üç mezar olayı (bkz. Faz 19'un "İşaretsiz Mezar" zinciri) kasıtlı
  olarak **aynı** resmi paylaşıyor, çünkü kurguda da aynı sahne.
- **Ekipman ilk kez bir resim taşıyor.** On iki yeni `eq_*.png`
  (silah/zırh üç tier, yüzük/kolye üçer tılsım) `WaybookTheme.
  equipment_icon()`'a (`item_icon()`'un birebir deseni -
  `Equipment.equipment_id` zaten dosya adıyla aynı) bağlandı; karakter
  ekranının equip satırı hem takılı parçanın hem her seçeneğin ikonunu
  gösteriyor artık, ikonu olmayan bir parça (henüz gelmemiş bir tier)
  sessizce boş bir yer tutucuya düşüyor - `item_icon`'un "satır hizası
  bozulmasın" kuralının aynısı.
- **Yönetim ekranı arka planları ve harita çok daha yüksek çözünürlükte
  yeniden geldi** (1376x768 ve 1200x896 asıl piksel, eskisi 220-300 KB'lık
  ölçeklenmiş kopyalardı) - aynı dosya adlarının üstüne yazıldığı için hiç
  kod değişmedi, `.tscn`'ler zaten o yolu okuyor.

Faz 23 ("Ayı gerçekten büyük, kurt sürüsünün bir reisi var") - kullanıcının
kendi ekran görüntüsüne ("bear_check.png") verdiği doğrudan geri bildirim:
ayı ve yaban domuzu Faz 21'in beast-skin sanatıyla artık *çiziliyordu* ama
savaş mevkisinin kutusuna sığdırılırken bir insanla neredeyse aynı boyuta
küçülüyordu - "portreler hayvanları küçültüp gerçek oranlarını küçültüyor."

- **Kök neden bir ölçek değil, bir kırpmaydı.** `CombatFigure.
  _draw_beast_sprites()` her zaman iki adım atıyordu: `fit` (hayvanın kutuya
  tam sığan en büyük boyu) ve ardından `archetype.bulk * 0.85`'i bununla
  çarpan bir ikinci pay. O ikinci pay `minf(1.0, ...)` ile üstten
  kırpılıyordu - yani `bulk` ne yazılırsa yazılsın (ayı zaten 1.35'ti),
  1.18'in üstündeki hiçbir değerin sprite çiziminde **hiçbir etkisi**
  yoktu, hayvan her zaman "kutuya tam sığan" boyda kalıyordu. Ayının
  arketip `bulk`'ı zemin gölgesini (`_draw_ground_shadow`) ve resmi
  olmayan prosedürel yedek çizimi (`_draw_beast`'in kendi dalı) zaten
  doğru okuyordu - kırpma yalnızca gerçek deri sanatının çizildiği tek
  yoldaydı, ki oyuncunun gördüğü tam olarak oydu.
- **Düzeltme kırpmayı kaldırmak, ikinci bir sistem eklemek değil.**
  `bulk := float(_archetype().bulk) * 0.85` artık kırpılmadan `h`'ye
  giriyor - `ARCHETYPES`'a yazılan sayı gerçekten o kadar büyük çiziliyor,
  kutuyu (ve komşu mevkiyi) bilerek aşarak. `CombatUnitSlot`'un hiçbir
  çocuğunda `clip_contents` açık değil, yani taşma zaten görsel olarak
  destekleniyordu - yalnızca hiçbir `bulk` değeri onu tetikleyecek kadar
  büyük olamıyordu. `bulk` tek bir çarpan olduğu için (`h` hem eni hem
  boyu birlikte büyütüyor) gerçek oran hiç bozulmuyor - kullanıcının
  "gerçekçi görünümleri olsun" isteği tam olarak bu: hayvan büyüyor,
  eğilmiyor/gerilmiyor. Ayının `bulk`'ı 1.35 → 2.6, domuzunki 1.10 → 1.75
  (kullanıcının kendi ölçüsü: "ayı iki insan genişliğinde, domuz bir buçuk"
  - ekran görüntüsüyle doğrulandı, bkz. `tests/screenshot_beast_rig.gd`'nin
  kardeşi olan tek seferlik doğrulama scripti, commit'e girmedi).
- **Kurt sürüsüne bir reis eklendi - "Kırağı Kurdu" (beyaz) ya da "Zifir
  Kurdu" (kara), kullanıcının kendi isteği.** `EnemyCatalog.
  WOLF_ALPHA_WHITE`/`_BLACK` sıradan kurdun (~1.8 katı can, biraz daha
  isabetli/kaçıngan/kritikli) iki yeni `EnemyTemplate`'i; `build_wildlife_
  squad()`'ın kurt kolu artık `WOLF_PACK_LEADER_CHANCE` (%40) ile sürünün
  ilk kurdunu bir reisle değiştiriyor - tek bir zar, tek bir yerine koyma,
  yani beyaz ve kara **hiçbir zaman** aynı sürüde birlikte çıkamaz
  (yapının kendisi garanti ediyor, `test_enemy_variety.gd`'nin
  `_test_wolf_pack_leader`'ı altmış bağımsız tohumda regresyon kilidi).
- **İsimler ayrı bir turda gerçek ada kavuştu - "kara börü" değil.**
  İlk sürüm ikisine de `display_name_key`'i bilerek WOLF'unkiyle aynı
  vermişti ("tek türden" testinin kolay yolu); kullanıcı bunu reddetti
  ("kara börü demeyin, uygun farklı bir isim bulun") ve her ikisinin kendi
  adını istedi. Çözüm ikinci bir isim sistemi değil, mevcut testin kendi
  varsayımını genişletmek oldu: `test_enemy_variety.gd`'ye
  `_species_family()` eklendi - "Kurt"/"Kırağı Kurdu"/"Zifir Kurdu" üçü de
  aynı aileye ("wolf") düşüyor, `_test_wildlife_squad_never_mixes_species`
  artık tek bir *ad* değil tek bir *aile* arıyor (ayı/domuz/kurt üçü yine
  asla karışmıyor - bu kural hiç gevşemedi). `ENEMY_WOLF_ALPHA_WHITE_NAME`/
  `_BLACK_NAME` `game.csv`'ye eklendi (tr/en dolu, diğer diller
  `ENEMY_WOLF_NAME` gibi boş - fallback zaten İngilizce).
- **Boy da ayrı bir turda büyüdü: sıradan kurt 1.5 kat, reisler sıradan
  kurdun tam üç katı - kullanıcının kendi ölçüsü.** `CombatFigure.
  ARCHETYPES`'ın `bulk`'ı: kurt 0.95 → 1.425, iki reis de 1.20 → 4.275
  (1.425 × 3). Bear/boar'ın kendi turundaki aynı formül (`_draw_beast_
  sprites()`'ın artık kırpmadığı `bulk`) burada da işliyor - reis artık
  sıradan kurdu tamamen gölgede bırakan, insan mevkisini de büyük ölçüde
  kaplayan bir silüet (ekran görüntüsüyle doğrulandı).
- **Görsel ayrım yeni bir sanat değil, bir renk çarpanı - bu karar
  değişmedi.** Ne "Kırağı Kurdu" ne "Zifir Kurdu" için ayrı bir 3D model/
  skin var - ikisi de aynı `BeastRig.WOLF` iskeletini/derisini kullanıyor.
  `CombatFigure.ARCHETYPES`'a `sprite_kind`/`sprite_tint` alanları
  eklendi: `_kind` (arketip anahtarı, palet/güç) artık her zaman doğrudan
  bir `BeastRig` türüne eşlenmek zorunda değil - `_sprite_species()` varsa
  `sprite_kind`'ı, yoksa `_kind`'ın kendisini döner (eski her tür için
  no-op). `_draw_beast_sprites()` `BeastRig.draw_species()`'e tonu
  `_state_tone() * _sprite_tint()` olarak geçiyor - beyaz reis için
  parlaklığı 1'in üstüne çıkaran bir çarpan (`Color(1.55,1.60,1.75)`,
  dokuyu aydınlığa yıkıyor), kara reis için koyulaştıran bir çarpan
  (`Color(0.28,0.27,0.30)`). Varsayılan (1,1,1,1) - her eski tür (kurt/ayı/
  domuz/geyik/at...) hiç değişmeden aynı kalıyor.
- **Mevki çerçevesi kaldırıldı, sıra/hedef bir çizgi değil bir parıltı
  oldu - kullanıcının kendi isteği ("çerçeve olmasın... hafif bir glow,
  temaya uygun").** `CombatUnitSlot`'un woodgrain K1/K2 dokuları
  (`k1_slot.png`/`k2_door.png`) tamamen kaldırıldı; panel artık yalnızca
  eski çerçevenin içerik boşluğunu koruyan boş bir `StyleBoxEmpty`. Ölümün
  Kıyısı'nın çatlak çerçevesi hiçbir zaman tek sinyal değildi (figürün
  kendi kırmızı tonu ve durum satırındaki rozet zaten var), o yüzden
  kaldırılması bir bilgi kaybı değil. Sıra/hedef vurgusu artık `_draw_
  glow()` - dıştan içe azalan alfalı, genişleyen kenarlı birkaç `StyleBoxFlat`
  katmanı (gerçek bir blur shader'ı yerine ucuz ama yeterli bir yaklaşım),
  renkler zaten temanın kendi paleti (`ArtPalette.GOLD` sıra, `ArtPalette.
  BLOOD` hedef - `UI_ACCENT`/can çubuğu dolgusuyla aynı aile, yeni bir renk
  icat edilmedi).
- **Mevkiler arası boşluk büyütüldü - domuzlar birbirine giriyordu.**
  Hayvan portrelerinin artık kutularını bilerek aşması (bkz. yukarısı)
  eski 4px'lik `_player_row`/`_enemy_row` ayracını anlamsız kıldı - iki
  büyük hayvan yan yana geldiğinde üst üste biniyordu, kullanıcının kendi
  bildirdiği hata. Ayraç 4 → 56'ya çıktı; iki domuzluk bir sürü artık
  ekran görüntüsünde net biçimde ayrışıyor.
- **İlk tur boşluğu yalnızca satır içinde çözdü - ölçülmeden bırakılan tek
  sınır patladı.** `_player_row`/`_enemy_row` arasındaki `gap` Control'ü
  (iki tarafın en önünün karşı karşıya durduğu, `_player_row`
  `ALIGNMENT_END`/`_enemy_row` `ALIGNMENT_BEGIN` olduğu için) hâlâ eski
  26px'te kalmıştı - kullanıcının kendi bildirdiği ikinci hata: "parti ile
  düşman arası boşluk da ezilmiş." En riskli sınır en dar boşluktaydı; 26 →
  160 (satır içi ayraçtan - 56 - da geniş, çünkü taşan bir ayı/kurt reisi
  tam bu noktada karşı safa bakıyor).
- **Kurt sürüsü reisi ayıdan büyük çıkmıştı - ölçüsüz bir "üç kat" hesabı
  yüzünden.** İlk turun `bulk`'ı (4.275 = sıradan kurdun üç katı,
  kullanıcının kendi ilk isteği) sıradan kurdun taze büyütülmüş boyu
  (1.425) üstüne bindirilince ayının kendi `bulk`'ını (2.6) geçti -
  kullanıcı ekran görüntüsünde gördü ve düzeltti: "direwolf çok büyük
  olmuş, bear ile aynı boyutta olmalı." `wolf_alpha_white`/`_black`'in
  `bulk`'ı artık bilerek "bear"la birebir aynı sayı (2.6) - iki büyük,
  nadir/tekil karşılaşılan hayvan aynı görsel ağırlığı taşıyor.
- **Wardrobe testinin tek başarısız satırı, oyunun kendi hatası değildi.**
  `_test_body_variant_id_falls_back` gerçek diske (`user://wardrobe_test/`)
  bir `body_male_heavy` fixture'ı yazıyordu ama hiçbir yerde silmiyordu -
  bu container'da testin daha önce en az bir kez çalışmış olması, "sanat
  yokken düz body'ye düşer" iddiasını her sonraki koşuda kalıcı olarak
  yanlış çıkarıyordu (fixture disk üstünde zaten duruyordu). `_remove_
  fixture()` eklendi ve test artık fallback'i sınamadan önce **ve** sonra
  kendi fixture'ını temizliyor - `simulate_journeys.gd`'nin "her RNG
  tohumlanır" disipliniyle aynı aile: bir testin sonucu kendi önceki
  koşusuna bağımlıysa flake'ten farksızdır.
- **160px'lik merkez boşluğu tek riskli sınır değilmiş - kurt sürüsü
  reisinin kuyruğu sıra içinde de aynı hatayı yaptı.** Kullanıcı kendi
  ekran görüntüsünü gönderdi: "Kırağı Kurdu"nun (bulk 2.6) kuyruğu
  arkasındaki sıradan kurdun (bulk 1.425) üstüne biniyordu - `_player_row`/
  `_enemy_row`'un kendi ayracı hâlâ 56px'teydi, yalnızca iki safın karşı
  karşıya geldiği merkez boşluk (`gap`) 160'a çıkarılmıştı (bkz. yukarısı).
  Ölçüm: `CombatFigure._draw_beast_sprites()`'ın `fit`/`bulk` formülü yan
  görünümlü bir kurdun çizilen genişliğini `box.x * 1.05 * bulk * 0.85`'e
  çıkarıyor - alpha'da (bulk 2.6) bu `SLOT_WIDTH`'in (136) neredeyse iki
  katı, sıradan kurttan (bulk 1.425) çok daha fazla taşıyor. Aynı riskin
  ikinci bir örneği olduğu için aynı çözüm: `_player_row`/`_enemy_row`'un
  ayracı da 56 → 160, merkez boşlukla birebir aynı değer - "taşan bir ayı/
  kurt reisinin gövdesi komşu mevkiye bakıyor" gerekçesi satır içi komşular
  için de eşit derecede geçerli. Yeniden çekilen ekran görüntüsü kuyruğun
  artık komşu kurda değmediğini doğruluyor; `test_combat_core.gd` bu sabiti
  sınamıyor (yalnızca mevki sayısını sayıyor), o yüzden regresyon tam
  test paketiyle (12839/12839) doğrulandı.

Faz 25 ("Eşya ve kuşam turu") - oyunun prosedürel çizdiği nesnelerin
ücretsiz, ticari kullanıma açık paketlerden render edilmesi; seçki önce bir
onay sayfasında sunuldu, oyuncu onayladı ve geri bildirim verdi (keçe külah
yedeği silindi, binici pantolonunun yedeği seçildi, diğer yedekler çeşit için
eklendi, deri tonları koyulaştırıldı, kombinlerin iç içe geçmemesi istendi):

- **Eşyalar** (bkz. Prop Rules): brandalı vagon (temel unsur, oyunun kendi
  oranlarıyla sıfırdan) ve eşek arabası, sur geçidi, iki değirmen, köy
  evleri, karakol, maden, çadır, kamp ateşi, sandık/fıçı/çuval, izometrik
  şehir binaları, on üç silah ve kalkan.
- **Kuşam**: 16 giysiden 48'e (cinsiyete özel kalemler, elbiseler, cübbeler,
  miğferler), üç zırh kademesinin görünüşü, `hides`/`genders` kuralları,
  kalınlık kabuğu. Önlük kesildi, rijit zırh yerine kumaş zırh - ikisi de
  kombin QA'sında görüldü (Wardrobe & Rig Rules).
- **Lore**: `docs/lore/LORE.md` ve `docs/lore/TARIHCE.md` - oyunun bugün
  bildiği evren ve tarih, boş satırlarıyla.

Faz 26 ("Büyü ve yara") - silahların ele göre önde/arkada çizilmesi
(kılıç sağ elde, kalkan sol kolda), büyücü cüppesi ve külahı (MakeHuman,
CC-BY), yedi temel büyü ve iki durum (yanma, üşüme), vuruşun biçimine göre
yedi yeni klip (ok/kesik darbesi, kaçınma, yanma/donma/zehir tepkisi, büyü
yapma; 6 beden × 50 giysi yeniden render), savaş boyunca saplı kalan ok ve
bıçak, Kenney Particle Pack (CC0) üzerinden mermi/çarpma katmanı ve bedenin
kendisinde süren durum izi (bkz. Combat Rules, Motion Rules). Lore: iki
büyük inanç Baikhan ve The Hand; coğrafya soruları `docs/lore/SORULAR.md`.

**Faz 27 ("Karanlık arayüz ve render edilmiş yol") birleştirildi.**
`ui-hud-redesign` dalındaki taslak üç turda onaylandı: şehre özgü önden
kasabalar (beş şehir), gece kampı menüsü, CC0 dokulu şeritler ve ikonlu
düğmeler, Celsius göstergesi, gotik vitrin yüzü - ve yolun render edilmiş
paralaks katmanları (bkz. Rendered Road Rules), ki bu oyunda zaten
çalışıyor. Kasaba, menü ve HUD bileşenleri hazır ama ekranlara bağlanmadı
(Ana Hedefler).
