class_name LootTransfer
extends RefCounted
## Regola cardine dell'extraction layer (GDD §4): il loot di run passa al permanente SOLO con un'estrazione
## riuscita; con la morte va perso. Logica pura, senza autoload: il deposito e' iniettato come Callable.


## Risolve il loot di fine run. deposit riceve Dictionary[StringName, int] ed e' chiamato solo se estratto
## e il loot non e' vuoto. L'inventario di run viene sempre svuotato. Ritorna la quantita' trasferita o persa.
static func resolve(extracted: bool, run_loot: LootRunInventory, deposit: Callable) -> int:
	var amount := run_loot.total()
	if extracted and amount > 0:
		deposit.call(run_loot.to_dictionary())
	run_loot.clear()
	return amount
