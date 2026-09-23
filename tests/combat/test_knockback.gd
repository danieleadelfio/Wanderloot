extends GdUnitTestSuite


func test_resistance_scales_impulse() -> void:
	var knockback: Knockback = auto_free(Knockback.new())
	knockback.resistance = 0.75
	knockback.apply(Vector2(400.0, 0.0))
	assert_float(knockback.velocity.x).is_equal_approx(100.0, 0.001)


func test_velocity_decays_to_zero() -> void:
	var knockback: Knockback = auto_free(Knockback.new())
	knockback.apply(Vector2(0.0, 300.0))
	knockback.step(0.1)
	assert_float(knockback.velocity.y).is_less(300.0 * 0.4)
	for i in 120:
		knockback.step(1.0 / 60.0)
	assert_vector(knockback.velocity).is_equal(Vector2.ZERO)
