class_name AbilityCatalog
extends Resource
## Abilita' che gli eventi possono offrire.

@export var abilities: Array[WandAbility] = []


## Fino a count abilita' diverse, escluse quelle gia' nella bacchetta.
func pick(count: int, owned: Array[StringName], rng: RandomNumberGenerator) -> Array[WandAbility]:
	var pool: Array[WandAbility] = abilities.filter(func(a: WandAbility) -> bool: return not owned.has(a.id))
	var result: Array[WandAbility] = []
	while result.size() < count and not pool.is_empty():
		result.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return result
