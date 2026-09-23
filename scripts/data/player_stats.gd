class_name PlayerStats
extends Resource
## Statistiche base del player. Mai modificate a runtime: upgrade ed equip lavorano su copie di run (Player.begin_run).

@export var max_hp: int = 5
@export var move_speed: float = 220.0
@export var invulnerability_time: float = 0.8
## Raggio (px) entro cui exp e materiali a terra vengono attratti verso il player.
@export var pickup_radius: float = 90.0
## Moltiplicatore dell'exp raccolta (upgrade "Saggezza").
@export var exp_multiplier: float = 1.0
## Moltiplicatore della probabilità di drop dei materiali (upgrade "Fortuna").
@export var drop_chance_multiplier: float = 1.0
