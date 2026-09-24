class_name BossData
extends Resource
## Dati di un boss: statistiche, drop, moveset e fase 2. La scena del boss usa lo script condiviso Boss.

@export var id: StringName = &""
@export var display_name: String = ""
@export var max_hp: int = 300
@export var move_speed: float = 90.0
@export var contact_damage: int = 2
@export var contact_knockback: float = 520.0
@export var exp_reward: int = 30
## Drop alla morte (chance 1.0 = garantito).
@export var drops: Array[DropEntry] = []

@export_group("Attacchi")
@export var attacks: Array[BossAttack] = []
## Secondi prima del primo attacco dopo la comparsa.
@export var first_attack_delay: float = 2.0
## Secondi di inseguimento tra un attacco e l'altro.
@export var chase_time: float = 1.6

@export_group("Fase 2")
## Sotto questa frazione di HP il boss passa alla fase 2 (sblocca gli attacchi con min_phase 2).
@export_range(0.0, 1.0, 0.05) var phase_two_threshold: float = 0.5
@export var phase_two_speed_multiplier: float = 1.25
## Moltiplica inseguimento e recupero in fase 2 (< 1 = attacchi piu' ravvicinati).
@export var phase_two_tempo_multiplier: float = 0.7
@export var phase_two_tint: Color = Color(1, 0.7, 0.7)


func phase_for(hp_ratio: float) -> int:
	return 2 if hp_ratio <= phase_two_threshold else 1
