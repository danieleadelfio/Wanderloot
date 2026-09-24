extends GdUnitTestSuite
## Scelta del punto di interazione piu' vicino (Interactable.nearest_index).


func test_nearest_index_empty() -> void:
	assert_int(Interactable.nearest_index(PackedVector2Array(), Vector2.ZERO)).is_equal(-1)


func test_nearest_index_picks_closest() -> void:
	var points := PackedVector2Array([Vector2(100, 0), Vector2(-30, 10), Vector2(0, 200)])
	assert_int(Interactable.nearest_index(points, Vector2.ZERO)).is_equal(1)
	assert_int(Interactable.nearest_index(points, Vector2(0, 150))).is_equal(2)


func test_interactable_tracks_player_range() -> void:
	var spot: Interactable = auto_free(Interactable.new())
	var body: Node2D = auto_free(Node2D.new())
	spot._on_body_changed(body, true)
	assert_bool(spot.player_in_range).is_true()
	spot._on_body_changed(body, false)
	assert_bool(spot.player_in_range).is_false()
