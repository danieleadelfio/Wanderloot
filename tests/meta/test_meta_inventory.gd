extends GdUnitTestSuite


func test_deposit_accumulates_and_ignores_non_positive() -> void:
	var meta := MetaInventory.new()
	meta.deposit({&"gel": 2, &"core": 0} as Dictionary[StringName, int])
	meta.deposit({&"gel": 3, &"bone": -1} as Dictionary[StringName, int])
	assert_int(meta.amount_of(&"gel")).is_equal(5)
	assert_int(meta.amount_of(&"core")).is_equal(0)
	assert_int(meta.amount_of(&"bone")).is_equal(0)
	assert_int(meta.total()).is_equal(5)


func test_spend_is_all_or_nothing_and_removes_empty_entries() -> void:
	var inventory := MetaInventory.new()
	inventory.deposit({&"gel": 5, &"core": 1} as Dictionary[StringName, int])

	assert_bool(inventory.spend({&"gel": 3, &"core": 2} as Dictionary[StringName, int])).is_false()
	assert_int(inventory.amount_of(&"gel")).is_equal(5)
	assert_bool(inventory.spend({&"gel": 3, &"core": 1} as Dictionary[StringName, int])).is_true()
	assert_int(inventory.amount_of(&"gel")).is_equal(2)
	assert_bool(inventory.to_dictionary().has(&"core")).is_false()


func test_load_dictionary_replaces_content() -> void:
	var meta := MetaInventory.new()
	meta.deposit({&"gel": 9} as Dictionary[StringName, int])
	meta.load_dictionary({&"core": 1} as Dictionary[StringName, int])
	assert_int(meta.amount_of(&"gel")).is_equal(0)
	assert_int(meta.amount_of(&"core")).is_equal(1)
