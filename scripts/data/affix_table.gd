class_name AffixTable
extends Resource
## Tutti i bonus che gli oggetti possono tirare. Un solo .tres: data/equipment/affix_table.tres.

@export var rolls: Array[AffixRoll] = []


## Bonus della tabella per statistica e tipo (null se assente).
func find(stat: int, is_multiplier: bool) -> AffixRoll:
	for roll in rolls:
		if int(roll.stat) == stat and roll.is_multiplier == is_multiplier:
			return roll
	return null
