class_name StarTwinkle
extends Node2D
## Stelle che luccicano nel cielo dell'hub (GDD §7): un solo nodo disegna tutti i punti, ognuno con
## velocita' e fase proprie; la luminosita' sale in un picco breve e torna quasi a zero.

@export var points: PackedVector2Array = PackedVector2Array()
@export var color: Color = Color(1.0, 0.95, 0.85, 1.0)
@export var min_speed: float = 0.35
@export var max_speed: float = 0.9
@export var max_size: float = 4.0

var _time: float = 0.0
var _speed: PackedFloat32Array = PackedFloat32Array()
var _phase: PackedFloat32Array = PackedFloat32Array()
var _size: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in points.size():
		_speed.append(rng.randf_range(min_speed, max_speed))
		_phase.append(rng.randf_range(0.0, TAU))
		_size.append(rng.randf_range(max_size * 0.5, max_size))


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	for i in points.size():
		var glow := 0.5 + 0.5 * sin(_time * _speed[i] + _phase[i])
		glow = glow * glow * glow
		if glow < 0.02:
			continue
		var c := Color(color, glow)
		var s := _size[i] * (0.5 + 0.5 * glow)
		var p := points[i]
		draw_line(p - Vector2(s, 0.0), p + Vector2(s, 0.0), c, 1.2, true)
		draw_line(p - Vector2(0.0, s), p + Vector2(0.0, s), c, 1.2, true)
		draw_circle(p, 0.8 + glow, c)
