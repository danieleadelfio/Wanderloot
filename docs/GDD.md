# Wanderloot — Game Design Document (MVP)

Nome del gioco: **Wanderloot** ("wanderlust" + "loot"). Nome di lavoro precedente: FirstAiGame.

Ultimo aggiornamento: 2026-09-23
Engine: Godot 4.6
Stato: M3 (hub minimo) in corso

## 1. Pitch

Dungeon crawler/arena 2D top-down, ranged, in pixel art (16x16 o 32x32), fantasy. Il giocatore parte da un hub centrale sicuro e si lancia in run procedurali/semi-fisse in stile "arena survivor" (Vampire Survivors / Brotato / Hades): durante la run sale di livello e sceglie potenziamenti temporanei, mentre nemici e forzieri droppano loot ed equipaggiamento grezzo. Quel loot resta "a rischio" finché non si compie un'estrazione riuscita: morire prima di estrarre significa perderlo tutto. Solo il loot estratto entra nell'inventario permanente e alimenta crafting ed equipaggiamento nell'hub, che a sua volta sblocca nuove strutture e NPC.

Riferimenti diretti: Vampire Survivors / Brotato (run loop, scelta reward a level-up), Hades (hub tra le run, progressione doppia), Risk of Rain 2 (arena + estrazione/portale di fine run), Escape from Tarkov (concetto di extraction shooter applicato al loot).

## 2. Core Loop

1. **Hub** — il giocatore prepara la run: sceglie equipaggiamento permanente (sbloccato via crafting), parla con NPC, eventualmente avvia il crafting.
2. **Run** — entra nell'arena/dungeon. Uccide nemici a distanza, guadagna exp e loot "grezzo" (in un inventario temporaneo, valido solo per questa run).
3. **Level-up in run** — al salire di livello il gioco si mette in pausa e propone 3 scelte di potenziamento temporaneo (danno, velocità, area, nuove abilità passive). Puramente run-scoped, si azzera a fine run.
4. **Fine run** — due esiti:
   - **Estrazione riuscita** (raggiungere un punto di estrazione e sopravvivere per un tempo/canalizzazione): il loot grezzo accumulato passa all'inventario permanente nell'hub.
   - **Morte**: tutto il loot grezzo della run viene perso. Non si perde invece l'exp/valuta eventualmente già "assicurata" da meccaniche specifiche (v. §4).
5. **Ritorno in hub** — con il loot estratto (se presente) si fa crafting/upgrade per la run successiva.

## 3. Le due progressioni

### 3.1 Progressione interna alla run (temporanea)
- Exp guadagnata uccidendo nemici → level-up. Curva in `LevelCurve` (`data/run/level_curve.tres`): exp per passare da N a N+1 = `5 * 1.35^(N-1)` arrotondato (5, 7, 9, 12, 17…). L'exp in eccesso passa al livello successivo; più level-up in un colpo sono gestiti uno alla volta.
- Ad ogni level-up: pausa, 3 scelte casuali (pesate) tra potenziamenti d'arma, abilità passive, statistiche.
  - **Stato M1**: 5 upgrade di statistica in `data/upgrades/` (Potenza +1 danno, Raffica +20% cadenza, Gittata +20% velocità proiettili, Agilità +10% movimento, Vigore +1 HP max e cura 1), tutti con peso 1, estratti senza ripetizioni da `UpgradeTable`. Scelta con mouse o tastiera/pad (focus sul primo). Abilità passive/nuove armi: dopo l'MVP.
- Tutto ciò che riguarda questa progressione si azzera all'inizio di ogni run, indipendentemente dall'esito.

### 3.2 Progressione esterna alla run (permanente, meta)
- Alimentata **solo** dal loot estratto con successo.
- **Stato M2**: autoload `MetaProgression` con `MetaInventory` (id materiale → quantità, logica pura). Salvato in `user://meta_progression.cfg` (`ConfigFile`, con numero di versione) a ogni deposito, caricato all'avvio. Unico punto di scrittura esterno: `deposit_run_loot()`.
- Due filoni:
  - **Materiali da crafting** (comuni/rari) → usati per craftare o potenziare equipaggiamento nell'hub.
  - **Equipaggiamento grezzo/non identificato** → utilizzabile solo dopo l'estrazione; una volta in hub può essere equipaggiato o smontato in materiali.
