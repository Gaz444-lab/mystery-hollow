extends Node3D
## Builds Mystery Hollow from primitives — modular, era-tinted open world.

const TOWN_SIZE := 80.0
# Preload scripts (do NOT rely on global class_name — that fails on cold start / some Macs)
const PlayerScene = preload("res://scenes/player/Player.tscn")
const InteractableScript = preload("res://scripts/world/Interactable.gd")
const NpcScript = preload("res://scripts/world/NPC.gd")

@onready var world_root: Node3D = $WorldRoot
@onready var sun: DirectionalLight3D = $Sun
@onready var env: WorldEnvironment = $WorldEnvironment

var _player: CharacterBody3D


func _ready() -> void:
	add_to_group("game_root")
	# Environment FIRST so the 3D view is never pure black
	_setup_environment()
	EventBus.time_changed.connect(_on_time)
	EventBus.era_changed.connect(func(_e): pass)

	# Defer heavy build one frame so the tree + physics are ready
	call_deferred("_boot_world")


func _boot_world() -> void:
	if world_root == null:
		push_error("TownWorld: WorldRoot missing")
		return
	_build_town()
	_spawn_player()
	_on_time(TimeSystem.get_hour(), TimeSystem.day)
	if not GameState.tutorial_done:
		EventBus.notification.emit(
			"Welcome to Mystery Hollow. Blue building = Detective Agency. WASD move · mouse look · E interact · J journal · Esc free cursor.",
			8.0
		)
		GameState.tutorial_done = true


func _setup_environment() -> void:
	if env == null:
		return
	if env.environment == null:
		env.environment = Environment.new()
	var e: Environment = env.environment
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.45, 0.62, 0.82)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.58, 0.62)
	e.ambient_light_energy = 0.85
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if sun:
		sun.light_energy = 1.1
		sun.shadow_enabled = true
		sun.rotation_degrees = Vector3(-50, 35, 0)


func enter_location(loc: String) -> void:
	if _player == null:
		return
	GameState.current_location = loc
	match loc:
		"house":
			_player.global_position = Vector3(-28, 1.2, 4)
		"office":
			_player.global_position = Vector3(12, 1.2, -2)
		"town":
			_player.global_position = Vector3(0, 1.2, 8)
	EventBus.notification.emit("Location: %s" % loc.capitalize(), 1.5)


func _spawn_player() -> void:
	if _player != null and is_instance_valid(_player):
		_player.queue_free()
	_player = PlayerScene.instantiate() as CharacterBody3D
	add_child(_player)
	var spawn := Vector3(0, 1.5, 10)
	if GameState.current_location == "house":
		spawn = Vector3(-28, 1.5, 4)
	elif GameState.current_location == "office":
		spawn = Vector3(12, 1.5, -2)
	else:
		var p: Vector3 = GameState.player_position
		if p.y < 0.5 or p.y > 50.0:
			p.y = 1.5
		# Prefer a known-good town spawn for first load
		if p.is_equal_approx(Vector3(0, 1, 8)) or p.length() < 0.1:
			spawn = Vector3(0, 1.5, 10)
		else:
			spawn = Vector3(p.x, maxf(p.y, 1.5), p.z)
	_player.global_position = spawn
	_player.rotation.y = GameState.player_rotation_y
	# Ensure a current camera exists
	var cam := _player.get_node_or_null("CameraPivot/SpringArm3D/Camera3D") as Camera3D
	if cam:
		cam.current = true


