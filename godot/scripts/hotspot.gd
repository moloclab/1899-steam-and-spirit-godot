extends Node2D
class_name Hotspot
## Interfaccia comune degli oggetti, configurati direttamente nella scena della stanza.
## Lo stato viene passato esplicitamente: nessun oggetto dipende da singleton o dalla UI.
const State = preload("res://scripts/game_state.gd")
const Step = preload("res://scripts/actions/action_step.gd")
const Sequence = preload("res://scripts/actions/action_sequence.gd")
## ID stabile, usato dal coordinatore per ritrovare il bersaglio all'arrivo del personaggio.
@export var hotspot_id := ""
## Collega una voce del dialogo all'oggetto parlante, per esempio l'interfono.
@export var speaker_key := ""
## Rettangolo selezionabile nelle coordinate originali; parte dall'origine del nodo.
@export var hit_size := Vector2(40, 40)
## Sceglie il pannello dell'originale: mano per oggetti, bocca per persone, uscita per passaggi.
@export_enum("hand", "mouth", "exit") var interaction_kind := "hand"
## Risposte dei semplici oggetti statici, modificabili senza creare una sottoclasse.
## Gli ID vengono tradotti in testo dal coordinatore; qui non si costruiscono dialoghi UI.
@export var examine_response := "common.prototype_boundary"
@export var interaction_response := "common.prototype_boundary"
## Una conversazione configurata sostituisce la sola risposta a mani libere.
## Esame e uso di oggetti continuano a passare dalle regole specifiche dell'hotspot.
@export var conversation: Sequence
var highlighted := false:
	set(value):
		if highlighted == value:
			return
		highlighted = value
		# Il disegno personalizzato viene invalidato solo quando il coordinatore assegna il valore.
		queue_redraw()

## Crea una sequenza senza applicare effetti durante la pianificazione.
## Le sottoclassi possono comporre passi diversi leggendo lo stato corrente.
## La stanza delega qui esami statici, raccolte semplici e altre interazioni generiche.
func actions(state: State, item_id: String = "", examining: bool = false) -> Array[Step]:
	if not examining and item_id.is_empty() and conversation != null and not conversation.steps.is_empty():
		return conversation.steps.duplicate()
	return [Step.effect(execute.bind(state, item_id, examining))]

## Si ferma all'esterno del bordo dal lato del giocatore, usando l'area interattiva.
## Se il giocatore è già sopra l'oggetto, sceglie il bordo più vicino (sinistro a parità).
func approach_position(player_x: float, player_half_width: float) -> float:
	var room := get_parent()
	while room != null and not room.has_method("hotspots"):
		room = room.get_parent()
	var left := INF
	var right := -INF
	for corner in [Vector2.ZERO, Vector2(hit_size.x, 0), hit_size, Vector2(0, hit_size.y)]:
		var point := to_global(corner)
		var x: float = room.to_local(point).x if room != null else point.x
		left = minf(left, x)
		right = maxf(right, x)
	return left - player_half_width if player_x <= (left + right) / 2.0 else right + player_half_width

## Punto d'ingresso comune alle azioni: la lente ha precedenza sull'oggetto selezionato.
## Validare il possesso qui impedisce di usare una selezione consumata durante l'avvicinamento.
## Le sottoclassi specializzano i tre metodi sottostanti, non il coordinatore della stanza.
func execute(state: State, item_id: String = "", examining: bool = false) -> String:
	if examining:
		return examine(state)
	if not item_id.is_empty():
		if item_id not in state.inventory:
			return "common.cannot_use"
		return use_item(state, item_id)
	return interact(state)

## Descrizione statica predefinita. Gli oggetti con descrizioni dipendenti dal progresso la ridefiniscono.
func examine(_state: State) -> String:
	return examine_response

## Azione a mani libere: adatta anche a battute di persone e segnaposto del corridoio.
func interact(_state: State) -> String:
	return interaction_response

## Gli usi non previsti restituiscono la stessa risposta generica del prototipo precedente.
func use_item(_state: State, _item_id: String) -> String:
	return "common.cannot_use"

## Aggiorna la rappresentazione leggendo lo stato, senza modificarlo.
## Anche gli hotspot nascosti ricevono questa chiamata dopo caricamento o nuova partita.
func sync_from_state(_state: State) -> void:
	pass

## Verifica un punto globale dopo averlo convertito nelle coordinate locali dell'hotspot.
## Il margine di quattro pixel rende più agevoli i clic sugli oggetti piccoli.
func contains(point: Vector2) -> bool:
	return is_visible_in_tree() and Rect2(Vector2.ZERO, hit_size).grow(4).has_point(to_local(point))

## Disegna soltanto la cornice di selezione; l'immagine dell'oggetto è nel figlio Visual.
func _draw() -> void:
	if highlighted:
		draw_rect(Rect2(Vector2.ZERO, hit_size).grow(3), Color("e5bf73"), false, 1.0)
