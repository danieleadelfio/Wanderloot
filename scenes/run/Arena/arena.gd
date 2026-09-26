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
## Stillicidio dal soffitto + pozzanghera/pozza che cresce (M12, #86): vedi ArenaData.drip_spots.
@export var drip_scene: PackedScene = preload("res://scenes/run/EnvironmentDrip/EnvironmentDrip.tscn")
## Zona in cui spargere decorazioni e candele (lontano dal centro, dove parte il player).
@export var decoration_rect: Rect2 = Rect2(-740.0, -440.0, 1480.0, 880.0)
## Torce per lato lungo (muro alto e basso), distribuite in modo uniforme.

var arena: ArenaData
var extraction_data: ExtractionData
var _enemy_pools: Array[EnemyPool] = []
var _pending_level_ups: int = 0
## Modificatori dell'equip indossato, letti una volta a inizio run (M12, #86): per isolare il bonus
## dell'equip nella schermata statistiche a tre numeri (HUD e inventario di run).
var _equip_modifiers: Array[StatModifier] = []
## Livello arena da potenza dell'equip (M12, #86): letto una volta a inizio run come _equip_modifiers,
## l'armadio non lo cambia (non e' equip permanente). Scala vita nemici, ritmo di spawn, boss e drop.
var arena_level: int = 1
var _current_choice_count: int = 0
## Volte scelto ogni upgrade in questa run (Ventaglio, M12 #86: tetto max_picks). Chiave = risorsa
## upgrade stessa (Resource, non copiata: quella in UpgradeTable.upgrades).
var _upgrade_picks: Dictionary[UpgradeData, int] = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Exp frazionaria dovuta al moltiplicatore "Saggezza", accumulata fino all'unità successiva.
var _exp_remainder: float = 0.0

@onready var _player: Player = %Player
## Boss vivi della run (vuoto finche' non compaiono). Letto anche dal bot di playtest.
var bosses: Array[Boss] = []
## Boss in piu' guadagnati dagli eventi (Pentagramma di sangue).
var _extra_bosses: int = 0
var _bosses_spawned: bool = false
## Abilita' che gli eventi possono offrire (M10).
@export var ability_catalog: AbilityCatalog = preload("res://data/abilities/ability_catalog.tres")
## Materiali del Bag of Resources (#20): livelli oltre il cap sbloccato di un'abilita' diventano
## una quantita' fissa di un materiale a caso, invece di andare persi o superare il cap.
@export var over_cap_materials: Array[MaterialData] = []
const OVER_CAP_MATERIAL_AMOUNT: int = 10
## Onda d'urto alla rottura della Barriera arcana (M12, #86): raggio ed entita' della spinta.
const SHIELD_BREAK_RADIUS: float = 100.0
const SHIELD_BREAK_KNOCKBACK: float = 260.0
var _choosing_ability: bool = false
## Finestra dell'armadio aperta (evento Scheletri nell'armadio, M12 #86): stessa pausa di _choosing_ability.
var _choosing_closet: bool = false
## Spiegazione a schermo intero in pausa alla prima volta in assoluto (M12, #86): primo evento, primo
## avviso di overtime. A differenza degli altri _choosing_*, non blocca altro (niente scelte da fare),
## solo la run finche' non si preme Continua.
var _showing_first_time_notice: bool = false
## Effetti a tempo dei consumabili attivi: chiave di traduzione -> secondi rimasti (solo per l'HUD).
var _buffs: Dictionary = {}
var boss_defeated: bool = false
## Evento dopo il boss gia' accodato (una volta per run, M11.2).
var _boss_event_queued: bool = false
var _boss_timer := Timer.new()
## Overtime (M11.1): parte all'apertura dell'estrazione.
var overtime := OvertimeState.new()
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
@onready var _closet_reward: ClosetReward = %ClosetReward
@onready var _wand: WandAbilities = %WandAbilities
@onready var _ability_choice: AbilityChoice = %AbilityChoice
@onready var _events: RunEventDirector = %EventDirector
@onready var _first_time_notice: FirstTimeNotice = %FirstTimeNotice


