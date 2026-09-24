class_name RunEventDirector
extends Node2D
## Fa partire gli eventi dell'arena ai tempi di ArenaData.event_times e ne gestisce le regole.
## Comunica via segnali: la composition root (Arena) mostra i testi e da' la ricompensa.

signal event_started(event: RunEventData)
signal event_progress(ratio: float)
signal event_completed(event: RunEventData)
signal event_failed(event: RunEventData)
signal strike_landed

const TELEGRAPH := preload("res://scenes/run/Telegraph/Telegraph.tscn")
const STRIKE_COLOR := Color(0.5, 0.8, 1.0)
const POOL_SIZE := 8

var events: Array[RunEventData] = []
var times: PackedFloat32Array = []
var player: Player
var bounds: Rect2 = Rect2(-760, -460, 1520, 920)
var current: RunEventData
var state := RunEventState.new()
var _elapsed: float = 0.0
var _fired: int = 0
var _strike_timer: float = 0.0
var _strikes: Array[Telegraph] = []
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


func setup(arena: ArenaData, for_player: Player) -> void:
	events = arena.events
	times = arena.event_times
	player = for_player
	player.health.damaged.connect(_on_player_damaged.unbind(1))


## Cerchi dei fulmini in arrivo (centro x,y e raggio z), per il bot di playtest.
func danger_zones() -> Array[Vector3]:
	var zones: Array[Vector3] = []
	for strike in _strikes:
		if strike.is_running():
			zones.append(Vector3(strike.global_position.x, strike.global_position.y, strike.radius))
	return zones


func _physics_process(delta: float) -> void:
	if events.is_empty() or player == null:
		return
	_elapsed += delta
	if state.status != RunEventState.Status.RUNNING:
		var next := RunEventState.next_time(times, _fired)
		if next >= 0.0 and _elapsed >= next:
			_start(events[_rng.randi_range(0, events.size() - 1)])
		return
	_strike_timer -= delta
	if _strike_timer <= 0.0:
		_strike_timer = current.strike_interval
		_spawn_strike()
	event_progress.emit(state.remaining_ratio())
	if state.tick(delta) == RunEventState.Status.COMPLETED:
		_end()
		event_completed.emit(current)


func _start(event: RunEventData) -> void:
	_fired += 1
	current = event
	state.start(event.duration)
	_strike_timer = 0.6
	event_started.emit(event)


func _spawn_strike() -> void:
	var target := player.global_position
	if _rng.randf() > current.aimed_chance:
		target += Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(40.0, current.strike_spread)
	target = target.clamp(bounds.position, bounds.end)
	for strike in _strikes:
		if not strike.is_running():
			strike.start(target, current.strike_radius, current.strike_telegraph, current.strike_damage, 300.0)
			return


func _on_player_damaged() -> void:
	if state.status == RunEventState.Status.RUNNING:
		state.fail()
		_end()
		event_failed.emit(current)


func _on_strike_finished(_strike: Telegraph) -> void:
	strike_landed.emit()


## Fine evento: i fulmini gia' annunciati si spengono senza colpire.
func _end() -> void:
	for strike in _strikes:
		strike.stop()
