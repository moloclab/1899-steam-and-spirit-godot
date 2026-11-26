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
const Texts = preload("res://scripts/data/dictionary_catalog.gd")
const Items = preload("res://scripts/data/item_catalog.gd")
const GOLD := Color("e5bf73")
## Cornici approvate: V2 per gli slot normali, V9 per l'oggetto selezionato.
const INVENTORY_FRAME := preload("res://assets/graphics/ui/inventory_frame.png")
const INVENTORY_FRAME_SELECTED := preload("res://assets/graphics/ui/inventory_frame-selected.png")
## Riutilizza V2 desaturata per tutti gli slot senza modificare il PNG originale.
var _inventory_frame_gray: ImageTexture
## Il coordinatore passa il catalogo condiviso prima della creazione dei controlli.
var texts: Texts
var _localized_controls: Dictionary = {}
var _speaker_key := "common.speaker.churchill"
const SPEECH_SIZE := Vector2(200, 100)
const SPEECH_FONT_SIZE := 40
var world_panel: Control
var speaker_label: Label
var speech_label: Label
var inventory_row: HBoxContainer
var inventory_scroll: ScrollContainer
var action_menu: Control
var help_panel: Panel
var help_close: Button
var reset_button: Button
var save_buttons: Array[Button] = []
var music_button: Button
var language_button: Button
var help_button: Button
var _inventory_ids: Array[String] = []
var _inventory_buttons: Array[Button] = []
var _inventory_built := false
var _highlight_valid := false
var _highlight_selected := ""
var _highlight_index := -1

## Conserva le chiavi per aggiornare i testi quando cambia la lingua.
func _localize(control: Control, key: String, property: String = "text") -> void:
	if key.is_empty():
		return
	if not _localized_controls.has(control):
		_localized_controls[control] = {}
	_localized_controls[control][property] = key
	control.set(property, texts.text(key))

## Aggiorna i controlli senza ricostruire la UI o modificare lo stato della musica.
func _refresh_texts() -> void:
	for control in _localized_controls:
		for property in _localized_controls[control]:
			control.set(property, texts.text(_localized_controls[control][property]))
	speaker_label.text = texts.text(_speaker_key).to_upper()

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

## Crea un testo dalla chiave del vocabolario con lo stile comune del prototipo.
## Le etichette ignorano il mouse: il testo non deve ostacolare i clic sui controlli sottostanti.
func _label(key: String, rect: Rect2, font_size: int = 32, parent: Node = self) -> Label:
	var label := Label.new()
	_localize(label, key)
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("eee4d0"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

## Crea un pulsante dalla chiave del vocabolario e collega pressed alla callback.
## Il medesimo costruttore serve per barra superiore e menu dei comandi.
func _button(key: String, rect: Rect2, callback: Callable, parent: Node = self) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	_localize(button, key)
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 32)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

