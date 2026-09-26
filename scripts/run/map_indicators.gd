class_name MapIndicators
extends RefCounted
## Indicatori piazzabili dalla mappa (tasto M, M13 #86): fino a MAX_INDICATORS, ognuno con uno dei
## colori di COLORS assegnato in ordine di aggiunta. Mai giallo: riservato alla freccia del portale
## di estrazione (ExtractionIndicator.COLOR). Logica pura, senza dipendenze da nodi: testata.

const MAX_INDICATORS: int = 5
const COLORS: Array[Color] = [
	Color(0.85, 0.2, 0.2),    # rosso
	Color(0.25, 0.55, 0.95),  # blu
	Color(0.3, 0.85, 0.35),   # verde
	Color(0.85, 0.35, 0.85),  # magenta
	Color(0.95, 0.55, 0.15),  # arancione
]

var _points: Array[Vector2] = []


## Aggiunge un punto se c'e' ancora posto; false se gia' a MAX_INDICATORS.
func add(point: Vector2) -> bool:
	if is_full():
		return false
	_points.append(point)
	return true


func remove_at(index: int) -> void:
	if index >= 0 and index < _points.size():
		_points.remove_at(index)


func clear() -> void:
	_points.clear()


func points() -> Array[Vector2]:
	return _points.duplicate()


func color_for(index: int) -> Color:
	return COLORS[index % COLORS.size()]


func size() -> int:
	return _points.size()


func is_full() -> bool:
	return _points.size() >= MAX_INDICATORS
