extends Control
## Collega i componenti del gioco: input, selezione e ciclo di aggiornamento.
## Le regole degli enigmi restano negli hotspot; contenuti, movimento, UI e salvataggi sono indipendenti.
const State = preload("res://scripts/game_state.gd")
const UI = preload("res://scripts/game_ui.gd")
const Items = preload("res://scripts/data/item_catalog.gd")
const Texts = preload("res://scripts/data/dialogue_catalog.gd")
const Rooms = preload("res://scripts/world/room_manager.gd")
const Interactions = preload("res://scripts/actions/interaction_controller.gd")
const Sequences = preload("res://scripts/actions/sequence_runner.gd")
const Step = preload("res://scripts/actions/action_step.gd")
const Saves = preload("res://scripts/save_store.gd")
const Episodes = preload("res://scripts/data/episode_catalog.gd")
const CURSOR_NORMAL = preload("res://assets/graphics/ui/cursors/cursor_normal.png")
const CURSOR_MAGNIFIER = preload("res://assets/graphics/ui/cursors/cursor_magnifier.png")
var state: State
var texts: Texts
var rooms = Rooms.new()
var interactions = Interactions.new()
var sequences = Sequences.new()
var ui: UI
var music := AudioStreamPlayer.new()
@export var starting_episode := Episodes.DEFAULT_EPISODE
var _active_episode := ""
## Selezioni temporanee: non appartengono al salvataggio e vengono scartate al cambio partita.
var selected_item := ""
var focus_index := 0
var inventory_focus := false
var keyboard_focus := false
var menu_hotspot: Hotspot
var menu_item := ""

## Prepara i componenti e collega le intenzioni della UI ai servizi del gioco.
func _ready() -> void:
	state = State.new(starting_episode)
	texts = Texts.new(starting_episode)
	Input.set_custom_mouse_cursor(CURSOR_NORMAL, Input.CURSOR_ARROW, Vector2(1, 1))
	Input.set_custom_mouse_cursor(CURSOR_NORMAL, Input.CURSOR_POINTING_HAND, Vector2(1, 1))
	Input.set_custom_mouse_cursor(CURSOR_MAGNIFIER, Input.CURSOR_CROSS, Vector2(12, 12))
	_register_movement()
	ui = UI.new()
	add_child(ui)
	ui.save_requested.connect(_save)
	ui.load_requested.connect(_load)
	# Un solo player mantiene il brano tra stanze dello stesso episodio.
	add_child(music)
	# La pausa conserva la posizione del brano quando si riabilita la musica.
	ui.music_toggled.connect(func(enabled: bool): music.stream_paused = not enabled)
	ui.new_game_requested.connect(_new_game)
	ui.world_input.connect(_world_input)
	ui.action_chosen.connect(_choose_action)
	ui.inventory_pressed.connect(_inventory_click)
	ui.item_examined.connect(func(item: String): _say(_item_description(item)))
	ui.menu_toggled.connect(_menu_toggled)
	sequences.line_requested.connect(func(key: String, speaker: String): ui.say(_text(key), speaker))
	sequences.state_changed.connect(_after_effect)
	sequences.waiting_changed.connect(func(waiting: bool): ui.continue_label.visible = waiting)
	sequences.finished.connect(func(_cancelled: bool): ui.lock_interactions(false))
	_load_room()
	_show_intro()

## I cursori appartengono a Input: rilasciarli alla chiusura evita texture trattenute oltre il renderer.
func _exit_tree() -> void:
	# Rilascia il decoder del sottofondo prima della chiusura del server audio.
	music.stop()
	music.stream = null
	for cursor in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_CROSS]:
		Input.set_custom_mouse_cursor(null, cursor)

## Nuova partita e caricamento eliminano ogni richiesta legata ai nodi della stanza precedente.
func _new_game() -> void:
	sequences.cancel()
	state = State.new(starting_episode)
	selected_item = ""
	inventory_focus = false
	focus_index = 0
	ui.help_panel.hide()
	_load_room()
	_show_intro()

