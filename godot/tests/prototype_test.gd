extends SceneTree
## Regressione eseguibile senza plugin: usa la scena reale e un file separato dal salvataggio del giocatore.
const Main = preload("res://scenes/main.tscn")
const State = preload("res://scripts/game_state.gd")
const Saves = preload("res://scripts/save_store.gd")
const Items = preload("res://scripts/data/item_catalog.gd")
const Rooms = preload("res://scripts/data/room_catalog.gd")
const Texts = preload("res://scripts/data/dictionary_catalog.gd")
const Step = preload("res://scripts/actions/action_step.gd")
const Runner = preload("res://scripts/actions/sequence_runner.gd")
const Episodes = preload("res://scripts/data/episode_catalog.gd")
const TEST_SAVE := "user://ep01_refactor_test.json"
var game: Control
var failures := 0
var checks := 0

## Attende che il viewport sia pronto prima di inviare input alla GUI di Godot.
func _initialize() -> void:
	root.size = Vector2i(1152, 720)
	_run.call_deferred()

## Ogni verifica segnala il proprio contesto; il processo termina con codice diverso da zero se fallisce.
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

## Il motore gestisce GUI e animazioni; il movimento viene avanzato a tempo fisso per test riproducibili.
func _step(frames: int = 300) -> void:
	for i in frames:
		game._process(1.0 / 60.0)

