extends Control
## Coordinatore del prototipo: movimento, selezione e interfaccia comune alle stanze.
const State = preload("res://scripts/game_state.gd")
const ActionMenu = preload("res://scripts/action_menu.gd")
const CURSOR_NORMAL = preload("res://assets/graphics/cursors/cursor_normal.png")
const CURSOR_MAGNIFIER = preload("res://assets/graphics/cursors/cursor_magnifier.png")
# Le risorse precaricate rendono disponibili le due scene al momento dell'avvio.
# Le chiavi coincidono con i valori di GameState.room, non con i nomi visibili al giocatore.
const ROOMS := {
	"cabin": preload("res://scenes/rooms/cabin.tscn"),
	"corridor": preload("res://scenes/rooms/corridor.tscn")
}
# Gli ID restano quelli dell'originale; i nomi italiani sono riservati all'interfaccia.
const ITEM_NAMES := {"bottle": "Bourbon", "feather": "Penna d'oca", "magnet": "Calamita",
	"magnetFeather": "Penna magnetica", "key": "Chiave"}
# Velocità in pixel originali al secondo: l'ingrandimento della stanza viene applicato dopo.
const SPEED := 115.0
const GOLD := Color("e5bf73")
# Dati persistenti della partita: questo oggetto sopravvive alla sostituzione delle scene.
var state = State.new()
var dialogue: Dictionary = {}
var current_room: Node2D
var actor: AnimatedSprite2D
# Il centro orizzontale di Churchill converge verso target_x durante _process.
var target_x := 180.0
# Richiesta differita: target, item ed examine vengono conservati fino all'arrivo.
# Un dizionario vuoto significa che si sta soltanto camminando o che non c'è nulla da fare.
var pending: Dictionary = {}
# ID dell'oggetto pronto per l'uso; la stringa vuota indica nessuna selezione.
var selected_item := ""
# Il focus da tastiera/controller è un indice nella lista della stanza o dell'inventario.
# È distinto dal focus UI standard usato dai pulsanti del menu dei comandi.
var focus_index := 0
var inventory_focus := false
var keyboard_focus := false
# Riferimenti ai controlli creati a runtime da _build_ui, per aggiornarli senza cercarli per nome.
var world_panel: Control
var room_label: Label
var subtitle: Label
var hover_label: Label
var speech_label: Label
var inventory_row: HBoxContainer
var selection_label: Label
var action_menu: Control
# Solo uno di questi bersagli è impostato: un nodo nella stanza oppure un ID nell'inventario.
# Vengono azzerati alla chiusura del pannello per non riutilizzare una scelta precedente.
var menu_hotspot: Node2D
var menu_item := ""
var help_panel: Panel
var help_close: Button
var hover_target: Node2D

## Avvio della scena: carica i testi, prepara i controlli e mostra la cabina.
## L'ordine è importante: la stanza aggiorna etichette e inventario già creati da _build_ui.
func _ready() -> void:
	Input.set_custom_mouse_cursor(CURSOR_NORMAL, Input.CURSOR_ARROW, Vector2(1, 1))
	Input.set_custom_mouse_cursor(CURSOR_NORMAL, Input.CURSOR_POINTING_HAND, Vector2(1, 1))
	Input.set_custom_mouse_cursor(CURSOR_MAGNIFIER, Input.CURSOR_CROSS, Vector2(12, 12))
	dialogue = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/dialogue.json"))
	_register_movement()
	_build_ui()
	_load_room()
	_say(_text("cabin.intro.headache") + "  " + _text("cabin.intro.whiskey"))

## Registra due azioni di movimento continue nell'InputMap di Godot.
## Ogni azione accetta tasti fisici e una direzione della levetta; 0.22 è la zona morta.
func _register_movement() -> void:
	for direction in ["walk_left", "walk_right"]:
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

## Crea un pannello con posizione e dimensioni espresse nelle coordinate del suo genitore.
## Il genitore predefinito è questa scena; i pannelli del menu usano invece un contenitore.
func _panel(rect: Rect2, color: Color, parent: Node = self) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

