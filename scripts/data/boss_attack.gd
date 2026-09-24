class_name BossAttack
extends Resource
## Un attacco del moveset di un boss (dati): tipo, preavviso, proiettili, salto, recupero, peso nella scelta.
## Nuovi tipi solo in coda all'enum (valore salvato nei .tres).

enum Kind { AIMED_FAN, RING, LEAP_SLAM }

@export var display_name: String = ""
@export var kind: Kind = Kind.AIMED_FAN
## Peso relativo nella scelta tra gli attacchi disponibili nella fase corrente.
@export var weight: float = 1.0
## Fase minima (1 = sempre, 2 = solo sotto la soglia di HP del boss).
@export_range(1, 2) var min_phase: int = 1
## Secondi di preavviso prima del colpo (cerchio o carica attorno al boss): il tempo per scappare.
@export var telegraph_time: float = 0.8
## Pausa dopo l'attacco, in cui il boss si muove lentamente (finestra per colpirlo).
@export var recovery: float = 1.0

@export_group("Proiettili")
## Arma dei proiettili (danno, velocita', durata, texture). Vuota = nessun proiettile.
@export var projectile: WeaponData
@export var projectile_count: int = 5
## Apertura del ventaglio (AIMED_FAN).
@export var spread_degrees: float = 50.0
@export var repeats: int = 1
@export var repeat_interval: float = 0.3
## Rotazione dell'anello a ogni ripetizione (RING), per non lasciare sempre gli stessi varchi.
@export var ring_rotation_degrees: float = 0.0

@export_group("Salto")
## Raggio del cerchio di impatto (LEAP_SLAM).
@export var radius: float = 130.0
@export var damage: int = 2
@export var knockback: float = 600.0
@export var leap_time: float = 0.45
@export var leap_height: float = 90.0


## Indice dell'attacco scelto per peso tra quelli ammessi nella fase; -1 se nessuno.
static func pick_index(attacks: Array[BossAttack], phase: int, rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for attack in attacks:
		if attack.min_phase <= phase:
			total += maxf(attack.weight, 0.0)
	if total <= 0.0:
		return -1
	var roll := rng.randf() * total
	for i in attacks.size():
		if attacks[i].min_phase > phase:
			continue
		roll -= maxf(attacks[i].weight, 0.0)
		if roll <= 0.0:
			return i
	for i in range(attacks.size() - 1, -1, -1):
		if attacks[i].min_phase <= phase:
			return i
	return -1
