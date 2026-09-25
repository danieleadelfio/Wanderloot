class_name ArenaLevel
extends RefCounted
## Potenza dell'equip -> livello arena (M12, #86). Logica pura: chi chiama passa gli item equipaggiati
## e ottiene i moltiplicatori da applicare. Si compone con overtime (moltiplicativo su vita/ritmo) e col
## Pentagramma di sangue (additivo sui boss), nessuno dei due sovrascrive l'altro.
##
## Formula (letterale, decisa dal proprietario): livello = tier piu' alto T (1=Comune..6=Mitico) per cui
## si hanno >= REQUIRED_COUNT pezzi equipaggiati di tier >= T, il massimo T soddisfatto; nessuna soglia
## soddisfatta = livello 1. Il gioco definisce effetti (vita nemici, ritmo di spawn, boss, drop) solo per
## i livelli 1-5 (il Mitico non si trova mai in run e 4 pezzi Mitici equipaggiati sono comunque fuori
## scope pratico): livello grezzo oltre 5 e' comunque calcolabile dalla formula ma va sempre attraverso
## level_for()/i clamp qui sotto prima di scalare qualunque cosa.

const MAX_LEVEL: int = 5
const REQUIRED_COUNT: int = 4
## Rarita' massima droppabile (indice RarityTable) per livello: livello 1 -> solo Comune (0),
## livello 5 -> fino a Leggendario (4). Il Mitico (5) non e' mai in questa lista: non droppa mai in run.
const _MAX_DROP_TIER_BY_LEVEL: Array[int] = [0, 0, 1, 2, 3, 4]  # indice 0 inutilizzato (livelli partono da 1)


## Livello grezzo dalla formula, non clampato: puo' superare MAX_LEVEL con equip estremo (Leggendario/Mitico).
static func raw_level(equipped: Array[ItemInstance]) -> int:
	var counts_by_rarity: Array[int] = [0, 0, 0, 0, 0, 0]
	for item in equipped:
		if item == null:
			continue
		counts_by_rarity[clampi(item.rarity, 0, counts_by_rarity.size() - 1)] += 1
	var best_t := 0
	for t in range(1, counts_by_rarity.size() + 1):
		var count := 0
		for r in range(t - 1, counts_by_rarity.size()):
			count += counts_by_rarity[r]
		if count >= REQUIRED_COUNT:
			best_t = t
	return best_t + 1


## Livello effettivo da usare per lo scaling: raw_level() clampato a [1, MAX_LEVEL].
static func level_for(equipped: Array[ItemInstance]) -> int:
	return clampi(raw_level(equipped), 1, MAX_LEVEL)


## Vita dei nemici nuovi: x1,5 per ogni livello sopra il primo. Si moltiplica con l'hp_multiplier()
## dell'overtime (indipendenti: livello 3 + overtime x2 = x2,25 * overtime_hp).
static func enemy_hp_multiplier(level: int) -> float:
	return pow(1.5, clampi(level, 1, MAX_LEVEL) - 1)


## Ritmo di spawn: +10% per ogni livello sopra il primo. Si moltiplica con lo spawn_rate_multiplier()
## dell'overtime allo stesso modo dell'hp.
static func spawn_rate_multiplier(level: int) -> float:
	return 1.0 + 0.1 * (clampi(level, 1, MAX_LEVEL) - 1)


## Boss in piu' per ogni livello sopra il primo: si somma a boss_count dell'arena e ai boss guadagnati
## dal Pentagramma di sangue (_extra_bosses), nessuno dei due sostituisce l'altro.
static func boss_bonus(level: int) -> int:
	return clampi(level, 1, MAX_LEVEL) - 1


## Rarita' massima droppabile per questo livello, mai oltre il tetto della tabella drop dell'arena
## (arena_max_tier): un'arena puo' scegliere di non arrivare mai a Leggendario anche a livello 5.
static func max_drop_tier(level: int, arena_max_tier: int) -> int:
	return mini(arena_max_tier, _MAX_DROP_TIER_BY_LEVEL[clampi(level, 1, MAX_LEVEL)])
