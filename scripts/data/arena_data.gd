class_name ArenaData
extends Resource
## Un'arena giocabile: aspetto, atmosfera, ondate, nemici e condizione di sblocco (M7).
## Aggiungere un'arena = un nuovo .tres in data/arenas/ + i suoi asset, senza codice nuovo.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Aspetto")
@export var floor_texture: Texture2D
@export var wall_texture: Texture2D
@export var ambient_color: Color = Color(0.4, 0.38, 0.5)
@export var player_light_color: Color = Color(1, 0.86, 0.66)
@export var player_light_energy: float = 1.05
@export var player_light_scale: float = 3.6
@export var torches_per_wall: int = 5
@export var torch_color: Color = Color(1, 0.62, 0.32)
@export var music: AudioStream
## Decorazioni sparse sul pavimento (senza collisioni), scelte a caso da questa lista.
@export var decorations: Array[Texture2D] = []
@export var decoration_count: int = 0
@export var candle_count: int = 0
@export var candle_color: Color = Color(1, 0.3, 0.25)
## Nebbia: alpha 0 = nessuna.
@export var fog_color: Color = Color(0, 0, 0, 0)
@export var fog_count: int = 0

@export_group("Gioco")
@export var wave_data: WaveData
@export var extraction_data: ExtractionData
@export var enemies: Array[EnemySpawn] = []

@export_group("Boss")
## Scena del boss (script Boss); vuota = nessun boss in questa arena.
@export var boss_scene: PackedScene
## Secondi dopo l'apertura della zona di estrazione in cui compare il boss.
@export var boss_delay: float = 20.0
@export var boss_spawn_min_distance: float = 380.0

@export_group("Eventi")
## Eventi possibili (uno a caso a ogni tempo di event_times).
@export var events: Array[RunEventData] = []
## Secondi di run in cui parte un evento.
@export var event_times: PackedFloat32Array = []

@export_group("Sblocco")
## Arena in cui servono estrazioni riuscite per sbloccare questa (vuoto = sempre disponibile).
@export var unlock_arena: StringName = &""
@export var unlock_extractions: int = 0


func is_unlocked(extractions: Dictionary) -> bool:
	return unlock_arena == &"" or int(extractions.get(unlock_arena, 0)) >= unlock_extractions