func _ready() -> void:
	get_tree().paused = false
	CursorStyle.use_crosshair()
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
	_pause_menu.abandon_requested.connect(_on_abandon_requested)
	_pause_menu.language_requested.connect(_on_language_requested)
	_first_time_notice.dismissed.connect(_on_first_time_notice_dismissed)
	_level_up_choice.upgrade_chosen.connect(_on_upgrade_chosen)
	_level_up_choice.reroll_requested.connect(_on_reroll_requested)
	_player.shot_requested.connect(_projectile_pool.spawn)
	_player.health.changed.connect(_hud.set_hp)
	_player.died.connect(_on_player_died)
	_player.health.damaged.connect(_hit_stop.trigger)
	_player.health.damaged.connect(_sfx.play.bind(&"player_hurt").unbind(1))
	_player.shot_requested.connect(_sfx.play.bind(&"shoot").unbind(3))
	_player.shield_broken.connect(_on_shield_broken)
	# Equip letto una volta a inizio run: cambiarlo nell'hub vale solo dalla run successiva.
	_equip_modifiers = MetaProgression.equipped_modifiers()
	arena_level = ArenaLevel.level_for(MetaProgression.loadout.equipped_items())
	_wave_spawner.level_hp = ArenaLevel.enemy_hp_multiplier(arena_level)
	_wave_spawner.level_rate = ArenaLevel.spawn_rate_multiplier(arena_level)
	_hud.set_arena_level(arena_level)
	_player.begin_run(_equip_modifiers)
	_hud.set_hp(_player.health.current, _player.health.max_hp)
	_hud.set_stats(_player, _equip_modifiers)
	# In pausa finche' non si preme Continua, come gli eventi (M12, #86): prima spariva da sola dopo
	# 7s con HUD.announce(), a volte prima che si finisse di leggere o si fosse anche solo mossi.
	if not MetaProgression.has_seen_tutorial(&"first_run"):
		_show_first_time_notice(&"first_run", tr("TUTORIAL_RUN_TITLE"), tr("TUTORIAL_RUN_BODY"))
	_create_enemy_pools()
	_wand.setup(_player, _projectile_pool, targetable_enemies)
	_wand.changed.connect(func(abilities: Array[WandAbility]) -> void: _hud.set_abilities(abilities, _wand.levels))
	_wand.over_cap.connect(_on_ability_over_cap)
	for ability in ability_catalog.abilities:
		_wand.caps[ability.id] = MetaProgression.ascension_cap(ability.id)
	for entry: Array in MetaProgression.equipped_ability_levels().values():
		_wand.equip_bonus(entry[0], entry[1])
	_ability_choice.resolved.connect(_on_ability_resolved)
	_events.bounds = extraction_spawn_rect
	_events.setup(arena, _player)
	_events.event_started.connect(_on_event_started)
	_player.dashed.connect(_sfx.play.bind(&"dash"))
	_events.event_progress.connect(_hud.set_event_progress)
	_events.event_completed.connect(_on_event_completed)
	_events.event_failed.connect(_on_event_failed)
	_events.event_activated.connect(_on_event_activated)
	_events.candle_out.connect(_sfx.play.bind(&"candle_out"))
	_closet_reward.item_chosen.connect(_on_closet_item_chosen)
	_events.strike_landed.connect(_sfx.play.bind(&"lightning"))
	_pickup_pool.target = _player
	_enemy_projectile_pool.pull_target = _player
	_pickup_pool.attract_radius = _player.stats.pickup_radius
	_pickup_pool.exp_collected.connect(_on_exp_collected)
	_pickup_pool.material_collected.connect(_on_material_collected)
	_pickup_pool.consumable_collected.connect(_on_consumable_collected)
	_pickup_pool.item_collected.connect(_on_item_collected)
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
	overtime.warned.connect(_on_overtime_warned)
	overtime.level_changed.connect(_on_overtime_level)
	overtime.boss_due.connect(_spawn_bosses)
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
	for alive in bosses:
		zones.append_array(alive.danger_zones())
	return zones


## Pentagramma in attesa o attivo, per il bot di playtest (z = 0 se non c'e').
func pentagram_zone() -> Vector3:
	return _events.pentagram_zone()


