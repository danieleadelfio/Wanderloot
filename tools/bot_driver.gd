class_name BotDriver
extends RefCounted
## Guida del bot di playtest: kiting dai nemici vicini, mira sul piu' vicino, raccoglie gli oggetti a terra
## quando e' al sicuro, va all'estrazione. Usata da
## tools/autoplay.gd (bilanciamento) e tools/flow.gd (playtest end-to-end). Agisce solo via Input actions.


## Se vero il bot ignora l'estrazione finche' il boss (comparso) e' vivo: serve a misurare il boss.
static var fight_boss: bool = false
## Se vero il bot non va mai all'estrazione: serve a misurare l'overtime (M11.1).
static var stay: bool = false


static func drive(a: Node) -> void:
	var p = a.get_node("%Player")
	var pos: Vector2 = p.global_position
	var nearest = null
	var nd := INF
	var flee := Vector2.ZERO
	for e in a.active_enemies():
		var d: float = pos.distance_to(e.global_position)
		if d < nd: nd = d; nearest = e
		if d < 240.0:
			flee += (pos - e.global_position).normalized() * pow(1.0 - d / 240.0, 2) * 3.0
	var bosses: Array = a.get("bosses") if a.get("bosses") != null else []
	for boss in bosses:
		var db: float = pos.distance_to(boss.global_position)
		if db < nd: nd = db; nearest = boss
		if db < 300.0:
			flee += (pos - boss.global_position).normalized() * pow(1.0 - db / 300.0, 2) * 4.0
	# Cerchi di preavviso (salto del boss, fulmini degli eventi): esce dal cerchio.
	if a.has_method("danger_zones"):
		for zone: Vector3 in a.danger_zones():
			var c := Vector2(zone.x, zone.y)
			if pos.distance_to(c) < zone.z + 50.0:
				flee += (pos - c).normalized() * 5.0 if pos.distance_to(c) > 1.0 else Vector2.RIGHT * 5.0
	if a.has_node("%EnemyProjectilePool"):
		for b in a.get_node("%EnemyProjectilePool").get_children():
			if b.visible and pos.distance_to(b.global_position) < 140.0:
				var side: Vector2 = Vector2.RIGHT.rotated(b.rotation).orthogonal()
				if side.dot(pos - b.global_position) < 0.0: side = -side
				flee += side * 2.0
	var center := Vector2.ZERO
	if absf(pos.x) > 600: center.x = -signf(pos.x) * (absf(pos.x) - 600) / 100.0
	if absf(pos.y) > 330: center.y = -signf(pos.y) * (absf(pos.y) - 330) / 80.0
	var goal := Vector2.ZERO
	var ep = a.get_node("%ExtractionPoint")
	var hold: bool = fight_boss and not a.get("boss_defeated") and (not bosses.is_empty() or a.get("_boss_timer").time_left > 0.0)
	# Pentagramma (M10.2): entra nel cerchio e ci resta, schivando solo dentro il cerchio.
	var penta: Vector3 = a.pentagram_zone() if a.has_method("pentagram_zone") else Vector3.ZERO
	if penta.z > 0.0:
		var pc := Vector2(penta.x, penta.y)
		var d_in: float = pos.distance_to(pc)
		goal = pos.direction_to(pc) * (2.5 if d_in > penta.z * 0.5 else 1.2 * d_in / penta.z)
		flee = flee.limit_length(0.5 if d_in < penta.z * 0.7 else 0.1)
		hold = true
	if stay:
		hold = true
	if ep.visible and not hold:
		var to: Vector2 = ep.global_position - pos
		# Con zona aperta l'estrazione ha la priorita': fuga limitata (serve nelle arene affollate).
		goal = to.normalized() * (2.2 if to.length() > 30 else 0.0)
		flee = flee.limit_length(1.5)
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

## Scelta dell'abilita' (M10): prende la prima proposta; con slot pieni sostituisce il primo slot.
static func resolve_menus(a: Node) -> bool:
	var choice = a.get_node_or_null("%AbilityChoice")
	if choice == null or not choice.visible:
		return false
	var buttons = choice.get_node("%Choices").get_children().filter(func(b): return not b.is_queued_for_deletion())
	if not buttons.is_empty():
		buttons[0].pressed.emit()
	return true


static func set_axis(neg: String, pos_a: String, v: float) -> void:
	Input.action_release(neg); Input.action_release(pos_a)
	if v < -0.05: Input.action_press(neg, -v)
	elif v > 0.05: Input.action_press(pos_a, v)


## Scelta del bot al level-up (M5): tra le opzioni offerte preferisce quelle di combattimento,
## come farebbe un giocatore; con 13 potenziamenti la scelta casuale lo rendeva artificialmente debole.
const PRIORITY: Array[int] = [
	UpgradeData.Stat.DAMAGE, UpgradeData.Stat.FIRE_RATE, UpgradeData.Stat.PROJECTILE_COUNT,
	UpgradeData.Stat.COUNT_BONUS, UpgradeData.Stat.PIERCE, UpgradeData.Stat.MAX_HP, UpgradeData.Stat.MOVE_SPEED,
	UpgradeData.Stat.PICKUP_RADIUS, UpgradeData.Stat.PROJECTILE_SPEED,
]


static func choose(options: Array[UpgradeData]) -> UpgradeData:
	for stat in PRIORITY:
		for option in options:
			if option.stat == stat:
				return option
	return options[0]
