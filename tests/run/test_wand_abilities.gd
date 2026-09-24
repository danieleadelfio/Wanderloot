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
