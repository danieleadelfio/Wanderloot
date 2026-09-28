class_name LootTransfer
extends RefCounted
## Regola cardine dell'extraction layer (GDD §4): il loot di run passa al permanente SOLO con un'estrazione
## riuscita; con la morte va perso. Logica pura, senza autoload: il deposito e' iniettato come Callable.


## Risolve il loot di fine run. deposit riceve Dictionary[StringName, int] (materiali), deposit_items
## Array[ItemInstance] (oggetti trovati), deposit_bags int (Bag of Resources, M13 #86): chiamati solo se
## estratto e se la rispettiva parte non e' vuota.
## L'inventario di run viene sempre svuotato. Ritorna la quantita' trasferita o persa (materiali + oggetti).
static func resolve(extracted: bool, run_loot: LootRunInventory, deposit: Callable, deposit_items: Callable = Callable(), deposit_bags: Callable = Callable()) -> int:
	var amount := run_loot.total()
	if extracted:
		var materials := run_loot.to_dictionary()
		if not materials.is_empty():
			deposit.call(materials)
		var items := run_loot.items()
		if not items.is_empty() and deposit_items.is_valid():
			deposit_items.call(items)
		if run_loot.bags() > 0 and deposit_bags.is_valid():
			deposit_bags.call(run_loot.bags())
	run_loot.clear()
	return amount
