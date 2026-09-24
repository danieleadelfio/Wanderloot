class_name AudioSettings
extends RefCounted
## Volumi di Musica ed Effetti (0..1), salvati in un file impostazioni separato dai salvataggi di gioco
## e scritti subito (non sono progressi). Il volume effettivo del bus = volume del layout + questo valore.

const PATH: String = "user://settings.cfg"
const SECTION: String = "audio"
const BUSES: Array[StringName] = [&"Music", &"SFX"]

## Volume in dB definito in default_bus_layout.tres, letto una volta prima di applicare le impostazioni.
static var _layout_db: Dictionary[StringName, float] = {}

var volumes: Dictionary[StringName, float] = {&"Music": 1.0, &"SFX": 1.0}
var path: String = PATH


static func load_and_apply() -> AudioSettings:
	var settings := AudioSettings.new()
	settings.load_file()
	settings.apply()
	return settings


func volume(bus: StringName) -> float:
	return volumes.get(bus, 1.0)


func set_volume(bus: StringName, linear: float) -> void:
	volumes[bus] = clampf(linear, 0.0, 1.0)


## Scala logaritmica: 50% = circa -6 dB rispetto al layout, 0% = muto.
static func to_db(linear: float) -> float:
	return linear_to_db(maxf(linear, 0.0001))


func apply() -> void:
	for bus in BUSES:
		var index := AudioServer.get_bus_index(bus)
		if index < 0:
			continue
		if not _layout_db.has(bus):
			_layout_db[bus] = AudioServer.get_bus_volume_db(index)
		AudioServer.set_bus_volume_db(index, _layout_db[bus] + to_db(volume(bus)))
		AudioServer.set_bus_mute(index, volume(bus) <= 0.001)


func load_file() -> Error:
	var config := ConfigFile.new()
	var error := config.load(path)
	if error == OK:
		for bus in BUSES:
			set_volume(bus, float(config.get_value(SECTION, String(bus), 1.0)))
	return error


func save_file() -> Error:
	var config := ConfigFile.new()
	for bus in BUSES:
		config.set_value(SECTION, String(bus), volume(bus))
	return config.save(path)
