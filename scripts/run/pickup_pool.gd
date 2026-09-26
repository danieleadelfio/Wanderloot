class_name PickupPool
extends Node2D
## Pool degli oggetti a terra ed effetto magnete: entro attract_radius dal target l'oggetto accelera
## verso di lui e viene assorbito al contatto. Un solo _physics_process per tutti gli oggetti.
## Non conosce RunManager: emette segnali, la composition root decide cosa farne.

signal exp_collected(amount: int)
signal material_collected(material: MaterialData, amount: int)
signal consumable_collected(consumable: ConsumableData)
signal item_collected(item: ItemInstance)

@export var pickup_scene: PackedScene
@export var initial_size: int = 96
@export var exp_texture: Texture2D
## Accelerazione e velocita' massima dell'attrazione (px/s^2, px/s). Alzate per le arene 10x (M13,
## #86): il Magnete ignora gia' la distanza (radius_sq bypassato mentre _attract_all_left > 0, vedi
## sotto), ma con arene fino a ~8600px di diagonale un oggetto lontano ci metteva troppo ad arrivare.
@export var attract_acceleration: float = 3200.0
@export var max_speed: float = 1800.0
@export var absorb_radius: float = 14.0
@export var pop_speed: float = 90.0

var target: Node2D
var attract_radius: float = 90.0
## Secondi rimasti del Magnete (consumabile): tutto quello che e' a terra viene attratto.
var _attract_all_left: float = 0.0
var _time: float = 0.0

var _free: Array[Pickup] = []
var _active: Array[Pickup] = []


func _ready() -> void:
	for i in initial_size:
		_free.append(_create())


func spawn_exp(at: Vector2, amount: int) -> void:
	_spawn(at, Pickup.Kind.EXP, amount, null, exp_texture, 0.5)


func spawn_material(at: Vector2, material: MaterialData, amount: int) -> void:
	_spawn(at, Pickup.Kind.MATERIAL, amount, material, material.icon, 0.375)


func spawn_consumable(at: Vector2, consumable: ConsumableData) -> void:
	_spawn(at, Pickup.Kind.CONSUMABLE, 1, null, consumable.icon, 0.5)
	_active.back().consumable = consumable


## Oggetto di equipaggiamento trovato: icona schiarita col colore della rarita' e alone pulsante.
func spawn_item(at: Vector2, item: ItemInstance, tint: Color, glow_scale: float = 1.0) -> void:
	_spawn(at, Pickup.Kind.ITEM, 1, null, item.base.icon, 0.6)
	var pickup: Pickup = _active.back()
	pickup.item = item
	pickup.set_tint(tint.lerp(Color.WHITE, 0.35))
	pickup.set_glow(tint, glow_scale)


## Magnete: per `seconds` ogni oggetto a terra, anche quelli che cadono nel frattempo, vola verso il player.
func attract_all(seconds: float) -> void:
	_attract_all_left = maxf(_attract_all_left, seconds)


func active_count() -> int:
	return _active.size()


## Consumabili attualmente a terra (M13, #86): mostrati come icona su mappa e minimappa, cosi' il
## player sa dove si trova un Magnete/Furia/Cuore anche a distanza. Solo Kind.CONSUMABLE.
func active_consumables() -> Array[Pickup]:
	return _active.filter(func(p: Pickup) -> bool: return p.kind == Pickup.Kind.CONSUMABLE)


func _physics_process(delta: float) -> void:
	if target == null or _active.is_empty():
		return
	_time += delta
	var goal := target.global_position
	_attract_all_left = maxf(_attract_all_left - delta, 0.0)
	var radius_sq := attract_radius * attract_radius
	var i := _active.size() - 1
	while i >= 0:
		var pickup := _active[i]
		pickup.pulse(_time)
		if not pickup.attracted:
			pickup.global_position += pickup.pop_velocity * delta
			pickup.pop_velocity *= exp(-10.0 * delta)
			pickup.attracted = _attract_all_left > 0.0 or pickup.global_position.distance_squared_to(goal) <= radius_sq
		if pickup.attracted:
			pickup.speed = minf(pickup.speed + attract_acceleration * delta, max_speed)
			var to_goal := goal - pickup.global_position
			var step := pickup.speed * delta
			if to_goal.length() <= absorb_radius + step:
				_collect(i)
			else:
				pickup.global_position += to_goal.normalized() * step
		i -= 1


func _spawn(at: Vector2, kind: Pickup.Kind, amount: int, material: MaterialData, texture: Texture2D, texture_scale: float) -> void:
	if amount <= 0:
		return
	if _free.is_empty():
		_free.append(_create())
	var pickup: Pickup = _free.pop_back()
	var pop := Vector2.RIGHT.rotated(randf() * TAU) * pop_speed * randf_range(0.5, 1.0)
	pickup.activate(at, kind, amount, material, texture, texture_scale, pop)
	_active.append(pickup)


func _collect(index: int) -> void:
	var pickup := _active[index]
	_active.remove_at(index)
	var item := pickup.item
	var consumable := pickup.consumable
	pickup.deactivate()
	_free.append(pickup)
	if pickup.kind == Pickup.Kind.EXP:
		exp_collected.emit(pickup.amount)
	elif pickup.kind == Pickup.Kind.CONSUMABLE:
		consumable_collected.emit(consumable)
	elif pickup.kind == Pickup.Kind.ITEM:
		item_collected.emit(item)
	else:
		material_collected.emit(pickup.item_material, pickup.amount)


func _create() -> Pickup:
	var pickup := pickup_scene.instantiate() as Pickup
	add_child(pickup)
	pickup.deactivate()
	return pickup
