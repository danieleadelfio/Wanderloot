class_name OptionsPanel
extends PanelContainer
## Pannello Opzioni condiviso da menu iniziale e menu di pausa (M9): volumi (applicati e salvati subito),
## Cancella dati (solo se allow_delete, doppia conferma), lingua (chi ospita il pannello applica il cambio).
## ESC o Indietro chiudono il pannello.

signal back_requested
## Emesso alla seconda pressione di "Cancella dati salvati": la cancellazione la fa chi ospita il pannello.
signal delete_confirmed
## Lingua diversa da quella attiva scelta nel selettore.
signal language_selected(locale: String)

@export var allow_delete: bool = false
## Mostra l'avviso che il cambio lingua salva e torna al menu (menu di pausa).
@export var show_language_hint: bool = false

var _settings: AudioSettings
var _delete_armed: bool = false

@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _music_value: Label = %MusicValue
@onready var _sfx_value: Label = %SfxValue
@onready var _delete_button: Button = %DeleteButton
@onready var _delete_separator: Control = %DeleteSeparator
@onready var _status: Label = %OptionsStatus
@onready var _back_button: Button = %BackButton
@onready var _language_option: OptionButton = %LanguageOption
@onready var _language_hint: Label = %LanguageHint


func _ready() -> void:
	_settings = AudioSettings.new()
	_settings.load_file()
	_music_slider.value = _settings.volume(&"Music") * 100.0
	_sfx_slider.value = _settings.volume(&"SFX") * 100.0
	_music_slider.value_changed.connect(_on_volume_changed.bind(&"Music"))
	_sfx_slider.value_changed.connect(_on_volume_changed.bind(&"SFX"))
	_delete_button.pressed.connect(_on_delete_pressed)
	_back_button.pressed.connect(back_requested.emit)
	for locale in LocaleSettings.LOCALES:
		_language_option.add_item(LocaleSettings.NAMES[locale])
	_language_option.item_selected.connect(_on_language_item_selected)
	_language_hint.visible = show_language_hint
	_delete_button.visible = allow_delete
	_delete_separator.visible = allow_delete
	_update_value_labels()


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


## Da chiamare quando il pannello viene mostrato: azzera messaggi e conferme, aggiorna Cancella.
func open(can_delete: bool = false) -> void:
	_status.text = ""
	_delete_armed = false
	_delete_button.text = tr("OPT_DELETE")
	_delete_button.disabled = not can_delete
	_language_option.select(LocaleSettings.LOCALES.find(LocaleSettings.current()))
	_music_slider.grab_focus()


func show_status(text: String) -> void:
	_status.text = text


func _on_volume_changed(value: float, bus: StringName) -> void:
	_settings.set_volume(bus, value / 100.0)
	_settings.apply()
	_settings.save_file()
	_update_value_labels()


func _update_value_labels() -> void:
	_music_value.text = "%d%%" % roundi(_music_slider.value)
	_sfx_value.text = "%d%%" % roundi(_sfx_slider.value)


func _on_language_item_selected(index: int) -> void:
	var locale := LocaleSettings.LOCALES[index]
	if locale != LocaleSettings.current():
		language_selected.emit(locale)


func _on_delete_pressed() -> void:
	if not _delete_armed:
		_delete_armed = true
		_delete_button.text = tr("OPT_DELETE_CONFIRM")
		_status.text = tr("OPT_DELETE_WARNING")
		return
	_delete_armed = false
	_delete_button.text = tr("OPT_DELETE")
	delete_confirmed.emit()
