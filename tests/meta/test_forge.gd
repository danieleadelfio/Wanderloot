extends GdUnitTestSuite
## Fusione (due identici -> rarita' successiva, fino a Leggendario) e smontaggio (resa per rarita').

const RARITIES: RarityTable = preload("res://data/equipment/rarity_table.tres")
const RECIPES: RecipeBook = preload("res://data/recipes/recipe_book.tres")

var _loadout: EquipmentLoadout
var _wand: EquipmentData
var _boots: EquipmentData


func before_test() -> void:
	_loadout = EquipmentLoadout.new()
	_wand = load("res://data/equipment/gel_wand.tres")
	_boots = load("res://data/equipment/slime_boots.tres")


func test_two_identical_items_fuse_into_next_rarity() -> void:
	var a := _add(_wand, 0)
	var b := _add(_wand, 0)
	assert_int(Forge.fusion_groups(_loadout, RARITIES).size()).is_equal(1)
	var fused := Forge.fuse(a, b, _loadout, RARITIES, _make)
	assert_object(fused).is_not_null()
	assert_int(fused.rarity).is_equal(1)
	assert_int(_loadout.count_of(&"gel_wand")).is_equal(1)
	assert_object(_loadout.get_item(a.uid)).is_null()


func test_different_rarity_or_base_does_not_fuse() -> void:
	var a := _add(_wand, 0)
	var b := _add(_wand, 1)
	var c := _add(_boots, 0)
	assert_bool(Forge.can_fuse(a, b, _loadout, RARITIES)).is_false()
	assert_bool(Forge.can_fuse(a, c, _loadout, RARITIES)).is_false()
	assert_bool(Forge.can_fuse(a, a, _loadout, RARITIES)).is_false()
	assert_bool(Forge.fusion_groups(_loadout, RARITIES).is_empty()).is_true()


func test_legendary_and_equipped_items_do_not_fuse() -> void:
	var top := Forge.max_fusion_tier(RARITIES)
	var a := _add(_wand, top)
	var b := _add(_wand, top)
	assert_bool(Forge.can_fuse(a, b, _loadout, RARITIES)).is_false()
	var c := _add(_boots, 0)
	var d := _add(_boots, 0)
	_loadout.equip(c.uid)
	assert_bool(Forge.can_fuse(c, d, _loadout, RARITIES)).is_false()
	assert_object(Forge.fuse(c, d, _loadout, RARITIES, _make)).is_null()


func test_salvage_yield_grows_with_rarity() -> void:
	var common := Forge.salvage_yield(ItemInstance.new(_wand, 0), RECIPES, RARITIES)
	var legendary := Forge.salvage_yield(ItemInstance.new(_wand, 4), RECIPES, RARITIES)
	assert_int(common[&"slime_gel"]).is_greater(0)
	assert_int(legendary[&"slime_gel"]).is_greater(common[&"slime_gel"])


func test_salvage_removes_item_and_deposits_materials() -> void:
	var inventory := MetaInventory.new()
	var item := _add(_wand, 2)
	var amounts := Forge.salvage_yield(item, RECIPES, RARITIES)
	assert_bool(Forge.salvage(item, _loadout, inventory, amounts)).is_true()
	assert_object(_loadout.get_item(item.uid)).is_null()
	assert_int(inventory.amount_of(&"slime_gel")).is_equal(amounts[&"slime_gel"])


func test_equipped_item_is_not_salvaged() -> void:
	var inventory := MetaInventory.new()
	var item := _add(_wand, 0)
	_loadout.equip(item.uid)
	assert_bool(Forge.salvage(item, _loadout, inventory, {&"slime_gel": 1} as Dictionary[StringName, int])).is_false()
	assert_object(_loadout.get_item(item.uid)).is_not_null()


func _add(base: EquipmentData, tier: int) -> ItemInstance:
	return _loadout.add(ItemInstance.new(base, tier))


func _make(base: EquipmentData, tier: int) -> ItemInstance:
	return ItemInstance.new(base, tier)
