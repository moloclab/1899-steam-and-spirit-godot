extends RefCounted
## Le definizioni appartengono alle scene degli episodi, senza file dati paralleli.
const Definition = preload("res://scripts/data/episode_definition.gd")
const Definitions = preload("res://scripts/data/scene_definitions.gd")
const DEFAULT_EPISODE := "ep01"
const COMMON_DICTIONARY := "res://assets/dictionaries/common/dictionary.json"
const EPISODES := {
	"ep01": "res://scenes/episodes/ep01/ep01.tscn"
}
static var _episodes: Dictionary = {}

static func get_episode(episode_id: String) -> Definition:
	if not EPISODES.has(episode_id):
		return null
	if _episodes.has(episode_id):
		return _episodes[episode_id]
	var definition = Definitions.property(EPISODES[episode_id], "definition")
	if not definition is Definition or definition.episode_id != episode_id:
		push_error("Definizione episodio non valida: " + episode_id)
		return null
	_episodes[episode_id] = definition
	return definition
