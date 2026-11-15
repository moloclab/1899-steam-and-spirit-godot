extends Control
## Interfaccia del gioco: costruisce i controlli e invia intenzioni tramite segnali.
## Non esegue enigmi, transizioni o scritture dei salvataggi.
signal save_requested
signal load_requested
signal music_toggled(enabled: bool)
signal new_game_requested
signal world_input(event: InputEvent)
signal action_chosen(examine: bool)
signal inventory_pressed(item: String, button: Button)
signal item_examined(item: String)
signal menu_toggled(open: bool)
const ActionMenu = preload("res://scripts/action_menu.gd")
const Items = preload("res://scripts/data/item_catalog.gd")
const GOLD := Color("e5bf73")
var world_panel: Control
var speaker_label: Label
var speech_label: Label
var continue_label: Label
var inventory_row: HBoxContainer
var inventory_scroll: ScrollContainer
var action_menu: Control
var help_panel: Panel
var help_close: Button
var reset_button: Button
var save_buttons: Array[Button] = []
var music_button: Button
var _inventory_ids: Array[String] = []
var _inventory_buttons: Array[Button] = []
var _inventory_built := false
var _highlight_valid := false
var _highlight_selected := ""
var _highlight_index := -1

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
func _label(value: String, rect: Rect2, font_size: int = 32, parent: Node = self) -> Label:
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
	button.add_theme_font_size_override("font_size", 32)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

## Costruisce l'interfaccia nelle coordinate di riferimento 1152×720.
## La stanza sta dentro world_panel; dialoghi e inventario restano fissi mentre il corridoio scorre.
func _ready() -> void:
	# Occupa il viewport del coordinatore senza intercettare i clic destinati ai controlli figli.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	save_buttons.append(_button("Salva", Rect2(696, 20, 110, 38), save_requested.emit))
	save_buttons.append(_button("Carica", Rect2(816, 20, 110, 38), load_requested.emit))
	# Il controllo musicale resta accanto a Carica e mostra lo stato corrente del sottofondo.
	music_button = _button("Musica: ON", Rect2(936, 20, 150, 38), _toggle_music)
	music_button.toggle_mode = true
	music_button.button_pressed = true
	# Il ritaglio nasconde le parti del corridoio fuori dalla finestra di gioco.
	# I clic sono gestiti dal contenitore: le immagini della stanza sono nodi 2D, non pulsanti.
	world_panel = Control.new()
	world_panel.position = Vector2(0, 84)
	world_panel.size = Vector2(1152, 412)
	world_panel.clip_contents = true
	world_panel.mouse_default_cursor_shape = Control.CURSOR_ARROW
	world_panel.gui_input.connect(func(event: InputEvent): world_input.emit(event))
	add_child(world_panel)
	speaker_label = _label("WINSTON CHURCHILL", Rect2(40, 506, 700, 20), 32)
	speaker_label.add_theme_color_override("font_color", GOLD)
	continue_label = _label("Clic / Invio / A per continuare", Rect2(780, 506, 330, 20), 32)
	continue_label.hide()
	speech_label = _label("", Rect2(40, 530, 1070, 50), 32)
	speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_row = HBoxContainer.new()
	inventory_row.position = Vector2.ZERO
	inventory_row.size = Vector2(850, 52)
	inventory_row.add_theme_constant_override("separation", 10)
	inventory_scroll = ScrollContainer.new()
	inventory_scroll.position = Vector2(28, 620)
	inventory_scroll.size = Vector2(1095, 68)
	inventory_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(inventory_scroll)
	inventory_scroll.add_child(inventory_row)
	# Il pannello è figlio della UI, così mantiene dimensioni fisse e non viene ritagliato dalla stanza.
	action_menu = ActionMenu.new()
	add_child(action_menu)
	action_menu.chosen.connect(func(examine: bool): action_chosen.emit(examine))
	_build_help()

## Disattiva o riattiva il sottofondo senza modificare lo stato della partita.
func _toggle_music() -> void:
	music_button.text = "Musica: ON" if music_button.button_pressed else "Musica: OFF"
	music_toggled.emit(music_button.button_pressed)

