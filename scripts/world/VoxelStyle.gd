extends RefCounted
## Minecraft-style helpers: flat block materials + blocky humanoids.


static func block_material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	mat.metallic = 0.0
	# Flat look — no fancy PBR shine
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Nearest-neighbor vibe if textures are added later
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat


static func make_block(size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = block_material(color)
	return mi


## Build a Minecraft-ish Steve-style body under parent. Origin at feet.
static func build_humanoid(parent: Node3D, skin: Color, shirt: Color, pants: Color, accent: Color = Color(0.15, 0.15, 0.15)) -> void:
	# Clear previous visual parts (keep CollisionShape if any)
	for c in parent.get_children():
		if c is MeshInstance3D and str(c.name).begins_with("Vox"):
			c.queue_free()

	# Legs
	_part(parent, "VoxLegL", Vector3(0.28, 0.72, 0.28), Vector3(-0.16, 0.36, 0.0), pants)
	_part(parent, "VoxLegR", Vector3(0.28, 0.72, 0.28), Vector3(0.16, 0.36, 0.0), pants)
	# Body / torso
	_part(parent, "VoxBody", Vector3(0.56, 0.72, 0.32), Vector3(0.0, 1.08, 0.0), shirt)
	# Arms
	_part(parent, "VoxArmL", Vector3(0.24, 0.72, 0.24), Vector3(-0.42, 1.08, 0.0), shirt.lightened(0.05))
	_part(parent, "VoxArmR", Vector3(0.24, 0.72, 0.24), Vector3(0.42, 1.08, 0.0), shirt.lightened(0.05))
	# Head (big blocky head)
	_part(parent, "VoxHead", Vector3(0.56, 0.56, 0.56), Vector3(0.0, 1.72, 0.0), skin)
	# Hair / hat top slab
	_part(parent, "VoxHair", Vector3(0.58, 0.12, 0.58), Vector3(0.0, 2.04, 0.0), accent)
	# Eyes (tiny black blocks on face)
	_part(parent, "VoxEyeL", Vector3(0.1, 0.1, 0.06), Vector3(-0.12, 1.78, 0.28), Color(0.05, 0.05, 0.08))
	_part(parent, "VoxEyeR", Vector3(0.1, 0.1, 0.06), Vector3(0.12, 1.78, 0.28), Color(0.05, 0.05, 0.08))
	# Smile-ish mouth
	_part(parent, "VoxMouth", Vector3(0.2, 0.06, 0.05), Vector3(0.0, 1.62, 0.28), Color(0.35, 0.15, 0.12))


static func _part(parent: Node3D, part_name: String, size: Vector3, pos: Vector3, color: Color) -> void:
	var mi := make_block(size, color)
	mi.name = part_name
	mi.position = pos
	parent.add_child(mi)


## Minecraft-ish palette
const GRASS_TOP := Color(0.35, 0.72, 0.22)
const GRASS_SIDE := Color(0.45, 0.55, 0.22)
const DIRT := Color(0.55, 0.38, 0.22)
const STONE := Color(0.55, 0.55, 0.55)
const COBBLE := Color(0.45, 0.45, 0.48)
const OAK := Color(0.55, 0.38, 0.18)
const LEAVES := Color(0.22, 0.58, 0.18)
const WATER := Color(0.22, 0.42, 0.85, 0.75)
const SAND := Color(0.86, 0.80, 0.55)
const PLANKS := Color(0.72, 0.58, 0.32)
const BRICK := Color(0.62, 0.32, 0.28)
const GLASS := Color(0.7, 0.85, 0.95, 0.45)
const IRON := Color(0.75, 0.75, 0.80)
const GOLD := Color(0.95, 0.78, 0.2)
const WOOL_BLUE := Color(0.25, 0.35, 0.75)
const WOOL_RED := Color(0.7, 0.2, 0.2)
const WOOL_GREEN := Color(0.25, 0.55, 0.3)
const SKY := Color(0.55, 0.75, 0.95)
const CLOUD := Color(0.95, 0.95, 0.98)
