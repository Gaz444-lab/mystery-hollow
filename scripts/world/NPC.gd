extends "res://scripts/world/Interactable.gd"
## Blocky Minecraft-style townsfolk.

@export var npc_id: String = ""
@export var display_name: String = "Townsperson"
@export var body_color: Color = Color(0.4, 0.35, 0.3)


func _ready() -> void:
	super._ready()
	interact_type = "npc"
	label = "Talk to %s" % display_name
	_build_mesh()


func _build_mesh() -> void:
	var VoxelStyle = load("res://scripts/world/VoxelStyle.gd")
	var skin := Color(0.9, 0.72, 0.55)
	var pants := Color(0.25, 0.25, 0.35)
	var hair := Color(0.2, 0.12, 0.08)
	# Slight variety from shirt color hash
	var h: float = fmod(body_color.r * 7.0 + body_color.g * 3.0, 1.0)
	if h > 0.6:
		hair = Color(0.55, 0.35, 0.15)
	elif h > 0.3:
		hair = Color(0.12, 0.1, 0.1)
	VoxelStyle.build_humanoid(self, skin, body_color, pants, hair)
	# Collision capsule for talking range
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.9
	col.shape = shape
	col.position.y = 0.95
	add_child(col)


func interact(_actor: Node) -> void:
	get_tree().call_group("hud", "open_dialogue", npc_id, display_name)
