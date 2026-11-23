extends Resource
## Metadati di una stanza condivisi da movimento, ingressi e validazione dei salvataggi.
## Il percorso mantiene il caricamento sincrono e non introduce dipendenze circolari fra script e scene.
@export var room_id := ""
@export var episode_id := ""
@export_file("*.tscn") var scene_path := ""
@export var width := 648.0
@export var walk_margin := 24.0
@export var floor_y := 200.0
## La scala intera mantiene uniformi i pixel di fondali e personaggi.
@export var visual_scale := 3.0
@export var entries: Dictionary[String, float] = {"default": 180.0}

## Mantiene il centro del personaggio entro la corsia percorribile della stanza.
func clamp_x(value: float) -> float:
	return clampf(value, walk_margin, width - walk_margin)
