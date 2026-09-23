extends GdUnitTestSuite


func test_add_accumulates_per_material() -> void:
	var inventory := LootRunInventory.new()
	var gel := _material(&"gel")
	inventory.add(gel, 2)
	inventory.add(gel, 3)
	inventory.add(_material(&"core"), 1)
	assert_int(inventory.amount_of(&"gel")).is_equal(5)
	assert_int(inventory.total()).is_equal(6)


func test_add_ignores_null_and_non_positive_amounts() -> void:
	var inventory := LootRunInventory.new()
	inventory.add(null, 3)
	inventory.add(_material(&"gel"), 0)
	inventory.add(_material(&"gel"), -2)
	assert_bool(inventory.is_empty()).is_true()


func test_to_dictionary_is_a_copy() -> void:
	var inventory := LootRunInventory.new()
	inventory.add(_material(&"gel"), 1)
	var snapshot := inventory.to_dictionary()
	inventory.clear()
	assert_int(snapshot.get(&"gel", 0)).is_equal(1)
	assert_int(inventory.total()).is_equal(0)


func _material(id: StringName) -> MaterialData:
	var material := MaterialData.new()
	material.id = id
	return material
