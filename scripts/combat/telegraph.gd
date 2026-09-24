class_name Telegraph
extends Node2D
## Preavviso di un attacco ad area: cerchio rosso a terra che si riempie in `duration` secondi.
## Alla fine, se damage > 0, la Hitbox resta attiva per un istante (colpisce chi e' ancora dentro).
## Riutilizzabile: start() lo riattiva, nessuna istanziazione per colpo.

signal finished(telegraph: Telegraph)

const PULSE_TIME: float = 0.12

@export var color: Color = Color(1, 0.18, 0.12)

var radius: float = 100.0
var _duration: float = 1.0
var _elapsed: float = 0.0
var _pulse_left: float = 0.0
var _running: bool = false
var _shape := CircleShape2D.new()

@onready var _hitbox: Hitbox = %Hitbox
@onready var _collision: CollisionShape2D = %CollisionShape


func _ready() -> void:
	_collision.shape = _shape
	_set_hitbox(false)
	visible = false
	set_process(false)


## Avanzamento del riempimento (0..1). Logica pura, testata.
static func progress(elapsed: float, duration: float) -> float:
	return clampf(elapsed / maxf(duration, 0.001), 0.0, 1.0)


func start(center: Vector2, area_radius: float, duration: float, damage: int = 0, knockback: float = 0.0) -> void:
	global_position = center
	radius = area_radius
	_shape.radius = area_radius
	_duration = duration
	_elapsed = 0.0
	_pulse_left = 0.0
	_hitbox.damage = damage
	_hitbox.knockback = knockback
	_running = true
	visible = true
	set_process(true)
	queue_redraw()


func is_running() -> bool:
	return _running


func stop() -> void:
	_running = false
	_set_hitbox(false)
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	if _pulse_left > 0.0:
		_pulse_left -= delta
		if _pulse_left <= 0.0:
			_finish()
		return
	_elapsed += delta
	queue_redraw()
	if _elapsed >= _duration:
		if _hitbox.damage > 0:
			_pulse_left = PULSE_TIME
			_set_hitbox(true)
		else:
			_finish()


func _finish() -> void:
	stop()
	finished.emit(self)


func _set_hitbox(enabled: bool) -> void:
	_hitbox.active = enabled
	_hitbox.set_deferred("monitorable", enabled)


func _draw() -> void:
	var p := progress(_elapsed, _duration)
	draw_circle(Vector2.ZERO, radius, Color(color, 0.12))
	draw_circle(Vector2.ZERO, radius * p, Color(color, 0.32))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(color, 0.9), 3.0, true)
