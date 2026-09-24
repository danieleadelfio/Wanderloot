class_name Player
extends CharacterBody2D
## Player twin-stick: movimento 8 direzioni, mira mouse (tenendo "shoot") o stick destro (auto-fire).

signal shot_requested(origin: Vector2, direction: Vector2, data: WeaponData)
signal died

const AIM_DEADZONE: float = 0.3

@export var stats: PlayerStats
## Falso nell'hub: il player cammina ma non spara.
@export var weapon_enabled: bool = true

## Riferimenti ai .tres base (condivisi, mai modificati): ogni run parte da copie fresche.
var _base_stats: PlayerStats
var _base_weapon: WeaponData

@onready var health: Health = %Health
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _weapon: Weapon = %Weapon
@onready var _knockback: Knockback = %Knockback
## Luce portata dal player (atmosfera cupa, M7): colore/energia/raggio li imposta la scena che lo ospita.
@onready var light: PointLight2D = %Light
@onready var _shield: Node2D = %Shield


func _ready() -> void:
	_base_stats = stats
	_base_weapon = _weapon.data
	_weapon.fired.connect(shot_requested.emit)
	health.died.connect(died.emit)
	_hurtbox.knocked.connect(_knockback.apply)
	_hurtbox.shield_broken.connect(set_shield.bind(false))
	begin_run([])


## Prepara le stats della run: copie fresche dei .tres base + equipaggiamento permanente.
## Upgrade ed equip lavorano solo su queste copie, mai sui .tres condivisi.
func begin_run(equipment: Array[EquipmentData]) -> void:
	stats = _base_stats.duplicate()
	_weapon.data = _base_weapon.duplicate()
	StatApplier.apply_equipment(equipment, stats, _weapon.data)
	health.reset(stats.max_hp)
	_knockback.reset()
	set_shield(false)
	_hurtbox.invulnerability_time = stats.invulnerability_time


func _physics_process(delta: float) -> void:
	var move_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_knockback.step(delta)
	velocity = move_dir * stats.move_speed + _knockback.velocity
	move_and_slide()
	var aim := _get_aim_direction()
	if weapon_enabled and aim != Vector2.ZERO:
		_weapon.try_fire(aim)


## Arma della run (copia con equip e potenziamenti applicati): letta per le statistiche a schermo.
func weapon_data() -> WeaponData:
	return _weapon.data


## Barriera (abilita' Barriera arcana): annulla il prossimo colpo.
func set_shield(active: bool) -> void:
	_hurtbox.shield_charges = 1 if active else 0
	_shield.visible = active


func has_shield() -> bool:
	return _hurtbox.shield_charges > 0


func apply_upgrade(upgrade: UpgradeData) -> void:
	StatApplier.apply(upgrade.stat, upgrade.amount, upgrade.is_multiplier, stats, _weapon.data)
	match upgrade.stat:
		UpgradeData.Stat.MAX_HP:
			health.set_max_hp(stats.max_hp)
		UpgradeData.Stat.INVULNERABILITY:
			_hurtbox.invulnerability_time = stats.invulnerability_time


func _get_aim_direction() -> Vector2:
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", AIM_DEADZONE)
	if stick != Vector2.ZERO:
		return stick.normalized()
	if Input.is_action_pressed("shoot"):
		return global_position.direction_to(get_global_mouse_position())
	return Vector2.ZERO
