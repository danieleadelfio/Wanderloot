class_name DashCharges
extends RefCounted
## Cariche dello scatto (evento Passo d'ombra, M11.1 #63). Logica pura: uno scatto consuma una carica,
## una carica torna ogni recharge_time secondi.

var max_charges: int = 6
var recharge_time: float = 2.0
var charges: int = 6
var _progress: float = 0.0


func reset(count: int, seconds: float) -> void:
	max_charges = maxi(count, 1)
	recharge_time = maxf(seconds, 0.01)
	charges = max_charges
	_progress = 0.0


func try_use() -> bool:
	if charges <= 0:
		return false
	charges -= 1
	return true


func tick(delta: float) -> void:
	if charges >= max_charges:
		_progress = 0.0
		return
	_progress += delta
	while _progress >= recharge_time and charges < max_charges:
		_progress -= recharge_time
		charges += 1
	if charges >= max_charges:
		_progress = 0.0


## Frazione della carica in ricarica (0..1), per lo spicchio che si riempie.
func partial() -> float:
	return _progress / recharge_time if charges < max_charges else 0.0
