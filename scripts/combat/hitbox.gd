class_name Hitbox
extends Area2D
## Area che infligge danno. Rilevata dall'Hurtbox (la rilevazione avviene lato hurtbox).

signal hit(hurtbox: Hurtbox)

@export var damage: int = 1

## Se false l'Hurtbox la ignora (es. proiettile gia' consumato nello stesso frame).
var active: bool = true


func notify_hit(hurtbox: Hurtbox) -> void:
	hit.emit(hurtbox)
