class_name RunEndScreen
extends CanvasLayer
## Schermata di fine run (morte o estrazione) con riepilogo, loot da guardare e ritorno all'hub. Funziona in pausa.

signal restart_requested

## Per le icone del loot (id sconosciuti non mostrati).
@export var materials: Array[MaterialData] = []

var _extracted: bool = false
var _amounts: Dictionary = {}
var _items: Array[ItemInstance] = []

@onready var _title_label: Label = %TitleLabel
@onready var _summary_label: Label = %SummaryLabel
@onready var _loot_label: Label = %LootLabel
@onready var _restart_button: Button = %RestartButton
@onready var _loot_button: Button = %LootButton
@onready var _center: Control = %Center
@onready var _loot_view: LootView = %LootView


func _ready() -> void:
	hide()
	_restart_button.pressed.connect(_on_restart_pressed)
	_loot_button.pressed.connect(_show_loot)
	_loot_view.back_requested.connect(_show_summary)
	_loot_view.hub_requested.connect(_on_restart_pressed)


## amounts: materiali raccolti (id -> quantita'), items: oggetti trovati; entrambi presi prima del trasferimento.
func present(extracted: bool, level: int, elapsed: float, kills: int, loot_amount: int, stash_total: int, items: Array[ItemInstance] = [], amounts: Dictionary = {}) -> void:
	_extracted = extracted
	_amounts = amounts
	_items = items
	_title_label.text = tr("RUNEND_EXTRACTED") if extracted else tr("RUNEND_DEAD")
	var seconds := int(elapsed)
	_summary_label.text = tr("RUNEND_SUMMARY") % [level, seconds / 60, seconds % 60, kills]
	if extracted:
		_loot_label.text = tr("RUNEND_LOOT_EXTRACTED") % [loot_amount, stash_total]
	else:
		_loot_label.text = tr("RUNEND_LOOT_LOST") % loot_amount
	if not items.is_empty():
		_loot_label.text += "\n" + (tr("RUNEND_ITEMS_EXTRACTED") if extracted else tr("RUNEND_ITEMS_LOST")) % str(items.size())
	_loot_button.disabled = items.is_empty() and amounts.is_empty()
	show()
	_show_summary()


func _show_loot() -> void:
	_center.hide()
	_loot_view.present(_extracted, materials, _amounts, _items)


func _show_summary() -> void:
	_loot_view.hide()
	_center.show()
	_restart_button.grab_focus()


func _on_restart_pressed() -> void:
	hide()
	restart_requested.emit()
