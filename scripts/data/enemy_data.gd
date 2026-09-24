class_name EnemyData
extends Resource
## Parametri di un tipo di nemico. Il bilanciamento si fa solo nei .tres in res://data/enemies/.

@export var display_name: String = ""
@export var max_hp: int = 3
@export var move_speed: float = 100.0
@export var contact_damage: int = 1
@export var exp_reward: int = 1
## Spinta sul player al contatto (px/s).
@export var contact_knockback: float = 380.0
## 0 = spinto del tutto, 1 = immobile ai colpi.
@export_range(0.0, 1.0, 0.05) var knockback_resistance: float = 0.0
## Freeze locale quando colpito (hitstop del solo nemico), in secondi.
@export var hit_freeze: float = 0.05

@export_group("Rage")
## Secondi in vita dopo i quali il nemico va in rage. 0 = mai.
@export var rage_after: float = 5.0
@export var rage_speed_multiplier: float = 1.5
## Danno da contatto aggiunto in rage.
@export var rage_damage_bonus: int = 1
## Durata della dissolvenza verso lo sprite rosso.
@export var rage_fade_time: float = 0.35
## Drop table: ogni riga viene tirata indipendentemente alla morte.
@export var drops: Array[DropEntry] = []
