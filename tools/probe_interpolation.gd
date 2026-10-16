extends SceneTree
var moving: Node2D
func _initialize() -> void: call_deferred("run")
func run() -> void:
 Engine.physics_ticks_per_second=10
 root.size=Vector2i(320,160)
 root.content_scale_size=Vector2i(320,160)
 moving=Node2D.new()
 root.add_child(moving)
 for item in [[30,Color.RED,Node.PHYSICS_INTERPOLATION_MODE_OFF],[90,Color.GREEN,Node.PHYSICS_INTERPOLATION_MODE_INHERIT]]:
  var visual=Polygon2D.new()
  visual.position.y=item[0]
  visual.polygon=PackedVector2Array([Vector2(0,0),Vector2(10,0),Vector2(10,10),Vector2(0,10)])
  visual.color=item[1]
  visual.physics_interpolation_mode=item[2]
  moving.add_child(visual)
 physics_frame.connect(func(): moving.position.x+=12)
 DirAccess.make_dir_recursive_absolute("res://test-results/interpolation-probe")
 for index in range(24):
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://test-results/interpolation-probe/%03d.png"%index)
 moving.free()
 quit()
