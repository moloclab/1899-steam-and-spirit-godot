extends "res://scripts/hotspot.gd"
## Comportamento condiviso: l'ID rimanda all'inventario della stanza di origine.
@export var item_id := ""
## Chiave della battuta mostrata soltanto quando la raccolta viene registrata con successo.
@export var pickup_response := "common.nothing_interesting"

## Prepara la raccolta senza modificare lo stato; usi e conversazioni seguono le regole comuni.
func interact(state: State, used_item_id: String = "") -> Array[Row]:
	if not used_item_id.is_empty() or (conversation != null and not conversation.rows.is_empty()):
		return super.interact(state, used_item_id)
	# Un oggetto sconosciuto, già posseduto o raccolto non viene aggiunto nuovamente.
	if not State.Items.has_item(item_id) or state.has_item(item_id) or item_id in state.collected:
		return [Row.of([Step.say("player", "common.nothing_interesting")], Callable(), false)]
	var steps: Array[Step] = [Step.addObj(item_id)]
	if not pickup_response.is_empty():
		steps.append(Step.say("player", pickup_response))
	return [Row.of(steps, Callable(), false)]

## Si usa collected, non inventory: un componente combinato o consumato non deve riapparire.
func sync_from_state(state: State) -> void:
	visible = item_id not in state.collected
