class_name RunEventDirector
extends Node2D
## Fa partire gli eventi dell'arena ai tempi di ArenaData.event_times e ne applica le regole
## (Tempesta di fulmini, Pentagramma di sangue). Comunica via segnali: la composition root (Arena)
## mostra i testi, gestisce i mostri in piu' e da' le ricompense.

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
const STRIKE_COLOR := Color(0.5, 0.8, 1.0)
const POOL_SIZE := 8

var events: Array[RunEventData] = []
var times: PackedFloat32Array = []
var player: Player
var bounds: Rect2 = Rect2(-760, -460, 1520, 920)
var current: RunEventData
var state := RunEventState.new()
var pentagram_state := PentagramState.new()
var _elapsed: float = 0.0
var _fired: int = 0
var _last: RunEventData
var _strike_timer: float = 0.0
var _strikes: Array[Telegraph] = []
var _pentagram: Pentagram
var _lit: int = 0
var _rng := RandomNumberGenerator.new()


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


func setup(arena: ArenaData, for_player: Player) -> void:
	events = arena.events
	times = arena.event_times
	player = for_player
	player.health.damaged.connect(_on_player_damaged.unbind(1))


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


func _physics_process(delta: float) -> void:
	if events.is_empty() or player == null:
		return
	_elapsed += delta
	if current == null:
		var next := RunEventState.next_time(times, _fired)
		if next >= 0.0 and _elapsed >= next:
			_start(_pick_event())
		return
	match current.kind:
		RunEventData.Kind.LIGHTNING_STORM:
			_tick_storm(delta)
		RunEventData.Kind.BLOOD_PENTAGRAM:
			_tick_pentagram(delta)


## A caso tra gli eventi dell'arena, evitando di ripetere l'ultimo se ce n'e' piu' d'uno.
func _pick_event() -> RunEventData:
	var pool: Array[RunEventData] = events.filter(func(e: RunEventData) -> bool: return e != _last or events.size() == 1)
	return pool[_rng.randi_range(0, pool.size() - 1)]


func _start(event: RunEventData) -> void:
	_fired += 1
	current = event
	_last = event
	if event.kind == RunEventData.Kind.BLOOD_PENTAGRAM:
		var at := SpawnUtils.random_point_away(bounds.grow(-event.circle_radius - 30.0), player.global_position, event.min_player_distance)
		pentagram_state.start(event.activation_timeout, event.duration, event.candle_count)
		_lit = event.candle_count
		_pentagram.setup(at, event.circle_radius, event.candle_count)
	else:
		state.start(event.duration)
		_strike_timer = 0.6
	event_started.emit(event)


func _tick_storm(delta: float) -> void:
	_strike_timer -= delta
	if _strike_timer <= 0.0:
		_strike_timer = current.strike_interval
		_spawn_strike()
	event_progress.emit(state.remaining_ratio())
	if state.tick(delta) == RunEventState.Status.COMPLETED:
		_finish(true)


func _tick_pentagram(delta: float) -> void:
	var inside := player.global_position.distance_to(_pentagram.global_position) <= current.circle_radius
	var before := pentagram_state.status
	var status := pentagram_state.tick(delta, inside)
	if before == PentagramState.Status.WAITING and status == PentagramState.Status.ACTIVE:
		_pentagram.active = true
		event_activated.emit(current)
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


func _spawn_strike() -> void:
	var target := player.global_position
	if _rng.randf() > current.aimed_chance:
		target += Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(40.0, current.strike_spread)
	target = target.clamp(bounds.position, bounds.end)
	for strike in _strikes:
		if not strike.is_running():
			strike.start(target, current.strike_radius, current.strike_telegraph, current.strike_damage, 300.0)
			return


## La Tempesta fallisce al primo colpo subito; il Pentagramma no (conta solo restare nel cerchio).
func _on_player_damaged() -> void:
	if current != null and current.kind == RunEventData.Kind.LIGHTNING_STORM and state.status == RunEventState.Status.RUNNING:
		state.fail()
		_finish(false)


func _on_strike_finished(_strike: Telegraph) -> void:
	strike_landed.emit()


## Fine evento: fulmini gia' annunciati spenti senza colpire, pentagramma nascosto.
func _finish(success: bool) -> void:
	var event := current
	current = null
	for strike in _strikes:
		strike.stop()
	_pentagram.hide()
	if success:
		event_completed.emit(event)
	else:
		event_failed.emit(event)
