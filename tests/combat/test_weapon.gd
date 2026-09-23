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
