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
@onready var _ability_bar: HBoxContainer = %AbilityBar
@onready var _buff_label: Label = %BuffLabel
@onready var _event_banner: Control = %EventBanner
@onready var _event_title: Label = %EventTitle
@onready var _event_subtitle: Label = %EventSubtitle
@onready var _event_bar: ProgressBar = %EventBar
var _banner_tween: Tween
@onready var _overtime_label: Label = %OvertimeLabel
@onready var _announce: Control = %Announce
@onready var _announce_title: Label = %AnnounceTitle
@onready var _announce_subtitle: Label = %AnnounceSubtitle
var _announce_tween: Tween
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


## Statistiche del personaggio sotto le barre (solo in run), aggiornate a ogni potenziamento. A 3 numeri
## (M12, #86): base di partenza (giallo, fisso), bonus dell'equip indossato (verde), valore finale (bianco).
func set_stats(player: Player, equip_modifiers: Array[StatModifier]) -> void:
	var rows := StatSheet.equip_rows(player.base_stats(), player.base_weapon_data(), player.stats, player.weapon_data(), equip_modifiers)
	StatSheet.fill_with_equip(_stats_grid, rows, 13)


## Icone delle abilita' della bacchetta (M10); il riempimento mostra l'avanzamento verso l'attivazione.
func set_abilities(abilities: Array[WandAbility], levels: Dictionary = {}) -> void:
	for child in _ability_bar.get_children():
		child.queue_free()
	for ability in abilities:
		var icon := TextureProgressBar.new()
		icon.texture_under = ability.icon
		icon.texture_progress = ability.icon
		icon.tint_under = Color(0.35, 0.35, 0.4)
		icon.fill_mode = TextureProgressBar.FILL_BOTTOM_TO_TOP
		icon.nine_patch_stretch = true
		icon.custom_minimum_size = Vector2(36, 36)
		icon.max_value = 1.0
		icon.step = 0.01
		icon.tooltip_text = tr(ability.display_name)
		var level: int = levels.get(ability.id, 1)
		if level > 1:
			var label := Label.new()
			label.text = "%d" % level
			label.add_theme_font_size_override("font_size", 13)
			label.add_theme_color_override("font_outline_color", Color.BLACK)
			label.add_theme_constant_override("outline_size", 4)
			label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
			label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			label.grow_vertical = Control.GROW_DIRECTION_BEGIN
			icon.add_child(label)
		_ability_bar.add_child(icon)


func set_ability_progress(index: int, ratio: float) -> void:
	if index < _ability_bar.get_child_count():
		(_ability_bar.get_child(index) as TextureProgressBar).value = ratio


## Evento in corso (M10): titolo grande, obiettivo in poche parole, barra del tempo rimasto.
func show_event(title: String, subtitle: String) -> void:
	if _banner_tween:
		_banner_tween.kill()
	_event_title.text = tr(title)
	_event_subtitle.text = tr(subtitle)
	_event_bar.visible = true
	_event_bar.value = 1.0
	_event_banner.modulate.a = 1.0
	_event_banner.visible = true


func set_event_subtitle(text: String) -> void:
	_event_subtitle.text = text


func set_event_progress(ratio: float) -> void:
	_event_bar.value = ratio


## Esito: il banner mostra il risultato e sparisce dopo poco (subito se si apre la scelta dell'abilita').
func end_event(success: bool, detail: String = "") -> void:
	_event_title.text = tr("EVENT_COMPLETED") if success else tr("EVENT_FAILED")
	_event_subtitle.text = detail if detail != "" or success else tr("EVENT_FAILED_HINT")
	_event_bar.visible = false
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_interval(1.6)
	_banner_tween.tween_property(_event_banner, "modulate:a", 0.0, 0.4)
	_banner_tween.tween_callback(_event_banner.hide)


## Effetti a tempo dei consumabili (nome tradotto -> secondi rimasti).
func set_buffs(buffs: Dictionary) -> void:
	var parts: PackedStringArray = []
	for name in buffs:
		parts.append(tr("HUD_BUFF") % [tr(name), ceili(buffs[name])])
	_buff_label.text = "  ".join(parts)


func show_boss(boss_name: String, current: int, maximum: int) -> void:
	_boss_name.text = tr(boss_name)
	_boss_panel.visible = true
	set_boss_hp(current, maximum)


func set_boss_hp(current: int, maximum: int) -> void:
	_boss_bar.max_value = maxi(maximum, 1)
	_boss_bar.value = current


func hide_boss() -> void:
	_boss_panel.visible = false


## Annuncio breve (overtime): sotto il banner degli eventi, sparisce da solo dopo `hold` secondi.
func announce(title: String, subtitle: String, hold: float = 2.5) -> void:
	_announce_title.text = title
	_announce_subtitle.text = subtitle
	_announce.modulate.a = 1.0
	_announce.show()
	if _announce_tween:
		_announce_tween.kill()
	_announce_tween = create_tween()
	_announce_tween.tween_interval(hold)
	_announce_tween.tween_property(_announce, "modulate:a", 0.0, 0.5)
	_announce_tween.tween_callback(_announce.hide)


## Livello di overtime sempre visibile sotto l'estrazione (0 = nascosto).
func set_overtime(level: int) -> void:
	_overtime_label.visible = level > 0
	_overtime_label.text = tr("OVERTIME_TITLE") % level


func set_extraction_countdown(seconds: float) -> void:
	_extraction_label.text = tr("HUD_EXTRACTION_IN") % ceili(seconds)


func set_extraction_progress(ratio: float) -> void:
	if ratio > 0.0:
		_extraction_label.text = tr("HUD_EXTRACTION_PROGRESS") % roundi(ratio * 100.0)
	else:
		_extraction_label.text = tr("HUD_EXTRACTION_READY")
