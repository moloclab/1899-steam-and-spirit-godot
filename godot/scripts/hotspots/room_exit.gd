extends "res://scripts/hotspot.gd"
## Passaggio senza enigma: destinazione e coordinata di ingresso si impostano nell'Inspector.
@export_enum("cabin", "corridor") var destination_room := "cabin"
@export var entry_x := 550.0

## Non istanzia scene: modifica solo i dati che il coordinatore controlla dopo l'azione.
func interact(state: State) -> String:
	state.room = destination_room
	state.player_x = entry_x
	return interaction_response
