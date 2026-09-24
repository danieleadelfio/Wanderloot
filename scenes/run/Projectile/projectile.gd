class_name Projectile
extends Node2D
## Proiettile poolable: activate()/deactivate(), mai queue_free. Emette expired al ritorno nel pool.

signal expired(projectile: Projectile)

var _velocity: Vector2 = Vector2.ZERO
var _time_left: float = 0.0
var _active: bool = false
var _pierce_left: int = 0
## Buco nero (M11.3): distanza percorsa, cresciuto, bersaglio attirato (impostato dal pool).
var pull_target: Node2D
var _weapon: WeaponData
var _travelled: float = 0.0
var _grown: bool = false

@onready var _hitbox: Hitbox = %Hitbox
@onready var _body: Sprite2D = %Body
@onready var _default_texture: Texture2D = _body.texture
@onready var _default_scale: Vector2 = _body.scale


func _ready() -> void:
	_hitbox.hit.connect(_on_hit)
	_hitbox.body_entered.connect(_on_body_entered)
	_set_enabled(false)


func _physics_process(delta: float) -> void:
	global_position += _velocity * delta
	if _weapon.grow_after > 0.0:
		_travelled += _velocity.length() * delta
		if not _grown and _travelled >= _weapon.grow_after:
			_grow()
		if _grown and is_instance_valid(pull_target) and pull_target.has_method("add_pull"):
			var to_self := global_position - pull_target.global_position
			var distance := to_self.length()
			if distance < _weapon.pull_radius and distance > 1.0:
				pull_target.add_pull(to_self / distance * _weapon.pull_strength * (1.0 - distance / _weapon.pull_radius))
	_time_left -= delta
	if _time_left <= 0.0:
		deactivate()


func activate(origin: Vector2, direction: Vector2, weapon: WeaponData) -> void:
	global_position = origin
	rotation = direction.angle()
	_velocity = direction * weapon.projectile_speed
	_weapon = weapon
	_travelled = 0.0
	_grown = false
	scale = Vector2.ONE
	_time_left = weapon.projectile_lifetime
	_hitbox.damage = weapon.damage
	_hitbox.knockback = weapon.knockback
	_hitbox.knockback_direction = direction
	_hitbox.poison_duration = weapon.poison_duration
	_hitbox.poison_interval = weapon.poison_interval
	_hitbox.poison_damage = weapon.poison_damage
	_pierce_left = weapon.pierce
	_body.texture = weapon.projectile_texture if weapon.projectile_texture else _default_texture
	_body.scale = Vector2.ONE * weapon.projectile_scale if weapon.projectile_scale > 0.0 else _default_scale
	_body.modulate = weapon.projectile_tint
	_active = true
	_set_enabled(true)
	reset_physics_interpolation()


func _grow() -> void:
	_grown = true
	_velocity *= _weapon.grown_speed_multiplier
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * _weapon.grow_scale, 0.25)


func deactivate() -> void:
	if not _active:
		return
	_active = false
	_set_enabled(false)
	expired.emit(self)


func _set_enabled(enabled: bool) -> void:
	visible = enabled
	set_physics_process(enabled)
	_hitbox.active = enabled
	_hitbox.set_deferred("monitoring", enabled)
	_hitbox.set_deferred("monitorable", enabled)


func _on_hit(_hurtbox: Hurtbox) -> void:
	# Perforazione: attraversa pierce nemici prima di sparire; i muri lo fermano sempre.
	if _pierce_left > 0:
		_pierce_left -= 1
		return
	deactivate()


func _on_body_entered(_body: Node2D) -> void:
	deactivate()
