class_name Boss
extends CharacterBody2D
## Boss generico guidato da BossData: insegue, sceglie un attacco per peso e fase, lo preannuncia
## (cerchio rosso, corsia, carica sul posto), lo esegue e si ferma a recuperare. Nessun pool.
## Un boss nuovo = scena che usa questo script + BossData + BossAttack (.tres), senza codice nuovo.
## Attacchi: raffica a ventaglio, anello, salto (anche a catena), evocazione, pioggia di cerchi,
## carica in linea, pestone sul posto, urlo (rage dei nemici); teletrasporto dopo l'attacco.

signal died(boss: Boss)
signal hurt(boss: Boss)
signal shot_requested(origin: Vector2, direction: Vector2, weapon: WeaponData)
signal attack_started(attack: BossAttack)
signal slammed(at: Vector2, radius: float)
signal phase_changed(phase: int)
## Evocazione: la composition root crea i nemici (dai pool dell'arena) attorno a `at`.
signal summon_requested(scene: PackedScene, count: int, at: Vector2)
## Urlo: la composition root manda in rage i nemici vivi.
signal scream_requested
signal teleported

enum State { CHASE, WINDUP, FIRE, LEAP, RECOVER, DEAD, CHARGE }

## Vita di tutti i boss moltiplicata (M11.3): vale per ogni BossData, anche futuri.
const HP_MULTIPLIER: float = 2.0
const TELEGRAPH := preload("res://scenes/run/Telegraph/Telegraph.tscn")
const EXTRA_TELEGRAPHS: int = 12
const LANE_STEP: float = 64.0
const RAIN_COLOR := Color(1, 0.18, 0.12)
## Corsia della carica: arancione, solo preavviso (il danno e' il contatto col boss).
const LANE_COLOR := Color(1, 0.6, 0.2)

@export var data: BossData
## Raggio della carica mostrata attorno al boss prima di una raffica.
@export var windup_radius: float = 70.0

var target: Node2D
## Area in cui il boss puo' ricomparire (teletrasporto) e cadono i cerchi; la imposta l'arena.
var bounds: Rect2 = Rect2(-7000.0, -4000.0, 14000.0, 8000.0)
var phase: int = 1
var state: State = State.CHASE
var _timer: float = 0.0
var _attack: BossAttack
var _repeats_left: int = 0
var _repeat_index: int = 0
var _chain_left: int = 0
var _leap_from: Vector2 = Vector2.ZERO
var _leap_to: Vector2 = Vector2.ZERO
var _charge_direction: Vector2 = Vector2.ZERO
var _charge_left: float = 0.0
var _extra: Array[Telegraph] = []
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
	health.reset(scaled_max_hp(data))
	health.died.connect(_on_health_died)
	health.changed.connect(_on_health_changed)
	_hurtbox.hurt.connect(hurt.emit.bind(self).unbind(1))
	_hurtbox.hurt.connect(_hit_flash.flash)
	for i in EXTRA_TELEGRAPHS:
		var telegraph: Telegraph = TELEGRAPH.instantiate()
		telegraph.top_level = true
		telegraph.attack_layer = _impact.attack_layer
		add_child(telegraph)
		_extra.append(telegraph)
	_timer = data.first_attack_delay


static func scaled_max_hp(boss_data: BossData) -> int:
	return roundi(boss_data.max_hp * HP_MULTIPLIER)


## Centro e raggio del cerchio di impatto se attivo (per il bot di playtest); raggio 0 = nessuno.
func danger_zone() -> Vector3:
	var zones := danger_zones()
	return zones[0] if not zones.is_empty() else Vector3.ZERO


## Tutti i cerchi attivi (impatto, pioggia, corsia della carica), per il bot di playtest.
func danger_zones() -> Array[Vector3]:
	var zones: Array[Vector3] = []
	for telegraph in [_impact] + _extra:
		if telegraph.is_running():
			zones.append(Vector3(telegraph.global_position.x, telegraph.global_position.y, telegraph.radius))
	return zones


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
		State.CHARGE:
			velocity = _charge_direction * _attack.charge_speed
			move_and_slide()
			_charge_left -= _attack.charge_speed * delta
			if _charge_left <= 0.0 or get_slide_collision_count() > 0:
				_recover()
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
	start_attack(data.attacks[index])


