extends Resource
## Definizione immutabile di un oggetto: il possesso appartiene a GameState.
## Una sola risorsa raccoglie ID, testi, icona e possibilità di raccolta dalla stanza.
@export var item_id := ""
@export var name_key := ""
@export var description_key := ""
@export var icon: Texture2D
@export var collectible := false
