extends Node2D
## Composition root della run: collega i segnali tra player, nemici, pool, HUD e RunManager.

@export var level_curve: LevelCurve
@export var upgrade_table: UpgradeTable
@export var choices_per_level: int = 3
@export var extraction_data: ExtractionData
@export var extraction_spawn_rect: Rect2 = Rect2(-700.0, -400.0, 1400.0, 800.0)

var _pending_level_ups: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _player: Player = %Player
@onready var _enemy_pool: EnemyPool = %EnemyPool
@onready var _wave_spawner: WaveSpawner = %WaveSpawner
@onready var _projectile_pool: ProjectilePool = %ProjectilePool
@onready var _hud: Hud = %HUD
@onready var _level_up_choice: LevelUpChoice = %LevelUpChoice
@onready var _extraction_point: ExtractionPoint = %ExtractionPoint
@onready var _extraction_timer: Timer = %ExtractionTimer
@onready var _run_end_screen: RunEndScreen = %RunEndScreen


func _ready() -> void:
	get_tree().paused = false
	_rng.randomize()
	RunManager.state_changed.connect(_on_run_state_changed)
	RunManager.run_ended.connect(_on_run_ended)
	RunManager.leveled_up.connect(_on_leveled_up)
	_run_end_screen.restart_requested.connect(_on_restart_requested)
	_level_up_choice.upgrade_chosen.connect(_on_upgrade_chosen)
	_player.shot_requested.connect(_projectile_pool.spawn)
	_player.health.changed.connect(_hud.set_hp)
	_player.died.connect(_on_player_died)
	_hud.set_hp(_player.health.current, _player.health.max_hp)
	_enemy_pool.enemy_died.connect(_on_enemy_died)
	_wave_spawner.start(_player)
	_extraction_point.data = extraction_data
	_extraction_point.progress_changed.connect(_hud.set_extraction_progress)
	_extraction_point.extracted.connect(_on_extracted)
	_extraction_timer.timeout.connect(_open_extraction)
	_extraction_timer.start(extraction_data.appear_after)
	RunManager.start_run(level_curve)


func _process(_delta: float) -> void:
	if not _extraction_timer.is_stopped():
		_hud.set_extraction_countdown(_extraction_timer.time_left)


func _on_enemy_died(enemy: Enemy) -> void:
	RunManager.register_kill(enemy.data.exp_reward)
	_roll_drops(enemy.data)


func _roll_drops(data: EnemyData) -> void:
	for entry in data.drops:
		var amount := entry.roll(_rng)
		if amount > 0:
			RunManager.add_loot(entry.material, amount)


func _open_extraction() -> void:
	var spawn_position := SpawnUtils.random_point_away(
		extraction_spawn_rect, _player.global_position, extraction_data.spawn_min_distance
	)
	_extraction_point.activate(spawn_position)


func _on_extracted() -> void:
	RunManager.end_run(RunManager.Result.EXTRACTED)


func _on_leveled_up(_level: int) -> void:
	_pending_level_ups += 1
	if RunManager.state == RunManager.State.RUNNING:
		RunManager.begin_level_up()
		_present_level_up()


func _present_level_up() -> void:
	_level_up_choice.present(upgrade_table.pick(choices_per_level, _rng))


func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	_player.apply_upgrade(upgrade)
	_pending_level_ups -= 1
	if _pending_level_ups > 0:
		_present_level_up()
	else:
		RunManager.end_level_up()


func _on_player_died() -> void:
	RunManager.end_run(RunManager.Result.DEATH)


func _on_run_state_changed(state: RunManager.State) -> void:
	get_tree().paused = state != RunManager.State.RUNNING


func _on_run_ended(result: RunManager.Result) -> void:
	_pending_level_ups = 0
	_level_up_choice.hide()
	var extracted := result == RunManager.Result.EXTRACTED
	# Unico punto in cui il loot di run raggiunge MetaProgression (GDD §4).
	var loot_amount := LootTransfer.resolve(extracted, RunManager.loot, MetaProgression.deposit_run_loot)
	_run_end_screen.present(
		extracted, RunManager.level, RunManager.elapsed, RunManager.kills,
		loot_amount, MetaProgression.inventory.total()
	)


func _on_restart_requested() -> void:
	# Si torna all'hub; la prossima run ricrea la scena Arena da zero (RunManager riparte da start_run()).
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(SceneRoutes.HUB)
