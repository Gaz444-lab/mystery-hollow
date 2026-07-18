extends Interactable
class_name TownNPC
## Townsperson with dialogue + relationship.

@export var npc_id: String = ""
@export var display_name: String = "Townsperson"
@export var body_color: Color = Color(0.4, 0.35, 0.3)

var _mesh: MeshInstance3D


func _ready() -> void:
	super._ready()
	interact_type = "npc"
	label = "Talk to %s" % display_name
	_build_mesh()


func _build_mesh() -> void:
	_mesh = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.32
	cap.height = 1.5
	_mesh.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	_mesh.material_override = mat
	_mesh.position.y = 0.9
	add_child(_mesh)
	var head := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.25
	head.mesh = s
	head.position.y = 1.85
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.85, 0.7, 0.55)
	head.material_override = hmat
	add_child(head)
	# Collision
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	col.shape = shape
	col.position.y = 0.9
	add_child(col)


func interact(actor: Node) -> void:
	get_tree().call_group("hud", "open_dialogue", npc_id, display_name)
