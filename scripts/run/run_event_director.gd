class_name RunEventDirector
extends Node2D
## Fa partire gli eventi dell'arena ai tempi di ArenaData.event_times e ne applica le regole
## (Tempesta di fulmini, Pentagramma di sangue, Passo d'ombra). Comunica via segnali: la composition root (Arena)
## mostra i testi, gestisce i mostri in piu' e da' le ricompense.
## Pentagramma di sangue (M13, #86): non piu' a tempo casuale. Statua e candele spente compaiono una
## volta sola a inizio run in un punto fisso dell'arena (vedi setup()); interagendo con la statua
## (PentagramStatue.interacted) l'evento parte subito.

signal event_started(event: RunEventData)
## Pentagramma: il player e' entrato nel cerchio (parte l'ondata di mostri in rage).
signal event_activated(event: RunEventData)
signal event_progress(ratio: float)
signal event_completed(event: RunEventData)
signal event_failed(event: RunEventData)
signal strike_landed
signal candle_out

const TELEGRAPH := preload("res://scenes/run/Telegraph/Telegraph.tscn")
const PENTAGRAM := preload("res://scenes/run/Pentagram/Pentagram.tscn")
const PENTAGRAM_STATUE := preload("res://scenes/run/PentagramStatue/PentagramStatue.tscn")
const SKELETON_CLOSET := preload("res://scenes/run/Enemies/SkeletonCloset/SkeletonCloset.tscn")
## Giallo: si distingue dai fulmini azzurri del Fulmine errante (M11.4, #82).
const STRIKE_COLOR := Color(1.0, 0.85, 0.25)
const POOL_SIZE := 8

## Eventi a tempo (esclude il Pentagramma: vedi pentagram_event).
var events: Array[RunEventData] = []
var times: PackedFloat32Array = []
var player: Player
var bounds: Rect2 = Rect2(-760, -460, 1520, 920)
var current: RunEventData
var state := RunEventState.new()
var pentagram_state := PentagramState.new()
## Dati del Pentagramma, se l'arena ne ha uno (null altrimenti). Non fa parte di `events`/`times`:
## parte dall'interazione con la statua, non da un tempo fisso.
var pentagram_event: RunEventData
var _elapsed: float = 0.0
var _fired: int = 0
## Evento accodato (dopo il boss): secondi rimasti, -1 = nessuno. Non consuma i tempi fissi.
var _queued_left: float = -1.0
var _last: RunEventData
var _strike_timer: float = 0.0
var _strikes: Array[Telegraph] = []
var _pentagram: Pentagram
var _statue: PentagramStatue
var _lit: int = 0
var _rng := RandomNumberGenerator.new()
## Scheletri nell'armadio (M12, #86): bersaglio fisso (centro del cerchio, non il player) e gli
## scheletri attivi, ripuliti a fine evento (successo o fallimento).
var _skeleton_target: Node2D
var _skeletons: Array[Enemy] = []


func _ready() -> void:
	_rng.randomize()
	for i in POOL_SIZE:
		var strike: Telegraph = TELEGRAPH.instantiate()
		strike.color = STRIKE_COLOR
		strike.lightning = true
		strike.top_level = true
		strike.finished.connect(_on_strike_finished)
		add_child(strike)
		_strikes.append(strike)
	_pentagram = PENTAGRAM.instantiate()
	_pentagram.top_level = true
	add_child(_pentagram)
	_statue = PENTAGRAM_STATUE.instantiate()
	_statue.top_level = true
	_statue.interacted.connect(_on_statue_interacted)
	add_child(_statue)
	_skeleton_target = Node2D.new()
	add_child(_skeleton_target)


func setup(arena: ArenaData, for_player: Player) -> void:
	events = arena.events.filter(func(e: RunEventData) -> bool: return e.kind != RunEventData.Kind.BLOOD_PENTAGRAM)
	times = arena.event_times
	player = for_player
	player.health.damaged.connect(_on_player_damaged.unbind(1))
	pentagram_event = null
	for event in arena.events:
		if event.kind == RunEventData.Kind.BLOOD_PENTAGRAM:
			pentagram_event = event
			break
	if pentagram_event != null:
		var at := SpawnUtils.random_point_away(bounds.grow(-pentagram_event.circle_radius - 30.0), player.global_position, pentagram_event.min_player_distance, pentagram_event.max_player_distance)
		_pentagram.setup(at, pentagram_event.circle_radius, pentagram_event.candle_count)
		_pentagram.set_lit(0)
		_statue.place(at)