## Crea un testo con lo stile comune del prototipo.
## Le etichette ignorano il mouse: il testo non deve ostacolare i clic sui controlli sottostanti.
func _label(value: String, rect: Rect2, font_size: int = 18, parent: Node = self) -> Label:
	var label := Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("eee4d0"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

## Crea un pulsante e collega il segnale pressed alla funzione ricevuta come callback.
## Il medesimo costruttore serve per barra superiore e menu dei comandi.
func _button(value: String, rect: Rect2, callback: Callable, parent: Node = self) -> Button:
	var button := Button.new()
	button.text = value
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 17)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

## Costruisce l'interfaccia nelle coordinate di riferimento 1152×720.
## La stanza sta dentro world_panel; dialoghi e inventario restano fissi mentre il corridoio scorre.
func _build_ui() -> void:
	_panel(Rect2(0, 0, 1152, 80), Color("192126"))
	_label("1899", Rect2(28, 9, 120, 38), 32).add_theme_color_override("font_color", GOLD)
	_label("STEAM & SPIRIT", Rect2(130, 18, 190, 24), 17)
	room_label = _label("", Rect2(330, 12, 490, 28), 23)
	subtitle = _label("EP01 · Prototipo con grafica originale", Rect2(330, 44, 510, 25), 15)
	_button("Salva · F5", Rect2(856, 20, 110, 38), _save)
	_button("Carica · F9", Rect2(976, 20, 110, 38), _load)
	_button("?", Rect2(1096, 20, 35, 38), _toggle_help)
	# Il ritaglio nasconde le parti del corridoio fuori dalla finestra di gioco.
	# I clic sono gestiti dal contenitore: le immagini della stanza sono nodi 2D, non pulsanti.
	world_panel = Control.new()
	world_panel.position = Vector2(0, 84)
	world_panel.size = Vector2(1152, 412)
	world_panel.clip_contents = true
	world_panel.mouse_default_cursor_shape = Control.CURSOR_ARROW
	world_panel.gui_input.connect(_world_input)
	add_child(world_panel)
	_panel(Rect2(24, 502, 1104, 82), Color("1e292e"))
	_label("WINSTON CHURCHILL", Rect2(40, 506, 270, 20), 13).add_theme_color_override("font_color", GOLD)
	speech_label = _label("", Rect2(40, 530, 1070, 50), 18)
	speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selection_label = _label("INVENTARIO", Rect2(28, 590, 750, 24), 15)
	inventory_row = HBoxContainer.new()
	inventory_row.position = Vector2(28, 620)
	inventory_row.size = Vector2(850, 52)
	inventory_row.add_theme_constant_override("separation", 10)
	add_child(inventory_row)
	hover_label = _label("", Rect2(28, 675, 1095, 20), 15)
	hover_label.add_theme_color_override("font_color", GOLD)
	# Il pannello è figlio della UI, così mantiene dimensioni fisse e non viene ritagliato dalla stanza.
	action_menu = ActionMenu.new()
	add_child(action_menu)
	action_menu.chosen.connect(_choose_action)
	_build_help()

