extends "res://scripts/hotspots/room_exit.gd"
## La porta della cabina specializza una normale uscita aggiungendo il vincolo della chiave.

## Dopo lo sblocco il passaggio eredita il comportamento dell'uscita semplice.
## Prima dello sblocco la risposta accompagna il progresso dell'enigma del lavandino.
func interact(state: State) -> String:
	if state.door_unlocked:
		return super.interact(state)
	return "cabin.door.key_needed" if state.sink_stage == 1 else ("cabin.door.ready_to_leave" if state.sink_stage == 2 else "cabin.door.locked")

## La chiave viene consumata una sola volta; il flag persistente permette i passaggi successivi.
func use_item(state: State, item_id: String) -> String:
	if item_id == "key" and item_id in state.inventory and state.sink_stage == 2:
		state.inventory.erase(item_id)
		state.door_unlocked = true
		return interact(state)
	return "common.cannot_use"
