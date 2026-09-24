# Guida operativa — creare contenuti in Wanderloot (Godot 4.6)

Come aggiungere nemici, arene, personaggi e gli altri contenuti sfruttando quello che il progetto ha già: classi `Resource` in `scripts/data/`, istanze `.tres` in `data/`, generatori di asset in `tools/`, bot di playtest e test GdUnit4.

Regola d'oro: **prima i dati, poi il codice**. Quasi tutto si fa creando o duplicando `.tres` e scene. Serve codice solo quando si introduce un *comportamento* nuovo (sezione 6).

---

## 0. Strumenti e operazioni base

### 0.1 Nell'editor di Godot

| Operazione | Come |
|---|---|
| Creare un `.tres` | FileSystem → tasto destro sulla cartella in `data/` → **Nuovo → Risorsa…** → cerca la classe (`EnemyData`, `ArenaData`, …) → salva. |
| Copiare un `.tres` esistente (consigliato) | FileSystem → tasto destro sul file → **Duplica…** → nuovo nome. Poi modifichi i valori nell'Inspector. |
| Copiare una scena | FileSystem → tasto destro sul `.tscn` → **Duplica…**, nella sua cartella (`scenes/<dominio>/<NomeScena>/`). Le forme di collisione interne restano indipendenti dall'originale. |
| Variante di una scena che segue l'originale | **Scena → Nuova scena ereditata…**. Le modifiche all'originale si propagano. Utile per i personaggi (§3). |
| Risorsa annidata condivisa per errore | Inspector → freccia sul campo → **Rendi unica**. Serve quando modifichi uno `Shape` o una `Gradient` di una scena duplicata e cambia anche l'originale. |
| Nodi con `%Nome` | Il codice li cerca per *unique name* (tasto destro sul nodo → **Accesso come nome univoco**). Se rinomini o togli quel flag, lo script si rompe. |

### 0.2 Generatori di asset (fuori dall'editor)

Dalla root del progetto, con Python 3 (`pip install cairosvg pillow numpy`):

```bash
python3 tools/sprites.py   # grafica: SVG in assets/art/, PNG a 2x in assets/sprites/
python3 tools/audio.py     # suoni e musiche WAV in assets/audio/
```

- **Grafica**: ogni asset è una funzione Python che restituisce un SVG. `save(nome, [frame1, frame2], lato_px)` affianca i frame in un solo PNG. Il PNG è a **2x** della dimensione a schermo: nella scena lo `Sprite2D` ha `scale = 0.5`, con `hframes` pari al numero di frame. Le dimensioni di riferimento sono nella §7.
- Puoi anche disegnare in Inkscape (o altro) e mettere un PNG in `assets/sprites/`, rispettando il 2x e lo stile (contorno scuro, sfumature). Se lo generi a mano, non aggiungerlo a `sprites.py`, che lo sovrascriverebbe.
- **Audio**: aggiungi i suoni nuovi **in fondo** a `tools/audio.py`, così i WAV esistenti restano identici e git non li vede cambiati. Per le musiche in loop: selezionale nel FileSystem → dock **Importa** → *Loop Mode* **Forward** → **Reimporta** (in `.import`: `edit/loop_mode=2`).
- Dopo aver generato, torna nell'editor: Godot importa i file nuovi da solo.

### 0.3 Verifica

| Cosa | Comando / dove |
|---|---|
| Test | Pannello GdUnit4 nell'editor, oppure `addons/gdUnit4/runtest.sh --godot_binary "/Applications/Godot.app/Contents/MacOS/Godot" -a res://tests` |
| Bilanciamento (bot) | `godot --headless --fixed-fps 60 --path . -s tools/autoplay.gd -- 10 arena=<id>` (aggiungi gli id di equipaggiamento dopo il numero di run: `-- 5 gel_wand core_amulet arena=ossuary`) |
| Giro completo hub→run→hub | `godot --headless --fixed-fps 60 --path . -s tools/flow.gd` |

Il bot stampa percentuale di estrazioni, durata, uccisioni e loot per materiale. Confronta i numeri **prima e dopo** ogni modifica ai `.tres` di bilanciamento e riporta i risultati nel GDD (§10).

---

## 1. Nuovo nemico

Tutti i nemici usano lo stesso script `scenes/run/Enemies/enemy.gd`: cambiano solo i dati (`EnemyData`) e la grafica. Esempi completi: `Ghoul` (in mischia, veloce) e `SkeletonArcher` (a distanza).