## Invia veri eventi mouse: apertura e scelta non invocano direttamente le regole degli enigmi.
func _click(point: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	# Il viewport aggiorna prima la posizione del puntatore anche nel renderer headless.
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = button
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await process_frame

## Tastiera e controller passano dallo stesso percorso del gioco, compresa la conferma dei dialoghi.
func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

## La conferma A viene simulata senza richiedere un controller fisico collegato.
func _joy(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

## Un punto vicino all'origine evita il fondale davanti al letto che copre parte della bottiglia.
func _hotspot_point(id: String) -> Vector2:
	var hotspot: Hotspot = game.rooms.find_hotspot(id)
	return hotspot.to_global(Vector2(4, 4))

## Sceglie la mano o la lente nel pannello realmente creato dalla UI.
func _choose(examining: bool = false) -> void:
	check(game.ui.action_menu.visible, "Pannello contestuale visibile")
	check(game.ui.action_menu.picture.texture != null, "Grafica del pannello contestuale caricata")
	var button: Button = game.ui.action_menu.examine_button if examining else game.ui.action_menu.interact_button
	await _click(button.get_global_rect().get_center())
	_step()
	await process_frame

## Esegue un'interazione libera col solo sinistro, compreso l'avvicinamento.
func _interact(id: String) -> void:
	await _click(_hotspot_point(id))
	await _choose()

## Un solo clic mostra la descrizione e prepara l'oggetto per l'uso, senza pannello.
func _select_inventory(id: String) -> void:
	var index: int = game.state.inventory.find(id)
	check(index >= 0, "Oggetto presente per la selezione: " + id)
	var button: Button = game.ui.inventory_row.get_child(index)
	await _click(button.get_global_rect().get_center())
	check(not game.ui.action_menu.visible, "Inventario senza pannello contestuale: " + id)
	check(game.ui.speech_label.text == game._item_description(id), "Descrizione immediata: " + id)
	check(game.selected_item == id, "Oggetto selezionato: " + id)

## Verifica chiavi dei testi, risorse e ingressi senza ripetere gli elenchi del catalogo nei test.
func _test_catalogs() -> void:
	var texts := Texts.new()
	for episode_id in Episodes.EPISODES:
		var episode = Episodes.get_episode(episode_id)
		var packed: PackedScene = load(Episodes.EPISODES[episode_id])
		check(packed != null, "Scena autonoma dell'episodio caricabile: " + episode_id)
		if packed != null:
			var node := packed.instantiate()
			check(node.definition == episode, "Scena e catalogo condividono la definizione incorporata: " + episode_id)
			var script: Script = node.get_script()
			check(script != null and script.resource_path == Episodes.EPISODES[episode_id].replace(".tscn", ".gd"), "Script nella cartella dell'episodio: " + episode_id)
			node.free()
		var initial = Rooms.get_room(episode.initial_room)
		check(initial != null and initial.episode_id == episode_id and initial.entries.has(episode.initial_entry), "Ingresso iniziale dell'episodio: " + episode_id)
		check(episode.music != null, "Musica configurata: " + episode_id)
		for key in episode.intro_keys:
			check(texts.entries.has(key), "Testo introduttivo configurato: " + key)
	for id in Items.ITEMS:
		var definition: Resource = Items.ITEMS[id]
		check(definition.item_id == id and definition.icon != null, "Definizione oggetto: " + id)
		for key in [definition.name_key, definition.description_key]:
			check(texts.entries.has(key) and texts.entries[key].has("it") and texts.entries[key].has("en"), "Testo IT/EN: " + key)
	for id in Rooms.ROOMS:
		var definition: Resource = Rooms.ROOMS[id]
		check(definition.room_id == id and ResourceLoader.exists(definition.scene_path), "Definizione stanza: " + id)
		check(Episodes.EPISODES.has(definition.episode_id) and id.begins_with(definition.episode_id + "_"), "Stanza associata a un episodio: " + id)
		for entry in definition.entries:
			check(definition.clamp_x(definition.entries[entry]) == definition.entries[entry], "Ingresso percorribile: " + entry)
	for recipe in Items.RECIPES:
		for id in recipe.ingredients + recipe.consumed + recipe.results:
			check(Items.has_item(id), "Oggetto registrato nella ricetta: " + id)
		check(texts.entries.has(recipe.response_key), "Risposta della ricetta presente")
	var before := texts.entries.duplicate(true)
	check(not texts.load_episode("unknown") and texts.entries == before, "Un episodio sconosciuto non modifica i testi correnti")
	var lazy := Texts.new("unknown")
	check(lazy.entries.is_empty(), "Nessun catalogo caricato per un episodio sconosciuto")
	check(lazy.text("ep01.inventory.bottle.name") == texts.text("ep01.inventory.bottle.name") and lazy.episode_id.is_empty(), "Testi dell'oggetto caricati dall'episodio di origine senza cambiare episodio attivo")
	for key in texts.entries:
		check(key.begins_with("common.") or key.begins_with("ep01."), "Namespace del testo: " + key)

## Cambiare la risorsa iniziale modifica nuova partita e introduzione senza modificare main.gd.
func _test_episode_configuration() -> void:
	var episode = Episodes.get_episode("ep01")
	var initial_room: String = episode.initial_room
	var initial_entry: String = episode.initial_entry
	var intro: Array[String] = episode.intro_keys.duplicate()
	episode.initial_room = "ep01_corridor"
	episode.initial_entry = "from_cabin"
	episode.intro_keys.assign(["ep01.corridor.cabin_sign.examine"])
	game._new_game()
	check(game.state.room == "ep01_corridor" and game.state.player_x == 94, "Nuova partita dall'ingresso configurato nell'episodio")
	check(game.ui.speech_label.text == game._text(episode.intro_keys[0]), "Introduzione letta dalla definizione dell'episodio")
	check(game.music.stream != episode.music and game.music.stream.get_length() == episode.music.get_length() and game.music.stream.loop, "Sottofondo configurato con ripetizione e decoder indipendente")
	var playing_stream: AudioStream = game.music.stream
	game.ui.music_button.button_pressed = false
	game.ui.music_toggled.emit(false)
	game.state.enter_room("ep01_cabin", "from_corridor")
	game._load_room()
	check(game.music.stream_paused and game.music.stream == playing_stream, "Preferenza musicale conservata al cambio stanza")
	game.ui.music_button.button_pressed = true
	game.ui.music_toggled.emit(true)
	var original_music: AudioStream = episode.music
	episode.music = null
	game._active_episode = ""
	game._sync_episode()
	await create_timer(0.05).timeout
	check(game.music.stream == null and not game.music.playing, "Un episodio può essere configurato senza sottofondo")
	episode.music = original_music
	game._active_episode = ""
	game._sync_episode()
	await create_timer(0.05).timeout
	episode.initial_room = initial_room
	episode.initial_entry = initial_entry
	episode.intro_keys.assign(intro)
	game._new_game()

## Copre ripresa intermedia, sovrascrittura atomica e rifiuto dei dati senza mutazioni parziali.
func _test_saves() -> void:
	var state := State.new()
	check(not state.pick_up("unknown") and not state.pick_up("ep01_cabin_key"), "Raccolta limitata agli oggetti registrati come raccoglibili")
	state.pick_up("ep01_cabin_feather")
	state.pick_up("ep01_cabin_magnet")
	check(state.combine("ep01_cabin_magnet", "ep01_cabin_feather") == "ep01.inventory.magnet_feather.combine", "Ricetta simmetrica")
	check(not state.pick_up("ep01_cabin_magnet"), "Un componente consumato non è raccoglibile due volte")
	state.set_progress("ep01_cabin", "sink_stage", 1)
	check(Saves.save_game(state, TEST_SAVE) == OK, "Scrittura versione 3")
	check(Saves.save_game(state, TEST_SAVE) == OK, "Sovrascrittura del salvataggio esistente")
	var restored := State.new()
	check(Saves.load_game(restored, TEST_SAVE) == OK, "Caricamento versione 3")
	check(Saves.snapshot(restored) == Saves.snapshot(state), "Ripresa completa dello stato")
	var valid := Saves.snapshot(restored)
	var bad_files: Array[Dictionary] = []
	for field in ["inventory", "collected", "progress", "room", "player_x", "version", "episode"]:
		var invalid := valid.duplicate(true)
		invalid[field] = null
		bad_files.append(invalid)
	for old_version in [1, 2]:
		var legacy := valid.duplicate(true)
		legacy.version = old_version
		bad_files.append(legacy)
	var unknown_episode := valid.duplicate(true)
	unknown_episode.episode = "ep99"
	bad_files.append(unknown_episode)
	var unknown_item := valid.duplicate(true)
	unknown_item.inventory = ["unknown"]
	bad_files.append(unknown_item)
	var duplicate := valid.duplicate(true)
	duplicate.inventory = ["ep01_cabin_key", "ep01_cabin_key"]
	bad_files.append(duplicate)
	var invalid_stage := valid.duplicate(true)
	invalid_stage.progress.ep01_cabin.sink_stage = 1.5
	bad_files.append(invalid_stage)
	var unknown_flag := valid.duplicate(true)
	unknown_flag.progress.ep01_cabin.unknown = true
	bad_files.append(unknown_flag)
	for invalid in bad_files:
		_write_json(invalid)
		check(Saves.load_game(restored, TEST_SAVE) == ERR_FILE_CORRUPT, "Rifiuto di un campo non valido")
		check(Saves.snapshot(restored) == valid, "Nessuna modifica parziale in caso di errore")
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	check(Saves.load_game(restored, TEST_SAVE) == ERR_FILE_CORRUPT, "Rifiuto di JSON corrotto")
	var defaults := valid.duplicate(true)
	defaults.progress = {}
	_write_json(defaults)
	check(Saves.load_game(restored, TEST_SAVE) == OK and restored.get_progress("ep01_cabin", "sink_stage") == 0, "Valori iniziali per progressi assenti")
	var outside_room := valid.duplicate(true)
	outside_room.room = "ep01_corridor"
	outside_room.player_x = 9999
	_write_json(outside_room)
	check(Saves.load_game(restored, TEST_SAVE) == OK and restored.player_x == 868, "Posizione caricata limitata ai bordi della stanza")
	check(restored.episode_id == "ep01" and Saves.snapshot(restored).episode == "ep01", "Episodio persistente coerente con la stanza")

## Le fixture usano esclusivamente il percorso del test, mai game_save.json.
func _write_json(data: Dictionary) -> void:
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

## Gioca l'enigma della cabina attraverso il mouse e verifica il ripristino tra due stanze.
func _test_cabin() -> void:
	await _interact("bottle")
	check(game.state.has_item("ep01_cabin_bottle") and not game.rooms.current_room.get_node("bottle").visible, "Raccolta bottiglia e sincronizzazione visiva")
	await _interact("feather")
	await _interact("map")
	check(game.state.inventory.size() == 3, "Raccolta dei tre oggetti")
	await _select_inventory("ep01_cabin_feather")
	var magnet_index: int = game.state.inventory.find("ep01_cabin_magnet")
	await _click(game.ui.inventory_row.get_child(magnet_index).get_global_rect().get_center())
	check(game.state.has_item("ep01_cabin_magnet_feather") and not game.state.has_item("ep01_cabin_feather"), "Combinazione tramite inventario")
	await _select_inventory("ep01_cabin_bottle")
	await _click(_hotspot_point("sink"))
	_step()
	await process_frame
	check(game.state.get_progress("ep01_cabin", "sink_stage") == 1 and not game.state.has_item("ep01_cabin_bottle"), "Bourbon consumato e chiave nello scarico")
	check(Saves.save_game(game.state, TEST_SAVE) == OK, "Salvataggio a metà enigma")
	await _select_inventory("ep01_cabin_magnet_feather")
	await _click(_hotspot_point("sink"))
	_step()
	await process_frame
	check(game.state.has_item("ep01_cabin_key") and game.state.get_progress("ep01_cabin", "sink_stage") == 2, "Recupero della chiave")
	await _select_inventory("ep01_cabin_key")
	await _click(_hotspot_point("door"))
	_step()
	await process_frame
	check(game.state.room == "ep01_corridor" and game.state.get_progress("ep01_cabin", "door_unlocked"), "Apertura della porta e uscita")
	check(not game.state.has_item("ep01_cabin_key") and game.state.player_x == 94, "Chiave consumata e ingresso nominato")
	await _interact("return")
	check(game.state.room == "ep01_cabin" and game.state.player_x == 550, "Ritorno alla cabina")
	check(not game.rooms.current_room.get_node("bottle").visible, "Oggetti consumati assenti al ritorno")
	check(Saves.load_game(game.state, TEST_SAVE) == OK, "Ripresa del salvataggio intermedio")
	game._load_room()
	await process_frame
	check(game.state.get_progress("ep01_cabin", "sink_stage") == 1 and not game.state.has_item("ep01_cabin_key"), "Enigma ripristinato allo stadio salvato")
	check(not game.rooms.current_room.get_node("feather").visible, "Componente combinato ancora nascosto dopo il caricamento")

## Verifica battute reali, interlocutori, input bloccato e pausa/ripresa della conversazione.
func _test_interphone() -> void:
	await _interact("interphone")
	check(game.sequences.busy and game.sequences.waiting_for_confirmation, "Conversazione avviata")
	check(game.rooms.actor.animation == "idle", "Personaggio fermo durante la conversazione dopo l'avvicinamento")
	check(game.ui.speech_label.text == game._text("ep01.cabin.interphone.greeting"), "Prima battuta dell'interfono")
	check(game.ui.save_buttons[0].disabled and game.ui.reset_button.disabled, "Salvataggio e reset bloccati durante la sequenza")
	# Sostituire una sequenza annulla le azioni future senza sbloccare l'interfaccia della successiva.
	game._start_actions(game.rooms.current_room.actions(game.state, "interphone"))
	check(game.ui.save_buttons[0].disabled and game.sequences.busy, "Blocco UI conservato dopo la sostituzione della sequenza")
	var before_x: float = game.state.player_x
	# Mantiene premuto il movimento durante l'aggiornamento, anziché rilasciarlo prima della verifica.
	var movement := InputEventKey.new()
	movement.physical_keycode = KEY_D
	movement.keycode = KEY_D
	movement.pressed = true
	Input.parse_input_event(movement)
	_step(30)
	check(game.state.player_x == before_x, "Input del mondo sospeso durante il dialogo")
	movement = movement.duplicate()
	movement.pressed = false
	Input.parse_input_event(movement)
	await _click(Vector2(300, 300))
	check(game.ui.speaker_label.text == "INTERFONO", "Cambio interlocutore col mouse")
	await _key(KEY_F1)
	var before_text: String = game.ui.speech_label.text
	_step(120)
	check(game.ui.help_panel.visible and game.ui.speech_label.text == before_text, "Menu in pausa senza avanzamento")
	check(game.rooms.actor.speed_scale == 0, "Animazioni sospese dal menu")
	await _key(KEY_ESCAPE)
	check(not game.ui.help_panel.visible and game.rooms.actor.speed_scale == 1, "Ripresa delle animazioni")
	await _key(KEY_ENTER)
	check(game.ui.speech_label.text == game._text("ep01.cabin.interphone.urgency"), "Avanzamento con tastiera")
	await _joy(JOY_BUTTON_A)
	check(not game.sequences.busy, "Fine della conversazione con controller")
	check(game.ui.speech_label.text == game._text("ep01.cabin.interphone.reply") and game.ui.speaker_label.text == "WINSTON CHURCHILL", "Ultima battuta persistente")
	check(not game.ui.save_buttons[0].disabled, "Interazioni riabilitate alla fine")

## Gli hotspot presenti al caricamento restano ricercabili secondo visibilità e appartenenza.
func _test_nested_hotspots() -> void:
	var room = load("res://scenes/rooms/ep01_cabin.tscn").instantiate()
	var container := Node2D.new()
	room.add_child(container)
	# La gerarchia viene preparata prima di _ready, come per una scena salvata nell'editor.
	var collectible: Hotspot = room.get_node("bottle")
	collectible.owner = null
	collectible.reparent(container)
	root.add_child(room)
	check(room.find_hotspot("bottle") == collectible, "Registrazione iniziale hotspot annidato")
	container.hide()
	check(room.find_hotspot("bottle") == null, "Antenato nascosto esclude il bersaglio")
	check(collectible in room.hotspots(false), "Sincronizzazione include hotspot nascosti")
	container.show()
	check(room.find_hotspot("bottle") == collectible, "Hotspot nuovamente visibile senza ricostruire la lista")
	container.remove_child(collectible)
	check(room.find_hotspot("bottle") == null, "Nodo rimosso escluso dalla ricerca")
	container.add_child(collectible)
	check(room.find_hotspot("bottle") == collectible, "Nodo già registrato riconosciuto al rientro")
	room.remove_child(container)
	check(room.find_hotspot("bottle") == null, "Contenitore rimosso esclude i propri hotspot")
	room.add_child(container)
	check(room.find_hotspot("bottle") == collectible, "Contenitore ripristinato senza ricostruire la lista")
	collectible.free()
	check(room.find_hotspot("bottle") == null, "Nodo liberato escluso dalla ricerca")
	room.queue_free()
	await process_frame

## Prova ordine, attese, movimento, animazioni non cicliche e cancellazione senza effetti tardivi.
func _test_sequence_steps() -> void:
	var runner := Runner.new()
	var effects := {"count": 0}
	var wait := Step.new()
	wait.kind = Step.Kind.WAIT
	wait.seconds = 0.5
	var walk := Step.new()
	walk.kind = Step.Kind.WALK
	walk.target_x = 320
	var animation := Step.new()
	animation.kind = Step.Kind.ANIMATE
	animation.animation_name = "idle"
	animation.wait_for_completion = false
	var effect := Step.effect(func(): effects.count += 1)
	var steps: Array[Step] = [wait, walk, animation, effect]
	runner.start(steps, game.state, game.rooms)
	runner.advance_dialogue()
	runner.tick(0.25)
	check(effects.count == 0, "Conferma e attesa non anticipano gli effetti")
	runner.tick(0.25)
	check(runner.waiting_for_confirmation, "Fine attesa richiede un clic prima del movimento")
	runner.advance_dialogue()
	for i in 300:
		runner.tick(1.0 / 60.0)
	check(runner.waiting_for_confirmation and effects.count == 0, "Fine movimento richiede un clic prima dell'animazione")
	runner.advance_dialogue()
	check(runner.waiting_for_confirmation and effects.count == 0, "Animazione senza attesa richiede un clic prima dell'effetto")
	runner.advance_dialogue()
	check(not runner.busy and effects.count == 1 and game.rooms.actor.current_x == 320, "Sequenza attesa-movimento-animazione-effetto")
	runner.start(steps, game.state, game.rooms)
	runner.cancel()
	runner.tick(10)
	check(effects.count == 1 and not runner.busy, "Cancellazione senza effetti tardivi")
	var frames: SpriteFrames = game.rooms.actor.sprite_frames.duplicate()
	frames.add_animation("test_once")
	frames.add_frame("test_once", frames.get_frame_texture("idle", 0))
	frames.set_animation_loop("test_once", false)
	frames.set_animation_speed("test_once", 20)
	game.rooms.actor.sprite_frames = frames
	animation = Step.new()
	animation.kind = Step.Kind.ANIMATE
	animation.animation_name = "test_once"
	var animated_steps: Array[Step] = [animation, effect]
	runner.start(animated_steps, game.state, game.rooms)
	runner.tick(0)
	check(runner.busy and effects.count == 1, "Attesa del completamento reale dell'animazione")
	await create_timer(0.15).timeout
	runner.tick(0)
	check(runner.waiting_for_confirmation and effects.count == 1, "Fine animazione non avvia l'effetto")
	runner.advance_dialogue()
	check(not runner.busy and effects.count == 2, "Animazione conclusa prima dell'effetto")
	var transition := Step.new()
	transition.kind = Step.Kind.CHANGE_ROOM
	transition.destination_room = "ep01_corridor"
	transition.destination_entry = "from_cabin"
	runner.state_changed.connect(game._after_effect)
	var transitions: Array[Step] = [transition]
	runner.start(transitions, game.state, game.rooms)
	check(game.rooms.current_room.definition.room_id == "ep01_corridor" and game.state.player_x == 94, "Transizione come passo di sequenza")
	# Il marinaio è un hotspot statico con grafica animata, come gli altri oggetti.
	var sailor = game.rooms.find_hotspot("smoker")
	check(sailor != null and sailor.approach_position(100, 22) == 398, "Marinaio: avvicinamento al bordo sinistro")
	check(sailor.approach_position(700, 22) == 482, "Marinaio: avvicinamento al bordo destro")
	# Il menu sospende anche un'animazione non ciclica in corso, senza anticipare il passo successivo.
	var once: SpriteFrames = game.rooms.actor.sprite_frames.duplicate()
	once.add_animation("pause_test")
	once.add_frame("pause_test", once.get_frame_texture("idle", 0))
	once.set_animation_loop("pause_test", false)
	once.set_animation_speed("pause_test", 10)
	game.rooms.actor.sprite_frames = once
	animation = Step.new()
	animation.kind = Step.Kind.ANIMATE
	animation.animation_name = "pause_test"
	var paused_steps: Array[Step] = [animation]
	game._start_actions(paused_steps)
	game._toggle_help()
	await create_timer(0.2).timeout
	game._process(1)
	check(game.sequences.busy and game.rooms.actor.is_playing(), "Animazione di sequenza ancora in attesa durante la pausa")
	game._toggle_help()
	await create_timer(0.2).timeout
	game._process(0)
	check(not game.sequences.busy, "Completamento dell'animazione dopo la ripresa")

## Gli aggiornamenti senza variazioni conservano i controlli e l'eventuale focus UI.
func _test_inventory_reuse() -> void:
	var empty: Array[String] = []
	game.ui.refresh_inventory(empty, "", game.texts)
	var placeholder = game.ui.inventory_row.get_child(0)
	game.ui.refresh_inventory(empty, "", game.texts)
	check(game.ui.inventory_row.get_child(0) == placeholder, "Inventario vuoto mantiene il messaggio senza ricrearlo")
	var items: Array[String] = ["ep01_cabin_bottle", "ep01_cabin_feather"]
	game.ui.refresh_inventory(items, "", game.texts)
	var button = game.ui._inventory_buttons[0]
	button.grab_focus()
	game.ui.refresh_inventory(items.duplicate(), items[0], game.texts)
	check(game.ui._inventory_buttons[0] == button and button.has_focus(), "Selezione conserva pulsanti e focus dell'inventario")
	game.ui.lock_interactions(true)
	game.ui.refresh_inventory(items, "", game.texts)
	check(button.disabled, "Aggiornamento invariato conserva il blocco delle interazioni")
	game.ui.lock_interactions(false)
	items.reverse()
	game.ui.refresh_inventory(items, "", game.texts)
	check(game.ui._inventory_ids == items and game.ui._inventory_buttons[0] != button, "Cambio ordine ricostruisce l'inventario")
	game._refresh()
	await process_frame

## La barra permette di raggiungere un oggetto oltre la larghezza visibile anche col focus del controller.
func _test_inventory_scroll() -> void:
	var many: Array[String] = []
	for i in 30:
		many.append("ep01_cabin_bottle")
	game.ui.refresh_inventory(many, "", game.texts)
	await process_frame
	await process_frame
	game.ui.highlight_inventory("", many.size() - 1, true)
	check(game.ui.inventory_scroll.scroll_horizontal > 0, "Scorrimento automatico dell'inventario")
	game.ui.inventory_scroll.scroll_horizontal = 0
	game.ui.highlight_inventory("", many.size() - 1, true)
	check(game.ui.inventory_scroll.scroll_horizontal == 0, "Focus invariato non forza nuovamente lo scorrimento")
	game.ui.highlight_inventory("", 0, true)
	game.ui.highlight_inventory("", many.size() - 1, true)
	check(game.ui.inventory_scroll.scroll_horizontal > 0, "Cambio focus riattiva lo scorrimento automatico")
	game._refresh()
	await process_frame

## Copre esame e raccolta dalla stanza e combinazione nell'inventario con input diversi dal mouse.
func _test_keyboard_controller() -> void:
	game._new_game()
	await process_frame
	await _key(KEY_E)
	_step()
	check(game.state.inventory.is_empty() and game.ui.speech_label.text == game._text("ep01.cabin.map.examine"),
		"Esame con tastiera senza raccolta")
	await _joy(JOY_BUTTON_A)
	_step()
	await process_frame
	check(game.state.has_item("ep01_cabin_magnet"), "Raccolta con controller")
	var feather_index := 0
	var hotspots: Array[Node2D] = game._hotspots()
	for i in hotspots.size():
		if hotspots[i].hotspot_id == "feather":
			feather_index = i
	for i in feather_index:
		await _key(KEY_TAB)
	await _key(KEY_ENTER)
	_step()
	await process_frame
	check(game.state.has_item("ep01_cabin_feather"), "Navigazione e raccolta con tastiera")
	await _joy(JOY_BUTTON_Y)
	await _joy(JOY_BUTTON_A)
	check(game.selected_item == "ep01_cabin_magnet", "Selezione nell'inventario con controller")
	await _joy(JOY_BUTTON_RIGHT_SHOULDER)
	await _joy(JOY_BUTTON_A)
	check(game.state.has_item("ep01_cabin_magnet_feather") and game.selected_item.is_empty(), "Combinazione con controller")

## Le stanze contengono direttamente gli oggetti e condividono i dati con il catalogo.
func _test_room_scenes() -> void:
	for room_id in Rooms.SCENES:
		var packed: PackedScene = load(Rooms.SCENES[room_id])
		var room := packed.instantiate()
		check(room.get_script().resource_path == Rooms.SCENES[room_id].replace(".tscn", ".gd"),
			"Script specifico della stanza: " + room_id)
		# Anche gli oggetti nascosti devono appartenere direttamente alla scena della stanza.
		for hotspot in room.hotspots(false):
			check(hotspot.scene_file_path.is_empty(), "Oggetto incorporato nella stanza: " + hotspot.hotspot_id)
		# L’identità della risorsa esclude copie separate fra stanza e catalogo inventario.
		for item in room.inventory_definitions:
			check(Items.ITEMS[item.item_id] == item, "Definizione condivisa senza istanziare la stanza: " + item.item_id)
		room.free()
	var sink: Hotspot = game.rooms.find_hotspot("sink")
	var original_x := sink.position.x
	check(sink.approach_position(180, 22) == 250, "Da sinistra il bordo destro di Churchill raggiunge il bordo sinistro dell'oggetto")
	check(sink.approach_position(500, 22) == 334, "Da destra il bordo sinistro di Churchill raggiunge il bordo destro dell'oggetto")
	check(sink.approach_position(290, 22) == 250 and sink.approach_position(300, 22) == 334,
		"Dentro l'oggetto viene scelto il bordo più vicino")
	check(sink.approach_position(292, 22) == 250, "Al centro dell'oggetto viene scelto il bordo sinistro")
	sink.position.x += 30
	check(sink.approach_position(180, 22) == 280, "Avvicinamento segue lo spostamento dell'oggetto")
	sink.position.x = original_x
	sink.scale.x = 2
	check(sink.approach_position(500, 22) == 374, "Avvicinamento tiene conto della scala dell'oggetto e della stanza")
	sink.scale.x = 1
	var actor = game.rooms.actor
	var original_player_x: float = actor.current_x
	for x in [180.0, 500.0]:
		actor.place(x, game.rooms.current_room.definition.floor_y)
		game.interactions.request(sink, "", true, game.rooms)
		check(actor.target_x == (250 if x == 180 else 334), "La richiesta sceglie il bordo dal lato di arrivo")
		_step()
		check(actor.has_arrived(), "Churchill raggiunge il bordo e completa l'avvicinamento")
	actor.place(24, game.rooms.current_room.definition.floor_y)
	sink.position.x = 20
	game.interactions.request(sink, "", true, game.rooms)
	check(actor.target_x == 24, "La destinazione rispetta i limiti percorribili della stanza")
	game.interactions.cancel(game.rooms)
	sink.position.x = original_x
	actor.place(original_player_x, game.rooms.current_room.definition.floor_y)
	game.state.player_x = original_player_x
	var first: Hotspot = game.rooms.find_hotspot("oblo1")
	var second: Hotspot = game.rooms.find_hotspot("oblo2")
	check(first != second and first.get_node("Visual").sprite_frames == second.get_node("Visual").sprite_frames,
		"Due oblò distinti condividono gli stessi fotogrammi")
	check(game.rooms.find_hotspot("bottle").item_id == Items.ITEMS.ep01_cabin_bottle.item_id,
		"Stanza e inventario condividono la stessa definizione")

## Esegue l'intero percorso e pulisce esclusivamente le fixture create da questo script.
func _run() -> void:
	_test_catalogs()
	_test_saves()
	game = Main.instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	_test_room_scenes()
	await _test_cabin()
	await _test_interphone()
	await _test_nested_hotspots()
	await _test_sequence_steps()
	await _test_inventory_reuse()
	await _test_inventory_scroll()
	await _test_keyboard_controller()
	await _test_episode_configuration()
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE + ".tmp"))
	print("EP01: %d verifiche, %d errori" % [checks, failures])
	quit(0 if failures == 0 else 1)
