# Redesign chiave della cabina

Metodo: Sprite Fusion `generate_sprites_in_style`, size 32, una chiamata, 15 crediti.
Prompt completo, riferimenti in ordine e ID dei nove asset in `generation.json`.

Sorgente: canvas 50x50, bounds (18,9,13,32), alpha binario. Chiave della porta della cabina: anello in alto, stelo verticale e denti a destra. Nessun hotspot della stanza modificato: questa texture e' l'icona inventario della chiave in ep01_cabin.tscn.

Intervallo ammesso del soggetto: larghezza 13, altezza 31-33. Canvas nativi generati 32x32, tutti con alpha binario.

| Variante | Soggetto | Conforme per dimensioni |
| --- | --- | --- |
| 1 | 12x32 | No |
| 2 | 11x29 | No |
| 3 | 15x31 | No |
| 4 | 14x31 | No |
| 5 | 9x30 | No |
| 6 | 14x31 | No |
| 7 | 14x29 | No |
| 8 | 12x31 | No |
| 9 | 12x31 | No |

Il confronto mostra originale, riferimenti e varianti a dimensione nativa e ingranditi con pixel replicati; per le chiavi include anche scala 2x, corrispondente alla visualizzazione del canvas inventario 50x50 nel pulsante 100x100. Non e' una verifica nella scena Godot: resta da svolgere dopo la scelta, insieme al centraggio su canvas finale 50x50 senza ridimensionare il soggetto.

Valutazione visiva: la 1 conserva meglio l'ingombro verticale e la struttura semplice, con contorno esterno scuro sottile, generalmente di un pixel, leggibile all'ingrandimento. L'anello e' piu' romboidale dell'originale. La 4 mantiene un anello piu' arrotondato ma e' piu' larga. La 9 introduce un elemento intermedio assente dalla sorgente e non e' consigliata. Tutte richiedono una deroga dimensionale esplicita prima dell'integrazione. Il controllo definitivo del bordo resta legato alla variante scelta.

Decisione: l'utente ha scelto esplicitamente "usa v8" dopo la segnalazione degli scostamenti dimensionali. Approvata la V8 con ingombro 12x31, in deroga per questo asset. Integrata in `inventory_key.png` su canvas trasparente 50x50, bounds (19,9,12,31), margini sinistra/destra 19/19 e alto/basso 9/10. Pixel del soggetto e contorno nativi invariati; alpha binario verificato pixel per pixel dopo il salvataggio. Il contorno della V8 e' scuro e sottile, di un pixel, leggibile su anello, stelo e denti. Originale conservato in `original.png`; risultati nativi e varianti conservati. Nessuna modifica ai riferimenti di scena o alla scala. Verifica visiva nella scena Godot non eseguita.
