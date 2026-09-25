extends GdUnitTestSuite
## Ascensione (M12, #86, #16): tabella costi per alzare il cap sbloccato di un'abilita' (logica pura).

func test_cost_grows_with_target_level() -> void:
	var lv2 := Ascension.cost_for(2)
	var lv8 := Ascension.cost_for(8)
	assert_bool(lv2.is_empty()).is_false()
	assert_bool(lv8.is_empty()).is_false()
	var total_lv2 := 0
	for amount in lv2.values():
		total_lv2 += amount
	var total_lv8 := 0
	for amount in lv8.values():
		total_lv8 += amount
	assert_int(total_lv8).is_greater(total_lv2)


func test_out_of_range_is_empty() -> void:
	assert_bool(Ascension.cost_for(1).is_empty()).is_true()
	assert_bool(Ascension.cost_for(0).is_empty()).is_true()
	assert_bool(Ascension.cost_for(9).is_empty()).is_true()
