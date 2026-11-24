# Valutazione penna d'oca dell'inventario

- Sorgente: `godot/assets/graphics/ep01_cabin/inventory_feather.png`, PNG 40x40, bounds visibili (4,4)-(35,35), soggetto 32x32, alpha binario 0/255. Penna color avorio con punta della piuma in alto a sinistra e pennino in basso a destra. Nessun calamaio nell'icona.
- Backup immutato in `original.png`; SHA256 ABD9F11799B9BB913F3D51EAA754F9024207F0948588BBEB6D9F0D5E2BA30683 verificato anche dopo la generazione.
- Una chiamata Sprite Fusion same-style, size 48, 15 crediti. Riferimenti nell'ordine: originale, Churchill approvato, calamaio con penna approvato, campioni della palette flessibile. Prompt e ID in `generation.json`.
- Nove PNG nativi 48x48 salvati accanto all'originale con suffisso -redesign e numerazione. Tutti hanno alpha 0/255. Nessuna modifica ai risultati nativi.
- La tolleranza del soggetto originale 32x32 ammette 31-33 px su ciascun asse. Nessun risultato rientra nell'intervallo.
- V1: 42x46; V2: 29x29; V3: 41x46; V4: 43x44; V5: 42x46; V6: 43x46; V7: 42x44; V8: 40x45; V9: 42x44. Bounds completi in `measurements.json`.
- V2 conserva la diagonale originale ma risulta piu piccola, con bordo esterno chiaro anziche scuro e pennino poco leggibile; non conforme anche per il contorno. Le altre otto varianti hanno contorno nero generalmente sottile e leggibile, ma alcuni raccordi diagonali risultano piu spessi e il bordo non e sempre uniforme. Invertono la diagonale rispetto all'originale, con pennino in basso a sinistra, e superano almeno una dimensione del canvas finale 40x40.
- Il confronto `comparison.png` mostra originale e risultati con dettaglio nearest-neighbor 5x e vista 2x. Per V2 viene simulato il centraggio 40x40; per gli output che non entrano nel canvas si mostra il nativo 48x48 senza adattamenti. Churchill e calamaio sono riportati come riferimenti stilistici. Non e una cattura del gioco.
- Nessun risultato integrato e nessun riferimento di scena modificato. Nessuna rigenerazione automatica. Una successiva prova con size 32 e soggetto quasi a pieno canvas potrebbe ridurre il rischio di superare l'ingombro, ma richiede una nuova scelta dell'utente e non garantisce l'orientamento o il bordo.

## Integrazione approvata e canvas 50x50

L'utente ha scelto V7 dopo il confronto, approvando l'ingombro 42x44 e l'inclinazione mostrata. Ha richiesto per tutte le icone PNG trasparenti 50x50. V7 integrata in inventory_feather.png, soggetto invariato centrato in (4,3); nativo conservato in selected-v7-native.png. Tutte le cinque icone in uso sono state ricentrate su canvas 50x50 senza ridimensionare i soggetti; backup e misure in ../inventory-canvas-50/. Verificati i pixel RGBA dopo il salvataggio e la trasparenza dei margini. Aggiornata la guida e adattate le altezze di riga e contenitore per la visualizzazione 2x con spazio per lo scorrimento orizzontale. Le varianti e il confronto precedente restano materiali storici della prova con la regola 40x40.
