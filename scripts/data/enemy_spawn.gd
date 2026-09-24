class_name EnemySpawn
extends Resource
## Un tipo di nemico nelle ondate di un'arena: scena, peso relativo, da quando puo' comparire.

@export var scene: PackedScene
@export var weight: float = 1.0
## Secondi di run prima che questo nemico possa comparire.
@export var min_time: float = 0.0


## Indice estratto (pesato) tra gli spawn gia' disponibili al tempo elapsed; -1 se nessuno.
static func pick_index(spawns: Array[EnemySpawn], elapsed: float, rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for spawn in spawns:
		if spawn.min_time <= elapsed:
			total += maxf(spawn.weight, 0.0)
	if total <= 0.0:
		return -1
	var roll := rng.randf() * total
	for i in spawns.size():
		if spawns[i].min_time > elapsed:
			continue
		roll -= maxf(spawns[i].weight, 0.0)
		if roll <= 0.0:
			return i
	return spawns.size() - 1
