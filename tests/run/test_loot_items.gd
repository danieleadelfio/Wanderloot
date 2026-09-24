extends GdUnitTestSuite
## Oggetti trovati in run: a rischio come i materiali, nel baule solo con l'estrazione.


func test_items_are_deposited_only_when_extracted() -> void:
	var run_loot := LootRunInventory.new()
	run_loot.add_item(_item())
	var deposited: Array = []
	var moved := LootTransfer.resolve(true, run_loot, func(_loot: Dictionary) -> void: pass, func(items: Array[ItemInstance]) -> void: deposited.append_array(items))
	assert_int(moved).is_equal(1)
	assert_int(deposited.size()).is_equal(1)
	assert_bool(run_loot.is_empty()).is_true()

	run_loot.add_item(_item())
	deposited.clear()
	var lost := LootTransfer.resolve(false, run_loot, func(_loot: Dictionary) -> void: pass, func(items: Array[ItemInstance]) -> void: deposited.append_array(items))
	assert_int(lost).is_equal(1)
	assert_bool(deposited.is_empty()).is_true()
	assert_int(run_loot.items().size()).is_equal(0)


func test_materials_deposit_is_skipped_when_only_items() -> void:
	var run_loot := LootRunInventory.new()
	run_loot.add_item(_item())
	var calls := [0]
	LootTransfer.resolve(true, run_loot, func(_loot: Dictionary) -> void: calls[0] += 1, func(_items: Array[ItemInstance]) -> void: pass)
	assert_int(calls[0]).is_equal(0)


func test_deposited_items_get_unique_uids() -> void:
	var loadout := EquipmentLoadout.new()
	var first := loadout.add(_item())
	var second := loadout.add(_item())
	assert_int(first.uid).is_not_equal(second.uid)
	assert_int(loadout.count_of(&"gel_wand")).is_equal(2)


func _item() -> ItemInstance:
	return ItemInstance.new(load("res://data/equipment/gel_wand.tres"), 1)
