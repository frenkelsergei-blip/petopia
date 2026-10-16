extends SceneTree
var main: Control
func _initialize() -> void: call_deferred("run")
func settle(n=12) -> void:
 for i in range(n):await physics_frame
 await RenderingServer.frame_post_draw
func shot(label_value: String) -> void:
 main.toast_time=0
 main.toast_panel.visible=false
 await settle()
 root.get_texture().get_image().save_png("res://docs/screenshots/interaction-"+label_value+".png")
func run() -> void:
 root.size=Vector2i(1280,720)
 root.content_scale_size=Vector2i(1280,720)
 main=load("res://scenes/main/main.tscn").instantiate()
 main.automation_mode=true
 main.save_directory="user://focus-captures/"+str(Time.get_ticks_usec())
 root.add_child(main)
 main.game.adopt("Foxy")
 main.show_river_art_test()
 await shot("near-crank")
 main.active_lab.player.reset_to(Vector2(1500,256))
 main.active_lab.camera.snap_to_target()
 await shot("out-of-range")
 main.show_adventure("W01_L01")
 main.active_adventure.player.reset_to(Vector2(2990,288))
 main.active_adventure.companion.position=Vector2(2950,288)
 main.active_adventure.camera.snap_to_target()
 await shot("basket")
 root.size=Vector2i(390,844)
 main.show_river_art_test()
 await settle(24)
 await shot("portrait")
 main.free()
 await process_frame
 print("PETOPIA INTERACTION: nearby crank, out of range, basket and portrait")
 quit()
