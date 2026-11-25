# Bussola inventario: prova del 25 novembre 2026

Metodo: Sprite Fusion `generate_sprites_in_style`, size 48, una chiamata da 15 crediti, nove risultati. Prompt completo, riferimenti in ordine e ID sono in `generation.json`. Risultati nativi salvati come `godot/assets/graphics/ui/option-redesign.png` e `option-redesign-2.png` fino a `option-redesign-9.png`. Nessuna conversione cromatica o modifica dei pixel.

La guida corrente richiede soggetto entro 40x40 e canvas finale trasparente 40x40; prevale sui precedenti materiali di prova da 50x50.

Originale corrente: canvas 50x50, soggetto 27x32, bounds (11,8), alpha binario. Copia conservata qui come `original.png`.

| Variante | Canvas nativo | Soggetto | Entro 40x40 |
| --- | --- | --- | --- |
| V1 | 48x48 | 38x47 | No |
| V2 | 48x48 | 38x41 | No |
| V3 | 48x48 | 38x45 | No |
| V4 | 48x48 | 38x46 | No |
| V5 | 48x48 | 38x42 | No |
| V6 | 48x48 | 38x45 | No |
| V7 | 48x48 | 38x44 | No |
| V8 | 48x48 | 38x46 | No |
| V9 | 48x48 | 38x47 | No |

Tutti i risultati hanno alpha binario 0/255. Il confronto mostra originale e varianti a scala 2x e dettaglio nearest neighbor 5x, con Churchill e magnete approvati. Sono anteprime, non una verifica in scena.

Valutazione visiva: la direzione diagonale dell'ago e la cassa in ottone sono leggibili. Il quadrante chiaro sostituisce il quadrante scuro della sorgente. Il bordo esterno appare scuro e prevalentemente sottile; la ghiera ha più fasce concentriche interne e alcuni raccordi scuri più pesanti. V2 ha l'attacco superiore più contenuto e il disegno più semplice, ma supera comunque il limite in altezza. La conformità esatta del bordo dovrà essere ricontrollata sulla variante scelta prima dell'integrazione.

Decisione finale: l'utente ha scelto V2 ("usa v2") dopo la segnalazione del superamento dimensionale. Integrata in `option.png` con deroga al canvas: 40x41 trasparente, soggetto 38x41 centrato in (1,0). Rimossi solo i margini trasparenti nativi, senza ridimensionamento o taglio di pixel visibili. Confronto pixel per pixel con V2: zero differenze, alpha binario. Originale e `selected-v2-native.png` conservati. Il contorno scuro sottile e il piccolo attacco superiore sono leggibili all'ispezione della variante scelta. Nessuna modifica a script, scene o scala 2x nearest esistente. Nessuna prova in scena eseguita; verifica limitata al PNG e al codice UI attuale. Dettagli in `integration.json`.
