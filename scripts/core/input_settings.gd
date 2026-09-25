class_name InputSettings
extends RefCounted
## Preferenze di input (M12, #86): opzione per mancini. Scambia i tasti del mouse tra "shoot" (sinistro
## di base) e "dash" (destro di base), cosi' chi impugna il mouse con la mano sinistra ha lo sparo sotto
## l'indice. Tastiera e pad non sono toccati. Salvata nel file impostazioni (sezione input), indipendente
## dal salvataggio di gioco.

const PATH: String = "user://settings.cfg"
const SECTION: String = "input"
const SHOOT_ACTION: StringName = &"shoot"
const DASH_ACTION: StringName = &"dash"

## Cache in memoria, letta una volta all'avvio e aggiornata subito quando si cambia opzione.
static var left_handed: bool = false


static func load_and_apply(path: String = PATH) -> bool:
	left_handed = load_saved(path)
	_apply_button_swap()
	return left_handed


static func load_saved(path: String = PATH) -> bool:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return false
	return bool(config.get_value(SECTION, "left_handed", false))


## Conserva le altre sezioni del file impostazioni (audio, lingua). Applica subito lo scambio tasti.
static func save(enabled: bool, path: String = PATH) -> Error:
	left_handed = enabled
	_apply_button_swap()
	var config := ConfigFile.new()
	config.load(path)
	config.set_value(SECTION, "left_handed", enabled)
	return config.save(path)


## Ricalcolata sempre dal flag (mai dallo stato precedente della InputMap): idempotente, richiamabile
## piu' volte senza rischio di ri-scambiare per sbaglio.
static func _apply_button_swap() -> void:
	_set_mouse_button(SHOOT_ACTION, MOUSE_BUTTON_RIGHT if left_handed else MOUSE_BUTTON_LEFT)
	_set_mouse_button(DASH_ACTION, MOUSE_BUTTON_LEFT if left_handed else MOUSE_BUTTON_RIGHT)


## Sostituisce il solo evento di tasto del mouse dell'azione con button_index; tastiera/pad invariati.
static func _set_mouse_button(action: StringName, button_index: MouseButton) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton:
			InputMap.action_erase_event(action, event)
	var new_event := InputEventMouseButton.new()
	new_event.button_index = button_index
	InputMap.action_add_event(action, new_event)
