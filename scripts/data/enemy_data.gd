class_name EnemyData
extends Resource
## Parametri di un tipo di nemico. Il bilanciamento si fa solo nei .tres in res://data/enemies/.

@export var display_name: String = ""
@export var max_hp: int = 3
@export var move_speed: float = 100.0
@export var contact_damage: int = 1
@export var exp_reward: int = 1
