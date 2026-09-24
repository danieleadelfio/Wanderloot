extends GdUnitTestSuite
## Persistenza su file di test dedicato: il salvataggio reale in user:// non viene mai toccato.
## Da M8 si scrive su disco solo con save_game() (salvataggi manuali).

const TEST_PATH: String = "user://test_meta_progression.cfg"

var _meta: Node


func before_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	_meta = auto_free(preload("res://autoload/meta_progression.gd").new())
	_meta.save_path = TEST_PATH


func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_first_load_without_file_gives_empty_inventory() -> void:
	assert_int(_meta.load_from_disk()).is_equal(ERR_FILE_NOT_FOUND)
	assert_int(_meta.inventory.total()).is_equal(0)


func test_deposit_is_saved_and_reloaded() -> void:
	_meta.deposit_run_loot({&"gel": 4, &"core": 1} as Dictionary[StringName, int])
	_meta.save_game()
	var reloaded: Node = auto_free(preload("res://autoload/meta_progression.gd").new())
	reloaded.save_path = TEST_PATH
	assert_int(reloaded.load_from_disk()).is_equal(OK)
	assert_int(reloaded.inventory.amount_of(&"gel")).is_equal(4)
	assert_int(reloaded.inventory.amount_of(&"core")).is_equal(1)


func test_craft_and_equip_are_saved_and_reloaded() -> void:
	_meta.deposit_run_loot({&"slime_gel": 30} as Dictionary[StringName, int])
	var recipe: RecipeData = load("res://data/recipes/gel_wand.tres")
	assert_int(_meta.craft(recipe)).is_equal(Crafting.Result.OK)
	_meta.equip(recipe.result)
	_meta.save_game()

	var reloaded := _reload()

	assert_int(reloaded.inventory.amount_of(&"slime_gel")).is_equal(30 - recipe.cost_dictionary()[&"slime_gel"])
	assert_bool(reloaded.loadout.owns(&"gel_wand")).is_true()
	assert_str(String(reloaded.loadout.equipped_id(EquipmentData.Slot.WEAPON))).is_equal("gel_wand")
	assert_array(reloaded.equipped_items()).contains([recipe.result])


func test_unequip_is_saved() -> void:
	_meta.loadout.add_owned(&"core_amulet")
	_meta.equip(load("res://data/equipment/core_amulet.tres"))
	_meta.unequip(EquipmentData.Slot.ACCESSORY)
	_meta.save_game()

	assert_array(_reload().equipped_items()).is_empty()


func test_v1_save_loads_materials_with_empty_loadout() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", 1)
	config.set_value("materials", "slime_gel", 7)
	config.save(TEST_PATH)

	var reloaded := _reload()

	assert_int(reloaded.inventory.amount_of(&"slime_gel")).is_equal(7)
	assert_array(reloaded.loadout.owned_ids()).is_empty()


func test_unknown_or_not_owned_equipment_is_discarded_on_load() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", 2)
	config.set_value("equipment", "owned", PackedStringArray(["gel_wand", "removed_item"]))
	config.set_value("equipped", "weapon", "gel_wand")
	config.set_value("equipped", "accessory", "core_amulet")
	config.save(TEST_PATH)

	var reloaded := _reload()

	assert_array(reloaded.loadout.owned_ids()).contains_exactly([&"gel_wand"])
	assert_str(String(reloaded.loadout.equipped_id(EquipmentData.Slot.ACCESSORY))).is_empty()
	assert_str(String(reloaded.loadout.equipped_id(EquipmentData.Slot.WEAPON))).is_equal("gel_wand")


func test_extractions_and_selected_arena_are_saved() -> void:
	_meta.register_extraction(&"crypt")
	_meta.register_extraction(&"crypt")
	assert_bool(_meta.select_arena(&"crypt")).is_true()
	_meta.save_game()
	var reloaded := _reload()
	assert_int(reloaded.extractions.get(&"crypt", 0)).is_equal(2)
	assert_str(String(reloaded.current_arena().id)).is_equal("crypt")


func test_locked_or_unknown_arena_cannot_be_selected() -> void:
	var locked := ArenaData.new()
	locked.id = &"deep"
	locked.unlock_arena = &"crypt"
	locked.unlock_extractions = 2
	var catalog := ArenaCatalog.new()
	catalog.arenas = [load("res://data/arenas/crypt.tres"), locked] as Array[ArenaData]
	_meta.arena_catalog = catalog
	assert_bool(_meta.select_arena(&"deep")).is_false()
	assert_bool(_meta.select_arena(&"nowhere")).is_false()
	_meta.register_extraction(&"crypt")
	_meta.register_extraction(&"crypt")
	assert_bool(_meta.select_arena(&"deep")).is_true()
	assert_str(String(_meta.current_arena().id)).is_equal("deep")


func test_v2_save_loads_with_no_extractions_and_first_arena() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", 2)
	config.set_value("materials", "slime_gel", 3)
	config.save(TEST_PATH)
	var reloaded := _reload()
	assert_int(reloaded.inventory.amount_of(&"slime_gel")).is_equal(3)
	assert_bool(reloaded.extractions.is_empty()).is_true()
	assert_str(String(reloaded.current_arena().id)).is_equal("crypt")


func _reload() -> Node:
	var reloaded: Node = auto_free(preload("res://autoload/meta_progression.gd").new())
	reloaded.save_path = TEST_PATH
	reloaded.load_from_disk()
	return reloaded


func test_changes_are_not_written_until_save() -> void:
	_meta.deposit_run_loot({&"slime_gel": 5} as Dictionary[StringName, int])
	assert_bool(_meta.has_save()).is_false()
	assert_bool(_meta.has_unsaved_changes).is_true()
	assert_int(_meta.save_game()).is_equal(OK)
	assert_bool(_meta.has_save()).is_true()
	assert_bool(_meta.has_unsaved_changes).is_false()


func test_load_game_discards_unsaved_changes() -> void:
	_meta.deposit_run_loot({&"slime_gel": 5} as Dictionary[StringName, int])
	_meta.save_game()
	_meta.deposit_run_loot({&"slime_gel": 7} as Dictionary[StringName, int])
	_meta.register_extraction(&"crypt")
	assert_int(_meta.load_game()).is_equal(OK)
	assert_int(_meta.inventory.amount_of(&"slime_gel")).is_equal(5)
	assert_bool(_meta.extractions.is_empty()).is_true()
	assert_bool(_meta.has_unsaved_changes).is_false()


func test_new_game_resets_memory_but_keeps_file() -> void:
	_meta.deposit_run_loot({&"slime_gel": 30} as Dictionary[StringName, int])
	_meta.craft(load("res://data/recipes/gel_wand.tres"))
	_meta.register_extraction(&"crypt")
	_meta.save_game()
	_meta.new_game()
	assert_int(_meta.inventory.total()).is_equal(0)
	assert_array(_meta.loadout.owned_ids()).is_empty()
	assert_bool(_meta.extractions.is_empty()).is_true()
	assert_bool(_meta.has_save()).is_true()


func test_delete_save_removes_file() -> void:
	assert_int(_meta.delete_save()).is_equal(ERR_FILE_NOT_FOUND)
	_meta.save_game()
	assert_int(_meta.delete_save()).is_equal(OK)
	assert_bool(_meta.has_save()).is_false()
