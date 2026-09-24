# Best Practices — Wanderloot (Godot 4.6)

Linee guida vincolanti per lo sviluppo di questo progetto. Aggiornare questo file solo se si trova un metodo oggettivamente migliore (più semplice, non duplicato, più mantenibile), non per preferenza estetica.

## 1. Struttura cartelle

```
res://
  scenes/<dominio>/<NomeScena>/   # una cartella per scena complessa, script+scena+asset locali insieme
  scripts/<dominio>/              # script condivisi/non legati a una scena singola
  scripts/data/                   # classi Resource (class_name WeaponData, EnemyData, ...)
  data/                            # istanze Resource (.tres) per armi, nemici, upgrade, ricette — mai hardcoded in script
  assets/{art,sprites,audio}/     # SVG sorgenti, PNG a 2x, WAV
  tools/                          # generatori di asset (Python) e bot di playtest (GDScript)
  autoload/                       # singleton globali (vedi §3)
  tests/                          # test GdUnit4, rispecchia la struttura di scripts/
docs/
  GDD.md
  CHANGELOG.md
  BEST_PRACTICES.md
  GUIDA_CONTENUTI.md             # procedure operative: nuovi nemici, arene, personaggi, equip, suoni
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
- **Più fonti di pausa**: `get_tree().paused` lo scrive solo la composition root, combinando le fonti (stato della run, pause del giocatore) in un unico `_refresh_pause()`. Nessun altro nodo lo imposta direttamente.
- **Chiamate differite (`call_deferred`) e `await`**: al rientro il nodo può essere uscito dall'albero (cambio scena). Controllare `is_inside_tree()` prima di usare viewport/tree.
- **Pausa**: si usa `get_tree().paused`; la UI che deve funzionare in pausa ha `process_mode = ALWAYS`. La pausa segue lo stato della run: `RunManager` cambia solo stato (nessun accesso alla scena, così resta testabile come logica pura) e la composition root applica `paused` reagendo a `state_changed`.

- **Salvataggi manuali (M8)**: i punti di scrittura qui sotto modificano solo lo stato in memoria (`has_unsaved_changes`); su disco si scrive solo con `MetaProgression.save_game()`, chiamato da `GameSession.save()` (Salva nel menu di pausa). Mai `save_to_disk()` dal gameplay.
- **Punti di scrittura di `MetaProgression`**: `deposit_run_loot` (solo dopo un'estrazione), `craft`, `equip`/`unequip`, `register_extraction` (solo dopo un'estrazione), `select_arena`. Nessun altro sistema scrive lo stato permanente.
- **Persistenza**: solo `MetaProgression` legge/scrive su disco, in `user://` con `ConfigFile` e chiave `version` per future migrazioni. Ogni cambio di formato alza `SAVE_VERSION`, resta compatibile con le versioni precedenti (sezioni mancanti = default) e ha un test che carica un file della versione vecchia. Sul disco si salvano id, mai Resource: al caricamento si risolvono via catalogo (`EquipmentCatalog`) e gli id sconosciuti si scartano. Mai caricare `.tres`/`.res` da `user://` (possono contenere script eseguibili). Logica di inventario in classi pure (`MetaInventory`) separate dall'I/O, così si testano senza file.

- Interazioni nel mondo (hub, M7): un `Interactable` (Area2D) sa solo se il player è nel raggio e quale finestra apre (export `window`); l'apertura, la pausa e il focus li gestisce la composition root. Le finestre restano scene UI riusabili (`Blacksmith`, `LoadoutPanel`, `ArenaSelect`) con unique name, così `tools/flow.gd` le pilota senza passare dal mondo.
- **Testi (M9)**: mai testo visibile scritto in chiaro. Nelle scene e nei `.tres` (`display_name`, `description`, `text`, `prompt`) si mette la **chiave** (`MENU_CONTINUE`, `MAT_SLIME_GEL`); nel codice si compone con `tr("KEY") % valori` e si traducono i nomi dei dati con `tr(item.display_name)`. Ogni chiave nuova va in `data/i18n/strings.csv` con tutte e 4 le lingue: `tests/i18n/test_translations.gd` fallisce se ne manca una.
- **Contenuti nuovi = dati prima del codice**: nemici, arene, equipaggiamento, ricette, upgrade e suoni si aggiungono con `.tres` e scene seguendo `docs/GUIDA_CONTENUTI.md`. Gli `id` (materiali, equip, arene) finiscono nel salvataggio: una volta pubblicati non si rinominano. Se una procedura della guida cambia, la guida si aggiorna nello stesso commit.

## 3.1 Componenti di combattimento

