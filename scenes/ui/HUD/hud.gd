class_name Hud
extends CanvasLayer
## HUD minimale: HP ed estrazione (da Arena), livello ed exp (da RunManager).

@onready var _hp_label: Label = %HpLabel
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _level_label: Label = %LevelLabel
@onready var _exp_label: Label = %ExpLabel
@onready var _exp_bar: ProgressBar = %ExpBar
@onready var _extraction_label: Label = %ExtractionLabel


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


func set_extraction_countdown(seconds: float) -> void:
	_extraction_label.text = "Estrazione tra %ds" % ceili(seconds)


func set_extraction_progress(ratio: float) -> void:
	if ratio > 0.0:
		_extraction_label.text = "Estrazione %d%%" % roundi(ratio * 100.0)
	else:
		_extraction_label.text = "Estrazione disponibile: raggiungi la zona verde"