## Chiave Codex (obiettivo + ricompensa, gia' scritta e mantenuta li') per il tutorial di ogni evento.
const EVENT_CODEX_BODY: Dictionary[StringName, StringName] = {
	&"lightning_storm": &"CODEX_EVENT_LIGHTNING_BODY",
	&"blood_pentagram": &"CODEX_EVENT_PENTAGRAM_BODY",
	&"shadow_step": &"CODEX_EVENT_SHADOWSTEP_BODY",
	&"skeletons_closet": &"CODEX_EVENT_CLOSET_BODY",
}


func _on_event_started(event: RunEventData) -> void:
	_hud.show_event(event.title, event.subtitle)
	_sfx.play(&"event_start")
	# Ogni evento mai incontrato prima, non solo il primo in assoluto (M12, #86): pausa con spiegazione
	# a schermo intero (obiettivo + ricompensa, stesso testo del Codex) invece del solo annuncio a
	# scomparsa, per lasciare il tempo di leggere senza essere colpiti nel frattempo.
	var tutorial_key := StringName("event_%s" % event.id)
	if not MetaProgression.has_seen_tutorial(tutorial_key) and EVENT_CODEX_BODY.has(event.id):
		_show_first_time_notice(tutorial_key, tr(event.title), tr(EVENT_CODEX_BODY[event.id]))


## Pentagramma: il player e' nel cerchio. Mostri +bonus subito, tetto dei vivi +bonus, nuovi mostri in rage.
func _on_event_activated(event: RunEventData) -> void:
	_hud.set_event_subtitle(tr("EVENT_PENTAGRAM_HOLD"))
	_wave_spawner.surge_multiplier = 1.0 + event.monster_bonus
	_wave_spawner.spawn_raged = event.spawn_raged
	_wave_spawner.burst(maxi(ceili(_wave_spawner.active_count() * event.monster_bonus), 5))
	_sfx.play(&"boss_warn")


func _end_surge() -> void:
	_wave_spawner.surge_multiplier = 1.0
	_wave_spawner.spawn_raged = false


func _on_event_completed(event: RunEventData) -> void:
	_end_surge()
	_hud.end_event(true, tr("EVENT_PENTAGRAM_REWARD") if event.bonus_bosses > 0 else "")
	if event.bonus_bosses > 0 and arena.has_boss():
		_extra_bosses += event.bonus_bosses
		_refresh_overtime_bosses()
		# Boss gia' comparsi: quello in piu' arriva subito, altrimenti si aggiunge alla comparsa.
		if _bosses_spawned:
			_spawn_bosses(event.bonus_bosses)
	if event.reward_choices > 0:
		offer_abilities(event.reward_choices)
	if event.kind == RunEventData.Kind.SKELETONS_CLOSET:
		_open_closet_reward(event)


## Armadio dell'evento Scheletri nell'armadio (M12, #86): pezzi mai estratti, a caso tra quelli
## disponibili (closet_choices, o meno se ne restano meno nel catalogo).
func _open_closet_reward(event: RunEventData) -> void:
	var pool := MetaProgression.undiscovered_equipment()
	if pool.is_empty():
		return
	var candidates: Array[ItemInstance] = []
	for i in mini(event.closet_choices, pool.size()):
		var index := _rng.randi_range(0, pool.size() - 1)
		candidates.append(MetaProgression.make_item(pool[index], 0))
		pool.remove_at(index)
	_choosing_closet = true
	_pause.enabled = false
	_refresh_pause()
	_closet_reward.present(MetaProgression.loadout, candidates)


## Il pezzo scelto si equipaggia subito per il resto della run (a rischio come ogni loot: si perde
## se si muore senza estrarre). Stesso trattamento dell'equip preso in hub: modificatori sulle stats
## correnti e, se l'oggetto ha un'abilita', alla bacchetta.
func _on_closet_item_chosen(item: ItemInstance) -> void:
	_choosing_closet = false
	_pause.enabled = RunManager.state == RunManager.State.RUNNING
	_refresh_pause()
	RunManager.add_loot_item(item)
	var modifiers := item.modifiers()
	_equip_modifiers.append_array(modifiers)
	_player.apply_equipment(modifiers)
	if item.ability:
		_wand.equip_bonus(item.ability, item.ability_level(MetaProgression.rarity_table))
	_hud.set_stats(_player, _equip_modifiers)
	_sfx.play(&"pickup_item")


