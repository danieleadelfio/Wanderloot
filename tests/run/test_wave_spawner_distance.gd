extends GdUnitTestSuite
## Anello di spawn e despawn a distanza (M13, #86: arene 10x). Gli spawn devono cadere nell'anello
## [spawn_min_distance, spawn_max_distance] dal player, non ovunque nel rect (altrimenti compaiono a
## migliaia di px, in rage prima ancora di arrivare). I nemici che restano troppo lontani (player
## scappato) despawnano in silenzio, senza segnale enemy_died ne' drop.

var _spawner: WaveSpawner
var _pool: EnemyPool
var _target: Node2D


func before_test() -> void:
	_target = auto_free(Node2D.new())
	add_child(_target)
	_pool = auto_free(EnemyPool.new())
	_pool.enemy_scene = load("res://scenes/run/Enemies/SkeletonArcher/SkeletonArcher.tscn")
	_pool.initial_size = 8
	add_child(_pool)
	var wave := WaveData.new()
	wave.start_interval = 0.01
	wave.min_interval = 0.01
	wave.interval_decay = 0.0
	wave.start_batch = 4
	wave.max_alive = 10
	_spawner = auto_free(WaveSpawner.new())
	_spawner.wave_data = wave
	_spawner.despawn_distance = 500.0
	add_child(_spawner)
	var spawn := EnemySpawn.new()
	spawn.scene = _pool.enemy_scene
	spawn.weight = 1.0
	_spawner.configure([spawn], [_pool])
	_spawner.start(_target)


func test_spawn_positions_stay_within_the_min_max_ring() -> void:
	for i in 5:
		_spawner._physics_process(0.1)
	assert_int(_pool.active_count()).is_greater(0)
	for enemy in _pool.active_enemies():
		var dist := enemy.global_position.distance_to(_target.global_position)
		assert_float(dist).is_greater_equal(_spawner.spawn_min_distance - 0.5)
		assert_float(dist).is_less_equal(_spawner.spawn_max_distance + 0.5)


func test_far_enemy_despawns_silently_without_enemy_died_or_drop() -> void:
	for i in 3:
		_spawner._physics_process(0.1)
	assert_int(_pool.active_count()).is_greater(0)
	# Blocca nuove ondate per isolare il despawn dal normale ciclo di spawn (altrimenti nello stesso
	# tick, col cooldown gia' scaduto, ne arriverebbero subito di nuovi mascherando l'assert).
	_spawner.spawning_blocked = true
	var died_signals := 0
	_pool.enemy_died.connect(func(_e: Enemy) -> void: died_signals += 1)
	for enemy in _pool.active_enemies().duplicate():
		enemy.global_position = _target.global_position + Vector2(_spawner.despawn_distance + 100.0, 0.0)
	_spawner._physics_process(0.1)
	assert_int(_pool.active_count()).is_equal(0)
	assert_int(died_signals).is_equal(0)


func test_despawned_enemy_is_returned_to_the_free_pool() -> void:
	for i in 3:
		_spawner._physics_process(0.1)
	var before_active := _pool.active_count()
	assert_int(before_active).is_greater(0)
	var enemy: Enemy = _pool.active_enemies()[0]
	_pool.despawn(enemy)
	assert_int(_pool.active_count()).is_equal(before_active - 1)
	assert_bool(_pool.active_enemies().has(enemy)).is_false()
