extends SceneTree
## Verifica gli ancoraggi reali e il contenimento delle battute con carattere fisso a 32 px.
const Main = preload("res://scenes/main.tscn")
var failures := 0
var checks := 0

## Il viewport deve essere pronto prima di costruire la UI.
func _initialize() -> void:
	root.size = Vector2i(1152, 720)
	_run.call_deferred()

## Restituisce un codice di errore utilizzabile anche senza renderer.
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

## Controlla dialogo, spostamento, scorrimento e sostituzione della stanza senza toccare salvataggi.
func _run() -> void:
	var game = Main.instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	# Le prove seguenti riguardano battute libere, dopo la conclusione dell'apertura.
	while game.sequences.busy:
		game.sequences.advance_dialogue()
	var label: Label = game.ui.speech_label
	game._say("Test")
	check(label.size == Vector2(100, 100), "Riquadro 100 x 100")
	check(label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and label.vertical_alignment == VERTICAL_ALIGNMENT_BOTTOM, "Testo centrato in basso")
	check(label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Il testo lascia passare i clic")
	check(not game.ui.speaker_label.visible, "Nessun nome sotto il gioco")
	var before := label.position
	game.rooms.actor.place(300, game.rooms.current_room.definition.floor_y)
	game._process(0)
	check(label.position == before, "La battuta resta ferma mentre Churchill si muove")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(100, 400)
	game._input(click)
	check(not label.visible, "Il clic nell'ambiente nasconde la battuta")
	game._process(0)
	check(not label.visible, "La battuta resta nascosta nei frame successivi")
	game._say("Test")
	click.position = Vector2(50, 640)
	game._input(click)
	check(not label.visible, "Il clic nell'inventario nasconde la battuta")
	game._say("Test")
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(100, 400)
	game._input(motion)
	check(label.visible, "Il movimento del mouse conserva la battuta")
	click.position = Vector2(100, 400)
	click.button_index = MOUSE_BUTTON_RIGHT
	game._input(click)
	check(not label.visible, "Anche il clic destro nasconde la battuta")
	# Avvia le battute dal punto d’ingresso reale della stanza, senza dipendere da risorse sull’hotspot.
	game._start_actions(game.rooms.current_room.actions(game.state, "interphone"))
	game.sequences.advance_dialogue()
	check(label.visible, "Una nuova battuta torna visibile")
	var interphone: Node2D = game.rooms.find_hotspot("interphone")
	var anchor: Vector2 = interphone.to_global(Vector2(interphone.hit_size.x / 2.0, 0))
	check((label.global_position + Vector2(label.size.x / 2.0, label.size.y + 4.0)).is_equal_approx(anchor), "La battuta appare sopra l'interfono scalato")
	# Verifica l'altezza effettiva dopo che Label ha composto ogni traduzione della conversazione.
	for language in ["it", "en"]:
		game.texts.language = language
		for row in game.rooms.current_room.actions(game.state, "interphone"):
			var step = row.actions[0]
			# La voce e l'ancoraggio appartengono al soggetto della battuta.
			game._say(game.texts.text(step.text_key), game.rooms.subject(step.subject_id).speaker_key)
			await process_frame
			check(label.get_theme_font_size("font_size") == 32, "Carattere fisso: " + step.text_key)
			check(label.get_line_count() * label.get_line_height() <= label.size.y, "Testo contenuto: " + language + " " + step.text_key)
	# Una battuta estesa deve allargare il riquadro e mantenersi dentro i bordi della UI.
	game._say("Una battuta lunga da leggere per intero. ".repeat(12))
	await process_frame
	check(label.size.x > 100 and label.get_theme_font_size("font_size") == 32, "Riquadro espanso senza ridurre il carattere")
	check(label.get_line_count() * label.get_line_height() <= label.size.y, "Battuta lunga interamente contenuta")
	game.rooms.actor.place(30, game.rooms.current_room.definition.floor_y)
	game._process(0)
	check(label.position.x >= 0 and label.position.x + label.size.x <= game.ui.world_panel.size.x, "Riquadro contenuto al bordo laterale")
	game.sequences.cancel()
	game.state.enter_room("ep01_corridor", "from_cabin")
	game._load_room()
	game.rooms.actor.place(600, game.rooms.current_room.definition.floor_y)
	game._process(0)
	game._say("Test")
	anchor = game.rooms.actor.to_global(Vector2(game.rooms.actor.half_width, 0))
	check((label.global_position + Vector2(label.size.x / 2.0, label.size.y + 4.0)).is_equal_approx(anchor), "Ancoraggio dopo cambio stanza e scorrimento")
	game._say("Test", "common.speaker.interphone")
	check(not label.visible, "Interlocutore assente nascosto")
	game.queue_free()
	await process_frame
	print("Dialoghi: %d verifiche, %d errori" % [checks, failures])
	quit(0 if failures == 0 else 1)
