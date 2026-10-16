class_name TrailTools
extends RefCounted
const PADS={
	"W01_L01":[Vector2(1918,288),Vector2(2018,288)],
	"W01_L02":[Vector2(1544,272),Vector2(1512,272)]
}
static func pads_for(level_id: String) -> Array[Vector2]:
	var result: Array[Vector2]=[]
	result.assign(PADS.get(level_id,[]))
	return result

# Old numbered layouts remain readable; new placements store world coordinates.
static func legacy_positions(level_id: String, counts: Dictionary) -> Array[Vector2]:
	var result: Array[Vector2]=[]
	var old_pads=pads_for(level_id)
	for key in counts:
		for layer in range(int(counts[key])):
			result.append(old_pads[int(key)]-Vector2(0,12+layer*24))
	return result
static func layout_for(level_id: String) -> LevelDefinition:
	return load("res://data/levels/"+("lost_picnic" if level_id=="W01_L01" else "windmill_walk")+".tres")
static func valid_positions(level_id: String, points: Array[Vector2]) -> bool:
	if level_id not in ["W01_L01","W01_L02"] or points.size()>3:return false
	var level=layout_for(level_id)
	var solids: Array[Rect2]=level.ground.duplicate()
	var remaining: Array[Rect2]=[]
	for point in points:
		if not is_finite(point.x) or not is_finite(point.y) or point.x<12 or point.x>level.world_width-12 or point.y<12 or point.y>376:return false
		var box=Rect2(point-Vector2(12,12),Vector2(24,24))
		for solid in solids:
			if box.grow(-.05).intersects(solid):return false
		for other in remaining:
			if box.grow(-.05).intersects(other):return false
		remaining.append(box)
	# Resolve from the ground up: floating/cyclic stacks cannot validate.
	while not remaining.is_empty():
		var progressed=false
		for i in range(remaining.size()-1,-1,-1):
			var box=remaining[i]
			for solid in solids:
				if absf(box.end.y-solid.position.y)<.1 and box.position.x>=solid.position.x-.1 and box.end.x<=solid.end.x+.1:
					solids.append(box)
					remaining.remove_at(i)
					progressed=true
					break
		if not progressed:return false
	return true
