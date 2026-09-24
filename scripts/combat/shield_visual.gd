class_name ShieldVisual
extends Node2D
## Anello dorato attorno al player finche' la barriera e' attiva.

@export var radius: float = 30.0
@export var color: Color = Color(1, 0.85, 0.4)

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.75 + 0.25 * sin(_time * 5.0)
	draw_circle(Vector2.ZERO, radius, Color(color, 0.12 * pulse))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(color, 0.85 * pulse), 2.5, true)
