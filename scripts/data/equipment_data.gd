class_name EquipmentData
extends Resource
## Pezzo di equipaggiamento permanente. Il bilanciamento si fa solo nei .tres in res://data/equipment/.

## Tipo di oggetto (M11). ACCESSORY = Amuleto. Nuove voci solo in coda (valore salvato nei .tres).
enum Slot { WEAPON, ACCESSORY, HEAD, GLOVES, ARMOR, PANTS, BOOTS, RING }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var slot: Slot = Slot.WEAPON
@export var icon: Texture2D
## Applicati alle copie di run di PlayerStats/WeaponData all'inizio di ogni run.
@export var modifiers: Array[StatModifier] = []
