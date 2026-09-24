class_name ConsumableData
extends Resource
## Consumabile a terra (M10.1): effetto immediato o a tempo alla raccolta. Non e' loot: non va nel baule.
## Nuovi tipi solo in coda all'enum (valore salvato nei .tres).

enum Kind { MAGNET, HEAL, FRENZY }

@export var id: StringName = &""
## Chiavi di traduzione.
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var kind: Kind = Kind.MAGNET
## Secondi dell'effetto (MAGNET, FRENZY).
@export var duration: float = 4.0
## HP curati (HEAL) o moltiplicatore della cadenza (FRENZY).
@export var amount: float = 1.0
## Peso relativo nella tabella dei drop.
@export var weight: float = 1.0
