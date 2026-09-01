class_name Item
extends Resource

@export var item_id: String = ""
@export var item_name: String = ""
@export var description: String = ""
@export var base_price: int = 0
@export var stack_size: int = 99
## Vagon kargo kapasitesi bu birimle ölçülür (bkz. GameSession.CARGO_PER_WAGON).
@export var unit_weight: float = 1.0
