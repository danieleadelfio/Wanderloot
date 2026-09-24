class_name BossPatterns
extends RefCounted
## Direzioni dei proiettili dei boss (logica pura, testata).


## count direzioni distribuite in un ventaglio di spread_degrees centrato su direction.
static func fan(direction: Vector2, count: int, spread_degrees: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var base := direction.normalized()
	if count <= 1:
		result.append(base)
		return result
	var spread := deg_to_rad(spread_degrees)
	for i in count:
		result.append(base.rotated(-spread / 2.0 + spread * i / (count - 1)))
	return result


## count direzioni equidistanti a 360 gradi, ruotate di offset_radians.
static func ring(count: int, offset_radians: float = 0.0) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for i in maxi(count, 0):
		result.append(Vector2.RIGHT.rotated(offset_radians + TAU * i / count))
	return result