## Introduzione e musica provengono dalla definizione dell'episodio corrente.
func _show_intro() -> void:
	var episode = Episodes.get_episode(state.episode_id)
	if episode == null:
		return
	var lines: Array[String] = []
	for key in episode.intro_keys:
		lines.append(_text(key))
	_say("  ".join(lines))

## I cambi stanza nello stesso episodio conservano posizione del brano e preferenza musicale.
func _sync_episode() -> void:
	if _active_episode == state.episode_id:
		return
	var episode = Episodes.get_episode(state.episode_id)
	if episode == null or not texts.load_episode(state.episode_id):
		return
	music.stop()
	# Il decoder usato dal player non modifica la risorsa condivisa della configurazione.
	music.stream = episode.music.duplicate() if episode.music != null else null
	if music.stream != null:
		music.play()
	music.stream_paused = not ui.music_button.button_pressed
	_active_episode = state.episode_id

## Il gestore delle stanze mantiene tutto il codice di creazione e posizionamento del personaggio.
func _load_room() -> void:
	_close_action_menu()
	interactions.cancel(rooms)
	if not rooms.load_room(state, ui.world_panel):
		push_error("Impossibile caricare la stanza: " + state.room)
		return
	focus_index = 0
	_sync_episode()
	_refresh()
	rooms.pause_animations(ui.help_panel.visible)

## Sincronizza anche gli oggetti nascosti, necessari quando si ripristina un salvataggio precedente.
func _refresh() -> void:
	for hotspot in _hotspots(false):
		hotspot.sync_from_state(state)
	if not state.has_item(selected_item):
		selected_item = ""
	ui.refresh_inventory(state.inventory, selected_item, texts)
	ui.lock_interactions(sequences.busy)

## Gli effetti possono chiedere una transizione modificando lo stato, senza conoscere il gestore scene.
func _after_effect() -> void:
	if rooms.current_room.definition.room_id != state.room:
		_load_room()
	else:
		_refresh()

## Ogni sequenza blocca la UI prima dell'avvio; il segnale finale la riabilita anche per azioni immediate.
func _start_actions(actions: Array[Step]) -> void:
	# La cancellazione può riabilitare la UI tramite finished: deve precedere il blocco della nuova sequenza.
	sequences.cancel()
	ui.lock_interactions(true)
	sequences.start(actions, state, rooms)

## Unica lista di hotspot della stanza corrente, con supporto per contenitori annidati.
func _hotspots(visible_only: bool = true) -> Array[Node2D]:
	return rooms.current_room.hotspots(visible_only)

## Separa la scelta di un'azione dal suo avvicinamento e dalla successiva esecuzione.
func _request(hotspot: Hotspot, examine: bool) -> void:
	if sequences.busy:
		return
	_close_action_menu()
	interactions.request(hotspot, selected_item, examine, rooms)

## I testi dell'inventario provengono dalla stessa definizione usata per nomi, icone e validazione.
func _item_description(item: String) -> String:
	return _text(Items.ITEMS[item].description_key)

## I componenti di gioco lavorano con chiavi, mentre il catalogo sceglie la traduzione corrente.
func _text(key: String) -> String:
	return texts.text(key)

## Le risposte immediate restano visibili fino alla battuta successiva, come nel prototipo.
func _say(value: String) -> void:
	ui.say(value)

## Aggiorna la selezione senza ricostruire i pulsanti dell'inventario.
func _update_selection() -> void:
	ui.update_selection(selected_item, texts)

## Il menu sospende il passo attivo e le animazioni, mantenendo in corso la conversazione.
func _toggle_help() -> void:
	ui._toggle_help()

## Le richieste di avvicinamento libere vengono annullate; le sequenze mantengono il proprio percorso.
func _menu_toggled(open: bool) -> void:
	_close_action_menu()
	if not sequences.busy:
		interactions.cancel(rooms)
	rooms.pause_animations(open)

