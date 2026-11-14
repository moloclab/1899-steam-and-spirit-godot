extends RefCounted
## Serializzazione e validazione separate dallo stato e dalle regole narrative.
const State = preload("res://scripts/game_state.gd")
const Items = preload("res://scripts/data/item_catalog.gd")
const Rooms = preload("res://scripts/data/room_catalog.gd")
const Progress = preload("res://scripts/data/progress_schema.gd")
const Episodes = preload("res://scripts/data/episode_catalog.gd")
const SAVE_PATH := "user://game_save.json"
const VERSION := 3

## Salva esclusivamente dati persistenti; le sequenze in corso appartengono al runtime.
static func snapshot(state: State) -> Dictionary:
	return {"version": VERSION, "inventory": state.inventory.duplicate(),
		"collected": state.collected.duplicate(), "progress": state.progress.duplicate(true),
		"episode": state.episode_id, "room": state.room, "player_x": state.player_x}

## Scrive prima un temporaneo: un errore di scrittura non tronca il salvataggio precedente.
static func save_game(state: State, path: String = SAVE_PATH) -> Error:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(state), "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
	return error

## Applica i campi solo dopo la validazione completa: un file corrotto lascia intatta la partita.
## I controlli garantiscono formato e tipi, senza ricostruire ogni possibile vincolo narrativo.
static func load_game(state: State, path: String = SAVE_PATH) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	# Il parser a istanza restituisce l'errore senza registrare come errore del motore un file utente corrotto.
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not parser.data is Dictionary:
		return ERR_FILE_CORRUPT
	var data: Dictionary = parser.data
	if data.get("version") != VERSION or not data.get("inventory") is Array or not data.get("collected") is Array:
		return ERR_FILE_CORRUPT
	if not data.get("room") is String or Rooms.get_room(data.room) == null:
		return ERR_FILE_CORRUPT
	if not data.get("episode") is String or Episodes.get_episode(data.episode) == null \
		or Rooms.get_room(data.room).episode_id != data.episode:
		return ERR_FILE_CORRUPT
	if not (data.get("player_x") is float or data.get("player_x") is int) or not is_finite(float(data.player_x)):
		return ERR_FILE_CORRUPT
	var loaded_progress := Progress.normalize(data.get("progress"))
	if loaded_progress.is_empty():
		return ERR_FILE_CORRUPT
	var loaded_inventory: Array[String] = []
	var loaded_collected: Array[String] = []
	for item in data.inventory:
		if not item is String or not Items.has_item(item) or item in loaded_inventory:
			return ERR_FILE_CORRUPT
		loaded_inventory.append(item)
	for item in data.collected:
		if not item is String or not Items.has_item(item) or not Items.ITEMS[item].collectible or item in loaded_collected:
			return ERR_FILE_CORRUPT
		loaded_collected.append(item)
	state.inventory = loaded_inventory
	state.collected = loaded_collected
	state.progress = loaded_progress
	state.room = data.room
	state.player_x = Rooms.get_room(state.room).clamp_x(float(data.player_x))
	return OK