## Condivide scala e stile delle icone, lasciando trasparente lo sfondo degli slot.
func _inventory_button(texture: Texture2D, background: Color = Color.TRANSPARENT) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	var icon_image: Image = texture.get_image().duplicate()
	icon_image.resize(icon_image.get_width() * 2, icon_image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	button.icon = ImageTexture.create_from_image(icon_image)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var icon_background := StyleBoxFlat.new()
	icon_background.bg_color = background
	for style in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(style, icon_background)
	button.add_theme_font_size_override("font_size", 32)
	button.custom_minimum_size = Vector2(100, 100)
	# Oggetti e bussola usano la stessa mano personalizzata degli hotspot nella stanza.
	button.mouse_default_cursor_shape = Control.CURSOR_CROSS
	return button

## Costruisce l'interfaccia nella risoluzione di riferimento del progetto.
## La stanza sta dentro world_panel; il dialogo segue chi parla e l'inventario resta fisso.
func _ready() -> void:
	# Desatura e scurisce la cornice V2 al 60% della luminosita', conservandone il canale alpha.
	var frame_image := INVENTORY_FRAME.get_image().duplicate() as Image
	_inventory_frame_gray = ImageTexture.create_from_image(frame_image)
	texts.language_changed.connect(_refresh_texts)
	# Occupa il viewport del coordinatore senza intercettare i clic destinati ai controlli figli.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# La larghezza logica resta fissa mentre Godot scala l'intera UI sul dispositivo.
	var view_width := float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	# Il ritaglio nasconde le parti del corridoio fuori dalla finestra di gioco.
	# I clic sono gestiti dal contenitore: le immagini della stanza sono nodi 2D, non pulsanti.
	world_panel = Control.new()
	# La stanza parte dal bordo superiore della finestra.
	world_panel.position = Vector2.ZERO
	# La parete parte da y=0: i suoi 192 px a scala 3× terminano dove inizia l'inventario.
	var world_height := 576.0
	world_panel.size = Vector2(view_width, world_height)
	world_panel.clip_contents = true
	world_panel.mouse_default_cursor_shape = Control.CURSOR_ARROW
	world_panel.gui_input.connect(func(event: InputEvent): world_input.emit(event))
	add_child(world_panel)
	speaker_label = _label("common.speaker.churchill", Rect2(40, 506, 700, 20), 32)
	speaker_label.add_theme_color_override("font_color", GOLD)
	# Il nome resta disponibile alla localizzazione; la battuta identifica chi parla tramite la posizione.
	speaker_label.hide()
	# Il testo si sovrappone alla stanza senza intercettare i clic e senza essere ritagliato al bordo superiore.
	speech_label = _label("", Rect2(Vector2.ZERO, SPEECH_SIZE), SPEECH_FONT_SIZE)
	speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	speech_label.clip_text = true
	speech_label.z_index = 2
	# L'ombra ripete il testo in nero, spostato di un pixel a destra e in basso.
	speech_label.add_theme_constant_override("outline_size", 0)
	speech_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	speech_label.add_theme_constant_override("shadow_offset_x", 3)
	speech_label.add_theme_constant_override("shadow_offset_y", 3)
	speech_label.add_theme_constant_override("line_spacing", 0)
	# La fascia opaca usa il marrone scuro #120F0E della palette e resta separata dalla stanza.
	var view_height := float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var inventory_background := _panel(Rect2(0, world_height, view_width, view_height - world_height), Color("0B0908"))
	inventory_background.z_index = 3
	# La bussola resta nel primo spazio anche con inventario vuoto o scorrimento degli oggetti.
	# Lo sfondo trasparente lascia visibile la fascia inventario sotto la bussola.
	help_button = _inventory_button(preload("res://assets/graphics/ui/option.png"), Color.TRANSPARENT)
	help_button.position = Vector2(30, world_height + 19)
	help_button.z_index = 3
	help_button.pressed.connect(_toggle_help)
	add_child(help_button)
	inventory_row = HBoxContainer.new()
	inventory_row.position = Vector2.ZERO
	# I pannelli 52×52 occupano 104 px alla scala di visualizzazione 2×.
	inventory_row.size = Vector2(850, 104)
	inventory_row.add_theme_constant_override("separation", 10)
	inventory_scroll = ScrollContainer.new()
	# Il contenitore lascia visibile lo sfondo dedicato della fascia inventario.
	inventory_scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	# Le icone stanno sopra la fascia opaca e sotto la patina dell'inventario.
	inventory_scroll.z_index = 3
	# Riserva il primo spazio fisso alla bussola e mantiene la separazione comune di 10 px.
	inventory_scroll.position = help_button.position + Vector2(110, 0)
	# Lascia spazio sotto le icone anche alla barra di scorrimento orizzontale.
	inventory_scroll.size = Vector2(view_width - 166, 120)
	inventory_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(inventory_scroll)
	inventory_scroll.add_child(inventory_row)
	# La stessa patina della stanza si sovrappone anche alla fascia e alle icone, lasciando passare i clic.
	var inventory_grime := TextureRect.new()
	inventory_grime.name = "InventoryGrime"
	inventory_grime.texture = preload("res://assets/graphics/ui/hover.png")
	inventory_grime.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	inventory_grime.stretch_mode = TextureRect.STRETCH_SCALE
	inventory_grime.position = inventory_background.position
	inventory_grime.size = inventory_background.size
	inventory_grime.z_index = 4
	inventory_grime.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grime_material := CanvasItemMaterial.new()
	grime_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	inventory_grime.material = grime_material
	add_child(inventory_grime)
	# Il pannello è figlio della UI, così mantiene dimensioni fisse e non viene ritagliato dalla stanza.
	action_menu = ActionMenu.new()
	add_child(action_menu)
	action_menu.chosen.connect(func(examine: bool): action_chosen.emit(examine))
	_build_help()

## Disattiva o riattiva il sottofondo senza modificare lo stato della partita.
func _toggle_music() -> void:
	_localize(music_button, "common.ui.music_on" if music_button.button_pressed else "common.ui.music_off")
	music_toggled.emit(music_button.button_pressed)

## Alterna italiano e inglese tramite il catalogo condiviso, aggiornando anche i dialoghi.
func _toggle_language() -> void:
	texts.language = "en" if texts.language == "it" else "it"

## Prepara il menu dei comandi, inizialmente nascosto, e i suoi pulsanti.
## Lo sfondo copre la finestra per intercettare i clic che altrimenti raggiungerebbero il gioco.
func _build_help() -> void:
	# Il velo copre tutta la base logica e il menu resta centrato anche cambiando risoluzione.
	var view_size := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	help_panel = _panel(Rect2(Vector2.ZERO, view_size), Color(0, 0, 0, 0.65))
	help_panel.z_index = 10
	var content := _panel(Rect2((view_size - Vector2(812, 610)) / 2.0, Vector2(812, 610)), Color("152027"), help_panel)
	_label("common.ui.help_title", Rect2(30, 20, 760, 40), 32, content)
	_label("common.ui.help_commands", Rect2(30, 65, 755, 390), 32, content)
	# La musica eredita la visibilità del pannello, con una riga dedicata sopra gli altri comandi.
	music_button = _button("common.ui.music_on", Rect2(30, 480, 200, 42), _toggle_music, content)
	music_button.toggle_mode = true
	music_button.button_pressed = true
	# La lingua corrente resta visibile accanto alla musica e cambia senza chiudere gli aiuti.
	language_button = _button("common.ui.language", Rect2(250, 480, 300, 42), _toggle_language, content)
	var save := _button("common.ui.save", Rect2(30, 540, 145, 42), func():
		save_requested.emit()
		_toggle_help(), content)
	var load_button := _button("common.ui.load", Rect2(185, 540, 145, 42), func():
		load_requested.emit()
		_toggle_help(), content)
	reset_button = _button("common.ui.restart", Rect2(340, 540, 180, 42), new_game_requested.emit, content)
	help_close = _button("common.ui.resume", Rect2(530, 540, 250, 42), _toggle_help, content)
	save_buttons.append(save)
	save_buttons.append(load_button)
	help_panel.hide()

## Apre o chiude il menu dei comandi, eliminando eventuali scelte contestuali aperte.
## Comunica la pausa al coordinatore quando si apre o si chiude il pannello.
func _toggle_help() -> void:
	action_menu.hide()
	help_panel.visible = not help_panel.visible
	if help_panel.visible:
		menu_toggled.emit(true)
	else:
		menu_toggled.emit(false)

## Aggiorna la battuta con speaker esplicito come primo parametro e testo traducibile come secondo.
func say(speaker_key: String, value: String) -> void:
	speech_label.text = value
	_speaker_key = speaker_key
	speaker_label.text = texts.text(_speaker_key).to_upper()
	# Allarga il riquadro mantenendo il carattere fisso; al limite del viewport cresce anche in altezza.
	var font := speech_label.get_theme_font("font")
	var width := SPEECH_SIZE.x
	var max_width := maxf(SPEECH_SIZE.x, world_panel.size.x - 16.0)
	var measured := font.get_multiline_string_size(value, HORIZONTAL_ALIGNMENT_CENTER, width, SPEECH_FONT_SIZE)
	while measured.y > SPEECH_SIZE.y and width < max_width:
		width = minf(width + 20.0, max_width)
		measured = font.get_multiline_string_size(value, HORIZONTAL_ALIGNMENT_CENTER, width, SPEECH_FONT_SIZE)
	speech_label.size = Vector2(width, maxf(SPEECH_SIZE.y, ceilf(measured.y)))

## Converte il punto sopra chi parla nelle coordinate della UI, anche con stanze scalate e scorrevoli.
func position_speech(target: Node2D, local_anchor: Vector2) -> void:
	speech_label.visible = is_instance_valid(target) and target.is_visible_in_tree()
	if not speech_label.visible:
		return
	var anchor := get_global_transform().affine_inverse() * target.to_global(local_anchor)
	# Lascia 6 pixel UI tra il punto di ancoraggio e il testo del dialogo.
	speech_label.position = anchor - Vector2(speech_label.size.x / 2.0, speech_label.size.y + 20.0)
	# Mantiene leggibili le battute anche quando chi parla si trova vicino ai bordi laterali.
	speech_label.position.x = clampf(speech_label.position.x, 8.0, world_panel.size.x - speech_label.size.x - 8.0)

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
		var button := _inventory_button(definition.icon)
		# Riserva un pannello 52×52 a scala 2×, mantenendo l'icona centrata.
		button.custom_minimum_size = Vector2(104, 104)
		# Disegna la cornice dietro l'icona, senza intercettare i clic o cambiare le dimensioni dello slot.
		var frame := TextureRect.new()
		frame.name = "InventoryFrame"
		frame.show_behind_parent = true
		frame.texture = INVENTORY_FRAME_SELECTED if item == _selected else _inventory_frame_gray
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(frame)
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.pressed.connect(func(): inventory_pressed.emit(item, button))
		button.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				item_examined.emit(item))
		inventory_row.add_child(button)
		_inventory_buttons.append(button)

## Aggiorna cornice, colore del focus e scorrimento quando cambiano selezione o pulsanti.
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
		# La selezione usa V9; il colore dorato continua a indicare il focus da tastiera.
		var frame := button.get_node("InventoryFrame") as TextureRect
		frame.texture = INVENTORY_FRAME_SELECTED if _inventory_ids[i] == selected else _inventory_frame_gray
		button.modulate = GOLD if is_focused else Color.WHITE
		if is_focused:
			inventory_scroll.ensure_control_visible(button)

## Impedisce di salvare o ricominciare a metà di una sequenza, lasciando accessibile il menu di pausa.
func lock_interactions(locked: bool) -> void:
	for button in save_buttons:
		button.disabled = locked
	reset_button.disabled = locked
	for button in _inventory_buttons:
		button.disabled = locked
