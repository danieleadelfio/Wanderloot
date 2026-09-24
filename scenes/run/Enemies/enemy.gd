class_name Enemy
extends CharacterBody2D
## Nemico base guidato da EnemyData. Insegue il target. API poolable: activate()/deactivate().
## Dopo EnemyData.rage_after secondi in vita va in rage: piu' veloce, piu' dannoso, sprite rosso.

signal died(enemy: Enemy)
signal hurt(enemy: Enemy)
signal raged(enemy: Enemy)

@export var data: EnemyData

var target: Node2D

var is_raged: bool = false

var _freeze_left: float = 0.0
var _alive_time: float = 0.0
var _rage_tween: Tween

@onready var health: Health = %Health
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _hitbox: Hitbox = %Hitbox
@onready var _collision: CollisionShape2D = %CollisionShape
@onready var _knockback: Knockback = %Knockback
@onready var _rage_body: CanvasItem = %RageBody


func _ready() -> void:
	_hitbox.damage = data.contact_damage
	_hitbox.knockback = data.contact_knockback
	_knockback.resistance = data.knockback_resistance
	health.died.connect(_on_health_died)
	_hurtbox.hurt.connect(_on_hurt)
	_hurtbox.knocked.connect(_knockback.apply)
	_set_enabled(false)


func _physics_process(delta: float) -> void:
	_alive_time += delta
	if not is_raged and data.rage_after > 0.0 and _alive_time >= data.rage_after:
		_enter_rage()
	# Hitstop locale: fermo per qualche frame, poi la spinta riparte da dove era.
	if _freeze_left > 0.0:
		_freeze_left -= delta
		return
	_knockback.step(delta)
	var chase := Vector2.ZERO
	if is_instance_valid(target):
		chase = global_position.direction_to(target.global_position) * current_speed()
	velocity = chase + _knockback.velocity
	move_and_slide()


func activate(spawn_position: Vector2) -> void:
	global_position = spawn_position
	health.reset(data.max_hp)
	_knockback.reset()
	_freeze_left = 0.0
	_reset_rage()
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


func current_speed() -> float:
	return data.move_speed * (data.rage_speed_multiplier if is_raged else 1.0)


func _enter_rage() -> void:
	is_raged = true
	_hitbox.damage = data.contact_damage + data.rage_damage_bonus
	if _rage_tween != null:
		_rage_tween.kill()
	_rage_tween = create_tween()
	_rage_tween.tween_property(_rage_body, "modulate:a", 1.0, data.rage_fade_time)
	raged.emit(self)


func _reset_rage() -> void:
	is_raged = false
	_alive_time = 0.0
	_hitbox.damage = data.contact_damage
	if _rage_tween != null:
		_rage_tween.kill()
	_rage_body.modulate.a = 0.0


func _on_hurt(_amount: int) -> void:
	_freeze_left = data.hit_freeze
	hurt.emit(self)


func _on_health_died() -> void:
	deactivate()
	died.emit(self)
