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
## Mana consumato per ogni colpo dello sparo base (0 = nessun costo, M12 #86): costa una volta per
## attivazione (un "while _cooldown <= 0" di Weapon.try_fire), non per proiettile del Ventaglio.
@export var mana_cost: float = 0.0

@export_group("Veleno")
## Secondi di veleno sul bersaglio colpito (0 = nessuno), ogni quanto e quanto danno (M11.3).
@export var poison_duration: float = 0.0
@export var poison_interval: float = 1.5
@export var poison_damage: int = 1

@export_group("Buco nero")
## Dopo questi pixel il proiettile si ingrandisce, rallenta e attira il player (0 = mai; M11.3).
@export var grow_after: float = 0.0
@export var grow_scale: float = 2.5
@export var grown_speed_multiplier: float = 0.35
## Attrazione verso il proiettile cresciuto: raggio (px) e velocita' massima impressa al player (px/s).
@export var pull_radius: float = 170.0
@export var pull_strength: float = 120.0

@export_group("Aspetto")
## Texture del proiettile; vuota = quella della scena del proiettile (M8, es. proiettili del boss).
@export var projectile_texture: Texture2D
## Scala dello sprite del proiettile; 0 = quella della scena.
@export var projectile_scale: float = 0.0
## Colore dei proiettili (abilita' della bacchetta, M10). Bianco = invariato.
@export var projectile_tint: Color = Color.WHITE
