extends GdUnitTestSuite


func test_arena_without_requirement_is_always_unlocked() -> void:
	var arena := ArenaData.new()
	assert_bool(arena.is_unlocked({})).is_true()


func test_unlock_needs_extractions_in_required_arena() -> void:
	var arena := ArenaData.new()
	arena.unlock_arena = &"crypt"
	arena.unlock_extractions = 3
	assert_bool(arena.is_unlocked({&"crypt": 2})).is_false()
	assert_bool(arena.is_unlocked({&"crypt": 3})).is_true()
	assert_bool(arena.is_unlocked({&"other": 9})).is_false()


func test_spawn_pick_respects_min_time_and_weights() -> void:
	var early := EnemySpawn.new()
	early.weight = 1.0
	var late := EnemySpawn.new()
	late.weight = 1000.0
	late.min_time = 30.0
	var spawns: Array[EnemySpawn] = [early, late]
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 50:
		assert_int(EnemySpawn.pick_index(spawns, 10.0, rng)).is_equal(0)
	var late_picks := 0
	for i in 200:
		if EnemySpawn.pick_index(spawns, 40.0, rng) == 1:
			late_picks += 1
	assert_int(late_picks).is_greater(190)


func test_no_spawn_available_returns_minus_one() -> void:
	var late := EnemySpawn.new()
	late.min_time = 30.0
	var spawns: Array[EnemySpawn] = [late]
	assert_int(EnemySpawn.pick_index(spawns, 5.0, RandomNumberGenerator.new())).is_equal(-1)


func test_catalog_starts_with_the_crypt() -> void:
	var catalog: ArenaCatalog = load("res://data/arenas/arena_catalog.tres")
	assert_str(String(catalog.first().id)).is_equal("crypt")
	assert_bool(catalog.first().is_unlocked({})).is_true()
	assert_object(catalog.first().wave_data).is_not_null()
	assert_array(catalog.first().enemies).is_not_empty()
