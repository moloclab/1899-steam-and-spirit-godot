extends Control
## Le stesse due aree cliccabili dell'originale, a scala 1.5× come gli oggetti della stanza.
## Segnale ascoltato dal coordinatore; il menu non deve conoscere lo stato dell'enigma.
signal chosen(examine: bool)
# La TextureRect mostra l'immagine completa; i due Button ricevono i clic sopra le icone.
var picture: TextureRect
var examine_button: Button
var interact_button: Button

## Costruisce immagine e due pulsanti sovrapposti, senza aggiungere nuove icone alla grafica originale.
## Il pannello misura 75×54: il GIF originale 50×36 viene mostrato a scala 1.5×.
func _ready() -> void:
	size = Vector2(75, 54)
	z_index = 5
	# Il pannello consuma il clic: scegliere la lente non deve anche spostare Churchill sul fondale.
	mouse_filter = Control.MOUSE_FILTER_STOP
	picture = TextureRect.new()
	picture.size = size
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# L'immagine è decorativa. I clic devono raggiungere i due pulsanti che vengono aggiunti dopo.
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	examine_button = _choice(Vector2.ZERO, "Esamina", true)
	# Le aree originali erano 22×22, con la seconda spostata di 28 pixel: moltiplichiamo per 1.5.
	interact_button = _choice(Vector2(42, 0), "Interagisci", false)
	hide()

## Crea un'area cliccabile trasparente sopra una delle due icone.
## Il pulsante non applica regole del gioco: emette chosen con true per la lente e false per l'altra azione.
func _choice(at: Vector2, caption: String, examine: bool) -> Button:
	var button := Button.new()
	button.position = at
	button.size = Vector2(33, 33)
	button.tooltip_text = caption
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	# Il passaggio del cursore lascia visibile solo la grafica originale delle scelte.
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	# Pressione e focus lascia visibile solo la grafica originale delle scelte.
	for style in ["pressed", "focus"]:
		button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	button.pressed.connect(func(): chosen.emit(examine))
	add_child(button)
	return button

## Mostra il menu accanto al punto at, espresso nelle coordinate del genitore.
## kind seleziona il PNG hand/mouth/exit; interaction è il suggerimento testuale della seconda scelta.
func open(at: Vector2, kind: String, interaction: String) -> void:
	picture.texture = load("res://assets/graphics/original/panel_%s.png" % kind)
	interact_button.tooltip_text = interaction
	# Il menu resta interamente dentro la finestra, anche vicino ai bordi e all'inventario.
	# L'offset colloca il piccolo cerchio inferiore in prossimità del bersaglio selezionato.
	position = Vector2(clampf(at.x - 37.5, 12, 1065), clampf(at.y - 45, 84, 654))
	show()
