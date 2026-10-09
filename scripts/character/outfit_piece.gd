class_name OutfitPiece
extends Resource

## Bir giysi: görünüşü (`art_id` - beden başına bir kare kümesi, bkz.
## OutfitCatalog.frames_id; `color` - kare kümesi olmayan çizimlerin
## taşıdığı ton) ve küçük bir savaş katkısı. Bonus alanları `Trait`'in ve
## `Equipment`'ın alanlarıyla aynı adda, aynı `CharacterData` sarmalayıcıları
## okuyor - savaş giyileni `CombatUnit.from_character` üstünden kendiliğinden
## görüyor. Görseli henüz render edilmemiş bir giysi (`art_id` boş) de
## giyilebilir; figür onu kendi rengiyle taşır.

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

## Kırk-elli parçalık bir zırhın yanında küçük: bir giysi kat kattır, bir
## korucu takımının hepsi bir zırh kademesine yakın durur (bkz. OutfitCatalog).
@export var hp_bonus: int = 0
@export var dodge_bonus: int = 0
@export var accuracy_bonus: int = 0
@export var crit_bonus: int = 0
@export var damage_bonus: int = 0
## Terzide satış fiyatı: kumaşın ve işçiliğin tabanı + verdiği her statın
## değeri (OutfitCatalog.price_for) - fiyat statla büyüyor, hepsi aynı formül.
@export var price: int = 0
## Karakter oluşturmada seçilebilir mi - yalnızca köylü takımı. Daha iyisi
## para ister; bedava seçilebilseydi terzi anlamsızlaşırdı.
@export var starter: bool = false

var display_name: String:
	get: return tr(display_name_key)
