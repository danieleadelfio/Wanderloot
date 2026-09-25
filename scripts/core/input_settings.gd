class_name InputSettings
extends RefCounted
## Preferenze di input (M12, #86): inversione dell'asse orizzontale della mira col mouse (per mancini).
## Salvata nel file impostazioni (sezione input), indipendente dal salvataggio di gioco.

const PATH: String = "user://settings.cfg"
const SECTION: String = "input"

## Cache in memoria, letta una volta all'avvio e aggiornata subito quando si cambia opzione.
static var mouse_invert_x: bool = false


static func load_and_apply(path: String = PATH) -> bool:
	mouse_invert_x = load_saved(path)
	return mouse_invert_x


static func load_saved(path: String = PATH) -> bool:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return false
	return bool(config.get_value(SECTION, "mouse_invert_x", false))


## Conserva le altre sezioni del file impostazioni (audio, lingua).
static func save(invert: bool, path: String = PATH) -> Error:
	mouse_invert_x = invert
	var config := ConfigFile.new()
	config.load(path)
	config.set_value(SECTION, "mouse_invert_x", invert)
	return config.save(path)
