class_name Telegraph
extends Node2D
## Preavviso di un attacco ad area: cerchio rosso a terra che si riempie in `duration` secondi.
## Alla fine, se damage > 0, la Hitbox resta attiva per un istante (colpisce chi e' ancora dentro).
## Riutilizzabile: start() lo riattiva, nessuna istanziazione per colpo.

signal finished(telegraph: Telegraph)

const PULSE_TIME: float = 0.12

@export var color: Color = Color(1, 0.18, 0.12)
## Layer della Hitbox: 16 = enemy_attack (colpisce il player), 8 = player_attack (colpisce i nemici).
@export_flags_2d_physics var attack_layer: int = 16
## Disegna un fulmine dall'alto nell'istante del colpo (eventi, abilita').
@export var lightning: bool = false

var radius: float = 100.0
## Carica in linea (M13, #86): se diverso da zero, disegna una striscia rettangolare orientata lungo
## questa direzione invece del cerchio (segmenti adiacenti della stessa carica si accostano esattamente,
## LANE_STEP in boss.gd, formando visivamente un'unica striscia continua invece di cerchi in fila).
## La hitbox resta circolare (raggio = charge_lane_radius): solo il preavviso cambia forma.
var lane_direction: Vector2 = Vector2.ZERO
var lane_length: float = 0.0
var _duration: float = 1.0
var _elapsed: float = 0.0
var _pulse_left: float = 0.0
var _running: bool = false
var _shape := CircleShape2D.new()

@onready var _hitbox: Hitbox = %Hitbox
@onready var _collision: CollisionShape2D = %CollisionShape


func _ready() -> void:
	_collision.shape = _shape
	_hitbox.collision_layer = attack_layer
	_set_hitbox(false)
	visible = false
	set_process(false)


## Avanzamento del riempimento (0..1). Logica pura, testata.
static func progress(elapsed: float, duration: float) -> float:
	return clampf(elapsed / maxf(duration, 0.001), 0.0, 1.0)


func start(center: Vector2, area_radius: float, duration: float, damage: int = 0, knockback: float = 0.0, direction: Vector2 = Vector2.ZERO, segment_length: float = 0.0) -> void:
	global_position = center
	radius = area_radius
	_shape.radius = area_radius
	_duration = duration
	_elapsed = 0.0
	_pulse_left = 0.0
	_hitbox.damage = damage
	_hitbox.knockback = knockback
	lane_direction = direction
	lane_length = segment_length
	_running = true
	visible = true
	reset_physics_interpolation()
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
			queue_redraw()
		else:
			_finish()


func _finish() -> void:
	stop()
	finished.emit(self)


## Segmento senza bordo (M13, #86): segmenti adiacenti con lo stesso colore si fondono senza cuciture
## visibili, cosi' la carica in linea legge come un'unica striscia invece di cerchi separati.
func _draw_lane_segment(p: float) -> void:
	var rect := Rect2(Vector2(-lane_length * 0.5, -radius), Vector2(lane_length, radius * 2.0))
	draw_set_transform(Vector2.ZERO, lane_direction.angle(), Vector2.ONE)
	draw_rect(rect, Color(color, 0.18), true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * p, rect.size.y)), Color(color, 0.36), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _set_hitbox(enabled: bool) -> void:
	_hitbox.active = enabled
	_hitbox.set_deferred("monitorable", enabled)


func _draw() -> void:
	var p := progress(_elapsed, _duration)
	if lane_direction != Vector2.ZERO and lane_length > 0.0:
		_draw_lane_segment(p)
		return
	draw_circle(Vector2.ZERO, radius, Color(color, 0.12))
	draw_circle(Vector2.ZERO, radius * p, Color(color, 0.32))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(color, 0.9), 3.0, true)
	if lightning and _pulse_left > 0.0:
		var points := PackedVector2Array()
		var rng := RandomNumberGenerator.new()
		rng.seed = int(global_position.x * 7.0 + global_position.y)
		for i in 9:
			points.append(Vector2(rng.randf_range(-14.0, 14.0) if 0 < i and i < 8 else 0.0, -260.0 + 260.0 * i / 8.0))
		draw_polyline(points, Color(1, 1, 1, 0.95), 5.0, true)
		draw_polyline(points, Color(color, 0.8), 9.0, true)
		draw_circle(Vector2.ZERO, radius * 0.6, Color(1, 1, 1, 0.5))
