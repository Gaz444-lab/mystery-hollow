extends Node3D
## Mystery Hollow as a Minecraft-style blocky open world.

const TOWN_SIZE := 64.0
const PlayerScene = preload("res://scenes/player/Player.tscn")
const InteractableScript = preload("res://scripts/world/Interactable.gd")
const NpcScript = preload("res://scripts/world/NPC.gd")
const VoxelStyle = preload("res://scripts/world/VoxelStyle.gd")

@onready var world_root: Node3D = $WorldRoot
@onready var sun: DirectionalLight3D = $Sun
@onready var env: WorldEnvironment = $WorldEnvironment

var _player: CharacterBody3D


func _ready() -> void:
	add_to_group("game_root")
	_setup_environment()
	EventBus.time_changed.connect(_on_time)
	EventBus.era_changed.connect(func(_e): pass)
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
			"Welcome to blocky Mystery Hollow! Blue wool building = Detective Agency. WASD · mouse · E interact · J journal.",
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
	e.background_color = VoxelStyle.SKY
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.78, 0.82)
	e.ambient_light_energy = 0.95
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	e.fog_enabled = true
	e.fog_light_color = VoxelStyle.SKY
	e.fog_density = 0.0015
	if sun:
		sun.light_energy = 1.15
		sun.shadow_enabled = true
		sun.light_color = Color(1.0, 0.98, 0.9)
		sun.rotation_degrees = Vector3(-55, 40, 0)


func enter_location(loc: String) -> void:
	if _player == null:
		return
	GameState.current_location = loc
	match loc:
		"house":
			_player.global_position = Vector3(-24, 1.2, 6)
		"office":
			_player.global_position = Vector3(10, 1.2, 0)
		"town":
			_player.global_position = Vector3(0, 1.2, 8)
	EventBus.notification.emit("Chunk: %s" % loc.capitalize(), 1.5)


func _spawn_player() -> void:
	if _player != null and is_instance_valid(_player):
		_player.queue_free()
	_player = PlayerScene.instantiate() as CharacterBody3D
	add_child(_player)
	var spawn := Vector3(0, 1.5, 10)
	if GameState.current_location == "house":
		spawn = Vector3(-24, 1.5, 6)
	elif GameState.current_location == "office":
		spawn = Vector3(10, 1.5, 0)
	else:
		var p: Vector3 = GameState.player_position
		if p.y < 0.5 or p.y > 50.0 or p.is_equal_approx(Vector3(0, 1, 8)) or p.length() < 0.1:
			spawn = Vector3(0, 1.5, 10)
		else:
			spawn = Vector3(p.x, maxf(p.y, 1.5), p.z)
	_player.global_position = spawn
	_player.rotation.y = GameState.player_rotation_y
	var cam := _player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if cam:
		cam.current = true


