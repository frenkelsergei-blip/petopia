class_name LevelDefinition
extends Resource
## Static authored layout, never personal progress.

@export var level_id = ""
@export var title = ""
@export var world_width = 3280.0
@export var ground: Array[Rect2] = []
@export var coin_positions: Array[Vector2] = []
@export var safe_anchors: Array[Vector2] = []
@export var jump_links: Array[Vector4] = []
@export var stream = Rect2(900,288,180,100)
@export var crank = Vector2(845,288)
@export var checkpoint = Vector2(1145,288)
@export var discovery = Vector2(1915,288)
@export var basket = Vector2(3043,288)
@export var return_gate = Vector2(3100,288)
@export var arrival = Vector2(165,288)

func ground_y(x: float) -> float:
	var surface = INF
	for r in ground:
		if x >= r.position.x and x <= r.end.x: surface = minf(surface,r.position.y)
	return surface
