extends RefCounted
## Risolve testi e traduzioni indipendentemente dalla UI e dalle regole degli oggetti.
var language := "it"
var entries: Dictionary = {}

## Un catalogo illeggibile produce un errore esplicito e conserva il ripiego per le risposte.
func _init() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/dialogue.json"))
	if parsed is Dictionary:
		entries = parsed
	else:
		push_error("Catalogo dei dialoghi non leggibile.")

## Le alternative originali separate da | continuano a mostrare la prima risposta.
func text(key: String) -> String:
	var entry: Variant = entries.get(key)
	if not entry is Dictionary:
		push_warning("Testo mancante: " + key)
		entry = entries.get("common.missing_response", {})
	return str(entry.get(language, entry.get("it", "Non saprei cosa farci."))).split("|")[0]
