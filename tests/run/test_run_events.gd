extends GdUnitTestSuite
## Eventi della run (M10): durata, fallimento al primo colpo, tempi, fulmini evitabili.


func test_event_completes_after_duration() -> void:
	var state := RunEventState.new()
	state.start(2.0)
	assert_int(state.tick(1.0)).is_equal(RunEventState.Status.RUNNING)
	assert_float(state.remaining_ratio()).is_equal_approx(0.5, 0.001)
	assert_int(state.tick(1.1)).is_equal(RunEventState.Status.COMPLETED)


func test_event_fails_on_hit_and_stays_failed() -> void:
	var state := RunEventState.new()
	state.start(2.0)
	state.fail()
	assert_int(state.tick(5.0)).is_equal(RunEventState.Status.FAILED)
	var idle := RunEventState.new()
	idle.fail()
	assert_int(idle.status).is_equal(RunEventState.Status.IDLE)


func test_next_time() -> void:
	var times := PackedFloat32Array([35.0, 80.0])
	assert_float(RunEventState.next_time(times, 0)).is_equal(35.0)
	assert_float(RunEventState.next_time(times, 2)).is_equal(-1.0)


func test_lightning_is_escapable_and_crypt_has_storms() -> void:
	var event: RunEventData = load("res://data/events/lightning_storm.tres")
	# Dal centro del cerchio, a velocita' base (220 px/s), si esce prima del colpo con margine.
	assert_float(event.strike_telegraph).is_greater(event.strike_radius / 220.0 * 1.5)
	var crypt: ArenaData = load("res://data/arenas/crypt.tres")
	assert_int(crypt.event_times.size()).is_equal(2)
	assert_bool(crypt.events.has(event)).is_true()
