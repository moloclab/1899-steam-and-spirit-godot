extends "res://scripts/hotspot.gd"
## Regole locali del lavandino: lo stadio appartiene all'ambito persistente cabin, non al nodo.

## La chiave nello scarico modifica sia la descrizione sia la risposta all'interazione a mani libere.
func examine(state: State) -> String:
	return "ep01.cabin.sink.key_unreachable" if state.get_progress("ep01_cabin", "sink_stage") == 1 else "ep01.cabin.sink.examine"

func interact(state: State) -> String:
	return "ep01.cabin.sink.key_unreachable" if state.get_progress("ep01_cabin", "sink_stage") == 1 else "ep01.cabin.sink.wash"

## Mantiene la sequenza dell'originale: Bourbon -> chiave nello scarico -> penna magnetica -> chiave raccolta.
## Le condizioni sullo stadio impediscono consumi ripetuti e duplicazione della chiave.
func use_item(state: State, item_id: String) -> String:
	if item_id not in state.inventory:
		return "common.cannot_use"
	if item_id == "ep01_cabin_bottle" and state.get_progress("ep01_cabin", "sink_stage") == 0:
		state.remove_item(item_id)
		state.set_progress("ep01_cabin", "sink_stage", 1)
		return "ep01.cabin.sink.key_dropped"
	if item_id == "ep01_cabin_magnet_feather" and state.get_progress("ep01_cabin", "sink_stage") == 1:
		state.add_item("ep01_cabin_key")
		state.set_progress("ep01_cabin", "sink_stage", 2)
		return "ep01.cabin.sink.key_pickup"
	if item_id == "ep01_cabin_feather" and state.get_progress("ep01_cabin", "sink_stage") == 1:
		# Tentativo plausibile, ma la penna da sola non aggancia la chiave.
		return "ep01.cabin.sink.feather_failed"
	return "common.cannot_use"