## Prepara il menu dei comandi, inizialmente nascosto, e i suoi pulsanti.
## Lo sfondo copre la finestra per intercettare i clic che altrimenti raggiungerebbero il gioco.
func _build_help() -> void:
	help_panel = _panel(Rect2(0, 0, 1152, 720), Color(0, 0, 0, 0.65))
	help_panel.z_index = 10
	var content := _panel(Rect2(170, 95, 812, 550), Color("152027"), help_panel)
	_label("CABINA DI CHURCHILL · COMANDI", Rect2(30, 20, 760, 40), 26, content)
	var commands := "MOUSE · BASTA IL TASTO SINISTRO\nClic sul pavimento: cammina. Clic su un oggetto: apri le due scelte.\nLente: esamina · Mano: usa/raccogli · Bocca: parla · Porta: esci.\nInventario: clic, poi mano per selezionare; quindi clic sul bersaglio.\nPer combinare: scegli il primo, poi clic sul secondo. Annulla: clic sul pavimento.\n\nTASTIERA\nA/D o frecce: cammina · Tab / Maiusc+Tab: scegli un bersaglio\nI: passa all'inventario / alla stanza · Invio: agisci · E: esamina\nEsc: annulla selezione · F5: salva · F9: carica\n\nCONTROLLER (etichette Xbox)\nLevetta sinistra: cammina · LB/RB: scegli bersaglio · Y: inventario/stanza\nA: agisci · X: esamina · B: annulla · Start: apri/chiudi questo menu\nNel menu: croce direzionale e A. Salvataggio manuale, uno slot."
	_label(commands, Rect2(30, 65, 755, 390), 17, content)
	var save := _button("Salva", Rect2(30, 480, 145, 42), func():
		_save()
		_toggle_help(), content)
	var load_button := _button("Carica", Rect2(185, 480, 145, 42), func():
		_load()
		_toggle_help(), content)
	var reset := _button("Ricomincia", Rect2(340, 480, 180, 42), _new_game, content)
	reset.tooltip_text = "Ricomincia il prototipo. Il file salvato resta disponibile con Carica."
	help_close = _button("Torna al gioco", Rect2(530, 480, 250, 42), _toggle_help, content)
	# Vicini espliciti: il controller resta sui pulsanti del menu, senza saltare alla barra sottostante.
	# Il percorso è circolare in entrambe le direzioni, anche per Tab e Maiusc+Tab.
	var buttons := [save, load_button, reset, help_close]
	for i in buttons.size():
		var previous: Button = buttons[posmod(i - 1, buttons.size())]
		var next: Button = buttons[(i + 1) % buttons.size()]
		buttons[i].focus_neighbor_left = buttons[i].get_path_to(previous)
		buttons[i].focus_neighbor_right = buttons[i].get_path_to(next)
		buttons[i].focus_neighbor_top = buttons[i].get_path_to(previous)
		buttons[i].focus_neighbor_bottom = buttons[i].get_path_to(next)
		buttons[i].focus_next = buttons[i].get_path_to(next)
		buttons[i].focus_previous = buttons[i].get_path_to(previous)
	help_panel.hide()

## Apre o chiude il menu dei comandi, eliminando eventuali scelte contestuali aperte.
## All'apertura ferma il movimento e assegna il focus UI al pulsante di ritorno al gioco.
func _toggle_help() -> void:
	_close_action_menu()
	help_panel.visible = not help_panel.visible
	if help_panel.visible:
		pending.clear()
		target_x = state.player_x
		help_close.grab_focus()
	else:
		help_close.release_focus()

## Crea una partita vuota e ricostruisce la cabina allo stato iniziale.
## Non cancella il file su disco: Carica permette ancora di recuperare il salvataggio manuale.
func _new_game() -> void:
	state = State.new()
	selected_item = ""
	inventory_focus = false
	focus_index = 0
	_load_room()
	help_panel.hide()
	_say(_text("cabin.intro.headache") + "  " + _text("cabin.intro.whiskey"))

## Istanzia la scena indicata dallo stato e vi aggiunge il personaggio.
## Lo stato persiste fuori dalla scena: cambiare stanza non azzera inventario ed enigma.
func _load_room() -> void:
	_close_action_menu()
	if is_instance_valid(current_room):
		# La rimozione dall'albero è immediata; la memoria viene liberata a fine frame con queue_free.
		world_panel.remove_child(current_room)
		current_room.queue_free()
	current_room = ROOMS[state.room].instantiate()
	current_room.scale = Vector2(1.5, 1.5)
	world_panel.add_child(current_room)
	actor = AnimatedSprite2D.new()
	actor.name = "Churchill"
	actor.centered = false
	# Churchill è davanti agli oggetti normali; il letto ha z_index = 2 e lo copre dove necessario.
	actor.z_index = 1
	# Duplichiamo SpriteFrames prima di aggiungere idle, evitando di modificare la risorsa condivisa.
	var frames: SpriteFrames = load("res://assets/graphics/original/churchillWalk.tres").duplicate()
	frames.rename_animation("default", "walk")
	frames.add_animation("idle")
	frames.add_frame("idle", load("res://assets/graphics/original/churchillStand.png"))
	actor.sprite_frames = frames
	actor.play("idle")
	current_room.add_child(actor)
	target_x = state.player_x
	pending.clear()
	hover_target = null
	_refresh()
	_position_world()

## Riconosce la classe base e tutte le sottoclassi, non soltanto uno script identico.
## Per l'input si escludono i nascosti; per sincronizzare la grafica si includono tutti.
func _hotspots(visible_only: bool = true) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for child in current_room.get_children():
		if child is Hotspot and (not visible_only or child.visible):
			result.append(child)
	return result

