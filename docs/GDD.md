# Wanderloot — Game Design Document (MVP)

Nome del gioco: **Wanderloot** ("wanderlust" + "loot"). Nome di lavoro precedente: FirstAiGame.

Ultimo aggiornamento: 2026-09-24
Engine: Godot 4.6
Stato: MVP completato (M0–M4), post-MVP M5–M7 completati (due arene, nemici a distanza, hub esplorabile) — prossimo: playtest umano, zoom della camera, roadmap v2

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
- Ad ogni level-up: pausa, 3 scelte casuali (pesate) tra potenziamenti d'arma, abilità passive, statistiche. **Reroll (M12, #86)**: bottone che rimescola le scelte con una in meno (minimo 1), scritto sul bottone; max 5 reroll per run (`RunManager.MAX_REROLLS`), condivisi da tutti i level-up della run.
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

- **Stato M10.1 (#51, Contatore)**: nuovo potenziamento (14 totali). **+1 a ogni conteggio di proiettili**: sparo (1 → 2), Anello arcano (6 → 7), Fulmine errante (1 → 2 fulmini su nemici diversi); nessun effetto sulla Barriera arcana. In combo con **Ventaglio**: ogni Ventaglio preso *dopo* aggiunge 1 + Contatori presi (1 → Ventaglio 2 → Contatore 3 → Ventaglio 5 → Contatore 6 → Ventaglio 9). Riga Contatore nelle statistiche.

### 3.2b Consumabili (M10.1, #50)

I nemici possono lasciare **consumabili** (1,2% per uccisione, moltiplicato dal bonus drop; il boss ne lascia 2): oggetti a terra con effetto alla raccolta, attratti dal magnete come exp e materiali, che **non sono loot** (non vanno nel baule). **Magnete**: per 4 s attira tutto ciò che è a terra in tutta l'arena. **Cuore**: cura 2 HP. **Furia**: cadenza +50% per 6 s. Gli effetti a tempo compaiono nell'HUD con i secondi rimasti. Dati in `data/consumables/` (`ConsumableData`, `ConsumableTable` assegnata da `ArenaData.consumables`).

### 3.3 Abilità della bacchetta (M10, #45)

La bacchetta ha **3 slot** di abilità per la run; l'ordine non conta e le abilità si perdono a fine run. Ogni abilità (`WandAbility`, `data/abilities/`) ha un criterio di attivazione: **ricarica** (ogni N secondi), **ogni N colpi** sparati, **ogni N pixel percorsi** o **sempre attiva**; l'effetto è una Resource riusabile (`AbilityEffect`: anello di proiettili, fulmine sul più vicino, barriera). Ogni abilità dà un colore ai proiettili (media dei colori delle abilità presenti). Si ottengono dagli **eventi della run** (§3.4): a evento superato il gioco si ferma e si sceglie tra 3 abilità non ancora possedute; con gli slot pieni si sceglie quale sostituire o si tiene la bacchetta com'è. Nell'HUD, sotto le statistiche, le icone delle abilità si riempiono verso la prossima attivazione. La finestra Inventario/Statistiche dell'hub (`Tabs`, `use_hidden_tabs_for_min_size`) ha sempre la stessa dimensione su entrambe le schede (M12, #86: prima si restringeva sulla scheda Statistiche, più corta dell'Inventario).

