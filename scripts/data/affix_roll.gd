class_name AffixRoll
extends Resource
## Un bonus possibile sull'equipaggiamento: statistica e intervallo del valore (M11).

@export var stat: UpgradeData.Stat = UpgradeData.Stat.DAMAGE
## Valore minimo e massimo (per i moltiplicatori es. 1.05 .. 1.25 = +5% .. +25%).
@export var min_value: float = 1.0
@export var max_value: float = 1.0
@export var is_multiplier: bool = false
## Tipi di oggetto che possono averlo (vuoto = tutti).
@export var slots: Array[EquipmentData.Slot] = []
@export var weight: float = 1.0


func allows(slot: EquipmentData.Slot) -> bool:
	return slots.is_empty() or slots.has(slot)
