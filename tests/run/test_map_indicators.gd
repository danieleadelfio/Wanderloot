extends GdUnitTestSuite
## Logica pura degli indicatori piazzabili sulla mappa (M13, #86): max 5, 5 colori distinti, mai
## giallo (riservato al portale di estrazione, ExtractionIndicator.COLOR).

const EXTRACTION_YELLOW: Color = Color(1.0, 0.85, 0.2)


func test_adds_up_to_max_and_then_refuses() -> void:
	var indicators := MapIndicators.new()
	for i in MapIndicators.MAX_INDICATORS:
		assert_bool(indicators.add(Vector2(i, i))).is_true()
	assert_bool(indicators.is_full()).is_true()
	assert_bool(indicators.add(Vector2(99, 99))).is_false()
	assert_int(indicators.size()).is_equal(MapIndicators.MAX_INDICATORS)


func test_has_five_distinct_colors_and_none_is_the_extraction_yellow() -> void:
	assert_int(MapIndicators.COLORS.size()).is_equal(5)
	var seen: Array[Color] = []
	for color in MapIndicators.COLORS:
		assert_bool(color.is_equal_approx(EXTRACTION_YELLOW)).is_false()
		assert_bool(seen.has(color)).is_false()
		seen.append(color)


func test_color_for_cycles_through_the_palette() -> void:
	var indicators := MapIndicators.new()
	assert_that(indicators.color_for(0)).is_equal(MapIndicators.COLORS[0])
	assert_that(indicators.color_for(5)).is_equal(MapIndicators.COLORS[0])


func test_remove_at_and_clear() -> void:
	var indicators := MapIndicators.new()
	indicators.add(Vector2(1, 1))
	indicators.add(Vector2(2, 2))
	indicators.remove_at(0)
	assert_int(indicators.size()).is_equal(1)
	assert_that(indicators.points()[0]).is_equal(Vector2(2, 2))
	indicators.clear()
	assert_int(indicators.size()).is_equal(0)
	assert_bool(indicators.is_full()).is_false()
