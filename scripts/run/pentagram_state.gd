class_name PentagramState
extends RefCounted
## Regole del Pentagramma di sangue (logica pura, testata), M13 #86: l'evento parte gia' attivo
## (trigger = interazione con la statua, gestita da RunEventDirector/PentagramStatue, non piu' un
## ingresso col timeout). Da quel momento bisogna restare dentro il cerchio finche' non si spengono
## tutte le candele: uscire fa fallire subito.

enum Status { IDLE, ACTIVE, COMPLETED, FAILED }

var status: Status = Status.IDLE
var candle_count: int = 15
## Secondi in cui le candele restano tutte accese prima di iniziare a spegnersi (una al secondo).
var start_extinguish_after: float = 10.0
var held: float = 0.0


func start(count: int, extinguish_after: float) -> void:
	candle_count = count
	start_extinguish_after = extinguish_after
	held = 0.0
	status = Status.ACTIVE


func tick(delta: float, inside: bool) -> Status:
	if status == Status.ACTIVE:
		if not inside:
			status = Status.FAILED
		else:
			held += delta
			if held >= _total_duration():
				status = Status.COMPLETED
	return status


## Candele ancora accese: tutte per i primi start_extinguish_after secondi, poi una in meno al secondo.
func candles_lit() -> int:
	if status != Status.ACTIVE:
		return 0
	if held < start_extinguish_after:
		return candle_count
	return clampi(candle_count - floori(held - start_extinguish_after), 0, candle_count)


## Tempo rimasto (0..1) per la barra, da resistere nel cerchio fino a candele spente.
func remaining_ratio() -> float:
	if status == Status.ACTIVE:
		return clampf(1.0 - held / maxf(_total_duration(), 0.001), 0.0, 1.0)
	return 0.0


func _total_duration() -> float:
	return start_extinguish_after + candle_count
