class_name BotDriver
extends RefCounted
## Guida del bot di playtest: kiting dai nemici vicini, mira sul piu' vicino, raccoglie gli oggetti a terra
## quando e' al sicuro, va all'estrazione. Usata da
## tools/autoplay.gd (bilanciamento) e tools/flow.gd (playtest end-to-end). Agisce solo via Input actions.


static func drive(a: Node) -> void:
	var p = a.get_node("%Player")
	var pos: Vector2 = p.global_position
	var nearest = null
	var nd := INF
	var flee := Vector2.ZERO
	for e in a.get_node("%EnemyPool").get_children():
		if not e.visible: continue
		var d: float = pos.distance_to(e.global_position)
		if d < nd: nd = d; nearest = e
		if d < 240.0:
			flee += (pos - e.global_position).normalized() * pow(1.0 - d / 240.0, 2) * 3.0
	var center := Vector2.ZERO
	if absf(pos.x) > 600: center.x = -signf(pos.x) * (absf(pos.x) - 600) / 100.0
	if absf(pos.y) > 330: center.y = -signf(pos.y) * (absf(pos.y) - 330) / 80.0
	var goal := Vector2.ZERO
	var ep = a.get_node("%ExtractionPoint")
	if ep.visible:
		var to: Vector2 = ep.global_position - pos
		goal = to.normalized() * (1.2 if to.length() > 30 else 0.0)
		if to.length() < 40: flee *= 0.25
	# Raccolta (M5): se non ci sono nemici vicini va verso l'oggetto a terra piu' vicino.
	if goal == Vector2.ZERO and flee.length() < 0.4 and a.has_node("%PickupPool"):
		var best := INF
		for pk in a.get_node("%PickupPool").get_children():
			if pk.visible:
				var dp: float = pos.distance_to(pk.global_position)
				if dp < best and dp < 400.0:
					best = dp
					goal = pos.direction_to(pk.global_position) * 0.8
	var move := (flee + center + goal).limit_length(1.0)
	set_axis("move_left", "move_right", move.x)
	set_axis("move_up", "move_down", move.y)
	var aim := Vector2.ZERO
	if nearest != null and nd < 700: aim = pos.direction_to(nearest.global_position)
	set_axis("aim_left", "aim_right", aim.x)
	set_axis("aim_up", "aim_down", aim.y)

static func set_axis(neg: String, pos_a: String, v: float) -> void:
	Input.action_release(neg); Input.action_release(pos_a)
	if v < -0.05: Input.action_press(neg, -v)
	elif v > 0.05: Input.action_press(pos_a, v)
