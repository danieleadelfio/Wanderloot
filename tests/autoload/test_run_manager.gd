extends GdUnitTestSuite
## Stato di run: loot azzerato a ogni run, niente loot/exp dopo la fine, level-up con exp in eccesso.

var _run: Node
var _gel: MaterialData


func before_test() -> void:
	_run = auto_free(preload("res://autoload/run_manager.gd").new())
	_gel = MaterialData.new()
	_gel.id = &"gel"


func test_start_run_resets_loot_and_progress() -> void:
	_run.start_run(_curve())
	_run.add_loot(_gel, 3)
	_run.register_kill(7)
	_run.end_run(_run.Result.DEATH)
	_run.start_run(_curve())
	assert_int(_run.loot.total()).is_equal(0)
	assert_int(_run.level).is_equal(1)
	assert_int(_run.kills).is_equal(0)


func test_no_loot_or_exp_after_run_ended() -> void:
	_run.start_run(_curve())
	_run.end_run(_run.Result.EXTRACTED)
	_run.add_loot(_gel, 3)
	_run.register_kill(50)
	assert_int(_run.loot.total()).is_equal(0)
	assert_int(_run.level).is_equal(1)


func test_exp_overflow_carries_to_next_level() -> void:
	_run.start_run(_curve())
	_run.add_exp(12)  # curva 5, 7, 9: 12 = liv.2 (5) + liv.3 (7), resto 0
	assert_int(_run.level).is_equal(3)
	assert_int(_run.experience).is_equal(0)


func test_end_run_only_once() -> void:
	_run.start_run(_curve())
	_run.end_run(_run.Result.DEATH)
	_run.end_run(_run.Result.EXTRACTED)
	assert_int(_run.state).is_equal(_run.State.ENDED)


func _curve() -> LevelCurve:
	var curve := LevelCurve.new()
	curve.base_exp = 5
	curve.growth = 1.35
	return curve
