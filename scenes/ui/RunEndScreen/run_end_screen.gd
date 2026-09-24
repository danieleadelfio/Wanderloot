class_name RunEndScreen
extends CanvasLayer
## Schermata di fine run (morte o estrazione) con riepilogo e ritorno all'hub. Funziona in pausa.

signal restart_requested

@onready var _title_label: Label = %TitleLabel
@onready var _summary_label: Label = %SummaryLabel
@onready var _loot_label: Label = %LootLabel
@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	hide()
	_restart_button.pressed.connect(_on_restart_pressed)


func present(extracted: bool, level: int, elapsed: float, kills: int, loot_amount: int, stash_total: int, items: Array[ItemInstance] = []) -> void:
	_title_label.text = tr("RUNEND_EXTRACTED") if extracted else tr("RUNEND_DEAD")
	var seconds := int(elapsed)
	_summary_label.text = tr("RUNEND_SUMMARY") % [level, seconds / 60, seconds % 60, kills]
	if extracted:
		_loot_label.text = tr("RUNEND_LOOT_EXTRACTED") % [loot_amount, stash_total]
	else:
		_loot_label.text = tr("RUNEND_LOOT_LOST") % loot_amount
	if not items.is_empty():
		var names := PackedStringArray()
		for item in items:
			names.append(ItemText.title(item))
		_loot_label.text += "\n" + (tr("RUNEND_ITEMS_EXTRACTED") if extracted else tr("RUNEND_ITEMS_LOST")) % ", ".join(names)
	show()
	_restart_button.grab_focus()


func _on_restart_pressed() -> void:
	hide()
	restart_requested.emit()
