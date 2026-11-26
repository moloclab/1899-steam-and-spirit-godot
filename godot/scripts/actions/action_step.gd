extends Resource
class_name ActionStep
## Un passo di sequenza esplicito, configurabile nell'Inspector e privo di codice testuale da eseguire.
enum Kind { SAY, WALK, ANIMATE, WAIT, EFFECT, CHANGE_ROOM, HIDE, LEAVE, ADD, CHANGE_STATUS }
@export var kind: Kind = Kind.SAY
## Soggetto: character_id di un personaggio oppure hotspot_id di un oggetto.
@export var subject_id := "player"
@export var text_key := ""
## LEAVE e ADD: oggetto da rimuovere o aggiungere all'inventario durante l'esecuzione.
@export var item_id := ""
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
## CHANGE_STATUS: progresso costruito da script; il valore conserva il proprio tipo.
var progress_scope := ""
var progress_key := ""
var progress_value: Variant

## Cammino bloccante del soggetto esplicito verso il bordo o il centro di un hotspot della stanza.
static func walkTo(subject: String, hotspot_id: String, center: bool = false) -> ActionStep:
	var step := ActionStep.new()
	step.kind = Kind.WALK
	step.subject_id = subject
	step.target_hotspot_id = hotspot_id
	step.center_on_hotspot = center
	return step

## Battuta con soggetto esplicito; SAY e ANIMATE nella stessa riga uniscono voce e posa.
static func say(subject: String, key: String) -> ActionStep:
	var step := ActionStep.new()
	step.text_key = key
	step.subject_id = subject
	return step

## Il soggetto della posa va esplicitato; le animazioni finite possono bloccare la riga.
static func animate(subject: String, animation: String, wait: bool = false) -> ActionStep:
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

## Accoda la rimozione dall'inventario senza richiedere lo stato allo script della stanza.
static func leaveObj(item: String) -> ActionStep:
	var step := ActionStep.new()
	step.kind = Kind.LEAVE
	step.item_id = item
	return step

## Accoda l'aggiunta all'inventario; il catalogo e i duplicati vengono gestiti dallo stato.
static func addObj(item: String) -> ActionStep:
	var step := ActionStep.new()
	step.kind = Kind.ADD
	step.item_id = item
	return step

## Accoda un cambio di progresso senza modificare subito la partita.
static func changeStatus(scope: String, key: String, value: Variant) -> ActionStep:
	var step := ActionStep.new()
	step.kind = Kind.CHANGE_STATUS
	step.progress_scope = scope
	step.progress_key = key
	step.progress_value = value
	return step
