class_name PoisonState
extends RefCounted
## Veleno (M11.3, #73), logica pura: `damage` ogni `interval` secondi per `duration` secondi.
## Un nuovo colpo rinnova la durata senza sommare il danno.

var remaining: float = 0.0
var interval: float = 1.5
var damage: int = 1
var _tick_left: float = 0.0


func apply(duration: float, every: float, amount: int) -> void:
	var was_active := is_active()
	remaining = maxf(remaining, duration)
	interval = maxf(every, 0.05)
	damage = amount
	if not was_active:
		_tick_left = interval


func is_active() -> bool:
	return remaining > 0.0


## Danno da infliggere in questo tick (0 se nessuno).
func tick(delta: float) -> int:
	if not is_active():
		return 0
	var dealt := 0
	var step := minf(delta, remaining)
	remaining -= step
	_tick_left -= step
	while _tick_left <= 0.0001:
		dealt += damage
		_tick_left += interval
	if remaining <= 0.0001:
		remaining = 0.0
	return dealt