## Registra due azioni di movimento continue nell'InputMap di Godot.
## Ogni azione accetta tasti fisici e una direzione della levetta; 0.22 è la zona morta.
func _register_movement() -> void:
	for direction in ["walk_left", "walk_right"]:
		# Le azioni possono essere già definite nell'editor o da un precedente avvio della scena.
		if InputMap.has_action(direction):
			continue
		InputMap.add_action(direction, 0.22)
		var left: bool = direction == "walk_left"
		for code in ([KEY_A, KEY_LEFT] if left else [KEY_D, KEY_RIGHT]):
			var key := InputEventKey.new()
			key.physical_keycode = code
			InputMap.action_add_event(direction, key)
		# Le due metà dello stesso asse diventano due azioni; get_axis le ricompone in -1…1.
		var stick := InputEventJoypadMotion.new()
		stick.axis = JOY_AXIS_LEFT_X
		stick.axis_value = -1.0 if left else 1.0
		InputMap.action_add_event(direction, stick)

## Nasconde il pannello e rimuove i riferimenti al suo bersaglio.
## Il controllo di validità consente di chiamarla anche prima che il pannello sia stato costruito.
func _close_action_menu() -> void:
	if is_instance_valid(ui.action_menu):
		ui.action_menu.hide()
	menu_hotspot = null
	menu_item = ""

## Apre le due scelte su un oggetto della stanza, senza ancora eseguire alcuna azione.
## Il tipo esportato dell'hotspot sceglie la grafica mano, bocca oppure uscita.
func _open_hotspot_menu(hotspot: Node2D) -> void:
	_close_action_menu()
	interactions.cancel(rooms)

	menu_hotspot = hotspot
	var kind: String = hotspot.interaction_kind
	var caption: String = {"hand": "Interagisci / raccogli", "mouth": "Parla", "exit": "Esci"}[kind]
	var center: Vector2 = hotspot.to_global(hotspot.hit_size / 2)
	# Stanza ingrandita e corridoio scorrevole usano trasformazioni diverse dalla UI:
	# passiamo prima al canvas globale, poi alle coordinate locali del genitore del pannello.
	ui.action_menu.open(get_global_transform().affine_inverse() * center, kind, caption)

## Gestisce il clic sinistro su un oggetto posseduto.
## Senza selezione apre lente/mano; con una selezione prova la combinazione o la deselezione.
func _inventory_click(item: String, button: Button) -> void:
	_close_action_menu()
	interactions.cancel(rooms)

	if not selected_item.is_empty():
		_select_item(item)
		return
	menu_item = item
	var center: Vector2 = button.get_global_rect().get_center()
	ui.action_menu.open(get_global_transform().affine_inverse() * center, "hand", "Usa / combina")

## Riceve la scelta dal pannello: true indica la lente, false l'interazione.
## Gli oggetti in inventario si esaminano subito; quelli della stanza richiedono avvicinamento.
func _choose_action(examine: bool) -> void:
	# Copia il bersaglio prima di chiudere il menu; il clic sulla scelta non passa alla stanza.
	var hotspot := menu_hotspot
	var item := menu_item
	_close_action_menu()
	if not item.is_empty():
		if examine:
			_say(_item_description(item))
		else:
			_select_item(item)
	elif is_instance_valid(hotspot) and hotspot.visible:
		_request(hotspot, examine)

## Gestisce solo i clic ricevuti dall'area della stanza.
## Il sinistro apre le scelte o usa un oggetto selezionato; il destro resta una scorciatoia facoltativa.
func _world_input(event: InputEvent) -> void:
	if ui.help_panel.visible or sequences.busy:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index not in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			return
		keyboard_focus = false
		# gui_input fornisce una posizione locale al contenitore, mentre gli hotspot ricevono punti globali.
		var point: Vector2 = ui.world_panel.get_global_transform() * event.position
		var hotspot := _at_point(point)
		if hotspot != null:
			if event.button_index == MOUSE_BUTTON_RIGHT or not selected_item.is_empty():
				# Come in EP01, un oggetto già selezionato si usa direttamente sul bersaglio.
				_close_action_menu()
				_request(hotspot, event.button_index == MOUSE_BUTTON_RIGHT)
			else:
				_open_hotspot_menu(hotspot)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel()
		else:
			# Sul pavimento si abbandona l'azione precedente e si sceglie una nuova destinazione.
			_close_action_menu()
			selected_item = ""
			_update_selection()
			interactions.cancel(rooms)
			rooms.actor.target_x = rooms.current_room.definition.clamp_x(rooms.current_room.to_local(point).x)

