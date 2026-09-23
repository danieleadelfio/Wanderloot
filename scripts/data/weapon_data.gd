class_name WeaponData
extends Resource
## Parametri di un'arma ranged. Il bilanciamento si fa solo nei .tres in res://data/weapons/.

@export var display_name: String = ""
@export var damage: int = 1
@export_range(0.1, 30.0, 0.1, "suffix:shots/s") var fire_rate: float = 4.0
@export var projectile_speed: float = 600.0
@export var projectile_lifetime: float = 1.0
## Spinta sul nemico colpito (px/s).
@export var knockback: float = 320.0
