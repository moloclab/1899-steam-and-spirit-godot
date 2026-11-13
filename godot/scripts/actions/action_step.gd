extends Resource
class_name ActionStep
## Un passo di sequenza esplicito, configurabile nell'Inspector e privo di codice testuale da eseguire.
enum Kind { SAY, WALK, ANIMATE, WAIT, EFFECT, CHANGE_ROOM }
@export var kind: Kind = Kind.SAY
@export var text_key := ""
@export var speaker := "Winston Churchill"
@export var wait_for_completion := true
@export var character_id := "player"
@export var target_x := 0.0
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
