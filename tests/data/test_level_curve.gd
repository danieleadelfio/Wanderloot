extends GdUnitTestSuite


func test_exp_to_next_follows_curve() -> void:
	var curve := LevelCurve.new()
	curve.base_exp = 5
	curve.growth = 1.35
	assert_array([curve.exp_to_next(1), curve.exp_to_next(2), curve.exp_to_next(3), curve.exp_to_next(4)]).is_equal([5, 7, 9, 12])


func test_exp_to_next_never_below_one() -> void:
	var curve := LevelCurve.new()
	curve.base_exp = 0
	assert_int(curve.exp_to_next(1)).is_equal(1)
