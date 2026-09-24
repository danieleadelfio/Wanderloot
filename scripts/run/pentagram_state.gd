class_name PentagramState
extends RefCounted
## Regole del Pentagramma di sangue (logica pura, testata): attesa finche' il player entra (con timeout),
## poi bisogna restare dentro `hold` secondi; uscire o non entrare in tempo = fallimento.

enum Status { IDLE, WAITING, ACTIVE, COMPLETED, FAILED }

var status: Status = Status.IDLE
var timeout: float = 20.0
var hold: float = 15.0
var candles: int = 15
var waited: float = 0.0
var held: float = 0.0


func start(wait_timeout: float, hold_time: float, candle_count: int) -> void:
	timeout = wait_timeout
	hold = hold_time
	candles = candle_count
	waited = 0.0
	held = 0.0
	status = Status.WAITING


func tick(delta: float, inside: bool) -> Status:
	match status:
		Status.WAITING:
			if inside:
				status = Status.ACTIVE
			else:
				waited += delta
				if waited >= timeout:
					status = Status.FAILED
		Status.ACTIVE:
			if not inside:
				status = Status.FAILED
			else:
				held += delta
				if held >= hold:
					status = Status.COMPLETED
	return status


## Candele ancora accese: tutte in attesa, una in meno ogni hold/candles secondi nel cerchio.
func candles_lit() -> int:
	match status:
		Status.WAITING:
			return candles
		Status.ACTIVE:
			return clampi(candles - floori(held / (hold / maxi(candles, 1))), 0, candles)
	return 0


## Tempo rimasto (0..1) per la barra: per entrare in attesa, da resistere nel cerchio.
func remaining_ratio() -> float:
	if status == Status.WAITING:
		return clampf(1.0 - waited / maxf(timeout, 0.001), 0.0, 1.0)
	if status == Status.ACTIVE:
		return clampf(1.0 - held / maxf(hold, 0.001), 0.0, 1.0)
	return 0.0