- `Health` (HP + segnali `changed`/`damaged`/`died`, nessuna logica di morte), `Hitbox` (infligge danno), `Hurtbox` (riceve danno, inoltra a `Health`, i-frames opzionali), `HitFlash`, `Weapon` (cooldown + segnale `fired`, non istanzia proiettili).
- Attacchi ad area (M8): sempre preceduti da un `Telegraph` visibile (tempo minimo per uscire dal cerchio a velocità base del player); il danno è un impulso della sua `Hitbox`, non un controllo di distanza nel codice.
- Effetti di abilità (M10): `AbilityEffect` è una Resource con comportamento (strategy) che agisce solo tramite l'API di `WandAbilities` (proiettili, colpi ad area, player); niente riferimenti diretti ad Arena o nemici. Un effetto nuovo = sottoclasse + `.tres`, un criterio di attivazione nuovo = voce in coda a `WandAbility.Trigger` + ramo in `AbilityTrigger` (testato).
- **Movimento e interpolazione (M10.1)**: posizioni e rotazioni si cambiano solo in `_physics_process` (il rendering interpola). Ogni spostamento istantaneo (oggetto preso dal pool, teletrasporto, posizione caricata) chiama `reset_physics_interpolation()` **dopo** averlo reso visibile (su un nodo nascosto il reset viene ignorato): altrimenti il nodo "scivola" dalla posizione vecchia. Verifica: `godot --path . -s tools/interpolation_check.gd` (serve un display).
- Enum salvati nei `.tres` (es. `UpgradeData.Stat`): nuove voci solo in coda, mai riordinare o inserire in mezzo.
- Cadenze e timer che possono scendere sotto un tick di fisica: accumulatore (il timer va sotto zero e si spendono più eventi nello stesso tick), mai un solo evento per tick.
- `Knockback` (spinta, il corpo chiama `step()` e somma `velocity`), `HitStop` (unico punto che tocca `Engine.time_scale`, ripristino garantito in `_exit_tree`), `Blink` (i-frames visibili). Segnali `Hurtbox.knocked(impulse)` e `invulnerable_changed(active)`.
- Rilevazione unidirezionale: l'`Hurtbox` è `monitoring` (mask sul layer di attacco avversario), l'`Hitbox` è solo `monitorable`. Nessun doppio conteggio.
- Riferimenti tra componenti della stessa scena: `@export` con NodePath impostato nella scena, o `%UniqueName`.
- **Composition root**: la scena di livello (es. `Arena`) collega i segnali tra entità, pool, HUD e autoload. Le entità non si conoscono tra loro.

## 3.1.0 Grafica (da M6)

- Sorgente = SVG in `assets/art/`, generato da `tools/sprites.py` (o modificato in Inkscape); il PNG in `assets/sprites/` è un derivato, esportato a 2x della dimensione a schermo. In scena gli Sprite2D stanno a scala 0.5.
- Filtro texture lineare (default di progetto). Non mischiare più pixel art e vettoriale nella stessa scena.
- Stessa dimensione a schermo = stesso fattore: se un asset cambia dimensione si rigenera il PNG, non si cambia la scala del nodo.

- Luci (M7): solo poche `PointLight2D` (player, torce, candele); mai una luce per proiettile o per nemico. Ciò che deve restare leggibile al buio (proiettili, pickup, UI di gioco) usa un `CanvasItemMaterial` con `light_mode = unshaded`.

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
- Bilanciamento: prima e dopo una modifica ai `.tres` di ondate/drop/estrazione si lancia `tools/autoplay.gd` (stesse N run) e si annotano i numeri in GDD §10.1. Il bot confronta configurazioni, non sostituisce il playtest umano.

## 5. Versionamento e workflow

- Repo git locale (inizializzato). Un commit per unità di lavoro coerente, messaggio in stile convenzionale (`feat:`, `fix:`, `chore:`, `docs:`, `test:`).
- Ogni commit che cambia feature/scope/gameplay: aggiornare `docs/GDD.md` (sezione toccata) e aggiungere voce in `docs/CHANGELOG.md` nello stesso commit — non a posteriori.
- Task tracking: GitHub Issues + Projects su `danieleadelfio/Wanderloot`, una milestone per ogni M del GDD. Nessun sistema duplicato.
- Referenziare la issue nel messaggio di commit (`feat: enemy pool (#1)`, `Closes #1` per chiuderla col push).

## 6. Regola generale

Prima di introdurre un pattern nuovo, chiedersi: è più semplice del pattern esistente? Evita duplicazione? È mantenibile senza documentazione aggiuntiva? Se la risposta a una delle tre è no, non introdurlo.
