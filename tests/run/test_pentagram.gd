extends GdUnitTestSuite
## Pentagramma di sangue (M10.2): attesa con timeout, resistenza nel cerchio, candele, boss in punti diversi.


func test_times_out_if_player_never_enters() -> void:
	var state := PentagramState.new()
	state.start(20.0, 15.0, 15)
	for i in 19:
		assert_int(state.tick(1.0, false)).is_equal(PentagramState.Status.WAITING)
	assert_int(state.tick(1.1, false)).is_equal(PentagramState.Status.FAILED)


func test_leaving_the_circle_fails() -> void:
	var state := PentagramState.new()
	state.start(20.0, 15.0, 15)
	state.tick(0.1, true)
	assert_int(state.tick(3.0, true)).is_equal(PentagramState.Status.ACTIVE)
	assert_int(state.tick(0.1, false)).is_equal(PentagramState.Status.FAILED)
	assert_int(state.tick(1.0, true)).is_equal(PentagramState.Status.FAILED)


func test_one_candle_per_second_then_completed() -> void:
	var state := PentagramState.new()
	state.start(20.0, 15.0, 15)
	state.tick(5.0, false)
	assert_int(state.candles_lit()).is_equal(15)
	state.tick(0.01, true)
	state.tick(1.0, true)
	assert_int(state.candles_lit()).is_equal(14)
	state.tick(9.0, true)
	assert_int(state.candles_lit()).is_equal(5)
	assert_int(state.tick(5.1, true)).is_equal(PentagramState.Status.COMPLETED)
	assert_int(state.candles_lit()).is_equal(0)


func test_boss_points_are_separated() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var rect := Rect2(-700, -400, 1400, 800)
	for attempt in 20:
		var points := SpawnUtils.separated_points(rect, Vector2.ZERO, 300.0, 350.0, 3, rng, [] as Array[Vector2])
		assert_int(points.size()).is_equal(3)
		for i in points.size():
			assert_float(points[i].distance_to(Vector2.ZERO)).is_greater_equal(300.0)
			for j in range(i + 1, points.size()):
				assert_float(points[i].distance_to(points[j])).is_greater_equal(200.0)


func test_crypt_has_both_events_and_pentagram_adds_a_boss() -> void:
	var crypt: ArenaData = load("res://data/arenas/crypt.tres")
	var pentagram: RunEventData = load("res://data/events/blood_pentagram.tres")
	assert_bool(crypt.events.has(pentagram)).is_true()
	assert_int(pentagram.bonus_bosses).is_equal(1)
	assert_int(crypt.boss_count).is_equal(1)
