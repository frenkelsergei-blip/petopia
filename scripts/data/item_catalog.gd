class_name ItemCatalog
extends RefCounted
const ITEMS = [preload("res://data/items/berry_bowl.tres"),preload("res://data/items/ball_sun.tres"),preload("res://data/items/blue_collar.tres")]
static func find(item_id: String) -> ItemDefinition:
	for item in ITEMS:
		if item.item_id == item_id: return item
	return null
