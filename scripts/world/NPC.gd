extends "res://scripts/world/Interactable.gd"
## Townsperson — stylized realistic low-poly humanoid + dialogue.

const HumanoidBuilder = preload("res://scripts/character/HumanoidBuilder.gd")

@export var npc_id: String = ""
@export var display_name: String = "Townsperson"
@export var body_color: Color = Color(0.35, 0.32, 0.3)


func _ready() -> void:
	super._ready()
	interact_type = "npc"
	label = "Talk to %s" % display_name
	_build_mesh()


func _build_mesh() -> void:
	var data := {
		"gender": "neutral",
		"height": 1,
		"body_type": 1,
		"skin_tone": 1 + (npc_id.length() % 4),
		"hair_style": npc_id.length() % 4,
		"hair_color": npc_id.length() % 5,
		"eye_color": npc_id.length() % 4,
		"facial_hair": 1 if npc_id in ["suspect_marcus", "mayor_hart", "bartender_sam"] else 0,
		"outfit": 0,
		"accessory": 1 if npc_id == "dr_ellis" else 0,
		"badge": 1 if npc_id == "deputy_cole" else 0,
		"primary_color": body_color,
		"secondary_color": body_color.darkened(0.25),
	}
	HumanoidBuilder.build(self, data)
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.7
	col.shape = shape
	col.position.y = 0.9
	add_child(col)


func interact(_actor: Node) -> void:
	get_tree().call_group("hud", "open_dialogue", npc_id, display_name)
