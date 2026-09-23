extends GdUnitTestSuite


func test_max_alive_keeps_growing_over_time() -> void:
	var wave: WaveData = load("res://data/waves/wave_default.tres")
	assert_int(wave.max_alive_at(0.0)).is_equal(wave.max_alive)
	assert_int(wave.max_alive_at(wave.max_alive_growth_period * 4.0)).is_equal(wave.max_alive + 4 * wave.max_alive_growth)


func test_zero_period_means_fixed_cap() -> void:
	var wave := WaveData.new()
	wave.max_alive_growth_period = 0.0
	assert_int(wave.max_alive_at(999.0)).is_equal(wave.max_alive)


func test_interval_never_below_min() -> void:
	var wave: WaveData = load("res://data/waves/wave_default.tres")
	assert_float(wave.interval_at(10000.0)).is_equal(wave.min_interval)
