extends SceneTree
## Verifica il vocabolario sulla scena reale senza leggere o scrivere salvataggi del giocatore.
const Main = preload("res://scenes/main.tscn")
var checks := 0
var failures := 0

## La UI richiede il viewport pronto prima della costruzione dei controlli.
func _initialize() -> void:
	root.size = Vector2i(1152, 720)
	_run.call_deferred()

## Ogni errore rende il processo utilizzabile anche come controllo automatico.
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

## Cerca il testo effettivamente visualizzato, includendo le etichette del pannello aiuti.
func has_label(node: Node, value: String) -> bool:
	if node is Label and node.text == value:
		return true
	for child in node.get_children():
		if has_label(child, value):
			return true
	return false

## Cambia lingua con menu aperti e musica spenta, poi controlla le battute della sequenza reale.
func _run() -> void:
	var game = Main.instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	check(not DirAccess.dir_exists_absolute("res://assets/dialogue"), "Cartella originale rinominata")
	check(game.ui.save_buttons[0].text == "Salva", "UI iniziale italiana")
	check(has_label(game.ui.help_panel, "COMANDI"), "Titolo aiuti italiano")
	for key in game.texts.entries:
		var entry: Dictionary = game.texts.entries[key]
		check(not str(entry.get("it", "")).is_empty() and not str(entry.get("en", "")).is_empty(), "Voce IT/EN completa: " + key)
	game.ui._toggle_help()
	game.ui.music_button.button_pressed = false
	game.ui._toggle_music()
	game.texts.language = "en"
	check(game.ui.help_panel.visible, "Cambio lingua conserva il pannello aperto")
	check(game.ui.save_buttons[0].text == "Save" and game.ui.save_buttons[1].text == "Load", "Barra superiore inglese")
	check(game.ui.save_buttons[2].text == "Save" and game.ui.save_buttons[3].text == "Load", "Pulsanti aiuti inglesi")
	check(game.ui.help_button.text == "Help" and game.ui.help_close.text == "Back to game", "Apertura e chiusura aiuti inglesi")
	check(game.ui.reset_button.text == "Restart" and game.ui.reset_button.tooltip_text.begins_with("Restart the prototype."), "Reset e tooltip inglesi")
	check(has_label(game.ui.help_panel, "CONTROLS"), "Titolo aiuti inglese")
	check(has_label(game.ui.help_panel, game.texts.entries["common.ui.help_commands"].en), "Istruzioni complete inglesi")
	check(game.ui.continue_label.text == "Click to continue", "Invito a continuare inglese")
	check(game.ui.music_button.text == "Music: OFF" and game.music.stream_paused, "Cambio lingua conserva musica spenta")
	game.ui._toggle_help()
	for pair in [["sink", "Interact / pick up"], ["interphone", "Talk"], ["door", "Exit"]]:
		game._open_hotspot_menu(game.rooms.find_hotspot(pair[0]))
		check(game.ui.action_menu.interact_button.tooltip_text == pair[1], "Tooltip azione inglese: " + pair[0])
	check(game.ui.action_menu.examine_button.tooltip_text == "Examine", "Tooltip esame inglese")
	game.texts.language = "it"
	check(game.ui.action_menu.visible and game.ui.action_menu.interact_button.tooltip_text == "Esci", "Menu aperto ritradotto in italiano")
	check(game.ui.music_button.text == "Musica: OFF", "Stato musicale ritradotto")
	game.texts.language = "en"
	game._start_actions(game.rooms.find_hotspot("interphone").conversation.steps)
	check(game.ui.speaker_label.text == "WINSTON CHURCHILL", "Nome Churchill dal vocabolario")
	game.sequences.advance_dialogue()
	check(game.ui.speaker_label.text == "INTERPHONE", "Nome interfono dal vocabolario")
	check(game.ui.speech_label.text == game.texts.text("ep01.cabin.interphone.summons"), "Battuta inglese della sequenza")
	game.texts.language = "it"
	check(game.ui.speaker_label.text == "INTERFONO", "Cambio lingua conserva l'interlocutore")
	game.sequences.cancel()
	game._say(game.texts.text("common.save_failed") % "test")
	check(game.ui.speech_label.text == "Non riesco a salvare la partita: test", "Messaggio di errore con parametro")
	game.queue_free()
	await process_frame
	print("Vocabolario: %d verifiche, %d errori" % [checks, failures])
	quit(0 if failures == 0 else 1)
