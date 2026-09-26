# Equip Info

Riferimento per il bilanciamento dell'equipaggiamento: statistiche base per pezzo, range dei bonus casuali per rarità, tasso di drop per arena.

**Regola fissa:** ogni nuovo pezzo di equip va aggiunto qui (statistiche base, slot, range) nello stesso commit che lo introduce, insieme all'aggiornamento di GDD.md e CHANGELOG.md.

Fonti: `data/equipment/*.tres` (pezzi), `data/equipment/rarity_table.tres` (rarità), `data/equipment/affix_table.tres` (bonus possibili), `data/equipment/drops_<arena>.tres` (drop in run), `scripts/meta/item_roller.gd` (logica di tiro).

## 1. Rarità

| Rarità | N. bonus | Qualità tiro (quality) | N. abilità | Peso drop | Molt. smontaggio |
|---|---|---|---|---|---|
| Comune | 1 | 0,00 – 0,35 | 0 | 60 | ×1 |
| Non comune | 2 | 0,20 – 0,55 | 0 | 25 | ×2 |
| Raro | 3 | 0,40 – 0,75 | 0 | 10 | ×3 |
| Super raro | 3 | 0,55 – 0,90 | 1 (Lv1) | 4 | ×5 |
| Leggendario | 4 | 0,75 – 1,00 | 1 (Lv2) | 1 | ×8 |
| Mitico | 4 | 0,90 – 1,00 | 1 (Lv3) | 0 (solo ricetta) | ×12 |

Ogni bonus tirato ha una "qualità" casuale nell'intervallo della rarità (uniforme); il valore del bonus è l'interpolazione lineare tra `min_value` e `max_value` dell'affisso a quella qualità. Statistiche intere (Danno, Vita max, N. proiettili, Perforazione) si arrotondano, minimo 1. Un oggetto non tira mai due volte la stessa statistica, né una statistica che ha già come bonus fisso di base. Dall'abilità (Super raro+): una a caso dal catalogo abilità, **sempre attiva per tutta la run**, fuori dai 3 slot.

Fusione: **tre** oggetti identici (stesso oggetto base, stessa rarità) → uno della rarità successiva, bonus e abilità ritirati da capo. Sale fino a Leggendario; il Mitico si ottiene solo da ricetta.

## 2. Bonus possibili (affissi) e range per rarità

Formato valori: flat = si somma al valore base; % = moltiplicatore (es. 1.25 = +25%). "—" = statistica non ammessa per quello slot. Bonus con peso 0 sono **disattivati** (mai estratti al momento, presenti nei dati per uso futuro).

