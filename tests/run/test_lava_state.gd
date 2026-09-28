extends GdUnitTestSuite
## Pavimento di lava (M13, #86): fasi, zone prima poche e grandi poi tante e piccole.

const EVENT: RunEventData = preload("res://data/events/lava_floor.tres")


func test_first_phase_few_big_last_phase_many_small() -> void:
	var last := EVENT.lava_phase_count - 1
	assert_int(LavaState.zone_count(EVENT, 0)).is_equal(EVENT.lava_zones_first)
	assert_int(LavaState.zone_count(EVENT, last)).is_equal(EVENT.lava_zones_last)
	assert_float(LavaState.zone_size(EVENT, 0)).is_equal(EVENT.lava_size_first)
	assert_float(LavaState.zone_size(EVENT, last)).is_equal(EVENT.lava_size_last)
	for phase in range(1, EVENT.lava_phase_count):
		assert_int(LavaState.zone_count(EVENT, phase)).is_greater_equal(LavaState.zone_count(EVENT, phase - 1))
		assert_float(LavaState.zone_size(EVENT, phase)).is_less(LavaState.zone_size(EVENT, phase - 1))


func test_phases_split_the_duration() -> void:
	var step := LavaState.phase_duration(EVENT)
	assert_float(step * EVENT.lava_phase_count).is_equal_approx(EVENT.duration, 0.001)
	assert_int(LavaState.phase_at(EVENT, 0.0)).is_equal(0)
	assert_int(LavaState.phase_at(EVENT, step * 1.5)).is_equal(1)
	assert_int(LavaState.phase_at(EVENT, EVENT.duration + 5.0)).is_equal(EVENT.lava_phase_count)


## La lava di una fase si spegne prima che parta la successiva.
func test_zone_fits_in_its_phase() -> void:
	assert_float(EVENT.lava_warning + EVENT.lava_active_time).is_less_equal(LavaState.phase_duration(EVENT))


## Stesso danno del veleno dei proiettili tossici.
func test_lava_damage_matches_poison() -> void:
	var toxic: WeaponData = load("res://data/weapons/toxic_glob.tres")
	assert_int(EVENT.lava_damage).is_equal(toxic.poison_damage)
	assert_float(EVENT.lava_interval).is_equal(toxic.poison_interval)


## Primo danno anticipato: entrando e uscendo di continuo non si evita la lava.
func test_poison_state_first_tick_override() -> void:
	var state := PoisonState.new()
	state.apply(0.2, 1.5, 100, 0.25)
	assert_int(state.tick(0.1)).is_equal(0)
	state.apply(0.2, 1.5, 100, 0.25)
	assert_int(state.tick(0.16)).is_equal(100)
