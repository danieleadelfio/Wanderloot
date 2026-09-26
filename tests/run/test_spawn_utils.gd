extends GdUnitTestSuite
## Logica pura di piazzamento spawn (M13, #86): il portale di estrazione non deve mai comparire a
## piu' di spawn_max_distance dal player, specialmente ora che le arene sono 10x piu' grandi.

const RECT: Rect2 = Rect2(-7000.0, -4000.0, 14000.0, 8000.0)


func test_point_respects_min_and_max_distance() -> void:
	var origin := Vector2.ZERO
	for i in 30:
		var point := SpawnUtils.random_point_away(RECT, origin, 400.0, 1000.0)
		var dist := point.distance_to(origin)
		assert_float(dist).is_greater_equal(400.0)
		assert_float(dist).is_less_equal(1000.0)


func test_point_stays_inside_rect_even_when_forced() -> void:
	# Player vicino a un bordo: la maggior parte dei tentativi casuali nel rect intero finira' fuori
	# dall'anello [min,max], quindi il fallback forzato entra spesso in gioco.
	var origin := Vector2(RECT.position.x + 10.0, RECT.position.y + 10.0)
	for i in 20:
		var point := SpawnUtils.random_point_away(RECT, origin, 400.0, 1000.0)
		assert_bool(RECT.grow(1.0).has_point(point)).is_true()


func test_default_max_distance_is_unbounded() -> void:
	# Comportamento pre-M13: senza max_distance, basta rispettare il minimo.
	var origin := Vector2.ZERO
	for i in 10:
		var point := SpawnUtils.random_point_away(RECT, origin, 400.0)
		assert_float(point.distance_to(origin)).is_greater_equal(400.0)
