class_name MapScreen
extends CanvasLayer
## Mappa dell'arena (tasto M, M13 #86): confini, posizione del player e punti di interesse (vuoto
## per ora, si popolera' in futuro). Da qui si piazzano fino a MapIndicators.MAX_INDICATORS
## indicatori (clic sinistro su %MapArea), che diventano frecce a bordo schermo per orientarsi
## (MapIndicatorArrow), come la freccia del portale di estrazione. La pausa la gestisce Arena.

signal indicator_placed(world_position: Vector2)

@onready var _window: Control = %Window
@onready var _map_area: MapArea = %MapArea
@onready var _poi_label: Label = %PoiLabel


func _ready() -> void:
	_window.hide()
	_poi_label.text = tr("MAP_NO_POI")
	_map_area.indicator_placed.connect(func(pos: Vector2) -> void: indicator_placed.emit(pos))


func close() -> void:
	_window.hide()


func present(arena_rect: Rect2, player: Node2D, indicators: MapIndicators, pickup_pool: PickupPool = null, event_director: RunEventDirector = null) -> void:
	_map_area.setup(arena_rect, player, indicators, pickup_pool, event_director)
	_window.show()
