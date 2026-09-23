class_name Hud
extends CanvasLayer
## HUD minimale: HP (da Arena via set_hp), livello ed exp (da RunManager).

@onready var _hp_label: Label = %HpLabel
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _level_label: Label = %LevelLabel
@onready var _exp_label: Label = %ExpLabel
@onready var _exp_bar: ProgressBar = %ExpBar


func _ready() -> void:
	RunManager.exp_changed.connect(set_exp)
	RunManager.leveled_up.connect(set_level)
	set_level(RunManager.level)
	set_exp(RunManager.experience, RunManager.exp_to_next())


func set_hp(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_hp_label.text = "HP %d/%d" % [current, maximum]


func set_level(level: int) -> void:
	_level_label.text = "LV %d" % level


func set_exp(current: int, required: int) -> void:
	_exp_bar.max_value = maxi(required, 1)
	_exp_bar.value = current
	_exp_label.text = "EXP %d/%d" % [current, required]
