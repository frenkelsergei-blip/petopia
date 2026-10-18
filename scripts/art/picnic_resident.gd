class_name PicnicResident
extends Node2D
## Three explicitly authored reactions, not a completed locomotion animation set.
var texture: Texture2D
var reaction="idle"
var remaining=0.0
var reduced_motion=false
var sprite: Sprite2D
var paper_poses: Array[Texture2D]=[]
func _ready() -> void:
 texture=ArtTexture.load_texture("res://assets/art/resident-v1/moss-reactions.png")
 sprite=Sprite2D.new()
 sprite.centered=false
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 add_child(sprite)
 react("wave",1.8)
func react(value: String, duration=1.4) -> void:
 reaction=value
 remaining=duration
func _process(delta: float) -> void:
 remaining=maxf(0,remaining-delta)
 if remaining<=0:reaction="idle"
 sprite.visible=ArtStyle.enabled
 var index=0 if reaction=="idle" else (1 if reaction=="wave" else 2)
 if ArtStyle.paper:
  # A55: Moss as a paper puppet (three poses), feet on the ground.
  if paper_poses.is_empty():
   for n in ["moss_idle","moss_wave","moss_happy"]:
    var path="res://assets/art/meadow-p31/%s.png"%n
    if not ResourceLoader.exists(path): path="res://assets/art/paper-v1/%s.png"%n
    paper_poses.append(ArtTexture.load_texture(path))
  var t: Texture2D=paper_poses[index]
  sprite.texture=t
  sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
  sprite.scale=Vector2.ONE*(44.0/paper_poses[0].get_height())
  sprite.position=Vector2(-t.get_width()*0.5,-t.get_height())*sprite.scale
  return
 var region=Rect2(index*724+140,45,470,630)
 var tex=ArtStyle.region_texture(texture,[region.position.x,region.position.y,region.size.x,region.size.y],"moss_"+str(index))
 sprite.texture=tex
 sprite.scale=Vector2.ONE*(42.0/604)
 sprite.position=Vector2(-([424.5,387.0,364.5][index]-140),-([662,662,663][index]-45))*sprite.scale
 queue_redraw()
func _draw() -> void:
 if ArtStyle.enabled:return
 draw_style_box(PetUI.style(Color("afa5c7")),Rect2(-9,-26,18,26))
 draw_circle(Vector2(3,-19),1.5,Color("283540"))
