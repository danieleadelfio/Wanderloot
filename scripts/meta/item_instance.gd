class_name ItemInstance
extends RefCounted
## Un oggetto posseduto (M11): istanza unica di un oggetto base (EquipmentData) con rarita' e bonus tirati.
## Si possono avere piu' istanze dello stesso oggetto base. Si salva come dizionario in MetaProgression.

## Identificativo unico nel salvataggio (assegnato da EquipmentLoadout.add).
var uid: int = 0
var base: EquipmentData
## Indice della rarita' nella RarityTable (0 = Comune).
var rarity: int = 0
## Bonus tirati al craft/drop, oltre ai modificatori fissi dell'oggetto base.
var affixes: Array[StatModifier] = []
## Modificatore di gameplay (da Super raro in su): abilita' della bacchetta attiva per tutta la run.
var ability: WandAbility


func _init(from_base: EquipmentData = null, tier: int = 0) -> void:
	base = from_base
	rarity = tier


## Livello dell'abilita' incorporata secondo la rarita' (0 senza abilita').
func ability_level(rarities: RarityTable) -> int:
	return rarities.tier(rarity).ability_level if ability else 0


func slot() -> EquipmentData.Slot:
	return base.slot


## Tutti i modificatori applicati a inizio run: quelli dell'oggetto base + i bonus tirati.
func modifiers() -> Array[StatModifier]:
	var result: Array[StatModifier] = []
	result.append_array(base.modifiers)
	result.append_array(affixes)
	return result


## Stesso oggetto base e stessa rarita' (condizione per la fusione).
func same_kind(other: ItemInstance) -> bool:
	return other != null and other.base == base and other.rarity == rarity


func to_dict() -> Dictionary:
	var rolled: Array = []
	for affix in affixes:
		rolled.append([int(affix.stat), affix.amount, affix.is_multiplier])
	return {"base": String(base.id), "rarity": rarity, "affixes": rolled, "ability": String(ability.id) if ability else ""}


## null se l'oggetto base non esiste piu' nel catalogo (salvataggio di una versione vecchia).
static func from_dict(data: Dictionary, catalog: EquipmentCatalog, abilities: AbilityCatalog) -> ItemInstance:
	var found := catalog.find(StringName(data.get("base", "")))
	if found == null:
		return null
	var item := ItemInstance.new(found, int(data.get("rarity", 0)))
	for entry in data.get("affixes", []):
		var affix := StatModifier.new()
		affix.stat = int(entry[0])
		affix.amount = float(entry[1])
		affix.is_multiplier = bool(entry[2])
		item.affixes.append(affix)
	var ability_id := StringName(data.get("ability", ""))
	if ability_id != &"" and abilities:
		for candidate in abilities.abilities:
			if candidate.id == ability_id:
				item.ability = candidate
	return item
