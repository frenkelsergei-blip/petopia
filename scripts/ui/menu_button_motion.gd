extends Node
## Visual feedback never resizes the real native hitbox or moves its label.
var button: Button
var tween: Tween
var down=false

func _ready() -> void:
	button.mouse_entered.connect(func():
		if button.focus_mode!=Control.FOCUS_NONE and not button.disabled: button.grab_focus()
		refresh())
	button.mouse_exited.connect(refresh)
	button.focus_entered.connect(refresh)
	button.focus_exited.connect(refresh)
	button.button_down.connect(func(): down=true;refresh())
	button.button_up.connect(func(): down=false;refresh())

func refresh() -> void:
	if not is_inside_tree() or not button.is_inside_tree() or button.is_queued_for_deletion(): return
	if button.disabled: return
	var selected=button.has_focus() or button.is_hovered()
	var previous=button.get_theme_stylebox("normal")
	# Hover/focus keeps the button's own face (gold stays gold, cream stays
	# cream) and brightens it slightly, instead of swapping styles.
	if previous.get("piece")==null: return
	var next=PetUI.kit_style(previous.piece,previous.corner_px,Color(1.07,1.07,1.07) if selected else Color.WHITE)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: next.set_content_margin(side,previous.get_content_margin(side))
	button.add_theme_stylebox_override("normal",next)
	if not button.get_meta("animate_symbol",true): return
	var icon=button.get_node_or_null("Content/Symbol") as Control
	if icon==null: return
	if tween: tween.kill()
	var rest: Vector2=icon.get_meta("rest",icon.position)
	if button.get_meta("reduced_motion",false):
		icon.position=rest
		icon.scale=Vector2.ONE
		return
	icon.pivot_offset=icon.size/2
	tween=create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon,"position",rest,0.12)
	tween.tween_property(icon,"scale",Vector2.ONE*(0.96 if down else (1.05 if selected else 1.0)),0.16)
