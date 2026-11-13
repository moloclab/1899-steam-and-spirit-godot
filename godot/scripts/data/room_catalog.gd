extends RefCounted
## Elenco delle stanze disponibili: per aggiungerne una bastano scena e relativa definizione.
const ROOMS := {
	"cabin": preload("res://assets/data/rooms/cabin.tres"),
	"corridor": preload("res://assets/data/rooms/corridor.tres")
}

## Restituisce null per un ID sconosciuto, prima di tentare caricamenti o transizioni.
static func get_room(room_id: String):
	return ROOMS.get(room_id)
