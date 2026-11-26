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
## WALK: raggiunge l'oggetto indicato; se vuoto usa target_x.
@export var target_hotspot_id := ""
## WALK verso un hotspot: false si ferma al bordo, true allinea i centri orizzontali.
@export var center_on_hotspot := false
@export var target_x := 0.0
@export var animation_name := ""
@export var seconds := 0.0
@export var destination_room := ""
@export var destination_entry := "default"
## Gli effetti personalizzati sono Callable creati a runtime; non vengono serializzati nei dati.
var callback: Callable

## Cammino bloccante verso il bordo o il centro di un hotspot della stanza.
static func walk_to(hotspot_id: String, center: bool = false, subject: String = "player") -> ActionStep:
	var step := ActionStep.new()
	step.kind = Kind.WALK
	step.subject_id = subject
	step.target_hotspot_id = hotspot_id
	step.center_on_hotspot = center
	return step

## Battuta indipendente: SAY e ANIMATE nella stessa riga permettono di parlare e cambiare posa insieme.
static func say(key: String, subject: String = "player") -> ActionStep:
	var step := ActionStep.new()
	step.text_key = key
	step.subject_id = subject
	return step

## Le pose cicliche partono senza attesa; le animazioni finite possono bloccare la riga.
static func animate(animation: String, subject: String = "player", wait: bool = false) -> ActionStep:
	var step := ActionStep.new()
	step.kind = Kind.ANIMATE
	step.subject_id = subject
	step.animation_name = animation
	step.wait_for_completion = wait
	return step

## Adatta le regole degli hotspot esistenti alla coda, rimandando la mutazione fino all'esecuzione.
static func effect(action: Callable) -> ActionStep:
	var step := ActionStep.new()
	step.kind = Kind.EFFECT
	step.callback = action
	return step
