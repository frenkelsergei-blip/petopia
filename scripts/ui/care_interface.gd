class_name CareInterface
extends Panel
## Native V03/V06/V07/V08/V09 screens over the same live room, rules and save.
var app: Control
var mode="home"
var logical_size=Vector2(1280,720)
var safe=Rect2(12,12,1256,696)
var signature=""
var content: Control
var room_view: TextureRect
var room_input: Control
var live_portrait: AtlasTexture
var details_canvas: Control
var meters: Dictionary={}
var numbers: Dictionary={}
var wallet_value: Label
var identity: Label
var stage_caption: Label
var feedback: Label
var action_buttons: Array[Button]=[]
var nav_buttons: Array[Button]=[]
var home_overlay=""
var care_button: Button
var menu_button: Button
var sheet: Control
## A55 P26: the room's four need chips (kept apart from the details meters).
var need_bars: Dictionary={}
var rest_button: Button
var pet_badge: Control
var selected_level=0
var draft_name=""
var name_input: LineEdit
var decorate_buttons: Array[Button]=[]
const NEEDS=[["fullness","Food","feed"],["happiness","Happy","happy"],["energy","Energy","energy"],["cleanliness","Clean","water"],["health","Health","health"],["bond","Bond","bond"]]
const TITLES={"games":"Mini games","home":"My Pet","details":"Your companion","map":"Adventures","shop":"Shop & Bag","decorate":"Decorate","collection":"Collection","pause":"Pause & Settings","result":"Adventure complete!","minigame_result":"Lovely time together"}

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	if not app.game.state.is_empty(): draft_name=app.game.pet().name
	app.game.changed.connect(refresh)
	layout(Vector2(get_window().content_scale_size),Rect2(12,12,1256,696))

func open(value: String) -> void:
	if value!="home" and is_instance_valid(app.home): app.home.cancel_care()
	mode=value
	home_overlay=""
	signature=""
	layout(logical_size,safe)

func _process(_delta: float) -> void:
	refresh()

func layout(dimensions: Vector2, bounds: Rect2) -> void:
	logical_size=dimensions
	safe=bounds
	var next=str([dimensions,bounds,mode,home_overlay])
	if next==signature: return
	signature=next
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	meters.clear()
	numbers.clear()
	action_buttons.clear()
	nav_buttons.clear()
	decorate_buttons.clear()
	identity=null
	stage_caption=null
	name_input=null
	care_button=null
	menu_button=null
	rest_button=null
	pet_badge=null
	feedback=null
	live_portrait=null
	details_canvas=null
	content=Control.new()
	content.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(content)
	content.size=dimensions
	# A48: the Care drawer and Menu sit over the sharp live room (concept),
	# so Foxy and the child stay visible while choosing; full pages still blur.
	if mode in ["details","map","shop","collection","games","pause","bag","world_bag","world_map"]:
		var backdrop=ModalBackdrop.new()
		content.add_child(backdrop)
		backdrop.configure(app.viewport.get_texture(),dimensions)
		room_view=backdrop
	else:
		room_view=TextureRect.new()
		room_view.texture=app.viewport.get_texture()
		room_view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		room_view.mouse_filter=Control.MOUSE_FILTER_IGNORE
		room_view.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		room_view.size=dimensions
		content.add_child(room_view)
	if is_instance_valid(app.home) and mode not in ["result","minigame_result"]:
		var room_size=Vector2(390,390*dimensions.y/dimensions.x) if dimensions.x<dimensions.y else Vector2(360*dimensions.x/dimensions.y,360)
		app.viewport.get_parent().stretch=false
		WorldRender.configure(app.viewport,Vector2i(room_size))
		app.home.layout_room(room_size)
		if mode!="pause": app.world.transform=Transform2D.IDENTITY
	room_input=Control.new()
	room_input.size=dimensions
	room_input.mouse_filter=Control.MOUSE_FILTER_STOP
	room_input.gui_input.connect(room_event)
	content.add_child(room_input)
	if mode=="pause":
		build_pause()
	elif mode=="settings":
		build_settings()
	elif mode=="bag":
		build_bag()
	elif mode=="world_bag":
		build_world_bag()
	elif mode=="world_map":
		build_world_map()
	elif mode in ["result","minigame_result"]:
		build_result()
	else:
		if mode not in ["details","shop"] and not (mode=="home" and ArtStyle.paper) and not (mode in ["games","collection"] and ArtStyle.paper) and not (mode=="decorate" and ArtStyle.paper and is_instance_valid(app.home) and app.home.p43) and not (mode=="map" and ArtStyle.paper and ResourceLoader.exists("res://assets/ui/map-p32/map.png")): build_header()
		match mode:
			"home": build_paper_home() if ArtStyle.paper else build_home()
			"details": build_details()
			"map": build_map()
			"shop": build_shop()
			"decorate": build_decorate()
			"collection": build_collection()
			"games": build_games()
	if mode not in ["pause","settings","bag","world_bag","world_map","result","minigame_result"] and home_overlay=="menu":
		if ArtStyle.paper: build_paper_navigation()
		else: build_navigation()
	if not notice_data.is_empty(): build_notice()
	refresh()

func portrait() -> bool: return logical_size.x<logical_size.y
func compact() -> bool: return logical_size.y<600 and not portrait()
func text(parent: Node, caption: String, rect: Rect2, points=22) -> Label:
	return CareArt.title(parent,caption,rect,points)
func button(parent: Node, caption: String, rect: Rect2, callback: Callable, icon="", primary=false, layout="") -> Button:
	return CareArt.button(parent,caption,rect,callback,icon,primary,layout)
func frame(parent: Node, rect: Rect2) -> Panel: return CareArt.frame(parent,rect)
func picture(parent: Node, path: String, rect: Rect2, cover=false) -> TextureRect:
	var image=TextureRect.new()
	image.texture=ArtTexture.load_texture(path)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.position=rect.position
	image.size=rect.size
	parent.add_child(image)
	return image
func fox_portrait(parent: Node, rect: Rect2) -> TextureRect:
	if ArtStyle.paper: return picture(parent,"res://assets/ui/details-paper/stage_"+app.game.pet().get("growth_stage","baby")+".png",rect)
	var image=picture(parent,"res://assets/ui/adoption-v1/foxy.png",rect)
	var atlas=AtlasTexture.new()
	atlas.atlas=image.texture
	atlas.region=Rect2(220,180,860,900)
	atlas.filter_clip=true
	image.texture=atlas
	return image

func build_wallet(rect: Rect2) -> void:
	var panel=frame(content,rect)
	PetUI.set_piece(panel,"wallet")
	PetUI.compose(panel,"0",ArtTexture.load_texture(PetUI.COIN_PATH),"left",28)
	panel.get_node("Content/Symbol").name="CoinIcon"
	wallet_value=panel.get_node("Content/Caption")
	if mode=="home": app.coin_label=wallet_value

func tab(caption: String, icon: String, rect: Rect2, callback: Callable, selected=false) -> void:
	var b=button(content,caption,rect,callback,icon,selected,"tile" if portrait() else "row")
	b.tooltip_text=caption
	nav_buttons.append(b)

func build_header() -> void:
	var parts: Dictionary
	if mode=="home":
		parts=CareArt.header(content,safe,"",Callable(),"menu",func(): toggle_overlay("menu"))
		# Home has no back: the wallet sits on the left, the menu square on the right.
		parts.wallet.position.x=safe.position.x
	else:
		parts=CareArt.header(content,safe,TITLES.get(mode,"My Pet"),app.show_home,"menu",func(): toggle_overlay("menu"))
		parts.back.tooltip_text="Back to My Pet"
	menu_button=parts.square
	menu_button.name="HomeMenu"
	wallet_value=parts.wallet_label
	if mode=="home": app.coin_label=wallet_value

## One-off explanation card over the room (e.g. why Foxy can't go out).
## Kept across re-layouts until dismissed.
var notice_data: Array=[]
func notice(title: String, body: String) -> void:
	notice_data=[title,body]
	signature=""
	layout(logical_size,safe)
func build_notice() -> void:
	var w=minf(420,safe.size.x)
	var card=CareArt.panel(content,Rect2(safe.get_center().x-w*0.5,safe.position.y+PetUI.H_HEADER+24,w,200))
	card.name="Notice"
	CareArt.picture(card,"paw",Rect2(24,28,48,48))
	var heading=text(card,notice_data[0],Rect2(84,20,w-104,36),24)
	heading.autowrap_mode=TextServer.AUTOWRAP_OFF
	text(card,notice_data[1],Rect2(84,56,w-104,76),17)
	var ok=button(card,"Got it",Rect2(w-160,200-PetUI.H_BUTTON-18,136,PetUI.H_BUTTON),func(): notice_data=[];signature="";layout(logical_size,safe),"",true)
	ok.name="GotIt"

func toggle_overlay(value: String) -> void:
	if value=="care" and is_instance_valid(app.home) and app.home.busy(): return
	if value=="menu" and is_instance_valid(app.home): app.home.cancel_care()
	home_overlay="" if home_overlay==value else value
	signature=""
	layout(logical_size,safe)

func close_overlay() -> void:
	home_overlay=""
	signature=""
	layout(logical_size,safe)

func handle_back() -> bool:
	if home_overlay.is_empty(): return false
	close_overlay()
	return true

func sheet_frame(rect: Rect2, caption: String) -> Panel:
	var panel=CareArt.panel(content,rect)
	panel.name="CareDrawer" if home_overlay=="care" else "NavigationMenu"
	# Concept drawer: centred title between paw ornaments, close at the right.
	var title=text(panel,caption,Rect2(64,12,rect.size.x-128,48),PetUI.F_TITLE-2)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode=TextServer.AUTOWRAP_OFF
	var font: Font=title.get_theme_font("font")
	var width=minf(font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,PetUI.F_TITLE-2).x,rect.size.x-128)
	for side in [-1,1]:
		picture(panel,"res://assets/ui/concept-v1/paw-ornament.png",Rect2(rect.size.x/2+side*(width/2+20)-11,25,22,22))
	var close=CareArt.square(panel,"close",Rect2(rect.size.x-60,12,48,48),close_overlay)
	close.name="CloseSheet"
	close.tooltip_text="Close"
	return panel

func care_bounds() -> Rect2:
	var width=minf(430,safe.size.x)
	var height=304.0
	if portrait(): return Rect2(safe.get_center().x-width/2,safe.end.y-height,width,height)
	width=minf(430,safe.size.x*.51)
	height=minf(304,safe.size.y-78)
	return Rect2(safe.end.x-width,safe.end.y-height,width,height)

func build_navigation() -> void:
	var width=minf(460,safe.size.x)
	var height=minf(354,safe.size.y)
	sheet=sheet_frame(Rect2(safe.get_center()-Vector2(width,height)/2,Vector2(width,height)),"Menu")
	var rows=[["Details","paw",app.show_details],["Adventures","map",app.show_map],["Shop","shop",app.show_shop],["Decorate","decorate",app.show_decorate],["Collection","bond",app.show_collection],["Mini games","ball",app.show_minigames],["Settings","gear",app.toggle_pause],["Main menu","back",app.show_menu]]
	var column_width=(width-48)/2
	var top=72.0
	var row_height=PetUI.H_BUTTON
	for i in range(rows.size()):
		var entry=rows[i]
		var b=button(sheet,entry[0],Rect2(18+(i%2)*(column_width+12),top+int(i/2)*(row_height+8),column_width,row_height),func(): close_overlay();entry[2].call(),entry[1])
		b.name=entry[0].to_pascal_case()
		(b.get_meta("compose") as Dictionary).points=PetUI.F_BUTTON
		nav_buttons.append(b)
	PetUI.unify(nav_buttons)

func needs_panel(parent: Node, rect: Rect2, two_columns=false, numeric=false) -> void:
	var panel=frame(parent,rect)
	two_columns=two_columns or (rect.size.y<260 and not numeric)
	var cols=2 if two_columns else 1
	var rows=3 if two_columns else 6
	var heading=0.0 if two_columns else 40.0
	if not two_columns: text(panel,app.game.pet().name+"’s Care",Rect2(18,10,rect.size.x-36,30),23)
	var row_h=(rect.size.y-heading-24)/rows
	for i in range(NEEDS.size()):
		var entry=NEEDS[i]
		var width=(rect.size.x-28-(8 if cols==2 else 0))/cols
		var pos=Vector2(14+(i%cols)*(width+8),12+heading+int(i/cols)*row_h)
		var small=row_h<45 or cols==2
		CareArt.picture(panel,entry[2],Rect2(pos,Vector2.ONE*(22 if small else 32)))
		text(panel,entry[1],Rect2(pos+Vector2(30 if small else 42,0),Vector2(width-32 if small else width-48,22 if small else 30)),14 if small else 18)
		var meter=CareArt.meter(panel,pos+Vector2(30 if small else 42,24 if small else 30),width-(36 if small else 50),entry[0],12 if small else 18)
		meters[entry[0]]=meter
		if entry[0]!="bond": app.bars[entry[0]]=meter
		if numeric:
			numbers[entry[0]]=text(panel,"",Rect2(pos+Vector2(width-50,0),Vector2(50,24)),18)

func build_home() -> void:
	# Selected A44: quiet room is one state; its Care button opens the drawer.
	var width=minf(260,safe.size.x)
	var y=minf(logical_size.y*.80,safe.end.y-PetUI.H_PRIMARY)
	if not portrait(): y=safe.end.y-PetUI.H_PRIMARY-8
	care_button=button(content,"Care for "+app.game.pet().name,Rect2(safe.get_center().x-width/2,y,width,PetUI.H_PRIMARY),func(): toggle_overlay("care"),"paw",true)
	care_button.name="CareForPet"
	care_button.tooltip_text="Feed, drinking water, wash, pet, play and rest"
	pet_badge=CareArt.name_badge(content,app.game.pet().name,Vector2.ZERO)
	identity=pet_badge.get_node("Panel/Caption") if pet_badge.has_node("Panel/Caption") else pet_badge.find_child("Caption",true,false)
	feedback=centered(content,"",Rect2(safe.get_center().x-minf(340,safe.size.x)/2,safe.position.y+76 if compact() else y-40,minf(340,safe.size.x),30),16)
	if home_overlay.is_empty(): return
	care_button.visible=false
	pet_badge.visible=false
	feedback.visible=false
	if home_overlay=="food":
		build_food_picker()
		return
	if home_overlay!="care": return
	var bounds=care_bounds()
	sheet=sheet_frame(bounds,"Care for "+app.game.pet().name)
	var row_height=(bounds.size.y-90)/2
	var tile_width=(bounds.size.x-56)/3
	var entries=[["Feed","feed","feed"],["Water","drink","water"],["Clean","clean","clean"],["Pet","paw","pet"],["Play","ball","play"],["Rest","rest","sleep"]]
	for i in range(entries.size()):
		var entry=entries[i]
		var b=button(sheet,entry[0],Rect2(18+(i%3)*(tile_width+10),72+int(i/3)*(row_height+8),tile_width,row_height),func(): choose_care(entry[2]),entry[1],false,"tile")
		b.name=entry[0]
		b.tooltip_text="Drinking water in a bowl" if entry[2]=="water" else entry[0]
		action_buttons.append(b)
		if entry[2]=="sleep": rest_button=b
	PetUI.unify(action_buttons)
	# Reframe the whole real room, not individual props or a pasted screenshot.
	var home=app.home
	if portrait():
		var target=(bounds.position.y-36)/logical_size.y*home.room_size.y
		app.world.position=Vector2(0,minf(0,target-home.floor_y))
	else:
		var zoom=1.35
		var factor=logical_size.y/360.0
		var target=(bounds.position.x-78)/factor
		var offset=clampf(target-home.pet_center*zoom,-(zoom-1)*home.room_size.x,0)
		app.world.transform=Transform2D(0,Vector2.ONE*zoom,0,Vector2(offset,home.floor_y*(1-zoom)))

## --- A55 My Pet room interface from concept P26 (assets/ui/roomui-paper) ---
const RK="roomui-paper"
## Concept scale for the room UI: concept pixels to screen, never so small that
## a round button drops under 48 px.
func pk() -> float:
	var k=minf(safe.size.x/1672.0,safe.size.y/941.0)
	if portrait(): k=safe.size.x/860.0
	return maxf(k,48.0/105.0)
## Concept rects anchored to a screen edge: "tl", "tr", "bc" (bottom centre).
func prect(anchor: String, x: float, y: float, w: float, h: float) -> Rect2:
	var k=pk()
	match anchor:
		"tr": return Rect2(safe.end.x-(1672.0-x)*k,safe.position.y+y*k,w*k,h*k)
		"bc": return Rect2(safe.get_center().x+(x-836.0)*k,safe.end.y-(941.0-y)*k,w*k,h*k)
		"c": return Rect2(safe.get_center().x+(x-836.0)*k,safe.get_center().y+(y-470.0)*k,w*k,h*k)
		_: return Rect2(safe.position.x+x*k,safe.position.y+y*k,w*k,h*k)
func ptex(kit: String, name: String) -> Texture2D: return ConceptScreen.tex(kit,name)

## A57 (P43): the room UI from concept P43 (roomui-p32 kit).
const R43="roomui-p32"
func p43() -> bool: return ArtStyle.paper and ResourceLoader.exists("res://assets/ui/roomui-p32/board.png")
func p43_top() -> void:
	var pet=app.game.pet()
	var k=pk()
	var st=prect("tl",20,24,476,228)
	if portrait():
		var room_w=prect("tr",1355,24,290,84).position.x-safe.position.x-8.0
		st=Rect2(st.position,Vector2(room_w,room_w*228.0/476.0))
	var u=st.size.x/476.0
	var A=func(x: float,y: float,w: float,h: float) -> Rect2: return Rect2(st.position+Vector2(x,y)*u,Vector2(w,h)*u)
	ConceptScreen.piece(content,R43,"status",st,false)
	ConceptScreen.piece(content,R43,"portrait",A.call(14,20,152,152)).name="StatusFace"
	identity=ConceptScreen.words(content,pet.name+" · "+pet.growth_stage.capitalize(),A.call(184,12,280,58),int(40*u),PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)
	var needs=[["fullness","Food","ic_food","fill_green"],["energy","Energy","ic_energy","fill_navy"],["cleanliness","Clean","ic_clean","fill_blue"],["happiness","Happy","ic_happy","fill_yellow"]]
	for i in needs.size():
		var y=80.0+i*38.0
		ConceptScreen.piece(content,R43,needs[i][2],A.call(188,y-15,32,30))
		ConceptScreen.words(content,needs[i][1],A.call(228,y-17,84,34),int(24*u),PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)
		var bar=ConceptScreen.meter(content,A.call(306,y-12,152,24),ptex(R43,needs[i][3]))
		bar.add_theme_stylebox_override("background",p43_track())
		bar.name="Need_"+needs[i][0]
		need_bars[needs[i][0]]=bar
	var cp=prect("tr",1355,26,188,78)
	var coins=Control.new()
	coins.name="Wallet"
	coins.position=cp.position
	coins.size=cp.size
	coins.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(coins)
	ConceptScreen.piece(coins,R43,"coins",Rect2(Vector2.ZERO,cp.size),false)
	# The canonical coin sits on the pill's own coin (same resource as the world).
	var coin_icon=ConceptScreen.piece(coins,R43,"coins",Rect2(0,cp.size.y*0.03,cp.size.y*0.96,cp.size.y*0.96))
	coin_icon.name="CoinIcon"
	coin_icon.texture=ArtTexture.load_texture(PetUI.COIN_PATH)
	wallet_value=ConceptScreen.words(coins,str(app.game.state.coins),Rect2(cp.size.x*0.44,0,cp.size.x*0.5,cp.size.y),int(44*k))
	app.coin_label=wallet_value
	menu_button=ConceptScreen.button(content,"HomeMenu",R43,"menu",prect("tr",1560,20,88,88),func(): toggle_overlay("menu"))
	menu_button.tooltip_text="Menu"
func p43_track() -> StyleBoxTexture:
	var t=StyleBoxTexture.new()
	t.texture=ptex(R43,"track")
	t.texture_margin_left=t.texture.get_height()*0.5
	t.texture_margin_right=t.texture.get_height()*0.5
	return t
## Landscape: the Care board sits on the right as in P43 and the room slides
## so the explorer and Foxy stay in view on the left.
func p43_board(title: String, cols: int, rows: int, make: Callable) -> Rect2:
	var k=pk()
	if portrait():
		k=safe.size.x/760.0
	var tw=196.0
	var th=208.0
	var gx=17.0
	var gy=18.0
	var w=cols*tw+(cols-1)*gx+84.0
	var h=110.0+rows*th+(rows-1)*gy+130.0
	var bounds=Rect2(safe.end.x-(w+40.0)*k,safe.position.y+(175.0 if rows<=2 else 110.0)*k,w*k,h*k)
	if portrait(): bounds=Rect2(safe.get_center().x-w*k*0.5,safe.end.y-h*k-6,w*k,h*k)
	if bounds.end.y>safe.end.y: bounds.position.y=safe.end.y-bounds.size.y
	sheet=Control.new()
	sheet.name="CareDrawer" if home_overlay in ["care","food"] else "NavigationMenu"
	sheet.position=bounds.position
	sheet.size=bounds.size
	content.add_child(sheet)
	ConceptScreen.piece(sheet,R43,"board",Rect2(Vector2.ZERO,bounds.size),false)
	var tp=Rect2(bounds.size.x*0.5-165.0*k,-34.0*k,330.0*k,96.0*k)
	ConceptScreen.piece(sheet,R43,"board_title",tp,false)
	ConceptScreen.words(sheet,title,tp.grow_individual(-tp.size.x*0.1,0,-tp.size.x*0.1,0),int(58*k))
	var close=ConceptScreen.button(sheet,"CloseSheet",R43,"close",Rect2(bounds.size.x-86.0*k,8.0*k,70.0*k,70.0*k),close_overlay)
	close.tooltip_text="Close"
	for i in cols*rows:
		make.call(i,Rect2((42.0+(i%cols)*(tw+gx))*k,(88.0+int(i/cols)*(th+gy))*k,tw*k,th*k))
	var plank=ConceptScreen.button(sheet,"CareDone",R43,"care_plank",Rect2(66.0*k,bounds.size.y-118.0*k,bounds.size.x-132.0*k,92.0*k),close_overlay,"Care for "+app.game.pet().name,null,int(48*k),Color("fff6e0"))
	plank.tooltip_text="Done"
	return bounds
func p43_tile(name: String, rect: Rect2, callback: Callable, caption: String, icon: Texture2D) -> Button:
	var b=ConceptScreen.button(sheet,name,R43,"tile",rect,callback)
	b.tooltip_text=caption
	b.text=caption
	var box: Control=b.get_node("Content")
	var s=minf(rect.size.x*0.78,rect.size.y*0.56)
	var ic=TextureRect.new()
	ic.name="Symbol"
	ic.texture=icon
	ic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ic.position=Vector2((rect.size.x-s)*0.5,rect.size.y*0.1)
	ic.size=Vector2(s,s)
	box.add_child(ic)
	ConceptScreen.words(box,caption,Rect2(rect.size.x*0.06,rect.size.y*0.68,rect.size.x*0.88,rect.size.y*0.24),int(rect.size.y*0.18))
	return b
func p43_reframe(bounds: Rect2) -> void:
	if portrait():
		paper_reframe(bounds)
		return
	var home=app.home
	var W=home.room_size.x
	var H=home.room_size.y
	# The pair moves to the middle of the free space left of the board; zoom
	# in just enough that the room still fills the screen while it slides.
	var target=bounds.position.x*0.5/logical_size.x*W
	var pair=(home.pet_center+home.explorer.position.x)*0.5
	var z=clampf((W-target)/maxf(1.0,W-pair),1.04,1.3)
	var ox=clampf(target-z*pair,W*(1.0-z),0.0)
	app.world.transform=Transform2D(0,Vector2.ONE*z,0,Vector2(ox,H*(1.0-z)))

func build_paper_home() -> void:
	var pet=app.game.pet()
	var k=pk()
	if p43():
		p43_top()
		care_button=ConceptScreen.button(content,"CareForPet",R43,"care_plank",prect("bc",560,830,552,92),func(): toggle_overlay("care"),"Care for "+pet.name,null,int(48*k),Color("fff6e0"))
		care_button.tooltip_text="Feed, drinking water, wash, pet, play and rest"
		feedback=centered(content,"",Rect2(safe.get_center().x-minf(340,safe.size.x)/2,care_button.position.y-34,minf(340,safe.size.x),30),16)
		pet_badge=null
		if home_overlay.is_empty(): return
		care_button.visible=false
		feedback.visible=false
		if home_overlay=="food":
			build_paper_food()
			return
		if home_overlay!="care": return
		var tiles43=[["Feed","big_feed","feed"],["Water","big_water","water"],["Bath","big_bath","clean"],["Pet","big_pet","pet"],["Rest","big_rest","sleep"],["Play","big_play","play"]]
		var b43=p43_board("CARE",3,2,func(i: int, rect: Rect2):
			var e=tiles43[i]
			var b=p43_tile("Clean" if e[0]=="Bath" else e[0],rect,func(): choose_care(e[2]),e[0],ptex(R43,e[1]))
			b.tooltip_text="Drinking water in a bowl" if e[2]=="water" else e[0]
			action_buttons.append(b)
			if e[2]=="sleep": rest_button=b)
		p43_reframe(b43)
		return
	# Status plaque: Foxy's portrait in its round window, name and age.
	var st=prect("tl",40,12,420,157)
	if portrait():
		# Phone upright: the plaque takes what the coins and menu leave.
		var room_w=prect("tr",1262,24,256,112).position.x-safe.position.x-6.0
		st=Rect2(st.position,Vector2(room_w,room_w*157.0/420.0))
	ConceptScreen.piece(content,RK,"status",st,false)
	var face=ConceptScreen.piece(content,"details-paper","stage_"+pet.growth_stage,Rect2(st.position+Vector2(st.size.y*0.13,st.size.y*0.16),Vector2(st.size.y*0.72,st.size.y*0.66)))
	face.name="StatusFace"
	identity=ConceptScreen.words(content,pet.name+" · "+pet.growth_stage.capitalize(),Rect2(st.position.x+st.size.x*0.36,st.position.y,st.size.x*0.58,st.size.y),int(56*k))
	# Four need chips; portrait puts them in their own row under the plaque.
	var needs=[["fullness","Food","need_food"],["energy","Energy","need_energy"],["cleanliness","Clean","need_clean"],["happiness","Happy","need_happy"]]
	for i in needs.size():
		var r=prect("tl",490+i*180,40,170,80)
		if portrait(): r=Rect2(safe.position.x+i*(safe.size.x/4.0),st.end.y+6,safe.size.x/4.0-6,80*k)
		ConceptScreen.piece(content,RK,"meter_chip",r,false)
		ConceptScreen.piece(content,RK,needs[i][2],Rect2(r.position+Vector2(r.size.x*0.06,r.size.y*0.15),Vector2(r.size.y*0.7,r.size.y*0.7)))
		ConceptScreen.words(content,needs[i][1],Rect2(r.position.x+r.size.x*0.4,r.position.y+r.size.y*0.08,r.size.x*0.55,r.size.y*0.42),int(26*k))
		var bar=ConceptScreen.meter(content,Rect2(r.position.x+r.size.x*0.42,r.position.y+r.size.y*0.56,r.size.x*0.5,r.size.y*0.24),ptex(RK,"meter_track"),PetUI.NEED_COLORS.get(needs[i][0],Color.WHITE).lightened(0.25))
		bar.name="Need_"+needs[i][0]
		need_bars[needs[i][0]]=bar
	# Coins and the menu.
	var cp=prect("tr",1262,24,256,112)
	var coins=Control.new()
	coins.name="Wallet"
	coins.position=cp.position
	coins.size=cp.size
	coins.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(coins)
	ConceptScreen.piece(coins,"map-paper","coin_plaque",Rect2(Vector2.ZERO,cp.size),false)
	# The canonical coin (A55: PetUI.COIN_PATH resolves to the paper coin).
	var coin_icon=ConceptScreen.piece(coins,"result-paper","coin",Rect2(cp.size.x*0.08,cp.size.y*0.14,cp.size.y*0.72,cp.size.y*0.72))
	coin_icon.name="CoinIcon"
	coin_icon.texture=ArtTexture.load_texture(PetUI.COIN_PATH)
	wallet_value=ConceptScreen.words(coins,str(app.game.state.coins),Rect2(cp.size.x*0.42,0,cp.size.x*0.5,cp.size.y),int(64*k))
	app.coin_label=wallet_value
	menu_button=ConceptScreen.button(content,"HomeMenu",RK,"menu_button",prect("tr",1535,22,112,114),func(): toggle_overlay("menu"))
	menu_button.tooltip_text="Menu"
	# Care for Foxy.
	care_button=ConceptScreen.button(content,"CareForPet",RK,"care_button",prect("bc",625,818,425,96),func(): toggle_overlay("care"),"Care for "+pet.name,ptex(RK,"ic_paw"),int(44*k))
	care_button.tooltip_text="Feed, drinking water, wash, pet, play and rest"
	feedback=centered(content,"",Rect2(safe.get_center().x-minf(340,safe.size.x)/2,care_button.position.y-34,minf(340,safe.size.x),30),16)
	pet_badge=null
	if home_overlay.is_empty(): return
	care_button.visible=false
	feedback.visible=false
	if home_overlay=="food":
		build_paper_food()
		return
	if home_overlay!="care": return
	var tiles=[["Feed","ic_feed","feed"],["Water","ic_water","water"],["Clean","ic_bath","clean"],["Pet","ic_pet","pet"],["Rest","ic_rest","sleep"],["Play","ic_play","play"]]
	var bounds=paper_board("Care",3,2,func(i: int, rect: Rect2):
		var e=tiles[i]
		var b=ConceptScreen.tile(sheet,e[0],RK,"tile",rect,func(): choose_care(e[2]),"Bath" if e[0]=="Clean" else e[0],ptex(RK,e[1]))
		b.tooltip_text="Drinking water in a bowl" if e[2]=="water" else e[0]
		action_buttons.append(b)
		if e[2]=="sleep": rest_button=b)
	paper_reframe(bounds)

