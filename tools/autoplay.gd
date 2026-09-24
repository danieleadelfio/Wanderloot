extends SceneTree
## Bot di playtest: gioca N run nell'Arena (kiting + mira automatica + va all'estrazione) e stampa metriche.
## Uso (dalla root del progetto): godot --headless --fixed-fps 60 --path . -s tools/autoplay.gd -- <runs> [equip_ids...] [arena=<id>]
## --fixed-fps fa girare la simulazione alla massima velocita' con delta fisso. Il salvataggio usato e' user://bot.cfg.
## Non e' un test: serve a confrontare i .tres di bilanciamento a parita' di giocatore.
var runs := 10
var equip: Array = []
var done := 0
var results: Array = []
var rng := RandomNumberGenerator.new()
var arena: Node = null
var ended := false
var damage_taken := 0
var last_gel := 0
var last_core := 0
var last_loot: Dictionary = {}
var last_items: Array[String] = []
var events_won := 0
var events_lost := 0
var pentas_won := 0
var pentas_lost := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: runs = int(args[0])
	for i in range(1, args.size()):
		if args[i] == "boss":
			BotDriver.fight_boss = true
		elif args[i] == "stay":
			BotDriver.stay = true
		elif args[i].begins_with("arena="):
			var m = root.get_node("MetaProgression")
			m.save_path = "user://bot.cfg"
			for arena in m.arena_catalog.arenas: m.extractions[arena.unlock_arena] = 99
			m.select_arena(StringName(args[i].trim_prefix("arena=")))
		else:
			equip.append(StringName(args[i]))
	rng.seed = 42
	_start()

func _start() -> void:
	ended = false
	damage_taken = 0
	arena = null
	change_scene_to_file("res://scenes/run/Arena/Arena.tscn")

func _physics_process(_d: float) -> bool:
	var a = current_scene
	if a == null or a.name != "Arena": return false
	if arena != a:
		arena = a
		var m = root.get_node("MetaProgression")
		m.save_path = "user://bot.cfg"
		for id in equip:
			m.loadout.equip(m.loadout.add(ItemInstance.new(m.catalog.find(id))).uid)
		a.get_node("%Player").begin_run(m.equipped_modifiers())
		a.get_node("%Player").health.damaged.connect(func(n): damage_taken += n)
		root.get_node("RunManager").run_ended.connect(_on_end, CONNECT_ONE_SHOT)
		var ev = a.get_node("%EventDirector")
		ev.event_completed.connect(func(_e): events_won += 1)
		ev.event_failed.connect(func(e): events_lost += 1; pentas_lost += 1 if e.kind == 1 else 0)
		ev.event_completed.connect(func(e): pentas_won += 1 if e.kind == 1 else 0)
	if ended: return false
	var rm = root.get_node("RunManager")
	last_gel = rm.loot.amount_of(&"slime_gel")
	last_core = rm.loot.amount_of(&"slime_core")
	last_loot = rm.loot.to_dictionary()
	last_items.clear()
	for item in rm.loot.items():
		last_items.append("%s/%d" % [item.base.id, item.rarity])
	if rm.elapsed > 600: rm.end_run(0); return false
	if rm.state == 2:  # LEVEL_UP
		var lvl = a.get_node("%LevelUpChoice")
		lvl._on_choice_pressed(BotDriver.choose(a.upgrade_table.pick(a.choices_per_level, rng)))
		return false
	if BotDriver.resolve_menus(a): return false
	BotDriver.drive(a)
	return false

func _on_end(result) -> void:
	ended = true
	var rm = root.get_node("RunManager")
	var gel = last_gel
	var core = last_core
	results.append({"r": "EXT" if result == 1 else "DIE", "t": rm.elapsed, "lv": rm.level, "k": rm.kills, "gel": gel, "core": core, "dmg": damage_taken, "loot": last_loot, "items": last_items.duplicate(), "boss": arena.boss_defeated if is_instance_valid(arena) else false})
	done += 1
	if done >= runs:
		_report()
		quit()
	else:
		_start.call_deferred()

func _report() -> void:
	var ext := 0; var t := 0.0; var k := 0; var gel := 0; var core := 0; var lv := 0; var tdie := []
	for r in results:
		if r.r == "EXT": ext += 1
		else: tdie.append(snappedf(r.t, 1))
		t += r.t; k += r.k; gel += r.gel; core += r.core; lv += r.lv
	var n := float(results.size())
	print("per-run: ", results.map(func(r): return "%s%d/%dk" % [r.r[0], int(r.t), r.k]))
	var per_material := {}
	for r in results:
		for id in r.loot: per_material[id] = per_material.get(id, 0) + r.loot[id]
	for id in per_material: per_material[id] = snappedf(per_material[id] / float(results.size()), 0.1)
	print("eventi superati: %d/%d (pentagrammi %d/%d)" % [events_won, events_won + events_lost, pentas_won, pentas_won + pentas_lost])
	print("boss sconfitti: %d/%d" % [results.filter(func(r): return r.boss).size(), results.size()])
	print("loot medio per run (raccolto, anche se poi perso): ", per_material)
	print("oggetti trovati (base/rarita'): ", results.map(func(r): return r.items))
	print("RUNS=%d extract=%d%% avg_t=%.0fs avg_lv=%.1f avg_kills=%.0f gel/run=%.1f core/run=%.2f death_times=%s" % [n, ext * 100 / n, t / n, lv / n, k / n, gel / n, core / n, tdie])
