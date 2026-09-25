class_name WandAbilities
extends Node2D
## Abilita' della bacchetta nella run (M10): tiene gli slot, conta colpi/distanza/tempo e attiva gli effetti.
## Collegato dalla composition root (Arena) a player, pool dei proiettili e lista dei nemici.

signal changed(abilities: Array[WandAbility])
signal activated(ability: WandAbility)
## Emesso quando un aumento di livello supera il cap sbloccato (M12, #86, #20): overflow = livelli
## non applicati, da convertire in un Bag of Resources (arena.gd, non e' compito di questa classe).
signal over_cap(ability: WandAbility, overflow: int)

const TELEGRAPH := preload("res://scenes/run/Telegraph/Telegraph.tscn")
const STRIKE_COLOR := Color(0.55, 0.85, 1.0)
const STRIKE_POOL_SIZE := 8

@export var slot_count: int = 3

## Cap sbloccato per abilita' (id -> livello, #20): assente = default Lv1 (Ascensione, #16).
## Impostato dalla composition root (Arena) prima di equip_bonus/equip, da MetaProgression.
var caps: Dictionary[StringName, int] = {}

var player: Player
var slots: AbilitySlots
## Abilita' date dall'equipaggiamento (Super raro e superiori): sempre attive, fuori dai 3 slot.
var bonus: Array[WandAbility] = []
## Livello di ogni abilita' posseduta (id -> livello): la stessa abilita' da equip o eventi si somma (M11.3, #72).
var levels: Dictionary[StringName, int] = {}
## Ultima abilita' presa o salita di livello (#15): decide il colore dei proiettili, niente piu' media
## (che con 2+ abilita' sbiadiva verso il centro). Null finche' non si possiede nulla (proiettili bianchi).
var last_taken: WandAbility = null
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
	return _triggers[index].progress(level_of(_triggers[index].ability)) if index < _triggers.size() else 0.0


## Aggiunge o, con index >= 0, sostituisce lo slot index. False se non e' cambiato nulla.
func equip(ability: WandAbility, index: int = -1) -> bool:
	# Gia' posseduta (slot o equip): sale di livello, nessuno slot occupato.
	if levels.has(ability.id):
		level_up(ability.id)
		return true
	if index >= 0:
		var removed := slots.replace(index, ability)
		if removed == null:
			return false
		if removed.effect:
			removed.effect.deactivate(self)
		levels.erase(removed.id)
	elif not slots.add(ability):
		return false
	levels[ability.id] = 1
	last_taken = ability
	_rebuild_triggers()
	if ability.trigger == WandAbility.Trigger.PERMANENT and ability.effect:
		ability.effect.activate(self, level_of(ability))
	_after_change()
	return true


func level_of(ability: WandAbility) -> int:
	return levels.get(ability.id, 1)


## Cap effettivo per l'abilita' (#20): cap sbloccato (Ascensione, #16), mai oltre il tetto assoluto.
func _cap_for(id: StringName) -> int:
	return mini(caps.get(id, 1), WandAbility.MAX_LEVEL)


## +amount livelli a un'abilita' gia' posseduta, senza superare il cap sbloccato (M12, #86, #19, #20).
## L'eccedenza (oltre il cap) e' segnalata con over_cap, non applicata: diventa loot altrove.
func level_up(id: StringName, amount: int = 1) -> void:
	var cap := _cap_for(id)
	var wanted: int = levels.get(id, 0) + amount
	levels[id] = mini(wanted, cap)
	var ability := _find(id)
	if ability:
		last_taken = ability
	if wanted > cap and ability:
		over_cap.emit(ability, wanted - cap)
	if ability and ability.effect and ability.trigger == WandAbility.Trigger.PERMANENT:
		ability.effect.activate(self, levels[id])
	_after_change()


## Abilita' dell'equipaggiamento, aggiunte a inizio run al livello del pezzo; se gia' presente si somma.
func equip_bonus(ability: WandAbility, level: int = 1) -> void:
	if ability == null:
		return
	if levels.has(ability.id):
		level_up(ability.id, level)
		return
	var cap := _cap_for(ability.id)
	bonus.append(ability)
	levels[ability.id] = mini(level, cap)
	last_taken = ability
	if level > cap:
		over_cap.emit(ability, level - cap)
	_rebuild_triggers()
	if ability.effect and (ability.trigger == WandAbility.Trigger.PERMANENT or ability.trigger == WandAbility.Trigger.COOLDOWN):
		ability.effect.activate(self, level)
	_after_change()


## Abilita' posseduta per id, o null (slot o bonus dell'equipaggiamento).
func _find(id: StringName) -> WandAbility:
	for ability in all_abilities():
		if ability.id == id:
			return ability
	return null


## Slot della bacchetta + abilita' dell'equipaggiamento (per HUD, colore, scelta degli eventi).
func all_abilities() -> Array[WandAbility]:
	var result: Array[WandAbility] = []
	result.append_array(slots.abilities)
	result.append_array(bonus)
	return result


func owned_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for ability in all_abilities():
		result.append(ability.id)
	return result


## Colore dei proiettili (#15): quello dell'ultima abilita' presa/salita di livello, bianco senza abilita'.
func _after_change() -> void:
	player.weapon_data().projectile_tint = last_taken.projectile_tint if last_taken else Color.WHITE
	changed.emit(all_abilities())


func _rebuild_triggers() -> void:
	_triggers.clear()
	for ability in all_abilities():
		_triggers.append(AbilityTrigger.new(ability))


func _physics_process(delta: float) -> void:
	if player == null:
		return
	var moved := player.global_position.distance_to(_last_position)
	_last_position = player.global_position
	for trigger in _triggers:
		var held := trigger.ability.effect != null and trigger.ability.effect.holds_cooldown(self)
		_fire(trigger, trigger.on_moved(moved) + trigger.tick(delta, held, level_of(trigger.ability)))


func _on_player_shot() -> void:
	for trigger in _triggers:
		_fire(trigger, trigger.on_shot())


func _fire(trigger: AbilityTrigger, times: int) -> void:
	for i in times:
		if trigger.ability.effect:
			trigger.ability.effect.activate(self, level_of(trigger.ability))
		activated.emit(trigger.ability)


func spawn_ring(count: int, damage_multiplier: float) -> void:
	var weapon := player.weapon_data().duplicate() as WeaponData
	weapon.damage = maxi(1, roundi(weapon.damage * damage_multiplier))
	for direction in BossPatterns.ring(count, randf() * TAU):
		_projectile_pool.spawn(player.global_position, direction, weapon)


func strike_nearest(max_range: float, radius: float, damage_bonus: int, count: int = 1) -> void:
	var in_range: Array[Node2D] = []
	for target: Node2D in _targets.call():
		if player.global_position.distance_to(target.global_position) <= max_range:
			in_range.append(target)
	in_range.sort_custom(func(a: Node2D, b: Node2D) -> bool: return player.global_position.distance_squared_to(a.global_position) < player.global_position.distance_squared_to(b.global_position))
	var fired := 0
	for strike in _strikes:
		if fired >= mini(count, in_range.size()):
			return
		if not strike.is_running():
			strike.start(in_range[fired].global_position, radius, 0.06, player.weapon_data().damage + damage_bonus, 180.0)
			fired += 1
