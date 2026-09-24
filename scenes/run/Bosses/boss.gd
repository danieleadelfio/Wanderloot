class_name Boss
extends CharacterBody2D
## Boss generico guidato da BossData: insegue, sceglie un attacco per peso e fase, lo preannuncia
## (cerchio rosso o carica sul posto), lo esegue e si ferma a recuperare. Nessun pool: uno per run.
## Un boss nuovo = scena che usa questo script + BossData + BossAttack (.tres), senza codice nuovo.

signal died(boss: Boss)
signal hurt(boss: Boss)
signal shot_requested(origin: Vector2, direction: Vector2, weapon: WeaponData)
signal attack_started(attack: BossAttack)
signal slammed(at: Vector2, radius: float)
signal phase_changed(phase: int)

enum State { CHASE, WINDUP, FIRE, LEAP, RECOVER, DEAD }

@export var data: BossData
## Raggio della carica mostrata attorno al boss prima di una raffica.
@export var windup_radius: float = 70.0

var target: Node2D
var phase: int = 1
var state: State = State.CHASE
var _timer: float = 0.0
var _attack: BossAttack
var _repeats_left: int = 0
var _repeat_index: int = 0
var _leap_from: Vector2 = Vector2.ZERO
var _leap_to: Vector2 = Vector2.ZERO
var _rng := RandomNumberGenerator.new()

@onready var health: Health = %Health
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _hitbox: Hitbox = %Hitbox
@onready var _body: Node2D = %Body
@onready var _impact: Telegraph = %Impact
@onready var _windup: Telegraph = %Windup
@onready var _hit_flash: HitFlash = %HitFlash


func _ready() -> void:
	_rng.randomize()
	_hitbox.damage = data.contact_damage
	_hitbox.knockback = data.contact_knockback
	health.reset(data.max_hp)
	health.died.connect(_on_health_died)
	health.changed.connect(_on_health_changed)
	_hurtbox.hurt.connect(hurt.emit.bind(self).unbind(1))
	_hurtbox.hurt.connect(_hit_flash.flash)
	_timer = data.first_attack_delay


## Centro e raggio del cerchio di impatto se attivo (per il bot di playtest); raggio 0 = nessuno.
func danger_zone() -> Vector3:
	if _impact.is_running():
		return Vector3(_impact.global_position.x, _impact.global_position.y, _impact.radius)
	return Vector3.ZERO


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_timer -= delta
	match state:
		State.CHASE:
			_move(1.0)
			if _timer <= 0.0:
				_begin_attack()
		State.WINDUP:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_execute()
		State.FIRE:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_fire_volley()
		State.LEAP:
			var t := 1.0 - clampf(_timer / _attack.leap_time, 0.0, 1.0)
			global_position = _leap_from.lerp(_leap_to, t)
			_body.position.y = -sin(t * PI) * _attack.leap_height
			if _timer <= 0.0:
				_land()
		State.RECOVER:
			_move(0.3)
			if _timer <= 0.0:
				state = State.CHASE
				_timer = data.chase_time * _tempo()


func _move(speed_scale: float) -> void:
	if not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	var speed := data.move_speed * (data.phase_two_speed_multiplier if phase == 2 else 1.0)
	velocity = global_position.direction_to(target.global_position) * speed * speed_scale
	move_and_slide()


func _tempo() -> float:
	return data.phase_two_tempo_multiplier if phase == 2 else 1.0


func _begin_attack() -> void:
	var index := BossAttack.pick_index(data.attacks, phase, _rng)
	if index < 0 or not is_instance_valid(target):
		_timer = data.chase_time
		return
	_attack = data.attacks[index]
	state = State.WINDUP
	_timer = _attack.telegraph_time
	if _attack.kind == BossAttack.Kind.LEAP_SLAM:
		# Il bersaglio e' fissato ora: il player ha telegraph_time + leap_time per uscire dal cerchio.
		_leap_to = target.global_position
		_impact.start(_leap_to, _attack.radius, _attack.telegraph_time + _attack.leap_time, _attack.damage, _attack.knockback)
	else:
		_windup.start(global_position, windup_radius, _attack.telegraph_time)
	attack_started.emit(_attack)


func _execute() -> void:
	if _attack.kind == BossAttack.Kind.LEAP_SLAM:
		state = State.LEAP
		_timer = _attack.leap_time
		_leap_from = global_position
		_hitbox.active = false
		return
	state = State.FIRE
	_repeats_left = maxi(_attack.repeats, 1)
	_repeat_index = 0
	_timer = 0.0


func _fire_volley() -> void:
	var directions: Array[Vector2]
	if _attack.kind == BossAttack.Kind.RING:
		directions = BossPatterns.ring(_attack.projectile_count, deg_to_rad(_attack.ring_rotation_degrees) * _repeat_index)
	else:
		var aim := global_position.direction_to(target.global_position) if is_instance_valid(target) else Vector2.DOWN
		directions = BossPatterns.fan(aim, _attack.projectile_count, _attack.spread_degrees)
	_shoot(directions)
	_repeat_index += 1
	_repeats_left -= 1
	if _repeats_left > 0:
		_timer = _attack.repeat_interval
	else:
		_recover()


func _land() -> void:
	global_position = _leap_to
	_body.position.y = 0.0
	_hitbox.active = true
	slammed.emit(_leap_to, _attack.radius)
	_shoot(BossPatterns.ring(_attack.projectile_count, _rng.randf() * TAU))
	_recover()


func _shoot(directions: Array[Vector2]) -> void:
	if _attack.projectile == null:
		return
	for direction in directions:
		shot_requested.emit(global_position, direction, _attack.projectile)


func _recover() -> void:
	state = State.RECOVER
	_timer = _attack.recovery * _tempo()


func _on_health_changed(current: int, maximum: int) -> void:
	var new_phase := data.phase_for(float(current) / maxf(maximum, 1))
	if new_phase > phase:
		phase = new_phase
		_body.modulate = data.phase_two_tint
		phase_changed.emit(phase)


func _on_health_died() -> void:
	state = State.DEAD
	_impact.stop()
	_windup.stop()
	_hitbox.active = false
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	died.emit(self)
