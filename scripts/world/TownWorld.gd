extends Node3D
## Builds Mystery Hollow from primitives — modular, era-tinted open world.

const TOWN_SIZE := 80.0

@onready var world_root: Node3D = $WorldRoot
@onready var sun: DirectionalLight3D = $Sun
@onready var env: WorldEnvironment = $WorldEnvironment

var _player_scene := preload("res://scenes/player/Player.tscn")
var _player: CharacterBody3D


func _ready() -> void:
	add_to_group("game_root")
	EventBus.time_changed.connect(_on_time)
	EventBus.era_changed.connect(func(_e): _rebuild_if_needed())
	_build_town()
	_spawn_player()
	_on_time(TimeSystem.get_hour(), TimeSystem.day)
	if not GameState.tutorial_done:
		EventBus.notification.emit(
			"Welcome to Mystery Hollow. Visit the Detective Agency (blue building) for your first case. WASD move, mouse look, E interact, J journal, Esc free cursor.",
			8.0
		)
		GameState.tutorial_done = true


func _rebuild_if_needed() -> void:
	pass  # palette applied live via _on_time / materials already era-based on build


func enter_location(loc: String) -> void:
	GameState.current_location = loc
	match loc:
		"house":
			_player.global_position = Vector3(-28, 1, 4)
		"office":
			_player.global_position = Vector3(12, 1, -2)
		"town":
			_player.global_position = Vector3(0, 1, 8)
	EventBus.notification.emit("Location: %s" % loc.capitalize(), 1.5)


func _spawn_player() -> void:
	_player = _player_scene.instantiate()
	add_child(_player)
	if GameState.current_location == "house":
		_player.global_position = Vector3(-28, 1, 4)
	elif GameState.current_location == "office":
		_player.global_position = Vector3(12, 1, -2)
	else:
		_player.global_position = GameState.player_position


func _build_town() -> void:
	for c in world_root.get_children():
		c.queue_free()
	var pal: Dictionary = EraManager.get_palette()

	# Ground
	_box(Vector3(0, -0.25, 0), Vector3(TOWN_SIZE, 0.5, TOWN_SIZE), pal["grass"], world_root)

	# Main road (cross)
	_box(Vector3(0, 0.02, 0), Vector3(8, 0.05, TOWN_SIZE * 0.7), pal["road"], world_root)
	_box(Vector3(0, 0.02, 0), Vector3(TOWN_SIZE * 0.6, 0.05, 8), pal["road"], world_root)

	# Downtown row
	_building(Vector3(10, 0, -12), Vector3(8, 5, 6), pal["building_a"], "General Store", world_root)
	_building(Vector3(20, 0, -12), Vector3(7, 4, 6), pal["building_b"], "Diner", world_root)
	_building(Vector3(-10, 0, -12), Vector3(9, 6, 7), pal["building_a"], "Town Hall", world_root)
	_building(Vector3(-20, 0, -10), Vector3(6, 4, 6), pal["building_b"], "Clinic", world_root)

	# Detective Agency (accent)
	var office := _building(Vector3(12, 0, 10), Vector3(8, 4.5, 7), pal["accent"], "Detective Agency", world_root)
	_add_door(office.global_position + Vector3(0, 0, 3.6), "door_office", "Enter Detective Agency")

	# Player house
	var house := _building(Vector3(-28, 0, 8), Vector3(9, 4, 8), Color(0.55, 0.48, 0.40), "Your Home", world_root)
	_add_door(house.global_position + Vector3(0, 0, 4.1), "door_house", "Enter Home")

	# Warehouse (case)
	_building(Vector3(28, 0, 18), Vector3(12, 5, 10), Color(0.35, 0.35, 0.38), "Warehouse", world_root)
	_add_evidence(Vector3(28, 0.5, 14), "ledger_page", "Search desk — torn ledger")

	# River + crime scene (east)
	_box(Vector3(36, -0.1, 0), Vector3(6, 0.3, 40), Color(0.15, 0.35, 0.50), world_root)
	_add_label(Vector3(36, 1.5, -8), "Riverbank")
	_add_evidence(Vector3(34, 0.4, -6), "river_watch", "Broken watch in the mud")
	_add_evidence(Vector3(35, 0.4, -4), "muddy_boots_cast", "Boot print in soft earth")
	_add_evidence(Vector3(33.5, 0.4, -7.5), "threatening_note", "Torn note in the reeds")
	_add_label(Vector3(34, 2.2, -5), "CRIME SCENE")

	# Forest edge
	for i in range(12):
		var fx := -35.0 + i * 3.0
		_tree(Vector3(fx, 0, 32), world_root)
		_tree(Vector3(fx + 1.5, 0, 35), world_root)

	# Park center
	_box(Vector3(-5, 0.05, 15), Vector3(10, 0.1, 10), Color(0.18, 0.40, 0.18), world_root)
	_tree(Vector3(-5, 0, 15), world_root)

	# Interior markers (house furniture zone)
	_build_house_interior()
	_build_office_interior()

	# NPCs
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
		_lamp(Vector3(3.5, 0, z), world_root)
		_lamp(Vector3(-3.5, 0, z), world_root)


