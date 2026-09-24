extends Node2D
## Composition root della run: collega i segnali tra player, nemici, pool, HUD e RunManager.
## L'arena si configura da ArenaData (M7): aspetto, luci, musica, ondate, nemici.

@export var level_curve: LevelCurve
@export var upgrade_table: UpgradeTable
@export var choices_per_level: int = 3
## Se vuoto si usa l'arena scelta in MetaProgression (portale).
@export var arena_override: ArenaData
@export var extraction_spawn_rect: Rect2 = Rect2(-700.0, -400.0, 1400.0, 800.0)
@export var torch_scene: PackedScene = preload("res://scenes/run/Torch/Torch.tscn")
@export var candle_scene: PackedScene = preload("res://scenes/run/Candle/Candle.tscn")
## Zona in cui spargere decorazioni e candele (lontano dal centro, dove parte il player).
@export var decoration_rect: Rect2 = Rect2(-740.0, -440.0, 1480.0, 880.0)
## Torce per lato lungo (muro alto e basso), distribuite in modo uniforme.

var arena: ArenaData
var extraction_data: ExtractionData
var _enemy_pools: Array[EnemyPool] = []
var _pending_level_ups: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Exp frazionaria dovuta al moltiplicatore "Saggezza", accumulata fino all'unità successiva.
var _exp_remainder: float = 0.0

@onready var _player: Player = %Player
## Boss della run (null finche' non compare o se l'arena non ne ha). Letto anche dal bot di playtest.
var boss: Boss = null
## Abilita' che gli eventi possono offrire (M10).
@export var ability_catalog: AbilityCatalog = preload("res://data/abilities/ability_catalog.tres")
var _choosing_ability: bool = false
var boss_defeated: bool = false
var _boss_timer := Timer.new()
@onready var _enemies: Node2D = %Enemies
@onready var _enemy_projectile_pool: ProjectilePool = %EnemyProjectilePool
@onready var _floor: Sprite2D = %Floor
@onready var _wall_tiles: Node2D = %WallTiles
@onready var _ambient: CanvasModulate = %Ambient
@onready var _music: AudioStreamPlayer = %Music
@onready var _decorations: Node2D = %Decorations
@onready var _fog: FogDrift = %Fog
@onready var _wave_spawner: WaveSpawner = %WaveSpawner
@onready var _projectile_pool: ProjectilePool = %ProjectilePool
@onready var _pickup_pool: PickupPool = %PickupPool
@onready var _torches: Node2D = %Torches
@onready var _hud: Hud = %HUD
@onready var _level_up_choice: LevelUpChoice = %LevelUpChoice
@onready var _extraction_point: ExtractionPoint = %ExtractionPoint
@onready var _extraction_timer: Timer = %ExtractionTimer
@onready var _run_end_screen: RunEndScreen = %RunEndScreen
@onready var _hit_stop: HitStop = %HitStop
@onready var _sfx: SfxPlayer = %Sfx
@onready var _extraction_indicator: ExtractionIndicator = %ExtractionIndicator
@onready var _pause: PauseController = %PauseController
@onready var _pause_menu: PauseMenu = %PauseMenu
@onready var _run_inventory: RunInventory = %RunInventory
@onready var _wand: WandAbilities = %WandAbilities
@onready var _ability_choice: AbilityChoice = %AbilityChoice
@onready var _events: RunEventDirector = %EventDirector


