extends GdUnitTestSuite
## Tutorial contestuale strutturato (M12, #86): un tutorial mostrato una volta, mai piu' finche' il
## salvataggio esiste. has_seen_tutorial()/mark_tutorial_seen() sono l'unico stato persistito; la
## presentazione (camera, testi) resta fuori da questa suite (UI, non logica pura).

const TEST_PATH: String = "user://test_meta_progression_tutorials.cfg"

var _meta: Node


func before_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	_meta = auto_free(preload("res://autoload/meta_progression.gd").new())
	_meta.save_path = TEST_PATH


func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_tutorial_starts_unseen() -> void:
	assert_bool(_meta.has_seen_tutorial(&"hub_intro")).is_false()


func test_mark_seen_persists_in_memory() -> void:
	_meta.mark_tutorial_seen(&"hub_intro")
	assert_bool(_meta.has_seen_tutorial(&"hub_intro")).is_true()
	assert_bool(_meta.has_seen_tutorial(&"first_run")).is_false()


func test_mark_seen_twice_is_a_no_op() -> void:
	_meta.mark_tutorial_seen(&"first_event")
	_meta.has_unsaved_changes = false
	_meta.mark_tutorial_seen(&"first_event")
	assert_bool(_meta.has_unsaved_changes).is_false()


func test_seen_tutorials_are_saved_and_reloaded() -> void:
	_meta.mark_tutorial_seen(&"hub_intro")
	_meta.mark_tutorial_seen(&"first_overtime")
	_meta.save_game()

	var reloaded: Node = auto_free(preload("res://autoload/meta_progression.gd").new())
	reloaded.save_path = TEST_PATH
	reloaded.load_from_disk()

	assert_bool(reloaded.has_seen_tutorial(&"hub_intro")).is_true()
	assert_bool(reloaded.has_seen_tutorial(&"first_overtime")).is_true()
	assert_bool(reloaded.has_seen_tutorial(&"first_event")).is_false()
	assert_bool(reloaded.has_seen_tutorial(&"first_run")).is_false()


func test_new_game_clears_seen_tutorials() -> void:
	_meta.mark_tutorial_seen(&"hub_intro")
	_meta.new_game()
	assert_bool(_meta.has_seen_tutorial(&"hub_intro")).is_false()