func is_running() -> bool:
	return current != null


## Cerchi dei fulmini in arrivo (centro x,y e raggio z), per il bot di playtest.
func danger_zones() -> Array[Vector3]:
	var zones: Array[Vector3] = []
	for strike in _strikes:
		if strike.is_running():
			zones.append(Vector3(strike.global_position.x, strike.global_position.y, strike.radius))
	return zones


## Pentagramma in attesa o attivo (centro x,y e raggio z; z = 0 se non c'e'), per il bot di playtest.
func pentagram_zone() -> Vector3:
	if current != null and current.kind == RunEventData.Kind.BLOOD_PENTAGRAM:
		return Vector3(_pentagram.global_position.x, _pentagram.global_position.y, current.circle_radius)
	return Vector3.ZERO


## Statua non ancora attivata (centro x,y e raggio z di interazione; z = 0 se gia' consumata o
## se l'arena non ha il Pentagramma), per il bot di playtest e per l'icona su mappa/minimappa.
func pentagram_statue_zone() -> Vector3:
	if pentagram_event != null and not _statue.consumed:
		return Vector3(_statue.global_position.x, _statue.global_position.y, PentagramStatue.INTERACT_RADIUS)
	return Vector3.ZERO


func _physics_process(delta: float) -> void:
	if player == null:
		return
	# Il Pentagramma va avanti (o e' in corso) anche se non c'e' nessun evento a tempo nell'arena:
	# parte dall'interazione con la statua, non dal ciclo qui sotto (M13, #86).
	if current != null:
		match current.kind:
			RunEventData.Kind.LIGHTNING_STORM:
				_tick_storm(delta)
			RunEventData.Kind.BLOOD_PENTAGRAM:
				_tick_pentagram(delta)
			RunEventData.Kind.SHADOW_STEP:
				_tick_timed(delta)
			RunEventData.Kind.SKELETONS_CLOSET:
				_tick_timed(delta)
		return
	if events.is_empty():
		return
	_elapsed += delta
	if _queued_left >= 0.0:
		_queued_left -= delta
		if _queued_left <= 0.0:
			_queued_left = -1.0
			_start(_pick_event(), false)
			return
	var next := RunEventState.next_time(times, _fired)
	if next >= 0.0 and _elapsed >= next:
		_start(_pick_event())


## A caso tra gli eventi dell'arena, evitando di ripetere l'ultimo se ce n'e' piu' d'uno.
func _pick_event() -> RunEventData:
	var pool: Array[RunEventData] = events.filter(func(e: RunEventData) -> bool: return e != _last or events.size() == 1)
	return pool[_rng.randi_range(0, pool.size() - 1)]


## Evento in piu' tra `delay` secondi (se in quel momento ne e' in corso un altro, parte appena finisce).
func queue_event(delay: float) -> void:
	_queued_left = maxf(delay, 0.001)


func has_queued_event() -> bool:
	return _queued_left >= 0.0


## Statua del Pentagramma interagita: parte subito, se non c'e' gia' un altro evento in corso
## (la statua si e' gia' resa non interagibile da sola, vedi PentagramStatue.consume()).
func _on_statue_interacted() -> void:
	if current != null:
		return
	_start(pentagram_event, false)


## timed = uno dei tempi fissi di event_times (li conta); falso per gli eventi accodati o per il Pentagramma
## (parte dall'interazione con la statua, non consuma un tempo fisso).
func _start(event: RunEventData, timed: bool = true) -> void:
	if timed:
		_fired += 1
	current = event
	_last = event
	if event.kind == RunEventData.Kind.BLOOD_PENTAGRAM:
		pentagram_state.start(event.candle_count, event.candles_start_extinguish_after)
		_lit = event.candle_count
		_pentagram.active = true
		_pentagram.set_lit(_lit)
	else:
		state.start(event.duration)
		_strike_timer = 0.6
		if event.kind == RunEventData.Kind.SHADOW_STEP:
			player.start_dash_mode(event)
		elif event.kind == RunEventData.Kind.SKELETONS_CLOSET:
			_spawn_skeletons(event)
	event_started.emit(event)
	if event.kind == RunEventData.Kind.BLOOD_PENTAGRAM:
		# Niente attesa di ingresso (M13, #86): l'interazione con la statua e' gia' l'attivazione.
		event_activated.emit(event)