func _on_event_failed(event: RunEventData) -> void:
	_end_surge()
	_hud.end_event(false, tr("EVENT_PENTAGRAM_FAILED_HINT") if event.kind == RunEventData.Kind.BLOOD_PENTAGRAM else "")


## Nemici e boss colpibili dalle abilita' della bacchetta.
func targetable_enemies() -> Array[Node2D]:
	var result: Array[Node2D] = []
	result.assign(active_enemies())
	result.append_array(bosses)
	return result


## Ricompensa degli eventi: il gioco si ferma e si sceglie un'abilita'; quelle gia' possedute salgono di livello.
func offer_abilities(count: int = 3) -> void:
	var options := ability_catalog.pick(count, [] as Array[StringName], _rng)
	if options.is_empty() or RunManager.state != RunManager.State.RUNNING:
		return
	_choosing_ability = true
	_pause.enabled = false
	_refresh_pause()
	_ability_choice.present(options, _wand.slots.abilities, _wand.slots.is_full(), _wand.levels, _wand.caps)


func _on_ability_resolved(ability: WandAbility, replace_index: int) -> void:
	_choosing_ability = false
	_pause.enabled = RunManager.state == RunManager.State.RUNNING
	if ability != null and _wand.equip(ability, replace_index):
		# Le abilita' a ricarica partono cariche (es. Barriera arcana attiva subito).
		if ability.trigger == WandAbility.Trigger.COOLDOWN and ability.effect:
			ability.effect.activate(_wand, _wand.level_of(ability))
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
	_place_drips()
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


## Stillicidio dal soffitto (Cripta: pozzanghera d'acqua; Ossario: pozza di sangue), M12 #86: punti
## fissi dell'arena, colore da ArenaData.drip_color. Vuoto = nessuno.
func _place_drips() -> void:
	for spot in arena.drip_spots:
		var drip := drip_scene.instantiate() as Node2D
		drip.position = spot
		var stain := drip.get_node("Stain") as GrowingStain
		stain.set_stain_color(arena.drip_color)
		_decorations.add_child(drip)


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


func _process(delta: float) -> void:
	if not get_tree().paused and not _buffs.is_empty():
		for key in _buffs.keys():
			_buffs[key] -= delta
			if _buffs[key] <= 0.0:
				_buffs.erase(key)
		_hud.set_buffs(_buffs)
	var owned := _wand.all_abilities()
	for i in owned.size():
		_hud.set_ability_progress(i, 1.0 if _player.has_shield() and owned[i].effect is ShieldEffect else _wand.progress_of(i))
	if not _extraction_timer.is_stopped():
		_hud.set_extraction_countdown(_extraction_timer.time_left)


func _on_enemy_died(enemy: Enemy) -> void:
	_sfx.play(&"enemy_die")
	# Exp e materiali restano a terra: contano solo quando il player li raccoglie (magnete).
	RunManager.register_kill(0)
	_pickup_pool.spawn_exp(enemy.global_position, enemy.data.exp_reward)
	_roll_drops(enemy)
	if arena.consumables:
		var consumable := arena.consumables.roll(_rng, _player.stats.drop_chance_multiplier)
		if consumable:
			_pickup_pool.spawn_consumable(enemy.global_position, consumable)
	if arena.item_drops:
		var base := arena.item_drops.roll(_rng, _player.stats.drop_chance_multiplier)
		if base:
			_drop_item(enemy.global_position, base, false)


## Oggetto trovato: rarita' tirata dalla tabella dell'arena, bonus tirati subito (resta a rischio fino all'estrazione).
func _drop_item(at: Vector2, base: EquipmentData, from_boss: bool) -> void:
	var level_max := ArenaLevel.max_drop_tier(arena_level, arena.item_drops.max_tier)
	var tier := arena.item_drops.roll_tier(MetaProgression.rarity_table, _rng, from_boss, level_max)
	var item := MetaProgression.make_item(base, tier)
	var rarity := MetaProgression.rarity_table.tier(tier)
	_pickup_pool.spawn_item(at, item, rarity.color, rarity.glow_scale)
	# Piu' e' raro, piu' il suono e' epico (M11.1).
	_sfx.play(rarity.drop_sound)


