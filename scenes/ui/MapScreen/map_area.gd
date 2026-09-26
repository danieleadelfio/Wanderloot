class_name MapArea
extends Control
## Riquadro della mappa (M13, #86): disegna i confini dell'arena, il player (cerchio) e gli
## indicatori piazzati (triangoli); bussola N/S/E/O ai bordi. Clic sinistro (se non piena,
## MapIndicators.MAX_INDICATORS) piazza un nuovo indicatore; clic destro cancella quello piu'
## vicino al cursore, se abbastanza vicino. Passando il cursore su statua/consumabili compare un
## tooltip col loro nome (_get_tooltip).

signal indicator_placed(world_position: Vector2)
signal indicator_removed

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
## Dimensione (raggio dal centro) del triangolo di un indicatore, e distanza in px schermo entro cui
## il clic destro lo cancella (M13, #86).
const INDICATOR_SIZE: float = 8.0
const INDICATOR_REMOVE_DISTANCE: float = 16.0


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
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		if indicators.is_full():
			return
		var ratio := Vector2(event.position.x / size.x, event.position.y / size.y)
		var world := arena_rect.position + ratio * arena_rect.size
		if indicators.add(world):
			indicator_placed.emit(world)
			queue_redraw()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		var pts := indicators.points()
		var nearest := -1
		var nearest_distance := INF
		for i in pts.size():
			var distance := _world_to_local(pts[i]).distance_to(event.position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = i
		if nearest >= 0 and nearest_distance <= INDICATOR_REMOVE_DISTANCE:
			indicators.remove_at(nearest)
			indicator_removed.emit()
			queue_redraw()


func _world_to_local(world: Vector2) -> Vector2:
	var ratio := (world - arena_rect.position) / arena_rect.size
	return ratio * size


func _draw_indicator_triangle(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -INDICATOR_SIZE),
		center + Vector2(INDICATOR_SIZE * 0.87, INDICATOR_SIZE * 0.5),
		center + Vector2(-INDICATOR_SIZE * 0.87, INDICATOR_SIZE * 0.5),
	])
	draw_colored_polygon(points, color)


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
			_draw_indicator_triangle(_world_to_local(pts[i]), indicators.color_for(i))
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


## Nome dell'icona sotto il cursore (statua del Pentagramma o consumabile a terra), vuoto altrimenti:
## stringa vuota sopprime il tooltip di default di Godot (M13, #86).
func _get_tooltip(at_position: Vector2) -> String:
	if events:
		var statue := events.pentagram_statue_zone()
		if statue.z > 0.0 and _world_to_local(Vector2(statue.x, statue.y)).distance_to(at_position) <= STATUE_ICON_SIZE * 0.5:
			return tr("MAP_TOOLTIP_PENTAGRAM_STATUE")
	if pickup_pool:
		for pickup in pickup_pool.active_consumables():
			if pickup.consumable == null:
				continue
			if _world_to_local(pickup.global_position).distance_to(at_position) <= CONSUMABLE_ICON_SIZE * 0.5:
				return tr(pickup.consumable.display_name)
	return ""
