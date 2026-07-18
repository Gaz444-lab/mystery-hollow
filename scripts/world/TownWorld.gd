extends Node3D
## Mystery Hollow open world — grounded small-town atmosphere.
## Districts: Downtown, Residential, Outskirts (forest / docks / factory).
## Art: stylized realistic low-poly placeholders (not cartoon / not Minecraft).

const InteractableScript = preload("res://scripts/world/Interactable.gd")
const NpcScript = preload("res://scripts/world/NPC.gd")
const PlayerScene = preload("res://scenes/player/Player.tscn")

@onready var world_root: Node3D = $WorldRoot
@onready var sun: DirectionalLight3D = $Sun
@onready var env: WorldEnvironment = $WorldEnvironment

var _player: CharacterBody3D
var _weather_timer: float = 0.0


func _ready() -> void:
	add_to_group("game_root")
	_setup_environment()
	EventBus.time_changed.connect(_on_time)
	EventBus.era_changed.connect(func(_e): pass)
	call_deferred("_boot_world")


func _process(delta: float) -> void:
	if GameState.phase != GameState.GamePhase.PLAYING:
		return
	_weather_timer += delta
	if _weather_timer > 180.0:
		_weather_timer = 0.0
		_cycle_weather()


func _boot_world() -> void:
	if world_root == null:
		return
	_build_town()
	_spawn_player()
	_on_time(TimeSystem.get_hour(), TimeSystem.day)
	if not GameState.tutorial_done:
		EventBus.notification.emit(
			"Mystery Hollow. The Detective Agency is the brick building downtown. WASD · mouse look · E interact · J journal · Esc pause.",
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
	e.background_color = Color(0.42, 0.52, 0.62)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.45, 0.48, 0.52)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.05
	e.fog_enabled = true
	e.fog_light_color = Color(0.5, 0.55, 0.6)
	e.fog_density = 0.0012
	if sun:
		sun.light_energy = 1.0
		sun.shadow_enabled = true
		sun.light_color = Color(1.0, 0.96, 0.9)
		sun.rotation_degrees = Vector3(-48, 30, 0)


func enter_location(loc: String) -> void:
	if _player == null:
		return
	GameState.current_location = loc
	match loc:
		"house":
			_player.global_position = Vector3(-26, 1.2, 6)
		"office":
			_player.global_position = Vector3(12, 1.2, 2)
		_:
			_player.global_position = Vector3(0, 1.2, 12)
	EventBus.notification.emit("Entered: %s" % loc.capitalize(), 1.5)


func _spawn_player() -> void:
	if _player != null and is_instance_valid(_player):
		_player.queue_free()
	_player = PlayerScene.instantiate() as CharacterBody3D
	add_child(_player)
	var spawn := Vector3(0, 1.5, 12)
	if GameState.current_location == "house":
		spawn = Vector3(-26, 1.5, 6)
	elif GameState.current_location == "office":
		spawn = Vector3(12, 1.5, 2)
	_player.global_position = spawn
	_player.rotation.y = GameState.player_rotation_y
	var cam := _player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if cam:
		cam.current = true