### 1.1 Grafica

1. In `tools/sprites.py` copia una funzione esistente (`ghoul_svg(up=False, rage=False)` o `skeleton_svg`) con un nome nuovo, es. `wraith_svg`. Il parametro `up` è il secondo frame dell'animazione, `rage` la variante rossa.
2. Aggiungi le chiamate in una funzione `build_...` richiamata in fondo al file (in `if __name__ == "__main__":`):
   ```python
   save("wraith", [wraith_svg(), wraith_svg(up=True)], 96)
   save("wraith_rage", [wraith_svg(rage=True), wraith_svg(up=True, rage=True)], 96)
   ```
3. `python3 tools/sprites.py`.

La variante rage è **obbligatoria**: lo script dissolve `%RageBody` verso il rosso quando il nemico va in rage. Se non vuoi la rage, crea comunque il nodo e imposta `rage_after = 0`.

### 1.2 Dati: `data/enemies/<id>.tres`

Duplica `ghoul.tres` (in mischia) o `skeleton_archer.tres` (a distanza) e modifica:

| Campo | Significato | Riferimenti |
|---|---|---|
| `max_hp`, `move_speed`, `contact_damage`, `exp_reward` | statistiche base | player: 220 di velocità, 5 HP |
| `contact_knockback`, `knockback_resistance` (0–1), `hit_freeze` | feeling dei colpi | |
| **Comportamento** `behavior` | `CHASE` (insegue) o `KEEP_DISTANCE` (tiene `preferred_distance`) | |
| `ranged_weapon` | un `WeaponData` → il nemico spara ogni `attack_interval` s entro `attack_range` | `data/weapons/skeleton_bow.tres` |
| **Rage** `rage_after`, `rage_speed_multiplier`, `rage_damage_bonus`, `rage_fade_time` | dopo N secondi in vita diventa rosso, più veloce e più dannoso; `rage_after = 0` la disattiva | con moltiplicatore alto supera la velocità del player |
| `drops` | lista di `DropEntry` (materiale, probabilità 0–1, quantità min/max) | Ossario: ossa 6–10%, essenza 0,4–1,2% |

I proiettili nemici usano un pool unico (`EnemyProjectile.tscn`, layer `enemy_attack`). Per un nemico a distanza basta creare un `WeaponData` (danno, velocità, durata, numero di proiettili e dispersione per i colpi a ventaglio).

### 1.3 Scena: `scenes/run/Enemies/<Nome>/<Nome>.tscn`

1. Duplica `Ghoul/Ghoul.tscn` nella nuova cartella.
2. Nodo radice: rinominalo, poi nell'Inspector imposta `data` → il tuo `.tres`.
3. `Body` e `%RageBody`: texture → i due PNG, `hframes = 2`. `offset` va regolato perché i piedi cadano sull'origine.
4. `%CollisionShape` (corpo, contro muri e altri nemici) e le forme di `%Hurtbox` e `%Hitbox`: raggio proporzionato allo sprite. Se cambi il raggio, usa prima **Rendi unica**.
5. Non toccare layer e mask:

| Nodo | layer | mask |
|---|---|---|
| radice | 4 (`enemy`, valore 4) | world + enemy (valore 5) |
| `%Hurtbox` | 0 | `player_attack` (valore 8) |
| `%Hitbox` | `enemy_attack` (valore 16) | 0 |

Nodi obbligatori, con questi unique name: `%Health`, `%Hurtbox`, `%Hitbox`, `%CollisionShape`, `%Knockback`, `%RageBody`, più `HitFlash` con `target` → `Body`.

### 1.4 Farlo comparire in un'arena

Apri `data/arenas/<arena>.tres` → **Gioco → enemies** → aggiungi un `EnemySpawn`:

- `scene`: la tua scena;
- `weight`: peso relativo nella scelta (il Ghoul dell'Ossario ha 1, l'arciere 0,3);
- `min_time`: da che secondo della run può comparire.

Non serve altro: `Arena` crea un `EnemyPool` per ogni voce e il `WaveSpawner` sceglie il tipo per peso. Suoni, exp, drop, knockback e rage sono già collegati.

### 1.5 Nuovo materiale di drop (se serve)

