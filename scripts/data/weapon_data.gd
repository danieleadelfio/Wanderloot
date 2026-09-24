class_name WeaponData
extends Resource
## Parametri di un'arma ranged. Il bilanciamento si fa solo nei .tres in res://data/weapons/.

@export var display_name: String = ""
@export var damage: int = 1
## Nessun tetto: gli upgrade possono spingerla oltre i tick di fisica (piu' colpi per tick).
@export_range(0.1, 30.0, 0.1, "or_greater", "suffix:shots/s") var fire_rate: float = 4.0
@export var projectile_speed: float = 600.0
@export var projectile_lifetime: float = 1.0
## Spinta sul nemico colpito (px/s).
@export var knockback: float = 320.0
## Proiettili per colpo, a ventaglio (upgrade "Ventaglio"). Nessun tetto.
@export var projectile_count: int = 1
## Gradi tra un proiettile e l'altro del ventaglio (compressi se il ventaglio supera 360°).
@export var spread_degrees: float = 10.0
## Nemici attraversati prima di sparire (upgrade "Perforazione").
@export var pierce: int = 0

@export_group("Aspetto")
## Texture del proiettile; vuota = quella della scena del proiettile (M8, es. proiettili del boss).
@export var projectile_texture: Texture2D
## Scala dello sprite del proiettile; 0 = quella della scena.
@export var projectile_scale: float = 0.0
