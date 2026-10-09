class_name OutfitPiece
extends Resource

## Kıyafet sistemi tamamen dış görünüm için - hiçbir stat/mekanik bonusu
## yok (bkz. CLAUDE.md Faz 13 hazırlık notu #14). Parçanın kendisi render
## edilmiş bir giysi (`art_id`, beden başına bir kare kümesi - bkz.
## OutfitCatalog.frames_id); `color` kare kümesi olmayan çizimlerin (savaş
## silüeti, eski parça mankeni) onu taşıdığı ton.

@export var piece_id: String = ""
## OutfitCatalog.SLOT_* değerlerinden biri.
@export var slot: String = ""
@export var display_name_key: String = ""
@export var color: Color = Color.WHITE
## Yalnızca SLOT_HAT parçaları için: WalkFigure/CombatFigure'ın ortak
## "head" vokabülerinden biri ("helmet"/"hood"/"wrap"/"cap"/"bare") - bu
## parça seçiliyken figürün kafasında hangi silüetin çizileceğini
## belirler. Boşsa (diğer beş slot hep böyledir) figür kendi sınıf/düşman
## arketipinin varsayılan kafa şeklini kullanır - bkz.
## OutfitCatalog.resolve_headgear().
@export var head_shape: String = ""

## tools/figure_pipeline/config/outfits.json'daki kalem adı; kare kümeleri
## data/assets/characters/frames/outfit_<art_id>_<beden>/.
@export var art_id: String = ""
## Bindirme sırası, küçük önce (pantolon < ayakkabı < gömlek < yelek <
## başlık). Render'da dış giysi iç giysiyi sarıyor; çizim de aynı sırada.
@export var draw_order: int = 0
## Bileği tutan ayakkabı: yürüyüş `walk_boots` klibine geçer (FigureRig'in
## BOOT_ANKLE_RANGE'i - bileği sert bir yürüyüş).
@export var boots: bool = false

var display_name: String:
	get: return tr(display_name_key)
