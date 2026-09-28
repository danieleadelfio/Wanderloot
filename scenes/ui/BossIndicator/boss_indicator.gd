class_name BossIndicator
extends Control
## Frecce rosse a bordo schermo verso i boss vivi fuori vista, con un teschio dagli occhi rossi
## (M13, #86): con le arene 10x un boss lontano non si ritrovava. Stesso principio di
## ExtractionIndicator, ma per piu' bersagli; creato e collegato dalla composition root (Arena).

const COLOR: Color = Color(0.95, 0.15, 0.12)
const SKULL: Texture2D = preload("res://assets/sprites/icon_boss_skull.png")
@export var margin: float = 34.0
@export var size_px: float = 20.0
@export var skull_px: float = 30.0

## Callable che restituisce i boss vivi (Array di Node2D).
var targets: Callable


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not targets.is_valid():
		return
	var rect := get_viewport_rect()
	var canvas := get_viewport().get_canvas_transform()
	for target: Node2D in targets.call():
		if not is_instance_valid(target):
			continue
		var screen_pos := canvas * target.global_position
		if rect.grow(-margin * 0.5).has_point(screen_pos):
			continue
		var tip := edge_point(rect.grow(-margin), screen_pos)
		var direction := (rect.size * 0.5).direction_to(screen_pos)
		var side := direction.orthogonal() * size_px * 0.45
		var back := tip - direction * size_px
		draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), COLOR)
		var skull_center := back - direction * (skull_px * 0.6)
		draw_texture_rect(SKULL, Rect2(skull_center - Vector2.ONE * skull_px * 0.5, Vector2.ONE * skull_px), false)


## Punto sul bordo di `inner` lungo la direzione centro -> screen_pos.
static func edge_point(inner: Rect2, screen_pos: Vector2) -> Vector2:
	var center := inner.get_center()
	var direction := center.direction_to(screen_pos)
	var scale_x := (inner.size.x * 0.5) / maxf(absf(direction.x), 0.001)
	var scale_y := (inner.size.y * 0.5) / maxf(absf(direction.y), 0.001)
	return center + direction * minf(scale_x, scale_y)
