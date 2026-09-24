class_name Hitbox
extends Area2D
## Area che infligge danno. Rilevata dall'Hurtbox (la rilevazione avviene lato hurtbox).

signal hit(hurtbox: Hurtbox)

@export var damage: int = 1
## Intensita' della spinta (px/s) applicata all'Hurtbox colpita. 0 = nessuna.
@export var knockback: float = 0.0
## Direzione della spinta; se zero si spinge via dal centro della Hitbox (es. contatto nemico).
var knockback_direction: Vector2 = Vector2.ZERO
## Veleno applicato all'Hurtbox colpita (0 = nessuno, M11.3).
var poison_duration: float = 0.0
var poison_interval: float = 1.5
var poison_damage: int = 1

## Se false l'Hurtbox la ignora (es. proiettile gia' consumato nello stesso frame).
var active: bool = true


func notify_hit(hurtbox: Hurtbox) -> void:
	hit.emit(hurtbox)
