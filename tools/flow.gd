extends SceneTree
## Playtest end-to-end automatico (uso: godot --headless --fixed-fps 60 --path . -s tools/flow.gd): hub -> run (bot) -> estrazione -> hub -> craft -> equip -> run -> morte -> hub -> riavvio.
var step := 0
var t := 0
var log_lines: PackedStringArray = []
var stash_before := {}
var attempts := 0

func _initialize() -> void:
	var m = root.get_node("MetaProgression")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://flow.cfg"))
	m.save_path = "user://flow.cfg"
	m.load_from_disk()
	change_scene_to_file("res://scenes/hub/Hub/Hub.tscn")

func say(s): print("[flow] ", s)

func _physics_process(_d: float) -> bool:
	t += 1
	var s = current_scene
	if s == null: return false
	var m = root.get_node("MetaProgression")
	var rm = root.get_node("RunManager")
	match step:
		0:
			if s.name == "Hub" and t > 3:
				say("hub, baule=%s" % m.inventory.to_dictionary())
				s.get_node("%StartButton").pressed.emit(); step = 1
		1, 4:
			if s.name == "Arena":
				if rm.state == 2:
					s.get_node("%LevelUpChoice")._on_choice_pressed(BotDriver.choose(s.upgrade_table.pick(3, RandomNumberGenerator.new())))
				elif rm.state == 3:
					var end = s.get_node("%RunEndScreen")
					if end.visible:
						var title: String = end.get_node("%TitleLabel").text
						say("fine run: %s tempo=%ds uccisioni=%d | %s" % [title, rm.elapsed, rm.kills, end.get_node("%LootLabel").text])
						end.get_node("%RestartButton").pressed.emit(); t = 0
						# step 1: si ripete finche' un'estrazione non riesce (max 6 tentativi)
						attempts += 1
						if step == 4 or title == TranslationServer.translate("RUNEND_EXTRACTED") or attempts >= 6: step += 1
						else: step = 0
				else:
					_drive(s, step == 1)
		2:
			if s.name == "Hub" and t > 3:
				say("ritorno hub, baule=%s" % m.inventory.to_dictionary())
				var buttons = s.get_node("%Blacksmith").get_node("%RecipeList").get_children().filter(func(b): return not b.disabled)
				if buttons.is_empty(): say("BUG? nessuna ricetta craftabile"); return true
				buttons[0].pressed.emit(); step = 3; t = 0
		3:
			if t > 3:
				say("craft -> baule=%s posseduti=%s" % [m.inventory.to_dictionary(), m.loadout.all_items().map(func(i): return i.base.id)])
				var stash = m.loadout.stash_items()
				if not stash.is_empty(): m.equip(stash[0].uid)
				say("equip -> %s" % [m.equipped_items().map(func(i): return i.base.id)])
				stash_before = m.inventory.to_dictionary()
				s.get_node("%StartButton").pressed.emit(); step = 4; t = 0
		5:
			if s.name == "Hub" and t > 3:
				var ok: bool = m.inventory.to_dictionary() == stash_before
				# M8: salvataggi manuali, si salva dal menu di pausa dell'hub prima di ricaricare
				s.get_node("%PauseMenu").get_node("%SaveButton").pressed.emit()
				say("salva dal menu di pausa -> file=%s" % m.has_save())
				say("dopo morte baule invariato=%s (%s)" % [ok, m.inventory.to_dictionary()])
				var fresh = preload("res://autoload/meta_progression.gd").new()
				fresh.save_path = "user://flow.cfg"; fresh.load_from_disk()
				say("ricarica da disco: baule=%s equip=%s" % [fresh.inventory.to_dictionary(), fresh.equipped_items().map(func(i): return i.base.id)])
				fresh.free()
				say("time_scale=%s paused=%s" % [Engine.time_scale, paused])
				s.get_node("%PauseMenu").get_node("%MenuButton").pressed.emit(); step = 6; t = 0
		6:
			if s.name == "MainMenu" and t > 3:
				var cont = s.get_node("%ContinueButton")
				say("menu iniziale: Continua visibile=%s" % cont.visible)
				cont.pressed.emit(); step = 7; t = 0
		7:
			if s.name == "Hub" and t > 3:
				say("Continua -> hub, baule=%s" % m.inventory.to_dictionary())
				return true
	return false

func _drive(a, dodging: bool) -> void:
	if t == 2 and not dodging:
		var p = a.get_node("%Player")
		say("run 2: hp max=%d danno=%d (equip applicato)" % [p.health.max_hp, p._weapon.data.damage])
	# riusa la guida del bot; in run 2 il player sta fermo e non spara (morte certa)
	if BotDriver.resolve_menus(a): return
	if dodging:
		BotDriver.drive(a)
	else:
		for act in ["move_left","move_right","move_up","move_down","aim_left","aim_right","aim_up","aim_down"]: Input.action_release(act)