func _tick_storm(delta: float) -> void:
	_strike_timer -= delta
	if _strike_timer <= 0.0:
		_strike_timer = current.strike_interval
		_spawn_strike()
	event_progress.emit(state.remaining_ratio())
	if state.tick(delta) == RunEventState.Status.COMPLETED:
		_finish(true)


## Passo d'ombra: dura `duration` secondi; come la Tempesta fallisce al primo colpo.
func _tick_timed(delta: float) -> void:
	event_progress.emit(state.remaining_ratio())
	if state.tick(delta) == RunEventState.Status.COMPLETED:
		_finish(true)


func _tick_pentagram(delta: float) -> void:
	var inside := player.global_position.distance_to(_pentagram.global_position) <= current.circle_radius
	var status := pentagram_state.tick(delta, inside)
	var lit := pentagram_state.candles_lit()
	if status == PentagramState.Status.ACTIVE and lit < _lit:
		candle_out.emit()
	_lit = lit
	_pentagram.set_lit(lit)
	event_progress.emit(pentagram_state.remaining_ratio())
	if status == PentagramState.Status.COMPLETED:
		_finish(true)
	elif status == PentagramState.Status.FAILED:
		_finish(false)


## Scheletri sul cerchio attorno al player: puntano al centro fisso (posizione del player ora),
## non lo inseguono (M12, #86).
func _spawn_skeletons(event: RunEventData) -> void:
	_skeleton_target.global_position = player.global_position
	for i in event.skeleton_count:
		var angle := TAU * i / float(maxi(event.skeleton_count, 1))
		var pos := player.global_position + Vector2.RIGHT.rotated(angle) * event.skeleton_spawn_radius
		# Raggio grande (M12, #86): puo' uscire dall'arena, come i fulmini della Tempesta lo teniamo
		# dentro i confini (bounds) invece di farlo comparire fuori muro o nel vuoto.
		pos = pos.clamp(bounds.position, bounds.end)
		var skeleton: Enemy = SKELETON_CLOSET.instantiate()
		skeleton.data = event.skeleton_enemy
		add_child(skeleton)
		skeleton.target = _skeleton_target
		skeleton.activate(pos)
		_skeletons.append(skeleton)


func _clear_skeletons() -> void:
	for skeleton in _skeletons:
		if is_instance_valid(skeleton):
			skeleton.queue_free()
	_skeletons.clear()


func _spawn_strike() -> void:
	var target := player.global_position
	if _rng.randf() > current.aimed_chance:
		target += Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(40.0, current.strike_spread)
	target = target.clamp(bounds.position, bounds.end)
	for strike in _strikes:
		if not strike.is_running():
			strike.start(target, current.strike_radius, current.strike_telegraph, current.strike_damage, 300.0)
			return


## Tempesta e Passo d'ombra falliscono al primo colpo subito; il Pentagramma no (conta solo restare nel cerchio).
func _on_player_damaged() -> void:
	if current != null and current.kind != RunEventData.Kind.BLOOD_PENTAGRAM and state.status == RunEventState.Status.RUNNING:
		state.fail()
		_finish(false)


func _on_strike_finished(_strike: Telegraph) -> void:
	strike_landed.emit()


## Fine evento: fulmini gia' annunciati spenti senza colpire. Il Pentagramma resta un monumento fisso
## dell'arena (mai nascosto): solo le candele si spengono, come al termine naturale del completamento.
func _finish(success: bool) -> void:
	var event := current
	current = null
	for strike in _strikes:
		strike.stop()
	if event.kind == RunEventData.Kind.BLOOD_PENTAGRAM:
		_pentagram.active = false
		_pentagram.set_lit(0)
	if event.kind == RunEventData.Kind.SHADOW_STEP:
		player.stop_dash_mode()
	elif event.kind == RunEventData.Kind.SKELETONS_CLOSET:
		_clear_skeletons()
	if success:
		event_completed.emit(event)
	else:
		event_failed.emit(event)
