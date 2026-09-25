class_name Player
extends CharacterBody2D
## Player twin-stick: movimento 8 direzioni, mira mouse (tenendo "shoot") o stick destro (auto-fire).

signal shot_requested(origin: Vector2, direction: Vector2, data: WeaponData)
signal died
## Scatto del Passo d'ombra (per il suono).
signal dashed

const AIM_DEADZONE: float = 0.3

@export var stats: PlayerStats
## Falso nell'hub: il player cammina ma non spara.
@export var weapon_enabled: bool = true

## Riferimenti ai .tres base (condivisi, mai modificati): ogni run parte da copie fresche.
var _base_stats: PlayerStats
var _frenzy_token: int = 0
var _base_weapon: WeaponData
## Passo d'ombra (M11.1): niente sparo, lo sparo diventa uno scatto invulnerabile a cariche.
var dash_mode: bool = false
var dash_charges := DashCharges.new()
var _dash_speed: float = 0.0
var _dash_duration: float = 0.0
var _dash_left: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
## Attrazione esterna di questo tick (buco nero), sommata al movimento e poi azzerata.
var _pull: Vector2 = Vector2.ZERO

@onready var health: Health = %Health
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _weapon: Weapon = %Weapon
@onready var _knockback: Knockback = %Knockback
## Luce portata dal player (atmosfera cupa, M7): colore/energia/raggio li imposta la scena che lo ospita.
@onready var light: PointLight2D = %Light
@onready var _shield: Node2D = %Shield
@onready var _body: CanvasItem = %Body
@onready var _dash_ring: DashRing = %DashRing
## Veleno (M11.3): applicato dai colpi avvelenati, azzerato a inizio run.
@onready var poison: Poison = %Poison


func _ready() -> void:
	_base_stats = stats
	_base_weapon = _weapon.data
	_weapon.fired.connect(shot_requested.emit)
	health.died.connect(died.emit)
	_hurtbox.knocked.connect(_knockback.apply)
	_hurtbox.shield_broken.connect(set_shield.bind(false))
	_hurtbox.poisoned.connect(poison.apply)
	begin_run([])


## Prepara le stats della run: copie fresche dei .tres base + equipaggiamento permanente.
## Upgrade ed equip lavorano solo su queste copie, mai sui .tres condivisi.
func begin_run(equipment: Array[StatModifier]) -> void:
	stats = _base_stats.duplicate()
	_weapon.data = _base_weapon.duplicate()
	StatApplier.apply_modifiers(equipment, stats, _weapon.data)
	health.reset(stats.max_hp)
	poison.clear()
	_knockback.reset()
	set_shield(false)
	_hurtbox.invulnerability_time = stats.invulnerability_time


func _physics_process(delta: float) -> void:
	var move_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_knockback.step(delta)
	if dash_mode:
		_dash_step(delta, move_dir)
		return
	velocity = move_dir * stats.move_speed + _knockback.velocity + _pull
	_pull = Vector2.ZERO
	move_and_slide()
	var aim := _get_aim_direction()
	if weapon_enabled and aim != Vector2.ZERO:
		_weapon.try_fire(aim)


## Passo d'ombra: cariche e secondi dal .tres dell'evento. Lo sparo resta bloccato fino a stop_dash_mode().
func start_dash_mode(event: RunEventData) -> void:
	dash_mode = true
	dash_charges.reset(event.dash_charges, event.dash_recharge)
	_dash_speed = event.dash_speed
	_dash_duration = event.dash_duration
	_dash_ring.show()
	_refresh_dash_ring()


func stop_dash_mode() -> void:
	_end_dash()
	dash_mode = false
	_dash_ring.hide()


## Scatto verso direction (se nulla: verso il mouse). false senza cariche, fuori dall'evento o gia' in scatto.
func try_dash(direction: Vector2) -> bool:
	if not dash_mode or is_dashing() or not dash_charges.try_use():
		return false
	if direction == Vector2.ZERO:
		direction = _mouse_aim_direction()
	_dash_direction = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	_dash_left = _dash_duration
	_hurtbox.set_immune(true)
	_body.modulate = Color(0.55, 0.7, 1.0, 0.45)
	_refresh_dash_ring()
	dashed.emit()
	return true


func is_dashing() -> bool:
	return _dash_left > 0.0


func is_immune() -> bool:
	return _hurtbox.immune


func _dash_step(delta: float, move_dir: Vector2) -> void:
	dash_charges.tick(delta)
	if is_dashing():
		_dash_left -= delta
		velocity = _dash_direction * _dash_speed
		move_and_slide()
		if _dash_left <= 0.0:
			_end_dash()
	else:
		velocity = move_dir * stats.move_speed + _knockback.velocity
		move_and_slide()
		if Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("dash"):
			var aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", AIM_DEADZONE)
			try_dash(move_dir if move_dir != Vector2.ZERO else aim)
	_refresh_dash_ring()


func _end_dash() -> void:
	if _dash_left <= 0.0 and not _hurtbox.immune:
		return
	_dash_left = 0.0
	_body.modulate = Color.WHITE
	_hurtbox.set_immune(false)


func _refresh_dash_ring() -> void:
	_dash_ring.show_charges(dash_charges.charges, dash_charges.max_charges, dash_charges.partial())


## Attrazione di un buco nero per questo tick (px/s), si somma tra piu' sorgenti.
func add_pull(force: Vector2) -> void:
	_pull += force


## Arma della run (copia con equip e potenziamenti applicati): letta per le statistiche a schermo.
func weapon_data() -> WeaponData:
	return _weapon.data


## Barriera (abilita' Barriera arcana): annulla il prossimo colpo.
func set_shield(active: bool, charges: int = 1) -> void:
	_hurtbox.shield_charges = maxi(charges, 1) if active else 0
	_shield.visible = active


## Furia (consumabile): cadenza moltiplicata per `seconds`; si ferma con la pausa del gioco.
func boost_fire_rate(multiplier: float, seconds: float) -> void:
	_frenzy_token += 1
	var token := _frenzy_token
	_weapon.rate_multiplier = multiplier
	await get_tree().create_timer(seconds, false).timeout
	# Una Furia raccolta nel frattempo rinnova la durata: vale solo l'ultima.
	if is_inside_tree() and token == _frenzy_token:
		_weapon.rate_multiplier = 1.0


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
		return _mouse_aim_direction()
	return Vector2.ZERO


## Direzione verso il mouse, con l'asse orizzontale invertito se attiva l'opzione mancini (M12, #86).
func _mouse_aim_direction() -> Vector2:
	var dir := global_position.direction_to(get_global_mouse_position())
	if InputSettings.mouse_invert_x:
		dir.x = -dir.x
	return dir
