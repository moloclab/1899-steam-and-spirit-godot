extends SceneTree
## Verifica il percorso delle azioni attraverso la stanza e il ripristino degli enigmi.
const Main = preload("res://scenes/main.tscn")
const State = preload("res://scripts/game_state.gd")
const Saves = preload("res://scripts/save_store.gd")
const Items = preload("res://scripts/data/item_catalog.gd")
const Episodes = preload("res://scripts/data/episode_catalog.gd")
const Definitions = preload("res://scripts/data/scene_definitions.gd")
const TEST_SAVE := "user://room_flow_test.json"
var game: Control
var failures := 0
var checks := 0

## Il viewport deve essere pronto prima di istanziare l'interfaccia reale.
func _initialize() -> void:
	_run.call_deferred()

## Ogni errore identifica il comportamento osservato, senza dipendere dai vecchi file oggetto.
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

## Usa lo stesso ingresso del coordinatore dopo l'avvicinamento del personaggio.
func act(target: String, item: String = "", examining: bool = false) -> void:
	if examining:
		game._start_actions(game.rooms.current_room.examine(game.state, target))
	else:
		game._start_actions(game.rooms.current_room.interact(game.state, target, item))
	# I controlli del percorso verificano lo stato al termine delle nuove sequenze narrative.
	if target != "interphone":
		finish_sequence()

## Completa cammini e battute con un limite per evitare sequenze bloccate.
func finish_sequence() -> void:
	for index in range(20):
		if not game.sequences.busy:
			return
		if game.sequences.waiting_for_confirmation:
			game.sequences.advance_dialogue()
		else:
			game._process(10)
	check(false, "Sequenza conclusa entro venti avanzamenti")

## L'apertura riproduce quattro battute sedute, blocca le azioni e termina in piedi.
func test_introduction() -> void:
	check(game.ui.save_buttons[0].disabled and game.ui.reset_button.disabled, "Introduzione protegge salvataggio e nuova partita")
	var keys := ["ep01.cabin.intro.headache", "ep01.cabin.intro.whiskey", "ep01.cabin.intro.burp", "ep01.cabin.bottle.reconsider"]
	for key in keys:
		check(game.sequences.busy and game.rooms.actor.animation == &"sit"
			and game.ui.speech_label.text == game._text(key), "Introduzione seduta, battuta: " + key)
		game.sequences.advance_dialogue()
	check(not game.sequences.busy and game.rooms.actor.animation == &"idle", "Chiusura dell'introduzione in piedi")

## Le ricette dell'episodio funzionano senza nodi di stanza e mantengono i controlli sul possesso.
func _test_combinations() -> void:
	var episode = Episodes.get_episode("ep01")
	var recipes: Array = Definitions.property(episode.combo_scene_path, "combination_definitions")
	check(recipes.size() == 1 and recipes[0] == Items.RECIPES[0], "Il catalogo condivide la ricetta della scena combo dell'episodio")
	for room_id in ["ep01_cabin", "ep01_corridor"]:
		for reverse in [false, true]:
			var state := State.new()
			state.enter_room(room_id, "default" if room_id == "ep01_cabin" else "from_cabin")
			state.add_item("ep01_cabin_feather")
			state.add_item("ep01_cabin_magnet")
			var first := "ep01_cabin_magnet" if reverse else "ep01_cabin_feather"
			var second := "ep01_cabin_feather" if reverse else "ep01_cabin_magnet"
			check(state.combine(first, second) == "ep01.inventory.magnet_feather.combine", "Combinazione simmetrica in " + room_id)
			check(state.inventory == ["ep01_cabin_magnet_feather"], "Consuma solo i componenti e aggiunge un risultato in " + room_id)
			check(state.combine(first, second) == "common.cannot_use" and state.inventory.size() == 1, "Ripetere la combinazione non duplica il risultato")
	# Possesso incompleto e coppie senza ricetta non devono modificare l'inventario.
	var state := State.new()
	state.add_item("ep01_cabin_feather")
	check(state.combine("ep01_cabin_feather", "ep01_cabin_magnet") == "common.cannot_use" and state.inventory == ["ep01_cabin_feather"], "Ingrediente mancante rifiutato senza consumi")
	state.add_item("ep01_cabin_bottle")
	check(state.combine("ep01_cabin_feather", "ep01_cabin_bottle") == "common.cannot_combine" and state.inventory.size() == 2, "Coppia sconosciuta rifiutata senza consumi")