func _on_item_collected(item: ItemInstance) -> void:
	_sfx.play(&"pickup_item")
	RunManager.add_loot_item(item)


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


func _on_consumable_collected(consumable: ConsumableData) -> void:
	_sfx.play(&"power_up")
	match consumable.kind:
		ConsumableData.Kind.MAGNET:
			_pickup_pool.attract_all(consumable.duration)
		ConsumableData.Kind.HEAL:
			_player.health.heal(roundi(consumable.amount))
		ConsumableData.Kind.FRENZY:
			_player.boost_fire_rate(consumable.amount, consumable.duration)
	if consumable.duration > 0.0:
		_buffs[consumable.display_name] = consumable.duration


## Onda d'urto quando la Barriera arcana si esaurisce (M12, #86): respinge i nemici vicini, cosi'
## non si accumulano addosso al player nel breve momento di invulnerabilita' che segue la rottura.
func _on_shield_broken() -> void:
	for enemy in active_enemies():
		var offset := _player.global_position.direction_to(enemy.global_position)
		var distance := _player.global_position.distance_to(enemy.global_position)
		if distance > SHIELD_BREAK_RADIUS:
			continue
		if offset == Vector2.ZERO:
			offset = Vector2.RIGHT
		enemy.apply_knockback(offset * SHIELD_BREAK_KNOCKBACK)


func _on_material_collected(material: MaterialData, amount: int) -> void:
	_sfx.play(&"pickup_item")
	RunManager.add_loot(material, amount)


## Livelli oltre il cap sbloccato dell'abilita' (#20, Ascensione #16): Bag of Resources invece del
## livello, cosi' non si perde ne' si aggira il cap. Quantita' fissa per livello in eccesso.
func _on_ability_over_cap(_ability: WandAbility, overflow: int) -> void:
	if over_cap_materials.is_empty():
		return
	var material: MaterialData = over_cap_materials[_rng.randi_range(0, over_cap_materials.size() - 1)]
	RunManager.add_loot(material, overflow * OVER_CAP_MATERIAL_AMOUNT)


func _open_extraction() -> void:
	var spawn_position := SpawnUtils.random_point_away(
		extraction_spawn_rect, _player.global_position, extraction_data.spawn_min_distance
	)
	_extraction_point.activate(spawn_position)
	_sfx.play(&"ui_select")
	# Scritta come quella degli eventi, per far notare che si puo' estrarre (M12, #86): prima non c'era
	# alcun avviso e capitava di non accorgersi che l'estrazione era gia' aperta.
	_hud.announce(tr("EXTRACTION_OPEN_TITLE"), tr("EXTRACTION_OPEN_SUB"))
	if arena.has_boss():
		_boss_timer.start(arena.boss_delay)
	_refresh_overtime_bosses()
	overtime.start(arena.overtime)


func _physics_process(delta: float) -> void:
	if RunManager.state == RunManager.State.RUNNING and not get_tree().paused:
		overtime.tick(delta)


## Ondate di boss dell'overtime = boss della run (arena + guadagnati col Pentagramma, anche in overtime).
func _refresh_overtime_bosses() -> void:
	overtime.bosses_per_wave = maxi(arena.boss_count + _extra_bosses + ArenaLevel.boss_bonus(arena_level), 1)


func _on_overtime_warned(seconds: int, next_level: int) -> void:
	# Primo avviso di overtime in assoluto (M12, #86): pausa con spiegazione, come il primo evento.
	if not MetaProgression.has_seen_tutorial(&"first_overtime_warning"):
		_show_first_time_notice(&"first_overtime_warning", tr("TUTORIAL_OVERTIME_WARNING_TITLE"), tr("TUTORIAL_OVERTIME_WARNING_BODY") + "\n\n" + tr("OVERTIME_WARNING") % [next_level, seconds])
	else:
		_hud.announce(tr("OVERTIME_WARNING") % [next_level, seconds], tr("OVERTIME_WARNING_SUB"))
	_sfx.play(&"overtime_warn")


