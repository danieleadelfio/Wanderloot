class_name OvertimeData
extends Resource
## Overtime (M11.1, #62): se si resta in arena dopo l'apertura dell'estrazione la run diventa
## sempre piu' dura, fino a rendere l'estrazione quasi impossibile. Livello N = modificatori del livello 1 x N.

## Secondi dall'apertura dell'estrazione all'overtime x1, poi ogni quanti secondi sale di livello.
@export var start_after: float = 50.0
@export var level_every: float = 50.0
## Avvisi a questi secondi dal prossimo livello (come per gli eventi).
@export var warnings: PackedFloat32Array = [30.0, 10.0]
@export_group("Livello 1")
## Un boss ogni tanti secondi (livello N: diviso per N, non sotto min_boss_interval).
@export var boss_interval: float = 10.0
@export var min_boss_interval: float = 2.0
## Velocita' dei nemici nuovi (livello N: x speed_multiplier * N).
@export var speed_multiplier: float = 2.0
## Vita in piu' dei nemici nuovi (livello N: +hp_bonus * N).
@export var hp_bonus: float = 0.25
## I nemici nuovi compaiono gia' in rage.
@export var spawn_raged: bool = true