## Avvia un attacco preciso (anche dai test).
func start_attack(attack: BossAttack) -> void:
	_attack = attack
	state = State.WINDUP
	_timer = _attack.telegraph_time
	var aim := target.global_position if is_instance_valid(target) else global_position + Vector2.DOWN
	match _attack.kind:
		BossAttack.Kind.LEAP_SLAM:
			# Il bersaglio e' fissato ora: il player ha telegraph_time + leap_time per uscire dal cerchio.
			_chain_left = maxi(_attack.repeats, 1) - 1
			_leap_to = aim
			_impact.start(_leap_to, _attack.radius, _attack.telegraph_time + _attack.leap_time, _attack.damage, _attack.knockback)
		BossAttack.Kind.STOMP:
			_impact.start(global_position, _attack.radius, _attack.telegraph_time, _attack.damage, _attack.knockback)
		BossAttack.Kind.RAIN:
			for i in mini(_attack.rain_count, _extra.size()):
				var offset := Vector2.ZERO if i == 0 else Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(_attack.radius, _attack.rain_spread)
				var point := (aim + offset).clamp(bounds.position, bounds.end)
				_extra[i].color = RAIN_COLOR
				_extra[i].start(point, _attack.radius, _attack.telegraph_time, _attack.damage, _attack.knockback)
		BossAttack.Kind.CHARGE:
			_charge_direction = global_position.direction_to(aim)
			var steps := mini(int(_attack.charge_distance / LANE_STEP), _extra.size())
			for i in steps:
				_extra[i].color = LANE_COLOR
				_extra[i].start(global_position + _charge_direction * LANE_STEP * (i + 1), _attack.charge_lane_radius, _attack.telegraph_time)
		_:
			if _attack.show_windup:
				_windup.start(global_position, windup_radius, _attack.telegraph_time)
	attack_started.emit(_attack)


func _execute() -> void:
	match _attack.kind:
		BossAttack.Kind.LEAP_SLAM:
			state = State.LEAP
			_timer = _attack.leap_time
			_leap_from = global_position
			_hitbox.active = false
			return
		BossAttack.Kind.STOMP:
			slammed.emit(global_position, _attack.radius)
			_shoot(BossPatterns.ring(_attack.projectile_count, _rng.randf() * TAU))
			_recover()
			return
		BossAttack.Kind.RAIN:
			_shoot(BossPatterns.ring(_attack.projectile_count, _rng.randf() * TAU))
			_recover()
			return
		BossAttack.Kind.CHARGE:
			state = State.CHARGE
			_charge_left = _attack.charge_distance
			return
		BossAttack.Kind.SUMMON:
			if _attack.summon_scene:
				summon_requested.emit(_attack.summon_scene, _attack.summon_count, global_position)
			_recover()
			return
		BossAttack.Kind.SCREAM:
			scream_requested.emit()
			_recover()
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
	# Balzi a catena: nuovo cerchio sul player con un preavviso piu' breve (repeat_interval).
	if _chain_left > 0 and is_instance_valid(target):
		_chain_left -= 1
		state = State.WINDUP
		_timer = _attack.repeat_interval
		_leap_to = target.global_position
		_impact.start(_leap_to, _attack.radius, _attack.repeat_interval + _attack.leap_time, _attack.damage, _attack.knockback)
		return
	_recover()


func _shoot(directions: Array[Vector2]) -> void:
	if _attack.projectile == null:
		return
	for direction in directions:
		shot_requested.emit(global_position, direction, _attack.projectile)


func _recover() -> void:
	state = State.RECOVER
	_timer = _attack.recovery * _tempo()
	if _attack.teleport_after:
		_teleport()


## Svanisce e ricompare lontano dal player, dentro bounds.
func _teleport() -> void:
	var from := target.global_position if is_instance_valid(target) else global_position
	var point := SpawnUtils.random_point_away(bounds, from, data.teleport_distance)
	var tween := create_tween()
	tween.tween_property(_body, "modulate:a", 0.0, 0.18)
	tween.tween_callback(func() -> void:
		global_position = point
		reset_physics_interpolation()
		teleported.emit())
	tween.tween_property(_body, "modulate:a", 1.0, 0.25)


func _on_health_changed(current: int, maximum: int) -> void:
	var new_phase := data.phase_for(float(current) / maxf(maximum, 1))
	if new_phase > phase:
		phase = new_phase
		_body.modulate = data.phase_two_tint
		phase_changed.emit(phase)
		if data.phase_two_summon_scene and data.phase_two_summon_count > 0:
			summon_requested.emit(data.phase_two_summon_scene, data.phase_two_summon_count, global_position)


func _on_health_died() -> void:
	state = State.DEAD
	_impact.stop()
	_windup.stop()
	for telegraph in _extra:
		telegraph.stop()
	_hitbox.active = false
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	died.emit(self)
