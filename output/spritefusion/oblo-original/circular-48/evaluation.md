# Oblò circolare: seconda prova

Sorgente: `godot/assets/graphics/ep01_cabin/oblo-original.png`, canvas e ingombro visibile 48×48, alpha binario. Nessuna modifica alla sorgente, allo spritesheet in uso o alle scene Godot.

Richiesta: oblò di sottomarino perfettamente circolare con acqua del mare visibile attraverso il vetro. Mantenuti il bordo in ottone e il livello dell'acqua a metà apertura già descritti dall'utente. Metodo `generate_sprites_in_style`, size 48, una chiamata, 15 crediti, nove varianti native. Non sono state usate le varianti precedenti come riferimenti. Prompt, riferimenti nell'ordine effettivo e ID degli output in `request.json`; corrispondenza file/ID in `files.json`.

Tutti i canvas sono 48×48, con trasparenza binaria. Ingombri visibili: 1=43×44, 2=43×43, 3=43×43, 4=43×44, 5=43×44, 6=43×44, 7=43×44, 8=43×43, 9=43×44. Tutti fuori dalla tolleranza 46–50 per asse. Nessun ridimensionamento, ritaglio o tentativo automatico aggiuntivo.

La silhouette delle varianti 2 e 8 ha dimensioni uguali e perfetta simmetria della maschera alpha orizzontale e verticale; questo controllo non dimostra da solo una circonferenza matematica. La variante 3 ha due pixel di differenza per asse nel confronto delle maschere riflesse. Le altre hanno un'altezza diversa dalla larghezza o maggiori irregolarità. Controlli in `outline-check.json`.

Contorno esterno scuro presente. Il campione superiore centrale delle varianti 1–6 e 8–9 passa dal contorno scuro all'ottone dopo un pixel; la 7 presenta invece tre pixel consecutivi molto scuri. Il controllo visivo mostra una lettura più fine rispetto alla prima prova; l'uniformità completa del bordo va ricontrollata sulla variante scelta prima dell'integrazione.

Valutazione visiva: 2 più scura e simmetrica; 8 simmetrica ma ottone verdastro; 3 ottone più caldo e acqua ben leggibile, con piccole irregolarità della sagoma. Nessuna variante è dichiarata pienamente conforme. Attendere scelta visiva ed eventuale deroga dimensionale prima di integrare. Non eseguita prova nella scena, né generata un'animazione.

Confronto nearest-neighbor, dimensione nativa e Churchill approvato in `comparison.png`. I PNG nativi sono conservati sia in questa cartella sia accanto alla sorgente con suffisso `-redesign`.

## Scelta dell'utente

L'utente ha scelto la variante 2 come base visiva. File: `godot/assets/graphics/ep01_cabin/oblo-original-redesign-2.png`, canvas 48×48 e soggetto 43×43. La scelta non comporta sostituzione dell'asset nella scena o generazione di animazioni. Conservate le altre varianti. Per il movimento, valutare una lavorazione locale dell'acqua mantenendo fissa la cornice, prima di richiedere ulteriori generazioni.

## Integrazione statica richiesta

Su successiva richiesta esplicita di sostituire la variante nel gioco per una prova senza animazione, sostituito `oblo.png` con il soggetto 43×43 della variante 2, ritagliando soltanto i margini trasparenti (2,2)-(45,45). Lo spritesheet precedente è conservato in `oblo-before-static.png`. Entrambi gli oblò della cabina condividono ora un singolo fotogramma, senza loop o autoplay. Visual traslati di (2.5,2.5) per mantenere il centro nell'ingombro originale 48×48; hotspot e posizioni delle interazioni conservati. Nessun ridimensionamento e nessuna nuova generazione.

Import Godot completato. Il test generale `prototype_test.gd` riporta 299 verifiche e 18 errori nei controlli di movimento e interfaccia, oltre a una chiamata `_toggle_help` non disponibile: non si dichiara superata la suite generale. Verifica mirata della configurazione statica in `check_static.gd`.
