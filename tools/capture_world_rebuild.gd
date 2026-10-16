extends SceneTree
var main: Control
func _initialize() -> void: call_deferred("run")
func settle(n=12) -> void:
 for i in range(n): await physics_frame
 await RenderingServer.frame_post_draw
func shot(label_value: String, level: Node2D, point: Vector2) -> void:
 level.player.reset_to(point)
 level.companion.position=point-Vector2(40,0)
 level.companion.safe_trail.clear()
 level.camera.snap_to_target()
 main.toast_time=0
 main.toast_panel.visible=false
 await settle(22)
 root.get_texture().get_image().save_png("res://docs/screenshots/v4-"+label_value+".png")
func run() -> void:
 root.size=Vector2i(1280,720)
 root.content_scale_size=Vector2i(1280,720)
 main=load("res://scenes/main/main.tscn").instantiate()
 main.automation_mode=true
 main.save_directory="user://v4-captures/"+str(Time.get_ticks_usec())
 root.add_child(main)
 main.game.adopt("Foxy")
 main.game.state.settings.reduced_motion=true
 main.show_river_art_test()
 await settle()
 main.active_lab.interact()
 await settle(30)
 var lab=main.active_lab
 for entry in [["lab-gap",Vector2(620,288)],["lab-step",Vector2(1060,256)],["lab-banks",Vector2(1460,256)],["crossing",Vector2(1810,288)],["checkpoint",Vector2(1965,288)],["treasure",Vector2(2160,288)]]:
  await shot(entry[0],lab,entry[1])
 main.show_adventure("W01_L01")
 main.active_adventure.add_bridge()
 await shot("picnic-join",main.active_adventure,Vector2(1650,272))
 main.show_adventure("W01_L02")
 await shot("windmill-upper",main.active_adventure,Vector2(1460,288))
 main.show_ball()
 await settle()
 root.get_texture().get_image().save_png("res://docs/screenshots/v4-garden.png")
 root.size=Vector2i(390,844)
 await settle(24)
 root.get_texture().get_image().save_png("res://docs/screenshots/v4-garden-portrait.png")
 main.show_river_art_test()
 await settle()
 main.active_lab.interact()
 await settle(30)
 await shot("crossing-portrait",main.active_lab,Vector2(1810,288))
 root.size=Vector2i(1280,720)
 main.show_river_art_test()
 await settle()
 main.active_lab.player.art.reduced_motion=true
 main.active_lab.companion.art.reduced_motion=true
 DirAccess.make_dir_recursive_absolute("res://test-results/v4-motion")
 # Show an actual interaction, run, jump and landing in one capture sequence.
 for index in range(130):
  if index==5: main.active_lab.interact()
  if index==20: Input.action_press("move_right")
  if index==65: Input.action_press("jump")
  if index==72: Input.action_release("jump")
  if index==115: Input.action_release("move_right")
  await settle(2)
  root.get_texture().get_image().save_png("res://test-results/v4-motion/%03d.png"%index)
 TouchControls.release_actions()
 main.free()
 await process_frame
 print("PETOPIA V4: whole-route samples, garden, portrait and reduced-motion run/crank/jump")
 quit()
