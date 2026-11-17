extends Resource
class_name ActionStep
## Un passo di sequenza esplicito, configurabile nell'Inspector e privo di codice testuale da eseguire.
enum Kind { SAY, WALK, ANIMATE, WAIT, EFFECT, CHANGE_ROOM, HIDE }
@export var kind: Kind = Kind.SAY
## Soggetto: character_id di un personaggio oppure hotspot_id di un oggetto.
@export var subject_id := "player"
@export var text_key := ""
## Solo ANIMATE: attende la fine dell'animazione prima di accettare il clic successivo.
@export var wait_for_completion := true
## WALK: raggiunge il bordo dell'oggetto indicato; se vuoto usa target_x.
@export var target_hotspot_id := ""
@export var target_x := 0.0
## SAY ed EFFECT possono impostare una posa insieme alla battuta, senza un clic aggiuntivo.
@export var animation_name := ""
@export var seconds := 0.0
@export var destination_room := ""
@export var destination_entry := "default"
## Gli effetti personalizzati sono Callable creati a runtime; non vengono serializzati nei dati.
var callback: Callable

## Adatta le regole degli hotspot esistenti alla coda, rimandando la mutazione fino all'esecuzione.
static func effect(action: Callable) -> ActionStep:
	var step := ActionStep.new()
	step.kind = Kind.EFFECT
	step.callback = action
	return step
