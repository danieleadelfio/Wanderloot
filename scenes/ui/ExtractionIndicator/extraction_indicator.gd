class_name ExtractionIndicator
extends Control
## Freccia sul bordo dello schermo verso la zona di estrazione quando e' attiva ma fuori vista.
## Trovato nel playtest M4: con la zona a 120s in un'arena piu' grande dello schermo, senza
## indicatore il giocatore non sa dove andare.

const COLOR: Color = Color(0.3, 1.0, 0.55)
@export var margin: float = 28.0
@export var size_px: float = 22.0

var target: Node2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if target == null or not target.visible:
		return
	var rect := get_viewport_rect()
	var screen_pos := get_viewport().get_canvas_transform() * target.global_position
	if rect.grow(-margin * 0.5).has_point(screen_pos):
		return
	var center := rect.size * 0.5
	var direction := center.direction_to(screen_pos)
	var inner := rect.grow(-margin)
	# Punto sul bordo del rettangolo interno lungo la direzione centro -> zona.
	var scale_x := (inner.size.x * 0.5) / maxf(absf(direction.x), 0.001)
	var scale_y := (inner.size.y * 0.5) / maxf(absf(direction.y), 0.001)
	var tip := center + direction * minf(scale_x, scale_y)
	var side := direction.orthogonal() * size_px * 0.45
	var back := tip - direction * size_px
	draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), COLOR)
