class_name MapArea
extends Control
## Riquadro della mappa (M13, #86): disegna i confini dell'arena, il player e gli indicatori
## piazzati; bussola N/S/E/O ai bordi. Un clic sinistro (se non piena, MapIndicators.MAX_INDICATORS)
## piazza un nuovo indicatore nella posizione di mondo corrispondente al punto cliccato.

signal indicator_placed(world_position: Vector2)

const COMPASS := {
	"N": Vector2(0.5, 0.04),
	"S": Vector2(0.5, 0.96),
	"E": Vector2(0.965, 0.5),
	"O": Vector2(0.035, 0.5),
}

var arena_rect: Rect2
var player: Node2D
var indicators: MapIndicators
var pickup_pool: PickupPool
## Per l'icona della statua del Pentagramma non ancora attivata (M13, #86).
var events: RunEventDirector

## Dimensione dell'icona dei consumabili e della statua sulla mappa (M13, #86).
const CONSUMABLE_ICON_SIZE: float = 20.0
const STATUE_ICON_SIZE: float = 30.0
const STATUE_ICON: Texture2D = preload("res://assets/sprites/demon_statue.png")


func setup(rect: Rect2, p: Node2D, ind: MapIndicators, pool: PickupPool = null, event_director: RunEventDirector = null) -> void:
	arena_rect = rect
	player = p
	indicators = ind
	pickup_pool = pool
	events = event_director
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if indicators == null or arena_rect.size == Vector2.ZERO:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if indicators.is_full():
			return
		var ratio := Vector2(event.position.x / size.x, event.position.y / size.y)
		var world := arena_rect.position + ratio * arena_rect.size
		if indicators.add(world):
			indicator_placed.emit(world)
			queue_redraw()


func _world_to_local(world: Vector2) -> Vector2:
	var ratio := (world - arena_rect.position) / arena_rect.size
	return ratio * size


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.14, 0.95), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 0.5, 0.58, 1.0), false, 2.0)
	if arena_rect.size == Vector2.ZERO:
		return
	if player:
		draw_circle(_world_to_local(player.global_position), 6.0, Color(0.95, 0.85, 0.2))
	if indicators:
		var pts := indicators.points()
		for i in pts.size():
			draw_circle(_world_to_local(pts[i]), 7.0, indicators.color_for(i))
	if pickup_pool:
		for pickup in pickup_pool.active_consumables():
			var icon := pickup.consumable.icon
			if icon == null:
				continue
			var center := _world_to_local(pickup.global_position)
			var half := CONSUMABLE_ICON_SIZE * 0.5
			draw_texture_rect(icon, Rect2(center - Vector2(half, half), Vector2.ONE * CONSUMABLE_ICON_SIZE), false)
	if events:
		var statue := events.pentagram_statue_zone()
		if statue.z > 0.0:
			var center := _world_to_local(Vector2(statue.x, statue.y))
			var half := STATUE_ICON_SIZE * 0.5
			draw_texture_rect(STATUE_ICON, Rect2(center - Vector2(half, half), Vector2.ONE * STATUE_ICON_SIZE), false)
	for label in COMPASS:
		var pos: Vector2 = COMPASS[label] * size
		draw_string(ThemeDB.fallback_font, pos, label, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)
