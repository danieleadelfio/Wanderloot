class_name LevelUpChoice
extends CanvasLayer
## Overlay di scelta upgrade al level-up. Funziona a gioco in pausa (process_mode ALWAYS).

signal upgrade_chosen(upgrade: UpgradeData)

const BUTTON_SIZE: Vector2 = Vector2(220.0, 110.0)

@onready var _choices: HBoxContainer = %Choices


func _ready() -> void:
	hide()


func present(options: Array[UpgradeData]) -> void:
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	for upgrade in options:
		var button := Button.new()
		button.text = "%s\n%s" % [tr(upgrade.display_name), tr(upgrade.description)]
		button.custom_minimum_size = BUTTON_SIZE
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_choice_pressed.bind(upgrade))
		_choices.add_child(button)
	show()
	if _choices.get_child_count() > 0:
		(_choices.get_child(0) as Button).grab_focus()


func _on_choice_pressed(upgrade: UpgradeData) -> void:
	hide()
	upgrade_chosen.emit(upgrade)
