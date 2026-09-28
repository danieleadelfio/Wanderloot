extends GdUnitTestSuite
## Bag of Resources (M13, #86): sacchetti chiusi nel loot di run, a casa solo con l'estrazione,
## salvati (v6, compatibile con v5), aperti nella piazza con contenuto tirato all'apertura.

const TEST_PATH: String = "user://test_meta_progression_bags.cfg"

var _meta: Node


func before_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	_meta = auto_free(preload("res://autoload/meta_progression.gd").new())
	_meta.save_path = TEST_PATH


func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_bags_go_home_only_with_extraction() -> void:
	var loot := LootRunInventory.new()
	loot.add_bags(2)
	assert_int(loot.total()).is_equal(2)
	LootTransfer.resolve(false, loot, _meta.deposit_run_loot, _meta.deposit_run_items, _meta.deposit_run_bags)
	assert_int(_meta.bags).is_equal(0)
	assert_bool(loot.is_empty()).is_true()
	loot.add_bags(3)
	LootTransfer.resolve(true, loot, _meta.deposit_run_loot, _meta.deposit_run_items, _meta.deposit_run_bags)
	assert_int(_meta.bags).is_equal(3)


func test_open_bag_adds_materials_and_consumes_one() -> void:
	_meta.deposit_run_bags(2)
	var content: Dictionary = _meta.open_bag()
	assert_int(content.size()).is_equal(1)
	var id: StringName = content.keys()[0]
	assert_int(content[id]).is_equal(_meta.resource_bag.amount_per_bag)
	assert_int(_meta.inventory.to_dictionary().get(id, 0)).is_equal(_meta.resource_bag.amount_per_bag)
	assert_int(_meta.bags).is_equal(1)
	assert_bool(_meta.has_unsaved_changes).is_true()


func test_open_bag_without_bags_does_nothing() -> void:
	assert_dict(_meta.open_bag()).is_empty()
	assert_bool(_meta.inventory.to_dictionary().is_empty()).is_true()


func test_bags_are_saved_and_reloaded() -> void:
	_meta.deposit_run_bags(4)
	assert_int(_meta.save_to_disk()).is_equal(OK)
	_meta.bags = 0
	_meta.load_from_disk()
	assert_int(_meta.bags).is_equal(4)


## Salvataggio v5 (prima dei sacchetti): nessun sacchetto, il resto si carica.
func test_v5_save_loads_without_bags() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", 5)
	config.set_value("materials", "slime_gel", 7)
	config.save(TEST_PATH)
	_meta.bags = 9
	assert_int(_meta.load_from_disk()).is_equal(OK)
	assert_int(_meta.bags).is_equal(0)
	assert_int(_meta.inventory.to_dictionary().get(&"slime_gel", 0)).is_equal(7)


func test_new_game_clears_bags() -> void:
	_meta.deposit_run_bags(1)
	_meta.new_game()
	assert_int(_meta.bags).is_equal(0)
