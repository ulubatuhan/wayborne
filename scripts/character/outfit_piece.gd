class_name OutfitPiece
extends Resource

## Kıyafet sistemi tamamen dış görünüm için - hiçbir stat/mekanik bonusu
## yok (bkz. CLAUDE.md Faz 13 hazırlık notu #14). `color` şimdilik önizleme
## penceresinin tek görsel kaynağı; gerçek doku/sprite gelince bu alanın
## yerini alacak (bkz. Art Rules'un ColorRect -> _draw() -> doku geçişi).

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

var display_name: String:
	get: return tr(display_name_key)
