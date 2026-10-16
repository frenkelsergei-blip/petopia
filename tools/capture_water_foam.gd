extends SceneTree
var main: Control
func _initialize() -> void:call_deferred("run")
func settle(n=20) -> void:
 for i in range(n):await physics_frame
 await RenderingServer.frame_post_draw
func run() -> void:
 root.size=Vector2i(1280,720)
 root.content_scale_size=Vector2i(1280,720)
 main=load("res://scenes/main/main.tscn").instantiate()
 main.automation_mode=true
 main.save_directory="user://foam-capture/"+str(Time.get_ticks_usec())
 root.add_child(main)
 main.show_river_art_test()
 await settle()
 main.active_lab.interact()
 await settle(35)
 main.active_lab.player.reset_to(Vector2(1810,288))
 main.active_lab.companion.position=Vector2(1768,288)
 main.active_lab.camera.snap_to_target()
 main.toast_time=0
 main.toast_panel.visible=false
 await settle()
 DirAccess.make_dir_recursive_absolute("res://test-results/water-foam-motion")
 for index in range(60):
  await settle(2)
  var frame=root.get_texture().get_image()
  frame.save_png("res://test-results/water-foam-motion/%03d.png"%index)
  if index==0:
   frame.save_png("res://docs/screenshots/water-foam-desktop.png")
   frame.save_png("res://docs/screenshots/readability-water-contact.png")
  if index==30:frame.save_png("res://docs/screenshots/water-foam-later.png")
 root.size=Vector2i(390,844)
 await settle(25)
 root.get_texture().get_image().save_png("res://docs/screenshots/water-foam-portrait.png")
 root.get_texture().get_image().save_png("res://docs/screenshots/readability-water-portrait.png")
 main.free()
 await process_frame
 print("PETOPIA FOAM:60 rendered motion frames, actual desktop/portrait pile contacts")
 quit()
