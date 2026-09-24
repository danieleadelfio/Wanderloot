class_name SpawnUtils
extends RefCounted
## Utility pure per scegliere punti di spawn.


## Punto casuale in rect ad almeno min_distance da origin (fino a 10 tentativi, poi l'ultimo estratto).
## count punti in rect ad almeno min_origin da origin e ad almeno min_separation tra loro e dagli `existing`
## (es. boss multipli che non devono sovrapporsi). Con poco spazio la separazione si riduce fino a 200 px.
static func separated_points(rect: Rect2, origin: Vector2, min_origin: float, min_separation: float, count: int, rng: RandomNumberGenerator, existing: Array[Vector2] = []) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var separation := min_separation
	while result.size() < count:
		var placed := false
		for attempt in 40:
			var candidate := Vector2(rng.randf_range(rect.position.x, rect.end.x), rng.randf_range(rect.position.y, rect.end.y))
			if candidate.distance_to(origin) < min_origin:
				continue
			var ok := true
			for other in result + existing:
				if candidate.distance_to(other) < separation:
					ok = false
					break
			if ok:
				result.append(candidate)
				placed = true
				break
		if not placed:
			separation = maxf(separation * 0.8, 200.0)
			if separation <= 200.0 and not placed:
				result.append(Vector2(rng.randf_range(rect.position.x, rect.end.x), rng.randf_range(rect.position.y, rect.end.y)))
	return result


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
