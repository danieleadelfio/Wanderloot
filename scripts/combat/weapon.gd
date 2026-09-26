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
## Mana da cui attinge lo sparo base (M12, #86): null o data.mana_cost <= 0 = nessun costo, spara
## sempre (retrocompatibile con le WeaponData senza costo e con chi non assegna mana, es. i test).
var mana: Mana


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
	var count := maxi(data.projectile_count, 1)
	# Costo per attivazione moltiplicato per i proiettili del Ventaglio (M13, #86): un colpo a ventaglio
	# vale di piu' (piu' danno/proiettili), quindi costa di piu', non lo stesso di un colpo singolo.
	var cost := data.mana_cost * count
	var shots := 0
	while _cooldown <= 0.0:
		# A corto di mana: il colpo resta "in credito" (cooldown non consumato), riprende non appena il
		# pool rigenera abbastanza, invece di perderlo o sparare gratis.
		if mana and cost > 0.0 and not mana.spend(cost):
			break
		_cooldown += interval
		shots += 1
	# Ventaglio centrato sulla mira; oltre 360° gli spazi si comprimono per coprire il cerchio.
	var step := deg_to_rad(minf(data.spread_degrees, 360.0 / count))
	for i in shots:
		# Colpi dello stesso tick sfalsati lungo la traiettoria, come se sparati in istanti diversi.
		var age := (shots - 1 - i) * interval
		for k in count:
			var direction_k := aim.rotated((k - (count - 1) * 0.5) * step)
			fired.emit(global_position + direction_k * data.projectile_speed * age, direction_k, data)
	return shots
