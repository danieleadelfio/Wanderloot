extends GdUnitTestSuite
## Persistenza su file di test dedicato: il salvataggio reale in user:// non viene mai toccato.

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
	var reloaded: Node = auto_free(preload("res://autoload/meta_progression.gd").new())
	reloaded.save_path = TEST_PATH
	assert_int(reloaded.load_from_disk()).is_equal(OK)
	assert_int(reloaded.inventory.amount_of(&"gel")).is_equal(4)
	assert_int(reloaded.inventory.amount_of(&"core")).is_equal(1)