## Il test usa soltanto un salvataggio dedicato; non tocca la partita del giocatore.
func _run() -> void:
	check(Items.ITEMS.size() == 5 and Items.RECIPES.size() == 1, "Inventario e ricette disponibili prima di istanziare le stanze")
	_test_combinations()
	game = Main.instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	test_introduction()
	var cabin = game.rooms.current_room
	var map_visual = cabin.get_node("mapMagnet/Visual")
	var complete_texture = map_visual.texture
	# Separa pianificazione ed esecuzione per accertare che la sola richiesta non raccolga la calamita.
	var pending = cabin.interact(game.state, "map")
	check(game.state.inventory.is_empty(), "Pianificare la raccolta non modifica lo stato")
	game._start_actions(pending)
	check(game.state.has_item("ep01_cabin_magnet") and map_visual.texture != complete_texture, "Raccolta dalla mappa e aggiornamento della texture")
	check(not game.sequences.busy, "La raccolta della calamita non richiede un clic di chiusura")
	act("map")
	check(game.state.inventory.size() == 1, "La mappa non duplica la calamita")
	act("map", "", true)
	check(game.ui.speech_label.text == game._text("ep01.cabin.map.examine_without_magnet"), "Esame della mappa dopo la raccolta")
	act("door")
	check(game.state.room == "ep01_cabin", "La porta chiusa impedisce il passaggio")
	act("sink", "ep01_cabin_bottle")
	check(game.state.get_progress("ep01_cabin", "sink_stage") == 0, "Uso di una bottiglia non posseduta rifiutato")
	act("bottle")
	act("feather")
	act("sink", "ep01_cabin_bottle", true)
	check(game.state.has_item("ep01_cabin_bottle") and game.state.get_progress("ep01_cabin", "sink_stage") == 0, "La lente precede l'uso dell'oggetto selezionato")
	# Costruire la sequenza non anticipa consumo o progresso.
	pending = cabin.act_drop_bottle()
	check(game.state.has_item("ep01_cabin_bottle") and game.state.get_progress("ep01_cabin", "sink_stage") == 0,
		"Costruire direttamente l'azione narrativa non anticipa consumo o progresso")
	# I requisiti vengono verificati all'ingresso dell'azione.
	act("sink", "ep01_cabin_magnet_feather")
	act("door", "ep01_cabin_key")
	check(not game.state.has_item("ep01_cabin_key") and not game.state.get_progress("ep01_cabin", "door_unlocked"),
		"Attrezzo e chiave non posseduti non avviano recupero o sblocco")
	# Esame e interazione generica conservano l'avvicinamento al bordo.
	var sink: Hotspot = game.rooms.find_hotspot("sink")
	for examining in [true, false]:
		game.rooms.actor.place(100, cabin.definition.floor_y)
		game.selected_item = "ep01_cabin_bottle" if examining else ""
		game._request(sink, examining)
		check(is_equal_approx(game.rooms.actor.target_x, sink.approach_position(100, game.rooms.actor.half_width)),
			"Esame e interazione senza Bourbon mantengono il bordo")
	# Anche il Bourbon raggiunge prima il bordo; il centraggio appartiene alla sua azione.
	game.rooms.actor.place(100, cabin.definition.floor_y)
	game.selected_item = "ep01_cabin_bottle"
	game._request(sink, false)
	check(is_equal_approx(game.rooms.actor.target_x, sink.approach_position(100, game.rooms.actor.half_width)), "La richiesta del Bourbon punta al bordo del lavandino")
	game._process(0.1)
	check(not game.sequences.busy and game.rooms.actor.animation == &"walk"
		and game.state.has_item("ep01_cabin_bottle"), "Il solo avvicinamento precede la sequenza del Bourbon")
	game._process(10)
	check(game.sequences.busy and game.rooms.actor.animation == &"walk"
		and not game.sequences.waiting_for_confirmation
		and is_equal_approx(game.rooms.actor.current_x, sink.approach_position(100, game.rooms.actor.half_width))
		and is_equal_approx(game.rooms.actor.target_x, sink.position.x + sink.hit_size.x / 2.0)
		and game.state.has_item("ep01_cabin_bottle"), "La prima riga avvia il centraggio dal bordo senza consumare il Bourbon")
	# I clic durante il cammino non anticipano la battuta né gli effetti.
	game.sequences.advance_dialogue()
	check(not game.sequences.waiting_for_confirmation and game.rooms.actor.animation == &"walk"
		and game.state.get_progress("ep01_cabin", "sink_stage") == 0, "Il centraggio resta bloccante durante i clic")
	game._process(10)
	check(is_equal_approx(game.rooms.actor.current_x, sink.position.x + sink.hit_size.x / 2.0), "Churchill raggiunge il centro del lavandino")
	check(game.sequences.busy and game.rooms.actor.animation == &"back"
		and game.ui.speech_label.text == game._text("ep01.cabin.sink.pour_bourbon")
		and game.state.has_item("ep01_cabin_bottle"), "Prima battuta di spalle senza consumare il Bourbon")
	game.sequences.advance_dialogue()
	check(game.sequences.busy and not game.state.has_item("ep01_cabin_bottle")
		and game.state.get_progress("ep01_cabin", "sink_stage") == 0
		and game.ui.speech_label.text == game._text("ep01.cabin.sink.surprise"), "Seconda battuta consuma il Bourbon senza anticipare la chiave")
	check(game.ui.save_buttons[0].disabled, "Salvataggio bloccato fra consumo e rivelazione della chiave")
	game.sequences.advance_dialogue()
	check(game.ui.speech_label.text == game._text("ep01.cabin.sink.key_found"), "Terza battuta rivela la chiave")
	check(game.state.get_progress("ep01_cabin", "sink_stage") == 1 and not game.state.has_item("ep01_cabin_bottle"), "Bottiglia consumata e chiave nello scarico")
	check(not game.sequences.busy and game.ui.speech_label.visible, "Ultima battuta del Bourbon visibile senza clic aggiuntivo")
	act("sink", "ep01_cabin_feather")
	check(not game.state.has_item("ep01_cabin_key") and game.state.has_item("ep01_cabin_feather"), "La penna semplice non recupera la chiave e non viene consumata")
	# Conserva lo stadio intermedio prima della combinazione e del recupero della chiave.
	check(Saves.save_game(game.state, TEST_SAVE) == OK, "Salvataggio dello stadio intermedio")
	game.state.combine("ep01_cabin_feather", "ep01_cabin_magnet")
	# I requisiti della raccolta e dello sblocco vengono verificati all'ingresso.
	game.state.remove_item("ep01_cabin_magnet_feather")
	act("sink", "ep01_cabin_magnet_feather")
	check(not game.state.has_item("ep01_cabin_key") and game.state.get_progress("ep01_cabin", "sink_stage") == 1
		and not game.sequences.busy, "Attrezzo perso prima del recupero non crea la chiave né modifica il lavandino")
	game.state.add_item("ep01_cabin_magnet_feather")
	game._start_actions(cabin.interact(game.state, "sink", "ep01_cabin_magnet_feather"))
	check(not game.sequences.busy and game.state.has_item("ep01_cabin_key")
		and game.ui.speech_label.text == game._text("ep01.cabin.sink.key_pickup"), "Recupero della chiave immediato con battuta esplicita")
	act("sink", "ep01_cabin_magnet_feather")
	check(game.state.inventory.count("ep01_cabin_key") == 1, "Recupero della chiave senza duplicazione")
	game.state.remove_item("ep01_cabin_key")
	act("door", "ep01_cabin_key")
	check(game.state.room == "ep01_cabin" and not game.state.get_progress("ep01_cabin", "door_unlocked")
		and not game.sequences.busy, "Chiave persa prima dello sblocco non apre la porta né cambia stanza")
	game.state.add_item("ep01_cabin_key")
	game._start_actions(cabin.interact(game.state, "door", "ep01_cabin_key"))
	check(game.sequences.busy and game.state.room == "ep01_cabin" and game.rooms.actor.animation == &"back"
		and not game.state.has_item("ep01_cabin_key") and game.state.get_progress("ep01_cabin", "door_unlocked")
		and game.ui.speech_label.text == game._text("ep01.cabin.door.exit"), "Finalmente viene pronunciato nella cabina prima del passaggio")
	game.sequences.advance_dialogue()
	check(game.state.room == "ep01_corridor" and not game.state.has_item("ep01_cabin_key"), "Chiave consumata e transizione al corridoio")
	check(not game.ui.speech_label.visible, "Il passaggio non ripete Finalmente nel corridoio")
	check(Items.ITEMS.ep01_cabin_bottle != null, "Inventario della cabina accessibile dal corridoio")
	act("return")
	check(game.state.room == "ep01_cabin" and not game.rooms.find_hotspot("bottle"), "Rientro senza far riapparire gli oggetti raccolti")
	act("door")
	check(game.state.room == "ep01_corridor", "La porta sbloccata rimane attraversabile")
	# Ricarica dal corridoio per ricreare la cabina e verificarne anche le varianti visive.
	check(Saves.load_game(game.state, TEST_SAVE) == OK, "Caricamento della partita intermedia")
	game._load_room()
	check(game.state.get_progress("ep01_cabin", "sink_stage") == 1 and not game.state.has_item("ep01_cabin_key"), "Ripristino dell'enigma precedente al recupero della chiave")
	act("door")
	check(game.state.room == "ep01_cabin", "Il caricamento ripristina la porta chiusa")
	act("interphone", "ep01_cabin_feather")
	check(not game.sequences.busy, "Usare un oggetto sull'interfono non avvia la conversazione")
	act("interphone", "", true)
	check(not game.sequences.busy and game.ui.speech_label.text == game._text("ep01.cabin.interphone.examine"), "Esame dell'interfono senza conversazione")
	# Ripetere il dialogo costruito dalla stanza deve conservare ordine e interlocutori.
	for repetition in range(2):
		act("interphone")
		for line in ["greeting", "summons", "urgency", "reply"]:
			var speaker: String = "common.speaker.interphone" if line in ["summons", "urgency"] else game.rooms.actor.speaker_key
			check(game.sequences.busy and game.ui.speech_label.text == game._text("ep01.cabin.interphone." + line)
				and game.ui._speaker_key == speaker, "Battuta e interlocutore: %s, dialogo %d" % [line, repetition + 1])
			game.sequences.advance_dialogue()
		check(not game.sequences.busy, "Ultimo clic conclude il dialogo")
	# Il nuovo stato deve ripristinare sia il fondale della mappa sia gli oggetti già nascosti.
	game.state = State.new()
	game._load_room()
	check(game.rooms.current_room.get_node("mapMagnet/Visual").texture == complete_texture and game.rooms.find_hotspot("bottle") != null, "Nuova partita ripristina immagini e visibilità")
	# Una richiesta perde il bersaglio se viene nascosto prima dell'arrivo del personaggio.
	var bottle: Hotspot = game.rooms.find_hotspot("bottle")
	game.interactions.request(bottle, "", false, game.rooms)
	bottle.hide()
	game.rooms.actor.place(game.rooms.actor.target_x, game.rooms.current_room.definition.floor_y)
	check(game.interactions.take_ready_actions(game.state, game.rooms).is_empty()
		and not game.state.has_item("ep01_cabin_bottle"), "Bersaglio nascosto durante l'avvicinamento non viene raccolto")
	game.rooms.current_room.sync_from_state(game.state)
	check(game.rooms.find_hotspot("bottle") == bottle, "Sincronizzazione ripristina il bersaglio senza ricostruire la lista")
	game.queue_free()
	await process_frame
	# Attende che il mixer audio rilasci i decoder dopo la rimozione del player.
	await create_timer(0.15).timeout
	# Elimina esclusivamente i file di prova, senza intervenire sul salvataggio del giocatore.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE + ".tmp"))
	print("Stanze: %d verifiche, %d errori" % [checks, failures])
	quit(0 if failures == 0 else 1)