## Trova l'hotspot sotto il puntatore attuale, usato per l'evidenziazione durante il movimento del mouse.
func _at_mouse() -> Node2D:
	return _at_point(get_global_mouse_position())

## Cerca un oggetto cliccabile a partire da un punto in coordinate globali del canvas.
## In caso di sovrapposizione viene provato prima l'ultimo hotspot nell'ordine dei figli.
func _at_point(point: Vector2) -> Node2D:
	var hotspots := _hotspots()
	hotspots.reverse() # Oggetti in primo piano prima del fondale.
	for hotspot in hotspots:
		if hotspot.contains(point):
			return hotspot
	return null

## Seleziona un oggetto, lo deseleziona al secondo clic oppure combina due oggetti diversi.
## La combinazione è delegata a GameState; qui si aggiornano soltanto selezione e interfaccia.
func _select_item(item: String) -> void:
	_close_action_menu()
	interactions.cancel(rooms)

	if selected_item == item:
		selected_item = ""
	elif selected_item.is_empty():
		selected_item = item
	else:
		_say(_text(state.combine(selected_item, item)))
		selected_item = ""
	_refresh()

## Annulla pannello, oggetto selezionato e azione in attesa, fermando il personaggio sul posto.
func _cancel() -> void:
	_close_action_menu()
	selected_item = ""
	interactions.cancel(rooms)

	_refresh()

## Sposta la selezione da tastiera/controller nella stanza oppure nell'inventario.
## Il modulo positivo permette di tornare all'ultimo elemento quando si procede all'indietro.
func _cycle_focus(step: int) -> void:
	_close_action_menu()
	keyboard_focus = true
	var count: int = state.inventory.size() if inventory_focus else _hotspots().size()
	if count > 0:
		focus_index = posmod(focus_index + step, count)

## Conferma il bersaglio selezionato con tastiera/controller.
## Questi dispositivi hanno tasti distinti per agire ed esaminare e non richiedono il pannello del mouse.
func _confirm_focus(examine: bool = false) -> void:
	_close_action_menu()
	keyboard_focus = true
	if inventory_focus:
		if not state.inventory.is_empty():
			var item: String = state.inventory[focus_index % state.inventory.size()]
			if examine:
				_say(_item_description(item))
			else:
				_select_item(item)
	else:
		var hotspots := _hotspots()
		if not hotspots.is_empty():
			_request(hotspots[focus_index % hotspots.size()], examine)

## Gestisce le scorciatoie discrete di tastiera e controller prima dei controlli UI.
## Il movimento continuo viene invece letto in _process tramite le azioni dell'InputMap.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		keyboard_focus = false
	# Il pulsante musicale resta utilizzabile anche durante le battute e le sequenze.
	if sequences.busy and not ui.help_panel.visible and event is InputEventMouseButton and event.pressed and not ui.music_button.get_global_rect().has_point(event.position):
		if event.button_index == MOUSE_BUTTON_LEFT:
			sequences.advance_dialogue()
		get_viewport().set_input_as_handled()
		return
	var key := event is InputEventKey and event.is_pressed() and not event.is_echo()
	var joy := event is InputEventJoypadButton and event.is_pressed()
	if not key and not joy:
		return
	var code: int = event.keycode if key else -1
	var button: int = event.button_index if joy else -1
	if code == KEY_F1 or code == KEY_QUESTION or button == JOY_BUTTON_START:
		_toggle_help()
	elif ui.help_panel.visible:
		if code == KEY_ESCAPE or button == JOY_BUTTON_B:
			_toggle_help()
		else:
			return # Il menu usa la navigazione UI standard di Godot.
	# Durante una sequenza i comandi del mondo sono sospesi: conferma avanza una sola battuta.
	elif sequences.busy:
		if code in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] or button == JOY_BUTTON_A:
			sequences.advance_dialogue()
		get_viewport().set_input_as_handled()
		return
	elif code == KEY_ESCAPE or button == JOY_BUTTON_B:
		_cancel()
	elif code == KEY_TAB or button in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
		var reverse: bool = (key and event.shift_pressed) or button == JOY_BUTTON_LEFT_SHOULDER
		_cycle_focus(-1 if reverse else 1)
	elif code == KEY_I or button == JOY_BUTTON_Y:
		_close_action_menu()
		inventory_focus = not inventory_focus
		keyboard_focus = true
		focus_index = 0
	elif code in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] or button == JOY_BUTTON_A:
		_confirm_focus()
	elif code == KEY_E or button == JOY_BUTTON_X:
		_confirm_focus(true)
	else:
		return
	# Evita che Invio/A attivi anche un pulsante UI rimasto con il focus dopo aver agito nel gioco.
	get_viewport().set_input_as_handled()

