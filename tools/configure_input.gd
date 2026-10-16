extends SceneTree
## Keep editor-visible InputMap settings in step with the shared bootstrap defaults.
func _initialize() -> void:
	var bootstrap=load("res://scripts/main.gd").new()
	bootstrap._setup_input()
	for action in ["move_left","move_right","jump","interact","pet_ability","companion_menu","pause","reset_checkpoint","recall_pet"]:
		ProjectSettings.set_setting("input/"+action,{"deadzone":InputMap.action_get_deadzone(action),"events":InputMap.action_get_events(action)})
	var result=ProjectSettings.save()
	bootstrap.free()
	print("PETOPIA InputMap saved: ",result==OK)
	quit(0 if result==OK else 1)