## The P26 hanging board with its title plaque, close button and a grid of
## tiles at the concept's spacing. Returns the board rect.
func paper_board(title: String, cols: int, rows: int, make: Callable, extra_h=0.0) -> Rect2:
	var k=pk()
	var tw=200.0*k
	var th=125.0*k
	var gap=12.0*k
	var w=cols*tw+(cols-1)*gap+110.0*k
	var h=rows*th+(rows-1)*gap+150.0*k+extra_h
	var bottom=safe.end.y-8.0*k
	var bounds=Rect2(safe.get_center().x-w*0.5,bottom-h,w,h)
	sheet=Control.new()
	sheet.name="CareDrawer" if home_overlay in ["care","food"] else "NavigationMenu"
	sheet.position=bounds.position
	sheet.size=bounds.size
	content.add_child(sheet)
	ConceptScreen.piece(sheet,RK,"board",Rect2(Vector2(0,-70.0*k),Vector2(w,h+70.0*k)),false)
	var tp=Rect2(w*0.5-125.0*k,-8.0*k,250.0*k,66.0*k)
	ConceptScreen.piece(sheet,RK,"board_title",tp,false)
	ConceptScreen.words(sheet,title,tp.grow_individual(-tp.size.x*0.12,0,-tp.size.x*0.12,0),int(46*k))
	var close=ConceptScreen.button(sheet,"CloseSheet",RK,"close",Rect2(w-58.0*k,22.0*k,76.0*k,76.0*k),close_overlay)
	close.tooltip_text="Close"
	var x0=(w-(cols*tw+(cols-1)*gap))*0.5
	for i in cols*rows:
		make.call(i,Rect2(x0+(i%cols)*(tw+gap),70.0*k+int(i/cols)*(th+gap),tw,th))
	return bounds

## While a board is open the room camera rises and zooms so the pair stays in
## view above it (the floor line sits just over the board).
func paper_reframe(bounds: Rect2) -> void:
	var home=app.home
	var H=home.room_size.y
	var target=bounds.position.y/logical_size.y*H-12.0
	var z=maxf(1.0,(H-target)/maxf(1.0,H-home.floor_y))
	var oy=minf(0.0,target-z*home.floor_y)
	var ox=clampf(home.room_size.x*0.5-z*home.pet_center,home.room_size.x*(1.0-z),0.0)
	app.world.transform=Transform2D(0,Vector2.ONE*z,0,Vector2(ox,oy))

## A57 (P51): choose a food. Board, tiles, pills and food pictures from the
## food-p32 kit; Kibble is always free, foods you don't have point to the shop.
func p51_food() -> void:
	var data=GameState.foods()
	var ids: Array=data.order
	var art={"kibble":"kibble","berry_bowl":"berries","apple":"apple","fish_treat":"fish","honey_cookie":"cookie","carrot":"carrot"}
	var k=pk()
	if portrait(): k=safe.size.x/980.0
	var w=900.0*k
	var h=690.0*k
	var bounds=Rect2(safe.end.x-w-24*k,safe.position.y+130*k,w,h)
	if portrait(): bounds=Rect2(safe.get_center().x-w*0.5,safe.end.y-h-8,w,h)
	if bounds.end.y>safe.end.y: bounds.position.y=safe.end.y-h
	sheet=Control.new()
	sheet.name="CareDrawer"
	sheet.position=bounds.position
	sheet.size=bounds.size
	content.add_child(sheet)
	ConceptScreen.piece(sheet,"food-p32","board",Rect2(Vector2(0,40*k),Vector2(w,h-40*k)),false)
	var tp=Rect2(w*0.08,-20*k,w*0.82,128*k)
	ConceptScreen.piece(sheet,"food-p32","title",tp,false)
	ConceptScreen.words(sheet,"What should %s eat?"%app.game.pet().name,tp.grow_individual(-tp.size.x*0.1,-tp.size.y*0.16,-tp.size.x*0.1,-tp.size.y*0.2),int(56*k))
	var close=ConceptScreen.button(sheet,"CloseSheet","food-p32","close",Rect2(w-104*k,40*k,92*k,92*k),close_overlay)
	close.tooltip_text="Close"
	for i in ids.size():
		var id: String=ids[i]
		var f: Dictionary=data.foods[id]
		var count=app.game.food_count(id)
		var rect=Rect2((48+(i%3)*285)*k,(150+int(i/3)*290)*k,262*k,270*k)
		var have=count>0
		var b=ConceptScreen.button(sheet,"Food_"+id,"food-p32","tile" if have else "tile_off",rect,func():
			close_overlay()
			if not have: app.show_shop()
			elif is_instance_valid(app.home): app.home.request_food(id))
		b.tooltip_text=String(f.short) if have else "Buy in the shop"
		b.text=String(f.short)
		var pic=ConceptScreen.piece(b,"food-p32",art.get(id,"apple"),Rect2(rect.size.x*0.14,rect.size.y*0.06,rect.size.x*0.72,rect.size.y*0.48))
		if not have: pic.modulate=Color(1,1,1,0.6)
		ConceptScreen.words(b,String(f.short),Rect2(0,rect.size.y*0.56,rect.size.x,rect.size.y*0.16),int(40*k),PetUI.INK if have else Color("7a7a7a"))
		var pr=Rect2(rect.size.x*0.24,rect.size.y*0.74,rect.size.x*0.52,rect.size.y*0.17)
		if id=="kibble":
			ConceptScreen.piece(b,"food-p32","free",pr,false)
			ConceptScreen.words(b,"Free",pr,int(34*k),Color("fff6e0"))
		elif have:
			ConceptScreen.piece(b,"food-p32","count",pr,false)
			ConceptScreen.words(b,"x%d"%count,pr,int(34*k))
		else:
			# Not in the bag: a little coin pill that opens the shop.
			var sr=Rect2(rect.size.x*0.16,rect.size.y*0.74,rect.size.x*0.68,rect.size.y*0.18)
			ConceptScreen.piece(b,"food-p32","shop",sr,false)
			ConceptScreen.words(b,"Shop",Rect2(sr.position.x+sr.size.x*0.34,sr.position.y,sr.size.x*0.6,sr.size.y),int(32*k))
		if app.game.food_taste(id)=="like": ConceptScreen.piece(b,"food-p32","heart",Rect2(rect.size.x*0.74,rect.size.y*0.04,rect.size.x*0.17,rect.size.x*0.17))
	if portrait(): paper_reframe(bounds)
	else: p43_reframe(bounds)

func build_paper_food() -> void:
	if p43() and ResourceLoader.exists("res://assets/ui/food-p32/board.png"):
		p51_food()
		return
	var data=GameState.foods()
	var ids: Array=data.order
	var art={"kibble":"","berry_bowl":"berries","apple":"apple","fish_treat":"fish","honey_cookie":"cookie","carrot":"carrot"}
	var cols=3
	var rows=int(ceil(ids.size()/3.0))
	var k=pk()
	var bounds=paper_board("What should %s eat?"%app.game.pet().name,cols,rows,func(i: int, rect: Rect2):
		if i>=ids.size(): return
		var id: String=ids[i]
		var f: Dictionary=data.foods[id]
		var count=app.game.food_count(id)
		var icon: Texture2D=ptex(RK,"ic_feed") if art.get(id,"").is_empty() else ArtTexture.load_texture("res://assets/ui/bag-paper/items/%s.png"%art[id])
		var b=ConceptScreen.tile(sheet,"Food_"+id,RK,"tile",rect,func():
			close_overlay()
			if is_instance_valid(app.home): app.home.request_food(id),String(f.short),icon)
		b.disabled=count<1
		if count<1:
			b.modulate=Color(1,1,1,0.55)
			b.tooltip_text="Buy in the shop"
		if id!="kibble":
			var bs=38.0*k
			ConceptScreen.piece(b,"bag-paper","badge",Rect2(rect.size.x-bs-6*k,6*k,bs,bs),false)
			ConceptScreen.words(b,str(count),Rect2(rect.size.x-bs-6*k,6*k,bs,bs),int(22*k))
		if app.game.food_taste(id)=="like": ConceptScreen.piece(b,"result-paper","heart",Rect2(8*k,8*k,30*k,30*k)),70.0*k)
	var shop=ConceptScreen.button(sheet,"BuyFood",RK,"care_button",Rect2(bounds.size.x*0.5-170*k,bounds.size.y-82*k,340*k,70*k),func(): close_overlay();app.show_shop(),"Buy more food",ArtTexture.load_texture("res://assets/ui/shop-paper/coin.png"),int(30*k))
	paper_reframe(bounds)

## A57 (P50): the room menu, eight tiles with big paper icons (menu50-p32).
## The concept's Bag tile is Decorate at home (the bag belongs to adventures);
## its picture is the paw cushion from the shop kit.
func p50_navigation() -> void:
	var rows=[["Details","Details","menu50-p32","ic_details",app.show_details],["Adventures","Adventures","menu50-p32","ic_map",app.show_map],["Shop","Shop","menu50-p32","ic_shop",app.show_shop],["MiniGames","Games","menu50-p32","ic_games",app.show_minigames],
		["Collection","Collection","menu50-p32","ic_collection",app.show_collection],["Decorate","Decorate","shop-p32","cushion",app.show_decorate],["Settings","Settings","menu50-p32","ic_settings",app.toggle_pause],["MainMenu","Main menu","menu50-p32","ic_home",app.show_menu]]
	nav_buttons.clear()
	var cols=4 if not portrait() else 2
	var k=pk()
	if portrait(): k=safe.size.x/560.0
	var tw=235.0
	var th=238.0
	var gap=12.0
	var w=(cols*tw+(cols-1)*gap+80.0)*k
	var h=(130.0+(8/cols)*th+(8/cols-1)*gap+50.0)*k
	var bounds=Rect2(safe.end.x-w-30*k,safe.position.y+170*k,w,h)
	if portrait(): bounds=Rect2(safe.get_center().x-w*0.5,safe.end.y-h-8,w,h)
	if bounds.end.y>safe.end.y: bounds.position.y=safe.end.y-h
	sheet=Control.new()
	sheet.name="NavigationMenu"
	sheet.position=bounds.position
	sheet.size=bounds.size
	content.add_child(sheet)
	ConceptScreen.piece(sheet,"menu50-p32","board",Rect2(Vector2(0,60*k),Vector2(w,h-60*k)),false)
	var tp=Rect2(w*0.5-230*k,0,460*k,116*k)
	ConceptScreen.piece(sheet,"menu50-p32","title",tp,false)
	ConceptScreen.words(sheet,"Menu",tp.grow(-14*k),int(78*k))
	var close=ConceptScreen.button(sheet,"CloseSheet","menu50-p32","close",Rect2(w-100*k,64*k,90*k,90*k),close_overlay)
	close.tooltip_text="Close"
	for i in rows.size():
		var e=rows[i]
		var rect=Rect2((40+(i%cols)*(tw+gap))*k,(140+int(i/cols)*(th+gap))*k,tw*k,th*k)
		var b=ConceptScreen.button(sheet,e[0],"menu50-p32","tile",rect,func(): close_overlay();e[4].call())
		b.tooltip_text=e[1]
		b.text=e[1]
		ConceptScreen.piece(b,e[2],e[3],Rect2(rect.size.x*0.1,rect.size.y*0.08,rect.size.x*0.8,rect.size.y*0.56))
		ConceptScreen.words(b,e[1],Rect2(0,rect.size.y*0.68,rect.size.x,rect.size.y*0.22),int(40*k))
		nav_buttons.append(b)
	if portrait(): paper_reframe(bounds)
	else: p43_reframe(bounds)

func build_paper_navigation() -> void:
	if p43() and ResourceLoader.exists("res://assets/ui/menu50-p32/board.png"):
		p50_navigation()
		return
	var rows=[["Details","Details","res://assets/ui/roomui-paper/ic_paw.png",app.show_details],["Adventures","Adventures","res://assets/ui/menu-paper/ic_map.png",app.show_map],["Shop","Shop","res://assets/ui/result-paper/coin.png",app.show_shop],["Decorate","Decorate","res://assets/ui/shop-paper/armchair.png",app.show_decorate],
		["Collection","Collection","res://assets/ui/result-paper/heart.png",app.show_collection],["MiniGames","Mini games","res://assets/ui/ball-paper/ball.png",app.show_minigames],["Settings","Settings","res://assets/ui/menu-paper/ic_gear.png",app.toggle_pause],["MainMenu","Main menu","res://assets/ui/turn-paper/ic_house.png",app.show_menu]]
	nav_buttons.clear()
	var cols=4 if not portrait() else 2
	var bounds=paper_board("Menu",cols,8/cols,func(i: int, rect: Rect2):
		var e=rows[i]
		var b=ConceptScreen.tile(sheet,e[0],RK,"tile",rect,func(): close_overlay();e[3].call(),e[1],ArtTexture.load_texture(e[2]))
		nav_buttons.append(b))

func choose_care(value: String) -> void:
	if value=="feed":
		home_overlay="food"
		signature=""
		layout(logical_size,safe)
		return
	close_overlay()
	if value=="play": app.show_ball()
	else: request_care(value)

## A51: choose what Foxy eats. Kibble is always free; other foods come from
## the shop. Hearts mark favourites.
func build_food_picker() -> void:
	var bounds=care_bounds()
	bounds=Rect2(bounds.position.x,bounds.position.y-40,bounds.size.x,bounds.size.y+40)
	sheet=sheet_frame(bounds,"What should %s eat?"%app.game.pet().name)
	var data=GameState.foods()
	var ids: Array=data.order
	var cols=3
	var tile_w=(bounds.size.x-36-(cols-1)*10)/cols
	var tile_h=(bounds.size.y-72-60-8)/2
	var tiles=[]
	for i in range(ids.size()):
		var id: String=ids[i]
		var f: Dictionary=data.foods[id]
		var count=app.game.food_count(id)
		var caption=f.short
		var rect=Rect2(18+(i%cols)*(tile_w+10),72+int(i/cols)*(tile_h+8),tile_w,tile_h)
		var b=button(sheet,caption,rect,func(): close_overlay(); if is_instance_valid(app.home): app.home.request_food(id),"food_"+id,false,"tile")
		b.name="Food_"+id
		b.clip_text=true
		b.custom_minimum_size=Vector2.ZERO
		b.size=rect.size
		b.disabled=count<1
		if id!="kibble":
			var badge=CareArt.tag(b,"%d"%count,Rect2(6,6,30,24))
			badge.size=Vector2(30,24)
			(badge.get_meta("compose") as Dictionary).layout="row"
			(badge.get_meta("compose") as Dictionary).points=13
			PetUI.arrange(badge)
		if count<1: b.tooltip_text="Buy in the shop"
		var taste=app.game.food_taste(id)
		if taste=="like": CareArt.picture(b,"heart",Rect2(tile_w-26,6,20,20))
		tiles.append(b)
	PetUI.unify(tiles)
	var shop=button(sheet,"Buy more food",Rect2(18,bounds.size.y-60,bounds.size.x-36,PetUI.H_BUTTON-6),func(): close_overlay();app.show_shop(),"shop_stall")
	shop.name="BuyFood"

func request_care(value: String) -> void:
	if is_instance_valid(app.home): app.home.request_care(value)

func scroll_card(rect: Rect2) -> VBoxContainer:
	var panel=CareArt.panel(content,rect)
	var scroll=ScrollContainer.new()
	scroll.position=Vector2(18,18)
	scroll.size=rect.size-Vector2(36,36)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	# Drag/wheel scrolling stays; the bar itself is hidden so it never covers
	# the right edge of rows and cards (phone convention).
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
	panel.add_child(scroll)
	var column=VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",12)
	scroll.add_child(column)
	return column
func flow_label(parent: Node, value: String, points=20) -> Label:
	var label=text(parent,value,Rect2(0,0,0,0),points)
	label.custom_minimum_size=Vector2(0,32)
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return label
func flow_button(parent: Node, value: String, callback: Callable, kind="", primary=false) -> Button:
	if mode in ["pause","settings"] and p42():
		var qb=ConceptScreen.button(parent,value.to_pascal_case(),P42,"resume" if primary else "button",Rect2(0,0,300,56),callback,value,null,22,Color("fff6e0") if primary else PetUI.INK)
		qb.custom_minimum_size=Vector2(0,60)
		qb.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		qb.resized.connect(func():
			qb.get_node("Face").size=qb.size
			qb.get_node("Content").size=qb.size
			for l in qb.get_node("Content").get_children(): if l is Label: l.size.x=qb.size.x-l.position.x*2)
		return qb
	var h=PetUI.H_PRIMARY if primary else PetUI.H_BUTTON
	var b=button(parent,value,Rect2(0,0,100,h),callback,kind,primary)
	(b.get_meta("compose") as Dictionary).points=PetUI.F_BUTTON
	b.custom_minimum_size=Vector2(0,h)
	b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return b
func page_bounds() -> Rect2:
	var top=safe.position.y+PetUI.H_HEADER+12
	return Rect2(safe.position.x,top,safe.size.x,safe.end.y-top)

func growth_cards(parent: Node, rect: Rect2, columns: int) -> void:
	var gap=8.0
	var width=(rect.size.x-gap*(columns-1))/columns
	for i in range(4):
		var current=app.game.pet().growth_stage==PetRules.STAGES[i]
		var position=rect.position+Vector2((i%columns)*(width+gap),int(i/columns)*88)
		var b=button(parent,PetRules.STAGES[i].capitalize()+"\n"+str([0,7,30,60][i])+" days",Rect2(position,Vector2(width,80)),func(): pass,"",current)
		b.disabled=not current
		b.tooltip_text="Growth follows real elapsed time, not XP."

func rename_field(parent: Node, bounds: Rect2) -> void:
	name_input=LineEdit.new()
	name_input.text=draft_name
	name_input.max_length=20
	name_input.position=bounds.position
	name_input.size=bounds.size
	name_input.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	name_input.add_theme_font_size_override("font_size",24)
	name_input.add_theme_color_override("font_color",PetUI.INK)
	name_input.add_theme_stylebox_override("normal",PetUI.style(Color("fff8e8"),6))
	name_input.text_changed.connect(func(value): draft_name=value)
	parent.add_child(name_input)

func save_name() -> void:
	if app.game.rename_pet(draft_name):
		app.notify("Your friend is now called "+app.game.pet().name+".")
		app.show_details()

func sharp_room_portrait(parent: Node, rect: Rect2) -> TextureRect:
	# The same room and the same pet, not the alternate room painted in V06.
	var image=TextureRect.new()
	live_portrait=AtlasTexture.new()
	live_portrait.atlas=app.viewport.get_texture()
	live_portrait.filter_clip=true
	image.texture=live_portrait
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.position=rect.position
	image.size=rect.size
	image.name="LiveRoomPortrait"
	parent.add_child(image)
	update_portrait()
	return image

func update_portrait() -> void:
	if live_portrait==null or not is_instance_valid(app.home): return
	var home=app.home
	var at=home.pet_art.position
	if app.game.pet().sleeping: at=Vector2(home.bed_bounds.get_center().x,home.floor_y)
	var area=Rect2(at-Vector2(74,113),Vector2(148,113))
	area.position.x=clampf(area.position.x,0,home.room_size.x-area.size.x)
	area.position.y=clampf(area.position.y,0,home.room_size.y-area.size.y)
	var density=Vector2(app.viewport.size)/home.room_size
	live_portrait.region=Rect2(area.position*density,area.size*density)

func clear_button(parent: Node, caption: String, rect: Rect2, callback: Callable, points=24) -> Button:
	var b=Button.new()
	b.text=caption
	b.position=rect.position
	b.size=rect.size
	b.add_theme_font_override("font",load(PetUI.MENU_FONT_PATH))
	b.add_theme_font_size_override("font_size",points)
	for key in ["font_color","font_hover_color","font_pressed_color"]: b.add_theme_color_override(key,PetUI.INK)
	for key in ["normal","hover","pressed","disabled"]: b.add_theme_stylebox_override(key,StyleBoxEmpty.new())
	b.add_theme_stylebox_override("focus",PetUI.style(Color(0,0,0,0),4))
	b.pressed.connect(callback)
	b.mouse_entered.connect(func(): b.modulate=Color(1.06,1.06,1.06))
	b.mouse_exited.connect(func(): b.modulate=Color.WHITE)
	parent.add_child(b)
	return b

func centered(parent: Node, caption: String, rect: Rect2, points: int) -> Label:
	var label=text(parent,caption,rect,points)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text=true
	return label

## A55: the paper details kit from P13 (tools/build_details_paper.py).
var DETAILS_ART: String:
	get: return "res://assets/ui/details-paper/" if ArtStyle.paper else "res://assets/ui/details-v2/"
## A V06 stat bar: carved track, coloured fill (three-sliced so the round
## caps keep their shape) and the number on the right.
class DetailMeter extends Control:
	var fill: Texture2D
	var track: Texture2D
	var value=0.0:
		set(v):
			value=v
			queue_redraw()
	func _draw() -> void:
		draw_texture_rect(track,Rect2(Vector2.ZERO,size),false)
		var v=clampf(value/100.0,0,1)
		if v<=0.01: return
		var inner=Rect2(size.y*0.12,size.y*0.14,size.x-size.y*0.24,size.y*0.72)
		var cap_src=fill.get_height()*0.5
		var cap=inner.size.y*0.5
		var w=maxf(cap*2,inner.size.x*v)
		draw_texture_rect_region(fill,Rect2(inner.position,Vector2(cap,inner.size.y)),Rect2(0,0,cap_src,fill.get_height()))
		draw_texture_rect_region(fill,Rect2(inner.position+Vector2(cap,0),Vector2(w-cap*2,inner.size.y)),Rect2(cap_src,0,fill.get_width()-cap_src*2,fill.get_height()))
		draw_texture_rect_region(fill,Rect2(inner.position+Vector2(w-cap,0),Vector2(cap,inner.size.y)),Rect2(fill.get_width()-cap_src,0,cap_src,fill.get_height()))

## Font size scaled with the screen, never below a readable 11 px.
func kp(points: float, k: float) -> int:
	return maxi(11,int(round(points*k)))

func dtex(parent: Node, name: String, rect: Rect2) -> TextureRect:
	var t=TextureRect.new()
	t.texture=ArtTexture.load_texture(DETAILS_ART+name+".png")
	t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position=rect.position
	t.size=rect.size
	t.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t

## A57 (P47): Foxy Details from concept P47 with the details-p32 kit.
const P47="details-p32"
func p47_details() -> void:
	var f=p32_frame(Rect2(185,0,1300,910))
	var k: float=f[0]
	var c=logical_size*0.5 if f[1]==Vector2(836,470) else safe.get_center()
	var o: Vector2=f[1]
	var R=func(x: float,y: float,w: float,h: float) -> Rect2: return Rect2(c+(Vector2(x,y)-o)*k,Vector2(w,h)*k)
	details_canvas=Control.new()
	details_canvas.name="DetailsPanel"
	details_canvas.size=logical_size
	content.add_child(details_canvas)
	var pet=app.game.pet()
	var cv=details_canvas
	ConceptScreen.piece(cv,P47,"board",R.call(185,100,1295,712),false)
	ConceptScreen.piece(cv,P47,"title",R.call(545,0,575,118),false)
	ConceptScreen.words(cv,pet.name+" Details",R.call(612,14,446,88),int(66*k))
	ConceptScreen.piece(cv,"roomui-p32","coins",R.call(1280,20,195,76),false)
	wallet_value=ConceptScreen.words(cv,str(app.game.state.coins),R.call(1355,20,112,76),int(40*k))
	ConceptScreen.piece(cv,P47,"photo",R.call(225,135,545,420),false)
	ConceptScreen.piece(cv,P47,"name",R.call(312,512,356,76),false)
	ConceptScreen.words(cv,pet.name,R.call(330,512,320,76),int(58*k))
	ConceptScreen.words(cv,age_caption(),R.call(330,578,320,44),int(28*k))
	var traits=[["pill_green","Curious",250],["pill_blue","Playful",415],["pill_yellow","Loyal",580]]
	for t in traits:
		ConceptScreen.piece(cv,P47,t[0],R.call(t[2],626,147,56),false)
		ConceptScreen.words(cv,t[1],R.call(t[2],626,147,56),int(28*k))
	var keys=["fullness","happiness","energy","cleanliness","health","bond"]
	var names=["Food","Happy","Energy","Clean","Health","Bond"]
	var icons=["ic_food","ic_happy","ic_energy","ic_clean","ic_health","ic_bond"]
	var fills=["fill_green","fill_yellow","fill_blue","fill_blue","fill_green","fill_yellow"]
	var track: Texture2D=ConceptScreen.tex(P47,"track")
	for i in 6:
		var y=167.0+i*72.0
		ConceptScreen.piece(cv,P47,"row",R.call(800,y-32,650,64),false)
		ConceptScreen.piece(cv,P47,icons[i],R.call(822,y-25,52,50))
		ConceptScreen.words(cv,names[i],R.call(893,y-30,95,60),int(30*k),PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)
		var m=DetailMeter.new()
		m.name="Meter_"+keys[i]
		m.track=track
		m.fill=ConceptScreen.tex(P47,fills[i])
		var mr: Rect2=R.call(985,y-18,345,36)
		m.position=mr.position
		m.size=mr.size
		m.mouse_filter=Control.MOUSE_FILTER_IGNORE
		cv.add_child(m)
		meters[keys[i]]=m
		numbers[keys[i]]=ConceptScreen.words(cv,"",R.call(1332,y-30,110,60),int(28*k))
	ConceptScreen.piece(cv,P47,"growth",R.call(905,578,392,66),false)
	ConceptScreen.words(cv,"Growth Journey",R.call(950,582,300,56),int(36*k))
	var stage: String=pet.growth_stage
	var current=PetRules.STAGES.find(stage)
	var xs=[790,955,1120,1288]
	for i in 4:
		var on=i==current
		var cr: Rect2=R.call(xs[i],640,136,140)
		ConceptScreen.piece(cv,P47,"stage_on" if on else "stage",cr,false)
		var pic=ConceptScreen.piece(cv,P47,"fox_"+PetRules.STAGES[i],Rect2(cr.position+Vector2(cr.size.x*0.12,cr.size.y*0.06),Vector2(cr.size.x*0.76,cr.size.y*0.66)))
		if i>current: pic.modulate=Color(1,1,1,0.55)
		var lab=ConceptScreen.words(cv,PetRules.STAGES[i].capitalize(),Rect2(cr.position+Vector2(0,cr.size.y*0.72),Vector2(cr.size.x,cr.size.y*0.24)),int(24*k))
		lab.name="Stage_"+PetRules.STAGES[i]
		if on: ConceptScreen.piece(cv,P47,"star",Rect2(cr.position-Vector2(8,8)*k,Vector2(38,38)*k))
		if i<3:
			# Dotted green thread between the stage cards.
			for d in 3:
				var dot=ColorRect.new()
				dot.color=Color("6f9a3c")
				var dp: Rect2=R.call(xs[i]+140+d*8,708,5,5)
				dot.position=dp.position
				dot.size=dp.size
				dot.mouse_filter=Control.MOUSE_FILTER_IGNORE
				cv.add_child(dot)
	var backb=ConceptScreen.button(cv,"BackToMyPet",P47,"back",R.call(352,818,460,90),app.show_home)
	ConceptScreen.words(backb,"Back to My Pet",Rect2(backb.size.x*0.28,0,backb.size.x*0.66,backb.size.y),int(40*k))
	backb.tooltip_text="Back to My Pet"
	var care=ConceptScreen.button(cv,"CareForPet",P47,"care",R.call(835,818,488,92),app.show_home)
	ConceptScreen.words(care,"Care for "+pet.name,Rect2(care.size.x*0.26,0,care.size.x*0.68,care.size.y),int(44*k),Color("fff6e0"))
	care.tooltip_text="Care for "+pet.name