## Nuovo livello: nemici nuovi in rage, piu' veloci e resistenti; i boss arrivano da overtime.boss_due.
func _on_overtime_level(level: int) -> void:
	# L'overtime mescola sempre boss e nemici base (comportamento attuale): eventuali boss pre-overtime
	# ancora vivi non bloccano piu' lo spawn da qui in poi.
	_wave_spawner.spawning_blocked = false
	_wave_spawner.overtime_raged = arena.overtime.spawn_raged
	_wave_spawner.overtime_speed = overtime.speed_multiplier()
	_wave_spawner.overtime_hp = overtime.hp_multiplier()
	_wave_spawner.overtime_alive = overtime.max_alive_multiplier()
	_wave_spawner.overtime_rate = overtime.spawn_rate_multiplier()
	_hud.set_overtime(level)
	var subtitle := tr("OVERTIME_SUB") % [overtime.bosses_per_wave, snappedf(overtime.boss_interval(), 0.1), snappedf(overtime.speed_multiplier(), 0.1), roundi((overtime.hp_multiplier() - 1.0) * 100.0)]
	# Prima volta in assoluto (M12, #86): spiegazione estesa al posto del solo annuncio breve, dura di
	# piu' per lasciare tempo di leggere. Dal secondo livello in poi (o nelle run successive) resta il
	# solo annuncio normale.
	if level == 1 and not MetaProgression.has_seen_tutorial(&"first_overtime"):
		_hud.announce(tr("TUTORIAL_OVERTIME_TITLE"), tr("TUTORIAL_OVERTIME_BODY") + "\n\n" + subtitle, 8.0)
		MetaProgression.mark_tutorial_seen(&"first_overtime")
	else:
		_hud.announce(tr("OVERTIME_TITLE") % level, subtitle, 3.5)
	_sfx.play(&"overtime_start")


## I boss compaiono arena.boss_delay secondi dopo l'apertura dell'estrazione, lontano dal player
## e in punti diversi tra loro (boss_count + quelli guadagnati dagli eventi).
func _spawn_boss() -> void:
	_bosses_spawned = true
	_spawn_bosses(arena.boss_count + _extra_bosses + ArenaLevel.boss_bonus(arena_level))
	# Boss pre-overtime (Ossario, M12, #86): mentre sono vivi, niente nuovi nemici base finche' non
	# muoiono o non arriva l'overtime (che li mescola come ora, vedi _on_overtime_level). I nemici gia'
	# in giro a quel momento restano e vanno uccisi normalmente.
	if not bosses.is_empty():
		_wave_spawner.spawning_blocked = true


func _spawn_bosses(count: int) -> void:
	if RunManager.state == RunManager.State.ENDED or count <= 0 or not arena.has_boss():
		return
	var taken: Array[Vector2] = []
	for alive in bosses:
		taken.append(alive.global_position)
	var points := SpawnUtils.separated_points(extraction_spawn_rect, _player.global_position, arena.boss_spawn_min_distance, arena.boss_min_separation, count, _rng, taken)
	for point in points:
		var new_boss: Boss = arena.pick_boss_scene(_rng).instantiate()
		new_boss.bounds = extraction_spawn_rect
		new_boss.target = _player
		new_boss.position = point
		_enemies.add_child(new_boss)
		new_boss.shot_requested.connect(_enemy_projectile_pool.spawn)
		new_boss.shot_requested.connect(_sfx.play.bind(&"enemy_shoot").unbind(3))
		new_boss.hurt.connect(_sfx.play.bind(&"enemy_hit").unbind(1))
		new_boss.attack_started.connect(_on_boss_attack_started)
		new_boss.slammed.connect(_sfx.play.bind(&"boss_slam").unbind(2))
		new_boss.health.changed.connect(_refresh_boss_bar.unbind(2))
		new_boss.died.connect(_on_boss_died)
		new_boss.summon_requested.connect(_on_boss_summon, CONNECT_DEFERRED)
		new_boss.scream_requested.connect(_on_boss_scream)
		new_boss.teleported.connect(_sfx.play.bind(&"dash"))
		bosses.append(new_boss)
	_refresh_boss_bar()
	_sfx.play(&"boss_appear")


