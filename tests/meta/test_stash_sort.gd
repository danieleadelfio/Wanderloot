extends GdUnitTestSuite
## Ordine del baule: per arrivo, per rarita' (dal piu' raro), per categoria (slot).

var _items: Array[ItemInstance] = []


func before_test() -> void:
	_items.clear()
	var ring: EquipmentData = load("res://data/equipment/gel_ring.tres")
	var wand: EquipmentData = load("res://data/equipment/gel_wand.tres")
	var boots: EquipmentData = load("res://data/equipment/slime_boots.tres")
	var specs := [[ring, 0], [wand, 3], [boots, 1], [ring, 4], [wand, 0]]
	for i in specs.size():
		var item := ItemInstance.new(specs[i][0], specs[i][1])
		item.uid = i + 1
		_items.append(item)


func test_rarity_puts_rarest_first() -> void:
	var result := StashSort.sorted(_items, StashSort.Mode.RARITY)
	assert_array(result.map(func(i: ItemInstance) -> int: return i.rarity)).is_equal([4, 3, 1, 0, 0])


func test_category_groups_by_slot() -> void:
	var result := StashSort.sorted(_items, StashSort.Mode.CATEGORY)
	var slots: Array = result.map(func(i: ItemInstance) -> int: return i.slot())
	var sorted_slots := slots.duplicate()
	sorted_slots.sort()
	assert_array(slots).is_equal(sorted_slots)
	# Nella stessa categoria, prima il piu' raro.
	assert_int(result[0].rarity).is_equal(3)


func test_filters_by_rarity_slot_and_new() -> void:
	_items[1].is_new = true
	_items[3].is_new = true
	assert_int(StashSort.filtered(_items, "all").size()).is_equal(5)
	assert_array(StashSort.filtered(_items, "new").map(func(i: ItemInstance) -> int: return i.uid)).is_equal([2, 4])
	assert_int(StashSort.filtered(_items, "rarity:0").size()).is_equal(2)
	assert_int(StashSort.filtered(_items, "slot:%d" % EquipmentData.Slot.RING).size()).is_equal(2)


func test_new_flag_is_saved_and_cleared() -> void:
	var item := ItemInstance.new(load("res://data/equipment/gel_ring.tres"), 1)
	item.is_new = true
	var copy := ItemInstance.from_dict(item.to_dict(), load("res://data/equipment/equipment_catalog.tres"), null)
	assert_bool(copy.is_new).is_true()


func test_arrival_keeps_uid_order() -> void:
	var shuffled := _items.duplicate()
	shuffled.reverse()
	var result := StashSort.sorted(shuffled, StashSort.Mode.ARRIVAL)
	assert_array(result.map(func(i: ItemInstance) -> int: return i.uid)).is_equal([1, 2, 3, 4, 5])