## Phone upright: the P47 pieces stacked: title, photo with name and traits,
## the six stat rows, the growth journey cards and the two buttons (scrolls).
func p47_details_portrait() -> void:
	var W=safe.size.x
	var u=W/400.0
	var x0=safe.position.x
	var pet=app.game.pet()
	details_canvas=Control.new()
	details_canvas.name="DetailsPanel"
	details_canvas.size=logical_size
	content.add_child(details_canvas)
	var cv=details_canvas
	var tr=Rect2(x0+W*0.12,safe.position.y,W*0.76,64*u)
	ConceptScreen.piece(cv,P47,"title",tr,false)
	ConceptScreen.words(cv,pet.name+" Details",tr.grow_individual(-tr.size.x*0.12,-tr.size.y*0.12,-tr.size.x*0.12,-tr.size.y*0.16),int(32*u))
	var top=tr.end.y+4*u
	var board=Rect2(x0,top,W,safe.end.y-top)
	ConceptScreen.slab(cv,P47,"board",board,0.12)
	var scroll=ScrollContainer.new()
	scroll.position=board.position+Vector2(10,12)*u
	scroll.size=board.size-Vector2(20,24)*u
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
	cv.add_child(scroll)
	var w=scroll.size.x
	var col=Control.new()
	col.custom_minimum_size=Vector2(w,820*u)
	scroll.add_child(col)
	ConceptScreen.piece(col,P47,"photo",Rect2(0,0,w*0.5,w*0.5*420/545),false)
	ConceptScreen.piece(col,P47,"name",Rect2(w*0.52,8*u,w*0.48,46*u),false)
	ConceptScreen.words(col,pet.name,Rect2(w*0.52,8*u,w*0.48,46*u),int(30*u))
	ConceptScreen.words(col,age_caption(),Rect2(w*0.52,56*u,w*0.48,26*u),int(18*u))
	var traits=[["pill_green","Curious"],["pill_blue","Playful"],["pill_yellow","Loyal"]]
	for i in traits.size():
		var pr=Rect2(w*0.54+(i%2)*w*0.23,90*u+int(i/2)*36*u,w*0.21,30*u)
		ConceptScreen.piece(col,P47,traits[i][0],pr,false)
		ConceptScreen.words(col,traits[i][1],pr,int(16*u))
	var keys=["fullness","happiness","energy","cleanliness","health","bond"]
	var names=["Food","Happy","Energy","Clean","Health","Bond"]
	var icons=["ic_food","ic_happy","ic_energy","ic_clean","ic_health","ic_bond"]
	var fills=["fill_green","fill_yellow","fill_blue","fill_blue","fill_green","fill_yellow"]
	var track: Texture2D=ConceptScreen.tex(P47,"track")
	var y=w*0.5*420/545+12*u
	for i in 6:
		var row=Rect2(0,y+i*48*u,w,44*u)
		ConceptScreen.piece(col,P47,"row",row,false)
		ConceptScreen.piece(col,P47,icons[i],Rect2(row.position+Vector2(10,7)*u,Vector2(30,30)*u))
		ConceptScreen.words(col,names[i],Rect2(row.position+Vector2(48,0)*u,Vector2(70,44)*u),int(18*u),PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)
		var m=DetailMeter.new()
		m.name="Meter_"+keys[i]
		m.track=track
		m.fill=ConceptScreen.tex(P47,fills[i])
		m.position=row.position+Vector2(120*u,12*u)
		m.size=Vector2(w-200*u,20*u)
		m.mouse_filter=Control.MOUSE_FILTER_IGNORE
		col.add_child(m)
		meters[keys[i]]=m
		numbers[keys[i]]=ConceptScreen.words(col,"",Rect2(row.end.x-76*u,row.position.y,70*u,44*u),int(16*u))
	y+=6*48*u+10*u
	var gr=Rect2(w*0.18,y,w*0.64,44*u)
	ConceptScreen.piece(col,P47,"growth",gr,false)
	ConceptScreen.words(col,"Growth Journey",gr,int(22*u))
	y+=52*u
	var current=PetRules.STAGES.find(pet.growth_stage)
	var sw=(w-18*u)/4.0
	for i in 4:
		var on=i==current
		var cr=Rect2(i*(sw+6*u),y,sw,sw*1.05)
		ConceptScreen.piece(col,P47,"stage_on" if on else "stage",cr,false)
		var pic=ConceptScreen.piece(col,P47,"fox_"+PetRules.STAGES[i],Rect2(cr.position+Vector2(cr.size.x*0.12,cr.size.y*0.06),Vector2(cr.size.x*0.76,cr.size.y*0.62)))
		if i>current: pic.modulate=Color(1,1,1,0.55)
		ConceptScreen.words(col,PetRules.STAGES[i].capitalize(),Rect2(cr.position+Vector2(0,cr.size.y*0.7),Vector2(cr.size.x,cr.size.y*0.26)),int(15*u)).name="Stage_"+PetRules.STAGES[i]
	y+=sw*1.05+12*u
	var backb=ConceptScreen.button(col,"BackToMyPet",P47,"back",Rect2(0,y,w*0.48,56*u),app.show_home)
	ConceptScreen.words(backb,"My Pet",Rect2(backb.size.x*0.3,0,backb.size.x*0.66,backb.size.y),int(22*u))
	backb.tooltip_text="Back to My Pet"
	var care=ConceptScreen.button(col,"CareForPet",P47,"care",Rect2(w*0.52,y,w*0.48,56*u),app.show_home)
	ConceptScreen.words(care,"Care",Rect2(care.size.x*0.28,0,care.size.x*0.66,care.size.y),int(24*u),Color("fff6e0"))
	care.tooltip_text="Care for "+pet.name
	col.custom_minimum_size.y=y+64*u

func build_details() -> void:
	app.home.focus_pet=true
	if portrait() and ArtStyle.paper and ResourceLoader.exists("res://assets/ui/details-p32/board.png"):
		p47_details_portrait()
		return
	if portrait():
		build_compact_details()
		return
	if ArtStyle.paper and ResourceLoader.exists("res://assets/ui/details-p32/board.png"):
		p47_details()
		return
	# Built from the V06 concept itself (tools/build_details_kit.py).
	var L: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DETAILS_ART+"layout.json"))
	var bw=float(L.size[0])
	var bh=float(L.size[1])
	var k=minf((safe.size.x-4)/bw,(safe.size.y-4)/bh)
	var at=func(x: float, y: float) -> Vector2: return Vector2(x,y)*k
	var rect=func(r: Array) -> Rect2: return Rect2(Vector2(r[0],r[1])*k,Vector2(r[2],r[3])*k)
	details_canvas=Control.new()
	details_canvas.name="DetailsPanel"
	details_canvas.position=safe.get_center()-Vector2(bw,bh)*k*0.5
	details_canvas.size=Vector2(bw,bh)*k
	content.add_child(details_canvas)
	var base=TextureRect.new()
	base.texture=ArtTexture.load_texture(DETAILS_ART+"base.png")
	base.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	base.size=details_canvas.size
	base.mouse_filter=Control.MOUSE_FILTER_IGNORE
	details_canvas.add_child(base)
	var pet=app.game.pet()
	var t=text(details_canvas,pet.name,rect.call(L.title),kp(52,k))
	t.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	var back=clear_button(details_canvas,"",rect.call(L.back),app.show_home)
	back.tooltip_text="Back to My Pet"
	if ArtStyle.paper:
		# P13: icons on the plain plaques (back arrow, coin, gear) are drawn here.
		var arrow=paper_icon(details_canvas,"res://assets/ui/menu-paper/ic_play.png",rect.call(L.back).grow(-10*k))
		arrow.flip_h=true
		arrow.self_modulate=Color(0.35,0.55,1.0)
		paper_icon(details_canvas,"res://assets/ui/menu-paper/coin.png",rect.call(L.coin_icon))
		paper_icon(details_canvas,"res://assets/ui/menu-paper/ic_gear.png",rect.call(L.gear).grow(-16*k)).material=PetUI.flat_ink(Color(1,0.96,0.88))
	wallet_value=centered(details_canvas,"",rect.call(L.coins),kp(40,k))
	clear_button(details_canvas,"",rect.call(L.gear),app.toggle_pause).tooltip_text="Settings"
	# Portrait: the concept room with this pet at its growth stage.
	var pr: Rect2=rect.call(L.portrait)
	dtex(details_canvas,"portrait_room",pr).stretch_mode=TextureRect.STRETCH_SCALE
	var stage: String=pet.growth_stage
	var fox_h=pr.size.y*[0.42,0.52,0.6,0.66][PetRules.STAGES.find(stage)]
	dtex(details_canvas,"stage_"+stage,Rect2(pr.position+Vector2(pr.size.x*0.5-fox_h*0.6,pr.size.y*0.88-fox_h),Vector2(fox_h*1.2,fox_h)))
	var cx=float(L.center_x)
	var line=func(caption: String, y: float, pts: int):
		var l=centered(details_canvas,caption,Rect2(at.call(cx-200,y-22),Vector2(400,44)*k),int(round(pts*k)))
		return l
	line.call(pet.name,float(L.name_y)-4,40)
	line.call(age_caption(),float(L.stage_y),24)
	line.call("Curious · Playful",float(L.traits_y)+2,22)
	var fav: Rect2=rect.call(L.favourite)
	var chip=Panel.new()
	var cs: StyleBox=StyleBoxEmpty.new()
	if not ArtStyle.paper:
		cs=StyleBoxFlat.new()
		cs.bg_color=Color8(244,228,196)
		cs.set_corner_radius_all(int(10*k))
	chip.add_theme_stylebox_override("panel",cs)
	chip.position=fav.position
	chip.size=fav.size
	chip.mouse_filter=Control.MOUSE_FILTER_IGNORE
	details_canvas.add_child(chip)
	var fav_icon=TextureRect.new()
	fav_icon.texture=ArtTexture.load_texture(BAG_ART+"items/berries.png")
	fav_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	fav_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fav_icon.position=Vector2(8*k,2*k)
	fav_icon.size=Vector2(70,fav.size.y/k-4)*k
	fav_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	chip.add_child(fav_icon)
	var fl=centered(chip,"Favorite: Berry bowl",Rect2(Vector2(80*k,0),Vector2(fav.size.x-88*k,fav.size.y)),kp(26 if not ArtStyle.paper else 18,k))
	fl.name="Favourite"
	# Stat bars (icons and labels are part of the concept picture).
	var bar: Array=L.bar
	var keys=["fullness","happiness","energy","cleanliness","health","bond"]
	var fills=["fill_food","fill_happy","fill_energy","fill_clean","fill_health","fill_bond"]
	var track: Texture2D=ArtTexture.load_texture(DETAILS_ART+"track.png")
	for i in 6:
		var row: Array=L.rows[i]
		var m=DetailMeter.new()
		m.name="Meter_"+keys[i]
		m.track=track
		m.fill=ArtTexture.load_texture(DETAILS_ART+fills[i]+".png")
		m.position=at.call(bar[0],float(row[0])+float(row[1])*0.5-float(bar[2])*0.5)
		m.size=Vector2(bar[1],bar[2])*k
		m.mouse_filter=Control.MOUSE_FILTER_IGNORE
		details_canvas.add_child(m)
		meters[keys[i]]=m
		var name_x=float(L.get("name_x",780))
		if L.has("icon_x"):
			var isz=float(row[1])*0.62
			dtex(details_canvas,["icon_food","icon_happy","icon_energy","icon_clean","icon_health","icon_bond"][i],Rect2(at.call(float(L.icon_x)-isz*0.5,float(row[0])+float(row[1])*0.5-isz*0.5),Vector2(isz,isz)*k))
		var nm=text(details_canvas,["Food","Happy","Energy","Clean","Health","Bond"][i],Rect2(Vector2(name_x,float(row[0]))*k,Vector2(110,row[1])*k),kp(32 if not ArtStyle.paper else 26,k))
		nm.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		numbers[keys[i]]=centered(details_canvas,"",Rect2(at.call(float(L.value_x)-60,float(row[0])),Vector2(120,row[1])*k),kp(34 if not ArtStyle.paper else 26,k))
	# Growth journey cards.
	var current=PetRules.STAGES.find(stage)
	var days=[0,7,30,60]
	var age=pet.elapsed_age_seconds/PetRules.DAY
	for i in 4:
		var cr: Rect2=rect.call(L.cards[i])
		var on=i==current
		dtex(details_canvas,"card_on" if on else "card",cr).stretch_mode=TextureRect.STRETCH_SCALE
		var pic_h=cr.size.y*0.62
		if ArtStyle.paper: pic_h=cr.size.y*0.5
		dtex(details_canvas,"stage_"+PetRules.STAGES[i]+("" if i<=current else "_grey"),Rect2(cr.position+Vector2(cr.size.x*0.5-pic_h*0.9,cr.size.y*0.1),Vector2(pic_h*1.2,pic_h)))
		dtex(details_canvas,"check" if i<=current else "clock",Rect2(cr.position+Vector2(cr.size.x*0.62,cr.size.y*0.18),Vector2(cr.size.y*0.42,cr.size.y*0.42)))
		var lab_box=Rect2(cr.position+Vector2(0,cr.size.y*0.66),Vector2(cr.size.x,cr.size.y*0.34))
		if ArtStyle.paper: lab_box=Rect2(cr.position+Vector2(0,cr.size.y*0.6),Vector2(cr.size.x,cr.size.y*0.26))
		var lab=centered(details_canvas,PetRules.STAGES[i].capitalize(),lab_box,kp(22 if not ArtStyle.paper else 16,k))
		lab.name="Stage_"+PetRules.STAGES[i]
		var cap=("%d / %d days to %s"%[int(age),days[i+1],PetRules.STAGES[i+1].capitalize()] if i+1<4 else "Grown up!") if on else ("%d days"%days[i] if i>current else "")
		if not cap.is_empty(): centered(details_canvas,cap,Rect2(Vector2(cr.position.x-20*k,float(L.card_caption_y)*k-14*k),Vector2(cr.size.x+40*k,28*k)),kp(22,k))
		if on and i+1<4:
			var p: Rect2=rect.call(L.progress)
			p.position.x=cr.position.x+(cr.size.x-p.size.x)*0.5
			var pm=DetailMeter.new()
			pm.track=track
			pm.fill=ArtTexture.load_texture(DETAILS_ART+"fill_health.png")
			pm.position=p.position
			pm.size=p.size
			pm.value=clampf((age-days[i])/(days[i+1]-days[i])*100.0,0,100)
			details_canvas.add_child(pm)
	var gt: Array=L.get("growth_title",[85,664,200,36])
	text(details_canvas,"Growth Journey",rect.call(gt),kp(28 if not ArtStyle.paper else 24,k)).autowrap_mode=TextServer.AUTOWRAP_OFF
	if k>0.6 or ArtStyle.paper:
		var gs: Array=L.get("growth_sub",[85,704,200,30])
		var gsub=text(details_canvas,"Foxy grows over time with your care!" if ArtStyle.paper else "Grows with your care!",rect.call(gs),kp(20 if not ArtStyle.paper else 17,k))
		gsub.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if ArtStyle.paper else TextServer.AUTOWRAP_OFF
	var backb=clear_button(details_canvas,"",rect.call(L.back_button),app.show_home)
	backb.name="BackToMyPet"
	centered(backb,"Back to My Pet",Rect2(Vector2.ZERO,backb.size),kp(28,k)).mouse_filter=Control.MOUSE_FILTER_IGNORE
	var care=clear_button(details_canvas,"",rect.call(L.care_button),app.show_home)
	care.name="CareForPet"
	centered(care,"Care for "+pet.name,Rect2(Vector2.ZERO,care.size),kp(36,k)).mouse_filter=Control.MOUSE_FILTER_IGNORE

func paper_icon(parent: Node, path: String, rect: Rect2) -> TextureRect:
	var t=TextureRect.new()
	t.texture=ArtTexture.load_texture(path)
	t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position=rect.position
	t.size=rect.size
	t.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t

func age_caption() -> String:
	return app.game.pet().growth_stage.capitalize()+" · %d days"%int(app.game.pet().elapsed_age_seconds/PetRules.DAY)