func _build_town() -> void:
	for c in world_root.get_children():
		c.queue_free()
	# Wait a frame so queue_free settles when rebuilding
	var pal: Dictionary = EraManager.get_palette()

	# Ground — mesh + collision as separate robust bodies
	_add_ground(pal.get("grass", Color(0.25, 0.42, 0.22)))

	# Main road (cross)
	_box(Vector3(0, 0.05, 0), Vector3(8, 0.08, TOWN_SIZE * 0.7), pal.get("road", Color(0.2, 0.2, 0.22)), false)
	_box(Vector3(0, 0.05, 0), Vector3(TOWN_SIZE * 0.6, 0.08, 8), pal.get("road", Color(0.2, 0.2, 0.22)), false)

	# Downtown
	_building(Vector3(10, 0, -12), Vector3(8, 5, 6), pal.get("building_a", Color(0.5, 0.45, 0.4)), "General Store")
	_building(Vector3(20, 0, -12), Vector3(7, 4, 6), pal.get("building_b", Color(0.4, 0.42, 0.48)), "Diner")
	_building(Vector3(-10, 0, -12), Vector3(9, 6, 7), pal.get("building_a", Color(0.5, 0.45, 0.4)), "Town Hall")
	_building(Vector3(-20, 0, -10), Vector3(6, 4, 6), pal.get("building_b", Color(0.4, 0.42, 0.48)), "Clinic")

	# Detective Agency
	_building(Vector3(12, 0, 10), Vector3(8, 4.5, 7), pal.get("accent", Color(0.25, 0.45, 0.55)), "Detective Agency")
	_add_door(Vector3(12, 0.1, 14.2), "door_office", "Enter Detective Agency")

	# Player house
	_building(Vector3(-28, 0, 8), Vector3(9, 4, 8), Color(0.55, 0.48, 0.40), "Your Home")
	_add_door(Vector3(-28, 0.1, 12.5), "door_house", "Enter Home")

	# Warehouse
	_building(Vector3(28, 0, 18), Vector3(12, 5, 10), Color(0.35, 0.35, 0.38), "Warehouse")
	_add_evidence(Vector3(28, 0.5, 14), "ledger_page", "Search desk — torn ledger")

	# River + crime scene
	_box(Vector3(36, -0.05, 0), Vector3(6, 0.35, 40), Color(0.15, 0.35, 0.50), false)
	_add_label(Vector3(36, 1.5, -8), "Riverbank")
	_add_evidence(Vector3(34, 0.4, -6), "river_watch", "Broken watch in the mud")
	_add_evidence(Vector3(35, 0.4, -4), "muddy_boots_cast", "Boot print in soft earth")
	_add_evidence(Vector3(33.5, 0.4, -7.5), "threatening_note", "Torn note in the reeds")
	_add_label(Vector3(34, 2.2, -5), "CRIME SCENE")

	# Forest edge
	for i in range(12):
		var fx := -35.0 + float(i) * 3.0
		_tree(Vector3(fx, 0, 32))
		_tree(Vector3(fx + 1.5, 0, 35))

	# Park
	_box(Vector3(-5, 0.06, 15), Vector3(10, 0.1, 10), Color(0.18, 0.40, 0.18), false)
	_tree(Vector3(-5, 0, 15))

	_build_house_interior()
	_build_office_interior()

	# NPCs (never use param name "name" — conflicts with Node.name)
	_spawn_npc("deputy_cole", "Deputy Cole", Vector3(11, 0, 8), Color(0.2, 0.25, 0.45))
	_spawn_npc("mayor_hart", "Mayor Hart", Vector3(-10, 0, -8), Color(0.45, 0.35, 0.25))
	_spawn_npc("bartender_sam", "Sam", Vector3(20, 0, -8), Color(0.5, 0.3, 0.25))
	_spawn_npc("witness_ben", "Ben Carter", Vector3(18, 0, -9), Color(0.35, 0.45, 0.35))
	_spawn_npc("suspect_vera", "Vera Lang", Vector3(-12, 0, -9), Color(0.55, 0.35, 0.40))
	_spawn_npc("suspect_marcus", "Marcus Reed", Vector3(26, 0, 16), Color(0.3, 0.3, 0.32))
	_spawn_npc("suspect_owen", "Owen Pike", Vector3(2, 0, 6), Color(0.55, 0.50, 0.30))
	_spawn_npc("shopkeeper_rita", "Rita", Vector3(10, 0, -9), Color(0.6, 0.4, 0.35))
	_spawn_npc("dr_ellis", "Dr. Ellis", Vector3(-20, 0, -7), Color(0.7, 0.7, 0.75))

	# Street lamps
	for z in [-20, -5, 10, 25]:
		_lamp(Vector3(3.5, 0, float(z)))
		_lamp(Vector3(-3.5, 0, float(z)))

	# Fill light near spawn so the world is never underexposed
	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 8, 10)
	fill.light_energy = 0.6
	fill.omni_range = 40.0
	fill.light_color = Color(1.0, 0.97, 0.92)
	world_root.add_child(fill)


func _add_ground(color: Color) -> void:
	var thickness := 2.0
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(TOWN_SIZE, thickness, TOWN_SIZE)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	# Top of ground at y = 0
	mi.position = Vector3(0, -thickness * 0.5, 0)
	world_root.add_child(mi)

	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector3(0, -thickness * 0.5, 0)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(TOWN_SIZE, thickness, TOWN_SIZE)
	col.shape = shape
	body.add_child(col)
	world_root.add_child(body)


func _build_house_interior() -> void:
	var bed := _make_interactable(Vector3(-30, 0.5, 6), "bed", "Sleep (restore energy)", "bed")
	world_root.add_child(bed)
	var food := _make_interactable(Vector3(-26, 0.5, 6), "food", "Eat a meal", "food")
	world_root.add_child(food)
	var desk := _make_interactable(Vector3(-28, 0.5, 10), "case_board", "Home case board", "case_board")
	world_root.add_child(desk)
	for f in GameState.house_furniture:
		var pos := _as_vec3(f.get("pos", Vector3.ZERO))
		var world_pos := Vector3(-28, 0.4, 8) + pos
		var col := Color(0.6, 0.5, 0.4)
		match str(f.get("id", "")):
			"bed":
				col = Color(0.4, 0.35, 0.55)
			"desk":
				col = Color(0.35, 0.28, 0.2)
			"lamp":
				col = Color(0.9, 0.85, 0.5)
		_box(world_pos, Vector3(1.2, 0.8, 1.2), col, false)