func _ready() -> void:
	get_tree().paused = false
	_rng.randomize()
	arena = arena_override if arena_override != null else MetaProgression.current_arena()
	extraction_data = arena.extraction_data
	_apply_arena_look()
	RunManager.state_changed.connect(_on_run_state_changed)
	RunManager.run_ended.connect(_on_run_ended)
	RunManager.leveled_up.connect(_on_leveled_up)
	_run_end_screen.restart_requested.connect(_on_restart_requested)
	_pause.mode_changed.connect(_on_pause_mode_changed)
	_pause_menu.action_requested.connect(_pause.request)
	_pause_menu.save_requested.connect(_on_save_requested)
	_pause_menu.load_requested.connect(GameSession.load_saved.bind(get_tree()))
	_pause_menu.menu_requested.connect(GameSession.quit_to_menu.bind(get_tree()))
	_pause_menu.language_requested.connect(_on_language_requested)
	_level_up_choice.upgrade_chosen.connect(_on_upgrade_chosen)
	_player.shot_requested.connect(_projectile_pool.spawn)
	_player.health.changed.connect(_hud.set_hp)
	_player.died.connect(_on_player_died)
	_player.health.damaged.connect(_hit_stop.trigger)
	_player.health.damaged.connect(_sfx.play.bind(&"player_hurt").unbind(1))
	_player.shot_requested.connect(_sfx.play.bind(&"shoot").unbind(3))
	# Equip letto una volta a inizio run: cambiarlo nell'hub vale solo dalla run successiva.
	_player.begin_run(MetaProgression.equipped_items())
	_hud.set_hp(_player.health.current, _player.health.max_hp)
	_hud.set_stats(_player.stats, _player.weapon_data())
	_create_enemy_pools()
	_wand.setup(_player, _projectile_pool, targetable_enemies)
	_wand.changed.connect(_hud.set_abilities)
	_ability_choice.resolved.connect(_on_ability_resolved)
	_events.bounds = extraction_spawn_rect
	_events.setup(arena, _player)
	_events.event_started.connect(_on_event_started)
	_events.event_progress.connect(_hud.set_event_progress)
	_events.event_completed.connect(_on_event_completed)
	_events.event_failed.connect(_on_event_failed)
	_events.strike_landed.connect(_sfx.play.bind(&"lightning"))
	_pickup_pool.target = _player
	_pickup_pool.attract_radius = _player.stats.pickup_radius
	_pickup_pool.exp_collected.connect(_on_exp_collected)
	_pickup_pool.material_collected.connect(_on_material_collected)
	_wave_spawner.start(_player)
	_extraction_point.data = extraction_data
	_extraction_indicator.target = _extraction_point
	_extraction_point.progress_changed.connect(_hud.set_extraction_progress)
	_extraction_point.extracted.connect(_on_extracted)
	_extraction_timer.timeout.connect(_open_extraction)
	_extraction_timer.start(extraction_data.appear_after)
	_boss_timer.one_shot = true
	add_child(_boss_timer)
	_boss_timer.timeout.connect(_spawn_boss)
	RunManager.start_run(level_curve)


## Nemici vivi in tutti i pool (usato anche dagli strumenti di playtest).
func active_enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for pool in _enemy_pools:
		for enemy in pool.get_children():
			if enemy is Enemy and enemy.visible:
				result.append(enemy)
	return result


## Zone di pericolo attive (boss + fulmini degli eventi) per il bot di playtest: centro x,y e raggio z.
func danger_zones() -> Array[Vector3]:
	var zones := _events.danger_zones()
	if is_instance_valid(boss) and boss.danger_zone().z > 0.0:
		zones.append(boss.danger_zone())
	return zones


func _on_event_started(event: RunEventData) -> void:
	_hud.show_event(event.title, event.subtitle)
	_sfx.play(&"event_start")


func _on_event_completed(event: RunEventData) -> void:
	_hud.end_event(true)
	offer_abilities(event.reward_choices)


func _on_event_failed(_event: RunEventData) -> void:
	_hud.end_event(false)


## Nemici e boss colpibili dalle abilita' della bacchetta.
func targetable_enemies() -> Array[Node2D]:
	var result: Array[Node2D] = []
	result.assign(active_enemies())
	if is_instance_valid(boss):
		result.append(boss)
	return result


## Ricompensa degli eventi: il gioco si ferma e si sceglie un'abilita' tra quelle non ancora nella bacchetta.
func offer_abilities(count: int = 3) -> void:
	var options := ability_catalog.pick(count, _wand.slots.ids(), _rng)
	if options.is_empty() or RunManager.state != RunManager.State.RUNNING:
		return
	_choosing_ability = true
	_pause.enabled = false
	_refresh_pause()
	_ability_choice.present(options, _wand.slots.abilities, _wand.slots.is_full())


func _on_ability_resolved(ability: WandAbility, replace_index: int) -> void:
	_choosing_ability = false
	_pause.enabled = RunManager.state == RunManager.State.RUNNING
	if ability != null and _wand.equip(ability, replace_index):
		# Le abilita' a ricarica partono cariche (es. Barriera arcana attiva subito).
		if ability.trigger == WandAbility.Trigger.COOLDOWN and ability.effect:
			ability.effect.activate(_wand)
		_sfx.play(&"level_up")
	_refresh_pause()


func _create_enemy_pools() -> void:
	for spawn in arena.enemies:
		var pool := EnemyPool.new()
		pool.enemy_scene = spawn.scene
		pool.initial_size = 24
		_enemies.add_child(pool)
		pool.enemy_died.connect(_on_enemy_died)
		pool.enemy_hurt.connect(_sfx.play.bind(&"enemy_hit").unbind(1))
		pool.enemy_shot.connect(_enemy_projectile_pool.spawn)
		pool.enemy_shot.connect(_sfx.play.bind(&"enemy_shoot").unbind(3))
		_enemy_pools.append(pool)
	_wave_spawner.wave_data = arena.wave_data
	_wave_spawner.configure(arena.enemies, _enemy_pools)


