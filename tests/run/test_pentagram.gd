extends GdUnitTestSuite
## Pentagramma di sangue (M13, #86): l'evento parte gia' attivo (trigger = interazione con la
## statua, non piu' un ingresso col timeout), resistenza nel cerchio, candele accese per un tratto
## fisso e poi spente una al secondo, boss in punti diversi.


func test_leaving_the_circle_fails_immediately() -> void:
	var state := PentagramState.new()
	state.start(15, 10.0)
	assert_int(state.tick(2.0, true)).is_equal(PentagramState.Status.ACTIVE)
	assert_int(state.tick(0.1, false)).is_equal(PentagramState.Status.FAILED)
	assert_int(state.tick(1.0, true)).is_equal(PentagramState.Status.FAILED)


func test_candles_stay_lit_then_go_out_one_per_second_and_completes() -> void:
	var state := PentagramState.new()
	state.start(15, 10.0)
	state.tick(9.9, true)
	assert_int(state.candles_lit()).is_equal(15)
	state.tick(0.1, true)  # held = 10.0: appena scattato il conto alla rovescia, ancora tutte accese
	assert_int(state.candles_lit()).is_equal(15)
	state.tick(1.0, true)  # held = 11.0
	assert_int(state.candles_lit()).is_equal(14)
	state.tick(8.0, true)  # held = 19.0
	assert_int(state.candles_lit()).is_equal(6)
	assert_int(state.tick(6.0, true)).is_equal(PentagramState.Status.COMPLETED)  # held = 25.0 = 10 + 15
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

func test_blood_pentagram_data_matches_the_bigger_10x_arenas() -> void:
	var pentagram: RunEventData = load("res://data/events/blood_pentagram.tres")
	assert_float(pentagram.circle_radius).is_equal(220.0)
	assert_float(pentagram.candles_start_extinguish_after).is_equal(10.0)
	assert_float(pentagram.max_player_distance).is_greater(pentagram.min_player_distance)
