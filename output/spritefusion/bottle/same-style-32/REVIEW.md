# Bottiglia di whiskey per terra

Una chiamata Sprite Fusion `generate_sprites_in_style`, size 32, 15 crediti.
Prompt completo, ID e URL degli output: `generation.json`.
Input nell'ordine: `bottle.png`, `characters/churchill/churchill-stand.png`, `feather.png`, `godot/palette/1899-base-128-swatches.png` (tutti sotto `godot/assets/graphics` eccetto la palette).

Originale: canvas e soggetto visibile 28x12, alpha binario. Posizione (364,188), base y=200, hotspot 28x12. I blocchi originali sono ampi e uniformi; nessun ulteriore ingrandimento applicato agli input.
Intervallo consentito: larghezza 27-29, altezza 12. Tutti gli output hanno canvas 32x32 e alpha binario. Misure complete in `measurements.json`.

| Variante | Soggetto visibile | Esito |
|---|---|---|
| 1 | 32x13 | Fuori tolleranza |
| 2 | 31x27 | Fuori tolleranza, due bottiglie |
| 3 | 32x14 | Fuori tolleranza |
| 4 | 32x12 | Fuori tolleranza |
| 5 | 31x12 | Fuori tolleranza |
| 6 | 32x27 | Fuori tolleranza, due bottiglie |
| 7 | 31x14 | Fuori tolleranza |
| 8 | 32x14 | Fuori tolleranza |
| 9 | 32x12 | Fuori tolleranza |

Contorno: tutte le varianti hanno un bordo esterno scuro e diagonali a gradini. Le fasce scure interne adiacenti al bordo rendono alcuni tratti piu pesanti, soprattutto 1, 5 e 8. La 9 presenta un bordo prevalentemente sottile e leggibile; la verifica visiva finale precede qualsiasi integrazione. Nessuna variante dichiarata pienamente conforme: tutte superano l'ingombro consentito, 2 e 6 contengono inoltre un soggetto duplicato.

`comparison.png` mostra originale, nove varianti e Churchill, con ingrandimenti nearest-neighbor e simulazioni statiche del contesto sul fondale attuale. Le simulazioni mantengono x=364 e base y=200; sono mockup, non test eseguiti nel gioco. Le dimensioni native restano intatte. Le copie native sono conservate sia accanto all'originale sia in questa cartella.

Decisione: il 22 novembre 2026 l'utente ha scelto la variante 9 dopo la segnalazione della larghezza maggiore. Integrata in `godot/assets/graphics/ep01_cabin/bottle.png`, ritagliando soltanto i margini completamente trasparenti: rettangolo (0,10,32,12) dal canvas 32x32. Verificata l'identita di ogni pixel con il nativo e l'assenza di pixel visibili fuori dal ritaglio. Originale conservato in `bottle-original.png`; nativo conservato in `bottle-redesign-9.png`. Posizione (364,188) e base y=200 invariate, hotspot aggiornato a 32x12. Nessun ridimensionamento, correzione o rigenerazione. Le altre varianti restano conservate. Verifica statica e dei pixel; nessun test interattivo nel gioco.