## Risolve una richiesta differita nella stanza attuale: un bersaglio rimosso o nascosto non agisce.
func _find_hotspot(id: String) -> Hotspot:
	for hotspot in _hotspots():
		if hotspot.hotspot_id == id:
			return hotspot
	return null

## Allinea immagini, testi e pulsanti dell'inventario allo stato logico corrente.
## Viene chiamata dopo un'azione o un caricamento, non a ogni fotogramma.
func _refresh() -> void:
	# Ogni oggetto interpreta lo stato: qui non servono nomi di nodi o regole specifiche della cabina.
	for hotspot in _hotspots(false):
		hotspot.sync_from_state(state)
	room_label.text = "Cabina di Churchill" if state.room == "cabin" else "Corridoio del Leviathan"
	subtitle.text = "EP01 · Prototipo con grafica originale" if state.room == "cabin" else "Uscita riuscita · Puoi tornare alla cabina"
	# L'inventario è piccolo: ricrearne i pulsanti evita di mantenere copie separate del suo contenuto.
	for child in inventory_row.get_children():
		inventory_row.remove_child(child)
		child.queue_free()
	if selected_item not in state.inventory:
		selected_item = ""
	for item in state.inventory:
		var button := Button.new()
		button.text = ITEM_NAMES[item]
		button.icon = load("res://assets/graphics/original/O_%s.png" % item)
		button.add_theme_font_size_override("font_size", 16)
		button.custom_minimum_size = Vector2(190, 52)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.modulate = GOLD if selected_item == item else Color.WHITE
		# bind conserva l'ID e il pulsante associati a questa voce anche dopo la fine del ciclo.
		button.pressed.connect(_inventory_click.bind(item, button))
		# Il destro resta una scorciatoia; la lente rende disponibile lo stesso esame col solo sinistro.
		button.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				_say(_item_description(item)))
		inventory_row.add_child(button)
	if state.inventory.is_empty():
		_label("Ancora nessun oggetto. Esplora la cabina.", Rect2(0, 0, 750, 52), 17, inventory_row)
	_update_selection()

## Aggiorna la frase sopra l'inventario per mostrare quale oggetto si sta usando.
func _update_selection() -> void:
	selection_label.text = "INVENTARIO" if selected_item.is_empty() else "USA %s CON…" % ITEM_NAMES[selected_item]

## Nasconde il pannello e rimuove i riferimenti al suo bersaglio.
## Il controllo di validità consente di chiamarla anche prima che il pannello sia stato costruito.
func _close_action_menu() -> void:
	if is_instance_valid(action_menu):
		action_menu.hide()
	menu_hotspot = null
	menu_item = ""

## Apre le due scelte su un oggetto della stanza, senza ancora eseguire alcuna azione.
## Il tipo esportato dell'hotspot sceglie la grafica mano, bocca oppure uscita.
func _open_hotspot_menu(hotspot: Node2D) -> void:
	_close_action_menu()
	pending.clear()
	target_x = state.player_x
	menu_hotspot = hotspot
	var kind: String = hotspot.interaction_kind
	var caption: String = {"hand": "Interagisci / raccogli", "mouth": "Parla", "exit": "Esci"}[kind]
	var center: Vector2 = hotspot.to_global(hotspot.hit_size / 2)
	# Stanza ingrandita e corridoio scorrevole usano trasformazioni diverse dalla UI:
	# passiamo prima al canvas globale, poi alle coordinate locali del genitore del pannello.
	action_menu.open(get_global_transform().affine_inverse() * center, kind, caption)

## Gestisce il clic sinistro su un oggetto posseduto.
## Senza selezione apre lente/mano; con una selezione prova la combinazione o la deselezione.
func _inventory_click(item: String, button: Button) -> void:
	_close_action_menu()
	pending.clear()
	target_x = state.player_x
	if not selected_item.is_empty():
		_select_item(item)
		return
	menu_item = item
	var center: Vector2 = button.get_global_rect().get_center()
	action_menu.open(get_global_transform().affine_inverse() * center, "hand", "Usa / combina")

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

## Risolve una risposta del modello in testo da mostrare al giocatore.
## Risolve una chiave descrittiva nel catalogo; il prototipo usa l'italiano.
## Il separatore | conserva le alternative originali: viene mostrata la prima.
func _text(id: String) -> String:
	if not dialogue.has(id):
		push_warning("Dialogo mancante: " + id)
		return str(dialogue.get("common.missing_response", {}).get("it", "Non saprei cosa farci."))
	return str(dialogue[id]["it"]).split("|")[0]

