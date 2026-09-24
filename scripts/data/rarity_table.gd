class_name RarityTable
extends Resource
## Le rarita' in ordine (0 = Comune ... 5 = Mitico). Un solo .tres: data/equipment/rarity_table.tres.

@export var tiers: Array[RarityTier] = []


func tier(index: int) -> RarityTier:
	return tiers[clampi(index, 0, tiers.size() - 1)]


func highest() -> int:
	return tiers.size() - 1


## Rarita' di un oggetto trovato, per peso, tra min_index e max_index compresi.
func pick_drop(rng: RandomNumberGenerator, min_index: int = 0, max_index: int = 99) -> int:
	var total := 0.0
	for i in range(min_index, mini(max_index, highest()) + 1):
		total += maxf(tiers[i].drop_weight, 0.0)
	if total <= 0.0:
		return min_index
	var roll := rng.randf() * total
	for i in range(min_index, mini(max_index, highest()) + 1):
		roll -= maxf(tiers[i].drop_weight, 0.0)
		if roll <= 0.0:
			return i
	return mini(max_index, highest())
