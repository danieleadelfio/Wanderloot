class_name ExtractionData
extends Resource
## Regole del punto di estrazione. Bilanciamento solo nei .tres in res://data/run/.

## Secondi di run prima che il punto di estrazione appaia.
@export var appear_after: float = 60.0
## Secondi da passare nella zona per estrarre.
@export var channel_time: float = 5.0
## Secondi di progresso persi per ogni secondo passato fuori dalla zona.
@export var decay_rate: float = 0.5
## Distanza minima dal player quando il punto appare.
@export var spawn_min_distance: float = 400.0
## Distanza massima dal player quando il punto appare (arene 10x, M13): non deve mai spawnare troppo lontano.
@export var spawn_max_distance: float = 1000.0
