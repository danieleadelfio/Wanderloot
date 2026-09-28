class_name SpawnUtils
extends RefCounted
## Utility pure per scegliere punti di spawn.


## count punti in rect ad almeno min_origin da origin e ad almeno min_separation tra loro e dagli `existing`
## (es. boss multipli che non devono sovrapporsi). Con poco spazio la separazione si riduce fino a 200 px.
## max_origin (M13, #86): con un valore finito i punti stanno nell'anello [min_origin, max_origin] attorno
## a origin, lo stesso dei nemici base (WaveSpawner.spawn_min/max_distance), invece che ovunque nel rect.
static func separated_points(rect: Rect2, origin: Vector2, min_origin: float, min_separation: float, count: int, rng: RandomNumberGenerator, existing: Array[Vector2] = [], max_origin: float = INF) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var separation := min_separation
	while result.size() < count:
		var placed := false
		for attempt in 40:
			var candidate := _candidate(rect, origin, min_origin, max_origin, rng)
			var distance := candidate.distance_to(origin)
			if distance < min_origin or distance > max_origin:
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
				result.append(_candidate(rect, origin, min_origin, max_origin, rng))
	return result


## Senza max_origin: uniforme nel rect. Con max_origin: uniforme sull'area dell'anello attorno a origin,
## poi dentro il rect (vicino ai bordi puo' finire piu' vicino di min_origin: lo scarta il chiamante).
static func _candidate(rect: Rect2, origin: Vector2, min_origin: float, max_origin: float, rng: RandomNumberGenerator) -> Vector2:
	if max_origin == INF:
		return Vector2(rng.randf_range(rect.position.x, rect.end.x), rng.randf_range(rect.position.y, rect.end.y))
	var radius := sqrt(rng.randf_range(min_origin * min_origin, max_origin * max_origin))
	var point := origin + Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * radius
	return Vector2(clampf(point.x, rect.position.x, rect.end.x), clampf(point.y, rect.position.y, rect.end.y))


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


## Punto di ricomparsa di un teletrasporto (M13, #86): entro max_jump da `from` (posizione del boss
## prima del salto), il piu' possibile ad almeno min_player_distance dal player, dentro rect. Se nessun
## candidato e' abbastanza lontano dal player, salta di max_jump nella direzione opposta al player.
## Mai oltre max_jump da `from` (il clamp nel rect non allontana: `from` sta nel rect).
static func teleport_point(rect: Rect2, from: Vector2, player_position: Vector2, min_player_distance: float, max_jump: float) -> Vector2:
	for i in 30:
		var radius := sqrt(randf()) * max_jump
		var candidate := (from + Vector2.RIGHT.rotated(randf() * TAU) * radius).clamp(rect.position, rect.end)
		if candidate.distance_to(player_position) >= min_player_distance:
			return candidate
	var away := player_position.direction_to(from)
	if away == Vector2.ZERO:
		away = Vector2.RIGHT.rotated(randf() * TAU)
	return (from + away * max_jump).clamp(rect.position, rect.end)
