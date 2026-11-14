extends "res://scripts/hotspot.gd"
## Comportamento condiviso: l'ID deriva dalla definizione incorporata nella scena.
var item_id: String:
	get:
		return inventory_definition.item_id if inventory_definition != null else ""
@export var pickup_response := "common.nothing_interesting"

## La raccolta è registrata nello stato prima di nascondere l'oggetto nella successiva sincronizzazione.
## pick_up restituisce false se era già stato raccolto: nessuna copia viene aggiunta due volte.
func interact(state: State) -> String:
	return pickup_response if state.pick_up(item_id) else "common.nothing_interesting"

## Si usa collected, non inventory: un componente combinato o consumato non deve riapparire.
func sync_from_state(state: State) -> void:
	visible = item_id not in state.collected
