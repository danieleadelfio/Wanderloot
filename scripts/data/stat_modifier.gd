class_name StatModifier
extends Resource
## Modificatore di una statistica del player/arma. Usa lo stesso enum degli upgrade di run.

@export var stat: UpgradeData.Stat = UpgradeData.Stat.DAMAGE
## Valore da sommare, o moltiplicatore se is_multiplier.
@export var amount: float = 0.0
@export var is_multiplier: bool = false
