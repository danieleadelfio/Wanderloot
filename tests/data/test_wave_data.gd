extends GdUnitTestSuite


func test_max_alive_keeps_growing_over_time() -> void:
	var wave: WaveData = load("res://data/waves/wave_default.tres")
	assert_int(wave.max_alive_at(0.0)).is_equal(wave.max_alive)
	var t := wave.max_alive_growth_period * 4.0
	var expected := wave.max_alive + 4 * wave.max_alive_growth + (wave.late_max_alive_bonus if wave.is_late(t) else 0)
	assert_int(wave.max_alive_at(t)).is_equal(expected)


func test_zero_period_means_fixed_cap() -> void:
	var wave := WaveData.new()
	wave.max_alive_growth_period = 0.0
	wave.late_start = 0.0
	assert_int(wave.max_alive_at(999.0)).is_equal(wave.max_alive)


func test_late_phase_spawns_faster_and_allows_more_enemies() -> void:
	var wave: WaveData = load("res://data/waves/wave_default.tres")
	var before := wave.late_start - 0.1
	var after := wave.late_start
	assert_float(wave.interval_at(after)).is_less(wave.interval_at(before))
	assert_int(wave.max_alive_at(after) - wave.max_alive_at(before)).is_greater_equal(wave.late_max_alive_bonus)


func test_interval_floor_in_late_phase() -> void:
	var wave: WaveData = load("res://data/waves/wave_default.tres")
	assert_float(wave.interval_at(10000.0)).is_equal_approx(wave.min_interval * wave.late_interval_multiplier, 0.0001)
