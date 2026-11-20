extends SceneTree
## Verifica proporzioni, contenimento della UI e input attraverso la scala dello schermo.
const Main = preload("res://scenes/main.tscn")
var failures := 0
var checks := 0

## Attende la preparazione della finestra prima di istanziare il gioco.
func _initialize() -> void:
	_run.call_deferred()

## Segnala ogni errore e permette l'esecuzione automatica delle verifiche.
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

## Simula il clic nelle coordinate fisiche della finestra, compresi scala e margini.
func _click(control: Control) -> void:
	var point := root.get_final_transform() * control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion)
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)
	await process_frame

## Prova riduzione, ingrandimento frazionario, telefono largo e tablet senza scrivere salvataggi.
func _run() -> void:
	var game = Main.instantiate()
	root.add_child(game)
	game.set_process(false)
	while game.sequences.busy:
		game.sequences.advance_dialogue()
	for resolution in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2400, 1080), Vector2i(1440, 1080)]:
		root.size = resolution
		await process_frame
		await process_frame
		var context := str(resolution)
		var logical := root.get_visible_rect()
		var transform := root.get_final_transform()
		check(logical.size.is_equal_approx(Vector2(1280, 720)), context + ": base logica invariata")
		var expected_scale := minf(resolution.x / 1280.0, resolution.y / 720.0)
		check(is_equal_approx(transform.x.length(), expected_scale) and is_equal_approx(transform.y.length(), expected_scale), context + ": scala uniforme e massima")
		var margins := (Vector2(resolution) - logical.size * expected_scale) / 2.0
		check(transform.origin.is_equal_approx(margins), context + ": bande simmetriche")
		for control in [game.ui.world_panel, game.ui.inventory_scroll, game.ui.help_button, game.ui.music_button]:
			check(logical.encloses(control.get_global_rect()), context + ": controllo contenuto")
		await _click(game.ui.help_button)
		check(game.ui.help_panel.visible, context + ": clic scalato apre il menu")
		check(game.ui.help_panel.get_global_rect().is_equal_approx(logical), context + ": velo su tutta la UI")
		await _click(game.ui.help_close)
		check(not game.ui.help_panel.visible, context + ": clic scalato chiude il menu")
		# Le scelte contestuali devono poter raggiungere anche il nuovo bordo destro.
		game.ui.action_menu.open(logical.end, "hand")
		check(logical.encloses(game.ui.action_menu.get_global_rect()), context + ": menu contestuale contenuto")
		check(is_equal_approx(game.ui.action_menu.get_global_rect().end.x, logical.end.x - 12.0), context + ": menu vicino al bordo destro")
		game.ui.action_menu.hide()
	game.queue_free()
	await process_frame
	print("Risoluzioni: %d verifiche, %d errori" % [checks, failures])
	quit(0 if failures == 0 else 1)
