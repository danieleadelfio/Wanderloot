class_name WaveData
extends Resource
## Curva di spawn dei nemici nel tempo. Bilanciamento solo nei .tres in res://data/waves/.

## Intervallo tra due batch a inizio run (secondi).
@export var start_interval: float = 2.0
## Intervallo minimo raggiungibile (secondi).
@export var min_interval: float = 0.5
## Secondi di intervallo tolti per ogni secondo di run.
@export var interval_decay: float = 0.015
@export var start_batch: int = 1
## Ogni N secondi di run il batch cresce di 1 nemico.
@export var batch_growth_period: float = 25.0
## Tetto di nemici vivi contemporaneamente.
@export var max_alive: int = 60
## Ogni N secondi il tetto di nemici vivi cresce di max_alive_growth: la pressione non si ferma
## mai, restare in arena oltre l'estrazione non diventa farming senza rischio. 0 = tetto fisso.
@export var max_alive_growth_period: float = 30.0
@export var max_alive_growth: int = 5


func interval_at(elapsed: float) -> float:
	return maxf(min_interval, start_interval - interval_decay * elapsed)


func batch_at(elapsed: float) -> int:
	return start_batch + int(elapsed / batch_growth_period)


func max_alive_at(elapsed: float) -> int:
	if max_alive_growth_period <= 0.0:
		return max_alive
	return max_alive + int(elapsed / max_alive_growth_period) * max_alive_growth
