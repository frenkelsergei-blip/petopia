extends SceneTree
## Interactive review entry. Keeps this lab session separate from personal progress.
func _initialize() -> void: call_deferred("run")
func run() -> void:
 root.size=Vector2i(500,920)
 root.content_scale_size=Vector2i(1280,720)
 var main=load("res://scenes/main/main.tscn").instantiate()
 main.save_directory="user://art-review-play"
 root.add_child(main)
 main.show_river_art_test()
 DisplayServer.window_set_title("PETOPIA · Updated playable art review")
