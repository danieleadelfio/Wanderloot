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

## Consumabili che i nemici possono lasciare (M10.1); vuoto = nessuno.
@export var consumables: ConsumableTable
## Oggetti di equipaggiamento trovabili in run (M11, #58).
@export var item_drops: ItemDropTable
## Overtime dopo l'apertura dell'estrazione (M11.1, #62). null = nessun overtime.
@export var overtime: OvertimeData

@export_group("Boss")
## Scena del boss (script Boss); vuota = nessun boss in questa arena.
@export var boss_scene: PackedScene
## Boss possibili (M11.3): se non vuoto, ogni boss che compare e' scelto a caso da qui (boss_scene ignorato).
@export var boss_scenes: Array[PackedScene] = []
## Secondi dopo l'apertura della zona di estrazione in cui compare il boss.
@export var boss_delay: float = 20.0
@export var boss_spawn_min_distance: float = 380.0
## Boss che compaiono insieme (il Pentagramma di sangue ne aggiunge); sempre in punti diversi.
@export var boss_count: int = 1
## Distanza minima tra due boss che compaiono.
@export var boss_min_separation: float = 350.0

func has_boss() -> bool:
	return boss_scene != null or not boss_scenes.is_empty()


func pick_boss_scene(rng: RandomNumberGenerator) -> PackedScene:
	if boss_scenes.is_empty():
		return boss_scene
	return boss_scenes[rng.randi_range(0, boss_scenes.size() - 1)]


@export_group("Eventi")
## Eventi possibili (uno a caso a ogni tempo di event_times).
@export var events: Array[RunEventData] = []
## Secondi di run in cui parte un evento.
@export var event_times: PackedFloat32Array = []
## Evento in piu' questi secondi dopo aver sconfitto tutti i boss (una volta per run, M11.2). Negativo = nessuno.
@export var boss_event_delay: float = 10.0

@export_group("Sblocco")
## Arena in cui servono estrazioni riuscite per sbloccare questa (vuoto = sempre disponibile).
@export var unlock_arena: StringName = &""
@export var unlock_extractions: int = 0


func is_unlocked(extractions: Dictionary) -> bool:
	return unlock_arena == &"" or int(extractions.get(unlock_arena, 0)) >= unlock_extractions
