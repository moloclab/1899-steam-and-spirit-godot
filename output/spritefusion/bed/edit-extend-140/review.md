# Allungamento del letto con edit_sprite

Richiesta: allungare la variante 5 integrata fino alla larghezza originale di 140 px. Una chiamata edit_sprite, 15 crediti. Nessun retry o ridimensionamento dei risultati.

Preparazione dichiarata prima della generazione: canvas 140x39, letto attuale 120x39 disegnato senza scala a (0,0), 20 colonne trasparenti a destra per consentire l'estensione. Copia precedente in bed-before.png, input in bed-input-140.png. Prompt e ID dei risultati in generation.json.

| Risultato | Canvas e soggetto visibile | Alpha |
| --- | --- | --- |
| bed-extended-1.png | 140x39 | 0/255 |
| bed-extended-2.png | 165x34 | 0/255 |

Il risultato 1 raggiunge esattamente la larghezza richiesta e mantiene l'altezza attuale. L'edit ha comunque ridisegnato alcuni dettagli del cuscino e delle pieghe; non garantisce identita dei pixel del letto precedente. Il secondo risultato modifica anche l'altezza e supera la larghezza richiesta.

Output nativi conservati in questa cartella e accanto a bed.png. comparison.png mostra precedente e risultati a ingrandimento nearest neighbor 4x.

L'utente ha approvato il risultato 1. Copiato il PNG nativo 140x39 in bed.png senza ritagli o ridimensionamenti; verificata l'identita SHA256 dei file. Hotspot aggiornato a 140x39 nella scena ep01_cabin.tscn, posizione (18,161) invariata e base a y=200. Conservata la versione precedente in bed-before.png. Nessuna verifica in esecuzione Godot.
