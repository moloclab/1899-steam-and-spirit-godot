# Valutazione del redesign door_sub

Una chiamata same-style, size 128, costo 15 crediti. Originale 76x116; tutte le quattro varianti hanno canvas 128x128 e soggetto visibile 76x116, bounds [26,6,102,122], alpha binario 0/255. Intervallo ammesso: larghezza 73..79, altezza 111..121. Tutte conformi per ingombro.

Confronto visivo a risoluzione nativa e ingrandimento nearest neighbor 2x: contorno esterno scuro sottile generalmente di un pixel, separato dai profili interni della cornice metallica. Nessun alone o antialiasing osservato. Lo spessore nei raccordi angolari resta da confermare sulla variante selezionata prima dell'integrazione.

Variante 1 consigliata: mantiene pannelli ampi, oblò leggibile e metallo bronzo/oliva coerente. L'oblò appare più grande dell'originale. Variante 2: più linee orizzontali, oblò più piccolo e reticolato. Variante 3: tono più verde e pannelli verticali inferiori diversi dall'originale. Variante 4: ombreggiatura più netta e dettagli laterali aggiunti. Queste differenze richiedono scelta visiva dell'utente.

cabin-preview.png è un compositing statico sul fondale attuale, con centro e base allineati alla porta della cabina (x=544..620, base y=200). Non è una cattura runtime Godot. La porta compare anche nella scena corridoio: verifica runtime e raccordi in entrambe le stanze da eseguire dopo la scelta.

Originale, guida e riferimenti delle scene non modificati da questa prova. Varianti native conservate accanto all'originale. Nessun ritaglio o ridimensionamento applicato. Decisione: in attesa della scelta dell'utente.