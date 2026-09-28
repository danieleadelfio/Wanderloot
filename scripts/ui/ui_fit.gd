class_name UiFit
extends RefCounted
## Adatta una finestra UI allo schermo (M13, #86): la rimpicciolisce attorno al centro dello schermo se il
## suo pannello (il contenuto) eccede una frazione del viewport. Condiviso da finestra Inventario dell'hub e
## inventario di run, prima con due copie della stessa logica.
##
## Due regole imparate a caro prezzo (bug "la finestra cambia dimensione a ogni equip"):
## - si misura su get_combined_minimum_size() del pannello, non sulla sua size (che puo' restare gonfia);
## - si scala la finestra a schermo intero che lo contiene (CenterContainer, non gestita da un container),
##   mai il pannello: Container.fit_child_in_rect() riporta a 1 la scala dei figli a ogni riordino, quindi
##   ogni refresh del contenuto faceva tornare il pannello a grandezza piena per un frame.


## Fattore di scala (<= 1) perche' content entri in available. Contenuto non ancora misurato = 1.
static func scale_factor(content: Vector2, available: Vector2) -> float:
	if content.x <= 0.0 or content.y <= 0.0:
		return 1.0
	return minf(1.0, minf(available.x / content.x, available.y / content.y))


## window: Control a schermo intero che centra panel; viewport_size: area visibile.
static func fit(window: Control, panel: Control, viewport_size: Vector2, fraction: float) -> void:
	# Centro dello schermo, non window.size * 0.5 (M13, #86): se per un frame il pannello e' piu' alto dello
	# schermo il CenterContainer si allunga, e un pivot preso da li' spostava la finestra fuori schermo.
	window.pivot_offset = viewport_size * 0.5
	window.scale = Vector2.ONE * scale_factor(panel.get_combined_minimum_size(), viewport_size * fraction)
