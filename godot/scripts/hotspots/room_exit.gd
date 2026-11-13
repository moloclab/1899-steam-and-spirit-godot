extends "res://scripts/hotspot.gd"
## Passaggio senza enigma: stanza e ingresso nominato si impostano nell'Inspector.
## Le coordinate appartengono alla definizione della destinazione e possono cambiare senza aggiornare le uscite.
@export var destination_room := "cabin"
@export var destination_entry := "default"

## Non istanzia scene: modifica solo i dati che il coordinatore controlla dopo l'azione.
func interact(state: State) -> String:
	return interaction_response if state.enter_room(destination_room, destination_entry) else "common.cannot_use"
