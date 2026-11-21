# Prova comò con palette flessibile

Una chiamata `generate_sprites_in_style`, `size: 48`, costo 15 crediti, nove varianti. Sorgente richiesta: `godot/assets/graphics/ep01_cabin/como.gif`, 40×36 px visibili. I riferimenti sono elencati in ordine in `request.json`; il quinto è la tavola dei 128 colori, allegata come riferimento visivo senza parametro `palette`, che imporrebbe colori esatti.

Gli output nativi sono salvati accanto alla sorgente come `como-redesign.png` e da `como-redesign-2.png` a `como-redesign-9.png`. Nessun output è stato ritagliato, ridimensionato o integrato. Il comò già usato dalla scena resta `como.png`.

## Controlli

Tutti i canvas sono 48×48 e tutti gli output hanno alpha 0/255. Le dimensioni visibili sono comprese nella tolleranza prevista di 38–42 px in larghezza e 35–37 px in altezza. I valori dettagliati e i colori opachi sono in `validation.json`. La percentuale di pixel esattamente nella palette è puramente descrittiva e non costituisce un criterio di accettazione.

| Variante | Soggetto visibile | Osservazione sul disegno |
| --- | --- | --- |
| 1 | 40×36 | Aggiunge fasce con rivetti, serratura e suddivisione del frontale. |
| 2 | 40×36 | Mantiene un pannello ma aggiunge una maniglia ad anello e grandi angolari color rame. |
| 3 | 39×36 | Introduce pannello sagomato, ferramenta e angolari color rame. |
| 4 | 40×37 | Introduce due cassetti; bordo superiore prevalentemente marrone, da uniformare al contorno scuro. |
| 5 | 39×37 | Cambia il frontale con cassetto, doghe e rinforzi; bordo superiore da uniformare. |
| 6 | 39×36 | Legno e ombreggiatura leggibili, ma introduce due cassetti. |
| 7 | 40×36 | Cambia il pannello e aggiunge ferramenta e angolari. |
| 8 | 40×36 | Introduce due cassetti e fasce metalliche. |
| 9 | 40×37 | Mantiene un pannello ma aggiunge chiusura superiore e rivetti. |

Il contorno scuro è visibile in molte varianti, soprattutto 1, 2, 3, 6, 7, 8 e 9. La somiglianza del contorno non risolve le modifiche al soggetto. Non certificare un bordo uniformemente di un pixel sulla sola base delle dimensioni o della presenza di una linea scura.

## Confronti e decisione

`comparison.png` mostra originale, comò precedente e Churchill, seguiti dai nove output a ingrandimento nearest neighbor 4× e con un campione nativo. `context.png` è un montaggio statico 2× sul fondale della cabina con lavabo e calamaio alle coordinate della scena. I soggetti visibili sono appoggiati alla quota y=200 senza scalare i pixel, usando soltanto il rettangolo visibile durante il disegno del montaggio. Non è una cattura del gioco o una verifica dell'esecuzione in Godot.

La palette fornisce una base cromatica utilizzabile; gli output restano nella gamma calda e scura delle sorgenti, con libertà di sfumature. Il limite principale di questa prova è la fedeltà al disegno: ogni variante aggiunge o cambia elementi rispetto alla sorgente. Nessuna viene quindi considerata completamente conforme alla guida per l'integrazione automatica. La variante 6 è utile per valutare il legno e il contrasto, ma richiede una scelta esplicita sul cambiamento a due cassetti.

## Scelta e integrazione

L'utente ha scelto esplicitamente la variante 9 e richiesto la rimozione delle altre. La scelta approva per questo asset i cambiamenti al frontale e alla ferramenta segnalati sopra.

Integrato il rettangolo visibile (4, 5, 40, 37) in `como.png`, verificando che ogni pixel corrisponda al nativo. Il canvas nativo è conservato come `como-selected-native.png` e il comò precedente come `como-before-selection.png` in questa cartella. Nella scena la posizione passa da (224, 164) a (224, 163), con hotspot 40×37: la base resta a y=200. Nessun cambio di scala.

Eliminate le altre otto varianti e gli eventuali `.import` dopo aver verificato l'assenza di riferimenti Godot. Conservata la variante 9 anche accanto alla sorgente. `downloads.json`, i confronti e la prima valutazione descrivono la generazione iniziale; i file delle varianti scartate non sono più presenti. La libreria Sprite Fusion non è stata modificata. Il montaggio del contesto resta un'anteprima statica precedente all'integrazione, non una verifica del gioco avviato.

Stato: variante 9 integrata; altre otto varianti locali eliminate. Nessuna seconda generazione.
