extends GdUnitTestSuite
## La cadenza non ha tetto: anche oltre i 60 tick/s partono tutti i colpi previsti.

const TICK: float = 1.0 / 60.0


func _shots_in_one_second(fire_rate: float) -> int:
	var weapon: Weapon = auto_free(Weapon.new())
	weapon.data = WeaponData.new()
	weapon.data.fire_rate = fire_rate
	add_child(weapon)
	weapon.set_physics_process(false)
	var shots := 0
	for i in 60:
		shots += weapon.try_fire(Vector2.RIGHT)
		weapon._physics_process(TICK)
	return shots


func test_low_fire_rate_is_unchanged() -> void:
	assert_int(_shots_in_one_second(4.0)).is_between(4, 5)


func test_rates_above_tick_rate_fire_multiple_shots_per_tick() -> void:
	# 60 chiamate coprono 59 tick di tempo + il colpo iniziale.
	for rate in [40.0, 120.0, 1000.0]:
		var expected := 1 + int(rate * 59.0 / 60.0)
		assert_int(_shots_in_one_second(rate)).is_between(expected - 1, expected + 1)


func test_no_burst_after_idle() -> void:
	var weapon: Weapon = auto_free(Weapon.new())
	weapon.data = WeaponData.new()
	weapon.data.fire_rate = 4.0
	add_child(weapon)
	weapon.set_physics_process(false)
	for i in 600:
		weapon._physics_process(TICK)
	assert_int(weapon.try_fire(Vector2.RIGHT)).is_equal(1)

func test_insufficient_mana_stops_firing() -> void:
	var weapon: Weapon = auto_free(Weapon.new())
	weapon.data = WeaponData.new()
	weapon.data.fire_rate = 4.0
	weapon.data.mana_cost = 5.0
	var mana := Mana.new()
	mana.reset(5.0, 0.0)
	weapon.mana = mana
	add_child(weapon)
	weapon.set_physics_process(false)
	assert_int(weapon.try_fire(Vector2.RIGHT)).is_equal(1)
	assert_float(mana.current).is_equal_approx(0.0, 0.001)
	# Cooldown esaurito del tutto (come test_no_burst_after_idle): il prossimo try_fire tenterebbe
	# davvero un colpo, ma niente mana, quindi non parte e non si scarica gratis.
	for i in 600:
		weapon._physics_process(TICK)
	assert_int(weapon.try_fire(Vector2.RIGHT)).is_equal(0)
	assert_float(mana.current).is_equal_approx(0.0, 0.001)


func test_regenerated_mana_allows_firing_again() -> void:
	var weapon: Weapon = auto_free(Weapon.new())
	weapon.data = WeaponData.new()
	weapon.data.fire_rate = 4.0
	weapon.data.mana_cost = 5.0
	var mana := Mana.new()
	mana.reset(5.0, 0.0)
	weapon.mana = mana
	add_child(weapon)
	weapon.set_physics_process(false)
	weapon.try_fire(Vector2.RIGHT)
	for i in 600:
		weapon._physics_process(TICK)
	assert_int(weapon.try_fire(Vector2.RIGHT)).is_equal(0)
	mana.current = 5.0  # mana tornato disponibile (regen o consumabile)
	assert_int(weapon.try_fire(Vector2.RIGHT)).is_equal(1)


func test_zero_mana_cost_never_gated_even_with_empty_pool() -> void:
	var weapon: Weapon = auto_free(Weapon.new())
	weapon.data = WeaponData.new()
	weapon.data.fire_rate = 4.0
	var mana := Mana.new()
	mana.reset(0.0, 0.0)
	weapon.mana = mana
	add_child(weapon)
	weapon.set_physics_process(false)
	assert_int(weapon.try_fire(Vector2.RIGHT)).is_equal(1)