func _build_office_interior() -> void:
	world_root.add_child(_make_interactable(Vector3(12, 0.5, 11), "case_accept", "Accept case: Riverside Murder", "case_accept"))
	world_root.add_child(_make_interactable(Vector3(14, 0.5, 11), "case_board", "Evidence board / Journal", "case_board"))
	world_root.add_child(_make_interactable(Vector3(10, 0.5, 11), "accuse", "Make an accusation", "accuse"))
	world_root.add_child(_make_interactable(Vector3(13, 0.5, 8), "food", "Agency coffee", "food"))


func _spawn_npc(npc_id: String, display_name: String, pos: Vector3, color: Color) -> void:
	var npc = NpcScript.new()
	npc.npc_id = npc_id
	npc.display_name = display_name
	npc.body_color = color
	npc.position = pos
	world_root.add_child(npc)


func _as_vec3(v: Variant) -> Vector3:
	if v is Vector3:
		return v
	if v is Dictionary:
		return Vector3(float(v.get("x", 0)), float(v.get("y", 0)), float(v.get("z", 0)))
	return Vector3.ZERO


func _box(pos: Vector3, size: Vector3, color: Color, with_collision: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	mi.position = pos + Vector3(0, size.y * 0.5, 0)
	world_root.add_child(mi)
	if with_collision:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = pos + Vector3(0, size.y * 0.5, 0)
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
		world_root.add_child(body)
	return mi


func _building(pos: Vector3, size: Vector3, color: Color, title: String) -> void:
	_box(pos, size, color, true)
	_add_label(pos + Vector3(0, size.y + 0.8, size.z * 0.5 + 0.2), title)


func _tree(pos: Vector3) -> void:
	_box(pos, Vector3(0.4, 2.5, 0.4), Color(0.35, 0.22, 0.12), false)
	var leaves := _box(pos + Vector3(0, 2.0, 0), Vector3(2.2, 2.2, 2.2), Color(0.15, 0.40, 0.18), false)
	leaves.position = pos + Vector3(0, 3.2, 0)


func _lamp(pos: Vector3) -> void:
	_box(pos, Vector3(0.15, 3.0, 0.15), Color(0.2, 0.2, 0.22), false)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 3.1, 0)
	light.light_energy = 0.0
	light.omni_range = 12.0
	light.light_color = Color(1.0, 0.9, 0.7)
	light.set_meta("street_lamp", true)
	world_root.add_child(light)


func _add_label(pos: Vector3, text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = 0.02
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.95, 0.9, 0.75)
	label.outline_modulate = Color(0, 0, 0, 1)
	label.outline_size = 8
	world_root.add_child(label)


func _add_door(pos: Vector3, type: String, label: String) -> void:
	world_root.add_child(_make_interactable(pos, type, label, type))


func _add_evidence(pos: Vector3, evidence_id: String, label: String) -> void:
	if CaseManager.has_evidence(evidence_id):
		return
	var e = _make_interactable(pos, evidence_id, label, "evidence")
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	mi.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.8, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.7, 0.1)
	mat.emission_energy_multiplier = 2.0
	mi.material_override = mat
	mi.position.y = 0.35
	e.add_child(mi)
	world_root.add_child(e)


func _make_interactable(pos: Vector3, id: String, label: String, type: String) -> StaticBody3D:
	var node = InteractableScript.new()
	node.position = pos
	node.interact_id = id
	node.label = label
	node.interact_type = type
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.0
	col.shape = shape
	node.add_child(col)
	if type != "evidence":
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.7, 1.4, 0.7)
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.55, 0.85, 0.75)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.4, 0.7)
		mat.emission_energy_multiplier = 0.4
		mi.material_override = mat
		mi.position.y = 0.7
		node.add_child(mi)
	return node


func _on_time(_hour: float, _day: int) -> void:
	if sun == null or env == null:
		return
	var factor := TimeSystem.get_sun_factor()
	sun.light_energy = lerpf(0.25, 1.25, factor)
	sun.rotation_degrees = Vector3(-35.0 - factor * 40.0, 35.0, 0.0)
	var pal: Dictionary = EraManager.get_palette()
	var sky_day: Color = pal.get("sky_day", Color(0.5, 0.7, 0.9))
	var sky_night: Color = pal.get("sky_night", Color(0.05, 0.06, 0.12))
	var sky_col: Color = sky_day.lerp(sky_night, 1.0 - factor)
	if env.environment == null:
		env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = sky_col
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = sky_col.lightened(0.15)
	# Keep ambient high enough that outdoor scenes never look black
	env.environment.ambient_light_energy = lerpf(0.45, 0.9, factor)
	for n in world_root.get_children():
		if n is OmniLight3D and n.has_meta("street_lamp"):
			(n as OmniLight3D).light_energy = 0.0 if factor > 0.35 else 2.5