1. Icona: funzione `icon_...` in `sprites.py`, `save("icon_<id>", [..], 64)`.
2. `data/materials/<id>.tres` (`MaterialData`): `id` (StringName univoco, **finisce nel salvataggio: non cambiarlo più**), `display_name`, `rarity`, `color`, `icon`.
3. Aggiungilo all'array `materials` di **`scenes/hub/Hub/Hub.tscn`** (radice) e di **`scenes/ui/RunInventory/RunInventory.tscn`**, altrimenti baule e inventario mostrano l'id grezzo senza icona.
4. Usalo nei `drops` del nemico e in una ricetta (§4.2).

### 1.6 Verifica

- Test: prendi `tests/run/test_enemy_behaviours.gd` come modello (carica il `.tres` e verifica i valori chiave, per esempio "più lento del player in rage" oppure "a distanza ha un'arma").
- Bot: `-- 10 arena=<id>`. Se le estrazioni crollano, i sospetti tipici sono velocità in rage ≥ player, proiettili troppo veloci o drop troppo generosi.

---

## 2. Nuova arena

Un'arena è **un solo `.tres`** (`ArenaData`). La scena `Arena.tscn` è unica e si configura da lì: pavimento, muri, luci, torce, candele, nebbia, decorazioni, musica, ondate, estrazione, nemici e sblocco.

### 2.1 Asset

