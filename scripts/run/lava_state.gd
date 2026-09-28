class_name LavaState
extends RefCounted
## Pavimento di lava (M13, #86), logica pura: fasi dell'evento, numero e lato delle zone per fase.
## Prima fase: poche zone grandi; ultima: tante piccole (interpolazione lineare).


## Fase in corso dopo `elapsed` secondi (0..phase_count-1; phase_count = evento finito).
static func phase_at(event: RunEventData, elapsed: float) -> int:
	var count := maxi(event.lava_phase_count, 1)
	return mini(floori(elapsed / phase_duration(event)), count)


static func phase_duration(event: RunEventData) -> float:
	return event.duration / maxi(event.lava_phase_count, 1)


static func _t(event: RunEventData, phase: int) -> float:
	var count := maxi(event.lava_phase_count, 1)
	return 0.0 if count == 1 else clampf(float(phase) / (count - 1), 0.0, 1.0)


static func zone_count(event: RunEventData, phase: int) -> int:
	return roundi(lerpf(event.lava_zones_first, event.lava_zones_last, _t(event, phase)))


static func zone_size(event: RunEventData, phase: int) -> float:
	return lerpf(event.lava_size_first, event.lava_size_last, _t(event, phase))
