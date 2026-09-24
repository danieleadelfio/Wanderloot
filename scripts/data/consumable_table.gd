class_name ConsumableTable
extends Resource
## Consumabili che un'arena puo' far cadere, con la probabilita' per uccisione.

@export var entries: Array[ConsumableData] = []
## Probabilita' che un nemico ucciso lasci un consumabile (moltiplicata dal bonus drop del player).
@export_range(0.0, 1.0, 0.001) var drop_chance: float = 0.012


## Consumabile scelto per peso (null se la tabella e' vuota).
func pick(rng: RandomNumberGenerator) -> ConsumableData:
	var total := 0.0
	for entry in entries:
		total += maxf(entry.weight, 0.0)
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	for entry in entries:
		roll -= maxf(entry.weight, 0.0)
		if roll <= 0.0:
			return entry
	return entries.back()


## Tiro per un'uccisione: un consumabile o null.
func roll(rng: RandomNumberGenerator, chance_multiplier: float = 1.0) -> ConsumableData:
	if rng.randf() >= drop_chance * chance_multiplier:
		return null
	return pick(rng)