## Prepara il menu dei comandi, inizialmente nascosto, e i suoi pulsanti.
## Lo sfondo copre la finestra per intercettare i clic che altrimenti raggiungerebbero il gioco.
func _build_help() -> void:
	help_panel = _panel(Rect2(0, 0, 1152, 720), Color(0, 0, 0, 0.65))
	help_panel.z_index = 10
	var content := _panel(Rect2(170, 95, 812, 550), Color("152027"), help_panel)
	_label("CABINA DI CHURCHILL · COMANDI", Rect2(30, 20, 760, 40), 32, content)
	var commands := "MOUSE · BASTA IL TASTO SINISTRO\nClic sul pavimento: cammina. Clic su un oggetto: apri le due scelte.\nLente: esamina · Mano: usa/raccogli · Bocca: parla · Porta: esci.\nInventario: clic per descrizione e selezione; poi clic sul bersaglio.\nPer combinare: scegli il primo, poi clic sul secondo. Annulla: clic sul pavimento.\n\nTASTIERA\nA/D o frecce: cammina · Tab / Maiusc+Tab: scegli un bersaglio\nI: passa all'inventario / alla stanza · Invio: agisci · E: esamina\nEsc: annulla selezione · Salva e Carica: pulsanti nella parte superiore\n\nCONTROLLER (etichette Xbox)\nLevetta sinistra: cammina · LB/RB: scegli bersaglio · Y: inventario/stanza\nA: agisci · X: esamina · B: annulla · Start: apri/chiudi questo menu\nNel menu: croce direzionale e A. Salvataggio manuale, uno slot."
	_label(commands, Rect2(30, 65, 755, 390), 32, content)
	var save := _button("Salva", Rect2(30, 480, 145, 42), func():
		save_requested.emit()
		_toggle_help(), content)
	var load_button := _button("Carica", Rect2(185, 480, 145, 42), func():
		load_requested.emit()
		_toggle_help(), content)
	reset_button = _button("Ricomincia", Rect2(340, 480, 180, 42), new_game_requested.emit, content)
	reset_button.tooltip_text = "Ricomincia il prototipo. Il file salvato resta disponibile con Carica."
	help_close = _button("Torna al gioco", Rect2(530, 480, 250, 42), _toggle_help, content)
	# Vicini espliciti: il controller resta sui pulsanti del menu, senza saltare alla barra sottostante.
	# Il percorso è circolare in entrambe le direzioni, anche per Tab e Maiusc+Tab.
	var buttons := [save, load_button, reset_button, help_close]
	for i in buttons.size():
		var previous: Button = buttons[posmod(i - 1, buttons.size())]
		var next: Button = buttons[(i + 1) % buttons.size()]
		buttons[i].focus_neighbor_left = buttons[i].get_path_to(previous)
		buttons[i].focus_neighbor_right = buttons[i].get_path_to(next)
		buttons[i].focus_neighbor_top = buttons[i].get_path_to(previous)
		buttons[i].focus_neighbor_bottom = buttons[i].get_path_to(next)
		buttons[i].focus_next = buttons[i].get_path_to(next)
		buttons[i].focus_previous = buttons[i].get_path_to(previous)
	save_buttons.append(save)
	save_buttons.append(load_button)
	help_panel.hide()

## Apre o chiude il menu dei comandi, eliminando eventuali scelte contestuali aperte.
## Comunica la pausa al coordinatore e assegna il focus UI al pulsante di ritorno al gioco.
func _toggle_help() -> void:
	action_menu.hide()
	help_panel.visible = not help_panel.visible
	if help_panel.visible:
		menu_toggled.emit(true)
		help_close.grab_focus()
	else:
		help_close.release_focus()
		menu_toggled.emit(false)

## Aggiorna la battuta mantenendo lo speaker distinto dal testo traducibile.
func say(value: String, speaker: String = "Winston Churchill") -> void:
	speech_label.text = value
	speaker_label.text = speaker.to_upper()

## Ricrea i pulsanti solo se cambiano gli ID o il loro ordine; conserva focus e scorrimento altrimenti.
func refresh_inventory(inventory: Array[String], _selected: String, _texts) -> void:
	if _inventory_built and _inventory_ids == inventory:
		return
	_inventory_built = true
	_highlight_valid = false
	_inventory_ids = inventory.duplicate()
	_inventory_buttons.clear()
	for child in inventory_row.get_children():
		inventory_row.remove_child(child)
		child.queue_free()
	for item in inventory:
		var definition: Resource = Items.ITEMS[item]
		var button := Button.new()
		# Nell'inventario l'oggetto viene mostrato solo tramite la sua icona.
		button.icon = definition.icon
		button.add_theme_font_size_override("font_size", 32)
		button.custom_minimum_size = Vector2(52, 52)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(func(): inventory_pressed.emit(item, button))
		button.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				item_examined.emit(item))
		inventory_row.add_child(button)
		_inventory_buttons.append(button)

## Aggiorna colori e scorrimento solo quando cambiano selezione, focus o pulsanti.
func highlight_inventory(selected: String, focus_index: int, focused: bool) -> void:
	var active_index := posmod(focus_index, _inventory_ids.size()) if focused and not _inventory_ids.is_empty() else -1
	if _highlight_valid and _highlight_selected == selected and _highlight_index == active_index:
		return
	_highlight_valid = true
	_highlight_selected = selected
	_highlight_index = active_index
	for i in _inventory_buttons.size():
		var button := _inventory_buttons[i]
		var is_focused := i == active_index
		button.modulate = GOLD if is_focused or _inventory_ids[i] == selected else Color.WHITE
		if is_focused:
			inventory_scroll.ensure_control_visible(button)

## Impedisce di salvare o ricominciare a metà di una sequenza, lasciando accessibile il menu di pausa.
func lock_interactions(locked: bool) -> void:
	for button in save_buttons:
		button.disabled = locked
	reset_button.disabled = locked
	for button in _inventory_buttons:
		button.disabled = locked
