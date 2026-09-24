# Wanderloot — Game Design Document (MVP)

Nome del gioco: **Wanderloot** ("wanderlust" + "loot"). Nome di lavoro precedente: FirstAiGame.

Ultimo aggiornamento: 2026-09-23
Engine: Godot 4.6
Stato: MVP completato (M0–M4) — prossimo: playtest umano e roadmap v2

## 1. Pitch

Dungeon crawler/arena 2D top-down, ranged, in grafica vettoriale 2D (da M6; prima pixel art), fantasy. Il giocatore parte da un hub centrale sicuro e si lancia in run procedurali/semi-fisse in stile "arena survivor" (Vampire Survivors / Brotato / Hades): durante la run sale di livello e sceglie potenziamenti temporanei, mentre nemici e forzieri droppano loot ed equipaggiamento grezzo. Quel loot resta "a rischio" finché non si compie un'estrazione riuscita: morire prima di estrarre significa perderlo tutto. Solo il loot estratto entra nell'inventario permanente e alimenta crafting ed equipaggiamento nell'hub, che a sua volta sblocca nuove strutture e NPC.

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
- Exp guadagnata raccogliendo le gemme lasciate dai nemici (da M5; prima era immediata) → level-up. Curva in `LevelCurve` (`data/run/level_curve.tres`): exp per passare da N a N+1 = `5 * 1.35^(N-1)` arrotondato (5, 7, 9, 12, 17…). L'exp in eccesso passa al livello successivo; più level-up in un colpo sono gestiti uno alla volta.
- Ad ogni level-up: pausa, 3 scelte casuali (pesate) tra potenziamenti d'arma, abilità passive, statistiche.
  - **Stato M1**: 5 upgrade di statistica in `data/upgrades/` (Potenza +1 danno, Raffica +20% cadenza, Gittata +20% velocità proiettili, Agilità +10% movimento, Vigore +1 HP max e cura 1), tutti con peso 1, estratti senza ripetizioni da `UpgradeTable`. Scelta con mouse o tastiera/pad (focus sul primo). Abilità passive/nuove armi: dopo l'MVP.
  - **Stato M5 (#25)**: 8 potenziamenti in più (13 totali), tutti cumulabili senza tetto. Statistiche: Persistenza +25% durata proiettili, Magnete +30% raggio di raccolta, Saggezza +15% exp raccolta, Fortuna +15% probabilità di drop, Guardia +0,2s di invulnerabilità, Impatto +30% spinta. Meccaniche (peso 0,6, più rari): Ventaglio +1 proiettile per colpo (ventaglio centrato, 10° tra i proiettili, compresso se supera 360°), Perforazione +1 nemico attraversato. Nuove voci di `UpgradeData.Stat` sempre in coda all'enum (i `.tres` salvano l'indice).
- Tutto ciò che riguarda questa progressione si azzera all'inizio di ogni run, indipendentemente dall'esito.

### 3.2 Progressione esterna alla run (permanente, meta)
- Alimentata **solo** dal loot estratto con successo.
- **Stato M2**: autoload `MetaProgression` con `MetaInventory` (id materiale → quantità, logica pura). Salvato in `user://meta_progression.cfg` (`ConfigFile`, con numero di versione) a ogni deposito, caricato all'avvio. Unico punto di scrittura esterno: `deposit_run_loot()`.
- **Stato M3 (#15)**: salvataggio versione 2 = materiali + equipaggiamento (`[equipment] owned`, `[equipped] weapon/accessory`), scritto a ogni deposito, craft, equip e unequip. Un salvataggio v1 si carica con loadout vuoto. Al caricamento gli id assenti dal catalogo e i pezzi equipaggiati ma non posseduti (o nello slot sbagliato) vengono scartati. Il loot entra ancora solo da `deposit_run_loot()`; i materiali escono solo da `craft()`.
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
  - **Stato M1** (`ExtractionData`, `data/run/extraction_default.tres`): la zona (cerchio verde, raggio 48px) appare dopo 60s di run in un punto casuale ad almeno 400px dal player; servono 5s dentro la zona. **Decisione:** uscendo il progresso non si azzera ma cala di 0.5s per ogni secondo fuori (un'uscita breve per schivare non vanifica tutto). HUD: countdown, poi percentuale di estrazione. Da M4 (#20): freccia verde sul bordo dello schermo verso la zona quando è fuori vista (`ExtractionIndicator`).
- Possibile estensione futura (fuori scope MVP): possibilità di estrarre "in anticipo" con meno loot ma meno rischio, o zone a rischio/reward crescente.

## 5. Combattimento (ranged)

- Player controllato con movimento in 8 direzioni (WASD/stick) + mira libera (mouse o stick destro) — twin-stick style.
- Arma di partenza singola (es. "arco" o "baccheta magica base"), a distanza, con cooldown/fire-rate.
- I proiettili sono sprite semplici (piccoli cerchi/frecce), riutilizzabili via object pooling per performance.
- Nemici: pattern semplici (inseguimento diretto, mantenimento distanza + attacco ranged, pattern a pattuglia). Nessuna animazione complessa richiesta: 1-2 frame di movimento + 1 di attacco/morte sono sufficienti in stile pixel art.
- Combat feel gestito via codice: knockback, hit-flash, hitstop leggero, i-frames sul player — nessun bisogno di asset aggiuntivi per "sentire" l'impatto.
- **Stato M4 (#16)**: knockback come componente `Knockback` (spinta che decade, `resistance` 0–1), alimentato da `Hurtbox.knocked`; intensità nei dati (`WeaponData.knockback` 320 → ~40px sullo slime, `EnemyData.contact_knockback` 380 → ~27px sul player, `knockback_resistance`). **Decisione hitstop**: sui colpi ai nemici (molto frequenti) solo freeze locale del nemico colpito (`EnemyData.hit_freeze` 0.05s); hitstop globale (`HitStop`, `Engine.time_scale` 0.05 per 0.08s reali) solo quando il player subisce danno, e `time_scale` viene sempre ripristinato all'uscita dalla scena. I-frames del player ora visibili (lampeggio `Blink`); il knockback da contatto allontana il player dal nemico, quindi il danno ripetuto a contatto diventa raro.
- **Stato M5 (#21)**: nessun tetto alla cadenza di fuoco. Prima l'arma sparava al massimo 1 colpo per tick di fisica (60/s) e l'arrotondamento del cooldown faceva perdere cadenza già da ~30 colpi/s; ora il cooldown è ad accumulatore e nello stesso tick partono tutti i colpi maturati, sfalsati lungo la traiettoria. Scelta di design: gli upgrade possono "rompere" il gioco, è parte del divertimento.
- **Stato M0**: movimento 8 direzioni (WASD/frecce/stick sinistro), mira col mouse tenendo premuto il tasto sinistro oppure stick destro con auto-fire, fire-rate da `WeaponData`. Implementati hit-flash (nemici e player) e i-frames del player (0.8s, danno da contatto ripetuto finché si resta a contatto). Knockback e hitstop rinviati a M4 (rifinitura).

## 6. Loot e crafting (scope MVP)

- I nemici droppano: exp (sempre) + eventualmente 1 tipo di materiale comune.
- Rari drop: pezzo di equipaggiamento grezzo (non identificato/non equipaggiabile finché non estratto).
- **Stato M2 (dati)**: `MaterialData` (id, nome, rarità comune/raro, colore placeholder) in `data/materials/`; drop table come array di `DropEntry` (materiale, probabilità, quantità min/max) dentro `EnemyData`, ogni riga tirata indipendentemente. Slime: Gelatina (comune) 35% ×1–2, Nucleo di slime (raro) 3% ×1. L'equipaggiamento grezzo arriva con M3 (crafting/equip), in M2 solo materiali.
- ~~Stato M2 (drop)~~: il loot andava direttamente nell'inventario di run. **Sostituito in M5 (#22)**: alla morte il nemico lascia a terra una gemma di exp (blu) e i materiali tirati dalla drop table (icona del materiale). Entro `PlayerStats.pickup_radius` (90px) vengono attratti verso il player con accelerazione (effetto magnete) e assorbiti al contatto, con due suoni distinti (`pickup_exp`, `pickup_item`). Exp e loot contano solo quando assorbiti; ciò che resta a terra a fine run è perso. Pool e movimento in `PickupPool` (un solo `_physics_process` per tutti gli oggetti), coperto da test. HUD: "Loot a rischio: N" in ambra.
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

- Stile (da M6): **grafica vettoriale** con contorno scuro, sfumature e ombre morbide. Sorgenti SVG in `assets/art/`, PNG esportati a 2x della dimensione a schermo in `assets/sprites/`, Sprite2D a scala 0.5 con filtro lineare. ~~Pixel art 16x16/32x32~~: abbandonata in M6 dopo il confronto 16/32/64/vettoriale, per nitidezza a qualsiasi zoom e schermo intero e per un migliore rapporto qualità/costo di produzione degli asset generati.
- Palette limitata (4-8 colori dominanti) per coerenza visiva e per ridurre il lavoro di produzione asset.
- Fonte asset consigliata: pacchetti pronti stile Kenney.nl (gratuiti) o pacchetti a pagamento coerenti (es. "Tiny Dungeon", "Cute Fantasy RPG") su itch.io, integrati con generazione AI mirata (sprite singoli, icone oggetti, tileset) per colmare i buchi specifici del proprio gioco.
- Nessuna animazione complessa richiesta per l'MVP: idle, movimento (2-4 frame), attacco, hit, morte per player e nemici base.

- **Stato M6 (#28)**: pavimento a lastre (tile di 192px di mondo, 3x3 lastre con variazioni di tono e crepe) e muri a mattoni vettoriali; icone vettoriali di materiali ed equipaggiamento (64px sorgente, 32px nell'hub, 24px come oggetti a terra). Nessun ostacolo nell'arena per ora: richiede steering o pathfinding per i nemici, da discutere a parte.
- **Stato M6 (#27)**: player (mago incappucciato col bastone, 48px a schermo), slime (44px), proiettile (sfera con scia, 16px) e gemma di exp (16px) vettoriali; 2 frame di respiro per player e slime (`FrameCycler`). Collider dello slime allargati alle nuove dimensioni (corpo 16px, hurtbox e contatto 17px). Generatore: `tools/sprites.py` (Python + cairosvg).
- ~~Stato M4 (#18)~~ (superato in M6): primo set di asset in pixel art 16x16 (scala 2, filtro nearest), palette ristretta derivata da Sweetie-16, contorno scuro su tutti gli sprite. Generati da `tools/sprites.py` (sprite descritti come griglie di caratteri: modificabili e rigenerabili senza editor grafico). **Nota**: è programmer art coerente, non arte finale da artista; la pipeline permette di sostituire i PNG in `assets/sprites/` a parità di dimensioni senza toccare scene o codice.
- **Stato M4 (#19, audio)**: SFX chiptune sintetizzati da `tools/audio.py` (numpy): sparo, colpo e morte nemico, danno e morte player, level-up, apertura estrazione, estrazione riuscita, craft, selezione. Due musiche in loop (hub 90 BPM calma, arena 140 BPM incalzante). Bus `Music` (−8 dB) e `SFX` (−3 dB) in `default_bus_layout.tres`. Suoni per id in `data/audio/sound_bank.tres`; `SfxPlayer` (pool di 12 voci, min 30ms tra ripetizioni dello stesso suono, pitch variato sui suoni frequenti) ignora id/stream mancanti senza errori. Stessa nota della grafica: suoni programmatici sostituibili file per file.
- **Stato M5 (#26, HUD e schermo)**: barra HP rossa, barra EXP blu. Scalatura della finestra `canvas_items` con risoluzione base 1280x720 e aspect `expand`: a schermo intero gioco e HUD si ingrandiscono in proporzione invece di mostrare più arena a pixel minuscoli. Zoom della camera (`Arena/Player/Camera2D`): 1.0 per ora, **valore definitivo da scegliere con il playtest del proprietario** e da riportare qui.

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
  scripts/combat/                    # health, hitbox, hurtbox, hit_flash, weapon, projectile_pool, knockback, hit_stop, blink, frame_cycler
  assets/art/                        # sorgenti SVG della grafica (da M6)
  assets/sprites/                    # PNG esportati a 2x (player, slime, proiettile, gemma, tile, icone)
  tools/sprites.py                   # generatore della grafica vettoriale (Python + cairosvg): SVG → PNG 2x
  tools/autoplay.gd                  # bot di playtest per il bilanciamento (metriche su N run)
  tools/flow.gd                      # playtest end-to-end automatico hub→run→hub
  scenes/ui/ExtractionIndicator/     # freccia a bordo schermo verso la zona di estrazione
  tools/bot_driver.gd                # guida del bot (kiting, mira, estrazione), condivisa dagli strumenti
  assets/audio/                      # WAV di SFX e musiche (generati da tools/audio.py)
  scripts/audio/                     # sound_entry, sound_bank, sfx_player, music_player
  data/audio/sound_bank.tres         # id suono -> stream + volume
  scripts/run/                       # enemy_pool, wave_spawner, spawn_utils, loot_run_inventory, loot_transfer, stat_applier, pickup_pool, pause_state, pause_controller
  scenes/run/Pickup/                 # oggetto a terra (gemma exp o materiale), poolable
  addons/gdUnit4/                    # framework di test (v6.2.1, vendored)
  tests/                             # test GdUnit4, specchio di scripts/ e autoload/
  scripts/data/                      # classi Resource: weapon_data, enemy_data, player_stats, wave_data, level_curve, upgrade_data, upgrade_table, extraction_data, material_data, drop_entry, stat_modifier, equipment_data, equipment_catalog, material_cost, recipe_data, recipe_book
  data/{weapons,enemies,player,waves,run,upgrades,materials,equipment,recipes}/ # .tres: starter_wand, enemy_basic, player_default, wave_default, level_curve, extraction_default, upgrade_*, slime_gel, slime_core, equipment_catalog + pezzi, recipe_book + ricette
```

- Grafica (M6): sprite vettoriali in `assets/sprites/` (player e slime a 2 frame via `FrameCycler`, proiettile, pavimento e muri a tile ripetute, icone 16x16 di materiali ed equipaggiamento usate nell'hub). Arena 1600x1000: muri visibili larghi 32px sul bordo, area giocabile ±768x±468, camera sul player con limiti arena.
- Autoload attivi: `RunManager` (stato run) e `MetaProgression` (stato permanente, da M2). Nessun altro.
- Nemici: `EnemyPool` (un pool per tipo di nemico, 32 pre-istanziati, cresce se serve) + `WaveSpawner` guidato da `WaveData`: l'intervallo tra batch scende da 2.0s a 0.5s (−0.015s per secondo di run), il batch cresce di 1 nemico ogni 25s, tetto 60 nemici vivi. Spawn in punto casuale ad almeno 300px dal player.
- Flusso di run (M1): `RunManager` è una macchina a stati `IDLE → RUNNING ⇄ LEVEL_UP → ENDED` con esito `DEATH` o `EXTRACTED`. `Arena` mette in pausa il gioco quando lo stato non è `RUNNING`. A fine run: schermata con esito, livello, tempo e uccisioni, bottone “Torna all'hub” (da M3; nuova run = scena `Arena` nuova + `start_run()`). Il canale di estrazione non è uno stato globale: vive in `ExtractionPoint` (nessun altro sistema ne dipende). `RunManager` non scrive mai su `MetaProgression` (vedi §4).
- Collision layers (nomi in Project Settings): 1 `world`, 2 `player`, 3 `enemy`, 4 `player_attack`, 5 `enemy_attack`.
- Input map: `move_*` (WASD, frecce, stick sinistro), `aim_*` (stick destro), `shoot` (mouse sinistro), `menu` (ESC, Start), `pause` (P), `inventory` (I, Back).
- Pausa (M5, #23): ESC apre il menu di pausa (Riprendi, Pausa; predisposto per altre voci), P mette direttamente in pausa con la scritta PAUSA bianca semitrasparente al centro (96px su base 720p). ESC chiude qualsiasi pausa aperta. Logica in `PauseState` (pura, testata), input in `PauseController`; `Arena` mette in pausa se lo chiede la run (level-up, fine run) o il giocatore. Durante level-up e fine run ESC/P/I sono ignorati.
- Inventario di run (M5, #24): I apre un pannello sulla metà destra dello schermo e mette in pausa; mostra l'equipaggiamento indossato (per slot) e il loot raccolto nella run con il totale a rischio. Si chiude con I o ESC. È un quarto modo di `PauseState`, quindi non si sovrappone a menu e pausa.

Note tecniche:
- Autoload consigliati: `RunManager` (stato run corrente, azzerato ad ogni run) e `MetaProgression` (persistito su disco, es. tramite `ConfigFile` o risorse `.tres`/JSON in `user://`).
- Separare nettamente lo stato "run" da quello "meta" fin dall'inizio: è la base tecnica di tutta la meccanica extraction/estrazione (vedi §4). Il `RunManager` non deve mai scrivere direttamente su `MetaProgression`: lo fa solo l'evento "estrazione riuscita".
- Object pooling per proiettili e nemici comuni, utile fin da subito viste le run ad orde (arena survivor-like).
- Godot's `TileMap`/`TileSet` per l'arena, `Area2D` per hitbox/hurtbox e per il trigger di estrazione.

## 10. Roadmap per milestone

**M0 — Skeleton tecnico** ✅ (2026-09-23): player che si muove e spara in un'arena vuota, un nemico che insegue, proiettili con pool, HUD minimale (HP/exp). Dettagli in §5 e §9.1.
**M1 — Run loop completo** ✅ (2026-09-23): level-up con scelta di 3 upgrade, spawn di nemici a ondate, punto di estrazione funzionante, morte = reset run.
**M2 — Loot ed extraction** ✅ (2026-09-23): inventario di run separato da quello permanente, drop di materiali, trasferimento del loot solo su estrazione riuscita.
**M3 — Hub minimo** ✅ (2026-09-23): scena hub, 1 NPC fabbro, crafting con ricette fisse, equipaggiamento persistente selezionabile prima della run.
**M4 — Rifinitura MVP** ✅ (2026-09-23): combat feel (knockback, hitstop), bilanciamento (curve exp/danno/drop rate), asset pixel art definitivi, audio minimo, primo playtest completo hub→run→estrazione/morte→hub.

Fuori da questa roadmap (v2+): più NPC/strutture nell'hub, crafting proceduralmente ricco, più biomi/arene, boss, sistema di rarità loot più profondo, meccaniche di estrazione a rischio variabile.

### 10.1 Bilanciamento M4 (#17)

Metodo: bot di playtest `tools/autoplay.gd` (kiting dai nemici vicini, mira automatica sul più vicino, va all'estrazione appena appare, upgrade casuale al level-up), 20–30 run per configurazione a velocità massima (`--fixed-fps`). Il bot mira meglio di un umano e schiva peggio: i numeri servono a confrontare configurazioni, non come verità assoluta.

| Configurazione | Estrazioni | Durata media | Uccisioni | Gelatina / run | Nuclei / run |
|---|---|---|---|---|---|
| Valori M3 (zona a 60s) | 70% | 74s | 88 | 46,6 | 2,3 |
| Zona a 120s, ondate M3 | 0% | 96s | 188 | — | — |
| **Finale** senza equip | 63% | 129s | 182 | 34,5 | 3,5 |
| Finale, Bacchetta di gelatina + Amuleto | 90% | 132s | 200 | — | — |
| Finale, Bacchetta rapida + Stivali | 80% | 134s | 200 | — | — |

Problemi trovati e scelte:
- Con la zona a 60s la run era troppo corta e l'economia regalava tutto: una sola estrazione bastava per craftare tutti e 4 i pezzi. Zona portata a **120s**, canale **6s**.
- Con la zona a 120s e le ondate di M3 il bot moriva sempre prima di 130s: intervallo tra batch che si riduce più lentamente (`interval_decay` 0.015 → **0.008**), batch che cresce ogni **40s** (era 25s), tetto iniziale **45** nemici vivi (era 60).
- **Bug di design trovato dal bot**: con un tetto fisso di nemici la pressione si fermava attorno ai 3 minuti e una run è durata 45 minuti, cioè farming infinito senza rischio. Ora il tetto cresce di **+5 ogni 30s** (`WaveData.max_alive_at`, coperto da test).
- Economia: Gelatina **20% ×1** (era 35% ×1–2), Nucleo **1,5%** (era 3%). Costi: Bacchetta di gelatina 25 Gelatina, Stivali 30, Amuleto 20 + 3 Nuclei, Bacchetta rapida 40 + 4 Nuclei. Obiettivo: primo pezzo dopo la prima estrazione riuscita, tutti e 4 dopo circa 4–5 estrazioni (6–8 run).
- L'equipaggiamento pesa: con 2 pezzi le estrazioni salgono dal 63% all'80–90%.

### 10.2 Playtest M4 (#20)

Playtest end-to-end automatico `tools/flow.gd` (bot): hub → run fino a un'estrazione riuscita → hub (baule aggiornato) → craft dal fabbro → equip → run con equip applicato → morte → hub (baule invariato) → ricarica del salvataggio da disco. Tutti i passi verificati; `Engine.time_scale` e pausa tornano sempre a normale. Trovati e corretti:
- **Crash**: il ripristino differito del focus nell'hub partiva dopo il cambio scena (`gui_get_focus_owner` su null) → controllo `is_inside_tree()`.
- **Blocco di UX**: con la zona a 120s in un'arena più grande dello schermo non c'era modo di sapere dove fosse → indicatore a bordo schermo.
- **Farming infinito** (vedi §10.1) → tetto di nemici crescente.

Non verificabile da bot, resta da fare a mano: feeling di controlli e mira col mouse, leggibilità degli sprite a 2x, volumi reali di SFX/musica, chiarezza di hub e fabbro per chi non conosce il gioco. Noti e accettati per l'MVP: nessun menu di pausa/uscita durante la run, nessun menu opzioni (volumi), nessuna schermata titolo.

### 10.3 Verifica M5 (#22, raccolta a magnete)

Con exp e materiali da raccogliere il bot che si limita a scappare crolla (estrazioni 20%, livello medio 4,2): conferma che la raccolta è una scelta attiva di rischio. Con il bot aggiornato (raccoglie gli oggetti quando non ha nemici vicini) i numeri tornano a quelli di M4 senza ritoccare i dati: estrazioni 65%, livello medio 8,8, ~31 gelatine per run (20 run). Raggio del magnete lasciato a 90px.

Con i nuovi potenziamenti (#25) il bot sceglie al level-up come un giocatore (prima combattimento: danno, cadenza, Ventaglio, Perforazione, HP). Risultato: **100% di estrazioni** su 20 run, ma lo stesso bot con i soli 5 potenziamenti di M4 fa ugualmente 100% (12 run). Il 63% misurato in M4 dipendeva dalla scelta casuale del bot, non dal gioco. **Da verificare con il playtest umano**: se chi sceglie bene estrae quasi sempre, la run a 120s è troppo facile e va alzata la pressione (ondate o zona più tardi). Non ritoccato ora per non bilanciare contro un bot.
Stress test "rompere tutto": 300 colpi/s × 20 proiettili × perforazione 5 → ~5.800 proiettili attivi, il gioco resta stabile ma la simulazione scende a circa metà velocità su una CPU cloud. Accettato: nessun tetto per scelta; eventuale ottimizzazione (proiettili fusi o fisica più leggera) solo se diventa un problema nel gioco reale.

## 11. Open questions

- Godot version confermata: 4.6 (da project.godot). Se si prevede export mobile o console, valutare per tempo eventuali limitazioni.
- ~~Dimensione sprite definitiva~~ → in M6 si passa alla grafica vettoriale (vedi §8): la domanda non si pone più. Storico: in M4 era stato deciso **16x16**, disegnati a scala 2 (32px a schermo), filtro nearest. Arena 1600x1000 con UI reale: a 32x32 i personaggi sarebbero stati troppo grandi rispetto al campo visivo e alla densità di nemici.
- ~~Persistenza meta-progressione~~ → decisa in M2: `ConfigFile` in `user://` (leggibile, versionato; niente `.tres` caricati da `user://`, che possono eseguire script). Cloud save fuori scope.
- ~~Durata target di una run~~ → M4: **~2–2,5 minuti** fino alla prima estrazione possibile (zona a 120s + 6s di canale); chi resta oltre rischia di più (tetto nemici crescente). Da confermare con playtest umano.

## 12. Processo e versionamento

- Repo GitHub: `danieleadelfio/Wanderloot` (remote `origin`, branch `main`).
- Task tracking: GitHub Issues + Projects, attivo. Una milestone per ogni M del §10; nessun sistema di task parallelo.
- Vedi `docs/BEST_PRACTICES.md` per convenzioni di codice, architettura e testing (GdUnit4). Vedi `docs/CHANGELOG.md` per lo storico modifiche.
- **Regola fissa**: ogni modifica a feature/grafica/scope/genere/gameplay loop va riportata in questo documento (sezione pertinente) e come voce in `docs/CHANGELOG.md`, nello stesso commit della modifica.
