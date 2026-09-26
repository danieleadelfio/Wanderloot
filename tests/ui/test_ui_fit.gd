extends GdUnitTestSuite
## UiFit (M13, #86): scala delle finestre Inventario (hub e run) per stare nello schermo.


func test_content_that_fits_is_not_scaled() -> void:
	assert_float(UiFit.scale_factor(Vector2(800, 500), Vector2(1177, 662))).is_equal(1.0)
	assert_float(UiFit.scale_factor(Vector2(1177, 662), Vector2(1177, 662))).is_equal(1.0)


func test_scale_follows_the_tightest_axis() -> void:
	assert_float(UiFit.scale_factor(Vector2(1220, 620), Vector2(1177.6, 662.4))).is_equal_approx(1177.6 / 1220.0, 0.0001)
	assert_float(UiFit.scale_factor(Vector2(1000, 1000), Vector2(1177.6, 662.4))).is_equal_approx(0.6624, 0.0001)


func test_unmeasured_content_is_not_scaled() -> void:
	assert_float(UiFit.scale_factor(Vector2.ZERO, Vector2(1177, 662))).is_equal(1.0)
	assert_float(UiFit.scale_factor(Vector2(0, 500), Vector2(1177, 662))).is_equal(1.0)


## Si scala la finestra (non gestita da un container), il pannello resta a scala 1: un container
## riporta a 1 la scala dei figli a ogni riordino, ed era la causa della finestra che "saltava".
func test_fit_scales_the_window_not_the_panel() -> void:
	var window: CenterContainer = auto_free(CenterContainer.new())
	add_child(window)
	window.size = Vector2(1280, 720)
	var panel: Control = Control.new()
	panel.custom_minimum_size = Vector2(1220, 620)
	window.add_child(panel)
	UiFit.fit(window, panel, Vector2(1280, 720), 0.92)
	assert_float(window.scale.x).is_equal_approx(1280.0 * 0.92 / 1220.0, 0.0001)
	assert_vector(window.pivot_offset).is_equal(Vector2(640, 360))
	window.queue_sort()
	await get_tree().process_frame
	assert_vector(panel.scale).is_equal(Vector2.ONE)
	assert_float(window.scale.x).is_equal_approx(1280.0 * 0.92 / 1220.0, 0.0001)
