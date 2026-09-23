# Best Practices — FirstAiGame (Godot 4.6)

Linee guida vincolanti per lo sviluppo di questo progetto. Aggiornare questo file solo se si trova un metodo oggettivamente migliore (più semplice, non duplicato, più mantenibile), non per preferenza estetica.

## 1. Struttura cartelle

```
res://
  scenes/<dominio>/<NomeScena>/   # una cartella per scena complessa, script+scena+asset locali insieme
  scripts/<dominio>/              # script condivisi/non legati a una scena singola
  scripts/data/                   # classi Resource (class_name WeaponData, EnemyData, ...)
  data/                            # istanze Resource (.tres) per armi, nemici, upgrade, ricette — mai hardcoded in script
  assets/{sprites,tiles,audio}/
  autoload/                       # singleton globali (vedi §3)
  tests/                          # test GdUnit4, rispecchia la struttura di scripts/
docs/
  GDD.md
  CHANGELOG.md
  BEST_PRACTICES.md
```

Regola: se una scena ha script/asset esclusivamente suoi, stanno nella stessa cartella della scena. Se sono condivisi da più scene, vanno in `scripts/`/`assets/` generici.

## 2. GDScript style (standard ufficiale Godot)

- Indentazione: tab, non spazi.
- `snake_case` per variabili, funzioni, file e nodi; `PascalCase` per classi/`class_name`; `CONSTANT_CASE` per costanti ed enum values.
- Tipizzazione statica sempre: `var hp: int = 10`, `func take_damage(amount: int) -> void:`. Previene una classe intera di bug a runtime ed è richiesta in questo progetto, non opzionale.
- Ordine dentro un file: `@tool`, `class_name`, `extends`, docstring, `signal`, `enum`, `const`, `@export var`, altre `var` pubbliche, `var _private` (prefisso `_`), `@onready var`, `_init`/metodi virtuali (`_ready`, `_process`...), metodi pubblici, metodi privati.
- Un solo `class_name` pubblico per file quando serve essere referenziato altrove; altrimenti nodo/scena senza `class_name` se uso puramente locale.
- Gli script autoload non hanno `class_name` (conflitto col nome del singleton).
- Evitare nomi che oscurano funzioni built-in (es. `exp` → usare `experience`).

## 3. Architettura: pattern obbligatori

- **Autoload/singleton solo per stato davvero globale**: `RunManager` (stato della run corrente) e `MetaProgression` (persistente). Niente altri autoload senza motivo forte — ogni autoload in più è uno stato globale nascosto, difficile da testare.
- **Segnali per comunicazione, non riferimenti diretti tra nodi non imparentati.** Un nemico che muore emette `died`, non chiama direttamente `RunManager.add_loot(...)` in giro per la scena se può essere disaccoppiato con un segnale ascoltato dal manager.
- **Composizione su ereditarietà profonda**: preferire componenti riusabili (`Hitbox`, `Hurtbox`, `Health`, `ProjectilePool` come nodi/script componibili) piuttosto che alberi di ereditarietà `Enemy -> RangedEnemy -> EliteRangedEnemy`. Più facile da estendere senza duplicare codice.
- **Dati fuori dal codice**: armi, nemici, upgrade, ricette come `Resource` custom (`.tres`), mai liste hardcoded in GDScript. Bilanciare il gioco deve significare modificare dati, non ricompilare logica.
- **Unique nodes (`%NodeName`)** invece di `get_node("../../UI/Label")`: i percorsi lunghi si rompono al primo refactor.
- **Object pooling** per proiettili e nemici comuni (arena a ondate): niente `instantiate()`/`queue_free()` ad ogni colpo.
  - API standard di un oggetto poolable: `activate(...)` / `deactivate()`, mai `queue_free()`. Il ritorno al pool avviene via segnale (`expired(obj)`), non con riferimento diretto al pool.
  - In activate/deactivate: `visible`, `set_physics_process` e toggle di `monitoring`/`monitorable`/`disabled` sempre con `set_deferred` (si è spesso dentro un callback fisico).

## 3.1 Componenti di combattimento

- `Health` (HP + segnali `changed`/`damaged`/`died`, nessuna logica di morte), `Hitbox` (infligge danno), `Hurtbox` (riceve danno, inoltra a `Health`, i-frames opzionali), `HitFlash`, `Weapon` (cooldown + segnale `fired`, non istanzia proiettili).
- Rilevazione unidirezionale: l'`Hurtbox` è `monitoring` (mask sul layer di attacco avversario), l'`Hitbox` è solo `monitorable`. Nessun doppio conteggio.
- Riferimenti tra componenti della stessa scena: `@export` con NodePath impostato nella scena, o `%UniqueName`.
- **Composition root**: la scena di livello (es. `Arena`) collega i segnali tra entità, pool, HUD e autoload. Le entità non si conoscono tra loro.

## 3.2 Collision layers (vincolanti)

| Layer | Nome | Chi ci sta |
|---|---|---|
| 1 | world | muri/ostacoli |
| 2 | player | corpo player |
| 3 | enemy | corpi nemici |
| 4 | player_attack | Hitbox dei proiettili del player |
| 5 | enemy_attack | Hitbox nemiche (contatto/proiettili) |

Hurtbox: `collision_layer = 0`, mask sul layer di attacco avversario. Nuovi layer vanno aggiunti qui e nei Project Settings.

## 4. Testing

Framework scelto: **GdUnit4** (attivamente mantenuto, nativo per Godot 4, scene runner per testare input/interazioni, mocking integrato, GitHub Action ufficiale per CI). Preferito a GUT, più datato e con integrazione CI meno diretta.

- Unit test per logica pura e testabile in isolamento: calcolo danno, curve exp/livello, drop rate, ricette di crafting, transizione loot run→meta. Questa è la parte con più valore/costo per un dev backend: stessa disciplina che già usi su ExplikAI.
- Scene test (via scene runner) solo per flussi critici end-to-end: level-up → scelta upgrade, morte → azzeramento loot run, estrazione riuscita → trasferimento loot a meta.
- Non testare rendering/asset grafici: tempo perso, valore basso.
- I test vivono in `tests/`, uno a uno con lo script sotto test (`scripts/run/run_manager.gd` → `tests/run/test_run_manager.gd`).
- Verrà introdotto quando si arriva a M2 (loot/estrazione) del GDD: prima di allora la logica è troppo instabile perché valga la pena, dopo diventa la rete di sicurezza per non rompere la regola "morte = perdita loot" mentre si aggiungono feature.

## 5. Versionamento e workflow

- Repo git locale (inizializzato). Un commit per unità di lavoro coerente, messaggio in stile convenzionale (`feat:`, `fix:`, `chore:`, `docs:`, `test:`).
- Ogni commit che cambia feature/scope/gameplay: aggiornare `docs/GDD.md` (sezione toccata) e aggiungere voce in `docs/CHANGELOG.md` nello stesso commit — non a posteriori.
- Task tracking: GitHub Issues + Projects una volta collegato il remote (nessun sistema duplicato nel frattempo — vedi `docs/GDD.md` §11 per lo stato del remote).

## 6. Regola generale

Prima di introdurre un pattern nuovo, chiedersi: è più semplice del pattern esistente? Evita duplicazione? È mantenibile senza documentazione aggiuntiva? Se la risposta a una delle tre è no, non introdurlo.
