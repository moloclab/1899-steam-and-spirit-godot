extends "res://scripts/world/room.gd"
## Azioni e varianti della cabina; disposizione e risposte statiche sono nella scena.
## Mappa con calamita ancora presente; la scena fornisce entrambe le varianti grafiche.
@export var map_complete_texture: Texture2D
## Mappa dopo la raccolta: cambia la grafica, ma rimane disponibile lo stesso hotspot.
@export var map_collected_texture: Texture2D

## Churchill resta seduto durante le battute iniziali e si rialza alla chiusura.
func introduction(keys: Array[String]) -> Array[Row]:
	if keys.is_empty():
		return []
	var rows: Array[Row] = [row([spriteTo("player", "sit"), say("player", keys[0])])]
	for key in keys.slice(1):
		rows.append(row([say("player", key)]))
	rows.append(row([spriteTo("player", "idle")]))
	return rows

## Sceglie l'azione narrativa; tutti gli effetti restano differiti fino all'esecuzione.
func actions(state: State, hotspot_id: String, item_id: String = "", examining: bool = false) -> Array[Row]:
	if find_hotspot(hotspot_id) == null:
		return []
	if examining:
		if hotspot_id in ["map", "sink", "door"]:
			return [row([effect(_examine.bind(state, hotspot_id))])]
		return super.actions(state, hotspot_id, item_id, true)
	match hotspot_id:
		"sink":
			if item_id == "ep01_cabin_bottle" and _can_pour(state):
				return act_drop_bottle(state)
			if item_id == "ep01_cabin_magnet_feather":
				return act_collect_key(state)
			return [row([effect(_sink_response.bind(state, item_id))])]
		"door":
			if item_id == "ep01_cabin_key":
				return act_use_key(state)
			return [row([effect(_door_response.bind(state, item_id))])]
		"map":
			return [row([effect(_map_response.bind(state, item_id))])]
		"interphone":
			if item_id.is_empty():
				return talk_interphone()
	# Letto, oblò, raccoglibili e usi generici restano configurati nella scena.
	return super.actions(state, hotspot_id, item_id, examining)

## Raggiunge il centro del lavandino, parla, consuma il Bourbon e rivela la chiave nello scarico.
func act_drop_bottle(state: State) -> Array[Row]:
	return [
		row([walkTo("player", "sink", true)], _can_pour.bind(state)),
		row([spriteTo("player", "back"), say("player", "ep01.cabin.sink.pour_bourbon")], _can_pour.bind(state)),
		row([
			leaveObj("ep01_cabin_bottle"),
			say("player", "ep01.cabin.sink.surprise")
		], _can_pour.bind(state)),
		row([
			changeStatus("ep01_cabin", "sink_stage", 1),
			say("player", "ep01.cabin.sink.key_found")
		], _sink_at_stage.bind(state, 0), false)
	]

## La penna magnetica recupera la chiave; la risposta finale non aggiunge clic di chiusura.
func act_collect_key(state: State) -> Array[Row]:
	return [row([
		addObj("ep01_cabin_key"),
		changeStatus("ep01_cabin", "sink_stage", 2),
		say("player", "ep01.cabin.sink.key_pickup")
	], _can_collect_key.bind(state), false)]

## «Finalmente...» resta nella cabina; soltanto il clic seguente attraversa la porta.
func act_use_key(state: State) -> Array[Row]:
	return [
		row([
			leaveObj("ep01_cabin_key"),
			changeStatus("ep01_cabin", "door_unlocked", true),
			spriteTo("player", "back"),
			say("player", "ep01.cabin.door.exit")
		], _can_unlock.bind(state)),
		row([effect(_leave_after_unlock.bind(state))], _door_is_unlocked.bind(state))
	]

