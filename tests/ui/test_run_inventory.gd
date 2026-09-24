extends GdUnitTestSuite
## Inventario di run: manichino senza baule, tutto il raccolto in griglia scorrevole con confronto.


func test_run_inventory_shows_mannequin_and_all_loot() -> void:
	var inventory: RunInventory = auto_free(load("res://scenes/ui/RunInventory/RunInventory.tscn").instantiate())
	add_child(inventory)
	var loadout := EquipmentLoadout.new()
	var worn := loadout.add(ItemInstance.new(load("res://data/equipment/gel_ring.tres"), 2))
	loadout.equip(worn.uid)
	var items: Array[ItemInstance] = []
	for i in 40:
		items.append(ItemInstance.new(load("res://data/equipment/gel_ring.tres"), i % 5))
	inventory.present(loadout, {&"slime_gel": 12} as Dictionary[StringName, int], items)
	var grid: GridContainer = inventory.get_node("%LootGrid")
	assert_int(grid.get_child_count()).is_equal(41)
	assert_bool(inventory.get_node("%Mannequin").get_node("%Stash").visible).is_false()
	var tile: ItemTile = grid.get_child(0)
	assert_int(tile.compare.size()).is_equal(1)
	assert_bool(grid.get_parent() is ScrollContainer).is_true()