func _build_town() -> void:
	for c in world_root.get_children():
		c.queue_free()
	var pal: Dictionary = EraManager.get_palette()

	# Ground plane
	_mesh_box(Vector3(0, -0.5, 0), Vector3(120, 1.0, 120), pal.get("grass", Color(0.28, 0.38, 0.22)), true)

	# Roads
	_mesh_box(Vector3(0, 0.02, 0), Vector3(7, 0.06, 90), pal.get("road", Color(0.18, 0.18, 0.2)), false)
	_mesh_box(Vector3(0, 0.02, 0), Vector3(70, 0.06, 7), pal.get("road", Color(0.18, 0.18, 0.2)), false)

	# --- DOWNTOWN ---
	_district_label(Vector3(0, 3.5, -14), "DOWNTOWN")
	_building(Vector3(10, 0, -14), Vector3(8, 5.5, 7), pal.get("building_a", Color(0.45, 0.42, 0.4)), "General Store")
	_building(Vector3(20, 0, -14), Vector3(7, 4.2, 6.5), pal.get("building_b", Color(0.4, 0.38, 0.42)), "Diner")
	_building(Vector3(-10, 0, -14), Vector3(9, 6.5, 8), Color(0.48, 0.45, 0.42), "Town Hall")
	_building(Vector3(-20, 0, -12), Vector3(6, 4, 6), Color(0.55, 0.55, 0.58), "Clinic")
	# Detective Agency — slightly warmer brick
	_building(Vector3(12, 0, 10), Vector3(8.5, 5, 7.5), Color(0.42, 0.28, 0.24), "Detective Agency")
	_add_door(Vector3(12, 0.1, 14.2), "door_office", "Enter Detective Agency")

	# --- RESIDENTIAL ---
	_district_label(Vector3(-28, 3.2, 10), "RESIDENTIAL")
	_building(Vector3(-28, 0, 10), Vector3(9, 4.2, 8), Color(0.52, 0.46, 0.4), "Your Home")
	_add_door(Vector3(-28, 0.1, 14.5), "door_house", "Enter Home")
	_building(Vector3(-38, 0, 8), Vector3(7, 3.8, 7), Color(0.5, 0.48, 0.45), "Neighbor")
	_building(Vector3(-18, 0, 16), Vector3(7, 3.8, 7), Color(0.48, 0.44, 0.4), "Neighbor")

	# --- OUTSKIRTS ---
	_district_label(Vector3(30, 3.2, 22), "OUTSKIRTS")
	_building(Vector3(28, 0, 22), Vector3(12, 5.5, 10), Color(0.32, 0.32, 0.35), "Warehouse / Factory")
	_add_evidence(Vector3(28, 0.55, 16), "ledger_page", "Search records desk")
	# Old mansion silhouette
	_building(Vector3(-35, 0, -28), Vector3(11, 7, 9), Color(0.3, 0.28, 0.32), "Old Mansion")
	# Docks / river
	_mesh_box(Vector3(40, -0.15, 0), Vector3(8, 0.4, 50), Color(0.14, 0.28, 0.42), false)
	_mesh_box(Vector3(36, 0.15, -8), Vector3(4, 0.3, 12), Color(0.35, 0.28, 0.2), false)
	_district_label(Vector3(38, 2.5, -6), "DOCKS / RIVER")
	_add_evidence(Vector3(34, 0.45, -5), "river_watch", "Broken watch")
	_add_evidence(Vector3(35, 0.45, -3), "muddy_boots_cast", "Boot print in mud")
	_add_evidence(Vector3(33.5, 0.45, -6.5), "threatening_note", "Torn note")
	_district_label(Vector3(34, 2.8, -4), "CRIME SCENE")

	# Forest (outskirts)
	for i in range(16):
		var fx := -40.0 + float(i) * 4.0
		_tree(Vector3(fx, 0, 32))
		_tree(Vector3(fx + 2.0, 0, 36))

	# Park
	_mesh_box(Vector3(-4, 0.04, 18), Vector3(12, 0.08, 10), Color(0.22, 0.4, 0.2), false)
	_tree(Vector3(-4, 0, 18))

	_build_house_interior()
	_build_office_interior()

	# NPCs with schedules positions (static for now — expanded later)
	_spawn_npc("deputy_cole", "Deputy Cole", Vector3(11, 0, 8), Color(0.2, 0.24, 0.38))
	_spawn_npc("mayor_hart", "Mayor Hart", Vector3(-10, 0, -10), Color(0.38, 0.28, 0.22))
	_spawn_npc("bartender_sam", "Sam", Vector3(20, 0, -10), Color(0.4, 0.28, 0.22))
	_spawn_npc("witness_ben", "Ben Carter", Vector3(18, 0, -11), Color(0.32, 0.4, 0.32))
	_spawn_npc("suspect_vera", "Vera Lang", Vector3(-12, 0, -11), Color(0.42, 0.28, 0.32))
	_spawn_npc("suspect_marcus", "Marcus Reed", Vector3(26, 0, 18), Color(0.28, 0.28, 0.3))
	_spawn_npc("suspect_owen", "Owen Pike", Vector3(2, 0, 8), Color(0.42, 0.38, 0.28))
	_spawn_npc("shopkeeper_rita", "Rita", Vector3(10, 0, -11), Color(0.45, 0.32, 0.28))
	_spawn_npc("dr_ellis", "Dr. Ellis", Vector3(-20, 0, -9), Color(0.55, 0.55, 0.58))

	# Street lamps
	for z in [-22, -6, 10, 24]:
		_lamp(Vector3(3.8, 0, float(z)))
		_lamp(Vector3(-3.8, 0, float(z)))

	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 12, 8)
	fill.light_energy = 0.35
	fill.omni_range = 55.0
	fill.light_color = Color(0.95, 0.92, 0.88)
	world_root.add_child(fill)


