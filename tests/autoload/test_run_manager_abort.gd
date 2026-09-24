extends GdUnitTestSuite
## Abbandono della run (Carica / Torna al menu dal menu di pausa, M8).


func test_abort_run_clears_loot_without_result() -> void:
	var manager: Node = auto_free(preload("res://autoload/run_manager.gd").new())
	manager.start_run(load("res://data/run/level_curve.tres"))
	manager.add_loot(load("res://data/materials/slime_gel.tres"), 3)
	var ended := [false]
	manager.run_ended.connect(func(_r: int) -> void: ended[0] = true)
	manager.abort_run()
	assert_int(manager.state).is_equal(0)
	assert_int(manager.loot.total()).is_equal(0)
	assert_bool(ended[0]).is_false()
