class_name Ascension
extends RefCounted
## Ascensione (M12, #86, #16): alza il cap sbloccato di un'abilita' oltre il default (Lv1, #20),
## fino al tetto assoluto WandAbility.MAX_LEVEL. Logica pura: qui solo la tabella dei costi.

## Costo per salire al livello indicato (indice = target_level - 2; livello 1 e' il default, gratuito).
const _COSTS: Array[Dictionary] = [
	{&"bone_shard": 10},
	{&"bone_shard": 20},
	{&"bone_shard": 30, &"slime_gel": 10},
	{&"bone_shard": 40, &"slime_gel": 20},
	{&"shadow_essence": 10, &"slime_gel": 30},
	{&"shadow_essence": 20, &"slime_core": 10},
	{&"shadow_essence": 30, &"slime_core": 20},
]


## Costo per salire da (target_level - 1) a target_level; vuoto se target_level fuori range (<=1 o > MAX_LEVEL).
static func cost_for(target_level: int) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	var index := target_level - 2
	if index < 0 or index >= _COSTS.size():
		return result
	for id in _COSTS[index]:
		result[id] = _COSTS[index][id]
	return result