func _apply_arena_look() -> void:
	if arena.floor_texture:
		_floor.texture = arena.floor_texture
	if arena.wall_texture:
		for wall in _wall_tiles.get_children():
			(wall as Sprite2D).texture = arena.wall_texture
	_ambient.color = arena.ambient_color
	_player.light.color = arena.player_light_color
	_player.light.energy = arena.player_light_energy
	_player.light.texture_scale = arena.player_light_scale
	_place_torches(arena.torches_per_wall, arena.torch_color)
	_place_decorations()
	if arena.fog_color.a > 0.0 and arena.fog_count > 0:
		_fog.setup(arena.fog_color, arena.fog_count, _rng)
	if arena.music:
		_music.stream = arena.music
		_music.play()


## Decorazioni e candele: posizioni casuali ma stabili per arena (seme dall'id), lontano dal centro.
func _place_decorations() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(arena.id)
	var unshaded := CanvasItemMaterial.new()
	for i in arena.decoration_count if not arena.decorations.is_empty() else 0:
		var sprite := Sprite2D.new()
		sprite.texture = arena.decorations[rng.randi() % arena.decorations.size()]
		sprite.scale = Vector2.ONE * rng.randf_range(0.28, 0.4)
		sprite.rotation = rng.randf_range(-0.4, 0.4)
		sprite.position = _random_away_from_center(rng)
		_decorations.add_child(sprite)
	for i in arena.candle_count:
		var candle := candle_scene.instantiate() as Node2D
		candle.position = _random_away_from_center(rng)
		(candle.get_node("Light") as PointLight2D).color = arena.candle_color
		_decorations.add_child(candle)


func _random_away_from_center(rng: RandomNumberGenerator) -> Vector2:
	for attempt in 20:
		var point := Vector2(rng.randf_range(decoration_rect.position.x, decoration_rect.end.x), rng.randf_range(decoration_rect.position.y, decoration_rect.end.y))
		if point.length() > 140.0:
			return point
	return decoration_rect.end


## Torce sui muri alto e basso (i muri visibili sono a y = ±484).
func _place_torches(per_wall: int, color: Color) -> void:
	for i in per_wall:
		var x := lerpf(-640.0, 640.0, (i + 0.5) / per_wall)
		for y in [-462.0, 462.0]:
			var torch := torch_scene.instantiate() as Node2D
			torch.position = Vector2(x, y)
			_torches.add_child(torch)
			(torch.get_node("Light") as PointLight2D).color = color


func _process(_delta: float) -> void:
	for i in _wand.slots.abilities.size():
		_hud.set_ability_progress(i, 1.0 if _player.has_shield() and _wand.slots.abilities[i].effect is ShieldEffect else _wand.progress_of(i))
	if not _extraction_timer.is_stopped():
		_hud.set_extraction_countdown(_extraction_timer.time_left)


func _on_enemy_died(enemy: Enemy) -> void:
	_sfx.play(&"enemy_die")
	# Exp e materiali restano a terra: contano solo quando il player li raccoglie (magnete).
	RunManager.register_kill(0)
	_pickup_pool.spawn_exp(enemy.global_position, enemy.data.exp_reward)
	_roll_drops(enemy)


func _roll_drops(enemy: Enemy) -> void:
	for entry in enemy.data.drops:
		var amount := entry.roll(_rng, _player.stats.drop_chance_multiplier)
		for i in amount:
			_pickup_pool.spawn_material(enemy.global_position, entry.material, 1)


func _on_exp_collected(amount: int) -> void:
	_sfx.play(&"pickup_exp")
	var total := amount * _player.stats.exp_multiplier + _exp_remainder
	var whole := floori(total)
	_exp_remainder = total - whole
	RunManager.add_exp(whole)


func _on_material_collected(material: MaterialData, amount: int) -> void:
	_sfx.play(&"pickup_item")
	RunManager.add_loot(material, amount)


func _open_extraction() -> void:
	var spawn_position := SpawnUtils.random_point_away(
		extraction_spawn_rect, _player.global_position, extraction_data.spawn_min_distance
	)
	_extraction_point.activate(spawn_position)
	_sfx.play(&"ui_select")
	if arena.boss_scene != null:
		_boss_timer.start(arena.boss_delay)


