extends "res://scripts/hotspots/room_exit.gd"
## La porta della cabina specializza una normale uscita aggiungendo il vincolo della chiave.

## Dopo lo sblocco il passaggio eredita il comportamento dell'uscita semplice.
## Prima dello sblocco la risposta accompagna il progresso dell'enigma del lavandino.
func interact(state: State) -> String:
	if state.get_progress("ep01_cabin", "door_unlocked"):
		return super.interact(state)
	return "ep01.cabin.door.key_needed" if state.get_progress("ep01_cabin", "sink_stage") == 1 else ("ep01.cabin.door.ready_to_leave" if state.get_progress("ep01_cabin", "sink_stage") == 2 else "ep01.cabin.door.locked")

## La chiave viene consumata una sola volta; il flag persistente permette i passaggi successivi.
func use_item(state: State, item_id: String) -> String:
	if item_id == "ep01_cabin_key" and item_id in state.inventory and state.get_progress("ep01_cabin", "sink_stage") == 2:
		state.remove_item(item_id)
		state.set_progress("ep01_cabin", "door_unlocked", true)
		return interact(state)
	return "common.cannot_use"
