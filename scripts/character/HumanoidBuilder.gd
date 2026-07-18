extends RefCounted
## Stylized realistic low-poly humanoid (NOT cartoon/Minecraft).
## Twin Peaks / grounded detective tone — clean proportions, muted materials.


static func mat(color: Color, rough: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = 0.0
	return m


static func clear_visuals(parent: Node3D) -> void:
	for c in parent.get_children():
		if c is MeshInstance3D and str(c.name).begins_with("H_"):
			c.queue_free()


## Build under parent. Origin at feet. scale from body_type 0-2.
static func build(parent: Node3D, data: Dictionary) -> void:
	clear_visuals(parent)
	var body_type: int = int(data.get("body_type", 1))
	var height_scale: float = 0.92 + body_type * 0.06 + float(data.get("height", 1)) * 0.04
	var skin := _skin(int(data.get("skin_tone", 2)))
	var hair_c := _hair(int(data.get("hair_color", 0)))
	var outfit: int = int(data.get("outfit", 0))
	var primary: Color = _as_color(data.get("primary_color", Color(0.18, 0.22, 0.32)))
	var secondary: Color = _as_color(data.get("secondary_color", Color(0.35, 0.32, 0.28)))
	var eye_c := _eye(int(data.get("eye_color", 0)))
	var gender: String = str(data.get("gender", "neutral"))

	# Legs (pants)
	_box(parent, "H_LegL", Vector3(0.18, 0.55 * height_scale, 0.18), Vector3(-0.11, 0.28 * height_scale, 0), secondary)
	_box(parent, "H_LegR", Vector3(0.18, 0.55 * height_scale, 0.18), Vector3(0.11, 0.28 * height_scale, 0), secondary)
	# Shoes
	_box(parent, "H_ShoeL", Vector3(0.2, 0.08, 0.28), Vector3(-0.11, 0.04, 0.04), Color(0.12, 0.1, 0.09))
	_box(parent, "H_ShoeR", Vector3(0.2, 0.08, 0.28), Vector3(0.11, 0.04, 0.04), Color(0.12, 0.1, 0.09))
	# Torso (coat / shirt)
	var torso_w := 0.42 + body_type * 0.04
	_box(parent, "H_Torso", Vector3(torso_w, 0.55 * height_scale, 0.24), Vector3(0, 0.72 * height_scale, 0), primary)
	# Collar / lapel accent
	_box(parent, "H_Collar", Vector3(torso_w * 0.9, 0.08, 0.26), Vector3(0, 0.98 * height_scale, 0.02), primary.darkened(0.15))
	# Arms
	_box(parent, "H_ArmL", Vector3(0.12, 0.5 * height_scale, 0.12), Vector3(-(torso_w * 0.55 + 0.08), 0.7 * height_scale, 0), primary.lightened(0.05))
	_box(parent, "H_ArmR", Vector3(0.12, 0.5 * height_scale, 0.12), Vector3(torso_w * 0.55 + 0.08, 0.7 * height_scale, 0), primary.lightened(0.05))
	# Hands
	_box(parent, "H_HandL", Vector3(0.1, 0.1, 0.1), Vector3(-(torso_w * 0.55 + 0.08), 0.42 * height_scale, 0), skin)
	_box(parent, "H_HandR", Vector3(0.1, 0.1, 0.1), Vector3(torso_w * 0.55 + 0.08, 0.42 * height_scale, 0), skin)
	# Neck + head
	var head_y := 1.15 * height_scale
	_box(parent, "H_Neck", Vector3(0.12, 0.1, 0.12), Vector3(0, head_y - 0.12, 0), skin)
	var head := MeshInstance3D.new()
	head.name = "H_Head"
	var sphere := SphereMesh.new()
	sphere.radius = 0.16 if gender != "masculine" else 0.17
	sphere.height = 0.34
	head.mesh = sphere
	head.position = Vector3(0, head_y, 0)
	head.material_override = mat(skin, 0.7)
	parent.add_child(head)
	# Hair volume (era/style index shapes)
	_hair_mesh(parent, int(data.get("hair_style", 0)), hair_c, head_y, gender)
	# Eyes
	_box(parent, "H_EyeL", Vector3(0.035, 0.025, 0.02), Vector3(-0.05, head_y + 0.02, 0.14), eye_c)
	_box(parent, "H_EyeR", Vector3(0.035, 0.025, 0.02), Vector3(0.05, head_y + 0.02, 0.14), eye_c)
	# Facial hair optional
	if int(data.get("facial_hair", 0)) > 0 and gender != "feminine":
		_box(parent, "H_Beard", Vector3(0.14, 0.08, 0.08), Vector3(0, head_y - 0.1, 0.1), hair_c.darkened(0.1))
	# Accessories
	match int(data.get("accessory", 0)):
		1: # glasses
			_box(parent, "H_GlassL", Vector3(0.06, 0.04, 0.02), Vector3(-0.05, head_y + 0.02, 0.155), Color(0.1, 0.1, 0.12))
			_box(parent, "H_GlassR", Vector3(0.06, 0.04, 0.02), Vector3(0.05, head_y + 0.02, 0.155), Color(0.1, 0.1, 0.12))
		2: # hat
			_box(parent, "H_Hat", Vector3(0.28, 0.08, 0.28), Vector3(0, head_y + 0.18, 0), Color(0.15, 0.12, 0.1))
			_box(parent, "H_Brim", Vector3(0.36, 0.03, 0.36), Vector3(0, head_y + 0.14, 0), Color(0.12, 0.1, 0.08))
		3: # watch (wrist)
			_box(parent, "H_Watch", Vector3(0.06, 0.04, 0.08), Vector3(torso_w * 0.55 + 0.08, 0.5 * height_scale, 0.06), Color(0.7, 0.65, 0.4))
		_:
			pass
	# Badge for detective
	if int(data.get("badge", 1)) != 0:
		_box(parent, "H_Badge", Vector3(0.06, 0.08, 0.02), Vector3(torso_w * 0.25, 0.8 * height_scale, 0.13), Color(0.75, 0.65, 0.25))


static func _box(parent: Node3D, n: String, size: Vector3, pos: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = n
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat(color)
	parent.add_child(mi)


static func _hair_mesh(parent: Node3D, style: int, color: Color, head_y: float, gender: String) -> void:
	match style:
		0: # short
			_box(parent, "H_Hair", Vector3(0.32, 0.1, 0.32), Vector3(0, head_y + 0.12, -0.02), color)
		1: # medium
			_box(parent, "H_Hair", Vector3(0.34, 0.14, 0.34), Vector3(0, head_y + 0.12, 0), color)
			_box(parent, "H_HairBack", Vector3(0.28, 0.2, 0.12), Vector3(0, head_y, -0.12), color)
		2: # long
			_box(parent, "H_Hair", Vector3(0.34, 0.12, 0.34), Vector3(0, head_y + 0.12, 0), color)
			_box(parent, "H_HairLong", Vector3(0.3, 0.35, 0.14), Vector3(0, head_y - 0.05, -0.12), color)
		3: # slicked
			_box(parent, "H_Hair", Vector3(0.3, 0.08, 0.32), Vector3(0, head_y + 0.14, 0.02), color)
		_:
			_box(parent, "H_Hair", Vector3(0.32, 0.1, 0.32), Vector3(0, head_y + 0.12, 0), color)
	if gender == "feminine" and style == 0:
		_box(parent, "H_HairSide", Vector3(0.12, 0.22, 0.1), Vector3(-0.14, head_y, 0), color)


static func _skin(i: int) -> Color:
	var tones := [
		Color(0.96, 0.86, 0.76), Color(0.9, 0.76, 0.62), Color(0.8, 0.62, 0.48),
		Color(0.62, 0.42, 0.3), Color(0.42, 0.28, 0.2), Color(0.28, 0.18, 0.14),
	]
	return tones[clampi(i, 0, tones.size() - 1)]


static func _hair(i: int) -> Color:
	var c := [
		Color(0.12, 0.09, 0.07), Color(0.28, 0.16, 0.1), Color(0.45, 0.28, 0.12),
		Color(0.55, 0.4, 0.2), Color(0.55, 0.55, 0.58), Color(0.85, 0.75, 0.55),
	]
	return c[clampi(i, 0, c.size() - 1)]


static func _eye(i: int) -> Color:
	var c := [Color(0.25, 0.4, 0.55), Color(0.3, 0.45, 0.25), Color(0.4, 0.28, 0.18), Color(0.2, 0.2, 0.22), Color(0.45, 0.5, 0.55)]
	return c[clampi(i, 0, c.size() - 1)]


static func _as_color(v: Variant) -> Color:
	if v is Color:
		return v
	if v is Dictionary:
		return Color(float(v.get("r", 0.2)), float(v.get("g", 0.2)), float(v.get("b", 0.3)))
	return Color(0.18, 0.22, 0.32)
