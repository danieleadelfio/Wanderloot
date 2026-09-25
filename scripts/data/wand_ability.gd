class_name WandAbility
extends Resource
## Abilita' della bacchetta per la run (M10): come si attiva, cosa fa (effect) e come cambia i proiettili.
## Nuovi criteri di attivazione solo in coda all'enum (valore salvato nei .tres).

enum Trigger { COOLDOWN, SHOTS, DISTANCE, PERMANENT }

## Livello massimo assoluto (M12, #86, #19): vale anche dopo aver sbloccato il cap con l'Ascensione.
const MAX_LEVEL: int = 8

@export var id: StringName = &""
## Chiavi di traduzione.
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var trigger: Trigger = Trigger.COOLDOWN
## Secondi tra un'attivazione e l'altra (COOLDOWN).
@export var cooldown: float = 10.0
## Colpi sparati per attivarsi (SHOTS).
@export var every_shots: int = 8
## Pixel percorsi per attivarsi (DISTANCE).
@export var every_distance: float = 350.0
@export var effect: AbilityEffect
## Colore dei proiettili finche' l'abilita' e' nella bacchetta (si mescola con quello delle altre).
@export var projectile_tint: Color = Color.WHITE


## Testo del criterio di attivazione (tradotto), per la scelta e l'HUD.
func trigger_text() -> String:
	match trigger:
		Trigger.SHOTS:
			return TranslationServer.translate("ABILITY_TRIGGER_SHOTS") % every_shots
		Trigger.DISTANCE:
			return TranslationServer.translate("ABILITY_TRIGGER_DISTANCE") % roundi(every_distance)
		Trigger.PERMANENT:
			return TranslationServer.translate("ABILITY_TRIGGER_PERMANENT")
	return TranslationServer.translate("ABILITY_TRIGGER_COOLDOWN") % cooldown
