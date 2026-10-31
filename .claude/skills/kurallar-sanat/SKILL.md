---
name: kurallar-sanat
description: Wayborne kural kitabının "Çizim, sahne sanatı, render edilmiş yol ve eşyalar, ses" bölümü (CLAUDE.md'den taşındı). Şunlara dokunmadan, şunları tasarlamadan ya da şunlar hakkında karar vermeden önce yükle: ArtPalette, ArtDraw, _draw() ile çizilen sahneler, TravelBand, TravelForeground, RoadStrips, PropArt, render edilmiş yol katmanları, eşya render'ları, AudioManager, müzik ve efekt. Bozulmaması gerekenleri ve nedenlerini tutar.
---

# Çizim, sahne sanatı, render edilmiş yol ve eşyalar, ses

CLAUDE.md'nin bu bölümleri 2026-10-30'da kullanıcı kararıyla buraya taşındı; metin değişmedi, başlıklar aynı. Koddaki
"bkz. CLAUDE.md <başlık>" başvuruları buraya bakar. Kural becerilerinin listesi CLAUDE.md'de ("Kural becerileri").
Bölümler: Audio Rules, Art Rules, Rendered Road Rules, Prop Rules.

### Audio Rules

- **One place knows which screen plays what.** `AudioManager` maps screens
  to tracks; the menu and the road share one (both are "you are on the
  way"), the city has its own (arrival). Same reasoning as `ArtPalette`
  being the only colour source.
- **A transition is a crossfade, not a cut.** Two players, not one: the
  moment the road ends and the city begins is where the game most needs to
  say *we arrived*, and a hard cut breaks it.
- **`play_track` is idempotent**, so moving between city screens does not
  restart the music.
- **The loop flag is set in code, not in the import settings.** `.import`
  files are gitignored and CI regenerates them, so a flag set there would
  vanish in a clean clone.
- **The default volume has exactly one owner** (`UserSettings`), and
  `AudioManager` reads it lazily. A second default is a silently wrong
  opening volume the day the two drift — and laziness also removes the
  dependency on autoload ordering.
- **Ambience is a third layer, not a variant of music.** The title screen
  needed wind playing while there is deliberately no music yet, and the
  moment the player presses a key both have to move at once - wind fading
  out under the road track fading in. Forcing that through the two-player
  crossfade built for *music-to-music* transitions would have meant either
  ambience competing with music for the same two players, or one of the
  two cutting instead of fading. `_ambience_player` is a third, independent
  `AudioStreamPlayer` with its own fade (`play_ambience`/`stop_ambience`),
  so the two layers can move in opposite directions in the same moment
  without touching each other's state.
- **A one-shot sound never shares a player.** `play_sfx()` spins up a
  fresh `AudioStreamPlayer`, plays it, and frees it on `finished` - it does
  not reuse `_active`/`_standby`/`_ambience_player`. Those three are always
  mid-crossfade or mid-loop; a gate creak and a menu-transition thud can
  land in the same moment, and stealing a busy player to play one of them
  would cut off whatever it was already doing.
- **A sound effect asset that doesn't exist yet is still safe to call.**
  `play_sfx`/`play_ambience` check `ResourceLoader.exists()` exactly like
  `_load_stream` already did for music, and no-op quietly if the file is
  missing - calling code never needs to know whether the asset landed yet.
  The wind bed, the wooden thud and the gate creak currently shipped are
  themselves placeholders in that same sense: synthesized in pure Python
  (`wave` + sine/noise, no external tools) rather than recorded, the audio
  equivalent of a `ColorRect` before the hand-drawn pass (see Art Rules).
  `AudioManager` has no idea which kind it's playing - swapping a `.wav`
  for a real recording later touches no code.

### Art Rules

The game was drawn in `ColorRect`s: the road was two rectangles and
fourteen sliding lines, the city five buttons, the caravan a row of
coloured boxes. The complaint - *"it looks like we are making a game in
Excel"* - was correct, and the deeper half of it is that a rectangle
cannot lie about being still but lies immediately once it moves.

The world (road, city, combat, menu backdrop) is drawn in `_draw()`. The
UI chrome has started moving to textures - see Waybook UI Rules - and
`ArtPalette` stays the colour authority either way; drawing functions give
way to textures one screen at a time.

- **One palette, one set of brushes.** `ArtPalette` is the game's only
  colour source (four day phases, five biomes, each biome filling the same
  four roles so a biome change can be a `lerp` rather than a cut);
  `ArtDraw` is the only set of brushes (gradient band, silhouette ridge,
  tree, conifer, rock, shrub, water, light pool, vignette, inked fill,
  wagon). Every screen inventing its own colours is why the game did not
  look like one production.
- **Tek sıcak kaynak (kullanıcı kararı 2026-10-31, görev Y-G17).** Dünyada sıcak renk yalnızca bir ışık
  kaynağından gelir: ateş, fener, meşale, pencere ışığı ve defterin sayfası (hatıra). Gök, zemin, bina, giysi ve
  sahne dokusu soğuk ve soluk kalır; bir sahnede sıcak olan ışığın kendisi ve düştüğü yerdir. Kıtlık derinleştikçe
  sıcağın payı küçülür, bölgeye göre (Gokyurt en geç solar, Y-G18). Neden: sıcak her yerde olunca ateşin anlamı
  kalmaz; kervanın ısındığı yer ekranda da tek sıcak yer olmalı. `GrimGrade` sıcak ışık dışındaki doygunluğu zaten
  düşürüyor; bu kural onun hedefini söyler. Arayüzün okunaklılığı (metin kontrastı) kuralın dışında. Yeni bir sahne
  ya da sanat bu kurala göre yapılır; eski sahnelerin denetimi Y-G17'de.
- **A shape drawn in two places is two different shapes.** The wagon lives
  in `ArtDraw.wagon()` because the road band and the walking area both draw
  it; keeping a copy each meant the same caravan's wagon was two different
  objects on two screens. Same reasoning as
  `CaravanPlan.daily_consumption()`.
- **The UI's own small marks are drawn too, never dialed from a font.**
  Position pips, sort chevrons and the objective check were Unicode
  characters (`●○↑↓✓`) for a while, and every one of them rendered as an
  empty box: Godot's default font doesn't carry Geometric Shapes, Arrows
  or Dingbats. A playtest photographed the combat panel's position marks;
  the same failure was sitting in eleven other player-facing spots
  (`UiIcon.gd`'s header lists them) and no test could see any of them,
  because the text itself was correct and translated - it just couldn't be
  rendered. `UiIcon` (`scripts/ui/`) draws these through `ArtDraw.pip()`/
  `chevron()`/`check()` instead, the same reasoning as the wagon: a shape
  is drawn once, not dialed from a font that may not carry it. See
  Localization Rules for the guard that now catches a glyph the font can't
  show, in either a CSV cell or a screen literal.
- **Scenery is generated from world coordinates, never from a list.** Each
  layer's props come from `hash(cell index)`; cells enter as the view
  scrolls and are forgotten as they leave. A fixed array wraps around, the
  player sees the repeat, and the road becomes a treadmill.
- **Nothing tall below the road; nothing low-and-near above it.** Trees,
  conifers, boulders and mountains all sit on the far side; below the road
  there are only shrubs, grass, small stones, mud and (in rain) puddles.
  Perspective is the reason: below is the closest point to the camera, and
  a tree there hides both the scene and the caravan.
- **Whatever is in front of the caravan must be drawn after it.** A band's
  own `_draw()` runs *under* its children, so anything it draws is behind
  the caravan - which is why figures looked like they were walking on top
  of the trees. `TravelForeground` is a sibling added after the caravan
  (`TravelBand.add_actor_layer()` is the single door that keeps the order);
  `HubScenery` splits into `LAYER_BACK` and `LAYER_FRONT` on two `z_index`
  values.
- **Column layout is spacing, never fixed steps.** Every piece of the
  caravan consumes its own width and a gap follows it, so an overlap is
  arithmetically impossible. Fixed steps failed twice - two wagons on top of
  each other, then the rear wagon's ox inside the front wagon - because the
  step was unrelated to the real widths. At most two people walk abreast and
  the gap between them is *derived from the figure's width*: a constant 30
  put two eighty-pixel figures on top of each other. Party members are
  spread along the column rather than stacked behind the leader, and the
  walking crew go **ahead of** their own wagon: beside it overlapped the
  body, behind it produced exactly the nameless tail the design does not
  want.
- **Nothing stands between an ox and its wagon — that space is the
  hitch.** The wagon unit was `[ox] [crew] [wagon]`, because the walking
  crew member could not go beside the wagon (it overlapped the body) or
  behind it (that is the nameless tail the design rejects). Putting them
  in the only remaining place put them *inside the harness*: measured, the
  ox sat 128px from its wagon against a wagon 67px wide, with a man
  standing in the middle, so the ox read as a stray animal rather than the
  one pulling that wagon. The drover now walks at the ox's head, which is
  how an ox cart is actually driven, and `ArtDraw.draught_pole()` draws
  the pole and yoke — without it the ox is an animal *standing* in front
  of a wagon. `tests/test_caravan_layout.gd` asserts the clearance is
  neither negative (ox inside the wagon) nor more than 0.6 × the wagon's
  width; the old order fails it 48 times.
- **The caravan must fit the frame it stands in, because it grows.** The
  anchor was a constant 0.34 of the band's width, so only a third of the
  screen sat behind the caravan — measured, a two-wagon caravan had its
  second wagon at x = −264 and a six-wagon one showed nothing but the
  first. Buying wagons is what the campaign pushes the player toward, and
  it had no visible consequence at all: the same failure as the nameless
  crew being invisible before Faz 8 PR-C. The anchor now slides right with
  the column (`TravelBand.caravan_x_ratio()`, clamped) and, only if that
  is not enough, `RoadCaravan` scales the whole column down to
  `MIN_COLUMN_SCALE`. Everything up to `FULLY_VISIBLE_WAGONS` (4) is on
  screen; a longer train's tail leaving the frame is honest, since a long
  caravan is longer than the view.
- **Measuring the column and placing it are the same function.** They were
  two, and they disagreed: the measuring copy forgot the walking crew
  member and two tight gaps inside each wagon unit, so the column read 66px
  short per wagon and the tail overflowed a frame it was calculated to fit.
  `RoadCaravan._walk_column(scale, place)` walks the cursor once and either
  places or only measures — the same reasoning that already puts the wagon
  centres in the layout rather than in `_draw()`.
- **A body part is the silhouette, not a decal on it.** The ox's shoulder
  hump — the cue that separates it from the horse — was a pale, un-inked
  ellipse laid over the back, and it read as exactly that: a disc stuck on
  the animal's nape. It was also the only shape on the whole figure drawn
  without `ArtDraw.inked`, so it did not even belong to the same drawing
  language as the body, neck and head. The hump is now two vertices in the
  body outline, so the topline itself humps; the small light ellipse that
  remains sits *inside* the body as a volume cue, which is the one place
  an outline-free shape is right.
- **A figure that moves needs joints.** `FigureRig` (see Wardrobe & Rig
  Rules) solves hip → knee → foot with two bones; swinging a single-piece leg reads as scissors. The
  foot stays put while it is on the ground, so the figure does not slide.
  Wheels and walk cycles advance with **distance, not time** - a stationary
  wagon whose wheels turn is the vehicle-shaped version of a sliding
  rectangle.
- **Palettes are shared with combat.** `WalkFigure` reads
  `CombatFigure.ARCHETYPES`: the guard you saw in the fight walks the road
  in the same colours. Skin tone comes from `CharacterData`, height scales
  the figure - what character creation chose has to be visible or the
  choice is only text.
- **Lessons kept from the deleted `CityView` (full history: `docs/history/CLAUDE_ARSIV.md`).** A child added after its
  parent was sized never receives `PRESET_FULL_RECT`'s size: adopt `get_parent_control().size` and re-sync on the
  parent's `resized`, and never mix anchors with direct `size`/`position` writes. A drawing that can be larger than its
  rect needs its own scale and `clip_contents`, with clicks run through the inverse transform. Every `Label` in a column
  that can narrow needs `autowrap_mode` and no hard minimum width, or one label widens the whole container. When a
  report says "gray strip", sample the exact edge the report points at: three fixes were declared done against
  screenshots that still showed it. A flat ground colour reads as an empty frame; scatter ground marks with a minimum
  gap, never on the town's own footprint.
- **The brief now opens with where you are, not just what to do.**
  `CityBriefPanel._welcome_heading()` prints the city's own name (a
  proper noun, same exemption as the culture name pools - not run through
  `tr()`) as the panel's first line, with a generic, suffix-free
  `UI_BRIEF_WELCOME_LINE` ("Hoş geldiniz.") under it. Turkish's dative
  case ("İpekevi'ne", "Yeşilova'ya") needs a different buffer letter per
  city name depending on vowel harmony, which a `%s`-formatted key cannot
  get right for names not yet written - splitting the city name onto its
  own line sidesteps needing that logic at all, for this or any later
  city.
- **Everything that stands on the ground gets a contact shadow.**
  `ArtDraw.wagon()` and `WalkFigure` had one from the first day, and
  `WalkFigure`'s comment already said why — *without it the figure really
  does look like it is floating*. The scenery never got the same
  treatment, and the complaint came back in exactly those words: *"the
  trees look like they are hanging in the air."* `ArtDraw.contact_shadow()`
  is now the one brush, used by every tree, conifer, rock, shrub, roadside
  stop and milestone. A shape whose body simply stops on a flat gradient
  has no ground; the ellipse is the ground.
- **A prop's size, haze and base all come from one `depth`, never
  independently.** The tree line used to place every tree on one flat line
  with a random height, so a small tree and a large one stood on the same
  spot and neither read as nearer than the other. One `depth` in 0..1 now
  drives base y, height and how far the colour fades into the haze — that
  is the whole of the perspective.
- **Anything standing on a ridge must read the ridge's *drawn* edge.**
  `ArtDraw.ridge()` samples its sine every `_ridge_step` and draws
  straight lines between the samples, so the real silhouette is that
  polyline, not the sine. A base computed from the continuous sine leaves
  the prop hanging at a crest and buried in a trough — half of the
  floating-trees bug. `ArtDraw.ridge_y()` reads the same polyline, and
  `ridge()`/`ridge_snow()` build their polygons through `ridge_points()`/
  `snow_runs()` precisely so `tests/test_art_geometry.gd` can assert the
  two agree; a polygon already drawn onto a canvas cannot be read back.
  Verified by mutation: computing `ridge_y` from the sine fails 590
  assertions.
- **Draw order below the horizon is depth order, and the road is last.**
  Sky → ridges → lake → distant cities → ground fill → tree line →
  roadside stops → near props → road. The tree line used to be drawn
  *before* the ground, so every trunk's foot was painted over by the
  ground gradient and the tree ended behind the grass rather than on it.
  The road going last is what makes a shrub at the verge disappear behind
  it correctly — which also means the near props' range has to stop above
  the verge, or that whole strip renders empty.
- **Snow is a region, not an outline.** Drawing the same ridge twice at
  slightly different amplitudes left a thin white line along the peaks —
  a pencil stroke, not snow. `ArtDraw.ridge_snow()` fills only the parts
  above a snow line, as separate polygons, so low hills stay bare and the
  high one really is capped; its lower hem carries a short-wavelength
  wobble because a dead-straight cut reads as a white triangle glued on.
- **Wavelength and amplitude are read together.** A 54px amplitude on a
  wavelength of 0.16 × width gave the city outskirts rows of grey
  molehills, and a ridge whose troughs fall below the ground line shows
  only its peaks — which is the same molehills by a different route. The
  trough has to clear the ground line for the silhouette to be continuous.
- **Godot's `_draw()` fails silently.** A degenerate polygon prints
  "Invalid polygon data, triangulation failed", skips that shape and carries
  on - invisible without a rendered frame. Do not append a base edge to a
  shape whose arc already closes on it.
- **The frame closes at the bottom, or the eye falls out of it.** The
  strip below the road used to be the road's own light tone, so the
  picture *opened* downward and the caravan never separated from the
  ground. `TravelForeground`'s apron is a near-black earth band, and it
  is a depth rule, not a fill: the nearest strip is the blackest one.
  Which flips the props on it — shrub, stone and mud are now chosen
  **lighter than the apron**, because a dark shrub on dark ground is no
  shrub at all.
- **Flat marks are ground; standing props stand on it.** Puddles and bare
  soil are painted *onto* the earth and may merge freely — two puddles
  running together is what puddles do. A shrub and a stone are volume:
  two in the same place read as one lump. So they are two passes, marks
  first, and the standing pass obeys the column rule — **each prop
  consumes its own width** (`RoadCaravan._walk_column`'s reasoning), the
  next one starts after it, and what does not fit is dropped. Mixed into
  one pass, a puddle got painted over a tuft of grass.
- **Size and density must come from the same measure.** The foreground's
  cell spacing was a fixed 130 world px while prop size was a ratio of
  the band's height. That agreed only at `BAND_HEIGHT`; when the road
  screen went full-frame the band became ~990px, props tripled and the
  spacing did not, so everything piled up. Spacing is derived from the
  prop ceiling now. Whenever one of a pair is a ratio and the other a
  constant, the pair is a bug waiting for a resolution change.
- **Gloom must not delete the hour.** Rain lerped the sky fully to grey,
  so every rainy hour was the same lead-coloured screen. The mix is
  partial and the *horizon* takes the least of it — the light under the
  cloud comes in there, and that warm strip is what holds the scene up.
- **The world's architecture is the world's, not a borrowed one.** The
  distant city was square towers under triangular caps, which is a north
  European keep. Domes and minarets were tried as the fix and
  **reverted**: Wayborne has no such institution, so a place of worship
  on the horizon states something from outside the game's own lore.
  Wayborne's cities grew out of trade — wall, gate, warehouse — and what
  makes the silhouette readable is those blocks being at *different
  heights*, not a symbol. `ArtDraw.city_silhouette` is one brush because
  the main menu's horizon shows the same city.
- **A silhouette is read by the gaps, not the mass.** In flat ink every
  cue that separated two shapes by tone is gone, so shapes that work in
  colour collapse. Measured on `MenuBackdrop` in one pass: a walker whose
  torso reached the ground had its legs drawn *inside* it and read as a
  skittle; a wagon whose canopy was as wide as its bed became a tunnel
  (the canopy is narrower now, so there is a shoulder); a horse's legs
  were a fixed ratio and hung below the contact line, so the rider read
  as a four-legged stool; and the yoked ox pair, at the *road's* own
  offsets, merged into one humped mass — a silhouette needs those
  offsets larger than a tinted drawing does.
- **Every screen stands somewhere, or it is a model on a table.** The
  city was an isometric slab on a flat two-colour gradient: no sky, no
  horizon, no ground, and no shadow under it. On its own it looked
  deliberate; beside a road and a menu that had all four it was plainly
  a different production. `CityView` now draws sky → ridges → field →
  countryside → the town's own contact shadow → the town, which is the
  road's depth order applied to a screen that is not the road. The
  lesson generalises: when one screen gets the treatment, the screens
  that did not are now *wrong*, not merely older — a shared visual
  language is only shared if every screen speaks it.
- **One wagon is drawn by one ox, and that reverses an earlier decision.**
  For a while it was a pair: a single animal reads as a horse's harness,
  not a yoke, and the far ox was pushed back by three marks at once -
  slightly ahead, slightly higher, slightly smaller - because any one or
  two of them alone read as a thick shadow of the near ox rather than a
  second animal. Asked for explicitly, it went back to one - same family
  as the mosque/minaret reversal in this section: a design tried,
  measured, and then undone on its own merits rather than because the
  first attempt was wrong. `RoadCaravan` no longer creates a second,
  shaded figure per wagon at all (`_oxen_far` and its `PAIR_LEAD`/`RISE`/
  `DEPTH`/`SHADE` offsets are gone, not merely hidden), and
  `menu_backdrop.gd`'s independent backlit-caravan silhouette - a second,
  separate implementation of the same pair, because a silhouette can't
  share a `WalkFigure` with the road - got the same edit for the same
  reason `ArtPalette`/`ArtDraw` exist: two places drawing the same
  caravan have to agree, or the game looks like two productions again.
  The column's measurements already came from the near ox only, so
  `get_ox_centres()` (one centre per wagon) needed no change at all.
- **Lessons kept from the deleted menu backdrop (full history: `docs/history/CLAUDE_ARSIV.md`).** A road and the
  caravan on it must travel in the same direction, or neither reads as a road. Measuring a formation and placing it are
  one function. The leader of a moving column is drawn at its leading edge. Loop a moving formation by wrapping it
  fully off-screen rather than fading it.

**Structural tests verify layout; they never verify appearance.** That is
what the screenshot tools are for - see Testing.

### Rendered Road Rules

Yolun manzarası (Faz 27) kasabalarla aynı hattan render ediliyor ve düzeni
Oregon Trail'den (2021) uyarlandı, paleti kasvetli: alçak kamera, yol
ekranın ortasında (`TravelBand.RENDERED_ROAD_RATIO` 0.72), önde kameraya
yakın koyu ve bulanık bir ot tarlası, arkada diz boyu ot ve prosedürel
ağaçlar, uzakta puslu sırtlar. Ayrıntı ve görüntüler
`docs/ui/REDESIGN.md` §2b'de.

- **Dört katman, biyom başına, tek kapı: `RoadStrips`.** `far`/`mid`/
  `ground` `TravelBand`'de, `fore` `TravelForeground`'da çiziliyor;
  `tools/ui_scenes/road_scene.py` (Blender) + `road_post.py` üretiyor,
  çıktı `data/assets/ui/road/<biyom>/`. Bir biyomun dört katmanı yoksa
  şerit eski prosedürel çizime düşer (`RoadStrips.has_biome`) - yarım bir
  set prosedürelle karışırsa iki prodüksiyon görünür.
- **Dikişsiz olmak bir kural, bir sonuç değil.** Sahne x'te periyotlu,
  doku tekrarı şeride tam sayı kez sığıyor, kar gürültüsü x'i bir çembere
  sarıp okuyor, mürekkep türevi ve bulanıklık yatayda sarmalı. Kar
  gürültüsünün düz dünya koordinatından okunduğu ilk sürüm her döşemede
  dikey bir dikiş bıraktı; `test_grim_ui` zeminin iki kenarını
  karşılaştırıyor.
- **Bağlantı noktaları render'ın kendisinden.** `RoadStrips.SPEC` (alttan
  piksel) `road_scene.py`'nin `LAYERS`'ından türüyor ve test her biyomun
  `layout.json`'ıyla karşılaştırıyor; kırpma yalnızca üstten yapıldığı
  için alttan ölçü değişmez.
- **Resim nötr gün ışığında; saat ve hava sistemin kendisi.** Katmanlar
  `_light` ile çarpılıyor, kapalı hava griye çekiyor; pus (uzak sırt ve
  ağaç hattı) ve yolun tozu oyunda gökyüzünün ve ışığın renginden
  çiziliyor, resme gömülmüyor. Gökyüzü, güneş/ay, uzak şehirler ve yol
  durakları prosedürel kalıyor.
- **Mürekkep yalnızca kervanın düzleminde.** Uzak katman mürekkepsiz ve
  bulanık, ön tarla koyu ve bulanık: derinlik pustan ve alan
  derinliğinden geliyor, göz yola düşüyor.
- **Işık taslağın ışığı (12.2e, y_122e_yol_isik.png).** Güneş ve ay disk değil: üç Gauss katmanı (geniş hale, orta
  hale, küçük çekirdek) `ArtDraw.radial_glow` ile - `light_pool`'un üst üste binen halkaları geniş bir halede saydamlığı
  biriktirip opak bir disk çiziyordu (ölçüldü). Bulutlar güneşe bakan kenarı ufuk bandının ışığını alan yumuşak
  elipsler, ufukta bütün genişlikte bir ışık bandı, uzak sırtla ağaç hattı arasında ayrı bir sis şeridi; uzak ve orta
  katman soğuk (`COOL_GRADE`), ön sıcak (`WARM_GRADE`). Gece evrenin son üçte birine kadar gece kalıyor (düz karışımla
  gece yarısı yarı şafaktı) ve kervanın feneri yolda sıcak bir daire bırakıyor. `tests/screenshot_road_light.gd`
  taslağın 4 evre × 3 biyom tablosunu basıyor.
- **Aynı biyom haritada nerede olduğuna göre görünür (görev Y-G07, kullanıcı kararı 2026-10-21).** Kuzeyde soğuk
  (karlı zemin, ladin, karlı sırtlar), güneyde sıcak (kuru ot, seyrek ağaç, bol taş), dağa yakın parçanın ufkunda dağ.
  Haritadan ölçülüyor ve `settlements.json`'da her parçanın `climate`/`peaks` alanı (`build_settlements.py
  --annotate`: ortalama y < 5600 soğuk, > 12400 sıcak; dağ maskesine 100 px'ten yakınsa ufukta dağ, dağ biyomu hariç).
  `--annotate` yalnızca bu alanları yazar: bütün üretimi yeniden koşmak bir yolun güzergâhını oynatıyordu.
  `RouteTerrain.look_of` görünüşü kurar ("forest_cold_peaks"), `RoadStrips.texture` katman başına bir alttakine düşer
  (biyom_iklim_peaks -> biyom_iklim -> biyom_peaks -> biyom): ufukta dağ yalnızca uzak katmandır. Varyant
  `road_scene.py --variant` ile biyomun kendi tohumundan render edilir, yani ağaçlar ve tepeler aynı yerde kalır.
  `tests/screenshot_road_looks.gd` 6 biyom x 4 görünüş tablosunu basıyor.
- **Biyom geçişi rengin geçişiyle aynı oranda**
  (`RouteTerrain.biome_blend_at`); zemin opak olduğu için eskisi tam,
  yenisi üstünde beliriyor, saydam katmanlarda eskisi de sönüyor.

### Prop Rules

Vagon, kapı, değirmen, binalar, kamp, silahlar: dünyanın prosedürel çizilen
nesneleri artık figürlerle **aynı hattan** gelen render'lar - aynı güneş, aynı
dört ton, gölge × albedo. Kaynaklar CC0 paketler (Quaternius, Kenney,
KayKit; `art_source/models/props/LICENSES.md`).

- **Tek kapı: `PropArt`** (`scripts/ui/prop_art.gd`). Paket
  `data/assets/props/<id>/<katman>.png` + `props.tres` (`PropSheet`: ppm,
  katman konumları ve milleri, metre boyu). Konumlar eşyanın yere bastığı
  orta noktaya göre; ölçek çağıranın: `k = (oyun pikseli/metre) / ppm`. Bir
  eşyanın resmi yoksa `has()` yanlış döner ve çağıran prosedürel çizimine
  düşer - Wardrobe'un "sanat parça parça gelebilir" kuralı.
- **Döndürme ve eğme köşeleri hesaplanmış bir çokgenle, `draw_set_transform`
  ile değil.** RoadCaravan dönüş aynalaması için kendi dönüşümünü kuruyor ve
  tuvalin o anki dönüşümü okunamıyor; üstüne yazmak onu bozardı.
- **Hareket eden her parça kendi katmanı.** Tekerlek döner (`wheel`,
  `wheel_front` - ön tekerlek küçük, yarıçap oranıyla daha hızlı), branda
  salınır (`canopy`, tabanı sabit eğme), değirmen kanadı döner (`blades`),
  kapı kanadı lider yaklaşınca kalkar (`gate`, duvarın arkasında çizilir).
  Bir katman render edilirken diğerleri kameraya görünmez ama gölge düşürür.
- **Brandalı vagon sıfırdan kuruldu, `ArtDraw.wagon`'un oranlarıyla**
  (`tools/figure_pipeline/props/wagon_builder.py`): h = 1.6 m, tekerlek
  0.34h, tekerlekler ±0.30w, branda tepesi ~1.24h. Aynı `base`/`h` aynı
  kutuya düşüyor; kolon, koşum oku ve arabacı koltuğu hiçbir sayı
  değişmeden yerinde kaldı. `test_props.gd` kutuyu kilitliyor. Paketlerde
  hazır brandalı vagon yoktu; MegaKit'in arabası tek akslı ve gevşek
  parçalı. Yarım vagon (eşek arabası) aynı kurucudan.
- **Ölçek gerçek boy.** Model `size` (metre) ya da paketin kendi birimi ×
  katsayı (Medieval Village ×2.3, Modular ×2.9 - insan boyuna göre ölçüldü)
  ile oturtuluyor; yolda kişi ~0.094 × şerit / 1.73 m, hub'da ~36 px/m.
  Şehir haritasında **bütün binalar tek ölçekte** (bir karo `TILE_METRES`
  5 m): ilk sürüm her binayı ayak izinin genişliğine sığdırdı ve dar-uzun
  lonca kulesi devleşip pazarı örttü.
- **Silahlar dik render edildi, sap altta.** `PropArt.draw_between` resmi
  sap ucundan uca gerer; `WalkFigure.WEAPON_PROPS` aileyi silaha ve
  tutuşa (sapın payı) bağlıyor. Yay (kiriş çekiliyor) ve asa prosedürel.
- **Modüler paketin malzemeleri düğümsüz** (`diffuse_color` beyaz); taş/
  ahşap tonları `props.json`'daki `tints` kurallarıyla veriliyor. Kenney
  modelleri `Textures/colormap.png`'yi göreli yoldan arıyor - doku dosyası
  modelin yanında durmalı.
- **Kenney/Quaternius sahnesinde ibadet yeri yok** (Art Rules): kilise
  izometrik haritada bir çan kulesi.
- Ekran görüntüsü: `tests/screenshot_hub_scene.gd` gerçek `world_hub`'ı
  açıyor (kapı, yerleşim, araba); `screenshot_hub.gd` sahneyi elle kurduğu
  için bunları göstermez.
