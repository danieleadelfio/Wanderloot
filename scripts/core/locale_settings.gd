class_name LocaleSettings
extends RefCounted
## Lingua del gioco (M9): italiano, inglese, francese, spagnolo. Salvata nel file impostazioni (sezione general),
## indipendente dal salvataggio di gioco, e applicata all'avvio dal menu iniziale.

const PATH: String = "user://settings.cfg"
const SECTION: String = "general"
const LOCALES: PackedStringArray = ["it", "en", "fr", "es"]
## Nomi mostrati nel selettore, sempre nella propria lingua.
const NAMES: Dictionary[String, String] = {"it": "Italiano", "en": "English", "fr": "Français", "es": "Español"}


## Lingua attiva ridotta al codice a due lettere; "en" se non supportata.
static func current() -> String:
	return normalize(TranslationServer.get_locale())


static func normalize(locale: String) -> String:
	var code := locale.substr(0, 2).to_lower()
	return code if code in LOCALES else "en"


static func load_saved(path: String = PATH) -> String:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return normalize(OS.get_locale_language())
	return normalize(String(config.get_value(SECTION, "locale", OS.get_locale_language())))


static func load_and_apply(path: String = PATH) -> String:
	var locale := load_saved(path)
	TranslationServer.set_locale(locale)
	return locale


static func save_locale(locale: String, path: String = PATH) -> Error:
	var config := ConfigFile.new()
	config.load(path)
	config.set_value(SECTION, "locale", normalize(locale))
	return config.save(path)