## Il mouse usa la lente; la cornice resta riservata al focus da tastiera/controller.
## Per la cornice dà precedenza al bersaglio del pannello aperto, poi al focus da tastiera/controller.
func _update_highlight() -> void:
	var hotspots := _hotspots()
	var mouse_target: Node2D = null
	if not ui.help_panel.visible and ui.world_panel.get_global_rect().has_point(get_global_mouse_position()):
		mouse_target = _at_mouse()
	ui.world_panel.mouse_default_cursor_shape = Control.CURSOR_CROSS if mouse_target != null else Control.CURSOR_ARROW
	var focused: Node2D = null
	if not ui.help_panel.visible:
		if ui.action_menu.visible and is_instance_valid(menu_hotspot):
			focused = menu_hotspot
		elif keyboard_focus and not inventory_focus and not hotspots.is_empty():
			focused = hotspots[focus_index % hotspots.size()]
	for hotspot in hotspots:
		hotspot.highlighted = keyboard_focus and hotspot == focused
	ui.highlight_inventory(selected_item, focus_index, keyboard_focus and inventory_focus and not sequences.busy)

## Aggiorna il movimento libero oppure il passo attivo della sequenza, mai entrambi nello stesso frame.
func _process(delta: float) -> void:
	if rooms.current_room == null:
		return
	if not ui.help_panel.visible:
		if sequences.busy:
			sequences.tick(delta)
		else:
			var direction := Input.get_axis("walk_left", "walk_right")
			if absf(direction) > 0.05:
				_close_action_menu()
				interactions.cancel(rooms)
				rooms.actor.target_x = rooms.current_room.definition.clamp_x(rooms.actor.current_x + direction * rooms.actor.speed * delta)
			rooms.actor.advance(delta)
			state.player_x = rooms.actor.current_x
			var actions: Array[Step] = interactions.take_ready_actions(state, rooms)
			if not actions.is_empty():
				selected_item = ""
				_start_actions(actions)
	state.player_x = rooms.actor.current_x
	rooms.position_world(ui.world_panel.size.x)
	_update_highlight()

## I salvataggi manuali sono disponibili ai confini delle sequenze, quando lo stato è stabile.
func _save() -> void:
	if sequences.busy:
		return
	_close_action_menu()
	var error: Error = Saves.save_game(state)
	_say(_text("common.game_saved") if error == OK else "Non riesco a salvare la partita: %s" % error_string(error))

## Il servizio valida e migra i dati prima di sostituire la partita corrente.
func _load() -> void:
	if sequences.busy:
		return
	_close_action_menu()
	var error: Error = Saves.load_game(state)
	if error == OK:
		selected_item = ""
		focus_index = 0
		_load_room()
		_say(_text("common.game_loaded"))
	elif error == ERR_FILE_NOT_FOUND:
		_say("Non c'è ancora una partita salvata. Usa il pulsante Salva.")
	else:
		_say("Salvataggio non leggibile. La partita corrente è rimasta invariata.")
