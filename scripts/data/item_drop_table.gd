class_name ItemDropTable
extends Resource
## Oggetti di equipaggiamento che un'arena puo' far cadere in run (loot a rischio, GDD §6.3).
## La rarita' si tira con RarityTable.pick_drop() tra min e max; il Mitico non si trova mai.

@export var items: Array[EquipmentData] = []
## Probabilita' che un nemico ucciso lasci un oggetto (moltiplicata dal bonus drop del player).
@export_range(0.0, 1.0, 0.0001) var drop_chance: float = 0.004
## Rarita' massima degli oggetti trovati (indice in rarity_table: 4 = Leggendario).
@export var max_tier: int = 4
@export_group("Boss")
## Oggetti garantiti per ogni boss sconfitto e rarita' minima (2 = Raro).
@export var boss_drops: int = 1
@export var boss_min_tier: int = 2


## Oggetto base scelto a caso (null se la lista e' vuota).
func pick(rng: RandomNumberGenerator) -> EquipmentData:
	if items.is_empty():
		return null
	return items[rng.randi_range(0, items.size() - 1)]


## Tiro per un'uccisione: un oggetto base o null.
func roll(rng: RandomNumberGenerator, chance_multiplier: float = 1.0) -> EquipmentData:
	if rng.randf() >= drop_chance * chance_multiplier:
		return null
	return pick(rng)


## Rarita' di un oggetto trovato (boss: almeno boss_min_tier).
func roll_tier(rarities: RarityTable, rng: RandomNumberGenerator, from_boss: bool = false) -> int:
	var low := boss_min_tier if from_boss else 0
	return rarities.pick_drop(rng, mini(low, max_tier), max_tier)
