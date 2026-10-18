class_name PaperPlaque
extends Control
## A55 paper plaque (assets/ui/paper-v1/plaque.png) with a live title. The
## text sits on the optical centre of the cream card: the baseline is placed
## by the font's cap height so capitals are centred, not the whole line box.
var title=""
var ink=Color("182952")
var _art: Texture2D
var _font: Font

func art() -> Texture2D:
	if _art==null:
		# A57 (P40): the torn-paper banner with leaves when present.
		var p32="res://assets/ui/hud-p32/banner.png"
		_art=ArtTexture.load_texture(p32 if ResourceLoader.exists(p32) else "res://assets/ui/paper-v1/plaque.png")
	return _art

func _ready() -> void:
	_font=load(PetUI.MENU_FONT_PATH)
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_texture_rect(art(),Rect2(Vector2.ZERO,size),false)
	# Cream card inside the cardboard frame (measured on the plaque art).
	var card=Rect2(size.x*0.07,size.y*0.2,size.x*0.86,size.y*0.64)
	if art().resource_path.contains("hud-p32"): card=Rect2(size.x*0.19,size.y*0.14,size.x*0.62,size.y*0.57)
	var points=int(card.size.y*(0.62 if art().resource_path.contains("hud-p32") else 0.5))
	while points>12 and _font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,points).x>card.size.x*0.9: points-=1
	var width=_font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,points).x
	var cap=_font.get_ascent(points)*0.7
	var baseline=Vector2(card.get_center().x-width*0.5,card.get_center().y+cap*0.5)
	draw_string(_font,baseline,title,HORIZONTAL_ALIGNMENT_LEFT,-1,points,ink)
