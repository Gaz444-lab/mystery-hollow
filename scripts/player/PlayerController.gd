extends CharacterBody3D
## Third-person detective controller.

const WALK_SPEED := 4.5
const SPRINT_SPEED := 7.5
const JUMP_VELOCITY := 4.2
const MOUSE_SENS := 0.003
const CONTROLLER_LOOK_SENS := 2.5

@onready var pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var spring: SpringArm3D = $CameraPivot/SpringArm3D
@onready var mesh: MeshInstance3D = $Body
@onready var interact_ray: RayCast3D = $CameraPivot/SpringArm3D/Camera3D/InteractRay

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _look_enabled: bool = true
var _nearby: Node = null


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_apply_character_look()
	global_position = GameState.player_position
	rotation.y = GameState.player_rotation_y


func _apply_character_look() -> void:
	if mesh.mesh == null:
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.35
		capsule.height = 1.4 + GameState.character.get("body_type", 1) * 0.1
		mesh.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GameState.character.get("primary_color", Color(0.2, 0.25, 0.4))
	mesh.material_override = mat
	# Head accent
	if not has_node("Head"):
		var head := MeshInstance3D.new()
		head.name = "Head"
		var sphere := SphereMesh.new()
		sphere.radius = 0.28
		sphere.height = 0.56
		head.mesh = sphere
		head.position = Vector3(0, 0.95, 0)
		var hmat := StandardMaterial3D.new()
		var tones := [
			Color(0.95, 0.85, 0.75), Color(0.90, 0.75, 0.60), Color(0.80, 0.62, 0.48),
			Color(0.65, 0.45, 0.32), Color(0.45, 0.30, 0.22), Color(0.30, 0.20, 0.15),
		]
		var idx: int = clampi(int(GameState.character.get("skin_tone", 2)), 0, tones.size() - 1)
		hmat.albedo_color = tones[idx]
		head.material_override = hmat
		add_child(head)


func _unhandled_input(event: InputEvent) -> void:
	if GameState.phase != GameState.GamePhase.PLAYING:
		return
	if event is InputEventMouseMotion and _look_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		pivot.rotate_x(-event.relative.y * MOUSE_SENS)
		pivot.rotation.x = clampf(pivot.rotation.x, deg_to_rad(-60), deg_to_rad(35))
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

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	# Low energy slows you
	if GameState.energy < 20.0:
		speed *= 0.7

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
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
	if interact_ray.is_colliding():
		var col := interact_ray.get_collider()
		if col and col.is_in_group("interactable"):
			return col
	# Proximity fallback
	var space := get_world_3d().direct_space_state
	var params := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.2
	params.shape = sphere
	params.transform = Transform3D(Basis(), global_position + Vector3(0, 1, 0))
	params.collision_mask = 4  # interactable layer
	var results := space.intersect_shape(params, 8)
	var best: Node = null
	var best_d := 999.0
	for r in results:
		var c: Node = r.get("collider")
		if c and c.is_in_group("interactable"):
			var d: float = global_position.distance_to(c.global_position)
			if d < best_d:
				best_d = d
				best = c
	return best


func _try_interact() -> void:
	var target := _get_interact_target()
	if target and target.has_method("interact"):
		target.interact(self)
