class_name PauseMenu
extends CanvasLayer
## Menu di pausa (ESC) e scritta PAUSA (P). Solo presentazione: le scelte tornano via segnale,
## salvataggio e caricamento li esegue la composition root (Arena, Hub) tramite GameSession.

signal action_requested(action: PauseState.Action)
signal save_requested
signal load_requested
## Abbandona Run (M12, #86): torna all'hub abbandonando la run in corso (loot non estratto perso).
## Nascosto nell'hub (set_can_abandon), dove non c'e' una run da abbandonare.
signal abandon_requested
signal menu_requested
## Lingua scelta nelle Opzioni: la composition root salva e torna al menu iniziale.
signal language_requested(locale: String)

## Con modifiche non salvate "Torna al menu" chiede una seconda pressione.
var _unsaved_changes: bool = false
var _menu_armed: bool = false

@onready var _menu: Control = %Menu
@onready var _pause_label: Label = %PauseLabel
@onready var _resume_button: Button = %ResumeButton
@onready var _save_button: Button = %SaveButton
@onready var _load_button: Button = %LoadButton
@onready var _abandon_button: Button = %AbandonButton
@onready var _menu_button: Button = %MenuButton
@onready var _options_button: Button = %OptionsButton
@onready var _buttons: Control = %VBox
@onready var _options_panel: OptionsPanel = %OptionsPanel
@onready var _status_label: Label = %StatusLabel
@onready var _hint: Label = %Hint


func _ready() -> void:
	show_mode(PauseState.Mode.NONE)
	_resume_button.pressed.connect(action_requested.emit.bind(PauseState.Action.RESUME))
	_save_button.pressed.connect(save_requested.emit)
	_load_button.pressed.connect(load_requested.emit)
	_abandon_button.pressed.connect(abandon_requested.emit)
	_menu_button.pressed.connect(_on_menu_pressed)
	_options_button.pressed.connect(_show_options.bind(true))
	_options_panel.back_requested.connect(_show_options.bind(false))
	_options_panel.language_selected.connect(language_requested.emit)


func show_mode(mode: PauseState.Mode) -> void:
	_menu.visible = mode == PauseState.Mode.MENU
	_pause_label.visible = mode == PauseState.Mode.PAUSED
	_status_label.text = ""
	_menu_armed = false
	_buttons.visible = true
	_options_panel.visible = false
	if _menu.visible:
		_resume_button.grab_focus()


## Carica e' disattivato se non esiste un salvataggio.
func set_can_load(can_load: bool) -> void:
	_load_button.disabled = not can_load


## Abbandona Run visibile solo in run (M12, #86): l'hub lo nasconde, non c'e' nulla da abbandonare.
func set_can_abandon(can_abandon: bool) -> void:
	_abandon_button.visible = can_abandon


func show_status(text: String) -> void:
	_status_label.text = text


## Testo d'aiuto sotto i bottoni (nell'hub P non e' la pausa diretta).
## Opzioni dentro il menu di pausa: volumi (e lingua); ESC o Indietro tornano ai bottoni.
func _show_options(show_options: bool) -> void:
	_buttons.visible = not show_options
	_options_panel.visible = show_options
	if show_options:
		_options_panel.open()
	elif _menu.visible:
		_options_button.grab_focus()


func set_hint(text: String) -> void:
	_hint.text = text


func set_unsaved_changes(unsaved: bool) -> void:
	_unsaved_changes = unsaved
	_menu_armed = false


func _on_menu_pressed() -> void:
	if _unsaved_changes and not _menu_armed:
		_menu_armed = true
		show_status(tr("PAUSE_UNSAVED"))
		return
	menu_requested.emit()