func _build_town() -> void:
	for c in world_root.get_children():
		c.queue_free()

	_add_layered_ground()
	_add_path_cross()
	_voxel_building(Vector3(8, 0, -10), Vector3i(7, 5, 6), VoxelStyle.PLANKS, VoxelStyle.OAK, "General Store")
	_voxel_building(Vector3(18, 0, -10), Vector3i(6, 4, 6), VoxelStyle.BRICK, VoxelStyle.STONE, "Diner")
	_voxel_building(Vector3(-10, 0, -10), Vector3i(8, 6, 7), VoxelStyle.STONE, VoxelStyle.COBBLE, "Town Hall")
	_voxel_building(Vector3(-20, 0, -8), Vector3i(5, 4, 5), VoxelStyle.WOOL_GREEN, VoxelStyle.STONE, "Clinic")
	# Detective Agency — blue wool (easy to spot)
	_voxel_building(Vector3(10, 0, 8), Vector3i(7, 5, 6), VoxelStyle.WOOL_BLUE, VoxelStyle.IRON, "Detective Agency")
	_add_door(Vector3(10, 0.1, 11.5), "door_office", "Enter Detective Agency")
	# Your house
	_voxel_building(Vector3(-24, 0, 8), Vector3i(8, 4, 7), VoxelStyle.PLANKS, VoxelStyle.OAK, "Your Home")
	_add_door(Vector3(-24, 0.1, 12.0), "door_house", "Enter Home")
	# Warehouse
	_voxel_building(Vector3(24, 0, 16), Vector3i(10, 5, 8), VoxelStyle.STONE, VoxelStyle.COBBLE, "Warehouse")
	_add_evidence(Vector3(24, 0.6, 12), "ledger_page", "Search chest — torn ledger")

	# River (water cubes) + crime scene
	for z in range(-12, 12, 2):
		_block(Vector3(32, -0.2, float(z)), Vector3(4, 0.6, 2), VoxelStyle.WATER, true)
		_block(Vector3(34, 0.0, float(z)), Vector3(2, 0.4, 2), VoxelStyle.SAND, false)
	_add_label(Vector3(32, 2.0, -6), "River")
	_add_evidence(Vector3(30, 0.5, -4), "river_watch", "Broken watch in the mud")
	_add_evidence(Vector3(31, 0.5, -2), "muddy_boots_cast", "Boot print")
	_add_evidence(Vector3(29.5, 0.5, -5), "threatening_note", "Torn note")
	_add_label(Vector3(30, 2.5, -3), "CRIME SCENE")
	# Gold block marker
	_block(Vector3(30, 0.5, -3.5), Vector3(0.6, 0.6, 0.6), VoxelStyle.GOLD, false)

	# Forest (Minecraft oak-style)
	for i in range(14):
		var fx := -28.0 + float(i) * 3.5
		_mc_tree(Vector3(fx, 0, 28))
		_mc_tree(Vector3(fx + 1.5, 0, 32))

	# Park
	_block(Vector3(-4, 0.05, 14), Vector3(10, 0.15, 10), VoxelStyle.GRASS_TOP, false)
	_mc_tree(Vector3(-4, 0, 14))

	_build_house_interior()
	_build_office_interior()

	# Blocky townsfolk
	_spawn_npc("deputy_cole", "Deputy Cole", Vector3(9, 0, 6), VoxelStyle.WOOL_BLUE)
	_spawn_npc("mayor_hart", "Mayor Hart", Vector3(-10, 0, -6), Color(0.55, 0.25, 0.2))
	_spawn_npc("bartender_sam", "Sam", Vector3(18, 0, -6), Color(0.6, 0.35, 0.2))
	_spawn_npc("witness_ben", "Ben Carter", Vector3(16, 0, -7), Color(0.3, 0.5, 0.35))
	_spawn_npc("suspect_vera", "Vera Lang", Vector3(-12, 0, -7), Color(0.7, 0.3, 0.45))
	_spawn_npc("suspect_marcus", "Marcus Reed", Vector3(22, 0, 14), Color(0.35, 0.35, 0.4))
	_spawn_npc("suspect_owen", "Owen Pike", Vector3(2, 0, 6), Color(0.75, 0.65, 0.25))
	_spawn_npc("shopkeeper_rita", "Rita", Vector3(8, 0, -7), Color(0.65, 0.4, 0.35))
	_spawn_npc("dr_ellis", "Dr. Ellis", Vector3(-20, 0, -5), Color(0.85, 0.85, 0.9))

	# Torch-style lamps (glowing blocks)
	for z in [-16, -4, 8, 20]:
		_torch_post(Vector3(3.0, 0, float(z)))
		_torch_post(Vector3(-3.0, 0, float(z)))

	# Floating clouds
	for i in range(6):
		var cx := -20.0 + float(i) * 10.0
		_block(Vector3(cx, 18, -5.0 + float(i % 3) * 8.0), Vector3(6, 1.2, 3), VoxelStyle.CLOUD, false)

	# Fill light
	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 10, 10)
	fill.light_energy = 0.45
	fill.omni_range = 50.0
	fill.light_color = Color(1.0, 0.98, 0.92)
	world_root.add_child(fill)


