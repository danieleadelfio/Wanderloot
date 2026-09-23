class_name Player
extends CharacterBody2D
## Player twin-stick: movimento 8 direzioni, mira mouse (tenendo "shoot") o stick destro (auto-fire).

signal shot_requested(origin: Vector2, direction: Vector2, data: WeaponData)
signal died

const AIM_DEADZONE: float = 0.3

@export var stats: PlayerStats

@onready var health: Health = %Health
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _weapon: Weapon = %Weapon


func _ready() -> void:
	health.reset(stats.max_hp)
	_hurtbox.invulnerability_time = stats.invulnerability_time
	_weapon.fired.connect(shot_requested.emit)
	health.died.connect(died.emit)


func _physics_process(_delta: float) -> void:
	var move_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = move_dir * stats.move_speed
	move_and_slide()
	var aim := _get_aim_direction()
	if aim != Vector2.ZERO:
		_weapon.try_fire(aim)


func _get_aim_direction() -> Vector2:
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", AIM_DEADZONE)
	if stick != Vector2.ZERO:
		return stick.normalized()
	if Input.is_action_pressed("shoot"):
		return global_position.direction_to(get_global_mouse_position())
	return Vector2.ZERO