## Associa ogni ID d'inventario alla descrizione originale usata dalla lente.
func _item_description(item: String) -> String:
	return _text({"bottle": "inventory.bottle.examine", "feather": "inventory.feather.examine", "magnet": "inventory.magnet.examine", "magnetFeather": "inventory.magnet_feather.examine", "key": "inventory.key.examine"}[item])

## Sostituisce la battuta nel riquadro dei dialoghi; resta visibile fino alla battuta successiva.
func _say(value: String) -> void:
	speech_label.text = value

## Gestisce solo i clic ricevuti dall'area della stanza.
## Il sinistro apre le scelte o usa un oggetto selezionato; il destro resta una scorciatoia facoltativa.
func _world_input(event: InputEvent) -> void:
	if help_panel.visible:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index not in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			return
		keyboard_focus = false
		# gui_input fornisce una posizione locale al contenitore, mentre gli hotspot ricevono punti globali.
		var point: Vector2 = world_panel.get_global_transform() * event.position
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
			pending.clear()
			target_x = clampf(current_room.to_local(point).x, 24, _room_width() - 24)

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

## Memorizza l'azione e la destinazione di avvicinamento, senza modificare ancora l'enigma.
## _process esegue la richiesta solo quando Churchill arriva alla coordinata prevista.
func _request(hotspot: Node2D, examine: bool) -> void:
	_close_action_menu()
	pending = {"target": hotspot.hotspot_id, "item": selected_item, "examine": examine}
	# Il margine di 24 pixel tiene il personaggio dentro la stanza anche sugli hotspot ai bordi.
	target_x = clampf(hotspot.approach_x, 24, _room_width() - 24)

## Seleziona un oggetto, lo deseleziona al secondo clic oppure combina due oggetti diversi.
## La combinazione è delegata a GameState; qui si aggiornano soltanto selezione e interfaccia.
func _select_item(item: String) -> void:
	_close_action_menu()
	pending.clear()
	target_x = state.player_x
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
	pending.clear()
	target_x = state.player_x
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
	var key := event is InputEventKey and event.is_pressed() and not event.is_echo()
	var joy := event is InputEventJoypadButton and event.is_pressed()
	if not key and not joy:
		return
	var code: int = event.keycode if key else -1
	var button: int = event.button_index if joy else -1
	if code == KEY_F1 or code == KEY_QUESTION or button == JOY_BUTTON_START:
		_toggle_help()
	elif help_panel.visible:
		if code == KEY_ESCAPE or button == JOY_BUTTON_B:
			_toggle_help()
		else:
			return # Il menu usa la navigazione UI standard di Godot.
	elif code == KEY_F5:
		_save()
	elif code == KEY_F9:
		_load()
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

## Larghezza della stanza nelle coordinate originali, prima dell'ingrandimento grafico 1.5×.
func _room_width() -> float:
	return 648.0 if state.room == "cabin" else 892.0

## Aggiornamento a ogni fotogramma: movimento, esecuzione dell'azione all'arrivo e selezione visiva.
## delta è il tempo trascorso in secondi: la velocità non dipende dal numero di fotogrammi al secondo.
func _process(delta: float) -> void:
	if current_room == null:
		return
	if not help_panel.visible:
		var direction := Input.get_axis("walk_left", "walk_right")
		if absf(direction) > 0.05:
			# Un comando di movimento manuale prende il posto di qualunque azione in attesa.
			_close_action_menu()
			pending.clear()
			target_x = clampf(state.player_x + direction * SPEED * delta, 24, _room_width() - 24)
		var distance: float = target_x - state.player_x
		if absf(distance) > 0.1:
			# move_toward non supera la destinazione; flip_h riutilizza la stessa camminata nei due versi.
			state.player_x = move_toward(state.player_x, target_x, SPEED * delta)
			actor.flip_h = distance < 0
			actor.play("walk")
		else:
			actor.play("idle")
			if not pending.is_empty():
				# La regola può cambiare room: confrontiamo prima/dopo per decidere se ricreare la scena.
				var old_room: String = state.room
				var hotspot := _find_hotspot(pending.target)
				if hotspot == null:
					# Il bersaglio potrebbe essere sparito mentre Churchill si avvicinava.
					_cancel()
					return
				var message: String = hotspot.execute(state, pending.item, pending.examine)
				pending.clear()
				selected_item = ""
				if state.room != old_room:
					focus_index = 0
					_load_room()
				else:
					_refresh()
				_say(_text(message))
	else:
		# Col menu aperto non si avanza il movimento e non si esegue un'azione differita.
		actor.play("idle")
	_position_world()
	_update_highlight()

