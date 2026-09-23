extends GdUnitTestSuite


func test_roll_respects_chance_bounds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var never := _entry(0.0, 1, 1)
	var always := _entry(1.0, 2, 4)
	for i in 200:
		assert_int(never.roll(rng)).is_equal(0)
		assert_int(always.roll(rng)).is_between(2, 4)


func test_roll_without_material_is_zero() -> void:
	var entry := _entry(1.0, 1, 1)
	entry.material = null
	assert_int(entry.roll(RandomNumberGenerator.new())).is_equal(0)


func _entry(chance: float, min_amount: int, max_amount: int) -> DropEntry:
	var entry := DropEntry.new()
	entry.material = MaterialData.new()
	entry.chance = chance
	entry.min_amount = min_amount
	entry.max_amount = max_amount
	return entry
