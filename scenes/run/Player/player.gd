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
	# Copie di run: gli upgrade non devono mai toccare i .tres condivisi.
	stats = stats.duplicate()
	_weapon.data = _weapon.data.duplicate()
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


func apply_upgrade(upgrade: UpgradeData) -> void:
	var weapon := _weapon.data
	match upgrade.stat:
		UpgradeData.Stat.DAMAGE:
			weapon.damage = roundi(upgrade.apply_to(weapon.damage))
		UpgradeData.Stat.FIRE_RATE:
			weapon.fire_rate = upgrade.apply_to(weapon.fire_rate)
		UpgradeData.Stat.PROJECTILE_SPEED:
			weapon.projectile_speed = upgrade.apply_to(weapon.projectile_speed)
		UpgradeData.Stat.MOVE_SPEED:
			stats.move_speed = upgrade.apply_to(stats.move_speed)
		UpgradeData.Stat.MAX_HP:
			stats.max_hp = roundi(upgrade.apply_to(stats.max_hp))
			health.set_max_hp(stats.max_hp)


func _get_aim_direction() -> Vector2:
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", AIM_DEADZONE)
	if stick != Vector2.ZERO:
		return stick.normalized()
	if Input.is_action_pressed("shoot"):
		return global_position.direction_to(get_global_mouse_position())
	return Vector2.ZERO
