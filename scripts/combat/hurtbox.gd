class_name Hurtbox
extends Area2D
## Rileva Hitbox e inoltra il danno a un Health. I-frames opzionali (invulnerability_time > 0).

signal hurt(amount: int)
signal knocked(impulse: Vector2)
signal invulnerable_changed(active: bool)
## La barriera ha assorbito un colpo (M10).
signal shield_broken
## Colpo avvelenato (M11.3).
signal poisoned(duration: float, interval: float, damage: int)

@export var health: Health
@export var invulnerability_time: float = 0.0

var _invulnerable: bool = false
## Colpi assorbiti prima di subire danno (barriera). 0 = nessuna.
var shield_charges: int = 0
## Immunita' comandata dall'esterno (scatto del Passo d'ombra): nessun colpo passa finche' e' attiva.
var immune: bool = false
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
	if hitbox == null or not hitbox.active or _invulnerable or immune:
		return
	if health == null or health.is_dead():
		return
	if shield_charges > 0:
		shield_charges -= 1
		hitbox.notify_hit(self)
		# Un solo shield_broken quando la barriera si esaurisce (M12, #86): con piu' cariche
		# (livello > 1) assorbe piu' colpi prima di rompersi, non solo il primo.
		if shield_charges == 0:
			shield_broken.emit()
		# Stessi i-frame del danno reale (M12, #86): senza, un nemico gia' a contatto quando la
		# barriera assorbe il colpo non fa mai piu' scattare area_entered (resta "sovrapposto" senza
		# ri-entrare) e quindi non colpisce mai piu' finche' non si allontana e rientra - sembra
		# invulnerabilita' prolungata quando piu' nemici circondano il player alla rottura. Il timeout
		# di _on_iframe_timeout() ri-scansiona le aree sovrapposte e riprende il normale ciclo di danno.
		if invulnerability_time > 0.0:
			_invulnerable = true
			invulnerable_changed.emit(true)
			_iframe_timer.start(invulnerability_time)
		return
	health.take_damage(hitbox.damage)
	hitbox.notify_hit(self)
	hurt.emit(hitbox.damage)
	if hitbox.poison_duration > 0.0:
		poisoned.emit(hitbox.poison_duration, hitbox.poison_interval, hitbox.poison_damage)
	if hitbox.knockback > 0.0:
		var direction := hitbox.knockback_direction
		if direction == Vector2.ZERO:
			direction = hitbox.global_position.direction_to(global_position)
		knocked.emit(direction.normalized() * hitbox.knockback)
	if invulnerability_time > 0.0:
		_invulnerable = true
		invulnerable_changed.emit(true)
		_iframe_timer.start(invulnerability_time)


func set_immune(active: bool) -> void:
	immune = active
	if not active and not _invulnerable:
		for area in get_overlapping_areas():
			_try_hit(area)
			if _invulnerable:
				return


func _on_iframe_timeout() -> void:
	_invulnerable = false
	invulnerable_changed.emit(false)
	# Contatto continuo: area_entered non riscatta se l'Hitbox e' ancora sovrapposta.
	for area in get_overlapping_areas():
		_try_hit(area)
		if _invulnerable:
			return
