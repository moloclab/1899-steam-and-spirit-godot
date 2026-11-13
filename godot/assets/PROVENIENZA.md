# Risorse provvisorie del prototipo

Le immagini in `graphics/original/` derivano esclusivamente dai file locali del gioco
originale `EP01/img`. Nessuna risorsa grafica è stata scaricata da terzi.

- `cabin_background.png` e `corridor_background.png`: ritagli 648×275 e 892×275 di `room.jpg`.
- Altri PNG: conversioni dei GIF omonimi, preservando dimensioni e trasparenza.
- PNG numerati e file `.tres`: fotogrammi e animazioni dai GIF originali. La velocità
  usa il ritardo del primo fotogramma del GIF.
- `O_*.png`: icone originali dell'inventario.
- `panel_hand.png`, `panel_mouth.png`, `panel_exit.png`: pannelli a due scelte dai GIF
  originali; mostrati a scala 1.5× con filtro nearest nel menu delle azioni.
- `data/dialogue.json`: selezione dei testi italiani/inglesi di `EP01/js/dictionary.js`,
  migrati a chiavi descrittive e campi `it`/`en`, con le conversazioni adattate del prototipo.
  È l'unico catalogo, curato manualmente e non rigenerato dall'importatore.
  Il prototipo visualizza la versione italiana e la prima alternativa separata da `|`.
- `audio/`: cartella predisposta per risorse future; al momento contiene solo un README.

`graphics/cursors/cursor_normal.png` e `cursor_magnifier.png` sono nuovi cursori
trasparenti 32×32, generati con lo strumento integrato ImageGen e adattati con ritaglio
e ridimensionamento nearest-neighbor. Riferimento stilistico: `original/panel_exit.png`.
Prompt: freccia verso l'alto a sinistra e lente con manico in basso a destra, isolate,
pixel art monocromatica bianco/grigio/nero anni Novanta, contorno nero, sfondo trasparente,
senza testo, pannelli o elementi aggiuntivi, leggibili a 32×32 pixel.

Coordinate e oggetti delle scene provengono da `EP01/rooms/room1.html` e `room2.html`.
Le regole iniziali seguono `room1.js` e la combinazione `cmb_FeatherMagnet` in `js/combo.js`.
Le brevi conversazioni nel prototipo sono adattate dai testi originali.

Queste risorse servono al prototipo locale. Titolarità e licenze di immagini,
audio e font del gioco originale devono essere inventariate prima della distribuzione
commerciale, come previsto nell'analisi iniziale. Non sono stati importati font o audio.
