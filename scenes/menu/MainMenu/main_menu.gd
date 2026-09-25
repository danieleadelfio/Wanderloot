extends Control
## Menu iniziale (M8): Continua (solo con un salvataggio), Nuova partita, Opzioni (volumi, cancella dati), Esci.
## Scena principale del gioco. Applica le impostazioni audio all'avvio.

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
@onready var _new_game_hint: Label = %NewGameHint
@onready var _main_panel: Control = %MainPanel
@onready var _options_panel: OptionsPanel = %OptionsPanel
@onready var _swirl: Control = %Swirl
@onready var _sfx: SfxPlayer = %Sfx


func _ready() -> void:
	get_tree().paused = false
	LocaleSettings.load_and_apply()
	AudioSettings.load_and_apply()
	InputSettings.load_and_apply()
	_continue_button.pressed.connect(_on_continue_pressed)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_options_button.pressed.connect(_show_options.bind(true))
	_options_panel.back_requested.connect(_show_options.bind(false))
	_options_panel.delete_confirmed.connect(_on_delete_confirmed)
	_options_panel.language_selected.connect(_on_language_selected)
	_quit_button.pressed.connect(get_tree().quit)
	_show_options(false)


func _process(delta: float) -> void:
	_swirl.rotation += delta * 0.6


func _refresh() -> void:
	var has_save := MetaProgression.has_save()
	_continue_button.visible = has_save
	_new_game_hint.visible = has_save


func _show_options(show_options: bool) -> void:
	_main_panel.visible = not show_options
	_options_panel.visible = show_options
	_refresh()
	if show_options:
		_options_panel.open(MetaProgression.has_save())
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


func _on_delete_confirmed() -> void:
	var ok := MetaProgression.delete_save() == OK
	MetaProgression.new_game()
	_refresh()
	_options_panel.open(MetaProgression.has_save())
	_options_panel.show_status(tr("DATA_DELETED") if ok else tr("DATA_DELETE_FAIL"))
	_sfx.play(&"ui_select")


## Dal menu iniziale non c'e' una partita in corso da salvare: si applica la lingua e si ricarica il menu.
func _on_language_selected(locale: String) -> void:
	LocaleSettings.save_locale(locale)
	TranslationServer.set_locale(locale)
	get_tree().reload_current_scene.call_deferred()
