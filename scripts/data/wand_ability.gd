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
## Cooldown per livello (COOLDOWN, M12 #86 #18): indice 0 = Lv1, ... Vuoto = usa sempre `cooldown`.
## Oltre l'ultimo indice si usa l'ultimo valore. Es. Barriera arcana: piatto fino a Lv4, poi scende.
@export var cooldown_by_level: Array[float] = []
## Colpi sparati per attivarsi (SHOTS).
@export var every_shots: int = 8
## Pixel percorsi per attivarsi (DISTANCE).
@export var every_distance: float = 350.0
@export var effect: AbilityEffect
## Colore dei proiettili finche' l'abilita' e' nella bacchetta (si mescola con quello delle altre).
@export var projectile_tint: Color = Color.WHITE


## Testo del criterio di attivazione (tradotto), per la scelta e l'HUD.
## Cooldown effettivo al livello dato: `cooldown_by_level[level - 1]` (clampato), o `cooldown` se vuoto.
func cooldown_for_level(level: int) -> float:
	if cooldown_by_level.is_empty():
		return cooldown
	return cooldown_by_level[clampi(level, 1, cooldown_by_level.size()) - 1]


func trigger_text() -> String:
	match trigger:
		Trigger.SHOTS:
			return TranslationServer.translate("ABILITY_TRIGGER_SHOTS") % every_shots
		Trigger.DISTANCE:
			return TranslationServer.translate("ABILITY_TRIGGER_DISTANCE") % roundi(every_distance)
		Trigger.PERMANENT:
			return TranslationServer.translate("ABILITY_TRIGGER_PERMANENT")
	return TranslationServer.translate("ABILITY_TRIGGER_COOLDOWN") % cooldown
