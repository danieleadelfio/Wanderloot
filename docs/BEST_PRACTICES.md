# Best Practices — Wanderloot (Godot 4.6)

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

- **Resource condivise sono read-only a runtime.** Un `.tres` caricato è la stessa istanza per tutti: per stato che cambia durante la run (stats potenziate dagli upgrade) lavorare su una copia fatta con `duplicate()` a inizio run.
  - Il proprietario tiene il riferimento al `.tres` base e ricrea le copie a ogni inizio run (`Player.begin_run()`); tutti i modificatori (equip, upgrade) passano da un'unica funzione pura (`StatApplier`), mai `match` sulle stat duplicati in più punti.
- **Pausa**: si usa `get_tree().paused`; la UI che deve funzionare in pausa ha `process_mode = ALWAYS`. La pausa segue lo stato della run: `RunManager` cambia solo stato (nessun accesso alla scena, così resta testabile come logica pura) e la composition root applica `paused` reagendo a `state_changed`.

- **Persistenza**: solo `MetaProgression` legge/scrive su disco, in `user://` con `ConfigFile` e chiave `version` per future migrazioni. Ogni cambio di formato alza `SAVE_VERSION`, resta compatibile con le versioni precedenti (sezioni mancanti = default) e ha un test che carica un file della versione vecchia. Sul disco si salvano id, mai Resource: al caricamento si risolvono via catalogo (`EquipmentCatalog`) e gli id sconosciuti si scartano. Mai caricare `.tres`/`.res` da `user://` (possono contenere script eseguibili). Logica di inventario in classi pure (`MetaInventory`) separate dall'I/O, così si testano senza file.

## 3.1 Componenti di combattimento

- `Health` (HP + segnali `changed`/`damaged`/`died`, nessuna logica di morte), `Hitbox` (infligge danno), `Hurtbox` (riceve danno, inoltra a `Health`, i-frames opzionali), `HitFlash`, `Weapon` (cooldown + segnale `fired`, non istanzia proiettili).
- `Knockback` (spinta, il corpo chiama `step()` e somma `velocity`), `HitStop` (unico punto che tocca `Engine.time_scale`, ripristino garantito in `_exit_tree`), `Blink` (i-frames visibili). Segnali `Hurtbox.knocked(impulse)` e `invulnerable_changed(active)`.
- Rilevazione unidirezionale: l'`Hurtbox` è `monitoring` (mask sul layer di attacco avversario), l'`Hitbox` è solo `monitorable`. Nessun doppio conteggio.
- Riferimenti tra componenti della stessa scena: `@export` con NodePath impostato nella scena, o `%UniqueName`.
- **Composition root**: la scena di livello (es. `Arena`) collega i segnali tra entità, pool, HUD e autoload. Le entità non si conoscono tra loro.

## 3.1.1 Audio

- Suoni sempre per id tramite `SfxPlayer.play(&"id")` e `SoundBank` (`.tres`): mai `AudioStreamPlayer` sparsi con stream hardcoded. Un id nuovo va aggiunto al banco e alla lista del test `tests/audio/test_sound_bank.gd`.
- Collegamento via segnali nella composition root (`Arena`, `Hub`), mai chiamate audio dalle entità.
- Bus: `Music`, `SFX` (Master sopra). Asset sorgente riproducibili: `tools/audio.py`.

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
- Attivo da M2. Addon vendored in `addons/gdUnit4` (v6.2.1, plugin abilitato); report in `reports/` (ignorato da git).
- Logica da testare = classi pure o autoload senza accesso alla scena (`RunManager`, `MetaInventory`, `LootTransfer`…): si istanziano direttamente nel test con `auto_free(preload(...).new())`. Dipendenze esterne (salvataggio, depositi) si iniettano (`Callable`, `save_path` di test), mai usare il file di salvataggio reale.
- Esecuzione: dal pannello GdUnit4 dell'editor, oppure da terminale nella root del progetto:
  `addons/gdUnit4/runtest.sh --godot_binary "/Applications/Godot.app/Contents/MacOS/Godot" -a res://tests`
- Headless (CI/VM senza display, dove `runtest.sh` si ferma): `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests`. Adatto alla logica pura; i test con input/UI vanno lanciati con display.
- Scene semplici (es. `Player`) si testano istanziandole con `add_child(auto_free(scene.instantiate()))`, senza scene runner, quando basta verificarne lo stato.
- Regola: una feature che tocca loot/estrazione/progressione non si committa con test rossi.

## 5. Versionamento e workflow

- Repo git locale (inizializzato). Un commit per unità di lavoro coerente, messaggio in stile convenzionale (`feat:`, `fix:`, `chore:`, `docs:`, `test:`).
- Ogni commit che cambia feature/scope/gameplay: aggiornare `docs/GDD.md` (sezione toccata) e aggiungere voce in `docs/CHANGELOG.md` nello stesso commit — non a posteriori.
- Task tracking: GitHub Issues + Projects su `danieleadelfio/Wanderloot`, una milestone per ogni M del GDD. Nessun sistema duplicato.
- Referenziare la issue nel messaggio di commit (`feat: enemy pool (#1)`, `Closes #1` per chiuderla col push).

## 6. Regola generale

Prima di introdurre un pattern nuovo, chiedersi: è più semplice del pattern esistente? Evita duplicazione? È mantenibile senza documentazione aggiuntiva? Se la risposta a una delle tre è no, non introdurlo.