func _build_house_interior() -> void:
	world_root.add_child(_make_interactable(Vector3(-30, 0.5, 7), "bed", "Sleep", "bed"))
	world_root.add_child(_make_interactable(Vector3(-26, 0.5, 7), "food", "Eat", "food"))
	world_root.add_child(_make_interactable(Vector3(-24, 0.5, 7), "drink", "Drink", "drink"))
	world_root.add_child(_make_interactable(Vector3(-28, 0.5, 11), "wash", "Wash up", "wash"))
	world_root.add_child(_make_interactable(Vector3(-28, 0.5, 9), "case_board", "Home case board", "case_board"))
	# Furniture silhouettes
	_mesh_box(Vector3(-30, 0.35, 7), Vector3(1.6, 0.5, 2.0), Color(0.35, 0.28, 0.4), false)
	_mesh_box(Vector3(-26, 0.4, 7), Vector3(0.9, 0.7, 0.9), Color(0.4, 0.32, 0.25), false)


func _build_office_interior() -> void:
	world_root.add_child(_make_interactable(Vector3(12, 0.5, 11), "case_accept", "Accept: Riverside Murder", "case_accept"))
	world_root.add_child(_make_interactable(Vector3(14, 0.5, 11), "case_board", "Evidence board", "case_board"))
	world_root.add_child(_make_interactable(Vector3(10, 0.5, 11), "accuse", "Make accusation", "accuse"))
	world_root.add_child(_make_interactable(Vector3(13, 0.5, 8), "food", "Agency coffee", "food"))
	world_root.add_child(_make_interactable(Vector3(11, 0.5, 8), "drink", "Water cooler", "drink"))
	_mesh_box(Vector3(12, 0.55, 11), Vector3(1.2, 0.9, 0.7), Color(0.3, 0.22, 0.18), false)


func _spawn_npc(npc_id: String, display_name: String, pos: Vector3, color: Color) -> void:
	var npc = NpcScript.new()
	npc.npc_id = npc_id
	npc.display_name = display_name
	npc.body_color = color
	npc.position = pos
	world_root.add_child(npc)


func _mesh_box(pos: Vector3, size: Vector3, color: Color, with_collision: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mi.material_override = mat
	mi.position = pos
	world_root.add_child(mi)
	if with_collision:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.position = pos
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
		world_root.add_child(body)
	return mi


func _building(pos: Vector3, size: Vector3, color: Color, title: String) -> void:
	_mesh_box(pos + Vector3(0, size.y * 0.5, 0), size, color, true)
	# Roof
	_mesh_box(pos + Vector3(0, size.y + 0.2, 0), Vector3(size.x + 0.4, 0.35, size.z + 0.4), color.darkened(0.2), false)
	# Door recess
	_mesh_box(pos + Vector3(0, 1.1, size.z * 0.5 + 0.05), Vector3(1.1, 2.1, 0.12), Color(0.12, 0.1, 0.09), false)
	# Windows
	_mesh_box(pos + Vector3(-size.x * 0.22, size.y * 0.55, size.z * 0.5 + 0.04), Vector3(1.1, 1.1, 0.08), Color(0.55, 0.65, 0.75), false)
	_mesh_box(pos + Vector3(size.x * 0.22, size.y * 0.55, size.z * 0.5 + 0.04), Vector3(1.1, 1.1, 0.08), Color(0.55, 0.65, 0.75), false)
	_district_label(pos + Vector3(0, size.y + 1.0, size.z * 0.45), title)


func _tree(pos: Vector3) -> void:
	_mesh_box(pos + Vector3(0, 1.2, 0), Vector3(0.35, 2.4, 0.35), Color(0.32, 0.22, 0.14), false)
	var leaves := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 1.3
	s.height = 2.4
	leaves.mesh = s
	leaves.position = pos + Vector3(0, 3.0, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.38, 0.18)
	mat.roughness = 1.0
	leaves.material_override = mat
	world_root.add_child(leaves)


func _lamp(pos: Vector3) -> void:
	_mesh_box(pos + Vector3(0, 1.5, 0), Vector3(0.12, 3.0, 0.12), Color(0.2, 0.2, 0.22), false)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 3.2, 0)
	light.light_energy = 0.0
	light.omni_range = 11.0
	light.light_color = Color(1.0, 0.88, 0.65)
	light.set_meta("street_lamp", true)
	world_root.add_child(light)


