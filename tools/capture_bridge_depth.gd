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
 main.save_directory="user://bridge-depth-capture/"+str(Time.get_ticks_usec())
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
 root.get_texture().get_image().save_png("res://docs/screenshots/bridge-depth-after.png")
 root.get_texture().get_image().save_png("res://docs/screenshots/readability-water-contact.png")
 root.size=Vector2i(390,844)
 await settle(25)
 root.get_texture().get_image().save_png("res://docs/screenshots/bridge-depth-portrait.png")
 root.get_texture().get_image().save_png("res://docs/screenshots/readability-water-portrait.png")
 main.free()
 await process_frame
 print("PETOPIA BRIDGE DEPTH: original river/deck, longer final pile; desktop/portrait captures")
 quit()