- L'equipaggiamento permanente scelto in hub prima della run (arma di partenza, oggetti passivi permanenti) influenza il power level di partenza della run successiva.
  - **Stato M3 (#14)**: pannello "Equipaggiamento" nell'hub (un pezzo per slot, click per equipaggiare/togliere). A inizio run `Arena` passa `MetaProgression.equipped_items()` a `Player.begin_run()`, che riparte da copie fresche di `PlayerStats`/`WeaponData` e applica i modificatori (`StatApplier`, stessa logica degli upgrade di run, che si sommano sopra). L'equip è letto una sola volta: cambiarlo vale dalla run successiva.
- Sblocco progressivo di strutture/NPC nell'hub in base a milestone (es. numero di estrazioni riuscite, materiali totali raccolti, boss sconfitti).

## 4. Extraction shooter layer — regole di rischio

- Il loot grezzo vive in un "inventario di run" separato da quello permanente.
  - **Stato M2**: `LootRunInventory` (classe pura `RefCounted`, id materiale → quantità) posseduta da `RunManager.loot`; si svuota a ogni `start_run()` e accetta loot solo a run in corso. Nessun autoload aggiuntivo.
- **Morte prima dell'estrazione = perdita totale del loot di run.** (Regola scelta per l'MVP: nessuna mitigazione parziale, per mantenere la tensione rischio/ricompensa netta.)
  - **Stato M2**: a fine run `Arena` chiama `LootTransfer.resolve()` (logica pura, coperta da test GdUnit4): con esito `EXTRACTED` il loot va in `MetaProgression.deposit_run_loot()` (salvato su disco), con `DEATH` viene scartato; in entrambi i casi l'inventario di run si svuota. La schermata di fine run mostra “Loot estratto: N · Totale nel baule: M” oppure “Loot perso: N”.
