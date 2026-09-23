extends Node2D
## Composition root della run: collega i segnali tra player, nemici, pool, HUD e RunManager.

@export var level_curve: LevelCurve
@export var upgrade_table: UpgradeTable
@export var choices_per_level: int = 3

var _pending_level_ups: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _player: Player = %Player
@onready var _enemy_pool: EnemyPool = %EnemyPool
@onready var _wave_spawner: WaveSpawner = %WaveSpawner
@onready var _projectile_pool: ProjectilePool = %ProjectilePool
@onready var _hud: Hud = %HUD
@onready var _level_up_choice: LevelUpChoice = %LevelUpChoice


func _ready() -> void:
	get_tree().paused = false
	_rng.randomize()
	RunManager.start_run(level_curve)
	RunManager.leveled_up.connect(_on_leveled_up)
	_level_up_choice.upgrade_chosen.connect(_on_upgrade_chosen)
	_player.shot_requested.connect(_projectile_pool.spawn)
	_player.health.changed.connect(_hud.set_hp)
	_player.died.connect(_on_player_died)
	_hud.set_hp(_player.health.current, _player.health.max_hp)
	_enemy_pool.enemy_died.connect(_on_enemy_died)
	_wave_spawner.start(_player)


func _on_enemy_died(enemy: Enemy) -> void:
	RunManager.add_exp(enemy.data.exp_reward)


func _on_leveled_up(_level: int) -> void:
	_pending_level_ups += 1
	if not _level_up_choice.visible:
		_present_level_up()


func _present_level_up() -> void:
	get_tree().paused = true
	_level_up_choice.present(upgrade_table.pick(choices_per_level, _rng))


func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	_player.apply_upgrade(upgrade)
	_pending_level_ups -= 1
	if _pending_level_ups > 0:
		_present_level_up()
	else:
		get_tree().paused = false


func _on_player_died() -> void:
	# Placeholder: riavvio immediato. Il flusso completo morte = reset run e' #5.
	get_tree().reload_current_scene.call_deferred()
