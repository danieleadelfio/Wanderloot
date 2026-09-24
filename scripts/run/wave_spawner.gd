class_name WaveSpawner
extends Node
## Spawna nemici secondo WaveData scegliendo il tipo tra gli EnemySpawn dell'arena (un EnemyPool per tipo).
## Avviato e configurato dalla composition root.

@export var wave_data: WaveData
@export var spawn_rect: Rect2 = Rect2(-740.0, -440.0, 1480.0, 880.0)
@export var spawn_min_distance: float = 300.0

var _target: Node2D
var _elapsed: float = 0.0
var _cooldown: float = 0.0
var _spawns: Array[EnemySpawn] = []
var _pools: Array[EnemyPool] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	set_physics_process(false)
	_rng.randomize()


## pools[i] contiene i nemici di spawns[i].
func configure(spawns: Array[EnemySpawn], pools: Array[EnemyPool]) -> void:
	_spawns = spawns
	_pools = pools


func active_count() -> int:
	var count := 0
	for pool in _pools:
		count += pool.active_count()
	return count


func _physics_process(delta: float) -> void:
	_elapsed += delta
	_cooldown -= delta
	if _cooldown > 0.0 or _pools.is_empty():
		return
	_cooldown = wave_data.interval_at(_elapsed)
	var free_slots := wave_data.max_alive_at(_elapsed) - active_count()
	for i in mini(wave_data.batch_at(_elapsed), free_slots):
		var index := EnemySpawn.pick_index(_spawns, _elapsed, _rng)
		if index < 0:
			return
		var spawn_position := SpawnUtils.random_point_away(spawn_rect, _target.global_position, spawn_min_distance)
		_pools[index].spawn(spawn_position, _target)


func start(target: Node2D) -> void:
	_target = target
	_elapsed = 0.0
	_cooldown = 0.0
	set_physics_process(true)


func stop() -> void:
	set_physics_process(false)