func build_compact_details() -> void:
	var parts=CareArt.header(content,safe,app.game.pet().name,app.show_home,"menu",func(): toggle_overlay("menu"))
	menu_button=parts.square
	wallet_value=parts.wallet_label
	var column=scroll_card(Rect2(safe.position+Vector2(0,PetUI.H_HEADER+10),safe.size-Vector2(0,PetUI.H_HEADER+10)))
	var portrait_box=Control.new()
	portrait_box.custom_minimum_size=Vector2(0,194)
	column.add_child(portrait_box)
	var width=safe.size.x-36
	sharp_room_portrait(portrait_box,Rect2(4,4,148,180))
	text(portrait_box,app.game.pet().name+"
"+age_caption()+"
Curious · Playful",Rect2(164,10,maxf(120,width-168),158),18)
	var meter_box=Control.new()
	meter_box.custom_minimum_size=Vector2(0,356)
	column.add_child(meter_box)
	for i in range(6):
		var entry=NEEDS[i]
		var row=CareArt.strip(meter_box,Rect2(0,i*58,width,54))
		PetUI.compose(row,entry[1],CareArt.icon(entry[2]),"left",17)
		var inset=PetUI.ROW_INSET
		meters[entry[0]]=CareArt.meter(row,Vector2(134,17),maxf(60,width-134-inset-56),entry[0],20)
		numbers[entry[0]]=centered(row,"",Rect2(width-inset-50,8,50,38),17)
		numbers[entry[0]].horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	flow_label(column,"Favorite: Berry bowl",18)
	flow_label(column,"Growth Journey",24)
	flow_label(column,"Baby at birth. Child at 7 days.
Teen at 30 days. Adult at 60 days.
Growth follows real time and your care.",18)
	var growth=Control.new()
	growth.custom_minimum_size=Vector2(0,176)
	column.add_child(growth)
	growth_cards(growth,Rect2(0,0,width,176),2)
	flow_button(column,"Back to My Pet",app.show_home,"back")
	flow_button(column,"Care for "+app.game.pet().name,app.show_home,"paw",true)

## V2: one connected region per stop; the V1 practice levels are retired from the map.
const LEVELS=[["WORLD","Green Meadows","Explore the connected meadows with Foxy: secrets, toy parts and a new ability.","res://assets/art/meadows-v2/town.png"]]
const MAP_POINTS=[Vector2(.163,.56),Vector2(.374,.513),Vector2(.521,.454),Vector2(.732,.576),Vector2(.86,.352)]
func chip(parent: Node, caption: String, rect: Rect2, icon="", points=18) -> Panel:
	var panel=frame(parent,rect)
	PetUI.set_piece(panel,"tag")
	PetUI.compose(panel,caption,CareArt.icon(icon) if not icon.is_empty() else null,"left",points)
	return panel
func map_board(rect: Rect2) -> void:
	var panel=CareArt.panel(content,rect)
	panel.name="MapBoard"
	panel.clip_contents=true
	var area=Rect2(8,8,rect.size.x-16,rect.size.y-16)
	picture(panel,"res://assets/ui/care-v1/meadows-map.png",area,true)
	var map_scale=maxf(area.size.x/1536.0,area.size.y/1024.0)
	var offset=area.get_center()-Vector2(1536,1024)*map_scale/2
	var spots: Array[Vector2]=[]
	for point in MAP_POINTS: spots.append(offset+point*Vector2(1536,1024)*map_scale)
	# Stone path between stops (kit path_dot at its own proportion).
	for i in range(spots.size()-1):
		var count=int(spots[i].distance_to(spots[i+1])/16)
		for k in range(1,count):
			var at=spots[i].lerp(spots[i+1],float(k)/count)
			var stone=picture(panel,"res://assets/ui/kit-v1/path_dot.png",Rect2(at-Vector2(6,4.5),Vector2(12,9)))
			stone.modulate=Color(1,1,1,1.0 if i<LEVELS.size()-1 else .6)
	# A49 medallions: done (gold check), current (our fox in a gold ring with
	# a flag), open (number), locked (padlock). Drawn at their own proportions.
	var size=56.0 if portrait() or compact() else 64.0
	for i in range(spots.size()):
		var open=i<LEVELS.size()
		var done=open and LEVELS[i][0] in app.game.state.completed_levels
		var current=i==selected_level
		var piece="medal_locked" if not open else ("medal_ring" if current else ("medal_done" if done else "medal_open"))
		var b=PetUI.menu_button(panel,"",func(): selected_level=i;signature="";layout(logical_size,safe))
		b.get_node("MenuButtonMotion").queue_free()
		PetUI.set_piece(b,piece)
		b.name="Level%d"%(i+1)
		b.position=(spots[i]-Vector2.ONE*size/2).round()
		b.size=Vector2.ONE*size
		b.disabled=not open
		b.tooltip_text=LEVELS[i][1] if open else "Coming later"
		if current:
			# Our fox inside the ring (pre-cut circle), drawn under the ring art.
			var face=picture(b,"res://assets/ui/kit-v1/fox-medal.png",Rect2(size*.14,size*.14,size*.72,size*.72))
			face.show_behind_parent=true
			var flag=picture(b,"res://assets/ui/kit-v1/flag.png",Rect2(size*.62,-size*.42,size*.42,size*.5))
			flag.name="Flag"
		elif open and not done:
			PetUI.compose(b,str(i+1),null,"row",int(size*.36))
		# A number plate only where the medallion does not already show it.
		if open and not done and not current: continue
		var label=CareArt.tag(panel,str(i+1),Rect2(b.position.x+size*.5-14,b.position.y+size-6,28,24))
		label.size=Vector2(28,24)
		(label.get_meta("compose") as Dictionary).layout="row"
		PetUI.arrange(label)
	CareArt.tag(panel,"Green Meadows",Rect2(12,12,minf(176,rect.size.x-24),PetUI.H_TAG),"map")
func world_card(parent: Node, rect: Rect2, caption: String, path: String) -> void:
	var card=frame(parent,rect)
	card.name=caption.to_pascal_case()
	var narrow=rect.size.x<rect.size.y*3.2
	var thumb_w=rect.size.x-16 if narrow else rect.size.y*1.6-16
	var thumb=picture(card,path,Rect2(8,8,thumb_w,rect.size.y-16),true)
	thumb.modulate=Color(.78,.78,.82)
	if narrow:
		# Phone width: the caption sits on the picture as a small locked chip.
		var label=CareArt.tag(card,caption,Rect2(10,rect.size.y-PetUI.H_TAG-10,rect.size.x-20,PetUI.H_TAG),"lock")
		label.name="Locked"
		return
	var x=rect.size.y*1.6
	text(card,caption,Rect2(x,6,rect.size.x-x-8,rect.size.y*.5),18)
	var lock=CareArt.tag(card,"Coming later",Rect2(x,rect.size.y-PetUI.H_TAG-10,minf(150,rect.size.x-x-10),PetUI.H_TAG),"lock")
	lock.name="Locked"
const LEVEL_CARD_BASE=14+34+38+48+136
func level_card_height(width: float, room: float) -> float:
	var preview=minf((width-32)*.42,150)+8
	var full=LEVEL_CARD_BASE+preview+54
	if room>=full: return full
	if room>=LEVEL_CARD_BASE+54: return LEVEL_CARD_BASE+54
	return minf(room,LEVEL_CARD_BASE)
func level_card(parent: Node, rect: Rect2) -> void:
	var level=LEVELS[selected_level]
	var card=CareArt.panel(parent,rect)
	card.name="LevelCard"
	var y=14.0
	var heading=text(card,"Green Meadows",Rect2(16,y,rect.size.x-32,34),26)
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	y+=34
	var sub=text(card,"%d · %s"%[selected_level+1,level[1]],Rect2(16,y,rect.size.x-32,30),20)
	sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	y+=38
	var preview_h=minf((rect.size.x-32)*.42,150)
	var room=rect.size.y-LEVEL_CARD_BASE
	if room>=preview_h+8+54:
		var preview=frame(card,Rect2(16,y,rect.size.x-32,preview_h))
		preview.name="LevelPreview"
		picture(preview,level[3],Rect2(6,6,rect.size.x-44,preview_h-12),true)
		y+=preview_h+8
	var goal=text(card,level[2],Rect2(16,y,rect.size.x-32,44),17)
	goal.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	y+=48
	var done=level[0] in app.game.state.completed_levels
	var pet=app.game.pet()
	var bottom=rect.size.y-16
	if y+46<=bottom-126:
		var companion=CareArt.tag(card,"%s · %s%s"%[pet.name,pet.growth_stage.capitalize(),"  ·  Completed" if done else ""],Rect2(16,y+6,rect.size.x-32,PetUI.H_TAG),"paw",true)
		companion.name="Companion"
	var back=button(card,"Back to My Pet",Rect2(16,bottom-PetUI.H_BUTTON,rect.size.x-32,PetUI.H_BUTTON),app.show_home,"back")
	back.name="BackToMyPet"
	var start=button(card,"Play again" if done else "Start adventure",Rect2(16,bottom-PetUI.H_BUTTON-8-PetUI.H_PRIMARY,rect.size.x-32,PetUI.H_PRIMARY),func(): app.show_world() if level[0]=="WORLD" else app.show_adventure(level[0]),"play",true)
	start.name="StartAdventure"
	PetUI.unify([back,start])
## A57 (P46): Adventures from concept P46 with the map-p32 kit. The five
## stops are the Green Meadows places: visited ones carry a check, the place
## you are in glows gold, places not reached yet are locked.
const P46="map-p32"
var map_pick=""
const P46_STOPS=[["meadow_fields",160,305],["river_crossing",330,405],["hidden_cave",550,462],["old_tower",800,435],["forest_gate",995,410]]
func p46_map() -> void:
	var f=p32_frame(Rect2(12,15,1648,905))
	var k: float=f[0]
	var c=logical_size*0.5 if f[1]==Vector2(836,470) else safe.get_center()
	var o: Vector2=f[1]
	var R=func(x: float,y: float,w: float,h: float) -> Rect2: return Rect2(c+(Vector2(x,y)-o)*k,Vector2(w,h)*k)
	var sky=ColorRect.new()
	sky.color=Color8(128,190,232)
	sky.size=logical_size
	sky.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(sky)
	var panel=Control.new()
	panel.name="AdventureMap"
	panel.size=logical_size
	content.add_child(panel)
	for cl in [[215,40,170,80],[1440,30,220,90],[1560,880,140,60]]: ConceptScreen.piece(panel,P46,"cloud",R.call(cl[0],cl[1],cl[2],cl[3]))
	var back=ConceptScreen.button(panel,"BackToMyPet",P46,"back",R.call(28,16,104,104),app.show_home)
	back.tooltip_text="Back to My Pet"
	ConceptScreen.piece(panel,P46,"sprig",R.call(468,32,72,72))
	ConceptScreen.piece(panel,P46,"sprig",R.call(1132,32,72,72)).flip_h=true
	ConceptScreen.piece(panel,P46,"title",R.call(545,14,580,108),false)
	ConceptScreen.words(panel,"Adventures",R.call(610,18,450,98),int(80*k))
	ConceptScreen.piece(panel,P46,"map",R.call(12,116,1190,568),false)
	var w=app.game.world()
	var here: String=app.active_world.room_id if is_instance_valid(app.active_world) else String(w.get("room",""))
	for i in P46_STOPS.size():
		var st: Array=P46_STOPS[i]
		var visited=st[0] in w.get("visited",[])
		var now=st[0]==here or (here.is_empty() and i==0)
		var r=48.0 if now else 42.0
		# Each stop is a button: tapping a place you know shows its name.
		var room_id: String=st[0]
		var title: String=String(GameState.world_data().rooms[room_id].get("title",room_id))
		var node=ConceptScreen.button(panel,"Stop%d"%(i+1),P46,"node_now" if now else "node",R.call(st[1]-(r*1.33 if now else r),st[2]-r,(r*2.66 if now else r*2),r*2),func():
			map_pick=room_id
			signature="";layout(logical_size,safe))
		node.tooltip_text=title if visited or now else "Not found yet"
		node.disabled=not (visited or now)
		ConceptScreen.words(panel,str(i+1),R.call(st[1]-r,st[2]-r,r*2,r*2),int(54*k))
		if not now:
			ConceptScreen.piece(panel,P46,"check" if visited else "lock",R.call(st[1]+16,st[2]+12,46,46))
	ConceptScreen.piece(panel,P46,"side",R.call(1205,108,454,566),false)
	ConceptScreen.piece(panel,P46,"sprig",R.call(1222,140,50,50))
	ConceptScreen.piece(panel,P46,"sprig",R.call(1600,140,50,50)).flip_h=true
	var side_title="Green Meadows"
	if not map_pick.is_empty() and GameState.world_data().rooms.has(map_pick): side_title=String(GameState.world_data().rooms[map_pick].get("title",side_title))
	ConceptScreen.words(panel,side_title,R.call(1262,132,350,76),int(46*k)).name="PlaceName"
	ConceptScreen.piece(panel,P46,"meadows",R.call(1226,210,412,320),false)
	ConceptScreen.piece(panel,P46,"sprig",R.call(1222,580,52,52))
	ConceptScreen.piece(panel,P46,"sprig",R.call(1598,580,52,52)).flip_h=true
	var start=ConceptScreen.button(panel,"StartAdventure",P46,"start",R.call(1272,544,320,108),app.show_world,"Start",null,int(66*k),Color("fff6e0"))
	start.tooltip_text="Start"
	for wc in [["SunnyBeach","Sunny Beach","beach",25],["MysticForest","Mystic Forest","forest",848]]:
		var x: float=wc[3]
		var card=ConceptScreen.piece(panel,P46,"world_card",R.call(x,692,804,224),false)
		card.name=wc[0]
		ConceptScreen.piece(panel,P46,wc[2],R.call(x+18,704,412,196),false)
		ConceptScreen.words(panel,wc[1],R.call(x+468,734,300,70),int(42*k))
		ConceptScreen.piece(panel,P46,"sprig",R.call(x+440,780,40,40))
		var lock=ConceptScreen.piece(panel,P46,"later",R.call(x+484,800,228,62),false)
		lock.name="Locked"
		ConceptScreen.words(panel,"Coming later",R.call(x+484,800,228,62),int(30*k))

## Phone upright: title, the island map with its stops, the Green Meadows
## card with Start, and the two locked worlds side by side.
func p46_map_portrait() -> void:
	var W=safe.size.x
	var u=W/400.0
	var x0=safe.position.x
	var y=safe.position.y
	var sky=ColorRect.new()
	sky.color=Color8(128,190,232)
	sky.size=logical_size
	sky.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(sky)
	var panel=Control.new()
	panel.name="AdventureMap"
	panel.size=logical_size
	content.add_child(panel)
	var back=ConceptScreen.button(panel,"BackToMyPet",P46,"back",Rect2(x0,y,52*u,52*u),app.show_home)
	back.tooltip_text="Back to My Pet"
	var tr=Rect2(x0+60*u,y,W-70*u,56*u)
	ConceptScreen.piece(panel,P46,"title",tr,false)
	ConceptScreen.words(panel,"Adventures",tr.grow_individual(-tr.size.x*0.1,-tr.size.y*0.1,-tr.size.x*0.1,-tr.size.y*0.14),int(36*u))
	y+=62*u
	var mh=W*568.0/1190.0
	var mr=Rect2(x0,y,W,mh)
	ConceptScreen.piece(panel,P46,"map",mr,false)
	var w=app.game.world()
	var here: String=app.active_world.room_id if is_instance_valid(app.active_world) else String(w.get("room",""))
	for i in P46_STOPS.size():
		var st: Array=P46_STOPS[i]
		var at=mr.position+Vector2((float(st[1])-12)/1190.0,(float(st[2])-116)/568.0)*mr.size
		var visited=st[0] in w.get("visited",[])
		var now=st[0]==here or (here.is_empty() and i==0)
		var r=(20.0 if now else 17.0)*u
		var node=ConceptScreen.piece(panel,P46,"node_now" if now else "node",Rect2(at-Vector2(r*(1.33 if now else 1.0),r),Vector2(r*(2.66 if now else 2.0),r*2)),now)
		node.name="Stop%d"%(i+1)
		ConceptScreen.words(panel,str(i+1),Rect2(at-Vector2(r,r),Vector2(r,r)*2),int(22*u))
		if not now: ConceptScreen.piece(panel,P46,"check" if visited else "lock",Rect2(at+Vector2(6,4)*u,Vector2(18,18)*u))
	# Spread the three blocks over the whole height.
	var cw0=(W-8*u)/2.0
	var spare=maxf(0.0,(safe.end.y-y-mh)-(W*0.84*566.0/454.0*0.62)-cw0*0.9-16*u)
	y+=mh+8*u+spare*0.3
	var side=Rect2(x0+W*0.08,y,W*0.84,W*0.84*566.0/454.0*0.62+spare*0.4)
	ConceptScreen.slab(panel,P46,"side",side,0.12)
	ConceptScreen.words(panel,"Green Meadows",Rect2(side.position+Vector2(0,8*u),Vector2(side.size.x,34*u)),int(26*u))
	ConceptScreen.piece(panel,P46,"meadows",Rect2(side.position+Vector2(side.size.x*0.08,44*u),Vector2(side.size.x*0.84,side.size.y-120*u)),false)
	var start=ConceptScreen.button(panel,"StartAdventure",P46,"start",Rect2(side.position.x+side.size.x*0.18,side.end.y-72*u,side.size.x*0.64,62*u),app.show_world,"Start",null,int(34*u),Color("fff6e0"))
	start.tooltip_text="Start"
	y=side.end.y+8*u+spare*0.1
	var cw=(W-8*u)/2.0
	var ch=minf(safe.end.y-y,cw*0.9+spare*0.2)
	for i in 2:
		var wc=[["SunnyBeach","Sunny Beach","beach"],["MysticForest","Mystic Forest","forest"]][i]
		var r2=Rect2(x0+i*(cw+8*u),y,cw,ch)
		var card=ConceptScreen.slab(panel,P46,"world_card",r2,0.15)
		card.name=wc[0]
		ConceptScreen.piece(panel,P46,wc[2],Rect2(r2.position+Vector2(8,8)*u,Vector2(r2.size.x-16*u,r2.size.y*0.52)),false)
		ConceptScreen.words(panel,wc[1],Rect2(r2.position+Vector2(0,r2.size.y*0.58),Vector2(r2.size.x,r2.size.y*0.16)),int(18*u))
		var lr=Rect2(r2.position+Vector2(r2.size.x*0.1,r2.size.y*0.76),Vector2(r2.size.x*0.8,r2.size.y*0.18))
		ConceptScreen.piece(panel,P46,"later",lr,false).name="Locked"
		ConceptScreen.words(panel,"Coming later",lr,int(15*u))

func build_map() -> void:
	if ArtStyle.paper and portrait() and ResourceLoader.exists("res://assets/ui/map-p32/map.png"):
		p46_map_portrait()
		return
	if ArtStyle.paper and not portrait() and ResourceLoader.exists("res://assets/ui/map-p32/map.png"):
		p46_map()
		return
	var bounds=page_bounds()
	if portrait():
		var map_h=minf(300,bounds.size.y*.38)
		map_board(Rect2(bounds.position,Vector2(bounds.size.x,map_h)))
		var card_h=level_card_height(bounds.size.x,bounds.size.y-map_h-8-(98 if bounds.size.y-map_h>LEVEL_CARD_BASE+98 else 0))
		var worlds_h=bounds.size.y-map_h-card_h-16
		level_card(content,Rect2(bounds.position+Vector2(0,map_h+8),Vector2(bounds.size.x,card_h)))
		if worlds_h>=64:
			var w=(bounds.size.x-8)/2
			world_card(content,Rect2(bounds.position.x,bounds.end.y-worlds_h,w,minf(worlds_h,90)),"Sunny Beach","res://assets/ui/concept-v1/world-sunny-beach.png")
			world_card(content,Rect2(bounds.position.x+w+8,bounds.end.y-worlds_h,w,minf(worlds_h,90)),"Mystic Forest","res://assets/ui/concept-v1/world-mystic-forest.png")
		return
	var side_w=clampf(bounds.size.x*.32,260,380)
	var map_w=bounds.size.x-side_w-12
	var worlds_h=0.0 if compact() else clampf(bounds.size.y*.2,70,100)
	map_board(Rect2(bounds.position,Vector2(map_w,bounds.size.y-worlds_h-(8 if worlds_h>0 else 0))))
	if worlds_h>0:
		var w=(map_w-8)/2
		world_card(content,Rect2(bounds.position.x,bounds.end.y-worlds_h,w,worlds_h),"Sunny Beach","res://assets/ui/concept-v1/world-sunny-beach.png")
		world_card(content,Rect2(bounds.position.x+w+8,bounds.end.y-worlds_h,w,worlds_h),"Mystic Forest","res://assets/ui/concept-v1/world-mystic-forest.png")
	level_card(content,Rect2(bounds.position+Vector2(map_w+12,0),Vector2(side_w,bounds.size.y)))

## A51 shop: foods for Foxy (kibble stays free), then toys and accessories.
func shop_row(column: VBoxContainer, icon: String, title: String, detail: String, price: int, can_buy: bool, buy: Callable) -> void:
	var row=CareArt.strip(column,Rect2(0,0,100,64))
	row.custom_minimum_size=Vector2(0,64)
	PetUI.compose(row,title+"\n"+detail,CareArt.icon(icon),"left",19)
	var btn=button(row,"%d"%price,Rect2(0,9,112,46),buy,"",true)
	btn.name="Buy_"+title.to_pascal_case()
	var coin=TextureRect.new()
	coin.texture=ArtTexture.load_texture(PetUI.COIN_PATH)
	coin.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	coin.size=Vector2(22,22)
	coin.position=Vector2(16,12)
	coin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	btn.add_child(coin)
	btn.disabled=not can_buy
	row.resized.connect(func(): btn.position.x=row.size.x-btn.size.x-14)

## V11 shop, built from its concept (tools/build_shop_kit.py).
## A55: the paper shop kit from P14 (tools/build_shop_paper.py).
var SHOP_ART: String:
	get: return "res://assets/ui/shop-paper/" if ArtStyle.paper else "res://assets/ui/shop-v2/"
var shop_tab="food"
var shop_pick=""
func shop_items(tab: String) -> Array:
	var out=[]
	match tab:
		"food":
			var data=GameState.foods()
			var art={"berry_bowl":"berries","apple":"apple","fish_treat":"fish","honey_cookie":"cookie","carrot":"carrot"}
			for id in data.order:
				if id=="kibble": continue
				var f: Dictionary=data.foods[id]
				var taste=app.game.food_taste(id)
				var line="A tasty treat for %s."%app.game.pet().name
				if taste=="like": line="%s's favourite!"%app.game.pet().name
				elif taste=="dislike": line="%s is not keen on this one."%app.game.pet().name
				out.append({"id":id,"name":String(f.get("short",f.name)),"full":f.name,"icon":BAG_ART+"items/%s.png"%art.get(id,"apple"),"price":int(f.price),"text":line,"have":app.game.food_count(id),"food":true})
		"toys":
			for item in ItemCatalog.ITEMS:
				if item.category=="food": continue
				var owned=int(app.game.state.inventory.get(item.item_id,0))
				var sun="res://assets/art/paper-v1/sun_ball.png" if ArtStyle.paper else "res://assets/ui/ball-v1/sun-ball.png"
				var icon=(sun if item.item_id=="ball_sun" else SHOP_ART+"collar.png")
				out.append({"id":item.item_id,"name":item.display_name,"full":item.display_name,"icon":icon,"price":item.price,"text":item.description,"have":owned,"food":false,"permanent":item.permanent})
	return out

func shop_buy(it: Dictionary) -> void:
	if it.food:
		if app.game.buy_food(it.id): app.notify("%s is in your bag."%it.full)
	elif app.game.purchase(it.id,GameState.event_id("purchase")):
		if it.id=="blue_collar": app.game.equip_collar()
	signature="";layout(logical_size,safe)

func stex(parent: Node, path: String, rect: Rect2, aspect=true) -> TextureRect:
	var t=TextureRect.new()
	t.texture=ArtTexture.load_texture(path)
	t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED if aspect else TextureRect.STRETCH_SCALE
	t.position=rect.position
	t.size=rect.size
	t.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t

func flat_button(parent: Node, name: String, rect: Rect2, callback: Callable) -> Button:
	var b=Button.new()
	b.name=name
	b.flat=true
	b.focus_mode=Control.FOCUS_NONE
	b.position=rect.position
	b.size=rect.size
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

## A57 (P45): the shop from concept P45 with the shop-p32 kit.
const P45="shop-p32"
const P45_ART={"berry_bowl":"berries","apple":"apple","fish_treat":"fish","honey_cookie":"cookie","carrot":"carrot","ball_sun":"ball","blue_collar":"collar"}
## Phone upright: title and coins, tabs, a two-column grid that scrolls,
## and the chosen item with Buy at the bottom (same P45 pieces).
func p45_shop_portrait() -> void:
	var W=safe.size.x
	var u=W/400.0
	var x0=safe.position.x
	var y=safe.position.y
	var panel=Control.new()
	panel.name="ShopPanel"
	panel.size=logical_size
	content.add_child(panel)
	var dim=ColorRect.new()
	dim.color=Color(.05,.04,.02,.3)
	dim.size=logical_size
	panel.add_child(dim)
	var close=ConceptScreen.button(panel,"CloseShop",P45,"close",Rect2(x0+W-52*u,y,50*u,50*u),app.show_home)
	close.tooltip_text="Close"
	var tr=Rect2(x0,y,220*u,56*u)
	ConceptScreen.piece(panel,P45,"title",tr,false)
	ConceptScreen.piece(panel,P45,"ic_stall",Rect2(tr.position+Vector2(14,6)*u,Vector2(62,44)*u))
	ConceptScreen.words(panel,"Shop",Rect2(tr.position.x+80*u,tr.position.y,120*u,tr.size.y),int(40*u)).name="ShopTitle"
	var cr=Rect2(x0+W-160*u,y+4*u,100*u,44*u)
	ConceptScreen.piece(panel,P45,"coins",cr,false)
	wallet_value=ConceptScreen.words(panel,str(app.game.state.coins),Rect2(cr.position.x+cr.size.x*0.42,cr.position.y,cr.size.x*0.52,cr.size.y),int(22*u))
	y+=64*u
	var board=Rect2(x0,y,W,safe.end.y-y)
	ConceptScreen.slab(panel,P45,"board",board,0.1)
	var tabs=[["food","Food","ic_leaf"],["toys","Toys","ic_ball"],["room","Room","ic_house"]]
	var tw=(W-24*u)/3.0
	for i in tabs.size():
		var t=tabs[i]
		var id: String=t[0]
		var on=shop_tab==id
		var r=Rect2(x0+8*u+i*(tw+4*u),y+10*u,tw,48*u)
		var b=ConceptScreen.button(panel,"Tab_"+id,P45,"tab_on" if on else "tab",r,func():
			shop_tab=id
			shop_pick=""
			signature="";layout(logical_size,safe),t[1],null,int(22*u),Color("fff6e0") if on else PetUI.INK)
		b.tooltip_text=t[1]
	var items: Array=shop_items(shop_tab)
	if shop_pick.is_empty() or not items.any(func(it): return it.id==shop_pick): shop_pick=items[0].id if not items.is_empty() else ""
	var detail_h=210*u
	var grid=Rect2(x0+10*u,y+66*u,W-20*u,board.end.y-y-66*u-detail_h-10*u)
	var scroll=ScrollContainer.new()
	scroll.position=grid.position
	scroll.size=grid.size
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
	panel.add_child(scroll)
	var cw=(grid.size.x-10*u)/2.0
	var ch=cw*1.05
	var holder=Control.new()
	holder.custom_minimum_size=Vector2(grid.size.x,ceil(items.size()/2.0)*(ch+8*u))
	scroll.add_child(holder)
	for n in items.size():
		var it: Dictionary=items[n]
		var on=it.id==shop_pick
		var pick: String=it.id
		var cr2=Rect2((n%2)*(cw+10*u),int(n/2)*(ch+8*u),cw,ch)
		var card=ConceptScreen.button(holder,"Card_"+String(it.id),P45,"card_on" if on else "card",cr2,func():
			shop_pick=pick
			signature="";layout(logical_size,safe))
		var art: String=P45_ART.get(it.id,"")
		if art.is_empty(): stex(card,it.icon,Rect2(cw*0.2,ch*0.06,cw*0.6,ch*0.5))
		else: ConceptScreen.piece(card,P45,art,Rect2(cw*0.18,ch*0.06,cw*0.64,ch*0.5))
		ConceptScreen.words(card,it.name,Rect2(0,ch*0.58,cw,ch*0.14),int(20*u))
		var pr=Rect2(cw*0.22,ch*0.76,cw*0.56,ch*0.17)
		ConceptScreen.piece(card,P45,"price",pr,false)
		var cs=pr.size.y*0.8
		ConceptScreen.piece(card,P45,"coin",Rect2(pr.position+Vector2(pr.size.x*0.22-cs*0.5,(pr.size.y-cs)*0.5),Vector2(cs,cs)))
		ConceptScreen.words(card,str(it.price),Rect2(pr.position+Vector2(pr.size.x*0.4,0),Vector2(pr.size.x*0.5,pr.size.y)),int(18*u))
	var dr=Rect2(x0+8*u,board.end.y-detail_h-6*u,W-16*u,detail_h)
	ConceptScreen.slab(panel,P45,"side",dr,0.2)
	if items.is_empty():
		wrapped(panel,"Room things are coming soon: beds, plants, lamps and rugs for %s's room."%app.game.pet().name,dr.grow(-16*u),int(20*u))
		return
	var item: Dictionary=items.filter(func(it): return it.id==shop_pick)[0]
	var big: String=P45_ART.get(item.id,"")
	var pic=Rect2(dr.position+Vector2(14,16)*u,Vector2(110,110)*u)
	if big.is_empty(): stex(panel,item.icon,pic)
	else: ConceptScreen.piece(panel,P45,big,pic)
	ConceptScreen.words(panel,item.full,Rect2(dr.position+Vector2(130,14)*u,Vector2(dr.size.x-140*u,40*u)),int(28*u)).name="ItemName"
	var owned_out=item.get("permanent",false) and int(item.have)>0
	var note=item.text if int(item.have)==0 else ("You have it" if owned_out else "%s · You have %d"%[item.text,int(item.have)])
	wrapped(panel,note,Rect2(dr.position+Vector2(130,54)*u,Vector2(dr.size.x-140*u,70*u)),int(16*u))
	var can=app.game.state.coins>=int(item.price) and not owned_out
	var br=Rect2(dr.position.x+dr.size.x*0.2,dr.end.y-74*u,dr.size.x*0.6,62*u)
	var buy=ConceptScreen.button(panel,"Buy_"+String(item.full).to_pascal_case(),P45,"buy",br,func(): shop_buy(item))
	buy.disabled=not can
	if not can: buy.modulate=Color(1,1,1,0.6)
	var label="Owned" if owned_out else "Buy %d"%int(item.price)
	buy.text=label
	ConceptScreen.words(buy,label,Rect2(br.size.y*0.6,0,br.size.x-br.size.y*0.7,br.size.y),int(28*u))

func p45_shop() -> void:
	if portrait():
		p45_shop_portrait()
		return
	var f=p32_frame(Rect2(105,28,1525,862))
	var k: float=f[0]
	var c=logical_size*0.5 if f[1]==Vector2(836,470) else safe.get_center()
	var o: Vector2=f[1]
	var R=func(x: float,y: float,w: float,h: float) -> Rect2: return Rect2(c+(Vector2(x,y)-o)*k,Vector2(w,h)*k)
	var panel=Control.new()
	panel.name="ShopPanel"
	panel.size=logical_size
	content.add_child(panel)
	ConceptScreen.piece(panel,P45,"board",R.call(105,150,1465,740),false)
	ConceptScreen.piece(panel,P45,"title",R.call(580,28,460,112),false)
	ConceptScreen.piece(panel,P45,"ic_stall",R.call(608,38,146,100))
	ConceptScreen.words(panel,"Shop",R.call(760,36,270,104),int(84*k)).name="ShopTitle"
	ConceptScreen.piece(panel,P45,"coins",R.call(1282,48,220,90),false)
	wallet_value=ConceptScreen.words(panel,str(app.game.state.coins),R.call(1372,48,120,90),int(48*k))
	var close=ConceptScreen.button(panel,"CloseShop",P45,"close",R.call(1528,44,98,98),app.show_home)
	close.tooltip_text="Close"
	var tabs=[["food","Food","ic_leaf",R.call(165,170,315,82)],["toys","Toys","ic_ball",R.call(495,174,305,78)],["room","Room","ic_house",R.call(815,174,275,78)]]
	for t in tabs:
		var id: String=t[0]
		var on=shop_tab==id
		var r: Rect2=t[3]
		var b=ConceptScreen.button(panel,"Tab_"+id,P45,"tab_on" if on else "tab",r,func():
			shop_tab=id
			shop_pick=""
			signature="";layout(logical_size,safe))
		b.tooltip_text=t[1]
		var font: Font=load(PetUI.MENU_FONT_PATH)
		var pts=int(44*k)
		var tw=font.get_string_size(t[1],HORIZONTAL_ALIGNMENT_LEFT,-1,pts).x
		var icon_s=r.size.y*0.6
		var x=(r.size.x-icon_s-14*k-tw)*0.5
		var ic=ConceptScreen.piece(b,P45,t[2],Rect2(x,(r.size.y-icon_s)*0.5,icon_s,icon_s))
		if on: ic.modulate=Color("fff6e0")
		ConceptScreen.words(b,t[1],Rect2(x+icon_s+14*k,0,tw+8,r.size.y),pts,Color("fff6e0") if on else PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)
	var items: Array=shop_items(shop_tab)
	if shop_pick.is_empty() or not items.any(func(it): return it.id==shop_pick): shop_pick=items[0].id if not items.is_empty() else ""
	ConceptScreen.piece(panel,P45,"side",R.call(1100,236,455,636),false)
	var xs=[128,378,622,866]
	for n in mini(items.size(),8):
		var it: Dictionary=items[n]
		var on=it.id==shop_pick
		var pick: String=it.id
		var cr: Rect2=R.call(xs[n%4]+(0 if on else 4),(268 if n<4 else 582)+(0 if on else 6),240 if on else 230,306 if on else 290)
		var card=ConceptScreen.button(panel,"Card_"+String(it.id),P45,"card_on" if on else "card",cr,func():
			shop_pick=pick
			signature="";layout(logical_size,safe))
		var cw=cr.size.x
		var ch=cr.size.y
		var art: String=P45_ART.get(it.id,"")
		if art.is_empty(): stex(card,it.icon,Rect2(cw*0.14,ch*0.08,cw*0.72,ch*0.55))
		else: ConceptScreen.piece(card,P45,art,Rect2(cw*0.12,ch*0.08,cw*0.76,ch*0.55))
		ConceptScreen.words(card,it.name,Rect2(0,ch*0.64,cw,ch*0.12),int(32*k))
		var pr=Rect2(cw*0.2,ch*0.79,cw*0.6,ch*0.15)
		ConceptScreen.piece(card,P45,"price",pr,false)
		var cs=pr.size.y*0.82
		ConceptScreen.piece(card,P45,"coin",Rect2(pr.position+Vector2(pr.size.x*0.22-cs*0.5,(pr.size.y-cs)*0.5),Vector2(cs,cs)))
		ConceptScreen.words(card,str(it.price),Rect2(pr.position+Vector2(pr.size.x*0.4,0),Vector2(pr.size.x*0.5,pr.size.y)),int(30*k))
	if items.is_empty():
		wrapped(panel,"Room things are coming soon: beds, plants, lamps and rugs for %s's room."%app.game.pet().name,R.call(1130,300,395,420),int(34*k))
		return
	var item: Dictionary=items.filter(func(it): return it.id==shop_pick)[0]
	var big: String=P45_ART.get(item.id,"")
	if big.is_empty(): stex(panel,item.icon,R.call(1160,275,340,320))
	else: ConceptScreen.piece(panel,P45,big,R.call(1150,270,360,330))
	ConceptScreen.words(panel,item.full,R.call(1120,600,415,80),int(60*k)).name="ItemName"
	var owned_out=item.get("permanent",false) and int(item.have)>0
	var note=item.text if int(item.have)==0 else ("You have it" if owned_out else "%s · You have %d"%[item.text,int(item.have)])
	wrapped(panel,note,R.call(1125,664,405,62),int(28*k))
	var can=app.game.state.coins>=int(item.price) and not owned_out
	var br: Rect2=R.call(1135,734,385,108)
	var buy=ConceptScreen.button(panel,"Buy_"+String(item.full).to_pascal_case(),P45,"buy",br,func(): shop_buy(item))
	buy.disabled=not can
	if not can: buy.modulate=Color(1,1,1,0.6)
	var label="Owned" if owned_out else "Buy %d"%int(item.price)
	buy.text=label
	var font: Font=load(PetUI.MENU_FONT_PATH)
	var pts=int(52*k)
	var lw=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,pts).x
	var lead=br.size.y*0.62 if not owned_out else 0.0
	ConceptScreen.words(buy,label,Rect2((br.size.x-lw+lead)*0.5,0,lw+6,br.size.y),pts,PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)

func build_shop() -> void:
	if ArtStyle.paper and ResourceLoader.exists("res://assets/ui/shop-p32/board.png"):
		p45_shop()
		return
	var L: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SHOP_ART+"layout.json"))
	var bw=float(L.size[0])
	var bh=float(L.size[1])
	var k=minf((safe.size.x-4)/bw,(safe.size.y-4)/bh)
	var R=func(r: Array) -> Rect2: return Rect2(Vector2(r[0],r[1])*k,Vector2(r[2],r[3])*k)
	var panel=Control.new()
	panel.name="ShopPanel"
	panel.position=safe.get_center()-Vector2(bw,bh)*k*0.5
	panel.size=Vector2(bw,bh)*k
	content.add_child(panel)
	stex(panel,SHOP_ART+"base.png",Rect2(Vector2.ZERO,panel.size),false)
	var tl: Array=L.get("title",[652,37,200,83])
	var shop_title=text(panel,"Shop",R.call(tl),kp(66,k))
	if L.has("coin_icon"): stex(panel,SHOP_ART+"coin.png",R.call(L.coin_icon))
	shop_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	wallet_value=centered(panel,"",R.call(L.coins),kp(44,k))
	var cl: Array=L.close
	flat_button(panel,"CloseShop",Rect2(Vector2(cl[0]-cl[2],cl[1]-cl[2])*k,Vector2.ONE*cl[2]*2*k),app.show_home)
	var font: Font=load(PetUI.MENU_FONT_PATH)
	var tabs=[["food","Food",BAG_ART+"items/apple.png"],["toys","Toys",SHOP_ART+"beach_ball.png"],["room","Room",SHOP_ART+"armchair.png"]]
	for i in 3:
		var r: Rect2=R.call(L.tabs[i])
		var id: String=tabs[i][0]
		var b=flat_button(panel,"Tab_"+id,r,func():
			shop_tab=id
			shop_pick=""
			signature="";layout(logical_size,safe))
		stex(b,SHOP_ART+("tab_on.png" if shop_tab==id else "tab.png"),Rect2(Vector2.ZERO,r.size),false)
		var pts=kp(46,k)
		var icon_s=r.size.y*0.62
		var tw=font.get_string_size(tabs[i][1],HORIZONTAL_ALIGNMENT_LEFT,-1,pts).x
		var x=(r.size.x-icon_s-12*k-tw)*0.5
		stex(b,tabs[i][2],Rect2(x,(r.size.y-icon_s)*0.5,icon_s,icon_s))
		var lab=text(b,tabs[i][1],Rect2(x+icon_s+12*k,0,tw+8,r.size.y),pts)
		lab.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		lab.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var items: Array=shop_items(shop_tab)
	if shop_pick.is_empty() or not items.any(func(it): return it.id==shop_pick): shop_pick=items[0].id if not items.is_empty() else ""
	var cw=float(L.card[0])*k
	var ch=float(L.card[1])*k
	for n in mini(items.size(),8):
		var it: Dictionary=items[n]
		var pos=Vector2(float(L.cards_x[n%4]),float(L.cards_y[int(n/4)]))*k
		var on=it.id==shop_pick
		var pick: String=it.id
		var card=flat_button(panel,"Card_"+String(it.id),Rect2(pos,Vector2(cw,ch)),func():
			shop_pick=pick
			signature="";layout(logical_size,safe))
		stex(card,SHOP_ART+("card_on.png" if on else "card.png"),Rect2(Vector2.ZERO,card.size),false)
		stex(card,it.icon,Rect2(cw*0.14,ch*0.1,cw*0.72,ch*0.46))
		var nm=centered(card,it.name,Rect2(0,ch*0.58,cw,ch*0.13),kp(28,k))
		nm.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var pr=Rect2(cw*0.1,ch*0.75,cw*0.8,ch*0.17)
		stex(card,SHOP_ART+"price.png",pr,false)
		var cs=pr.size.y*0.7
		stex(card,SHOP_ART+"coin.png",Rect2(pr.position+Vector2(pr.size.x*0.24-cs*0.5,(pr.size.y-cs)*0.5),Vector2(cs,cs)))
		var pv=centered(card,str(it.price),Rect2(pr.position+Vector2(pr.size.x*0.38,0),Vector2(pr.size.x*0.5,pr.size.y)),kp(30,k))
		pv.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var d: Rect2=R.call(L.detail)
	if items.is_empty():
		var none=centered(panel,"Room things are coming soon: beds, plants, lamps and rugs for %s's room."%app.game.pet().name,d.grow(-24*k),kp(28,k))
		none.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		return
	var item: Dictionary=items.filter(func(it): return it.id==shop_pick)[0]
	var pic: Array=L.picture
	stex(panel,BAG_ART+"glow.png",Rect2(Vector2(pic[0]-pic[2]*1.4,pic[1]-pic[2]*1.2)*k,Vector2(pic[2]*2.8,pic[2]*2.4)*k))
	stex(panel,item.icon,Rect2(Vector2(pic[0]-pic[2],pic[1]-pic[2])*k,Vector2.ONE*pic[2]*2*k))
	centered(panel,item.full,Rect2(Vector2(d.position.x,float(L.name_y)*k-28*k),Vector2(d.size.x,56*k)),kp(46,k)).name="ItemName"
	var line=centered(panel,item.text,Rect2(Vector2(d.position.x+16*k,float(L.text_y)*k-20*k),Vector2(d.size.x-32*k,44*k)),kp(26,k))
	line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if L.has("divider"): stex(panel,SHOP_ART+"divider.png",R.call(L.divider))
	var owned_out=item.get("permanent",false) and int(item.have)>0
	centered(panel,("You have it" if owned_out else "You have %d"%int(item.have)),Rect2(Vector2(d.position.x,float(L.have_y)*k-22*k),Vector2(d.size.x,44*k)),kp(32,k))
	var br: Rect2=R.call(L.buy)
	var can=app.game.state.coins>=int(item.price) and not owned_out
	var buy=flat_button(panel,"Buy_"+String(item.full).to_pascal_case(),br,func(): shop_buy(item))
	buy.disabled=not can
	stex(buy,SHOP_ART+"buy.png",Rect2(Vector2.ZERO,br.size),false).modulate=Color.WHITE if can else Color(1,1,1,0.55)
	var label="Owned" if owned_out else "Buy · %d"%int(item.price)
	var pts=kp(44,k)
	var lw=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,pts).x
	var cs=br.size.y*0.5
	var x0=(br.size.x-lw-(0 if owned_out else cs+10*k))*0.5
	var bl=text(buy,label,Rect2(x0,0,lw+6,br.size.y),pts)
	bl.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	bl.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if not owned_out: stex(buy,SHOP_ART+"coin.png",Rect2(x0+lw+10*k,(br.size.y-cs)*0.5,cs,cs))

