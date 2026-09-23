extends Node2D
## Composition root della run: collega i segnali tra player, nemici, pool, HUD e RunManager.

@onready var _player: Player = %Player
@onready var _enemy_pool: EnemyPool = %EnemyPool
@onready var _wave_spawner: WaveSpawner = %WaveSpawner
@onready var _projectile_pool: ProjectilePool = %ProjectilePool
@onready var _hud: Hud = %HUD


func _ready() -> void:
	RunManager.reset()
	_player.shot_requested.connect(_projectile_pool.spawn)
	_player.health.changed.connect(_hud.set_hp)
	_player.died.connect(_on_player_died)
	_hud.set_hp(_player.health.current, _player.health.max_hp)
	_enemy_pool.enemy_died.connect(_on_enemy_died)
	_wave_spawner.start(_player)


func _on_enemy_died(enemy: Enemy) -> void:
	RunManager.add_exp(enemy.data.exp_reward)


func _on_player_died() -> void:
	# Placeholder: riavvio immediato. Il flusso completo morte = reset run e' #5.
	get_tree().reload_current_scene.call_deferred()
