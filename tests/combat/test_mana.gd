extends GdUnitTestSuite
## Pool di mana dello sparo base (M12, #86): logica pura (RefCounted, nessun nodo).


func test_reset_fills_to_max() -> void:
	var mana := Mana.new()
	mana.reset(30.0, 6.0)
	assert_float(mana.current).is_equal_approx(30.0, 0.001)
	assert_float(mana.max_value).is_equal_approx(30.0, 0.001)


func test_spend_reduces_current_when_affordable() -> void:
	var mana := Mana.new()
	mana.reset(10.0, 0.0)
	assert_bool(mana.spend(4.0)).is_true()
	assert_float(mana.current).is_equal_approx(6.0, 0.001)


func test_spend_fails_and_does_not_change_when_not_affordable() -> void:
	var mana := Mana.new()
	mana.reset(10.0, 0.0)
	mana.spend(9.0)
	assert_bool(mana.spend(5.0)).is_false()
	assert_float(mana.current).is_equal_approx(1.0, 0.001)


func test_zero_or_negative_cost_is_always_affordable() -> void:
	var mana := Mana.new()
	mana.reset(0.0, 0.0)
	assert_bool(mana.can_afford(0.0)).is_true()
	assert_bool(mana.spend(0.0)).is_true()


func test_regenerate_clamps_to_max() -> void:
	var mana := Mana.new()
	mana.reset(10.0, 5.0)
	mana.spend(8.0)
	mana.regenerate(0.2)
	assert_float(mana.current).is_equal_approx(3.0, 0.001)
	mana.regenerate(100.0)
	assert_float(mana.current).is_equal_approx(10.0, 0.001)
