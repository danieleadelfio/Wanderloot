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


## max_distance (M13, arene 10x): oltre a min_distance, il punto non deve superare questa distanza
## dal player (es. portale di estrazione, mai a piu' di 1000px). INF = nessun limite (default).
static func random_point_away(rect: Rect2, origin: Vector2, min_distance: float, max_distance: float = INF) -> Vector2:
	for i in 20:
		var candidate := Vector2(
			randf_range(rect.position.x, rect.end.x),
			randf_range(rect.position.y, rect.end.y)
		)
		var dist := candidate.distance_to(origin)
		if dist >= min_distance and dist <= max_distance:
			return candidate
	# Nessun candidato valido nei tentativi (rect piccolo o max_distance stretto): forza un punto
	# sull'anello [min_distance, max_distance] attorno al player, poi lo clampa dentro il rect.
	var angle := randf_range(0.0, TAU)
	var radius := min_distance if max_distance == INF else randf_range(min_distance, maxf(max_distance, min_distance))
	var forced := origin + Vector2.RIGHT.rotated(angle) * radius
	forced.x = clampf(forced.x, rect.position.x, rect.end.x)
	forced.y = clampf(forced.y, rect.position.y, rect.end.y)
	return forced
