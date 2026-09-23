class_name WaveSpawner
extends Node
## Spawna nemici da un EnemyPool secondo WaveData. Avviato dalla composition root.

@export var wave_data: WaveData
@export var enemy_pool: EnemyPool
@export var spawn_rect: Rect2 = Rect2(-760.0, -460.0, 1520.0, 920.0)
@export var spawn_min_distance: float = 300.0

var _target: Node2D
var _elapsed: float = 0.0
var _cooldown: float = 0.0


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = wave_data.interval_at(_elapsed)
	var free_slots := wave_data.max_alive - enemy_pool.active_count()
	for i in mini(wave_data.batch_at(_elapsed), free_slots):
		var spawn_position := SpawnUtils.random_point_away(spawn_rect, _target.global_position, spawn_min_distance)
		enemy_pool.spawn(spawn_position, _target)


func start(target: Node2D) -> void:
	_target = target
	_elapsed = 0.0
	_cooldown = 0.0
	set_physics_process(true)


func stop() -> void:
	set_physics_process(false)
