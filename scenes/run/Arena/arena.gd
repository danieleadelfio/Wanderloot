extends Node2D
## Composition root della run: collega i segnali tra player, nemici, pool, HUD e RunManager.

@export var enemy_respawn_delay: float = 1.5
@export var spawn_rect: Rect2 = Rect2(-760.0, -460.0, 1520.0, 920.0)
@export var spawn_min_distance: float = 300.0

@onready var _player: Player = %Player
@onready var _enemy: Enemy = %EnemyBasic
@onready var _projectile_pool: ProjectilePool = %ProjectilePool
@onready var _hud: Hud = %HUD
@onready var _respawn_timer: Timer = %RespawnTimer


func _ready() -> void:
	RunManager.reset()
	_player.shot_requested.connect(_projectile_pool.spawn)
	_player.health.changed.connect(_hud.set_hp)
	_player.died.connect(_on_player_died)
	_hud.set_hp(_player.health.current, _player.health.max_hp)
	_enemy.target = _player
	_enemy.died.connect(_on_enemy_died)
	_respawn_timer.timeout.connect(_spawn_enemy)
	_spawn_enemy()


func _spawn_enemy() -> void:
	_enemy.activate(_random_spawn_position())


func _random_spawn_position() -> Vector2:
	var candidate := Vector2.ZERO
	for i in 10:
		candidate = Vector2(
			randf_range(spawn_rect.position.x, spawn_rect.end.x),
			randf_range(spawn_rect.position.y, spawn_rect.end.y)
		)
		if candidate.distance_to(_player.global_position) >= spawn_min_distance:
			break
	return candidate


func _on_enemy_died(enemy: Enemy) -> void:
	RunManager.add_exp(enemy.data.exp_reward)
	_respawn_timer.start(enemy_respawn_delay)


func _on_player_died() -> void:
	# Placeholder M0: riavvio immediato. Il flusso completo morte = reset run e' M1.
	get_tree().reload_current_scene.call_deferred()
