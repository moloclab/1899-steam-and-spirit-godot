# Valutazione magnete inventario

- Una chiamata Sprite Fusion same-style, size 48, costo 15 crediti, nove output. Prompt, riferimenti ordinati e ID in `generation.json`.
- Originale: canvas 40x40, soggetto 15x15, bounds (13,12)-(27,26), alpha binario. SHA256 9CB9A56D7C0AEACF5F24D0E16D18EA2213F80110FA8D2C2EA969CCE2D9F18876, invariato dopo la prova.
- Tutti i risultati nativi: canvas 48x48, alpha esclusivamente 0/255, nessuna modifica ai pixel generati. Misure individuali in `measurements.json`.
- Tolleranza 95-105%: per entrambe le dimensioni il solo intero ammissibile e 15. Solo V6 (15x15) e conforme. V1 15x16; V2 12x12; V3 13x15; V4 14x15; V5 14x16; V7 14x15; V8 13x16; V9 13x15 richiedono deroga esplicita per l'ingombro.
- Controllo visivo su grigio e ingrandimento nearest-neighbor: V6 presenta contorno esterno nero continuo, sostanzialmente di un pixel, senza aloni o antialiasing. Alcune altre varianti hanno tratti non uniformi (in particolare il lato superiore sinistro di V3 e V8). Nessuna di esse e candidata conforme all'integrazione per le dimensioni.
- V6 mantiene corpo cilindrico grigio e faccia rossa superiore; aggiunge un riflesso sul bordo metallico e sulla faccia. E la candidata consigliata.
- `comparison.png` mostra originale e nove varianti alla scala 2x attualmente usata dall'inventario e un dettaglio 8x, con Churchill e calamaio approvati in basso. La fascia nera simula il fondo dei pulsanti: non e uno screenshot della scena in esecuzione.
- Nessuna sostituzione dell'originale e nessun aggiornamento di scena o script. Approvazione visiva dell'utente ancora da ricevere. La verifica nella scena effettiva resta da eseguire all'integrazione.

## Integrazione approvata

L'utente ha scelto V1 con il messaggio 'usa v1', approvando l'ingombro 15x16. Integrata nel percorso originale eliminando solo i margini trasparenti: regione (16,16), 15x16 dal canvas 48x48. Pixel RGBA verificati uno per uno dopo il salvataggio. Originale conservato in original.png e nativo in selected-v1-native.png. Nessuna modifica a scene, script o scala di visualizzazione. Varianti conservate. Verifica nel gioco non eseguita.

Aggiornamento richiesto dall'utente: V1 centrata in canvas trasparente 40x40, soggetto 15x16 invariato in posizione (12,12). La regola di ritaglio per l'integrazione e ora subordinata al canvas comune delle icone inventario, documentato in ASSET-REDESIGN.md. Controllate tutte le cinque icone in uso: ricentrate anche bottiglia (+1 px x) e chiave (-1 px x), senza modificare i soggetti. Backup in ../inventory-canvas-40/.