## A57 (P58): Decorate from concept P58 (decor-p32): glowing "+" spots in the
## room, the tray with item cards (the sun ball is placeable; the other room
## pieces arrive with the room makeover shop), close and Done.
func p58_decorate() -> void:
	# A compact tray so the rug (where toys go) stays in view above it.
	var k=pk()*0.72
	if portrait(): k=safe.size.x/1700.0
	app.home.decorating=true
	var tray=Rect2(safe.position.x+30*k,safe.end.y-300*k,safe.size.x-60*k,290*k)
	var tp=Rect2(tray.position+Vector2(50,-75)*k,Vector2(330,95)*k)
	# The whole room, as in P58: the rug spots sit just above the tray.
	app.world.transform=Transform2D.IDENTITY
	ConceptScreen.slab(content,"decor-p32","tray",tray,0.2)
	ConceptScreen.piece(content,"decor-p32","title",tp,false)
	ConceptScreen.words(content,"Decorate",tp.grow_individual(-tp.size.x*0.14,0,-tp.size.x*0.14,0),int(54*k))
	var cancel=ConceptScreen.button(content,"Cancel","decor-p32","close",Rect2(tray.end.x-95*k,tray.position.y+15*k,75*k,75*k),func():
		app.home.decorating=false
		app.home.toy_preview=-1
		app.show_home())
	cancel.tooltip_text="Close"
	cancel.text="Cancel"
	var owned=app.game.state.inventory.get("ball_sun",0)>=1
	var items=[["sun_ball","Sun ball"],["cushion","Paw cushion"],["lamp","Leaf lamp"],["pot","Flower pot"],["picture","Wall picture"]]
	var cw=210.0*k
	for i in items.size():
		var r=Rect2(tray.position+Vector2(40+i*(230),25)*k,Vector2(cw,250*k))
		var on=i==0 and app.home.toy_preview>=0
		ConceptScreen.piece(content,"decor-p32","card_on" if on else "card",r,false)
		var pic=ConceptScreen.piece(content,"decor-p32",items[i][0],Rect2(r.position+Vector2(r.size.x*0.18,r.size.y*0.06),Vector2(r.size.x*0.64,r.size.y*0.42)))
		ConceptScreen.words(content,items[i][1],Rect2(r.position+Vector2(0,r.size.y*0.5),Vector2(r.size.x,r.size.y*0.14)),int(30*k))
		var pr=Rect2(r.position+Vector2(r.size.x*0.12,r.size.y*0.77),Vector2(r.size.x*0.76,r.size.y*0.17))
		if i==0 and owned:
			ConceptScreen.words(content,"Owned",Rect2(r.position+Vector2(0,r.size.y*0.63),Vector2(r.size.x,r.size.y*0.13)),int(26*k),Color("3e7a2c"))
			var placed=app.home.placed_toy_slot()
			if placed>=0 and app.home.toy_preview<0:
				ConceptScreen.button(content,"Pack","decor-p32","place",pr,func():
					if app.game.place_toy(-1): app.show_home(),"Pack",null,int(30*k),Color("fff6e0"))
			else: ConceptScreen.words(content,"Tap a spot",pr,int(24*k))
		elif i==0:
			ConceptScreen.button(content,"Shop","decor-p32","price",pr,app.show_shop,"Shop",null,int(26*k))
		else:
			pic.modulate=Color(1,1,1,0.55)
			ConceptScreen.words(content,"Coming soon",Rect2(r.position+Vector2(0,r.size.y*0.66),Vector2(r.size.x,r.size.y*0.26)),int(24*k),Color("7a6a55"))
	var done=ConceptScreen.button(content,"Confirm","decor-p32","done",Rect2(tray.end.x-300*k,tray.position.y+120*k,265*k,100*k),func():
		app.home.decorating=false
		if app.home.toy_preview>=0 and app.game.place_toy(app.home.toy_preview):
			app.show_home()
			app.home.react_to("toy")
		else: app.show_home())
	done.text="Confirm"
	ConceptScreen.words(done,"Done",Rect2(Vector2.ZERO,done.size),int(48*k),Color("fff6e0"))
	# The "+" spots in the room are buttons (same names as before for tests).
	if owned:
		var names=["On the rug","By the bed","By the window"]
		for i in 3:
			var at: Vector2=app.home.toy_position(i)*app.world.transform.get_scale()+app.world.transform.origin
			var sb=ConceptScreen.button(content,names[i].to_pascal_case(),"decor-p32","plus",Rect2(at-Vector2(30,60),Vector2(60,60)),func(): app.home.toy_preview=i;signature="";layout(logical_size,safe))
			sb.text=names[i]
			sb.tooltip_text=names[i]
			sb.get_node("Face").modulate.a=0.0
			decorate_buttons.append(sb)

func build_decorate() -> void:
	if ArtStyle.paper and ResourceLoader.exists("res://assets/ui/decor-p32/tray.png") and is_instance_valid(app.home) and app.home.p43:
		p58_decorate()
		return
	var bounds=page_bounds()
	var panel_rect=Rect2(bounds.position.x,safe.end.y-(250 if portrait() else 180),bounds.size.x,250 if portrait() else 180)
	var panel=CareArt.panel(content,panel_rect)
	text(panel,"Choose a place for the ball",Rect2(20,12,panel_rect.size.x-40,36),24)
	if app.game.state.inventory.get("ball_sun",0)<1:
		text(panel,"The ball is in the Shop. Your care furniture is free.",Rect2(20,56,panel_rect.size.x-40,54),18)
		button(panel,"Shop",Rect2(20,panel_rect.size.y-74,140,56),app.show_shop,"shop")
		button(panel,"Back",Rect2(172,panel_rect.size.y-74,140,56),app.show_home,"back")
		return
	var gap=8.0
	var width=(panel_rect.size.x-40-gap*2)/3
	for i in range(3):
		var b=button(panel,["On the rug","By the bed","By the window"][i],Rect2(20+i*(width+gap),60,width,56),func(): app.home.toy_preview=i)
		b.add_theme_font_size_override("font_size",15 if portrait() else 20)
		decorate_buttons.append(b)
	var actions_y=132 if portrait() else 120
	var actions_w=(panel_rect.size.x-48)/3
	button(panel,"Confirm",Rect2(20,actions_y,actions_w,56),func():
		if app.home.toy_preview>=0 and app.game.place_toy(app.home.toy_preview): app.show_home();app.home.react_to("toy"),"",true)
	button(panel,"Cancel",Rect2(24+actions_w,actions_y,actions_w,56),app.show_home)
	button(panel,"Pack",Rect2(28+actions_w*2,actions_y,actions_w,56),func():
		if app.game.place_toy(-1): app.show_home())

## A57 (P55): Play together from concept P55 (games-p32): Catch the Ball
## card with its picture, line, Play and the reward strip; two locked cards.
func p55_games() -> void:
	var f=p32_frame(Rect2(20,20,1640,880))
	var k: float=f[0]
	var c=logical_size*0.5 if f[1]==Vector2(836,470) else safe.get_center()
	var o: Vector2=f[1]
	var R=func(x: float,y: float,w: float,h: float) -> Rect2: return Rect2(c+(Vector2(x,y)-o)*k,Vector2(w,h)*k)
	var bg=TextureRect.new()
	bg.texture=ConceptScreen.tex("ball-p32","garden")
	bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size=logical_size
	bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(bg)
	var back=ConceptScreen.button(content,"BackToMyPet","collect-p32","back",R.call(30,25,120,120),app.show_home)
	back.tooltip_text="Back to My Pet"
	var tr: Rect2=R.call(505,30,680,165)
	ConceptScreen.piece(content,"games-p32","title",tr,false)
	ConceptScreen.words(content,"Play together",tr.grow_individual(-tr.size.x*0.14,-tr.size.y*0.18,-tr.size.x*0.14,-tr.size.y*0.22),int(84*k))
	var cr: Rect2=R.call(1435,30,210,95)
	ConceptScreen.piece(content,"result-p32","coins",cr,false)
	wallet_value=ConceptScreen.words(content,str(app.game.state.coins),Rect2(cr.position.x+cr.size.x*0.42,cr.position.y,cr.size.x*0.52,cr.size.y),int(46*k))
	var cards=[["Catch the Ball","pic_ball",115,true],["Hide and Seek","pic_hide",630,false],["Treasure Dig","pic_dig",1115,false]]
	for e in cards:
		var x: float=e[2]
		ConceptScreen.piece(content,"games-p32","card",R.call(x,230,470,590),false)
		ConceptScreen.piece(content,"games-p32","card_title",R.call(x+20,250,430,95),false)
		ConceptScreen.words(content,e[0],R.call(x+70,255,330,85),int(46*k))
		ConceptScreen.piece(content,"games-p32",e[1],R.call(x+25,340,420,330),false)
		if e[3]:
			ConceptScreen.words(content,"Foxy brings it back",R.call(x+30,670,410,50),int(30*k))
			var play=ConceptScreen.button(content,"CatchTheBall","games-p32","play",R.call(x+60,720,360,90),app.show_ball,"Play",null,int(56*k),Color("fff6e0"))
			play.tooltip_text="Catch the Ball"
			var rr: Rect2=R.call(x+45,825,390,75)
			ConceptScreen.piece(content,"games-p32","reward",rr,false)
			ConceptScreen.piece(content,"games-p32","heart",R.call(x+70,832,60,58))
			ConceptScreen.words(content,"+ Happiness",R.call(x+135,825,145,75),int(26*k),PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)
			ConceptScreen.piece(content,"games-p32","paw",R.call(x+275,835,45,48))
			ConceptScreen.words(content,"+ Bond",R.call(x+325,825,100,75),int(26*k),PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)
		else:
			var info=ConceptScreen.piece(content,"games-p32","info",R.call(x+45,700,380,95),false)
			info.modulate=Color(0.96,0.92,0.84)
			ConceptScreen.words(content,"Coming later",R.call(x+45,700,380,95),int(32*k)).name="Locked"

## A57 (P54): Collection from concept P54 (collect-p32): My friends with Foxy
## and two friends to come; Memories as stickers (picnic, windmill).
func p54_collection() -> void:
	var f=p32_frame(Rect2(20,20,1640,880))
	var k: float=f[0]
	var c=logical_size*0.5 if f[1]==Vector2(836,470) else safe.get_center()
	var o: Vector2=f[1]
	var R=func(x: float,y: float,w: float,h: float) -> Rect2: return Rect2(c+(Vector2(x,y)-o)*k,Vector2(w,h)*k)
	var dim=ColorRect.new()
	dim.color=Color(.05,.04,.02,.25)
	dim.size=logical_size
	content.add_child(dim)
	var back=ConceptScreen.button(content,"BackToMyPet","collect-p32","back",R.call(25,35,112,112),app.show_home)
	back.tooltip_text="Back to My Pet"
	ConceptScreen.slab(content,"result-p32","board",R.call(445,150,1200,720),0.2)
	var seam=ColorRect.new()
	seam.color=Color(0.55,0.42,0.25,0.18)
	var sr0: Rect2=R.call(905,210,3,600)
	seam.position=sr0.position
	seam.size=sr0.size
	seam.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(seam)
	var tr: Rect2=R.call(500,30,780,140)
	ConceptScreen.piece(content,"collect-p32","title",tr,false)
	ConceptScreen.words(content,"Collection",tr.grow_individual(-tr.size.x*0.18,-tr.size.y*0.12,-tr.size.x*0.18,-tr.size.y*0.16),int(96*k))
	var cr: Rect2=R.call(1405,32,220,92)
	ConceptScreen.piece(content,"result-p32","coins",cr,false)
	wallet_value=ConceptScreen.words(content,str(app.game.state.coins),Rect2(cr.position.x+cr.size.x*0.42,cr.position.y,cr.size.x*0.52,cr.size.y),int(46*k))
	for sec in [["My friends",505],["Memories",1090]]:
		var sr: Rect2=R.call(sec[1],195,390,85)
		ConceptScreen.piece(content,"collect-p32","section",sr,false)
		ConceptScreen.words(content,sec[0],sr.grow_individual(-sr.size.x*0.2,0,-sr.size.x*0.2,0),int(42*k))
	var pet=app.game.pet()
	ConceptScreen.piece(content,"collect-p32","portrait",R.call(565,275,255,240))
	ConceptScreen.words(content,pet.name,R.call(530,490,330,60),int(48*k))
	ConceptScreen.words(content,age_caption(),R.call(530,535,330,40),int(28*k))
	for lk in [["locked_cat",505],["locked_pup",705]]:
		ConceptScreen.piece(content,"collect-p32",lk[0],R.call(lk[1],575,180,175))
		ConceptScreen.words(content,"Coming later",R.call(lk[1]-10,740,200,40),int(26*k))
	var stickers=[["picnic_sticker","Picnic together","sticker_picnic"],["windmill_badge","Windmill delivery","sticker_windmill"]]
	for i in 6:
		var x=950+(i%3)*225
		var y=300+int(i/3)*230
		var e=stickers[i] if i<stickers.size() else []
		var have=not e.is_empty() and e[0] in app.game.state.discovered_ids
		if have:
			ConceptScreen.piece(content,"collect-p32","slot",R.call(x,y,210,210),false)
			ConceptScreen.piece(content,"collect-p32",e[2],R.call(x+15,y+10,180,150))
			ConceptScreen.words(content,e[1],R.call(x,y+160,210,40),int(24*k))
		else: ConceptScreen.piece(content,"collect-p32","slot_empty",R.call(x,y,210,210),false)
	var b=ConceptScreen.button(content,"BackPlank","collect-p32","plank",R.call(960,755,650,105),app.show_home,"Back to My Pet",null,int(54*k),Color("fff6e0"))
	b.tooltip_text="Back to My Pet"

## Phone upright: the three game cards stacked (Catch the Ball first).
func p55_games_portrait() -> void:
	var W=safe.size.x
	var u=W/400.0
	var x0=safe.position.x
	var y=safe.position.y
	var bg=TextureRect.new()
	bg.texture=ConceptScreen.tex("ball-p32","garden")
	bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size=logical_size
	bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(bg)
	var back=ConceptScreen.button(content,"BackToMyPet","collect-p32","back",Rect2(x0,y,52*u,52*u),app.show_home)
	back.tooltip_text="Back to My Pet"
	var tr=Rect2(x0+58*u,y,W-62*u,60*u)
	ConceptScreen.piece(content,"games-p32","title",tr,false)
	ConceptScreen.words(content,"Play together",tr.grow_individual(-tr.size.x*0.14,-tr.size.y*0.12,-tr.size.x*0.14,-tr.size.y*0.2),int(32*u))
	y+=68*u
	var big=Rect2(x0+W*0.04,y,W*0.92,minf(safe.end.y-y-170*u,W*1.05))
	ConceptScreen.slab(content,"games-p32","card",big,0.12)
	ConceptScreen.piece(content,"games-p32","card_title",Rect2(big.position+Vector2(big.size.x*0.1,8*u),Vector2(big.size.x*0.8,48*u)),false)
	ConceptScreen.words(content,"Catch the Ball",Rect2(big.position+Vector2(big.size.x*0.16,8*u),Vector2(big.size.x*0.68,46*u)),int(26*u))
	ConceptScreen.piece(content,"games-p32","pic_ball",Rect2(big.position+Vector2(12*u,60*u),Vector2(big.size.x-24*u,big.size.y-200*u)),false)
	ConceptScreen.words(content,"Foxy brings it back",Rect2(big.position.x,big.end.y-138*u,big.size.x,30*u),int(20*u))
	var play=ConceptScreen.button(content,"CatchTheBall","games-p32","play",Rect2(big.position.x+big.size.x*0.15,big.end.y-106*u,big.size.x*0.7,60*u),app.show_ball,"Play",null,int(34*u),Color("fff6e0"))
	play.tooltip_text="Catch the Ball"
	var rr=Rect2(big.position.x+big.size.x*0.12,big.end.y-42*u,big.size.x*0.76,36*u)
	ConceptScreen.piece(content,"games-p32","reward",rr,false)
	ConceptScreen.piece(content,"games-p32","heart",Rect2(rr.position+Vector2(10,4)*u,Vector2(28,28)*u))
	ConceptScreen.words(content,"+ Happiness",Rect2(rr.position+Vector2(42,0)*u,Vector2(110,36)*u),int(16*u),PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)
	ConceptScreen.piece(content,"games-p32","paw",Rect2(rr.position+Vector2(160,6)*u,Vector2(24,24)*u))
	ConceptScreen.words(content,"+ Bond",Rect2(rr.position+Vector2(188,0)*u,Vector2(80,36)*u),int(16*u),PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)
	y=big.end.y+10*u
	var cw=(W-10*u)/2.0
	var ch=safe.end.y-y
	for i in 2:
		var e=[["Hide and Seek","pic_hide"],["Treasure Dig","pic_dig"]][i]
		var r=Rect2(x0+i*(cw+10*u),y,cw,ch)
		ConceptScreen.slab(content,"games-p32","card",r,0.12)
		ConceptScreen.words(content,e[0],Rect2(r.position+Vector2(0,6*u),Vector2(r.size.x,28*u)),int(18*u))
		ConceptScreen.piece(content,"games-p32",e[1],Rect2(r.position+Vector2(8*u,36*u),Vector2(r.size.x-16*u,r.size.y-80*u)),false)
		ConceptScreen.words(content,"Coming later",Rect2(r.position.x,r.end.y-40*u,r.size.x,34*u),int(16*u)).name="Locked"

## Phone upright: Foxy and the friends to come, then the memory stickers.
func p54_collection_portrait() -> void:
	var W=safe.size.x
	var u=W/400.0
	var x0=safe.position.x
	var y=safe.position.y
	var dim=ColorRect.new()
	dim.color=Color(.05,.04,.02,.25)
	dim.size=logical_size
	content.add_child(dim)
	var back=ConceptScreen.button(content,"BackToMyPet","collect-p32","back",Rect2(x0,y,52*u,52*u),app.show_home)
	back.tooltip_text="Back to My Pet"
	var tr=Rect2(x0+58*u,y,W-62*u,58*u)
	ConceptScreen.piece(content,"collect-p32","title",tr,false)
	ConceptScreen.words(content,"Collection",tr.grow_individual(-tr.size.x*0.18,-tr.size.y*0.1,-tr.size.x*0.18,-tr.size.y*0.14),int(34*u))
	y+=64*u
	var board=Rect2(x0,y,W,safe.end.y-y)
	ConceptScreen.slab(content,"result-p32","board",board,0.2)
	var pet=app.game.pet()
	var sr=Rect2(x0+W*0.2,y+12*u,W*0.6,42*u)
	ConceptScreen.piece(content,"collect-p32","section",sr,false)
	ConceptScreen.words(content,"My friends",sr.grow_individual(-sr.size.x*0.2,0,-sr.size.x*0.2,0),int(22*u))
	ConceptScreen.piece(content,"collect-p32","portrait",Rect2(x0+20*u,y+62*u,120*u,114*u))
	ConceptScreen.words(content,pet.name,Rect2(x0+20*u,y+176*u,120*u,30*u),int(24*u))
	ConceptScreen.words(content,age_caption(),Rect2(x0+10*u,y+204*u,140*u,22*u),int(14*u))
	for i in 2:
		var lx=x0+160*u+i*112*u
		ConceptScreen.piece(content,"collect-p32",["locked_cat","locked_pup"][i],Rect2(lx,y+80*u,96*u,94*u))
		ConceptScreen.words(content,"Coming later",Rect2(lx-8*u,y+178*u,112*u,24*u),int(14*u))
	y+=236*u
	var mr=Rect2(x0+W*0.2,y,W*0.6,42*u)
	ConceptScreen.piece(content,"collect-p32","section",mr,false)
	ConceptScreen.words(content,"Memories",mr.grow_individual(-mr.size.x*0.2,0,-mr.size.x*0.2,0),int(22*u))
	y+=50*u
	var stickers=[["picnic_sticker","Picnic together","sticker_picnic"],["windmill_badge","Windmill delivery","sticker_windmill"]]
	var sw=(W-40*u)/3.0
	for i in 6:
		var x=x0+10*u+(i%3)*(sw+10*u)
		var yy=y+int(i/3)*(sw+10*u)
		var e=stickers[i] if i<stickers.size() else []
		var have=not e.is_empty() and e[0] in app.game.state.discovered_ids
		if have:
			ConceptScreen.piece(content,"collect-p32","slot",Rect2(x,yy,sw,sw),false)
			ConceptScreen.piece(content,"collect-p32",e[2],Rect2(x+sw*0.08,yy+sw*0.04,sw*0.84,sw*0.68))
			ConceptScreen.words(content,e[1],Rect2(x,yy+sw*0.74,sw,sw*0.2),int(12*u))
		else: ConceptScreen.piece(content,"collect-p32","slot_empty",Rect2(x,yy,sw,sw),false)
	var b=ConceptScreen.button(content,"BackPlank","collect-p32","plank",Rect2(x0+W*0.08,safe.end.y-72*u,W*0.84,62*u),app.show_home,"Back to My Pet",null,int(28*u),Color("fff6e0"))
	b.tooltip_text="Back to My Pet"