## Barra unica con la vita di tutti i boss vivi (nome "× N" se piu' d'uno).
func _refresh_boss_bar() -> void:
	if bosses.is_empty():
		_hud.hide_boss()
		return
	var current := 0
	var maximum := 0
	for alive in bosses:
		current += alive.health.current
		maximum += alive.health.max_hp
	# Boss diversi insieme: nomi separati; stesso boss piu' volte: nome x N.
	var names: PackedStringArray = []
	for alive in bosses:
		if not names.has(tr(alive.data.display_name)):
			names.append(tr(alive.data.display_name))
	var title := " · ".join(names)
	if names.size() == 1 and bosses.size() > 1:
		title += "  ×%d" % bosses.size()
	_hud.show_boss(title, current, maximum)


## Evocazione di un boss: nemici dal pool dell'arena della stessa scena, attorno al boss.
func _on_boss_summon(scene: PackedScene, count: int, at: Vector2) -> void:
	for i in arena.enemies.size():
		if arena.enemies[i].scene != scene:
			continue
		for k in count:
			var point := (at + Vector2.RIGHT.rotated(TAU * k / maxi(count, 1)) * _rng.randf_range(70.0, 130.0)).clamp(extraction_spawn_rect.position, extraction_spawn_rect.end)
			_enemy_pools[i].spawn(point, _player)
		_sfx.play(&"boss_warn")
		return


## Urlo di un boss: tutti i nemici vivi in rage.
func _on_boss_scream() -> void:
	for enemy in active_enemies():
		enemy.force_rage()
	_sfx.play(&"boss_appear")


func _on_boss_attack_started(attack: BossAttack) -> void:
	if attack.kind == BossAttack.Kind.LEAP_SLAM:
		_sfx.play(&"boss_warn")


func _on_boss_died(dead: Boss) -> void:
	bosses.erase(dead)
	boss_defeated = bosses.is_empty()
	if _wave_spawner.spawning_blocked and bosses.is_empty():
		_wave_spawner.spawning_blocked = false
	if boss_defeated and not _boss_event_queued and arena.boss_event_delay >= 0.0:
		_boss_event_queued = true
		_events.queue_event(arena.boss_event_delay)
	_refresh_boss_bar()
	_sfx.play(&"enemy_die")
	RunManager.register_kill(0)
	# Exp in piu' gemme e drop garantiti: si raccolgono come quelli dei nemici (magnete).
	for i in 6:
		_pickup_pool.spawn_exp(dead.global_position, ceili(dead.data.exp_reward / 6.0))
	for entry in dead.data.drops:
		for i in entry.roll(_rng, _player.stats.drop_chance_multiplier):
			_pickup_pool.spawn_material(dead.global_position, entry.material, 1)
	# Il boss lascia sempre due consumabili.
	if arena.consumables:
		for i in 2:
			var consumable := arena.consumables.pick(_rng)
			if consumable:
				_pickup_pool.spawn_consumable(dead.global_position, consumable)
	# Oggetti garantiti, almeno Rari (GDD §6.3).
	if arena.item_drops:
		for i in arena.item_drops.boss_drops:
			var base := arena.item_drops.pick(_rng)
			if base:
				_drop_item(dead.global_position, base, true)
	dead.queue_free()


func _on_extracted() -> void:
	RunManager.end_run(RunManager.Result.EXTRACTED)


func _on_leveled_up(_level: int) -> void:
	_sfx.play(&"level_up")
	_pending_level_ups += 1
	if RunManager.state == RunManager.State.RUNNING:
		RunManager.begin_level_up()
		_current_choice_count = choices_per_level
		_present_level_up()


func _present_level_up() -> void:
	_level_up_choice.present(upgrade_table.pick(_current_choice_count, _rng, _upgrade_picks), RunManager.rerolls_left())


