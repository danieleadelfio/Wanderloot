class_name SpawnUtils
extends RefCounted
## Utility pure per scegliere punti di spawn.


## Punto casuale in rect ad almeno min_distance da origin (fino a 10 tentativi, poi l'ultimo estratto).
static func random_point_away(rect: Rect2, origin: Vector2, min_distance: float) -> Vector2:
	var candidate := Vector2.ZERO
	for i in 10:
		candidate = Vector2(
			randf_range(rect.position.x, rect.end.x),
			randf_range(rect.position.y, rect.end.y)
		)
		if candidate.distance_to(origin) >= min_distance:
			break
	return candidate
