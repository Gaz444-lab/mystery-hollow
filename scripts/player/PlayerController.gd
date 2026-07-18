extends CharacterBody3D
## Third-person detective controller.

const WALK_SPEED := 4.5
const SPRINT_SPEED := 7.5
const MOUSE_SENS := 0.003

@onready var pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var mesh: MeshInstance3D = $Body
@onready var interact_ray: RayCast3D = $CameraPivot/Camera3D/InteractRay

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _look_enabled: bool = true
var _nearby: Node = null


func _ready() -> void:
	# Make sure we are the active camera
	if camera:
		camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_apply_character_look()
	# Don't override spawn set by TownWorld — only restore rotation
	rotation.y = GameState.player_rotation_y
	# Soft floor snap if we spawned slightly above ground
	call_deferred("_snap_to_ground")


func _snap_to_ground() -> void:
	if not is_inside_tree():
		return
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3(0, 2, 0)
	var to := global_position + Vector3(0, -20, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1
	var hit := space.intersect_ray(q)
	if hit:
		global_position.y = hit.position.y + 0.05


func _apply_character_look() -> void:
	# Hide default capsule body — we build a Minecraft-style humanoid
	if mesh:
		mesh.visible = false
	if has_node("Head"):
		get_node("Head").queue_free()
	var VoxelStyle = load("res://scripts/world/VoxelStyle.gd")
	var tones := [
		Color(0.96, 0.82, 0.68), Color(0.90, 0.75, 0.58), Color(0.80, 0.62, 0.45),
		Color(0.65, 0.45, 0.30), Color(0.45, 0.30, 0.20), Color(0.30, 0.20, 0.14),
	]
	var idx: int = clampi(int(GameState.character.get("skin_tone", 2)), 0, tones.size() - 1)
	var skin: Color = tones[idx]
	var shirt: Color = _char_color()
	var pants := Color(0.2, 0.25, 0.45)
	var hair_colors := [
		Color(0.15, 0.1, 0.08), Color(0.35, 0.2, 0.1), Color(0.55, 0.35, 0.15),
		Color(0.7, 0.55, 0.2), Color(0.4, 0.4, 0.42), Color(0.9, 0.85, 0.7),
	]
	var hair_i: int = clampi(int(GameState.character.get("hair_color", 0)), 0, hair_colors.size() - 1)
	VoxelStyle.build_humanoid(self, skin, shirt, pants, hair_colors[hair_i])


func _char_color() -> Color:
	var c: Variant = GameState.character.get("primary_color", Color(0.2, 0.25, 0.4))
	if c is Color:
		return c
	if c is String:
		return Color.html(c) if (c as String).begins_with("#") else Color(0.2, 0.25, 0.4)
	if c is Dictionary:
		return Color(float(c.get("r", 0.2)), float(c.get("g", 0.25)), float(c.get("b", 0.4)))
	return Color(0.2, 0.25, 0.4)


func _unhandled_input(event: InputEvent) -> void:
	if GameState.phase != GameState.GamePhase.PLAYING:
		return
	if event is InputEventMouseMotion and _look_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		pivot.rotate_x(-event.relative.y * MOUSE_SENS)
		pivot.rotation.x = clampf(pivot.rotation.x, deg_to_rad(-50), deg_to_rad(30))
	if event.is_action_pressed("interact"):
		_try_interact()
	if event.is_action_pressed("pause_menu"):
		_toggle_pause_cursor()


func _toggle_pause_cursor() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if GameState.phase != GameState.GamePhase.PLAYING:
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Prevent tiny bounce jitter
		if velocity.y < 0.0:
			velocity.y = 0.0

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	if GameState.energy < 20.0:
		speed *= 0.7

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# Safety net: if we fell through the world, respawn
	if global_position.y < -10.0:
		global_position = Vector3(0, 2, 10)
		velocity = Vector3.ZERO
		EventBus.notification.emit("Rescued — you fell out of the world.", 2.0)

	GameState.player_position = global_position
	GameState.player_rotation_y = rotation.y
	GameState.tick_needs(delta)
	_update_interact_hint()


func _update_interact_hint() -> void:
	var target := _get_interact_target()
	if target != _nearby:
		_nearby = target
		if target and target.has_method("get_interact_label"):
			EventBus.interaction_available.emit(target.get_interact_label())
		elif target:
			EventBus.interaction_available.emit("Press E to interact")
		else:
			EventBus.interaction_cleared.emit()


func _get_interact_target() -> Node:
	if interact_ray and interact_ray.is_colliding():
		var col := interact_ray.get_collider()
		if col and col.is_in_group("interactable"):
			return col
	if not is_inside_tree() or get_world_3d() == null:
		return null
	var space := get_world_3d().direct_space_state
	var params := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.5
	params.shape = sphere
	params.transform = Transform3D(Basis(), global_position + Vector3(0, 1, 0))
	params.collision_mask = 4
	var results := space.intersect_shape(params, 8)
	var best: Node = null
	var best_d := 999.0
	for r in results:
		var c: Node = r.get("collider")
		if c and c.is_in_group("interactable"):
			var d: float = global_position.distance_to((c as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = c
	return best


func _try_interact() -> void:
	var target := _get_interact_target()
	if target and target.has_method("interact"):
		target.interact(self)
