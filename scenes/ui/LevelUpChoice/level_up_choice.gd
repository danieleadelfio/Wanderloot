class_name LevelUpChoice
extends CanvasLayer
## Overlay di scelta upgrade al level-up. Funziona a gioco in pausa (process_mode ALWAYS).
## Reroll (M12, #86): rimescola le scelte con una in meno, max RunManager.MAX_REROLLS a run.

signal upgrade_chosen(upgrade: UpgradeData)
signal reroll_requested

const BUTTON_SIZE: Vector2 = Vector2(220.0, 110.0)

@onready var _choices: HBoxContainer = %Choices
@onready var _reroll_button: Button = %RerollButton


func _ready() -> void:
	hide()
	_reroll_button.pressed.connect(reroll_requested.emit)


## rerolls_left: quanti reroll restano nella run; il bottone si disabilita a 0.
func present(options: Array[UpgradeData], rerolls_left: int) -> void:
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
	_reroll_button.text = tr("LEVELUP_REROLL") % rerolls_left
	_reroll_button.disabled = rerolls_left <= 0
	show()
	if _choices.get_child_count() > 0:
		(_choices.get_child(0) as Button).grab_focus()


func _on_choice_pressed(upgrade: UpgradeData) -> void:
	hide()
	upgrade_chosen.emit(upgrade)
