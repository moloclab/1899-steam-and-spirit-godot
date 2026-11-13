extends RefCounted
## Dati persistenti, combinazioni e salvataggi; le azioni delle stanze appartengono agli hotspot.

# user:// è la cartella dati dell'applicazione gestita da Godot, separata dai sorgenti del progetto.
const SAVE_PATH := "user://cabin_save.json"
# Elenco degli identificatori ammessi nel salvataggio di questo prototipo.
const ITEMS := ["bottle", "feather", "magnet", "magnetFeather", "key"]
# inventory rappresenta ciò che si possiede adesso; collected ciò che è già stato tolto dalla stanza.
# Consumare o combinare un oggetto lo rimuove soltanto da inventory: non deve riapparire nel fondale.
var inventory: Array[String] = []
var collected: Array[String] = []
var sink_stage := 0 # 0: chiave nascosta; 1: nello scarico; 2: recuperata.
# Una volta aperta, la porta resta attraversabile anche dopo aver consumato la chiave.
var door_unlocked := false
# Punto d'ingresso e stanza vengono salvati insieme al progresso dell'enigma.
var room := "cabin"
var player_x := 180.0

## Registra sia il possesso attuale sia la raccolta definitiva dell'oggetto dalla stanza.
## Restituisce false se già raccolto, evitando duplicati anche con chiamate ripetute.
func pick_up(item: String) -> bool:
	if item in collected:
		return false
	collected.append(item)
	inventory.append(item)
	return true

## Combina due oggetti posseduti, accettando entrambi gli ordini di selezione.
## Un tentativo non previsto restituisce una risposta senza consumare alcun oggetto.
func combine(first: String, second: String) -> String:
	if first == second or first not in inventory or second not in inventory:
		return "common.cannot_use"
	if (first == "feather" and second == "magnet") or (first == "magnet" and second == "feather"):
		# I due componenti spariscono dal possesso attuale e diventano un unico strumento.
		inventory.erase("feather")
		inventory.erase("magnet")
		inventory.append("magnetFeather")
		return "inventory.magnet_feather.combine"
	return "common.cannot_combine"

## Scrive un'istantanea dello stato in JSON e restituisce un codice Error di Godot.
## Il percorso opzionale permette ai test di usare un file distinto dal salvataggio del giocatore.
func save_game(path: String = SAVE_PATH) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	# La versione identifica il formato, non la versione di Godot. Servirà per eventuali migrazioni future.
	# Non salviamo nodi, texture, selezioni UI o azioni in attesa: solo i dati della partita.
	file.store_string(JSON.stringify({"version": 1, "inventory": inventory, "collected": collected,
		"sink_stage": sink_stage, "door_unlocked": door_unlocked, "room": room, "player_x": player_x}, "\t"))
	file.close()
	return OK

## Legge e valida formato, tipi e identificatori del salvataggio prima di applicarli.
## I controlli sono strutturali: non ricostruiscono tutta la coerenza narrativa di un file modificato a mano.
func load_game(path: String = SAVE_PATH) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var data = JSON.parse_string(file.get_as_text())
	# Un JSON sintatticamente valido non è necessariamente un salvataggio di questo gioco.
	if not data is Dictionary or data.get("version") != 1:
		return ERR_FILE_CORRUPT
	if not data.get("inventory") is Array or not data.get("collected") is Array:
		return ERR_FILE_CORRUPT
	# JSON legge i numeri come float: Array.has([0,1,2]) distinguerebbe int e float.
	if not (data.get("sink_stage") is float or data.get("sink_stage") is int):
		return ERR_FILE_CORRUPT
	if data.sink_stage < 0 or data.sink_stage > 2 or data.sink_stage != floor(data.sink_stage) or not data.get("door_unlocked") is bool:
		return ERR_FILE_CORRUPT
	if data.get("room") not in ["cabin", "corridor"] or not (data.get("player_x") is float or data.get("player_x") is int):
		return ERR_FILE_CORRUPT
	var loaded_inventory: Array[String] = []
	# I dati vengono raccolti in liste temporanee tipizzate e senza duplicati.
	# Gli oggetti combinati e la chiave sono ammessi nell'inventario, ma non nella lista di raccolta.
	var loaded_collected: Array[String] = []
	for item in data.inventory:
		if item not in ITEMS or item in loaded_inventory:
			return ERR_FILE_CORRUPT
		loaded_inventory.append(item)
	for item in data.collected:
		if item not in ["bottle", "feather", "magnet"] or item in loaded_collected:
			return ERR_FILE_CORRUPT
		loaded_collected.append(item)
	# Non modificare la partita corrente finché tutto il file non è stato validato.
	inventory = loaded_inventory
	collected = loaded_collected
	sink_stage = int(data.sink_stage)
	door_unlocked = data.door_unlocked
	room = data.room
	# Una coordinata esterna ai limiti viene riportata nella corsia percorribile della stanza caricata.
	player_x = clampf(float(data.player_x), 24.0, 624.0 if room == "cabin" else 868.0)
	return OK
