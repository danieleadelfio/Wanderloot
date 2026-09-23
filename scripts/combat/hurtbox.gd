class_name Hurtbox
extends Area2D
## Rileva Hitbox e inoltra il danno a un Health. I-frames opzionali (invulnerability_time > 0).

signal hurt(amount: int)
signal knocked(impulse: Vector2)
signal invulnerable_changed(active: bool)

@export var health: Health
@export var invulnerability_time: float = 0.0

var _invulnerable: bool = false
var _iframe_timer: Timer


func _ready() -> void:
	monitorable = false
	_iframe_timer = Timer.new()
	_iframe_timer.one_shot = true
	add_child(_iframe_timer)
	_iframe_timer.timeout.connect(_on_iframe_timeout)
	area_entered.connect(_try_hit)


func _try_hit(area: Area2D) -> void:
	var hitbox := area as Hitbox
	if hitbox == null or not hitbox.active or _invulnerable:
		return
	if health == null or health.is_dead():
		return
	health.take_damage(hitbox.damage)
	hitbox.notify_hit(self)
	hurt.emit(hitbox.damage)
	if hitbox.knockback > 0.0:
		var direction := hitbox.knockback_direction
		if direction == Vector2.ZERO:
			direction = hitbox.global_position.direction_to(global_position)
		knocked.emit(direction.normalized() * hitbox.knockback)
	if invulnerability_time > 0.0:
		_invulnerable = true
		invulnerable_changed.emit(true)
		_iframe_timer.start(invulnerability_time)


func _on_iframe_timeout() -> void:
	_invulnerable = false
	invulnerable_changed.emit(false)
	# Contatto continuo: area_entered non riscatta se l'Hitbox e' ancora sovrapposta.
	for area in get_overlapping_areas():
		_try_hit(area)
		if _invulnerable:
			return
