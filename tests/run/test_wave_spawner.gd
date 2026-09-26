extends GdUnitTestSuite
## WaveSpawner: blocco spawn (Ossario, boss pre-overtime, M12 #86). I nemici gia' vivi non sono toccati,
## semplicemente non ne arrivano di nuovi finche' il blocco resta attivo.

var _spawner: WaveSpawner
var _pool: EnemyPool
var _target: Node2D


func before_test() -> void:
	_target = auto_free(Node2D.new())
	add_child(_target)
	_pool = auto_free(EnemyPool.new())
	_pool.enemy_scene = load("res://scenes/run/Enemies/SkeletonArcher/SkeletonArcher.tscn")
	_pool.initial_size = 4
	add_child(_pool)
	var wave := WaveData.new()
	wave.start_interval = 0.01
	wave.min_interval = 0.01
	wave.interval_decay = 0.0
	wave.start_batch = 1
	wave.max_alive = 10
	_spawner = auto_free(WaveSpawner.new())
	_spawner.wave_data = wave
	add_child(_spawner)
	var spawn := EnemySpawn.new()
	spawn.scene = _pool.enemy_scene
	spawn.weight = 1.0
	_spawner.configure([spawn], [_pool])
	_spawner.start(_target)


func test_spawning_blocked_prevents_new_enemies() -> void:
	_spawner.spawning_blocked = true
	for i in 10:
		_spawner._physics_process(0.1)
	assert_int(_pool.active_count()).is_equal(0)


func test_unblocking_lets_spawns_resume() -> void:
	_spawner.spawning_blocked = true
	for i in 5:
		_spawner._physics_process(0.1)
	assert_int(_pool.active_count()).is_equal(0)
	_spawner.spawning_blocked = false
	for i in 5:
		_spawner._physics_process(0.1)
	assert_int(_pool.active_count()).is_greater(0)
