extends SceneTree
## Verifica la matrice con la scena reale, clic utente e più azioni bloccanti contemporanee.
const Main = preload("res://scenes/main.tscn")
const Step = preload("res://scripts/actions/action_step.gd")
const Row = preload("res://scripts/actions/action_row.gd")
const Player = preload("res://scenes/characters/churchill.tscn")
var checks := 0
var failures := 0
var game: Control

## Mantiene il tipo delle righe anche nelle matrici costruite direttamente nei casi di prova.
func start(rows: Array[Row]) -> void:
	game._start_actions(rows)

## Il viewport viene preparato prima della UI e della stanza.
func _initialize() -> void:
	root.size = root.content_scale_size
	_run.call_deferred()

## Ogni errore produce un codice finale utilizzabile da riga di comando.
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

## Il clic passa dal coordinatore, come quello del giocatore.
func click() -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(100, 400)
	game._input(event)

## Ogni movimento ha un proprio soggetto e una destinazione della stanza.
func walk(subject: String, x: float) -> Step:
	var action := Step.new()
	action.kind = Step.Kind.WALK
	action.subject_id = subject
	action.target_x = x
	return action

## I timer delle colonne sono indipendenti anche quando le durate coincidono.
func wait(seconds: float) -> Step:
	var action := Step.new()
	action.kind = Step.Kind.WAIT
	action.seconds = seconds
	return action

