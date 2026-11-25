# Cornice degli slot inventario

Richiesta: bordo dorato sottile con accenti steampunk discreti, canvas 48x48 da adattare a cura dell'utente.

Una chiamata Sprite Fusion same-style, 15 crediti, nove varianti native conservate in godot/assets/graphics/ui/inventory_frame-redesign*.png. Prompt, riferimenti e ID in generation.json. La precisazione dell'utente sui singoli slot e' arrivata dopo l'invio del prompt, che menzionava la fascia inventario; i risultati sono comunque cornici quadrate adatte alla valutazione per gli slot.

Tutti i canvas sono 48x48, alpha binario 0/255, centro trasparente. Misure in measurements.json. Nessun ridimensionamento o ritocco. Il confronto mostra scala nativa e ingrandimento 3x su fondo scuro.

Consigliata V6: lati sottili, quattro piccoli raccordi in ottone, decorazione contenuta. V2 e' la scelta piu' minimale, con richiami steampunk quasi assenti. V1 ha angoli piu' evidenti; V8 e V9 sono piu' ingombranti. I bordi scuri sono sottili; la leggibilita' va verificata quando l'utente adattera' la cornice allo slot.

Scelta dell'utente: V2 per gli oggetti non selezionati, V9 per l'oggetto selezionato. Integrate in game_ui.gd come cornici sovrapposte agli slot, con centro trasparente e dimensioni dello slot invariate. Il focus da tastiera conserva l'indicazione cromatica. La bussola conserva lo stile esistente. Importazione e avvio headless Godot 4.7.2 completati senza errori; resa visiva nel gioco non verificata.
