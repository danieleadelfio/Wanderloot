class_name ExtractionPoint
extends Area2D
## Zona di estrazione: il player deve restarci dentro per data.channel_time secondi.
## Fuori dalla zona il progresso cala di data.decay_rate secondi al secondo (non si azzera di colpo).

signal progress_changed(ratio: float)
signal extracted

const COLOR: Color = Color(0.3, 1.0, 0.55)

@export var data: ExtractionData

var _progress: float = 0.0
var _player_inside: bool = false

@onready var _shape: CircleShape2D = %CollisionShape.shape


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_set_enabled(false)


func _physics_process(delta: float) -> void:
	var previous := _progress
	if _player_inside:
		_progress = minf(_progress + delta, data.channel_time)
	else:
		_progress = maxf(_progress - data.decay_rate * delta, 0.0)
	if _progress != previous:
		progress_changed.emit(ratio())
		queue_redraw()
	if _progress >= data.channel_time:
		_set_enabled(false)
		extracted.emit()


func _draw() -> void:
	var radius := _shape.radius
	draw_circle(Vector2.ZERO, radius, Color(COLOR, 0.15))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(COLOR, 0.4), 2.0)
	if ratio() > 0.0:
		draw_arc(Vector2.ZERO, radius - 4.0, -PI / 2.0, -PI / 2.0 + TAU * ratio(), 48, COLOR, 5.0)


func activate(spawn_position: Vector2) -> void:
	global_position = spawn_position
	_progress = 0.0
	_player_inside = false
	_set_enabled(true)
	progress_changed.emit(0.0)
	queue_redraw()


func ratio() -> float:
	return clampf(_progress / data.channel_time, 0.0, 1.0)


func _set_enabled(enabled: bool) -> void:
	visible = enabled
	set_physics_process(enabled)
	set_deferred("monitoring", enabled)


func _on_body_entered(_body: Node2D) -> void:
	_player_inside = true


func _on_body_exited(_body: Node2D) -> void:
	_player_inside = false
