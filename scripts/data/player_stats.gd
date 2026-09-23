class_name PlayerStats
extends Resource
## Statistiche base del player. Mai modificate a runtime: upgrade ed equip lavorano su copie di run (Player.begin_run).

@export var max_hp: int = 5
@export var move_speed: float = 220.0
@export var invulnerability_time: float = 0.8
