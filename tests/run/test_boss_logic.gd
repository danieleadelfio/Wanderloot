extends GdUnitTestSuite
## Logica pura del sistema boss (M8): scelta dell'attacco per fase, pattern dei proiettili, preavviso, fasi.


func _attack(weight: float, min_phase: int) -> BossAttack:
	var attack := BossAttack.new()
	attack.weight = weight
	attack.min_phase = min_phase
	return attack


func test_pick_respects_phase() -> void:
	var attacks: Array[BossAttack] = [_attack(1.0, 1), _attack(5.0, 2)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for i in 50:
		assert_int(BossAttack.pick_index(attacks, 1, rng)).is_equal(0)
	var seen_second := false
	for i in 50:
		if BossAttack.pick_index(attacks, 2, rng) == 1:
			seen_second = true
	assert_bool(seen_second).is_true()


func test_pick_without_available_attacks() -> void:
	var attacks: Array[BossAttack] = [_attack(1.0, 2)]
	assert_int(BossAttack.pick_index(attacks, 1, RandomNumberGenerator.new())).is_equal(-1)
	assert_int(BossAttack.pick_index([] as Array[BossAttack], 2, RandomNumberGenerator.new())).is_equal(-1)


func test_fan_is_centered_on_direction() -> void:
	var dirs := BossPatterns.fan(Vector2.RIGHT, 3, 60.0)
	assert_int(dirs.size()).is_equal(3)
	assert_float(dirs[1].angle()).is_equal_approx(0.0, 0.001)
	assert_float(dirs[0].angle()).is_equal_approx(deg_to_rad(-30.0), 0.001)
	assert_float(dirs[2].angle()).is_equal_approx(deg_to_rad(30.0), 0.001)
	assert_int(BossPatterns.fan(Vector2.UP, 1, 90.0).size()).is_equal(1)


func test_ring_is_evenly_spaced() -> void:
	var dirs := BossPatterns.ring(4)
	assert_int(dirs.size()).is_equal(4)
	assert_float(dirs[0].angle_to(dirs[1])).is_equal_approx(PI / 2.0, 0.001)
	var sum := Vector2.ZERO
	for d in dirs:
		sum += d
	assert_float(sum.length()).is_equal_approx(0.0, 0.001)


func test_telegraph_progress_is_clamped() -> void:
	assert_float(Telegraph.progress(0.5, 1.0)).is_equal_approx(0.5, 0.001)
	assert_float(Telegraph.progress(3.0, 1.0)).is_equal(1.0)
	assert_float(Telegraph.progress(-1.0, 1.0)).is_equal(0.0)


func test_phase_two_below_threshold() -> void:
	var data := BossData.new()
	data.phase_two_threshold = 0.5
	assert_int(data.phase_for(0.8)).is_equal(1)
	assert_int(data.phase_for(0.5)).is_equal(2)
