extends CharacterBody3D
## Third-person detective controller — smooth follow camera, sprint, interact ray.
## Uses stylized realistic humanoid (HumanoidBuilder), not cartoon blocks.

const WALK_SPEED := 4.2
const SPRINT_SPEED := 7.0
const MOUSE_SENS := 0.0028
const HumanoidBuilder = preload("res://scripts/character/HumanoidBuilder.gd")

@onready var pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var mesh: MeshInstance3D = $Body
@onready var interact_ray: RayCast3D = $CameraPivot/Camera3D/InteractRay

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _look_enabled: bool = true
var _nearby: Node = null


func _ready() -> void:
	if camera:
		camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_apply_character_look()
	rotation.y = GameState.player_rotation_y
	call_deferred("_snap_to_ground")


func _snap_to_ground() -> void:
	if not is_inside_tree():
		return
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 3, 0), global_position + Vector3(0, -25, 0))
	q.collision_mask = 1
	var hit := space.intersect_ray(q)
	if hit:
		global_position.y = hit.position.y + 0.05


func _apply_character_look() -> void:
	if mesh:
		mesh.visible = false
	HumanoidBuilder.build(self, GameState.character)


func _unhandled_input(event: InputEvent) -> void:
	if GameState.phase != GameState.GamePhase.PLAYING:
		return
	if event is InputEventMouseMotion and _look_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		pivot.rotate_x(-event.relative.y * MOUSE_SENS)
		pivot.rotation.x = clampf(pivot.rotation.x, deg_to_rad(-48), deg_to_rad(28))
	if event.is_action_pressed("interact"):
		_try_interact()
	if event.is_action_pressed("pause_menu"):
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
	elif velocity.y < 0.0:
		velocity.y = 0.0

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	if GameState.energy < 20.0:
		speed *= 0.65
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	move_and_slide()
	if global_position.y < -10.0:
		global_position = Vector3(0, 2, 12)
		velocity = Vector3.ZERO
		EventBus.notification.emit("You stumble back onto solid ground.", 2.0)
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
	sphere.radius = 2.4
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
