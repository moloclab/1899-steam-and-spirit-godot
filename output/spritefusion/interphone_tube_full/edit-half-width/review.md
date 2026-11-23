# Edit Sprite Fusion: meta' larghezza

Richiesta: dimezzare la larghezza della V4, imboccatura compresa, ridisegnando le forme e conservando l'altezza. Una chiamata edit_sprite (15 crediti), input asset 3698ad64-3c8e-456e-929e-4014b4846fe6. Prompt e risultati in request.json e generation.json.

Il servizio ha restituito due immagini native senza margini trasparenti esterni:

| Risultato | Canvas e soggetto | Esito |
| --- | --- | --- |
| Edit 1 / redesign-5 | 37x121 | Non restringe l'ingombro originale |
| Edit 2 / redesign-6 | 21x114 | Piu' vicino all'obiettivo di 19x121, ma largo due pixel in piu' e alto sette pixel in meno |

Entrambi hanno alpha binario 0/255 e contorno scuro leggibile, con ispessimenti nei raccordi come nella V4. Edit 2 ridisegna meglio il volume dell'imboccatura rispetto alla compressione diretta. Non rispetta la richiesta di mantenere esattamente l'altezza: nessuna compensazione, riscalatura, ritaglio o ulteriore generazione applicata.

comparison.png mostra V4 originale, precedente riduzione diretta, Edit 1 e Edit 2, a 4x nearest neighbor e 1x. File nativi salvati come interphone_tube_full-redesign-5.png e interphone_tube_full-redesign-6.png accanto alla sorgente.

Scelta finale: «si, usa edit 2». Integrato il nativo 21x114 senza modifiche dei pixel, con hash SHA256 identico alla variante scaricata. Copia nativa in selected-native.png e versione sostituita in before-integration-19x121.png. Attacco superiore invariato a (478,0); hotspot spostato da (478,100) a (478,93) per seguire la bocca sette pixel piu' in alto, dimensioni 21x21 e offset Visual (0,-93). Scala, dialoghi e sequenza invariati.
