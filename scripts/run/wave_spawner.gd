class_name WaveSpawner
extends Node
## Spawna nemici secondo WaveData scegliendo il tipo tra gli EnemySpawn dell'arena (un EnemyPool per tipo).
## Avviato e configurato dalla composition root.

## Tetto assoluto dei nemici vivi (prestazioni), anche in overtime.
const MAX_ALIVE: int = 320

@export var wave_data: WaveData
@export var spawn_rect: Rect2 = Rect2(-7400.0, -4400.0, 14800.0, 8800.0)
## Anello di spawn attorno al player (M13, #86: arene 10x, un rect uniforme faceva comparire i nemici
## a migliaia di px, in rage prima ancora di arrivare). min = appena fuori dallo schermo (viewport
## 1280x720, mezza diagonale ~734px), max = abbastanza vicino da arrivare in pochi secondi.
@export var spawn_min_distance: float = 900.0
@export var spawn_max_distance: float = 1500.0
## Oltre questa distanza dal player un nemico vivo despawna (silenzioso, nessun drop) e viene
## rimpiazzato dal normale ciclo di ondate con uno spawn point aggiornato sulla posizione attuale
## (M13, #86: player che scappa lontano non deve trascinarsi dietro nemici dall'altra parte dell'arena).
@export var despawn_distance: float = 2400.0

var _target: Node2D
var _elapsed: float = 0.0
var _cooldown: float = 0.0
var _spawns: Array[EnemySpawn] = []
var _pools: Array[EnemyPool] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Ondata (Pentagramma di sangue): tetto dei vivi moltiplicato e nuovi mostri gia' in rage.
var surge_multiplier: float = 1.0
var spawn_raged: bool = false
## Overtime (M11.1): nuovi mostri in rage, piu' veloci e con piu' vita. Indipendente dal Pentagramma.
var overtime_raged: bool = false
var overtime_speed: float = 1.0
var overtime_hp: float = 1.0
## Overtime (M11.4): tetto dei vivi e frequenza delle ondate moltiplicati; mai oltre MAX_ALIVE.
var overtime_alive: float = 1.0
var overtime_rate: float = 1.0
## Livello arena (M12, #86): vita e ritmo di spawn scalati dalla potenza dell'equip indossato a inizio
## run. Indipendente da overtime: si moltiplicano tra loro (ArenaLevel non cambia in run).
var level_hp: float = 1.0
var level_rate: float = 1.0
## Blocca nuove ondate senza toccare i nemici gia' vivi (Ossario, boss pre-overtime, M12, #86): i nemici
## presenti quando il blocco scatta restano e vengono uccisi normalmente, ma non ne arrivano di nuovi
## finche' il blocco non si toglie.
var spawning_blocked: bool = false


func _ready() -> void:
	set_physics_process(false)
	_rng.randomize()


## pools[i] contiene i nemici di spawns[i].
func configure(spawns: Array[EnemySpawn], pools: Array[EnemyPool]) -> void:
	_spawns = spawns
	_pools = pools


func active_count() -> int:
	var count := 0
	for pool in _pools:
		count += pool.active_count()
	return count


func _physics_process(delta: float) -> void:
	_elapsed += delta
	_cooldown -= delta
	_despawn_far_enemies()
	if _cooldown > 0.0 or _pools.is_empty() or spawning_blocked:
		return
	_cooldown = wave_data.interval_at(_elapsed) / maxf(overtime_rate * level_rate, 0.01)
	var cap := mini(roundi(wave_data.max_alive_at(_elapsed) * surge_multiplier * overtime_alive), MAX_ALIVE)
	var free_slots := cap - active_count()
	_spawn_batch(mini(wave_data.batch_at(_elapsed), free_slots))


## Mostri subito in piu' (Pentagramma di sangue), oltre al ritmo delle ondate.
func burst(count: int) -> void:
	_spawn_batch(count)


func _spawn_batch(count: int) -> void:
	for i in count:
		var index := EnemySpawn.pick_index(_spawns, _elapsed, _rng)
		if index < 0:
			return
		var spawn_position := SpawnUtils.random_point_away(spawn_rect, _target.global_position, spawn_min_distance, spawn_max_distance)
		var enemy := _pools[index].spawn(spawn_position, _target)
		if enemy == null:
			continue
		if spawn_raged or overtime_raged:
			enemy.force_rage()
		if overtime_speed != 1.0 or overtime_hp != 1.0 or level_hp != 1.0:
			enemy.boost(overtime_speed, overtime_hp * level_hp)


## Nemici troppo lontani dal player (M13, #86): tornano al pool in silenzio, senza drop ne' segnale
## enemy_died. Il prossimo _spawn_batch() li rimpiazza con uno spawn point sulla posizione attuale.
func _despawn_far_enemies() -> void:
	if _target == null:
		return
	for pool in _pools:
		for enemy in pool.active_enemies().duplicate():
			if enemy.global_position.distance_to(_target.global_position) > despawn_distance:
				pool.despawn(enemy)


func start(target: Node2D) -> void:
	_target = target
	_elapsed = 0.0
	_cooldown = 0.0
	set_physics_process(true)


func stop() -> void:
	set_physics_process(false)
