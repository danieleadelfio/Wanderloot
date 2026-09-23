class_name Hud
extends CanvasLayer
## HUD minimale: HP (da Arena via set_hp) ed exp (da RunManager).

@onready var _hp_label: Label = %HpLabel
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _exp_label: Label = %ExpLabel


func _ready() -> void:
	RunManager.exp_changed.connect(set_exp)
	set_exp(RunManager.experience)


func set_hp(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_hp_label.text = "HP %d/%d" % [current, maximum]


func set_exp(total: int) -> void:
	_exp_label.text = "EXP %d" % total
