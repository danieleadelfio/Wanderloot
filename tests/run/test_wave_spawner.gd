extends GdUnitTestSuite
## WaveSpawner: blocco spawn dei boss pre-overtime (M12 #86, esteso a tutte le arene e a ogni fonte di
## boss in M13 #86). I nemici gia' vivi non sono toccati, semplicemente non ne arrivano di nuovi finche'
## il blocco resta attivo.

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


## Livello arena 1 (M13, #86): niente rage naturale sui nemici spawnati, il flag si propaga da subito.
func test_natural_rage_enabled_propagates_to_spawned_enemies() -> void:
	_spawner.natural_rage_enabled = false
	_spawner._physics_process(0.1)
	assert_int(_pool.active_count()).is_greater(0)
	for enemy in _pool.active_enemies():
		assert_bool(enemy.natural_rage_enabled).is_false()


func _spawned_after(seconds: float) -> int:
	for i in roundi(seconds / 0.1):
		_spawner._physics_process(0.1)
	return _pool.active_count()


func test_boss_alive_before_overtime_blocks_new_enemies() -> void:
	_spawner.update_boss_block(1, 0)
	assert_bool(_spawner.spawning_blocked).is_true()
	assert_int(_spawned_after(1.0)).is_equal(0)


## Piu' boss pre-overtime (Ossario, bonus livello arena, Pentagramma): il blocco resta finche' ne resta uno.
func test_block_lasts_until_the_last_boss_dies() -> void:
	_spawner.update_boss_block(3, 0)
	_spawner.update_boss_block(2, 0)
	_spawner.update_boss_block(1, 0)
	assert_int(_spawned_after(0.5)).is_equal(0)
	_spawner.update_boss_block(0, 0)
	assert_bool(_spawner.spawning_blocked).is_false()
	assert_int(_spawned_after(0.5)).is_greater(0)


## Boss arrivato dopo che il primo era gia' morto (es. Pentagramma superato piu' tardi): blocca di nuovo.
func test_new_pre_overtime_boss_blocks_again() -> void:
	_spawner.update_boss_block(1, 0)
	_spawner.update_boss_block(0, 0)
	_spawner.update_boss_block(1, 0)
	assert_bool(_spawner.spawning_blocked).is_true()


func test_overtime_never_blocks_even_with_bosses_alive() -> void:
	_spawner.update_boss_block(2, 0)
	_spawner.update_boss_block(2, 1)
	assert_bool(_spawner.spawning_blocked).is_false()
	_spawner.update_boss_block(5, 3)
	assert_bool(_spawner.spawning_blocked).is_false()
	assert_int(_spawned_after(0.5)).is_greater(0)


## La regola vale per ogni arena con un boss, non solo per l'Ossario.
func test_every_arena_has_a_boss_subject_to_the_rule() -> void:
	for path in ["res://data/arenas/crypt.tres", "res://data/arenas/ossuary.tres"]:
		var arena: ArenaData = load(path)
		assert_bool(arena.has_boss()).override_failure_message(path).is_true()