## Reroll (M12, #86): una scelta in meno (minimo 1), consuma un reroll della run.
func _on_reroll_requested() -> void:
	if not RunManager.use_reroll():
		return
	_current_choice_count = maxi(_current_choice_count - 1, 1)
	_sfx.play(&"ui_select")
	_present_level_up()


func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	_upgrade_picks[upgrade] = _upgrade_picks.get(upgrade, 0) + 1
	_player.apply_upgrade(upgrade)
	_hud.set_stats(_player, _equip_modifiers)
	_pickup_pool.attract_radius = _player.stats.pickup_radius
	_pending_level_ups -= 1
	if _pending_level_ups > 0:
		_current_choice_count = choices_per_level
		_present_level_up()
	else:
		RunManager.end_level_up()


func _on_player_died() -> void:
	RunManager.end_run(RunManager.Result.DEATH)


func _on_run_state_changed(state: RunManager.State) -> void:
	_pause.enabled = state == RunManager.State.RUNNING and not _choosing_ability and not _choosing_closet
	_refresh_pause()


func _on_pause_mode_changed(mode: PauseState.Mode) -> void:
	_pause_menu.set_can_load(MetaProgression.has_save())
	_pause_menu.set_unsaved_changes(MetaProgression.has_unsaved_changes)
	_pause_menu.show_mode(mode)
	if mode == PauseState.Mode.INVENTORY:
		_run_inventory.present(MetaProgression.loadout, RunManager.loot.to_dictionary(), RunManager.loot.items(), _player, _equip_modifiers)
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
	get_tree().paused = RunManager.state != RunManager.State.RUNNING or _pause.state.is_paused() or _choosing_ability or _choosing_closet or _showing_first_time_notice
	# Mirino mentre si gioca, freccia nei menu (pausa, level-up, scelte, fine run).
	if get_tree().paused:
		CursorStyle.use_arrow()
	else:
		CursorStyle.use_crosshair()


## Spiegazione a schermo intero, in pausa, finche' non si preme Continua (M12, #86): usata solo la prima
## volta in assoluto per un dato tutorial_key, al posto del solo HUD.announce() che sparisce da solo
## mentre la run continua (non lascia il tempo di leggere con calma).
func _show_first_time_notice(tutorial_key: StringName, title: String, body: String) -> void:
	_showing_first_time_notice = true
	_first_time_notice.show_notice(title, body)
	MetaProgression.mark_tutorial_seen(tutorial_key)
	_refresh_pause()


func _on_first_time_notice_dismissed() -> void:
	_showing_first_time_notice = false
	_refresh_pause()


func _on_run_ended(result: RunManager.Result) -> void:
	_pending_level_ups = 0
	_level_up_choice.hide()
	_showing_first_time_notice = false
	_first_time_notice.hide()
	var extracted := result == RunManager.Result.EXTRACTED
	_sfx.play(&"extract" if extracted else &"player_death")
	if extracted:
		MetaProgression.register_extraction(arena.id)
	# Unico punto in cui il loot di run raggiunge MetaProgression (GDD §4).
	var items := RunManager.loot.items()
	var amounts: Dictionary = RunManager.loot.to_dictionary()
	var loot_amount := LootTransfer.resolve(extracted, RunManager.loot, MetaProgression.deposit_run_loot, MetaProgression.deposit_run_items)
	_run_end_screen.present(
		extracted, RunManager.level, RunManager.elapsed, RunManager.kills,
		loot_amount, MetaProgression.inventory.total(), items, amounts
	)


## Abbandona Run (ESC, M12, #86): come Carica/Torna al menu ma resta in gioco, verso l'hub invece
## del menu iniziale. Nessun esito: RunManager.abort_run() fa perdere il loot non estratto.
func _on_abandon_requested() -> void:
	RunManager.abort_run()
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(SceneRoutes.HUB)


func _on_restart_requested() -> void:
	# Si torna all'hub; la prossima run ricrea la scena Arena da zero (RunManager riparte da start_run()).
	# Autosave a ogni fine run, successo o game over (M12, #86): l'hub mostra il toast al suo _ready().
	MetaProgression.autosave()
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(SceneRoutes.HUB)


func _exit_tree() -> void:
	CursorStyle.use_arrow()
