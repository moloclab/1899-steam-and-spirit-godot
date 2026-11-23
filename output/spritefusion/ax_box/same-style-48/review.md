# Ascia nella teca di vetro

Una chiamata Sprite Fusion `generate_sprites_in_style`, size 48, 15 crediti, nove varianti. Input e prompt in request.json; ID e URL in generation.json e downloads.json. Originale conservato in ax_box-original.png. Nessun asset originale o riferimento della scena modificato.

Sorgente 36x44, bounds (0,0,36,44), alpha binario. Hotspot 36x44 a (200,108). Tolleranza del soggetto: larghezza 35-37, altezza 42-46. Tutti gli output nativi hanno canvas 48x48 e alpha 0/255; nessun ridimensionamento o ritaglio dei nativi.

| Variante | Soggetto | Dimensioni conformi |
| --- | --- | --- |
| V1 | 39x45 | No, larghezza |
| V2 | 36x44 | Si |
| V3 | 34x44 | No, larghezza |
| V4 | 39x45 | No, larghezza |
| V5 | 37x44 | Si |
| V6 | 35x45 | Si |
| V7 | 36x44 | Si |
| V8 | 35x44 | Si |
| V9 | 36x44 | Si |

Controllo visivo a 4x e nativo: tutte mantengono ascia, cornice e piccola etichetta inferiore. V3, V4, V5, V7 e V8 rendono il vetro piu' esplicito con riflessi diagonali. V5 copre maggiormente la lama. V2, V6 e V9 mostrano bene l'ascia ma il vetro e' meno evidente. V1 introduce angoli decorativi piu' marcati. Le cerniere, il pomello e il profilo dell'ascia sono reinterpretati: la conformita' delle misure non basta ad approvare questi cambiamenti.

Il contorno esterno e' scuro e generalmente sottile; si osservano ispessimenti locali agli angoli e nei raccordi delle cerniere, particolarmente nelle versioni piu' elaborate. Non si certifica uniformita' di un pixel lungo tutto il perimetro delle nove varianti. Il bordo va verificato e, se necessario, corretto prima dell'integrazione secondo ASSET-REDESIGN.md. Cornice in legno e ombre interne sono distinte dal contorno esterno.

V7 e' il candidato consigliato per l'equilibrio fra vetro leggibile, ascia, etichetta e ingombro identico alla sorgente. La raccomandazione non costituisce approvazione dell'utente ne' certificazione del contorno.

comparison.png mostra originale e varianti a 4x nearest neighbor e 1x. context.png mostra una composizione statica sul fondale corrente del corridoio a 3x, ancorando il soggetto visibile a (200,108), senza gli altri oggetti o la patina: non e' una cattura Godot. Per un'eventuale integrazione preservare il nativo e rimuovere soltanto i margini completamente trasparenti della variante scelta.

Decisione finale: l'utente ha scelto «usa v3» dopo la segnalazione delle dimensioni fuori tolleranza. Integrata V3 come deroga specifica per il soggetto 34x44. Il controllo visivo della variante scelta mostra un contorno esterno scuro sottile; la cornice e i riflessi interni restano distinti dal bordo. Rimossi esclusivamente i margini trasparenti (7,2,34,44), senza modificare i pixel visibili: confronto con il nativo, zero differenze. Copia nativa conservata in ax_box-selected-native.png e originale precedente in ax_box-original.png. ax_box.png ora misura 34x44, hotspot aggiornato a 34x44; posizione (200,108), scala e interazioni invariati. Le altre varianti sono conservate.