## Le matrici vengono condivise come risorse, ma tutti i dati di esecuzione sono privati del runner.
func _run() -> void:
	game = Main.instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	var first := Step.say("player", "ep01.cabin.interphone.greeting")
	var second := Step.say("player", "ep01.cabin.interphone.reply")
	var third := Step.say("interphone", "ep01.cabin.interphone.summons")
	var walking := walk("player", 250)
	walking.target_hotspot_id = "como"
	var matrix: Array[Row] = [Row.of([first, Step.animate("player", "back")]), Row.of([walking]), Row.of([second]), Row.of([third])]
	start(matrix)
	check(game.ui.speech_label.text == game._text(first.text_key) and game.rooms.actor.animation == &"back", "Riga 1 avvia insieme frase e posa")
	check(game.sequences.waiting_for_confirmation and game.ui.save_buttons[0].disabled, "Riga immediata attende il clic e protegge il salvataggio")
	click()
	var target: Hotspot = game.rooms.find_hotspot("como")
	check(game.rooms.actor.target_x == target.approach_position(game.rooms.actor.current_x, game.rooms.actor.half_width), "Riga 2 raggiunge il bordo del comodino")
	check(not game.ui.speech_label.visible, "Avvio del cammino chiude la battuta precedente")
	click()
	check(not game.sequences.waiting_for_confirmation, "Clic durante il cammino ignorato")
	game._process(10)
	check(game.rooms.actor.has_arrived() and game.ui.speech_label.text == game._text(second.text_key), "Arrivo avvia automaticamente la riga 3")
	game._process(10)
	check(game.ui.speech_label.text == game._text(second.text_key), "Il clic anticipato non salta la riga 3")
	click()
	check(game.ui.speech_label.text == game._text(third.text_key) and game.ui._speaker_key == "common.speaker.interphone", "Il clic successivo cambia riga e interlocutore")
	click()
	check(not game.sequences.busy and not game.ui.speech_label.visible and not game.ui.save_buttons[0].disabled, "Ultimo clic chiude e sblocca la UI")
	check(matrix[0].actions.size() == 2 and matrix[0].actions[1].animation_name == "back", "La matrice configurata non viene modificata")
	# Il centraggio deve funzionare da entrambi i lati e avviare la posa solo all'arrivo.
	for origin in [100.0, 400.0]:
		game.rooms.actor.place(origin, game.rooms.current_room.definition.floor_y)
		start([Row.of([Step.walkTo("player", "sink", true)]), Row.of([Step.animate("player", "back"), first])])
		var sink: Hotspot = game.rooms.find_hotspot("sink")
		check(is_equal_approx(game.rooms.actor.target_x, sink.position.x + sink.hit_size.x / 2.0), "Cammino centrato indipendente dal lato di partenza")
		check(game.rooms.actor.animation == &"walk" and not game.sequences.waiting_for_confirmation, "Il centraggio attende il cammino prima della posa")
		game._process(10)
		check(game.rooms.actor.has_arrived() and game.rooms.actor.animation == &"back" and game.sequences.waiting_for_confirmation, "Arrivo al centro avvia automaticamente posa e battuta")
		click()
	var effects := {"count": 0}
	var effect := Step.effect(func(): effects.count += 1)
	var hide := Step.new()
	hide.kind = Step.Kind.HIDE
	hide.subject_id = "interphone"
	start([Row.of([first]), Row.of([hide, effect, effect]), Row.of([effect])])
	click()
	check(game.rooms.find_hotspot("interphone") == null and effects.count == 2, "Un clic avvia insieme scomparsa e due effetti")
	click()
	check(effects.count == 3 and not game.sequences.busy, "La riga seguente richiede un altro clic")
	start([Row.of([wait(0.25), wait(0.5), effect]), Row.of([effect])])
	check(effects.count == 4, "L'effetto parte insieme ai due timer")
	game._process(0.25)
	check(effects.count == 4 and game.sequences.busy, "Il primo timer non anticipa la riga successiva")
	click()
	game._process(0.25)
	check(effects.count == 5 and not game.sequences.busy, "L'ultimo timer avvia automaticamente la riga successiva")
	# Due personaggi, anche annidati, devono muoversi nello stesso frame e attendere il più lento.
	var container := Node2D.new()
	container.position.x = 30
	game.rooms.current_room.add_child(container)
	var partner = Player.instantiate()
	partner.character_id = "partner"
	container.add_child(partner)
	partner.place(100, game.rooms.current_room.definition.floor_y)
	partner.speed = 50
	game.rooms.actor.place(200, game.rooms.current_room.definition.floor_y)
	start([Row.of([walk("player", 210), walk("partner", 330), wait(0.5), effect]), Row.of([effect])])
	game._process(0.25)
	check(is_equal_approx(game.rooms.actor.current_x, 210) and partner.current_x > 100 and partner.current_x < 300, "Entrambi i personaggi avanzano nello stesso aggiornamento")
	check(effects.count == 6, "L'arrivo del primo personaggio non anticipa il secondo")
	game.ui._toggle_help()
	var before: float = partner.current_x
	game._process(10)
	check(partner.current_x == before and effects.count == 6, "Il menu sospende tutte le colonne")
	game.ui._toggle_help()
	game._process(10)
	check(partner.current_x == 300 and effects.count == 7 and not game.sequences.busy, "Destinazione annidata corretta e avanzamento dopo tutti gli arrivi")
	# Animazione e timer partono insieme; la conclusione dell'animazione non richiede un clic.
	var frames: SpriteFrames = game.rooms.actor.sprite_frames.duplicate()
	frames.add_animation("sequence_test")
	frames.add_frame("sequence_test", frames.get_frame_texture("idle", 0))
	frames.set_animation_loop("sequence_test", false)
	frames.set_animation_speed("sequence_test", 20)
	game.rooms.actor.sprite_frames = frames
	start([Row.of([Step.animate("player", "sequence_test", true), wait(0.5)]), Row.of([effect])])
	await create_timer(0.15).timeout
	game._process(0.25)
	check(effects.count == 7 and game.sequences.busy, "Animazione finita attende anche il timer della stessa riga")
	game._process(0.25)
	check(effects.count == 8 and not game.sequences.busy, "Fine di tutte le colonne bloccanti avanza automaticamente")
	start([Row.of([walk("player", 500), walk("partner", 400)]), Row.of([effect])])
	game._process(0.1)
	game.sequences.cancel()
	check(game.rooms.actor.has_arrived() and partner.has_arrived(), "Annullamento ferma tutti i personaggi")
	game._process(10)
	check(effects.count == 8, "Annullamento scarta tutte le righe future")
	# La validazione dell'intera riga precede effetti e movimenti.
	start([Row.of([effect, walk("missing", 200)])])
	check(effects.count == 8 and not game.sequences.busy, "Soggetto mancante invalida la riga prima degli effetti")
	start([Row.of([effect, walk("player", 300), Step.animate("player", "idle")])])
	check(effects.count == 8 and not game.sequences.busy, "Azioni di movimento incompatibili non sovrascrivono lo stesso attore")
	start([Row.of([effect, Step.animate("player", "idle", true)])])
	check(effects.count == 8 and not game.sequences.busy, "Animazione ciclica bloccante rifiutata senza effetti parziali")
	start([Row.of([]), Row.of([wait(0)]), Row.of([effect])])
	check(effects.count == 9 and not game.sequences.busy, "Righe vuote e attese nulle non richiedono clic inutili")
	var observed: Array[int] = []
	var observer := func(): observed.append(effects.count)
	game.sequences.state_changed.connect(observer)
	start([Row.of([effect, effect])])
	check(observed == [11], "La scena osserva tutti gli effetti della riga insieme, con una sola sincronizzazione")
	game.sequences.state_changed.disconnect(observer)
	var reusable: Array[Row] = [Row.of([wait(0.25), wait(0.25)]), Row.of([effect])]
	for repetition in range(2):
		start(reusable)
		game._process(0.125)
		check(effects.count == 11 + repetition, "I timer ripartono da zero riutilizzando la stessa matrice")
		game._process(0.125)
	check(effects.count == 13 and reusable[0].actions[0].seconds == 0.25, "Timer uguali completati senza modificare le risorse")
	start([Row.of([walk("player", 500), walk("partner", 400)]), Row.of([effect])])
	partner.free()
	game._process(0.1)
	check(not game.sequences.busy and game.rooms.actor.has_arrived() and effects.count == 13, "Attore rimosso annulla la riga e ferma anche gli altri cammini")
	var transition := Step.new()
	transition.kind = Step.Kind.CHANGE_ROOM
	transition.destination_room = "ep01_corridor"
	transition.destination_entry = "from_cabin"
	start([Row.of([transition]), Row.of([effect])])
	check(game.state.room == "ep01_corridor" and game.sequences.waiting_for_confirmation, "Cambio stanza completato senza avviare la riga seguente")
	click()
	check(effects.count == 14 and not game.sequences.busy, "La matrice prosegue nella nuova stanza al clic successivo")
	# La pianificazione non legge i requisiti; il runner li conserva e li rivaluta a ogni riga.
	var gate := {"allowed": true, "checks": 0, "effects": 0}
	var requirement := func() -> bool:
		gate.checks += 1
		return gate.allowed
	var guarded_effect := Step.effect(func(): gate.effects += 1)
	var guarded := Row.of([guarded_effect, first], requirement)
	var guarded_rows: Array[Row] = [Row.of([first], requirement), guarded, Row.of([guarded_effect])]
	check(gate.checks == 0 and gate.effects == 0, "Costruire righe condizionate non esegue requisiti né effetti")
	start(guarded_rows)
	check(gate.checks == 1 and game.sequences.waiting_for_confirmation, "Requisito valido eseguito all'avvio della prima riga")
	gate.allowed = false
	# Modificare la risorsa originale non cambia la condizione già copiata dal runner.
	guarded.condition = func() -> bool: return true
	click()
	check(gate.checks == 2 and gate.effects == 0 and not game.sequences.busy,
		"Requisito scaduto ferma effetti della riga e righe future, usando la condizione copiata")
	check(game.ui.speech_label.text == game._text("common.cannot_use") and game.ui.speech_label.visible
		and not game.ui.save_buttons[0].disabled, "Requisito fallito mostra il rifiuto e sblocca la UI")
	# Riutilizzare le stesse righe non conserva l'esito precedente della condizione.
	guarded.condition = requirement
	gate.allowed = true
	start(guarded_rows)
	click()
	check(gate.effects == 1 and game.ui.speech_label.text == game._text(first.text_key),
		"Sequenza riutilizzata rivaluta il requisito e avvia effetto e battuta insieme")
	click()
	check(gate.effects == 2 and not game.sequences.busy, "Requisiti validi consentono le righe successive")
	# Una risposta immediata resta visibile; la copia conserva la scelta di non attendere clic.
	var immediate := Row.of([first], Callable(), false)
	start([Row.of([second]), immediate])
	immediate.wait_for_confirmation = true
	click()
	check(not game.sequences.busy and game.ui.speech_label.visible
		and game.ui.speech_label.text == game._text(first.text_key), "Risposta immediata conserva testo e politica di conferma copiata")
	# Anche senza conferma i cammini e i timer devono completarsi prima della riga seguente.
	start([Row.of([wait(0.25)], Callable(), false), Row.of([guarded_effect])])
	check(game.sequences.busy and gate.effects == 2, "Riga senza conferma attende comunque le operazioni bloccanti")
	game._process(0.25)
	check(gate.effects == 3 and not game.sequences.busy, "Fine dell'attesa avvia automaticamente la riga seguente")
	# Un requisito legato a un nodo rimosso annulla la sequenza senza effetti parziali.
	var owner := Node.new()
	var expired := Callable(owner, "is_inside_tree")
	owner.free()
	start([Row.of([guarded_effect], expired)])
	check(gate.effects == 3 and not game.sequences.busy, "Callable di un requisito rimosso annulla la riga senza effetti")
	start([])
	check(not game.sequences.busy, "Matrice vuota conclusa")
	game.queue_free()
	await process_frame
	# Attende che il mixer audio rilasci i decoder dopo la rimozione del player.
	await create_timer(0.15).timeout
	print("Matrice: %d verifiche, %d errori" % [checks, failures])
	quit(0 if failures == 0 else 1)
