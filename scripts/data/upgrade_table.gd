class_name UpgradeTable
extends Resource
## Insieme degli upgrade estraibili al level-up, con estrazione pesata senza ripetizioni.

@export var upgrades: Array[UpgradeData] = []


func pick(count: int, rng: RandomNumberGenerator) -> Array[UpgradeData]:
	# weight <= 0 = disattivato (M12, #86: Gittata e Persistenza fuori dal pool), mai estraibile.
	var candidates: Array[UpgradeData] = upgrades.filter(func(u: UpgradeData) -> bool: return u.weight > 0.0)
	var result: Array[UpgradeData] = []
	while result.size() < count and not candidates.is_empty():
		var total := 0.0
		for upgrade in candidates:
			total += maxf(upgrade.weight, 0.0)
		var roll := rng.randf() * total
		var index := candidates.size() - 1
		for i in candidates.size():
			roll -= maxf(candidates[i].weight, 0.0)
			if roll <= 0.0:
				index = i
				break
		result.append(candidates[index])
		candidates.remove_at(index)
	return result