func _add_layered_ground() -> void:
	# Dirt base + grass top slab (Minecraft dirt/grass)
	_block(Vector3(0, -1.0, 0), Vector3(TOWN_SIZE, 1.6, TOWN_SIZE), VoxelStyle.DIRT, true)
	_block(Vector3(0, 0.05, 0), Vector3(TOWN_SIZE, 0.2, TOWN_SIZE), VoxelStyle.GRASS_TOP, false)
	# Border stone
	_block(Vector3(0, 0.15, TOWN_SIZE * 0.5 - 0.5), Vector3(TOWN_SIZE, 0.5, 1.0), VoxelStyle.COBBLE, false)
	_block(Vector3(0, 0.15, -TOWN_SIZE * 0.5 + 0.5), Vector3(TOWN_SIZE, 0.5, 1.0), VoxelStyle.COBBLE, false)


func _add_path_cross() -> void:
	_block(Vector3(0, 0.12, 0), Vector3(6, 0.12, TOWN_SIZE * 0.65), VoxelStyle.COBBLE, false)
	_block(Vector3(0, 0.12, 0), Vector3(TOWN_SIZE * 0.55, 0.12, 6), VoxelStyle.COBBLE, false)


func _voxel_building(pos: Vector3, size: Vector3i, wall: Color, trim: Color, title: String) -> void:
	var w := float(size.x)
	var h := float(size.y)
	var d := float(size.z)
	# Walls as solid block (hollow would need many boxes — solid is fine for vibe)
	_block(pos + Vector3(0, h * 0.5, 0), Vector3(w, h, d), wall, true)
	# Roof slab
	_block(pos + Vector3(0, h + 0.25, 0), Vector3(w + 0.8, 0.5, d + 0.8), trim, false)
	# Door hole marker (darker recess)
	_block(pos + Vector3(0, 1.0, d * 0.5 + 0.05), Vector3(1.2, 2.0, 0.15), Color(0.12, 0.1, 0.08), false)
	# Window glass blocks
	_block(pos + Vector3(-w * 0.25, h * 0.55, d * 0.5 + 0.05), Vector3(1.0, 1.0, 0.12), VoxelStyle.GLASS, true)
	_block(pos + Vector3(w * 0.25, h * 0.55, d * 0.5 + 0.05), Vector3(1.0, 1.0, 0.12), VoxelStyle.GLASS, true)
	_add_label(pos + Vector3(0, h + 1.2, d * 0.5), title)


func _mc_tree(pos: Vector3) -> void:
	# Trunk
	_block(pos + Vector3(0, 1.5, 0), Vector3(0.7, 3.0, 0.7), VoxelStyle.OAK, false)
	# Leaf cubes (cross)
	_block(pos + Vector3(0, 3.6, 0), Vector3(3.2, 2.2, 3.2), VoxelStyle.LEAVES, false)
	_block(pos + Vector3(0, 4.8, 0), Vector3(2.0, 1.4, 2.0), VoxelStyle.LEAVES, false)


func _torch_post(pos: Vector3) -> void:
	_block(pos + Vector3(0, 1.0, 0), Vector3(0.25, 2.0, 0.25), VoxelStyle.OAK, false)
	_block(pos + Vector3(0, 2.2, 0), Vector3(0.45, 0.45, 0.45), Color(1.0, 0.85, 0.3), false)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 2.4, 0)
	light.light_energy = 0.0
	light.omni_range = 12.0
	light.light_color = Color(1.0, 0.85, 0.5)
	light.set_meta("street_lamp", true)
	world_root.add_child(light)