| Abilità | Attivazione | Effetto | Colore |
|---|---|---|---|
| Anello arcano | ogni 12 colpi | anello di 6 proiettili con l'arma della run | viola |
| Fulmine errante | ogni 350 px percorsi | fulmine sul nemico più vicino entro 420 px: danno dell'arma + 2 in raggio 70 | azzurro |
| Barriera arcana | ricarica 12 s dopo la rottura (10/8/6 s da Lv5, M12 #86 #18) | annulla N colpi = livello (attiva subito alla presa); alla rottura, onda d'urto che respinge i nemici entro 100px (M12 #86) | oro |

Il catalogo completo (abilità di Magicraft riadattate e originali) è in `docs/catalog/` (§13).

**Colore dei proiettili**: quello dell'**ultima abilità presa o salita di livello** (M12, #86, #15), non più la media di tutte le abilità possedute — con 2+ abilità la media sbiadiva il colore verso il centro invece di restare vivido.

**Scelta al cap (M12, #86, #20)**: se un'abilità offerta è già al cap sbloccato, la carta mostra un **Bag of Resources** (icona sacco, niente Lv→Lv) invece della carta normale — sceglierla dà materiali, non un livello (comportamento già presente in `WandAbilities`, ora visibile anche nella scelta).

#### 3.3.1 Ascensione (meta, M12, #86, #16)

Scheda **Ascensione** nel fabbro (quarta scheda, insieme a Crafting/Fusione/Smontaggio): per ogni abilità del catalogo mostra il **cap sbloccato** attuale (default Lv1) e il costo per alzarlo di 1, fino al tetto assoluto Lv8. Costo in materiali esistenti, crescente col livello target (`Ascension.cost_for()`, logica pura, 7 gradini Lv2→Lv8). Il cap sbloccato è per-abilità e persiste nel salvataggio (`MetaProgression.ascension_caps`); letto a inizio run per impostare `WandAbilities.caps`.

### 3.4 Eventi della run (M10, #46)

A tempi fissi della run (`ArenaData.event_times`) parte un evento scelto tra quelli dell'arena (`RunEventData`, `data/events/`). Al centro in alto compaiono un **titolo grande** e un **sottotitolo di poche parole** con l'obiettivo, e una barra del tempo rimasto. Superato l'evento il gioco si ferma e si sceglie un'abilità della bacchetta tra 3 (§3.3); fallito, compare "Evento fallito" e si continua senza premio.

**Terzo evento, dopo il boss (M11.2, #65)**: sconfitti tutti i boss della run, dopo **10 s** parte un altro evento scelto come gli altri (mai lo stesso dell'ultimo). Una volta per run; se in quel momento c'è già un evento in corso parte appena finisce. Non consuma i tempi fissi di `event_times`. Ritardo in `ArenaData.boss_event_delay` (negativo = disattivato). Nella Cripta con estrazione a 120 s e boss a 140 s gli eventi diventano 3 per chi resta a combattere.

**Tempesta di fulmini** (primo evento): 10 s; un fulmine ogni 0,55 s, annunciato da un cerchio giallo (M11.4, #82: azzurro è solo il Fulmine errante della bacchetta) di 70 px che si riempie in 0,8 s (35% sulla posizione del player, gli altri entro 260 px). Basta un colpo subito, da qualsiasi fonte, per fallire. Cripta: eventi a 35 s e 80 s; Ossario: 30 s e 75 s (anche nella build esportata dopo il fix #85). A ogni tempo si sceglie a caso tra gli eventi dell'arena, senza ripetere l'ultimo.

**Pentagramma di sangue** (M10.2, #53): in un punto a caso (ad almeno 320 px dal player) compare un pentagramma di sangue di 110 px di raggio con **15 candele** attorno; titolo "PENTAGRAMMA DI SANGUE", sottotitolo "Entra nel cerchio di candele" e barra di **20 s**: se il player non entra in tempo l'evento fallisce. Appena entra i mostri aumentano subito del **30%** (almeno 5 in più), il tetto dei vivi sale del 30% e i nuovi mostri compaiono **già in rage**; bisogna restare nel cerchio **15 s** mentre si spegne una candela al secondo. Uscire anche un attimo = fallimento, il pentagramma scompare. Essere colpiti non lo fa fallire. Riuscita: **un boss in più** in questa run (se i boss sono già comparsi arriva subito). Nessuna abilità in premio: la ricompensa è il loot del boss in più. Il catalogo degli eventi pianificati è in `docs/catalog/`.

**Passo d'ombra** (M11.1, #63): per 10 s **non si spara**; il tasto di sparo (o Spazio, tasto destro, A del pad) fa uno **scatto** nella direzione di movimento (o verso il mouse) a 850 px/s per 0,2 s, **invulnerabile** per tutto lo scatto (player semitrasparente azzurro). **6 cariche**, mostrate da un cerchio bianco in 6 spicchi accanto al player: ogni scatto consuma uno spicchio, uno spicchio si ricarica ogni **2 s** (quello in ricarica si riempie dal centro). Come la Tempesta fallisce al primo colpo subito; superato = scelta di un'abilità. Le abilità della bacchetta sempre attive continuano a funzionare. Valori in `data/events/shadow_step.tres` (gruppo *Passo d'ombra*), cariche in `DashCharges` (testata). Nella Cripta e nell'Ossario esce tra i tre eventi (due per run, mai lo stesso due volte di fila).

**Scheletri nell'armadio** (M12, #86; numeri rivisti sempre in #86 dopo feedback): per 10 s compaiono **30 scheletri** su un cerchio di raggio 780 px attorno al player (clampato ai bordi dell'arena come i fulmini della Tempesta); **invulnerabili** (non si possono uccidere, e' un evento di sola schivata: `EnemyData.invulnerable`, i proiettili li attraversano senza consumare perforazione), **non inseguono il player**, camminano a velocita' ridotta (1/3 rispetto alla prima versione) verso il centro del cerchio (punto fisso, non il player che nel frattempo si muove). Come gli altri eventi a tempo, un solo colpo subito da qualsiasi fonte fa fallire l'evento (nessuna ricompensa); gli scheletri stessi non hanno logica speciale, sono un `EnemyData` normale con `target` puntato su un nodo fermo invece che sul player. Superato: si apre un **armadio** (finestra a schermo intero con ante decorative ai lati, manichino della run a sinistra come nell'inventario e fino a **3 pezzi** proposti a destra) con pezzi di equipaggiamento **mai estratti prima in nessuna run**; sceglierne uno lo equipaggia subito per il resto della run (si somma alle stat correnti, non resetta nulla) ed entra nel loot a rischio come un drop normale: **si perde se si muore senza estrarre**, resta nel baule solo estraendo. Se non ci sono più pezzi mai visti, l'armadio è vuoto (nessuna scelta). "Mai estratto" è tracciato per pezzo base (`MetaProgression.discovered_equipment`, persistito) e si marca **solo all'estrazione riuscita**, mai al semplice pickup o al crafting: morire con un pezzo nuovo senza estrarre lo lascia "da scoprire" per un futuro armadio. Valori in `data/events/skeletons_closet.tres` (gruppo *Scheletri nell'armadio*). Nella Cripta e nell'Ossario esce tra gli eventi disponibili.

### 3.5 Tutorial contestuale (M12, #86)

Nessun tutorial a schermo intero da chiudere prima di giocare: ogni pezzo compare **una sola volta**, nel momento in cui serve, e non torna piu' finche' il salvataggio esiste (`MetaProgression.tutorials_seen`, chiave per pezzo: `hub_intro`, `first_run`, `first_event`, `first_overtime_warning`, `first_overtime`; persistito, azzerato da Nuova partita). Sempre skippabile.

- **Tour della piazza** (`hub_intro`): alla prima volta che si entra nella piazza dopo una nuova partita, la camera si stacca dal player (`Player.set_physics_process(false)`, la camera resta ferma dov'e') e si sposta in sequenza su fabbro, baule e portale con una didascalia (titolo + descrizione breve di cosa fare li'), poi torna sul player. Bottone **Salta tutorial** sempre visibile, in ogni momento interrompe la sequenza e la segna vista. `HubTutorial` (scena + script, `scenes/hub/HubTutorial/`) riceve la sequenza di passi da `Hub._start_hub_tutorial()`, che li costruisce dai tre `Interactable` che hanno `tutorial_title` non vuoto (campo su `Interactable`, cosi' un punto di interazione futuro senza tutorial dedicato viene ignorato automaticamente).
- **Obiettivo della run** (`first_run`): al primo `Arena._ready()` di sempre, un annuncio HUD piu' lungo del solito (7s invece dei ~3s standard) spiega l'obiettivo in una frase: combattere, raccogliere loot, superare gli eventi, l'estrazione che si apre dopo un po' e il rischio di perdere tutto morendo prima di estrarre. Non ripete i tempi esatti (gia' mostrati dal countdown/indicatore di estrazione a schermo): resta concettuale.
- **Evento** (`first_event`) e **avviso di overtime in arrivo** (`first_overtime_warning`, M12 #86, rivisto dopo feedback): a differenza degli altri annunci (`HUD.announce`, sparisce da solo mentre la run continua), la primissima volta la run **si ferma davvero**: `FirstTimeNotice` (`scenes/ui/FirstTimeNotice/`, `process_mode` ALWAYS come `LevelUpChoice`/`AbilityChoice`) mostra la spiegazione a schermo intero e resta in pausa finche' non si preme **Continua** — cosi' si legge con calma invece di rischiare di essere colpiti mentre si legge un banner a scomparsa. Titolo/sottotitolo dell'evento (`_hud.show_event`) restano visibili come sempre sotto. Dalla seconda volta in poi (e nelle run successive) resta il solo annuncio normale a scomparsa.
- **Overtime** (`first_overtime`): al primo ingresso in overtime di sempre (livello 1), l'annuncio normale (`OVERTIME_TITLE`/`OVERTIME_SUB`, che mostra i moltiplicatori del livello) viene preceduto da una spiegazione estesa di cosa sia e come evolve nei livelli successivi, con durata piu' lunga (8s) — resta un annuncio a scomparsa, non ferma la run (l'avviso *precedente*, a 30s/10s dall'overtime, e' quello che si ferma, vedi sopra). Dal secondo livello in poi, o nelle run successive, resta solo l'annuncio normale.

Test solo sulla persistenza (`has_seen_tutorial`/`mark_tutorial_seen`, salvataggio/caricamento) e sulla sequenza del tour (avanzamento, skip, segnale finale con nodi finti); niente sul contenuto testuale o sul posizionamento a schermo (fuori dalla regola di test generale).

## 4. Extraction shooter layer — regole di rischio

- Il loot grezzo vive in un "inventario di run" separato da quello permanente.
  - **Stato M2**: `LootRunInventory` (classe pura `RefCounted`, id materiale → quantità) posseduta da `RunManager.loot`; si svuota a ogni `start_run()` e accetta loot solo a run in corso. Nessun autoload aggiuntivo.
- **Morte prima dell'estrazione = perdita totale del loot di run.** (Regola scelta per l'MVP: nessuna mitigazione parziale, per mantenere la tensione rischio/ricompensa netta.)
  - **Stato M2**: a fine run `Arena` chiama `LootTransfer.resolve()` (logica pura, coperta da test GdUnit4): con esito `EXTRACTED` il loot va in `MetaProgression.deposit_run_loot()` (salvato su disco), con `DEATH` viene scartato; in entrambi i casi l'inventario di run si svuota. La schermata di fine run mostra “Loot estratto: N · Totale nel baule: M” oppure “Loot perso: N”.
- L'estrazione è un punto/area che appare dopo un certo tempo o dopo un trigger (es. uccisione di un'elite), e richiede di rimanere nella zona per N secondi (rischio: i nemici continuano ad arrivare durante il canale).
  - **Stato M1** (`ExtractionData`, `data/run/extraction_default.tres`): la zona (cerchio verde, raggio 48px) appare dopo 60s di run in un punto casuale ad almeno 400px dal player; servono 5s dentro la zona. **Decisione:** uscendo il progresso non si azzera ma cala di 0.5s per ogni secondo fuori (un'uscita breve per schivare non vanifica tutto). HUD: countdown, poi percentuale di estrazione. Da M4 (#20): freccia verde sul bordo dello schermo verso la zona quando è fuori vista (`ExtractionIndicator`).
- **Overtime (M11.1, #62)**: per evitare run infinite, **50 s dopo l'apertura dell'estrazione** si entra in **overtime x1**: **ogni 10 s un'ondata di boss** grande quanto i boss della run (`boss_count` + quelli guadagnati col Pentagramma, anche se superato in overtime: il contatore persiste; M11.2, #66), i nemici nuovi compaiono **già in rage**, **velocità x2** e **vita +25%**. Ogni altri **50 s** il livello sale (x2, x3, …) e i modificatori del livello 1 si moltiplicano per il livello: a xN velocità x2N, vita +25%·N, un boss ogni 10/N s (non sotto 2 s), **tetto dei nemici vivi x1,5·N e ondate 1,5·N volte più frequenti** (M11.4, #84; tetto assoluto 320 nemici per le prestazioni). Già a x3 l'estrazione è quasi impossibile e si perde tutto. Avvisi come per gli eventi a **30 s e 10 s** da ogni livello (allarme a due toni), all'ingresso annuncio rosso con i modificatori e gong; sotto l'estrazione resta la scritta OVERTIME xN. Valori in `data/run/overtime_default.tres` (`OvertimeData`, `ArenaData.overtime`), tempi e livelli in `OvertimeState` (logica pura, testata). Si applica ai nemici nuovi, non a quelli già in vita; i boss dell'overtime lasciano i drop normali.
- Possibile estensione futura (fuori scope MVP): possibilità di estrarre "in anticipo" con meno loot ma meno rischio, o zone a rischio/reward crescente.

## 5. Combattimento (ranged)

- **Vita base del player: 10** (da M11.3, #73; prima 5).
- **Veleno (M11.3, #73)**: alcuni proiettili nemici avvelenano (`WeaponData` gruppo *Veleno*): **1 danno ogni 1,5 s per 4,5 s** (3 danni in tutto). Un nuovo colpo rinnova la durata senza sommare il danno; il player diventa verde finché dura. Logica in `PoisonState` (testata), nodo `Poison` sul player; a inizio run si azzera.

- Player controllato con movimento in 8 direzioni (WASD/stick) + mira libera (mouse o stick destro) — twin-stick style.
- Arma di partenza singola (es. "arco" o "baccheta magica base"), a distanza, con cooldown/fire-rate.
- I proiettili sono sprite semplici (piccoli cerchi/frecce), riutilizzabili via object pooling per performance.
- **Nemici dell'Ossario (M7, #34)**: **Ghoul** (2 HP, velocità 175, rage dopo 4s ×1,25 cioè circa la velocità del player, 1 exp): inseguitore veloce e fragile. **Scheletro arciere** (3 HP, velocità 95, 2 exp): mantiene ~280px dal player (`EnemyMovement.keep_distance`, gira attorno quando è alla distanza giusta) e tira un dardo viola (240px/s, schivabile, ingrandito M12 #86 perche' poco leggibile: `projectile_scale` 0.9 invece del default 0.6) ogni 2,6s entro 420px (primo nemico a distanza: `EnemyProjectile` poolato sul layer `enemy_attack`, unshaded). Entrambi usano `enemy.gd` con comportamento e arma nei dati (`EnemyData`: gruppo Comportamento). Drop: **Frammento d'osso** (comune; ghoul 6%, arciere 10%) ed **Essenza d'ombra** (rara; 0,4% / 1,2%): percentuali basse perché nell'Ossario si uccide molto (~680 nemici per run col bot).
- **Rage (M6, #29)**: un nemico vivo da più di `rage_after` secondi (slime: 5s) va in rage: velocità ×1,8 (era ×1,5, alzata dopo il primo playtest del proprietario), +1 danno da contatto. **M12, #86**: non cambia più colore/texture (si perdeva la tipologia del nemico, specie per gli slime della Cripta); compaiono invece due piccoli fulmini rossi sopra la testa (`RageBody`, sfuma in 0,35s, `assets/sprites/rage_indicator.png`). Si azzera quando il nemico torna nel pool. Valori in `EnemyData` (gruppo Rage). Con lo spawn ad almeno 300px e ~3s per raggiungere il player, quasi tutti i nemici che arrivano a contatto sono in rage: di fatto alza la pressione generale (voluto, vedi §10.3).
- Nemici: pattern semplici (inseguimento diretto, mantenimento distanza + attacco ranged, pattern a pattuglia). Nessuna animazione complessa richiesta: 1-2 frame di movimento + 1 di attacco/morte sono sufficienti in stile pixel art.
- Combat feel gestito via codice: knockback, hit-flash, hitstop leggero, i-frames sul player — nessun bisogno di asset aggiuntivi per "sentire" l'impatto.
- **Stato M4 (#16)**: knockback come componente `Knockback` (spinta che decade, `resistance` 0–1), alimentato da `Hurtbox.knocked`; intensità nei dati (`WeaponData.knockback` 320 → ~40px sullo slime, `EnemyData.contact_knockback` 380 → ~27px sul player, `knockback_resistance`). **Decisione hitstop**: sui colpi ai nemici (molto frequenti) solo freeze locale del nemico colpito (`EnemyData.hit_freeze` 0.05s); hitstop globale (`HitStop`, `Engine.time_scale` 0.05 per 0.08s reali) solo quando il player subisce danno, e `time_scale` viene sempre ripristinato all'uscita dalla scena. I-frames del player ora visibili (lampeggio `Blink`); il knockback da contatto allontana il player dal nemico, quindi il danno ripetuto a contatto diventa raro.
- **Stato M5 (#21)**: nessun tetto alla cadenza di fuoco. Prima l'arma sparava al massimo 1 colpo per tick di fisica (60/s) e l'arrotondamento del cooldown faceva perdere cadenza già da ~30 colpi/s; ora il cooldown è ad accumulatore e nello stesso tick partono tutti i colpi maturati, sfalsati lungo la traiettoria. Scelta di design: gli upgrade possono "rompere" il gioco, è parte del divertimento.
- **Stato M0**: movimento 8 direzioni (WASD/frecce/stick sinistro), mira col mouse tenendo premuto il tasto sinistro oppure stick destro con auto-fire, fire-rate da `WeaponData`. Implementati hit-flash (nemici e player) e i-frames del player (0.8s, danno da contatto ripetuto finché si resta a contatto). Knockback e hitstop rinviati a M4 (rifinitura).

### 5.1 Boss (M8, #38)

**Boss multipli (M10.2)**: `ArenaData.boss_count` (1 nella Cripta) più i boss guadagnati col Pentagramma; compaiono sempre in punti diversi, ad almeno `boss_min_separation` (350 px) l'uno dall'altro e da quelli già vivi (`SpawnUtils.separated_points`). Una sola barra HP con la vita totale e "× N".

Sistema riutilizzabile: un boss è una scena con lo script condiviso `Boss` + un `BossData` (HP, velocità, contatto, exp, drop, attacchi, fase 2) + una lista di `BossAttack` (.tres). Tipi di attacco: **raffica a ventaglio** mirata al player, **anello** di proiettili (con rotazione tra le ripetizioni), **salto schiacciante** sulla posizione del player. Ogni attacco ha un **preavviso**: carica sul posto (cerchio attorno al boss, disattivabile per attacco con `show_windup`) per le raffiche, **cerchio rosso a terra** che si riempie per il salto (`Telegraph`): il bersaglio è fissato all'inizio del preavviso, il player ha `telegraph_time + leap_time` per uscirne; a fine riempimento l'area colpisce per un istante. Dopo ogni attacco il boss recupera (si muove piano: finestra per colpirlo). Sotto `phase_two_threshold` HP entra in fase 2: più veloce, attacchi più ravvicinati, sblocca gli attacchi con `min_phase = 2`, colore alterato. Scelta per peso tra gli attacchi della fase. `ArenaData` (gruppo Boss): scena del boss, secondi di ritardo dall'apertura dell'estrazione (default 20), distanza minima di comparsa. Barra HP del boss in alto al centro. I proiettili del boss usano il pool dei proiettili nemici; `WeaponData` ha texture e scala opzionali del proiettile. Alla morte: exp in 6 gemme e drop come i nemici. Il boss non è poolato (uno per run). **Blocco spawn pre-overtime** (Ossario, M12 #86): mentre sono vivi i boss comparsi *prima* dell'overtime (`arena.boss_delay` dopo l'apertura dell'estrazione), il `WaveSpawner` non genera più nemici base (quelli già in giro restano e vanno uccisi normalmente); lo spawn riprende alla morte dell'ultimo di quei boss, oppure subito all'inizio dell'overtime, che invece mescola sempre boss e nemici base come prima (`WaveSpawner.spawning_blocked`).

- **Inventario di run (M11.4, #80)**: col tasto I a destra compare lo stesso **manichino** dell'hub (solo gli slot, in sola lettura, con tooltip delle statistiche) e accanto il **raccolto in questa run** in una griglia scorrevole alta quanto lo schermo di icone: oggetti col bordo della rarità (tooltip con statistiche e confronto con il pezzo indossato) e materiali con la quantità. **M12, #86**: manichino e griglia sono dentro un `ScrollContainer` (`BodyScroll`) oltre a quello interno della griglia — su schermi bassi o stretti non tagliava più il manichino, si può scorrere tutto il corpo del pannello. Il manichino qui è al **50%** (`LoadoutPanel.figure_scale`, M12 #86): a piena dimensione (360×440) il contenuto eccedeva lo schermo anche con lo scroll. Sotto il manichino (hub e run, `LoadoutPanel`), i **livelli totali di ogni abilità** data dai pezzi indossati, sommati come in run (M12, #86).
- **Fine run (M11.3, #68)**: oltre a *Torna all'hub* c'è **Guarda il loot**: apre una griglia di icone con tutto quello che si è raccolto (oggetti col bordo della rarità, dal più raro; materiali con la quantità), tooltip al passaggio del mouse, titolo *Estratto con successo* o *Perso*. *Indietro* torna al riepilogo, *Torna all'hub* è sempre presente. Il riepilogo mostra solo il numero degli oggetti.
- **Slime della Cripta (M11.3, #74)**: gli slime base diventano **celesti**. Con meno frequenza compaiono: **Slime tossico** (verde, con un alone di nube; dal secondo 30, peso 0,18) che spara gocce **avvelenate** (tinta viola/veleno, M12 #86: prima erano confondibili col materiale raccoglibile Gelatina di slime, stesso stile di sprite); **Slime del vuoto** (viola; dal secondo 45, peso 0,15) che spara una sfera: è grande il doppio del normale (M11.4, #83), dopo 200 px si ingrandisce (x2,6), rallenta e **attira il player** entro 360 px (tetto alla somma di più sfere vicine, `Player.MAX_PULL_FORCE`, M12 #86: senza, più Slime del vuoto ravvicinati sommavano l'attrazione senza limite e rendevano la fuga impossibile); **Slime di pietra** (grigio; dal secondo 20, peso 0,22), non spara, **vita x4** e **velocità /2** rispetto al celeste, resiste alla spinta. Tossico e vuoto hanno **vita x2** e la stessa velocità del celeste. Dati in `data/enemies/slime_*.tres`, armi in `data/weapons/toxic_glob.tres` e `void_orb.tres` (gruppo *Buco nero* di `WeaponData`).
- **Negromante (M11.3, #76)**, boss dell'Ossario (uno a caso tra i boss dell'arena, 20 s dopo l'apertura dell'estrazione): 450×2 = 900 HP, lento (60), **si teletrasporta dopo quasi ogni attacco** (ricompare ad almeno 300 px). Moveset: **Anello di teschi** (3 anelli da 12 rotanti), **Sguardo** (2 ventagli da 5), **Richiamo degli arcieri** (3 Scheletri arcieri) e **dei ghoul** (4 Ghoul), in fase 2 **Pioggia d'ossa** (7 cerchi rossi da 70 px, uno sul player, 1,1 s di preavviso, danno 2). Drop: 18–26 Frammenti d'osso, 3–5 Essenze d'ombra.
- **Colosso d'ossa (M11.3, #77)**, boss dell'Ossario: 600×2 = 1200 HP, lentissimo (55), contatto 3 con spinta forte. Moveset: **Carica** (corsia arancione per 1,1 s, poi corsa di 600 px a 760 px/s, si ferma contro i muri), **Pestone** (cerchio di 150 px attorno a sé, danno 2, poi 14 spuntoni d'osso a raggiera), **Raggiera d'ossa** (2 anelli da 16); in fase 2 **Doppia carica** più rapida e all'ingresso in fase 2 **perde pezzi**: 4 Scheletri arcieri. Drop: 25–35 Frammenti d'osso, 2–4 Essenze d'ombra.
- **Regina dei Ghoul (M11.3, #78)**, boss dell'Ossario: 380×2 = 760 HP, veloce (150). Moveset: **Balzi a catena** (3 salti di fila sul player, cerchi da 100 px: 0,8 s di preavviso il primo, 0,55 s i successivi), **Graffio** (2 ventagli ravvicinati da 7 artigliate a corto raggio), **Urlo** (tutti i nemici vivi in rage), in fase 2 **Richiamo del branco** (5 Ghoul) e 4 Ghoul all'ingresso in fase 2. Drop: 16–24 Frammenti d'osso, 4–6 Essenze d'ombra.
- **Sistema boss esteso (M11.3, #75)**: nuovi tipi di attacco, tutti da dati: **SUMMON** (evoca `summon_count` nemici della scena `summon_scene`, presa dai nemici dell'arena), **RAIN** (`rain_count` cerchi rossi, il primo sul player, gli altri entro `rain_spread`), **CHARGE** (corsa in linea verso dove era il player, corsia segnata da cerchi per tutto il preavviso), **STOMP** (cerchio sul boss stesso, poi anello di proiettili), **SCREAM** (tutti i nemici vivi in rage); **LEAP_SLAM** con `repeats` > 1 = balzi a catena (preavviso dei successivi = `repeat_interval`); `teleport_after` su qualsiasi attacco = il boss svanisce e ricompare ad almeno `teleport_distance` dal player; `BossData.phase_two_summon_*` = evocazione all'ingresso in fase 2. `ArenaData.boss_scenes`: più boss possibili, uno a caso per ogni comparsa (anche le ondate dell'overtime e i boss del Pentagramma); la barra mostra i nomi dei boss presenti. **La vita di tutti i boss è x2** (`Boss.HP_MULTIPLIER`, vale anche per i boss futuri): il Re Slime passa da 400 a 800 HP.
- **Stato M8 (#39, Re Slime)**: primo boss, nella **Cripta**, compare **20 s dopo l'apertura della zona di estrazione** (chi estrae subito non lo incontra: è la sfida per chi resta). 400 HP, lento (80), contatto 2. Moveset: **Raffica di gelatina** (3 ventagli da 5 mirati, 0,7 s di pausa senza cerchio: si legge dal boss che si ferma), **Anello di gelatina** (2 anelli da 14 sfalsati), **Salto reale** (cerchio rosso di 140 px sulla posizione del player, 1,1 s di preavviso + 0,5 s di salto; all'impatto danno 2 e anello da 10). **Fase 2** sotto il 50% HP: +25% velocità, pause −30%, sblocca la **Spirale furiosa** (6 anelli rotanti da 10). Drop garantiti: 12–18 Gelatina, 3–5 Nuclei, 40 exp. Proiettili: palle di gelatina lente (220 px/s) e ben visibili.

## 6. Loot e crafting (scope MVP)

- I nemici droppano: exp (sempre) + eventualmente 1 tipo di materiale comune.
- Rari drop: pezzo di equipaggiamento grezzo (non identificato/non equipaggiabile finché non estratto).
- **Stato M2 (dati)**: `MaterialData` (id, nome, rarità comune/raro, colore placeholder) in `data/materials/`; drop table come array di `DropEntry` (materiale, probabilità, quantità min/max) dentro `EnemyData`, ogni riga tirata indipendentemente. Slime: Gelatina (comune) 35% ×1–2, Nucleo di slime (raro) 3% ×1. L'equipaggiamento grezzo arriva con M3 (crafting/equip), in M2 solo materiali.
- ~~Stato M2 (drop)~~: il loot andava direttamente nell'inventario di run. **Sostituito in M5 (#22)**: alla morte il nemico lascia a terra una gemma di exp (blu) e i materiali tirati dalla drop table (icona del materiale). Entro `PlayerStats.pickup_radius` (90px) vengono attratti verso il player con accelerazione (effetto magnete) e assorbiti al contatto, con due suoni distinti (`pickup_exp`, `pickup_item`). Exp e loot contano solo quando assorbiti; ciò che resta a terra a fine run è perso. Pool e movimento in `PickupPool` (un solo `_physics_process` per tutti gli oggetti), coperto da test. HUD: "Loot a rischio: N" in ambra.
- Crafting MVP: sistema semplice "materiali → oggetto", con ricette fisse (niente crafting proceduralmente generato in v1).
- Equipaggiamento MVP: slot minimi (arma, 1 accessorio) per non esplodere lo scope.
- **Stato M3 (#12, dati)**: `EquipmentData` (id, nome, descrizione, slot `WEAPON`/`ACCESSORY`, lista di `StatModifier`) in `data/equipment/`, tutti elencati in `EquipmentCatalog` (risolve gli id salvati). `StatModifier` riusa l'enum di `UpgradeData.Stat` (danno, cadenza, velocità proiettili, movimento, HP max). Pezzi iniziali: Bacchetta di gelatina (+1 danno), Bacchetta rapida (+25% cadenza), Amuleto del nucleo (+2 HP), Stivali viscosi (+10% movimento). **Decisione**: lo slot arma modifica la bacchetta base, non la sostituisce (nuovi tipi di arma: v2). L'equipaggiamento grezzo droppato in run resta fuori dall'MVP: i pezzi si ottengono solo col crafting.
- `EquipmentLoadout` (logica pura, in `MetaProgression.loadout`): pezzi posseduti per id, un pezzo equipaggiato per slot; si può equipaggiare solo ciò che si possiede.

### 6.0 Oggetti unici (M11, #55)

Ogni oggetto posseduto è un'**istanza** (`ItemInstance`): oggetto base (`EquipmentData`), rarità, bonus tirati e, da Super raro in su, un'abilità. Si possono avere più copie dello stesso oggetto: il fabbro crafta anche duplicati (serve per la fusione). `EquipmentLoadout` tiene tutte le istanze per `uid` e l'istanza indossata per slot; a inizio run si applicano i modificatori di base + i bonus di ogni pezzo indossato. **Salvataggio v5**: sezione `[items]` (uid → oggetto base, rarità, bonus, abilità) e `[equipped]` (slot → uid). I salvataggi v2–v4 si convertono: ogni pezzo posseduto diventa un'istanza Comune e resta equipaggiato.

### 6.1 Slot dell'equipaggiamento (M11, #56)

Slot: **Testa, Guanti, Armatura, Pantaloni, Stivali, Anello (×2), Amuleto** e **Bacchetta** (l'arma, che porta anche gli slot delle abilità). Gli oggetti esistenti passano agli slot nuovi: bacchette → Bacchetta, Stivali viscosi → Stivali, Amuleto del nucleo → Amuleto. Nell'inventario dell'hub un **manichino** mostra gli slot con l'icona dell'oggetto indossato: **clic su un oggetto** del baule → va nel suo slot (sostituendo quello presente); **clic su uno slot occupato** → l'oggetto torna nel baule. I due anelli si riempiono in ordine (il secondo clic su un anello va nello slot libero, poi sostituisce il primo). Nuovi oggetti base: Cappuccio del viandante (Testa), Guanti del fabbro (Guanti), Corazza d'osso (Armatura), Brache di cuoio (Pantaloni), Anello di gelatina (Anello), ognuno con ricetta; gli Stivali viscosi passano allo slot Stivali. Il bordo degli slot e degli oggetti prende il colore della rarità (§6.2).

Gli oggetti arrivati nel baule (estratti, craftati, fusi) hanno una **N gialla** in alto a destra finché non ci si passa sopra col mouse o li si equipaggia (salvata con l'oggetto). Il menu **Mostra** filtra il baule: Tutti, Nuovi, una rarità, una categoria (M11.4, #81). Il baule degli oggetti si ordina con tre bottoni sopra la griglia: **Arrivo** (dal più vecchio), **Rarità** (dal più raro, poi per slot) e **Categoria** (per slot: bacchetta, amuleto, testa, guanti, armatura, pantaloni, stivali, anelli; poi dal più raro). La scelta resta finché il gioco è aperto (`StashSort`, M11.3 #69).

**Tooltip (M11.3, #70; M11.4 #79: intervalli in bianco, sfondo quasi opaco dal tema `data/ui/wanderloot_theme.tres`)**: passando su un oggetto del baule compare accanto il pezzo equipaggiato nello stesso slot (per gli anelli entrambi), per il confronto. Ogni bonus tirato mostra l'**intervallo possibile per la sua rarità**, es. *+13% Vel. proiettile (+10% – +20%)*: si vede subito se il tiro è vicino al minimo o al massimo. L'intervallo è quello del bonus in `affix_table.tres` letto tra `roll_min` e `roll_max` della rarità.

**Livelli delle abilità (M11.3, #72)**: ogni abilità della bacchetta ha un livello. Gli oggetti la portano a **Lv1 (Super raro), Lv2 (Leggendario), Lv3 (Mitico)** (`ability_level` in `rarity_table.tres`). La stessa abilità da più pezzi o da un evento **si somma**: non si duplica e non sparisce dalle scelte; gli eventi propongono tutte le abilità, e per quelle già possedute la scelta mostra *Lv2 → Lv3* e non occupa uno slot. Effetto del livello: Fulmine errante = un fulmine per livello; Anello arcano = +5 proiettili per livello; Barriera arcana = un colpo assorbito per livello, e da Lv5 anche ricarica ridotta (12 → 10 → 8 → 6 s, M12 #86 #18; `WandAbility.cooldown_by_level`). Nell'HUD il numero del livello compare sull'icona (da Lv2). **Livello massimo assoluto: LV8** (M12, #86, #19; `WandAbility.MAX_LEVEL`), invalicabile da qualunque fonte — `WandAbilities.level_up()`/`equip_bonus()` clampano sempre. **Cap sbloccato di default: Lv1** (M12, #86, #20): senza Ascensione (§3.3.1) un'abilità non supera Lv1 in run, anche presa più volte da equip o eventi; l'eccedenza diventa un **Bag of Resources** (materiali, quantità = livelli in eccesso × 10) invece del livello. **Futuro (M12)**: Leggendari e Mitici avranno anche abilità **uniche**, che non si trovano in run.

### 6.2 Rarità (M11, #57)

| Rarità | Colore | Drop tra gli oggetti trovati | Contenuto |
|---|---|---|---|
| Comune | grigio | 60% | statistiche base (1 bonus) |
| Non comune | verde | 25% | 2 bonus migliori |
| Raro | blu | 10% | 3 bonus alti |
| Super raro | viola | 4% | 3 bonus + **1 modificatore di gameplay casuale** |
| Leggendario | arancio | 1% | 4 bonus alti + **1 modificatore forte casuale** |
| Mitico | rosso | non si trova | 4 bonus massimi + **poteri fissi della ricetta** |

Le rarità sono in `data/equipment/rarity_table.tres` (colore, numero di bonus, qualità dei tiri `roll_min`–`roll_max`, abilità, peso di drop, moltiplicatore dello smontaggio); i bonus possibili in `data/equipment/affix_table.tres` (statistica, intervallo, tipi di oggetto ammessi, peso). Un oggetto non tira mai due volte la stessa statistica, né una statistica che ha già tra i bonus fissi dell'oggetto base (M11.3, #71: una Bacchetta rapida non può tirare *Cadenza di fuoco*); le statistiche intere (danno, HP, proiettili, perforazione) si arrotondano. Il craft dal fabbro dà un Comune con 1 bonus tirato: due craft dello stesso oggetto sono diversi. L'abilità di Super raro e superiori è una delle abilità della bacchetta, **sempre attiva per tutta la run**, fuori dai 3 slot (e non viene più offerta dagli eventi). Il nome e il bordo degli oggetti hanno il colore della rarità; il tooltip mostra rarità, bonus e abilità. Percentuali indicative, da bilanciare col bot. Ogni oggetto diventa un'**istanza unica** (id, oggetto base, rarità, bonus tirati) invece di un id di catalogo. I bonus sono tirati dentro intervalli che crescono con la rarità (`StatModifier` con minimo/massimo per rarità). I modificatori di Super raro e Leggendario vengono dalla lista delle abilità (§3.3, catalogo): lo stesso effetto (`AbilityEffect`) sempre attivo o potenziato, così i due sistemi non si duplicano.

### 6.3 Drop in run (M11, #58), fusione e smontaggio (M11, #59)

Statistiche base, range dei bonus per rarità e tasso di drop per arena di ogni pezzo: `docs/EQUIP_INFO.md` (M12, #86), aggiornato a ogni nuovo pezzo introdotto.

- In run i nemici possono lasciare oggetti da Comune a **Leggendario** (probabilità bassa per uccisione, più alta per il boss). Sono **loot a rischio** come i materiali: si tengono solo estraendo.
- Tabella per arena in `ArenaData.item_drops` (`data/equipment/drops_<arena>.tres`, `ItemDropTable`): oggetti possibili, `drop_chance` per uccisione (Cripta 0,4 %, Ossario 0,6 %, × bonus drop), `max_tier` (4 = Leggendario), `boss_drops` (1 per boss) con `boss_min_tier` (2 = Raro). La rarità si tira coi pesi `drop_weight` di `rarity_table.tres`; bonus e abilità si tirano quando l'oggetto cade.
- A terra l'oggetto ha la sua icona tinta col colore della rarità e un **alone pulsante** dello stesso colore, più grande per le rarità alte (`glow_scale` 1 → 2,3); quando cade parte un **suono per rarità** (`drop_sound`), sempre più epico: rintocco (Comune), due note, arpeggio (Raro), arpeggio con scintillio (Super raro), fanfara con colpo di basso (Leggendario), fanfara con coro e doppio colpo (Mitico). Si raccoglie col magnete; nell'inventario di run (I) compare tra il loot a rischio con tooltip; a fine run la schermata elenca gli oggetti portati in salvo o persi. Estraendo entrano nel baule dell'hub come istanze nuove.
- **Fusione dal fabbro**: tre oggetti **identici** (stesso oggetto base) della **stessa rarità** → uno della rarità successiva, con bonus e modificatore ritirati. Si sale fino a Leggendario; il Mitico non si ottiene per fusione. (M12, #86: prima ne bastavano due.)
- **Smontaggio** di un oggetto in materiali (quantità crescente con la rarità), per gestire il baule. **In lavorazione (#60):** non deve restituire i materiali che si trovano in run (se ne raccolgono centinaia); darà materiali **ottenibili solo smontando**, ingredienti di altre ricette (quali, da definire). Per ora la scheda mostra gli oggetti con la scritta *Work in progress* e i pulsanti disattivati (`Blacksmith.salvage_enabled = false`); la logica in `Forge` resta, con la resa provvisoria descritta sotto.
- Il fabbro ha tre schede: **Crafting**, **Fusione**, **Smontaggio**. Fusione e smontaggio valgono solo per oggetti nel baule (non equipaggiati). La fusione elenca i terzetti disponibili (stesso oggetto, stessa rarità, sotto Leggendario, `Forge.FUSION_COUNT = 3`) e fonde i primi tre; il risultato è un oggetto nuovo tirato alla rarità successiva. Lo smontaggio rende `max(1, floor(costo ricetta × 25 % × salvage_multiplier))` per ogni materiale della ricetta (Comune ×1, Non comune ×2, Raro ×3, Super raro ×5, Leggendario ×8, Mitico ×12); es. Bacchetta di gelatina (25 Gelatina): Comune 6, Leggendario 50. Lo smontaggio chiede conferma (secondo clic). Logica in `scripts/meta/forge.gd`.

### 6.3b Livello arena da potenza dell'equip (M12, #86)

L'equip indossato all'**inizio della run** (hub, non cambia con l'armadio degli Scheletri: non e' equip permanente) determina un **livello arena da 1 a 5**, letto una volta come i modificatori dell'equip. Formula: **livello = tier piu' alto T (1=Comune...6=Mitico) per cui si hanno almeno 4 pezzi equipaggiati di tier >= T**, il massimo T soddisfatto (livello 1 se nessuna soglia e' raggiunta). In pratica: **4 Comuni -> livello 2**, **4 Non comuni -> livello 3**, **4 Rari -> livello 4**, **4 Super rari -> livello 5**; con 4 Leggendari o 4 Mitici la formula darebbe 6/7 ma il gioco definisce effetti solo fino al **livello 5** (tetto, `ArenaLevel.MAX_LEVEL`). Logica pura in `scripts/meta/arena_level.gd`, testata.

Effetti, tutti ereditati da ogni arena (nessun codice per arena):

- **Vita dei nemici nuovi**: ×1,5 per ogni livello sopra il primo (livello 5 = ×5,0625). Si moltiplica con l'hp_multiplier() dell'overtime, indipendenti tra loro.
- **Ritmo di spawn**: +10% per ogni livello sopra il primo (livello 5 = +40%). Si moltiplica con lo spawn_rate_multiplier() dell'overtime.
- **Boss**: +1 per ogni livello sopra il primo, sommato a `ArenaData.boss_count` e ai boss guadagnati dal Pentagramma di sangue (nessuno dei tre sostituisce gli altri).
- **Rarita' massima dei drop**: livello 1 = solo Comune; livello 2 = +Non comune; livello 3 = +Raro; livello 4 = +Super raro; livello 5 = +Leggendario (il Mitico non droppa mai in run, invariato). Il tetto naturale di `ItemDropTable.max_tier` dell'arena resta un limite ulteriore: un'arena puo' scegliere di non arrivare mai a Leggendario anche a livello 5. Le probabilita' relative tra le rarita' sbloccate restano quelle di `rarity_table.tres` (`drop_weight`): la rarita' piu' alta sbloccata resta comunque la meno probabile, senza tabelle separate per livello.

Non ha ancora un'indicazione a schermo (open question): il player non vede il livello raggiunto durante la run.

### 6.4 Mitici (progetto M12)

- Si craftano solo da una **ricetta mitica**, che si sblocca dai **boss** (drop raro della ricetta; una volta sbloccata resta per sempre e si può usare più volte).
- La ricetta fissa **oggetto e poteri**; a ogni craft si ritirano i **valori** dentro intervalli ampi (es. Danno da +1 a +10).
- Costo volutamente alto, **non più facile che trovare un Leggendario**: **materiali composti** (ottenuti dal fabbro unendo altri materiali, es. Gelatina reale = Gelatina + Nuclei + drop del boss) e grandi quantità di risorse di più arene.
- Esempio: **Corona del Re Slime** (Testa, dal Re Slime): ogni 16 s *Salto del Re* sotto il cursore; bonus a vita e danno tirati a ogni craft.

## 7. Hub centrale (scope MVP)

Per l'MVP, hub ridotto a:
- **1 NPC "Fabbro/Blacksmith"**: crafting base e potenziamento equipaggiamento con i materiali estratti.
  - **Stato M3 (#13)**: pannello "Fabbro" nell'hub con le ricette fisse di `data/recipes/recipe_book.tres` (`RecipeData`: risultato + righe `MaterialCost`). Costi iniziali: Bacchetta di gelatina 6 Gelatina, Stivali viscosi 8 Gelatina, Bacchetta rapida 10 Gelatina + 1 Nucleo, Amuleto del nucleo 4 Gelatina + 2 Nuclei. Bottone disabilitato se mancano materiali o il pezzo è già posseduto. **Decisione**: ogni pezzo si crafta una sola volta (niente duplicati né potenziamento nell'MVP: potenziamento/smontaggio in v2). Regole in `Crafting` (logica pura); `MetaProgression.craft()` è l'unico punto che scala i materiali e salva. **M12, #86**: le risorse possedute sono sempre visibili sopra le schede del pannello (prima bisognava controllare il baule per sapere cosa si poteva craftare).
- **1 baule/inventario permanente**: dove finisce il loot dopo un'estrazione riuscita.
- **1 portale/punto di partenza run**.
- Portale: l'arena scelta resta evidenziata (bottone premuto) e con il focus anche dopo il cambio di scelta (M11.3, #67).
- **Stato M7 (#33, Ossario)**: seconda arena, si sblocca dopo **3 estrazioni riuscite nella Cripta**. Buio quasi totale (ambiente 0.19, 0.16, 0.22: ancora abbastanza per leggere i nemici), luce del player più corta, niente torce ma 12 candele rosse tremolanti, nebbia viola che scorre (`FogDrift`), pavimento di lastre scure con crepe e macchie di sangue, muri con teschi, 34 decorazioni (teschi, ossa, costole, lapidi, sangue). Musica: bordone dissonante, campana lontana e battito (`music_ossuary`, loop di 24s). Ondate più dure (`wave_ossuary.tres`: tetto 55, fase avanzata da 50s), estrazione a 120s con canale di 7s e zona ad almeno 450px. Nemici: Ghoul dall'inizio, Scheletro arciere dal secondo 15. Ricompensa: **Bacchetta d'ossa** (arma, +1 danno e +1 perforazione) = 40 Frammenti d'osso + 6 Essenze d'ombra.
- **Stato M7 (#32, arene)**: ogni arena è un `ArenaData` (`data/arenas/`): pavimento, muri, luce ambiente e del player, torce, musica, `WaveData`, `ExtractionData` e lista di `EnemySpawn` (scena, peso, da che secondo compare). `Arena.tscn` è una sola scena che si configura dall'arena scelta; il `WaveSpawner` crea un pool per tipo di nemico e sceglie il tipo per peso. Il portale (pannello nell'hub) mostra le arene: quelle bloccate indicano quante estrazioni servono e in quale arena. `MetaProgression` salva estrazioni riuscite per arena e arena scelta (salvataggio v3, carica v1/v2). Prima arena: **Cripta**, sempre disponibile.
- **Stato M8 (#37, menu iniziale)**: il gioco parte da `scenes/menu/MainMenu/` (scena principale): **Continua** (solo se esiste un salvataggio: carica e va all'hub), **Nuova partita** (stato vuoto in memoria; il file resta finché non si salva), **Opzioni** (volume Musica ed Effetti 0–100% su scala logaritmica sopra i valori del bus layout, salvati subito in `user://settings.cfg` e applicati all'avvio da `AudioSettings`; **Opzione per mancini** (M12 #86, corretta #86 dopo feedback): scambia i tasti del mouse di sparo/scatto (default sinistro=spara, destro=scatto → sinistro=scatto, destro=spara), tastiera e pad invariati; checkbox con contorno bianco per essere visibile; salvato in `user://settings.cfg` sezione `input` e applicato subito da `InputSettings`; **Cancella dati salvati** con doppia conferma), **Esci**. Il menu di pausa aggiunge **Torna al menu** (abbandona la run; con modifiche non salvate chiede una seconda pressione, in un'etichetta di stato a size fissa — M12 #86 — così il menu non cambia più dimensione quando compare).
- **Stato M9 (#44, lingue)**: italiano, inglese, francese e spagnolo. Tutti i testi (scene, dati, codice) sono chiavi di traduzione in `data/i18n/strings.csv` (colonne `keys,it,en,fr,es`, importato da Godot come `.translation`). La lingua si sceglie nelle Opzioni (menu iniziale e pausa); a partita avviata il cambio **salva la partita** (dalla piazza anche la posizione, in run solo i progressi permanenti) e **torna al menu iniziale** con la nuova lingua. La lingua è salvata nel file impostazioni (`user://settings.cfg`, sezione `general`) e riapplicata all'avvio, quindi resta anche senza salvare la partita; al primo avvio si usa la lingua del sistema se supportata, altrimenti l'inglese.
- **Stato M9 (#43, opzioni in pausa)**: il menu di pausa (run e hub) ha la voce **Opzioni** con lo stesso pannello del menu iniziale (`scenes/ui/OptionsPanel/`, unico e riusato); Cancella dati solo nel menu iniziale. ESC o Indietro tornano al menu di pausa.
- **Stato M9 (#42, statistiche e inventario)**: in run, sotto HP/EXP/loot a sinistra, le **statistiche del personaggio** (vita, velocità, danno, cadenza, proiettili, perforazione, velocità e durata del proiettile, spinta, magnete, invulnerabilità, bonus exp e drop), aggiornate a ogni potenziamento. Nell'hub la finestra del baule diventa **Inventario** con due schede: *Inventario* (baule + equipaggiamento) e *Statistiche* (valori base + equipaggiamento). Si apre con **I** (scheda Inventario), **C** (Statistiche), dalle **icone cliccabili in alto a destra** (solo nell'hub) o con E sul baule; stesso tasto chiude, l'altro cambia scheda. Righe calcolate da `StatSheet` (logica pura). **M12, #86**: righe a **tre numeri** (`StatSheet.equip_rows`/`fill_with_equip`, 4 colonne): valore **base** di partenza (giallo, fisso, mai equip né potenziamenti), **bonus dell'equip indossato** (verde, % rispetto alla base — assoluto nel formato della statistica se la base è zero, es. Invulnerabilità), valore **finale** (bianco). In HUD e nell'inventario di run il finale include anche i potenziamenti di livello; nella scheda Statistiche dell'hub finale = base + solo equip (nessun potenziamento fuori run). **Inventario di run ridisegnato (M12, #86)**: da pannello sulla meta' destra (con manichino, statistiche e loot affiancati in una riga che si sovrapponeva su schermi stretti) a **pagina a tutto schermo identica alla finestra Inventario dell'hub** (stesso Panel 1080px, stesso TabContainer a due schede). Scheda *Inventario*: a sinistra il loot raccolto nella run (a rischio, si perde se muori) al posto del baule dell'hub, a destra il manichino in sola lettura (livelli abilita' inclusi). Scheda *Statistiche*: valori live con i potenziamenti di run. Stesso riepilogo aggiunto anche all'inventario di run (tasto I), che prima non aveva una vista statistiche. In HUD (font ridotto a 11px, M12 #86) il riepilogo si aggiorna in tempo reale a ogni level-up (`StatSheet.run_rows`, non solo `equip_rows`): bonus e finale includono anche i potenziamenti di run, con un suffisso **"*"** su bonus e finale quando quella statistica va oltre il solo equip, per distinguere a colpo d'occhio cosa viene dall'equip e cosa da una scelta fatta in run; a run finita (hub) il riepilogo torna equip-only, senza asterischi (M12, #86).
- **Stato M9 (#41, posizione)**: salvando dalla piazza si memorizza anche la posizione del player (salvataggio v4, sezione `[hub]`); Carica e Continua lo rimettono lì. Salvando in run la posizione non si salva: al caricamento si riparte dall'ingresso della piazza. Salvataggi v1–v3 si caricano senza posizione.
- **Stato M8 (#36, salvataggi)**: `MetaProgression` lavora in memoria; su disco (`user://save.cfg`, formato v3) si scrive con **Salva** nel menu di pausa (ESC), disponibile in run e nella piazza (ESC senza finestre aperte), oppure **in automatico** (M12, #86: `MetaProgression.autosave()`, stessa scrittura di `save_game()`) a ogni fine run, successo o game over, prima di tornare all'hub; l'hub mostra per ~2s la scritta "Salvataggio automatico..." (`AutosaveToast`) al suo `_ready()`. Menu di pausa: Riprendi, Salva, Carica (disattivato senza salvataggio); P resta la pausa diretta in run. Salvare in run salva lo stato permanente (baule, equipaggiamento, estrazioni, arena scelta): il loot della run in corso resta a rischio e non viene salvato. **Carica** ricarica il file e torna all'hub, abbandonando la run in corso (`RunManager.abort_run()`, nessun esito). Il vecchio file dei salvataggi automatici (`user://meta_progression.cfg`) viene cancellato all'avvio: si riparte da zero. Azioni condivise in `GameSession` (logica di sessione, nessun autoload nuovo).
- **Stato M12 (#86, Abbandona Run)**: il menu di pausa in run aggiunge **Abbandona Run** tra Carica e Opzioni: come Carica/Torna al menu abbandona la run in corso (`RunManager.abort_run()`, nessun esito, loot non estratto perso) ma torna alla piazza invece che al menu iniziale. Nascosto nel menu di pausa della piazza (`PauseMenu.set_can_abandon`), dove non c'è nulla da abbandonare.
- **Stato M12 (#86, Codex)**: manuale consultabile in ogni momento dalla piazza (icona libro accanto a baule/statistiche, `CodexIcon` in `UI/MenuIcons`), a differenza del tour di `HubTutorial` (§3.5) che è un'introduzione animata una tantum. Finestra a due colonne (`CodexWindow`, `scenes/hub/Codex/`): lista a sinistra raggruppata per sezione, testo a destra della voce selezionata. Contenuto statico (non legato a scoperte/salvataggio) in `CodexData` (logica pura, solo chiavi di traduzione): **Strutture** (Fabbro, Baule, Portale — cosa fanno), **Eventi** (i quattro eventi di run: Tempesta di fulmini, Pentagramma di sangue, Passo d'ombra, Scheletri nell'armadio — trigger, obiettivo, ricompensa), **Equipaggiamento e potenza** (le sei rarità e il livello arena), **Estrazione e overtime** (regole del punto di estrazione e dell'overtime). Distinto dall'Enciclopedia sbloccabile per scoperta descritta al §13 (progetto non ancora avviato): quella mostrerà i dati effettivi del gioco (abilità, oggetti, nemici) sbloccati incontrandoli, il Codex è un riferimento statico sempre completo, scritto a mano.
- **Stato M7 (#35, piazza)**: l'hub è una **piazza all'aperto esplorabile** (`Hub.tscn`, Node2D): pavimento in ciottoli, fontana al centro, forgia (tetto rosso) e magazzino (tetto blu) sul lato nord, alberi ai bordi, 8 lampioni, portale ad arco con vortice viola al lato sud. Atmosfera serale (`CanvasModulate` 0.52, 0.49, 0.68 e luci calde dei lampioni). Il player (stessa scena della run, `weapon_enabled = false`) cammina nella piazza; camera con zoom 0,85 e limiti sulla piazza. Tre punti di interazione (`Interactable`, Area2D sul layer del player) con suggerimento "E — …": **incudine del fabbro** → finestra Fabbro, **baule** davanti al magazzino → finestra Baule + Equipaggiamento, **portale** → finestra Portale (scelta dell'arena + "Attraversa il portale"). Con una finestra aperta il mondo è in pausa (nodo `World` pausabile, hub e UI sempre attivi); ESC o E la chiude. Nuova azione di input `interact` (E, pad X). Asset generati da `tools/sprites.py` (`build_hub`; M12, #86: `plaza_floor` a griglia fissa 48px, seamless in tiling su entrambi gli assi — lastre a larghezza casuale lasciavano una cucitura visibile ogni 384px). **Supera la decisione M3 (#11)** sull'hub solo menu.
- ~~Stato M3 (#11)~~ (superato in M7, #35): l'hub è una schermata UI (`scenes/hub/Hub/`), non ancora un ambiente esplorabile: pannello "Baule" con i materiali permanenti e bottone "Parti per la run". È la scena principale del gioco. A fine run (morte o estrazione) "Torna all'hub" sostituisce "Nuova run". **Decisione**: hub esplorabile con NPC fisici rinviato (M4 o v2), per l'MVP conta il ciclo hub→run→hub. Cambi scena via `change_scene_to_file` con percorsi in `SceneRoutes` (nessun autoload aggiuntivo).

Fuori scope MVP ma parte della visione a lungo termine (da aggiungere per fasi successive): NPC mercante (compra/vendi), NPC alchimista (pozioni/buff), strutture che si sbloccano con la progressione (nuova ala dell'hub, arena di addestramento, ecc.), più tipi di run/arena, più armi ranged ed elite/boss.

## 8. Arte e stile

- Stile (da M6): **grafica vettoriale** con contorno scuro, sfumature e ombre morbide. Sorgenti SVG in `assets/art/`, PNG esportati a 2x della dimensione a schermo in `assets/sprites/`, Sprite2D a scala 0.5 con filtro lineare. ~~Pixel art 16x16/32x32~~: abbandonata in M6 dopo il confronto 16/32/64/vettoriale, per nitidezza a qualsiasi zoom e schermo intero e per un migliore rapporto qualità/costo di produzione degli asset generati.
- Palette limitata (4-8 colori dominanti) per coerenza visiva e per ridurre il lavoro di produzione asset.
- Fonte asset consigliata: pacchetti pronti stile Kenney.nl (gratuiti) o pacchetti a pagamento coerenti (es. "Tiny Dungeon", "Cute Fantasy RPG") su itch.io, integrati con generazione AI mirata (sprite singoli, icone oggetti, tileset) per colmare i buchi specifici del proprio gioco.
- Nessuna animazione complessa richiesta per l'MVP: idle, movimento (2-4 frame), attacco, hit, morte per player e nemici base.

- **Stato M6 (#28)**: pavimento a lastre (tile di 192px di mondo, 3x3 lastre con variazioni di tono e crepe) e muri a mattoni vettoriali; icone vettoriali di materiali ed equipaggiamento (64px sorgente, 32px nell'hub, 24px come oggetti a terra). Nessun ostacolo nell'arena per ora: richiede steering o pathfinding per i nemici, da discutere a parte.
- **Stato M12 (#86, shader di movimento ambientale)**: `.gdshader` in `assets/shaders/` invece di sole animazioni GDScript.
  - **Fiamme di torce e candele**: `flame_flicker.gdshader` (canvas_item, unshaded) distorce l'UV orizzontale dello sprite a due frequenze sfasate, piu' forte verso la punta della fiamma e quasi nulla alla base (ancorata); indipendente dal tremolio gia' esistente dell'energia della luce (`LightFlicker`, invariato). Materiale sostituisce il `CanvasItemMaterial` unshaded su `Torch.tscn`/`Candle.tscn`.
  - **Alberi della piazza**: `tree_sway.gdshader` sposta i vertici in orizzontale con un seno, ancorato alla base (`UV.y=1`) e piu' marcato verso la chioma (`UV.y=0`); la fase usa la posizione nel mondo dell'albero, cosi' i 22 alberi di `Hub.tscn` non ondeggiano in sincrono senza bisogno di un uniform per istanza.
  - **Pozzanghera/pozza a crescita animata**: scena `EnvironmentDrip.tscn` (`ArenaData.drip_spots`/`drip_color`, vuoto = nessuno), uno `Sprite2D` con `growing_stain.gdshader` (canvas_item, nessuna texture: forma circolare da SDF sull'UV, bordo che increspa) che cresce da vuota a piena in `growth_seconds` (script `GrowingStain`, anima l'uniform `progress` perche' `TIME` nello shader parte dall'avvio del motore e non da quando l'istanza compare). Colore per ambientazione: pozzanghera d'acqua nella Cripta, pozza di sangue nell'Ossario (stessa scena, stesso shader, colore diverso). Arena.gd la istanzia in `_place_drips()` come le torce/candele.
  - Non testato a runtime oltre un caricamento/instanziazione di controllo (`tests/scenes/run/test_environment_shaders.gd`): rendering/asset restano fuori dalla regola di test generale.

- **Stato M6 (#27)**: player (mago incappucciato col bastone, 48px a schermo), slime (44px), proiettile (sfera con scia, 16px) e gemma di exp (16px) vettoriali; 2 frame di respiro per player e slime (`FrameCycler`). Collider dello slime allargati alle nuove dimensioni (corpo 16px, hurtbox e contatto 17px). Generatore: `tools/sprites.py` (Python + cairosvg).
- ~~Stato M4 (#18)~~ (superato in M6): primo set di asset in pixel art 16x16 (scala 2, filtro nearest), palette ristretta derivata da Sweetie-16, contorno scuro su tutti gli sprite. Generati da `tools/sprites.py` (sprite descritti come griglie di caratteri: modificabili e rigenerabili senza editor grafico). **Nota**: è programmer art coerente, non arte finale da artista; la pipeline permette di sostituire i PNG in `assets/sprites/` a parità di dimensioni senza toccare scene o codice.
- **Icona dell'eseguibile (M11.2, #64)**: portale viola su fondo scuro (`tools/sprites.py` → `build_app_icon()`): `assets/icon/icon.png` (1024 px, icona del progetto), `icon.ico` (Windows, 16–256 px) e `icon.icns` (macOS), impostate in Impostazioni progetto → Applicazione → Config (*Icon*, *Windows Native Icon*, *macOS Native Icon*). Nei preset di esport il campo icona lasciato vuoto usa queste.
- **Stato M4 (#19, audio)**: SFX chiptune sintetizzati da `tools/audio.py` (numpy): sparo, colpo e morte nemico, danno e morte player, level-up, apertura estrazione, estrazione riuscita, craft, selezione. Due musiche in loop (hub 90 BPM calma, arena 140 BPM incalzante). Bus `Music` (−8 dB) e `SFX` (−3 dB) in `default_bus_layout.tres`. Suoni per id in `data/audio/sound_bank.tres`; `SfxPlayer` (pool di 12 voci, min 30ms tra ripetizioni dello stesso suono, pitch variato sui suoni frequenti) ignora id/stream mancanti senza errori. Stessa nota della grafica: suoni programmatici sostituibili file per file.
- **Stato M5 (#26, HUD e schermo)**: barra HP rossa, barra EXP blu. Scalatura della finestra `canvas_items` con risoluzione base 1280x720 e aspect `expand`: a schermo intero gioco e HUD si ingrandiscono in proporzione invece di mostrare più arena a pixel minuscoli. Zoom della camera (`Arena/Player/Camera2D`): 1.0 per ora, **valore definitivo da scegliere con il playtest del proprietario** e da riportare qui.
- **Stato M7 (#31, atmosfera)**: tono più cupo con le luci 2D di Godot. L'arena attuale è la **Cripta** (arena iniziale): ambiente scurito da `CanvasModulate` (0.40, 0.38, 0.50), il player porta una luce calda (`Player/%Light`, raggio ~450px), 5 torce tremolanti per muro lungo (`Torch.tscn`, `LightFlicker`), vignettatura ai bordi. Proiettili, gemme, oggetti a terra e zona di estrazione sono *unshaded*: restano luminosi e leggibili al buio. HUD e menu sono su CanvasLayer propri e non vengono scuriti.
- **Stato M7 (#35, piazza)**: props vettoriali dell'hub generati da `build_hub()` (ciottoli, fontana, forgia e magazzino, incudine, baule, portale ad arco con vortice, lampione, due alberi). Lampioni e arco con materiale normale, illuminati dalle luci della piazza; il vortice del portale è unshaded.

## 9. Struttura tecnica (Godot 4.6)

La struttura target iniziale (M0) è superata dallo stato reale in §9.1. Per aggiungere contenuti (nemici, arene, personaggi, equipaggiamento, suoni) seguire `docs/GUIDA_CONTENUTI.md`.

### 9.1 Struttura attuale

```
res://
  autoload/run_manager.gd            # RunManager: stato, exp, livello, tempo, uccisioni, loot di run
  autoload/meta_progression.gd       # MetaProgression: inventario, equip, estrazioni per arena, arena scelta, salvataggio v3
  scripts/core/scene_routes.gd       # percorsi delle scene principali (MainMenu, Hub, Arena)
  scripts/core/                      # game_session (Salva/Carica/Torna al menu), audio_settings (volumi, file impostazioni)
  data/i18n/strings.csv              # traduzioni it/en/fr/es (chiavi usate da scene, dati e codice)
  scenes/ui/OptionsPanel/            # pannello Opzioni condiviso (menu iniziale e pausa)
  scenes/menu/MainMenu/              # menu iniziale (scena principale): Continua, Nuova partita, Opzioni, Esci
  scripts/data/                      # classi Resource: arena_data, arena_catalog, enemy_spawn, enemy_data, weapon_data, player_stats, wave_data, extraction_data, level_curve, upgrade_data, upgrade_table, material_data, drop_entry, equipment_data, equipment_catalog, stat_modifier, recipe_data, material_cost, recipe_book
  scripts/meta/                      # meta_inventory, equipment_loadout, crafting (logica pura dello stato permanente)
  scripts/combat/                    # health, hitbox, hurtbox, hit_flash, weapon, projectile_pool, knockback, hit_stop, blink, frame_cycler, light_flicker
  scripts/run/                       # enemy_pool, wave_spawner, enemy_movement, spawn_utils, loot_run_inventory, loot_transfer, stat_applier, pickup_pool, pause_state, pause_controller, fog_drift
  scenes/run/Bosses/boss.gd          # script boss condiviso (macchina a stati guidata da BossData)
  scenes/run/Telegraph/              # cerchio di preavviso con Hitbox a impulso (attacchi ad area)
  data/abilities/                    # abilità della bacchetta + ability_catalog
  scripts/run/abilities/             # effetti delle abilità (AbilityEffect e sottoclassi)
  scenes/ui/AbilityChoice/           # scelta dell'abilità (pausa), sostituzione con slot pieni
  data/events/                       # eventi della run (RunEventData)
  scripts/run/run_event_director.gd  # fa partire gli eventi e ne applica le regole (fulmini con Telegraph)
  data/consumables/                  # consumabili a terra e tabella dei drop
  scripts/hub/                       # interactable (punto di interazione, nearest_index testato), spinner (vortice del portale)
  scripts/audio/                     # sound_entry, sound_bank, sfx_player, music_player
  scenes/hub/Hub/                    # Hub.tscn + hub.gd: piazza esplorabile, scena principale, composition root dell'hub
  scenes/hub/{Blacksmith,LoadoutPanel,ArenaSelect}/ # finestre dell'hub: fabbro, equipaggiamento, portale (segnali verso l'hub)
  scenes/hub/Lamp/                   # lampione con luce calda
  scenes/run/Arena/                  # Arena.tscn + arena.gd: unica scena di arena, configurata da ArenaData (composition root della run)
  scenes/run/Player/                 # Player.tscn + player.gd (usato in Arena e Hub)
  scenes/run/Enemies/enemy.gd        # script nemico condiviso, guidato da EnemyData
  scenes/run/Enemies/{EnemyBasic,Ghoul,SkeletonArcher}/ # scene dei nemici (stesso script, dati e grafica diversi)
  scenes/run/Projectile/             # Projectile.tscn (player) ed EnemyProjectile.tscn (layer enemy_attack), poolable
  scenes/run/{Pickup,ExtractionPoint,Torch,Candle}/ # oggetto a terra, zona di estrazione, torcia, candela
  scenes/ui/                         # HUD, LevelUpChoice, RunEndScreen, PauseMenu, RunInventory, ExtractionIndicator
  data/arenas/                       # arena_catalog + un .tres per arena (crypt, ossuary)
  data/{weapons,enemies,player,waves,run,upgrades,materials,equipment,recipes,audio}/ # istanze .tres di tutti i contenuti
  assets/art/                        # sorgenti SVG (generati da tools/sprites.py)
  assets/sprites/                    # PNG a 2x (personaggi, nemici, tile, decorazioni, props dell'hub, icone)
  assets/audio/                      # WAV di SFX e musiche (generati da tools/audio.py)
  tools/sprites.py, tools/audio.py   # generatori di grafica vettoriale e audio (Python)
  tools/autoplay.gd, tools/bot_driver.gd # bot di playtest per il bilanciamento (metriche su N run, anche per arena)
  tools/flow.gd                      # playtest end-to-end automatico hub→run→hub
  addons/gdUnit4/                    # framework di test (v6.2.1, vendored)
  tests/                             # test GdUnit4, specchio di scripts/ e autoload/
docs/                                # GDD, CHANGELOG, BEST_PRACTICES, GUIDA_CONTENUTI (procedure operative per i contenuti)
```

- Grafica (M6): sprite vettoriali in `assets/sprites/` (player e slime a 2 frame via `FrameCycler`, proiettile, pavimento e muri a tile ripetute, icone 16x16 di materiali ed equipaggiamento usate nell'hub). Arena 1600x1000: muri visibili larghi 32px sul bordo, area giocabile ±768x±468, camera sul player con limiti arena.
- Autoload attivi: `RunManager` (stato run) e `MetaProgression` (stato permanente, da M2). Nessun altro.
- Nemici: `EnemyPool` (un pool per tipo di nemico, 32 pre-istanziati, cresce se serve) + `WaveSpawner` guidato da `WaveData`: l'intervallo tra batch scende da 2.0s a 0.5s (−0.015s per secondo di run), il batch cresce di 1 nemico ogni 25s, tetto 60 nemici vivi. Spawn in punto casuale ad almeno 300px dal player.
- Flusso di run (M1): `RunManager` è una macchina a stati `IDLE → RUNNING ⇄ LEVEL_UP → ENDED` con esito `DEATH` o `EXTRACTED`. `Arena` mette in pausa il gioco quando lo stato non è `RUNNING`. A fine run: schermata con esito, livello, tempo e uccisioni, bottone “Torna all'hub” (da M3; nuova run = scena `Arena` nuova + `start_run()`). Il canale di estrazione non è uno stato globale: vive in `ExtractionPoint` (nessun altro sistema ne dipende). `RunManager` non scrive mai su `MetaProgression` (vedi §4).
- **Cursore (M10.1, #49)**: freccia chiara con contorno scuro (default di progetto: menu, hub) e mirino in run; in pausa, level-up, scelte e fine run torna la freccia (`CursorStyle`).
- **Interpolazione della fisica (M10.1, #48)**: attiva nel progetto (`physics/common/physics_interpolation`). Tutto si muove nei tick di fisica e il rendering interpola tra un tick e l'altro, così il personaggio seguito dalla camera non trema più su schermi a frequenza diversa da 60 Hz; la camera (`Camera2D`) si aggiorna sui tick di fisica. **M10.2 (#52)**: gli oggetti presi dai pool scivolavano per un attimo dalla posizione precedente perché il reset dell'interpolazione era fatto prima di renderli visibili; ora è fatto dopo (verificato con `tools/interpolation_check.gd`).
- Collision layers (nomi in Project Settings): 1 `world`, 2 `player`, 3 `enemy`, 4 `player_attack`, 5 `enemy_attack`.
- Input map: `move_*` (WASD, frecce, stick sinistro), `aim_*` (stick destro), `shoot` (mouse sinistro), `menu` (ESC, Start), `pause` (P), `inventory` (I, Back), `interact` (E, pad X; hub, M7), `character` (C; hub, M9).
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
**M5 — Post-MVP: controlli e UI** ✅ (2026-09-23): cadenza senza tetto, raccolta a magnete, pausa (ESC/P), inventario di run (I), 8 nuovi potenziamenti, barre HUD e scalatura della finestra.
**M6 — Grafica vettoriale e rage** ✅ (2026-09-23): addio pixel art, arena e icone vettoriali, rage dei nemici, fase avanzata delle ondate dopo 60s.
**M7 — Atmosfera, arene, hub esplorabile** ✅ (2026-09-24): luci 2D e Cripta cupa, arene guidate dai dati con scelta dal portale, Ossario con Ghoul e Scheletro arciere, hub come piazza all'aperto.
**M8 — Salvataggi, menu, boss** ✅ (2026-09-24): salvataggi manuali, menu iniziale con opzioni audio, sistema boss riutilizzabile, Re Slime.
**M9 — Rifiniture dal playtest** ✅ (2026-09-24): statistiche, inventario nell'hub con I/C, opzioni in pausa, posizione salvata nella piazza, 4 lingue.
**M10 — Abilità ed eventi** ✅ (2026-09-24): abilità della bacchetta (3 slot), eventi della run (Tempesta di fulmini), catalogo PDF, progetto di rarità/slot/mitici/enciclopedia (§6.1–6.4).
**M11 — Rarità ed equipaggiamento** ✅ (2026-09-24): istanze uniche con rarità e bonus casuali, 9 slot con manichino, drop in run fino a Leggendario, fusione di due oggetti identici, modificatori da Super raro (§6.1–6.3).
**M11.1 — Overtime e Passo d'ombra** ✅ (2026-09-24): smontaggio in lavorazione, alone e suono dei drop per rarità, overtime dopo l'apertura dell'estrazione, evento Passo d'ombra (§4, §3, §6.3).
**M11.2 — Icona, evento dopo il boss, boss dell'overtime** ✅ (2026-09-24): icona dell'eseguibile, terzo evento 10 s dopo il boss, ondate di boss dell'overtime pari ai boss della run.
**M11.3 — Loot, abilità a livelli, nemici e boss** ✅ (2026-09-24): Guarda il loot, baule ordinabile, confronto e intervalli nel tooltip, niente bonus duplicati, abilità a livelli, veleno e vita 10, slime colorati nella Cripta, sistema boss esteso con vita x2, Negromante, Colosso d'ossa, Regina dei Ghoul (§4, §5, §6).
**M12 — Mitici, enciclopedia, achievement** (pianificata): abilità **uniche** di Leggendari e Mitici che non si trovano in run, ricette mitiche dai boss, materiali composti, enciclopedia in gioco, achievement (§6.4, §13).

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
- **Fase avanzata (M6, #30, dal playtest del proprietario)**: dal secondo 60 l'intervallo tra batch si accorcia del 40% (`late_interval_multiplier` 0,6, anche sotto `min_interval`) e il tetto di nemici vivi sale di +20 (`late_max_alive_bonus`), oltre alla crescita di +5 ogni 30s. Valori in `WaveData` (gruppo "Fase avanzata"). Bot che sceglie bene (15 run): estrazioni dal 100% all'**80%**, uccisioni medie da 195 a 293, gelatina per run da ~32 a ~45 (l'economia accelera di circa il 40%: da rivedere se i pezzi arrivano troppo in fretta).
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

### 10.4 Verifica M6 (#29, rage)

Con il bot che sceglie bene i potenziamenti la rage non cambia l'esito: 100% di estrazioni su 20 run; in una run campione 22 slime su 179 sono andati in rage e il player non ha subito nessun danno. Il problema non è la rage ma la potenza del player a metà run (Ventaglio, Perforazione, cadenza senza tetto). Leve possibili, da decidere dopo il playtest umano: rage più aggressiva (soglia più bassa, +velocità), più HP ai nemici nel tempo, un nemico a distanza, ondate più fitte dopo i 60s.

### 10.5 Verifica M7 (#33/#34, Ossario)

Bot migliorato per le arene affollate (schiva i dardi nemici; con la zona aperta dà priorità all'estrazione) e con resoconto del loot per materiale. Risultati:

| Arena | Equipaggiamento | Estrazioni | Uccisioni medie | Loot raccolto per run |
|---|---|---|---|---|
| Cripta | nessuno | 90% (10 run) | 273 | ~43 Gelatina, ~2,8 Nuclei |
| Ossario | nessuno | 20% (5 run) | 616 | — |
| Ossario | Bacchetta di gelatina + Amuleto | 60% (5 run) | 602 | ~27 Frammenti d'osso, ~2 Essenze |

Correzioni fatte durante la verifica: prima versione impossibile (0% anche con equip) perché i ghoul in rage erano più veloci del player e gli arcieri colpivano 5–8 volte per run senza possibilità di schivare → ghoul rage ×1,25 dopo 4s, dardi a 240px/s ogni 2,6s, meno arcieri (peso 0,3). Drop ridotti perché nell'Ossario si uccide 2–3 volte più che nella Cripta; la Bacchetta d'ossa arriva dopo ~3 estrazioni riuscite nell'Ossario.

### 10.6 Verifica M8 (#39, Re Slime)

Bot con opzione `boss` (resta nell'arena finché il boss comparso è vivo, poi va all'estrazione; schiva i cerchi rossi), 8 run per riga, Cripta:

| Configurazione | Boss sconfitto | Estrazioni | Durata media | Gelatina / Nuclei raccolti per run |
|---|---|---|---|---|
| Normale (estrae appena può) | 0/8 (non lo incontra) | 75% | 122 s | 36 / 3,3 |
| Combatte il boss, senza equip | 4/8 | 37% | 180 s | 107 / 10,1 |
| Combatte il boss, Bacchetta di gelatina + Amuleto | 6/8 | 50% | 183 s | 118 / 10,8 |

Lettura: chi estrae subito non è toccato dal boss; chi resta rischia molto di più ma raccoglie circa il triplo (soprattutto per le uccisioni in più, fase avanzata delle ondate inclusa). Le morti arrivano quasi tutte dopo i 170 s, quando boss e ondate fitte si sommano. Da rivedere col playtest umano: il bot schiva i cerchi in modo quasi perfetto ma subisce i proiettili.

### 10.7 Verifica M10 (#45/#46, abilità ed eventi)

Bot aggiornato: schiva i cerchi dei fulmini come quelli del boss e prende la prima abilità proposta.

| Configurazione | Eventi superati | Estrazioni | Confronto |
|---|---|---|---|
| Cripta, senza equip (8 run) | 13/16 (81%) | 100% | prima delle abilità 75–90% |
| Ossario, gelatina + amuleto (5 run) | 8/10 (80%) | 100% | prima delle abilità 60% |

Lettura: le abilità alzano molto la potenza della run (Anello arcano e Fulmine errante raddoppiano di fatto il danno ad area). Il bot schiva quasi perfettamente, un giocatore umano fallirà più eventi. Da rivedere col playtest; il bilanciamento della difficoltà è previsto insieme alle rarità (M11), quando cresce anche la potenza dell'equipaggiamento.

### 10.8 Verifica M10.2 (#53, Pentagramma e boss multipli)

Bot: va nel pentagramma e ci resta schivando solo dentro il cerchio.

| Configurazione | Pentagrammi superati | Eventi totali | Boss sconfitti | Estrazioni | Materiali per run |
|---|---|---|---|---|---|
| Cripta, senza equip, estrae appena può (8 run) | 6/6 | 10/13 | — | 75% (morti a 47 e 95 s) | 37 Gelatina, 2,4 Nuclei |
| Cripta, gelatina + amuleto, resta per i boss (6 run) | 6/6 | 11/12 | 6/6 (spesso 2 Re Slime) | 100% | 169 Gelatina, 17,8 Nuclei |

Lettura: il Pentagramma è un rischio breve (ondata di mostri in rage per 15 s) che il bot regge sempre; il costo vero è il boss in più, che con l'equipaggiamento vale molto loot. Da rivedere col playtest umano: se è troppo facile alzare `monster_bonus` o ridurre `circle_radius`.

### 10.9 Verifica M11.1 (#62 overtime, #63 Passo d'ombra)

| Configurazione | Risultato |
|---|---|
| Cripta, bot che non estrae mai (`stay`, 2 run) | una morte normale a 87 s; l'altra regge fino a 334 s, cioè a overtime x4 (estrazione aperta a 120 s, x1 a 170 s) |
| Cripta, solo Passo d'ombra (`event=shadow_step`, 6 run) | 8/12 eventi superati (67%), 100% estrazioni; la Tempesta nelle stesse condizioni ~80% |

Lettura: il bot schiva quasi perfettamente e arriva a x4; un giocatore umano dovrebbe cedere tra x2 e x3, come richiesto. Il Passo d'ombra è l'evento più difficile per il bot (scatta solo quando un nemico è a meno di 70 px). Da rivedere col playtest umano.

### 10.10 Verifica M11.3 (slime della Cripta, boss con vita x2, boss dell'Ossario)

| Configurazione | Risultato |
|---|---|
| Cripta, senza equip, estrae appena può (6 run) | 66% estrazioni (morti a 63 e 96 s); prima degli slime colorati 75% |
| Cripta, gelatina + amuleto, resta per il Re Slime (3 run) | Re Slime (800 HP) sconfitto 1/3; le altre run muoiono nell'overtime |
| Ossario, gelatina + amuleto, resta per il boss (2 run) | boss sconfitti 0/2, morte nell'overtime a ~200 s |

Lettura: con la vita dei boss x2 l'overtime (50 s dopo l'estrazione, 30 s dopo la comparsa del boss) arriva prima che il boss muoia; chi vuole il boss deve avere equipaggiamento migliore, chi estrae subito non ne risente. Da decidere col playtest umano se far partire l'overtime dalla morte del boss o allungarne l'attesa. Gli slime colorati tolgono circa un'estrazione su dieci al bot.

## 11. Open questions

- Godot version confermata: 4.6 (da project.godot). Se si prevede export mobile o console, valutare per tempo eventuali limitazioni.
- ~~Dimensione sprite definitiva~~ → in M6 si passa alla grafica vettoriale (vedi §8): la domanda non si pone più. Storico: in M4 era stato deciso **16x16**, disegnati a scala 2 (32px a schermo), filtro nearest. Arena 1600x1000 con UI reale: a 32x32 i personaggi sarebbero stati troppo grandi rispetto al campo visivo e alla densità di nemici.
- ~~Persistenza meta-progressione~~ → decisa in M2 (da M8 solo salvataggi manuali, vedi §7): `ConfigFile` in `user://` (leggibile, versionato; niente `.tres` caricati da `user://`, che possono eseguire script). Cloud save fuori scope.
- ~~Durata target di una run~~ → M4: **~2–2,5 minuti** fino alla prima estrazione possibile (zona a 120s + 6s di canale); chi resta oltre rischia di più (tetto nemici crescente). Da confermare con playtest umano.
- **Zoom della camera in arena**: in attesa del valore scelto dal playtest del proprietario (oggi zoom 1). Nell'hub è 0,85.
- **Difficoltà per giocatori esperti**: il bot estrae nel 90% delle run nella Cripta; da verificare con giocatori umani se serve una curva più dura o se basta l'Ossario come sfida.
- **Scelta del personaggio**: non prevista finora; percorso tecnico descritto in `docs/GUIDA_CONTENUTI.md` §3.3, da pianificare con una issue.
- **Sblocco delle ricette mitiche**: deciso che arrivano dai boss; resta da fissare la probabilità di drop della ricetta e se servono più frammenti (M12).
- **Potenza con le abilità**: con le abilità della bacchetta il bot estrae nel 100% delle run (§10.7); la difficoltà va rivista insieme alle rarità.

- **Controlli touch mobile** (M13, da fare): pianificato ma non ancora iniziato. Resta in coda finche' non si decide di riprenderlo.
- **Livello arena, indicazione a schermo** (M12, #86): il sistema (§6.3b) non mostra ancora il livello raggiunto al player durante la run; da decidere dove (HUD? solo a fine run?) col proprietario.
- ~~**Backlog M12/M13 richiesto dal proprietario (#86)**~~: tutti e quattro implementati — evento "Scheletri nell'armadio" (§3.4), livello arena da potenza dell'equip (§6.3b), shader di movimento ambientale (§8), tutorial contestuale (§3.5).

## 12. Processo e versionamento

- Repo GitHub: `danieleadelfio/Wanderloot` (remote `origin`, branch `main`).
- Task tracking: GitHub Issues + Projects, attivo. Una milestone per ogni M del §10; nessun sistema di task parallelo.
- Vedi `docs/BEST_PRACTICES.md` per convenzioni di codice, architettura e testing (GdUnit4). Vedi `docs/CHANGELOG.md` per lo storico modifiche. Vedi `docs/GUIDA_CONTENUTI.md` per le procedure operative (nuovi nemici, arene, personaggi, equipaggiamento, suoni).
- **Bilanciamento**: dove si cambia ogni valore (player, livelli, potenziamenti, nemici, ondate, estrazione, boss e numero di boss, eventi, loot, consumabili, abilità) e come verificarlo col bot: `docs/GUIDA_CONTENUTI.md` §8.
- **Catalogo** (`docs/catalog/`): `catalog.json` è la fonte di abilità, eventi, equipaggiamento, rarità e achievement (con la provenienza di ogni idea: Magicraft o originale); `tools/catalog_pdf.py` rigenera `Wanderloot_Catalogo.pdf` (richiede reportlab). Ogni contenuto nuovo va aggiunto al JSON nello stesso commit.
- **Regola fissa**: ogni modifica a feature/grafica/scope/genere/gameplay loop va riportata in questo documento (sezione pertinente) e come voce in `docs/CHANGELOG.md`, nello stesso commit della modifica.

## 13. Enciclopedia in gioco (progetto M12)

Finestra consultabile dall'hub (e dalla pausa) con schede **Abilità, Equipaggiamento, Nemici e boss, Eventi, Achievement**, costruita dagli stessi dati del gioco (`.tres`) e ordinata come il catalogo (`docs/catalog/`). Una voce si **sblocca quando la incontri** (abilità scelta almeno una volta, oggetto trovato, nemico ucciso, evento visto); le voci non ancora scoperte mostrano solo la sagoma e "???". Le scoperte si salvano in `MetaProgression` (sezione dedicata). Gli **achievement** (proposte nel catalogo: Prima estrazione, Regicida, Occhio al cielo, Alchimista, Mito…) si registrano allo stesso modo e possono sbloccare ricompense (ricette, cosmetici).
