extends Resource
## Contenuti iniziali di un episodio, modificabili nell'Inspector senza cambiare il coordinatore.
@export var episode_id := ""
@export var initial_room := ""
@export var initial_entry := "default"
@export var music: AudioStream
@export var intro_keys: Array[String] = []
@export_file("*.json") var dictionary_path := ""
## Scena delle combinazioni dell'episodio, indipendente dalla stanza attiva.
@export_file("*.tscn") var combo_scene_path := ""
