# Queen: confronto delle varianti

Originale: 30x43 px, bounds 0,0,30,43. Alpha 253 e 255: sfondo grigio sostanzialmente opaco. Tolleranza: larghezza 29-31, altezza 41-45 px.

Una chiamata same-style, size 48, 15 crediti, nove varianti. Prompt, riferimenti ordinati, ID e URL nativi in generation.json. Misure in measurements.csv. Confronto con originale e Churchill in comparison.png: ingrandimenti nearest neighbor e immagini native.

| Varianti | Canvas | Ingombro alpha |
| --- | --- | --- |
| V1-V5 | 48x48 | 48x48 |
| V6 | 48x48 | 47x48 |
| V7 | 49x49 | 48x49 |
| V8-V9 | 49x49 | 49x48 |

Tutte fuori tolleranza: il generatore ha esteso lo sfondo al canvas anziche conservare il rettangolo verticale richiesto. Non sono state ridimensionate o ritagliate. Le misure alpha includono lo sfondo opaco, come nella sorgente, e non isolano la figura della regina.

Valutazione visiva: V4 conserva il velo e l'abito chiaro senza la fascia scura aggiunta in altre varianti; e la proposta piu vicina al soggetto, pur variandone volto e proporzioni. V7-V9 rimuovono il velo e si allontanano dall'originale. I contorni sono scuri, prevalentemente sottili e a gradini, ma si ispessiscono in alcuni raccordi tra corona, capelli e collo: il requisito uniforme di un pixel non e pienamente soddisfatto. Alcuni output presentano pixel colorati indesiderati sul perimetro del canvas.

Nessun risultato e pronto per l'integrazione automatica. Occorrono scelta visiva e deroga dimensionale esplicita; il bordo e gli artefatti richiedono correzione prima dell'integrazione. Nessun riferimento diretto a queen.png trovato nelle scene o negli script correnti: la prova dentro la scena non e stata eseguita. Originale e scene invariati; nessuna rigenerazione automatica.