## Le quattro battute conservano ordine e interlocutori a ogni conversazione.
func talk_interphone() -> Array[Row]:
	return [
		row([say("player", "ep01.cabin.interphone.greeting")]),
		row([say("interphone", "ep01.cabin.interphone.summons")]),
		row([say("interphone", "ep01.cabin.interphone.urgency")]),
		row([say("player", "ep01.cabin.interphone.reply")])
	]

## I requisiti leggono lo stato corrente, senza consumare oggetti durante la pianificazione.
func _can_pour(state: State) -> bool:
	return state.has_item("ep01_cabin_bottle") and _sink_at_stage(state, 0)

## Stadi del lavandino: 0 iniziale, 1 chiave nello scarico, 2 chiave recuperata.
func _sink_at_stage(state: State, stage: int) -> bool:
	return state.get_progress("ep01_cabin", "sink_stage") == stage

## Il recupero è disponibile soltanto con l'attrezzo completo e la chiave nello scarico.
func _can_collect_key(state: State) -> bool:
	return state.has_item("ep01_cabin_magnet_feather") and _sink_at_stage(state, 1)

## Lo sblocco richiede ancora la chiave quando la riga viene eseguita.
func _can_unlock(state: State) -> bool:
	return state.has_item("ep01_cabin_key") and _sink_at_stage(state, 2)

## Il flag persistente permette il passaggio anche dopo il consumo della chiave.
func _door_is_unlocked(state: State) -> bool:
	return state.get_progress("ep01_cabin", "door_unlocked")

## Rivaluta il bersaglio; mappa e lavandino hanno descrizioni dipendenti dal progresso.
func _examine(state: State, hotspot_id: String) -> String:
	var hotspot := find_hotspot(hotspot_id)
	if hotspot == null:
		return "common.cannot_use"
	if hotspot_id == "map" and "ep01_cabin_magnet" in state.collected:
		return "ep01.cabin.map.examine_without_magnet"
	if hotspot_id == "sink" and _sink_at_stage(state, 1):
		return "ep01.cabin.sink.key_unreachable"
	return hotspot.examine(state)

## La calamita viene raccolta una volta sola; la mappa rimane esaminabile.
func _map_response(state: State, item_id: String) -> String:
	if find_hotspot("map") == null or not item_id.is_empty():
		return "common.cannot_use"
	return "ep01.cabin.magnet.pickup" if state.pick_up("ep01_cabin_magnet") else "ep01.cabin.map.examine_without_magnet"

## Risposte del lavandino che non avviano una sequenza narrativa.
func _sink_response(state: State, item_id: String) -> String:
	var hotspot := find_hotspot("sink")
	if hotspot == null:
		return "common.cannot_use"
	if item_id.is_empty():
		return "ep01.cabin.sink.key_unreachable" if _sink_at_stage(state, 1) else hotspot.interaction_response
	if item_id == "ep01_cabin_feather" and state.has_item(item_id) and _sink_at_stage(state, 1):
		return "ep01.cabin.sink.feather_failed"
	return "common.cannot_use"

## L'uscita generica risolve la destinazione; la stanza aggiunge il vincolo dell'enigma.
func _door_response(state: State, item_id: String) -> String:
	var hotspot := find_hotspot("door")
	if hotspot == null or not item_id.is_empty():
		return "common.cannot_use"
	if _door_is_unlocked(state):
		return hotspot.interact(state)
	match state.get_progress("ep01_cabin", "sink_stage"):
		1: return "ep01.cabin.door.key_needed"
		2: return "ep01.cabin.door.ready_to_leave"
	return "ep01.cabin.door.locked"

## Il passaggio non ripete la battuta della chiave nella nuova stanza.
func _leave_after_unlock(state: State) -> String:
	var response: String = $door.interact(state)
	return "" if state.room != definition.room_id else response

## Ricostruisce la mappa dal progresso, anche al rientro o caricando una partita precedente.
func sync_from_state(state: State) -> void:
	super.sync_from_state(state)
	$mapMagnet/Visual.texture = map_collected_texture if "ep01_cabin_magnet" in state.collected else map_complete_texture
