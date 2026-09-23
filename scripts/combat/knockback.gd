class_name Knockback
extends Node
## Spinta ricevuta dai colpi: velocita' aggiuntiva che decade esponenzialmente.
## Il corpo proprietario chiama step() nel proprio _physics_process e somma velocity al movimento.

@export_range(0.0, 1.0, 0.05) var resistance: float = 0.0
## Smorzamento per secondo: piu' alto = spinta piu' breve.
@export var decay: float = 12.0

var velocity: Vector2 = Vector2.ZERO


func apply(impulse: Vector2) -> void:
	velocity += impulse * (1.0 - resistance)


func step(delta: float) -> void:
	velocity *= exp(-decay * delta)
	if velocity.length_squared() < 1.0:
		velocity = Vector2.ZERO


func reset() -> void:
	velocity = Vector2.ZERO