func _build_house_interior() -> void:
	world_root.add_child(_make_interactable(Vector3(-26, 0.5, 6), "bed", "Sleep (respawn energy)", "bed"))
	world_root.add_child(_make_interactable(Vector3(-22, 0.5, 6), "food", "Eat steak", "food"))
	world_root.add_child(_make_interactable(Vector3(-24, 0.5, 10), "case_board", "Case map / Journal", "case_board"))
	# Bed & crafting-table-ish blocks
	_block(Vector3(-26, 0.4, 6), Vector3(1.4, 0.5, 2.0), VoxelStyle.WOOL_RED, false)
	_block(Vector3(-22, 0.4, 6), Vector3(1.0, 0.9, 1.0), VoxelStyle.PLANKS, false)


func _build_office_interior() -> void:
	world_root.add_child(_make_interactable(Vector3(10, 0.5, 9), "case_accept", "Accept case: Riverside Murder", "case_accept"))
	world_root.add_child(_make_interactable(Vector3(12, 0.5, 9), "case_board", "Evidence board", "case_board"))
	world_root.add_child(_make_interactable(Vector3(8, 0.5, 9), "accuse", "Make an accusation", "accuse"))
	world_root.add_child(_make_interactable(Vector3(11, 0.5, 6), "food", "Coffee", "food"))
	_block(Vector3(10, 0.5, 9), Vector3(1.0, 1.0, 1.0), VoxelStyle.GOLD, false)


func _spawn_npc(npc_id: String, display_name: String, pos: Vector3, shirt: Color) -> void:
	var npc = NpcScript.new()
	npc.npc_id = npc_id
	npc.display_name = display_name
	npc.body_color = shirt
	npc.position = pos
	world_root.add_child(npc)


func _block(pos: Vector3, size: Vector3, color: Color, with_collision: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := VoxelStyle.block_material(color)
	if color.a < 0.99:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = color.a
	mi.material_override = mat
	mi.position = pos
	world_root.add_child(mi)
	if with_collision:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = pos
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
		world_root.add_child(body)
	return mi


func _add_label(pos: Vector3, text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = 0.02
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1, 1, 1)
	label.outline_modulate = Color(0, 0, 0, 1)
	label.outline_size = 12
	world_root.add_child(label)


func _add_door(pos: Vector3, type: String, label: String) -> void:
	world_root.add_child(_make_interactable(pos, type, label, type))


func _add_evidence(pos: Vector3, evidence_id: String, label: String) -> void:
	if CaseManager.has_evidence(evidence_id):
		return
	var e = _make_interactable(pos, evidence_id, label, "evidence")
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.45, 0.45, 0.45)
	mi.mesh = box
	var mat := VoxelStyle.block_material(VoxelStyle.GOLD)
	mat.emission_enabled = true
	mat.emission = VoxelStyle.GOLD
	mat.emission_energy_multiplier = 1.2
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
		box.size = Vector3(0.7, 1.2, 0.7)
		mi.mesh = box
		var mat := VoxelStyle.block_material(Color(0.3, 0.7, 1.0, 0.8))
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.5, 0.9)
		mat.emission_energy_multiplier = 0.5
		mi.material_override = mat
		mi.position.y = 0.6
		node.add_child(mi)
	return node


func _on_time(_hour: float, _day: int) -> void:
	if sun == null or env == null:
		return
	var factor := TimeSystem.get_sun_factor()
	sun.light_energy = lerpf(0.25, 1.2, factor)
	sun.rotation_degrees = Vector3(-35.0 - factor * 40.0, 40.0, 0.0)
	var day_sky := VoxelStyle.SKY
	var night_sky := Color(0.05, 0.06, 0.12)
	var sky: Color = day_sky.lerp(night_sky, 1.0 - factor)
	if env.environment == null:
		env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = sky
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = sky.lightened(0.1)
	env.environment.ambient_light_energy = lerpf(0.5, 1.0, factor)
	env.environment.fog_light_color = sky
	for n in world_root.get_children():
		if n is OmniLight3D and n.has_meta("street_lamp"):
			(n as OmniLight3D).light_energy = 0.0 if factor > 0.35 else 2.8
