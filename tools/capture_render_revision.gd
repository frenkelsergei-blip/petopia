extends SceneTree
var main: Control
func _initialize() -> void: call_deferred("run")
func settle(n=10) -> void:
 for i in range(n): await physics_frame
 await RenderingServer.frame_post_draw
func shot(name_value: String) -> void:
 await settle()
 main.viewport.get_texture().get_image().save_png("res://docs/screenshots/v3-"+name_value+".png")
func run() -> void:
 root.size=Vector2i(1280,720)
 root.content_scale_size=Vector2i(1280,720)
 main=load("res://scenes/main/main.tscn").instantiate()
 main.automation_mode=true
 main.save_directory="user://v3-captures/"+str(Time.get_ticks_usec())
 root.add_child(main)
 main.game.adopt("Foxy")
 main.show_river_art_test()
 main.active_lab.player.reset_to(Vector2(1670,288))
 main.active_lab.interact()
 main.active_lab.player.reset_to(Vector2(1800,288))
 main.active_lab.companion.position=Vector2(1758,288)
 main.active_lab.camera.snap_to_target()
 await shot("crossing")
 DirAccess.make_dir_recursive_absolute("res://test-results/v3-motion")
 main.show_river_art_test()
 await settle(12)
 Input.action_press("move_right")
 for index in range(60):
  if index==24: Input.action_press("jump")
  if index==31: Input.action_release("jump")
  await settle(2)
  main.viewport.get_texture().get_image().save_png("res://test-results/v3-motion/%03d.png"%index)
 TouchControls.release_actions()
 main.show_ball()
 main.toast_time=0
 await shot("garden")
 root.size=Vector2i(390,844)
 await settle(16)
 root.get_texture().get_image().save_png("res://docs/screenshots/v3-garden-portrait.png")
 main.show_river_art_test()
 main.active_lab.player.reset_to(Vector2(1800,288))
 main.active_lab.companion.position=Vector2(1758,288)
 main.toast_time=0
 await settle(16)
 root.get_texture().get_image().save_png("res://docs/screenshots/v3-crossing-portrait.png")
 main.free()
 await process_frame
 print("PETOPIA V3: high-resolution crossing and garden, desktop and portrait")
 quit()