func _build_house_interior() -> void:
	# Floor pad inside house footprint for sleep/eat/build
	var bed := _make_interactable(Vector3(-30, 0.5, 6), "bed", "Sleep (restore energy)", "bed")
	world_root.add_child(bed)
	var food := _make_interactable(Vector3(-26, 0.5, 6), "food", "Eat a meal", "food")
	world_root.add_child(food)
	var desk := _make_interactable(Vector3(-28, 0.5, 10), "case_board", "Home case board", "case_board")
	world_root.add_child(desk)
	# Furniture visuals from GameState
	for f in GameState.house_furniture:
		var pos: Vector3 = f.get("pos", Vector3.ZERO)
		# offset into house
		var world_pos := Vector3(-28, 0.4, 8) + pos
		var col := Color(0.6, 0.5, 0.4)
		match str(f.get("id", "")):
			"bed": col = Color(0.4, 0.35, 0.55)
			"desk": col = Color(0.35, 0.28, 0.2)
			"lamp": col = Color(0.9, 0.85, 0.5)
		_box(world_pos, Vector3(1.2, 0.8, 1.2), col, world_root)


func _build_office_interior() -> void:
	var accept := _make_interactable(Vector3(12, 0.5, 11), "case_accept", "Accept case: Riverside Murder", "case_accept")
	world_root.add_child(accept)
	var board := _make_interactable(Vector3(14, 0.5, 11), "case_board", "Evidence board / Journal", "case_board")
	world_root.add_child(board)
	var accuse := _make_interactable(Vector3(10, 0.5, 11), "accuse", "Make an accusation", "accuse")
	world_root.add_child(accuse)
	var coffee := _make_interactable(Vector3(13, 0.5, 8), "food", "Agency coffee", "food")
	world_root.add_child(coffee)


func _spawn_npc(id: String, name: String, pos: Vector3, color: Color) -> void:
	var npc := TownNPC.new()
	npc.npc_id = id
	npc.display_name = name
	npc.body_color = color
	npc.position = pos
	world_root.add_child(npc)


func _box(pos: Vector3, size: Vector3, color: Color, parent: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	mi.position = pos + Vector3(0, size.y * 0.5, 0)
	parent.add_child(mi)
	# Static collision for large platforms only
	if size.x > 5.0 or size.z > 5.0:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
		mi.add_child(body)
	return mi


func _building(pos: Vector3, size: Vector3, color: Color, title: String, parent: Node) -> MeshInstance3D:
	var b := _box(pos, size, color, parent)
	_add_label(pos + Vector3(0, size.y + 0.8, size.z * 0.5 + 0.2), title)
	# Simple collision building
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.position = pos + Vector3(0, size.y * 0.5, 0)
	body.add_child(col)
	parent.add_child(body)
	return b


func _tree(pos: Vector3, parent: Node) -> void:
	_box(pos, Vector3(0.4, 2.5, 0.4), Color(0.35, 0.22, 0.12), parent)
	var leaves := _box(pos + Vector3(0, 2.2, 0), Vector3(2.2, 2.2, 2.2), Color(0.15, 0.40, 0.18), parent)
	leaves.position = pos + Vector3(0, 3.2, 0)


func _lamp(pos: Vector3, parent: Node) -> void:
	_box(pos, Vector3(0.15, 3.0, 0.15), Color(0.2, 0.2, 0.22), parent)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 3.1, 0)
	light.light_energy = 0.0
	light.omni_range = 10.0
	light.light_color = Color(1.0, 0.9, 0.7)
	light.set_meta("street_lamp", true)
	parent.add_child(light)


func _add_label(pos: Vector3, text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 32
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.95, 0.9, 0.75)
	world_root.add_child(label)


func _add_door(pos: Vector3, type: String, label: String) -> void:
	var door := _make_interactable(pos, type, label, type)
	world_root.add_child(door)


func _add_evidence(pos: Vector3, evidence_id: String, label: String) -> void:
	if CaseManager.has_evidence(evidence_id):
		return
	var e := _make_interactable(pos, evidence_id, label, "evidence")
	# Visual marker
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	mi.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.75, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.6, 0.1)
	mat.emission_energy_multiplier = 1.5
	mi.material_override = mat
	mi.position.y = 0.3
	e.add_child(mi)
	world_root.add_child(e)


func _make_interactable(pos: Vector3, id: String, label: String, type: String) -> Interactable:
	var node := Interactable.new()
	node.position = pos
	node.interact_id = id
	node.label = label
	node.interact_type = type
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.8
	col.shape = shape
	node.add_child(col)
	# Visible pillar for doors / actions
	if type != "evidence":
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.6, 1.2, 0.6)
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.5, 0.7)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.55
		mi.material_override = mat
		mi.position.y = 0.6
		node.add_child(mi)
	return node


func _on_time(hour: float, _day: int) -> void:
	var factor := TimeSystem.get_sun_factor()
	sun.light_energy = lerpf(0.15, 1.2, factor)
	sun.rotation_degrees = Vector3(-30 - factor * 40, 35, 0)
	var pal: Dictionary = EraManager.get_palette()
	var sky_col: Color = pal["sky_day"].lerp(pal["sky_night"], 1.0 - factor)
	if env.environment == null:
		env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = sky_col
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = sky_col.lightened(0.1)
	env.environment.ambient_light_energy = lerpf(0.2, 0.6, factor)
	# Street lamps at night
	for n in world_root.get_children():
		if n is OmniLight3D and n.has_meta("street_lamp"):
			n.light_energy = 0.0 if factor > 0.35 else 2.2
