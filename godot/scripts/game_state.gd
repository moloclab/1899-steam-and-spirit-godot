extends RefCounted
## Stato persistente indipendente dalle scene e dal formato dei salvataggi.
const Items = preload("res://scripts/data/item_catalog.gd")
const Rooms = preload("res://scripts/data/room_catalog.gd")
const Progress = preload("res://scripts/data/progress_schema.gd")
const Episodes = preload("res://scripts/data/episode_catalog.gd")

## collected registra la raccolta definitiva; un oggetto consumato non riappare nella stanza.
var inventory: Array[String] = []
var collected: Array[String] = []
var progress: Dictionary = Progress.defaults()
var room := ""
var player_x := 0.0
var episode_id: String:
	get:
		var definition = Rooms.get_room(room)
		return definition.episode_id if definition != null else ""

## La posizione iniziale appartiene all'ingresso della stanza configurata nell'episodio.
func _init(starting_episode: String = Episodes.DEFAULT_EPISODE) -> void:
	var episode = Episodes.get_episode(starting_episode)
	if episode == null:
		push_error("Episodio iniziale sconosciuto: " + starting_episode)
		return
	var definition = Rooms.get_room(episode.initial_room)
	if definition == null or definition.episode_id != starting_episode:
		push_error("Stanza iniziale non valida per l'episodio: " + starting_episode)
		return
	enter_room(episode.initial_room, episode.initial_entry)

## L'accesso ai progressi è circoscritto all'enigma, con i valori iniziali dello schema.
func get_progress(scope: String, key: String) -> Variant:
	return progress[scope][key]

## Le stesse regole di validazione vengono usate durante il gioco e il caricamento.
func set_progress(scope: String, key: String, value: Variant) -> bool:
	if not Progress.accepts(scope, key, value):
		push_error("Progresso non valido: %s.%s" % [scope, key])
		return false
	progress[scope][key] = value
	return true

## Tutte le aggiunte passano dal catalogo: nessun ID sconosciuto entra nell'inventario.
func add_item(item: String) -> bool:
	if not Items.has_item(item) or has_item(item):
		return false
	inventory.append(item)
	return true

## Rimuove soltanto il possesso attuale, preservando la memoria della raccolta.
func remove_item(item: String) -> void:
	inventory.erase(item)

## Espone il controllo del possesso senza richiedere l'accesso diretto alla lista.
func has_item(item: String) -> bool:
	return item in inventory

## Gli oggetti creati da un enigma o da una ricetta non sono raccolte dalla scena.
func pick_up(item: String) -> bool:
	if not Items.has_item(item) or not Items.ITEMS[item].collectible or item in collected:
		return false
	if not add_item(item):
		return false
	collected.append(item)
	return true

## La ricetta decide consumi, risultati e risposta; gli ingredienti devono essere posseduti.
func combine(first: String, second: String) -> String:
	if first == second or not has_item(first) or not has_item(second):
		return "common.cannot_use"
	var recipe = Items.combination(first, second)
	return recipe.apply(self) if recipe != null else "common.cannot_combine"

## Gli ingressi hanno nomi stabili: le uscite non devono conoscere coordinate di altre stanze.
func enter_room(room_id: String, entry_id: String) -> bool:
	var definition = Rooms.get_room(room_id)
	if definition == null or not definition.entries.has(entry_id):
		push_error("Ingresso sconosciuto: %s/%s" % [room_id, entry_id])
		return false
	room = room_id
	player_x = definition.clamp_x(definition.entries[entry_id])
	return true
