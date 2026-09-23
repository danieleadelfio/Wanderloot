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


func interval_at(elapsed: float) -> float:
	return maxf(min_interval, start_interval - interval_decay * elapsed)


func batch_at(elapsed: float) -> int:
	return start_batch + int(elapsed / batch_growth_period)
