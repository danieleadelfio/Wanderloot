class_name Weapon
extends Node2D
## Arma ranged: gestisce cooldown ed emette la richiesta di sparo. Non istanzia proiettili.
## Nessun tetto alla cadenza: se l'intervallo tra colpi e' piu' corto di un tick di fisica,
## nello stesso tick partono piu' proiettili (cooldown ad accumulatore).

signal fired(origin: Vector2, direction: Vector2, data: WeaponData)

@export var data: WeaponData

var _cooldown: float = 0.0
## Moltiplicatore temporaneo della cadenza (consumabile Furia, M10.1). Non tocca i dati dell'arma.
var rate_multiplier: float = 1.0


func _physics_process(delta: float) -> void:
	# Il cooldown scende fino a -delta: il "credito" di un tick viene speso da try_fire.
	# Non oltre, cosi' dopo una pausa di fuoco non parte una raffica accumulata.
	_cooldown = maxf(_cooldown - delta, -delta)


## Spara tutti i colpi maturati nel tick corrente. Ritorna quanti ne sono partiti.
func try_fire(direction: Vector2) -> int:
	if data == null or data.fire_rate <= 0.0 or _cooldown > 0.0 or direction == Vector2.ZERO:
		return 0
	var interval := 1.0 / (data.fire_rate * maxf(rate_multiplier, 0.01))
	var aim := direction.normalized()
	var shots := 0
	while _cooldown <= 0.0:
		_cooldown += interval
		shots += 1
	var count := maxi(data.projectile_count, 1)
	# Ventaglio centrato sulla mira; oltre 360° gli spazi si comprimono per coprire il cerchio.
	var step := deg_to_rad(minf(data.spread_degrees, 360.0 / count))
	for i in shots:
		# Colpi dello stesso tick sfalsati lungo la traiettoria, come se sparati in istanti diversi.
		var age := (shots - 1 - i) * interval
		for k in count:
			var direction_k := aim.rotated((k - (count - 1) * 0.5) * step)
			fired.emit(global_position + direction_k * data.projectile_speed * age, direction_k, data)
	return shots
