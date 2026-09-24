class_name DashRing
extends Node2D
## Cerchio bianco in spicchi accanto al player: uno spicchio per carica dello scatto,
## quello in ricarica si riempie dal centro.

@export var radius: float = 13.0
@export var gap: float = 0.12
@export var color: Color = Color(1, 1, 1, 0.95)

var charges: int = 0
var max_charges: int = 6
var partial: float = 0.0


func show_charges(current: int, maximum: int, recharging: float) -> void:
	if current == charges and maximum == max_charges and absf(recharging - partial) < 0.02:
		return
	charges = current
	max_charges = maximum
	partial = recharging
	queue_redraw()


func _draw() -> void:
	var step := TAU / max_charges
	draw_circle(Vector2.ZERO, radius + 2.0, Color(0, 0, 0, 0.45))
	for i in max_charges:
		var from := -PI / 2.0 + i * step + gap * 0.5
		var to := from + step - gap
		var fill := 1.0 if i < charges else (partial if i == charges else 0.0)
		_segment(from, to, radius, Color(color, 0.18))
		if fill > 0.0:
			_segment(from, to, radius * fill, color if fill >= 1.0 else Color(color, 0.55))


func _segment(from: float, to: float, r: float, c: Color) -> void:
	var points := PackedVector2Array([Vector2.ZERO])
	for k in 7:
		points.append(Vector2.from_angle(lerpf(from, to, k / 6.0)) * r)
	draw_colored_polygon(points, c)
