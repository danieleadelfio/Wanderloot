class_name Spinner
extends Node2D
## Rotazione continua (vortice del portale).

@export var speed: float = 1.2


func _process(delta: float) -> void:
	rotation += speed * delta
