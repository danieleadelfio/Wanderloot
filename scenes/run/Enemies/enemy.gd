class_name Enemy
extends CharacterBody2D
## Nemico base guidato da EnemyData. Insegue il target. API poolable: activate()/deactivate().

signal died(enemy: Enemy)

@export var data: EnemyData

var target: Node2D

var _freeze_left: float = 0.0

@onready var health: Health = %Health
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _hitbox: Hitbox = %Hitbox
@onready var _collision: CollisionShape2D = %CollisionShape
@onready var _knockback: Knockback = %Knockback


func _ready() -> void:
	_hitbox.damage = data.contact_damage
	_hitbox.knockback = data.contact_knockback
	_knockback.resistance = data.knockback_resistance
	health.died.connect(_on_health_died)
	_hurtbox.hurt.connect(_on_hurt)
	_hurtbox.knocked.connect(_knockback.apply)
	_set_enabled(false)


func _physics_process(delta: float) -> void:
	# Hitstop locale: fermo per qualche frame, poi la spinta riparte da dove era.
	if _freeze_left > 0.0:
		_freeze_left -= delta
		return
	_knockback.step(delta)
	var chase := Vector2.ZERO
	if is_instance_valid(target):
		chase = global_position.direction_to(target.global_position) * data.move_speed
	velocity = chase + _knockback.velocity
	move_and_slide()


func activate(spawn_position: Vector2) -> void:
	global_position = spawn_position
	health.reset(data.max_hp)
	_knockback.reset()
	_freeze_left = 0.0
	_set_enabled(true)


func deactivate() -> void:
	_set_enabled(false)


func _set_enabled(enabled: bool) -> void:
	visible = enabled
	set_physics_process(enabled)
	_collision.set_deferred("disabled", not enabled)
	_hurtbox.set_deferred("monitoring", enabled)
	_hitbox.set_deferred("monitorable", enabled)
	_hitbox.active = enabled


func _on_hurt(_amount: int) -> void:
	_freeze_left = data.hit_freeze


func _on_health_died() -> void:
	deactivate()
	died.emit(self)
