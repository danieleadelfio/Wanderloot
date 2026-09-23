class_name Enemy
extends CharacterBody2D
## Nemico base guidato da EnemyData. Insegue il target. API poolable: activate()/deactivate().

signal died(enemy: Enemy)

@export var data: EnemyData

var target: Node2D

@onready var health: Health = %Health
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _hitbox: Hitbox = %Hitbox
@onready var _collision: CollisionShape2D = %CollisionShape


func _ready() -> void:
	_hitbox.damage = data.contact_damage
	health.died.connect(_on_health_died)
	_set_enabled(false)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	velocity = global_position.direction_to(target.global_position) * data.move_speed
	move_and_slide()


func activate(spawn_position: Vector2) -> void:
	global_position = spawn_position
	health.reset(data.max_hp)
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


func _on_health_died() -> void:
	deactivate()
	died.emit(self)
