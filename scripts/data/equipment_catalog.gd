class_name EquipmentCatalog
extends Resource
## Elenco di tutti i pezzi di equipaggiamento esistenti: risolve gli id salvati su disco in Resource.

@export var items: Array[EquipmentData] = []


func find(id: StringName) -> EquipmentData:
	for item in items:
		if item.id == id:
			return item
	return null
