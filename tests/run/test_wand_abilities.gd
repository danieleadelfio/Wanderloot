extends GdUnitTestSuite
## Abilita' della bacchetta (M10): criteri di attivazione, slot, scelta dal catalogo, barriera.


func _ability(id: StringName, trigger: WandAbility.Trigger) -> WandAbility:
	var ability := WandAbility.new()
	ability.id = id
	ability.trigger = trigger
	ability.every_shots = 3
	ability.every_distance = 100.0
	ability.cooldown = 2.0
	return ability


func test_shots_trigger() -> void:
	var trigger := AbilityTrigger.new(_ability(&"a", WandAbility.Trigger.SHOTS))
	assert_int(trigger.on_shot() + trigger.on_shot()).is_equal(0)
	assert_int(trigger.on_shot()).is_equal(1)
	assert_int(trigger.on_moved(500.0) + trigger.tick(10.0)).is_equal(0)


func test_distance_trigger_counts_multiple() -> void:
	var trigger := AbilityTrigger.new(_ability(&"a", WandAbility.Trigger.DISTANCE))
	assert_int(trigger.on_moved(60.0)).is_equal(0)
	assert_int(trigger.on_moved(260.0)).is_equal(3)
	assert_float(trigger.progress()).is_equal_approx(0.2, 0.001)


func test_cooldown_trigger_and_hold() -> void:
	var trigger := AbilityTrigger.new(_ability(&"a", WandAbility.Trigger.COOLDOWN))
	assert_int(trigger.tick(1.5)).is_equal(0)
	assert_int(trigger.tick(5.0, true)).is_equal(0)
	assert_int(trigger.tick(0.6)).is_equal(1)
	assert_int(trigger.tick(0.1)).is_equal(0)


func test_cooldown_by_level() -> void:
	# M12 #86 #18: cooldown per-livello (es. Barriera arcana, piatto poi in calo).
	var ability := _ability(&"a", WandAbility.Trigger.COOLDOWN)
	ability.cooldown_by_level = [12.0, 12.0, 12.0, 12.0, 10.0, 8.0, 6.0, 6.0]
	assert_float(ability.cooldown_for_level(1)).is_equal_approx(12.0, 0.001)
	assert_float(ability.cooldown_for_level(5)).is_equal_approx(10.0, 0.001)
	assert_float(ability.cooldown_for_level(8)).is_equal_approx(6.0, 0.001)
	assert_float(ability.cooldown_for_level(99)).is_equal_approx(6.0, 0.001)
	# Vuoto: usa sempre il cooldown piatto.
	assert_float(_ability(&"b", WandAbility.Trigger.COOLDOWN).cooldown_for_level(5)).is_equal_approx(2.0, 0.001)
	var trigger := AbilityTrigger.new(ability)
	assert_int(trigger.tick(9.9, false, 5)).is_equal(0)
	assert_int(trigger.tick(0.2, false, 5)).is_equal(1)


func test_level_up_respects_unlocked_cap_and_signals_overflow() -> void:
	# M12 #86 #20: senza Ascensione il cap sbloccato e' Lv1, l'eccedenza va in over_cap.
	var player: Player = auto_free(load("res://scenes/run/Player/Player.tscn").instantiate())
	add_child(player)
	var slots := AbilitySlots.new(2)
	var a := _ability(&"a", WandAbility.Trigger.SHOTS)
	slots.add(a)
	var wand: WandAbilities = auto_free(WandAbilities.new())
	add_child(wand)
	wand.player = player
	wand.slots = slots
	wand.levels[&"a"] = 1
	var overflow_events: Array = []
	wand.over_cap.connect(func(ability: WandAbility, overflow: int) -> void: overflow_events.append([ability, overflow]))
	wand.level_up(&"a", 3)
	assert_int(wand.levels[&"a"]).is_equal(1)
	assert_int(overflow_events.size()).is_equal(1)
	assert_int(overflow_events[0][1]).is_equal(3)
	wand.caps[&"a"] = 5
	overflow_events.clear()
	wand.level_up(&"a", 2)
	assert_int(wand.levels[&"a"]).is_equal(3)
	assert_int(overflow_events.size()).is_equal(0)
	wand.level_up(&"a", 10)
	assert_int(wand.levels[&"a"]).is_equal(5)
	assert_int(overflow_events[0][1]).is_equal(8)


