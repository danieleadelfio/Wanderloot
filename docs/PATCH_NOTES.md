# Patch Notes (beta)

Note in linguaggio semplice per i beta tester. Ogni versione elenca solo cosa cambia rispetto alla precedente. Le note tecniche complete sono in `docs/CHANGELOG.md`.

## e72df9b — 26/09/2026

### Correzioni
- Fusione: il tooltip, il tutorial del fabbro e la voce del Codex dicevano ancora "tre oggetti" per fondere un item al tier successivo. Ora dicono correttamente "sei", come il gioco richiede da qualche versione.

### Novità
- Nuova statistica **Mana** (valore assoluto) visibile nella scheda Statistiche, sia in hub che in run.
- Nuovo potenziamento di run **Riserva**: +10% mana massimo. L'aumento si accredita subito al mana attuale, non è un rabbocco gratuito.

## ab6409e — 26/09/2026

### Bilanciamento
- Fusione: serve **sei** oggetti dello stesso tipo e tier (prima tre) per ottenere un pezzo del tier successivo.
- Fabbro: il costo in risorse per craftare ogni pezzo è **triplicato**.
- Raggio magnete (calamita per il loot): il bonus ottenibile da equip e potenziamenti di run è ridotto a **un terzo** di prima.

## 707aeab — 26/09/2026

### Bilanciamento
- Danno e Vita massima: i bonus che prima erano un numero fisso (es. "+1 danno", "+1 HP") ora sono **percentuali** (es. "+10% danno", "+10% HP"), sia sui pezzi di equip che sui potenziamenti di run. Stesso principio già usato per la cadenza di fuoco.

## 594be3f — 26/09/2026

### Bilanciamento
- Riscalati danno, vita e esperienza in tutto il gioco (circa x100 rispetto a prima): vita del player, danno delle armi, HP/exp dei nemici e dei boss. È un cambio di scala interno, il gioco si gioca allo stesso modo — serve solo per dare più margine ai numeri futuri.

## In lavorazione — 26/09/2026

### Novità
- Arene **10 volte più grandi** (stessi rapporti di prima, tutto scalato x10: muri, decorazioni, zona di spawn).
- La zona di estrazione non compare comunque mai a più di 1000px dal player, anche su un'arena così grande.

## In lavorazione (2) — 26/09/2026

### Novità
- Mappa dell'arena: premi **M** per aprirla (o Esc per chiuderla). Mostra i confini dell'arena e la tua posizione; i punti di interesse arriveranno in futuro.
- Sulla mappa puoi piazzare fino a **5 indicatori** con un clic: ognuno diventa una freccia colorata a bordo schermo per orientarti verso quel punto (il giallo è riservato al portale di estrazione).
- Nuova **minimappa** in alto a destra durante la run: ti tiene sempre al centro, con una bussola N/S/E/O sul bordo, e mostra i tuoi indicatori e il portale quando è attivo.
- Il tutorial dell'obiettivo di run ora ricorda anche il tasto M.

## In lavorazione (3) — 26/09/2026

### Novità
- Le statistiche a sinistra in run si possono nascondere con un pulsante accanto al titolo, comodo nei combattimenti più affollati.
- Il tutorial e il Codex del Passo d'ombra ora spiegano che durante lo scatto sei invulnerabile e attraversi i nemici senza subire danno.

### Miglioramenti visivi
- L'attacco a carica in linea di alcuni boss ora mostra una striscia rettangolare unica invece di una fila di cerchi separati.

## In lavorazione (4) — 26/09/2026

### Bilanciamento
- I nemici ora compaiono in una fascia di distanza ragionevole dal player (appena fuori vista, ma abbastanza vicini da arrivare in fretta), non più ovunque nell'arena enorme: prima capitava che arrivassero già furiosi solo per la lunga camminata. (aggiustato: 700–1200px di spawn, despawn oltre 1600px)
- Se ti allontani troppo, i nemici rimasti troppo indietro spariscono e vengono sostituiti da altri più vicini a te.
