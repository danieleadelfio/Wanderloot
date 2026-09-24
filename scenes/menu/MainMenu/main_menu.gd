extends Control
## Menu iniziale (M8): Continua (solo con un salvataggio), Nuova partita, Opzioni (volumi, cancella dati), Esci.
## Scena principale del gioco. Applica le impostazioni audio all'avvio.

var _settings: AudioSettings
var _delete_armed: bool = false

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
@onready var _new_game_hint: Label = %NewGameHint
@onready var _main_panel: Control = %MainPanel
@onready var _options_panel: Control = %OptionsPanel
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _music_value: Label = %MusicValue
@onready var _sfx_value: Label = %SfxValue
@onready var _delete_button: Button = %DeleteButton
@onready var _options_status: Label = %OptionsStatus
@onready var _back_button: Button = %BackButton
@onready var _swirl: Control = %Swirl
@onready var _sfx: SfxPlayer = %Sfx


func _ready() -> void:
	get_tree().paused = false
	_settings = AudioSettings.load_and_apply()
	_continue_button.pressed.connect(_on_continue_pressed)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_options_button.pressed.connect(_show_options.bind(true))
	_back_button.pressed.connect(_show_options.bind(false))
	_quit_button.pressed.connect(get_tree().quit)
	_delete_button.pressed.connect(_on_delete_pressed)
	_music_slider.value = _settings.volume(&"Music") * 100.0
	_sfx_slider.value = _settings.volume(&"SFX") * 100.0
	_music_slider.value_changed.connect(_on_volume_changed.bind(&"Music"))
	_sfx_slider.value_changed.connect(_on_volume_changed.bind(&"SFX"))
	_sfx_slider.drag_ended.connect(_sfx.play.bind(&"ui_select").unbind(1))
	_show_options(false)


func _process(delta: float) -> void:
	_swirl.rotation += delta * 0.6


func _unhandled_input(event: InputEvent) -> void:
	if _options_panel.visible and event.is_action_pressed("menu"):
		_show_options(false)
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	var has_save := MetaProgression.has_save()
	_continue_button.visible = has_save
	_new_game_hint.visible = has_save
	_delete_button.disabled = not has_save
	_delete_armed = false
	_delete_button.text = "Cancella dati salvati"
	_update_value_labels()


func _show_options(show_options: bool) -> void:
	_main_panel.visible = not show_options
	_options_panel.visible = show_options
	_options_status.text = ""
	_refresh()
	if show_options:
		_music_slider.grab_focus()
	elif _continue_button.visible:
		_continue_button.grab_focus()
	else:
		_new_game_button.grab_focus()


func _on_continue_pressed() -> void:
	if MetaProgression.load_game() == OK:
		get_tree().change_scene_to_file(SceneRoutes.HUB)


func _on_new_game_pressed() -> void:
	MetaProgression.new_game()
	get_tree().change_scene_to_file(SceneRoutes.HUB)


func _on_volume_changed(value: float, bus: StringName) -> void:
	_settings.set_volume(bus, value / 100.0)
	_settings.apply()
	_settings.save_file()
	_update_value_labels()


func _update_value_labels() -> void:
	_music_value.text = "%d%%" % roundi(_music_slider.value)
	_sfx_value.text = "%d%%" % roundi(_sfx_slider.value)


## Doppia pressione: la prima arma la cancellazione, la seconda cancella il file e azzera lo stato in memoria.
func _on_delete_pressed() -> void:
	if not _delete_armed:
		_delete_armed = true
		_delete_button.text = "Conferma: cancella tutto"
		_options_status.text = "Il salvataggio verra' eliminato definitivamente."
		return
	var ok := MetaProgression.delete_save() == OK
	MetaProgression.new_game()
	_refresh()
	_options_status.text = "Dati cancellati." if ok else "Cancellazione non riuscita."
	_sfx.play(&"ui_select")
