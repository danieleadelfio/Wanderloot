class_name Spinner
extends Node2D
## Rotazione continua (vortice del portale).

@export var speed: float = 1.2


# Movimento sui tick di fisica: con l'interpolazione attiva resta fluido (M10.1).
func _physics_process(delta: float) -> void:
	rotation += speed * delta
