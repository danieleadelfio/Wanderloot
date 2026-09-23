class_name SoundBank
extends Resource
## Catalogo degli effetti sonori per id. Aggiungere/sostituire suoni = modificare il .tres, non il codice.

@export var entries: Array[SoundEntry] = []


func find(id: StringName) -> SoundEntry:
	for entry in entries:
		if entry != null and entry.id == id:
			return entry
	return null
