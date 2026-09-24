class_name Hud
extends CanvasLayer
## HUD minimale: HP ed estrazione (da Arena), livello, exp e loot di run (da RunManager).

@onready var _hp_label: Label = %HpLabel
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _level_label: Label = %LevelLabel
@onready var _exp_label: Label = %ExpLabel
@onready var _exp_bar: ProgressBar = %ExpBar
@onready var _extraction_label: Label = %ExtractionLabel
@onready var _loot_label: Label = %LootLabel
@onready var _boss_panel: Control = %BossPanel
@onready var _stats_grid: GridContainer = %StatsGrid
@onready var _boss_name: Label = %BossName
@onready var _boss_bar: ProgressBar = %BossBar


func _ready() -> void:
	RunManager.exp_changed.connect(set_exp)
	RunManager.leveled_up.connect(set_level)
	RunManager.loot.changed.connect(set_loot)
	set_level(RunManager.level)
	set_exp(RunManager.experience, RunManager.exp_to_next())
	set_loot(RunManager.loot.total())


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


func set_loot(total: int) -> void:
	_loot_label.text = tr("HUD_LOOT") % total


## Statistiche del personaggio sotto le barre (solo in run), aggiornate a ogni potenziamento.
func set_stats(stats: PlayerStats, weapon: WeaponData) -> void:
	StatSheet.fill(_stats_grid, StatSheet.rows(stats, weapon), 13)


func show_boss(boss_name: String, current: int, maximum: int) -> void:
	_boss_name.text = tr(boss_name)
	_boss_panel.visible = true
	set_boss_hp(current, maximum)


func set_boss_hp(current: int, maximum: int) -> void:
	_boss_bar.max_value = maxi(maximum, 1)
	_boss_bar.value = current


func hide_boss() -> void:
	_boss_panel.visible = false


func set_extraction_countdown(seconds: float) -> void:
	_extraction_label.text = tr("HUD_EXTRACTION_IN") % ceili(seconds)


func set_extraction_progress(ratio: float) -> void:
	if ratio > 0.0:
		_extraction_label.text = tr("HUD_EXTRACTION_PROGRESS") % roundi(ratio * 100.0)
	else:
		_extraction_label.text = tr("HUD_EXTRACTION_READY")
