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
	var hotspot := find_hotspot(hotspot_id)
	if hotspot == null:
		return []
	if examining:
		# La mappa descrive l'assenza della calamita dopo la raccolta.
		if hotspot_id == "map" and "ep01_cabin_magnet" in state.collected:
			return [row([say("player", "ep01.cabin.map.examine_without_magnet")], Callable(), false)]
		# Allo stadio 1 la chiave è visibile nello scarico, ma non ancora raggiungibile.
		if hotspot_id == "sink" and state.get_progress("ep01_cabin", "sink_stage") == 1:
			return [row([say("player", "ep01.cabin.sink.key_unreachable")], Callable(), false)]
		# Negli altri casi usa la descrizione dell'hotspot senza un clic aggiuntivo di chiusura.
		if hotspot_id in ["map", "sink", "door"]:
			return [row([say("player", hotspot.examine(state))], Callable(), false)]
		return super.actions(state, hotspot_id, item_id, true)
	match hotspot_id:
		"sink":
			# Il versamento richiede il Bourbon nell'inventario e il lavandino allo stadio iniziale.
			if item_id == "ep01_cabin_bottle" and state.has_item(item_id) and state.get_progress("ep01_cabin", "sink_stage") == 0:
				return act_drop_bottle()
			# Il recupero richiede l'attrezzo completo nell'inventario e la chiave nello scarico.
			if item_id == "ep01_cabin_magnet_feather" and state.has_item(item_id) and state.get_progress("ep01_cabin", "sink_stage") == 1:
				return act_collect_key()
			# A mani libere descrive la chiave nello scarico oppure usa la risposta della scena.
			if item_id.is_empty():
				if state.get_progress("ep01_cabin", "sink_stage") == 1:
					return [row([say("player", "ep01.cabin.sink.key_unreachable")], Callable(), false)]
				return [row([say("player", hotspot.interaction_response)], Callable(), false)]
			# La penna semplice non riesce a recuperare la chiave e non viene consumata.
			if item_id == "ep01_cabin_feather" and state.has_item(item_id) and state.get_progress("ep01_cabin", "sink_stage") == 1:
				return [row([say("player", "ep01.cabin.sink.feather_failed")], Callable(), false)]
			return [row([say("player", "common.cannot_use")], Callable(), false)]
		"door":
			# Lo sblocco richiede la chiave nell'inventario e il recupero completato.
			if item_id == "ep01_cabin_key" and state.has_item(item_id) and state.get_progress("ep01_cabin", "sink_stage") == 2:
				return act_use_key()
			# Gli altri usi di oggetti non aprono la porta.
			if not item_id.is_empty():
				return [row([say("player", "common.cannot_use")], Callable(), false)]
			# Dopo lo sblocco il passaggio usa la destinazione configurata nell'hotspot.
			if state.get_progress("ep01_cabin", "door_unlocked"):
				return super.actions(state, hotspot_id)
			# Prima dello sblocco la risposta segue il progresso dell'enigma.
			match state.get_progress("ep01_cabin", "sink_stage"):
				1: return [row([say("player", "ep01.cabin.door.key_needed")], Callable(), false)]
				2: return [row([say("player", "ep01.cabin.door.ready_to_leave")], Callable(), false)]
			return [row([say("player", "ep01.cabin.door.locked")], Callable(), false)]
		"map":
			# Le risposte restano visibili senza richiedere un clic di chiusura.
			# Gli oggetti usati sulla mappa non hanno effetto.
			if not item_id.is_empty():
				return [row([say("player", "common.cannot_use")], Callable(), false)]
			# La calamita viene raccolta una volta sola; la mappa rimane esaminabile.
			if "ep01_cabin_magnet" in state.collected or state.has_item("ep01_cabin_magnet"):
				return [row([say("player", "ep01.cabin.map.examine_without_magnet")], Callable(), false)]
			return [row([
				addObj("ep01_cabin_magnet"),
				say("player", "ep01.cabin.magnet.pickup")
			], Callable(), false)]
		"interphone":
			if item_id.is_empty():
				return talk_interphone()
	# Letto, oblò, raccoglibili e usi generici restano configurati nella scena.
	return super.actions(state, hotspot_id, item_id, examining)

## Raggiunge il centro del lavandino, parla, consuma il Bourbon e rivela la chiave nello scarico.
func act_drop_bottle() -> Array[Row]:
	return [
		row([walkTo("player", "sink", true)]),
		row([spriteTo("player", "back"), say("player", "ep01.cabin.sink.pour_bourbon")]),
		row([
			leaveObj("ep01_cabin_bottle"),
			say("player", "ep01.cabin.sink.surprise")
		]),
		row([
			changeStatus("ep01_cabin", "sink_stage", 1),
			say("player", "ep01.cabin.sink.key_found")
		], Callable(), false)
	]

## La penna magnetica recupera la chiave; la risposta finale non aggiunge clic di chiusura.
func act_collect_key() -> Array[Row]:
	return [row([
		addObj("ep01_cabin_key"),
		changeStatus("ep01_cabin", "sink_stage", 2),
		say("player", "ep01.cabin.sink.key_pickup")
	], Callable(), false)]

## «Finalmente...» resta nella cabina; soltanto il clic seguente attraversa la porta.
func act_use_key() -> Array[Row]:
	return [
		row([
			leaveObj("ep01_cabin_key"),
			changeStatus("ep01_cabin", "door_unlocked", true),
			spriteTo("player", "back"),
			say("player", "ep01.cabin.door.exit")
		]),
		# Il passaggio usa la destinazione della porta senza ripetere la battuta nella nuova stanza.
		row([changeRoom($door.destination_room, $door.destination_entry)])
	]

## Le quattro battute conservano ordine e interlocutori a ogni conversazione.
func talk_interphone() -> Array[Row]:
	return [
		row([say("player", "ep01.cabin.interphone.greeting")]),
		row([say("interphone", "ep01.cabin.interphone.summons")]),
		row([say("interphone", "ep01.cabin.interphone.urgency")]),
		row([say("player", "ep01.cabin.interphone.reply")])
	]

## Ricostruisce la mappa dal progresso, anche al rientro o caricando una partita precedente.
func sync_from_state(state: State) -> void:
	super.sync_from_state(state)
	$mapMagnet/Visual.texture = map_collected_texture if "ep01_cabin_magnet" in state.collected else map_complete_texture