func build_games() -> void:
	if ArtStyle.paper and portrait() and ResourceLoader.exists("res://assets/ui/games-p32/card.png"):
		p55_games_portrait()
		return
	if ArtStyle.paper and not portrait() and ResourceLoader.exists("res://assets/ui/games-p32/card.png"):
		p55_games()
		return
	var column=scroll_card(page_bounds())
	flow_label(column,"Play together",30)
	flow_label(column,"You lead. Foxy catches and brings the ball back.",20)
	flow_button(column,"Catch the Ball",app.show_ball,"play",true)
	flow_label(column,"Practice first, then ten throws. A game together earns happiness and bond.",18)
	flow_button(column,"Back to My Pet",app.show_home,"back")

func build_collection() -> void:
	if ArtStyle.paper and portrait() and ResourceLoader.exists("res://assets/ui/collect-p32/board.png"):
		p54_collection_portrait()
		return
	if ArtStyle.paper and not portrait() and ResourceLoader.exists("res://assets/ui/collect-p32/board.png"):
		p54_collection()
		return
	var column=scroll_card(page_bounds())
	flow_label(column,"Your little family",28)
	flow_label(column,app.game.pet().name+" · Foxy · "+app.game.pet().growth_stage.capitalize(),24)
	var portrait_box=Control.new()
	portrait_box.custom_minimum_size=Vector2(0,170)
	column.add_child(portrait_box)
	fox_portrait(portrait_box,Rect2(0,0,160,170))
	flow_label(column,"Adventure memories",26)
	var memories=0
	for entry in [["picnic_sticker","Picnic together"],["windmill_badge","Windmill delivery"]]:
		if entry[0] in app.game.state.discovered_ids:
			flow_label(column,entry[1]+" · Saved",22)
			memories+=1
	if memories==0: flow_label(column,"Complete an adventure to keep a memory here.",18)
	flow_button(column,"Adventures",app.show_map,"map")
	flow_button(column,"Back to My Pet",app.show_home,"back")

const STEPS={"music_volume":[[25,"Quiet"],[50,"Soft"],[75,"Normal"],[100,"Loud"]],"sfx_volume":[[25,"Quiet"],[50,"Soft"],[75,"Normal"],[100,"Loud"]],"stick_size":[[85,"Small"],[100,"Medium"],[120,"Large"]],"control_opacity":[[50,"Light"],[75,"Medium"],[100,"Solid"]],"touch_size":[[52,"Small"],[60,"Medium"],[68,"Large"]],"touch_spacing":[[0,"Close"],[12,"Normal"],[24,"Wide"]],"touch_raise":[[0,"Low"],[16,"Middle"],[32,"High"]]}
## A55 (P15) icons for the settings rows.
const PAPER_SETTING_ICON={"speaker":["settings-paper","ic_sound"],"music":["settings-paper","ic_music"],"voice":["settings-paper","ic_voice"],
	"world":["menu-paper","ic_map"],"hint":["settings-paper","ic_hint"],"star":["settings-paper","ic_hint"],"map":["menu-paper","ic_map"],
	"motion":["settings-paper","ic_motion"],"hand":["paper-v1","ic_use"],"controller":["settings-paper","ic_controls"],"right":["settings-paper","ic_controls"],
	"up":["paper-v1","ic_jump"],"sense":["settings-paper","ic_timing"],"left":["settings-paper","ic_controls"],"heart":["result-paper","heart"]}
func setting_row(column: VBoxContainer, icon: String, caption: String) -> Control:
	if p42():
		# P42 row: navy icon, caption, control at the right, a faint line under.
		var u=p42_row
		var qrow=Control.new()
		qrow.custom_minimum_size=Vector2(0,u)
		qrow.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		column.add_child(qrow)
		ConceptScreen.piece(qrow,P42,P42_ICON.get(icon,"ic_bulb"),Rect2(2,u*0.22,u*0.56,u*0.56))
		var ql=ConceptScreen.words(qrow,caption,Rect2(u*0.85,0,200,u),int(u*0.36),PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)
		ql.name="Caption"
		var line=ColorRect.new()
		line.color=Color(0.45,0.36,0.22,0.16)
		line.mouse_filter=Control.MOUSE_FILTER_IGNORE
		qrow.add_child(line)
		qrow.resized.connect(func(): line.position=Vector2(0,qrow.size.y-1);line.size=Vector2(qrow.size.x,1.5))
		return qrow
	if ArtStyle.paper:
		var prow=Control.new()
		prow.custom_minimum_size=Vector2(0,56)
		prow.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		column.add_child(prow)
		var ic: Array=PAPER_SETTING_ICON.get(icon,["settings-paper","ic_hint"])
		ConceptScreen.piece(prow,ic[0],ic[1],Rect2(0,8,40,40))
		var pl=ConceptScreen.words(prow,caption,Rect2(50,0,200,56),22,PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)
		pl.name="Caption"
		return prow
	var row=Control.new()
	row.custom_minimum_size=Vector2(0,50)
	row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_child(row)
	CareArt.picture(row,icon,Rect2(0,9,32,32))
	var label=text(row,caption,Rect2(42,0,200,50),20)
	label.name="Caption"
	return row
## The setting name uses the space left of its control, shrinking if needed.
func fit_caption(row: Control, control_w: float) -> void:
	var label: Label=row.get_node("Caption")
	label.size.x=maxf(60.0,row.size.x-label.position.x-control_w-8)
	label.clip_text=true
	PetUI.fit_points(label,label.size.x,int(p42_row*0.36) if p42() else (22 if ArtStyle.paper else 20),13)
func toggle_setting(column: VBoxContainer, icon: String, caption: String, key: String) -> void:
	var row=setting_row(column,icon,caption)
	var on: bool=app.game.preferences()[key]
	if p42():
		# P42 switch: green paper pill with the cream knob right when on.
		var u=p42_row
		var qs=ConceptScreen.button(row,caption.to_pascal_case(),P42,"toggle_on" if on else "toggle_off",Rect2(0,u*0.18,u*1.24,u*0.64),func():
			if not app.game.set_preference(key,not app.game.preferences()[key]): app.notify("Could not save that setting. Please try again.")
			Sound.apply_settings(app.game.preferences())
			signature="";layout(logical_size,safe))
		qs.text="On" if on else "Off"
		row.resized.connect(func():
			qs.position=Vector2(row.size.x-qs.size.x-4,u*0.18)
			fit_caption(row,qs.size.x))
		return
	if ArtStyle.paper:
		# P15 paper switch: orange "On" / grey "Off".
		var sw=ConceptScreen.button(row,caption.to_pascal_case(),"settings-paper","toggle_on" if on else "toggle_off",Rect2(0,6,104,44),func():
			if not app.game.set_preference(key,not app.game.preferences()[key]): app.notify("Could not save that setting. Please try again.")
			Sound.apply_settings(app.game.preferences())
			signature="";layout(logical_size,safe))
		ConceptScreen.words(sw.get_node("Content"),"On" if on else "Off",Rect2(10 if on else 44,0,50,44),20,PetUI.INK)
		row.resized.connect(func():
			sw.position=Vector2(row.size.x-sw.size.x,6)
			fit_caption(row,sw.size.x))
		return
	var pill=CareArt.toggle(row,on,func():
		if not app.game.set_preference(key,not app.game.preferences()[key]): app.notify("Could not save that setting. Please try again.")
		Sound.apply_settings(app.game.preferences())
		signature="";layout(logical_size,safe))
	pill.name=caption.to_pascal_case()
	row.resized.connect(func():
		pill.position=Vector2(row.size.x-pill.size.x,5)
		fit_caption(row,pill.size.x))
func step_setting(column: VBoxContainer, icon: String, caption: String, key: String) -> void:
	var row=setting_row(column,icon,caption)
	var options: Array=STEPS[key]
	var current=0
	for i in range(options.size()):
		if int(app.game.preferences()[key])==options[i][0]: current=i
	if ArtStyle.paper:
		paper_step(row,caption,key,options,current)
		return
	var stepper=CareArt.stepper(row,options[current][1],current>0,current<options.size()-1,func(direction: int):
		if not app.game.set_preference(key,options[clampi(current+direction,0,options.size()-1)][0]): app.notify("Could not save that setting. Please try again.")
		Sound.apply_settings(app.game.preferences())
		signature="";layout(logical_size,safe),160.0 if portrait() else 196.0)
	stepper.name=caption.to_pascal_case()
	row.resized.connect(func():
		stepper.position=Vector2(row.size.x-stepper.size.x,5)
		fit_caption(row,stepper.size.x))
## P15 controls: volumes are blue paper sliders with a percentage, other
## choices a cream stepper with blue arrows (Lower / Raise).
func paper_step(row: Control, caption: String, key: String, options: Array, current: int) -> void:
	var set_to=func(i: int):
		if not app.game.set_preference(key,options[clampi(i,0,options.size()-1)][0]): app.notify("Could not save that setting. Please try again.")
		Sound.apply_settings(app.game.preferences())
		signature="";layout(logical_size,safe)
	var holder=Control.new()
	holder.name=caption.to_pascal_case()
	row.add_child(holder)
	var kit="pause-p32" if p42() else "settings-paper"
	if p42() and key in ["music_volume","sfx_volume"]:
		# P42 slider: blue fill on a cream track, golden knob, no number.
		var u=p42_row
		holder.size=Vector2(p42_ctrl,u)
		var qt=Rect2(u*0.1,u*0.38,p42_ctrl-u*0.3,u*0.24)
		ConceptScreen.piece(holder,kit,"track",qt,false)
		var qv=float(current+1)/options.size()
		ConceptScreen.piece(holder,kit,"fill",Rect2(qt.position,Vector2(maxf(16,qt.size.x*qv),qt.size.y)),false)
		ConceptScreen.piece(holder,kit,"knob",Rect2(qt.position.x+qt.size.x*qv-u*0.24,u*0.26,u*0.48,u*0.48))
		for i in options.size():
			var qh=Button.new()
			qh.name="Lower" if i<current else ("Raise" if i>current else "Here%d"%i)
			qh.flat=true
			qh.focus_mode=Control.FOCUS_NONE
			for st in ["normal","hover","pressed","focus"]: qh.add_theme_stylebox_override(st,StyleBoxEmpty.new())
			qh.position=Vector2(qt.size.x*i/options.size(),0)
			qh.size=Vector2(qt.size.x/options.size(),u)
			var qi=i
			qh.pressed.connect(func(): set_to.call(qi))
			holder.add_child(qh)
	elif p42():
		# P42 stepper: two round paper arrows with the value between them.
		var u=p42_row
		var a=clampf(u*0.8,48.0,56.0)
		holder.size=Vector2(p42_ctrl,u)
		ConceptScreen.words(holder,String(options[current][1]),Rect2(a,0,p42_ctrl-a*2,u),int(u*0.32))
		for side in [-1,1]:
			var qa=ConceptScreen.button(holder,"Lower" if side<0 else "Raise",kit,"arrow_l" if side<0 else "arrow_r",Rect2(0 if side<0 else p42_ctrl-a,(u-a)*0.5,a,a),func(): set_to.call(current+side))
			qa.disabled=(current==0 and side<0) or (current==options.size()-1 and side>0)
			if qa.disabled: qa.modulate.a=0.4
	elif key in ["music_volume","sfx_volume"]:
		holder.size=Vector2(230,56)
		var tr=Rect2(0,18,170,20)
		ConceptScreen.piece(holder,"settings-paper","track",tr,false)
		var v=float(current+1)/options.size()
		ConceptScreen.piece(holder,"settings-paper","fill",Rect2(tr.position,Vector2(maxf(20,tr.size.x*v),tr.size.y)),false)
		ConceptScreen.piece(holder,"settings-paper","knob",Rect2(tr.position.x+tr.size.x*v-17,8,34,36))
		ConceptScreen.words(holder,"%d%%"%int(options[current][0]),Rect2(176,0,56,56),20)
		for i in options.size():
			var hit=Button.new()
			hit.name="Lower" if i<current else ("Raise" if i>current else "Here%d"%i)
			hit.flat=true
			hit.focus_mode=Control.FOCUS_NONE
			for st in ["normal","hover","pressed","focus"]: hit.add_theme_stylebox_override(st,StyleBoxEmpty.new())
			hit.position=Vector2(tr.size.x*i/options.size(),4)
			hit.size=Vector2(tr.size.x/options.size(),48)
			var idx=i
			hit.pressed.connect(func(): set_to.call(idx))
			holder.add_child(hit)
	else:
		holder.size=Vector2(200,56)
		ConceptScreen.piece(holder,"settings-paper","stepper",Rect2(0,4,200,48),false)
		ConceptScreen.words(holder,String(options[current][1]),Rect2(44,4,112,48),20)
		for side in [-1,1]:
			var arrow=Button.new()
			arrow.name="Lower" if side<0 else "Raise"
			arrow.flat=true
			arrow.focus_mode=Control.FOCUS_NONE
			for st in ["normal","hover","pressed","focus"]: arrow.add_theme_stylebox_override(st,StyleBoxEmpty.new())
			arrow.position=Vector2(0 if side<0 else 152,4)
			arrow.size=Vector2(48,48)
			arrow.disabled=(current==0 and side<0) or (current==options.size()-1 and side>0)
			arrow.pressed.connect(func(): set_to.call(current+side))
			holder.add_child(arrow)
	row.resized.connect(func():
		holder.position=Vector2(row.size.x-holder.size.x,0)
		fit_caption(row,holder.size.x))
func settings_section(column: VBoxContainer, title: String) -> void:
	var label=text(column,title,Rect2(0,0,0,0),22)
	label.custom_minimum_size=Vector2(0,40)
	label.vertical_alignment=VERTICAL_ALIGNMENT_BOTTOM
	label.add_theme_color_override("font_color",Color("8a4b1c"))
func settings_column(column: VBoxContainer) -> void:
	if p42():
		# P42 order: the concept's seven rows first, then the rest.
		step_setting(column,"music","Music","music_volume")
		step_setting(column,"speaker","Sound effects","sfx_volume")
		toggle_setting(column,"voice","Voices","voices")
		toggle_setting(column,"world","Minimap","show_minimap")
		toggle_setting(column,"hint","Hints","show_hints")
		step_setting(column,"hand","Button size","touch_size")
		toggle_setting(column,"left","Left-handed","left_handed")
		toggle_setting(column,"music","Music on","music")
		toggle_setting(column,"speaker","Sound on","sound")
		toggle_setting(column,"star","Guide arrow and goal","show_goal")
		toggle_setting(column,"map","Place names","place_names")
		toggle_setting(column,"motion","Reduced motion","reduced_motion")
		step_setting(column,"controller","Joystick size","stick_size")
		step_setting(column,"right","Spacing","touch_spacing")
		step_setting(column,"up","Height","touch_raise")
		step_setting(column,"sense","See-through","control_opacity")
		toggle_setting(column,"heart","Gentle mode","gentle")
		settings_tail(column)
		return
	if not ArtStyle.paper: text(column,"Settings",Rect2(0,0,0,0),28).custom_minimum_size=Vector2(0,40)
	settings_section(column,"Sound")
	toggle_setting(column,"speaker","Sound","sound")
	toggle_setting(column,"music","Music","music")
	step_setting(column,"music","Music volume","music_volume")
	step_setting(column,"speaker","Effects volume","sfx_volume")
	toggle_setting(column,"voice","Voices","voices")
	settings_section(column,"Screen and help")
	toggle_setting(column,"world","Minimap","show_minimap")
	toggle_setting(column,"hint","Hint bar","show_hints")
	toggle_setting(column,"star","Guide arrow and goal","show_goal")
	toggle_setting(column,"map","Place names","place_names")
	toggle_setting(column,"motion","Reduced motion","reduced_motion")
	settings_section(column,"Touch controls")
	step_setting(column,"hand","Button size","touch_size")
	step_setting(column,"controller","Joystick size","stick_size")
	step_setting(column,"right","Spacing","touch_spacing")
	step_setting(column,"up","Height","touch_raise")
	step_setting(column,"sense","See-through","control_opacity")
	toggle_setting(column,"left","Left-handed","left_handed")
	settings_section(column,"Play")
	toggle_setting(column,"heart","Gentle mode","gentle")
	settings_tail(column)
func settings_tail(column: VBoxContainer) -> void:
	flow_label(column,"Bumps and thorns push you back but never take a heart.",14)
	var controls=setting_row(column,"controller","Controls")
	var hint=text(controls,"Keyboard · Touch",Rect2(0,0,170,50),17)
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	controls.resized.connect(func(): hint.position.x=controls.size.x-hint.size.x)
	if not portrait():
		var keys=text(column,"Arrows / A D: move · Space: jump · E: use · Q: sense · B: bag · Esc: pause",Rect2(0,0,0,0),15)
		keys.custom_minimum_size=Vector2(0,40)
	var reset=flow_button(column,"Reset all settings",func():
		for key in SaveStore.DEFAULT_PREFERENCES: app.game.set_preference(key,SaveStore.DEFAULT_PREFERENCES[key])
		Sound.apply_settings(app.game.preferences())
		signature="";layout(logical_size,safe),"back")
	reset.name="ResetSettings"
	# Start the Green Meadows adventure again (two taps, so it can't happen by accident).
	if not app.game.state.is_empty() and app.game.state.quest_state.has("world"):
		var again=flow_button(column,"Are you sure? Tap again to restart" if confirm_reset else "Start Green Meadows again",func():
			if confirm_reset:
				confirm_reset=false
				if app.game.world_reset():
					app.notify("Green Meadows starts fresh. Your pet, coins and food are kept.")
					app.show_world()
					return
			else: confirm_reset=true
			signature="";layout(logical_size,safe),"back")
		again.name="RestartMeadows"
		flow_label(column,"Keeps %s, coins and food. Chests, keys and quests start over."%app.game.pet().name,14)

var confirm_reset=false
func pause_card(rect: Rect2, art_height: float, framed=true) -> void:
	# Inside the portrait scroll panel it is plain content (no frame in a frame).
	var panel: Control=CareArt.panel(content,rect) if framed else Control.new()
	if not framed:
		panel.position=rect.position
		panel.size=rect.size
		content.add_child(panel)
	panel.name="PauseCard"
	var heading=text(panel,"A little pause",Rect2(16,14,rect.size.x-32,40),30)
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	if compact():
		# Short landscape phones: title and the three actions only.
		var h=PetUI.H_BUTTON
		var gap=10.0
		var top=58+maxf(0,(rect.size.y-58-3*h-2*gap)/2)
		var entries=[["Resume",app.toggle_pause,"play",true],["My Pet",app.show_home,"paw",false],["Main menu",app.show_menu,"back",false]]
		var group=[]
		for i in range(entries.size()):
			var entry=entries[i]
			var b=button(panel,entry[0],Rect2(16,top+i*(h+gap),rect.size.x-32,h),entry[1],entry[2],entry[3])
			b.name=entry[0].to_pascal_case()
			group.append(b)
		PetUI.unify(group)
		return
	var line=text(panel,"Rest, adjust your settings, then get back to the adventure.",Rect2(20,54,rect.size.x-40,44),16)
	line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var friends=preload("res://scripts/ui/menu_friends.gd").new()
	friends.reduced_motion=app.game.preferences().reduced_motion
	friends.position=Vector2(rect.size.x*.14,102)
	friends.size=Vector2(rect.size.x*.72,art_height)
	panel.add_child(friends)
	var y=110+art_height
	var group=[]
	group.append(button(panel,"Resume",Rect2(20,y,rect.size.x-40,PetUI.H_PRIMARY),app.toggle_pause,"play",true))
	group.append(button(panel,"My Pet",Rect2(20,y+PetUI.H_PRIMARY+8,rect.size.x-40,PetUI.H_BUTTON),app.show_home,"paw"))
	group.append(button(panel,"Main menu",Rect2(20,y+PetUI.H_PRIMARY+PetUI.H_BUTTON+16,rect.size.x-40,PetUI.H_BUTTON),app.show_menu,"back"))
	for i in range(3): group[i].name=["Resume","MyPet","MainMenu"][i]
	PetUI.unify(group)

## Full settings on their own (from the main menu): one scrolling card.
## --- A55 Pause & Settings from concept P15 (assets/ui/settings-paper) ---
## --- A57 Pause & Settings from concept P42 (assets/ui/pause-p32) ---
const P42="pause-p32"
func p42() -> bool: return ArtStyle.paper and ResourceLoader.exists("res://assets/ui/pause-p32/panel.png")
const P42_ICON={"speaker":"ic_sound","music":"ic_music","voice":"ic_mic","world":"ic_pin","map":"ic_pin","hint":"ic_bulb","star":"ic_bulb","hand":"ic_resize","controller":"ic_resize","right":"ic_resize","up":"ic_resize","sense":"ic_resize","left":"ic_hand","motion":"ic_bulb","heart":"ic_hand"}
var p42_row=60.0
var p42_ctrl=204.0
func p42_board(left: bool) -> void:
	var dim=ColorRect.new()
	dim.color=Color(.05,.04,.02,.3)
	dim.size=logical_size
	content.add_child(dim)
	if mode=="pause" and not portrait(): p32_status(content)
	var k=minf(safe.size.x/1672.0,safe.size.y/941.0)*1.06
	if portrait(): k=safe.size.x/700.0
	var c=safe.get_center()
	var R=func(x: float,y: float,w: float,h: float) -> Rect2: return Rect2(c+(Vector2(x,y)-Vector2(836,470))*k,Vector2(w,h)*k)
	var title_r: Rect2=R.call(505,20,665,125)
	var right_r: Rect2=R.call(830 if left else 528,158,615,730)
	if portrait():
		title_r=Rect2(safe.position.x+safe.size.x*0.06,safe.position.y,safe.size.x*0.88,safe.size.x*0.88*124.0/576.0)
		right_r=Rect2(safe.position.x,title_r.end.y-6,safe.size.x,safe.end.y-title_r.end.y+6)
		left=false
	if left:
		ConceptScreen.piece(content,P42,"card",R.call(240,158,575,730),false)
		ConceptScreen.words(content,"A little pause",R.call(300,178,460,78),int(56*k))
		ConceptScreen.piece(content,P42,"picture",R.call(272,252,516,306),false)
		ConceptScreen.button(content,"Resume",P42,"resume",R.call(285,570,482,92),app.toggle_pause,"Resume",null,int(50*k),Color("fff6e0"))
		ConceptScreen.button(content,"MyPet",P42,"button",R.call(288,670,478,84),app.show_home,"My Pet",null,int(42*k))
		ConceptScreen.button(content,"MainMenu",P42,"button",R.call(288,766,478,84),app.show_menu,"Main menu",null,int(42*k))
	ConceptScreen.piece(content,P42,"card",right_r,false)
	# Title plaque (torn paper with leaves): tapping it also resumes.
	var head=ConceptScreen.button(content,"PauseHeader" if mode=="pause" else "SettingsDone",P42,"title",title_r,app.toggle_pause)
	head.tooltip_text="Resume" if mode=="pause" else "Done"
	head.text="Pause & Settings" if mode=="pause" else "Done"
	ConceptScreen.words(head,"Pause & Settings" if mode=="pause" else "Settings",Rect2(title_r.size.x*0.17,title_r.size.y*0.2,title_r.size.x*0.66,title_r.size.y*0.52),int(title_r.size.y*0.42))
	var close_r=Rect2(right_r.end.x-right_r.size.x*0.13,right_r.position.y-right_r.size.x*0.02,right_r.size.x*0.15,right_r.size.x*0.15)
	var close=ConceptScreen.button(content,"Close",P42,"close",close_r,app.toggle_pause)
	close.tooltip_text="Close"
	var inner=right_r.grow_individual(-right_r.size.x*0.06,-right_r.size.y*0.05,-right_r.size.x*0.06,-right_r.size.y*0.05)
	ConceptScreen.words(content,"Settings",Rect2(inner.position.x,inner.position.y,inner.size.x,62*k*1.3),int(60*k*(1.3 if portrait() else 1.0)))
	inner=inner.grow_individual(0,-70*k*(1.3 if portrait() else 1.0),0,0)
	# Seven rows fill the card as in the concept (phones keep 52 px rows).
	p42_row=maxf(52.0,floorf(inner.size.y/7.15)) if not portrait() else 60.0
	# Sliders and steppers never take more than half the row from the caption.
	p42_ctrl=minf(p42_row*3.4,inner.size.x*0.5)
	var scroll=ScrollContainer.new()
	scroll.position=inner.position
	scroll.size=inner.size
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
	content.add_child(scroll)
	var column=VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",0)
	scroll.add_child(column)
	if not left and mode=="pause":
		for e in [["Resume","resume",app.toggle_pause,"#fff6e0"],["MyPet","button",app.show_home,"#182952"],["MainMenu","button",app.show_menu,"#182952"]]:
			var hb=Control.new()
			hb.custom_minimum_size=Vector2(0,64)
			column.add_child(hb)
			var b=ConceptScreen.button(hb,e[0],P42,e[1],Rect2(0,2,inner.size.x,58),e[2],{"Resume":"Resume","MyPet":"My Pet","MainMenu":"Main menu"}[e[0]],null,28,Color(e[3]))
			hb.resized.connect(func(): b.size.x=hb.size.x;b.get_node("Face").size.x=hb.size.x)
	settings_column(column)

func paper_settings_board(left: bool) -> void:
	if p42():
		p42_board(left)
		return
	var dim=ColorRect.new()
	dim.color=Color(.05,.04,.02,.35)
	dim.size=logical_size
	content.add_child(dim)
	var SKIT="settings-paper"
	var k=minf(safe.size.x/1672.0,safe.size.y/941.0)*1.08
	if portrait(): k=safe.size.x/700.0
	var c=safe.get_center()
	var R=func(x: float,y: float,w: float,h: float) -> Rect2: return Rect2(c+(Vector2(x,y)-Vector2(836,470))*k,Vector2(w,h)*k)
	var title_r: Rect2=R.call(520,20,630,170)
	var right_r: Rect2=R.call(790 if left else 520,175,620,650)
	var left_r: Rect2=R.call(290,175,500,650)
	if portrait():
		title_r=Rect2(safe.position.x+safe.size.x*0.06,safe.position.y,safe.size.x*0.88,safe.size.x*0.88*184.0/455.0)
		right_r=Rect2(safe.position.x,title_r.end.y-10,safe.size.x,safe.end.y-title_r.end.y+10)
		left=false
	if left: ConceptScreen.piece(content,SKIT,"pause_panel",left_r,false)
	ConceptScreen.piece(content,SKIT,"settings_panel",right_r,false)
	# Hanging title plaque with its back arrow: the whole plaque is the button.
	var head=ConceptScreen.button(content,"PauseHeader" if mode=="pause" else "SettingsDone",SKIT,"title",title_r,app.toggle_pause)
	head.tooltip_text="Resume" if mode=="pause" else "Done"
	head.text="Pause & Settings" if mode=="pause" else "Done"
	ConceptScreen.words(head,"Pause & Settings" if mode=="pause" else "Settings",Rect2(title_r.size.x*0.26,title_r.size.y*0.42,title_r.size.x*0.66,title_r.size.y*0.42),int(64*k*(1.6 if portrait() else 1.0)))
	var inner=right_r.grow_individual(-right_r.size.x*0.07,-right_r.size.y*0.07,-right_r.size.x*0.07,-right_r.size.y*0.06)
	var scroll=ScrollContainer.new()
	scroll.position=inner.position
	scroll.size=inner.size
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
	content.add_child(scroll)
	var column=VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",4)
	scroll.add_child(column)
	if not left and mode=="pause":
		# Phone upright: Resume, My Pet and Main menu head the list.
		for e in [["Resume","plank_green",app.toggle_pause,"#fff3d6"],["MyPet","plank_cream",app.show_home,"#182952"],["MainMenu","plank_cream",app.show_menu,"#182952"]]:
			var hb=Control.new()
			hb.custom_minimum_size=Vector2(0,58)
			column.add_child(hb)
			var b=ConceptScreen.button(hb,e[0],SKIT,e[1],Rect2(0,0,inner.size.x,56),e[2],{"Resume":"Resume","MyPet":"My Pet","MainMenu":"Main menu"}[e[0]],null,26,Color(e[3]))
			hb.resized.connect(func(): b.size.x=hb.size.x;b.get_node("Face").size.x=hb.size.x)
	var heading=ConceptScreen.words(column,"Settings",Rect2(0,0,10,48),34,PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)
	heading.custom_minimum_size=Vector2(0,48)
	settings_column(column)
	if left:
		var L=func(x: float,y: float,w: float,h: float) -> Rect2: return R.call(x,y,w,h)
		ConceptScreen.words(content,"A little pause",L.call(330,210,420,70),int(60*k))
		var sub=ConceptScreen.words(content,"Rest, adjust your settings,\nthen get back to the adventure!",L.call(320,275,440,80),int(28*k))
		sub.autowrap_mode=TextServer.AUTOWRAP_OFF
		ConceptScreen.piece(content,SKIT,"resting",L.call(340,340,420,270))
		ConceptScreen.button(content,"Resume",SKIT,"plank_green",L.call(345,605,410,100),app.toggle_pause,"Resume",null,int(56*k),Color("fff3d6"))
		ConceptScreen.button(content,"MyPet",SKIT,"plank_cream",L.call(340,712,205,82),app.show_home,"My Pet",null,int(34*k))
		ConceptScreen.button(content,"MainMenu",SKIT,"plank_cream",L.call(555,712,205,82),app.show_menu,"Main menu",null,int(34*k))
		if mode=="pause" and not compact():
			var tag=R.call(700,815,280,110)
			ConceptScreen.piece(content,SKIT,"paused_tag",tag,false).name="PausedRibbon"
			ConceptScreen.words(content,"Paused",Rect2(tag.position.x+tag.size.x*0.15,tag.position.y+tag.size.y*0.35,tag.size.x*0.7,tag.size.y*0.55),int(48*k),Color("fff3d6"))

