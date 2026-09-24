class_name Pentagram
extends Node2D
## Pentagramma di sangue a terra con le candele attorno (solo aspetto). Le regole sono in PentagramState.

const CANDLE: Texture2D = preload("res://assets/sprites/candle.png")
const BLOOD := Color(0.72, 0.04, 0.08)

var radius: float = 110.0
var active: bool = false
var _candles: Array[Sprite2D] = []
var _time: float = 0.0

@onready var _light: PointLight2D = %Light


func _ready() -> void:
	hide()


func setup(at: Vector2, circle_radius: float, candle_count: int) -> void:
	global_position = at
	radius = circle_radius
	active = false
	for candle in _candles:
		candle.queue_free()
	_candles.clear()
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for i in candle_count:
		var candle := Sprite2D.new()
		candle.texture = CANDLE
		candle.scale = Vector2(0.4, 0.4)
		candle.material = unshaded
		candle.offset = Vector2(0, -20)
		candle.position = Vector2.RIGHT.rotated(TAU * i / candle_count - PI / 2.0) * (radius + 14.0)
		add_child(candle)
		_candles.append(candle)
	set_lit(candle_count)
	show()
	reset_physics_interpolation()


func set_lit(count: int) -> void:
	for i in _candles.size():
		_candles[i].modulate = Color.WHITE if i < count else Color(0.22, 0.18, 0.2)
	_light.energy = 0.4 + 1.0 * float(count) / maxi(_candles.size(), 1)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.8 + 0.2 * sin(_time * (6.0 if active else 2.5))
	draw_circle(Vector2.ZERO, radius, Color(BLOOD, 0.14 * pulse))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(BLOOD, 0.9 * pulse), 5.0, true)
	draw_arc(Vector2.ZERO, radius * 0.86, 0.0, TAU, 64, Color(BLOOD, 0.6 * pulse), 2.5, true)
	var star := PackedVector2Array()
	for i in 6:
		star.append(Vector2.RIGHT.rotated(-PI / 2.0 + TAU * (i * 2 % 5) / 5.0) * radius * 0.86)
	draw_polyline(star, Color(BLOOD, 0.85 * pulse), 4.0, true)
