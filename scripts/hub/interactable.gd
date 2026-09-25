class_name Interactable
extends Area2D
## Punto di interazione dell'hub (fabbro, baule, portale): sa se il player e' nel raggio e quale finestra apre.
## La composition root (Hub) decide quando aprire: qui nessuna logica di UI.

## Testo del suggerimento mostrato a schermo ("E — Fabbro").
@export var prompt: String = ""
## Finestra dell'hub aperta dall'interazione.
@export var window: Control
## Chiavi di traduzione del tutorial della piazza (M12, #86): tutorial_title vuoto = la camera non si
## ferma qui (es. lampioni o altri Interactable futuri senza tutorial dedicato).
@export var tutorial_title: String = ""
@export var tutorial_description: String = ""

var player_in_range: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_changed.bind(true))
	body_exited.connect(_on_body_changed.bind(false))


func _on_body_changed(_body: Node2D, entered: bool) -> void:
	player_in_range = entered


## Indice del punto piu' vicino a `from` (-1 se vuoto). Logica pura, testata.
static func nearest_index(points: PackedVector2Array, from: Vector2) -> int:
	var best := -1
	var best_distance := INF
	for i in points.size():
		var distance := from.distance_squared_to(points[i])
		if distance < best_distance:
			best_distance = distance
			best = i
	return best