func test_projectile_tint_follows_last_taken_ability() -> void:
	# M12 #86 #15: colore dell'ultima abilita' presa/salita, non piu' la media (si sbiadiva con 2+).
	var player: Player = auto_free(load("res://scenes/run/Player/Player.tscn").instantiate())
	add_child(player)
	var wand: WandAbilities = auto_free(WandAbilities.new())
	add_child(wand)
	wand.player = player
	var red := _ability(&"red", WandAbility.Trigger.SHOTS)
	red.projectile_tint = Color(1, 0, 0)
	var blue := _ability(&"blue", WandAbility.Trigger.SHOTS)
	blue.projectile_tint = Color(0, 0, 1)
	wand.caps[&"red"] = WandAbility.MAX_LEVEL
	wand.caps[&"blue"] = WandAbility.MAX_LEVEL
	assert_bool(wand.equip(red)).is_true()
	assert_object(player.weapon_data().projectile_tint).is_equal(Color(1, 0, 0))
	assert_bool(wand.equip(blue)).is_true()
	assert_object(player.weapon_data().projectile_tint).is_equal(Color(0, 0, 1))
	# Ri-prendere red (sale di livello) lo rende di nuovo l'ultima presa.
	assert_bool(wand.equip(red)).is_true()
	assert_object(player.weapon_data().projectile_tint).is_equal(Color(1, 0, 0))


func test_slots_add_replace_and_tint() -> void:
	var slots := AbilitySlots.new(2)
	var a := _ability(&"a", WandAbility.Trigger.SHOTS)
	a.projectile_tint = Color(1, 0, 0)
	var b := _ability(&"b", WandAbility.Trigger.SHOTS)
	b.projectile_tint = Color(0, 0, 1)
	assert_bool(slots.add(a)).is_true()
	assert_bool(slots.add(a)).is_false()
	assert_bool(slots.add(b)).is_true()
	assert_bool(slots.is_full()).is_true()
	assert_bool(slots.add(_ability(&"c", WandAbility.Trigger.SHOTS))).is_false()
	assert_object(slots.tint()).is_equal(Color(0.5, 0, 0.5))
	var removed := slots.replace(0, _ability(&"c", WandAbility.Trigger.SHOTS))
	assert_str(String(removed.id)).is_equal("a")
	assert_array(slots.ids()).is_equal([&"c", &"b"])


func test_catalog_pick_excludes_owned() -> void:
	var catalog := AbilityCatalog.new()
	catalog.abilities = [_ability(&"a", 0), _ability(&"b", 0), _ability(&"c", 0)] as Array[WandAbility]
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var picked := catalog.pick(3, [&"b"] as Array[StringName], rng)
	assert_int(picked.size()).is_equal(2)
	for ability in picked:
		assert_str(String(ability.id)).is_not_equal("b")


func test_same_ability_levels_up_instead_of_duplicating() -> void:
	var player: Player = auto_free(load("res://scenes/run/Player/Player.tscn").instantiate())
	add_child(player)
	var wand: WandAbilities = auto_free(WandAbilities.new())
	add_child(wand)
	wand.player = player
	var lightning: WandAbility = load("res://data/abilities/wandering_lightning.tres")
	var ring: WandAbility = load("res://data/abilities/arcane_ring.tres")
	# Cap sbloccato alto: qui si testa l'accumulo dei livelli, non il cap (#20, vedi test dedicato sopra).
	wand.caps[lightning.id] = WandAbility.MAX_LEVEL
	wand.caps[ring.id] = WandAbility.MAX_LEVEL
	wand.equip_bonus(lightning, 2)
	wand.equip_bonus(lightning, 1)
	assert_int(wand.level_of(lightning)).is_equal(3)
	assert_bool(wand.equip(lightning)).is_true()
	assert_int(wand.level_of(lightning)).is_equal(4)
	assert_int(wand.slots.abilities.size()).is_equal(0)
	assert_int(wand.all_abilities().size()).is_equal(1)
	assert_bool(wand.equip(ring)).is_true()
	assert_int(wand.level_of(ring)).is_equal(1)
	assert_int(wand.slots.abilities.size()).is_equal(1)


func test_legendary_items_carry_level_two() -> void:
	var rarities: RarityTable = load("res://data/equipment/rarity_table.tres")
	var item := ItemInstance.new(load("res://data/equipment/gel_ring.tres"), 4)
	item.ability = load("res://data/abilities/wandering_lightning.tres")
	assert_int(item.ability_level(rarities)).is_equal(2)
	item.rarity = 3
	assert_int(item.ability_level(rarities)).is_equal(1)


func test_real_catalog_has_three_abilities_with_translated_texts() -> void:
	var catalog: AbilityCatalog = load("res://data/abilities/ability_catalog.tres")
	assert_int(catalog.abilities.size()).is_equal(3)
	for ability in catalog.abilities:
		assert_object(ability.effect).is_not_null()
		assert_object(ability.icon).is_not_null()
		assert_str(ability.trigger_text()).is_not_empty()


func test_hurtbox_shield_absorbs_one_hit() -> void:
	var health: Health = auto_free(Health.new())
	health.reset(5)
	var hurtbox: Hurtbox = auto_free(Hurtbox.new())
	hurtbox.health = health
	var hitbox: Hitbox = auto_free(Hitbox.new())
	hitbox.damage = 2
	hurtbox.shield_charges = 1
	hurtbox._try_hit(hitbox)
	assert_int(health.current).is_equal(5)
	assert_int(hurtbox.shield_charges).is_equal(0)
	hurtbox._try_hit(hitbox)
	assert_int(health.current).is_equal(3)
