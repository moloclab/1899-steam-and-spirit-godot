extends RefCounted
## Le definizioni appartengono alle scene delle stanze, senza file dati paralleli.
const Definitions = preload("res://scripts/data/scene_definitions.gd")
const SCENES := {
	"cabin": "res://scenes/rooms/cabin.tscn",
	"corridor": "res://scenes/rooms/corridor.tscn"
}
static var _rooms: Dictionary = {}
static var ROOMS: Dictionary:
	get:
		if _rooms.is_empty():
			for id in SCENES:
				_rooms[id] = Definitions.property(SCENES[id], "definition")
		return _rooms

## Restituisce null per un ID sconosciuto, prima di tentare caricamenti o transizioni.
static func get_room(room_id: String):
	return ROOMS.get(room_id)
