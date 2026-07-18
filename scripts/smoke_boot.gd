extends SceneTree
## Headless smoke test.
## godot --path . --headless -s res://scripts/smoke_boot.gd

var _done := false
var _started := false
var _t := 0.0


func _process(delta: float) -> bool:
	if _done:
		return true
	if not _started:
		_started = true
		print("SMOKE: starting")
		var gs = root.get_node_or_null("GameState")
		if gs == null:
			print("SMOKE FAIL: GameState autoload missing")
			_done = true
			return true
		gs.new_game("present", {
			"name": "SmokeTest",
			"gender": "neutral",
			"body_type": 1,
			"skin_tone": 2,
			"hair_style": 0,
			"hair_color": 0,
			"face_style": 0,
			"outfit": 0,
			"accessory": 0,
			"primary_color": Color(0.2, 0.25, 0.4),
			"secondary_color": Color(0.7, 0.7, 0.5),
		})
		var err := change_scene_to_file("res://scenes/world/Town.tscn")
		print("SMOKE: change_scene err=", err)
		return false
	_t += delta
	if _t < 2.0:
		return false
	# Evaluate
	var scene := current_scene
	if scene == null:
		print("SMOKE FAIL: no current_scene")
		_done = true
		return true
	print("SMOKE: scene=", scene.name, " children=", scene.get_child_count())
	var player := scene.find_child("Player", true, false)
	if player == null:
		print("SMOKE FAIL: no Player")
		for c in scene.get_children():
			print("  child: ", c.name, " ", c.get_class())
		_done = true
		return true
	print("SMOKE: player at ", (player as Node3D).global_position)
	var cam := scene.find_child("Camera3D", true, false)
	if cam == null:
		print("SMOKE FAIL: no Camera3D")
		_done = true
		return true
	print("SMOKE: camera current=", (cam as Camera3D).current)
	var world_root := scene.find_child("WorldRoot", true, false)
	if world_root == null:
		print("SMOKE FAIL: no WorldRoot")
		_done = true
		return true
	print("SMOKE: WorldRoot children=", world_root.get_child_count())
	if world_root.get_child_count() < 5:
		print("SMOKE FAIL: world not built")
		_done = true
		return true
	print("SMOKE PASS")
	_done = true
	return true
