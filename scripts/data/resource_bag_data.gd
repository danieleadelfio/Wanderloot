class_name ResourceBagData
extends Resource
## Bag of Resources (M13, #86): livelli di un'abilita' oltre il cap sbloccato diventano sacchetti
## (uno per livello in eccesso). Non e' equipaggiamento: in run e' loot a rischio, dopo l'estrazione
## sta nell'inventario della piazza e si apre con un clic. Il contenuto si tira all'apertura:
## amount_per_bag di un materiale a caso tra `materials`.

@export var id: StringName = &"resource_bag"
@export var display_name: String = "BAG_NAME"
@export var description: String = "BAG_DESC"
@export var icon: Texture2D
@export var materials: Array[MaterialData] = []
@export var amount_per_bag: int = 10


## Contenuto di un sacchetto (id materiale -> quantita'); vuoto se non ci sono materiali.
func roll(rng: RandomNumberGenerator) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	if materials.is_empty() or amount_per_bag <= 0:
		return result
	var material := materials[rng.randi_range(0, materials.size() - 1)]
	result[material.id] = amount_per_bag
	return result
