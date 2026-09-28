class_name Minimap
extends Control
## Minimappa radar in alto a destra (M13, #86): il player resta sempre al centro, il contenuto
## scorre con lui. Bordo a bussola (N/S/E/O). Mostra gli indicatori piazzati dalla mappa (M) e il
## portale di estrazione quando attivo, come punti nella direzione relativa al player, appiattiti
## sul bordo del cerchio oltre world_radius (radar, non in scala 1:1).

const EXTRACTION_COLOR: Color = Color(1.0, 0.85, 0.2)

## Distanza di mondo mappata sul bordo del cerchio: oltre, il punto resta comunque sul bordo.
@export var world_radius: float = 2500.0

var player: Node2D
var indicators: MapIndicators
var extraction_point: Node2D
var pickup_pool: PickupPool
## Per l'icona della statua del Pentagramma non ancora attivata (M13, #86).
var events: RunEventDirector

## Dimensione dell'icona dei consumabili e della statua in minimappa (M13, #86): piu' piccole che
## sulla mappa intera.
const CONSUMABLE_ICON_SIZE: float = 12.0
const STATUE_ICON_SIZE: float = 16.0
const STATUE_ICON: Texture2D = preload("res://assets/sprites/demon_statue.png")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(p: Node2D, ind: MapIndicators, extraction: Node2D, pool: PickupPool = null, event_director: RunEventDirector = null) -> void:
	player = p
	indicators = ind
	extraction_point = extraction
	pickup_pool = pool
	events = event_director


func _process(_delta: float) -> void:
	queue_redraw()


func _relative(world_pos: Vector2, radius: float) -> Vector2:
	var delta := world_pos - player.global_position
	var dist := delta.length()
	if dist <= 0.001:
		return size * 0.5
	var local_dist := clampf(dist / world_radius, 0.0, 1.0) * radius
	return size * 0.5 + delta.normalized() * local_dist


func _draw() -> void:
	var radius := size.x * 0.5
	var center := size * 0.5
	# Stile A "Reliquiario d'oro" (M13, #86): anello d'oro doppio con rombi cardinali, lettere col font dei titoli.
	var gold := Color(0.79, 0.62, 0.33)
	draw_circle(center, radius, Color(0.05, 0.035, 0.07, 0.85))
	draw_arc(center, radius - 2.5, 0.0, TAU, 64, Color(0.23, 0.16, 0.08), 5.0)
	draw_arc(center, radius - 2.5, 0.0, TAU, 64, gold, 2.2)
	draw_arc(center, radius - 8.0, 0.0, TAU, 64, Color(gold, 0.55), 1.0)
	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		var tip: Vector2 = center + direction * (radius - 2.5)
		var side: Vector2 = direction.orthogonal() * 4.5
		draw_colored_polygon(PackedVector2Array([tip - direction * 5.0, tip + side, tip + direction * 5.0, tip - side]), gold)
	var font := get_theme_font(&"font", &"TitleLabel")
	draw_string(font, center + Vector2(-5, -radius + 22), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, gold)
	draw_string(font, center + Vector2(-5, radius - 12), "S", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, gold)
	draw_string(font, center + Vector2(radius - 22, 5), "E", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, gold)
	draw_string(font, center + Vector2(-radius + 12, 5), "O", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, gold)
	if player == null:
		return
	draw_circle(center, 4.0, Color(0.95, 0.95, 1.0))
	if extraction_point and extraction_point.visible:
		draw_circle(_relative(extraction_point.global_position, radius - 6.0), 5.0, EXTRACTION_COLOR)
	if indicators:
		var pts := indicators.points()
		for i in pts.size():
			draw_circle(_relative(pts[i], radius - 6.0), 5.0, indicators.color_for(i))
	if pickup_pool:
		for pickup in pickup_pool.active_consumables():
			var icon := pickup.consumable.icon
			if icon == null:
				continue
			var pos := _relative(pickup.global_position, radius - 6.0)
			var half := CONSUMABLE_ICON_SIZE * 0.5
			draw_texture_rect(icon, Rect2(pos - Vector2(half, half), Vector2.ONE * CONSUMABLE_ICON_SIZE), false)
	if events:
		var statue := events.pentagram_statue_zone()
		if statue.z > 0.0:
			var pos := _relative(Vector2(statue.x, statue.y), radius - 6.0)
			var half := STATUE_ICON_SIZE * 0.5
			draw_texture_rect(STATUE_ICON, Rect2(pos - Vector2(half, half), Vector2.ONE * STATUE_ICON_SIZE), false)
