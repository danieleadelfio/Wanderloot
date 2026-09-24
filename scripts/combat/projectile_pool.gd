class_name ProjectilePool
extends Node2D
## Pool di proiettili pre-istanziati. Deve stare all'origine: i proiettili usano global_position.

@export var projectile_scene: PackedScene
@export var initial_size: int = 64
@export var can_grow: bool = true

var _free: Array[Projectile] = []


func _ready() -> void:
	for i in initial_size:
		_free.append(_create())


func spawn(origin: Vector2, direction: Vector2, weapon: WeaponData) -> void:
	if _free.is_empty():
		if not can_grow:
			return
		_free.append(_create())
	var projectile: Projectile = _free.pop_back()
	projectile.pull_target = pull_target
	projectile.activate(origin, direction, weapon)


## Bersaglio attirato dai proiettili a buco nero (il player, per il pool dei nemici).
var pull_target: Node2D


func free_count() -> int:
	return _free.size()


func _create() -> Projectile:
	var projectile := projectile_scene.instantiate() as Projectile
	projectile.expired.connect(_on_projectile_expired)
	add_child(projectile)
	return projectile


func _on_projectile_expired(projectile: Projectile) -> void:
	_free.append(projectile)
