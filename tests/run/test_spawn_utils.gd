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


## Boss (M13, #86): stesso anello di spawn dei nemici base (WaveSpawner 700-1200 px), non piu' ovunque
## nell'arena oltre una distanza minima. Anche con piu' boss insieme e boss gia' presenti.
func test_bosses_spawn_in_the_enemy_ring_and_stay_separated() -> void:
	var spawner := WaveSpawner.new()
	var min_d := spawner.spawn_min_distance
	var max_d := spawner.spawn_max_distance
	spawner.free()
	var rng := RandomNumberGenerator.new()
	for run_seed in 40:
		rng.seed = run_seed
		var origin := Vector2(rng.randf_range(-3000.0, 3000.0), rng.randf_range(-1500.0, 1500.0))
		var existing: Array[Vector2] = [origin + Vector2(900.0, 0.0)]
		var points := SpawnUtils.separated_points(RECT, origin, min_d, 350.0, 1 + run_seed % 4, rng, existing, max_d)
		assert_int(points.size()).is_equal(1 + run_seed % 4)
		for i in points.size():
			var dist := points[i].distance_to(origin)
			assert_float(dist).override_failure_message("seed %d dist %f" % [run_seed, dist]).is_between(min_d, max_d)
			for other in points.slice(i + 1) + existing:
				assert_float(points[i].distance_to(other)).is_greater_equal(350.0)


## Player vicino a un angolo dell'arena: i punti restano dentro il rect e nell'anello.
func test_ring_spawn_near_arena_corner_stays_inside() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var origin := RECT.end - Vector2(300.0, 300.0)
	var points := SpawnUtils.separated_points(RECT, origin, 700.0, 350.0, 3, rng, [] as Array[Vector2], 1200.0)
	for point in points:
		assert_bool(RECT.grow(0.01).has_point(point)).is_true()
		assert_float(point.distance_to(origin)).is_between(700.0, 1200.0)


## Senza max_origin (default) il comportamento resta quello di prima: ovunque nel rect oltre il minimo.
func test_without_max_origin_points_can_be_far() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var far := 0
	for i in 20:
		for point in SpawnUtils.separated_points(RECT, Vector2.ZERO, 380.0, 350.0, 1, rng):
			if point.distance_to(Vector2.ZERO) > 1200.0:
				far += 1
	assert_int(far).is_greater(0)


## Teletrasporto dei boss (M13, #86): mai oltre max_jump dal punto di partenza, dentro il rect.
func test_teleport_point_stays_within_max_jump() -> void:
	var rect := Rect2(-5000, -5000, 10000, 10000)
	for i in 200:
		var from := Vector2(randf_range(-4800, 4800), randf_range(-4800, 4800))
		var player := from + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, 350.0)
		var point := SpawnUtils.teleport_point(rect, from, player, 300.0, 400.0)
		assert_float(point.distance_to(from)).is_less_equal(400.01)
		assert_bool(rect.has_point(point) or point.x == rect.end.x or point.y == rect.end.y).is_true()


func test_teleport_point_prefers_distance_from_player() -> void:
	var rect := Rect2(-5000, -5000, 10000, 10000)
	for i in 50:
		var point := SpawnUtils.teleport_point(rect, Vector2.ZERO, Vector2(50, 0), 300.0, 400.0)
		assert_float(point.distance_to(Vector2(50, 0))).is_greater_equal(300.0)
