class_name RunEndScreen
extends CanvasLayer
## Schermata di fine run (morte o estrazione) con riepilogo e riavvio. Funziona in pausa.

signal restart_requested

@onready var _title_label: Label = %TitleLabel
@onready var _summary_label: Label = %SummaryLabel
@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	hide()
	_restart_button.pressed.connect(_on_restart_pressed)


func present(extracted: bool, level: int, elapsed: float, kills: int) -> void:
	_title_label.text = "Estrazione riuscita!" if extracted else "Sei morto"
	var seconds := int(elapsed)
	_summary_label.text = "Livello %d  ·  Tempo %d:%02d  ·  Uccisioni %d" % [level, seconds / 60, seconds % 60, kills]
	show()
	_restart_button.grab_focus()


func _on_restart_pressed() -> void:
	hide()
	restart_requested.emit()
