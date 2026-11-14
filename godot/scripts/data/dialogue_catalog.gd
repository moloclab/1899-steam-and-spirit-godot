extends RefCounted
## Risolve testi e traduzioni indipendentemente dalla UI e dalle regole degli oggetti.
const Episodes = preload("res://scripts/data/episode_catalog.gd")
var language := "it"
var entries: Dictionary = {}
var episode_id := ""
var _loaded_episodes: Dictionary = {}

## Un catalogo illeggibile produce un errore esplicito e conserva il ripiego per le risposte.
func _init(starting_episode: String = Episodes.DEFAULT_EPISODE) -> void:
	load_episode(starting_episode)

## Conserva i cataloghi precedenti: gli oggetti portati da altri episodi mantengono nome e descrizione.
func load_episode(next_episode: String) -> bool:
	if not _ensure_episode(next_episode):
		return false
	episode_id = next_episode
	return true

func _ensure_episode(next_episode: String) -> bool:
	if _loaded_episodes.has(next_episode):
		return true
	var episode = Episodes.get_episode(next_episode)
	if episode == null:
		return false
	var merged := entries.duplicate()
	var catalog_paths: Array[String] = [episode.dialogue_path]
	if _loaded_episodes.is_empty():
		catalog_paths.push_front(Episodes.COMMON_DIALOGUE)
	for catalog_path in catalog_paths:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(catalog_path))
		if not parsed is Dictionary:
			push_error("Catalogo dei dialoghi non leggibile: " + catalog_path)
			return false
		for key in parsed:
			var prefix := "common." if catalog_path == Episodes.COMMON_DIALOGUE else next_episode + "."
			if not key is String or not key.begins_with(prefix) or merged.has(key) or not parsed[key] is Dictionary:
				push_error("Chiave dei dialoghi duplicata o non valida: " + str(key))
				return false
			merged[key] = parsed[key]
	entries = merged
	_loaded_episodes[next_episode] = true
	return true

## Le alternative originali separate da | continuano a mostrare la prima risposta.
func text(key: String) -> String:
	# Un salvataggio può contenere oggetti di un episodio non ancora visitato in questa esecuzione.
	if not entries.has(key):
		var origin_episode := key.get_slice(".", 0)
		if Episodes.EPISODES.has(origin_episode):
			_ensure_episode(origin_episode)
	var entry: Variant = entries.get(key)
	if not entry is Dictionary:
		push_warning("Testo mancante: " + key)
		entry = entries.get("common.missing_response", {})
	return str(entry.get(language, entry.get("it", "Non saprei cosa farci."))).split("|")[0]
