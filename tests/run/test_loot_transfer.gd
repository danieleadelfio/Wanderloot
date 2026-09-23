extends GdUnitTestSuite
## La regola piu' delicata del gioco: estrazione = loot trasferito, morte = loot perso.

var _gel: MaterialData
var _core: MaterialData


func before_test() -> void:
	_gel = _material(&"gel")
	_core = _material(&"core")


func test_extraction_transfers_all_loot_and_clears_run_inventory() -> void:
	var run_loot := LootRunInventory.new()
	run_loot.add(_gel, 3)
	run_loot.add(_core, 1)
	var meta := MetaInventory.new()
	meta.deposit({&"gel": 2} as Dictionary[StringName, int])

	var moved := LootTransfer.resolve(true, run_loot, meta.deposit)

	assert_int(moved).is_equal(4)
	assert_int(meta.amount_of(&"gel")).is_equal(5)
	assert_int(meta.amount_of(&"core")).is_equal(1)
	assert_bool(run_loot.is_empty()).is_true()


func test_death_loses_all_loot_and_never_touches_meta() -> void:
	var run_loot := LootRunInventory.new()
	run_loot.add(_gel, 3)
	var deposits: Array = []

	var lost := LootTransfer.resolve(false, run_loot, func(loot: Dictionary) -> void: deposits.append(loot))

	assert_int(lost).is_equal(3)
	assert_array(deposits).is_empty()
	assert_bool(run_loot.is_empty()).is_true()


func test_extraction_with_empty_loot_does_not_deposit() -> void:
	var deposits: Array = []

	var moved := LootTransfer.resolve(true, LootRunInventory.new(), func(loot: Dictionary) -> void: deposits.append(loot))

	assert_int(moved).is_equal(0)
	assert_array(deposits).is_empty()


func _material(id: StringName) -> MaterialData:
	var material := MaterialData.new()
	material.id = id
	return material
