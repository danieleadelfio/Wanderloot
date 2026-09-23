class_name RecipeData
extends Resource
## Ricetta fissa del fabbro: materiali -> pezzo di equipaggiamento (GDD §6).

@export var result: EquipmentData
@export var costs: Array[MaterialCost] = []


## Costi come id materiale -> quantita' (righe duplicate sommate, nulle/non positive ignorate).
func cost_dictionary() -> Dictionary[StringName, int]:
	var amounts: Dictionary[StringName, int] = {}
	for cost in costs:
		if cost != null and cost.material != null and cost.amount > 0:
			amounts[cost.material.id] = amounts.get(cost.material.id, 0) + cost.amount
	return amounts
