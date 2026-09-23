class_name MaterialData
extends Resource
## Materiale da crafting droppato dai nemici. L'id e' la chiave usata negli inventari e nella persistenza.

enum Rarity { COMMON, RARE }

@export var id: StringName = &""
@export var display_name: String = ""
@export var rarity: Rarity = Rarity.COMMON
## Colore placeholder finche' non ci sono icone.
@export var color: Color = Color.WHITE
@export var icon: Texture2D
