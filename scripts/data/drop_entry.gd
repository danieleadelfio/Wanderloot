class_name DropEntry
extends Resource
## Riga di drop table: probabilita' e quantita' di un materiale alla morte di un nemico.

@export var material: MaterialData
@export_range(0.0, 1.0, 0.01) var chance: float = 0.0
@export var min_amount: int = 1
@export var max_amount: int = 1


## Quantita' droppata (0 se il tiro fallisce).
## chance_multiplier: upgrade "Fortuna" (oltre 1.0 di probabilità il drop è sicuro).
func roll(rng: RandomNumberGenerator, chance_multiplier: float = 1.0) -> int:
	if material == null or rng.randf() >= chance * chance_multiplier:
		return 0
	return rng.randi_range(mini(min_amount, max_amount), maxi(min_amount, max_amount))
