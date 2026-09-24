class_name RarityTier
extends Resource
## Una rarita' dell'equipaggiamento (M11): colore, quanti bonus, quanto sono buoni, abilita', drop, smontaggio.

## Chiave di traduzione.
@export var display_name: String = ""
@export var color: Color = Color.WHITE
## Bonus tirati dalla AffixTable.
@export var affix_count: int = 1
## Qualita' dei tiri: il valore di ogni bonus e' tra min e max dell'intervallo, a questa altezza (0..1).
@export_range(0.0, 1.0, 0.05) var roll_min: float = 0.0
@export_range(0.0, 1.0, 0.05) var roll_max: float = 0.35
## Modificatori di gameplay (abilita' della bacchetta sempre attive in run).
@export var ability_count: int = 0
## Peso tra gli oggetti trovati in run (0 = non si trova, es. Mitico).
@export var drop_weight: float = 1.0
## Moltiplicatore dei materiali restituiti dallo smontaggio.
@export var salvage_multiplier: int = 1
## Suono quando un oggetto di questa rarita' cade in run (id del banco suoni, M11.1 #61).
@export var drop_sound: StringName = &"drop_common"
## Dimensione dell'alone colorato dell'oggetto a terra (1 = come l'icona).
@export var glow_scale: float = 1.0