func build_settings() -> void:
	if ArtStyle.paper:
		paper_settings_board(false)
		return
	var dim=ColorRect.new()
	dim.color=Color(.03,.08,.16,.5)
	dim.size=logical_size
	content.add_child(dim)
	var width=minf(640,safe.size.x)
	var top=safe.position.y+PetUI.H_HEADER+8
	var header=button(content,"Done",Rect2(safe.get_center().x-110,safe.position.y,220,PetUI.H_HEADER),app.toggle_pause,"back",true)
	header.name="SettingsDone"
	var column=scroll_card(Rect2(safe.get_center().x-width/2,top,width,safe.end.y-top))
	column.add_theme_constant_override("separation",6)
	settings_column(column)

func build_pause() -> void:
	if ArtStyle.paper:
		paper_settings_board(true)
		return
	var dim=ColorRect.new()
	dim.color=Color(.03,.08,.16,.28)
	dim.size=logical_size
	content.add_child(dim)
	var tab_width=minf(330,safe.size.x)
	var header=button(content,"Pause & Settings",Rect2(safe.get_center().x-tab_width/2,safe.position.y,tab_width,PetUI.H_HEADER),app.toggle_pause,"back")
	header.name="PauseHeader"
	header.tooltip_text="Resume"
	var top=safe.position.y+PetUI.H_HEADER+10
	if portrait():
		var column=scroll_card(Rect2(safe.position.x,top,safe.size.x,safe.end.y-top))
		var card=Control.new()
		card.custom_minimum_size=Vector2(0,420)
		column.add_child(card)
		var holder=content
		content=card
		pause_card(Rect2(0,0,safe.size.x-36,410),110,false)
		content=holder
		settings_column(column)
		return
	var bounds=Rect2(safe.position.x+maxf(0,(safe.size.x-980)/2),top,minf(980,safe.size.x),safe.end.y-top-(0 if compact() else 40))
	var left=bounds.size.x*.38
	var art=clampf(bounds.size.y-300,40,220)
	pause_card(Rect2(bounds.position,Vector2(left-8,bounds.size.y)),art)
	var right=scroll_card(Rect2(bounds.position+Vector2(left+4,0),Vector2(bounds.size.x-left-4,bounds.size.y)))
	right.add_theme_constant_override("separation",6)
	settings_column(right)
	if not compact():
		var ribbon=CareArt.tag(content,"Paused",Rect2(safe.get_center().x-70,bounds.end.y+6,140,PetUI.H_TAG))
		ribbon.name="PausedRibbon"
		(ribbon.get_meta("compose") as Dictionary).layout="row"
		PetUI.arrange(ribbon)

func build_bag() -> void:
	var width=minf(600,safe.size.x)
	var height=minf(440,safe.size.y)
	var column=scroll_card(Rect2(safe.get_center()-Vector2(width,height)/2,Vector2(width,height)))
	column.add_theme_constant_override("separation",8)
	flow_label(column,"Your adventure bag",28)
	flow_label(column,"Reusable crates: %d free / %d owned\nMeals for home: %d\nChoose where to place crates, then jump on them.\nPack them to try another arrangement."%[app.game.available_crates(),int(app.game.state.inventory.get("trail_crate",0)),int(app.game.state.inventory.get("berry_bowl",0))],17).custom_minimum_size.y=88
	var build=flow_button(column,"Place a crate",func():
		app.toggle_bag()
		app.placement_ui=preload("res://scripts/ui/crate_placement.gd").new()
		app.placement_ui.app=app
		app.add_child(app.placement_ui),"",true)
	build.disabled=app.game.available_crates()<=0
	flow_button(column,"Pack all placed crates",func(): app.game.pack_trail_crates();app.toggle_bag())
	flow_button(column,"Back",app.toggle_bag,"back")

## V2 area map: rooms you have visited, where you are, chests still hidden
## and locked ways. Unvisited rooms show as "?" until you get there.
## A57 (P56): the area map from concept P56 (areamap-p32). Places sit on the
## painted map's own buildings; clouds hide places not visited yet, chests mark
## hidden treasure, padlocks the ways Foxy can't open yet.
const P56_SPOTS={"meadow_fields":Vector2(0.22,0.3),"river_crossing":Vector2(0.52,0.5),"hidden_cave":Vector2(0.64,0.26),"old_tower":Vector2(0.86,0.3),"windmill_cellar":Vector2(0.75,0.72),"forest_gate":Vector2(0.24,0.83)}
func p56_map() -> void:
	var data=GameState.world_data()
	var w=app.game.world()
	var current: String=app.active_world.room_id if is_instance_valid(app.active_world) else w.room
	var k=minf(safe.size.x/1300.0,safe.size.y/900.0)
	var c=safe.get_center()
	var R=func(x: float,y: float,ww: float,hh: float) -> Rect2: return Rect2(c+(Vector2(x,y)-Vector2(836,470))*k,Vector2(ww,hh)*k)
	var dim=ColorRect.new()
	dim.color=Color(.05,.04,.02,.4)
	dim.size=logical_size
	content.add_child(dim)
	var panel=Control.new()
	panel.name="WorldMap"
	panel.size=logical_size
	content.add_child(panel)
	ConceptScreen.piece(panel,"areamap-p32","board",R.call(205,25,1265,880),false)
	ConceptScreen.words(panel,"Green Meadows",R.call(560,55,560,110),int(80*k))
	var close=ConceptScreen.button(panel,"CloseMap","areamap-p32","close",R.call(1360,55,105,105),app.toggle_world_map)
	close.tooltip_text="Close"
	var mr: Rect2=R.call(240,135,1195,640)
	ConceptScreen.piece(panel,"areamap-p32","map",mr,false)
	var spot=func(id: String) -> Vector2: return mr.position+P56_SPOTS.get(id,Vector2(0.5,0.5))*mr.size
	var t=Time.get_ticks_msec()/1000.0
	for id in data.rooms:
		var at: Vector2=spot.call(id)
		var seen=id in w.visited or id==current
		var room: Dictionary=data.rooms[id]
		var holder=Control.new()
		holder.name="Room_"+String(id)
		holder.position=at
		holder.mouse_filter=Control.MOUSE_FILTER_IGNORE
		panel.add_child(holder)
		if not seen:
			ConceptScreen.piece(holder,"areamap-p32","cloud",Rect2(Vector2(-120,-80)*k,Vector2(240,150)*k))
			continue
		var hidden=0
		for chest in room.get("chests",[]):
			if not chest.id in w.opened: hidden+=1
		if hidden>0 and id!=current: ConceptScreen.piece(holder,"areamap-p32","chest",Rect2(Vector2(10,-90)*k,Vector2(90,80)*k))
		for g in room.get("gates",[]):
			if not app.game.has_ability(g.ability):
				ConceptScreen.piece(holder,"areamap-p32","lock",Rect2(Vector2(-40,-50)*k,Vector2(64,74)*k))
				break
		var lw=String(room.get("title",id))
		var lr=Rect2(Vector2(-95,22)*k,Vector2(190,44)*k)
		ConceptScreen.piece(holder,"areamap-p32","label",lr,false)
		ConceptScreen.words(holder,lw,lr,int(26*k))
	if data.rooms.has(current):
		var here=ConceptScreen.piece(panel,"areamap-p32","pin",Rect2(spot.call(current)+Vector2(-48,-150)*k,Vector2(96,128)*k))
		here.name="YouAreHere"
	var found=0
	var robot=0
	for part in data.parts:
		if not part.begins_with("robot_"): continue
		robot+=1
		found+=1 if int(w.parts.get(part,0))>0 else 0
	var lg: Rect2=R.call(255,780,1165,105)
	ConceptScreen.piece(panel,"areamap-p32","legend",lg,false)
	var items=[["pin","You",300],["chest","Treasure",520],["lock","Locked",820],["robot","Toy parts %d / %d"%[found,robot],1090]]
	for it in items:
		ConceptScreen.piece(panel,"areamap-p32",it[0],R.call(it[2],790,80,85))
		ConceptScreen.words(panel,it[1],R.call(it[2]+95,790,240,85),int(34*k),PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)

func build_world_map() -> void:
	if ArtStyle.paper and ResourceLoader.exists("res://assets/ui/areamap-p32/map.png"):
		p56_map()
		return
	var data=GameState.world_data()
	var w=app.game.world()
	var current: String=app.active_world.room_id if is_instance_valid(app.active_world) else w.room
	var width=minf(900,safe.size.x)
	var height=minf(560,safe.size.y)
	var box=Rect2(safe.get_center()-Vector2(width,height)/2,Vector2(width,height))
	var panel=CareArt.panel(content,box)
	panel.name="WorldMap"
	# The painted map keeps its proportions inside the frame.
	var art: Texture2D=ArtTexture.load_texture(data.map_art)
	var inner=Rect2(16,16,width-32,height-32)
	var scale_value=minf(inner.size.x/art.get_width(),inner.size.y/art.get_height())
	var art_size=Vector2(art.get_width(),art.get_height())*scale_value
	var origin=inner.position+(inner.size-art_size)*0.5
	var painting=TextureRect.new()
	painting.texture=art
	painting.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	painting.position=origin
	painting.size=art_size
	painting.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(painting)
	var spot=func(f: Array) -> Vector2: return origin+Vector2(f[0],f[1])*art_size
	# Clouds over places not yet visited.
	var fog=Control.new()
	fog.mouse_filter=Control.MOUSE_FILTER_IGNORE
	fog.size=box.size
	panel.add_child(fog)
	var hidden_spots=[]
	for id in data.map_spots:
		if not id in w.visited: hidden_spots.append(spot.call(data.map_spots[id]))
	var r=art_size.y*0.13
	# Soft painted cumulus: a cool shadow layer, a white body and a sunlit
	# top, built from one feathered puff so the edges melt into the map.
	var puff=GradientTexture2D.new()
	puff.width=64
	puff.height=64
	puff.fill=GradientTexture2D.FILL_RADIAL
	puff.fill_from=Vector2(0.5,0.5)
	puff.fill_to=Vector2(1.0,0.5)
	var soft=Gradient.new()
	soft.offsets=PackedFloat32Array([0.0,0.68,0.84,1.0])
	soft.colors=PackedColorArray([Color(1,1,1,1),Color(1,1,1,0.95),Color(1,1,1,0.45),Color(1,1,1,0)])
	puff.gradient=soft
	# (offset in r, radius in r): a flat base row and a rounded crown.
	var shape=[[Vector2(-0.95,0.18),0.42],[Vector2(-0.45,0.22),0.5],[Vector2(0.1,0.24),0.52],[Vector2(0.65,0.2),0.46],[Vector2(1.05,0.16),0.36],[Vector2(-0.55,-0.12),0.46],[Vector2(0.0,-0.3),0.6],[Vector2(0.55,-0.14),0.48]]
	var started=Time.get_ticks_msec()
	fog.draw.connect(func():
		var t=(Time.get_ticks_msec()-started)/1000.0
		for i in hidden_spots.size():
			var c: Vector2=hidden_spots[i]+Vector2(sin(t*0.35+i*1.7)*r*0.06,0)
			# Faint mist halo so the place reads as hidden, not erased.
			fog.draw_texture_rect(puff,Rect2(c-Vector2(r*1.9,r*1.1),Vector2(r*3.8,r*2.2)),false,Color(0.93,0.95,1.0,0.35))
			for layer in [[Vector2(0.05,0.16),1.0,Color(0.6,0.64,0.86,0.75)],[Vector2.ZERO,0.96,Color(0.98,0.98,1.0,1.0)],[Vector2(-0.07,-0.1),0.6,Color(1,1,0.96,1.0)]]:
				for k in shape.size():
					var bob=sin(t*0.8+k*1.3+i)*r*0.015
					var rad: float=shape[k][1]*r*layer[1]*1.25
					var at: Vector2=c+(shape[k][0]+layer[0])*r+Vector2(0,bob)
					fog.draw_texture_rect(puff,Rect2(at-Vector2(rad,rad),Vector2(rad,rad)*2),false,layer[2]))
	(Engine.get_main_loop() as SceneTree).process_frame.connect(fog.queue_redraw)
	var found=0
	var robot=0
	for part in data.parts:
		if not part.begins_with("robot_"): continue
		robot+=1
		found+=1 if int(w.parts.get(part,0))>0 else 0
	# Route: dotted trail between connected places, solid where both are visited.
	var route=Control.new()
	route.mouse_filter=Control.MOUSE_FILTER_IGNORE
	route.size=box.size
	panel.add_child(route)
	var pairs=[]
	for id in data.map_spots:
		for exit in data.rooms[id].exits:
			if data.map_spots.has(exit.to) and not [exit.to,id] in pairs: pairs.append([id,exit.to])
		for sd in data.rooms[id].get("secret_doors",[]):
			if data.map_spots.has(sd.to) and sd.id in w.opened: pairs.append([id,sd.to])
	pairs.append(["home","meadow_fields"])
	var at_of=func(id: String) -> Vector2: return spot.call(data.map_home if id=="home" else data.map_spots[id])
	route.draw.connect(func():
		for pair in pairs:
			var a: Vector2=at_of.call(pair[0])
			var b: Vector2=at_of.call(pair[1])
			var known=(pair[0]=="home" or pair[0] in w.visited) and pair[1] in w.visited
			var n=int(a.distance_to(b)/9.0)
			for k in range(1,n):
				var p2=a.lerp(b,float(k)/n)
				route.draw_circle(p2,3.4 if known else 2.4,Color(0.35,0.2,0.08,0.95) if known else Color(1,1,1,0.75))
				if known: route.draw_circle(p2,2.0,Color("ffd65a")))
	var title=CareArt.tag(panel,"Green Meadows  ·  Robot parts %d / %d"%[found,robot],Rect2(28,26,330,PetUI.H_TAG),"map",true)
	title.position.x=28
	title.name="MapTitle"
	var close=CareArt.square(panel,"close",Rect2(width-62,14,48,48),app.toggle_world_map)
	close.name="CloseMap"
	var medal=clampf(art_size.y*0.1,36,54)
	var small=art_size.x<700
	var home=CareArt.tag(panel,"Home",Rect2(spot.call(data.map_home)+Vector2(-40,medal*0.2),Vector2(80,PetUI.H_TAG)),"home",true)
	home.name="HomeTag"
	for id in data.map_spots:
		var room=data.rooms[id]
		var at: Vector2=spot.call(data.map_spots[id])
		var seen=id in w.visited
		var hidden=0
		for chest in room.get("chests",[]):
			if not chest.id in w.opened: hidden+=1
		var piece="medal_ring" if id==current else ("medal_locked" if not seen else ("medal_open" if hidden>0 else "medal_done"))
		var m=PetUI.panel(panel,Rect2(at-Vector2.ONE*medal*0.5,Vector2.ONE*medal))
		m.name="Room_"+id
		PetUI.set_piece(m,piece)
		if id==current:
			var face=picture(m,"res://assets/ui/kit-v1/fox-medal.png",Rect2(medal*0.14,medal*0.14,medal*0.72,medal*0.72))
			face.show_behind_parent=true
			face.name="YouAreHere"
		if seen and hidden>0 and id!=current:
			CareArt.picture(m,"act_open",Rect2(medal*0.24,medal*0.24,medal*0.52,medal*0.52))
		if seen:
			var label=room.title
			if not small:
				if hidden>0: label+="  ·  %d chest%s"%[hidden,"" if hidden==1 else "s"]
				for g in room.get("gates",[]):
					if not app.game.has_ability(g.ability): label+="  ·  locked"
			var above=id in data.map_tag_above
			var y=at.y-medal*0.5-PetUI.H_TAG-2 if above else at.y+medal*0.5+2
			var tag=CareArt.tag(panel,label,Rect2(at.x-130,y,260,PetUI.H_TAG),"",true)
			tag.name="Tag_"+id
	# Next goal: a bouncing gold star over the place to go, and the step
	# written at the bottom of the map.
	var goal: Dictionary=app.game.world_goal() if app.game.preferences().show_goal else {"text":"","room":""}
	var next=CareArt.tag(panel,"Next: "+goal.text,Rect2(28,26+PetUI.H_TAG+6,width*0.62,PetUI.H_TAG),"star",true)
	next.position.x=28
	next.name="NextGoal"
	next.visible=not String(goal.text).is_empty()
	if data.map_spots.has(goal.room):
		var star=CareArt.picture(panel,"star",Rect2(spot.call(data.map_spots[goal.room])-Vector2(medal*0.4,medal*1.35),Vector2.ONE*medal*0.8))
		star.name="GoalStar"
		if not app.game.state.settings.reduced_motion:
			var bounce=star.create_tween().set_loops()
			bounce.tween_property(star,"position:y",star.position.y-8,0.45).set_trans(Tween.TRANS_SINE)
			bounce.tween_property(star,"position:y",star.position.y,0.45).set_trans(Tween.TRANS_SINE)

## V2 world bag on one screen (no scrolling): snacks to tap, crates,
## robot parts and the current quest step. Tapping a snack closes the bag and
## Foxy eats it in the world.
## V10 bag: tabs, a scrolling grid of equal slots (only what you own) and a
## details card with one clear action. Grows with whatever you carry.
var bag_tab="snacks"
var bag_pick=""
## A55: the paper bag kit from P12 (tools/build_bag_paper.py), same layout keys.
var BAG_ART: String:
	get: return "res://assets/ui/bag-paper/" if ArtStyle.paper else "res://assets/ui/bag-v1/"
func bag_items(tab: String) -> Array:
	var w=app.game.world()
	var out=[]
	var add=func(id: String, name: String, icon: String, count: int, text: String, action: String):
		out.append({"id":id,"name":name,"icon":icon,"count":count,"text":text,"action":action})
	match tab:
		"snacks":
			var data=GameState.foods()
			for id in data.order:
				if id=="kibble" or app.game.food_count(id)<1: continue
				var taste=app.game.food_taste(id)
				var line="Fills %s's tummy and gives energy."%app.game.pet().name
				if taste=="like": line="%s's favourite! Extra happy."%app.game.pet().name
				elif taste=="dislike": line="%s is not keen on this one."%app.game.pet().name
				add.call(id,data.foods[id].name,"food_"+id,app.game.food_count(id),line,"Give to %s"%app.game.pet().name)
		"tools":
			var free=app.game.world_crates_free()
			if w.crates>0: add.call("crate","Crate","res://assets/art/meadows-v2/crate.png",free,"Stand on it to reach high places. Pick it up again any time.","Place it" if free>0 else "")
			if int(w.get("carrots",0))>0: add.call("magic_carrot","Magic carrot","res://assets/art/meadows-v2/pickup_carrot.png",int(w.carrots),"Eat it and your next jump is a big one.","Eat it")
			if "foxy_boost" in w.abilities: add.call("sky_feather","Sky Feather","res://assets/art/meadows-v2/sky_feather.png",1,"Double Jump: jump, then jump again in the air.","")
		"treasures":
			if "tower_key" in w.opened: add.call("key","Golden key","res://assets/art/meadows-v2/pickup_key.png",1,"Opens the locked door at the top of the Old Tower.","")
			for part in ["robot_head","robot_arm","robot_body","robot_wheel"]:
				if int(w.parts.get(part,0))>0: add.call(part,String(GameState.world_data().parts.get(part,part)),"res://assets/art/meadows-v2/%s.png"%part,1,"A toy robot part. Find all four to build a robot!","")
		"quests":
			var stage="Talk to Moss the bunny in Meadow Fields." if not "picnic_asked" in w.opened else ("Find Moss's picnic basket at the top of the Old Tower." if not "picnic_basket" in w.opened else ("Bring the picnic basket to Moss in Meadow Fields." if not "picnic_done" in w.opened else "Done! Thank you for helping Moss."))
			add.call("picnic","The Lost Picnic","basket",1,stage,"")
			add.call("goal","Next goal","star",1,String(app.game.world_goal().text)+".","")
	return out

func bag_use(item: Dictionary) -> void:
	app.toggle_bag()
	if not is_instance_valid(app.active_world): return
	match item.id:
		"crate": app.active_world.start_placing()
		"magic_carrot": app.active_world.use_carrot()
		_: app.active_world.give_snack(item.id)

func bag_icon(icon: String) -> Texture2D:
	return ArtTexture.load_texture(icon) if icon.begins_with("res://") else CareArt.icon(icon)

## A57 (P44): the bag built from concept P44 with the bag-p32 kit, placed at
## the concept's coordinates (1672x941); every word is live.
const P44="bag-p32"
const P44_ITEM={"food_apple":["bag-p32","apple"],"food_fish_treat":["bag-p32","fish"],"food_carrot":["bag-p32","carrot"],"food_berry_bowl":["shop-p32","berries"],"food_honey_cookie":["shop-p32","cookie"],
	"res://assets/art/meadows-v2/crate.png":["bag-p32","crate"],"res://assets/art/meadows-v2/pickup_key.png":["bag-p32","key"],"basket":["../art/meadow-p31","pickup_note"],"star":["details-p32","star"],
	"res://assets/art/meadows-v2/pickup_carrot.png":["../art/meadow-p31","pickup_carrot"],"res://assets/art/meadows-v2/sky_feather.png":["../art/meadow-p31","sky_feather"]}
func p44_item(parent: Node, icon: String, rect: Rect2) -> TextureRect:
	if P44_ITEM.has(icon): return ConceptScreen.piece(parent,P44_ITEM[icon][0],P44_ITEM[icon][1],rect)
	return bag_icon_rect(parent,icon,rect)
## Concept scale: the whole 1672x941 concept fits the screen (room is left
## for the HUD as in the concept); small phones use the panels' own box.
func p32_frame(box: Rect2) -> Array:
	var k=minf(logical_size.x/1672.0,logical_size.y/941.0)
	var c=Vector2(836,470)
	if k<0.62:
		k=minf((safe.size.x-8)/box.size.x,(safe.size.y-4)/box.size.y)
		c=box.get_center()
	# Before the first real layout the screen can still be empty.
	return [maxf(k,0.05),c]
## P42/P44: hearts top left and the coin counter top right stay visible
## over adventure modals (HUD pieces from hud-p32).
func p32_status(parent: Node) -> void:
	if not is_instance_valid(app.active_world): return
	var h=clampf(logical_size.y*0.075,28.0,56.0)
	var world: MeadowWorld=app.active_world
	for i in range(MeadowWorld.MAX_HEARTS):
		ConceptScreen.piece(parent,"hud-p32","heart_full" if i<world.hearts else "heart_empty",Rect2(safe.position.x+6+i*h*1.08,safe.position.y+6,h,h))
	var cw=h*2.6
	var coins=Rect2(safe.end.x-cw-6,safe.position.y+6,cw,h*1.1)
	ConceptScreen.piece(parent,"hud-p32","coins",coins,false)
	var n=ConceptScreen.words(parent,str(app.adventure_coins()),Rect2(coins.position.x+cw*0.4,coins.position.y,cw*0.52,coins.size.y),int(h*0.6),Color("fff8e6"))
	n.name="StatusCoins"
func wrapped(parent: Node, caption: String, rect: Rect2, points: int) -> Label:
	var l=ConceptScreen.words(parent,caption,rect,points)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",points)
	return l
func p44_bag() -> void:
	var f=p32_frame(Rect2(148,22,1400,790))
	var k: float=f[0]
	var c=logical_size*0.5 if f[1]==Vector2(836,470) else safe.get_center()
	var o: Vector2=f[1]
	var R=func(x: float,y: float,w: float,h: float) -> Rect2: return Rect2(c+(Vector2(x,y)-o)*k,Vector2(w,h)*k)
	var panel=Control.new()
	panel.name="WorldBag"
	panel.size=logical_size
	content.add_child(panel)
	p32_status(panel)
	ConceptScreen.piece(panel,P44,"title",R.call(505,22,655,138),false)
	ConceptScreen.piece(panel,P44,"ic_bag",R.call(668,38,108,114))
	var bag_title=ConceptScreen.words(panel,"Bag",R.call(790,36,300,116),int(96*k))
	bag_title.name="BagTitle"
	ConceptScreen.piece(panel,P44,"board",R.call(148,165,975,640),false)
	ConceptScreen.piece(panel,P44,"side",R.call(1130,180,415,627),false)
	var close=ConceptScreen.button(panel,"CloseBag",P44,"close",R.call(1458,176,90,90),app.toggle_bag)
	close.tooltip_text="Close"
	var tabs=[["snacks","Snacks",R.call(183,190,250,74)],["tools","Tools",R.call(445,196,198,68)],["treasures","Treasures",R.call(655,196,212,68)],["quests","Quests",R.call(880,196,208,68)]]
	for t in tabs:
		var id: String=t[0]
		var on=bag_tab==id
		var b=ConceptScreen.button(panel,"Tab_"+id,P44,"tab_on" if on else "tab",t[2],func():
			bag_tab=id
			bag_pick=""
			signature="";layout(logical_size,safe),t[1],null,int((44 if on else 36)*k),Color("fff6e0") if on else PetUI.INK)
		b.tooltip_text=t[1]
	var items: Array=bag_items(bag_tab)
	if bag_pick.is_empty() or not items.any(func(it): return it.id==bag_pick): bag_pick=items[0].id if not items.is_empty() else ""
	# Slots: 5 x 3 at the concept's spacing; more items scroll.
	var grid=R.call(190,276,900,512)
	var scroll=ScrollContainer.new()
	scroll.name="BagGrid"
	scroll.position=grid.position
	scroll.size=grid.size
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
	panel.add_child(scroll)
	var rows=maxi(3,int(ceil(items.size()/5.0)))
	var holder=Control.new()
	holder.custom_minimum_size=Vector2(900,rows*168.0)*k
	scroll.add_child(holder)
	var sw=158.0*k
	var sh=152.0*k
	for n in rows*5:
		var pos=Vector2((n%5)*179.5,int(n/5)*168.0)*k+Vector2(4,4)*k
		var it: Dictionary=items[n] if n<items.size() else {}
		var picked=not it.is_empty() and it.id==bag_pick
		if picked: ConceptScreen.piece(holder,P44,"slot_on",Rect2(pos-Vector2(6,6)*k,Vector2(sw,sh)+Vector2(12,12)*k),false)
		else: ConceptScreen.piece(holder,P44,"slot" if not it.is_empty() else "slot_empty",Rect2(pos,Vector2(sw,sh)),false)
		if it.is_empty(): continue
		var cell=Button.new()
		cell.name="Item_"+String(it.id)
		cell.flat=true
		cell.focus_mode=Control.FOCUS_NONE
		for st in ["normal","hover","pressed","focus"]: cell.add_theme_stylebox_override(st,StyleBoxEmpty.new())
		cell.position=pos
		cell.size=Vector2(sw,sh)
		holder.add_child(cell)
		p44_item(cell,it.icon,Rect2(sw*0.14,sh*0.1,sw*0.72,sh*0.72))
		if int(it.count)>0 and String(it.icon)!="star" and bag_tab!="quests":
			var bp=Rect2(sw-62*k,sh-44*k,56*k,38*k)
			ConceptScreen.piece(cell,P44,"count",bp,false)
			ConceptScreen.words(cell,"x%d"%int(it.count),bp,int(26*k))
		var pick: String=it.id
		cell.pressed.connect(func():
			bag_pick=pick
			signature="";layout(logical_size,safe))
	if items.is_empty():
		wrapped(panel,{"snacks":"No snacks yet. Find apples and fish, or buy food in the shop.","tools":"No tools yet. Foxy can dig up crates and magic carrots.","treasures":"No treasures yet. Look for chests!","quests":""}[bag_tab],R.call(1160,280,355,380),int(32*k))
		return
	var item: Dictionary=items.filter(func(it): return it.id==bag_pick)[0]
	ConceptScreen.piece(panel,P44,"blob",R.call(1178,252,320,276),false)
	p44_item(panel,item.icon,R.call(1232,282,214,214))
	var name_label=ConceptScreen.words(panel,item.name,R.call(1150,530,375,74),int(56*k))
	name_label.name="ItemName"
	var rule=ColorRect.new()
	rule.color=Color(0.45,0.36,0.22,0.2)
	var rr: Rect2=R.call(1180,604,316,2)
	rule.position=rr.position
	rule.size=Vector2(rr.size.x,maxf(1.0,rr.size.y))
	panel.add_child(rule)
	var line=wrapped(panel,item.text,R.call(1160,612,355,62),int(26*k))
	line.add_theme_constant_override("line_spacing",-2)
	if not String(item.action).is_empty():
		var act=ConceptScreen.button(panel,"BagAction",P44,"give",R.call(1163,680,355,92),func(): bag_use(item),item.action,null,int(40*k),Color("fff6e0"))
		act.tooltip_text=item.action