func _district_label(pos: Vector3, text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 40
	label.pixel_size = 0.018
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.9, 0.88, 0.82)
	label.outline_modulate = Color(0, 0, 0, 0.9)
	label.outline_size = 10
	world_root.add_child(label)


func _add_door(pos: Vector3, type: String, label: String) -> void:
	world_root.add_child(_make_interactable(pos, type, label, type))


func _add_evidence(pos: Vector3, evidence_id: String, label: String) -> void:
	if CaseManager.has_evidence(evidence_id):
		return
	var e = _make_interactable(pos, evidence_id, label, "evidence")
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.25, 0.15, 0.35)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.65, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.5, 0.2)
	mat.emission_energy_multiplier = 0.6
	mi.material_override = mat
	mi.position.y = 0.2
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
		box.size = Vector3(0.55, 1.1, 0.55)
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.45, 0.55, 0.55)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = mat
		mi.position.y = 0.55
		node.add_child(mi)
	return node


func _cycle_weather() -> void:
	var options := ["clear", "overcast", "fog", "rain"]
	var next: String = options[randi() % options.size()]
	GameState.weather = next
	EventBus.weather_changed.emit(next)
	EventBus.notification.emit("Weather: %s" % next.capitalize(), 2.5)
	_apply_weather()


func _apply_weather() -> void:
	if env == null or env.environment == null:
		return
	match GameState.weather:
		"fog":
			env.environment.fog_density = 0.008
		"rain", "overcast":
			env.environment.fog_density = 0.003
			if sun:
				sun.light_energy = minf(sun.light_energy, 0.55)
		_:
			env.environment.fog_density = 0.0012


func _on_time(_hour: float, _day: int) -> void:
	if sun == null or env == null:
		return
	var factor := TimeSystem.get_sun_factor()
	var pal: Dictionary = EraManager.get_palette()
	var day_sky: Color = pal.get("sky_day", Color(0.5, 0.62, 0.75))
	var night_sky: Color = pal.get("sky_night", Color(0.05, 0.06, 0.1))
	# Dusk bias for atmosphere
	var sky: Color = day_sky.lerp(night_sky, 1.0 - factor)
	if env.environment == null:
		env.environment = Environment.new()
	sun.light_energy = lerpf(0.2, 1.05, factor)
	if GameState.weather == "overcast" or GameState.weather == "rain":
		sun.light_energy *= 0.55
	sun.rotation_degrees = Vector3(-32.0 - factor * 42.0, 30.0, 0.0)
	env.environment.background_color = sky
	env.environment.ambient_light_color = sky.lightened(0.08)
	env.environment.ambient_light_energy = lerpf(0.35, 0.65, factor)
	env.environment.fog_light_color = sky
	_apply_weather()
	for n in world_root.get_children():
		if n is OmniLight3D and n.has_meta("street_lamp"):
			(n as OmniLight3D).light_energy = 0.0 if factor > 0.35 else 2.4