## Posiziona Churchill nelle coordinate della stanza e calcola lo scorrimento del corridoio.
## La cabina entra interamente nell'area visibile e rimane centrata.
func _position_world() -> void:
	# Gli sprite originali sono larghi 44 pixel: -22 converte il centro nella posizione dell'angolo sinistro.
	# L'altezza rimane sulla corsia orizzontale originale, con i piedi a y = 200.
	actor.position = Vector2(roundf(state.player_x) - 22, 100)
	if state.room == "cabin":
		current_room.position = Vector2(90, 0)
	else:
		# Seguiamo il personaggio mantenendolo vicino al centro, senza mostrare oltre i bordi del fondale.
		current_room.position = Vector2(clampf(576 - state.player_x * 1.5, 1152 - _room_width() * 1.5, 0), 0)

## Il mouse usa la lente; la cornice resta riservata al focus da tastiera/controller.
## Dà precedenza al bersaglio del pannello aperto, poi al focus da tastiera/controller e infine al mouse.
func _update_highlight() -> void:
	var hotspots := _hotspots()
	var mouse_target: Node2D = null
	if not help_panel.visible and world_panel.get_global_rect().has_point(get_global_mouse_position()):
		mouse_target = _at_mouse()
	world_panel.mouse_default_cursor_shape = Control.CURSOR_CROSS if mouse_target != null else Control.CURSOR_ARROW
	var focused: Node2D = null
	if not help_panel.visible:
		if action_menu.visible and is_instance_valid(menu_hotspot):
			focused = menu_hotspot
		elif keyboard_focus and not inventory_focus and not hotspots.is_empty():
			focused = hotspots[focus_index % hotspots.size()]
		elif not keyboard_focus and world_panel.get_global_rect().has_point(get_global_mouse_position()):
			focused = _at_mouse()
	for hotspot in hotspots:
		hotspot.highlighted = keyboard_focus and hotspot == focused
	hover_target = focused
	var name_text := ""
	if focused != null:
		name_text = focused.display_name
	elif keyboard_focus and inventory_focus and not state.inventory.is_empty():
		name_text = ITEM_NAMES[state.inventory[focus_index % state.inventory.size()]]
	# La tinta dorata segnala sia l'oggetto scelto per l'uso sia la voce raggiunta dal controller.
	for i in inventory_row.get_child_count():
		var child := inventory_row.get_child(i)
		if child is Button:
			var focused_item: bool = keyboard_focus and inventory_focus and i == focus_index % maxi(1, state.inventory.size())
			child.modulate = GOLD if focused_item or state.inventory[i] == selected_item else Color.WHITE
	hover_label.text = name_text
	if not name_text.is_empty() and not selected_item.is_empty():
		hover_label.text = "Usa %s con %s" % [ITEM_NAMES[selected_item], name_text]

## Salva lo stato attraverso il modello e mostra un messaggio di successo o l'errore restituito.
func _save() -> void:
	_close_action_menu()
	var error: Error = state.save_game()
	_say(_text("common.game_saved") if error == OK else "Non riesco a salvare la partita: %s" % error_string(error))

## Carica un salvataggio validato e ricostruisce la stanza, scartando le selezioni dell'interfaccia.
## Un file assente o illeggibile produce una battuta senza sostituire la partita corrente.
func _load() -> void:
	_close_action_menu()
	var error: Error = state.load_game()
	if error == OK:
		selected_item = ""
		focus_index = 0
		_load_room()
		_say(_text("common.game_loaded"))
	elif error == ERR_FILE_NOT_FOUND:
		_say("Non c'è ancora una partita salvata. Usa Salva o F5.")
	else:
		_say("Salvataggio non leggibile. La partita corrente è rimasta invariata.")
