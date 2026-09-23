class_name Weapon
extends Node2D
## Arma ranged: gestisce cooldown ed emette la richiesta di sparo. Non istanzia proiettili.

signal fired(origin: Vector2, direction: Vector2, data: WeaponData)

@export var data: WeaponData

var _cooldown: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)


func try_fire(direction: Vector2) -> bool:
	if data == null or _cooldown > 0.0 or direction == Vector2.ZERO:
		return false
	_cooldown = 1.0 / data.fire_rate
	fired.emit(global_position, direction.normalized(), data)
	return true
