extends SceneTree
var main: Control
func _initialize() -> void:call_deferred("run")
func settle(n=18) -> void:
 for i in range(n):await physics_frame
 await RenderingServer.frame_post_draw
func shot(label_value: String, level: Node2D, point: Vector2) -> void:
 level.player.reset_to(point)
 level.companion.position=point-Vector2(42,0)
 level.companion.safe_trail.clear()
 level.camera.snap_to_target()
 main.toast_time=0
 main.toast_panel.visible=false
 await settle()
 root.get_texture().get_image().save_png("res://docs/screenshots/readability-"+label_value+".png")
func run() -> void:
 root.size=Vector2i(1280,720)
 root.content_scale_size=Vector2i(1280,720)
 main=load("res://scenes/main/main.tscn").instantiate()
 main.automation_mode=true
 main.save_directory="user://readability-capture/"+str(Time.get_ticks_usec())
 root.add_child(main)
 main.game.adopt("Foxy")
 main.show_river_art_test()
 await shot("crank-ready",main.active_lab,Vector2(1620,288))
 main.active_lab.interact()
 await settle(35)
 await shot("crank-used",main.active_lab,Vector2(1620,288))
 await shot("water-contact",main.active_lab,Vector2(1810,288))
 await shot("checkpoint",main.active_lab,Vector2(1970,288))
 main.active_lab.meadow.marker.active=false
 main.active_lab.meadow.marker.activate()
 await shot("checkpoint-arrival",main.active_lab,Vector2(1970,288))
 await shot("finish-practice",main.active_lab,Vector2(2480,288))
 await shot("roots",main.active_lab,Vector2(2310,288))
 main.show_adventure("W01_L01")
 var level=main.active_adventure
 main.game.collect_trail_crates()
 level.player.reset_to(Vector2(1885,288))
 main.game.place_trail_crate_at("W01_L01",Vector2(1918,276))
 level.ability()
 level.open_cache()
 await settle()
 await shot("cache-and-crate",level,Vector2(1918,264))
 # Actual free-position preview, with portrait touch controls and child/pet context.
 root.size=Vector2i(390,844)
 level.player.reset_to(Vector2(500,288))
 level.companion.position=Vector2(455,288)
 level.camera.snap_to_target()
 await settle(25)
 main.toggle_bag()
 for button in main.bag_panel.find_children("*","Button",true,false):
  if button.text=="Place a crate":button.pressed.emit()
 await settle(12)
 level.crates.choose_at(Vector2(546.5,288),level.player.position)
 await settle(5)
 root.get_texture().get_image().save_png("res://docs/screenshots/readability-placement-portrait.png")
 main.placement_ui.confirm()
 await settle()
 root.get_texture().get_image().save_png("res://docs/screenshots/readability-placed-portrait.png")
 root.size=Vector2i(1280,720)
 level.run.basket=true
 level.meadow.basket=true
 await shot("picnic-arrival",level,Vector2(220,288))
 level.interact()
 await settle()
 root.get_texture().get_image().save_png("res://docs/screenshots/readability-picnic-complete.png")
 root.size=Vector2i(390,844)
 await settle(25)
 root.get_texture().get_image().save_png("res://docs/screenshots/readability-results-portrait.png")
 main.show_river_art_test()
 await settle(25)
 main.active_lab.interact()
 await settle(35)
 await shot("water-portrait",main.active_lab,Vector2(1810,288))
 main.free()
 await process_frame
 print("PETOPIA READABILITY CAPTURES COMPLETE")
 quit()
