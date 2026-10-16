extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var world=Node2D.new()
 root.add_child(world)
 var shape=SS2D_Shape.new()
 shape.scale=Vector2.ONE*0.075
 var material=SS2D_Material_Shape.new()
 var fills: Array[Texture2D]=[load("res://art/rock-material-v2.png")]
 material.fill_textures=fills
 material.fill_texture_scale=0.14
 var edge=SS2D_Material_Edge.new()
 var edges: Array[Texture2D]=[load("res://art/grass-fringe.png")]
 edge.textures=edges
 edge.use_corner_texture=false
 edge.use_taper_texture=false
 var meta=SS2D_Material_Edge_Metadata.new()
 meta.edge_material=edge
 meta.normal_range=SS2D_NormalRange.new(40,100)
 meta.weld=true
 meta.offset=0.22
 material.add_edge_material(meta)
 shape.shape_material=material
 var curve=Curve2D.new()
 for point in [Vector2(-20,230),Vector2(160,230),Vector2(220,200),Vector2(360,200),Vector2(405,235),Vector2(470,300),Vector2(650,300),Vector2(650,420),Vector2(-20,420)]:
  curve.add_point(point/.075)
 curve.set_point_in(2,Vector2(-30,0)/.075)
 curve.set_point_out(2,Vector2(30,0)/.075)
 curve.set_point_in(3,Vector2(-35,0)/.075)
 curve.set_point_out(3,Vector2(30,0)/.075)
 shape.get_point_array().set_from_curve(curve)
 shape.get_point_array().close_shape()
 world.add_child(shape)
 var metadata=JSON.parse_string(FileAccess.get_file_as_string("res://art/run-metadata.json"))
 for item in [["explorer","explorer-run-v3.png",42,Vector2(310,200)],["foxy_baby","foxy-run.png",24,Vector2(270,200)]]:
  var row=metadata[item[0]]
  var frame=row.frames[0]
  var sprite=Sprite2D.new()
  var tex=AtlasTexture.new()
  tex.atlas=load("res://art/"+item[1])
  tex.region=Rect2(frame.region[0],frame.region[1],frame.region[2],frame.region[3])
  sprite.texture=tex
  sprite.centered=false
  var density=float(item[2])/row.body_height
  sprite.scale=Vector2.ONE*density
  sprite.position=item[3]-Vector2(frame.pivot[0],frame.pivot[1])*density
  sprite.z_index=2
  world.add_child(sprite)
 for i in range(10):await process_frame
 await RenderingServer.frame_post_draw
 var path=ProjectSettings.globalize_path("res://../../docs/screenshots/terrain-toolkit-evaluation.png")
 root.get_texture().get_image().save_png(path)
 var report={"engine":Engine.get_version_info().string,"generated_edges":shape._edges.size(),"scope":"Isolated SmartShape2D shape/material compatibility spike with PETOPIA sources and child/pet at game scale. No production migration, no physics/camera/save change. Correct corner/side artwork still required."}
 var file=FileAccess.open("res://../../test-results/terrain-toolkit.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"\t"))
 print("PETOPIA TOOLKIT ",JSON.stringify(report))
 world.free()
 await process_frame
 quit()
