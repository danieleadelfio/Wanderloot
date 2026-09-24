extends GdUnitTestSuite
## Evento dopo il boss: parte dopo il ritardo, non consuma i tempi fissi, aspetta la fine di un evento in corso.

var _director: RunEventDirector
var _started: Array = []


func before_test() -> void:
	var player: Player = auto_free(load("res://scenes/run/Player/Player.tscn").instantiate())
	add_child(player)
	_director = auto_free(RunEventDirector.new())
	add_child(_director)
	_director.setup(load("res://data/arenas/crypt.tres"), player)
	_director.set_physics_process(false)
	var storm: Array[RunEventData] = [load("res://data/events/lightning_storm.tres")]
	_director.events = storm
	_started.clear()
	_director.event_started.connect(func(e: RunEventData) -> void: _started.append(e.id))


func _run(seconds: float) -> void:
	for i in roundi(seconds / 0.1):
		_director._physics_process(0.1)


func test_queued_event_starts_after_delay_without_using_fixed_times() -> void:
	_director.times = PackedFloat32Array([100.0])
	_director.queue_event(10.0)
	_run(9.9)
	assert_array(_started).is_empty()
	_run(0.2)
	assert_array(_started).is_equal([&"lightning_storm"])
	assert_int(_director._fired).is_equal(0)
	assert_bool(_director.has_queued_event()).is_false()


func test_queued_event_waits_for_the_running_one() -> void:
	_director.times = PackedFloat32Array([0.05])
	_run(0.1)
	assert_int(_started.size()).is_equal(1)
	_director.queue_event(1.0)
	_run(3.0)
	assert_int(_started.size()).is_equal(1)
	_run(9.0)
	assert_int(_started.size()).is_equal(2)


func test_arenas_have_the_boss_event() -> void:
	for path in ["res://data/arenas/crypt.tres", "res://data/arenas/ossuary.tres"]:
		assert_float((load(path) as ArenaData).boss_event_delay).is_equal(10.0)