| Asset | Formato | Esempio |
|---|---|---|
| Pavimento | tile ripetibile 384x384 px (192 px di mondo) | `ossuary_floor_svg` → `ossuary_floor.png` |
| Muri | tile 64x64 px (32 px di mondo) | `ossuary_wall.png` |
| Decorazioni | PNG singoli (teschi, lapidi…), sparsi a caso | `deco_*.png` |
| Musica | WAV in loop (loop Forward all'import) | `music_ossuary` in `tools/audio.py` |

Copia `build_ossuary()` in `sprites.py` come modello. Le tile devono essere seamless (i bordi combaciano).

### 2.2 Dati

1. **Ondate**: duplica `data/waves/wave_default.tres` (o `wave_ossuary.tres` per un'arena più dura). `start_interval`, `min_interval` e `interval_decay` regolano la cadenza; `start_batch` e `batch_growth_period` la dimensione dei gruppi; `max_alive` e i campi `max_alive_growth_*` il tetto di nemici vivi. Il gruppo **Fase avanzata** (da `late_start` s) accelera gli spawn e alza il tetto.
2. **Estrazione**: duplica `data/run/extraction_default.tres`: `appear_after` (s), `channel_time` (s nella zona), `decay_rate` (quanto scende il progresso se esci), `spawn_min_distance` (distanza minima dal player).
3. **Arena**: duplica `data/arenas/ossuary.tres` e imposta:
   - `id` (univoco, **finisce nel salvataggio**), `display_name`, `description` (mostrata nel portale);
   - **Aspetto**: `floor_texture`, `wall_texture`, `ambient_color` (più è scuro più è cupo: Cripta 0,4, Ossario 0,19), luce del player (`player_light_*`), `torches_per_wall` e `torch_color`, `decorations` e `decoration_count`, `candle_count` e `candle_color`, `fog_color` (alfa 0 = niente nebbia) e `fog_count`, `music`;
   - **Gioco**: `wave_data`, `extraction_data`, `enemies` (§1.4);
   - **Sblocco**: `unlock_arena` + `unlock_extractions` (es. `crypt` + 3). Vuoto = sempre disponibile.
4. Aggiungi l'arena all'array `arenas` di **`data/arenas/arena_catalog.tres`**. L'ordine dell'array è quello del portale.

Già automatico: la voce nel portale dell'hub (col motivo del blocco), il conteggio delle estrazioni per arena nel salvataggio, la posizione stabile delle decorazioni (seme dall'`id`) e i pool di nemici.

### 2.3 Premio dell'arena

Un materiale nuovo (§1.5) negli `drops` dei suoi nemici e una ricetta che lo usa (§4.2). È questo che dà un motivo per rischiare l'arena più dura.

### 2.4 Verifica

- Test: modello `tests/data/test_ossuary.gd` (arena nel catalogo, sblocco dopo N estrazioni, ricetta presente).
- Bot, con e senza equipaggiamento: `-- 5 arena=<id>` e `-- 5 gel_wand core_amulet arena=<id>`. Riporta la tabella nel GDD §10 come per l'Ossario (§10.5).
- A mano: controlla che nemici, dardi e pickup si leggano con la luce scelta.

---

## 3. Personaggio giocante

**Stato attuale**: c'è un solo personaggio, `scenes/run/Player/Player.tscn`, istanziato in **due** scene: `Arena.tscn` (combatte) e `Hub.tscn` (cammina nella piazza con `weapon_enabled = false`). La scelta del personaggio non esiste ancora.

### 3.1 Modificare il personaggio attuale (solo dati)

| Cosa | Dove |
|---|---|
| HP, velocità, i-frames, raggio magnete, moltiplicatori exp/drop | `data/player/player_default.tres` (`PlayerStats`) |
| Arma di partenza (danno, cadenza, velocità e durata del proiettile, knockback, numero di proiettili, dispersione, perforazione) | `data/weapons/starter_wand.tres` (`WeaponData`), assegnata a `%Weapon` in `Player.tscn` |
| Aspetto | `player_svg(up)` in `sprites.py` → `player.png` (2 frame, 96 px per frame) |
| Luce portata | `%Light` in `Player.tscn`; per arena la sovrascrive `ArenaData.player_light_*` |

Equipaggiamento e potenziamenti lavorano su **copie** di stats e arma (`Player.begin_run()`): i `.tres` base non cambiano mai durante la partita.

### 3.2 Creare un personaggio alternativo (per prova)

1. **Scena → Nuova scena ereditata…** da `Player.tscn` → salva in `scenes/run/Player<Nome>/Player<Nome>.tscn`.
2. Crea `data/player/<nome>.tres` (duplica `player_default.tres`) e un'arma `data/weapons/<nome>_weapon.tres`.
3. Nella scena ereditata: radice → `stats` = il nuovo `.tres`; `%Weapon` → `data` = la nuova arma; `Body` → nuova texture.
4. Per giocarlo: in `Arena.tscn` e `Hub.tscn` cambia la scena istanziata dal nodo `Player`. Il modo più sicuro è aprire i due `.tscn` in un editor di testo e sostituire `res://scenes/run/Player/Player.tscn` nella riga `[ext_resource …]` con il percorso della nuova scena. Così restano il nome `Player`, il flag unique, la `Camera2D` figlia e le sovrascritture (es. `weapon_enabled = false` nell'hub). Se cancelli e reistanzi il nodo dall'editor, devi rifare tutto questo a mano.

Questo cambia il personaggio per tutti: va bene per provare, non è una selezione.

### 3.3 Selezione del personaggio (da fare, fuori scope attuale)

Va aperta una issue dedicata, perché serve codice. Percorso previsto, coerente con il resto del progetto:

- una classe `CharacterData` (`Resource`) con `id`, nome, `PlayerStats`, `WeaponData` iniziale e texture, più un `CharacterCatalog` come quello delle arene;
- personaggio scelto e sblocchi salvati in `MetaProgression` (salvataggio v4, compatibile con v3), come `selected_arena`;
- `Player` applica il `CharacterData` in `begin_run()`, così resta **una sola** scena `Player.tscn`;
- scelta nella piazza con un nuovo `Interactable` (es. una statua o un NPC) che apre una finestra, come il portale.

---

## 4. Altri contenuti rapidi

### 4.1 Equipaggiamento

1. Icona `icon_<id>` a 64 px in `sprites.py`.
2. `data/equipment/<id>.tres` (`EquipmentData`): `id` (nel salvataggio), nome, descrizione, `slot` (`WEAPON` o `ACCESSORY`), `icon`, `modifiers` (lista di `StatModifier`: `stat`, `amount`, `is_multiplier`).
3. Aggiungilo a `data/equipment/equipment_catalog.tres`: gli id che non sono nel catalogo vengono scartati al caricamento del salvataggio.

### 4.2 Ricetta del fabbro

`data/recipes/<id>.tres` (`RecipeData`): `result` = l'equipaggiamento, `costs` = righe `MaterialCost` (materiale + quantità). Poi aggiungila a `data/recipes/recipe_book.tres`. Ogni pezzo si crafta una sola volta.

### 4.3 Potenziamento di level-up

`data/upgrades/<id>.tres` (`UpgradeData`): nome, descrizione, `stat`, `amount`, `is_multiplier`, `weight` (frequenza di comparsa). Poi aggiungilo a `data/upgrades/upgrade_table.tres`.

Le stat disponibili sono quelle dell'enum `UpgradeData.Stat` (danno, cadenza, velocità e durata del proiettile, velocità, HP, raggio magnete, exp, drop, i-frames, knockback, numero di proiettili, perforazione). **Una stat nuova è codice** (§6).

### 4.4 Suono

1. Sintetizzalo in fondo a `tools/audio.py` con `save("<id>", segnale, gain)`.
2. Aggiungi una voce `SoundEntry` (id, stream, volume) a `data/audio/sound_bank.tres`.
3. Collega il suono a un **segnale** nella composition root (`arena.gd` o `hub.gd`) con `_sfx.play(&"<id>")`. Mai dalle entità.
4. Aggiungi l'id a `USED_IDS` in `tests/audio/test_sound_bank.gd`.

### 4.5 Punto di interazione nella piazza

1. Aggiungi l'oggetto (sprite + collisione) sotto `World/Props` in `Hub.tscn`, che ordina i nodi per Y.
2. Aggiungi un `Area2D` con script `Interactable` sotto `World`: `collision_layer = 0`, `collision_mask = 2`, `prompt = "E — …"` e `window` → una finestra sotto `UI`.
3. La finestra è un `CenterContainer` con un `PanelContainer` (stile `window_style`) che contiene la scena UI. L'hub gestisce da solo apertura, pausa, focus e chiusura con ESC/E. La logica della finestra (segnali verso `MetaProgression`) va collegata in `hub.gd`.

---

## 5. Cose da non fare

- **Non chiamare `MetaProgression.save_to_disk()` dal gameplay**: i salvataggi sono solo manuali (Salva nel menu di pausa → `GameSession.save()`). Per provare contenuti nuovi parti da **Nuova partita** o da un salvataggio di prova.

- **Non cambiare un `id`** di materiale, equipaggiamento o arena già usato: i salvataggi dei giocatori lo referenziano.
- **Non riordinare gli enum** salvati nei `.tres` (`UpgradeData.Stat`, `EnemyData.Behavior`, `EquipmentData.Slot`): voci nuove solo in coda, perché nei `.tres` sono salvati come numeri.
- **Non modificare un `.tres` condiviso a runtime** (es. `stats.max_hp += 1` sul file caricato): lavora su `duplicate()`, come fa `Player.begin_run()`.
- Niente `instantiate()`/`queue_free()` per nemici e proiettili in combattimento: si usano i pool (`activate`/`deactivate`).
- Niente nuove `PointLight2D` per nemico o proiettile: per farli brillare si usa il materiale *unshaded*.
- Non collegare suoni o UI dalle entità: si emette un segnale e lo collega la composition root.

---

## 6. Quando serve codice

| Novità | Dove | Test |
|---|---|---|
| Comportamento di movimento nemico (es. "gira attorno", "carica") | voce **in coda** a `EnemyData.Behavior`, funzione statica pura in `scripts/run/enemy_movement.gd`, ramo in `enemy.gd::_desired_direction()` | sulla funzione statica (modello `keep_distance`) |
| Attacco nemico diverso (es. esplosione a contatto) | nuovo componente-nodo in `scripts/combat/` (composizione), collegato via segnale in `arena.gd` | logica pura del componente |
| Nuova stat per upgrade o equipaggiamento | voce **in coda** a `UpgradeData.Stat`, campo in `PlayerStats` o `WeaponData`, ramo in `StatApplier` | `tests/run/test_stat_applier.gd` |
| Selezione del personaggio | §3.3 | catalogo e salvataggio v4 |
| Nuova regola di sblocco (non solo "N estrazioni in X") | `ArenaData.is_unlocked()` | `tests/data/test_arena_data.gd` |

Prima di scrivere: apri una issue e dichiara lo scope. Dopo: aggiorna GDD e CHANGELOG nello stesso commit, e `BEST_PRACTICES.md` se cambia un pattern.

---

## 7. Dimensioni di riferimento (a schermo = metà del PNG)

| Oggetto | PNG per frame | A schermo |
|---|---|---|
| Player | 96 px | 48 px |
| Slime / Ghoul / Scheletro | 88–96 px | 44–48 px |
| Proiettile, gemma exp, dardo | 32 px | 16 px |
| Icone (materiali, equip) | 64 px | 32 px nell'UI |
| Tile pavimento / muro | 384 / 64 px | 192 / 32 px |
| Arena calpestabile | — | 1600 x 1000 px |
| Piazza dell'hub | — | circa 1720 x 960 px calpestabili, camera con zoom 0,85 |
