class_name ArenaCatalog
extends Resource
## Elenco delle arene, nell'ordine in cui compaiono al portale. La prima e' quella iniziale.

@export var arenas: Array[ArenaData] = []


func find(id: StringName) -> ArenaData:
	for arena in arenas:
		if arena.id == id:
			return arena
	return null


func first() -> ArenaData:
	return arenas[0] if not arenas.is_empty() else null