## Il boss compare arena.boss_delay secondi dopo l'apertura dell'estrazione, lontano dal player.
func _spawn_boss() -> void:
	if RunManager.state == RunManager.State.ENDED:
		return
	boss = arena.boss_scene.instantiate()
	boss.target = _player
	boss.position = SpawnUtils.random_point_away(extraction_spawn_rect, _player.global_position, arena.boss_spawn_min_distance)
	_enemies.add_child(boss)
	boss.shot_requested.connect(_enemy_projectile_pool.spawn)
	boss.shot_requested.connect(_sfx.play.bind(&"enemy_shoot").unbind(3))
	boss.hurt.connect(_sfx.play.bind(&"enemy_hit").unbind(1))
	boss.attack_started.connect(_on_boss_attack_started)
	boss.slammed.connect(_sfx.play.bind(&"boss_slam").unbind(2))
	boss.health.changed.connect(_hud.set_boss_hp)
	boss.died.connect(_on_boss_died)
	_hud.show_boss(boss.data.display_name, boss.health.current, boss.health.max_hp)
	_sfx.play(&"boss_appear")


func _on_boss_attack_started(attack: BossAttack) -> void:
	if attack.kind == BossAttack.Kind.LEAP_SLAM:
		_sfx.play(&"boss_warn")


func _on_boss_died(dead: Boss) -> void:
	boss_defeated = true
	_hud.hide_boss()
	_sfx.play(&"enemy_die")
	RunManager.register_kill(0)
	# Exp in piu' gemme e drop garantiti: si raccolgono come quelli dei nemici (magnete).
	for i in 6:
		_pickup_pool.spawn_exp(dead.global_position, ceili(dead.data.exp_reward / 6.0))
	for entry in dead.data.drops:
		for i in entry.roll(_rng, _player.stats.drop_chance_multiplier):
			_pickup_pool.spawn_material(dead.global_position, entry.material, 1)
	dead.queue_free()
	boss = null


func _on_extracted() -> void:
	RunManager.end_run(RunManager.Result.EXTRACTED)


func _on_leveled_up(_level: int) -> void:
	_sfx.play(&"level_up")
	_pending_level_ups += 1
	if RunManager.state == RunManager.State.RUNNING:
		RunManager.begin_level_up()
		_present_level_up()


func _present_level_up() -> void:
	_level_up_choice.present(upgrade_table.pick(choices_per_level, _rng))


func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	_player.apply_upgrade(upgrade)
	_hud.set_stats(_player.stats, _player.weapon_data())
	_pickup_pool.attract_radius = _player.stats.pickup_radius
	_pending_level_ups -= 1
	if _pending_level_ups > 0:
		_present_level_up()
	else:
		RunManager.end_level_up()


func _on_player_died() -> void:
	RunManager.end_run(RunManager.Result.DEATH)


func _on_run_state_changed(state: RunManager.State) -> void:
	_pause.enabled = state == RunManager.State.RUNNING and not _choosing_ability
	_refresh_pause()


func _on_pause_mode_changed(mode: PauseState.Mode) -> void:
	_pause_menu.set_can_load(MetaProgression.has_save())
	_pause_menu.set_unsaved_changes(MetaProgression.has_unsaved_changes)
	_pause_menu.show_mode(mode)
	if mode == PauseState.Mode.INVENTORY:
		_run_inventory.present(MetaProgression.equipped_items(), RunManager.loot.to_dictionary())
	else:
		_run_inventory.close()
	_refresh_pause()


## Cambio lingua in run: salva i progressi permanenti (la run si perde) e torna al menu iniziale.
func _on_language_requested(locale: String) -> void:
	MetaProgression.clear_hub_position()
	GameSession.change_language(get_tree(), locale)


func _on_save_requested() -> void:
	# In run si salvano solo i progressi permanenti: al caricamento si riparte dall'ingresso della piazza.
	MetaProgression.clear_hub_position()
	var ok := GameSession.save()
	_pause_menu.show_status(tr("SAVE_OK_RUN") if ok else tr("SAVE_FAIL"))
	_pause_menu.set_can_load(MetaProgression.has_save())
	_pause_menu.set_unsaved_changes(MetaProgression.has_unsaved_changes)
	_sfx.play(&"ui_select")


## Due fonti di pausa: lo stato della run (level-up, fine run) e le pause del giocatore (ESC, P).
func _refresh_pause() -> void:
	get_tree().paused = RunManager.state != RunManager.State.RUNNING or _pause.state.is_paused() or _choosing_ability


func _on_run_ended(result: RunManager.Result) -> void:
	_pending_level_ups = 0
	_level_up_choice.hide()
	var extracted := result == RunManager.Result.EXTRACTED
	_sfx.play(&"extract" if extracted else &"player_death")
	if extracted:
		MetaProgression.register_extraction(arena.id)
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
