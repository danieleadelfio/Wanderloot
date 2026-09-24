class_name RunEventData
extends Resource
## Evento a tempo della run (M10): titolo e sottotitolo a schermo, durata, regole, ricompensa.
## Nuovi tipi solo in coda all'enum (valore salvato nei .tres).

enum Kind { LIGHTNING_STORM }

@export var id: StringName = &""
## Chiavi di traduzione: titolo grande e obiettivo in poche parole.
@export var title: String = ""
@export var subtitle: String = ""
@export var kind: Kind = Kind.LIGHTNING_STORM
@export var duration: float = 10.0
## Abilita' proposte a evento superato.
@export var reward_choices: int = 3

@export_group("Fulmini")
## Secondi tra un fulmine e l'altro.
@export var strike_interval: float = 0.55
@export var strike_radius: float = 70.0
## Preavviso: il cerchio azzurro compare cosi' tanto prima del colpo.
@export var strike_telegraph: float = 0.8
@export var strike_damage: int = 1
## Distanza massima dal player dei fulmini casuali.
@export var strike_spread: float = 260.0
## Probabilita' che un fulmine miri esattamente alla posizione del player.
@export_range(0.0, 1.0, 0.05) var aimed_chance: float = 0.35
