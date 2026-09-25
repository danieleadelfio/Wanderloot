class_name RunEventData
extends Resource
## Evento a tempo della run (M10): titolo e sottotitolo a schermo, durata, regole, ricompensa.
## Nuovi tipi solo in coda all'enum (valore salvato nei .tres).

enum Kind { LIGHTNING_STORM, BLOOD_PENTAGRAM, SHADOW_STEP, SKELETONS_CLOSET }

@export var id: StringName = &""
## Chiavi di traduzione: titolo grande e obiettivo in poche parole.
@export var title: String = ""
@export var subtitle: String = ""
@export var kind: Kind = Kind.LIGHTNING_STORM
## Durata (Tempesta) o secondi da resistere nel cerchio (Pentagramma).
@export var duration: float = 10.0
## Abilita' proposte a evento superato (0 = nessuna).
@export var reward_choices: int = 3
## Boss in piu' in questa run a evento superato.
@export var bonus_bosses: int = 0

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


@export_group("Pentagramma")
## Secondi in cui il pentagramma aspetta che il player entri; poi l'evento fallisce.
@export var activation_timeout: float = 20.0
@export var circle_radius: float = 110.0
## Candele attorno al cerchio: se ne spegne una ogni duration / candle_count secondi.
@export var candle_count: int = 15
## Mostri in piu' mentre si e' nel cerchio (0.3 = +30% subito e tetto dei vivi +30%).
@export var monster_bonus: float = 0.3
## I mostri che compaiono durante l'evento sono gia' in rage.
@export var spawn_raged: bool = true
## Distanza minima dal player del punto in cui compare il pentagramma.
@export var min_player_distance: float = 320.0

@export_group("Passo d'ombra")
## Niente sparo: il tasto di sparo (o Spazio / tasto destro) scatta. Cariche e secondi per ricaricarne una.
@export var dash_charges: int = 6
@export var dash_recharge: float = 2.0
## Velocita' e durata dello scatto: il player e' invulnerabile per tutta la durata.
@export var dash_speed: float = 850.0
@export var dash_duration: float = 0.2

@export_group("Scheletri nell'armadio")
## Dati del nemico spawnato (velocita'/vita/danno da contatto vengono da qui). Non attirato dal
## player: target fisso sul centro del cerchio (M12, #86).
@export var skeleton_enemy: EnemyData
## Quanti scheletri compaiono sul cerchio.
@export var skeleton_count: int = 10
## Raggio del cerchio attorno al player su cui compaiono (M12, #86: "ampio cerchio attorno al player").
@export var skeleton_spawn_radius: float = 260.0
## Pezzi proposti dall'armadio a evento superato (mai estratti prima; se ne restano meno, si propone
## quel che c'e'). Ruolo equivalente a reward_choices, ma per equipaggiamento invece di abilita'.
@export var closet_choices: int = 3