| Statistica | Tipo | Slot ammessi | Peso | Comune | Non comune | Raro | Super raro | Leggendario | Mitico |
|---|---|---|---|---|---|---|---|---|---|
| Danno | flat | Arma, Guanti, Anello | 1,0 | 1 – 2 | 1 – 2 | 2 – 2 | 2 – 3 | 2 – 3 | 3 – 3 |
| Cadenza di fuoco | % | tutti | 1,0 | +1,3% – +3,7% | +2,7% – +5,1% | +4,1% – +6,5% | +5,1% – +7,6% | +6,5% – +8,3% | +7,6% – +8,3% |
| Vel. proiettile | % | Arma, Guanti | **0 (disattivato)** | +5% – +12% | +9% – +16% | +13% – +20% | +16% – +23% | +20% – +25% | +23% – +25% |
| Velocità | % | Stivali, Pantaloni, Amuleto | 1,0 | +3% – +6,2% | +4,8% – +8% | +6,6% – +9,8% | +8% – +11,1% | +9,8% – +12% | +11,1% – +12% |
| Vita max | flat | Armatura, Pantaloni, Testa, Amuleto | 1,0 | 1 – 2 | 1 – 2 | 2 – 2 | 2 – 3 | 2 – 3 | 3 – 3 |
| Durata proiettile | % | Arma, Testa | **0 (disattivato)** | +5% – +13,8% | +10% – +18,8% | +15% – +23,8% | +18,8% – +27,5% | +23,8% – +30% | +27,5% – +30% |
| Raggio magnete | % | tutti | 0,8 | +10% – +20,5% | +16% – +26,5% | +22% – +32,5% | +26,5% – +37% | +32,5% – +40% | +37% – +40% |
| Bonus exp | flat % | tutti | 0,8 | +5% – +12% | +9% – +16% | +13% – +20% | +16% – +23% | +20% – +25% | +23% – +25% |
| Bonus drop | flat % | tutti | 0,8 | +5% – +12% | +9% – +16% | +13% – +20% | +16% – +23% | +20% – +25% | +23% – +25% |
| Invulnerabilità | flat s | Armatura, Testa | 0,6 | +0,05 – +0,10s | +0,08 – +0,13s | +0,11 – +0,16s | +0,13 – +0,19s | +0,16 – +0,20s | +0,19 – +0,20s |
| Spinta | % | Arma, Guanti | 0,6 | +10% – +20,5% | +16% – +26,5% | +22% – +32,5% | +26,5% – +37% | +32,5% – +40% | +37% – +40% |
| N. proiettili | flat | Arma, Anello | 0,25 | +1 | +1 | +1 | +1 | +1 | +1 |
| Perforazione | flat | Arma | 0,3 | +1 | +1 | +1 | +1 | +1 | +1 |

## 3. Pezzi

Per ogni pezzo: slot, statistiche base fisse (sempre presenti, escluse dal pool di bonus casuali per quello slot), arena/e di drop.

| Pezzo | Slot | Statistiche base | Drop in |
|---|---|---|---|
| Bacchetta di gelatina (`gel_wand`) | Arma | +1 Danno | Cripta, Ossario |
| Bacchetta rapida (`rapid_wand`) | Arma | +8% Cadenza di fuoco | Cripta, Ossario |
| Bacchetta d'osso (`bone_wand`) | Arma | +1 Danno, +1 Perforazione | Ossario |
| Amuleto del nucleo (`core_amulet`) | Amuleto | +2 Vita max | Cripta, Ossario |
| Cappuccio del vagabondo (`wanderer_hood`) | Testa | +20% Raggio magnete, +10% Bonus exp | Cripta, Ossario |
| Guanti del fabbro (`smith_gloves`) | Guanti | +4% Cadenza di fuoco, +20% Spinta | Cripta, Ossario |
| Armatura d'osso (`bone_armor`) | Armatura | +1 Vita max, +10% Invulnerabilità | Ossario |
| Pantaloni di cuoio (`leather_pants`) | Pantaloni | +5% Velocità, +1 Vita max | Cripta, Ossario |
| Stivali di gelatina (`slime_boots`) | Stivali | +10% Velocità | Cripta, Ossario |
| Anello di gelatina (`gel_ring`) | Anello | +10% Bonus drop | Cripta, Ossario |

## 4. Tasso di drop per arena

Il tasso è per **uccisione** (moltiplicato dal Bonus drop del player), oggetto base scelto a caso tra quelli della tabella; la rarità si tira separatamente coi pesi di §1 (min. Raro dai boss). Tetto rarità in run: Leggendario (il Mitico non si trova mai, solo da ricetta).

| Arena | Drop chance/uccisione | Pezzi in tabella | Chance per pezzo specifico | Boss |
|---|---|---|---|---|
| Cripta | 0,4% | 8 (tutti tranne i due d'osso) | ≈0,05% | 1 garantito, rarità ≥ Raro |
| Ossario | 0,6% | 10 (tutti) | ≈0,06% | 1 garantito, rarità ≥ Raro |

I due pezzi "d'osso" (Bacchetta d'osso, Armatura d'osso) cadono solo nell'Ossario.
