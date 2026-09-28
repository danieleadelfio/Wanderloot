class_name PoisonState
extends RefCounted
## Veleno (M11.3, #73), logica pura: `damage` ogni `interval` secondi per `duration` secondi.
## Un nuovo colpo rinnova la durata senza sommare il danno.

var remaining: float = 0.0
var interval: float = 1.5
var damage: int = 1
var _tick_left: float = 0.0


## first_tick: secondi al primo danno di una nuova applicazione (< 0 = un intervallo, come il veleno).
## La lava (M13, #86) lo usa corto, se no entrando e uscendo di continuo non si prendeva mai danno.
func apply(duration: float, every: float, amount: int, first_tick: float = -1.0) -> void:
	var was_active := is_active()
	remaining = maxf(remaining, duration)
	interval = maxf(every, 0.05)
	damage = amount
	if not was_active:
		_tick_left = interval if first_tick < 0.0 else first_tick


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
