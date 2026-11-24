extends Control
## Le stesse due aree cliccabili dell'originale, a scala intera 2× per preservare i pixel.
## Segnale ascoltato dal coordinatore; il menu non deve conoscere lo stato dell'enigma.
signal chosen(examine: bool)
# La TextureRect mostra l'immagine completa; i due Button ricevono i clic sopra le icone.
## Condivide il vocabolario della UI e conserva il tipo di azione per i tooltip.
var texts: RefCounted
var _interaction_kind := ""
var picture: TextureRect
var examine_button: Button
var interact_button: Button

## Costruisce immagine e due pulsanti sovrapposti, senza aggiungere nuove icone alla grafica originale.
## Il pannello misura 100×72: il PNG originale 50×36 viene mostrato a scala 2×.
func _ready() -> void:
	size = Vector2(100, 72)
	# Il livello assoluto resta sopra hover.png (z=2) e sotto il menu degli aiuti (z=10).
	z_as_relative = false
	z_index = 5
	# Il pannello consuma il clic: scegliere la lente non deve anche spostare Churchill sul fondale.
	mouse_filter = Control.MOUSE_FILTER_STOP
	picture = TextureRect.new()
	# Le dimensioni dipendono dal pannello, senza vincoli minimi imposti dalla texture.
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.size = size
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# L'immagine è decorativa. I clic devono raggiungere i due pulsanti che vengono aggiunti dopo.
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	examine_button = _choice(Vector2.ZERO, texts.text("common.ui.examine"), true)
	# Le aree originali erano 22×22, con la seconda spostata di 28 pixel: moltiplichiamo per 2.
	interact_button = _choice(Vector2(56, 0), texts.text("common.ui.interact"), false)
	hide()

## Crea un'area cliccabile trasparente sopra una delle due icone.
## Il pulsante non applica regole del gioco: emette chosen con true per la lente e false per l'altra azione.
func _choice(at: Vector2, caption: String, examine: bool) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.position = at
	button.size = Vector2(44, 44)
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

## Traduce anche un menu aperto, mantenendo la scelta mano, bocca o uscita.
func refresh_texts() -> void:
	examine_button.tooltip_text = texts.text("common.ui.examine")
	var key := "common.ui.interact" if _interaction_kind.is_empty() else "common.ui.interact_" + _interaction_kind
	interact_button.tooltip_text = texts.text(key)

## Mostra il menu accanto al punto at, espresso nelle coordinate del genitore.
## kind seleziona il PNG hand/mouth/exit e la chiave del suggerimento della seconda scelta.
func open(at: Vector2, kind: String) -> void:
	picture.texture = load("res://assets/graphics/ui/panel_%s.png" % kind)
	_interaction_kind = kind
	refresh_texts()
	# Il menu resta interamente dentro la finestra, anche vicino ai bordi e all'inventario.
	# L'offset colloca il piccolo cerchio inferiore in prossimità del bersaglio selezionato.
	var bounds: Vector2 = get_parent().size
	# Il cerchio si trova a 30 pixel nell'originale; arrotonda anche i centri trasformati della stanza.
	position = Vector2(clampf(at.x - size.x / 2.0, 12, bounds.x - size.x - 12), clampf(at.y - 60, 84, bounds.y - size.y - 12)).round()
	show()
