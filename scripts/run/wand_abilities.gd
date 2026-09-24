class_name WandAbilities
extends Node2D
## Abilita' della bacchetta nella run (M10): tiene gli slot, conta colpi/distanza/tempo e attiva gli effetti.
## Collegato dalla composition root (Arena) a player, pool dei proiettili e lista dei nemici.

signal changed(abilities: Array[WandAbility])
signal activated(ability: WandAbility)

const TELEGRAPH := preload("res://scenes/run/Telegraph/Telegraph.tscn")
const STRIKE_COLOR := Color(0.55, 0.85, 1.0)
const STRIKE_POOL_SIZE := 4

@export var slot_count: int = 3

var player: Player
var slots: AbilitySlots
var _projectile_pool: ProjectilePool
var _targets: Callable
var _triggers: Array[AbilityTrigger] = []
var _last_position: Vector2
var _strikes: Array[Telegraph] = []


func _ready() -> void:
	slots = AbilitySlots.new(slot_count)
	for i in STRIKE_POOL_SIZE:
		var strike: Telegraph = TELEGRAPH.instantiate()
		strike.attack_layer = 8
		strike.color = STRIKE_COLOR
		strike.lightning = true
		strike.top_level = true
		add_child(strike)
		_strikes.append(strike)


## targets: Callable che restituisce i nemici colpibili (Array di Node2D).
func setup(for_player: Player, projectile_pool: ProjectilePool, targets: Callable) -> void:
	player = for_player
	_projectile_pool = projectile_pool
	_targets = targets
	_last_position = player.global_position
	player.shot_requested.connect(_on_player_shot.unbind(3))


func progress_of(index: int) -> float:
	return _triggers[index].progress() if index < _triggers.size() else 0.0


## Aggiunge o, con index >= 0, sostituisce lo slot index. False se non e' cambiato nulla.
func equip(ability: WandAbility, index: int = -1) -> bool:
	if index >= 0:
		var removed := slots.replace(index, ability)
		if removed == null:
			return false
		if removed.effect:
			removed.effect.deactivate(self)
	elif not slots.add(ability):
		return false
	_rebuild_triggers()
	if ability.trigger == WandAbility.Trigger.PERMANENT and ability.effect:
		ability.effect.activate(self)
	player.weapon_data().projectile_tint = slots.tint()
	changed.emit(slots.abilities)
	return true


func _rebuild_triggers() -> void:
	_triggers.clear()
	for ability in slots.abilities:
		_triggers.append(AbilityTrigger.new(ability))


func _physics_process(delta: float) -> void:
	if player == null:
		return
	var moved := player.global_position.distance_to(_last_position)
	_last_position = player.global_position
	for trigger in _triggers:
		var held := trigger.ability.effect != null and trigger.ability.effect.holds_cooldown(self)
		_fire(trigger, trigger.on_moved(moved) + trigger.tick(delta, held))


func _on_player_shot() -> void:
	for trigger in _triggers:
		_fire(trigger, trigger.on_shot())


func _fire(trigger: AbilityTrigger, times: int) -> void:
	for i in times:
		if trigger.ability.effect:
			trigger.ability.effect.activate(self)
		activated.emit(trigger.ability)


func spawn_ring(count: int, damage_multiplier: float) -> void:
	var weapon := player.weapon_data().duplicate() as WeaponData
	weapon.damage = maxi(1, roundi(weapon.damage * damage_multiplier))
	for direction in BossPatterns.ring(count, randf() * TAU):
		_projectile_pool.spawn(player.global_position, direction, weapon)


func strike_nearest(max_range: float, radius: float, damage_bonus: int) -> void:
	var best: Node2D = null
	var best_distance := max_range
	for target: Node2D in _targets.call():
		var distance := player.global_position.distance_to(target.global_position)
		if distance < best_distance:
			best_distance = distance
			best = target
	if best == null:
		return
	for strike in _strikes:
		if not strike.is_running():
			strike.start(best.global_position, radius, 0.06, player.weapon_data().damage + damage_bonus, 180.0)
			return
