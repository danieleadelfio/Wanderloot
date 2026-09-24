extends GdUnitTestSuite
## Caselle del loot e del baule: icona, bordo e tooltip per oggetti e materiali.


func test_item_and_material_tiles() -> void:
	var item := ItemInstance.new(load("res://data/equipment/gel_ring.tres"), 4)
	var tile: ItemTile = auto_free(ItemTile.for_item(item))
	assert_object(tile.icon).is_not_null()
	assert_str(tile.tooltip_text).contains(ItemText.title(item))
	var gel: MaterialData = load("res://data/materials/slime_gel.tres")
	var stack: ItemTile = auto_free(ItemTile.for_material(gel, 12))
	assert_int(stack.amount).is_equal(12)
	assert_object(stack.item_material).is_same(gel)
	assert_str(stack.tooltip_text).contains("12")


func test_loot_view_lists_everything() -> void:
	var screen: RunEndScreen = auto_free(load("res://scenes/ui/RunEndScreen/RunEndScreen.tscn").instantiate())
	add_child(screen)
	var items: Array[ItemInstance] = []
	for i in 20:
		items.append(ItemInstance.new(load("res://data/equipment/gel_wand.tres"), i % 5))
	screen.present(true, 5, 100.0, 50, 30, 30, items, {&"slime_gel": 10, &"slime_core": 2})
	screen._show_loot()
	assert_int(screen.get_node("%LootGrid").get_child_count()).is_equal(22)
