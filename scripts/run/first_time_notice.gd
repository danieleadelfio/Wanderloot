class_name FirstTimeNotice
extends CanvasLayer
## Spiegazione a schermo intero la prima volta in assoluto che capita qualcosa (primo evento, primo
## avviso di overtime, M12 #86): a differenza di HUD.announce() (sparisce da solo, il gioco continua),
## questa ferma la run finche' non si preme Continua, cosi' si legge con calma senza essere colpiti nel
## frattempo. Una volta per voce (Arena la mostra solo se MetaProgression.has_seen_tutorial() e' falso).

signal dismissed

@onready var _title: Label = %Title
@onready var _body: Label = %Body
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	hide()
	_continue_button.pressed.connect(_on_continue_pressed)


func show_notice(title: String, body: String) -> void:
	_title.text = title
	_body.text = body
	show()
	_continue_button.grab_focus()


func _on_continue_pressed() -> void:
	hide()
	dismissed.emit()
