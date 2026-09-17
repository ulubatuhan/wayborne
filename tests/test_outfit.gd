extends RefCounted

## Kıyafet sistemi: OutfitCatalog'un çözümleyicileri (WalkFigure/CombatFigure/
## OutfitPreview'in üçünün de okuduğu tek mantık) ve kıyafetin karakterden
## savaş birimine doğru taşınması. Bkz. CLAUDE.md Kervan Envanteri Rules'un
## yanındaki "kıyafet sisteminin kapsamı" notu - bu paket o notun kapattığı
## boşluğu (figürler outfit'e hiç bakmıyordu) kilitliyor.

func suite_name() -> String:
	return "Outfit"

func run(t) -> void:
	_test_resolve_color_falls_back_when_empty(t)
	_test_resolve_color_returns_piece_color(t)
	_test_resolve_torso_color_jacket_overrides_shirt(t)
	_test_resolve_torso_color_shirt_alone(t)
	_test_resolve_headgear_no_hat_means_no_override(t)
	_test_resolve_headgear_hat_overrides_shape_and_color(t)
	_test_unknown_piece_id_falls_back(t)
	_test_combat_unit_carries_outfit_from_character(t)
	_test_enemy_units_have_no_outfit(t)
	_test_figures_accept_outfit_without_error(t)

func _test_resolve_color_falls_back_when_empty(t) -> void:
	var fallback := Color(0.1, 0.2, 0.3)
	var result := OutfitCatalog.resolve_color({}, OutfitCatalog.SLOT_PANTS, fallback)
	t.eq(result, fallback, "boş outfit sözlüğü hep fallback'e düşer")

func _test_resolve_color_returns_piece_color(t) -> void:
	var outfit := {OutfitCatalog.SLOT_PANTS: "pants_wool"}
	var piece := OutfitCatalog.get_piece("pants_wool")
	var result := OutfitCatalog.resolve_color(outfit, OutfitCatalog.SLOT_PANTS, Color.BLACK)
	t.eq(result, piece.color, "seçili parçanın kendi rengi dönmeli")

func _test_resolve_torso_color_jacket_overrides_shirt(t) -> void:
	var outfit := {
		OutfitCatalog.SLOT_SHIRT: "shirt_linen",
		OutfitCatalog.SLOT_JACKET: "jacket_leather",
	}
	var jacket := OutfitCatalog.get_piece("jacket_leather")
	var result := OutfitCatalog.resolve_torso_color(outfit, Color.BLACK)
	t.eq(result, jacket.color, "ceket varken gömleğin üstünü kapatır")

func _test_resolve_torso_color_shirt_alone(t) -> void:
	var outfit := {OutfitCatalog.SLOT_SHIRT: "shirt_dyed"}
	var shirt := OutfitCatalog.get_piece("shirt_dyed")
	var result := OutfitCatalog.resolve_torso_color(outfit, Color.BLACK)
	t.eq(result, shirt.color, "ceket yoksa gömlek rengi kullanılır")

## Sistemin en önemli garantisi: kıyafetsiz bir karakter (tayfa, düşman,
## kıyafet seçmemiş oyuncu) bu sistem hiç var olmadan önceki gibi çiziliyor
## olmalı - `override` bu yüzden false döner, çağıran `color` alanına hiç
## bakmamalı.
func _test_resolve_headgear_no_hat_means_no_override(t) -> void:
	var result := OutfitCatalog.resolve_headgear({}, "helmet")
	t.not_ok(bool(result.override), "şapka seçilmemişken override olmamalı")
	t.eq(String(result.kind), "helmet", "fallback kafa şekli aynen dönmeli")

func _test_resolve_headgear_hat_overrides_shape_and_color(t) -> void:
	var outfit := {OutfitCatalog.SLOT_HAT: "hat_hood"}
	var piece := OutfitCatalog.get_piece("hat_hood")
	var result := OutfitCatalog.resolve_headgear(outfit, "helmet")
	t.ok(bool(result.override), "kukulete seçiliyken override true olmalı")
	t.eq(String(result.kind), "hood", "kukulete WalkFigure/CombatFigure'ın 'hood' şeklini kullanmalı")
	t.eq(result.color, piece.color, "kafanın rengi kukuletenin kendi rengi olmalı")

func _test_unknown_piece_id_falls_back(t) -> void:
	var outfit := {OutfitCatalog.SLOT_SHOES: "shoes_nonexistent"}
	var fallback := Color(0.4, 0.4, 0.4)
	var result := OutfitCatalog.resolve_color(outfit, OutfitCatalog.SLOT_SHOES, fallback)
	t.eq(result, fallback, "bozuk/tanınmayan bir piece_id fallback'e düşer")

func _test_combat_unit_carries_outfit_from_character(t) -> void:
	var character := CharacterData.create(
		"Test", CultureCatalog.NOMAD, CharacterStats.new(),
		CharacterData.DEFAULT_HEIGHT_CM, 0, ClassCatalog.GUARD
	)
	character.set_outfit_piece(OutfitCatalog.SLOT_JACKET, "jacket_wool")
	var unit := CombatUnit.from_character(character, 1)
	t.eq(unit.outfit, character.outfit, "CombatUnit karakterin outfit'ini aynen taşımalı")
	t.ok(
		unit.outfit.get(OutfitCatalog.SLOT_JACKET, "") == "jacket_wool",
		"taşınan sözlükte seçilen parça gerçekten var"
	)

func _test_enemy_units_have_no_outfit(t) -> void:
	var template := EnemyCatalog.get_enemy(EnemyCatalog.CUTTER)
	var unit := CombatUnit.from_enemy(template, 1)
	t.eq(unit.outfit, {}, "düşmanın hiç kıyafeti yok - kendi arketip paletinde kalır")

## Yapısal: yeni `outfit` parametresi geriye dönük uyumlu (varsayılanı boş
## sözlük) ve figürler bir outfit verildiğinde hatasız çiziyor. Görünümü
## bir assertion değil, screenshot araçları doğrular (bkz. CLAUDE.md
## Testing bölümü) - burada yalnızca API'nin çökmediğini kilitliyoruz.
func _test_figures_accept_outfit_without_error(t) -> void:
	var walk := WalkFigure.new()
	walk.size = Vector2(80, 160)
	walk.set_kind(
		WalkFigure.KIND_PERSON, "guard", 1.0, Color(0.7, 0.5, 0.4), false,
		{OutfitCatalog.SLOT_HAT: "hat_felt", OutfitCatalog.SLOT_PANTS: "pants_canvas"}
	)
	t.ok(true, "WalkFigure.set_kind() outfit ile çağrılabiliyor")
	walk.free()

	var combat := CombatFigure.new()
	combat.size = Vector2(120, 200)
	combat.setup(
		"guard", true, "normal", 0.0,
		{OutfitCatalog.SLOT_JACKET: "jacket_leather", OutfitCatalog.SLOT_HAT: "hat_hood"}
	)
	t.ok(true, "CombatFigure.setup() outfit ile çağrılabiliyor")
	combat.free()
