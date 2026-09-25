extends GdUnitTestSuite
## Scoperta equip (M12, #86): un pezzo conta come "scoperto" solo dopo un'estrazione riuscita con
## quel pezzo nel loot, mai al semplice pickup o crafting. Usata da undiscovered_equipment() per
## proporre solo pezzi mai visti nell'evento Scheletri nell'armadio.

const TEST_PATH: String = "user://test_meta_progression_discovery.cfg"

var _meta: Node


func before_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	_meta = auto_free(preload("res://autoload/meta_progression.gd").new())
	_meta.save_path = TEST_PATH


func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_new_equipment_is_undiscovered() -> void:
	assert_bool(_meta.is_discovered(&"gel_wand")).is_false()
	assert_array(_meta.undiscovered_equipment()).contains([load("res://data/equipment/gel_wand.tres")])


func test_deposit_run_items_marks_discovered() -> void:
	var item := ItemInstance.new(load("res://data/equipment/gel_wand.tres"))
	_meta.deposit_run_items([item] as Array[ItemInstance])
	assert_bool(_meta.is_discovered(&"gel_wand")).is_true()
	assert_array(_meta.undiscovered_equipment()).not_contains([load("res://data/equipment/gel_wand.tres")])


func test_crafting_without_extraction_does_not_discover() -> void:
	# Il crafting aggiunge direttamente al loadout (loadout.add), non passa da deposit_run_items:
	# solo l'estrazione riuscita marca come scoperto.
	_meta.deposit_run_loot({&"slime_gel": 30} as Dictionary[StringName, int])
	_meta.craft(load("res://data/recipes/gel_wand.tres"))
	assert_bool(_meta.is_discovered(&"gel_wand")).is_false()


func test_discovery_is_saved_and_reloaded() -> void:
	var item := ItemInstance.new(load("res://data/equipment/core_amulet.tres"))
	_meta.deposit_run_items([item] as Array[ItemInstance])
	_meta.save_game()

	var reloaded: Node = auto_free(preload("res://autoload/meta_progression.gd").new())
	reloaded.save_path = TEST_PATH
	reloaded.load_from_disk()

	assert_bool(reloaded.is_discovered(&"core_amulet")).is_true()
	assert_bool(reloaded.is_discovered(&"gel_wand")).is_false()


func test_new_game_clears_discovery() -> void:
	var item := ItemInstance.new(load("res://data/equipment/gel_wand.tres"))
	_meta.deposit_run_items([item] as Array[ItemInstance])
	_meta.new_game()
	assert_bool(_meta.is_discovered(&"gel_wand")).is_false()