func build_world_bag() -> void:
	if ArtStyle.paper and ResourceLoader.exists("res://assets/ui/bag-p32/board.png"):
		p44_bag()
		return
	# The concept picture is the bag (assets/ui/bag-v1/base.png); everything
	# that changes is placed at the concept's own coordinates (layout.json).
	var L: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BAG_ART+"layout.json"))
	var bw=float(L.size[0])
	var bh=float(L.size[1])
	var k=minf((safe.size.x-8)/bw,(safe.size.y-4)/bh)
	var origin=safe.get_center()-Vector2(bw,bh)*k*0.5
	var at=func(x: float, y: float) -> Vector2: return Vector2(x,y)*k
	var panel=Control.new()
	panel.name="WorldBag"
	panel.position=origin
	panel.size=Vector2(bw,bh)*k
	content.add_child(panel)
	bag_tex(panel,"base",Rect2(Vector2.ZERO,panel.size))
	var tr: Array=L.get("title",[610,45,190,65])
	var bag_title=text(panel,"Bag",Rect2(Vector2(tr[0],tr[1])*k,Vector2(tr[2],tr[3])*k),kp(64,k))
	bag_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	# Close: the concept's own round button.
	var cl: Array=L.close
	var close=Button.new()
	close.name="CloseBag"
	close.flat=true
	close.focus_mode=Control.FOCUS_NONE
	close.position=at.call(cl[0]-cl[2],cl[1]-cl[2])
	close.size=Vector2.ONE*cl[2]*2*k
	close.pressed.connect(app.toggle_bag)
	panel.add_child(close)
	# Tabs: plain tabs are in the picture; the chosen one turns gold.
	var tabs=[["snacks","Snacks","tab_snacks"],["tools","Tools","tab_tools"],["treasures","Treasures","tab_treasures"],["quests","Quests","tab_quests"]]
	for i in tabs.size():
		var r: Array=L.tabs[i]
		var rect=Rect2(at.call(r[0],r[1]),Vector2(r[2],r[3])*k)
		var id: String=tabs[i][0]
		var b=Button.new()
		b.name="Tab_"+id
		b.flat=true
		b.focus_mode=Control.FOCUS_NONE
		b.position=rect.position
		b.size=rect.size
		panel.add_child(b)
		if bag_tab==id: bag_tex(b,"tab_on_%d"%i,Rect2(Vector2(-3,-3)*k,rect.size+Vector2(6,6)*k))
		var icon_s=58.0*k
		var font: Font=load(PetUI.MENU_FONT_PATH)
		var pts=kp(30,k)
		var tw=font.get_string_size(tabs[i][1],HORIZONTAL_ALIGNMENT_LEFT,-1,pts).x
		var gap=14.0*k
		var start=(rect.size.x-icon_s-gap-tw)*0.5
		bag_tex(b,"items/"+String(tabs[i][2]),Rect2(start,(rect.size.y-icon_s)*0.5,icon_s,icon_s),true)
		var lab=text(b,tabs[i][1],Rect2(start+icon_s+gap,0,tw+6,rect.size.y),pts)
		lab.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		lab.mouse_filter=Control.MOUSE_FILTER_IGNORE
		b.pressed.connect(func():
			bag_tab=id
			bag_pick=""
			signature="";layout(logical_size,safe))
	# Slots: 5 x 3 at the concept's spacing; more items scroll.
	var items: Array=bag_items(bag_tab)
	if bag_pick.is_empty() or not items.any(func(it): return it.id==bag_pick): bag_pick=items[0].id if not items.is_empty() else ""
	var g: Array=L.grid
	var scroll=ScrollContainer.new()
	scroll.name="BagGrid"
	scroll.position=at.call(g[0],g[1])
	scroll.size=Vector2(g[2],g[3])*k
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
	panel.add_child(scroll)
	var rows=maxi(3,int(ceil(items.size()/5.0)))
	var holder=Control.new()
	holder.custom_minimum_size=Vector2(g[2],float(L.slots_y[0])-float(g[1])+rows*float(L.pitch[1]))*k
	scroll.add_child(holder)
	var sw=float(L.slot[0])*k
	var sh=float(L.slot[1])*k
	for n in rows*5:
		var pos=at.call(float(L.slots_x[n%5])-float(g[0]),float(L.slots_y[0])-float(g[1])+int(n/5)*float(L.pitch[1]))
		var it: Dictionary=items[n] if n<items.size() else {}
		var picked=not it.is_empty() and it.id==bag_pick
		if picked: bag_tex(holder,"slot_on",Rect2(pos-Vector2(10,8)*k,Vector2(sw,sh)+Vector2(21,16)*k))
		else: bag_tex(holder,"slot",Rect2(pos,Vector2(sw,sh)))
		if it.is_empty(): continue
		var cell=Button.new()
		cell.name="Item_"+String(it.id)
		cell.flat=true
		cell.focus_mode=Control.FOCUS_NONE
		cell.position=pos
		cell.size=Vector2(sw,sh)
		holder.add_child(cell)
		bag_icon_rect(cell,it.icon,Rect2(sw*0.14,sh*0.12,sw*0.72,sh*0.7))
		if int(it.count)>0 and String(it.icon)!="star" and bag_tab!="quests":
			var bs=50.0*k
			var bp=Vector2(sw-bs-8*k,sh-bs-6*k)
			bag_tex(cell,"badge",Rect2(bp,Vector2(bs,bs)))
			var num=text(cell,str(it.count),Rect2(bp,Vector2(bs,bs)),kp(30,k))
			num.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			num.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
			num.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var pick: String=it.id
		cell.pressed.connect(func():
			bag_pick=pick
			signature="";layout(logical_size,safe))
	# Details card.
	var card: Array=L.card
	var cx=(float(card[0])+float(card[2])*0.5)
	if items.is_empty():
		var none=text(panel,{"snacks":"No snacks yet. Find apples and fish, or buy food in the shop.","tools":"No tools yet. Foxy can dig up crates and magic carrots.","treasures":"No treasures yet. Look for chests!","quests":""}[bag_tab],Rect2(at.call(card[0]+24,card[1]+24),Vector2(card[2]-48,card[3]-48)*k),kp(24,k))
		none.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		none.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		none.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		return
	var item: Dictionary=items.filter(func(it): return it.id==bag_pick)[0]
	var pic: Array=L.picture
	bag_tex(panel,"glow",Rect2(at.call(pic[0]-pic[2]*1.35,pic[1]-pic[2]*1.25),Vector2(pic[2]*2.7,pic[2]*2.5)*k))
	bag_icon_rect(panel,item.icon,Rect2(at.call(pic[0]-pic[2],pic[1]-pic[2]),Vector2(pic[2]*2,pic[2]*2)*k),true)
	var name_label=text(panel,item.name,Rect2(at.call(card[0]+10,float(L.name_y)-30),Vector2(card[2]-20,60)*k),kp(46,k))
	name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	name_label.name="ItemName"
	var text_h=48.0
	if ArtStyle.paper: text_h=float(L.button[1])-float(L.text_y)+10.0
	var line=text(panel,item.text,Rect2(at.call(card[0]+16,float(L.text_y)-18),Vector2(card[2]-32,text_h)*k),kp(24,k))
	line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	line.add_theme_constant_override("line_spacing",-2)
	if int(item.count)>1:
		var cp: Array=L.count
		var pill=Panel.new()
		var ps=StyleBoxFlat.new()
		ps.bg_color=Color8(240,226,196)
		ps.set_corner_radius_all(int(19*k))
		if ArtStyle.paper:
			ps=StyleBoxTexture.new()
			ps.texture=ArtTexture.load_texture(BAG_ART+"pill.png")
		pill.add_theme_stylebox_override("panel",ps)
		pill.position=at.call(cp[0],cp[1])
		pill.size=Vector2(cp[2],cp[3])*k
		if ArtStyle.paper:
			# P12 paper: the count sits on the picture's corner like a badge,
			# leaving the card's text room for two lines.
			pill.size=Vector2(84,40)*k
			pill.position=at.call(float(pic[0])+float(pic[2])*0.45,float(pic[1])+float(pic[2])*0.6)
		pill.mouse_filter=Control.MOUSE_FILTER_IGNORE
		panel.add_child(pill)
		var cnt=text(pill,"x%d"%int(item.count),Rect2(Vector2.ZERO,pill.size),kp(30,k))
		cnt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		cnt.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	if not String(item.action).is_empty():
		var br: Array=L.button
		var act=Button.new()
		act.name="BagAction"
		act.flat=true
		act.focus_mode=Control.FOCUS_NONE
		act.position=at.call(br[0],br[1])
		act.size=Vector2(br[2],br[3])*k
		panel.add_child(act)
		bag_tex(act,"button_gold",Rect2(Vector2.ZERO,act.size))
		var al=text(act,item.action,Rect2(Vector2.ZERO,act.size),kp(32,k))
		al.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		al.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		al.mouse_filter=Control.MOUSE_FILTER_IGNORE
		act.pressed.connect(func(): bag_use(item))

func bag_tex(parent: Node, name: String, rect: Rect2, keep_aspect=false) -> TextureRect:
	var t=TextureRect.new()
	t.texture=ArtTexture.load_texture(BAG_ART+name+".png")
	t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED if keep_aspect else TextureRect.STRETCH_SCALE
	t.position=rect.position
	t.size=rect.size
	t.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t

## Bag pictures: the concept's own icons where it has them.
const BAG_ICONS={"food_apple":"apple","food_fish_treat":"fish","food_honey_cookie":"cookie","food_berry_bowl":"berries","food_carrot":"carrot","res://assets/art/meadows-v2/crate.png":"crate","res://assets/art/meadows-v2/pickup_carrot.png":"magic_carrot","res://assets/art/meadows-v2/sky_feather.png":"feather","res://assets/art/meadows-v2/pickup_key.png":"key","basket":"scroll"}
func bag_icon_rect(parent: Node, icon: String, rect: Rect2, big=false) -> TextureRect:
	var t=TextureRect.new()
	var concept=BAG_ICONS.get(icon,"")
	if big and concept=="apple": concept="apple_big"
	t.texture=ArtTexture.load_texture(BAG_ART+"items/"+concept+".png") if concept!="" and ResourceLoader.exists(BAG_ART+"items/"+concept+".png") else bag_icon(icon)
	t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position=rect.position
	t.size=rect.size
	t.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t

func reward_row(parent: Node, rect: Rect2, caption: String, amount: int, gold=false) -> Panel:
	var panel=CareArt.strip(parent,rect,gold)
	PetUI.compose(panel,caption,ArtTexture.load_texture(PetUI.COIN_PATH),"row" if gold else "left",22 if gold else 19)
	panel.get_node("Content/Symbol").name="CoinIcon"
	if gold: panel.get_node("Content/Caption").name="Total"
	else:
		var value=centered(panel,"+%d"%amount,Rect2(rect.size.x-PetUI.ROW_INSET-80,0,80,rect.size.y),22)
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	return panel

## A57 (P49): Adventure complete. The picnic plate (P49 with its UI removed)
## behind the result-p32 board, rows, total strip, memory row and buttons.
func p49_result() -> void:
	var adventure=mode=="result"
	var reward: Dictionary=app.game.state.quest_state.get("last_completion",{}) if adventure else {}
	var level_name="The Lost Picnic" if reward.get("level_id","W01_L01")=="W01_L01" else "Windmill Walk"
	var R49="result-p32"
	var k=maxf(logical_size.x/1672.0,logical_size.y/941.0)
	var o=(logical_size-Vector2(1672,941)*k)*0.5
	if portrait():
		k=logical_size.y/941.0*0.62
		o=Vector2(logical_size.x*0.5-560*k,0)
	var scene=TextureRect.new()
	scene.name="Celebration"
	scene.texture=ConceptScreen.tex(R49,"plate")
	scene.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	scene.stretch_mode=TextureRect.STRETCH_SCALE
	scene.position=o
	scene.size=Vector2(1672,941)*k
	scene.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(scene)
	var R=func(x: float,y: float,w: float,h: float) -> Rect2: return Rect2(o+Vector2(x,y)*k,Vector2(w,h)*k)
	var bk=k
	var B=R
	if portrait():
		# Phone upright: the picture on top, the board fills the lower part.
		bk=minf(safe.size.x/560.0,(safe.end.y-scene.size.y+40)/720.0)
		var bo=Vector2(safe.get_center().x-280*bk,safe.end.y-720*bk)
		B=func(x: float,y: float,w: float,h: float) -> Rect2: return Rect2(bo+(Vector2(x,y)-Vector2(1075,105))*bk,Vector2(w,h)*bk)
	var title=("A picnic, together!" if level_name=="The Lost Picnic" else "Delivery complete!") if adventure else "Lovely time together"
	var tr: Rect2=R.call(215,60,725,165) if not portrait() else Rect2(safe.position.x,safe.position.y,safe.size.x*0.8,safe.size.x*0.8*165/725)
	ConceptScreen.piece(content,R49,"title",tr,false)
	ConceptScreen.words(content,title,tr.grow_individual(-tr.size.x*0.1,-tr.size.y*0.22,-tr.size.x*0.12,-tr.size.y*0.2),int(tr.size.y*0.42)).name="ResultTitle"
	var cr: Rect2=R.call(1385,22,235,80) if not portrait() else Rect2(safe.end.x-safe.size.x*0.38,safe.position.y+tr.size.y+4,safe.size.x*0.38,safe.size.x*0.38*80/235)
	ConceptScreen.piece(content,R49,"coins",cr,false)
	# The canonical coin sits exactly on the pill's own coin (measured).
	var coin=ConceptScreen.piece(content,R49,"coin",Rect2(cr.position+Vector2(cr.size.x*0.077,cr.size.y*0.094),Vector2(cr.size.y*0.78,cr.size.y*0.78)))
	coin.name="CoinIcon"
	coin.texture=ArtTexture.load_texture(PetUI.COIN_PATH)
	wallet_value=ConceptScreen.words(content,str(app.game.state.coins),Rect2(cr.position.x+cr.size.x*0.42,cr.position.y,cr.size.x*0.52,cr.size.y),int(cr.size.y*0.5))
	var card=Control.new()
	card.name="ResultCard"
	content.add_child(card)
	ConceptScreen.slab(card,R49,"board",B.call(1075,105,560,820))
	var line=("Basket returned." if level_name=="The Lost Picnic" else "Food delivered to the windmill.") if adventure else "A lovely game of fetch. Happiness and bond saved."
	ConceptScreen.piece(card,R49,"ic_leaf",B.call(1118,160,50,56))
	ConceptScreen.piece(card,R49,"ic_leaf",B.call(1585,160,50,56)).flip_h=true
	wrapped(card,line,B.call(1165,140,420,90),int(48*bk))
	if adventure and not reward.is_empty():
		var rows=[["Adventure",reward.base_coins,"ic_map"],["Trail coins",reward.pickup_coins,"coin"],["First discovery",reward.discovery_coins,"ic_leaf"]]
		for i in rows.size():
			var y=245.0+i*107.0
			ConceptScreen.piece(card,R49,"row",B.call(1110,y,510,95),false)
			var ic=ConceptScreen.piece(card,R49,rows[i][2],B.call(1135,y+8,100,80))
			if rows[i][2]=="coin":
				ic.name="CoinIcon"
				ic.texture=ArtTexture.load_texture(PetUI.COIN_PATH)
			ConceptScreen.words(card,rows[i][0],B.call(1262,y,250,95),int(34*bk),PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)
			ConceptScreen.words(card,"+%d"%int(rows[i][1]),B.call(1500,y,100,95),int(38*bk))
		ConceptScreen.piece(card,R49,"total",B.call(1098,565,530,92),false)
		var tc=ConceptScreen.piece(card,R49,"coin",B.call(1172,560,86,100))
		tc.name="CoinIcon"
		tc.texture=ArtTexture.load_texture(PetUI.COIN_PATH)
		ConceptScreen.words(card,"Earned %d coins"%int(reward.total_coins),B.call(1262,565,340,92),int(42*bk),PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT).name="Total"
		ConceptScreen.piece(card,R49,"row",B.call(1110,665,510,95),false).name="MemoryRow"
		ConceptScreen.piece(card,R49,"basket",B.call(1135,652,110,95))
		ConceptScreen.words(card,"New memory" if reward.new_keepsake else "Memory collected",B.call(1262,662,260,50),int(34*bk),PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)
		ConceptScreen.words(card,"+%d Berry bowl%s · +%d bond XP"%[reward.meals,"s" if reward.meals>1 else "",reward.bond],B.call(1262,706,280,40),int(22*bk),Color("495873"),HORIZONTAL_ALIGNMENT_LEFT)
		ConceptScreen.piece(card,R49,"check",B.call(1525,682,60,60))
	var home=ConceptScreen.button(card,"MyPet",R49,"mypet",B.call(1100,785,255,95),app.show_home)
	ConceptScreen.piece(home,R49,"paw",Rect2(home.size.x*0.17,home.size.y*0.27,home.size.y*0.46,home.size.y*0.46))
	ConceptScreen.words(home,"My Pet",Rect2(home.size.x*0.36,0,home.size.x*0.58,home.size.y),int(36*bk),PetUI.INK,HORIZONTAL_ALIGNMENT_LEFT)
	home.text="My Pet"
	var again=ConceptScreen.button(card,"PlayAgain",R49,"again",B.call(1375,780,260,100),(func(): app.show_adventure(reward.get("level_id","W01_L01"))) if adventure else app.show_ball,"Play again",null,int(38*bk),Color("fff6e0"))
	again.tooltip_text="Play again"

func build_result() -> void:
	room_view.visible=false
	if ArtStyle.paper and ResourceLoader.exists("res://assets/ui/result-p32/plate.png"):
		p49_result()
		return
	var adventure=mode=="result"
	var wanted=(520.0 if adventure else 300.0) if not compact() else logical_size.y
	var reward: Dictionary=app.game.state.quest_state.get("last_completion",{}) if adventure else {}
	var level_name="The Lost Picnic" if reward.get("level_id","W01_L01")=="W01_L01" else "Windmill Walk"
	var parts=CareArt.header(content,safe,level_name if adventure else "Catch the Ball",Callable(),"",Callable())
	wallet_value=parts.wallet_label
	var top=safe.position.y+PetUI.H_HEADER+10
	var width=minf(440,safe.size.x) if not portrait() else safe.size.x
	var height=minf(safe.end.y-top,wanted)
	var x=safe.end.x-width if not portrait() else safe.position.x
	var y=top+(safe.end.y-top-height)*(1.0 if portrait() else .5)
	# Portrait: the celebration picture fills the space above the card so the
	# child, Foxy and Moss stay visible instead of sitting behind it.
	var scene=picture(content,"res://assets/ui/care-v1/picnic-finish.png",Rect2(Vector2.ZERO,Vector2(logical_size.x,y+40) if portrait() else logical_size),true)
	scene.name="Celebration"
	if portrait():
		# Keep the left two thirds, where the child, Foxy and Moss sit.
		var focus=AtlasTexture.new()
		focus.atlas=scene.texture
		focus.region=Rect2(0,0,scene.texture.get_width()*.66,scene.texture.get_height())
		scene.texture=focus
	content.move_child(scene,room_view.get_index()+1)
	var card=CareArt.panel(content,Rect2(x,y,width,height))
	card.name="ResultCard"
	var inner=width-32
	var title=text(card,("A picnic, together!" if level_name=="The Lost Picnic" else "Delivery complete!") if adventure else "Lovely time together",Rect2(16,12,inner,40),30)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var line=text(card,("Basket returned." if level_name=="The Lost Picnic" else "Food delivered to the windmill.") if adventure else "A lovely game of fetch. Happiness and bond saved.",Rect2(16,50,inner,30),18)
	line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var row_y=88.0
	if adventure and not reward.is_empty() and compact():
		var summary=text(card,"Adventure +%d · Trail +%d · Discovery +%d"%[reward.base_coins,reward.pickup_coins,reward.discovery_coins],Rect2(16,row_y-6,inner,26),15)
		summary.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		reward_row(card,Rect2(16,row_y+22,inner,46),"Earned %d coins"%reward.total_coins,reward.total_coins,true)
		var note=text(card,("New memory saved" if reward.new_keepsake else "Memory collected")+" · +%d Berry bowl · +%d bond XP"%[reward.meals,reward.bond],Rect2(16,row_y+72,inner,26),15)
		note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	elif adventure and not reward.is_empty():
		var row_h=clampf((height-88-196)/4.6,38,50)
		for entry in [["Adventure",reward.base_coins],["Trail coins",reward.pickup_coins],["First discovery",reward.discovery_coins]]:
			reward_row(card,Rect2(16,row_y,inner,row_h),entry[0],entry[1])
			row_y+=row_h+6
		reward_row(card,Rect2(16,row_y+2,inner,row_h+6),"Earned %d coins"%reward.total_coins,reward.total_coins,true)
		row_y+=row_h+16
		var memory=CareArt.strip(card,Rect2(16,row_y,inner,58))
		memory.name="MemoryRow"
		PetUI.compose(memory,("New memory" if reward.new_keepsake else "Memory collected")+"\n+%d Berry bowl%s · +%d bond XP · Saved"%[reward.meals,"s" if reward.meals>1 else "",reward.bond],CareArt.icon("basket"),"left",18)
		CareArt.picture(memory,"check",Rect2(inner-PetUI.ROW_INSET-30,14,30,30))
		row_y+=66
	var buttons_y=height-16-PetUI.H_PRIMARY
	var half=(inner-10)/2
	var home=button(card,"My Pet",Rect2(16,buttons_y,half,PetUI.H_PRIMARY),app.show_home,"paw",true)
	home.name="MyPet"
	var again=button(card,"Play again",Rect2(26+half,buttons_y,half,PetUI.H_PRIMARY),(func(): app.show_adventure(reward.get("level_id","W01_L01"))) if adventure else app.show_ball,"play")
	again.name="PlayAgain"
	PetUI.unify([home,again])

func refresh() -> void:
	if not is_instance_valid(app) or app.game.state.is_empty() or is_queued_for_deletion(): return
	var pet=app.game.pet()
	update_portrait()
	for key in need_bars:
		if is_instance_valid(need_bars[key]): need_bars[key].value=pet.needs[key]
	for key in meters:
		if not is_instance_valid(meters[key]): continue
		meters[key].value=minf(100,pet.bond_xp) if key=="bond" else pet.needs[key]
		if numbers.has(key) and is_instance_valid(numbers[key]):
			var v=int(pet.bond_xp if key=="bond" else pet.needs[key])
			# P47 shows every row out of 100 (bond: XP toward the next level).
			if mode=="details" and is_instance_valid(details_canvas) and details_canvas.get_child_count()>0 and ArtStyle.paper and ResourceLoader.exists("res://assets/ui/details-p32/board.png"): numbers[key].text="%d/100"%mini(v,100)
			else: numbers[key].text=str(v)+(" XP" if key=="bond" else "")
	if is_instance_valid(wallet_value): wallet_value.text=str(app.game.state.coins)
	if is_instance_valid(identity): identity.text=pet.name+(" · "+pet.growth_stage.capitalize() if ArtStyle.paper and mode=="home" else "")
	if is_instance_valid(stage_caption): stage_caption.text=pet.growth_stage.capitalize()+" · %d bond XP"%pet.bond_xp
	if is_instance_valid(feedback) and is_instance_valid(app.home):
		feedback.text=app.home.care_feedback
	for b in action_buttons:
		if is_instance_valid(app.home): b.disabled=app.home.busy()
	if is_instance_valid(rest_button): rest_button.get_node("Content/Caption").text="Wake" if pet.sleeping else "Rest"
	if is_instance_valid(care_button) and is_instance_valid(app.home): care_button.disabled=app.home.busy()
	if is_instance_valid(pet_badge) and is_instance_valid(app.home):
		var home=app.home
		var point=(app.world.transform*home.pet_art.position)/home.room_size*logical_size
		var pet_height=float(home.STAGE_HEIGHTS[pet.growth_stage])*home.room_scale()/home.room_size.y*logical_size.y
		if ArtStyle.paper: pet_height=home.fox_px()/home.room_size.y*logical_size.y
		# Beside Foxy's head, on the side away from the child, so it never covers him.
		pet_badge.position=Vector2(clampf(point.x+pet_height*.35,safe.position.x,safe.end.x-pet_badge.size.x),point.y-pet_height-pet_badge.size.y*.5).round()

func room_event(event: InputEvent) -> void:
	if mode!="home" or not home_overlay.is_empty() or not is_instance_valid(app.home) or app.home.busy(): return
	var point=Vector2.ZERO
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed: point=event.position
	elif event is InputEventScreenTouch and not event.pressed: point=event.position
	else: return
	point=point/logical_size*app.home.room_size
	var pet_height=float(app.home.STAGE_HEIGHTS[app.game.pet().growth_stage])*app.home.room_scale()
	if Rect2(app.home.pet_art.position-Vector2(pet_height*.65,pet_height),Vector2(pet_height*1.3,pet_height+10)).has_point(point): toggle_overlay("care")
	elif app.home.bed_bounds.has_point(point): request_care("sleep")
	elif app.home.wash_bounds().has_point(point): request_care("clean")
	elif point.y>app.home.floor_y-70: app.home.call_to(point.x)