- L'estrazione è un punto/area che appare dopo un certo tempo o dopo un trigger (es. uccisione di un'elite), e richiede di rimanere nella zona per N secondi (rischio: i nemici continuano ad arrivare durante il canale).
  - **Stato M1** (`ExtractionData`, `data/run/extraction_default.tres`): la zona (cerchio verde, raggio 48px) appare dopo 60s di run in un punto casuale ad almeno 400px dal player; servono 5s dentro la zona. **Decisione:** uscendo il progresso non si azzera ma cala di 0.5s per ogni secondo fuori (un'uscita breve per schivare non vanifica tutto). HUD: countdown, poi percentuale di estrazione. Nessun indicatore fuori schermo per ora (valutare in M4).
- Possibile estensione futura (fuori scope MVP): possibilità di estrarre "in anticipo" con meno loot ma meno rischio, o zone a rischio/reward crescente.

## 5. Combattimento (ranged)

- Player controllato con movimento in 8 direzioni (WASD/stick) + mira libera (mouse o stick destro) — twin-stick style.
- Arma di partenza singola (es. "arco" o "baccheta magica base"), a distanza, con cooldown/fire-rate.
- I proiettili sono sprite semplici (piccoli cerchi/frecce), riutilizzabili via object pooling per performance.
- Nemici: pattern semplici (inseguimento diretto, mantenimento distanza + attacco ranged, pattern a pattuglia). Nessuna animazione complessa richiesta: 1-2 frame di movimento + 1 di attacco/morte sono sufficienti in stile pixel art.
- Combat feel gestito via codice: knockback, hit-flash, hitstop leggero, i-frames sul player — nessun bisogno di asset aggiuntivi per "sentire" l'impatto.
- **Stato M0**: movimento 8 direzioni (WASD/frecce/stick sinistro), mira col mouse tenendo premuto il tasto sinistro oppure stick destro con auto-fire, fire-rate da `WeaponData`. Implementati hit-flash (nemici e player) e i-frames del player (0.8s, danno da contatto ripetuto finché si resta a contatto). Knockback e hitstop rinviati a M4 (rifinitura).

## 6. Loot e crafting (scope MVP)

- I nemici droppano: exp (sempre) + eventualmente 1 tipo di materiale comune.
- Rari drop: pezzo di equipaggiamento grezzo (non identificato/non equipaggiabile finché non estratto).
- **Stato M2 (dati)**: `MaterialData` (id, nome, rarità comune/raro, colore placeholder) in `data/materials/`; drop table come array di `DropEntry` (materiale, probabilità, quantità min/max) dentro `EnemyData`, ogni riga tirata indipendentemente. Slime: Gelatina (comune) 35% ×1–2, Nucleo di slime (raro) 3% ×1. L'equipaggiamento grezzo arriva con M3 (crafting/equip), in M2 solo materiali.
- **Stato M2 (drop)**: alla morte di un nemico `Arena` tira la sua drop table e aggiunge direttamente all'inventario di run (nessun pickup fisico da raccogliere: pickup/magnete valutabili in M4). HUD: "Loot a rischio: N" in ambra.
- Crafting MVP: sistema semplice "materiali → oggetto", con ricette fisse (niente crafting proceduralmente generato in v1).
- Equipaggiamento MVP: slot minimi (arma, 1 accessorio) per non esplodere lo scope.
- **Stato M3 (#12, dati)**: `EquipmentData` (id, nome, descrizione, slot `WEAPON`/`ACCESSORY`, lista di `StatModifier`) in `data/equipment/`, tutti elencati in `EquipmentCatalog` (risolve gli id salvati). `StatModifier` riusa l'enum di `UpgradeData.Stat` (danno, cadenza, velocità proiettili, movimento, HP max). Pezzi iniziali: Bacchetta di gelatina (+1 danno), Bacchetta rapida (+25% cadenza), Amuleto del nucleo (+2 HP), Stivali viscosi (+10% movimento). **Decisione**: lo slot arma modifica la bacchetta base, non la sostituisce (nuovi tipi di arma: v2). L'equipaggiamento grezzo droppato in run resta fuori dall'MVP: i pezzi si ottengono solo col crafting.
- `EquipmentLoadout` (logica pura, in `MetaProgression.loadout`): pezzi posseduti per id, un pezzo equipaggiato per slot; si può equipaggiare solo ciò che si possiede.

## 7. Hub centrale (scope MVP)

Per l'MVP, hub ridotto a:
- **1 NPC "Fabbro/Blacksmith"**: crafting base e potenziamento equipaggiamento con i materiali estratti.
  - **Stato M3 (#13)**: pannello "Fabbro" nell'hub con le ricette fisse di `data/recipes/recipe_book.tres` (`RecipeData`: risultato + righe `MaterialCost`). Costi iniziali: Bacchetta di gelatina 6 Gelatina, Stivali viscosi 8 Gelatina, Bacchetta rapida 10 Gelatina + 1 Nucleo, Amuleto del nucleo 4 Gelatina + 2 Nuclei. Bottone disabilitato se mancano materiali o il pezzo è già posseduto. **Decisione**: ogni pezzo si crafta una sola volta (niente duplicati né potenziamento nell'MVP: potenziamento/smontaggio in v2). Regole in `Crafting` (logica pura); `MetaProgression.craft()` è l'unico punto che scala i materiali e salva.
- **1 baule/inventario permanente**: dove finisce il loot dopo un'estrazione riuscita.
- **1 portale/punto di partenza run**.
- **Stato M3 (#11)**: l'hub è una schermata UI (`scenes/hub/Hub/`), non ancora un ambiente esplorabile: pannello "Baule" con i materiali permanenti e bottone "Parti per la run". È la scena principale del gioco. A fine run (morte o estrazione) "Torna all'hub" sostituisce "Nuova run". **Decisione**: hub esplorabile con NPC fisici rinviato (M4 o v2), per l'MVP conta il ciclo hub→run→hub. Cambi scena via `change_scene_to_file` con percorsi in `SceneRoutes` (nessun autoload aggiuntivo).

Fuori scope MVP ma parte della visione a lungo termine (da aggiungere per fasi successive): NPC mercante (compra/vendi), NPC alchimista (pozioni/buff), strutture che si sbloccano con la progressione (nuova ala dell'hub, arena di addestramento, ecc.), più tipi di run/arena, più armi ranged ed elite/boss.

## 8. Arte e stile

- Stile: pixel art, griglia 16x16 o 32x32 (da fissare in fase di prototipo in base alla leggibilità a schermo; 32x32 dà più margine per dettagli su armi/effetti).
- Palette limitata (4-8 colori dominanti) per coerenza visiva e per ridurre il lavoro di produzione asset.
- Fonte asset consigliata: pacchetti pronti stile Kenney.nl (gratuiti) o pacchetti a pagamento coerenti (es. "Tiny Dungeon", "Cute Fantasy RPG") su itch.io, integrati con generazione AI mirata (sprite singoli, icone oggetti, tileset) per colmare i buchi specifici del proprio gioco.
- Nessuna animazione complessa richiesta per l'MVP: idle, movimento (2-4 frame), attacco, hit, morte per player e nemici base.

## 9. Struttura tecnica (Godot 4.6)

Struttura scene target (indicativa; lo stato reale è in §9.1):

```
res://
  scenes/
    hub/
      Hub.tscn
      NpcBlacksmith.tscn
    run/
      Arena.tscn
      Player.tscn
      Enemies/
        EnemyBasic.tscn
        EnemyRanged.tscn
      Projectile.tscn
      ExtractionPoint.tscn
    ui/
      LevelUpChoice.tscn
      HubMenu.tscn
      HUD.tscn
  scripts/
    player/
      player_controller.gd
      player_stats.gd
    combat/
      projectile_pool.gd
      hitbox.gd
      hurtbox.gd
    run/
      run_manager.gd        # stato della run corrente, exp, level, timer estrazione
      loot_run_inventory.gd # inventario "a rischio" della run
    meta/
      meta_progression.gd   # inventario permanente, materiali, equip
      crafting_system.gd
    enemies/
      enemy_ai_base.gd
  data/
    weapons.tres / .json
    enemies.tres / .json
    upgrades.tres / .json
    recipes.tres / .json
  assets/
    sprites/
    tiles/
    audio/
```

### 9.1 Struttura attuale

```
res://
  autoload/run_manager.gd            # RunManager: stato, exp, livello, tempo, uccisioni, loot di run
  autoload/meta_progression.gd       # MetaProgression: inventario permanente + salvataggio su disco
  scripts/meta/                      # meta_inventory, equipment_loadout, crafting (logica pura dello stato permanente)
  scripts/core/scene_routes.gd       # percorsi delle scene principali (Hub, Arena)
  scenes/hub/Hub/                    # Hub.tscn + hub.gd (scena principale, composition root dell'hub)
  scenes/hub/Blacksmith/             # pannello fabbro (ricette, richiesta craft via segnale)
  scenes/hub/LoadoutPanel/           # pannello equipaggiamento (equip/unequip via segnale)
  scenes/run/Arena/                  # Arena.tscn + arena.gd (composition root: collega i segnali)
  scenes/run/Player/                 # Player.tscn + player.gd
  scenes/run/Enemies/enemy.gd        # script nemico condiviso, guidato da EnemyData
  scenes/run/Enemies/EnemyBasic/     # EnemyBasic.tscn (inseguimento diretto)
  scenes/run/Projectile/             # Projectile.tscn + projectile.gd (poolable)
  scenes/run/ExtractionPoint/        # zona di estrazione (Area2D + _draw del progresso)
  scenes/ui/HUD/                     # HUD.tscn + hud.gd (HP, livello, barra EXP)
  scenes/ui/LevelUpChoice/           # overlay scelta upgrade (funziona in pausa)
  scenes/ui/RunEndScreen/            # schermata di fine run (morte/estrazione) + riavvio
  scripts/combat/                    # health, hitbox, hurtbox, hit_flash, weapon, projectile_pool
  scripts/run/                       # enemy_pool, wave_spawner, spawn_utils, loot_run_inventory, loot_transfer, stat_applier
  addons/gdUnit4/                    # framework di test (v6.2.1, vendored)
  tests/                             # test GdUnit4, specchio di scripts/ e autoload/
  scripts/data/                      # classi Resource: weapon_data, enemy_data, player_stats, wave_data, level_curve, upgrade_data, upgrade_table, extraction_data, material_data, drop_entry, stat_modifier, equipment_data, equipment_catalog, material_cost, recipe_data, recipe_book
  data/{weapons,enemies,player,waves,run,upgrades,materials,equipment,recipes}/ # .tres: starter_wand, enemy_basic, player_default, wave_default, level_curve, extraction_default, upgrade_*, slime_gel, slime_core, equipment_catalog + pezzi, recipe_book + ricette
```

- Grafica placeholder: `Polygon2D` (player ottagono blu, nemico quadrato rosso, proiettile rombo giallo). Arena 1600x1000 con muri, camera sul player con limiti arena.
- Autoload attivi: `RunManager` (stato run) e `MetaProgression` (stato permanente, da M2). Nessun altro.
- Nemici: `EnemyPool` (un pool per tipo di nemico, 32 pre-istanziati, cresce se serve) + `WaveSpawner` guidato da `WaveData`: l'intervallo tra batch scende da 2.0s a 0.5s (−0.015s per secondo di run), il batch cresce di 1 nemico ogni 25s, tetto 60 nemici vivi. Spawn in punto casuale ad almeno 300px dal player.
- Flusso di run (M1): `RunManager` è una macchina a stati `IDLE → RUNNING ⇄ LEVEL_UP → ENDED` con esito `DEATH` o `EXTRACTED`. `Arena` mette in pausa il gioco quando lo stato non è `RUNNING`. A fine run: schermata con esito, livello, tempo e uccisioni, bottone “Torna all'hub” (da M3; nuova run = scena `Arena` nuova + `start_run()`). Il canale di estrazione non è uno stato globale: vive in `ExtractionPoint` (nessun altro sistema ne dipende). `RunManager` non scrive mai su `MetaProgression` (vedi §4).
- Collision layers (nomi in Project Settings): 1 `world`, 2 `player`, 3 `enemy`, 4 `player_attack`, 5 `enemy_attack`.
- Input map: `move_*` (WASD, frecce, stick sinistro), `aim_*` (stick destro), `shoot` (mouse sinistro).

Note tecniche:
- Autoload consigliati: `RunManager` (stato run corrente, azzerato ad ogni run) e `MetaProgression` (persistito su disco, es. tramite `ConfigFile` o risorse `.tres`/JSON in `user://`).
- Separare nettamente lo stato "run" da quello "meta" fin dall'inizio: è la base tecnica di tutta la meccanica extraction/estrazione (vedi §4). Il `RunManager` non deve mai scrivere direttamente su `MetaProgression`: lo fa solo l'evento "estrazione riuscita".
- Object pooling per proiettili e nemici comuni, utile fin da subito viste le run ad orde (arena survivor-like).
- Godot's `TileMap`/`TileSet` per l'arena, `Area2D` per hitbox/hurtbox e per il trigger di estrazione.

## 10. Roadmap per milestone

**M0 — Skeleton tecnico** ✅ (2026-09-23): player che si muove e spara in un'arena vuota, un nemico che insegue, proiettili con pool, HUD minimale (HP/exp). Dettagli in §5 e §9.1.
**M1 — Run loop completo** ✅ (2026-09-23): level-up con scelta di 3 upgrade, spawn di nemici a ondate, punto di estrazione funzionante, morte = reset run.
**M2 — Loot ed extraction** ✅ (2026-09-23): inventario di run separato da quello permanente, drop di materiali, trasferimento del loot solo su estrazione riuscita.
**M3 — Hub minimo**: scena hub, 1 NPC fabbro, crafting con ricette fisse, equipaggiamento persistente selezionabile prima della run.
**M4 — Rifinitura MVP**: combat feel (knockback, hitstop), bilanciamento (curve exp/danno/drop rate), asset pixel art definitivi, audio minimo, primo playtest completo hub→run→estrazione/morte→hub.

Fuori da questa roadmap (v2+): più NPC/strutture nell'hub, crafting proceduralmente ricco, più biomi/arene, boss, sistema di rarità loot più profondo, meccaniche di estrazione a rischio variabile.

## 11. Open questions

- Godot version confermata: 4.6 (da project.godot). Se si prevede export mobile o console, valutare per tempo eventuali limitazioni.
- Dimensione sprite definitiva (16x16 vs 32x32): da decidere dopo un primo test visivo in arena con la UI reale.
- ~~Persistenza meta-progressione~~ → decisa in M2: `ConfigFile` in `user://` (leggibile, versionato; niente `.tres` caricati da `user://`, che possono eseguire script). Cloud save fuori scope.
- Durata target di una run (utile per bilanciare drop rate e timer di estrazione): da definire con il primo playtest.

## 12. Processo e versionamento

- Repo GitHub: `danieleadelfio/Wanderloot` (remote `origin`, branch `main`).
- Task tracking: GitHub Issues + Projects, attivo. Una milestone per ogni M del §10; nessun sistema di task parallelo.
- Vedi `docs/BEST_PRACTICES.md` per convenzioni di codice, architettura e testing (GdUnit4). Vedi `docs/CHANGELOG.md` per lo storico modifiche.
- **Regola fissa**: ogni modifica a feature/grafica/scope/genere/gameplay loop va riportata in questo documento (sezione pertinente) e come voce in `docs/CHANGELOG.md`, nello stesso commit della modifica.
