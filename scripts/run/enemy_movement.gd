class_name EnemyMovement
extends RefCounted
## Comportamenti di movimento dei nemici (logica pura): direzione desiderata verso/attorno al bersaglio.


## Resta a circa preferred px dal bersaglio: si avvicina se lontano, si allontana se vicino,
## dentro la fascia gira attorno (strafe) per non restare fermo.
static func keep_distance(to_target: Vector2, preferred: float, band: float = 40.0) -> Vector2:
	var distance := to_target.length()
	if distance < 0.001:
		return Vector2.ZERO
	var direction := to_target / distance
	if distance > preferred + band:
		return direction
	if distance < preferred - band:
		return -direction
	return direction.orthogonal() * 0.6
