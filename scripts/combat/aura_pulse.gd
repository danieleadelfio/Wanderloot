class_name AuraPulse
extends Sprite2D
## Alone che respira (nube tossica attorno allo slime verde).

@export var speed: float = 2.2
@export var amount: float = 0.12

var _time: float = 0.0
@onready var _base_scale: Vector2 = scale


func _process(delta: float) -> void:
	_time += delta
	scale = _base_scale * (1.0 + amount * sin(_time * speed))
	rotation += delta * 0.3
