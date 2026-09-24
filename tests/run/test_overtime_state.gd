extends GdUnitTestSuite
## Overtime: avvisi a 30 e 10 s, livello 1 dopo 50 s dall'apertura, poi un livello ogni 50 s;
## modificatori del livello 1 moltiplicati per il livello, boss sempre piu' frequenti.

const DATA: OvertimeData = preload("res://data/run/overtime_default.tres")
const TICK: float = 0.1

var _state: OvertimeState
var _warnings: Array = []
var _levels: Array = []
var _bosses: Array = [0]


func before_test() -> void:
	_state = OvertimeState.new()
	_warnings.clear()
	_levels.clear()
	_bosses[0] = 0
	_state.warned.connect(func(seconds: int, next_level: int) -> void: _warnings.append([seconds, next_level]))
	_state.level_changed.connect(func(level: int) -> void: _levels.append(level))
	_state.boss_due.connect(func(count: int) -> void: _bosses[0] += count)
	_state.start(DATA)


func _run(seconds: float) -> void:
	for i in roundi(seconds / TICK):
		_state.tick(TICK)


func test_warnings_then_level_one_after_fifty_seconds() -> void:
	_run(19.95)
	assert_array(_warnings).is_empty()
	_run(0.2)
	assert_array(_warnings).is_equal([[30, 1]])
	_run(20.0)
	assert_array(_warnings).is_equal([[30, 1], [10, 1]])
	assert_array(_levels).is_empty()
	_run(10.0)
	assert_array(_levels).is_equal([1])
	assert_int(_bosses[0]).is_equal(1)


func test_level_one_modifiers() -> void:
	_run(50.1)
	assert_float(_state.speed_multiplier()).is_equal_approx(2.0, 0.001)
	assert_float(_state.hp_multiplier()).is_equal_approx(1.25, 0.001)
	assert_float(_state.boss_interval()).is_equal_approx(10.0, 0.001)
	_run(10.0)
	assert_int(_bosses[0]).is_equal(2)


func test_each_level_multiplies_the_modifiers() -> void:
	_run(150.1)
	assert_array(_levels).is_equal([1, 2, 3])
	assert_float(_state.speed_multiplier()).is_equal_approx(6.0, 0.001)
	assert_float(_state.hp_multiplier()).is_equal_approx(1.75, 0.001)
	assert_float(_state.boss_interval()).is_equal_approx(10.0 / 3.0, 0.001)
	# Avvisi anche prima di ogni livello successivo.
	assert_bool(_warnings.has([10, 3])).is_true()


func test_boss_waves_match_the_run_boss_count() -> void:
	_state.bosses_per_wave = 2
	_run(50.1)
	assert_int(_bosses[0]).is_equal(2)
	_run(10.0)
	assert_int(_bosses[0]).is_equal(4)
	# Un Pentagramma superato in overtime alza le ondate successive.
	_state.bosses_per_wave = 3
	_run(10.0)
	assert_int(_bosses[0]).is_equal(7)


func test_bosses_per_wave_survives_start() -> void:
	_state.bosses_per_wave = 2
	_state.start(DATA)
	assert_int(_state.bosses_per_wave).is_equal(2)


func test_boss_interval_has_a_floor() -> void:
	_run(50.0 * 20 + 0.1)
	assert_float(_state.boss_interval()).is_equal_approx(DATA.min_boss_interval, 0.001)


func test_stopped_state_does_nothing() -> void:
	_state.stop()
	_run(60.0)
	assert_array(_levels).is_empty()
