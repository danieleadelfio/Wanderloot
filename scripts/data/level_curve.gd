class_name LevelCurve
extends Resource
## Exp richiesta per passare dal livello N al N+1: base_exp * growth^(N-1), arrotondata.

@export var base_exp: int = 500
@export var growth: float = 1.35


func exp_to_next(level: int) -> int:
	return maxi(1, roundi(base_exp * pow(growth, level - 1)))
