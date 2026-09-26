class_name MapIndicatorArrow
extends Control
## Freccia sul bordo dello schermo verso un indicatore piazzato dal giocatore sulla mappa (M13, #86):
## stesso disegno di ExtractionIndicator (scenes/ui/ExtractionIndicator), ma verso un punto del mondo
## fisso invece che verso un nodo, e con colore configurabile (mai giallo: quello e' il portale).

@export var margin: float = 28.0
@export var size_px: float = 22.0

var color: Color = Color.WHITE
var target_position: Vector2 = Vector2.ZERO
var active: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	if active:
		queue_redraw()


func _draw() -> void:
	if not active:
		return
	var rect := get_viewport_rect()
	var screen_pos := get_viewport().get_canvas_transform() * target_position
	if rect.grow(-margin * 0.5).has_point(screen_pos):
		return
	var center := rect.size * 0.5
	var direction := center.direction_to(screen_pos)
	var inner := rect.grow(-margin)
	var scale_x := (inner.size.x * 0.5) / maxf(absf(direction.x), 0.001)
	var scale_y := (inner.size.y * 0.5) / maxf(absf(direction.y), 0.001)
	var tip := center + direction * minf(scale_x, scale_y)
	var side := direction.orthogonal() * size_px * 0.45
	var back := tip - direction * size_px
	draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), color)
